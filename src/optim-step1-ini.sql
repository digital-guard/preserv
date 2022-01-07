CREATE SCHEMA    IF NOT EXISTS optim;
CREATE SCHEMA    IF NOT EXISTS tmp_orig;

CREATE EXTENSION IF NOT EXISTS file_fdw;
CREATE SERVER    IF NOT EXISTS files FOREIGN DATA WRAPPER file_fdw;

------------------------

CREATE TABLE IF NOT EXISTS optim.jurisdiction ( -- only current
  -- need a view vw01current_jurisdiction to avoid the lost of non-current.
  -- https://schema.org/AdministrativeArea or https://schema.org/jurisdiction ?
  -- OSM use AdminLevel, etc. but LexML uses Jurisdiction.
  osm_id bigint PRIMARY KEY,    -- official or adapted geometry. AdministrativeArea.
  jurisd_base_id int NOT NULL,  -- ISO3166-1-numeric COUNTRY ID (e.g. Brazil is 76) or negative for non-iso (ex. oceans)
  jurisd_local_id int   NOT NULL, -- numeric official ID like IBGE_ID of BR jurisdiction.
  -- for example BR's ACRE is 12 and its cities are {1200013, 1200054,etc}.
  parent_id bigint REFERENCES optim.jurisdiction(osm_id), -- null for INT.
  admin_level smallint NOT NULL CHECK(admin_level>0 AND admin_level<100), -- 2=country (e.g. BR), at BR: 4=UFs, 8=municipios.
  name    text  NOT NULL CHECK(length(name)<60), -- city name for admin_level=8.
  parent_abbrev   text  NOT NULL, -- state is admin-level2, country level1
  abbrev text  CHECK(length(abbrev)>=2 AND length(abbrev)<=5), -- ISO and other abbreviations
  wikidata_id  bigint,  --  from '^Q\d+'
  lexlabel     text NOT NULL,  -- cache from name; e.g. 'sao.paulo'.
  isolabel_ext text NOT NULL,  -- cache from parent_abbrev (ISO) and name (camel case); e.g. 'BR-SP-SaoPaulo'.
  ddd          integer, -- Direct distance dialing
  housenumber_system_type text, -- housenumber system
  lex_urn text, -- housenumber system law
  info JSONb -- creation, extinction, postalCode_ranges, notes, etc.
  ,UNIQUE(isolabel_ext)
  ,UNIQUE(wikidata_id)
  ,UNIQUE(jurisd_base_id,jurisd_local_id)
  ,UNIQUE(jurisd_base_id,parent_abbrev,name) -- parent-abbrev é null ou cumulativo
  ,UNIQUE(jurisd_base_id,parent_abbrev,lexlabel)
  ,UNIQUE(jurisd_base_id,parent_abbrev,abbrev)
);

CREATE TABLE optim.auth_user (
  -- authorized users to be a datapack responsible and eclusa-FTP manager
  username text NOT NULL PRIMARY KEY,
  info jsonb
);
INSERT INTO optim.auth_user(username) VALUES ('carlos'),('igor'),('enio'),('peter'); -- minimal one Linux's /home/username

CREATE TABLE optim.donor (
  id integer NOT NULL PRIMARY KEY CHECK (id = country_id*1000000+local_serial),  -- by trigger!
  country_id int NOT NULL CHECK(country_id>0), -- ISO
  local_serial  int NOT NULL CHECK(local_serial>0), -- byu contry
  scope text, -- city code or country code
  shortname text, -- abreviation or acronym (local)
  vat_id text,    -- in the Brazilian case is "CNPJ:number"
  legalName text NOT NULL, -- in the Brazilian case is Razao Social
  wikidata_id bigint,  -- without "Q" prefix
  url text,     -- official home page of the organization
  info JSONb,   -- all other information using controlled keys
  kx_vat_id text,    -- cache for normalized vat_id
  UNIQUE(country_id,local_serial),
  UNIQUE(country_id,kx_vat_id),
  UNIQUE(country_id,legalName),
  UNIQUE(country_id,scope,shortname)
);

CREATE TABLE optim.donated_PackTpl(
   -- donated pack template, Pacote não-versionado, apenas controle de pack_id e registro da entrada. Só metadados comuns às versões.
  id bigint NOT NULL PRIMARY KEY CHECK (id = donor_id::bigint*100::bigint + pk_count::bigint),  -- by trigger!
  donor_id int NOT NULL REFERENCES optim.donor(id),
  user_resp text NOT NULL REFERENCES optim.auth_user(username), -- responsável pelo README e teste do makefile
  pk_count int  NOT NULL CHECK(pk_count>0),
  original_tpl text NOT NULL, -- cópia de segurança do make_conf.yaml trocando "version" e "file" por placeholder mustache.
  make_conf_tpl JSONb,  -- cache, resultado de parsing do original_tpl (YAML) para JSON
  kx_num_files int, -- cache para  jsonb_array_length(make_conf_tpl->files).
  info JSONb, -- uso futuro caso necessário.
  UNIQUE(donor_id,pk_count)
);  -- cada file de  make_conf_tpl->files  resulta em um registro optim.donated_PackFileVers

CREATE TABLE optim.donated_PackFileVers(
  -- armazena histórico de versões, requer VIEW contendo apenas registros de MAX(pack_item_accepted_date).
  id bigint NOT NULL PRIMARY KEY  CHECK(id=pack_id*1000000000+pack_item*100+kx_pack_item_version),  -- by trigger!
  hashedfname text NOT NULL  CHECK( hashedfname ~ '^[0-9a-f]{64,64}\.[a-z0-9]+$' ), -- formato "sha256.ext". Hashed filename. Futuro "size~sha256"
  pack_id bigint NOT NULL REFERENCES optim.donated_PackTpl(id),
  pack_item int NOT NULL DEFAULT 1, --  um dos make_conf_tpl->files->file de pack_id
  pack_item_accepted_date date NOT NULL, --  data tipo ano-mês-01, mês da homologação da doação
  kx_pack_item_version int NOT NULL DEFAULT 1, --  versão (serial) correspondente à pack_item_accepted_date. Trigguer: next value.
  user_resp text NOT NULL REFERENCES optim.auth_user(username), -- responsável pela ingestão do arquivo (testemunho)
  -- escopo text NOT NULL, -- bbox or minimum bounding AdministrativeArea
  -- license?  tirar do info e trazer para REFERENCES licenças.
  --- about text,
  info jsonb  -- livre
  ,UNIQUE(hashedfname)
  ,UNIQUE(pack_id,pack_item,pack_item_accepted_date)
  ,UNIQUE(pack_id,pack_item,kx_pack_item_version) -- revisar se precisa.
);
-------

---------
CREATE TABLE optim.feature_type (  -- replacing old optim.origin_content_type
  ftid smallint PRIMARY KEY NOT NULL,
  ftname text NOT NULL CHECK(lower(ftname)=ftname), -- ftlabel
  geomtype text NOT NULL CHECK(lower(geomtype)=geomtype), -- old model_geo
  need_join boolean, -- false=não, true=sim, null=both (at class).
  description text NOT NULL,
  info jsonb, -- is_useful, score, model_septable, description_pt, description_es, synonymous_pt, synonymous_es
  UNIQUE (ftname)
);
-- DELETE FROM optim.feature_type;
INSERT INTO optim.feature_type VALUES
  (0,'address',       'class', null,  'Cadastral address.','{"shortname_pt":"endereço","description_pt":"Endereço cadastral, representação por nome de via e numeração predial.","synonymous_pt":["endereço postal","endereço","planilha dos endereços","cadastro de endereços"]}'::jsonb),
  --(1,'address_full',  'none', true,   'Cadastral address (gid,via_id,via_name,number,postal_code,etc), joining with geoaddress_ext by a gid.', NULL),
  (1,'address_cmpl',  'none', true,   'Cadastral address, like address_full with only partial core metadata.', NULL),
  (2,'address_noid',  'none', false,  'Cadastral address with some basic metadata but no standard gid for join with geo).', NULL),

  (5,'cadparcel',           'class', null,  'Cadastral parcel (name of parcel).', '{"shortname_pt":"lote","description_pt":"Lote cadastral (nome de parcel), complemento da geográfica. Lote representado por dados cadastrais apenas.","synonymous_pt":["terreno","parcela"]}'::jsonb),
  (6,'cadparcel_cmpl',      'none', true,   'Cadastral parcel with metadata complementing parcel_ext (parcel_cod,parcel_name).', NULL),
  (7,'cadparcel_noid',      'none', false,   'Parcel name (and optional metadata) with no ID for join with parcel_ext.', NULL),

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
  (42,'genericvia_ext',        'line', true,  'Generic-via line, with external metadata at cadgenericvia_cmpl', NULL),
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
  (73,'nsvia_none',   'poly', true,  'Namespace of vias polygon-only, no metadata', NULL),
  -- renomear para 'namedArea'

  (80,'block',        'class', null, 'Urban block and similar structures, delimited by a polygon.', '{"shortname_pt":"quadra","description_pt":"Quadras ou divisões poligonais similares.","synonymous_pt":["quadra"]}'::jsonb),
  (81,'block_full',   'poly', false, 'Urban block with IDs and all other jurisdiction needs', NULL),
  (82,'block_none',   'poly', false,  'Urban block with no ID', NULL)
;
-- Para a iconografia do site:
-- SELECT f.ftname as "feature type", t.geomtype as "geometry type", f.description from optim.feature_type f inner JOIN (select  substring(ftname from '^[^_]+') as ftgroup, geomtype  from optim.feature_type where geomtype!='class' group by 1,2) t ON t.ftgroup=f.ftname ;--where t.geomtype='class';
-- Para gerar backup CSV:
-- copy ( select lpad(ftid::text,2,'0') ftid, ftname, description, info->>'description_pt' as description_pt, array_to_string(jsonb_array_totext(info->'synonymous_pt'),'; ') as synonymous_pt from optim.feature_type where geomtype='class' ) to '/tmp/pg_io/featur_type_classes.csv' CSV HEADER;
-- copy ( select lpad(ftid::text,2,'0') ftid, ftname,geomtype, iif(need_join,'yes'::text,'no') as need_join, description  from optim.feature_type where geomtype!='class' ) to '/tmp/pg_io/featur_types.csv' CSV HEADER;

CREATE TABLE optim.housenumber_system_type (
  hstid smallint PRIMARY KEY NOT NULL,
  hstname text NOT NULL CHECK(lower(hstname)=hstname), -- hslabel
  regex_sort text NOT NULL,
  description text NOT NULL,
  UNIQUE (hstid)
);
INSERT INTO optim.housenumber_system_type VALUES
  (0,'metric',        '[0-9]+ integer',                        $$Distance in meters from city's origin (or similar mark). Example: BR-SP-PIR housenumbers [123, 4560].$$),
  (1,'street-metric', '[0-9]+[A-Z]? \- [0-9]+ [SNEL]? string', 'First code refers to the previous intersecting street, and the second is the distance to that intersection. Optional last letter is sort-direction. Example: CO-DC-Bogota housenumbers [96A -11, 12 - 34, 14A - 31 E].'),
  (2,'block-metric',  '[0-9]+ \- [0-9]+ integer function',     $$First number refers to the urban-block counter, and the second is the distance to the begin of the block in the city's origin order. Sort function is $1*10000 + $2. Example: BR-SP-Bauru housenumbers [30-14, 2-1890].$$)
;

--------
CREATE TABLE optim.donated_PackComponent(
  -- Tabela similar a ingest.layer_file, armazena sumários descritivos de cada layer. Equivale a um subfile do hashedfname.
  id bigserial NOT NULL PRIMARY KEY,  -- layerfile_id
  packvers_id bigint NOT NULL REFERENCES optim.donated_PackFileVers(id),
  ftid smallint NOT NULL REFERENCES optim.feature_type(ftid),
  is_evidence boolean default false,
  hash_md5 text NOT NULL, -- or "size-md5" as really unique string
  proc_step int DEFAULT 1,  -- current status of the "processing steps", 1=started, 2=loaded, ...=finished
  file_meta jsonb,
  feature_asis_summary jsonb,
  feature_distrib jsonb,
  UNIQUE(ftid,hash_md5),
  UNIQUE(packvers_id,ftid,is_evidence)  -- conferir como será o controle de múltiplos files ingerindo no mesmo layer.
);

-----

CREATE FUNCTION optim.vat_id_normalize(p_vat_id text) RETURNS text AS $f$
  SELECT lower(regexp_replace($1,'[,\.;/\-\+\*~]+','','g'))
$f$ language SQL immutable;

CREATE FUNCTION optim.input_donor() RETURNS TRIGGER AS $f$
BEGIN
  NEW.kx_vat_id := optim.vat_id_normalize(NEW.vat_id);
  NEW.id = NEW.country_id*1000000 + NEW.local_serial;
	RETURN NEW;
END;
$f$ LANGUAGE PLpgSQL;
CREATE TRIGGER check_kx_vat_id
    BEFORE INSERT OR UPDATE ON optim.donor
    FOR EACH ROW EXECUTE PROCEDURE optim.input_donor()
;

CREATE FUNCTION optim.input_donated_PackTpl() RETURNS TRIGGER AS $f$
BEGIN
  NEW.id = NEW.donor_id::bigint*100 + NEW.pk_count::bigint;
	RETURN NEW;
END;
$f$ LANGUAGE PLpgSQL;
CREATE TRIGGER generate_id_PackTpl
    BEFORE INSERT OR UPDATE ON optim.donated_PackTpl
    FOR EACH ROW EXECUTE PROCEDURE optim.input_donated_PackTpl()
;

CREATE FUNCTION optim.input_donated_PackFileVers() RETURNS TRIGGER AS $f$
DECLARE
  p_kx_pack_item_version int DEFAULT 0;
BEGIN
  p_kx_pack_item_version := (SELECT MAX(kx_pack_item_version)+1 FROM optim.donated_PackFileVers WHERE pack_id = NEW.pack_id AND pack_item = NEW.pack_item);
  NEW.kx_pack_item_version = CASE WHEN p_kx_pack_item_version IS NULL THEN 1 ELSE p_kx_pack_item_version END; 
  NEW.id = NEW.pack_id*1000000000 + NEW.pack_item*100 + NEW.kx_pack_item_version;
	RETURN NEW;
END;
$f$ LANGUAGE PLpgSQL;
CREATE TRIGGER generate_id_PackFileVers
    BEFORE INSERT OR UPDATE ON optim.donated_PackFileVers
    FOR EACH ROW EXECUTE PROCEDURE optim.input_donated_PackFileVers()
;

CREATE FUNCTION optim.mkdonated_PackTpl() RETURNS TRIGGER AS $f$
BEGIN
  NEW.kx_num_files = jsonb_array_length(NEW.make_conf_tpl->'files');
	RETURN NEW;
END;
$f$ LANGUAGE PLpgSQL;
CREATE TRIGGER check_kx_num_files
    BEFORE INSERT OR UPDATE ON optim.donated_PackTpl
    FOR EACH ROW EXECUTE PROCEDURE optim.mkdonated_PackTpl()
;


-- funções fdw_generate2 e fdw_generate_getclone2 não inserem aspas duplas quando p_addtxtype=false
CREATE or replace FUNCTION optim.fdw_generate2(
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
 sepcols := iIF(p_addtxtype, '" text,"'::text, ','::text);
 -- if delimiter = tab, format = tsv
 EXECUTE
    format(
      'DROP FOREIGN TABLE IF EXISTS %s; CREATE FOREIGN TABLE %s    (%s%s%s)',
       fdwname, fdwname,  iIF(p_addtxtype, '"'::text, ''::text), array_to_string(p_columns,sepcols), iIF(p_addtxtype, '" text'::text, '')
     ) || format(
       'SERVER files OPTIONS (filename %L, format %L, header %L, delimiter %L)',
       f, 'csv', p_header::text, p_delimiter
    );
    return ' '|| fdwname || E' was created!\n source: '||f|| ' ';
END;
$f$ language PLpgSQL;
COMMENT ON FUNCTION optim.fdw_generate2
  IS 'Generates a structure FOREIGN TABLE for ingestion.'
;

CREATE or replace FUNCTION optim.fdw_generate_getclone2(
  -- foreign-data wrapper generator
  p_tablename text,  -- cloned-table name
  p_context text DEFAULT 'br',  -- or null
  p_schemaname text DEFAULT 'optim',
  p_ignore text[] DEFAULT NULL, -- colunms to be ignored.
  p_add text[] DEFAULT NULL, -- colunms to be added.
  p_path text DEFAULT NULL  -- default based on ids
) RETURNS text  AS $wrap$
  SELECT optim.fdw_generate2(
    $1,$2,$3,
    pg_tablestruct_dump_totext(p_schemaname||'.'||p_tablename,p_ignore,p_add),
    false, -- p_addtxtype
    p_path
  )
$wrap$ language SQL;
COMMENT ON FUNCTION optim.fdw_generate_getclone2
  IS 'Generates a clone-structure FOREIGN TABLE for ingestion. Wrap for fdw_generate().'
;

CREATE or replace FUNCTION optim.load_donor_pack(
    jurisdiction text
) RETURNS text AS $f$
DECLARE
  p_path text;
BEGIN
  p_path := '/var/gits/_dg/preserv' || iIF(jurisdiction='INT', '', '-' || UPPER(jurisdiction)) || '/data';
  RETURN (SELECT optim.fdw_generate_getclone2('donor', null, 'optim', array['id','country_id', 'info', 'kx_vat_id'], null, p_path)) || (SELECT optim.fdw_generate2('donatedPack', null, 'optim', array['pack_id int', 'donor_id int', 'pack_count int', 'lst_vers int', 'donor_label text', 'user_resp text', 'accepted_date date', 'escopo text', 'about text', 'author text', 'contentReferenceTime text', 'license_is_explicit text', 'license text', 'uri_objType text', 'uri text', 'isAt_UrbiGIS text','status text','statusUpdateDate text'],false,p_path));
END;
$f$ LANGUAGE PLpgSQL;

CREATE or replace FUNCTION optim.insert_donor_pack() RETURNS text AS $f$
BEGIN
    -- popula optim.donor a partir de tmp_orig.fdw_donor
    INSERT INTO optim.donor (country_id,local_serial, scope, shortname, vat_id, legalname, wikidata_id, url)
    SELECT (SELECT jurisd_base_id FROM optim.jurisdiction WHERE isolabel_ext = split_part(scope,'-', 1)) AS country_id, tmp_orig.fdw_donor.*
    FROM tmp_orig.fdw_donor
    WHERE scope <> 'INT' -- verificar escopo INT
    ON CONFLICT (country_id,local_serial)
    DO UPDATE 
    SET scope=EXCLUDED.scope, shortName=EXCLUDED.shortName, vat_id=EXCLUDED.vat_id, legalName=EXCLUDED.legalName, wikidata_id=EXCLUDED.wikidata_id, url=EXCLUDED.url;

    -- popula optim.donated_PackTpl a partir de tmp_orig.fdw_donatedPack
    INSERT INTO optim.donated_PackTpl (donor_id, user_resp, pk_count, original_tpl, make_conf_tpl)
    SELECT (SELECT jurisd_base_id*1000000+donor_id FROM optim.jurisdiction WHERE isolabel_ext = split_part(escopo, '-', 1)), lower(user_resp), 1, pg_read_file('/var/gits/_dg/preserv-'|| replace(regexp_replace(escopo, '-', '/data/'),'-',$$/$$) || '/_pk' || to_char(donor_id,'fm0000') || '.' || to_char(1,'fm00') || '/make_conf.yaml'), yamlfile_to_jsonb('/var/gits/_dg/preserv-'|| replace(regexp_replace(escopo, '-', '/data/'),'-',$$/$$) || '/_pk' || to_char(donor_id,'fm0000') || '.' || to_char(1,'fm00') || '/make_conf.yaml') as make_conf_tpl
    FROM tmp_orig.fdw_donatedpack
    WHERE file_exists('/var/gits/_dg/preserv-'|| replace(regexp_replace(escopo, '-', '/data/'),'-',$$/$$) || '/_pk' || to_char(donor_id,'fm0000') || '.' || to_char(1,'fm00') || '/make_conf.yaml') -- verificar make_conf.yaml ausentes
    ON CONFLICT (donor_id,pk_count)
    DO UPDATE 
    SET original_tpl=EXCLUDED.original_tpl, make_conf_tpl=EXCLUDED.make_conf_tpl, kx_num_files=EXCLUDED.kx_num_files;

    -- popula optim.donated_PackFileVers a partir de optim.donated_PackTpl
    -- falta pack_item_accepted_date
    INSERT INTO optim.donated_PackFileVers (hashedfname, pack_id, pack_item, pack_item_accepted_date, user_resp)
    SELECT j->>'file'::text AS hashedfname, pack_id , (j->>'p')::int AS pack_item, '1970-01-01'::date, lower(user_resp::text)
    FROM (SELECT id AS pack_id, user_resp, jsonb_array_elements(make_conf_tpl->'files')::jsonb AS j FROM optim.donated_packtpl) AS t 
    WHERE j->'file' IS NOT NULL; -- verificar hash null

    RETURN (SELECT 'OK, inserted new itens at jurisdiction, donor and donatedPack. ');
END;
$f$ LANGUAGE PLpgSQL;

--- LIXO: adaptar para o novo esquema de ID
/* mudou
CREATE FUNCTION dg_preserv.donatedPack_trigf() RETURNS trigger AS $f$
DECLARE
  p_pack_id int;
BEGIN
  p_pack_id := floor(new.pkv_id);
  RETURN CASE
          WHEN dg_preserv.packid_isvalid(new.pkv_id)
            AND EXISTS( SELECT true FROM dg_preserv.donatedPack_commom WHERE pack_id=p_pack_id )
            THEN new
          ELSE NULL
        END;
END
$f$ LANGUAGE PLpgSQL;
CREATE TRIGGER tbefore BEFORE INSERT OR UPDATE ON dg_preserv.donatedPack
  FOR EACH ROW EXECUTE PROCEDURE dg_preserv.donatedPack_trigf()
;
*/

---

/* OLD LIXO:
CREATE FUNCTION lixo optim.donor_id_build_trig() RETURNS trigger AS $f$
DECLARE
  p_pack_id int;
BEGIN
  id = country_id*1000000+local_serial
  p_pack_id := floor(new.pkv_id);
  RETURN CASE
          WHEN dg_preserv.packid_isvalid(new.pkv_id)
            AND EXISTS( SELECT true FROM dg_preserv.donatedPack_commom WHERE pack_id=p_pack_id )
            THEN new
          ELSE NULL
        END;
END
$f$ LANGUAGE PLpgSQL;
*/
