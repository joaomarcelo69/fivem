local function getQB()
  if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
    return exports['qb-core']:GetCoreObject()
  elseif GetCoreObject then
    return GetCoreObject()
  end
end

local QBCore = getQB()

local function hasJob(src, jobNames)
  if not QBCore then return false end
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player or not Player.PlayerData or not Player.PlayerData.job then return false end
  for _, j in ipairs(jobNames) do
    if Player.PlayerData.job.name == j or Player.PlayerData.job.type == j then return true end
  end
  return false
end

local function isLeoJob(name)
  return name == 'police' or name == 'psp' or name == 'gnr' or name == 'pj'
end

local function getGradeLevel(src)
  local Player = QBCore.Functions.GetPlayer(src)
  if Player and Player.PlayerData and Player.PlayerData.job and Player.PlayerData.job.grade and Player.PlayerData.job.grade.level then
    return tonumber(Player.PlayerData.job.grade.level) or 0
  end
  return 0
end

-- Simple in-memory route state and payouts
local RouteState = {}
-- Prefer global RoutePayouts from config.lua if present
local RoutePayouts = rawget(_G, 'RoutePayouts') or {
  taxi = { per = 75, bonus = 150 },
  bus = { per = 100, bonus = 250 },
  trucker = { per = 150, bonus = 400 },
}

-- Return job/grade and allowed actions to client
QBCore.Functions.CreateCallback('pt-jobmenu:getContext', function(source, cb)
  local Player = QBCore.Functions.GetPlayer(source)
  if not Player then cb(nil) return end
  local job = Player.PlayerData.job or {}
  local lvl = getGradeLevel(source)
  local context = { job = job.name, grade = lvl, isBoss = job.grade and job.grade.isboss or false, onDuty = job.onduty or false }
  cb(context)
end)

-- Generic actions per job (minimal realistic placeholders)
local JobActions = {
  police = {
    { id = 'police_backup', label = 'Pedir Reforços', minGrade = 1, requiresDuty = true },
    { id = 'police_loadout', label = 'Requisitar Equipamento', minGrade = 1, requiresDuty = true },
    { id = 'police_cone', label = 'Colocar cone', minGrade = 1, requiresDuty = true },
    { id = 'police_barrier', label = 'Colocar barreira', minGrade = 1, requiresDuty = true },
    { id = 'police_spikes', label = 'Colocar “spikes”', minGrade = 2, requiresDuty = true },
    { id = 'police_barrier_line', label = 'Linha de cones/barreiras', minGrade = 1, requiresDuty = true },
    { id = 'police_spikes_wide', label = 'Spikes (cobrir faixa)', minGrade = 2, requiresDuty = true },
    { id = 'police_megaphone', label = 'Megafone: Dispersar!', minGrade = 1, requiresDuty = true },
    { id = 'police_clearprops', label = 'Recolher cones/barreiras', minGrade = 1, requiresDuty = true },
    { id = 'police_uniform', label = 'Vestir uniforme', minGrade = 0, requiresDuty = true },
  },
  -- PSP (urbano)
  psp = {
    { id = 'police_backup', label = 'PSP: Pedir Reforços', minGrade = 1, requiresDuty = true },
    { id = 'police_loadout', label = 'PSP: Requisitar Equipamento', minGrade = 1, requiresDuty = true },
    { id = 'police_cone', label = 'Colocar cone', minGrade = 1, requiresDuty = true },
    { id = 'police_barrier', label = 'Colocar barreira', minGrade = 1, requiresDuty = true },
    { id = 'police_spikes', label = 'Colocar “spikes”', minGrade = 2, requiresDuty = true },
    { id = 'police_barrier_line', label = 'Linha de cones/barreiras', minGrade = 1, requiresDuty = true },
    { id = 'police_megaphone', label = 'Megafone: Dispersar!', minGrade = 1, requiresDuty = true },
    { id = 'police_clearprops', label = 'Recolher cones/barreiras', minGrade = 1, requiresDuty = true },
    { id = 'psp_spawn', label = 'PSP: Requisitar viatura', minGrade = 1, requiresDuty = true },
    { id = 'psp_store', label = 'PSP: Guardar viatura', minGrade = 1, requiresDuty = true },
    { id = 'police_uniform', label = 'PSP: Vestir uniforme', minGrade = 0, requiresDuty = true },
  },
  -- GNR (trânsito)
  gnr = {
    { id = 'police_backup', label = 'GNR: Pedir Reforços', minGrade = 1, requiresDuty = true },
    { id = 'police_loadout', label = 'GNR: Requisitar Equipamento', minGrade = 1, requiresDuty = true },
    { id = 'police_cone', label = 'Colocar cone', minGrade = 0, requiresDuty = true },
    { id = 'police_barrier', label = 'Colocar barreira', minGrade = 0, requiresDuty = true },
    { id = 'police_spikes', label = 'Colocar “spikes”', minGrade = 1, requiresDuty = true },
    { id = 'police_barrier_line', label = 'Linha de cones/barreiras', minGrade = 0, requiresDuty = true },
    { id = 'gnr_speed_check', label = 'Operação STOP / Radar (RP)', minGrade = 0, requiresDuty = true },
  { id = 'gnr_radar', label = 'Ativar Radar de Velocidade', minGrade = 0, requiresDuty = true },
  { id = 'police_uniform', label = 'GNR: Vestir uniforme', minGrade = 0, requiresDuty = true },
    { id = 'police_megaphone', label = 'Megafone: Encostar, por favor!', minGrade = 0, requiresDuty = true },
    { id = 'police_clearprops', label = 'Recolher cones/barreiras', minGrade = 0, requiresDuty = true },
    { id = 'gnr_spawn', label = 'GNR: Requisitar viatura', minGrade = 0, requiresDuty = true },
    { id = 'gnr_store', label = 'GNR: Guardar viatura', minGrade = 0, requiresDuty = true },
  },
  -- PJ (investigação)
  pj = {
    { id = 'police_backup', label = 'PJ: Pedir Reforços', minGrade = 1, requiresDuty = true },
    { id = 'police_loadout', label = 'PJ: Requisitar Equipamento', minGrade = 1, requiresDuty = true },
    { id = 'pj_seize', label = 'Apreender Provas (RP)', minGrade = 1, requiresDuty = true },
    { id = 'pj_markscene', label = 'Isolar Local do Crime', minGrade = 1, requiresDuty = true },
    { id = 'police_megaphone', label = 'Megafone: Afastar do local!', minGrade = 1, requiresDuty = true },
    { id = 'police_clearprops', label = 'Recolher material', minGrade = 1, requiresDuty = true },
    { id = 'pj_spawn', label = 'PJ: Requisitar viatura descaracterizada', minGrade = 1, requiresDuty = true },
    { id = 'pj_store', label = 'PJ: Guardar viatura', minGrade = 1, requiresDuty = true },
    { id = 'police_uniform', label = 'PJ: Vestir traje', minGrade = 0, requiresDuty = true },
  },
  ambulance = {
    { id = 'ems_treat', label = 'Tratar paciente próximo', minGrade = 1, requiresDuty = true },
    { id = 'ems_kit', label = 'Requisitar Kit Médico', minGrade = 0, requiresDuty = true },
    { id = 'ems_stabilize', label = 'Estabilizar paciente próximo', minGrade = 1, requiresDuty = true },
    { id = 'ems_revive', label = 'Reanimar paciente próximo', minGrade = 2, requiresDuty = true },
  },
  -- Alias para bombeiros mais abaixo
  taxi = {
    { id = 'taxi_available', label = 'Anunciar disponibilidade', minGrade = 0, requiresDuty = true },
    { id = 'taxi_route', label = 'Iniciar rota de táxi', minGrade = 0, requiresDuty = true },
    { id = 'mech_repair', label = 'Reparar veículo próximo', minGrade = 0, requiresDuty = true },
  },
  tvde = {
    { id = 'tvde_available', label = 'Anunciar disponibilidade (TVDE)', minGrade = 0, requiresDuty = true },
    { id = 'tvde_route', label = 'Iniciar rota TVDE', minGrade = 0, requiresDuty = true },
  },
  mechanic = {
    { id = 'mech_open', label = 'Anunciar oficina aberta', minGrade = 0, requiresDuty = true },
    { id = 'mech_kit', label = 'Requisitar Kit de Reparação', minGrade = 0, requiresDuty = true },
    { id = 'mech_repair', label = 'Reparar veículo próximo', minGrade = 0, requiresDuty = true },
  },
  beeker = {
    { id = 'mech_open', label = 'Anunciar oficina aberta', minGrade = 0, requiresDuty = true },
    { id = 'mech_kit', label = 'Requisitar Kit de Reparação', minGrade = 0, requiresDuty = true },
    { id = 'mech_repair', label = 'Reparar veículo próximo', minGrade = 0, requiresDuty = true },
  },
  bennys = {
    { id = 'mech_open', label = 'Anunciar oficina aberta', minGrade = 0, requiresDuty = true },
    { id = 'mech_kit', label = 'Requisitar Kit de Reparação', minGrade = 0, requiresDuty = true },
    { id = 'mech_repair', label = 'Reparar veículo próximo', minGrade = 0, requiresDuty = true },
  },
  mechanic2 = {
    { id = 'mech_open', label = 'Anunciar oficina aberta', minGrade = 0, requiresDuty = true },
  },
  mechanic3 = {
    { id = 'mech_open', label = 'Anunciar oficina aberta', minGrade = 0, requiresDuty = true },
  },
  tow = {
    { id = 'tow_available', label = 'Anunciar reboque disponível', minGrade = 0, requiresDuty = true },
  },
  garbage = {
    { id = 'garb_start', label = 'Iniciar rota de lixo', minGrade = 0, requiresDuty = true },
  },
  bus = {
    { id = 'bus_start', label = 'Iniciar rota de autocarro', minGrade = 0, requiresDuty = true },
  },
  reporter = {
    { id = 'news_announce', label = 'Anunciar reportagem', minGrade = 0, requiresDuty = true },
  },
  cardealer = {
    { id = 'dealer_stock', label = 'Anunciar stock', minGrade = 0, requiresDuty = true },
  },
  realestate = {
    { id = 're_state', label = 'Anunciar casas para venda', minGrade = 0, requiresDuty = true },
  },
  vineyard = {
    { id = 'vine_shift', label = 'Anunciar turno na vinha', minGrade = 0, requiresDuty = true },
  },
  hotdog = {
    { id = 'hotdog_shift', label = 'Anunciar hotdogs à venda', minGrade = 0, requiresDuty = true },
  },
  trucker = {
    { id = 'truck_shift', label = 'Anunciar turno de camionista', minGrade = 0, requiresDuty = true },
    { id = 'truck_route', label = 'Iniciar rota de camionista', minGrade = 0, requiresDuty = true },
  },
  ctt = {
    { id = 'ctt_available', label = 'Anunciar estafeta disponível', minGrade = 0, requiresDuty = true },
    { id = 'ctt_route', label = 'Iniciar rota CTT', minGrade = 0, requiresDuty = true },
  },
  pescador = {
    { id = 'fish_start', label = 'Iniciar rota de pesca', minGrade = 0, requiresDuty = true },
  },
  mineiro = {
    { id = 'mine_start', label = 'Iniciar rota de mineração', minGrade = 0, requiresDuty = true },
  },
}

-- Aliases: bombeiros herda das ações de ambulance
JobActions.bombeiros = JobActions.ambulance

QBCore.Functions.CreateCallback('pt-jobmenu:getActions', function(source, cb)
  local Player = QBCore.Functions.GetPlayer(source)
  if not Player or not Player.PlayerData or not Player.PlayerData.job then cb({}) return end
  local jobName = Player.PlayerData.job.name
  local grade = getGradeLevel(source)
  local onDuty = Player.PlayerData.job.onduty or false
  local actions = {}
   local defs = JobActions[jobName] or {}
    -- Universal vehicle actions for jobs with configured garage/vehicles (except PSP/GNR/PJ which already have custom ones)
    local hasGarage = JobVehicleSpawns and JobVehicleSpawns[jobName] and #JobVehicleSpawns[jobName] > 0
    local hasModels = AllowedJobVehicles and AllowedJobVehicles[jobName] and #AllowedJobVehicles[jobName] > 0
    if hasGarage and hasModels and not (jobName == 'psp' or jobName == 'gnr' or jobName == 'pj') then
      defs = {
        table.unpack(defs),
        { id = 'job_spawn', label = 'Requisitar viatura', minGrade = 0, requiresDuty = true },
        { id = 'job_store', label = 'Guardar viatura', minGrade = 0, requiresDuty = true },
      }
    end
  for _, act in ipairs(defs) do
    if grade >= (act.minGrade or 0) and (not act.requiresDuty or onDuty) then
      table.insert(actions, { id = act.id, label = act.label })
    end
  end
  cb(actions)
end)

RegisterNetEvent('pt-jobmenu:server:execAction')
AddEventHandler('pt-jobmenu:server:execAction', function(actionId)
  local src = source
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player or not Player.PlayerData or not Player.PlayerData.job then return end
  local jobName = Player.PlayerData.job.name
  local grade = getGradeLevel(src)
  local onDuty = Player.PlayerData.job.onduty or false
  -- Validate action against config
  -- Build effective defs (include universal vehicle actions when applicable)
  local defs = JobActions[jobName] or {}
  local hasGarage = JobVehicleSpawns and JobVehicleSpawns[jobName] and #JobVehicleSpawns[jobName] > 0
  local hasModels = AllowedJobVehicles and AllowedJobVehicles[jobName] and #AllowedJobVehicles[jobName] > 0
  if hasGarage and hasModels and not (jobName == 'psp' or jobName == 'gnr' or jobName == 'pj') then
    defs = {
      table.unpack(defs),
      { id = 'job_spawn', label = 'Requisitar viatura', minGrade = 0, requiresDuty = true },
      { id = 'job_store', label = 'Guardar viatura', minGrade = 0, requiresDuty = true },
    }
  end
  local found
  for _, act in ipairs(defs) do
    if act.id == actionId then found = act break end
  end
  if not found then return end
  if grade < (found.minGrade or 0) then return end
  if found.requiresDuty and not onDuty then return end
  -- Execute simple realistic placeholders
  if actionId == 'police_backup' then
    TriggerClientEvent('chat:addMessage', -1, { args = { '^4[Polícia]', ('%s pediu reforços!'):format(GetPlayerName(src)) } })
  elseif actionId == 'ems_treat' then
    TriggerClientEvent('QBCore:Notify', src, 'Tratou o paciente próximo (RP).', 'success')
  elseif actionId == 'ems_kit' then
    local give = function(item, count)
      local ok = pcall(function() Player.Functions.AddItem(item, count or 1) end)
      return ok
    end
    give('firstaid', 2)
    give('bandage', 5)
    TriggerClientEvent('QBCore:Notify', src, 'Recebeu kit médico (2x First Aid, 5x Bandage).', 'success')
  elseif actionId == 'taxi_available' then
    TriggerClientEvent('chat:addMessage', -1, { args = { '^3[Taxi]', 'Motorista disponível. Ligue pelo telefone!' } })
  elseif actionId == 'taxi_route' then
    TriggerClientEvent('pt-jobmenu:client:startRoute', src, 'taxi')
  elseif actionId == 'mech_open' then
    TriggerClientEvent('chat:addMessage', -1, { args = { '^5[Mecânico]', 'Oficina aberta. Dirija-se à garagem!' } })
  elseif actionId == 'mech_kit' then
    local give = function(item, count)
      local ok = pcall(function() Player.Functions.AddItem(item, count or 1) end)
      return ok
    end
    give('repairkit', 1)
    give('tirerepairkit', 2)
    TriggerClientEvent('QBCore:Notify', src, 'Recebeu kit de mecânico (1x Repairkit, 2x Tire Repair Kit).', 'success')
  elseif actionId == 'mech_repair' then
    -- Consume 1 repairkit before allowing repair
    local has = Player.Functions.GetItemByName and Player.Functions.GetItemByName('repairkit')
    if not has or (has.amount or 0) <= 0 then
      TriggerClientEvent('QBCore:Notify', src, 'Precisa de um Repairkit.', 'error')
      return
    end
    local removed = pcall(function() Player.Functions.RemoveItem('repairkit', 1) end)
    if not removed then
      TriggerClientEvent('QBCore:Notify', src, 'Não foi possível usar o Repairkit.', 'error')
      return
    end
    TriggerClientEvent('pt-jobmenu:client:repairNearest', src)
  elseif actionId == 'tow_available' then
    TriggerClientEvent('chat:addMessage', -1, { args = { '^5[Reboque]', 'Serviço de reboque disponível.' } })
  elseif actionId == 'garb_start' then
    TriggerClientEvent('pt-jobmenu:client:startRoute', src, 'garbage')
  elseif actionId == 'bus_start' then
    TriggerClientEvent('pt-jobmenu:client:startRoute', src, 'bus')
  elseif actionId == 'news_announce' then
    TriggerClientEvent('chat:addMessage', -1, { args = { '^6[Weazel News]', 'Reportagem em direto brevemente.' } })
  elseif actionId == 'dealer_stock' then
    TriggerClientEvent('chat:addMessage', -1, { args = { '^2[Stand]', 'Novas viaturas disponíveis no stand!' } })
  elseif actionId == 're_state' then
    TriggerClientEvent('chat:addMessage', -1, { args = { '^2[Imobiliária]', 'Imóveis disponíveis para visita.' } })
  elseif actionId == 'vine_shift' then
    TriggerClientEvent('QBCore:Notify', src, 'Iniciou o turno na vinha (RP).', 'primary')
  elseif actionId == 'hotdog_shift' then
    TriggerClientEvent('chat:addMessage', -1, { args = { '^1[Hotdog]', 'Carrinho de hotdogs em serviço.' } })
  elseif actionId == 'truck_shift' then
    TriggerClientEvent('QBCore:Notify', src, 'Iniciou o turno de camionista (RP).', 'primary')
  elseif actionId == 'truck_route' then
    TriggerClientEvent('pt-jobmenu:client:startRoute', src, 'trucker')
  elseif actionId == 'tvde_available' then
    TriggerClientEvent('chat:addMessage', -1, { args = { '^3[TVDE]', 'Condutor disponível via aplicação.' } })
  elseif actionId == 'tvde_route' then
    TriggerClientEvent('pt-jobmenu:client:startRoute', src, 'tvde')
  elseif actionId == 'ctt_available' then
    TriggerClientEvent('chat:addMessage', -1, { args = { '^3[CTT]', 'Estafeta disponível para entregas.' } })
  elseif actionId == 'ctt_route' then
    TriggerClientEvent('pt-jobmenu:client:startRoute', src, 'ctt')
  elseif actionId == 'fish_start' then
    TriggerClientEvent('pt-jobmenu:client:startRoute', src, 'pescador')
  elseif actionId == 'mine_start' then
    TriggerClientEvent('pt-jobmenu:client:startRoute', src, 'mineiro')
  elseif actionId == 'police_loadout' then
    local give = function(item, count)
      local ok = pcall(function() Player.Functions.AddItem(item, count or 1) end)
      return ok
    end
    -- Loadouts distintos por força
    local jn = jobName
    if jn == 'gnr' then
      give('weapon_handcuffs', 1)
      give('bandage', 2)
      TriggerClientEvent('QBCore:Notify', src, 'Equipamento GNR: algemas + 2x bandage.', 'success')
    elseif jn == 'psp' then
      give('weapon_handcuffs', 1)
      TriggerClientEvent('QBCore:Notify', src, 'Equipamento PSP: algemas.', 'success')
    elseif jn == 'pj' then
      give('weapon_handcuffs', 1)
      TriggerClientEvent('QBCore:Notify', src, 'Equipamento PJ: algemas.', 'success')
    else
      give('weapon_handcuffs', 1)
      TriggerClientEvent('QBCore:Notify', src, 'Equipamento requisitado (algemas).', 'success')
    end
  elseif actionId == 'police_cone' then
    local models = rawget(_G, 'PolicePropModels') or { cone = 'prop_roadcone02a', barrier = 'prop_barrier_work05', spikes = 'p_ld_stinger_s' }
    TriggerClientEvent('pt-jobmenu:client:deployProp', src, models.cone)
  elseif actionId == 'police_barrier' then
    local models = rawget(_G, 'PolicePropModels') or { cone = 'prop_roadcone02a', barrier = 'prop_barrier_work05', spikes = 'p_ld_stinger_s' }
    TriggerClientEvent('pt-jobmenu:client:deployProp', src, models.barrier)
  elseif actionId == 'police_spikes' then
    local models = rawget(_G, 'PolicePropModels') or { cone = 'prop_roadcone02a', barrier = 'prop_barrier_work05', spikes = 'p_ld_stinger_s' }
    TriggerClientEvent('pt-jobmenu:client:deployProp', src, models.spikes)
  elseif actionId == 'police_barrier_line' then
    local models = rawget(_G, 'PolicePropModels') or { cone = 'prop_roadcone02a', barrier = 'prop_barrier_work05', spikes = 'p_ld_stinger_s' }
    TriggerClientEvent('pt-jobmenu:client:deployPropLine', src, models.cone, models.barrier)
  elseif actionId == 'police_spikes_wide' then
    local models = rawget(_G, 'PolicePropModels') or { cone = 'prop_roadcone02a', barrier = 'prop_barrier_work05', spikes = 'p_ld_stinger_s' }
    TriggerClientEvent('pt-jobmenu:client:deploySpikesWide', src, models.spikes)
  elseif actionId == 'police_megaphone' then
    -- Simple megaphone broadcast to nearby players via chat
    local ped = GetPlayerPed(src)
    local pcoords = GetEntityCoords(ped)
    for _, pid in ipairs(GetPlayers()) do
      local tped = GetPlayerPed(pid)
      if tped and tped ~= 0 then
        local c = GetEntityCoords(tped)
        local dx,dy,dz = pcoords.x - c.x, pcoords.y - c.y, pcoords.z - c.z
        local dist2 = dx*dx + dy*dy + dz*dz
        if dist2 <= (80.0*80.0) then
          TriggerClientEvent('chat:addMessage', tonumber(pid), { args = { '^4[Megafone Polícia]', 'Dispersar imediatamente! Colaborem com as autoridades.' } })
        end
      end
    end
  elseif actionId == 'police_clearprops' then
    TriggerClientEvent('pt-jobmenu:client:clearProps', src)
  elseif actionId == 'psp_spawn' or actionId == 'gnr_spawn' or actionId == 'pj_spawn' then
    TriggerClientEvent('pt-jobmenu:client:spawnJobVehicle', src, jobName)
  elseif actionId == 'psp_store' or actionId == 'gnr_store' or actionId == 'pj_store' then
    TriggerClientEvent('pt-jobmenu:client:storeNearestVehicle', src)
  elseif actionId == 'police_uniform' then
    TriggerClientEvent('pt-jobmenu:client:applyUniform', src, jobName)
  elseif actionId == 'gnr_speed_check' then
    -- Placeholder RP: broadcast nearby announcement
    TriggerClientEvent('chat:addMessage', -1, { args = { '^4[GNR]', 'Operação STOP em curso. Respeite a sinalização.' } })
  elseif actionId == 'gnr_radar' then
    TriggerClientEvent('pt-jobmenu:client:gnr:radar', src, 90)
  elseif actionId == 'pj_seize' then
    TriggerClientEvent('QBCore:Notify', src, 'Provas apreendidas (RP).', 'primary')
  elseif actionId == 'pj_markscene' then
    local models = rawget(_G, 'PolicePropModels') or { cone = 'prop_roadcone02a', barrier = 'prop_barrier_work05', spikes = 'p_ld_stinger_s' }
    TriggerClientEvent('pt-jobmenu:client:deployPropLine', src, models.cone, models.barrier)
  elseif actionId == 'ems_revive' then
    TriggerClientEvent('pt-jobmenu:client:ems:promptRevive', src)
  elseif actionId == 'ems_stabilize' then
    TriggerClientEvent('pt-jobmenu:client:ems:promptStabilize', src)
  end
end)

local function isNearDutyZone(src, jobName)
  if not jobName or not JobDutyZones or not JobDutyZones[jobName] then return false end
  local ped = GetPlayerPed(src)
  if ped == 0 then return false end
  local px, py, pz = table.unpack(GetEntityCoords(ped))
  for _, zone in ipairs(JobDutyZones[jobName]) do
    local dx = px - zone.coords.x
    local dy = py - zone.coords.y
    local dz = pz - (zone.coords.z or pz)
    local dist2 = dx*dx + dy*dy + dz*dz
    local r = (zone.radius or 20.0)
    if dist2 <= (r*r) then return true end
  end
  return false
end

-- Duty toggle is triggered via world prompt (client) using this same server event
RegisterNetEvent('pt-jobmenu:server:toggleDuty')
AddEventHandler('pt-jobmenu:server:toggleDuty', function()
  local src = source
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player or not Player.PlayerData or not Player.PlayerData.job then return end
  local jobName = Player.PlayerData.job.name
  if not isNearDutyZone(src, jobName) then
    TriggerClientEvent('QBCore:Notify', src, 'Tem de estar no ponto de serviço do seu emprego.', 'error')
    return
  end
  local newState = not not (not Player.PlayerData.job.onduty)
  Player.Functions.SetJobDuty(newState)
  TriggerEvent('QBCore:Server:SetDuty', src, newState)
  TriggerClientEvent('QBCore:Client:SetDuty', src, newState)
  local msg = newState and 'Entrou em serviço.' or 'Saiu de serviço.'
  TriggerClientEvent('QBCore:Notify', src, msg, newState and 'success' or 'primary')
end)

-- Route lifecycle: secure start and per-checkpoint payouts
QBCore.Functions.CreateCallback('pt-jobmenu:routeStart', function(source, cb, job)
  local Player = QBCore.Functions.GetPlayer(source)
  if not Player or not Player.PlayerData or not Player.PlayerData.job then cb(false, 'Jogador inválido') return end
  if Player.PlayerData.job.name ~= job then cb(false, 'Emprego incorreto') return end
  if not Player.PlayerData.job.onduty then cb(false, 'Tem de estar em serviço') return end
  if not JobRoutes or not JobRoutes[job] or #JobRoutes[job] == 0 then cb(false, 'Rota indisponível') return end
  RouteState[source] = { job = job, idx = 1, len = #JobRoutes[job], lastAt = 0 }
  cb(true, #JobRoutes[job])
end)

QBCore.Functions.CreateCallback('pt-jobmenu:routeCheckpoint', function(source, cb, job, index)
  local st = RouteState[source]
  local Player = QBCore.Functions.GetPlayer(source)
  if not st or not Player then cb(false, 'Sem rota ativa') return end
  if st.job ~= job then cb(false, 'Rota/job inválidos') return end
  if index ~= st.idx then cb(false, 'Checkpoint inválido') return end
  if not Player.PlayerData.job or Player.PlayerData.job.name ~= job or not Player.PlayerData.job.onduty then
    cb(false, 'Tem de estar em serviço no emprego correto')
    return
  end
  -- Basic anti-spam: minimum time between checkpoints
  local now = os.time()
  if st.lastAt and (now - (st.lastAt or 0)) < 2 then
    cb(false, 'Muito rápido')
    return
  end
  st.lastAt = now
  local pay = RoutePayouts[job] or { per = 50, bonus = 100 }
  local amount = pay.per
  local complete = false
  st.idx = st.idx + 1
  if st.idx > st.len then
    -- Completing route pays bonus
    amount = amount + (pay.bonus or 0)
    complete = true
    RouteState[source] = nil
  end
  -- Apply IRS withholding and pay net to bank
  local net, irs = 0, 0
  if exports and exports['pt-fisco'] and exports['pt-fisco'].ApplyIRS then
    net, irs = exports['pt-fisco']:ApplyIRS(source, amount, 'trabalho')
  else
    net = amount
  end
  pcall(function() Player.Functions.AddMoney('bank', net, ('route-%s'):format(job)) end)
  cb(true, amount, complete)
end)

AddEventHandler('playerDropped', function()
  local src = source
  RouteState[src] = nil
end)

-- EMS server-side target handling and item consumption
RegisterNetEvent('pt-jobmenu:server:ems:reviveTarget')
AddEventHandler('pt-jobmenu:server:ems:reviveTarget', function(target)
  local src = source
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player or not Player.PlayerData or not Player.PlayerData.job or Player.PlayerData.job.name ~= 'ambulance' or not Player.PlayerData.job.onduty then return end
  -- require firstaid
  local has = Player.Functions.GetItemByName and Player.Functions.GetItemByName('firstaid')
  if not has or (has.amount or 0) <= 0 then
    TriggerClientEvent('QBCore:Notify', src, 'Precisa de um First Aid.', 'error')
    return
  end
  pcall(function() Player.Functions.RemoveItem('firstaid', 1) end)
  if target and tonumber(target) then
    TriggerClientEvent('pt-jobmenu:client:ems:revive', target)
    TriggerClientEvent('QBCore:Notify', src, 'Paciente reanimado.', 'success')
  end
end)

RegisterNetEvent('pt-jobmenu:server:ems:stabilizeTarget')
AddEventHandler('pt-jobmenu:server:ems:stabilizeTarget', function(target)
  local src = source
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player or not Player.PlayerData or not Player.PlayerData.job or Player.PlayerData.job.name ~= 'ambulance' or not Player.PlayerData.job.onduty then return end
  -- require bandage
  local has = Player.Functions.GetItemByName and Player.Functions.GetItemByName('bandage')
  if not has or (has.amount or 0) <= 0 then
    TriggerClientEvent('QBCore:Notify', src, 'Precisa de uma Bandage.', 'error')
    return
  end
  pcall(function() Player.Functions.RemoveItem('bandage', 1) end)
  if target and tonumber(target) then
    TriggerClientEvent('pt-jobmenu:client:ems:stabilize', target)
    TriggerClientEvent('QBCore:Notify', src, 'Paciente estabilizado.', 'success')
  end
end)

-- Handle police issue fine via menu
RegisterNetEvent('pt-jobmenu:server:police:issueFine')
AddEventHandler('pt-jobmenu:server:police:issueFine', function(data)
  local src = source
  -- Accept any LEO (police, psp, gnr, pj) via type check
  local P = QBCore.Functions.GetPlayer(src)
  if not P or not P.PlayerData or not P.PlayerData.job then return end
  if not isLeoJob(P.PlayerData.job.name) then return end
  local lvl = getGradeLevel(src)
  -- allow from Officer+ (>=1)
  if lvl < 1 then return end
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player or not Player.PlayerData or not Player.PlayerData.job or not Player.PlayerData.job.onduty then return end
  local citizenid = tostring(data.citizenid or '')
  local amount = tonumber(data.amount or 0) or 0
  local reason = tostring(data.reason or '')
  if citizenid == '' or amount <= 0 or reason == '' then return end
  TriggerEvent('pt-multas:emitir', citizenid, amount, reason)
end)

-- Handle reprint fine
RegisterNetEvent('pt-jobmenu:server:police:reprintFine')
AddEventHandler('pt-jobmenu:server:police:reprintFine', function(data)
  local src = source
  local P = QBCore.Functions.GetPlayer(src)
  if not P or not P.PlayerData or not P.PlayerData.job then return end
  if not isLeoJob(P.PlayerData.job.name) then return end
  local lvl = getGradeLevel(src)
  -- allow Sergeant+ (>=2)
  if lvl < 2 then return end
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player or not Player.PlayerData or not Player.PlayerData.job or not Player.PlayerData.job.onduty then return end
  local citizenid = tostring(data.citizenid or '')
  local id = data.id and tonumber(data.id) or nil
  if citizenid == '' then return end
  -- Reprint the last fine or a specific id for the citizen
  local targetCitizenId = data.citizenid
  local id = tonumber(data.id) or nil
  TriggerEvent('pt-multas:reprint', targetCitizenId, id)
end)

-- GNR radar suggestion: try to resolve plate -> driver -> citizenid and auto-fill fine UI
RegisterNetEvent('pt-jobmenu:server:gnr:suggestFine')
AddEventHandler('pt-jobmenu:server:gnr:suggestFine', function(payload)
  local src = source
  local P = QBCore.Functions.GetPlayer(src)
  if not P or not P.PlayerData or not P.PlayerData.job or not P.PlayerData.job.onduty then return end
  if P.PlayerData.job.name ~= 'gnr' and P.PlayerData.job.name ~= 'police' and P.PlayerData.job.name ~= 'psp' then return end
  local amount = tonumber(payload.amount or 0) or 0
  local speed = tonumber(payload.speed or 0) or 0
  local limit = tonumber(payload.limit or 0) or 0
  -- We cannot directly map plate to citizen reliably here without a dedicated vehicle ownership DB.
  -- Attempt to find nearest player in front as the suspected driver (best-effort):
  local suspectId
  local sp = GetPlayerPed(src)
  local spx,spy,spz = table.unpack(GetEntityCoords(sp))
  local best, bestDist
  for _, pid in ipairs(GetPlayers()) do
    if tonumber(pid) ~= tonumber(src) then
      local ped = GetPlayerPed(pid)
      if ped and ped ~= 0 and IsPedInAnyVehicle(ped, false) then
        local x,y,z = table.unpack(GetEntityCoords(ped))
        local dx,dy,dz = spx-x, spy-y, spz-z
        local d2 = dx*dx + dy*dy + dz*dz
        if d2 < (35.0*35.0) and (not best or d2 < bestDist) then
          best = pid; bestDist = d2
        end
      end
    end
  end
  if best then
    local PB = QBCore.Functions.GetPlayer(best)
    if PB and PB.PlayerData and PB.PlayerData.citizenid then
      local citizenid = PB.PlayerData.citizenid
      -- Push auto-fill to officer's NUI
      TriggerClientEvent('pt-jobmenu:client:nui', src, { action = 'fine:autoFill', citizenid = citizenid, amount = amount, reason = ('Excesso de velocidade (%dkm/h em %dkm/h)'):format(speed, limit), speed = speed, limit = limit })
    end
  else
    -- Only push reason/amount
    TriggerClientEvent('pt-jobmenu:client:nui', src, { action = 'fine:autoFill', amount = amount, reason = ('Excesso de velocidade (%dkm/h em %dkm/h)'):format(speed, limit), speed = speed, limit = limit })
  end
end)

-- Simple NUI bridge event for sending messages to pt-jobmenu app
RegisterNetEvent('pt-jobmenu:client:nui')
AddEventHandler('pt-jobmenu:client:nui', function(msg)
  -- passthrough, handled client-side. This event is intended to be sent to a specific client via TriggerClientEvent
end)

-- Fallback: broadcast delete vehicle by network id
RegisterNetEvent('pt-jobmenu:server:broadcastDeleteVehicle')
AddEventHandler('pt-jobmenu:server:broadcastDeleteVehicle', function(netId)
  local src = source
  local P = QBCore.Functions.GetPlayer(src)
  if not P or not P.PlayerData or not P.PlayerData.job or not P.PlayerData.job.onduty then return end
  if not isLeoJob(P.PlayerData.job.name) then return end
  TriggerClientEvent('pt-jobmenu:client:deleteVehicle', -1, netId)
end)

-- Apreender veículo mais próximo do target (polícia; valida proximidade)
RegisterNetEvent('pt-jobmenu:server:impoundNearest')
AddEventHandler('pt-jobmenu:server:impoundNearest', function(targetSrc)
  local src = source
  local P = QBCore.Functions.GetPlayer(src)
  if not P or not P.PlayerData or not P.PlayerData.job or not P.PlayerData.job.onduty then return end
  if not isLeoJob(P.PlayerData.job.name) then return end
  local ts = tonumber(targetSrc)
  if not ts then return end
  -- Delegate detection and deletion to the officer client (more reliable for entity control)
  TriggerClientEvent('pt-jobmenu:client:impoundNearest', src, ts)
end)
