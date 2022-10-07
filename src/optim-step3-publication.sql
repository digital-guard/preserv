CREATE or replace VIEW optim.vw03publication AS
SELECT isolabel_ext, '_pk' || pack_number AS pack_number, jsonb_build_object(
    'isolabel_ext', isolabel_ext,
    'legalname', legalname,
    'vat_id', vat_id,
    'url', url,
    'wikidata_id', wikidata_id,
    'user_resp', user_resp,
    'accepted_date', pack_item_accepted_date,
    'path_preserv_git', path_preserv_git,
    'pack_number', pack_number,
    'path_cutgeo_git', path_cutgeo_git,
    'license_evidences',license_evidences,
    'path_cutgeo_notree', replace(replace(path_cutgeo_git,'tree/',''),'http://git.digital-guard.org/',''),
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
  SELECT pf.isolabel_ext, pf.legalname, pf.vat_id, pf.url, pf.wikidata_id, pf.pack_item_accepted_date, pf.kx_pack_item_version, pf.local_serial, pf.pk_count, pf.pack_number,
  pf.user_resp_initcap AS user_resp, pf.path_preserv_git, pf.path_cutgeo_git,
  row_number() OVER (PARTITION BY pf.isolabel_ext, pf.local_serial, pf.pk_count ORDER BY pf.ftype_info->'class_ftname' ASC ) AS row_num,
  pf.ftype_info->>'class_ftname' as class_ftname,
  pf.ftype_info->'class_info'->>'shortname_pt' as shortname,
  pf.ftype_info->'class_info'->>'description_pt' as description,
  pf.make_conf_tpl->'license_evidences' AS license_evidences,
  pf.hashedfname, 
  pf.hashedfname_without_ext,
  pf.hashedfname_7_ext,
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
        'bytes_mb', (pc.kx_profile->'publication_summary'->'bytes')::bigint / 1048576.0,
        'bytes_mb_round2', ROUND(((pc.kx_profile->'publication_summary'->'bytes')::bigint / 1048576.0),0.01),
        'avg_density_round2', ROUND(((pc.kx_profile->'publication_summary'->'avg_density')::float),0.01),
        'bytes_mb_round4', ROUND(((pc.kx_profile->'publication_summary'->'bytes')::bigint / 1048576.0),0.0001),
        'avg_density_round4', ROUND(((pc.kx_profile->'publication_summary'->'avg_density')::float),0.0001),
        'size_round2',CASE
            WHEN pc.kx_profile->'publication_summary'->>'size' IS NOT NULL
            THEN ROUND(((pc.kx_profile->'publication_summary'->'size')::float),0.01)
            ELSE  NULL
            END,
        'size_round4',CASE
            WHEN pc.kx_profile->'publication_summary'->>'size' IS NOT NULL
            THEN ROUND(((pc.kx_profile->'publication_summary'->'size')::float),0.0001)
            ELSE  NULL
            END
  )) || (pc.kx_profile->'publication_summary') AS publication_summary

  FROM optim.vw01full_packfilevers_ftype pf
  INNER JOIN optim.donated_PackComponent pc
  ON pc.packvers_id=pf.id AND pc.ftid=pf.ftid

  WHERE pf.ftid > 19
  ORDER BY pf.isolabel_ext, pf.local_serial, pf.pk_count, pf.ftype_info->>'class_ftname'
) t
GROUP BY isolabel_ext, legalname, vat_id, url, wikidata_id, user_resp, path_preserv_git, pack_number, path_cutgeo_git, pack_item_accepted_date, kx_pack_item_version, local_serial, pk_count,license_evidences
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
    ) v;
$f$ language SQL VOLATILE;
-- SELECT optim.publicating_index_page('/tmp/pg_io');
COMMENT ON FUNCTION optim.publicating_index_page
  IS 'Generate index.html file for preservDataViz pages.'
;
