local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('pt-tolls:server:charge')
AddEventHandler('pt-tolls:server:charge', function(gantryId, plate)
  local src = source
  local P = QBCore.Functions.GetPlayer(src)
  if not P then return end
  local g = TollsConfig.gantries[gantryId]
  if not g then return end
  local price = g.price or 2
  -- isenção para serviço
  local j = P.PlayerData and P.PlayerData.job and P.PlayerData.job.name or ''
  if j == 'police' or j == 'psp' or j == 'gnr' or j == 'pj' or j == 'ambulance' or j == 'ems' or j == 'inem' or j == 'doctor' or j == 'fire' or j == 'bombeiros' or j == 'firefighter' then
    TriggerClientEvent('QBCore:Notify', src, 'Portagem isenta (viatura de serviço).', 'success')
    return
  end
  -- Via Verde desconto
  local discount = 1.0
  if P.Functions and P.Functions.GetItemByName and TollsConfig.viaverdeItem then
    local tag = P.Functions.GetItemByName(TollsConfig.viaverdeItem)
    if tag then discount = TollsConfig.viaverdeDiscount or 0.5 end
  end
  price = math.floor(price * discount)
  if not P.Functions.RemoveMoney('bank', price, 'portagem') then
    if not P.Functions.RemoveMoney('cash', price, 'portagem') then
      TriggerClientEvent('QBCore:Notify', src, ('Saldo insuficiente para portagem (%d€).'):format(price), 'error')
      return
    end
  end
  TriggerClientEvent('QBCore:Notify', src, ('Portagem: -%d€'):format(price), 'success')
  TriggerEvent('qb-phone:server:sendNewMail', {
    sender = 'Portagens',
    subject = 'Recibo de portagem',
    message = ('Foi cobrado %d€ ao passar na portagem. Matrícula: %s'):format(price, plate or 'N/D'),
    button = {}
  })
end)
