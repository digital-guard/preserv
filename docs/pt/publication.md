# Publicação

## Responsabilidade do ingestor

Após realizar o processo de ingestão:

### Gerar os arquivos publicavéis

```sh
make publicating_geojsons_<nome_do_layer> # exemplo: make publicating_geojsons_via` gera os arquivos em `/var/gits/_dg/preservCutGeo-BR2021/data/AC/RioBranco/_pk0042.01/via/`

make target audit-geojsons_<nome do layer> # exibe informações sobre os arquivos gerados.
```

Atualmente, apenas em casos excepcionais é necessário recorrer a [busca de parametros de distribuição](https://github.com/digital-guard/preserv/blob/main/docs/pt/man-diversos.md#par%C3%A2metros-de-publica%C3%A7%C3%A3o).


### Pull CutGeo

O `pull` dos arquivos gerados deve ser feito em _branch_ diferente da _main_ e exclusiva para o pacote de dados, para aguardar aprovação.


### Copiar informações para DL03t_main
A execução dos targets de ingestão e publicação geram dados na tabela `ingest.donated_packcomponent` da base de dados `ingest` utilizada no processo. A base `ingest` é transitória. Findo os passos anteriores, os dados gerados devem ser movidos para a base de dados permanente `DL03t_main`.

Para copiar o conteúdo da tabela `ingest.donated_packcomponent` para `optim.donated_PackComponent_not_approved` em `DL03t_main`:

```sh
pushd /var/gits/_dg/preserv/src
make to_donated_packcomponent pg_db=ingestXX pg_datalake=dl03t_main
```

## Responsabilidade do homologador

### Aprovação
A aprovação se dá pela avaliação dos arquivos, _merge_ com a _branch_ _main_ e movendo os dados de `optim.donated_PackComponent_not_approved` para `optim.donated_PackComponent` em `DL03t_main`:

```sh
# obter a variavel id
psql postgres://postgres@localhost/dl03t_main <<< "SELECT * FROM optim.donated_PackComponent_not_approved;"
pushd /var/gits/_dg/preserv/src
make approved_donated_packcomponent id=ZZ pg_datalake=dl03t_main
```

Nesse momento, os novos dados fazem parte das estátisticas disponibilizadas em api. Também, listas disponibilizadas no site addressforall e em documentações podem ser atualizadas.
