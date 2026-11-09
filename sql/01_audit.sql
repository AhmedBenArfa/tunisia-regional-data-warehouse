-- =============================================================================
-- 01_audit.sql
-- Tables de traçabilité : journal des exécutions et lignes rejetées.
--
-- Exécution (avec les variables du fichier .env) :
--   psql -f sql/01_audit.sql
-- Le script peut être relancé : les objets existants sont conservés.
-- =============================================================================

\set ON_ERROR_STOP on
\encoding UTF8

-- Journal des exécutions : une ligne par job et par exécution -------------------
CREATE TABLE IF NOT EXISTS audit.etl_run_log (
    id_execution     varchar(36)  NOT NULL,
    job              varchar(100) NOT NULL,
    debut            timestamptz  NOT NULL,
    fin              timestamptz,
    statut           varchar(20)  NOT NULL DEFAULT 'EN_COURS'
                     CHECK (statut IN ('EN_COURS', 'SUCCES', 'ECHEC')),
    lignes_lues      integer      CHECK (lignes_lues      >= 0),
    lignes_chargees  integer      CHECK (lignes_chargees  >= 0),
    lignes_rejetees  integer      CHECK (lignes_rejetees  >= 0),
    message          text,
    CONSTRAINT pk_etl_run_log PRIMARY KEY (id_execution, job)
);

COMMENT ON TABLE  audit.etl_run_log                 IS 'Journal des exécutions ETL : une ligne par job et par exécution.';
COMMENT ON COLUMN audit.etl_run_log.id_execution    IS 'Identifiant d''exécution fourni par Talend (pid du job, ou root_pid quand le job est lancé par J00_Master).';
COMMENT ON COLUMN audit.etl_run_log.job             IS 'Nom du job Talend (ex. J01_Referentiel_Geo).';
COMMENT ON COLUMN audit.etl_run_log.statut          IS 'EN_COURS, SUCCES ou ECHEC.';
COMMENT ON COLUMN audit.etl_run_log.lignes_lues     IS 'Nombre de lignes lues dans la source.';
COMMENT ON COLUMN audit.etl_run_log.lignes_chargees IS 'Nombre de lignes insérées ou mises à jour dans la table cible.';
COMMENT ON COLUMN audit.etl_run_log.lignes_rejetees IS 'Nombre de lignes envoyées dans audit.etl_rejets.';

-- Lignes rejetées : une ligne par enregistrement refusé -------------------------
CREATE TABLE IF NOT EXISTS audit.etl_rejets (
    id_rejet        bigint       GENERATED ALWAYS AS IDENTITY,
    id_execution    varchar(36)  NOT NULL,
    job             varchar(100) NOT NULL,
    etape           varchar(100) NOT NULL,
    source_fichier  varchar(300),
    cle_source      varchar(200),
    ligne_brute     text,
    motif           text         NOT NULL,
    date_rejet      timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT pk_etl_rejets PRIMARY KEY (id_rejet)
);

CREATE INDEX IF NOT EXISTS ix_etl_rejets_execution ON audit.etl_rejets (id_execution, job);

COMMENT ON TABLE  audit.etl_rejets              IS 'Lignes refusées par les contrôles des jobs, avec le motif du rejet. Alimente la revue manuelle (ex. nouveaux synonymes).';
COMMENT ON COLUMN audit.etl_rejets.etape        IS 'Composant ou contrôle à l''origine du rejet (ex. tMap_controles).';
COMMENT ON COLUMN audit.etl_rejets.cle_source   IS 'Identifiant de la ligne dans la source (code, libellé, numéro de ligne).';
COMMENT ON COLUMN audit.etl_rejets.ligne_brute  IS 'Contenu de la ligne rejetée, tel que lu (champs séparés par « | »).';
COMMENT ON COLUMN audit.etl_rejets.motif        IS 'Raison du rejet, en clair.';
