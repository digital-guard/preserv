#!/bin/bash

{{#layers}}
{{#address}}
# layer address:
rm -rf {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{/address}}

{{#block}}
# layer block:
rm -rf {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{>common008_publicating_geojsons}}
{{/block}}

{{#building}}
# layer building:
rm -rf {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{>common008_publicating_geojsons}}
{{/building}}

{{#cadparcel}}
# layer cadparcel:
rm -rf {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{/cadparcel}}

{{#cadvia}}
# layer cadvia:
rm -rf {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{/cadvia}}

{{#genericvia}}
# layer genericvia:
rm -rf {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{>common008_publicating_geojsons}}
{{/genericvia}}

{{#geoaddress}}
# layer geoaddress:
rm -rf {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{#isOsm}}
psql {{pg_uri}}/{{pg_db}} -c "CREATE VIEW vw{{file}}_{{tabname}} AS SELECT way, tags - ARRAY['addr:housenumber','addr:street'] || jsonb_objslice(ARRAY['addr:housenumber','addr:street'], tags, ARRAY['hnum','via']) AS tags FROM jplanet_osm_point WHERE tags ?| ARRAY['addr:housenumber','addr:street'] AND country_id = {{data_packtpl.country_id}}::smallint UNION ALL SELECT ST_PointOnSurface(way) AS way, tags - ARRAY['addr:housenumber','addr:street'] || jsonb_objslice(ARRAY['addr:housenumber','addr:street'], tags, ARRAY['hnum','via']) AS tags FROM jplanet_osm_polygon WHERE tags ?| ARRAY['addr:housenumber','addr:street'] AND tags ?& ARRAY['building'] AND country_id = {{data_packtpl.country_id}}::smallint "
{{/isOsm}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{>common008_publicating_geojsons}}
{{/geoaddress}}

{{#nsvia}}
# layer nsvia:
rm -rf {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{>common008_publicating_geojsons}}
{{/nsvia}}

{{#parcel}}
# layer parcel:
rm -rf {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{>common008_publicating_geojsons}}
{{/parcel}}

{{#via}}
# layer via:
rm -rf {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{#isOsm}}
psql {{pg_uri}}/{{pg_db}} -c "CREATE VIEW vw{{file}}_{{tabname}} AS SELECT way, tags - ARRAY['name'] || jsonb_objslice(ARRAY['name'], tags, ARRAY['via']) AS tags FROM jplanet_osm_line WHERE tags->>'highway' IN ('residential','unclassified','tertiary','secondary','primary','trunk','motorway') AND country_id = {{data_packtpl.country_id}}::smallint "
{{/isOsm}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{>common008_publicating_geojsons}}
{{/via}}

{{#datagrid}}
# layer datagrid:
rm -rf {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{>common008_publicating_geojsons}}
{{/datagrid}}
{{/layers}}

{{#openstreetmap}}
# layer openstreetmap:
rm -rf {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{packtpl_id}}_{{pkversion}}
mkdir -p {{pg_io}}
cp -s  {{orig}}/{{file_data.file}} {{sandbox}}/_pk{{pack_id}}_{{pkversion}}
osm2pgsql -E {{srid}} -c -d {{pg_db}} -U postgres -H localhost --slim --hstore --extra-attributes --hstore-add-index --multi-geometry --number-processes 4 --style /usr/share/osm2pgsql/empty.style {{sandbox}}/_pk{{pack_id}}_{{pkversion}}/{{file_data.file}}
psql {{pg_uri}}/{{pg_db}} -c "SELECT ingest.jplanet_inserts_and_drops({{data_packtpl.country_id}}::smallint,true);"
{{>common006_clean}}
{{/openstreetmap}}

{{#joins}}# layer joining
{{#genericvia}}{{>common005_join}}{{/genericvia}}
{{#geoaddress}}{{>common005_join}}{{/geoaddress}}
{{#via}}{{>common005_join}}{{/via}}
{{#parcel}}{{>common005_join}}{{/parcel}}{{/joins}}
