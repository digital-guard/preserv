-- dl.digital-guard
SELECT download.load_dldg_csv('/var/gits/_dg/preserv/data/redirs/fromDL_toFileServer.csv');
SELECT download.insert_dldg_csv();

-- Data VisualiZation
SELECT download.load_viz_csv('/var/gits/_dg/preserv/data/redirs/fromCutLayer_toVizLayer.csv');
SELECT download.insert_viz_csv();

SELECT optim.insert_donor_pack(t) FROM unnest(ARRAY[     'BO','BR','CL','CO','EC','PE','PY','SR','UY','VE']) t;
SELECT optim.insert_codec_type();
