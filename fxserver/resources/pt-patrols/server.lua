local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('pt-patrols:server:finish')
AddEventHandler('pt-patrols:server:finish', function(routeKey)
  local src = source
  local route = PatrolsConfig.routes[routeKey]
  if not route then return end
  local P = QBCore.Functions.GetPlayer(src)
  if not P then return end
  local reward = route.reward or 0
  if reward > 0 then P.Functions.AddMoney('bank', reward, 'patrol-reward') end
  TriggerClientEvent('QBCore:Notify', src, ('Recompensa: %d€'):format(reward), 'success')
  TriggerEvent('qb-phone:server:sendNewMail', {
    sender = 'Central',
    subject = 'Relatório de Ronda',
    message = ('Ronda "%s" concluída. Pontos percorridos: %d.'):format(route.label, #route.points),
    button = {}
  })
end)
