O acesso ao servidor é realizado com o software de código aberto [Putty](https://www.putty.org/).

### Configuração do servidor

- Host Name (or IP address): addressforall.org

- Port: 22

- Connection type: SSH Telnet

### Login

Utilizando usuário e senha.

### Passo-a-passo

Este manual utiliza o arquivo `Num_Predial_14_03_2022.zip`, que está no endereço `Imput_Dados/Brasil/Prefeituras/PR/Maringa-Prefeitura/2022-03-21-email/`, como exemplo. É necessário substituir o arquivo e endereço.

1) Preencher `donor_id`, `filename_original` e `package_path` na **tabela de-para**.

2) Conferir se o arquivo está no endereço correto

```
rclone ls operacao:A4A_SHARED/Imput_Dados/Brasil/Prefeituras/PR/Maringa-Prefeitura/2022-03-21-email/
```

3) Utilizar o endereço completo do arquivo para gerar o endereço final

```
rclone link operacao:A4A_SHARED/Imput_Dados/Brasil/Prefeituras/PR/Maringa-Prefeitura/2022-03-21-email/Num_Predial_14_03_2022.zip
```

4) Preencher a coluna `para_url` da **tabela de-para** com o endereço final obtido em (3)

5) Copiar o arquivo para o servidor

```
rclone copy operacao:A4A_SHARED/Imput_Dados/Brasil/Prefeituras/PR/Maringa-Prefeitura/2022-03-21-email/Num_Predial_14_03_2022.zip .
```

6) Gerar o sha256

```
sha256sum -b Num_Predial_14_03_2022.zip
```

7) Preencher a coluna `de_sha256` da **tabela de-para** com o sha256 obtido em (6)

8) Atualizar o servidor

```
cd /var/gits/_dg/preserv/src
```

```
make redirects_update pg_datalake=dl02s_main
```

9) Conferir se o download do arquivo está funcionando corretamente

```
cd
```

```
wget dl.digital-guard.org/8884e9035116c647376301085809c7cbfb0d44841e1f51035b4b286e8648b05a.zip
```

ou

[dl.digital-guard.org/8884e9035116c647376301085809c7cbfb0d44841e1f51035b4b286e8648b05a.zip](dl.digital-guard.org/8884e9035116c647376301085809c7cbfb0d44841e1f51035b4b286e8648b05a.zip)

ou

[http://dl.digital-guard.org/8884e9](http://dl.digital-guard.org/8884e9)
