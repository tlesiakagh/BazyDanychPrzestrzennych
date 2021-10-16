--1 Utworzenie odpowiednich tabel w bazie danych

create table buildings(ID serial, geom geometry(POLYGON, 0), name varchar(30));
create table roads(ID serial, geom geometry(LINESTRING, 0), name varchar(30));
create table poi(ID serial, geom geometry(POINT, 0), name varchar(30));

--2 Wype³nienie tabel

-- Buildings 

insert into buildings (geom, name)
 	values('POLYGON((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))', 'BuildingA');
insert into buildings (geom, name)
 	values('POLYGON((4 7, 6 7, 6 5, 4 5, 4 7))', 'BuildingB');
insert into buildings (geom, name)
 	values('POLYGON((3 8, 5 8, 5 6, 3 6, 3 8))', 'BuildingC');
insert into buildings (geom, name)
 	values('POLYGON((9 9, 10 9, 10 8, 9 8, 9 9))', 'BuildingD');
insert into buildings (geom, name)
	values('POLYGON((1 2, 2 2, 2 1, 1 1, 1 2))', 'BuildingF');

select id, name, geom 
	from buildings;

-- PointOfInterest

insert into poi (geom, name)
 	values('POINT(1 3.5)', 'G');
insert into poi (geom, name)
 	values('POINT(6 9.5)', 'K');
insert into poi (geom, name)
 	values('POINT(6.5 6)', 'J');
insert into poi (geom, name)
 	values('POINT(5.5 1.5)', 'H');
insert into poi (geom, name)
 	values('POINT(9.5 6)', 'I');

select id, name, geom 
	from poi;

-- Roads

insert into roads (geom, name)
 	values('LINESTRING(7.5 10.5, 7.5 0)', 'RoadY');
insert into roads (geom, name)
 	values('LINESTRING(0 4.5, 12 4.5)', 'RoadX');

select id, name, geom 
	from roads;

-- Wypisanie wszystkich obiektów

select name, geom 
	from zadania.buildings
Union
select name, geom 
	from zadania.poi
Union
select name, geom 
	from zadania.roads;

--3 Zapytania

--a

select sum(st_length(r.geom)) as ca³kowita_dlugoœæ_dróg 
 	from roads r;

--b

select st_astext(b.geom) as WKT, st_area(b.geom) as pole_powierzchni, st_perimeter(b.geom) as obwód  
 	from buildings b 
  		where name like 'BuildingA';

--c 

select b.name as nazwa_budynku, st_area(b.geom) as pole_powierzchni
	from buildings b 
  		order by b.name;
  		
--d 

select b.name as nazwa_budynku, st_perimeter(b.geom) as obwód
	from buildings b 
		order by st_area(b.geom) desc
			limit 2;

--e
 
select st_distance(b.geom, p.geom) as odleg³oœæ
	from buildings b, poi p 
		where b.name like 'BuildingC' and p.name like 'G';

--f
	
select st_area(st_difference(b.geom, (select st_buffer(b.geom, 0.5, 'side=left') 
										from buildings b 
											where b.name like 'BuildingB'))) as pole_wycinka
	from buildings b
		where b.name like 'BuildingC';
	
--g

select b.name as nazwa_budynku 	
	from buildings b
		where st_y(st_centroid(b.geom)) > st_y((select ST_PointOnSurface(r.geom) 
													from roads r 
														where r.name like 'RoadX')); 

--h

select st_area(st_symdifference(b.geom, st_geomfromtext('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))', 0))) as pole_wycinka
	from buildings b 
		where b.name like 'BuildingC';
													
