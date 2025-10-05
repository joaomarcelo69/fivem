local QBCore = exports['qb-core']:GetCoreObject()

-- Fallback DrawText3D caso não exista
if not QBCore.Functions.DrawText3D then
  QBCore.Functions.DrawText3D = function(x, y, z, text)
    SetDrawOrigin(x, y, z, 0)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 215)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
  end
end

local function getClosestPlayer()
  local players = QBCore.Functions.GetPlayersFromCoords()
  local closest, dist = -1, 999999
  local myCoords = GetEntityCoords(PlayerPedId())
  for i=1,#players do
    local pid = players[i]
    if pid ~= PlayerId() then
      local ped = GetPlayerPed(pid)
      local coords = GetEntityCoords(ped)
      local d = #(coords - myCoords)
      if d < dist then
        closest = pid
        dist = d
      end
    end
  end
  return closest, dist
end

-- Comando STOP: verificar documentos do veículo do jogador mais próximo
RegisterCommand('stopdocs', function()
  local pid, dist = getClosestPlayer()
  if pid == -1 or dist > 5.0 then QBCore.Functions.Notify('Sem cidadão por perto.', 'error') return end
  TriggerServerEvent('pt-vehicle-docs:requestDocs', GetPlayerServerId(pid))
end)

-- Marcadores para postos (seguro/inspeção) e interação
CreateThread(function()
  while true do
    Wait(0)
    if not VehicleDocsConfig or not VehicleDocsConfig.Offices then goto continue end
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    for k, pos in pairs(VehicleDocsConfig.Offices) do
      local v = vector3(pos.x+0.0, pos.y+0.0, pos.z+0.0)
      local dist = #(pcoords - v)
      if dist < 30.0 then
        DrawMarker(1, v.x, v.y, v.z-1.0, 0.0,0.0,0.0, 0.0,0.0,0.0, 1.0,1.0,0.5, 50,150,255, 120, false, true, 2, nil, nil, false)
        if dist < 2.0 then
          local label = (k == 'insuranceOffice') and 'Renovar Seguro (E)' or ((k == 'inspectionCenter') and 'Fazer Inspeção (E)' or 'Atendimento (E)')
          QBCore.Functions.DrawText3D(v.x, v.y, v.z, label)
          if IsControlJustReleased(0, 38) then -- E
            if k == 'insuranceOffice' then
              ExecuteCommand('renovarseguro')
            elseif k == 'inspectionCenter' then
              ExecuteCommand('renovarinspecao')
            end
          end
        end
      end
    end
    ::continue::
  end
end)

RegisterNetEvent('pt-vehicle-docs:showDocs')
AddEventHandler('pt-vehicle-docs:showDocs', function(data)
  -- data: { ownerCid, plate, insurance = { valid, expiresAt }, inspection = { valid, expiresAt } }
  local msg = ("Matrícula %s | Seguro: %s | Inspeção: %s"):format(
    tostring(data.plate or 'N/A'),
    data.insurance and (data.insurance.valid and ('Válido até '..(data.insurance.expiresAt or '?')) or 'Em falta/expirado') or 'N/A',
    data.inspection and (data.inspection.valid and ('Válida até '..(data.inspection.expiresAt or '?')) or 'Em falta/expirada') or 'N/A'
  )
  QBCore.Functions.Notify(msg, (data.insurance and data.insurance.valid) and ((data.inspection and data.inspection.valid) and 'success' or 'error') or 'error')
end)

-- Valet: oferta após levantamento da apreensão
local pendingValetPlate = nil
RegisterNetEvent('pt-vehicle-docs:client:offerValet', function(plate)
  pendingValetPlate = plate
  SetNuiFocus(true, true)
  SendNUIMessage({ action = 'valet:open', plate = plate })
end)

RegisterNUICallback('valet:accept', function(_, cb)
  if pendingValetPlate then
    TriggerServerEvent('pt-vehicle-docs:server:startValet', pendingValetPlate)
  end
  SetNuiFocus(false, false)
  SendNUIMessage({ action = 'valet:close' })
  pendingValetPlate = nil
  cb(true)
end)

RegisterNUICallback('valet:decline', function(_, cb)
  QBCore.Functions.Notify('Valet cancelado.', 'error')
  SetNuiFocus(false, false)
  SendNUIMessage({ action = 'valet:close' })
  pendingValetPlate = nil
  cb(true)
end)

-- Utilitário: carregar modelo
local function loadModel(model)
  local hash = type(model) == 'number' and model or GetHashKey(model)
  if not IsModelValid(hash) then return nil end
  RequestModel(hash)
  local tries = 0
  while not HasModelLoaded(hash) and tries < 200 do Wait(10) tries = tries + 1 end
  if not HasModelLoaded(hash) then return nil end
  return hash
end

-- Spawna um ped condutor com veículo base e dirige até ao jogador, entregando o carro
RegisterNetEvent('pt-vehicle-docs:client:spawnValet', function(plate, props, depot, valetCfg)
  local pedModel = loadModel(valetCfg.pedModel or 's_m_y_cop_01')
  if not pedModel then QBCore.Functions.Notify('Falha ao carregar modelo do condutor.', 'error') return end
  local vehModel = props and props.model or 'police'
  local vehHash = loadModel(vehModel)
  if not vehHash then QBCore.Functions.Notify('Falha ao carregar viatura.', 'error') return end
  local veh = CreateVehicle(vehHash, depot.x, depot.y, depot.z, depot.h or 0.0, true, false)
  SetVehicleOnGroundProperly(veh)
  SetVehicleDirtLevel(veh, 0.0)
  SetEntityAsMissionEntity(veh, true, true)
  if props then
    if QBCore.Functions.SetVehicleProperties then
      QBCore.Functions.SetVehicleProperties(veh, props)
    else
      SetVehicleNumberPlateText(veh, plate)
    end
  else
    SetVehicleNumberPlateText(veh, plate)
  end
  local driver = CreatePedInsideVehicle(veh, 26, pedModel, -1, true, true)
  SetEntityAsMissionEntity(driver, true, true)
  SetDriverAbility(driver, 1.0)
  SetDriverAggressiveness(driver, 0.0)
  SetBlockingOfNonTemporaryEvents(driver, true)
  SetPedKeepTask(driver, true)
  SetVehicleEngineOn(veh, true, true, false)
  local dest = GetEntityCoords(PlayerPedId())
  TaskVehicleDriveToCoordLongrange(driver, veh, dest.x, dest.y, dest.z, valetCfg.driveSpeed or 18.0, valetCfg.drivingStyle or 786603, 5.0)

  -- Monitorizar chegada
  CreateThread(function()
    local timeout = (valetCfg.timeoutSec or 180)
    local arrived = false
    while timeout > 0 do
      Wait(1000)
      timeout = timeout - 1
      local d = #(GetEntityCoords(veh) - GetEntityCoords(PlayerPedId()))
      if d <= (valetCfg.arrivalDist or 12.0) then
        arrived = true
        break
      end
    end
    if not arrived then
      QBCore.Functions.Notify('Valet cancelado (tempo esgotado).', 'error')
      -- cleanup
      if DoesEntityExist(driver) then DeleteEntity(driver) end
      if DoesEntityExist(veh) then DeleteVehicle(veh) end
      return
    end
    -- Entrega: condutor sai e passa a chave (RP)
    TaskLeaveVehicle(driver, veh, 0)
    Wait(1500)
    SetPedAsNoLongerNeeded(driver)
    QBCore.Functions.Notify(('O veículo %s foi-lhe entregue.'):format(plate), 'success')
    -- Email a indicar chegada
    TriggerServerEvent('qb-phone:server:sendNewMail', {
      sender = 'Parque Apreensões',
      subject = ('Veículo entregue: %s'):format(plate),
      message = 'Obrigado pela sua espera. Qualquer anomalia reporte às autoridades.',
      button = {}
    })
  end)
end)
