--
-- PostgreSQL database dump
--

\restrict QZK8KSL5DB2FrBjcLYxtoONXNsAntomKsYOLKIproWt7btA1hAF5cImhZODBfn6

-- Dumped from database version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: afa; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA afa;


ALTER SCHEMA afa OWNER TO postgres;

--
-- Name: api; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA api;


ALTER SCHEMA api OWNER TO postgres;

--
-- Name: SCHEMA api; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA api IS 'AddressForAll API documentation
/*
For detailed instructions, see the <a href="https://wikifull.addressforall.org/doc/osmc:Swagger">official wiki documentation</a>.*/
';


--
-- Name: br_custom_buffer; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA br_custom_buffer;


ALTER SCHEMA br_custom_buffer OWNER TO postgres;

--
-- Name: download; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA download;


ALTER SCHEMA download OWNER TO postgres;

--
-- Name: geouri_ext; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA geouri_ext;


ALTER SCHEMA geouri_ext OWNER TO postgres;

--
-- Name: grid; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA grid;


ALTER SCHEMA grid OWNER TO postgres;

--
-- Name: lib; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA lib;


ALTER SCHEMA lib OWNER TO postgres;

--
-- Name: license; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA license;


ALTER SCHEMA license OWNER TO postgres;

--
-- Name: natcod; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA natcod;


ALTER SCHEMA natcod OWNER TO postgres;

--
-- Name: optim; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA optim;


ALTER SCHEMA optim OWNER TO postgres;

--
-- Name: osmc; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA osmc;


ALTER SCHEMA osmc OWNER TO postgres;

--
-- Name: qgis_test; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA qgis_test;


ALTER SCHEMA qgis_test OWNER TO postgres;

--
-- Name: tmp_orig; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA tmp_orig;


ALTER SCHEMA tmp_orig OWNER TO postgres;

--
-- Name: adminpack; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS adminpack WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION adminpack; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION adminpack IS 'administrative functions for PostgreSQL';


--
-- Name: file_fdw; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS file_fdw WITH SCHEMA public;


--
-- Name: EXTENSION file_fdw; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION file_fdw IS 'foreign-data wrapper for flat file access';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: xml2; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS xml2 WITH SCHEMA public;


--
-- Name: EXTENSION xml2; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION xml2 IS 'XPath querying and XSLT';


--
-- Name: br_afacode(public.geometry, integer, boolean); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.br_afacode(pt public.geometry, level integer, addprefix boolean DEFAULT false) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.hBig_to_hex(afa.br_encode(pt,level),addprefix)
$$;


ALTER FUNCTION afa.br_afacode(pt public.geometry, level integer, addprefix boolean) OWNER TO postgres;

--
-- Name: FUNCTION br_afacode(pt public.geometry, level integer, addprefix boolean); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.br_afacode(pt public.geometry, level integer, addprefix boolean) IS 'Converts a geometry point (SRID 4326) into an AFAcode value based on the specified level and optional prefix.';


--
-- Name: br_afacode(double precision, double precision, integer, boolean); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.br_afacode(lat double precision, lon double precision, level integer, addprefix boolean DEFAULT false) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.hBig_to_hex(afa.br_encode(lon,lat,level),addprefix)
$$;


ALTER FUNCTION afa.br_afacode(lat double precision, lon double precision, level integer, addprefix boolean) OWNER TO postgres;

--
-- Name: FUNCTION br_afacode(lat double precision, lon double precision, level integer, addprefix boolean); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.br_afacode(lat double precision, lon double precision, level integer, addprefix boolean) IS 'Converts latitude and longitude (in float and SRID 4326) into a AFAcode value based on the specified level and optional prefix.';


--
-- Name: br_afacode(integer, integer, integer, boolean); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.br_afacode(x integer, y integer, level integer, addprefix boolean DEFAULT false) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.hBig_to_hex(afa.br_encode(x,y,level),addprefix)
$$;


ALTER FUNCTION afa.br_afacode(x integer, y integer, level integer, addprefix boolean) OWNER TO postgres;

--
-- Name: FUNCTION br_afacode(x integer, y integer, level integer, addprefix boolean); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.br_afacode(x integer, y integer, level integer, addprefix boolean) IS 'Converts canonical xyL coordinates to an AFAcode value based on the specified level and optional prefix.';


--
-- Name: br_afacode_decode(text); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.br_afacode_decode(p_code text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT
    jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
      'type','Feature',
      'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
      'id',v.id,
      'jurisd_base_id',76,
      'properties',jsonb_build_object(
          'area',l.area,
          'side',l.side,
          'truncated',(CASE WHEN length(v.id) - length(code) <> 3 THEN TRUE ELSE FALSE END)))))::jsonb
  FROM regexp_split_to_table(p_code,',') code,
  LATERAL (SELECT afa.br_hex_to_hBig(substring(code,1,11))) m(hbig),
  LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.br_decode(hbig), afa.br_hBig_to_xyLRef(hbig)) v(id,geom,xyL),
  LATERAL (SELECT afa.br_cell_area(xyL[3]), afa.br_cell_side(xyL[3])) l(area,side)
$$;


ALTER FUNCTION afa.br_afacode_decode(p_code text) OWNER TO postgres;

--
-- Name: FUNCTION br_afacode_decode(p_code text); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.br_afacode_decode(p_code text) IS 'Decodes a scientific AFAcode.';


--
-- Name: br_afacode_encode(double precision, double precision, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.br_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
    SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
        'id',v.id,
        'jurisd_base_id',76,
        'properties', jsonb_build_object(
            'area',l.area,
            'side',l.side))))::jsonb
    FROM (SELECT afa.br_encode(p_lat,p_lon,p_level), afa.br_cell_area(p_level), afa.br_cell_side(p_level)) l(hbig,area,side),
    LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.br_decode(hbig)) v(id,geom)
$$;


ALTER FUNCTION afa.br_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) OWNER TO postgres;

--
-- Name: FUNCTION br_afacode_encode(p_lat double precision, p_lon double precision, p_level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.br_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) IS 'Encodes lat/lon to AFAcode grid scientific.';


--
-- Name: br_afacode_equalarea(public.geometry, integer, boolean); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.br_afacode_equalarea(pt public.geometry, level integer, addprefix boolean DEFAULT false) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.hBig_to_hex(afa.br_encode_equalarea(pt,level),addprefix)
$$;


ALTER FUNCTION afa.br_afacode_equalarea(pt public.geometry, level integer, addprefix boolean) OWNER TO postgres;

--
-- Name: FUNCTION br_afacode_equalarea(pt public.geometry, level integer, addprefix boolean); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.br_afacode_equalarea(pt public.geometry, level integer, addprefix boolean) IS 'Converts a geometry point in a country-specific projection to an AFAcode value based on the specified level and optional prefix.';


--
-- Name: br_cover_to_xy(bit varying); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.br_cover_to_xy(faceid bit varying) RETURNS integer[]
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $$
  SELECT afa.br_cover_to_xy((faceid::bit(32))::int)
$$;


ALTER FUNCTION afa.br_cover_to_xy(faceid bit varying) OWNER TO postgres;

--
-- Name: FUNCTION br_cover_to_xy(faceid bit varying); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.br_cover_to_xy(faceid bit varying) IS 'Wrapper function to convert a varbit faceid to faceid array..';


--
-- Name: br_decode(bigint); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.br_decode(hbig bigint) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT ST_GeomFromText( format('POLYGON((%s %s,%s %s,%s %s,%s %s,%s %s))', s[1],s[2],  s[1]+s[7]+s[7]*s[10],s[2],  s[1]+s[7]+s[7]*s[10],s[2]+s[7],  s[1],s[2]+s[7],  s[1],s[2]), 10857)
  FROM afa.br_hBig_to_xyLRef(hbig) t(s)
$$;


ALTER FUNCTION afa.br_decode(hbig bigint) OWNER TO postgres;

--
-- Name: FUNCTION br_decode(hbig bigint); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.br_decode(hbig bigint) IS 'Generates a cell geometry (polygon in country-specific projection) based on the AFAcode (hBig) value.';


--
-- Name: br_decode(text); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.br_decode(hex text) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.br_decode(afa.hex_to_hBig(hex))
$$;


ALTER FUNCTION afa.br_decode(hex text) OWNER TO postgres;

--
-- Name: FUNCTION br_decode(hex text); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.br_decode(hex text) IS 'Generates a cell geometry (polygon in country-specific projection) based on the AFAcode (in base16h with prefix) value.';


--
-- Name: br_decode(integer, integer, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.br_decode(x integer, y integer, level integer) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.br_decode(afa.br_encode(x,y,level))
$$;


ALTER FUNCTION afa.br_decode(x integer, y integer, level integer) OWNER TO postgres;

--
-- Name: FUNCTION br_decode(x integer, y integer, level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.br_decode(x integer, y integer, level integer) IS 'Generates a cell geometry (polygon in country-specific projection) based on the canonical xyL coordinates.';


--
-- Name: br_decode_point(bigint); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.br_decode_point(hbig bigint) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT ST_Point(s[1]::float+(s[7] + s[7]*s[10])/2.0, s[2]::float+s[7]/2.0, 10857)
  FROM afa.br_hBig_to_xyLRef(hbig) t(s)
$$;


ALTER FUNCTION afa.br_decode_point(hbig bigint) OWNER TO postgres;

--
-- Name: FUNCTION br_decode_point(hbig bigint); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.br_decode_point(hbig bigint) IS 'Generates a point geometry (in country-specific projection) representing the center of a cell based on the AFAcode (hBig) value.';


--
-- Name: br_decode_point(text); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.br_decode_point(hex text) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.br_decode_point(afa.hex_to_hBig(hex))
$$;


ALTER FUNCTION afa.br_decode_point(hex text) OWNER TO postgres;

--
-- Name: FUNCTION br_decode_point(hex text); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.br_decode_point(hex text) IS 'Generates a point geometry (in country-specific projection) representing the center of a cell based on the AFAcode (in base16h with prefix) value.';


--
-- Name: br_encode(public.geometry, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.br_encode(pt public.geometry, level integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.br_encode_equalarea(ST_Transform(pt,10857),level)
$$;


ALTER FUNCTION afa.br_encode(pt public.geometry, level integer) OWNER TO postgres;

--
-- Name: FUNCTION br_encode(pt public.geometry, level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.br_encode(pt public.geometry, level integer) IS 'Converts a geometry point (SRID 4326) into an AFAcode (hBig) value based on the specified level.';


--
-- Name: br_encode(double precision, double precision, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.br_encode(lat double precision, lon double precision, level integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.br_encode_equalarea(ST_Transform(ST_SetSRID(ST_Point(lon,lat),4326),10857),level)
$$;


ALTER FUNCTION afa.br_encode(lat double precision, lon double precision, level integer) OWNER TO postgres;

--
-- Name: FUNCTION br_encode(lat double precision, lon double precision, level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.br_encode(lat double precision, lon double precision, level integer) IS 'Converts latitude and longitude (in float and SRID 4326) into a AFAcode (hBig) value based on the specified level.';


--
-- Name: br_encode_equalarea(public.geometry, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.br_encode_equalarea(pt public.geometry, level integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.br_encode(floor(ST_X(pt))::int,floor(ST_Y(pt))::int,level)
$$;


ALTER FUNCTION afa.br_encode_equalarea(pt public.geometry, level integer) OWNER TO postgres;

--
-- Name: FUNCTION br_encode_equalarea(pt public.geometry, level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.br_encode_equalarea(pt public.geometry, level integer) IS 'Converts a geometry point in a country-specific projection to an AFAcode (hBig) value based on the specified level.';


--
-- Name: cm_afacode(public.geometry, integer, boolean); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.cm_afacode(pt public.geometry, level integer, addprefix boolean DEFAULT false) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.hBig_to_hex(afa.cm_encode(pt,level),addprefix)
$$;


ALTER FUNCTION afa.cm_afacode(pt public.geometry, level integer, addprefix boolean) OWNER TO postgres;

--
-- Name: FUNCTION cm_afacode(pt public.geometry, level integer, addprefix boolean); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.cm_afacode(pt public.geometry, level integer, addprefix boolean) IS 'Converts a geometry point (SRID 4326) into an AFAcode value based on the specified level and optional prefix.';


--
-- Name: cm_afacode(double precision, double precision, integer, boolean); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.cm_afacode(lat double precision, lon double precision, level integer, addprefix boolean DEFAULT false) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.hBig_to_hex(afa.cm_encode(lon,lat,level),addprefix)
$$;


ALTER FUNCTION afa.cm_afacode(lat double precision, lon double precision, level integer, addprefix boolean) OWNER TO postgres;

--
-- Name: FUNCTION cm_afacode(lat double precision, lon double precision, level integer, addprefix boolean); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.cm_afacode(lat double precision, lon double precision, level integer, addprefix boolean) IS 'Converts latitude and longitude (in float and SRID 4326) into a AFAcode value based on the specified level and optional prefix.';


--
-- Name: cm_afacode(integer, integer, integer, boolean); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.cm_afacode(x integer, y integer, level integer, addprefix boolean DEFAULT false) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.hBig_to_hex(afa.cm_encode(x,y,level),addprefix)
$$;


ALTER FUNCTION afa.cm_afacode(x integer, y integer, level integer, addprefix boolean) OWNER TO postgres;

--
-- Name: FUNCTION cm_afacode(x integer, y integer, level integer, addprefix boolean); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.cm_afacode(x integer, y integer, level integer, addprefix boolean) IS 'Converts canonical xyL coordinates to an AFAcode value based on the specified level and optional prefix.';


--
-- Name: cm_afacode_decode(text); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.cm_afacode_decode(p_code text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT
    jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
      'type','Feature',
      'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
      'id',v.id,
      'jurisd_base_id',120,
      'properties',jsonb_build_object(
          'area',l.area,
          'side',l.side,
          'truncated',(CASE WHEN length(v.id) - length(code) <> 3 THEN TRUE ELSE FALSE END)))))::jsonb
  FROM regexp_split_to_table(p_code,',') code,
  LATERAL (SELECT afa.cm_hex_to_hBig(substring(code,1,11))) m(hbig),
  LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.cm_decode(hbig), afa.cm_hBig_to_xyLRef(hbig)) v(id,geom,xyL),
  LATERAL (SELECT afa.cm_cell_area(xyL[3]), afa.cm_cell_side(xyL[3])) l(area,side)
$$;


ALTER FUNCTION afa.cm_afacode_decode(p_code text) OWNER TO postgres;

--
-- Name: FUNCTION cm_afacode_decode(p_code text); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.cm_afacode_decode(p_code text) IS 'Decodes a scientific AFAcode.';


--
-- Name: cm_afacode_encode(double precision, double precision, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.cm_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
    SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
        'id',v.id,
        'jurisd_base_id',120,
        'properties', jsonb_build_object(
            'area',l.area,
            'side',l.side))))::jsonb
    FROM (SELECT afa.cm_encode(p_lat,p_lon,p_level), afa.cm_cell_area(p_level), afa.cm_cell_side(p_level)) l(hbig,area,side),
    LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.cm_decode(hbig)) v(id,geom)
$$;


ALTER FUNCTION afa.cm_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) OWNER TO postgres;

--
-- Name: FUNCTION cm_afacode_encode(p_lat double precision, p_lon double precision, p_level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.cm_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) IS 'Encodes lat/lon to AFAcode grid scientific.';


--
-- Name: cm_afacode_equalarea(public.geometry, integer, boolean); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.cm_afacode_equalarea(pt public.geometry, level integer, addprefix boolean DEFAULT false) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.hBig_to_hex(afa.cm_encode_equalarea(pt,level),addprefix)
$$;


ALTER FUNCTION afa.cm_afacode_equalarea(pt public.geometry, level integer, addprefix boolean) OWNER TO postgres;

--
-- Name: FUNCTION cm_afacode_equalarea(pt public.geometry, level integer, addprefix boolean); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.cm_afacode_equalarea(pt public.geometry, level integer, addprefix boolean) IS 'Converts a geometry point in a country-specific projection to an AFAcode value based on the specified level and optional prefix.';


--
-- Name: cm_cover_to_xy(bit varying); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.cm_cover_to_xy(faceid bit varying) RETURNS integer[]
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $$
  SELECT afa.cm_cover_to_xy((faceid::bit(32))::int)
$$;


ALTER FUNCTION afa.cm_cover_to_xy(faceid bit varying) OWNER TO postgres;

--
-- Name: FUNCTION cm_cover_to_xy(faceid bit varying); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.cm_cover_to_xy(faceid bit varying) IS 'Wrapper function to convert a varbit faceid to faceid array..';


--
-- Name: cm_decode(bigint); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.cm_decode(hbig bigint) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT ST_GeomFromText( format('POLYGON((%s %s,%s %s,%s %s,%s %s,%s %s))', s[1],s[2],  s[1]+s[7]+s[7]*s[10],s[2],  s[1]+s[7]+s[7]*s[10],s[2]+s[7],  s[1],s[2]+s[7],  s[1],s[2]), 32632)
  FROM afa.cm_hBig_to_xyLRef(hbig) t(s)
$$;


ALTER FUNCTION afa.cm_decode(hbig bigint) OWNER TO postgres;

--
-- Name: FUNCTION cm_decode(hbig bigint); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.cm_decode(hbig bigint) IS 'Generates a cell geometry (polygon in country-specific projection) based on the AFAcode (hBig) value.';


--
-- Name: cm_decode(text); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.cm_decode(hex text) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.cm_decode(afa.hex_to_hBig(hex))
$$;


ALTER FUNCTION afa.cm_decode(hex text) OWNER TO postgres;

--
-- Name: FUNCTION cm_decode(hex text); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.cm_decode(hex text) IS 'Generates a cell geometry (polygon in country-specific projection) based on the AFAcode (in base16h with prefix) value.';


--
-- Name: cm_decode(integer, integer, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.cm_decode(x integer, y integer, level integer) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.cm_decode(afa.cm_encode(x,y,level))
$$;


ALTER FUNCTION afa.cm_decode(x integer, y integer, level integer) OWNER TO postgres;

--
-- Name: FUNCTION cm_decode(x integer, y integer, level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.cm_decode(x integer, y integer, level integer) IS 'Generates a cell geometry (polygon in country-specific projection) based on the canonical xyL coordinates.';


--
-- Name: cm_decode_point(bigint); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.cm_decode_point(hbig bigint) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT ST_Point(s[1]::float+(s[7] + s[7]*s[10])/2.0, s[2]::float+s[7]/2.0, 32632)
  FROM afa.cm_hBig_to_xyLRef(hbig) t(s)
$$;


ALTER FUNCTION afa.cm_decode_point(hbig bigint) OWNER TO postgres;

--
-- Name: FUNCTION cm_decode_point(hbig bigint); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.cm_decode_point(hbig bigint) IS 'Generates a point geometry (in country-specific projection) representing the center of a cell based on the AFAcode (hBig) value.';


--
-- Name: cm_decode_point(text); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.cm_decode_point(hex text) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.cm_decode_point(afa.hex_to_hBig(hex))
$$;


ALTER FUNCTION afa.cm_decode_point(hex text) OWNER TO postgres;

--
-- Name: FUNCTION cm_decode_point(hex text); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.cm_decode_point(hex text) IS 'Generates a point geometry (in country-specific projection) representing the center of a cell based on the AFAcode (in base16h with prefix) value.';


--
-- Name: cm_encode(public.geometry, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.cm_encode(pt public.geometry, level integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.cm_encode_equalarea(ST_Transform(pt,32632),level)
$$;


ALTER FUNCTION afa.cm_encode(pt public.geometry, level integer) OWNER TO postgres;

--
-- Name: FUNCTION cm_encode(pt public.geometry, level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.cm_encode(pt public.geometry, level integer) IS 'Converts a geometry point (SRID 4326) into an AFAcode (hBig) value based on the specified level.';


--
-- Name: cm_encode(double precision, double precision, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.cm_encode(lat double precision, lon double precision, level integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.cm_encode_equalarea(ST_Transform(ST_SetSRID(ST_Point(lon,lat),4326),32632),level)
$$;


ALTER FUNCTION afa.cm_encode(lat double precision, lon double precision, level integer) OWNER TO postgres;

--
-- Name: FUNCTION cm_encode(lat double precision, lon double precision, level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.cm_encode(lat double precision, lon double precision, level integer) IS 'Converts latitude and longitude (in float and SRID 4326) into a AFAcode (hBig) value based on the specified level.';


--
-- Name: cm_encode_equalarea(public.geometry, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.cm_encode_equalarea(pt public.geometry, level integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.cm_encode(floor(ST_X(pt))::int,floor(ST_Y(pt))::int,level)
$$;


ALTER FUNCTION afa.cm_encode_equalarea(pt public.geometry, level integer) OWNER TO postgres;

--
-- Name: FUNCTION cm_encode_equalarea(pt public.geometry, level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.cm_encode_equalarea(pt public.geometry, level integer) IS 'Converts a geometry point in a country-specific projection to an AFAcode (hBig) value based on the specified level.';


--
-- Name: co_afacode(public.geometry, integer, boolean); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.co_afacode(pt public.geometry, level integer, addprefix boolean DEFAULT false) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.hBig_to_hex(afa.co_encode(pt,level),addprefix)
$$;


ALTER FUNCTION afa.co_afacode(pt public.geometry, level integer, addprefix boolean) OWNER TO postgres;

--
-- Name: FUNCTION co_afacode(pt public.geometry, level integer, addprefix boolean); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.co_afacode(pt public.geometry, level integer, addprefix boolean) IS 'Converts a geometry point (SRID 4326) into an AFAcode value based on the specified level and optional prefix.';


--
-- Name: co_afacode(double precision, double precision, integer, boolean); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.co_afacode(lat double precision, lon double precision, level integer, addprefix boolean DEFAULT false) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.hBig_to_hex(afa.co_encode(lon,lat,level),addprefix)
$$;


ALTER FUNCTION afa.co_afacode(lat double precision, lon double precision, level integer, addprefix boolean) OWNER TO postgres;

--
-- Name: FUNCTION co_afacode(lat double precision, lon double precision, level integer, addprefix boolean); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.co_afacode(lat double precision, lon double precision, level integer, addprefix boolean) IS 'Converts latitude and longitude (in float and SRID 4326) into a AFAcode value based on the specified level and optional prefix.';


--
-- Name: co_afacode(integer, integer, integer, boolean); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.co_afacode(x integer, y integer, level integer, addprefix boolean DEFAULT false) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.hBig_to_hex(afa.co_encode(x,y,level),addprefix)
$$;


ALTER FUNCTION afa.co_afacode(x integer, y integer, level integer, addprefix boolean) OWNER TO postgres;

--
-- Name: FUNCTION co_afacode(x integer, y integer, level integer, addprefix boolean); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.co_afacode(x integer, y integer, level integer, addprefix boolean) IS 'Converts canonical xyL coordinates to an AFAcode value based on the specified level and optional prefix.';


--
-- Name: co_afacode_decode(text); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.co_afacode_decode(p_code text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT
    jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
      'type','Feature',
      'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
      'id',v.id,
      'jurisd_base_id',170,
      'properties',jsonb_build_object(
          'area',l.area,
          'side',l.side,
          'truncated',(CASE WHEN length(v.id) - length(code) <> 3 THEN TRUE ELSE FALSE END)))))::jsonb
  FROM regexp_split_to_table(p_code,',') code,
  LATERAL (SELECT afa.co_hex_to_hBig(substring(code,1,11))) m(hbig),
  LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.co_decode(hbig), afa.co_hBig_to_xyLRef(hbig)) v(id,geom,xyL),
  LATERAL (SELECT afa.co_cell_area(xyL[3]), afa.co_cell_side(xyL[3])) l(area,side)
$$;


ALTER FUNCTION afa.co_afacode_decode(p_code text) OWNER TO postgres;

--
-- Name: FUNCTION co_afacode_decode(p_code text); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.co_afacode_decode(p_code text) IS 'Decodes a scientific AFAcode.';


--
-- Name: co_afacode_encode(double precision, double precision, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.co_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
    SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
        'id',v.id,
        'jurisd_base_id',170,
        'properties', jsonb_build_object(
            'area',l.area,
            'side',l.side))))::jsonb
    FROM (SELECT afa.co_encode(p_lat,p_lon,p_level), afa.co_cell_area(p_level), afa.co_cell_side(p_level)) l(hbig,area,side),
    LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.co_decode(hbig)) v(id,geom)
$$;


ALTER FUNCTION afa.co_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) OWNER TO postgres;

--
-- Name: FUNCTION co_afacode_encode(p_lat double precision, p_lon double precision, p_level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.co_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) IS 'Encodes lat/lon to AFAcode grid scientific.';


--
-- Name: co_afacode_equalarea(public.geometry, integer, boolean); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.co_afacode_equalarea(pt public.geometry, level integer, addprefix boolean DEFAULT false) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.hBig_to_hex(afa.co_encode_equalarea(pt,level),addprefix)
$$;


ALTER FUNCTION afa.co_afacode_equalarea(pt public.geometry, level integer, addprefix boolean) OWNER TO postgres;

--
-- Name: FUNCTION co_afacode_equalarea(pt public.geometry, level integer, addprefix boolean); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.co_afacode_equalarea(pt public.geometry, level integer, addprefix boolean) IS 'Converts a geometry point in a country-specific projection to an AFAcode value based on the specified level and optional prefix.';


--
-- Name: co_cover_to_xy(bit varying); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.co_cover_to_xy(faceid bit varying) RETURNS integer[]
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $$
  SELECT afa.co_cover_to_xy((faceid::bit(32))::int)
$$;


ALTER FUNCTION afa.co_cover_to_xy(faceid bit varying) OWNER TO postgres;

--
-- Name: FUNCTION co_cover_to_xy(faceid bit varying); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.co_cover_to_xy(faceid bit varying) IS 'Wrapper function to convert a varbit faceid to faceid array..';


--
-- Name: co_decode(bigint); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.co_decode(hbig bigint) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT ST_GeomFromText( format('POLYGON((%s %s,%s %s,%s %s,%s %s,%s %s))', s[1],s[2],  s[1]+s[7]+s[7]*s[10],s[2],  s[1]+s[7]+s[7]*s[10],s[2]+s[7],  s[1],s[2]+s[7],  s[1],s[2]), 9377)
  FROM afa.co_hBig_to_xyLRef(hbig) t(s)
$$;


ALTER FUNCTION afa.co_decode(hbig bigint) OWNER TO postgres;

--
-- Name: FUNCTION co_decode(hbig bigint); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.co_decode(hbig bigint) IS 'Generates a cell geometry (polygon in country-specific projection) based on the AFAcode (hBig) value.';


--
-- Name: co_decode(text); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.co_decode(hex text) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.co_decode(afa.hex_to_hBig(hex))
$$;


ALTER FUNCTION afa.co_decode(hex text) OWNER TO postgres;

--
-- Name: FUNCTION co_decode(hex text); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.co_decode(hex text) IS 'Generates a cell geometry (polygon in country-specific projection) based on the AFAcode (in base16h with prefix) value.';


--
-- Name: co_decode(integer, integer, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.co_decode(x integer, y integer, level integer) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.co_decode(afa.co_encode(x,y,level))
$$;


ALTER FUNCTION afa.co_decode(x integer, y integer, level integer) OWNER TO postgres;

--
-- Name: FUNCTION co_decode(x integer, y integer, level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.co_decode(x integer, y integer, level integer) IS 'Generates a cell geometry (polygon in country-specific projection) based on the canonical xyL coordinates.';


--
-- Name: co_decode_point(bigint); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.co_decode_point(hbig bigint) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT ST_Point(s[1]::float+(s[7] + s[7]*s[10])/2.0, s[2]::float+s[7]/2.0, 9377)
  FROM afa.co_hBig_to_xyLRef(hbig) t(s)
$$;


ALTER FUNCTION afa.co_decode_point(hbig bigint) OWNER TO postgres;

--
-- Name: FUNCTION co_decode_point(hbig bigint); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.co_decode_point(hbig bigint) IS 'Generates a point geometry (in country-specific projection) representing the center of a cell based on the AFAcode (hBig) value.';


--
-- Name: co_decode_point(text); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.co_decode_point(hex text) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.co_decode_point(afa.hex_to_hBig(hex))
$$;


ALTER FUNCTION afa.co_decode_point(hex text) OWNER TO postgres;

--
-- Name: FUNCTION co_decode_point(hex text); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.co_decode_point(hex text) IS 'Generates a point geometry (in country-specific projection) representing the center of a cell based on the AFAcode (in base16h with prefix) value.';


--
-- Name: co_encode(public.geometry, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.co_encode(pt public.geometry, level integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.co_encode_equalarea(ST_Transform(pt,9377),level)
$$;


ALTER FUNCTION afa.co_encode(pt public.geometry, level integer) OWNER TO postgres;

--
-- Name: FUNCTION co_encode(pt public.geometry, level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.co_encode(pt public.geometry, level integer) IS 'Converts a geometry point (SRID 4326) into an AFAcode (hBig) value based on the specified level.';


--
-- Name: co_encode(double precision, double precision, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.co_encode(lat double precision, lon double precision, level integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.co_encode_equalarea(ST_Transform(ST_SetSRID(ST_Point(lon,lat),4326),9377),level)
$$;


ALTER FUNCTION afa.co_encode(lat double precision, lon double precision, level integer) OWNER TO postgres;

--
-- Name: FUNCTION co_encode(lat double precision, lon double precision, level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.co_encode(lat double precision, lon double precision, level integer) IS 'Converts latitude and longitude (in float and SRID 4326) into a AFAcode (hBig) value based on the specified level.';


--
-- Name: co_encode_equalarea(public.geometry, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.co_encode_equalarea(pt public.geometry, level integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.co_encode(floor(ST_X(pt))::int,floor(ST_Y(pt))::int,level)
$$;


ALTER FUNCTION afa.co_encode_equalarea(pt public.geometry, level integer) OWNER TO postgres;

--
-- Name: FUNCTION co_encode_equalarea(pt public.geometry, level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.co_encode_equalarea(pt public.geometry, level integer) IS 'Converts a geometry point in a country-specific projection to an AFAcode (hBig) value based on the specified level.';


--
-- Name: hbig_to_geom(bigint[]); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.hbig_to_geom(hbig_cells bigint[]) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
 SELECT ST_Union(afa.br_decode(x))
 FROM unnest(hbig_cells) t(x)
$$;


ALTER FUNCTION afa.hbig_to_geom(hbig_cells bigint[]) OWNER TO postgres;

--
-- Name: FUNCTION hbig_to_geom(hbig_cells bigint[]); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.hbig_to_geom(hbig_cells bigint[]) IS 'Converts an array of hBig into a combined geometry object.';


--
-- Name: hbig_to_hex(bigint[], boolean); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.hbig_to_hex(hbig_cells bigint[], addprefix boolean DEFAULT false) RETURNS text[]
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
 SELECT array_agg(afa.hbig_to_hex(x,addprefix) ORDER BY x)
 FROM unnest(hbig_cells) t(x)
$$;


ALTER FUNCTION afa.hbig_to_hex(hbig_cells bigint[], addprefix boolean) OWNER TO postgres;

--
-- Name: FUNCTION hbig_to_hex(hbig_cells bigint[], addprefix boolean); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.hbig_to_hex(hbig_cells bigint[], addprefix boolean) IS 'Converts an array of hBig to hexadecimal string representations.';


--
-- Name: redux_hbig(bigint[]); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.redux_hbig(args bigint[]) RETURNS bigint[]
    LANGUAGE plpgsql
    AS $$
DECLARE
    result bigint[] := '{}';                   -- Final result array, initialized as empty
    chunk bigint[];                            -- Array holding the current chunk
    processed_chunk bigint[];                  -- Temporary array to hold results for the chunk
    chunk_size INT := 400000;                  -- Maximum chunk size
    num_elements INT := COALESCE(array_length(args, 1),0); -- Length of the input array
    i INT;                                     -- Iterator for processing each chunk
    start_index INT;                           -- Start index for the current chunk
    end_index INT;                             -- End index for the current chunk
BEGIN
    -- Print initial message about the start of the process
    -- RAISE NOTICE 'Starting to process an array of % elements.', num_elements;

    -- If the input array is empty, return it immediately
    IF num_elements = 0 THEN RETURN args; END IF;

    -- Sort the args before continuing
    args := array(SELECT DISTINCT * FROM unnest(args) ORDER BY 1);

    -- Process the array in chunks (divide array into chunks of chunk_size)
    FOR i IN 1..CEIL(num_elements::float / chunk_size) LOOP
        -- Calculate start and end indices for the current chunk
        start_index := (i - 1) * chunk_size + 1;
        end_index := LEAST(i * chunk_size, num_elements);

        -- Extract the chunk from the input array
        chunk := args[start_index:end_index];

        -- Log the current chunk being processed
        -- RAISE NOTICE 'Processing chunk % of % (elements % to %).', i, CEIL(num_elements::float / chunk_size), start_index, end_index;

        -- Process the chunk by applying the redux function until no change occurs
        LOOP
            processed_chunk := afa.redux_hbig_chunk(chunk);

            -- Check if the chunk has been fully reduced
            IF processed_chunk = chunk THEN
                -- RAISE NOTICE 'Chunk processed successfully with no changes.';
                EXIT;
            ELSE
                -- Sort the processed_chunk before continuing
                chunk := array(SELECT DISTINCT * FROM unnest(processed_chunk) ORDER BY 1);
                -- RAISE NOTICE 'Chunk still being reduced, new size: % elements.', array_length(processed_chunk, 1);
            END IF;
        END LOOP;

        -- Append the processed (and sorted) chunk to the final result
        result := result || processed_chunk;

        -- Log the completion of chunk processing
        -- RAISE NOTICE 'Chunk % processed and added to the result array.', i;
    END LOOP;

    -- Sort the entire result array before returning
    result := array(SELECT DISTINCT * FROM unnest(result) ORDER BY 1);

    -- Print final message and return the result
    -- RAISE NOTICE 'Processing complete, returning the final result with % elements.', array_length(result, 1);

    -- Return the final collapsed and sorted array
    RETURN result;
END;
$$;


ALTER FUNCTION afa.redux_hbig(args bigint[]) OWNER TO postgres;

--
-- Name: FUNCTION redux_hbig(args bigint[]); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.redux_hbig(args bigint[]) IS 'Processes an input array of bigints in chunks, applying a reduction function to each chunk and concatenating the results into a final array.';


--
-- Name: sv_afacode(public.geometry, integer, boolean); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.sv_afacode(pt public.geometry, level integer, addprefix boolean DEFAULT false) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.hBig_to_hex(afa.sv_encode(pt,level),addprefix)
$$;


ALTER FUNCTION afa.sv_afacode(pt public.geometry, level integer, addprefix boolean) OWNER TO postgres;

--
-- Name: FUNCTION sv_afacode(pt public.geometry, level integer, addprefix boolean); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.sv_afacode(pt public.geometry, level integer, addprefix boolean) IS 'Converts a geometry point (SRID 4326) into an AFAcode value based on the specified level and optional prefix.';


--
-- Name: sv_afacode(double precision, double precision, integer, boolean); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.sv_afacode(lat double precision, lon double precision, level integer, addprefix boolean DEFAULT false) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.hBig_to_hex(afa.sv_encode(lon,lat,level),addprefix)
$$;


ALTER FUNCTION afa.sv_afacode(lat double precision, lon double precision, level integer, addprefix boolean) OWNER TO postgres;

--
-- Name: FUNCTION sv_afacode(lat double precision, lon double precision, level integer, addprefix boolean); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.sv_afacode(lat double precision, lon double precision, level integer, addprefix boolean) IS 'Converts latitude and longitude (in float and SRID 4326) into a AFAcode value based on the specified level and optional prefix.';


--
-- Name: sv_afacode(integer, integer, integer, boolean); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.sv_afacode(x integer, y integer, level integer, addprefix boolean DEFAULT false) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.hBig_to_hex(afa.sv_encode(x,y,level),addprefix)
$$;


ALTER FUNCTION afa.sv_afacode(x integer, y integer, level integer, addprefix boolean) OWNER TO postgres;

--
-- Name: FUNCTION sv_afacode(x integer, y integer, level integer, addprefix boolean); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.sv_afacode(x integer, y integer, level integer, addprefix boolean) IS 'Converts canonical xyL coordinates to an AFAcode value based on the specified level and optional prefix.';


--
-- Name: sv_afacode_decode(text); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.sv_afacode_decode(p_code text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT
    jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
      'type','Feature',
      'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
      'id',v.id,
      'jurisd_base_id',222,
      'properties',jsonb_build_object(
          'area',l.area,
          'side',l.side,
          'truncated',(CASE WHEN length(v.id) - length(code) <> 3 THEN TRUE ELSE FALSE END)))))::jsonb
  FROM regexp_split_to_table(p_code,',') code,
  LATERAL (SELECT afa.sv_hex_to_hBig(substring(code,1,11))) m(hbig),
  LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.sv_decode(hbig), afa.sv_hBig_to_xyLRef(hbig)) v(id,geom,xyL),
  LATERAL (SELECT afa.sv_cell_area(xyL[3]), afa.sv_cell_side(xyL[3])) l(area,side)
$$;


ALTER FUNCTION afa.sv_afacode_decode(p_code text) OWNER TO postgres;

--
-- Name: FUNCTION sv_afacode_decode(p_code text); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.sv_afacode_decode(p_code text) IS 'Decodes a scientific AFAcode.';


--
-- Name: sv_afacode_encode(double precision, double precision, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.sv_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
    SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
        'id',v.id,
        'jurisd_base_id',222,
        'properties', jsonb_build_object(
            'area',l.area,
            'side',l.side))))::jsonb
    FROM (SELECT afa.sv_encode(p_lat,p_lon,p_level), afa.sv_cell_area(p_level), afa.sv_cell_side(p_level)) l(hbig,area,side),
    LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.sv_decode(hbig)) v(id,geom)
$$;


ALTER FUNCTION afa.sv_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) OWNER TO postgres;

--
-- Name: FUNCTION sv_afacode_encode(p_lat double precision, p_lon double precision, p_level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.sv_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) IS 'Encodes lat/lon to AFAcode grid scientific.';


--
-- Name: sv_afacode_equalarea(public.geometry, integer, boolean); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.sv_afacode_equalarea(pt public.geometry, level integer, addprefix boolean DEFAULT false) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.hBig_to_hex(afa.sv_encode_equalarea(pt,level),addprefix)
$$;


ALTER FUNCTION afa.sv_afacode_equalarea(pt public.geometry, level integer, addprefix boolean) OWNER TO postgres;

--
-- Name: FUNCTION sv_afacode_equalarea(pt public.geometry, level integer, addprefix boolean); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.sv_afacode_equalarea(pt public.geometry, level integer, addprefix boolean) IS 'Converts a geometry point in a country-specific projection to an AFAcode value based on the specified level and optional prefix.';


--
-- Name: sv_cover_to_xy(bit varying); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.sv_cover_to_xy(faceid bit varying) RETURNS integer[]
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $$
  SELECT afa.sv_cover_to_xy((faceid::bit(32))::int)
$$;


ALTER FUNCTION afa.sv_cover_to_xy(faceid bit varying) OWNER TO postgres;

--
-- Name: FUNCTION sv_cover_to_xy(faceid bit varying); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.sv_cover_to_xy(faceid bit varying) IS 'Wrapper function to convert a varbit faceid to faceid array..';


--
-- Name: sv_decode(bigint); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.sv_decode(hbig bigint) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT ST_GeomFromText( format('POLYGON((%s %s,%s %s,%s %s,%s %s,%s %s))', s[1],s[2],  s[1]+s[7]+s[7]*s[10],s[2],  s[1]+s[7]+s[7]*s[10],s[2]+s[7],  s[1],s[2]+s[7],  s[1],s[2]), 5399)
  FROM afa.sv_hBig_to_xyLRef(hbig) t(s)
$$;


ALTER FUNCTION afa.sv_decode(hbig bigint) OWNER TO postgres;

--
-- Name: FUNCTION sv_decode(hbig bigint); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.sv_decode(hbig bigint) IS 'Generates a cell geometry (polygon in country-specific projection) based on the AFAcode (hBig) value.';


--
-- Name: sv_decode(text); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.sv_decode(hex text) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.sv_decode(afa.hex_to_hBig(hex))
$$;


ALTER FUNCTION afa.sv_decode(hex text) OWNER TO postgres;

--
-- Name: FUNCTION sv_decode(hex text); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.sv_decode(hex text) IS 'Generates a cell geometry (polygon in country-specific projection) based on the AFAcode (in base16h with prefix) value.';


--
-- Name: sv_decode(integer, integer, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.sv_decode(x integer, y integer, level integer) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.sv_decode(afa.sv_encode(x,y,level))
$$;


ALTER FUNCTION afa.sv_decode(x integer, y integer, level integer) OWNER TO postgres;

--
-- Name: FUNCTION sv_decode(x integer, y integer, level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.sv_decode(x integer, y integer, level integer) IS 'Generates a cell geometry (polygon in country-specific projection) based on the canonical xyL coordinates.';


--
-- Name: sv_decode_point(bigint); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.sv_decode_point(hbig bigint) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT ST_Point(s[1]::float+(s[7] + s[7]*s[10])/2.0, s[2]::float+s[7]/2.0, 5399)
  FROM afa.sv_hBig_to_xyLRef(hbig) t(s)
$$;


ALTER FUNCTION afa.sv_decode_point(hbig bigint) OWNER TO postgres;

--
-- Name: FUNCTION sv_decode_point(hbig bigint); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.sv_decode_point(hbig bigint) IS 'Generates a point geometry (in country-specific projection) representing the center of a cell based on the AFAcode (hBig) value.';


--
-- Name: sv_decode_point(text); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.sv_decode_point(hex text) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.sv_decode_point(afa.hex_to_hBig(hex))
$$;


ALTER FUNCTION afa.sv_decode_point(hex text) OWNER TO postgres;

--
-- Name: FUNCTION sv_decode_point(hex text); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.sv_decode_point(hex text) IS 'Generates a point geometry (in country-specific projection) representing the center of a cell based on the AFAcode (in base16h with prefix) value.';


--
-- Name: sv_encode(public.geometry, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.sv_encode(pt public.geometry, level integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.sv_encode_equalarea(ST_Transform(pt,5399),level)
$$;


ALTER FUNCTION afa.sv_encode(pt public.geometry, level integer) OWNER TO postgres;

--
-- Name: FUNCTION sv_encode(pt public.geometry, level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.sv_encode(pt public.geometry, level integer) IS 'Converts a geometry point (SRID 4326) into an AFAcode (hBig) value based on the specified level.';


--
-- Name: sv_encode(double precision, double precision, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.sv_encode(lat double precision, lon double precision, level integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.sv_encode_equalarea(ST_Transform(ST_SetSRID(ST_Point(lon,lat),4326),5399),level)
$$;


ALTER FUNCTION afa.sv_encode(lat double precision, lon double precision, level integer) OWNER TO postgres;

--
-- Name: FUNCTION sv_encode(lat double precision, lon double precision, level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.sv_encode(lat double precision, lon double precision, level integer) IS 'Converts latitude and longitude (in float and SRID 4326) into a AFAcode (hBig) value based on the specified level.';


--
-- Name: sv_encode_equalarea(public.geometry, integer); Type: FUNCTION; Schema: afa; Owner: postgres
--

CREATE FUNCTION afa.sv_encode_equalarea(pt public.geometry, level integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT afa.sv_encode(floor(ST_X(pt))::int,floor(ST_Y(pt))::int,level)
$$;


ALTER FUNCTION afa.sv_encode_equalarea(pt public.geometry, level integer) OWNER TO postgres;

--
-- Name: FUNCTION sv_encode_equalarea(pt public.geometry, level integer); Type: COMMENT; Schema: afa; Owner: postgres
--

COMMENT ON FUNCTION afa.sv_encode_equalarea(pt public.geometry, level integer) IS 'Converts a geometry point in a country-specific projection to an AFAcode (hBig) value based on the specified level.';


--
-- Name: afacode_decode(text, text); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.afacode_decode(p_code text, p_iso text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  WITH
  input_validated AS (
    SELECT
      list,
      --list IS NOT NULL AND array_length(list, 1) > 0 AS is_valid
      TRUE AS is_valid
    FROM natcod.reduxseq_to_list(p_code) u(list)
  ),
  decoded AS (
    SELECT *,
      CASE p_iso
        WHEN 'BR' THEN osmc.br_afacode_decode(list)
        WHEN 'CM' THEN osmc.cm_afacode_decode(list)
        WHEN 'CO' THEN osmc.co_afacode_decode(list)
        WHEN 'SV' THEN osmc.sv_afacode_decode(list)
        ELSE NULL
      END AS result
    FROM input_validated
  )
  SELECT
    CASE
      WHEN NOT is_valid                                   THEN jsonb_build_object('error','Invalid or empty AFAcode input.','code',1)
      WHEN p_iso NOT IN ('BR', 'CM', 'CO', 'SV')          THEN jsonb_build_object('error','Jurisdiction not supported.','code',2)
      WHEN (result #> '{features,0}') IS NULL             THEN jsonb_build_object('error','No feature returned.','code',3)
      WHEN (result #> '{features,0,geometry}') IS NULL    THEN jsonb_build_object('error','Invalid geometry.','code',4)
      WHEN (result #>> '{features,0,id}') IS NULL
           OR (result #>> '{features,0,id}') = 'null'     THEN jsonb_build_object('error','Invalid ID.','code',5)
      ELSE result
    END
  FROM decoded
$$;


ALTER FUNCTION api.afacode_decode(p_code text, p_iso text) OWNER TO postgres;

--
-- Name: FUNCTION afacode_decode(p_code text, p_iso text); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.afacode_decode(p_code text, p_iso text) IS 'Decodes a scientific AFAcode. Jurisdictional context is required. Returns GeoJSON or structured error.';


--
-- Name: afacode_decode_log(text); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.afacode_decode_log(p_code text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  WITH
  split_parts AS (
    SELECT regexp_split_to_array(p_code, '~') AS u
  ),
  parts AS (
    SELECT
      u[1] AS geo_part,
      u[2] AS code_part
    FROM split_parts
    WHERE array_length(u,1) = 2
  ),
  decoded_iso AS (
    SELECT
      str_geocodeiso_decode(geo_part) AS l,
      code_part
    FROM parts
  ),
  encoded AS (
    SELECT *,
      CASE l[2]
        WHEN 'BR' THEN osmc.br_afacode_decode_log( upper(REPLACE(code_part,'.','')), l[1] )
        WHEN 'CM' THEN osmc.cm_afacode_decode_log( upper(REPLACE(code_part,'.','')), l[1] )
        WHEN 'CO' THEN osmc.co_afacode_decode_log( upper(REPLACE(code_part,'.','')), l[1] )
        WHEN 'SV' THEN osmc.sv_afacode_decode_log( upper(REPLACE(code_part,'.','')), l[1] )
        ELSE jsonb_build_object('error', 'Jurisdiction not supported.')
      END AS result
    FROM decoded_iso
  )
  SELECT
    CASE
      WHEN NOT EXISTS (SELECT 1 FROM split_parts) OR array_length((SELECT u FROM split_parts), 1) != 2 THEN jsonb_build_object('error','Invalid AFAcode format.','code',1)
      WHEN (SELECT code_part FROM parts) IS NULL THEN jsonb_build_object('error','Missing code component after jurisdiction.','code',2)
      WHEN l[2] NOT IN ('BR','CM','CO','SV') THEN jsonb_build_object('error','Jurisdiction not supported.','code',3)
      ELSE result
    END
  FROM encoded
$$;


ALTER FUNCTION api.afacode_decode_log(p_code text) OWNER TO postgres;

--
-- Name: FUNCTION afacode_decode_log(p_code text); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.afacode_decode_log(p_code text) IS 'Decodes a logistic AFAcode.';


--
-- Name: afacode_decode_log_abs(text); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.afacode_decode_log_abs(p_code text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  WITH
  split_parts AS (
    SELECT regexp_split_to_array(p_code, '~') AS u
  ),
  parts AS (
    SELECT
      u[1] AS geo_part,
      u[2] AS code_part
    FROM split_parts
    WHERE array_length(u,1) = 2
  ),
  decoded_iso AS (
    SELECT
      str_geocodeiso_decode(geo_part) AS l,
      code_part
    FROM parts
  ),
  encoded AS (
    SELECT *,
      CASE l[2]
        WHEN 'BR' THEN osmc.br_afacode_decode_log_abs( upper(REPLACE(code_part,'.','')) )
        ELSE jsonb_build_object('error', 'Jurisdiction not supported.')
      END AS result
    FROM decoded_iso
  )
  SELECT
    CASE
      WHEN NOT EXISTS (SELECT 1 FROM split_parts) OR array_length((SELECT u FROM split_parts), 1) != 2 THEN jsonb_build_object('error','Invalid AFAcode format.','code',1)
      WHEN (SELECT code_part FROM parts) IS NULL THEN jsonb_build_object('error','Missing code component after jurisdiction.','code',2)
      WHEN l[2] NOT IN ('BR') THEN jsonb_build_object('error','Jurisdiction not supported.','code',3)
      ELSE result
    END
  FROM encoded
$$;


ALTER FUNCTION api.afacode_decode_log_abs(p_code text) OWNER TO postgres;

--
-- Name: FUNCTION afacode_decode_log_abs(p_code text); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.afacode_decode_log_abs(p_code text) IS 'Decodes a logistic AFAcode without jurisdiction local prefix.';


--
-- Name: afacode_encode(text, text); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.afacode_encode(p_uri text, p_iso text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  WITH
  params AS (
    SELECT
      u[1]::float AS lat,
      u[2]::float AS lon,
      u[3]::float AS scale
    FROM osmc.str_geouri_decode(p_uri) t(u)
  ),
  levels AS (
    SELECT
      lat, lon, scale,
      CASE p_iso
        WHEN 'BR' THEN COALESCE(afa.br_cell_nearst_level(scale), 40)
        WHEN 'CM' THEN COALESCE(afa.cm_cell_nearst_level(scale), 36)
        WHEN 'CO' THEN COALESCE(afa.co_cell_nearst_level(scale), 38)
        WHEN 'SV' THEN COALESCE(afa.sv_cell_nearst_level(scale), 32)
        ELSE NULL
      END AS level
    FROM params
  ),
  raw_result AS (
    SELECT *,
      CASE p_iso
        WHEN 'BR' THEN osmc.br_afacode_encode(lat, lon, level)
        WHEN 'CM' THEN osmc.cm_afacode_encode(lat, lon, level)
        WHEN 'CO' THEN osmc.co_afacode_encode(lat, lon, level)
        WHEN 'SV' THEN osmc.sv_afacode_encode(lat, lon, level)
        ELSE NULL
      END AS result
    FROM levels
  )
  SELECT
    CASE
      WHEN (result IS NULL)                                 THEN jsonb_build_object('error','Jurisdiction not supported.','code',1)
      WHEN (result #> '{features,0}') IS NULL               THEN jsonb_build_object('error','No feature returned.','code',2)
      WHEN (result #> '{features,0,geometry}') IS NULL
           OR (result #>> '{features,0,geometry}') = 'null' THEN jsonb_build_object('error','Invalid geometry.','code',3)
      WHEN (result #>> '{features,0,id}') IS NULL
           OR (result #>> '{features,0,id}') = 'null'       THEN jsonb_build_object('error','Invalid ID.','code',4)
      ELSE result
    END
  FROM raw_result
$$;


ALTER FUNCTION api.afacode_encode(p_uri text, p_iso text) OWNER TO postgres;

--
-- Name: FUNCTION afacode_encode(p_uri text, p_iso text); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.afacode_encode(p_uri text, p_iso text) IS 'Encodes a GeoURI into a scientific AFAcode. Jurisdictional context is required.';


--
-- Name: afacode_encode_log(text, text); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.afacode_encode_log(p_uri text, p_iso text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  WITH
  parsed AS (
    SELECT u[1]::float AS lat, u[2]::float AS lon, u[3] AS lvl, split_part(p_iso,'-',1) AS iso_alpha2
    FROM osmc.str_geouri_decode(p_uri) t(u)
  ),
  resolved_level AS (
    SELECT *,
      CASE iso_alpha2
        WHEN 'BR' THEN COALESCE(ROUND((afa.br_cell_nearst_level(lvl)/5)*5)::int, 35) -- old
        WHEN 'CM' THEN COALESCE(ROUND((LEAST(afa.cm_cell_nearst_level(lvl),36)/5)*5 + 1)::int, 31)
        WHEN 'CO' THEN COALESCE(ROUND((LEAST(afa.co_cell_nearst_level(lvl),38)/5)*5 + 3)::int, 33)
        WHEN 'SV' THEN COALESCE(ROUND((LEAST(afa.sv_cell_nearst_level(lvl),32)/4)*4)::int, 28)
        ELSE NULL
      END AS level
    FROM parsed
  ),
  encoded AS (
    SELECT *,
      CASE iso_alpha2
        WHEN 'BR' THEN osmc.br_afacode_encode_log(lat,lon,level,p_iso) -- old
        WHEN 'CM' THEN osmc.cm_afacode_encode_log(lat,lon,level,p_iso)
        WHEN 'CO' THEN osmc.co_afacode_encode_log(lat,lon,level,p_iso)
        WHEN 'SV' THEN osmc.sv_afacode_encode_log(lat,lon,level,p_iso)
        ELSE NULL
      END AS result
    FROM resolved_level
  )
  SELECT
    CASE
      WHEN iso_alpha2 NOT IN ('BR','CM','CO','SV') THEN jsonb_build_object('error','Jurisdiction not supported.','code',1)
      WHEN (result #> '{features,0}') IS NULL                   THEN jsonb_build_object('error','No feature returned.','code',2)
      WHEN (result #> '{features,0,geometry}') IS NULL
           OR (result #>> '{features,0,geometry}') = 'null'     THEN jsonb_build_object('error','Invalid geometry.','code',3)
      WHEN (result #>> '{features,0,id}') IS NULL               THEN jsonb_build_object('error','Invalid ID.','code',4)
      ELSE result
    END
  FROM encoded
$$;


ALTER FUNCTION api.afacode_encode_log(p_uri text, p_iso text) OWNER TO postgres;

--
-- Name: FUNCTION afacode_encode_log(p_uri text, p_iso text); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.afacode_encode_log(p_uri text, p_iso text) IS 'Encodes a GeoURI into a logistic AFAcode. Jurisdictional context is required.';


--
-- Name: afacode_encode_log_abs(text, text); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.afacode_encode_log_abs(p_uri text, p_iso text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  WITH
  parsed AS (
    SELECT u[1]::float AS lat, u[2]::float AS lon, u[3] AS lvl, split_part(p_iso,'-',1) AS iso_alpha2
    FROM osmc.str_geouri_decode(p_uri) t(u)
  ),
  resolved_level AS (
    SELECT *,
      CASE iso_alpha2
        WHEN 'BR' THEN COALESCE(ROUND((LEAST(afa.br_cell_nearst_level(lvl),36)/5)*5)::int+1, 36)
        ELSE NULL
      END AS level
    FROM parsed
  ),
  encoded AS (
    SELECT *,
      CASE iso_alpha2
        WHEN 'BR' THEN osmc.br_afacode_encode_log_abs(lat,lon,level)
        ELSE NULL
      END AS result
    FROM resolved_level
  )
  SELECT
    CASE
      WHEN iso_alpha2 NOT IN ('BR') THEN jsonb_build_object('error','Jurisdiction not supported.','code',1)
      WHEN (result #> '{features,0}') IS NULL                   THEN jsonb_build_object('error','No feature returned.','code',2)
      WHEN (result #> '{features,0,geometry}') IS NULL
           OR (result #>> '{features,0,geometry}') = 'null'     THEN jsonb_build_object('error','Invalid geometry.','code',3)
      WHEN (result #>> '{features,0,id}') IS NULL               THEN jsonb_build_object('error','Invalid ID.','code',4)
      ELSE result
    END
  FROM encoded
$$;


ALTER FUNCTION api.afacode_encode_log_abs(p_uri text, p_iso text) OWNER TO postgres;

--
-- Name: FUNCTION afacode_encode_log_abs(p_uri text, p_iso text); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.afacode_encode_log_abs(p_uri text, p_iso text) IS 'Encodes a GeoURI into a logistic AFAcode without jurisdiction local prefix. Jurisdictional context is required.';


--
-- Name: afacode_encode_log_no_context(text); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.afacode_encode_log_no_context(p_uri text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  WITH
  decoded_point AS
  (
    SELECT ST_SetSRID(ST_MakePoint(a.udec[2],a.udec[1]),4326) AS pt
    FROM osmc.str_geouri_decode(p_uri) a(udec)
  ),
  candidate_bbox AS
  (
    SELECT bbox.id, bbox.jurisd_base_id, bbox.isolabel_ext, dp.pt
    FROM osmc.jurisdiction_bbox bbox
    JOIN decoded_point dp
    ON dp.pt && bbox.geom
  ),
  resolved_jurisdiction AS (
    SELECT
      cb.id,
      cb.pt,
      COALESCE(cb.jurisd_base_id, border.jurisd_base_id) AS jurisd_base_id,
      COALESCE(cb.isolabel_ext, border.isolabel_ext) AS isolabel_ext
    FROM candidate_bbox cb
    LEFT JOIN LATERAL
    (
      SELECT b.jurisd_base_id, b.isolabel_ext
      FROM osmc.mvjurisdiction_bbox_border b
      WHERE b.bbox_id = cb.id
        AND ST_Intersects(b.geom,cb.pt)
      LIMIT 1
    ) border
    ON cb.jurisd_base_id IS NULL
  ),
  transformed_point AS
  (
    SELECT id, jurisd_base_id, isolabel_ext,
        CASE isolabel_ext
          WHEN 'BR' THEN ST_Transform(rj.pt,10857)
          WHEN 'CM' THEN ST_Transform(rj.pt,32632)
          WHEN 'CO' THEN ST_Transform(rj.pt,9377)
          WHEN 'UY' THEN ST_Transform(rj.pt,32721)
          WHEN 'EC' THEN ST_Transform(rj.pt,32717)
          WHEN 'SV' THEN ST_Transform(rj.pt,5399)
        END AS pt
    FROM resolved_jurisdiction rj
  ),
  matched_coverage AS (
    SELECT g.isolabel_ext, e.isolabel_ext AS country
    FROM transformed_point e
    LEFT JOIN osmc.mvwcoverage g
    ON e.pt && g.geom
      AND g.isolabel_ext LIKE split_part(e.isolabel_ext,'-',1) || '%'
      AND (is_contained IS TRUE OR ST_intersects(e.pt,g.geom))
      AND g.is_country IS FALSE
  ),
  encoded AS (
    SELECT
        CASE
          WHEN country = 'BR' THEN api.afacode_encode_log_abs(p_uri,'BR')
          ELSE api.afacode_encode_log(p_uri,mc.isolabel_ext)
        END AS result

    FROM matched_coverage mc
  )
  SELECT
    CASE
      WHEN NOT EXISTS (SELECT 1 FROM decoded_point)         THEN jsonb_build_object('error','Invalid GeoURI.','code',1)
      WHEN NOT EXISTS (SELECT 1 FROM resolved_jurisdiction) THEN jsonb_build_object('error','Jurisdiction not found.','code',2)
      WHEN NOT EXISTS (SELECT 1 FROM matched_coverage)      THEN jsonb_build_object('error','Jurisdiction coverage not found.','code',3)
      WHEN (encoded.result #> '{features,0}') IS NULL       THEN jsonb_build_object('error','No feature returned.','code',4)
      ELSE encoded.result
    END
  FROM encoded
$$;


ALTER FUNCTION api.afacode_encode_log_no_context(p_uri text) OWNER TO postgres;

--
-- Name: FUNCTION afacode_encode_log_no_context(p_uri text); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.afacode_encode_log_no_context(p_uri text) IS 'Encodes a GeoURI into a logistic AFAcode. No jurisdictional context is required.';


--
-- Name: download_list(); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.download_list() RETURNS jsonb
    LANGUAGE sql
    AS $$
    SELECT *
    FROM optim.vw02generate_list
    ;
$$;


ALTER FUNCTION api.download_list() OWNER TO postgres;

--
-- Name: FUNCTION download_list(); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.download_list() IS 'Returns the json for the site''s download list. Include filtered files.';


--
-- Name: download_list_hash(); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.download_list_hash() RETURNS jsonb
    LANGUAGE sql
    AS $$
    SELECT *
    FROM optim.vw03generate_list_hash
    ;
$$;


ALTER FUNCTION api.download_list_hash() OWNER TO postgres;

--
-- Name: FUNCTION download_list_hash(); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.download_list_hash() IS 'Returns the json for the site''s download list hash. Not include filtered files.';


--
-- Name: ghs_decode(text, integer); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.ghs_decode(p_code text, digits integer DEFAULT NULL::integer) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT jsonb_build_object(
    'type', 'FeatureCollection',
    'features', jsonb_agg(
          ST_AsGeoJSONb(y,8,0,null,
              jsonb_build_object(
                  'code', p_code,
                  'type', 'ghs',
                  'area', ST_Area(y,true),
                  'side', SQRT(ST_Area(y,true))
                  )
              )::jsonb)
    )
    FROM (SELECT geouri_ext.ghs_geom(p_code)) s(y)
$$;


ALTER FUNCTION api.ghs_decode(p_code text, digits integer) OWNER TO postgres;

--
-- Name: FUNCTION ghs_decode(p_code text, digits integer); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.ghs_decode(p_code text, digits integer) IS 'Decodes GHS.';


--
-- Name: ghs_encode(text); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.ghs_encode(p_uri text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT jsonb_build_object(
    'type', 'FeatureCollection',
    'features',
      (
        SELECT jsonb_agg(
          ST_AsGeoJSONb(y,8,0,null,
              jsonb_build_object(
                  'code', x,
                  'type', 'ghs',
                  'area', ST_Area(y,true),
                  'side', SQRT(ST_Area(y,true))
                  )
              )::jsonb)
        FROM (SELECT  ST_GeoHash(ST_SetSRID(ST_Point(u[2],u[1]),4326),geouri_ext.uncertain_ghs( (CASE WHEN u[4] IS NULL THEN 9 ELSE u[4] END) )) ) t(x),
        LATERAL (SELECT ST_GeomFromGeoHash(x)) s(y)
      )
    )
  FROM ( SELECT str_geouri_decode(p_uri) ) t(u)
$$;


ALTER FUNCTION api.ghs_encode(p_uri text) OWNER TO postgres;

--
-- Name: FUNCTION ghs_encode(p_uri text); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.ghs_encode(p_uri text) IS 'Encodes GeoURI to GHS.';


--
-- Name: jurisdiction_autocomplete(text); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.jurisdiction_autocomplete(p_code text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $_$
SELECT
CASE
WHEN cardinality(u)=2 AND u[1] ~*  '^[A-Z]{2}(-[A-Z]{1,3})?$' AND u[2] NOT IN ('ES','EN','PT','FR','')       THEN jsonb_build_object('error', 'Unsupported language.')
WHEN cardinality(u)=2 AND u[1] !~* '^[A-Z]{2}(-[A-Z]{1,3})?$' AND u[2]     IN ('ES','EN','PT','FR'   )       THEN jsonb_build_object('error', 'Isocode wrong format.')
WHEN cardinality(u)=2 AND u[1] !~* '^[A-Z]{2}(-[A-Z]{1,3})?$' AND u[2] NOT IN ('ES','EN','PT','FR','')       THEN jsonb_build_object('error', 'Isocode wrong format and unsupported language.')
WHEN cardinality(u)=1 AND u[1] !~* '^[A-Z]{2}(-[A-Z]{1,3})?$'                                                THEN jsonb_build_object('error', 'Isocode wrong format.')
WHEN (cardinality(u)=1 OR (cardinality(u)=2 AND u[2] IN ('') ))
                 AND u[1] NOT IN (SELECT isolabel_ext FROM optim.jurisdiction WHERE isolevel IN (1,2))       THEN jsonb_build_object('error', 'Isocode does not exist.')
WHEN (SELECT count(isolabel_ext) FROM optim.jurisdiction WHERE isolabel_ext = u[1]) = 0 AND u[1] NOT IN ('') THEN jsonb_build_object('error', 'No information for this jurisdiction.')

WHEN (cardinality(u)=2 AND u[1] ~* '^[A-Z]{2}(-[A-Z]{1,3})?$' AND u[2] IN ('ES','EN','PT','FR','')) OR
     (cardinality(u)=1 AND u[1] ~* '^[A-Z]{2}(-[A-Z]{1,3})?$') OR
     p_code IS NULL OR p_code = ''
THEN
(
    SELECT jsonb_agg(jsonb_build_object(
                        'name', name, -- currently no multilingual support.
                        'abbreviation', lower(abbrev),
                        'synonymous',
                            CASE
                            WHEN isolevel IN (1,2) THEN ARRAY []::text[]
                            -- WHEN isolevel = 2 THEN ARRAY [ lexname_to_unix(lexlabel,true,true,true) ]::text[]
                            WHEN isolevel = 3      THEN ARRAY [ split_part(isolabel_ext,'-',3) ]::text[]
                            ELSE ARRAY []::text[]
                            END
                        ))
    FROM optim.jurisdiction j
    WHERE

    CASE
    WHEN p_code IS NULL OR p_code = ''  THEN isolevel = 1
    WHEN cardinality(v)=1               THEN isolabel_ext LIKE u[1] || '%' AND isolevel = 2
    WHEN cardinality(v)=2               THEN isolabel_ext LIKE u[1] || '%' AND isolevel = 3
    END
)
ELSE jsonb_build_object('error', 'Unknown.')
END
FROM (SELECT string_to_array(upper(p_code),'/')::text[] AS u ) r, LATERAL (SELECT string_to_array(u[1],'-')::text[] AS v) s
$_$;


ALTER FUNCTION api.jurisdiction_autocomplete(p_code text) OWNER TO postgres;

--
-- Name: FUNCTION jurisdiction_autocomplete(p_code text); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.jurisdiction_autocomplete(p_code text) IS 'Jurisdictions to autocomplete.';


--
-- Name: jurisdiction_buffer(text); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.jurisdiction_buffer(p_iso text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT json_buffer AS json
  FROM osmc.mvwjurisdiction_geojson_from_isolabel
  WHERE isolabel_ext = (str_geocodeiso_decode(p_iso))[1]
$$;


ALTER FUNCTION api.jurisdiction_buffer(p_iso text) OWNER TO postgres;

--
-- Name: FUNCTION jurisdiction_buffer(p_iso text); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.jurisdiction_buffer(p_iso text) IS 'Returns the jurisdiction geometry with a 50 meter buffer.';


--
-- Name: jurisdiction_coverage(text); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.jurisdiction_coverage(p_iso text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT json
  FROM osmc.mvwjurisdiction_coverage
  WHERE isolabel_ext = (str_geocodeiso_decode(p_iso))[1]
$$;


ALTER FUNCTION api.jurisdiction_coverage(p_iso text) OWNER TO postgres;

--
-- Name: FUNCTION jurisdiction_coverage(p_iso text); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.jurisdiction_coverage(p_iso text) IS 'Returns jurisdiction coverage.';


--
-- Name: jurisdiction_geojson(text); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.jurisdiction_geojson(p_iso text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT json_nonbuffer AS json
  FROM osmc.mvwjurisdiction_geojson_from_isolabel
  WHERE isolabel_ext = (str_geocodeiso_decode(p_iso))[1]
$$;


ALTER FUNCTION api.jurisdiction_geojson(p_iso text) OWNER TO postgres;

--
-- Name: FUNCTION jurisdiction_geojson(p_iso text); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.jurisdiction_geojson(p_iso text) IS 'Returns the jurisdiction geometry.';


--
-- Name: olc_decode(text); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.olc_decode(p_code text) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  RETURN
  (
    SELECT
      CASE geouri_ext.olc_isfull(p_code)
        WHEN FALSE THEN jsonb_build_object('error', 'Not a valid full code.')
        WHEN TRUE THEN
        (
          jsonb_build_object(
            'type', 'FeatureCollection',
            'features', jsonb_agg(
                  ST_AsGeoJSONb(y,8,0,null,
                      jsonb_build_object(
                          'code', p_code,
                          'type', 'olc',
                          'area', ST_Area(y,true),
                          'side', SQRT(ST_Area(y,true))
                          )
                      )::jsonb)
            )
        )
        ELSE jsonb_build_object('error', 'Unknown.')
      END
    FROM (SELEcT geouri_ext.olc_geom(p_code)) s(y)
  );
END;
$$;


ALTER FUNCTION api.olc_decode(p_code text) OWNER TO postgres;

--
-- Name: FUNCTION olc_decode(p_code text); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.olc_decode(p_code text) IS 'Decode OLC.';


--
-- Name: olc_encode(text); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.olc_encode(p_uri text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT jsonb_build_object(
    'type', 'FeatureCollection',
    'features',
      (
        SELECT jsonb_agg(
          ST_AsGeoJSONb(y,8,0,null,
              jsonb_build_object(
                  'code', x,
                  'type', 'olc',
                  'area', ST_Area(y,true),
                  'side', SQRT(ST_Area(y,true))
                  )
              )::jsonb)
        FROM (SELECT geouri_ext.olc_encode(u[1],u[2],geouri_ext.uncertain_olc( (CASE WHEN u[4] IS NULL THEN 10 ELSE u[4] END) ))) t(x),
        LATERAL (SELECT geouri_ext.olc_geom(x)) s(y)
      )
    )
  FROM ( SELECT str_geouri_decode(p_uri) ) t(u)
$$;


ALTER FUNCTION api.olc_encode(p_uri text) OWNER TO postgres;

--
-- Name: FUNCTION olc_encode(p_uri text); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.olc_encode(p_uri text) IS 'Encodes GeoURI to OLC.';


--
-- Name: plicenses(text); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.plicenses(p_string text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT
    CASE
    WHEN count(*) = 1 THEN jsonb_build_object('error', null, 'result', (jsonb_agg(to_jsonb(r.*)))                                )
    WHEN count(*) > 1 THEN jsonb_build_object('error', null, 'result', (jsonb_agg(to_jsonb(r.*))), 'warning', 'Multiple results.')
    WHEN count(*) = 0 THEN jsonb_build_object('error', 'No results.')
    ELSE jsonb_build_object('error', 'Unknown.')
    END
  FROM
  (
    SELECT *
    FROM license.licenses_implieds
    WHERE
      ( lower(id_label) = lower(p_string) ) OR
      ( regexp_split_to_array (lower(p_string),'~') = ARRAY[lower(id_label),id_version] ) OR
      ( lower(name) = lower(lower(p_string)) ) OR
      ( lower(id_label) =
        substring
          (
            lower(p_string)
            FROM 1
            FOR (CASE WHEN length(split_part(lower(p_string), '-', -1)) = length(p_string) THEN 0 ELSE length(p_string) - 1 - length(split_part(lower(p_string), '-', -1)) END)
          )
          AND id_version = split_part(lower(p_string), '-', -1) )
    ORDER BY id_label, id_version
  ) r
$$;


ALTER FUNCTION api.plicenses(p_string text) OWNER TO postgres;

--
-- Name: FUNCTION plicenses(p_string text); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.plicenses(p_string text) IS 'Get license info.';


--
-- Name: redirects_viz(text); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.redirects_viz(p_uri text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $_$
    WITH results AS (
        SELECT *
        FROM optim.vw01fromCutLayer_toVizLayer
        WHERE
        ( -- 'BR-SP-Jacarei/_pk0145.01/parcel'
          p_uri ~*  '^/?[A-Z]{2}-[A-Z]{1,3}-[A-Z]+\/\_pk[0-9]{4}\.[0-9]{2}\/[A-Z]+$' AND
          jurisdiction_pack_layer ILIKE regexp_replace(p_uri,'/?([A-Z]{2}-[A-Z]{1,3}-[A-Z]+\/\_pk[0-9]{4}\.[0-9]{2}\/[A-Z]+)','\1%','i')
        )
        OR
        ( -- 'BR-SP-Jacarei/parcel'
          p_uri ~*  '^/?[A-Z]{2}-[A-Z]{1,3}-[A-Z]+\/[A-Z]+$' AND
          jurisdiction_pack_layer ILIKE regexp_replace(p_uri,'/?([A-Z]{2}-[A-Z]{1,3}-[A-Z]+)\/([A-Z]+)','\1%\2%','i')
        )
        OR
        ( -- BR/pk0081
          -- BR/_pk0081
          -- BR/81
          p_uri ~*  '^/?[A-Z]{2}\/(\_?pk)?[0-9]+(\.[0-9]{1,2})?$' AND
          jurisdiction_pack_layer ILIKE regexp_replace(p_uri,'/?([A-Z]{2})\/(\_?pk)?([0-9]+)(\.[0-9]{1,2})?','\1%\3%','i')
        )
        OR
        ( -- BR/pk0081/via
          -- BR/_pk0081/via
          -- BR/81/via
          p_uri ~*  '^/?[A-Z]{2}\/(\_?pk)?[0-9]+(\.[0-9]{1,2})?\/[A-Z]+$' AND
          jurisdiction_pack_layer ILIKE regexp_replace(p_uri,'/?([A-Z]{2})\/(\_?pk)?([0-9]+)(\.[0-9]{1,2})?(\/[A-Z]+)','\1%\3%\5%','i')
        )
        OR
        ( -- c26c149b/geoaddress
          p_uri ~*  '^/?([a-f0-9]{1,64})(\.[a-z0-9]+)?\/([A-Z]+)$' AND
          hash_from ILIKE regexp_replace(p_uri,'/?([a-f0-9]{6,64})(\.[a-z0-9]+)?\/([A-Z]+)','\1%','i') AND
          jurisdiction_pack_layer ILIKE regexp_replace(p_uri,'/?([a-f0-9]{1,64})(\.[a-z0-9]+)?\/([A-Z]+)','%\3%','i')
        )
        OR
        ( -- c26c149b
          p_uri ~*  '^/?([a-f0-9]{1,64})(\.[a-z0-9]+)?$' AND
          hash_from ILIKE regexp_replace(p_uri,'/?([a-f0-9]{1,64})(\.[a-z0-9]+)?','\1%','i')
        )
    )
    SELECT
     coalesce
     (
      (
        SELECT jsonb_build_object(
        'jurisdiction_pack_layer',jurisdiction_pack_layer,
        'url_layer_visualization',url_layer_visualization,
        'hashedfname_from',hash_from,
        'error',

          CASE
          WHEN url_layer_visualization IS NULL THEN  'no uri.'
          ELSE NULL
          END
        )
        FROM results WHERE (SELECT COUNT(*) FROM results) = 1
      ),
      jsonb_build_object
      (
        'error',
          CASE
          WHEN (SELECT COUNT(*) FROM results) > 1 THEN  'Multiple results.'
          ELSE  'no result'
          END
      )
    )
    ;
$_$;


ALTER FUNCTION api.redirects_viz(p_uri text) OWNER TO postgres;

--
-- Name: FUNCTION redirects_viz(p_uri text); Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON FUNCTION api.redirects_viz(p_uri text) IS 'Jurisdictions to autocomplete.';


--
-- Name: insert_dldg_csv(); Type: FUNCTION; Schema: download; Owner: postgres
--

CREATE FUNCTION download.insert_dldg_csv() RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO download.redirects(donor_id,filename_original,package_path,hashedfname,hashedfnameuri)
  SELECT donor_id,filename_original,package_path,de_sha256,para_url
  FROM tmp_orig.redirects_dlguard
  ON CONFLICT (hashedfname,hashedfnameuri)
  DO UPDATE
  SET donor_id=EXCLUDED.donor_id, filename_original=EXCLUDED.filename_original, package_path=EXCLUDED.package_path
  -- RETURNING 'Ok, updated download.redirects.'
  ;
  RETURN 'Ok, updated download.redirects.';
END;
$$;


ALTER FUNCTION download.insert_dldg_csv() OWNER TO postgres;

--
-- Name: FUNCTION insert_dldg_csv(); Type: COMMENT; Schema: download; Owner: postgres
--

COMMENT ON FUNCTION download.insert_dldg_csv() IS 'Update download.redirects from tmp_orig.redirects_dlguard';


--
-- Name: update_cloudcontrol_vizuri(); Type: FUNCTION; Schema: download; Owner: postgres
--

CREATE FUNCTION download.update_cloudcontrol_vizuri() RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE optim.donated_PackComponent_cloudControl c
  SET info = coalesce(info,'{}'::jsonb) || jsonb_build_object('viz_uri', url_layer_visualization)
  FROM
  (
    SELECT pf.id, v.*
    FROM tmp_orig.redirects_viz v
    LEFT JOIN optim.vw01full_packfilevers_ftype pf
    ON v.hash_from = pf.hashedfname
  ) r
  WHERE c.packvers_id= r.id AND hashedfnametype ='shp' AND lower(split_part(r.jurisdiction_pack_layer,'/',3)) = (SELECT split_part(ftname,'_',1) FROM optim.feature_type WHERE ftid = c.ftid )
  -- RETURNING 'Ok, update viz_uri in info of optim.donated_PackComponent_cloudControl.'
  ;
  RETURN 'Ok, update viz_uri in info of optim.donated_PackComponent_cloudControl.';
END;
$$;


ALTER FUNCTION download.update_cloudcontrol_vizuri() OWNER TO postgres;

--
-- Name: FUNCTION update_cloudcontrol_vizuri(); Type: COMMENT; Schema: download; Owner: postgres
--

COMMENT ON FUNCTION download.update_cloudcontrol_vizuri() IS 'Update viz_uri in info of optim.donated_PackComponent_cloudControl';


--
-- Name: ghs_geom(text, integer); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.ghs_geom(code text, digits integer DEFAULT NULL::integer) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT ST_GeomFromGeoHash( $1, CASE WHEN $2 IS NULL THEN length($1) ELSE $2 END)
$_$;


ALTER FUNCTION geouri_ext.ghs_geom(code text, digits integer) OWNER TO postgres;

--
-- Name: FUNCTION ghs_geom(code text, digits integer); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.ghs_geom(code text, digits integer) IS 'Wrap for ST_GeomFromGeoHash(). Use digits to truncate the code.';


--
-- Name: ghs_geom(public.geometry, integer); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.ghs_geom(geom public.geometry, digits integer DEFAULT 9) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT ST_GeomFromGeoHash(ST_GeoHash($1,$2),$2)
$_$;


ALTER FUNCTION geouri_ext.ghs_geom(geom public.geometry, digits integer) OWNER TO postgres;

--
-- Name: FUNCTION ghs_geom(geom public.geometry, digits integer); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.ghs_geom(geom public.geometry, digits integer) IS 'Wrap for ST_GeomFromGeoHash(ST_GeoHash()). Return a geometry from a GeoHash of a point or geometry (in SRID 4326).';


--
-- Name: ghs_geom(double precision, double precision, integer); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.ghs_geom(lat double precision, lon double precision, digits integer DEFAULT 9) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT geouri_ext.ghs_geom( ST_SetSRID(ST_Point($2,$1),4326), $3 )
$_$;


ALTER FUNCTION geouri_ext.ghs_geom(lat double precision, lon double precision, digits integer) OWNER TO postgres;

--
-- Name: FUNCTION ghs_geom(lat double precision, lon double precision, digits integer); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.ghs_geom(lat double precision, lon double precision, digits integer) IS 'Wrap for ghs_geom(). Converts latLon into a point.';


--
-- Name: olc_cliplatitude(double precision); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.olc_cliplatitude(lat double precision) RETURNS double precision
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT CASE
    WHEN lat < -90 THEN -90
    WHEN lat > 90  THEN 90
    ELSE lat
  END;
$$;


ALTER FUNCTION geouri_ext.olc_cliplatitude(lat double precision) OWNER TO postgres;

--
-- Name: FUNCTION olc_cliplatitude(lat double precision); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.olc_cliplatitude(lat double precision) IS 'Clip latitude between -90 and 90 degrees.';


--
-- Name: olc_codearea(double precision, double precision, double precision, double precision, integer); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.olc_codearea(latitudelo double precision, longitudelo double precision, latitudehi double precision, longitudehi double precision, codelength integer) RETURNS double precision[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    rlatitudeLo float:= latitudeLo;
    rlongitudeLo float:= longitudeLo;
    rlatitudeHi float:= latitudeHi;
    rlongitudeHi float:= longitudeHi;
    rcodeLength float:= codeLength;
    rlatitudeCenter float:= 0;
    rlongitudeCenter float:= 0;
    latitude_max_ int:= 90;
    longitude_max_ int:= 180;
BEGIN
    --calculate the latitude center
    IF (((latitudeLo + (latitudeHi - latitudeLo))/ 2) > latitude_max_) THEN
        rlatitudeCenter := latitude_max_;
    ELSE
        rlatitudeCenter := (latitudeLo + (latitudeHi - latitudeLo)/ 2);
    END IF;
    --calculate the longitude center
    IF (((longitudeLo + (longitudeHi - longitudeLo))/ 2) > longitude_max_) THEN
        rlongitudeCenter := longitude_max_;
    ELSE
        rlongitudeCenter := (longitudeLo + (longitudeHi - longitudeLo)/ 2);
    END IF;
    RETURN array[
        rlatitudeLo,  -- lat_lo
        rlongitudeLo, -- lng_lo
        rlatitudeHi,  -- lat_hi
        rlongitudeHi, -- lng_hi
        rcodeLength,  -- code_length
        rlatitudeCenter,
        rlongitudeCenter
    ];
END;
$$;


ALTER FUNCTION geouri_ext.olc_codearea(latitudelo double precision, longitudelo double precision, latitudehi double precision, longitudehi double precision, codelength integer) OWNER TO postgres;

--
-- Name: FUNCTION olc_codearea(latitudelo double precision, longitudelo double precision, latitudehi double precision, longitudehi double precision, codelength integer); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.olc_codearea(latitudelo double precision, longitudelo double precision, latitudehi double precision, longitudehi double precision, codelength integer) IS 'Coordinates of a decoded OLC code. Returns [lat_lo, lng_lo, lat_hi, lng_hi, code_length, rlatCenter, rlongCenter].';


--
-- Name: olc_computelatitudeprecision(integer); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.olc_computelatitudeprecision(codelength integer) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    CODE_ALPHABET_ text := '23456789CFGHJMPQRVWX';
    ENCODING_BASE_ int := char_length(CODE_ALPHABET_);
    PAIR_CODE_LENGTH_ int := 10;
    GRID_ROWS_ int := 5;
BEGIN
    IF (codeLength <= PAIR_CODE_LENGTH_) THEN
        RETURN power(ENCODING_BASE_, floor((codeLength / (-2)) + 2));
    ELSE
        RETURN power(ENCODING_BASE_, -3) / power(GRID_ROWS_, codeLength - PAIR_CODE_LENGTH_);
    END IF;
END;
$$;


ALTER FUNCTION geouri_ext.olc_computelatitudeprecision(codelength integer) OWNER TO postgres;

--
-- Name: FUNCTION olc_computelatitudeprecision(codelength integer); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.olc_computelatitudeprecision(codelength integer) IS 'Compute the latitude precision value for a given code length.';


--
-- Name: olc_decode(text); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.olc_decode(code text) RETURNS double precision[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
lat_out float := 0;
lng_out float := 0;
latitude_max_ int := 90;
longitude_max_ int := 180;
lat_precision float := 0;
lng_precision float := 0;
code_alphabet text := '23456789CFGHJMPQRVWX';
stripped_code text := UPPER(replace(replace(code,'0',''),'+',''));
encoding_base_ int := char_length(code_alphabet);
pair_precision_ float := power(encoding_base_::float, 3::float);
normal_lat float:= -latitude_max_ * pair_precision_;
normal_lng float:= -longitude_max_ * pair_precision_;
grid_lat_ float:= 0;
grid_lng_ float:= 0;
max_digit_count_ int:= 15;
pair_code_length_ int:=10;
digits int:= 0;
pair_first_place_value_ float:= power(encoding_base_, (pair_code_length_/2)-1);
pv int:= 0;
iterator int:=0;
iterator_d int:=0;
digit_val int := 0;
row_ float := 0;
col_ float := 0;
return_record record;
grid_code_length_ int:= max_digit_count_ - pair_code_length_;
grid_columns_ int := 4;
grid_rows_  int := 5;
grid_lat_first_place_value_ int := power(grid_rows_, (grid_code_length_ - 1));
grid_lng_first_place_value_ int := power(grid_columns_, (grid_code_length_ - 1));
final_lat_precision_ float := pair_precision_ * power(grid_rows_, (max_digit_count_ - pair_code_length_));
final_lng_precision_ float := pair_precision_ * power(grid_columns_, (max_digit_count_ - pair_code_length_));
rowpv float := grid_lat_first_place_value_;
colpv float := grid_lng_first_place_value_;

BEGIN
    IF (geouri_ext.olc_isfull(code)) is FALSE THEN
        RAISE EXCEPTION 'NOT A VALID FULL CODE: %', code;
    END IF;
    --strip 0 and + chars
    code:= stripped_code;
    normal_lat := -latitude_max_ * pair_precision_;
    normal_lng := -longitude_max_ * pair_precision_;

    --how many digits must be used
    IF (char_length(code) > pair_code_length_) THEN
        digits := pair_code_length_;
    ELSE
        digits := char_length(code);
    END IF;
    pv := pair_first_place_value_;
    WHILE iterator < digits
        LOOP
            normal_lat := normal_lat + (POSITION( SUBSTRING(code FROM iterator+1 FOR 1) IN code_alphabet)-1 )* pv;
            normal_lng := normal_lng + (POSITION( SUBSTRING(code FROM iterator+1+1 FOR 1) IN code_alphabet)-1  ) * pv;
            IF (iterator < (digits -2)) THEN
                pv := pv/encoding_base_;
            END IF;
            iterator := iterator + 2;

        END LOOP;

    --convert values to degrees
    lat_precision := pv/ pair_precision_;
    lng_precision := pv/ pair_precision_;

    IF (char_length(code) > pair_code_length_) THEN
        IF (char_length(code) > max_digit_count_) THEN
            digits := max_digit_count_;
        ELSE
            digits := char_length(code);
        END IF;
        iterator_d := pair_code_length_;
        WHILE iterator_d < digits
        LOOP
            digit_val := (POSITION( SUBSTRING(code FROM iterator_d+1 FOR 1) IN code_alphabet)-1);
            row_ := ceil(digit_val/grid_columns_);
            col_ := digit_val % grid_columns_;
            grid_lat_ := grid_lat_ +(row_*rowpv);
            grid_lng_ := grid_lng_ +(col_*colpv);
            IF ( iterator_d < (digits -1) ) THEN
                rowpv := rowpv / grid_rows_;
                colpv := colpv / grid_columns_;
            END IF;
            iterator_d := iterator_d + 1;
        END LOOP;
        --adjust precision
        lat_precision := rowpv / final_lat_precision_;
        lng_precision := colpv / final_lng_precision_;
    END IF;

    --merge the normal and extra precision of the code
    lat_out := normal_lat / pair_precision_ + grid_lat_ / final_lat_precision_;
    lng_out := normal_lng / pair_precision_ + grid_lng_ / final_lng_precision_;

    IF (char_length(code) > max_digit_count_ ) THEN
        digits := max_digit_count_;
        RAISE NOTICE 'lat_out max_digit_count_ %', lat_out;
    ELSE
        digits := char_length(code);
        RAISE NOTICE 'digits char_length%', digits;
    END IF ;

    RETURN geouri_ext.olc_codearea(
            lat_out,
            lng_out,
            (lat_out+lat_precision),
            (lng_out+lng_precision),
            digits::int
    );
END;
$$;


ALTER FUNCTION geouri_ext.olc_decode(code text) OWNER TO postgres;

--
-- Name: FUNCTION olc_decode(code text); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.olc_decode(code text) IS 'Decode a OLC code to get the corresponding bounding box and the center. Returns [1=lat_lo, 2=lng_lo, 3=lat_hi, 4=lng_hi, 5=code_length, 6=rlatCenter, 7=rlongCenter].';


--
-- Name: olc_encode(double precision, double precision, integer); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.olc_encode(latitude double precision, longitude double precision, codelength integer DEFAULT 10) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    SEPARATOR_ text := '+';
    SEPARATOR_POSITION_ int := 8;
    PADDING_CHARACTER_ text := '0';
    CODE_ALPHABET_ text := '23456789CFGHJMPQRVWX';
    ENCODING_BASE_ int := char_length(CODE_ALPHABET_);
    LATITUDE_MAX_ int := 90;
    LONGITUDE_MAX_ int := 180;
    MAX_DIGIT_COUNT_ int := 15;
    PAIR_CODE_LENGTH_ int := 10;
    PAIR_PRECISION_ decimal := power(ENCODING_BASE_, 3);
    GRID_CODE_LENGTH_ int := MAX_DIGIT_COUNT_ - PAIR_CODE_LENGTH_;
    GRID_COLUMNS_ int := 4;
    GRID_ROWS_ int := 5;
    FINAL_LAT_PRECISION_ decimal := PAIR_PRECISION_ * power(GRID_ROWS_, MAX_DIGIT_COUNT_ - PAIR_CODE_LENGTH_);
    FINAL_LNG_PRECISION_ decimal := PAIR_PRECISION_ * power(GRID_COLUMNS_, MAX_DIGIT_COUNT_ - PAIR_CODE_LENGTH_);
    code text := '';
    latVal decimal := 0;
    lngVal decimal := 0;
    latDigit smallint;
    lngDigit smallint;
    ndx smallint;
    i_ smallint;
BEGIN
    IF ((codeLength < 2) OR ((codeLength < PAIR_CODE_LENGTH_) AND (codeLength % 2 = 1))) THEN
        RAISE EXCEPTION 'Invalid Open Location Code length - %', codeLength
        USING HINT = 'The Open Location Code length must be 2, 4, 6, 8, 10, 11, 12, 13, 14, or 15.';
    END IF;

    codeLength := LEAST(codeLength, MAX_DIGIT_COUNT_);

    latitude := geouri_ext.olc_cliplatitude(latitude);
    longitude := geouri_ext.olc_normalizelongitude(longitude);

    IF (latitude = 90) THEN
        latitude := latitude - geouri_ext.olc_computeLatitudePrecision(codeLength);
    END IF;

    latVal := floor(round((latitude + LATITUDE_MAX_) * FINAL_LAT_PRECISION_, 6));
    lngVal := floor(round((longitude + LONGITUDE_MAX_) * FINAL_LNG_PRECISION_, 6));

    IF (codeLength > PAIR_CODE_LENGTH_) THEN
        i_ := 0;
        WHILE (i_ < (MAX_DIGIT_COUNT_ - PAIR_CODE_LENGTH_)) LOOP
            latDigit := latVal % GRID_ROWS_;
            lngDigit := lngVal % GRID_COLUMNS_;
            ndx := (latDigit * GRID_COLUMNS_) + lngDigit;
            code := substr(CODE_ALPHABET_, ndx + 1, 1) || code;
            latVal := div(latVal, GRID_ROWS_);
            lngVal := div(lngVal, GRID_COLUMNS_);
            i_ := i_ + 1;
        END LOOP;
    ELSE
        latVal := div(latVal, power(GRID_ROWS_, GRID_CODE_LENGTH_)::integer);
        lngVal := div(lngVal, power(GRID_COLUMNS_, GRID_CODE_LENGTH_)::integer);
    END IF;

    i_ := 0;
    WHILE (i_ < (PAIR_CODE_LENGTH_ / 2)) LOOP
        code := substr(CODE_ALPHABET_, (lngVal % ENCODING_BASE_)::integer + 1, 1) || code;
        code := substr(CODE_ALPHABET_, (latVal % ENCODING_BASE_)::integer + 1, 1) || code;
        latVal := div(latVal, ENCODING_BASE_);
        lngVal := div(lngVal, ENCODING_BASE_);
        i_ := i_ + 1;
    END LOOP;

    code := substr(code, 1, SEPARATOR_POSITION_) || SEPARATOR_ || substr(code, SEPARATOR_POSITION_ + 1);

    IF (codeLength >= SEPARATOR_POSITION_) THEN
        RETURN substr(code, 1, codeLength + 1);
    ELSE
        RETURN rpad(substr(code, 1, codeLength), SEPARATOR_POSITION_, PADDING_CHARACTER_) || SEPARATOR_;
    END IF;
END;
$$;


ALTER FUNCTION geouri_ext.olc_encode(latitude double precision, longitude double precision, codelength integer) OWNER TO postgres;

--
-- Name: FUNCTION olc_encode(latitude double precision, longitude double precision, codelength integer); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.olc_encode(latitude double precision, longitude double precision, codelength integer) IS 'Encode lat lng to get OLC code.';


--
-- Name: olc_geom(text); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.olc_geom(code text) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT ST_MakeEnvelope(a[2], a[1], a[4], a[3], 4326)
                    --  xmin, ymin, xmax, ymax  (x=lon, y=lat)
  FROM ( SELECT geouri_ext.olc_decode($1) ) t(a)
  -- Returns [1=lat_lo, 2=lng_lo, 3=lat_hi, 4=lng_hi, 5=code_length, 6=rlatCenter, 7=rlongCenter].'
$_$;


ALTER FUNCTION geouri_ext.olc_geom(code text) OWNER TO postgres;

--
-- Name: FUNCTION olc_geom(code text); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.olc_geom(code text) IS 'Returns OLC_center as complete cell geometry.';


--
-- Name: olc_geom(public.geometry, integer); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.olc_geom(geom public.geometry, maxchars integer DEFAULT 9) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT geouri_ext.olc_geom( ST_Y(g), ST_X(g), $2 )
  FROM (SELECT CASE WHEN GeometryType($1)='POINT' THEN $1 ELSE ST_PointOnSurface($1) END) t(g)
$_$;


ALTER FUNCTION geouri_ext.olc_geom(geom public.geometry, maxchars integer) OWNER TO postgres;

--
-- Name: FUNCTION olc_geom(geom public.geometry, maxchars integer); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.olc_geom(geom public.geometry, maxchars integer) IS 'Returns OLC_center as complete cell geometry. Wrap of olc_geom(float,float).';


--
-- Name: olc_geom(double precision, double precision, integer); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.olc_geom(lat double precision, lon double precision, maxchars integer DEFAULT 9) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT geouri_ext.olc_geom( geouri_ext.olc_encode($1,$2,$3) )
$_$;


ALTER FUNCTION geouri_ext.olc_geom(lat double precision, lon double precision, maxchars integer) OWNER TO postgres;

--
-- Name: FUNCTION olc_geom(lat double precision, lon double precision, maxchars integer); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.olc_geom(lat double precision, lon double precision, maxchars integer) IS 'Returns OLC_center as complete cell geometry. Wrap for olc_geom(olc_encode()).';


--
-- Name: olc_isfull(text); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.olc_isfull(code text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
code_alphabet text := '23456789CFGHJMPQRVWX';
first_lat_val int:= 0;
first_lng_val int:= 0;
encoding_base_ int := char_length(code_alphabet);
latitude_max_ int := 90;
longitude_max_ int := 180;
BEGIN
    IF (geouri_ext.olc_isvalid(code)) is FALSE THEN
        RETURN FALSE;
    END IF;
    -- If is short --> not full.
    IF (geouri_ext.olc_isshort(code)) is TRUE THEN
        RETURN FALSE;
    END IF;
    --Check latitude for first lat char
    first_lat_val := (POSITION( UPPER(LEFT(code,1)) IN  code_alphabet  )-1) * encoding_base_;
    IF (first_lat_val >= latitude_max_ * 2) THEN
        RETURN FALSE;
    END IF;
    IF (char_length(code) > 1) THEN
        --Check longitude for first lng char
        first_lng_val := (POSITION( UPPER(SUBSTRING(code FROM 2 FOR 1)) IN  code_alphabet)-1) * encoding_base_;
        IF (first_lng_val >= longitude_max_ *2) THEN
            RETURN FALSE;
        END IF;
    END IF;
    RETURN TRUE;
END;
$$;


ALTER FUNCTION geouri_ext.olc_isfull(code text) OWNER TO postgres;

--
-- Name: FUNCTION olc_isfull(code text); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.olc_isfull(code text) IS 'Is the codeplus a full code.';


--
-- Name: olc_isshort(text); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.olc_isshort(code text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
separator_ text := '+';
separator_position int := 9;
BEGIN
    -- the OLC code is valid ?
    IF (geouri_ext.olc_isvalid(code)) is FALSE THEN
        RETURN FALSE;
    END IF;
    -- the OLC code contain a '+' at a correct place
    IF ((POSITION(separator_ in code)>0) AND (POSITION(separator_ in code)< separator_position)) THEN
        RETURN TRUE;
    END IF;
RETURN FALSE;
END;
$$;


ALTER FUNCTION geouri_ext.olc_isshort(code text) OWNER TO postgres;

--
-- Name: FUNCTION olc_isshort(code text); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.olc_isshort(code text) IS 'Check if the code is a short version of a OLC code.';


--
-- Name: olc_isvalid(text); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.olc_isvalid(code text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
separator_ text := '+';
separator_position int := 8;
padding_char text:= '0';
padding_int_pos integer:=0;
padding_one_int_pos integer:=0;
stripped_code text := replace(replace(code,'0',''),'+','');
code_alphabet_ text := '23456789CFGHJMPQRVWX';
idx int := 1;
BEGIN
code := code::text;
--Code Without "+" char
IF (POSITION(separator_ in code) = 0) THEN
    RETURN FALSE;
END IF;
--Code beginning with "+" char
IF (POSITION(separator_ in code) = 1) THEN
    RETURN FALSE;
END IF;
--Code with illegal position separator
IF ( (POSITION(separator_ in code) > separator_position+1) OR ((POSITION(separator_ in code)-1) % 2 = 1)  ) THEN
      RETURN FALSE;
END IF;
--Code contains padding characters "0"
IF (POSITION(padding_char in code) > 0) THEN
    IF (POSITION(separator_ in code) < 9) THEN
        RETURN FALSE;
    END IF;
    IF (POSITION(separator_ in code) = 1) THEN
        RETURN FALSE;
    END IF;
    --Check if there are many "00" groups (only one is legal)
    padding_int_pos := (select ROW_NUMBER() OVER( ORDER BY REGEXP_MATCHES(code,'('||padding_char||'+)' ,'g') ) order by 1 DESC limit 1);
    padding_one_int_pos := char_length( (select REGEXP_MATCHES(code,'('||padding_char||'+)' ,'g')  limit 1)[1] );
    IF (padding_int_pos > 1 ) THEN
        RETURN FALSE;
    END IF;
    --Check if the first group is % 2 = 0
    IF ((padding_one_int_pos % 2) = 1 ) THEN
        RETURN FALSE;
    END IF;
    --Lastchar is a separator
    IF (RIGHT(code,1) <> separator_) THEN
        RETURN FALSE;
    END IF;
END IF;
--If there is just one char after '+'
IF (char_length(code) - POSITION(separator_ in code) = 1 ) THEN
    RETURN FALSE;
END IF;
--Check if each char is in code_alphabet_
FOR i IN 1..char_length(stripped_code) LOOP
    IF (POSITION( UPPER(substring(stripped_code from i for 1)) in code_alphabet_ ) = 0) THEN
        RETURN FALSE;
    END IF;
END LOOP;
RETURN TRUE;
END;
$$;


ALTER FUNCTION geouri_ext.olc_isvalid(code text) OWNER TO postgres;

--
-- Name: FUNCTION olc_isvalid(code text); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.olc_isvalid(code text) IS 'Check if the code is valid.';


--
-- Name: olc_normalizelongitude(double precision); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.olc_normalizelongitude(lng double precision) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
    WHILE (lng < -180) LOOP
      lng := lng + 360;
    END LOOP;
    WHILE (lng >= 180) LOOP
      lng := lng - 360;
    END LOOP;
    return lng;
END;
$$;


ALTER FUNCTION geouri_ext.olc_normalizelongitude(lng double precision) OWNER TO postgres;

--
-- Name: FUNCTION olc_normalizelongitude(lng double precision); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.olc_normalizelongitude(lng double precision) IS 'Normalize a longitude between -180 and 180 degrees (180 excluded).';


--
-- Name: olc_recovernearest(text, double precision, double precision); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.olc_recovernearest(short_code text, reference_latitude double precision, reference_longitude double precision) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
padding_length int :=0;
separator_position_ int := 8;
separator_ text := '+';
resolution int := 0;
half_resolution float := 0;
code_area float[];
latitude_max int := 90;
code_out text := '';
BEGIN

    IF (geouri_ext.olc_isshort(short_code)) is FALSE THEN
        IF (geouri_ext.olc_isfull(short_code)) THEN
            RETURN UPPER(short_code);
        ELSE
            RAISE EXCEPTION 'Short code is not valid: %', short_code;
        END IF;
        RAISE EXCEPTION 'NOT A VALID FULL CODE: %', code;
    END IF;

    -- Only make sense for Javascript:
    --Are the latitude and longitude valid.
    --IF (pg_typeof(reference_latitude) NOT IN ('float','real','double precision','integer','bigint','float')) OR (pg_typeof(reference_longitude) NOT IN ('float','real','double precision','integer','bigint','float')) THEN
    --    RAISE EXCEPTION 'LAT || LNG are not numbers % !',pg_typeof(latitude)||' || '||pg_typeof(longitude);
    --END IF;

    reference_latitude := geouri_ext.olc_cliplatitude(reference_latitude);
    reference_longitude := geouri_ext.olc_normalizelongitude(reference_longitude);

    short_code := UPPER(short_code);
    -- Calculate the number of digits to recover.
    padding_length := separator_position_ - POSITION(separator_ in short_code)+1;
    -- Calculate the resolution of the padded area in degrees.
    resolution := power(20, 2 - (padding_length / 2));
    -- Half resolution for difference with the center
    half_resolution := resolution / 2.0;

    -- Concatenate short_code and the calculated value --> encode(lat,lng)
    code_area := geouri_ext.olc_decode(SUBSTRING(geouri_ext.olc_encode(reference_latitude, reference_longitude) , 1 , padding_length) || short_code);
    -- Returns [1=lat_lo, 2=lng_lo, 3=lat_hi, 4=lng_hi, 5=code_length, 6=rlatCenter, 7=rlongCenter]

    --Check if difference with the center is more than half_resolution
    --Keep value between -90 and 90
    IF (((reference_latitude + half_resolution) < code_area[6]) AND ((code_area[6] - resolution) >= -latitude_max)) THEN
        code_area[6] := code_area[6] - resolution;
    ELSIF (((reference_latitude - half_resolution) > code_area[6]) AND ((code_area[6] + resolution) <= latitude_max)) THEN
      code_area[6] := code_area[6] + resolution;
    END IF;

    -- difference with the longitude reference
    IF (reference_longitude + half_resolution < code_area[7] ) THEN
      code_area[7] := code_area[7] - resolution;
    ELSIF (reference_longitude - half_resolution > code_area[7]) THEN
      code_area[7] := code_area[7] + resolution;
    END IF;

    code_out := geouri_ext.olc_encode(code_area[6], code_area[7], code_area[5]::integer);

RETURN code_out;
END;
$$;


ALTER FUNCTION geouri_ext.olc_recovernearest(short_code text, reference_latitude double precision, reference_longitude double precision) OWNER TO postgres;

--
-- Name: FUNCTION olc_recovernearest(short_code text, reference_latitude double precision, reference_longitude double precision); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.olc_recovernearest(short_code text, reference_latitude double precision, reference_longitude double precision) IS 'Retrieve a valid full code (the nearest from lat/lng).';


--
-- Name: olc_shorten(text, double precision, double precision); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.olc_shorten(code text, latitude double precision, longitude double precision) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
padding_character text :='0';
code_area float[];
min_trimmable_code_len int:= 6;
range_ float:= 0;
lat_dif float:= 0;
lng_dif float:= 0;
pair_resolutions_ FLOAT[] := ARRAY[20.0, 1.0, 0.05, 0.0025, 0.000125]::FLOAT[];
iterator int:= 0;
BEGIN
    IF (geouri_ext.olc_isfull(code)) is FALSE THEN
        RAISE EXCEPTION 'Code is not full and valid: %', code;
    END IF;

    IF (POSITION(padding_character IN code) > 0) THEN
      RAISE EXCEPTION 'Code contains 0 character(s), not valid : %', code;
    END IF;

    code := UPPER(code);
    code_area := geouri_ext.olc_decode(code);
    -- Returns [1=lat_lo, 2=lng_lo, 3=lat_hi, 4=lng_hi, 5=code_length, 6=rlatCenter, 7=rlongCenter]

    IF (code_area[5] < min_trimmable_code_len ) THEN
        RAISE EXCEPTION 'Code must contain more than 6 character(s) : %',code;
    END IF;

    --Are the latitude and longitude valid
    IF (pg_typeof(latitude) NOT IN ('float','real','double precision','integer','bigint','float')) OR (pg_typeof(longitude) NOT IN ('float','real','double precision','integer','bigint','float')) THEN
        RAISE EXCEPTION 'LAT || LNG are not numbers % !',pg_typeof(latitude)||' || '||pg_typeof(longitude);
    END IF;

    latitude := geouri_ext.olc_cliplatitude(latitude);
    longitude := geouri_ext.olc_normalizelongitude(longitude);

    lat_dif := ABS(code_area[6] - latitude);
    lng_dif := ABS(code_area[7] - longitude);

    --calculate max distance with the center
    IF (lat_dif > lng_dif) THEN
        range_ := lat_dif;
    ELSE
        range_ := lng_dif;
    END IF;

    iterator := ARRAY_LENGTH( pair_resolutions_, 1)-2;

    WHILE ( iterator >= 1 )
    LOOP
        --is it close enough to shortent the code ?
        --use 0.3 for safety instead of 0.5
        IF ( range_ < (pair_resolutions_[ iterator ]*0.3) ) THEN
            RETURN SUBSTRING( code , ((iterator+1)*2)-1 );
        END IF;
        iterator := iterator - 1;
    END LOOP;
RETURN code;
END;
$$;


ALTER FUNCTION geouri_ext.olc_shorten(code text, latitude double precision, longitude double precision) OWNER TO postgres;

--
-- Name: FUNCTION olc_shorten(code text, latitude double precision, longitude double precision); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.olc_shorten(code text, latitude double precision, longitude double precision) IS 'Remove characters from the start of an OLC code.';


--
-- Name: uncertain_ghs(double precision); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.uncertain_ghs(u double precision) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $$
  -- GeoURI's uncertainty value "is the radius of the disk that represents uncertainty geometrically."
  SELECT CASE -- discretization by "snap to code length."
    WHEN s < 0.09 THEN 12
    WHEN s < 0.5 THEN 11
    WHEN s < 2.81 THEN 10
    WHEN s < 15 THEN 9
    WHEN s < 90 THEN 8
    WHEN s < 4389 THEN 7
    WHEN s < 28763 THEN 6
    WHEN s < 68109 THEN 5
    WHEN s < 121659 THEN 4
    WHEN s < 519941 THEN 3
    WHEN s < 2941941 THEN 2
    ELSE 1
    END
  FROM (SELECT CASE WHEN u > 9 THEN (ROUND(u,0))*2 ELSE (ROUND(u,1))*2 END) t(s)
$$;


ALTER FUNCTION geouri_ext.uncertain_ghs(u double precision) OWNER TO postgres;

--
-- Name: FUNCTION uncertain_ghs(u double precision); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.uncertain_ghs(u double precision) IS 'Converts uncertainty to GHS code size.';


--
-- Name: uncertain_olc(double precision); Type: FUNCTION; Schema: geouri_ext; Owner: postgres
--

CREATE FUNCTION geouri_ext.uncertain_olc(u double precision) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $$
  -- GeoURI's uncertainty value "is the radius of the disk that represents uncertainty geometrically."
  SELECT CASE -- discretization by "snap to code length."
    WHEN s < 0.02 THEN 15
    WHEN s < 0.09 THEN 14
    WHEN s < 0.43 THEN 13
    WHEN s < 1.91 THEN 12
    WHEN s < 8.52 THEN 11
    WHEN s < 145 THEN 10
    WHEN s < 2922 THEN 8
    WHEN s < 58443 THEN 6
    WHEN s < 1168660 THEN 4
    ELSE 2
    END
  FROM (SELECT CASE WHEN u > 9 THEN (ROUND(u,0))*2 ELSE (ROUND(u,1))*2 END) t(s)
$$;


ALTER FUNCTION geouri_ext.uncertain_olc(u double precision) OWNER TO postgres;

--
-- Name: FUNCTION uncertain_olc(u double precision); Type: COMMENT; Schema: geouri_ext; Owner: postgres
--

COMMENT ON FUNCTION geouri_ext.uncertain_olc(u double precision) IS 'Converts uncertainty to OLC code size.';


--
-- Name: id_format(text, bigint); Type: FUNCTION; Schema: lib; Owner: postgres
--

CREATE FUNCTION lib.id_format(p_type text, pck_id bigint) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
 SELECT CASE p_type
 WHEN 'donor'        THEN regexp_replace(to_char(pck_id,'FM000000000'),     '^(\d{3})(\d{6})$',                     '\1.\2'         )
 WHEN 'packtpl'      THEN regexp_replace(to_char(pck_id,'FM00000000000'),   '^(\d{3})(\d{6})(\d{2})$',              '\1.\2.\3'      )
 WHEN 'packfilevers' THEN regexp_replace(to_char(pck_id,'FM00000000000000'),'^(\d{3})(\d{6})(\d{2})(\d{1})(\d{2})$','\1.\2.\3.\4.\5')
 END
$_$;


ALTER FUNCTION lib.id_format(p_type text, pck_id bigint) OWNER TO postgres;

--
-- Name: insert_licenses(); Type: FUNCTION; Schema: license; Owner: postgres
--

CREATE FUNCTION license.insert_licenses() RETURNS text
    LANGUAGE plpgsql
    AS $$
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

  ON CONFLICT (id_label,COALESCE(id_version, ''))
  DO UPDATE
  SET name=EXCLUDED.name, family=EXCLUDED.family, status=EXCLUDED.status, year=EXCLUDED.year, is_by=EXCLUDED.is_by, is_sa=EXCLUDED.is_sa, is_noreuse=EXCLUDED.is_noreuse, od_conformance=EXCLUDED.od_conformance, osd_conformance=EXCLUDED.osd_conformance, maintainer=EXCLUDED.maintainer, title=EXCLUDED.title, url=EXCLUDED.url, license_is_explicit=EXCLUDED.license_is_explicit, info=EXCLUDED.info
  ;
  RETURN 'Ok, updated license.licenses_implieds.';
END;
$$;


ALTER FUNCTION license.insert_licenses() OWNER TO postgres;

--
-- Name: FUNCTION insert_licenses(); Type: COMMENT; Schema: license; Owner: postgres
--

COMMENT ON FUNCTION license.insert_licenses() IS 'Update license.licenses_implieds from tmp_orig.redirects_dlguard';


--
-- Name: array_first_not_in_lag(bit varying[], bit varying[]); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.array_first_not_in_lag(p_x bit varying[], p_lag_x bit varying[]) RETURNS bit varying
    LANGUAGE sql IMMUTABLE
    AS $_$
 SELECT CASE
  WHEN $2 IS NULL THEN $1[1]
  ELSE (
   SELECT x
   FROM (SELECT * FROM unnest($1) WITH ORDINALITY t0(x,i) ORDER BY x) g0
        INNER JOIN (SELECT * FROM unnest($2) WITH ORDINALITY t1(y,j) ORDER BY y) g1
     ON i=j 
   WHERE x!=y
   ORDER BY y
   LIMIT 1
  )
  END   
$_$;


ALTER FUNCTION natcod.array_first_not_in_lag(p_x bit varying[], p_lag_x bit varying[]) OWNER TO postgres;

--
-- Name: array_median_length(text[]); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.array_median_length(p_vals text[]) RETURNS integer
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
 SELECT percentile_disc (0.5) WITHIN GROUP ( ORDER BY length(x))
 FROM unnest(p_vals) t(x)
$$;


ALTER FUNCTION natcod.array_median_length(p_vals text[]) OWNER TO postgres;

--
-- Name: FUNCTION array_median_length(p_vals text[]); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.array_median_length(p_vals text[]) IS 'Median of characters-lenght of codes. Used by grid cover generation, see natcod.parents_to_children().';


--
-- Name: array_median_length(bit varying[]); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.array_median_length(p_vals bit varying[]) RETURNS integer
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
 SELECT percentile_disc (0.5) WITHIN GROUP ( ORDER BY length(x))
 FROM unnest(p_vals) t(x)
$$;


ALTER FUNCTION natcod.array_median_length(p_vals bit varying[]) OWNER TO postgres;

--
-- Name: FUNCTION array_median_length(p_vals bit varying[]); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.array_median_length(p_vals bit varying[]) IS 'Median of lenghts of bit string codes. Used by grid cover generation, see natcod.parents_to_children().';


--
-- Name: b16hlist_redux(text[]); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.b16hlist_redux(p_list_b16h text[]) RETURNS text[]
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
   SELECT natcod.vbit_to_baseh(natcod.vbitlist_redux(  natcod.baseh_to_vbit(p_list_b16h,16)  ),16)
$$;


ALTER FUNCTION natcod.b16hlist_redux(p_list_b16h text[]) OWNER TO postgres;

--
-- Name: b16hset_normalize(text[]); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.b16hset_normalize(p_b16h_list text[]) RETURNS text[]
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
  SELECT CASE WHEN array_length(x,1) IS NULL THEN NULL ELSE x END -- same as  x='{}'::anyarray
  FROM (
  	SELECT ARRAY(
        SELECT DISTINCT translate( lower(trim(x)), 'gqhmrvjknpstzy', 'GQHMRVJKNPSTZY' )
        FROM unnest(p_b16h_list) t1(x)
   )
 ) t2(x)
$$;


ALTER FUNCTION natcod.b16hset_normalize(p_b16h_list text[]) OWNER TO postgres;

--
-- Name: FUNCTION b16hset_normalize(p_b16h_list text[]); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.b16hset_normalize(p_b16h_list text[]) IS 'Normalize item syntax as canonical Base 16h, and apply DISTINCT into the array items.';


--
-- Name: b32nvu_to_vbit(text); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.b32nvu_to_vbit(p_val text) RETURNS bit varying
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
 -- see old NaturalCodes/src-sql/step01def-lib_NatCod.sql
 DECLARE
   ch  char;
   ret varbit := b'';
   alphabet text  := '0123456789BCDFGHJKLMNPQRSTUVWXYZ';
 BEGIN
   FOREACH ch IN ARRAY regexp_split_to_array(p_val,'') LOOP
      ret := ret || (strpos(alphabet,ch)-1)::bit(5)::varbit;
   END LOOP;
   RETURN ret;
 END
$$;


ALTER FUNCTION natcod.b32nvu_to_vbit(p_val text) OWNER TO postgres;

--
-- Name: FUNCTION b32nvu_to_vbit(p_val text); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.b32nvu_to_vbit(p_val text) IS 'Faster base32 No-Vogal except U, string to varbit. Algorithm based on strpos.';


--
-- Name: base16h_to_order(text); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.base16h_to_order(p_code text) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT translate(p_code, 'GHJ01K23MN45P67QRS89TabVZcdYef', '0123456789ABCDEFGHIJKLMNOPQRST')
$$;


ALTER FUNCTION natcod.base16h_to_order(p_code text) OWNER TO postgres;

--
-- Name: FUNCTION base16h_to_order(p_code text); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.base16h_to_order(p_code text) IS 'Simulate collation for base 16h, equivalent to bitString lexicographical order.';


--
-- Name: baseh_to_vbit(text, integer); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.baseh_to_vbit(p_val text, p_base integer DEFAULT 4) RETURNS bit varying
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $_$
DECLARE
  tr_hdig jsonb := '{
    "G":[1,0],"Q":[1,1],
    "H":[2,0],"M":[2,1],"R":[2,2],"V":[2,3],
    "J":[3,0],"K":[3,1],"N":[3,2],"P":[3,3],
    "S":[3,4],"T":[3,5],"Y":[3,6],"Z":[3,7]
  }'::jsonb;
  tr_full jsonb := '{
    "0":0,"1":1,"2":2,"3":3,"4":4,"5":5,"6":6,"7":7,"8":8,
    "9":9,"a":10,"b":11,"c":12,"d":13,"e":14,"f":15
  }'::jsonb;
  blk text[];
  bits varbit;
  n int;
  i char;
  ret varbit;
  BEGIN
  ret = '';
  p_val = translate(lower(p_val),'ghjkmnpqrstvyz','GHJKMNPQRSTVYZ');
  blk := regexp_match(p_val,'^([0-9a-f]*)([GHJKMNP-TVYZ])?$');
  IF blk[1] >'' THEN
    FOREACH i IN ARRAY regexp_split_to_array(blk[1],'') LOOP
      ret := ret || CASE p_base
        WHEN 16 THEN (tr_full->>i)::int::bit(4)::varbit
        WHEN 8 THEN (tr_full->>i)::int::bit(3)::varbit
        WHEN 4 THEN (tr_full->>i)::int::bit(2)::varbit
        END;
    END LOOP;
  END IF;
  IF blk[2] >'' THEN
    n = (tr_hdig->blk[2]->>0)::int;
    ret := ret || CASE n
      WHEN 1 THEN (tr_hdig->blk[2]->>1)::int::bit(1)::varbit
      WHEN 2 THEN (tr_hdig->blk[2]->>1)::int::bit(2)::varbit
      WHEN 3 THEN (tr_hdig->blk[2]->>1)::int::bit(3)::varbit
      END;
  END IF;
  RETURN ret;
  END
$_$;


ALTER FUNCTION natcod.baseh_to_vbit(p_val text, p_base integer) OWNER TO postgres;

--
-- Name: FUNCTION baseh_to_vbit(p_val text, p_base integer); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.baseh_to_vbit(p_val text, p_base integer) IS 'Converts text BaseH to bit string, inverse of vbit_to_baseh().';


--
-- Name: baseh_to_vbit(text[], integer, boolean); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.baseh_to_vbit(p_vals text[], p_base integer DEFAULT 4, p_ordering boolean DEFAULT false) RETURNS bit varying[]
    LANGUAGE sql IMMUTABLE
    AS $$
 SELECT CASE
    WHEN p_ordering THEN array_agg(natcod.baseh_to_vbit(c,p_base) ORDER BY c)
    ELSE array_agg(natcod.baseh_to_vbit(c,p_base) ORDER BY ord)
    END
 FROM unnest(p_vals) WITH ORDINALITY t(c,ord)
$$;


ALTER FUNCTION natcod.baseh_to_vbit(p_vals text[], p_base integer, p_ordering boolean) OWNER TO postgres;

--
-- Name: FUNCTION baseh_to_vbit(p_vals text[], p_base integer, p_ordering boolean); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.baseh_to_vbit(p_vals text[], p_base integer, p_ordering boolean) IS 'Converts text BaseH array to bit string array, inverse of vbit_to_baseh(array).';


--
-- Name: bigint_to_vbit(bigint); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.bigint_to_vbit(x bigint) RETURNS bit varying
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$ -- infer LENGTH, low performance!
    SELECT CASE WHEN x<=0 THEN '0'::varbit ELSE substring(x::bit(64), (64-floor(log(x)/log(2)))::int) END
$$;


ALTER FUNCTION natcod.bigint_to_vbit(x bigint) OWNER TO postgres;

--
-- Name: bitlength(integer); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.bitlength(x integer) RETURNS integer
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT 33-position(B'1' in x::bit(32))
$$;


ALTER FUNCTION natcod.bitlength(x integer) OWNER TO postgres;

--
-- Name: FUNCTION bitlength(x integer); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.bitlength(x integer) IS 'The bit-length of the value (non-optimized).';


--
-- Name: bitlength(bigint); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.bitlength(x bigint) RETURNS integer
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT 65-position(B'1' in x::bit(64))
  --   SELECT CASE WHEN p_x<1 THEN 0 ELSE 1+floor(ln(p_x)/ln(2)) END
$$;


ALTER FUNCTION natcod.bitlength(x bigint) OWNER TO postgres;

--
-- Name: FUNCTION bitlength(x bigint); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.bitlength(x bigint) IS 'The bit-length of the value (non-optimized).';


--
-- Name: generate_hb_series(integer, boolean); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.generate_hb_series(bit_len integer, p_non_recursive boolean DEFAULT false) RETURNS SETOF bigint
    LANGUAGE plpgsql IMMUTABLE
    AS $$
-- See optimized at https://stackoverflow.com/q/75503880/287948
DECLARE
  s text;
BEGIN
  IF p_non_recursive THEN
  	  s := 'SELECT * FROM natcod.generatep_hb_series('|| bit_len::text ||')';
  ELSE
	  s := 'SELECT * FROM natcod.generatep_hb_series(1)';
	  FOR i IN 2..bit_len LOOP
	    s := s || ' UNION ALL  SELECT * FROM natcod.generatep_hb_series('|| i::text ||')';
	  END LOOP;
  END IF;
  RETURN QUERY EXECUTE s;
END;
$$;


ALTER FUNCTION natcod.generate_hb_series(bit_len integer, p_non_recursive boolean) OWNER TO postgres;

--
-- Name: FUNCTION generate_hb_series(bit_len integer, p_non_recursive boolean); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.generate_hb_series(bit_len integer, p_non_recursive boolean) IS 'Obtain a sequency of all hidden-bit numbers, for generate_vbit_series().';


--
-- Name: generate_vbit_ranges(integer, integer, boolean); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.generate_vbit_ranges(p_m integer, p_maxlen integer DEFAULT 57, p_include_empty boolean DEFAULT true) RETURNS TABLE(x bit varying, x_max bit varying)
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT CASE WHEN p_include_empty AND x=b'0' THEN b'' ELSE x END,
	 natcod.prefix_to_max(i,p_maxlen) as x_max
  FROM (
	SELECT *, natcod.array_first_not_in_lag( prevs,  lag(prevs) OVER () ) x
	FROM (
	 SELECT i, array_agg(iprev order by iprev) prevs
	 FROM natcod.generate_vbit_series(p_m,true) t1(i)
	 INNER JOIN natcod.generate_vbit_series(p_m) t2(iprev)
	    ON  i<=natcod.prefix_to_max(iprev,p_maxlen)  AND  iprev <= natcod.prefix_to_max(i,p_maxlen)
	 GROUP BY 1
	 ORDER BY 1
	 ) t3
  ) t4
$$;


ALTER FUNCTION natcod.generate_vbit_ranges(p_m integer, p_maxlen integer, p_include_empty boolean) OWNER TO postgres;

--
-- Name: FUNCTION generate_vbit_ranges(p_m integer, p_maxlen integer, p_include_empty boolean); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.generate_vbit_ranges(p_m integer, p_maxlen integer, p_include_empty boolean) IS 'Balanced distribution (near uniform ranges). Like a generate_vbit_series(p_m,true), but including all interval without lost small bit strings';


--
-- Name: generate_vbit_series(integer, boolean); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.generate_vbit_series(bit_len integer, p_non_recursive boolean DEFAULT false) RETURNS SETOF bit varying
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$

  SELECT natcod.hiddenbig_to_vbit(hb)
  FROM natcod.generate_hb_series(
    CASE WHEN bit_len>62 THEN 62 WHEN bit_len<=0 THEN 1 ELSE bit_len END,
    p_non_recursive
  ) t(hb)
  WHERE bit_len>=1
  UNION ALL
  -- lixo SELECT ''::varbit FROM natcod.notable_1row WHERE bit_len=0
  SELECT x FROM ( VALUES (''::varbit) ) s(x) WHERE bit_len=0

  ORDER BY 1
$$;


ALTER FUNCTION natcod.generate_vbit_series(bit_len integer, p_non_recursive boolean) OWNER TO postgres;

--
-- Name: FUNCTION generate_vbit_series(bit_len integer, p_non_recursive boolean); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.generate_vbit_series(bit_len integer, p_non_recursive boolean) IS 'Obtain a sequency of all Natural Codes of bit_len, with 63>bit_len>0.';


--
-- Name: generate_vbit_series_didactic(integer); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.generate_vbit_series_didactic(bit_len integer) RETURNS TABLE(s bit varying, len integer, rval integer, lval integer, lval_rot integer, "lval_rot+len" integer, rval_bin bit varying, lval_bin bit varying, len_bin bit varying, "bin(lval_rot+len)" bit varying)
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT s,len,rval,lval,
         lval<<llen, -- lval_rot,
         len + (lval<<llen), -- lval_rot+len. use (natcod.bitlength(bit_len)+1) for empty string = 0
         substring(rval::bit(32),b32len), -- as rval_bin,
         substring(lval::bit(32),b32len), -- as lval_bin,
         len_bin,
         substring( (length(s) + (lval<<llen))::bit(32), 33-bit_len-llen)
  FROM (
    SELECT *, natcod.bitlength(bit_len) as llen,
        32-bit_len+1 as b32len,
        substring(length(s)::bit(32),33-natcod.bitlength(bit_len)) as len_bin
    FROM (
      SELECT s, length(s) as len,
         vbit_to_int(s) as rval, -- conferir se mesmo que natcod.vbit_to_intval()
         (b'0'||s)::bit(32)::int>>(32-bit_len-1) as lval
      FROM natcod.generate_vbit_series(bit_len) t1(s)
    ) t2
  ) t3
$$;


ALTER FUNCTION natcod.generate_vbit_series_didactic(bit_len integer) OWNER TO postgres;

--
-- Name: FUNCTION generate_vbit_series_didactic(bit_len integer); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.generate_vbit_series_didactic(bit_len integer) IS 'Obtain a sequency and didactic explain of Natural Codes of bit_len, and right-copy value, left-copy-value, etc.';


--
-- Name: generatep_hb_series(integer); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.generatep_hb_series(bit_len integer) RETURNS SETOF bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT i::bigint | maxval as x
  FROM (SELECT (2^bit_len)::bigint) t(maxval),
       LATERAL generate_series(0,maxval-1) s(i)
$$;


ALTER FUNCTION natcod.generatep_hb_series(bit_len integer) OWNER TO postgres;

--
-- Name: FUNCTION generatep_hb_series(bit_len integer); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.generatep_hb_series(bit_len integer) IS 'Obtain a sequency of hidden-bit Natural Codes P set (fixed length), from zero to 2^bit_len-1.';


--
-- Name: hbig_to_vbit(bigint); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.hbig_to_vbit(x bigint) RETURNS bit varying
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT substring( x::bit(64) from 2 for (x&63)::int );
$$;


ALTER FUNCTION natcod.hbig_to_vbit(x bigint) OWNER TO postgres;

--
-- Name: FUNCTION hbig_to_vbit(x bigint); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.hbig_to_vbit(x bigint) IS 'Fast conversion, from efficient hierarchical Bigint representation to Varbit.';


--
-- Name: hiddenbig_to_vbit(bigint); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.hiddenbig_to_vbit(x bigint) RETURNS bit varying
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT natcod.hiddenbig_to_vbit(x,0)
$$;


ALTER FUNCTION natcod.hiddenbig_to_vbit(x bigint) OWNER TO postgres;

--
-- Name: FUNCTION hiddenbig_to_vbit(x bigint); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.hiddenbig_to_vbit(x bigint) IS 'Wrap function. Converts hidden-bit Natural Code BigInt into VarBit.';


--
-- Name: hiddenbig_to_vbit(bigint, integer); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.hiddenbig_to_vbit(x bigint, p integer) RETURNS bit varying
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$  -- hb_decode
  SELECT substring( x_bin from 1+p+position(B'1' in x_bin) )  -- not use log2, perhaps better performance
  FROM (select x::bit(64)) t(x_bin) -- WHERE $1>7 AND $1<4611686018427387904
$_$;


ALTER FUNCTION natcod.hiddenbig_to_vbit(x bigint, p integer) OWNER TO postgres;

--
-- Name: FUNCTION hiddenbig_to_vbit(x bigint, p integer); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.hiddenbig_to_vbit(x bigint, p integer) IS 'Converts hidden-bit Natural Code BigInt into VarBit. Disregards most significant p bits';


--
-- Name: int_to_vbit(integer); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.int_to_vbit(x integer) RETURNS bit varying
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$ -- infer LENGTH, low performance!
    SELECT CASE WHEN x<=0 THEN '0'::varbit ELSE substring(x::bit(32), (32-floor(log(x)/log(2)))::int) END
$$;


ALTER FUNCTION natcod.int_to_vbit(x integer) OWNER TO postgres;

--
-- Name: list_to_reduxseq(text[]); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.list_to_reduxseq(p_list text[]) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
  WITH prep AS (
    SELECT g.i, t2.*
    FROM ( -- podem ocorrer listas completas (ex. '2,G,H,Q'), e mais de uma simultaneamente: troca a lista completa por "."
      SELECT CASE WHEN '{0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f}'::text[] <@ i0 THEN '{.}'||array_subtract(i0,'{0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f}'::text[]) ELSE i0 END FROM (
        SELECT CASE WHEN '{J,K,N,P,S,T,Y,Z}'::text[] <@ i0 THEN '{.}'||array_subtract(i0,'{J,K,N,P,S,T,Y,Z}'::text[]) ELSE i0 END FROM (
          SELECT CASE WHEN '{H,M,R,V}'::text[] <@ i0 THEN '{.}'||array_subtract(i0,'{H,M,R,V}'::text[]) ELSE i0 END FROM (
            SELECT CASE WHEN '{G,Q}'::text[] <@ i0 THEN '{.}'||array_subtract(i0,'{G,Q}'::text[]) ELSE i0 END
            FROM ( SELECT natcod.b16hSet_normalize($1) ) t0i0(i0)
          ) t0i1(i0)
        ) t0i2(i0)
      ) t0i3(i0)
    ) t1(input),  -- t1 faz todas normalizações sobre o input $1.
    generate_series( 1, length(input::text)/cardinality(input)-1 ) g(i),
    natcod.list_to_reduxseq_prepare(input,i) t2 -- i as prefix shift.
  ),
  s AS (
     SELECT i, sum(score)+count(*) - 1 as score FROM prep GROUP BY 1 ORDER BY 1
  ),
  find AS (
    SELECT i
    FROM s
    WHERE score=(SELECT MIN(score) FROM s)
    ORDER BY 1 LIMIT 1
  ),
  final AS (
      SELECT replace( string_agg(
         prefix||(CASE WHEN cardinality(suffixes)=1 THEN suffixes[1] ELSE suffixes::text END),
         ',' ORDER BY prefix
       ),  '""', '.')  AS output
      FROM prep
      WHERE i = (SELECT i FROM find)
  )
  SELECT natcod.reduxseq_to_list_beaulty(
    natcod.list_to_reduxseq_recursive_check(output)
  )
  FROM final
$_$;


ALTER FUNCTION natcod.list_to_reduxseq(p_list text[]) OWNER TO postgres;

--
-- Name: FUNCTION list_to_reduxseq(p_list text[]); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.list_to_reduxseq(p_list text[]) IS 'Convert a comma-separated list of codes into reduxseq format. See https://wikifull.addressforall.org/doc/ReduxSeq_format.';


--
-- Name: list_to_reduxseq_prepare(text[], integer); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.list_to_reduxseq_prepare(p_list text[], p_shift integer DEFAULT 1) RETURNS TABLE(prefix text, suffixes text[], n integer, score integer)
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT *,
         length(prefix || CASE WHEN n=1 THEN suffixes[1] ELSE suffixes::text END) as score
  FROM (
    SELECT substring(x,1,p_shift) as prefix,
           array_agg(substring(x,p_shift+1)) as suffixes,
           count(*) n
    FROM (SELECT x FROM unnest($1) t0(x) ORDER BY natcod.base16h_to_order(x)) t1
    GROUP BY 1 ORDER BY 1
  ) t2
$_$;


ALTER FUNCTION natcod.list_to_reduxseq_prepare(p_list text[], p_shift integer) OWNER TO postgres;

--
-- Name: FUNCTION list_to_reduxseq_prepare(p_list text[], p_shift integer); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.list_to_reduxseq_prepare(p_list text[], p_shift integer) IS 'Used in list_to_reduxseq() function, or for debug analysis. Create reduced sequencies with bitstring lexicographical order.';


--
-- Name: list_to_reduxseq_recursive_check(text); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.list_to_reduxseq_recursive_check(p_list text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    tmp RECORD;
    s text;
    s_before text default '';
    protect int default 1;
    need_more int default 1;
BEGIN
  s := p_list;
  WHILE protect<100 AND need_more>0 AND s_before!=s LOOP
    s_before := s;
    need_more :=0;
  	FOR tmp IN
      SELECT x[1] as original, natcod.list_to_reduxseq(x[1]::text[]) as redux
      FROM regexp_matches(s, '(\{[^\{\}]+\})', 'g') t(x) ORDER BY 1
  	LOOP
       IF tmp.original>'' AND tmp.original!=tmp.redux THEN
          s := replace(s, tmp.original, '{'||tmp.redux||'}');
          need_more := need_more+1;
       END IF;
  	END LOOP; -- /tmp
    protect:=protect+1;
    -- raise notice '  loop: %', s;
  END LOOP; -- /while
	RETURN s;
END;
$$;


ALTER FUNCTION natcod.list_to_reduxseq_recursive_check(p_list text) OWNER TO postgres;

--
-- Name: FUNCTION list_to_reduxseq_recursive_check(p_list text); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.list_to_reduxseq_recursive_check(p_list text) IS '(internal use) Check oppotunities for more reduction after natcod.list_to_reduxseq() core.';


--
-- Name: parents_to_children(integer, bit varying[], boolean, boolean); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.parents_to_children(p_intlevel integer, bit varying[], boolean DEFAULT true, boolean DEFAULT true) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $_$
 SELECT natcod.parents_to_children( p_intlevel/10.0, $2, $3, $4 )
$_$;


ALTER FUNCTION natcod.parents_to_children(p_intlevel integer, bit varying[], boolean, boolean) OWNER TO postgres;

--
-- Name: parents_to_children(real, bit varying[], boolean, boolean, boolean); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.parents_to_children(p_level real, p_l0_list bit varying[], p_non_recursive boolean DEFAULT true, p_majority boolean DEFAULT true, p_non_repeat boolean DEFAULT true) RETURNS bit varying[]
    LANGUAGE sql IMMUTABLE
    AS $$
 SELECT array_agg(cbits ORDER BY cbits)
 FROM (
   WITH l0_mj AS (SELECT natcod.array_median_length(p_l0_list) AS majority_len)

   SELECT DISTINCT c FROM unnest(p_l0_list) l0(c), l0_mj
   WHERE (p_level=0.0 OR NOT(p_non_recursive))
         AND  not(p_non_repeat is null and length(c) > majority_len)

  UNION ALL
   SELECT *
   FROM (
     SELECT DISTINCT CASE
       WHEN p_majority AND majority_len < length(l0.cbits) THEN CASE
         WHEN (length(t.cbits) + majority_len) <= length(l0.cbits) THEN -- gambiarra do null, simplificar:
            CASE WHEN p_non_repeat=true THEN NULL
            WHEN p_non_repeat IS NULL AND (length(t.cbits) + majority_len = length(l0.cbits)) THEN l0.cbits
            WHEN p_non_repeat IS NOT NULL AND p_non_repeat=false THEN l0.cbits END
         ELSE l0.cbits || substring( t.cbits, length(l0.cbits)-majority_len +1 )
         END
       ELSE l0.cbits||t.cbits
     END c
     FROM natcod.generate_vbit_series( (p_level*2.0)::int, p_non_recursive ) t(cbits),
          unnest(p_l0_list) l0(cbits), l0_mj
     WHERE p_level>0.0
   )t3 WHERE c IS NOT NULL
 ) t2 (cbits)
$$;


ALTER FUNCTION natcod.parents_to_children(p_level real, p_l0_list bit varying[], p_non_recursive boolean, p_majority boolean, p_non_repeat boolean) OWNER TO postgres;

--
-- Name: FUNCTION parents_to_children(p_level real, p_l0_list bit varying[], p_non_recursive boolean, p_majority boolean, p_non_repeat boolean); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.parents_to_children(p_level real, p_l0_list bit varying[], p_non_recursive boolean, p_majority boolean, p_non_repeat boolean) IS 'Generate series of cbits of a country defined by p_l0_list_b16. When p_non_recursive is false generates recursivally. When p_majority is false ignores abnormal list.';


--
-- Name: parents_to_children_baseh(real, text[], integer, boolean, boolean, boolean); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.parents_to_children_baseh(p_level real, p_l0_list text[], p_baseh integer DEFAULT 16, p_non_recursive boolean DEFAULT true, p_majority boolean DEFAULT true, p_non_repeat boolean DEFAULT true) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
 SELECT natcod.vbit_to_baseh(
           natcod.parents_to_children(p_level, natcod.baseh_to_vbit(p_l0_list,p_baseh), p_non_recursive, p_majority,p_non_repeat),
           p_baseh,
           true   -- ordered
       )
$$;


ALTER FUNCTION natcod.parents_to_children_baseh(p_level real, p_l0_list text[], p_baseh integer, p_non_recursive boolean, p_majority boolean, p_non_repeat boolean) OWNER TO postgres;

--
-- Name: FUNCTION parents_to_children_baseh(p_level real, p_l0_list text[], p_baseh integer, p_non_recursive boolean, p_majority boolean, p_non_repeat boolean); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.parents_to_children_baseh(p_level real, p_l0_list text[], p_baseh integer, p_non_recursive boolean, p_majority boolean, p_non_repeat boolean) IS 'Generate series of parent-list defined by p_l0_list, a base16 list of codes. When p_non_recursive is false generates recursivally. When p_majority is false ignores abnormal list. Wrap for parents_to_children().';


--
-- Name: parents_to_children_baseh(integer, text[], integer, boolean, boolean, boolean); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.parents_to_children_baseh(p_intlevel integer, text[], integer, boolean DEFAULT true, boolean DEFAULT true, boolean DEFAULT true) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $_$
 SELECT natcod.parents_to_children_baseh( p_intlevel/10.0, $2, $3, $4, $5, $6 )
$_$;


ALTER FUNCTION natcod.parents_to_children_baseh(p_intlevel integer, text[], integer, boolean, boolean, boolean) OWNER TO postgres;

--
-- Name: prefix_to_max(bit varying, integer); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.prefix_to_max(p bit varying, len integer DEFAULT 57) RETURNS bit varying
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT substring(p||b'1111111111111111111111111111111111111111111111111111111111111111' from 1 for len)
$$;


ALTER FUNCTION natcod.prefix_to_max(p bit varying, len integer) OWNER TO postgres;

--
-- Name: FUNCTION prefix_to_max(p bit varying, len integer); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.prefix_to_max(p bit varying, len integer) IS 'fill ones to length (unlimited), to obtain the range of a prefix, from itself.';


--
-- Name: reduxseq_to_list(text); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.reduxseq_to_list(p_list text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    tmp RECORD;
    s text;
    s_before text default '';
    protect int default 1;
BEGIN
  s := p_list;
  WHILE protect<100 AND s_before!=s LOOP
    s_before := s;
  	FOR tmp IN
  		SELECT original, merged FROM natcod.reduxseq_to_list_prepare(s_before)
  	LOOP
       -- raise notice '%. s=%', protect, s;
  	   -- raise notice '  % = %', tmp.original, tmp.merged;
       s := replace(s, tmp.original, tmp.merged);
  	END LOOP; -- /tmp
    protect:=protect+1;
    -- raise notice '  loop';
  END LOOP; -- /while
	RETURN s;
END;
$$;


ALTER FUNCTION natcod.reduxseq_to_list(p_list text) OWNER TO postgres;

--
-- Name: reduxseq_to_list_beaulty(text); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.reduxseq_to_list_beaulty(p_list text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    tmp RECORD;
    s_aux text;
BEGIN
	FOR tmp IN
		SELECT original, merged FROM natcod.reduxseq_to_list_prepare(p_list)
	LOOP
     s_aux := replace(p_list, tmp.original, tmp.merged);
     IF length(s_aux)-3 < length(p_list) THEN -- quality control
        p_list := s_aux;
     END IF;
	END LOOP; -- /tmp
  RETURN regexp_replace(p_list, '([\{,])\{([^\{\}]+)\}', '\1\2', 'g');
  -- replace for e.g. 'a170d14bf,a170d16{{1,11,1M},4{0,6,b,K,S,V},5T,65,70}'
END;
$$;


ALTER FUNCTION natcod.reduxseq_to_list_beaulty(p_list text) OWNER TO postgres;

--
-- Name: FUNCTION reduxseq_to_list_beaulty(p_list text); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.reduxseq_to_list_beaulty(p_list text) IS '(internal use) Expands useless-redux after natcod.list_to_reduxseq() core. The beaulty-format for humamns.';


--
-- Name: reduxseq_to_list_prepare(text); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.reduxseq_to_list_prepare(p_list text) RETURNS TABLE(original text, merged text)
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT CASE WHEN x[1] IS NULL THEN '{'||x[3]||'}' ELSE x[1]||'{'||x[2]||'}' END as original,
         CASE WHEN x[1] IS NULL THEN x[3]           ELSE translate( array_rebuild_add_prefix( x[1], ('{'||x[2]||'}')::text[], '' )::text, '.', '') END AS merged
  FROM regexp_matches(p_list, '(?:([^\{\},]+)\{([^\{\}]+)\})|(?:\{([^\{\}]+)\})', 'g') t(x)
  ORDER BY 1
$$;


ALTER FUNCTION natcod.reduxseq_to_list_prepare(p_list text) OWNER TO postgres;

--
-- Name: FUNCTION reduxseq_to_list_prepare(p_list text); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.reduxseq_to_list_prepare(p_list text) IS '(internal use) Prepare inner parts for reduxseq_to_list functions.';


--
-- Name: strbit_to_vbit(text, integer); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.strbit_to_vbit(b text, p_len integer DEFAULT NULL::integer) RETURNS bit varying
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
   SELECT CASE WHEN p_len>0 THEN  lpad(b, p_len, '0')::varbit ELSE  b::varbit  END
$$;


ALTER FUNCTION natcod.strbit_to_vbit(b text, p_len integer) OWNER TO postgres;

--
-- Name: FUNCTION strbit_to_vbit(b text, p_len integer); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.strbit_to_vbit(b text, p_len integer) IS 'Cast from string to varbit, with optional lpad zeros when given a length.';


--
-- Name: vbit_to_baseh(bit varying, integer); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.vbit_to_baseh(p_val bit varying, p_base integer DEFAULT 4) RETURNS text
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $_$
DECLARE
    vlen int;
    pos0 int;
    ret text := '';
    blk varbit;
    blk_n int;
    bits_per_digit int;
    tr int[] := '{ {1,2,0,0}, {1,3,4,0}, {1,3,5,6} }'::int[]; -- --4h(bits,pos), 8h(bits,pos)
    tr_selected JSONb;
    trtypes JSONb := '{"2":[1,1], "4":[1,2], "8":[2,3], "16":[3,4]}'::JSONb; -- TrPos,bits. Can optimize? by sparse array.
    trpos int;
    baseh "char"[] := array[ -- new 2023 standard for Baseh:
    '[0:15]={G,Q,x,x,x,x,x,x,x,x,x,x,x,x,x,x}'::"char"[], --1. 1 bit in 4h,8h,16h
    '[0:15]={0,1,2,3,x,x,x,x,x,x,x,x,x,x,x,x}'::"char"[], --2. 2 bits in 4h
    '[0:15]={H,M,R,V,x,x,x,x,x,x,x,x,x,x,x,x}'::"char"[], --3. 2 bits 8h,16h
    '[0:15]={0,1,2,3,4,5,6,7,x,x,x,x,x,x,x,x}'::"char"[], --4. 3 bits in 8h
    '[0:15]={J,K,N,P,S,T,Y,Z,x,x,x,x,x,x,x,x}'::"char"[], --5. 3 bits in 16h
    '[0:15]={0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f}'::"char"[]  --6. 4 bits in standard hex
    ]; -- jumpping I,O and L,U,W,X letters;
       -- the standard hexadecimals as https://tools.ietf.org/html/rfc4648#section-6
BEGIN
  vlen := bit_length(p_val);
  tr_selected := trtypes->(p_base::text);  -- can be array instead of JSON
  IF p_val IS NULL OR tr_selected IS NULL THEN
    RETURN NULL; -- or  p_retnull;
  ELSIF vlen=0 THEN
     RETURN b'';
  END IF;
  IF p_base=2 THEN
    RETURN $1::text; --- direct bit string as string
  END IF;
  bits_per_digit := (tr_selected->>1)::int;
  blk_n := vlen/bits_per_digit;
  pos0  := (tr_selected->>0)::int;
  trpos := tr[pos0][bits_per_digit];
  FOR counter IN 1..blk_n LOOP
      blk := substring(p_val FROM 1 FOR bits_per_digit);
      ret := ret || baseh[trpos][ vbit_to_int(blk,bits_per_digit) ]::text;
      p_val := substring(p_val FROM bits_per_digit+1); -- same as p_val<<(bits_per_digit*blk_n)
  END LOOP;
  vlen := bit_length(p_val);
  IF p_val!=b'' THEN -- vlen % bits_per_digit>0
    trpos := tr[pos0][vlen];
    ret := ret || baseh[trpos][ vbit_to_int(p_val,vlen) ]::text;
  END IF;
  RETURN ret;
END
$_$;


ALTER FUNCTION natcod.vbit_to_baseh(p_val bit varying, p_base integer) OWNER TO postgres;

--
-- Name: FUNCTION vbit_to_baseh(p_val bit varying, p_base integer); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.vbit_to_baseh(p_val bit varying, p_base integer) IS 'Converts bit string to text, using base2h, base4h, base8h or base16h. Uses letters "G" and "H" to sym44bolize non strandard bit strings (0 for44 bases44). Uses extended alphabet (with no letter I,O,U W or X) for base8h and base16h.';


--
-- Name: vbit_to_baseh(bit varying[], integer, boolean); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.vbit_to_baseh(p_vals bit varying[], p_base integer DEFAULT 4, p_ordering boolean DEFAULT false) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
 SELECT CASE
    WHEN p_ordering THEN array_agg(natcod.vbit_to_baseh(c,p_base) ORDER BY c)
    ELSE array_agg(natcod.vbit_to_baseh(c,p_base) ORDER BY ord)
    END
 FROM unnest(p_vals) WITH ORDINALITY t(c,ord)
$$;


ALTER FUNCTION natcod.vbit_to_baseh(p_vals bit varying[], p_base integer, p_ordering boolean) OWNER TO postgres;

--
-- Name: FUNCTION vbit_to_baseh(p_vals bit varying[], p_base integer, p_ordering boolean); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.vbit_to_baseh(p_vals bit varying[], p_base integer, p_ordering boolean) IS 'Converts text BaseH array to bit string array, inverse of baseh_to_vbit(array) and a wrap to vbit_to_baseh(scalar).';


--
-- Name: vbit_to_hanyint(bit varying, integer); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.vbit_to_hanyint(p_b bit varying, p_k integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE
    AS $$  -- replace by vBit_to_hAnyInt2?
  SELECT x
  FROM dynamic_query(
       format('SELECT vbit_to_bigint( (b%L||b%L)::bit(%s) ||  %s::bit(%s) )::bigint AS x', 0, p_b, p_k+1, length(p_b), ceil(log(1+p_k)/log(2)) )
  ) t(x bigint)
  WHERE p_k<=57 AND length(p_b)<=p_k
$$;


ALTER FUNCTION natcod.vbit_to_hanyint(p_b bit varying, p_k integer) OWNER TO postgres;

--
-- Name: FUNCTION vbit_to_hanyint(p_b bit varying, p_k integer); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.vbit_to_hanyint(p_b bit varying, p_k integer) IS '(use vBit_to_hAnyInt2? depends on vbit_to_bigint) Converts varbit into hInt of any integer-type. Any code with less tham 57 bits, to use maximum of 6 bits of cache.';


--
-- Name: vbit_to_hanyint2(bit varying, integer); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.vbit_to_hanyint2(p_b bit varying, p_k integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT x
  FROM dynamic_query(
       format(E'SELECT OVERLAY( b\'0\'::bit(64) PLACING (b\'0\'||b%L || %s::bit(%s)) FROM %s )::bigint AS x', p_b, length(p_b), ceil(log(1+p_k)/log(2)), 65-length(p_b) )
  ) t(x bigint)
  WHERE p_k>=0 AND p_k<=57 AND length(p_b)<=p_k
$$;


ALTER FUNCTION natcod.vbit_to_hanyint2(p_b bit varying, p_k integer) OWNER TO postgres;

--
-- Name: FUNCTION vbit_to_hanyint2(p_b bit varying, p_k integer); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.vbit_to_hanyint2(p_b bit varying, p_k integer) IS '(best than vBit_to_hAnyInt? need tests?) Converts varbit into hInt of any integer-type. Any code with less tham 57 bits, to use maximum of 6 bits of cache.';


--
-- Name: vbit_to_hbig(bit varying, integer); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.vbit_to_hbig(b bit varying, blen integer DEFAULT NULL::integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
-- penging bug on blen, it not reduce b length, only expands.
  -- max of 57 bits (64-1-6). Left_copy of value by x::bit(64) and right_copy of the bitstring_lenght.
  SELECT overlay( (b'0' || b)::bit(64) PLACING COALESCE(blen,length(b))::bit(6) FROM 59 )::bigint
$$;


ALTER FUNCTION natcod.vbit_to_hbig(b bit varying, blen integer) OWNER TO postgres;

--
-- Name: FUNCTION vbit_to_hbig(b bit varying, blen integer); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.vbit_to_hbig(b bit varying, blen integer) IS 'Fast conversion and efficient hierarchical representation, from Varbit to Bigint.';


--
-- Name: vbit_to_hiddenbig(bit varying); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.vbit_to_hiddenbig(x bit varying) RETURNS bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$  -- hb_encode
  SELECT overlay( b'0'::bit(64) PLACING (b'1' || x) FROM 64-length(x) )::bigint
$$;


ALTER FUNCTION natcod.vbit_to_hiddenbig(x bit varying) OWNER TO postgres;

--
-- Name: FUNCTION vbit_to_hiddenbig(x bit varying); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.vbit_to_hiddenbig(x bit varying) IS 'Converts VarBit into a hidden-bit Natural Code BigInt.';


--
-- Name: vbit_to_hint(bit varying, integer); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.vbit_to_hint(b bit varying, blen integer DEFAULT NULL::integer) RETURNS integer
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  -- max of 26 bits (32-1-5). Left_copy of value by x::bit(32) and right_copy of the bitstring_lenght.
  SELECT overlay( (b'0' || b)::bit(32) PLACING COALESCE(blen,length(b))::bit(5) FROM 28 )::int;
$$;


ALTER FUNCTION natcod.vbit_to_hint(b bit varying, blen integer) OWNER TO postgres;

--
-- Name: FUNCTION vbit_to_hint(b bit varying, blen integer); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.vbit_to_hint(b bit varying, blen integer) IS 'Fast conversion and efficient hierarchical representation, from Varbit to Integer.';


--
-- Name: vbit_to_hsml(bit varying, integer); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.vbit_to_hsml(b bit varying, blen integer DEFAULT NULL::integer) RETURNS smallint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  -- max of 11 bits (16-1-4). Half_Left_copy of value by x::bit(16)m padding zeros on other left 16 bits.
  -- NÃO precisaria do zero a esqueda do sinal ... mas pode ajudar na equivalência com inteiro... Testar com e sem.
  SELECT overlay( (b'0' || b)::bit(16) PLACING COALESCE(blen,length(b))::bit(4) FROM 13)::int;
  --- testar denovo com b::bit(16)
$$;


ALTER FUNCTION natcod.vbit_to_hsml(b bit varying, blen integer) OWNER TO postgres;

--
-- Name: FUNCTION vbit_to_hsml(b bit varying, blen integer); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.vbit_to_hsml(b bit varying, blen integer) IS 'Fast conversion and efficient hierarchical representation, from Varbit to Smallint.';


--
-- Name: vbit_to_str(bit varying, text); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.vbit_to_str(p_val bit varying, p_base text DEFAULT '4h'::text) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$
  SELECT CASE WHEN x IS NULL OR p_val IS NULL THEN NULL
    WHEN x[1] IS NULL THEN  natcod.vbit_to_strstd(p_val, x[2])
    ELSE  natcod.vbit_to_baseh(p_val, x[1]::int)  END
  FROM regexp_match(lower(p_base), '^(?:base\-?\s*)?(?:(\d+)h|(\d.+))$') t(x);
$_$;


ALTER FUNCTION natcod.vbit_to_str(p_val bit varying, p_base text) OWNER TO postgres;

--
-- Name: FUNCTION vbit_to_str(p_val bit varying, p_base text); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.vbit_to_str(p_val bit varying, p_base text) IS 'Converts bit string to text, wrap funtion for vbit_to_strstd() and vbit_to_baseh().';


--
-- Name: vbit_to_strstd(bit varying, text); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.vbit_to_strstd(p_val bit varying, p_base text DEFAULT '4js'::text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $_$
DECLARE
    vlen int;
    pos0 int;
    ret text := '';
    blk varbit;
    blk_n int;
    bits_per_digit int;
    trtypes JSONb := '{
      "4js":[0,1,2],"8js":[0,1,3],"16js":[0,1,4],
      "32ghs":[1,4,5],"32hex":[1,1,5],"32nvu":[1,2,5],"32rfc":[1,3,5],
      "64url":[2,8,6],"32js":[1,1,5]
    }'::JSONb; -- var,pos,bits
    base0 "char"[] := array[
      '[0:15]={0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f}'::"char"[] --1. 4, 5 , 16 js
    ];
    base1 "char"[] := array[
       '[0:31]={0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v}'::"char"[] --1=32hex
      ,'[0:31]={0,1,2,3,4,5,6,7,8,9,B,C,D,F,G,H,J,K,L,M,N,P,Q,R,S,T,U,V,W,X,Y,Z}'::"char"[] --2=32nvu
      ,'[0:31]={A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,2,3,4,5,6,7}'::"char"[] --3=32rfc
      ,'[0:31]={0,1,2,3,4,5,6,7,8,9,b,c,d,e,f,g,h,j,k,m,n,p,q,r,s,t,u,v,w,x,y,z}'::"char"[] --4=32ghs
    ];
    -- "64url": "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
    tr_selected JSONb;
    trbase "char"[];
BEGIN
  vlen := bit_length(p_val);
  tr_selected := trtypes->(p_base::text);-- [1=var,2=pos,3=bits]
  IF p_val IS NULL OR tr_selected IS NULL OR vlen=0 THEN
    RETURN NULL; -- or  p_retnull;
  END IF;
  IF p_base='2' THEN
     -- need to strip leading zeros
    RETURN $1::text; --- direct bit string as string
  END IF;
  bits_per_digit := (tr_selected->>2)::int;
  IF vlen % bits_per_digit != 0 THEN
    RETURN NULL;  -- trigging ERROR
  END IF;
  blk_n := vlen/bits_per_digit;
  pos0 = (tr_selected->>1)::int;
  -- trbase := CASE tr_selected->>0 WHEN '0' THEN base0[pos0] ELSE base1[pos0] END; -- NULL! pgBUG?
  trbase := CASE tr_selected->>0 WHEN '0' THEN base0 ELSE base1 END;
  --RAISE NOTICE 'HELLO: %; % % -- %',pos0,blk_n,trbase,trbase[pos0][1];
  FOR counter IN 1..blk_n LOOP
      blk := substring(p_val FROM 1 FOR bits_per_digit);
      ret := ret || trbase[pos0][ vbit_to_int(blk,bits_per_digit) ]::text;
      p_val := substring(p_val FROM bits_per_digit+1);
  END LOOP;
  vlen := bit_length(p_val);
  -- IF p_val!=b'' THEN ERROR
  RETURN ret;
END
$_$;


ALTER FUNCTION natcod.vbit_to_strstd(p_val bit varying, p_base text) OWNER TO postgres;

--
-- Name: FUNCTION vbit_to_strstd(p_val bit varying, p_base text); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.vbit_to_strstd(p_val bit varying, p_base text) IS 'Converts bit string to text, using standard numeric bases (base4js, base32ghs, etc.).';


--
-- Name: vbitlist_redux(bit varying[]); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.vbitlist_redux(p_list bit varying[]) RETURNS bit varying[]
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
DECLARE
    tmp RECORD;
    s varbit;
    s_list varbit[];
    need_more int default 40; -- guard limit, how to define?
BEGIN
  s_list := p_list;
  WHILE need_more>0 LOOP
  	FOR tmp IN
      SELECT bool_or(cond) as cond,
          array_agg(CASE WHEN cond AND (ldcond is null OR not(ldcond)) THEN NULL WHEN ldcond THEN substring(x,1,lx-1) ELSE x END) final
      FROM ( -- t5
        SELECT *, lead(cond) over() ldcond
        FROM ( -- t4
          SELECT *, llx=lx AND lx>1 AND substring(x,1,lx-1)=substring(lg,1,lx-1) cond
          FROM ( -- t3
            SELECT *, lag(x) over() lg, lag(lx) over() llx
            FROM (
              SELECT DISTINCT x, length(x) lx
              FROM unnest(s_list) t(x)
              WHERE x IS NOT NULL
              ORDER BY 2 DESC,1
            ) t2
          ) t3
        ) t4
      ) t5
    LOOP
    need_more := CASE WHEN tmp.cond THEN need_more-1 ELSE 0 END; -- ou "" dentro de tmp.final!
    s_list := tmp.final;
    END LOOP; -- /FOR tmp
  END LOOP; -- /WHILE need_more
	RETURN array_distinct_sort(s_list);
END;
$$;


ALTER FUNCTION natcod.vbitlist_redux(p_list bit varying[]) OWNER TO postgres;

--
-- Name: FUNCTION vbitlist_redux(p_list bit varying[]); Type: COMMENT; Schema: natcod; Owner: postgres
--

COMMENT ON FUNCTION natcod.vbitlist_redux(p_list bit varying[]) IS 'Reduces list by aggregation oppotunities, see ReduxSeq format. PENDING: remove subcells!!';


--
-- Name: vbitlist_to_b16h(bit varying[]); Type: FUNCTION; Schema: natcod; Owner: postgres
--

CREATE FUNCTION natcod.vbitlist_to_b16h(p_list bit varying[]) RETURNS text[]
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT array_agg(natcod.vbit_to_baseh(x,16)) FROM unnest(p_list) t(x)
$$;


ALTER FUNCTION natcod.vbitlist_to_b16h(p_list bit varying[]) OWNER TO postgres;

--
-- Name: approved_packcomponent(bigint); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.approved_packcomponent(p_id bigint) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
  q text;
BEGIN
  q := $$
    INSERT INTO optim.donated_PackComponent (packvers_id, ftid, is_evidence, proc_step, lineage, lineage_md5, kx_profile)
    SELECT packvers_id, ftid, is_evidence, proc_step, lineage, lineage_md5, coalesce(kx_profile,'{}'::jsonb) || jsonb_build_object( 'date_aprroved', (date_trunc('second',NOW())) )
    FROM optim.donated_PackComponent_not_approved
    WHERE id=%s
    ON CONFLICT (packvers_id,ftid,lineage_md5)
    DO UPDATE
    SET (is_evidence, proc_step, lineage, kx_profile) = (EXCLUDED.is_evidence, EXCLUDED.proc_step, EXCLUDED.lineage, EXCLUDED.kx_profile);
    DELETE FROM optim.donated_PackComponent_not_approved WHERE id=%s
  $$;

  EXECUTE format( q, p_id, p_id ) ;

  RETURN (SELECT 'OK, approved.');
END;
$_$;


ALTER FUNCTION optim.approved_packcomponent(p_id bigint) OWNER TO postgres;

--
-- Name: fdw_generate(text, text, text, text[], boolean, text, text, boolean); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.fdw_generate(p_name text, p_jurisdiction text DEFAULT 'br'::text, p_schemaname text DEFAULT 'optim'::text, p_columns text[] DEFAULT NULL::text[], p_addtxtype boolean DEFAULT false, p_path text DEFAULT NULL::text, p_delimiter text DEFAULT ','::text, p_header boolean DEFAULT true) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
 fdwname text;
 f text;
 sepcols text;
BEGIN
 f := concat( COALESCE(p_path,'/var/gits/_dg'), '/preserv', iIF(p_jurisdiction='INT', '', '-' || UPPER(p_jurisdiction)), '/data/', p_name, '.csv');
 fdwname := 'tmp_orig.fdw_'|| iIF(p_schemaname='optim', ''::text, p_schemaname || '_') || p_name || p_jurisdiction;
 sepcols := iIF(p_addtxtype, '" text,"'::text, ','::text);
 EXECUTE
    format(
      'DROP FOREIGN TABLE IF EXISTS %s; CREATE FOREIGN TABLE %s    (%s%s%s)',
       fdwname, fdwname,  iIF(p_addtxtype, '"'::text, ''::text), array_to_string(p_columns,sepcols), iIF(p_addtxtype, '" text'::text, '')
     ) || format(
       'SERVER files OPTIONS (filename %L, format %L, header %L, delimiter %L)',
       f, 'csv', p_header::text, p_delimiter
    );
    return ' '|| fdwname || E' was created!\n source: '||f|| ' ';
END;
$$;


ALTER FUNCTION optim.fdw_generate(p_name text, p_jurisdiction text, p_schemaname text, p_columns text[], p_addtxtype boolean, p_path text, p_delimiter text, p_header boolean) OWNER TO postgres;

--
-- Name: FUNCTION fdw_generate(p_name text, p_jurisdiction text, p_schemaname text, p_columns text[], p_addtxtype boolean, p_path text, p_delimiter text, p_header boolean); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.fdw_generate(p_name text, p_jurisdiction text, p_schemaname text, p_columns text[], p_addtxtype boolean, p_path text, p_delimiter text, p_header boolean) IS 'Generates a structure FOREIGN TABLE for ingestion.';


--
-- Name: fdw_generate_direct_csv(text, text, text, boolean, boolean); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.fdw_generate_direct_csv(p_file text, p_fdwname text, p_delimiter text DEFAULT ','::text, p_addtxtype boolean DEFAULT true, p_header boolean DEFAULT true) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
 fpath text;
 cols text[];
 sepcols text;
BEGIN
 sepcols := iIF(p_addtxtype, '" text,"'::text, '","'::text);
 cols := pg_csv_head(p_file, p_delimiter);
 EXECUTE
    format(
      'DROP FOREIGN TABLE IF EXISTS %s; CREATE FOREIGN TABLE %s    (%s%s%s)',
       p_fdwname, p_fdwname,   '"', array_to_string(cols,sepcols), iIF(p_addtxtype, '" text'::text, '"')
     ) || format(
       'SERVER files OPTIONS (filename %L, format %L, header %L, delimiter %L)',
       p_file, 'csv', p_header::text, p_delimiter
    );
 RETURN p_fdwname;
END;
$$;


ALTER FUNCTION optim.fdw_generate_direct_csv(p_file text, p_fdwname text, p_delimiter text, p_addtxtype boolean, p_header boolean) OWNER TO postgres;

--
-- Name: FUNCTION fdw_generate_direct_csv(p_file text, p_fdwname text, p_delimiter text, p_addtxtype boolean, p_header boolean); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.fdw_generate_direct_csv(p_file text, p_fdwname text, p_delimiter text, p_addtxtype boolean, p_header boolean) IS 'Generates a FOREIGN TABLE for simples and direct CSV ingestion.';


--
-- Name: fdw_generate_getclone(text, text, text, text[], text[], text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.fdw_generate_getclone(p_tablename text, p_jurisdiction text DEFAULT 'br'::text, p_schemaname text DEFAULT 'optim'::text, p_ignore text[] DEFAULT NULL::text[], p_add text[] DEFAULT NULL::text[], p_path text DEFAULT NULL::text) RETURNS text
    LANGUAGE sql
    AS $_$
  SELECT optim.fdw_generate(
    $1,$2,$3,
    pg_tablestruct_dump_totext(p_schemaname||'.'||p_tablename,p_ignore,p_add),
    false, -- p_addtxtype
    p_path
  )
$_$;


ALTER FUNCTION optim.fdw_generate_getclone(p_tablename text, p_jurisdiction text, p_schemaname text, p_ignore text[], p_add text[], p_path text) OWNER TO postgres;

--
-- Name: FUNCTION fdw_generate_getclone(p_tablename text, p_jurisdiction text, p_schemaname text, p_ignore text[], p_add text[], p_path text); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.fdw_generate_getclone(p_tablename text, p_jurisdiction text, p_schemaname text, p_ignore text[], p_add text[], p_path text) IS 'Generates a clone-structure FOREIGN TABLE for ingestion. Wrap for fdw_generate().';


--
-- Name: format_filepath(text, bigint, integer); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.format_filepath(scope text, donor_id bigint, pack_count integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN (
        SELECT '/var/gits/_dg/preserv-' ||
        CASE WHEN EXISTS (SELECT 1 FROM regexp_matches(scope,'^EC-EC-[A-Z]-.*$'))
        THEN regexp_replace(scope, '^([A-Z][A-Z])-([A-Z][A-Z]-[A-Z])-(.*)$', '\1/data/\2/\3')
        ELSE regexp_replace(replace(regexp_replace(scope, '^([^-]*)-?', '\1/data/'),'-','/'),'\/$','')
        END
         ||
        '/_pk' ||
        to_char(donor_id,'fm0000') ||
        '.' ||
        to_char(pack_count,'fm00') ||
        '/make_conf.yaml');
END;
$_$;


ALTER FUNCTION optim.format_filepath(scope text, donor_id bigint, pack_count integer) OWNER TO postgres;

--
-- Name: FUNCTION format_filepath(scope text, donor_id bigint, pack_count integer); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.format_filepath(scope text, donor_id bigint, pack_count integer) IS 'Generates filepath.';


--
-- Name: generate_commands(text, text, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.generate_commands(jurisd text, p_path_pack text, p_path text DEFAULT '/var/gits/_dg'::text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
    DECLARE
        q_query text;
        p_yaml jsonb;
        mkme_srcTpl text;
        output_file text;
    BEGIN

    SELECT yaml_to_jsonb(pg_read_file(p_path_pack ||'/make_conf.yaml' )) ||
           yamlfile_to_jsonb(p_path || '/preserv' || CASE WHEN jurisd ='INT' THEN '' ELSE '-' || upper(jurisd) END || '/src/maketemplates/commomFirst.yaml')
    INTO p_yaml;

    SELECT pg_read_file(p_path || '/preserv/src/maketemplates/reproducibility/make_' || lower(p_yaml->>'schemaId_template') || '.mustache.mk')
    INTO mkme_srcTpl;

    SELECT replace(jsonb_mustache_render(mkme_srcTpl, optim.jsonb_mustache_prepare(p_yaml),p_path ||'/preserv/src/maketemplates/reproducibility/'),E'\u130C9',$$\"$$)
    INTO q_query;

    RETURN q_query;

    END;
$_$;


ALTER FUNCTION optim.generate_commands(jurisd text, p_path_pack text, p_path text) OWNER TO postgres;

--
-- Name: generate_list(text, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.generate_list(p_fileref text, p_template text DEFAULT '/var/gits/_dg/preserv/src/list_jurisd.mustache'::text) RETURNS text
    LANGUAGE sql
    AS $$
    SELECT volat_file_write(p_fileref, jsonb_mustache_render(pg_read_file(p_template), y)) AS output_write
    FROM optim.vw02generate_list
    ;
$$;


ALTER FUNCTION optim.generate_list(p_fileref text, p_template text) OWNER TO postgres;

--
-- Name: FUNCTION generate_list(p_fileref text, p_template text); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.generate_list(p_fileref text, p_template text) IS 'Generate list page.';


--
-- Name: generate_list_hash(text, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.generate_list_hash(p_fileref text, p_template text DEFAULT '/var/gits/_dg/preserv/src/list_hash.mustache'::text) RETURNS text
    LANGUAGE sql
    AS $$
    SELECT volat_file_write(p_fileref, jsonb_mustache_render(pg_read_file(p_template), y)) AS output_write
    FROM optim.vw03generate_list_hash
    ;
$$;


ALTER FUNCTION optim.generate_list_hash(p_fileref text, p_template text) OWNER TO postgres;

--
-- Name: FUNCTION generate_list_hash(p_fileref text, p_template text); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.generate_list_hash(p_fileref text, p_template text) IS 'Generate list page.';


--
-- Name: generate_make_conf_with_license(text, text, text, text, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.generate_make_conf_with_license(jurisd text, pack_id text, p_output text, p_path_pack text, p_path text DEFAULT '/var/gits/_dg'::text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
    DECLARE
        q_query text;
        p_yaml jsonb;
        p_yaml_t text;
        license_evidences jsonb;
        definition jsonb;
        license_explicit boolean;
    BEGIN

    SELECT pg_read_file(p_path_pack ||'/make_conf.yaml') INTO p_yaml_t;
    SELECT yaml_to_jsonb(p_yaml_t) ||
           yamlfile_to_jsonb(p_path || '/preserv' || CASE WHEN jurisd ='INT' THEN '' ELSE '-' || upper(jurisd) END || '/src/maketemplates/commomFirst.yaml')
    INTO p_yaml;

    SELECT to_jsonb(ARRAY[name, family, url]), CASE WHEN lower(license_is_explicit)='yes' THEN TRUE ELSE FALSE END FROM license.pack_licenses WHERE license.pack_licenses.pack_id = (to_char(substring(p_yaml->>'pack_id','^([^\.]*)')::int,'fm000') || to_char(substring(p_yaml->>'pack_id','([^\.]*)$')::int,'fm00'))::int AND license.pack_licenses.jurisdiction = lower(jurisd) INTO definition, license_explicit;

    IF definition <> '[null,null,null]'::jsonb
    THEN
        IF p_yaml?'license_evidences' AND definition <> '[null,null,null]'::jsonb
        THEN
            license_evidences := p_yaml->'license_evidences' || jsonb_build_object('definition',null);

            SELECT regexp_replace( p_yaml_t , '\n*license_evidences: *(\n *[(definition)|(file)][^\n]*|\n[\t ]+[^\n]+)+\n*', E'\n\n' || regexp_replace(jsonb_to_yaml(jsonb_build_object('license_evidences',license_evidences)::text)::text,'definition: null\n', 'definition: ' || jsonb_to_yaml(definition::text,True)::text) || E'\n', 'n') INTO q_query;
        ELSE
            license_evidences := jsonb_build_object('definition',null);

            SELECT regexp_replace( p_yaml_t , '\n*files: *(\n *\-[^\n]*|\n[\t ]+[^\n]+)+\n*', E'\n\n' || jsonb_to_yaml((jsonb_build_object('files',(p_yaml->'files')))::text)::text || E'\n' || regexp_replace(jsonb_to_yaml(jsonb_build_object('license_evidences',license_evidences)::text)::text,'definition: null', 'definition: ' || jsonb_to_yaml(definition::text,True)::text) /*|| E'\n'*/, 'n') INTO q_query;
        END IF;

        SELECT volat_file_write(p_output,q_query) INTO q_query;
    ELSE
        q_query := 'Error, license not found. Check license value in donatedPack.csv.';
    END IF;

    RETURN q_query;
    END;
$_$;


ALTER FUNCTION optim.generate_make_conf_with_license(jurisd text, pack_id text, p_output text, p_path_pack text, p_path text) OWNER TO postgres;

--
-- Name: generate_make_conf_with_size(text, text, text, text, text, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.generate_make_conf_with_size(jurisd text, pack_id text, p_output text, p_path_pack text, p_path text DEFAULT '/var/gits/_dg'::text, p_orig text DEFAULT '/tmp'::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
    DECLARE
        q_query     text;
        conf_yaml   jsonb;
        conf_yaml_t text;
    BEGIN

    SELECT pg_read_file(p_path_pack ||'/make_conf.yaml') INTO conf_yaml_t;
    SELECT yaml_to_jsonb(conf_yaml_t) ||
           yamlfile_to_jsonb(p_path || '/preserv' || CASE WHEN jurisd ='INT' THEN '' ELSE '-' || upper(jurisd) END || '/src/maketemplates/commomFirst.yaml')
    INTO conf_yaml;

    --SELECT jsonb_to_yaml(optim.insert_bytesize(conf_yaml)::text) INTO q_query;
    SELECT regexp_replace( conf_yaml_t , '\n*files: *(\n *\-[^\n]*|\n[\t ]+[^\n]+)+\n*', E'\n\n' || jsonb_to_yaml((jsonb_build_object('files',optim.insert_bytesize(conf_yaml,p_orig)->'files'))::text) || E'\n', 'n') INTO q_query;

    SELECT volat_file_write(p_output,q_query) INTO q_query;

    RETURN q_query;
    END;
$$;


ALTER FUNCTION optim.generate_make_conf_with_size(jurisd text, pack_id text, p_output text, p_path_pack text, p_path text, p_orig text) OWNER TO postgres;

--
-- Name: generate_makefile(text, text, text, text, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.generate_makefile(jurisd text, pack_id text, p_output text, p_path_pack text, p_path text DEFAULT '/var/gits/_dg'::text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
    DECLARE
        q_query text;
        p_yaml jsonb;
        mkme_tpl text;
    BEGIN

    SELECT yaml_to_jsonb(pg_read_file(p_path_pack ||'/make_conf.yaml' )) ||
           yamlfile_to_jsonb(p_path || '/preserv' || CASE WHEN jurisd ='INT' THEN '' ELSE '-' || upper(jurisd) END || '/src/maketemplates/commomFirst.yaml')
    INTO p_yaml;

    SELECT pg_read_file(p_path || '/preserv/src/maketemplates/make_' || lower(p_yaml->>'schemaId_template') || '.mustache.mk') ||
           pg_read_file(p_path || '/preserv/src/maketemplates/commomLast.mustache.mk')
    INTO mkme_tpl;

    SELECT replace(jsonb_mustache_render(mkme_tpl, optim.jsonb_mustache_prepare(p_yaml)),E'\u130C9',$$\"$$) INTO q_query; -- "

    SELECT volat_file_write(p_output,q_query) INTO q_query;

    RETURN q_query;
    END;
$_$;


ALTER FUNCTION optim.generate_makefile(jurisd text, pack_id text, p_output text, p_path_pack text, p_path text) OWNER TO postgres;

--
-- Name: generate_readme(text, text, text, text, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.generate_readme(jurisd text, pack_id text, p_output text, p_path_pack text, p_path text DEFAULT '/var/gits/_dg'::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
    DECLARE
        q_query text;
        conf_yaml jsonb;
        p_yaml jsonb;
        readme text;
        reproducibility text;
    BEGIN

    SELECT optim.jsonb_mustache_prepare(
           yaml_to_jsonb(pg_read_file(p_path_pack ||'/make_conf.yaml' )) ||
           yamlfile_to_jsonb(p_path || '/preserv' || CASE WHEN jurisd ='INT' THEN '' ELSE '-' || upper(jurisd) END || '/src/maketemplates/commomFirst.yaml')
    ) INTO p_yaml;

    SELECT commands FROM optim.reproducibility WHERE packtpl_id= (p_yaml->>'packtpl_id')::bigint INTO reproducibility;

    SELECT p_yaml || jsonb_build_object('layers',list) || jsonb_build_object( 'reproducibility', to_jsonb(reproducibility) )
           || COALESCE( jsonb_build_object('viz_keys',to_jsonb(viz_keys)),'{}'::jsonb) || COALESCE( jsonb_build_object('publication_keys',to_jsonb(publication_keys)),'{}'::jsonb)
           || jsonb_build_object('has_publication_keys',(CASE WHEN publication_keys IS NOT NULL THEN true ELSE false END)) || jsonb_build_object('has_viz_keys',(CASE WHEN viz_keys IS NOT NULL THEN true ELSE false END))
    FROM
    (
      SELECT jsonb_agg(jsonb_build_object('value',value)) AS list, MAX(viz_keys) AS viz_keys, MAX(publication_keys) AS publication_keys
      FROM
      (
        SELECT t.value || jsonb_build_object('publication_data',COALESCE(u.l,'{}'::jsonb)) AS value, viz_keys, publication_keys
        FROM jsonb_each(p_yaml->'layers') t(key,value)
        LEFT JOIN
        (
          SELECT jsonb_array_elements(page->'layers') AS l, jsonb_array_to_text_array(page->'viz_keys') AS viz_keys, jsonb_array_to_text_array(page->'publication_keys') AS publication_keys
          FROM optim.vw03publication
          WHERE pack_number = ('_pk' || (p_yaml->'data_packtpl'->>'pack_number')::text) AND  isolabel_ext = p_yaml->'data_packtpl'->>'isolabel_ext'
        ) u
        ON u.l->'class_ftname' = t.value->'layername_root'
      ) g
    ) r
    INTO conf_yaml;

    RAISE NOTICE 'conf: %', conf_yaml;

    SELECT pg_read_file(p_path || '/preserv/src/maketemplates/readme_' || CASE WHEN jurisd ='BR' THEN 'ptbr' ELSE 'es' END || '.mustache') INTO readme;

    SELECT jsonb_mustache_render(readme, conf_yaml) ||
           (CASE WHEN file_exists(p_yaml->'data_packtpl'->>'path_preserv_server' ||'/attachment.md') THEN pg_read_file(p_yaml->'data_packtpl'->>'path_preserv_server' ||'/attachment.md') ELSE '' END)
    INTO q_query;

    SELECT volat_file_write(p_output,regexp_replace(q_query, '(\n\n\n)\n*', E'\n\n', 'g')) INTO q_query;

    RETURN q_query;
    END;
$$;


ALTER FUNCTION optim.generate_readme(jurisd text, pack_id text, p_output text, p_path_pack text, p_path text) OWNER TO postgres;

--
-- Name: generate_reproducibility(text, text, text, text, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.generate_reproducibility(jurisd text, pack_id text, p_output text, p_path_pack text, p_path text DEFAULT '/var/gits/_dg'::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
    DECLARE
        q_query text;
        p_yaml jsonb;
    BEGIN

    SELECT optim.jsonb_mustache_prepare(
           yaml_to_jsonb(pg_read_file(p_path_pack ||'/make_conf.yaml' )) ||
           yamlfile_to_jsonb(p_path || '/preserv' || CASE WHEN jurisd ='INT' THEN '' ELSE '-' || upper(jurisd) END || '/src/maketemplates/commomFirst.yaml')
    ) INTO p_yaml;

    SELECT commands FROM optim.reproducibility WHERE packtpl_id=(p_yaml->>'packtpl_id')::bigint INTO q_query;

    SELECT volat_file_write(p_output,q_query) INTO q_query;

    RETURN q_query;
    END;
$$;


ALTER FUNCTION optim.generate_reproducibility(jurisd text, pack_id text, p_output text, p_path_pack text, p_path text) OWNER TO postgres;

--
-- Name: generate_synonym_csv(text, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.generate_synonym_csv(p_isolabel_ext text, p_path text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    q_copy text;
BEGIN
  q_copy := $$
    COPY (
      SELECT *
      FROM optim.jurisdiction_abbrev_option
      WHERE isolabel_ext %s
      ORDER BY isolabel_ext, abbrev
    ) TO '%s' CSV HEADER
  $$;

  EXECUTE format(q_copy,'LIKE ''' || p_isolabel_ext || '%''',p_path);

  RETURN 'Ok.';
END
$_$;


ALTER FUNCTION optim.generate_synonym_csv(p_isolabel_ext text, p_path text) OWNER TO postgres;

--
-- Name: FUNCTION generate_synonym_csv(p_isolabel_ext text, p_path text); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.generate_synonym_csv(p_isolabel_ext text, p_path text) IS 'Generate csv with isolevel=3 coverage and overlay in separate array.';


--
-- Name: generate_synonym_ref_csv(text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.generate_synonym_ref_csv(p_path text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    q_copy text;
BEGIN
  q_copy := $$
    COPY (
      SELECT *
      FROM optim.jurisdiction_abbrev_ref
      ORDER BY abbrevref_id
    ) TO '%s' CSV HEADER
  $$;

  EXECUTE format(q_copy,p_path);

  RETURN 'Ok.';
END
$_$;


ALTER FUNCTION optim.generate_synonym_ref_csv(p_path text) OWNER TO postgres;

--
-- Name: FUNCTION generate_synonym_ref_csv(p_path text); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.generate_synonym_ref_csv(p_path text) IS 'Generate csv with isolevel=3 coverage and overlay in separate array.';


--
-- Name: input_donated_packfilevers(); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.input_donated_packfilevers() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  p_kx_pack_item_version int DEFAULT 0;
BEGIN
  p_kx_pack_item_version := (SELECT MAX(kx_pack_item_version)+1 FROM optim.donated_PackFileVers WHERE pack_id = NEW.pack_id AND pack_item = NEW.pack_item);
  NEW.kx_pack_item_version = CASE WHEN p_kx_pack_item_version IS NULL THEN 1 ELSE p_kx_pack_item_version END; 
  NEW.id = NEW.pack_id*1000 + NEW.pack_item*100 + NEW.kx_pack_item_version;
	RETURN NEW;
END;
$$;


ALTER FUNCTION optim.input_donated_packfilevers() OWNER TO postgres;

--
-- Name: input_donated_packtpl(); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.input_donated_packtpl() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.id = NEW.donor_id::bigint*100 + NEW.pk_count::bigint;
	RETURN NEW;
END;
$$;


ALTER FUNCTION optim.input_donated_packtpl() OWNER TO postgres;

--
-- Name: input_donor(); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.input_donor() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.kx_vat_id := optim.vat_id_normalize(NEW.vat_id);
  NEW.id = NEW.country_id*1000000 + NEW.local_serial;
	RETURN NEW;
END;
$$;


ALTER FUNCTION optim.input_donor() OWNER TO postgres;

--
-- Name: insert_bytesize(jsonb, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.insert_bytesize(dict jsonb, p_orig text DEFAULT '/tmp'::text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $_$
DECLARE
 a text;
 sz bigint;
BEGIN
    FOR i in 0..(select jsonb_array_length(dict->'files')-1)
    LOOP
        a := format($$ {files,%s,file} $$, i )::text[];

        SELECT size::bigint FROM pg_stat_file(concat(p_orig,'/',dict#>>a::text[])) INTO sz;

        a := format($$ {files,%s,size} $$, i );
        dict := jsonb_set( dict, a::text[],to_jsonb(sz));
    END LOOP;
 RETURN dict;
END;
$_$;


ALTER FUNCTION optim.insert_bytesize(dict jsonb, p_orig text) OWNER TO postgres;

--
-- Name: insert_cloudcontrol(bigint, smallint, text, text, text, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.insert_cloudcontrol(p_packvers_id bigint, p_ftid smallint, p_lineage_md5 text, p_hashedfname text, p_hashedfnameuri text, p_hashedfnametype text) RETURNS text
    LANGUAGE sql
    AS $$
    INSERT INTO optim.donated_PackComponent_cloudControl(packvers_id,ftid,lineage_md5,hashedfname,hashedfnameuri,hashedfnametype)
    VALUES (p_packvers_id,p_ftid,p_lineage_md5,p_hashedfname,p_hashedfnameuri,p_hashedfnametype)
    ON CONFLICT (packvers_id,ftid,lineage_md5,hashedfnametype)
    DO UPDATE SET hashedfname=EXCLUDED.hashedfname, hashedfnameuri=EXCLUDED.hashedfnameuri
    RETURNING 'Ok, updated table.'
  ;
$$;


ALTER FUNCTION optim.insert_cloudcontrol(p_packvers_id bigint, p_ftid smallint, p_lineage_md5 text, p_hashedfname text, p_hashedfnameuri text, p_hashedfnametype text) OWNER TO postgres;

--
-- Name: FUNCTION insert_cloudcontrol(p_packvers_id bigint, p_ftid smallint, p_lineage_md5 text, p_hashedfname text, p_hashedfnameuri text, p_hashedfnametype text); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.insert_cloudcontrol(p_packvers_id bigint, p_ftid smallint, p_lineage_md5 text, p_hashedfname text, p_hashedfnameuri text, p_hashedfnametype text) IS 'Update optim.donated_PackComponent_cloudControl.';


--
-- Name: insert_codec_type(); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.insert_codec_type() RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO optim.codec_type (extension,variant,descr_mime,descr_encode)
      SELECT lower(extension) AS extension, COALESCE(variant, '') AS variant, jsonb_object(regexp_split_to_array ('mime=' || descr_mime,'(;|=)')) AS descr_mime, jsonb_object(regexp_split_to_array ( descr_encode,'(;|=)')) AS descr_encode
      FROM tmp_orig.fdw_codec_type
    ON CONFLICT (extension,variant)
    DO UPDATE
    SET descr_mime=EXCLUDED.descr_mime, descr_encode=EXCLUDED.descr_encode
    ;

    UPDATE optim.codec_type
    SET descr_encode = jsonb_set(descr_encode, '{delimiter}', to_jsonb(str_urldecode(descr_encode->>'delimiter')), true)
    WHERE descr_encode->'delimiter' IS NOT NULL;

    RETURN 'Load codec_type from codec_type.csv.';
END;
$$;


ALTER FUNCTION optim.insert_codec_type() OWNER TO postgres;

--
-- Name: FUNCTION insert_codec_type(); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.insert_codec_type() IS 'Load codec_type.csv.';


--
-- Name: insert_donor_pack(text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.insert_donor_pack(jurisdiction text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
  q text;
  ret text;
  a text;
BEGIN
  q := $$
    -- popula optim.donor a partir de tmp_orig.fdw_donor
    INSERT INTO optim.donor (country_id, local_serial, scope_osm_id, scope_label, vat_id, legalname, wikidata_id, url, info)
    SELECT
        (
            SELECT jurisd_base_id
            FROM optim.jurisdiction
            WHERE lower(isolabel_ext) = lower(scope_label)
        ) AS country_id,
        t.local_id::int AS local_serial,
        (
            SELECT osm_id
            FROM optim.jurisdiction
            WHERE lower(isolabel_ext) = lower(scope_label)
        ) AS scope_osm_id,
        t.scope_label,
        t.vat_id,
        t."legalName" AS legalname,
        t.wikidata_id::bigint,
        t.url,
        to_jsonb(subq) AS info
    FROM tmp_orig.fdw_donor%s t, LATERAL (SELECT %s) subq
    WHERE t.scope_label IS NOT NULL
      AND t."legalName" IS NOT NULL
      AND lower(t.scope_label) <> 'na'
      AND lower(t."legalName") <> 'na'
      AND lower(t.wikidata_id) <> 'na'
    ON CONFLICT (country_id,local_serial)
    DO UPDATE 
    SET scope_osm_id=EXCLUDED.scope_osm_id, scope_label=EXCLUDED.scope_label, vat_id=EXCLUDED.vat_id, legalName=EXCLUDED.legalName, wikidata_id=EXCLUDED.wikidata_id, url=EXCLUDED.url, info=EXCLUDED.info;
  $$;

  EXECUTE format( $$ SELECT array_to_string((SELECT array_agg(x)
  FROM (SELECT split_part(unnest(pg_tablestruct_dump_totext('tmp_orig.fdw_donor%s')),' ',1) ) t(x)
  WHERE x NOT IN ('local_id','scope_label','vat_id','legalName','wikidata_id','url')),',')
  FROM tmp_orig.fdw_donor%s $$, jurisdiction, jurisdiction ) INTO a;

  EXECUTE format( q, jurisdiction, a ) ;

  q := $$
    -- popula optim.donated_PackTpl a partir de tmp_orig.fdw_donatedPack
    INSERT INTO optim.donated_PackTpl (donor_id, user_resp, pk_count, original_tpl, make_conf_tpl,info, license)
    SELECT (
        SELECT jurisd_base_id*1000000+donor_id
        FROM optim.jurisdiction
        WHERE lower(isolabel_ext) = lower(scope)
        ) AS donor_id, lower(user_resp) AS user_resp, pack_count, optim.replace_file_and_version(pg_read_file(optim.format_filepath(scope, donor_id, pack_count))) AS original_tpl, yamlfile_to_jsonb(optim.format_filepath(scope, donor_id, pack_count)) AS make_conf_tpl,
        to_jsonb(t) AS info,
        license
    FROM tmp_orig.fdw_donatedpack%s t
    WHERE file_exists(optim.format_filepath(scope, donor_id, pack_count)) -- verificar make_conf.yaml ausentes
          AND lst_vers=(select MAX(lst_vers) from tmp_orig.fdw_donatedpack%s where pack_id=t.pack_id )
    ON CONFLICT (donor_id,pk_count)
    DO UPDATE 
    SET original_tpl=EXCLUDED.original_tpl, make_conf_tpl=EXCLUDED.make_conf_tpl, kx_num_files=EXCLUDED.kx_num_files, info=EXCLUDED.info, license=EXCLUDED.license;
  $$;

  EXECUTE format( q, jurisdiction, jurisdiction) ;

  q := $$
    -- popula optim.donated_PackFileVers a partir de optim.donated_PackTpl
    INSERT INTO optim.donated_PackFileVers (hashedfname, pack_id, pack_item, pack_item_accepted_date, kx_pack_item_version, user_resp, info)
    SELECT j->>'file'::text AS hashedfname, t.pack_id , (j->>'p')::int AS pack_item, accepted_date::date AS pack_item_accepted_date, lst_vers, lower(t.user_resp::text) AS user_resp, jsonb_build_object('name', (j->>'name')) AS info
    FROM (
        SELECT pt.id AS pack_id, pt.user_resp, fpt.accepted_date, fpt.lst_vers, jsonb_array_elements((yamlfile_to_jsonb(optim.format_filepath(fpt.scope, fpt.donor_id, fpt.pack_count)))->'files')::jsonb AS j
        FROM optim.donated_packtpl pt
        LEFT JOIN optim.donor d
        ON pt.donor_id = d.id
        LEFT JOIN tmp_orig.fdw_donatedpack%s fpt
        ON d.local_serial = fpt.donor_id AND pt.pk_count = fpt.pack_count
        WHERE pt.donor_id IN (
                SELECT id FROM optim.donor
                WHERE country_id = (
                    SELECT jurisd_base_id
                    FROM optim.jurisdiction
                    WHERE lower(isolabel_ext) = lower(scope)
                    )
                )
            AND ((yamlfile_to_jsonb(optim.format_filepath(fpt.scope, fpt.donor_id, fpt.pack_count)))->'pkversion')::int = lst_vers
            AND file_exists(optim.format_filepath(fpt.scope, fpt.donor_id, fpt.pack_count))
        ) AS t 
    WHERE j->'file' IS NOT NULL -- verificar hash null
    ON CONFLICT (hashedfname)
    DO UPDATE 
    SET pack_id=EXCLUDED.pack_id, pack_item=EXCLUDED.pack_item, pack_item_accepted_date=EXCLUDED.pack_item_accepted_date, user_resp=EXCLUDED.user_resp, info=coalesce(EXCLUDED.info,'{}'::jsonb)||coalesce(optim.donated_PackFileVers.info,'{}'::jsonb);
  $$;
  
  EXECUTE format( q, jurisdiction ) ;

  RETURN (SELECT 'OK, inserted new itens at jurisdiction, donor and donatedPack. ');
END;
$_$;


ALTER FUNCTION optim.insert_donor_pack(jurisdiction text) OWNER TO postgres;

--
-- Name: insert_jurisdpoint(); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.insert_jurisdpoint() RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO optim.jurisdiction_geom_point (osm_id,jurisd_local_id,wikidata_id,geom)
      SELECT p.osm_id::bigint, local_id::int, split_part(wikidata,'Q',2)::bigint, geom
      FROM tmp_orig.jurisdPoints p
      WHERE osm_id IS NOT NULL
    ON CONFLICT (osm_id)
    DO UPDATE
    SET jurisd_local_id=EXCLUDED.jurisd_local_id, wikidata_id=EXCLUDED.wikidata_id, geom=EXCLUDED.geom
    ;
    RETURN 'Upsert jurisdPoint.csv in optim.jurisdiction_geom_point.';
END;
$$;


ALTER FUNCTION optim.insert_jurisdpoint() OWNER TO postgres;

--
-- Name: FUNCTION insert_jurisdpoint(); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.insert_jurisdpoint() IS 'Upsert jurisdPoint.csv.';


--
-- Name: jsonb_mustache_prepare(jsonb, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.jsonb_mustache_prepare(dict jsonb, p_type text DEFAULT 'make_conf'::text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $_$
DECLARE
 packvers_id bigint;
 key text;
 method text;
 sql_select text;
 sql_view text;
 bt jsonb := 'true'::jsonb;
 bf jsonb := 'false'::jsonb;
 codec_value text[];
 orig_filename_ext text[]; 
 orig_filename_string text;
 multiple_files jsonb; 
 codec_desc_global jsonb;
 housenumber_system text;

 codec_desc0 jsonb DEFAULT NULL;
 codec_desc_default0 jsonb DEFAULT NULL;
 codec_desc_sobre0 jsonb DEFAULT NULL;
 codec_extension0 text DEFAULT NULL;
 codec_descr_mime0 jsonb DEFAULT NULL;

 codec_desc jsonb;
 codec_desc_default jsonb;
 codec_desc_sobre jsonb;
 codec_extension text;
 codec_descr_mime jsonb;
BEGIN
 CASE p_type -- preparing types
 WHEN 'make_conf', NULL THEN

    IF dict?'codec:descr_encode'
    THEN
        codec_desc_global := jsonb_object(regexp_split_to_array ( dict->>'codec:descr_encode','(;|=)'));

        -- Compatibilidade com sql_view de BR-MG-BeloHorizonte/_pk0008.01
        dict := dict || codec_desc_global;

        RAISE NOTICE 'codec_desc_global : %', codec_desc_global;
    END IF;

    IF dict?'srid_proj'
    THEN
        codec_desc_global := jsonb_build_object('srid', (SELECT 952022 + floor(random()*100)));

        -- Compatibilidade com srid_proj de BR-RS-PortoAlegre/_pk0018.01
        dict := dict || codec_desc_global;

        RAISE NOTICE 'codec_desc_global : %', codec_desc_global;
    END IF;

    IF dict?'openstreetmap'
    THEN
        IF codec_desc_global IS NOT NULL
        THEN
            dict := jsonb_set( dict, array['openstreetmap','file_data'] , to_jsonb(jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.openstreetmap.file)')::jsonpath  )->0->>'file'));
            
            dict := jsonb_set( dict, array['openstreetmap'], (dict->>'openstreetmap')::jsonb || codec_desc_global::jsonb );
        END IF;
    END IF;

    IF dict?'to-do'
    THEN
        dict := jsonb_set( dict, array['has_to-do'], bt);
    END IF;

    IF dict?'license_evidences'
    THEN
      IF dict->'license_evidences'?'file'
      THEN
          dict := jsonb_set( dict, array['license_evidences','file_7'], to_jsonb( substring(dict->'license_evidences'->>'file', '^([0-9a-f]{7}).+$') ) );
          dict := jsonb_set( dict, array['license_evidences','file_7_ext'], to_jsonb( substring(dict->'license_evidences'->>'file', '^([0-9a-f]{7}).+$') || '...' || substring(dict->'license_evidences'->>'file', '^.+\.([a-z0-9]+)$') ) );
      END IF;

      IF dict->'license_evidences'?'uri_evidency'
      THEN
        IF EXISTS (SELECT 1 FROM regexp_matches(dict->'license_evidences'->>'uri_evidency','^.+\.eml$'))
        THEN
          dict := jsonb_set( dict, array['license_evidences','is_uri_evidency_eml'], bt );
          dict := jsonb_set( dict, array['license_evidences','uri_evidency_7'], to_jsonb( substring(dict->'license_evidences'->>'uri_evidency', '^([0-9a-f]{7}).+$') ) );
          dict := jsonb_set( dict, array['license_evidences','uri_evidency_7_ext'], to_jsonb( substring(dict->'license_evidences'->>'uri_evidency', '^([0-9a-f]{7}).+$') || '...' || substring(dict->'license_evidences'->>'uri_evidency', '^.+\.([a-z0-9]+)$') ) );
        ELSE
          dict := jsonb_set( dict, array['license_evidences','is_uri_evidency_eml'], bf );
        END IF;
      END IF;
    END IF;

    FOREACH key IN ARRAY jsonb_object_keys_asarray(dict->'layers')
    LOOP
        method := dict->'layers'->key->>'method';
        
        RAISE NOTICE 'layer : %, method: %', key, method;

        -- id_profile_params default values
        IF NOT dict->'layers'->key?'id_profile_params'
        THEN
            CASE key
            WHEN 'geoaddress'  THEN dict := jsonb_set( dict, array['layers',key,'id_profile_params'], to_jsonb(1));
            WHEN 'via'         THEN dict := jsonb_set( dict, array['layers',key,'id_profile_params'], to_jsonb(5));
            ELSE
                dict := jsonb_set( dict, array['layers',key,'id_profile_params'], to_jsonb(5));
            END CASE;
        END IF;

        -- buffer_type default: 1 small buffer (50 m). 0 no buffer, 2 big buffer (500 m).
        IF NOT dict->'layers'->key?'buffer_type'
        THEN
            dict := jsonb_set( dict, array['layers',key,'buffer_type'], to_jsonb(1));
        END IF;

        codec_desc := codec_desc0;
        codec_desc_default := codec_desc_default0;
        codec_desc_sobre := codec_desc_sobre0;
        codec_extension := codec_extension0;
        codec_descr_mime := codec_descr_mime0;

        dict := jsonb_set( dict, array['layers',key,'isCsv'],        IIF(method='csv2sql',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isOgr'],        IIF(method='ogr2ogr',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isOgrWithShp'], IIF(method='ogrWshp',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isShp'],        IIF(method='shp2sql',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isOsm'],        IIF(method='osm2sql',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isGdb'],        IIF(method='gdb2sql',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isGeojson'],    IIF(method='geojson2sql',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isTxt2sql'],    IIF(method='txt2sql',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isGeoaddress'], IIF(key='geoaddress',bt,bf) );

        dict := jsonb_set( dict, array['layers',key,'isShpParalell'],IIF(method='shp2sqlparalell',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'multiple_files'],IIF(method='shp2sqlparalell',bt,bf) );

        IF dict->'layers'->key?'standardized_fields'
        THEN
            dict := jsonb_set( dict, array['layers',key,'has_standardized_fields'], bt);
        END IF;

        IF dict->'layers'->key?'other_fields'
        THEN
            dict := jsonb_set( dict, array['layers',key,'has_other_fields'], bt);
        END IF;

        dict := jsonb_set( dict, array['layers',key,'file_data'] , to_jsonb(jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.'|| key ||'.file)')::jsonpath  )->0));

        IF dict->'layers'->key->'file_data'?'size'
        THEN
            dict := jsonb_set( dict, array['layers',key,'file_data','size_mb_round2'], to_jsonb(ROUND(((dict->'layers'->key->'file_data'->'size')::bigint / 1048576.0),0.01)));
            dict := jsonb_set( dict, array['layers',key,'file_data','size_mb_round4'], to_jsonb(ROUND(((dict->'layers'->key->'file_data'->'size')::bigint / 1048576.0),0.0001)));
        END IF;
        
        IF dict?'orig'
        THEN
            dict := jsonb_set( dict, array['layers',key,'file_data','path'] , to_jsonb((dict->>'orig') || '/' || (dict->'layers'->key->'file_data'->>'file') ));
        END IF;

        SELECT id, housenumber_system_type FROM optim.vw01full_packfilevers WHERE hashedfname = dict->'layers'->key->'file_data'->>'file' INTO packvers_id, housenumber_system;

        dict := jsonb_set( dict, array['layers',key,'packvers_id'] , to_jsonb(packvers_id));
        dict := jsonb_set( dict, array['layers',key,'layername_root'] , to_jsonb(key));
        dict := jsonb_set( dict, array['layers',key,'layername'] , to_jsonb(key || '_' || (dict->'layers'->key->>'subtype') ));
        dict := jsonb_set( dict, array['layers',key,'tabname'] , to_jsonb('pk' || packvers_id || '_p' || (dict->'layers'->key->>'file') || '_' || key));
        dict := jsonb_set( dict, array['layers',key,'isolabel_ext'] , to_jsonb((SELECT isolabel_ext FROM optim.vw01full_packfilevers WHERE id=packvers_id)));
        dict := jsonb_set( dict, array['layers',key,'path_cutgeo_server'] , to_jsonb((SELECT path_cutgeo_server || '/' || key FROM optim.vw01full_packfilevers WHERE id=packvers_id)));
        dict := jsonb_set( dict, array['layers',key,'path_cutgeo_git'] , to_jsonb((SELECT path_cutgeo_git || '/' || key FROM optim.vw01full_packfilevers WHERE id=packvers_id)));

        dict := jsonb_set( dict, array['packtpl_id'] , to_jsonb((SELECT packtpl_id FROM optim.vw01full_packfilevers WHERE id=packvers_id)));

        -- dict := jsonb_set( dict, array['layers',key,'full_name_layer'] , to_jsonb((SELECT full_name_layer FROM optim.vw01full_packfilevers_ftype WHERE id=packvers_id AND ftid=(SELECT ftid::int FROM optim.feature_type WHERE ftname=lower(key)) )));

        -- Caso de BR-PR-Araucaria/_pk0061.01
        IF jsonb_typeof(dict->'layers'->key->'orig_filename') = 'array'
        THEN
            SELECT to_jsonb(array_agg(jsonb_build_object(
                    'name_item',n,
                    'sql_select_item',s,
                    'orig_filename_array_first',(to_jsonb(((dict->'layers'->key->'orig_filename'))->0)),
                    'isFirst', iif(row_num=1,'true'::jsonb,'false'::jsonb))))
            FROM (
                SELECT row_number() OVER () AS row_num, t.*
                FROM  unnest(ARRAY(SELECT jsonb_array_elements_text(dict->'layers'->key->'orig_filename')),ARRAY(SELECT jsonb_array_elements(dict->'layers'->key->'sql_select'))) t(n,s)
            ) r
            INTO multiple_files;

            RAISE NOTICE 'multiple_files_array : %', multiple_files;
            dict := jsonb_set( dict, array['layers',key,'multiple_files'], 'true'::jsonb );
            dict := jsonb_set( dict, array['layers',key,'multiple_files_array'], multiple_files );

            SELECT string_agg($$'*$$ || trim(txt::text, $$"$$) || $$*'$$, ' ') FROM jsonb_array_elements(dict->'layers'->key->'orig_filename') AS txt INTO orig_filename_string;
            dict := jsonb_set( dict, array['layers',key,'orig_filename_string_extract'], to_jsonb(orig_filename_string) );

            dict := jsonb_set( dict, array['layers',key,'orig_filename_array_first'], (to_jsonb(((dict->'layers'->key->'orig_filename'))->0)) );

            SELECT $$\( $$ || string_agg($$-iname '*$$ || trim(txt::text, $$"$$) || $$*.shp'$$, ' -o ') || $$ \)$$ FROM jsonb_array_elements(dict->'layers'->key->'orig_filename') AS txt INTO orig_filename_string;
            dict := jsonb_set( dict, array['layers',key,'orig_filename_string_find'], to_jsonb(orig_filename_string) );
        END IF;

        IF dict->'layers'->key?'sql_select'
        THEN
            sql_select :=  replace(dict->'layers'->key->>'sql_select',$$\"$$,E'\u130C9');
            dict := jsonb_set( dict, array['layers',key,'sql_select'], sql_select::jsonb );
        END IF;

        IF dict->'layers'->key?'sql_view'
        THEN
            sql_view := replace(dict->'layers'->key->>'sql_view',$$"$$,E'\u130C9');
            dict := jsonb_set( dict, array['layers',key,'sql_view'], to_jsonb(sql_view) );
        END IF;

        -- obtem codec a partir da extensão do arquivo
        IF jsonb_typeof(dict->'layers'->key->'orig_filename') <> 'array'
        THEN
            orig_filename_ext := regexp_matches(dict->'layers'->key->>'orig_filename','\.(\w+)$');
            
            IF orig_filename_ext IS NOT NULL
            THEN
                SELECT extension, descr_mime, descr_encode FROM optim.codec_type WHERE (array[extension] = orig_filename_ext) INTO codec_extension, codec_descr_mime, codec_desc_default;
                dict := jsonb_set( dict, array['layers',key,'orig_filename_with_extension'], 'true'::jsonb );
                RAISE NOTICE 'orig_filename_ext : %', orig_filename_ext;
                RAISE NOTICE 'codec_desc_default from extension: %', codec_desc_default;
            END IF;
        END IF;

        IF dict->'layers'->key?'codec'
        THEN
            -- 1. Extensão, variação e sobrescrição. Descarta a variação.
            IF EXISTS (SELECT 1 FROM regexp_matches(dict->'layers'->key->>'codec','^(.*)~(.*);(.*)$'))
            THEN
                    SELECT extension, descr_mime, descr_encode FROM optim.codec_type WHERE (extension = lower(split_part(dict->'layers'->key->>'codec', '~', 1)) AND variant = '') INTO codec_extension, codec_descr_mime, codec_desc_default;

                codec_desc_sobre := jsonb_object(regexp_split_to_array (split_part(regexp_replace(dict->'layers'->key->>'codec', ';','~'),'~',3),'(;|=)'));

                RAISE NOTICE '1. codec_desc_default : %', codec_desc_default;
                RAISE NOTICE '1. codec_desc_sobre : %', codec_desc_sobre;
            END IF;

            -- 2. Extensão e sobrescrição, sem variação
            IF EXISTS (SELECT 1 FROM regexp_matches(dict->'layers'->key->>'codec','^([^;~]*);(.*)$'))
            THEN
                SELECT extension, descr_mime, descr_encode FROM optim.codec_type WHERE (extension = lower(split_part(dict->'layers'->key->>'codec', ';', 1)) AND variant = '') INTO codec_extension, codec_descr_mime, codec_desc_default;

                codec_desc_sobre := jsonb_object(regexp_split_to_array (split_part(regexp_replace(dict->'layers'->key->>'codec', ';','~'),'~',2),'(;|=)'));

                RAISE NOTICE '2. codec_desc_default : %', codec_desc_default;
                RAISE NOTICE '2. codec_desc_sobre : %', codec_desc_sobre;
            END IF;

            -- 3. Extensão e variação ou apenas extensão, sem sobrescrição
            IF EXISTS (SELECT 1 FROM regexp_matches(dict->'layers'->key->>'codec','^(.*)~([^;]*)$')) OR EXISTS (SELECT 1 FROM regexp_matches(dict->'layers'->key->>'codec','^([^~;]*)$'))
            THEN
                codec_value := regexp_split_to_array( dict->'layers'->key->>'codec' ,'(~)');

                SELECT extension, descr_mime, descr_encode FROM optim.codec_type WHERE (array[upper(extension), variant] = codec_value AND cardinality(codec_value) = 2) OR (array[upper(extension)] = codec_value AND cardinality(codec_value) = 1 AND variant = '') INTO codec_extension, codec_descr_mime, codec_desc_default;

                RAISE NOTICE '3. codec_desc_default : %', codec_desc_default;
            END IF;

            dict := jsonb_set( dict, array['layers',key,'isXlsx'], IIF(lower(codec_extension) = 'xlsx',bt,bf) );
        END IF;

        -- codec resultante
        -- global sobrescreve default e é sobrescrito por sobre
        IF codec_desc_default IS NOT NULL
        THEN
            codec_desc := codec_desc_default;

            IF codec_desc_global IS NOT NULL
            THEN
                codec_desc := codec_desc || codec_desc_global;

                IF codec_desc_global?'srid'
                THEN
                    dict := jsonb_set( dict, array['layers',key,'insertSrid'], 'true'::jsonb );
                END IF;

            END IF;

            IF codec_desc_sobre IS NOT NULL
            THEN
                codec_desc := codec_desc || codec_desc_sobre;

                IF codec_desc_sobre?'srid'
                THEN
                    dict := jsonb_set( dict, array['layers',key,'insertSrid'], 'false'::jsonb );
                END IF;

            END IF;
        ELSE
            IF codec_desc_global IS NOT NULL
            THEN
                codec_desc := codec_desc_global;

                IF codec_desc_global?'srid'
                THEN
                    dict := jsonb_set( dict, array['layers',key,'insertSrid'], 'true'::jsonb );
                END IF;

            END IF;

            IF codec_desc_sobre IS NOT NULL
            THEN
                codec_desc := codec_desc || codec_desc_sobre;

                IF codec_desc_sobre?'srid'
                THEN
                    dict := jsonb_set( dict, array['layers',key,'insertSrid'], 'false'::jsonb );
                END IF;

            END IF;
        END IF;

        IF codec_desc IS NOT NULL
        THEN
            dict := jsonb_set( dict, array['layers',key], (dict->'layers'->>key)::jsonb || codec_desc::jsonb );
            
            RAISE NOTICE 'codec resultante : %', codec_desc;
        END IF;

        IF codec_desc IS NOT NULL AND codec_desc?'charset' AND lower(codec_desc->>'charset') IN ('utf-8')
        THEN
            dict := jsonb_set( dict, array['layers',key,'isUtf8'], 'true'::jsonb );
        END IF;

        IF codec_extension IS NOT NULL
        THEN
            dict := jsonb_set( dict, array['layers',key,'extension'], to_jsonb(codec_extension) );
            RAISE NOTICE 'codec_extension : %', codec_extension;
        ELSE
            CASE method
            WHEN 'csv2sql'  THEN dict := jsonb_set( dict, array['layers',key,'extension'], to_jsonb('csv'::text) );
            WHEN 'shp2sql'  THEN dict := jsonb_set( dict, array['layers',key,'extension'], to_jsonb('shp'::text) );
            WHEN 'shp2sqlparalell'  THEN dict := jsonb_set( dict, array['layers',key,'extension'], to_jsonb('shp'::text) );
            WHEN 'geojson2sql'  THEN dict := jsonb_set( dict, array['layers',key,'extension'], to_jsonb('geojson'::text) );
            WHEN 'txt2sql'  THEN dict := jsonb_set( dict, array['layers',key,'extension'], to_jsonb('txt'::text) );
            ELSE
                --  do nothing
            END CASE;
            
            RAISE NOTICE 'codec_extension from method: %', dict->'layers'->key->'extension';
        END IF;
                
        IF codec_descr_mime IS NOT NULL
        THEN
            dict := jsonb_set( dict, array['layers',key], (dict->'layers'->>key)::jsonb || codec_descr_mime::jsonb );
        END IF;

        IF codec_descr_mime?'mime' AND codec_descr_mime->>'mime' = 'application/zip' OR codec_descr_mime->>'mime' = 'application/gzip'
        THEN
            dict := jsonb_set( dict, array['layers',key,'multiple_files'], 'true'::jsonb );
            dict := jsonb_set( dict, array['layers',key,'extension'], to_jsonb((regexp_matches(codec_extension,'(.*)\.\w+$'))[1]) );
        END IF;

        IF key='address' OR key='cadparcel' OR key='cadvia'
        THEN
            dict := jsonb_set( dict, array['layers',key,'isCadLayer'], 'true'::jsonb );
        END IF;

        IF dict->'layers'?key AND dict->'layers'?('cad'||key)
            AND dict->'layers'->key->>'subtype' = 'ext'
            AND dict->'layers'->('cad'||key)->>'subtype' = 'cmpl'
            AND dict->'layers'->key?'join_id' AND dict->'layers'->('cad'||key)?'join_id'
        THEN
            dict := jsonb_set( dict, '{joins}', '{}'::jsonb );
            dict := jsonb_set( dict, array['joins',key] , jsonb_build_object(
                'layer',           key || '_ext'
                ,'cadLayer',        'cad' || key || '_cmpl'
                ,'layerColumn',     dict->'layers'->key->'join_id'
                ,'cadLayerColumn',  dict->'layers'->('cad'||key)->'join_id'
                ,'layerFile',       jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.'|| key ||'.file)')::jsonpath  )->0->>'file'
                ,'cadLayerFile',    jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.cad'|| key ||'.file)')::jsonpath  )->0->>'file'
                -- check by dict @? ('$.files[*].p ? (@ == $.layers.'|| key ||'.file)')
            ));
            dict := jsonb_set( dict, array['layers',key,'join_data'] , jsonb_build_object(
                'cadLayer',        'cad' || key
                ,'cadLayerColumn',  dict->'layers'->('cad'||key)->'join_id'
                ,'cadLayerFile',    jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.cad'|| key ||'.file)')::jsonpath  )->0->>'file'
            ));
            dict := jsonb_set( dict, array['layers','cad'||key,'join_data'] , jsonb_build_object(
                'cadLayer',         key
                ,'cadLayerColumn',  dict->'layers'->key->'join_id'
                ,'cadLayerFile',    jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.'|| key ||'.file)')::jsonpath  )->0->>'file'
            ));
        END IF;

        IF key='geoaddress' AND dict->'layers'?'address'
            AND dict->'layers'->key->>'subtype' = 'ext'
            AND dict->'layers'->'address'->>'subtype' = 'cmpl'
        AND dict->'layers'->key?'join_id'
            AND dict->'layers'->'address'?'join_id'
        THEN
            dict := jsonb_set( dict, '{joins}', '{}'::jsonb );
            dict := jsonb_set( dict, array['joins',key] , jsonb_build_object(
                'layer',           key || '_ext'
                ,'cadLayer',        'address_cmpl'
                ,'layerColumn',     dict->'layers'->key->'join_id'
                ,'cadLayerColumn',  dict->'layers'->'address'->'join_id'
                ,'layerFile',       jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.'|| key ||'.file)')::jsonpath  )->0->>'file'
                ,'cadLayerFile',    jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.address.file)')::jsonpath  )->0->>'file'
            ));
            dict := jsonb_set( dict, array['layers',key,'join_data'] , jsonb_build_object(
                'cadLayer',        'address'
                ,'cadLayerColumn',  dict->'layers'->('address')->'join_id'
                ,'cadLayerFile',    jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.address.file)')::jsonpath  )->0->>'file'
            ));
            dict := jsonb_set( dict, array['layers','address','join_data'] , jsonb_build_object(
                'cadLayer',         key
                ,'cadLayerColumn',  dict->'layers'->key->'join_id'
                ,'cadLayerFile',    jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.'|| key ||'.file)')::jsonpath  )->0->>'file'
            ));
        END IF;
	 END LOOP;

    IF housenumber_system IS NOT NULL
    THEN
        dict := jsonb_set( dict, array['housenumber_system_type'], to_jsonb(housenumber_system) );
    END IF;

	 IF jsonb_array_length(to_jsonb(jsonb_object_keys_asarray(dict->'joins'))) > 0
	 THEN
        dict := dict || jsonb_build_object( 'joins_keys', jsonb_object_keys_asarray(dict->'joins') );
	 END IF;

	 dict := dict || jsonb_build_object( 'layers_keys', jsonb_object_keys_asarray(dict->'layers') );
	 dict := dict || jsonb_build_object( 'layers_keys_nocad', ( SELECT  array_agg(x) FROM jsonb_object_keys(dict->'layers') t(x) WHERE x NOT IN ('address','cadvia','cadparcel','cadgenericvia') ) );
	 dict := jsonb_set( dict, array['pkversion'], to_jsonb(to_char((dict->>'pkversion')::int,'fm000')) );
	 dict := jsonb_set( dict, '{files,-1,last}','true'::jsonb);

	 dict := jsonb_set( dict, array['data_packtpl'] , to_jsonb((SELECT (jsonb_agg(t))[0] FROM (SELECT * FROM optim.vw01full_donated_PackTpl WHERE packtpl_id=((dict->>'packtpl_id')::bigint)) t)));
 -- CASE ELSE ...?
 END CASE;
 RETURN dict;
END;
$_$;


ALTER FUNCTION optim.jsonb_mustache_prepare(dict jsonb, p_type text) OWNER TO postgres;

--
-- Name: jurisdiction_to_geojson(text, text, integer); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.jurisdiction_to_geojson(p_isolabel_ext text, p_fileref text, p_pretty_opt integer DEFAULT 3) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    PERFORM write_geojsonb_features(
      format('SELECT * FROM optim.vw01full_jurisdiction_geom WHERE isolabel_ext = ''%s''',p_isolabel_ext),
      format('%s/%s_jurisd.geojson',p_fileref,lower(replace(p_isolabel_ext,'-','_'))),
      't1.geom',
      'osm_id,jurisd_base_id,jurisd_local_id,parent_id,admin_level,name,parent_abbrev,abbrev,wikidata_id,lexlabel,isolabel_ext,ddd,housenumber_system_type,lex_urn,info,name_en,isolevel,ne_country_id,int_country_id',
      NULL,NULL,$3,5);

    RETURN (SELECT 'Publicado em ' || p_fileref::text)
  ;
END
$_$;


ALTER FUNCTION optim.jurisdiction_to_geojson(p_isolabel_ext text, p_fileref text, p_pretty_opt integer) OWNER TO postgres;

--
-- Name: load_codec_type(); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.load_codec_type() RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN (SELECT optim.fdw_generate_direct_csv('/var/gits/_dg/preserv/data/codec_type.csv','tmp_orig.fdw_codec_type',','));
END;
$$;


ALTER FUNCTION optim.load_codec_type() OWNER TO postgres;

--
-- Name: FUNCTION load_codec_type(); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.load_codec_type() IS 'Generates a clone-structure FOREIGN TABLE for codec_type.csv.';


--
-- Name: load_donor_pack(text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.load_donor_pack(jurisdiction text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN (SELECT optim.fdw_generate_direct_csv(concat('/var/gits/_dg/preserv', iIF(jurisdiction='INT', '', '-' || UPPER(jurisdiction)), '/data/donor.csv'),'tmp_orig.fdw_donor'|| lower(jurisdiction),',')) || (SELECT optim.fdw_generate('donatedPack', jurisdiction, 'optim', array['pack_id int', 'donor_id int', 'pack_count int', 'lst_vers int', 'user_resp text', 'accepted_date date', 'scope text', 'about text', 'author text', 'contentReferenceTime text', 'license_is_explicit text', 'license text', 'uri_objType text', 'uri text', 'isAt_UrbiGIS text','status text','statusUpdateDate text'],false,null));
END;
$$;


ALTER FUNCTION optim.load_donor_pack(jurisdiction text) OWNER TO postgres;

--
-- Name: FUNCTION load_donor_pack(jurisdiction text); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.load_donor_pack(jurisdiction text) IS 'Insert from clone-structure FOREIGN TABLE from donor.csv and donatedPack.csv.';


--
-- Name: mkdonated_packtpl(); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.mkdonated_packtpl() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.kx_num_files = jsonb_array_length(NEW.make_conf_tpl->'files');
	RETURN NEW;
END;
$$;


ALTER FUNCTION optim.mkdonated_packtpl() OWNER TO postgres;

--
-- Name: publicating_index_page(text, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.publicating_index_page(p_fileref text, p_template text DEFAULT '/var/gits/_dg/preservDataViz/src/preservCutGeo/index_page.mustache'::text) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT volat_file_write(($1 || '/' || 'index.html'), jsonb_mustache_render(pg_read_file(p_template), y)) AS output_write
    FROM optim.vw01publicating_index
    ;
$_$;


ALTER FUNCTION optim.publicating_index_page(p_fileref text, p_template text) OWNER TO postgres;

--
-- Name: FUNCTION publicating_index_page(p_fileref text, p_template text); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.publicating_index_page(p_fileref text, p_template text) IS 'Generate index in markdown file for preservDataViz pages.';


--
-- Name: publicating_index_pagemd(text, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.publicating_index_pagemd(p_fileref text, p_template text DEFAULT '/var/gits/_dg/preservDataViz/src/preservCutGeo/index_page_markdown.mustache'::text) RETURNS text
    LANGUAGE sql
    AS $$
    SELECT volat_file_write(p_fileref, jsonb_mustache_render(pg_read_file(p_template), y)) AS output_write
    FROM optim.vw01publicating_index
    ;
$$;


ALTER FUNCTION optim.publicating_index_pagemd(p_fileref text, p_template text) OWNER TO postgres;

--
-- Name: publicating_page(text, text, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.publicating_page(p_isolabel_ext text, p_pack_number text, p_fileref text) RETURNS text
    LANGUAGE sql
    AS $$
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
$$;


ALTER FUNCTION optim.publicating_page(p_isolabel_ext text, p_pack_number text, p_fileref text) OWNER TO postgres;

--
-- Name: FUNCTION publicating_page(p_isolabel_ext text, p_pack_number text, p_fileref text); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.publicating_page(p_isolabel_ext text, p_pack_number text, p_fileref text) IS 'Generate html file for preservDataViz pages.';


--
-- Name: replace_file_and_version(text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.replace_file_and_version(file text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN (SELECT regexp_replace(regexp_replace( file , '(p: *([0-9]{1,})\n *)file: *[0-9a-f]{64,64}\.[a-z0-9]+ *$', '\1file: {{file\2}}','ng'),'(pkversion:) *[0-9]{1,}','\1 {{version}}'));
END;
$_$;


ALTER FUNCTION optim.replace_file_and_version(file text) OWNER TO postgres;

--
-- Name: FUNCTION replace_file_and_version(file text); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.replace_file_and_version(file text) IS 'Replacing "version" and "file" with mustache placeholder.';


--
-- Name: update_pub_id_cloudcontrol(bigint, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.update_pub_id_cloudcontrol(p_id bigint, p_info text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE optim.donated_PackComponent_cloudControl c
  SET info = coalesce(info,'{}'::jsonb) || jsonb_build_object('pub_id', p_info)
  WHERE c.id= p_id
  ;
  RETURN 'Ok, update info of optim.donated_PackComponent_cloudControl.';
END;
$$;


ALTER FUNCTION optim.update_pub_id_cloudcontrol(p_id bigint, p_info text) OWNER TO postgres;

--
-- Name: FUNCTION update_pub_id_cloudcontrol(p_id bigint, p_info text); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.update_pub_id_cloudcontrol(p_id bigint, p_info text) IS 'Update info of optim.donated_PackComponent_cloudControl';


--
-- Name: update_shp_id_cloudcontrol(bigint, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.update_shp_id_cloudcontrol(p_id bigint, p_info text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE optim.donated_PackComponent_cloudControl c
  SET info = coalesce(info,'{}'::jsonb) || jsonb_build_object('shp_id', p_info)
  WHERE c.id= p_id
  ;
  RETURN 'Ok, update info of optim.donated_PackComponent_cloudControl.';
END;
$$;


ALTER FUNCTION optim.update_shp_id_cloudcontrol(p_id bigint, p_info text) OWNER TO postgres;

--
-- Name: FUNCTION update_shp_id_cloudcontrol(p_id bigint, p_info text); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.update_shp_id_cloudcontrol(p_id bigint, p_info text) IS 'Update info of optim.donated_PackComponent_cloudControl';


--
-- Name: update_view_id_cloudcontrol(bigint, text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.update_view_id_cloudcontrol(p_id bigint, p_info text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE optim.donated_PackComponent_cloudControl c
  SET info = coalesce(info,'{}'::jsonb) || jsonb_build_object('view_id', p_info)
  WHERE c.id= p_id
  ;
  RETURN 'Ok, update info of optim.donated_PackComponent_cloudControl.';
END;
$$;


ALTER FUNCTION optim.update_view_id_cloudcontrol(p_id bigint, p_info text) OWNER TO postgres;

--
-- Name: FUNCTION update_view_id_cloudcontrol(p_id bigint, p_info text); Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON FUNCTION optim.update_view_id_cloudcontrol(p_id bigint, p_info text) IS 'Update info of optim.donated_PackComponent_cloudControl';


--
-- Name: vat_id_normalize(text); Type: FUNCTION; Schema: optim; Owner: postgres
--

CREATE FUNCTION optim.vat_id_normalize(p_vat_id text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT lower(regexp_replace($1,'[,\.;/\-\+\*~]+','','g'))
$_$;


ALTER FUNCTION optim.vat_id_normalize(p_vat_id text) OWNER TO postgres;

--
-- Name: br_afacode_decode(text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.br_afacode_decode(p_code text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT
    jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
      'type','Feature',
      'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
      'id',v.id,
      'jurisd_base_id',76,
      'properties',jsonb_build_object(
          'area',l.area,
          'side',l.side,
          'truncated',(CASE WHEN length(v.id) - length(code) <> 3 THEN TRUE ELSE FALSE END)))))::jsonb
  FROM regexp_split_to_table(p_code,',') code,
  LATERAL (SELECT afa.br_hex_to_hBig(substring(code,1,11))) m(hbig),
  LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.br_decode(hbig), afa.br_hBig_to_xyLRef(hbig)) v(id,geom,xyL),
  LATERAL (SELECT afa.br_cell_area(xyL[3]), afa.br_cell_side(xyL[3])) l(area,side)
$$;


ALTER FUNCTION osmc.br_afacode_decode(p_code text) OWNER TO postgres;

--
-- Name: FUNCTION br_afacode_decode(p_code text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.br_afacode_decode(p_code text) IS 'Decodes a scientific AFAcode for Brazil.';


--
-- Name: br_afacode_decode_log(text, text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.br_afacode_decode_log(p_code text, p_isolabel_ext text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
        'id',v.id,
        'jurisd_base_id',jurisd_base_id,
        'properties',jsonb_build_object(
            'area',area,
            'side',side,
            'isolabel_ext',p_isolabel_ext,
            'isolabel_ext_abbrev',abbreviations,
            'logistic_id',canonical_prefix_with_separator || p_code,
            -- 'truncated',truncated,
            'jurisd_local_id',jurisd_local_id))))::jsonb
  FROM
  (
    SELECT jurisd_local_id, jurisd_base_id, abbreviations, canonical_prefix_with_separator, afa.vbit_to_hBig( cbits_in_vbit || afa.b32nvu_to_vbit(substring(p_code,2)) ) AS hbig
    FROM osmc.mvwcoverage c
    WHERE is_country IS FALSE
      AND c.isolabel_ext = p_isolabel_ext
      AND cindex = substring(p_code,1,1)
  ) j,
  LATERAL (SELECT afa.hBig_to_hex(j.hbig,true), afa.br_decode(j.hbig), ((j.hbig)::bit(6))::int - 12) v(id,geom,id_length),
  LATERAL (SELECT afa.br_cell_area(v.id_length), afa.br_cell_side(v.id_length)) l(area,side)
$$;


ALTER FUNCTION osmc.br_afacode_decode_log(p_code text, p_isolabel_ext text) OWNER TO postgres;

--
-- Name: FUNCTION br_afacode_decode_log(p_code text, p_isolabel_ext text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.br_afacode_decode_log(p_code text, p_isolabel_ext text) IS 'Decodes a logistic AFAcode for Brazil. Requiring prior jurisdictional context.';


--
-- Name: br_afacode_decode_log_abs(text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.br_afacode_decode_log_abs(p_code text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
        'id',v.id,
        'jurisd_base_id',76,
        'properties',jsonb_build_object(
            'area',area,
            'side',side,
            'logistic_id','BR~'||p_code))))::jsonb
  FROM
  (
    SELECT afa.vbit_to_hBig( b'00010100' || afa.b32nvu_to_vbit(p_code) ) AS hbig
  ) j,
  LATERAL (SELECT afa.hBig_to_hex(j.hbig,true), afa.br_decode(j.hbig), ((j.hbig)::bit(6))::int - 12) v(id,geom,id_length),
  LATERAL (SELECT afa.br_cell_area(v.id_length), afa.br_cell_side(v.id_length)) l(area,side)
$$;


ALTER FUNCTION osmc.br_afacode_decode_log_abs(p_code text) OWNER TO postgres;

--
-- Name: FUNCTION br_afacode_decode_log_abs(p_code text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.br_afacode_decode_log_abs(p_code text) IS 'Decodes a logistic AFAcode for Brazil. Requiring prior jurisdictional context.';


--
-- Name: br_afacode_encode(double precision, double precision, integer); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.br_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
    SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
        'id',v.id,
        'jurisd_base_id',76,
        'properties', jsonb_build_object(
            'area',l.area,
            'side',l.side))))::jsonb
    FROM (SELECT afa.br_encode(p_lat,p_lon,p_level), afa.br_cell_area(p_level), afa.br_cell_side(p_level)) l(hbig,area,side),
    LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.br_decode(hbig)) v(id,geom)
$$;


ALTER FUNCTION osmc.br_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) OWNER TO postgres;

--
-- Name: FUNCTION br_afacode_encode(p_lat double precision, p_lon double precision, p_level integer); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.br_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) IS 'Encodes lat/lon to AFAcode grid scientific for Brazil.';


--
-- Name: br_afacode_encode_log(double precision, double precision, integer, text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.br_afacode_encode_log(p_lat double precision, p_lon double precision, p_level integer, p_isolabel_ext text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
    SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
        'id',v.id,
        'jurisd_base_id',76,
        'properties',jsonb_build_object(
            'area',l.area,
            'side',l.side,
            'isolabel_ext',p_isolabel_ext,
            'isolabel_ext_abbrev',abbreviations,
            'logistic_id', canonical_prefix_with_cindex || COALESCE(afa.vbit_to_b32nvu(vbit_without_prefix),''),
            'jurisd_local_id', jurisd_local_id))))::jsonb
    FROM (SELECT afa.br_encode(p_lat,p_lon,p_level), afa.br_cell_area(p_level), afa.br_cell_side(p_level)) l(hbig,area,side),
    LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.br_decode(hbig)) v(id,geom),
    LATERAL (SELECT cindex, cbits, abbreviations, jurisd_local_id, canonical_prefix_with_cindex, vbit_without_prefix FROM osmc.encode_short_code(hbig,p_isolabel_ext)) d(cindex, cbits, abbreviations, jurisd_local_id, canonical_prefix_with_cindex, vbit_without_prefix)
$$;


ALTER FUNCTION osmc.br_afacode_encode_log(p_lat double precision, p_lon double precision, p_level integer, p_isolabel_ext text) OWNER TO postgres;

--
-- Name: FUNCTION br_afacode_encode_log(p_lat double precision, p_lon double precision, p_level integer, p_isolabel_ext text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.br_afacode_encode_log(p_lat double precision, p_lon double precision, p_level integer, p_isolabel_ext text) IS 'Encodes lat/lon to a Logistics AFAcode for Brazil.';


--
-- Name: br_afacode_encode_log_abs(double precision, double precision, integer); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.br_afacode_encode_log_abs(p_lat double precision, p_lon double precision, p_level integer) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
    SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
        'id',v.id,
        'jurisd_base_id',76,
        'properties',jsonb_build_object(
            'area',l.area,
            'side',l.side,
            'logistic_id', COALESCE('BR~'||afa.vbit_to_b32nvu(substring(afa.hBig_to_vbit(hbig) FROM 9)),'') ))))::jsonb
    FROM (SELECT afa.br_encode(p_lat,p_lon,p_level), afa.br_cell_area(p_level), afa.br_cell_side(p_level)) l(hbig,area,side),
    LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.br_decode(hbig)) v(id,geom)
$$;


ALTER FUNCTION osmc.br_afacode_encode_log_abs(p_lat double precision, p_lon double precision, p_level integer) OWNER TO postgres;

--
-- Name: FUNCTION br_afacode_encode_log_abs(p_lat double precision, p_lon double precision, p_level integer); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.br_afacode_encode_log_abs(p_lat double precision, p_lon double precision, p_level integer) IS 'Encodes lat/lon to a Logistics AFAcode for Brazil.';


--
-- Name: br_jurisdiction_coverage(text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.br_jurisdiction_coverage(p_iso text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform(c.geom,4326),8,0)::jsonb,
        'id', v.id,
        'properties',jsonb_build_object(
                'area', area,
                'side', side,
                'index', cindex,
                'is_country', is_country,
                'is_contained', is_contained,
                'is_overlay', is_overlay,
                'level', id_length))))::jsonb
  FROM osmc.mvwcoverage c,
  LATERAL (SELECT afa.hBig_to_hex(c.cbits), afa.br_decode(c.cbits), (c.prefixlen - 12 )) v(id,geom,id_length),
  LATERAL (SELECT afa.br_cell_area(v.id_length), afa.br_cell_side(v.id_length)) l(area,side)
  WHERE isolabel_ext = p_iso
$$;


ALTER FUNCTION osmc.br_jurisdiction_coverage(p_iso text) OWNER TO postgres;

--
-- Name: FUNCTION br_jurisdiction_coverage(p_iso text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.br_jurisdiction_coverage(p_iso text) IS 'Returns jurisdiction coverage.';


--
-- Name: cm_afacode_decode(text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.cm_afacode_decode(p_code text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT
    jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
      'type','Feature',
      'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
      'id',v.id,
      'jurisd_base_id',120,
      'properties',jsonb_build_object(
          'area',l.area,
          'side',l.side,
          'truncated',(CASE WHEN length(v.id) - length(code) <> 3 THEN TRUE ELSE FALSE END)))))::jsonb
  FROM regexp_split_to_table(p_code,',') code,
  LATERAL (SELECT afa.cm_hex_to_hBig(substring(code,1,10))) m(hbig),
  LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.cm_decode(hbig), afa.cm_hBig_to_xyLRef(hbig)) v(id,geom,xyL),
  LATERAL (SELECT afa.cm_cell_area(xyL[3]), afa.cm_cell_side(xyL[3])) l(area,side)
$$;


ALTER FUNCTION osmc.cm_afacode_decode(p_code text) OWNER TO postgres;

--
-- Name: FUNCTION cm_afacode_decode(p_code text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.cm_afacode_decode(p_code text) IS 'Decodes a scientific AFAcode for Cameroon.';


--
-- Name: cm_afacode_decode_log(text, text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.cm_afacode_decode_log(p_code text, p_isolabel_ext text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
        'id',v.id,
        'jurisd_base_id',jurisd_base_id,
        'properties',jsonb_build_object(
            'area',area,
            'side',side,
            'isolabel_ext',p_isolabel_ext,
            'isolabel_ext_abbrev',abbreviations,
            'logistic_id', canonical_prefix_with_separator || p_code,
            -- 'truncated',truncated,
            'jurisd_local_id', jurisd_local_id))))::jsonb
  FROM
  (
    SELECT jurisd_local_id, jurisd_base_id, abbreviations, canonical_prefix_with_separator, afa.vbit_to_hBig( cbits_in_vbit || afa.b32nvu_to_vbit(substring(p_code,2)) ) AS hbig
    FROM osmc.mvwcoverage c
    WHERE is_country IS FALSE
      AND c.isolabel_ext = p_isolabel_ext
      AND cindex = substring(p_code,1,1)
  ) j,
  LATERAL (SELECT afa.hBig_to_hex(j.hbig,true), afa.cm_decode(j.hbig), ((j.hbig)::bit(6))::int - 12) v(id,geom,id_length),
  LATERAL (SELECT afa.cm_cell_area(v.id_length), afa.cm_cell_side(v.id_length)) l(area,side)
$$;


ALTER FUNCTION osmc.cm_afacode_decode_log(p_code text, p_isolabel_ext text) OWNER TO postgres;

--
-- Name: FUNCTION cm_afacode_decode_log(p_code text, p_isolabel_ext text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.cm_afacode_decode_log(p_code text, p_isolabel_ext text) IS 'Decodes a logistic AFAcode for Cameroon. Requiring prior jurisdictional context.';


--
-- Name: cm_afacode_encode(double precision, double precision, integer); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.cm_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
    SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
        'id',v.id,
        'jurisd_base_id',120,
        'properties',jsonb_build_object(
            'area',l.area,
            'side',l.side))))::jsonb
    FROM (SELECT afa.cm_encode(p_lat,p_lon,p_level), afa.cm_cell_area(p_level), afa.cm_cell_side(p_level)) l(hbig,area,side),
    LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.cm_decode(hbig)) v(id,geom)
$$;


ALTER FUNCTION osmc.cm_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) OWNER TO postgres;

--
-- Name: FUNCTION cm_afacode_encode(p_lat double precision, p_lon double precision, p_level integer); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.cm_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) IS 'Encodes lat/lon to AFAcode grid scientific for Cameroon.';


--
-- Name: cm_afacode_encode_log(double precision, double precision, integer, text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.cm_afacode_encode_log(p_lat double precision, p_lon double precision, p_level integer, p_isolabel_ext text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
    SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
        'id',v.id,
        'jurisd_base_id',120,
        'properties',jsonb_build_object(
            'area',l.area,
            'side',l.side,
            'isolabel_ext',p_isolabel_ext,
            'isolabel_ext_abbrev',abbreviations,
            'logistic_id',canonical_prefix_with_cindex || COALESCE(afa.vbit_to_b32nvu(vbit_without_prefix),''),
            'jurisd_local_id', jurisd_local_id))))::jsonb
    FROM (SELECT afa.cm_encode(p_lat,p_lon,p_level), afa.cm_cell_area(p_level), afa.cm_cell_side(p_level)) l(hbig,area,side),
    LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.cm_decode(hbig)) v(id,geom),
    LATERAL (SELECT cindex, cbits, abbreviations, jurisd_local_id, canonical_prefix_with_cindex, vbit_without_prefix FROM osmc.encode_short_code(hbig,p_isolabel_ext)) d(cindex, cbits, abbreviations, jurisd_local_id, canonical_prefix_with_cindex, vbit_without_prefix)
$$;


ALTER FUNCTION osmc.cm_afacode_encode_log(p_lat double precision, p_lon double precision, p_level integer, p_isolabel_ext text) OWNER TO postgres;

--
-- Name: FUNCTION cm_afacode_encode_log(p_lat double precision, p_lon double precision, p_level integer, p_isolabel_ext text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.cm_afacode_encode_log(p_lat double precision, p_lon double precision, p_level integer, p_isolabel_ext text) IS 'Encodes lat/lon to a Logistics AFAcode for Cameroon.';


--
-- Name: cm_jurisdiction_coverage(text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.cm_jurisdiction_coverage(p_iso text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform(c.geom,4326),8,0)::jsonb,
        'id', v.id,
        'properties',jsonb_build_object(
                'area', area,
                'side', side,
                'index', cindex,
                'is_country', is_country,
                'is_contained', is_contained,
                'is_overlay', is_overlay,
                'level', id_length))))::jsonb
  FROM osmc.mvwcoverage c,
  LATERAL (SELECT afa.hBig_to_hex(c.cbits), afa.cm_decode(c.cbits), (c.prefixlen - 12 )) v(id,geom,id_length),
  LATERAL (SELECT afa.cm_cell_area(v.id_length), afa.cm_cell_side(v.id_length)) l(area,side)
  WHERE isolabel_ext = p_iso
$$;


ALTER FUNCTION osmc.cm_jurisdiction_coverage(p_iso text) OWNER TO postgres;

--
-- Name: FUNCTION cm_jurisdiction_coverage(p_iso text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.cm_jurisdiction_coverage(p_iso text) IS 'Returns jurisdiction coverage.';


--
-- Name: co_afacode_decode(text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.co_afacode_decode(p_code text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT
    jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
      'type','Feature',
      'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
      'id',v.id,
      'jurisd_base_id',170,
      'properties',jsonb_build_object(
          'area',l.area,
          'side',l.side,
          'truncated',(CASE WHEN length(v.id) - length(code) <> 3 THEN TRUE ELSE FALSE END)))))::jsonb
  FROM regexp_split_to_table(p_code,',') code,
  LATERAL (SELECT afa.co_hex_to_hBig(substring(code,1,11))) m(hbig),
  LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.co_decode(hbig), afa.co_hBig_to_xyLRef(hbig)) v(id,geom,xyL),
  LATERAL (SELECT afa.co_cell_area(xyL[3]), afa.co_cell_side(xyL[3])) l(area,side)
$$;


ALTER FUNCTION osmc.co_afacode_decode(p_code text) OWNER TO postgres;

--
-- Name: FUNCTION co_afacode_decode(p_code text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.co_afacode_decode(p_code text) IS 'Decodes a scientific AFAcode for Colombia.';


--
-- Name: co_afacode_decode_log(text, text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.co_afacode_decode_log(p_code text, p_isolabel_ext text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
        'id',v.id,
        'jurisd_base_id',jurisd_base_id,
        'properties',jsonb_build_object(
            'area',area,
            'side',side,
            'isolabel_ext',p_isolabel_ext,
            'isolabel_ext_abbrev',abbreviations,
            'logistic_id', canonical_prefix_with_separator || p_code,
            -- 'truncated',truncated,
            'jurisd_local_id', jurisd_local_id))))::jsonb
  FROM
  (
    SELECT jurisd_local_id, jurisd_base_id, abbreviations, canonical_prefix_with_separator, afa.vbit_to_hBig( cbits_in_vbit || afa.b32nvu_to_vbit(substring(p_code,2)) ) AS hbig
    FROM osmc.mvwcoverage c
    WHERE is_country IS FALSE
      AND c.isolabel_ext = p_isolabel_ext
      AND cindex = substring(p_code,1,1)
  ) j,
  LATERAL (SELECT afa.hBig_to_hex(j.hbig,true), afa.co_decode(j.hbig), ((j.hbig)::bit(6))::int - 12) v(id,geom,id_length),
  LATERAL (SELECT afa.co_cell_area(v.id_length), afa.co_cell_side(v.id_length)) l(area,side)
$$;


ALTER FUNCTION osmc.co_afacode_decode_log(p_code text, p_isolabel_ext text) OWNER TO postgres;

--
-- Name: FUNCTION co_afacode_decode_log(p_code text, p_isolabel_ext text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.co_afacode_decode_log(p_code text, p_isolabel_ext text) IS 'Decodes a logistic AFAcode for Colombia. Requiring prior jurisdictional context.';


--
-- Name: co_afacode_encode(double precision, double precision, integer); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.co_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT
    jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
      'type','Feature',
      'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
      'id',v.id,
      'jurisd_base_id',170,
      'properties',jsonb_build_object(
          'area',l.area,
          'side',l.side))))::jsonb
    FROM (SELECT afa.co_encode(p_lat,p_lon,p_level), afa.co_cell_area(p_level), afa.co_cell_side(p_level)) l(hbig,area,side),
    LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.co_decode(hbig)) v(id,geom)
$$;


ALTER FUNCTION osmc.co_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) OWNER TO postgres;

--
-- Name: FUNCTION co_afacode_encode(p_lat double precision, p_lon double precision, p_level integer); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.co_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) IS 'Encodes lat/lon to AFAcode grid scientific for Colombia.';


--
-- Name: co_afacode_encode_log(double precision, double precision, integer, text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.co_afacode_encode_log(p_lat double precision, p_lon double precision, p_level integer, p_isolabel_ext text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
    SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
        'id',v.id,
        'jurisd_base_id',170,
        'properties',jsonb_build_object(
            'area',l.area,
            'side',l.side,
            'isolabel_ext',p_isolabel_ext,
            'isolabel_ext_abbrev',abbreviations,
            'logistic_id', canonical_prefix_with_cindex || COALESCE(afa.vbit_to_b32nvu(vbit_without_prefix),''),
            'jurisd_local_id', jurisd_local_id))))::jsonb
    FROM (SELECT afa.co_encode(p_lat,p_lon,p_level), afa.co_cell_area(p_level), afa.co_cell_side(p_level)) l(hbig,area,side),
    LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.co_decode(hbig)) v(id,geom),
    LATERAL (SELECT cindex, cbits, abbreviations, jurisd_local_id, canonical_prefix_with_cindex, vbit_without_prefix FROM osmc.encode_short_code(hbig,p_isolabel_ext)) d(cindex, cbits, abbreviations, jurisd_local_id, canonical_prefix_with_cindex, vbit_without_prefix)
$$;


ALTER FUNCTION osmc.co_afacode_encode_log(p_lat double precision, p_lon double precision, p_level integer, p_isolabel_ext text) OWNER TO postgres;

--
-- Name: FUNCTION co_afacode_encode_log(p_lat double precision, p_lon double precision, p_level integer, p_isolabel_ext text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.co_afacode_encode_log(p_lat double precision, p_lon double precision, p_level integer, p_isolabel_ext text) IS 'Encodes lat/lon to a Logistics AFAcode for Colombia.';


--
-- Name: co_jurisdiction_coverage(text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.co_jurisdiction_coverage(p_iso text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform(c.geom,4326),8,0)::jsonb,
        'id', v.id,
        'properties',jsonb_build_object(
                'area', area,
                'side', side,
                'index', cindex,
                'is_country', is_country,
                'is_contained', is_contained,
                'is_overlay', is_overlay,
                'level', id_length))))::jsonb
  FROM osmc.mvwcoverage c,
  LATERAL (SELECT afa.hBig_to_hex(c.cbits), afa.co_decode(c.cbits), (c.prefixlen - 12 )) v(id,geom,id_length),
  LATERAL (SELECT afa.co_cell_area(v.id_length), afa.co_cell_side(v.id_length)) l(area,side)
  WHERE isolabel_ext = p_iso
$$;


ALTER FUNCTION osmc.co_jurisdiction_coverage(p_iso text) OWNER TO postgres;

--
-- Name: FUNCTION co_jurisdiction_coverage(p_iso text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.co_jurisdiction_coverage(p_iso text) IS 'Returns jurisdiction coverage.';


--
-- Name: encode_short_code(bigint, text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.encode_short_code(p_hbig bigint, p_isolabel_ext text) RETURNS TABLE(cindex text, cbits bigint, abbreviations text[], jurisd_local_id integer, canonical_prefix_with_cindex text, vbit_without_prefix bit varying)
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT cindex, cbits, abbreviations, jurisd_local_id, canonical_prefix_with_cindex, substring(v.hbitstr FROM (r.prefixlen +1)) AS vbit_without_prefix
  FROM osmc.mvwcoverage r,
  LATERAL (SELECT afa.hBig_to_vbit(p_hbig) AS hbitstr) v
  WHERE isolabel_ext = p_isolabel_ext
    AND afa.hBig_to_vbit(cbits) = substring(v.hbitstr FROM 1 FOR r.prefixlen)
    order by is_overlay DESC
    LIMIT 1
  ;
$$;


ALTER FUNCTION osmc.encode_short_code(p_hbig bigint, p_isolabel_ext text) OWNER TO postgres;

--
-- Name: FUNCTION encode_short_code(p_hbig bigint, p_isolabel_ext text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.encode_short_code(p_hbig bigint, p_isolabel_ext text) IS 'Computes the short code representation of a hierarchical grid cell for a given jurisdiction.';


--
-- Name: generate_cover_csv(text, text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.generate_cover_csv(p_isolabel_ext text, p_path text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    q_copy text;
BEGIN
  q_copy := $$
    COPY (

      WITH base AS (
        SELECT
          isolabel_ext,
          status,
          kx_prefix,
          is_overlay,
          cindex
        FROM osmc.mvwcoverage
        WHERE is_country IS FALSE
          AND isolabel_ext LIKE '%s%%'
      )
      SELECT
        isolabel_ext,
        MIN(status) AS status,
        NULL AS base_intlevel,
        STRING_AGG(kx_prefix, ' ') FILTER (WHERE is_overlay IS FALSE) AS cover,
        STRING_AGG(kx_prefix, ' ') FILTER (WHERE is_overlay IS TRUE) AS overlay,
        STRING_AGG(cindex,    ' ') FILTER (WHERE is_overlay IS FALSE) AS cover_order,
        STRING_AGG(cindex,    ' ') FILTER (WHERE is_overlay IS TRUE) AS overlay_order
      FROM base
      GROUP BY isolabel_ext
      ORDER BY isolabel_ext

    ) TO '%s' CSV HEADER
  $$;

  EXECUTE format(q_copy,p_isolabel_ext,p_path);

  RETURN 'Ok.';
END
$_$;


ALTER FUNCTION osmc.generate_cover_csv(p_isolabel_ext text, p_path text) OWNER TO postgres;

--
-- Name: FUNCTION generate_cover_csv(p_isolabel_ext text, p_path text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.generate_cover_csv(p_isolabel_ext text, p_path text) IS 'Generate csv with isolevel=3 coverage and overlay in separate array.';


--
-- Name: str_geouri_decode(text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.str_geouri_decode(uri text) RETURNS double precision[]
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT regexp_match(uri,'^geo:(?:olc:|ghs:)?([-0-9\.]+),([-0-9\.]+)(?:;u=([-0-9\.]+))?','i')::float[]
$$;


ALTER FUNCTION osmc.str_geouri_decode(uri text) OWNER TO postgres;

--
-- Name: sv_afacode_decode(text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.sv_afacode_decode(p_code text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT
    jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
      'type','Feature',
      'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
      'id',v.id,
      'jurisd_base_id',222,
      'properties',jsonb_build_object(
          'area',l.area,
          'side',l.side,
          'truncated',(CASE WHEN length(v.id) - length(code) <> 3 THEN TRUE ELSE FALSE END)))))::jsonb
  FROM regexp_split_to_table(p_code,',') code,
  LATERAL (SELECT afa.sv_hex_to_hBig(substring(code,1,9))) m(hbig),
  LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.sv_decode(hbig), afa.sv_hBig_to_xyLRef(hbig)) v(id,geom,xyL),
  LATERAL (SELECT afa.sv_cell_area(xyL[3]), afa.sv_cell_side(xyL[3])) l(area,side)
$$;


ALTER FUNCTION osmc.sv_afacode_decode(p_code text) OWNER TO postgres;

--
-- Name: FUNCTION sv_afacode_decode(p_code text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.sv_afacode_decode(p_code text) IS 'Decodes a scientific AFAcode for El Salvador.';


--
-- Name: sv_afacode_decode_log(text, text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.sv_afacode_decode_log(p_code text, p_isolabel_ext text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
        'id',v.id,
        'jurisd_base_id',jurisd_base_id,
        'properties',jsonb_build_object(
            'area',area,
            'side',side,
            'isolabel_ext',p_isolabel_ext,
            'isolabel_ext_abbrev',abbreviations,
            'logistic_id', canonical_prefix_with_separator || p_code,
            -- 'truncated',truncated,
            'jurisd_local_id', jurisd_local_id))))::jsonb
  FROM
  (
    SELECT jurisd_local_id, jurisd_base_id, abbreviations, canonical_prefix_with_separator, afa.vbit_to_hBig( cbits_in_vbit || afa.hex_to_vbit(substring(lower(p_code),2)) ) AS hbig, cbits
    FROM osmc.mvwcoverage c
    WHERE is_country IS FALSE
      AND c.isolabel_ext = p_isolabel_ext
      AND cindex = substring(p_code,1,1)
  ) j,
  LATERAL (SELECT afa.hBig_to_hex(j.hbig,true), afa.sv_decode(j.hbig), ((j.hbig)::bit(6))::int - 12) v(id,geom,id_length),
  LATERAL (SELECT afa.sv_cell_area(v.id_length), afa.sv_cell_side(v.id_length)) l(area,side)
$$;


ALTER FUNCTION osmc.sv_afacode_decode_log(p_code text, p_isolabel_ext text) OWNER TO postgres;

--
-- Name: FUNCTION sv_afacode_decode_log(p_code text, p_isolabel_ext text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.sv_afacode_decode_log(p_code text, p_isolabel_ext text) IS 'Decodes a logistic AFAcode for El Salvador. Requiring prior jurisdictional context.';


--
-- Name: sv_afacode_encode(double precision, double precision, integer); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.sv_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT
    jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
      'type','Feature',
      'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
      'id',v.id,
      'jurisd_base_id',222,
      'properties',jsonb_build_object(
          'area',l.area,
          'side',l.side))))::jsonb
    FROM (SELECT afa.sv_encode(p_lat,p_lon,p_level), afa.sv_cell_area(p_level), afa.sv_cell_side(p_level)) l(hbig,area,side),
    LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.sv_decode(hbig)) v(id,geom)
$$;


ALTER FUNCTION osmc.sv_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) OWNER TO postgres;

--
-- Name: FUNCTION sv_afacode_encode(p_lat double precision, p_lon double precision, p_level integer); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.sv_afacode_encode(p_lat double precision, p_lon double precision, p_level integer) IS 'Encodes lat/lon to AFAcode grid scientific for El Salvador.';


--
-- Name: sv_afacode_encode_log(double precision, double precision, integer, text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.sv_afacode_encode_log(p_lat double precision, p_lon double precision, p_level integer, p_isolabel_ext text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
    SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform_Resilient(v.geom,4326,0.005,0.00000005),8,0)::jsonb,
        'id',v.id,
        'jurisd_base_id',222,
        'properties',jsonb_build_object(
            'area',l.area,
            'side',l.side,
            'isolabel_ext',p_isolabel_ext,
            'isolabel_ext_abbrev',abbreviations,
            'logistic_id', canonical_prefix_with_cindex || COALESCE(natcod.vbit_to_baseh(vbit_without_prefix ,'16'),''),
            'jurisd_local_id', jurisd_local_id))))::jsonb
    FROM (SELECT afa.sv_encode(p_lat,p_lon,p_level), afa.sv_cell_area(p_level), afa.sv_cell_side(p_level)) l(hbig,area,side),
    LATERAL (SELECT afa.hBig_to_hex(hbig,true), afa.sv_decode(hbig)) v(id,geom),
    LATERAL (SELECT cindex, cbits, abbreviations, jurisd_local_id, canonical_prefix_with_cindex, vbit_without_prefix FROM osmc.encode_short_code(hbig,p_isolabel_ext)) d(cindex, cbits, abbreviations, jurisd_local_id, canonical_prefix_with_cindex, vbit_without_prefix)
$$;


ALTER FUNCTION osmc.sv_afacode_encode_log(p_lat double precision, p_lon double precision, p_level integer, p_isolabel_ext text) OWNER TO postgres;

--
-- Name: FUNCTION sv_afacode_encode_log(p_lat double precision, p_lon double precision, p_level integer, p_isolabel_ext text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.sv_afacode_encode_log(p_lat double precision, p_lon double precision, p_level integer, p_isolabel_ext text) IS 'Encodes lat/lon to a Logistics AFAcode for El Savador.';


--
-- Name: sv_jurisdiction_coverage(text); Type: FUNCTION; Schema: osmc; Owner: postgres
--

CREATE FUNCTION osmc.sv_jurisdiction_coverage(p_iso text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT
      jsonb_build_object('type','FeatureCollection','features',jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry',ST_AsGeoJSON(ST_Transform(c.geom,4326),8,0)::jsonb,
        'id', v.id,
        'properties',jsonb_build_object(
                'area', area,
                'side', side,
                'index', cindex,
                'is_country', is_country,
                'is_contained', is_contained,
                'is_overlay', is_overlay,
                'level', id_length))))::jsonb
  FROM osmc.mvwcoverage c,
  LATERAL (SELECT afa.hBig_to_hex(c.cbits), afa.sv_decode(c.cbits), (c.prefixlen - 12 )) v(id,geom,id_length),
  LATERAL (SELECT afa.sv_cell_area(v.id_length), afa.sv_cell_side(v.id_length)) l(area,side)
  WHERE isolabel_ext = p_iso
$$;


ALTER FUNCTION osmc.sv_jurisdiction_coverage(p_iso text) OWNER TO postgres;

--
-- Name: FUNCTION sv_jurisdiction_coverage(p_iso text); Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON FUNCTION osmc.sv_jurisdiction_coverage(p_iso text) IS 'Returns jurisdiction coverage.';


--
-- Name: array_cat_distinct(anyarray, anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_cat_distinct(a anyarray, b anyarray) RETURNS anyarray
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT CASE WHEN a is null THEN b WHEN b is null THEN a ELSE (
    SELECT a || array_agg(b_i)
    FROM unnest(b) t(b_i)
    WHERE NOT( b_i=any(a) )
  ) END
$$;


ALTER FUNCTION public.array_cat_distinct(a anyarray, b anyarray) OWNER TO postgres;

--
-- Name: array_distinct_sort(anyarray, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_distinct_sort(anyarray, p_no_null boolean DEFAULT true) RETURNS anyarray
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
  SELECT CASE WHEN array_length(x,1) IS NULL THEN NULL ELSE x END -- same as  x='{}'::anyarray
  FROM (
  	SELECT ARRAY(
        SELECT DISTINCT x
        FROM unnest($1) t(x)
        WHERE CASE
          WHEN p_no_null  THEN  x IS NOT NULL
          ELSE  true
          END
        ORDER BY 1
   )
 ) t(x)
$_$;


ALTER FUNCTION public.array_distinct_sort(anyarray, p_no_null boolean) OWNER TO postgres;

--
-- Name: array_fastsort(anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_fastsort(anyarray) RETURNS anyarray
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
  SELECT ARRAY(SELECT unnest($1) ORDER BY 1)
$_$;


ALTER FUNCTION public.array_fastsort(anyarray) OWNER TO postgres;

--
-- Name: array_fillto(anyarray, integer, anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_fillto(p_array anyarray, p_len integer, p_null anyelement DEFAULT NULL::unknown) RETURNS anyarray
    LANGUAGE sql IMMUTABLE
    AS $_$
   SELECT CASE
       WHEN len=0 THEN array_fill(p_null,array[p_len])
       WHEN len<p_len THEN p_array || array_fill($3,array[$2-len])
       ELSE $1 END
   FROM ( SELECT COALESCE( array_length(p_array,1), 0) ) t(len)
$_$;


ALTER FUNCTION public.array_fillto(p_array anyarray, p_len integer, p_null anyelement) OWNER TO postgres;

--
-- Name: array_fillto_duo(anyarray, anyarray, anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_fillto_duo(anyarray, anyarray, anyelement DEFAULT NULL::unknown) RETURNS TABLE(a anyarray, b anyarray)
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT CASE WHEN l1>=l2 THEN $1 ELSE array_fillto($1,l2,$3) END a,
   CASE WHEN l1<=l2 THEN $2 ELSE array_fillto($2,l1,$3) END b
  FROM (SELECT array_length($1,1) l1, array_length($2,1) l2) t
$_$;


ALTER FUNCTION public.array_fillto_duo(anyarray, anyarray, anyelement) OWNER TO postgres;

--
-- Name: array_is_allsame(anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_is_allsame(anyarray) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
  SELECT CASE
           WHEN $1 is NULL OR l=0 THEN NULL
           WHEN l=1 THEN true
           ELSE (
             SELECT bool_and($1[1]=x)
             FROM unnest($1[2:]) t1(x)
           )
           END
  FROM (SELECT array_length($1,1)) t2(l)
$_$;


ALTER FUNCTION public.array_is_allsame(anyarray) OWNER TO postgres;

--
-- Name: array_last(anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_last(p_input anyarray) RETURNS anyelement
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT $1[array_upper($1,1)]
$_$;


ALTER FUNCTION public.array_last(p_input anyarray) OWNER TO postgres;

--
-- Name: array_last_butnot(anyarray, anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_last_butnot(p_input anyarray, p_not anyarray) RETURNS anyelement
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT CASE
     WHEN array_length($1,1)<2 THEN   $1[array_lower($1,1)]
     WHEN p_not IS NOT NULL AND thelast=any(p_not) THEN   $1[x-1]
     ELSE thelast
     END
  FROM (select x,$1[x] thelast FROM (select array_upper($1,1)) t(x)) t2
$_$;


ALTER FUNCTION public.array_last_butnot(p_input anyarray, p_not anyarray) OWNER TO postgres;

--
-- Name: array_last_butnot(anyarray, anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_last_butnot(p_input anyarray, p_not anyelement) RETURNS anyelement
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT array_last_butnot($1,array[$2])
$_$;


ALTER FUNCTION public.array_last_butnot(p_input anyarray, p_not anyelement) OWNER TO postgres;

--
-- Name: array_merge_sort(anycompatiblearray, anycompatiblearray, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_merge_sort(anycompatiblearray, anycompatiblearray, boolean DEFAULT true) RETURNS anycompatiblearray
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT array_distinct_sort(array_cat($1,$2),$3)
$_$;


ALTER FUNCTION public.array_merge_sort(anycompatiblearray, anycompatiblearray, boolean) OWNER TO postgres;

--
-- Name: array_rebuild_add_prefix(text, text[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_rebuild_add_prefix(prefix text, a text[], sep text DEFAULT '#'::text) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT array_agg(px)
  FROM (
    SELECT prefix||sep||x as px
    FROM unnest(a) t(x) ORDER BY x
  ) t
$$;


ALTER FUNCTION public.array_rebuild_add_prefix(prefix text, a text[], sep text) OWNER TO postgres;

--
-- Name: FUNCTION array_rebuild_add_prefix(prefix text, a text[], sep text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.array_rebuild_add_prefix(prefix text, a text[], sep text) IS 'Rebuild array by adding a prefix in all items.';


--
-- Name: array_reduce_dim(anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_reduce_dim(anyarray) RETURNS SETOF anyarray
    LANGUAGE plpgsql IMMUTABLE
    AS $_$ -- see https://wiki.postgresql.org/wiki/Unnest_multidimensional_array
DECLARE
    s $1%TYPE;
BEGIN
    FOREACH s SLICE 1  IN ARRAY $1 LOOP
        RETURN NEXT s;
    END LOOP;
    RETURN;
END;
$_$;


ALTER FUNCTION public.array_reduce_dim(anyarray) OWNER TO postgres;

--
-- Name: array_sample(anyarray, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_sample(p_items anyarray, p_qt integer DEFAULT NULL::integer) RETURNS anyarray
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT array_agg(x)
  FROM (
    SELECT x FROM unnest($1) t2(x)
    ORDER BY random() LIMIT $2
  ) t
$_$;


ALTER FUNCTION public.array_sample(p_items anyarray, p_qt integer) OWNER TO postgres;

--
-- Name: array_substr(text[], integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_substr(text[], integer) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT array_agg( substring(x,$2) ) FROM unnest($1) t(x)
$_$;


ALTER FUNCTION public.array_substr(text[], integer) OWNER TO postgres;

--
-- Name: array_substr(text[], integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_substr(text[], integer, integer) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT array_agg( substring(x,$2,$3) ) FROM unnest($1) t(x)
$_$;


ALTER FUNCTION public.array_substr(text[], integer, integer) OWNER TO postgres;

--
-- Name: array_subtract(anyarray, anyarray, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_subtract(p_a anyarray, p_b anyarray, p_empty_to_null boolean DEFAULT true) RETURNS anyarray
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT CASE WHEN p_empty_to_null AND x='{}' THEN NULL ELSE x END
  FROM (
    SELECT array(  SELECT unnest(p_a) EXCEPT SELECT unnest(p_b)  )
  ) t(x)
$$;


ALTER FUNCTION public.array_subtract(p_a anyarray, p_b anyarray, p_empty_to_null boolean) OWNER TO postgres;

--
-- Name: array_text_to_distleft(text[], integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_text_to_distleft(p_in text[], p_num integer DEFAULT 1) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
   SELECT array_agg(DISTINCT x ORDER BY x) 
   FROM ( select LEFT(unnest(p_in),p_num) ) t(x)
$$;


ALTER FUNCTION public.array_text_to_distleft(p_in text[], p_num integer) OWNER TO postgres;

--
-- Name: FUNCTION array_text_to_distleft(p_in text[], p_num integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.array_text_to_distleft(p_in text[], p_num integer) IS 'Cut all strings using LEFT, filtering DISTINCT.';


--
-- Name: array_text_to_distright(text[], integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_text_to_distright(p_in text[], p_num integer DEFAULT 1) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
   SELECT array_agg(DISTINCT x ORDER BY x) 
   FROM ( select RIGHT(unnest(p_in),p_num) ) t(x)
$$;


ALTER FUNCTION public.array_text_to_distright(p_in text[], p_num integer) OWNER TO postgres;

--
-- Name: FUNCTION array_text_to_distright(p_in text[], p_num integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.array_text_to_distright(p_in text[], p_num integer) IS 'Cut all strings using RIGHT, filtering DISTINCT.';


--
-- Name: array_text_to_left(text[], integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_text_to_left(p_in text[], p_num integer DEFAULT 1) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
   SELECT array_agg(x ORDER BY x) 
   FROM ( select LEFT(unnest(p_in),p_num) ) t(x)
$$;


ALTER FUNCTION public.array_text_to_left(p_in text[], p_num integer) OWNER TO postgres;

--
-- Name: FUNCTION array_text_to_left(p_in text[], p_num integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.array_text_to_left(p_in text[], p_num integer) IS 'Cut all strings using LEFT.';


--
-- Name: array_text_to_right(text[], integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_text_to_right(p_in text[], p_num integer DEFAULT 1) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
   SELECT array_agg(x ORDER BY x) 
   FROM ( select RIGHT(unnest(p_in),p_num) ) t(x)
$$;


ALTER FUNCTION public.array_text_to_right(p_in text[], p_num integer) OWNER TO postgres;

--
-- Name: FUNCTION array_text_to_right(p_in text[], p_num integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.array_text_to_right(p_in text[], p_num integer) IS 'Cut all strings using RIGHT.';


--
-- Name: base36_encode(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.base36_encode(digits bigint) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
  chars char[] := ARRAY[
	  '0','1','2','3','4','5','6','7','8','9'
          ,'A','B','C','D','E','F','G','H','I','J','K','L','M'
  	  ,'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'];
  ret text := '';
  val bigint;
BEGIN
  val := digits;
  WHILE val != 0 LOOP
    ret := chars[(val % 36)+1] || ret;
    val := val / 36;
  END LOOP;
  RETURN ret;
END;
$$;


ALTER FUNCTION public.base36_encode(digits bigint) OWNER TO postgres;

--
-- Name: bit_msb(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.bit_msb(x bigint) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $$
  -- Must be optimized in C, see e.g. https://stackoverflow.com/a/673781/287948
  SELECT CASE 
        WHEN x IS NULL OR x<0 THEN NULL 
        WHEN x =0 THEN 0 
        ELSE (floor( log(2,x::numeric) ) +1)::int
        END 
$$;


ALTER FUNCTION public.bit_msb(x bigint) OWNER TO postgres;

--
-- Name: FUNCTION bit_msb(x bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.bit_msb(x bigint) IS 'Must Significant Bit position, the length in a varbit representation.';


--
-- Name: csv_to_jsonb(text, text[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.csv_to_jsonb(p_info text, coltypes_sql text[], rgx_sep text DEFAULT '\|'::text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  -- from https://stackoverflow.com/a/64988973/287948
  SELECT to_jsonb(a) FROM (
      SELECT array_agg(CASE
          WHEN tp IN ('int','integer','smallint','bigint') THEN to_jsonb(p::bigint)
          WHEN tp IN ('number','numeric','float','double') THEN  to_jsonb(p::numeric)
          WHEN tp='boolean' THEN to_jsonb(p::boolean)
          WHEN tp IN ('json','jsonb','object','array') THEN p::jsonb
          ELSE to_jsonb(p)
        END) a
      FROM regexp_split_to_table(p_info,rgx_sep) WITH ORDINALITY t1(p,i)
      INNER JOIN unnest(coltypes_sql) WITH ORDINALITY t2(tp,j)
      ON i=j
  ) t
$$;


ALTER FUNCTION public.csv_to_jsonb(p_info text, coltypes_sql text[], rgx_sep text) OWNER TO postgres;

--
-- Name: FUNCTION csv_to_jsonb(p_info text, coltypes_sql text[], rgx_sep text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.csv_to_jsonb(p_info text, coltypes_sql text[], rgx_sep text) IS 'Atomic SQL-to-JSON datatypes convertions, starting from CSV lines and its column definition';


--
-- Name: decimal_zeros(double precision, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.decimal_zeros(x double precision, d_correction integer DEFAULT 1) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT CASE WHEN d<0 THEN 0 ELSE d END
    FROM (
      SELECT length(s) - length( regexp_replace(s,'\.0+','') ) - d_correction AS d
      FROM (SELECT x::text) t1(s)
    ) t2
$$;


ALTER FUNCTION public.decimal_zeros(x double precision, d_correction integer) OWNER TO postgres;

--
-- Name: doc_udf_show(text, text, text, oid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.doc_udf_show(p_schema_name text DEFAULT NULL::text, p_name_like text DEFAULT ''::text, p_name_notlike text DEFAULT ''::text, p_oid oid DEFAULT NULL::oid) RETURNS TABLE(oid oid, schema_name text, name text, language text, arguments text, return_type text, definition text, prokind text, comment text)
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT
    pg_proc.oid,
    pg_namespace.nspname::text,
    pg_proc.proname::text,
    pg_language.lanname::text,
    pg_get_function_arguments(pg_proc.oid)::text,
    pg_type.typname::text,
    CASE
      WHEN pg_language.lanname = 'internal' then pg_proc.prosrc::text
      ELSE pg_get_functiondef(pg_proc.oid)::text
    END,
    CASE pg_proc.prokind
       WHEN 'a' THEN 'agg'
       WHEN 'w' THEN 'window'
       WHEN 'p' THEN 'proc'
       ELSE 'func'
    END,
    obj_description(pg_proc.oid)::text
  FROM pg_proc
    LEFT JOIN pg_namespace on pg_proc.pronamespace = pg_namespace.oid
    LEFT JOIN pg_language on pg_proc.prolang = pg_language.oid
    LEFT JOIN pg_type on pg_type.oid = pg_proc.prorettype
  WHERE pg_namespace.nspname not in ('pg_catalog', 'information_schema')
        AND CASE WHEN COALESCE(p_schema_name,'') >'' THEN p_schema_name=pg_namespace.nspname::text ELSE true END
        AND CASE WHEN COALESCE(p_name_like,'') >'' THEN
              CASE WHEN position('%' in p_name_like)>0 THEN pg_proc.proname::text iLIKE p_name_like
              ELSE pg_proc.proname::text ~* p_name_like END
            ELSE true END
        AND CASE WHEN COALESCE(p_name_notlike,'') >'' THEN
              CASE WHEN position('%' in p_name_notlike)>0 THEN NOT(pg_proc.proname::text iLIKE p_name_notlike)
              ELSE NOT(pg_proc.proname::text ~* p_name_notlike) END
            ELSE true END
        AND CASE WHEN p_oid IS NOT NULL THEN pg_proc.oid=p_oid ELSE true END
$$;


ALTER FUNCTION public.doc_udf_show(p_schema_name text, p_name_like text, p_name_notlike text, p_oid oid) OWNER TO postgres;

--
-- Name: FUNCTION doc_udf_show(p_schema_name text, p_name_like text, p_name_notlike text, p_oid oid); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.doc_udf_show(p_schema_name text, p_name_like text, p_name_notlike text, p_oid oid) IS 'Show all information about an User Defined Function (UDF), by its OID, or listing all functions by LIKE filter.';


--
-- Name: doc_udf_show_simple(text, text, text, oid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.doc_udf_show_simple(p_schema_name text DEFAULT NULL::text, p_name_like text DEFAULT ''::text, p_name_notlike text DEFAULT ''::text, p_oid oid DEFAULT NULL::oid) RETURNS TABLE(id text, oid oid, schema_name text, name text, language text, definition_md5 text, arguments_simplified text[], arguments text, return_type text, prokind text, comment text)
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT doc_UDF_transparent_id(u.schema_name, u.name::text, s.arguments_simplified::text[]) AS id,
         u.oid, u.schema_name, u.name::text,
         u.language, md5(u.definition),
         s.arguments_simplified::text[] as arguments_simplified,
         u.arguments::text AS arguments,
         u.return_type, u.prokind, u.comment
  FROM doc_UDF_show_simplified_signature($1,$2,$3) s
      INNER JOIN doc_UDF_show($1,$2,$3,$4) u ON s.oid=u.oid::text
$_$;


ALTER FUNCTION public.doc_udf_show_simple(p_schema_name text, p_name_like text, p_name_notlike text, p_oid oid) OWNER TO postgres;

--
-- Name: doc_udf_show_simplified_signature(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.doc_udf_show_simplified_signature(p_schema_name text DEFAULT NULL::text, p_name_like text DEFAULT ''::text, p_name_notlike text DEFAULT ''::text) RETURNS TABLE(oid text, schema_name information_schema.sql_identifier, name information_schema.sql_identifier, arguments_simplified information_schema.character_data[])
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT substring(routines.specific_name::text from '[^_]+$'),
         routines.specific_schema, routines.routine_name,
         array_agg(parameters.data_type ORDER BY parameters.ordinal_position) as simplified_signature
  FROM information_schema.routines
    LEFT JOIN information_schema.parameters ON routines.specific_name=parameters.specific_name
  WHERE
        CASE WHEN COALESCE(p_schema_name,'') >''   THEN p_schema_name=routines.specific_schema  ELSE true END
        AND CASE WHEN COALESCE(p_name_like,'') >'' THEN
              CASE WHEN position('%' in p_name_like)>0 THEN
                   routines.routine_name::text iLIKE p_name_like
                   ELSE routines.routine_name::text ~* p_name_like END
            ELSE true END
        AND CASE WHEN COALESCE(p_name_notlike,'') >'' THEN 
              CASE WHEN position('%' in p_name_notlike)>0 THEN NOT(routines.routine_name::text iLIKE p_name_notlike)
              ELSE NOT(routines.routine_name::text ~* p_name_notlike) END
            ELSE true END
  GROUP BY routines.specific_name, 2, 3
  ORDER BY routines.routine_name, routines.specific_name
$_$;


ALTER FUNCTION public.doc_udf_show_simplified_signature(p_schema_name text, p_name_like text, p_name_notlike text) OWNER TO postgres;

--
-- Name: FUNCTION doc_udf_show_simplified_signature(p_schema_name text, p_name_like text, p_name_notlike text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.doc_udf_show_simplified_signature(p_schema_name text, p_name_like text, p_name_notlike text) IS 'Show name and simplified argument list about an User Defined Function (UDF), by its name or listing all functions by LIKE filter. Useful for namespace analyses';


--
-- Name: doc_udf_transparent_id(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.doc_udf_transparent_id(name_expression text, md5_digits integer DEFAULT 6) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT substr( md5(lower(name_expression)), 1, md5_digits)
$$;


ALTER FUNCTION public.doc_udf_transparent_id(name_expression text, md5_digits integer) OWNER TO postgres;

--
-- Name: FUNCTION doc_udf_transparent_id(name_expression text, md5_digits integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.doc_udf_transparent_id(name_expression text, md5_digits integer) IS 'Offers a public eternal identifier for a function, important to JOINS in the documentation schema.';


--
-- Name: doc_udf_transparent_id(text, text[], integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.doc_udf_transparent_id(name text, arguments_simplified text[], md5_digits integer DEFAULT 6) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT doc_UDF_transparent_id('public',$1,$2,$3);
$_$;


ALTER FUNCTION public.doc_udf_transparent_id(name text, arguments_simplified text[], md5_digits integer) OWNER TO postgres;

--
-- Name: FUNCTION doc_udf_transparent_id(name text, arguments_simplified text[], md5_digits integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.doc_udf_transparent_id(name text, arguments_simplified text[], md5_digits integer) IS 'Prepare parameters for doc_UDF_transparent_id().';


--
-- Name: doc_udf_transparent_id(text, text, text[], integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.doc_udf_transparent_id(schema_name text, name text, arguments_simplified text[], md5_digits integer DEFAULT 6) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT doc_UDF_transparent_id( schema_name||'.'||name||'('||array_to_string(arguments_simplified,',')||')', md5_digits)
$$;


ALTER FUNCTION public.doc_udf_transparent_id(schema_name text, name text, arguments_simplified text[], md5_digits integer) OWNER TO postgres;

--
-- Name: FUNCTION doc_udf_transparent_id(schema_name text, name text, arguments_simplified text[], md5_digits integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.doc_udf_transparent_id(schema_name text, name text, arguments_simplified text[], md5_digits integer) IS 'Prepare the standard parameters for doc_UDF_transparent_id().';


--
-- Name: dynamic_execute(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.dynamic_execute(text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
 BEGIN
    RAISE NOTICE '-- EXECUTing: %',substring(trim($1),1,52)||'...'; -- max 64 columns
    EXECUTE $1 ;  -- INTO ret; revisar para comando devolver ret booleano de sucesso
    RETURN true;
 END
$_$;


ALTER FUNCTION public.dynamic_execute(text) OWNER TO postgres;

--
-- Name: FUNCTION dynamic_execute(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.dynamic_execute(text) IS 'Executes dynamically the text as a SQL non-DQL COMMAND, like CREATE TABLE.';


--
-- Name: dynamic_query(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.dynamic_query(text) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $_$
 BEGIN
    RETURN QUERY EXECUTE $1;
 END
$_$;


ALTER FUNCTION public.dynamic_query(text) OWNER TO postgres;

--
-- Name: FUNCTION dynamic_query(text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.dynamic_query(text) IS 'Executes dynamically the text as a SQL-query (DQL command).';


--
-- Name: geohash_adjacent(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geohash_adjacent(geohash text, direction integer) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT parent || substring(
        '0123456789bcdefghjkmnpqrstuvwxyz',
        position(lastCh IN ('{p0r21436x8zb9dcf5h7kjnmqesgutwvy,bc01fg45238967deuvhjyznpkmstqrwx,14365h7k9dcfesgujnmqp0r2twvyx8zb,238967debc01fg45kmstqrwxuvhjyznp,bc01fg45238967deuvhjyznpkmstqrwx,p0r21436x8zb9dcf5h7kjnmqesgutwvy,238967debc01fg45kmstqrwxuvhjyznp,14365h7k9dcfesgujnmqp0r2twvyx8zb}'::text[])[direction*type]),
        1
      )
    FROM (
       SELECT lastch,type,
           CASE -- check for edge-cases which don't share common prefix:
              WHEN error THEN NULL
              WHEN position(lastCh IN ('{prxz,bcfguvyz,028b,0145hjnp,bcfguvyz,prxz,0145hjnp,028b}'::text[])[direction*type]) > 0 AND parent is not NULL
                   THEN geohash_adjacent(parent, direction) -- PERFORMANCE PROBLEM, need repeat your-senf once.
              ELSE parent
         END AS parent
       FROM (
         SELECT *, CASE WHEN length(geohash)=0 THEN true ELSE false END AS error
         FROM (
           SELECT lower(geohash) AS geohash,
                right(geohash,1) AS lastCh,               -- last character of hash. '4'
                left(geohash,length(geohash)-1) AS parent, -- hash without last character. '123'... Or NULL
                (length(geohash) % 2) + 1 AS type   -- +1 for PostgreSQL arrays
           ) t0
       ) prepare
    ) t2
$$;


ALTER FUNCTION public.geohash_adjacent(geohash text, direction integer) OWNER TO postgres;

--
-- Name: FUNCTION geohash_adjacent(geohash text, direction integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.geohash_adjacent(geohash text, direction integer) IS 'Optimizing.';


--
-- Name: geohash_adjacent(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geohash_adjacent(geohash text, direction text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT geohash_adjacent(geohash,translate(lower(direction),'nsew','1234')::int)
$$;


ALTER FUNCTION public.geohash_adjacent(geohash text, direction text) OWNER TO postgres;

--
-- Name: FUNCTION geohash_adjacent(geohash text, direction text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.geohash_adjacent(geohash text, direction text) IS 'wrap for geohash_adjacent(text,int).';


--
-- Name: geohash_adjacent2(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geohash_adjacent2(p_geohash text, direction integer) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT parent || substring(
        '0123456789bcdefghjkmnpqrstuvwxyz',
        position(lastCh IN ('{p0r21436x8zb9dcf5h7kjnmqesgutwvy,bc01fg45238967deuvhjyznpkmstqrwx,14365h7k9dcfesgujnmqp0r2twvyx8zb,238967debc01fg45kmstqrwxuvhjyznp,bc01fg45238967deuvhjyznpkmstqrwx,p0r21436x8zb9dcf5h7kjnmqesgutwvy,238967debc01fg45kmstqrwxuvhjyznp,14365h7k9dcfesgujnmqp0r2twvyx8zb}'::text[])[direction*type]),
        1
      )
    FROM (SELECT lower(p_geohash) AS geohash) t0,
           LATERAL cast(CASE WHEN length(geohash)=0 THEN true ELSE false END as boolean) AS error,
           LATERAL right(geohash,1) AS lastCh,               -- last character of hash. '4'
           LATERAL left(geohash,length(geohash)-1) AS parent1, -- hash without last character. '123'... Or NULL
           LATERAL cast((length(geohash) % 2) + 1 as int) AS type,   -- +1 for PostgreSQL arrays
           LATERAL cast(CASE -- check for edge-cases which don't share common prefix:
              WHEN error THEN NULL
              WHEN position(lastCh IN ('{prxz,bcfguvyz,028b,0145hjnp,bcfguvyz,prxz,0145hjnp,028b}'::text[])[direction*type]) > 0 AND parent1 is not NULL
                   THEN geohash_adjacent2(parent1, direction) -- PERFORMANCE PROBLEM, need repeat your-senf once.
              ELSE parent1
              END as text) AS parent
$$;


ALTER FUNCTION public.geohash_adjacent2(p_geohash text, direction integer) OWNER TO postgres;

--
-- Name: geohash_cover_geoms(public.geometry, text, boolean, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geohash_cover_geoms(input_geom public.geometry, input_prefix text DEFAULT ''::text, onlycontained boolean DEFAULT false, force_scan boolean DEFAULT true) RETURNS TABLE(ghs text, is_contained boolean, geom public.geometry, cut_geom public.geometry)
    LANGUAGE sql IMMUTABLE
    AS $$
  WITH t0 AS (
    SELECT ghs0,
           ghs0>'' AND (NOT(force_scan) OR input_prefix!=ghs0) AS test0,
           onlycontained IS NULL                               AS must_both,
           onlycontained IS NOT NULL AND onlycontained         AS must_contained
    FROM ( SELECT ST_GeoHash(input_geom) ) t(ghs0)
  )
   SELECT ghs0, false,
          ST_SetSRID(ST_GeomFromGeoHash(ghs0),4326) AS geom,
          input_geom AS cut_geom
   FROM t0
   WHERE test0 AND ghs0 LIKE input_prefix||'%'

  UNION ALL  -- theoretically never duplicates

   SELECT ghs, is_contained, geom, cut_geom
   FROM (
     SELECT ghs, t1.geom, t0.must_both, t0.must_contained,
            ST_Intersection(input_geom,t1.geom) as cut_geom,
            ST_Contains(input_geom,t1.geom) as is_contained
     FROM geohash_GeomsFromPrefix(input_prefix) t1, t0
     WHERE NOT(t0.test0) AND ST_Intersects(t1.geom,input_geom)
   ) t2
   WHERE must_both
         OR ( NOT(must_contained) AND NOT(is_contained) )
         OR ( must_contained AND is_contained )
$$;


ALTER FUNCTION public.geohash_cover_geoms(input_geom public.geometry, input_prefix text, onlycontained boolean, force_scan boolean) OWNER TO postgres;

--
-- Name: FUNCTION geohash_cover_geoms(input_geom public.geometry, input_prefix text, onlycontained boolean, force_scan boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.geohash_cover_geoms(input_geom public.geometry, input_prefix text, onlycontained boolean, force_scan boolean) IS 'Geometry of geohash_cover() list, assuming a region delimited by the prefix.';


--
-- Name: geohash_cover_list(public.geometry, text, boolean, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geohash_cover_list(input_geom public.geometry, input_prefix text DEFAULT ''::text, onlycontained boolean DEFAULT NULL::boolean, force_scan boolean DEFAULT true) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT array_agg(ghs)
  FROM geohash_cover_geoms($1,$2,$3,$4)
$_$;


ALTER FUNCTION public.geohash_cover_list(input_geom public.geometry, input_prefix text, onlycontained boolean, force_scan boolean) OWNER TO postgres;

--
-- Name: FUNCTION geohash_cover_list(input_geom public.geometry, input_prefix text, onlycontained boolean, force_scan boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.geohash_cover_list(input_geom public.geometry, input_prefix text, onlycontained boolean, force_scan boolean) IS 'Geohash list of covering Geohashes, assuming a region delimited by the prefix. Returns null for incompatible prefixes, and 32 itens from prefix-contained geometry.';


--
-- Name: geohash_cover_testlist(public.geometry, text, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geohash_cover_testlist(input_geom public.geometry, input_prefix text DEFAULT ''::text, force_scan boolean DEFAULT true) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT jsonb_object_agg(ghs,is_contained)
  FROM geohash_cover_geoms(input_geom, input_prefix, NULL, force_scan)
$$;


ALTER FUNCTION public.geohash_cover_testlist(input_geom public.geometry, input_prefix text, force_scan boolean) OWNER TO postgres;

--
-- Name: FUNCTION geohash_cover_testlist(input_geom public.geometry, input_prefix text, force_scan boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.geohash_cover_testlist(input_geom public.geometry, input_prefix text, force_scan boolean) IS 'Geohash jsonb object (geocode-is_contained pairs) of covering Geohashes, a wrap for geohash_cover_geoms function.';


--
-- Name: geohash_covercontour_geoms(public.geometry, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geohash_covercontour_geoms(input_geom public.geometry, ghs_len integer DEFAULT 3, prefix0 text DEFAULT ''::text) RETURNS TABLE(ghs text, geom public.geometry, cut_geom public.geometry)
    LANGUAGE sql IMMUTABLE
    AS $$

 WITH RECURSIVE rcover(ghs, is_contained, geom, cut_geom) AS (
   SELECT *
   FROM geohash_cover_geoms(input_geom,prefix0,false) t0
  UNION ALL
   SELECT c.*
   FROM rcover,
        LATERAL geohash_cover_geoms(input_geom, rcover.ghs, false) c
   WHERE length(rcover.ghs)<ghs_len AND NOT(rcover.is_contained) -- redundant AND NOT(c.is_contained)
 )
 SELECT ghs,geom,cut_geom
 FROM rcover WHERE length(ghs)=ghs_len;

$$;


ALTER FUNCTION public.geohash_covercontour_geoms(input_geom public.geometry, ghs_len integer, prefix0 text) OWNER TO postgres;

--
-- Name: FUNCTION geohash_covercontour_geoms(input_geom public.geometry, ghs_len integer, prefix0 text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.geohash_covercontour_geoms(input_geom public.geometry, ghs_len integer, prefix0 text) IS 'Geohash cover of the contour.';


--
-- Name: geohash_covercontour_geoms_splitarea(public.geometry, integer, double precision, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geohash_covercontour_geoms_splitarea(input_geom public.geometry, ghs_len integer DEFAULT 3, max_area_factor double precision DEFAULT 0.8, prefix0 text DEFAULT ''::text) RETURNS TABLE(ghs text, geom public.geometry, cut_geom public.geometry, area_factor double precision)
    LANGUAGE sql IMMUTABLE
    AS $_$
  WITH rcover_area AS (
    SELECT *, ST_Area(cut_geom)/ST_Area(geom) AS k
    FROM geohash_coverContour_geoms($1,$2,prefix0) -- all recurrency steps here.
  )
   SELECT ghs, geom, cut_geom, k
   FROM rcover_area
   WHERE k < max_area_factor
  UNION ALL  -- More one recurrency step for big area_factor cells:
   SELECT g.ghs, g.geom, g.cut_geom, ST_Area(g.cut_geom)/ST_Area(g.geom)
   FROM rcover_area r, LATERAL geohash_cover_geoms(input_geom, ghs, false) g
   WHERE r.k >= max_area_factor
$_$;


ALTER FUNCTION public.geohash_covercontour_geoms_splitarea(input_geom public.geometry, ghs_len integer, max_area_factor double precision, prefix0 text) OWNER TO postgres;

--
-- Name: geohash_geomsfromprefix(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geohash_geomsfromprefix(prefix text DEFAULT ''::text) RETURNS TABLE(ghs text, geom public.geometry)
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT prefix||x, ST_SetSRID( ST_GeomFromGeoHash(prefix||x), 4326)
  FROM unnest('{0,1,2,3,4,5,6,7,8,9,b,c,d,e,f,g,h,j,k,m,n,p,q,r,s,t,u,v,w,x,y,z}'::text[]) t(x)
$$;


ALTER FUNCTION public.geohash_geomsfromprefix(prefix text) OWNER TO postgres;

--
-- Name: FUNCTION geohash_geomsfromprefix(prefix text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.geohash_geomsfromprefix(prefix text) IS 'Return a Geohash grid, the quadrilateral geometry of each child-cell and its geocode. The parameter is the Geohash the parent-cell, that will be a prefix for all child-cells.';


--
-- Name: geohash_geomsmosaic(text[], public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geohash_geomsmosaic(ghs_array text[], geom_mask public.geometry DEFAULT NULL::public.geometry) RETURNS TABLE(ghs text, lghs integer, geom public.geometry)
    LANGUAGE sql IMMUTABLE
    AS $$
  WITH ghsgeom AS (
    SELECT ghs, length(ghs) as lghs,
           ST_SetSRID( ST_GeomFromGeoHash(ghs) , 4326) AS geom
    FROM unnest(ghs_array) t1(ghs)
  )
  ,lghsgeom AS (
    SELECT lghs, ST_UNION(geom) as ugeom
    FROM ghsgeom GROUP BY 1 ORDER BY 1
  ),final AS (
    SELECT g.ghs, g.lghs, COALESCE(
         (SELECT ST_Difference(g.geom,ST_UNION(ugeom)) FROM lghsgeom WHERE lghs>g.lghs),
         g.geom
       ) AS geom
    FROM lghsgeom l INNER JOIN ghsgeom g ON l.lghs=g.lghs
  )
    SELECT  ghs, lghs,
            CASE WHEN geom_mask IS NULL THEN geom ELSE ST_Intersection(geom,geom_mask) END
    FROM final
$$;


ALTER FUNCTION public.geohash_geomsmosaic(ghs_array text[], geom_mask public.geometry) OWNER TO postgres;

--
-- Name: FUNCTION geohash_geomsmosaic(ghs_array text[], geom_mask public.geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.geohash_geomsmosaic(ghs_array text[], geom_mask public.geometry) IS 'Return a mosaic the geometries of an arbitrary set of Geohashes, cuting, when exists, contained cells from its parent-cell.';


--
-- Name: geohash_geomsmosaic(jsonb, public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geohash_geomsmosaic(ghs_set jsonb, geom_mask public.geometry DEFAULT NULL::public.geometry) RETURNS TABLE(ghs text, lghs integer, val text, geom public.geometry)
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT ghs, lghs, ghs_set->>ghs AS val, geom
  FROM (
    SELECT * FROM geohash_GeomsMosaic( (SELECT array_agg(k) FROM jsonb_object_keys(ghs_set) t(k)), geom_mask )
  ) t
$$;


ALTER FUNCTION public.geohash_geomsmosaic(ghs_set jsonb, geom_mask public.geometry) OWNER TO postgres;

--
-- Name: FUNCTION geohash_geomsmosaic(ghs_set jsonb, geom_mask public.geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.geohash_geomsmosaic(ghs_set jsonb, geom_mask public.geometry) IS 'Wrap for geohash_GeomsMosaic(text[]), adding a val column of text-type from input key-value pairs.';


--
-- Name: geohash_geomsmosaic_jinfo(jsonb, public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geohash_geomsmosaic_jinfo(ghs_set jsonb, geom_mask public.geometry DEFAULT NULL::public.geometry) RETURNS TABLE(ghs text, info jsonb, geom public.geometry)
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT ghs,
         CASE jsonb_typeof(ghs_set->ghs)
            WHEN 'null' THEN jsonb_build_object('ghs_len',lghs)
            WHEN 'object' THEN (ghs_set->ghs) || jsonb_build_object('ghs_len',lghs)
            ELSE jsonb_build_object('ghs_len',lghs, 'ghs_items',ghs_set->ghs)
         END,
         geom
  FROM geohash_GeomsMosaic(  (SELECT array_agg(k) FROM jsonb_object_keys(ghs_set) t(k)),  geom_mask   )
$$;


ALTER FUNCTION public.geohash_geomsmosaic_jinfo(ghs_set jsonb, geom_mask public.geometry) OWNER TO postgres;

--
-- Name: FUNCTION geohash_geomsmosaic_jinfo(ghs_set jsonb, geom_mask public.geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.geohash_geomsmosaic_jinfo(ghs_set jsonb, geom_mask public.geometry) IS 'Wrap for geohash_GeomMosaic(text[]), adding a val column of jsonb-type from input key-value pairs.';


--
-- Name: geohash_geomsmosaic_jinfo(jsonb, jsonb, public.geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geohash_geomsmosaic_jinfo(ghs_set jsonb, opts jsonb, geom_mask public.geometry DEFAULT NULL::public.geometry, minimal_area double precision DEFAULT 1.0) RETURNS TABLE(ghs text, info jsonb, geom public.geometry)
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT ghs
         ,info || COALESCE(
            (SELECT jsonb_object_agg(
                 CASE WHEN substr(opt,1,7)='density' THEN (opts->>opt)||'_'||opt ELSE opt END,
                 CASE opt
                     WHEN 'area'        THEN  l.area
                     WHEN 'area_km2'    THEN  l.area/1000000.0
                     WHEN 'density'     THEN  (info->(opts->>opt))::float / l.area
                     WHEN 'density_km2' THEN  1000000.0*(info->(opts->>opt))::float / l.area
                     ELSE null
                 END) -- \agg
             FROM jsonb_object_keys(opts) t(opt) WHERE opts is not null AND opts!='{}'::jsonb
           ), -- \select
           '{}'::jsonb  -- when opts is null or empty
         ) -- \coalesce
         ,geom
  FROM geohash_GeomsMosaic_jinfo(ghs_set,geom_mask), LATERAL (SELECT ST_Area(geom,true)) l(area)
  WHERE l.area>minimal_area
$$;


ALTER FUNCTION public.geohash_geomsmosaic_jinfo(ghs_set jsonb, opts jsonb, geom_mask public.geometry, minimal_area double precision) OWNER TO postgres;

--
-- Name: FUNCTION geohash_geomsmosaic_jinfo(ghs_set jsonb, opts jsonb, geom_mask public.geometry, minimal_area double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.geohash_geomsmosaic_jinfo(ghs_set jsonb, opts jsonb, geom_mask public.geometry, minimal_area double precision) IS 'Wrap for geohash_GeomsMosaic_jinfo, adding optional area and density values';


--
-- Name: geohash_neighbors_brute(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geohash_neighbors_brute(hash text) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
 SELECT
  array_agg(ST_GeoHash(
    ST_MakePoint(px, py),
    len
  ))
 FROM
  (SELECT LENGTH(hash) AS len) t,
  LATERAL ST_PointFromGeoHash(hash, len) AS pt,
  Generate_Series(-1, 1, 1) AS x,
  Generate_Series(-1, 1, 1) AS y,
  LATERAL CAST(ST_X(pt) + x*360.0/(2^CEIL(len / 2.0)*4^len) AS FLOAT) AS px,
  LATERAL CAST(ST_Y(pt) + y*180.0/(2^FLOOR(len / 2.0)*4^len) AS FLOAT) AS py
 WHERE NOT (x = 0 AND y = 0)
       AND NOT (px < -180.0 OR px > 180.0)
       AND NOT (py < -90.0 OR py > 90.0)
$$;


ALTER FUNCTION public.geohash_neighbors_brute(hash text) OWNER TO postgres;

--
-- Name: FUNCTION geohash_neighbors_brute(hash text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.geohash_neighbors_brute(hash text) IS 'Obtains Geohash neighbors by a brute-force algorithm. With erros, see https://gis.stackexchange.com/a/431410/7505';


--
-- Name: geohash_neighbours(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geohash_neighbours(geohash text) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT array[
    geohash_adjacent(geohash, 1),                      -- N
    geohash_adjacent(geohash_adjacent(geohash, 1), 3), -- NE
    geohash_adjacent(geohash, 3),                      -- E
    geohash_adjacent(geohash_adjacent(geohash, 2), 3), -- SE
    geohash_adjacent(geohash, 2),                      -- S
    geohash_adjacent(geohash_adjacent(geohash, 2), 4), -- SW
    geohash_adjacent(geohash, 4),                      -- W
    geohash_adjacent(geohash_adjacent(geohash, 1), 4)  -- NW
  ]
$$;


ALTER FUNCTION public.geohash_neighbours(geohash text) OWNER TO postgres;

--
-- Name: geojson_readfile_features(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geojson_readfile_features(f text) RETURNS TABLE(fname text, feature_id integer, geojson_type text, feature_type text, properties jsonb, geom public.geometry)
    LANGUAGE sql
    AS $$
   SELECT fname, (ROW_NUMBER() OVER())::int, -- feature_id,
          geojson_type, feature->>'type',    -- feature_type,
          jsonb_objslice('name',feature) || feature->'properties', -- properties and name.
          -- see CRS problems at https://gis.stackexchange.com/questions/60928/
          ST_GeomFromGeoJSON(  crs || (feature->'geometry')  ) AS geom
   FROM (
      SELECT j->>'file' AS fname,
             jsonb_objslice('crs',j) AS crs,
             j->>'type' AS geojson_type,
             jsonb_array_elements(j->'features') AS feature
      FROM ( SELECT pg_read_file(f)::JSONb AS j ) jfile
   ) t2
$$;


ALTER FUNCTION public.geojson_readfile_features(f text) OWNER TO postgres;

--
-- Name: FUNCTION geojson_readfile_features(f text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.geojson_readfile_features(f text) IS 'Reads a small GeoJSON file and transforms it into a table with a geometry column.';


--
-- Name: geojson_readfile_features_jgeom(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geojson_readfile_features_jgeom(file text, file_id integer DEFAULT NULL::integer) RETURNS TABLE(file_id integer, feature_id integer, feature_type text, properties jsonb, jgeom jsonb)
    LANGUAGE sql
    AS $$
   SELECT file_id, (ROW_NUMBER() OVER())::int AS subfeature_id,
          subfeature->>'type' AS subfeature_type,
          subfeature->'properties' AS properties,
          crs || (subfeature->'geometry') AS jgeom
   FROM (
      SELECT j->>'type' AS geojson_type,
             jsonb_objslice('crs',j) AS crs,
             jsonb_array_elements(j->'features') AS subfeature
      FROM ( SELECT pg_read_file(file)::JSONb AS j ) jfile
   ) t2
$$;


ALTER FUNCTION public.geojson_readfile_features_jgeom(file text, file_id integer) OWNER TO postgres;

--
-- Name: FUNCTION geojson_readfile_features_jgeom(file text, file_id integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.geojson_readfile_features_jgeom(file text, file_id integer) IS 'Reads a big GeoJSON file and transforms it into a table with a json-geometry column.';


--
-- Name: geojson_readfile_headers(text, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geojson_readfile_headers(f text, missing_ok boolean DEFAULT false) RETURNS jsonb
    LANGUAGE sql
    AS $$
  SELECT j || jsonb_build_object( 'file',f,  'content_header', pg_read_file(f)::JSONB - 'features' )
  FROM to_jsonb( pg_stat_file(f,missing_ok) ) t(j)
  WHERE j IS NOT NULL
$$;


ALTER FUNCTION public.geojson_readfile_headers(f text, missing_ok boolean) OWNER TO postgres;

--
-- Name: geojson_repretty(json, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geojson_repretty(j json, blocksize integer DEFAULT 4) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT geojson_repretty( $1::text, $2 );
$_$;


ALTER FUNCTION public.geojson_repretty(j json, blocksize integer) OWNER TO postgres;

--
-- Name: FUNCTION geojson_repretty(j json, blocksize integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.geojson_repretty(j json, blocksize integer) IS 'Wrap for geojson_repretty()';


--
-- Name: geojson_repretty(jsonb, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geojson_repretty(j jsonb, blocksize integer DEFAULT 4) RETURNS text
    LANGUAGE sql
    AS $$
    SELECT geojson_repretty( jsonb_pretty(j), blocksize );
$$;


ALTER FUNCTION public.geojson_repretty(j jsonb, blocksize integer) OWNER TO postgres;

--
-- Name: FUNCTION geojson_repretty(j jsonb, blocksize integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.geojson_repretty(j jsonb, blocksize integer) IS 'Wrap for geojson_repretty(geojson_repretty())';


--
-- Name: geojson_repretty(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.geojson_repretty(j text, blocksize integer DEFAULT 4) RETURNS text
    LANGUAGE sql
    AS $$
 WITH pre AS (
 SELECT t.id,
        CASE WHEN substring(t.lin,1,3)='##[' THEN substring(t.lin,3) ELSE  t.lin END AS lin,
        CASE WHEN substring(t.lin,1,3)='##[' THEN 1+t.id%blocksize   ELSE 0 END AS mod
 FROM  regexp_split_to_table(
           regexp_replace(
                replace(j, '  ',' '),
                '\s*\[\s*([\-\d\.]+)\s*,\s*([\-\d\.]+)\s*\](,)?',
                E'\n##[\\1,\\2]\\3',
                'g'
           ),
       E'\n'
       ) with ordinality t(lin,id)
  )
  
  SELECT string_agg(sp||lin2,E'\n')
FROM (
SELECT id6, CASE WHEN mod=0 THEN '' ELSE '          ' END as sp,
       string_agg(lin,' ') as lin2
FROM ( -- tg
SELECT *, CASE WHEN id5 is null THEN LAG(id5) over() else id5 END as id6
FROM (
SELECT *, CASE WHEN id4 is null THEN LAG(id4) over() else id4 END as id5
FROM (
SELECT *, CASE WHEN id3 is null THEN LAG(id3) over() else id3 END as id4
FROM (
SELECT *, CASE WHEN id2 is null THEN LAG(id2) over() else id2 END as id3
FROM (
SELECT *, CASE WHEN mod=0 THEN id WHEN open_id is null THEN LAG(open_id) over() else open_id END as id2
FROM (
SELECT *, CASE WHEN open_block THEN id else null END open_id, 
       CASE WHEN close_block THEN id else null END close_id
FROM (
   select *, mod>LEAD(mod) over() AND mod!=0 as close_block,
            (mod<LAG(mod) over() AND mod!=0) or (0=LAG(mod) over() AND mod>0) as open_block
   from pre
) t
) t2
) t3
) t4
) t5
) t6
) tg
GROUP BY 1,2 ORDER BY 1 -- -- id6,sp,lin2
) t7
$$;


ALTER FUNCTION public.geojson_repretty(j text, blocksize integer) OWNER TO postgres;

--
-- Name: FUNCTION geojson_repretty(j text, blocksize integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.geojson_repretty(j text, blocksize integer) IS 'Alternative for jsonb_pretty() to return GeoJSON pretty and coordinates in compact form';


--
-- Name: gridcellgeom_areafrac(public.geometry, public.geometry[], public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.gridcellgeom_areafrac(p_orig_geom public.geometry, p_targ_geom public.geometry[], p_excl_geom public.geometry DEFAULT NULL::public.geometry) RETURNS double precision[]
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT array_agg( ST_Area(ST_Intersection(p_orig_geom,tgeom)) / area )
  FROM (
    SELECT ST_Area(CASE
                   WHEN p_excl_geom IS NOT NULL AND p_orig_geom && p_excl_geom
                   THEN ST_Difference(p_orig_geom,p_excl_geom)
                   ELSE p_orig_geom
                   END) area,
           unnest(p_targ_geom) tgeom
  ) t
$$;


ALTER FUNCTION public.gridcellgeom_areafrac(p_orig_geom public.geometry, p_targ_geom public.geometry[], p_excl_geom public.geometry) OWNER TO postgres;

--
-- Name: FUNCTION gridcellgeom_areafrac(p_orig_geom public.geometry, p_targ_geom public.geometry[], p_excl_geom public.geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.gridcellgeom_areafrac(p_orig_geom public.geometry, p_targ_geom public.geometry[], p_excl_geom public.geometry) IS 'Area fraction of an original cell covered by a set of target cells. Matrix used in the original-to-target grid value convertion.';


--
-- Name: gridcellgeom_dump(public.geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.gridcellgeom_dump(p_geom public.geometry, p_minlength double precision DEFAULT NULL::double precision) RETURNS TABLE(geom public.geometry)
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT (pt).geom
    FROM ( SELECT ST_DumpPoints(CASE WHEN p_minlength>0.0 THEN ST_Segmentize(p_geom,p_minlength) ELSE p_geom END) ) t1(pt)
    UNION ALL
    SELECT ST_Centroid(p_geom)
$$;


ALTER FUNCTION public.gridcellgeom_dump(p_geom public.geometry, p_minlength double precision) OWNER TO postgres;

--
-- Name: FUNCTION gridcellgeom_dump(p_geom public.geometry, p_minlength double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.gridcellgeom_dump(p_geom public.geometry, p_minlength double precision) IS 'Sample points from an square grid-cell, with optional segmentize. Supposing border-centroid distance greater than p_minlength.';


--
-- Name: hex_to_varbit(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hex_to_varbit(h text) RETURNS bit varying
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$
 SELECT ('X' || $1)::varbit
$_$;


ALTER FUNCTION public.hex_to_varbit(h text) OWNER TO postgres;

--
-- Name: FUNCTION hex_to_varbit(h text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.hex_to_varbit(h text) IS 'Fast and case-insensitive hexadecimal conversion to varbit.';


--
-- Name: iif(boolean, anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.iif(condition boolean, true_result anyelement, false_result anyelement) RETURNS anyelement
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT CASE WHEN condition THEN true_result ELSE false_result END
$$;


ALTER FUNCTION public.iif(condition boolean, true_result anyelement, false_result anyelement) OWNER TO postgres;

--
-- Name: FUNCTION iif(condition boolean, true_result anyelement, false_result anyelement); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.iif(condition boolean, true_result anyelement, false_result anyelement) IS 'Immediate IF. Sintax sugar for the most frequent CASE-WHEN. Avoid with text, need explicit cast.';


--
-- Name: ints_to_interleavedbits(integer, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ints_to_interleavedbits(x integer, y integer, len integer DEFAULT 32, is_half boolean DEFAULT NULL::boolean) RETURNS bit varying
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT vbit_interleave( substring(x::bit(32),33-len),  substring( y::bit(32), 33-len+CASE WHEN is_half THEN 1 ELSE 0 END ) )
$$;


ALTER FUNCTION public.ints_to_interleavedbits(x integer, y integer, len integer, is_half boolean) OWNER TO postgres;

--
-- Name: json_pretty_lines(json, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.json_pretty_lines(j_input json, opt integer DEFAULT 0) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
 -- json input (not jsonB!) 
 SELECT CASE opt
   WHEN 0  THEN j_input::text
   WHEN 1  THEN jsonb_pretty(j_input::jsonb)
   WHEN 2  THEN regexp_replace(regexp_replace(j_input::text, ' ?\{"type": "Feature", "geometry":\n', '{"type": "Feature", "geometry": ', 'g'), ' ?\{"type": "Feature", "geometry":', E'\n{"type": "Feature", "geometry":', 'g') || E'\n'  -- GeoJSON
   WHEN 3  THEN replace(regexp_replace(j_input::text, ' ?\{"type": "Feature", "geometry":\n', '{"type": "Feature", "geometry": ', 'g'), ' ', '') || E'\n'  -- GeoJSON
   WHEN 4  THEN json_strip_nulls(j_input)::text -- canonical compact form, same as jsonb_pretty(j,true)
   END
$$;


ALTER FUNCTION public.json_pretty_lines(j_input json, opt integer) OWNER TO postgres;

--
-- Name: FUNCTION json_pretty_lines(j_input json, opt integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.json_pretty_lines(j_input json, opt integer) IS 'Format JSON like jsonB_pretty() to return one item per line: 0 = to_text with no formating, 1=standard Pretty, 2=GeoJSON preserving type, 3=GeoJSON removing type, 4=compact form';


--
-- Name: jsonb_array_to_text_array(jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_array_to_text_array(_js jsonb) RETURNS text[]
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    BEGIN ATOMIC
 SELECT ARRAY( SELECT jsonb_array_elements_text(_js) AS jsonb_array_elements_text) AS "array";
END;


ALTER FUNCTION public.jsonb_array_to_text_array(_js jsonb) OWNER TO postgres;

--
-- Name: FUNCTION jsonb_array_to_text_array(_js jsonb); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.jsonb_array_to_text_array(_js jsonb) IS 'JSONB-to-SQL_text arrays optimized convertion, for pg14+. See https://dba.stackexchange.com/a/54289/90651';


--
-- Name: jsonb_object_keys_asarray(jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_object_keys_asarray(j jsonb) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT  array_agg(x) FROM jsonb_object_keys(j) t(x)
$$;


ALTER FUNCTION public.jsonb_object_keys_asarray(j jsonb) OWNER TO postgres;

--
-- Name: jsonb_object_length(jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_object_length(jsonb) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $_$
  -- Integer because never expect a big JSON, with more tham 10^9 or 2147483647 items
  SELECT count(*)::int FROM jsonb_object_keys($1)  -- faster tham jsonb_each()
$_$;


ALTER FUNCTION public.jsonb_object_length(jsonb) OWNER TO postgres;

--
-- Name: jsonb_objslice(text[], jsonb, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_objslice(keys text[], j jsonb, renames text[] DEFAULT NULL::text[]) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT COALESCE( jsonb_object_agg(COALESCE(rename,key),j->key),   '{}'::jsonb )
    FROM (SELECT unnest(keys), unnest(renames)) t(key,rename)
$$;


ALTER FUNCTION public.jsonb_objslice(keys text[], j jsonb, renames text[]) OWNER TO postgres;

--
-- Name: jsonb_objslice(jsonpath, jsonb, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_objslice(keypath jsonpath, j jsonb, keyname text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT COALESCE( jsonb_build_object(keyname,j_0), '{}'::jsonb )
    FROM jsonb_path_query_first(j, keypath) t(j_0)
$$;


ALTER FUNCTION public.jsonb_objslice(keypath jsonpath, j jsonb, keyname text) OWNER TO postgres;

--
-- Name: jsonb_objslice(text, jsonb, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_objslice(key text, j jsonb, rename text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT COALESCE( jsonb_build_object( COALESCE(rename,key) , j->key ), '{}'::jsonb )
$$;


ALTER FUNCTION public.jsonb_objslice(key text, j jsonb, rename text) OWNER TO postgres;

--
-- Name: FUNCTION jsonb_objslice(key text, j jsonb, rename text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.jsonb_objslice(key text, j jsonb, rename text) IS 'Get the first path-result as keyname-result object.';


--
-- Name: jsonb_pg_stat_file(text, boolean, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_pg_stat_file(f text, add_md5 boolean DEFAULT false, missing_ok boolean DEFAULT false) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  -- = indest.get_file_meta(). Falta emitir erro quando file not found!
  -- usar (j->'size')::bigint+1 como pg_read(size)!  para poder usar missing nele.
  SELECT j
         || jsonb_build_object( 'file',f )
         || CASE WHEN add_md5 THEN jsonb_build_object( 'hash_md5', md5(pg_read_binary_file(f,0,900000000)) ) ELSE '{}'::jsonb END
  FROM to_jsonb( pg_stat_file(f,missing_ok) ) t(j)
  WHERE j IS NOT NULL
$$;


ALTER FUNCTION public.jsonb_pg_stat_file(f text, add_md5 boolean, missing_ok boolean) OWNER TO postgres;

--
-- Name: FUNCTION jsonb_pg_stat_file(f text, add_md5 boolean, missing_ok boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.jsonb_pg_stat_file(f text, add_md5 boolean, missing_ok boolean) IS 'Convert pg_stat_file() information in JSONb, adding option to include MD5 digest and filename.';


--
-- Name: jsonb_pretty(jsonb, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_pretty(jsonb, compact boolean) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT CASE -- warning: incidental behaviour of strip_nulls.
    WHEN $2 THEN  json_strip_nulls($1::json)::text
    ELSE  jsonb_pretty($1)
  END
  -- from https://stackoverflow.com/a/27536804/287948
  -- pg16+ back to https://stackoverflow.com/a/70828187/287948
$_$;


ALTER FUNCTION public.jsonb_pretty(jsonb, compact boolean) OWNER TO postgres;

--
-- Name: FUNCTION jsonb_pretty(jsonb, compact boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.jsonb_pretty(jsonb, compact boolean) IS 'Extends jsonb_pretty() to return canonical compact form when true';


--
-- Name: jsonb_pretty_lines(jsonb, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_pretty_lines(j_input jsonb, opt integer DEFAULT 0) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
 -- jsonB input
 SELECT CASE opt
   WHEN 0  THEN j_input::text
   WHEN 1  THEN jsonb_pretty(j_input)
   WHEN 2  THEN regexp_replace(regexp_replace(j_input::text, ' ?\{"type": "Feature", "geometry":\n', '{"type": "Feature", "geometry": ', 'g'), ' ?\{"type": "Feature", "geometry":', E'\n{"type": "Feature", "geometry":', 'g') || E'\n'  -- GeoJSON
   WHEN 3  THEN replace(regexp_replace(j_input::text, ' ?\{"type": "Feature", "geometry":\n', '{"type": "Feature", "geometry": ', 'g'), ' ', '') || E'\n'  -- GeoJSON
   WHEN 4  THEN jsonb_pretty(j_input,true)  -- canonical compact form
   END
$$;


ALTER FUNCTION public.jsonb_pretty_lines(j_input jsonb, opt integer) OWNER TO postgres;

--
-- Name: FUNCTION jsonb_pretty_lines(j_input jsonb, opt integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.jsonb_pretty_lines(j_input jsonb, opt integer) IS 'Alternatives for jsonb_pretty() to return one item per line: 0 = to_text with no formating, 1=standard pretty, 2=GeoJSON preserving type, 3=GeoJSON removing type, 4=compact form';


--
-- Name: jsonb_rename(jsonb, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_rename(js jsonb, nmold text, nmnew text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT js - nmold || jsonb_build_object(nmnew, js->nmold)
$$;


ALTER FUNCTION public.jsonb_rename(js jsonb, nmold text, nmnew text) OWNER TO postgres;

--
-- Name: jsonb_strip_nulls(jsonb, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_strip_nulls(p_input jsonb, p_ret_empty boolean) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT CASE
     WHEN p_ret_empty THEN x
     WHEN x='{}'::JSONb THEN NULL
     ELSE x END
  FROM ( SELECT jsonb_strip_nulls(p_input) ) t(x)
$$;


ALTER FUNCTION public.jsonb_strip_nulls(p_input jsonb, p_ret_empty boolean) OWNER TO postgres;

--
-- Name: FUNCTION jsonb_strip_nulls(p_input jsonb, p_ret_empty boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.jsonb_strip_nulls(p_input jsonb, p_ret_empty boolean) IS 'Extends jsonb_strip_nulls to return NULL instead empty';


--
-- Name: jsonb_summable_check(jsonb, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_summable_check(jsonb, text DEFAULT 'numeric'::text) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
  -- CORE function of jsonb_summable_*().
  SELECT not($1 IS NULL OR jsonb_typeof($1)!='object' OR $1='{}'::jsonb)
        AND CASE
          WHEN $2='numeric' OR $2='float' THEN (SELECT bool_and(jsonb_typeof(value)='number') FROM jsonb_each($1))
          ELSE (SELECT bool_and(value ~ '^\d+$') FROM jsonb_each_text($1))
          END
$_$;


ALTER FUNCTION public.jsonb_summable_check(jsonb, text) OWNER TO postgres;

--
-- Name: jsonb_summable_maxval(jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_summable_maxval(jsonb) RETURNS bigint
    LANGUAGE sql IMMUTABLE
    AS $_$
  -- CORE function of jsonb_summable_*(), change also the "returns" to bigint or float.
  SELECT max(value::bigint) from jsonb_each_text($1)
$_$;


ALTER FUNCTION public.jsonb_summable_maxval(jsonb) OWNER TO postgres;

--
-- Name: jsonb_summable_merge(jsonb[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_summable_merge(jsonb[]) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
 DECLARE
  x JSONb;
  j JSONb;
 BEGIN
    IF $1 IS NULL OR array_length($1,1)=0 THEN
      RETURN NULL;
    ELSEIF array_length($1,1)=1 THEN
      RETURN $1[1];
    END IF;
    x := $1[1];
    FOREACH j IN ARRAY $1[2:] LOOP
      x:= jsonb_summable_merge(x,j);
    END LOOP;
    RETURN x;
 END
$_$;


ALTER FUNCTION public.jsonb_summable_merge(jsonb[]) OWNER TO postgres;

--
-- Name: jsonb_summable_merge(jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_summable_merge(jsonb, jsonb) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $_$
  -- CORE function of jsonb_summable_*().
  SELECT CASE
    WHEN emp1 AND emp2 THEN NULL
    WHEN emp2 THEN $1
    WHEN emp1 THEN $2
    ELSE $1 || (
      -- CHANGE replacing ::int by your choice of type in the jsonb_summable_check(x,choice)
      SELECT jsonb_object_agg(
          COALESCE(key,'')
          , value::int + COALESCE(($1->>key)::int,0)
        )
      FROM jsonb_each_text($2)
    ) END
  FROM (
   SELECT $1 IS NULL OR jsonb_typeof($1)!='object' OR $1='{}'::jsonb emp1,
          $2 IS NULL OR jsonb_typeof($2)!='object' OR $2='{}'::jsonb emp2
  ) t
$_$;


ALTER FUNCTION public.jsonb_summable_merge(jsonb, jsonb) OWNER TO postgres;

--
-- Name: jsonb_summable_output(jsonb, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_summable_output(p_j jsonb, p_sep text DEFAULT ', '::text, p_prefix text DEFAULT ''::text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT array_to_string(
    array_agg(concat(p_prefix,key,':',value)) FILTER (WHERE key is not null)
    ,p_sep
  )
  FROM jsonb_each_text(p_j)
$$;


ALTER FUNCTION public.jsonb_summable_output(p_j jsonb, p_sep text, p_prefix text) OWNER TO postgres;

--
-- Name: jsonb_summable_values(jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_summable_values(jsonb) RETURNS integer[]
    LANGUAGE sql IMMUTABLE
    AS $_$
  -- CORE function of jsonb_summable_*().
  -- CHANGE replacing ::int by your choice of type in the jsonb_summable_check(x,choice)
  SELECT array_agg(value::int) from jsonb_each_text($1)
$_$;


ALTER FUNCTION public.jsonb_summable_values(jsonb) OWNER TO postgres;

--
-- Name: jsonb_to_bigints(jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_to_bigints(p_j jsonb) RETURNS bigint[]
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT array_agg(value::text::bigint) FROM jsonb_array_elements($1)
$_$;


ALTER FUNCTION public.jsonb_to_bigints(p_j jsonb) OWNER TO postgres;

--
-- Name: FUNCTION jsonb_to_bigints(p_j jsonb); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.jsonb_to_bigints(p_j jsonb) IS 'Casts JSON array of non-floating numbers to SQL array of bigints.';


--
-- Name: jsonb_to_jsonlines(jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.jsonb_to_jsonlines(jsonb) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
    SELECT string_agg( json_strip_nulls(x::json)::text, E'\n')
    FROM  jsonb_array_elements($1) t(x)
$_$;


ALTER FUNCTION public.jsonb_to_jsonlines(jsonb) OWNER TO postgres;

--
-- Name: FUNCTION jsonb_to_jsonlines(jsonb); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.jsonb_to_jsonlines(jsonb) IS 'Formats JSON as https://JSONlines.org streaming standard';


--
-- Name: lexname_to_unix(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lexname_to_unix(p_lexname text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT string_agg(initcap(p),'') FROM regexp_split_to_table($1,'\.') t(p)
$_$;


ALTER FUNCTION public.lexname_to_unix(p_lexname text) OWNER TO postgres;

--
-- Name: FUNCTION lexname_to_unix(p_lexname text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.lexname_to_unix(p_lexname text) IS 'Convert URN LEX jurisdiction string to camel-case filename for Unix-like file systems.';


--
-- Name: pg_csv_head(text, text, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pg_csv_head(filename text, separator text DEFAULT ','::text, linesize bigint DEFAULT 9000) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT regexp_split_to_array(replace(s,'"',''), separator)
  FROM regexp_split_to_table(  pg_read_file(filename,0,linesize,true),  E'\n') t(s)
  LIMIT 1
$$;


ALTER FUNCTION public.pg_csv_head(filename text, separator text, linesize bigint) OWNER TO postgres;

--
-- Name: FUNCTION pg_csv_head(filename text, separator text, linesize bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.pg_csv_head(filename text, separator text, linesize bigint) IS 'Devolve array do header de um arquivo CSV com separador estrito, lendo apenas primeiros bytes.';


--
-- Name: pg_csv_head_tojsonb(text, boolean, text, bigint, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pg_csv_head_tojsonb(filename text, tolower boolean DEFAULT false, separator text DEFAULT ','::text, linesize bigint DEFAULT 9000, is_idx_json boolean DEFAULT true) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $_$
    SELECT  jsonb_object_agg(
      CASE WHEN tolower THEN lower(x) ELSE x END ,
      ordinality - CASE WHEN is_idx_json THEN 1 ELSE 0 END
    )
    FROM unnest( pg_csv_head($1,$3,$4) ) WITH ORDINALITY x
$_$;


ALTER FUNCTION public.pg_csv_head_tojsonb(filename text, tolower boolean, separator text, linesize bigint, is_idx_json boolean) OWNER TO postgres;

--
-- Name: pg_relation_lines(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pg_relation_lines(p_tablename text) RETURNS bigint
    LANGUAGE plpgsql
    AS $_$
  DECLARE
    lines bigint;
  BEGIN
      EXECUTE 'SELECT COUNT(*) FROM '|| $1 INTO lines;
      RETURN lines;
  END
$_$;


ALTER FUNCTION public.pg_relation_lines(p_tablename text) OWNER TO postgres;

--
-- Name: FUNCTION pg_relation_lines(p_tablename text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.pg_relation_lines(p_tablename text) IS 'run COUNT(*), a complement for pg_relation_size() function.';


--
-- Name: pg_tablestruct_dump_totext(text, text[], text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pg_tablestruct_dump_totext(p_tabname text, p_ignore text[] DEFAULT NULL::text[], p_add text[] DEFAULT NULL::text[]) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT array_agg(col||' '||datatype) || COALESCE(p_add,array[]::text[])
  FROM (
    SELECT -- attrelid::regclass AS tbl,
           attname            AS col
         , atttypid::regtype  AS datatype
    FROM   pg_attribute
    WHERE  attrelid = p_tabname::regclass  -- table name, optionally schema-qualified
    AND    attnum > 0
    AND    NOT attisdropped
    AND    ( p_ignore IS null OR NOT(attname=ANY(p_ignore)) )
    ORDER  BY attnum
  ) t
$$;


ALTER FUNCTION public.pg_tablestruct_dump_totext(p_tabname text, p_ignore text[], p_add text[]) OWNER TO postgres;

--
-- Name: FUNCTION pg_tablestruct_dump_totext(p_tabname text, p_ignore text[], p_add text[]); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.pg_tablestruct_dump_totext(p_tabname text, p_ignore text[], p_add text[]) IS 'Extraxcts column descriptors of a table. Used in ingest.fdw_generate_getclone() function. Optional adds to the end.';


--
-- Name: rel_columns(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rel_columns(p_relname text, p_schemaname text DEFAULT NULL::text) RETURNS text[]
    LANGUAGE sql
    AS $_$
   SELECT --attrelid::regclass AS tbl,  atttypid::regtype  AS datatype
        array_agg(attname::text ORDER  BY attnum)
   FROM   pg_attribute
   WHERE  attrelid = (CASE
             WHEN strpos($1, '.')>0 THEN $1
             WHEN $2 IS NULL THEN 'public.'||$1
             ELSE $2||'.'||$1
          END)::regclass
   AND    attnum > 0
   AND    NOT attisdropped
$_$;


ALTER FUNCTION public.rel_columns(p_relname text, p_schemaname text) OWNER TO postgres;

--
-- Name: round(double precision[], double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.round(input double precision[], accuracy double precision) RETURNS double precision[]
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT array_agg(round(x,accuracy)) FROM unnest(input) t(x)
$$;


ALTER FUNCTION public.round(input double precision[], accuracy double precision) OWNER TO postgres;

--
-- Name: FUNCTION round(input double precision[], accuracy double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.round(input double precision[], accuracy double precision) IS 'ROUND array of floats by accuracy. A wrap for ROUND(float,float).';


--
-- Name: round(double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.round(input double precision, accuracy double precision) RETURNS double precision
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT (ROUND($1/accuracy)*accuracy)::numeric(99,9)::float
  -- SELECT ROUND($1/accuracy)*accuracy
$_$;


ALTER FUNCTION public.round(input double precision, accuracy double precision) OWNER TO postgres;

--
-- Name: FUNCTION round(input double precision, accuracy double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.round(input double precision, accuracy double precision) IS 'ROUND by accuracy. See Round9 at https://stackoverflow.com/a/20933882/287948';


--
-- Name: round(double precision, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.round(double precision, integer) RETURNS numeric
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$
   SELECT ROUND($1::numeric,$2)
$_$;


ALTER FUNCTION public.round(double precision, integer) OWNER TO postgres;

--
-- Name: FUNCTION round(double precision, integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.round(double precision, integer) IS 'Cast for ROUND(float,x). Useful for SUM, AVG, etc. See also https://stackoverflow.com/a/20934099/287948.';


--
-- Name: round_minutes(timestamp without time zone, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.round_minutes(input timestamp without time zone, countunit_minutes integer) RETURNS timestamp without time zone
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT
     date_trunc('hour', $1)
     +  cast((countUnit_minutes::varchar||' min') as interval)
     * round(
       (date_part('minute',$1)::float + date_part('second',$1)/ 60.)::float
       / countUnit_minutes::float
     )
$_$;


ALTER FUNCTION public.round_minutes(input timestamp without time zone, countunit_minutes integer) OWNER TO postgres;

--
-- Name: round_minutes(timestamp without time zone, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.round_minutes(input timestamp without time zone, countunit_minutes integer, str_format text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT to_char( round_minutes($1,countUnit_minutes), str_format)
$_$;


ALTER FUNCTION public.round_minutes(input timestamp without time zone, countunit_minutes integer, str_format text) OWNER TO postgres;

--
-- Name: shapedescr_sizes(public.geometry, integer, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.shapedescr_sizes(gbase public.geometry, p_decplacesof_zero integer DEFAULT 6, p_dwmin double precision DEFAULT 99999999.0, p_deltaimpact double precision DEFAULT 9999.0) RETURNS double precision[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
  DECLARE
    ret float[];
    dw float;
    b float;
    L_estim float;
    H_estim float;
    aorig float;
    gaux geometry;
    g1 geometry;
    A0 float;
    A1 float;
    c float;
    delta float;
    per float;
    errcod float;
  BEGIN
    errcod=0.0;
    IF gbase IS NULL OR NOT(ST_IsClosed(gbase)) THEN
        errcod=1;                  -- ERROR1 (die)
        RAISE EXCEPTION 'error %: invalid input geometry',errcod;
    END IF;
    A0 := ST_Area(gbase);
    per := st_perimeter(gbase);
    dw := sqrt(A0)/p_deltaimpact;
    IF dw>p_dwmin THEN dw:=p_dwmin; END IF;
    g1 = ST_Buffer(gbase,dw);
    A1 = ST_area(g1);
    IF A0>A1 THEN
        errcod=10;                 -- ERROR2 (die)
        RAISE EXCEPTION 'error %: invalid buffer/geometry with A0=% g.t. A1=%',errcod,A0,A1;
    END IF;
    IF (A1-A0)>1.001*dw*per THEN
        gaux := ST_Buffer(g1,-dw);  -- closing operation.
        A0 = ST_Area(gaux);         -- changed area
        per := ST_Perimeter(gaux);  -- changed
        errcod:=errcod + 0.1;       -- Warning3
    END IF;
    C := 2.0*dw;
    b := -(A1-A0)/C+C;
    delta := b^2-4.0*A0;
    IF delta<0.0 AND round(delta,p_decplacesof_zero)<=0.0 THEN
           delta=0.0; -- for regular shapes like the square
           errcod:=errcod + 0.01;  -- Warning2
    END IF;
    IF delta<0.0 THEN
        L_estim := NULL;
        H_estim := NULL;
        errcod:=errcod+100;        -- ERROR3
    ELSE
        L_estim := (-b + sqrt(delta))/2.0;
        H_estim := (-b - sqrt(delta))/2.0;
    END IF;
    IF abs(A0-L_estim*H_estim)>0.001 THEN
        errcod:=errcod + 0.001;    -- Warning1
    END IF;
    ret := array[L_estim,H_estim,a0,per,dw,errcod];
    return ret;
  END
$$;


ALTER FUNCTION public.shapedescr_sizes(gbase public.geometry, p_decplacesof_zero integer, p_dwmin double precision, p_deltaimpact double precision) OWNER TO postgres;

--
-- Name: sql_parse_selectcols(text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sql_parse_selectcols(selcols text[]) RETURNS text[]
    LANGUAGE sql
    AS $_$
   SELECT array_agg( CASE
      WHEN $1 IS NULL OR p_as IS NULL OR array_length(p_as,1)=0 OR array_length(p_as,1)>2 THEN NULL
      WHEN array_length(p_as,1)=2 THEN p_as[1] ||' AS '||p_as[2]
      ELSE sql_parse_selectcols_simple(p_as[1])
      END )
   FROM (
     SELECT i,regexp_split_to_array(x, '\s+as\s+','i') p_as
     FROM UNNEST($1) WITH ORDINALITY t1(x,i)
   ) t2
$_$;


ALTER FUNCTION public.sql_parse_selectcols(selcols text[]) OWNER TO postgres;

--
-- Name: sql_parse_selectcols_simple(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sql_parse_selectcols_simple(s text) RETURNS text
    LANGUAGE sql
    AS $_$
   SELECT CASE
       WHEN $1 IS NULL OR p[1]='' OR array_length(p,1)>2 THEN NULL
       WHEN array_length(p,1)=1 THEN p[1]
       ELSE p[1] ||' AS '||p[2]
       END
   FROM (SELECT regexp_split_to_array(trim($1),'\s+') p) t
$_$;


ALTER FUNCTION public.sql_parse_selectcols_simple(s text) OWNER TO postgres;

--
-- Name: srid_utmzone_from4326(public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.srid_utmzone_from4326(p_geom public.geometry) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $$
   SELECT CASE WHEN x[1]::boolean THEN 32600  ELSE 32700 END  +  x[2]
   FROM (SELECT utmzone_from4326(p_geom)) t(x)
$$;


ALTER FUNCTION public.srid_utmzone_from4326(p_geom public.geometry) OWNER TO postgres;

--
-- Name: srid_utmzone_title(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.srid_utmzone_title(p_srid integer) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  -- SIRGAS or WGS 84. At srtext the PROJCS keyword is the "PROJ Coordinate System title"
  SELECT substr(srtext, 9, 21 + CASE WHEN p_srid<32600 THEN 5 ELSE 0 END)
  FROM  spatial_ref_sys
  WHERE srid=p_srid;
$$;


ALTER FUNCTION public.srid_utmzone_title(p_srid integer) OWNER TO postgres;

--
-- Name: srid_utmzone_title(public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.srid_utmzone_title(p_geom public.geometry) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT srid_utmzone_title( srid_utmzone_from4326(p_geom) )
$$;


ALTER FUNCTION public.srid_utmzone_title(p_geom public.geometry) OWNER TO postgres;

--
-- Name: st_asgeojsonb(public.geometry, integer, integer, text, jsonb, text, text, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.st_asgeojsonb(p_geom public.geometry, p_decimals integer DEFAULT 6, p_options integer DEFAULT 0, p_id text DEFAULT NULL::text, p_properties jsonb DEFAULT NULL::jsonb, p_name text DEFAULT NULL::text, p_title text DEFAULT NULL::text, p_id_as_int boolean DEFAULT false) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
-- Do ST_AsGeoJSON() adding id, crs, properties, name and title
  SELECT jsonb_build_object('type', 'Feature', 'geometry', ST_AsGeoJSON(p_geom,p_decimals,p_options)::jsonb)
       || CASE
          WHEN p_properties IS NULL OR jsonb_typeof(p_properties)!='object' THEN '{}'::jsonb
          ELSE jsonb_build_object('properties',p_properties)
          END
       || CASE
          WHEN p_id IS NULL THEN '{}'::jsonb
          WHEN p_id_as_int THEN jsonb_build_object('id',p_id::bigint)
          ELSE jsonb_build_object('id',p_id)
          END
       || CASE WHEN p_name IS NULL THEN '{}'::jsonb ELSE jsonb_build_object('name',p_name) END
       || CASE WHEN p_title IS NULL THEN '{}'::jsonb ELSE jsonb_build_object('title',p_title) END
$$;


ALTER FUNCTION public.st_asgeojsonb(p_geom public.geometry, p_decimals integer, p_options integer, p_id text, p_properties jsonb, p_name text, p_title text, p_id_as_int boolean) OWNER TO postgres;

--
-- Name: FUNCTION st_asgeojsonb(p_geom public.geometry, p_decimals integer, p_options integer, p_id text, p_properties jsonb, p_name text, p_title text, p_id_as_int boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.st_asgeojsonb(p_geom public.geometry, p_decimals integer, p_options integer, p_id text, p_properties jsonb, p_name text, p_title text, p_id_as_int boolean) IS '
  Enhances ST_AsGeoJSON() PostGIS function.
  Use ST_AsGeoJSONb( geom, 6, 1, osm_id::text, stable.element_properties(osm_id) - ''name:'' ).
';


--
-- Name: st_charactdiam(public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.st_charactdiam(g public.geometry) RETURNS double precision
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT
    CASE
      WHEN tp IS NULL OR tp IN ('POINT','MULTIPOINT') THEN 0.0
      WHEN is_poly AND poly_p<2*poly_a THEN (poly_a+poly_p)/2.0 -- normal perimeter
      WHEN is_poly THEN (2*poly_a+SQRT(poly_p))/3.0  -- fractal perimeter
      ELSE ST_Length(g)/2.0  -- or use buffer
    END
  FROM
  (
    SELECT tp, is_poly,
          CASE WHEN is_poly THEN SQRT(ST_Area(g)) ELSE 0 END AS poly_a,
          CASE WHEN is_poly THEN ST_Perimeter(g)/3.5 ELSE 0 END AS poly_p
    FROM
    (
       SELECT tp,
        CASE
          WHEN tp IN ('POLYGON','MULTIPOLYGON') THEN true
          ELSE false
        END is_poly
       FROM (SELECT GeometryType(g)) t1(tp)
    ) t2
  ) t3
$$;


ALTER FUNCTION public.st_charactdiam(g public.geometry) OWNER TO postgres;

--
-- Name: FUNCTION st_charactdiam(g public.geometry); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.st_charactdiam(g public.geometry) IS 'Characteristic-diameter (zero for point or null geometry). A reference for ST_Segmentize, etc. for complex geometries as countries. Not depends on SRID.';


--
-- Name: st_generategridpoints(public.geometry, integer, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.st_generategridpoints(g public.geometry, p_dist integer, p_x0 integer DEFAULT NULL::integer, p_y0 integer DEFAULT NULL::integer, p_show_all boolean DEFAULT false) RETURNS public.geometry
    LANGUAGE sql
    AS $_$
 SELECT ST_Collect(  ST_POINT(x, y, ST_SRID($1))  )
 FROM (         --- Parameter calculation: ---
   SELECT CASE
     WHEN p_dist>0 THEN p_dist
     WHEN p_dist<0 THEN LEAST(
       ceiling(ST_XMAX($1)-ST_XMIN($1))::int / -p_dist,
       ceiling(ST_YMAX($1)-ST_YMIN($1))::int / -p_dist
     )
     ELSE NULL
     END,
     CASE WHEN p_x0 is null THEN floor(ST_XMIN($1))::int ELSE p_x0 END,
     CASE WHEN p_y0 is null THEN floor(ST_YMIN($1))::int ELSE p_y0 END
  ) t(selected_dist, x0, y0),
  generate_series(  --- X axis scan: ---
    x0,
    ceiling(ST_XMAX($1))::int,
    selected_dist
   ) AS x,
   generate_series(  --- Y axis scan: ---
     y0,
     ceiling(ST_YMAX($1))::int,
     selected_dist
   ) AS y
 WHERE p_show_all OR st_intersects($1, ST_POINT(x, y, ST_SRID($1)))
$_$;


ALTER FUNCTION public.st_generategridpoints(g public.geometry, p_dist integer, p_x0 integer, p_y0 integer, p_show_all boolean) OWNER TO postgres;

--
-- Name: st_transform_resilient(public.geometry, integer, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.st_transform_resilient(g public.geometry, srid integer, size_fraction double precision DEFAULT 0.05, tolerance double precision DEFAULT 0) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE
    AS $$
 SELECT CASE
      WHEN COALESCE(size_fraction,0.0)>0.0 AND COALESCE(tolerance,0)>0 THEN
           ST_SimplifyPreserveTopology(geom,tolerance) -- ST_Simplify enough for grid
      ELSE geom
      END
 FROM (
  SELECT CASE
    WHEN size>0.0 THEN  ST_Transform(  ST_Segmentize(g,size)  , srid  )
    ELSE  ST_Transform(g,srid)
    END geom, size
  FROM (
    SELECT CASE
         WHEN size_fraction IS NULL THEN 0.0
         WHEN size_fraction<0       THEN -size_fraction
         ELSE         ST_CharactDiam(g) * size_fraction
         END
  ) t1(size)
 ) t2
$$;


ALTER FUNCTION public.st_transform_resilient(g public.geometry, srid integer, size_fraction double precision, tolerance double precision) OWNER TO postgres;

--
-- Name: FUNCTION st_transform_resilient(g public.geometry, srid integer, size_fraction double precision, tolerance double precision); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.st_transform_resilient(g public.geometry, srid integer, size_fraction double precision, tolerance double precision) IS 'See problem/solution discussed at https://gis.stackexchange.com/q/444441';


--
-- Name: st_transform_to_utmzone(public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.st_transform_to_utmzone(p_geom public.geometry) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT ST_Transform(p_geom, srid_utmzone_from4326( ST_Transform(ST_Centroid(p_geom),4326) ) )
$$;


ALTER FUNCTION public.st_transform_to_utmzone(p_geom public.geometry) OWNER TO postgres;

--
-- Name: str_abbrev_minscore(text, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.str_abbrev_minscore(abbrev text, name text, lexlabel text DEFAULT ''::text, old_score text DEFAULT ''::text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  -- SCORES CONVENCIONADOS: 'B'=bom = 7 a 9, 'R'=regular=4 a 6, 'F'=fraco = 0 a 3
  -- ou mudar?  1 e 2    Fraca (ou Péssima);  3 e 4 Ruim;  5 e 6 Regular,  7 e 8 Boa; 9 e 10 Ótima.
  SELECT CASE WHEN NOT(upper(unaccent(lexlabel)) ~ str_abbrev_regex(abbrev)) THEN
     iif( upper(unaccent(name)) ~ str_abbrev_regex(abbrev), iif(old_score>'',old_score, 'R'::text), 'F'::text)
  ELSE COALESCE(old_score,'') END
$$;


ALTER FUNCTION public.str_abbrev_minscore(abbrev text, name text, lexlabel text, old_score text) OWNER TO postgres;

--
-- Name: str_abbrev_regex(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.str_abbrev_regex(abbrev text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT string_agg(x||'.*','') FROM regexp_split_to_table(abbrev,'') t(x)
$$;


ALTER FUNCTION public.str_abbrev_regex(abbrev text) OWNER TO postgres;

--
-- Name: str_geocodeiso_decode(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.str_geocodeiso_decode(iso text) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT isolabel_ext || array[split_part(isolabel_ext,'-',1)]
  FROM mvwjurisdiction_synonym
  WHERE synonym = lower((
    SELECT
      CASE
        WHEN cardinality(u)=2 AND u[2] ~ '^\d+?$'
        THEN u[1]::text || '-' || ((u[2])::integer)::text
        ELSE iso
      END
    FROM (SELECT regexp_split_to_array(iso,'(-)')::text[] AS u ) r
  ))
$_$;


ALTER FUNCTION public.str_geocodeiso_decode(iso text) OWNER TO postgres;

--
-- Name: FUNCTION str_geocodeiso_decode(iso text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.str_geocodeiso_decode(iso text) IS 'Decode abbrev isolabel_ext.';


--
-- Name: str_geouri_decode(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.str_geouri_decode(uri text) RETURNS double precision[]
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT regexp_match(uri,'^geo:(?:olc:|ghs:)?([-0-9\.]+),([-0-9\.]+)(?:,([-0-9\.]+))?(?:;u=([-0-9\.]+))?','i')::float[]
$$;


ALTER FUNCTION public.str_geouri_decode(uri text) OWNER TO postgres;

--
-- Name: FUNCTION str_geouri_decode(uri text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.str_geouri_decode(uri text) IS 'Decodes standard GeoURI of latitude and longitude into float array.';


--
-- Name: str_url_todomain(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.str_url_todomain(url text, command text DEFAULT NULL::text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
   -- see https://stackoverflow.com/a/37835341/287948
   SELECT CASE WHEN command>'' THEN trim(command)||' ' ELSE '' END
          ||  regexp_replace(lower(trim(url,' /')), '(^(mailto:)?[^@]+@)|(^.*(https?|s?ftp)://(?:www\d?\.)?)|(/.+$)|(^[^\.]+$)', '', 'g')
$_$;


ALTER FUNCTION public.str_url_todomain(url text, command text) OWNER TO postgres;

--
-- Name: str_urldecode(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.str_urldecode(p text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
 SELECT convert_from(CAST(E'\\x' || string_agg(
    CASE WHEN length(r.m[1]) = 1 THEN encode(convert_to(r.m[1], 'SQL_ASCII'), 'hex')
    ELSE substring(r.m[1] from 2 for 2)
 END, '') AS bytea), 'UTF8')
FROM regexp_matches($1, '%[0-9a-f][0-9a-f]|.', 'gi') AS r(m);
  -- adapted from https://stackoverflow.com/a/8494602/287948
$_$;


ALTER FUNCTION public.str_urldecode(p text) OWNER TO postgres;

--
-- Name: str_urls_todomains(text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.str_urls_todomains(urls text[]) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT array_agg(d) FROM (SELECT DISTINCT str_url_todomain(UNNEST(urls))  ORDER BY 1) t(d) WHERE d>''
$$;


ALTER FUNCTION public.str_urls_todomains(urls text[]) OWNER TO postgres;

--
-- Name: stragg_prefix(text, text[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.stragg_prefix(prefix text, s text[], sep text DEFAULT ','::text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT string_agg(x,sep) FROM ( select prefix||(unnest(s)) ) t(x)
$$;


ALTER FUNCTION public.stragg_prefix(prefix text, s text[], sep text) OWNER TO postgres;

--
-- Name: substring_occurs(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.substring_occurs(p_main text, p_sub text) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT ( CHAR_LENGTH(p_main) - CHAR_LENGTH(REPLACE(p_main,p_sub,'')) )  / CHAR_LENGTH(p_sub);
  -- see https://stackoverflow.com/a/36376548/287948
$$;


ALTER FUNCTION public.substring_occurs(p_main text, p_sub text) OWNER TO postgres;

--
-- Name: FUNCTION substring_occurs(p_main text, p_sub text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.substring_occurs(p_main text, p_sub text) IS 'Counts the number of occurences of a substring.';


--
-- Name: table_disk_usage(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.table_disk_usage(p_schema_name text DEFAULT 'public'::text, p_name_like text DEFAULT NULL::text) RETURNS TABLE(schema_name text, relname text, relkind character, size text, size_bytes bigint)
    LANGUAGE sql IMMUTABLE
    AS $$
SELECT
  schema_name, relname,relkind,
  pg_size_pretty(table_size) AS size,
  table_size as size_bytes
FROM (
       SELECT
         pg_catalog.pg_namespace.nspname           AS schema_name,
         relname,
         pg_relation_size(pg_catalog.pg_class.oid) AS table_size,
         relkind
       FROM pg_catalog.pg_class
         JOIN pg_catalog.pg_namespace ON relnamespace = pg_catalog.pg_namespace.oid
       WHERE relkind IN ('r','i','t','m','f','p','I') -- exclude view and sequences
     ) t
WHERE (p_schema_name IS NULL OR schema_name=p_schema_name)
      AND (p_name_like IS NULL OR relname LIKE ('%'||p_name_like||'%'))
ORDER BY table_size DESC
$$;


ALTER FUNCTION public.table_disk_usage(p_schema_name text, p_name_like text) OWNER TO postgres;

--
-- Name: to_bigint(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.to_bigint(str text) RETURNS bigint
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT CASE WHEN s='' THEN NULL::int ELSE substr(s,1,18)::bigint END
  FROM (SELECT regexp_replace(str, '[^0-9]', '','g')) t(s)
  -- pendente avaliar solução que pega só o primero de vários número separados por espaço.
$$;


ALTER FUNCTION public.to_bigint(str text) OWNER TO postgres;

--
-- Name: to_hex(bigint[], integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.to_hex(p_x bigint[], p_fill_zeros integer DEFAULT NULL::integer) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT array_agg( CASE WHEN $2>0 THEN lpad(x,p_fill_zeros,'0') ELSE x END )
  FROM (SELECT to_hex(x) x FROM unnest($1) t1(x)) t
$_$;


ALTER FUNCTION public.to_hex(p_x bigint[], p_fill_zeros integer) OWNER TO postgres;

--
-- Name: to_integer(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.to_integer(str text) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT CASE WHEN s='' THEN NULL::int ELSE s::int END
  FROM (SELECT regexp_replace(str, '[^0-9]', '','g')) t(s)
$$;


ALTER FUNCTION public.to_integer(str text) OWNER TO postgres;

--
-- Name: treport_aswikitext(text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.treport_aswikitext(treport_name text, p_caption text DEFAULT ''::text, p_safe_limit integer DEFAULT 1000) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
 WITH r AS ( SELECT * FROM treport_to_json_rows($1,p_safe_limit) )
 ,h AS ( SELECT json_object_keys(j) k FROM (select j from r limit 1) t  )
 ,v AS ( SELECT idx,  (json_each_text(j)).value as txt FROM  r )
 SELECT string_agg(x,'') FROM (
   SELECT E'{| class="wikitable"' as x
   UNION ALL
   SELECT E'\n|+' as x WHERE p_caption>''
   UNION ALL
   SELECT format(E'\n|-\n!%s', string_agg(k,'!!')) FROM h
   UNION ALL
   SELECT E'\n|-\n|'|| string_agg(txt,'||' order by idx) FROM v group by idx
   UNION ALL
   SELECT E'\n|}'
 ) s
$_$;


ALTER FUNCTION public.treport_aswikitext(treport_name text, p_caption text, p_safe_limit integer) OWNER TO postgres;

--
-- Name: treport_to_json_rows(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.treport_to_json_rows(treport_name text, p_safe_limit integer DEFAULT 1000) RETURNS TABLE(j json, idx integer)
    LANGUAGE plpgsql
    AS $$
   -- Note: JSONB not good because losts column-order
 DECLARE
    query text;
 BEGIN
    query := format(
      'SELECT to_json(t) j, (ROW_NUMBER () OVER())::int idx FROM %s t LIMIT %s',
      treport_name,
      p_safe_limit
    );
    RETURN QUERY EXECUTE query; 
 END;
$$;


ALTER FUNCTION public.treport_to_json_rows(treport_name text, p_safe_limit integer) OWNER TO postgres;

--
-- Name: trunc(double precision, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trunc(x double precision, xtype text, xdigits integer DEFAULT 0) RETURNS double precision
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT CASE
       WHEN xtype NOT IN ('dec','bin','hex') THEN 'NaN'::float
       WHEN xdigits=0 THEN trunc(x)
       WHEN xtype='dec' THEN trunc(x::numeric,xdigits)
       ELSE (s1 ||'.'|| s2)::float
      END
    FROM (
      SELECT s1,
             lpad(
               trunc_bin( s2::bigint, CASE WHEN xd<bin_bits THEN bin_bits - xd ELSE 0 END )::text,
               l2,
               '0'
             ) AS s2
      FROM (
        SELECT *,
             (floor( log(2,s2::numeric) ) +1)::int AS bin_bits, -- most significant bit position, bitwise_MSB()
             CASE WHEN xtype='hex' THEN xdigits*4 ELSE xdigits END AS xd
        FROM (
          SELECT s[1] AS s1, s[2] AS s2, length(s[2]) AS l2
          FROM (SELECT regexp_split_to_array(x::text,'\.')) t1a(s)
        ) t1b
      ) t1c
    ) t2
$$;


ALTER FUNCTION public.trunc(x double precision, xtype text, xdigits integer) OWNER TO postgres;

--
-- Name: trunc_bin(bigint, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trunc_bin(x bigint, bits integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT ((x::bit(64) >> bits) << bits)::bigint;
$$;


ALTER FUNCTION public.trunc_bin(x bigint, bits integer) OWNER TO postgres;

--
-- Name: unnest_2d_1d(anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.unnest_2d_1d(anyarray, OUT a anyarray) RETURNS SETOF anyarray
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $_$
 BEGIN
    -- https://stackoverflow.com/a/41405177/287948
    -- IF $1 = '{}'::int[] THEN ERROR END IF;
    FOREACH a SLICE 1 IN ARRAY $1 LOOP
       RETURN NEXT;
    END LOOP;
 END
$_$;


ALTER FUNCTION public.unnest_2d_1d(anyarray, OUT a anyarray) OWNER TO postgres;

--
-- Name: unnest_multidim(anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.unnest_multidim(anyarray) RETURNS SETOF anyarray
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$
  SELECT array_agg($1[series2.i][series2.x]) FROM
    (SELECT generate_series(array_lower($1,2),array_upper($1,2)) as x, series1.i
     FROM
     (SELECT generate_series(array_lower($1,1),array_upper($1,1)) as i) series1
    ) series2
GROUP BY series2.i
-- see https://stackoverflow.com/a/9724943/287948
$_$;


ALTER FUNCTION public.unnest_multidim(anyarray) OWNER TO postgres;

--
-- Name: utmgrid_from4326(public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.utmgrid_from4326(p_geom public.geometry) RETURNS integer[]
    LANGUAGE sql IMMUTABLE
    AS $$
   -- see https://gis.stackexchange.com/a/15613/7505
  SELECT array[
    x[1],   -- Hemisphere
    x[2],   -- UTM Zone
    floor( (ST_Y(p_geom)+80.0)/8.0 ), -- Latitude Band, normalize to positive interval before division (8° of latitude wide)
    CASE WHEN x[1]::boolean THEN 32600  ELSE 32700 END  +  x[2]    -- SRID
  ]
  FROM (SELECT utmzone_from4326(p_geom)) t(x)
$$;


ALTER FUNCTION public.utmgrid_from4326(p_geom public.geometry) OWNER TO postgres;

--
-- Name: utmgrid_from4326_coverlabels(public.geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.utmgrid_from4326_coverlabels(p_geom public.geometry, p_samples integer DEFAULT 1000) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT array_agg(code)
  FROM (
    SELECT DISTINCT utmgrid_from4326_label((pt).geom) code
    FROM ( SELECT ST_DumpPoints(ST_GeneratePoints(p_geom,p_samples)) ) t1(pt)
    ORDER BY 1
  ) t2
$$;


ALTER FUNCTION public.utmgrid_from4326_coverlabels(p_geom public.geometry, p_samples integer) OWNER TO postgres;

--
-- Name: utmgrid_from4326_label(public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.utmgrid_from4326_label(p_geom public.geometry) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  -- 'CDEFGHJKLM' are in the southern hemisphere, and 'NPQRSTUVWX' are in the northern hemisphere.
  --  A and B are below 80 South and Y and Z are above 84 North.
  SELECT x[2]::text || substr(lastBandChars, x[3]+1, 1)
  FROM (SELECT utmgrid_from4326(p_geom)) t(x),
       (SELECT 'CDEFGHJKLMNPQRSTUVWXX' lastBandChars) s
$$;


ALTER FUNCTION public.utmgrid_from4326_label(p_geom public.geometry) OWNER TO postgres;

--
-- Name: utmzone_from4326(public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.utmzone_from4326(p_geom public.geometry) RETURNS integer[]
    LANGUAGE sql IMMUTABLE
    AS $$
   -- see https://gis.stackexchange.com/a/439316/7505
   SELECT array[
     ((ST_Y(p_geom))>0)::boolean::int, -- 1 is Northern, 0 is Southern
     floor((ST_X(p_geom)+180)/6)+1
    ]
$$;


ALTER FUNCTION public.utmzone_from4326(p_geom public.geometry) OWNER TO postgres;

--
-- Name: utmzone_from4326_label(public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.utmzone_from4326_label(p_geom public.geometry) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  -- The Southern/Northern label is redundant?? So, need only the number
  SELECT x[2]::text || CASE WHEN x[1]::boolean THEN 'N'  ELSE 'S' END
  FROM (SELECT utmzone_from4326(p_geom)) t(x)
$$;


ALTER FUNCTION public.utmzone_from4326_label(p_geom public.geometry) OWNER TO postgres;

--
-- Name: vbit_deinterleave(bit varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.vbit_deinterleave(x bit varying) RETURNS bit varying[]
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT  array[  bitcat_agg(substring(x,i,1)),
                 bitcat_agg(substring(x,i+1,1))
          ]
  FROM generate_series(1,bit_length(x),2) t(i)
$$;


ALTER FUNCTION public.vbit_deinterleave(x bit varying) OWNER TO postgres;

--
-- Name: vbit_deinterleave2(bit varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.vbit_deinterleave2(p_x bit varying) RETURNS bit varying[]
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT  array[  bitcat_agg(substring(x,i+1,1)),
                  bitcat_agg(substring(x,i,1))
          ]
  FROM (select CASE WHEN (bit_length(p_x)%2)::boolean THEN b'0'||p_x ELSE p_x END) t0(x),
       generate_series(1,bit_length(x),2) t1(i)
$$;


ALTER FUNCTION public.vbit_deinterleave2(p_x bit varying) OWNER TO postgres;

--
-- Name: vbit_deinterleave3(bit varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.vbit_deinterleave3(p_x bit varying) RETURNS bit varying[]
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT  array[  bitcat_agg(substring(x,i,1)),
               bitcat_agg(substring(x,i+1,1))
        ]
  FROM (select CASE WHEN (bit_length(p_x)%2)::boolean THEN b'0'||p_x ELSE p_x END) t0(x),
       generate_series(1,bit_length(x),2) t1(i)
$$;


ALTER FUNCTION public.vbit_deinterleave3(p_x bit varying) OWNER TO postgres;

--
-- Name: vbit_deinterleave_to_int(bit varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.vbit_deinterleave_to_int(x bit varying) RETURNS integer[]
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT vbit_to_int( vbit_DeInterleave(x) )
$$;


ALTER FUNCTION public.vbit_deinterleave_to_int(x bit varying) OWNER TO postgres;

--
-- Name: vbit_deinterleave_to_int2(bit varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.vbit_deinterleave_to_int2(x bit varying) RETURNS integer[]
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT vbit_to_int( vbit_DeInterleave2(x) )
$$;


ALTER FUNCTION public.vbit_deinterleave_to_int2(x bit varying) OWNER TO postgres;

--
-- Name: vbit_deinterleave_to_int3(bit varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.vbit_deinterleave_to_int3(x bit varying) RETURNS integer[]
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT vbit_to_int( vbit_DeInterleave3(x) )
$$;


ALTER FUNCTION public.vbit_deinterleave_to_int3(x bit varying) OWNER TO postgres;

--
-- Name: vbit_interleave(bit varying, bit varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.vbit_interleave(x bit varying, y bit varying) RETURNS bit varying
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT CASE WHEN x=b'' OR y=b'' THEN x||y ELSE (
    SELECT  bitcat_agg( substring(x,i,1) || substring(y,i,1) )
    FROM generate_series(1,bit_length(x)) t(i)
  ) END
$$;


ALTER FUNCTION public.vbit_interleave(x bit varying, y bit varying) OWNER TO postgres;

--
-- Name: vbit_to_bigint(bit varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.vbit_to_bigint(b bit varying, blen integer DEFAULT NULL::integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT OVERLAY( b'0'::bit(64) PLACING b FROM 65-COALESCE(blen,length(b)) )::bigint
$$;


ALTER FUNCTION public.vbit_to_bigint(b bit varying, blen integer) OWNER TO postgres;

--
-- Name: FUNCTION vbit_to_bigint(b bit varying, blen integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.vbit_to_bigint(b bit varying, blen integer) IS 'Converts Varbit into native Bigint by simple right-side copy.';


--
-- Name: vbit_to_int(bit varying[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.vbit_to_int(x bit varying[]) RETURNS integer[]
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  SELECT  array_agg( vbit_to_int(x_i) ORDER BY i) FROM unnest(x) WITH ORDINALITY t(x_i,i)
$$;


ALTER FUNCTION public.vbit_to_int(x bit varying[]) OWNER TO postgres;

--
-- Name: vbit_to_int(bit varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.vbit_to_int(b bit varying, blen integer DEFAULT NULL::integer) RETURNS integer
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  -- slower  SELECT (  (b'0'::bit(32) || b) << COALESCE(blen,length(b))   )::bit(32)::int
  -- !loss information about varbit zeros and empty varbit
  SELECT overlay( b'0'::bit(32) PLACING b FROM 33-COALESCE(blen,length(b)) )::int
  -- same as  ( substring(0::bit(32),bit_length(x)+1) || x )::bit(32)::int
$$;


ALTER FUNCTION public.vbit_to_int(b bit varying, blen integer) OWNER TO postgres;

--
-- Name: volat_file_write(text, text, text, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.volat_file_write(file text, fcontent text, msg text DEFAULT 'Ok'::text, append boolean DEFAULT false) RETURNS text
    LANGUAGE sql
    AS $$
  SELECT pg_catalog.pg_file_unlink(file);
  -- solves de PostgreSQL problem of the "LAZY COALESCE", as https://stackoverflow.com/a/42405837/287948
  SELECT msg ||'. Content bytes '|| CASE WHEN append THEN 'appended:' ELSE 'writed:' END
         ||  pg_catalog.pg_file_write(file,fcontent,append)::text
         || E'\nSee '|| file
$$;


ALTER FUNCTION public.volat_file_write(file text, fcontent text, msg text, append boolean) OWNER TO postgres;

--
-- Name: FUNCTION volat_file_write(file text, fcontent text, msg text, append boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.volat_file_write(file text, fcontent text, msg text, append boolean) IS 'Do lazy coalesce. To use in a "only write when null" condiction of COALESCE(x,volat_file_write()).';


--
-- Name: write_geojsonb_features(text, text, text, text, text[], text, integer, integer, integer, text, text, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.write_geojsonb_features(sql_tablename text, p_file text, sql_geom text DEFAULT 't1.geom'::text, p_cols text DEFAULT NULL::text, p_cols_orderby text[] DEFAULT NULL::text[], col_id text DEFAULT NULL::text, p_pretty_opt integer DEFAULT 0, p_decimals integer DEFAULT 6, p_options integer DEFAULT 0, p_name text DEFAULT NULL::text, p_title text DEFAULT NULL::text, p_id_as_int boolean DEFAULT false) RETURNS text
    LANGUAGE plpgsql
    AS $_$
  DECLARE
    msg text;
    sql_orderby text;
    sql_pre text;
    sql text;
  BEGIN
      IF position(' ' in trim(sql_tablename))>0 THEN
        sql_tablename := '('||sql_tablename||')';
      END IF;
      sql_orderby := CASE
        WHEN p_cols_orderby IS NULL OR array_length(p_cols_orderby,1) IS NULL THEN ''
        ELSE 'ORDER BY '||stragg_prefix('t1.',p_cols_orderby) END;
      sql_pre := format($$
        ST_AsGeoJSONb( %s, %s, %s, %s, %s, %s, %s, %s) %s
        $$,
        sql_geom, p_decimals::text, p_options::text,
        CASE WHEN col_id is null THEN 'NULL' ELSE 't1.'||col_id||'::text' END,
        CASE WHEN p_cols~'::jsonb?$' THEN regexp_replace(p_cols,'::jsonb?$','')
             WHEN p_cols is null THEN 'NULL'
             ELSE 'to_jsonb(t2)'
        END,
        COALESCE(p_name::text,'NULL'),
        COALESCE(p_title::text,'NULL'),
        COALESCE(p_id_as_int::text,'NULL'),
        sql_orderby
      );
      -- RAISE NOTICE '--- DEBUG sql_pre: %', sql_pre
      -- ex. 'ST_AsGeoJSONb( ST_Transform(t1.geom,4326), 6, 0, t1.gid::text, to_jsonb(t2) ) ORDER BY t1.gid'
      -- EXECUTE
      SELECT pg_catalog.pg_file_unlink(p_file)::text INTO sql;
      sql := format($$
        SELECT volat_file_write(
                %L,
                jsonb_pretty_lines( jsonb_build_object('type','FeatureCollection', 'features', gj), %s)
             )
        FROM (
          SELECT jsonb_agg( %s ) AS gj
          FROM %s t1 %s
        ) t3
       $$,
       p_file,
       p_pretty_opt::text,
       sql_pre, sql_tablename,
       CASE WHEN p_cols IS NULL OR p_cols~'::jsonb?$' THEN ''
            ELSE ', LATERAL (SELECT '||p_cols||') t2'
       END
      );
      -- RAISE NOTICE E'--- DEBUG SQL: ---\n%\n', sql
      EXECUTE sql INTO msg;
      RETURN msg;
  END
$_$;


ALTER FUNCTION public.write_geojsonb_features(sql_tablename text, p_file text, sql_geom text, p_cols text, p_cols_orderby text[], col_id text, p_pretty_opt integer, p_decimals integer, p_options integer, p_name text, p_title text, p_id_as_int boolean) OWNER TO postgres;

--
-- Name: FUNCTION write_geojsonb_features(sql_tablename text, p_file text, sql_geom text, p_cols text, p_cols_orderby text[], col_id text, p_pretty_opt integer, p_decimals integer, p_options integer, p_name text, p_title text, p_id_as_int boolean); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.write_geojsonb_features(sql_tablename text, p_file text, sql_geom text, p_cols text, p_cols_orderby text[], col_id text, p_pretty_opt integer, p_decimals integer, p_options integer, p_name text, p_title text, p_id_as_int boolean) IS 'run file_write() dynamically to save specified relation as GeoJSONb FeatureCollection.';


--
-- Name: xml_pretty(xml, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.xml_pretty(x xml, mode integer DEFAULT 0) RETURNS xml
    LANGUAGE sql IMMUTABLE
    AS $_$
  -- requires xml2 pg extension
  -- https://postgres.cz/wiki/PostgreSQL_SQL_Tricks#Pretty_xml_formating
  select xslt_process($1::text,
CASE WHEN mode=1 THEN  -- see https://stackoverflow.com/a/29113073/287948
$$
<?xml version='1.0' encoding='UTF-8'?>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
<xsl:template match="*">
    <xsl:variable name="indent" select="concat('&#10;', substring('    ', 1, 3*count(ancestor::*)))" />
    <xsl:value-of select="$indent" />
    <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:apply-templates select="node()"/>
        <xsl:value-of select="$indent" />
    </xsl:copy>
</xsl:template>
$$
ELSE -- See https://gist.github.com/LeKovr/e7b365d2dca58e4bc8c8f4695e0ca435
$$
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:strip-space elements="*" />
<xsl:output method="xml" indent="yes" />
<xsl:template match="node() | @*"><xsl:copy><xsl:apply-templates select="node() | @*" /></xsl:copy></xsl:template>
</xsl:stylesheet>
$$
END
)::xml
$_$;


ALTER FUNCTION public.xml_pretty(x xml, mode integer) OWNER TO postgres;

--
-- Name: xml_to_dec(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.xml_to_dec(text) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
  -- https://postgres.cz/wiki/PostgreSQL_SQL_Tricks_II#Conversion_between_hex_and_dec_numbers
declare r int;
begin
 execute E'select x\''||$1|| E'\'::integer' into r;
 return r;
end
$_$;


ALTER FUNCTION public.xml_to_dec(text) OWNER TO postgres;

--
-- Name: xml_unescape(xml); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.xml_unescape(xml) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
  -- this function do similar work as PHP's preg_replace_callback().
  -- convert escaped sybols like '&#x43E;' to unicode
  -- sample: select xml_unescape('&#x43E;&#x43F;&#x43B;&#x44F;&#x44F;'::xml) = 'опляя';
  -- See https://gist.github.com/LeKovr/e7b365d2dca58e4bc8c8f4695e0ca435
declare
  s text;
  rv text := $1;
begin
  for s in select distinct unnest(regexp_matches($1::text,'&#x(\w+);','g')) loop
    rv := replace(rv,'&#x'||s||';',chr(xml_to_dec(s)));
  end loop;
  return rv;
end
$_$;


ALTER FUNCTION public.xml_unescape(xml) OWNER TO postgres;

--
-- Name: yamlfile_to_jsonb(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.yamlfile_to_jsonb(file text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT yaml_to_jsonb( pg_read_file(file) )
$$;


ALTER FUNCTION public.yamlfile_to_jsonb(file text) OWNER TO postgres;

--
-- Name: array_agg_cat(anycompatiblearray); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE public.array_agg_cat(anycompatiblearray) (
    SFUNC = array_cat,
    STYPE = anycompatiblearray,
    INITCOND = '{}'
);


ALTER AGGREGATE public.array_agg_cat(anycompatiblearray) OWNER TO postgres;

--
-- Name: array_agg_cat_distinct(anyarray); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE public.array_agg_cat_distinct(anyarray) (
    SFUNC = public.array_cat_distinct,
    STYPE = anyarray,
    INITCOND = '{}'
);


ALTER AGGREGATE public.array_agg_cat_distinct(anyarray) OWNER TO postgres;

--
-- Name: array_concat_agg(anycompatiblearray); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE public.array_concat_agg(anycompatiblearray) (
    SFUNC = array_cat,
    STYPE = anycompatiblearray
);


ALTER AGGREGATE public.array_concat_agg(anycompatiblearray) OWNER TO postgres;

--
-- Name: bitcat_agg(bit varying); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE public.bitcat_agg(bit varying) (
    SFUNC = bitcat,
    STYPE = bit varying
);


ALTER AGGREGATE public.bitcat_agg(bit varying) OWNER TO postgres;

--
-- Name: jsonb_summable_aggmerge(jsonb); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE public.jsonb_summable_aggmerge(jsonb) (
    SFUNC = public.jsonb_summable_merge,
    STYPE = jsonb,
    INITCOND = 'null'
);


ALTER AGGREGATE public.jsonb_summable_aggmerge(jsonb) OWNER TO postgres;

--
-- Name: files; Type: SERVER; Schema: -; Owner: postgres
--

CREATE SERVER files FOREIGN DATA WRAPPER file_fdw;


ALTER SERVER files OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: jurisdiction; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.jurisdiction (
    osm_id bigint NOT NULL,
    jurisd_base_id integer NOT NULL,
    jurisd_local_id integer NOT NULL,
    parent_id bigint,
    admin_level smallint NOT NULL,
    name text NOT NULL,
    parent_abbrev text NOT NULL,
    abbrev text,
    wikidata_id bigint,
    lexlabel text NOT NULL,
    isolabel_ext text NOT NULL,
    ddd integer,
    housenumber_system_type text,
    lex_urn text,
    info jsonb,
    name_en text,
    isolevel integer,
    ne_country_id integer,
    int_country_id integer,
    CONSTRAINT jurisdiction_admin_level_check CHECK (((admin_level > 0) AND (admin_level < 100))),
    CONSTRAINT jurisdiction_name_check CHECK ((length(name) < 60))
);


ALTER TABLE optim.jurisdiction OWNER TO postgres;

--
-- Name: TABLE jurisdiction; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.jurisdiction IS 'Information about jurisdictions without geometry.';


--
-- Name: COLUMN jurisdiction.osm_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.osm_id IS 'Relation identifier in OpenStreetMap.';


--
-- Name: COLUMN jurisdiction.jurisd_base_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.jurisd_base_id IS 'ISO3166-1-numeric COUNTRY ID (e.g. Brazil is 76) or negative for non-iso (ex. oceans).';


--
-- Name: COLUMN jurisdiction.jurisd_local_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.jurisd_local_id IS 'Numeric official ID like IBGE_ID of BR jurisdiction. For example ACRE is 12 and its cities are {1200013, 1200054,etc}.';


--
-- Name: COLUMN jurisdiction.parent_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.parent_id IS 'osm_id of top admin_level.';


--
-- Name: COLUMN jurisdiction.admin_level; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.admin_level IS 'OSM convention for admin_level tag in country.';


--
-- Name: COLUMN jurisdiction.name; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.name IS 'Name of jurisdiction';


--
-- Name: COLUMN jurisdiction.parent_abbrev; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.parent_abbrev IS 'Abbreviation of parent name.';


--
-- Name: COLUMN jurisdiction.abbrev; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.abbrev IS 'Name abbreviation.';


--
-- Name: COLUMN jurisdiction.wikidata_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.wikidata_id IS 'wikidata identifier without Q prefix.';


--
-- Name: COLUMN jurisdiction.lexlabel; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.lexlabel IS 'Cache from name; e.g. sao.paulo.';


--
-- Name: COLUMN jurisdiction.isolabel_ext; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.isolabel_ext IS 'Cache from parent_abbrev (ISO) and name (camel case); e.g. BR-SP-SaoPaulo.';


--
-- Name: COLUMN jurisdiction.ddd; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.ddd IS 'Direct distance dialing.';


--
-- Name: COLUMN jurisdiction.housenumber_system_type; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.housenumber_system_type IS 'Housenumber system.';


--
-- Name: COLUMN jurisdiction.lex_urn; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.lex_urn IS 'Housenumber system law.';


--
-- Name: COLUMN jurisdiction.info; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.info IS 'Others information.';


--
-- Name: COLUMN jurisdiction.name_en; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.name_en IS 'City name in english.';


--
-- Name: COLUMN jurisdiction.isolevel; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.isolevel IS '1=country, 2=state, 3=mun';


--
-- Name: COLUMN jurisdiction.ne_country_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.ne_country_id IS 'NaturalEarthData country gid.';


--
-- Name: COLUMN jurisdiction.int_country_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction.int_country_id IS 'Internal country id.';


--
-- Name: jurisdiction; Type: VIEW; Schema: api; Owner: postgres
--

CREATE VIEW api.jurisdiction AS
 SELECT osm_id,
    jurisd_base_id,
    jurisd_local_id,
    name,
    parent_abbrev,
    abbrev,
    wikidata_id,
    lexlabel,
    isolabel_ext,
    ddd,
    jsonb_strip_nulls((info || jsonb_build_object('sys_housenumbering', housenumber_system_type, 'sys_housenumbering_lex', lex_urn))) AS info
   FROM optim.jurisdiction
  ORDER BY jurisd_base_id, isolevel, name
 LIMIT 100000;


ALTER VIEW api.jurisdiction OWNER TO postgres;

--
-- Name: VIEW jurisdiction; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON VIEW api.jurisdiction IS 'Returns list of jurisdictions from optim schema.';


--
-- Name: COLUMN jurisdiction.osm_id; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON COLUMN api.jurisdiction.osm_id IS 'Relation identifier in OpenStreetMap.';


--
-- Name: COLUMN jurisdiction.jurisd_base_id; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON COLUMN api.jurisdiction.jurisd_base_id IS 'ISO3166-1-numeric COUNTRY ID (e.g. Brazil is 76) or negative for non-iso (ex. oceans).';


--
-- Name: COLUMN jurisdiction.jurisd_local_id; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON COLUMN api.jurisdiction.jurisd_local_id IS 'NaturalEarthData country gid.';


--
-- Name: COLUMN jurisdiction.name; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON COLUMN api.jurisdiction.name IS 'Name of jurisdiction';


--
-- Name: COLUMN jurisdiction.parent_abbrev; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON COLUMN api.jurisdiction.parent_abbrev IS 'Abbreviation of parent name.';


--
-- Name: COLUMN jurisdiction.abbrev; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON COLUMN api.jurisdiction.abbrev IS 'Name abbreviation.';


--
-- Name: COLUMN jurisdiction.wikidata_id; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON COLUMN api.jurisdiction.wikidata_id IS 'wikidata identifier without Q prefix.';


--
-- Name: COLUMN jurisdiction.lexlabel; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON COLUMN api.jurisdiction.lexlabel IS 'Cache from name; e.g. sao.paulo.';


--
-- Name: COLUMN jurisdiction.isolabel_ext; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON COLUMN api.jurisdiction.isolabel_ext IS 'Cache from parent_abbrev (ISO) and name (camel case); e.g. BR-SP-SaoPaulo.';


--
-- Name: COLUMN jurisdiction.ddd; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON COLUMN api.jurisdiction.ddd IS 'Direct distance dialing.';


--
-- Name: COLUMN jurisdiction.info; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON COLUMN api.jurisdiction.info IS 'Others information.';


--
-- Name: jurisdiction_lexlabel; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.jurisdiction_lexlabel AS
 SELECT isolabel_ext,
        CASE
            WHEN (cardinality(a) = 3) THEN lower(((((a[1] || ';'::text) || lexlabel_parent) || ';'::text) || lexlabel))
            WHEN (cardinality(a) = 2) THEN lower(((a[1] || ';'::text) || lexlabel))
            WHEN (cardinality(a) = 1) THEN lower(isolabel_ext)
            ELSE NULL::text
        END AS lex_isoinlevel1,
        CASE
            WHEN (cardinality(a) = 3) THEN lower(((((a[1] || ';'::text) || a[2]) || ';'::text) || lexlabel))
            WHEN (cardinality(a) = 2) THEN lower(((a[1] || ';'::text) || lexlabel))
            WHEN (cardinality(a) = 1) THEN lower(isolabel_ext)
            ELSE NULL::text
        END AS lex_isoinlevel2,
        CASE
            WHEN (cardinality(a) = 3) THEN lower(((((a[1] || ';'::text) || a[2]) || ';'::text) || abbrev))
            WHEN (cardinality(a) = 2) THEN lower(((a[1] || ';'::text) || a[2]))
            WHEN (cardinality(a) = 1) THEN lower(isolabel_ext)
            ELSE NULL::text
        END AS lex_isoinlevel2_abbrev
   FROM ( SELECT s.isolabel_ext AS isolabel_ext_parent,
            s.lexlabel AS lexlabel_parent,
            r.isolabel_ext,
            r.abbrev,
            r.name,
            r.lexlabel,
            regexp_split_to_array(r.isolabel_ext, '(-)'::text) AS a
           FROM (optim.jurisdiction r
             LEFT JOIN optim.jurisdiction s ON ((s.isolabel_ext = ( SELECT ((a.a[1] || '-'::text) || a.a[2])
                   FROM regexp_split_to_array(r.isolabel_ext, '(-)'::text) a(a)))))) t;


ALTER VIEW optim.jurisdiction_lexlabel OWNER TO postgres;

--
-- Name: VIEW jurisdiction_lexlabel; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.jurisdiction_lexlabel IS 'Jurisdictions in lex format.';


--
-- Name: COLUMN jurisdiction_lexlabel.isolabel_ext; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_lexlabel.isolabel_ext IS 'ISO and name (camel case); e.g. BR-SP-SaoPaulo.';


--
-- Name: COLUMN jurisdiction_lexlabel.lex_isoinlevel1; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_lexlabel.lex_isoinlevel1 IS 'isolabel_ext in lex format, e.g. br;sao.paulo;sao.paulo.';


--
-- Name: COLUMN jurisdiction_lexlabel.lex_isoinlevel2; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_lexlabel.lex_isoinlevel2 IS 'isolabel_ext in lex format, e.g. br;sp;sao.paulo.';


--
-- Name: COLUMN jurisdiction_lexlabel.lex_isoinlevel2_abbrev; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_lexlabel.lex_isoinlevel2_abbrev IS 'isolabel_ext in lex format, e.g. br;sp;spa.';


--
-- Name: jurisdiction_lexlabel; Type: VIEW; Schema: api; Owner: postgres
--

CREATE VIEW api.jurisdiction_lexlabel AS
 SELECT isolabel_ext,
    lex_isoinlevel1,
    lex_isoinlevel2,
    lex_isoinlevel2_abbrev
   FROM optim.jurisdiction_lexlabel;


ALTER VIEW api.jurisdiction_lexlabel OWNER TO postgres;

--
-- Name: VIEW jurisdiction_lexlabel; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON VIEW api.jurisdiction_lexlabel IS 'Jurisdictions in lex format.';


--
-- Name: COLUMN jurisdiction_lexlabel.isolabel_ext; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON COLUMN api.jurisdiction_lexlabel.isolabel_ext IS 'ISO and name (camel case); e.g. BR-SP-SaoPaulo.';


--
-- Name: COLUMN jurisdiction_lexlabel.lex_isoinlevel1; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON COLUMN api.jurisdiction_lexlabel.lex_isoinlevel1 IS 'isolabel_ext in lex format, e.g. br;sao.paulo;sao.paulo.';


--
-- Name: COLUMN jurisdiction_lexlabel.lex_isoinlevel2; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON COLUMN api.jurisdiction_lexlabel.lex_isoinlevel2 IS 'isolabel_ext in lex format, e.g. br;sp;sao.paulo.';


--
-- Name: COLUMN jurisdiction_lexlabel.lex_isoinlevel2_abbrev; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON COLUMN api.jurisdiction_lexlabel.lex_isoinlevel2_abbrev IS 'isolabel_ext in lex format, e.g. br;sp;spa.';


--
-- Name: licenses_implieds; Type: TABLE; Schema: license; Owner: postgres
--

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
    info jsonb
);


ALTER TABLE license.licenses_implieds OWNER TO postgres;

--
-- Name: licenses; Type: VIEW; Schema: api; Owner: postgres
--

CREATE VIEW api.licenses AS
 SELECT id_label,
    id_version,
    name,
    family,
    status,
    year,
    is_by,
    is_sa,
    is_noreuse,
    od_conformance,
    osd_conformance,
    maintainer,
    title,
    url,
    license_is_explicit,
    info
   FROM license.licenses_implieds
 LIMIT 100000;


ALTER VIEW api.licenses OWNER TO postgres;

--
-- Name: VIEW licenses; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON VIEW api.licenses IS 'Merge implicit and explicit licenses.';


--
-- Name: redirects; Type: TABLE; Schema: download; Owner: postgres
--

CREATE TABLE download.redirects (
    donor_id text,
    filename_original text,
    package_path text,
    hashedfname text NOT NULL,
    hashedfnameuri text,
    CONSTRAINT redirects_hashedfname_check CHECK ((hashedfname ~ '^[0-9a-f]{64,64}(\.[a-z0-9]+)+$'::text))
);


ALTER TABLE download.redirects OWNER TO postgres;

--
-- Name: donated_packcomponent_cloudcontrol; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.donated_packcomponent_cloudcontrol (
    id bigint NOT NULL,
    packvers_id bigint NOT NULL,
    ftid smallint NOT NULL,
    lineage_md5 text NOT NULL,
    hashedfname text NOT NULL,
    hashedfnameuri text NOT NULL,
    hashedfnametype text NOT NULL,
    info jsonb
);


ALTER TABLE optim.donated_packcomponent_cloudcontrol OWNER TO postgres;

--
-- Name: TABLE donated_packcomponent_cloudcontrol; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.donated_packcomponent_cloudcontrol IS 'Stores filtered file hyperlinks for each publication feature type.';


--
-- Name: COLUMN donated_packcomponent_cloudcontrol.id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent_cloudcontrol.id IS 'bigserial identifier.';


--
-- Name: COLUMN donated_packcomponent_cloudcontrol.packvers_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent_cloudcontrol.packvers_id IS 'donated_PackFileVers identifier.';


--
-- Name: COLUMN donated_packcomponent_cloudcontrol.ftid; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent_cloudcontrol.ftid IS 'Feature type identifier.';


--
-- Name: COLUMN donated_packcomponent_cloudcontrol.lineage_md5; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent_cloudcontrol.lineage_md5 IS 'md5 from the file.';


--
-- Name: COLUMN donated_packcomponent_cloudcontrol.hashedfname; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent_cloudcontrol.hashedfname IS 'name of filtred file.';


--
-- Name: COLUMN donated_packcomponent_cloudcontrol.hashedfnameuri; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent_cloudcontrol.hashedfnameuri IS 'hashedfname file cloud link.';


--
-- Name: COLUMN donated_packcomponent_cloudcontrol.hashedfnametype; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent_cloudcontrol.hashedfnametype IS 'type, csv or shp.';


--
-- Name: COLUMN donated_packcomponent_cloudcontrol.info; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent_cloudcontrol.info IS 'Others information.';


--
-- Name: redirects; Type: VIEW; Schema: api; Owner: postgres
--

CREATE VIEW api.redirects AS
 SELECT redirects.hashedfname AS fhash,
    redirects.hashedfnameuri AS furi
   FROM download.redirects
UNION
 SELECT donated_packcomponent_cloudcontrol.hashedfname AS fhash,
    donated_packcomponent_cloudcontrol.hashedfnameuri AS furi
   FROM optim.donated_packcomponent_cloudcontrol;


ALTER VIEW api.redirects OWNER TO postgres;

--
-- Name: VIEW redirects; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON VIEW api.redirects IS 'Redirects the DL.digital-guard eternal hyperlink to cloud storage.';


--
-- Name: COLUMN redirects.fhash; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON COLUMN api.redirects.fhash IS 'sha256.ext of file.';


--
-- Name: COLUMN redirects.furi; Type: COMMENT; Schema: api; Owner: postgres
--

COMMENT ON COLUMN api.redirects.furi IS 'hashedfname file cloud link.';


--
-- Name: jurisdiction_eez; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.jurisdiction_eez (
    osm_id bigint NOT NULL,
    isolabel_ext text NOT NULL,
    geom public.geometry(Geometry,4326),
    geom_svg public.geometry(Geometry,4326)
);


ALTER TABLE optim.jurisdiction_eez OWNER TO postgres;

--
-- Name: TABLE jurisdiction_eez; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.jurisdiction_eez IS 'OpenStreetMap exclusive economic zone (EEZ) for optim.jurisdiction.';


--
-- Name: COLUMN jurisdiction_eez.osm_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_eez.osm_id IS 'Relation identifier in OpenStreetMap.';


--
-- Name: COLUMN jurisdiction_eez.isolabel_ext; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_eez.isolabel_ext IS 'ISO 3166-1 alpha-2 code; e.g. BR.';


--
-- Name: COLUMN jurisdiction_eez.geom; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_eez.geom IS 'Geometry for osm_id identifier';


--
-- Name: COLUMN jurisdiction_eez.geom_svg; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_eez.geom_svg IS 'Simplified geometry version to use in svg interface.';


--
-- Name: jurisdiction_geom; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.jurisdiction_geom (
    osm_id bigint NOT NULL,
    isolabel_ext text NOT NULL,
    geom public.geometry(Geometry,4326),
    geom_svg public.geometry(Geometry,4326),
    kx_ghs1_intersects text[],
    kx_ghs2_intersects text[]
);


ALTER TABLE optim.jurisdiction_geom OWNER TO postgres;

--
-- Name: TABLE jurisdiction_geom; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.jurisdiction_geom IS 'OpenStreetMap geometries for optim.jurisdiction.';


--
-- Name: COLUMN jurisdiction_geom.osm_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_geom.osm_id IS 'Relation identifier in OpenStreetMap.';


--
-- Name: COLUMN jurisdiction_geom.isolabel_ext; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_geom.isolabel_ext IS 'ISO 3166-1 alpha-2 code and name (camel case); e.g. BR-SP-SaoPaulo.';


--
-- Name: COLUMN jurisdiction_geom.geom; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_geom.geom IS 'Geometry for osm_id identifier';


--
-- Name: COLUMN jurisdiction_geom.geom_svg; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_geom.geom_svg IS 'Simplified geometry version to use in svg interface.';


--
-- Name: vw01full_jurisdiction_geom; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw01full_jurisdiction_geom AS
 SELECT j.osm_id,
    j.jurisd_base_id,
    j.jurisd_local_id,
    j.parent_id,
    j.admin_level,
    j.name,
    j.parent_abbrev,
    j.abbrev,
    j.wikidata_id,
    j.lexlabel,
    j.isolabel_ext,
    j.ddd,
    j.housenumber_system_type,
    j.lex_urn,
    j.info,
    j.name_en,
    j.isolevel,
    j.ne_country_id,
    j.int_country_id,
        CASE
            WHEN ((e.geom IS NOT NULL) AND (j.isolevel = 1) AND (((j.info ->> 'use_jurisdiction_eez'::text))::boolean IS TRUE)) THEN public.st_union(g.geom, e.geom)
            ELSE g.geom
        END AS geom
   FROM ((optim.jurisdiction j
     LEFT JOIN optim.jurisdiction_geom g ON ((j.osm_id = g.osm_id)))
     LEFT JOIN optim.jurisdiction_eez e ON ((j.isolabel_ext = e.isolabel_ext)));


ALTER VIEW optim.vw01full_jurisdiction_geom OWNER TO postgres;

--
-- Name: VIEW vw01full_jurisdiction_geom; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vw01full_jurisdiction_geom IS 'Add geom to optim.jurisdiction. For countries (isolevel=1) with use_jurisdiction_eez=true, merges land and EEZ geometries using ST_Union.';


--
-- Name: jurisd; Type: VIEW; Schema: br_custom_buffer; Owner: postgres
--

CREATE VIEW br_custom_buffer.jurisd AS
 SELECT osm_id AS gid,
    public.st_transform(public.st_simplifypreservetopology(public.st_buffer(public.st_transform(geom, 3395), (
        CASE
            WHEN (isolevel = 1) THEN 500
            ELSE 50
        END)::double precision), (5)::double precision), 10857) AS geom
   FROM optim.vw01full_jurisdiction_geom
  WHERE (isolabel_ext = 'BR'::text);


ALTER VIEW br_custom_buffer.jurisd OWNER TO postgres;

--
-- Name: type_logistic_export_csv; Type: TABLE; Schema: grid; Owner: postgres
--

CREATE TABLE grid.type_logistic_export_csv (
    jurisd_local_id text,
    gid bigint,
    code_b32nvu text,
    geom text
);


ALTER TABLE grid.type_logistic_export_csv OWNER TO postgres;

--
-- Name: fdw_donatedpackar; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donatedpackar (
    pack_id integer,
    donor_id integer,
    pack_count integer,
    lst_vers integer,
    user_resp text,
    accepted_date date,
    scope text,
    about text,
    author text,
    contentreferencetime text,
    license_is_explicit text,
    license text,
    uri_objtype text,
    uri text,
    isat_urbigis text,
    status text,
    statusupdatedate text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-AR/data/donatedPack.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donatedpackar OWNER TO postgres;

--
-- Name: fdw_donatedpackbo; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donatedpackbo (
    pack_id integer,
    donor_id integer,
    pack_count integer,
    lst_vers integer,
    user_resp text,
    accepted_date date,
    scope text,
    about text,
    author text,
    contentreferencetime text,
    license_is_explicit text,
    license text,
    uri_objtype text,
    uri text,
    isat_urbigis text,
    status text,
    statusupdatedate text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-BO/data/donatedPack.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donatedpackbo OWNER TO postgres;

--
-- Name: fdw_donatedpackbr; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donatedpackbr (
    pack_id integer,
    donor_id integer,
    pack_count integer,
    lst_vers integer,
    user_resp text,
    accepted_date date,
    scope text,
    about text,
    author text,
    contentreferencetime text,
    license_is_explicit text,
    license text,
    uri_objtype text,
    uri text,
    isat_urbigis text,
    status text,
    statusupdatedate text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-BR/data/donatedPack.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donatedpackbr OWNER TO postgres;

--
-- Name: fdw_donatedpackcl; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donatedpackcl (
    pack_id integer,
    donor_id integer,
    pack_count integer,
    lst_vers integer,
    user_resp text,
    accepted_date date,
    scope text,
    about text,
    author text,
    contentreferencetime text,
    license_is_explicit text,
    license text,
    uri_objtype text,
    uri text,
    isat_urbigis text,
    status text,
    statusupdatedate text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-CL/data/donatedPack.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donatedpackcl OWNER TO postgres;

--
-- Name: fdw_donatedpackco; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donatedpackco (
    pack_id integer,
    donor_id integer,
    pack_count integer,
    lst_vers integer,
    user_resp text,
    accepted_date date,
    scope text,
    about text,
    author text,
    contentreferencetime text,
    license_is_explicit text,
    license text,
    uri_objtype text,
    uri text,
    isat_urbigis text,
    status text,
    statusupdatedate text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-CO/data/donatedPack.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donatedpackco OWNER TO postgres;

--
-- Name: fdw_donatedpackec; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donatedpackec (
    pack_id integer,
    donor_id integer,
    pack_count integer,
    lst_vers integer,
    user_resp text,
    accepted_date date,
    scope text,
    about text,
    author text,
    contentreferencetime text,
    license_is_explicit text,
    license text,
    uri_objtype text,
    uri text,
    isat_urbigis text,
    status text,
    statusupdatedate text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-EC/data/donatedPack.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donatedpackec OWNER TO postgres;

--
-- Name: fdw_donatedpackmx; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donatedpackmx (
    pack_id integer,
    donor_id integer,
    pack_count integer,
    lst_vers integer,
    user_resp text,
    accepted_date date,
    scope text,
    about text,
    author text,
    contentreferencetime text,
    license_is_explicit text,
    license text,
    uri_objtype text,
    uri text,
    isat_urbigis text,
    status text,
    statusupdatedate text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-MX/data/donatedPack.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donatedpackmx OWNER TO postgres;

--
-- Name: fdw_donatedpackpe; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donatedpackpe (
    pack_id integer,
    donor_id integer,
    pack_count integer,
    lst_vers integer,
    user_resp text,
    accepted_date date,
    scope text,
    about text,
    author text,
    contentreferencetime text,
    license_is_explicit text,
    license text,
    uri_objtype text,
    uri text,
    isat_urbigis text,
    status text,
    statusupdatedate text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-PE/data/donatedPack.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donatedpackpe OWNER TO postgres;

--
-- Name: fdw_donatedpackpy; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donatedpackpy (
    pack_id integer,
    donor_id integer,
    pack_count integer,
    lst_vers integer,
    user_resp text,
    accepted_date date,
    scope text,
    about text,
    author text,
    contentreferencetime text,
    license_is_explicit text,
    license text,
    uri_objtype text,
    uri text,
    isat_urbigis text,
    status text,
    statusupdatedate text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-PY/data/donatedPack.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donatedpackpy OWNER TO postgres;

--
-- Name: fdw_donatedpacksr; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donatedpacksr (
    pack_id integer,
    donor_id integer,
    pack_count integer,
    lst_vers integer,
    user_resp text,
    accepted_date date,
    scope text,
    about text,
    author text,
    contentreferencetime text,
    license_is_explicit text,
    license text,
    uri_objtype text,
    uri text,
    isat_urbigis text,
    status text,
    statusupdatedate text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-SR/data/donatedPack.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donatedpacksr OWNER TO postgres;

--
-- Name: fdw_donatedpackuy; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donatedpackuy (
    pack_id integer,
    donor_id integer,
    pack_count integer,
    lst_vers integer,
    user_resp text,
    accepted_date date,
    scope text,
    about text,
    author text,
    contentreferencetime text,
    license_is_explicit text,
    license text,
    uri_objtype text,
    uri text,
    isat_urbigis text,
    status text,
    statusupdatedate text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-UY/data/donatedPack.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donatedpackuy OWNER TO postgres;

--
-- Name: fdw_donatedpackve; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donatedpackve (
    pack_id integer,
    donor_id integer,
    pack_count integer,
    lst_vers integer,
    user_resp text,
    accepted_date date,
    scope text,
    about text,
    author text,
    contentreferencetime text,
    license_is_explicit text,
    license text,
    uri_objtype text,
    uri text,
    isat_urbigis text,
    status text,
    statusupdatedate text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-VE/data/donatedPack.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donatedpackve OWNER TO postgres;

--
-- Name: fdw_donorar; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donorar (
    local_id text,
    scope_label text,
    vat_id text,
    "legalName" text,
    wikidata_id text,
    url text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-AR/data/donor.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donorar OWNER TO postgres;

--
-- Name: fdw_donorbo; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donorbo (
    local_id text,
    scope_label text,
    vat_id text,
    "legalName" text,
    wikidata_id text,
    url text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-BO/data/donor.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donorbo OWNER TO postgres;

--
-- Name: fdw_donorbr; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donorbr (
    local_id text,
    scope_label text,
    vat_id text,
    "legalName" text,
    wikidata_id text,
    url text,
    donor_date text,
    donor_status text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-BR/data/donor.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donorbr OWNER TO postgres;

--
-- Name: fdw_donorcl; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donorcl (
    local_id text,
    scope_label text,
    vat_id text,
    "legalName" text,
    wikidata_id text,
    url text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-CL/data/donor.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donorcl OWNER TO postgres;

--
-- Name: fdw_donorco; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donorco (
    local_id text,
    scope_label text,
    vat_id text,
    "legalName" text,
    wikidata_id text,
    url text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-CO/data/donor.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donorco OWNER TO postgres;

--
-- Name: fdw_donorec; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donorec (
    local_id text,
    scope_label text,
    vat_id text,
    "legalName" text,
    wikidata_id text,
    url text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-EC/data/donor.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donorec OWNER TO postgres;

--
-- Name: fdw_donormx; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donormx (
    local_id text,
    scope_label text,
    vat_id text,
    "legalName" text,
    wikidata_id text,
    url text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-MX/data/donor.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donormx OWNER TO postgres;

--
-- Name: fdw_donorpe; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donorpe (
    local_id text,
    scope_label text,
    vat_id text,
    "legalName" text,
    wikidata_id text,
    url text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-PE/data/donor.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donorpe OWNER TO postgres;

--
-- Name: fdw_donorpy; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donorpy (
    local_id text,
    scope_label text,
    vat_id text,
    "legalName" text,
    wikidata_id text,
    url text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-PY/data/donor.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donorpy OWNER TO postgres;

--
-- Name: fdw_donorsr; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donorsr (
    local_id text,
    scope_label text,
    vat_id text,
    "legalName" text,
    wikidata_id text,
    url text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-SR/data/donor.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donorsr OWNER TO postgres;

--
-- Name: fdw_donoruy; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donoruy (
    local_id text,
    scope_label text,
    vat_id text,
    "legalName" text,
    wikidata_id text,
    url text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-UY/data/donor.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donoruy OWNER TO postgres;

--
-- Name: fdw_donorve; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_donorve (
    local_id text,
    scope_label text,
    vat_id text,
    "legalName" text,
    wikidata_id text,
    url text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv-VE/data/donor.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_donorve OWNER TO postgres;

--
-- Name: donatedpacks_donor; Type: VIEW; Schema: tmp_orig; Owner: postgres
--

CREATE VIEW tmp_orig.donatedpacks_donor AS
 SELECT 'br'::text AS jurisdiction,
    r.pack_id,
    r.donor_id,
    r.pack_count,
    r.lst_vers,
    r.user_resp,
    r.accepted_date,
    r.scope,
    r.about,
    r.author,
    r.contentreferencetime,
    r.license_is_explicit,
    r.license,
    r.uri_objtype,
    r.uri,
    r.isat_urbigis,
    r.status,
    r.statusupdatedate,
    s.local_id,
    s.scope_label,
    s.vat_id,
    s."legalName",
    s.wikidata_id,
    s.url,
    s.donor_date,
    s.donor_status
   FROM (tmp_orig.fdw_donatedpackbr r
     LEFT JOIN tmp_orig.fdw_donorbr s ON (((s.local_id)::integer = r.donor_id)))
UNION ALL
 SELECT 'ar'::text AS jurisdiction,
    r.pack_id,
    r.donor_id,
    r.pack_count,
    r.lst_vers,
    r.user_resp,
    r.accepted_date,
    r.scope,
    r.about,
    r.author,
    r.contentreferencetime,
    r.license_is_explicit,
    r.license,
    r.uri_objtype,
    r.uri,
    r.isat_urbigis,
    r.status,
    r.statusupdatedate,
    s.local_id,
    s.scope_label,
    s.vat_id,
    s."legalName",
    s.wikidata_id,
    s.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM (tmp_orig.fdw_donatedpackar r
     LEFT JOIN tmp_orig.fdw_donorar s ON (((s.local_id)::integer = r.donor_id)))
UNION ALL
 SELECT 'bo'::text AS jurisdiction,
    r.pack_id,
    r.donor_id,
    r.pack_count,
    r.lst_vers,
    r.user_resp,
    r.accepted_date,
    r.scope,
    r.about,
    r.author,
    r.contentreferencetime,
    r.license_is_explicit,
    r.license,
    r.uri_objtype,
    r.uri,
    r.isat_urbigis,
    r.status,
    r.statusupdatedate,
    s.local_id,
    s.scope_label,
    s.vat_id,
    s."legalName",
    s.wikidata_id,
    s.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM (tmp_orig.fdw_donatedpackbo r
     LEFT JOIN tmp_orig.fdw_donorbo s ON (((s.local_id)::integer = r.donor_id)))
UNION ALL
 SELECT 'cl'::text AS jurisdiction,
    r.pack_id,
    r.donor_id,
    r.pack_count,
    r.lst_vers,
    r.user_resp,
    r.accepted_date,
    r.scope,
    r.about,
    r.author,
    r.contentreferencetime,
    r.license_is_explicit,
    r.license,
    r.uri_objtype,
    r.uri,
    r.isat_urbigis,
    r.status,
    r.statusupdatedate,
    s.local_id,
    s.scope_label,
    s.vat_id,
    s."legalName",
    s.wikidata_id,
    s.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM (tmp_orig.fdw_donatedpackcl r
     LEFT JOIN tmp_orig.fdw_donorcl s ON (((s.local_id)::integer = r.donor_id)))
UNION ALL
 SELECT 'co'::text AS jurisdiction,
    r.pack_id,
    r.donor_id,
    r.pack_count,
    r.lst_vers,
    r.user_resp,
    r.accepted_date,
    r.scope,
    r.about,
    r.author,
    r.contentreferencetime,
    r.license_is_explicit,
    r.license,
    r.uri_objtype,
    r.uri,
    r.isat_urbigis,
    r.status,
    r.statusupdatedate,
    s.local_id,
    s.scope_label,
    s.vat_id,
    s."legalName",
    s.wikidata_id,
    s.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM (tmp_orig.fdw_donatedpackco r
     LEFT JOIN tmp_orig.fdw_donorco s ON (((s.local_id)::integer = r.donor_id)))
UNION ALL
 SELECT 'ec'::text AS jurisdiction,
    r.pack_id,
    r.donor_id,
    r.pack_count,
    r.lst_vers,
    r.user_resp,
    r.accepted_date,
    r.scope,
    r.about,
    r.author,
    r.contentreferencetime,
    r.license_is_explicit,
    r.license,
    r.uri_objtype,
    r.uri,
    r.isat_urbigis,
    r.status,
    r.statusupdatedate,
    s.local_id,
    s.scope_label,
    s.vat_id,
    s."legalName",
    s.wikidata_id,
    s.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM (tmp_orig.fdw_donatedpackec r
     LEFT JOIN tmp_orig.fdw_donorec s ON (((s.local_id)::integer = r.donor_id)))
UNION ALL
 SELECT 'mx'::text AS jurisdiction,
    r.pack_id,
    r.donor_id,
    r.pack_count,
    r.lst_vers,
    r.user_resp,
    r.accepted_date,
    r.scope,
    r.about,
    r.author,
    r.contentreferencetime,
    r.license_is_explicit,
    r.license,
    r.uri_objtype,
    r.uri,
    r.isat_urbigis,
    r.status,
    r.statusupdatedate,
    s.local_id,
    s.scope_label,
    s.vat_id,
    s."legalName",
    s.wikidata_id,
    s.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM (tmp_orig.fdw_donatedpackmx r
     LEFT JOIN tmp_orig.fdw_donormx s ON (((s.local_id)::integer = r.donor_id)))
UNION ALL
 SELECT 'pe'::text AS jurisdiction,
    r.pack_id,
    r.donor_id,
    r.pack_count,
    r.lst_vers,
    r.user_resp,
    r.accepted_date,
    r.scope,
    r.about,
    r.author,
    r.contentreferencetime,
    r.license_is_explicit,
    r.license,
    r.uri_objtype,
    r.uri,
    r.isat_urbigis,
    r.status,
    r.statusupdatedate,
    s.local_id,
    s.scope_label,
    s.vat_id,
    s."legalName",
    s.wikidata_id,
    s.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM (tmp_orig.fdw_donatedpackpe r
     LEFT JOIN tmp_orig.fdw_donorpe s ON (((s.local_id)::integer = r.donor_id)))
UNION ALL
 SELECT 'py'::text AS jurisdiction,
    r.pack_id,
    r.donor_id,
    r.pack_count,
    r.lst_vers,
    r.user_resp,
    r.accepted_date,
    r.scope,
    r.about,
    r.author,
    r.contentreferencetime,
    r.license_is_explicit,
    r.license,
    r.uri_objtype,
    r.uri,
    r.isat_urbigis,
    r.status,
    r.statusupdatedate,
    s.local_id,
    s.scope_label,
    s.vat_id,
    s."legalName",
    s.wikidata_id,
    s.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM (tmp_orig.fdw_donatedpackpy r
     LEFT JOIN tmp_orig.fdw_donorpy s ON (((s.local_id)::integer = r.donor_id)))
UNION ALL
 SELECT 'sr'::text AS jurisdiction,
    r.pack_id,
    r.donor_id,
    r.pack_count,
    r.lst_vers,
    r.user_resp,
    r.accepted_date,
    r.scope,
    r.about,
    r.author,
    r.contentreferencetime,
    r.license_is_explicit,
    r.license,
    r.uri_objtype,
    r.uri,
    r.isat_urbigis,
    r.status,
    r.statusupdatedate,
    s.local_id,
    s.scope_label,
    s.vat_id,
    s."legalName",
    s.wikidata_id,
    s.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM (tmp_orig.fdw_donatedpacksr r
     LEFT JOIN tmp_orig.fdw_donorsr s ON (((s.local_id)::integer = r.donor_id)))
UNION ALL
 SELECT 'uy'::text AS jurisdiction,
    r.pack_id,
    r.donor_id,
    r.pack_count,
    r.lst_vers,
    r.user_resp,
    r.accepted_date,
    r.scope,
    r.about,
    r.author,
    r.contentreferencetime,
    r.license_is_explicit,
    r.license,
    r.uri_objtype,
    r.uri,
    r.isat_urbigis,
    r.status,
    r.statusupdatedate,
    s.local_id,
    s.scope_label,
    s.vat_id,
    s."legalName",
    s.wikidata_id,
    s.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM (tmp_orig.fdw_donatedpackuy r
     LEFT JOIN tmp_orig.fdw_donoruy s ON (((s.local_id)::integer = r.donor_id)))
UNION ALL
 SELECT 've'::text AS jurisdiction,
    r.pack_id,
    r.donor_id,
    r.pack_count,
    r.lst_vers,
    r.user_resp,
    r.accepted_date,
    r.scope,
    r.about,
    r.author,
    r.contentreferencetime,
    r.license_is_explicit,
    r.license,
    r.uri_objtype,
    r.uri,
    r.isat_urbigis,
    r.status,
    r.statusupdatedate,
    s.local_id,
    s.scope_label,
    s.vat_id,
    s."legalName",
    s.wikidata_id,
    s.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM (tmp_orig.fdw_donatedpackve r
     LEFT JOIN tmp_orig.fdw_donorve s ON (((s.local_id)::integer = r.donor_id)));


ALTER VIEW tmp_orig.donatedpacks_donor OWNER TO postgres;

--
-- Name: pack_licenses; Type: VIEW; Schema: license; Owner: postgres
--

CREATE VIEW license.pack_licenses AS
 SELECT d.pack_id,
    d.jurisdiction,
    l.id_label,
    l.id_version,
    l.name,
    l.family,
    l.status,
    l.year,
    l.is_by,
    l.is_sa,
    l.is_noreuse,
    l.od_conformance,
    l.osd_conformance,
    l.maintainer,
    l.title,
    l.url,
    l.license_is_explicit,
    l.info
   FROM (tmp_orig.donatedpacks_donor d
     LEFT JOIN license.licenses_implieds l ON (((lower(d.license) = lower(((l.id_label || '-'::text) || l.id_version))) AND (d.license_is_explicit = l.license_is_explicit))));


ALTER VIEW license.pack_licenses OWNER TO postgres;

--
-- Name: auth_user; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.auth_user (
    username text NOT NULL,
    info jsonb
);


ALTER TABLE optim.auth_user OWNER TO postgres;

--
-- Name: TABLE auth_user; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.auth_user IS 'Authorized users to be a data pack responsible.';


--
-- Name: COLUMN auth_user.username; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.auth_user.username IS 'username in host account.';


--
-- Name: COLUMN auth_user.info; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.auth_user.info IS 'Other account details on host.';


--
-- Name: codec_type; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.codec_type (
    extension text,
    variant text,
    descr_mime jsonb,
    descr_encode jsonb
);


ALTER TABLE optim.codec_type OWNER TO postgres;

--
-- Name: TABLE codec_type; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.codec_type IS 'Custom codec for ingesting files.';


--
-- Name: consolidated_data; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.consolidated_data (
    id bigint NOT NULL,
    afa_id bigint NOT NULL,
    via_type text,
    via_name text,
    house_number text,
    postcode text,
    geom_frontparcel boolean,
    score text,
    geom public.geometry(Geometry,4326)
);


ALTER TABLE optim.consolidated_data OWNER TO postgres;

--
-- Name: TABLE consolidated_data; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.consolidated_data IS 'Data from ingestion (ingest.vwconsolidated_data) to be consolidated.';


--
-- Name: COLUMN consolidated_data.id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.consolidated_data.id IS 'donated_PackComponent identifier.';


--
-- Name: COLUMN consolidated_data.afa_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.consolidated_data.afa_id IS 'AFAcodes scientific. 64bits format.';


--
-- Name: COLUMN consolidated_data.via_type; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.consolidated_data.via_type IS 'Via type.';


--
-- Name: COLUMN consolidated_data.via_name; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.consolidated_data.via_name IS 'Via name.';


--
-- Name: COLUMN consolidated_data.house_number; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.consolidated_data.house_number IS 'House number.';


--
-- Name: COLUMN consolidated_data.postcode; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.consolidated_data.postcode IS 'Postal code.';


--
-- Name: COLUMN consolidated_data.geom_frontparcel; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.consolidated_data.geom_frontparcel IS 'Flag. Indicates if geometry is in front of the parcel.';


--
-- Name: COLUMN consolidated_data.score; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.consolidated_data.score IS '...';


--
-- Name: COLUMN consolidated_data.geom; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.consolidated_data.geom IS 'Feature geometry.';


--
-- Name: consolidated_data_pre; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.consolidated_data_pre (
    id bigint NOT NULL,
    via_name text,
    house_number text,
    postcode text,
    geom_frontparcel boolean,
    score text,
    geom public.geometry(Geometry,4326)
);


ALTER TABLE optim.consolidated_data_pre OWNER TO postgres;

--
-- Name: TABLE consolidated_data_pre; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.consolidated_data_pre IS 'Data from ingestion (ingest.vwconsolidated_data) to be consolidated.';


--
-- Name: COLUMN consolidated_data_pre.id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.consolidated_data_pre.id IS 'donated_PackComponent identifier.';


--
-- Name: COLUMN consolidated_data_pre.via_name; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.consolidated_data_pre.via_name IS 'Via name.';


--
-- Name: COLUMN consolidated_data_pre.house_number; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.consolidated_data_pre.house_number IS 'House number.';


--
-- Name: COLUMN consolidated_data_pre.postcode; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.consolidated_data_pre.postcode IS 'Postal code.';


--
-- Name: COLUMN consolidated_data_pre.geom_frontparcel; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.consolidated_data_pre.geom_frontparcel IS 'Flag. Indicates if geometry is in front of the parcel.';


--
-- Name: COLUMN consolidated_data_pre.score; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.consolidated_data_pre.score IS '...';


--
-- Name: COLUMN consolidated_data_pre.geom; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.consolidated_data_pre.geom IS 'Feature geometry.';


--
-- Name: donated_packcomponent; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.donated_packcomponent (
    id bigint NOT NULL,
    packvers_id bigint NOT NULL,
    ftid smallint NOT NULL,
    is_evidence boolean DEFAULT false,
    proc_step integer DEFAULT 1,
    lineage jsonb NOT NULL,
    lineage_md5 text NOT NULL,
    kx_profile jsonb
);


ALTER TABLE optim.donated_packcomponent OWNER TO postgres;

--
-- Name: TABLE donated_packcomponent; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.donated_packcomponent IS 'Stores definitive descriptive summaries of each published feature type.';


--
-- Name: COLUMN donated_packcomponent.id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent.id IS 'bigserial identifier.';


--
-- Name: COLUMN donated_packcomponent.packvers_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent.packvers_id IS 'donated_PackFileVers identifier.';


--
-- Name: COLUMN donated_packcomponent.ftid; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent.ftid IS 'Feature type identifier.';


--
-- Name: COLUMN donated_packcomponent.proc_step; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent.proc_step IS 'Date of approval of the donation.';


--
-- Name: COLUMN donated_packcomponent.lineage; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent.lineage IS 'General information.';


--
-- Name: COLUMN donated_packcomponent.lineage_md5; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent.lineage_md5 IS 'md5 from the file.';


--
-- Name: COLUMN donated_packcomponent.kx_profile; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent.kx_profile IS 'Others information.';


--
-- Name: donated_packcomponent_cloudcontrol_id_seq; Type: SEQUENCE; Schema: optim; Owner: postgres
--

CREATE SEQUENCE optim.donated_packcomponent_cloudcontrol_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE optim.donated_packcomponent_cloudcontrol_id_seq OWNER TO postgres;

--
-- Name: donated_packcomponent_cloudcontrol_id_seq; Type: SEQUENCE OWNED BY; Schema: optim; Owner: postgres
--

ALTER SEQUENCE optim.donated_packcomponent_cloudcontrol_id_seq OWNED BY optim.donated_packcomponent_cloudcontrol.id;


--
-- Name: donated_packcomponent_id_seq; Type: SEQUENCE; Schema: optim; Owner: postgres
--

CREATE SEQUENCE optim.donated_packcomponent_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE optim.donated_packcomponent_id_seq OWNER TO postgres;

--
-- Name: donated_packcomponent_id_seq; Type: SEQUENCE OWNED BY; Schema: optim; Owner: postgres
--

ALTER SEQUENCE optim.donated_packcomponent_id_seq OWNED BY optim.donated_packcomponent.id;


--
-- Name: donated_packcomponent_not_approved; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.donated_packcomponent_not_approved (
    id bigint NOT NULL,
    packvers_id bigint NOT NULL,
    ftid smallint NOT NULL,
    is_evidence boolean DEFAULT false,
    proc_step integer DEFAULT 1,
    lineage jsonb NOT NULL,
    lineage_md5 text NOT NULL,
    kx_profile jsonb
);


ALTER TABLE optim.donated_packcomponent_not_approved OWNER TO postgres;

--
-- Name: TABLE donated_packcomponent_not_approved; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.donated_packcomponent_not_approved IS 'Stores descriptive summaries of each feature type awaiting publication approval.';


--
-- Name: COLUMN donated_packcomponent_not_approved.id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent_not_approved.id IS 'bigserial identifier.';


--
-- Name: COLUMN donated_packcomponent_not_approved.packvers_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent_not_approved.packvers_id IS 'donated_PackFileVers identifier.';


--
-- Name: COLUMN donated_packcomponent_not_approved.ftid; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent_not_approved.ftid IS 'Feature type identifier.';


--
-- Name: COLUMN donated_packcomponent_not_approved.proc_step; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent_not_approved.proc_step IS 'Date of approval of the donation.';


--
-- Name: COLUMN donated_packcomponent_not_approved.lineage; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent_not_approved.lineage IS 'General information.';


--
-- Name: COLUMN donated_packcomponent_not_approved.lineage_md5; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent_not_approved.lineage_md5 IS 'md5 from the file.';


--
-- Name: COLUMN donated_packcomponent_not_approved.kx_profile; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packcomponent_not_approved.kx_profile IS 'Others information.';


--
-- Name: donated_packcomponent_not_approved_id_seq; Type: SEQUENCE; Schema: optim; Owner: postgres
--

CREATE SEQUENCE optim.donated_packcomponent_not_approved_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE optim.donated_packcomponent_not_approved_id_seq OWNER TO postgres;

--
-- Name: donated_packcomponent_not_approved_id_seq; Type: SEQUENCE OWNED BY; Schema: optim; Owner: postgres
--

ALTER SEQUENCE optim.donated_packcomponent_not_approved_id_seq OWNED BY optim.donated_packcomponent_not_approved.id;


--
-- Name: donated_packfilevers; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.donated_packfilevers (
    id bigint NOT NULL,
    hashedfname text NOT NULL,
    pack_id bigint NOT NULL,
    pack_item integer DEFAULT 1 NOT NULL,
    pack_item_accepted_date date NOT NULL,
    kx_pack_item_version integer DEFAULT 1 NOT NULL,
    user_resp text NOT NULL,
    info jsonb,
    CONSTRAINT donated_packfilevers_check CHECK ((id = (((pack_id * 1000) + (pack_item * 100)) + kx_pack_item_version))),
    CONSTRAINT donated_packfilevers_hashedfname_check CHECK ((hashedfname ~ '^[0-9a-f]{64,64}\.[a-z0-9]+$'::text))
);


ALTER TABLE optim.donated_packfilevers OWNER TO postgres;

--
-- Name: TABLE donated_packfilevers; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.donated_packfilevers IS 'Stores history of donated package versions.';


--
-- Name: COLUMN donated_packfilevers.id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packfilevers.id IS 'id=pack_id*1000+pack_item*100+kx_pack_item_version';


--
-- Name: COLUMN donated_packfilevers.hashedfname; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packfilevers.hashedfname IS 'sha256.ext of file.';


--
-- Name: COLUMN donated_packfilevers.pack_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packfilevers.pack_id IS 'donated_PackTpl identifier.';


--
-- Name: COLUMN donated_packfilevers.pack_item; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packfilevers.pack_item IS 'make_conf_tpl->files->file corresponding to hashedfname.';


--
-- Name: COLUMN donated_packfilevers.pack_item_accepted_date; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packfilevers.pack_item_accepted_date IS 'Date of approval of the donation.';


--
-- Name: COLUMN donated_packfilevers.kx_pack_item_version; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packfilevers.kx_pack_item_version IS 'Version (serial) corresponding to pack_item_accepted_date. Trigger: next value.';


--
-- Name: COLUMN donated_packfilevers.user_resp; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packfilevers.user_resp IS 'User responsible for ingesting the file.';


--
-- Name: COLUMN donated_packfilevers.info; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packfilevers.info IS 'Others information.';


--
-- Name: donated_packtpl; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.donated_packtpl (
    id bigint NOT NULL,
    donor_id integer NOT NULL,
    user_resp text NOT NULL,
    pk_count integer NOT NULL,
    original_tpl text NOT NULL,
    make_conf_tpl jsonb,
    kx_num_files integer,
    info jsonb,
    license text,
    CONSTRAINT donated_packtpl_check CHECK ((id = (((donor_id)::bigint * (100)::bigint) + (pk_count)::bigint))),
    CONSTRAINT donated_packtpl_pk_count_check CHECK ((pk_count > 0))
);


ALTER TABLE optim.donated_packtpl OWNER TO postgres;

--
-- Name: TABLE donated_packtpl; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.donated_packtpl IS 'Donated pack template, unversioned package, only pack_id control and input logging. Only metadata common to versions.';


--
-- Name: COLUMN donated_packtpl.id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packtpl.id IS 'id = donor_id::bigint*100::bigint + pk_count::bigint';


--
-- Name: COLUMN donated_packtpl.donor_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packtpl.donor_id IS 'Package donor identifier.';


--
-- Name: COLUMN donated_packtpl.user_resp; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packtpl.user_resp IS 'User responsible for the README and makefile testing.';


--
-- Name: COLUMN donated_packtpl.pk_count; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packtpl.pk_count IS 'Serial number of the package donated by the donor.';


--
-- Name: COLUMN donated_packtpl.original_tpl; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packtpl.original_tpl IS 'make_conf.yaml backup by replacing "version" and "file" with mustache placeholder.';


--
-- Name: COLUMN donated_packtpl.make_conf_tpl; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packtpl.make_conf_tpl IS 'Cache, parsing result from original_tpl (YAML) to JSON.';


--
-- Name: COLUMN donated_packtpl.kx_num_files; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packtpl.kx_num_files IS 'Cache for jsonb_array_length(make_conf_tpl->files).';


--
-- Name: COLUMN donated_packtpl.info; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packtpl.info IS 'Others information.';


--
-- Name: COLUMN donated_packtpl.license; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donated_packtpl.license IS 'License of the package donated by the donor.';


--
-- Name: donor; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.donor (
    id integer NOT NULL,
    country_id integer NOT NULL,
    local_serial integer NOT NULL,
    scope_osm_id bigint NOT NULL,
    scope_label text,
    shortname text,
    vat_id text,
    legalname text NOT NULL,
    wikidata_id bigint,
    url text,
    info jsonb,
    kx_vat_id text,
    CONSTRAINT donor_check CHECK ((id = ((country_id * 1000000) + local_serial))),
    CONSTRAINT donor_country_id_check CHECK ((country_id > 0)),
    CONSTRAINT donor_local_serial_check CHECK ((local_serial > 0))
);


ALTER TABLE optim.donor OWNER TO postgres;

--
-- Name: TABLE donor; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.donor IS 'Data package donor information.';


--
-- Name: COLUMN donor.id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donor.id IS 'id = country_id*1000000+local_serial';


--
-- Name: COLUMN donor.country_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donor.country_id IS 'ISO3166-1-numeric COUNTRY ID (e.g. Brazil is 76) or negative for non-iso (ex. oceans).';


--
-- Name: COLUMN donor.local_serial; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donor.local_serial IS 'Numeric official ID like IBGE_ID of BR jurisdiction. For example ACRE is 12 and its cities are {1200013, 1200054,etc}.';


--
-- Name: COLUMN donor.scope_osm_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donor.scope_osm_id IS 'osm_id of jurisdiction.';


--
-- Name: COLUMN donor.scope_label; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donor.scope_label IS 'OSM convention for admin_level tag in country.';


--
-- Name: COLUMN donor.shortname; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donor.shortname IS 'Abreviation or acronym (local)';


--
-- Name: COLUMN donor.vat_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donor.vat_id IS 'in the Brazilian case is CNPJ number.';


--
-- Name: COLUMN donor.legalname; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donor.legalname IS 'in the Brazilian case is Razao Social.';


--
-- Name: COLUMN donor.wikidata_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donor.wikidata_id IS 'wikidata identifier without Q prefix.';


--
-- Name: COLUMN donor.url; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donor.url IS 'Official home page of the organization.';


--
-- Name: COLUMN donor.info; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donor.info IS 'Others information.';


--
-- Name: COLUMN donor.kx_vat_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.donor.kx_vat_id IS 'Cache for normalized vat_id.';


--
-- Name: feature_type; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.feature_type (
    ftid smallint NOT NULL,
    ftname text NOT NULL,
    geomtype text NOT NULL,
    need_join boolean,
    description text NOT NULL,
    info jsonb,
    CONSTRAINT feature_type_ftname_check CHECK ((lower(ftname) = ftname)),
    CONSTRAINT feature_type_geomtype_check CHECK ((lower(geomtype) = geomtype))
);


ALTER TABLE optim.feature_type OWNER TO postgres;

--
-- Name: TABLE feature_type; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.feature_type IS 'Describes the types of data that can be ingested.';


--
-- Name: COLUMN feature_type.ftid; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.feature_type.ftid IS 'Feature type numeric identifier.';


--
-- Name: COLUMN feature_type.ftname; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.feature_type.ftname IS 'Feature type name.';


--
-- Name: COLUMN feature_type.geomtype; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.feature_type.geomtype IS 'Feature type geometry type.';


--
-- Name: COLUMN feature_type.need_join; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.feature_type.need_join IS 'If feature type needs join. false=no, true=yes, null=both (at class)';


--
-- Name: COLUMN feature_type.description; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.feature_type.description IS 'Feature type description.';


--
-- Name: COLUMN feature_type.info; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.feature_type.info IS 'Others information.';


--
-- Name: housenumber_system_type; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.housenumber_system_type (
    hstid smallint NOT NULL,
    hstname text NOT NULL,
    regex_sort text NOT NULL,
    description text NOT NULL,
    CONSTRAINT housenumber_system_type_hstname_check CHECK ((lower(hstname) = hstname))
);


ALTER TABLE optim.housenumber_system_type OWNER TO postgres;

--
-- Name: TABLE housenumber_system_type; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.housenumber_system_type IS 'Stores descriptive house numbering systems.';


--
-- Name: jurisdiction_abbrev_option; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.jurisdiction_abbrev_option (
    selected boolean DEFAULT false NOT NULL,
    abbrevref_id integer NOT NULL,
    isolabel_ext text NOT NULL,
    abbrev text NOT NULL,
    insert_date date DEFAULT now() NOT NULL,
    default_abbrev boolean DEFAULT false NOT NULL
);


ALTER TABLE optim.jurisdiction_abbrev_option OWNER TO postgres;

--
-- Name: TABLE jurisdiction_abbrev_option; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.jurisdiction_abbrev_option IS 'Stores abbreviations for a jurisdiction.';


--
-- Name: COLUMN jurisdiction_abbrev_option.selected; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_abbrev_option.selected IS 'Standard jurisdiction abbreviation.';


--
-- Name: COLUMN jurisdiction_abbrev_option.abbrevref_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_abbrev_option.abbrevref_id IS 'optim.jurisdiction_abbrev_ref primary key referencek.';


--
-- Name: COLUMN jurisdiction_abbrev_option.isolabel_ext; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_abbrev_option.isolabel_ext IS 'ISO and name (camel case), e.g. BR-SP-SaoPaulo.';


--
-- Name: COLUMN jurisdiction_abbrev_option.abbrev; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_abbrev_option.abbrev IS 'Abbreviation.';


--
-- Name: COLUMN jurisdiction_abbrev_option.insert_date; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_abbrev_option.insert_date IS 'Date the abbreviation was added.';


--
-- Name: COLUMN jurisdiction_abbrev_option.default_abbrev; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_abbrev_option.default_abbrev IS 'Abbreviation.';


--
-- Name: jurisdiction_abbrev_ref; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.jurisdiction_abbrev_ref (
    abbrevref_id integer NOT NULL,
    name text NOT NULL,
    info jsonb NOT NULL
);


ALTER TABLE optim.jurisdiction_abbrev_ref OWNER TO postgres;

--
-- Name: TABLE jurisdiction_abbrev_ref; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.jurisdiction_abbrev_ref IS 'Source for abbreviation of jurisdictions.';


--
-- Name: COLUMN jurisdiction_abbrev_ref.abbrevref_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_abbrev_ref.abbrevref_id IS 'Source identifier.';


--
-- Name: COLUMN jurisdiction_abbrev_ref.name; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_abbrev_ref.name IS 'Source name.';


--
-- Name: COLUMN jurisdiction_abbrev_ref.info; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_abbrev_ref.info IS 'Others information.';


--
-- Name: jurisdiction_geom_buffer; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.jurisdiction_geom_buffer (
    osm_id bigint NOT NULL,
    isolabel_ext text NOT NULL,
    geom public.geometry(Geometry,4326)
);


ALTER TABLE optim.jurisdiction_geom_buffer OWNER TO postgres;

--
-- Name: TABLE jurisdiction_geom_buffer; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.jurisdiction_geom_buffer IS 'OpenStreetMap geometries for optim.jurisdiction.';


--
-- Name: COLUMN jurisdiction_geom_buffer.osm_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_geom_buffer.osm_id IS 'Relation identifier in OpenStreetMap.';


--
-- Name: COLUMN jurisdiction_geom_buffer.isolabel_ext; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_geom_buffer.isolabel_ext IS 'ISO 3166-1 alpha-2 code and name (camel case); e.g. BR-SP-SaoPaulo.';


--
-- Name: COLUMN jurisdiction_geom_buffer.geom; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_geom_buffer.geom IS 'Geometry for osm_id identifier';


--
-- Name: jurisdiction_geom_point; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.jurisdiction_geom_point (
    osm_id bigint NOT NULL,
    isolabel_ext text,
    jurisd_local_id integer,
    wikidata_id bigint,
    geom public.geometry(Point,4326)
);


ALTER TABLE optim.jurisdiction_geom_point OWNER TO postgres;

--
-- Name: TABLE jurisdiction_geom_point; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.jurisdiction_geom_point IS 'Wikidata point for optim.jurisdiction.';


--
-- Name: COLUMN jurisdiction_geom_point.osm_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_geom_point.osm_id IS 'Relation identifier in OpenStreetMap.';


--
-- Name: COLUMN jurisdiction_geom_point.isolabel_ext; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_geom_point.isolabel_ext IS 'ISO 3166-1 alpha-2 code and name (camel case); e.g. BR-SP-SaoPaulo.';


--
-- Name: COLUMN jurisdiction_geom_point.jurisd_local_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_geom_point.jurisd_local_id IS 'Numeric official ID like IBGE_ID of BR jurisdiction. For example ACRE is 12 and its cities are {1200013, 1200054,etc}.';


--
-- Name: COLUMN jurisdiction_geom_point.wikidata_id; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_geom_point.wikidata_id IS 'wikidata identifier without Q prefix.';


--
-- Name: COLUMN jurisdiction_geom_point.geom; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.jurisdiction_geom_point.geom IS 'Geometry for osm_id identifier';


--
-- Name: vw01full_donated_packtpl; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw01full_donated_packtpl AS
 SELECT pt.id AS packtpl_id,
    pt.donor_id,
    pt.user_resp AS user_resp_packtpl,
    au.info AS user_resp_packtpl_info,
    pt.pk_count,
    pt.original_tpl,
    pt.make_conf_tpl,
    pt.kx_num_files,
    (pt.info || jsonb_build_object('accepted_date_ptbr', to_char((((pt.info ->> 'accepted_date'::text))::date)::timestamp with time zone, 'DD/MM/YYYY'::text), 'accepted_date_en', to_char((((pt.info ->> 'accepted_date'::text))::date)::timestamp with time zone, 'MM/DD/YYYY'::text), 'accepted_date_es', to_char((((pt.info ->> 'accepted_date'::text))::date)::timestamp with time zone, 'DD/MM/YYYY'::text))) AS packtpl_info,
    dn.country_id,
    dn.local_serial,
    dn.scope_osm_id,
    dn.scope_label,
    dn.shortname,
    dn.vat_id,
    dn.legalname,
    dn.wikidata_id,
    dn.url,
    dn.info AS donor_info,
    dn.kx_vat_id,
    j.osm_id,
    j.jurisd_base_id,
    j.jurisd_local_id,
    j.parent_id,
    j.admin_level,
    j.name,
    j.parent_abbrev,
    j.abbrev,
    j.wikidata_id AS jurisdiction_wikidata_id,
    j.lexlabel,
    j.isolabel_ext,
    j.ddd,
    j.housenumber_system_type,
    j.lex_urn,
    j.info AS jurisdiction_info,
    j.isolevel,
    to_char(dn.local_serial, 'fm0000'::text) AS local_serial_formated,
    ((to_char(dn.local_serial, 'fm0000'::text) || '.'::text) || to_char(pt.pk_count, 'fm00'::text)) AS pack_number,
    ((((('/var/gits/_dg/preservCutGeo-'::text || regexp_replace(replace(regexp_replace(j.isolabel_ext, '^([^-]*)-?'::text, '\12021/data/'::text), '-'::text, '/'::text), '\/$'::text, ''::text)) || '/_pk'::text) || to_char(dn.local_serial, 'fm0000'::text)) || '.'::text) || to_char(pt.pk_count, 'fm00'::text)) AS path_cutgeo_server,
    ((((('/var/gits/_dg/preserv-'::text || regexp_replace(replace(regexp_replace(j.isolabel_ext, '^([^-]*)-?'::text, '\1/data/'::text), '-'::text, '/'::text), '\/$'::text, ''::text)) || '/_pk'::text) || to_char(dn.local_serial, 'fm0000'::text)) || '.'::text) || to_char(pt.pk_count, 'fm00'::text)) AS path_preserv_server,
    ((((('https://git.digital-guard.org/preserv-'::text || regexp_replace(replace(regexp_replace(j.isolabel_ext, '^([^-]*)-?'::text, '\1/blob/main/data/'::text), '-'::text, '/'::text), '\/$'::text, ''::text)) || '/_pk'::text) || to_char(dn.local_serial, 'fm0000'::text)) || '.'::text) || to_char(pt.pk_count, 'fm00'::text)) AS path_preserv_git,
    ((((('https://git.digital-guard.org/preservCutGeo-'::text || regexp_replace(replace(regexp_replace(j.isolabel_ext, '^([^-]*)-?'::text, '\12021/tree/main/data/'::text), '-'::text, '/'::text), '\/$'::text, ''::text)) || '/_pk'::text) || to_char(dn.local_serial, 'fm0000'::text)) || '.'::text) || to_char(pt.pk_count, 'fm00'::text)) AS path_cutgeo_git,
    (('preservCutGeo-'::text || split_part(j.isolabel_ext, '-'::text, 1)) || '2021'::text) AS repo_cutgeo_name,
    (to_char(dn.local_serial, 'fm000'::text) || to_char(pt.pk_count, 'fm00'::text)) AS pack_number_donatedpackcsv,
    initcap(pt.user_resp) AS user_resp_packtpl_initcap,
    upper(split_part(dn.vat_id, ':'::text, 1)) AS vat_id_p1,
    split_part(dn.vat_id, ':'::text, 2) AS vat_id_p2,
    (to_jsonb(l.*) || jsonb_build_object('isimplicit',
        CASE lower(l.license_is_explicit)
            WHEN 'no'::text THEN true
            ELSE false
        END)) AS license_data
   FROM ((((optim.donated_packtpl pt
     LEFT JOIN optim.donor dn ON ((pt.donor_id = dn.id)))
     LEFT JOIN optim.jurisdiction j ON ((dn.scope_osm_id = j.osm_id)))
     LEFT JOIN optim.auth_user au ON ((pt.user_resp = au.username)))
     LEFT JOIN license.licenses_implieds l ON ((lower(pt.license) = lower(replace(l.name, ' '::text, '-'::text)))));


ALTER VIEW optim.vw01full_donated_packtpl OWNER TO postgres;

--
-- Name: VIEW vw01full_donated_packtpl; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vw01full_donated_packtpl IS 'Add geom to optim.jurisdiction.';


--
-- Name: reproducibility; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.reproducibility AS
 SELECT packtpl_id,
    donor_id,
    user_resp_packtpl,
    user_resp_packtpl_info,
    pk_count,
    original_tpl,
    make_conf_tpl,
    kx_num_files,
    packtpl_info,
    country_id,
    local_serial,
    scope_osm_id,
    scope_label,
    shortname,
    vat_id,
    legalname,
    wikidata_id,
    url,
    donor_info,
    kx_vat_id,
    osm_id,
    jurisd_base_id,
    jurisd_local_id,
    parent_id,
    admin_level,
    name,
    parent_abbrev,
    abbrev,
    jurisdiction_wikidata_id,
    lexlabel,
    isolabel_ext,
    ddd,
    housenumber_system_type,
    lex_urn,
    jurisdiction_info,
    isolevel,
    local_serial_formated,
    pack_number,
    path_cutgeo_server,
    path_preserv_server,
    path_preserv_git,
    path_cutgeo_git,
    repo_cutgeo_name,
    pack_number_donatedpackcsv,
    user_resp_packtpl_initcap,
    vat_id_p1,
    vat_id_p2,
    license_data,
    optim.generate_commands(split_part(isolabel_ext, '-'::text, 1), path_preserv_server, '/var/gits/_dg'::text) AS commands
   FROM optim.vw01full_donated_packtpl pt
  WHERE (path_preserv_server <> '/var/gits/_dg/preserv-BR/data/PR/Curitiba/_pk0002.01'::text)
  ORDER BY packtpl_id;


ALTER VIEW optim.reproducibility OWNER TO postgres;

--
-- Name: templates; Type: TABLE; Schema: optim; Owner: postgres
--

CREATE TABLE optim.templates (
    template_name text NOT NULL,
    template_content text
);


ALTER TABLE optim.templates OWNER TO postgres;

--
-- Name: TABLE templates; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON TABLE optim.templates IS 'vw03_metadata_viz uses pg_read_file. Table to avoid the error on api.metadata_viz:  permission denied for function pg_read_file. Recreate the table if the templates change.';


--
-- Name: vw01donorevidencecmd; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw01donorevidencecmd AS
 SELECT isolabel_ext,
    iso,
    line,
    p,
    path,
        CASE
            WHEN ((is_cctld IS TRUE) AND (upper(p[array_upper(p, 1)]) = 'BR'::text)) THEN concat('mkdir -p ', path, ' && wget https://rdap.registro.br/domain/', line, ' > ', path, '/rdap.json')
            ELSE concat('mkdir -p ', path, ' && rdap -v -j ', line, ' > ', path, '/rdap.json')
        END AS commandline_rdap
   FROM ( SELECT t3.isolabel_ext,
            t3.iso,
            t3.line,
            t3.p,
            t3.is_cctld,
                CASE cardinality(t3.p)
                    WHEN 2 THEN concat('/var/gits/_dg/preserv-', t3.iso, '/data/_donorEvidence/', t3.p[2], '/', t3.p[1], '.', t3.p[2])
                    WHEN 3 THEN concat('/var/gits/_dg/preserv-', t3.iso, '/data/_donorEvidence/', t3.p[3], '/', t3.p[2], '.', t3.p[3], '/', t3.p[1], '.', t3.p[2], '.', t3.p[3])
                    WHEN 4 THEN concat('/var/gits/_dg/preserv-', t3.iso, '/data/_donorEvidence/', t3.p[4], '/', t3.p[3], '.', t3.p[4], '/', t3.p[2], '.', t3.p[3], '.', t3.p[4], '/', t3.p[1], '.', t3.p[2], '.', t3.p[3], '.', t3.p[4])
                    WHEN 5 THEN concat('/var/gits/_dg/preserv-', t3.iso, '/data/_donorEvidence/', t3.p[5], '/', t3.p[4], '.', t3.p[5], '/', t3.p[3], '.', t3.p[4], '.', t3.p[5], '/', t3.p[2], '.', t3.p[3], '.', t3.p[4], '.', t3.p[5], '/', t3.p[1], '.', t3.p[2], '.', t3.p[3], '.', t3.p[4], '.', t3.p[5])
                    WHEN 6 THEN concat('/var/gits/_dg/preserv-', t3.iso, '/data/_donorEvidence/', t3.p[6], '/', t3.p[5], '.', t3.p[6], '/', t3.p[4], '.', t3.p[5], '.', t3.p[6], '/', t3.p[3], '.', t3.p[4], '.', t3.p[5], '.', t3.p[6], '/', t3.p[2], '.', t3.p[3], '.', t3.p[4], '.', t3.p[5], '.', t3.p[6], '/', t3.p[1], '.', t3.p[2], '.', t3.p[3], '.', t3.p[4], '.', t3.p[5], '.', t3.p[6])
                    ELSE ''::text
                END AS path
           FROM ( SELECT t2.isolabel_ext,
                    t2.iso,
                    t2.line,
                    t2.p,
                        CASE
                            WHEN (upper(t2.p[array_upper(t2.p, 1)]) IN ( SELECT jurisdiction.isolabel_ext
                               FROM optim.jurisdiction
                              WHERE (jurisdiction.isolevel = 1))) THEN true
                            ELSE false
                        END AS is_cctld
                   FROM ( SELECT DISTINCT t1.isolabel_ext,
                            split_part(t1.isolabel_ext, '-'::text, 1) AS iso,
                            t1.line,
                            regexp_split_to_array(t1.line, '\.'::text) AS p
                           FROM ( SELECT j.isolabel_ext,
                                    public.str_url_todomain(dn.url) AS line
                                   FROM (optim.donor dn
                                     LEFT JOIN optim.jurisdiction j ON ((dn.scope_osm_id = j.osm_id)))
                                UNION
                                 SELECT vw01full_donated_packtpl.isolabel_ext,
                                    public.str_url_todomain((vw01full_donated_packtpl.packtpl_info ->> 'uri'::text)) AS line
                                   FROM optim.vw01full_donated_packtpl) t1
                          WHERE (t1.line > ''::text)
                          ORDER BY t1.isolabel_ext, (split_part(t1.isolabel_ext, '-'::text, 1))) t2) t3) t4;


ALTER VIEW optim.vw01donorevidencecmd OWNER TO postgres;

--
-- Name: VIEW vw01donorevidencecmd; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vw01donorevidencecmd IS 'Generate commands to update or create evidences for donor and donatedPack.';


--
-- Name: vw01full_packfilevers; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw01full_packfilevers AS
 SELECT pf.id,
    pf.hashedfname,
    pf.pack_id,
    pf.pack_item,
    pf.pack_item_accepted_date,
    pf.kx_pack_item_version,
    pf.user_resp,
    pf.info,
    pt.packtpl_id,
    pt.donor_id,
    pt.user_resp_packtpl,
    pt.user_resp_packtpl_info,
    pt.pk_count,
    pt.original_tpl,
    pt.make_conf_tpl,
    pt.kx_num_files,
    pt.packtpl_info,
    pt.country_id,
    pt.local_serial,
    pt.scope_osm_id,
    pt.scope_label,
    pt.shortname,
    pt.vat_id,
    pt.legalname,
    pt.wikidata_id,
    pt.url,
    pt.donor_info,
    pt.kx_vat_id,
    pt.osm_id,
    pt.jurisd_base_id,
    pt.jurisd_local_id,
    pt.parent_id,
    pt.admin_level,
    pt.name,
    pt.parent_abbrev,
    pt.abbrev,
    pt.jurisdiction_wikidata_id,
    pt.lexlabel,
    pt.isolabel_ext,
    pt.ddd,
    pt.housenumber_system_type,
    pt.lex_urn,
    pt.jurisdiction_info,
    pt.isolevel,
    pt.local_serial_formated,
    pt.pack_number,
    pt.path_cutgeo_server,
    pt.path_preserv_server,
    pt.path_preserv_git,
    pt.path_cutgeo_git,
    pt.repo_cutgeo_name,
    pt.pack_number_donatedpackcsv,
    pt.user_resp_packtpl_initcap,
    pt.vat_id_p1,
    pt.vat_id_p2,
    pt.license_data,
    "substring"(pf.hashedfname, '^([0-9a-f]{7}).+$'::text) AS hashedfname_7,
    "substring"(pf.hashedfname, '^([0-9a-f]{64,64})\.[a-z0-9]+$'::text) AS hashedfname_without_ext,
    (("substring"(pf.hashedfname, '^([0-9a-f]{7}).+$'::text) || '...'::text) || "substring"(pf.hashedfname, '^.+\.([a-z0-9]+)$'::text)) AS hashedfname_7_ext,
    ('https://dl.digital-guard.org/'::text || pf.hashedfname) AS hashedfname_url,
    initcap(pf.user_resp) AS user_resp_initcap,
    au.info AS user_resp_packfilevers_info
   FROM ((( SELECT donated_packfilevers.id,
            donated_packfilevers.hashedfname,
            donated_packfilevers.pack_id,
            donated_packfilevers.pack_item,
            donated_packfilevers.pack_item_accepted_date,
            donated_packfilevers.kx_pack_item_version,
            donated_packfilevers.user_resp,
            donated_packfilevers.info
           FROM optim.donated_packfilevers
          WHERE ((donated_packfilevers.pack_id, donated_packfilevers.pack_item, donated_packfilevers.kx_pack_item_version) IN ( SELECT donated_packfilevers_1.pack_id,
                    donated_packfilevers_1.pack_item,
                    max(donated_packfilevers_1.kx_pack_item_version) AS max
                   FROM optim.donated_packfilevers donated_packfilevers_1
                  GROUP BY donated_packfilevers_1.pack_id, donated_packfilevers_1.pack_item
                  ORDER BY donated_packfilevers_1.pack_id, donated_packfilevers_1.pack_item))) pf
     LEFT JOIN optim.vw01full_donated_packtpl pt ON ((pf.pack_id = pt.packtpl_id)))
     LEFT JOIN optim.auth_user au ON ((pf.user_resp = au.username)))
  ORDER BY pt.isolabel_ext, pt.local_serial, pt.pk_count;


ALTER VIEW optim.vw01full_packfilevers OWNER TO postgres;

--
-- Name: VIEW vw01full_packfilevers; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vw01full_packfilevers IS 'Join donated_packfilevers with donated_PackTpl and auth_user.';


--
-- Name: vw01info_feature_type; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw01info_feature_type AS
 SELECT ftid,
    ftname,
    geomtype,
    need_join,
    description,
    (COALESCE(info, '{}'::jsonb) || ( SELECT to_jsonb(t2.*) AS to_jsonb
           FROM ( SELECT c.ftid AS class_ftid,
                    c.ftname AS class_ftname,
                    c.description AS class_description,
                    c.info AS class_info
                   FROM optim.feature_type c
                  WHERE ((c.geomtype = 'class'::text) AND ((c.ftid)::double precision = ((5)::double precision * round(((f.ftid / 5))::double precision))))) t2)) AS info
   FROM optim.feature_type f
  WHERE (geomtype <> 'class'::text);


ALTER VIEW optim.vw01info_feature_type OWNER TO postgres;

--
-- Name: VIEW vw01info_feature_type; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vw01info_feature_type IS 'Adds class_ftname, class_description and class_info to optim.feature_type.info.';


--
-- Name: vw01full_packfilevers_ftype; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw01full_packfilevers_ftype AS
 SELECT pf.id,
    pf.hashedfname,
    pf.pack_id,
    pf.pack_item,
    pf.pack_item_accepted_date,
    pf.kx_pack_item_version,
    pf.user_resp,
    pf.info,
    pf.packtpl_id,
    pf.donor_id,
    pf.user_resp_packtpl,
    pf.user_resp_packtpl_info,
    pf.pk_count,
    pf.original_tpl,
    pf.make_conf_tpl,
    pf.kx_num_files,
    pf.packtpl_info,
    pf.country_id,
    pf.local_serial,
    pf.scope_osm_id,
    pf.scope_label,
    pf.shortname,
    pf.vat_id,
    pf.legalname,
    pf.wikidata_id,
    pf.url,
    pf.donor_info,
    pf.kx_vat_id,
    pf.osm_id,
    pf.jurisd_base_id,
    pf.jurisd_local_id,
    pf.parent_id,
    pf.admin_level,
    pf.name,
    pf.parent_abbrev,
    pf.abbrev,
    pf.jurisdiction_wikidata_id,
    pf.lexlabel,
    pf.isolabel_ext,
    pf.ddd,
    pf.housenumber_system_type,
    pf.lex_urn,
    pf.jurisdiction_info,
    pf.isolevel,
    pf.local_serial_formated,
    pf.pack_number,
    pf.path_cutgeo_server,
    pf.path_preserv_server,
    pf.path_preserv_git,
    pf.path_cutgeo_git,
    pf.repo_cutgeo_name,
    pf.pack_number_donatedpackcsv,
    pf.user_resp_packtpl_initcap,
    pf.vat_id_p1,
    pf.vat_id_p2,
    pf.license_data,
    pf.hashedfname_7,
    pf.hashedfname_without_ext,
    pf.hashedfname_7_ext,
    pf.hashedfname_url,
    pf.user_resp_initcap,
    pf.user_resp_packfilevers_info,
    pf.layer,
    ft.ftid,
    ft.ftname,
    ft.geomtype,
    ft.need_join,
    ft.description,
    ft.info AS ftype_info,
    ((((lower(replace(pf.isolabel_ext, '-'::text, '_'::text)) || '_pk'::text) || replace(pf.pack_number, '.'::text, '_'::text)) || '_'::text) || (ft.info ->> 'class_ftname'::text)) AS full_name_layer
   FROM (( SELECT vw01full_packfilevers.id,
            vw01full_packfilevers.hashedfname,
            vw01full_packfilevers.pack_id,
            vw01full_packfilevers.pack_item,
            vw01full_packfilevers.pack_item_accepted_date,
            vw01full_packfilevers.kx_pack_item_version,
            vw01full_packfilevers.user_resp,
            vw01full_packfilevers.info,
            vw01full_packfilevers.packtpl_id,
            vw01full_packfilevers.donor_id,
            vw01full_packfilevers.user_resp_packtpl,
            vw01full_packfilevers.user_resp_packtpl_info,
            vw01full_packfilevers.pk_count,
            vw01full_packfilevers.original_tpl,
            vw01full_packfilevers.make_conf_tpl,
            vw01full_packfilevers.kx_num_files,
            vw01full_packfilevers.packtpl_info,
            vw01full_packfilevers.country_id,
            vw01full_packfilevers.local_serial,
            vw01full_packfilevers.scope_osm_id,
            vw01full_packfilevers.scope_label,
            vw01full_packfilevers.shortname,
            vw01full_packfilevers.vat_id,
            vw01full_packfilevers.legalname,
            vw01full_packfilevers.wikidata_id,
            vw01full_packfilevers.url,
            vw01full_packfilevers.donor_info,
            vw01full_packfilevers.kx_vat_id,
            vw01full_packfilevers.osm_id,
            vw01full_packfilevers.jurisd_base_id,
            vw01full_packfilevers.jurisd_local_id,
            vw01full_packfilevers.parent_id,
            vw01full_packfilevers.admin_level,
            vw01full_packfilevers.name,
            vw01full_packfilevers.parent_abbrev,
            vw01full_packfilevers.abbrev,
            vw01full_packfilevers.jurisdiction_wikidata_id,
            vw01full_packfilevers.lexlabel,
            vw01full_packfilevers.isolabel_ext,
            vw01full_packfilevers.ddd,
            vw01full_packfilevers.housenumber_system_type,
            vw01full_packfilevers.lex_urn,
            vw01full_packfilevers.jurisdiction_info,
            vw01full_packfilevers.isolevel,
            vw01full_packfilevers.local_serial_formated,
            vw01full_packfilevers.pack_number,
            vw01full_packfilevers.path_cutgeo_server,
            vw01full_packfilevers.path_preserv_server,
            vw01full_packfilevers.path_preserv_git,
            vw01full_packfilevers.path_cutgeo_git,
            vw01full_packfilevers.repo_cutgeo_name,
            vw01full_packfilevers.pack_number_donatedpackcsv,
            vw01full_packfilevers.user_resp_packtpl_initcap,
            vw01full_packfilevers.vat_id_p1,
            vw01full_packfilevers.vat_id_p2,
            vw01full_packfilevers.license_data,
            vw01full_packfilevers.hashedfname_7,
            vw01full_packfilevers.hashedfname_without_ext,
            vw01full_packfilevers.hashedfname_7_ext,
            vw01full_packfilevers.hashedfname_url,
            vw01full_packfilevers.user_resp_initcap,
            vw01full_packfilevers.user_resp_packfilevers_info,
            jsonb_object_keys((vw01full_packfilevers.make_conf_tpl -> 'layers'::text)) AS layer
           FROM optim.vw01full_packfilevers) pf
     LEFT JOIN optim.vw01info_feature_type ft ON ((ft.ftid = ( SELECT (feature_type.ftid)::integer AS ftid
           FROM optim.feature_type
          WHERE (feature_type.ftname = lower(((pf.layer || '_'::text) || (((pf.make_conf_tpl -> 'layers'::text) -> pf.layer) ->> 'subtype'::text))))))));


ALTER VIEW optim.vw01full_packfilevers_ftype OWNER TO postgres;

--
-- Name: VIEW vw01full_packfilevers_ftype; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vw01full_packfilevers_ftype IS 'Join vw01full_packfilevers with vw01info_feature_type.';


--
-- Name: vw01filtered_files; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw01filtered_files AS
 SELECT pack_id,
    jsonb_build_object('layers', jsonb_agg(jsonb_build_object('class_ftname', class_ftname, 'files', files, 'packvers_id', id))) AS filtered_files
   FROM ( SELECT r.id,
            r.pack_id,
            r.class_ftname,
            jsonb_agg(jsonb_build_object('hashedfname', r.hashedfname, 'hashedfname_url', ('https://dl.digital-guard.org/out/'::text || r.hashedfname), 'hashedfname_7', r.hashedfname_7, 'hashedfnametype', r.hashedfnametype, 'hashedfname_without_ext', r.hashedfname_without_ext, 'hashedfname_7_ext', r.hashedfname_7_ext, 'hashedfnameuri', r.hashedfnameuri)) AS files
           FROM ( SELECT pf.id,
                    pf.pack_id,
                    (pf.ftype_info ->> 'class_ftname'::text) AS class_ftname,
                    "substring"(pc.hashedfname, '^([0-9a-f]{7}).+$'::text) AS hashedfname_7,
                    "substring"(pc.hashedfname, '^([0-9a-f]{64,64})\.[a-z0-9]+$'::text) AS hashedfname_without_ext,
                    (("substring"(pc.hashedfname, '^([0-9a-f]{7}).+$'::text) || '...'::text) || "substring"(pc.hashedfname, '^.+\.([a-z0-9]+)$'::text)) AS hashedfname_7_ext,
                    pc.hashedfname,
                    pc.hashedfnameuri,
                    pc.hashedfnametype
                   FROM (optim.vw01full_packfilevers_ftype pf
                     JOIN optim.donated_packcomponent_cloudcontrol pc ON (((pc.packvers_id = pf.id) AND (pc.ftid = pf.ftid))))
                  ORDER BY pf.pack_id, (pf.ftype_info ->> 'class_ftname'::text), pc.hashedfnametype, pc.hashedfname) r
          GROUP BY r.id, r.pack_id, r.class_ftname) s
  GROUP BY pack_id;


ALTER VIEW optim.vw01filtered_files OWNER TO postgres;

--
-- Name: VIEW vw01filtered_files; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vw01filtered_files IS 'Filtered files in a package.';


--
-- Name: vw01fromcutlayer_tovizlayer; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw01fromcutlayer_tovizlayer AS
 SELECT pc.id,
    pc.packvers_id,
    pc.ftid,
    pc.lineage_md5,
    pc.hashedfname,
    pc.hashedfnameuri,
    pc.hashedfnametype,
    pc.info,
    ((((pf.isolabel_ext || '/_pk'::text) || pf.pack_number) || '/'::text) || (pf.ftype_info ->> 'class_ftname'::text)) AS jurisdiction_pack_layer,
    pf.hashedfname AS hash_from,
    ('https://addressforall.maps.arcgis.com/apps/mapviewer/index.html?layers='::text || (pc.info ->> 'pub_id'::text)) AS url_layer_visualization,
    (((((('https://dl.digital-guard.org/out/a4a_'::text || replace(lower(pf.isolabel_ext), '-'::text, '_'::text)) || '_'::text) || (pf.ftype_info ->> 'class_ftname'::text)) || '_'::text) || pc.packvers_id) || '.zip'::text) AS uri_default,
    pc.hashedfnameuri AS cloud_uri,
    pc.hashedfnametype AS filetype,
    pf.path_preserv_git AS uri_preserv,
    pf.path_cutgeo_git AS uri_cutgeo
   FROM (optim.donated_packcomponent_cloudcontrol pc
     JOIN optim.vw01full_packfilevers_ftype pf ON (((pc.packvers_id = pf.id) AND (pc.ftid = pf.ftid))))
  WHERE (pc.hashedfnametype = 'shp'::text)
  ORDER BY pf.pack_id, (pf.ftype_info ->> 'class_ftname'::text), pc.hashedfnametype, pc.hashedfname;


ALTER VIEW optim.vw01fromcutlayer_tovizlayer OWNER TO postgres;

--
-- Name: VIEW vw01fromcutlayer_tovizlayer; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vw01fromcutlayer_tovizlayer IS 'For fromCutLayer_toVizLayer csv.';


--
-- Name: vw01full_donated_packcomponent; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw01full_donated_packcomponent AS
 SELECT pf.id,
    pf.hashedfname,
    pf.pack_id,
    pf.pack_item,
    pf.pack_item_accepted_date,
    pf.kx_pack_item_version,
    pf.user_resp,
    pf.info,
    pf.packtpl_id,
    pf.donor_id,
    pf.user_resp_packtpl,
    pf.user_resp_packtpl_info,
    pf.pk_count,
    pf.original_tpl,
    pf.make_conf_tpl,
    pf.kx_num_files,
    pf.packtpl_info,
    pf.country_id,
    pf.local_serial,
    pf.scope_osm_id,
    pf.scope_label,
    pf.shortname,
    pf.vat_id,
    pf.legalname,
    pf.wikidata_id,
    pf.url,
    pf.donor_info,
    pf.kx_vat_id,
    pf.osm_id,
    pf.jurisd_base_id,
    pf.jurisd_local_id,
    pf.parent_id,
    pf.admin_level,
    pf.name,
    pf.parent_abbrev,
    pf.abbrev,
    pf.jurisdiction_wikidata_id,
    pf.lexlabel,
    pf.isolabel_ext,
    pf.ddd,
    pf.housenumber_system_type,
    pf.lex_urn,
    pf.jurisdiction_info,
    pf.isolevel,
    pf.local_serial_formated,
    pf.pack_number,
    pf.path_cutgeo_server,
    pf.path_preserv_server,
    pf.path_preserv_git,
    pf.path_cutgeo_git,
    pf.repo_cutgeo_name,
    pf.pack_number_donatedpackcsv,
    pf.user_resp_packtpl_initcap,
    pf.vat_id_p1,
    pf.vat_id_p2,
    pf.license_data,
    pf.hashedfname_7,
    pf.hashedfname_without_ext,
    pf.hashedfname_7_ext,
    pf.hashedfname_url,
    pf.user_resp_initcap,
    pf.user_resp_packfilevers_info,
    pf.layer,
    pf.ftid,
    pf.ftname,
    pf.geomtype,
    pf.need_join,
    pf.description,
    pf.ftype_info,
    pf.full_name_layer,
    pc.id AS id_component,
    pc.proc_step,
    pc.lineage,
    pc.lineage_md5,
    pc.kx_profile,
    (((((('a4a_'::text || replace(lower(pf.isolabel_ext), '-'::text, '_'::text)) || '_'::text) || (pf.ftype_info ->> 'class_ftname'::text)) || '_'::text) || pf.id) || '.zip'::text) AS filtered_name,
    (((((lower(pf.isolabel_ext) || '_pk'::text) || pf.pack_number) || '_'::text) || (pf.ftype_info ->> 'class_ftname'::text)) || '.html'::text) AS url_page
   FROM (optim.vw01full_packfilevers_ftype pf
     JOIN optim.donated_packcomponent pc ON (((pc.packvers_id = pf.id) AND (pc.ftid = pf.ftid))));


ALTER VIEW optim.vw01full_donated_packcomponent OWNER TO postgres;

--
-- Name: VIEW vw01full_donated_packcomponent; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vw01full_donated_packcomponent IS 'Join vw01full_packfilevers_ftype with donated_PackComponent.';


--
-- Name: vw01full_jurisdiction_geom_point; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw01full_jurisdiction_geom_point AS
 SELECT j.osm_id,
    j.jurisd_base_id,
    j.jurisd_local_id,
    j.parent_id,
    j.admin_level,
    j.name,
    j.parent_abbrev,
    j.abbrev,
    j.wikidata_id,
    j.lexlabel,
    j.isolabel_ext,
    j.ddd,
    j.housenumber_system_type,
    j.lex_urn,
    j.info,
    j.name_en,
    j.isolevel,
    j.ne_country_id,
    j.int_country_id,
    g.geom
   FROM (optim.jurisdiction j
     LEFT JOIN optim.jurisdiction_geom_point g ON ((j.osm_id = g.osm_id)));


ALTER VIEW optim.vw01full_jurisdiction_geom_point OWNER TO postgres;

--
-- Name: VIEW vw01full_jurisdiction_geom_point; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vw01full_jurisdiction_geom_point IS 'Add geom point to optim.jurisdiction.';


--
-- Name: vw01generate_list; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw01generate_list AS
 SELECT r.scope_label,
    r.isolevel,
    (r.pacotes || COALESCE(jsonb_build_object('filtered_files', s.filtered_files), '{}'::jsonb)) AS pacotes
   FROM (( SELECT pf2.pack_id,
            pf2.scope_label,
            pf2.isolevel,
            jsonb_build_object('legalName', pf2.legalname, 'isunpublished',
                CASE
                    WHEN (lower(max(regexp_replace((pf2.packtpl_info ->> 'uri_objtype'::text), '[\s+]|\-'::text, ''::text, 'g'::text))) = 'email'::text) THEN true
                    ELSE false
                END, 'pack_number', max(pf2.pack_number), 'path_preserv_git', max(pf2.path_preserv_git), 'local_serial_formated', max(pf2.local_serial_formated), 'pacotes', jsonb_agg(pf2.*), 'license_data', pf2.license_data) AS pacotes
           FROM ( SELECT pf.id,
                    pf.hashedfname,
                    pf.pack_id,
                    pf.pack_item,
                    pf.pack_item_accepted_date,
                    pf.kx_pack_item_version,
                    pf.user_resp,
                    pf.info,
                    pf.packtpl_id,
                    pf.donor_id,
                    pf.user_resp_packtpl,
                    pf.user_resp_packtpl_info,
                    pf.pk_count,
                    pf.original_tpl,
                    pf.make_conf_tpl,
                    pf.kx_num_files,
                    pf.packtpl_info,
                    pf.country_id,
                    pf.local_serial,
                    pf.scope_osm_id,
                    pf.scope_label,
                    pf.shortname,
                    pf.vat_id,
                    pf.legalname,
                    pf.wikidata_id,
                    pf.url,
                    pf.donor_info,
                    pf.kx_vat_id,
                    pf.osm_id,
                    pf.jurisd_base_id,
                    pf.jurisd_local_id,
                    pf.parent_id,
                    pf.admin_level,
                    pf.name,
                    pf.parent_abbrev,
                    pf.abbrev,
                    pf.jurisdiction_wikidata_id,
                    pf.lexlabel,
                    pf.isolabel_ext,
                    pf.ddd,
                    pf.housenumber_system_type,
                    pf.lex_urn,
                    pf.jurisdiction_info,
                    pf.isolevel,
                    pf.local_serial_formated,
                    pf.pack_number,
                    pf.path_cutgeo_server,
                    pf.path_preserv_server,
                    pf.path_preserv_git,
                    pf.path_cutgeo_git,
                    pf.repo_cutgeo_name,
                    pf.pack_number_donatedpackcsv,
                    pf.user_resp_packtpl_initcap,
                    pf.vat_id_p1,
                    pf.vat_id_p2,
                    pf.license_data,
                    pf.hashedfname_7,
                    pf.hashedfname_without_ext,
                    pf.hashedfname_7_ext,
                    pf.hashedfname_url,
                    pf.user_resp_initcap,
                    pf.user_resp_packfilevers_info
                   FROM optim.vw01full_packfilevers pf
                  ORDER BY pf.scope_label, pf.legalname, pf.pack_id, pf.pack_item) pf2
          GROUP BY pf2.country_id, pf2.local_serial, pf2.scope_osm_id, pf2.scope_label, pf2.shortname, pf2.vat_id, pf2.legalname, pf2.wikidata_id, pf2.url, pf2.donor_info, pf2.kx_vat_id, pf2.isolevel, pf2.pack_id, pf2.license_data
          ORDER BY pf2.scope_label, pf2.legalname) r
     LEFT JOIN optim.vw01filtered_files s ON ((r.pack_id = s.pack_id)));


ALTER VIEW optim.vw01generate_list OWNER TO postgres;

--
-- Name: vw01publicating_index; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw01publicating_index AS
 SELECT jsonb_build_object('pages', pages) AS y
   FROM ( SELECT jsonb_agg(t.*) AS pages
           FROM ( SELECT s.isolabel_ext,
                    s.pack_number,
                    s.class_ftname,
                    s.row_num,
                    (((((lower(s.isolabel_ext) || '_pk'::text) || s.pack_number) || '_'::text) || s.class_ftname) || '.html'::text) AS url_page,
                    ((s.isolabel_ext || '/pk'::text) || s.pack_number) AS name
                   FROM ( SELECT r.isolabel_ext,
                            r.pack_number,
                            r.class_ftname,
                            row_number() OVER (PARTITION BY r.isolabel_ext, r.pack_number ORDER BY r.class_ftname) AS row_num
                           FROM ( SELECT pf.isolabel_ext,
                                    pf.pack_number,
                                    (pf.ftype_info ->> 'class_ftname'::text) AS class_ftname
                                   FROM (optim.vw01full_packfilevers_ftype pf
                                     JOIN optim.donated_packcomponent pc ON (((pc.packvers_id = pf.id) AND (pc.ftid = pf.ftid))))
                                  WHERE (pf.ftid > 19)
                                  ORDER BY pf.isolabel_ext, pf.local_serial, pf.pk_count, (pf.ftype_info ->> 'class_ftname'::text)) r) s
                  WHERE (s.row_num = 1)) t) u;


ALTER VIEW optim.vw01publicating_index OWNER TO postgres;

--
-- Name: vw01report; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw01report AS
 SELECT isolabel_ext,
    legalname,
    vat_id,
    "ID de pack_componente",
    ftname,
    ftid,
    step,
    data_feito,
    n_items,
    size
   FROM ( SELECT pf.isolabel_ext,
            pf.legalname,
            pf.vat_id,
            t.packvers_id,
            t.idcomp AS "ID de pack_componente",
            ft.ftname,
            t.ftid,
            t.step,
            t.data_feito,
            (((t.j ->> 'n'::text) || ' '::text) || (t.j ->> 'n_unit'::text)) AS n_items,
            (((t.j ->> 'size'::text) || ' '::text) || (t.j ->> 'size_unit'::text)) AS size
           FROM ((( SELECT r.packvers_id,
                    replace(lib.id_format('packfilevers'::text, r.packvers_id), '076.00'::text, 'br'::text) AS idcomp,
                    r.ftid,
                    r.proc_step AS step,
                    substr(((r.lineage -> 'file_meta'::text) ->> 'modification'::text), 1, 10) AS data_feito,
                    (r.lineage -> 'feature_asis_summary'::text) AS j
                   FROM optim.donated_packcomponent r
                  ORDER BY r.packvers_id) t
             JOIN optim.feature_type ft ON ((ft.ftid = t.ftid)))
             JOIN optim.vw01full_packfilevers pf ON ((t.packvers_id = pf.id)))
          ORDER BY pf.isolabel_ext) g;


ALTER VIEW optim.vw01report OWNER TO postgres;

--
-- Name: VIEW vw01report; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vw01report IS 'Donated package report.';


--
-- Name: vw01report_median; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw01report_median AS
 SELECT isolabel_ext,
    pack_number,
    class_ftname,
    count(ghs) AS n,
    (percentile_disc((0.5)::double precision) WITHIN GROUP (ORDER BY size_bytes) / 1024) AS mdn_n,
    round((avg(size_bytes) / (1024)::numeric)) AS avg_n,
    (min(size_bytes) / 1024) AS min_n,
    (max(size_bytes) / 1024) AS max_n
   FROM ( SELECT s.isolabel_ext,
            s.pack_number,
            s.class_ftname,
            s.ghs,
            ( SELECT pg_stat_file.size
                   FROM pg_stat_file(s.path) pg_stat_file(size, access, modification, change, creation, isdir)) AS size_bytes
           FROM ( SELECT r.isolabel_ext,
                    r.pack_number,
                    r.class_ftname,
                    r.ghs,
                    ((((((((r.path_cutgeo || r.pack_number) || '/'::text) || r.class_ftname) || '/'::text) || r.geom_type_abbr) || '_'::text) || r.ghs) || '.geojson'::text) AS path
                   FROM ( SELECT pf.isolabel_ext,
                            pf.pack_number,
                            (pf.ftype_info ->> 'class_ftname'::text) AS class_ftname,
                            jsonb_object_keys((pc.kx_profile -> 'ghs_distrib_mosaic'::text)) AS ghs,
                            (('/var/gits/_dg/preservCutGeo-'::text || regexp_replace(replace(regexp_replace(pf.isolabel_ext, '^([^-]*)-?'::text, '\12021/data/'::text), '-'::text, '/'::text), '\/$'::text, ''::text)) || '/_pk'::text) AS path_cutgeo,
                                CASE pf.geomtype
                                    WHEN 'poly'::text THEN 'pols'::text
                                    WHEN 'line'::text THEN 'lns'::text
                                    WHEN 'point'::text THEN 'pts'::text
                                    ELSE NULL::text
                                END AS geom_type_abbr
                           FROM (optim.vw01full_packfilevers_ftype pf
                             JOIN optim.donated_packcomponent pc ON (((pc.packvers_id = pf.id) AND (pc.ftid = pf.ftid))))
                          WHERE (pf.ftid > 19)
                          ORDER BY pf.isolabel_ext, pf.local_serial, pf.pk_count, (pf.ftype_info ->> 'class_ftname'::text)) r) s) t
  GROUP BY isolabel_ext, pack_number, class_ftname;


ALTER VIEW optim.vw01report_median OWNER TO postgres;

--
-- Name: VIEW vw01report_median; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vw01report_median IS 'Returns the number of files, median, average, minimum and maximum in kibibytes.';


--
-- Name: vw02generate_list; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw02generate_list AS
 WITH scope_iso3 AS (
         SELECT m.scope_label,
            jsonb_agg(m.iso3) AS iso3
           FROM ( SELECT split_part(vw01generate_list.scope_label, '-'::text, 1) AS scope_label,
                    jsonb_build_object('jurisd', vw01generate_list.scope_label, 'doadores', jsonb_agg(vw01generate_list.pacotes)) AS iso3
                   FROM optim.vw01generate_list
                  WHERE (vw01generate_list.scope_label ~~ '%-%-%'::text)
                  GROUP BY vw01generate_list.scope_label
                  ORDER BY (split_part(vw01generate_list.scope_label, '-'::text, 1))) m
          GROUP BY m.scope_label
        ), scope_iso2 AS (
         SELECT split_part(vw01generate_list.scope_label, '-'::text, 1) AS scope_label,
            jsonb_agg(vw01generate_list.pacotes) AS iso2
           FROM optim.vw01generate_list
          WHERE (vw01generate_list.isolevel = 2)
          GROUP BY (split_part(vw01generate_list.scope_label, '-'::text, 1))
        ), scope_iso1 AS (
         SELECT vw01generate_list.scope_label,
            jsonb_agg(vw01generate_list.pacotes) AS iso1
           FROM optim.vw01generate_list
          WHERE (vw01generate_list.isolevel = 1)
          GROUP BY vw01generate_list.scope_label
        ), jurisdiction AS (
         SELECT h.abbrev AS scope_label,
            (jsonb_agg(h.*) -> 0) AS jurisd
           FROM optim.jurisdiction h
          WHERE (h.isolevel = 1)
          GROUP BY h.abbrev
        ), combined AS (
         SELECT COALESCE(s.scope_label, r.scope_label, t.scope_label) AS scope_label,
            s.iso3,
            t.iso2,
            r.iso1,
            v.jurisd
           FROM ((scope_iso3 s
             FULL JOIN scope_iso1 r ON ((s.scope_label = r.scope_label)))
             FULL JOIN scope_iso2 t ON ((s.scope_label = t.scope_label))),
            LATERAL ( SELECT (jsonb_agg(h.*) -> 0) AS jurisd
                   FROM optim.jurisdiction h
                  WHERE ((h.abbrev = COALESCE(s.scope_label, r.scope_label, t.scope_label)) AND (h.isolevel = 1))) v
        )
 SELECT jsonb_build_object('paises', jsonb_agg(jsonb_build_object('scope_label', scope_label, 'iso1', iso1, 'iso2', iso2, 'iso3', iso3, 'jurisd', jurisd))) AS y
   FROM combined c;


ALTER VIEW optim.vw02generate_list OWNER TO postgres;

--
-- Name: vw02publication; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw02publication AS
 SELECT g.id,
    g.hashedfname,
    g.pack_id,
    g.pack_item,
    g.pack_item_accepted_date,
    g.kx_pack_item_version,
    g.user_resp,
    g.info,
    g.packtpl_id,
    g.donor_id,
    g.user_resp_packtpl,
    g.user_resp_packtpl_info,
    g.pk_count,
    g.original_tpl,
    g.make_conf_tpl,
    g.kx_num_files,
    g.packtpl_info,
    g.country_id,
    g.local_serial,
    g.scope_osm_id,
    g.scope_label,
    g.shortname,
    g.vat_id,
    g.legalname,
    g.wikidata_id,
    g.url,
    g.donor_info,
    g.kx_vat_id,
    g.osm_id,
    g.jurisd_base_id,
    g.jurisd_local_id,
    g.parent_id,
    g.admin_level,
    g.name,
    g.parent_abbrev,
    g.abbrev,
    g.jurisdiction_wikidata_id,
    g.lexlabel,
    g.isolabel_ext,
    g.ddd,
    g.housenumber_system_type,
    g.lex_urn,
    g.jurisdiction_info,
    g.isolevel,
    g.local_serial_formated,
    g.pack_number,
    g.path_cutgeo_server,
    g.path_preserv_server,
    g.path_preserv_git,
    g.path_cutgeo_git,
    g.repo_cutgeo_name,
    g.pack_number_donatedpackcsv,
    g.user_resp_packtpl_initcap,
    g.vat_id_p1,
    g.vat_id_p2,
    g.license_data,
    g.hashedfname_7,
    g.hashedfname_without_ext,
    g.hashedfname_7_ext,
    g.hashedfname_url,
    g.user_resp_initcap,
    g.user_resp_packfilevers_info,
    g.layer,
    g.ftid,
    g.ftname,
    g.geomtype,
    g.need_join,
    g.description,
    g.ftype_info,
    g.full_name_layer,
    g.id_component,
    g.proc_step,
    g.lineage,
    g.lineage_md5,
    g.kx_profile,
    g.filtered_name,
    g.url_page,
    g.row_num,
    g.class_ftname,
    g.shortnameftname,
    g.descriptionftname,
    g.license_evidences,
    g.geom_type_abbr,
    g.publication_summary,
    jsonb_strip_nulls(to_jsonb(dviz.*)) AS viz_summary,
    ( SELECT to_jsonb(j.*) AS to_jsonb
           FROM optim.jurisdiction j
          WHERE ((j.isolevel = 2) AND (j.jurisd_base_id = g.jurisd_base_id) AND (j.isolabel_ext = ((split_part(g.isolabel_ext, '-'::text, 1) || '-'::text) || split_part(g.isolabel_ext, '-'::text, 2))))) AS jurisd2,
    ( SELECT to_jsonb(j.*) AS to_jsonb
           FROM optim.jurisdiction j
          WHERE ((j.isolevel = 1) AND (j.jurisd_base_id = g.jurisd_base_id) AND (j.isolabel_ext = split_part(g.isolabel_ext, '-'::text, 1)))) AS jurisd1
   FROM (( SELECT pf.id,
            pf.hashedfname,
            pf.pack_id,
            pf.pack_item,
            pf.pack_item_accepted_date,
            pf.kx_pack_item_version,
            pf.user_resp,
            pf.info,
            pf.packtpl_id,
            pf.donor_id,
            pf.user_resp_packtpl,
            pf.user_resp_packtpl_info,
            pf.pk_count,
            pf.original_tpl,
            pf.make_conf_tpl,
            pf.kx_num_files,
            pf.packtpl_info,
            pf.country_id,
            pf.local_serial,
            pf.scope_osm_id,
            pf.scope_label,
            pf.shortname,
            pf.vat_id,
            pf.legalname,
            pf.wikidata_id,
            pf.url,
            pf.donor_info,
            pf.kx_vat_id,
            pf.osm_id,
            pf.jurisd_base_id,
            pf.jurisd_local_id,
            pf.parent_id,
            pf.admin_level,
            pf.name,
            pf.parent_abbrev,
            pf.abbrev,
            pf.jurisdiction_wikidata_id,
            pf.lexlabel,
            pf.isolabel_ext,
            pf.ddd,
            pf.housenumber_system_type,
            pf.lex_urn,
            pf.jurisdiction_info,
            pf.isolevel,
            pf.local_serial_formated,
            pf.pack_number,
            pf.path_cutgeo_server,
            pf.path_preserv_server,
            pf.path_preserv_git,
            pf.path_cutgeo_git,
            pf.repo_cutgeo_name,
            pf.pack_number_donatedpackcsv,
            pf.user_resp_packtpl_initcap,
            pf.vat_id_p1,
            pf.vat_id_p2,
            pf.license_data,
            pf.hashedfname_7,
            pf.hashedfname_without_ext,
            pf.hashedfname_7_ext,
            pf.hashedfname_url,
            pf.user_resp_initcap,
            pf.user_resp_packfilevers_info,
            pf.layer,
            pf.ftid,
            pf.ftname,
            pf.geomtype,
            pf.need_join,
            pf.description,
            pf.ftype_info,
            pf.full_name_layer,
            pf.id_component,
            pf.proc_step,
            pf.lineage,
            pf.lineage_md5,
            pf.kx_profile,
            pf.filtered_name,
            pf.url_page,
            row_number() OVER (PARTITION BY pf.isolabel_ext, pf.local_serial, pf.pk_count ORDER BY (pf.ftype_info -> 'class_ftname'::text)) AS row_num,
            (pf.ftype_info ->> 'class_ftname'::text) AS class_ftname,
            ((pf.ftype_info -> 'class_info'::text) ->> 'shortname_pt'::text) AS shortnameftname,
            ((pf.ftype_info -> 'class_info'::text) ->> 'description_pt'::text) AS descriptionftname,
            (pf.make_conf_tpl -> 'license_evidences'::text) AS license_evidences,
                CASE pf.geomtype
                    WHEN 'poly'::text THEN 'pols'::text
                    WHEN 'line'::text THEN 'lns'::text
                    WHEN 'point'::text THEN 'pts'::text
                    ELSE NULL::text
                END AS geom_type_abbr,
            (jsonb_strip_nulls(jsonb_build_object('geom_type',
                CASE pf.geomtype
                    WHEN 'poly'::text THEN 'polígonos'::text
                    WHEN 'line'::text THEN 'segmentos'::text
                    WHEN 'point'::text THEN 'pontos'::text
                    ELSE NULL::text
                END, 'geom_unit_abr',
                CASE pf.geomtype
                    WHEN 'poly'::text THEN 'km²'::text
                    WHEN 'line'::text THEN 'km'::text
                    ELSE ''::text
                END, 'geom_unit_ext',
                CASE pf.geomtype
                    WHEN 'poly'::text THEN 'quilômetros quadrados'::text
                    WHEN 'line'::text THEN 'quilômetros'::text
                    ELSE ''::text
                END, 'isGeoaddress', public.iif(((pf.ftype_info ->> 'class_ftname'::text) = 'geoaddress'::text), 'true'::jsonb, 'false'::jsonb), 'bytes_mb', (((((pf.kx_profile -> 'publication_summary'::text) -> 'bytes'::text))::bigint)::numeric / 1048576.0), 'bytes_mb_round2', public.round(((((((pf.kx_profile -> 'publication_summary'::text) -> 'bytes'::text))::bigint)::numeric / 1048576.0))::double precision, (0.01)::double precision), 'avg_density_round2', public.round((((pf.kx_profile -> 'publication_summary'::text) -> 'avg_density'::text))::double precision, (0.01)::double precision), 'bytes_mb_round4', public.round(((((((pf.kx_profile -> 'publication_summary'::text) -> 'bytes'::text))::bigint)::numeric / 1048576.0))::double precision, (0.0001)::double precision), 'avg_density_round4', public.round((((pf.kx_profile -> 'publication_summary'::text) -> 'avg_density'::text))::double precision, (0.0001)::double precision), 'size_round2',
                CASE
                    WHEN (((pf.kx_profile -> 'publication_summary'::text) ->> 'size'::text) IS NOT NULL) THEN public.round((((pf.kx_profile -> 'publication_summary'::text) -> 'size'::text))::double precision, (0.01)::double precision)
                    ELSE NULL::double precision
                END, 'size_round4',
                CASE
                    WHEN (((pf.kx_profile -> 'publication_summary'::text) ->> 'size'::text) IS NOT NULL) THEN public.round((((pf.kx_profile -> 'publication_summary'::text) -> 'size'::text))::double precision, (0.0001)::double precision)
                    ELSE NULL::double precision
                END)) || (pf.kx_profile -> 'publication_summary'::text)) AS publication_summary
           FROM optim.vw01full_donated_packcomponent pf
          WHERE (pf.ftid > 19)
          ORDER BY pf.isolabel_ext, pf.local_serial, pf.pk_count, (pf.ftype_info ->> 'class_ftname'::text)) g
     LEFT JOIN optim.vw01fromcutlayer_tovizlayer dviz ON ((dviz.jurisdiction_pack_layer = ((((g.isolabel_ext || '/_pk'::text) || g.pack_number) || '/'::text) || g.class_ftname))));


ALTER VIEW optim.vw02publication OWNER TO postgres;

--
-- Name: VIEW vw02publication; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vw02publication IS 'Join optim.vw01full_packfilevers_ftype with optim.donated_PackComponent, ftid > 19.';


--
-- Name: vw02report_simple; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw02report_simple AS
 SELECT isolabel_ext,
    ftname
   FROM optim.vw01report;


ALTER VIEW optim.vw02report_simple OWNER TO postgres;

--
-- Name: VIEW vw02report_simple; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vw02report_simple IS 'Simplifies optim.vw01report.';


--
-- Name: vw03generate_list_hash; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw03generate_list_hash AS
 SELECT jsonb_build_object('pacotes', jsonb_agg(r.*)) AS y
   FROM ( SELECT pf.legalname,
            pf.scope_label,
            pf.hashedfname,
            pf.hashedfname_url,
            pf.hashedfname_7,
            pf.pack_number,
            pf.local_serial_formated,
            pf.path_preserv_git,
            pf.info
           FROM optim.vw01full_packfilevers pf
          ORDER BY pf.hashedfname) r;


ALTER VIEW optim.vw03generate_list_hash OWNER TO postgres;

--
-- Name: vw03prepare_jurisdiction_metrics1; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw03prepare_jurisdiction_metrics1 AS
 SELECT osm_id,
    isolabel_ext,
    (round((area_m / (1000000.0)::double precision)))::integer AS area_km2,
    (public.round(area_sr, 5))::double precision AS area_sr,
    (public.round((sqrt(area_m) / (1000.0)::double precision), 1))::double precision AS side_estim_km,
    (public.round(sqrt(area_sr), 4))::double precision AS side_estim_deg,
    public.round((sqrt(area_sr) / sqrt(area_m)), 7) AS fat_deg_m
   FROM ( SELECT vw01full_jurisdiction_geom.osm_id,
            vw01full_jurisdiction_geom.jurisd_base_id,
            vw01full_jurisdiction_geom.jurisd_local_id,
            vw01full_jurisdiction_geom.parent_id,
            vw01full_jurisdiction_geom.admin_level,
            vw01full_jurisdiction_geom.name,
            vw01full_jurisdiction_geom.parent_abbrev,
            vw01full_jurisdiction_geom.abbrev,
            vw01full_jurisdiction_geom.wikidata_id,
            vw01full_jurisdiction_geom.lexlabel,
            vw01full_jurisdiction_geom.isolabel_ext,
            vw01full_jurisdiction_geom.ddd,
            vw01full_jurisdiction_geom.housenumber_system_type,
            vw01full_jurisdiction_geom.lex_urn,
            vw01full_jurisdiction_geom.info,
            vw01full_jurisdiction_geom.name_en,
            vw01full_jurisdiction_geom.isolevel,
            vw01full_jurisdiction_geom.ne_country_id,
            vw01full_jurisdiction_geom.int_country_id,
            vw01full_jurisdiction_geom.geom,
            public.st_area((vw01full_jurisdiction_geom.geom)::public.geography, true) AS area_m,
            public.st_area(vw01full_jurisdiction_geom.geom) AS area_sr
           FROM optim.vw01full_jurisdiction_geom
          WHERE (vw01full_jurisdiction_geom.geom IS NOT NULL)) t0;


ALTER VIEW optim.vw03prepare_jurisdiction_metrics1 OWNER TO postgres;

--
-- Name: VIEW vw03prepare_jurisdiction_metrics1; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vw03prepare_jurisdiction_metrics1 IS 'Prepare the standard geometry metrics.';


--
-- Name: COLUMN vw03prepare_jurisdiction_metrics1.area_sr; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.vw03prepare_jurisdiction_metrics1.area_sr IS 'Area in spheroradians.';


--
-- Name: COLUMN vw03prepare_jurisdiction_metrics1.side_estim_km; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.vw03prepare_jurisdiction_metrics1.side_estim_km IS 'Estimating the side size of an equivalent-area square, in quilometers.';


--
-- Name: COLUMN vw03prepare_jurisdiction_metrics1.side_estim_deg; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.vw03prepare_jurisdiction_metrics1.side_estim_deg IS 'Estimating the side size of an equivalent-area square, in degrees.';


--
-- Name: COLUMN vw03prepare_jurisdiction_metrics1.fat_deg_m; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.vw03prepare_jurisdiction_metrics1.fat_deg_m IS 'Average degree per meter convertion factor at the points of this area.';


--
-- Name: vw03publication; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw03publication AS
 SELECT isolabel_ext,
    ('_pk'::text || pack_number) AS pack_number,
    jsonb_build_object('packtpl_id', packtpl_id, 'isolabel_ext', isolabel_ext, 'legalname', legalname, 'vat_id', vat_id, 'url', url, 'wikidata_id', wikidata_id, 'user_resp', user_resp, 'uri_objtype', (packtpl_info ->> 'uri_objtype'::text), 'user_resp_packtpl_info', user_resp_packtpl_info, 'accepted_date', pack_item_accepted_date, 'accepted_date_ptbr', (packtpl_info ->> 'accepted_date_ptbr'::text), 'accepted_date_en', (packtpl_info ->> 'accepted_date_en'::text), 'accepted_date_es', (packtpl_info ->> 'accepted_date_es'::text), 'path_preserv_git', path_preserv_git, 'pack_number', pack_number, 'path_cutgeo_git', path_cutgeo_git, 'license_evidences', license_evidences, 'path_cutgeo_notree', replace(replace(path_cutgeo_git, 'tree/'::text, ''::text), 'https://git.digital-guard.org/'::text, ''::text), 'layers', jsonb_agg(jsonb_build_object('id', id, 'class_ftname', class_ftname, 'shortname', shortnameftname, 'description', descriptionftname, 'hashedfname', hashedfname, 'hashedfname_url', hashedfname_url, 'hashedfname_without_ext', hashedfname_without_ext, 'hashedfname_7_ext', hashedfname_7_ext, 'isFirst', public.iif((row_num = 1), 'true'::jsonb, 'false'::jsonb), 'geom_type_abbr', geom_type_abbr, 'publication_summary', publication_summary, 'url_page', url_page, 'filtered_name', filtered_name, 'viz_summary', viz_summary)), 'viz_keys', array_agg(
        CASE
            WHEN (viz_summary IS NOT NULL) THEN class_ftname
            ELSE NULL::text
        END), 'publication_keys', array_agg(
        CASE
            WHEN (publication_summary IS NOT NULL) THEN class_ftname
            ELSE NULL::text
        END)) AS page
   FROM optim.vw02publication t
  GROUP BY packtpl_id, isolabel_ext, legalname, vat_id, url, wikidata_id, user_resp, path_preserv_git, pack_number, path_cutgeo_git, pack_item_accepted_date, kx_pack_item_version, local_serial, pk_count, license_evidences, (packtpl_info ->> 'accepted_date_ptbr'::text), (packtpl_info ->> 'accepted_date_es'::text), (packtpl_info ->> 'accepted_date_en'::text), (packtpl_info ->> 'uri_objtype'::text), user_resp_packtpl_info;


ALTER VIEW optim.vw03publication OWNER TO postgres;

--
-- Name: VIEW vw03publication; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vw03publication IS 'Generate json for mustache template for preservDataViz pages.';


--
-- Name: vw03publication_viz; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw03publication_viz AS
 SELECT isolabel_ext,
    ('_pk'::text || pack_number) AS pack_number,
    split_part((viz_summary ->> 'url_layer_visualization'::text), '='::text, 2) AS viz_id,
    (viz_summary -> 'jurisdiction_pack_layer'::text) AS viz_id2,
    jsonb_build_object('packtpl_id', packtpl_id, 'isolabel_ext', isolabel_ext, 'legalname', legalname, 'vat_id', vat_id, 'url', url, 'wikidata_id', wikidata_id, 'user_resp', user_resp, 'accepted_date', pack_item_accepted_date, 'accepted_date_ptbr', (packtpl_info ->> 'accepted_date_ptbr'::text), 'accepted_date_en', (packtpl_info ->> 'accepted_date_en'::text), 'accepted_date_es', (packtpl_info ->> 'accepted_date_es'::text), 'path_preserv_git', path_preserv_git, 'pack_number', pack_number, 'path_cutgeo_git', path_cutgeo_git, 'license_evidences', license_evidences, 'license_data', license_data, 'jurisd1', jurisd1, 'jurisd2', jurisd2, 'name', name, 'jurisdiction_info', (jurisdiction_info || jsonb_build_object('population', (jsonb_build_object('date_year', EXTRACT(year FROM (((jurisdiction_info -> 'population'::text) ->> 'date'::text))::date)) || (jurisdiction_info -> 'population'::text)))), 'path_cutgeo_notree', replace(replace(path_cutgeo_git, 'tree/'::text, ''::text), 'https://git.digital-guard.org/'::text, ''::text), 'id', id, 'class_ftname', class_ftname, 'shortnameftname', shortnameftname, 'description', descriptionftname, 'hashedfname', hashedfname, 'hashedfname_url', hashedfname_url, 'hashedfname_without_ext', hashedfname_without_ext, 'hashedfname_7_ext', hashedfname_7_ext, 'isFirst', public.iif((row_num = 1), 'true'::jsonb, 'false'::jsonb), 'geom_type_abbr', geom_type_abbr, 'publication_summary', publication_summary, 'url_page', url_page, 'filtered_name', filtered_name, 'viz_summary', viz_summary, 'initcap_ftnameviz',
        CASE class_ftname
            WHEN 'block'::text THEN 'City blocks'::text
            WHEN 'building'::text THEN 'Building footprints'::text
            WHEN 'nsvia'::text THEN 'Neighborhood boundaries'::text
            WHEN 'parcel'::text THEN 'Land parcels'::text
            WHEN 'via'::text THEN 'Road network'::text
            WHEN 'geoaddress'::text THEN 'Address points'::text
            ELSE NULL::text
        END, 'ftnameviz',
        CASE class_ftname
            WHEN 'block'::text THEN 'city blocks'::text
            WHEN 'building'::text THEN 'building footprints'::text
            WHEN 'nsvia'::text THEN 'neighborhood boundaries'::text
            WHEN 'parcel'::text THEN 'land parcels'::text
            WHEN 'via'::text THEN 'road network'::text
            WHEN 'geoaddress'::text THEN 'address points'::text
            ELSE NULL::text
        END, 'with_address',
        CASE
            WHEN (ftid = ANY (ARRAY[21, 22, 51, 52, 61, 62])) THEN true
            ELSE false
        END, 'isblock',
        CASE class_ftname
            WHEN 'block'::text THEN true
            ELSE false
        END, 'isbuilding',
        CASE class_ftname
            WHEN 'building'::text THEN true
            ELSE false
        END, 'isnsvia',
        CASE class_ftname
            WHEN 'nsvia'::text THEN true
            ELSE false
        END, 'isparcel',
        CASE class_ftname
            WHEN 'parcel'::text THEN true
            ELSE false
        END, 'isvia',
        CASE class_ftname
            WHEN 'via'::text THEN true
            ELSE false
        END, 'isgeoaddress',
        CASE class_ftname
            WHEN 'geoaddress'::text THEN true
            ELSE false
        END, 'isisolevel1',
        CASE isolevel
            WHEN 1 THEN true
            ELSE false
        END, 'isisolevel2',
        CASE isolevel
            WHEN 2 THEN true
            ELSE false
        END, 'isisolevel3',
        CASE isolevel
            WHEN 3 THEN true
            ELSE false
        END, 'iscapital1',
        CASE ((jurisdiction_info -> 'is_capital_isolevel'::text))::integer
            WHEN 1 THEN true
            ELSE false
        END) AS conf
   FROM optim.vw02publication t;


ALTER VIEW optim.vw03publication_viz OWNER TO postgres;

--
-- Name: VIEW vw03publication_viz; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vw03publication_viz IS 'Generate json for mustache template for Viz.';


--
-- Name: vw04prepare_jurisdiction_shapemetrics; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vw04prepare_jurisdiction_shapemetrics AS
 SELECT osm_id,
    isolabel_ext,
    rectang_l_km,
    rectang_h_km,
    elongation_factor_km,
    elongation_factor_deg,
    rectang_factor_deg,
    (public.round(((rectang_factor_deg + ((1.5)::double precision * elongation_factor_deg)) / (2.5)::double precision), 2))::double precision AS elong_deg_mixfactor
   FROM ( SELECT t1.osm_id,
            t1.isolabel_ext,
            (round((t1.s[1] / t1.fat_deg_m)) / (1000)::double precision) AS rectang_l_km,
            (round((t1.s[2] / t1.fat_deg_m)) / (1000)::double precision) AS rectang_h_km,
                CASE
                    WHEN (t1.s[6] = (0)::double precision) THEN ((round((((t1.s[1] - t1.s[2]) / t1.side_estim_deg) / t1.fat_deg_m)) / (1000.0)::double precision))::integer
                    ELSE '-1'::integer
                END AS elongation_factor_km,
                CASE
                    WHEN (t1.s[6] = (0)::double precision) THEN (public.round(((t1.s[1] - t1.s[2]) / t1.side_estim_deg), 2))::double precision
                    ELSE ('-1'::integer)::double precision
                END AS elongation_factor_deg,
            (public.round(((0.95)::double precision + ((t1.diaglen_deg - t1.side_estim_deg) / t1.side_estim_deg)), 3))::double precision AS rectang_factor_deg
           FROM ( SELECT vw01full_jurisdiction_geom.osm_id,
                    vw01full_jurisdiction_geom.jurisd_base_id,
                    vw01full_jurisdiction_geom.jurisd_local_id,
                    vw01full_jurisdiction_geom.parent_id,
                    vw01full_jurisdiction_geom.admin_level,
                    vw01full_jurisdiction_geom.name,
                    vw01full_jurisdiction_geom.parent_abbrev,
                    vw01full_jurisdiction_geom.abbrev,
                    vw01full_jurisdiction_geom.wikidata_id,
                    vw01full_jurisdiction_geom.lexlabel,
                    vw01full_jurisdiction_geom.isolabel_ext,
                    vw01full_jurisdiction_geom.ddd,
                    vw01full_jurisdiction_geom.housenumber_system_type,
                    vw01full_jurisdiction_geom.lex_urn,
                    vw01full_jurisdiction_geom.info,
                    vw01full_jurisdiction_geom.name_en,
                    vw01full_jurisdiction_geom.isolevel,
                    vw01full_jurisdiction_geom.ne_country_id,
                    vw01full_jurisdiction_geom.int_country_id,
                    vw01full_jurisdiction_geom.geom,
                    ((vw01full_jurisdiction_geom.info -> 'side_estim_deg'::text))::double precision AS side_estim_deg,
                    ((vw01full_jurisdiction_geom.info -> 'side_estim_km'::text))::double precision AS side_estim_km,
                    ((vw01full_jurisdiction_geom.info -> 'fat_deg_m'::text))::double precision AS fat_deg_m,
                    public.shapedescr_sizes(public.st_simplifypreservetopology(vw01full_jurisdiction_geom.geom, (((vw01full_jurisdiction_geom.info -> 'side_estim_deg'::text))::double precision / (350.0)::double precision))) AS s,
                    public.st_length(public.st_boundingdiagonal(vw01full_jurisdiction_geom.geom, true)) AS diaglen_deg
                   FROM optim.vw01full_jurisdiction_geom
                  WHERE ((vw01full_jurisdiction_geom.geom IS NOT NULL) AND (vw01full_jurisdiction_geom.info ? 'side_estim_deg'::text))) t1) t2;


ALTER VIEW optim.vw04prepare_jurisdiction_shapemetrics OWNER TO postgres;

--
-- Name: vwjurisdiction_synonym; Type: VIEW; Schema: optim; Owner: postgres
--

CREATE VIEW optim.vwjurisdiction_synonym AS
 SELECT DISTINCT synonym,
    isolabel_ext
   FROM (( SELECT ((('CO-'::text || "substring"(j.isolabel_ext, 4, 1)) || '-'::text) || split_part(j.abbrev, '-'::text, 3)) AS synonym,
            max(j.isolabel_ext) AS isolabel_ext
           FROM ( SELECT jurisdiction_abbrev_option.abbrev,
                    max(jurisdiction_abbrev_option.isolabel_ext) AS isolabel_ext
                   FROM optim.jurisdiction_abbrev_option
                  WHERE ((jurisdiction_abbrev_option.selected IS TRUE) AND (jurisdiction_abbrev_option.isolabel_ext ~~ 'CO-%-%'::text))
                  GROUP BY jurisdiction_abbrev_option.abbrev
                 HAVING (count(*) = 1)) j
          GROUP BY ((('CO-'::text || "substring"(j.isolabel_ext, 4, 1)) || '-'::text) || split_part(j.abbrev, '-'::text, 3))
         HAVING (count(*) = 1)
          ORDER BY ((('CO-'::text || "substring"(j.isolabel_ext, 4, 1)) || '-'::text) || split_part(j.abbrev, '-'::text, 3)))
        UNION ALL
        ( SELECT ((('CO-'::text || "substring"(j.isolabel_ext, 4, 1)) || '-'::text) || split_part(j.isolabel_ext, '-'::text, 3)),
            max(j.isolabel_ext) AS max
           FROM optim.jurisdiction j
          WHERE ((j.isolevel > 2) AND (j.isolabel_ext ~~ 'CO-%'::text))
          GROUP BY ((('CO-'::text || "substring"(j.isolabel_ext, 4, 1)) || '-'::text) || split_part(j.isolabel_ext, '-'::text, 3))
         HAVING (count(*) = 1)
          ORDER BY ((('CO-'::text || "substring"(j.isolabel_ext, 4, 1)) || '-'::text) || split_part(j.isolabel_ext, '-'::text, 3)))
        UNION ALL
         SELECT ((split_part(jurisdiction.isolabel_ext, '-'::text, 1) || '-'::text) || jurisdiction.jurisd_local_id),
            jurisdiction.isolabel_ext
           FROM optim.jurisdiction
          WHERE ((jurisdiction.jurisd_base_id = ANY (ARRAY[76, 120, 170, 858])) AND
                CASE
                    WHEN (jurisdiction.jurisd_base_id = ANY (ARRAY[120, 170])) THEN (jurisdiction.isolevel = 3)
                    WHEN (jurisdiction.jurisd_base_id = ANY (ARRAY[76, 858])) THEN (jurisdiction.isolevel = ANY (ARRAY[2, 3]))
                    ELSE NULL::boolean
                END)
        UNION ALL
         SELECT ((split_part(a.isolabel_ext, '-'::text, 1) || '-'::text) || split_part(a.isolabel_ext, '-'::text, 3)),
            a.isolabel_ext
           FROM ( SELECT lower(((split_part(j.isolabel_ext, '-'::text, 1) || '-'::text) || split_part(j.isolabel_ext, '-'::text, 3))) AS lower,
                    max(j.isolabel_ext) AS isolabel_ext
                   FROM optim.jurisdiction j
                  WHERE ((j.isolevel > 2) AND (j.jurisd_base_id = ANY (ARRAY[76, 120, 170])))
                  GROUP BY (lower(((split_part(j.isolabel_ext, '-'::text, 1) || '-'::text) || split_part(j.isolabel_ext, '-'::text, 3))))
                 HAVING (count(*) = 1)
                  ORDER BY (lower(((split_part(j.isolabel_ext, '-'::text, 1) || '-'::text) || split_part(j.isolabel_ext, '-'::text, 3))))) a
        UNION ALL
        ( SELECT ((split_part(jurisdiction.isolabel_ext, '-'::text, 1) || '-'::text) || jurisdiction.abbrev),
            max(jurisdiction.isolabel_ext) AS max
           FROM optim.jurisdiction
          WHERE ((jurisdiction.isolevel > 2) AND (jurisdiction.jurisd_base_id = 120))
          GROUP BY ((split_part(jurisdiction.isolabel_ext, '-'::text, 1) || '-'::text) || jurisdiction.abbrev)
         HAVING (count(*) = 1)
          ORDER BY ((split_part(jurisdiction.isolabel_ext, '-'::text, 1) || '-'::text) || jurisdiction.abbrev))
        UNION ALL
         SELECT ("substring"(jurisdiction.isolabel_ext, 1, 6) || jurisdiction.abbrev),
            jurisdiction.isolabel_ext
           FROM optim.jurisdiction
          WHERE ((jurisdiction.isolabel_ext ~~ 'BR-%-%'::text) AND (jurisdiction.abbrev IS NOT NULL))
        UNION ALL (
                 SELECT jurisdiction_lexlabel.lex_isoinlevel1,
                    jurisdiction_lexlabel.isolabel_ext
                   FROM optim.jurisdiction_lexlabel
                  WHERE (jurisdiction_lexlabel.lex_isoinlevel1 IS NOT NULL)
                UNION
                 SELECT jurisdiction_lexlabel.lex_isoinlevel2,
                    jurisdiction_lexlabel.isolabel_ext
                   FROM optim.jurisdiction_lexlabel
                  WHERE (jurisdiction_lexlabel.lex_isoinlevel2 IS NOT NULL)
                UNION
                 SELECT jurisdiction_lexlabel.lex_isoinlevel2_abbrev,
                    jurisdiction_lexlabel.isolabel_ext
                   FROM optim.jurisdiction_lexlabel
                  WHERE (jurisdiction_lexlabel.lex_isoinlevel2_abbrev IS NOT NULL)
        )
        UNION ALL
         SELECT lower(((('BR-'::text || j.parent_abbrev) || '-'::text) || j.parent_abbrev)) AS lower,
            j.isolabel_ext
           FROM optim.jurisdiction j
          WHERE ((((j.info -> 'is_capital_isolevel'::text))::integer > 0) AND (j.isolevel = 3) AND (j.isolabel_ext ~~ 'BR-%-%'::text))
        UNION ALL
         SELECT lower(((split_part(j.isolabel_ext, '-'::text, 1) || '-'::text) || split_part(j.isolabel_ext, '-'::text, 2))) AS lower,
            j.isolabel_ext
           FROM optim.jurisdiction j
          WHERE ((((j.info -> 'is_capital_isolevel'::text))::integer = 1) AND (j.isolevel = 3))) z;


ALTER VIEW optim.vwjurisdiction_synonym OWNER TO postgres;

--
-- Name: VIEW vwjurisdiction_synonym; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON VIEW optim.vwjurisdiction_synonym IS 'Synonymous names of jurisdictions.';


--
-- Name: COLUMN vwjurisdiction_synonym.synonym; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.vwjurisdiction_synonym.synonym IS 'Synonym for isolabel_ext, e.g. br;sao.paulo;sao.paulo br-saopaulo';


--
-- Name: COLUMN vwjurisdiction_synonym.isolabel_ext; Type: COMMENT; Schema: optim; Owner: postgres
--

COMMENT ON COLUMN optim.vwjurisdiction_synonym.isolabel_ext IS 'ISO and name (camel case); e.g. BR-SP-SaoPaulo.';


--
-- Name: citycover_dust_raw; Type: TABLE; Schema: osmc; Owner: postgres
--

CREATE TABLE osmc.citycover_dust_raw (
    dust_b16h text NOT NULL,
    dust_city integer NOT NULL,
    dust_city_label text,
    merge_score integer,
    receptor_b16h text NOT NULL,
    receptor_city integer NOT NULL
);


ALTER TABLE osmc.citycover_dust_raw OWNER TO postgres;

--
-- Name: citycover_raw; Type: TABLE; Schema: osmc; Owner: postgres
--

CREATE TABLE osmc.citycover_raw (
    isolabel_ext text NOT NULL,
    status integer NOT NULL,
    base_intlevel integer,
    cover text NOT NULL,
    "overlay" text,
    cover_order text,
    overlay_order text
);


ALTER TABLE osmc.citycover_raw OWNER TO postgres;

--
-- Name: jurisdiction_bbox; Type: TABLE; Schema: osmc; Owner: postgres
--

CREATE TABLE osmc.jurisdiction_bbox (
    id integer NOT NULL,
    jurisd_base_id integer,
    isolabel_ext text,
    geom public.geometry
);


ALTER TABLE osmc.jurisdiction_bbox OWNER TO postgres;

--
-- Name: TABLE jurisdiction_bbox; Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON TABLE osmc.jurisdiction_bbox IS 'BStores geographic bounding boxes (BBOX) for national jurisdictions. Used as a preliminary filter to identify the potential jurisdiction of a given point geometry. Entries with NULL in `jurisd_base_id` represent undefined or shared regions (e.g., border areas like BR/UY, BR/CO).';


--
-- Name: COLUMN jurisdiction_bbox.id; Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON COLUMN osmc.jurisdiction_bbox.id IS 'Gid.';


--
-- Name: COLUMN jurisdiction_bbox.jurisd_base_id; Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON COLUMN osmc.jurisdiction_bbox.jurisd_base_id IS 'Numeric official ID.';


--
-- Name: COLUMN jurisdiction_bbox.isolabel_ext; Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON COLUMN osmc.jurisdiction_bbox.isolabel_ext IS 'ISO code';


--
-- Name: COLUMN jurisdiction_bbox.geom; Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON COLUMN osmc.jurisdiction_bbox.geom IS 'Box2D for id identifier';


--
-- Name: mvjurisdiction_bbox_border; Type: MATERIALIZED VIEW; Schema: osmc; Owner: postgres
--

CREATE MATERIALIZED VIEW osmc.mvjurisdiction_bbox_border AS
 SELECT row_number() OVER () AS id,
    b.id AS bbox_id,
    g.jurisd_base_id,
    g.isolabel_ext,
    public.st_intersection(b.geom, g.geom) AS geom
   FROM (osmc.jurisdiction_bbox b
     LEFT JOIN optim.vw01full_jurisdiction_geom g ON ((public.st_intersects(b.geom, g.geom) IS TRUE)))
  WHERE ((b.jurisd_base_id IS NULL) AND (g.isolabel_ext = ANY (ARRAY['CM'::text, 'CO'::text, 'BR'::text, 'UY'::text, 'EC'::text])))
  WITH NO DATA;


ALTER MATERIALIZED VIEW osmc.mvjurisdiction_bbox_border OWNER TO postgres;

--
-- Name: MATERIALIZED VIEW mvjurisdiction_bbox_border; Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON MATERIALIZED VIEW osmc.mvjurisdiction_bbox_border IS 'Stores actual geographic intersections between undefined/shared BBOX regions (from `jurisdiction_bbox`) and countries, using their official jurisdiction geometry. This table helps resolve ambiguous or shared BBOX areas by mapping them to one or more valid countries.';


--
-- Name: COLUMN mvjurisdiction_bbox_border.id; Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON COLUMN osmc.mvjurisdiction_bbox_border.id IS 'Gid.';


--
-- Name: COLUMN mvjurisdiction_bbox_border.bbox_id; Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON COLUMN osmc.mvjurisdiction_bbox_border.bbox_id IS 'id of osmc.jurisdiction_bbox.';


--
-- Name: COLUMN mvjurisdiction_bbox_border.jurisd_base_id; Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON COLUMN osmc.mvjurisdiction_bbox_border.jurisd_base_id IS 'Numeric official ID.';


--
-- Name: COLUMN mvjurisdiction_bbox_border.isolabel_ext; Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON COLUMN osmc.mvjurisdiction_bbox_border.isolabel_ext IS 'ISO code';


--
-- Name: COLUMN mvjurisdiction_bbox_border.geom; Type: COMMENT; Schema: osmc; Owner: postgres
--

COMMENT ON COLUMN osmc.mvjurisdiction_bbox_border.geom IS 'Geometry of intersection of box with country.';


--
-- Name: lixo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lixo (
    osm_id bigint,
    isolabel_ext text,
    geom public.geometry(Geometry,4326),
    geom_svg public.geometry(Geometry,4326),
    kx_ghs1_intersects text[],
    kx_ghs2_intersects text[]
);


ALTER TABLE public.lixo OWNER TO postgres;

--
-- Name: lixo_felipe; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lixo_felipe (
    osm_id bigint,
    isolabel_ext text,
    geom public.geometry(Geometry,4326),
    geom_svg public.geometry(Geometry,4326),
    kx_ghs1_intersects text[],
    kx_ghs2_intersects text[]
);


ALTER TABLE public.lixo_felipe OWNER TO postgres;

--
-- Name: mvwjurisdiction_synonym; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.mvwjurisdiction_synonym AS
 SELECT DISTINCT synonym,
    isolabel_ext
   FROM ( SELECT lower(jurisdiction.isolabel_ext) AS synonym,
            jurisdiction.isolabel_ext
           FROM optim.jurisdiction
          WHERE ((jurisdiction.isolevel > 1) AND (NOT (jurisdiction.osm_id IN ( SELECT jurisdiction_1.parent_id
                   FROM optim.jurisdiction jurisdiction_1
                  WHERE (((jurisdiction_1.info -> 'is_capital_isolevel'::text))::integer = 1)))))
        UNION ALL
         SELECT lower(jurisdiction_abbrev_option.abbrev) AS lower,
            max(jurisdiction_abbrev_option.isolabel_ext) AS max
           FROM optim.jurisdiction_abbrev_option
          WHERE (jurisdiction_abbrev_option.selected IS TRUE)
          GROUP BY jurisdiction_abbrev_option.abbrev
         HAVING (count(*) = 1)) z
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.mvwjurisdiction_synonym OWNER TO postgres;

--
-- Name: MATERIALIZED VIEW mvwjurisdiction_synonym; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON MATERIALIZED VIEW public.mvwjurisdiction_synonym IS 'Synonymous names of jurisdictions.';


--
-- Name: COLUMN mvwjurisdiction_synonym.synonym; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mvwjurisdiction_synonym.synonym IS 'Synonym for isolabel_ext, e.g. br;sao.paulo;sao.paulo br-saopaulo';


--
-- Name: COLUMN mvwjurisdiction_synonym.isolabel_ext; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mvwjurisdiction_synonym.isolabel_ext IS 'ISO and name (camel case); e.g. BR-SP-SaoPaulo.';


--
-- Name: donors; Type: VIEW; Schema: tmp_orig; Owner: postgres
--

CREATE VIEW tmp_orig.donors AS
 SELECT 'br'::text AS jurisdiction,
    r.local_id,
    r.scope_label,
    r.vat_id,
    r."legalName",
    r.wikidata_id,
    r.url,
    r.donor_date,
    r.donor_status
   FROM tmp_orig.fdw_donorbr r
UNION ALL
 SELECT 'ar'::text AS jurisdiction,
    r.local_id,
    r.scope_label,
    r.vat_id,
    r."legalName",
    r.wikidata_id,
    r.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM tmp_orig.fdw_donorar r
UNION ALL
 SELECT 'bo'::text AS jurisdiction,
    r.local_id,
    r.scope_label,
    r.vat_id,
    r."legalName",
    r.wikidata_id,
    r.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM tmp_orig.fdw_donorbo r
UNION ALL
 SELECT 'cl'::text AS jurisdiction,
    r.local_id,
    r.scope_label,
    r.vat_id,
    r."legalName",
    r.wikidata_id,
    r.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM tmp_orig.fdw_donorcl r
UNION ALL
 SELECT 'co'::text AS jurisdiction,
    r.local_id,
    r.scope_label,
    r.vat_id,
    r."legalName",
    r.wikidata_id,
    r.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM tmp_orig.fdw_donorco r
UNION ALL
 SELECT 'ec'::text AS jurisdiction,
    r.local_id,
    r.scope_label,
    r.vat_id,
    r."legalName",
    r.wikidata_id,
    r.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM tmp_orig.fdw_donorec r
UNION ALL
 SELECT 'mx'::text AS jurisdiction,
    r.local_id,
    r.scope_label,
    r.vat_id,
    r."legalName",
    r.wikidata_id,
    r.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM tmp_orig.fdw_donormx r
UNION ALL
 SELECT 'pe'::text AS jurisdiction,
    r.local_id,
    r.scope_label,
    r.vat_id,
    r."legalName",
    r.wikidata_id,
    r.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM tmp_orig.fdw_donorpe r
UNION ALL
 SELECT 'py'::text AS jurisdiction,
    r.local_id,
    r.scope_label,
    r.vat_id,
    r."legalName",
    r.wikidata_id,
    r.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM tmp_orig.fdw_donorpy r
UNION ALL
 SELECT 'sr'::text AS jurisdiction,
    r.local_id,
    r.scope_label,
    r.vat_id,
    r."legalName",
    r.wikidata_id,
    r.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM tmp_orig.fdw_donorsr r
UNION ALL
 SELECT 'uy'::text AS jurisdiction,
    r.local_id,
    r.scope_label,
    r.vat_id,
    r."legalName",
    r.wikidata_id,
    r.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM tmp_orig.fdw_donoruy r
UNION ALL
 SELECT 've'::text AS jurisdiction,
    r.local_id,
    r.scope_label,
    r.vat_id,
    r."legalName",
    r.wikidata_id,
    r.url,
    NULL::text AS donor_date,
    NULL::text AS donor_status
   FROM tmp_orig.fdw_donorve r;


ALTER VIEW tmp_orig.donors OWNER TO postgres;

--
-- Name: fdw_codec_type; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.fdw_codec_type (
    extension text,
    variant text,
    descr_mime text,
    descr_encode text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv/data/codec_type.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.fdw_codec_type OWNER TO postgres;

--
-- Name: implieds; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.implieds (
    id_label text,
    id_version text,
    name text,
    family text,
    status text,
    year text,
    report_year text,
    is_by text,
    is_sa text,
    is_noreuse text,
    scope text,
    od_conformance text,
    osd_conformance text,
    maintainer text,
    title text,
    url_report text,
    url_ref text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/licenses/data/implieds.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.implieds OWNER TO postgres;

--
-- Name: jurisdpoints; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.jurisdpoints (
    wikidata text,
    local_id text,
    osm_id text,
    geom text,
    "wikidataLabel" text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv/data/jurisdPoint.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.jurisdpoints OWNER TO postgres;

--
-- Name: licenses; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.licenses (
    id_label text,
    id_version text,
    name text,
    family text,
    is_ref text,
    status text,
    year text,
    is_by text,
    is_sa text,
    is_salink text,
    is_nd text,
    is_noreuse text,
    is_generic text,
    domain_content text,
    domain_data text,
    domain_software text,
    od_conformance text,
    osd_conformance text,
    maintainer text,
    title text,
    url text,
    "NOTES" text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/licenses/data/licenses.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.licenses OWNER TO postgres;

--
-- Name: redirects_dlguard; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.redirects_dlguard (
    donor_id text,
    filename_original text,
    package_path text,
    de_sha256 text,
    para_url text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv/data/redirs/fromDL_toFileServer.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.redirects_dlguard OWNER TO postgres;

--
-- Name: redirects_viz; Type: FOREIGN TABLE; Schema: tmp_orig; Owner: postgres
--

CREATE FOREIGN TABLE tmp_orig.redirects_viz (
    jurisdiction_pack_layer text,
    user_resp text,
    status text,
    hash_from text,
    url_layer_visualization text
)
SERVER files
OPTIONS (
    delimiter ',',
    filename '/var/gits/_dg/preserv/data/redirs/fromCutLayer_toVizLayer.csv',
    format 'csv',
    header 'true'
);


ALTER FOREIGN TABLE tmp_orig.redirects_viz OWNER TO postgres;

--
-- Name: donated_packcomponent id; Type: DEFAULT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packcomponent ALTER COLUMN id SET DEFAULT nextval('optim.donated_packcomponent_id_seq'::regclass);


--
-- Name: donated_packcomponent_cloudcontrol id; Type: DEFAULT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packcomponent_cloudcontrol ALTER COLUMN id SET DEFAULT nextval('optim.donated_packcomponent_cloudcontrol_id_seq'::regclass);


--
-- Name: donated_packcomponent_not_approved id; Type: DEFAULT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packcomponent_not_approved ALTER COLUMN id SET DEFAULT nextval('optim.donated_packcomponent_not_approved_id_seq'::regclass);


--
-- Name: redirects redirects_hashedfname_hashedfnameuri_key; Type: CONSTRAINT; Schema: download; Owner: postgres
--

ALTER TABLE ONLY download.redirects
    ADD CONSTRAINT redirects_hashedfname_hashedfnameuri_key UNIQUE (hashedfname, hashedfnameuri);


--
-- Name: redirects redirects_pkey; Type: CONSTRAINT; Schema: download; Owner: postgres
--

ALTER TABLE ONLY download.redirects
    ADD CONSTRAINT redirects_pkey PRIMARY KEY (hashedfname);


--
-- Name: licenses_implieds licenses_implieds_id_label_id_version_key; Type: CONSTRAINT; Schema: license; Owner: postgres
--

ALTER TABLE ONLY license.licenses_implieds
    ADD CONSTRAINT licenses_implieds_id_label_id_version_key UNIQUE (id_label, id_version);


--
-- Name: auth_user auth_user_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.auth_user
    ADD CONSTRAINT auth_user_pkey PRIMARY KEY (username);


--
-- Name: codec_type codec_type_extension_variant_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.codec_type
    ADD CONSTRAINT codec_type_extension_variant_key UNIQUE (extension, variant);


--
-- Name: consolidated_data consolidated_data_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.consolidated_data
    ADD CONSTRAINT consolidated_data_pkey PRIMARY KEY (afa_id);


--
-- Name: donated_packcomponent_cloudcontrol donated_packcomponent_cloudco_packvers_id_ftid_lineage_md5__key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packcomponent_cloudcontrol
    ADD CONSTRAINT donated_packcomponent_cloudco_packvers_id_ftid_lineage_md5__key UNIQUE (packvers_id, ftid, lineage_md5, hashedfnametype);


--
-- Name: donated_packcomponent_cloudcontrol donated_packcomponent_cloudcontr_hashedfname_hashedfnameuri_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packcomponent_cloudcontrol
    ADD CONSTRAINT donated_packcomponent_cloudcontr_hashedfname_hashedfnameuri_key UNIQUE (hashedfname, hashedfnameuri);


--
-- Name: donated_packcomponent_cloudcontrol donated_packcomponent_cloudcontrol_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packcomponent_cloudcontrol
    ADD CONSTRAINT donated_packcomponent_cloudcontrol_pkey PRIMARY KEY (id);


--
-- Name: donated_packcomponent_not_approved donated_packcomponent_not_appr_packvers_id_ftid_lineage_md5_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packcomponent_not_approved
    ADD CONSTRAINT donated_packcomponent_not_appr_packvers_id_ftid_lineage_md5_key UNIQUE (packvers_id, ftid, lineage_md5);


--
-- Name: donated_packcomponent_not_approved donated_packcomponent_not_approved_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packcomponent_not_approved
    ADD CONSTRAINT donated_packcomponent_not_approved_pkey PRIMARY KEY (id);


--
-- Name: donated_packcomponent donated_packcomponent_packvers_id_ftid_lineage_md5_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packcomponent
    ADD CONSTRAINT donated_packcomponent_packvers_id_ftid_lineage_md5_key UNIQUE (packvers_id, ftid, lineage_md5);


--
-- Name: donated_packcomponent donated_packcomponent_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packcomponent
    ADD CONSTRAINT donated_packcomponent_pkey PRIMARY KEY (id);


--
-- Name: donated_packfilevers donated_packfilevers_hashedfname_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packfilevers
    ADD CONSTRAINT donated_packfilevers_hashedfname_key UNIQUE (hashedfname);


--
-- Name: donated_packfilevers donated_packfilevers_pack_id_pack_item_kx_pack_item_version_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packfilevers
    ADD CONSTRAINT donated_packfilevers_pack_id_pack_item_kx_pack_item_version_key UNIQUE (pack_id, pack_item, kx_pack_item_version);


--
-- Name: donated_packfilevers donated_packfilevers_pack_id_pack_item_pack_item_accepted_d_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packfilevers
    ADD CONSTRAINT donated_packfilevers_pack_id_pack_item_pack_item_accepted_d_key UNIQUE (pack_id, pack_item, pack_item_accepted_date);


--
-- Name: donated_packfilevers donated_packfilevers_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packfilevers
    ADD CONSTRAINT donated_packfilevers_pkey PRIMARY KEY (id);


--
-- Name: donated_packtpl donated_packtpl_donor_id_pk_count_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packtpl
    ADD CONSTRAINT donated_packtpl_donor_id_pk_count_key UNIQUE (donor_id, pk_count);


--
-- Name: donated_packtpl donated_packtpl_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packtpl
    ADD CONSTRAINT donated_packtpl_pkey PRIMARY KEY (id);


--
-- Name: donor donor_country_id_kx_vat_id_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donor
    ADD CONSTRAINT donor_country_id_kx_vat_id_key UNIQUE (country_id, kx_vat_id);


--
-- Name: donor donor_country_id_legalname_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donor
    ADD CONSTRAINT donor_country_id_legalname_key UNIQUE (country_id, legalname);


--
-- Name: donor donor_country_id_local_serial_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donor
    ADD CONSTRAINT donor_country_id_local_serial_key UNIQUE (country_id, local_serial);


--
-- Name: donor donor_country_id_scope_label_shortname_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donor
    ADD CONSTRAINT donor_country_id_scope_label_shortname_key UNIQUE (country_id, scope_label, shortname);


--
-- Name: donor donor_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donor
    ADD CONSTRAINT donor_pkey PRIMARY KEY (id);


--
-- Name: feature_type feature_type_ftname_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.feature_type
    ADD CONSTRAINT feature_type_ftname_key UNIQUE (ftname);


--
-- Name: feature_type feature_type_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.feature_type
    ADD CONSTRAINT feature_type_pkey PRIMARY KEY (ftid);


--
-- Name: housenumber_system_type housenumber_system_type_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.housenumber_system_type
    ADD CONSTRAINT housenumber_system_type_pkey PRIMARY KEY (hstid);


--
-- Name: jurisdiction_abbrev_option jurisdiction_abbrev_option_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction_abbrev_option
    ADD CONSTRAINT jurisdiction_abbrev_option_pkey PRIMARY KEY (abbrevref_id, isolabel_ext, abbrev);


--
-- Name: jurisdiction_abbrev_ref jurisdiction_abbrev_ref_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction_abbrev_ref
    ADD CONSTRAINT jurisdiction_abbrev_ref_pkey PRIMARY KEY (abbrevref_id);


--
-- Name: jurisdiction_eez jurisdiction_eez_isolabel_ext_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction_eez
    ADD CONSTRAINT jurisdiction_eez_isolabel_ext_key UNIQUE (isolabel_ext);


--
-- Name: jurisdiction_eez jurisdiction_eez_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction_eez
    ADD CONSTRAINT jurisdiction_eez_pkey PRIMARY KEY (osm_id);


--
-- Name: jurisdiction_geom_buffer jurisdiction_geom_buffer_isolabel_ext_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction_geom_buffer
    ADD CONSTRAINT jurisdiction_geom_buffer_isolabel_ext_key UNIQUE (isolabel_ext);


--
-- Name: jurisdiction_geom_buffer jurisdiction_geom_buffer_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction_geom_buffer
    ADD CONSTRAINT jurisdiction_geom_buffer_pkey PRIMARY KEY (osm_id);


--
-- Name: jurisdiction_geom jurisdiction_geom_isolabel_ext_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction_geom
    ADD CONSTRAINT jurisdiction_geom_isolabel_ext_key UNIQUE (isolabel_ext);


--
-- Name: jurisdiction_geom jurisdiction_geom_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction_geom
    ADD CONSTRAINT jurisdiction_geom_pkey PRIMARY KEY (osm_id);


--
-- Name: jurisdiction_geom_point jurisdiction_geom_point_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction_geom_point
    ADD CONSTRAINT jurisdiction_geom_point_pkey PRIMARY KEY (osm_id);


--
-- Name: jurisdiction jurisdiction_isolabel_ext_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction
    ADD CONSTRAINT jurisdiction_isolabel_ext_key UNIQUE (isolabel_ext);


--
-- Name: jurisdiction jurisdiction_jurisd_base_id_jurisd_local_id_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction
    ADD CONSTRAINT jurisdiction_jurisd_base_id_jurisd_local_id_key UNIQUE (jurisd_base_id, jurisd_local_id);


--
-- Name: jurisdiction jurisdiction_jurisd_base_id_parent_abbrev_abbrev_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction
    ADD CONSTRAINT jurisdiction_jurisd_base_id_parent_abbrev_abbrev_key UNIQUE (jurisd_base_id, parent_abbrev, abbrev);


--
-- Name: jurisdiction jurisdiction_jurisd_base_id_parent_abbrev_lexlabel_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction
    ADD CONSTRAINT jurisdiction_jurisd_base_id_parent_abbrev_lexlabel_key UNIQUE (jurisd_base_id, parent_abbrev, lexlabel);


--
-- Name: jurisdiction jurisdiction_jurisd_base_id_parent_abbrev_name_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction
    ADD CONSTRAINT jurisdiction_jurisd_base_id_parent_abbrev_name_key UNIQUE (jurisd_base_id, parent_abbrev, name);


--
-- Name: jurisdiction jurisdiction_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction
    ADD CONSTRAINT jurisdiction_pkey PRIMARY KEY (osm_id);


--
-- Name: jurisdiction jurisdiction_wikidata_id_key; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction
    ADD CONSTRAINT jurisdiction_wikidata_id_key UNIQUE (wikidata_id);


--
-- Name: templates templates_pkey; Type: CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.templates
    ADD CONSTRAINT templates_pkey PRIMARY KEY (template_name);


--
-- Name: citycover_dust_raw citycover_dust_raw_dust_b16h_dust_city_key; Type: CONSTRAINT; Schema: osmc; Owner: postgres
--

ALTER TABLE ONLY osmc.citycover_dust_raw
    ADD CONSTRAINT citycover_dust_raw_dust_b16h_dust_city_key UNIQUE (dust_b16h, dust_city);


--
-- Name: citycover_raw citycover_raw_isolabel_ext_key; Type: CONSTRAINT; Schema: osmc; Owner: postgres
--

ALTER TABLE ONLY osmc.citycover_raw
    ADD CONSTRAINT citycover_raw_isolabel_ext_key UNIQUE (isolabel_ext);


--
-- Name: jurisdiction_bbox jurisdiction_bbox_pkey; Type: CONSTRAINT; Schema: osmc; Owner: postgres
--

ALTER TABLE ONLY osmc.jurisdiction_bbox
    ADD CONSTRAINT jurisdiction_bbox_pkey PRIMARY KEY (id);


--
-- Name: redirects_hashedfname_idx1; Type: INDEX; Schema: download; Owner: postgres
--

CREATE INDEX redirects_hashedfname_idx1 ON download.redirects USING btree (hashedfname);


--
-- Name: upsert_licenses_implieds_idx; Type: INDEX; Schema: license; Owner: postgres
--

CREATE UNIQUE INDEX upsert_licenses_implieds_idx ON license.licenses_implieds USING btree (id_label, COALESCE(id_version, ''::text));


--
-- Name: idx_geom_consolidated_data; Type: INDEX; Schema: optim; Owner: postgres
--

CREATE INDEX idx_geom_consolidated_data ON optim.consolidated_data USING gist (geom);


--
-- Name: jurisdiction_isolabel_ext_idx1; Type: INDEX; Schema: optim; Owner: postgres
--

CREATE INDEX jurisdiction_isolabel_ext_idx1 ON optim.jurisdiction USING btree (isolabel_ext);


--
-- Name: optim_jurisdiction_eez_idx1; Type: INDEX; Schema: optim; Owner: postgres
--

CREATE INDEX optim_jurisdiction_eez_idx1 ON optim.jurisdiction_eez USING gist (geom);


--
-- Name: optim_jurisdiction_eez_isolabel_ext_idx1; Type: INDEX; Schema: optim; Owner: postgres
--

CREATE INDEX optim_jurisdiction_eez_isolabel_ext_idx1 ON optim.jurisdiction_eez USING btree (isolabel_ext);


--
-- Name: optim_jurisdiction_geom_buffer_idx1; Type: INDEX; Schema: optim; Owner: postgres
--

CREATE INDEX optim_jurisdiction_geom_buffer_idx1 ON optim.jurisdiction_geom_buffer USING gist (geom);


--
-- Name: optim_jurisdiction_geom_buffer_isolabel_ext_idx1; Type: INDEX; Schema: optim; Owner: postgres
--

CREATE INDEX optim_jurisdiction_geom_buffer_isolabel_ext_idx1 ON optim.jurisdiction_geom_buffer USING btree (isolabel_ext);


--
-- Name: optim_jurisdiction_geom_buffer_osm_id_idx1; Type: INDEX; Schema: optim; Owner: postgres
--

CREATE INDEX optim_jurisdiction_geom_buffer_osm_id_idx1 ON optim.jurisdiction_geom_buffer USING btree (osm_id);


--
-- Name: optim_jurisdiction_geom_idx1; Type: INDEX; Schema: optim; Owner: postgres
--

CREATE INDEX optim_jurisdiction_geom_idx1 ON optim.jurisdiction_geom USING gist (geom);


--
-- Name: optim_jurisdiction_geom_isolabel_ext_idx1; Type: INDEX; Schema: optim; Owner: postgres
--

CREATE INDEX optim_jurisdiction_geom_isolabel_ext_idx1 ON optim.jurisdiction_geom USING btree (isolabel_ext);


--
-- Name: optim_jurisdiction_geom_point_idx1; Type: INDEX; Schema: optim; Owner: postgres
--

CREATE INDEX optim_jurisdiction_geom_point_idx1 ON optim.jurisdiction_geom_point USING gist (geom);


--
-- Name: optim_jurisdiction_geom_svg_idx1; Type: INDEX; Schema: optim; Owner: postgres
--

CREATE INDEX optim_jurisdiction_geom_svg_idx1 ON optim.jurisdiction_geom USING gist (geom_svg);


--
-- Name: idx_jbbox_geom; Type: INDEX; Schema: osmc; Owner: postgres
--

CREATE INDEX idx_jbbox_geom ON osmc.jurisdiction_bbox USING gist (geom);


--
-- Name: mvjurisdiction_bbox_border_id; Type: INDEX; Schema: osmc; Owner: postgres
--

CREATE UNIQUE INDEX mvjurisdiction_bbox_border_id ON osmc.mvjurisdiction_bbox_border USING btree (id);


--
-- Name: jurisdiction_abbrev_synonym; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX jurisdiction_abbrev_synonym ON public.mvwjurisdiction_synonym USING btree (synonym);


--
-- Name: donated_packtpl check_kx_num_files; Type: TRIGGER; Schema: optim; Owner: postgres
--

CREATE TRIGGER check_kx_num_files BEFORE INSERT OR UPDATE ON optim.donated_packtpl FOR EACH ROW EXECUTE FUNCTION optim.mkdonated_packtpl();


--
-- Name: donor check_kx_vat_id; Type: TRIGGER; Schema: optim; Owner: postgres
--

CREATE TRIGGER check_kx_vat_id BEFORE INSERT OR UPDATE ON optim.donor FOR EACH ROW EXECUTE FUNCTION optim.input_donor();


--
-- Name: donated_packfilevers generate_id_packfilevers; Type: TRIGGER; Schema: optim; Owner: postgres
--

CREATE TRIGGER generate_id_packfilevers BEFORE INSERT ON optim.donated_packfilevers FOR EACH ROW EXECUTE FUNCTION optim.input_donated_packfilevers();


--
-- Name: donated_packtpl generate_id_packtpl; Type: TRIGGER; Schema: optim; Owner: postgres
--

CREATE TRIGGER generate_id_packtpl BEFORE INSERT OR UPDATE ON optim.donated_packtpl FOR EACH ROW EXECUTE FUNCTION optim.input_donated_packtpl();


--
-- Name: consolidated_data consolidated_data_id_fkey; Type: FK CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.consolidated_data
    ADD CONSTRAINT consolidated_data_id_fkey FOREIGN KEY (id) REFERENCES optim.donated_packcomponent(id);


--
-- Name: consolidated_data_pre consolidated_data_pre_id_fkey; Type: FK CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.consolidated_data_pre
    ADD CONSTRAINT consolidated_data_pre_id_fkey FOREIGN KEY (id) REFERENCES optim.donated_packcomponent(id);


--
-- Name: donated_packcomponent_cloudcontrol donated_packcomponent_cloudcontrol_ftid_fkey; Type: FK CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packcomponent_cloudcontrol
    ADD CONSTRAINT donated_packcomponent_cloudcontrol_ftid_fkey FOREIGN KEY (ftid) REFERENCES optim.feature_type(ftid);


--
-- Name: donated_packcomponent_cloudcontrol donated_packcomponent_cloudcontrol_packvers_id_fkey; Type: FK CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packcomponent_cloudcontrol
    ADD CONSTRAINT donated_packcomponent_cloudcontrol_packvers_id_fkey FOREIGN KEY (packvers_id) REFERENCES optim.donated_packfilevers(id);


--
-- Name: donated_packcomponent donated_packcomponent_ftid_fkey; Type: FK CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packcomponent
    ADD CONSTRAINT donated_packcomponent_ftid_fkey FOREIGN KEY (ftid) REFERENCES optim.feature_type(ftid);


--
-- Name: donated_packcomponent_not_approved donated_packcomponent_not_approved_ftid_fkey; Type: FK CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packcomponent_not_approved
    ADD CONSTRAINT donated_packcomponent_not_approved_ftid_fkey FOREIGN KEY (ftid) REFERENCES optim.feature_type(ftid);


--
-- Name: donated_packcomponent_not_approved donated_packcomponent_not_approved_packvers_id_fkey; Type: FK CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packcomponent_not_approved
    ADD CONSTRAINT donated_packcomponent_not_approved_packvers_id_fkey FOREIGN KEY (packvers_id) REFERENCES optim.donated_packfilevers(id);


--
-- Name: donated_packcomponent donated_packcomponent_packvers_id_fkey; Type: FK CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packcomponent
    ADD CONSTRAINT donated_packcomponent_packvers_id_fkey FOREIGN KEY (packvers_id) REFERENCES optim.donated_packfilevers(id);


--
-- Name: donated_packfilevers donated_packfilevers_pack_id_fkey; Type: FK CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packfilevers
    ADD CONSTRAINT donated_packfilevers_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES optim.donated_packtpl(id);


--
-- Name: donated_packfilevers donated_packfilevers_user_resp_fkey; Type: FK CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packfilevers
    ADD CONSTRAINT donated_packfilevers_user_resp_fkey FOREIGN KEY (user_resp) REFERENCES optim.auth_user(username);


--
-- Name: donated_packtpl donated_packtpl_donor_id_fkey; Type: FK CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packtpl
    ADD CONSTRAINT donated_packtpl_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES optim.donor(id);


--
-- Name: donated_packtpl donated_packtpl_user_resp_fkey; Type: FK CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donated_packtpl
    ADD CONSTRAINT donated_packtpl_user_resp_fkey FOREIGN KEY (user_resp) REFERENCES optim.auth_user(username);


--
-- Name: donor donor_scope_osm_id_fkey; Type: FK CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.donor
    ADD CONSTRAINT donor_scope_osm_id_fkey FOREIGN KEY (scope_osm_id) REFERENCES optim.jurisdiction(osm_id);


--
-- Name: jurisdiction_abbrev_option jurisdiction_abbrev_option_abbrevref_id_fkey; Type: FK CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction_abbrev_option
    ADD CONSTRAINT jurisdiction_abbrev_option_abbrevref_id_fkey FOREIGN KEY (abbrevref_id) REFERENCES optim.jurisdiction_abbrev_ref(abbrevref_id);


--
-- Name: jurisdiction jurisdiction_parent_id_fkey; Type: FK CONSTRAINT; Schema: optim; Owner: postgres
--

ALTER TABLE ONLY optim.jurisdiction
    ADD CONSTRAINT jurisdiction_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES optim.jurisdiction(osm_id);


--
-- PostgreSQL database dump complete
--

\unrestrict QZK8KSL5DB2FrBjcLYxtoONXNsAntomKsYOLKIproWt7btA1hAF5cImhZODBfn6

