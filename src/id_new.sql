
-- carrega donor.csv em tmp_orig.fdw_donor
SELECT ingest.fdw_generate_getclone('donor', null, 'optim', array['id','country_id', 'info', 'kx_vat_id'], null, '/var/gits/_dg/preserv-BR/data');

-- popula optim.donor a partir de tmp_orig.fdw_donor
--INSERT INTO optim.donor 
--SELECT (SELECT jurisd_base_id FROM optim.jurisdiction WHERE isolabel_ext = split_part('scope text', '-', 1)) AS country_id, 'local_serial' , 'scope text' , 'shortname text' , 'vat_id text', 'legalname text', 'wikidata_id bigint', 'url text'
--FROM tmp_orig.fdw_donor
--ON CONFLICT (country_id,donor_localid)
--DO UPDATE 
--SET scope=EXCLUDED.scope, shortName=EXCLUDED.shortName, vat_id=EXCLUDED.vat_id, legalName=EXCLUDED.legalName, wikidata_id=EXCLUDED.wikidata_id, url=EXCLUDED.url;





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

-- popula optim.donated_PackTpl a partir de tmp_orig.fdw_donatedPack_br
INSERT INTO optim.donated_PackTpl (donor_id, user_resp, pk_count, original_tpl, make_conf_tpl)
SELECT (SELECT jurisd_base_id*1000000+donor_id FROM optim.jurisdiction WHERE isolabel_ext = split_part(escopo, '-', 1)), user_resp, 1, pg_read_file('/var/gits/_dg/preserv-'|| replace(regexp_replace(escopo, '-', '/data/'),'-',$$/$$) || '/_pk' || to_char(donor_id,'fm0000') || '.' || to_char(1,'fm00') || '/make_conf.yaml'), yamlfile_to_jsonb('/var/gits/_dg/preserv-'|| replace(regexp_replace(escopo, '-', '/data/'),'-',$$/$$) || '/_pk' || to_char(donor_id,'fm0000') || '.' || to_char(1,'fm00') || '/make_conf.yaml') as make_conf_tpl
FROM optim.donatedpack;
--ON CONFLICT (donor_id,pk_count)
--DO UPDATE 
--SET ;
