CREATE SCHEMA IF NOT EXISTS api;
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
      jsonb_strip_nulls(info) AS info
FROM optim.jurisdiction
ORDER BY jurisd_base_id, isolevel, name
;
--curl "http://localhost:3103/jurisdiction?jurisd_base_id=eq.76&parent_abbrev=eq.CE" -H "Accept: text/csv"
-- https://osm.codes/_sql.csv/jurisdiction?jurisd_base_id=eq.76&parent_abbrev=eq.CE

---------
-- Union de fdw_donor de todas as jurisdições
CREATE or replace VIEW api.donors AS
    (
        SELECT 'br' AS jurisdiction, r.*
        FROM tmp_orig.fdw_donorbr r
    )
    UNION ALL
    (
        SELECT 'ar' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorar r
    )
    UNION ALL
    (
        SELECT 'bo' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorbo r
    )
    UNION ALL
    (
        SELECT 'cl' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorcl r
    )
    UNION ALL
    (
        SELECT 'co' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorco r
    )
    UNION ALL
    (
        SELECT 'ec' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorec r
    )
    UNION ALL
    (
        SELECT 'pe' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorpe r
    )
    UNION ALL
    (
        SELECT 'py' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorpy r
    )
    UNION ALL
    (
        SELECT 'sr' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorsr r
    )
    UNION ALL
    (
        SELECT 'uy' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donoruy r
    )
    UNION ALL
    (
        SELECT 've' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorve r
    )
;

-- Union de fdw_donatedpack X fdw_donor de todas as jurisdições
CREATE or replace VIEW api.donatedpacks_donor AS
    (
        SELECT 'br' AS jurisdiction, r.*, s.*
        FROM tmp_orig.fdw_donatedpackbr r
        LEFT JOIN tmp_orig.fdw_donorbr s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'ar' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackar r
        LEFT JOIN tmp_orig.fdw_donorar s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'bo' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackbo r
        LEFT JOIN tmp_orig.fdw_donorbo s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'cl' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackcl r
        LEFT JOIN tmp_orig.fdw_donorcl s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'co' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackco r
        LEFT JOIN tmp_orig.fdw_donorco s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'ec' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackec r
        LEFT JOIN tmp_orig.fdw_donorec s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'pe' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackpe r
        LEFT JOIN tmp_orig.fdw_donorpe s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'py' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackpy r
        LEFT JOIN tmp_orig.fdw_donorpy s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'sr' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpacksr r
        LEFT JOIN tmp_orig.fdw_donorsr s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'uy' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackuy r
        LEFT JOIN tmp_orig.fdw_donoruy s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 've' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackve r
        LEFT JOIN tmp_orig.fdw_donorve s
        ON s.local_id::int = r.donor_id
    )
;

--tabelão
CREATE or replace VIEW api.stats_donated_packcomponent AS
SELECT a.*,
    jurisdiction, pack_id, donor_id, pack_count, lst_vers, donor_label, user_resp, accepted_date, scope, about, author, contentreferencetime, license_is_explicit, license, uri_objtype, uri, isat_urbigis, status, statusupdatedate, local_id, scope_label, "shortName", vat_id, "legalName", wikidata_id, url, donor_date, donor_status,
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
--curl "http://localhost:3103/stats_donated_packcomponent?uri_objtype=like.*email*" -H "Accept: text/csv"

-- Para gráfico donor_status X number of donors
CREATE or replace VIEW api.stats_donors_prospection AS
    SELECT *, SUM(amount) OVER (ORDER BY donor_status DESC ) AS accumulated_amount
    FROM
    (
        SELECT CASE WHEN donor_status IS NULL THEN '-1' ELSE donor_status END AS donor_status,
            CASE
            WHEN donor_status = '0' THEN 'Donors contacted'
            WHEN donor_status = '1' THEN 'Donors interested in collaborating'
            WHEN donor_status = '2' THEN 'Donated pack received'
            WHEN donor_status = '3' THEN 'Donated pack published'
            ELSE 'Unknown'
            END AS label,
            COUNT(*) AS amount
        FROM api.donors
        GROUP BY donor_status
    ) r
    ORDER BY donor_status
;

-- Para gráfico layers X packages
CREATE or replace VIEW api.stats_donated_packcomponent_classgrouped AS
    SELECT ftname_class, COUNT(*) AS amount
    FROM api.stats_donated_packcomponent
    GROUP BY ftname_class
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

-- Para tabela de licenças
CREATE or replace VIEW api.stats_donated_pack_licensegrouped AS
    SELECT license_family, license_is_explicit, COUNT(donor_id) AS donor_amount, SUM(quantidade_feicoes_bruta::int) AS data_amount
    FROM api.stats_donated_packcomponent
    WHERE ftname IN ('geoaddress_full', 'parcel_full')
    GROUP BY license_family, license_is_explicit
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

--DROP MATERIALIZED VIEW mvwjurisdiction_synonym;
CREATE MATERIALIZED VIEW mvwjurisdiction_synonym AS
SELECT DISTINCT lower(synonym) AS synonym, isolabel_ext
FROM
(
  (
    -- identidade
    SELECT isolabel_ext AS synonym, isolabel_ext AS isolabel_ext
    FROM optim.jurisdiction
    WHERE isolevel > 1
  )
  UNION ALL
  (
    -- não deve retornar abbrev repetidos
    SELECT abbrev, MAX(isolabel_ext)
    FROM optim.jurisdiction_abbrev_option
    WHERE selected IS TRUE
    GROUP BY abbrev
    HAVING count(*) = 1
  )
  UNION ALL
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
    -- co state abbrev.
    SELECT  'CO-DC', 'CO-DC-Bogota'
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
) z
;
CREATE UNIQUE INDEX jurisdiction_abbrev_synonym ON mvwjurisdiction_synonym (synonym);
COMMENT ON MATERIALIZED VIEW mvwjurisdiction_synonym
 IS 'Synonymous names of jurisdictions.'
;

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
                        'jurisd_base_id', jurisd_base_id
                        )
                    )::jsonb)
            )
        )
    FROM optim.vw01full_jurisdiction_geom g
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
