RegisterCommand('hospital', function()
  print('Serviços do SNS ativos')
end)

RegisterNetEvent('pt-hospital:client:revive')
AddEventHandler('pt-hospital:client:revive', function()
  print('Você foi revivido (teste)')
end)

RegisterNetEvent('pt-hospital:client:notify')
AddEventHandler('pt-hospital:client:notify', function(msg)
  print(msg)
end)
