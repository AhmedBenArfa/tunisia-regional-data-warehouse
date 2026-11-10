# Inventaire des sources

Inventaire établi le 9 novembre 2026. Chaque source est suivie jusqu'au fichier : les téléchargements effectifs (URL, date, empreinte SHA-256) sont consignés dans [`data/manifest_telechargements.csv`](../data/manifest_telechargements.csv).

## Vue d'ensemble

| # | Source | Contenu utile | Période | Format | Granularité | Statut |
|---|---|---|---|---|---|---|
| 1 | Référentiel administratif INS / OCHA (HDX) | P-codes, noms français, arabes et sans accents, contours | Découpage 2022 | XLSX, SHP, GDB | Gouvernorat et niveaux inférieurs | Vérifié |
| 2 | INS — RGPH 2014 et 2024 | Population, âge, sexe, chômage, conditions de vie | 2014, 2024 | PDF + tableaux | Gouvernorat, délégation | En partie vérifié |
| 3 | INS — Banque de données statistiques | Indicateurs socio-économiques, export massif, API | À confirmer | XLSX, TXT, MDB, DBF + API XML | District, gouvernorat, délégation | En ligne (HTTP seulement) ; couverture régionale à explorer |
| 4 | INS — Annuaire statistique | Éducation, santé, équipements | 5 ans par édition | PDF | Gouvernorat | En partie vérifié |
| 5 | agridata.tn (catalogue CKAN) | Production agricole, eau potable, branchements SONEDE | Variable | XLSX + API CKAN | Gouvernorat, parfois délégation | Vérifié |
| 6 | ONTT — Tourisme en chiffres | Capacité en lits, taux d'occupation, durée de séjour, investissements | 3 ans par édition | PDF | 18 régions touristiques ; 24 gouvernorats pour les investissements | Vérifié : seuls les extraits 2020 et 2022 sont publiés |
| 7 | Open-Meteo (archive ERA5) | Températures, précipitations | 1940 à aujourd'hui | JSON (REST) | Point GPS (chef-lieu) | Vérifié |
| 8 | ITCEQ — Indicateur de développement régional (IDR) | Rangs partiels par gouvernorat, classes de score, rangs des délégations | Rapport 2024 (rappels 2012 à 2021) | PDF | Gouvernorat (partiel), délégation | Vérifié : tableau complet par gouvernorat non publié |
| 9 | Open-Meteo — API de géocodage (données GeoNames) | Coordonnées des villes chefs-lieux | Sans objet | JSON (REST) | Ville | Vérifié |
| 10 | Décret n° 2023-589 (JORT n° 108 du 22 septembre 2023) | Rattachement des 24 gouvernorats aux 5 districts | 2023 | PDF | Gouvernorat | Vérifié |

Fenêtre d'analyse visée : 2014–2024, ajustée selon la couverture réelle des sources.

## Détail par source

### 1. Référentiel administratif INS / OCHA (HDX)

- **Page :** https://data.humdata.org/dataset/e47eda48-8f83-4858-b739-dbffb8a50c47
- **Fichiers téléchargés le 9 novembre 2026** (jeu mis à jour sur HDX le 26 janvier 2026, découpage valide depuis le 15 novembre 2022, version `v01`) :
  - `tun_admin_boundaries.xlsx` : codes et noms, une feuille par niveau ;
  - `tun_admin_boundaries.shp.zip` : contours.
  - Les noms de fichiers cités dans les premières notes (`TUN_AdminBoundaries_TabularData.xlsx`, `tun_adm_ins_20221115_SHP.zip`) ne sont plus ceux publiés.
- **Licence :** CC BY-IGO.
- **Rôle :** référentiel géographique maître. Le P-code est la clé unique de tout l'entrepôt.
- **Dossier :** `data/raw/hdx/`

**Structure constatée du fichier XLSX :**

| Feuille | Lignes | Contenu |
|---|---|---|
| `tun_admin0` | 1 | Pays |
| `tun_admin1` | 6 | Grandes régions (Nord-Est, Nord-Ouest, Centre-Est, Centre-Ouest, Sud-Est, Sud-Ouest), P-codes `TN1` à `TN6` |
| `tun_admin2` | 24 | **Gouvernorats**, P-codes `TN11` à `TN63` |
| `tun_admin3` | 264 | Délégations |
| `tun_admin4` | 2 084 | Imadas (secteurs) |
| `tun_adminpoints` | 2 379 | Un point par unité, tous niveaux |
| `*_em`, `tun_adminlines*` | | Variantes « limites étendues » et lignes de frontière, non utilisées |

**Constats :**

- Le gouvernorat est au **niveau 2** (`adm2`), pas au niveau 1. Le niveau 1 correspond aux six grandes régions.
- `adm2_name` est déclaré en français (`lang = fr`) : Béja, Kassérine, Médenine, Gabès… `adm2_name1` est en arabe (`lang1 = ar`). `adm2_ref_name` est la forme sans accents (Beja, Kasserine, Medenine…). **Il n'y a pas de nom anglais.**
- Les libellés de niveau 1 sont en anglais (« Centre East ») bien que la langue déclarée soit `fr`.
- Graphies à prévoir dans la table de synonymes : `Manubah` (Manouba, La Manouba), `Sidi Bou Zid` (Sidi Bouzid), `Kebili` sans accent (Kébili), `Kassérine` avec accent (Kasserine), `Le Kef` (Kef).
- Le nom arabe de Siliana contient des caractères d'allongement (`سليانـــة`, tatweel) : il faut les supprimer avant toute comparaison sur l'arabe.
- `center_lat` / `center_lon` et `tun_adminpoints` donnent le **centroïde** de chaque unité, pas la position du chef-lieu. Pour Tataouine ou Kébili, l'écart est de plusieurs dizaines de kilomètres.

### 2. INS — Recensements (RGPH) 2014 et 2024

- **Page RGPH 2024 :** https://ins.tn/en/publication/population-and-housing-census-2024
- **Bilan démographique (mai 2025) :** https://www.ins.tn/sites/default/files-ftp3/files/2025-05/Bilan%20Démographique_0.pdf
- **Remarque :** deux points dans le temps seulement. Ce sont des indicateurs de niveau, pas des séries annuelles.
- **Dossier :** `data/raw/ins_rgph/`

### 3. INS — Banque de données statistiques

- **Dépliant de présentation (décrit dataportal.ins.tn, ses exports et son API) :** https://www.ins.tn/sites/default/files-ftp3/files/publication/pdf/Depliant%20banque%20de%20donn%C3%A9es%20statistiques.pdf
- **Portail :** http://dataportal.ins.tn/ (lien depuis la page d'accueil de ins.tn).
- **Constat du 9 novembre 2026 :**
  - le portail répond **en HTTP seulement** ; la connexion HTTPS est refusée ;
  - l'API est documentée sur http://dataportal.ins.tn/fr/API : requêtes XML (`QueryMessage` avec une source, une période et des filtres par dimension), adresse de service `http://dataportal.ins.tn/WebApi/`, plus de 300 indicateurs annoncés, fréquences annuelle et mensuelle ;
  - la liste des sources et la disponibilité de dimensions par gouvernorat restent à explorer.
- **Dossier :** `data/raw/ins_bds/`

### 4. INS — Annuaire statistique

- **Édition 2023 :** https://ins.tn/sites/default/files-ftp3/files/publication/pdf/annuaire-2023avec%20lien.pdf
- **Remarque :** chaque édition couvre 5 ans ; les éditions successives se recouvrent. Règle par défaut, à valider : l'édition la plus récente l'emporte.
- **Dossier :** `data/raw/ins_annuaire/`

### 5. agridata.tn (catalogue CKAN)

- **Olives à huile par gouvernorat** (colonnes Date, Gouvernorat, Production) : https://catalog.agridata.tn/fr/dataset/1994-2016/resource/efe84210-77d9-4003-a598-e9a5761fcb26
- **Taux de branchement des ménages au réseau SONEDE :** https://catalog.agridata.tn/dataset/taux-de-branchement-des-menages-par-gouvernorat-au-reseau-de-la-sonede/resource/2364be4b-d424-4b7c-8b40-6285125db5ca
- **Accès :** fichiers XLSX ou API CKAN (datastore actif).
- **Dossier :** `data/raw/agridata/`

### 6. ONTT — Tourisme en chiffres

- **Édition 2022 :** https://www.tourisme.gov.tn/wp-content/uploads/2024/12/rapport-EXTRAIT-2022-1.pdf
- **Édition 2020 :** https://www.tourisme.gov.tn/wp-content/uploads/2024/12/Extrait-tourisme-en-chiffres-2020.pdf
- **Tableaux utiles (édition 2022) :**
  - par région touristique : capacité en lits par catégorie (p. 4), durée de séjour hôtelier (p. 13), durée de séjour des résidents (p. 14), taux d'occupation par catégorie et région (p. 15) ;
  - par gouvernorat : investissements touristiques (p. 5).
- **Éditions disponibles :** la médiathèque du site (API WordPress `wp-json/wp/v2/media`, interrogée le 9 novembre 2026) ne contient que ces deux extraits, mis en ligne le 18 décembre 2024. Le site `ontt.tn` ne répond pas. Les autres années ne sont pas publiées en ligne.
- **Remarque :** les régions touristiques ne coïncident pas avec les gouvernorats (voir `docs/decisions.md`, pont zones → gouvernorats). Les libellés varient d'un tableau à l'autre dans une même édition.
- **Dossier :** `data/raw/ontt/`

### 7. Open-Meteo (archive ERA5)

- **Site :** https://open-meteo.com/
- **API archive :** `https://archive-api.open-meteo.com/v1/archive`
- **Conditions :** gratuit en usage non commercial, jusqu'à 10 000 appels par jour. Attribution CC BY 4.0 obligatoire : *Weather data by Open-Meteo.com*.
- **Granularité :** point GPS (chef-lieu de chaque gouvernorat), données journalières agrégées à l'année.
- **Dossier :** `data/raw/openmeteo/`

### 8. ITCEQ — Indicateur de développement régional (IDR)

- **Page :** https://www.itceq.tn/lindice-du-developpement-regional-2024/
- **Fichier :** `indice-dev-regional-2024.pdf` (70 pages, daté de juin 2025, 17,9 Mo, non versionné). L'ancienne note méthodologique (`.../indicateur-dev-regional.pdf`) renvoie une erreur 404.
- **Couverture presse :** https://www.leconomistemaghrebin.com/2025/07/25/nord-ouest-et-centre-ouest-en-bas-du-classement-du-developpement-regional-itceq/
- **Méthode de l'édition 2024 (p. 6-7 du rapport)** : elle diffère de la description « 17 variables, quatre domaines » trouvée dans des publications antérieures. Le rapport retient **4 dimensions** (commodités de la vie, dimension sociale, capital humain, emploi et marché du travail), **7 facteurs** et environ 26 variables, calculés **par délégation** puis agrégés. Les années d'observation des variables vont de 2015 à 2023.
- **Contenu exploitable en texte** (numéros de page imprimés, décalés d'une unité par rapport à la page du fichier PDF) :
  - p. 8, tableau 1 : IDR national (moyenne, minimum, maximum) pour 2012, 2015, 2018, 2021 et 2024 ;
  - p. 12, tableau 2 : rangs 2021 et 2024 des **5 premiers et des 5 derniers gouvernorats seulement** ;
  - p. 21 à 68, fiches par gouvernorat : rangs 2021 et 2024 de chaque délégation **au sein de son gouvernorat**.
- **Contenu disponible uniquement en image :** carte des scores en 4 classes (figure 3, p. 11), graphiques radar par facteur. **Le rapport ne publie pas le score ni le rang des 24 gouvernorats.**
- **Usage retenu (D-007) :** rangs publiés quand ils existent ; sinon, classe de score lue sur la carte (une classe n'est pas un rang). Les éditions 2018 et 2021, publiées séparément, sont considérées comme relevant de l'ancienne méthode (à vérifier) : contexte seulement, pas de comparaison stricte avec 2024. Les rangs 2021 cités dans le rapport 2024 font exception.
- Anomalie relevée : la fiche de Zaghouan (p. 31) titre ses colonnes « Rang 2021 » et « Rang 2018 », au lieu de « Rang 2024 ».
- **Rôle :** référence externe de comparaison. L'IDR n'entre pas dans le calcul de l'indice du projet ; il sert à le confronter au classement officiel.
- **Droits :** le rapport est la propriété de l'ITCEQ ; toute reproduction, intégrale ou partielle, sans autorisation écrite est interdite (p. 2). Conséquences pour le projet : le PDF n'est jamais versionné (dossier exclu dans `.gitignore`), seules les valeurs nécessaires à la comparaison sont reprises, toujours avec leur référence (page, tableau). La demande prévue à l'ITCEQ (D-007, option 2) inclura une demande d'autorisation de réutilisation.
- **Dossier :** `data/raw/itceq/` (non versionné)

### 9. Open-Meteo — API de géocodage

- **Documentation :** https://open-meteo.com/en/docs/geocoding-api
- **Point d'accès :** `https://geocoding-api.open-meteo.com/v1/search?name=<ville>&countryCode=TN&language=fr`
- **Données :** issues de la base GeoNames. Attribution obligatoire : *Location data based on GeoNames* (https://www.geonames.org, CC BY 4.0).
- **Rôle :** fournit les coordonnées de la ville chef-lieu de chaque gouvernorat, utilisées pour les appels météo (voir décision D-003).
- **Sélection :** on retient le résultat dont `feature_code = PPLA` (chef-lieu de division administrative de premier rang dans GeoNames). Exemple vérifié le 9 novembre 2026 : Tataouine, `PPLA`, 32,92967 N / 10,45177 E.
- **Dossier :** `data/raw/openmeteo_geocodage/`

### 10. Texte officiel créant les districts (2023)

- **Texte :** décret n° 2023-589 du 21 septembre 2023, relatif à la détermination du territoire des districts de la Tunisie et des gouvernorats qui relèvent de chaque district. Publié au JORT n° 108 du 22 septembre 2023, p. 2397-2398.
- **Fichier :** `Journal1082023.pdf`, traduction française « pour information » du JORT. Copie hébergée par le média inkyfada (https://inkyfada.com/wp-content/uploads/2023/12/Journal1082023.pdf) : à remplacer par la copie de l'Imprimerie officielle (iort.gov.tn) si elle est accessible.
- **Transcription :** `data/reference/gouvernorat_district.csv` (24 lignes, P-codes HDX, référence de la page pour chaque ligne).
- **Dossier :** `data/raw/districts/`

## Points à vérifier (phase 0)

- [x] dataportal.ins.tn est-il en ligne ? **Oui, en HTTP seulement.** API XML documentée. *Reste à faire : lister les sources et les thèmes disponibles par gouvernorat.*
- [x] Quelles éditions « Tourisme en chiffres » existent ? **Seulement les extraits 2020 et 2022** en ligne. *Reste à faire : années couvertes par chaque extrait.*
- [ ] À quels gouvernorats correspondent Tunis-Côtes de Carthage et Tunis-Sud ?
- [x] Le référentiel HDX contient-il des libellés français ? **Oui** (`adm2_name`), plus l'arabe et une forme sans accents. Pas d'anglais.
- [ ] Choisir 3 ou 4 fichiers agridata et noter leurs années.
- [ ] Récupérer les tableaux par gouvernorat des RGPH 2014 et 2024.
- [x] Version de Talend et disponibilité de PostgreSQL (voir `docs/architecture.md`, section Environnement).
- [x] Retrouver le rapport IDR 2024 de l'ITCEQ. **Trouvé** (PDF, 70 pages). Méthode différente de celle annoncée ; scores et rangs complets par gouvernorat non publiés (décision D-007).
- [x] Localiser le texte officiel des cinq districts (2023). **Décret n° 2023-589**, transcrit dans `data/reference/gouvernorat_district.csv`. *Reste à faire : vérifier que le RGPH 2024 utilise ce découpage.*
