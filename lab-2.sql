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





