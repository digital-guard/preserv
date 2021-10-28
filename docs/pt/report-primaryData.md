## Relatório de dados das fontes primárias

Confira a **Listagem dos downloads** ordenada:
- [por Jurisdição](list-primaryData-byJurisdic.md)
- [por Hash](list-primaryData-byHash.md)

-----

## Geração por filesystem

As listagens podem ser obtidas por API do banco de dados, ou, a título de auditoria, por *filesystem*. Em seguida, independente da forma como foi gerada, a listagem pode ser gravada como documento estático.

Para gerar a listagem de arquivos [preservados por jurisdição](https://github.com/digital-guard/preserv/wiki/Listagem-dos-downloads-preservados-por-jurisdi%C3%A7%C3%A3o):

`find ~/a4a/preserv-{BR,CO,PE}/data/ -type f -name make_conf.yaml  -exec bash -c "echo {} | sed -r 's#.*preserv-([A-Z]{2})/data/(.*)/(make_conf.yaml)#- [\1 \2](https://github.com/digital-guard/preserv-\1/blob/main/data/\2/\3) #' ; grep -A1 -E "file:" {} | sed -e 's/^--//g' | sed -e 's/^[ \t]*//' | sed -e 's/^#.*//g' | sed -e '/^$/d' | sed 's/file:[ ][0-9]$/AAA/g' | grep -A1 "file:" | sed -r '$!N;s/file: ([a-fA-F0-9]{7})(.*)\nname: (.*)/\t- [\3 (\1)](http:\/\/dl.digital-guard.org\/\1\2)/' | sort " \; > lista.md`

Para gerar a listagem de arquivos [preservados por hash](https://github.com/digital-guard/preserv/wiki/Listagem-dos-downloads-preservados-por-hash):

```
commands() {
    LINKYAML=$(echo $1 | sed -r 's#.*preserv-([A-Z]{2})/data/(.*)/(make_conf.yaml)#: [\1 \2](https://github.com/digital-guard/preserv-\1/blob/main/data/\2/\3) #')

    LINE=$(grep -A1 -E "file:" $1 | sed -e 's/^--//g' | sed -e 's/^[ \t]*//' | sed -e 's/^#.*//g' | sed -e '/^$/d' | sed 's/file:[ ][0-9]$/AAA/g' | grep -A1 "file:" | sed -r '$!N;s#file: ([a-fA-F0-9]{7})(.*)\nname: (.*)#- [\1 (\3)](http:\/\/dl.digital-guard.org\/\1\2)'"$LINKYAML"'#' | sort)

    echo -e "$LINE\n"
};
export -f commands;
find ~/a4a/preserv-{BR,CO,PE}/data/ -type f -name make_conf.yaml -exec bash -c 'commands "$0"' {} \; | sort | sed -e '/^$/d' > lista.md``
```
