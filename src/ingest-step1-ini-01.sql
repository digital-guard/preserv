CREATE or replace FUNCTION ingest.feature_asis_export(p_file_id bigint)
RETURNS TABLE (kx_ghs9 text, gid int, info jsonb, geom geometry(Point,4326)) AS $f$
DECLARE
    p_ftname text;
    sys_housenumber text;
    jproperties jsonb;
BEGIN
  SELECT ft_info->>'class_ftname', housenumber_system_type FROM ingest.vw03full_layer_file WHERE id=p_file_id
  INTO p_ftname, sys_housenumber;

  SELECT properties FROM ingest.feature_asis WHERE file_id=p_file_id LIMIT 1
  INTO jproperties;

  CASE
  WHEN ( p_ftname IN ('geoaddress', 'parcel') ) OR ( p_ftname IN ('building') AND ( (jproperties ?| ARRAY['via','hnum','sup']) ) ) THEN
  RETURN QUERY
  SELECT
        t.ghs,
        t.gid,
        CASE
        WHEN p_ftname IN ('parcel','building')
        THEN jsonb_strip_nulls(jsonb_build_object('address', address, 'name', name, 'nsvia', nsvia, 'postcode', postcode, 'type', type, 'error', error_code, 'info', infop, 'bytes', length(St_asGeoJson(t.geom))))
        ELSE jsonb_strip_nulls(jsonb_build_object('address', address, 'name', name, 'nsvia', nsvia, 'postcode', postcode, 'type', type, 'error', error_code, 'info', infop                                       ))
        END AS info,
        t.geom
  FROM
  (
      SELECT file_id, fa.geom, fa.feature_id::int AS gid, fa.kx_ghs9 AS ghs,

      properties->>'nsvia'    AS nsvia,
      properties->>'name'     AS name,
      properties->>'postcode' AS postcode,
      properties->>'type'     AS type,

      CASE WHEN (properties->>'is_agg')::boolean THEN 100 END AS error_code,
      COALESCE(nullif(properties->'is_complemento_provavel','null')::boolean,false) AS is_compl,

      NULLIF(properties - ARRAY['via','hnum','sup','postcode','nsvia','name','type'],'{}'::jsonb) AS infop,

      CASE sys_housenumber
      -- address: [via], [hnum]
      WHEN 'metric' THEN
        ROW_NUMBER() OVER(ORDER BY properties->>'via', to_bigint(properties->>'hnum'))
      WHEN 'bh-metric' THEN
        ROW_NUMBER() OVER(ORDER BY properties->>'via', to_bigint(regexp_replace(properties->>'hnum', '\D', '', 'g')), regexp_replace(properties->>'hnum', '[^[:alpha:]]', '', 'g') )
      WHEN 'street-metric' THEN
        ROW_NUMBER() OVER(ORDER BY properties->>'via', regexp_replace(properties->>'hnum', '[^[:alnum:]]', '', 'g'))
      WHEN 'block-metric' THEN
        ROW_NUMBER() OVER(ORDER BY properties->>'via', to_bigint(split_part(replace(properties->>'hnum',' ',''), '-', 1)), to_bigint(split_part(replace(properties->>'hnum',' ',''), '-', 2)))

        -- address: [via], [hnum], [sup     ]
        --          [via], [hnum], [[quadra], [lote]]
      WHEN 'ago-block' THEN
        ROW_NUMBER() OVER(ORDER BY properties->>'via', to_bigint(properties->>'hnum'), to_bigint(split_part(properties->>'sup', ',', 1)), to_bigint(split_part(properties->>'sup', ',', 2)) )

      -- address: [via], [sup]
      --          [[quadra], [lote]], [sup]
      WHEN 'df-block' THEN
        ROW_NUMBER() OVER(ORDER BY split_part(properties->>'via', ',', 1),split_part(properties->>'via', ',', 2),properties->>'sup')

      ELSE
        ROW_NUMBER() OVER(ORDER BY properties->>'via', to_bigint(properties->>'hnum'))
      END AS address_order,

      CASE sys_housenumber
      WHEN 'ago-block' THEN
      (
        -- address: [via], [hnum], [sup     ]
        --          [via], [hnum], [[quadra], [lote]]
        CASE WHEN ((trim(properties->>'via')  = '') IS FALSE) THEN trim(properties->>'via')  ELSE '?' END || ', ' ||
        CASE WHEN ((trim(properties->>'hnum') = '') IS FALSE) THEN trim(properties->>'hnum') ELSE '?' END || ', ' ||
        CASE WHEN ((trim(properties->>'sup')  = '') IS FALSE) THEN trim(properties->>'sup')  ELSE '?' END
      )
      WHEN 'df-block' THEN
      (
        -- address: [via], [sup]
        --          [[quadra], [lote]], [sup]
        CASE WHEN ((trim(properties->>'via')  = '') IS FALSE) THEN trim(properties->>'via')  ELSE '?, ?' END || ', ' ||
        CASE WHEN ((trim(properties->>'sup')  = '') IS FALSE) THEN trim(properties->>'sup')  ELSE '?' END
      )
      ELSE
      (
        -- address: [via], [hnum]
        CASE WHEN ((trim(properties->>'via')  = '') IS FALSE) THEN trim(properties->>'via')  ELSE '?' END || ', ' ||
        CASE WHEN ((trim(properties->>'hnum') = '') IS FALSE) THEN trim(properties->>'hnum') ELSE '?' END
      )
      END AS address
      FROM ingest.feature_asis AS fa
      WHERE fa.file_id=p_file_id
  ) t
  ORDER BY address_order;

  WHEN ( p_ftname IN ('block','via','genericvia','nsvia','blockface') ) OR ( p_ftname IN ('building') AND NOT ( (jproperties ?| ARRAY['via','hnum','sup']) ) ) THEN
  RETURN QUERY
  SELECT
        t.ghs,
        t.gid,
        jsonb_strip_nulls(jsonb_build_object(
          'type', type,
          'via', via,
          'nsvia', nsvia,
          'name', name,
          'postcode', postcode,
          'bytes',length(St_asGeoJson(t.geom)),
          'info', infop
        )) AS info,
        t.geom
  FROM (
      SELECT fa.file_id, fa.geom,
        fa.feature_id::int         AS gid,
        fa.properties->>'via'      AS via,
        fa.properties->>'type'     AS type,
        fa.properties->>'nsvia'    AS nsvia,
        fa.properties->>'name'     AS name,
        fa.properties->>'postcode' AS postcode,
        fa.kx_ghs9                 AS ghs,
        NULLIF(fa.properties - ARRAY['via','postcode','nsvia','name','type'],'{}'::jsonb) AS infop
      FROM ingest.feature_asis AS fa
      WHERE fa.file_id=p_file_id
  ) t
  ORDER BY type, via, nsvia, gid
  ;

  WHEN p_ftname IN ('datagrid') THEN
  RETURN QUERY
  SELECT
        t.ghs,
        t.gid,
        jsonb_strip_nulls(jsonb_build_object('bytes',length(St_asGeoJson(t.geom)))) || t.info  AS info,
        t.geom
  FROM (
      SELECT fa.file_id, fa.geom,
        fa.feature_id::int AS gid,
        fa.properties      AS info,
        fa.kx_ghs9         AS ghs
      FROM ingest.feature_asis AS fa
      WHERE fa.file_id=p_file_id
  ) t
  ORDER BY gid;
  END CASE;
END;
$f$ LANGUAGE PLpgSQL;
-- SELECT * FROM ingest.feature_asis_export(5) t LIMIT 1000;
