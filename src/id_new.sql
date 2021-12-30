-- funções fdw_generate2 e fdw_generate_getclone2 não inserem aspas duplas quando p_addtxtype=false
CREATE or replace FUNCTION ingest.fdw_generate2(
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
 RAISE NOTICE '1. codec_desc_default : %', array_to_string(p_columns,sepcols);
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
COMMENT ON FUNCTION ingest.fdw_generate
  IS 'Generates a structure FOREIGN TABLE for ingestion.'
;

CREATE or replace FUNCTION ingest.fdw_generate_getclone2(
  -- foreign-data wrapper generator
  p_tablename text,  -- cloned-table name
  p_context text DEFAULT 'br',  -- or null
  p_schemaname text DEFAULT 'optim',
  p_ignore text[] DEFAULT NULL, -- colunms to be ignored.
  p_add text[] DEFAULT NULL, -- colunms to be added.
  p_path text DEFAULT NULL  -- default based on ids
) RETURNS text  AS $wrap$
  SELECT ingest.fdw_generate2(
    $1,$2,$3,
    pg_tablestruct_dump_totext(p_schemaname||'.'||p_tablename,p_ignore,p_add),
    false, -- p_addtxtype
    p_path
  )
$wrap$ language SQL;
COMMENT ON FUNCTION ingest.fdw_generate_getclone
  IS 'Generates a clone-structure FOREIGN TABLE for ingestion. Wrap for fdw_generate().'
;

 
-- carrega donor.csv em tmp_orig.fdw_donor
SELECT ingest.fdw_generate_getclone2('donor', null, 'optim', array['id','country_id', 'info', 'kx_vat_id'], null, '/var/gits/_dg/preserv-BR/data');

-- popula optim.donor a partir de tmp_orig.fdw_donor
INSERT INTO optim.donor (country_id,local_serial, scope, shortname, vat_id, legalname, wikidata_id, url)
SELECT (SELECT jurisd_base_id FROM optim.jurisdiction WHERE isolabel_ext = split_part(scope,'-', 1)) AS country_id, tmp_orig.fdw_donor.*
FROM tmp_orig.fdw_donor
WHERE scope <> 'INT' -- verificar escopo INT
ON CONFLICT (country_id,local_serial)
DO UPDATE 
SET scope=EXCLUDED.scope, shortName=EXCLUDED.shortName, vat_id=EXCLUDED.vat_id, legalName=EXCLUDED.legalName, wikidata_id=EXCLUDED.wikidata_id, url=EXCLUDED.url;


-- carrega donatedPack.csv em tmp_orig.fdw_donatedPack
SELECT ingest.fdw_generate2('donatedPack', null, 'optim', array['pack_id int', 'donor_id int', 'pack_count int', 'lst_vers int', 'donor_label text', 'user_resp text', 'accepted_date date', 'escopo text', 'about text', 'author text', 'contentReferenceTime text', 'license_is_explicit text', 'license text', 'uri_objType text', 'uri text', 'isAt_UrbiGIS text','status text','statusUpdateDate text'],false,'/var/gits/_dg/preserv-BR/data');


CREATE FUNCTION optim.mkdonated_PackTpl() RETURNS TRIGGER AS $f$
BEGIN
  NEW.kx_num_files = jsonb_array_length(NEW.make_conf_tpl->files);
	RETURN NEW;
END;
$f$ LANGUAGE PLpgSQL;
CREATE TRIGGER check_kx_num_files
    BEFORE INSERT OR UPDATE ON optim.donated_PackTpl
    FOR EACH ROW EXECUTE PROCEDURE optim.mkdonated_PackTpl()
;
  
-- popula optim.donated_PackTpl a partir de tmp_orig.fdw_donatedPack
INSERT INTO optim.donated_PackTpl (donor_id, user_resp, donorpack_id, license_default, info)
SELECT (SELECT jurisd_base_id*1000000+donor_id FROM optim.jurisdiction WHERE isolabel_ext = split_part(escopo,'-', 1)), pack_count, escopo, license, null, 
FROM tmp_orig.fdw_donatedpack;
--ON CONFLICT (donor_id,donorpack_id)
--DO UPDATE 
--SET ;

-- popula optim.donated_PackTpl a partir de tmp_orig.fdw_donatedPack
INSERT INTO optim.donated_PackTpl (donor_id, user_resp, pk_count, original_tpl, make_conf_tpl)
SELECT (SELECT jurisd_base_id*1000000+donor_id FROM optim.jurisdiction WHERE isolabel_ext = split_part(escopo, '-', 1)), user_resp, 1, pg_read_file('/var/gits/_dg/preserv-'|| replace(regexp_replace(escopo, '-', '/data/'),'-',$$/$$) || '/_pk' || to_char(donor_id,'fm0000') || '.' || to_char(1,'fm00') || '/make_conf.yaml'), yamlfile_to_jsonb('/var/gits/_dg/preserv-'|| replace(regexp_replace(escopo, '-', '/data/'),'-',$$/$$) || '/_pk' || to_char(donor_id,'fm0000') || '.' || to_char(1,'fm00') || '/make_conf.yaml') as make_conf_tpl
FROM tmp_orig.fdw_donatedpack
WHERE file_exists('/var/gits/_dg/preserv-'|| replace(regexp_replace(escopo, '-', '/data/'),'-',$$/$$) || '/_pk' || to_char(donor_id,'fm0000') || '.' || to_char(1,'fm00') || '/make_conf.yaml') -- verificar make_conf.yaml ausentes
ON CONFLICT (donor_id,pk_count)
DO UPDATE 
SET original_tpl=EXCLUDED.original_tpl, make_conf_tpl=EXCLUDED.make_conf_tpl, kx_num_files=EXCLUDED.kx_num_files;
