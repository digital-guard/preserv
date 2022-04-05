## No rule to make target
Ao executar `make layer` ou `make all_layers`, caso encontre um erro do tipo
```
make: *** No rule to make target '/var/www/preserv.addressforall.org/download/bae2054448855305db0fc855d2852cd5a7b369481cc03aeb809a0c3c162a2c04.zip', needed by 'parcel'.  Stop.
```
o arquivo especificado não está no diretório default `/var/www/preserv.addressforall.org/download`, informado na chave `orig` de uma jurisdição, por exemplo, em [commomFirst.yaml](https://github.com/digital-guard/preserv-BR/blob/main/src/maketemplates/commomFirst.yaml#L2). Significando que o arquivo está armazenado em outro lugar. Isso está indicado  na tabela [de-para](https://docs.google.com/spreadsheets/d/1CL6f0I9DSpqKxKC7QNJGCfyabq7mDOVab5QBGV5VLOk).


Nesse caso usar:

```
wget -P /diretorio/para/arquivo/baixado http://dl.digital-guard.org/bae2054448855305db0fc855d2852cd5a7b369481cc03aeb809a0c3c162a2c04.zip

make me pg_db=ingestXX

make parcel orig=/diretorio/para/arquivo/baixado pg_db=ingestXX
```
Se o download for realizado em /var/www/preserv.addressforall.org/download utilizar apenas

`make parcel  pg_db=ingestXX`

uma vez que o valor default de orig é /var/www/preserv.addressforall.org/download.

Observação: atualmente, [common002_layerHeader.mustache](https://github.com/digital-guard/preserv/blob/main/src/maketemplates/common002_layerHeader.mustache#L18) interage com o usuário solicitando a confirmação de download de dl.digital-guard.org ou o fornecimento do valor correto de orig. Caso o download seja realizado, o arquivo estará localizado na respectiva sandbox do layer. Notar que se `nointeraction=y` não haverá interação com o usuário e o download será feito.

## Clean sandbox

O processo de ingestão utiliza subpastas no caminho informado em `sandbox`, cujo valor default é informado no _commomFirst.yaml_.
Antes na execução da ingestão de cada layer, o target `makedirs` cria ou limpa a subpasta utilizada pelo layer. Após a execução, o target `clean-sandbox` remove a subpasta, evitando que arquivos não mais necessários permanecem no sistema de arquivos.

## Resumo do tratamento aplicado às geometrias no processo de ingestão:

Dado um conjunto de geometrias:

1. Inicialmente se garante que [SRID](https://en.wikipedia.org/wiki/Spatial_reference_system#Identifiers) das geometrias será 4326.

2. Em seguida, são selecionadas as geometrias onde a função [ST_IsClosed](https://postgis.net/docs/ST_IsClosed.html) é verdadeira ou forem linhas.

3. Para as geometrias onde [ST_IsSimple](https://postgis.net/docs/ST_IsSimple.html), [ST_IsValid](https://postgis.net/docs/ST_IsValid.html) e [ST_Intersects](https://postgis.net/docs/ST_Intersects.html) [^1] são verdadeiras, são aplicadas as funções [ST_Intersection](https://postgis.net/docs/ST_Intersection.html) [^1], [ST_ReducePrecision](https://postgis.net/docs/ST_ReducePrecision.html) [^2] e, para geometrias diferentes de ponto, [ST_SimplifyPreserveTopology](https://postgis.net/docs/ST_SimplifyPreserveTopology.html) [^3].

4. São ingeridas, em `feature_asis`, as geometrias que não são nulas (IS NOT NULL) e que não são vazias, utilizando [ST_IsEmpty](https://postgis.net/docs/ST_IsEmpty.html). Além disso, são ingeridos apenas polígonos com [ST_Area](https://postgis.net/docs/ST_Area.html) >= 5 e linhas com [ST_Length](https://postgis.net/docs/ST_Length.html) >= 2.

5. Às geometrias ingeridas, independentemente do tipo, são aplicadas as funções [ST_PointOnSurface](https://postgis.net/docs/ST_PointOnSurface.html) e [ST_Geohash](https://postgis.net/docs/ST_GeoHash.html) com  `maxchars=9`, para obter _geohash_ com 9 caracteres.

6. Geometrias com _geohash_ iguais são consideradas iguais, sendo agrupadas e representadas pela geometria que possuir o menor `feature_id`. Isso significa que as repetidas são removidas de `feature_asis` e o representante é inserido, contendo:

      5.1. `is_agg`: flag para indicar que é um `feature_id` agregado;
      5.2. `properties_agg`: array contendo `properties` dos `feature_id` agregados;
      5.3. `geom_cmp_equals`: array contendo o resultado de [ST_Equals](https://postgis.net/docs/ST_Equals.html) entre o representante e os agregados;
      5.4. `geom_cmp_frechet`: array contendo o resultado de [ST_FrechetDistance](https://postgis.net/docs/ST_FrechetDistance.html) entre o representante e os agregados. Apenas para geometrias do tipo linha;
      5.5. `geom_cmp_intersec`: array contendo medida de similaridade [^4] entre polígono represente e os agregados. Apenas para geometrias do tipo polígono.

7. Geometrias que não atendam algum dos critérios acima possuem `error_mask` com algum bit diferente de zero. Essas geometrias ficam disponíveis em `feature_asis_discarded`, tabela idêntica à `feature_asis`, exceto por o jsonb `properties` possuir a chave `error_mask` indicando os critérios não atendidos. Às geometrias que não são fechadas ou não são linhas é aplicada a função [ST_MakeValid](https://postgis.net/docs/ST_MakeValid.html), para possibilitar o uso da função [ST_PointOnSurface](https://postgis.net/docs/ST_PointOnSurface.html) antes da aplicação da [ST_Geohash](https://postgis.net/docs/ST_GeoHash.html) no momento em que o _geohash_ é obtido.

Esse processo é realizado pela função `any_load` no _schema_ `ingest`.

O processo de ingestão utiliza uma sequencia de 12 bits, em `error_mask`, para indicar erros encontrados.

No inicio do processo a sequencia de bits de um item é:

`error_mask=000000000000`

Dá direita para esquerda, um bit igual a 1 representa:

- Item não intersecta a geometria da jurisdição;
- Item não tem geometria válida;
- Item não tem geometria simples;
- Item tem geometria vazia;
- Item tem área ou comprimeto menor que 5 ou 2, respectivamente;
- Item tem geometria nula;
- Item tem geometria com tipo diferente do estabelecido para o layer em feature_type;
- Item duplicado. Dois items são duplicados se seus geohash de tamanho 9 são iguais;
- Item com geometria não fechada (em se tratando de polígonos);
- Os 3 bits mais à esquerda estão reservados para eventuais usos futuros e, por hora, são sempre zero.

Exemplo de saída produzida após a execução de uma ingestão:

```
------------------------------------------------------------------------
 From file_id=8 inserted type=geoaddress_full.                         +
                                                                       +
         Statistics:                                                   +
 .                                                                     +
         Before deduplication:                                         +
                                                                       +
         Originals: 474520 items.                                      +
                                                                       +
         Not Intersecs: 684 items.                                     +
                                                                       +
         Invalid: 0 items.                                             +
                                                                       +
         Not simple: 0 items.                                          +
                                                                       +
         Empty: 0 items.                                               +
                                                                       +
         Small: 0 items.                                               +
                                                                       +
         Null: 0 items.                                                +
                                                                       +
         Invalid geometry type: 0 items.                               +
                                                                       +
         Not closed: 0 items.                                          +
                                                                       +
         Inserted in feature_asis: 473836 items.                       +
                                                                       +
         Inserted in feature_asis_discarded: 684 items.                +
                                                                       +
                                                                       +
         After deduplication:                                          +
                                                                       +
         Removed duplicates from feature_asis: 169477 items.           +
                                                                       +
         Inserted in feature_asis_discarded (duplicates): 169477 items.+
                                                                       +
         Inserted in feature_asis (aggregated duplicates): 79967 items.+
                                                                       +
         Resulting in feature_asis: 384326                             +
 
(1 row)
```


[^1]: com a geometria da respectiva jurisdição, obtida do OpenStreetMap, com um `buffer_type` = 1 por default.
[^2]: sendo utilizado  `gridsize = 0.000001`, para precisão ~1m, conforme [Decimal_degrees#Precision](https://en.wikipedia.org/wiki/Decimal_degrees#Precision).
[^3]: sendo utilizado `tolerance = 0.00000001`, com a intensão do algoritmo [Douglas-Peucker](https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm) remover apenas pontos colineares.
[^4]: As medidas de similaridade são calculadas pela função `feature_asis_similarity`no _schema_ `ingest`.

## make layer sem interação com usuário:

Para rodar um _target_ sem serem solicitadas confirmações do usuário, utilizar `nointeraction=y`.

Por exemplo, `make block nointeraction=y` faz a ingestão dos dados sem solicitar confirmações do usuário.[^5]

Essa variável só produz efeito em _target_ `layer`, `publicating_geojsons_layer` ou `me`. Para os demais, não.

[^5]: _Layer_ com `method` que utiliza o _ogr2ogr_ via docker, ou target `me`, podem solicitar a senha do usuário.

## Buffer em geometrias jurisdicionais:

Foi adotada a aplicação de um buffer, por _default_, nas geometrias de jurisdição. Atualmente essa valor é de 50 metros.
Esse comportamento pode ser alterado utilizando a chave buffer_type em layer do make_conf. Os valores possíveis para essa chave são:

- `buffer_type: 1`, valor default, aplica um buffer de aproximadamente 100 metros. Não é necessário informá-lo no _make_conf.yaml_. É inserido automaticamente pela função `jsonb_mustache_prepare` caso não seja informado. 
- `buffer_type: 0`, sem buffer. Para utilizá-lo, deve-se informá-lo no _make_conf.yaml_
- `buffer_type: 2`, aplica um buffer de aproximadamente 5000 metros. Para utilizá-lo, deve-se informá-lo no respectivo layer do _make_conf.yaml_

## Atualizar tabelas de optim (atualmente em `dl03t_main`):

Se donatedPack.csv ou donor.csv (em qualquer jurisdição) forem alterados ou um novo _make_conf.yaml_ for criado (se não existia e passou a existir), é necessário atualizar as tabelas do [schema optim](https://github.com/digital-guard/preserv/blob/main/src/optim-step1-ini.sql). Para isso, utilizar:

```
pushd /var/gits/_dg/preserv/src
make load_optim_csv pg_datalake=dl03t_main
```

Notar que se as restrições das tabelas não forem respeitadas o carregamento ou atualização dos dados não acontece. Retornando erro.

Caso for alterado o sha256 em um make_conf.yaml já existente, ver [preserv-BR/issues/68](https://github.com/digital-guard/preserv-BR/issues/68#issuecomment-1081026983).


## Especificações mosaico:

Propriedades presentes em todos os layers:

* ghs_bytes: inteiro. soma da quantidade de bytes dos itens (SUM(length(St_asGeoJson(geom)))
* ghs_area: duas casa decimais. area do ghs, em km2
* ghs_len: inteiro. tamanho de ghs
* ghs_items: inteiro. quantidade de itens em ghs
* ghs_itemsDensity: duas casas decimais. densidade, ghs_items por ghs_area (itens por unidade de área).
* ghsval_unit: nome da unidade utilizada como métrica da distribuição (tipicamente "ghs_bytes" ou "ghs_items".

Propriedade que variam conforme os layers:
* size: duas casas decimais. tamanho total dos itens em ghs, (unidade para linhas:km. unidade para polígonos: km2. não utilizada para pontos.)
* size_unit:
  * dim0 = pontos = não precisa de soma de métrica
  * dim1= linhas = tem soma de métrica km  
  * dim2 = polígonos = tem soma de km2, e densidade_km2
* size_unitDensity

## Relatórios

### optim.vw01report

Exemplo:

```
dl03t_main=# select * from optim.vw01report;
 isolabel_ext  |            legalname            |         vat_id          | ID de pack_componente |     ftname      | ftid | step | data_feito |    n_items     |  size   
---------------+---------------------------------+-------------------------+-----------------------+-----------------+------+------+------------+----------------+---------
 BR-RJ-Niteroi | Prefeitura Municipal de Niterói | cnpj:28.521.748/0001-59 | br0016.01.3.01        | nsvia_ext       |   72 |    6 | 2020-05-22 | 65 polygons    | 133 km2
 BR-RJ-Niteroi | Prefeitura Municipal de Niterói | cnpj:28.521.748/0001-59 | br0016.01.2.01        | via_full        |   31 |    6 | 2020-05-22 | 2538 segments  | 759 km
 BR-RJ-Niteroi | Prefeitura Municipal de Niterói | cnpj:28.521.748/0001-59 | br0016.01.1.01        | parcel_ext      |   62 |    6 | 2020-04-20 | 74804 polygons | 62 km2
 BR-SP-Santos  | Prefeitura Municipal de Santos  | cnpj:58.200.015/0001-83 | br0029.01.1.01        | geoaddress_full |   21 |    6 | 2018-09-18 | 43161 points   | 
(4 rows)
```

### optim.vw02report_simple

Exemplo:

```
dl03t_main=# select * from optim.vw02report_simple;
 isolabel_ext  |     ftname
---------------+-----------------
 BR-RJ-Niteroi | nsvia_ext
 BR-RJ-Niteroi | via_full
 BR-RJ-Niteroi | parcel_ext
 BR-SP-Santos  | geoaddress_full
(4 rows)
```

### vw01report_median

A view optim.vw01report_median (em dl03t_main) retorna a quantidade de arquivos, sua a mediana, média, mínimo e máximo em _kibibytes_. Exemplo:

```
dl03t_main=# select * from optim.vw01report_median ;
 isolabel_ext  | pack_number | class_ftname | n  | mdn_n | avg_n | min_n | max_n
---------------+-------------+--------------+----+-------+-------+-------+-------
 BR-RJ-Niteroi | 0016.01     | nsvia        |  2 |   154 |   272 |   154 |   390
 BR-RJ-Niteroi | 0016.01     | parcel       | 36 |   327 |   682 |   261 |  2765
 BR-RJ-Niteroi | 0016.01     | via          |  6 |   199 |   232 |   154 |   331
 BR-SP-Santos  | 0029.01     | geoaddress   | 33 |   149 |   166 |   101 |   469
(4 rows)
```


## Parâmetros de publicação

 A opção `pretty_opt=3` aplicada por default no target `publicating_geojsons_<nome_do_layer>` gera um mosaico sem espaços e quebra de linha, ver função [jsonb_pretty_lines](https://github.com/AddressForAll/pg_pubLib-v1/blob/main/src/pubLib03-json.sql#L166).

### Tabela de parâmetros
Bytes passaram a ser utilizados para balanceamento. [hcode_parameters.csv](https://github.com/digital-guard/preserv/blob/main/data/hcode_parameters.csv) fornece a lista de parametros.

* `id_profile_params: 1`: valor default para layers `geoaddress`;
* `id_profile_params: 5`: valor default para os demais layers. 

### Busca de parâmetros
Se for necessário, para buscar novos parametros para `hcode_distribution_parameters` para distribuição, após a ingestão do _layer_, duas opções:

1. Target

   O target `change_parameters_<nome do layer>` altera os parâmetros em `lineage`, executa a publicação (no respectivo repositório CutGeo) e, no final, executa o `target audit-geojsons_<nome do layer>`

   Exemplos de uso (é obrigatório informar as variáveis threshold_sum):
```
   make change_parameters_block threshold_sum=3000000 pg_db=ingest99 (`pg_db` é opcional, se estiver usando abase de dados default da respectiva jurisdição.)
```

2. Manual:

   Para configurar os parâmetros, utilizar, por exemplo:

```
   UPDATE ingest.donated_packcomponent
   SET lineage = jsonb_set(lineage, '{hcode_distribution_parameters}', '{"p_threshold_sum": 13500}', TRUE)
WHERE id = 11;
```
   O valor de `id` pode ser obtido por meio de `SELECT * FROM ingest.donated_packcomponent;`.

   Após o `UPDATE` executar novamente o target de publicação.

### Registrar parâmetros encontrados
Depois de encontrar os parâmetros, registrá-los em [hcode_parameters.csv](https://github.com/digital-guard/preserv/blob/main/data/hcode_parameters.csv) e informar no layer, como no exemplo:

```
  parcel:
        subtype: full
        ...
        id_profile_params: 3
```
   Após registrar os novos parâmetros em [hcode_parameters.csv](https://github.com/digital-guard/preserv/blob/main/data/hcode_parameters.csv) deve-se atualizar o banco de dados com:

```
pushd /var/gits/_dg/preserv/src
make load_hcode_parameters
popd
```

## Alterações de sha256 em make_conf.yaml

Ao alterações no sha256 de arquivos make_conf.yaml:

1. incrementar `pkversion`;
2. insrir nova entrada no arquivo donatePack.csv;
3. excecutar https://github.com/digital-guard/preserv/blob/main/docs/pt/man-diversos.md#atualizar-tabelas-de-optim-atualmente-em-dl03t_main

