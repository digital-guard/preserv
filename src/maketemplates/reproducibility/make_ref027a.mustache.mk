{{#layers}}
{{#address}}
address:
rm -rf {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{/address}}

{{#block}}
block:
rm -rf {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{>common008_publicating_geojsons}}
{{/block}}

{{#building}}
building:
rm -rf {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{>common008_publicating_geojsons}}
{{/building}}

{{#cadparcel}}
cadparcel:
rm -rf {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{/cadparcel}}

{{#cadvia}}
cadvia:
rm -rf {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{/cadvia}}

{{#genericvia}}
genericvia:
rm -rf {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{>common008_publicating_geojsons}}
{{/genericvia}}

{{#geoaddress}}
geoaddress:
rm -rf {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{#isOsm}}
psql {{pg_uri}}/{{pg_db}} -c "CREATE VIEW vw{{file}}_{{tabname}} AS SELECT way, tags - ARRAY['addr:housenumber','addr:street'] || jsonb_objslice(ARRAY['addr:housenumber','addr:street'], tags, ARRAY['house_number','via_name']) AS tags FROM jplanet_osm_point WHERE tags ?| ARRAY['addr:housenumber','addr:street'] AND country_id = {{country_id}}::smallint UNION ALL SELECT ST_PointOnSurface(way) AS way, tags - ARRAY['addr:housenumber','addr:street'] || jsonb_objslice(ARRAY['addr:housenumber','addr:street'], tags, ARRAY['house_number','via_name']) AS tags FROM jplanet_osm_polygon WHERE tags ?| ARRAY['addr:housenumber','addr:street'] AND tags ?& ARRAY['building'] AND country_id = {{country_id}}::smallint "
{{/isOsm}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{>common008_publicating_geojsons}}
{{/geoaddress}}

{{#nsvia}}
nsvia:
rm -rf {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{>common008_publicating_geojsons}}
{{/nsvia}}

{{#parcel}}
parcel:
rm -rf {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{>common008_publicating_geojsons}}
{{/parcel}}

{{#via}}
via:
rm -rf {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{#isOsm}}
psql {{pg_uri}}/{{pg_db}} -c "CREATE VIEW vw{{file}}_{{tabname}} AS SELECT way, tags - ARRAY['name'] || jsonb_objslice(ARRAY['name'], tags, ARRAY['via_name']) AS tags FROM jplanet_osm_line WHERE tags->>'highway' IN ('residential','unclassified','tertiary','secondary','primary','trunk','motorway') AND country_id = {{country_id}}::smallint "
{{/isOsm}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{>common008_publicating_geojsons}}
{{/via}}

{{#datagrid}}
datagrid:
rm -rf {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}}
mkdir -p {{pg_io}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common006_clean}}
{{>common008_publicating_geojsons}}
{{/datagrid}}
{{/layers}}

{{#openstreetmap}}
openstreetmap:
rm -rf {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}} || true
mkdir -m 777 -p {{sandbox}}
mkdir -m 777 -p {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}}
mkdir -p {{pg_io}}
cp -s  {{orig}}/{{file_data.file}} {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}}
osm2pgsql -E {{srid}} -c -d {{pg_db}} -U postgres -H localhost --slim --hstore --extra-attributes --hstore-add-index --multi-geometry --number-processes 4 --style /usr/share/osm2pgsql/empty.style {{sandbox}}/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}}/{{file_data.file}}
psql {{pg_uri}}/{{pg_db}} -c "SELECT ingest.jplanet_inserts_and_drops({{country_id}}::smallint,true);"
{{>common006_clean}}
{{/openstreetmap}}

{{#joins}}{{#genericvia}}{{>common005_join}}{{/genericvia}}
{{#geoaddress}}{{>common005_join}}{{/geoaddress}}
{{#via}}{{>common005_join}}{{/via}}
{{#parcel}}{{>common005_join}}{{/parcel}}{{/joins}}
