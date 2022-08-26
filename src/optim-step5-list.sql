CREATE or replace VIEW optim.vw01generate_list AS
SELECT scope_label, isolevel, jsonb_build_object('legalName',legalName,'pack_number', MAX(pack_number), 'path_yaml', MAX(path_yaml), 'flocal_serial', MAX(flocal_serial), 'pacotes',jsonb_agg(pf2.*)) AS pacotes
FROM  
(
  SELECT pf.*,
    substring(pf.hashedfname, '^([0-9a-f]{7}).+$') AS hashedfname_7,
    to_char(pf.local_serial,'fm0000') || '.' || to_char(pf.pk_count,'fm00') AS pack_number,
    to_char(pf.local_serial,'fm0000') AS flocal_serial,
    regexp_replace(replace(regexp_replace(pf.isolabel_ext, '^([^-]*)-?', '\1/blob/main/data/'),'-','/'),'\/$','') AS path_yaml
    
  FROM optim.vw01full_packfilevers pf
) pf2
GROUP BY country_id, local_serial, scope_osm_id, scope_label, shortname, vat_id, legalName, wikidata_id, url, donor_info, kx_vat_id, isolevel
ORDER BY scope_label, legalName
;

CREATE or replace VIEW optim.vw02generate_list AS
SELECT jsonb_build_object('paises',jsonb_agg(u.*)) AS y
FROM
(
  SELECT COALESCE(s.scope_label,r.scope_label) AS scope_label, iso3, iso1
  FROM
  (
    SELECT scope_label, jsonb_build_object('jurisd', scope_label,'iso3',jsonb_agg(iso3)) AS iso3
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
    SELECT scope_label, jsonb_build_object('jurisd',scope_label,'iso1',jsonb_agg(pacotes)) AS iso1
    FROM optim.vw01generate_list
    WHERE isolevel = 1
    GROUP BY scope_label
  ) r
  ON s.scope_label = r.scope_label
) u
;

CREATE or replace FUNCTION optim.generate_list(
	p_fileref text
) RETURNS text  AS $f$
    SELECT volat_file_write(p_fileref, jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/list.mustache'), y)) AS output_write
    FROM optim.vw02generate_list
    ;
$f$ language SQL VOLATILE;
COMMENT ON FUNCTION optim.generate_list
  IS 'Generate list page.'
;
-- SELECT optim.generate_list('/tmp/pg_io/list.txt');
