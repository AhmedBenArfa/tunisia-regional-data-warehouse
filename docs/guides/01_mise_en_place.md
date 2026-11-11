# Guide 1 — Mise en place de l'environnement

*Observatoire des disparités régionales en Tunisie — Ahmed Ben Arfa*

Ce guide décrit, dans l'ordre, tout ce qui a été installé et configuré avant le premier job Talend : la base PostgreSQL, le fichier de configuration unique `.env`, puis le projet Talend (contextes, connexion, métadonnées). Pour chaque étape, il indique le *pourquoi*, pas seulement le *comment*, ainsi que les pièges rencontrés.

Documents liés : [`architecture.md`](../architecture.md) (vue d'ensemble), [`decisions.md`](../decisions.md) (journal des décisions), [Guide 2 — Job J01](02_job_J01_referentiel_geo.md).

---

## 1. Environnement de travail

| Composant | Version | Remarque |
|---|---|---|
| Windows 11 Professionnel | 10.0.26200 | |
| Talend Open Studio for Data Integration | 8.0.1 (build 20211109_1610) | Plus maintenu depuis janvier 2024 |
| Java | JDK 17.0.12 | Requis par Talend 8 |
| PostgreSQL | 18.1 | Service `postgresql-x64-18`, démarrage automatique |
| Python | 3.13 | Environnement virtuel `.venv/` (téléchargements, extraction PDF, contrôles) |
| Power BI Desktop | installé | Phase de restitution |

Les versions ont été relevées avant toute création d'objet : rien n'est supposé.

## 2. La base PostgreSQL

### 2.1 Principe : un utilisateur applicatif dédié (D-006)

Le compte `postgres` est un superutilisateur : il peut tout faire sur le serveur. Les jobs n'en ont pas besoin. On crée donc un utilisateur **`dwh_user`**, propriétaire de la seule base **`tunisia_dwh`** et de ses trois schémas, sans aucun droit sur le reste du serveur (principe du moindre privilège).

| Schéma | Rôle |
|---|---|
| `staging` | Copie fidèle des sources, sans contrainte, rechargée entièrement à chaque exécution |
| `dwh` | Modèle en étoile : dimensions, faits, tables de référence, avec contraintes |
| `audit` | Journal des exécutions et des lignes rejetées |

### 2.2 Les scripts SQL

| Script | Exécuté par | Contenu |
|---|---|---|
| `sql/00_creation_base.sql` | `postgres` | Rôle `dwh_user`, base `tunisia_dwh` (UTF-8), schémas `staging`, `dwh`, `audit`. Le mot de passe est demandé de façon interactive (`\password`) : il n'apparaît ni dans le fichier ni dans l'historique. Relançable sans erreur. |
| `sql/01_audit.sql` | `dwh_user` | `audit.etl_run_log` (une ligne par exécution de job) et `audit.etl_rejets` (une ligne par ligne rejetée, avec son motif) |
| `sql/02_staging_hdx.sql` | `dwh_user` | `staging.stg_hdx_admin2` : copie de la feuille HDX des gouvernorats, plus les colonnes de traçabilité |
| `sql/03_dwh_dim_gouvernorat.sql` | `dwh_user` | `dwh.dim_gouvernorat` et ses contraintes de contrôle |

Commandes (invite de commandes Windows, à la racine du dépôt) :

```
psql -U postgres -h localhost -f sql/00_creation_base.sql
psql -f sql/01_audit.sql
psql -f sql/02_staging_hdx.sql
psql -f sql/03_dwh_dim_gouvernorat.sql
```

Les trois dernières commandes n'indiquent ni utilisateur ni base : `psql` lit les variables `PG*` de l'environnement, chargées depuis `.env` (section 3).

### 2.3 Les contraintes de `dim_gouvernorat`, premier filet de qualité

La dimension refuse d'elle-même une ligne incohérente, même si un job laissait passer une erreur :

| Contrainte | Règle |
|---|---|
| `pk_dim_gouvernorat` | Le P-code est unique |
| `ck_pcode_format` | P-code de la forme `TN` + région (1 à 6) + rang (1 à 9) |
| `ck_pcode_dans_region` | Les trois premiers caractères du P-code sont ceux de la région HDX |
| `ck_nom_ar_sans_tatweel` | Le nom arabe ne contient plus de caractère d'allongement (U+0640, D-009) |
| `ck_district` | District entre 1 et 5 (décret 2023-589, D-004) |
| `ck_centroide_tunisie`, `ck_chef_lieu_tunisie` | Coordonnées dans les limites de la Tunisie (30–38° N, 7–12° E) |
| `ck_chef_lieu_complet` | Latitude et longitude du chef-lieu toutes deux renseignées ou toutes deux vides |
| `ck_sha256` | Empreinte du fichier source au format SHA-256 |

Ces contraintes ont été testées avant le premier job : les 24 gouvernorats réels sont acceptés, et 6 lignes volontairement fausses sont toutes refusées. Le test a été annulé (`ROLLBACK`) : la table était vide au démarrage de J01.

## 3. Une configuration unique : le fichier `.env`

Un seul fichier, à la racine du dépôt, sert à **psql**, aux **scripts Python** et à **Talend**. Il est ignoré par git ; le modèle versionné est `.env.example`.

```
PGHOST=localhost
PGPORT=5432
PGDATABASE=tunisia_dwh
PGUSER=dwh_user
PGPASSWORD=
PGSCHEMA=
PGPARAMS=
RACINE_PROJET=D:/Projet/tunisia-regional-data-warehouse
```

- Les noms `PG*` sont les variables standard de PostgreSQL : `psql` les lit sans paramètre.
- Les mêmes noms sont utilisés pour les variables de contexte Talend, qui les lit au lancement de chaque job.
- Le fichier ne contient que des lignes `CLE=valeur`, **sans commentaire** : Talend lirait un commentaire comme une variable.
- `PGSCHEMA` et `PGPARAMS` sont vides mais présents : la connexion Talend en mode contexte les exige (section 4.3).

## 4. Le projet Talend

### 4.1 Lancer Talend en administrateur

L'espace de travail se trouve sous `C:\Program Files (x86)\…`. Windows y interdit l'écriture à un utilisateur standard : Talend doit être lancé **en tant qu'administrateur**, sinon les modifications ne sont pas enregistrées.

Si la disposition des fenêtres est perdue : relancer Talend en administrateur avec l'option `-clearPersistedState`.

### 4.2 Les groupes de contexte

Projet `TUNISIA_DWH`, environnement de contexte unique **`DEV`** (l'environnement `Default` créé par Talend a été supprimé, pour qu'il n'y ait qu'une source de valeurs).

| Groupe | Variables | Usage |
|---|---|---|
| `ctx_dwh` | `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`, `PGSCHEMA`, `PGPARAMS` | Connexion à la base |
| `ctx_chemins` | `RACINE_PROJET` | Base de tous les chemins de fichiers |

**Pourquoi deux groupes ?** La connexion du référentiel ne peut être reliée (« Export as context ») qu'à un groupe dont **chaque** variable correspond à l'un de ses champs. Un groupe unique contenant aussi `RACINE_PROJET` était refusé.

**Le mot de passe** : dans Talend, `PGPASSWORD` est de type mot de passe et sa valeur reste **vide**. Il n'est lu que dans `.env`, au lancement. Il n'apparaît donc dans aucun fichier du projet Talend ni dans les exports de jobs.

### 4.3 La connexion `cnx_tunisia_dwh`

*Métadonnées → Connexions de bases de données*, PostgreSQL, version « v9 and later ». Chaque champ pointe vers une variable de contexte :

| Champ | Valeur |
|---|---|
| Serveur | `context.PGHOST` |
| Port | `context.PGPORT` |
| Base de données | `context.PGDATABASE` |
| Utilisateur | `context.PGUSER` |
| Mot de passe | `context.PGPASSWORD` |
| Schéma | `context.PGSCHEMA` (vide) |
| Paramètres additionnels | `context.PGPARAMS` (vide) |

Pièges rencontrés :

- Talend avertit que le champ *Schéma* doit être rempli en mode contexte : on valide avec OK et on le laisse vide. Le schéma est choisi dans chaque composant (voir le Guide 2, « schéma alternatif »).
- Dans le tableau de correspondance des variables, le bouton *Finish* reste grisé tant que la dernière cellule modifiée n'a pas été validée avec Entrée.

### 4.4 Chargement implicite du contexte

*Fichier → Éditer les propriétés du projet → Paramètres du job → Implicit tContextLoad* :

| Paramètre | Valeur |
|---|---|
| Activé | oui |
| Source | From File |
| Fichier | `"D:/Projet/tunisia-regional-data-warehouse/.env"` |
| Séparateur de champs | `"="` |
| Print operations | oui |

Avec *Print operations*, chaque exécution affiche dans la console les variables chargées, mot de passe masqué :

```
Implicit_Context_Context set key "PGHOST" with value "localhost"
Implicit_Context_Context set key "PGPASSWORD" with value "*********"
Implicit_Context_Context set key "RACINE_PROJET" with value "D:/Projet/tunisia-regional-data-warehouse"
```

### 4.5 La métadonnée Excel `hdx_admin2`

*Métadonnées → Fichier Excel*, fichier `data/raw/hdx/tun_admin_boundaries.xlsx`, feuille **`tun_admin2`** (les 24 gouvernorats), en-tête sur la ligne 1.

**Piège rencontré :** l'assistant a repris la structure de la première feuille du classeur (`tun_admin0`, 18 colonnes) au lieu de celle de `tun_admin2` (26 colonnes), et refusait « Dernière colonne : 26 ». Solution : vider ce champ, puis ajouter à la main les 8 colonnes manquantes dans l'éditeur de schéma.

Schéma final, 26 colonnes dans l'ordre du fichier :

| Colonnes | Type |
|---|---|
| `adm2_name`, `adm2_name1` à `adm2_name3`, `adm2_pcode`, `adm1_name`, `adm1_name1` à `adm1_name3`, `adm1_pcode`, `adm0_name`, `adm0_name1` à `adm0_name3`, `adm0_pcode` | String |
| `valid_on` | Date, modèle `"dd-MM-yyyy"` |
| `valid_to`, `version`, `lang`, `lang1` à `lang3`, `adm2_ref_name` | String |
| `area_sqkm`, `center_lat`, `center_lon` | Double |

Revenir en arrière dans l'assistant réinitialise les types : ils ont été corrigés ensuite par *Éditer le schéma*.

## 5. Récapitulatif des pièges

| Symptôme | Cause | Solution |
|---|---|---|
| Modifications Talend non enregistrées, disposition cassée | Espace de travail sous Program Files | Lancer en administrateur ; `-clearPersistedState` |
| « Export as context » refusé | Groupe contenant une variable sans champ correspondant | Un groupe par usage (`ctx_dwh`, `ctx_chemins`) |
| *Finish* grisé | Dernière cellule non validée | Entrée avant *Finish* |
| Assistant Excel bloqué à 18 colonnes | Structure lue sur la première feuille | Ajouter les colonnes à la main |
| Types du schéma Excel perdus | Retour arrière dans l'assistant | Les corriger dans *Éditer le schéma* |
| Après l'export d'un job, les autres jobs ont disparu de `talend/` | *Exporter des éléments* vers un répertoire remplace son contenu par les seuls éléments sélectionnés | Exporter **tous les jobs ensemble**, avec leurs dépendances (contextes, connexion, métadonnées, routines) |

Précaution prise d'emblée (pas un incident) : aucun commentaire dans `.env`, car le chargement implicite lirait chaque ligne comme une variable.
