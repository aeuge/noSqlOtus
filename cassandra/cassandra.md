# Cassandra

Cassandra - это распределенная NoSQL база данных, которая разработана для храненеия и обработки больших объемов данных на нескольких серверах без единой точки отказа.
Она создана на основе модели столбцов (column-family), что позволяет сохранять данные в формате, удобном для их анализа и доступа.

Основные принципы Cassandra:
- Горизонтальное масштабирование: Cassandra позволяет добавлять новые серверы для увеличения производительности и хранения большого объема данных. 
- Высокая доступность: Cassandra имеет механизмы репликации и распределения данных, что обеспечивает непрерывную доступность данных в случае отказа одного или нескольких узлов.
- Низкая задержка: Cassandra разработана для обработки больших объемов данных с низкой задержкой при запросах.
- AP - в CAP теореме.

##Домашнее задание

- развернуть Kubernetes кластер в облаке или локально;
- поднять 3 узловый Cassandra кластер на Kubernetes;
- нагрузить кластер при помощи Cassandra Stress Tool.

### Развернуть Kubernetes кластер в облаке или локально

В качестве кластера использую docker-compose

### Поднять 3 узловый Cassandra кластер на Kubernetes

Пример реализации 3 node в файле docker-compose.yml

### Нагрузить кластер при помощи Cassandra Stress Tool

1. Создал keyspace `store` с фактором репликации `2`.
```sql
create keyspace store with replication = {'class' : 'SimpleStrategy', 'replication_factor' : 2}
```
2. Создал таблицу `products` для хранения категорий продуктов.
```sql
CREATE TABLE store.products {
    product_id int PRIMARY KEY,
    category_id int,
    product_name text,
    description text,
    price double
};
```
3. Создал yml с описанием таблицы products `products.yml`
4. Запустил стресс тест командой 
```sql
cassandra-stress user profile=products.yaml ops\(insert=1\) n=10000 -rate threads=50
```