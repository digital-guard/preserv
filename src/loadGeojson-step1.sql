CREATE or replace FUNCTION geojson_readfile_cutgeo(file text, packvers_id bigint) RETURNS TABLE (
  file_id int, feature_id int, properties jsonb, geom geometry
) AS $f$
    SELECT 
        file_id,
        subfeature_id+COALESCE(
            (
                SELECT MAX(feature_id)
                FROM ingest.feature_asis
                WHERE file_id= t3.file_id
            ),0) AS feature_id,
        properties,
        geom
    FROM
    (
        SELECT 
            (
                SELECT id
                FROM ingest.donated_packcomponent
                WHERE packvers_id=packvers_id
                LIMIT 1
            ) AS file_id,
            (ROW_NUMBER() OVER())::int AS subfeature_id,
            subfeature->'properties' AS properties,
            ST_GeomFromGeoJSON( '{"crs":{"type":"name","properties":{"name":"urn:ogc:def:crs:EPSG::4326"}}}'::jsonb || (subfeature->'geometry') ) AS geom
        FROM
        (
            SELECT jsonb_array_elements(j->'features') AS subfeature
            FROM 
                (
                    SELECT pg_read_file(file)::jsonb AS j
                ) jfile
        ) t2
    ) t3
$f$ LANGUAGE SQL;
