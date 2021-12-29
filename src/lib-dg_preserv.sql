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
  parent_id bigint references dg_preserv.jurisdiction(osm_id), -- null for INT.
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
  id integer NOT NULL PRIMARY KEY CHECK (id = country_id*1000000+local_serial),
  country_id int NOT NULL CHECK(country_id>0), -- ISO
  local_serial  int NOT NULL CHECK(local_serial>0), -- byu contry 
  scope text, -- city code or country code
  shortname text, -- abreviation or acronym (local)
  vat_id text,    -- in the Brazilian case is "CNPJ:number"
  legalName text NOT NULL, -- in the Brazilian case is Razao Social
  wikidata_id bigint,  -- without "Q" prefix
  url text,     -- official home page of the organization
  info JSONb,   -- all other information using controlled keys
  --kx_vat_id text,    -- cache for search 
  UNIQUE(country_id,local_serial),
  UNIQUE(country_id,vat_id),
  --UNIQUE(kx_vat_id),
  UNIQUE(country_id,legalName),
  UNIQUE(country_id,scope,shortname)
);

CREATE TABLE optim.donated_PackTpl(   
   -- donated pack template, Pacote não-versionado, apenas controle de pack_id e registro da entrada. Só metaqdos comuns às versóes.
  id bigint NOT NULL PRIMARY KEY CHECK (id = donor_id::bigint*100::bigint + pk_count::bigint),
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
  id bigint NOT NULL PRIMARY KEY  CHECK(id=pack_id*1000000000+pack_item*100+kx_pack_item_version),  -- old checked by donatedPack_trigf().
  hashedfname text NOT NULL  CHECK( hashedfname ~ '^[0-9a-f]{64,64}\.[a-z0-9]+$' ),, -- formato "size~sha256.ext". Hashed filename.
  pack_id bigint NOT NULL REFERENCES optim.donated_PackTpl(id),
  pack_item int NOT NULL DEFAULT 1, --  um dos make_conf_tpl->files->file de pack_id 
  pack_item_accepted_date date NOT NULL, --  data tipo ano-mês-01, mês da homologação da doação
  kx_pack_item_version int NOT NULL DEFAULT 1, --  versão (serial) correspondente à pack_item_accepted_date. Requer Trigguer para automatizar.
  user_resp text NOT NULL REFERENCES optim.auth_user(username), -- responsável pela ingestão do arquivo (testemunho)
  -- escopo text NOT NULL, -- bbox or minimum bounding AdministrativeArea
  -- license?  tirar do info e trazer para REFERENCES licenças.
  --- about text,
  info jsonb  -- livre
  ,UNIQUE(hashedfname),
  ,UNIQUE(pack_id,pack_item,pack_item_accepted_date),
  ,UNIQUE(donor_id,accepted_date,escopo) -- revisar se precisa.
);

CREATE TABLE optim.donated_PackComponent(
  -- ... similar ao ingest.layer_file, armazena sumários descritivos de cada layer. Equivale a um subfile do hashedfname.
  layerfile_id bigserial NOT NULL PRIMARY KEY,
  packvers_id bigint NOT NULL REFERENCES optim.donated_PackFileVers(id),
  ftid smallint NOT NULL REFERENCES ingest.feature_type(ftid),
  is_evidence boolean default false,
  ash_md5 text NOT NULL, -- or "size-md5" as really unique string
  proc_step int DEFAULT 1,  -- current status of the "processing steps", 1=started, 2=loaded, ...=finished
  file_meta jsonb,
  feature_asis_summary jsonb,
  feature_distrib jsonb,
  UNIQUE(ftid,hash_md5),
  UNIQUE(packvers_id,ftid,is_evidence)  -- conferir como será o controle de multiplos files ingerindo no mesmo layer.
);

-----

--- LIXO: adaptar para o novo esquema de ID
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
