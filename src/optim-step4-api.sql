CREATE SCHEMA IF NOT EXISTS api;
CREATE or replace VIEW api.jurisdiction AS
SELECT osm_id,
      jurisd_base_id,
      jurisd_local_id,
      name,
      parent_abbrev,
      abbrev,
      wikidata_id,
      lexlabel,
      isolabel_ext,
      ddd,
      jsonb_strip_nulls(info)
FROM optim.jurisdiction
;
--curl "http://localhost:3103/jurisdiction?jurisd_base_id=eq.76&parent_abbrev=eq.CE" -H "Accept: text/csv"

---------

CREATE or replace VIEW api.stats_donated_packcomponent AS
SELECT *
FROM (
      SELECT pc.id,
      pc.packvers_id,
      pc.proc_step,
      pc.ftid,
      pc.is_evidence,
      (lineage->'statistics')[0]                                  AS quantidade_feicoes_bruta,
      pc.kx_profile->'date_aprroved'                              AS date_aprroved,
      pc.kx_profile->'publication_summary'->'size'                AS size,
      pc.kx_profile->'publication_summary'->'bytes'               AS bytes,
      pc.kx_profile->'publication_summary'->'itens'               AS itens,
      pc.kx_profile->'publication_summary'->'size_unit'           AS size_unit,
      pc.kx_profile->'publication_summary'->'avg_density'         AS avg_density,
      pc.kx_profile->'publication_summary'->'size_unitDensity'    AS size_unitDensity,
      ft.ftname,
      split_part(ft.ftname,'_',1)                                 AS ftname_class,
      ft.geomtype,
      ft.need_join,
      ft.description
      FROM optim.donated_PackComponent pc
      LEFT JOIN optim.feature_type ft
      ON ft.ftid = pc.ftid
      --WHERE pc.ftid > 19
) a
INNER JOIN
(
      SELECT *
      FROM tmp_orig.fdw_donorbr d
      INNER JOIN tmp_orig.fdw_donatedpackbr p
      ON d.local_id::int = p.donor_id
) b
ON substring(to_char(a.packvers_id,'FM00000000000000'),4,8) = to_char(b.pack_id,'FM00000000')
    AND substring(to_char(a.packvers_id,'FM00000000000000'),1,3) = '076'

UNION ALL

SELECT *
FROM (
      SELECT pc.id,
      pc.packvers_id,
      pc.proc_step,
      pc.ftid,
      pc.is_evidence,
      (lineage->'statistics')[0]                                  AS quantidade_feicoes_bruta,
      pc.kx_profile->'date_aprroved'                              AS date_aprroved,
      pc.kx_profile->'publication_summary'->'size'                AS size,
      pc.kx_profile->'publication_summary'->'bytes'               AS bytes,
      pc.kx_profile->'publication_summary'->'itens'               AS itens,
      pc.kx_profile->'publication_summary'->'size_unit'           AS size_unit,
      pc.kx_profile->'publication_summary'->'avg_density'         AS avg_density,
      pc.kx_profile->'publication_summary'->'size_unitDensity'    AS size_unitDensity,
      ft.ftname,
      split_part(ft.ftname,'_',1)                                 AS ftname_class,
      ft.geomtype,
      ft.need_join,
      ft.description
      FROM optim.donated_PackComponent pc
      LEFT JOIN optim.feature_type ft
      ON ft.ftid = pc.ftid
      --WHERE pc.ftid > 19
) a
INNER JOIN
(
      SELECT r.*, null, null, s.*
      FROM tmp_orig.fdw_donorco r
      INNER JOIN tmp_orig.fdw_donatedpackco s
      ON r.local_id::int = s.donor_id
) b
ON substring(to_char(a.packvers_id,'FM00000000000000'),4,8) = to_char(b.pack_id,'FM00000000')
    AND substring(to_char(a.packvers_id,'FM00000000000000'),1,3) = '170'
;
--curl "http://localhost:3103/stats_donated_packcomponent?uri_objtype=like.*email*" -H "Accept: text/csv"

---------

CREATE or replace VIEW api.jurisdiction_lexlabel AS
SELECT isolabel_ext,
CASE
    WHEN cardinality(a)=3 THEN lower(a[1] || ';' ||  lexlabel_parent || ';' || lexlabel)
    WHEN cardinality(a)=2 THEN lower(a[1] || ';' || lexlabel)
    WHEN cardinality(a)=1 THEN lower(isolabel_ext)
    ELSE NULL
END AS lex_isoinlevel1,
CASE
    WHEN cardinality(a)=3 THEN lower(a[1] || ';' ||  a[2] || ';' || lexlabel)
    WHEN cardinality(a)=2 THEN lower(a[1] || ';' || lexlabel)
    WHEN cardinality(a)=1 THEN lower(isolabel_ext)
    ELSE NULL
END AS lex_isoinlevel2,
CASE
    WHEN cardinality(a)=3 THEN lower(a[1] || ';' ||  a[2] || ';' || abbrev)
    WHEN cardinality(a)=2 THEN lower(a[1] || ';' ||  a[2])
    WHEN cardinality(a)=1 THEN lower(isolabel_ext)
    ELSE NULL
END AS lex_isoinlevel2_abbrev
FROM (
    SELECT s.isolabel_ext AS isolabel_ext_parent, s.lexlabel AS lexlabel_parent, r.isolabel_ext, r.abbrev, r.name, r.lexlabel, regexp_split_to_array (r.isolabel_ext,'(-)')::text[] AS a
    FROM optim.vw01full_jurisdiction_geom r
    LEFT JOIN optim.jurisdiction s
    ON s.isolabel_ext = (SELECT a[1]||'-'||a[2] FROM regexp_split_to_array (r.isolabel_ext,'(-)') a)
) t
;

CREATE or replace FUNCTION api.jurisdiction_geojson_from_isolabel(
   p_isolabel_ext text
) RETURNS jsonb AS $f$
    SELECT jsonb_build_object(
        'type', 'FeatureCollection',
        'features',
            (
                ST_AsGeoJSONb(
                    geom,
                    6,0,null,
                    jsonb_build_object(
                        'osm_id', osm_id,
                        'jurisd_base_id', jurisd_base_id,
                        'jurisd_local_id', jurisd_local_id,
                        'parent_id', parent_id,
                        'admin_level', admin_level,
                        'name', name,
                        'parent_abbrev', parent_abbrev,
                        'abbrev', abbrev,
                        'wikidata_id', wikidata_id,
                        'lexlabel', lexlabel,
                        'isolabel_ext', isolabel_ext,
                        'lex_urn', lex_urn,
                        'name_en', name_en,
                        'isolevel', isolevel,
                        'area', ST_Area(geom,true),
                        'jurisd_base_id', jurisd_base_id
                        )
                    )::jsonb
            )
        )
    FROM optim.vw01full_jurisdiction_geom
    WHERE isolabel_ext = p_isolabel_ext
$f$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION api.jurisdiction_geojson_from_isolabel(text)
  IS 'Return jurisdiction geojson from isolabel_ext.'
;
--SELECT api.jurisdiction_geojson_from_isolabel('BR-SP-Campinas');


CREATE or replace FUNCTION api.jurisdiction_geojson_from_lex_isoinlevel1(
   p_lex text
) RETURNS jsonb AS $f$
    SELECT api.jurisdiction_geojson_from_isolabel(( SELECT isolabel_ext FROM api.jurisdiction_lexlabel WHERE lex_isoinlevel1 = lower(p_lex) ))
$f$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION api.jurisdiction_geojson_from_lex_isoinlevel1(text)
  IS 'Return jurisdiction geojson from lex. ISO 3166-1 alpha-2 country code.'
;
--SELECT api.jurisdiction_geojson_from_lex_isoinlevel1('br;sao.paulo;campinas');

CREATE or replace FUNCTION api.jurisdiction_geojson_from_lex_isoinlevel2(
   p_lex text
) RETURNS jsonb AS $f$
    SELECT api.jurisdiction_geojson_from_isolabel(( SELECT isolabel_ext FROM api.jurisdiction_lexlabel WHERE lex_isoinlevel2 = lower(p_lex) ))
$f$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION api.jurisdiction_geojson_from_lex_isoinlevel2(text)
  IS 'Return jurisdiction geojson from lex. ISO 3166-1 alpha-2 code.'
;
--SELECT api.jurisdiction_geojson_from_lex_isoinlevel2('br;sp;campinas');

CREATE or replace FUNCTION api.jurisdiction_geojson_from_lex_isoinlevel2_abbrev(
   p_lex text
) RETURNS jsonb AS $f$
    SELECT api.jurisdiction_geojson_from_isolabel(( SELECT isolabel_ext FROM api.jurisdiction_lexlabel WHERE lex_isoinlevel2_abbrev = lower(p_lex) ))
$f$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION api.jurisdiction_geojson_from_lex_isoinlevel2_abbrev(text)
  IS 'Return jurisdiction geojson from lex. All abbrev.'
;
--SELECT api.jurisdiction_geojson_from_lex_isoinlevel2_abbrev('br;sp;cam');
--SELECT api.jurisdiction_geojson_from_lex_isoinlevel2_abbrev('br;sp');
