## Documentação do Projeto Preserv

Serão apresentados conceitos, especificações e um guia rápido para sanar dúvidas e indicar procedimentos. Conteúdo:

* [**Organização e conceitos do projeto**](organizacao.md)
* Modelo de dados:
   - [**Feature Types**](ftypes.md)
* Módulos:
   - [**Eclusa**](eclusa.md)
   - [**Jurisdiction**](jurisdiction.md)
* Manuais, guias ou tutoriais:
   - [**Manual do Git-update**](man-gitUpdate.md)
   - [**Guia do make_conf**](man-makeConf.md)
   - [**Diversos**](man-diversos.md)
   - [**Guia do sha256**](man-sha256.md)
* Relatórios:
   - [Dados primários preservados](report-primaryData.md)
   - [Listagem dos downloads por Jurisdição](list-primaryData-byJurisdic.md)
   - [Listagem dos downloads por Hash](list-primaryData-byHash.md)

## Elementos do repositório preserv

O repositório *git* do Projeto Preserv fica em http://git.digital-guard.org/preserv

Códicos-fonte em [`/srv`](http://git.digital-guard.org/preserv/tree/main/src):
* Eclusa: ...
* Jurisdiction: ...
* maketemplates: ...  

## Instalação do preserv

Use `make` depois de ter feito `clone` e `cd` para a pasta [`/srv`](http://git.digital-guard.org/preserv/tree/main/src).

Lembretes:

* src/pubLib.sql precisa ser unificado por inicialização de database, podendo ser centrado no projeto WS. Mais simples referenciar lista de funções controladas de uma publib previamente definida como projeto e versionando grupos de prefixo (array, io, jsonb, etc.). Com cada módulo demandando as suas.

* src relativo a database  "dl03t_main"
