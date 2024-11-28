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

-- Можем предположить, что две строки ('ABC', NULL) и ('ABC', NULL) допустимы при уникальном индексе, поскольку все значения NULL считаются отличными друг от друга, а следовательно и кортежи, содержащие NULL, также будут считаться различными. Проверим это предположение на практике:

DROP TABLE IF EXISTS test_table;
CREATE TABLE test_table (
	column1 text,
	column2 text
);

CREATE UNIQUE INDEX
	ON test_table ( column1, column2 );

INSERT INTO test_table ( column1, column2 ) VALUES ( 'ABC', NULL );
INSERT INTO test_table ( column1, column2 ) VALUES ( 'ABC', NULL );

INSERT INTO test_table ( column1, column2 ) VALUES ( 'ABC', 'DEF' );
-- INSERT INTO test_table ( column1, column2 ) VALUES ( 'ABC', 'DEF' ); -- Ошибка

SELECT * FROM test_table;

--  column1 | column2 
-- ---------+---------
--  ABC     | 
--  ABC     | 
--  ABC     | DEF

-- Действительно, наше предположение оказалось верным.



-- Задание 2

SELECT count( * )
    FROM tickets
    WHERE passenger_name = 'IVAN IVANOV';

-- Time: 61.594 ms
-- Time: 13.982 ms
-- Time: 12.956 ms
-- Time: 13.084 ms
-- Time: 11.010 ms

CREATE INDEX
    ON tickets ( passenger_name );

-- Time: 1.120 ms
-- Time: 0.405 ms
-- Time: 0.616 ms
-- Time: 0.378 ms
-- Time: 0.596 ms

-- Как видим, первый запрос всегда выполняется дольше, чем все такие же последующие, причём как при наличии индекса, так и при его отсутствии. Это может быть связано с тем, что СУБД некоторым образом кеширует запросы после первого выполнения, и дальше использует этот кеш для выдачи последующих ответов на такой же запрос.

DROP INDEX tickets_passenger_name_idx;



-- Задание 3

SELECT count( * )
FROM ticket_flights
WHERE fare_conditions = 'Comfort';

-- Time: 25.739 ms
-- Time: 24.012 ms
-- Time: 26.576 ms
-- Time: 25.831 ms
-- Average: 25.5395 ms

SELECT count( * )
FROM ticket_flights
WHERE fare_conditions = 'Business';

-- Time: 32.673 ms
-- Time: 23.588 ms
-- Time: 24.572 ms
-- Time: 28.134 ms
-- Time: 34.452 ms
-- Average: 28.6838 ms

SELECT count( * )
FROM ticket_flights
WHERE fare_conditions = 'Economy';

-- Time: 33.282 ms
-- Time: 25.655 ms
-- Time: 28.916 ms
-- Time: 30.711 ms
-- Time: 31.301 ms
-- Average: 29.973 ms


CREATE INDEX
    ON ticket_flights ( fare_conditions );

SELECT count( * )
FROM ticket_flights
WHERE fare_conditions = 'Comfort';

-- Time: 1.718 ms
-- Time: 1.134 ms
-- Time: 0.958 ms
-- Time: 0.939 ms
-- Time: 1.272 ms
-- Average: 1.2042 ms

SELECT count( * )
FROM ticket_flights
WHERE fare_conditions = 'Business';

-- Time: 5.798 ms
-- Time: 4.302 ms
-- Time: 4.427 ms
-- Time: 4.404 ms
-- Time: 4.295 ms
-- Average: 4.6452 ms

SELECT count( * )
FROM ticket_flights
WHERE fare_conditions = 'Economy';

-- Time: 22.267 ms
-- Time: 25.814 ms
-- Time: 16.429 ms
-- Time: 18.118 ms
-- Time: 16.732 ms
-- Average: 19.872 ms

-- Можем заметить, что без индекса время подсчёта количество строк с каждым значением примерно совпадает и равняется примерно 25-30 мс, а при наличии индекса, во-первых, время запроса пропорционально количеству подсчитанных строк с искомым значением fare_conditions, а во-вторых, времена трёх запросов для каждого значения fare_conditions в сумме дают как раз около 25 мс, то есть среднее время запроса без индекса. Из этого можем сделать вывод, что без индекса при подсчёте перебираются все строки таблицы, а при наличии индекса - только те, которые имеют соответствующее значение fare_conditions (они быстро отбираются благодаря наличию индекса по fare_conditions).

DROP INDEX ticket_flights_fare_conditions_idx;



-- Задание 4

CREATE INDEX
	ON ticket_flights ( flight_id DESC NULLS FIRST, amount ASC NULLS LAST );
-- При обратном сканировании: flight_id ASC NULLS LAST, amount DESC NULLS FIRST

-- Можем предположить, что при использовании ORDER BY запросы ускорятся лишь при таком же порядке, как и в индексе (flight_id DESC NULLS FIRST, amount ASC NULLS LAST), а также при обратном порядке (flight_id ASC NULLS LAST, amount DESC NULLS FIRST), поскольку индекс также можно читать в обратном порядке. Проверим это предположение на практике:

SELECT count( * )
    FROM ticket_flights
    ORDER BY flight_id DESC NULLS FIRST, amount ASC NULLS LAST;

-- Time: 0.391 ms
-- Time: 0.402 ms
-- Time: 0.247 ms

SELECT count( * )
    FROM ticket_flights
    ORDER BY flight_id ASC NULLS LAST, amount DESC NULLS FIRST;

-- Time: 0.266 ms
-- Time: 0.241 ms
-- Time: 0.235 ms

SELECT count( * )
    FROM ticket_flights
    ORDER BY flight_id ASC NULLS LAST, amount ASC NULLS FIRST;

-- Time: 0.626 ms
-- Time: 0.493 ms
-- Time: 0.245 ms

SELECT count( * )
    FROM ticket_flights
    ORDER BY flight_id DESC NULLS LAST, amount DESC NULLS FIRST;

-- Time: 0.532 ms
-- Time: 0.370 ms
-- Time: 0.234 ms

DROP INDEX ticket_flights_flight_id_amount_idx;

-- Time: 0.493 ms
-- Time: 0.359 ms
-- Time: 0.237 ms

-- Действительно, заметно ускорились только указанные запросы.



-- Задание 5

-- Таблица flights, аэропорты отправления и прибытия

-- Вариант 1 (если чаще приходится фильтровать/сортировать выборки по конкретному аэропорту прибытия или отправления):
CREATE INDEX
    ON flights ( departure_airport )
CREATE INDEX
    ON flights ( arrival_airport )

-- Вариант 2 (если чаще приходится фильтровать/сортировать выборки по паре аэропорта отправления и прибытия - например, при поиске маршрутов):
CREATE INDEX
    ON flights ( departure_airport. arrival_airport )

-- Вариант 3 (если одинаково часто приходится фильтровать/сортировать выборки как по конкретному аэропорту прибытия или отправления, так и по их парам):
CREATE INDEX
    ON flights ( departure_airport )
CREATE INDEX
    ON flights ( arrival_airport )
CREATE INDEX
    ON flights ( departure_airport. arrival_airport )



-- Задание 6

-- Если понадобится часто находить полёты с наибольшими отклонениями от графика:

CREATE INDEX
    ON flights ( actual_departure - scheduled_departure );

CREATE INDEX
    ON flights ( actual_arrival - scheduled_arrival );



-- Задание 7*
--===========



-- Задание 8*
--===========



-- Задание 9

-- Подходит для использования с шаблонами LIKE или регулярными выражениями POSIX, если в системе с СУБД используются настройки локализации, отличные от "C"
CREATE INDEX tickets_pass_name
    ON tickets ( passenger_name text_pattern_ops );

-- Подходит для обычных сравнений <, <=, > или >=
CREATE INDEX tickets_pass_name
    ON tickets ( passenger_name );

