
## ############################ ##
## SELF-GENERATE MAKE (make me) ##
## ############################ ##

mkme_input    = $(shell ls -d "${PWD}/"make_conf.yaml)
country       = $(shell ls -d "${PWD}" | cut -d'-' -f2 | cut -d'/' -f1)
baseSrc       = /var/gits/_dg

mkme_input0   = $(baseSrc)/preserv-$(country)/src/maketemplates/commomFirst.yaml

ifeq ($(shell ls -d "${PWD}" | grep "-"),) # empty result from grep
country       = INT
mkme_input0   = $(baseSrc)/preserv/src/maketemplates/commomFirst.yaml
endif

pg_io         = $(shell grep 'pg_io'  < $(mkme_input0) | cut -f2  -d':' | sed 's/^[ \t]*//' | sed 's/[\ \#].*//')
pg_uri        = $(shell grep 'pg_uri' < $(mkme_input0) | cut -f2- -d':' | sed 's/^[ \t]*//' | sed 's/[\ \#].*//')
pg_db         = $(shell grep 'pg_db'  < $(mkme_input0) | cut -f2  -d':' | sed 's/^[ \t]*//' | sed 's/[\ \#].*//')
pkid          = $(shell grep 'pkid'   < $(mkme_input)  | cut -f2  -d':' | sed 's/^[ \t]*//' | sed 's/[\ \#].*//')

pg_uri_db     = $(pg_uri)/$(pg_db)

mkme_output   = $(pg_io)/makeme_$(country)$(pkid)
readme_output = $(pg_io)/README-draft_$(country)$(pkid)
conf_output   = $(pg_io)/make_conf_$(country)$(pkid)

info:
	@echo "=== Targets ==="
	@printf "me: gera makefile para ingestão dos dados, a partir de make_conf.yaml.\n"
	@printf "readme: gera rascunho de Readme.md para conjunto de dados.\n"
	@printf "insert_size: Insere tamanho em bytes em files no arquivo make_conf.yaml.\n"
	@printf "insert_license: Insere detalhes sobre licenças no arquivo make_conf.yaml.\n"
	@printf "insert_make_conf.yaml: carrega na base de dados o arquivo make_conf.yaml.\n"
	@printf "delete_file: deleta arquivo ingestado, a partir do sha256.\n"
	@printf "load_license_tables: carrega tabelas utilizadas pelo target insert_license.\n"

me: insert_make_conf.yaml
	@echo "-- Updating this make --"
	psql $(pg_uri_db) -c "SELECT ingest.lix_generate_makefile('$(country)','$(pkid)');"
	sudo chmod 777 $(mkme_output)
	@echo " Check diff, the '<' lines are the new ones... Something changed?"
	@diff $(mkme_output) ./makefile || :
	@echo "If some changes, and no error in the changes, move the script:"
	@echo " mv $(mkme_output) ./makefile"
	@echo "[ENTER para rodar mv ou ^C para sair]"
	@read _tudo_bem_
	mv $(mkme_output) ./makefile

readme:
	@echo "-- Create basic README-draft.md template --"
	psql $(pg_uri_db) -c "SELECT ingest.lix_generate_readme('$(country)','$(pkid)');"
	sudo chmod 777 $(readme_output)
	@echo " Check diff, the '<' lines are the new ones... Something changed?"
	@diff $(readme_output) ./README-draft.md || :
	@echo "If some changes, and no error in the changes, move the readme:"
	@echo " mv $(readme_output) ./README-draft.md"
	@echo "[ENTER para rodar mv ou ^C para sair]"
	@read _tudo_bem_
	mv $(readme_output) ./README-draft.md

insert_size: insert_make_conf.yaml
	@echo "-- Updating make_conf with files size --"
	psql $(pg_uri_db) -c "SELECT ingest.lix_generate_make_conf_with_size('$(country)','$(pkid)');"
	sudo chmod 777 $(conf_output)
	@echo " Check diff, the '<' lines are the new ones... Something changed?"
	@diff $(conf_output) ./make_conf.yaml || :
	@echo "If some changes, and no error in the changes, move the script:"
	@echo " mv $(conf_output) ./make_conf.yaml"
	@echo "[ENTER para rodar mv ou ^C para sair]"
	@read _tudo_bem_
	mv $(conf_output) ./make_conf.yaml

insert_license: insert_make_conf.yaml
	@echo "-- Updating make_conf with files licenses --"
	psql $(pg_uri_db) -c "SELECT lix_generate_make_conf_with_license('$(country)','$(pkid)');"
	sudo chmod 777 $(conf_output)
	@echo " Check diff, the '<' lines are the new ones... Something changed?"
	@diff $(conf_output) ./make_conf.yaml || :
	@echo "If some changes, and no error in the changes, move the script:"
	@echo " mv $(conf_output) ./make_conf.yaml"
	@echo "[ENTER para rodar mv ou ^C para sair]"
	@read _tudo_bem_
	mv $(conf_output) ./make_conf.yaml

insert_make_conf.yaml:
	@echo "-- Carrega make_conf.yaml na base de dados. --"
	@echo "Uso: make insert_make_conf.yaml"
	@echo "pkid: $(pkid)"
	@echo "[ENTER para continuar ou ^C para sair]"
	@read _tudo_bem_
	psql $(pg_uri_db) -c "SELECT ingest.lix_insert('$(country)','$(mkme_input)','make_conf');"

delete_file:
	@echo "Uso: make delete_file hash=<inicio do hash do arquivo>"
	@echo "hash: $(hash)"
	@echo "[ENTER para continuar ou ^C para sair]"
	@read _tudo_bem_
	@[ "${hash}" ] && psql $(pg_uri_db) -c "DELETE FROM ingest.layer_file WHERE pck_fileref_sha256 LIKE '$(hash)%'" || ( echo "hash não informado.")

load_license_tables:
	@echo "-- Carrega tabelas --"
	wget "https://raw.githubusercontent.com/ppKrauss/licenses/master/data/families.csv" -O "$(pg_io)/families.csv"
	wget "https://raw.githubusercontent.com/ppKrauss/licenses/master/data/licenses.csv" -O "$(pg_io)/licenses.csv"
	wget "https://raw.githubusercontent.com/ppKrauss/licenses/master/data/implieds.csv" -O "$(pg_io)/implieds.csv"
	wget "https://raw.githubusercontent.com/digital-guard/preserv-BR/main/data/donatedPack.csv" -O "$(pg_io)/donatedPack.csv"
	wget "https://raw.githubusercontent.com/digital-guard/preserv-BR/main/data/donatedPack-old2new.csv" -O "$(pg_io)/donatedPack-old2new.csv"

	psql $(pg_uri_db) -c "SELECT ingest.fdw_generate_direct_csv('$(pg_io)/families.csv','tmp_families'); SELECT ingest.fdw_generate_direct_csv('$(pg_io)/licenses.csv','tmp_licenses'); SELECT ingest.fdw_generate_direct_csv('$(pg_io)/implieds.csv','tmp_implieds'); SELECT ingest.fdw_generate_direct_csv('$(pg_io)/donatedPack.csv','tmp_donatedPack'); SELECT ingest.fdw_generate_direct_csv('/tmp/pg_io/donatedPackold2new.csv','tmp_donatedPackold2new');"
