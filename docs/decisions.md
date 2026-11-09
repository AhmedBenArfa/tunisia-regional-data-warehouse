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
- **Source de la composition :** décret n° 2023-589 du 21 septembre 2023, article premier (JORT n° 108 du 22 septembre 2023). Transcription : `data/reference/gouvernorat_district.csv`, contrôlée contre HDX (24 P-codes, aucun absent ni inconnu ; 4, 6, 6, 4 et 4 gouvernorats par district).
- **Reste à vérifier :** que le RGPH 2024 utilise bien ce découpage.
- **Impact :** `dwh.dim_gouvernorat`, `data/reference/gouvernorat_district.csv`.

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

## D-007 — Portée de la comparaison avec l'IDR

- **Date :** 2026-11-09
- **Problème :** le rapport IDR 2024 de l'ITCEQ ne publie ni le score ni le rang des 24 gouvernorats. On dispose seulement :
  - des rangs 2021 et 2024 des 5 premiers et des 5 derniers gouvernorats (tableau 2, p. 12) ;
  - de la classe de score de chaque gouvernorat (4 classes), lisible uniquement sur une carte (figure 3, p. 11) ;
  - des rangs des délégations au sein de chaque gouvernorat (annexes).
- **Options :**
  1. Comparer sur les 10 rangs publiés et sur les 4 classes, avec une lecture manuelle de la carte documentée comme telle.
  2. Demander à l'ITCEQ le tableau complet (scores et rangs par gouvernorat).
  3. Chercher le tableau complet dans les éditions 2018 et 2021, ou dans d'autres publications de l'ITCEQ.
  4. Reprendre un classement complet publié par la presse (source secondaire, à éviter sauf si elle cite un tableau officiel).
- **Choix :** options 1 et 3 tout de suite, option 2 en parallèle.
  - **Option 1 :** charger les 10 rangs publiés (5 premiers, 5 derniers, éditions 2021 et 2024) et la classe de score des 24 gouvernorats lue sur la figure 3. La lecture de la carte donne une **classe** (intervalle de score), **pas un rang** : la comparaison avec l'indice du projet se fait donc par classe pour les 14 gouvernorats sans rang publié. La lecture est manuelle et documentée comme telle (page, figure, légende).
  - **Option 3 :** rechercher les tableaux complets des éditions 2018 et 2021. On considère qu'elles reposent sur l'**ancienne méthode** : elles servent de contexte seulement et ne permettent pas de comparaison stricte avec 2024. *À vérifier dans chaque édition retrouvée.* Le rapport 2024 cite lui-même des rangs 2021 (tableau 2, annexes) et une série 2012-2024 (tableau 1), ce qui laisse penser que ces valeurs ont été recalculées avec la méthode 2024. Ces chiffres-là, cités dans le rapport 2024, restent comparables.
  - **Option 2 :** demander à l'ITCEQ le tableau complet de l'édition 2024. La demande et la réponse éventuelle seront consignées ici.
- **Justification :** on n'utilise que ce qui est publié par l'organisme, en signalant pour chaque valeur s'il s'agit d'un rang exact ou d'une classe. Aucune valeur n'est déduite.
- **Impact :** `dwh.ref_idr_itceq` (colonnes `rang`, `classe_score_min`, `classe_score_max`, `type_valeur` : rang publié ou classe lue sur la carte, `methode` : ancienne ou 2024), `J15_ITCEQ_IDR`, page Power BI de comparaison.

## D-008 — Définition de l'attribut côtier (proposée, à vérifier)

- **Date :** 2026-11-09
- **Problème :** l'analyse côte / intérieur suppose de classer chaque gouvernorat.
- **Options :**
  1. Définition géographique : le gouvernorat a une façade maritime.
  2. Définition statistique ou institutionnelle (liste publiée par l'INS ou l'ITCEQ), si elle existe.
  3. Distance du chef-lieu à la mer.
- **Proposition :** option 1, vérifiée avec les contours HDX (contact du polygone du gouvernorat avec le trait de côte).
- **Statut :** en attendant cette vérification, `dim_gouvernorat.cotier` reste vide (colonne facultative). La règle ne sera appliquée qu'une fois le contrôle fait et son résultat consigné ici.
- **Impact :** `dwh.dim_gouvernorat.cotier`, pages Power BI côte / intérieur.

## D-009 — Nettoyage du nom arabe

- **Date :** 2026-11-09
- **Problème :** le nom arabe de Siliana dans HDX contient des caractères d'allongement (`سليانـــة`, tatweel U+0640). Ils ne changent pas le mot, mais faussent toute comparaison de chaînes.
- **Choix :** dans `dwh.dim_gouvernorat.nom_ar`, suppression de tous les caractères U+0640 et des espaces en début et en fin. La forme brute reste dans `staging.stg_hdx_admin2.adm2_name1`. Une contrainte (`ck_nom_ar_sans_tatweel`) refuse tout nom arabe qui en contiendrait encore.
- **Justification :** la donnée source reste intacte en staging, et la dimension est propre pour le rapprochement.
- **Impact :** `J01_Referentiel_Geo` (expression du `tMap`), `dwh.dim_gouvernorat`.

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
