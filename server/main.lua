local QBCore = exports['qb-core']:GetCoreObject()
local tier = nil
local isRunning = false
local ItemConfig = {}
--[[
   Structure = {
      [citizenid] = {
         status = false or true -- joining queue or not
         tier = 'A' or 'B' or 'C' or 'D'
         startContract = false or true -- start contract or not
         contract = {
            [1] = {
               owner = "Who ever the owner",
               car = "Car model",
               tier = "Tier",
               expire = "Expire time",
            }
         },
         xp = 0, -- xp
      }
   }
   ]] 

CreateThread(function ()
   while true do
      Wait(100)
      DeleteExpiredContract()
   end
end)
-- Event
RegisterNetEvent('jl-carboost:server:getBoostData', function()
   local src = source
   local Player = QBCore.Functions.GetPlayer(src)
   local result = MySQL.Sync.fetchAll('SELECT * FROM boost_data WHERE citizenid = @citizenid', {
      ['@citizenid'] = Player.PlayerData.citizenid
   })
   if result[1] then
      local res = result[1]
      local data = {
         status = false,
         tier = tostring(res.tier),
         startContract = false,
         contract = {},
         xp = res.xp,
      }
      Config.QueueList[Player.PlayerData.citizenid] = data
   else
      local data = {
         status = false,
         tier = 'D',
         startContract = false,
         contract = {},
         xp = 0
      }
      Config.QueueList[Player.PlayerData.citizenid] = data
      MySQL.Async.insert('INSERT INTO boost_data (citizenid, tier, xp) VALUES (@citizenid, @tier, @xp)', {
         ['@citizenid'] = Player.PlayerData.citizenid,
         ['@tier'] = data.tier,
         ['@xp'] = data.xp
      })
   end
   -- print(json.encode(Config.QueueList))

end)

RegisterNetEvent('jl-carboost:server:saveBoostData', function (citizenid)
   MySQL.Async.execute('UPDATE boost_data SET data = @data WHERE citizenid = @citizenid', {
      ['@citizenid'] = citizenid,
      ['@data'] = json.encode(Config.QueueList[citizenid])
   })
end)

RegisterNetEvent('jl-carboost:server:newContract', function (citizenid)
   local src = source
   local config = Config.QueueList[citizenid]
   local tier = config.tier
   local Player = QBCore.Functions.GetPlayer(src)
   local car = Config.Tier[tier].car[math.random(#Config.Tier[tier].car)]
   local owner = Config.RandomName[math.random(1, #Config.RandomName)]
   local contractData = {
      owner = owner,
      car = car,
      tier = tier,
   }
   if #Config.QueueList[citizenid].contract <= Config.MaxContract then     
      MySQL.Async.insert('INSERT INTO boost_contract (owner, data, started, expire) VALUES (@owner, @data, NOW(),DATE_ADD(NOW(), INTERVAL ? HOUR))', {
         ['@owner'] = citizenid,
         ['@data'] = json.encode(contractData)
      })
      Config.QueueList[citizenid].contract[#Config.QueueList[citizenid].contract+1] = contractData
   end

end)

-- I think I don't need this for now

-- RegisterNetEvent('jl-carboost:server:setupQueueData', function ()
--    local src = source
--    local Player = QBCore.Functions.GetPlayer(src)
--    local citizenid = Player.PlayerData.citizenid
--    local data = {
--       status = false,
--       tier = "D",
--       startContract = false,
--       contract = {}
--    }
-- end)
RegisterNetEvent('jl-carboost:server:sendTask', function (source, data)

end)

RegisterNetEvent('jl-carboost:server:joinQueue', function (status, citizenid)

end)

RegisterNetEvent('jl-carboost:server:takeItem', function (name, quantity)
   local src = source
   local Player = QBCore.Functions.GetPlayer(src)
   Player.Functions.AddItem(name, quantity)
   TriggerClientEvent('inventory:client:itemBox', src, QBCore.Shared.Items[tostring(name)], 'add')
end)

RegisterNetEvent('jl-carboost:server:getItem', function ()
   local src = source
   local pData = QBCore.Functions.GetPlayer(src)
   local result = MySQL.Sync.fetchScalar('SELECT items FROM bennys_shop WHERE citizenid = @citizenid', {
      ['@citizenid'] = pData.PlayerData.citizenid
   })
   if result then
      TriggerClientEvent('jl-carboost:client:setConfig', src, json.decode(result))
   end
end)

RegisterNetEvent('jl-carboost:server:setConfig', function ()
   TriggerClientEvent('jl-carboost:client:setConfig', -1, Config.BennysItems)
end)

RegisterNetEvent('jl-carboost:server:giveContract', function ()
   local src = source
   local pData = QBCore.Functions.GetPlayer(src)
   local config = Config.QueueList[pData.PlayerData.citizenid]
   if config and #config.contract <= Config.MaxContract then
      TriggerEvent('jl-carboost:server:newContract', src,pData.PlayerData.citizenid)
   end
end)


RegisterNetEvent('jl-carboost:server:buyItem', function (price, config, first)
   local src = source 
   local pData = QBCore.Functions.GetPlayer(src)
   pData.Functions.RemoveMoney('bank', price, 'bought-bennys-item')
      MySQL.Async.insert('INSERT INTO bennys_shop (citizenid, items) VALUES (@citizenid, @items) ON DUPLICATE KEY UPDATE items = @items', {
         ['@citizenid'] = pData.PlayerData.citizenid,
         ['@items'] = json.encode(config)
      })
end)

RegisterNetEvent('jl-carboost:server:finishBoosting', function ()
   local src = source
   local pData = QBCore.Functions.GetPlayer(src)
   pData.Functions.AddMoney('bank', math.random(500, 2000), 'finished-boosting')
end)

RegisterNetEvent('jl-carboost:server:updateBennysConfig', function (data)
   local src = source 
   local pData = QBCore.Functions.GetPlayer(src)
   MySQL.Async.execute('UPDATE bennys_shop SET items = @items WHERE citizenid = @citizenid', {
      ['@citizenid'] = pData.PlayerData.citizenid,
      ['@items'] = json.encode(data)
   })
end)

RegisterNetEvent('jl-carboost:server:takeAll', function (data)
   local src = source
   local Player = QBCore.Functions.GetPlayer(src)
   for k, v in pairs(data) do
      local item = v.item
      Player.Functions.AddItem(item.name, item.quantity)
      TriggerClientEvent('inventory:client:itemBox', src, QBCore.Shared.Items[tostring(item.name)], 'add')
   end
   MySQL.Async.execute('UPDATE bennys_shop SET items = @items WHERE citizenid = @citizenid', {
      ['@citizenid'] = Player.PlayerData.citizenid,
      ['@items'] = json.encode({})
   })
   TriggerClientEvent('QBCore:Notify', src, "Succesfully bought all items", "success")
end)

-- Callback
QBCore.Functions.CreateCallback('jl-carboost:server:canBuy', function(source, cb, data)
   local src = source
   local pData = QBCore.Functions.GetPlayer(src)
   local bankAccount = pData.PlayerData.money["bank"]
   if bankAccount >= data then
      cb(true)
   else
      cb(false)
   end
   return cb
end)

QBCore.Functions.CreateCallback('jl-carboost:server:canTake', function (source, cb, data)

end)

QBCore.Functions.CreateCallback('jl-carboost:server:getboostdata', function (source, cb, citizenid)
   local config = Config.QueueList[citizenid] 
   if config then
      if #config.contract == 0 then
         local result = MySQL.Sync.fetchAll('SELECT * FROM boost_contract WHERE owner = @owner', {
            ['@owner'] = citizenid
         })
         if result[1] then
            print(json.encode(result))
            for k, v in pairs(result) do
               local data = {
                  owner = v.owner,
                  data = json.decode(v.data) 
               }
               Config.QueueList[citizenid].contract[#Config.QueueList[citizenid].contract+1] = data
            end
            cb(Config.QueueList[citizenid])
            print(json.encode(Config.QueueList))
         end
      end
   else
      cb(false)
   end
end)

QBCore.Functions.CreateCallback('jl-carboost:server:spawnCar', function (source, cb, data)
   print(json.encode(data))
   local boosttier = Config.Tier[data.type]
   local coords = boosttier.location[math.random(1, #boosttier.location)]
   -- local cars = boosttier.car[math.random(#boosttier.car)]
   local carhash = GetHashKey(data.car)
   local CreateAutomobile = GetHashKey('CREATE_AUTOMOBILE')
   local car = Citizen.InvokeNative(CreateAutomobile, carhash, coords, coords.w, true, false)
   SetVehicleDoorsLocked(car, 2)
   local data
   while not DoesEntityExist(car) do
      Wait(25)
   end
   if DoesEntityExist(car) then
      local netId = NetworkGetNetworkIdFromEntity(car)
      print(netId)
      data = {
         networkID = netId,
         coords = coords
      }
      isRunning = true
      cb(data)
   else
      data = {
         networkID = 0,
      }
      cb(data)
   end
end)

function DeleteExpiredContract()
   MySQL.Async.execute('DELETE FROM boost_contract WHERE expire < NOW()',{}, function (result)
      if result > 0 then
         print('Contracts deleted')
      end
   end)
end

QBCore.Functions.CreateUseableItem('laptop' , function(source, item)
   TriggerClientEvent('jl-carboost:client:openLaptop', source)
end)