# airflow/ — ingestão em Python orquestrada pelo Airflow

Substitui a cola feita pelos makefiles gerados (mustache) por três scripts Python.
O trabalho pesado continua no SQL do schema `ingest` (`ingest.any_load`,
`ingest.ppublicating_geojsons`) e do schema `optim` (datalake). O `make_conf.yaml`
continua sendo o contrato do pacote e não muda.

```
make_conf.yaml ──python01_ingest──▶ ingest<NN> ──python02_publish──▶ preservCutGeo-<PAIS>2021/
                                        │
                                        └──python03_promote──▶ dl05s_main (fila ▶ aprovado) + README/reproducibility
```

| Script | Equivale a | Grava em |
|---|---|---|
| `python01_ingest.py`  | `make all_layers pg_db=…`                                   | `ingest<NN>` (`donated_packcomponent`, `feature_asis`) |
| `python02_publish.py` | `make all_publications pg_db=…`                             | pasta `path_cutgeo_server/<layer>/*.geojson` |
| `python03_promote.py` | `make to_donated_packcomponent`, `approved_donated_packcomponent`, `readme`, `me_reproducibility` | `dl05s_main` (`optim.donated_packcomponent[_not_approved]`), pasta do pacote |
| `python04_clean.py`   | limpeza no fim do ciclo                                      | remove tabelas brutas, views de análise, sandbox e temporários do pacote (`--all` para o banco inteiro) |

Cada script grava um relatório em `/tmp/pg_io/reports/` (json + txt), imprime e
envia por e-mail (`DG_MAIL_TO`, SMTP em `DG_SMTP_*`). Todos aceitam `--dry-run`,
`--layers a,b`, `--mail-to`, `--no-mail`.

Nenhum banco é fixo no código:

| Parâmetro | Variável de ambiente | Default |
|---|---|---|
| `--pg-db` (obrigatório) | `DG_PG_DB` | nenhum |
| `--pg-uri` | `DG_PG_URI` | `postgres://postgres@localhost` |
| `--pg-datalake` (só python03) | `DG_PG_DATALAKE` | `dl05s_main` |

Ex.: `--pg-uri postgres://postgres@localhost:5499 --pg-db ingest_teste` usa o container
`pg_carlos_16`. O banco de ingestão precisa ter sido criado com `make ini_ingest pg_db=…`.

## Pré-requisitos

- Rodar no `pk21` (ou em máquina com os mesmos mounts): `/var/gits/_dg`, `/tmp/pg_io`,
  `/tmp/sandbox`, `/var/www/dl.digital-guard.org`, `sudo` sem senha, `7z`, `ogr2ogr` (GDAL ≥ 3.x).
- Postgres em `localhost:5432` (container `pg_felipe_16`), bancos `ingest<NN>` e `dl05s_main`.
  O banco de ingestão precisa do FDW para o datalake (`ingest.vw01full_packfilevers`,
  `ingest.fdw_feature_type`), que `make ini_ingest` já cria.
- Pacote cadastrado no datalake (`optim.donated_packtpl`, `optim.donated_packfilevers`):
  os hashes dos `files:` do yaml são a chave de resolução.
- View de validação `ingest.vw06ingest_report`: criada por `make ini_ingest` (está em
  `preserv/src/ingest-step1-ini.sql`); em bancos já existentes, `psql …/ingest<NN> < sql/ingest_vw06_report.sql`.
- Python 3 com `PyYAML` e `psycopg2` (já no pk21).

## Uso

```sh
cd /var/gits/_dg/preserv/airflow
P=/var/gits/_dg/preserv-BR/data/RS/PortoAlegre/_pk0018.01

python3 python01_ingest.py  $P --pg-db ingest20                 # ingestão + relatório
python3 python02_publish.py $P --pg-db ingest20 --out-root /tmp/pg_io/cutgeo_test  # teste, sem tocar no CutGeo
python3 python02_publish.py $P --pg-db ingest20 [--git-commit]  # geojsons no CutGeo real
python3 python03_promote.py $P --pg-db ingest20 --regenerate    # fila de aprovação + README/reproducibility
python3 python03_promote.py $P --pg-db ingest20 --approve       # aprovação no datalake
```

## Cobertura dos targets do makefile gerado

Inventário feito em 2026-10-31 gerando o makefile de 104 pacotes com `optim.generate_makefile`.

| Target do makefile | Onde está nos scripts |
|---|---|
| `all_layers`, `<layer>` | `python01` (ogr2ogr / funções SQL + `ingest.any_load`) |
| `all_joins`, `join-<layer>` | `python01` (`ingest.join` após os layers; `--no-join`) |
| `partition_by` (`any_load_loop`) | `python01` |
| `wget_files` | `python01` baixa de `dl.digital-guard.org` quando o zip falta em `DG_ORIG` |
| `makedirs`, `clean_sandbox`, `clean`, `<layer>-clean` | `python01` (sandbox mantido; `--clean-sandbox`) |
| `delete_file id=` | `python01` reset do layer (`--no-reset` desliga) |
| `all_publications`, `publicating_geojsons_<layer>` | `python02` |
| `audit-geojsons_<layer>` | `python02` (n, média, min, max no relatório) |
| `change_parameters_<layer> threshold_sum=` | `python02 --layer X --threshold-sum N` |
| `all_filtered`, `generate_filtered_files id=` | `python02 --filtered` (chama `generateFiles.sh`) |
| `insert_size` | `python03 --insert-size` (mede no host, não no servidor) |
| `insert_license` | `python03 --insert-license` |
| `readme`, `me_reproducibility` | `python03 --regenerate` |
| `me`, `info` | obsoletos: o makefile deixa de existir |
| `openstreetmap`, `osm2sql`, `openstreetmap-clean` | **não coberto** (12 pacotes: AR, BO, …; exige `osm2pgsql`, `ingest.jplanet_inserts_and_drops`, `ingest.osm_load`) |

## Ciclo do analista (dado novo que dá erro)

O `python01` deixa no banco, após cada execução, três objetos por layer, recriados a
cada rodada (`DROP … CREATE`):

| Objeto | Exemplo | Conteúdo |
|---|---|---|
| tabela bruta | `pk7600001801301_p3_via` | saída do `ogr2ogr`, colunas originais em minúsculas |
| view técnica | `vw3_pk7600001801301_p3_via` | o `sql_view` do yaml, é o que `any_load` lê |
| view do analista | `vw_br_rs_portoalegre_via` | alias legível da view técnica (ou da tabela, sem `sql_view`) |

Fluxo sugerido:

```sh
python3 python01_ingest.py $P --layer via --stage load   # carrega e cria as views, sem any_load
psql …/ingest20 -c "select * from vw_br_rs_portoalegre_via limit 10"   # ou abrir no QGIS
# corrigir sql_view / orig_filename / charset no make_conf.yaml
python3 python01_ingest.py $P --layer via               # ingestão completa só desse layer
```

Em erro, o relatório lista as colunas da tabela bruta, os objetos que ficaram para
análise e a linha de comando de reexecução. O sandbox `/tmp/sandbox/_pk<id>_<ver>`
também é mantido (`--clean-sandbox` apaga; `--drop-tables` remove os objetos no fim).

## Decisões

- **Uma só interpretação do yaml.** Os scripts chamam `optim.jsonb_mustache_prepare()` no datalake,
  a mesma função que alimenta os templates mustache, e consomem o dicionário resolvido: `srid`
  (de `codec:descr_encode`), `charset`, `delimiter`, `extension`, `orig_tabname`, `tabname`,
  `layername`, `packvers_id`, `joins`. Não há tradução de `codec` reimplementada em Python.
- **Validação do yaml antes de qualquer carga** (`Package.lint`): chave desconhecida em layer vira
  aviso (ex. `subtupe`), falta de `method`, `file`, `subtype` ou `orig_filename` aborta.
- **Cada `method` espelha o template `common003_shp2pgsql.mustache`:**

  | method | carga |
  |---|---|
  | `shp2sql` | `ogr2ogr` com convenção `shp2pgsql` (`gid`, `geom`, `PROMOTE_TO_MULTI`, `SHAPE_ENCODING`), CRS nativo |
  | `shp2sqlparalell` | idem, todos os `.shp` acumulados em uma tabela, um `any_load` |
  | `gdb2sql`, `ogr2ogr` | `ogr2ogr <fonte> <orig_tabname> -lco GEOMETRY_NAME=geom -a_srs EPSG:<srid>`, sem `FID` nem `MULTI`; para gdb o `fileref` é `<gdb>/random_data_file` |
  | `geojson2sql` | SQL `geojson_readfile_features_jgeom` (colunas `properties`, `jgeom`), com `splitGeojson.bash` acima de 150 MB |
  | `csv2sql` | `xlsx2csv`, `iconv` + `dos2unix` quando preciso, depois `ingest.fdw_generate_direct_csv` |
  | `txt2sql` | `ingest.copy_tabular_data` |
  | `osm2sql` | não suportado aqui |

- `ogr2ogr` para `shp2sql`, `shp2sqlparalell`, `gdb2sql`, `geojson2sql`, `ogr2ogr`,
  com a convenção do `shp2pgsql` (`gid`, `geom`, nomes em minúsculas, `PROMOTE_TO_MULTI`)
  para que os `sql_view` dos yamls continuem válidos. Carrega no CRS nativo (`-a_srs` vem
  de `srid`/`srid_proj`, sem reprojetar) para que `st_area`/`st_length` nos `sql_view`
  continuem em metros; `ingest.any_load` converte para 4326, como no makefile. Para CRS
  customizado o driver PostgreSQL do GDAL cria uma linha em `spatial_ref_sys` na primeira
  carga e a reutiliza nas seguintes (busca pelo WKT), sem o SRID aleatório dos makefiles.
- `csv2sql` e `txt2sql` continuam nas funções SQL (`fdw_generate_direct_csv`,
  `copy_tabular_data`), que já tratam geometria a partir de colunas.
- Joins: pares `<layer>_ext` + `cad<layer>_cmpl` (ou `geoaddress_ext` + `address_cmpl`) com
  `join_id` nos dois chamam `ingest.join()` depois da ingestão dos layers, como o `all_joins`
  do makefile. Layers cadastrais (`address`, `cadparcel`, `cadvia`, `cadgeopoint`) vão para
  `ingest.cadastral_asis` e não são publicados pelo python02.
- `osm2sql`/`openstreetmap` não são suportados por estes scripts (fluxo OSM à parte).
- Idempotência: `python01` remove o componente anterior do mesmo `(packvers_id, ftid)`
  antes de recarregar (`--no-reset` desliga).
- Aprovação é humana: o disparo da DAG seguinte (ou `--approve` no python03) é o gate.
- Container Postgres não monta `/var/www`; por isso o tamanho dos zips é lido no host,
  nunca pelo servidor.

## Airflow

O Airflow roda em outra máquina e executa os scripts no pk21 por SSH. `dags/dg_preserv_dags.py`
define `dg_01_ingest`, `dg_02_publish`, `dg_03_promote` e `dg_04_clean` com `SSHOperator`
(provider `apache-airflow-providers-ssh`), sem schedule, disparadas com parâmetros
(`pack_dir`, `pg_db` obrigatório, `pg_uri`, `layers`, `mail_to` e os específicos de cada etapa).

Configuração na máquina do Airflow:
1. `pip install apache-airflow-providers-ssh`
2. Connection tipo SSH com id `pk21`: host `pk21`, login `carlos`, chave privada sem senha
   (a mesma do `ssh carlos@pk21`).
3. Variables opcionais: `dg_ssh_conn_id`, `dg_preserv_airflow`, `dg_pg_uri`, `dg_mail_to`, `dg_python`.
4. SMTP em `airflow.cfg` para o e-mail de falha (`on_failure_callback`); o de resultado é
   enviado pelo próprio script no pk21 (`DG_SMTP_*` no ambiente do `carlos`).
