CREATE SCHEMA    IF NOT EXISTS optim;
CREATE SCHEMA    IF NOT EXISTS tmp_orig;

CREATE EXTENSION IF NOT EXISTS file_fdw;
CREATE SERVER    IF NOT EXISTS files FOREIGN DATA WRAPPER file_fdw;

----------------------

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
COMMENT ON COLUMN optim.jurisdiction.osm_id                  IS 'Relation identifier in OpenStreetMap.';
COMMENT ON COLUMN optim.jurisdiction.jurisd_base_id          IS 'ISO3166-1-numeric COUNTRY ID (e.g. Brazil is 76) or negative for non-iso (ex. oceans).';
COMMENT ON COLUMN optim.jurisdiction.jurisd_local_id         IS 'Numeric official ID like IBGE_ID of BR jurisdiction. For example ACRE is 12 and its cities are {1200013, 1200054,etc}.';
COMMENT ON COLUMN optim.jurisdiction.parent_id               IS 'osm_id of top admin_level.';
COMMENT ON COLUMN optim.jurisdiction.admin_level             IS 'OSM convention for admin_level tag in country.';
COMMENT ON COLUMN optim.jurisdiction.name                    IS 'Name of jurisdiction';
--COMMENT ON COLUMN optim.jurisdiction.parent_abbrev           IS '';
--COMMENT ON COLUMN optim.jurisdiction.abbrev                  IS '';
COMMENT ON COLUMN optim.jurisdiction.wikidata_id             IS 'wikidata identifier without Q prefix.';
COMMENT ON COLUMN optim.jurisdiction.lexlabel                IS 'Cache from name; e.g. sao.paulo.';
COMMENT ON COLUMN optim.jurisdiction.isolabel_ext            IS 'Cache from parent_abbrev (ISO) and name (camel case); e.g. BR-SP-SaoPaulo.';
COMMENT ON COLUMN optim.jurisdiction.ddd                     IS 'Direct distance dialing.';
COMMENT ON COLUMN optim.jurisdiction.housenumber_system_type IS 'Housenumber system.';
COMMENT ON COLUMN optim.jurisdiction.lex_urn                 IS 'Housenumber system law.';
COMMENT ON COLUMN optim.jurisdiction.info                    IS 'Others information.';

COMMENT ON TABLE optim.jurisdiction IS 'Information about jurisdictions without geometry.';

CREATE INDEX jurisdiction_isolabel_ext_idx1 ON optim.jurisdiction USING btree (isolabel_ext);


CREATE TABLE optim.jurisdiction_geom (
  osm_id bigint PRIMARY KEY,
  isolabel_ext text NOT NULL,
  geom geometry(Geometry,4326),
  geom_svg geometry(Geometry,4326),
  kx_ghs1_intersects text[],
  kx_ghs2_intersects text[],
  UNIQUE(isolabel_ext)
);
COMMENT ON COLUMN optim.jurisdiction_geom.osm_id             IS 'Relation identifier in OpenStreetMap.';
COMMENT ON COLUMN optim.jurisdiction_geom.isolabel_ext       IS 'ISO 3166-1 alpha-2 code and name (camel case); e.g. BR-SP-SaoPaulo.';
COMMENT ON COLUMN optim.jurisdiction_geom.geom               IS 'Geometry for osm_id identifier';
COMMENT ON COLUMN optim.jurisdiction_geom.geom_svg           IS 'Simplified geometry version to use in svg interface.';
--COMMENT ON COLUMN optim.jurisdiction_geom.kx_ghs1_intersects IS '';
--COMMENT ON COLUMN optim.jurisdiction_geom.kx_ghs2_intersects IS '';
CREATE INDEX optim_jurisdiction_geom_idx1     ON optim.jurisdiction_geom USING gist (geom);
CREATE INDEX optim_jurisdiction_geom_svg_idx1 ON optim.jurisdiction_geom USING gist (geom_svg);
CREATE INDEX optim_jurisdiction_geom_isolabel_ext_idx1 ON optim.jurisdiction_geom USING btree (isolabel_ext);

COMMENT ON TABLE optim.jurisdiction_geom IS 'OpenStreetMap geometries for optim.jurisdiction.';

CREATE TABLE optim.jurisdiction_eez (
  osm_id bigint PRIMARY KEY,
  isolabel_ext text NOT NULL,
  geom geometry(Geometry,4326),
  UNIQUE(isolabel_ext)
);
COMMENT ON COLUMN optim.jurisdiction_eez.osm_id             IS 'Relation identifier in OpenStreetMap.';
COMMENT ON COLUMN optim.jurisdiction_eez.isolabel_ext       IS 'ISO 3166-1 alpha-2 code; e.g. BR.';
COMMENT ON COLUMN optim.jurisdiction_eez.geom               IS 'Geometry for osm_id identifier';
CREATE INDEX optim_jurisdiction_eez_idx1              ON optim.jurisdiction_eez USING gist (geom);
CREATE INDEX optim_jurisdiction_eez_isolabel_ext_idx1 ON optim.jurisdiction_eez USING btree (isolabel_ext);

COMMENT ON TABLE optim.jurisdiction_eez IS 'OpenStreetMap exclusive economic zone (EEZ) for optim.jurisdiction.';

CREATE TABLE optim.auth_user (
  username text NOT NULL PRIMARY KEY,
  info jsonb
);
COMMENT ON COLUMN optim.auth_user.username IS 'username in host account.';
COMMENT ON COLUMN optim.auth_user.info     IS 'Other account details on host.';

COMMENT ON TABLE optim.auth_user IS 'Authorized users to be a data pack responsible.';

INSERT INTO optim.auth_user(username) VALUES
('carlos','{"git_user":"crebollobr"}'::jsonb),
('igor','{"git_user":"IgorEliezer"}'::jsonb),
('enio','{"git_user":""}'::jsonb),
('peter','{"git_user":"ppKrauss"}'::jsonb),
('claiton','{"git_user":"0e1"}'::jsonb),
('luis','{"git_user":"luisfelipebr"}'::jsonb); -- minimal one Linux's /home/username

CREATE TABLE optim.codec_type (
  extension text,
  variant text,
  descr_mime jsonb,
  descr_encode jsonb,
  UNIQUE(extension,variant)
);
COMMENT ON COLUMN optim.codec_type.extension     IS '';
COMMENT ON COLUMN optim.codec_type.variant       IS '';
COMMENT ON COLUMN optim.codec_type.descr_mime    IS '';
COMMENT ON COLUMN optim.codec_type.descr_encode  IS '';

COMMENT ON TABLE optim.codec_type IS 'Custom codec for ingesting files.';

CREATE TABLE optim.donor (
  id integer NOT NULL PRIMARY KEY CHECK (id = country_id*1000000+local_serial),  -- by trigger!
  country_id int NOT NULL CHECK(country_id>0), -- ISO
  local_serial  int NOT NULL CHECK(local_serial>0), -- byu contry
  scope_osm_id bigint NOT NULL REFERENCES optim.jurisdiction(osm_id),
  scope_label text, -- city code or country code
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
  UNIQUE(country_id,scope_label,shortname)
);
COMMENT ON COLUMN optim.donor.id             IS 'id = country_id*1000000+local_serial';
COMMENT ON COLUMN optim.donor.country_id     IS 'ISO3166-1-numeric COUNTRY ID (e.g. Brazil is 76) or negative for non-iso (ex. oceans).';
COMMENT ON COLUMN optim.donor.local_serial   IS 'Numeric official ID like IBGE_ID of BR jurisdiction. For example ACRE is 12 and its cities are {1200013, 1200054,etc}.';
COMMENT ON COLUMN optim.donor.scope_osm_id   IS 'osm_id of jurisdiction.';
COMMENT ON COLUMN optim.donor.scope_label    IS 'OSM convention for admin_level tag in country.';
COMMENT ON COLUMN optim.donor.shortname      IS 'Abreviation or acronym (local)';
COMMENT ON COLUMN optim.donor.vat_id         IS 'in the Brazilian case is CNPJ number.';
COMMENT ON COLUMN optim.donor.legalName      IS 'in the Brazilian case is Razao Social.';
COMMENT ON COLUMN optim.donor.wikidata_id    IS 'wikidata identifier without Q prefix.';
COMMENT ON COLUMN optim.donor.url            IS 'Official home page of the organization.';
COMMENT ON COLUMN optim.donor.info           IS 'Others information.';
COMMENT ON COLUMN optim.donor.kx_vat_id      IS 'Cache for normalized vat_id.';

COMMENT ON TABLE optim.donor IS 'Data package donor information.';

CREATE TABLE optim.donated_PackTpl(
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
COMMENT ON COLUMN optim.donated_PackTpl.id            IS 'id = donor_id::bigint*100::bigint + pk_count::bigint';
COMMENT ON COLUMN optim.donated_PackTpl.donor_id      IS 'Package donor identifier.';
COMMENT ON COLUMN optim.donated_PackTpl.user_resp     IS 'User responsible for the README and makefile testing.';
COMMENT ON COLUMN optim.donated_PackTpl.pk_count      IS 'Serial number of the package donated by the donor.';
COMMENT ON COLUMN optim.donated_PackTpl.original_tpl  IS 'make_conf.yaml backup by replacing "version" and "file" with mustache placeholder.';
COMMENT ON COLUMN optim.donated_PackTpl.make_conf_tpl IS 'Cache, parsing result from original_tpl (YAML) to JSON.';
COMMENT ON COLUMN optim.donated_PackTpl.kx_num_files  IS 'Cache for jsonb_array_length(make_conf_tpl->files).';
COMMENT ON COLUMN optim.donated_PackTpl.info          IS 'Others information.';

COMMENT ON TABLE optim.donated_PackTpl IS 'Donated pack template, unversioned package, only pack_id control and input logging. Only metadata common to versions.';

CREATE TABLE optim.donated_PackFileVers(
  -- armazena histórico de versões, requer VIEW contendo apenas registros de MAX(pack_item_accepted_date).
  id bigint NOT NULL PRIMARY KEY  CHECK(id=pack_id*1000+pack_item*100+kx_pack_item_version),  -- by trigger!
  hashedfname text NOT NULL  CHECK( hashedfname ~ '^[0-9a-f]{64,64}\.[a-z0-9]+$' ), -- formato "sha256.ext". Hashed filename. Futuro "size~sha256"
  pack_id bigint NOT NULL REFERENCES optim.donated_PackTpl(id),
  pack_item int NOT NULL DEFAULT 1, --  um dos make_conf_tpl->files->file de pack_id
  pack_item_accepted_date date NOT NULL, --  data tipo ano-mês-01, mês da homologação da doação
  kx_pack_item_version int NOT NULL DEFAULT 1, --  versão (serial) correspondente à pack_item_accepted_date. Trigguer: next value.
  user_resp text NOT NULL REFERENCES optim.auth_user(username), -- responsável pela ingestão do arquivo (testemunho)
  -- scope text NOT NULL, -- bbox or minimum bounding AdministrativeArea
  -- license?  tirar do info e trazer para REFERENCES licenças.
  --- about text,
  info jsonb  -- livre
  ,UNIQUE(hashedfname)
  ,UNIQUE(pack_id,pack_item,pack_item_accepted_date)
  ,UNIQUE(pack_id,pack_item,kx_pack_item_version) -- revisar se precisa.
);
COMMENT ON COLUMN optim.donated_PackFileVers.id                      IS 'id=pack_id*1000+pack_item*100+kx_pack_item_version';
COMMENT ON COLUMN optim.donated_PackFileVers.hashedfname             IS 'sha256.ext of file.';
COMMENT ON COLUMN optim.donated_PackFileVers.pack_id                 IS 'donated_PackTpl identifier.';
COMMENT ON COLUMN optim.donated_PackFileVers.pack_item               IS 'make_conf_tpl->files->file corresponding to hashedfname.';
COMMENT ON COLUMN optim.donated_PackFileVers.pack_item_accepted_date IS 'Date of approval of the donation.';
COMMENT ON COLUMN optim.donated_PackFileVers.kx_pack_item_version    IS 'Version (serial) corresponding to pack_item_accepted_date. Trigger: next value.';
COMMENT ON COLUMN optim.donated_PackFileVers.user_resp               IS 'User responsible for ingesting the file.';
COMMENT ON COLUMN optim.donated_PackFileVers.info                    IS 'Others information.';

COMMENT ON TABLE optim.donated_PackFileVers IS 'Stores history of donated package versions.';

------------------------

CREATE TABLE optim.feature_type (  -- replacing old optim.origin_content_type
  ftid smallint PRIMARY KEY NOT NULL,
  ftname text NOT NULL CHECK(lower(ftname)=ftname), -- ftlabel
  geomtype text NOT NULL CHECK(lower(geomtype)=geomtype), -- old model_geo
  need_join boolean, -- false=não, true=sim, null=both (at class).
  description text NOT NULL,
  info jsonb, -- is_useful, score, model_septable, description_pt, description_es, synonymous_pt, synonymous_es
  UNIQUE (ftname)
);
COMMENT ON COLUMN optim.feature_type.ftid        IS 'Feature type numeric identifier.';
COMMENT ON COLUMN optim.feature_type.ftname      IS 'Feature type name.';
COMMENT ON COLUMN optim.feature_type.geomtype    IS 'Feature type geometry type.';
COMMENT ON COLUMN optim.feature_type.need_join   IS 'If feature type needs join. false=no, true=yes, null=both (at class)';
COMMENT ON COLUMN optim.feature_type.description IS 'Feature type description.';
COMMENT ON COLUMN optim.feature_type.info        IS 'Others information.';

COMMENT ON TABLE optim.feature_type IS 'Describes the types of data that can be ingested.';

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

  (15,'cadgeopoint',       'class', null,  'Cadastral geopoint.','{"shortname_pt":"endereço","description_pt":"Endereço cadastral, representação por nome de via e numeração predial.","synonymous_pt":["endereço","planilha dos endereços","cadastro de endereços"]}'::jsonb),
  (16,'cadgeopoint_cmpl',  'none', true,   'Cadastral geopoint, like geopoint_full with only partial core metadata.', NULL),
  (17,'cadgeopoint_noid',  'none', false,  'Cadastral geopoint with some basic metadata but no standard gid for join with geopoint).', NULL),

  (20,'geoaddress',         'class', null,  'Geo-address point.', '{"shortname_pt":"endereço","description_pt":"Geo-endereço. Representação geográfica do endereço, como ponto.","synonymous_pt":["geo-endereço","ponto de endereço","endereço georreferenciado","ponto de endereçamento postal"]}'::jsonb),
  (21,'geoaddress_full',    'point', false, 'Geo-address point with all attributes, via_name and number.', NULL),
  (22,'geoaddress_ext',     'point', true,  'Geo-address point with no (or some) metadata, external metadata at address_cmpl or address_full.', NULL),
  (23,'geoaddress_none',    'point', false, 'Geo-address point-only, no metadata (or no core metadata).', NULL),

  (25,'geopoint',         'class', null,  'Geo-point.', '{"shortname_pt":"endereço","description_pt":"Geo-endereço. Representação geográfica do endereço, como ponto.","synonymous_pt":["geo-endereço","ponto de endereço","endereço georreferenciado"]}'::jsonb),
  (26,'geopoint_full',    'point', false, 'Geo-point with all attributes, via_name and number.', NULL),
  (27,'geopoint_ext',     'point', true,  'Geo-point with no (or some) metadata, external metadata at cadgeopoint_cmpl or cadgeopoint_full.', NULL),
  (28,'geopoint_none',    'point', false, 'Geo-point only, no metadata (or no core metadata).', NULL),

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
  (82,'block_none',   'poly', false,  'Urban block with no ID', NULL),

  (90,'datagrid',        'class', null, 'Grid of cells.', '{"shortname_pt":"grid","description_pt":".","synonymous_pt":["bairro","loteamento"]}'::jsonb),
  (91,'datagrid_full',   'point', false, 'Grid with metadata', NULL),
  (92,'datagrid_ext',    'point', true,  'Grid with external metadata', NULL),
  (93,'datagrid_none',   'point', true,  'Cell center only, no metadata', NULL)
;
-- Para a iconografia do site:
-- SELECT f.ftname as "feature type", t.geomtype as "geometry type", f.description from optim.feature_type f inner JOIN (select  substring(ftname from '^[^_]+') as ftgroup, geomtype  from optim.feature_type where geomtype!='class' group by 1,2) t ON t.ftgroup=f.ftname ;--where t.geomtype='class';
-- Para gerar backup CSV:
-- copy ( select lpad(ftid::text,2,'0') ftid, ftname, description, info->>'description_pt' as description_pt, array_to_string(jsonb_array_totext(info->'synonymous_pt'),'; ') as synonymous_pt from optim.feature_type where geomtype='class' ) to '/tmp/pg_io/featur_type_classes.csv' CSV HEADER;
-- copy ( select lpad(ftid::text,2,'0') ftid, ftname,geomtype, iif(need_join,'yes'::text,'no') as need_join, description  from optim.feature_type where geomtype!='class' ) to '/tmp/pg_io/featur_types.csv' CSV HEADER;

CREATE TABLE optim.donated_PackComponent(
  -- Tabela similar a ingest.layer_file, armazena sumários descritivos de cada layer. Equivale a um subfile do hashedfname.
  id bigserial NOT NULL PRIMARY KEY,  -- layerfile_id
  packvers_id bigint NOT NULL REFERENCES optim.donated_PackFileVers(id),
  ftid smallint NOT NULL REFERENCES optim.feature_type(ftid),
  is_evidence boolean default false,
  --hash_md5 text NOT NULL, -- or "size-md5" as really unique string
  proc_step int DEFAULT 1,  -- current status of the "processing steps", 1=started, 2=loaded, ...=finished
  lineage jsonb NOT NULL,
  lineage_md5 text NOT NULL,
  kx_profile jsonb,
  --file_meta jsonb,
  --hcode_distribution_parameters jsonb,
  --feature_asis_summary jsonb,
  --feature_distrib jsonb,
  UNIQUE(packvers_id,ftid,lineage_md5)
  --UNIQUE(packvers_id,ftid,is_evidence)  -- conferir como será o controle de múltiplos files ingerindo no mesmo layer.
);
COMMENT ON COLUMN optim.donated_PackComponent.id          IS 'bigserial identifier.';
COMMENT ON COLUMN optim.donated_PackComponent.packvers_id IS 'donated_PackFileVers identifier.';
COMMENT ON COLUMN optim.donated_PackComponent.ftid        IS 'Feature type identifier.';
--COMMENT ON COLUMN optim.donated_PackComponent.is_evidence IS '';
COMMENT ON COLUMN optim.donated_PackComponent.proc_step   IS 'Date of approval of the donation.';
COMMENT ON COLUMN optim.donated_PackComponent.lineage     IS 'General information.';
COMMENT ON COLUMN optim.donated_PackComponent.lineage_md5 IS 'md5 from the file.';
COMMENT ON COLUMN optim.donated_PackComponent.kx_profile  IS 'Others information.';

COMMENT ON TABLE optim.donated_PackComponent IS 'Stores definitive descriptive summaries of each published feature type.';

CREATE TABLE optim.donated_PackComponent_not_approved(
  -- Tabela similar a ingest.layer_file, armazena sumários descritivos de cada layer. Equivale a um subfile do hashedfname.
  id bigserial NOT NULL PRIMARY KEY,  -- layerfile_id
  packvers_id bigint NOT NULL REFERENCES optim.donated_PackFileVers(id),
  ftid smallint NOT NULL REFERENCES optim.feature_type(ftid),
  is_evidence boolean default false,
  proc_step int DEFAULT 1,  -- current status of the "processing steps", 1=started, 2=loaded, ...=finished
  lineage jsonb NOT NULL,
  lineage_md5 text NOT NULL,
  kx_profile jsonb,
  UNIQUE(packvers_id,ftid,lineage_md5)
  --UNIQUE(packvers_id,ftid,is_evidence)  -- conferir como será o controle de múltiplos files ingerindo no mesmo layer.
);
COMMENT ON COLUMN optim.donated_PackComponent_not_approved.id          IS 'bigserial identifier.';
COMMENT ON COLUMN optim.donated_PackComponent_not_approved.packvers_id IS 'donated_PackFileVers identifier.';
COMMENT ON COLUMN optim.donated_PackComponent_not_approved.ftid        IS 'Feature type identifier.';
--COMMENT ON COLUMN optim.donated_PackComponent_not_approved.is_evidence IS '';
COMMENT ON COLUMN optim.donated_PackComponent_not_approved.proc_step   IS 'Date of approval of the donation.';
COMMENT ON COLUMN optim.donated_PackComponent_not_approved.lineage     IS 'General information.';
COMMENT ON COLUMN optim.donated_PackComponent_not_approved.lineage_md5 IS 'md5 from the file.';
COMMENT ON COLUMN optim.donated_PackComponent_not_approved.kx_profile  IS 'Others information.';

COMMENT ON TABLE optim.donated_PackComponent_not_approved IS 'Stores descriptive summaries of each feature type awaiting publication approval.';
------------------------

DROP VIEW IF EXISTS optim.vw01info_feature_type CASCADE;
CREATE VIEW optim.vw01info_feature_type AS
  SELECT ftid, ftname, geomtype, need_join, description,
       COALESCE(f.info,'{}'::jsonb) || (
         SELECT to_jsonb(t2) FROM (
           SELECT c.ftid as class_ftid, c.ftname as class_ftname,
                  c.description as class_description,
                  c.info as class_info
           FROM optim.feature_type c
           WHERE c.geomtype='class' AND c.ftid = 5*round(f.ftid/5)
         ) t2
       ) AS info
  FROM optim.feature_type f
  WHERE f.geomtype!='class'
;
COMMENT ON VIEW optim.vw01info_feature_type
  IS 'Adds class_ftname, class_description and class_info to optim.feature_type.info.'
;

CREATE VIEW optim.vw01full_jurisdiction_geom AS
    SELECT j.*, g.geom
    FROM optim.jurisdiction j
    LEFT JOIN optim.jurisdiction_geom g
    ON j.osm_id = g.osm_id
;
COMMENT ON VIEW optim.vw01full_jurisdiction_geom
  IS 'Add geom to optim.jurisdiction.'
;

CREATE or replace VIEW optim.vw01full_donated_PackTpl AS
  SELECT pt.id AS packtpl_id, pt.donor_id, pt.user_resp AS user_resp_packtpl, au.info AS user_resp_packtpl_info, pt.pk_count, pt.original_tpl, pt.make_conf_tpl, pt.kx_num_files, pt.info AS packtpl_info,
         dn.country_id, dn.local_serial, dn.scope_osm_id, dn.scope_label, dn.shortname, dn.vat_id, dn.legalName, dn.wikidata_id, dn.url, dn.info AS donor_info, dn.kx_vat_id,
         j.osm_id, j.jurisd_base_id, j.jurisd_local_id, j.parent_id, j.admin_level, j.name, j.parent_abbrev, j.abbrev, j.wikidata_id AS jurisdiction_wikidata_id, j.lexlabel, j.isolabel_ext, j.ddd, j.housenumber_system_type, j.lex_urn, j.info AS jurisdiction_info, j.isolevel,
         to_char(dn.local_serial,'fm0000') AS local_serial_formated, -- e.g.: 0042
         to_char(dn.local_serial,'fm0000') || '.' || to_char(pt.pk_count,'fm00') AS pack_number, -- e.g.: 0042.01
         '/var/gits/_dg/preservCutGeo-' || regexp_replace(replace(regexp_replace(j.isolabel_ext, '^([^-]*)-?', '\12021/data/'),'-','/'),'\/$','') || '/_pk' || to_char(dn.local_serial,'fm0000') || '.' || to_char(pt.pk_count,'fm00') AS path_cutgeo_server, -- e.g.:
         '/var/gits/_dg/preserv-' || regexp_replace(replace(regexp_replace(j.isolabel_ext, '^([^-]*)-?', '\1/data/'),'-','/'),'\/$','') || '/_pk' || to_char(dn.local_serial,'fm0000') || '.' || to_char(pt.pk_count,'fm00') AS path_preserv_server, -- e.g.:
         'http://git.digital-guard.org/preserv-' || regexp_replace(replace(regexp_replace(j.isolabel_ext, '^([^-]*)-?', '\1/blob/main/data/'),'-','/'),'\/$','') || '/_pk' || to_char(dn.local_serial,'fm0000') || '.' || to_char(pt.pk_count,'fm00') AS path_preserv_git, -- e.g.:
         'http://git.digital-guard.org/preservCutGeo-' || regexp_replace(replace(regexp_replace(j.isolabel_ext, '^([^-]*)-?', '\12021/tree/main/data/'),'-','/'),'\/$','') || '/_pk' || to_char(dn.local_serial,'fm0000') || '.' || to_char(pt.pk_count,'fm00') AS path_cutgeo_git, -- e.g.:
         to_char(dn.local_serial,'fm000') || to_char(pt.pk_count,'fm00') AS pack_number_donatedpackcsv, -- e.g.: 04201
         INITCAP(pt.user_resp) AS user_resp_packtpl_initcap
  FROM optim.donated_PackTpl pt
  LEFT JOIN optim.donor dn
    ON pt.donor_id=dn.id
  LEFT JOIN optim.jurisdiction j
    ON dn.scope_osm_id=j.osm_id
  LEFT JOIN optim.auth_user au
    ON pt.user_resp=au.username
;
COMMENT ON VIEW optim.vw01full_donated_PackTpl
  IS 'Add geom to optim.jurisdiction.'
;

CREATE or replace VIEW optim.vw01full_packfilevers AS
  SELECT pf.*, pt.*,
         substring(pf.hashedfname, '^([0-9a-f]{7}).+$') AS hashedfname_7,
         substring(pf.hashedfname, '^([0-9a-f]{64,64})\.[a-z0-9]+$') AS hashedfname_without_ext,
         substring(pf.hashedfname, '^([0-9a-f]{7}).+$') || '...' || substring(pf.hashedfname, '^.+\.([a-z0-9]+)$') AS hashedfname_7_ext,
         INITCAP(pf.user_resp) AS user_resp_initcap,
         au.info AS user_resp_packfilevers_info
  FROM
  (
    SELECT *
    FROM optim.donated_packfilevers
    WHERE (pack_id,pack_item,kx_pack_item_version) IN
    (
        SELECT pack_id,pack_item, MAX(kx_pack_item_version)
        FROM optim.donated_PackFileVers
        GROUP BY pack_id, pack_item
        ORDER BY pack_id, pack_item
    )
  ) pf
  LEFT JOIN optim.vw01full_donated_PackTpl pt
    ON pf.pack_id=pt.packtpl_id
  LEFT JOIN optim.auth_user au
    ON pf.user_resp=au.username
  ORDER BY pt.isolabel_ext, pt.local_serial, pt.pk_count
;
COMMENT ON VIEW optim.vw01full_packfilevers
  IS 'Join donated_packfilevers with donated_PackTpl, donor and vw01full_jurisdiction_geom.'
;

CREATE or replace VIEW optim.vw01full_packfilevers_ftype AS
    SELECT pf.*, ft.ftid, ft.ftname, ft.geomtype, ft.need_join, ft.description, ft.info AS ftype_info,
    lower(replace(pf.isolabel_ext,'-','_'))  || '_pk' || replace(pf.pack_number,'.','_') || '_' || (ft.info->>'class_ftname') AS full_name_layer
    FROM (
        SELECT *, jsonb_object_keys(make_conf_tpl->'layers') AS layer
        FROM optim.vw01full_packfilevers
    ) pf
    LEFT JOIN optim.vw01info_feature_type ft
    ON ft.ftid = ( SELECT ftid::int FROM optim.feature_type WHERE ftname=lower(layer || '_' || (make_conf_tpl->'layers'->layer->>'subtype')) ) 
;
COMMENT ON VIEW optim.vw01full_packfilevers_ftype
  IS 'Join vw01full_packfilevers with vw01info_feature_type.'
;

------------------------

CREATE or replace VIEW optim.vw01report AS
SELECT isolabel_ext, legalName, vat_id, "ID de pack_componente", ftname, ftid, step, data_feito, n_items, size
FROM (
  SELECT pf.isolabel_ext, pf.legalName, pf.vat_id, packvers_id, idcomp AS "ID de pack_componente",ft.ftname, t.ftid,step, data_feito, (j->>'n')||' '||(j->>'n_unit') AS n_items,  (j->>'size')||' '||(j->>'size_unit') AS size
  FROM (
    SELECT packvers_id, replace(lib.id_format('packfilevers',packvers_id), '076.00','br') AS idcomp, ftid, proc_step AS step, substr(lineage->'file_meta'->>'modification',1,10) AS data_feito, lineage->'feature_asis_summary' AS j
    FROM optim.donated_PackComponent AS r
    ORDER BY 1) t 
  INNER JOIN optim.feature_type ft
    ON ft.ftid=t.ftid
  INNER JOIN optim.vw01full_packfilevers pf
    ON packvers_id=pf.id
  ORDER BY pf.isolabel_ext
) AS g
;
COMMENT ON VIEW optim.vw01report
  IS 'Donated package report.'
;

CREATE or replace VIEW optim.vw02report_simple AS
SELECT isolabel_ext, ftname
FROM optim.vw01report
;
COMMENT ON VIEW optim.vw02report_simple
  IS 'Simplifies optim.vw01report.'
;

CREATE or replace VIEW optim.vw01report_median AS
SELECT isolabel_ext, pack_number, class_ftname,
       COUNT(ghs) AS n,
       ( percentile_disc(0.5) WITHIN GROUP (ORDER BY size_bytes) ) / 1024 AS mdn_n,
       ROUND(AVG(size_bytes) / 1024) AS avg_n,
       MIN(size_bytes) / 1024 AS min_n,
       MAX(size_bytes) / 1024 AS max_n
FROM (
    SELECT isolabel_ext, pack_number, class_ftname, ghs, (SELECT size::bigint FROM pg_stat_file(path)) AS size_bytes
    FROM (
        SELECT isolabel_ext, pack_number, class_ftname, ghs, path_cutgeo || pack_number || '/' || class_ftname || '/' || geom_type_abbr || '_' || ghs || '.geojson' AS path
        FROM (
            SELECT pf.isolabel_ext, pf.pack_number,
                    pf.ftype_info->>'class_ftname' as class_ftname,
                    jsonb_object_keys(pc.kx_profile->'ghs_distrib_mosaic') AS ghs,
                    '/var/gits/_dg/preservCutGeo-' || regexp_replace(replace(regexp_replace(pf.isolabel_ext, '^([^-]*)-?', '\12021/data/'),'-','/'),'\/$','') || '/_pk' AS path_cutgeo,
                    CASE pf.geomtype
                        WHEN 'poly'  THEN 'pols'
                        WHEN 'line'  THEN 'lns'
                        WHEN 'point' THEN 'pts'
                    END AS geom_type_abbr
            FROM optim.vw01full_packfilevers_ftype pf
            INNER JOIN optim.donated_PackComponent pc
            ON pc.packvers_id=pf.id AND pc.ftid=pf.ftid

            WHERE pf.ftid > 19
            ORDER BY pf.isolabel_ext, pf.local_serial, pf.pk_count, pf.ftype_info->>'class_ftname'
        ) r
    ) s
) t
GROUP BY isolabel_ext, pack_number, class_ftname
;
COMMENT ON VIEW optim.vw01report_median
  IS 'Returns the number of files, median, average, minimum and maximum in kibibytes.'
;

------------------------

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
  (2,'block-metric',  '[0-9]+ \- [0-9]+ integer function',     $$First number refers to the urban-block counter, and the second is the distance to the begin of the block in the city's origin order. Sort function is $1*10000 + $2. Example: BR-SP-Bauru housenumbers [30-14, 2-1890].$$),
  (3,'ago-block','',''),
  (4,'df-block','','')
;

COMMENT ON TABLE optim.housenumber_system_type IS 'Stores descriptive house numbering systems.';

------------------------

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
  NEW.id = NEW.pack_id*1000 + NEW.pack_item*100 + NEW.kx_pack_item_version;
	RETURN NEW;
END;
$f$ LANGUAGE PLpgSQL;
CREATE TRIGGER generate_id_PackFileVers
    BEFORE INSERT ON optim.donated_PackFileVers
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

CREATE FUNCTION optim.fdw_generate_direct_csv(
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
COMMENT ON FUNCTION optim.fdw_generate_direct_csv
  IS 'Generates a FOREIGN TABLE for simples and direct CSV ingestion.'
;

-- funções fdw_generate e fdw_generate_getclone não inserem aspas duplas quando p_addtxtype=false
CREATE or replace FUNCTION optim.fdw_generate(
  p_name text,  -- table name and CSV input filename
  p_jurisdiction text DEFAULT 'br',  -- or null
  p_schemaname text DEFAULT 'optim',
  p_columns text[] DEFAULT NULL, -- mais importante! nao poderia ser null
  p_addtxtype boolean DEFAULT false,  -- add " text"
  p_path text DEFAULT NULL,  -- default based on ids
  p_delimiter text DEFAULT ',',
  p_header boolean DEFAULT true
) RETURNS text  AS $f$
DECLARE
 fdwname text;
 f text;
 sepcols text;
BEGIN
 f := concat( COALESCE(p_path,'/var/gits/_dg'), '/preserv', iIF(p_jurisdiction='INT', '', '-' || UPPER(p_jurisdiction)), '/data/', p_name, '.csv');
 fdwname := 'tmp_orig.fdw_'|| iIF(p_schemaname='optim', ''::text, p_schemaname || '_') || p_name || p_jurisdiction;
 sepcols := iIF(p_addtxtype, '" text,"'::text, ','::text);
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
COMMENT ON FUNCTION optim.fdw_generate
  IS 'Generates a structure FOREIGN TABLE for ingestion.'
;

CREATE or replace FUNCTION optim.fdw_generate_getclone(
  -- foreign-data wrapper generator
  p_tablename text,  -- cloned-table name
  p_jurisdiction text DEFAULT 'br',  -- or null
  p_schemaname text DEFAULT 'optim',
  p_ignore text[] DEFAULT NULL, -- colunms to be ignored.
  p_add text[] DEFAULT NULL, -- colunms to be added.
  p_path text DEFAULT NULL  -- default based on ids
) RETURNS text  AS $wrap$
  SELECT optim.fdw_generate(
    $1,$2,$3,
    pg_tablestruct_dump_totext(p_schemaname||'.'||p_tablename,p_ignore,p_add),
    false, -- p_addtxtype
    p_path
  )
$wrap$ language SQL;
COMMENT ON FUNCTION optim.fdw_generate_getclone
  IS 'Generates a clone-structure FOREIGN TABLE for ingestion. Wrap for fdw_generate().'
;

CREATE or replace FUNCTION optim.load_donor_pack(
    jurisdiction text
) RETURNS text AS $f$
BEGIN
  RETURN (SELECT optim.fdw_generate_direct_csv(concat('/var/gits/_dg/preserv', iIF(jurisdiction='INT', '', '-' || UPPER(jurisdiction)), '/data/donor.csv'),'tmp_orig.fdw_donor'|| lower(jurisdiction),',')) || (SELECT optim.fdw_generate('donatedPack', jurisdiction, 'optim', array['pack_id int', 'donor_id int', 'pack_count int', 'lst_vers int', 'donor_label text', 'user_resp text', 'accepted_date date', 'scope text', 'about text', 'author text', 'contentReferenceTime text', 'license_is_explicit text', 'license text', 'uri_objType text', 'uri text', 'isAt_UrbiGIS text','status text','statusUpdateDate text'],false,null));
END;
$f$ LANGUAGE PLpgSQL;
COMMENT ON FUNCTION optim.load_donor_pack
  IS 'Generates a clone-structure FOREIGN TABLE for donor.csv and donatedPack.csv.'
;

--SELECT optim.fdw_generate_direct_csv('/var/gits/_dg/preserv-BR/data/donor.csv','tmp_orig.fdw_donorbr',',')

CREATE or replace FUNCTION optim.load_codec_type(
) RETURNS text AS $f$
BEGIN
  RETURN (SELECT optim.fdw_generate_direct_csv('/var/gits/_dg/preserv/data/codec_type.csv','tmp_orig.fdw_codec_type',','));
END;
$f$ LANGUAGE PLpgSQL;
COMMENT ON FUNCTION optim.load_codec_type
  IS 'Generates a clone-structure FOREIGN TABLE for codec_type.csv.'
;

CREATE or replace FUNCTION optim.insert_codec_type(
) RETURNS text  AS $f$
BEGIN
    INSERT INTO optim.codec_type (extension,variant,descr_mime,descr_encode)
      SELECT lower(extension) AS extension, COALESCE(variant, '') AS variant, jsonb_object(regexp_split_to_array ('mime=' || descr_mime,'(;|=)')) AS descr_mime, jsonb_object(regexp_split_to_array ( descr_encode,'(;|=)')) AS descr_encode
      FROM tmp_orig.fdw_codec_type
    ON CONFLICT (extension,variant)
    DO UPDATE
    SET descr_mime=EXCLUDED.descr_mime, descr_encode=EXCLUDED.descr_encode
    ;

    UPDATE optim.codec_type
    SET descr_encode = jsonb_set(descr_encode, '{delimiter}', to_jsonb(str_urldecode(descr_encode->>'delimiter')), true)
    WHERE descr_encode->'delimiter' IS NOT NULL;

    RETURN 'Load codec_type from codec_type.csv.';
END;
$f$ language PLpgSQL;
COMMENT ON FUNCTION optim.insert_codec_type
  IS 'Load codec_type.csv.'
;

CREATE or replace FUNCTION optim.replace_file_and_version(file text) RETURNS text AS $f$
BEGIN
    RETURN (SELECT regexp_replace(regexp_replace( file , '(p: *([0-9]{1,})\n *)file: *[0-9a-f]{64,64}\.[a-z0-9]+ *$', '\1file: {{file\2}}','ng'),'(pkversion:) *[0-9]{1,}','\1 {{version}}'));
END;
$f$ LANGUAGE PLpgSQL;
--SELECT optim.replace_file_and_version(pg_read_file('/var/gits/_dg/preserv-BR/data/RS/SantaMaria/_pk0019.01/make_conf.yaml'));
COMMENT ON FUNCTION optim.replace_file_and_version
  IS 'Replacing "version" and "file" with mustache placeholder.'
;

CREATE or replace FUNCTION optim.format_filepath(scope text, donor_id bigint, pack_count int) RETURNS text AS $f$
BEGIN
    RETURN (
        SELECT '/var/gits/_dg/preserv-' ||
        CASE WHEN EXISTS (SELECT 1 FROM regexp_matches(scope,'^EC-EC-[A-Z]-.*$'))
        THEN regexp_replace(scope, '^([A-Z][A-Z])-([A-Z][A-Z]-[A-Z])-(.*)$', '\1/data/\2/\3')
        ELSE regexp_replace(replace(regexp_replace(scope, '^([^-]*)-?', '\1/data/'),'-','/'),'\/$','')
        END
         ||
        '/_pk' ||
        to_char(donor_id,'fm0000') ||
        '.' ||
        to_char(pack_count,'fm00') ||
        '/make_conf.yaml');
END;
$f$ LANGUAGE PLpgSQL;
--SELECT optim.format_filepath('BR', 34);
COMMENT ON FUNCTION optim.format_filepath
  IS 'Generates filepath.'
;

CREATE or replace FUNCTION optim.insert_donor_pack(
    jurisdiction text
) RETURNS text AS $f$
DECLARE
  q text;
  ret text;
  a text;
BEGIN
  q := $$
    -- popula optim.donor a partir de tmp_orig.fdw_donor
    INSERT INTO optim.donor (country_id, local_serial, scope_osm_id, scope_label, shortname, vat_id, legalname, wikidata_id, url, info)
    SELECT
        (
            SELECT jurisd_base_id
            FROM optim.jurisdiction
            WHERE lower(isolabel_ext) = lower(scope_label)
        ) AS country_id,
        t.local_id::int AS local_serial,
        (
            SELECT osm_id
            FROM optim.jurisdiction
            WHERE lower(isolabel_ext) = lower(scope_label)
        ) AS scope_osm_id,
        t.scope_label,
        t."shortName" AS shortname,
        t.vat_id,
        t."legalName" AS legalname,
        t.wikidata_id::bigint,
        t.url,
        to_jsonb(subq) AS info
    FROM tmp_orig.fdw_donor%s t, LATERAL (SELECT %s) subq
    WHERE t.scope_label IS NOT NULL
      AND t."legalName" IS NOT NULL
      AND lower(t.scope_label) <> 'na'
      AND lower(t."legalName") <> 'na'
      AND lower(t.wikidata_id) <> 'na'
    ON CONFLICT (country_id,local_serial)
    DO UPDATE 
    SET scope_osm_id=EXCLUDED.scope_osm_id, scope_label=EXCLUDED.scope_label, shortName=EXCLUDED.shortName, vat_id=EXCLUDED.vat_id, legalName=EXCLUDED.legalName, wikidata_id=EXCLUDED.wikidata_id, url=EXCLUDED.url, info=EXCLUDED.info;
  $$;

  EXECUTE format( $$ SELECT array_to_string((SELECT array_agg(x)
  FROM (SELECT split_part(unnest(pg_tablestruct_dump_totext('tmp_orig.fdw_donor%s')),' ',1) ) t(x)
  WHERE x NOT IN ('local_id','scope_label','shortName','vat_id','legalName','wikidata_id','url')),',')
  FROM tmp_orig.fdw_donor%s $$, jurisdiction, jurisdiction ) INTO a;

  EXECUTE format( q, jurisdiction, a ) ;

  q := $$
    -- popula optim.donated_PackTpl a partir de tmp_orig.fdw_donatedPack
    INSERT INTO optim.donated_PackTpl (donor_id, user_resp, pk_count, original_tpl, make_conf_tpl,info)
    SELECT (
        SELECT jurisd_base_id*1000000+donor_id
        FROM optim.jurisdiction
        WHERE lower(isolabel_ext) = lower(scope)
        ) AS donor_id, lower(user_resp) AS user_resp, pack_count, optim.replace_file_and_version(pg_read_file(optim.format_filepath(scope, donor_id, pack_count))) AS original_tpl, yamlfile_to_jsonb(optim.format_filepath(scope, donor_id, pack_count)) AS make_conf_tpl,
        to_jsonb(t) AS info
    FROM tmp_orig.fdw_donatedpack%s t
    WHERE file_exists(optim.format_filepath(scope, donor_id, pack_count)) -- verificar make_conf.yaml ausentes
          AND lst_vers=(select MAX(lst_vers) from tmp_orig.fdw_donatedpack%s where donor_id=t.donor_id )
    ON CONFLICT (donor_id,pk_count)
    DO UPDATE 
    SET original_tpl=EXCLUDED.original_tpl, make_conf_tpl=EXCLUDED.make_conf_tpl, kx_num_files=EXCLUDED.kx_num_files, info=EXCLUDED.info;
  $$;

  EXECUTE format( q, jurisdiction, jurisdiction) ;

  q := $$
    -- popula optim.donated_PackFileVers a partir de optim.donated_PackTpl
    INSERT INTO optim.donated_PackFileVers (hashedfname, pack_id, pack_item, pack_item_accepted_date, kx_pack_item_version, user_resp, info)
    SELECT j->>'file'::text AS hashedfname, t.pack_id , (j->>'p')::int AS pack_item, accepted_date::date AS pack_item_accepted_date, lst_vers, lower(t.user_resp::text) AS user_resp, jsonb_build_object('name', (j->>'name')) AS info
    FROM (
        SELECT pt.id AS pack_id, pt.user_resp, fpt.accepted_date, fpt.lst_vers, jsonb_array_elements((yamlfile_to_jsonb(optim.format_filepath(fpt.scope, fpt.donor_id, fpt.pack_count)))->'files')::jsonb AS j
        FROM optim.donated_packtpl pt
        LEFT JOIN optim.donor d
        ON pt.donor_id = d.id
        LEFT JOIN tmp_orig.fdw_donatedpack%s fpt
        ON d.local_serial = fpt.donor_id AND pt.pk_count = fpt.pack_count
        WHERE pt.donor_id IN (
                SELECT id FROM optim.donor
                WHERE country_id = (
                    SELECT jurisd_base_id
                    FROM optim.jurisdiction
                    WHERE lower(isolabel_ext) = lower(scope)
                    )
                )
            AND ((yamlfile_to_jsonb(optim.format_filepath(fpt.scope, fpt.donor_id, fpt.pack_count)))->'pkversion')::int = lst_vers
            AND file_exists(optim.format_filepath(fpt.scope, fpt.donor_id, fpt.pack_count))
        ) AS t 
    WHERE j->'file' IS NOT NULL -- verificar hash null
    ON CONFLICT (hashedfname)
    DO UPDATE 
    SET pack_id=EXCLUDED.pack_id, pack_item=EXCLUDED.pack_item, pack_item_accepted_date=EXCLUDED.pack_item_accepted_date, user_resp=EXCLUDED.user_resp, info=coalesce(EXCLUDED.info,'{}'::jsonb)||coalesce(optim.donated_PackFileVers.info,'{}'::jsonb);
  $$;
  
  EXECUTE format( q, jurisdiction ) ;

  RETURN (SELECT 'OK, inserted new itens at jurisdiction, donor and donatedPack. ');
END;
$f$ LANGUAGE PLpgSQL;

CREATE or replace FUNCTION optim.approved_packcomponent(
    p_id bigint
) RETURNS text AS $f$
DECLARE
  q text;
BEGIN
  q := $$
    INSERT INTO optim.donated_PackComponent (packvers_id, ftid, is_evidence, proc_step, lineage, lineage_md5, kx_profile)
    SELECT packvers_id, ftid, is_evidence, proc_step, lineage, lineage_md5, coalesce(kx_profile,'{}'::jsonb) || jsonb_build_object( 'date_aprroved', (date_trunc('second',NOW())) )
    FROM optim.donated_PackComponent_not_approved
    WHERE id=%s
    ON CONFLICT (packvers_id,ftid,lineage_md5)
    DO UPDATE
    SET (is_evidence, proc_step, lineage, kx_profile) = (EXCLUDED.is_evidence, EXCLUDED.proc_step, EXCLUDED.lineage, EXCLUDED.kx_profile);
    DELETE FROM optim.donated_PackComponent_not_approved WHERE id=%s
  $$;

  EXECUTE format( q, p_id, p_id ) ;

  RETURN (SELECT 'OK, approved.');
END;
$f$ LANGUAGE PLpgSQL;
COMMENT ON FUNCTION optim.load_donor_pack
  IS 'Insert from clone-structure FOREIGN TABLE from donor.csv and donatedPack.csv.'
;

--- arquivo filtrados

CREATE TABLE optim.donated_PackComponent_cloudControl(
  id              bigserial NOT NULL PRIMARY KEY,
  packvers_id     bigint    NOT NULL REFERENCES optim.donated_PackFileVers(id),
  ftid            smallint  NOT NULL REFERENCES optim.feature_type(ftid),
  lineage_md5     text      NOT NULL,
  hashedfname     text      NOT NULL,
  hashedfnameuri  text      NOT NULL,
  hashedfnametype text      NOT NULL,
  info            jsonb, -- viz_uri: url_layer_visualization
  UNIQUE(packvers_id,ftid,lineage_md5,hashedfnametype),
  UNIQUE(hashedfname,hashedfnameuri)
);
COMMENT ON COLUMN optim.donated_PackComponent_cloudControl.id              IS 'bigserial identifier.';
COMMENT ON COLUMN optim.donated_PackComponent_cloudControl.packvers_id     IS 'donated_PackFileVers identifier.';
COMMENT ON COLUMN optim.donated_PackComponent_cloudControl.ftid            IS 'Feature type identifier.';
COMMENT ON COLUMN optim.donated_PackComponent_cloudControl.lineage_md5     IS 'md5 from the file.';
COMMENT ON COLUMN optim.donated_PackComponent_cloudControl.hashedfname     IS 'name of filtred file.';
COMMENT ON COLUMN optim.donated_PackComponent_cloudControl.hashedfnameuri  IS 'hashedfname file cloud link.';
COMMENT ON COLUMN optim.donated_PackComponent_cloudControl.hashedfnametype IS 'type, csv or shp.';
COMMENT ON COLUMN optim.donated_PackComponent_cloudControl.info            IS 'Others information.';

COMMENT ON TABLE optim.donated_PackComponent_cloudControl IS 'Stores filtered file hyperlinks for each publication feature type.';

CREATE or replace FUNCTION optim.insert_cloudControl(
  p_packvers_id     bigint,
  p_ftid            smallint,
  p_lineage_md5     text,
  p_hashedfname     text, -- formato "sha256.ext". Hashed filename. Futuro "size~sha256"
  p_hashedfnameuri  text,
  p_hashedfnametype text
) RETURNS text AS $f$
    INSERT INTO optim.donated_PackComponent_cloudControl(packvers_id,ftid,lineage_md5,hashedfname,hashedfnameuri,hashedfnametype)
    VALUES (p_packvers_id,p_ftid,p_lineage_md5,p_hashedfname,p_hashedfnameuri,p_hashedfnametype)
    ON CONFLICT (packvers_id,ftid,lineage_md5,hashedfnametype)
    DO UPDATE SET hashedfname=EXCLUDED.hashedfname, hashedfnameuri=EXCLUDED.hashedfnameuri
    RETURNING 'Ok, updated table.'
  ;
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION optim.insert_cloudControl(bigint,smallint,text,text,text,text)
  IS 'Update optim.donated_PackComponent_cloudControl.'
;

CREATE or replace VIEW optim.vw01filtered_files AS
SELECT pack_id, jsonb_build_object('layers', jsonb_agg(jsonb_build_object(
                  'class_ftname',class_ftname,
                  'files',files,
                  'packvers_id', id
                  ))) AS filtered_files
FROM
(
  SELECT id, pack_id, class_ftname, jsonb_agg(jsonb_build_object(
                  'hashedfname', hashedfname,
                  'hashedfname_7', hashedfname_7,
                  'hashedfnametype',hashedfnametype,
                  'hashedfname_without_ext', hashedfname_without_ext,
                  'hashedfname_7_ext', hashedfname_7_ext,
                  'hashedfnameuri', hashedfnameuri
                  )) AS files
  FROM
  (
    SELECT pf.id, pf.pack_id,

      pf.ftype_info->>'class_ftname' as class_ftname,
      substring(pc.hashedfname, '^([0-9a-f]{7}).+$') AS hashedfname_7,
      substring(pc.hashedfname, '^([0-9a-f]{64,64})\.[a-z0-9]+$') AS hashedfname_without_ext,
      substring(pc.hashedfname, '^([0-9a-f]{7}).+$') || '...' || substring(pc.hashedfname, '^.+\.([a-z0-9]+)$') AS hashedfname_7_ext,
      pc.hashedfname,
      hashedfnameuri,
      hashedfnametype

    FROM optim.vw01full_packfilevers_ftype pf
    INNER JOIN optim.donated_PackComponent_cloudControl pc
    ON pc.packvers_id=pf.id AND pc.ftid=pf.ftid
    ORDER BY pf.pack_id, pf.ftype_info->>'class_ftname', pc.hashedfnametype, pc.hashedfname
  ) r
  GROUP BY id, pack_id, class_ftname
) s
GROUP BY pack_id
;
COMMENT ON VIEW optim.vw01filtered_files
  IS 'Filtered files in a package.'
;

CREATE or replace VIEW optim.vw01fromCutLayer_toVizLayer AS
    SELECT isolabel_ext || '/_pk' || pack_number || '/' || (pf.ftype_info->>'class_ftname' ) AS jurisdiction_pack_layer,
           pf.hashedfname AS hash_from,
           pc.info->>'viz_uri' AS url_layer_visualization,
           'https://dl.digital-guard.org/out/a4a_' || replace(lower(isolabel_ext),'-','_') || '_' || (pf.ftype_info->>'class_ftname' ) || '_' || pc.packvers_id || '.zip' AS uri_default,
           pc.hashedfnameuri   AS cloud_uri,
           pc.hashedfnametype  AS filetype
    FROM optim.vw01full_packfilevers_ftype pf
    INNER JOIN optim.donated_PackComponent_cloudControl pc
    ON pc.packvers_id=pf.id AND pc.ftid=pf.ftid
    WHERE pc.hashedfnametype ='shp'
    ORDER BY pf.pack_id, pf.ftype_info->>'class_ftname', pc.hashedfnametype, pc.hashedfname
;
COMMENT ON VIEW optim.vw01fromCutLayer_toVizLayer
  IS 'For fromCutLayer_toVizLayer csv.'
;
-- psql postgres://postgres@localhost/dl03t_main -c "COPY ( SELECT jurisdiction_pack_layer, hash_from, url_layer_visualization FROM optim.vw01fromCutLayer_toVizLayer ) TO '/tmp/pg_io/fromCutLayer_toVizLayer.csv' CSV HEADER;"

    SELECT isolabel_ext,(pf.ftype_info->>'class_ftname' ),'https://dl.digital-guard.org/out/a4a_' || replace(lower(isolabel_ext),'-','_') || '_' || (pf.ftype_info->>'class_ftname' ) || '_' || pc.packvers_id || '.zip'
    FROM optim.vw01full_packfilevers_ftype pf
    INNER JOIN optim.donated_PackComponent_cloudControl pc
    ON pc.packvers_id=pf.id AND pc.ftid=pf.ftid
    WHERE pc.hashedfnametype ='shp'
    ORDER BY pf.pack_id, pf.ftype_info->>'class_ftname', pc.hashedfnametype, pc.hashedfname
;
