-- candidatos a jurisdicao nivel 3 (municipios) da Argentina a partir de jplanet_osm_boundaries (ingestar)
-- regra: admin_level 5 (partidos/departamentos/comunas) em AR-B, AR-M, AR-J, AR-F, AR-C ; admin_level 7 (municipios/comunas) nas demais
DROP TABLE IF EXISTS tmp_ar_l3;
CREATE TABLE tmp_ar_l3 AS
WITH prov AS (
  SELECT osm_id prov_osm_id, tags->>'ISO3166-2' iso, name AS prov_name, geom
  FROM jplanet_osm_boundaries WHERE admin_level=4 AND tags->>'ISO3166-2' LIKE 'AR-%'
), cand AS (
  SELECT p.iso, p.prov_osm_id, j.osm_id, j.admin_level, j.name,
         trim(regexp_replace(j.name,
              '^(Municipio de|Municipio|Municipalidad de|Comuna Rural de|Comuna de|Comuna|Partido de|Partido|Departamento de|Departamento|Junta de Gobierno de|Junta de Gobierno|Comisi[oó]n de Fomento de|Comisi[oó]n Municipal de|Comisi[oó]n de Fomento|Delegaci[oó]n Municipal de|Comunidad de)[[:space:]]+', '')) AS name_clean,
         nullif(regexp_replace(coalesce(j.tags->>'wikidata',''), '^Q', ''), '')::bigint AS wikidata_id,
         round(st_area(j.geom::geography)/1e6) km2, j.geom
  FROM jplanet_osm_boundaries j JOIN prov p ON ST_Within(ST_PointOnSurface(j.geom), p.geom)
  WHERE (p.iso IN ('AR-B','AR-M','AR-J','AR-F','AR-C') AND j.admin_level=5)
     OR (p.iso NOT IN ('AR-B','AR-M','AR-J','AR-F','AR-C') AND j.admin_level=7)
)
SELECT *,
  lower(unaccent(regexp_replace(name_clean, '[^[:alnum:][:space:]]', '', 'g'))) AS lex_base
FROM cand;

\echo ### totais
SELECT count(*) total, count(wikidata_id) com_wikidata, count(*) FILTER (WHERE name_clean <> name) prefixo_removido FROM tmp_ar_l3;
\echo ### prefixos que restaram (primeira palavra) com >= 5 ocorrencias
SELECT split_part(name_clean,' ',1) p1, count(*) FROM tmp_ar_l3 GROUP BY 1 HAVING count(*)>=5 ORDER BY 2 DESC LIMIT 12;
\echo ### conflitos: mesmo lexlabel na mesma provincia
SELECT iso, lex_base, count(*), string_agg(osm_id::text||' '||name||' ('||km2||'km2)', ' | ') FROM tmp_ar_l3 GROUP BY 1,2 HAVING count(*)>1 ORDER BY 1,2;
\echo ### conflitos: wikidata repetido
SELECT wikidata_id, count(*) FROM tmp_ar_l3 WHERE wikidata_id IS NOT NULL GROUP BY 1 HAVING count(*)>1;
\echo ### os quatro doadores
SELECT iso, osm_id, admin_level, name, name_clean, wikidata_id, km2 FROM tmp_ar_l3
WHERE name_clean IN ('Villa Giardino','Jesús María','Coronel Suárez','San Miguel') ORDER BY 1,4;
\echo ### nomes >= 60 chars
SELECT osm_id, name FROM tmp_ar_l3 WHERE length(name_clean) >= 60;
