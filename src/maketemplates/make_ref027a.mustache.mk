##
## Template file reference: preserv-BR/data/RS/PortoAlegre/_pk0018.01
## tplId: 027a
##
tplInputSchema_id = 027a

## BASIC CONFIG
srid              = {{srid}}
pg_io             = {{pg_io}}
orig              = {{orig}}
pg_uri            = {{pg_uri}}
pg_db             = {{pg_db}}
sandbox_root      = {{sandbox}}
sandbox           = $(sandbox_root)/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}}
need_commands     = 7z v16+; psql v12+; shp2pgsql v3+; {{need_extra_commands}}

## COMPOSED VARS
pg_uri_db         = $(pg_uri)/$(pg_db)


all:
	@echo "=== Resumo deste makefile de recuperação de dados preservados ==="
	@printf "Targets para a geração de layers:\n\tall_layers {{#layers_keys}}{{.}} {{/layers_keys}}\n"
{{#openstreetmap}}
	@printf "Target para carregar dados do OpenStreetMap: openstreetmap.\n"
	@printf "ATENÇÂO. Execute make openstreetmap antes de fazer a ingestão dos layers.\n"
{{/openstreetmap}}
{{#joins}}
	@printf "Targets para join de layers:\n\tall_joins {{#joins_keys}}{{.}} {{/joins_keys}}\n"
{{/joins}}
	@printf "Demais targets implementados:\n\tmakedirs clean clean_sandbox wget_files me readme delete_file\n"
	@echo "A geração de layers requer os seguintes comandos e versões:\n\t$(need_commands)"
{{#layers}}
	@printf "Targets de publicação de layers:\n"
{{#block}}
	@printf "\tpublicating_geojsons_block audit-geojsons_block change_parameters_block\n"
{{/block}}
{{#building}}
	@printf "\tpublicating_geojsons_building audit-geojsons_building change_parameters_building\n"
{{/building}}
{{#genericvia}}
	@printf "\tpublicating_geojsons_genericvia audit-geojsons_genericvia change_parameters_genericvia\n"
{{/genericvia}}
{{#geoaddress}}
	@printf "\tpublicating_geojsons_geoaddress audit-geojsons_geoaddress change_parameters_geoaddress\n"
{{/geoaddress}}
{{#nsvia}}
	@printf "\tpublicating_geojsons_nsvia audit-geojsons_nsvia change_parameters_nsvia\n"
{{/nsvia}}
{{#parcel}}
	@printf "\tpublicating_geojsons_parcel audit-geojsons_parcel change_parameters_parcel\n"
{{/parcel}}
{{#via}}
	@printf "\tpublicating_geojsons_via audit-geojsons_via change_parameters_via\n"
{{/via}}
{{/layers}}

all_layers: {{#layers_keys}}{{.}} {{/layers_keys}}
	@echo "--ALL LAYERS--"
{{#joins}}
all_joins: {{#joins_keys}}join-{{.}} {{/joins_keys}}
	@echo "--ALL JOINS--"
{{/joins}}

## ## ## ## ## ## ## ## ##
## Make targets of the Project Digital Preservation
## Sponsored by Project AddressForAll
{{#layers}}
{{#address}}
address: tabname = {{tabname}}
address: makedirs $(orig)/{{sha256file}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common007_layerFooter}}

address-clean:
{{>common006_clean}}
{{/address}}

{{#block}}
block: tabname = {{tabname}}
block: makedirs $(orig)/{{sha256file}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common007_layerFooter}}

block-clean:
{{>common006_clean}}

{{>common008_publicating_geojsons}}
{{/block}}

{{#building}}
building: tabname = {{tabname}}
building: makedirs $(orig)/{{sha256file}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common007_layerFooter}}

building-clean:
{{>common006_clean}}

{{>common008_publicating_geojsons}}
{{/building}}

{{#cadparcel}}
cadparcel: tabname = {{tabname}}
cadparcel: makedirs $(orig)/{{sha256file}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common007_layerFooter}}

cadparcel-clean:
{{>common006_clean}}
{{/cadparcel}}

{{#cadvia}}
cadvia: tabname = {{tabname}}
cadvia: makedirs $(orig)/{{sha256file}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common007_layerFooter}}

cadvia-clean:
{{>common006_clean}}
{{/cadvia}}

{{#genericvia}}
genericvia: tabname = {{tabname}}
genericvia: makedirs $(orig)/{{sha256file}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common007_layerFooter}}

genericvia-clean:
{{>common006_clean}}

{{>common008_publicating_geojsons}}
{{/genericvia}}

{{#geoaddress}}
geoaddress: tabname = {{tabname}}
geoaddress: makedirs $(orig)/{{sha256file}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{#isOsm}}
	psql $(pg_uri_db) -c "CREATE VIEW vw{{file}}_{{tabname}} AS SELECT way, tags - ARRAY['addr:housenumber','addr:street'] || jsonb_objslice(ARRAY['addr:housenumber','addr:street'], tags, ARRAY['house_number','via_name']) AS tags FROM jplanet_osm_point WHERE tags ?| ARRAY['addr:housenumber','addr:street'] AND country_id = {{country_id}}::smallint "
{{/isOsm}}
{{>common001_pgAny_load}}
{{>common007_layerFooter}}

geoaddress-clean:
{{>common006_clean}}

{{>common008_publicating_geojsons}}
{{/geoaddress}}

{{#nsvia}}
nsvia: tabname = {{tabname}}
nsvia: makedirs $(orig)/{{sha256file}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common007_layerFooter}}

nsvia-clean:
{{>common006_clean}}

{{>common008_publicating_geojsons}}
{{/nsvia}}

{{#parcel}}
parcel: tabname = {{tabname}}
parcel: makedirs $(orig)/{{sha256file}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
{{>common007_layerFooter}}

parcel-clean:
{{>common006_clean}}

{{>common008_publicating_geojsons}}
{{/parcel}}

{{#via}}
via: tabname = {{tabname}}
via: makedirs $(orig)/{{sha256file}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{#isOsm}}
	psql $(pg_uri_db) -c "CREATE VIEW vw{{file}}_{{tabname}} AS SELECT way, tags FROM jplanet_osm_roads WHERE tags->>'highway' IN ('residential','unclassified','tertiary','secondary','primary','trunk','motorway') AND country_id = {{country_id}}::smallint "
{{/isOsm}}
{{>common001_pgAny_load}}
{{>common007_layerFooter}}

via-clean:
{{>common006_clean}}

{{>common008_publicating_geojsons}}
{{/via}}
{{/layers}}

{{#openstreetmap}}
openstreetmap: makedirs $(orig)/{{sha256file}}
	@# pk{{pack_id}}_p{{file}} - ETL extrating to PostgreSQL/PostGIS the "openstreetmap" data
	cd $(sandbox);  cp  $(orig)/{{sha256file}} . ; chmod -R a+rwx . > /dev/null
	osm2pgsql -E {{srid}} -c -d $(pg_db) -U postgres -H localhost --slim --hstore --extra-attributes --hstore-add-index --multi-geometry --number-processes 4 --style /usr/share/osm2pgsql/empty.style $(sandbox)/{{sha256file}}
	@echo "Convertendo hstore para jsonb"
	psql $(pg_uri_db) -c "SELECT ingest.jplanet_inserts_and_drops({{country_id}}::smallint,true);"
{{>common007_layerFooter}}

openstreetmap-clean:
{{>common006_clean}}
{{/openstreetmap}}

{{#joins}}
{{#genericvia}}
join-genericvia:
{{>common005_join}}
{{/genericvia}}

{{#geoaddress}}
join-geoaddress:
{{>common005_join}}
{{/geoaddress}}

{{#via}}
join-via:
{{>common005_join}}
{{/via}}

{{#parcel}}
join-parcel:
{{>common005_join}}
{{/parcel}}
{{/joins}}


## ## ## ## ## ## ## ## ##

makedirs: clean_sandbox
	@mkdir -m 777 -p $(sandbox_root)
	@mkdir -m 777 -p $(sandbox)
	@mkdir -p $(pg_io)

wget_files:
	@echo "Under construction, need to check that orig path is not /var/www! or use orig=x [ENTER if not else ^C]"
	@echo $(orig)
	@read -p "[Press ENTER to continue or Ctrl+C to quit]" _press_enter_
	mkdir -p $(orig)
{{#files}}
	@cd $(orig); wget http://preserv.addressforall.org/download/{{file}} && chmod o+rw {{file}}
{{/files}}
	@echo "Please, if orig not default, run 'make _target_ orig=$(orig)'"

## ## ## ## ## ## ## ## ##

clean_sandbox:
	@rm -rf $(sandbox) || true

clean: {{#layers_keys}}{{.}}-clean {{/layers_keys}}{{#openstreetmap}} openstreetmap-clean{{/openstreetmap}}
