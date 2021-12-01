-- Przyk³ad 1 - St_Intersects

CREATE TABLE lesiak.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

-- 1.1

alter table lesiak.intersects
add column rid SERIAL PRIMARY KEY;

-- 1.2

CREATE INDEX idx_intersects_rast_gist ON lesiak.intersects
USING gist (ST_ConvexHull(rast));

-- 1.3

-- schema::name table_name::name raster_column::name
SELECT AddRasterConstraints('lesiak'::name, 'intersects'::name, 'rast'::name);

-- Przyk³ad 2 - St_Clip

CREATE TABLE lesiak.clip2 AS
SELECT ST_Clip(a.rast, b.geom, true) as rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

select * from  lesiak.clip p

-- 2.1

alter table lesiak.clip
add column rid SERIAL PRIMARY KEY;

-- 2.2

CREATE INDEX idx_clip_rast_gist ON lesiak.clip
USING gist (ST_ConvexHull(rast));

-- 3.3

SELECT AddRasterConstraints('lesiak'::name, 'clip'::name, 'rast'::name);

-- Przyk³ad 3 - St_Union

CREATE TABLE lesiak."union" AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true)) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality like 'PORTO' and ST_Intersects(b.geom,a.rast);

select * from  lesiak."union";

-- 2.1

alter table lesiak."union"
add column rid SERIAL PRIMARY KEY;

-- 2.2

CREATE INDEX idx_union_rast_gist ON lesiak."union"
USING gist (ST_ConvexHull(rast));

-- 3.3

SELECT AddRasterConstraints('lesiak'::name, 'union'::name, 'rast'::name);

-- Przyk³ad 4 - St_asRaster

CREATE TABLE lesiak.porto_parishes AS
WITH r AS (SELECT rast FROM rasters.dem LIMIT 1)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality like 'PORTO';

-- Przyk³ad 5 - St_Union(st_asRaster)

DROP TABLE lesiak.porto_parishes; --> drop table porto_parishes first
CREATE TABLE lesiak.porto_parishes AS
WITH r AS (SELECT rast FROM rasters.dem LIMIT 1)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality like 'PORTO';

-- Przyk³ad 6 - St_Tile

DROP TABLE lesiak.porto_parishes; --> drop table porto_parishes first
CREATE TABLE lesiak.porto_parishes AS
WITH r AS (SELECT rast FROM rasters.dem LIMIT 1)
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- Przyk³ad 7 - St_Intersection (raster2wektor)

create table lesiak."intersection" as
SELECT a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- Przyk³ad 8 - St_dumpAsPolygon (raster2wektor)

CREATE TABLE lesiak.dumppolygons AS
SELECT a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- Przyk³ad 9 - St_Band (wyodrêbnianie pasm z rastra)

CREATE TABLE lesiak.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

-- Przyk³ad 10 - St_Clip (wycinanie rastra na podstawie rastra)

CREATE TABLE lesiak.paranhos_dem AS
SELECT a.rid, ST_Clip(a.rast, b.geom, true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- Przyk³ad 11 - St_Slope

CREATE TABLE lesiak.paranhos_slope AS
SELECT a.rid, ST_Slope(a.rast, 1, '32BF', 'PERCENTAGE') as rast
FROM lesiak.paranhos_dem AS a;

-- Przyk³ad 12 - St_Reclass

CREATE TABLE lesiak.paranhos_slope_reclass AS
SELECT a.rid, ST_Reclass(a.rast, 1, ']0-15]:1, (15-30]:2, (30-9999:3', '32BF', 0)
FROM lesiak.paranhos_slope AS a;

-- Przyk³ad 13 - St_SummaryStats

SELECT st_summarystats(a.rast) AS stats
FROM lesiak.paranhos_dem AS a;

-- Przyk³ad 14 - St_SummaryStats + St_Union

SELECT st_summarystats(ST_Union(a.rast))
FROM lesiak.paranhos_dem AS a;

-- Przyk³ad 15 - St_summaryStats z wyborem statystyk

WITH t AS (SELECT st_summarystats(ST_Union(a.rast)) AS stats FROM lesiak.paranhos_dem AS a)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

-- Przyk³ad 16 - St_SummaryStats z Group By (statystyki dla rastrów wewn¹rz wektora)

WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast, b.geom, true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

-- Przyk³ad 17 - St_Value

SELECT b.name, st_value(a.rast,(ST_Dump(b.geom)).geom) -- konwersja MULTIPOINT na POINT
from rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

-- Przyk³ad 18 - St_TPI

create table lesiak.tpi30 as
select ST_TPI(a.rast,1) as rast
from rasters.dem a;

-- 18.1 

CREATE INDEX idx_tpi30_rast_gist ON lesiak.tpi30
USING gist (ST_ConvexHull(rast));

-- 18.2

SELECT AddRasterConstraints('lesiak'::name, 'tpi30'::name,'rast'::name);
select * from public.raster_columns rc 

-- Przyk³ad 19 - Samodzielny problem

create table lesiak.tpi30Porto as
with p as(
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO'
)
select ST_TPI(p.rast,1) as rast
from p;

-- Przyk³ad 20 - Wyra¿enie Algebry Map (NDVI)

CREATE TABLE lesiak.porto_ndvi AS
WITH r AS (
SELECT a.rid, ST_Clip(a.rast, b.geom, true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid, ST_MapAlgebra(
	r.rast, 1,
	r.rast, 4,
	'([rast2.val] - [rast1.val]) / ([rast2.val] + [rast1.val])::float','32BF' ) AS rast
FROM r;

-- 20.1

CREATE INDEX idx_porto_ndvi_rast_gist ON lesiak.porto_ndvi
USING gist (ST_ConvexHull(rast));

-- 20.2

SELECT AddRasterConstraints('lesiak'::name, 'porto_ndvi'::name,'rast'::name);

-- Przyk³ad 21 - Algebra Map (callback function)

-- 21.1 - deklaracja funkcji
 
create or replace function lesiak.ndvi(
	value double precision [] [] [],
	pos integer [][],
	VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
	--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
	RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value [1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

-- 21.2 - kwerenda z wykorzystaniem fukcji

CREATE TABLE lesiak.porto_ndvi2 AS
WITH r AS (
	SELECT a.rid, ST_Clip(a.rast, b.geom, true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid, ST_MapAlgebra(
		r.rast, ARRAY[1,4],
		'lesiak.ndvi(double precision[], integer[],text[])'::regprocedure, --> This is the function!
		'32BF'::text
	) AS rast
FROM r;

-- 21.3 - indeks przestrzenny

CREATE INDEX idx_porto_ndvi2_rast_gist ON lesiak.porto_ndvi2
USING gist (ST_ConvexHull(rast));

-- 21.4 - raster constraints

SELECT AddRasterConstraints('lesiak'::name, 'porto_ndvi2'::name,'rast'::name);

-- Przyk³ad 22 - St_asTiff

SELECT ST_AsTiff(ST_Union(rast))
FROM lesiak.porto_ndvi;

-- Przyk³ad 23 - ST_AsGDALRaster

SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
FROM lesiak.porto_ndvi;

SELECT ST_GDALDrivers();

-- Przyk³ad 24 - large object (lo)

CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM lesiak.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'F:\myraster.tiff') --> Save the file in a place where the user postgres have access. In windows a flash drive usualy works fine.
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.

select * from public.raster_columns rc;








