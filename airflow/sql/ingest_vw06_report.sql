-- View de validacao da ingestao, usada pelos scripts airflow/python01..03.
-- Aplicar no banco de ingestao:  psql postgres://postgres@localhost/ingest20 < ingest_vw06_report.sql
-- Uma linha por componente (layer ingerido), com contagens de feature_asis,
-- descartes por motivo (bits do error_mask) e resumo do lineage.

CREATE OR REPLACE VIEW ingest.vw06ingest_report AS
SELECT v.isolabel_ext,
       v.pack_id,
       v.packvers_id,
       v.id                                   AS file_id,
       v.ftid,
       v.ftname,
       v.geomtype,
       v.proc_step,
       (v.lineage->'statistics'->>0)::bigint  AS n_original,
       fa.n                                   AS n_feature_asis,
       COALESCE(fad.n, 0)                     AS n_discarded,
       ROUND(100.0 * COALESCE(fad.n, 0) / NULLIF((v.lineage->'statistics'->>0)::bigint, 0), 2) AS pct_discarded,
       d.duplicate, d.nointersects, d.invalid, d.nosimple, d.empty, d.small, d."null", d.invalid_type, d.noclosed, d.large,
       (v.lineage->'feature_asis_summary'->>'n')::bigint        AS n_summary,
       v.lineage->'feature_asis_summary'->>'n_unit'             AS n_unit,
       (v.lineage->'feature_asis_summary'->>'size')::numeric    AS size,
       v.lineage->'feature_asis_summary'->>'size_unit'          AS size_unit,
       (v.lineage->'feature_asis_summary'->>'bbox_km2')::numeric AS bbox_km2,
       v.lineage->'file_meta'->>'file'                          AS source_file,
       (v.lineage->'file_meta'->>'modification')::timestamptz   AS source_modification,
       v.lineage->'hcode_distribution_parameters'               AS hcode_params,
       v.lineage_md5,
       v.kx_profile
FROM ingest.vw03full_layer_file v
LEFT JOIN (SELECT file_id, count(*) AS n FROM ingest.feature_asis GROUP BY 1)           fa  ON fa.file_id  = v.id
LEFT JOIN (SELECT file_id, count(*) AS n FROM ingest.feature_asis_discarded GROUP BY 1) fad ON fad.file_id = v.id
LEFT JOIN ingest.vwreport_geometries_discarded d ON d.id = v.id
ORDER BY v.isolabel_ext, v.packvers_id, v.ftid;

COMMENT ON VIEW ingest.vw06ingest_report IS
  'Relatorio de validacao por componente ingerido: contagens, descartes por motivo e resumo do lineage. Usada por airflow/python01_ingest.py.';
