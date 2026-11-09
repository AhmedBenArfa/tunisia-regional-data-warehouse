-- =============================================================================
-- 00_creation_base.sql
-- Création de l'utilisateur applicatif, de la base et des schémas de l'entrepôt.
--
-- À exécuter une seule fois, avec un compte superutilisateur :
--   psql -U postgres -h localhost -f sql/00_creation_base.sql
--
-- Le mot de passe de dwh_user est demandé de façon interactive (\password) :
-- il n'apparaît ni dans ce fichier ni dans l'historique du terminal.
-- Le script peut être relancé sans erreur : les objets existants sont conservés.
-- =============================================================================

\set ON_ERROR_STOP on
\encoding UTF8

-- 1. Utilisateur applicatif -----------------------------------------------------
-- Propriétaire de la base, sans droit d'administration du serveur.
SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dwh_user') AS role_existe \gset
\if :role_existe
    \echo 'Le rôle dwh_user existe déjà : création ignorée.'
\else
    CREATE ROLE dwh_user LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
    \echo 'Saisis le mot de passe de dwh_user (à reporter ensuite dans le fichier .env) :'
    \password dwh_user
\endif

-- 2. Base de données ------------------------------------------------------------
SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'tunisia_dwh') AS base_existe \gset
\if :base_existe
    \echo 'La base tunisia_dwh existe déjà : création ignorée.'
\else
    CREATE DATABASE tunisia_dwh
        OWNER    dwh_user
        ENCODING 'UTF8'
        TEMPLATE template0;
\endif

COMMENT ON DATABASE tunisia_dwh IS
    'Observatoire des disparités régionales en Tunisie : entrepôt intégrant des sources publiques par gouvernorat.';

-- Seul dwh_user (et les superutilisateurs) peuvent se connecter.
REVOKE ALL ON DATABASE tunisia_dwh FROM PUBLIC;

-- 3. Schémas --------------------------------------------------------------------
\connect tunisia_dwh

REVOKE CREATE ON SCHEMA public FROM PUBLIC;

CREATE SCHEMA IF NOT EXISTS staging AUTHORIZATION dwh_user;
CREATE SCHEMA IF NOT EXISTS dwh     AUTHORIZATION dwh_user;
CREATE SCHEMA IF NOT EXISTS audit   AUTHORIZATION dwh_user;

COMMENT ON SCHEMA staging IS 'Zone de transit : données sources chargées telles quelles, avant contrôle et rapprochement.';
COMMENT ON SCHEMA dwh     IS 'Entrepôt : dimensions, table de faits, référentiels et vues pour Power BI.';
COMMENT ON SCHEMA audit   IS 'Traçabilité : journal des exécutions ETL et lignes rejetées.';

-- 4. Vérification ---------------------------------------------------------------
\echo 'Schémas créés dans tunisia_dwh :'
SELECT nspname AS schema, pg_get_userbyid(nspowner) AS proprietaire
FROM pg_namespace
WHERE nspname IN ('staging', 'dwh', 'audit')
ORDER BY nspname;
