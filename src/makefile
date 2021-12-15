##
## Installing Project Digital Preservation
##

## -- -- VARS -- --

pg_io  =/tmp/pg_io

pg_uri_root =postgres://postgres@localhost
pg_db       =dl03t_main
pg_dbingest =ingest1
pg_uri      =$(pg_uri_root)/$(pg_db)
pg_uringest =$(pg_uri_root)/$(pg_dbingest)

countries = "'BR','CL','CO','EC','PE','VE'"  # em uso e conforme data/jurisdiction.csv

gits_basepath = /var/gits

DB_TEST := $(shell psql $(pg_uri_root) -c "\l" | awk '/$(pg_dbingest)/ {n=(n>0)?3:1} /$(pg_db)/ {n=(n>0)?3:2} END {print n;}')
DB_TEST2 := $(shell echo '/$(pg_dbingest)/ {n=(n>0)?3:1} /$(pg_db)/ {n=(n>0)?3:2} END {print n;}')

## -- -- RULES -- --

all:
	@echo "--------  make do projeto Preserv  ----------"
	@echo "Use primeiro   sudo make permissions"
	@echo "Use depois     make ini_all"
	@echo "!Importante para users deste projeto:"
	@echo "   sudo usermod -a -G postgres masterUser"
	@echo "   sudo usermod -a -G www-data masterUser"

ini_all: ini_sql_db ini_sql

ini_sql_db:
	@echo "... Verificando bancos de dados"
ifneq ($(DB_TEST),$(filter $(DB_TEST),1 3))
	@echo "... Criando banco $(pg_dbingest)"
	psql $(pg_uri_root) -c "CREATE DATABASE $(pg_dbingest)"
endif
ifneq ($(DB_TEST),$(filter $(DB_TEST),3 2))
	@echo "... Criando banco $(pg_db)"
	psql $(pg_uri_root) -c "CREATE DATABASE $(pg_db)"
endif
	@echo "Bases $(pg_db) e $(pg_dbingest) criadas."

ini_sql: $(gits_basepath)/_a4a/pg_pubLib-v1/src/makefile
	@echo "--- Preparing filesystem... ---"
	rm -f /opt/lock-mkStatus/digitalPreservation-makeSQL.~feito
	mkdir -p $(pg_io)
	@echo "--- Preparing databses... ---"
	@echo "--- Running SQL pubLib ---"
	cd $(gits_basepath)/_a4a/pg_pubLib-v1/src; make all pg_db=$(pg_db)
	cd $(gits_basepath)/_a4a/pg_pubLib-v1/src; make all pg_db=$(pg_dbingest)
	@echo "--- Running Ingest ---"
	psql $(pg_uringest) < $(gits_basepath)/_dg/preserv/src/digpreserv.sql
	psql $(pg_uringest) < $(gits_basepath)/_dg/preserv/src/ingest-step1-ini.sql
	psql $(pg_uringest) < $(gits_basepath)/_dg/preserv/src/ini.sql
	@echo "--- Running API SQL templates ---"
	psql $(pg_uri) < step00-iniApi.sql
	@echo "--- Running Eclusa ---"
	psql $(pg_uri) < eclusa/step1-ini.sql
	# sh eclusa-step2a-ins.sh
	#/var/gits/WS/src? psql $(pg_uri) < eclusa/step2b-ins.sql
	touch /opt/lock-mkStatus/digitalPreservation-makeSQL.~feito

## GENERAL CHECKs:

countpacks: $(pkdir)
	@echo "---- Counting lines of $(dir) ----"
	@echo "* sha256sum.txt files:"
	@find $(pkdir) -name "sha256sum.txt" | wc -l
	@echo "* _pk* directories:"
	@(cd $(pkdir); find . -type d  -wholename "./*/*/*/_pk*" | wc -l)
	@echo "* README.md files:"
	@find $(pkdir) -name "README.md" | wc -l
	@echo "* make_conf files:"
	@find $(pkdir) -name "make_conf.*" | wc -l
	
	
## ECLUSA, commands to execute by root at crontab:

ecl_run: /opt/lock-mkStatus/digitalPreservation-makeSQL.~feito
	whoami
	pwd
	@echo "Run with sudo! (idempotent)"
	mkdir -p $(pg_io)
	chown postgres:postgres -R $(pg_io)
	# make -C /var/gits/WS/src ini_tmprefresh
	psql $(pg_uri) -c "SELECT optim.fdw_wgets_script('refresh')"
	sh $(pg_io)/run_wgets-refresh.sh
	psql $(pg_uri) -c "SELECT optim.fdw_wgets_refresh(false)" # (donor e donatedpack) true on master
	sh /var/gits/digital-preservartion/src/eclusa/mkCpHashFiles.sh
	psql $(pg_uri) -c "SELECT * FROM eclusa.vw03alldft_cityfolder_ins" # insert into origin

ecl_out: ecl_run
	# testar se $$(pg_io) funciona
	psql $(pg_uri) -c "COPY (SELECT * FROM optim.vwdump_origin) TO '$$(pg_io)/br-origin.csv' CSV HEADER"
	# tem API nao precisa disso?

# core inserts
ini_ins:
	@echo "run SQL spcripts"
	mkdir -p $(pg_io)
	psql $(pg_uri) -c "SELECT optim.fdw_wgets_script()"
	sh $(pg_io)/run_wgets-all.sh
  # falta rodar resto


## testing ... correct is to wget
ins_step1: # LIXO
	mkdir -p $(pg_io)/digital-preservartion-XX
	rm -f $(pg_io)/digital-preservartion-XX/*.csv
	for gitdir in /var/gits/digital-preservartion-*; do \
	   echo "Refreshing $$gitdir and copying its CSVs..."; \
	   git -C "$$gitdir" pull; \
	   cp "$$gitdir/data/"*.csv $(pg_io)/digital-preservartion-XX; \
	done

##############

# Tests "load and check" of first-level local jurisdictions, maintained by Wikidata and OSM:
jurisdiction_iso_prepare:  # depends on prepared databases
	@echo "--- Jurisdiction prepare ingestion database ---"
	psql $(pg_uringest) -c "CREATE SCHEMA IF NOT EXISTS optim; DROP TABLE optim.jurisdiction;"
	pg_dump --format plain --table optim.jurisdiction $(pg_uri)  | psql $(pg_uringest)

jurisdiction_iso_run: jurisdiction_iso_prepare jurisdiction/get.sh jurisdiction/get.sql run_mustache.py jurisdiction/getWikidata.mustache
	@echo "--- Jurisdiction prepare bash file and LOAD ---"
	sh jurisdiction/get.sh
	ls -l /tmp/pg_io/wdquery-*.csv
	psql $(pg_uringest) < jurisdiction/get.sql

# edit SQL and run:
jurisdiction_iso_run2:  get-Latam5.sql get-Latam5.sh run_mustache.py getWikidata.mustache
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

redirects_update:
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
