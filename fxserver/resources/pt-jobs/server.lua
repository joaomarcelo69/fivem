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

local function buildJobsMap()
  local map = {}
  local list = PT_JOBS or {}
  
  if PT_UNEMPLOYED then
    map[PT_UNEMPLOYED.id] = { label = PT_UNEMPLOYED.label, salary = PT_UNEMPLOYED.baseSalary or 0 }
  end
  for _, j in ipairs(list) do
    map[j.id] = { label = j.label, salary = j.baseSalary or 0 }
  end
  return map
end

local JobsCache = buildJobsMap()

if QBCore and QBCore.Functions and QBCore.Functions.CreateCallback then
  QBCore.Functions.CreateCallback('pt-jobs:server:getJobs', function(source, cb)
    cb(JobsCache)
  end)
end

RegisterCommand('setjob', function(source, args)
  local src = source
  local target = tonumber(args[1])
  local job = args[2]
  local grade = tonumber(args[3]) or 0
  if not target or not job then
    TriggerClientEvent('pt-jobs:client:notify', src, 'Uso: /setjob <id> <job> [grau]')
    return
  end
  if not JobsCache[job] then
    TriggerClientEvent('pt-jobs:client:notify', src, 'Job inválido: '..tostring(job))
    return
  end
  if QBCore and QBCore.Functions and QBCore.Functions.GetPlayer then
    local Player = QBCore.Functions.GetPlayer(target)
    if not Player then
      TriggerClientEvent('pt-jobs:client:notify', src, 'Jogador não encontrado: '..tostring(target))
      return
    end
    Player.Functions.SetJob(job, grade)
    TriggerClientEvent('pt-jobs:client:notify', target, 'O teu emprego foi definido para '..JobsCache[job].label)
    TriggerClientEvent('pt-jobs:client:notify', src, 'Definiste o emprego do ID '..target..' para '..JobsCache[job].label)
  else
    
    TriggerClientEvent('pt-jobs:client:setJob', target, job)
    TriggerClientEvent('pt-jobs:client:notify', src, 'Definiste o emprego do ID '..target..' para '..JobsCache[job].label)
  end
end, true)
