#!/bin/bash

for folder in "$@" 
do
    echo "Diretório: ${folder}";
    chown -R postgres:www-data ${folder}
    find  ${folder} -type d -exec chmod 774 {} \;
    find  ${folder} -type f -exec chmod 664 {} \;
done

#para o plugin do mediaiki funcionar
chmod +x /var/www/addressforall.org/mediawiki/w/./extensions/SyntaxHighlight_GeSHi/pygments/pygmentize
