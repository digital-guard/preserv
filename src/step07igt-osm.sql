
CREATE TABLE IF NOT EXISTS jplanet_osm_point (
  country_id smallint   NOT NULL, 
  osm_id     bigint     NOT NULL,
  z_order    integer,
  tags       jsonb,
  way        geometry(Point,4326) NOT NULL,
  PRIMARY KEY(country_id, osm_id)
);
CREATE INDEX IF NOT EXISTS jplanet_osm_point_country
       ON jplanet_osm_point USING brin(country_id)
;

CREATE TABLE IF NOT EXISTS jplanet_osm_polygon (
  country_id smallint   NOT NULL, 
  osm_id     bigint     NOT NULL,
  z_order    integer,
  tags       jsonb,
  way        geometry(Geometry,4326) NOT NULL,
  PRIMARY KEY(country_id, osm_id)
);
CREATE INDEX IF NOT EXISTS jplanet_osm_polygon_country
       ON jplanet_osm_polygon USING brin(country_id)
;

CREATE TABLE IF NOT EXISTS jplanet_osm_line (
  country_id smallint   NOT NULL, 
  osm_id     bigint     NOT NULL,
  z_order    integer,
  tags       jsonb,
  way        geometry(MultiLineString,4326) NOT NULL,
  PRIMARY KEY(country_id, osm_id)
);
CREATE INDEX IF NOT EXISTS jplanet_osm_line_country
       ON jplanet_osm_line USING brin(country_id)
;

--------

CREATE FUNCTION ingest.jplanet_inserts_and_drops(
  p_country_id smallint,
  p_drop_extra boolean DEFAULT true
) RETURNS void AS $f$
BEGIN
  -- pending to build jplanet_osm_line of generic vias (waterway and railroad).
  DROP TABLE planet_osm_nodes;
  DROP TABLE planet_osm_roads;
  DROP TABLE planet_osm_rels;
  DROP TABLE planet_osm_ways;

  INSERT INTO jplanet_osm_point
    SELECT p_country_id, osm_id, z_order,
       jsonb_strip_nulls( lib.osm_to_jsonb(tags), true ) as tags,
       way
    FROM planet_osm_point
  ;
  DROP TABLE planet_osm_point
  ;
  
  INSERT INTO jplanet_osm_polygon
    SELECT p_country_id, osm_id, z_order,
       jsonb_strip_nulls( lib.osm_to_jsonb(tags), true ) as tags,
       way
    FROM planet_osm_polygon
  ;
  DROP TABLE planet_osm_polygon
  ;
  
  INSERT INTO jplanet_osm_line
    SELECT p_country_id, osm_id, MAX(z_order),
        jsonb_strip_nulls( lib.osm_to_jsonb((array_agg(tags))[1]), true ) AS tags,
        ST_Collect(way) AS way
    FROM planet_osm_line
    GROUP BY osm_id
  ;
  DROP TABLE planet_osm_line
  ;
END
$f$ language PLpgSQL;

-- To ingest planet of a country, for example Brazil:
-- SELECT ingest.jplanet_inserts_and_drops(76,true);
