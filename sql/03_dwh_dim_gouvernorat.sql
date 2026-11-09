-- =============================================================================
-- 03_dwh_dim_gouvernorat.sql
-- Dimension des 24 gouvernorats : référentiel géographique maître de l'entrepôt.
--
-- Alimentée par J01_Referentiel_Geo à partir de :
--   - staging.stg_hdx_admin2 (codes, noms, superficie, centroïdes) ;
--   - data/reference/gouvernorat_district.csv (district, décret n° 2023-589) ;
--   - data/manifest_telechargements.csv (empreinte SHA-256 du fichier HDX).
-- Les coordonnées des chefs-lieux (J14) et l'attribut côtier (D-008) sont
-- renseignés plus tard : colonnes facultatives.
--
-- Décisions : D-001 (niveau adm2), D-002 (noms), D-003 (coordonnées),
--             D-004 (districts), D-008 (côtier).
-- Exécution :  psql -f sql/03_dwh_dim_gouvernorat.sql
-- =============================================================================

\set ON_ERROR_STOP on
\encoding UTF8

CREATE TABLE IF NOT EXISTS dwh.dim_gouvernorat (
    pcode             varchar(4)    NOT NULL,
    nom_fr            varchar(50)   NOT NULL,
    nom_ar            varchar(50)   NOT NULL,
    nom_ascii         varchar(50)   NOT NULL,
    district_num      smallint      NOT NULL,
    district_libelle  varchar(30)   NOT NULL,
    region_hdx_pcode  varchar(3)    NOT NULL,
    region_hdx_nom    varchar(30)   NOT NULL,
    superficie_km2    numeric(10,2) NOT NULL,
    lat_centroide     numeric(9,6)  NOT NULL,
    lon_centroide     numeric(9,6)  NOT NULL,
    lat_chef_lieu     numeric(9,6),
    lon_chef_lieu     numeric(9,6),
    cotier            boolean,
    source_fichier    varchar(300)  NOT NULL,
    source_sha256     char(64)      NOT NULL,
    date_chargement   timestamptz   NOT NULL DEFAULT now(),
    id_execution      varchar(36)   NOT NULL,

    CONSTRAINT pk_dim_gouvernorat        PRIMARY KEY (pcode),
    CONSTRAINT uq_dim_gouvernorat_nom_fr UNIQUE (nom_fr),
    CONSTRAINT uq_dim_gouvernorat_ascii  UNIQUE (nom_ascii),
    CONSTRAINT ck_pcode_format           CHECK (pcode ~ '^TN[1-6][1-9]$'),
    CONSTRAINT ck_region_format          CHECK (region_hdx_pcode ~ '^TN[1-6]$'),
    CONSTRAINT ck_pcode_dans_region      CHECK (left(pcode, 3) = region_hdx_pcode),
    CONSTRAINT ck_nom_ar_sans_tatweel    CHECK (strpos(nom_ar, chr(1600)) = 0),  -- U+0640
    CONSTRAINT ck_nom_ascii              CHECK (nom_ascii ~ '^[A-Za-z][A-Za-z '' -]*$'),
    CONSTRAINT ck_district               CHECK (district_num BETWEEN 1 AND 5),
    CONSTRAINT ck_superficie             CHECK (superficie_km2 > 0),
    -- Emprise de la Tunisie, avec une marge : environ 30 à 38 °N, 7 à 12 °E
    CONSTRAINT ck_centroide_tunisie      CHECK (lat_centroide BETWEEN 30 AND 38 AND lon_centroide BETWEEN 7 AND 12),
    CONSTRAINT ck_chef_lieu_tunisie      CHECK (lat_chef_lieu BETWEEN 30 AND 38 AND lon_chef_lieu BETWEEN 7 AND 12),
    CONSTRAINT ck_chef_lieu_complet      CHECK ((lat_chef_lieu IS NULL) = (lon_chef_lieu IS NULL)),
    CONSTRAINT ck_sha256                 CHECK (source_sha256 ~ '^[0-9a-f]{64}$')
);

COMMENT ON TABLE  dwh.dim_gouvernorat                  IS 'Référentiel des 24 gouvernorats. Clé unique de l''entrepôt : le P-code HDX (niveau administratif 2).';
COMMENT ON COLUMN dwh.dim_gouvernorat.pcode            IS 'P-code HDX du gouvernorat (TN11 à TN63), repris de adm2_pcode. Clé primaire.';
COMMENT ON COLUMN dwh.dim_gouvernorat.nom_fr           IS 'Nom français, tel que publié par HDX (adm2_name), accents compris.';
COMMENT ON COLUMN dwh.dim_gouvernorat.nom_ar           IS 'Nom arabe (adm2_name1), nettoyé : caractères d''allongement (tatweel) supprimés, espaces superflus retirés. Forme brute dans staging.stg_hdx_admin2.';
COMMENT ON COLUMN dwh.dim_gouvernorat.nom_ascii        IS 'Nom sans accents (adm2_ref_name). Sert au rapprochement des libellés sources (D-002).';
COMMENT ON COLUMN dwh.dim_gouvernorat.district_num     IS 'Numéro du district (1 à 5), décret n° 2023-589 du 21 septembre 2023 (D-004).';
COMMENT ON COLUMN dwh.dim_gouvernorat.district_libelle IS 'Libellé du district (ex. Premier district).';
COMMENT ON COLUMN dwh.dim_gouvernorat.region_hdx_pcode IS 'P-code de la grande région HDX (TN1 à TN6). Attribut secondaire (D-004).';
COMMENT ON COLUMN dwh.dim_gouvernorat.region_hdx_nom   IS 'Nom de la grande région HDX (libellé anglais publié par HDX).';
COMMENT ON COLUMN dwh.dim_gouvernorat.superficie_km2   IS 'Superficie en km², calculée par HDX, arrondie à 2 décimales.';
COMMENT ON COLUMN dwh.dim_gouvernorat.lat_centroide    IS 'Latitude du centroïde HDX (WGS 84). Usage : étiquettes de carte (D-003).';
COMMENT ON COLUMN dwh.dim_gouvernorat.lon_centroide    IS 'Longitude du centroïde HDX (WGS 84). Usage : étiquettes de carte (D-003).';
COMMENT ON COLUMN dwh.dim_gouvernorat.lat_chef_lieu    IS 'Latitude de la ville chef-lieu (géocodage Open-Meteo / GeoNames). Usage : appels météo (D-003). Vide tant que J14 n''a pas tourné.';
COMMENT ON COLUMN dwh.dim_gouvernorat.lon_chef_lieu    IS 'Longitude de la ville chef-lieu (géocodage Open-Meteo / GeoNames). Usage : appels météo (D-003).';
COMMENT ON COLUMN dwh.dim_gouvernorat.cotier           IS 'Vrai si le gouvernorat a une façade maritime (D-008). Vide tant que la règle n''est pas validée.';
COMMENT ON COLUMN dwh.dim_gouvernorat.source_fichier   IS 'Fichier source HDX, chemin relatif au dépôt.';
COMMENT ON COLUMN dwh.dim_gouvernorat.source_sha256    IS 'Empreinte SHA-256 du fichier source, reprise de data/manifest_telechargements.csv.';
COMMENT ON COLUMN dwh.dim_gouvernorat.date_chargement  IS 'Date et heure du dernier chargement de la ligne.';
COMMENT ON COLUMN dwh.dim_gouvernorat.id_execution     IS 'Identifiant de l''exécution Talend qui a chargé la ligne.';
