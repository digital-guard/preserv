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

uma vez que esse 

## Resumo do tratamento aplicado às geometrias no processo de ingestão:

Dado um conjunto de geometrias:

1. Inicialmente se garante que [SRID](https://en.wikipedia.org/wiki/Spatial_reference_system#Identifiers) das geometrias será 4326.

2. Para as geometrias onde [ST_IsSimple](https://postgis.net/docs/ST_IsSimple.html), [ST_IsValid](https://postgis.net/docs/ST_IsValid.html) e [ST_Intersects](https://postgis.net/docs/ST_Intersects.html) [^1] são verdadeiras, são aplicadas as funções [ST_Intersection](https://postgis.net/docs/ST_Intersection.html) [^1], [ST_ReducePrecision](https://postgis.net/docs/ST_ReducePrecision.html) [^2] e, para geometrias diferentes de ponto, [ST_SimplifyPreserveTopology](https://postgis.net/docs/ST_SimplifyPreserveTopology.html) [^3].

3. São ingeridas, em `feature_asis`, as geometrias que não são nulas (IS NOT NULL) e que não são vazias, utilizando [ST_IsEmpty](https://postgis.net/docs/ST_IsEmpty.html). Além disso, são ingeridos apenas polígonos com [ST_Area](https://postgis.net/docs/ST_Area.html) > 5 e linhas com [ST_Length](https://postgis.net/docs/ST_Length.html) > 2.

4. Às geometrias ingeridas, independentemente do tipo, são aplicadas as funções [ST_PointOnSurface](https://postgis.net/docs/ST_PointOnSurface.html) e [ST_Geohash](https://postgis.net/docs/ST_GeoHash.html) com  `maxchars=9`, para obter _geohash_ com 9 caracteres.

5. Geometrias com _geohash_ iguais são consideradas iguais, sendo agrupadas e representadas pela geometria que possuir o menor `feature_id`. Isso significa que as repetidas são removidas de `feature_asis` e o representante é inserido, contendo:

      5.1. `is_agg`: flag para indicar que é um `feature_id` agregado;
      5.2. `properties_agg`: array contendo `properties` dos `feature_id` agregados;
      5.3. `geom_cmp_equals`: array contendo o resultado de [ST_Equals](https://postgis.net/docs/ST_Equals.html) entre o representante e os agregados;
      5.4. `geom_cmp_frechet`: array contendo o resultado de [ST_FrechetDistance](https://postgis.net/docs/ST_FrechetDistance.html) entre o representante e os agregados. Apenas para geometrias do tipo linha;
      5.5. `geom_cmp_intersec`: array contendo medida de similaridade [^4] entre polígono represente e os agregados. Apenas para geometrias do tipo polígono.

Esse processo é realizado pela função `any_load` no _schema_ `ingest`.

O processo de ingestão utiliza uma sequencia de 12 bits para indicar erros encontrados.

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
- Os 3 bits mais à esquerda estão reservados para eventuais usos futuros e, por hora, são sempre zero.

[^1]: com a geometria da respectiva jurisdição, obtida do OpenStreetMap.
[^2]: sendo utilizado  `gridsize = 0.000001`, para precisão ~1m, conforme [Decimal_degrees#Precision](https://en.wikipedia.org/wiki/Decimal_degrees#Precision).
[^3]: sendo utilizado `tolerance = 0.00000001`, com a intensão do algoritmo [Douglas-Peucker](https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm) remover apenas pontos colineares.
[^4]: As medidas de similaridade são calculadas pela função `feature_asis_similarity`no _schema_ `ingest`.
