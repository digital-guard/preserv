SELECT optim.load_donor_pack(t)   FROM unnest(ARRAY['AR','BO','BR','CL','CO','EC','PE','PY','SR','UY','VE']) t;
SELECT optim.load_codec_type();
