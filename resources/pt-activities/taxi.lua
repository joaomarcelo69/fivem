local QBCore = exports['qb-core']:GetCoreObject()

local active = false
local blip = nil
local pedModel = 'a_m_y_business_01'

local function loadModel(model)
  local hash = type(model) == 'number' and model or GetHashKey(model)
  RequestModel(hash)
  local tries = 0
  while not HasModelLoaded(hash) and tries < 200 do Wait(10) tries = tries + 1 end
  return hash
end

local function randomDest()
  local choices = {
    vector3(-1034.6, -2732.6, 13.8), -- LSIA
    vector3(255.1, -375.9, 44.1),    -- Tribunal
    vector3(-516.7, -257.0, 35.6),   -- Weazel
    vector3(185.0, -1016.0, 29.4),   -- Comissaria
    vector3(-709.0, -911.0, 19.2)    -- Alta
  }
  return choices[math.random(#choices)]
end

RegisterCommand('taxi_npc', function()
  if active then QBCore.Functions.Notify('Já tens uma corrida ativa.', 'error') return end
  local veh = GetVehiclePedIsIn(PlayerPedId(), false)
  if veh == 0 or GetVehicleClass(veh) ~= 8 and GetVehicleClass(veh) ~= 0 and GetVehicleClass(veh) ~= 1 and GetVehicleClass(veh) ~= 2 then
    QBCore.Functions.Notify('Precisas de um táxi ou veículo de passageiros.', 'error')
    return
  end
  local hash = loadModel(pedModel)
  if not hash then QBCore.Functions.Notify('Falha ao carregar passageiro.', 'error') return end
  local pos = GetEntityCoords(PlayerPedId())
  local p = CreatePed(4, hash, pos.x + 2.0, pos.y, pos.z, 0.0, true, true)
  TaskEnterVehicle(p, veh, -1, 2, 1.0, 1, 0)
  local dest = randomDest()
  if blip then RemoveBlip(blip) end
  blip = AddBlipForCoord(dest.x, dest.y, dest.z)
  SetBlipRoute(blip, true)
  QBCore.Functions.Notify('Leva o passageiro ao destino marcado.', 'success')
  active = true

  CreateThread(function()
    while active do
      Wait(1000)
      local d = #(GetEntityCoords(PlayerPedId()) - dest)
      if d < 15.0 then
        TaskLeaveVehicle(p, veh, 0)
        Wait(1500)
        if blip then RemoveBlip(blip) blip = nil end
        DeleteEntity(p)
        active = false
        TriggerServerEvent('pt-activities:server:reward', 'taxi')
        break
      end
    end
  end)
end)
