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

## D-010 — Documentation : Markdown source, PDF généré

- **Date :** 2026-11-09
- **Problème :** la documentation doit être lisible sur GitHub et partageable hors de GitHub (entretien, réseau professionnel), sans maintenir deux versions.
- **Options :**
  1. Markdown seul.
  2. Documents rédigés directement en PDF ou en traitement de texte.
  3. Markdown comme source unique, PDF générés par script.
- **Choix :** option 3. `scripts/generer_pdf.py` convertit les fichiers Markdown en HTML puis imprime en PDF avec Edge ou Chrome sans interface, dans `docs/pdf/`. Les PDF sont versionnés et régénérés à chaque mise à jour de la documentation.
- **Justification :** une seule source à tenir à jour, des diffs lisibles dans git, une mise en page soignée pour la lecture hors ligne, sans logiciel supplémentaire (le navigateur est déjà installé).
- **Impact :** `docs/guides/`, `docs/pdf/`, `scripts/generer_pdf.py`, `requirements.txt`.

## D-011 — Images de la documentation et supports de publication

- **Date :** 2026-11-10
- **Problème :** les guides, le README et la publication finale (réseau professionnel) ont besoin d'images du travail réalisé. Des captures d'écran brutes contiennent le bureau et la barre des tâches, et toute image retouchée ou reconstituée affaiblirait la crédibilité du projet.
- **Options :**
  1. Captures d'écran complètes, telles quelles.
  2. Schémas redessinés à la main pour illustrer les jobs.
  3. Images réelles uniquement, tirées des fichiers produits par les outils ou des captures d'exécution, simplement recadrées.
- **Choix :** option 3.
  - **Canevas et tMap** : images PNG extraites du fichier `.screenshot` que Talend Studio enregistre avec chaque job exporté (`talend/TUNISIA_DWH/process/`). Elles montrent le job tel qu'il a été construit, sans élément du bureau.
  - **Exécution** : capture d'écran prise après une exécution réussie, recadrée sur le canevas pour garder le nombre de lignes affiché sur chaque lien.
  - Rangement dans `docs/img/`, nommage `Jxx_job.png`, `Jxx_tmap_<nom>.png`, `Jxx_execution.png`. Aucune modification du contenu d'une image : recadrage seulement.
  - À la fin de chaque job : les trois images sont produites, insérées dans le guide du job, et le PDF est régénéré.
- **Supports prévus pour la publication finale (phase 7)** :
  1. Schéma d'architecture de la chaîne (sources → Talend → PostgreSQL → Power BI).
  2. Canevas des principaux jobs Talend, avec leurs statistiques d'exécution.
  3. Rapport qualité (complétude par source et par année, rejets, contrôles de totaux).
  4. Pages du rapport Power BI : carte, indice composite, côte / intérieur, tourisme, comparaison avec l'IDR.
  5. Carrousel PDF de quelques pages, qui résume le projet (problème, sources, intégration, résultats, limites).
  6. Texte du post, qui décrit exactement ce qui a été fait, y compris les étapes hors Talend.
  - Les captures de Power BI seront prises fenêtre agrandie, sans barre des tâches.
- **Justification :** des images authentiques et reproductibles (régénérées à chaque export du job), cohérentes avec le principe de présentation honnête du projet.
- **Impact :** `docs/img/`, guides des jobs, `README.md`, `scripts/generer_pdf.py`, phase 7 du projet.

## D-012 — Table de synonymes géographiques : normalisation, portée, priorité

- **Date :** 2026-11-10
- **Problème :** chaque source écrit les gouvernorats à sa façon (accents, articles, apostrophes typographiques, arabe avec ou sans hamza). Il faut rattacher chaque libellé à un P-code de façon fiable, traçable et sans multiplier les entrées pour de simples différences d'écriture.
- **Options :**
  1. Lister toutes les graphies exactes, sans normalisation.
  2. Normaliser fortement (supprimer aussi les articles « le », « la », « l' »), pour réduire la liste.
  3. Normalisation légère et prévisible, plus une liste explicite des variantes réellement observées.
- **Choix :** option 3.
  - **Normalisation** (routine Talend `Libelles.normaliser`, copiée à l'identique dans `scripts/normaliser_libelle.py` pour les contrôles) : décomposition Unicode et suppression des signes diacritiques (accents latins, hamza, voyelles arabes), suppression du tatweel, `ى` → `ي` et `ة` → `ه`, minuscules, ponctuation (y compris apostrophes et tirets typographiques) remplacée par une espace, espaces multiples réduites. Exemples : « l’Ariana » → `l ariana`, « Kébili » → `kebili`, « سليانـــة » → `سليانه`.
  - **Les articles sont conservés** : « Le Kef » et « Kef » restent deux formes distinctes, chacune présente parce qu'elle a été observée. La normalisation ne fait que des transformations sans ambiguïté.
  - **Contenu de la table** : les noms officiels HDX (français, arabe, sans accents), repris de `dwh.dim_gouvernorat`, plus les variantes de `data/reference/synonymes_geo.csv`. Chaque variante indique où elle a été observée (fichier, page). Aucune variante n'est ajoutée sans avoir été rencontrée dans une source.
  - **Portée** : chaque synonyme porte une source et un tableau ; `*` signifie « toutes ». Les variantes observées jusqu'ici valent pour toutes les sources. Une entrée propre à une source ou à un tableau servira pour un libellé ambigu (cas prévu pour les tableaux de l'ONTT). Dans les jobs de chargement, la recherche se fait d'abord sur la source et le tableau, puis sur la portée générale.
  - **Priorité et conflits** : les noms officiels sont lus avant les variantes. Si deux entrées donnent la même forme normalisée pour la même portée, avec le même P-code, la seconde est un simple doublon et elle est écartée ; avec un P-code différent, c'est un conflit : la seconde part dans `audit.etl_rejets`, et le nom officiel l'emporte.
  - **Cycle de vie** : un libellé inconnu rencontré par un job de chargement part dans les rejets ; après vérification, il est ajouté au fichier CSV avec son origine, et J02 est relancé.
- **Justification :** une règle courte et explicable en entretien, aucun rapprochement « approximatif » qui pourrait rattacher un libellé au mauvais gouvernorat, et une table où chaque entrée a une origine vérifiable.
- **Impact :** `dwh.ref_synonyme_geo` (`sql/04_dwh_ref_synonyme_geo.sql`), `data/reference/synonymes_geo.csv`, routine Talend `Libelles`, job `J02_Synonymes`, tous les jobs de chargement de sources.

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
