-- preserv-[A-Z]{2}/data/donor.csv and preserv-[A-Z]{2}/data/donatedPack.csv
-- SELECT optim.insert_donor_pack(t) FROM unnest(ARRAY['AR','BO','BR','CL','CO','EC','MX','PE','PY','SR','UY','VE']) t;
SELECT optim.insert_donor_pack(t) FROM unnest(ARRAY['BO','BR','CL','CO','EC','MX','PE','PY','SR','UY','VE']) t;

-- dl.digital-guard: preserv/data/redirs/fromDL_toFileServer.csv
SELECT download.insert_dldg_csv();

-- Data VisualiZation: preserv/data/redirs/fromCutLayer_toVizLayer.csv
SELECT download.insert_viz_csv();

-- licenses
SELECT license.insert_licenses();

-- preserv/data/codec_type.csv
SELECT optim.insert_codec_type();
