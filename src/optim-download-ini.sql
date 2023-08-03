-- dl.digital-guard
SELECT optim.fdw_generate_direct_csv('/var/gits/_dg/preserv/data/redirs/fromDL_toFileServer.csv','tmp_orig.redirects_viz',',');
SELECT download.insert_dldg_csv();

-- Data VisualiZation
SELECT optim.fdw_generate_direct_csv('/var/gits/_dg/preserv/data/redirs/fromCutLayer_toVizLayer.csv','tmp_orig.redirects_viz',',');
SELECT download.insert_viz_csv();

-- donor.csv donatedpack.csv
SELECT optim.insert_donor_pack(t) FROM unnest(ARRAY[     'BO','BR','CL','CO','EC','PE','PY','SR','UY','VE']) t;

-- codecs
SELECT optim.insert_codec_type();

-- licenses
SELECT optim.fdw_generate_direct_csv('/var/gits/_dg/licenses/data/licenses.csv','tmp_orig.licenses',',');
SELECT optim.fdw_generate_direct_csv('/var/gits/_dg/licenses/data/implieds.csv','tmp_orig.implieds',',');
SELECT license.insert_licenses();
