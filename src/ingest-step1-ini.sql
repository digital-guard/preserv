-- INGEST STEP1
-- Inicialização do Módulo Ingest dos projetos Digital-Guard.
--

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS adminpack;

-- old CREATE SCHEMA    IF NOT EXISTS ingest;
DROP SCHEMA      IF EXISTS     ingest CASCADE; -- important to clean!
CREATE SCHEMA                  ingest;

CREATE SCHEMA    IF NOT EXISTS tmp_orig;
CREATE SCHEMA    IF NOT EXISTS api;
CREATE SCHEMA    IF NOT EXISTS download;

CREATE EXTENSION IF NOT EXISTS file_fdw;
CREATE SERVER    IF NOT EXISTS files
        FOREIGN DATA WRAPPER file_fdw
;
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
CREATE SERVER    IF NOT EXISTS foreign_server_dl03
         FOREIGN DATA WRAPPER postgres_fdw
         OPTIONS (dbname 'dl03t_main')
;
CREATE USER MAPPING FOR PUBLIC SERVER foreign_server_dl03;

-- -- --
-- SQL and bash generators (optim-ingest submodule)

CREATE FUNCTION ingest.fdw_csv_paths(
  p_name text, p_context text DEFAULT 'br', p_path text DEFAULT NULL
) RETURNS text[] AS $f$
  SELECT  array[
    fpath, -- /tmp/pg_io/digital-preservation-XX
    concat(fpath,'/', iIF(p_context IS NULL,''::text,p_context||'-'), p_name, '.csv')
  ]
  FROM COALESCE(p_path,'/tmp/pg_io') t(fpath)
$f$ language SQL;

CREATE FUNCTION ingest.fdw_generate_direct_csv(
  p_file text,  -- path+filename+ext
  p_fdwname text, -- nome da tabela fwd
  p_delimiter text DEFAULT ',',
  p_addtxtype boolean DEFAULT true,
  p_header boolean DEFAULT true
) RETURNS text  AS $f$
DECLARE
 fpath text;
 cols text[];
 sepcols text;
BEGIN
 sepcols := iIF(p_addtxtype, '" text,"'::text, '","'::text);
 cols := pg_csv_head(p_file, p_delimiter);
 EXECUTE
    format(
      'DROP FOREIGN TABLE IF EXISTS %s; CREATE FOREIGN TABLE %s    (%s%s%s)',
       p_fdwname, p_fdwname,   '"', array_to_string(cols,sepcols), iIF(p_addtxtype, '" text'::text, '"')
     ) || format(
       'SERVER files OPTIONS (filename %L, format %L, header %L, delimiter %L)',
       p_file, 'csv', p_header::text, p_delimiter
    );
 RETURN p_fdwname;
END;
$f$ language PLpgSQL;
COMMENT ON FUNCTION ingest.fdw_generate_direct_csv
  IS 'Generates a FOREIGN TABLE for simples and direct CSV ingestion.'
;

CREATE FUNCTION ingest.fdw_generate(
  p_name text,  -- table name and CSV input filename
  p_context text DEFAULT 'br',  -- or null
  p_schemaname text DEFAULT 'optim',
  p_columns text[] DEFAULT NULL, -- mais importante! nao poderia ser null
  p_addtxtype boolean DEFAULT false,  -- add " text"
  p_path text DEFAULT NULL,  -- default based on ids
  p_delimiter text DEFAULT ',',
  p_header boolean DEFAULT true
) RETURNS text  AS $f$
DECLARE
 fdwname text;
 fpath text;
 f text;
 sepcols text;
BEGIN
  -- usar ingest.fdw_csv_paths!
 fpath := COALESCE(p_path,'/tmp/pg_io'); -- /tmp/pg_io/digital-preservation-XX
 f := concat(fpath,'/', iIF(p_context IS NULL,''::text,p_context||'-'), p_name, '.csv');
 p_context := iIF(p_context IS NULL, ''::text, '_'|| p_context);
 fdwname := 'tmp_orig.fdw_'|| iIF(p_schemaname='optim', ''::text, p_schemaname||'_') || p_name || p_context;
 -- poderia otimizar por chamada (alter table option filename), porém não é paralelizável.
 sepcols := iIF(p_addtxtype, '" text,"'::text, '","'::text);
 -- if delimiter = tab, format = tsv
 EXECUTE
    format(
      'DROP FOREIGN TABLE IF EXISTS %s; CREATE FOREIGN TABLE %s    (%s%s%s)',
       fdwname, fdwname,   '"', array_to_string(p_columns,sepcols), iIF(p_addtxtype, '" text'::text, '"')
     ) || format(
       'SERVER files OPTIONS (filename %L, format %L, header %L, delimiter %L)',
       f, 'csv', p_header::text, p_delimiter
    );
    return ' '|| fdwname || E' was created!\n source: '||f|| ' ';
END;
$f$ language PLpgSQL;
COMMENT ON FUNCTION ingest.fdw_generate
  IS 'Generates a structure FOREIGN TABLE for ingestion.'
;

CREATE FUNCTION ingest.fdw_generate_getCSV(
  p_name text,  -- table name and CSV input filename
  p_context text DEFAULT 'br',  -- or null
  p_path text DEFAULT NULL,     -- default based on ids
  p_delimiter text DEFAULT ','
) RETURNS text  AS $f$
  SELECT ingest.fdw_generate(p_name, p_context, 'optim', pg_csv_head(p[2],p_delimiter), true, p_path, p_delimiter)
  FROM ingest.fdw_csv_paths(p_name,p_context,p_path) t(p)
$f$ language SQL;
-- select ingest.fdw_generate_getCSV('enderecos','br_mg_bho');
-- creates tmp_orig.fdw_enderecos_br_mg_bho by source: /tmp/pg_io/br_mg_bho-enderecos.csv

CREATE FUNCTION ingest.fdw_generate_getclone(
  -- foreign-data wrapper generator
  p_tablename text,  -- cloned-table name
  p_context text DEFAULT 'br',  -- or null
  p_schemaname text DEFAULT 'optim',
  p_ignore text[] DEFAULT NULL, -- colunms to be ignored.
  p_add text[] DEFAULT NULL, -- colunms to be added.
  p_path text DEFAULT NULL  -- default based on ids
) RETURNS text  AS $wrap$
  SELECT ingest.fdw_generate(
    $1,$2,$3,
    pg_tablestruct_dump_totext(p_schemaname||'.'||p_tablename,p_ignore,p_add),
    true, -- p_addtxtype
    p_path
  )
$wrap$ language SQL;
COMMENT ON FUNCTION ingest.fdw_generate_getclone
  IS 'Generates a clone-structure FOREIGN TABLE for ingestion. Wrap for fdw_generate().'
;

------------
-- GEOMETRIAS
/* !REVISAR CONTROLE DE IDs!
CREATE TABLE ingest.addr_point(
  ?file_id,
  pack_id int, -- each donated package have only 1 set of points. E.g. pk012 of BR_MG_BHO.
  vianame text, -- official name in the origin
  housenum text, -- supply by origin
  -- is_informal boolean default false, -- non-official. E.g. closed condominim.
  geom geometry(Point,4326) NOT NULL,

  UNIQUE(pack_id,vianame,housenum),
  UNIQUE(pack_id,geom)
);
COMMENT ON TABLE ingest.addr_point
  IS 'Ingested address points of one or more packages, temporary data (not need package-version).'
;
*/

CREATE TABLE ingest.hcode_parameters (
  id_profile_params             int   NOT NULL PRIMARY KEY,
  distribution_parameters       jsonb NOT NULL,
  signature_parameters          jsonb NOT NULL,
  comments                      text
);

CREATE TABLE ingest.via_line(
  pck_id real NOT NULL, -- REFERENCES optim.donatedPack(pck_id),
  vianame text,
  is_informal boolean default false, -- non-official name (loteamentos com ruas ainda sem nome)
  geom geometry,
  info JSONb,
  UNIQUE(pck_id,geom)
);
COMMENT ON TABLE ingest.via_line
  IS 'Ingested via lines (street axis) of one or more packages, temporary data (not need package-version).'
;

---------

CREATE FOREIGN TABLE ingest.fdw_jurisdiction (
 osm_id          bigint,
 jurisd_base_id  integer,
 jurisd_local_id integer,
 parent_id       bigint,
 admin_level     smallint,
 name            text,
 parent_abbrev   text,
 abbrev          text,
 wikidata_id     bigint,
 lexlabel        text,
 isolabel_ext    text,
 ddd             integer,
 housenumber_system_type text,
 lex_urn         text,
 info            jsonb,
 name_en         text,
 isolevel        text
) SERVER foreign_server_dl03
  OPTIONS (schema_name 'optim', table_name 'jurisdiction')
;

CREATE FOREIGN TABLE ingest.fdw_jurisdiction_geom (
 osm_id          bigint,
 isolabel_ext    text,
 geom            geometry(Geometry,4326),
 kx_ghs1_intersects text[],
 kx_ghs2_intersects text[]
) SERVER foreign_server_dl03
  OPTIONS (schema_name 'optim', table_name 'jurisdiction_geom')
;

CREATE VIEW ingest.vw01full_jurisdiction_geom AS
    SELECT j.*, g.geom
    FROM ingest.fdw_jurisdiction j
    LEFT JOIN ingest.fdw_jurisdiction_geom g
    ON j.osm_id = g.osm_id
;
COMMENT ON VIEW ingest.vw01full_jurisdiction_geom
  IS 'Add geom to ingest.fdw_jurisdiction.'
;

CREATE FOREIGN TABLE ingest.fdw_donor (
 id integer,
 country_id integer,
 local_serial integer,
 scope_osm_id bigint,
 kx_scope_label text,
 shortname text,
 vat_id text,
 legalname text,
 wikidata_id bigint,
 url text,
 info jsonb,
 kx_vat_id text
) SERVER foreign_server_dl03
  OPTIONS (schema_name 'optim', table_name 'donor');

CREATE FOREIGN TABLE ingest.fdW_donated_PackTpl (
 id bigint,
 donor_id integer,
 user_resp text,
 pk_count integer,
 original_tpl text,
 make_conf_tpl jsonb,
 kx_num_files integer,
 info jsonb
) SERVER foreign_server_dl03
  OPTIONS (schema_name 'optim', table_name 'donated_packtpl');

CREATE FOREIGN TABLE ingest.fdw_donated_PackFileVers (
 id bigint,
 hashedfname text,
 pack_id bigint,
 pack_item integer,
 pack_item_accepted_date date,
 kx_pack_item_version integer,
 user_resp text,
 info jsonb
) SERVER foreign_server_dl03
  OPTIONS (schema_name 'optim', table_name 'donated_packfilevers');

CREATE FOREIGN TABLE ingest.fdw_feature_type (
 ftid smallint,
 ftname text,
 geomtype text,
 need_join boolean,
 description text,
 info jsonb
) SERVER foreign_server_dl03
  OPTIONS (schema_name 'optim', table_name 'feature_type');

CREATE TABLE ingest.donated_PackComponent(
  -- Tabela similar a ingest.layer_file, armazena sumários descritivos de cada layer. Equivale a um subfile do hashedfname.
  id bigserial NOT NULL PRIMARY KEY,  -- layerfile_id
  packvers_id bigint NOT NULL, --REFERENCES ingest.t_donated_PackFileVers(id),
  ftid smallint NOT NULL,      --REFERENCES ingest.t_feature_type(ftid),
  is_evidence boolean default false,
  proc_step int DEFAULT 1,  -- current status of the "processing steps", 1=started, 2=loaded, ...=finished
  lineage jsonb NOT NULL,
  lineage_md5 text NOT NULL, -- or "size-md5" as really unique string
  kx_profile jsonb,
  UNIQUE(packvers_id,ftid,lineage_md5)
  --UNIQUE(packvers_id,ftid,is_evidence)  -- conferir como será o controle de múltiplos files ingerindo no mesmo layer.
);

CREATE TABLE ingest.tmp_geojson_feature (
  file_id bigint NOT NULL REFERENCES ingest.donated_PackComponent(id) ON DELETE CASCADE,
  feature_id int,
  feature_type text,
  properties jsonb,
  jgeom jsonb,
  UNIQUE(file_id,feature_id)
); -- to be feature_asis after GeoJSON ingestion.

CREATE OR REPLACE FUNCTION f(geom text, file_id bigint, ghs_size integer)
RETURNS text AS $f$
    --SELECT ST_Geohash(CASE WHEN (SELECT geomtype FROM ingest.vw03full_layer_file  WHERE id = file_id)='point' THEN geom ELSE ST_PointOnSurface(geom) END,ghs_size)
    SELECT ST_Geohash(ST_PointOnSurface(geom),ghs_size)
$f$ LANGUAGE SQL IMMUTABLE;

CREATE TABLE ingest.feature_asis (
  file_id bigint NOT NULL REFERENCES ingest.donated_PackComponent(id) ON DELETE CASCADE,
  feature_id int NOT NULL,
  properties jsonb,
  geom geometry NOT NULL CHECK ( st_srid(geom)=4326 ),
  kx_ghs9 text GENERATED ALWAYS AS (f(geom,file_id,9)) STORED,
  UNIQUE(file_id,feature_id)
);
CREATE INDEX ingest_feature_asis_ghs9_idx ON ingest.feature_asis (file_id,kx_ghs9);

CREATE TABLE ingest.feature_asis_discarded (
  file_id bigint NOT NULL REFERENCES ingest.donated_PackComponent(id) ON DELETE CASCADE,
  feature_id int NOT NULL,
  properties jsonb,
  geom geometry NOT NULL CHECK ( st_srid(geom)=4326 ),
  kx_ghs9 text GENERATED ALWAYS AS (f(geom,file_id,9)) STORED,
  UNIQUE(file_id,feature_id)
);
CREATE INDEX ingest_feature_asis_discarded_ghs9_idx ON ingest.feature_asis_discarded (file_id,kx_ghs9);

CREATE TABLE ingest.cadastral_asis (
  file_id bigint NOT NULL REFERENCES ingest.donated_PackComponent(id) ON DELETE CASCADE,
  cad_id int NOT NULL,
  properties jsonb NOT NULL,
  UNIQUE(file_id,cad_id)
);

-- -- -- --
--  VIEWS:

DROP VIEW IF EXISTS ingest.vw01info_feature_type CASCADE;
CREATE VIEW ingest.vw01info_feature_type AS
  SELECT ftid, ftname, geomtype, need_join, description,
       COALESCE(f.info,'{}'::jsonb) || (
         SELECT to_jsonb(t2) FROM (
           SELECT c.ftid as class_ftid, c.ftname as class_ftname,
                  c.description as class_description,
                  c.info as class_info
           FROM ingest.fdw_feature_type c
           WHERE c.geomtype='class' AND c.ftid = 10*round(f.ftid/10)
         ) t2
       ) AS info
  FROM ingest.fdw_feature_type f
  WHERE f.geomtype!='class'
;
COMMENT ON VIEW ingest.vw01info_feature_type
  IS 'Adds class_ftname, class_description and class_info to ingest.fdw_feature_type.info.'
;

DROP VIEW IF EXISTS ingest.vw02simple_feature_asis CASCADE;
CREATE VIEW ingest.vw02simple_feature_asis AS
 -- Pending: validar fazendo count(*) comparativo entre a view e a tabela.
 WITH dump AS (
    SELECT *, (ST_DUMP(geom)).geom AS geometry
    FROM ingest.feature_asis
 )
   SELECT file_id, feature_id, properties, geometry::geometry(POLYGON,4326) AS geom
   FROM dump
   WHERE  GeometryType(geom)='MULTIPOLYGON'
  UNION
   SELECT file_id, feature_id, properties, geometry::geometry(LINESTRING,4326)
   FROM dump
   WHERE  GeometryType(geom)='MULTILINESTRING'
  UNION
   SELECT file_id, feature_id, properties, geom
   FROM dump
   WHERE  GeometryType(geom) NOT IN ('MULTILINESTRING','MULTIPOLYGON')
;
COMMENT ON VIEW ingest.vw02simple_feature_asis
  IS 'Normalize (and simplify) geometries of ingest.feature_asis, when it is a redundant multi-geometry.'
;
-- Homologando o uso do feature_id como gid, n=n2:
--  SELECT count(*) n, count(distinct feature_id::text||','||file_id::text) n2 FROM ingest.feature_asis;

DROP VIEW IF EXISTS ingest.vw02full_donated_packfilevers CASCADE;
CREATE or replace VIEW ingest.vw02full_donated_packfilevers AS
  SELECT pf.*, j.isolabel_ext, j.geom, '/var/gits/_dg/preservCutGeo-' || regexp_replace(replace(regexp_replace(j.isolabel_ext, '^([^-]*)-?', '\12021/data/'),'-','/'),'\/$','') || '/_pk' || to_char(dn.local_serial,'fm0000') || '.' || to_char(pf.kx_pack_item_version,'fm00') AS path
  FROM ingest.fdw_donated_packfilevers pf
  LEFT JOIN ingest.fdw_donated_PackTpl pt
    ON pf.pack_id=pt.id
  LEFT JOIN ingest.fdw_donor dn
    ON pt.donor_id=dn.id
  LEFT JOIN ingest.vw01full_jurisdiction_geom j
    ON dn.scope_osm_id=j.osm_id
  ORDER BY j.isolabel_ext
;

DROP VIEW IF EXISTS ingest.vw03full_layer_file CASCADE;
CREATE VIEW ingest.vw03full_layer_file AS
  SELECT j.isolabel_ext,dn.kx_scope_label, pc.*, ft.ftname, ft.geomtype, j.housenumber_system_type, ft.need_join, ft.description, ft.info AS ft_info
  FROM ingest.donated_PackComponent pc
  INNER JOIN ingest.vw01info_feature_type ft
    ON pc.ftid=ft.ftid
  LEFT JOIN ingest.fdw_donated_packfilevers pf
    ON pc.packvers_id=pf.id
  LEFT JOIN ingest.fdw_donated_PackTpl pt
    ON pf.pack_id=pt.id
  LEFT JOIN ingest.fdw_donor dn
    ON pt.donor_id=dn.id
  LEFT JOIN ingest.vw01full_jurisdiction_geom j
    ON dn.scope_osm_id=j.osm_id
  ORDER BY j.isolabel_ext
;

CREATE VIEW ingest.vw03dup_feature_asis AS
 SELECT v.ftname, v.geomtype, t.*, round(100.0*n_ghs/n::float, 2)::text || '%' as n_ghs_perc
 FROM (
   SELECT file_id, count(*) n, count(DISTINCT kx_ghs9) as n_ghs
   FROM ingest.feature_asis
   GROUP BY 1
   ORDER BY 1
) t INNER JOIN ingest.vw03full_layer_file v
    ON v.id = t.file_id
;

DROP VIEW IF EXISTS ingest.vw04simple_layer_file CASCADE;
CREATE VIEW ingest.vw04simple_layer_file AS
  --SELECT id, geomtype, proc_step, ftid, ftname, file_type,
  SELECT id, geomtype, proc_step, ftid, ftname,
         round((lineage->'file_meta'->'size')::int/2014^2) file_mb,
         substr(lineage_md5,1,7) as md5_prefix
  FROM ingest.vw03full_layer_file
;

DROP VIEW IF EXISTS ingest.vw05test_feature_asis CASCADE;
CREATE VIEW ingest.vw05test_feature_asis AS
  SELECT v.packvers_id, v.ft_info->>'class_ftname' as class_ftname, t.file_id,
         v.lineage->'file_meta'->>'file' as file,
         t.n, t.n_feature_ids,
         CASE WHEN t.n=t.n_feature_ids  THEN 'ok' ELSE '!BUG!' END AS is_ok_msg,
          t.n=t.n_feature_ids AS is_ok
  FROM (
    SELECT file_id, COUNT(*) n, COUNT(DISTINCT feature_id) n_feature_ids
    FROM ingest.feature_asis
    GROUP BY 1
  ) t INNER JOIN ingest.vw03full_layer_file v
    ON v.id = t.file_id
  ORDER BY 1,2,3
;

/*
DROP VIEW IF EXISTS ingest.vw06simple_layer CASCADE;
CREATE VIEW ingest.vw06simple_layer AS
  SELECT t.*, (SELECT COUNT(*) FROM ingest.feature_asis WHERE file_id=t.file_id) AS n_items
  FROM ingest.vw04simple_layer_file t
; */

----------------
----------------
-- Ingest AS-IS

CREATE FUNCTION ingest.donated_PackComponent_geomtype(
  p_file_id bigint
) RETURNS text[] AS $f$
  -- ! pendente revisão para o caso shortname multiplingual, aqui usando só 'pt'
  SELECT array[geomtype, ftname, info->>'class_ftname', info->'class_info'->>'shortname_pt']
  FROM ingest.vw01info_feature_type
  WHERE ftid = (
    SELECT ftid
    FROM ingest.donated_PackComponent
    WHERE id = p_file_id
  )
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.donated_PackComponent_geomtype(bigint)
  IS '[Geomtype,ftname,class_ftname,shortname_pt] of a layer_file.'
;

CREATE FUNCTION ingest.feature_asis_geohashes(
    p_file_id bigint,  -- ID at ingest.donated_PackComponent
    ghs_size integer DEFAULT 5
) RETURNS jsonb AS $f$
  WITH scan AS (
   SELECT  ghs, COUNT(*) n
   FROM (
  	SELECT
  	  ST_Geohash(
  	    CASE WHEN t1a.gtype='point' THEN geom ELSE ST_PointOnSurface(geom) END
  	    ,ghs_size
  	  ) as ghs
  	FROM ingest.feature_asis,
  	 (SELECT (ingest.donated_PackComponent_geomtype(p_file_id))[1] AS gtype) t1a
  	WHERE file_id=p_file_id
   ) t2
   GROUP BY 1
   ORDER BY 1
  )
   SELECT jsonb_object_agg( ghs,n )
   FROM scan
$f$ LANGUAGE SQL;

CREATE FUNCTION ingest.feature_asis_assign_volume(
    p_file_id bigint,  -- ID at ingest.donated_PackComponent
    p_usemedian boolean DEFAULT false
) RETURNS jsonb AS $f$
  WITH get_layer_type AS (SELECT (ingest.donated_PackComponent_geomtype(p_file_id))[1] AS gtype)
  SELECT to_jsonb(t3)
  FROM (
      SELECT n, CASE gtype
          WHEN 'poly'  THEN 'polygons'
          WHEN 'line'  THEN 'segments'
          WHEN 'point'  THEN 'points'
        END n_unit,
      size, CASE gtype
          WHEN 'poly'  THEN 'km2'
          WHEN 'line'  THEN 'km'
          ELSE  ''
        END size_unit,
        bbox_km2,
        size_mdn
      FROM (
        SELECT gtype, n, CASE gtype
            WHEN 'poly'  THEN round( ST_Area(geom,true)/1000000.0)::int
            WHEN 'line'  THEN round( ST_Length(geom,true)/1000.0)::int
            ELSE  null::int
          END size,
          round( (ST_Area(ST_OrientedEnvelope(geom),true)/1000000)::numeric, 1)::int AS bbox_km2,
          round(size_mdn::numeric,3) AS size_mdn
        FROM (
            SELECT count(*) n, st_collect(geom) as geom, CASE gtype --(gtype||iif(p_usemedian,'','_no'::text))
                WHEN 'poly'  THEN percentile_disc (0.5) WITHIN GROUP(ORDER BY ST_Area(geom,true)) /1000000.0
                WHEN 'line'  THEN percentile_disc (0.5) WITHIN GROUP(ORDER BY ST_Length(geom,true)) /1000.0
                ELSE  null::float
                END size_mdn
            FROM ingest.feature_asis, get_layer_type
            WHERE file_id=p_file_id
            GROUP BY gtype
        ) t1a, get_layer_type
      ) t2
  ) t3
$f$ LANGUAGE SQL;

CREATE or replace FUNCTION ingest.feature_asis_assign(
    p_file_id bigint  -- ID at ingest.donated_PackComponent
) RETURNS jsonb AS $f$
  SELECT jsonb_build_object(
        'feature_asis_summary',
        ingest.feature_asis_assign_volume(p_file_id,true)
        )
$f$ LANGUAGE SQL;

CREATE or replace FUNCTION ingest.feature_asis_assign_signature(
    p_file_id bigint  -- ID at ingest.donated_PackComponent
) RETURNS jsonb AS $f$
  SELECT jsonb_build_object(
        'ghs_signature',
        hcode_signature_reduce(ingest.feature_asis_geohashes(p_file_id,ghs_size), 2, 1, (SELECT lineage->'hcode_signature_parameters' FROM ingest.donated_PackComponent WHERE id=p_file_id))
    )
  FROM (
    SELECT CASE WHEN (ingest.donated_PackComponent_geomtype(p_file_id))[1]='poly' THEN 5 ELSE 6 END AS ghs_size
  ) t
$f$ LANGUAGE SQL;

CREATE or replace FUNCTION ingest.feature_asis_assign_format(
    p_file_id bigint,  -- ID at ingest.donated_PackComponent
    p_layer_type text DEFAULT NULL,
    p_layer_name text DEFAULT '',
    p_glink text DEFAULT '' -- ex. http://git.AddressForAll.org/out-BR2021-A4A/blob/main/data/SP/RibeiraoPreto/_pk058/
) RETURNS text AS $f$
  SELECT  format(
   $$<tr>
<td><b>%s</b><br/>(%s)</td>
<td><b>Quantity</b>: %s %s &#160;&#160;&#160; bbox_km2: %s &#160;&#160;&#160; %s
<br/><b>Distribution</b>: %s.
<br/><b>Package</b> file: <code>%s</code>
<br/>Sub-file: <b>%s</b> with MD5 <code>%s</code> (%s bytes modifyed in %s)
</td>
</tr>$$,
   CASE WHEN p_layer_type IS NULL THEN layerinfo[2] ELSE p_layer_type END,
   CASE WHEN p_layer_name>'' OR layerinfo[4] IS NULL THEN p_layer_name ELSE layerinfo[4] END,
   lineage->'feature_asis_summary'->>'n',
   lineage->'feature_asis_summary'->>'n_unit',
   lineage->'feature_asis_summary'->>'bbox_km2',
   CASE WHEN lineage->'feature_asis_summary'?'size' THEN 'Total size: '||(lineage->'feature_asis_summary'->>'size') ||' '|| (lineage->'feature_asis_summary'->>'size_unit') END,
   hcode_distribution_format(lineage->'feature_asis_summary'->'ghs_feature_distrib', true, p_glink|| layerinfo[3] ||'_'),
   lineage_md5,
   lineage->'file_meta'->>'size',
   substr(lineage->'file_meta'->>'modification',1,10)
  ) as htmltabline
  FROM ingest.donated_PackComponent, (SELECT ingest.donated_PackComponent_geomtype(p_file_id) as layerinfo) t
  WHERE id=p_file_id
$f$ LANGUAGE SQL;

CREATE FUNCTION ingest.package_layers_summary(
  p_pck_id real,
  p_caption text DEFAULT 'Package XX version YY, jurisdiction ZZ',
  p_glink text DEFAULT '' -- ex. http://git.AddressForAll.org/out-BR2021-A4A/blob/main/data/SP/RibeiraoPreto/_pk058/
) RETURNS xml AS $f$
  SELECT xmlelement(
  	 name table,
  	 xmlelement(name caption, p_caption),
  	 xmlagg( trinfo::xml ORDER BY trinfo )
  	)
  FROM (
    SELECT ingest.feature_asis_assign_format(id, null, '', p_glink) AS trinfo
    FROM ingest.donated_PackComponent
    WHERE packvers_id=p_pck_id
  ) t
$f$ LANGUAGE SQL;
-- SELECT volat_file_write( '/tmp/pg_io/pk'||floor(pck_id)::text||'readme_table.txt', ingest.package_layers_summary(pck_id)::text ) FROM (select distinct pck_id from ingest.donated_PackComponent) t;

-----

CREATE FUNCTION ingest.geojson_load(
  p_file text, -- absolute path and filename, test with '/tmp/pg_io/EXEMPLO3.geojson'
  p_ftid int,  -- REFERENCES ingest.fdw_feature_type(ftid)
  p_pck_id real,
  p_pck_fileref_sha256 text,
  p_ftype text DEFAULT NULL,
  p_to4326 boolean DEFAULT true
) RETURNS text AS $f$

  DECLARE
    q_file_id integer;
    jins_count bigint;
    q_ret text;
  BEGIN

  INSERT INTO ingest.donated_PackComponent(p_pck_id,ftid,/*file_type,*/file_meta/*,pck_fileref_sha256*/)
     SELECT p_pck_id, p_ftid::smallint,
            COALESCE( p_ftype, substring(p_file from '[^\.]+$') ),
            geojson_readfile_headers(p_file)/*,*/
            --p_pck_fileref_sha256
     RETURNING file_id INTO q_file_id;

  WITH jins AS (
    INSERT INTO ingest.tmp_geojson_feature
     SELECT *
     FROM geojson_readfile_features_jgeom(p_file, q_file_id )
    RETURNING 1
   )
   SELECT COUNT(*) FROM jins INTO jins_count;

  WITH ins2 AS (
    INSERT INTO ingest.feature_asis
     SELECT file_id, feature_id, properties,
            CASE WHEN p_to4326 AND ST_SRID(geom)!=4326 THEN ST_Transform(geom,4326) ELSE geom END
     FROM (
       SELECT file_id, feature_id, properties,
              ST_GeomFromGeoJSON(jgeom) geom
       FROM ingest.tmp_geojson_feature
       WHERE file_id = q_file_id
     ) t
    RETURNING 1
   )
   SELECT 'Inserted in tmp '|| jins_count ||' items from file_id '|| q_file_id
         ||E'.\nInserted in feature '|| (SELECT COUNT(*) FROM ins2) ||' items.'
         INTO q_ret;

  DELETE FROM ingest.tmp_geojson_feature WHERE file_id = q_file_id;
  RETURN q_ret;
 END;
$f$ LANGUAGE PLpgSQL;

CREATE or replace FUNCTION ingest.getmeta_to_file(
  p_file text,
  p_ftid int,
  p_pck_id bigint,
  p_pck_fileref_sha256 text,
  p_id_profile_params int,
  p_ftype text DEFAULT NULL
  -- proc_step = 1
  -- ,p_size_min int DEFAULT 5
) RETURNS bigint AS $f$
-- with ... check
 WITH filedata AS (
   SELECT p_pck_id, p_ftid,
          CASE
            WHEN (fmeta->'size')::int<5 OR (fmeta->>'hash_md5')='' THEN NULL --guard
            ELSE fmeta->>'hash_md5'
          END AS hash_md5,
          (fmeta - 'hash_md5') AS fmeta
   FROM (
       SELECT jsonb_pg_stat_file(p_file,true) as fmeta
   ) t
 ),
  file_exists AS (
    SELECT id,proc_step
    FROM ingest.donated_PackComponent
    WHERE packvers_id=p_pck_id AND lineage_md5=(SELECT hash_md5 FROM filedata) AND ftid=p_ftid
  ), ins AS (
   INSERT INTO ingest.donated_PackComponent(packvers_id,ftid,lineage_md5,lineage)
      SELECT p_pck_id, p_ftid, hash_md5, (SELECT jsonb_build_object('hcode_distribution_parameters',distribution_parameters,'hcode_signature_parameters',signature_parameters ) FROM ingest.hcode_parameters WHERE id_profile_params = $5) || jsonb_build_object('file_meta',fmeta) FROM filedata
   ON CONFLICT DO NOTHING
   RETURNING id
  )
  SELECT id FROM (
      SELECT id, 1 as proc_step FROM ins
      UNION ALL
      SELECT id, proc_step      FROM file_exists
  ) t WHERE proc_step=1
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.getmeta_to_file(text,int,bigint,text,int,text)
  IS 'Reads file metadata and inserts it into ingest.donated_PackComponent. If proc_step=1 returns valid ID else NULL.'
;

CREATE or replace FUNCTION ingest.getmeta_to_file(
  p_file text,
  p_ftid int,
  p_pck_id bigint
) RETURNS bigint AS $f$
 WITH filedata AS (
   SELECT p_pck_id, p_ftid,
          CASE
            WHEN (fmeta->'size')::int<5 OR (fmeta->>'hash_md5')='' THEN NULL --guard
            ELSE fmeta->>'hash_md5'
          END AS hash_md5,
          (fmeta - 'hash_md5') AS fmeta
   FROM (
       SELECT jsonb_pg_stat_file(p_file,true) as fmeta
   ) t
 ),
  file_exists AS (
    SELECT id
    FROM ingest.donated_PackComponent
    WHERE packvers_id=p_pck_id AND lineage_md5=(SELECT hash_md5 FROM filedata) AND ftid=p_ftid
  )
  SELECT id FROM file_exists
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.getmeta_to_file(text,int,bigint)
  IS 'Reads file metadata and return id if exists in ingest.donated_PackComponent.'
;

CREATE or replace FUNCTION ingest.getmeta_to_file(
  p_file text,   -- 1.
  p_ftname text, -- 2. define o layer... um file pode ter mais de um layer??
  p_pck_id bigint
) RETURNS bigint AS $wrap$
    SELECT ingest.getmeta_to_file(
      $1,
      (SELECT ftid::int FROM ingest.fdw_feature_type WHERE ftname=lower($2)),
      $3
    );
$wrap$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.getmeta_to_file(text,text,bigint)
  IS 'Wrap para ingest.getmeta_to_file(text,int,bigint) usando ftName ao invés de ftID.'
;

CREATE or replace FUNCTION ingest.getmeta_to_file(
  p_file text,   -- 1.
  p_ftname text, -- 2. define o layer... um file pode ter mais de um layer??
  p_pck_id bigint,
  p_pck_fileref_sha256 text,
  p_id_profile_params int,
  p_ftype text DEFAULT NULL -- 6
) RETURNS bigint AS $wrap$
    SELECT ingest.getmeta_to_file(
      $1,
      (SELECT ftid::int FROM ingest.fdw_feature_type WHERE ftname=lower($2)),
      $3, $4, $5, $6
    );
$wrap$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.getmeta_to_file(text,text,bigint,text,int,text)
  IS 'Wrap para ingest.getmeta_to_file() usando ftName ao invés de ftID.'
;
-- ex. select ingest.getmeta_to_file('/tmp/a.csv',3,555);
-- ex. select ingest.getmeta_to_file('/tmp/b.shp','geoaddress_full',555);

/* ver VIEW
CREATE FUNCTION ingest.fdw_feature_type_refclass_tab(
  p_ftid integer
) RETURNS TABLE (like ingest.fdw_feature_type) AS $f$
  SELECT *
  FROM ingest.fdw_feature_type
  WHERE ftid = 10*round(p_ftid/10)
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.fdw_feature_type_refclass_tab(integer)
  IS 'Feature class of a feature_type, returing it as table.'
;
CREATE FUNCTION ingest.fdw_feature_type_refclass_jsonb(
  p_ftid integer
) RETURNS JSONB AS $wrap$
  SELECT to_jsonb(t)
  FROM ingest.fdw_feature_type_refclass_tab($1) t
$wrap$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.fdw_feature_type_refclass_jsonb(integer)
  IS 'Feature class of a feature_type, returing it as JSONb.'
;
*/

CREATE FUNCTION ingest.any_load_debug(
  p_method text,   -- 1.; shp/csv/etc.
  p_fileref text,  -- apenas referencia para ingest.donated_PackComponent
  p_ftname text,   -- featureType of layer... um file pode ter mais de um layer??
  p_tabname text,  -- tabela temporária de ingestáo
  p_pck_id text,   -- 5. id do package da Preservação.
  p_pck_fileref_sha256 text,
  p_tabcols text[] DEFAULT NULL, -- 7. array[]=tudo, senão lista de atributos de p_tabname, ou só geometria
  p_geom_name text DEFAULT 'geom',
  p_to4326 boolean DEFAULT true -- 9. on true converts SRID to 4326 .
) RETURNS JSONb AS $f$
  SELECT to_jsonb(t)
  FROM ( SELECT $1 AS method, $2 AS fileref, $3 AS ftname, $4 AS tabname, $5 AS pck_id,
                $6 pck_fileref_sha256, $7 tabcols, $8 geom_name, $9 to4326
  ) t
$f$ LANGUAGE SQL;

CREATE or replace FUNCTION ingest.feature_asis_similarity(
    p_file_id bigint,  -- ID at ingest.donated_PackComponent
    p_geom geometry,
    p_geoms geometry[]
) RETURNS jsonb AS $f$

  SELECT to_jsonb(t)
  FROM (
      SELECT (SELECT array_agg(ST_Equals(p_geom, n)) FROM unnest(p_geoms) AS n) AS geom_cmp_equals,
        CASE (SELECT (ingest.donated_PackComponent_geomtype(p_file_id))[1] AS gtype) 
        WHEN 'line' THEN (SELECT array_agg(ST_FrechetDistance(p_geom, n)) FROM unnest(p_geoms) AS n) END AS geom_cmp_frechet,
        CASE (SELECT (ingest.donated_PackComponent_geomtype(p_file_id))[1] AS gtype) 
        WHEN 'poly' THEN (SELECT array_agg( 2*ST_Area(ST_INTERSECTION(p_geom, n),true)/(ST_Area(p_geom,true)+ST_Area(n,true))) FROM unnest(p_geoms) AS n) END AS geom_cmp_intersec
  ) t;
$f$ LANGUAGE SQL;
  
CREATE or replace FUNCTION ingest.any_load(
    p_method text,   -- shp/csv/etc.
    p_fileref text,  -- apenas referencia para ingest.donated_PackComponent
    p_ftname text,   -- featureType of layer... um file pode ter mais de um layer??
    p_tabname text,  -- tabela temporária de ingestão
    p_pck_id bigint,   -- id do package da Preservação.
    p_pck_fileref_sha256 text,
    p_tabcols text[] DEFAULT NULL, -- array[]=tudo, senão lista de atributos de p_tabname, ou só geometria
    p_id_profile_params int DEFAULT 1,
    p_geom_name text DEFAULT 'geom',
    p_to4326 boolean DEFAULT true -- on true converts SRID to 4326 .
) RETURNS text AS $f$
  DECLARE
    q_file_id integer;
    q_query text;
    q_query_cad text;
    feature_id_col text;
    use_tabcols boolean;
    msg_ret text;
    num_items bigint;
    stats bigint[];
    stats_dup bigint[];
  BEGIN
  q_file_id := ingest.getmeta_to_file(p_fileref,p_ftname,p_pck_id,p_pck_fileref_sha256,p_id_profile_params); -- not null when proc_step=1. Ideal retornar array.
  
  IF q_file_id IS NULL THEN
    RETURN format(E'ERROR: file-read problem or data ingested before.\nSee %s\nor use make delete_file id=%s to delete data.\nSee ingest.vw03full_layer_file.',p_fileref,ingest.getmeta_to_file(p_fileref,p_ftname,p_pck_id));
  END IF;
  IF p_tabcols=array[]::text[] THEN  -- condição para solicitar todas as colunas
    p_tabcols = rel_columns(p_tabname);
  END IF;
  IF 'gid'=ANY(p_tabcols) THEN
    feature_id_col := 'gid';
    p_tabcols := array_remove(p_tabcols,'gid');
  ELSE
    feature_id_col := 'row_number() OVER () AS gid';
  END IF;
  -- RAISE NOTICE E'\n===tabcols:\n %\n===END tabcols\n',  array_to_string(p_tabcols,',');
  IF p_tabcols is not NULL AND array_length(p_tabcols,1)>0 THEN
    p_tabcols   := sql_parse_selectcols(p_tabcols); -- clean p_tabcols
    use_tabcols := true;
  ELSE
    use_tabcols := false;
  END IF;
  IF 'geom'=ANY(p_tabcols) THEN
    p_tabcols := array_remove(p_tabcols,'geom');
  END IF;
  q_query := format(
      $$
      WITH
      scan AS (
        SELECT %s AS file_id, gid, properties,
               CASE
                 WHEN ST_SRID(geom)=0 THEN ST_SetSRID(geom,4326)
                 WHEN %s AND ST_SRID(geom)!=4326 AND %s THEN ST_Transform(geom,4326)
                 ELSE geom
               END AS geom
        FROM (
            SELECT %s,  -- feature_id_col
                 %s as properties,
                 %s -- geom
            FROM %s %s
          ) t
      ),
      mask AS (SELECT geom FROM ingest.vw02full_donated_packfilevers WHERE id=%s LIMIT 1),
      a AS (
        SELECT file_id, gid, properties, geom, ( B'000000000' ||  (NOT(ST_IsSimple(geom)))::int::bit || (NOT(ST_IsValid(geom)))::int::bit || (NOT(ST_Intersects(geom,(SELECT geom FROM ingest.vw02full_donated_packfilevers WHERE id=%s))))::int::bit ) AS error_mask
        FROM scan
      ),
      b AS (
        SELECT file_id, gid, properties, geom, (error_mask | ( B'00000' || (GeometryType(geom) NOT IN %s)::int::bit || (geom IS NULL)::int::bit || (NOT(CASE (SELECT (ingest.donated_PackComponent_geomtype(%s))[1]) WHEN 'poly' THEN ST_Area(geom,true) > 5 WHEN 'line' THEN ST_Length(geom,true) > 2 ELSE FALSE END))::int::bit || (ST_IsEmpty(geom))::int::bit || B'000' )) AS error_mask
        FROM (
           SELECT file_id, gid,
                  properties,
                  CASE (SELECT (ingest.donated_PackComponent_geomtype(%s))[1])
                    WHEN 'point' THEN ST_ReducePrecision( ST_Intersection(geom,(SELECT geom FROM mask)), 0.000001 )
                    ELSE ST_SimplifyPreserveTopology( -- remove collinear points 
			    ST_ReducePrecision( -- round decimal degrees of SRID 4326, ~1 meter
			      ST_Intersection( geom, (SELECT geom FROM mask) )
			      ,0.000001
		            ),
			    0.00000001
		    )
	          END AS geom,
	          error_mask
           FROM a
           WHERE bit_count(error_mask) = 0
           ) t
      ),
      stats AS (
      SELECT ARRAY [
            (SELECT COUNT(gid) FROM scan)::bigint,
            (COUNT(gid) filter (WHERE get_bit(error_mask,1) = 1))::bigint, -- intersects
            (COUNT(gid) filter (WHERE get_bit(error_mask,2) = 1))::bigint, -- invalid
            (COUNT(gid) filter (WHERE get_bit(error_mask,3) = 1))::bigint, -- simple
            (COUNT(gid) filter (WHERE get_bit(error_mask,4) = 1))::bigint, -- empty
            (COUNT(gid) filter (WHERE get_bit(error_mask,5) = 1))::bigint, -- small
            (COUNT(gid) filter (WHERE get_bit(error_mask,6) = 1))::bigint, -- null
            (COUNT(gid) filter (WHERE get_bit(error_mask,7) = 1))::bigint  -- invalid_type
            ]
        FROM ((SELECT * FROM b ) UNION (SELECT * FROM a WHERE gid NOT IN (SELECT gid FROM b) )) t
      ),
      ins_asis AS (
        INSERT INTO ingest.feature_asis
        SELECT file_id, gid, properties, geom
        FROM b t
	    WHERE  bit_count(error_mask) = 0 
        RETURNING 1
      ),
      ins_asis_discarded AS (
        INSERT INTO ingest.feature_asis_discarded
        SELECT file_id, gid, properties || jsonb_build_object('error_mask',error_mask), geom
        FROM ((SELECT * FROM b ) UNION (SELECT * FROM a WHERE gid NOT IN (SELECT gid FROM b) )) t
	    WHERE  bit_count(error_mask) <> 0 
        RETURNING 1
      )
      SELECT array_append(array_append( (SELECT * FROM stats), (SELECT COUNT(*) FROM ins_asis) ), (SELECT COUNT(*) FROM ins_asis_discarded))
    $$,
    q_file_id,
    iif(p_to4326,'true'::text,'false'),  -- decide ST_Transform
    iif(p_to4326,'true'::text,'false'),  -- decide ST_Transform
    feature_id_col,
    iIF( use_tabcols, 'to_jsonb(subq)'::text, E'\'{}\'::jsonb' ), -- properties
    CASE WHEN lower(p_geom_name)='geom' THEN 'geom' ELSE p_geom_name||' AS geom' END,
    p_tabname,
    iIF( use_tabcols, ', LATERAL (SELECT '|| array_to_string(p_tabcols,',') ||') subq',  ''::text ),
    p_pck_id,
    p_pck_id,
        (CASE (SELECT (ingest.donated_PackComponent_geomtype(q_file_id))[1]) 
        WHEN 'point' THEN $$('POINT')$$ 
        WHEN 'poly'  THEN $$('POLYGON'   ,'MULTIPOLYGON')$$ 
        WHEN 'line'  THEN $$('LINESTRING','MULTILINESTRING')$$
        END),
    q_file_id,
    q_file_id
  );
  q_query_cad := format(
      $$
      WITH
      scan AS (
        SELECT %s, gid, properties
        FROM (
            SELECT %s,  -- feature_id_col
                 %s as properties
            FROM %s %s
          ) t
      ),
      ins AS (
        INSERT INTO ingest.cadastral_asis
           SELECT *
           FROM scan WHERE properties IS NOT NULL
        RETURNING 1
      )
      SELECT COUNT(*) FROM ins
    $$,
    q_file_id,
    feature_id_col,
    iIF( use_tabcols, 'to_jsonb(subq)'::text, E'\'{}\'::jsonb' ), -- properties
    p_tabname,
    iIF( use_tabcols, ', LATERAL (SELECT '|| array_to_string(p_tabcols,',') ||') subq',  ''::text )
  );

  IF (SELECT ftid::int FROM ingest.fdw_feature_type WHERE ftname=lower(p_ftname))<20 THEN -- feature_type id
    EXECUTE q_query_cad INTO num_items;
    msg_ret := format(E'From file_id=%s inserted type=%s\nin cadastral_asis %s items.', q_file_id, p_ftname, num_items);
  ELSE
    EXECUTE q_query INTO stats;
    num_items := stats[9];
    msg_ret := format(
        E'From file_id=%s inserted type=%s.\nStatistics:\n
        %s',
        q_file_id, p_ftname, format(
        E'Originals: %s items.\n
        Not Intersecs: %s items.\n
        Invalid: %s items.\n
        Not simple: %s items.\n
        Empty: %s items.\n
        Small: %s items.\n
        Null: %s items.\n
        Invalid geometry type: %s items.\n
        Inserted feature_asis: %s items.\n
        Inserted feature_asis_discarded: %s items.\n',
        VARIADIC stats
    )
    );
  END IF;
  
  IF num_items>0 AND (SELECT ftid::int FROM ingest.fdw_feature_type WHERE ftname=lower(p_ftname))>=20 THEN
    q_query := format(
        $$
        WITH dup AS (
            SELECT file_id, kx_ghs9, min(feature_id) AS min_feature_id
            FROM ingest.feature_asis
            WHERE file_id = %s
            GROUP BY 1,2
            HAVING count(*) > 1
            ORDER BY 1,2
        ),
        dup_mask AS (
        SELECT *, B'00010000000' AS error_mask
        FROM ingest.feature_asis
        WHERE (file_id, kx_ghs9) IN ( SELECT file_id, kx_ghs9 FROM dup)
        ),
        dup_agg AS (
            SELECT t.file_id, t.feature_id, f.properties || jsonb_build_object('properties_agg',t.properties,'is_agg','true'::jsonb) || ingest.feature_asis_similarity(%s,f.geom,geoms), f.geom
            FROM (
                SELECT min(file_id) AS file_id, min(feature_id) AS feature_id, jsonb_agg(properties || jsonb_build_object('feature_id',feature_id)) AS properties, kx_ghs9, array_agg(geom) AS geoms
                FROM ( SELECT * FROM dup_mask ) t
                GROUP BY file_id, kx_ghs9
                ORDER BY file_id, kx_ghs9
                ) AS t
            LEFT JOIN ingest.feature_asis f
            ON t.file_id = f.file_id AND t.feature_id = f.feature_id
        ),
        ins_asis_discarded AS (
            INSERT INTO ingest.feature_asis_discarded (file_id, feature_id, properties, geom)
            SELECT file_id, feature_id, ( properties || jsonb_build_object('error_mask', error_mask) ) AS properties, geom
            FROM dup_mask t
            RETURNING 1
        ),
        del AS (
            DELETE FROM ingest.feature_asis WHERE (file_id, kx_ghs9) IN ( SELECT file_id, kx_ghs9 FROM dup)
            RETURNING 1
        ),
        ins AS (
            INSERT INTO ingest.feature_asis SELECT * FROM dup_agg
            RETURNING 1
        )
        SELECT array_append(array_append((SELECT ARRAY[COUNT(*)] FROM del), (SELECT COUNT(*) FROM ins_asis_discarded) ), (SELECT COUNT(*) FROM ins) )
        $$, 
        q_file_id,
        q_file_id
    );
    EXECUTE q_query INTO stats_dup;

    msg_ret := format(
        E'From file_id=%s inserted type=%s.\n
        %s\n',
        q_file_id,
        p_ftname,
        format(
        E'Statistics:\n.
        Before deduplication:\n
        Originals: %s items.\n
        Not Intersecs: %s items.\n
        Invalid: %s items.\n
        Not simple: %s items.\n
        Empty: %s items.\n
        Small: %s items.\n
        Null: %s items.\n
        Invalid geometry type: %s items.\n
        Inserted in feature_asis: %s items.\n
        Inserted in feature_asis_discarded: %s items.\n\n
        After deduplication:\n
        Removed duplicates from feature_asis: %s items.\n
        Inserted in feature_asis_discarded (duplicates): %s items.\n
        Inserted in feature_asis (aggregated duplicates): %s items.\n
        Resulting in feature_asis: %s',
        VARIADIC (stats || stats_dup || ARRAY[num_items-stats_dup[1]+stats_dup[3]])
        )
    );

    UPDATE ingest.donated_PackComponent
    SET proc_step=2,   -- if insert process occurs after q_query.
        lineage = lineage || ingest.feature_asis_assign(q_file_id) || 
        jsonb_build_object('statistics',(stats || stats_dup || ARRAY[num_items-stats_dup[1]+stats_dup[3]]) )

    WHERE id=q_file_id;
  END IF;

  IF num_items>0 THEN
    UPDATE ingest.donated_PackComponent
    SET proc_step=3,   -- if insert process occurs after q_query.
        lineage =  lineage || ingest.feature_asis_assign_signature(q_file_id)
    WHERE id=q_file_id;
  END IF;

  RETURN msg_ret;
  END;
$f$ LANGUAGE PLpgSQL;
COMMENT ON FUNCTION ingest.any_load(text,text,text,text,bigint,text,text[],int,text,boolean)
  IS 'Load (into ingest.feature_asis) shapefile or any other non-GeoJSON, of a separated table.'
;
-- posto ipiranga logo abaixo..  sorvetorua.
-- ex. SELECT ingest.any_load('/tmp/pg_io/NRO_IMOVEL.shp','geoaddress_none','pk027_geoaddress1',27,array['gid','textstring']);

CREATE or replace FUNCTION ingest.any_load(
    p_method text,   -- 1.  shp/csv/etc.
    p_fileref text,  -- 2. apenas referencia para ingest.donated_PackComponent
    p_ftname text,   -- 3. featureType of layer... um file pode ter mais de um layer??
    p_tabname text,  -- 4. tabela temporária de ingestáo
    p_pck_id text,   -- 5. id do package da Preservação no formato "a.b".
    p_pck_fileref_sha256 text,   -- 6
    p_tabcols text[] DEFAULT NULL,   -- 7. lista de atributos, ou só geometria
    p_id_profile_params int DEFAULT 1,
    p_geom_name text DEFAULT 'geom', -- 8
    p_to4326 boolean DEFAULT true    -- 9. on true converts SRID to 4326 .
) RETURNS text AS $wrap$
   SELECT ingest.any_load($1, $2, $3, $4, to_bigint($5), $6, $7, $8, $9,$10)
$wrap$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.any_load(text,text,text,text,text,text,text[],int,text,boolean)
  IS 'Wrap to ingest.any_load(1,2,3,4=real) using string format DD_DD.'
;

CREATE FUNCTION ingest.osm_load(
    p_fileref text,  -- apenas referencia para ingest.donated_PackComponent
    p_ftname text,   -- featureType of layer... um file pode ter mais de um layer??
    p_tabname text,  -- tabela temporária de ingestáo
    p_pck_id bigint,   -- id do package da Preservação.
    p_pck_fileref_sha256 text,
    p_tabcols text[] DEFAULT NULL, -- array[]=tudo, senão lista de atributos de p_tabname, ou só geometria
    p_id_profile_params int DEFAULT 1,
    p_geom_name text DEFAULT 'way',
    p_to4326 boolean DEFAULT false -- on true converts SRID to 4326 .
) RETURNS text AS $f$
  DECLARE
    q_file_id integer;
    q_query text;
    feature_id_col text;
    use_tabcols boolean;
    msg_ret text;
    num_items bigint;
    num_items_ins bigint;
    num_items_del bigint;
  BEGIN
  q_file_id := ingest.getmeta_to_file(p_fileref,p_ftname,p_pck_id,p_pck_fileref_sha256,p_id_profile_params); -- not null when proc_step=1. Ideal retornar array.
  IF q_file_id IS NULL THEN
    RETURN format(E'ERROR: file-read problem or data ingested before.\nSee %s\nor use make delete_file id=%s to delete data.\nSee ingest.vw03full_layer_file.',p_fileref,ingest.getmeta_to_file(p_fileref,p_ftname,p_pck_id));
  END IF;
  IF p_tabcols=array[]::text[] THEN  -- condição para solicitar todas as colunas
    p_tabcols = rel_columns(p_tabname);
  END IF;
  IF 'gid'=ANY(p_tabcols) THEN
    feature_id_col := 'gid';
    p_tabcols := array_remove(p_tabcols,'gid');
  ELSE
    feature_id_col := 'row_number() OVER () AS gid';
  END IF;
  IF p_geom_name=ANY(p_tabcols) THEN
    p_tabcols := array_remove(p_tabcols,p_geom_name);
  END IF;
  IF p_tabcols is not NULL AND array_length(p_tabcols,1)>1 THEN
    p_tabcols   := sql_parse_selectcols(p_tabcols); -- clean p_tabcols
    use_tabcols := true;
  ELSE
    use_tabcols := false;
  END IF;
  q_query := format(
      $$
      WITH
      scan AS (
        SELECT %s AS file_id, gid, properties,
               CASE
                 WHEN ST_SRID(geom)=0 THEN ST_SetSRID(geom,4326)
                 WHEN %s AND ST_SRID(geom)!=4326 THEN ST_Transform(geom,4326)
                 ELSE geom
               END AS geom
        FROM (
            SELECT %s,  -- feature_id_col
                 %s as properties,
                 %s -- geom
            FROM %s %s
          ) t
      ),
      mask AS (SELECT geom FROM ingest.vw02full_donated_packfilevers WHERE id=%s LIMIT 1),
      ins AS (
        INSERT INTO ingest.feature_asis
        SELECT *
        FROM (
           SELECT file_id, gid,
                  properties,
                  CASE (SELECT (ingest.donated_PackComponent_geomtype(%s))[1])
                    WHEN 'point' THEN ST_ReducePrecision( ST_Intersection(geom,(SELECT geom FROM mask)), 0.000001 )
                    ELSE ST_SimplifyPreserveTopology( -- remove collinear points 
			    ST_ReducePrecision( -- round decimal degrees of SRID 4326, ~1 meter
			      ST_Intersection( geom, (SELECT geom FROM mask) )
			      ,0.000001
		            ),
			    0.00000001
		    )
	          END AS geom
           FROM scan
           WHERE ST_IsSimple(geom)
                AND ST_IsValid(geom)
                AND ST_Intersects(geom,(SELECT geom FROM ingest.vw02full_donated_packfilevers WHERE id=%s))
           ) t
	    WHERE geom IS NOT NULL 
            AND CASE (SELECT (ingest.donated_PackComponent_geomtype(%s))[1]) WHEN 'poly' THEN ST_Area(geom,true) > 5 WHEN 'line' THEN ST_Length(geom,true) > 2 ELSE TRUE END
            AND NOT(ST_IsEmpty(geom)) 
        RETURNING 1
      )
      SELECT COUNT(*) FROM ins
    $$,
    q_file_id,
    iif(p_to4326,'true'::text,'false'),  -- decide ST_Transform
    feature_id_col,
    iIF( use_tabcols, $$to_jsonb(subq) - 'tags' || (subq).tags $$::text, $$tags$$ ), -- properties
    CASE WHEN lower(p_geom_name)='geom' THEN 'geom' ELSE p_geom_name||' AS geom' END,
    p_tabname,
    iIF( use_tabcols, ', LATERAL (SELECT '|| array_to_string(p_tabcols,',') ||') subq',  ''::text ),
    p_pck_id,
    q_file_id,
    p_pck_id,
    q_file_id
  );

  EXECUTE q_query INTO num_items;
  msg_ret := format(
    E'From file_id=%s inserted type=%s\nin feature_asis %s items.',
    q_file_id, p_ftname, num_items
  );

  IF num_items>0 AND (SELECT ftid::int FROM ingest.fdw_feature_type WHERE ftname=lower(p_ftname))>=20 THEN
    q_query := format(
        $$
        WITH dup AS (
            SELECT file_id, kx_ghs9
            FROM ingest.feature_asis
            WHERE file_id = %s
            GROUP BY 1,2
            HAVING count(*) > 1
            ORDER BY 1,2
        ),
        dup_agg AS (
            SELECT t.file_id, t.feature_id, f.properties || jsonb_build_object('properties_agg',t.properties,'is_agg','true'::jsonb) || ingest.feature_asis_similarity(%s,f.geom,geoms), f.geom
            FROM (
                SELECT min(file_id) AS file_id, min(feature_id) AS feature_id, jsonb_agg(properties || jsonb_build_object('feature_id',feature_id)) AS properties, kx_ghs9
                FROM ingest.feature_asis
                WHERE (file_id, kx_ghs9) IN ( SELECT * FROM dup)
                GROUP BY file_id, kx_ghs9
                ORDER BY file_id, kx_ghs9
                ) AS t
            LEFT JOIN ingest.feature_asis f
            ON t.file_id = f.file_id AND t.feature_id = f.feature_id
        ),
        del AS (
            DELETE FROM ingest.feature_asis WHERE (file_id, kx_ghs9) IN ( SELECT * FROM dup)
            RETURNING 1
        ),
        ins AS (
            INSERT INTO ingest.feature_asis SELECT * FROM dup_agg
            RETURNING 1
        )
        SELECT (SELECT count(*) FROM ins) AS delete, count(*) AS insert FROM del;
        $$,
        q_file_id,
        q_file_id
    );
    EXECUTE q_query INTO num_items_ins, num_items_del;

    msg_ret := format(
        E'From file_id=%s inserted type=%s\nin feature_asis %s items.\nRemoved %s duplicates and inserted %s aggregated duplicates.\nResulting in %s items at feature_asis. ',
        q_file_id, p_ftname, num_items, num_items_del, num_items_ins,num_items-num_items_del+num_items_ins
    );
  END IF;

  IF num_items>0 THEN
    UPDATE ingest.donated_PackComponent
    SET proc_step=2,   -- if insert process occurs after q_query.
        lineage = lineage || ingest.feature_asis_assign(q_file_id) || 
        jsonb_build_object('num_itens_stat',jsonb_build_object('originals',num_items,
                          'duplicates' ,num_items_del,
                          'aggregates' ,num_items_ins,
                          'feature_asis',num_items-num_items_del+num_items_ins))
    WHERE id=q_file_id;
  END IF;

  IF num_items>0 THEN
    UPDATE ingest.donated_PackComponent
    SET proc_step=3,   -- if insert process occurs after q_query.
        lineage =  lineage || ingest.feature_asis_assign_signature(q_file_id)
    WHERE id=q_file_id;
  END IF;
  
  RETURN msg_ret;
  END;
$f$ LANGUAGE PLpgSQL;

CREATE FUNCTION ingest.osm_load(
    p_fileref text,  -- 1. apenas referencia para ingest.donated_PackComponent
    p_ftname text,   -- 2. featureType of layer... um file pode ter mais de um layer??
    p_tabname text,  -- 3. tabela temporária de ingestáo
    p_pck_id text,   -- 4. id do package da Preservação no formato "a.b".
    p_pck_fileref_sha256 text,   -- 5
    p_tabcols text[] DEFAULT NULL,   -- 6. lista de atributos, ou só geometria
    p_id_profile_params int DEFAULT 1,       -- 7
    p_geom_name text DEFAULT 'way', -- 8
    p_to4326 boolean DEFAULT false    -- 9. on true converts SRID to 4326 .
) RETURNS text AS $wrap$
   SELECT ingest.osm_load($1, $2, $3, to_bigint($4), $5, $6, $7, $8, $9)
$wrap$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.osm_load(text,text,text,text,text,text[],int,text,boolean)
  IS 'Wrap to ingest.osm_load(1,2,3,4=real) using string format DD_DD.'
;

-----
CREATE FUNCTION ingest.qgis_vwadmin_feature_asis(
  p_mode text -- 'create' or 'drop'
) RETURNS text AS $f$
  DECLARE
    q_query text;
  BEGIN
    SELECT string_agg( format(
      CASE  p_mode
        WHEN 'drop' THEN 'DROP VIEW IF EXISTS vw_asis_pk%s_f%s_%s; -- %s.'
        ELSE 'CREATE VIEW vw_asis_pk%s_f%s_%s AS SELECT feature_id AS gid, properties, geom FROM ingest.feature_asis WHERE file_id=%s;'
      END
      ,dg_preserv.packid_to_str(pck_id,true)
      ,file_id
      ,feature_asis_summary->>'n_unit'
      ,file_id
    ), E' \n' )
    INTO q_query
    FROM ingest.donated_PackComponent;
    EXECUTE q_query;
    RETURN E'\n(check before NO BUGs with SELECT * FROM ingest.vw05test_feature_asis)\n---\nok! all '||p_mode||E'\nCheck on psql by \\dv vw_asis_*';
  END;
$f$ LANGUAGE PLpgSQL;
-- select ingest.qgis_vwadmin_feature_asis('create');
----

CREATE FUNCTION ingest.donated_PackComponent_distribution_prefixes(
  p_file_id int
) RETURNS text[] AS $f$
  SELECT array_agg(p ORDER BY length(p) desc, p) FROM (
    SELECT jsonb_object_keys(lineage->'feature_asis_summary'->'distribution') p
    FROM ingest.donated_PackComponent WHERE id=p_file_id
  ) t
$f$ LANGUAGE SQL;
-- for use with geohash_checkprefix()
-- select file_id, ingest.donated_PackComponent_distribution_prefixes(file_id)as prefixes FROM ingest.donated_PackComponent


------------------------
------------------------


CREATE or replace FUNCTION ingest.feature_asis_export(p_file_id bigint)
RETURNS TABLE (kx_ghs9 text, gid int, info jsonb, geom geometry(Point,4326)) AS $f$
DECLARE
    p_ftname text;
BEGIN
  p_ftname := (SELECT ft_info->>'class_ftname' FROM ingest.vw03full_layer_file WHERE id=p_file_id);
  CASE p_ftname
  WHEN 'geoaddress', 'parcel' THEN
  RETURN QUERY
  SELECT 
        t.ghs,
        t.row_id::int AS gid, 
        CASE p_ftname
        WHEN 'parcel' THEN jsonb_strip_nulls(jsonb_build_object('error_code', error_code, 'bytes',length(St_asGeoJson(t.geom))) || address ) ELSE jsonb_strip_nulls(jsonb_build_object('error_code', error_code) || address) END AS info,
        t.geom
  FROM (
      SELECT file_id, fa.geom,
        CASE (SELECT housenumber_system_type FROM ingest.vw03full_layer_file WHERE id=p_file_id)
        WHEN 'metric' THEN
        ROW_NUMBER() OVER(ORDER BY properties->>'via_name', to_bigint(properties->>'house_number'))
        WHEN 'bh-metric' THEN
        ROW_NUMBER() OVER(ORDER BY properties->>'via_name', to_bigint(regexp_replace(properties->>'house_number', '\D', '', 'g')), regexp_replace(properties->>'house_number', '[^[:alpha:]]', '', 'g') )
        WHEN 'street-metric' THEN
        ROW_NUMBER() OVER(ORDER BY properties->>'via_name', regexp_replace(properties->>'house_number', '[^[:alnum:]]', '', 'g'))
        WHEN 'block-metric' THEN
        ROW_NUMBER() OVER(ORDER BY properties->>'via_name', to_bigint(split_part(replace(properties->>'house_number',' ',''), '-', 1)), to_bigint(split_part(replace(properties->>'house_number',' ',''), '-', 2)))
        ELSE
        ROW_NUMBER() OVER(ORDER BY properties->>'via_name', to_bigint(properties->>'house_number'))
        --ROW_NUMBER() OVER(ORDER BY  properties->>'address')) 
        -- or (properties->>'via_name')||'#'||properties->>'house_number'
      END AS row_id,
      CASE WHEN (properties->>'is_agg')::boolean THEN 100 END AS error_code,
      COALESCE(nullif(properties->'is_complemento_provavel','null')::boolean,false) AS is_compl,
      properties->>'via_name' AS via_name,
      properties->>'house_number' AS house_number,
      --COALESCE((properties->>'via_name') || ', ' || (properties->>'house_number'), properties->>'via_name', properties->>'house_number') AS address,
      CASE WHEN (properties->>'via_name' IS NULL) OR (properties->>'house_number' IS NULL) 
      THEN jsonb_strip_nulls(jsonb_build_object('via_name',properties->>'via_name', 'house_number', properties->>'house_number'))
      ELSE jsonb_build_object('address',(properties->>'via_name') || ', ' || (properties->>'house_number'))
      END AS address,
      fa.kx_ghs9 AS ghs
      FROM ingest.feature_asis AS fa
      WHERE fa.file_id=p_file_id
  ) t
  ORDER BY gid;

  WHEN 'nsvia' THEN
  RETURN QUERY 
  SELECT 
        t.ghs, 
        t.row_id::int AS gid, 
        jsonb_strip_nulls(jsonb_build_object('ns_name',ns_name, 'ref', ref, 'bytes',length(St_asGeoJson(t.geom)))) AS info,
        t.geom
  FROM (
      SELECT fa.file_id, fa.geom,
        ROW_NUMBER() OVER(ORDER BY fa.properties->>'ns_name') AS row_id,
        fa.properties->>'ns_name' AS ns_name,
        fa.properties->>'ref' AS ref,
        fa.kx_ghs9 AS ghs
      FROM ingest.feature_asis AS fa
      WHERE fa.file_id=p_file_id
  ) t
  ORDER BY gid;
  
  WHEN 'via', 'genericvia', 'block', 'building' THEN
  RETURN QUERY 
  SELECT 
        t.ghs, 
        t.row_id::int AS gid, 
        jsonb_strip_nulls(jsonb_build_object('via_name', via_name, 'name', name, 'ref', ref, 'bytes',length(St_asGeoJson(t.geom)))) AS info,
        t.geom
  FROM (
      SELECT fa.file_id, fa.geom,
        ROW_NUMBER() OVER(ORDER BY gid) AS row_id,
        fa.properties->>'via_name'      AS via_name,
        fa.properties->>'name'          AS name,
        fa.properties->>'ref'           AS ref,
        fa.kx_ghs9                      AS ghs
      FROM ingest.feature_asis AS fa
      WHERE fa.file_id=p_file_id
  ) t
  ORDER BY gid;
  END CASE;
END;
$f$ LANGUAGE PLpgSQL;
--$f$ LANGUAGE SQL IMMUTABLE;
-- SELECT * FROM ingest.feature_asis_export(1) t LIMIT 1000;

-- ----------------------------

DROP TABLE IF EXISTS ingest.publicating_geojsons_p3exprefix;
CREATE TABLE ingest.publicating_geojsons_p3exprefix(
 kx_ghs9   text,
 prefix text,
 gid    integer,
 info   jsonb,
 geom   geometry
);
DROP TABLE IF EXISTS ingest.publicating_geojsons_p2distrib;
CREATE TABLE ingest.publicating_geojsons_p2distrib(
 hcode    text,
 n_items  integer,
 geom     geometry
);

CREATE FUNCTION ingest.publicating_geojsons_p1(
	p_file_id    bigint,  -- e.g. 1, see ingest.donated_PackComponent
	p_isolabel_ext  text  -- e.g. 'BR-MG-BeloHorizonte', see jurisdiction_geom
) RETURNS text  AS $f$

  DELETE FROM ingest.publicating_geojsons_p3exprefix;
  INSERT INTO ingest.publicating_geojsons_p3exprefix
     SELECT kx_ghs9, NULL::text, gid, info, geom
     FROM ingest.feature_asis_export(p_file_id) t
  ;
  SELECT 'p1';
$f$ language SQL VOLATILE; --fim p1

CREATE FUNCTION ingest.publicating_geojsons_p2(
	p_file_id    bigint,  -- e.g. 1, see ingest.donated_PackComponent
	p_isolabel_ext  text, -- e.g. 'BR-MG-BeloHorizonte', see jurisdiction_geom
	p_sum  boolean  DEFAULT false
) RETURNS text  AS $f$

  UPDATE ingest.donated_PackComponent
  SET proc_step=4, 
      kx_profile = coalesce(kx_profile,'{}'::jsonb) || jsonb_build_object('ghs_distrib_mosaic', geocode_distribution_generate('ingest.publicating_geojsons_p3exprefix',7, p_sum))
  WHERE id= p_file_id
  ;

  SELECT 'p2';
$f$ language SQL VOLATILE; --fim p2

CREATE or replace FUNCTION ingest.publicating_geojsons_p3(
	p_file_id    bigint,  -- e.g. 1, see ingest.donated_PackComponent
	p_isolabel_ext  text, -- e.g. 'BR-MG-BeloHorizonte', see jurisdiction_geom
	p_fileref text        --
) RETURNS text  AS $f$

  DELETE FROM ingest.publicating_geojsons_p2distrib;
  INSERT INTO ingest.publicating_geojsons_p2distrib
    SELECT t.hcode, t.n_items,  -- length(t.hcode) AS len,
      ST_Intersection(
        ST_SetSRID( ST_geomFromGeohash(replace(t.hcode, '*', '')) ,  4326),
        (SELECT geom FROM ingest.vw01full_jurisdiction_geom WHERE isolabel_ext=p_isolabel_ext)
      ) AS geom
    FROM hcode_distribution_reduce_recursive_raw(
    	(SELECT kx_profile->'ghs_distrib_mosaic' FROM ingest.donated_PackComponent WHERE id= p_file_id),
    	1,
    	(SELECT length(st_geohash(geom)) FROM ingest.vw01full_jurisdiction_geom WHERE isolabel_ext=p_isolabel_ext),
    	(SELECT lineage->'hcode_distribution_parameters' FROM ingest.donated_PackComponent WHERE id= p_file_id)
    ) t
  ;
  SELECT pg_catalog.pg_file_unlink(p_fileref || '/'|| (CASE geomtype WHEN 'point' THEN 'pts' WHEN 'line' THEN 'lns' WHEN 'poly' THEN 'pols' END) || '_*.geojson') FROM ingest.vw03full_layer_file WHERE id=$1;

  UPDATE ingest.publicating_geojsons_p3exprefix
  SET prefix=t4.prefix
  FROM (
    WITH t1 (prefix_regex) as (
     SELECT hcode_prefixset_parse( array_agg(hcode) )
     FROM ingest.publicating_geojsons_p2distrib
    )
      SELECT hcode_prefixset_element(t.kx_ghs9,'^(?:'|| t1.prefix_regex ||')') AS prefix, t.gid
      FROM ingest.publicating_geojsons_p3exprefix t, t1
  ) t4
  WHERE t4.gid = publicating_geojsons_p3exprefix.gid
  ;

  --UPDATE ingest.publicating_geojsons_p3exprefix
  --SET info = publicating_geojsons_p3exprefix.info || t1.info
  --FROM (
    --WITH geomtype AS (
        --SELECT geomtype FROM ingest.vw03full_layer_file WHERE id=$1
    --)
    --SELECT gid, jsonb_strip_nulls(jsonb_build_object('bytes', length(St_asGeoJson(intersec)), 'size',
        --CASE (SELECT geomtype FROM geomtype)
        --WHEN 'line' THEN round(ST_Length(intersec,true)/1000.0,0.01)
        --WHEN 'poly' THEN round(ST_Area(intersec,true)/1000000.0,0.01)
        --END)) AS info
    --FROM
        --(
        --SELECT gid, ST_Intersection(geom,ST_SetSRID( ST_geomFromGeohash(prefix),4326)) AS intersec
        --FROM ingest.publicating_geojsons_p3exprefix
        --) as t
  --) t1
  --WHERE t1.gid = publicating_geojsons_p3exprefix.gid
  --;

  UPDATE ingest.donated_PackComponent
  SET proc_step=5, 
      kx_profile = kx_profile || jsonb_build_object('ghs_distrib_mosaic', (SELECT jsonb_object_agg(hcode, n_items) FROM ingest.publicating_geojsons_p2distrib))
  WHERE id= p_file_id
  ;

  DELETE FROM ingest.publicating_geojsons_p2distrib; -- limpa
  SELECT 'p3';
$f$ language SQL VOLATILE; --fim p3

CREATE or replace FUNCTION ingest.publicating_geojsons_p4(
	p_file_id    bigint,  -- e.g. 1, see ingest.donated_PackComponent
	p_isolabel_ext  text, -- e.g. 'BR-MG-BeloHorizonte', see jurisdiction_geom
	p_fileref text
) RETURNS text  AS $f$
DECLARE
    q_copy text;
BEGIN
   PERFORM write_geojsonb_Features(
    format('SELECT kx_ghs9, prefix, gid, info - ''bytes'' AS info, geom FROM ingest.publicating_geojsons_p3exprefix WHERE prefix=%L ORDER BY gid',prefix),
    format('%s/%s_%s.geojson',p_fileref,(SELECT CASE geomtype WHEN 'point' THEN 'pts' WHEN 'line' THEN 'lns' WHEN 'poly' THEN 'pols' END AS geomprefix FROM ingest.vw03full_layer_file WHERE id=$1),prefix),
    't1.geom',
    'info::jsonb',
    NULL,  -- p_cols_orderby
    NULL, -- col_id
    2
  ) FROM ( SELECT DISTINCT prefix FROM ingest.publicating_geojsons_p3exprefix ORDER BY 1 ) AS t;

  q_copy := $$
        COPY (
            SELECT name, string_agg(prefix, ' ') as ghs
            FROM
            (
                SELECT DISTINCT %s, p3.prefix
                FROM ingest.publicating_geojsons_p3exprefix p3
                LEFT JOIN ingest.feature_asis fa
                ON p3.kx_ghs9 = fa.kx_ghs9 AND fa.file_id=%s
                ORDER BY %s, p3.prefix
            ) AS t
            GROUP BY name
            ) TO '%s' CSV HEADER
    $$;

  CASE (SELECT ft_info->>'class_ftname' FROM ingest.vw03full_layer_file WHERE id=p_file_id)
  WHEN 'geoaddress', 'parcel', 'via' THEN
    EXECUTE format(q_copy,
    $$fa.properties->>'via_name' AS name$$,
    p_file_id,
    $$fa.properties->>'via_name'$$,
    p_fileref || '/distrib_viaName_ghs.csv'
    );
  WHEN 'nsvia' THEN
    EXECUTE format(q_copy,
    $$fa.properties->>'ns_name' AS name$$,
    p_file_id,
    $$fa.properties->>'ns_name'$$,
    p_fileref || '/distrib_name_ghs.csv'
    );
  WHEN 'genericvia', 'block', 'building' THEN
    EXECUTE format(q_copy,
    $$fa.properties->>'name' AS name$$,
    p_file_id,
    $$fa.properties->>'name'$$,
    p_fileref || '/distrib_name_ghs.csv'
    );
  END CASE;

  DELETE FROM ingest.publicating_geojsons_p3exprefix;  -- limpa
  RETURN (SELECT 'Arquivos de file_id='|| p_file_id::text || ' publicados em ' || p_file_id::text || '/' || (CASE geomtype WHEN 'point' THEN 'pts' WHEN 'line' THEN 'lns' WHEN 'poly' THEN 'pols' END) ||'_*.geojson' FROM ingest.vw03full_layer_file WHERE id=$1)
  ;
END
$f$ language PLpgSQL; -- fim p4

CREATE FUNCTION ingest.publicating_geojsons(
	p_file_id    bigint,  -- e.g. 1, see ingest.donated_PackComponent
	p_isolabel_ext  text, -- e.g. 'BR-MG-BeloHorizonte', see jurisdiction_geom
	p_fileref text
) RETURNS text  AS $f$
  SELECT ingest.publicating_geojsons_p1($1,$2);
  SELECT ingest.publicating_geojsons_p2($1,$2,(SELECT CASE geomtype WHEN 'point' THEN false ELSE true END FROM ingest.vw03full_layer_file WHERE id=$1));
  SELECT ingest.publicating_geojsons_p3($1,$2,$3);
  SELECT ingest.publicating_geojsons_p4($1,$2,$3);
  SELECT 'fim';
$f$ language SQL VOLATILE; -- need be a sequential PLpgSQL to neatly COMMIT?
-- Ver id em ingest.donated_PackComponent
-- SELECT ingest.publicating_geojsons(X,'BR-MG-BeloHorizonte','/tmp/pg_io');

CREATE or replace FUNCTION ingest.publicating_geojsons(
	p_ftname text,       -- e.g. 'geoaddress'
	p_isolabel_ext text, -- e.g. 'BR-MG-BeloHorizonte', see jurisdiction_geom
	p_fileref text       -- e.g. 
) RETURNS text AS $wrap$
  SELECT ingest.publicating_geojsons((SELECT id FROM ingest.vw03full_layer_file WHERE isolabel_ext = $2 AND lower(ft_info->>'class_ftname') = lower($1)),$2,$3);
$wrap$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.publicating_geojsons(text,text,text)
  IS 'Wrap to ingest.publicating_geojsons'
;
-- SELECT ingest.publicating_geojsons('geoaddress','BR-MG-BeloHorizonte','folder');


-- Armazena arquivos make_conf.yaml
CREATE TABLE ingest.lix_conf_yaml (
  jurisdiction text NOT NULL, -- jurisdição, por exemplo: BR
  t text,                     -- versão texto de make_conf.yaml.
  y jsonb                     -- arquivo make_conf.yaml. Pode ser substituído por make_conf_tpl de optim.donated_PackTpl. Tornando essa tabela desnecessária.
);
CREATE UNIQUE INDEX ON ingest.lix_conf_yaml (jurisdiction,(y->>'pack_id'));

-- Armazena templates para geração de makefile
CREATE TABLE ingest.lix_mkme_srcTpl (
  tplInputSchema_id text NOT NULL, -- identificador do template. por exemplo: ref027a
  y text,                          -- template, por exemplo make_ref027a.mustache.mk
  UNIQUE(tplInputSchema_id)
);

-- Armazena conteúdos de arquivos referentes a uma jurisdição, para geração de makefile.
-- Pode ser absorvida por optim.jurisdiction
CREATE TABLE ingest.lix_jurisd_tpl (
  jurisdiction text NOT NULL, -- jurisdição, por exemplo: BR
  tpl_last text,              -- commomLast.mustache.mk
  first_yaml jsonb,           -- commomFirst.yaml da jurisdição.
  readme_mk text,             -- template mustache para readme.
  UNIQUE(jurisdiction)
);

CREATE or replace FUNCTION ingest.lix_insert(
    file text
    ) RETURNS void AS $wrap$
    DECLARE
    yl jsonb;
    conf jsonb;
    t text;
    aux text;
    p_type text;
    jurisd text;
    BEGIN
        SELECT (regexp_matches(file, '([^/]*)$'))[1] INTO p_type;

        SELECT (regexp_matches(file, '.*-([^/-]*)/.*$'))[1] INTO jurisd;
        IF jurisd IS NULL
        THEN
            jurisd := 'INT';
        END IF;

        --RAISE NOTICE 'type : %', p_type;
        --RAISE NOTICE 'Jurisdiction : %', jurisd;

        CASE p_type
        WHEN 'make_conf.yaml' THEN
        aux:= pg_read_file(file);
        conf:= yaml_to_jsonb(aux);
        INSERT INTO ingest.lix_conf_yaml (jurisdiction,t,y) VALUES (jurisd,aux,conf)
        ON CONFLICT (jurisdiction,(y->>'pack_id')) DO UPDATE SET y = conf, t = aux;

        WHEN (select (regexp_matches(p_type, 'make_ref[0-9]+[a-z]\.mustache.mk'))[1]) THEN
        t:= pg_read_file(file);
        INSERT INTO ingest.lix_mkme_srcTpl VALUES (SUBSTRING(file,'(ref[0-9]{1,3}[a-z])'),t)
        ON CONFLICT (tplInputSchema_id) DO UPDATE SET tplInputSchema_id = t;

        WHEN 'commomFirst.yaml' THEN
        yl:= yamlfile_to_jsonb(file);
        INSERT INTO ingest.lix_jurisd_tpl (jurisdiction, first_yaml) VALUES (jurisd,yl)
        ON CONFLICT (jurisdiction) DO UPDATE SET first_yaml = yl;

        WHEN 'commomLast.mustache.mk' THEN
        t:= pg_read_file(file);
        INSERT INTO ingest.lix_jurisd_tpl (jurisdiction, tpl_last) VALUES (jurisd,t)
        ON CONFLICT (jurisdiction) DO UPDATE SET tpl_last = t;

        WHEN 'readme.mustache' THEN
        t:= pg_read_file(file);
        INSERT INTO ingest.lix_jurisd_tpl (jurisdiction, readme_mk) VALUES (jurisd,t)
        ON CONFLICT (jurisdiction) DO UPDATE SET readme_mk = t;

        END CASE;
    END;
$wrap$ LANGUAGE PLpgSQL;

--SELECT ingest.lix_insert('/var/gits/_dg/preserv-BR/src/maketemplates/commomFirst.yaml');
--SELECT ingest.lix_insert('/var/gits/_dg/preserv-BR/src/maketemplates/readme.mustache');
--SELECT ingest.lix_insert('/var/gits/_dg/preserv-PE/src/maketemplates/commomFirst.yaml');
--SELECT ingest.lix_insert('/var/gits/_dg/preserv-PE/src/maketemplates/readme.mustache');
--SELECT ingest.lix_insert('/var/gits/_dg/preserv-CO/src/maketemplates/commomFirst.yaml');
--SELECT ingest.lix_insert('/var/gits/_dg/preserv-CO/src/maketemplates/readme.mustache');
--SELECT ingest.lix_insert('/var/gits/_dg/preserv/src/maketemplates/make_ref027a.mustache.mk');
--SELECT ingest.lix_insert('/var/gits/_dg/preserv/src/maketemplates/commomLast.mustache.mk');
--SELECT ingest.lix_insert('/var/gits/_dg/preserv/src/maketemplates/commomFirst.yaml');

--SELECT ingest.lix_insert('/var/gits/_dg/preserv-BR/data/RJ/Niteroi/_pk0016.01/make_conf.yaml');
--SELECT ingest.lix_insert('/var/gits/_dg/preserv-BR/data/MG/BeloHorizonte/_pk0008.01/make_conf.yaml');


CREATE or replace FUNCTION ingest.jsonb_mustache_prepare(
  dict jsonb,  -- input
  p_type text DEFAULT 'make_conf'
) RETURNS jsonb  AS $f$
DECLARE
 packvers_id bigint;
 key text;
 method text;
 sql_select text;
 sql_view text;
 bt jsonb := 'true'::jsonb;
 bf jsonb := 'false'::jsonb;
 codec_value text[];
 orig_filename_ext text[]; 
 orig_filename_string text;
 multiple_files jsonb; 
 codec_desc_global jsonb;

 codec_desc0 jsonb DEFAULT NULL;
 codec_desc_default0 jsonb DEFAULT NULL;
 codec_desc_sobre0 jsonb DEFAULT NULL;
 codec_extension0 text DEFAULT NULL;
 codec_descr_mime0 jsonb DEFAULT NULL;

 codec_desc jsonb;
 codec_desc_default jsonb;
 codec_desc_sobre jsonb;
 codec_extension text;
 codec_descr_mime jsonb;
BEGIN
 CASE p_type -- preparing types
 WHEN 'make_conf', NULL THEN

    IF dict?'pack_id'
    THEN
        dict := jsonb_set( dict, array['pack_id'], replace(dict->>'pack_id','.','')::jsonb);
        
        RAISE NOTICE 'pack_id : %', dict->>'pack_id';
    END IF;

    IF dict?'jurisdiction'
    THEN
        dict := jsonb_set( dict, array['country_id'], to_jsonb((SELECT jurisd_base_id::int FROM ingest.vw01full_jurisdiction_geom WHERE abbrev= upper(dict->>'jurisdiction') AND jurisd_local_id=0)));

        RAISE NOTICE 'country_id : %', dict->>'country_id';
    END IF;

    IF dict?'codec:descr_encode'
    THEN
        codec_desc_global := jsonb_object(regexp_split_to_array ( dict->>'codec:descr_encode','(;|=)'));

        -- Compatibilidade com sql_view de BR-MG-BeloHorizonte/_pk0008.01
        dict := dict || codec_desc_global;

        RAISE NOTICE 'codec_desc_global : %', codec_desc_global;
    END IF;

    IF dict?'srid_proj'
    THEN
        codec_desc_global := jsonb_build_object('srid', (SELECT 952022 + floor(random()*100)));

        -- Compatibilidade com srid_proj de BR-RS-PortoAlegre/_pk0018.01
        dict := dict || codec_desc_global;

        RAISE NOTICE 'codec_desc_global : %', codec_desc_global;
    END IF;

    IF dict?'openstreetmap'
    THEN
        IF codec_desc_global IS NOT NULL
        THEN
            dict := jsonb_set( dict, array['openstreetmap','sha256file'] , to_jsonb(jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.openstreetmap.file)')::jsonpath  )->0->>'file'));
            
            dict := jsonb_set( dict, array['openstreetmap'], (dict->>'openstreetmap')::jsonb || codec_desc_global::jsonb );
        END IF;
    END IF;

    FOREACH key IN ARRAY jsonb_object_keys_asarray(dict->'layers')
    LOOP
        method := dict->'layers'->key->>'method';
        
        RAISE NOTICE 'layer : %, method: %', key, method;

        -- id_profile_params default values
        IF NOT dict->'layers'->key?'id_profile_params'
        THEN
            CASE key
            WHEN 'geoaddress'  THEN dict := jsonb_set( dict, array['layers',key,'id_profile_params'], to_jsonb(1));
            WHEN 'via'         THEN dict := jsonb_set( dict, array['layers',key,'id_profile_params'], to_jsonb(5));
            --WHEN 'block'       THEN dict := jsonb_set( dict, array['layers',key,'id_profile_params'], to_jsonb());
            --WHEN 'building'    THEN dict := jsonb_set( dict, array['layers',key,'id_profile_params'], to_jsonb());
            --WHEN 'genericvia'  THEN dict := jsonb_set( dict, array['layers',key,'id_profile_params'], to_jsonb());
            --WHEN 'nsvia'       THEN dict := jsonb_set( dict, array['layers',key,'id_profile_params'], to_jsonb());
            --WHEN 'parcel'      THEN dict := jsonb_set( dict, array['layers',key,'id_profile_params'], to_jsonb());
            ELSE
                dict := jsonb_set( dict, array['layers',key,'id_profile_params'], to_jsonb(5));
            END CASE;
        END IF;
        
        codec_desc := codec_desc0;
        codec_desc_default := codec_desc_default0;
        codec_desc_sobre := codec_desc_sobre0;
        codec_extension := codec_extension0;
        codec_descr_mime := codec_descr_mime0;

        dict := jsonb_set( dict, array['layers',key,'isCsv'], IIF(method='csv2sql',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isOgr'], IIF(method='ogr2ogr',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isOgrWithShp'], IIF(method='ogrWshp',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isShp'], IIF(method='shp2sql',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isOsm'], IIF(method='osm2sql',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isGdb'], IIF(method='gdb2sql',bt,bf) );
        
        dict := jsonb_set( dict, array['layers',key,'isGeoaddress'], IIF(key='geoaddress',bt,bf) );

        dict := jsonb_set( dict, array['layers',key,'sha256file'] , to_jsonb(jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.'|| key ||'.file)')::jsonpath  )->0->>'file'));

        dict := jsonb_set( dict, array['layers',key,'sha256file_name'] , to_jsonb(jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.'|| key ||'.file)')::jsonpath  )->0->>'name'));

        SELECT id FROM ingest.fdw_donated_packfilevers WHERE hashedfname = dict->'layers'->key->>'sha256file' INTO packvers_id;

        dict := jsonb_set( dict, array['layers',key,'fullPkID'] , to_jsonb(packvers_id));
        dict := jsonb_set( dict, array['layers',key,'layername_root'] , to_jsonb(key));
        dict := jsonb_set( dict, array['layers',key,'layername'] , to_jsonb(key || '_' || (dict->'layers'->key->>'subtype') ));
        dict := jsonb_set( dict, array['layers',key,'tabname'] , to_jsonb('pk' || (dict->'layers'->key->>'fullPkID') || '_p' || (dict->'layers'->key->>'file') || '_' || key));

        dict := jsonb_set( dict, array['layers',key,'isolabel_ext'] , to_jsonb((SELECT isolabel_ext FROM ingest.vw02full_donated_packfilevers WHERE id=packvers_id)));
        dict := jsonb_set( dict, array['layers',key,'path_root'] , to_jsonb((SELECT path || '/' || key FROM ingest.vw02full_donated_packfilevers WHERE id=packvers_id)));

        
        IF dict?'orig'
        THEN
            dict := jsonb_set( dict, array['layers',key,'sha256file_path'] , to_jsonb((dict->>'orig') || '/' || (dict->'layers'->key->>'sha256file') ));
        END IF;

        -- Caso de BR-PR-Araucaria/_pk0061.01
        IF jsonb_typeof(dict->'layers'->key->'orig_filename') = 'array'
        THEN
            SELECT to_jsonb(array_agg(jsonb_build_object('name_item',n, 'sql_select_item',s))) FROM  unnest(ARRAY(SELECT jsonb_array_elements_text(dict->'layers'->key->'orig_filename')),ARRAY(SELECT jsonb_array_elements(dict->'layers'->key->'sql_select'))) t(n,s) INTO multiple_files;

            RAISE NOTICE 'multiple_files_array : %', multiple_files;
            dict := jsonb_set( dict, array['layers',key,'multiple_files'], 'true'::jsonb );
            dict := jsonb_set( dict, array['layers',key,'multiple_files_array'], multiple_files );

            SELECT string_agg($$'*$$ || trim(txt::text, $$"$$) || $$*'$$, ' ') FROM jsonb_array_elements(dict->'layers'->key->'orig_filename') AS txt INTO orig_filename_string;
            dict := jsonb_set( dict, array['layers',key,'orig_filename_string_extract'], to_jsonb(orig_filename_string) );

            SELECT $$\( $$ || string_agg($$-iname '*$$ || trim(txt::text, $$"$$) || $$*.shp'$$, ' -o ') || $$ \)$$ FROM jsonb_array_elements(dict->'layers'->key->'orig_filename') AS txt INTO orig_filename_string;
            dict := jsonb_set( dict, array['layers',key,'orig_filename_string_find'], to_jsonb(orig_filename_string) );
        END IF;

        IF dict->'layers'->key?'sql_select'
        THEN
            sql_select :=  replace(dict->'layers'->key->>'sql_select',$$\"$$,E'\u130C9');
            dict := jsonb_set( dict, array['layers',key,'sql_select'], sql_select::jsonb );
        END IF;

        IF dict->'layers'->key?'sql_view'
        THEN
            sql_view := replace(dict->'layers'->key->>'sql_view',$$"$$,E'\u130C9');
            dict := jsonb_set( dict, array['layers',key,'sql_view'], to_jsonb(sql_view) );
        END IF;

        -- obtem codec a partir da extensão do arquivo
        IF jsonb_typeof(dict->'layers'->key->'orig_filename') <> 'array'
        THEN
            orig_filename_ext := regexp_matches(dict->'layers'->key->>'orig_filename','\.(\w+)$');
            
            IF orig_filename_ext IS NOT NULL
            THEN
                SELECT extension, descr_mime, descr_encode FROM ingest.codec_type WHERE (array[extension] = orig_filename_ext) INTO codec_extension, codec_descr_mime, codec_desc_default;
                dict := jsonb_set( dict, array['layers',key,'orig_filename_with_extension'], 'true'::jsonb );
                RAISE NOTICE 'orig_filename_ext : %', orig_filename_ext;
                RAISE NOTICE 'codec_desc_default from extension: %', codec_desc_default;
            END IF;
        END IF;

        IF dict->'layers'->key?'codec'
        THEN
            -- 1. Extensão, variação e sobrescrição. Descarta a variação.
            IF EXISTS (SELECT 1 FROM regexp_matches(dict->'layers'->key->>'codec','^(.*)~(.*);(.*)$'))
            THEN
                    SELECT extension, descr_mime, descr_encode FROM ingest.codec_type WHERE (extension = lower(split_part(dict->'layers'->key->>'codec', '~', 1)) AND variant IS NULL) INTO codec_extension, codec_descr_mime, codec_desc_default;

                codec_desc_sobre := jsonb_object(regexp_split_to_array (split_part(regexp_replace(dict->'layers'->key->>'codec', ';','~'),'~',3),'(;|=)'));

                RAISE NOTICE '1. codec_desc_default : %', codec_desc_default;
                RAISE NOTICE '1. codec_desc_sobre : %', codec_desc_sobre;
            END IF;

            -- 2. Extensão e sobrescrição, sem variação
            IF EXISTS (SELECT 1 FROM regexp_matches(dict->'layers'->key->>'codec','^([^;~]*);(.*)$'))
            THEN
                SELECT extension, descr_mime, descr_encode FROM ingest.codec_type WHERE (extension = lower(split_part(dict->'layers'->key->>'codec', ';', 1)) AND variant IS NULL) INTO codec_extension, codec_descr_mime, codec_desc_default;

                codec_desc_sobre := jsonb_object(regexp_split_to_array (split_part(regexp_replace(dict->'layers'->key->>'codec', ';','~'),'~',2),'(;|=)'));

                RAISE NOTICE '2. codec_desc_default : %', codec_desc_default;
                RAISE NOTICE '2. codec_desc_sobre : %', codec_desc_sobre;
            END IF;

            -- 3. Extensão e variação ou apenas extensão, sem sobrescrição
            IF EXISTS (SELECT 1 FROM regexp_matches(dict->'layers'->key->>'codec','^(.*)~([^;]*)$')) OR EXISTS (SELECT 1 FROM regexp_matches(dict->'layers'->key->>'codec','^([^~;]*)$'))
            THEN
                codec_value := regexp_split_to_array( dict->'layers'->key->>'codec' ,'(~)');

                SELECT extension, descr_mime, descr_encode FROM ingest.codec_type WHERE (array[upper(extension), variant] = codec_value AND cardinality(codec_value) = 2) OR (array[upper(extension)] = codec_value AND cardinality(codec_value) = 1 AND variant IS NULL) INTO codec_extension, codec_descr_mime, codec_desc_default;

                RAISE NOTICE '3. codec_desc_default : %', codec_desc_default;
            END IF;

            dict := jsonb_set( dict, array['layers',key,'isXlsx'], IIF(lower(codec_extension) = 'xlsx',bt,bf) );
        END IF;

        -- codec resultante
        -- global sobrescreve default e é sobrescrito por sobre
        IF codec_desc_default IS NOT NULL
        THEN
            codec_desc := codec_desc_default;

            IF codec_desc_global IS NOT NULL
            THEN
                codec_desc := codec_desc || codec_desc_global;
            END IF;

            IF codec_desc_sobre IS NOT NULL
            THEN
                codec_desc := codec_desc || codec_desc_sobre;
            END IF;
        ELSE
            IF codec_desc_global IS NOT NULL
            THEN
                codec_desc := codec_desc_global;
            END IF;

            IF codec_desc_sobre IS NOT NULL
            THEN
                codec_desc := codec_desc || codec_desc_sobre;
            END IF;
        END IF;

        IF codec_desc IS NOT NULL
        THEN
            dict := jsonb_set( dict, array['layers',key], (dict->'layers'->>key)::jsonb || codec_desc::jsonb );
            
            RAISE NOTICE 'codec resultante : %', codec_desc;
        END IF;

        IF codec_extension IS NOT NULL
        THEN
            dict := jsonb_set( dict, array['layers',key,'extension'], to_jsonb(codec_extension) );
            RAISE NOTICE 'codec_extension : %', codec_extension;
        ELSE
            CASE method
            WHEN 'csv2sql'  THEN dict := jsonb_set( dict, array['layers',key,'extension'], to_jsonb('csv'::text) );
            WHEN 'shp2sql'  THEN dict := jsonb_set( dict, array['layers',key,'extension'], to_jsonb('shp'::text) );
            ELSE
                --  do nothing
            END CASE;
            
            RAISE NOTICE 'codec_extension from method: %', dict->'layers'->key->'extension';
        END IF;
                
        IF codec_descr_mime IS NOT NULL
        THEN
            dict := jsonb_set( dict, array['layers',key], (dict->'layers'->>key)::jsonb || codec_descr_mime::jsonb );
        END IF;

        IF codec_descr_mime?'mime' AND codec_descr_mime->>'mime' = 'application/zip' OR codec_descr_mime->>'mime' = 'application/gzip'
        THEN
            dict := jsonb_set( dict, array['layers',key,'multiple_files'], 'true'::jsonb );
            dict := jsonb_set( dict, array['layers',key,'extension'], to_jsonb((regexp_matches(codec_extension,'(.*)\.\w+$'))[1]) );
        END IF;

        IF key='address' OR key='cadparcel' OR key='cadvia'
        THEN
            dict := jsonb_set( dict, array['layers',key,'isCadLayer'], 'true'::jsonb );
        END IF;

        IF dict->'layers'?key AND dict->'layers'?('cad'||key)
            AND dict->'layers'->key->>'subtype' = 'ext'
            AND dict->'layers'->('cad'||key)->>'subtype' = 'cmpl'
            AND dict->'layers'->key?'join_column' AND dict->'layers'->('cad'||key)?'join_column'
        THEN
            dict := jsonb_set( dict, '{joins}', '{}'::jsonb );
            dict := jsonb_set( dict, array['joins',key] , jsonb_build_object(
                'layer',           key || '_ext'
                ,'cadLayer',        'cad' || key || '_cmpl'
                ,'layerColumn',     dict->'layers'->key->'join_column'
                ,'cadLayerColumn',  dict->'layers'->('cad'||key)->'join_column'
                ,'layerFile',       jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.'|| key ||'.file)')::jsonpath  )->0->>'file'
                ,'cadLayerFile',    jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.cad'|| key ||'.file)')::jsonpath  )->0->>'file'
                -- check by dict @? ('$.files[*].p ? (@ == $.layers.'|| key ||'.file)')
            ));
        END IF;

        IF key='geoaddress' AND dict->'layers'?'address'
            AND dict->'layers'->key->>'subtype' = 'ext'
            AND dict->'layers'->'address'->>'subtype' = 'cmpl'
        AND dict->'layers'->key?'join_column'
            AND dict->'layers'->'address'?'join_column'
        THEN
            dict := jsonb_set( dict, '{joins}', '{}'::jsonb );
            dict := jsonb_set( dict, array['joins',key] , jsonb_build_object(
                'layer',           key || '_ext'
                ,'cadLayer',        'address_cmpl'
                ,'layerColumn',     dict->'layers'->key->'join_column'
                ,'cadLayerColumn',  dict->'layers'->'address'->'join_column'
                ,'layerFile',       jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.'|| key ||'.file)')::jsonpath  )->0->>'file'
                ,'cadLayerFile',    jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.address.file)')::jsonpath  )->0->>'file'
            ));
        END IF;
	 END LOOP;

	 IF jsonb_array_length(to_jsonb(jsonb_object_keys_asarray(dict->'joins'))) > 0
	 THEN
        dict := dict || jsonb_build_object( 'joins_keys', jsonb_object_keys_asarray(dict->'joins') );
	 END IF;

	 dict := dict || jsonb_build_object( 'layers_keys', jsonb_object_keys_asarray(dict->'layers') );
	 dict := jsonb_set( dict, array['pkversion'], to_jsonb(to_char((dict->>'pkversion')::int,'fm000')) );
	 dict := jsonb_set( dict, '{files,-1,last}','true'::jsonb);
 -- CASE ELSE ...?
 END CASE;
 RETURN dict;
END;
$f$ language PLpgSQL;
-- SELECT ingest.jsonb_mustache_prepare( yamlfile_to_jsonb('/var/gits/_dg/preserv-BR/data/RJ/Niteroi/_pk0016.01/make_conf.yaml') );
-- SELECT ingest.jsonb_mustache_prepare( yamlfile_to_jsonb('/var/gits/_dg/preserv-BR/data/MG/BeloHorizonte/_pk0008.01/make_conf.yaml') );
-- SELECT ingest.jsonb_mustache_prepare( yamlfile_to_jsonb('/var/gits/_dg/preserv-PE/data/CUS/Cusco/_pk001/make_conf.yaml');
-- SELECT ingest.jsonb_mustache_prepare( yamlfile_to_jsonb('/var/gits/_dg/preserv-BR/data/SP/SaoPaulo/_pk0033.01/make_conf.yaml') );
-- SELECT ingest.jsonb_mustache_prepare( yamlfile_to_jsonb('/var/gits/_dg/preserv-BR/data/PR/Araucaria/_pk0061.01/make_conf.yaml') );
-- SELECT ingest.jsonb_mustache_prepare( yamlfile_to_jsonb('/var/gits/_dg/preserv-BR/data/_pk0004.01/make_conf.yaml') );
-- SELECT ingest.jsonb_mustache_prepare( yamlfile_to_jsonb('/var/gits/_dg/preserv-PE/data/CUS/Cusco/_pk0001.01/make_conf.yaml') ); 

CREATE or replace FUNCTION ingest.insert_bytesize(
  dict jsonb  -- input
) RETURNS jsonb  AS $f$
DECLARE
 a text;
 sz bigint;
BEGIN
    FOR i in 0..(select jsonb_array_length(dict->'files')-1)
    LOOP
        a := format($$ {files,%s,file} $$, i )::text[];

        SELECT size::bigint FROM pg_stat_file(concat('/var/www/preserv.addressforall.org/download/',dict#>>a::text[])) INTO sz;

        a := format($$ {files,%s,size} $$, i );
        dict := jsonb_set( dict, a::text[],to_jsonb(sz));
    END LOOP;
 RETURN dict;
END;
$f$ language PLpgSQL;
--SELECT ingest.insert_bytesize( yamlfile_to_jsonb('/var/gits/_dg/preserv-BR/data/RS/SantaMaria/_pk0019.01/make_conf.yaml') );

CREATE or replace FUNCTION ingest.lix_generate_make_conf_with_size(
    jurisd text,
    pack_id text
) RETURNS text AS $f$
    DECLARE
        q_query text;
        conf_yaml jsonb;
        conf_yaml_t text;
        f_yaml jsonb;
        output_file text;
    BEGIN

    SELECT y, t FROM ingest.lix_conf_yaml WHERE jurisdiction = jurisd AND (y->>'pack_id') = pack_id INTO conf_yaml, conf_yaml_t;
    SELECT first_yaml FROM ingest.lix_jurisd_tpl WHERE jurisdiction = jurisd INTO f_yaml;

    SELECT f_yaml->>'pg_io' || '/make_conf_' || jurisd || pack_id INTO output_file;

    --SELECT jsonb_to_yaml(ingest.insert_bytesize(conf_yaml)::text) INTO q_query;
    SELECT regexp_replace( conf_yaml_t , '\n*files: *(\n *\-[^\n]*|\n[\t ]+[^\n]+)+\n*', E'\n\n' || jsonb_to_yaml((jsonb_build_object('files',ingest.insert_bytesize(conf_yaml)->'files'))::text) || E'\n', 'n') INTO q_query;
    
    SELECT volat_file_write(output_file,q_query) INTO q_query;

    RETURN q_query;
    END;
$f$ LANGUAGE PLpgSQL;
-- SELECT ingest.lix_generate_make_conf_with_size('BR','19.1');


CREATE or replace FUNCTION ingest.lix_generate_make_conf_with_license(
    jurisd text,
    pack_id text
) RETURNS text AS $f$
    DECLARE
        q_query text;
        conf_yaml jsonb;
        conf_yaml_t text;
        f_yaml jsonb;
        output_file text;
        license_evidences jsonb;
        definition jsonb;
    BEGIN

    SELECT y, t FROM ingest.lix_conf_yaml WHERE jurisdiction = jurisd AND (y->>'pack_id') = pack_id INTO conf_yaml, conf_yaml_t;
    SELECT first_yaml FROM ingest.lix_jurisd_tpl WHERE jurisdiction = jurisd INTO f_yaml;

    SELECT f_yaml->>'pg_io' || '/make_conf_' || jurisd || pack_id INTO output_file;

    SELECT to_jsonb(ARRAY[name, family, url]) FROM tmp_pack_licenses WHERE tmp_pack_licenses.pack_id = (to_char(substring(conf_yaml->>'pack_id','^([^\.]*)')::int,'fm000') || to_char(substring(conf_yaml->>'pack_id','([^\.]*)$')::int,'fm00')) INTO definition;

    --conf_yaml := jsonb_set( conf_yaml, array['files_license'], files_license);
    --SELECT jsonb_to_yaml(conf_yaml::text) INTO q_query;

    IF conf_yaml?'license_evidences'
    THEN
        license_evidences := conf_yaml->'license_evidences' || jsonb_build_object('definition',definition);
    ELSE
        license_evidences := jsonb_build_object('license_evidences',jsonb_build_object('definition',definition));

        --license_evidences := jsonb_set( '{}'::jsonb, array['license_evidences','definition'], definition );
    END IF;

    SELECT conf_yaml_t || jsonb_to_yaml(license_evidences::text)::text INTO q_query;

    --SELECT volat_file_write(output_file,q_query) INTO q_query;

    RETURN q_query;
    END;
$f$ LANGUAGE PLpgSQL;
-- SELECT ingest.lix_generate_make_conf_with_license('BR','16.1');

CREATE FUNCTION ingest.lix_generate_makefile(
    jurisd text,
    pack_id text
) RETURNS text AS $f$
    DECLARE
        q_query text;
        conf_yaml jsonb;
        f_yaml jsonb;
        mkme_srcTplLast text;
        mkme_srcTpl text;
        output_file text;
    BEGIN

    SELECT y FROM ingest.lix_conf_yaml WHERE jurisdiction = jurisd AND (y->>'pack_id') = pack_id INTO conf_yaml;
    SELECT y FROM ingest.lix_mkme_srcTpl WHERE tplInputSchema_id = conf_yaml->>'schemaId_template' INTO mkme_srcTpl;
    SELECT first_yaml FROM ingest.lix_jurisd_tpl WHERE jurisdiction = jurisd INTO f_yaml;
    SELECT tpl_last FROM ingest.lix_jurisd_tpl WHERE jurisdiction = 'INT' INTO mkme_srcTplLast;

    SELECT f_yaml->>'pg_io' || '/makeme_' || jurisd || pack_id INTO output_file;

    conf_yaml := jsonb_set( conf_yaml, array['jurisdiction'], to_jsonb(jurisd) );

    SELECT replace(jsonb_mustache_render(mkme_srcTpl || mkme_srcTplLast, ingest.jsonb_mustache_prepare(f_yaml || conf_yaml)),E'\u130C9',$$\"$$) INTO q_query; -- "

    SELECT volat_file_write(output_file,q_query) INTO q_query;

    RETURN q_query;
    END;
$f$ LANGUAGE PLpgSQL;
-- SELECT ingest.lix_generate_makefile('BR','16.1');
-- SELECT ingest.lix_generate_makefile('PE','1');

CREATE FUNCTION ingest.lix_generate_readme(
    jurisd text,
    pack_id text
) RETURNS text AS $f$
    DECLARE
        q_query text;
        conf_yaml jsonb;
        f_yaml jsonb;
        readme text;
        output_file text;
    BEGIN
    SELECT y FROM ingest.lix_conf_yaml WHERE jurisdiction = jurisd AND (y->>'pack_id') = pack_id INTO conf_yaml;
    SELECT first_yaml FROM ingest.lix_jurisd_tpl WHERE jurisdiction = jurisd INTO f_yaml;
    SELECT readme_mk FROM ingest.lix_jurisd_tpl WHERE jurisdiction = jurisd INTO readme;

    SELECT f_yaml->>'pg_io' || '/README-draft_' || jurisd || pack_id INTO output_file;

    SELECT jsonb_mustache_render(readme, conf_yaml) INTO q_query;

    SELECT volat_file_write(output_file,q_query) INTO q_query;

    RETURN q_query;
    END;
$f$ LANGUAGE PLpgSQL;
-- SELECT ingest.lix_generate_readme('/var/gits/_dg/','BR','16.1');

-- ----------------------------

CREATE TABLE download.redirects (
    donor_id          text,
    filename_original text,
    package_path      text,
    fhash             text NOT NULL PRIMARY KEY, -- de_sha256
    furi              text NOT NULL,             -- para_url
    UNIQUE (fhash, furi)
);

CREATE or replace VIEW api.redirects AS SELECT * FROM download.redirects;



CREATE or replace FUNCTION ingest.join(
    p_ftname_layer text,
    p_join_col_layer text,
    p_fileref_layer_sha256 text,
    p_ftname_cad text,
    p_join_col_cad text,
    p_fileref_cad_sha256 text
) RETURNS text AS $f$
  DECLARE
    q_query text;
    msg_ret text;
    num_items bigint;
  BEGIN
  q_query := format(
      $$
      WITH
      cadis AS
      (
        SELECT *
        FROM ingest.cadastral_asis
        WHERE file_id IN
            (
            SELECT id
            FROM ingest.donated_PackComponent
            WHERE ftid IN
                (
                SELECT ftid::int
                FROM ingest.fdw_feature_type
                WHERE ftname=lower('%s')
                )
                AND packvers_id = (SELECT id FROM ingest.fdw_donated_PackFileVers WHERE hashedfname = '%s')
            )
      ),
      duplicate_keys AS (
        SELECT asis.properties->'%s'
        FROM
        (
            SELECT  *
            FROM ingest.feature_asis
            WHERE file_id IN
            (
                SELECT id
                FROM ingest.donated_PackComponent
                WHERE ftid IN
                    (
                    SELECT ftid::int
                    FROM ingest.fdw_feature_type
                    WHERE ftname=lower('%s')
                    )
                    AND packvers_id = (SELECT id FROM ingest.fdw_donated_PackFileVers WHERE hashedfname = '%s')
            )
        ) AS asis

        INNER JOIN

        cadis

        ON asis.properties->'%s' = cadis.properties->'%s'

        GROUP BY asis.properties->'%s'

        HAVING COUNT(*)>1
      ),
      layer_features AS (
      UPDATE ingest.feature_asis l
      SET properties =  l.properties || c.properties-'%s'
      FROM cadis AS c
      WHERE l.properties->'%s' = c.properties->'%s'
            AND l.file_id IN
            (
            SELECT id
            FROM ingest.donated_PackComponent
            WHERE ftid IN
                (
                SELECT ftid::int
                FROM ingest.fdw_feature_type
                WHERE ftname=lower('%s')
                )
                AND packvers_id = (SELECT id FROM ingest.fdw_donated_PackFileVers WHERE hashedfname = '%s')
            )
            AND l.properties->'%s' NOT IN (  SELECT * FROM duplicate_keys  )
            RETURNING 1
            )
      SELECT COUNT(*) FROM layer_features
    $$,
    p_ftname_cad,
    p_fileref_cad_sha256,
    p_join_col_layer,
    p_ftname_layer,
    p_fileref_layer_sha256,
    p_join_col_layer,
    p_join_col_cad,
    p_join_col_layer,
    p_join_col_cad,
    p_join_col_layer,
    p_join_col_cad,
    p_ftname_layer,
    p_fileref_layer_sha256,
    p_join_col_layer
  );

  EXECUTE q_query INTO num_items;

  msg_ret := format(
    E'Join %s items.',
    num_items
  );

  RETURN msg_ret;
  END;
$f$ LANGUAGE PLpgSQL;
COMMENT ON FUNCTION ingest.join(text,text,text,text,text,text)
  IS 'Join layer and cadlayer.'
;

CREATE or replace FUNCTION ingest.load_hcode_parameters(
  p_file text,  -- path+filename+ext
  p_delimiter text DEFAULT ',',
  p_fdwname text DEFAULT 'tmp_hcode_parameters' -- nome da tabela fwd
) RETURNS text  AS $f$
DECLARE
    q_query text;
BEGIN
    SELECT ingest.fdw_generate_direct_csv(p_file,p_fdwname,p_delimiter) INTO q_query;

    DELETE FROM ingest.hcode_parameters;

    EXECUTE format($$INSERT INTO ingest.hcode_parameters (id_profile_params,distribution_parameters,signature_parameters,comments) SELECT id_profile_params::int, (SELECT json_build_object(t[1],t[2]::int,t[3],t[4]::int,t[5],t[6]::int) FROM regexp_split_to_array(replace(hcode_distribution_parameters,' ',''),'(:|;)') AS t), (SELECT json_build_object(t[1],t[2]::real,t[3],t[4]::int) FROM regexp_split_to_array(replace(hcode_signature_parameters,' ',''),'(:|;)') AS t), comments FROM %s$$, p_fdwname);

    EXECUTE format('DROP FOREIGN TABLE IF EXISTS %s;',p_fdwname);

    RETURN ' '|| E'Load hcode_parameters from: '||p_file|| ' ';
END;
$f$ language PLpgSQL;
COMMENT ON FUNCTION ingest.load_hcode_parameters
  IS 'Load hcode_parameters.csv.'
;
--SELECT ingest.load_hcode_parameters('/var/gits/_dg/preserv/data/hcode_parameters.csv')

CREATE TABLE ingest.codec_type (
  extension text,
  variant text,
  descr_mime jsonb,
  descr_encode jsonb,
  UNIQUE(extension,variant)
);

CREATE FUNCTION ingest.load_codec_type(
  p_file text,  -- path+filename+ext
  p_delimiter text DEFAULT ',',
  p_fdwname text DEFAULT 'tmp_codec_type' -- nome da tabela fwd
) RETURNS text  AS $f$
DECLARE
        q_query text;
BEGIN
    SELECT ingest.fdw_generate_direct_csv(p_file,p_fdwname,p_delimiter) INTO q_query;

    DELETE FROM ingest.codec_type;

    EXECUTE format($$INSERT INTO ingest.codec_type (extension,variant,descr_mime,descr_encode) SELECT lower(extension), variant, jsonb_object(regexp_split_to_array ('mime=' || descr_mime,'(;|=)')), jsonb_object(regexp_split_to_array ( descr_encode,'(;|=)')) FROM %s$$, p_fdwname);

    EXECUTE format('DROP FOREIGN TABLE IF EXISTS %s;',p_fdwname);

    UPDATE ingest.codec_type
    SET descr_encode = jsonb_set(descr_encode, '{delimiter}', to_jsonb(str_urldecode(descr_encode->>'delimiter')), true)
    WHERE descr_encode->'delimiter' IS NOT NULL;

    RETURN ' '|| E'Load codec_type from: '||p_file|| ' ';
END;
$f$ language PLpgSQL;
COMMENT ON FUNCTION ingest.load_codec_type
  IS 'Load codec_type.csv.'
;
