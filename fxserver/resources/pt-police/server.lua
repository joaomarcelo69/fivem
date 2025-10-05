local function safeGetQBCore()
  if exports and exports['qb-core'] and type(exports['qb-core'].GetCoreObject) == 'function' then
    return exports['qb-core']:GetCoreObject()
  elseif type(GetCoreObject) == 'function' then
    return GetCoreObject()
  elseif Global and Global.GetCoreObject then
    return Global.GetCoreObject()
  elseif _G and _G.GetCoreObject then
    return _G.GetCoreObject()
  end
  return {}
end

local QBCore = safeGetQBCore()

RegisterCommand('multar', function(source, args)
  local target = tonumber(args[1])
  local amount = tonumber(args[2])
  if target and amount then
    if QBCore and QBCore.Functions and QBCore.Functions.GetPlayer then
      local Player = QBCore.Functions.GetPlayer(target)
      if Player then
        Player.Functions.RemoveMoney('bank', amount, 'multa-pt')
      end
    end
    TriggerClientEvent('pt-police:client:notify', target, 'Foi multado: '..amount..'€')
    TriggerClientEvent('pt-police:client:notify', source, 'Multa aplicada: '..amount..'€')
  end
end, false)
