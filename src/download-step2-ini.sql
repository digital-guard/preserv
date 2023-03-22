-- dl.digital-guard
SELECT download.load_dldg_csv('/var/gits/_dg/preserv/data/redirs/fromDL_toFileServer.csv');
SELECT download.insert_dldg_csv();

-- Data VisualiZation
SELECT download.load_viz_csv('/var/gits/_dg/preserv/data/redirs/fromCutLayer_toVizLayer.csv');
SELECT download.insert_viz_csv();
