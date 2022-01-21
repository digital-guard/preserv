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
