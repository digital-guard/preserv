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
 cols := pg_csv_head(p_file, replace(p_delimiter,'|','\|'));
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

CREATE or replace FUNCTION ingest.copy_tabular_data(
  p_file text,  -- path+filename+ext
  p_fdwname text, -- nome da tabela fwd
  p_enconding text DEFAULT 'UTF8', -- https://www.postgresql.org/docs/current/multibyte.html
  p_delimiter text DEFAULT ',',
  p_addtxtype boolean DEFAULT true
) RETURNS text  AS $f$
DECLARE
 fpath text;
 cols text[];
 sepcols text;
BEGIN
 sepcols := iIF(p_addtxtype, '" text,"'::text, '","'::text);
 cols := pg_csv_head(p_file, replace(p_delimiter,'|','\|'));
 EXECUTE
    format(
      'DROP TABLE IF EXISTS %s; CREATE TABLE %s (%s%s%s);
      COPY %s(%s) FROM %L DELIMITER %L CSV HEADER ENCODING %L;',
       p_fdwname, p_fdwname, '"', array_to_string(cols,sepcols), iIF(p_addtxtype, '" text'::text, '"'),
       p_fdwname, '"'||array_to_string(cols,'","')||'"', p_file, p_delimiter, p_enconding
     );
 RETURN p_fdwname;
END;
$f$ language PLpgSQL;
COMMENT ON FUNCTION ingest.copy_tabular_data
  IS 'Generates a TABLE for tabular data ingestion.'
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

--CREATE TABLE ingest.via_line(
  --pck_id real NOT NULL, -- REFERENCES optim.donatedPack(pck_id),
  --vianame text,
  --is_informal boolean default false, -- non-official name (loteamentos com ruas ainda sem nome)
  --geom geometry,
  --info JSONb,
  --UNIQUE(pck_id,geom)
--);
--COMMENT ON TABLE ingest.via_line
  --IS 'Ingested via lines (street axis) of one or more packages, temporary data (not need package-version).'
--;

---------

CREATE OR REPLACE FUNCTION ingest.buffer_geom(geom geometry, buffer_type integer )
RETURNS geometry AS $f$
    SELECT
        CASE
        WHEN buffer_type=0 THEN geom                  -- no buffer
        WHEN buffer_type=1 THEN ST_Buffer(geom,0.001) -- ~100m
        WHEN buffer_type=2 THEN ST_Buffer(geom,0.05)  -- ~5000m
        WHEN buffer_type=3 THEN ST_Buffer(geom,0.5)   -- ~50km
        WHEN buffer_type=4 THEN ST_Buffer(geom,5)     -- ~500km
        ELSE geom                                     -- no buffer
        END
$f$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION ingest.buffer_geom(geometry,integer)
  IS 'Add standardized buffer to geometries.'
;

CREATE FOREIGN TABLE ingest.fdw_feature_type (
 ftid smallint,
 ftname text,
 geomtype text,
 need_join boolean,
 description text,
 info jsonb
) SERVER foreign_server_dl03
  OPTIONS (schema_name 'optim', table_name 'vw01info_feature_type');

CREATE FOREIGN TABLE ingest.fdw_codec_type (
  extension text,
  variant text,
  descr_mime jsonb,
  descr_encode jsonb
) SERVER foreign_server_dl03
  OPTIONS (schema_name 'optim', table_name 'codec_type');

CREATE FOREIGN TABLE ingest.vw01full_packfilevers (
  id                       bigint,
  hashedfname              text,
  pack_id                  bigint,
  pack_item                integer,
  pack_item_accepted_date  date,
  kx_pack_item_version     integer,
  user_resp                text,
  info                     jsonb,
  local_serial_formated    text,
  pack_number              text,
  path_cutgeo_server       text,
  path_preserv_server      text,
  path_preserv_git         text,
  path_cutgeo_git          text,
  hashedfname_7            text,
  hashedfname_without_ext  text,
  donor_id                 integer,
  pk_count                 integer,
  original_tpl             text,
  make_conf_tpl            jsonb,
  kx_num_files             integer,
  packtpl_info             jsonb,
  country_id               integer,
  local_serial             integer,
  scope_osm_id             bigint,
  scope_label              text,
  shortname                text,
  vat_id                   text,
  legalname                text,
  wikidata_id              bigint,
  url                      text,
  donor_info               jsonb,
  kx_vat_id                text,
  osm_id                   bigint,
  jurisd_base_id           integer,
  jurisd_local_id          integer,
  parent_id                bigint,
  admin_level              smallint,
  name                     text,
  parent_abbrev            text,
  abbrev                   text,
  jurisdiction_wikidata_id bigint,
  lexlabel                 text,
  isolabel_ext             text,
  ddd                      integer,
  housenumber_system_type  text,
  lex_urn                  text,
  jurisdiction_info        jsonb,
  isolevel                 integer
) SERVER foreign_server_dl03
  OPTIONS (schema_name 'optim', table_name 'vw01full_packfilevers');

CREATE FOREIGN TABLE ingest.vw01full_jurisdiction_geom (
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
 isolevel        text,
 geom            geometry(Geometry,4326)
) SERVER foreign_server_dl03
  OPTIONS (schema_name 'optim', table_name 'vw01full_jurisdiction_geom')
;
COMMENT ON FOREIGN TABLE ingest.vw01full_jurisdiction_geom
  IS 'Add geom to ingest.fdw_jurisdiction.'
;

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

CREATE OR REPLACE FUNCTION f(geom geometry, file_id bigint, ghs_size integer)
RETURNS text AS $f$
    SELECT ST_Geohash(
      CASE GeometryType(geom)
        WHEN 'POINT' THEN geom
        WHEN 'LINESTRING' THEN ST_LineInterpolatePoint(geom,0.5)
        WHEN 'MULTILINESTRING' THEN ST_LineInterpolatePoint(ST_GeometryN(geom,1),0.5)
        ELSE ST_PointOnSurface(geom)
      END
      ,ghs_size)
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
  geom geometry        CHECK ( st_srid(geom)=4326 ),
  kx_ghs9 text,
  UNIQUE(file_id,feature_id)
);
CREATE INDEX ingest_feature_asis_discarded_ghs9_idx ON ingest.feature_asis_discarded (file_id,kx_ghs9);
ALTER TABLE ingest.feature_asis_discarded ADD COLUMN kx_ghs9 text constraint;
CREATE TABLE ingest.cadastral_asis (
  file_id bigint NOT NULL REFERENCES ingest.donated_PackComponent(id) ON DELETE CASCADE,
  cad_id int NOT NULL,
  properties jsonb NOT NULL,
  UNIQUE(file_id,cad_id)
);

-- -- -- --
--  VIEWS:

--DROP VIEW IF EXISTS ingest.vw02simple_feature_asis CASCADE;
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

--DROP VIEW IF EXISTS ingest.vw03full_layer_file CASCADE;
CREATE VIEW ingest.vw03full_layer_file AS
  SELECT pf.isolabel_ext, pf.scope_label, pf.pack_id, pc.*, ft.ftname, ft.geomtype, pf.housenumber_system_type, ft.need_join, ft.description, ft.info AS ft_info
  FROM ingest.donated_PackComponent pc
  INNER JOIN ingest.fdw_feature_type ft
    ON pc.ftid=ft.ftid
  LEFT JOIN ingest.vw01full_packfilevers pf
    ON pc.packvers_id=pf.id
  ORDER BY pf.isolabel_ext
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

--DROP VIEW IF EXISTS ingest.vw04simple_layer_file CASCADE;
CREATE VIEW ingest.vw04simple_layer_file AS
  --SELECT id, geomtype, proc_step, ftid, ftname, file_type,
  SELECT id, geomtype, proc_step, ftid, ftname,
         round((lineage->'file_meta'->'size')::int/2014^2) file_mb,
         substr(lineage_md5,1,7) as md5_prefix
  FROM ingest.vw03full_layer_file
;

--DROP VIEW IF EXISTS ingest.vw05test_feature_asis CASCADE;
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

CREATE VIEW ingest.vwreport_geometries_discarded AS
SELECT isolabel_ext, packvers_id, id, ftid, ftname, geomtype, fad.*
FROM
(
    SELECT file_id,
        (COUNT(*) filter (WHERE get_bit((properties->>'error')::varbit,11) = 1))::bigint AS nointersects, -- intersects
        (COUNT(*) filter (WHERE get_bit((properties->>'error')::varbit,10) = 1))::bigint AS invalid, -- invalid
        (COUNT(*) filter (WHERE get_bit((properties->>'error')::varbit, 9) = 1))::bigint AS nosimple, -- simple
        (COUNT(*) filter (WHERE get_bit((properties->>'error')::varbit, 8) = 1))::bigint AS empty, -- empty
        (COUNT(*) filter (WHERE get_bit((properties->>'error')::varbit, 7) = 1))::bigint AS small, -- small
        (COUNT(*) filter (WHERE get_bit((properties->>'error')::varbit, 6) = 1))::bigint AS null, -- null
        (COUNT(*) filter (WHERE get_bit((properties->>'error')::varbit, 5) = 1))::bigint AS invalid_type, -- invalid_type
        (COUNT(*) filter (WHERE get_bit((properties->>'error')::varbit, 4) = 1))::bigint AS duplicate, -- duplicados
        (COUNT(*) filter (WHERE get_bit((properties->>'error')::varbit, 3) = 1))::bigint AS noclosed, -- is_closed
        (COUNT(*) filter (WHERE get_bit((properties->>'error')::varbit, 2) = 1))::bigint AS large, -- large
        (COUNT(*) filter (WHERE get_bit((properties->>'error')::varbit, 1) = 1))::bigint AS reserved1, -- reserved
        (COUNT(*) filter (WHERE get_bit((properties->>'error')::varbit, 0) = 1))::bigint AS reserved2 -- reserved
    FROM ingest.feature_asis_discarded
    GROUP BY file_id
) fad
LEFT JOIN ingest.vw03full_layer_file vw
ON vw.id = fad.file_id
;
COMMENT ON VIEW ingest.vwreport_geometries_discarded
  IS 'Reason report for geometries discarded from ingested layers.'
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
  FROM ingest.fdw_feature_type
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

CREATE or replace FUNCTION ingest.feature_asis_assign_volume(
    p_file_id bigint,  -- ID at ingest.donated_PackComponent
    p_usemedian boolean DEFAULT false
) RETURNS jsonb AS $f$
DECLARE
    j jsonb;
BEGIN
    WITH get_layer_type AS (SELECT (ingest.donated_PackComponent_geomtype(p_file_id))[1] AS gtype)
    SELECT to_jsonb(t3) INTO j
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
                SELECT count(*) n,
                CASE 
                    WHEN (SELECT COUNT(*) FROM ingest.feature_asis WHERE file_id=p_file_id ) > 1000000  THEN (SELECT geom FROM ingest.vw01full_jurisdiction_geom WHERE isolabel_ext=(SELECT isolabel_ext FROM ingest.vw03full_layer_file WHERE id=p_file_id))
                    ELSE ST_Collect(ST_Force2D(geom))
                END geom,
                CASE gtype --(gtype||iif(p_usemedian,'','_no'::text))
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
    ;

    RETURN j;
END
$f$ language PLpgSQL;

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
        hcode.signature_reduce(ingest.feature_asis_geohashes(p_file_id,ghs_size), 2, 1, (SELECT lineage->'hcode_signature_parameters' FROM ingest.donated_PackComponent WHERE id=p_file_id))
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
   hcode.distribution_format(lineage->'feature_asis_summary'->'ghs_feature_distrib', true, p_glink|| layerinfo[3] ||'_'),
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
  p_ftype text DEFAULT NULL,
  p_add_md5 boolean DEFAULT true
  -- proc_step = 1
  -- ,p_size_min int DEFAULT 5
) RETURNS bigint AS $f$
-- with ... check
 WITH filedata AS (
   SELECT p_pck_id, p_ftid,
          CASE
            WHEN ((fmeta->'size')::int<5 OR (fmeta->>'hash_md5')='') THEN NULL --guard
            ELSE fmeta->>'hash_md5'
          END AS hash_md5,
          (fmeta - 'hash_md5') AS fmeta
   FROM (
       SELECT jsonb_pg_stat_file(p_file,p_add_md5) as fmeta
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
COMMENT ON FUNCTION ingest.getmeta_to_file(text,int,bigint,text,int,text,boolean)
  IS 'Reads file metadata and inserts it into ingest.donated_PackComponent. If proc_step=1 returns valid ID else NULL.'
;

CREATE or replace FUNCTION ingest.getmeta_to_file(
  p_file text,
  p_ftid int,
  p_pck_id bigint,
  p_add_md5 boolean DEFAULT true
) RETURNS bigint AS $f$
 WITH filedata AS (
   SELECT p_pck_id, p_ftid,
          CASE
            WHEN ((fmeta->'size')::int<5 OR (fmeta->>'hash_md5')='') THEN NULL --guard
            ELSE fmeta->>'hash_md5'
          END AS hash_md5,
          (fmeta - 'hash_md5') AS fmeta
   FROM (
       SELECT jsonb_pg_stat_file(p_file,p_add_md5) as fmeta
   ) t
 ),
  file_exists AS (
    SELECT id
    FROM ingest.donated_PackComponent
    WHERE packvers_id=p_pck_id AND lineage_md5=(SELECT hash_md5 FROM filedata) AND ftid=p_ftid
  )
  SELECT id FROM file_exists
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.getmeta_to_file(text,int,bigint,boolean)
  IS 'Reads file metadata and return id if exists in ingest.donated_PackComponent.'
;

CREATE or replace FUNCTION ingest.getmeta_to_file(
  p_file text,   -- 1.
  p_ftname text, -- 2. define o layer... um file pode ter mais de um layer??
  p_pck_id bigint,
  p_add_md5 boolean DEFAULT true
) RETURNS bigint AS $wrap$
    SELECT ingest.getmeta_to_file(
      $1,
      (SELECT ftid::int FROM ingest.fdw_feature_type WHERE ftname=lower($2)),
      $3,
      $4
    );
$wrap$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.getmeta_to_file(text,text,bigint,boolean)
  IS 'Wrap para ingest.getmeta_to_file(text,int,bigint) usando ftName ao invés de ftID.'
;

CREATE or replace FUNCTION ingest.getmeta_to_file(
  p_file text,   -- 1.
  p_ftname text, -- 2. define o layer... um file pode ter mais de um layer??
  p_pck_id bigint,
  p_pck_fileref_sha256 text,
  p_id_profile_params int,
  p_ftype text DEFAULT NULL, -- 6
  p_add_md5 boolean DEFAULT true
) RETURNS bigint AS $wrap$
    SELECT ingest.getmeta_to_file(
      $1,
      (SELECT ftid::int FROM ingest.fdw_feature_type WHERE ftname=lower($2)),
      $3, $4, $5, $6, $7
    );
$wrap$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.getmeta_to_file(text,text,bigint,text,int,text,boolean)
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

CREATE or replace FUNCTION ingest.any_load_returnmsg(
    p_file_id bigint  -- ID at ingest.donated_PackComponent
) RETURNS text AS $f$
    SELECT
        CASE
        WHEN ftid >= 20
        THEN
            format(E'Statistics from file_id=%s (%s of %s of %s) in ingest.feature_asis.\n
            %s\n',
            id,
            ftname,
            packvers_id,
            isolabel_ext,
            format(
            E'Originals: %1$s items.\n
            Not Intersecs: %2$s items.\n
            Invalid: %3$s items.\n
            Not simple: %4$s items.\n
            Empty: %5$s items.\n
            Small: %6$s items.\n
            Null: %7$s items.\n
            Invalid geometry type: %8$s items.\n
            Not closed: %9$s items.\n
            Large: %10$s items.\n
            Deduplication: %15$s items.\n
            Resulting in feature_asis: %16$s.\n
            Resulting in feature_asis_discarded: %17$s.',
            VARIADIC (ARRAY(SELECT jsonb_array_elements_text(lineage->'statistics'))::bigint[])
            ))
        ELSE
            format(E'Statistics from file_id=%s (%s of %s of %s) in ingest.cadastral_asis.\n
            %s\n',
            id,
            ftname,
            packvers_id,
            isolabel_ext,
            format(
            E'Originals: %1$s items.\n
            Resulting in cadastral_asis: %16$s.',
            VARIADIC (ARRAY(SELECT jsonb_array_elements_text(lineage->'statistics'))::bigint[])))
        END
    FROM ingest.vw03full_layer_file
    WHERE id = p_file_id
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.any_load_returnmsg(bigint)
  IS 'Generates the final message after ingesting the layer.'
;

CREATE or replace FUNCTION ingest.any_load(
    p_method text,   -- shp/csv/etc.
    p_fileref text,  -- apenas referencia para ingest.donated_PackComponent
    p_ftname text,   -- featureType of layer... um file pode ter mais de um layer??
    p_tabname text,  -- tabela temporária de ingestão
    p_pck_id bigint,   -- id do package da Preservação.
    p_pck_fileref_sha256 text,
    p_tabcols text[] DEFAULT NULL, -- array[]=tudo, senão lista de atributos de p_tabname, ou só geometria
    p_id_profile_params int DEFAULT 1,
    buffer_type int DEFAULT 1,
    p_check_file_id_exist boolean DEFAULT true,
    p_geom_name text DEFAULT 'geom',
    p_to4326 boolean DEFAULT true,  -- on true converts SRID to 4326 .
    p_partition_name  text DEFAULT NULL,
    p_partition_value text DEFAULT NULL
) RETURNS text AS $f$
  DECLARE
    q_file_id integer;
    q_query text;
    q_query_cad text;
    feature_id_col text;
    use_tabcols boolean;
    num_items bigint;
    stats bigint[];
    stats_dup bigint[];
  BEGIN
  q_file_id := ingest.getmeta_to_file(p_fileref,p_ftname,p_pck_id,p_pck_fileref_sha256,p_id_profile_params); -- not null when proc_step=1. Ideal retornar array.
  
  IF q_file_id IS NULL AND p_check_file_id_exist THEN
    RETURN format(E'ERROR: file-read problem or data ingested before.\nSee %s\nor use make delete_file id=%s to delete data.\nSee ingest.vw03full_layer_file.',p_fileref,ingest.getmeta_to_file(p_fileref,p_ftname,p_pck_id));
  END IF;
  IF q_file_id IS NULL AND NOT(p_check_file_id_exist) THEN
    q_file_id := ingest.getmeta_to_file(p_fileref,p_ftname,p_pck_id);
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
  IF p_geom_name=ANY(p_tabcols) THEN
    p_tabcols := array_remove(p_tabcols,p_geom_name);
  END IF;

  q_query := format(
      $$
      WITH
      scan AS (
        SELECT %s AS file_id,
                CASE
                 WHEN %s THEN gid
                 ELSE gid+COALESCE((SELECT MAX(feature_id) FROM ingest.feature_asis WHERE file_id=%s),0)
               END AS gid,
        properties,
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
      a0 AS (
        SELECT *
        FROM scan
        WHERE ST_IsValid(geom)
      ),
      a AS (
        SELECT *
        FROM a0
        WHERE ST_IsClosed(geom) = TRUE OR GeometryType(geom) IN ('LINESTRING','MULTILINESTRING')
      ),
      mask AS (SELECT ingest.buffer_geom(geom,%s) AS geom FROM ingest.vw01full_jurisdiction_geom WHERE isolabel_ext=(SELECT isolabel_ext FROM ingest.vw01full_packfilevers WHERE id=%s)),
      b AS (
        SELECT file_id, gid, properties, geom, ( B'000000000' ||  (NOT(ST_IsSimple(geom)))::int::bit || (NOT(ST_IsValid(geom)))::int::bit || (NOT(ST_Intersects(geom,(SELECT geom FROM mask))))::int::bit ) AS error
        FROM a
      ),
      c AS (
        (
        SELECT file_id, gid, properties, geom, (error | (
            B'00' ||
            (CASE (SELECT (ingest.donated_PackComponent_geomtype(%s))[1]) WHEN 'poly' THEN ST_Area(geom,true) > 2147483647 WHEN 'line' THEN ST_Length(geom,true) > 2147483647 ELSE FALSE END)::int::bit ||
            B'00' ||
            (GeometryType(geom) NOT IN %s)::int::bit ||
            (geom IS NULL)::int::bit ||
            (CASE (SELECT (ingest.donated_PackComponent_geomtype(%s))[1]) WHEN 'poly' THEN ST_Area(geom,true) < 5 WHEN 'line' THEN ST_Length(geom,true) < 2 ELSE FALSE END)::int::bit ||
            (ST_IsEmpty(geom))::int::bit ||
            B'000' )) AS error
        FROM (
           SELECT file_id, gid,
                  properties,
                  CASE (SELECT (ingest.donated_PackComponent_geomtype(%s))[1])
                    WHEN 'point' THEN ST_ReducePrecision( geom, 0.000001 )
                    ELSE ST_SimplifyPreserveTopology( -- remove collinear points 
			    ST_ReducePrecision( -- round decimal degrees of SRID 4326, ~1 meter
			      geom
			      ,0.000001
		            ),
			    0.00000001
		    )
	          END AS geom,
	          error
           FROM b
           WHERE bit_count(error) = 0
           ) t
        )
        UNION
        (
            SELECT * FROM b WHERE bit_count(error) <> 0
        )
        UNION
        (
            SELECT file_id, gid, properties, geom, B'000100000000' AS error
            FROM a0
            WHERE ST_IsClosed(geom) = FALSE AND GeometryType(geom) NOT IN ('LINESTRING','MULTILINESTRING')
        )
        UNION
        (
            SELECT file_id, gid, properties, geom, B'000000000010' AS error
            FROM scan
            WHERE ST_IsValid(geom) = FALSE
        )
      ),
      stats AS (
      SELECT ARRAY [
            (SELECT COUNT(*) FROM scan)::bigint,
            (COUNT(*) filter (WHERE get_bit(error,11) = 1))::bigint, -- intersects
            (COUNT(*) filter (WHERE get_bit(error,10) = 1))::bigint, -- invalid
            (COUNT(*) filter (WHERE get_bit(error, 9) = 1))::bigint, -- simple
            (COUNT(*) filter (WHERE get_bit(error, 8) = 1))::bigint, -- empty
            (COUNT(*) filter (WHERE get_bit(error, 7) = 1))::bigint, -- small
            (COUNT(*) filter (WHERE get_bit(error, 6) = 1))::bigint, -- null
            (COUNT(*) filter (WHERE get_bit(error, 5) = 1))::bigint, -- invalid_type
                                                                          -- bit 4 é reservado para duplicados
            (COUNT(*) filter (WHERE get_bit(error, 3) = 1))::bigint, -- is_closed
            (COUNT(*) filter (WHERE get_bit(error, 2) = 1))::bigint  -- large
                                                                          -- bit 1 uso futuro
                                                                          -- bit 0 uso futuro
            ]
        FROM c
      ),
      ins_asis AS (
        INSERT INTO ingest.feature_asis
        SELECT file_id, gid, properties, geom
        FROM c
	    WHERE  bit_count(error) = 0
        RETURNING 1
      ),
      ins_asis_discarded AS (
        INSERT INTO ingest.feature_asis_discarded (file_id, feature_id, properties, geom)
        SELECT file_id, gid, properties || jsonb_build_object('error',error), geom
        FROM c
	    WHERE  bit_count(error) <> 0
        ON CONFLICT (file_id, feature_id)
        DO UPDATE
        SET properties = EXCLUDED.properties, geom = EXCLUDED.geom
        RETURNING 1
      )
      SELECT array_append(array_append( (SELECT * FROM stats), (SELECT COUNT(*) FROM ins_asis) ), (SELECT COUNT(*) FROM ins_asis_discarded))
    $$,
    q_file_id,
    CASE
        WHEN p_partition_name IS NOT NULL  THEN 'true'
        WHEN p_check_file_id_exist IS FALSE THEN 'false'
        ELSE 'true'
    END,
    q_file_id,
    iif(p_to4326,'true'::text,'false'),  -- decide ST_Transform
    iif(p_to4326,'true'::text,'false'),  -- decide ST_Transform
    feature_id_col,
    iIF( use_tabcols, 'to_jsonb(subq)'::text, E'\'{}\'::jsonb' ), -- properties
    CASE
        WHEN lower(p_geom_name)= 'geom' AND p_method= 'geojson2sql' THEN 'ST_GeomFromGeoJSON(geom) AS geom'
        WHEN lower(p_geom_name)= 'geom' AND p_method<>'geojson2sql' THEN 'geom'
        WHEN lower(p_geom_name)<>'geom' AND p_method= 'geojson2sql' THEN 'ST_GeomFromGeoJSON(' || p_geom_name ||') AS geom'
        WHEN lower(p_geom_name)<>'geom' AND p_method<>'geojson2sql' THEN p_geom_name ||' AS geom'   
    END,
    CASE WHEN p_partition_name IS NOT NULL THEN ' (SELECT * FROM ' || p_tabname || ' WHERE '|| p_partition_name || ' = $$' || p_partition_value || '$$::text) zx ' ELSE p_tabname END,
    iIF( use_tabcols, ', LATERAL (SELECT '|| array_to_string(p_tabcols,',') ||') subq',  ''::text ),
    buffer_type,
    p_pck_id,
    q_file_id,
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
    stats := ARRAY[num_items,0,0,0,0,0,0,0,0,0,num_items,0,0,0,0,num_items,0];

    UPDATE ingest.donated_PackComponent
    SET --proc_step=2,   -- if insert process occurs after q_query.
        lineage = lineage || jsonb_build_object('statistics',stats)
    WHERE id=q_file_id;
  ELSE
    EXECUTE q_query INTO stats;
    num_items := stats[11];

    IF num_items>0 THEN
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
          SELECT *, B'000010000000' AS error
          FROM ingest.feature_asis
          WHERE (file_id, kx_ghs9) IN ( SELECT file_id, kx_ghs9 FROM dup)
          ),
          dup_agg0 AS (
          SELECT min(file_id) AS file_id, min(feature_id) AS feature_id, min(kx_ghs9) AS kx_ghs9
          FROM dup_mask t
          GROUP BY file_id, kx_ghs9
          ORDER BY file_id, kx_ghs9
          ),
          dup_agg AS (
              SELECT f.file_id, f.feature_id, f.properties || jsonb_build_object('properties_agg',t.properties,'is_agg','true'::jsonb) || ingest.feature_asis_similarity(%s,f.geom,geoms), f.geom
              FROM (
                  SELECT min(file_id) AS file_id, jsonb_agg(properties || jsonb_build_object('feature_id',feature_id)) AS properties, kx_ghs9, array_agg(geom) AS geoms
                  FROM ( SELECT * FROM dup_mask  WHERE (file_id, feature_id, kx_ghs9) NOT IN ( SELECT file_id, feature_id, kx_ghs9 FROM dup_agg0) ) t
                  GROUP BY file_id, kx_ghs9
                  ORDER BY file_id, kx_ghs9
                  ) AS t
              LEFT JOIN dup_agg0 f0
              ON t.file_id = f0.file_id AND t.kx_ghs9 = f0.kx_ghs9
              LEFT JOIN ingest.feature_asis f
              ON t.file_id = f.file_id AND t.kx_ghs9 = f.kx_ghs9 AND f.feature_id = f0.feature_id
          ),
          ins_asis_discarded AS (
              INSERT INTO ingest.feature_asis_discarded (file_id, feature_id, properties, geom)
              SELECT file_id, feature_id, ( properties || jsonb_build_object('error', error) ) AS properties, geom
              FROM ( SELECT * FROM dup_mask  WHERE (file_id, feature_id, kx_ghs9) NOT IN ( SELECT file_id, feature_id, kx_ghs9 FROM dup_agg0) ) t
              ON CONFLICT (file_id,feature_id)
              DO UPDATE
              SET properties = EXCLUDED.properties
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

      IF p_check_file_id_exist THEN
          UPDATE ingest.donated_PackComponent
          SET proc_step=2,   -- if insert process occurs after q_query.
              lineage = lineage || ingest.feature_asis_assign(q_file_id) ||
              jsonb_build_object('statistics',(stats || stats_dup || ARRAY[num_items-stats_dup[1]+stats_dup[3]]) || ARRAY[stats[12]+stats_dup[2]] )
          WHERE id=q_file_id;
      END IF;
    END IF;
  END IF;

  IF num_items>0 AND p_check_file_id_exist THEN
    UPDATE ingest.donated_PackComponent
    SET proc_step=3,   -- if insert process occurs after q_query.
        lineage =  lineage || ingest.feature_asis_assign_signature(q_file_id)
    WHERE id=q_file_id;
  END IF;

  RETURN ingest.any_load_returnmsg(q_file_id);
  END;
$f$ LANGUAGE PLpgSQL;
COMMENT ON FUNCTION ingest.any_load(text,text,text,text,bigint,text,text[],int,int,boolean,text,boolean,text,text)
  IS 'Load (into ingest.feature_asis) shapefile or any other, of a separated table.'
;
-- posto ipiranga logo abaixo..  sorvetorua.
-- ex. SELECT ingest.any_load('/tmp/pg_io/NRO_IMOVEL.shp','geoaddress_none','pk027_geoaddress1',27,array['gid','textstring']);

CREATE or replace FUNCTION ingest.any_load_assign(
    p_fileref text,  -- apenas referencia para ingest.donated_PackComponent
    p_ftname text,   -- featureType of layer... um file pode ter mais de um layer??
    p_pck_id bigint  -- id do package da Preservação.
) RETURNS text AS $f$
  DECLARE
    q_file_id integer;
  BEGIN
  q_file_id := ingest.getmeta_to_file(p_fileref,p_ftname,p_pck_id);

  IF (SELECT COUNT(*) FROM ingest.feature_asis WHERE file_id=q_file_id)>0 AND (SELECT ftid::int FROM ingest.fdw_feature_type WHERE ftname=lower(p_ftname))>=20 THEN
    UPDATE ingest.donated_PackComponent
    SET proc_step=2,   -- if insert process occurs after q_query.
        lineage = lineage || ingest.feature_asis_assign(q_file_id)
    WHERE id=q_file_id;
  END IF;

  IF (SELECT COUNT(*) FROM ingest.feature_asis WHERE file_id=q_file_id)>0 THEN
    UPDATE ingest.donated_PackComponent
    SET proc_step=3,   -- if insert process occurs after q_query.
        lineage =  lineage || ingest.feature_asis_assign_signature(q_file_id)
    WHERE id=q_file_id;
  END IF;

  RETURN 'Ok';
  END;
$f$ LANGUAGE PLpgSQL;
COMMENT ON FUNCTION ingest.any_load_assign(text,text,bigint)
  IS 'Assign when ingest multiple files per layer.'
;

CREATE OR replace PROCEDURE ingest.any_load_loop(
    p_method text,   -- shp/csv/etc.
    p_fileref text,  -- apenas referencia para ingest.donated_PackComponent
    p_ftname text,   -- featureType of layer... um file pode ter mais de um layer??
    p_tabname text,  -- tabela temporária de ingestão
    p_pck_id bigint,   -- id do package da Preservação.
    p_pck_fileref_sha256 text,
    p_tabcols text[] DEFAULT NULL, -- array[]=tudo, senão lista de atributos de p_tabname, ou só geometria
    p_id_profile_params int DEFAULT 1,
    buffer_type int DEFAULT 1,
    p_check_file_id_exist boolean DEFAULT true,
    p_geom_name text DEFAULT 'geom',
    p_to4326 boolean DEFAULT true, -- on true converts SRID to 4326 .
    p_partition_name  text DEFAULT NULL
)
LANGUAGE PLpgSQL
AS $$
DECLARE
    r RECORD;
    t text;
BEGIN
    FOR r IN EXECUTE format('SELECT DISTINCT %s AS value FROM %s' ,p_partition_name, p_tabname)
    LOOP
        RAISE NOTICE 'Partition ingestion: %', r.value;
        SELECT INTO t ingest.any_load(p_method,p_fileref,p_ftname,p_tabname,p_pck_id,p_pck_fileref_sha256,p_tabcols,p_id_profile_params,buffer_type,p_check_file_id_exist,p_geom_name,p_to4326,p_partition_name,(r.value)::text);
        COMMIT;
        RAISE NOTICE 'Partition % committed. Result: %', r.value, t;
    END LOOP;
END;
$$;
COMMENT ON PROCEDURE ingest.any_load_loop(text,text,text,text,bigint,text,text[],int,int,boolean,text,boolean,text)
  IS 'Load data into ingest.feature_asis partitionally, using column p_partition_name.'
;

CREATE or replace FUNCTION ingest.any_load(
    p_method text,                              --  1. shp/csv/etc.
    p_fileref text,                             --  2. apenas referencia para ingest.donated_PackComponent
    p_ftname text,                              --  3. featureType of layer... um file pode ter mais de um layer??
    p_tabname text,                             --  4. tabela temporária de ingestáo
    p_pck_id text,                              --  5. id do package da Preservação no formato "a.b".
    p_pck_fileref_sha256 text,                  --  6.
    p_tabcols text[] DEFAULT NULL,              --  7. lista de atributos, ou só geometria
    p_id_profile_params int DEFAULT 1,          --  8.
    buffer_type int DEFAULT 1,                  --  9.
    p_check_file_id_exist boolean DEFAULT true, -- 10.
    p_geom_name text DEFAULT 'geom',            -- 11.
    p_to4326 boolean DEFAULT true,              -- 12.. on true converts SRID to 4326 .
    p_partition_name  text DEFAULT NULL,
    p_partition_value text DEFAULT NULL
) RETURNS text AS $wrap$
   SELECT ingest.any_load($1, $2, $3, $4, to_bigint($5), $6, $7, $8, $9, $10, $11, $12, $13, $14)
$wrap$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.any_load(text,text,text,text,text,text,text[],int,int,boolean,text,boolean,text,text)
  IS 'Wrap to ingest.any_load(1,2,3,4=real) using string format DD_DD.'
;

CREATE or replace FUNCTION ingest.osm_load(
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
      a AS (
        SELECT *
        FROM scan
        WHERE ST_IsClosed(geom) = TRUE OR GeometryType(geom) IN ('LINESTRING','MULTILINESTRING')
      ),
      mask AS (SELECT geom FROM ingest.vw01full_jurisdiction_geom WHERE isolabel_ext=(SELECT isolabel_ext FROM ingest.vw01full_packfilevers WHERE id=%s)),
      b AS (
        SELECT file_id, gid, properties, geom, ( B'000000000' ||  (NOT(ST_IsSimple(geom)))::int::bit || (NOT(ST_IsValid(geom)))::int::bit || (NOT(ST_Intersects(geom,(SELECT geom FROM mask))))::int::bit ) AS error
        FROM a
      ),
      c AS (
        (
        SELECT file_id, gid, properties, geom, (error | ( B'00000' || (GeometryType(geom) NOT IN %s)::int::bit || (geom IS NULL)::int::bit || (CASE (SELECT (ingest.donated_PackComponent_geomtype(%s))[1]) WHEN 'poly' THEN ST_Area(geom,true) < 5 WHEN 'line' THEN ST_Length(geom,true) < 2 ELSE FALSE END)::int::bit || (ST_IsEmpty(geom))::int::bit || B'000' )) AS error
        FROM (
           SELECT file_id, gid,
                  properties,
                  CASE (SELECT (ingest.donated_PackComponent_geomtype(%s))[1])
                    WHEN 'point' THEN ST_ReducePrecision( geom, 0.000001 )
                    ELSE ST_SimplifyPreserveTopology( -- remove collinear points 
			    ST_ReducePrecision( -- round decimal degrees of SRID 4326, ~1 meter
			      geom
			      ,0.000001
		            ),
			    0.00000001
		    )
	          END AS geom,
	          error
           FROM b
           WHERE bit_count(error) = 0
           ) t
        )
        UNION
        (
            SELECT * FROM b WHERE bit_count(error) <> 0
        )
        UNION
        (
            SELECT file_id, gid, properties, geom, B'000100000000' AS error
            FROM scan
            WHERE ST_IsClosed(geom) = FALSE AND GeometryType(geom) NOT IN ('LINESTRING','MULTILINESTRING')
        )
      ),
      stats AS (
      SELECT ARRAY [
            (SELECT COUNT(*) FROM scan)::bigint,
            (COUNT(*) filter (WHERE get_bit(error,11) = 1))::bigint, -- intersects
            (COUNT(*) filter (WHERE get_bit(error,10) = 1))::bigint, -- invalid
            (COUNT(*) filter (WHERE get_bit(error, 9) = 1))::bigint, -- simple
            (COUNT(*) filter (WHERE get_bit(error, 8) = 1))::bigint, -- empty
            (COUNT(*) filter (WHERE get_bit(error, 7) = 1))::bigint, -- small
            (COUNT(*) filter (WHERE get_bit(error, 6) = 1))::bigint, -- null
            (COUNT(*) filter (WHERE get_bit(error, 5) = 1))::bigint, -- invalid_type
                                                                          -- bit 4 é reservado para duplicados
            (COUNT(*) filter (WHERE get_bit(error, 3) = 1))::bigint  -- is_closed
            ]
        FROM c
      ),
      ins_asis AS (
        INSERT INTO ingest.feature_asis
        SELECT file_id, gid, properties, geom
        FROM c
	    WHERE  bit_count(error) = 0
        RETURNING 1
      ),
      ins_asis_discarded AS (
        INSERT INTO ingest.feature_asis_discarded (file_id, feature_id, properties, geom)
        SELECT file_id, gid, properties || jsonb_build_object('error',error), geom
        FROM c
	    WHERE  bit_count(error) <> 0
        RETURNING 1
      )
      SELECT array_append(array_append( (SELECT * FROM stats), (SELECT COUNT(*) FROM ins_asis) ), (SELECT COUNT(*) FROM ins_asis_discarded))
    $$,
    q_file_id,
    iif(p_to4326,'true'::text,'false'),  -- decide ST_Transform
    iif(p_to4326,'true'::text,'false'),  -- decide ST_Transform
    feature_id_col,
    iIF( use_tabcols, $$to_jsonb(subq) - 'tags' || (subq).tags $$::text, $$tags$$ ), -- properties
    CASE WHEN lower(p_geom_name)='geom' THEN 'geom' ELSE p_geom_name||' AS geom' END,
    p_tabname,
    iIF( use_tabcols, ', LATERAL (SELECT '|| array_to_string(p_tabcols,',') ||') subq',  ''::text ),
    p_pck_id,
        (CASE (SELECT (ingest.donated_PackComponent_geomtype(q_file_id))[1])
        WHEN 'point' THEN $$('POINT')$$ 
        WHEN 'poly'  THEN $$('POLYGON'   ,'MULTIPOLYGON')$$
        WHEN 'line'  THEN $$('LINESTRING','MULTILINESTRING')$$
        END),
    q_file_id,
    q_file_id
  );

    EXECUTE q_query INTO stats;
    num_items := stats[10];
    msg_ret := format(
        E'From file_id=%s inserted type=%s.\nStatistics:\n
        %s\n',
        q_file_id, p_ftname, format(
        E'Originals: %s items.\n
        Not Intersecs: %s items.\n
        Invalid: %s items.\n
        Not simple: %s items.\n
        Empty: %s items.\n
        Small: %s items.\n
        Null: %s items.\n
        Invalid geometry type: %s items.\n
        Not closed: %s items.\n
        Inserted feature_asis: %s items.\n
        Inserted feature_asis_discarded: %s items.\n',
        VARIADIC stats
    )
    );

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
        SELECT *, B'000010000000' AS error
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
            SELECT file_id, feature_id, ( properties || jsonb_build_object('error', error) ) AS properties, geom
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
        Not closed: %s items.\n
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
        THEN jsonb_strip_nulls(jsonb_build_object('address', address, 'name', name, 'nsvia', nsvia, 'postcode', postcode, 'error', error_code, 'info', infop, 'bytes', length(St_asGeoJson(t.geom))))
        ELSE jsonb_strip_nulls(jsonb_build_object('address', address, 'name', name, 'nsvia', nsvia, 'postcode', postcode, 'error', error_code, 'info', infop                                       ))
        END AS info,
        t.geom
  FROM
  (
      SELECT file_id, fa.geom, fa.feature_id::int AS gid, fa.kx_ghs9 AS ghs,

      properties->>'nsvia'    AS nsvia,
      properties->>'name'     AS name,
      properties->>'postcode' AS postcode,

      CASE WHEN (properties->>'is_agg')::boolean THEN 100 END AS error_code,
      COALESCE(nullif(properties->'is_complemento_provavel','null')::boolean,false) AS is_compl,

      NULLIF(properties - ARRAY['via','hnum','sup'],'{}'::jsonb) AS infop,

      CASE sys_housenumber
      WHEN 'metric' THEN
        ROW_NUMBER() OVER(ORDER BY properties->>'via', to_bigint(properties->>'hnum'))
      WHEN 'bh-metric' THEN
        ROW_NUMBER() OVER(ORDER BY properties->>'via', to_bigint(regexp_replace(properties->>'hnum', '\D', '', 'g')), regexp_replace(properties->>'hnum', '[^[:alpha:]]', '', 'g') )
      WHEN 'street-metric' THEN
        ROW_NUMBER() OVER(ORDER BY properties->>'via', regexp_replace(properties->>'hnum', '[^[:alnum:]]', '', 'g'))
      WHEN 'block-metric' THEN
        ROW_NUMBER() OVER(ORDER BY properties->>'via', to_bigint(split_part(replace(properties->>'hnum',' ',''), '-', 1)), to_bigint(split_part(replace(properties->>'hnum',' ',''), '-', 2)))
      WHEN 'ago-block' THEN
        ROW_NUMBER() OVER(ORDER BY properties->>'via', to_bigint(properties->>'hnum'), to_bigint(split_part(properties->>'sup', ',', 1)), to_bigint(split_part(properties->>'sup', ',', 2)) )
      -- WHEN 'df-block' THEN
      --   ROW_NUMBER() OVER(ORDER BY to_bigint(properties->>'blref'),to_bigint(properties->>'set'),to_bigint(properties->>'pnum'))
      ELSE
        ROW_NUMBER() OVER(ORDER BY properties->>'via', to_bigint(properties->>'hnum'))
      END AS address_order,

      CASE sys_housenumber
      WHEN 'ago-block' THEN
      (
        CASE WHEN ((trim(properties->>'via')  = '') IS FALSE) THEN trim(properties->>'via')  ELSE '?' END || ', ' ||
        CASE WHEN ((trim(properties->>'hnum') = '') IS FALSE) THEN trim(properties->>'hnum') ELSE '?' END || ', ' ||
        CASE WHEN ((trim(properties->>'sup')  = '') IS FALSE) THEN trim(properties->>'sup')  ELSE '?' END
      )
      ELSE
      (
        CASE WHEN ((trim(properties->>'via')  = '') IS FALSE) THEN trim(properties->>'via')  ELSE '?' END || ', ' ||
        CASE WHEN ((trim(properties->>'hnum') = '') IS FALSE) THEN trim(properties->>'hnum') ELSE '?' END
      )
      END AS address

      FROM ingest.feature_asis AS fa
      WHERE fa.file_id=p_file_id
  ) t
  ORDER BY address_order;

  WHEN ( p_ftname IN ('block','via','genericvia','nsvia') ) OR ( p_ftname IN ('building') AND NOT ( (jproperties ?| ARRAY['via','hnum','sup']) ) ) THEN
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
--$f$ LANGUAGE SQL IMMUTABLE;
-- SELECT * FROM ingest.feature_asis_export(5) t LIMIT 1000;

CREATE or replace FUNCTION ingest.feature_asis_export_csv(
	p_file_id bigint,
	p_name    text DEFAULT NULL,
	p_path    text DEFAULT '/tmp/pg_io'
) RETURNS text AS $f$
DECLARE
    q_copy text;
    class_ftname text;
    filename text;
    jproperties jsonb;
BEGIN
  SELECT ft_info->>'class_ftname',
         'a4a_' || replace(lower(isolabel_ext),'-','_') || '_' || split_part(ftname,'_',1) || '_' || packvers_id
  FROM ingest.vw03full_layer_file WHERE id=p_file_id
  INTO class_ftname, filename;

  SELECT properties || (SELECT properties FROM ingest.feature_asis_discarded WHERE file_id=p_file_id LIMIT 1)
  FROM ingest.feature_asis WHERE file_id=p_file_id LIMIT 1
  INTO jproperties;

  q_copy := $$
        COPY (
              SELECT feature_id AS gid, %s ST_X(geom) AS longitude, ST_Y(geom) AS latitude
              FROM
              (
                SELECT *
                FROM ingest.feature_asis
                WHERE file_id=%s

                UNION

                SELECT *
                FROM ingest.feature_asis_discarded
                WHERE file_id=%s
              ) fa
              ORDER BY feature_id
            ) TO '%s' CSV HEADER
    $$;

  CASE class_ftname
  WHEN 'geoaddress' THEN
    EXECUTE format(q_copy,
    (
      NULLIF(
      array_to_string(
      (
        SELECT array_agg(('properties->>''' || x || ''' AS ' || x))
        FROM jsonb_object_keys(jproperties) t(x)
        WHERE x IN ('via','hnum','sup','postcode','nsvia','name','type','ref','error')
      ),', ')
    || ',',',')
    ),
    p_file_id,
    p_file_id,
    p_path || '/' || (CASE WHEN p_name IS NULL THEN filename ELSE p_name END) || '.csv'
    );
  ELSE NULL;
  END CASE;

  RETURN filename
  ;
END
$f$ language PLpgSQL;
COMMENT ON FUNCTION ingest.feature_asis_export_csv(bigint,text,text)
  IS 'Export geoaddress layer from ingest.feature_assis table to csv file.'
;
-- SELECT ingest.feature_asis_export_csv(3::bigint);


CREATE or replace FUNCTION ingest.feature_asis_export_shp_cmd(
	p_file_id bigint
) RETURNS text AS $f$
DECLARE
    q_copy text;
    jproperties jsonb;
BEGIN
  SELECT properties || (SELECT properties FROM ingest.feature_asis_discarded WHERE file_id=p_file_id LIMIT 1)
  FROM ingest.feature_asis WHERE file_id=p_file_id LIMIT 1
  INTO jproperties;

  q_copy := $$SELECT feature_id AS gid, %s geom FROM ((SELECT * FROM ingest.feature_asis WHERE file_id=%s) UNION (SELECT * FROM ingest.feature_asis_discarded WHERE file_id=%s)) fa ORDER BY feature_id$$;

  RETURN format(q_copy,
    (
    NULLIF(
        array_to_string(
        (
          SELECT array_agg(('properties->>''' || x || ''' AS ' || x))
          FROM jsonb_object_keys(jproperties) t(x)
          WHERE
          (
            CASE
            WHEN jproperties ?| ARRAY['via','hnum','sup','postcode','nsvia','name','type','ref','error']
            THEN x IN ('via','hnum','sup','postcode','nsvia','name','type','ref','error')
            ELSE NULL
            END
          )
        ),', ') || ','
    ,',')
    ),
    p_file_id,
    p_file_id
  )
  ;
END
$f$ language PLpgSQL;
COMMENT ON FUNCTION ingest.feature_asis_export_shp_cmd(bigint)
  IS 'Generate query to use in pgsql2shp program.'
;
-- SELECT ingest.feature_asis_export_shp_cmd(1::bigint);

-- ----------------------------

CREATE TABLE ingest.publicating_geojsons_p3exprefix(
 kx_ghs9   text,
 prefix text,
 gid    integer,
 info   jsonb,
 geom   geometry
);

CREATE TABLE ingest.publicating_geojsons_p3exprefix_aux(
 kx_ghs9   text,
 prefix text,
 gid    integer,
 info   jsonb,
 geom   geometry
);

CREATE TABLE ingest.publicating_geojsons_p2distrib(
 hcode    text,
 n_items  integer,
 n_keys   integer,
 jj       text[],
 geom     geometry
);

CREATE TABLE ingest.publicating_geojsons_p5distrib(
 ghs    text,
 info   jsonb,
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

/*
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
*/

CREATE or replace FUNCTION ingest.publicating_geojsons_p3(
	p_file_id    bigint,  -- e.g. 1, see ingest.donated_PackComponent
	p_isolabel_ext  text, -- e.g. 'BR-MG-BeloHorizonte', see jurisdiction_geom
	p_fileref text,       --
	p_buffer_type int DEFAULT 1,
	p_size_max      int    DEFAULT 1     -- 5. max size of hcode
) RETURNS text  AS $f$
BEGIN
    DELETE FROM ingest.publicating_geojsons_p2distrib;
    INSERT INTO ingest.publicating_geojsons_p2distrib
        SELECT t.hcode, t.n_items, t.n_keys,  t.jj, -- length(t.hcode) AS len,
        ST_Intersection(
            ST_SetSRID( ST_geomFromGeohash(replace(t.hcode, '*', '')) ,  4326),
            (SELECT geom FROM ingest.vw01full_jurisdiction_geom WHERE isolabel_ext=p_isolabel_ext)
        ) AS geom
        FROM hcode.distribution_reduce_recursive_raw_alt(
            ((SELECT jsonb_object_agg(kx_ghs9,(CASE (SELECT geomtype FROM ingest.vw03full_layer_file WHERE id=$1) WHEN 'point' THEN 1::bigint ELSE ((info->'bytes')::bigint) END) ) FROM ingest.publicating_geojsons_p3exprefix)),
            1,
            (
                CASE (SELECT COUNT(*) FROM ingest.feature_asis WHERE file_id=p_file_id ) > 1000000
                WHEN TRUE THEN (SELECT length((geohash_cover_list(geom))[1]) FROM ingest.vw01full_jurisdiction_geom WHERE isolabel_ext=p_isolabel_ext)
                ELSE (SELECT length((geohash_cover_list( ST_Collect(ST_Force2D(geom)) ))[1]) FROM ingest.feature_asis WHERE file_id=$1)
                END
            ),
            $5,
            (SELECT (lineage->'hcode_distribution_parameters'->'p_threshold_sum')::int FROM ingest.donated_PackComponent WHERE id= p_file_id),
            (CASE (SELECT geomtype FROM ingest.vw03full_layer_file WHERE id=$1) WHEN 'point' THEN 1000::int ELSE 102400::int END)
        ) t
    ;

    PERFORM pg_catalog.pg_file_unlink(p_fileref || '/'|| (CASE geomtype WHEN 'point' THEN 'pts' WHEN 'line' THEN 'lns' WHEN 'poly' THEN 'pols' END) || '_*.geojson') FROM ingest.vw03full_layer_file WHERE id=$1;

    --UPDATE ingest.publicating_geojsons_p3exprefix
    --SET prefix=t.prefix
    --FROM (
        --SELECT hcode AS prefix, unnest(jj) as kx_ghs9
        --FROM ingest.publicating_geojsons_p2distrib
    --) t
    --WHERE t.kx_ghs9 = publicating_geojsons_p3exprefix.kx_ghs9
    --;

    DELETE FROM ingest.publicating_geojsons_p3exprefix_aux;
    INSERT INTO ingest.publicating_geojsons_p3exprefix_aux
    SELECT p3.kx_ghs9, p2.prefix, p3.gid, p3.info, p3.geom
    FROM ingest.publicating_geojsons_p3exprefix p3
    LEFT JOIN
      (
        SELECT unnest(jj) as kx_ghs9, hcode AS prefix
        FROM ingest.publicating_geojsons_p2distrib
      ) p2
    ON p3.kx_ghs9 = p2.kx_ghs9;

    DELETE FROM ingest.publicating_geojsons_p3exprefix;
    INSERT INTO ingest.publicating_geojsons_p3exprefix
    SELECT * FROM ingest.publicating_geojsons_p3exprefix_aux;

    UPDATE ingest.donated_PackComponent
    SET proc_step=4, 
        kx_profile = coalesce(kx_profile,'{}'::jsonb) || jsonb_build_object('ghs_distrib_mosaic', (SELECT jsonb_object_agg(hcode, n_keys) FROM ingest.publicating_geojsons_p2distrib))
    WHERE id= p_file_id
    ;

    DELETE FROM ingest.publicating_geojsons_p2distrib; -- limpa
    DELETE FROM ingest.publicating_geojsons_p3exprefix_aux;
    RETURN 'p3';
END
$f$ language PLpgSQL; --fim p3

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
    $$fa.properties->>'via' AS name$$,
    p_file_id,
    $$fa.properties->>'via'$$,
    p_fileref || '/distrib_viaName_ghs.csv'
    );
  WHEN 'nsvia' THEN
    EXECUTE format(q_copy,
    $$fa.properties->>'nsvia' AS name$$,
    p_file_id,
    $$fa.properties->>'nsvia'$$,
    p_fileref || '/distrib_name_ghs.csv'
    );
  WHEN 'genericvia', 'block', 'building' THEN
    EXECUTE format(q_copy,
    $$fa.properties->>'name' AS name$$,
    p_file_id,
    $$fa.properties->>'name'$$,
    p_fileref || '/distrib_name_ghs.csv'
    );
  ELSE NULL;
  END CASE;

  RETURN (SELECT 'Arquivos de file_id='|| p_file_id::text || ' publicados em ' || p_file_id::text || '/' || (CASE geomtype WHEN 'point' THEN 'pts' WHEN 'line' THEN 'lns' WHEN 'poly' THEN 'pols' END) ||'_*.geojson' FROM ingest.vw03full_layer_file WHERE id=$1)
  ;
END
$f$ language PLpgSQL; -- fim p4


CREATE or replace FUNCTION ingest.publicating_geojsons_p5(
	p_file_id    bigint,  -- e.g. 1, see ingest.donated_PackComponent
	p_isolabel_ext  text, -- e.g. 'BR-MG-BeloHorizonte', see jurisdiction_geom
	p_fileref text,       -- e.g.
	p_buffer_type int DEFAULT 1,  -- e.g.
	p_pretty_opt int DEFAULT 3
) RETURNS text  AS $f$
BEGIN

    DELETE FROM ingest.publicating_geojsons_p5distrib;

    CASE (SELECT geomtype FROM ingest.vw03full_layer_file WHERE id=p_file_id)
    WHEN 'point' THEN
        WITH geohash_GeomsMosaic AS (
            SELECT * FROM  geohash_GeomsMosaic_jinfo(
                            (SELECT kx_profile->'ghs_distrib_mosaic' from ingest.donated_packcomponent WHERE id=$1),
                            '{"density_km2":"val","area_km2":"val","area":"val"}  '::jsonb,
                            (SELECT ingest.buffer_geom(geom,1) FROM ingest.vw01full_jurisdiction_geom where isolabel_ext=$2)
                            )
        )
        INSERT INTO ingest.publicating_geojsons_p5distrib
        SELECT  t.ghs,
                (u.info || jsonb_build_object(
                    'ghsval_unit','items',
                    'ghs_bytes', bytes,
                    'ghs_itemsDensity', ((u.info->'ghs_items')::float/(u.info->'area_km2')::float),
                    'ghs_area', ((u.info->'area_km2')::float) )
                ) AS info,
                u.geom
        FROM
        (
            SELECT  ghs,
                    SUM(length(St_asGeoJson(ST_Intersection( r.geom, s.geom )))) AS bytes
            FROM ingest.publicating_geojsons_p3exprefix r
            LEFT JOIN geohash_GeomsMosaic s
            ON r.prefix = s.ghs
            GROUP BY ghs
        ) t
        LEFT JOIN geohash_GeomsMosaic u
        ON t.ghs = u.ghs
        ;
    ELSE
        WITH geohash_GeomsMosaic AS (
            SELECT * FROM  geohash_GeomsMosaic_jinfo(
                            (SELECT kx_profile->'ghs_distrib_mosaic' from ingest.donated_packcomponent WHERE id=$1),
                            '{"density_km2":"val","area_km2":"val","area":"val"}  '::jsonb,
                            (SELECT ingest.buffer_geom(geom,1) FROM ingest.vw01full_jurisdiction_geom where isolabel_ext=$2)
                            )
        )
        INSERT INTO ingest.publicating_geojsons_p5distrib
        SELECT  t.ghs,
                (u.info || jsonb_build_object(
                    'ghsval_unit','bytes',
                    'ghs_bytes', bytes,
                    'size', size,
                    'size_unit', size_unit,
                    'size_unitDensity', (size::float/(u.info->'area_km2')::float),
                    'ghs_itemsDensity', ((u.info->'ghs_items')::float/(u.info->'area_km2')::float),
                    'ghs_area', ((u.info->'area_km2')::float) )
                ) AS info,
                u.geom
        FROM
        (
            SELECT  ghs,
                    SUM(length(St_asGeoJson(ST_Intersection( r.geom, s.geom )))) AS bytes,

                    (CASE (SELECT geomtype FROM ingest.vw03full_layer_file WHERE id=$1) WHEN 'line' THEN SUM(ST_Length(ST_Intersection( r.geom, s.geom ), true))/1000  WHEN 'poly' THEN SUM(ST_Area(ST_Intersection( r.geom, s.geom ),true))/1000000.0  END) AS size,
                    (SELECT lineage->'feature_asis_summary'->'size_unit' FROM ingest.vw03full_layer_file WHERE id=$1) AS size_unit
            FROM ingest.publicating_geojsons_p3exprefix r
            LEFT JOIN geohash_GeomsMosaic s
            ON r.prefix = s.ghs
            GROUP BY ghs
        ) t
        LEFT JOIN geohash_GeomsMosaic u
        ON t.ghs = u.ghs
        ;
    END CASE;

    CASE (SELECT geomtype FROM ingest.vw03full_layer_file WHERE id=p_file_id)
    WHEN 'point' THEN
        PERFORM write_geojsonb_features(
            format('SELECT * FROM ingest.publicating_geojsons_p5distrib'),
            format('%s/geohashes.geojson',p_fileref),
            't1.geom',
            'ghs, (info->''ghs_items'')::int AS ghs_items, (info->''ghs_len'')::int AS ghs_len, round((info->''ghs_itemsDensity'')::float,0.01) AS ghs_itemsDensity, round((info->''ghs_area'')::float,0.01) AS ghs_area, (info->''ghs_bytes'') AS ghs_bytes, (info->''ghsval_unit'') AS ghsval_unit',
            NULL,
            NULL,
            $5,
            5);
    ELSE
        PERFORM write_geojsonb_features(
            format('SELECT * FROM ingest.publicating_geojsons_p5distrib'),
            format('%s/geohashes.geojson',p_fileref),
            't1.geom', 
            'ghs, (info->''ghs_items'')::int AS ghs_items, (info->''ghs_len'')::int AS ghs_len, round((info->''ghs_itemsDensity'')::float,0.01) AS ghs_itemsDensity, round((info->''ghs_area'')::float,0.01) AS ghs_area, round((info->''size'')::float,0.01) AS size, (info->''size_unit'') AS size_unit, round((info->''size_unitDensity'')::float,0.01) AS size_unitDensity, (info->''ghs_bytes'') AS ghs_bytes, (info->''ghsval_unit'') AS ghsval_unit',
            NULL,
            NULL,
            $5,
            5);
    END CASE;

    UPDATE ingest.donated_packcomponent
    SET proc_step=5, kx_profile = kx_profile || jsonb_build_object(
        'publication_summary', (SELECT jsonb_build_object(
                'itens', SUM((info->'ghs_items')::int),
                'bytes', SUM((info->'ghs_bytes')::bigint),
                'size', SUM((info->'size')::float),
                'size_unit', MIN((info->>'size_unit')),
                'size_unitDensity', (CASE (SELECT geomtype FROM ingest.vw03full_layer_file WHERE id=$1)
                                    WHEN 'point' THEN SUM((info->'ghs_itemsDensity')::float)
                                    ELSE                   SUM((info->'size_unitDensity')::float)
                                    END),
                'avg_density', (CASE (SELECT geomtype FROM ingest.vw03full_layer_file WHERE id=$1)
                                    WHEN 'point' THEN AVG((info->'ghs_itemsDensity')::float)
                                    ELSE                   AVG((info->'size_unitDensity')::float)
                                    END)) FROM ingest.publicating_geojsons_p5distrib ),
        'date_generation', (date_trunc('second',NOW())),
        'ghs_info_mosaic', (SELECT jsonb_object_agg(ghs, info) FROM ingest.publicating_geojsons_p5distrib WHERE ghs IS NOT NULL)
        )
    WHERE id = $1 ;

    DELETE FROM ingest.publicating_geojsons_p3exprefix; -- limpa
    DELETE FROM ingest.publicating_geojsons_p5distrib;  -- limpa
    RETURN (SELECT 'Mosaico de file_id='|| p_file_id::text || ' publicado em ' || p_fileref::text || '/geohashes.geojson')
  ;
END
$f$ language PLpgSQL; -- fim p5

CREATE or replace FUNCTION ingest.publicating_geojsons(
	p_file_id    bigint,          -- e.g. 1, see ingest.donated_PackComponent
	p_isolabel_ext  text,         -- e.g. 'BR-MG-BeloHorizonte', see jurisdiction_geom
	p_fileref text,               -- e.g.
	p_buffer_type int DEFAULT 1,  -- e.g.
	p_size_max int DEFAULT 1,     -- e.g.
	p_pretty_opt int DEFAULT 3
) RETURNS text  AS $f$
  SELECT ingest.publicating_geojsons_p1($1,$2);
  --SELECT ingest.publicating_geojsons_p2($1,$2,(SELECT CASE geomtype WHEN 'point' THEN false ELSE true END FROM ingest.vw03full_layer_file WHERE id=$1));
  SELECT ingest.publicating_geojsons_p3($1,$2,$3,$4,$5);
  SELECT ingest.publicating_geojsons_p4($1,$2,$3);
  SELECT ingest.publicating_geojsons_p5($1,$2,$3,$4,$6);
  SELECT 'fim';
$f$ language SQL VOLATILE; -- need be a sequential PLpgSQL to neatly COMMIT?

CREATE or replace FUNCTION ingest.publicating_geojsons(
	p_ftname text,                -- e.g. 'geoaddress'
	p_isolabel_ext  text,         -- e.g. 'BR-MG-BeloHorizonte', see jurisdiction_geom
	p_fileref text,               -- e.g.
	p_buffer_type int DEFAULT 1,  -- e.g.
	p_size_max int DEFAULT 1,     -- e.g.
	p_pretty_opt int DEFAULT 3
) RETURNS text AS $wrap$
  SELECT ingest.publicating_geojsons((SELECT id FROM ingest.vw03full_layer_file WHERE isolabel_ext = $2 AND lower(ft_info->>'class_ftname') = lower($1)),$2,$3,$4,$5,$6);
$wrap$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.publicating_geojsons(text,text,text,int,int,int)
  IS 'Wrap to ingest.publicating_geojsons'
;
-- SELECT ingest.publicating_geojsons('geoaddress','BR-MG-BeloHorizonte','folder');

-- ----------------------------

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
                AND packvers_id = (SELECT id FROM ingest.vw01full_packfilevers WHERE hashedfname = '%s')
            )
      ),
      duplicate_keys AS (
        SELECT cadis.properties->'%s'
        FROM
        --(
            --SELECT  *
            --FROM ingest.feature_asis
            --WHERE file_id IN
            --(
                --SELECT id
                --FROM ingest.donated_PackComponent
                --WHERE ftid IN
                    --(
                    --SELECT ftid::int
                    --FROM ingest.fdw_feature_type
                    --WHERE ftname=lower('%s')
                    --)
                    --AND packvers_id = (SELECT id FROM ingest.vw01full_packfilevers WHERE hashedfname = '%s')
            --)
        --) AS asis

        --INNER JOIN

        cadis

        --ON asis.properties->'%s' = cadis.properties->'%s'

        GROUP BY cadis.properties->'%s'

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
                AND packvers_id = (SELECT id FROM ingest.vw01full_packfilevers WHERE hashedfname = '%s')
            )
            AND c.properties->'%s' NOT IN (  SELECT * FROM duplicate_keys  )
            RETURNING 1
            )
      SELECT COUNT(*) FROM layer_features
    $$,
    p_ftname_cad,
    p_fileref_cad_sha256,
    p_join_col_cad,
    p_ftname_layer,
    p_fileref_layer_sha256,
    p_join_col_layer,
    p_join_col_cad,
    p_join_col_cad,
    p_join_col_cad,
    p_join_col_layer,
    p_join_col_cad,
    p_ftname_layer,
    p_fileref_layer_sha256,
    p_join_col_cad
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
