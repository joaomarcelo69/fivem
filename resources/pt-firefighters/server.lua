local QBCore = exports['qb-core']:GetCoreObject()

local incidents = {}
local nextId = 1
local stats = {}

local function getPlayersWithJob(jobs)
  local result = {}
  for _, src in pairs(QBCore.Functions.GetPlayers()) do
    local P = QBCore.Functions.GetPlayer(src)
    if P and P.PlayerData and P.PlayerData.job then
      local j = P.PlayerData.job.name
      for _, name in ipairs(jobs) do
        if j == name then table.insert(result, src) break end
      end
    end
  end
  return result
end

local function randomScenario(kind, center)
  local fires, victims = {}, {}
  local nF = math.random(FireConfig.incidents[kind].min, FireConfig.incidents[kind].max)
  for i=1,nF do
    local ox = math.random(-5,5) + 0.0
    local oy = math.random(-5,5) + 0.0
    table.insert(fires, { x = center.x + ox, y = center.y + oy, z = center.z })
  end
  local nV = (kind == 'house') and 2 or 1
  for i=1,nV do
    local ox = math.random(-3,3) + 0.0
    local oy = math.random(-3,3) + 0.0
    table.insert(victims, { x = center.x + ox, y = center.y + oy, z = center.z })
  end
  return { fires = fires, victims = victims }
end

-- Criar incidente (pode ser via admin ou spawn aleatório)
RegisterCommand('fire_spawn', function(src, args)
  local source = src
  local P = QBCore.Functions.GetPlayer(source)
  if source ~= 0 and (not P or not P.PlayerData or not P.PlayerData.job) then return end
  -- default: spawn no jogador
  local ped = GetPlayerPed(source)
  local coords = GetEntityCoords(ped)
  local kind = args[1] == 'house' and 'house' or 'car'
  local id = nextId
  nextId = nextId + 1
  local data = { id = id, kind = kind, location = { x = coords.x, y = coords.y, z = coords.z }, createdAt = os.time(), assigned = false }
  incidents[id] = data
  -- alertar bombeiros via dispatch
  for _, r in ipairs(getPlayersWithJob({ 'fire', 'bombeiros', 'firefighter' })) do
    TriggerClientEvent('pt-dispatch:client:incomingCall', r, id, 'fire', ('Incêndio (%s) reportado'):format(kind), data.location, source)
  end
  TriggerClientEvent('QBCore:Notify', source, ('Incêndio (%s) criado (#%d).'):format(kind, id), 'primary')
end)

RegisterNetEvent('pt-firefighters:server:accept')
AddEventHandler('pt-firefighters:server:accept', function(id)
  local src = source
  local inc = incidents[id]
  if not inc or inc.assigned then return end
  inc.assigned = src
  TriggerClientEvent('pt-firefighters:client:assign', src, inc)
  -- criar cenário
  local scenario = randomScenario(inc.kind, inc.location)
  TriggerClientEvent('pt-firefighters:client:spawnScenario', src, scenario)
  -- notificar INEM para standby
  for _, ems in ipairs(getPlayersWithJob({ 'ambulance', 'ems', 'inem', 'doctor' })) do
    TriggerEvent('qb-phone:server:sendNewMail', {
      sender = 'Central', subject = 'Incêndio em curso', message = 'Bombeiros em deslocação. Estejam em standby para evacuação.', button = {}
    })
  end
end)

RegisterNetEvent('pt-firefighters:server:complete')
AddEventHandler('pt-firefighters:server:complete', function(id)
  local src = source
  local inc = incidents[id]
  if not inc then return end
  -- recompensa simbólica
  local P = QBCore.Functions.GetPlayer(src)
  if P then P.Functions.AddMoney('bank', 500, 'firefighting') end
  TriggerClientEvent('QBCore:Notify', src, 'Incêndio controlado. Bom trabalho!', 'success')
  incidents[id] = nil
  stats[src] = stats[src] or { incidents = 0, victims = 0 }
  stats[src].incidents = stats[src].incidents + 1
end)

RegisterNetEvent('pt-firefighters:server:locker')
AddEventHandler('pt-firefighters:server:locker', function(option)
  local src = source
  local P = QBCore.Functions.GetPlayer(src)
  if not P or not P.PlayerData or not P.PlayerData.job then return end
  local j = P.PlayerData.job.name
  if not (j == 'fire' or j == 'bombeiros' or j == 'firefighter') then return end
  -- dar equipamentos básicos
  if P.Functions.AddItem then
    if option == 'epi' then
      -- Aqui poderíamos chamar um recurso de roupas; por agora, apenas notificação
      TriggerClientEvent('QBCore:Notify', src, 'EPI equipado.', 'success')
    elseif option == 'ext' then
      P.Functions.AddItem('weapon_fireextinguisher', 1)
      TriggerClientEvent('QBCore:Notify', src, 'Extintor recolhido.', 'success')
    elseif option == 'kit' then
      P.Functions.AddItem('medkit', 2)
      TriggerClientEvent('QBCore:Notify', src, 'Kits médicos recolhidos.', 'success')
    else
      P.Functions.AddItem('weapon_fireextinguisher', 1)
      P.Functions.AddItem('medkit', 2)
      TriggerClientEvent('QBCore:Notify', src, 'Equipamento recolhido (EPI simbólico/Extintor/Kit).', 'success')
    end
  end
end)

RegisterNetEvent('pt-firefighters:server:spawnVehicle')
AddEventHandler('pt-firefighters:server:spawnVehicle', function()
  local src = source
  local P = QBCore.Functions.GetPlayer(src)
  if not P or not P.PlayerData or not P.PlayerData.job then return end
  local j = P.PlayerData.job.name
  if not (j == 'fire' or j == 'bombeiros' or j == 'firefighter') then return end
  TriggerClientEvent('QBCore:Notify', src, 'Dirige um veículo autorizado da garagem.', 'primary')
  -- Mantemos simples: jogadores puxam veículo do menu do servidor/garagem de job existente
end)

-- Aceitação vinda do dispatch (quando o pedido foi aberto por um cidadão)
RegisterNetEvent('pt-firefighters:server:acceptFromDispatch')
AddEventHandler('pt-firefighters:server:acceptFromDispatch', function(callId, coords)
  local src = source
  local id = callId
  if not incidents[id] then
    incidents[id] = { id = id, kind = 'car', location = coords, createdAt = os.time(), assigned = false }
  end
  local inc = incidents[id]
  if inc.assigned then return end
  inc.assigned = src
  TriggerClientEvent('pt-firefighters:client:assign', src, inc)
  local scenario = randomScenario(inc.kind, inc.location)
  TriggerClientEvent('pt-firefighters:client:spawnScenario', src, scenario)
end)

-- Entrega de vítima no hospital
RegisterNetEvent('pt-firefighters:server:dropVictim')
AddEventHandler('pt-firefighters:server:dropVictim', function()
  local src = source
  local P = QBCore.Functions.GetPlayer(src)
  if not P then return end
  P.Functions.AddMoney('bank', 150, 'victim-dropoff')
  TriggerClientEvent('QBCore:Notify', src, 'Vítima entregue. +150€', 'success')
  stats[src] = stats[src] or { incidents = 0, victims = 0 }
  stats[src].victims = stats[src].victims + 1
end)

QBCore.Commands.Add('ffstats', 'Estatísticas de serviço (Bombeiros)', {}, false, function(source)
  local s = stats[source]
  if not s then
    TriggerClientEvent('QBCore:Notify', source, 'Sem estatísticas ainda.', 'primary')
    return
  end
  TriggerClientEvent('QBCore:Notify', source, ('Incêndios: %d | Vítimas: %d'):format(s.incidents, s.victims), 'primary')
end, 'user')
