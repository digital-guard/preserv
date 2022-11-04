
# Registro proveniência do *hostname* da doação *online*

> ✋ ESCOPO: procedimentos para registro de evidência da *proveniência* dos dados, comprovando-se a **enquivalência entre doador e  proprietário do endereço Internet que comparece na doação *online***.

Os arquivos preservados pela Digital-Guard podem ser provenientes de diferentes origens, tipicamente *download* de páginas oficiais do doador, e anexos de e-mail enviados por preposto oficial do doador.

Em ambos os casos a evidência primária de comprovação é o [**nome de domínio**](https://en.wikipedia.org/wiki/Domain_name): deve-se comprovar que o domínio vinculado à origem dos dados doados era propriedade do doador no instante da doação, garantindo que o **[*vatID*](https://schema.org/vatID) do proprietário** e o **<i>vatID</i> do suposto doador** são os mesmos naquela data. <!-- syntax de vatID com jurisdição em  https://www.websecurity.digicert.com/content/dam/websitesecurity/digitalassets/desktop/pdfs/repository/VAT-formats.pdf  -->

A relação entre domínio e *vatID* é, a princípio, garantida pelos protoclos [WHOIS](https://en.wikipedia.org/wiki/WHOIS) (antigo) e/ou [**RDAP**](https://en.wikipedia.org/wiki/Registration_Data_Access_Protocol) (moderno), que permitirem a identificação pública oficial do proprietário do domínio. No Brasil, por exemplo, o [Registro-BR](https://registro.br/) obriga a identificaçao e publica em ambos protocolos.

O *vatID* de cada país é diferente, por exemplo no Brasil é o [CNPJ](https://www.wikidata.org/wiki/Q15816867), na Argentina é o [CUIT](https://www.wikidata.org/wiki/Q5772290). Além disso o registro da relação entre domínio e *vatID* pode variar a cada país: apesar dos protoclo WHOIS e RDAP o permitirem, nem todos os países obrigam a transparência.

## Resumo dos procedimentos

A cada projeto de preservação digital de metadados, `git.digital-guard.ogr/preserv-{país}` (ex. [preserv-BR](http://git.digital-guard.org/preserv-BR) para Brasil), e a cado *hostname* (ex. `subsub.subdom.xpto.tipo.pais`) a ser comprovado:

1. Quebrar o *hostname* em domínio (`xpto.etc.pais`) e subdomínio (`subsub.subdom`) para análise na pasta `data/_donorEvidence` (ex. [preserv-BR/data/_donorEvidence](http://git.digital-guard.org/preserv-BR/tree/main/data/_donorEvidence)).

2. Se o **domínio** não existir, ou não estiver suficientemente atualizado (com mais de 6 meses é recomendada atualização), realizar os procedimentos:

   2.1. Criar a respectiva pasta se necessário;

   2.2. incluir ou atualizar o arquivo `rdap.json` ([exemplo](https://github.com/digital-guard/preserv-BR/blob/main/data/_donorEvidence/ac.gov.br/rdap.json));

   2.3. incluir ou atualizar o arquivo `webArchives.csv` ([exemplo](https://github.com/digital-guard/preserv-BR/blob/main/data/_donorEvidence/ac.gov.br/webArchives.csv)).

3. Se o **subdomínio** não existir na pasta do domínio, ou não estiver suficientemente atualizado, realizar os procedimentos:

   3.1. Criar a respectiva pasta se necessário ([exemplo](https://github.com/digital-guard/preserv-BR/tree/main/data/_donorEvidence/ac.gov.br/riobranco.ac.gov.br));

   3.2. incluir ou atualizar o arquivo `webArchives.csv` ([exemplo](https://github.com/digital-guard/preserv-BR/blob/main/data/_donorEvidence/ac.gov.br/riobranco.ac.gov.br/webArchives.csv)).

   3.3. incluir ou atualizar imagens de evidência   ([exemplo](https://github.com/digital-guard/preserv-BR/blob/main/data/_donorEvidence/sp.gov.br/prefeitura.sp.gov.br/localWhois-dominioSpGovBr-in2022-04-16.png)).

Em geral é suficiente comprovar domínio, para casos especiais o subdomínio e em casos muito especiais subsubdomínio. Neste Guia dada um desses casos será detalhado.

### Domínios e subdomínios a comprovar

As **[URLs](https://en.wikipedia.org/wiki/URL) que comparecem nos arquivos `donor.csv`** de registro de doador (ex. [preserv-BR/data/donor.csv](https://github.com/digital-guard/preserv-BR/blob/main/data/donor.csv)) **e `donatedPack.csv`** de registro de pacote doado (ex. [preserv-BR/data/donatedPack.csv](https://github.com/digital-guard/preserv-BR/blob/main/data/donatedPack.csv)) precisam ter a sua origem rastreada e comprovada.

Toda URL contém um [*hostname*](https://en.wikipedia.org/wiki/Hostname), fácilmente identificável pela sintaxe. Exemplos:

Exemplo de URL       | Hostname         | Nome de domínio
---------------------|------------------|-------------
`mailto:ibge@ibge.gov.br`   | `ibge.gov.br`    | `ibge.gov.br`
`https://www.ibge.gov.br/geociencias/downloads-geociencias.html` | `www.ibge.gov.br` |  `ibge.gov.br`
`mailto:fulano@prefeitura.sp.gov.br`   | `prefeitura.sp.gov.br`    | `sp.gov.br`
`http://geosampa.prefeitura.sp.gov.br` | `geosampa.prefeitura.sp.gov.br`    | `sp.gov.br`
`https://geoweb.vitoria.es.gov.br/#/shp` | `geoweb.vitoria.es.gov.br` | `es.gov.br`

A maior parte dos subdomínios não precisa ser comprovada, pois o responsável é o proprietário do domínio. A exceção são os subdomínios de grandes organizações. Aí surgem duas situações:

* organizações **com documentação pública *online*** (ou algo como um "WHOIS local") dos proprietários do subdomínio: podemos registrar essa documentação. <br/>Exemplo: evidências de responsabilidade do *vatID* (CNPJ) da Prefeitura de São Paulo sobre o subdomínio `prefeitura.sp.gov.br` através da imagem da [consulta ao WHOIS-PRODESP](https://github.com/digital-guard/preserv-BR/blob/main/data/_donorEvidence/sp.gov.br/prefeitura.sp.gov.br/localWhois-dominioSpGovBr-in2022-04-16.png) e da comprovação de [vínculo da PRODESP com o domínio `sp.gov.br`](https://github.com/digital-guard/preserv-BR/blob/main/data/_donorEvidence/sp.gov.br/webArchives.csv).

* organizações **sem documentação *online*** que comprove a responsabilidade do *vatID* sobre o subdomínio: ou os dados serão entendidos como pertecentes a uma instituição de nível superior (ex. internacional), ou um "certificado mais artezanal" deverá ser solicitado. <br/> Exemplo: o [Escritório de represemtação da UNESCO no Brasil](https://pt.unesco.org/fieldoffice/brasilia/about) tem CNPJ próprio (03.736.617/0001-68) mas não tem domínio próprio &mdash; supondo dados de [uis.unesco.org/en/country/br](http://uis.unesco.org/en/country/br), sem o devido certificado seriam tidos como de propriedade da UNESCO internacional.

-----

# GUIA DETALHADO

## Registro da evidência de domínio

Tanto e-mails como páginas Web são de responsabilidade do proprietário do domínio que figura na "transação de doação" (ato de *download* ou de envio de e-mail), conforme exemplos acima.

No Brasil os proprietários de domínio podem ter seu CNPJ comprovado através da consulta ao **WHOIS do Registro-BR**,<br/> https://registro.br/tecnologia/ferramentas/whois <br/>Todavia nem sempre será o CNPJ do responsável final. Podem haver encadeamentos formais de responsabilidade. Tradicionalmente os governos estaduais e governos municipais não são designados na Internet diretamente por um domínio, mas por **subdomínios** (parte final do *hostname*). Nos exemplos a prefeitura de São Paulo é subdomínio de `sp.gov.br` e a prefeitura de Vitória é subdomínio de `es.gov.br`.

Os **subdomínios `gov.br`** dos estados são gerenciados por autarquias independentes, listadas em https://iprefeituras.com.br/como-ter-dominio-governamental   <br/>No exemplo `sp.gov.br` é gerenciado pela PRODESP, que oferece seu "WHOIS de subdomínio" em https://www.dominio.sp.gov.br

### Exemplo do e-mail IBGE

Suponhamos um simples arquivo CSV zipado, `listaAbreviacoesSP.csv.zip`, como pacote doado. A lista de abreviações de 3 letras dos municípios de São Paulo foi obtida por um antigo e-mail de agente do IBGE que anexava a lista em correspondência remetida por `fulano@ibge.org.br`, ou seja, domínio `ibge.gov.br`, que pode ser consultado diretamente no WHOIS do Registro-BR:  https://registro.br/tecnologia/ferramentas/whois/?search=ibge.gov.br

&nbsp;&nbsp;![](../assets/ex02-RegistroBR-IBGE.png)

A imagem da ilustrações acima, que destaca a porção da página onde o domínio é associado ao `CNPJ 33.787.094/0001-40`,  já configura parte das evidências.  

### Exemplo do *download* GeoSampa

Como vimos na tabela acima, a URL da página de *downloads* do GeoSampa é um pouco mais complexo, http://geosampa.prefeitura.sp.gov.br  <br/>Ela requer que primeiro seja estabelecido o vínculo do gestor PRODESP com o domínio `SP.GOV.BR`.<br/>PS: se buscar `geosampa.prefeitura.sp.gov.br` o resultado será o mesmo.

&nbsp;&nbsp;![](../assets/ex03-DomainOwnner_evidence-SP-Sampa.png)

Coletada essa evidência, que pode ser comum a diversos outros doadores, **estaremos comprovando o vínculo entre o domínio `sp.gov.br` e o `CNPJ 62.577.929/0001-35`** da PRODESP.  <br/>NOTA: o uso de serviços não-oficiais tais como Google ou [IPrefeituras/dominio-governamental](https://iprefeituras.com.br/como-ter-dominio-governamental) é meramente confirmativo e informal, não tem valor jurídico.

Em seguida consultamos a página (de responsabilidade da PRODESP) que faz  papel de "WHOIS de `sp.gov.br`", https://www.dominio.sp.gov.br <br/> NOTA: se por azar não houvesse, seria necessária a consulta por e-mail ou eSIC, como no caso de `es.gov.br`.

&nbsp;&nbsp;![](../assets/ex04-SubDomainOwnner_evidence-SP-Sampa-prefeitura.png)

Evidencia-se por fim a relação entre o subdomínio `prefeitura.sp.gov.br` e o `CNPJ 46.392.080/0001-79` da Prefeitura, que é a o doador e responsável pelo GeoSampa.

### Exemplos de redirecionamento

Numa URL do tipo HTTP a *pasta* (também dita "diretório"), `http://dominio/pasta`, e o *subdomínio*, `http://subdomínio.domínio` são maneiras alternativas de se isolar um certo conteúdo e suas sub-páginas (tipicamente um sufixo `/subPasta`). Com frequência os administradores do *website* mudam esses endereços ao longo do tempo, inclusive intercambiando formas de representação, ora em pasta ora em subdomínio.

Para aproveitar nomes mais curtos ou populares, ou para evitar que antigas URLs se percam (ex. URL no interior das páginas de um CD-ROM ou de um arquivo PDF), os administradores de *websites* podem fazer uso da técnica conhecida como [*redirecionamento de URL*](https://en.wikipedia.org/wiki/URL_redirection), que consiste em renomear a página, direcionando o navegante para o novo nome. Exemplos:

* o domínio `OSM.org`, mais curto, é redirecionado para `OpenStreetMap.org`. Exemplo:<br/> https://OSM.org/copyright ⇒ `https://www.openstreetmap.org/copyright`

* o subdomínio `prefeitura.sp.gov.br`, utilizado no passado, foi redirecionado em 2020 para `capital.sp.gov.br`. Exemplo:<br/> https://prefeitura.sp.gov.br ⇒ `http://www.capital.sp.gov.br`

Esse tipo de situação é captada e certificada pelas "ferramentas de datação", discutidas a seguir. Comprovar será particularmente relevante quando a simples redução da URL não leva ao mesmo subdomínio. No  exemplo do subdomínio `geosampa.prefeitura.sp.gov.br` que não oferecia comprovação direta de `prefeitura.sp.gov.br` na data do *download*, devido ao redirecionamento.

## Datação da evidência

> ✋ ESCOPO: registro de "cópia e datação oficial" de uma página Web, feita por robôs de [*arquivamento da web*](https://en.wikipedia.org/wiki/Web_archiving).

Como os domínios podem mudar de proprietário ao longo dos anos, **é importante comprovar que outra testemunha tenha "visto" a mesma pǵanina no mesmo dia**. O interessante é que essas testemunhas estejam fazendo uso de outra rede de acesso à Internet, o que pode ser garantido quando o acesso se dá em outro país. E não importa se a "testemunha" é um ser humano ou um robô. O que importa é que o seu papel e seu relógio sejam formalmente reconhecidos &mdash; pelo Sistema Jurídico ou auditoria a que o *dataset* for submetido.

Atualmente dois robôs estrangeiros são reconhecidos:

* `web.archive.org`, também conhecido como [Wayback Machine](https://en.wikipedia.org/wiki/Wayback_Machine), e com algum histórico de utilização em tribunais. Apesar de pioneiro e amplamente reconhecido, tecnicamente vem apresentado instabilidades, o que não permite mais que seja o único robô de registro a se utilizar. Para gravar uma URL nova ou atualiza-la, usar<br/> https://web.archive.org/save

* [`archive.ph`](https://archive.ph), mais moderno e funcional porém menos popular, também conhecido com [Archive Today](https://en.wikipedia.org/wiki/Archive.today). Permite o registro de págnas com conteúdo Javascript, tais como o WHOIS do Registro-BR e interfaces com mapas.

* Usando o *software* aberto [pywb](https://github.com/webrecorder/pywb) a Digital-Guard pode no futuro realizar sua própria cópia de segurança para garantir todas as formas de registro.

### Exemplos e procedimentos

No https://Archive.Today basta copiar e colar a URL na caixa da opção *"My url is alive and I want to archive its content"* e clicar no botão "SAVE":

![](../assets/howTo02-ArchiveToday-workflow01.png)

O resultado do registro de `http://geosampa.prefeitura.sp.gov.br` em 15/04/2022 foi  https://archive.is/UBFqu

O mesmo foi feito com a página do Registro-BR com a consulta ao domínio `sp.gov.br`, que resultou em  https://archive.ph/eRrvE  com todos os conteúdos vizíveis e também gravados na forma de imagem *screenshot*.

No tradicional **Web Archive** deve-se utilizar https://web.archive.org/save as mesmas consultas foram realizadas, resultando em conteúdos parciais (javascript ausentes), portanto um registro menos efetivo:

* Consulta à página `www.dominio.sp.gov.br/dominiospgovbr/` em 2022-04-15 resultou em  http://web.archive.org/web/20220415184630/https://www.dominio.sp.gov.br/dominiospgovbr/

* Consulta à página `www.dominio.sp.gov.br/dominiospgovbr/` em 2022-04-15 resultou em  http://web.archive.org/web/20220415184630/https://www.dominio.sp.gov.br/dominiospgovbr/

* Consulta à página  `registro.br/tecnologia/ferramentas/whois/?search=sp.gov.br` em 2022-04-16 resultou em  http://web.archive.org/web/20220416151237/https://registro.br/tecnologia/ferramentas/whois/?search=sp.gov.br

* Consulta a `http://geosampa.prefeitura.sp.gov.br` em , http://web.archive.org/web/20220416151443/http://geosampa.prefeitura.sp.gov.br/PaginasPublicas/_SBC.aspx

* consulta a http://prefeitura.sp.gov.br  em http://web.archive.org/web/20220416151730/http://www.capital.sp.gov.br/

O Web Archive oferece problemas para os diversos casos, tanto de redirecionamento como de conteúdo dinâmico Javascript. Portanto a recomendação é usar o ArchiveToday.

## Evidências adicionais

Apresar de não ser imprescindível, pode-se agregar valor comprobatório através de evidências de que o site do domínio requerido pertence à entidade doadora.

Exemplo:  os *websites* do IBGE (https://ibge.gov.br) e da Prefeitura de São Paulo (https://prefeitura.sp.gov.br), apesar de não oferecerem página de auto-identificação (algo como "quem somos"), fazem uso consistente do nome oficial e sua logomarca.

![](../assets/ex05-Screenshot-DlIBGE.png)

<!--
Quando o doador oferece diretamente em suas páginas
http://geosampa.prefeitura.sp.gov.br

https://web.archive.org/web/*/http://geosampa.prefeitura.sp.gov.br


A comprovação do CNPJ de origem é feita pelo WHOIS,

https://registro.br/tecnologia/ferramentas/whois/?search=geosampa.prefeitura.sp.gov.br

que infelizmente não é uma página HTML, é só um acesso tipo ReactJS aos dados da API:

http://web.archive.org/web/20220415104902/https://registro.br/tecnologia/ferramentas/whois/?search=geosampa.prefeitura.sp.gov.br

por isso precisamos fazer um save-screen

-----

![](../assets/ex01-DL_evidence-SP-Sampa2020.png)

![](../assets/howTo01-WebArchiveRegister-workflow01.png)

![](../assets/ex03-DomainOwnner_evidence-SP-Sampa2020.png)
-->


------------------------

## Automação assistida com make

### RDAP

A inclusão dos arquivos `rdap.json` na pasta `/_donorEvidence`  ainda não é 100% automática, mas [foi](https://github.com/digital-guard/preserv/issues/124#issuecomment-1304302903) em sua maior parte automatizada.

O target a seguir gera uma lista de comandos para criar os diretórios, se necessário, e obter o rdap.json.

```
pushd /var/gits/_dg/preserv/src
make cmd_rdap iso=br pg_datalake=dl03t_main
```
Exemplo de output:

```sh
make cmd_rdap iso=br pg_datalake=dl03t_main
Generate list of commands to update or create rdap.json
for donor and donatedPack
Usage: make cmd_rdap iso=<ISO 3166 country code> pg_datalake=<database>
[Press ENTER to continue or Ctrl+C to quit]

commandline_rdap                                                                                                                                                                                   
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 mkdir -p /var/gits/_dg/preserv-BR/data/_donorEvidence/org/addressforall.org && rdap -v -j addressforall.org > /var/gits/_dg/preserv-BR/data/_donorEvidence/org/addressforall.org/rdap.json
 mkdir -p /var/gits/_dg/preserv-BR/data/_donorEvidence/br/com.br/clicksistema.com.br && wget https://rdap.registro.br/domain/clicksistema.com.br > /var/gits/_dg/preserv-BR/data/_donorEvidence/br/com.br/clicksistema.com.br/rdap.json
 mkdir -p /var/gits/_dg/preserv-BR/data/_donorEvidence/br/com.br/correios.com.br && wget https://rdap.registro.br/domain/correios.com.br > /var/gits/_dg/preserv-BR/data/_donorEvidence/br/com.br/correios.com.br/rdap.json

...

 mkdir -p /var/gits/_dg/preserv-BR/data/_donorEvidence/br/gov.br/sp.gov.br/sorocaba.sp.gov.br && wget https://rdap.registro.br/domain/sorocaba.sp.gov.br > /var/gits/_dg/preserv-BR/data/_donorEvidence/br/gov.br/sp.gov.br/sorocaba.sp.gov.br/rdap.json
(109 rows)

(END)
```
Por exemplo, os comandos

```sh
 mkdir -p /var/gits/_dg/preserv-BR/data/_donorEvidence/org/addressforall.org && rdap -v -j addressforall.org > /var/gits/_dg/preserv-BR/data/_donorEvidence/org/addressforall.org/rdap.json
 mkdir -p /var/gits/_dg/preserv-BR/data/_donorEvidence/br/gov.br/sp.gov.br/sorocaba.sp.gov.br && wget https://rdap.registro.br/domain/sorocaba.sp.gov.br > /var/gits/_dg/preserv-BR/data/_donorEvidence/br/gov.br/sp.gov.br/sorocaba.sp.gov.br/rdap.json
```

geram a seguinte estrutura de diretórios:

```sh
/var/gits/_dg/preserv-BR/data/_donorEvidence/
├── README.md
├── br
│   ├── gov.br
│   │   └── sp.gov.br
│   │       └── sorocaba.sp.gov.br
│   │           └── rdap.json
└── org
    └── addressforall.org
        └── rdap.json
```

_**Tomar os seguintes cuidados**_:
- Se já existir um rdap.json, não atualizá-lo. Se necessário, mover o atual para a estrutura de diretório criada pelo comando fornecido pelo target;
- Conforme comentário acima, nem sempre o `rdap` vai retornar uma resposta. Reportar esses casos.

**IMPORTANTE**:

Os valores _(anexo de email)_  presentes na coluna `uri` de [donatedPack.csv](https://github.com/digital-guard/preserv-BR/blob/main/data/donatedPack.csv) devem ser substituídos pelo respectivo email, conforme [Domínios e subdomínios a comprovar](https://github.com/digital-guard/preserv/blob/main/docs/pt/evidenceProvenance.md#dom%C3%ADnios-e-subdom%C3%ADnios-a-comprovar).

### APIs de Datação
Conforme apresentados acima, os procedimentos para [datação-da-evidência](#datação-da-evidência) dependem de como cada "cartório Web" os define. Pendente pesquisar. Por exempo Web Archive oferece indiretamente [bulk-upload com software Python](https://www.sucho.org/ia-bulk-upload).  
