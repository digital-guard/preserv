
## ############################ ##
## SELF-GENERATE MAKE (make me) ##
## ############################ ##

mkme_input    = $(shell ls -d "${PWD}/"make_conf.yaml)
country       = $(shell ls -d "${PWD}" | cut -d'-' -f2 | cut -d'/' -f1)
baseSrc       = /var/gits/_dg
baseSrcPack   = $(shell ls -d "${PWD}")
preservSrc    = $(baseSrc)/preserv/src

mkme_input0   = $(baseSrc)/preserv-$(country)/src/maketemplates/commomFirst.yaml

ifeq ($(shell ls -d "${PWD}" | grep "-"),)
country       = INT
mkme_input0   = $(preservSrc)/maketemplates/commomFirst.yaml
endif

pg_io         = $(shell grep 'pg_io'   < $(mkme_input0) | cut -f2  -d':' | sed 's/^[ \t]*//' | sed 's/[\ \#].*//')
pg_uri        = $(shell grep 'pg_uri'  < $(mkme_input0) | cut -f2- -d':' | sed 's/^[ \t]*//' | sed 's/[\ \#].*//')
pg_db         = $(shell grep 'pg_db'   < $(mkme_input0) | cut -f2  -d':' | sed 's/^[ \t]*//' | sed 's/[\ \#].*//')
orig          = $(shell grep 'orig'    < $(mkme_input0) | cut -f2  -d':' | sed 's/^[ \t]*//' | sed 's/[\ \#].*//')
pack_id       = $(shell grep 'pack_id' < $(mkme_input)  | cut -f2  -d':' | sed 's/^[ \t]*//' | sed 's/[\ \#].*//')

pg_uri_db     = $(pg_uri)/$(pg_db)

tmpfile       = $(pg_io)/tmpfile_$(country)$(pack_id)

info:
	@echo "=== Targets ==="
	@printf "info: resumo dos targets.\n"
	@printf "me: gera makefile para ingestão de make_conf.yaml.\n"
	@printf "readme: gera README.md do pacote de dados.\n"
	@printf "insert_size: insere size bytes em files de make_conf.yaml.\n"
	@printf "insert_license: insere detalhes sobre licenças em make_conf.yaml.\n"
	@printf "delete_file: deleta layer ingestado. Uso: make delete_file id=<id do layer em ingest.donated_PackComponent>\n"
	@printf "generate_csvfile: gera CSV do layer (SOMENTE para geoaddress). Uso: make generate_csvfile id=<id do layer em ingest.donated_PackComponent> pg_db=<ingest>.\n"
	@printf "generate_shapefile: gera SHAPEFILE do layer. Uso: make generate_shapefile id=<id do layer em ingest.donated_PackComponent> pg_db=<ingest>. \n"

me:
	@echo "-- Generating makefile --"
	cd $(preservSrc); make generate_makefile country=$(country) pack_id=$(pack_id) baseSrcPack=$(baseSrcPack) baseSrc=$(baseSrc) output=$(tmpfile)
	sudo chmod 777 $(tmpfile)
	@echo " Check diff, the '<' lines are the new ones. Something changed?"
	@diff $(tmpfile) ./makefile || :
	@echo "If some changes, and no error in the changes, move the script:"
	@echo " mv $(tmpfile) ./makefile"
ifneq ($(nointeraction),y)
	@read -p "[Press ENTER to continue or Ctrl+C to quit]" _press_enter_
endif
	mv $(tmpfile) ./makefile

readme:
	@echo "-- Generating README.md --"
	cd $(preservSrc); make generate_readme country=$(country) pack_id=$(pack_id) baseSrcPack=$(baseSrcPack) baseSrc=$(baseSrc) output=$(tmpfile)
	sudo chmod 777 $(tmpfile)
	@echo " Check diff, the '<' lines are the new ones. Something changed?"
	@diff $(tmpfile) ./README.md || :
	@echo "If some changes, and no error in the changes, move the readme:"
	@echo " mv $(tmpfile) ./README.md"
ifneq ($(nointeraction),y)
	@read -p "[Press ENTER to continue or Ctrl+C to quit]" _press_enter_
endif
	mv $(tmpfile) ./README.md

insert_size:
	@echo "-- Inserting size in files of make_conf --"
	cd $(preservSrc); make insert_size country=$(country) pack_id=$(pack_id) baseSrcPack=$(baseSrcPack) baseSrc=$(baseSrc) output=$(tmpfile) orig=$(orig)
	sudo chmod 777 $(tmpfile)
	@echo " Check diff, the '<' lines are the new ones. Something changed?"
	@diff $(tmpfile) ./make_conf.yaml || :
	@echo "If some changes, and no error in the changes, move the script:"
	@echo " mv $(tmpfile) ./make_conf.yaml"
ifneq ($(nointeraction),y)
	@read -p "[Press ENTER to continue or Ctrl+C to quit]" _press_enter_
endif
	mv $(tmpfile) ./make_conf.yaml

insert_license:
	@echo "-- Inserting files_licenses in make_conf --"
	cd $(preservSrc); make insert_license country=$(country) pack_id=$(pack_id) baseSrcPack=$(baseSrcPack) baseSrc=$(baseSrc) output=$(tmpfile)
	sudo chmod 777 $(tmpfile)
	@echo " Check diff, the '<' lines are the new ones. Something changed?"
	@diff $(tmpfile) ./make_conf.yaml || :
	@echo "If some changes, and no error in the changes, move the script:"
	@echo " mv $(tmpfile) ./make_conf.yaml"
ifneq ($(nointeraction),y)
	@read -p "[Press ENTER to continue or Ctrl+C to quit]" _press_enter_
endif
	mv $(tmpfile) ./make_conf.yaml

delete_file:
	@echo "-- Deleting donated donated packcomponent --"
	@echo "Usage: make delete_file id=<id de donated_packcomponent>"
	@echo "id: $(id)"
	@read -p "[Press ENTER to continue or Ctrl+C to quit]" _press_enter_
	@[ "${id}" ] && psql $(pg_uri_db) -c "DELETE FROM ingest.donated_packcomponent WHERE id = $(id)" || ( echo "Unknown id.")

generate_csvfile:
	@echo "-- Generate feature_asis CSV files --"
	@echo "Usage: make generate_csvfile id=<id of ingest.donated_PackComponent> pg_db=<ingest>"
	@echo ""
	@echo "       CAUTION: ONLY for geoaddress!"
	@echo ""
	@read -p "[Press ENTER to continue or Ctrl+C to quit]" _press_enter_
	@[ "${id}" ] && bash -c "source $(preservSrc)/generateFiles.sh && gen_csv $(pg_db) $(id)" || ( echo "Unknown id.")

generate_shapefile:
	@echo "-- Generate feature_asis SHAPEFILE file --"
	@echo "Usage: make generate_shapefile id=<id of ingest.donated_PackComponent> pg_db=<ingest>"
	@echo "       Get id from ingest.donated_PackComponent table"
	@read -p "[Press ENTER to continue or Ctrl+C to quit]" _press_enter_
	@[ "${id}" ] && bash -c "source $(preservSrc)/generateFiles.sh && gen_shapefile $(pg_db) $(id)" || ( echo "Unknown id.")
