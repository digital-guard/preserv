CREATE SCHEMA IF NOT EXISTS api;

-- https://github.com/PostgREST/postgrest/pull/2624
COMMENT ON SCHEMA "api" IS
$$AddressForAll API documentation

A RESTful API that serves AddressForAll data.
$$;

CREATE ROLE webanon nologin;
-- https://www.postgresql.org/docs/current/predefined-roles.html
GRANT pg_read_all_data TO webanon;

------------------

CREATE or replace VIEW api.jurisdiction AS
SELECT osm_id,
      jurisd_base_id,
      jurisd_local_id,
      name,
      parent_abbrev,
      abbrev,
      wikidata_id,
      lexlabel,
      isolabel_ext,
      ddd,
      jsonb_strip_nulls(info || jsonb_build_object('sys_housenumbering',housenumber_system_type,'sys_housenumbering_lex',lex_urn)) AS info
FROM optim.jurisdiction
ORDER BY jurisd_base_id, isolevel, name
;
COMMENT ON VIEW api.jurisdiction
  IS 'Returns list of jurisdictions from optim schema.'
;
--curl "http://localhost:3103/jurisdiction?jurisd_base_id=eq.76&parent_abbrev=eq.CE" -H "Accept: text/csv"
-- https://osm.codes/_sql.csv/jurisdiction?jurisd_base_id=eq.76&parent_abbrev=eq.CE

---------
-- Union de fdw_donor de todas as jurisdições
CREATE or replace VIEW api.donors AS
    SELECT * FROM tmp_orig.donors
;
COMMENT ON VIEW api.donors
  IS 'Raw data of donor.csv of all jurisdiction.'
;

-- Union de fdw_donatedpack X fdw_donor de todas as jurisdições
CREATE or replace VIEW api.donatedpacks_donor AS
    SELECT * FROM tmp_orig.donatedpacks_donor
;
COMMENT ON VIEW api.donatedpacks_donor
  IS 'Joining raw data from donatedPack.csv with donor.csv from all jurisdictions.'
;

--tabelão
CREATE or replace VIEW api.stats_donated_packcomponent AS
SELECT a.*,
    jurisdiction, pack_id, donor_id, pack_count, lst_vers, user_resp, accepted_date, scope, about, author, contentreferencetime, license_is_explicit, license, uri_objtype, uri, isat_urbigis, status, statusupdatedate, local_id, scope_label, vat_id, "legalName", wikidata_id, url, donor_date, donor_status,
    CASE
    WHEN license_is_explicit = 'yes' THEN 'explicit'
    WHEN license_is_explicit = 'no'  THEN 'implicit'
    ELSE ''
    END AS license_type,
    CASE
    WHEN license ~* '^CC0.*$' /*AND license_family IS NULL*/ THEN 'cc0'
    WHEN license ~* 'CC-BY'   /*AND license_family IS NULL*/ THEN 'by'
    WHEN license ~* 'ODbL'    /*AND license_family IS NULL*/ THEN 'by-sa'
    ELSE ''
    END AS license_family
FROM (
      SELECT pc.id,
      pc.packvers_id,
      pc.proc_step,
      pc.ftid,
      pc.is_evidence,
      (lineage->'statistics')[0]                                  AS quantidade_feicoes_bruta,
      pc.kx_profile->'date_aprroved'                              AS date_aprroved,
      pc.kx_profile->'publication_summary'->'size'                AS size,
      pc.kx_profile->'publication_summary'->'bytes'               AS bytes,
      pc.kx_profile->'publication_summary'->'itens'               AS itens,
      pc.kx_profile->'publication_summary'->'size_unit'           AS size_unit,
      pc.kx_profile->'publication_summary'->'avg_density'         AS avg_density,
      pc.kx_profile->'publication_summary'->'size_unitDensity'    AS size_unitDensity,
      ft.ftname,
      split_part(ft.ftname,'_',1)                                 AS ftname_class,
      ft.geomtype,
      ft.need_join,
      ft.description
      FROM optim.donated_PackComponent pc
      LEFT JOIN optim.feature_type ft
      ON ft.ftid = pc.ftid
      --WHERE pc.ftid > 19
) a
LEFT JOIN
(
    SELECT d.*/*, family AS license_family*/
    FROM api.donatedpacks_donor d
    --LEFT JOIN
    --(
        --SELECT id_label, name, family, url, 'yes' AS license_is_explicit FROM tmp_orig.fdw_licenses
        --UNION
        --SELECT id_label, name, family, url_report AS url, 'no' AS license_is_explicit FROM tmp_orig.fdw_implieds
    --) AS l
    --ON lower(d.license) = l.id_label AND d.license_is_explicit = l.license_is_explicit
) b
ON substring(to_char(a.packvers_id,'FM00000000000000'),4,8) = to_char(b.pack_id,'FM00000000')
    AND substring(to_char(a.packvers_id,'FM00000000000000'),1,3)::int = (SELECT jurisd_base_id FROM optim.jurisdiction WHERE lower(isolabel_ext)=jurisdiction)
;
COMMENT ON VIEW api.stats_donated_packcomponent
  IS 'Tabelão.'
;
--curl "http://localhost:3103/stats_donated_packcomponent?uri_objtype=like.*email*" -H "Accept: text/csv"

-- Para gráfico donor_status X number of donors
CREATE or replace VIEW api.stats_donors_prospection AS
    SELECT *, SUM(amount) OVER (ORDER BY donor_status DESC ) AS accumulated_amount
    FROM
    (
        SELECT CASE WHEN donor_status IS NULL THEN '-1' ELSE donor_status END AS donor_status,
            CASE
            WHEN donor_status = '0' THEN '{"pt":"Doadores contatados","en":"Donors contacted","es":"Donantes contactados","fr":"Donateurs contactés"}'::jsonb
            WHEN donor_status = '1' THEN '{"pt":"Doadores interessados em colaborar","en":"Donors interested in collaborating","es":"Donantes interesados ​​en colaborar","fr":"Donateurs intéressés à collaborer"}'::jsonb
            WHEN donor_status = '2' THEN '{"pt":"Pacotes doados recebidos","en":"Donated pack received","es":"Paquetes donados recibidos","fr":"Packs donnés reçus"}'::jsonb
            WHEN donor_status = '3' THEN '{"pt":"Pacotes doados publicados","en":"Donated pack published","es":"Paquetes donados publicados","fr":"Packs donnés publiés"}'::jsonb
            ELSE '{"pt":"Desconhecido","en":"Unknown","es":"Desconocido","fr":"Inconnue"}'::jsonb
            END AS label,
            COUNT(*) AS amount
        FROM api.donors
        GROUP BY donor_status
    ) r
    ORDER BY donor_status
;
COMMENT ON VIEW api.stats_donors_prospection
  IS 'For donor_status X number of donors chart.'
;

-- Para gráfico layers X packages
CREATE or replace VIEW api.stats_donated_packcomponent_classgrouped AS
    SELECT ftname_class, COUNT(*) AS amount
    FROM api.stats_donated_packcomponent
    GROUP BY ftname_class
;
COMMENT ON VIEW api.stats_donated_packcomponent_classgrouped
  IS 'For layers X packages chart.'
;

-- Para gráfico donated packages X date
CREATE or replace VIEW api.stats_donated_pack_timeline AS
    SELECT accepted_date, SUM(amount) OVER (ORDER BY accepted_date ASC ) AS accumulated_amount
    FROM
    (
        SELECT accepted_date, COUNT(*) AS amount
        FROM
        (
            SELECT accepted_date
            FROM api.stats_donated_packcomponent
            GROUP BY jurisdiction, pack_id, accepted_date
        ) r
        GROUP BY accepted_date
    ) s
    ORDER BY accepted_date
;
COMMENT ON VIEW api.stats_donated_pack_timeline
  IS 'For donated packages X date chart.'
;

-- Para tabela de licenças
CREATE or replace VIEW api.stats_donated_pack_licensegrouped AS
    SELECT license_family, license_is_explicit, COUNT(donor_id) AS donor_amount, SUM(quantidade_feicoes_bruta::int) AS data_amount
    FROM api.stats_donated_packcomponent
    WHERE ftname IN ('geoaddress_full', 'parcel_full')
    GROUP BY license_family, license_is_explicit
;
COMMENT ON VIEW api.stats_donated_pack_licensegrouped
  IS 'Amount of data per license considering layers geoaddress_full and parcel_full on the raw data provided by stats_donated_packcomponent.'
;

---------

CREATE or replace VIEW api.jurisdiction_lexlabel AS
SELECT isolabel_ext,
CASE
    WHEN cardinality(a)=3 THEN lower(a[1] || ';' ||  lexlabel_parent || ';' || lexlabel)
    WHEN cardinality(a)=2 THEN lower(a[1] || ';' || lexlabel)
    WHEN cardinality(a)=1 THEN lower(isolabel_ext)
    ELSE NULL
END AS lex_isoinlevel1,
CASE
    WHEN cardinality(a)=3 THEN lower(a[1] || ';' ||  a[2] || ';' || lexlabel)
    WHEN cardinality(a)=2 THEN lower(a[1] || ';' || lexlabel)
    WHEN cardinality(a)=1 THEN lower(isolabel_ext)
    ELSE NULL
END AS lex_isoinlevel2,
CASE
    WHEN cardinality(a)=3 THEN lower(a[1] || ';' ||  a[2] || ';' || abbrev)
    WHEN cardinality(a)=2 THEN lower(a[1] || ';' ||  a[2])
    WHEN cardinality(a)=1 THEN lower(isolabel_ext)
    ELSE NULL
END AS lex_isoinlevel2_abbrev
FROM (
    SELECT s.isolabel_ext AS isolabel_ext_parent, s.lexlabel AS lexlabel_parent, r.isolabel_ext, r.abbrev, r.name, r.lexlabel, regexp_split_to_array (r.isolabel_ext,'(-)')::text[] AS a
    FROM optim.jurisdiction r
    LEFT JOIN optim.jurisdiction s
    ON s.isolabel_ext = (SELECT a[1]||'-'||a[2] FROM regexp_split_to_array (r.isolabel_ext,'(-)') a)
) t
;
COMMENT ON VIEW api.jurisdiction_lexlabel
  IS 'Jurisdictions in lex format.'
;


CREATE VIEW optim.vwjurisdiction_synonym AS
SELECT DISTINCT lower(synonym) AS synonym, isolabel_ext
FROM
(
  (
    -- co state abbrev, mun abbrev.
    -- e.g.: CO-A-IGI
    SELECT  'CO-' || substring(isolabel_ext,4,1) ||'-'|| split_part(abbrev,'-',3) AS synonym, MAX(isolabel_ext) AS isolabel_ext
    FROM
    (
        -- não deve retornar abbrev repetidos
        SELECT abbrev, MAX(isolabel_ext) AS isolabel_ext
        FROM optim.jurisdiction_abbrev_option
        WHERE selected IS TRUE
        GROUP BY abbrev
        HAVING count(*) = 1
    ) j
    GROUP BY 1
    HAVING count(*)=1
    ORDER BY 1
  )
  UNION ALL
  (
    -- co unique names
    -- eg.: CO-Medellin
    SELECT 'CO-' || split_part(isolabel_ext,'-',3) AS synonym, MAX(isolabel_ext) AS isolabel_ext
    FROM optim.jurisdiction j
    WHERE isolevel::int >2 AND isolabel_ext LIKE 'CO%'
    GROUP BY 1
    HAVING count(*)=1
    ORDER BY 1
  )
  UNION ALL
  (
    -- co state abbrev.
    SELECT  'CO-' || substring(isolabel_ext,4,1) ||'-'|| split_part(isolabel_ext,'-',3) AS synonym, MAX(isolabel_ext) AS isolabel_ext
    FROM optim.jurisdiction j
    WHERE isolevel::int >2 AND isolabel_ext LIKE 'CO-%'
    GROUP BY 1
    HAVING count(*)=1
    ORDER BY 1
  )
  UNION ALL
  (
    -- CO-divipola (municipios)
    SELECT 'CO-' || jurisd_local_id, isolabel_ext
    FROM optim.jurisdiction
    WHERE isolabel_ext LIKE 'CO-%-%'
  )
  UNION ALL
  (
    -- BR-ibgegeocodigo (municipios e estados)
    SELECT 'BR-' || jurisd_local_id, isolabel_ext
    FROM optim.jurisdiction
    WHERE isolabel_ext LIKE 'BR-%'
  )
  UNION ALL
  (
    -- UY-codigo (municipios)
    SELECT 'UY-' || jurisd_local_id, isolabel_ext
    FROM optim.jurisdiction
    WHERE isolabel_ext LIKE 'UY-%'
  )
  UNION ALL
  (
    -- BR isolevel=3 abbrev
    SELECT substring(isolabel_ext,1,6) || abbrev, isolabel_ext
    FROM optim.jurisdiction
    WHERE isolabel_ext LIKE 'BR-%-%' AND abbrev IS NOT NULL
  )
  UNION ALL
  (
    (
        -- Return jurisdiction geojson from lex. ISO 3166-1 alpha-2 country code
        -- e.g.: br;sao.paulo;campinas
        SELECT lex_isoinlevel1, isolabel_ext
        FROM api.jurisdiction_lexlabel
        WHERE lex_isoinlevel1 IS NOT NULL
    )
    UNION
    (
        -- Return jurisdiction geojson from lex. ISO 3166-1 alpha-2 code.
        -- e.g.: br;sp;campinas
        SELECT lex_isoinlevel2, isolabel_ext
        FROM api.jurisdiction_lexlabel
        WHERE lex_isoinlevel2 IS NOT NULL
    )
    UNION
    (
        -- Return jurisdiction geojson from lex. All abbrev.
        -- e.g.: br;sp;cam br;sp
        SELECT lex_isoinlevel2_abbrev, isolabel_ext
        FROM api.jurisdiction_lexlabel
        WHERE lex_isoinlevel2_abbrev IS NOT NULL
    )
  )
  UNION ALL
  (
    -- br unique names
    -- eg.: BR-Zortea
    SELECT lower('BR-' || split_part(isolabel_ext,'-',3)) AS synonym, MAX(isolabel_ext) AS isolabel_ext
    FROM optim.jurisdiction j
    WHERE isolevel::int >2 AND isolabel_ext LIKE 'BR%'
    GROUP BY 1
    HAVING count(*)=1
    ORDER BY 1
  )
  UNION ALL
  (
    -- br-uf-uf para capitais de isolevel = 2
    SELECT lower('BR-' || parent_abbrev || '-' || parent_abbrev) AS synonym, isolabel_ext
    FROM optim.jurisdiction j
    WHERE (info->'is_capital_isolevel')::int > 0 AND isolevel::int = 3 AND isolabel_ext LIKE 'BR-%-%'
  )
  UNION ALL
  (
    -- br-uf para capitais de isolevel = 1 e que cidade=distrito
    SELECT lower(split_part(isolabel_ext,'-',1) || '-' || split_part(isolabel_ext,'-',2)) AS synonym, isolabel_ext
    FROM optim.jurisdiction j
    WHERE (info->'is_capital_isolevel')::int = 1 AND isolevel::int = 3
  )
) z
;
-- CREATE UNIQUE INDEX jurisdiction_abbrev_synonym ON optim.vwjurisdiction_synonym (synonym);
COMMENT ON VIEW optim.vwjurisdiction_synonym
 IS 'Synonymous names of jurisdictions.'
;

DROP MATERIALIZED VIEW IF EXISTS mvwjurisdiction_synonym;
CREATE MATERIALIZED VIEW mvwjurisdiction_synonym AS
SELECT DISTINCT synonym, isolabel_ext
FROM
(
  (
    -- identidade
    SELECT lower(isolabel_ext) AS synonym, isolabel_ext AS isolabel_ext
    FROM optim.jurisdiction
    WHERE isolevel > 1 AND osm_id NOT IN (SELECT parent_id FROM optim.jurisdiction WHERE (info->'is_capital_isolevel')::int = 1)
  )
  UNION ALL
  (
    -- não deve retornar abbrev repetidos
    SELECT lower(abbrev) AS synonym, MAX(isolabel_ext) AS isolabel_ext
    FROM optim.jurisdiction_abbrev_option
    WHERE selected IS TRUE
    GROUP BY abbrev
    HAVING count(*) = 1
  )
  UNION ALL
  (
    SELECT *
    FROM optim.vwjurisdiction_synonym
  )
) z
;
COMMENT ON MATERIALIZED VIEW mvwjurisdiction_synonym
 IS 'Synonymous names of jurisdictions.'
;
CREATE UNIQUE INDEX jurisdiction_abbrev_synonym ON mvwjurisdiction_synonym (synonym);


CREATE or replace FUNCTION optim.generate_synonym_csv(
  p_isolabel_ext text,
  p_path text
) RETURNS text AS $f$
DECLARE
    q_copy text;
BEGIN
  q_copy := $$
    COPY (
      SELECT *
      FROM optim.jurisdiction_abbrev_option
      WHERE isolabel_ext %s
      ORDER BY isolabel_ext
    ) TO '%s' CSV HEADER
  $$;

  EXECUTE format(q_copy,'LIKE ''' || p_isolabel_ext || '%''',p_path);

  RETURN 'Ok.';
END
$f$ LANGUAGE PLpgSQL;
COMMENT ON FUNCTION optim.generate_synonym_csv(text,text)
  IS 'Generate csv with isolevel=3 coverage and overlay in separate array.'
;
/*
SELECT optim.generate_synonym_csv('BR','/tmp/pg_io/synonymbr.csv');
SELECT optim.generate_synonym_csv('CO','/tmp/pg_io/synonymco.csv');
SELECT optim.generate_synonym_csv('UY','/tmp/pg_io/synonymuy.csv');
*/

CREATE or replace FUNCTION optim.generate_synonym_a4a_csv(
  p_isolabel_ext text,
  p_path text
) RETURNS text AS $f$
DECLARE
    q_copy text;
BEGIN
  q_copy := $$
    COPY (
      -- SELECT true, 5, isolabel_ext, synonym, '2022-01-01'
      SELECT isolabel_ext, synonym
      FROM optim.vwjurisdiction_synonym
      WHERE isolabel_ext %s
      ORDER BY isolabel_ext
    ) TO '%s' CSV HEADER
  $$;

  EXECUTE format(q_copy,'LIKE ''' || p_isolabel_ext || '%''',p_path);

  RETURN 'Ok.';
END
$f$ LANGUAGE PLpgSQL;
COMMENT ON FUNCTION optim.generate_synonym_a4a_csv(text,text)
  IS 'Generate csv with isolevel=3 coverage and overlay in separate array.'
;
/*
SELECT optim.generate_synonym_a4a_csv('BR','/tmp/pg_io/synonym_a4abr.csv');
SELECT optim.generate_synonym_a4a_csv('CO','/tmp/pg_io/synonym_a4aco.csv');
SELECT optim.generate_synonym_a4a_csv('UY','/tmp/pg_io/synonym_a4auy.csv');
*/

CREATE or replace FUNCTION optim.generate_synonym_ref_csv(
  p_path text
) RETURNS text AS $f$
DECLARE
    q_copy text;
BEGIN
  q_copy := $$
    COPY (
      SELECT *
      FROM optim.jurisdiction_abbrev_ref
      ORDER BY abbrevref_id
    ) TO '%s' CSV HEADER
  $$;

  EXECUTE format(q_copy,p_path);

  RETURN 'Ok.';
END
$f$ LANGUAGE PLpgSQL;
COMMENT ON FUNCTION optim.generate_synonym_ref_csv(text)
  IS 'Generate csv with isolevel=3 coverage and overlay in separate array.'
;
-- SELECT optim.generate_synonym_ref_csv('/tmp/pg_io/synonym_ref.csv');

CREATE or replace FUNCTION str_geocodeiso_decode(iso text)
RETURNS text[] as $f$
  SELECT isolabel_ext || array[split_part(isolabel_ext,'-',1)]
  FROM mvwjurisdiction_synonym
  WHERE synonym = lower((
    SELECT
      CASE
        WHEN cardinality(u)=2 AND u[2] ~ '^\d+?$'
        THEN u[1]::text || '-' || ((u[2])::integer)::text
        ELSE iso
      END
    FROM (SELECT regexp_split_to_array(iso,'(-)')::text[] AS u ) r
  ))
$f$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION str_geocodeiso_decode(text)
  IS 'Decode abbrev isolabel_ext.'
;

CREATE or replace FUNCTION api.jurisdiction_geojson_from_isolabel(
   p_code text
) RETURNS jsonb AS $f$
    SELECT jsonb_build_object(
        'type', 'FeatureCollection',
        'features',
            (
                jsonb_agg(ST_AsGeoJSONb(
                    geom,
                    8,0,null,
                    jsonb_build_object(
                        'osm_id', osm_id,
                        'jurisd_base_id', jurisd_base_id,
                        'jurisd_local_id', jurisd_local_id,
                        'parent_id', parent_id,
                        'admin_level', admin_level,
                        'name', name,
                        'parent_abbrev', parent_abbrev,
                        'abbrev', abbrev,
                        'wikidata_id', wikidata_id,
                        'lexlabel', lexlabel,
                        'isolabel_ext', isolabel_ext,
                        'lex_urn', lex_urn,
                        'name_en', name_en,
                        'isolevel', isolevel,
                        'area', ST_Area(geom,true),
                        'jurisd_base_id', jurisd_base_id,
                        'is_multipolygon', CASE WHEN GeometryType(geom) IN ('MULTIPOLYGON') THEN TRUE ELSE FALSE END,
                        -- 'size_shortestprefix', size_shortestprefix,
                        'canonical_pathname', CASE WHEN jurisd_base_id=170 THEN 'CO-'|| jurisd_local_id ELSE isolabel_ext END
                        )
                    )::jsonb)
            )
        )
    FROM optim.vw01full_jurisdiction_geom g/*,

    LATERAL
    (
      SELECT MIN(LENGTH(kx_prefix)) AS size_shortestprefix
      FROM osmc.coverage
      WHERE isolabel_ext = g.isolabel_ext AND is_overlay IS FALSE
    ) s*/

    WHERE g.isolabel_ext = (SELECT (str_geocodeiso_decode(p_code))[1])
$f$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION api.jurisdiction_geojson_from_isolabel(text)
  IS 'Return jurisdiction geojson from isolabel_ext.'
;
/*
SELECT api.jurisdiction_geojson_from_isolabel('BR-SP-Campinas');
SELECT api.jurisdiction_geojson_from_isolabel('CO-ANT-Itagui');
SELECT api.jurisdiction_geojson_from_isolabel('CO-A-Itagui');
SELECT api.jurisdiction_geojson_from_isolabel('CO-Itagui');
*/

CREATE or replace FUNCTION api.jurisdiction_autocomplete(
   p_code text DEFAULT NULL
) RETURNS jsonb AS $f$
SELECT
CASE
WHEN cardinality(u)=2 AND u[1] ~*  '^[A-Z]{2}(-[A-Z]{1,3})?$' AND u[2] NOT IN ('ES','EN','PT','FR','')       THEN jsonb_build_object('error', 'Unsupported language.')
WHEN cardinality(u)=2 AND u[1] !~* '^[A-Z]{2}(-[A-Z]{1,3})?$' AND u[2]     IN ('ES','EN','PT','FR'   )       THEN jsonb_build_object('error', 'Isocode wrong format.')
WHEN cardinality(u)=2 AND u[1] !~* '^[A-Z]{2}(-[A-Z]{1,3})?$' AND u[2] NOT IN ('ES','EN','PT','FR','')       THEN jsonb_build_object('error', 'Isocode wrong format and unsupported language.')
WHEN cardinality(u)=1 AND u[1] !~* '^[A-Z]{2}(-[A-Z]{1,3})?$'                                                THEN jsonb_build_object('error', 'Isocode wrong format.')
WHEN (cardinality(u)=1 OR (cardinality(u)=2 AND u[2] IN ('') ))
                 AND u[1] NOT IN (SELECT isolabel_ext FROM optim.jurisdiction WHERE isolevel IN (1,2))       THEN jsonb_build_object('error', 'Isocode does not exist.')
WHEN (SELECT count(isolabel_ext) FROM optim.jurisdiction WHERE isolabel_ext = u[1]) = 0 AND u[1] NOT IN ('') THEN jsonb_build_object('error', 'No information for this jurisdiction.')

WHEN (cardinality(u)=2 AND u[1] ~* '^[A-Z]{2}(-[A-Z]{1,3})?$' AND u[2] IN ('ES','EN','PT','FR','')) OR
     (cardinality(u)=1 AND u[1] ~* '^[A-Z]{2}(-[A-Z]{1,3})?$') OR
     p_code IS NULL OR p_code = ''
THEN
(
    SELECT jsonb_agg(jsonb_build_object(
                        'name', name, -- currently no multilingual support.
                        'abbreviation', lower(abbrev),
                        'synonymous',
                            CASE
                            WHEN isolevel IN (1,2) THEN ARRAY []::text[]
                            -- WHEN isolevel = 2 THEN ARRAY [ lexname_to_unix(lexlabel,true,true,true) ]::text[]
                            WHEN isolevel = 3      THEN ARRAY [ split_part(isolabel_ext,'-',3) ]::text[]
                            ELSE ARRAY []::text[]
                            END
                        ))
    FROM optim.jurisdiction j
    WHERE

    CASE
    WHEN p_code IS NULL OR p_code = ''  THEN isolevel = 1
    WHEN cardinality(v)=1               THEN isolabel_ext LIKE u[1] || '%' AND isolevel = 2
    WHEN cardinality(v)=2               THEN isolabel_ext LIKE u[1] || '%' AND isolevel = 3
    END
)
ELSE jsonb_build_object('error', 'Unknown.')
END
FROM (SELECT string_to_array(upper(p_code),'/')::text[] AS u ) r, LATERAL (SELECT string_to_array(u[1],'-')::text[] AS v) s
$f$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION api.jurisdiction_autocomplete(text)
  IS 'Jurisdictions to autocomplete.'
;
/*
SELECT api.jurisdiction_autocomplete();
SELECT api.jurisdiction_autocomplete('CO-ANT');
*/

----------------------

CREATE or replace VIEW api.quarter AS
SELECT country, quarter, SUM(n) AS n
FROM
(
  SELECT split_part(isolabel_ext,'-',1) AS country, n,CASE WHEN date < '2020-01-01' THEN 'Q1 2020' ELSE quarter END AS quarter
  FROM
  (
    SELECT *, 'Q' || (extract(quarter from date)::text) || ' ' || (extract(year from date))::text as quarter
    FROM
    (
      SELECT isolabel_ext, packtpl_id, MAX(date) AS date, MAX(n) AS n
      FROM
      (
        SELECT *
        FROM (
          SELECT pf.isolabel_ext,packtpl_id,ftype_info->>'class_ftname' AS class_ftname, (packtpl_info->>'accepted_date')::date, (jsonb_array_to_text_array((lineage->'statistics'))::int[])[16] AS n
          FROM optim.vw01full_donated_PackComponent pf
          ORDER BY pf.isolabel_ext
        ) AS g
        WHERE class_ftname IN ('geoaddress','parcel')
        ORDER BY isolabel_ext, packtpl_id, n
      ) h
      GROUP BY isolabel_ext, packtpl_id
    ) i
  ) j
) d
GROUP BY country, quarter
ORDER BY country, split_part(quarter,' ',2), split_part(quarter,' ',1)
;
COMMENT ON VIEW api.quarter
  IS 'For amount data X quarter chart.'
;

CREATE EXTENSION tablefunc;

CREATE or replace VIEW api.quarter2 AS
SELECT *
FROM
  crosstab
  (
    $$
      SELECT country, quarter, sum(n) OVER (PARTITION BY country ORDER BY split_part(quarter,' ',2), split_part(quarter,' ',1)) AS n
      FROM
      (
        SELECT * FROM api.quarter

        UNION

        SELECT country, quarter, 0::bigint
        FROM
          (
            SELECT DISTINCT country FROM api.quarter
          ) r,
          (
            SELECT 'Q' || (extract(quarter from date)::text) || ' ' || (extract(year from date))::text as quarter
            FROM generate_series('2020-01-01 00:00'::timestamp, NOW()- interval '3 months', '3 months') t(date)
          ) s
        WHERE (country, quarter) NOT IN (SELECT country, quarter FROM api.quarter)
      ) r
    $$,
    $$
    SELECT 'Q' || (extract(quarter from date)::text) || ' ' || (extract(year from date))::text as quarter
    FROM generate_series('2020-01-01 00:00'::timestamp, NOW()- interval '3 months', '3 months') t(date)
    ORDER BY date
    $$
  ) AS t ("country" text, "Q1 2020" bigint, "Q2 2020" bigint,"Q3 2020" bigint,"Q4 2020" bigint,"Q1 2021" bigint,"Q2 2021" bigint,"Q3 2021" bigint,"Q4 2021" bigint,"Q1 2022" bigint,"Q2 2022" bigint,"Q3 2022" bigint,"Q4 2022" bigint,"Q1 2023" bigint,"Q2 2023" bigint,"Q3 2023" bigint)
;
COMMENT ON VIEW api.quarter2
  IS 'For amount data X quarter chart.'
;

----------------------

-- https://github.com/AddressForAll/site-v2/issues/59
CREATE or replace VIEW api.pkindown AS
  SELECT isolabel_ext, legalname, pack_number, MAX(description) AS description, SUM(geoaddress) AS geoaddress, SUM(parcel) AS parcel, SUM(via) AS via, SUM(building) AS building, SUM(block) AS block, SUM(nsvia) AS nsvia, SUM(genericvia) AS genericvia, MAX(license) AS license, MAX(url) As url
  FROM
  (
    SELECT
      isolabel_ext,
      legalname,
      pack_number,
      packtpl_info->>'about' AS description,

      CASE WHEN (ftype_info->>'class_ftname') = 'geoaddress' THEN (jsonb_array_to_text_array((lineage->'statistics'))::int[])[16] ELSE NULL END AS geoaddress,
      CASE WHEN (ftype_info->>'class_ftname') = 'parcel'     THEN (jsonb_array_to_text_array((lineage->'statistics'))::int[])[16] ELSE NULL END AS parcel,
      CASE WHEN (ftype_info->>'class_ftname') = 'via'        THEN (jsonb_array_to_text_array((lineage->'statistics'))::int[])[16] ELSE NULL END AS via,
      CASE WHEN (ftype_info->>'class_ftname') = 'building'   THEN (jsonb_array_to_text_array((lineage->'statistics'))::int[])[16] ELSE NULL END AS building,
      CASE WHEN (ftype_info->>'class_ftname') = 'block'      THEN (jsonb_array_to_text_array((lineage->'statistics'))::int[])[16] ELSE NULL END AS block,
      CASE WHEN (ftype_info->>'class_ftname') = 'nsvia'      THEN (jsonb_array_to_text_array((lineage->'statistics'))::int[])[16] ELSE NULL END AS nsvia,
      CASE WHEN (ftype_info->>'class_ftname') = 'genericvia' THEN (jsonb_array_to_text_array((lineage->'statistics'))::int[])[16] ELSE NULL END AS genericvia,

      license_data->>'id_label' || CASE WHEN license_data->>'id_label' = '' THEN  '' ELSE '-' || (license_data->>'id_version')::text END AS license,
      path_preserv_git AS url
    FROM optim.vw01full_donated_PackComponent pf
    WHERE pf.ftid > 19
  ) a
  GROUP BY isolabel_ext, legalname, pack_number
  ORDER BY 1, 2, 3
;
COMMENT ON VIEW api.pkindown
  IS 'Returns some information about packages listed on the https://addressforall.org/downloads website.'
;

----------------------

CREATE or replace FUNCTION api.redirects_viz(
   p_uri text
) RETURNS jsonb AS $f$
    WITH results AS (
        SELECT *
        FROM optim.vw01fromCutLayer_toVizLayer
        WHERE
        ( -- 'BR-SP-Jacarei/_pk0145.01/parcel'
          p_uri ~*  '^/?[A-Z]{2}-[A-Z]{1,3}-[A-Z]+\/\_pk[0-9]{4}\.[0-9]{2}\/[A-Z]+$' AND
          jurisdiction_pack_layer ILIKE regexp_replace(p_uri,'/?([A-Z]{2}-[A-Z]{1,3}-[A-Z]+\/\_pk[0-9]{4}\.[0-9]{2}\/[A-Z]+)','\1%','i')
        )
        OR
        ( -- 'BR-SP-Jacarei/parcel'
          p_uri ~*  '^/?[A-Z]{2}-[A-Z]{1,3}-[A-Z]+\/[A-Z]+$' AND
          jurisdiction_pack_layer ILIKE regexp_replace(p_uri,'/?([A-Z]{2}-[A-Z]{1,3}-[A-Z]+)\/([A-Z]+)','\1%\2%','i')
        )
        OR
        ( -- BR/pk0081
          -- BR/_pk0081
          -- BR/81
          p_uri ~*  '^/?[A-Z]{2}\/(\_?pk)?[0-9]+(\.[0-9]{1,2})?$' AND
          jurisdiction_pack_layer ILIKE regexp_replace(p_uri,'/?([A-Z]{2})\/(\_?pk)?([0-9]+)(\.[0-9]{1,2})?','\1%\3%','i')
        )
        OR
        ( -- BR/pk0081/via
          -- BR/_pk0081/via
          -- BR/81/via
          p_uri ~*  '^/?[A-Z]{2}\/(\_?pk)?[0-9]+(\.[0-9]{1,2})?\/[A-Z]+$' AND
          jurisdiction_pack_layer ILIKE regexp_replace(p_uri,'/?([A-Z]{2})\/(\_?pk)?([0-9]+)(\.[0-9]{1,2})?(\/[A-Z]+)','\1%\3%\5%','i')
        )
        OR
        ( -- c26c149b/geoaddress
          p_uri ~*  '^/?([a-f0-9]{1,64})(\.[a-z0-9]+)?\/([A-Z]+)$' AND
          hash_from ILIKE regexp_replace(p_uri,'/?([a-f0-9]{6,64})(\.[a-z0-9]+)?\/([A-Z]+)','\1%','i') AND
          jurisdiction_pack_layer ILIKE regexp_replace(p_uri,'/?([a-f0-9]{1,64})(\.[a-z0-9]+)?\/([A-Z]+)','%\3%','i')
        )
        OR
        ( -- c26c149b
          p_uri ~*  '^/?([a-f0-9]{1,64})(\.[a-z0-9]+)?$' AND
          hash_from ILIKE regexp_replace(p_uri,'/?([a-f0-9]{1,64})(\.[a-z0-9]+)?','\1%','i')
        )
    )
    SELECT
     coalesce
     (
      (
        SELECT jsonb_build_object(
        'jurisdiction_pack_layer',jurisdiction_pack_layer,
        'url_layer_visualization',url_layer_visualization,
        'hashedfname_from',hash_from,
        'error',

          CASE
          WHEN url_layer_visualization IS NULL THEN  'no uri.'
          ELSE NULL
          END
        )
        FROM results WHERE (SELECT COUNT(*) FROM results) = 1
      ),
      jsonb_build_object
      (
        'error',
          CASE
          WHEN (SELECT COUNT(*) FROM results) > 1 THEN  'Multiple results.'
          ELSE  'no result'
          END
      )
    )
    ;
$f$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION api.redirects_viz(text)
  IS 'Jurisdictions to autocomplete.'
;
-- SELECT api.redirects_viz('BR-SP-Jacarei/_pk0145.01/parcel');
-- SELECT api.redirects_viz('BR-SP-Jacarei/parcel');
-- SELECT api.redirects_viz('c26c149b/geoaddress');
-- SELECT api.redirects_viz('d101e729/geoaddress');
-- SELECT api.redirects_viz('BR/81');

CREATE or replace VIEW api.redirects AS
    -- dl.digital-guard
    SELECT hashedfname AS fhash, hashedfnameuri AS furi
    FROM download.redirects

    UNION

    -- Data VisualiZation
    SELECT hashedfname, hashedfnameuri
    FROM optim.donated_PackComponent_cloudControl
;
COMMENT ON VIEW api.redirects
  IS ''
;
COMMENT ON VIEW api.redirects
  IS 'Redirects the DL.digital-guard eternal hyperlink to cloud storage.'
;
----------------------

CREATE or replace FUNCTION api.download_list(

) RETURNS jsonb  AS $f$
    SELECT *
    FROM optim.vw02generate_list
    ;
$f$ language SQL VOLATILE;
COMMENT ON FUNCTION api.download_list
  IS 'Returns the json for the site''s download list template.'
;

----------------------

DROP MATERIALIZED VIEW IF EXISTS optim.mvwjurisdiction_geomeez;
CREATE MATERIALIZED VIEW optim.mvwjurisdiction_geomeez AS
  SELECT *
  FROM optim.jurisdiction_geom
  WHERE osm_id IN
    (
        SELECT osm_id
        FROM optim.jurisdiction
        WHERE isolevel=1 AND COALESCE( (info->>'use_jurisdiction_eez')::boolean,false) IS FALSE
    )

  UNION

  SELECT g.osm_id, g.isolabel_ext, ST_UNION(g.geom,e.geom), ST_UNION(g.geom_svg,e.geom_svg), g.kx_ghs1_intersects, g.kx_ghs2_intersects
  FROM optim.jurisdiction_geom g
  LEFT JOIN optim.jurisdiction_eez e
  ON g.osm_id = e.osm_id
  WHERE g.osm_id IN
    (
        SELECT osm_id
        FROM optim.jurisdiction
        WHERE isolevel=1 AND (info->>'use_jurisdiction_eez')::boolean IS TRUE
    )
;
CREATE INDEX optim_mvwjurisdiction_geomeez_idx1              ON optim.mvwjurisdiction_geomeez USING gist (geom);
CREATE INDEX optim_mvwjurisdiction_geomeez_isolabel_ext_idx1 ON optim.mvwjurisdiction_geomeez USING btree (isolabel_ext);

COMMENT ON MATERIALIZED VIEW optim.mvwjurisdiction_geomeez
 IS 'Merge geom and eez geometries when ''info->use_jurisdiction_eez'' is true'
;
----------------------

CREATE or replace VIEW api.metadata_viz AS
SELECT *
FROM optim.vw03_metadata_viz
;
COMMENT ON VIEW api.metadata_viz
  IS 'Redirects the viz canonical  hyperlink to external provider.'
;
----------------------

CREATE or replace VIEW api.licenses AS
SELECT *
FROM license.licenses_implieds
;
COMMENT ON VIEW api.licenses
  IS 'Merge implicit and explicit licenses.'
;

CREATE or replace FUNCTION api.plicenses(
   p_string text DEFAULT NULL
) RETURNS jsonb AS $f$
  SELECT
    CASE
    WHEN count(*) = 1 THEN jsonb_build_object('error', null, 'result', (jsonb_agg(to_jsonb(r.*)))                                )
    WHEN count(*) > 1 THEN jsonb_build_object('error', null, 'result', (jsonb_agg(to_jsonb(r.*))), 'warning', 'Multiple results.')
    WHEN count(*) = 0 THEN jsonb_build_object('error', 'No results.')
    ELSE jsonb_build_object('error', 'Unknown.')
    END
  FROM
  (
    SELECT *
    FROM license.licenses_implieds
    WHERE
      ( lower(id_label) = lower(p_string) ) OR
      ( regexp_split_to_array (lower(p_string),'~') = ARRAY[lower(id_label),id_version] ) OR
      ( lower(name) = lower(lower(p_string)) ) OR
      ( lower(id_label) =
        substring
          (
            lower(p_string)
            FROM 1
            FOR (CASE WHEN length(split_part(lower(p_string), '-', -1)) = length(p_string) THEN 0 ELSE length(p_string) - 1 - length(split_part(lower(p_string), '-', -1)) END)
          )
          AND id_version = split_part(lower(p_string), '-', -1) )
    ORDER BY id_label, id_version
  ) r
$f$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION api.plicenses(text)
  IS 'Get license info.'
;
/*
SELECT api.plicenses();
SELECT api.plicenses('cc0');
SELECT api.plicenses('ecl');
SELECT api.plicenses('cc0~1.0');
SELECT api.plicenses('cc0-1.0');
*/

----------------------

CREATE or replace VIEW api.full_packfilevers AS
SELECT *
FROM optim.vw01full_packfilevers
;
COMMENT ON VIEW api.full_packfilevers
  IS 'Get the latest version of donated packages. Join between donated_packfilevers, donated_PackTpl, jurisdiction, auth_user and licenses_implieds.'
;

----------------------

CREATE or replace VIEW api.consolidated_data AS
SELECT  isolabel_ext, via_name, house_number, postcode, license_family, latitude, longitude, afa_id, afacodes_scientific, geom_frontparcel, score
FROM optim.consolidated_data
;
COMMENT ON VIEW api.consolidated_data
  IS 'Returns consolidated data.'
;

COMMENT ON COLUMN api.consolidated_data.isolabel_ext     IS 'ISO and name (camel case); e.g. BR-SP-SaoPaulo.';
COMMENT ON COLUMN api.consolidated_data.via_name         IS 'Via name.';
COMMENT ON COLUMN api.consolidated_data.house_number     IS 'House number.';
COMMENT ON COLUMN api.consolidated_data.postcode         IS 'Postal code.';
COMMENT ON COLUMN api.consolidated_data.license_family   IS 'License family.';
COMMENT ON COLUMN api.consolidated_data.latitude         IS 'Feature latitude.';
COMMENT ON COLUMN api.consolidated_data.longitude        IS 'Feature longitude.';
COMMENT ON COLUMN api.consolidated_data.afa_id              IS 'AFAcodes scientific. 64bits format.';
COMMENT ON COLUMN api.consolidated_data.afacodes_scientific IS 'AFAcodes scientific.';
COMMENT ON COLUMN api.consolidated_data.geom_frontparcel IS 'Flag. Indicates if geometry is in front of the parcel.';
COMMENT ON COLUMN api.consolidated_data.score            IS '...';
