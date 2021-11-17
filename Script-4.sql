-- 1. Utworzenie podanych obiektów

create table zadania.obiekty(
	gid serial primary KEY,
	nazwa varchar(30),
	geom geometry
)

insert into zadania.obiekty ( nazwa, geom ) 
 values ('obiekt1', st_geomfromEWKt('SRID=0;COMPOUNDCURVE((0 1, 1 1),CIRCULARSTRING(1 1, 2 0, 3 1),CIRCULARSTRING(3 1, 4 2, 5 1),(5 1, 6 1))'));

insert into zadania.obiekty ( nazwa, geom ) 
 values ('obiekt2', st_geomfromEWKT('SRID=0;CURVEPOLYGON(COMPOUNDCURVE((10 6, 14 6),CIRCULARSTRING(14 6, 16 4, 14 2),CIRCULARSTRING(14 2, 12 0, 10 2),(10 2, 10 6)),COMPOUNDCURVE(Circularstring(12 1, 11 2, 12 3),Circularstring(12 3, 13 2, 12 1)))'));

insert into zadania.obiekty ( nazwa, geom ) 
 values ('obiekt3', st_geomfromEWKT('SRID=0;MULTILINESTRING((7 15, 10 17),(10 17, 12 13),(12 13, 7 15))'));

insert into zadania.obiekty ( nazwa, geom ) 
 values ('obiekt4', st_geomfromEWKT('SRID=0;MULTILINESTRING((20 20, 25 25),(25 25, 27 24),(27 24, 25 22),(25 22, 26 21),(26 21, 22 19),(22 19, 20.5 19.5),(20.5 19.5, 20 20))'));
 
insert into zadania.obiekty ( nazwa, geom ) 
 values('obiekt5', st_geomfromEWKT('SRID=0;MULTIPOINTM(30 30 59,38 32 234)'));

insert into zadania.obiekty ( nazwa, geom ) 
 values('obiekt6', st_geomfromEWKT('SRID=0;GEOMETRYCOLLECTIONM(POINTM(4 2 0),LINESTRINGM(1 1 0, 3 2 0))'));
 
select * from obiekty o;

delete from obiekty o

-- Zapytania

-- 1 Pole bufora z najkrótszej linii

select st_area(st_buffer(st_shortestline(o.geom, o2.geom),5)) as pole_bufora
 from zadania.obiekty o, zadania.obiekty o2 
  where o.nazwa like 'obiekt3' and o2.nazwa like 'obiekt4';
  
-- 2 Zamiana obiekt4 na poligon, problem - brak domkniêcia poligonu
 
select ST_Polygonize(o.geom)
 from zadania.obiekty o 
  where o.nazwa like 'obiekt4';
  
select st_buildarea(o.geom)
 from zadania.obiekty o 
  where o.nazwa like 'obiekt4';
  
-- 3 obiekt7 = obiekt3 + obiekt4
 
insert into zadania.obiekty (nazwa, geom)
values('obiekt7', (select st_collect(o.geom, o2.geom) 
  from zadania.obiekty o, zadania.obiekty o2
   where o.nazwa like 'obiekt3' and o2.nazwa like 'obiekt4'));

-- 4 suma pól buforów dla obiektów bez ³uków
  
select sum(st_area(st_buffer(o.geom,5))) as pole_buforów
 from zadania.obiekty o 
  where st_hasarc(o.geom) is false;