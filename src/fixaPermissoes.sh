#!/bin/bash

for folder in "$@" 
do
    echo "Diretório: ${folder}";
    chown -R postgres:www-data ${folder}
    find  ${folder} -type d -exec chmod 774 {} \;
    find  ${folder} -type f -exec chmod 664 {} \;
done
