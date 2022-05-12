#!/bin/bash

crs=$(jq -nc --stream 'fromstream(1|truncate_stream(inputs| select(.[0][0] == "crs"))) | . , halt' "$1")

[ -z "$crs" ] && crs='{}'

#https://stackoverflow.com/a/70628468
jq -nc --stream --argjson size "$2" --argjson crs "${crs}" '
  def regroup(stream; $n):
    foreach (stream, null) as $x ({a:[]};
      if $x == null then .emit = .a
      elif .a|length == $n then .emit = .a | .a = [$x]
      else .emit=null | .a += [$x] end;
      select(.emit).emit);

    regroup(fromstream( 2 | truncate_stream(inputs | select(.[0][0] == "features" )) ); $size) | {"type": "FeatureCollection", "crs": $crs, "features": . }' "$1" | awk -v name=$1 '{fn++; print > "splited" fn "_" name}'
