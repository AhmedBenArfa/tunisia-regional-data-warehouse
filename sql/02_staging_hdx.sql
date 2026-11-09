-- =============================================================================
-- 02_staging_hdx.sql
-- Zone de transit du référentiel HDX, niveau gouvernorat (feuille tun_admin2).
--
-- Principe : copie fidèle de la source. Aucune contrainte métier, aucun
-- nettoyage (le nom arabe y garde ses caractères d'allongement). Les contrôles
-- et les transformations sont faits par J01_Referentiel_Geo entre staging et dwh.
-- La table est vidée à chaque exécution de J01.
--
-- Exécution :  psql -f sql/02_staging_hdx.sql
-- =============================================================================

\set ON_ERROR_STOP on
\encoding UTF8

CREATE TABLE IF NOT EXISTS staging.stg_hdx_admin2 (
    -- Colonnes de la source, noms d'origine conservés
    adm2_pcode       varchar(20),
    adm2_name        varchar(100),
    adm2_name1       varchar(100),
    adm2_ref_name    varchar(100),
    adm1_pcode       varchar(20),
    adm1_name        varchar(100),
    area_sqkm        numeric,
    center_lat       numeric,
    center_lon       numeric,
    valid_on         date,
    version          varchar(20),
    -- Colonnes techniques ajoutées au chargement
    source_fichier   varchar(300) NOT NULL,
    source_feuille   varchar(50)  NOT NULL,
    source_ligne     integer      NOT NULL,
    id_execution     varchar(36)  NOT NULL,
    date_chargement  timestamptz  NOT NULL DEFAULT now()
);

COMMENT ON TABLE  staging.stg_hdx_admin2                IS 'Copie fidèle de la feuille tun_admin2 (24 gouvernorats) du fichier HDX tun_admin_boundaries.xlsx. Aucun nettoyage.';
COMMENT ON COLUMN staging.stg_hdx_admin2.adm2_pcode     IS 'P-code du gouvernorat (ex. TN21).';
COMMENT ON COLUMN staging.stg_hdx_admin2.adm2_name      IS 'Nom du gouvernorat en français (lang = fr).';
COMMENT ON COLUMN staging.stg_hdx_admin2.adm2_name1     IS 'Nom du gouvernorat en arabe (lang1 = ar), forme brute : peut contenir des caractères d''allongement (tatweel, U+0640).';
COMMENT ON COLUMN staging.stg_hdx_admin2.adm2_ref_name  IS 'Nom du gouvernorat sans accents.';
COMMENT ON COLUMN staging.stg_hdx_admin2.adm1_pcode     IS 'P-code de la grande région HDX (TN1 à TN6).';
COMMENT ON COLUMN staging.stg_hdx_admin2.adm1_name      IS 'Nom de la grande région HDX (libellé anglais, ex. North West).';
COMMENT ON COLUMN staging.stg_hdx_admin2.area_sqkm      IS 'Superficie en km², calculée par HDX.';
COMMENT ON COLUMN staging.stg_hdx_admin2.center_lat     IS 'Latitude du centroïde (degrés décimaux, WGS 84).';
COMMENT ON COLUMN staging.stg_hdx_admin2.center_lon     IS 'Longitude du centroïde (degrés décimaux, WGS 84).';
COMMENT ON COLUMN staging.stg_hdx_admin2.valid_on       IS 'Date de validité du découpage administratif.';
COMMENT ON COLUMN staging.stg_hdx_admin2.version        IS 'Version du jeu HDX.';
COMMENT ON COLUMN staging.stg_hdx_admin2.source_fichier IS 'Chemin du fichier source, relatif à la racine du dépôt.';
COMMENT ON COLUMN staging.stg_hdx_admin2.source_feuille IS 'Feuille Excel lue.';
COMMENT ON COLUMN staging.stg_hdx_admin2.source_ligne   IS 'Numéro de la ligne de données dans la feuille (1 = première ligne après l''en-tête).';
COMMENT ON COLUMN staging.stg_hdx_admin2.id_execution   IS 'Identifiant de l''exécution Talend qui a chargé la ligne.';
