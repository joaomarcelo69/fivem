local QBCore = exports['qb-core']:GetCoreObject()

local active = false
local blip = nil

local function randomSpot()
  local choices = {
    vector3(180.0, -1736.0, 29.3),
    vector3(-1137.5, -1991.4, 12.2),
    vector3(1209.0, -1402.0, 35.2),
    vector3(-72.2, -819.5, 326.2),
    vector3(806.1, -1062.1, 28.7)
  }
  return choices[math.random(#choices)]
end

RegisterCommand('mec_servico', function()
  if active then QBCore.Functions.Notify('Já tens uma assistência ativa.', 'error') return end
  local dest = randomSpot()
  if blip then RemoveBlip(blip) end
  blip = AddBlipForCoord(dest.x, dest.y, dest.z)
  SetBlipRoute(blip, true)
  QBCore.Functions.Notify('Vai até ao cliente e carrega E para concluir o serviço.', 'success')
  active = true

  CreateThread(function()
    while active do
      Wait(0)
      local ped = PlayerPedId()
      local pos = GetEntityCoords(ped)
      DrawMarker(1, dest.x, dest.y, dest.z-1.0, 0,0,0, 0,0,0, 1.0,1.0,0.5, 255,200,0, 120, false, true, 2, nil, nil, false)
      if #(pos - dest) < 2.0 then
        QBCore.Functions.DrawText3D(dest.x, dest.y, dest.z, 'Carrega [E] para concluir')
        if IsControlJustReleased(0, 38) then
          if blip then RemoveBlip(blip) blip = nil end
          active = false
          TriggerServerEvent('pt-activities:server:reward', 'mec')
        end
      end
    end
  end)
end)
