-- 4. Wyznacz liczb� budynk�w (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty) po�o�onych w odleg�o�ci mniejszej ni� 1000 m od g��wnych rzek. 
--    Budynki spe�niaj�ce to kryterium zapisz do osobnej tabeli tableB.

-- Distinct, aby tylko raz zapisa�o budynek, kt�ry spe�nia kryterium dla wi�kszej ilo�ci rzek
drop table public.tableb ;

select distinct * 
	into public.tableB 
		from (select p.* from public.popp p, public.majrivers r where ST_ContainsProperly(st_buffer(r.geom, 1000), p.geom) = true and p.f_codedesc like 'Building') as foo;

select * from public.tableb;

select count(geom) as liczba_budynk�w
	from public.tableb;

-- 5. Utw�rz tabel� o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich geometri�, a tak�e atrybut elev, reprezentuj�cy wysoko�� n.p.m.

drop table public.airportsnew ;

select a.gid, a."name", a.geom, a.elev
	into airportsNew
		from airports a;

select * from airportsNew a 

-- 5a. Znajd� lotnisko, kt�re po�o�one jest najbardziej na zach�d i najbardziej na wsch�d. (st_y, bo w uk�adzie geodezyjnym o� Y jest osi� poziom�)
	
select a."name" as max_W
	from public.airportsnew a
		order by st_y(a.geom) asc
			limit 1;
	
select a."name" as max_E
	from public.airportsnew a
		order by st_y(a.geom) desc
			limit 1;
	
-- 5b. Do tabeli airportsNew dodaj nowy obiekt - lotnisko, kt�re po�o�one jest w punkcie �rodkowym drogi pomi�dzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB. Wysoko�� n.p.m. przyjmij dowoln�.
		
insert into public.airportsnew 
	values (77, 'airportB', st_centroid(st_shortestline((select a.geom from public.airportsnew a order by st_y(a.geom) desc limit 1),(select a.geom from public.airportsnew a order by st_y(a.geom) asc limit 1))), 98);

select * from public.airportsnew a ;
		
-- 6. Wyznacz pole powierzchni obszaru, kt�ry oddalony jest mniej ni� 1000 jednostek od najkr�tszej linii ��cz�cej jezioro o nazwie �Iliamna Lake� i lotnisko o nazwie �AMBLER�.

select st_area(st_buffer(st_shortestLine(l.geom, a.geom), 1000)) as pole_wycinka
	from public.lakes l, public.airports a 
		where l.names like 'Iliamna Lake' and a."name" like 'AMBLER';

-- 7. Napisz zapytanie, kt�re zwr�ci sumaryczne pole powierzchni poligon�w reprezentuj�cych poszczeg�lne typy drzew znajduj�cych si� na obszarze tundry i bagien (swamps).  

select vegdesc as rodzaj, sum(pole) as pole
from((select sum(st_area(st_intersection(st_makevalid(t.geom), st_makevalid(t2.geom)))) as pole, t.vegdesc 
		from public.tundra t2, public.trees t
			group by t.vegdesc)
	Union
	(select sum(st_area(st_intersection(st_makevalid(t.geom), st_makevalid(s.geom)))) as pole, t.vegdesc 
		from public.swamp s, public.trees t
			group by t.vegdesc)
	) as foo
group by vegdesc;