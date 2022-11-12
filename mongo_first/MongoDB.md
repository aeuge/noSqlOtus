# MongoDB

1. Документоориентированная БД.
2. Без схемы базы данных.
3. Документы хранятся в формате BSON (binary JSON).
4. Размер 1 документа – max 16 Мб.
5. В одном документе допускается до 100 уровней вложенностей.
6. Горизонтально масштабируется из коробки.
7. Регистрозависимость: 
`
{"age" : "28"} 
{“Age" : 28}
`
___
## Домашнее задание
> 1. установить MongoDB одним из способов: ВМ, докер;
> 2. заполнить данными;
> 3. написать несколько запросов на выборку и обновление данных;
> 4. создать индексы и сравнить производительность.
__
### Установить MongoDB одним из способов: ВМ, докер.

Установку выполнил в docker. Создал файл docker-compose,
image выбрал без версии и подтянул последний оффициальный образ.
1. подключаемся к докеру: docker exec -it mongo bash;
2. командой mongosh подключаемся к командной оболочке shell;
3. создаем юзера: ```db.createUser( { user: "vlad", pwd: "123", roles: [ "userAdminAnyDatabase", "dbAdminAnyDatabase", "readWriteAnyDatabase" ] } )```
4. авторизуемся командой db.auth("vlad", "123").
___
### Заполнить данными.
Создадим коллекции:
```
db.createCollection("service")
db.createCollection("mock")
```

Заполним информацию о сервисах:
```
db.service.insertMany([
{"name":"service1","uri":"localhost:8080","mockCount":0},
{"name":"service2","uri":"localhost:8090","mockCount":0},
{"name":"service3","uri":"localhost:80","mockCount":0}
])
```

Заполним информацию о моках:
```db.mock.insertMany([
{"httpMethod":"GET","response":{"code":200,"body":"Body1"},"path":"/path1","mockType":"JSON_HTTP","serviceName":"service1"},
{"httpMethod":"POST","response":{"code":200,"body":"Body2"},"path":"/path2","mockType":"SOAP_HTTP","serviceName":"service1"},
{"httpMethod":"PUT","response":{"code":200,"body":"Body3"},"path":"/path3","mockType":"JSON_HTTP","serviceName":"service1"},
{"httpMethod":"DELETE","response":{"code":200,"body":"Body4"},"path":"/path4","mockType":"SOAP_HTTP","serviceName":"service1"}
])
db.mock.insertMany([
{"httpMethod":"GET","response":{"code":200,"body":"Body1"},"path":"/path1","mockType":"JSON_HTTP","serviceName":"service2"},
{"httpMethod":"POST","response":{"code":200,"body":"Body2"},"path":"/path2","mockType":"SOAP_HTTP","serviceName":"service2"},
{"httpMethod":"GET","response":{"code":200,"body":"Body3"},"path":"/path1","mockType":"JSON_HTTP","serviceName":"service2"}
)]
db.mock.insertMany([
{"httpMethod":"POST","response":{"code":200,"body":"Body2"},"path":"/path2","mockType":"SOAP_HTTP","serviceName":"service3"},
{"httpMethod":"PUT","response":{"code":200,"body":"Body3"},"path":"/path3","mockType":"JSON_HTTP","serviceName":"service3"}
])
```
___
### Написать несколько запросов на выборку и обновление данных.

Получим все сервисы:
`db.service.find()`

Получим все моки:
`db.mock.find()`

запишем новое количество моков в сервисах:
```
db.service.updateOne({"name": "service1"}, {$set: { "mockCount": db.mock.countDocuments({ "serviceName" : "service1"} )}})
db.service.updateOne({"name": "service2"}, {$set: { "mockCount": db.mock.countDocuments({ "serviceName" : "service2"} )}})
db.service.updateOne({"name": "service3"}, {$set: { "mockCount": db.mock.countDocuments({ "serviceName" : "service3"} )}})
```

Получим сервис service1:
`db.service.find({"name": "service1"})`

Получим все моки с body = "Body3":
`db.mock.find({"serviceName"}, {"response.body" : "Body3"})`

удалим мок:
`db.mock.deleteOne({"serviceName": "service1", "httpMethod": "POST"})`

удалим все моки в сервисе:
`db.mock.deleteMany({"serviceName": "service2"})`

количество моков в каждом сервисе:
`db.mock.aggregate([{$group : {_id : "$serviceName", count_mock : {$sum : 1}}}])`
___
### Индексы.
> MongoDB использует B-tree структуру данных для хранения деревьев.

В нашем сервисе основной поиск чаще всего происходит по имени сервиса, поэтому добавим индекс:
```
db.mock.createIndex({ serviceName: 1 })
```
проанализируем запрос:
```
db.mock.explain().aggregate([{$group : {_id : "$serviceName", count_mock : {$sum : 1}}}])
```
