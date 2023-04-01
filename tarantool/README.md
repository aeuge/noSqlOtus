# Tarantool

- Высокопроизводительная NoSql база данных и приложение в одном фреймворке;
- Использует принципы хранимой процедуры и асинхронного ввода/вывода 
для достижение очень высокой производительности и масшатбируемости;
- Поддерживает схему свободной формы, т.е. не нужно определять структуру
таблицы до начала работы с базой данных;
- Подходит для работы с высоконагруженными приложениями, 
где производительность и масштабируемость имеют особое значение, например:
системы реального времени - приложения, требующие быстрокого отклика в режиме реального времени,
таких как системы онлайн-торговли и игровые приложения

## Домашнее задание
Необходимо написать на тарантуле биллинг реального времени облачной системы. Должны быть хранимые процедуры:

- добавление денег на баланс;
- списание денег.

Когда баланс становится равным нулю, тарантул по http должен сделать GET-запрос на какой-либо внешний урл, где передать userID пользователя, у которого кончились деньги (запрос на отключение виртуальных машин). Этот вызов должен происходить как можно быстрее после окончания денег на счете.
Для реализации рекомендуется использовать библиотеку expirationd.
Использовать шардинг на основе vshard.

## Решение

Cоздаем таблицы:
```lua
box.once('init', function()
    box.schema.space.create('users')
    box.space.users:create_index('pk', {parts = {1, 'unsigned'}})
    box.space.users:create_index('balance', {parts = {3, 'number'}})

    box.schema.space.create('transactions')
    box.space.transactions:create_index('pk', {parts = {1, 'unsigned'}})
end)
```

Хранимка для добавления денег на баланс:
```lua
function add_money(user_id, amount)
   local user = box.space.users:get(user_id)
   if not user then
      return {status = "ERROR", message = "Пользователь не найден"}
   end
   user.balance = user.balance + amount
   box.space.users:replace(user)
   local transaction = {
      user_id = user_id,
      type = "deposit",
      amount = amount,
      timestamp = os.time()
   }
   box.space.transactions:insert(transaction)
   return {status = "OK", message = "Ура! Денюжки на балансе :)"}
end
```
Хранимка для списания денег:
```lua
function withdraw_money(user_id, amount)
   local user = box.space.users:get(user_id)
   if not user then
      return {status = "ERROR", message = "Пользователь не найден"}
   end
   if user.balance < amount then
      return {status = "ERROR", message = "Недостаточно средств"}
   end
   user.balance = user.balance - amount
   box.space.users:replace(user)
   local transaction = {
      user_id = user_id,
      type = "withdraw",
      amount = amount,
      timestamp = os.time()
   }
   box.space.transactions:insert(transaction)
   return {status = "OK", message = "Прощайте денюжки :("}
end
```

Хранимка для обработки исчерпания баланса и отправки GET-запроса на внешний URL:

```lua
function check_balance(user_id)
   local user = box.space.users:get(user_id)
   if not user then
      return {status = "ERROR", message = "Пользователь не найден"}
   end
   if user.balance <= 0 then
      box.space.users:delete(user_id)
      local url = "http://external.url/user/" .. user_id
      http.request('GET', url)
   end
   return {status = "OK", message = "Баланс успешно проверен!"}
end
```

Настройка автоматического удаления пользователя с исчерпанным балансом:

```lua
local expirationd = require('expirationd')

expirationd.start('user_expirationd', {
   -- задаем интервал проверки (в секундах)
   check_interval = 60,
   -- устанавливаем правило для удаления записей
   eviction = {
      -- ищем записи с исчерпанным балансом
      mode = 'all',
      filter = function(key, tuple)
         return tuple.balance <= 0
      end,
      -- удаляем записи и отправляем GET-запрос на внешний URL
      get_placeholder = function()
         return 'user_id'
      end,
      format = function(user_id)
         return 'http://external.url/user/{user_id}'
      end,
      -- удаляем записи без задержки
      ttl = 0
   }
})
```