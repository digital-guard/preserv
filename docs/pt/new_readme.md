## Readme automatizado

A seguir exemplo fictício de make_conf.yaml para gerar um README.md do pacote. Reparar nas chaves: `comments, comment, test_evidence, standardized_fields, other_fields, other_files e to-do`.

Informações extras ou que não se encaixam nas referidas chaves devem ser incluídas num arquivo _attachment.md_, que terá seu conteúdo anexado ao final do README.md numa seção chamada _anexo_.


```yaml
pack_id: 81.1
pkversion: 001
schemaId_input: 
schemaId_template: 
codec:descr_encode: srid=31983

files:
  -
    p:    1
    file: d9cddc63f7782d250fc80f0572b9fb884ee7ec1911e19deea4381a4ad5d0a172.zip
    name: Bairros
    comments: Comentários sobre o arquivo, se houver.
    size: 1234
  -
    p:    2
    file: 47910adcd297a9ba875d89dacc91bc6b2a37d6eab4910964253e117c1484b4c5.zip
    name: Logradouros
    comments: Comentários sobre o arquivo, se houver.
    size: 1234

layers:

  geoaddress:
    subtype: ext
    method: shp2sql
    file: 3
    sql_select: ['gid', 'numnovo as house_number', 'cod_log', 'geom']
    orig_filename: pg_renumeracoes
    join_column: cod_log
    comments: Comentários referente ao layer, se houver.
    test_evidence: endereço da imagem. 
    standardized_fields:
     -
      name: numnovo
      standard: house_number
      comment: comentários, se houver.
    other_fields:
     -
      name: cod_log
      comment: Identificador, usado para join.

  address:
    subtype: cmpl
    method: shp2sql
    file: 2
    sql_view: SELECT DISTINCT Logradouro as via_name, cod_log FROM $(tabname) WHERE Logradouro IS NOT NULL
    orig_filename: pg_cartografia_logradouros
    join_column: cod_log
    comments: Comentários referente ao layer, se houver.
    test_evidence: endereço da imagem. 
    standardized_fields:
     -
      name: Logradouro
      standard: via_name
      comment: comentários, se houver.
    other_fields:
     -
      name: cod_log
      comment: Identificador, usado para join.

comments: Comentários gerais, se houver.

test_evidence: endereço da imagem. 

other_files:
  -
    p: 4
    file: pg_div_municipio.zip
    name: pg_div_municipio
    format: shp
    comment: Arquivo com a divisa territorial de guarulhos e vizinhos.
  -
    p: 5 
    file: pg_cartografia_ct_vias.zip
    name: pg_cartografia_ct_vias
    format: shp
    comment: Arquivo com as vias sem nome do logradouro. Possui mais geometrias que o arquivo importado.

to-do: 
  - E necessario buscar via_name do arquivo geoaddress no arquivo via, atraves do campo 'cod_log'.

```

### Como gerar

Exemplo de geração de README.md:

```
pushd /var/gits/_dg/preserv-BR/src
make all
pushd /var/gits/_dg/preserv-BR/data/AC/RioBranco/_pk0042.01
make readme pd_db=ingest99
popd
popd
```
