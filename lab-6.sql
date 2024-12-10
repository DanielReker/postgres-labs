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



