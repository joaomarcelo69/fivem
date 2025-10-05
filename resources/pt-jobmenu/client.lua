local QBCore
local isOpen = false
local dutyBlips = {}
local routeActive = false
local routeJob = nil
local routeIndex = 0
local routeBlip = nil
local routeLen = 0
local placedProps = {}
local routeTotal = 0
local lastSpawnedVeh = nil
local lastRadar = { active = false, limit = 90, plate = nil, speed = 0.0 }

local function getQB()
  if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
    return exports['qb-core']:GetCoreObject()
  elseif GetCoreObject then
    return GetCoreObject()
  end
end

CreateThread(function()
  QBCore = getQB()
  -- Default key: F6 (Police/Job menu)
  RegisterKeyMapping('ptjobmenu:toggle', 'Abrir menu de emprego', 'keyboard', 'F6')
  RegisterCommand('ptjobmenu:toggle', function()
    if isOpen then
      SetNuiFocus(false, false)
      SendNUIMessage({ action = 'close' })
      isOpen = false
      return
    end
    QBCore.Functions.TriggerCallback('pt-jobmenu:getContext', function(ctx)
      SetNuiFocus(true, true)
      SendNUIMessage({ action = 'open', context = ctx })
      isOpen = true
    end)
  end)
end)

function ClearDutyBlips()
  for _, b in ipairs(dutyBlips) do
    if b and DoesBlipExist(b) then RemoveBlip(b) end
  end
  dutyBlips = {}
end

function CreateDutyBlipsForJob(job)
  ClearDutyBlips()
  if not JobDutyZones or not JobDutyZones[job] then return end
  for _, zone in ipairs(JobDutyZones[job]) do
    local blip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
    SetBlipSprite(blip, 280) -- briefcase icon
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, 3)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(zone.label or 'Ponto de Serviço')
    EndTextCommandSetBlipName(blip)
    table.insert(dutyBlips, blip)
  end
end

-- Duty is now toggled via in-world prompt, not via NUI

RegisterNUICallback('close', function(_, cb)
  SetNuiFocus(false, false)
  isOpen = false
  cb(true)
end)

RegisterNUICallback('police:issueFine', function(data, cb)
  TriggerServerEvent('pt-jobmenu:server:police:issueFine', data)
  cb(true)
end)

RegisterNUICallback('police:reprintFine', function(data, cb)
  TriggerServerEvent('pt-jobmenu:server:police:reprintFine', data)
  cb(true)
end)

-- Fetch job actions
RegisterNUICallback('job:getActions', function(_, cb)
  QBCore.Functions.TriggerCallback('pt-jobmenu:getActions', function(actions)
    SendNUIMessage({ action = 'actions', actions = actions or {} })
  end)
  cb(true)
end)

-- Execute one action
RegisterNUICallback('job:execAction', function(data, cb)
  if not data or not data.id then return cb(false) end
  TriggerServerEvent('pt-jobmenu:server:execAction', data.id)
  cb(true)
end)

-- STOP: obter documentos via pt-vehicle-docs
RegisterNUICallback('stop:getDocs', function(data, cb)
  local target = data and tonumber(data.target)
  if not target then cb(false) return end
  QBCore.Functions.TriggerCallback('pt-vehicle-docs:getDocsForSrc', function(d)
    SendNUIMessage({ action = 'stop:docs', docs = d })
  end, target)
  cb(true)
end)

-- STOP: apreender veículo (server valida permissões e proximidade)
RegisterNUICallback('stop:impound', function(data, cb)
  local target = data and tonumber(data.target)
  if not target then cb(false) return end
  -- Primeiro valida documentos: se inválidos, regista apreensão, depois prossegue para remoção do veículo in-world
  QBCore.Functions.TriggerCallback('pt-vehicle-docs:impoundIfInvalid', function(ok, plateOrMsg)
    if not ok then
      QBCore.Functions.Notify(plateOrMsg or 'Documentos em dia.', 'error')
      cb(false)
      return
    end
    -- Agora efetua a apreensão no mundo
    TriggerServerEvent('pt-jobmenu:server:impoundNearest', target)
    if type(plateOrMsg) == 'string' then
      QBCore.Functions.Notify(('Apreensão registada para a matrícula %s.'):format(plateOrMsg), 'primary')
    end
    cb(true)
  end, target)
end)

-- Server asks officer client to locate and impound target's nearest vehicle
RegisterNetEvent('pt-jobmenu:client:impoundNearest', function(targetSrc)
  local officer = PlayerPedId()
  local targetPed = GetPlayerPed(GetPlayerFromServerId(targetSrc))
  if not targetPed or targetPed == 0 then
    QBCore.Functions.Notify('Alvo não encontrado.', 'error')
    return
  end
  -- Check distance from officer to target
  local d = #(GetEntityCoords(officer) - GetEntityCoords(targetPed))
  if d > 20.0 then
    QBCore.Functions.Notify('Muito longe do veículo/condutor.', 'error')
    return
  end
  -- Vehicle the target is in, otherwise raycast ahead of target
  local veh = GetVehiclePedIsIn(targetPed, false)
  if veh == 0 then
    local from = GetEntityCoords(targetPed)
    local to = GetOffsetFromEntityInWorldCoords(targetPed, 0.0, 3.5, 0.0)
    local ray = StartShapeTestRay(from.x, from.y, from.z + 0.8, to.x, to.y, to.z, 10, targetPed, 0)
    local _, hit, _, _, ent = GetShapeTestResult(ray)
    if hit == 1 and ent ~= 0 and IsEntityAVehicle(ent) then veh = ent end
    if veh == 0 then
      -- fallback: closest vehicle around target
      veh = GetClosestVehicle(from.x, from.y, from.z, 6.0, 0, 71)
    end
  end
  if veh == 0 then
    QBCore.Functions.Notify('Nenhum veículo encontrado.', 'error')
    return
  end
  -- Snapshot de propriedades para valet futuro
  local props
  if QBCore.Functions.GetVehicleProperties then
    props = QBCore.Functions.GetVehicleProperties(veh)
  end
  if props and props.plate then
    TriggerServerEvent('pt-vehicle-docs:savePropsAtImpound', props.plate, props)
  end
  -- Try to take control then delete
  SetEntityAsMissionEntity(veh, true, true)
  DeleteVehicle(veh)
  if DoesEntityExist(veh) then
    -- network fallback
    local netId = VehToNet(veh)
    TriggerServerEvent('pt-jobmenu:server:broadcastDeleteVehicle', netId)
  else
    QBCore.Functions.Notify('Veículo apreendido.', 'success')
  end
end)

RegisterNetEvent('pt-jobmenu:client:deleteVehicle', function(netId)
  local veh = NetToVeh(netId)
  if veh ~= 0 and DoesEntityExist(veh) then
    SetEntityAsMissionEntity(veh, true, true)
    DeleteVehicle(veh)
  end
end)

-- Create blips for your current job on spawn/login
CreateThread(function()
  while not QBCore do Wait(200) end
  local player = QBCore.Functions.GetPlayerData()
  if player and player.job and player.job.name then
    CreateDutyBlipsForJob(player.job.name)
  end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
  if job and job.name then
    CreateDutyBlipsForJob(job.name)
  else
    ClearDutyBlips()
  end
end)

-- Duty prompt near blip: press E to toggle duty when close to the duty point
local currentJobName = nil
local currentOnDuty = false

-- Track job and duty state
CreateThread(function()
  while not QBCore do Wait(200) end
  local pdata = QBCore.Functions.GetPlayerData()
  if pdata and pdata.job then
    currentJobName = pdata.job.name
    currentOnDuty = pdata.job.onduty or false
  end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
  local pdata = QBCore.Functions.GetPlayerData()
  if pdata and pdata.job then
    currentJobName = pdata.job.name
    currentOnDuty = pdata.job.onduty or false
  end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
  if job then
    currentJobName = job.name
    currentOnDuty = job.onduty or false
  end
end)

local function DrawText3D(x,y,z, text)
  SetDrawOrigin(x, y, z, 0)
  SetTextScale(0.35, 0.35)
  SetTextFont(4)
  SetTextProportional(1)
  SetTextColour(255, 255, 255, 215)
  SetTextEntry("STRING")
  SetTextCentre(1)
  AddTextComponentString(text)
  DrawText(0.0, 0.0)
  ClearDrawOrigin()
end

CreateThread(function()
  while true do
    Wait(0)
    if currentJobName and JobDutyZones and JobDutyZones[currentJobName] then
      local ped = PlayerPedId()
      local pcoords = GetEntityCoords(ped)
      for _, zone in ipairs(JobDutyZones[currentJobName]) do
        -- draw small marker at duty point
        DrawMarker(2, zone.coords.x, zone.coords.y, zone.coords.z + 0.1, 0,0,0, 0,0,0, 0.25,0.25,0.25, 0, 200, 150, 120, false, true, 2, nil, nil, false)
        local dist = #(pcoords - zone.coords)
        if dist <= 2.0 then
          local keyName = (rawget(_G, 'DutyInteractName') or 'E')
          local keyCode = (rawget(_G, 'DutyInteractKey') or 38)
          local label = (currentOnDuty and ('[%s] Sair de Serviço'):format(keyName)) or ('[%s] Entrar em Serviço'):format(keyName)
          DrawText3D(zone.coords.x, zone.coords.y, zone.coords.z + 0.4, label)
          if IsControlJustReleased(0, keyCode) then
            TriggerServerEvent('pt-jobmenu:server:toggleDuty')
            Wait(500)
          end
        end
      end
    else
      Wait(500)
    end
  end
end)

-- Lightweight routes for taxi/bus/trucker from config
RegisterNetEvent('pt-jobmenu:client:startRoute', function(job)
  if routeActive then return end
  if not JobRoutes or not JobRoutes[job] then return end
  QBCore.Functions.TriggerCallback('pt-jobmenu:routeStart', function(ok, lenOrMsg)
    if not ok then
      QBCore.Functions.Notify(lenOrMsg or 'Não foi possível iniciar a rota.', 'error')
      return
    end
    routeActive = true
    routeJob = job
    routeIndex = 1
    routeLen = tonumber(lenOrMsg) or #JobRoutes[job]
    routeTotal = 0
    SetNextRouteBlip()
    SendNUIMessage({ action = 'hud:route', hud = { show = true, job = job, idx = routeIndex, len = routeLen, last = 0, total = routeTotal } })
    QBCore.Functions.Notify(('Rota iniciada (%s). %d pontos.'):format(job, routeLen), 'primary')
  end, job)
end)

function SetNextRouteBlip()
  if routeBlip and DoesBlipExist(routeBlip) then RemoveBlip(routeBlip) end
  local pts = JobRoutes[routeJob]
  if not pts or not pts[routeIndex] then
    QBCore.Functions.Notify('Rota concluída!', 'success')
    routeActive = false
    routeJob = nil
    routeIndex = 0
    return
  end
  local p = pts[routeIndex]
  routeBlip = AddBlipForCoord(p.x, p.y, p.z)
  SetBlipSprite(routeBlip, 1)
  SetBlipColour(routeBlip, 5)
  SetBlipScale(routeBlip, 0.8)
  SetBlipRoute(routeBlip, true)
end

CreateThread(function()
  while true do
    Wait(0)
    if routeActive and JobRoutes and JobRoutes[routeJob] and JobRoutes[routeJob][routeIndex] then
      local ped = PlayerPedId()
      local pcoords = GetEntityCoords(ped)
      local tgt = JobRoutes[routeJob][routeIndex]
      local dist = #(pcoords - vector3(tgt.x, tgt.y, tgt.z))
      DrawMarker(1, tgt.x, tgt.y, tgt.z - 1.0, 0,0,0, 0,0,0, 1.5,1.5,0.8, 0,150,255, 150, false, true, 2, nil, nil, false)
      -- Update HUD distance smoothly
      SendNUIMessage({ action = 'hud:route', hud = { show = true, job = routeJob, idx = routeIndex, len = routeLen, dist = dist, total = routeTotal } })
      if dist < 3.0 then
        local idx = routeIndex
        QBCore.Functions.TriggerCallback('pt-jobmenu:routeCheckpoint', function(ok, paid, done)
          if not ok then
            QBCore.Functions.Notify(paid or 'Falha no checkpoint.', 'error')
            return
          end
          if paid and paid > 0 then
            QBCore.Functions.Notify(('Recebeu %d€'):format(paid), 'success')
            routeTotal = routeTotal + paid
            SendNUIMessage({ action = 'hud:route', hud = { show = true, job = routeJob, idx = idx, len = routeLen, last = paid, total = routeTotal } })
          end
          if done then
            QBCore.Functions.Notify('Rota concluída!', 'success')
            routeActive = false
            routeJob = nil
            routeIndex = 0
            if routeBlip and DoesBlipExist(routeBlip) then RemoveBlip(routeBlip) end
            SendNUIMessage({ action = 'hud:route', hud = { show = false } })
            return
          end
          routeIndex = idx + 1
          SetNextRouteBlip()
          SendNUIMessage({ action = 'hud:route', hud = { show = true, job = routeJob, idx = routeIndex, len = routeLen, total = routeTotal } })
        end, routeJob, idx)
        Wait(750)
      end
    else
      Wait(250)
    end
  end
end)

RegisterNetEvent('pt-jobmenu:client:repairNearest', function()
  local ped = PlayerPedId()
  local pcoords = GetEntityCoords(ped)
  local veh = GetClosestVehicle(pcoords.x, pcoords.y, pcoords.z, 5.0, 0, 71)
  if veh == 0 then
    QBCore.Functions.Notify('Não há veículo por perto.', 'error')
    return
  end
  TaskStartScenarioInPlace(ped, 'PROP_HUMAN_BUM_BIN', 0, true)
  QBCore.Functions.Notify('A reparar veículo...', 'primary')
  Wait(5000)
  ClearPedTasks(ped)
  SetVehicleFixed(veh)
  SetVehicleDeformationFixed(veh)
  SetVehicleUndriveable(veh, false)
  QBCore.Functions.Notify('Veículo reparado.', 'success')
end)

-- Vehicle spawn/store for job forces
local function getClosestSpawn(job)
  local list = rawget(_G, 'JobVehicleSpawns') and JobVehicleSpawns[job]
  if not list or #list == 0 then return nil end
  local ped = PlayerPedId()
  local p = GetEntityCoords(ped)
  local best, bestd
  for _, s in ipairs(list) do
    local d = #(p - s.coords)
    if not best or d < bestd then best, bestd = s, d end
  end
  return best
end

local function spawnVehicle(model, where)
  local hash = GetHashKey(model)
  if not IsModelValid(hash) then return nil end
  RequestModel(hash)
  local tries=0
  while not HasModelLoaded(hash) and tries<100 do Wait(10) tries=tries+1 end
  if not HasModelLoaded(hash) then return nil end
  local veh = CreateVehicle(hash, where.coords.x, where.coords.y, where.coords.z, where.heading or 0.0, true, false)
  SetVehicleOnGroundProperly(veh)
  SetVehicleDirtLevel(veh, 0.0)
  SetEntityAsMissionEntity(veh, true, true)
  SetVehicleNumberPlateText(veh, (string.upper((currentJobName or 'JOB'))..math.random(100,999)))
  SetPedIntoVehicle(PlayerPedId(), veh, -1)
  SetModelAsNoLongerNeeded(hash)
  return veh
end

RegisterNetEvent('pt-jobmenu:client:spawnJobVehicle', function(job)
  job = job or currentJobName
  local allowed = rawget(_G, 'AllowedJobVehicles') and AllowedJobVehicles[job]
  if not allowed or #allowed == 0 then
    QBCore.Functions.Notify('Sem viaturas definidas para este emprego.', 'error')
    return
  end
  local spot = getClosestSpawn(job)
  if not spot then
    QBCore.Functions.Notify('Sem garagem próxima para este emprego.', 'error')
    return
  end
  -- Try spawn first allowed model that loads
  for _, mdl in ipairs(allowed) do
    local veh = spawnVehicle(mdl, spot)
    if veh and veh ~= 0 then
      if lastSpawnedVeh and DoesEntityExist(lastSpawnedVeh) then
        -- Keep only one spawned by menu: delete previous
        SetEntityAsMissionEntity(lastSpawnedVeh, true, true)
        DeleteVehicle(lastSpawnedVeh)
      end
      lastSpawnedVeh = veh
      QBCore.Functions.Notify('Viatura requisitada.', 'success')
      return
    end
  end
  QBCore.Functions.Notify('Falha ao requisitar viatura.', 'error')
end)

RegisterNetEvent('pt-jobmenu:client:storeNearestVehicle', function()
  local ped = PlayerPedId()
  local coords = GetEntityCoords(ped)
  local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
  if veh ~= 0 then
    SetEntityAsMissionEntity(veh, true, true)
    DeleteVehicle(veh)
    if lastSpawnedVeh and DoesEntityExist(lastSpawnedVeh) then
      if veh == lastSpawnedVeh then lastSpawnedVeh = nil end
    end
    QBCore.Functions.Notify('Viatura guardada.', 'primary')
  else
    QBCore.Functions.Notify('Nenhuma viatura por perto.', 'error')
  end
end)

-- Police props (cones, barreiras, spikes)
RegisterNetEvent('pt-jobmenu:client:deployProp', function(model)
  local ped = PlayerPedId()
  local coords = GetEntityCoords(ped)
  local fwd = GetEntityForwardVector(ped)
  local right = vector3(fwd.y, -fwd.x, 0.0)
  local placeDist = 1.6
  local pos = coords + fwd * placeDist
  local heading = GetEntityHeading(ped)
  local mdl = GetHashKey(model)
  if not IsModelValid(mdl) then QBCore.Functions.Notify('Modelo inválido.', 'error') return end
  RequestModel(mdl)
  local tries = 0
  while not HasModelLoaded(mdl) and tries < 100 do Wait(10) tries = tries + 1 end
  if not HasModelLoaded(mdl) then QBCore.Functions.Notify('Falha a carregar modelo.', 'error') return end

  -- Ajustar altura ao chão com raycast
  local function groundAt(pos)
    local from = vector3(pos.x, pos.y, pos.z + 1.5)
    local to = vector3(pos.x, pos.y, pos.z - 2.0)
    local ray = StartShapeTestRay(from.x, from.y, from.z, to.x, to.y, to.z, 1, ped, 0)
    local _, hit, hitPos = GetShapeTestResult(ray)
    if hit == 1 then return hitPos.z end
    return pos.z
  end

  pos = vector3(pos.x, pos.y, groundAt(pos))
  local obj = CreateObject(mdl, pos.x, pos.y, pos.z, true, true, false)
  SetEntityHeading(obj, heading)

  -- Afinar orientação específica por tipo (spikes perpendicular, cones/barreiras alinhados ao heading)
  local isSpikes = (model == 'p_ld_stinger_s')
  if isSpikes then
    -- Rodar spikes para ficarem perpendiculares ao avanço do agente
    SetEntityHeading(obj, heading + 90.0)
    -- Baixar ligeiramente para assentar bem
    local ox, oy, oz = table.unpack(GetEntityCoords(obj))
    SetEntityCoordsNoOffset(obj, ox, oy, oz - 0.02, false, false, false)
  end

  PlaceObjectOnGroundProperly(obj)
  FreezeEntityPosition(obj, true)
  SetEntityAsMissionEntity(obj, true, true)
  table.insert(placedProps, obj)
  QBCore.Functions.Notify('Item colocado.', 'success')
end)

RegisterNetEvent('pt-jobmenu:client:clearProps', function()
  for i=#placedProps,1,-1 do
    local obj = placedProps[i]
    if obj and DoesEntityExist(obj) then
      DeleteObject(obj)
    end
    table.remove(placedProps, i)
  end
  QBCore.Functions.Notify('Itens recolhidos.', 'primary')
end)

-- Helper to create object with ground alignment
local function CreateGroundedObject(model, pos, heading)
  local mdl = GetHashKey(model)
  if not IsModelValid(mdl) then return nil end
  RequestModel(mdl)
  local tries = 0
  while not HasModelLoaded(mdl) and tries < 100 do Wait(10) tries = tries + 1 end
  if not HasModelLoaded(mdl) then return nil end
  local function groundZ(p)
    local from = vector3(p.x, p.y, p.z + 1.5)
    local to = vector3(p.x, p.y, p.z - 3.0)
    local ray = StartShapeTestRay(from.x, from.y, from.z, to.x, to.y, to.z, 1, PlayerPedId(), 0)
    local _, hit, hitPos = GetShapeTestResult(ray)
    if hit == 1 then return hitPos.z end
    return p.z
  end
  local p = vector3(pos.x, pos.y, groundZ(pos))
  local obj = CreateObject(mdl, p.x, p.y, p.z, true, true, false)
  SetEntityHeading(obj, heading)
  PlaceObjectOnGroundProperly(obj)
  FreezeEntityPosition(obj, true)
  SetEntityAsMissionEntity(obj, true, true)
  table.insert(placedProps, obj)
  return obj
end

-- Deploy a short line of cones and barriers perpendicular to player heading
RegisterNetEvent('pt-jobmenu:client:deployPropLine', function(coneModel, barrierModel)
  local ped = PlayerPedId()
  local base = GetEntityCoords(ped) + GetEntityForwardVector(ped) * 2.0
  local heading = GetEntityHeading(ped)
  local perp = heading + 90.0
  local spacing = 1.8
  for i=-2,2 do
    local offset = i * spacing
    local pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
    pos = vector3(pos.x + math.cos(math.rad(perp)) * offset, pos.y + math.sin(math.rad(perp)) * offset, pos.z)
    CreateGroundedObject((math.abs(i)%2==0) and coneModel or barrierModel, pos, heading)
    Wait(25)
  end
  QBCore.Functions.Notify('Linha colocada.', 'success')
end)

-- Deploy multiple spikes to cover lane width
RegisterNetEvent('pt-jobmenu:client:deploySpikesWide', function(spikeModel)
  local ped = PlayerPedId()
  local forward = GetEntityForwardVector(ped)
  local heading = GetEntityHeading(ped)
  local perpHeading = heading + 90.0
  local base = GetEntityCoords(ped) + forward * 2.0
  local spacing = 3.0
  for i=-1,1 do
    local offset = i * spacing
    local pos = vector3(base.x + math.cos(math.rad(perpHeading)) * offset, base.y + math.sin(math.rad(perpHeading)) * offset, base.z)
    local obj = CreateGroundedObject(spikeModel, pos, perpHeading)
    if obj then
      -- small sink for better look
      local ox, oy, oz = table.unpack(GetEntityCoords(obj))
      SetEntityCoordsNoOffset(obj, ox, oy, oz - 0.02, false, false, false)
    end
    Wait(20)
  end
  QBCore.Functions.Notify('Spikes colocados.', 'success')
end)

-- Simple GNR radar: measure nearest vehicle speed ahead and suggest fine
local function getVehicleInFront(distance)
  local ped = PlayerPedId()
  local from = GetEntityCoords(ped)
  local fwd = GetEntityForwardVector(ped)
  local to = from + (fwd * (distance or 25.0))
  local ray = StartShapeTestRay(from.x, from.y, from.z + 1.0, to.x, to.y, to.z, 10, ped, 0)
  local _, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(ray)
  if hit == 1 and entityHit ~= 0 and IsEntityAVehicle(entityHit) then
    return entityHit
  end
  return 0
end

local function resolveSpeedLimitHere()
  local limits = rawget(_G, 'SpeedLimits') or {}
  local def = rawget(_G, 'DefaultSpeedLimit') or 90
  local p = GetEntityCoords(PlayerPedId())
  local best, bestd
  for _, z in ipairs(limits) do
    local d = #(p - z.coords)
    if d <= (z.radius or 0) and (not bestd or d < bestd) then best = z; bestd = d end
  end
  return (best and best.limit) or def
end

RegisterNetEvent('pt-jobmenu:client:gnr:radar', function(limit)
  limit = tonumber(limit) or resolveSpeedLimitHere() or lastRadar.limit or 90
  lastRadar.active = true
  lastRadar.limit = limit
  QBCore.Functions.Notify(('Radar ativo. Limite %dkm/h. Aponte a via. [E] medir, [G] terminar'):format(limit), 'primary')
  CreateThread(function()
    while lastRadar.active do
      Wait(0)
      -- draw hint
      BeginTextCommandDisplayHelp('STRING')
      AddTextComponentSubstringPlayerName(('Pressione ~INPUT_CONTEXT~ para medir • Limite: %d km/h  |  ~INPUT_VEH_HEADLIGHT~ para terminar'):format(limit))
      EndTextCommandDisplayHelp(0, false, false, -1)
      if IsControlJustReleased(0, 38) then -- E
        local veh = getVehicleInFront(45.0)
        if veh ~= 0 then
          local speed = GetEntitySpeed(veh) * 3.6 -- m/s -> km/h
          local plate = GetVehicleNumberPlateText(veh)
          lastRadar.plate = plate
          lastRadar.speed = speed
          -- Compute suggested fine tiers
          local over = math.max(0, math.floor(speed - limit))
          local tier = 0
          if over >= 50 then tier = 500
          elseif over >= 30 then tier = 300
          elseif over >= 20 then tier = 150
          elseif over >= 10 then tier = 75 end
          QBCore.Functions.Notify(('Medido %skm/h (limite %s). Placa %s. Multa sugerida: %s€'):format(math.floor(speed), limit, plate, tier), tier>0 and 'error' or 'success')
          -- Ask server for citizenid from vehicle plate/driver if possible
          TriggerServerEvent('pt-jobmenu:server:gnr:suggestFine', { plate = plate, speed = math.floor(speed), limit = limit, amount = tier })
        else
          QBCore.Functions.Notify('Sem veículo à frente.', 'error')
        end
        Wait(500)
      elseif IsControlJustReleased(0, 47) then -- G
        lastRadar.active = false
        QBCore.Functions.Notify('Radar terminado.', 'primary')
      end
    end
  end)
end)

-- Uniform toggles (basic): apply presets per job
RegisterNetEvent('pt-jobmenu:client:applyUniform', function(job)
  local ped = PlayerPedId()
  job = job or currentJobName or 'police'
  -- naive presets; servers usually use clothing resources. Here apply minimal components as RP placeholder.
  local function set(comp, drawable, texture)
    SetPedComponentVariation(ped, comp, drawable, texture or 0, 2)
  end
  local function setProp(comp, drawable, texture)
    ClearPedProp(ped, comp)
    if drawable >= 0 then SetPedPropIndex(ped, comp, drawable, texture or 0, true) end
  end
  if job == 'psp' then
    set(11, 55, 0) -- torso
    set(8, 58, 0)  -- undershirt
    set(4, 35, 0)  -- pants
    set(6, 25, 0)  -- shoes
    setProp(0, 46, 0) -- hat
  elseif job == 'gnr' then
    set(11, 53, 0)
    set(8, 58, 0)
    set(4, 33, 0)
    set(6, 25, 0)
    setProp(0, 47, 0)
  elseif job == 'pj' then
    set(11, 4, 0) -- suit jacket
    set(8, 4, 0)  -- shirt
    set(4, 10, 0) -- suit pants
    set(6, 10, 0) -- smart shoes
    setProp(0, -1, 0)
  else -- police default
    set(11, 55, 0)
    set(8, 58, 0)
    set(4, 35, 0)
    set(6, 25, 0)
    setProp(0, 46, 0)
  end
  QBCore.Functions.Notify('Uniforme aplicado (RP).', 'success')
end)

-- EMS revive & stabilize
local function getClosestPlayer(maxDist)
  local players = GetActivePlayers()
  local ped = PlayerPedId()
  local pcoords = GetEntityCoords(ped)
  local best, bestDist
  for _, pid in ipairs(players) do
    if pid ~= PlayerId() then
      local tp = GetPlayerPed(pid)
      local c = GetEntityCoords(tp)
      local d = #(pcoords - c)
      if d <= (maxDist or 3.0) and (not bestDist or d < bestDist) then
        best = pid; bestDist = d
      end
    end
  end
  if best then return GetPlayerServerId(best), bestDist end
  return nil, nil
end

RegisterNetEvent('pt-jobmenu:client:ems:promptRevive', function()
  local target, d = getClosestPlayer(3.0)
  if not target then QBCore.Functions.Notify('Sem paciente por perto.', 'error') return end
  local ped = PlayerPedId()
  TaskStartScenarioInPlace(ped, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
  QBCore.Functions.Notify('A reanimar paciente...', 'primary')
  Wait(5000)
  ClearPedTasks(ped)
  TriggerServerEvent('pt-jobmenu:server:ems:reviveTarget', target)
end)

RegisterNetEvent('pt-jobmenu:client:ems:promptStabilize', function()
  local target, d = getClosestPlayer(3.0)
  if not target then QBCore.Functions.Notify('Sem paciente por perto.', 'error') return end
  local ped = PlayerPedId()
  TaskStartScenarioInPlace(ped, 'CODE_HUMAN_MEDIC_KNEEL', 0, true)
  QBCore.Functions.Notify('A estabilizar paciente...', 'primary')
  Wait(4000)
  ClearPedTasks(ped)
  TriggerServerEvent('pt-jobmenu:server:ems:stabilizeTarget', target)
end)

-- Effects on the target
RegisterNetEvent('pt-jobmenu:client:ems:revive', function()
  local ped = PlayerPedId()
  -- Basic revive effect: clear ragdoll and heal
  ResurrectPed(ped)
  SetEntityHealth(ped, GetEntityMaxHealth(ped))
  ClearPedTasksImmediately(ped)
  QBCore.Functions.Notify('Foste reanimado por um paramédico.', 'success')
end)

RegisterNetEvent('pt-jobmenu:client:ems:stabilize', function()
  local ped = PlayerPedId()
  local h = GetEntityHealth(ped)
  SetEntityHealth(ped, math.max(h, math.floor(GetEntityMaxHealth(ped)*0.6)))
  QBCore.Functions.Notify('Foste estabilizado por um paramédico.', 'success')
end)

-- Generic NUI passthrough: allow server to push messages to the job menu app
RegisterNetEvent('pt-jobmenu:client:nui', function(msg)
  if type(msg) == 'table' then
    SendNUIMessage(msg)
    if msg.action and msg.action:find('fine:') and not isOpen then
      -- ensure menu shows up if needed
      QBCore.Functions.TriggerCallback('pt-jobmenu:getContext', function(ctx)
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', context = ctx })
        isOpen = true
      end)
    end
  end
end)
