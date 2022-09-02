
## ############################ ##
## SELF-GENERATE MAKE (make me) ##
## ############################ ##

mkme_input    = $(shell ls -d "${PWD}/"make_conf.yaml)
country       = $(shell ls -d "${PWD}" | cut -d'-' -f2 | cut -d'/' -f1)
baseSrc       = /var/gits/_dg
baseSrcPack   = $(shell ls -d "${PWD}")

mkme_input0   = $(baseSrc)/preserv-$(country)/src/maketemplates/commomFirst.yaml

ifeq ($(shell ls -d "${PWD}" | grep "-"),)
country       = INT
mkme_input0   = $(baseSrc)/preserv/src/maketemplates/commomFirst.yaml
endif

pg_io         = $(shell grep 'pg_io'   < $(mkme_input0) | cut -f2  -d':' | sed 's/^[ \t]*//' | sed 's/[\ \#].*//')
pg_uri        = $(shell grep 'pg_uri'  < $(mkme_input0) | cut -f2- -d':' | sed 's/^[ \t]*//' | sed 's/[\ \#].*//')
pg_db         = $(shell grep 'pg_db'   < $(mkme_input0) | cut -f2  -d':' | sed 's/^[ \t]*//' | sed 's/[\ \#].*//')
orig          = $(shell grep 'orig'    < $(mkme_input0) | cut -f2  -d':' | sed 's/^[ \t]*//' | sed 's/[\ \#].*//')
pack_id       = $(shell grep 'pack_id' < $(mkme_input)  | cut -f2  -d':' | sed 's/^[ \t]*//' | sed 's/[\ \#].*//')

pg_uri_db     = $(pg_uri)/$(pg_db)

mkme_output   = $(pg_io)/makeme_$(country)$(pack_id)
readme_output = $(pg_io)/README_$(country)$(pack_id)
conf_output   = $(pg_io)/make_conf_$(country)$(pack_id)

info:
	@echo "=== Targets ==="
	@printf "info: resumo dos targets.\n"
	@printf "me: gera makefile para ingestão de make_conf.yaml.\n"
	@printf "readme: gera README.md do pacote de dados.\n"
	@printf "insert_size: insere size bytes em files de make_conf.yaml.\n"
	@printf "insert_license: insere detalhes sobre licenças em make_conf.yaml.\n"
	@printf "delete_file: deleta layer ingestado.\n"

me:
	@echo "-- Generating makefile --"
	psql $(pg_uri_db) -c "SELECT ingest.generate_makefile('$(country)','$(pack_id)','$(baseSrcPack)','$(baseSrc)');"
	sudo chmod 777 $(mkme_output)
	@echo " Check diff, the '<' lines are the new ones. Something changed?"
	@diff $(mkme_output) ./makefile || :
	@echo "If some changes, and no error in the changes, move the script:"
	@echo " mv $(mkme_output) ./makefile"
ifneq ($(nointeraction),y)
	@read -p "[Press ENTER to continue or Ctrl+C to quit]" _press_enter_
endif
	mv $(mkme_output) ./makefile

readme:
	@echo "-- Generating README.md --"
	psql $(pg_uri_db) -c "SELECT ingest.generate_readme('$(country)','$(pack_id)','$(baseSrcPack)','$(baseSrc)');"
	sudo chmod 777 $(readme_output)
	@echo " Check diff, the '<' lines are the new ones. Something changed?"
	@diff $(readme_output) ./README.md || :
	@echo "If some changes, and no error in the changes, move the readme:"
	@echo " mv $(readme_output) ./README.md"
ifneq ($(nointeraction),y)
	@read -p "[Press ENTER to continue or Ctrl+C to quit]" _press_enter_
endif
	mv $(readme_output) ./README.md

insert_size:
	@echo "-- Inserting size in files of make_conf --"
	psql $(pg_uri_db) -c "SELECT ingest.generate_make_conf_with_size('$(country)','$(pack_id)','$(baseSrcPack)','$(baseSrc)','$(orig)');"
	sudo chmod 777 $(conf_output)
	@echo " Check diff, the '<' lines are the new ones. Something changed?"
	@diff $(conf_output) ./make_conf.yaml || :
	@echo "If some changes, and no error in the changes, move the script:"
	@echo " mv $(conf_output) ./make_conf.yaml"
ifneq ($(nointeraction),y)
	@read -p "[Press ENTER to continue or Ctrl+C to quit]" _press_enter_
endif
	mv $(conf_output) ./make_conf.yaml

insert_license:
	@echo "-- Inserting files_licenses in make_conf --"
	psql $(pg_uri_db) -c "SELECT ingest.generate_make_conf_with_license('$(country)','$(pack_id)','$(baseSrcPack)','$(baseSrc)');"
	sudo chmod 777 $(conf_output)
	@echo " Check diff, the '<' lines are the new ones. Something changed?"
	@diff $(conf_output) ./make_conf.yaml || :
	@echo "If some changes, and no error in the changes, move the script:"
	@echo " mv $(conf_output) ./make_conf.yaml"
ifneq ($(nointeraction),y)
	@read -p "[Press ENTER to continue or Ctrl+C to quit]" _press_enter_
endif
	mv $(conf_output) ./make_conf.yaml

delete_file:
	@echo "-- Deleting donated donated packcomponent --"
	@echo "Usage: make delete_file id=<id de donated_packcomponent>"
	@echo "id: $(id)"
	@read -p "[Press ENTER to continue or Ctrl+C to quit]" _press_enter_
	@[ "${id}" ] && psql $(pg_uri_db) -c "DELETE FROM ingest.donated_packcomponent WHERE id = $(id)" || ( echo "Unknown id.")
