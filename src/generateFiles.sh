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

    psql postgres://postgres@localhost/dl03t_main -c"INSERT INTO optim.donated_PackComponent_cloudControl(packvers_id,ftid,lineage_md5,hashedfname,hashedfnameuri,hashedfnametype) VALUES (${packvers_id},${ftid},'${lineage_md5}','${file_name_hash}','${url_cloud}','${file_type}');" && psql postgres://postgres@localhost/dl02s_main -c"INSERT INTO download.redirects(fhash,furi) VALUES ('${file_name_hash}','${url_cloud}');"
}

# gen_shapefile a4a_co_pk0006_02_geoaddress ingest99 1
gen_shapefile(){
    link_operacao='operacao:preserv.addressforall.org/download/'
    file_basename=$1
    database=$2
    file_id=$3

    pushd /tmp/

    pgsql2shp -k -f ${file_basename}.shp -h localhost -u postgres -P postgres ${database} "$(psql postgres://postgres@localhost/${database} -qtAX -c "SELECT 'SELECT feature_id AS gid,' || array_to_string((SELECT  array_agg(('properties->''' || x || ''' AS ' || x)) FROM jsonb_object_keys((SELECT properties FROM ingest.feature_asis WHERE file_id=${file_id} LIMIT 1)) t(x)),', ') || ', geom FROM ingest.feature_asis WHERE file_id=${file_id} LIMIT 10;';")"

    mkdir ${file_basename}
    mv ${file_basename}.{shp,cpg,dbf,prj,shx} ${file_basename}

    file_name="${file_basename}.shp.zip"
    zip -r ${file_name} ${file_basename}
    file_sha256sum=$( sha256sum -b ${file_name} | cut -f1 -d' ' )
    file_name_hash="${file_sha256sum}.zip"
    mv ${file_name} ${file_name_hash}

    rm -rf ${file_basename}

    sudo rclone copy ${file_name_hash} ${link_operacao}

    url_cloud=$( sudo rclone link ${link_operacao}${file_name_hash})

    echo ${file_name_hash}
    echo ${url_cloud}

    update_tables ${file_id} ${database} ${file_name_hash} ${url_cloud} 'shp'

    popd
}

# gen_csv a4a_co_pk0006_02_geoaddress ingest99 1
gen_csv(){
    # only geoaddress
    link_operacao='operacao:preserv.addressforall.org/download/'
    file_basename=$1
    database=$2
    file_id=$3

    pushd /tmp

    CMD_STRING=$(psql postgres://postgres@localhost/${database} -qtAX -c "SELECT 'SELECT feature_id AS gid,' || array_to_string((SELECT  array_agg(('properties->''' || x || ''' AS ' || x)) FROM jsonb_object_keys((SELECT properties FROM ingest.feature_asis WHERE file_id=${file_id} LIMIT 1)) t(x)),', ') || ', ST_X(geom) AS longitude, ST_Y(geom) AS latitude FROM ingest.feature_asis WHERE file_id=${file_id}'")

    COPY_STRING=$(echo COPY \( ${CMD_STRING} ORDER BY feature_id LIMIT 10 \) TO \'/tmp/pg_io/${file_basename}.csv\' CSV HEADER)

    psql postgres://postgres@localhost/${database} -c "${COPY_STRING}"

    file_name="${file_basename}.csv.zip"
    zip -r ${file_name} /tmp/pg_io/${file_basename}.csv
    file_sha256sum=$( sha256sum -b ${file_name} | cut -f1 -d' ' )
    file_name_hash="${file_sha256sum}.zip"
    mv ${file_name} ${file_name_hash}

    sudo rclone copy ${file_name_hash} ${link_operacao}

    url_cloud=$( sudo rclone link ${link_operacao}${file_name_hash})

    echo ${file_name_hash}
    echo ${url_cloud}

    update_tables ${file_id} ${database} ${file_name_hash} ${url_cloud} 'csv'

    popd
}
