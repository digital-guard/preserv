-- dl05s_main: insere municipios da Argentina em optim.jurisdiction / jurisdiction_geom / jurisdiction_geom_buffer e calcula info.
-- Pre-requisito: tmp_orig.ar_jurisdiction_l3 (gerada por ar_jurisdiction_l3_candidates.sql + ar_jurisdiction_l3_final.sql em ingestar
-- e copiada com pg_dump). Rodar:  psql postgres://postgres@localhost/dl05s_main -f ar_jurisdiction_l3_insert.sql
\set ON_ERROR_STOP on
BEGIN;

-- San Lorenzo (Salta) traz no OSM o wikidata da provincia (Q44803): fica sem wikidata
UPDATE tmp_orig.ar_jurisdiction_l3 SET wikidata_id = NULL, jurisd_local_id = -osm_id WHERE osm_id = 7274360;

INSERT INTO optim.jurisdiction (osm_id, jurisd_base_id, jurisd_local_id, parent_id, admin_level, name, parent_abbrev, abbrev, wikidata_id, lexlabel, isolabel_ext, isolevel)
SELECT osm_id, jurisd_base_id, jurisd_local_id, parent_id, admin_level, name, parent_abbrev, abbrev, wikidata_id, lexlabel, isolabel_ext, isolevel
FROM tmp_orig.ar_jurisdiction_l3;

INSERT INTO optim.jurisdiction_geom (osm_id, isolabel_ext, geom)
SELECT osm_id, isolabel_ext, geom FROM tmp_orig.ar_jurisdiction_l3;

-- buffer de 50 m (isolevel 3), mesma formula do comentario em optim-step1-ini.sql
INSERT INTO optim.jurisdiction_geom_buffer (osm_id, isolabel_ext, geom)
SELECT osm_id, isolabel_ext, ST_Transform(ST_SimplifyPreserveTopology(ST_Buffer(ST_Transform(geom, 3395), 50), 5), 4326)
FROM tmp_orig.ar_jurisdiction_l3;

-- metricas padrao (optim-step6-metrics.sql)
UPDATE optim.jurisdiction j
SET info = COALESCE(j.info,'{}'::jsonb) || (to_jsonb(t) - 'osm_id' - 'isolabel_ext')
FROM optim.vw03prepare_jurisdiction_metrics1 t
WHERE t.osm_id = j.osm_id AND j.osm_id IN (SELECT osm_id FROM tmp_orig.ar_jurisdiction_l3);

UPDATE optim.jurisdiction j
SET info = COALESCE(j.info,'{}'::jsonb) || jsonb_build_object('elongation_factor', t.elong_deg_mixfactor)
FROM optim.vw04prepare_jurisdiction_shapemetrics t
WHERE t.osm_id = j.osm_id AND t.elongation_factor_deg > 0 AND j.osm_id IN (SELECT osm_id FROM tmp_orig.ar_jurisdiction_l3);

\echo ### verificacao dentro da transacao (esperado: 2138 em todas as colunas, menos elongation que pode ser um pouco menor)
SELECT (SELECT count(*) FROM optim.jurisdiction WHERE jurisd_base_id=32 AND isolevel=3) jurisdiction_ar_l3,
       (SELECT count(*) FROM optim.jurisdiction_geom g JOIN optim.jurisdiction j USING (osm_id) WHERE j.jurisd_base_id=32 AND j.isolevel=3) geom,
       (SELECT count(*) FROM optim.jurisdiction_geom_buffer b JOIN optim.jurisdiction j USING (osm_id) WHERE j.jurisd_base_id=32 AND j.isolevel=3) buffer,
       (SELECT count(*) FROM optim.jurisdiction WHERE jurisd_base_id=32 AND isolevel=3 AND info ? 'area_km2') com_area,
       (SELECT count(*) FROM optim.jurisdiction WHERE jurisd_base_id=32 AND isolevel=3 AND info ? 'elongation_factor') com_elongation;
SELECT isolabel_ext, osm_id, admin_level, parent_id, wikidata_id, info FROM optim.jurisdiction WHERE isolabel_ext IN ('AR-X-VillaGiardino','AR-B-CoronelSuarez','AR-X-JesusMaria','AR-B-SanMiguel');

COMMIT;
