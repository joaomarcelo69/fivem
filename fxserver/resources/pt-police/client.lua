RegisterCommand('policia', function()
  print('Sistema da PSP mínimo ativo')
end)

RegisterNetEvent('pt-police:client:notify')
AddEventHandler('pt-police:client:notify', function(msg)
  print(msg)
end)
