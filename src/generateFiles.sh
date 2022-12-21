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
    psql postgres://postgres@localhost/dl03t_main -c"INSERT INTO optim.donated_PackComponent_cloudControl(packvers_id,ftid,lineage_md5,hashedfname,hashedfnameuri,hashedfnametype) VALUES (${packvers_id},${ftid},'${lineage_md5}','${file_name_hash}','${url_cloud}','${file_type}') ON CONFLICT (packvers_id,ftid,lineage_md5) DO UPDATE SET hashedfname=EXCLUDED.hashedfname, hashedfnameuri=EXCLUDED.hashedfnameuri, hashedfnametype=EXCLUDED.hashedfnametype ;" && psql postgres://postgres@localhost/dl02s_main -c"INSERT INTO download.redirects(fhash,furi) VALUES ('${file_name_hash}','${url_cloud}') ;"
}

# gen_shapefile ingest99 1
gen_shapefile(){
    link_operacao='operacao:preserv.addressforall.org/download/'
    database=$1
    file_id=$2
    file_basename=$(psql postgres://postgres@localhost/${database} -qtAX -c "SELECT 'a4a_' || replace(lower(isolabel_ext),'-','_') || '_' || split_part(ftname,'_',1) || '_' || packvers_id FROM ingest.vw03full_layer_file WHERE id=${file_id} ")


    pushd /tmp/

    echo "Generating shapefile..."
    pgsql2shp -k -f ${file_basename}.shp -h localhost -u postgres -P postgres ${database} "$(psql postgres://postgres@localhost/${database} -qtAX -c "SELECT 'SELECT feature_id AS gid,' || CASE WHEN (SELECT properties FROM ingest.feature_asis WHERE file_id=${file_id} LIMIT 1) = '{}'::jsonb THEN '' ELSE array_to_string((SELECT  array_agg(('properties->''' || x || ''' AS ' || x)) FROM jsonb_object_keys((SELECT properties FROM ingest.feature_asis WHERE file_id=${file_id} LIMIT 1)) t(x)),', ') || ', ' END || ' geom FROM ingest.feature_asis WHERE file_id=${file_id};';")"

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

    echo "Upload to cloud..."
    sudo rclone copy ${file_name_hash} ${link_operacao}
    echo "Upload completed."

    echo "Get uri of cloud file..."
    url_cloud=$( sudo rclone link ${link_operacao}${file_name_hash})

    echo "File hash: ${file_name_hash}"
    echo "Link cloud: ${url_cloud}"

    echo "Update tables"
    update_tables ${file_id} ${database} ${file_name_hash} ${url_cloud} 'shp'

    echo "End. File available at /tmp/pg_io/${file_name_hash} or http://dl.digital-guard.org/${file_name_hash}"

    popd
}

# gen_csv ingest99 1
gen_csv(){
    # only geoaddress
    link_operacao='operacao:preserv.addressforall.org/download/'
    database=$1
    file_id=$2

    file_basename=$(psql postgres://postgres@localhost/${database} -qtAX -c "SELECT 'a4a_' || replace(lower(isolabel_ext),'-','_') || '_' || split_part(ftname,'_',1) || '_' || packvers_id FROM ingest.vw03full_layer_file WHERE id=${file_id} ")


    pushd /tmp/pg_io

    echo "Generating csv file..."
    [ -e ${file_basename}.csv ] && rm ${file_basename}.csv

    CMD_STRING=$(psql postgres://postgres@localhost/${database} -qtAX -c "SELECT 'SELECT feature_id AS gid,' || CASE WHEN (SELECT properties FROM ingest.feature_asis WHERE file_id=${file_id} LIMIT 1) = '{}'::jsonb THEN '' ELSE array_to_string((SELECT  array_agg(('properties->''' || x || ''' AS ' || x)) FROM jsonb_object_keys((SELECT properties FROM ingest.feature_asis WHERE file_id=${file_id} LIMIT 1)) t(x)),', ') || ', ' END || ' ST_X(geom) AS longitude, ST_Y(geom) AS latitude FROM ingest.feature_asis WHERE file_id=${file_id}'")

    COPY_STRING=$(echo COPY \( ${CMD_STRING} ORDER BY feature_id \) TO \'/tmp/pg_io/${file_basename}.csv\' CSV HEADER)

    psql postgres://postgres@localhost/${database} -c "${COPY_STRING}"


    file_name="${file_basename}.csv.zip"

    [ -e ${file_name} ] && rm ${file_name}

    echo "Creating zip file..."
    zip -r ${file_name} ${file_basename}.csv

    echo "Calculate zip file sha256sum ..."
    file_sha256sum=$( sha256sum -b ${file_name} | cut -f1 -d' ' )
    file_name_hash="${file_sha256sum}.zip"

    echo "Rename zip file to <sha256sum>.zip"
    mv ${file_name} ${file_name_hash}

    echo "Upload to cloud..."
    sudo rclone copy ${file_name_hash} ${link_operacao}
    echo "Upload completed."

    echo "Get uri of cloud file..."
    url_cloud=$( sudo rclone link ${link_operacao}${file_name_hash})

    echo "File hash: ${file_name_hash}"
    echo "Link cloud: ${url_cloud}"

    echo "Update tables"
    update_tables ${file_id} ${database} ${file_name_hash} ${url_cloud} 'csv'

    echo "End. File available at /tmp/pg_io/${file_name_hash} or http://dl.digital-guard.org/${file_name_hash}"
    popd
}
