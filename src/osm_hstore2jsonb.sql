

CREATE TABLE jplanet_osm_point AS  
  SELECT osm_id, z_order,
       jsonb_strip_nulls( lib.osm_to_jsonb(tags), true ) as tags,
       way
  FROM planet_osm_point;

DROP TABLE planet_osm_point;


CREATE TABLE jplanet_osm_polygon AS  
  SELECT osm_id, z_order,
       jsonb_strip_nulls( lib.osm_to_jsonb(tags), true ) as tags,
       way
  FROM planet_osm_polygon;

DROP TABLE planet_osm_polygon;


CREATE TABLE jplanet_osm_roads AS  
  SELECT osm_id, z_order,
       jsonb_strip_nulls( lib.osm_to_jsonb(tags), true ) as tags,
       way
  FROM planet_osm_roads;

DROP TABLE planet_osm_roads;
