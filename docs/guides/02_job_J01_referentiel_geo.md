# Guide 2 — Job `J01_Referentiel_Geo`

*Observatoire des disparités régionales en Tunisie — Ahmed Ben Arfa*

**Statut :** job terminé et vérifié (10 novembre 2026) : 24 gouvernorats dans `dwh.dim_gouvernorat`, 0 rejet, 0 écart avec les fichiers sources.

Le job exporté depuis Talend Studio se trouve dans [`talend/TUNISIA_DWH/process/`](../../talend/TUNISIA_DWH/process/).

---

## 1. Rôle du job

`J01_Referentiel_Geo` construit le **référentiel géographique maître** de l'entrepôt : la dimension `dwh.dim_gouvernorat`, une ligne par gouvernorat (24), identifiée par le **P-code HDX** (`TN11` à `TN63`). Toutes les autres sources seront rattachées à ce P-code.

Il croise trois fichiers :

| Fichier | Apport | Source |
|---|---|---|
| `data/raw/hdx/tun_admin_boundaries.xlsx`, feuille `tun_admin2` | P-codes, noms français, arabe et sans accents, région HDX, superficie, centroïde | INS / OCHA, publié sur HDX (CC BY-IGO) |
| `data/reference/gouvernorat_district.csv` | District de rattachement (1 à 5) | Décret n° 2023-589, transcrit et vérifié (D-004) |
| `data/manifest_telechargements.csv` | Empreinte SHA-256 du fichier HDX | Produit par `scripts/telecharger.py` |

## 2. Architecture du job

Deux sous-jobs enchaînés, sur une connexion unique :

```
cnx_dwh  (tPostgresqlConnection, connexion du référentiel cnx_tunisia_dwh)
   │ OnSubjobOk
   ▼
lire_hdx_admin2 ──row1──► tracer_hdx ──stg──► ecrire_stg_hdx_admin2        SOUS-JOB 1 : Excel → staging
   │ OnSubjobOk
   ▼
Valider  (tDBCommit, connexion laissée ouverte)
   │ OnSubjobOk
   ▼
lire_stg_hdx_admin2 ──row2──► controler_gouvernorat ──dim──► ecrire_dim_gouvernorat     SOUS-JOB 2 :
lire_district   ──row3 (lookup)──┘  │  └─rejet_jointure──► ecrire_rejets_jointure      staging → dwh
lire_manifeste  ──row4 (lookup)──┘  └───rejet_controle──► ecrire_rejets_controle
   │ OnSubjobOk
   ▼
valider_dwh  (tDBCommit, ferme la connexion)
```

**Pourquoi passer par `staging` ?** La copie en staging est fidèle à la source, sans aucune transformation (le nom arabe de Siliana y garde ses caractères d'allongement). En cas de doute sur une valeur de la dimension, on peut toujours comparer avec ce qui a été lu, ligne par ligne, avec le numéro de ligne du fichier d'origine.

**Pourquoi une seule connexion et un commit explicite ?** Tous les composants partagent la même session PostgreSQL, ouverte une fois. Les écritures ne sont validées qu'au `tDBCommit` : si le job échoue avant, rien n'est enregistré à moitié.

## 3. Sous-job 1 — Excel vers `staging.stg_hdx_admin2`

### 3.1 `cnx_dwh` — tPostgresqlConnection

| Paramètre | Valeur |
|---|---|
| Type de propriété | Référentiel → `cnx_tunisia_dwh` |
| Contexte | `ctx_dwh` (valeurs lues dans `.env` au lancement) |

### 3.2 `lire_hdx_admin2` — tFileInputExcel

| Paramètre | Valeur |
|---|---|
| Type de propriété | Built-in |
| Format | Excel 2007 (xlsx) |
| Nom de fichier | `context.RACINE_PROJET + "/data/raw/hdx/tun_admin_boundaries.xlsx"` |
| Feuille | `"tun_admin2"` |
| En-tête | 1 |
| Schéma | Référentiel → `hdx_admin2` (26 colonnes, voir Guide 1) |
| Arrêter en cas d'erreur | coché : pour un référentiel de 24 lignes, une ligne illisible doit arrêter le job |

Le chemin est construit à partir de `RACINE_PROJET` : le job fonctionne sur un autre poste en changeant une seule ligne de `.env`.

### 3.3 `tracer_hdx` — tMap

Le tMap ne transforme rien : il **sélectionne** les 11 colonnes utiles et **ajoute la traçabilité**.

| Colonne de sortie `stg` | Expression | Type |
|---|---|---|
| `adm2_pcode`, `adm2_name`, `adm2_name1`, `adm2_ref_name`, `adm1_pcode`, `adm1_name`, `version` | colonne source du même nom | String |
| `area_sqkm`, `center_lat`, `center_lon` | colonne source du même nom | Double |
| `valid_on` | `row1.valid_on` | Date |
| `source_fichier` | `"data/raw/hdx/tun_admin_boundaries.xlsx"` | String |
| `source_feuille` | `"tun_admin2"` | String |
| `source_ligne` | `Numeric.sequence("ligne_hdx", 1, 1)` | Integer |
| `id_execution` | `rootPid` | String |

- `source_ligne` numérote les lignes dans l'ordre du fichier (1 = Tunis, 24 = Kebili).
- `rootPid` est l'identifiant d'exécution fourni par Talend. Quand le job maître `J00_Master` lancera J01, `rootPid` sera celui du job maître : toutes les tables chargées lors d'une même exécution porteront le même identifiant.
- `date_chargement` n'est pas dans le flux : PostgreSQL la remplit (`DEFAULT now()`).

### 3.4 `ecrire_stg_hdx_admin2` — tPostgresqlOutput

| Paramètre | Valeur |
|---|---|
| Utiliser une connexion existante | `cnx_dwh` |
| Paramètres avancés → Utiliser un schéma alternatif | `"staging"` |
| Table | `"stg_hdx_admin2"` |
| Action sur la table | Tronquer la table |
| Action sur les données | Insert |
| Schéma | Sync colonnes (repris du tMap) |
| Arrêter en cas d'erreur | coché |

**Tronquer** et non « Vider la table » : TRUNCATE vide la table en une opération, alors que « Vider » exécute un DELETE ligne par ligne. La copie en staging est entièrement rechargée à chaque exécution.

### 3.5 `Valider` — tDBCommit

| Paramètre | Valeur |
|---|---|
| Connexion | `cnx_dwh` |
| Fermer la connexion | **décoché** : le sous-job 2 réutilise la connexion |

Déclenché par `lire_hdx_admin2` → OnSubjobOk.

### 3.6 Pièges rencontrés

| Symptôme | Cause | Solution |
|---|---|---|
| Impossible de relier le tMap à la sortie | Le tMap n'avait pas encore de sortie, et le `tDBOutput` avait été posé sans choisir de base (composant générique) | Créer la sortie `stg` dans le tMap ; poser un `tPostgresqlOutput` |
| Écrire dans `"staging.stg_hdx_admin2"` ne fonctionnerait pas | Talend met le nom de table entier entre guillemets : `INSERT INTO "staging.stg_hdx_admin2"` | Option *Utiliser un schéma alternatif* dans les paramètres avancés |
| Les champs Schéma et Hôte disparaissent | Normal en connexion existante : ils viennent de `cnx_dwh` | — |

### 3.7 Résultat vérifié (exécution du 9 novembre 2026, 23:28)

Console : contexte chargé depuis `.env`, 24 lignes lues, 24 écrites, code de sortie 0.

Contrôles en base (`sql/controles/controle_J01.sql`) puis comparaison, valeur par valeur, avec le fichier Excel :

| Contrôle | Résultat |
|---|---|
| Lignes / P-codes distincts | 24 / 24 |
| Écarts avec la feuille `tun_admin2` (textes, superficies, centroïdes, version, ordre) | **0** |
| `source_ligne` | 1 à 24 |
| Identifiants d'exécution distincts | 1 |
| `valid_on` | 2022-11-15 pour les 24 lignes |
| Superficie totale | 154 454,1 km² |
| Noms arabes avec tatweel (forme brute conservée) | 1 (Siliana) |

## 4. Sous-job 2 — `staging` vers `dwh.dim_gouvernorat`

### 4.1 `lire_stg_hdx_admin2` — tPostgresqlInput

| Paramètre | Valeur |
|---|---|
| Connexion existante | `cnx_dwh` |
| Requête | voir ci-dessous |
| Schéma | Copié de `ecrire_stg_hdx_admin2` (15 colonnes, même ordre que la requête) |

```
SELECT adm2_pcode, adm2_name, adm2_name1, adm2_ref_name, adm1_pcode, adm1_name,
       area_sqkm, center_lat, center_lon, valid_on, version,
       source_fichier, source_feuille, source_ligne, id_execution
FROM staging.stg_hdx_admin2
ORDER BY source_ligne
```

- La table est qualifiée par son schéma dans la requête : c'est du SQL écrit à la main, Talend ne le modifie pas.
- Talend associe les colonnes du résultat au schéma **par position** : l'ordre de la requête et celui du schéma doivent être identiques.
- « Deviner le schéma » n'est pas utilisable : il se connecte avec les valeurs du contexte dans le Studio, où le mot de passe est vide.

### 4.2 Les lookups

| Composant | Fichier | Paramètres | Schéma |
|---|---|---|---|
| `lire_manifeste` (tFileInputDelimited) | `context.RACINE_PROJET + "/data/manifest_telechargements.csv"` | séparateur `","`, lignes `"\n"`, en-tête 1, UTF-8 | Référentiel → métadonnée `manifest_telechargements` (6 colonnes String), réutilisée par tous les jobs |
| `lire_district` (tFileInputDelimited) | `context.RACINE_PROJET + "/data/reference/gouvernorat_district.csv"` | séparateur `","`, lignes `"\n"`, en-tête 1, UTF-8, **options CSV** avec encadrement `"\""` (la colonne `source_texte` contient des virgules) | Built-in, 7 colonnes, `district_num` en Integer |

Les deux composants ont « Arrêter en cas d'erreur » coché. Les colonnes du manifeste sont toutes en texte (même `taille_octets` et `telecharge_le_utc`) : ce sont des valeurs de traçabilité, recopiées sans calcul.

Les fichiers CSV sont forcés en fin de ligne LF par `.gitattributes`. Sans cela, un clone sous Windows ajouterait un `\r` à la dernière colonne lue (le `sha256` du manifeste).

### 4.3 `controler_gouvernorat` — tMap

**Jointures.** Les deux lookups sont en `Inner Join` / `Unique match`, chargés une fois :

| Lookup | Clé |
|---|---|
| `row3` (districts) | `row3.adm2_pcode = row2.adm2_pcode` |
| `row4` (manifeste) | `row4.fichier = row2.source_fichier` |

Un gouvernorat sans district, ou un fichier source absent du manifeste, n'entre pas dans la dimension : il part dans les rejets.

**Variables.**

`Var.nom_ar` (D-009) :

```
row2.adm2_name1 == null ? null : row2.adm2_name1.replace("\u0640", "").trim()
```

`Var.motif_controle` : chaîne vide si la ligne est valide, sinon la liste des problèmes détectés.

```
(row2.adm2_pcode == null || !row2.adm2_pcode.matches("TN[1-6][1-9]") ? "P-code absent ou mal forme ; " : "")
+ (row2.adm1_pcode == null || row2.adm2_pcode == null || !row2.adm2_pcode.startsWith(row2.adm1_pcode) ? "P-code hors de sa region HDX ; " : "")
+ (row2.adm2_name == null || row2.adm2_ref_name == null ? "Nom francais ou sans accents manquant ; " : "")
+ (Var.nom_ar == null || Var.nom_ar.isEmpty() ? "Nom arabe manquant ; " : "")
+ (row2.area_sqkm == null || row2.area_sqkm <= 0 ? "Superficie manquante ou nulle ; " : "")
+ (row2.center_lat == null || row2.center_lon == null || row2.center_lat < 30 || row2.center_lat > 38 || row2.center_lon < 7 || row2.center_lon > 12 ? "Centroide hors de la Tunisie ; " : "")
+ (row4.sha256 == null || !row4.sha256.matches("[0-9a-f]{64}") ? "Empreinte SHA-256 invalide ; " : "")
```

Ces contrôles reprennent les contraintes de `dim_gouvernorat` (Guide 1, § 2.3). Les deux niveaux sont complémentaires : le tMap détourne une ligne fautive vers les rejets, avec un motif lisible ; la contrainte en base reste le dernier filet si une règle du job était un jour modifiée par erreur. Les messages sont sans accents, pour éviter tout problème d'encodage dans le code Java généré.

**Sortie `dim`** — filtre `Var.motif_controle.isEmpty()` :

| Colonne | Expression |
|---|---|
| `pcode` (clé) | `row2.adm2_pcode` |
| `nom_fr` | `row2.adm2_name` |
| `nom_ar` | `Var.nom_ar` |
| `nom_ascii` | `row2.adm2_ref_name` |
| `district_num`, `district_libelle` | `row3.district_num`, `row3.district_libelle` |
| `region_hdx_pcode`, `region_hdx_nom` | `row2.adm1_pcode`, `row2.adm1_name` |
| `superficie_km2` | `row2.area_sqkm` |
| `lat_centroide`, `lon_centroide` | `row2.center_lat`, `row2.center_lon` |
| `source_fichier` | `row2.source_fichier` |
| `source_sha256` | `row4.sha256` |
| `date_chargement` | `TalendDate.getCurrentDate()` |
| `id_execution` | `rootPid` |

`lat_chef_lieu`, `lon_chef_lieu` et `cotier` sont volontairement absents du flux : ils seront remplis par d'autres traitements (D-003, D-008), et une nouvelle exécution de J01 ne les efface pas.

**Sorties de rejet.** Même schéma que `audit.etl_rejets`, sans `id_rejet` ni `date_rejet`, remplis par la base.

| Colonne | `rejet_jointure` (*Catch lookup inner join reject*) | `rejet_controle` (*Catch output reject*) |
|---|---|---|
| `id_execution` | `rootPid` | `rootPid` |
| `job` | `jobName` | `jobName` |
| `etape` | `"controler_gouvernorat : jointure"` | `"controler_gouvernorat : controles"` |
| `source_fichier` | `row2.source_fichier` | `row2.source_fichier` |
| `cle_source` | P-code et numéro de ligne | P-code et numéro de ligne |
| `ligne_brute` | champs utiles séparés par une barre verticale | idem |
| `motif` | lookup en échec (voir ci-dessous et § 4.7) | `Var.motif_controle` |

```
cle_source       : row2.adm2_pcode + " (ligne " + row2.source_ligne + ")"
ligne_brute      : row2.adm2_pcode + "|" + row2.adm2_name + "|" + row2.adm2_name1 + "|" + row2.adm1_pcode + "|" + row2.area_sqkm + "|" + row2.center_lat + "|" + row2.center_lon
motif (jointure) : row3.adm2_pcode == null ? "P-code absent de gouvernorat_district.csv ; " : "Fichier source absent du manifeste ; "
```

### 4.4 Les écritures

| Composant | Schéma alternatif | Table | Action sur la table | Action sur les données |
|---|---|---|---|---|
| `ecrire_dim_gouvernorat` | `"dwh"` | `"dim_gouvernorat"` | Par défaut (aucune) | **Insert or update** sur la clé `pcode` |
| `ecrire_rejets_jointure` | `"audit"` | `"etl_rejets"` | Par défaut | Insert |
| `ecrire_rejets_controle` | `"audit"` | `"etl_rejets"` | Par défaut | Insert |

Tous ont « Arrêter en cas d'erreur » coché.

- **Insert or update** : le gouvernorat est inséré s'il est absent, mis à jour s'il existe. Le job peut être relancé sans créer de doublon, et seules les colonnes du flux sont mises à jour.
- **Aucune action sur la table** : la table est créée par `sql/03_dwh_dim_gouvernorat.sql`, avec ses contraintes ; le job ne la recrée jamais.
- `valider_dwh` (tDBCommit, **Fermer la connexion** coché) valide en une fois la dimension et les rejets, puis ferme la connexion. Il est déclenché par `lire_stg_hdx_admin2` → OnSubjobOk.

### 4.5 Pièges rencontrés

| Symptôme | Cause | Solution |
|---|---|---|
| Impossible de relier la seconde sortie de rejet au `tUnite` | Talend n'accepte qu'un seul flux entre deux mêmes composants | Un composant d'écriture par flux de rejet, vers la même table |
| Après duplication d'un composant, la table devient `ecrire_rejets_jointure,"etl_rejets"` | Talend modifie le champ lors du copier-coller | Toujours relire le champ *Table* d'un composant dupliqué |
| « Erreurs de compilation du Job … Invalid Character » | Expressions copiées depuis un tableau mis en page : des caractères de bordure et des retours à la ligne ont été collés dans le tMap | Copier les expressions longues depuis un bloc de code, sur une seule ligne |
| Motif de rejet de jointure inexact (« Fichier source absent du manifeste » alors qu'il y était) | Talend fait les lookups dans l'ordre et s'arrête au premier Inner Join en échec : le lookup suivant reste vide, sans avoir été testé | Le motif ne teste que le premier lookup : s'il est vide, c'est lui qui a échoué, sinon c'est le second (§ 4.7) |
| Avertissement « schema DB type not correct » sur une sortie | Colonne *Db Type* vide dans le schéma du composant | Renseigner les types réels de la table (VARCHAR, TEXT) |
| Assistant « Fichier délimité » : colonnes nommées `hdx`, `48163`… | « En-tête : 1 » et « Définir la ligne d'en-tête comme nom de colonnes » cumulés : la première ligne de données devient l'en-tête | En-tête 1 seulement, puis noms de colonnes saisis à la main |

### 4.6 Résultat vérifié (exécution du 10 novembre 2026, 01:15)

Console : code de sortie 0. Canevas : 24 lignes lues en staging, 24 vers `dim`, 0 sur chaque flux de rejet.

Contrôles en base (`sql/controles/controle_J01.sql`) et comparaison avec les fichiers sources :

| Contrôle | Résultat |
|---|---|
| Lignes dans `dwh.dim_gouvernorat` | 24 |
| Districts / régions HDX distincts | 5 / 6 |
| Gouvernorats de staging absents de la dimension | 0 |
| Districts comparés à `gouvernorat_district.csv` | 0 écart |
| `source_sha256` comparé au manifeste | 0 écart |
| Noms arabes contenant encore un tatweel | 0 (Siliana : `سليانة`) |
| Rejets de l'exécution | 0 |
| Chef-lieu et côtier renseignés | 0, comme prévu (D-003, D-008) |

Superficies et centroïdes sont arrondis par PostgreSQL au type des colonnes (2 et 6 décimales).

### 4.7 Test des flux de rejets

Avec des données propres, les flux de rejets ne reçoivent rien : il faut les tester volontairement. Deux fichiers de test, dérivés des vrais fichiers avec une seule altération chacun, sont décrits dans [`data/test/README.md`](../../data/test/README.md). Ils ne sont jamais chargés dans l'entrepôt.

**Procédure.** Pointer `lire_district` et/ou `lire_manifeste` sur un fichier de test, exécuter **sans enregistrer**, remettre les vrais chemins, enregistrer et relancer.

| Exécution | Fichiers de test utilisés | Attendu | Obtenu |
|---|---|---|---|
| `AjAkbo` (10/11, 01:26) | district sans TN24 + manifeste à empreinte invalide | 1 rejet de jointure (TN24), 23 rejets de contrôle, 0 ligne vers `dim` | 1 + 23 + 0 : conforme. Mais le motif de TN24 mentionnait aussi, à tort, le manifeste (voir ci-dessous) |
| `BplArM` (10/11, 01:29) | district sans TN24, après correction du motif | 1 rejet de jointure, motif « P-code absent de gouvernorat_district.csv », 23 lignes vers `dim` | conforme |
| `xJif8Z` (10/11, 01:30) | aucun (vrais fichiers) | 24 lignes vers `dim`, 0 rejet | conforme |

Exemple de ligne rejetée (`audit.etl_rejets`) :

```
etape       : controler_gouvernorat : jointure
cle_source  : TN24 (ligne 11)
ligne_brute : TN24|Siliana|سليانـــة|TN2|4683.48868349|35.9687801|9.35412398
motif       : P-code absent de gouvernorat_district.csv ;
```

La ligne brute garde la forme lue en staging, caractères d'allongement compris : c'est bien la donnée d'origine qui est tracée.

**Ce que le test a révélé.** Le premier motif de jointure testait les deux lookups : `(row3… == null ? … : "") + (row4.sha256 == null ? … : "")`. Pour TN24, il affichait aussi « Fichier source absent du manifeste », alors que le fichier y figurait. Talend traite les lookups dans l'ordre et s'arrête au premier Inner Join en échec : `row4` n'est pas cherché et reste vide. Le motif corrigé n'interroge que le premier lookup ; s'il a réussi, l'échec vient forcément du second.

Les lignes des exécutions de test restent dans `audit.etl_rejets` : c'est l'historique, identifié par `id_execution`.
