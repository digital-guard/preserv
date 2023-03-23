# Conectar em um PostGis remoto com SSH e QGis

## Passo 1: Local Port Fowarding

### Para usários de sistema tipo unix

Redirecionar a porta do servidor onde roda o banco de dados (atualmente 5432) para uma porta local via túnel SSH:

```sh
ssh -L [porta_máquina_local]:localhost:[porta_banco_de_dados] nome_de_usuario@ipv4_ou_ipv6_do_servidor`
```

ou, se usar chaves SSH:

```sh
ssh -L [porta_máquina_local]:localhost:[porta_bancodedados] user@host -i caminho_da_chave
```

Exemplo

```sh
ssh -L 5555:localhost:5432 joao@192.0.2.0
```

Com isso o banco de dados na porta 5432 do servidor 192.0.2.0 pode ser acessado na porta 5555 da máquina local.


### Para usuários de windowns




## Passo 2: Adicionando e usando no QGIS

No navegador lateral clicar com o botão direito do mouse em _PostGIS_ (ícone de elefante) e em _nova conexão_.

Em seguida preencher os campos da nova conexão:

* Nome: postgis_remoto (por exemplo)
* Host: **localhost**
* Porta: **5555** (porta_máquina_local)
* Banco de dados: **ingestXX** (nome da base de dados)

Depois de preencher as informações da conexão, clicar no botão _OK_ e adicionar _usuário_ e _senha_ (ambos iguais a _postgres_)

<img align="right" src="../assets/postgis_remote_in_qgis.png"/>


Com isso todos os _schemas_ existentes na base de dados serão listados no navegador lateral.

<img align="right" src="../assets/postgis_remote_in_qgis1.png"/>


Ao expandir algum dos esquemas existentes as tabelas com geometrias estarão disponíveis para serem adicionadas como camadas ao projeto.

<img align="right" src="../assets/postgis_remote_in_qgis2.png"/>



##

Cada ingestão realizada gera um `file_id`:

<img align="right" src="../assets/ingest_output_example.png"/>

O `file_id` pode ser utilizado em conjuto com acapacidade de filtragem do QGIS para visualizar apenas as geometrias de um layer de interesse dentre as disponiveis na tabela `ingest.feature_asis`:

<img align="right" src="../assets/postgis_remote_in_qgis3.png"/>
