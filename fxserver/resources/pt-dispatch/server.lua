local function getQB()
  if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
    return exports['qb-core']:GetCoreObject()
  elseif GetCoreObject then
    return GetCoreObject()
  end
end

local QBCore = getQB()

local calls = {}
local nextId = 1

local function getPlayersWithJob(job)
  local result = {}
  for _, src in pairs(QBCore.Functions.GetPlayers()) do
    local P = QBCore.Functions.GetPlayer(src)
    if P and P.PlayerData and P.PlayerData.job and P.PlayerData.job.name then
      local j = P.PlayerData.job.name
      if (job == 'police' and (j == 'police' or j == 'psp' or j == 'gnr' or j == 'pj'))
        or (job == 'ems' and (j == 'ambulance' or j == 'ems' or j == 'inem' or j == 'doctor'))
        or (job == 'fire' and (j == 'fire' or j == 'bombeiros' or j == 'firefighter'))
        or j == job then
        table.insert(result, src)
      end
    end
  end
  return result
end

RegisterNetEvent('pt-dispatch:server:newCall')
AddEventHandler('pt-dispatch:server:newCall', function(job, text, coords)
  local src = source
  job = tostring(job)
  if not DispatchConfig.jobs[job] then return end
  local id = nextId
  nextId = nextId + 1
  calls[id] = { job = job, text = tostring(text or ''), coords = coords, caller = src, acceptedBy = nil }
  
  local recipients = getPlayersWithJob(job)
  for _, rsrc in ipairs(recipients) do
    TriggerClientEvent('pt-dispatch:client:incomingCall', rsrc, id, job, text, coords, src)
  end
end)

RegisterNetEvent('pt-dispatch:server:accept')
AddEventHandler('pt-dispatch:server:accept', function(callId)
  local src = source
  local call = calls[callId]
  if not call or call.acceptedBy then return end
  
  local P = QBCore.Functions.GetPlayer(src)
  if not P or not P.PlayerData or not P.PlayerData.job then return end
  local j = P.PlayerData.job.name
  if not ((call.job == 'police' and (j == 'police' or j == 'psp' or j == 'gnr' or j == 'pj'))
    or (call.job == 'ems' and (j == 'ambulance' or j == 'ems' or j == 'inem' or j == 'doctor'))
    or (call.job == 'fire' and (j == 'fire' or j == 'bombeiros' or j == 'firefighter'))
    or j == call.job) then return end
  call.acceptedBy = src
  TriggerClientEvent('pt-dispatch:client:startRoute', src, callId, call.job, call.coords)
  
  local recipients = getPlayersWithJob(call.job)
  for _, rsrc in ipairs(recipients) do
    if rsrc ~= src then
      TriggerClientEvent('QBCore:Notify', rsrc, ('Pedido #%d aceite por uma unidade.'):format(callId), 'primary')
    end
  end
  
  TriggerClientEvent('QBCore:Notify', call.caller, 'O teu pedido foi aceite. A unidade está a caminho.', 'success')
  
  if call.job == 'fire' then
    TriggerEvent('pt-firefighters:server:acceptFromDispatch', callId, call.coords)
  end
end)

RegisterCommand('fecharcall', function(source, args)
  local id = tonumber(args[1] or '')
  if not id or not calls[id] then return end
  local call = calls[id]
  if call.acceptedBy then
    TriggerClientEvent('pt-dispatch:client:clear', call.acceptedBy, id)
  end
  calls[id] = nil
end)
