RegisterCommand('reviver', function(source, args)
  local target = tonumber(args[1])
  if target then
    TriggerClientEvent('pt-hospital:client:revive', target)
    TriggerClientEvent('pt-hospital:client:notify', source, 'Jogador revivido')
  end
end, false)
