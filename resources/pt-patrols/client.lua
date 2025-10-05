local QBCore = exports['qb-core']:GetCoreObject()

local active = nil
local idx = 0
local blip = nil

local function isJobAllowed(allowed)
  local p = QBCore.Functions.GetPlayerData()
  local j = p and p.job and p.job.name or ''
  for _, name in ipairs(allowed or {}) do
    if j == name then return true end
  end
  return false
end

local function setPoint(point)
  if blip then RemoveBlip(blip) end
  blip = AddBlipForCoord(point.x, point.y, point.z)
  SetBlipRoute(blip, true)
end

local function openPatrolMenu()
  local options = {}
  for key, route in pairs(PatrolsConfig.routes or {}) do
    if isJobAllowed(route.job) then
      table.insert(options, { title = route.label, description = ('Checkpoints: %d | Recompensa: %d€'):format(#route.points, route.reward or 0), onSelect = function()
        active = key
        idx = 1
        setPoint(route.points[idx])
        QBCore.Functions.Notify('Ronda iniciada: '..route.label, 'success')
      end })
    end
  end
  if lib and lib.registerContext and lib.showContext then
    lib.registerContext({ id = 'pt_patrols_menu', title = 'Rondas', options = options })
    lib.showContext('pt_patrols_menu')
  else
    if #options == 0 then QBCore.Functions.Notify('Sem rondas disponíveis para o teu job.', 'error') return end
    -- fallback: inicia a primeira disponível
    options[1].onSelect()
  end
end

RegisterCommand('patrolmenu', openPatrolMenu)
RegisterKeyMapping('patrolmenu', 'Menu de Rondas (PSP/GNR/PJ/INEM)', 'keyboard', 'F7')

CreateThread(function()
  while true do
    Wait(0)
    if active then
      local route = PatrolsConfig.routes[active]
      if not route then active = nil end
      local ped = PlayerPedId()
      local pos = GetEntityCoords(ped)
      local target = route.points[idx]
      DrawMarker(1, target.x, target.y, target.z-1.0, 0,0,0, 0,0,0, 1.5,1.5,0.7, 0,125,255, 120, false, true, 2, nil, nil, false)
      if #(pos - target) < (PatrolsConfig.checkpointRadius or 12.0) then
        idx = idx + 1
        if idx > #route.points then
          TriggerServerEvent('pt-patrols:server:finish', active)
          if blip then RemoveBlip(blip) blip = nil end
          active = nil
          QBCore.Functions.Notify('Ronda concluída. Bom trabalho!', 'success')
        else
          setPoint(route.points[idx])
          QBCore.Functions.Notify(('Checkpoint %d/%d'):format(idx, #route.points), 'primary')
        end
      end
    end
  end
end)
