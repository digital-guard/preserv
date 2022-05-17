#!/bin/bash

pushd $1

path=$1
ftype="${path##*/}"

if [[ "$ftype" == "geoaddress" ]]
then
ftid=20
elif [[ "$ftype" == "parcel" ]]
then
ftid=60
elif [[ "$ftype" == "via" ]]
then
ftid=30
elif [[ "$ftype" == "nsvia" ]]
then
ftid=70
elif [[ "$ftype" == "block" ]]
then
ftid=80
elif [[ "$ftype" == "building" ]]
then
ftid=50
elif [[ "$ftype" == "genericvia" ]]
then
ftid=40
else
echo "No ftid."
fi

regex='.*pk([0-9]{1,})\.([0-9]{1,}).*$'

[[ $path =~ $regex ]] && packid=${BASH_REMATCH[1]}${BASH_REMATCH[2]}

psql postgres://postgres@localhost/$2 -c "INSERT INTO ingest.donated_packcomponent (packvers_id, ftid, lineage, lineage_md5) VALUES ($packid$ftid,$ftid,'{\"read\":\"cutgeo\"}','addressforall');"

find $path -type f -iname "*\_*.geojson*" -exec sh -c "psql postgres://postgres@localhost/$2 -c \"INSERT INTO ingest.feature_asis SELECT * FROM geojson_readfile_cutgeo('{}',$packid$ftid::bigint);\"" \;

popd
