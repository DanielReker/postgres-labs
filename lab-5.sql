-- Лабораторная работа 5

-- Глава 6

DROP TABLE IF EXISTS aircrafts_tmp;
CREATE TEMP TABLE aircrafts_tmp AS
	SELECT * FROM aircrafts WITH NO DATA;

ALTER TABLE aircrafts_tmp
	ADD PRIMARY KEY ( aircraft_code );
ALTER TABLE aircrafts_tmp
	ADD UNIQUE ( model );

DROP TABLE IF EXISTS aircrafts_log;
CREATE TEMP TABLE aircrafts_log AS
	SELECT * FROM aircrafts WITH NO DATA;

ALTER TABLE aircrafts_log
	ADD COLUMN when_add timestamp;
ALTER TABLE aircrafts_log
	ADD COLUMN operation text;


-- Задание 1

ALTER TABLE aircrafts_log
    ALTER COLUMN when_add SET DEFAULT current_timestamp;

WITH add_row AS (
	INSERT INTO aircrafts_tmp
	SELECT * FROM aircrafts
	RETURNING *
)
INSERT INTO aircrafts_log (aircraft_code, model, range, operation)
	SELECT add_row.aircraft_code, add_row.model, add_row.range, 'INSERT'
	FROM add_row;

SELECT * FROM aircrafts_log;



-- Задание 2

WITH add_row AS (
	INSERT INTO aircrafts_tmp
	SELECT * FROM aircrafts
	RETURNING aircraft_code, model, range, current_timestamp, 'INSERT'
)
INSERT INTO aircrafts_log
	SELECT * FROM add_row;

SELECT * FROM aircrafts_log;



-- Задание 3

INSERT INTO aircrafts_tmp SELECT * FROM aircrafts;

-- Вероятно, при использовании RETURNING * в команде INSERT мы увидим на экране те строки, которые были вставлены в таблицу. Проверим это предположение на практкие:

INSERT INTO aircrafts_tmp SELECT * FROM aircrafts RETURNING *;

--  aircraft_code |        model        | range 
-- ---------------+---------------------+-------
--  773           | Боинг 777-300       | 11100
--  763           | Боинг 767-300       |  7900
--  SU9           | Сухой Суперджет-100 |  3000
--  320           | Аэробус A320-200    |  5700
--  321           | Аэробус A321-200    |  5600
--  319           | Аэробус A319-100    |  6700
--  733           | Боинг 737-300       |  4200
--  CN1           | Сессна 208 Караван  |  1200
--  CR2           | Бомбардье CRJ-200   |  2700

-- Действительно, мы увидели все 9 строк, которые были вставлены в таблицу.


-- Задание 4

DROP TABLE IF EXISTS seats_tmp;
CREATE TEMP TABLE seats_tmp AS
	SELECT * FROM seats WITH NO DATA;

ALTER TABLE seats_tmp
	ADD PRIMARY KEY ( aircraft_code, seat_no );

INSERT INTO seats_tmp
	SELECT * FROM seats;

-- С использованием перечисления имен столбцов для проверки наличия дублирования
INSERT INTO seats_tmp ( aircraft_code, seat_no, fare_conditions ) VALUES
	('319', '2A', 'Business')
ON CONFLICT ( aircraft_code, seat_no ) DO NOTHING;

-- С использованием предложения ON CONSTRAINT
INSERT INTO seats_tmp ( aircraft_code, seat_no, fare_conditions ) VALUES
	('319', '2A', 'Business')
ON CONFLICT ON CONSTRAINT seats_tmp_pkey DO NOTHING;



-- Задание 5

DROP TABLE IF EXISTS seats_tmp;
CREATE TEMP TABLE seats_tmp AS
	SELECT * FROM seats WITH NO DATA;

ALTER TABLE seats_tmp
	ADD PRIMARY KEY ( aircraft_code, seat_no );

INSERT INTO seats_tmp
	SELECT * FROM seats;

INSERT INTO seats_tmp ( aircraft_code, seat_no, fare_conditions ) VALUES
	('319', '2A', 'Comfort'),
	('320', '2A', 'Economy'), -- не изменло значение
	('321', '2A', 'Economy')
ON CONFLICT ON CONSTRAINT seats_tmp_pkey DO UPDATE
	SET fare_conditions = EXCLUDED.fare_conditions WHERE EXCLUDED.aircraft_code <> '320';

SELECT * FROM seats_tmp
	WHERE aircraft_code IN ('319', '320', '321') AND seat_no = '2A';

-- aircraft_code | seat_no | fare_conditions 
-- ---------------+---------+-----------------
--  319           | 2A      | Comfort
--  320           | 2A      | Business
--  321           | 2A      | Economy



-- Задание 6

COPY aircrafts_tmp FROM STDIN WITH ( FORMAT csv );

-- IL9, Ilyushin IL96, 9800
-- I93, Ilyushin IL96-300, 9800
-- \.

SELECT * FROM aircrafts_tmp;

--  aircraft_code |        model        | range 
-- ---------------+---------------------+-------
--  773           | Боинг 777-300       | 11100
--  763           | Боинг 767-300       |  7900
--  SU9           | Сухой Суперджет-100 |  3000
--  320           | Аэробус A320-200    |  5700
--  321           | Аэробус A321-200    |  5600
--  319           | Аэробус A319-100    |  6700
--  733           | Боинг 737-300       |  4200
--  CN1           | Сессна 208 Караван  |  1200
--  CR2           | Бомбардье CRJ-200   |  2700
--  IL9           |  Ilyushin IL96      |  9800
--  I93           |  Ilyushin IL96-300  |  9800

-- Значения в столбце model оказались смещены из за лишнего пробела в начале названий модели, поскольку в CSV значение столбца - это значение между запятыми (или запятой и концом строки), в нашем случае после начальной запятой находится также пробел (", Ilyushin IL96,") - он и оказался во вставленных названиях модели



-- Задание 7

INSERT INTO aircrafts_tmp ( aircraft_code, model, range ) VALUES
	('763','Boeing 767-300',7900),
	('SU9','Sukhoi SuperJet-100',3000);

-- Ошибка
--INSERT INTO aircrafts_tmp ( aircraft_code, model, range ) VALUES
--	('773','Boeing 777-300',11100),
--	('763','Boeing 767-300',7900);

-- Вероятно, при попытке вставить в таблицу строки, нарушающие ограничения, по умолчанию произойдет ошибка (как и в случае с командой INSERT), а следовательно, вся команда целиком не будет выполнена. Проверим это предположение:

-- aircrafts_tmp.csv
--773,Boeing 777-300,11100
--763,Boeing 767-300,7900

COPY aircrafts_tmp
	FROM '/home/postgres/aircrafts_tmp.csv' WITH ( FORMAT csv );
--ERROR:  Key (aircraft_code)=(763) already exists.duplicate key value violates unique constraint "aircrafts_tmp_pkey" 
--ERROR:  duplicate key value violates unique constraint "aircrafts_tmp_pkey"

SELECT * FROM aircrafts_tmp;

-- aircraft_code |        model        | range 
-----------------+---------------------+-------
-- 763           | Boeing 767-300      |  7900
-- SU9           | Sukhoi SuperJet-100 |  3000

-- Действительно, как и в случае с INSERT, мы получили ошибку, при этом таблица не была изменена.



-- Задание 8*
--============


-- Задание 9*
--============


-- Задание 10*
--============



-- Глава 8

-- Задание 1



