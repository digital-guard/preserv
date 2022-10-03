-- https://github.com/osm-codes/WS/issues/11

DROP VIEW IF EXISTS optim.vw03prepare_jurisdiction_metrics1;
CREATE VIEW optim.vw03prepare_jurisdiction_metrics1 AS
 SELECT osm_id, isolabel_ext,   round(area_m/1000000.0)::int as area_km2,
       round( area_sr, 5)::float as area_sr,
       round( SQRT(area_m)/1000.0, 1)::float as side_estim_km,
       round( SQRT(area_sr), 4)::float       as side_estim_deg,
       round( SQRT(area_sr)/SQRT(area_m), 7 ) as fat_deg_m
 FROM (
   SELECT *, st_area(geom,true) area_m,
                 st_area(geom) area_sr
   FROM optim.vw01full_jurisdiction_geom
   WHERE geom IS NOT NULL
 ) t0
;
comment on view optim.vw03prepare_jurisdiction_metrics1 IS 'Prepare the standard geometry metrics.';
comment on column optim.vw03prepare_jurisdiction_metrics1.area_sr IS 'Area in spheroradians.';
comment on column optim.vw03prepare_jurisdiction_metrics1.side_estim_km IS 'Estimating the side size of an equivalent-area square, in quilometers.';
comment on column optim.vw03prepare_jurisdiction_metrics1.side_estim_deg IS 'Estimating the side size of an equivalent-area square, in degrees.';
comment on column optim.vw03prepare_jurisdiction_metrics1.fat_deg_m IS 'Average degree per meter convertion factor at the points of this area.';

/*
-- PERIGO!
UPDATE  optim.jurisdiction
SET info = COALESCE (info,'{}'::JSONB) || (to_jsonb(t) - 'osm_id')
FROM   ( 
  SELECT osm_id, area_km2, area_sr, side_estim_km, side_estim_deg, fat_deg_m
   FROM optim.vw03prepare_jurisdiction_metrics1 
) t
WHERE t.osm_id=jurisdiction.osm_id
;  -- UPDATE 9245
*/


DROP VIEW IF EXISTS optim.vw04prepare_jurisdiction_shapemetrics;
CREATE VIEW optim.vw04prepare_jurisdiction_shapemetrics AS
SELECT *, round( (rectang_factor_deg + 1.5*elongation_factor_deg)/2.5 , 2)::float AS elong_deg_mixfactor
FROM (
 SELECT osm_id, isolabel_ext,
       round(s[1]/fat_deg_m)/1000 as rectang_L_km,
       round(s[2]/fat_deg_m)/1000 as rectang_H_km,
       CASE 
          WHEN s[6]=0 THEN (round( ((s[1]-s[2])/side_estim_deg)/fat_deg_m )/1000.0)::int
          ELSE -1
       END AS elongation_factor_km,
      CASE
          WHEN s[6]=0 THEN round( (s[1]-s[2]) / side_estim_deg , 2)::float
          ELSE -1
       END AS elongation_factor_deg,
      round( 0.95 + (diaglen_deg - side_estim_deg)/side_estim_deg , 3)::float as rectang_factor_deg
 FROM (
   SELECT  *, (info->'side_estim_deg')::float AS side_estim_deg,
            (info->'side_estim_km')::float  AS side_estim_km,
             (info->'fat_deg_m')::float AS fat_deg_m,
             shapedescr_sizes( ST_SimplifyPreserveTopology(geom, (info->'side_estim_deg')::float/350.0) ) AS s,
                   -- ideal usar ao inves de side_estim a media (diaglen_deg+side_estim_deg)/2.0 
             ST_Length( ST_BoundingDiagonal(geom,true) ) as diaglen_deg
  FROM optim.vw01full_jurisdiction_geom
  WHERE geom is not null  AND info?'side_estim_deg'
 ) t1
) t2;

/*
-- check:
SELECT percentile_disc( array[0.2, 0.5, 0.8] ) WITHIN GROUP (ORDER BY elongation_factor_deg) as pctl_elongation_factor_deg ,
       percentile_disc( array[0.2, 0.5, 0.8] ) WITHIN GROUP (ORDER BY rectang_factor_deg) as pctl_rectang_factor_deg,
       percentile_disc( array[0.2, 0.5, 0.8] ) WITHIN GROUP (ORDER BY elong_deg_mixfactor) as pctl_mix
FROM optim.vw04prepare_jurisdiction_shapemetrics
WHERE isolabel_ext LIKE 'CO-%-%' AND  elongation_factor_deg>0
;  --  shape={1.5,2.02,2.63}      |    pctl_rectang={1.858,2.017,2.255}     |   pctl_mix={1.65,2.02,2.47}
-- Estamos adotando o mix, deu mais certo.

----- PERIGO!
UPDATE  optim.jurisdiction
SET info = COALESCE (info,'{}'::JSONB) || jsonb_build_object('elongation_factor',t.elong_deg_mixfactor)
FROM  optim.vw04prepare_jurisdiction_shapemetrics t
WHERE t.osm_id=jurisdiction.osm_id  AND t.elongation_factor_deg>0
;  -- UPDATE 9203
*/
