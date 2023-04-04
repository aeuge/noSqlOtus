# Домашнее задание

1. построить шардированный кластер из 3 кластерных нод( по 3 инстанса с репликацией) и с кластером конфига(3 инстанса);
2. добавить балансировку, нагрузить данными, выбрать хороший ключ шардирования, посмотреть как данные перебалансируются между шардами;
3. поронять разные инстансы, посмотреть, что будет происходить, поднять обратно. Описать что произошло.
4. настроить аутентификацию и многоролевой доступ;

## Решение

1. Создал docker-compose файл с описанием кластера.
2. Создал конфигурационный файл config.js, запускаю:
```
docker-compose exec configsvr1 mongo < config.js
```
3. Создал конфиг файл для каждого шарда shard1.js и shard2.js, запускаю:
```
docker-compose exec shard1a mongo < shard1.js
docker-compose exec shard2a mongo < shard2.js
```
4. Добавляем шарды в маршрутизатор:
```
docker-compose exec router mongo --eval "sh.addShard('shard1/shard1a:27017,shard1b:27017,shard1c:27017')"
docker-compose exec router mongo --eval "sh.addShard('shard2/shard2a:27017,shard2b:27017,shard2c:27017')"
```
5. Добавим данные в кластер, для шардирования буду использовать поле `mykey`:
```
docker-compose exec router mongo --eval "sh.enableSharding('mydatabase')"
docker-compose exec router mongo --eval "db.createCollection('mycollection')"
docker-compose exec router mongo --eval "sh.shardCollection('mydatabase.mycollection', {mykey: 1})"
```
Накидаем данных в базу:
```kotlin
for (i in 0..100000) {
   db.mycollection.insert("{mykey: $i, myvalue: 'value' + $i}");
}
```
6. Проверяем запущена ли балансировка:
```
docker-compose exec router mongo --eval "sh.isBalancerRunning()"
```
Запускаем балансировку:
```
docker-compose exec router mongo --eval "sh.startBalancer()"
```
Смотрим статус балансировки:
```
docker-compose exec router mongo --eval "sh.status()"
```
7. Роняем инстансы:
```
Убиваю один инстанс - если запрос идет на текущий инстанс, получаю ошибку. Все остальное работает нормально
Убиваю инстанс конфигурации - MongoDB работает только на чтение. Нельзя добавить шарды и удалить шарды и изменять настройки конфигурации. Операции на шардах работают нормально.
Убиваю все сервера конфигурации, кластер MongoDB остановился и нельзя выполнить никакие операции.
Убиваю несколько серверов шардирования, то MongoDB будет продолжать работать на оставшихся серверах шардирования, но при этом ухудшается производительность из-за перегрузки оставшихся серверов.
```
8. Настроить аутентификацию и многоролевой доступ:
```
use admin
db.createUser({
  user: "admin",
  pwd: "password",
  roles: [
    { role: "userAdminAnyDatabase", db: "admin" },
    { role: "readWriteAnyDatabase", db: "admin" }
  ]
})
```
Создание пользователей и добавление им ролей:
```
use mydatabase
db.createUser({
  user: "user",
  pwd: "password",
  roles: [
    { role: "readWrite", db: "mydatabase" }
  ]
})
```