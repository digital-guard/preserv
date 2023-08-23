-- Create FDW

-- preserv-[A-Z]{2}/data/donor.csv and preserv-[A-Z]{2}/data/donatedPack.csv
SELECT optim.load_donor_pack(t) FROM unnest(ARRAY['AR','BO','BR','CL','CO','EC','PE','PY','SR','UY','VE']) t;

-- preserv/data/codec_type.csv
SELECT optim.load_codec_type();

-- preserv/data/jurisdPoint.csv
SELECT optim.fdw_generate_direct_csv('/var/gits/_dg/preserv/data/jurisdPoint.csv','tmp_orig.jurisdPoints',',');

-- dl.digital-guard: preserv/data/redirs/fromDL_toFileServer.csv
SELECT optim.fdw_generate_direct_csv('/var/gits/_dg/preserv/data/redirs/fromDL_toFileServer.csv','tmp_orig.redirects_viz',',');

-- Data VisualiZation: preserv/data/redirs/fromCutLayer_toVizLayer.csv
SELECT optim.fdw_generate_direct_csv('/var/gits/_dg/preserv/data/redirs/fromCutLayer_toVizLayer.csv','tmp_orig.redirects_viz',',');

-- licenses
SELECT optim.fdw_generate_direct_csv('/var/gits/_dg/licenses/data/licenses.csv','tmp_orig.licenses',',');
SELECT optim.fdw_generate_direct_csv('/var/gits/_dg/licenses/data/implieds.csv','tmp_orig.implieds',',');

----------------------

CREATE or replace VIEW license.pack_licenses AS
SELECT d.pack_id, l.*
FROM tmp_orig.donatedpacks_donor AS d
LEFT JOIN license.licenses_implieds AS l
ON lower(d.license) = lower(l.id_label || '-' || id_version) AND d.license_is_explicit = l.license_is_explicit;

----------------------

-- Union de fdw_donor de todas as jurisdições
CREATE or replace VIEW tmp_orig.donors AS
    (
        SELECT 'br' AS jurisdiction, r.*
        FROM tmp_orig.fdw_donorbr r
    )
    UNION ALL
    (
        SELECT 'ar' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorar r
    )
    UNION ALL
    (
        SELECT 'bo' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorbo r
    )
    UNION ALL
    (
        SELECT 'cl' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorcl r
    )
    UNION ALL
    (
        SELECT 'co' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorco r
    )
    UNION ALL
    (
        SELECT 'ec' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorec r
    )
    UNION ALL
    (
        SELECT 'pe' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorpe r
    )
    UNION ALL
    (
        SELECT 'py' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorpy r
    )
    UNION ALL
    (
        SELECT 'sr' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorsr r
    )
    UNION ALL
    (
        SELECT 'uy' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donoruy r
    )
    UNION ALL
    (
        SELECT 've' AS jurisdiction, r.*, null, null
        FROM tmp_orig.fdw_donorve r
    )
;

-- Union de fdw_donatedpack X fdw_donor de todas as jurisdições
CREATE or replace VIEW tmp_orig.donatedpacks_donor AS
    (
        SELECT 'br' AS jurisdiction, r.*, s.*
        FROM tmp_orig.fdw_donatedpackbr r
        LEFT JOIN tmp_orig.fdw_donorbr s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'ar' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackar r
        LEFT JOIN tmp_orig.fdw_donorar s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'bo' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackbo r
        LEFT JOIN tmp_orig.fdw_donorbo s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'cl' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackcl r
        LEFT JOIN tmp_orig.fdw_donorcl s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'co' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackco r
        LEFT JOIN tmp_orig.fdw_donorco s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'ec' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackec r
        LEFT JOIN tmp_orig.fdw_donorec s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'pe' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackpe r
        LEFT JOIN tmp_orig.fdw_donorpe s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'py' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackpy r
        LEFT JOIN tmp_orig.fdw_donorpy s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'sr' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpacksr r
        LEFT JOIN tmp_orig.fdw_donorsr s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 'uy' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackuy r
        LEFT JOIN tmp_orig.fdw_donoruy s
        ON s.local_id::int = r.donor_id
    )
    UNION ALL
    (
        SELECT 've' AS jurisdiction, r.*, s.*, null, null
        FROM tmp_orig.fdw_donatedpackve r
        LEFT JOIN tmp_orig.fdw_donorve s
        ON s.local_id::int = r.donor_id
    )
;
