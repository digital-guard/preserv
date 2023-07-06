SELECT optim.load_donor_pack(t) FROM unnest(ARRAY['AR','BO','BR','CL','CO','EC','PE','PY','SR','UY','VE']) t;
SELECT optim.load_codec_type();
SELECT optim.fdw_generate_direct_csv('/var/gits/_dg/preserv/data/jurisdPoint.csv','tmp_orig.jurisdPoints',',');
