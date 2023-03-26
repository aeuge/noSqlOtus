# Neo4j

## Домашнее задание

Воспользоваться моделью, данными и командами из лекции и реализовать аналог в любой выбранной БД (реляционной или нет -
на выбор). Сравнить команды. Написать, что удобнее было сделать в выбранной БД, а что в Neo4j и привести примеры.

1. Игрушечный пример:
   • Фильмы (название, год выпуска, жанр)
   • Актеры (имя, фамилия, год рождения)
   • Связь между фильмами и актерами (актеры, участвующие в фильме)
2. В Neo4j создал узлы для каждой сущности и связи между ними:

```neo4j
// Создание узлов для фильмов
CREATE (:Film { title: 'The Godfather', year: 1972, genre: 'crime' })
CREATE (:Film { title: 'The Shawshank Redemption', year: 1994, genre: 'drama' })
CREATE (:Film { title: 'The Dark Knight', year: 2008, genre: 'action' })

// Создание узлов для актеров
CREATE (:Actor { name: 'Marlon', surname: 'Brando', birthYear: 1924 })
CREATE (:Actor { name: 'Al', surname: 'Pacino', birthYear: 1940 })
CREATE (:Actor { name: 'Morgan', surname: 'Freeman', birthYear: 1937 })

// Создание связей между фильмами и актерами
MATCH (f:Film { title: 'The Godfather' }), (a:Actor { surname: 'Brando' })
CREATE (a)-[:ACTS_IN]->(f)

MATCH (f:Film { title: 'The Godfather' }), (a:Actor { surname: 'Pacino' })
CREATE (a)-[:ACTS_IN]->(f)

MATCH (f:Film { title: 'The Shawshank Redemption' }), (a:Actor { surname: 'Freeman' })
CREATE (a)-[:ACTS_IN]->(f)

MATCH (f:Film { title: 'The Dark Knight' }), (a:Actor { surname: 'Freeman' })
CREATE (a)-[:ACTS_IN]->(f)
```

3. SQL пример:

```sql
// Создание таблицы для фильмов
CREATE TABLE films
(
    id    INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    year  INT          NOT NULL,
    genre VARCHAR(255) NOT NULL
);

// Создание таблицы для актеров
CREATE TABLE actors
(
    id        INT AUTO_INCREMENT PRIMARY KEY,
    name      VARCHAR(255) NOT NULL,
    surname   VARCHAR(255) NOT NULL,
    birthYear INT          NOT NULL
);

// Создание таблицы для связи между фильмами и актерами
CREATE TABLE film_actors
(
    id       INT AUTO_INCREMENT PRIMARY KEY,
    film_id  INT NOT NULL,
    actor_id INT NOT NULL,
    FOREIGN KEY (film_id) REFERENCES films (id),
    FOREIGN KEY (actor_id) REFERENCES actors (id)
);
// Вставка данных в таблицы
INSERT INTO films (title, year, genre) VALUES
('The Godfather', 1972, 'crime'),
('The Shawshank Redemption', 1994, 'drama'),
('The Dark Knight', 2008, 'action');
INSERT INTO actors (name, surname, birthYear)
VALUES ('Marlon', 'Brando', 1924),
       ('Al', 'Pacino', 1940),
       ('Morgan', 'Freeman', 1937);
// Вставка данных в таблицу связей
INSERT INTO film_actors (film_id, actor_id) VALUES
(1, 1),
(1, 2),
(2, 3),
(3, 3);
```

Создаю таблицы для фильмов, актеров и связей между ними. Затем заполняем таблицы

Сравнивая два подхода, можно заметить, что в Neo4j более удобно работать с связями между сущностями, так как мы можем явно указать их с помощью оператора CREATE. 
В MySQL мы должны создать отдельную таблицу для связей и добавлять данные в нее отдельно. Однако, в MySQL удобнее работать со множеством данных, так как мы можем использовать SQL-запросы для фильтрации, сортировки и агрегации данных.

Примеры:

1. Чтобы найти всех актеров, участвующих в фильме "The Godfather", в Neo4j использую следующий запрос:
```sql
MATCH (f:Film { title: 'The Godfather' })<-[:ACTS_IN]-(a:Actor)
RETURN a.name, a.surname
```
Здесь ищу узлы фильма "The Godfather" и нахожу все связанные с ним узлы актеров, которые участвуют в этом фильме.

В MySQL использую следующий запрос:
```sql
SELECT actors.name, actors.surname
FROM films
JOIN film_actors ON films.id = film_actors.film_id
JOIN actors ON film_actors.actor_id = actors.id
WHERE films.title = 'The Godfather';
```
Здесь объединяю таблицы фильмов, связей и актеров с помощью оператора JOIN и выбираю имена и фамилии актеров, участвующих в фильме "The Godfather".

2. Чтобы найти все фильмы, в которых участвовал актер "Morgan Freeman", в Neo4j:
```sql
MATCH (a:Actor { surname: 'Freeman' })-[:ACTS_IN]->(f:Film)
RETURN f.title, f.year, f.genre
```
Ищу узел актера "Morgan Freeman" и нахожу все связанные с ним узлы фильмов, в которых он участвовал.
В MySQL использую следующий запрос:
```sql
SELECT films.title, films.year, films.genre
FROM actors
JOIN film_actors ON actors.id = film_actors.actor_id
JOIN films ON film_actors.film_id = films.id
WHERE actors.surname = 'Freeman';
```
Объединяю таблицы актеров, связей и фильмов с помощью оператора JOIN и выбираю название, год и жанр фильмов, в которых участвовал актер "Morgan Freeman".
