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
    hashedfname       text NOT NULL PRIMARY KEY CHECK( hashedfname ~ '^[0-9a-f]{64,64}\.[a-z0-9]+$' ), -- formato "sha256.ext". Hashed filename. Futuro "size~sha256"
    hashedfnameuri    text,                      -- para_url
    UNIQUE (hashedfname,hashedfnameuri)
);
COMMENT ON TABLE download.redirects
  IS ''
;
CREATE INDEX redirects_hashedfname_idx1 ON download.redirects USING btree (hashedfname);

CREATE or replace FUNCTION download.load_dldg_csv(
    p_filename text DEFAULT '/var/gits/_dg/preserv/data/redirs/fromDL_toFileServer.csv'
) RETURNS text AS $f$
  SELECT optim.fdw_generate_direct_csv(p_filename,'tmp_orig.redirects_dlguard',',');
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION download.load_dldg_csv
  IS 'Generates a clone-structure FOREIGN TABLE for fromDL_toFileServer.csv.'
;
-- SELECT download.load_dldg_csv('/var/gits/_dg/preserv/data/redirs/fromDL_toFileServer.csv');
-- SELECT optim.fdw_generate_direct_csv('/var/gits/_dg/preserv/data/redirs/fromDL_toFileServer.csv','tmp_orig.redirects_viz',',');

CREATE or replace FUNCTION download.insert_dldg_csv(
) RETURNS text AS $f$
  INSERT INTO download.redirects(donor_id,filename_original,package_path,hashedfname,hashedfnameuri)
  SELECT donor_id,filename_original,package_path,de_sha256,para_url
  FROM tmp_orig.redirects_dlguard
  ON CONFLICT (hashedfname,hashedfnameuri)
  DO UPDATE
  SET donor_id=EXCLUDED.donor_id, filename_original=EXCLUDED.filename_original, package_path=EXCLUDED.package_path
  RETURNING 'Ok, updated download.redirects.'
  ;
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION download.insert_dldg_csv
  IS 'Update download.redirects from tmp_orig.redirects_dlguard'
;
-- SELECT download.insert_dldg_csv();

----------------------

-- Data VisualiZation
CREATE TABLE download.redirects_viz (
    jurisdiction_pack_layer text NOT NULL PRIMARY KEY, -- BR-SP-Guarulhos/_pk0081.01/geoaddress
    hashedfname_from        text NOT NULL CHECK( hashedfname_from ~ '^[0-9a-f]{64,64}\.[a-z0-9]+$' ), -- formato "sha256.ext". Hashed filename. Futuro "size~sha256"
    url_layer_visualization text NOT NULL,            -- https://addressforall.maps.arcgis.com/apps/mapviewer/index.html?layers=341962cd00c441f8876202f29fc33dcc
    UNIQUE (jurisdiction_pack_layer),
    UNIQUE (hashedfname_from),
    UNIQUE (url_layer_visualization),
    UNIQUE (jurisdiction_pack_layer,hashedfname_from,url_layer_visualization)
);
COMMENT ON TABLE download.redirects_viz
  IS 'Matching between layer and external view provided by third party.'
;
CREATE INDEX redirects_viz_jurisdiction_pack_layer_idx1 ON download.redirects_viz USING btree (jurisdiction_pack_layer);

CREATE or replace FUNCTION download.load_viz_csv(
    p_filename text DEFAULT '/var/gits/_dg/preserv/data/redirs/fromCutLayer_toVizLayer.csv'
) RETURNS text AS $f$
  SELECT optim.fdw_generate_direct_csv(p_filename,'tmp_orig.redirects_viz',',');
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION download.load_viz_csv
  IS 'Generates a clone-structure FOREIGN TABLE for fromCutLayer_toVizLayer.csv.'
;
-- SELECT download.load_viz_csv('/var/gits/_dg/preserv/data/redirs/fromCutLayer_toVizLayer.csv');
-- SELECT optim.fdw_generate_direct_csv('/var/gits/_dg/preserv/data/redirs/fromCutLayer_toVizLayer.csv','tmp_orig.redirects_viz',',');

CREATE or replace FUNCTION download.insert_viz_csv(
) RETURNS text AS $f$
  INSERT INTO download.redirects_viz(jurisdiction_pack_layer,hashedfname_from,url_layer_visualization)
  SELECT jurisdiction_pack_layer, hash_from, url_layer_visualization
  FROM tmp_orig.redirects_viz
  ON CONFLICT (jurisdiction_pack_layer,hashedfname_from,url_layer_visualization)
  DO NOTHING
  RETURNING 'Ok, updated download.redirects_viz.'
  ;
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION download.insert_viz_csv
  IS 'Update download.redirects_viz from tmp_orig.redirects_viz'
;
-- SELECT download.insert_viz_csv();

CREATE or replace FUNCTION download.update_cloudControl_vizuri(
) RETURNS text AS $f$
  UPDATE optim.donated_PackComponent_cloudControl c
  SET info = coalesce(info,'{}'::jsonb) || jsonb_build_object('viz_uri', url_layer_visualization)
  FROM tmp_orig.redirects_viz v
  WHERE c.hashedfname= v.hash_from
  RETURNING 'Ok, update viz_uri in info of optim.donated_PackComponent_cloudControl.'
  ;
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION download.update_cloudControl_vizuri
  IS 'Update viz_uri in info of optim.donated_PackComponent_cloudControl'
;
-- SELECT download.update_cloudControl_vizuri();

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

----------------------

CREATE or replace VIEW api.redirects AS
    -- dl.digital-guard
    SELECT hashedfname AS fhash, hashedfnameuri AS furi
    FROM download.redirects

    UNION

    -- Data VisualiZation
    SELECT hashedfname, hashedfnameuri
    FROM optim.donated_PackComponent_cloudControl
;
COMMENT ON VIEW api.redirects
  IS ''
;
