DROP VIEW IF EXISTS optim.vw03publication CASCADE;
CREATE VIEW optim.vw03publication AS
SELECT isolabel_ext, jsonb_build_object(
    'isolabel_ext', isolabel_ext,
    'legalname', legalname,
    'vat_id', vat_id,
    'url', url,
    'wikidata_id', wikidata_id,
    'user_resp', user_resp,
    'accepted_date', pack_item_accepted_date,
    'path_preserv', path_preserv,
    'pack_number', pack_number,
    'path_cutgeo', path_cutgeo,
    'path_cutgeo_notree', replace(path_cutgeo,'tree/',''),
    'layers',  jsonb_agg(jsonb_build_object(
                'class_ftname', class_ftname,
                'shortname', shortname,
                'description', description,
                'hashedfname', hashedfname,
                'hashedfname_without_ext', hashedfname_without_ext,
                'hashedfname_7_ext', hashedfname_7_ext,
                'isFirst', iif(row_num=1,'true'::jsonb,'false'::jsonb),
                'publication_summary', publication_summary,
                'url_page', lower(isolabel_ext) || '_' || class_ftname || '.html'
                ))
    ) AS page
FROM (
  SELECT j.isolabel_ext, dn.legalname, dn.vat_id, dn.url, dn.wikidata_id, pf.pack_item_accepted_date,
  INITCAP(pt.user_resp) AS user_resp, 
  row_number() OVER (PARTITION BY j.isolabel_ext, dn.local_serial, pt.pk_count ORDER BY ft.info->'class_ftname' ASC ) AS row_num,
  ft.info->>'class_ftname' as class_ftname, 
  ft.info->'class_info'->>'shortname_pt' as shortname,
  ft.info->'class_info'->>'description_pt' as description,
  pt.make_conf_tpl->'license_evidences' AS license_evidences,
  pf.hashedfname, 
  substring(pf.hashedfname, '^([0-9a-f]{64,64})\.[a-z0-9]+$') AS hashedfname_without_ext, 
  substring(pf.hashedfname, '^([0-9a-f]{7}).+$') || '...' || substring(pf.hashedfname, '^.+\.([a-z0-9]+)$') AS hashedfname_7_ext,
  jsonb_build_object(
        'geom_type',CASE ft.geomtype
            WHEN 'poly'  THEN 'polígonos'
            WHEN 'line'  THEN 'segmentos'
            WHEN 'point' THEN 'pontos'
            END,
        'geom_type_abbr',CASE ft.geomtype
            WHEN 'poly'  THEN 'pols'
            WHEN 'line'  THEN 'lns'
            WHEN 'point' THEN 'pts'
            END,
        'geom_unit_abr',CASE ft.geomtype
            WHEN 'poly'  THEN 'km2'
            WHEN 'line'  THEN 'km'
            ELSE  ''
            END,
        'geom_unit_ext',CASE ft.geomtype
            WHEN 'poly'  THEN 'quilômetros quadrados'
            WHEN 'line'  THEN 'quilômetros'
            ELSE  ''
            END,
            'isGeoaddress', iif(ft.info->>'class_ftname'='geoaddress','true'::jsonb,'false'::jsonb),
        'bytes_mb', (pc.kx_profile->'publication_summary'->'bytes')::bigint / 1048576.0
  ) || (pc.kx_profile->'publication_summary') AS publication_summary,
  regexp_replace(replace(regexp_replace(j.isolabel_ext, '^([^-]*)-?', '\1/blob/main/data/'),'-','/'),'\/$','') || '/_pk' || to_char(dn.local_serial,'fm0000') || '.' || to_char(pt.pk_count,'fm00') AS path_preserv,
  to_char(dn.local_serial,'fm0000') || '.' || to_char(pt.pk_count,'fm00') AS pack_number,
  'preservCutGeo-' || regexp_replace(replace(regexp_replace(j.isolabel_ext, '^([^-]*)-?', '\12021/tree/main/data/'),'-','/'),'\/$','') || '/_pk' || to_char(dn.local_serial,'fm0000') || '.' || to_char(pt.pk_count,'fm00') AS path_cutgeo
  --, dn.kx_scope_label, pc.*, ft.ftname, ft.geomtype, ft.need_join, ft.description, ft.info AS ft_info
  FROM optim.donated_PackComponent pc
  INNER JOIN optim.vw01info_feature_type ft
    ON pc.ftid=ft.ftid
  LEFT JOIN optim.donated_packfilevers pf
    ON pc.packvers_id=pf.id
  LEFT JOIN optim.donated_PackTpl pt
    ON pf.pack_id=pt.id
  LEFT JOIN optim.donor dn
    ON pt.donor_id=dn.id
  LEFT JOIN optim.vw01full_jurisdiction_geom j
    ON dn.scope_osm_id=j.osm_id
  ORDER BY j.isolabel_ext, ft.info->>'class_ftname'
) t
GROUP BY isolabel_ext, legalname, vat_id, url, wikidata_id, user_resp, path_preserv, pack_number, path_cutgeo, pack_item_accepted_date
;

CREATE or replace FUNCTION optim.publicating_page(
	p_isolabel_ext  text, -- e.g. 'BR-AC-RioBranco'
	p_fileref text
) RETURNS text  AS $f$
  SELECT string_agg(output_write, ',')
  FROM (
    SELECT volat_file_write(($2 || '/' || s.name), s.page) AS output_write
    FROM (
        SELECT (page->'layer'->>'url_page') AS name, jsonb_mustache_render(pg_read_file('/var/gits/_dg/preservDataViz/src/preservCutGeo/pk_page.mustache'), r.page) AS page
        FROM (
            SELECT page || jsonb_build_object('layer',jsonb_array_elements(page->'layers')) AS page
            FROM optim.vw03publication
            WHERE isolabel_ext=$1) r
    ) s
  ) t;
$f$ language SQL VOLATILE;
-- SELECT optim.publicating_page('BR-AC-RioBranco','/tmp/pg_io');
-- SELECT jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/template_page_publi.mustache'), (SELECT page FROM optim.vw03publication WHERE isolabel_ext='BR-AC-RioBranco'));
