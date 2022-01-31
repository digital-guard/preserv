/**
 * System for Digital Preservation
 * System's Public library (commom for others)
 */

CREATE SCHEMA IF NOT EXISTS dg_preserv;
--------------
-- BEGIN LIXO:
CREATE or replace FUNCTION dg_preserv.packid_to_real(pkid int, version int) RETURNS real AS $f$
  SELECT pkid::real + (CASE WHEN version IS NULL or version<=0 THEN 1 ELSE version END)::real/1000.0::real
  -- Estimativa de versões: 1 por semana ao longo de 15 anos. 15*12*4.3=780. Ainda sobram 320 por segurança.
$f$ language SQL IMMUTABLE;

COMMENT ON FUNCTION dg_preserv.packid_to_real(int,int)
 IS 'Encodes integer pkid and version into real pck_id, convention of the one new version a week for 15 years.'
;

CREATE or replace FUNCTION dg_preserv.packid_to_real(pck_id int[]) RETURNS real AS $wrap$
  SELECT dg_preserv.packid_to_real(pck_id[1],pck_id[2])
$wrap$ language SQL IMMUTABLE;

COMMENT ON FUNCTION dg_preserv.packid_to_real(int[])
 IS 'Encodes integer array[pkid,version] into real pck_id, convention of the 20 years with 40 versions/year.'
;

CREATE or replace FUNCTION dg_preserv.packid_to_real(str_pkid text) RETURNS real AS $f$
  SELECT replace(str_pkid,'_','.')::real
$f$ language SQL IMMUTABLE;

COMMENT ON FUNCTION dg_preserv.packid_to_real(text)
 IS 'Converts pck_id format, text into real.'
;

CREATE or replace FUNCTION dg_preserv.packid_to_ints(pck_id real) RETURNS int[] AS $f$
  SELECT array[k::int,round((pck_id-k)*1000)::int]
  FROM ( SELECT trunc(pck_id) k) t
$f$ language SQL IMMUTABLE;

COMMENT ON FUNCTION dg_preserv.packid_to_ints(real)
 IS 'Decodes real pck_id into integer array[pkid,version], convention of the 20 years with 40 versions/year.'
;

CREATE or replace FUNCTION dg_preserv.packid_to_str(pck_id real, sep boolean default false) RETURNS text AS $f$
 SELECT CASE WHEN sep IS NULL THEN replace(s,'.000','') WHEN sep THEN replace(s,'.','_') ELSE s END
 FROM ( SELECT to_char(CASE WHEN sep IS NULL THEN floor($1) ELSE $1 END,'FM999999000.000') s ) t
$f$ language SQL IMMUTABLE;

CREATE or replace FUNCTION dg_preserv.packid_to_str(pck_id int[], sep boolean default false) RETURNS text AS $wrap$
  select  dg_preserv.packid_to_str( dg_preserv.packid_to_real($1), $2 )
$wrap$ language SQL IMMUTABLE;

CREATE or replace FUNCTION dg_preserv.packid_to_str(pkid int, version int, sep boolean default false) RETURNS text AS $wrap$
 select  dg_preserv.packid_to_str( dg_preserv.packid_to_real($1,$2), $3 )
$wrap$ language SQL IMMUTABLE;

CREATE or replace FUNCTION dg_preserv.packid_plusone(pck_id real) RETURNS real AS $f$
  SELECT dg_preserv.packid_to_real(p[1],p[2]+1) -- +1?
  FROM (SELECT dg_preserv.packid_to_ints(pck_id) p) t
$f$ language SQL IMMUTABLE;

CREATE or replace FUNCTION dg_preserv.packid_isvalid(pck_id real) RETURNS boolean AS $f$
  SELECT CASE
    WHEN p IS NULL OR p[1] IS NULL OR p[1]=0 OR p[2]=0 OR dg_preserv.packid_to_real(p)!=pck_id::real THEN false
    ELSE true
    END
  FROM (SELECT dg_preserv.packid_to_ints(pck_id) p) t
$f$ language SQL IMMUTABLE;

-- falta dinâmico de MAX de real da tabela. Use dg_preserv.packid_plusone(x) para o próximo.

CREATE or replace FUNCTION dg_preserv.packid_getmax(
  p_tablename  text,
  p_plusone boolean DEFAULT false
) RETURNS real AS $f$
DECLARE
  r real;
BEGIN
  EXECUTE format(
    CASE
      WHEN p_plusone THEN 'SELECT MAX(pck_id) INTO r FROM %s'
      ELSE  'SELECT dg_preserv.packid_plusone(MAX(pck_id)) INTO r FROM %s'
    END, p_tablename
  );
  RETURN r;
END
$f$ LANGUAGE PLpgSQL;
COMMENT ON FUNCTION dg_preserv.packid_getmax
 IS 'Obtais the current (or the next when p_plusOne) pck_id of a table.'
;

-- FIM LIXO
-------------
