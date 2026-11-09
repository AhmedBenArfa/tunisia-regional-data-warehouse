# Journal des décisions

Chaque règle de mapping, de répartition ou de dédoublonnage est consignée ici : date, problème, options envisagées, choix retenu, justification.

---

## D-001 — Niveau administratif du gouvernorat dans le référentiel HDX

- **Date :** 2026-11-09
- **Problème :** le fichier `tun_admin_boundaries.xlsx` contient cinq niveaux. Il faut savoir lequel correspond au gouvernorat.
- **Constat :** `tun_admin1` contient 6 grandes régions (`TN1` à `TN6`) ; `tun_admin2` contient les 24 gouvernorats (`TN11` à `TN63`).
- **Choix :** `dwh.dim_gouvernorat` est alimentée par la feuille `tun_admin2`. La clé est `adm2_pcode`. Le niveau 1 (`adm1_pcode`, `adm1_name`) est conservé comme attribut de regroupement.
- **Justification :** 24 lignes, une par gouvernorat ; les P-codes reprennent les codes INS des gouvernorats préfixés par `TN`.
- **Impact :** `J01_Referentiel_Geo`, `dwh.dim_gouvernorat`.

## D-002 — Pas de nom anglais ; ajout d'une forme sans accents

- **Date :** 2026-11-09
- **Problème :** le modèle prévoyait un nom anglais par gouvernorat, mais le référentiel HDX n'en fournit pas. Il fournit le français (`adm2_name`), l'arabe (`adm2_name1`) et une forme sans accents (`adm2_ref_name`).
- **Options :**
  1. Garder une colonne « nom anglais » vide.
  2. La remplir depuis une autre source.
  3. La supprimer et exploiter la forme sans accents fournie.
- **Choix :** option 3. `dim_gouvernorat` contient `nom_fr`, `nom_ar` et `nom_ascii` (copie de `adm2_ref_name`).
- **Justification :** aucune source ne justifie une colonne anglaise, et une colonne vide n'apporte rien. La forme sans accents sert directement au rapprochement des libellés sources (Beja / Béja, Gabes / Gabès).
- **Impact :** `dwh.dim_gouvernorat`, `J01_Referentiel_Geo`, `J02_Synonymes`.

## D-003 — Coordonnées des chefs-lieux pour la météo

- **Date :** 2026-11-09
- **Problème :** HDX ne fournit que le centroïde de chaque gouvernorat. Pour les grands gouvernorats du Sud, le centroïde tombe loin de la population (pour Tataouine, il est situé vers 31,74° N, alors que la ville est plus au nord).
- **Options :**
  1. Utiliser le centroïde HDX.
  2. Utiliser le point de la délégation du chef-lieu dans `tun_admin3` (encore un centroïde).
  3. Interroger l'API de géocodage Open-Meteo pour obtenir les coordonnées de la ville chef-lieu.
- **Choix :** option 3 pour les appels météo. Les centroïdes HDX sont conservés pour les étiquettes de carte. Les deux paires de coordonnées sont stockées dans `dim_gouvernorat`.
- **Justification :** la ville chef-lieu représente mieux les conditions vécues par la population que le centre géométrique. L'API de géocodage est documentée comme une source à part, avec sa propre ligne dans le manifeste.
- **Limite assumée :** un point par gouvernorat reste une approximation. Il ne rend pas compte des écarts internes (littoral et intérieur de Sfax ou de Médenine, nord et sud de Tataouine). Cette limite figurera dans le README.
- **Impact :** `dwh.dim_gouvernorat` (`lat_chef_lieu`, `lon_chef_lieu`, `lat_centroide`, `lon_centroide`), `J14_OpenMeteo`.

## D-004 — Regroupement régional : les cinq districts de 2023

- **Date :** 2026-11-09
- **Problème :** HDX regroupe les gouvernorats en six grandes régions (`adm1`). Depuis 2023, la Tunisie compte cinq districts.
- **Options :**
  1. Six régions HDX.
  2. Cinq districts de 2023.
- **Choix :** les cinq districts de 2023 sont l'attribut principal (`district`). Les six régions HDX restent un attribut secondaire (`region_hdx_pcode`, `region_hdx_nom`).
- **Justification :** c'est le découpage institutionnel en vigueur, et celui que l'INS utiliserait dans le RGPH 2024.
- **À vérifier avant chargement :** la composition exacte des districts doit venir d'une source identifiée (texte officiel ou tableaux du RGPH 2024). On ne la saisit pas de mémoire. Il faut aussi confirmer que le RGPH 2024 utilise bien ce découpage.
- **Impact :** `dwh.dim_gouvernorat`, `data/reference/` (table gouvernorat → district avec sa source).

## D-005 — Versionnement des fichiers bruts

- **Date :** 2026-11-09
- **Problème :** certains fichiers bruts sont lourds (contours HDX : 48 Mo).
- **Choix :** les fichiers bruts de plus de 10 Mo sont exclus de git via `.gitignore`. Les plus petits sont versionnés. Le manifeste `data/manifest_telechargements.csv` donne l'URL, la date et l'empreinte SHA-256 de **tous** les fichiers, versionnés ou non. `scripts/telecharger.py` applique cette règle automatiquement.
- **Justification :** le dépôt reste léger, et quiconque peut retrouver le fichier exact et vérifier son intégrité.
- **Impact :** `.gitignore`, `scripts/telecharger.py`.

## D-006 — Utilisateur PostgreSQL dédié

- **Date :** 2026-11-09
- **Problème :** quel compte utiliser pour les jobs Talend, les scripts et Power BI ?
- **Choix :** un rôle `dwh_user`, propriétaire de la base `tunisia_dwh` et de ses schémas, sans droit d'administration du serveur. Le superutilisateur `postgres` ne sert qu'à exécuter `sql/00_creation_base.sql`. Les identifiants sont rangés dans un fichier `.env` ignoré par git (modèle : `.env.example`).
- **Justification :** principe du moindre privilège. Aucun secret dans le dépôt.
- **Impact :** `sql/00_creation_base.sql`, groupes de contexte Talend, connexion Power BI.

---

<!-- Modèle d'entrée

## D-000 — Titre court

- **Date :** AAAA-MM-JJ
- **Problème :**
- **Options :**
  1.
  2.
- **Choix :**
- **Justification :**
- **Impact :** (tables, jobs ou fichiers concernés)

-->
