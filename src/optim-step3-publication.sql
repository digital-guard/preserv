CREATE or replace VIEW optim.vw03publication AS
SELECT isolabel_ext, '_pk' || pack_number AS pack_number, jsonb_build_object(
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
                'geom_type_abbr', geom_type_abbr,
                'publication_summary', publication_summary,
                'url_page', lower(isolabel_ext) || '_pk' || pack_number || '_' ||  class_ftname || '.html'
                ))
    ) AS page
FROM (
  SELECT pf.isolabel_ext, pf.legalname, pf.vat_id, pf.url, pf.wikidata_id, pf.pack_item_accepted_date, pf.kx_pack_item_version, pf.local_serial, pf.pk_count,
  INITCAP(pf.user_resp) AS user_resp,
  row_number() OVER (PARTITION BY pf.isolabel_ext, pf.local_serial, pf.pk_count ORDER BY pf.ftype_info->'class_ftname' ASC ) AS row_num,
  pf.ftype_info->>'class_ftname' as class_ftname,
  pf.ftype_info->'class_info'->>'shortname_pt' as shortname,
  pf.ftype_info->'class_info'->>'description_pt' as description,
  pf.make_conf_tpl->'license_evidences' AS license_evidences,
  pf.hashedfname, 
  substring(pf.hashedfname, '^([0-9a-f]{64,64})\.[a-z0-9]+$') AS hashedfname_without_ext, 
  substring(pf.hashedfname, '^([0-9a-f]{7}).+$') || '...' || substring(pf.hashedfname, '^.+\.([a-z0-9]+)$') AS hashedfname_7_ext,
  CASE pf.geomtype
            WHEN 'poly'  THEN 'pols'
            WHEN 'line'  THEN 'lns'
            WHEN 'point' THEN 'pts'
            END AS geom_type_abbr,
  jsonb_build_object(
        'geom_type',CASE pf.geomtype
            WHEN 'poly'  THEN 'polígonos'
            WHEN 'line'  THEN 'segmentos'
            WHEN 'point' THEN 'pontos'
            END,
        'geom_unit_abr',CASE pf.geomtype
            WHEN 'poly'  THEN 'km2'
            WHEN 'line'  THEN 'km'
            ELSE  ''
            END,
        'geom_unit_ext',CASE pf.geomtype
            WHEN 'poly'  THEN 'quilômetros quadrados'
            WHEN 'line'  THEN 'quilômetros'
            ELSE  ''
            END,
            'isGeoaddress', iif(pf.ftype_info->>'class_ftname'='geoaddress','true'::jsonb,'false'::jsonb),
        'bytes_mb', (pc.kx_profile->'publication_summary'->'bytes')::bigint / 1048576.0
  ) || (pc.kx_profile->'publication_summary') AS publication_summary,
  regexp_replace(replace(regexp_replace(pf.isolabel_ext, '^([^-]*)-?', '\1/blob/main/data/'),'-','/'),'\/$','') || '/_pk' || to_char(pf.local_serial,'fm0000') || '.' || to_char(pf.pk_count,'fm00') AS path_preserv,
  to_char(pf.local_serial,'fm0000') || '.' || to_char(pf.pk_count,'fm00') AS pack_number,
  'preservCutGeo-' || regexp_replace(replace(regexp_replace(pf.isolabel_ext, '^([^-]*)-?', '\12021/tree/main/data/'),'-','/'),'\/$','') || '/_pk' || to_char(pf.local_serial,'fm0000') || '.' || to_char(pf.pk_count,'fm00') AS path_cutgeo

  FROM optim.vw01full_packfilevers_ftype pf
  INNER JOIN optim.donated_PackComponent pc
  ON pc.packvers_id=pf.id AND pc.ftid=pf.ftid

  WHERE pf.ftid > 19
  ORDER BY pf.isolabel_ext, pf.local_serial, pf.pk_count, pf.ftype_info->>'class_ftname'
) t
GROUP BY isolabel_ext, legalname, vat_id, url, wikidata_id, user_resp, path_preserv, pack_number, path_cutgeo, pack_item_accepted_date, kx_pack_item_version, local_serial, pk_count
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

CREATE or replace FUNCTION optim.publicating_index_page(
	p_fileref text
) RETURNS text  AS $f$
    SELECT volat_file_write(($1 || '/' || 'index.html'), v.page) AS output_write
    FROM (
        SELECT jsonb_mustache_render(pg_read_file('/var/gits/_dg/preservDataViz/src/preservCutGeo/index_page.mustache'), jsonb_build_object('pages', pages)) AS page
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
                    SELECT pf.isolabel_ext,
                            to_char(pf.local_serial,'fm0000') || '.' || to_char(pf.pk_count,'fm00') AS pack_number,
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
    ) v;
$f$ language SQL VOLATILE;
-- SELECT optim.publicating_index_page('/tmp/pg_io');
COMMENT ON FUNCTION optim.publicating_index_page
  IS 'Generate index.html file for preservDataViz pages.'
;
