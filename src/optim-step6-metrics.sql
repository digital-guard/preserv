-- https://github.com/osm-codes/WS/issues/11

CREATE OR REPLACE FUNCTION public.st_charactdiam(g geometry)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE
AS $function$
  SELECT CASE
      WHEN tp IS NULL OR tp IN ('POINT','MULTIPOINT') THEN 0.0  -- or use convexHull for MULTIPOINT
      WHEN is_poly AND poly_p<2*poly_a THEN (poly_a+poly_p)/2.0 -- normal perimeter
      WHEN is_poly THEN (2*poly_a+SQRT(poly_p))/3.0  -- fractal perimeter
      ELSE ST_Length(g)/2.0  -- or use buffer or convexHull
    END
  FROM (
    SELECT tp, is_poly,
           CASE WHEN is_poly THEN SQRT(ST_Area(g)) ELSE 0 END AS poly_a,
           CASE WHEN is_poly THEN ST_Perimeter(g)/3.5 ELSE 0 END AS poly_p
    FROM (SELECT GeometryType(g)) t(tp),
         LATERAL (SELECT CASE WHEN tp IN ('POLYGON','MULTIPOLYGON') THEN true ELSE false END) t2(is_poly)
  ) t3
$function$
;

CREATE OR REPLACE FUNCTION public.st_transform_resilient(g geometry, srid integer, size_fraction double precision DEFAULT 0.05)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE
AS $function$
  -- discuss ideal at https://gis.stackexchange.com/q/444441/7505
  SELECT CASE
    WHEN size>0.0 THEN  ST_Transform(  ST_Segmentize(g,size)  , srid  )
    ELSE  ST_Transform(g,srid)
    END
  FROM (
    SELECT CASE
         WHEN size_fraction IS NULL THEN 0.0
         WHEN size_fraction<0 THEN -size_fraction
         ELSE ST_CharactDiam(g) * size_fraction
         END
  ) t1(size)
$function$
;

CREATE OR REPLACE FUNCTION public.shapedescr_sizes(gbase geometry, p_decplacesof_zero integer DEFAULT 6, p_dwmin double precision DEFAULT 99999999.0, p_deltaimpact double precision DEFAULT 9999.0)
 RETURNS double precision[]
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
  DECLARE
    ret float[];
    dw float;
    b float;
    L_estim float;
    H_estim float;
    aorig float;
    gaux geometry;
    g1 geometry;
    A0 float;
    A1 float;
    c float;
    delta float;
    per float;
    errcod float;
  BEGIN
    errcod=0.0;
    IF gbase IS NULL OR NOT(ST_IsClosed(gbase)) THEN
        errcod=1;                  -- ERROR1 (die)
        RAISE EXCEPTION 'error %: invalid input geometry',errcod;
    END IF;
    A0 := ST_Area(gbase);
    per := st_perimeter(gbase);
    dw := sqrt(A0)/p_deltaimpact;
    IF dw>p_dwmin THEN dw:=p_dwmin; END IF;
    g1 = ST_Buffer(gbase,dw);
    A1 = ST_area(g1);
    IF A0>A1 THEN
        errcod=10;                 -- ERROR2 (die)
        RAISE EXCEPTION 'error %: invalid buffer/geometry with A0=% g.t. A1=%',errcod,A0,A1;
    END IF;
    IF (A1-A0)>1.001*dw*per THEN
        gaux := ST_Buffer(g1,-dw);  -- closing operation.
        A0 = ST_Area(gaux);         -- changed area
        per := ST_Perimeter(gaux);  -- changed
        errcod:=errcod + 0.1;       -- Warning3
    END IF;
    C := 2.0*dw;
    b := -(A1-A0)/C+C;
    delta := b^2-4.0*A0;
    IF delta<0.0 AND round(delta,p_decplacesof_zero)<=0.0 THEN
           delta=0.0; -- for regular shapes like the square
           errcod:=errcod + 0.01;  -- Warning2
    END IF;
    IF delta<0.0 THEN
        L_estim := NULL;
        H_estim := NULL;
        errcod:=errcod+100;        -- ERROR3
    ELSE
        L_estim := (-b + sqrt(delta))/2.0;
        H_estim := (-b - sqrt(delta))/2.0;
    END IF;
    IF abs(A0-L_estim*H_estim)>0.001 THEN
        errcod:=errcod + 0.001;    -- Warning1
    END IF;
    ret := array[L_estim,H_estim,a0,per,dw,errcod];
    return ret;
  END
$function$
;

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
