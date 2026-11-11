-- =============================================================================
-- 04_dwh_ref_synonyme_geo.sql
-- Table de synonymes géographiques : libellé source -> P-code du gouvernorat.
--
--   psql -f sql/04_dwh_ref_synonyme_geo.sql
--
-- Alimentée par le job J02_Synonymes (rechargement complet à chaque exécution),
-- à partir de dwh.dim_gouvernorat (noms officiels HDX) et de
-- data/reference/synonymes_geo.csv (variantes observées dans les sources).
-- Règles de normalisation et de portée : décision D-012.
-- =============================================================================

\set ON_ERROR_STOP on
\encoding UTF8

CREATE TABLE IF NOT EXISTS dwh.ref_synonyme_geo (
    source             varchar(30)   NOT NULL DEFAULT '*',
    tableau            varchar(60)   NOT NULL DEFAULT '*',
    libelle_normalise  varchar(100)  NOT NULL,
    libelle_source     varchar(100)  NOT NULL,
    pcode              varchar(4)    NOT NULL,
    type_libelle       varchar(10)   NOT NULL,
    origine            varchar(400)  NOT NULL,
    date_chargement    timestamptz   NOT NULL DEFAULT now(),
    id_execution       varchar(36)   NOT NULL,

    CONSTRAINT pk_ref_synonyme_geo        PRIMARY KEY (source, tableau, libelle_normalise),
    CONSTRAINT fk_synonyme_gouvernorat    FOREIGN KEY (pcode) REFERENCES dwh.dim_gouvernorat (pcode),
    CONSTRAINT ck_synonyme_type           CHECK (type_libelle IN ('nom_fr', 'nom_ar', 'nom_ascii', 'variante')),
    CONSTRAINT ck_synonyme_normalise      CHECK (libelle_normalise = btrim(libelle_normalise)
                                                 AND libelle_normalise <> ''
                                                 AND libelle_normalise !~ '[A-Z]'
                                                 AND libelle_normalise !~ '  '
                                                 AND strpos(libelle_normalise, chr(1600)) = 0),
    CONSTRAINT ck_synonyme_portee         CHECK (source <> '' AND tableau <> '')
);

CREATE INDEX IF NOT EXISTS ix_ref_synonyme_geo_pcode ON dwh.ref_synonyme_geo (pcode);

COMMENT ON TABLE  dwh.ref_synonyme_geo                   IS 'Synonymes géographiques : chaque libellé de gouvernorat rencontré dans une source, rattaché à son P-code HDX (D-012). Rechargée entièrement par J02_Synonymes.';
COMMENT ON COLUMN dwh.ref_synonyme_geo.source            IS 'Source à laquelle le synonyme s''applique ; * = toutes les sources.';
COMMENT ON COLUMN dwh.ref_synonyme_geo.tableau           IS 'Tableau de la source auquel le synonyme s''applique ; * = tous les tableaux. Permet de traiter un libellé ambigu propre à un tableau.';
COMMENT ON COLUMN dwh.ref_synonyme_geo.libelle_normalise IS 'Forme de comparaison : minuscules, sans accents ni signes diacritiques arabes, sans tatweel, ponctuation remplacée par une espace (routine Talend Libelles.normaliser, D-012). Clé de recherche des jobs.';
COMMENT ON COLUMN dwh.ref_synonyme_geo.libelle_source    IS 'Libellé tel qu''il apparaît dans la source (premier rencontré pour cette forme normalisée).';
COMMENT ON COLUMN dwh.ref_synonyme_geo.pcode             IS 'P-code HDX du gouvernorat (référence dwh.dim_gouvernorat).';
COMMENT ON COLUMN dwh.ref_synonyme_geo.type_libelle      IS 'nom_fr, nom_ar, nom_ascii : noms officiels HDX ; variante : graphie observée dans une source (data/reference/synonymes_geo.csv).';
COMMENT ON COLUMN dwh.ref_synonyme_geo.origine           IS 'Où le libellé a été observé : fichier, page ou feuille.';
COMMENT ON COLUMN dwh.ref_synonyme_geo.id_execution      IS 'Identifiant de l''exécution Talend qui a chargé la ligne.';
