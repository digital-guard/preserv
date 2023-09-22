CREATE or replace VIEW optim.vw02publication AS
  SELECT g.*,
         jsonb_strip_nulls( to_jsonb(dviz.*) ) AS viz_summary,
         'a4a_' || replace(lower(g.isolabel_ext),'-','_') || '_' || g.class_ftname || '_' || g.id || '.zip' AS filtered_name,
         lower(g.isolabel_ext) || '_pk' || g.pack_number || '_' ||  g.class_ftname || '.html' AS url_page,

         (SELECT to_jsonb(j.*) FROM optim.jurisdiction j WHERE j.isolevel = 2 AND j.jurisd_base_id = g.jurisd_base_id AND j.isolabel_ext = (split_part(g.isolabel_ext,'-',1) || '-' || split_part(g.isolabel_ext,'-',2)) ) AS jurisd2,
         (SELECT to_jsonb(j.*) FROM optim.jurisdiction j WHERE j.isolevel = 1 AND j.jurisd_base_id = g.jurisd_base_id AND j.isolabel_ext =  split_part(g.isolabel_ext,'-',1) ) AS jurisd1
  FROM
  (
    SELECT pf.*, row_number() OVER (PARTITION BY pf.isolabel_ext, pf.local_serial, pf.pk_count ORDER BY pf.ftype_info->'class_ftname' ASC ) AS row_num,
    pf.ftype_info->>'class_ftname' as class_ftname,
    pf.ftype_info->'class_info'->>'shortname_pt' as shortnameftname,
    pf.ftype_info->'class_info'->>'description_pt' as descriptionftname,
    pf.make_conf_tpl->'license_evidences' AS license_evidences,


    CASE pf.geomtype
              WHEN 'poly'  THEN 'pols'
              WHEN 'line'  THEN 'lns'
              WHEN 'point' THEN 'pts'
              END AS geom_type_abbr,
    jsonb_strip_nulls(jsonb_build_object(
          'geom_type',CASE pf.geomtype
              WHEN 'poly'  THEN 'polígonos'
              WHEN 'line'  THEN 'segmentos'
              WHEN 'point' THEN 'pontos'
              END,
          'geom_unit_abr',CASE pf.geomtype
              WHEN 'poly'  THEN 'km²'
              WHEN 'line'  THEN 'km'
              ELSE  ''
              END,
          'geom_unit_ext',CASE pf.geomtype
              WHEN 'poly'  THEN 'quilômetros quadrados'
              WHEN 'line'  THEN 'quilômetros'
              ELSE  ''
              END,
              'isGeoaddress', iif(pf.ftype_info->>'class_ftname'='geoaddress','true'::jsonb,'false'::jsonb),
          'bytes_mb', (pf.kx_profile->'publication_summary'->'bytes')::bigint / 1048576.0,
          'bytes_mb_round2', ROUND(((pf.kx_profile->'publication_summary'->'bytes')::bigint / 1048576.0),0.01),
          'avg_density_round2', ROUND(((pf.kx_profile->'publication_summary'->'avg_density')::float),0.01),
          'bytes_mb_round4', ROUND(((pf.kx_profile->'publication_summary'->'bytes')::bigint / 1048576.0),0.0001),
          'avg_density_round4', ROUND(((pf.kx_profile->'publication_summary'->'avg_density')::float),0.0001),
          'size_round2',CASE
              WHEN pf.kx_profile->'publication_summary'->>'size' IS NOT NULL
              THEN ROUND(((pf.kx_profile->'publication_summary'->'size')::float),0.01)
              ELSE  NULL
              END,
          'size_round4',CASE
              WHEN pf.kx_profile->'publication_summary'->>'size' IS NOT NULL
              THEN ROUND(((pf.kx_profile->'publication_summary'->'size')::float),0.0001)
              ELSE  NULL
              END
    )) || (pf.kx_profile->'publication_summary') AS publication_summary

    FROM optim.vw01full_donated_PackComponent pf
    WHERE pf.ftid > 19

    ORDER BY pf.isolabel_ext, pf.local_serial, pf.pk_count, pf.ftype_info->>'class_ftname'
  ) g
  LEFT JOIN optim.vw01fromCutLayer_toVizLayer dviz
  ON dviz.jurisdiction_pack_layer = isolabel_ext || '/_pk' || pack_number || '/' || class_ftname
     -- AND dviz.url_layer_visualization IS NOT NULL
;
COMMENT ON VIEW optim.vw02publication
  IS 'Join optim.vw01full_packfilevers_ftype with optim.donated_PackComponent, ftid > 19.'
;

CREATE or replace VIEW optim.vw03publication_viz AS
SELECT isolabel_ext, '_pk' || pack_number AS pack_number,
    split_part(viz_summary->>'url_layer_visualization','=',2) AS viz_id,
    viz_summary->'jurisdiction_pack_layer' AS viz_id2,
    jsonb_build_object(
    'packtpl_id', packtpl_id,
    'isolabel_ext', isolabel_ext,
    'legalname', legalname,
    'vat_id', vat_id,
    'url', url,
    'wikidata_id', wikidata_id,
    'user_resp', user_resp,
    'accepted_date', pack_item_accepted_date,
    'accepted_date_ptbr', packtpl_info->>'accepted_date_ptbr',
    'accepted_date_en', packtpl_info->>'accepted_date_en',
    'accepted_date_es', packtpl_info->>'accepted_date_es',
    'path_preserv_git', path_preserv_git,
    'pack_number', pack_number,
    'path_cutgeo_git', path_cutgeo_git,
    'license_evidences',license_evidences,
    'license_data',license_data,
    'jurisd1',jurisd1,
    'jurisd2',jurisd2,
    'name', name,
    'jurisdiction_info', jurisdiction_info || jsonb_build_object('population',(jsonb_build_object('date_year',EXTRACT('Year' FROM (jurisdiction_info->'population'->>'date')::date)) || (jurisdiction_info->'population'))),
    'path_cutgeo_notree', replace(replace(path_cutgeo_git,'tree/',''),'https://git.digital-guard.org/',''),
      'id', id,
      'class_ftname', class_ftname,
      'shortnameftname', shortnameftname,
      'description', descriptionftname,
      'hashedfname', hashedfname,
      'hashedfname_without_ext', hashedfname_without_ext,
      'hashedfname_7_ext', hashedfname_7_ext,
      'isFirst', iif(row_num=1,'true'::jsonb,'false'::jsonb),
      'geom_type_abbr', geom_type_abbr,
      'publication_summary', publication_summary,
      'url_page', url_page,
      'filtered_name', filtered_name,
      'viz_summary', viz_summary,
    'initcap_ftnameviz',
      (
        CASE class_ftname
        WHEN 'block'      THEN 'City blocks'
        WHEN 'building'   THEN 'Building footprints'
        WHEN 'nsvia'      THEN 'Neighborhood boundaries'
        WHEN 'parcel'     THEN 'Land parcels'
        WHEN 'via'        THEN 'Road network'
        WHEN 'geoaddress' THEN 'Address points'
        END
      ),
    'ftnameviz',
      (
        CASE class_ftname
        WHEN 'block'      THEN 'city blocks'
        WHEN 'building'   THEN 'building footprints'
        WHEN 'nsvia'      THEN 'neighborhood boundaries'
        WHEN 'parcel'     THEN 'land parcels'
        WHEN 'via'        THEN 'road network'
        WHEN 'geoaddress' THEN 'address points'
        END
      ),
    'with_address', ( CASE WHEN ftid IN (21,22,51,52,61,62) THEN TRUE ELSE FALSE END),
    'isblock', ( CASE class_ftname WHEN 'block' THEN TRUE ELSE FALSE END),
    'isbuilding', ( CASE class_ftname WHEN 'building' THEN TRUE ELSE FALSE END),
    'isnsvia', ( CASE class_ftname WHEN 'nsvia' THEN TRUE ELSE FALSE END),
    'isparcel', ( CASE class_ftname WHEN 'parcel' THEN TRUE ELSE FALSE END),
    'isvia', ( CASE class_ftname WHEN 'via' THEN TRUE ELSE FALSE END),
    'isgeoaddress', ( CASE class_ftname WHEN 'geoaddress' THEN TRUE ELSE FALSE END),

    'isisolevel1', ( CASE isolevel WHEN 1 THEN TRUE ELSE FALSE END),
    'isisolevel2', ( CASE isolevel WHEN 2 THEN TRUE ELSE FALSE END),
    'isisolevel3', ( CASE isolevel WHEN 3 THEN TRUE ELSE FALSE END),

    'iscapital1', ( CASE (jurisdiction_info->'is_capital_isolevel')::int WHEN 1 THEN TRUE ELSE FALSE END)

    ) AS conf
FROM optim.vw02publication t
;
COMMENT ON VIEW optim.vw03publication_viz
  IS 'Generate json for mustache template for Viz.'
;

CREATE or replace VIEW optim.vw03_metadata_viz AS
SELECT
  viz_id, viz_id2, isolabel_ext, conf->'viz_summary'->'info'->>'shp_id' AS shp_id, conf->'viz_summary'->'info'->>'pub_id' AS pub_id, conf->'viz_summary'->'info'->>'view_id' AS view_id, conf->>'class_ftname' AS class_ftname,

  jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/title.mustache'), conf)                   AS title,
  jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/snippet.mustache'), conf)                 AS snippet,
  jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/description.mustache'), conf)
  ||
  (
    CASE (conf->'jurisd1'->'jurisd_base_id')::int
    WHEN 76 THEN jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/description-pt-br.mustache'), conf)
    ELSE jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/description-es.mustache'), conf)
    END
  )
  AS description,
  jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/licenseinfo.mustache'), conf)             AS licenseinfo,
  jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/accessinformation.mustache'), conf)       AS accessinformation,
  replace(conf->>'ftnameviz',' ', '_') || (CASE WHEN (conf->>'with_address')::BOOLEAN IS TRUE THEN ', address' ELSE '' END) || ', ' || isolabel_ext || ', ' || (conf->'jurisd1'->>'name_en')::text AS tags,

  ARRAY['/Categories/Country/' || (conf->'jurisd1'->>'name_en')::text , '/Categories/Feature type/' || (conf->>'initcap_ftnameviz')::text] AS categories,

  jsonb_build_object(
  'title',jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/title.mustache'), conf),
  'snippet',jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/snippet.mustache'), conf),
  'description',jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/description.mustache'), conf)
  ||
  (
    CASE (conf->'jurisd1'->'jurisd_base_id')::int
    WHEN 76 THEN jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/description-pt-br.mustache'), conf)
    ELSE jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/description-es.mustache'), conf)
    END
  ),
  'licenseinfo',jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/licenseinfo.mustache'), conf),
  'accessinformation',jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/accessinformation.mustache'), conf),
  'tags',replace(conf->>'ftnameviz',' ', '_') || (CASE WHEN (conf->>'with_address')::BOOLEAN IS TRUE THEN ', address' ELSE '' END) || ', ' || isolabel_ext || ', ' || (conf->'jurisd1'->>'name_en')::text
  ) AS properties_fl,

  jsonb_build_object(
  'title',jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/title.mustache'), conf || jsonb_build_object('foropenstreetmap', true)),
  'snippet',jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/snippet.mustache'), conf || jsonb_build_object('foropenstreetmap', true)),
  'description',jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/description.mustache'), conf || jsonb_build_object('foropenstreetmap', true))
  ||
  (
    CASE (conf->'jurisd1'->'jurisd_base_id')::int
    WHEN 76 THEN jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/description-pt-br.mustache'), conf || jsonb_build_object('foropenstreetmap', true))
    ELSE jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/description-es.mustache'), conf || jsonb_build_object('foropenstreetmap', true))
    END
  ),
  'licenseinfo',jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/licenseinfo.mustache'), conf || jsonb_build_object('foropenstreetmap', true)),
  'accessinformation',jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/accessinformation.mustache'), conf || jsonb_build_object('foropenstreetmap', true)),
  'tags',replace(conf->>'ftnameviz',' ', '_') || (CASE WHEN (conf->>'with_address')::BOOLEAN IS TRUE THEN ', address' ELSE '' END) || ', OpenStreetMap' || ', ' || isolabel_ext || ', ' || (conf->'jurisd1'->>'name_en')::text
  ) AS properties_flw,

  jsonb_build_object(
  'displayField', '',
  'name',replace(conf->>'ftnameviz',' ', '_'),
  'description',jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/snippet.mustache'), conf),
  'copyrightText',jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/maketemplates/viz/accessinformation.mustache'), conf)
  ) AS properties_l,

  CASE conf->>'class_ftname'
    WHEN 'genericvia' THEN jsonb_build_object('via', 'name')
    WHEN 'block'      THEN jsonb_build_object('name', 'name')
    WHEN 'nsvia'      THEN jsonb_build_object('nsvia', 'name')
    WHEN 'via'        THEN jsonb_build_object('via','name','highway','highway','lanes','lanes','lit','lit','sidewalk','sidewalk','surface','surface','oneway','oneway')
    WHEN 'parcel'     THEN      jsonb_build_object('address','addr:full','via','addr:street','hnum','addr:housenumber','postcode','addr:postcode','nsvia','addr:suburb','name','name','place','addr:place','city','addr:city','country','addr:country','block','addr:block','district','addr:district')
    WHEN 'geoaddress' THEN      jsonb_build_object('address','addr:full','via','addr:street','hnum','addr:housenumber','postcode','addr:postcode','nsvia','addr:suburb','name','name','place','addr:place','city','addr:city','country','addr:country','block','addr:block','district','addr:district')
    WHEN 'building' THEN      jsonb_build_object('address','addr:full','via','addr:street','hnum','addr:housenumber','postcode','addr:postcode','nsvia','addr:suburb','name','name','place','addr:place','city','addr:city','country','addr:country','block','addr:block','district','addr:district',   'class','building','use','building:use','amenity','amenity','levels','building:levels','material','building:material','min_level','building:min_level','part','building:part','height','height')
  END AS tr_dict,

  CASE conf->>'class_ftname'
    WHEN 'genericvia' THEN ARRAY['via','name']
    WHEN 'block'      THEN ARRAY['name']
    WHEN 'nsvia'      THEN ARRAY['nsvia','name']
    WHEN 'via'        THEN ARRAY['via','name','highway','lanes','lit','surface','oneway']
    WHEN 'parcel'     THEN ARRAY['sup','address','addr:full','via','addr:street','hnum','addr:housenumber','postcode','addr:postcode','nsvia','addr:suburb','name','place','addr:place','city','addr:city','country','addr:country','block','addr:block','district','addr:district']
    WHEN 'geoaddress' THEN ARRAY['sup','address','addr:full','via','addr:street','hnum','addr:housenumber','postcode','addr:postcode','nsvia','addr:suburb','name','place','addr:place','city','addr:city','country','addr:country','block','addr:block','district','addr:district']
    WHEN 'building'   THEN ARRAY['sup','address','addr:full','via','addr:street','hnum','addr:housenumber','postcode','addr:postcode','nsvia','addr:suburb','name','place','addr:place','city','addr:city','country','addr:country','block','addr:block','district','addr:district', 'class','building','use','building:use','amenity','levels','building:levels','material','building:material','min_level','building:min_level','part','building:part','height']
  END AS nodel_fields

FROM optim.vw03publication_viz
;
COMMENT ON VIEW optim.vw03_metadata_viz
  IS 'Metadata for viz.'
;

CREATE or replace VIEW optim.vw03publication AS
SELECT isolabel_ext, '_pk' || pack_number AS pack_number, jsonb_build_object(
    'packtpl_id', packtpl_id,
    'isolabel_ext', isolabel_ext,
    'legalname', legalname,
    'vat_id', vat_id,
    'url', url,
    'wikidata_id', wikidata_id,
    'user_resp', user_resp,
    'uri_objtype', packtpl_info->>'uri_objtype',
    'user_resp_packtpl_info',user_resp_packtpl_info,
    'accepted_date', pack_item_accepted_date,
    'accepted_date_ptbr', packtpl_info->>'accepted_date_ptbr',
    'accepted_date_en', packtpl_info->>'accepted_date_en',
    'accepted_date_es', packtpl_info->>'accepted_date_es',
    'path_preserv_git', path_preserv_git,
    'pack_number', pack_number,
    'path_cutgeo_git', path_cutgeo_git,
    'license_evidences',license_evidences,
    'path_cutgeo_notree', replace(replace(path_cutgeo_git,'tree/',''),'https://git.digital-guard.org/',''),
    'layers',  jsonb_agg(jsonb_build_object(
                'id', id,
                'class_ftname', class_ftname,
                'shortname', shortnameftname,
                'description', descriptionftname,
                'hashedfname', hashedfname,
                'hashedfname_without_ext', hashedfname_without_ext,
                'hashedfname_7_ext', hashedfname_7_ext,
                'isFirst', iif(row_num=1,'true'::jsonb,'false'::jsonb),
                'geom_type_abbr', geom_type_abbr,
                'publication_summary', publication_summary,
                'url_page', url_page,
                'filtered_name', filtered_name,
                'viz_summary', viz_summary
                )),
    'viz_keys', array_agg((CASE WHEN viz_summary IS NOT NULL THEN class_ftname ELSE NULL END)),
    'publication_keys', array_agg((CASE WHEN publication_summary IS NOT NULL THEN class_ftname ELSE NULL END))
    ) AS page
FROM optim.vw02publication t
GROUP BY packtpl_id, isolabel_ext, legalname, vat_id, url, wikidata_id, user_resp, path_preserv_git, pack_number, path_cutgeo_git, pack_item_accepted_date, kx_pack_item_version, local_serial, pk_count,license_evidences,packtpl_info->>'accepted_date_ptbr',packtpl_info->>'accepted_date_es',packtpl_info->>'accepted_date_en',packtpl_info->>'uri_objtype', user_resp_packtpl_info
;
COMMENT ON VIEW optim.vw03publication
  IS 'Generate json for mustache template for preservDataViz pages.'
;

CREATE or replace FUNCTION optim.publicating_page(
	p_isolabel_ext  text, -- e.g. 'BR-AC-RioBranco'
	p_pack_number text,
	p_fileref text
) RETURNS text  AS $f$
  SELECT string_agg(output_write, ',')
  FROM (
    SELECT volat_file_write((p_fileref || '/' || s.name), s.page) AS output_write
    FROM (
        SELECT (page->'layer'->>'url_page') AS name, jsonb_mustache_render(pg_read_file('/var/gits/_dg/preservDataViz/src/preservCutGeo/pk_page.mustache'), r.page) AS page
        FROM (
            SELECT page || jsonb_build_object('layer',jsonb_array_elements(page->'layers')) AS page
            FROM optim.vw03publication
            WHERE isolabel_ext=p_isolabel_ext AND pack_number=p_pack_number) r
    ) s
  ) t;
$f$ language SQL VOLATILE;
-- SELECT optim.publicating_page('BR-AC-RioBranco','_pk0042.01','/tmp/pg_io');
-- SELECT jsonb_mustache_render(pg_read_file('/var/gits/_dg/preservDataViz/src/preservCutGeo/pk_page.mustache'), (SELECT page FROM optim.vw03publication WHERE isolabel_ext='BR-AC-RioBranco' AND pack_number='_pk0042.01'));
COMMENT ON FUNCTION optim.publicating_page
  IS 'Generate html file for preservDataViz pages.'
;


CREATE or replace VIEW optim.vw01publicating_index AS
SELECT jsonb_build_object('pages', pages) AS y
FROM
(
    SELECT jsonb_agg(t.*) AS pages
    FROM
    (
        SELECT *, lower(isolabel_ext) || '_pk' || pack_number || '_' ||  class_ftname || '.html' AS url_page,
                    isolabel_ext || '/pk' || pack_number AS name
        FROM
        (
            SELECT *, row_number() OVER (PARTITION BY isolabel_ext, pack_number ORDER BY class_ftname ASC ) AS row_num
            FROM
            (
            SELECT pf.isolabel_ext, pf.pack_number,
                    pf.ftype_info->>'class_ftname' as class_ftname
            FROM optim.vw01full_packfilevers_ftype pf
            INNER JOIN optim.donated_PackComponent pc
            ON pc.packvers_id=pf.id AND pc.ftid=pf.ftid

            WHERE pf.ftid > 19
            ORDER BY pf.isolabel_ext, pf.local_serial, pf.pk_count, pf.ftype_info->>'class_ftname'
            ) r
        ) s
        WHERE row_num = 1
    ) t
) u
;

CREATE or replace FUNCTION optim.publicating_index_page(
	p_fileref text,
	p_template text DEFAULT '/var/gits/_dg/preservDataViz/src/preservCutGeo/index_page.mustache'
) RETURNS text  AS $f$
    SELECT volat_file_write(($1 || '/' || 'index.html'), jsonb_mustache_render(pg_read_file(p_template), y)) AS output_write
    FROM optim.vw01publicating_index
    ;
$f$ language SQL VOLATILE;
COMMENT ON FUNCTION optim.publicating_index_page
  IS 'Generate index.html file for preservDataViz pages.'
;
-- SELECT optim.publicating_index_page('/tmp/pg_io/index.html','/var/gits/_dg/preservDataViz/src/preservCutGeo/index_page.mustache');

CREATE or replace FUNCTION optim.publicating_index_pagemd(
	p_fileref text,
	p_template text DEFAULT '/var/gits/_dg/preservDataViz/src/preservCutGeo/index_page_markdown.mustache'
) RETURNS text  AS $f$
    SELECT volat_file_write(p_fileref, jsonb_mustache_render(pg_read_file(p_template), y)) AS output_write
    FROM optim.vw01publicating_index
    ;
$f$ language SQL VOLATILE;
COMMENT ON FUNCTION optim.publicating_index_page
  IS 'Generate index in markdown file for preservDataViz pages.'
;
-- SELECT optim.publicating_index_pagemd('/tmp/pg_io/index_teste2.md','/var/gits/_dg/preservDataViz/src/preservCutGeo/index_page_markdown.mustache');

----------------------

CREATE or replace VIEW optim.vw01generate_list AS
SELECT scope_label, isolevel, pacotes || coalesce(jsonb_build_object('filtered_files',filtered_files),'{}'::jsonb) AS pacotes
FROM
(
  SELECT pack_id, scope_label, isolevel, jsonb_build_object('legalName',legalName,'isunpublished',(CASE WHEN lower(MAX(regexp_replace(packtpl_info->>'uri_objtype', '[\s+]|\-', '', 'g'))) = 'email' THEN TRUE ELSE FALSE END),
  'pack_number', MAX(pack_number), 'path_preserv_git', MAX(path_preserv_git), 'local_serial_formated', MAX(local_serial_formated), 'pacotes',jsonb_agg(pf2.*), 'license_data',license_data) AS pacotes
  FROM
  (
    SELECT pf.*
    FROM optim.vw01full_packfilevers pf
    ORDER BY scope_label, legalName,pack_id,pack_item
  ) pf2
  GROUP BY country_id, local_serial, scope_osm_id, scope_label, shortname, vat_id, legalName, wikidata_id, url, donor_info, kx_vat_id, isolevel, pack_id, license_data
  ORDER BY scope_label, legalName
) r
LEFT JOIN optim.vw01filtered_files s
ON r.pack_id = s.pack_id
;


CREATE or replace VIEW optim.vw02generate_list AS
SELECT jsonb_build_object('paises',jsonb_agg(jsonb_build_object('scope_label', scope_label, 'iso1', iso1, 'iso3', iso3, 'jurisd', jurisd))) AS y
FROM
(
    SELECT COALESCE(s.scope_label,r.scope_label) AS scope_label, iso3, iso1, jurisd
    FROM
    (
      SELECT scope_label, jsonb_agg(iso3) AS iso3
      FROM
      (
        SELECT split_part(scope_label,'-',1)  AS scope_label, jsonb_build_object('jurisd',scope_label,'doadores',jsonb_agg(pacotes)) AS iso3
        FROM optim.vw01generate_list
        WHERE scope_label LIKE '%-%-%'
        GROUP BY scope_label
        ORDER BY scope_label
      ) m
      GROUP BY scope_label
    ) s
    FULL OUTER JOIN
    (
      SELECT scope_label, jsonb_agg(pacotes) AS iso1
      FROM optim.vw01generate_list
      WHERE isolevel = 1
      GROUP BY scope_label
    ) r
    ON s.scope_label = r.scope_label,
    LATERAL
    (
      SELECT jsonb_agg(h.*)->0 AS jurisd
      FROM optim.jurisdiction h
      WHERE  abbrev = COALESCE(s.scope_label,r.scope_label) AND isolevel=1
    ) v
) t
;

CREATE or replace VIEW optim.vw03generate_list_hash AS
SELECT jsonb_build_object('pacotes',jsonb_agg(r.*)) AS y
FROM
(
  SELECT legalName, scope_label, hashedfname, hashedfname_7, pack_number, local_serial_formated, path_preserv_git, info
  FROM optim.vw01full_packfilevers pf
  ORDER BY hashedfname
) r
;

CREATE or replace FUNCTION optim.generate_list(
	p_fileref text,
	p_template text DEFAULT '/var/gits/_dg/preserv/src/list_jurisd.mustache'
) RETURNS text  AS $f$
    SELECT volat_file_write(p_fileref, jsonb_mustache_render(pg_read_file(p_template), y)) AS output_write
    FROM optim.vw02generate_list
    ;
$f$ language SQL VOLATILE;
COMMENT ON FUNCTION optim.generate_list
  IS 'Generate list page.'
;
-- SELECT optim.generate_list('/tmp/pg_io/list_jurisd_with_filtered_markdown.txt',    '/var/gits/_dg/preserv/src/list_jurisd.mustache');
-- SELECT optim.generate_list('/tmp/pg_io/list_jurisd_without_filtered_markdown.txt', '/var/gits/_dg/preserv/src/list_jurisd_without_filtered.mustache');
-- SELECT optim.generate_list('/tmp/pg_io/list_jurisd_with_filtered_mediawiki.txt',   '/var/gits/_dg/preserv/src/list_jurisd_mediawiki.mustache');
-- SELECT optim.generate_list('/tmp/pg_io/list_jurisd_without_filtered_mediawiki.txt','/var/gits/_dg/preserv/src/list_jurisd_without_filtered_mediawiki.mustache');

CREATE or replace FUNCTION optim.generate_list_hash(
	p_fileref text,
	p_template text DEFAULT '/var/gits/_dg/preserv/src/list_hash.mustache'
) RETURNS text  AS $f$
    SELECT volat_file_write(p_fileref, jsonb_mustache_render(pg_read_file(p_template), y)) AS output_write
    FROM optim.vw03generate_list_hash
    ;
$f$ language SQL VOLATILE;
COMMENT ON FUNCTION optim.generate_list_hash
  IS 'Generate list page.'
;
-- SELECT optim.generate_list_hash('/tmp/pg_io/list_hash_markdown.txt');
-- SELECT optim.generate_list_hash('/tmp/pg_io/list_hash_mediawiki.txt','/var/gits/_dg/preserv/src/list_hash_wiki.mustache');
