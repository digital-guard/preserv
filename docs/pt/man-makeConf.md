
Os arquivos `make_conf.yaml` têm como finalidade principal a conversão automática para [*makefile*](https://en.wikipedia.org/wiki/Make_(software)#Makefile), e, secundariamente, conversões para geração de "conteúdo esqueleto" do README e de e-mails do _workflow_ de aprovação. 

## Resumo da ferramenta

Os dados recebidos de diferentes doadores apresentam diferentes formatos e estruturas. Na Digital-Guard, por outro lado, criamos uma estrutura padrão para que os dados "conversem" e sejam comparáveis entre si... A compatibilidade dos dados é um aspecto fundamental, mas não podemos devolver os dados para os doadores dizendo "coloque no formato padrão". É uma condição de trabalho que a Digital-Guard se propôs a enfrentar. Enfrentamos o desafio através da implementação de "motores de conversão", que são softwares que convertem dados de outros formatos para o formato e estrutura padronizados.

Uma outra condição é a preservação: os dados originais são guardados por 20 anos, e qualquer um que desejar, hoje ou no futuro, recuperar os dados e p

Os _makefiles_ rodam softwares


padronizados (ex. [shp2pgsql](https://postgis.net/docs/using_postgis_dbmanagement.html#shp2pgsql_usage)), com ampla comunidade de usuários de geoprocessamento e Unix,  consolidados por mais de 10 anos de domínio público, **garantindo [reprodutibilidade](https://pt.wikipedia.org/wiki/Reprodutibilidade)  da ingestão em banco de dados PostgreSQL+PostGIS**.


Os _makefiles_ rodam softwares padronizados (ex. [shp2pgsql](https://postgis.net/docs/using_postgis_dbmanagement.html#shp2pgsql_usage)), com ampla comunidade de usuários de geoprocessamento e Unix,  consolidados por mais de 10 anos de domínio público, **garantindo [reprodutibilidade](https://pt.wikipedia.org/wiki/Reprodutibilidade)  da ingestão em banco de dados PostgreSQL+PostGIS**.

## Formato

JSON e YAML são equivalentes, se precisar use ferramentas de conversão "JSON to YAML". A preferência por YAML é por ser mais "legível ao humano" (*human readable*),  assim como mais fácil de interpretar no *diff* de cada novo *commit* do *git*. Adotamos o padrão [YAML v1.2.2](https://yaml.org/spec/1.2.2), que preserva sua compatibilidade sintática com a especificação de 2001, [RFC&#160;2822](https://www.rfc-editor.org/rfc/rfc2822.txt), e estende sua semântica para interpretadores JSON.

## Estrutura e sintaxe mais comum

Os *templates* são flexíveis, mas as variantes são pouco usadas, de modo que a estrutura mais comum acaba servindo de referência para 90% dos casos. A estrutura a seguir é utilizada por exemplo em [BR-pk046](http://git.digital-guard.org/preserv-BR/blob/main/data/AC/RioBranco/_pk046/make_conf.yaml).

Primeiro nível, cabeçalho:

* `pkid`:      identificador local (país) do package, um número sequencial controlado por  
* `pkversion`: entre aspas o número de versão, "001" para que não seja depois seja convertido em decimal corretamente. <br/>(bug do YAML que poderia ser corrigido no Python)
* `schemaId_input`:

Primeiro nível, demais objetos:

* `files`: lista dos arquivos preservados a serem submetidos a algum tipo de transformação para se tornarem úteis para os projetos-patrocinadores. Cada item da lista é contextualmente único e totalmente identificável.  

* `layers`: chaves definidoras de layers conforme convenções especificadas em ... Cada layer pode ter um ou mais arquivos como fonte, e dois layers diferentes podem ser oriundos de um mesmo arquivo (por exemplo OSM gera todos os layers).

A seguir cada subseção descritiva de segundo nível segue a nomenclatura da respectiva chave de primeiro nível.

### files

Cada item da lista de arquivos é especificado da seguinte maneira:

* `-`

  * `p:`    Identificador local do arquivo no arquivo de configuração

  * `file:` nome de arquivo no formato "sha256.ext".

  * `name:` nome livre, sugerindo conteúdos do arquivo.

...

### layers

Comumente, cada layer é especificado pelas seguintes chaves:

* `layer:` nome padronizado do *layer*, conforme tabela dos [***feature types***](ftypes.md).  

  * `subtype:` completeza do layer com relação a dados-core do sponsor: full, ext ou none. Dados complementares (cadastrais) aos dados-core são descritos pelos valores: cmpl, noid e none.

  * `method:` método de conversão utilizado para a ingestão de `file`. Os mais comuns são shp2sql e ogr2ogr. Outros disponíveis são csv2sql e ogrWshp.

  * `p:` identificador do arquivo seguido de letra identificadora do layer.

  * `file:` referência ao identificador `p` de um dos itens da lista de arquivos `files`.

  * `sql_view:` [OPCIONAL] query completa referenciando "FROM $(tabname)". Torna inócua `select_sql`.

  * `select_sql:` [OPCIONAL] lista de nomes de coluna da tabela de referência do method. É obrigatória se `sql_view` não existir.

  * `orig_filename:` nome do arquivo (ou arquivo de referência como no caso de shape) a ser utilizado pelo método de conversão.

...

## Outras estruturas
(Avaliar se é o local correto)
Além das opções mais comuns, outras podem ser utilizadas:

  * `multiple_files:` valor boleano, informa se o respectivo `file` de um layer possui mais de um arquivo. É obrigatória quando `file` possuir vários arquivos.

  * `orig_subfilename:` nome do arquivo para o caso de `file` possuir arquivo compactado dentro de arquivo compactado.

  * `join_column:` nome da coluna utilizada para correlacionar um layer e seu respectivo layer complementar(cadastral).

  * `orig_ext:` utilizada em algumas situações com os métodos csv2sql (apenas para a extensão .xlsx) e ogr2ogr para indicar a extensão do arquivo.

  * `method_opts:` opções para os programas shp2pgsql (utilizado pelo método shp2sql) e xlsx2csv (utilizado por csv2sql na conversão de um arquivo xlsx para csv, quando combinado com orig_ext: .xlsx).

  * `7z_opts:` opções para o compactador de arquivos 7z utilizado na descompactação de dos arquivos listados em `files`.

  * `srid:` ou `srid_local` (???).

  * `tabname:` (obsoleta?)


Estrutura do arquivo commomFirst.yaml

O arquivo é utilizado para configurações de cada jurisdição ...

* `pg_io:`   ??? /tmp/pg_io

* `orig:`    ??? /var/www/preserv.addressforall.org/download

* `pg_uri:`  URI para conexão com base de dados (postgres://postgres@localhost)

* `pg_db:`   nome da base de dados.

* `sandbox:` caminho de diretório temporário utilizado durante o processo de ingestão de dados.

* `thisTplFile_root:` ??? Como foi centralizado em preserv, acho que essa chave se tornou obsoleta.


## Commom files

## Processamento

O processamento dos arquivos `make_conf.yaml` é feito pelo software [run_mustache.py](http://git.digital-guard.org/preserv/blob/main/src/run_mustache.py), escrito em python, utilizando templates Mustache. Os principais templates utilizados estão em [src/maketemplates](http://git.digital-guard.org/preserv/tree/main/src/maketemplates). Antes da renderização é incluído no arquivo `make_conf.yaml` o conteúdo do arquivo [commomFirst.yaml](http://git.digital-guard.org/preserv-BR/blob/main/src/maketemplates/commomFirst.yaml), especifico para cada jurisdição.  

... usando Mustache... usando

## Semânica

* Uso do makefile como [ETL](https://en.wikipedia.org/wiki/Extract,_transform,_load) ...
* Semântica dos dados-origem e dos dados gerados ... ver [***feature types***](http://git.digital-guard.org/preserv/blob/main/docs/pt/ftypes.md).

----

##  Referências

Outros documentos A4A:
* ...

Casos análogos:
* https://github.com/pelias/pelias#how-does-it-work
* https://github.com/openaddresses/openaddresses/blob/master/CONTRIBUTING.md
* ...
