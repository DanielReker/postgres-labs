-- Лабораторная работа 2 (глава 5)


-- Используемые стандартные таблицы:

DROP TABLE IF EXISTS students CASCADE;
CREATE TABLE students (
    record_book numeric( 5 ) NOT NULL,
    name text NOT NULL,
    doc_ser numeric( 4 ),
    doc_num numeric( 6 ),
    PRIMARY KEY ( record_book )
);

DROP TABLE IF EXISTS progress CASCADE;
CREATE TABLE progress (
	record_book numeric( 5 ) NOT NULL,
	subject text NOT NULL,
	acad_year text NOT NULL,
	term numeric( 1 ) NOT NULL CHECK ( term = 1 OR term = 2 ),
	mark numeric( 1 ) NOT NULL CHECK ( mark >= 3 AND mark <= 5 ) DEFAULT 5,
	FOREIGN KEY ( record_book )
		REFERENCES students ( record_book )
		ON DELETE CASCADE
		ON UPDATE CASCADE
);




-- Задание 1

DROP TABLE IF EXISTS students;
CREATE TABLE students (
	record_book numeric( 5 ) NOT NULL,
	name text NOT NULL,
	doc_ser numeric( 4 ),
	doc_num numeric( 6 ),
	who_adds_row text DEFAULT current_user, -- добавленный столбец
	PRIMARY KEY ( record_book )
);

INSERT INTO students ( record_book, name, doc_ser, doc_num ) VALUES
	( 12300, 'Иванов Иван Иванович', 0402, 543281 );

SELECT * FROM students;

-- Вывод:
--  record_book |         name         | doc_ser | doc_num | who_adds_row 
-- -------------+----------------------+---------+---------+--------------
--        12300 | Иванов Иван Иванович |     402 |  543281 | postgres

-- Как видим, в поле who_adds_row, если его не указать явно в INSERT, как в нашем случае, записывается текущий пользователь СУБД, то есть пользователь postgres.

-- Используя команду ALTER TABLE, добавим также поле when_row_added, содержащее время, когда была добавлена запись. Поскольку мы не можем знать, когда были добавлены уже существующие строки, добавим сначала поле без значения по умолчанию (тогда для существующих строк оно будет null), а после, для новых вставляемых строк, установим значение по умолчанию current_timestamp.

ALTER TABLE students
	ADD COLUMN when_row_added timestamptz,
	ALTER COLUMN when_row_added SET DEFAULT current_timestamp;

INSERT INTO students ( record_book, name, doc_ser, doc_num ) VALUES
	( 12301, 'Петров Петр Петрович', 1234, 123456 );

SELECT * FROM students;

-- Вывод:
--  record_book |         name         | doc_ser | doc_num | who_adds_row |        when_row_added         
-- -------------+----------------------+---------+---------+--------------+-------------------------------
--        12300 | Иванов Иван Иванович |     402 |  543281 | postgres     | 
--        12301 | Петров Петр Петрович |    1234 |  123456 | postgres     | 2024-10-31 19:27:22.851205+00

-- Как видим, старая строка действительно не содержит значение (т.е. содержит null), а новая строка содержит момент времени, когда она была добавлена.



-- Задание 2

\d progress
--                    Table "public.progress"
--    Column    |     Type     | Collation | Nullable | Default 
-- -------------+--------------+-----------+----------+---------
--  record_book | numeric(5,0) |           | not null | 
--  subject     | text         |           | not null | 
--  acad_year   | text         |           | not null | 
--  term        | numeric(1,0) |           | not null | 
--  mark        | numeric(1,0) |           | not null | 5
-- Check constraints:
--     "progress_mark_check" CHECK (mark >= 3::numeric AND mark <= 5::numeric)
--     "progress_term_check" CHECK (term = 1::numeric OR term = 2::numeric)
-- Foreign-key constraints:
--     "progress_record_book_fkey" FOREIGN KEY (record_book) REFERENCES students(record_book) ON UPDATE CASCADE ON DELETE CASCADE

ALTER TABLE progress
	ADD COLUMN test_form char( 7 ) NOT NULL CHECK ( test_form IN ( 'зачет', 'экзамен' ) ),
	ADD CHECK (
		( test_form = 'экзамен' AND mark IN ( 3, 4, 5 ) )
		OR
		( test_form = 'зачет' AND mark IN ( 0, 1 ) )
	);

-- ERROR:  Failing row contains (12300, Математика, 2024/2025, 2, 1, зачет  ).new row for relation "progress" violates check constraint "progress_mark_check" 
-- ERROR:  new row for relation "progress" violates check constraint "progress_mark_check"
-- INSERT INTO progress (record_book, subject, acad_year, term, mark, test_form) VALUES
-- 	( 12300, 'Математика', '2024/2025', 2, 1, 'зачет' );

-- Поскольку ограничения независимы, то есть вставляемая строка проверяется на соответствие всем ограничениям отдельно, получаем ошибку -- вставляемая строка нарушает ограничение progress_mark_check (3 <= оценка <= 5). Удалим это ограничение из таблицы:

ALTER TABLE progress
	DROP CONSTRAINT progress_mark_check;

INSERT INTO progress (record_book, subject, acad_year, term, mark, test_form) VALUES
	( 12300, 'Математика', '2024/2025', 2, 1, 'зачет' ),
	( 12300, 'Информатика', '2024/2025', 2, 3, 'экзамен' );

SELECT * FROM progress;

-- Вставка прошла успешно:
--  record_book |   subject   | acad_year | term | mark | test_form 
-- -------------+-------------+-----------+------+------+-----------
--        12300 | Математика  | 2024/2025 |    2 |    1 | зачет  
--        12300 | Информатика | 2024/2025 |    2 |    3 | экзамен

-- ERROR:  Failing row contains (12300, Математика, 2024/2025, 2, 5, зачет  ).new row for relation "progress" violates check constraint "progress_check" 
-- ERROR:  new row for relation "progress" violates check constraint "progress_check"
--INSERT INTO progress (record_book, subject, acad_year, term, mark, test_form) VALUES
--	( 12300, 'Математика', '2024/2025', 2, 5, 'зачет' );

--ERROR:  Failing row contains (12300, Информатика, 2024/2025, 2, 2, экзамен).new row for relation "progress" violates check constraint "progress_check" 
--ERROR:  new row for relation "progress" violates check constraint "progress_check"
--INSERT INTO progress (record_book, subject, acad_year, term, mark, test_form) VALUES
--	( 12300, 'Информатика', '2024/2025', 2, 2, 'экзамен' );

-- Как видим, новое ограничение действительно работает.



-- Задание 3*
-------------



-- Задание 4

DROP TABLE IF EXISTS progress CASCADE;
CREATE TABLE progress (
	record_book numeric( 5 ) NOT NULL,
	subject text NOT NULL,
	acad_year text NOT NULL,
	term numeric( 1 ) NOT NULL CHECK ( term = 1 OR term = 2 ),
	mark numeric( 1 ) NOT NULL CHECK ( mark >= 3 AND mark <= 5 ) DEFAULT 6, -- ошибка
	FOREIGN KEY ( record_book )
		REFERENCES students ( record_book )
		ON DELETE CASCADE
		ON UPDATE CASCADE
);
-- Ошибки нет

-- ERROR:  Failing row contains (12300, Физика, 2016/2017, 1, 6).new row for relation "progress" violates check constraint "progress_mark_check" 
-- ERROR:  new row for relation "progress" violates check constraint "progress_mark_check"
INSERT INTO progress ( record_book, subject, acad_year, term ) VALUES
    ( 12300, 'Физика', '2016/2017', 1 );

-- Как видим, на этапе создания таблицы проверки соответствия значения DEFAULT ограничениям не происходит -- она происходит лишь при вставке строки в таблицу со значением по умолчанию (т.е. без задания явного значения полю mark)



-- Задание 5

ALTER TABLE students
	ADD UNIQUE ( doc_ser, doc_num );

INSERT INTO students ( record_book, name, doc_ser, doc_num ) VALUES
	( 12300, 'Иванов Иван Иванович', 0402, 543281 ),
	( 12301, 'Иванов Иван Петрович', null, 543281 ),
	( 12302, 'Иванов Петр Петрович', null, 543281 ),
	( 12303, 'Петров Иван Иванович', 0402, null ),
	( 12304, 'Петров Петр Иванович', 0402, null ),
	( 12305, 'Петров Петр Петрович', null, null ),
	( 12306, 'Иванов Петр Иванович', null, null );

-- Ошибки нет

SELECT * FROM students;
--  record_book |         name         | doc_ser | doc_num 
-- -------------+----------------------+---------+---------
--        12300 | Иванов Иван Иванович |     402 |  543281
--        12301 | Иванов Иван Петрович |         |  543281
--        12302 | Иванов Петр Петрович |         |  543281
--        12303 | Петров Иван Иванович |     402 |        
--        12304 | Петров Петр Иванович |     402 |        
--        12305 | Петров Петр Петрович |         |        
--        12306 | Иванов Петр Иванович |         |        

-- ERROR:  Key (doc_ser, doc_num)=(402, 543281) already exists.duplicate key value violates unique constraint "students_doc_ser_doc_num_key" 
-- ERROR:  duplicate key value violates unique constraint "students_doc_ser_doc_num_key"
INSERT INTO students ( record_book, name, doc_ser, doc_num ) VALUES
	( 12307, 'Петров Иван Петрович', 0402, 543281 );

-- Как видим, ошибка, связанная с нарушением ограничение UNIQUE возникает лишь в случае, когда все поля, охватываемые UNIQUE, не являются null, и при этом строка с такими не-null значениями уже содержится в таблице. Это работает таким образом, поскольку результат сравнения null с null не определён:

SELECT (null = null);
-- ?column? 
-- ----------
--

-- Как видим, результат сравнения двух значений null на равенство не определён (т.е. сам является null)



-- Задание 6

DROP TABLE IF EXISTS students CASCADE;
CREATE TABLE students (
	record_book numeric( 5 ) NOT NULL UNIQUE,
	name text NOT NULL,
	doc_ser numeric( 4 ),
	doc_num numeric( 6 ),
	PRIMARY KEY ( doc_ser, doc_num )
);

DROP TABLE IF EXISTS progress CASCADE;
CREATE TABLE progress (
	doc_ser numeric( 4 ),
	doc_num numeric( 6 ),
	subject text NOT NULL,
	acad_year text NOT NULL,
	term numeric( 1 ) NOT NULL CHECK ( term = 1 OR term = 2 ),
	mark numeric( 1 ) NOT NULL CHECK ( mark >= 3 AND mark <= 5 ) DEFAULT 5,
	FOREIGN KEY ( doc_ser, doc_num )
		REFERENCES students ( doc_ser, doc_num )
		ON DELETE CASCADE
		ON UPDATE CASCADE
);

INSERT INTO students ( record_book, name, doc_ser, doc_num ) VALUES
	( 12300, 'Иванов Иван Иванович', 1111, 222222 ),
	( 12301, 'Иванов Иван Петрович', 3333, 222222 ),
	( 12302, 'Иванов Петр Петрович', 4444, 555555 ),
	( 12303, 'Петров Иван Иванович', 4444, 666666 );

SELECT * FROM students;

--  record_book |         name         | doc_ser | doc_num 
-- -------------+----------------------+---------+---------
--        12300 | Иванов Иван Иванович |    1111 |  222222
--        12301 | Иванов Иван Петрович |    3333 |  222222
--        12302 | Иванов Петр Петрович |    4444 |  555555
--        12303 | Петров Иван Иванович |    4444 |  666666

-- ERROR:  Key (doc_ser, doc_num)=(1111, 222222) already exists.duplicate key value violates unique constraint "students_pkey" 
-- ERROR:  duplicate key value violates unique constraint "students_pkey"
INSERT INTO students ( record_book, name, doc_ser, doc_num ) VALUES
	( 12304, 'Петров Петр Иванович', 1111, 222222 );

-- ERROR:  Failing row contains (12305, Петров Петр Петрович, null, 777777).null value in column "doc_ser" of relation "students" violates not-null constraint 
-- ERROR:  null value in column "doc_ser" of relation "students" violates not-null constraint
INSERT INTO students ( record_book, name, doc_ser, doc_num ) VALUES
	( 12305, 'Петров Петр Петрович', null, 777777 );

-- ERROR:  Failing row contains (12306, Иванов Петр Иванович, 8888, null).null value in column "doc_num" of relation "students" violates not-null constraint 
-- ERROR:  null value in column "doc_num" of relation "students" violates not-null constraint
INSERT INTO students ( record_book, name, doc_ser, doc_num ) VALUES
	( 12306, 'Иванов Петр Иванович', 8888, null );



INSERT INTO progress (doc_ser, doc_num, subject, acad_year, term, mark) VALUES
	( 1111, 222222, 'Математика', '2020/2021', 1, 3 ),
	( 1111, 222222, 'Информатика', '2020/2021', 2, 5 ),
	( 3333, 222222, 'Математика', '2023/2024', 2, 4 ),
	( 4444, 666666, 'Физика', '2023/2024', 1, 5 ),
	( 8888, null, 'Математика', '2020/2021', 1, 3 ),
	( null, 888888, 'Математика', '2020/2021', 1, 3 ),
	( null, null, 'Математика', '2020/2021', 1, 3 );

SELECT * FROM progress;

--  doc_ser | doc_num |   subject   | acad_year | term | mark 
-- ---------+---------+-------------+-----------+------+------
--     1111 |  222222 | Математика  | 2020/2021 |    1 |    3
--     1111 |  222222 | Информатика | 2020/2021 |    2 |    5
--     3333 |  222222 | Математика  | 2023/2024 |    2 |    4
--     4444 |  666666 | Физика      | 2023/2024 |    1 |    5
--     8888 |         | Математика  | 2020/2021 |    1 |    3
--          |  888888 | Математика  | 2020/2021 |    1 |    3
--          |         | Математика  | 2020/2021 |    1 |    3
	
-- ERROR:  Key (doc_ser, doc_num)=(1111, 999999) is not present in table "students".insert or update on table "progress" violates foreign key constraint "progress_doc_ser_doc_num_fkey" 
-- ERROR:  insert or update on table "progress" violates foreign key constraint "progress_doc_ser_doc_num_fkey"
INSERT INTO progress (doc_ser, doc_num, subject, acad_year, term, mark) VALUES
	( 1111, 999999, 'Математика', '2020/2021', 1, 3 );

-- ERROR:  Key (doc_ser, doc_num)=(9999, 222222) is not present in table "students".insert or update on table "progress" violates foreign key constraint "progress_doc_ser_doc_num_fkey" 
-- ERROR:  insert or update on table "progress" violates foreign key constraint "progress_doc_ser_doc_num_fkey"
INSERT INTO progress (doc_ser, doc_num, subject, acad_year, term, mark) VALUES
	( 9999, 222222, 'Математика', '2020/2021', 1, 3 );

-- Как видим, новые первичный и внешний ключи работают корректно.


-- Задание 7*
-------------



-- Задание 8

INSERT INTO students ( record_book, name, doc_ser, doc_num ) VALUES
	( 12300, 'Иванов Иван Иванович', 0402, 543281 );
	
INSERT INTO progress ( record_book, subject, acad_year, term, mark ) VALUES
	( 12300, 'Математика', '2024/2025', 1, 4 ),
	( 12300, 'Информатика', '2024/2025', 2, 3 ),
	( 12300, 'Физика', '2024/2025', 2, 5 );

SELECT * FROM progress;
--  record_book |   subject   | acad_year | term | mark 
-- -------------+-------------+-----------+------+------
--        12300 | Математика  | 2024/2025 |    1 |    4
--        12300 | Информатика | 2024/2025 |    2 |    3
--        12300 | Физика      | 2024/2025 |    2 |    5

DROP TABLE IF EXISTS subjects CASCADE;
CREATE TABLE subjects (
	subject_id serial PRIMARY KEY,
	subject text UNIQUE NOT NULL
);
INSERT INTO subjects ( subject ) VALUES
	( 'Физика' ),
	( 'Математика' ),
	( 'Информатика' );

SELECT * FROM subjects;
--  subject_id |   subject   
-- ------------+-------------
--           1 | Физика
--           2 | Математика
--           3 | Информатика

ALTER TABLE progress
	RENAME COLUMN subject TO subject_id;

ALTER TABLE progress
	ALTER COLUMN subject_id SET DATA TYPE integer
		USING ( CASE
			WHEN subject_id = 'Физика' THEN 1
			WHEN subject_id = 'Математика' THEN 2
			ELSE 3
		END );

SELECT * FROM progress;
--  record_book | subject_id | acad_year | term | mark 
-- -------------+------------+-----------+------+------
--        12300 |          2 | 2024/2025 |    1 |    4
--        12300 |          3 | 2024/2025 |    2 |    3
--        12300 |          1 | 2024/2025 |    2 |    5

ALTER TABLE progress
	ADD FOREIGN KEY ( subject_id )
		REFERENCES subjects
		ON DELETE CASCADE
		ON UPDATE CASCADE;

INSERT INTO progress ( record_book, subject_id, acad_year, term, mark ) VALUES
	( 12300, 1, '2022/2023', 1, 4 ),
	( 12300, 2, '2022/2023', 2, 3 ),
	( 12300, 3, '2022/2023', 2, 5 );

SELECT * FROM progress;
--  record_book | subject_id | acad_year | term | mark 
-- -------------+------------+-----------+------+------
--        12300 |          2 | 2024/2025 |    1 |    4
--        12300 |          3 | 2024/2025 |    2 |    3
--        12300 |          1 | 2024/2025 |    2 |    5
--        12300 |          1 | 2022/2023 |    1 |    4
--        12300 |          2 | 2022/2023 |    2 |    3
--        12300 |          3 | 2022/2023 |    2 |    5



-- Задание 9

INSERT INTO students ( record_book, name, doc_ser, doc_num ) VALUES
    ( 12300, '', 0402, 543281 ),
    ( 12346, ' ', 0406, 112233 ),
    ( 12347, '  ', 0407, 112234 );

SELECT *, length( name ) FROM students;
--  record_book | name | doc_ser | doc_num | length 
-- -------------+------+---------+---------+--------
--        12300 |      |     402 |  543281 |      0
--        12346 |      |     406 |  112233 |      1
--        12347 |      |     407 |  112234 |      2

DELETE FROM students
	WHERE trim(name) = '';
ALTER TABLE students ADD CHECK (trim(name) <> '');

-- ERROR:  Failing row contains (12300, , 402, 543281).new row for relation "students" violates check constraint "students_name_check" 
-- ERROR:  new row for relation "students" violates check constraint "students_name_check"
INSERT INTO students ( record_book, name, doc_ser, doc_num ) VALUES
    ( 12300, '', 0402, 543281 );
	
-- ERROR:  Failing row contains (12346,  , 406, 112233).new row for relation "students" violates check constraint "students_name_check" 
-- ERROR:  new row for relation "students" violates check constraint "students_name_check"
INSERT INTO students ( record_book, name, doc_ser, doc_num ) VALUES
    ( 12346, ' ', 0406, 112233 );

-- Подобное ограничение следовало бы наложить также, например, на поле subject таблицы progress (это можно сделать аналогично).



-- Задание 10

INSERT INTO students ( record_book, name, doc_ser, doc_num ) VALUES
    ( 12300, 'Иванов Иван Иванович', 0402, 543281 ),
    ( 12346, 'Петров Петр Петрович', 0016, 112233 ),
    ( 12347, 'Иванов Петр Иванович', 0007, 112234 );

-- Если не использовать USING, в преобразованных значениях не будет ведущих нулей, то есть их длина может быть меньше необходимой

ALTER TABLE students
    ALTER COLUMN doc_ser SET DATA TYPE char(4)
    USING lpad(doc_ser::text, 4, '0');
ALTER TABLE students
	ADD CHECK (doc_ser ~ '[0-9]{4}');

ALTER TABLE students
    ALTER COLUMN doc_num SET DATA TYPE char(6)
    USING lpad(doc_num::text, 6, '0');
ALTER TABLE students
	ADD CHECK (doc_num ~ '[0-9]{6}');

SELECT * FROM students;
--  record_book |         name         | doc_ser | doc_num 
-- -------------+----------------------+---------+---------
--        12300 | Иванов Иван Иванович | 0402    | 543281
--        12346 | Петров Петр Петрович | 0016    | 002233
--        12347 | Иванов Петр Иванович | 0007    | 000034



-- Задание 11*
--------------



-- Задание 12

\d flights
--                                               Table "bookings.flights"
--        Column        |           Type           | Collation | Nullable |                  Default                   
-- ---------------------+--------------------------+-----------+----------+--------------------------------------------
--  flight_id           | integer                  |           | not null | nextval('flights_flight_id_seq'::regclass)
--  flight_no           | character(6)             |           | not null | 
--  scheduled_departure | timestamp with time zone |           | not null | 
--  scheduled_arrival   | timestamp with time zone |           | not null | 
--  departure_airport   | character(3)             |           | not null | 
--  arrival_airport     | character(3)             |           | not null | 
--  status              | character varying(20)    |           | not null | 
--  aircraft_code       | character(3)             |           | not null | 
--  actual_departure    | timestamp with time zone |           |          | 
--  actual_arrival      | timestamp with time zone |           |          | 
-- Indexes:
--     "flights_pkey" PRIMARY KEY, btree (flight_id)
--     "flights_flight_no_scheduled_departure_key" UNIQUE CONSTRAINT, btree (flight_no, scheduled_departure)
-- Check constraints:
--     "flights_check" CHECK (scheduled_arrival > scheduled_departure)
--     "flights_check1" CHECK (actual_arrival IS NULL OR actual_departure IS NOT NULL AND actual_arrival IS NOT NULL AND actual_arrival > actual_departure)
--     "flights_status_check" CHECK (status::text = ANY (ARRAY['On Time'::character varying::text, 'Delayed'::character varying::text, 'Departed'::character varying::text, 'Arrived'::character varying::text, 'Scheduled'::character varying::text, 'Cancelled'::character varying::text]))
-- Foreign-key constraints:
--     "flights_aircraft_code_fkey" FOREIGN KEY (aircraft_code) REFERENCES aircrafts_data(aircraft_code)
--     "flights_arrival_airport_fkey" FOREIGN KEY (arrival_airport) REFERENCES airports_data(airport_code)
--     "flights_departure_airport_fkey" FOREIGN KEY (departure_airport) REFERENCES airports_data(airport_code)
-- Referenced by:
--     TABLE "ticket_flights" CONSTRAINT "ticket_flights_flight_id_fkey" FOREIGN KEY (flight_id) REFERENCES flights(flight_id)

ALTER TABLE flights RENAME TO flights123;

\d flights123
--                                             Table "bookings.flights123"
--        Column        |           Type           | Collation | Nullable |                  Default                   
-- ---------------------+--------------------------+-----------+----------+--------------------------------------------
--  flight_id           | integer                  |           | not null | nextval('flights_flight_id_seq'::regclass)
--  flight_no           | character(6)             |           | not null | 
--  scheduled_departure | timestamp with time zone |           | not null | 
--  scheduled_arrival   | timestamp with time zone |           | not null | 
--  departure_airport   | character(3)             |           | not null | 
--  arrival_airport     | character(3)             |           | not null | 
--  status              | character varying(20)    |           | not null | 
--  aircraft_code       | character(3)             |           | not null | 
--  actual_departure    | timestamp with time zone |           |          | 
--  actual_arrival      | timestamp with time zone |           |          | 
-- Indexes:
--     "flights_pkey" PRIMARY KEY, btree (flight_id)
--     "flights_flight_no_scheduled_departure_key" UNIQUE CONSTRAINT, btree (flight_no, scheduled_departure)
-- Check constraints:
--     "flights_check" CHECK (scheduled_arrival > scheduled_departure)
--     "flights_check1" CHECK (actual_arrival IS NULL OR actual_departure IS NOT NULL AND actual_arrival IS NOT NULL AND actual_arrival > actual_departure)
--     "flights_status_check" CHECK (status::text = ANY (ARRAY['On Time'::character varying::text, 'Delayed'::character varying::text, 'Departed'::character varying::text, 'Arrived'::character varying::text, 'Scheduled'::character varying::text, 'Cancelled'::character varying::text]))
-- Foreign-key constraints:
--     "flights_aircraft_code_fkey" FOREIGN KEY (aircraft_code) REFERENCES aircrafts_data(aircraft_code)
--     "flights_arrival_airport_fkey" FOREIGN KEY (arrival_airport) REFERENCES airports_data(airport_code)
--     "flights_departure_airport_fkey" FOREIGN KEY (departure_airport) REFERENCES airports_data(airport_code)
-- Referenced by:
--     TABLE "ticket_flights" CONSTRAINT "ticket_flights_flight_id_fkey" FOREIGN KEY (flight_id) REFERENCES flights123(flight_id)

-- Как видим, названия ограничений остались неизменными.


-- Задание 13

\d
--                    List of relations
--   Schema  |         Name          |   Type   |  Owner   
-- ----------+-----------------------+----------+----------
--  bookings | aircrafts             | view     | postgres
--  bookings | aircrafts_data        | table    | postgres
--  bookings | airports              | view     | postgres
--  bookings | airports_data         | table    | postgres
--  bookings | boarding_passes       | table    | postgres
--  bookings | bookings              | table    | postgres
--  bookings | flights               | table    | postgres
--  bookings | flights_flight_id_seq | sequence | postgres
--  bookings | flights_v             | view     | postgres
--  bookings | routes                | view     | postgres
--  bookings | seats                 | table    | postgres
--  bookings | ticket_flights        | table    | postgres
--  bookings | tickets               | table    | postgres

DROP TABLE airports_data;
-- ERROR:  cannot drop table airports_data because other objects depend on it
-- DETAIL:  view airports depends on table airports_data
-- view flights_v depends on view airports
-- view routes depends on view airports
-- constraint flights_arrival_airport_fkey on table flights depends on table airports_data
-- constraint flights_departure_airport_fkey on table flights depends on table airports_data
-- HINT:  Use DROP ... CASCADE to drop the dependent objects too.

-- Как видим, если какие-либо объекты БД зависят от таблицы, то мы не можем удалить только её. Дополним команду указанием CASCADE, как предлагается в подсказке:

DROP TABLE airports_data CASCADE;
-- NOTICE:  drop cascades to 5 other objects
-- DETAIL:  drop cascades to view airports
-- drop cascades to view flights_v
-- drop cascades to view routes
-- drop cascades to constraint flights_arrival_airport_fkey on table flights
-- drop cascades to constraint flights_departure_airport_fkey on table flights
-- DROP TABLE

\d
--                    List of relations
--   Schema  |         Name          |   Type   |  Owner   
-- ----------+-----------------------+----------+----------
--  bookings | aircrafts             | view     | postgres
--  bookings | aircrafts_data        | table    | postgres
--  bookings | boarding_passes       | table    | postgres
--  bookings | bookings              | table    | postgres
--  bookings | flights               | table    | postgres
--  bookings | flights_flight_id_seq | sequence | postgres
--  bookings | seats                 | table    | postgres
--  bookings | ticket_flights        | table    | postgres
--  bookings | tickets               | table    | postgres

-- Как видим, теперь зависимые объекты, в том числе представления flights_v и routes, были каскадно удалены вместе с таблицей airports_data.



-- Задание 14

DROP VIEW IF EXISTS long_haul_aircrafts;
CREATE VIEW long_haul_aircrafts AS
	SELECT aircraft_code, model, range FROM aircrafts_data
		WHERE range >= 6000;

SELECT * FROM long_haul_aircrafts;
--  aircraft_code |                        model                        | range 
-- ---------------+-----------------------------------------------------+-------
--  773           | {"en": "Boeing 777-300", "ru": "Боинг 777-300"}     | 11100
--  763           | {"en": "Boeing 767-300", "ru": "Боинг 767-300"}     |  7900
--  319           | {"en": "Airbus A319-100", "ru": "Аэробус A319-100"} |  6700

UPDATE long_haul_aircrafts SET range = range + 1000;
INSERT INTO long_haul_aircrafts (aircraft_code, model, range) VALUES
	( '123', '{ "en": "Test plane", "ru": "Тестовый самолёт" }'::jsonb, 13500 );
-- DELETE FROM long_haul_aircrafts WHERE aircraft_code = '773'; -- Ошибка: нарушение ссылочной целостности

SELECT * FROM long_haul_aircrafts;
--  aircraft_code |                        model                        | range 
-- ---------------+-----------------------------------------------------+-------
--  773           | {"en": "Boeing 777-300", "ru": "Боинг 777-300"}     | 12100
--  763           | {"en": "Boeing 767-300", "ru": "Боинг 767-300"}     |  8900
--  319           | {"en": "Airbus A319-100", "ru": "Аэробус A319-100"} |  7700
--  123           | {"en": "Test plane", "ru": "Тестовый самолёт"}      | 13500

SELECT * FROM aircrafts_data;
--  aircraft_code |                           model                            | range 
-- ---------------+------------------------------------------------------------+-------
--  SU9           | {"en": "Sukhoi Superjet-100", "ru": "Сухой Суперджет-100"} |  3000
--  320           | {"en": "Airbus A320-200", "ru": "Аэробус A320-200"}        |  5700
--  321           | {"en": "Airbus A321-200", "ru": "Аэробус A321-200"}        |  5600
--  733           | {"en": "Boeing 737-300", "ru": "Боинг 737-300"}            |  4200
--  CN1           | {"en": "Cessna 208 Caravan", "ru": "Сессна 208 Караван"}   |  1200
--  CR2           | {"en": "Bombardier CRJ-200", "ru": "Бомбардье CRJ-200"}    |  2700
--  773           | {"en": "Boeing 777-300", "ru": "Боинг 777-300"}            | 12100
--  763           | {"en": "Boeing 767-300", "ru": "Боинг 767-300"}            |  8900
--  319           | {"en": "Airbus A319-100", "ru": "Аэробус A319-100"}        |  7700
--  123           | {"en": "Test plane", "ru": "Тестовый самолёт"}             | 13500


-- Задание 15

ALTER VIEW long_haul_aircrafts RENAME TO long_range_aircrafts;
ALTER VIEW long_range_aircrafts RENAME COLUMN aircraft_code TO code;

SELECT * FROM long_range_aircrafts;
--  code |                        model                        | range 
-- ------+-----------------------------------------------------+-------
--  773  | {"en": "Boeing 777-300", "ru": "Боинг 777-300"}     | 12100
--  763  | {"en": "Boeing 767-300", "ru": "Боинг 767-300"}     |  8900
--  319  | {"en": "Airbus A319-100", "ru": "Аэробус A319-100"} |  7700
--  123  | {"en": "Test plane", "ru": "Тестовый самолёт"}      | 13500

DROP VIEW IF EXISTS long_range_aircrafts;
CREATE MATERIALIZED VIEW long_haul_aircrafts AS
	SELECT aircraft_code, model, range FROM aircrafts_data
		WHERE range >= 6000;

SELECT * FROM long_haul_aircrafts;
--  aircraft_code |                        model                        | range 
-- ---------------+-----------------------------------------------------+-------
--  773           | {"en": "Boeing 777-300", "ru": "Боинг 777-300"}     | 12100
--  763           | {"en": "Boeing 767-300", "ru": "Боинг 767-300"}     |  8900
--  319           | {"en": "Airbus A319-100", "ru": "Аэробус A319-100"} |  7700
--  123           | {"en": "Test plane", "ru": "Тестовый самолёт"}      | 13500

ALTER VIEW long_haul_aircrafts RENAME TO long_range_aircrafts;
ALTER VIEW long_range_aircrafts RENAME COLUMN aircraft_code TO code;

SELECT * FROM long_range_aircrafts;
--  code |                        model                        | range 
-- ------+-----------------------------------------------------+-------
--  773  | {"en": "Boeing 777-300", "ru": "Боинг 777-300"}     | 12100
--  763  | {"en": "Boeing 767-300", "ru": "Боинг 767-300"}     |  8900
--  319  | {"en": "Airbus A319-100", "ru": "Аэробус A319-100"} |  7700
--  123  | {"en": "Test plane", "ru": "Тестовый самолёт"}      | 13500


-- Задание 16

SELECT * FROM long_range_aircrafts;
--  code |                        model                        | range 
-- ------+-----------------------------------------------------+-------
--  773  | {"en": "Boeing 777-300", "ru": "Боинг 777-300"}     | 12100
--  763  | {"en": "Boeing 767-300", "ru": "Боинг 767-300"}     |  8900
--  319  | {"en": "Airbus A319-100", "ru": "Аэробус A319-100"} |  7700
--  123  | {"en": "Test plane", "ru": "Тестовый самолёт"}      | 13500

UPDATE aircrafts_data SET range = 15000 WHERE aircraft_code = '123';


SELECT * FROM long_range_aircrafts; -- Ничего не изменилось автоматически в MATERIALIZED VIEW
--  code |                        model                        | range 
-- ------+-----------------------------------------------------+-------
--  773  | {"en": "Boeing 777-300", "ru": "Боинг 777-300"}     | 12100
--  763  | {"en": "Boeing 767-300", "ru": "Боинг 767-300"}     |  8900
--  319  | {"en": "Airbus A319-100", "ru": "Аэробус A319-100"} |  7700
--  123  | {"en": "Test plane", "ru": "Тестовый самолёт"}      | 13500

REFRESH MATERIALIZED VIEW long_range_aircrafts;
SELECT * FROM long_range_aircrafts;
--  code |                        model                        | range 
-- ------+-----------------------------------------------------+-------
--  773  | {"en": "Boeing 777-300", "ru": "Боинг 777-300"}     | 12100
--  763  | {"en": "Boeing 767-300", "ru": "Боинг 767-300"}     |  8900
--  319  | {"en": "Airbus A319-100", "ru": "Аэробус A319-100"} |  7700
--  123  | {"en": "Test plane", "ru": "Тестовый самолёт"}      | 15000

-- Как видим, материализованные представления не обновляются автоматически - их нужно обновлять вручную с помощью команды REFRESH MATERIALIZED VIEW.



-- Задание 17

CREATE VIEW airports_names AS
	SELECT airport_code, airport_name, city
	FROM airports;
SELECT * FROM airports_names LIMIT 10;
--  airport_code |  airport_name   |           city           
-- --------------+-----------------+--------------------------
--  YKS          | Якутск          | Якутск
--  MJZ          | Мирный          | Мирный
--  KHV          | Хабаровск-Новый | Хабаровск
--  PKC          | Елизово         | Петропавловск-Камчатский
--  UUS          | Хомутово        | Южно-Сахалинск
--  VVO          | Владивосток     | Владивосток
--  LED          | Пулково         | Санкт-Петербург
--  KGD          | Храброво        | Калининград
--  KEJ          | Кемерово        | Кемерово
--  CEK          | Челябинск       | Челябинск

CREATE VIEW siberian_airports AS
	SELECT * FROM airports
	WHERE city = 'Новосибирск' OR city = 'Кемерово';
SELECT * FROM siberian_airports;
-- airport_code | airport_name |    city     |             coordinates              |     timezone      
-- --------------+--------------+-------------+--------------------------------------+-------------------
--  KEJ          | Кемерово     | Кемерово    | (86.1072006225586,55.27009963989258) | Asia/Novokuznetsk
--  OVB          | Толмачёво    | Новосибирск | (82.650703430176,55.012599945068)    | Asia/Novosibirsk

-- Можно создать также, например, представление, содержащее только дальнемагистральные самолёты (дальность от 6000 км):
DROP VIEW IF EXISTS long_range_aircrafts;
CREATE VIEW long_haul_aircrafts AS
	SELECT aircraft_code, model, range FROM aircrafts_data
		WHERE range >= 6000;

SELECT * FROM long_haul_aircrafts;
--  aircraft_code |                        model                        | range 
-- ---------------+-----------------------------------------------------+-------
--  773           | {"en": "Boeing 777-300", "ru": "Боинг 777-300"}     | 12100
--  763           | {"en": "Boeing 767-300", "ru": "Боинг 767-300"}     |  8900
--  319           | {"en": "Airbus A319-100", "ru": "Аэробус A319-100"} |  7700
--  123           | {"en": "Test plane", "ru": "Тестовый самолёт"}      | 15000


-- Задание 18*
--------------

