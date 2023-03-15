CREATE SCHEMA    IF NOT EXISTS download;
CREATE SCHEMA    IF NOT EXISTS api;

CREATE EXTENSION IF NOT EXISTS file_fdw;
CREATE SERVER    IF NOT EXISTS files FOREIGN DATA WRAPPER file_fdw;

----------------------

-- dl.digital-guard
CREATE TABLE download.redirects (
    donor_id          text,
    filename_original text,
    package_path      text,
    fhash             text NOT NULL PRIMARY KEY, -- de_sha256
    furi              text,                      -- para_url
    UNIQUE (fhash,furi)
);
COMMENT ON TABLE CREATE TABLE download.redirects
  IS ''
;
-- CREATE INDEX jurisdiction_isolabel_ext_idx1 ON optim.jurisdiction USING btree (fhash);

CREATE or replace VIEW api.redirects AS
    SELECT *
    FROM download.redirects
;
COMMENT ON VIEW api.redirects
  IS ''
;

-- Data VisualiZation
CREATE TABLE download.redirects_viz (
    jurisdiction_pack_layer text NOT NULL PRIMARY KEY, -- BR-SP-Guarulhos/_pk0081.01/geoaddress
    url_layer_visualization text NOT NULL ,            -- https://addressforall.maps.arcgis.com/apps/mapviewer/index.html?layers=341962cd00c441f8876202f29fc33dcc
    UNIQUE (jurisdiction_pack_layer,url_layer_visualization)
);
COMMENT ON TABLE download.redirects_viz
  IS 'Matching between layer and external view provided by third party.'
;
CREATE INDEX redirects_viz_jurisdiction_pack_layer_idx1 ON download.redirects_viz USING btree (jurisdiction_pack_layer);

CREATE or replace FUNCTION download.load_viz_csv(
    p_filename text DEFAULT '/var/gits/_dg/preserv/data/viz/fromCutLayer_toVizLayer.csv'
) RETURNS text AS $f$
  SELECT optim.fdw_generate_direct_csv(p_filename,'tmp_orig.redirects_viz',',');
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION download.load_viz_csv
  IS 'Generates a clone-structure FOREIGN TABLE for fromCutLayer_toVizLayer.csv.'
;
-- SELECT download.load_viz_csv('/var/gits/_dg/preserv/data/viz/fromCutLayer_toVizLayer.csv');
-- SELECT optim.fdw_generate_direct_csv('/var/gits/_dg/preserv/data/viz/fromCutLayer_toVizLayer.csv','tmp_orig.redirects_viz',',');

CREATE or replace FUNCTION download.insert_viz_csv(
) RETURNS text AS $f$
    INSERT INTO download.redirects_viz(jurisdiction_pack_layer,url_layer_visualization)
    SELECT jurisdiction_pack_layer, url_layer_visualization
    FROM tmp_orig.redirects_viz
    ON CONFLICT (jurisdiction_pack_layer,url_layer_visualization)
    DO NOTHING
    RETURNING 'Ok, updated table.'
  ;
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION download.insert_viz_csv
  IS 'Update download.redirects_viz from tmp_orig.redirects_viz'
;
-- SELECT download.insert_viz_csv();

CREATE or replace FUNCTION api.redirects_viz(
   p_uri text
) RETURNS jsonb AS $f$
    SELECT jsonb_build_object('error', 'Multiple results.')
    ;
$f$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION api.redirects_viz(text)
  IS ''
;
-- SELECT api.redirects_viz('BR-SP-Jacarei/_pk0145.01/parcel');
