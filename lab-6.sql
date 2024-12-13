-- Лабораторная работа 6

-- Глава 9

DROP TABLE IF EXISTS aircrafts_tmp;
CREATE TABLE aircrafts_tmp AS
	SELECT
		aircraft_code,
		model ->> 'en' AS model,
		range
	FROM aircrafts_data ml;


-- Задание 1

-- SELECT ... FOR UPDATE

-- 1
BEGIN;

SELECT *
FROM aircrafts_tmp
WHERE model ~ '^Air'
FOR UPDATE;


-- 2
SELECT *
FROM aircrafts_tmp
WHERE model ~ '^Air'
FOR UPDATE;


-- 1
UPDATE aircrafts_tmp
SET range = 5800
WHERE aircraft_code = '320';

COMMIT;

-- 2
--  aircraft_code |      model      | range
-- ---------------+-----------------+-------
--  320           | Airbus A320-200 |  5800
--  321           | Airbus A321-200 |  5600
--  319           | Airbus A319-100 |  6700

-- SELECT ... LOCK TABLE

-- 1
BEGIN;

LOCK TABLE aircrafts_tmp
    IN ACCESS EXCLUSIVE MODE;
    LOCK TABLE;

-- 2
SELECT *
FROM aircrafts_tmp
WHERE model ~ '^Air';

-- 1
ROLLBACK;

-- 2
--  aircraft_code |      model      | range
-- ---------------+-----------------+-------
--  320           | Airbus A320-200 |  5700
--  321           | Airbus A321-200 |  5600
--  319           | Airbus A319-100 |  6700



-- Задание 2

-- 1
BEGIN;

SELECT *
FROM aircrafts_tmp
WHERE range < 2000;
--  aircraft_code |       model        | range
-- ---------------+--------------------+-------
--  CN1           | Cessna 208 Caravan |  1200

UPDATE aircrafts_tmp
SET range = 2100
WHERE aircraft_code = 'CN1';

UPDATE aircrafts_tmp
SET range = 1900
WHERE aircraft_code = 'CR2';

-- 2

BEGIN;

SELECT *
FROM aircrafts_tmp
WHERE range < 2000;

--  aircraft_code |       model        | range
-- ---------------+--------------------+-------
--  CN1           | Cessna 208 Caravan |  1200

DELETE FROM aircrafts_tmp WHERE range < 2000 RETURNING *;

-- 1
ROLLBACK;

-- 2

--  aircraft_code |       model        | range
-- ---------------+--------------------+-------
--  CN1           | Cessna 208 Caravan |  1200
-- (1 row)

-- DELETE 1

-- Как видим, был удалён изначально выбранный самолёт (Cessna), поскольку первая транзакция была отменена (ROLLBACK) и, следовательно, результат пересчёта условия WHERE в DELETE после снятия блокировки не изменился.



-- Задание 3*
--===========



-- Задание 4

-- 1
BEGIN;

SELECT *
FROM aircrafts_tmp
WHERE range > 6000;
--  aircraft_code |      model      | range
-- ---------------+-----------------+-------
--  773           | Boeing 777-300  | 11100
--  763           | Boeing 767-300  |  7900
--  319           | Airbus A319-100 |  6700

-- 2

BEGIN;

INSERT INTO aircrafts_tmp
    VALUES ('TST', 'Test aircraft', 12000);

COMMIT;

-- 1

SELECT *
FROM aircrafts_tmp
WHERE range > 6000;
--  aircraft_code |      model      | range
-- ---------------+-----------------+-------
--  773           | Boeing 777-300  | 11100
--  763           | Boeing 767-300  |  7900
--  319           | Airbus A319-100 |  6700
--  TST           | Test aircraft   | 12000

COMMIT;



-- Задание 5

-- 1
BEGIN;

SELECT * FROM aircrafts_tmp WHERE model ~ '^Air' FOR UPDATE;
--  aircraft_code |      model      | range
-- ---------------+-----------------+-------
--  320           | Airbus A320-200 |  5700
--  321           | Airbus A321-200 |  5600
--  319           | Airbus A319-100 |  6700

-- 2

SELECT * FROM aircrafts_tmp WHERE aircraft_code = '773' FOR UPDATE; -- не пересекаются, блокировки нет
--  aircraft_code |     model      | range
-- ---------------+----------------+-------
--  773           | Boeing 777-300 | 11100


SELECT * FROM aircrafts_tmp WHERE aircraft_code IN ( '773', '320' ) FOR UPDATE; -- пересекаются, запрос блокируется

SELECT * FROM aircrafts_tmp WHERE aircraft_code IN ( '320' ) FOR UPDATE; -- подмножество, запрос блокируется

SELECT * FROM aircrafts_tmp FOR UPDATE; -- надмножество, запрос блокируется

-- 1
COMMIT;

-- Таким образом, блокировка запроса во втором терминале не возникает лишь в том случае, если множество выбранных для модификации строк не пересекается с множеством заблокированных в другой транзакции (в первом терминале) строк. Иными словами, если среди модифицируемых строк есть хотя бы одна заблокированная другой транзакцией, то такой запрос блокируется до завершения всех транзакций, которые блокируют какую-либо из модифицируемых строк.



-- Задание 6

-- 1
BEGIN;

SELECT * FROM aircrafts_tmp FOR SHARE;
--  aircraft_code |        model        | range
-- ---------------+---------------------+-------
--  773           | Boeing 777-300      | 11100
--  763           | Boeing 767-300      |  7900
--  SU9           | Sukhoi Superjet-100 |  3000
--  320           | Airbus A320-200     |  5700
--  321           | Airbus A321-200     |  5600
--  319           | Airbus A319-100     |  6700
--  733           | Boeing 737-300      |  4200
--  CN1           | Cessna 208 Caravan  |  1200
--  CR2           | Bombardier CRJ-200  |  2700

-- 2
BEGIN;

SELECT * FROM aircrafts_tmp FOR SHARE;
--  aircraft_code |        model        | range
-- ---------------+---------------------+-------
--  773           | Boeing 777-300      | 11100
--  763           | Boeing 767-300      |  7900
--  SU9           | Sukhoi Superjet-100 |  3000
--  320           | Airbus A320-200     |  5700
--  321           | Airbus A321-200     |  5600
--  319           | Airbus A319-100     |  6700
--  733           | Boeing 737-300      |  4200
--  CN1           | Cessna 208 Caravan  |  1200
--  CR2           | Bombardier CRJ-200  |  2700

-- 1
SELECT * FROM aircrafts_tmp WHERE aircraft_code = '320' FOR UPDATE; -- запрос блокируется

-- 2
SELECT * FROM aircrafts_tmp FOR SHARE;
--  aircraft_code |        model        | range
-- ---------------+---------------------+-------
--  773           | Boeing 777-300      | 11100
--  763           | Boeing 767-300      |  7900
--  SU9           | Sukhoi Superjet-100 |  3000
--  320           | Airbus A320-200     |  5700
--  321           | Airbus A321-200     |  5600
--  319           | Airbus A319-100     |  6700
--  733           | Boeing 737-300      |  4200
--  CN1           | Cessna 208 Caravan  |  1200
--  CR2           | Bombardier CRJ-200  |  2700

COMMIT;

-- 1
--  aircraft_code |      model      | range  -- блокировка снята
-- ---------------+-----------------+-------
--  320           | Airbus A320-200 |  5700

-- 2
SELECT * FROM aircrafts_tmp FOR SHARE; -- запрос блокируется, поскольку теперь он заблокирован для обновления транзакцией в терминале 1

-- 1
COMMIT;

-- 2
--  aircraft_code |        model        | range  -- блокировка снята
-- ---------------+---------------------+-------
--  773           | Boeing 777-300      | 11100
--  763           | Boeing 767-300      |  7900
--  SU9           | Sukhoi Superjet-100 |  3000
--  320           | Airbus A320-200     |  5700
--  321           | Airbus A321-200     |  5600
--  319           | Airbus A319-100     |  6700
--  733           | Boeing 737-300      |  4200
--  CN1           | Cessna 208 Caravan  |  1200
--  CR2           | Bombardier CRJ-200  |  2700

-- Таким образом, вызывая в транзакции SELECT ... FOR SHARE, мы получаем гарантию, что до конца нашей транзакции никто не сможет изменить эти строки, то есть далее в транзакции их можно считывать/использовать повторно при необходимости и получать фиксированный результат. Но при этом, другие транзакции всё также могут без блокировки осуществлять блокирующее чтение (с помощью того же SELECT ... FOR SHARE), гарантируя себе тот же самый эффект (при использовании же SELECT ... FOR UPDATE, другие транзакции смогут осуществлять лишь неблокирующее чтение этих строк, то есть без гарантии их дальнейшей неизменности).


-- Задание 7

-- 1
BEGIN;

SELECT * FROM aircrafts_tmp FOR SHARE;
--  aircraft_code |        model        | range
-- ---------------+---------------------+-------
--  773           | Boeing 777-300      | 11100
--  763           | Boeing 767-300      |  7900
--  SU9           | Sukhoi Superjet-100 |  3000
--  320           | Airbus A320-200     |  5700
--  321           | Airbus A321-200     |  5600
--  319           | Airbus A319-100     |  6700
--  733           | Boeing 737-300      |  4200
--  CN1           | Cessna 208 Caravan  |  1200
--  CR2           | Bombardier CRJ-200  |  2700


-- 2
BEGIN;

SELECT * FROM aircrafts_tmp WHERE aircraft_code = '320' FOR UPDATE; -- вызов заблокирован


-- 3
BEGIN;

SELECT * FROM aircrafts_tmp FOR SHARE;
--  aircraft_code |        model        | range
-- ---------------+---------------------+-------
--  773           | Boeing 777-300      | 11100
--  763           | Boeing 767-300      |  7900
--  SU9           | Sukhoi Superjet-100 |  3000
--  320           | Airbus A320-200     |  5700
--  321           | Airbus A321-200     |  5600
--  319           | Airbus A319-100     |  6700
--  733           | Boeing 737-300      |  4200
--  CN1           | Cessna 208 Caravan  |  1200
--  CR2           | Bombardier CRJ-200  |  2700


-- 4
BEGIN;

SELECT * FROM aircrafts_tmp WHERE aircraft_code = '320' FOR UPDATE; -- вызов заблокирован


-- 1
COMMIT;


-- 3
COMMIT;


-- 2
--  aircraft_code |      model      | range
-- ---------------+-----------------+-------
--  320           | Airbus A320-200 |  5700


-- 1
BEGIN;

SELECT * FROM aircrafts_tmp FOR SHARE; -- вызов заблокирован


-- 2
COMMIT;


-- 4
--  aircraft_code |      model      | range
-- ---------------+-----------------+-------
--  320           | Airbus A320-200 |  5700

COMMIT;


-- 1
--  aircraft_code |        model        | range
-- ---------------+---------------------+-------
--  773           | Boeing 777-300      | 11100
--  763           | Boeing 767-300      |  7900
--  SU9           | Sukhoi Superjet-100 |  3000
--  320           | Airbus A320-200     |  5700
--  321           | Airbus A321-200     |  5600
--  319           | Airbus A319-100     |  6700
--  733           | Boeing 737-300      |  4200
--  CN1           | Cessna 208 Caravan  |  1200
--  CR2           | Bombardier CRJ-200  |  2700

COMMIT;



-- Задание 8*
--===========


-- Задание 9*
--===========



-- Задание 10*
--===========



-- Глава 10

-- Задание 1

EXPLAIN
	SELECT *
	FROM bookings
	ORDER BY book_ref;
--                                       QUERY PLAN                                       
-- ---------------------------------------------------------------------------------------
--  Index Scan using bookings_pkey on bookings  (cost=0.42..8549.24 rows=262788 width=21)
-- (1 row)

-- Вероятнее всего небольшая задержка первых результатов при просмотре по индексу связана с тем, что для начала обхода b-дерева (с помощью которого построен индекс), необходимо спуститься по дереву от корня до первого элемента, а это хотя и происходит крайне быстро, но всё же занимает некоторое время.



-- Задание 2

-- При использовании ORDER BY по столбцу, по которому создан индекс, этот индекс не всегда будет использован. Например:

CREATE INDEX ON aircrafts_data ( range );

EXPLAIN SELECT * FROM aircrafts_data ORDER BY range;
--                              QUERY PLAN                              
-- ---------------------------------------------------------------------
--  Sort  (cost=1.23..1.26 rows=9 width=52)
--    Sort Key: range
--    ->  Seq Scan on aircrafts_data  (cost=0.00..1.09 rows=9 width=52)

DROP INDEX aircrafts_data_range_idx;

-- Вероятно это связано с тем, что таблица aircrafts_data содержит крайне мало данных (9 строк), и планировщик посчитал, что получение доступа к индексу и его обход окажется дороже, чем последовательное считывание всех данных в память и их ручную сортировку (также в памяти).



-- Задание 3

WITH aircraft_seats_count AS (
	SELECT
		aircraft_code,
		count( * ) AS seats_count
	FROM seats
	GROUP BY aircraft_code
)
SELECT
	a.model ->> 'en' AS aircraft_model,
	sc.seats_count
FROM aircrafts_data a
JOIN aircraft_seats_count sc ON a.aircraft_code = sc.aircraft_code
WHERE sc.seats_count < ( SELECT avg( seats_count ) FROM aircraft_seats_count );
--                                      QUERY PLAN                                     
-- ------------------------------------------------------------------------------------
--  Hash Join  (cost=28.65..29.81 rows=3 width=40)
--    Hash Cond: (a.aircraft_code = sc.aircraft_code)
--    CTE aircraft_seats_count -- формирование CTE
--      ->  HashAggregate  (cost=28.09..28.18 rows=9 width=12)
--            Group Key: seats.aircraft_code
--            ->  Seq Scan on seats  (cost=0.00..21.39 rows=1339 width=4)
--    InitPlan 2
--      ->  Aggregate  (cost=0.20..0.21 rows=1 width=32)
--            ->  CTE Scan on aircraft_seats_count  (cost=0.00..0.18 rows=9 width=8) -- сканирование CTE для нахождения среднего количества сидений в самолетах
--    ->  Seq Scan on aircrafts_data a  (cost=0.00..1.09 rows=9 width=48)
--    ->  Hash  (cost=0.23..0.23 rows=3 width=24)
--          ->  CTE Scan on aircraft_seats_count sc  (cost=0.00..0.23 rows=3 width=24) -- сканирование CTE для соединения с таблицей самолётов
--                Filter: ((seats_count)::numeric < (InitPlan 2).col1)


-- Задание 4

EXPLAIN
SELECT total_amount
FROM bookings
ORDER BY total_amount DESC
LIMIT 5;
--                                         QUERY PLAN                                         
-- -------------------------------------------------------------------------------------------
-- Вывод результата, ограниченный 5 штуками (поэтому rows=5, т.к. СУБД заранее знает точное количество строк, которые будут выведены на этом этапе). Ширина всё также не изменилась: width = 6. cost=6825.36..6825.93 -- вывод начнётся одновременно с получением первого результата из предыдущего узла (6825 у.е. времени), и почти сразу же закончится, поскольку нам требуется всего 5 строк.
--  Limit  (cost=6825.36..6825.93 rows=5 width=6)
-- Результаты параллельного исполнения сливаются, причём первая строка будет получена в 6825 у.е. времени (почти сразу после коцна сортировки), а последняя - в 24602 у.е. времени. Как и в прошлый раз, rows=154581 width=6, поскольку данные не изменились
--    ->  Gather Merge  (cost=6825.36..24602.17 rows=154581 width=6)
-- Сортировка исполняется параллельно (однако, всего с 1 worker'ом)
--          Workers Planned: 1
-- Сортировка строк с предыдущего узла. cost=5825.35..6211.80 говорит о том, что первая отсортированная строка будет передана далее в 5825 у.е. времени (что позже, чем будут получены все строки с предыдущего этапа, т.к. при сортировке для нахождения первого отсортированного элемента тоже требуется время), а последняя - в 6211 у.е. времени. Поскольку сортировка не меняет ширины и количество строк, rows=154581 width=6, как и на предыдущем этапе
--          ->  Sort  (cost=5825.35..6211.80 rows=154581 width=6)
-- По каким столбцам и в каком порядке будут требуется отсортировать строки с предыдущего узла
--                Sort Key: total_amount DESC
-- Последовательное чтение строк таблицы bookings (а именно, значений total_amount - его width = 6). cost=0.00..3257.81 говорит о том, что данные из этого узла начнут передаваться далее сразу же, а закончат - в 3257 у.е. времени (если, конечно, понадобится вся таблица). rows=154581 - предсказание количества строк, формируемых этим узлом
--                ->  Parallel Seq Scan on bookings  (cost=0.00..3257.81 rows=154581 width=6)



-- Задание 5

EXPLAIN
SELECT city, count( * )
FROM airports
GROUP BY city
HAVING count( * ) > 1;
--                                 QUERY PLAN                                
-- --------------------------------------------------------------------------
--  HashAggregate  (cost=30.82..40.67 rows=34 width=40)
--    Group Key: (ml.city ->> lang())
--    Filter: (count(*) > 1)
--    ->  Seq Scan on airports_data ml  (cost=0.00..30.30 rows=104 width=32)

-- Вывод строк из HashAggregate (30.82 у.е. времени) начинается не сразу же после получения последней строки из Seq Scan (30.30 у.е. времени), поскольку после получения всех данных их необходимо предварительно обработать -- в частности, создать хеш-таблицу, без которой невозможно даже начать выводить данные.



-- Задание 6

EXPLAIN
SELECT airport_name,
	city,
	round( coordinates[1]::numeric, 2 ) AS ltd,
	timezone,
	rank() OVER (
		PARTITION BY timezone
		ORDER BY coordinates[1] DESC
	)
FROM airports
WHERE timezone IN ( 'Asia/Irkutsk', 'Asia/Krasnoyarsk' );
--                                      QUERY PLAN                                     
-- ------------------------------------------------------------------------------------
--  WindowAgg  (cost=4.54..11.43 rows=13 width=127)
--    ->  Sort  (cost=4.54..4.57 rows=13 width=149)
--          Sort Key: ml.timezone, (ml.coordinates[1]) DESC
--          ->  Seq Scan on airports_data ml  (cost=0.00..4.30 rows=13 width=149)
--                Filter: (timezone = ANY ('{Asia/Irkutsk,Asia/Krasnoyarsk}'::text[]))

-- WindowAgg требуются данные в отсортированном порядке (по часовому поясу и широте, поскольку сортировка по часовому поясу позволяет отделять разделы, а сортировка по широте требуется для подсчёта ранга каждой строки в разделе), причём он сразу начинает выводить данные, как только поступила первая строка с Sort (4.54 у.е. времени).



-- Задание 7

-- CREATE TEMP TABLE aircrafts_tmp ...

CREATE 

BEGIN;

EXPLAIN ANALYZE
DELETE FROM aircrafts_tmp
WHERE range < 5000;
--                                                    QUERY PLAN                                                   
-- ----------------------------------------------------------------------------------------------------------------
--  Delete on aircrafts_tmp  (cost=0.00..22.75 rows=0 width=0) (actual time=0.026..0.027 rows=0 loops=1)
--    ->  Seq Scan on aircrafts_tmp  (cost=0.00..22.75 rows=340 width=6) (actual time=0.010..0.012 rows=4 loops=1)
--          Filter: (range < 5000)
--          Rows Removed by Filter: 5
--  Planning Time: 0.091 ms
--  Execution Time: 0.065 ms

ROLLBACK;


BEGIN;

EXPLAIN ANALYZE
INSERT INTO aircrafts_tmp VALUES
	('TS1', 'Test aircraft 1', 1111),
	('TS2', 'Test aircraft 2', 2222),
	('TS3', 'Test aircraft 3', 3333),
	('TS4', 'Test aircraft 4', 4444),
	('TS5', 'Test aircraft 5', 5555);
--                                                   QUERY PLAN                                                  
-- --------------------------------------------------------------------------------------------------------------
--  Insert on aircrafts_tmp  (cost=0.00..0.06 rows=0 width=0) (actual time=0.275..0.276 rows=0 loops=1)
--    ->  Values Scan on "*VALUES*"  (cost=0.00..0.06 rows=5 width=52) (actual time=0.008..0.013 rows=5 loops=1)
--  Planning Time: 0.041 ms
--  Execution Time: 0.289 ms

ROLLBACK;



-- Задание 8*
--===========



-- Задание 9

CREATE MATERIALIZED VIEW IF NOT EXISTS routes_mat AS 
WITH f3 AS (
	SELECT f2.flight_no,
	f2.departure_airport,
	f2.arrival_airport,
	f2.aircraft_code,
	f2.duration,
	array_agg( f2.days_of_week ) AS days_of_week
	FROM (
		SELECT
			f1.flight_no,
			f1.departure_airport,
			f1.arrival_airport,
			f1.aircraft_code,
			f1.duration,
			f1.days_of_week
		FROM (
			SELECT
				flights.flight_no,
				flights.departure_airport,
				flights.arrival_airport,
				flights.aircraft_code,
				( flights.scheduled_arrival - flights.scheduled_departure ) AS duration,
				( to_char( flights.scheduled_departure, 'ID'::text ) )::integer AS days_of_week
			FROM flights
		) f1
		GROUP BY
			f1.flight_no,
			f1.departure_airport,
			f1.arrival_airport,
			f1.aircraft_code,
			f1.duration,
			f1.days_of_week
		ORDER BY
			f1.flight_no,
			f1.departure_airport,
			f1.arrival_airport,
			f1.aircraft_code,
			f1.duration,
			f1.days_of_week
	) f2
	GROUP BY
		f2.flight_no,
		f2.departure_airport,
		f2.arrival_airport,
		f2.aircraft_code,
		f2.duration
)
SELECT
	f3.flight_no,
	f3.departure_airport,
	dep.airport_name AS departure_airport_name,
	dep.city AS departure_city,
	f3.arrival_airport,
	arr.airport_name AS arrival_airport_name,
	arr.city AS arrival_city,
	f3.aircraft_code,
	f3.duration,
	f3.days_of_week
FROM
	f3,
	airports dep,
	airports arr
WHERE f3.departure_airport = dep.airport_code AND f3.arrival_airport = arr.airport_code;

EXPLAIN ANALYZE
SELECT * FROM routes_mat;
--                                                 QUERY PLAN                                                 
-- -----------------------------------------------------------------------------------------------------------
--  Seq Scan on routes_mat  (cost=0.00..41.28 rows=928 width=252) (actual time=0.009..0.087 rows=710 loops=1)
--  Planning Time: 0.155 ms
--  Execution Time: 0.129 ms


EXPLAIN ANALYZE
-- WITH f3 AS ( ...
--                                                                                                                         QUERY PLAN                                                                                                                         
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Hash Join  (cost=2443.64..2916.50 rows=275 width=195) (actual time=26.856..29.957 rows=710 loops=1)
--    Hash Cond: (flights.arrival_airport = ml_1.airport_code)
--    ->  Hash Join  (cost=2438.30..2631.99 rows=529 width=177) (actual time=26.751..27.758 rows=710 loops=1)
--          Hash Cond: (flights.departure_airport = ml.airport_code)
--          ->  GroupAggregate  (cost=2432.96..2623.92 rows=1018 width=67) (actual time=26.695..27.584 rows=710 loops=1)
--                Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure))
--                ->  Sort  (cost=2432.96..2458.42 rows=10185 width=39) (actual time=26.685..26.817 rows=3798 loops=1)
--                      Sort Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure)), ((to_char(flights.scheduled_departure, 'ID'::text))::integer)
--                      Sort Method: quicksort  Memory: 334kB
--                      ->  HashAggregate  (cost=1551.24..1754.93 rows=10185 width=39) (actual time=21.651..22.242 rows=3798 loops=1)
--                            Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, (flights.scheduled_arrival - flights.scheduled_departure), (to_char(flights.scheduled_departure, 'ID'::text))::integer
--                            Batches: 1  Memory Usage: 913kB
--                            ->  Seq Scan on flights  (cost=0.00..1054.42 rows=33121 width=39) (actual time=0.016..11.308 rows=33121 loops=1)
--          ->  Hash  (cost=4.04..4.04 rows=104 width=114) (actual time=0.052..0.052 rows=104 loops=1)
--                Buckets: 1024  Batches: 1  Memory Usage: 23kB
--                ->  Seq Scan on airports_data ml  (cost=0.00..4.04 rows=104 width=114) (actual time=0.003..0.020 rows=104 loops=1)
--    ->  Hash  (cost=4.04..4.04 rows=104 width=114) (actual time=0.071..0.071 rows=104 loops=1)
--          Buckets: 1024  Batches: 1  Memory Usage: 23kB
--          ->  Seq Scan on airports_data ml_1  (cost=0.00..4.04 rows=104 width=114) (actual time=0.015..0.034 rows=104 loops=1)
--  Planning Time: 0.380 ms
--  Execution Time: 30.079 ms



-- Задание 10*
--============



-- Задание 11*
--============



-- Задание 12

EXPLAIN ANALYZE
SELECT count( * )
FROM tickets
WHERE passenger_name = 'IVAN IVANOV';
--                                                             QUERY PLAN                                                            
-- ----------------------------------------------------------------------------------------------------------------------------------
--  Finalize Aggregate  (cost=9086.32..9086.33 rows=1 width=8) (actual time=63.735..65.043 rows=1 loops=1)
--    ->  Gather  (cost=9086.10..9086.31 rows=2 width=8) (actual time=63.676..65.038 rows=3 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          ->  Partial Aggregate  (cost=8086.10..8086.11 rows=1 width=8) (actual time=57.377..57.378 rows=1 loops=3)
--                ->  Parallel Seq Scan on tickets  (cost=0.00..8086.07 rows=14 width=0) (actual time=1.611..57.333 rows=67 loops=3)
--                      Filter: (passenger_name = 'IVAN IVANOV'::text)
--                      Rows Removed by Filter: 122178
--  Planning Time: 1.856 ms
--  Execution Time: 65.093 ms

CREATE INDEX passenger_name_key
ON tickets ( passenger_name );

EXPLAIN ANALYZE
SELECT count( * )
FROM tickets
WHERE passenger_name = 'IVAN IVANOV';
--                                                                 QUERY PLAN                                                                
-- ------------------------------------------------------------------------------------------------------------------------------------------
--  Aggregate  (cost=9.08..9.09 rows=1 width=8) (actual time=0.057..0.058 rows=1 loops=1)
--    ->  Index Only Scan using passenger_name_key on tickets  (cost=0.42..9.00 rows=33 width=0) (actual time=0.032..0.045 rows=200 loops=1)
--          Index Cond: (passenger_name = 'IVAN IVANOV'::text)
--          Heap Fetches: 0
--  Planning Time: 0.213 ms
--  Execution Time: 0.075 ms

-- Можем видеть, что после добавления индекса время исполнения запроса уменьшилось на 3 порядка, поскольку без индекса приходилось просматривать всю таблицу целиком лишь для подсчёта количества пассажиров с конкретными именем и фамилией. После введения индекса в нашем случае не понадобилось даже обращаться к самим строкам таблицы (Heap Fetches: 0).

-- Можем также предложить следующий индекс, полезный при нахождении, например, 10 самых дешёвых бронирований:

EXPLAIN ANALYZE
SELECT * FROM bookings
ORDER BY total_amount
LIMIT 10;
--                                                                 QUERY PLAN                                                                 
-- -------------------------------------------------------------------------------------------------------------------------------------------
--  Limit  (cost=7598.26..7599.41 rows=10 width=21) (actual time=19.665..21.030 rows=10 loops=1)
--    ->  Gather Merge  (cost=7598.26..25375.08 rows=154581 width=21) (actual time=19.663..21.027 rows=10 loops=1)
--          Workers Planned: 1
--          Workers Launched: 1
--          ->  Sort  (cost=6598.25..6984.70 rows=154581 width=21) (actual time=16.572..16.573 rows=10 loops=2)
--                Sort Key: total_amount
--                Sort Method: top-N heapsort  Memory: 26kB
--                Worker 0:  Sort Method: top-N heapsort  Memory: 26kB
--                ->  Parallel Seq Scan on bookings  (cost=0.00..3257.81 rows=154581 width=21) (actual time=0.023..5.806 rows=131394 loops=2)
--  Planning Time: 0.198 ms
--  Execution Time: 21.061 ms

CREATE INDEX ON bookings ( total_amount );

EXPLAIN ANALYZE
SELECT * FROM bookings
ORDER BY total_amount
LIMIT 10;
--                                                                      QUERY PLAN                                                                      
-- -----------------------------------------------------------------------------------------------------------------------------------------------------
--  Limit  (cost=0.42..0.94 rows=10 width=21) (actual time=0.158..0.172 rows=10 loops=1)
--    ->  Index Scan using bookings_total_amount_idx on bookings  (cost=0.42..13685.50 rows=262788 width=21) (actual time=0.157..0.169 rows=10 loops=1)
--  Planning Time: 0.223 ms
--  Execution Time: 0.189 ms



-- Задание 13*
--============



-- Задание 14

CREATE TABLE nulls AS
	SELECT num::integer, 'TEXT' || num::text AS txt
	FROM generate_series( 1, 200000 ) AS gen_ser( num );

CREATE INDEX nulls_ind
	ON nulls ( num );

INSERT INTO nulls VALUES
	( NULL, 'TEXT' );

EXPLAIN
SELECT *
FROM nulls
ORDER BY num;
--                                    QUERY PLAN                                   
-- --------------------------------------------------------------------------------
--  Index Scan using nulls_ind on nulls  (cost=0.42..9556.42 rows=200000 width=36)

SELECT *
FROM nulls
ORDER BY num
OFFSET 199995; -- null в конце

EXPLAIN
SELECT *
FROM nulls
ORDER BY num NULLS FIRST;
--                              QUERY PLAN                             
-- --------------------------------------------------------------------
--  Sort  (cost=24117.25..24617.25 rows=200001 width=14)
--    Sort Key: num NULLS FIRST
--    ->  Seq Scan on nulls  (cost=0.00..3088.01 rows=200001 width=14)

-- 1
EXPLAIN
SELECT *
FROM nulls
ORDER BY num DESC NULLS FIRST;
-- Индекс будет использован, поскольку при обходе созданного индекса num ASC NULLS LAST, можно получить порядок num DESC NULLS FIRST. Проверим на практике:
--                                        QUERY PLAN                                        
-- -----------------------------------------------------------------------------------------
--  Index Scan Backward using nulls_ind on nulls  (cost=0.42..6295.44 rows=200001 width=14)

-- Действительно, индекс используется, причём слово Backward указывает нам на то, что индекс обходится в обратном порядке

-- 2
DROP INDEX nulls_ind;
CREATE INDEX nulls_ind
	ON nulls ( num NULLS FIRST );

EXPLAIN
SELECT *
FROM nulls
ORDER BY num NULLS FIRST;
--                                    QUERY PLAN                                   
-- --------------------------------------------------------------------------------
--  Index Scan using nulls_ind on nulls  (cost=0.42..6295.44 rows=200001 width=14)

-- Теперь индекс используется

-- 3

DROP INDEX nulls_ind;
CREATE INDEX nulls_ind
	ON nulls ( num DESC NULLS LAST );

EXPLAIN
SELECT *
FROM nulls
ORDER BY num NULLS FIRST;
--                                        QUERY PLAN                                        
-- -----------------------------------------------------------------------------------------
--  Index Scan Backward using nulls_ind on nulls  (cost=0.42..6295.44 rows=200001 width=14)

-- Индекс также используется, но теперь в обратном порядке



-- Задание 15

EXPLAIN
SELECT * FROM aircrafts
WHERE model NOT LIKE 'Airbus%'
AND model NOT LIKE 'Boeing%'
--                                             QUERY PLAN                                             
-- ---------------------------------------------------------------------------------------------------
--  Seq Scan on aircrafts_data ml  (cost=0.00..7.95 rows=9 width=52)
--    Filter: (((model ->> lang()) !~~ 'Airbus%'::text) AND ((model ->> lang()) !~~ 'Boeing%'::text))

EXPLAIN
SELECT * FROM airports WHERE airport_name LIKE '___';
--                              QUERY PLAN                             
-- --------------------------------------------------------------------
--  Seq Scan on airports_data ml  (cost=0.00..83.08 rows=104 width=99)
--    Filter: ((airport_name ->> lang()) ~~ '___'::text)


EXPLAIN
SELECT * FROM aircrafts ORDER BY range DESC;
--                                QUERY PLAN                               
-- ------------------------------------------------------------------------
--  Sort  (cost=3.51..3.53 rows=9 width=52)
--    Sort Key: ml.range DESC
--    ->  Seq Scan on aircrafts_data ml  (cost=0.00..3.36 rows=9 width=52)

EXPLAIN
SELECT DISTINCT timezone FROM airports ORDER BY 1;
--                                   QUERY PLAN                                   
-- -------------------------------------------------------------------------------
--  Sort  (cost=4.82..4.86 rows=17 width=15)
--    Sort Key: ml.timezone
--    ->  HashAggregate  (cost=4.30..4.47 rows=17 width=15)
--          Group Key: ml.timezone
--          ->  Seq Scan on airports_data ml  (cost=0.00..4.04 rows=104 width=15)

EXPLAIN
SELECT airport_name, city, coordinates[0] AS longitude
FROM airports
ORDER BY longitude DESC
LIMIT 3;
--                                       QUERY PLAN                                      
-- --------------------------------------------------------------------------------------
--  Limit  (cost=5.38..6.94 rows=3 width=72)
--    ->  Result  (cost=5.38..59.20 rows=104 width=72)
--          ->  Sort  (cost=5.38..5.64 rows=104 width=118)
--                Sort Key: (ml.coordinates[0]) DESC
--                ->  Seq Scan on airports_data ml  (cost=0.00..4.04 rows=104 width=118)

EXPLAIN
SELECT model, range,
CASE WHEN range < 2000 THEN 'Ближнемагистральный'
WHEN range < 5000 THEN 'Среднемагистральный'
ELSE 'Дальнемагистральный'
END AS type
FROM aircrafts
ORDER BY model;
--                                QUERY PLAN                               
-- ------------------------------------------------------------------------
--  Sort  (cost=3.55..3.57 rows=9 width=68)
--    Sort Key: ((ml.model ->> lang()))
--    ->  Seq Scan on aircrafts_data ml  (cost=0.00..3.41 rows=9 width=68)

EXPLAIN
SELECT a.aircraft_code, a.model, s.seat_no, s.fare_conditions
FROM seats AS s
JOIN aircrafts AS a
ON s.aircraft_code = a.aircraft_code
WHERE a.model ~ '^Cessna'
ORDER BY s.seat_no;
--                                       QUERY PLAN                                       
-- ---------------------------------------------------------------------------------------
--  Sort  (cost=63.17..63.54 rows=149 width=59)
--    Sort Key: s.seat_no
--    ->  Nested Loop  (cost=5.43..57.79 rows=149 width=59)
--          ->  Seq Scan on aircrafts_data ml  (cost=0.00..3.39 rows=1 width=48)
--                Filter: ((model ->> lang()) ~ '^Cessna'::text)
--          ->  Bitmap Heap Scan on seats s  (cost=5.43..15.29 rows=149 width=15)
--                Recheck Cond: (aircraft_code = ml.aircraft_code)
--                ->  Bitmap Index Scan on seats_pkey  (cost=0.00..5.39 rows=149 width=0)
--                      Index Cond: (aircraft_code = ml.aircraft_code)

EXPLAIN
SELECT a.aircraft_code, a.model, s.seat_no, s.fare_conditions
FROM seats s, aircrafts a
WHERE s.aircraft_code = a.aircraft_code
AND a.model ~ '^Cessna'
ORDER BY s.seat_no;
--                                       QUERY PLAN                                       
-- ---------------------------------------------------------------------------------------
--  Sort  (cost=63.17..63.54 rows=149 width=59)
--    Sort Key: s.seat_no
--    ->  Nested Loop  (cost=5.43..57.79 rows=149 width=59)
--          ->  Seq Scan on aircrafts_data ml  (cost=0.00..3.39 rows=1 width=48)
--                Filter: ((model ->> lang()) ~ '^Cessna'::text)
--          ->  Bitmap Heap Scan on seats s  (cost=5.43..15.29 rows=149 width=15)
--                Recheck Cond: (aircraft_code = ml.aircraft_code)
--                ->  Bitmap Index Scan on seats_pkey  (cost=0.00..5.39 rows=149 width=0)
--                      Index Cond: (aircraft_code = ml.aircraft_code)

EXPLAIN
SELECT count( * )
FROM airports a1, airports a2
WHERE a1.city <> a2.city;
--                                       QUERY PLAN                                       
-- ---------------------------------------------------------------------------------------
--  Aggregate  (cost=5659.44..5659.45 rows=1 width=8)
--    ->  Nested Loop  (cost=0.00..5632.66 rows=10712 width=0)
--          Join Filter: ((ml.city ->> lang()) <> (ml_1.city ->> lang()))
--          ->  Seq Scan on airports_data ml  (cost=0.00..4.04 rows=104 width=49)
--          ->  Materialize  (cost=0.00..4.56 rows=104 width=49)
--                ->  Seq Scan on airports_data ml_1  (cost=0.00..4.04 rows=104 width=49)

EXPLAIN
SELECT r.aircraft_code, a.model, count( * ) AS num_routes
FROM routes r
JOIN aircrafts a ON r.aircraft_code = a.aircraft_code
GROUP BY 1, 2
ORDER BY 3 DESC;
--                                                                                                                                     QUERY PLAN                                                                                                                                     
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Sort  (cost=2734.19..2734.22 rows=12 width=44)
--    Sort Key: (count(*)) DESC
--    ->  GroupAggregate  (cost=2730.70..2733.97 rows=12 width=44)
--          Group Key: flights.aircraft_code, ((ml.model ->> lang()))
--          ->  Sort  (cost=2730.70..2730.73 rows=12 width=36)
--                Sort Key: flights.aircraft_code, ((ml.model ->> lang()))
--                ->  Hash Join  (cost=2444.84..2730.49 rows=12 width=36)
--                      Hash Cond: (flights.aircraft_code = ml.aircraft_code)
--                      ->  Hash Join  (cost=2443.64..2722.77 rows=275 width=240)
--                            Hash Cond: (flights.arrival_airport = ml_2.airport_code)
--                            ->  Hash Join  (cost=2438.30..2716.01 rows=529 width=8)
--                                  Hash Cond: (flights.departure_airport = ml_1.airport_code)
--                                  ->  GroupAggregate  (cost=2432.96..2697.76 rows=1018 width=67)
--                                        Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure))
--                                        ->  Sort  (cost=2432.96..2458.42 rows=10185 width=39)
--                                              Sort Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure)), ((to_char(flights.scheduled_departure, 'ID'::text))::integer)
--                                              ->  HashAggregate  (cost=1551.24..1754.93 rows=10185 width=39)
--                                                    Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, (flights.scheduled_arrival - flights.scheduled_departure), (to_char(flights.scheduled_departure, 'ID'::text))::integer
--                                                    ->  Seq Scan on flights  (cost=0.00..1054.42 rows=33121 width=39)
--                                  ->  Hash  (cost=4.04..4.04 rows=104 width=4)
--                                        ->  Seq Scan on airports_data ml_1  (cost=0.00..4.04 rows=104 width=4)
--                            ->  Hash  (cost=4.04..4.04 rows=104 width=4)
--                                  ->  Seq Scan on airports_data ml_2  (cost=0.00..4.04 rows=104 width=4)
--                      ->  Hash  (cost=1.09..1.09 rows=9 width=48)
--                            ->  Seq Scan on aircrafts_data ml  (cost=0.00..1.09 rows=9 width=48)

EXPLAIN
SELECT a.aircraft_code AS a_code,
a.model,
r.aircraft_code AS r_code,
count( r.aircraft_code ) AS num_routes
FROM aircrafts a
LEFT OUTER JOIN routes r ON r.aircraft_code = a.aircraft_code
GROUP BY 1, 2, 3
ORDER BY 4 DESC;
--                                                                                                                                     QUERY PLAN                                                                                                                                     
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Sort  (cost=2734.22..2734.25 rows=12 width=60)
--    Sort Key: (count(flights.aircraft_code)) DESC
--    ->  GroupAggregate  (cost=2730.70..2734.00 rows=12 width=60)
--          Group Key: ml.aircraft_code, ((ml.model ->> lang())), flights.aircraft_code
--          ->  Sort  (cost=2730.70..2730.73 rows=12 width=52)
--                Sort Key: ml.aircraft_code, ((ml.model ->> lang())), flights.aircraft_code
--                ->  Hash Right Join  (cost=2444.84..2730.49 rows=12 width=52)
--                      Hash Cond: (flights.aircraft_code = ml.aircraft_code)
--                      ->  Hash Join  (cost=2443.64..2722.77 rows=275 width=240)
--                            Hash Cond: (flights.arrival_airport = ml_2.airport_code)
--                            ->  Hash Join  (cost=2438.30..2716.01 rows=529 width=8)
--                                  Hash Cond: (flights.departure_airport = ml_1.airport_code)
--                                  ->  GroupAggregate  (cost=2432.96..2697.76 rows=1018 width=67)
--                                        Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure))
--                                        ->  Sort  (cost=2432.96..2458.42 rows=10185 width=39)
--                                              Sort Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure)), ((to_char(flights.scheduled_departure, 'ID'::text))::integer)
--                                              ->  HashAggregate  (cost=1551.24..1754.93 rows=10185 width=39)
--                                                    Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, (flights.scheduled_arrival - flights.scheduled_departure), (to_char(flights.scheduled_departure, 'ID'::text))::integer
--                                                    ->  Seq Scan on flights  (cost=0.00..1054.42 rows=33121 width=39)
--                                  ->  Hash  (cost=4.04..4.04 rows=104 width=4)
--                                        ->  Seq Scan on airports_data ml_1  (cost=0.00..4.04 rows=104 width=4)
--                            ->  Hash  (cost=4.04..4.04 rows=104 width=4)
--                                  ->  Seq Scan on airports_data ml_2  (cost=0.00..4.04 rows=104 width=4)
--                      ->  Hash  (cost=1.09..1.09 rows=9 width=48)
--                            ->  Seq Scan on aircrafts_data ml  (cost=0.00..1.09 rows=9 width=48)

EXPLAIN
SELECT count( * )
FROM ( ticket_flights t
JOIN flights f ON t.flight_id = f.flight_id
)
LEFT OUTER JOIN boarding_passes b
ON t.ticket_no = b.ticket_no AND t.flight_id = b.flight_id
WHERE f.actual_departure IS NOT NULL AND b.flight_id IS NULL;
--                                                       QUERY PLAN                                                       
-- -----------------------------------------------------------------------------------------------------------------------
--  Finalize Aggregate  (cost=33798.18..33798.19 rows=1 width=8)
--    ->  Gather  (cost=33797.96..33798.17 rows=2 width=8)
--          Workers Planned: 2
--          ->  Partial Aggregate  (cost=32797.96..32797.97 rows=1 width=8)
--                ->  Parallel Hash Right Anti Join  (cost=19804.50..32442.49 rows=142187 width=0)
--                      Hash Cond: ((b.ticket_no = t.ticket_no) AND (b.flight_id = t.flight_id))
--                      ->  Parallel Seq Scan on boarding_passes b  (cost=0.00..6703.36 rows=241536 width=18)
--                      ->  Parallel Hash  (cost=15209.60..15209.60 rows=220260 width=18)
--                            ->  Hash Join  (cost=932.50..15209.60 rows=220260 width=18)
--                                  Hash Cond: (t.flight_id = f.flight_id)
--                                  ->  Parallel Seq Scan on ticket_flights t  (cost=0.00..13133.19 rows=435719 width=18)
--                                  ->  Hash  (cost=723.21..723.21 rows=16743 width=4)
--                                        ->  Seq Scan on flights f  (cost=0.00..723.21 rows=16743 width=4)
--                                              Filter: (actual_departure IS NOT NULL)

EXPLAIN
SELECT f.flight_no,
f.scheduled_departure,
f.flight_id,
f.departure_airport,
f.arrival_airport,
f.aircraft_code,
t.passenger_name,
tf.fare_conditions AS fc_to_be,
s.fare_conditions AS fc_fact,
b.seat_no
FROM boarding_passes b
JOIN ticket_flights tf
ON b.ticket_no = tf.ticket_no AND b.flight_id = tf.flight_id
JOIN tickets t ON tf.ticket_no = t.ticket_no
JOIN flights f ON tf.flight_id = f.flight_id
JOIN seats s
ON b.seat_no = s.seat_no AND f.aircraft_code = s.aircraft_code
WHERE tf.fare_conditions <> s.fare_conditions
ORDER BY f.flight_no, f.scheduled_departure;
--                                                           QUERY PLAN                                                          
-- ------------------------------------------------------------------------------------------------------------------------------
--  Gather Merge  (cost=37402.19..41285.83 rows=33286 width=66)
--    Workers Planned: 2
--    ->  Sort  (cost=36402.17..36443.78 rows=16643 width=66)
--          Sort Key: f.flight_no, f.scheduled_departure
--          ->  Nested Loop  (cost=10820.32..35235.28 rows=16643 width=66)
--                Join Filter: (b.ticket_no = t.ticket_no)
--                ->  Parallel Hash Join  (cost=10819.90..27221.07 rows=16643 width=78)
--                      Hash Cond: ((tf.ticket_no = b.ticket_no) AND (tf.flight_id = b.flight_id))
--                      Join Filter: ((tf.fare_conditions)::text <> (s.fare_conditions)::text)
--                      ->  Parallel Seq Scan on ticket_flights tf  (cost=0.00..13133.19 rows=435719 width=26)
--                      ->  Parallel Hash  (cost=9784.87..9784.87 rows=69002 width=60)
--                            ->  Hash Join  (cost=1178.70..9784.87 rows=69002 width=60)
--                                  Hash Cond: (((b.seat_no)::text = (s.seat_no)::text) AND (f.aircraft_code = s.aircraft_code))
--                                  ->  Hash Join  (cost=1137.22..8474.69 rows=241536 width=52)
--                                        Hash Cond: (b.flight_id = f.flight_id)
--                                        ->  Parallel Seq Scan on boarding_passes b  (cost=0.00..6703.36 rows=241536 width=21)
--                                        ->  Hash  (cost=723.21..723.21 rows=33121 width=31)
--                                              ->  Seq Scan on flights f  (cost=0.00..723.21 rows=33121 width=31)
--                                  ->  Hash  (cost=21.39..21.39 rows=1339 width=15)
--                                        ->  Seq Scan on seats s  (cost=0.00..21.39 rows=1339 width=15)
--                ->  Index Scan using tickets_pkey on tickets t  (cost=0.42..0.47 rows=1 width=30)
--                      Index Cond: (ticket_no = tf.ticket_no)

EXPLAIN
SELECT r.min_sum, r.max_sum, count( b.* )
FROM bookings b
RIGHT OUTER JOIN
( VALUES ( 0, 100000 ), ( 100000, 200000 ),
( 200000, 300000 ), ( 300000, 400000 ),
( 400000, 500000 ), ( 500000, 600000 ),
( 600000, 700000 ), ( 700000, 800000 ),
( 800000, 900000 ), ( 900000, 1000000 ),
( 1000000, 1100000 ), ( 1100000, 1200000 ),
( 1200000, 1300000 )
) AS r ( min_sum, max_sum )
ON b.total_amount >= r.min_sum AND b.total_amount < r.max_sum
GROUP BY r.min_sum, r.max_sum
ORDER BY r.min_sum;
--                                                              QUERY PLAN                                                              
-- -------------------------------------------------------------------------------------------------------------------------------------
--  Sort  (cost=118080.75..118080.78 rows=13 width=16)
--    Sort Key: "*VALUES*".column1
--    ->  HashAggregate  (cost=118080.38..118080.51 rows=13 width=16)
--          Group Key: "*VALUES*".column1, "*VALUES*".column2
--          ->  Nested Loop Left Join  (cost=0.00..115233.50 rows=379583 width=53)
--                Join Filter: ((b.total_amount >= ("*VALUES*".column1)::numeric) AND (b.total_amount < ("*VALUES*".column2)::numeric))
--                ->  Values Scan on "*VALUES*"  (cost=0.00..0.16 rows=13 width=8)
--                ->  Materialize  (cost=0.00..8220.82 rows=262788 width=51)
--                      ->  Seq Scan on bookings b  (cost=0.00..4339.88 rows=262788 width=51)
--  JIT:
--    Functions: 8
--    Options: Inlining false, Optimization false, Expressions true, Deforming true

EXPLAIN
SELECT arrival_city FROM routes
WHERE departure_city = 'Москва'
UNION
SELECT arrival_city FROM routes
WHERE departure_city = 'Санкт-Петербург'
ORDER BY arrival_city;
--                                                                                                                                            QUERY PLAN                                                                                                                                            
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Unique  (cost=5505.94..5505.97 rows=6 width=32)
--    ->  Sort  (cost=5505.94..5505.95 rows=6 width=32)
--          Sort Key: routes.arrival_city
--          ->  Append  (cost=2433.10..5505.86 rows=6 width=32)
--                ->  Subquery Scan on routes  (cost=2433.10..2752.91 rows=3 width=32)
--                      ->  Nested Loop  (cost=2433.10..2752.88 rows=3 width=252)
--                            ->  Nested Loop  (cost=2432.96..2751.23 rows=5 width=4)
--                                  Join Filter: (ml.airport_code = flights.departure_airport)
--                                  ->  Seq Scan on airports_data ml  (cost=0.00..30.56 rows=1 width=4)
--                                        Filter: ((city ->> lang()) = 'Москва'::text)
--                                  ->  GroupAggregate  (cost=2432.96..2697.76 rows=1018 width=67)
--                                        Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure))
--                                        ->  Sort  (cost=2432.96..2458.42 rows=10185 width=39)
--                                              Sort Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure)), ((to_char(flights.scheduled_departure, 'ID'::text))::integer)
--                                              ->  HashAggregate  (cost=1551.24..1754.93 rows=10185 width=39)
--                                                    Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, (flights.scheduled_arrival - flights.scheduled_departure), (to_char(flights.scheduled_departure, 'ID'::text))::integer
--                                                    ->  Seq Scan on flights  (cost=0.00..1054.42 rows=33121 width=39)
--                            ->  Index Scan using airports_data_pkey on airports_data ml_1  (cost=0.14..0.18 rows=1 width=53)
--                                  Index Cond: (airport_code = flights.arrival_airport)
--                ->  Subquery Scan on routes_1  (cost=2433.10..2752.91 rows=3 width=32)
--                      ->  Nested Loop  (cost=2433.10..2752.88 rows=3 width=252)
--                            ->  Nested Loop  (cost=2432.96..2751.23 rows=5 width=4)
--                                  Join Filter: (ml_2.airport_code = flights_1.departure_airport)
--                                  ->  Seq Scan on airports_data ml_2  (cost=0.00..30.56 rows=1 width=4)
--                                        Filter: ((city ->> lang()) = 'Санкт-Петербург'::text)
--                                  ->  GroupAggregate  (cost=2432.96..2697.76 rows=1018 width=67)
--                                        Group Key: flights_1.flight_no, flights_1.departure_airport, flights_1.arrival_airport, flights_1.aircraft_code, ((flights_1.scheduled_arrival - flights_1.scheduled_departure))
--                                        ->  Sort  (cost=2432.96..2458.42 rows=10185 width=39)
--                                              Sort Key: flights_1.flight_no, flights_1.departure_airport, flights_1.arrival_airport, flights_1.aircraft_code, ((flights_1.scheduled_arrival - flights_1.scheduled_departure)), ((to_char(flights_1.scheduled_departure, 'ID'::text))::integer)
--                                              ->  HashAggregate  (cost=1551.24..1754.93 rows=10185 width=39)
--                                                    Group Key: flights_1.flight_no, flights_1.departure_airport, flights_1.arrival_airport, flights_1.aircraft_code, (flights_1.scheduled_arrival - flights_1.scheduled_departure), (to_char(flights_1.scheduled_departure, 'ID'::text))::integer
--                                                    ->  Seq Scan on flights flights_1  (cost=0.00..1054.42 rows=33121 width=39)
--                            ->  Index Scan using airports_data_pkey on airports_data ml_3  (cost=0.14..0.18 rows=1 width=53)
--                                  Index Cond: (airport_code = flights_1.arrival_airport)

EXPLAIN
SELECT avg( total_amount ) FROM bookings;
--                                         QUERY PLAN                                         
-- -------------------------------------------------------------------------------------------
--  Finalize Aggregate  (cost=4644.38..4644.39 rows=1 width=32)
--    ->  Gather  (cost=4644.27..4644.38 rows=1 width=32)
--          Workers Planned: 1
--          ->  Partial Aggregate  (cost=3644.27..3644.28 rows=1 width=32)
--                ->  Parallel Seq Scan on bookings  (cost=0.00..3257.81 rows=154581 width=6)


EXPLAIN
SELECT array_length( days_of_week, 1 ) AS days_per_week,
count( * ) AS num_routes
FROM routes
GROUP BY days_per_week
ORDER BY 1 desc;
--                                                                                                                                  QUERY PLAN                                                                                                                                  
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  GroupAggregate  (cost=2663.51..2668.07 rows=200 width=12)
--    Group Key: (array_length(routes.days_of_week, 1))
--    ->  Sort  (cost=2663.51..2664.20 rows=275 width=4)
--          Sort Key: (array_length(routes.days_of_week, 1)) DESC
--          ->  Subquery Scan on routes  (cost=2443.64..2652.37 rows=275 width=4)
--                ->  Hash Join  (cost=2443.64..2648.93 rows=275 width=252)
--                      Hash Cond: (flights.arrival_airport = ml_1.airport_code)
--                      ->  Hash Join  (cost=2438.30..2642.17 rows=529 width=36)
--                            Hash Cond: (flights.departure_airport = ml.airport_code)
--                            ->  GroupAggregate  (cost=2432.96..2623.92 rows=1018 width=67)
--                                  Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure))
--                                  ->  Sort  (cost=2432.96..2458.42 rows=10185 width=39)
--                                        Sort Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure)), ((to_char(flights.scheduled_departure, 'ID'::text))::integer)
--                                        ->  HashAggregate  (cost=1551.24..1754.93 rows=10185 width=39)
--                                              Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, (flights.scheduled_arrival - flights.scheduled_departure), (to_char(flights.scheduled_departure, 'ID'::text))::integer
--                                              ->  Seq Scan on flights  (cost=0.00..1054.42 rows=33121 width=39)
--                            ->  Hash  (cost=4.04..4.04 rows=104 width=4)
--                                  ->  Seq Scan on airports_data ml  (cost=0.00..4.04 rows=104 width=4)
--                      ->  Hash  (cost=4.04..4.04 rows=104 width=4)
--                            ->  Seq Scan on airports_data ml_1  (cost=0.00..4.04 rows=104 width=4)


EXPLAIN
SELECT departure_city, count( * )
FROM routes
GROUP BY departure_city
HAVING count( * ) >= 15
ORDER BY count DESC;
--                                                                                                                                     QUERY PLAN                                                                                                                                     
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Sort  (cost=2812.70..2812.87 rows=67 width=40)
--    Sort Key: (count(*)) DESC
--    ->  GroupAggregate  (cost=2806.10..2810.67 rows=67 width=40)
--          Group Key: routes.departure_city
--          Filter: (count(*) >= 15)
--          ->  Sort  (cost=2806.10..2806.79 rows=275 width=32)
--                Sort Key: routes.departure_city
--                ->  Subquery Scan on routes  (cost=2443.64..2794.96 rows=275 width=32)
--                      ->  Hash Join  (cost=2443.64..2792.21 rows=275 width=252)
--                            Hash Cond: (flights.arrival_airport = ml_1.airport_code)
--                            ->  Hash Join  (cost=2438.30..2716.01 rows=529 width=53)
--                                  Hash Cond: (flights.departure_airport = ml.airport_code)
--                                  ->  GroupAggregate  (cost=2432.96..2697.76 rows=1018 width=67)
--                                        Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure))
--                                        ->  Sort  (cost=2432.96..2458.42 rows=10185 width=39)
--                                              Sort Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure)), ((to_char(flights.scheduled_departure, 'ID'::text))::integer)
--                                              ->  HashAggregate  (cost=1551.24..1754.93 rows=10185 width=39)
--                                                    Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, (flights.scheduled_arrival - flights.scheduled_departure), (to_char(flights.scheduled_departure, 'ID'::text))::integer
--                                                    ->  Seq Scan on flights  (cost=0.00..1054.42 rows=33121 width=39)
--                                  ->  Hash  (cost=4.04..4.04 rows=104 width=53)
--                                        ->  Seq Scan on airports_data ml  (cost=0.00..4.04 rows=104 width=53)
--                            ->  Hash  (cost=4.04..4.04 rows=104 width=4)
--                                  ->  Seq Scan on airports_data ml_1  (cost=0.00..4.04 rows=104 width=4)

EXPLAIN
SELECT city, count( * )
FROM airports
GROUP BY city
HAVING count( * ) > 1;
--                                 QUERY PLAN                                
-- --------------------------------------------------------------------------
--  HashAggregate  (cost=30.82..40.67 rows=34 width=40)
--    Group Key: (ml.city ->> lang())
--    Filter: (count(*) > 1)
--    ->  Seq Scan on airports_data ml  (cost=0.00..30.30 rows=104 width=32)

EXPLAIN
SELECT b.book_ref,
b.book_date,
extract( 'month' from b.book_date ) AS month,
extract( 'day' from b.book_date ) AS day,
count( * ) OVER (
PARTITION BY date_trunc( 'month', b.book_date )
ORDER BY b.book_date
) AS count
FROM ticket_flights tf
JOIN tickets t ON tf.ticket_no = t.ticket_no
JOIN bookings b ON t.book_ref = b.book_ref
WHERE tf.flight_id = 1
ORDER BY b.book_date;
--                                                      QUERY PLAN                                                     
-- --------------------------------------------------------------------------------------------------------------------
--  Sort  (cost=15482.68..15482.85 rows=68 width=95)
--    Sort Key: b.book_date
--    ->  WindowAgg  (cost=15470.99..15480.61 rows=68 width=95)
--          ->  Gather Merge  (cost=15470.99..15478.91 rows=68 width=23)
--                Workers Planned: 2
--                ->  Sort  (cost=14470.97..14471.04 rows=28 width=23)
--                      Sort Key: (date_trunc('month'::text, b.book_date)), b.book_date
--                      ->  Nested Loop  (cost=0.84..14470.30 rows=28 width=23)
--                            ->  Nested Loop  (cost=0.42..14457.16 rows=28 width=7)
--                                  ->  Parallel Seq Scan on ticket_flights tf  (cost=0.00..14222.49 rows=28 width=14)
--                                        Filter: (flight_id = 1)
--                                  ->  Index Scan using tickets_pkey on tickets t  (cost=0.42..8.38 rows=1 width=21)
--                                        Index Cond: (ticket_no = tf.ticket_no)
--                            ->  Index Scan using bookings_pkey on bookings b  (cost=0.42..0.47 rows=1 width=15)
--                                  Index Cond: (book_ref = t.book_ref)

EXPLAIN
SELECT count( * ) FROM bookings
WHERE total_amount >
( SELECT avg( total_amount ) FROM bookings );
--                                                   QUERY PLAN                                                  
-- --------------------------------------------------------------------------------------------------------------
--  Finalize Aggregate  (cost=9417.59..9417.60 rows=1 width=8)
--    InitPlan 1
--      ->  Finalize Aggregate  (cost=4644.38..4644.39 rows=1 width=32)
--            ->  Gather  (cost=4644.27..4644.38 rows=1 width=32)
--                  Workers Planned: 1
--                  ->  Partial Aggregate  (cost=3644.27..3644.28 rows=1 width=32)
--                        ->  Parallel Seq Scan on bookings bookings_1  (cost=0.00..3257.81 rows=154581 width=6)
--    ->  Gather  (cost=4773.08..4773.19 rows=1 width=8)
--          Workers Planned: 1
--          ->  Partial Aggregate  (cost=3773.08..3773.09 rows=1 width=8)
--                ->  Parallel Seq Scan on bookings  (cost=0.00..3644.26 rows=51527 width=0)
--                      Filter: (total_amount > (InitPlan 1).col1)

EXPLAIN
SELECT flight_no, departure_city, arrival_city
FROM routes
WHERE departure_city IN (
SELECT city
FROM airports
WHERE timezone ~ 'Krasnoyarsk'
)
AND arrival_city IN (
SELECT city
FROM airports
WHERE timezone ~ 'Krasnoyarsk'
);
--                                                                                                                               QUERY PLAN                                                                                                                               
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Hash Semi Join  (cost=2452.44..2878.93 rows=1 width=71)
--    Hash Cond: (((ml_3.city ->> lang())) = (ml_1.city ->> lang()))
--    ->  Hash Semi Join  (cost=2448.04..2874.36 rows=11 width=71)
--          Hash Cond: (((ml_2.city ->> lang())) = (ml.city ->> lang()))
--          ->  Hash Join  (cost=2443.64..2861.65 rows=275 width=231)
--                Hash Cond: (flights.arrival_airport = ml_3.airport_code)
--                ->  Hash Join  (cost=2438.30..2716.01 rows=529 width=60)
--                      Hash Cond: (flights.departure_airport = ml_2.airport_code)
--                      ->  GroupAggregate  (cost=2432.96..2697.76 rows=1018 width=67)
--                            Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure))
--                            ->  Sort  (cost=2432.96..2458.42 rows=10185 width=39)
--                                  Sort Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure)), ((to_char(flights.scheduled_departure, 'ID'::text))::integer)
--                                  ->  HashAggregate  (cost=1551.24..1754.93 rows=10185 width=39)
--                                        Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, (flights.scheduled_arrival - flights.scheduled_departure), (to_char(flights.scheduled_departure, 'ID'::text))::integer
--                                        ->  Seq Scan on flights  (cost=0.00..1054.42 rows=33121 width=39)
--                      ->  Hash  (cost=4.04..4.04 rows=104 width=53)
--                            ->  Seq Scan on airports_data ml_2  (cost=0.00..4.04 rows=104 width=53)
--                ->  Hash  (cost=4.04..4.04 rows=104 width=53)
--                      ->  Seq Scan on airports_data ml_3  (cost=0.00..4.04 rows=104 width=53)
--          ->  Hash  (cost=4.30..4.30 rows=8 width=49)
--                ->  Seq Scan on airports_data ml  (cost=0.00..4.30 rows=8 width=49)
--                      Filter: (timezone ~ 'Krasnoyarsk'::text)
--    ->  Hash  (cost=4.30..4.30 rows=8 width=49)
--          ->  Seq Scan on airports_data ml_1  (cost=0.00..4.30 rows=8 width=49)
--                Filter: (timezone ~ 'Krasnoyarsk'::text)

EXPLAIN
SELECT DISTINCT a.city
FROM airports a
WHERE NOT EXISTS (
SELECT * FROM routes r
WHERE r.departure_city = 'Москва'
AND r.arrival_city = a.city
)
AND a.city <> 'Москва'
ORDER BY city;
--                                                                                                                                  QUERY PLAN                                                                                                                                  
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Unique  (cost=2813.75..2814.25 rows=100 width=32)
--    ->  Sort  (cost=2813.75..2814.00 rows=100 width=32)
--          Sort Key: ((ml.city ->> lang()))
--          ->  Hash Right Anti Join  (cost=2464.95..2810.43 rows=100 width=32)
--                Hash Cond: (((ml_2.city ->> lang())) = (ml.city ->> lang()))
--                ->  Nested Loop  (cost=2433.10..2752.88 rows=3 width=252)
--                      ->  Nested Loop  (cost=2432.96..2751.23 rows=5 width=4)
--                            Join Filter: (ml_1.airport_code = flights.departure_airport)
--                            ->  Seq Scan on airports_data ml_1  (cost=0.00..30.56 rows=1 width=4)
--                                  Filter: ((city ->> lang()) = 'Москва'::text)
--                            ->  GroupAggregate  (cost=2432.96..2697.76 rows=1018 width=67)
--                                  Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure))
--                                  ->  Sort  (cost=2432.96..2458.42 rows=10185 width=39)
--                                        Sort Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, ((flights.scheduled_arrival - flights.scheduled_departure)), ((to_char(flights.scheduled_departure, 'ID'::text))::integer)
--                                        ->  HashAggregate  (cost=1551.24..1754.93 rows=10185 width=39)
--                                              Group Key: flights.flight_no, flights.departure_airport, flights.arrival_airport, flights.aircraft_code, (flights.scheduled_arrival - flights.scheduled_departure), (to_char(flights.scheduled_departure, 'ID'::text))::integer
--                                              ->  Seq Scan on flights  (cost=0.00..1054.42 rows=33121 width=39)
--                      ->  Index Scan using airports_data_pkey on airports_data ml_2  (cost=0.14..0.18 rows=1 width=53)
--                            Index Cond: (airport_code = flights.arrival_airport)
--                ->  Hash  (cost=30.56..30.56 rows=103 width=49)
--                      ->  Seq Scan on airports_data ml  (cost=0.00..30.56 rows=103 width=49)
--                            Filter: ((city ->> lang()) <> 'Москва'::text)

EXPLAIN
SELECT a.model,
( SELECT count( * )
FROM seats s
WHERE s.aircraft_code = a.aircraft_code
AND s.fare_conditions = 'Business'
) AS business,
( SELECT count( * )
FROM seats s
WHERE s.aircraft_code = a.aircraft_code
AND s.fare_conditions = 'Comfort'
) AS comfort,
( SELECT count( * )
FROM seats s
WHERE s.aircraft_code = a.aircraft_code
AND s.fare_conditions = 'Economy'
) AS economy
FROM aircrafts a
ORDER BY 1;
--                                           QUERY PLAN                                           
-- -----------------------------------------------------------------------------------------------
--  Sort  (cost=429.47..429.50 rows=9 width=56)
--    Sort Key: ((ml.model ->> lang()))
--    ->  Seq Scan on aircrafts_data ml  (cost=0.00..429.33 rows=9 width=56)
--          SubPlan 1
--            ->  Aggregate  (cost=15.68..15.69 rows=1 width=8)
--                  ->  Bitmap Heap Scan on seats s  (cost=5.40..15.63 rows=17 width=0)
--                        Recheck Cond: (aircraft_code = ml.aircraft_code)
--                        Filter: ((fare_conditions)::text = 'Business'::text)
--                        ->  Bitmap Index Scan on seats_pkey  (cost=0.00..5.39 rows=149 width=0)
--                              Index Cond: (aircraft_code = ml.aircraft_code)
--          SubPlan 2
--            ->  Aggregate  (cost=15.64..15.65 rows=1 width=8)
--                  ->  Bitmap Heap Scan on seats s_1  (cost=5.40..15.63 rows=5 width=0)
--                        Recheck Cond: (aircraft_code = ml.aircraft_code)
--                        Filter: ((fare_conditions)::text = 'Comfort'::text)
--                        ->  Bitmap Index Scan on seats_pkey  (cost=0.00..5.39 rows=149 width=0)
--                              Index Cond: (aircraft_code = ml.aircraft_code)
--          SubPlan 3
--            ->  Aggregate  (cost=15.98..15.99 rows=1 width=8)
--                  ->  Bitmap Heap Scan on seats s_2  (cost=5.43..15.66 rows=127 width=0)
--                        Recheck Cond: (aircraft_code = ml.aircraft_code)
--                        Filter: ((fare_conditions)::text = 'Economy'::text)
--                        ->  Bitmap Index Scan on seats_pkey  (cost=0.00..5.39 rows=149 width=0)
--                              Index Cond: (aircraft_code = ml.aircraft_code)

EXPLAIN
SELECT s2.model,
string_agg(
s2.fare_conditions || ' (' || s2.num || ')',
', '
)
FROM (
SELECT a.model,
s.fare_conditions,
count( * ) AS num
FROM aircrafts a
JOIN seats s ON a.aircraft_code = s.aircraft_code
GROUP BY 1, 2
ORDER BY 1, 2
) AS s2
GROUP BY s2.model
ORDER BY s2.model;
--                                            QUERY PLAN                                           
-- ------------------------------------------------------------------------------------------------
--  GroupAggregate  (cost=383.63..384.51 rows=27 width=64)
--    Group Key: ((ml.model ->> lang()))
--    ->  Sort  (cost=383.63..383.70 rows=27 width=48)
--          Sort Key: ((ml.model ->> lang())), s.fare_conditions
--          ->  HashAggregate  (cost=375.91..382.99 rows=27 width=48)
--                Group Key: (ml.model ->> lang()), s.fare_conditions
--                ->  Hash Join  (cost=1.20..365.86 rows=1339 width=40)
--                      Hash Cond: (s.aircraft_code = ml.aircraft_code)
--                      ->  Seq Scan on seats s  (cost=0.00..21.39 rows=1339 width=12)
--                      ->  Hash  (cost=1.09..1.09 rows=9 width=48)
--                            ->  Seq Scan on aircrafts_data ml  (cost=0.00..1.09 rows=9 width=48)

EXPLAIN
SELECT aa.city, aa.airport_code, aa.airport_name
FROM (
SELECT city, count( * )
FROM airports
GROUP BY city
HAVING count( * ) > 1
) AS a
JOIN airports AS aa ON a.city = aa.city
ORDER BY aa.city, aa.airport_name;
--                                              QUERY PLAN                                             
-- ----------------------------------------------------------------------------------------------------
--  Sort  (cost=65.22..65.30 rows=34 width=68)
--    Sort Key: ((ml.city ->> lang())), ((ml.airport_name ->> lang()))
--    ->  Hash Join  (cost=41.43..64.35 rows=34 width=68)
--          Hash Cond: ((ml.city ->> lang()) = a.city)
--          ->  Seq Scan on airports_data ml  (cost=0.00..4.04 rows=104 width=114)
--          ->  Hash  (cost=41.01..41.01 rows=34 width=32)
--                ->  Subquery Scan on a  (cost=30.82..41.01 rows=34 width=32)
--                      ->  HashAggregate  (cost=30.82..40.67 rows=34 width=40)
--                            Group Key: (ml_1.city ->> lang())
--                            Filter: (count(*) > 1)
--                            ->  Seq Scan on airports_data ml_1  (cost=0.00..30.30 rows=104 width=32)

EXPLAIN
SELECT ts.flight_id,
ts.flight_no,
ts.scheduled_departure_local,
ts.departure_city,
ts.arrival_city,
a.model,
ts.fact_passengers,
ts.total_seats,
round( ts.fact_passengers::numeric /
ts.total_seats::numeric, 2 ) AS fraction
FROM (
SELECT f.flight_id,
f.flight_no,
f.scheduled_departure_local,
f.departure_city,
f.arrival_city,
f.aircraft_code,
count( tf.ticket_no ) AS fact_passengers,
( SELECT count( s.seat_no )
FROM seats s
WHERE s.aircraft_code = f.aircraft_code
) AS total_seats
FROM flights_v f
JOIN ticket_flights tf ON f.flight_id = tf.flight_id
WHERE f.status = 'Arrived'
GROUP BY 1, 2, 3, 4, 5, 6
) AS ts
JOIN aircrafts AS a ON ts.aircraft_code = a.aircraft_code
ORDER BY ts.scheduled_departure_local;
--                                                               QUERY PLAN                                                              
-- --------------------------------------------------------------------------------------------------------------------------------------
--  Sort  (cost=4509790.08..4509849.34 rows=23703 width=163)
--    Sort Key: (timezone(ml_1.timezone, f.scheduled_departure))
--    ->  Hash Join  (cost=376159.23..4506121.73 rows=23703 width=163)
--          Hash Cond: (f.aircraft_code = ml.aircraft_code)
--          ->  HashAggregate  (cost=376158.03..4493219.20 rows=526731 width=103)
--                Group Key: f.flight_id, timezone(ml_1.timezone, f.scheduled_departure), (ml_1.city ->> lang()), (ml_2.city ->> lang())
--                Planned Partitions: 16
--                ->  Hash Join  (cost=1025.23..293197.89 rows=526731 width=101)
--                      Hash Cond: (f.arrival_airport = ml_2.airport_code)
--                      ->  Hash Join  (cost=1019.89..24437.55 rows=526731 width=105)
--                            Hash Cond: (f.departure_airport = ml_1.airport_code)
--                            ->  Hash Join  (cost=1014.55..22993.20 rows=526731 width=45)
--                                  Hash Cond: (tf.flight_id = f.flight_id)
--                                  ->  Seq Scan on ticket_flights tf  (cost=0.00..19233.26 rows=1045726 width=18)
--                                  ->  Hash  (cost=806.01..806.01 rows=16683 width=31)
--                                        ->  Seq Scan on flights f  (cost=0.00..806.01 rows=16683 width=31)
--                                              Filter: ((status)::text = 'Arrived'::text)
--                            ->  Hash  (cost=4.04..4.04 rows=104 width=68)
--                                  ->  Seq Scan on airports_data ml_1  (cost=0.00..4.04 rows=104 width=68)
--                      ->  Hash  (cost=4.04..4.04 rows=104 width=53)
--                            ->  Seq Scan on airports_data ml_2  (cost=0.00..4.04 rows=104 width=53)
--                SubPlan 1
--                  ->  Aggregate  (cost=7.26..7.27 rows=1 width=8)
--                        ->  Index Only Scan using seats_pkey on seats s  (cost=0.28..6.88 rows=149 width=3)
--                              Index Cond: (aircraft_code = f.aircraft_code)
--          ->  Hash  (cost=1.09..1.09 rows=9 width=48)
--                ->  Seq Scan on aircrafts_data ml  (cost=0.00..1.09 rows=9 width=48)
--  JIT:
--    Functions: 43
--    Options: Inlining true, Optimization true, Expressions true, Deforming true

EXPLAIN
WITH ts AS
( SELECT f.flight_id,
f.flight_no,
f.scheduled_departure_local,
f.departure_city,
f.arrival_city,
f.aircraft_code,
count( tf.ticket_no ) AS fact_passengers,
( SELECT count( s.seat_no )
FROM seats s
WHERE s.aircraft_code = f.aircraft_code
) AS total_seats
FROM flights_v f
JOIN ticket_flights tf ON f.flight_id = tf.flight_id
WHERE f.status = 'Arrived'
GROUP BY 1, 2, 3, 4, 5, 6
)
SELECT ts.flight_id,
ts.flight_no,
ts.scheduled_departure_local,
ts.departure_city,
ts.arrival_city,
a.model,
ts.fact_passengers,
ts.total_seats,
round( ts.fact_passengers::numeric /
ts.total_seats::numeric, 2 ) AS fraction
FROM ts
JOIN aircrafts AS a ON ts.aircraft_code = a.aircraft_code
ORDER BY ts.scheduled_departure_local;
--                                                               QUERY PLAN                                                              
-- --------------------------------------------------------------------------------------------------------------------------------------
--  Sort  (cost=4509790.08..4509849.34 rows=23703 width=163)
--    Sort Key: (timezone(ml_1.timezone, f.scheduled_departure))
--    ->  Hash Join  (cost=376159.23..4506121.73 rows=23703 width=163)
--          Hash Cond: (f.aircraft_code = ml.aircraft_code)
--          ->  HashAggregate  (cost=376158.03..4493219.20 rows=526731 width=103)
--                Group Key: f.flight_id, timezone(ml_1.timezone, f.scheduled_departure), (ml_1.city ->> lang()), (ml_2.city ->> lang())
--                Planned Partitions: 16
--                ->  Hash Join  (cost=1025.23..293197.89 rows=526731 width=101)
--                      Hash Cond: (f.arrival_airport = ml_2.airport_code)
--                      ->  Hash Join  (cost=1019.89..24437.55 rows=526731 width=105)
--                            Hash Cond: (f.departure_airport = ml_1.airport_code)
--                            ->  Hash Join  (cost=1014.55..22993.20 rows=526731 width=45)
--                                  Hash Cond: (tf.flight_id = f.flight_id)
--                                  ->  Seq Scan on ticket_flights tf  (cost=0.00..19233.26 rows=1045726 width=18)
--                                  ->  Hash  (cost=806.01..806.01 rows=16683 width=31)
--                                        ->  Seq Scan on flights f  (cost=0.00..806.01 rows=16683 width=31)
--                                              Filter: ((status)::text = 'Arrived'::text)
--                            ->  Hash  (cost=4.04..4.04 rows=104 width=68)
--                                  ->  Seq Scan on airports_data ml_1  (cost=0.00..4.04 rows=104 width=68)
--                      ->  Hash  (cost=4.04..4.04 rows=104 width=53)
--                            ->  Seq Scan on airports_data ml_2  (cost=0.00..4.04 rows=104 width=53)
--                SubPlan 1
--                  ->  Aggregate  (cost=7.26..7.27 rows=1 width=8)
--                        ->  Index Only Scan using seats_pkey on seats s  (cost=0.28..6.88 rows=149 width=3)
--                              Index Cond: (aircraft_code = f.aircraft_code)
--          ->  Hash  (cost=1.09..1.09 rows=9 width=48)
--                ->  Seq Scan on aircrafts_data ml  (cost=0.00..1.09 rows=9 width=48)
--  JIT:
--    Functions: 43
--    Options: Inlining true, Optimization true, Expressions true, Deforming true

EXPLAIN
WITH RECURSIVE ranges ( min_sum, max_sum ) AS
( VALUES ( 0, 100000 )
UNION ALL
SELECT min_sum + 100000, max_sum + 100000
FROM ranges
WHERE max_sum <
( SELECT max( total_amount ) FROM bookings )
)
SELECT * FROM ranges;
--                                                    QUERY PLAN                                                    
-- -----------------------------------------------------------------------------------------------------------------
--  CTE Scan on ranges  (cost=46446.84..46447.46 rows=31 width=8)
--    CTE ranges
--      ->  Recursive Union  (cost=0.00..46446.84 rows=31 width=8)
--            ->  Result  (cost=0.00..0.01 rows=1 width=8)
--            ->  WorkTable Scan on ranges ranges_1  (cost=4644.39..4644.65 rows=3 width=8)
--                  Filter: ((max_sum)::numeric < (InitPlan 1).col1)
--                  InitPlan 1
--                    ->  Finalize Aggregate  (cost=4644.38..4644.39 rows=1 width=32)
--                          ->  Gather  (cost=4644.26..4644.37 rows=1 width=32)
--                                Workers Planned: 1
--                                ->  Partial Aggregate  (cost=3644.26..3644.27 rows=1 width=32)
--                                      ->  Parallel Seq Scan on bookings  (cost=0.00..3257.81 rows=154581 width=6)

EXPLAIN
WITH RECURSIVE ranges ( min_sum, max_sum ) AS
( VALUES( 0, 100000 )
UNION ALL
SELECT min_sum + 100000, max_sum + 100000
FROM ranges
WHERE max_sum <
( SELECT max( total_amount ) FROM bookings )
)
SELECT r.min_sum, r.max_sum, count( b.* )
FROM bookings b
RIGHT OUTER JOIN ranges r
ON b.total_amount >= r.min_sum
AND b.total_amount < r.max_sum
GROUP BY r.min_sum, r.max_sum
ORDER BY r.min_sum;
--                                                     QUERY PLAN                                                     
-- -------------------------------------------------------------------------------------------------------------------
--  Sort  (cost=321105.71..321105.79 rows=31 width=16)
--    Sort Key: r.min_sum
--    CTE ranges
--      ->  Recursive Union  (cost=0.00..46446.84 rows=31 width=8)
--            ->  Result  (cost=0.00..0.01 rows=1 width=8)
--            ->  WorkTable Scan on ranges  (cost=4644.39..4644.65 rows=3 width=8)
--                  Filter: ((max_sum)::numeric < (InitPlan 1).col1)
--                  InitPlan 1
--                    ->  Finalize Aggregate  (cost=4644.38..4644.39 rows=1 width=32)
--                          ->  Gather  (cost=4644.26..4644.37 rows=1 width=32)
--                                Workers Planned: 1
--                                ->  Partial Aggregate  (cost=3644.26..3644.27 rows=1 width=32)
--                                      ->  Parallel Seq Scan on bookings  (cost=0.00..3257.81 rows=154581 width=6)
--    ->  HashAggregate  (cost=274657.79..274658.10 rows=31 width=16)
--          Group Key: r.min_sum, r.max_sum
--          ->  Nested Loop Left Join  (cost=0.00..267869.10 rows=905159 width=53)
--                Join Filter: ((b.total_amount >= (r.min_sum)::numeric) AND (b.total_amount < (r.max_sum)::numeric))
--                ->  CTE Scan on ranges r  (cost=0.00..0.62 rows=31 width=8)
--                ->  Materialize  (cost=0.00..8220.82 rows=262788 width=51)
--                      ->  Seq Scan on bookings b  (cost=0.00..4339.88 rows=262788 width=51)
--  JIT:
--    Functions: 17
--    Options: Inlining false, Optimization false, Expressions true, Deforming true



-- Задание 16

SET enable_hashjoin = off;
SET enable_mergejoin = off;
SET enable_nestloop = off;

EXPLAIN
SELECT a.model, count( * )
FROM aircrafts_data a, seats s
WHERE a.aircraft_code = s.aircraft_code
GROUP BY a.model, a.aircraft_code;

SET enable_hashjoin = default;
SET enable_mergejoin = default;
SET enable_nestloop = default;

--                                              QUERY PLAN                                              
-- -----------------------------------------------------------------------------------------------------
--  GroupAggregate  (cost=10000000000.41..10000000082.43 rows=9 width=56)
--    Group Key: a.aircraft_code
--    ->  Nested Loop  (cost=10000000000.41..10000000075.65 rows=1339 width=48)
--          ->  Index Scan using aircrafts_pkey on aircrafts_data a  (cost=0.14..12.27 rows=9 width=48)
--          ->  Index Only Scan using seats_pkey on seats s  (cost=0.28..5.55 rows=149 width=4)
--                Index Cond: (aircraft_code = a.aircraft_code)
--  JIT:
--    Functions: 6
--    Options: Inlining true, Optimization true, Expressions true, Deforming true


EXPLAIN
SELECT * FROM airports WHERE airport_name LIKE '___';
--                              QUERY PLAN                             
-- --------------------------------------------------------------------
--  Seq Scan on airports_data ml  (cost=0.00..83.08 rows=104 width=99)
--    Filter: ((airport_name ->> lang()) ~~ '___'::text)

SET seq_page_cost = 10000000000.0; -- 3 раза
SET cpu_tuple_cost  = 1000000.0; -- 104 раз
SET cpu_operator_cost  = 1.0; -- 31616 раз
EXPLAIN
SELECT * FROM airports WHERE airport_name LIKE '___';
--                                   QUERY PLAN                                   
-- -------------------------------------------------------------------------------
--  Seq Scan on airports_data ml  (cost=0.00..30104031616.00 rows=104 width=99)
--    Filter: ((airport_name ->> lang()) ~~ '___'::text)
--  JIT:
--    Functions: 4
--    Options: Inlining true, Optimization true, Expressions true, Deforming true

SET seq_page_cost = default;
SET cpu_tuple_cost  = default;
SET cpu_operator_cost  = default;


-- Задание 17
SELECT relname, relkind, reltuples, relpages
FROM pg_class
WHERE relname LIKE 'bookings%';
--     relname    | relkind | reltuples | relpages 
-- ---------------+---------+-----------+----------
--  bookings      | r       |    262788 |     1712
--  bookings_pkey | i       |    262788 |      723

SELECT attname, inherited, n_distinct,
       array_to_string(most_common_vals, E'\n') as most_common_vals
FROM pg_stats
WHERE tablename = 'airports';
--     attname     | inherited | n_distinct |   most_common_vals   
-- ----------------+-----------+------------+----------------------
--  ticket_no      | f         |         -1 | 
--  book_ref       | f         | -0.6144443 | 
--  passenger_id   | f         |         -1 | 
--  passenger_name | f         |      10219 | ALEKSANDR IVANOV    +
--                 |           |            | SERGEY KUZNECOV     +
--                 |           |            | ALEKSANDR KUZNECOV  +
--                 |           |            | VLADIMIR IVANOV     +
--                                                   ...
--                 |           |            | DMITRIY POPOV       +
--                 |           |            | NATALYA PAVLOVA     +
--                 |           |            | VLADIMIR ANTONOV    +
--                 |           |            | YURIY KUZNECOV
--  contact_data   | f         |         -1 | 



-- Задание 18

EXPLAIN (ANALYZE, BUFFERS)
SELECT a.aircraft_code, a.model, s.seat_no, s.fare_conditions
FROM seats AS s
JOIN aircrafts AS a
ON s.aircraft_code = a.aircraft_code
WHERE a.model ~ '^Cessna'
ORDER BY s.seat_no;
--                                                        QUERY PLAN                                                       
-- ------------------------------------------------------------------------------------------------------------------------
--  Sort  (cost=63.17..63.54 rows=149 width=59) (actual time=0.060..0.061 rows=0 loops=1)
--    Sort Key: s.seat_no
--    Sort Method: quicksort  Memory: 25kB
--    Buffers: shared hit=1
--    ->  Nested Loop  (cost=5.43..57.79 rows=149 width=59) (actual time=0.056..0.057 rows=0 loops=1)
--          Buffers: shared hit=1
--          ->  Seq Scan on aircrafts_data ml  (cost=0.00..3.39 rows=1 width=48) (actual time=0.056..0.056 rows=0 loops=1)
--                Filter: ((model ->> lang()) ~ '^Cessna'::text)
--                Rows Removed by Filter: 9
--                Buffers: shared hit=1
--          ->  Bitmap Heap Scan on seats s  (cost=5.43..15.29 rows=149 width=15) (never executed)
--                Recheck Cond: (aircraft_code = ml.aircraft_code)
--                ->  Bitmap Index Scan on seats_pkey  (cost=0.00..5.39 rows=149 width=0) (never executed)
--                      Index Cond: (aircraft_code = ml.aircraft_code)
--  Planning Time: 0.153 ms
--  Execution Time: 0.087 ms



-- Задание 19

COPY bookings TO '/home/postgres/bookings.csv' WITH (FORMAT csv, DELIMITER ',');


-- Сначала индексы и ограничения, потом заполнение таблицы
DROP TABLE IF EXISTS bookings_tmp;
CREATE TEMP TABLE bookings_tmp
(
    book_ref character(6),
    book_date timestamp with time zone,
    total_amount numeric(10,2),
    CONSTRAINT bookings_pkey PRIMARY KEY (book_ref)
);
CREATE INDEX ON bookings_tmp ( total_amount );
CREATE INDEX ON bookings_tmp ( book_date );

COPY bookings_tmp FROM '/home/postgres/bookings.csv' WITH (FORMAT csv, DELIMITER ',');
-- COPY 262788
-- Time: 1008.947 ms (00:01.009)


-- Сначала заполнение таблицы, потом индексы и ограничения
DROP TABLE IF EXISTS bookings_tmp;
CREATE TEMP TABLE bookings_tmp
(
    book_ref character(6),
    book_date timestamp with time zone,
    total_amount numeric(10,2)
);

COPY bookings_tmp FROM '/home/postgres/bookings.csv' WITH (FORMAT csv, DELIMITER ',');

ALTER TABLE bookings_tmp
	ADD CONSTRAINT bookings_pkey PRIMARY KEY (book_ref);
CREATE INDEX ON bookings_tmp ( total_amount );
CREATE INDEX ON bookings_tmp ( book_date );

-- CREATE TABLE
-- Time: 1.098 ms
-- COPY 262788
-- Time: 158.020 ms
-- ALTER TABLE
-- Time: 67.850 ms
-- CREATE INDEX
-- Time: 163.524 ms
-- CREATE INDEX
-- Time: 68.645 ms

-- Суммарно около 460 мс, более чем в 2 раза меньше, чем в пролшый раз

