-- Лабораторная работа 7



-- Создание БД (из Dev1_07)


DROP TABLE IF EXISTS authors CASCADE;
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS authorship CASCADE;
DROP TABLE IF EXISTS operations CASCADE;

CREATE TABLE authors(
    author_id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    last_name text NOT NULL,
    first_name text NOT NULL,
    middle_name text
);

CREATE TABLE books(
    book_id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    title text NOT NULL
);

CREATE TABLE authorship(
    book_id integer REFERENCES books,
    author_id integer REFERENCES authors,
    seq_num integer NOT NULL,
    PRIMARY KEY (book_id,author_id)
);

CREATE TABLE operations(
    operation_id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    book_id integer NOT NULL REFERENCES books,
    qty_change integer NOT NULL,
    date_created date NOT NULL DEFAULT current_date
);

INSERT INTO authors(last_name, first_name, middle_name)
VALUES 
    ('Пушкин', 'Александр', 'Сергеевич'),
    ('Тургенев', 'Иван', 'Сергеевич'),
    ('Стругацкий', 'Борис', 'Натанович'),
    ('Стругацкий', 'Аркадий', 'Натанович'),
    ('Толстой', 'Лев', 'Николаевич'),
    ('Свифт', 'Джонатан', NULL);

INSERT INTO books(title)
VALUES
    ('Сказка о царе Салтане'),
    ('Муму'),
    ('Трудно быть богом'),
    ('Война и мир'),
    ('Путешествия в некоторые удаленные страны мира в четырех частях: сочинение Лемюэля Гулливера, сначала хирурга, а затем капитана нескольких кораблей'),
    ('Хрестоматия'),
	('Книга без авторов');

INSERT INTO authorship(book_id, author_id, seq_num) 
VALUES
    (1, 1, 1),
    (2, 2, 1),
    (3, 3, 2),
    (3, 4, 1),
    (4, 5, 1),
    (5, 6, 1),
    (6, 1, 1),
    (6, 5, 2),
    (6, 2, 3);

INSERT INTO operations(book_id, qty_change)
VALUES
    (1, 10),
    (1, 10),
    (1, -1);

DROP VIEW IF EXISTS authors_v CASCADE;
CREATE VIEW authors_v AS
SELECT a.author_id,
       a.last_name || ' ' ||
       a.first_name ||
       coalesce(' ' || nullif(a.middle_name, ''), '') AS display_name
FROM   authors a;

DROP VIEW IF EXISTS catalog_v CASCADE;
CREATE VIEW catalog_v AS
SELECT b.book_id,
       b.title AS display_name
FROM   books b;

DROP VIEW IF EXISTS operations_v CASCADE;
CREATE VIEW operations_v AS
SELECT book_id,
       CASE
           WHEN qty_change > 0 THEN 'Поступление'
           ELSE 'Покупка'
       END op_type, 
       abs(qty_change) qty_change, 
       to_char(date_created, 'DD.MM.YYYY') date_created
FROM   operations
ORDER BY operation_id;



-- Dev1_08


-- Задание 1

DROP FUNCTION IF EXISTS author_name CASCADE;
CREATE FUNCTION author_name(IN last_name text, IN first_name text, IN middle_name text DEFAULT NULL)
RETURNS text
LANGUAGE sql
RETURN last_name || ' ' ||
       first_name ||
       coalesce(' ' || nullif(middle_name, ''), '');

DROP VIEW IF EXISTS authors_v CASCADE;
CREATE VIEW authors_v AS
SELECT author_name(a.last_name, a.first_name, a.middle_name) AS display_name
FROM   authors a;

SELECT * FROM authors_v;
--          display_name         
-- ------------------------------
--  Пушкин Александр Сергеевич
--  Тургенев Иван Сергеевич
--  Стругацкий Борис Натанович
--  Стругацкий Аркадий Натанович
--  Толстой Лев Николаевич
--  Свифт Джонатан


-- Задание 2

DROP FUNCTION IF EXISTS book_name CASCADE;
CREATE FUNCTION book_name(IN id integer, IN title text)
RETURNS text
LANGUAGE sql
RETURN (
	SELECT
		title || coalesce(' (' || string_agg(author_name(authors.last_name, authors.first_name, authors.middle_name), ', ') || ')', '')
	FROM authorship
	JOIN authors ON authorship.author_id = authors.author_id
	WHERE authorship.book_id = id
);

DROP VIEW IF EXISTS catalog_v CASCADE;
CREATE VIEW catalog_v AS
SELECT b.book_id,
       book_name(b.book_id, b.title) AS display_name
FROM   books b;

SELECT * FROM catalog_v;
--  book_id |                                                                            display_name                                                                             
-- ---------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------
--        1 | Сказка о царе Салтане (Пушкин Александр Сергеевич)
--        2 | Муму (Тургенев Иван Сергеевич)
--        3 | Трудно быть богом (Стругацкий Борис Натанович, Стругацкий Аркадий Натанович)
--        4 | Война и мир (Толстой Лев Николаевич)
--        5 | Путешествия в некоторые удаленные страны мира в четырех частях: сочинение Лемюэля Гулливера, сначала хирурга, а затем капитана нескольких кораблей (Свифт Джонатан)
--        6 | Хрестоматия (Пушкин Александр Сергеевич, Тургенев Иван Сергеевич, Толстой Лев Николаевич)
--        7 | Книга без авторов



-- Dev1_09


-- Задание 1

INSERT INTO authors (last_name, first_name, middle_name) VALUES
	('Пушкин', 'Александр', 'Сергеевич'),
	('Пушкин', 'Александр', 'Сергеевич'),
	('Свифт', 'Джонатан', NULL);


DROP PROCEDURE IF EXISTS delete_duplicated_authors;
CREATE PROCEDURE delete_duplicated_authors()
LANGUAGE sql
BEGIN ATOMIC
	WITH a_dups AS (
		SELECT
			author_id,
			row_number() OVER (
				PARTITION BY last_name, first_name, middle_name
				ORDER BY author_id
			) AS row_num
		FROM authors
	)
	DELETE FROM authors a USING a_dups
	WHERE a.author_id = a_dups.author_id AND a_dups.row_num > 1;
END;

CALL delete_duplicated_authors();

SELECT * FROM authors;
--  author_id | last_name  | first_name | middle_name 
-- -----------+------------+------------+-------------
--          1 | Пушкин     | Александр  | Сергеевич
--          2 | Тургенев   | Иван       | Сергеевич
--          3 | Стругацкий | Борис      | Натанович
--          4 | Стругацкий | Аркадий    | Натанович
--          5 | Толстой    | Лев        | Николаевич
--          6 | Свифт      | Джонатан   | 


-- Задание 2

ALTER TABLE authors
ADD UNIQUE NULLS NOT DISTINCT (last_name, first_name, middle_name); 

-- INSERT INTO authors (last_name, first_name, middle_name) VALUES
-- 	('Тургенев', 'Иван', 'Сергеевич'); -- ошибка

-- INSERT INTO authors (last_name, first_name, middle_name) VALUES
-- 	('Свифт', 'Джонатан', NULL); -- ошибка



-- Dev1_17


-- Задание 1

DROP FUNCTION IF EXISTS onhand_qty;
CREATE FUNCTION onhand_qty(book books) RETURNS integer
STABLE LANGUAGE sql
BEGIN ATOMIC
    SELECT coalesce(sum(o.qty_change),0)::integer
    FROM operations o
    WHERE o.book_id = book.book_id;
END;

DROP VIEW IF EXISTS catalog_v;
CREATE VIEW catalog_v AS
SELECT b.book_id,
       book_name(b.book_id, b.title) AS display_name,
       b.onhand_qty
FROM   books b
ORDER BY display_name;


DROP FUNCTION IF EXISTS update_catalog_v CASCADE;
CREATE FUNCTION update_catalog_v() RETURNS trigger
AS $$
BEGIN
	INSERT INTO operations (book_id, qty_change)
		VALUES (OLD.book_id, NEW.onhand_qty - OLD.onhand_qty);
	RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER catalog_v_upd_trigger
INSTEAD OF UPDATE ON catalog_v
FOR EACH ROW EXECUTE FUNCTION update_catalog_v();

UPDATE catalog_v SET onhand_qty = 10;
UPDATE catalog_v SET onhand_qty = 5 WHERE display_name ~ 'Пушкин';

SELECT * FROM catalog_v;
--  book_id |                                                                            display_name                                                                             | onhand_qty 
-- ---------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------+------------
--        4 | Война и мир (Толстой Лев Николаевич)                                                                                                                                |         10
--        7 | Книга без авторов                                                                                                                                                   |         10
--        2 | Муму (Тургенев Иван Сергеевич)                                                                                                                                      |         10
--        5 | Путешествия в некоторые удаленные страны мира в четырех частях: сочинение Лемюэля Гулливера, сначала хирурга, а затем капитана нескольких кораблей (Свифт Джонатан) |         10
--        1 | Сказка о царе Салтане (Пушкин Александр Сергеевич)                                                                                                                  |          5
--        3 | Трудно быть богом (Стругацкий Борис Натанович, Стругацкий Аркадий Натанович)                                                                                        |         10
--        6 | Хрестоматия (Пушкин Александр Сергеевич, Тургенев Иван Сергеевич, Толстой Лев Николаевич)                                                                           |          5

SELECT * FROM operations_v;
--  book_id |   op_type   | qty_change | date_created 
-- ---------+-------------+------------+--------------
--        1 | Поступление |         10 | 19.12.2024
--        1 | Поступление |         10 | 19.12.2024
--        1 | Покупка     |          1 | 19.12.2024
--        4 | Поступление |         10 | 19.12.2024
--        7 | Поступление |         10 | 19.12.2024
--        2 | Поступление |         10 | 19.12.2024
--        5 | Поступление |         10 | 19.12.2024
--        1 | Покупка     |          9 | 19.12.2024
--        3 | Поступление |         10 | 19.12.2024
--        6 | Поступление |         10 | 19.12.2024
--        1 | Покупка     |          5 | 19.12.2024
--        6 | Покупка     |          5 | 19.12.2024


-- Задание 2

BEGIN;

DROP VIEW IF EXISTS catalog_v;
LOCK TABLE books IN EXCLUSIVE MODE;
LOCK TABLE operations IN EXCLUSIVE MODE;

ALTER TABLE books
	ADD COLUMN onhand_qty integer;
UPDATE books SET onhand_qty = onhand_qty(books);

DROP FUNCTION IF EXISTS onhand_qty;

ALTER TABLE books
    ADD CHECK (onhand_qty >= 0);
ALTER TABLE books
	ALTER COLUMN onhand_qty SET NOT NULL;
ALTER TABLE books
	ALTER COLUMN onhand_qty SET DEFAULT 0;

CREATE VIEW catalog_v AS
SELECT b.book_id,
       book_name(b.book_id, b.title) AS display_name,
       b.onhand_qty
FROM   books b
ORDER BY display_name;


DROP FUNCTION IF EXISTS update_onhand_qty CASCADE;
CREATE FUNCTION update_onhand_qty() RETURNS trigger
AS $$
BEGIN
	UPDATE books
	SET onhand_qty = onhand_qty + NEW.qty_change
	WHERE book_id = NEW.book_id;
	RETURN NULL;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_onhand_qty_trigger
AFTER INSERT ON operations
FOR EACH ROW
EXECUTE FUNCTION update_onhand_qty();


COMMIT;

SELECT * FROM books;
--  book_id |                                                                       title                                                                        | onhand_qty 
-- ---------+----------------------------------------------------------------------------------------------------------------------------------------------------+------------
--        1 | Сказка о царе Салтане                                                                                                                              |          5
--        2 | Муму                                                                                                                                               |         10
--        3 | Трудно быть богом                                                                                                                                  |         10
--        4 | Война и мир                                                                                                                                        |         10
--        5 | Путешествия в некоторые удаленные страны мира в четырех частях: сочинение Лемюэля Гулливера, сначала хирурга, а затем капитана нескольких кораблей |         10
--        6 | Хрестоматия                                                                                                                                        |          5
--        7 | Книга без авторов                                                                                                                                  |         10

INSERT INTO operations (book_id, qty_change) VALUES
	(4, -8),
	(5, 7);

--INSERT INTO operations (book_id, qty_change) VALUES (1, -100);
--ERROR:  Failing row contains (1, Сказка о царе Салтане, -95).new row for relation "books" violates check constraint "books_onhand_qty_check" 
--
--ERROR:  new row for relation "books" violates check constraint "books_onhand_qty_check"

SELECT * FROM books;
--  book_id |                                                                       title                                                                        | onhand_qty 
-- ---------+----------------------------------------------------------------------------------------------------------------------------------------------------+------------
--        1 | Сказка о царе Салтане                                                                                                                              |          5
--        2 | Муму                                                                                                                                               |         10
--        3 | Трудно быть богом                                                                                                                                  |         10
--        6 | Хрестоматия                                                                                                                                        |          5
--        7 | Книга без авторов                                                                                                                                  |         10
--        4 | Война и мир                                                                                                                                        |          2
--        5 | Путешествия в некоторые удаленные страны мира в четырех частях: сочинение Лемюэля Гулливера, сначала хирурга, а затем капитана нескольких кораблей |         17
