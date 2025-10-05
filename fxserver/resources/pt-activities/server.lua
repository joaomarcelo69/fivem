local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('pt-activities:server:reward')
AddEventHandler('pt-activities:server:reward', function(kind)
  local src = source
  local P = QBCore.Functions.GetPlayer(src)
  if not P then return end
  local map = { taxi = 250, mec = 300 }
  local amt = map[kind] or 100
  P.Functions.AddMoney('bank', amt, 'activity-'..kind)
  TriggerClientEvent('QBCore:Notify', src, ('Recebeste %d€ (%s).'):format(amt, kind), 'success')
end)
