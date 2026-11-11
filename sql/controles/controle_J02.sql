-- =============================================================================
-- controle_J02.sql
-- Contrôles après exécution du job J02_Synonymes.
--
--   psql -f sql/controles/controle_J02.sql
--
-- Lecture seule : aucune requête ne modifie la base.
-- La comparaison avec le calcul Python indépendant de la normalisation se fait
-- avec scripts/normaliser_libelle.py (voir le guide du job J02).
-- =============================================================================

\encoding UTF8

\echo '== 1. Volumes par type de libellé (attendu : nom_fr 24, nom_ar 24, variante = lignes de synonymes_geo.csv)'
SELECT type_libelle, count(*) AS lignes, count(DISTINCT pcode) AS gouvernorats
FROM dwh.ref_synonyme_geo
GROUP BY type_libelle
ORDER BY type_libelle;

\echo '== 2. Une seule exécution dans la table (rechargement complet)'
SELECT count(*) AS lignes, count(DISTINCT id_execution) AS executions, min(date_chargement) AS chargement
FROM dwh.ref_synonyme_geo;

\echo '== 3. Gouvernorats sans nom français ou sans nom arabe dans la table (attendu : aucune ligne)'
SELECT d.pcode, d.nom_fr
FROM dwh.dim_gouvernorat d
WHERE NOT EXISTS (SELECT 1 FROM dwh.ref_synonyme_geo s WHERE s.pcode = d.pcode AND s.type_libelle = 'nom_fr')
   OR NOT EXISTS (SELECT 1 FROM dwh.ref_synonyme_geo s WHERE s.pcode = d.pcode AND s.type_libelle = 'nom_ar');

\echo '== 4. Une même forme normalisée rattachée à plusieurs P-codes, toutes portées confondues (attendu : aucune ligne)'
SELECT libelle_normalise, string_agg(DISTINCT pcode, ', ') AS pcodes
FROM dwh.ref_synonyme_geo
GROUP BY libelle_normalise
HAVING count(DISTINCT pcode) > 1;

\echo '== 5. Variantes chargées, avec leur origine'
SELECT libelle_source, libelle_normalise, pcode, origine
FROM dwh.ref_synonyme_geo
WHERE type_libelle = 'variante'
ORDER BY pcode, libelle_source;

\echo '== 6. Rejets de la dernière exécution de J02 (attendu : aucune ligne avec les vrais fichiers)'
SELECT etape, cle_source, motif
FROM audit.etl_rejets
WHERE job = 'J02_Synonymes'
  AND id_execution = (SELECT max(id_execution) FROM dwh.ref_synonyme_geo)
ORDER BY id_rejet;
