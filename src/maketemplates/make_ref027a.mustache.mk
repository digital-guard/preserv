##
## Template file reference: preserv-BR/data/RS/PortoAlegre/_pk027
## tplId: 027a
##
tplInputSchema_id=027a

## BASIC CONFIG
srid   ={{srid}}
pg_io  ={{pg_io}}
orig   ={{orig}}
pg_uri ={{pg_uri}}
pg_db  ={{pg_db}}
sandbox_root={{sandbox}}
sandbox=$(sandbox_root)/_pk{{jurisdiction}}{{pack_id}}_{{pkversion}}
need_commands= 7z v16+; psql v12+; shp2pgsql v3+; {{need_extra_commands}}

## COMPOSED VARS
pg_uri_db   =$(pg_uri)/$(pg_db)


all:
	@echo "=== Resumo deste makefile de recuperação de dados preservados ==="
	@printf "Targets para a geração de layers:\n\tall_layers {{#layers_keys}}{{.}} {{/layers_keys}}\n"
{{#joins}}
	@printf "Targets para join de layers:\n\tall_joins {{#joins_keys}}{{.}} {{/joins_keys}}\n"
{{/joins}}
	@printf "Demais targets implementados:\n\tmakedirs clean clean_sandbox wget_files me readme delete_file\n"
	@echo "A geração de layers requer os seguintes comandos e versões:\n\t$(need_commands)"

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
{{/genericvia}}

{{#geoaddress}}
geoaddress: tabname = {{tabname}}
geoaddress: makedirs $(orig)/{{sha256file}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{#isOsm}}
	psql $(pg_uri_db) -c "CREATE VIEW vw{{file}}_{{tabname}} AS SELECT way, tags - ARRAY['addr:housenumber','addr:street'] || jsonb_objslice(ARRAY['addr:housenumber','addr:street'], tags, ARRAY['house_number','via_name']) AS tags FROM jplanet_osm_point WHERE tags ?| ARRAY['addr:housenumber','addr:street'] "
{{/isOsm}}
{{>common001_pgAny_load}}
{{>common007_layerFooter}}

geoaddress-clean:
{{>common006_clean}}
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
{{/parcel}}

{{#via}}
via: tabname = {{tabname}}
via: makedirs $(orig)/{{sha256file}}
{{>common002_layerHeader}}
{{>common003_shp2pgsql}}
{{#isOsm}}
	psql $(pg_uri_db) -c "CREATE VIEW vw{{file}}_{{tabname}} AS SELECT way, tags FROM jplanet_osm_roads WHERE tags->>'highway' IN ('residential','unclassified','tertiary','secondary','primary','trunk','motorway') "
{{/isOsm}}
{{>common001_pgAny_load}}
{{>common007_layerFooter}}

via-clean:
{{>common006_clean}}
{{/via}}
{{/layers}}

{{#openstreetmap}}
openstreetmap: makedirs $(orig)/{{sha256file}}
	@# pk{{pack_id}}_p{{file}} - ETL extrating to PostgreSQL/PostGIS the "openstreetmap" data
	cd $(sandbox);  cp  $(orig)/{{sha256file}} . ; chmod -R a+rx . > /dev/null
	osm2pgsql -E {{srid}} -c -d $(pg_db) -U postgres -H localhost --slim --hstore --extra-attributes --hstore-add-index --multi-geometry --number-processes 4 --style /usr/share/osm2pgsql/empty.style $(sandbox)/{{sha256file}}
	@echo "Convertendo hstore para jsonb"
	psql $(pg_uri_db) < /var/gits/_dg/preserv/src/osm_hstore2jsonb.sql
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
	@read _ENTER_OK_
	mkdir -p $(orig)
{{#files}}
	@cd $(orig); wget http://preserv.addressforall.org/download/{{file}} && chmod o+rw {{file}}
{{/files}}
	@echo "Please, if orig not default, run 'make _target_ orig=$(orig)'"

## ## ## ## ## ## ## ## ##

clean_sandbox:
	@rm -rf $(sandbox) || true

clean: {{#layers_keys}}{{.}}-clean {{/layers_keys}}{{#openstreetmap}} openstreetmap-clean{{/openstreetmap}}
