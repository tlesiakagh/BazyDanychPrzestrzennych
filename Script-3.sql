-- 1. Dla warstwy trees zmie� ustawienia tak, aby lasy li�ciaste, iglaste i mieszane wy�wietlane by�y innymi kolorami. Podaj pole powierzchni wszystkich las�w o charakterze mieszanym.

select t.vegdesc as typ_lasu, sum(St_area(geom))/(3281^2) as "pole_powierzchni [km^2]"
	from public.trees t 
		where t.vegdesc = 'Mixed Trees'
			group by t.vegdesc;
			
-- 2. Podziel warstw� trees na trzy warstwy. Na ka�dej z nich umie�� inny typ lasu.
		
select t.*
 into Mixed_Trees
  from public.trees t 
   where t.vegdesc = 'Mixed Trees'
			
select t.*
 into Deciduous
  from public.trees t 
   where t.vegdesc = 'Deciduous'
			
select t.*
 into Evergreen
  from public.trees t 
   where t.vegdesc = 'Evergreen'

-- 3. Oblicz d�ugo�� linii kolejowych dla regionu Matanuska-Susitna.

select r2.name_2 as region, sum(st_length(r.geom))/3.281 as "d�ugo��_linii_kolejowej [m]", count(r.geom) as ilo��_odcink�w_w_regionie
 from public.railroads r, public.regions2 r2 
  where r2.name_2 = 'Matanuska-Susitna' and st_crosses(r2.geom, r.geom)
   group by r2.name_2;
		
select r2.name_2 as region, sum(st_length(st_intersection(r.geom, r2.geom)))/3.281 as "d�ugo��_linii_kolejowej [m]", count(r.geom) as ilo��_odcink�w_w_regionie
 from public.railroads r, public.regions2 r2 
  where r2.name_2 = 'Matanuska-Susitna'
   group by r2.name_2;
		
-- 4. Oblicz, na jakiej �redniej wysoko�ci nad poziomem morza po�o�one s� lotniska o charakterze militarnym. Ile jest takich lotnisk? 
		
select a.use as wykorzystanie, avg(a.elev) as "srednia_wysokosc [m n. p. m.]", count(a.gid) as ilosc_lotnisk
 from public.airports a 
  where a.use = 'Military'
   group by a.use;
		
-- Usu� z warstwy airports lotniska o charakterze militarnym, kt�re s� dodatkowo po�o�one powy�ej 1400 m n.p.m. Ile by�o takich lotnisk?
  
delete 
 from public.airports a 
  where a.use = 'Military' and a.elev > 1400;
-- By�o 1 takie lotnisko.
 
-- 5. Utw�rz warstw�, na kt�rej znajdowa� si� b�d� jedynie budynki po�o�one w regionie Bristol Bay (wykorzystaj warstw� popp). Podaj liczb� budynk�w.
 
select p.*
 into popp_Bristol_Bay 
  from public.popp p, public.regions2 r 
   where r.name_2 = 'Bristol Bay' and ST_contains(r.geom, p.geom);
 
select * 
 from popp_bristol_bay pbb;
  
-- Na warstwie zostaw tylko te budynki, kt�re s� po�o�one nie dalej ni� 100 km od rzek (rivers). Ile jest takich budynk�w? 
-- D�ugo�ci podane w stopach, bo uk�ad (2964).

-- Czas wykonania ok. 7s
select distinct pbb.gid 
 from public.popp_bristol_bay pbb, public.rivers r
  where st_contains(st_buffer(r.geom, 100*3281), pbb.geom);

-- Czas wykonania ok. 40ms
select distinct pbb.gid 
 from public.popp_bristol_bay pbb, public.rivers r
  where st_distance(r.geom, pbb.geom) <= 100*3281; 
  
-- 6. Sprawd� w ilu miejscach przecinaj� si� rzeki (majrivers) z liniami kolejowymi (railroads).
 
select sum(st_numgeometries(st_intersection(m.geom, r.geom))) as liczba_przeci��
 from public.majrivers m, public.railroads r
  where st_intersects(m.geom, r.geom);
 
-- 7. Wydob�d� w�z�y dla warstwy railroads. Ile jest takich w�z��w?

select st_npoints(r.geom) as liczba_wierzcho�k�w
 from public.railroads r 
  group by r.exsdesc;
  
-- 8. Wyszukaj najlepsze lokalizacje do budowy hotelu. Hotel powinien by� oddalony od lotniska nie wi�cej ni� 100 km i nie mniej ni� 50 km od linii kolejowych. Powinien le�e� tak�e w pobli�u sieci drogowej.
 
select distinct st_intersection(st_difference(st_buffer(a.geom, 100*3281), st_buffer(r.geom, 50*3281)), st_buffer(t.geom, 10*3281))
 from public.airports a, public.railroads r, public.trails t;

-- 9. Upro�� geometri� warstwy przedstawiaj�cej bagna (swamps). Ustaw tolerancj� na 100. Ile wierzcho�k�w zosta�o zredukowanych? 
-- Czy zmieni�o si� pole powierzchni ca�kowitej wszystkich poligon�w (je�eli tak, to podaj r�nic�)?
 
select 'Bez '||sum(st_npoints(s.geom))||', '||sum(st_area(s.geom)/(3281^2))||' [km^2]'
 from public.swamp s
Union
select 'Douglas '||sum(st_npoints(ST_SimplifyPreserveTopology(s.geom, 100)))||', '||sum(st_area(ST_SimplifyPreserveTopology(s.geom, 100))/(3281^2))||' [km^2]'
 from public.swamp s
Union
select 'Whyatt '||sum(st_npoints(ST_SimplifyVW(s.geom,100)))||', '||sum(st_area(ST_SimplifyVW(s.geom,100))/(3281^2))||' [km^2]'
 from public.swamp s;
  