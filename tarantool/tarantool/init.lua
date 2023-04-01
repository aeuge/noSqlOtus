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
   return {status = "OK", message = "Ура! Денюжки на балансе ;)"}
end

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
         return 'http://external.url/user/' .. user_id
      end,
      -- удаляем записи без задержки
      ttl = 0
   }
})

box.once('init', function()
    box.schema.space.create('users')
    box.space.users:create_index('pk', {parts = {1, 'unsigned'}})
    box.space.users:create_index('balance', {parts = {3, 'number'}})

    box.schema.space.create('transactions')
    box.space.transactions:create_index('pk', {parts = {1, 'unsigned'}})
end)