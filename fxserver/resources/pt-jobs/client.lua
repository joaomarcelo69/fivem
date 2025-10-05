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

RegisterCommand('jobs', function()
  if QBCore and QBCore.Functions and QBCore.Functions.TriggerCallback then
    QBCore.Functions.TriggerCallback('pt-jobs:server:getJobs', function(jobs)
      local msg = 'Empregos disponíveis:\n'
      for k,v in pairs(jobs) do
        msg = msg..string.format('- %s (%s) | Salário base: %d€\n', v.label, k, v.salary)
      end
      print(msg)
    end)
  else
    print('QBCore não disponível para listar jobs')
  end
end)

RegisterNetEvent('pt-jobs:client:setJob')
AddEventHandler('pt-jobs:client:setJob', function(job)
  print('Job definido: '..job)
end)

RegisterNetEvent('pt-jobs:client:notify')
AddEventHandler('pt-jobs:client:notify', function(msg)
  print(msg)
end)
