SELECT optim.load_donor_pack(t)   FROM unnest(ARRAY['AR','BO','BR','CL','CO','EC','PE','PY','SR','UY','VE']) t;
SELECT optim.insert_donor_pack(t) FROM unnest(ARRAY[     'BO','BR','CL','CO','EC','PE','PY','SR','UY','VE']) t;
SELECT optim.load_codec_type();
SELECT optim.insert_codec_type();

