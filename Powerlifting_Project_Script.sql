/*

								                      POWERLIFTING EUROCUP

Datos obtenidos de: 
https://www.kaggle.com/datasets/konstantinmakarenko/debloated-powerlifting-dataset?resource=download

Para añadir más capas a la tabla proncipal creamos:
City & Country - Variables inventadas, se asigna un número aleatorio a cada ID para poder generar la competición

Equipment & Brand - Equipment nos viene dado en la base de datos incial, Brand es una variable inventada con las 25 mejores marcas del mundo del powerlifting

Date - columna con datos aleatorios sobre fechas para poder separar los datos de manera temporal

La competición se celebra anualmente:
2020 - 2021 - 2022 - 2023

Con tres categorías principales:
M(male) - F(Female) - Mx(Neutral)

Cada una de estas categorías tiene restricciones por edad: 
Sub-Junior: 14 - 18 años
Junior: 19 - 23 años
Open: 24 - 39 años
Master 1: 40 - 49 años
Master 2: 50 - 59 años
Master 3: 60 - 69 años
Master 4: +70 años

El usuario es libre de usar el equipo que quiera dentro de los limites establecidos: 
Multi-ply: mono de powerlifting con varias capas de resistencia
Single-ply: mono de powerlifting con una sola capa de resitencia
Wraps: muñequeras
Raw: sin equipamiento
*/

-- Comprobamos la cantidad de participantes que tenemos para cada una de las categorías -- 
-- Creamos una nueva columna con las categorías de los participantes -- 

alter table powerlifting
add Categoria_edad Varchar(100);

update powerlifting 
set Categoria_edad = case 
when floor(age) >= 14 and floor(age) <= 18 then 'Sub-junior'
    when floor(age) >= 19 and floor(age) <= 23 then 'Junior'
    when floor(age) >= 24 and floor(age) <= 39 then 'Open'
    when floor(age) >= 40 and floor(age) <= 49 then 'Master_1'
    when floor(age) >= 50 and floor(age) <= 59 then 'Master_2'
    when floor(age) >= 60 and floor(age) <= 69 then 'Master_3'
    when floor(age) >= 70 then 'Master_4'
    else 'Under-age'
    end
    where id>=0;

 

select 
	sex, 
	categoria_edad, 
	count(categoria_edad) as participantes 
from powerlifting
group by sex, Categoria_edad
order by sex, count(categoria_edad) desc;
-- las categorías con más participantes son la de OPEN y Junior para todos los géneros 

-- Mirar por año.
select 
	right(Date,4) 			as 	Year, 
	count(right(Date,4))	as 	participants 
from powerlifting
group by right(Date,4)
order by right(Date,4);
-- El número de participantes de cada año es similar. 

select date_format(convert(if(length(date)<8,concat(0,date),date), DATE),'%D - %M - %Y') from powerlifting; -- NO FUNCIONA
-- Para hacer lo de date: intentar hacer con todas las columnas con el mismo número de lenght 

select year, count(id) as participants from (
SELECT DATE_FORMAT(
           STR_TO_DATE(
               IF(LENGTH(date) < 8, CONCAT('0', date), date), '%m%d%Y'), 
           '%Y') AS Year,
           id
FROM powerlifting) sub1
group by year
order by year desc;

-- pesos medios de cada categoría 
select 
	Categoria_edad 					as category_Male, 
	round(avg(best3squatKg),2) 		as squat_avg, 
	round(avg(best3benchkg),2) 		as bench_avg, 
	round(avg(best3deadliftkg),2) 	as DL_avg 
from powerlifting
where sex = 'M'
group by Categoria_edad
order by avg(age);

select 
	Categoria_edad 					as category_Female, 
	round(avg(best3squatKg),2) 		as squat_avg, 
	round(avg(best3benchkg),2) 		as bench_avg, 
	round(avg(best3deadliftkg),2) 	as DL_avg 
from powerlifting
where sex = 'F'
group by Categoria_edad
order by avg(age);

select Categoria_edad 				as 	category_Mx, 
	round(avg(best3squatKg),2) 		as 	squat_avg, 
	round(avg(best3benchkg),2) 		as 	bench_avg, 
	round(avg(best3deadliftkg),2)   as 	DL_avg 
from powerlifting
where sex = 'Mx'
group by Categoria_edad
order by avg(age);

-- Países con los participantes más fuertes en promedio
Select 
	c.country, 
	round(avg(best3squatKg),2)	 	as squat_avg, 
	round(avg(best3benchkg),2) 		as bench_avg, 
	round(avg(best3deadliftkg),2) 	as DL_avg 
from powerlifting p 
	left join city ci on ci.City_id = p.city_id
	left join country c on ci.country_id = c.Country_id
group by c.Country
order by avg(p.totalkg) asc
Limit 5; 
-- HACER LA DIFERENCIA ENTRE EL AVG DEL PRIMERO Y EL SEGUNDO

-- Top pesos levantados en cada categoría con usuario y país
select 
    sex,
    id,
    totalKg,
    country
    from (
		select 
			row_number() over(partition by sex order by totalKg desc) as Ranking,
            sex,
            id, 
            totalkg, 
            c.country
		from powerlifting p 
        left join city ci on p.city_id = ci.city_id
        left join country c on ci.country_id = c.country_id) sub1
where Ranking=1
order by totalkg desc;
-- Aquí tenemos el top 1 participantes por género y de qué país son. 


-- Pesos levantados con los diferentes accesorios.
select 
	e.equipment,
	round(avg(p.best3squatKg),2)	 	as squat_avg, 
	round(avg(p.best3benchkg),2) 		as bench_avg, 
	round(avg(p.best3deadliftkg),2) 	as DL_avg
from powerlifting p 
left join equipment e on p.equipment_id = e.equipment_id
group by e.equipment
order by avg(totalkg) desc;

-- Diferencia de levantamiento total entre el equipamiento usado y los pesos levantados por aquellos que van sin equipamiento. Creamos tablas
alter view total_multiply as 
select 
	e.equipment,
    p.best3squatkg,
    p.best3benchkg,
    p.best3deadliftkg,
    p.totalkg
from powerlifting p
	left join equipment e on p.equipment_id = e.equipment_id
where equipment = 'Multi-ply';

create view total_singleply as 
select 
	e.equipment,
    p.best3squatkg,
    p.best3benchkg,
    p.best3deadliftkg,
    p.totalkg
from powerlifting p
	left join equipment e on p.equipment_id = e.equipment_id
where equipment = 'Single-ply';

create view total_raw as 
select 
	e.equipment,
    p.best3squatkg,
    p.best3benchkg,
    p.best3deadliftkg,
    p.totalkg
from powerlifting p
	left join equipment e on p.equipment_id = e.equipment_id
where equipment = 'Raw';

create view total_wraps as 
select 
	e.equipment,
    p.best3squatkg,
    p.best3benchkg,
    p.best3deadliftkg,
    p.totalkg
from powerlifting p
	left join equipment e on p.equipment_id = e.equipment_id
where equipment = 'Wraps';

-- Querieamos para ver la diferencia
select 
	e.equipment,
	concat(
    round(((select avg(totalkg) from total_multiply)/(select avg(totalkg) from total_raw)-1)*100,2)
    ,'%') as diff_multiply_percent,
    concat(
    round(((select avg(totalkg) from total_singleply)/(select avg(totalkg) from total_raw)-1)*100,2)
    ,'%') as diff_singleply_percent,
    concat(
    round(((select avg(totalkg) from total_wraps)/(select avg(totalkg) from total_raw)-1)*100,2)
    ,'%') as diff_wraps_percent
from powerlifting p 
left join equipment e on p.equipment_id = e.equipment_id
where e.equipment='Raw'
group by e.equipment;

-- Ver si en proporción al peso corporal las muejeres siguen levantando menos que los hombres. 

select 
	sex, 
    round(avg(best3squatkg)/avg(Bodyweightkg),2) as squat_relative_stg,
    round(avg(best3benchkg)/avg(Bodyweightkg),2) as bench_relative_stg,
    round(avg(best3deadliftkg)/avg(Bodyweightkg),2) as DL_relative_stg
from powerlifting
where Categoria_edad = 'Open' and Equipment_id = 3
group by sex
;


