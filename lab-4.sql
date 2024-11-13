-- Лабораторная работа 4 (глава 5)


-- Задание 1

SELECT count( * ) FROM tickets; -- 366733
SELECT count( * ) FROM tickets WHERE passenger_name LIKE '% %'; -- 366733
SELECT count( * ) FROM tickets WHERE passenger_name LIKE '% % %'; -- 0
SELECT count( * ) FROM tickets WHERE passenger_name LIKE '% %%'; -- 366733

-- Можем сделать вывод, что символ % в шаблоне соответствует любому количеству любых символов строки, кроме пробела - так, при использовании шаблонов '% %' и '% %%' выбираются все доступные строки (состоящие из разделенных одним пробелом двух слов из латинских символов), поскольку как '%', так и '%%' - любое количество непробельных символов, в то время как при использовании шаблона '% % %' не выбирается ни одной строки (поскольку в них для соответствия шаблону должно содержаться не менее двух пробелов).



-- Задание 2

-- Выбор всех пассажиров с фамилиями, состоящими из 5 букв
SELECT passenger_name
FROM tickets
WHERE passenger_name LIKE '% _____';


-- Задание 3

SELECT 'abc' SIMILAR TO 'abc'; -- true
SELECT 'abc' SIMILAR TO 'a'; -- false
SELECT 'abc' SIMILAR TO '%(b|d)%'; -- true
SELECT 'abc' SIMILAR TO '(b|c)%'; --false
SELECT '-abc-' SIMILAR TO '%\mabc\M%'; -- true
SELECT 'xabcy' SIMILAR TO '%\mabc\M%'; -- false
SELECT 'a35ab64d' SIMILAR TO '_[a-d3-6]{4,}'; -- true
SELECT 'x35ab64d' SIMILAR TO '_[a-d3-6]{4,}'; -- true
SELECT 'a35aAb64d' SIMILAR TO '_[a-d3-6]{4,}'; --false
SELECT 'a35a8b64d' SIMILAR TO '_[a-d3-6]{4,}'; --false
SELECT 'a45b' SIMILAR TO '_[a-d3-6]{4,}'; -- false
SELECT 'a45bc' SIMILAR TO '_[a-d3-6]{4,}'; -- trues


-- Задание 4

SELECT 2 BETWEEN SYMMETRIC 3 AND 1; -- true
SELECT 2 NOT BETWEEN SYMMETRIC 3 AND 1; -- false
SELECT 1 IS DISTINCT FROM NULL; -- true
SELECT NULL IS DISTINCT FROM NULL; -- false
SELECT 1.5 IS NULL; -- false 
SELECT NULL IS NULL; -- true
SELECT 'null' IS NOT NULL; -- true
SELECT true IS TRUE; -- true
SELECT NULL::boolean IS TRUE; -- false
SELECT true IS UNKNOWN; -- false
SELECT NULL::boolean IS UNKNOWN; -- true


-- Задание 5

SELECT COALESCE(NULL, 123, NULL, 54, NULL); -- 123
SELECT COALESCE(TRUE, NULL, FALSE, NULL, NULL); -- true
SELECT COALESCE(NULL, NULL, 'abc', 'def'); -- abc

SELECT NULLIF('abc', 'none'); -- abc
SELECT NULLIF('none', 'none'); -- null
SELECT NULLIF(NULL, 'none'); -- null

SELECT GREATEST(1, 6, 2, 7, 1, 7, 9, 5); -- 9
SELECT GREATEST(NULL, 6, 2, NULL, 1, NULL, NULL, 5); -- 6
SELECT GREATEST(NULL, NULL, NULL); -- null

SELECT LEAST(1, 6, 2, 7, 1, 7, 9, 5); -- 1
SELECT LEAST(NULL, 6, NULL, NULL, 7, 7, 9, 5); -- 5
SELECT LEAST(NULL, NULL, NULL); -- null


-- Задание 6

SELECT
	r.flight_no,
	r.departure_airport,
	r.departure_airport_name,
	r.departure_city,
	r.arrival_airport,
	r.arrival_airport_name,
	r.arrival_city,
	a.model->>'en' AS aircraft_model_name,
	r.duration,
	r.days_of_week
FROM routes AS r
JOIN aircrafts_data AS a
	ON r.aircraft_code = a.aircraft_code
WHERE a.model->>'en' ~ 'Boeing';


-- Задание 7

SELECT DISTINCT departure_city, arrival_city
FROM routes r
JOIN aircrafts_data a
	ON r.aircraft_code = a.aircraft_code AND arrival_city < departure_city
WHERE a.model->>'en' = 'Boeing 777-300'
ORDER BY 1;


-- Задание 8

-- Найти все самолёты, которые не работают ни на одном маршруте, а также маршруты, у которых нет самолёта
SELECT *
FROM routes r FULL OUTER JOIN aircrafts a
	ON r.aircraft_code = a.aircraft_code
WHERE r.aircraft_code IS NULL OR a.aircraft_code IS NULL;


-- Задание 9

SELECT departure_city, arrival_city, count( * )
FROM routes
GROUP BY departure_city, arrival_city
HAVING departure_city = 'Москва' AND arrival_city = 'Санкт-Петербург';


-- Задание 10

SELECT departure_city, count( DISTINCT arrival_city )
FROM routes
GROUP BY departure_city
ORDER BY count DESC;


-- Задание 11

SELECT
	arrival_city,
	count( * ) AS routes_number
FROM routes
WHERE array_length(days_of_week, 1) = 7 AND departure_city = 'Москва'
GROUP BY arrival_city
ORDER BY routes_number DESC
LIMIT 5;


-- Задание 12*
--============


-- Задание 13

SELECT
	f.departure_city,
	f.arrival_city,
	max( tf.amount ),
	min( tf.amount )
FROM flights_v f
LEFT JOIN ticket_flights tf ON f.flight_id = tf.flight_id
GROUP BY 1, 2
ORDER BY 1, 2;


-- Задание 14

SELECT
	(regexp_match(passenger_name, '^(\w+) (\w+)$'))[2] AS firstname,
	count( * )
FROM tickets
GROUP BY 1
ORDER BY 2 DESC;


-- Задание 15*
--============


-- Задание 16*
--============


-- Задание 17

SELECT
	s.aircraft_code,
	a.model->>'en',
	s.fare_conditions,
	count( * )
FROM seats s
JOIN aircrafts_data a ON s.aircraft_code = a.aircraft_code
GROUP BY s.aircraft_code, a.model, s.fare_conditions
ORDER BY aircraft_code;


-- Задание 18

SELECT
	a.aircraft_code,
	a.model,
	count( r.aircraft_code ) AS num_routes,
	round( count( r.aircraft_code )::numeric / ( SELECT count( * ) FROM routes ), 3 )
FROM routes r
RIGHT JOIN aircrafts a ON r.aircraft_code = a.aircraft_code
GROUP BY 1, 2
ORDER BY 3 DESC;


-- Задание 19*
--============


-- Задание 20*
--============


-- Задание 21

SELECT city
	FROM airports
	WHERE city <> 'Москва'
EXCEPT -- поскольку нам необходимо из множества всех городов аэропортов, кроме Москвы, исключить множество тех городов, в которые есть рейсы из Моксквы
SELECT arrival_city
	FROM routes
	WHERE departure_city = 'Москва'
ORDER BY city;



-- Задание 22

SELECT aa.city, aa.airport_code, aa.airport_name
FROM (
	SELECT city, count( * )
	FROM airports
	GROUP BY city
	HAVING count( * ) > 1
) AS a
JOIN airports AS aa ON a.city = aa.city
ORDER BY aa.city, aa.airport_name;

-- Предположительно, наличие функции count в подзапросе обязательно, поскольку она используется в условии HAVING, которое проверяется уже после группировки -- соответственно, на этом этапе, если не включить в выборку во время группировки count( * ), информация о количестве аэропортов в городе будет утеряна. Проверим эту гипотезу на практике:

SELECT aa.city, aa.airport_code, aa.airport_name
FROM (
	SELECT city
	FROM airports
	GROUP BY city
	HAVING count( * ) > 1
) AS a
JOIN airports AS aa ON a.city = aa.city
ORDER BY aa.city, aa.airport_name;

--    city    | airport_code |    airport_name     
-- -----------+--------------+---------------------
--  Москва    | VKO          | Внуково
--  Москва    | DME          | Домодедово
--  Москва    | SVO          | Шереметьево
--  Ульяновск | ULV          | Баратаевка
--  Ульяновск | ULY          | Ульяновск-Восточный
-- (5 rows)

-- Как видим, наша гипотеза оказалась ошибочной -- вывод получился таким же, как и в исходном запросе. Вероятно, СУБД в таких случаях заранее проверяет, какие агрегатные функции будут использоваться далее в запросе, и неявно сохраняет их в памяти с возможностью дальнейшего использования.


-- Задание 23

WITH cities_with_airport AS (
	SELECT DISTINCT city FROM airports
)
SELECT count( * )
FROM cities_with_airport AS a1
JOIN cities_with_airport AS a2
ON a1.city <> a2.city;

-- Задание 24

SELECT * FROM airports
WHERE timezone IN ( 'Asia/Novokuznetsk', 'Asia/Krasnoyarsk' );

SELECT * FROM airports
WHERE timezone = ANY (
	VALUES ( 'Asia/Novokuznetsk' ), ( 'Asia/Krasnoyarsk' )
);

-- Одинаковый вывод, т. е. IN эквивалентно = ANY (действительно, элемент находится в списке, когда он равен хотя бы одному элементу списка).

SELECT departure_city, count( * )
FROM routes
GROUP BY departure_city
HAVING departure_city IN (
	SELECT city
	FROM airports
	WHERE coordinates[0] > 150
)
ORDER BY count DESC;

SELECT departure_city, count( * )
FROM routes
GROUP BY departure_city
HAVING departure_city = ANY (
	SELECT city
	FROM airports
	WHERE coordinates[0] > 150
)
ORDER BY count DESC;

-- Аналогично, вывод одинаковый.


-- Задание 25*
--============


-- Задание 26*
--============

