local QBCore = exports['qb-core']:GetCoreObject()

local active = nil
local blip = nil
local fires = {}
local victims = {}
local hoseActive = false
local nearHydrant = false
local oxygen = 100
local carrying = false
local carriedPed = nil
local smokeFx = {}

local function isFireJob()
  local d = QBCore.Functions.GetPlayerData()
  local j = d and d.job and d.job.name or ''
  return j == 'fire' or j == 'bombeiros' or j == 'firefighter'
end

local function applyOutfitEPI()
  -- EPI simples (pode ser substituído por integração qb-clothing)
  local ped = PlayerPedId()
  local model = GetEntityModel(ped)
  local cfg = FireConfig.outfits
  local set = (model == GetHashKey('mp_m_freemode_01')) and cfg.male or cfg.female
  if set and set.components then
    for _, c in ipairs(set.components) do
      SetPedComponentVariation(ped, c.id, c.drawable, c.texture or 0, 2)
    end
  end
  if set and set.props then
    for _, p in ipairs(set.props) do
      SetPedPropIndex(ped, p.id, p.drawable, p.texture or 0, true)
    end
  end
  QBCore.Functions.Notify('EPI equipado (genérico).', 'success')
end

local function setWaypoint(coords)
  if blip then RemoveBlip(blip) end
  blip = AddBlipForCoord(coords.x, coords.y, coords.z)
  SetBlipSprite(blip, 436) -- fire
  SetBlipColour(blip, 1)
  SetBlipRoute(blip, true)
end

RegisterNetEvent('pt-firefighters:client:assign')
AddEventHandler('pt-firefighters:client:assign', function(data)
  active = data
  setWaypoint(data.location)
  QBCore.Functions.Notify('Incêndio designado. Dirige-te ao local!', 'error')
end)

RegisterNetEvent('pt-firefighters:client:spawnScenario')
AddEventHandler('pt-firefighters:client:spawnScenario', function(scenario)
  -- scenario: { fires = [{x,y,z}], victims = [{x,y,z}] }
  for _, f in ipairs(scenario.fires or {}) do
    local h = StartScriptFire(f.x+0.0, f.y+0.0, f.z+0.0, 25, false)
    table.insert(fires, h)
  end
  for _, v in ipairs(scenario.victims or {}) do
    local ped = CreatePed(4, GetHashKey('a_m_y_stwhi_01'), v.x, v.y, v.z, 0.0, true, true)
    SetEntityHealth(ped, 150)
    TaskWrithe(ped, ped, 5000, 0)
    table.insert(victims, ped)
  end
end)

local function hasItem(item)
  local pdata = QBCore.Functions.GetPlayerData()
  if not pdata or not pdata.items then return false end
  for _, it in pairs(pdata.items) do
    if it and (it.name == item or it.slot == item) then return true end
  end
  return true -- fallback permissivo se inventário não estiver integrado
end

CreateThread(function()
  while true do
    Wait(0)
    if active then
      -- render UI mínima nas vítimas/fogos
      local p = PlayerPedId()
      local pos = GetEntityCoords(p)
      for _, fire in ipairs(fires) do
        -- desenhar hint
      end
      -- Extinguir com extintor (ajuste: detectar spray)
      if IsPedShooting(PlayerPedId()) then
        local wep = GetSelectedPedWeapon(PlayerPedId())
        if wep == GetHashKey('WEAPON_FIREEXTINGUISHER') then
          -- apagar fogos próximos
          local cleaned = 0
          for i=#fires,1,-1 do
            local fh = fires[i]
            StopScriptFire(fh)
            table.remove(fires, i)
            cleaned = cleaned + 1
            if cleaned >= 2 then break end
          end
          if cleaned > 0 then QBCore.Functions.Notify('Fogo reduzido.', 'success') end
        end
      end
      -- Tratar vítimas (E com medkit)
      for i=#victims,1,-1 do
        local vp = victims[i]
        if DoesEntityExist(vp) then
          local d = #(GetEntityCoords(vp) - pos)
          if d < 2.0 then
            QBCore.Functions.DrawText3D(GetEntityCoords(vp).x, GetEntityCoords(vp).y, GetEntityCoords(vp).z+0.9, 'Carrega [E] para estabilizar')
            if IsControlJustReleased(0, 38) then
              if hasItem(FireConfig.medkitItem or 'medkit') then
                SetEntityHealth(vp, 200)
                ClearPedTasks(vp)
                TaskSmartFleePed(vp, PlayerPedId(), 30.0, -1)
                table.remove(victims, i)
                QBCore.Functions.Notify('Vítima estabilizada.', 'success')
              else
                QBCore.Functions.Notify('Precisas de um kit médico.', 'error')
              end
            end
          end
        else
          table.remove(victims, i)
        end
      end
      -- concluir quando não restarem fogos nem vítimas
      if #fires == 0 and #victims == 0 then
        TriggerServerEvent('pt-firefighters:server:complete', active.id)
        if blip then RemoveBlip(blip) blip = nil end
        active = nil
      end
    end
    -- Quartel: armários e garagem
    for _, st in ipairs(FireConfig.stations or {}) do
      local p = PlayerPedId()
      local pos = GetEntityCoords(p)
      local l = vector3(st.locker.x, st.locker.y, st.locker.z)
      if #(pos - l) < 20.0 then
        DrawMarker(1, l.x, l.y, l.z-1.0, 0,0,0, 0,0,0, 1.2,1.2,0.6, 255,0,0, 120, false, true, 2, nil, nil, false)
        if #(pos - l) < 2.0 then
          QBCore.Functions.DrawText3D(l.x, l.y, l.z, 'Armário: [E] Equipar EPI / Extintor / Kit')
          if IsControlJustReleased(0, 38) then
            if lib and lib.registerContext and lib.showContext then
              lib.registerContext({ id = 'ff_locker', title = 'Armário Bombeiros', options = {
                { title = 'Equipar EPI', onSelect = function() applyOutfitEPI(); TriggerServerEvent('pt-firefighters:server:locker', 'epi') end },
                { title = 'Extintor', onSelect = function() TriggerServerEvent('pt-firefighters:server:locker', 'ext') end },
                { title = 'Kit Médico', onSelect = function() TriggerServerEvent('pt-firefighters:server:locker', 'kit') end },
              }})
              lib.showContext('ff_locker')
            else
              applyOutfitEPI(); TriggerServerEvent('pt-firefighters:server:locker')
            end
          end
        end
      end
  local g = vector3(st.garage.x, st.garage.y, st.garage.z)
      if #(pos - g) < 20.0 then
        DrawMarker(36, g.x, g.y, g.z+0.2, 0,0,0, 0,0,0, 1.4,1.4,1.4, 255,100,0, 120, false, true, 2, nil, nil, false)
        if #(pos - g) < 2.5 then
          QBCore.Functions.DrawText3D(g.x, g.y, g.z+0.2, 'Garagem: [E] Tirar Viatura')
          if IsControlJustReleased(0, 38) then
            if lib and lib.registerContext and lib.showContext then
              local opts = {}
              for _, m in ipairs(st.vehicles or {}) do
                table.insert(opts, { title = m.label or m.model, onSelect = function()
                  local hash = GetHashKey(m.model or 'firetruk')
                  RequestModel(hash); while not HasModelLoaded(hash) do Wait(10) end
                  local heading = (st.garage and st.garage.h) or 0.0
                  local veh = CreateVehicle(hash, g.x, g.y, g.z, heading, true, false)
                  SetVehicleOnGroundProperly(veh)
                  -- Pinturas personalizadas conforme config
                  if m.color1 then
                    SetVehicleCustomPrimaryColour(veh, m.color1[1] or 255, m.color1[2] or 0, m.color1[3] or 0)
                  end
                  if m.color2 then
                    SetVehicleCustomSecondaryColour(veh, m.color2[1] or 255, m.color2[2] or 255, m.color2[3] or 255)
                  end
                  -- Extras do veículo (liga extras listados)
                  if m.extras then
                    for k, v in pairs(m.extras) do
                      if type(k) == 'number' and type(v) == 'boolean' then
                        -- v=true significa ligado; SetVehicleExtra usa disable, por isso inverte
                        SetVehicleExtra(veh, k, not v)
                      elseif type(v) == 'number' then
                        SetVehicleExtra(veh, v, false)
                      end
                    end
                  end
                  -- Matrícula estilo PT com prefixo de serviço, se existir
                  if m.platePrefix and type(m.platePrefix) == 'string' and #m.platePrefix > 0 then
                    local p1 = string.format('%02d', math.random(0,99))
                    local p2 = string.format('%02d', math.random(0,99))
                    SetVehicleNumberPlateText(veh, (m.platePrefix .. '-' .. p1 .. '-' .. p2))
                  else
                    local l1 = string.char(math.random(65,90), math.random(65,90))
                    local l2 = string.char(math.random(65,90), math.random(65,90))
                    local n = string.format('%02d', math.random(0,99))
                    SetVehicleNumberPlateText(veh, (l1..'-'..l2..'-'..n))
                  end
                  if m.livery then SetVehicleLivery(veh, m.livery) end
                  TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
                end })
              end
              lib.registerContext({ id = 'ff_garage', title = 'Garagem', options = opts })
              lib.showContext('ff_garage')
            else
              TriggerServerEvent('pt-firefighters:server:spawnVehicle')
            end
          end
        end
      end
    end
    -- Hidrantes: ligar mangueira para maior alcance
    nearHydrant = false
    local nearTruck = false
    for _, h in ipairs(FireConfig.hydrants or {}) do
      local hv = vector3(h.x, h.y, h.z)
      if #(GetEntityCoords(PlayerPedId()) - hv) < 2.0 then
        nearHydrant = true
        QBCore.Functions.DrawText3D(hv.x, hv.y, hv.z+0.5, hoseActive and '[E] Desligar Mangueira' or '[E] Ligar Mangueira')
        if IsControlJustReleased(0, 38) then
          hoseActive = not hoseActive
          QBCore.Functions.Notify(hoseActive and 'Mangueira ligada ao hidrante.' or 'Mangueira desligada.', 'primary')
        end
      end
    end
    -- verificar proximidade de camião de bombeiros
    local pcoords = GetEntityCoords(PlayerPedId())
    local veh = GetClosestVehicle(pcoords.x, pcoords.y, pcoords.z, 6.0, 0, 70)
    if veh ~= 0 and DoesEntityExist(veh) then
      local mdl = GetEntityModel(veh)
      if mdl == GetHashKey('firetruk') then nearTruck = true end
    end
    if hoseActive and (not nearHydrant and not nearTruck) then
      hoseActive = false
      QBCore.Functions.Notify('A mangueira desconectou-se (afastaste-te do hidrante/camião).', 'error')
    end
    -- Efeito máscara O2 e fumo (simples)
    if active and active.kind == 'house' then
      if not IsPedInAnyVehicle(PlayerPedId(), false) then
        oxygen = math.max(0, oxygen - 0.02)
        if oxygen <= 10 then
          ApplyDamageToPed(PlayerPedId(), 1, false)
        end
      end
    else
      oxygen = math.min(100, oxygen + 0.05)
    end
  end
end)

-- Extintor com mangueira ligada: mais alcance e apaga mais focos
CreateThread(function()
  while true do
    Wait(0)
    if hoseActive and IsPedShooting(PlayerPedId()) then
      local wep = GetSelectedPedWeapon(PlayerPedId())
      if wep == GetHashKey('WEAPON_FIREEXTINGUISHER') then
        local cleaned = 0
        for i=#fires,1,-1 do
          StopScriptFire(fires[i])
          table.remove(fires, i)
          cleaned = cleaned + 1
          if cleaned >= 4 then break end
        end
        if cleaned > 0 then QBCore.Functions.Notify('Mangueira: vários focos extintos.', 'success') end
      end
    end
  end
end)

-- Transportar vítima e entregar no hospital
CreateThread(function()
  while true do
    Wait(0)
    if not carrying then
      -- tentar apanhar vítima perto
      local p = PlayerPedId()
      local pos = GetEntityCoords(p)
      for _, v in ipairs(victims) do
        if DoesEntityExist(v) and #(GetEntityCoords(v) - pos) < 2.0 then
          QBCore.Functions.DrawText3D(pos.x, pos.y, pos.z+1.0, '[G] Pegar Vítima')
          if IsControlJustReleased(0, 47) then -- G
            carrying = true
            carriedPed = v
            AttachEntityToEntity(v, p, GetPedBoneIndex(p, 11816), 0.25, 0.15, 0.0, 180.0, 90.0, 90.0, false, false, false, false, 2, true)
            QBCore.Functions.Notify('Vítima ao ombro. Leva à ambulância ou hospital.', 'primary')
            break
          end
        end
      end
      else
      -- Soltar/entregar
      local p = PlayerPedId()
      local pos = GetEntityCoords(p)
      QBCore.Functions.DrawText3D(pos.x, pos.y, pos.z+1.0, '[H] Largar | Aproxima-te do hospital para entregar')
      if IsControlJustReleased(0, 74) then -- H
        DetachEntity(carriedPed, true, true)
        carrying = false
        carriedPed = nil
      else
        -- Check hospitais
        for _, h in ipairs(FireConfig.hospitals or {}) do
          local hv = vector3(h.x, h.y, h.z)
          if #(pos - hv) < 3.0 then
            DetachEntity(carriedPed, true, true)
            DeleteEntity(carriedPed)
            carrying = false
            carriedPed = nil
            TriggerServerEvent('pt-firefighters:server:dropVictim')
            QBCore.Functions.Notify('Vítima entregue no hospital.', 'success')
            break
          end
        end
          -- Carregar para ambulância próxima
          local veh = GetClosestVehicle(pos.x, pos.y, pos.z, 4.0, 0, 70)
          if veh ~= 0 and DoesEntityExist(veh) and GetEntityModel(veh) == GetHashKey('ambulance') then
            QBCore.Functions.DrawText3D(pos.x, pos.y, pos.z+1.1, '[E] Carregar na ambulância')
            if IsControlJustReleased(0, 38) then
              DetachEntity(carriedPed, true, true)
              DeleteEntity(carriedPed)
              carrying = false
              carriedPed = nil
              TriggerServerEvent('pt-firefighters:server:dropVictim')
              QBCore.Functions.Notify('Vítima carregada na ambulância.', 'success')
            end
          end
      end
    end
  end
end)

-- Propagação simples de incêndio em casa (timer) – pode ser tornada mais sofisticada depois
CreateThread(function()
  while true do
    Wait(5000)
    if active and active.kind == 'house' and #fires > 0 then
      -- chance pequena de novo foco perto
      if math.random() < 0.35 then
        local ox = math.random(-2,2) + 0.0
        local oy = math.random(-2,2) + 0.0
        local loc = active.location
        local h = StartScriptFire(loc.x + ox, loc.y + oy, loc.z, 25, false)
        table.insert(fires, h)
        -- fumo
        UseParticleFxAssetNextCall('core')
        local fx = StartParticleFxLoopedAtCoord('ent_amb_smoke_factory', loc.x + ox, loc.y + oy, loc.z+1.0, 0.0,0.0,0.0, 1.0, false, false, false, false)
        table.insert(smokeFx, fx)
        QBCore.Functions.Notify('O fogo está a alastrar! Acelera o combate.', 'error')
      end
    end
  end
end)
