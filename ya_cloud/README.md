# Домашнее задание

1. одну из облачных БД заполнить данными (любыми из предыдущих дз);
2. протестировать скорость запросов.

В качестве базы данных выбрал clickhouse.

Начал пробовать создавать кластер в yandex cloud, но запоролся почти в самом начале - при создании конфига yc config list.
Грешу на то, что ноутбук рабочий и есть некоторые ограничения внутри. Решил пойти другим путем и использовать тестовое окружение для поднятия кластера.
С помощью Ansible поднял готовый кластер по шаблону. 

Заполнил данным таблицу:
```sql
INSERT INTO test_stg.uk_price_paid
WITH splitByChar(' ', postcode) AS p
SELECT toUInt32(price_string) AS price,
       parseDateTimeBestEffortUS(time) AS date,
    p[1] AS postcode1,
    p[2] AS postcode2,
    transform(a, ['T', 'S', 'D', 'F', 'O'], ['terraced', 'semi-detached', 'detached', 'flat', 'other']) AS type,
    b = 'Y' AS is_new,
    transform(c, ['F', 'L', 'U'], ['freehold', 'leasehold', 'unknown']) AS duration,
    addr1,
    addr2,
    street,
    locality,
    town,
    district,
    county
FROM url(
    'http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com/pp-complete.csv',
    'CSV',
    'uuid_string String,
    price_string String,
    time String,
    postcode String,
    a String,
    b String,
    c String,
    addr1 String,
    addr2 String,
    street String,
    locality String,
    town String,
    district String,
    county String,
    d String,
    e String'
    ) SETTINGS max_http_get_redirects=10;

SELECT toYear(date) AS year,
   round(avg(price)) AS price,
   bar(price, 0, 1000000, 80
   )
FROM uk_price_paid
GROUP BY year
ORDER BY year;
```

Поделал обычные запросы, в целом разница в ответах не сильно большая в сравнении с локальным запуском в докере,
так как в ответ мне приходят сгруппированные данные, нагрузка на сеть минимальная:

1. Запрос на подсчет всех данных выполнился за 142мс;

```
SELECT count()
FROM uk_price_paid;
```

2. Средняя цена с построением графика - 271ms

```
SELECT toYear(date) AS year,
      round(avg(price)) AS price, bar(price, 0, 1000000, 80)
FROM uk_price_paid
GROUP BY year
ORDER BY year
```

3. Самые дорогие районы - 183ms

```
SELECT
    town,
    district,
    count() AS c,
    round(avg(price)) AS price,
    bar(price, 0, 5000000, 100)
FROM uk_price_paid
WHERE date >= '2020-01-01'
GROUP BY
    town,
    district
HAVING c >= 100
ORDER BY price DESC
LIMIT 100
```

