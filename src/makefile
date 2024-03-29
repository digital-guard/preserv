##
## Installing Project Digital Preservation
##

## ## ## ##
## -- VARS --

pg_io           := /tmp/pg_io
lockpath        := /var/gits/_lock-mkStatus

pg_uri_root     := postgres://postgres@localhost

## Danger dl05s_main, ingest1.
## Use dummy 99 to test.
pg_db           := ingest99
pg_datalake     := dl99t_main

pg_db_uri       := $(pg_uri_root)/$(pg_db)
pg_datalake_uri := $(pg_uri_root)/$(pg_datalake)

countries       := "'BR','CL','CO','EC','PE','VE'"  # em uso e conforme data/jurisdiction.csv

gits_basepath   := /var/gits
sbx_path        := /tmp/sandbox

DB_TEST         := $(shell psql $(pg_uri_root) -c "\l" | grep $(pg_db)       | cut -d'|' -f1 | tr -d ' ')
DL_TEST         := $(shell psql $(pg_uri_root) -c "\l" | grep $(pg_datalake) | cut -d'|' -f1 | tr -d ' ')

## ## ## ##
## -- CONFIGS --
.SILENT: message countpacks status_disk_abuse

## ## ## ##
## -- HELP --
message:
	echo "--------  make of the Preserv project ----------"
	echo
	echo " -- SQL BUILDERs --"
	echo " all: configure and prepare default test databases ingest99 and dl99t_main."
	echo " all pg_db=ingest42 pg_datalake=dl42t_main: configure and prepare custom databases ingest42 and dl42t_main."
	echo
	echo " ini_ingest: configure and prepare default test database ingest99."
	echo " ini_ingest pg_db=ingest42: configure and prepare custom database ingest42."
	echo
	echo " ini_datalake: configure and prepare default test database dl99t_main."
	echo " ini_datalake pg_datalake=dl42t_main: configure and prepare custom database dl42t_main."
	echo
	echo " -- REPORT tools --"
	echo " countpacks [pkdir=v]: count package-evidence files ok pkdir (e.g. preserv-BR) or its root"
	echo " status: of databases and disk usage"
	echo
	echo " -- ADMIN tools --"
	echo " cmd_rdap iso=<ISO 3166> pg_datalake=<database>: Update or create rdap.json for donor and donatedPack."
	echo
	echo " fix_usergroup username=v: add standard groups to username"
	echo " fix_usergroup username=v: add standard groups to username"
	echo " fix_permissions: execute chmod and chown in the standard folders"
	echo
	echo " get_wikidata_points: get points wikidata of BR and CO."
	echo
	echo
	echo " redirects_update: update download.redirects in default database dl."
	echo " redirects_update pg_datalake=dl42t_main: update download.redirects in custom database dl42t_main."
	echo " sha256_update: update sha256 in optim.donated_packfilevers."
	echo "         usage: make sha256_update pg_datalake=<datalake with optim schema> id=<id from optim.donated_packfilevers> oldsha256=<sha256 that will be changed> newsha256=<sha256 that will replace oldsha256>"
	echo
	echo " publicating_geojsons: "
	echo " build_fdwtable:"
	echo " first_makefile: copying initial makefile in 'data/_pk*' directories"
	echo " load_optim_csv pg_datalake=dl42t_main: load tables donor.csv and donatedPack.csv into pg_datalake optim tables, for all jurisdictions."
	echo " load_codec_type: update codec_type table. "
	echo " load_hcode_parameters: update hcode_parameters table. "
	echo " load_license_tables: create or update tmp_pack_licenses table. "
	echo " generate_pages pg_datalake=dl42t_main: create html pages for layers. "
	echo
	echo " to_donated_packcomponent pg_db=ingest42 pg_datalake=dl42t_main: copy ingest.donated_packcomponent to optim.donated_PackComponent_not_approved in DL03t_main. "
	echo " approved_donated_packcomponent id=42 pg_datalake=dl42t_main: approved packcomponent from optim.donated_PackComponent_not_approved to optim.donated_PackComponent. "
	echo " report pg_datalake= "
## ## ## ##
## -- SQL BUILDERs --

all: ini_all

ini_all: ini_ingest ini_datalake

ini_ingest: ini_ingest_sql load_hcode_parameters

ini_ingest_sql: pgio lck $(gits_basepath)/_a4a/pg_pubLib-v1/src/makefile
ifeq ($(DB_TEST),$(pg_db))
	@echo "... DROP old database $(pg_db)?"
	@read -p "[Press ENTER to drop or Ctrl+C to quit]" _press_enter_
	psql $(pg_uri_root) -c "DROP DATABASE $(pg_db)"
endif
	psql $(pg_uri_root) -c "CREATE DATABASE $(pg_db);"
	psql $(pg_uri_root) -c "COMMENT ON DATABASE $(pg_db) IS 'INGEST database.';"
	@echo "--- Preparing filesystem... ---"
	rm -f $(lockpath)/digitalPreservation-makeSQL.~feito
	@echo "--- Preparing databse... ---"
	@echo "--- Running SQL pg_pubLib ---"
	cd $(gits_basepath)/_a4a/pg_pubLib-v1/src; make all pg_db=$(pg_db)
	@echo "--- Running SQL GGeohash hcode ---"
	psql $(pg_db_uri) < $(gits_basepath)/_osmc/GGeohash/src/step01def-libHcode.sql
	@echo "--- Running Ingest ---"
	psql $(pg_db_uri) < $(gits_basepath)/_dg/preserv/src/lib-dg_preserv.sql
	psql $(pg_db_uri) < $(gits_basepath)/_dg/preserv/src/step01def-lib_osm.sql
	psql $(pg_db_uri) < $(gits_basepath)/_dg/preserv/src/ingest-step1-ini.sql
	psql $(pg_db_uri) < $(gits_basepath)/_dg/preserv/src/step07igt-osm.sql
	touch $(lockpath)/digitalPreservation-makeSQL.~feito
	chmod 666 $(lockpath)/digitalPreservation-makeSQL.~feito

ini_datalake: pgio lck $(gits_basepath)/_a4a/pg_pubLib-v1/src/makefile
ifeq ($(DL_TEST),$(pg_datalake))
	@echo "... DROP old database $(pg_datalake)?"
	@read -p "[Press ENTER to drop or Ctrl+C to quit]" _press_enter_
	psql $(pg_uri_root) -c "DROP DATABASE $(pg_datalake)"
endif
	psql $(pg_uri_root) -c "CREATE DATABASE $(pg_datalake);"
	psql $(pg_uri_root) -c "COMMENT ON DATABASE $(pg_datalake) IS 'TEST database.';"
	@echo "--- Preparing filesystem... ---"
	rm -f $(lockpath)/digitalPreservation-makeSQL.~feito
	@echo "--- Preparing databses... ---"
	@echo "--- Running SQL pubLib ---"
	cd $(gits_basepath)/_a4a/pg_pubLib-v1/src; make all pg_db=$(pg_datalake)
	@echo "Creating optim schema at $(pg_datalake) database"
	psql $(pg_datalake_uri) < $(gits_basepath)/_dg/preserv/src/step01def-lib.sql
	psql $(pg_datalake_uri) < $(gits_basepath)/_dg/preserv/src/optim-step1-ini.sql
	psql $(pg_datalake_uri) < $(gits_basepath)/_dg/preserv/src/optim-step2-ini.sql
	psql $(pg_datalake_uri) < $(gits_basepath)/_dg/preserv/src/optim-step3-publication.sql
	psql $(pg_datalake_uri) < $(gits_basepath)/_dg/preserv/src/optim-step6-metrics.sql
	psql $(pg_datalake_uri) < $(gits_basepath)/_dg/preserv/src/optim-step7-make.sql
	psql $(pg_datalake_uri) < $(gits_basepath)/_dg/preserv/src/optim-download-ini.sql
	psql $(pg_datalake_uri) < $(gits_basepath)/_dg/preserv/src/optim-step4-api.sql

	@echo "--- Running API SQL templates ---"
	@echo "!nao fazendo ainda, futuro"
	#psql $(pg_datalake_uri) < step00-iniApi.sql
	@echo "--- Running Eclusa ---"
	@echo "!nao fazendo ainda, futuro"
	#psql $(pg_datalake_uri) < eclusa/step1-ini.sql
	# sh eclusa-step2a-ins.sh
	#/var/gits/WS/src? psql $(pg_datalake_uri) < eclusa/step2b-ins.sql
	touch $(lockpath)/digitalPreservation-makeSQL.~feito
	chmod 666 $(lockpath)/digitalPreservation-makeSQL.~feito

generate_pages:
	@echo "--- Save html pages in $(folder) ---"
	@echo "--- Create $(folder)"
	mkdir -p $(folder)
	@echo "--- fix_permissions $(folder)"
	sudo bash fixaPermissoes.sh $(folder)
	@echo "--- Generate pages in $(folder)"
	@psql $(pg_datalake_uri) -c "SELECT optim.publicating_page('$(isolabel)','$(pk)','$(folder)');"
	@echo "--- Generate new index in $(folder)"
	@psql $(pg_datalake_uri) -c "SELECT optim.publicating_index_page('$(folder)');"
	@echo "--- fix_permissions $(folder)"
	sudo bash fixaPermissoes.sh $(folder)

generate_reproducibility: pg_datalake=dl05s_main
generate_reproducibility:
	@echo "-- Generating reproducibility.sh in $(output) --"
	@psql $(pg_uri_root)/$(pg_datalake) -c "SELECT optim.generate_reproducibility('$(country)','$(pack_id)','$(output)','$(baseSrcPack)','$(baseSrc)');"

generate_readme: pg_datalake=dl05s_main
generate_readme:
	@echo "-- Generating README.md in $(output) --"
	@psql $(pg_uri_root)/$(pg_datalake) -c "SELECT optim.generate_readme('$(country)','$(pack_id)','$(output)','$(baseSrcPack)','$(baseSrc)');"

generate_makefile: pg_datalake=dl05s_main
generate_makefile:
	@echo "-- Generating makefile in $(output) --"
	@psql $(pg_uri_root)/$(pg_datalake) -c "SELECT optim.generate_makefile('$(country)','$(pack_id)','$(output)','$(baseSrcPack)','$(baseSrc)');"

insert_license: pg_datalake=dl05s_main
insert_license:
	@echo "-- Inserting files_licenses in make_conf $(output) --"
	@psql $(pg_uri_root)/$(pg_datalake) -c "SELECT optim.generate_make_conf_with_license('$(country)','$(pack_id)','$(output)','$(baseSrcPack)','$(baseSrc)');"

insert_size: pg_datalake=dl05s_main
insert_size:
	@echo "-- Inserting size in files of make_conf --"
	@psql $(pg_uri_root)/$(pg_datalake) -c "SELECT optim.generate_make_conf_with_size('$(country)','$(pack_id)','$(output)','$(baseSrcPack)','$(baseSrc)','$(orig)');"

load_codec_type:
	@echo "--- codec_type load ---"
	psql $(pg_datalake_uri) -c "SELECT optim.insert_codec_type();"

load_hcode_parameters:
	@echo "--- hcode_parameters load ---"
	psql $(pg_db_uri) -c "SELECT ingest.load_hcode_parameters('$(gits_basepath)/_dg/preserv/data/hcode_parameters.csv',',');"

load_license_tables: pg_datalake=dl05s_main
load_license_tables: pgio
	@echo "--- license table load ---"
	psql $(pg_uri_root)/$(pg_datalake) -c "SELECT license.insert_licenses();"

load_optim_csv:
	@echo "Load tables donor.csv, donatedPack.csv and codec_type into $(pg_datalake_uri), for all jurisdictions."
	@read -p "[Press ENTER to continue or Ctrl+C to quit]" _press_enter_
	psql $(pg_datalake_uri) -c "SELECT optim.insert_donor_pack(t) FROM unnest(ARRAY['BO','BR','CL','CO','EC','MX','PE','PY','SR','UY','VE']) t;"
	psql $(pg_datalake_uri) -c "SELECT optim.insert_codec_type();"
	psql $(pg_datalake_uri) -c "SELECT optim.insert_jurisdPoint();"

redirects_update: pgio
	@echo "-- Atualização de redirecionamentos --"
	@echo "--- dl.digital-guard.org ---"
	psql $(pg_datalake_uri) -c "SELECT download.insert_dldg_csv();"
	@echo "--- Data VisualiZation ---"
	psql $(pg_datalake_uri) -c "SELECT download.update_cloudControl_vizuri();"

first_makefile:
	@echo "--- Copying initial makefile in 'data/_pk*' directories   ---"
	# retorna todos os diretórios com o padrão '*_pk*' e copia o arquivo commomLast.mustache.mk para cada um deles, renomeando o arquivo para makefile.
	sed "s/^country *.*/country=INT/" maketemplates/commomLast.mustache.mk > maketemplates/commomLast.mustache.mk.tmp
	find ../data -type d -name '*_pk*' -exec cp maketemplates/commomLast.mustache.mk.tmp \{\}/makefile \;
	rm maketemplates/commomLast.mustache.mk.tmp

to_donated_packcomponent:
	@echo "--- DUMP ingest.donated_packcomponent to $(pg_io)/dump_component_$(pg_db).sql ---"
	pg_dump --column-inserts --data-only -t ingest.donated_packcomponent $(pg_db_uri) > $(pg_io)/dump_component_$(pg_db).sql
	@echo "--- Preparing $(pg_io)/dump_component_$(pg_db).sql ---"
	bash to_donated_packcomponent.bash $(pg_io)/dump_component_$(pg_db).sql
	@echo "--- INSERT $(pg_io)/dump_component_$(pg_db).sql INTO $(pg_datalake) optim.donated_PackComponent_not_approved ---"
	grep "INSERT INTO" $(pg_io)/dump_component_$(pg_db).sql | psql $(pg_datalake_uri)
	@echo "--- See optim.donated_PackComponent_not_approved in $(pg_datalake) ---"

approved_donated_packcomponent:
	@echo "Usage: make approved_donated_packcomponent id=<id from optim.donated_PackComponent_not_approved>"
	@read -p "[Press ENTER to continue or Ctrl+C to quit]" _press_enter_
	@[ "${id}" ] && psql $(pg_datalake_uri) -c "SELECT optim.approved_packcomponent($(id))" || ( echo "Unknown id.")

sha256_update:
	@echo "Update sha256 in optim.donated_packfilevers"
	@echo "Old sha256: $(oldsha256)"
	@echo "New sha256: $(newsha256)"
	@echo "id: $(id)"
	@echo "pg_datalake: $(pg_datalake)"
	@echo "Usage: make sha256_update pg_datalake=<datalake with optim schema> id=<id from optim.donated_packfilevers> oldsha256=<sha256 that will be changed> newsha256=<sha256 that will replace oldsha256>"
	@read -p "[Press ENTER to continue or Ctrl+C to quit]" _press_enter_
	psql $(pg_datalake_uri) -c "UPDATE optim.donated_packfilevers SET hashedfname = '$(newsha256)' WHERE id = $(id) AND hashedfname = '$(oldsha256)';"

cmd_rdap:
	@echo "Generate list of commands to update or create rdap.json"
	@echo "for donor and donatedPack"
	@echo "Usage: make cmd_rdap iso=<ISO 3166 country code> pg_datalake=<database>"
	@read -p "[Press ENTER to continue or Ctrl+C to quit]" _press_enter_
	@[ "${iso}" ] && psql $(pg_datalake_uri) -c "SELECT commandline_rdap FROM optim.vw01donorEvidenceCMD WHERE iso=upper('$(iso)')" || ( echo "Unknown iso code.")

report:
	@echo "Relatorios"
	@echo "Uso make report pg_datalake=dl05s_main "
	@echo "Doc: https://github.com/digital-guard/preserv/blob/main/docs/pt/man-diversos.md#relat%C3%B3rios"
# 	@echo "View optim.vw01report:"
# 	psql $(pg_datalake_uri) -c "SELECT * FROM optim.vw01report;"
# 	@echo "View optim.vw02report_simple:"
# 	psql $(pg_datalake_uri) -c "SELECT * FROM optim.vw02report_simple;"
	@echo "View vw01report_median:"
	psql $(pg_datalake_uri) -c "SELECT * FROM optim.vw01report_median;"

build_fdwtable: # fdwOrigBase=name fdwOrigSchema=name fdwOrigName=name fdwName=name
	@echo "DROP FOREIGN TABLE IF EXISTS $(fdwName);"
	@echo "CREATE FOREIGN TABLE $(fdwName) ("
	@psql $(pg_uri_root)/$(fdwOrigBase) -c "\d $(fdwOrigSchema).$(fdwOrigName)" |  awk '/^ [a-z]/ {print $$1,$$3 ",";}'
	@echo ") SERVER foreign_server"
	@echo "  OPTIONS (schema_name '$(fdwOrigSchema)', table_name '$(fdwOrigName)');"
	@echo

get_wikidata_points:
	@echo "Get points wikidata: BR and CO."
	curl -o /tmp/wikidata_coord.csv -G 'https://query.wikidata.org/sparql' \
	--header "Accept: text/csv"  \
	--data-urlencode query='PREFIX schema: <http://schema.org/> SELECT ?wikidata ?local_id ?osm_id ?geom ?wikidataLabel WHERE {{?wikidata wdt:P31 wd:Q3184121.} UNION {?wikidata wdt:P31 wd:Q2555896.} OPTIONAL { ?wikidata wdt:P402 ?osm_id. } OPTIONAL { ?wikidata wdt:P1585 ?local_id. } OPTIONAL { ?wikidata wdt:P7325 ?local_id. } OPTIONAL { ?wikidata wdt:P625 ?geom. } SERVICE wikibase:label { bd:serviceParam wikibase:language "es,pt-br". } } ORDER BY ?local_id'

## ## ## ##
## -- REPORT tools --

countpacks: $(gits_basepath)/_dg
	echo "---- Counting lines of $(gits_basepath)/_dg/$(pkdir) ----"
	echo "* sha256sum.txt files:"
	find $(gits_basepath)/_dg/$(pkdir) -name "sha256sum.txt" | wc -l
	echo "* _pk* directories:"
	(cd $(gits_basepath)/_dg/$(pkdir); find . -type d  -wholename "./*/*/*/_pk*" | wc -l)
	echo "* README.md files:"
	find $(gits_basepath)/_dg/$(pkdir) -name "README.md" | wc -l
	echo "* make_conf files:"
	find $(gits_basepath)/_dg/$(pkdir) -name "make_conf.*" | wc -l

status: status_base status_disk_abuse

status_base:
	psql $(pg_uri_root) -c "\l+"

status_schEtc:
	@echo "-- database ingest1:"
	psql $(pg_uri_root)/ingest1    -c "\dn"
	@echo "-- OSM testing database DL01t_osm:"
	psql $(pg_uri_root)/dl01t_osm  -c "\dn"
	@echo "-- MAIN testing database DL03t_main:"
	psql $(pg_uri_root)/dl05s_main -c "\dn"

status_schProd:
	@echo "-- -- -- ON-PRODUCTION SCHEMAS -- -- --"
	@echo "-- OSM stable database DL02s_osm:"
	psql $(pg_uri_root)/dl02s_osm  -c "\dn"
	@echo "-- MAIN stable database DL04s_main:"
	psql $(pg_uri_root)/dl04s_main -c "\dn"

status_disk_abuse:
	echo "-- -- -- CHECK disk usage ABUSE -- -- --"
	(du -h $(gits_basepath)  | grep -v "^[0-9][0-9,\.]*[KM]") || true
	# (du -h /var/www | grep -v "^[0-9][0-9,\.]*[KM]") || true
	(du -h $(pg_io)     | grep -v "^[0-9][0-9,\.]*[KM]") || true
	echo "... if no line, it is ok!"


## ## ## ##
## ECLUSA, commands to execute by root at crontab:

ecl_run: pgio $(lockpath)/digitalPreservation-makeSQL.~feito
	whoami
	pwd
	@echo "Run with sudo! (idempotent)"
	sudo bash fixaPermissoes.sh $(pg_io)
	# make -C /var/gits/WS/src ini_tmprefresh
	psql $(pg_uri) -c "SELECT optim.fdw_wgets_script('refresh')"
	sh $(pg_io)/run_wgets-refresh.sh
	psql $(pg_uri) -c "SELECT optim.fdw_wgets_refresh(false)" # (donor e donatedpack) true on master
	sh /var/gits/digital-preservartion/src/eclusa/mkCpHashFiles.sh
	psql $(pg_uri) -c "SELECT * FROM eclusa.vw03alldft_cityfolder_ins" # insert into origin

ecl_out: pgio ecl_run
	psql $(pg_uri) -c "COPY (SELECT * FROM optim.vwdump_origin) TO '$$(pg_io)/br-origin.csv' CSV HEADER"
	# tem API nao precisa disso?

# core inserts
ini_ins: pgio
	@echo "run SQL spcripts:"
	psql $(pg_uri) -c "SELECT optim.fdw_wgets_script()"
	sh $(pg_io)/run_wgets-all.sh
  # falta rodar resto


## testing ... correct is to wget
ins_step1: pgio # LIXO
	mkdir -p $(pg_io)/digital-preservartion-XX
	rm -f $(pg_io)/digital-preservartion-XX/*.csv
	for gitdir in /var/gits/digital-preservartion-*; do \
	   echo "Refreshing $$gitdir and copying its CSVs..."; \
	   git -C "$$gitdir" pull; \
	   cp "$$gitdir/data/"*.csv $(pg_io)/digital-preservartion-XX; \
	done


## ## ## ##
## LIXO? commands to execute by root at crontab:

# Tests "load and check" of first-level local jurisdictions, maintained by Wikidata and OSM:
jurisdiction_iso_prepare:  # depends on prepared databases
	@echo "--- Jurisdiction prepare ingestion database ---"
	psql $(pg_uringest) -c "CREATE SCHEMA IF NOT EXISTS optim; DROP TABLE optim.jurisdiction;"
	pg_dump --format plain --table optim.jurisdiction $(pg_uri)  | psql $(pg_uringest)

jurisdiction_iso_run: pgio jurisdiction_iso_prepare jurisdiction/get.sh jurisdiction/get.sql run_mustache.py jurisdiction/getWikidata.mustache
	@echo "--- Jurisdiction prepare bash file and LOAD ---"
	sh jurisdiction/get.sh
	ls -l /tmp/pg_io/wdquery-*.csv
	psql $(pg_uringest) < jurisdiction/get.sql

# edit SQL and run:
jurisdiction_iso_run2: pgio get-Latam5.sql get-Latam5.sh run_mustache.py getWikidata.mustache
	@echo "--- Jurisdiction prepare2 bash file and LOAD ---"
	sh jurisdiction/get.sh
	ls -l /tmp/pg_io/wdquery-*.csv
	psql $(pg_uringest) < jurisdiction/get.sql

jurisdiction_iso_test:
	psql $(pg_uringest) -c "\
	WITH RECURSIVE rec_ids AS (\
	   SELECT osm_id FROM optim.jurisdiction\
	     WHERE admin_level=2 AND abbrev IN ($(countries))\
	   UNION ALL\
	   SELECT sa.osm_id\
	    FROM optim.jurisdiction AS sa\
	    JOIN rec_ids ON rec_ids.osm_id = sa. parent_id\
	)\
	 SELECT isolabel_ext,  osm_id, abbrev, name, name_en, parent_id, lexlabel, wikidata_id, jurisd_base_id, jurisd_local_id, admin_level\
	 FROM optim.jurisdiction\
	 WHERE osm_id IN (SELECT osm_id FROM rec_ids) order by 1\
	"

## ## ## ##
## -- ADMIN FIX TOOLS --
fix_permissions: pgio sdbox
	@echo "... Fixing standard permissions, as sudor:"
	sudo bash fixaPermissoes.sh $(gits_basepath) $(pg_io) /var/www $(sbx_path)

fix_usergroup:
	@echo "... Adding standard usergroups, as sudor:"
ifeq ($(username),)
	@echo "Target error: please say username"
else
	@echo "... Addding to $(username):"
	sudo usermod -a -G postgres $(username)
	sudo usermod -a -G www-data $(username)
endif

## ## ## ##
## -- AUXILIAR TARGETS, snippet code for reuse --
pgio:
	mkdir -p $(pg_io)
sdbox:
	mkdir -p $(sbx_path)
lck:
	mkdir -p $(lockpath)
