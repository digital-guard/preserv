/**
 * System for Digital Preservation
 * System's Public library (commom for others)
 */

CREATE SCHEMA IF NOT EXISTS optim;
CREATE SCHEMA IF NOT EXISTS dg_preserv;

--------------
-- BEGIN LIXO:
CREATE or replace FUNCTION dg_preserv.packid_to_real(pkid int, version int) RETURNS real AS $f$
  SELECT pkid::real + (CASE WHEN version IS NULL or version<=0 THEN 1 ELSE version END)::real/1000.0::real
  -- Estimativa de versões: 1 por semana ao longo de 15 anos. 15*12*4.3=780. Ainda sobram 320 por segurança.
$f$ language SQL IMMUTABLE;

COMMENT ON FUNCTION dg_preserv.packid_to_real(int,int)
 IS 'Encodes integer pkid and version into real pck_id, convention of the one new version a week for 15 years.'
;

CREATE or replace FUNCTION dg_preserv.packid_to_real(pck_id int[]) RETURNS real AS $wrap$
  SELECT dg_preserv.packid_to_real(pck_id[1],pck_id[2])
$wrap$ language SQL IMMUTABLE;

COMMENT ON FUNCTION dg_preserv.packid_to_real(int[])
 IS 'Encodes integer array[pkid,version] into real pck_id, convention of the 20 years with 40 versions/year.'
;

CREATE or replace FUNCTION dg_preserv.packid_to_real(str_pkid text) RETURNS real AS $f$
  SELECT replace(str_pkid,'_','.')::real
$f$ language SQL IMMUTABLE;

COMMENT ON FUNCTION dg_preserv.packid_to_real(text)
 IS 'Converts pck_id format, text into real.'
;

CREATE or replace FUNCTION dg_preserv.packid_to_ints(pck_id real) RETURNS int[] AS $f$
  SELECT array[k::int,round((pck_id-k)*1000)::int]
  FROM ( SELECT trunc(pck_id) k) t
$f$ language SQL IMMUTABLE;

COMMENT ON FUNCTION dg_preserv.packid_to_ints(real)
 IS 'Decodes real pck_id into integer array[pkid,version], convention of the 20 years with 40 versions/year.'
;

CREATE or replace FUNCTION dg_preserv.packid_to_str(pck_id real, sep boolean default false) RETURNS text AS $f$
 SELECT CASE WHEN sep IS NULL THEN replace(s,'.000','') WHEN sep THEN replace(s,'.','_') ELSE s END
 FROM ( SELECT to_char(CASE WHEN sep IS NULL THEN floor($1) ELSE $1 END,'FM999999000.000') s ) t
$f$ language SQL IMMUTABLE;

CREATE or replace FUNCTION dg_preserv.packid_to_str(pck_id int[], sep boolean default false) RETURNS text AS $wrap$
  select  dg_preserv.packid_to_str( dg_preserv.packid_to_real($1), $2 )
$wrap$ language SQL IMMUTABLE;

CREATE or replace FUNCTION dg_preserv.packid_to_str(pkid int, version int, sep boolean default false) RETURNS text AS $wrap$
 select  dg_preserv.packid_to_str( dg_preserv.packid_to_real($1,$2), $3 )
$wrap$ language SQL IMMUTABLE;

CREATE or replace FUNCTION dg_preserv.packid_plusone(pck_id real) RETURNS real AS $f$
  SELECT dg_preserv.packid_to_real(p[1],p[2]+1) -- +1?
  FROM (SELECT dg_preserv.packid_to_ints(pck_id) p) t
$f$ language SQL IMMUTABLE;

CREATE or replace FUNCTION dg_preserv.packid_isvalid(pck_id real) RETURNS boolean AS $f$
  SELECT CASE
    WHEN p IS NULL OR p[1] IS NULL OR p[1]=0 OR p[2]=0 OR dg_preserv.packid_to_real(p)!=pck_id::real THEN false
    ELSE true
    END
  FROM (SELECT dg_preserv.packid_to_ints(pck_id) p) t
$f$ language SQL IMMUTABLE;

-- falta dinâmico de MAX de real da tabela. Use dg_preserv.packid_plusone(x) para o próximo.

CREATE or replace FUNCTION dg_preserv.packid_getmax(
  p_tablename  text,
  p_plusone boolean DEFAULT false
) RETURNS real AS $f$
DECLARE
  r real;
BEGIN
  EXECUTE format(
    CASE
      WHEN p_plusone THEN 'SELECT MAX(pck_id) INTO r FROM %s'
      ELSE  'SELECT dg_preserv.packid_plusone(MAX(pck_id)) INTO r FROM %s'
    END, p_tablename
  );
  RETURN r;
END
$f$ LANGUAGE PLpgSQL;
COMMENT ON FUNCTION dg_preserv.packid_getmax
 IS 'Obtais the current (or the next when p_plusOne) pck_id of a table.'
;

-- FIM LIXO
-------------


------------------------

CREATE TABLE IF NOT EXISTS optim.jurisdiction ( -- only current
  -- need a view vw01current_jurisdiction to avoid the lost of non-current.
  -- https://schema.org/AdministrativeArea or https://schema.org/jurisdiction ?
  -- OSM use AdminLevel, etc. but LexML uses Jurisdiction.
  osm_id bigint PRIMARY KEY,    -- official or adapted geometry. AdministrativeArea.
  jurisd_base_id int NOT NULL,  -- ISO3166-1-numeric COUNTRY ID (e.g. Brazil is 76) or negative for non-iso (ex. oceans)
  jurisd_local_id int   NOT NULL, -- numeric official ID like IBGE_ID of BR jurisdiction.
  -- for example BR's ACRE is 12 and its cities are {1200013, 1200054,etc}.
  parent_id bigint references optim.jurisdiction(osm_id), -- null for INT.
  admin_level smallint NOT NULL CHECK(admin_level>0 AND admin_level<100), -- 2=country (e.g. BR), at BR: 4=UFs, 8=municipios.
  name    text  NOT NULL CHECK(length(name)<60), -- city name for admin_level=8.
  parent_abbrev   text  NOT NULL, -- state is admin-level2, country level1
  abbrev text  CHECK(length(abbrev)>=2 AND length(abbrev)<=5), -- ISO and other abbreviations
  wikidata_id  bigint,  --  from '^Q\d+'
  lexlabel     text NOT NULL,  -- cache from name; e.g. 'sao.paulo'.
  isolabel_ext text NOT NULL,  -- cache from parent_abbrev (ISO) and name (camel case); e.g. 'BR-SP-SaoPaulo'.
  ddd          integer, -- Direct distance dialing
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
BEGIN
  NEW.kx_pack_item_version := (SELECT MAX(kx_pack_item_version)+1 FROM optim.donated_PackFileVers WHERE pack_id = NEW.pack_id AND pack_item = NEW.pack_item); 
  NEW.id = NEW.pack_id*1000000000 + NEW.pack_item*100 + NEW.kx_pack_item_version;
	RETURN NEW;
END;
$f$ LANGUAGE PLpgSQL;
CREATE TRIGGER generate_id_PackFileVers
    BEFORE INSERT OR UPDATE ON optim.donated_PackFileVers
    FOR EACH ROW EXECUTE PROCEDURE optim.input_donated_PackFileVers()
;

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
