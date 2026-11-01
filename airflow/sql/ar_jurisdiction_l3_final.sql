-- ingestar: tabela final de municipios da Argentina no formato de optim.jurisdiction (+ geom)
DROP TABLE IF EXISTS tmp_orig.ar_jurisdiction_l3;
DROP TABLE IF EXISTS tmp_orig.ar_jurisdiction_l3_dropped;

CREATE TABLE tmp_orig.ar_jurisdiction_l3_all AS
WITH base AS (
  SELECT t.*,
         replace(iso,'AR-','') AS abbrev_prov,
         -- CABA: as comunas chamam-se "Comuna N"; manter o nome original
         CASE WHEN iso = 'AR-C' THEN name ELSE regexp_replace(replace(name_clean,' - ',' '), '\s+', ' ', 'g') END AS name_final,
         CASE WHEN osm_id = 9433688 THEN 48288 ELSE wikidata_id END AS wikidata_final,   -- Jesús María: donor.csv
         -- prioridade do tipo de entidade em empates de nome: Municipio > Comuna > Partido/Departamento > Junta/Comision > sem prefixo
         CASE WHEN name ~* '^(Municipio|Municipalidad)' THEN 1
              WHEN name ~* '^Comuna' THEN 2
              WHEN name ~* '^(Partido|Departamento)' THEN 3
              WHEN name ~* '^(Junta|Comisi)' THEN 4
              ELSE 5 END AS prio
  FROM tmp_ar_l3 t
), lex AS (
  SELECT *, lib.name2lex(name_final, true, true, true) AS lex1,
            trim(both '.' from regexp_replace(lower(unaccent(name_final)), '[^a-z0-9]+', '.', 'g')) AS lex_full
  FROM base
), ranked0 AS (
  SELECT *, row_number() OVER (PARTITION BY iso, lex1 ORDER BY prio, km2 DESC, (wikidata_final IS NULL), osm_id) AS rn0,
            first_value(name_final) OVER (PARTITION BY iso, lex1 ORDER BY prio, km2 DESC, (wikidata_final IS NULL), osm_id) AS kept_name
  FROM lex
), lex2 AS (
  -- mesmo lex1 mas nome diferente (ex. "Villa de María" x "Villa María"): mantem os dois, o segundo com lexlabel completo
  SELECT *, CASE WHEN rn0 > 1 AND name_final <> kept_name THEN lex_full ELSE lex1 END AS lexlabel FROM ranked0
), ranked AS (
  SELECT *, row_number() OVER (PARTITION BY iso, lexlabel ORDER BY prio, km2 DESC, (wikidata_final IS NULL), osm_id) AS rn,
            count(*)     OVER (PARTITION BY iso, lexlabel) AS n_same
  FROM lex2
)
SELECT osm_id,
       32::int                                   AS jurisd_base_id,
       coalesce(wikidata_final, -osm_id)::int    AS jurisd_local_id,
       prov_osm_id                               AS parent_id,
       admin_level::smallint                     AS admin_level,
       name_final                                AS name,
       abbrev_prov                               AS parent_abbrev,
       NULL::text                                AS abbrev,
       wikidata_final                            AS wikidata_id,
       lexlabel,
       'AR-' || abbrev_prov || '-' ||
         (SELECT string_agg(initcap(p), '' ORDER BY ord) FROM unnest(string_to_array(lexlabel,'.')) WITH ORDINALITY u(p, ord)) AS isolabel_ext,
       3::int                                    AS isolevel,
       iso, name AS osm_name, km2, rn, n_same,
       ST_Multi(ST_MakeValid(geom))::geometry(MultiPolygon,4326) AS geom
FROM ranked;

CREATE TABLE tmp_orig.ar_jurisdiction_l3 AS SELECT * FROM tmp_orig.ar_jurisdiction_l3_all WHERE rn = 1;
CREATE TABLE tmp_orig.ar_jurisdiction_l3_dropped AS
  SELECT d.osm_id, d.iso, d.osm_name, d.km2, d.wikidata_id, k.osm_id AS kept_osm_id, k.osm_name AS kept_name, k.km2 AS kept_km2
  FROM tmp_orig.ar_jurisdiction_l3_all d JOIN tmp_orig.ar_jurisdiction_l3_all k ON k.iso=d.iso AND k.lexlabel=d.lexlabel AND k.rn=1
  WHERE d.rn > 1;
DROP TABLE tmp_orig.ar_jurisdiction_l3_all;

\echo ### totais
SELECT count(*) total, count(wikidata_id) com_wikidata, count(*) FILTER (WHERE NOT ST_IsValid(geom)) geom_invalida,
       count(*) FILTER (WHERE length(name)>=60) nome_longo, count(DISTINCT isolabel_ext) isolabel_distintos,
       count(DISTINCT (jurisd_base_id, jurisd_local_id)) localid_distintos, count(DISTINCT wikidata_id) wd_distintos
FROM tmp_orig.ar_jurisdiction_l3;
\echo ### descartados por conflito de nome
SELECT iso, osm_id, osm_name, km2, kept_osm_id, kept_name, kept_km2 FROM tmp_orig.ar_jurisdiction_l3_dropped ORDER BY 1,3;
\echo ### amostra (doadores + 6 aleatorios)
SELECT isolabel_ext, osm_id, admin_level, name, lexlabel, jurisd_local_id, wikidata_id, parent_abbrev, km2 FROM tmp_orig.ar_jurisdiction_l3
WHERE osm_id IN (9461241, 9433688, 2594942, 2430369) ORDER BY 1;
SELECT isolabel_ext, name, lexlabel, jurisd_local_id FROM tmp_orig.ar_jurisdiction_l3 ORDER BY random() LIMIT 6;
