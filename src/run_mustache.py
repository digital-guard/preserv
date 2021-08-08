#!/usr/bin/env python3

##
## Runs Mustache template system using argv files, by terminal.
##

import sys, os, getopt, pprint
import chevron
from   csv import DictReader

## ## ##
## Mustache-input Standard Library:
#class MsiStdLib:
def items_setLast(x,lstLabel='last'):
    if x:  x[ len(x) - 1 ][lstLabel] = True
#msi = MsiStdLib()

def load_data(file, loaderName='SafeLoader'):
    if loaderName == 'csv':
        return list( DictReader(read_obj) )
    else:
        try:
            import yaml
            loader = getattr(yaml, loaderName)     # not tested
            return yaml.load(file, Loader=loader)  # not tested
        except ImportError:
            import json
            return json.load(file)
## ## ##

def main(argv):
    basepath       = '/opt/gits/_a4a/'
    partials_path  = basepath + 'digital-preservation-BR/src/maketemplates/'
    fname_input0   = ''
    fname_mustache = '/tmp/run_mustache.mustache'
    fname_input    = '/tmp/run_mustache.json'
    outputfile     = ''
    tpl_inline     = ''
    json_inline    = ''
    str_help       = "Use the filenames --tpl --input --csv --output --input0 --tplLast or its prefixes:\n " \
                      + argv[0] + " -t <template_file> -i <input_file> [-o <outputfile>]\n or\n " \
                      + argv[0] + " -t <template_file> -c <csv_file> [-o <outputfile>]\n or\n " \
                      + argv[0] + " --tpl_inline=\"etc\" --json_inline=\"etc\" etc"
    str_outputfile = ''
    flag_except    = False
    flag_csv       = False
    #print(*argv)

    concatenate    = {
        'input':    {'fname': fname_input0,       'fname2': '/tmp/run_mustache.yaml',      'filenames': [fname_input0, fname_input]},
        'mustache': {'fname': fname_mustacheLast, 'fname2': '/tmp/run_mustache2.mustache', 'filenames': [fname_mustache, fname_mustacheLast]}
    }

    ## Seta flag se um parâmetro não for reconhecido ou faltar uma
    try:
        opts, args = getopt.getopt(argv[1:],"ht:i:c:o:b:",["tpl=","input=","input0=","csv=","output=","tpl_inline=","json_inline=","tplLast=","basepath="])
    except getopt.GetoptError:
        flag_except=True

    ## Trata a insuficiência de parâmetros de entrada.
    if len(argv) < 2:
        flag_except=True

    if flag_except and len(argv) >= 1:
        print ("Please supply one or more arguments\n" + str_help)
        sys.exit(2)
    elif flag_except:
        print ('!BUG ON ARGV!')
        sys.exit(2)

    ## Armazena os parâmetros de entrada. Compõe mensagem final e grava arquivos temporários com os códigos inline.
    for opt, arg in opts:
        if opt == '-h':
            print (str_help)
            sys.exit()
        elif opt in ("-b","--basepath"):
            basepath = arg
        elif opt in ("-t","--tpl"):
            fname_mustache = arg
            str_outputfile += 'Input mustache file: ' + fname_mustache + '.\n'
        elif opt in ("-1","--tplLast"):
            fname_mustacheLast = arg
        elif opt in ("-0","--input0"): # yaml
            fname_input0 = arg
        elif opt in ("-i","--input"):  # json or yaml!
            fname_input = arg
            str_outputfile += 'Input JSON ot YAML file: ' + fname_input + '.\n'
        elif opt in ("-c","--csv"):
            fname_input = arg
            flag_csv = True
            str_outputfile += 'Input CSV file: ' + fname_input + '.\n'
        elif opt in ("-o","--ofile"):
            outputfile = arg
            str_outputfile += 'Output file: ' + outputfile + '.\n'
        elif opt == '--tpl_inline':
            tpl_inline = arg
            f = open(fname_mustache, 'w')
            f.write(tpl_inline)
            f.close()
        elif opt == '--json_inline':
            json_inline = arg
            f = open(fname_input, 'w')
            f.write(json_inline)
            f.close()

    ## Encerra o programa se caminhos de arquivos de entrada forem vazios ou não existirem.
    if fname_mustache == '' or not os.path.isfile(fname_mustache):
        print ('ERR1. Template file not found: %s.' % fname_mustache)
        sys.exit(2)
    elif fname_input == '' and not os.path.isfile(fname_input):
        print ('ERR2. Input file not found, no %s: %s.' % ('CSV' if flag_csv else 'JSON or YAML',fname_input))
        sys.exit(2)

    ## Concatena input0 e input ou mustache e mustacheLast, se input0 ou mustacheLast forem recebidos.
    for key in concatenate:
        if concatenate[key]['fname'] > '':
            import fileinput
            fname2 = concatenate[key]['fname2']

            with open(fname2, 'w') as fout, fileinput.input(concatenate[key]['filenames']) as fin:
                for line in fin:
                    fout.write(line)

            fout.close()

            ## Atualiza o caminho do arquivo
            if key == 'input':
                fname_input = fname2
            elif key == 'mustache':
                fname_mustache = fname2

    ## Prepara input para renderização
    with open(fname_input, 'r') as read_obj:
        if flag_csv:
            listOfDict = load_data(read_obj,loaderName='csv')
            items_setLast(listOfDict)
        else:
            listOfDict = load_data(read_obj)
            items_setLast(listOfDict['files'])
            listOfDict['layers_keys'] = [*listOfDict['layers'].keys()]
            # a cada key indicar se method é shp ou csv, criando flags isCsv e isShp
            #let listWithSeparators = pureList.map( (x, i, arr) => x.toString()+((arr.length-1===i)? '':', ') );
            #let listOfObjects = pureList.map( x=> ({name:x}) )

    ## Renderiza os dados e exibe ou salva os resultados.
    with open(fname_mustache, 'r') as tpl:
        result = chevron.render( tpl, listOfDict, partials_path, 'mustache' )

    if outputfile > '':
        print (str_outputfile)
        with open(outputfile, 'w') as text_file:
            text_file.write(result)
    else:
        print(result)

###

if __name__ == "__main__":
    main(sys.argv)
