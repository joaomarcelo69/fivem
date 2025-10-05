local QBCore
CreateThread(function()
  if not QBCore then
    if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
      QBCore = exports['qb-core']:GetCoreObject()
    elseif GetCoreObject then
      QBCore = GetCoreObject()
    end
  end
end)

local nuiOpen = false

RegisterCommand('housing', function()
  if nuiOpen then return end
  QBCore.Functions.TriggerCallback('pt-housing:list', function(props)
    local pdata = QBCore.Functions.GetPlayerData()
    local me = pdata and pdata.citizenid or ''
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', props = props, me = me })
    nuiOpen = true
  end)
end)

RegisterKeyMapping('housing', 'Abrir painel de Habitação', 'keyboard', 'F6')

RegisterNUICallback('ui:close', function(_, cb)
  SetNuiFocus(false, false)
  nuiOpen = false
  cb(true)
end)

RegisterNUICallback('listSale', function(data, cb)
  TriggerServerEvent('pt-housing:listForSale', data.id, tonumber(data.price))
  cb(true)
end)
RegisterNUICallback('listRent', function(data, cb)
  TriggerServerEvent('pt-housing:listForRent', data.id, tonumber(data.price))
  cb(true)
end)
RegisterNUICallback('unlist', function(data, cb)
  TriggerServerEvent('pt-housing:unlist', data.id)
  cb(true)
end)
RegisterNUICallback('buy', function(data, cb)
  TriggerServerEvent('pt-housing:buy', data.id)
  cb(true)
end)
RegisterNUICallback('rent', function(data, cb)
  TriggerServerEvent('pt-housing:rent', data.id)
  cb(true)
end)
RegisterNUICallback('renewRent', function(data, cb)
  TriggerServerEvent('pt-housing:renewRent', data.id)
  cb(true)
end)
RegisterNUICallback('withdraw', function(data, cb)
  TriggerServerEvent('pt-housing:withdrawIncome', data.id)
  cb(true)
end)
RegisterNUICallback('transfer', function(data, cb)
  TriggerServerEvent('pt-housing:transfer', data.id, data.target)
  cb(true)
end)
RegisterNUICallback('giveKeys', function(data, cb)
  TriggerServerEvent('pt-housing:giveKeys', data.id, data.target)
  cb(true)
end)
RegisterNUICallback('revokeKeys', function(data, cb)
  TriggerServerEvent('pt-housing:revokeKeys', data.id, data.target)
  cb(true)
end)
RegisterNUICallback('evict', function(data, cb)
  TriggerServerEvent('pt-housing:evictTenant', data.id, data.target)
  cb(true)
end)

RegisterCommand('housebuy', function(_, args)
  local id = args[1]
  if not id then return print('Uso: /housebuy <propertyId>') end
  TriggerServerEvent('pt-housing:buy', id)
end)

RegisterCommand('houselistsale', function(_, args)
  local id = args[1]; local price = tonumber(args[2] or '0')
  if not id or price <= 0 then return print('Uso: /houselistsale <propertyId> <preço>') end
  TriggerServerEvent('pt-housing:listForSale', id, price)
end)

RegisterCommand('houselistrent', function(_, args)
  local id = args[1]; local price = tonumber(args[2] or '0')
  if not id or price <= 0 then return print('Uso: /houselistrent <propertyId> <preçoPorPeriodo>') end
  TriggerServerEvent('pt-housing:listForRent', id, price)
end)

RegisterCommand('houseunlist', function(_, args)
  local id = args[1]
  if not id then return print('Uso: /houseunlist <propertyId>') end
  TriggerServerEvent('pt-housing:unlist', id)
end)

RegisterCommand('houserent', function(_, args)
  local id = args[1]
  if not id then return print('Uso: /houserent <propertyId>') end
  TriggerServerEvent('pt-housing:rent', id)
end)

RegisterCommand('houserenew', function(_, args)
  local id = args[1]
  if not id then return print('Uso: /houserenew <propertyId>') end
  TriggerServerEvent('pt-housing:renewRent', id)
end)

RegisterCommand('housetransfer', function(_, args)
  local id = args[1]; local targetCid = args[2]
  if not id or not targetCid then return print('Uso: /housetransfer <propertyId> <targetCitizenId>') end
  TriggerServerEvent('pt-housing:transfer', id, targetCid)
end)

RegisterCommand('housegivekeys', function(_, args)
  local id = args[1]; local targetCid = args[2]
  if not id or not targetCid then return print('Uso: /housegivekeys <propertyId> <targetCitizenId>') end
  TriggerServerEvent('pt-housing:giveKeys', id, targetCid)
end)

RegisterCommand('houserevokekeys', function(_, args)
  local id = args[1]; local targetCid = args[2]
  if not id or not targetCid then return print('Uso: /houserevokekeys <propertyId> <targetCitizenId>') end
  TriggerServerEvent('pt-housing:revokeKeys', id, targetCid)
end)

RegisterCommand('houseevict', function(_, args)
  local id = args[1]; local targetCid = args[2]
  if not id or not targetCid then return print('Uso: /houseevict <propertyId> <tenantCitizenId>') end
  TriggerServerEvent('pt-housing:evictTenant', id, targetCid)
end)

RegisterCommand('housewithdraw', function(_, args)
  local id = args[1]
  if not id then return print('Uso: /housewithdraw <propertyId>') end
  TriggerServerEvent('pt-housing:withdrawIncome', id)
end)
