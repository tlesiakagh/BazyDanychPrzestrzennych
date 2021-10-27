-- 4. Wyznacz liczbê budynków (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty) po³o¿onych w odleg³oœci mniejszej ni¿ 1000 m od g³ównych rzek. 
--    Budynki spe³niaj¹ce to kryterium zapisz do osobnej tabeli tableB.

-- Distinct, aby tylko raz zapisa³o budynek, który spe³nia kryterium dla wiêkszej iloœci rzek
drop table public.tableb ;

select distinct * 
	into public.tableB 
		from (select p.* from public.popp p, public.majrivers r where ST_ContainsProperly(st_buffer(r.geom, 1000), p.geom) = true and p.f_codedesc like 'Building') as foo;

select * from public.tableb;

select count(geom) as liczba_budynków
	from public.tableb;

-- 5. Utwórz tabelê o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich geometriê, a tak¿e atrybut elev, reprezentuj¹cy wysokoœæ n.p.m.

drop table public.airportsnew ;

select a.gid, a."name", a.geom, a.elev
	into airportsNew
		from airports a;

select * from airportsNew a 

-- 5a. ZnajdŸ lotnisko, które po³o¿one jest najbardziej na zachód i najbardziej na wschód. (st_y, bo w uk³adzie geodezyjnym oœ Y jest osi¹ poziom¹)
	
select a."name" as max_W
	from public.airportsnew a
		order by st_y(a.geom) asc
			limit 1;
	
select a."name" as max_E
	from public.airportsnew a
		order by st_y(a.geom) desc
			limit 1;
	
-- 5b. Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które po³o¿one jest w punkcie œrodkowym drogi pomiêdzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB. Wysokoœæ n.p.m. przyjmij dowoln¹.
		
insert into public.airportsnew 
	values (77, 'airportB', st_centroid(st_shortestline((select a.geom from public.airportsnew a order by st_y(a.geom) desc limit 1),(select a.geom from public.airportsnew a order by st_y(a.geom) asc limit 1))), 98);

select * from public.airportsnew a ;
		
-- 6. Wyznacz pole powierzchni obszaru, który oddalony jest mniej ni¿ 1000 jednostek od najkrótszej linii ³¹cz¹cej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”.

select st_area(st_buffer(st_shortestLine(l.geom, a.geom), 1000)) as pole_wycinka
	from public.lakes l, public.airports a 
		where l.names like 'Iliamna Lake' and a."name" like 'AMBLER';

-- 7. Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentuj¹cych poszczególne typy drzew znajduj¹cych siê na obszarze tundry i bagien (swamps).  

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