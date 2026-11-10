-- =============================================================================
-- controle_J01.sql
-- Contrôles après exécution du job J01_Referentiel_Geo.
--
--   psql -f sql/controles/controle_J01.sql
--
-- Lecture seule : aucune requête ne modifie la base.
-- =============================================================================

\encoding UTF8

\echo '== 1. staging.stg_hdx_admin2 : volumes et traçabilité (attendu : 24 / 24 / 1 / 24 / 1)'
SELECT count(*)                         AS lignes,
       count(DISTINCT adm2_pcode)       AS pcodes_distincts,
       min(source_ligne)                AS premiere_ligne,
       max(source_ligne)                AS derniere_ligne,
       count(DISTINCT id_execution)     AS executions,
       min(valid_on)                    AS valid_on_min,
       max(valid_on)                    AS valid_on_max,
       round(sum(area_sqkm)::numeric, 1) AS superficie_totale_km2
FROM staging.stg_hdx_admin2;

\echo '== 2. staging : noms arabes contenant un tatweel (U+0640), forme brute conservée'
SELECT source_ligne, adm2_pcode, adm2_name, adm2_name1
FROM staging.stg_hdx_admin2
WHERE strpos(adm2_name1, chr(1600)) > 0;

\echo '== 3. staging : valeurs manquantes dans les colonnes utiles (attendu : aucune ligne)'
SELECT source_ligne, adm2_pcode
FROM staging.stg_hdx_admin2
WHERE adm2_pcode IS NULL OR adm2_name IS NULL OR adm2_name1 IS NULL OR adm2_ref_name IS NULL
   OR adm1_pcode IS NULL OR area_sqkm IS NULL OR center_lat IS NULL OR center_lon IS NULL;

\echo '== 4. dwh.dim_gouvernorat : volumes (attendu : 24 lignes, 5 districts, 6 régions)'
SELECT count(*)                          AS lignes,
       count(DISTINCT district_num)      AS districts,
       count(DISTINCT region_hdx_pcode)  AS regions_hdx,
       count(lat_chef_lieu)              AS chefs_lieux_renseignes,
       count(cotier)                     AS cotier_renseigne
FROM dwh.dim_gouvernorat;

\echo '== 5. Gouvernorats présents en staging mais absents de la dimension (attendu : aucune ligne)'
SELECT s.adm2_pcode, s.adm2_name
FROM staging.stg_hdx_admin2 s
LEFT JOIN dwh.dim_gouvernorat d ON d.pcode = s.adm2_pcode
WHERE d.pcode IS NULL;

\echo '== 6. Rejets de la dernière exécution de J01'
SELECT etape, motif, count(*) AS lignes
FROM audit.etl_rejets
WHERE job = 'J01_Referentiel_Geo'
  AND id_execution = (SELECT max(id_execution) FROM staging.stg_hdx_admin2)
GROUP BY etape, motif;
