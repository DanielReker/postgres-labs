-- Лабораторная работа 2 (глава 4)



-- Задание 1

DROP TABLE IF EXISTS test_numeric;
CREATE TABLE test_numeric (
	measurement numeric(5, 2),
	description text
);

INSERT INTO test_numeric VALUES ( 999.9999, 'Какое-то измерение ' ); -- Ошибка
INSERT INTO test_numeric VALUES ( 999.9009, 'Еще одно измерение' );
INSERT INTO test_numeric VALUES ( 999.1111, 'И еще измерение' );
INSERT INTO test_numeric VALUES ( 998.9999, 'И еще одно' );

-- При попытке выполнить первую строку INSERT (значение 999.9999), возникает следующая ошибка:
-- ERROR:  A field with precision 5, scale 2 must round to an absolute value less than 10^3.numeric field overflow 
-- ERROR:  numeric field overflow
-- Ошибка возникает следующим образом: значение 999.9999, в отличие от типа measurement, имеет большие precision 7 и scale 4, поэтому СУБД пытается округлить значение до scale 2 по общематематическим правилам, получается значение 1000.00 -- оно имеет нужное scale 2, однако его precision равен 6, что все ещё больше precision 5 типа measurement -- заданное значение невозможно записать в поле measurement, поэтому возникает ошибка numeric field overflow. Все остальные же вставляемые значения после округления имеют scale 5, поэтому их вставка возможна.



-- Задание 2

DROP TABLE IF EXISTS test_numeric;
CREATE TABLE test_numeric (
	measurement numeric,
	description text
);

INSERT INTO test_numeric VALUES ( 1234567890.0987654321, 'Точность 20 знаков, масштаб 10 знаков' );
INSERT INTO test_numeric VALUES ( 1.5, 'Точность 2 знака, масштаб 1 знак' );
INSERT INTO test_numeric VALUES ( 0.12345678901234567890, 'Точность 21 знак, масштаб 20 знаков' );
INSERT INTO test_numeric VALUES ( 1234567890, 'Точность 10 знаков, масштаб 0 знаков (целое число)' );

SELECT * FROM test_numeric;
-- Вывод:
--       measurement       |                    description                     
-- ------------------------+----------------------------------------------------
--   1234567890.0987654321 | Точность 20 знаков, масштаб 10 знаков
--                     1.5 | Точность 2 знака, масштаб 1 знак
--  0.12345678901234567890 | Точность 21 знак, масштаб 20 знаков
--              1234567890 | Точность 10 знаков, масштаб 0 знаков (целое число)

-- Действительно, значения сохранились в таблице в точности так, как они были заданы, в том числе и с незначащими нулями, указывающими на точность числа



-- Задание 3

SELECT 'NaN'::numeric = 'NaN'::numeric; -- true
SELECT 'NaN'::numeric > 10000; -- true

-- Можем видеть, что проверяемые утверждения верны: NaN = NaN, а также NaN больше не-NaN значения.



-- Задание 4

SELECT '5e-324'::double precision > '4e-324'::double precision; -- false

SELECT '5e-324'::double precision;
--  float8 
-- --------
--  5e-324

SELECT '4e-324'::double precision;
--  float8 
-- --------
--  5e-324

-- Как мы видим, разные значения, находящиеся на границе диапазона double precision, при записи в таблицу округляются до одного значения вследствие недостатка точности. Проведём подобные эксперименты для real и double precision для очень малых и очень больших чисел

-- real:
-- SELECT '7e-46'::real; -- ERROR:  "7e-46" is out of range for type real
SELECT 3e-45::real;
SELECT
'9e-46'::real > '8e-46'::real, -- false
'1e-45'::real > '9e-46'::real, -- false
'2e-45'::real > '1e-45'::real, -- false
'3e-45'::real > '2e-45'::real, -- true
'4e-45'::real > '3e-45'::real; -- true

-- SELECT '4e38'::real; -- ERROR:  "4e38" is out of range for type real

SELECT
'3e38'::real > '2e38'::real, -- true
'2e38'::real > '1e38'::real; -- true




-- double precision:
-- SELECT '2e-324'::double precision; -- ERROR:  "2e-324" is out of range for type double precision
SELECT
'4e-324'::double precision > '3e-324'::double precision, -- false
'5e-324'::double precision > '4e-324'::double precision, -- false
'6e-324'::double precision > '5e-324'::double precision, -- false
'7e-324'::double precision > '6e-324'::double precision, -- false
'9e-324'::double precision > '8e-324'::double precision, -- false
'2e-323'::double precision > '1e-323'::double precision, -- true
'3e-323'::double precision > '2e-323'::double precision; -- true

-- SELECT '1.8e308'::double precision; -- ERROR:  "1.8e308" is out of range for type double precision

SELECT
'1.7e308'::double precision > '1.6e308'::double precision, -- true
'1.6e308'::double precision > '1.5e308'::double precision; -- true

-- Можем заметить, что результаты для real и для double precision аналогичны. Кроме того, в обоих случаях, в отличие от очень малых значений (положительных), при очень больших значениях проблем с точностью при сравнении не возникает. Из этого можем сделать вывол, что значения с плавающей точкой могут вести себя непредсказуемо на очень малых положительных значениях.



-- Задание 5

-- SELECT '1.7976931348623159E+308'::double precision; -- ERROR:  "1.7976931348623159E+308" is out of range for type double precision
SELECT 'Inf'::double precision > '1.7976931348623158E+308'::double precision; -- true

-- SELECT '2E-324'::double precision; -- ERROR:  "2E-324" is out of range for type double precision
SELECT '-Inf' < '3E-324'::double precision; -- true

-- Как и ожидалось, Inf больше самого большого значения, а -Inf меньше самого маленького значения double precision.



-- Задание 6

SELECT 0.0 * 'Inf'::real; -- NaN (real)
SELECT 'NaN'::real = 'NaN'::real; -- true
SELECT 'NaN'::real > 'Inf'::real; -- true
SELECT 'Inf'::real = 'Inf'::real; -- true

-- Как видим, для real NaN = NaN, Inf = Inf, но NaN > Inf, так как NaN больше любого не-NaN значения. Аналогичный результат получаем и для double precision:

SELECT 0.0 * 'Inf'::double precision; -- NaN (double precision)
SELECT 'NaN'::double precision = 'NaN'::double precision; -- true
SELECT 'NaN'::double precision > 'Inf'::double precision; -- true
SELECT 'Inf'::double precision = 'Inf'::double precision; -- true


-- Задание 7

DROP TABLE IF EXISTS test_serial;
CREATE TABLE test_serial (
	id serial,
	name text
);

INSERT INTO test_serial ( name ) VALUES ( 'Вишневая' );
INSERT INTO test_serial ( name ) VALUES ( 'Грушевая' );
INSERT INTO test_serial ( name ) VALUES ( 'Зеленая' );
INSERT INTO test_serial ( id, name ) VALUES ( 10, 'Прохладная' );
INSERT INTO test_serial ( name ) VALUES ( 'Луговая' );

SELECT * FROM test_serial;

--  id |    name    
-- ----+------------
--   1 | Вишневая
--   2 | Грушевая
--   3 | Зеленая
--  10 | Прохладная
--   4 | Луговая

-- Как видим, вставка строки с вручную заданным значением id = 10 действительно не повлияла на автоматическую генерацию, поскольку никак не повлияла на автоматически созданную для столбца последовательность test_serial_id_seq.



-- Задание 8

DROP TABLE IF EXISTS test_serial;
CREATE TABLE test_serial (
	id serial PRIMARY KEY,
	name text
);

INSERT INTO test_serial ( name ) VALUES ( 'Вишневая' ); -- здесь используется значение id = 1 (последовательность)
INSERT INTO test_serial ( id, name ) VALUES ( 2, 'Прохладная' ); -- здесь используется значение id = 2 (вручную)
INSERT INTO test_serial ( name ) VALUES ( 'Грушевая' ); -- здесь используется значение id = 2 (последовательность) - ошибка
-- ERROR:  Key (id)=(2) already exists.duplicate key value violates unique constraint "test_serial_pkey" 
-- ERROR:  duplicate key value violates unique constraint "test_serial_pkey"

-- При вставке строки с name = 'Грушевая' мы получили ошибку, сообщающую нам о том, что значение id = 2 уже существует в таблице, то есть вставляемая строка нарушает ограничение уникальности первичного ключа. Это происходит потому, что вставка строки с вручную заданным id = 2 и name = 'Прохладная' никак не повлиала на текущее значение последовательности test_serial_id_seq, созданную автоматически для типа serial, то есть к моменту вызова вставки строки с name = 'Грушевая', значение последовательности равно 2 (с 1 до 2 оно увеличилось при вставке строки с name = 'Вишневая') и, соответственно, СУБД использует в качестве id значение 2, а оно уже существует в таблице.
-- Если же мы попытаемся вставить строку ещё раз, то никакой ошибки не будет, поскольку при предыдущей, неудачной попытке вставки, значение последовательности было увеличено на 1, то есть стало теперь 3.
INSERT INTO test_serial ( name ) VALUES ( 'Грушевая' ); -- здесь используется значение id = 3 (последовательность)

INSERT INTO test_serial ( name ) VALUES ( 'Зеленая' ); -- здесь используется значение id = 4 (последовательность)
DELETE FROM test_serial WHERE id = 4;
INSERT INTO test_serial ( name ) VALUES ( 'Луговая' ); -- здесь используется значение id = 5 (последовательность)
SELECT * FROM test_serial;
-- +------+--------------+
-- | "id" |    "name"    |
-- +------+--------------+
-- |    1 | "Вишневая"   |
-- |    2 | "Прохладная" |
-- |    3 | "Грушевая"   |
-- |    5 | "Луговая"    |
-- +------+--------------+

-- Как и ожидалось, при вставке строки с name = 'Луговая' в качестве id было использовано текущее значение последовательности - 5. То есть, удаление строки из таблицы также никак не повлияло на последовательность test_serial_id_seq. Таким образом, можем сделать вывод, что последовательность, автоматически создаваемая при использовании типа данных serial, существует независимо от значений столбца, для нумерации которого она используется, то есть изменения в таблице никак не влияют на значение такой последовательности.

-- Задание 9

-- Для работы с датами в PostgreSQL используется григорианский (современный) календарь.



-- Задание 10

-- Приведём таблицу типов данных даты/времени из раздела 8.5 документации PostgreSQL (https://postgrespro.ru/docs/postgresql/15/datatype-datetime)
-- +-----------------------------------------+---------+----------------------------------------+---------------------+---------------------+----------------+
-- |                   Имя                   | Размер  |                Описание                | Наименьшее значение | Наибольшее значение |    Точность    |
-- +-----------------------------------------+---------+----------------------------------------+---------------------+---------------------+----------------+
-- | timestamp [ (p) ] [ without time zone ] | 8 байт  | дата и время (без часового пояса)      | 4713 до н. э.       | 294276 н. э.        | 1 микросекунда |
-- | timestamp [ (p) ] with time zone        | 8 байт  | дата и время (с часовым поясом)        | 4713 до н. э.       | 294276 н. э.        | 1 микросекунда |
-- | date                                    | 4 байта | дата (без времени суток)               | 4713 до н. э.       | 5874897 н. э.       | 1 день         |
-- | time [ (p) ] [ without time zone ]      | 8 байт  | время суток (без даты)                 | 00:00:00            | 24:00:00            | 1 микросекунда |
-- | time [ (p) ] with time zone             | 12 байт | время дня (без даты), с часовым поясом | 00:00:00+1559       | 24:00:00-1559       | 1 микросекунда |
-- | interval [ поля ] [ (p) ]               | 16 байт | временной интервал                     | -178000000 лет      | 178000000 лет       | 1 микросекунда |
-- +-----------------------------------------+---------+----------------------------------------+---------------------+---------------------+----------------+

-- Для типов, содержащих информацию о дате, в качестве минимального значения был выбран 4713 год до н.э. - это год начала первого юлианского периода. Максимальные же значения, вероятнее всего, посчитаны исходя из точности и вмещаемого в размер байт количества информации. Для времени были взяты наиболее естественные границы - от 0 до 24 часов. Значения для интервала симметричны, а расстояние между ними, вероятнее всего, было рассчитано исходя из точности (1 мкс) и размера (16 байт).



-- Задание 11

SELECT current_time;
--    current_time    
-- --------------------
--  16:04:45.395258+00

SELECT current_time::time(0);
--    current_time 
-- --------------
--  16:05:19

SELECT current_time::time(3);
--    current_time 
-- --------------
--  16:05:53.523


SELECT
current_timestamp::timestamp AS timestamp,
current_timestamp::timestamp(0) AS timestamp0,
current_timestamp::timestamp(3) AS timestamp3;
--          timestamp          |     timestamp0      |       timestamp3        
-- ----------------------------+---------------------+-------------------------
--  2024-10-16 16:09:18.594394 | 2024-10-16 16:09:19 | 2024-10-16 16:09:18.594

SELECT
(current_timestamp - '1945-05-09'::timestamptz)::interval AS interval,
(current_timestamp - '1945-05-09'::timestamptz)::interval(0) AS interval0,
(current_timestamp - '1945-05-09'::timestamptz)::interval(3) AS interval3;
--           interval          |      interval0      |        interval3        
-- ----------------------------+---------------------+-------------------------
--  29015 days 16:27:22.433898 | 29015 days 16:27:22 | 29015 days 16:27:22.434

-- Как видим, типы time, timestamp и interval действительно позволяют задать точность ввода и вывода. Тип date же такой возможности не имеет, поскольку он оперирует не с непрерывными значениями конкретных моментов времени, а с целочисленными значениями дат - если бы тип date позволял задавать дробные даты, он ничем бы не отличался от типа timestamp.



-- Задание 12*
-------------------



-- Задание 13

-- PGDATESTYLE="Postgres" psql -d test -U postgres -h localhost
SHOW datestyle;
--    DateStyle
-- ---------------
--  Postgres, MDY



-- Задание 14

-- postgresql.conf: datestyle = 'iso, mdy'
SHOW datestyle;
--  DateStyle
-- -----------
--  ISO, MDY

-- postgresql.conf: datestyle = 'iso, ymd'
SHOW datestyle;
--  DateStyle
-- -----------
--  ISO, YMD

-- Задание 15

SELECT
to_char(current_timestamp, 'mi:ss'),
to_char(current_timestamp, 'dd'),
to_char(current_timestamp, 'yyyy-mm-dd'),
to_char(current_timestamp, 'dd.mm.yyyy hh24:mi:ss');

--  to_char | to_char |  to_char   |       to_char       
-- ---------+---------+------------+---------------------
--  52:33   | 16      | 2024-10-16 | 16.10.2024 17:52:33

-- как видим, mi - минуты, ss - секунды, yyyy - год (4 цифры), dd - день, mm - месяц, hh24 - часы в 24-часовом формате, и т.д.



-- Задание 16

SELECT 'Feb 29, 2015'::date;
-- ERROR:  date/time field value out of range: "Feb 29, 2015" - эта ошибка сообщает нам о том, что указанной даты в реальности не существует



-- Задание 17

SELECT '21:15:16:22'::time;
-- ERROR:  invalid input syntax for type time: "21:15:16:22" -- эта ошибка сообщает нам о том, что синтаксис (формат) введённой в виде строки даты некорректен



-- Задание 18

-- Даты можно рассматривать как целые числа, то есть количества дней, прошедших с определённой, выбранной заранее точки отсчёта, поэтому можно предположить, что при вычитании одной даты из другой мы получим целое число, означающее, сколько дней прошло между двумя датами
SELECT ('2016-09-16'::date - '2016-09-01'::date);
--  ?column? 
-- ----------
--        15
-- Как видим, мы действительно получили целое число 15 с 1-го сентября 2016 до 16-го сентября 2016 прошло 15 дней



-- Задание 19

-- Можем предположить, что при вычитании двух значений типа type мы получим значение типа interval, поскольку, по аналогии с предыдущими рассуждениями, времена можно рассматривать как числа, означающие, сколько времени прошло с некоторой выбранной заранее точки отсчёта до заданного времени (в некоторой единице измерения -- например, в милисекундах). Тип interval используется как раз для хранения продолжительности отрезка времени, то есть количества времени без какой-либо базовой точки отсчёта. Проверим наше предположение на практике:
SELECT ('20:34:35'::time - '19:44:45'::time);
--  ?column? 
-- ----------
--  00:49:50
-- Как видим, мы действительно получили продолжительность отрезка времени между 19:44:45 и 20:34:35 - 49 минут и 50 секунд.

-- При попытке же заменить знак '-' на '+', можем предположить, что СУБД вернёт ошибку, поскольку в отличие от предыдущего случая, в котором одинаковые значения точки отсчёта вычиитаются друг из друга и сокращаются, оставляя лишь количество времени, прошедшее между двумя моментами времени, при сложении базовая точка отсчёта удвоится, поэтому получившийся результат не получится интерпретировать в каком-либо прикладном смысле. Проверим наше предположение:
SELECT ('20:34:35'::time + '19:44:45'::time);
-- ERROR:  operator is not unique: time without time zone + time without time zone
-- LINE 1: SELECT ('20:34:35'::time + '19:44:45'::time);
--                                  ^
-- HINT:  Could not choose a best candidate operator. You might need to add explicit type casts.
-- Действительно, получаем ошибку, которая сообщает нам о том, что невозможно выбрать однозначную (наилучшую) операцию, соответствующую сигнатуре "type + type", то есть не понятно, что оператор, вводящий такую команду, имеет в виду и желает получить.


-- Задание 20

SELECT (current_timestamp - '2016-01-01'::timestamp) AS new_date;
--         new_date          
-- ---------------------------
--  3211 days 18:53:22.994112

-- Поскольку timestamp2 - timestamp1 = interval12, то, прибавив с обеих сторон timestamp1 и получив timestamp2 = timestamp1 + interval12, логично предположить, что прибавив к моменту времени некоторый интервал, мы получим другой момент времени, который позже исходного на количество времени, содержащееся в интервале. Проверим это предположение:
SELECT (current_timestamp + '1 mon'::interval) AS new_date;
--           new_date            
-- -------------------------------
--  2024-11-16 18:56:54.772166+00
-- Действительно, мы получили дату и время, которые ровно на месяц позднее, чем текущие (16.10.2024). Также попробуем выполнить команду без псевдонима:
SELECT (current_timestamp + '1 mon'::interval);
--           ?column?           
-- ------------------------------
--  2024-11-16 18:59:09.30299+00
-- Можем видеть, что не изменилось ничего, кроме нескольких минут, прошедших между выполнениями запросов, а также заменой названия new_date на ?column? (не заданное название).



-- Задание 21

-- Можем предположить, что каждый интервал обозначает единственное, конкретное количество времени -- так, интервал '1 mon'::inverval, вероятнее всего, будет равен интервалу в 30 дней. Проверим это на практике:
SELECT
('2016-01-31'::date + '1 mon'::interval) AS new_date_1, -- "2016-02-29 00:00:00"
('2016-02-29'::date + '1 mon'::interval) AS new_date_2, -- "2016-03-29 00:00:00"
('2016-03-29'::date + '1 mon'::interval) AS new_date_2; -- "2016-04-29 00:00:00"

SELECT
('2016-02-29'::date - '2016-01-31'::date) AS actual_interval_1,
('2016-03-29'::date - '2016-02-29'::date) AS actual_interval_2,
('2016-04-29'::date - '2016-03-29'::date) AS actual_interval_3;
--  actual_interval_1 | actual_interval_2 | actual_interval_3 
-- -------------------+-------------------+-------------------
--                 29 |                29 |                31

-- Как видим, наше предположение оказалось неверным - в зависимости от даты, к которой прибавлялся интервал в 1 месяц, его реальный размер составлял различные значения - например, 29 и 31. Как можно понять из рассмотренных примеров, при прибавлении к дате 1 месяца СУБД пытается лишь увеличить номер месяца, сохранив номер дня. Если же в новом месяце не существует старого номера дня, то берётся номер последний номер нового месяца.



-- Задание 22

SET intervalstyle TO 'iso_8601';
SHOW intervalstyle; -- iso_8601
SELECT current_timestamp - '1945-05-09'::timestamptz; -- P29015DT19H48M26.299906S

SET intervalstyle TO 'sql_standard';
SHOW intervalstyle; -- sql_standard
SELECT current_timestamp - '1945-05-09'::timestamptz; -- 29015 19:48:46.232028

SET intervalstyle TO DEFAULT;
SHOW intervalstyle; -- postgres
SELECT current_timestamp - '1945-05-09'::timestamptz; -- 29015 days 19:49:01.011398



-- Задание 23

SELECT ('2016-09-16'::date - '2015-09-01'::date); -- 381
SELECT ('2016-09-16'::timestamp - '2015-09-01'::timestamp); -- 381 days

-- Разница между датами возвращает количество дней, то есть целое число, поэтому оно выводится как целое число, без какого-либо форматирования. Разница же между timestamp, то есть моментами времени, возвращает interval, который при выводе форматируется соответствующим образом (в нашем случае intervalstyle = 'postgres' по умолчанию, поэтому интервал форматируется в виде "3381 days").



-- Задание 24

SELECT ('20:34:35'::time - 1);
-- ERROR:  operator does not exist: time without time zone - integer
-- LINE 1: SELECT ('20:34:35'::time - 1);
--                                  ^
-- HINT:  No operator matches the given name and argument types. You might need to add explicit type casts.

SELECT ('2016-09-16'::date - 1); -- 2016-09-15

-- В первом случае возникает ошибка, поскольку оператор вычитания целого числа из типа time не определён. Вероятнее всего, это связано с тем, что нет единого и очевидного для всех способа интерпретировать целочисленное значение 1 - это может быть день, секунда, милисекунда, микросекунда и так далее. Во втором же случае, поскольку мы имеем дело с датами, которые можно воспринимать, как целые числа, вполне естественно считать за единицу наименьшую неделимую разницу дат - 1 день.



-- Задание 25

SELECT (date_trunc('microsecond', timestamp '1999-11-27 12:34:56.987654')); -- "1999-11-27 12:34:56.987654"
SELECT (date_trunc('millisecond', timestamp '1999-11-27 12:34:56.987654')); -- "1999-11-27 12:34:56.987"
SELECT (date_trunc('second', timestamp '1999-11-27 12:34:56.987654')); -- "1999-11-27 12:34:56"
SELECT (date_trunc('minute', timestamp '1999-11-27 12:34:56.987654')); -- "1999-11-27 12:34:00"
SELECT (date_trunc('hour', timestamp '1999-11-27 12:34:56.987654')); -- "1999-11-27 12:00:00"
SELECT (date_trunc('day', timestamp '1999-11-27 12:34:56.987654')); -- "1999-11-27 00:00:00"
SELECT (date_trunc('week', timestamp '1999-11-27 12:34:56.987654')); -- "1999-11-22 00:00:00"
SELECT (date_trunc('month', timestamp '1999-11-27 12:34:56.987654')); -- "1999-11-01 00:00:00"
SELECT (date_trunc('year', timestamp '1999-11-27 12:34:56.987654')); -- "1999-01-01 00:00:00"
SELECT (date_trunc('decade', timestamp '1999-11-27 12:34:56.987654')); -- "1990-01-01 00:00:00"
SELECT (date_trunc('century', timestamp '1999-11-27 12:34:56.987654')); -- "1901-01-01 00:00:00"
SELECT (date_trunc('millennium', timestamp '1999-11-27 12:34:56.987654')); -- "1001-01-01 00:00:00"

-- Действительно, функция date_trunc округляет в меньшую сторону, отбрасывая все меньшие единицы. При использовании же в качестве первого параметра функции неделю, выбирается ближайший снизу понедельник (или текущая дата, если она и так является понедельником).



-- Задание 26

SELECT (date_trunc('microsecond', interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- "1999 years 11 mons 27 days 12:34:56.987654"
SELECT (date_trunc('millisecond', interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- "1999 years 11 mons 27 days 12:34:56.987"
SELECT (date_trunc('second', interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- "1999 years 11 mons 27 days 12:34:56"
SELECT (date_trunc('minute', interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- "1999 years 11 mons 27 days 12:34:00"
SELECT (date_trunc('hour', interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- "1999 years 11 mons 27 days 12:00:00"
SELECT (date_trunc('day', interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- "1999 years 11 mons 27 days"
SELECT (date_trunc('week', interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- week не поддерживается для interval
--ERROR:  Months usually have fractional weeks.unit "week" not supported for type interval 
--ERROR:  unit "week" not supported for type interval

SELECT (date_trunc('month', interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- "1999 years 11 mons"
SELECT (date_trunc('year', interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- "1999 years"
SELECT (date_trunc('decade', interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- "1990 years"
SELECT (date_trunc('century', interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- "1900 years"
SELECT (date_trunc('millennium', interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- "1000 years"



-- Задание 27

SELECT (extract('microsecond' from timestamp '1999-11-27 12:34:56.987654')); -- 56987654
SELECT (extract('millisecond' from timestamp '1999-11-27 12:34:56.987654')); -- 56987.654
SELECT (extract('second' from timestamp '1999-11-27 12:34:56.987654')); -- 56.987654
SELECT (extract('minute' from timestamp '1999-11-27 12:34:56.987654')); -- 34
SELECT (extract('hour' from timestamp '1999-11-27 12:34:56.987654')); -- 12
SELECT (extract('day' from timestamp '1999-11-27 12:34:56.987654')); -- 27
SELECT (extract('week' from timestamp '1999-11-27 12:34:56.987654')); -- 47
SELECT (extract('month' from timestamp '1999-11-27 12:34:56.987654')); -- 11
SELECT (extract('year' from timestamp '1999-11-27 12:34:56.987654')); -- 1999
SELECT (extract('decade' from timestamp '1999-11-27 12:34:56.987654')); -- 199
SELECT (extract('century' from timestamp '1999-11-27 12:34:56.987654')); -- 20
SELECT (extract('millennium' from timestamp '1999-11-27 12:34:56.987654')); -- 2



-- Задание 28

SELECT (extract('microsecond' from interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- 56987654
SELECT (extract('millisecond' from interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- 56987.654
SELECT (extract('second' from interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- 56.987654
SELECT (extract('minute' from interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- 34
SELECT (extract('hour' from interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- 12
SELECT (extract('day' from interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- 27
SELECT (extract('week' from interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- ERROR:  unit "week" not supported for type interval
SELECT (extract('month' from interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- 11
SELECT (extract('year' from interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- 1999
SELECT (extract('decade' from interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- 199
SELECT (extract('century' from interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- 19
SELECT (extract('millennium' from interval '1999 years 11 months 27 days 12 hours 34 minutes 56.987654 seconds')); -- 1
-- Можем заметить, что в отличие от timestamp, при работе с interval функция extract не поддерживает недели. Кроме того, века и тысячелетия обрабатываются по-разному (вероятно, это связано с тем, что не имея конкретной даты, содержащей помимо количества времени базовую точку отсчёта, невозможно определить, к какому конкретно веку/тысячелетию относится интервал, то есть extract возвращает лишь полное количество веков/тысячелетий, которые занимает заданный период - так, например, 1999 лет - это всего лишь 1 полное тысячелетие (1000 лет), однако 1999 год относится ко второму тысячелетию, поскольку счёт тысячелетий начинается с единицы).



-- Задание 29*
--------------



-- Задание 30*
--------------



-- Задание 31*
--------------



-- Задание 32

SELECT ARRAY[1,4,3] @> ARRAY[3,1,3]; -- true
SELECT ARRAY[2,2,7] <@ ARRAY[1,7,4,2,6]; -- true
SELECT ARRAY[1,4,3] && ARRAY[2,1]; -- true
SELECT ARRAY[1,2,3] || ARRAY[4,5,6,7]; -- {1,2,3,4,5,6,7}
SELECT ARRAY[1,2,3] || ARRAY[[4,5,6],[7,8,9.9]]; -- {{1,2,3},{4,5,6},{7,8,9.9}}
SELECT 3 || ARRAY[4,5,6]; -- {3,4,5,6}
SELECT ARRAY[4,5,6] || 7; -- {4,5,6,7}
SELECT array_append(ARRAY[1,2], 3); -- {1,2,3}
SELECT array_cat(ARRAY[1,2,3], ARRAY[4,5]); -- {1,2,3,4,5}
SELECT array_dims(ARRAY[[1,2,3], [4,5,6]]); -- "[1:2][1:3]"
SELECT array_fill(11, ARRAY[2,3]); -- {{11,11,11},{11,11,11}}
SELECT array_fill(7, ARRAY[3], ARRAY[2]); -- [2:4]={7,7,7}
SELECT array_length(array[1,2,3], 1); -- 3
SELECT array_length(array[]::int[], 1); -- null
SELECT array_length(array['text'], 2); -- null
SELECT array_lower('[0:2]={1,2,3}'::integer[], 1); -- 0
SELECT array_ndims(ARRAY[[1,2,3], [4,5,6]]); -- 2
SELECT array_position(ARRAY['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'], 'mon'); -- 2
SELECT array_positions(ARRAY['A','A','B','A'], 'A'); -- {1,2,4}
SELECT array_prepend(1, ARRAY[2,3]); -- {1,2,3}
SELECT array_remove(ARRAY[1,2,3,2], 2); -- {1,3}
SELECT array_replace(ARRAY[1,2,5,4], 5, 3); -- {1,2,3,4}
SELECT array_to_string(ARRAY[1, 2, 3, NULL, 5], ',', '*'); -- "1,2,3,*,5"
SELECT array_upper(ARRAY[1,8,3,7], 1); -- 4
SELECT cardinality(ARRAY[[1,2],[3,4]]); -- 4
SELECT trim_array(ARRAY[1,2,3,4,5,6], 2); -- {1,2,3,4}
SELECT unnest(ARRAY[1,2]);
--  unnest 
-- --------
--       1
--       2
SELECT unnest(ARRAY[['foo','bar'],['baz','quux']]);
--  unnest 
-- --------
--  foo
--  bar
--  baz
--  quux
SELECT * FROM unnest(ARRAY[1,2], ARRAY['foo','bar','baz']) AS x(a,b)
--  a |  b  
-- ---+-----
--  1 | foo
--  2 | bar
--    | baz



-- Задание 33*
--------------



-- Задание 34

DROP TABLE IF EXISTS pilot_hobbies;
CREATE TABLE pilot_hobbies (
	pilot_name text,
	hobbies jsonb
);
INSERT INTO pilot_hobbies
VALUES (
	'Ivan',
	'{ "sports": [ "футбол", "плавание" ], "home_lib": true, "trips": 3}'::jsonb
), (
	'Petr',
	'{ "sports": [ "теннис", "плавание" ], "home_lib": true, "trips": 2 }'::jsonb
), (
	'Pavel',
	'{ "sports": [ "плавание" ], "home_lib": false, "trips": 4 }'::jsonb
), (
	'Boris',
	'{ "sports": [ "футбол", "плавание", "теннис" ], "home_lib": true, "trips": 0 }'::jsonb
);
SELECT * FROM pilot_hobbies;
--  pilot_name |                                  hobbies                                   
-- ------------+----------------------------------------------------------------------------
--  Ivan       | {"trips": 3, "sports": ["футбол", "плавание"], "home_lib": true}
--  Petr       | {"trips": 2, "sports": ["теннис", "плавание"], "home_lib": true}
--  Pavel      | {"trips": 4, "sports": ["плавание"], "home_lib": false}
--  Boris      | {"trips": 0, "sports": ["футбол", "плавание", "теннис"], "home_lib": true}

UPDATE pilot_hobbies
	SET hobbies = jsonb_set(hobbies, '{ home_lib }', 'false')
	WHERE pilot_name = 'Petr';
SELECT * FROM pilot_hobbies;
-- pilot_name |                                  hobbies                                   
-- ------------+----------------------------------------------------------------------------
--  Ivan       | {"trips": 3, "sports": ["футбол", "плавание"], "home_lib": true}
--  Pavel      | {"trips": 4, "sports": ["плавание"], "home_lib": false}
--  Boris      | {"trips": 0, "sports": ["футбол", "плавание", "теннис"], "home_lib": true}
--  Petr       | {"trips": 2, "sports": ["теннис", "плавание"], "home_lib": false}



-- Задание 35

SELECT '[{"a":"foo"},{"b":"bar"},{"c":"baz"}]'::json -> 2; -- "{""c"":""baz""}"
SELECT '[{"a":"foo"},{"b":"bar"},{"c":"baz"}]'::json -> -3; -- "{""a"":""foo""}"
SELECT '{"a": {"b":"foo"}}'::json -> 'a'; -- "{""b"":""foo""}"
SELECT '[1,2,3]'::json ->> 2; -- "3"
SELECT '{"a":1,"b":2}'::json ->> 'b'; -- "2"
SELECT '{"a": {"b": ["foo","bar"]}}'::json #> '{a,b,1}'; -- """bar"""
SELECT '{"a": {"b": ["foo","bar"]}}'::json #>> '{a,b,1}'; -- "bar"
SELECT '{"a":1, "b":2}'::jsonb @> '{"b":2}'::jsonb; -- true
SELECT '{"b":2}'::jsonb <@ '{"a":1, "b":2}'::jsonb; -- true
SELECT '{"a":1, "b":2}'::jsonb ? 'b'; -- true
SELECT '["a", "b", "c"]'::jsonb ? 'b'; -- true
SELECT '{"a":1, "b":2, "c":3}'::jsonb ?| array['b', 'd']; -- true
SELECT '["a", "b", "c"]'::jsonb ?& array['a', 'b']; -- true
SELECT '["a", "b"]'::jsonb || '["a", "d"]'::jsonb; -- "[""a"", ""b"", ""a"", ""d""]"
SELECT '{"a": "b"}'::jsonb || '{"c": "d"}'::jsonb; -- "{""a"": ""b"", ""c"": ""d""}"
SELECT '[1, 2]'::jsonb || '3'::jsonb; -- "[1, 2, 3]"
SELECT '{"a": "b"}'::jsonb || '42'::jsonb; -- "[{""a"": ""b""}, 42]"
SELECT '[1, 2]'::jsonb || jsonb_build_array('[3, 4]'::jsonb); -- "[1, 2, [3, 4]]"
SELECT '{"a": "b", "c": "d"}'::jsonb - 'a'; -- "{""c"": ""d""}"
SELECT '["a", "b", "c", "b"]'::jsonb - 'b'; -- "[""a"", ""c""]"
SELECT '{"a": "b", "c": "d"}'::jsonb - '{a,c}'::text[]; -- "{}"
SELECT '["a", "b"]'::jsonb - 1; -- "[""a""]"
SELECT '["a", {"b":1}]'::jsonb #- '{1,b}'; -- "[""a"", {}]"
SELECT '{"a":[1,2,3,4,5]}'::jsonb @? '$.a[*] ? (@ > 2)'; -- true
SELECT '{"a":[1,2,3,4,5]}'::jsonb @@ '$.a[*] > 2'; -- true
SELECT to_json('Fred said "Hi."'::text); -- """Fred said \""Hi.\"""""
SELECT to_jsonb(row(42, 'Fred said "Hi."'::text)); -- "{""f1"": 42, ""f2"": ""Fred said \""Hi.\""""}"
SELECT array_to_json('{{1,5},{99,100}}'::int[]); -- "[[1,5],[99,100]]"
SELECT row_to_json(row(1,'foo')); -- "{""f1"":1,""f2"":""foo""}"
SELECT json_build_array(1, 2, 'foo', 4, 5); -- "[1, 2, ""foo"", 4, 5]"
SELECT json_build_object('foo', 1, 2, row(3,'bar')); -- 
SELECT json_object('{a, 1, b, "def", c, 3.5}'); -- "{""a"" : ""1"", ""b"" : ""def"", ""c"" : ""3.5""}"
SELECT json_object('{{a, 1}, {b, "def"}, {c, 3.5}}'); -- "{""a"" : ""1"", ""b"" : ""def"", ""c"" : ""3.5""}"
SELECT json_object('{a,b}', '{1,2}'); -- "{""a"" : ""1"", ""b"" : ""2""}"
SELECT json_array_length('[1,2,3,{"f1":1,"f2":[5,6]},4]'); -- 5
SELECT json_extract_path('{"f2":{"f3":1},"f4":{"f5":99,"f6":"foo"}}', 'f4', 'f6'); -- """foo"""
SELECT jsonb_set('[{"f1":1,"f2":null},2,null,3]', '{0,f1}', '[2,3,4]', false); -- "[{""f1"": [2, 3, 4], ""f2"": null}, 2, null, 3]"
SELECT jsonb_set('[{"f1":1,"f2":null},2]', '{0,f3}', '[2,3,4]'); -- "[{""f1"": 1, ""f2"": null, ""f3"": [2, 3, 4]}, 2]"
SELECT jsonb_insert('{"a": [0,1,2]}', '{a, 1}', '"new_value"'); -- "{""a"": [0, ""new_value"", 1, 2]}"
SELECT jsonb_insert('{"a": [0,1,2]}', '{a, 1}', '"new_value"', true); -- "{""a"": [0, 1, ""new_value"", 2]}"
SELECT json_typeof('-123.4'); -- "number"
SELECT json_typeof('null'::json); -- "null"
SELECT json_typeof(NULL::json) IS NULL; -- true


-- Задание 36*
--------------



-- Задание 37

DROP TABLE IF EXISTS pilot_hobbies;
CREATE TABLE pilot_hobbies (
	pilot_name text,
	hobbies jsonb
);
INSERT INTO pilot_hobbies
VALUES (
	'Ivan',
	'{ "sports": [ "футбол", "плавание" ], "home_lib": true, "trips": 3}'::jsonb
), (
	'Petr',
	'{ "sports": [ "теннис", "плавание" ], "home_lib": true, "trips": 2 }'::jsonb
), (
	'Pavel',
	'{ "sports": [ "плавание" ], "home_lib": false, "trips": 4 }'::jsonb
), (
	'Boris',
	'{ "sports": [ "футбол", "плавание", "теннис" ], "home_lib": true, "trips": 0 }'::jsonb
);
SELECT * FROM pilot_hobbies;
--  pilot_name |                                  hobbies                                   
-- ------------+----------------------------------------------------------------------------
--  Ivan       | {"trips": 3, "sports": ["футбол", "плавание"], "home_lib": true}
--  Petr       | {"trips": 2, "sports": ["теннис", "плавание"], "home_lib": true}
--  Pavel      | {"trips": 4, "sports": ["плавание"], "home_lib": false}
--  Boris      | {"trips": 0, "sports": ["футбол", "плавание", "теннис"], "home_lib": true}

UPDATE pilot_hobbies
	SET hobbies = hobbies - 'sports'
	WHERE pilot_name = 'Petr';
SELECT * FROM pilot_hobbies;
--  pilot_name |                                  hobbies                                   
-- ------------+----------------------------------------------------------------------------
--  Ivan       | {"trips": 3, "sports": ["футбол", "плавание"], "home_lib": true}
--  Pavel      | {"trips": 4, "sports": ["плавание"], "home_lib": false}
--  Boris      | {"trips": 0, "sports": ["футбол", "плавание", "теннис"], "home_lib": true}
--  Petr       | {"trips": 2, "home_lib": true}