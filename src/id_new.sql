
-- carrega donor.csv em tmp_orig.fdw_donor
SELECT ingest.fdw_generate_getclone('donor', null, 'optim', array['id','country_id', 'info', 'kx_vat_id'], null, '/var/gits/_dg/preserv-BR/data');

-- popula optim.donor a partir de tmp_orig.fdw_donor
--INSERT INTO optim.donor 
--SELECT (SELECT jurisd_base_id FROM optim.jurisdiction WHERE isolabel_ext = split_part('scope text', '-', 1)) AS country_id, 'local_serial' , 'scope text' , 'shortname text' , 'vat_id text', 'legalname text', 'wikidata_id bigint', 'url text'
--FROM tmp_orig.fdw_donor
--ON CONFLICT (country_id,donor_localid)
--DO UPDATE 
--SET scope=EXCLUDED.scope, shortName=EXCLUDED.shortName, vat_id=EXCLUDED.vat_id, legalName=EXCLUDED.legalName, wikidata_id=EXCLUDED.wikidata_id, url=EXCLUDED.url;



