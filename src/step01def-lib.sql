--------------------
--------------------
CREATE SCHEMA    IF NOT EXISTS lib;  -- lib geral, que não é public mas pode fazer drop/create sem medo.

CREATE or replace FUNCTION lib.id_format(p_type text,pck_id bigint) RETURNS text AS $f$
 SELECT CASE p_type
 WHEN 'donor'        THEN regexp_replace(to_char(pck_id,'FM000000000'),     '^(\d{3})(\d{6})$',                     '\1.\2'         )
 WHEN 'packtpl'      THEN regexp_replace(to_char(pck_id,'FM00000000000'),   '^(\d{3})(\d{6})(\d{2})$',              '\1.\2.\3'      )
 WHEN 'packfilevers' THEN regexp_replace(to_char(pck_id,'FM00000000000000'),'^(\d{3})(\d{6})(\d{2})(\d{1})(\d{2})$','\1.\2.\3.\4.\5')
 END
$f$ language SQL IMMUTABLE;
-- SELECT lib.id_format('donor',       lib.id_encode('donor',       '{76,29}'));
-- SELECT lib.id_format('packtpl',     lib.id_encode('packtpl',     '{76000029,1}'));
-- SELECT lib.id_format('packfilevers',lib.id_encode('packfilevers','{7600002901,1,1}'));

-------------------------------------------------
