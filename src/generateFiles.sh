#!/bin/bash

update_tables(){
    file_id=$1
    database=$2
    file_namezip=$3
    url_cloud=$4
    file_type=$5

    id_pack=$(psql postgres://postgres@localhost/${database} -qtAX -c "SELECT packvers_id, ftid, lineage_md5 FROM ingest.donated_packcomponent WHERE id=${file_id}")

    packvers_id=$(cut -d'|' -f1 <<< ${id_pack})
    ftid=$(cut -d'|' -f2 <<< ${id_pack})
    lineage_md5=$(cut -d'|' -f3 <<< ${id_pack})

    echo "Insert infos in optim.donated_PackComponent_cloudControl..."
    psql postgres://postgres@localhost/dl03t_main -c"SELECT optim.insert_cloudControl (${packvers_id}::bigint,${ftid}::smallint,'${lineage_md5}','${file_namezip}','${url_cloud}','${file_type}');"
}

# gen_shapefile ingest99 1 true
gen_shapefile(){
    link_operacao='operacao:preserv.addressforall.org/download/'
    database=$1
    file_id=$2
    up_cloud=$3
    file_basename=$4

    file_namezip=${file_basename}.zip

    pushd /tmp

    [ -d ${file_basename} ] && rm -rf ${file_basename}
    [ -e ${file_namezip} ]  && rm ${file_namezip}

    mkdir ${file_basename}

    echo "Generating ziped shapefile..."
    pgsql2shp -r -k -f ${file_basename}/${file_basename} -h localhost -u postgres -P postgres ${database} "$(psql postgres://postgres@localhost/${database} -qtAX -c "SELECT ingest.feature_asis_export_shp_cmd(${file_id});")"

    zip -r ${file_namezip} ${file_basename}

    if [ "${up_cloud}" = true ]; then
        echo "Upload and get uri cloud..."
        sudo rclone copy ${file_namezip} ${link_operacao}

        url_cloud=$( sudo rclone link ${link_operacao}${file_namezip})

        update_tables ${file_id} ${database} ${file_namezip} ${url_cloud} 'shp'

        echo "File available at: http://dl.digital-guard.org/out/${file_namezip}"
        echo "File available at: ${url_cloud}"
    fi

    rm -rf ${file_basename}

    echo "File available at: /tmp/${file_namezip}"
    echo "End."

    popd
}

# gen_csv ingest99 1 true
gen_csv(){
    # only geoaddress
    link_operacao='operacao:preserv.addressforall.org/download/'
    database=$1
    file_id=$2
    up_cloud=$3
    file_basename=$4
    file_namezip=${file_basename}_csv.zip

    echo "Generating ziped csv."

    pushd /tmp/pg_io

    [ -e ${file_basename}.csv ] && rm ${file_basename}.csv
    [ -e ${file_namezip} ]      && rm ${file_namezip}

    psql postgres://postgres@localhost/${database} -c "SELECT ingest.feature_asis_export_csv(${file_id}::bigint);"

    zip -r ${file_namezip} ${file_basename}.csv

    if [ "${up_cloud}" = true ]; then
        echo "Upload and get uri cloud..."
        sudo rclone copy ${file_namezip} ${link_operacao}
        url_cloud=$( sudo rclone link ${link_operacao}${file_namezip})

        update_tables ${file_id} ${database} ${file_namezip} ${url_cloud} 'csv'

        echo "File available at: http://dl.digital-guard.org/out/${file_namezip}"
        echo "File available at: ${url_cloud}"
    fi

    mv ${file_namezip} /tmp
    [ -e ${file_basename}.csv ] && rm ${file_basename}.csv

    echo "File available at: /tmp/${file_namezip}"
    echo "End."

    popd
}

# generate_filtered_files ingest99 1 true
generate_filtered_files(){
    database=$1
    file_id=$2
    uptocloud=$3

    result=$(psql postgres://postgres@localhost/${database} -qtAX -c "SELECT 'a4a_' || replace(lower(isolabel_ext),'-','_') || '_' || split_part(ftname,'_',1) || '_' || packvers_id, split_part(ftname,'_',1) FROM ingest.vw03full_layer_file WHERE id=${file_id} ")

    namefile=$(cut -d'|' -f1 <<< ${result})
    ftname=$(cut -d'|' -f2 <<< ${result})

    gen_shapefile ${database} ${file_id} ${uptocloud} ${namefile}

    if [[ "$ftname" == "geoaddress" ]]
    then
        gen_csv ${database} ${file_id} ${uptocloud} ${namefile}
    fi
}

# gen_all ingest62 7600008401 true
gen_all(){
    database=$1
    packtpl_id=$2
    uptocloud=$3

    echo "Generating all filtred."

    ids=$(psql postgres://postgres@localhost/${database} -qtAX -c "SELECT id FROM ingest.vw03full_layer_file WHERE pack_id=${packtpl_id} ")

    for id in ${ids}
    do
        generate_filtered_files ${database} ${id} ${uptocloud}
    done

    echo "End all filtred."
}
