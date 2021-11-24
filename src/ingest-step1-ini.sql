-- INGEST STEP1
-- Inicialização do Módulo Ingest dos prjetos Digital-Guard.
--

CREATE extension IF NOT EXISTS postgis;
CREATE extension IF NOT EXISTS adminpack;

CREATE EXTENSION IF NOT EXISTS file_fdw;
CREATE SERVER    IF NOT EXISTS files FOREIGN DATA WRAPPER file_fdw;

CREATE schema    IF NOT EXISTS ingest;
CREATE schema    IF NOT EXISTS tmp_orig;

CREATE EXTENSION postgres_fdw;
CREATE SERVER foreign_server
        FOREIGN DATA WRAPPER postgres_fdw
        OPTIONS (dbname 'dl03t_main')
;
CREATE USER MAPPING FOR PUBLIC SERVER foreign_server;

-- -- --
-- SQL and bash generators (optim-ingest submodule)

CREATE or replace FUNCTION ingest.fdw_csv_paths(
  p_name text, p_context text DEFAULT 'br', p_path text DEFAULT NULL
) RETURNS text[] AS $f$
  SELECT  array[
    fpath, -- /tmp/pg_io/digital-preservation-XX
    concat(fpath,'/', iIF(p_context IS NULL,''::text,p_context||'-'), p_name, '.csv')
  ]
  FROM COALESCE(p_path,'/tmp/pg_io') t(fpath)
$f$ language SQL;


CREATE or replace FUNCTION ingest.fdw_generate_direct_csv(
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

CREATE or replace FUNCTION ingest.fdw_generate(
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

CREATE or replace FUNCTION ingest.fdw_generate_getCSV(
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


CREATE or replace FUNCTION ingest.fdw_generate_getclone(
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
CREATE TABLE ingest.via_line(
  pck_id real NOT NULL, -- REFERENCES optim.donatedPack(pck_id),
  vianame text,
  is_informal boolean default false, -- non-official name (loteametos com ruas ainda sem nome)
  geom geometry,
  info JSONb,
  UNIQUE(pck_id,geom)
);
COMMENT ON TABLE ingest.via_line
  IS 'Ingested via lines (street axis) of one or more packages, temporary data (not need package-version).'
;

---------
CREATE TABLE ingest.feature_type (  -- replacing old optim.origin_content_type
  ftid smallint PRIMARY KEY NOT NULL,
  ftname text NOT NULL CHECK(lower(ftname)=ftname), -- ftlabel
  geomtype text NOT NULL CHECK(lower(geomtype)=geomtype), -- old model_geo
  need_join boolean, -- false=não, true=sim, null=both (at class).
  description text NOT NULL,
  info jsonb, -- is_useful, score, model_septable, description_pt, description_es, synonymous_pt, synonymous_es
  UNIQUE (ftname)
);
-- DELETE FROM ingest.feature_type;
INSERT INTO ingest.feature_type VALUES
  (0,'address',       'class', null,  'Cadastral address.','{"shortname_pt":"endereço","description_pt":"Endereço cadastral, representação por nome de via e numeração predial.","synonymous_pt":["endereço postal","endereço","planilha dos endereços","cadastro de endereços"]}'::jsonb),
  (1,'address_full',  'none', true,   'Cadastral address (gid,via_id,via_name,number,postal_code,etc), joining with geoaddress_ext by a gid.', NULL),
  (2,'address_cmpl',  'none', true,   'Cadastral address, like address_full with only partial core metadata.', NULL),
  (3,'address_noid',  'none', false,  'Cadastral address with some basic metadata but no standard gid for join with geo).', NULL),

  (10,'cadvia',           'class', null,  'Cadastral via (name of via).', '{"shortname_pt":"logradouro","description_pt":"Via cadastral (nome de via), complemento da geográfica. Logradouro representado por dados cadastrais apenas.","synonymous_pt":["nomes de logradouro","nomes de rua"]}'::jsonb),
  (11,'cadvia_cmpl',      'none', true,   'Cadastral via with metadata complementing via_ext (via_cod,via_name).', NULL),
  (12,'cadvia_noid',      'none', false,   'Via name (and optional metadata) with no ID for join with via_ext.', NULL),

  (20,'geoaddress',         'class', null,  'Geo-address point.', '{"shortname_pt":"endereço","description_pt":"Geo-endereço. Representação geográfica do endereço, como ponto.","synonymous_pt":["geo-endereço","ponto de endereço","endereço georreferenciado","ponto de endereçamento postal"]}'::jsonb),
  (21,'geoaddress_full',    'point', false, 'Geo-address point with all attributes, via_name and number.', NULL),
  (22,'geoaddress_ext',     'point', true,  'Geo-address point with no (or some) metadata, external metadata at address_cmpl or address_full.', NULL),
  (23,'geoaddress_none',    'point', false, 'Geo-address point-only, no metadata (or no core metadata).', NULL),

  (30,'via',           'class', null,  'Via line.', '{"shortname_pt":"eixo de via","description_pt":"Eixo de via. Logradouro representado por linha central, com nome oficial e codlog opcional.","synonymous_pt":["eixo de logradouro","ruas"]}'::jsonb),
  (31,'via_full',       'line', false, 'Via line, with all metadata (official name, optional code and others)', NULL),
  (32,'via_ext',        'line', true,  'Via line, with external metadata at cadvia_cmpl', NULL),
  (33,'via_none',       'line', false, 'Via line with no metadata', NULL),

  (40,'genericvia',           'class', null,  'Generic-via line. Complementar parcel and block divider: railroad, waterway or other.', '{"shortname_pt":"eixo de etc-via","description_pt":"Via complementar generalizada. Qualquer linha divisora de lotes e quadras: rios, ferrovias, etc. Permite gerar a quadra generalizada.","synonymous_pt":["hidrovia","ferrovia","limite de município"]}'::jsonb),
  (41,'genericvia_full',       'line', false, 'Generic-via line, with all metadata (type, official name, optional code and others)', NULL),
  (42,'genericvia_ext',        'line', true,  'Generic-via line, with external metadata', NULL),
  (43,'genericvia_none',       'line', false, 'Generic-via line with no metadata', NULL),

  (50,'building',        'class', null, 'Building polygon.', '{"shortname_pt":"construção","description_pt":"Polígono de edificação.","synonymous_pt":["construções","construção"]}'::jsonb),
  (51,'building_full',   'poly', false, 'Building polygon with all attributes, via_name and number.', NULL),
  (52,'building_ext',    'poly', true,  'Building polygon with no (or some) metadata, external metadata at address_cmpl or address_full.', NULL),
  (53,'building_none',   'poly', false, 'Building polygon-only, no metadata (or no core metadata).', NULL),

  (60,'parcel',        'class', null, 'Parcel polygon (land lot).', '{"shortname_pt":"lote","description_pt":"Polígono de lote.","synonymous_pt":["lote","parcela","terreno"]}'::jsonb),
  (61,'parcel_full',   'poly', false, 'Parcel polygon with all attributes, its main via_name and number.', NULL),
  (62,'parcel_ext',    'poly', true,  'Parcel polygon-only, all metadata external.', NULL),
  (63,'parcel_none',   'poly', false, 'Parcel polygon-only, no metadata.', NULL),

  (70,'nsvia',        'class', null, 'Namespace of vias, a name delimited by a polygon.', '{"shortname_pt":"bairro","description_pt":"Espaço-de-nomes para vias, um nome delimitado por polígono. Tipicamente nome de bairro ou de loteamento. Complementa o nome de via em nomes duplicados (repetidos dentro do mesmo município mas não dentro do mesmo nsvia).","synonymous_pt":["bairro","loteamento"]}'::jsonb),
  (71,'nsvia_full',   'poly', false, 'Namespace of vias polygon with name and optional metadata', NULL),
  (72,'nsvia_ext',    'poly', true,  'Namespace of vias polygon with external metadata', NULL),

  (80,'block',        'class', null, 'Urban block and similar structures, delimited by a polygon.', '{"shortname_pt":"quadra","description_pt":"Quadras ou divisões poligonais similares.","synonymous_pt":["quadra"]}'::jsonb),
  (81,'block_full',   'poly', false, 'Urban block with IDs and all other jurisdiction needs', NULL),
  (82,'block_none',   'poly', false,  'Urban block with no ID', NULL)
;
-- Para a iconografia do site:
-- SELECT f.ftname as "feature type", t.geomtype as "geometry type", f.description from ingest.feature_type f inner JOIN (select  substring(ftname from '^[^_]+') as ftgroup, geomtype  from ingest.feature_type where geomtype!='class' group by 1,2) t ON t.ftgroup=f.ftname ;--where t.geomtype='class';
-- Para gerar backup CSV:
-- copy ( select lpad(ftid::text,2,'0') ftid, ftname, description, info->>'description_pt' as description_pt, array_to_string(jsonb_array_totext(info->'synonymous_pt'),'; ') as synonymous_pt from ingest.feature_type where geomtype='class' ) to '/tmp/pg_io/featur_type_classes.csv' CSV HEADER;
-- copy ( select lpad(ftid::text,2,'0') ftid, ftname,geomtype, iif(need_join,'yes'::text,'no') as need_join, description  from ingest.feature_type where geomtype!='class' ) to '/tmp/pg_io/featur_types.csv' CSV HEADER;

-- DROP TABLE ingest.layer_file;
CREATE TABLE ingest.layer_file (
  file_id serial NOT NULL PRIMARY KEY,
  pck_id real NOT NULL CHECK( digpreserv_packid_isvalid(pck_id) ), -- package file ID, not controled here. Talvez seja packVers (package and version) ou pck_id com real
  pck_fileref_sha256 text NOT NULL CHECK( pck_fileref_sha256 ~ '^[0-9a-f]{64,64}\.[a-z0-9]+$' ),
  ftid smallint NOT NULL REFERENCES ingest.feature_type(ftid),
  file_type text,  -- csv, geojson, shapefile, etc.
  proc_step int DEFAULT 1,  -- current status of the "processing steps", 1=started, 2=loaded, ...=finished
  hash_md5 text NOT NULL, -- or "size-md5" as really unique string
  file_meta jsonb,
  feature_asis_summary jsonb,
  UNIQUE(hash_md5) -- or size-MD5 or (ftid,hash_md5)?  não faz sentido usar duas vezes se existe _full.
);

/* LIXO
CREATE TABLE ingest.feature_asis_report (
  file_id int NOT NULL REFERENCES ingest.layer_file(file_id),
  feature_id int NOT NULL,
  info jsonb,
  UNIQUE(file_id,feature_id)
);
*/

CREATE TABLE ingest.tmp_geojson_feature (
  file_id int NOT NULL REFERENCES ingest.layer_file(file_id),
  feature_id int,
  feature_type text,
  properties jsonb,
  jgeom jsonb,
  UNIQUE(file_id,feature_id)
);

CREATE TABLE ingest.feature_asis (
  file_id int NOT NULL REFERENCES ingest.layer_file(file_id),
  feature_id int NOT NULL,
  properties jsonb,
  geom geometry,
  UNIQUE(file_id,feature_id)
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
           FROM ingest.feature_type c
           WHERE c.geomtype='class' AND c.ftid = 10*round(f.ftid/10)
         ) t2
       ) AS info
  FROM ingest.feature_type f
  WHERE f.geomtype!='class'
;
COMMENT ON VIEW ingest.vw01info_feature_type
  IS 'Adds class_ftname, class_description and class_info to ingest.feature_type.info.'
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

DROP VIEW IF EXISTS ingest.vw03full_layer_file CASCADE;
CREATE VIEW ingest.vw03full_layer_file AS
  SELECT lf.*, ft.ftname, ft.geomtype, ft.need_join, ft.description, ft.info AS ft_info
  FROM ingest.layer_file lf INNER JOIN ingest.vw01info_feature_type ft
    ON lf.ftid=ft.ftid
;

DROP VIEW IF EXISTS ingest.vw04simple_layer_file CASCADE;
CREATE VIEW ingest.vw04simple_layer_file AS
  SELECT file_id, geomtype, proc_step, ftid, ftname, file_type,
         round((file_meta->'size')::int/2014^2) file_mb,
         substr(hash_md5,1,7) as md5_prefix
  FROM ingest.vw03full_layer_file
;

DROP VIEW IF EXISTS ingest.vw05test_feature_asis CASCADE;
CREATE VIEW ingest.vw05test_feature_asis AS
  SELECT v.pck_id, v.ft_info->>'class_ftname' as class_ftname, t.file_id,
         v.file_meta->>'file' as file,
         t.n, t.n_feature_ids,
         CASE WHEN t.n=t.n_feature_ids  THEN 'ok' ELSE '!BUG!' END AS is_ok_msg,
          t.n=t.n_feature_ids AS is_ok
  FROM (
    SELECT file_id, COUNT(*) n, COUNT(DISTINCT feature_id) n_feature_ids
    FROM ingest.feature_asis
    GROUP BY 1
  ) t INNER JOIN ingest.vw03full_layer_file v
    ON v.file_id = t.file_id
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

CREATE or replace FUNCTION ingest.layer_file_geomtype(
  p_file_id integer
) RETURNS text[] AS $f$
  -- ! pendente revisão para o caso shortname multiplingual, aqui usando só 'pt'
  SELECT array[geomtype, ftname, info->>'class_ftname', info->'class_info'->>'shortname_pt']
  FROM ingest.vw01info_feature_type
  WHERE ftid = (
    SELECT ftid
    FROM ingest.layer_file
    WHERE file_id = p_file_id
  )
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.layer_file_geomtype(integer)
  IS '[Geomtype,ftname,class_ftname,shortname_pt] of a layer_file.'
;

CREATE or replace FUNCTION ingest.feature_asis_geohashes(
    p_file_id integer,  -- ID at ingest.layer_file
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
  	 (SELECT (ingest.layer_file_geomtype(p_file_id))[1] AS gtype) t1a
  	WHERE file_id=p_file_id
   ) t2
   GROUP BY 1
   ORDER BY 1
  )
   SELECT jsonb_object_agg( ghs,n )
   FROM scan
$f$ LANGUAGE SQL;

CREATE or replace FUNCTION ingest.feature_asis_assign_volume(
    p_file_id integer,  -- ID at ingest.layer_file
    p_usemedian boolean DEFAULT false
) RETURNS jsonb AS $f$
  WITH get_layer_type AS (SELECT (ingest.layer_file_geomtype(p_file_id))[1] AS gtype)
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
          round( ST_Area(ST_OrientedEnvelope(geom),true)/1000000, 1)::int AS bbox_km2,
          round(size_mdn,3) AS size_mdn
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
    p_file_id integer  -- ID at ingest.layer_file
) RETURNS jsonb AS $f$
  SELECT ingest.feature_asis_assign_volume(p_file_id,true)
    || jsonb_build_object(
        'distribution',
        geohash_distribution_summary( ingest.feature_asis_geohashes(p_file_id,ghs_size), ghs_size, 10, 0.7)
    )
  FROM (
    SELECT CASE WHEN (ingest.layer_file_geomtype(p_file_id))[1]='poly' THEN 5 ELSE 6 END AS ghs_size
  ) t
$f$ LANGUAGE SQL;

CREATE or replace FUNCTION ingest.feature_asis_assign_format(
    p_file_id integer,  -- ID at ingest.layer_file
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
   feature_asis_summary->>'n',
   feature_asis_summary->>'n_unit',
   feature_asis_summary->>'bbox_km2',
   CASE WHEN feature_asis_summary?'size' THEN 'Total size: '||(feature_asis_summary->>'size') ||' '|| (feature_asis_summary->>'size_unit') END,
   geohash_distribution_format(feature_asis_summary->'distribution', true, p_glink|| layerinfo[3] ||'_'),
   pck_fileref_sha256,
   file_type,
   hash_md5,
   file_meta->>'size',
   substr(file_meta->>'modification',1,10)
  ) as htmltabline
  FROM ingest.layer_file, (SELECT ingest.layer_file_geomtype(p_file_id) as layerinfo) t
  WHERE file_id=p_file_id
$f$ LANGUAGE SQL;

CREATE or replace FUNCTION ingest.package_layers_summary(
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
    SELECT ingest.feature_asis_assign_format(file_id, null, '', p_glink) AS trinfo
    FROM ingest.layer_file
    WHERE pck_id=p_pck_id
  ) t
$f$ LANGUAGE SQL;
-- SELECT volat_file_write( '/tmp/pg_io/pk'||floor(pck_id)::text||'readme_table.txt', ingest.package_layers_summary(pck_id)::text ) FROM (select distinct pck_id from ingest.layer_file) t;

-----

CREATE or replace FUNCTION ingest.geojson_load(
  p_file text, -- absolute path and filename, test with '/tmp/pg_io/EXEMPLO3.geojson'
  p_ftid int,  -- REFERENCES ingest.feature_type(ftid)
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

  INSERT INTO ingest.layer_file(p_pck_id,ftid,file_type,file_meta,pck_fileref_sha256)
     SELECT p_pck_id, p_ftid::smallint,
            COALESCE( p_ftype, substring(p_file from '[^\.]+$') ),
            geojson_readfile_headers(p_file),
            p_pck_fileref_sha256
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
  p_pck_id real,
  p_pck_fileref_sha256 text,
  p_ftype text DEFAULT NULL
  -- proc_step = 1
  -- ,p_size_min int DEFAULT 5
) RETURNS int AS $f$
-- with ... check
 WITH filedata AS (
   SELECT p_pck_id, p_ftid, ftype,
          CASE
            WHEN (fmeta->'size')::int<5 OR (fmeta->>'hash_md5')='' THEN NULL --guard
            ELSE fmeta->>'hash_md5'
          END AS hash_md5,
          (fmeta - 'hash_md5') AS fmeta
   FROM (
       SELECT COALESCE( p_ftype, lower(substring(p_file from '[^\.]+$')) ) as ftype,
          jsonb_pg_stat_file(p_file,true) as fmeta
   ) t
 ),
  file_exists AS (
    SELECT file_id,proc_step
    FROM ingest.layer_file
    WHERE pck_id=p_pck_id AND hash_md5=(SELECT hash_md5 FROM filedata)
  ), ins AS (
   INSERT INTO ingest.layer_file(pck_id,ftid,file_type,hash_md5,file_meta,pck_fileref_sha256)
      SELECT *, p_pck_fileref_sha256 FROM filedata
   ON CONFLICT DO NOTHING
   RETURNING file_id
  )
  SELECT file_id FROM (
      SELECT file_id, 1 as proc_step FROM ins
      UNION ALL
      SELECT file_id, proc_step      FROM file_exists
  ) t WHERE proc_step=1
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.getmeta_to_file(text,int,real,text,text)
  IS 'Reads file metadata and inserts it into ingest.layer_file. If proc_step=1 returns valid ID else NULL.'
;
CREATE or replace FUNCTION ingest.getmeta_to_file(
  p_file text,   -- 1.
  p_ftname text, -- 2. define o layer... um file pode ter mais de um layer??
  p_pck_id real,
  p_pck_fileref_sha256 text,
  p_ftype text DEFAULT NULL -- 5
) RETURNS int AS $wrap$
    SELECT ingest.getmeta_to_file(
      $1,
      (SELECT ftid::int FROM ingest.feature_type WHERE ftname=lower($2)),
      $3, $4, $5
    );
$wrap$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.getmeta_to_file(text,text,real,text,text)
  IS 'Wrap para ingest.getmeta_to_file() usando ftName ao invés de ftID.'
;
-- ex. select ingest.getmeta_to_file('/tmp/a.csv',3,555);
-- ex. select ingest.getmeta_to_file('/tmp/b.shp','geoaddress_full',555);

/* ver VIEW
CREATE or replace FUNCTION ingest.feature_type_refclass_tab(
  p_ftid integer
) RETURNS TABLE (like ingest.feature_type) AS $f$
  SELECT *
  FROM ingest.feature_type
  WHERE ftid = 10*round(p_ftid/10)
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.feature_type_refclass_tab(integer)
  IS 'Feature class of a feature_type, returing it as table.'
;
CREATE or replace FUNCTION ingest.feature_type_refclass_jsonb(
  p_ftid integer
) RETURNS JSONB AS $wrap$
  SELECT to_jsonb(t)
  FROM ingest.feature_type_refclass_tab($1) t
$wrap$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.feature_type_refclass_jsonb(integer)
  IS 'Feature class of a feature_type, returing it as JSONb.'
;
*/

CREATE or replace FUNCTION ingest.any_load_debug(
  p_method text,   -- 1.; shp/csv/etc.
  p_fileref text,  -- apenas referencia para ingest.layer_file
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


CREATE or replace FUNCTION ingest.any_load(
    p_method text,   -- shp/csv/etc.
    p_fileref text,  -- apenas referencia para ingest.layer_file
    p_ftname text,   -- featureType of layer... um file pode ter mais de um layer??
    p_tabname text,  -- tabela temporária de ingestáo
    p_pck_id real,   -- id do package da Preservação.
    p_pck_fileref_sha256 text,
    p_tabcols text[] DEFAULT NULL, -- array[]=tudo, senão lista de atributos de p_tabname, ou só geometria
    p_geom_name text DEFAULT 'geom',
    p_to4326 boolean DEFAULT true -- on true converts SRID to 4326 .
) RETURNS text AS $f$
  DECLARE
    q_file_id integer;
    q_query text;
    feature_id_col text;
    use_tabcols boolean;
    msg_ret text;
    num_items bigint;
  BEGIN
  IF p_method='csv2sql' THEN
    p_fileref := p_fileref || '.csv';
    -- other checks
  ELSE
    p_fileref := p_fileref || '.shp';
  END IF;
  q_file_id := ingest.getmeta_to_file(p_fileref,p_ftname,p_pck_id,p_pck_fileref_sha256); -- not null when proc_step=1. Ideal retornar array.
  IF q_file_id IS NULL THEN
    RETURN format('ERROR: file-read problem or data ingested before, see %s.',p_fileref);
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
        SELECT %s, gid, properties,
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
      ins AS (
        INSERT INTO ingest.feature_asis
           SELECT *
           FROM scan WHERE geom IS NOT NULL AND ST_IsValid(geom)
        RETURNING 1
      )
      SELECT COUNT(*) FROM ins
    $$,
    q_file_id,
    iif(p_to4326,'true'::text,'false'),  -- decide ST_Transform
    feature_id_col,
    iIF( use_tabcols, 'to_jsonb(subq)'::text, E'\'{}\'::jsonb' ), -- properties
    CASE WHEN lower(p_geom_name)='geom' THEN 'geom' ELSE p_geom_name||' AS geom' END,
    p_tabname,
    iIF( use_tabcols, ', LATERAL (SELECT '|| array_to_string(p_tabcols,',') ||') subq',  ''::text )
  );
  EXECUTE q_query INTO num_items;
  msg_ret := format(
    E'From file_id=%s inserted type=%s\nin feature_asis %s items.',
    q_file_id, p_ftname, num_items
  );
  IF num_items>0 THEN
    UPDATE ingest.layer_file
    SET proc_step=2,   -- if insert process occurs after q_query.
        feature_asis_summary= ingest.feature_asis_assign(q_file_id)
    WHERE file_id=q_file_id;
  END IF;
  RETURN msg_ret;
  END;
$f$ LANGUAGE PLpgSQL;
COMMENT ON FUNCTION ingest.any_load(text,text,text,text,real,text,text[],text,boolean)
  IS 'Load (into ingest.feature_asis) shapefile or any other non-GeoJSON, of a separated table.'
;
-- posto ipiranga logo abaixo..  sorvetorua.
-- ex. SELECT ingest.any_load('/tmp/pg_io/NRO_IMOVEL.shp','geoaddress_none','pk027_geoaddress1',27,array['gid','textstring']);

CREATE or replace FUNCTION ingest.any_load(
    p_method text,   -- 1.  shp/csv/etc.
    p_fileref text,  -- 2. apenas referencia para ingest.layer_file
    p_ftname text,   -- 3. featureType of layer... um file pode ter mais de um layer??
    p_tabname text,  -- 4. tabela temporária de ingestáo
    p_pck_id text,   -- 5. id do package da Preservação no formato "a.b".
    p_pck_fileref_sha256 text,   -- 6
    p_tabcols text[] DEFAULT NULL,   -- 7. lista de atributos, ou só geometria
    p_geom_name text DEFAULT 'geom', -- 8
    p_to4326 boolean DEFAULT true    -- 9. on true converts SRID to 4326 .
) RETURNS text AS $wrap$
   SELECT ingest.any_load($1, $2, $3, $4, digpreserv_packid_to_real($5), $6, $7, $8, $9)
$wrap$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest.any_load(text,text,text,text,text,text,text[],text,boolean)
  IS 'Wrap to ingest.any_load(1,2,3,4=real) using string format DD_DD.'
;

-----
CREATE or replace FUNCTION ingest.qgis_vwadmin_feature_asis(
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
      ,digpreserv_packid_to_str(pck_id,true)
      ,file_id
      ,feature_asis_summary->>'n_unit'
      ,file_id
    ), E' \n' )
    INTO q_query
    FROM ingest.layer_file;
    EXECUTE q_query;
    RETURN E'\n(check before NO BUGs with SELECT * FROM ingest.vw05test_feature_asis)\n---\nok! all '||p_mode||E'\nCheck on psql by \\dv vw_asis_*';
  END;
$f$ LANGUAGE PLpgSQL;
-- select ingest.qgis_vwadmin_feature_asis('create');
----

CREATE or replace FUNCTION ingest.layer_file_distribution_prefixes(
  p_file_id int
) RETURNS text[] AS $f$
  SELECT array_agg(p ORDER BY length(p) desc, p) FROM (
    SELECT jsonb_object_keys(feature_asis_summary->'distribution') p
    FROM ingest.layer_file WHERE file_id=p_file_id
  ) t
$f$ LANGUAGE SQL;
-- for use with geohash_checkprefix()
-- select file_id, ingest.layer_file_distribution_prefixes(file_id)as prefixes FROM ingest.layer_file


------------------------
------------------------


CREATE or replace FUNCTION ingest.feature_asis_export(p_file_id int)
RETURNS TABLE (ghs9 text, gid int, info jsonb, geom geometry(Point,4326)) AS $f$
 SELECT ghs, gid,
    CASE
      WHEN n=1 THEN jsonb_build_object('address',addresses[1])
      WHEN n>1 AND cardinality(via_names)=1 THEN
        jsonb_build_object('via_name',via_names[1], 'house_numbers',to_jsonb(house_numbers))
      ELSE jsonb_build_object('addresses',addresses)
    END as info,
    CASE n WHEN 1 THEN geoms[1] ELSE ST_Centroid(ST_Collect(geoms)) END AS geom
 FROM (
  SELECT ghs,
   MIN(row_id)::int as gid,
   COUNT(*) n,
   array_agg(geom) as geoms,
   array_agg(DISTINCT via_name||', '||house_number) addresses,
   array_agg(DISTINCT via_name) via_names,
   array_agg(DISTINCT house_number) house_numbers,
   max(DISTINCT is_compl::text)::boolean house_numbers_has_complement
  FROM (
     SELECT file_id, geom,
       ROW_NUMBER() OVER(ORDER BY  properties->>'via_name', to_integer(properties->>'house_number')) as row_id,
       COALESCE(nullif(properties->'is_complemento_provavel','null')::boolean,false) as is_compl,
       properties->>'via_name' as via_name,
       properties->>'house_number' as house_number,
       st_geohash(geom,9) ghs
    FROM ingest.feature_asis
    WHERE file_id=p_file_id
  ) t1
  GROUP BY 1
 ) t2
 WHERE cardinality(via_names)<3
 ORDER BY gid
$f$ LANGUAGE SQL IMMUTABLE;
-- SELECT * FROM ingest.feature_asis_export(1) t LIMIT 1000;

-- ----------------------------


DROP FOREIGN TABLE IF EXISTS foreign_osm_city;
CREATE FOREIGN TABLE foreign_osm_city (
 osm_id          bigint,
 jurisd_base_id  integer,
 jurisd_local_id integer,
 name            text,
 parent_abbrev   text,
 abbrev          text,
 wikidata_id     bigint,
 lexlabel        text,
 isolabel_ext    text,
 ddd             integer,
 info            jsonb,
 jtags           jsonb,
 geom            geometry(Geometry,4326)
) SERVER foreign_server
  OPTIONS (schema_name 'public', table_name 'osm_city')
;
DROP TABLE IF EXISTS ingest.publicating_geojsons_p3exprefix;
CREATE TABLE ingest.publicating_geojsons_p3exprefix(
 ghs9   text,
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

CREATE or replace FUNCTION ingest.publicating_geojsons(
	p_file_id       int,  -- e.g. 1, see ingest.layer_file
	p_isolabel_ext  text  -- e.g. 'BR-MG-BeloHorizonte', see osm_city
) RETURNS text  AS $f$

  DELETE FROM ingest.publicating_geojsons_p3exprefix;
  INSERT INTO ingest.publicating_geojsons_p3exprefix
     SELECT ghs9, NULL::text, gid, info, geom
     FROM ingest.feature_asis_export(p_file_id) t
  ;
  -- COMMIT1 INSERT
  UPDATE ingest.layer_file
  SET feature_distrib = geocode_distribution_generate('ingest.publicating_geojsons_p3exprefix',7)
  WHERE file_id= p_file_id
  ;
  DELETE FROM ingest.publicating_geojsons_p2distrib;
  INSERT INTO ingest.publicating_geojsons_p2distrib
    SELECT t.hcode, t.n_items,  -- length(t.hcode) AS len,
      ST_Intersection(
        ST_SetSRID( ST_geomFromGeohash(replace(t.hcode, '*', '')) ,  4326),
        (SELECT geom FROM foreign_osm_city WHERE isolabel_ext=p_isolabel_ext)
      ) AS geom
    FROM hcode_distribution_reduce_recursive_raw(
    	(SELECT feature_distrib FROM ingest.layer_file WHERE file_id= p_file_id),
    	1,
    	(SELECT length(st_geohash(geom)) FROM foreign_osm_city WHERE isolabel_ext=p_isolabel_ext),
    	750, 8000, 3
    ) t
  ;
  SELECT pg_catalog.pg_file_unlink('/tmp/pg_io/pts_*.geojson');

  UPDATE ingest.publicating_geojsons_p3exprefix
  SET prefix=t4.prefix
  FROM (
    WITH t1 (prefix_regex) as (
     SELECT hcode_prefixset_parse( array_agg(hcode) )
     FROM ingest.publicating_geojsons_p2distrib
    )
      SELECT hcode_prefixset_element(t.ghs9,'^(?:'|| t1.prefix_regex ||')') AS prefix, t.gid
      FROM ingest.publicating_geojsons_p3exprefix t, t1
  ) t4
  WHERE t4.gid = publicating_geojsons_p3exprefix.gid
  ;
  DELETE FROM ingest.publicating_geojsons_p2distrib; -- limpa
  -- COMMIT2

  WITH prefs AS ( SELECT DISTINCT prefix FROM ingest.publicating_geojsons_p3exprefix ORDER BY 1 )
   SELECT write_geojsonb_Features(
    format('SELECT * FROM ingest.publicating_geojsons_p3exprefix WHERE prefix=%L ORDER BY gid',prefix),
    format('/tmp/pg_io/pts_%s.geojson',prefix),
    't1.geom',
    'info::jsonb',
    NULL,  -- p_cols_orderby
    NULL, -- col_id
    2
  ) FROM prefs;
  DELETE FROM ingest.publicating_geojsons_p3exprefix;  -- limpa
  SELECT 'Arquivos de file_id='||p_file_id::text|| ' publicados em /tmp/pg_io/pts_*.geojson';

$f$ language SQL VOLATILE;
-- e.g. select ingest.publicating_geojsons(1, 'BR-MG-BeloHorizonte');

--------------------
--------------------
-- OSM lib


create extension IF NOT EXISTS hstore;     -- to make osm
create extension IF NOT EXISTS unaccent;   -- to normalize
create schema    IF NOT EXISTS lib;  -- lib geral, que não é public mas pode fazer drop/create sem medo.

CREATE or replace FUNCTION lib.osm_to_jsonb_remove() RETURNS text[] AS $f$
   SELECT array['osm_uid','osm_user','osm_version','osm_changeset','osm_timestamp'];
$f$ LANGUAGE SQL IMMUTABLE;

CREATE or replace FUNCTION lib.osm_to_jsonb(
  p_input text[], p_strip boolean DEFAULT false
) RETURNS jsonb AS $f$
  SELECT CASE WHEN p_strip THEN jsonb_strip_nulls(x,true) ELSE x END
  FROM (
    SELECT jsonb_object($1) - lib.osm_to_jsonb_remove()
  ) t(x)
$f$ LANGUAGE sql IMMUTABLE;

CREATE or replace FUNCTION lib.osm_to_jsonb(
  p_input public.hstore, p_strip boolean DEFAULT false
) RETURNS jsonb AS $f$
  SELECT CASE WHEN p_strip THEN jsonb_strip_nulls(x,true) ELSE x END
  FROM (
    SELECT hstore_to_jsonb_loose($1) - lib.osm_to_jsonb_remove()
  ) t(x)
$f$ LANGUAGE sql IMMUTABLE;

CREATE or replace FUNCTION lib.name2lex_pre(
  p_name       text                  -- 1
  ,p_normalize boolean DEFAULT true  -- 2
  ,p_cut       boolean DEFAULT true  -- 3
  ,p_unaccent  boolean DEFAULT false -- 4
) RETURNS text AS $f$
   SELECT
      CASE WHEN p_unaccent THEN lower(unaccent(x)) ELSE x END
   FROM (
     -- old    SELECT CASE WHEN p_normalize THEN stable.normalizeterm2($1,p_cut) ELSE $1 END
     SELECT CASE WHEN p_normalize THEN $1 ELSE $1 END
    ) t(x)
$f$ LANGUAGE SQL IMMUTABLE;


CREATE or replace FUNCTION lib.name2lex(
  p_name       text                  -- 1
  ,p_normalize boolean DEFAULT true  -- 2
  ,p_cut       boolean DEFAULT true  -- 3
  ,p_flag      boolean DEFAULT false -- 4
) RETURNS text AS $f$
  SELECT trim(replace(
    regexp_replace(
      lib.name2lex_pre($1,$2,$3,$4),
      E' d[aeo] | d[oa]s | com | para |^d[aeo] | / .+| [aeo]s | [aeo] |\-d\'| d\'|[\-\' ]',
      '.',
      'g'
    ),
    '..',
    '.'
  ),'.')
$f$ LANGUAGE SQL IMMUTABLE;


























CREATE extension IF NOT EXISTS plpython3u;
-- SELECT * FROM pg_language;

CREATE OR REPLACE FUNCTION ingest.py3_return_version() RETURNS text AS $$
    import sys

    return sys.version
$$ LANGUAGE plpython3u;
-- SELECT * FROM ingest.py3_return_version();

CREATE OR REPLACE FUNCTION ingest.lixo_chevron_test() RETURNS text AS $$
  import chevron

  return chevron.render('Hello, {{ mustache }}!', {'mustache': 'World'})
$$ LANGUAGE plpython3u;
-- SELECT ingest.lixo_chevron_test();

CREATE OR REPLACE FUNCTION ingest.mustache_render(tpl text,i jsonb, partials_path text) RETURNS text AS $$
  import chevron
  import json
  
  j = json.loads(i)

  return chevron.render(tpl,j,partials_path)
$$ LANGUAGE plpython3u IMMUTABLE;
-- SELECT ingest.mustache_render('Hello, {{ mustache }}!', '{"mustache":"World"}'::jsonb, '');

CREATE OR REPLACE FUNCTION ingest.yaml2jsonb(file text) RETURNS jsonb AS $$
    import yaml
    import json

    query = "SELECT pg_read_file('{}')".format(file)

    result_query = plpy.execute(query)

    dict = yaml.safe_load(result_query[0]['pg_read_file'])

    jsonb = json.dumps(dict)

    return jsonb
$$ LANGUAGE plpython3u IMMUTABLE;
-- SELECT ingest.yaml2jsonb('/opt/gits/_dg/preserv-BR/data/RJ/Niteroi/_pk018/make_conf.yaml');

CREATE OR REPLACE FUNCTION ingest.make_conf_yaml2jsonb(file text) RETURNS jsonb AS $$
    import yaml
    import json

    query = "SELECT pg_read_file('{}')".format(file)

    result_query = plpy.execute(query)

    dict = yaml.safe_load(result_query[0]['pg_read_file'])

    if 'layers' in dict:
        dict['layers_keys'] = [*dict['layers'].keys()]

        dict['joins'] = {}

        # flags que indicam tipo de method
        for key in dict['layers'].keys():
            dict['layers'][key]['isCsv'] = False
            dict['layers'][key]['isOgr'] = False
            dict['layers'][key]['isOgrWithShp'] = False
            dict['layers'][key]['isShp'] = False

            if dict['layers'][key]['method'] == 'shp2sql':
                dict['layers'][key]['isShp'] = True
            elif dict['layers'][key]['method'] == 'csv2sql':
                dict['layers'][key]['isCsv'] = True
            elif dict['layers'][key]['method'] == 'ogr2ogr':
                dict['layers'][key]['isOgr'] = True
            elif dict['layers'][key]['method'] == 'ogrWshp':
                dict['layers'][key]['isOgrWithShp'] = True

            if key in dict['layers'] and 'cad' + key in dict['layers']:
                if dict['layers'][key]['subtype'] == 'ext' and dict['layers']['cad' + key]['subtype'] == 'cmpl':
                    if dict['layers'][key]['join_column'] and dict['layers']['cad' + key]['join_column']:
                        dict['joins'][key] = {}
                        dict['joins'][key]['layer'] = key + '_ext'
                        dict['joins'][key]['cadLayer'] = 'cad' + key + '_cmpl'
                        dict['joins'][key]['layerColumn'] = dict['layers'][key]['join_column']
                        dict['joins'][key]['cadLayerColumn'] = dict['layers']['cad' + key]['join_column']
                        dict['joins'][key]['layerFile'] = [x['file'] for x in dict['files'] if x['p'] == dict['layers'][key]['file']][0]
                        dict['joins'][key]['cadLayerFile'] = [x['file'] for x in dict['files'] if x['p'] == dict['layers']['cad' + key]['file']][0]


            if key == 'geoaddress' and 'address' in dict['layers']:
                if dict['layers'][key]['subtype'] == 'ext' and dict['layers']['address']['subtype'] == 'cmpl':
                    if dict['layers'][key]['join_column'] and dict['layers']['address']['join_column']:
                        dict['joins'][key] = {}
                        dict['joins'][key]['layer'] = key + '_ext'
                        dict['joins'][key]['cadLayer'] = 'address' + '_cmpl'
                        dict['joins'][key]['layerColumn'] = dict['layers'][key]['join_column']
                        dict['joins'][key]['cadLayerColumn'] = dict['layers']['address']['join_column']
                        dict['joins'][key]['layerFile'] = [x['file'] for x in dict['files'] if x['p'] == dict['layers'][key]['file']][0]
                        dict['joins'][key]['cadLayerFile'] = [x['file'] for x in dict['files'] if x['p'] == dict['layers']['address']['file']][0]

        dict['joins_keys'] = [*dict['joins'].keys()]

    jsonb = json.dumps(dict)

    return jsonb
$$ LANGUAGE plpython3u IMMUTABLE;
-- SELECT ingest.make_conf_yaml2jsonb('/opt/gits/_dg/preserv-BR/data/RJ/Niteroi/_pk018/make_conf.yaml');

CREATE OR REPLACE FUNCTION ingest.generate_makefile(
    baseSrc text,
    mkme_srcTpl text,
    mkme_srcTplLast text,
    mkme_yamlFirst text,
    mkme_yaml text
) RETURNS text AS $f$
    DECLARE
        q_query text;
    BEGIN

    WITH tpl AS (
    SELECT pg_read_file(mkme_srcTpl) || pg_read_file(mkme_srcTplLast)
    ),
    conf_yaml AS (
    SELECT yaml2jsonb(mkme_yamlFirst) || make_conf_yaml2jsonb(mkme_yaml)
    )
    
    SELECT mustache_render((SELECT * FROM tpl), (SELECT * FROM conf_yaml), concat(baseSrc,'preserv/src/maketemplates/')) INTO q_query;
 
    RETURN q_query;
    END;
$f$ LANGUAGE PLpgSQL;
-- SELECT ingest.generate_makefile('/opt/gits/_dg/','/opt/gits/_dg/preserv/src/maketemplates/make_ref027a.mustache.mk','/opt/gits/_dg/preserv-BR/src/maketemplates/commomLast.mustache.mk','/opt/gits/_dg/preserv-BR/src/maketemplates/commomFirst.yaml','/opt/gits/_dg/preserv-BR/data/RJ/Niteroi/_pk018/make_conf.yaml');

-- psql postgres://postgres@localhost/ingest1 -t -c "SELECT ingest.generate_makefile('/opt/gits/_dg/','/opt/gits/_dg/preserv/src/maketemplates/make_ref027a.mustache.mk','/opt/gits/_dg/preserv-BR/src/maketemplates/commomLast.mustache.mk','/opt/gits/_dg/preserv-BR/src/maketemplates/commomFirst.yaml','/opt/gits/_dg/preserv-BR/data/RJ/Niteroi/_pk018/make_conf.yaml')";

CREATE OR REPLACE FUNCTION ingest.generate_readme(
    baseSrc text,
    readme_srcTpl text,
    mkme_yaml text
) RETURNS text AS $f$
    DECLARE
        q_query text;
    BEGIN

    WITH tpl AS (
    SELECT pg_read_file(readme_srcTpl)
    ),
    conf_yaml AS (
    SELECT make_conf_yaml2jsonb(mkme_yaml)
    )
    
    SELECT mustache_render((SELECT * FROM tpl), (SELECT * FROM conf_yaml), concat(baseSrc,'preserv/src/maketemplates/')) INTO q_query;
 
    RETURN q_query;
    END;
$f$ LANGUAGE PLpgSQL;
-- SELECT ingest.generate_readme('/opt/gits/_dg/','/opt/gits/_dg/preserv-BR/src/maketemplates/readme.mustache','/opt/gits/_dg/preserv-BR/data/RJ/Niteroi/_pk018/make_conf.yaml');

-- psql postgres://postgres@localhost/ingest1 -t -c "SELECT ingest.generate_readme('/opt/gits/_dg/','/opt/gits/_dg/preserv-BR/src/maketemplates/readme.mustache','/opt/gits/_dg/preserv-BR/data/RJ/Niteroi/_pk018/make_conf.yaml')";
