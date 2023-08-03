CREATE SCHEMA    IF NOT EXISTS license;
CREATE SCHEMA    IF NOT EXISTS api;

CREATE EXTENSION IF NOT EXISTS file_fdw;
CREATE SERVER    IF NOT EXISTS files FOREIGN DATA WRAPPER file_fdw;

----------------------

CREATE TABLE license.licenses_implieds (
 id_label text,
 id_version text,
 name text,
 family text,
 status text,
 year text,
 is_by text,
 is_sa text,
 is_noreuse text,
 od_conformance text,
 osd_conformance text,
 maintainer text,
 title text,
 url text,
 license_is_explicit text,
 info jsonb,
 UNIQUE (id_label,id_version)
);
COMMENT ON TABLE license.licenses_implieds
  IS ''
;

CREATE or replace FUNCTION license.insert_licenses(
) RETURNS text AS $f$
BEGIN
  INSERT INTO license.licenses_implieds(id_label,id_version,name,family,status,year,is_by,is_sa,is_noreuse,od_conformance,osd_conformance,maintainer,title,url,license_is_explicit,info)

  SELECT id_label,id_version,name,family,status,year,is_by,is_sa,is_noreuse,od_conformance,osd_conformance,maintainer,title,url,
  'yes' AS license_is_explicit,
  jsonb_build_object('is_ref',is_ref,'is_salink',is_salink,'is_nd',is_nd,'is_generic',is_generic,'domain_content',domain_content,'domain_data',domain_data,'domain_software',domain_software,'notes',"NOTES") AS info
  FROM tmp_orig.licenses

  UNION

  SELECT id_label,id_version,name,family,status,year,is_by,is_sa,is_noreuse,od_conformance,osd_conformance,maintainer,title, url_report AS url,
  'no' AS license_is_explicit,
  jsonb_build_object('report_year',report_year,'scope',scope,'url_ref',url_ref) as info
  FROM tmp_orig.implieds

  ON CONFLICT (id_label,id_version)
  DO UPDATE
  SET name=EXCLUDED.name, family=EXCLUDED.family, status=EXCLUDED.status, year=EXCLUDED.year, is_by=EXCLUDED.is_by, is_sa=EXCLUDED.is_sa, is_noreuse=EXCLUDED.is_noreuse, od_conformance=EXCLUDED.od_conformance, osd_conformance=EXCLUDED.osd_conformance, maintainer=EXCLUDED.maintainer, title=EXCLUDED.title, url=EXCLUDED.url, license_is_explicit=EXCLUDED.license_is_explicit, info=EXCLUDED.info
  -- RETURNING 'Ok, updated license.licenses_implieds.'
  ;
  RETURN 'Ok, updated license.licenses_implieds.';
END;
$f$ LANGUAGE PLpgSQL;
COMMENT ON FUNCTION license.insert_licenses
  IS 'Update license.licenses_implieds from tmp_orig.redirects_dlguard'
;
-- SELECT license.insert_licenses();

CREATE or replace VIEW license.pack_licenses AS
SELECT d.pack_id, l.*
FROM tmp_orig.donatedpacks_donor AS d
LEFT JOIN license.licenses_implieds AS l
ON lower(d.license) = l.id_label AND d.license_is_explicit = l.license_is_explicit;

----------------------

CREATE or replace VIEW api.licenses AS
SELECT *
FROM license.licenses_implieds
;
