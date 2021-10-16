# Preservação de dados no Digital-guard

O **Projeto Digital-guard**, de curadoria e [preservação digital](https://en.wikipedia.org/wiki/Digital_preservation), é mantido pelo [ITGS](http://itgs.org.br). A curadoria seleciona dados relevantes (fontes primárias) doados para o domínio público pelos seus autores ou entidades responsáveis. Dados brutos são mantidos em discos de preservação, e seus metadados descritivos são mantigos em repositórios *git*.

Nos repositórios *git* de cada país são registrados apenas:
* *input*: dados de gestão e **metadados dos arquivos doados** (principal ativo);
* *output*: relatórios e **sumarizações estatísticas** dos arquivos recebidos.

Cada *git* é publicado em um endereço permanente, distinguido pelo código do país, na forma `http://git.digital-guard.org/preserv-{isoCode}`. Por exemplo o *isoCode*  `BR` indica Brasil, ou seja, os metadados do Brasil estão em<br/>&nbsp; http://git.digital-guard.org/preserv-BR<br/>&nbsp; *Output* em ['/data/_out'](http://git.digital-guard.org/preserv-BR/tree/main/data/_out); *input* no restante da pasta ['/data'](http://git.digital-guard.org/preserv-BR/tree/main/data).

Metadados típicos são o número de bytes (*file size*), a data de aceitação ou registro, o tipo de arquivo (ex. `.zip` ou  `.gz`), o CNPJ da entidade doadora, o *hash* SHA256 do arquivo, etc.

Os arquivos de dados, por serem [grandes](https://git-lfs.github.com/),  têm as suas cópias armazenadas em diversos locais seguros, para fins de preservação, e em núvem através de serviço de [*storage* "frio"](https://en.wikipedia.org/wiki/File_hosting_service#Storage_charges), acessível para *download* em `DL.digital-guard.org/{hash}`, conforme a *hash* SHA256 do arquivo solicitado. Por exemplo  

<!-- ou seja, onde não há o compromisso de recuperação instantânea, mas dentro de um prazo de segundos a horas o *download* do arquivo é disponibilizado.-->

Em particular os dados de domínio público são registrados e armazenados também na [Fundação Biblioteca Nacional](https://www.bn.gov.br/sobre-bn/deposito-legal), na forma de [DVD durável](https://en.wikipedia.org/wiki/M-DISC), anexo a obras descritivas dos metadados, submetidas ao depósito legal.


<!-- Os metadados relativos a datasets são relativos ao arquivo comprimido contendo um ou mais pacotes de dados preservados (doação), relativos a um doador e uma data específicos. -->

<!--
Vide pasta `/data` deste git.
Os relatórios são como um blog de anúncio de atos de registro, em geral com um resumo para apresentar também os metadados. Vide pasta `/reports` deste git. -->

-----
## CONCEITOS
Apresentação dos principais conceitos e diretivas adotadas no Projeto Digital-guard de _preservação digital_.

### Fontes primárias

As [fontes de dados primárias](https://en.wikipedia.org/wiki/Primary_source) podem ter diversas origens e diferentes metodologias de coleta. De especial interesse para o Instituto ITGS, num contexto de preservação de longo prazo (décadas), são as fontes de dados relativos a endereços postais de cada município do Brasil. Cada fonte consiste de um conjunto de dados sistematizados e publicados **por uma instituição** (nacional ou internacional) com idoniedade reconhecida pela comunidade local.

As fontes primárias estão relacionadas aos [dados brutos](https://en.wikipedia.org/wiki/Raw_data), quando tidos como ["verdade de campo" ou  "verdade oficial"](https://wiki.openstreetmap.org/wiki/Ground_truth_and_Official_truth), e com o trabalho mobilizado pela instituição para sistematizar, consolidar ou transformar os dados brutos em dados geográficos consistentes. Dois exemplos ilustrativos:

* Um carteiro com seu [GPS](https://en.wikipedia.org/wiki/Global_Positioning_System), confirmando que o endereço de entrega existe e está localizado nas coordenadas de latitude e longitude indicadas pelo GPS. Diversos carteiros, entregadores e outros profissionais podem alimentar uma planilha e essa planilha por fim, publicada como [**arquivo CSV**](https://en.wikipedia.org/wiki/Comma-separated_values), será a nossa fonte primária de dados.

* [Imagens de satélite](https://en.wikipedia.org/wiki/Remote_sensing) são dados brutos. Os lotes, rios e vias são desenhados sobre a imagem a partir de softwares confiáveis assistidos por pessoas habilidadas, e que terão seu trabalho publicado (na forma por exemplo de [**arquivos&nbsp;GeoJSON**](https://en.wikipedia.org/wiki/GeoJSON)) por instituições que "assinam embaixo" desse trabalho, tais como o IBGE, a Fundação OpenStreetMap, o departamento de cartografia de uma grande prefeitura, e muitos outros. <br/>Mesmo tendo  usado a mesma imagem como origem, os produtos (ex. arquivos GeoJSON resultantes) podem diferir bastante em termos de qualidade, metodologia de interpretação, modelagem dos dados e software de interpretação, de modo que **cada produto de interpretação da imagem é considerado uma fonte primária distinta**.

#### Fontes OpenStreetMap Geofabrik

O [mapa OSM](https://www.openstreetmap.org/about) cobre todo o planeta, é mantido pela [Openstreetmap Foundation](https://blog.osmfoundation.org/about/), uma fundação inglesa registrada sob *Company Registration Number 05912761*.

O [planeta inteiro](https://planet.openstreetmap.org/) é uma massa de dados tão grande que inviabiliza filtragem de dados específicos. Diversos recortes do mapa OSM são [gerados por membros da OSMF](https://wiki.openstreetmap.org/wiki/Planet.osm), entre eles a  [empresa alemã, Geofabrik](https://www.geofabrik.de/geofabrik/openstreetmap.html) (*USt-Id DE222535480*). Seus recortes são considerados fiáveis e utilizados por governos e empresas por todo o mundo, portanto  amplamente auditados. Por orientação do projeto  [OSM-Stable Brasil](https://github.com/OSMBrasil/stable) ([docs](http://addressforall.org/osms/)),  o Instituto ITGS também  faz uso desses recortes.

Os metadados dos arquivos preservados estão descritos no *git* do projeto, [git/OSMBrasil/stable/brazil-latest.osm.md](https://github.com/OSMBrasil/stable/blob/master/brazil-latest.osm.md#dump-opensstreetmap-do-brasil).

#### Fontes IBGE

Fonte dos dados estatísticos oficiais do Brasil, bem como elementos de cartografia e localização de endereços. O IBGE - Instituto Brasileiro de Geografia e Estatística (*CNPJ  33.787.094/0001-40*).

Por ser uma fonte muito extensa, requer  [curadoria e decisões de projeto](http://git.digital-guard.org/preserv-BR/issues/).

### Fontes nas prefeituras
Por ser uma fonte muito extensa e diversificada, requer  [curadoria e decisões de projeto](http://git.digital-guard.org/preserv-BR/issues/).

### Normalização das fontes

Os conjuntos de dados de cada fonte apresentam formatos e características de modelagem de dados distintas. Para que possam ser comparados entre si ou processados pelas ferramentas internas do AddressForAll, precisam estar todos obedecendo a um mesmo esquema, todos modelados com uma semântica.

A transformação que se aplica a um determinado conjunto de dados da *fonte primária* para chegar no modelo de dados padrão AddressForAll, é denominada **normalização**. A descrição da metodologia, dos algorímos, bem como os códigos-fonte do software de normalização, são todos também preservados, com a mesma perspectiva de longo prazo que os dados da fonte primária.

Todos os elementos da normalização são repositórios *git* com licença aberta e publicamente distribuidos, atualmente em https://github.com/AddressForAll

### Depósito legal e preservação digital

O Depósito legal dos metadados e da normalização das fontes é realizado em dois meios complementares, tendo em vista que no Brasil os cartórios e o sistema jurídico ainda não são 100% digitais.

* **Depósito em blockchain** realizado previamente a cada confirmação de entrada, no "cartório digital" [Uniproof.com.br](https://uniproof.com.br/), garangtindo a integridade dos registros da licença e de integridade dos arquivos da fonte.

* **Depósito legal** realizado anualmente através da consolidação dos metados e códigos-fonte em um documento entitulado **"Inventário Anual  AddressForAll"**, junto à Fundação Biblioteca Nacional. O [*depósito legal* é um dispositivo previsto pelas leis federais nº 10.994 de 2004 e  nº 12.192 de 2010](https://www.bn.gov.br/sobre-bn/deposito-legal).

A preservação do arquivo em si (muitos Gigabytes) é feita por contratos de longo prazo (décadas), ainda em estudo. Uma vez no repositório definitivo, alguns parceiros se comprometem também com réplicas. PS: sistemas como  Filecoin ou LOCKSS, também em estudo, geram as réplicas de segurança automaticamente.

### Contexto

A *Plataforma de Projetos* do *Instituto ITGS* foi concebida para a gestão de projetos integrados e uso de um ecosistema de padrões e metodologias interoperáveis.
O presente projeto de preservação digital é um deles. Abaixo um diagrama que resume o passo-a-passo da preservação e como ele se relaciona com atividades de outros projetos.

![](https://github.com/AddressForAll/specifications/raw/master/docs/assets-spec02/image5.png)
