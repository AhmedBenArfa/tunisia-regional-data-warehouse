# Inventaire des sources

Inventaire établi le 9 novembre 2026. Chaque source est suivie jusqu'au fichier : les téléchargements effectifs (URL, date, empreinte SHA-256) sont consignés dans [`data/manifest_telechargements.csv`](../data/manifest_telechargements.csv).

## Vue d'ensemble

| # | Source | Contenu utile | Période | Format | Granularité | Statut |
|---|---|---|---|---|---|---|
| 1 | Référentiel administratif INS / OCHA (HDX) | P-codes, noms anglais et arabes, contours | Découpage 2022 | XLSX, SHP, GDB | Gouvernorat et niveaux inférieurs | Vérifié |
| 2 | INS — RGPH 2014 et 2024 | Population, âge, sexe, chômage, conditions de vie | 2014, 2024 | PDF + tableaux | Gouvernorat, délégation | En partie vérifié |
| 3 | INS — Banque de données statistiques | Indicateurs socio-économiques, export massif, API | À confirmer | XLSX, TXT, MDB, DBF + API | District, gouvernorat, délégation | Non vérifié |
| 4 | INS — Annuaire statistique | Éducation, santé, équipements | 5 ans par édition | PDF | Gouvernorat | En partie vérifié |
| 5 | agridata.tn (catalogue CKAN) | Production agricole, eau potable, branchements SONEDE | Variable | XLSX + API CKAN | Gouvernorat, parfois délégation | Vérifié |
| 6 | ONTT — Tourisme en chiffres | Capacité en lits, taux d'occupation, durée de séjour, investissements | 3 ans par édition | PDF | 18 régions touristiques ; 24 gouvernorats pour les investissements | Vérifié (édition 2022) |
| 7 | Open-Meteo (archive ERA5) | Températures, précipitations | 1940 à aujourd'hui | JSON (REST) | Point GPS (chef-lieu) | Vérifié |
| 8 | ITCEQ — Indicateur de développement régional (IDR) | Score et rang par gouvernorat (référence de validation) | Éditions 2018, 2021, 2024 | PDF (à confirmer) | Gouvernorat, parfois délégation | Non vérifié |
| 9 | Open-Meteo — API de géocodage (données GeoNames) | Coordonnées des villes chefs-lieux | Sans objet | JSON (REST) | Ville | Vérifié |
| 10 | Texte officiel créant les districts (2023) | Rattachement des 24 gouvernorats aux 5 districts | 2023 | À localiser | Gouvernorat | Non vérifié |

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
- **Statut :** portail non encore ouvert. Disponibilité de l'API et thèmes par gouvernorat à vérifier.
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
- **Remarque :** les régions touristiques ne coïncident pas avec les gouvernorats (voir `docs/decisions.md`, pont zones → gouvernorats). Les libellés varient d'un tableau à l'autre dans une même édition.
- **Dossier :** `data/raw/ontt/`

### 7. Open-Meteo (archive ERA5)

- **Site :** https://open-meteo.com/
- **API archive :** `https://archive-api.open-meteo.com/v1/archive`
- **Conditions :** gratuit en usage non commercial, jusqu'à 10 000 appels par jour. Attribution CC BY 4.0 obligatoire : *Weather data by Open-Meteo.com*.
- **Granularité :** point GPS (chef-lieu de chaque gouvernorat), données journalières agrégées à l'année.
- **Dossier :** `data/raw/openmeteo/`

### 8. ITCEQ — Indicateur de développement régional (IDR)

- **Site :** https://www.itceq.tn (rapport IDR 2024 à localiser).
- **Ancienne note méthodologique citée dans des publications :** http://www.itceq.tn/files/developpement-regional/indicateur-dev-regional.pdf
- **Couverture presse du rapport 2024 :** https://www.leconomistemaghrebin.com/?p=636023
- **Méthode publiée :** moyenne simple de 17 variables en quatre domaines (richesse et emploi, savoir, santé et population, justice et équité), normalisées de 0 à 1.
- **Rôle :** référence externe de comparaison. L'IDR n'entre pas dans le calcul de l'indice du projet ; il sert à le confronter au classement officiel.
- **Dossier :** `data/raw/itceq/`

### 9. Open-Meteo — API de géocodage

- **Documentation :** https://open-meteo.com/en/docs/geocoding-api
- **Point d'accès :** `https://geocoding-api.open-meteo.com/v1/search?name=<ville>&countryCode=TN&language=fr`
- **Données :** issues de la base GeoNames. Attribution obligatoire : *Location data based on GeoNames* (https://www.geonames.org, CC BY 4.0).
- **Rôle :** fournit les coordonnées de la ville chef-lieu de chaque gouvernorat, utilisées pour les appels météo (voir décision D-003).
- **Sélection :** on retient le résultat dont `feature_code = PPLA` (chef-lieu de division administrative de premier rang dans GeoNames). Exemple vérifié le 9 novembre 2026 : Tataouine, `PPLA`, 32,92967 N / 10,45177 E.
- **Dossier :** `data/raw/openmeteo_geocodage/`

### 10. Texte officiel créant les districts (2023)

- **Rôle :** source de la table de rattachement gouvernorat → district (voir décision D-004).
- **Statut :** à localiser (texte publié au Journal officiel ou tableaux du RGPH 2024).
- **Dossier :** `data/raw/districts/`

## Points à vérifier (phase 0)

- [ ] dataportal.ins.tn est-il en ligne ? L'API répond-elle ? Quels thèmes par gouvernorat ?
- [ ] Quelles éditions « Tourisme en chiffres » existent, et quelles années couvrent-elles ?
- [ ] À quels gouvernorats correspondent Tunis-Côtes de Carthage et Tunis-Sud ?
- [x] Le référentiel HDX contient-il des libellés français ? **Oui** (`adm2_name`), plus l'arabe et une forme sans accents. Pas d'anglais.
- [ ] Choisir 3 ou 4 fichiers agridata et noter leurs années.
- [ ] Récupérer les tableaux par gouvernorat des RGPH 2014 et 2024.
- [x] Version de Talend et disponibilité de PostgreSQL (voir `docs/architecture.md`, section Environnement).
- [ ] Retrouver le rapport IDR 2024 de l'ITCEQ (et si possible 2018, 2021) : format, gouvernorats, liste des 17 variables.
- [ ] Localiser le texte officiel des cinq districts (2023) et vérifier que le RGPH 2024 l'utilise.
