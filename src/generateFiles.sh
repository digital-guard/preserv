#!/bin/bash

update_tables(){
    file_id=$1
    database=$2
    file_name_hash=$3
    url_cloud=$4
    file_type=$5

    id_pack=$(psql postgres://postgres@localhost/${database} -qtAX -c "SELECT packvers_id, ftid, lineage_md5 FROM ingest.donated_packcomponent WHERE id=${file_id}")

    packvers_id=$(cut -d'|' -f1 <<< ${id_pack})
    ftid=$(cut -d'|' -f2 <<< ${id_pack})
    lineage_md5=$(cut -d'|' -f3 <<< ${id_pack})

    echo "Update download.redirects..."
    psql postgres://postgres@localhost/dl03t_main -c"SELECT optim.insert_cloudControl (${packvers_id}::bigint,${ftid}::smallint,'${lineage_md5}','${file_name_hash}','${url_cloud}','${file_type}');"
}

# gen_shapefile ingest99 1 true
gen_shapefile(){
    link_operacao='operacao:preserv.addressforall.org/download/'
    database=$1
    file_id=$2
    up_cloud=$3

    file_basename=$(psql postgres://postgres@localhost/${database} -qtAX -c "SELECT 'a4a_' || replace(lower(isolabel_ext),'-','_') || '_' || split_part(ftname,'_',1) || '_' || packvers_id FROM ingest.vw03full_layer_file WHERE id=${file_id} ")

    pushd /tmp/

    echo "Generating shapefile..."
    pgsql2shp -r -k -f ${file_basename}.shp -h localhost -u postgres -P postgres ${database} "$(psql postgres://postgres@localhost/${database} -qtAX -c "SELECT ingest.feature_asis_export_shp_cmd(${file_id});")"

    mkdir ${file_basename}
    mv ${file_basename}.{shp,cpg,dbf,prj,shx} ${file_basename}

    echo "Creating zip file..."
    file_name="${file_basename}.shp.zip"
    zip -r ${file_name} ${file_basename}

    echo "Calculate zip file sha256sum ..."
    file_sha256sum=$( sha256sum -b ${file_name} | cut -f1 -d' ' )

    echo "Rename zip file to <sha256sum>.zip"
    file_name_hash="${file_sha256sum}.zip"
    mv ${file_name} ${file_name_hash}

    rm -rf ${file_basename}

    if [ "${up_cloud}" = true ]; then
        echo "Upload to cloud..."
        sudo rclone copy ${file_name_hash} ${link_operacao}
        echo "Upload completed."

        echo "Get uri of cloud file..."
        url_cloud=$( sudo rclone link ${link_operacao}${file_name_hash})

        echo "File hash: ${file_name_hash}"
        echo "Link cloud: ${url_cloud}"

        echo "Update tables"
        update_tables ${file_id} ${database} ${file_name_hash} ${url_cloud} 'shp'

        echo "End. File available at /tmp/${file_name_hash} or http://dl.digital-guard.org/${file_name_hash}."
    else
        echo "End. File available at /tmp/${file_name_hash}."
    fi

    popd
}

# gen_csv ingest99 1 true
gen_csv(){
    # only geoaddress
    link_operacao='operacao:preserv.addressforall.org/download/'
    database=$1
    file_id=$2
    up_cloud=$3

    echo "Generating csv file. ONLY for geoaddress!"

    file_basename=$(psql postgres://postgres@localhost/${database} -qtAX -c "SELECT 'a4a_' || replace(lower(isolabel_ext),'-','_') || '_' || split_part(ftname,'_',1) || '_' || packvers_id FROM ingest.vw03full_layer_file WHERE id=${file_id} ")

    pushd /tmp/pg_io

    [ -e ${file_basename}.csv ] && rm ${file_basename}.csv

    psql postgres://postgres@localhost/${database} -c "SELECT ingest.feature_asis_export_csv(${file_id}::bigint);"

    file_name="${file_basename}.csv.zip"

    [ -e ${file_name} ] && rm ${file_name}

    echo "Creating zip file..."
    zip -r ${file_name} ${file_basename}.csv

    echo "Calculate zip file sha256sum ..."
    file_sha256sum=$( sha256sum -b ${file_name} | cut -f1 -d' ' )
    file_name_hash="${file_sha256sum}.zip"

    echo "Rename zip file to <sha256sum>.zip"
    mv ${file_name} ${file_name_hash}

    if [ "${up_cloud}" = true ]; then
        echo "Upload to cloud..."
        sudo rclone copy ${file_name_hash} ${link_operacao}
        echo "Upload completed."

        echo "Get uri of cloud file..."
        url_cloud=$( sudo rclone link ${link_operacao}${file_name_hash})

        echo "File hash: ${file_name_hash}"
        echo "Link cloud: ${url_cloud}"

        echo "Update tables"
        update_tables ${file_id} ${database} ${file_name_hash} ${url_cloud} 'csv'

        echo "End. File available at /tmp/${file_name_hash} or http://dl.digital-guard.org/${file_name_hash}."
    else
        echo "End. File available at /tmp/${file_name_hash}."
    fi

    mv ${file_name_hash} /tmp

    popd
}

# generate_filtered_files ingest99 1
generate_filtered_files(){
    database=$1
    file_id=$2
    ftname=$(psql postgres://postgres@localhost/${database} -qtAX -c "SELECT split_part(ftname,'_',1) FROM ingest.vw03full_layer_file WHERE id=${file_id} ")

    gen_shapefile ${database} ${file_id} true

    if [[ "$ftname" == "geoaddress" ]]
    then
        gen_csv ${database} ${file_id} true
    fi
}

# gen_all ingest62 7600008401
gen_all(){
    database=$1
    packtpl_id=$2

    echo "Generating all filtred"

    ids=$(psql postgres://postgres@localhost/${database} -qtAX -c "SELECT id FROM ingest.vw03full_layer_file WHERE pack_id=${packtpl_id} ")

    for id in ${ids}
    do
        generate_filtered_files ${database} ${id}
    done
}
