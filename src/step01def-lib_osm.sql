--------------------
--------------------
-- OSM lib

-- only for ingest OSM
CREATE EXTENSION IF NOT EXISTS hstore;     -- to make osm

CREATE EXTENSION IF NOT EXISTS unaccent;   -- to normalize
CREATE SCHEMA    IF NOT EXISTS lib;  -- lib geral, que não é public mas pode fazer drop/create sem medo.

CREATE or replace FUNCTION lib.osm_to_jsonb_remove() RETURNS text[] AS $f$
   SELECT array['osm_uid','osm_user','osm_version','osm_changeset','osm_timestamp'];
$f$ LANGUAGE SQL IMMUTABLE;

CREATE or replace FUNCTION lib.osm_to_jsonb(
  p_input text[], p_strip boolean DEFAULT false
) RETURNS jsonb AS $f$
  SELECT CASE WHEN p_strip THEN jsonb_strip_nulls(x,true) ELSE x END
  FROM (
    SELECT jsonb_object($1) - lib.osm_to_jsonb_remove()
  ) t(x)
$f$ LANGUAGE sql IMMUTABLE;

CREATE or replace FUNCTION lib.osm_to_jsonb(
  p_input public.hstore, p_strip boolean DEFAULT false
) RETURNS jsonb AS $f$
  SELECT CASE WHEN p_strip THEN jsonb_strip_nulls(x,true) ELSE x END
  FROM (
    SELECT hstore_to_jsonb_loose($1) - lib.osm_to_jsonb_remove()
  ) t(x)
$f$ LANGUAGE sql IMMUTABLE;

CREATE or replace FUNCTION lib.name2lex_pre(
  p_name       text                  -- 1
  ,p_normalize boolean DEFAULT true  -- 2
  ,p_cut       boolean DEFAULT true  -- 3
  ,p_unaccent  boolean DEFAULT false -- 4
) RETURNS text AS $f$
   SELECT
      CASE WHEN p_unaccent THEN lower(unaccent(x)) ELSE x END
   FROM (
     -- old    SELECT CASE WHEN p_normalize THEN stable.normalizeterm2($1,p_cut) ELSE $1 END
     SELECT CASE WHEN p_normalize THEN $1 ELSE $1 END
    ) t(x)
$f$ LANGUAGE SQL IMMUTABLE;

CREATE or replace FUNCTION lib.name2lex(
  p_name       text                  -- 1
  ,p_normalize boolean DEFAULT true  -- 2
  ,p_cut       boolean DEFAULT true  -- 3
  ,p_flag      boolean DEFAULT false -- 4
) RETURNS text AS $f$
  SELECT trim(replace(
    regexp_replace(
      lib.name2lex_pre($1,$2,$3,$4),
      E' d[aeo] | d[oa]s | com | para |^d[aeo] | l[oa]s | de l[oa]s | del | la |^la | el |^el | / .+| [aeo]s | [aeo] |\-d\'| d\'|[\-\' ]',
      '.',
      'g'
    ),
    '..',
    '.'
  ),'.')
$f$ LANGUAGE SQL IMMUTABLE;

-------------------------------------------------
