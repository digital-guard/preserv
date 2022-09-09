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

layers:

  geoaddress:
    subtype: ext
    method: shp2sql
    file: 1
    sql_select: ['gid', 'numnovo as house_number', 'cod_log', 'geom']
    orig_filename: pg_renumeracoes
    comments: Comentários referente ao layer, se houver.
    test_evidence: endereço da imagem de evidencia do layer.
    
    # dados relevantes, padronizados
    standardized_fields:
     -
      name: nome do campo ou combinação de campos
      standard: 'nome padronizado, por exemplo: house_number'
      comment: comentários sobre o campo, se houver.

    # dados relevantes, NÃO padronizados, se houver
    other_fields:
     -
      name: nome do campo ou combinação de campos
      comment: comentários sobre o campo, se houver.

comments: Comentários gerais sobre os dados, sobre o pacote, etc, se houver.

test_evidence: endereço da imagem de evidencia de todos os dados. 

# outros arquivos que podem ser úteis
other_files:
  -
    p: 2
    file: pg_div_municipio.zip
    name: pg_div_municipio
    format: shp
    comment: Arquivo com a divisa territorial de guarulhos e vizinhos.
  -
    p: 3 
    file: pg_cartografia_ct_vias.zip
    name: pg_cartografia_ct_vias
    format: shp
    comment: Arquivo com as vias sem nome do logradouro. Possui mais geometrias que o arquivo importado.

# Lista de tarefas
to-do: 
  - Tarefa 1.
  - Tarefa 2.
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
