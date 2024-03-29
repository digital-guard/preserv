#!/usr/bin/env python3

##
## Runs Mustache template system using argv files, by terminal.
##

import chevron
import json
import yaml
import getopt
import os
import sys
from csv import DictReader

## ## ##
## Mustache-input Standard Library:
# class MsiStdLib:
def items_setLast(x, lstLabel='last'):
    if x:
        x[len(x) - 1][lstLabel] = True
# msi = MsiStdLib()


def load_data(file, loaderName='SafeLoader'):
    if loaderName == 'csv':
        return list(DictReader(file))
    else:
        try:
            loader = getattr(yaml, loaderName)    # not tested
            return yaml.load(file, Loader=loader)  # not tested
        except ImportError:
            return json.load(file)


def main(argv):
    basepath_default = '/var/gits/_dg/'
    basepath_arg = ''
    partials_path = 'preserv/src/maketemplates/'
    fname_input0 = ''
    fname_input = ''
    fname_mustache = ''
    fname_mustacheLast = ''
    tpl_inline = ''
    json_inline = ''
    outputfile = ''
    flag_except = False
    flag_csv = False
    str_outputfile = ''
    str_help = "Use the filenames --tpl --input --csv --output --input0 --tplLast or its prefixes:\n " \
                        + argv[0] + " -t <template_file> -i <input_file> [-o <outputfile>]\n or\n " \
                        + argv[0] + " -t <template_file> -c <csv_file> [-o <outputfile>]\n or\n " \
                        + argv[0] + " --tpl_inline=\"etc\" --json_inline=\"etc\" etc"

    ## Seta flag se parâmetro não for reconhecido ou parâmetro necessário faltar
    try:
        opts, args = getopt.getopt(argv[1:], "ht:i:c:o:b:", ["tpl=", "input=", "input0=", "csv=", "output=", "tpl_inline=", "json_inline=", "tplLast=", "basepath="])
    except getopt.GetoptError:
        flag_except = True

    ## Trata a insuficiência de parâmetros de entrada.
    if len(argv) < 2:
        flag_except = True

    if flag_except and len(argv) >= 1:
        print("Please supply one or more arguments\n"+str_help)
        sys.exit(2)
    elif flag_except:
        print('!BUG ON ARGV!')
        sys.exit(2)

    ## Armazena os parâmetros de entrada. Compõe mensagem final e grava arquivos temporários com os códigos inline.
    for opt, arg in opts:
        if opt == '-h':
            print(str_help)
            sys.exit()
        elif opt in ("-b", "--basepath"):
            basepath_arg = arg
        elif opt in ("-t", "--tpl"):
            fname_mustache = arg
            str_outputfile += 'Input mustache file: ' + fname_mustache + '.\n'
        elif opt in ("-1", "--tplLast"):
            fname_mustacheLast = arg
        elif opt in ("-0", "--input0"):  # yaml
            fname_input0 = arg
        elif opt in ("-i", "--input"):  # json or yaml!
            fname_input = arg
            str_outputfile += 'Input JSON ot YAML file: ' + fname_input + '.\n'
        elif opt in ("-c", "--csv"):
            fname_input = arg
            str_outputfile += 'Input CSV file: ' + fname_input + '.\n'
            flag_csv = True
        elif opt in ("-o", "--ofile"):
            outputfile = arg
            str_outputfile += 'Output file: ' + outputfile + '.\n'
        elif opt == '--tpl_inline':
            tpl_inline = arg
        elif opt == '--json_inline':
            json_inline = arg

    ## Decide qual basepath será usado
    partials_path = (basepath_arg if basepath_arg else basepath_default) + partials_path

    ## Encerra o programa se caminhos de arquivos de entrada forem vazios ou não existirem.
    if not fname_mustache or not os.path.isfile(fname_mustache):
        print('ERR1. Template file not found: %s.' % fname_mustache)
        sys.exit(2)
    elif not fname_input or not os.path.isfile(fname_input):
        print('ERR2. Input file not found, no %s: %s.' % ('CSV' if flag_csv else 'JSON or YAML', fname_input))
        sys.exit(2)
    elif fname_input0 and not os.path.isfile(fname_input0):
        print('ERR3. input0 file not found: %s.' % fname_input0)
        sys.exit(2)
    elif fname_mustacheLast and not os.path.isfile(fname_mustacheLast):
        print('ERR4. mustacheLast file not found: %s.' % fname_mustacheLast)
        sys.exit(2)
    elif (not tpl_inline and json_inline) or (tpl_inline and not json_inline):
        print('ERR5. tpl_inline or json_inline not found.')
        sys.exit(2)

    ## Concatena input0 e input, transformando-os em dicionário
    if fname_input0:
        with open(fname_input0, 'r') as read_obj:
            dict_input0 = load_data(read_obj)

    if json_inline:
        dict_input = json.loads(json_inline)
    else:
        with open(fname_input, 'r') as read_obj:
            if flag_csv:
                dict_input = load_data(read_obj, loaderName='csv')
            else:
                dict_input = load_data(read_obj)

    if fname_input0:
        #listOfDict = dict_input0 | dict_input # merge dict python3.9+
        listOfDict = {**dict_input0, **dict_input}  # merge dict python3.5+
    else:
        listOfDict = dict_input

    ## Concatena mustache e mustacheLast, gerando o template
    if tpl_inline:
        template_begin = tpl_inline
    else:
        with open(fname_mustache, 'r') as read_obj:
            template_begin = read_obj.read()

    if fname_mustacheLast:
        with open(fname_mustacheLast, 'r') as read_obj:
            template_end = read_obj.read()

    if fname_mustacheLast:
        template = template_begin + template_end
    else:
        template = template_begin

    ## Finaliza a preparação dos dados para renderização
    if flag_csv:
        items_setLast(listOfDict)
    else:
        items_setLast(listOfDict['files'])
        listOfDict['layers_keys'] = [*listOfDict['layers'].keys()]
        listOfDict['joins'] = {}

        # flags que indicam tipo de method
        for key in listOfDict['layers'].keys():
            listOfDict['layers'][key]['isCsv'] = False
            listOfDict['layers'][key]['isOgr'] = False
            listOfDict['layers'][key]['isOgrWithShp'] = False
            listOfDict['layers'][key]['isShp'] = False

            if listOfDict['layers'][key]['method'] == 'shp2sql':
                listOfDict['layers'][key]['isShp'] = True
            elif listOfDict['layers'][key]['method'] == 'csv2sql':
                listOfDict['layers'][key]['isCsv'] = True
            elif listOfDict['layers'][key]['method'] == 'ogr2ogr':
                listOfDict['layers'][key]['isOgr'] = True
            elif listOfDict['layers'][key]['method'] == 'ogrWshp':
                listOfDict['layers'][key]['isOgrWithShp'] = True

        #let listWithSeparators = pureList.map( (x, i, arr) => x.toString()+((arr.length-1===i)? '':', ') );
        #let listOfObjects = pureList.map( x=> ({name:x}) )

            if key in listOfDict['layers'] and 'cad' + key in listOfDict['layers']:
                if listOfDict['layers'][key]['subtype'] == 'ext' and listOfDict['layers']['cad' + key]['subtype'] == 'cmpl':
                    if listOfDict['layers'][key]['join_id'] and listOfDict['layers']['cad' + key]['join_id']:
                        listOfDict['joins'][key] = {}
                        listOfDict['joins'][key]['layer'] = key + '_ext'
                        listOfDict['joins'][key]['cadLayer'] = 'cad' + key + '_cmpl'
                        listOfDict['joins'][key]['layerColumn'] = listOfDict['layers'][key]['join_id']
                        listOfDict['joins'][key]['cadLayerColumn'] = listOfDict['layers']['cad' + key]['join_id']
                        listOfDict['joins'][key]['layerFile'] = [x['file'] for x in listOfDict['files'] if x['p'] == listOfDict['layers'][key]['file']][0]
                        listOfDict['joins'][key]['cadLayerFile'] = [x['file'] for x in listOfDict['files'] if x['p'] == listOfDict['layers']['cad' + key]['file']][0]


            if key == 'geoaddress' and 'address' in listOfDict['layers']:
                if listOfDict['layers'][key]['subtype'] == 'ext' and listOfDict['layers']['address']['subtype'] == 'cmpl':
                    if listOfDict['layers'][key]['join_id'] and listOfDict['layers']['address']['join_id']:
                        listOfDict['joins'][key] = {}
                        listOfDict['joins'][key]['layer'] = key + '_ext'
                        listOfDict['joins'][key]['cadLayer'] = 'address' + '_cmpl'
                        listOfDict['joins'][key]['layerColumn'] = listOfDict['layers'][key]['join_id']
                        listOfDict['joins'][key]['cadLayerColumn'] = listOfDict['layers']['address']['join_id']
                        listOfDict['joins'][key]['layerFile'] = [x['file'] for x in listOfDict['files'] if x['p'] == listOfDict['layers'][key]['file']][0]
                        listOfDict['joins'][key]['cadLayerFile'] = [x['file'] for x in listOfDict['files'] if x['p'] == listOfDict['layers']['address']['file']][0]

        listOfDict['joins_keys'] = [*listOfDict['joins'].keys()]

    ## Renderiza os dados e exibe ou salva os resultados.
    result = chevron.render(template, listOfDict, partials_path, 'mustache')

    if outputfile:
        print(str_outputfile)

        with open(outputfile, 'w') as text_file:
            text_file.write(result)
    else:
        print(result)


if __name__ == "__main__":
    main(sys.argv)
