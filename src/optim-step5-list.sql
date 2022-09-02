CREATE or replace VIEW optim.vw01generate_list AS
SELECT scope_label, isolevel, jsonb_build_object('legalName',legalName,'pack_number', MAX(pack_number), 'path_yaml', MAX(path_yaml), 'local_serial_formated', MAX(local_serial_formated), 'pacotes',jsonb_agg(pf2.*)) AS pacotes
FROM  
(
  SELECT pf.*,
    regexp_replace(replace(regexp_replace(pf.isolabel_ext, '^([^-]*)-?', '\1/blob/main/data/'),'-','/'),'\/$','') AS path_yaml
  FROM optim.vw01full_packfilevers_withoutgeom pf
) pf2
GROUP BY country_id, local_serial, scope_osm_id, scope_label, shortname, vat_id, legalName, wikidata_id, url, donor_info, kx_vat_id, isolevel
ORDER BY scope_label, legalName
;

CREATE or replace VIEW optim.vw02generate_list AS
SELECT jsonb_build_object('paises',jsonb_build_object('scope_label', scope_label, 'iso1', iso1, 'iso3', iso3, 'jurisd', jurisd)) AS y 
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
  SELECT legalName, scope_label, hashedfname, hashedfname_7, pack_number, local_serial_formated,
    regexp_replace(replace(regexp_replace(pf.isolabel_ext, '^([^-]*)-?', '\1/blob/main/data/'),'-','/'),'\/$','') AS path_yaml,
    pf.info AS info
  FROM optim.vw01full_packfilevers_withoutgeom pf
  ORDER BY hashedfname
) r
;

CREATE or replace FUNCTION optim.generate_list(
	p_fileref text
) RETURNS text  AS $f$
    SELECT volat_file_write(p_fileref, jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/list_jurisd.mustache'), y)) AS output_write
    FROM optim.vw02generate_list
    ;
$f$ language SQL VOLATILE;
COMMENT ON FUNCTION optim.generate_list
  IS 'Generate list page.'
;
-- SELECT optim.generate_list('/tmp/pg_io/list_jurisd.txt');

CREATE or replace FUNCTION optim.generate_list_hash(
	p_fileref text
) RETURNS text  AS $f$
    SELECT volat_file_write(p_fileref, jsonb_mustache_render(pg_read_file('/var/gits/_dg/preserv/src/list_hash.mustache'), y)) AS output_write
    FROM optim.vw03generate_list_hash
    ;
$f$ language SQL VOLATILE;
COMMENT ON FUNCTION optim.generate_list_hash
  IS 'Generate list page.'
;
-- SELECT optim.generate_list_hash('/tmp/pg_io/list_hash.txt');