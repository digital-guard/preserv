##
## Installing Project Digital Preservation
##

## -- -- VARS -- --

pg_io       := /tmp/pg_io
lockpath    := /var/gits/_lock-mkStatus

pg_uri_root := postgres://postgres@localhost

## danger dl03t_main, ingest1. Use dummy 99 to test.
pg_db       := dl99t_main
pg_dbingest := ingest99

pg_uri      := $(pg_uri_root)/$(pg_db)
pg_uringest := $(pg_uri_root)/$(pg_dbingest)

countries   := "'BR','CL','CO','EC','PE','VE'"  # em uso e conforme data/jurisdiction.csv

gits_basepath := /var/gits
pk_basepath   := $(gits_basepath)/_dg

## not working!
DB_TEST  := $(shell psql $(pg_uri_root) -c "\l" | awk '/$(pg_dbingest)/ {n=(n>0)?3:1} /$(pg_db)/ {n=(n>0)?3:2} END {print n;}')
DB_TEST2 := $(shell echo '/$(pg_dbingest)/ {n=(n>0)?3:1} /$(pg_db)/ {n=(n>0)?3:2} END {print n;}')

## -- CONFIGS --
.SILENT: message countpacks status_disk_abuse

## ## ## ## ##
## -- HELP --
message:
	echo "--------  make of the Preserv project ----------"
	echo
	echo " -- SQL BUILDERs --"
	echo " ini_all: configure and prepare all basic databases and schemas"
	echo " ini_sql_db: ..."
	echo
	echo " -- REPORT tools --"
	echo " countpacks [pkdir=v]: count package-evidence files ok pkdir (e.g. preserv-BR) or its root"
	echo " status: of databases and disk usage"
	echo
	echo " -- ADMIN tools --"
	echo " fix_usergroup username=v: add standard groups to username"
	echo " fix_permissions: execute chmod and chown in the standard folders"
	echo

## ## ## ## ##
## -- -- SQL BUILDERs -- --

all: ini_all

ini_all: ini_sql_db ini_sql

ini_sql_db:
	psql $(pg_uri_root) -c "CREATE DATABASE $(pg_dbingest)"
	psql $(pg_uri_root) -c "CREATE DATABASE $(pg_db)"

ini_sql_db_BUG:
	@echo "... Checking databases "
	@echo " debug $(DB_TEST), test2=$(DB_TEST2)"
	exit
ifneq ($(DB_TEST),$(filter $(DB_TEST),1 3))
	@echo "... Creating database $(pg_dbingest)"
	psql $(pg_uri_root) -c "CREATE DATABASE $(pg_dbingest)"
endif
ifneq ($(DB_TEST),$(filter $(DB_TEST),3 2))
	@echo "... Creating database $(pg_db)"
	psql $(pg_uri_root) -c "CREATE DATABASE $(pg_db)"
endif
	@echo "Databases $(pg_db) and $(pg_dbingest) created."


ini_sql: pgio lck $(gits_basepath)/_a4a/pg_pubLib-v1/src/makefile
	@echo "--- Preparing filesystem... ---"
	rm -f $(lockpath)/digitalPreservation-makeSQL.~feito
	@echo "--- Preparing databses... ---"
	@echo "--- Running SQL pubLib ---"
	cd $(gits_basepath)/_a4a/pg_pubLib-v1/src; make all pg_db=$(pg_db)
	cd $(gits_basepath)/_a4a/pg_pubLib-v1/src; make all pg_db=$(pg_dbingest)
	@echo "--- Running Ingest ---"
	psql $(pg_uringest) < $(gits_basepath)/_dg/preserv/src/lib-dg_preserv.sql
	psql $(pg_uringest) < $(gits_basepath)/_dg/preserv/src/ingest-step1-ini.sql
	psql $(pg_uringest) < $(gits_basepath)/_dg/preserv/src/ingest-step2-ini-make.sql
	@echo "Creating optim schema at $(pg_db) database"
	psql $(pg_uri) < $(gits_basepath)/_dg/preserv/src/optim-step1-ini.sql
	@echo "--- Running API SQL templates ---"
	@echo "!nao fazendo ainda, futuro"
	#psql $(pg_uri) < step00-iniApi.sql
	@echo "--- Running Eclusa ---"
	@echo "!nao fazendo ainda, futuro"
	#psql $(pg_uri) < eclusa/step1-ini.sql
	# sh eclusa-step2a-ins.sh
	#/var/gits/WS/src? psql $(pg_uri) < eclusa/step2b-ins.sql
	touch $(lockpath)/digitalPreservation-makeSQL.~feito
	chmod 666 $(lockpath)/digitalPreservation-makeSQL.~feito


build_fdwtable: # fdwOrigBase=name fdwOrigSchema=name fdwOrigName=name fdwnName=name
	@echo "DROP FOREIGN TABLE IF EXISTS $(fdwName);"
	@echo "CREATE FOREIGN TABLE $(fdwName) ("
	@psql postgres://postgres@localhost/$(fdwOrigBase) -c "\d $(fdwOrigSchema).$(fdwOrigName)" |  awk '/^ [a-z]/ {print $$1,$$3 ",";}'
	@echo ") SERVER foreign_server"
	@echo "  OPTIONS (schema_name '$(fdwOrigSchema)', table_name '$(fdwOrigName)');"
	@echo


## ## ## ## ##
## -- -- REPORT tools -- --

countpacks: $(pk_basepath)
	echo "---- Counting lines of $(pk_basepath)/$(pkdir) ----"
	echo "* sha256sum.txt files:"
	find $(pk_basepath)/$(pkdir) -name "sha256sum.txt" | wc -l
	echo "* _pk* directories:"
	(cd $(pk_basepath)/$(pkdir); find . -type d  -wholename "./*/*/*/_pk*" | wc -l)
	echo "* README.md files:"
	find $(pk_basepath)/$(pkdir) -name "README.md" | wc -l
	echo "* make_conf files:"
	find $(pk_basepath)/$(pkdir) -name "make_conf.*" | wc -l

status: status_base status_disk_abuse

status_base:
	psql $(pg_uri_root) -c "\l+"

status_schEtc:
	@echo "-- database ingest1:"
	psql $(pg_uri)/ingest1    -c "\dn"
	@echo "-- OSM testing database DL01t_osm:"
	psql $(pg_uri)/dl01t_osm  -c "\dn"
	@echo "-- MAIN testing database DL03t_main:"
	psql $(pg_uri)/dl03t_main -c "\dn"

status_schProd:
	@echo "-- -- -- ON-PRODUCTION SCHEMAS -- -- --"
	@echo "-- OSM stable database DL02s_osm:"
	psql $(pg_uri)/dl02s_osm  -c "\dn"
	@echo "-- MAIN stable database DL04s_main:"
	psql $(pg_uri)/dl04s_main -c "\dn"

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

##############
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

redirects_update: pgio
	@echo "-- Atualiza redirecionamentos --"
	@echo Download da tabela de-para ....
	wget "https://docs.google.com/spreadsheets/d/1CL6f0I9DSpqKxKC7QNJGCfyabq7mDOVab5QBGV5VLOk/gviz/tq?tqx=out:csv&sheet={de-para}" -O "$(pg_io)/de-para.csv"
	psql $(pg_uri) -c "DELETE FROM download.redirects; COPY download.redirects FROM '$(pg_io)/de-para.csv' CSV HEADER;"

makefile_pk_first:
	@echo "------------------------------------------------------"
	@echo "Iniciada cópia de makefile inicial nos diretórios '_pk*' de data."
	# retorna todos os diretórios com o padrão '*_pk*' e copia o arquivo commomLast.mustache.mk para cada um deles, renomeando o arquivo para makefile.
	sed "s/^country *.*/country=INT/" maketemplates/commomLast.mustache.mk > maketemplates/commomLast.mustache.mk.tmp
	find ../data -type d -name '*_pk*' -exec cp maketemplates/commomLast.mustache.mk.tmp \{\}/makefile \;
	rm maketemplates/commomLast.mustache.mk.tmp
	@echo "Finalizada a cópia "
	@echo "------------------------------------------------------"

codec_type_prepare:
	@echo "--- codec_type load ---"
	psql $(pg_uringest) -c "SELECT ingest.load_codec_type('$(gits_basepath)/_dg/preserv/data/codec_type.csv',',');"

load_license_tables: pgio
	@echo "-- Carrega tabelas --"
# 	wget "https://raw.githubusercontent.com/ppKrauss/licenses/master/data/families.csv" -O "$(pg_io)/families.csv"
	wget "https://raw.githubusercontent.com/ppKrauss/licenses/master/data/licenses.csv" -O "$(pg_io)/licenses.csv"
	wget "https://raw.githubusercontent.com/ppKrauss/licenses/master/data/implieds.csv" -O "$(pg_io)/implieds.csv"
	wget "https://raw.githubusercontent.com/digital-guard/preserv-BR/main/data/donatedPack.csv" -O "$(pg_io)/donatedPack.csv"
	wget "https://raw.githubusercontent.com/digital-guard/preserv-BR/main/data/donatedPack-old2new.csv" -O "$(pg_io)/donatedPack-old2new.csv"

	psql $(pg_uringest) -c "SELECT ingest.fdw_generate_direct_csv('$(pg_io)/licenses.csv','tmp_licenses'); SELECT ingest.fdw_generate_direct_csv('$(pg_io)/implieds.csv','tmp_implieds'); SELECT ingest.fdw_generate_direct_csv('$(pg_io)/donatedPack.csv','tmp_donatedPack'); SELECT ingest.fdw_generate_direct_csv('/tmp/pg_io/donatedPackold2new.csv','tmp_donatedPackold2new'); \
	DROP TABLE IF EXISTS tmp_pack_licenses; CREATE TABLE tmp_pack_licenses AS SELECT d.pack_id, t.old_pack_id, l.* FROM tmp_donatedPack AS d \
	LEFT JOIN (\
	SELECT id_label, name, family, url, 'yes' AS license_is_explicit FROM tmp_licenses \
	UNION \
	SELECT id_label, name, family, url_report AS url, 'no' AS license_is_explicit FROM tmp_implieds) AS l \
	ON lower(d.license) = l.id_label AND d.license_is_explicit = l.license_is_explicit \
	LEFT JOIN tmp_donatedPackold2new AS t \
	ON d.pack_id = t.pack_id;\
	DROP FOREIGN TABLE IF EXISTS tmp_licenses; DROP FOREIGN TABLE IF EXISTS tmp_implieds; DROP FOREIGN TABLE IF EXISTS tmp_donatedPack; DROP FOREIGN TABLE IF EXISTS tmp_donatedPackold2new;"

idnew_test:
	psql $(pg_uri) -c "DROP TABLE optim.jurisdiction ;"
	pg_dump -t optim.jurisdiction $(pg_uri_root)/dl02s_main | psql $(pg_uri)
	psql $(pg_uri) -c "select optim.load_donor_pack('br');"
	psql $(pg_uri) -c "select optim.insert_donor_pack();"

## ## ## ##
## -- ADMIN FIX TOOLS --
fix_permissions: pgio
	@echo "... Fixing standard permissions, as sudor:"
	sudo bash fixaPermissoes.sh /var/gits /tmp/pg_io /var/www

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
## AUXILIAR TARGETS, snippet code for reuse
pgio:
	mkdir -p $(pg_io)
lck:
	mkdir -p $(lockpath)
