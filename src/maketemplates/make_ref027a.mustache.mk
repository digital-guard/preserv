##
## Template file reference: preserv-BR/data/RS/PortoAlegre/_pk027
## tplId: 027a
##
tplInputSchema_id=027a

## BASIC CONFIG
pg_io  ={{pg_io}}
orig   ={{orig}}
pg_uri ={{pg_uri}}
sandbox_root={{sandbox}}
need_commands= 7z v16+; psql v12+; shp2pgsql v3+; {{need_extra_commands}}

pkid = {{pkid}}
fullPkID={{pkid}}_{{pkversion}}
sandbox=$(sandbox_root)/_pk$(fullPkID)

## USER CONFIGS
pg_db  ={{pg_db}}

## ## ## ## ## ## ##
## THIS_MAKE, _pk{{pkid}}

{{#files}}
part{{p}}_file  ={{file}}
part{{p}}_name  ={{name}}
{{/files}}

## COMPOSED VARS
pg_uri_db   =$(pg_uri)/$(pg_db)
{{#files}}
part{{p}}_path  =$(orig)/$(part{{p}}_file)
{{/files}}

all:
	@echo "=== Resumo deste makefile de recuperação de dados preservados ==="
	@printf "Targets para a geração de layers:\n\tall_layers {{#layers_keys}}{{.}} {{/layers_keys}}\n"
	@printf "Targets para join de layers:\n\tall_joins {{#joins_keys}}{{.}} {{/joins_keys}}\n"
	@printf "Demais targets implementados:\n\tmakedirs clean clean_sandbox wget_files me readme delete_file\n"
	@echo "A geração de layers requer os seguintes comandos e versões:\n\t$(need_commands)"

all_layers: {{#layers_keys}}{{.}} {{/layers_keys}}
	@echo "--ALL LAYERS--"

all_joins: {{#joins_keys}}join-{{.}} {{/joins_keys}}
	@echo "--ALL JOINS--"

## ## ## ## ## ## ## ## ##
## ## ## ## ## ## ## ## ##
## Make targets of the Project Digital Preservation
## Sponsored by Project AddressForAll
{{#layers}}
{{#address}}
address: layername = address_{{subtype}}
address: tabname = pk$(fullPkID)_p{{file}}_address
address: makedirs $(part{{file}}_path)
	@# pk{{pkid}}_p{{file}} - ETL extrating to PostgreSQL/PostGIS the "address" datatype (street axes)
{{>common002_layerHeader}}
	cd $(sandbox); 7z {{7z_opts}} x -y $(part{{file}}_path) "*{{orig_filename}}*" ; chmod -R a+rx . > /dev/null
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
	@echo FIM.

address-clean: tabname = pk$(fullPkID)_p{{file}}_address
address-clean:
	rm -f "$(sandbox)/*{{orig_filename}}.*" || true
	psql $(pg_uri_db) -c "DROP TABLE IF EXISTS $(tabname) CASCADE"
{{/address}}

{{#block}}
block: layername = block_{{subtype}}
block: tabname = pk$(fullPkID)_p{{file}}_block
block: makedirs $(part{{file}}_path)
	@# pk{{pkid}}_p{{file}} - ETL extrating to PostgreSQL/PostGIS the "block" datatype (street axes)
{{>common002_layerHeader}}
	cd $(sandbox); 7z {{7z_opts}} x -y $(part{{file}}_path) "*{{orig_filename}}*" ; chmod -R a+rx . > /dev/null
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
	@echo FIM.

block-clean: tabname = pk$(fullPkID)_p{{file}}_block
block-clean:
	rm -f "$(sandbox)/*{{orig_filename}}.*" || true
	psql $(pg_uri_db) -c "DROP TABLE IF EXISTS $(tabname) CASCADE"
{{/block}}

{{#building}}
building: layername = building_{{subtype}}
building: tabname = pk$(fullPkID)_p{{file}}_building
building: makedirs $(part{{file}}_path)
	@# pk{{pkid}}_p{{file}} - ETL extrating to PostgreSQL/PostGIS the "building" datatype (point with house_number but no via name)
{{>common002_layerHeader}}
	cd $(sandbox); 7z {{7z_opts}} x -y $(part{{file}}_path) "*{{orig_filename}}*" ; chmod -R a+rx . > /dev/null
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
	@echo FIM.

building-clean: tabname = pk$(fullPkID)_p{{file}}_building
building-clean:
	rm -f "$(sandbox)/*{{orig_filename}}.*" || true
	psql $(pg_uri_db) -c "DROP TABLE IF EXISTS $(tabname) CASCADE"
{{/building}}

{{#cadparcel}}
cadparcel: layername = cadparcel_{{subtype}}
cadparcel: tabname = pk$(fullPkID)_p{{file}}_cadparcel
cadparcel: makedirs $(part{{file}}_path)
	@# pk{{pkid}}_p{{file}} - ETL extrating to PostgreSQL/PostGIS the "cadparcel" datatype (street axes)
{{>common002_layerHeader}}
	cd $(sandbox); 7z {{7z_opts}} x -y $(part{{file}}_path) "*{{orig_filename}}*" ; chmod -R a+rx . > /dev/null
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
	@echo FIM.

cadparcel-clean: tabname = pk$(fullPkID)_p{{file}}_cadparcel
cadparcel-clean:
	rm -f "$(sandbox)/*{{orig_filename}}.*" || true
	psql $(pg_uri_db) -c "DROP TABLE IF EXISTS $(tabname) CASCADE"
{{/cadparcel}}

{{#cadvia}}
cadvia: layername = cadvia_{{subtype}}
cadvia: tabname = pk$(fullPkID)_p{{file}}_cadvia
cadvia: makedirs $(part{{file}}_path)
	@# pk{{pkid}}_p{{file}} - ETL extrating to PostgreSQL/PostGIS the "cadvia" datatype (street axes)
{{>common002_layerHeader}}
	cd $(sandbox); 7z {{7z_opts}} x -y $(part{{file}}_path) "*{{orig_filename}}*" ; chmod -R a+rx . > /dev/null
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
	@echo FIM.

cadvia-clean: tabname = pk$(fullPkID)_p{{file}}_cadvia
cadvia-clean:
	rm -f "$(sandbox)/*{{orig_filename}}.*" || true
	psql $(pg_uri_db) -c "DROP TABLE IF EXISTS $(tabname) CASCADE"
{{/cadvia}}

{{#genericvia}}
genericvia: layername = genericvia_{{subtype}}
genericvia: tabname = pk$(fullPkID)_p{{file}}_genericvia
genericvia: makedirs $(part{{file}}_path)
	@# pk{{pkid}}_p{{file}} - ETL extrating to PostgreSQL/PostGIS the "genericvia" datatype (zone with name)
{{>common002_layerHeader}}
	cd $(sandbox); 7z {{7z_opts}} x -y $(part{{file}}_path) "*{{orig_filename}}*" ; chmod -R a+rx . > /dev/null
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
	@echo FIM.

genericvia-clean: tabname = pk$(fullPkID)_p{{file}}_genericvia
genericvia-clean:
	rm -f "$(sandbox)/*{{orig_filename}}.*" || true
	psql $(pg_uri_db) -c "DROP TABLE IF EXISTS $(tabname) CASCADE;  DROP VIEW IF EXISTS vw_$(tabname) CASCADE;"
{{/genericvia}}

{{#geoaddress}}
geoaddress: layername = geoaddress_{{subtype}}
geoaddress: tabname = pk$(fullPkID)_p{{file}}_geoaddress
geoaddress: makedirs $(part{{file}}_path)
	@# pk{{pkid}}_p{{file}} - ETL extrating to PostgreSQL/PostGIS the "geoaddress" datatype (point with house_number but no via name)
{{>common002_layerHeader}}
	cd $(sandbox); 7z {{7z_opts}} x -y $(part{{file}}_path) "*{{orig_filename}}*" ; chmod -R a+rx . > /dev/null
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
	@echo FIM.

geoaddress-clean: tabname = pk$(fullPkID)_p{{file}}_geoaddress
geoaddress-clean:
	rm -f "$(sandbox)/*{{orig_filename}}.*" || true
	psql $(pg_uri_db) -c "DROP TABLE IF EXISTS $(tabname) CASCADE"
{{/geoaddress}}

{{#nsvia}}
nsvia: layername = nsvia_{{subtype}}
nsvia: tabname = pk$(fullPkID)_p{{file}}_nsvia
nsvia: makedirs $(part{{file}}_path)
	@# pk{{pkid}}_p{{file}} - ETL extrating to PostgreSQL/PostGIS the "nsvia" datatype (zone with name)
{{>common002_layerHeader}}
	cd $(sandbox); 7z {{7z_opts}} x -y $(part{{file}}_path) "*{{orig_filename}}*" ; chmod -R a+rx . > /dev/null
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
	@echo FIM.

nsvia-clean: tabname = pk$(fullPkID)_p{{file}}_nsvia
nsvia-clean:
	rm -f "$(sandbox)/*{{orig_filename}}.*" || true
	psql $(pg_uri_db) -c "DROP TABLE IF EXISTS $(tabname) CASCADE;  DROP VIEW IF EXISTS vw_$(tabname) CASCADE;"
{{/nsvia}}

{{#parcel}}
parcel: layername = parcel_{{subtype}}
parcel: tabname = pk$(fullPkID)_p{{file}}_parcel
parcel: makedirs $(part{{file}}_path)
	@# pk{{pkid}}_p{{file}} - ETL extrating to PostgreSQL/PostGIS the "parcel" datatype (street axes)
{{>common002_layerHeader}}
	cd $(sandbox); 7z {{7z_opts}} x -y $(part{{file}}_path) "*{{orig_filename}}*" ; chmod -R a+rx . > /dev/null
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
	@echo FIM.

parcel-clean: tabname = pk$(fullPkID)_p{{file}}_parcel
parcel-clean:
	rm -f "$(sandbox)/*{{orig_filename}}.*" || true
	psql $(pg_uri_db) -c "DROP TABLE IF EXISTS $(tabname) CASCADE"
{{/parcel}}

{{#via}}
via: layername = via_{{subtype}}
via: tabname = pk$(fullPkID)_p{{file}}_via
via: makedirs $(part{{file}}_path)
	@# pk{{pkid}}_p{{file}} - ETL extrating to PostgreSQL/PostGIS the "via" datatype (street axes)
{{>common002_layerHeader}}
	cd $(sandbox); 7z {{7z_opts}} x -y $(part{{file}}_path) "*{{orig_filename}}*" ; chmod -R a+rx . > /dev/null
{{>common003_shp2pgsql}}
{{>common001_pgAny_load}}
	@echo FIM.

via-clean: tabname = pk$(fullPkID)_p{{file}}_via
via-clean:
	rm -f "$(sandbox)/*{{orig_filename}}.*" || true
	psql $(pg_uri_db) -c "DROP TABLE IF EXISTS $(tabname) CASCADE"
{{/via}}
{{/layers}}

## ## ## ## ## ## ## ## ##
## ## ## ## ## ## ## ## ##

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

## ## ## ##

clean_sandbox:
	@rm -rf $(sandbox) || true

clean: {{#layers_keys}}{{.}}-clean {{/layers_keys}}
