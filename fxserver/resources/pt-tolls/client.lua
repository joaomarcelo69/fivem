local QBCore = exports['qb-core']:GetCoreObject()

local lastPass = {}

CreateThread(function()
  while true do
    Wait(250)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then goto continue end
    local ppos = GetEntityCoords(ped)
    for i, g in ipairs(TollsConfig.gantries or {}) do
      local pos = vector3(g.x+0.0, g.y+0.0, g.z+0.0)
      local dist = #(ppos - pos)
      if dist < 35.0 then
        DrawMarker(43, pos.x, pos.y, pos.z+4.5, 0,0,0, 0,0,0, 4.0,4.0,1.0, 0,150,255, 40, false, true, 2, nil, nil, false)
      end
      if dist < 8.0 then
        local now = GetGameTimer()
        if not lastPass[i] or (now - lastPass[i]) > (TollsConfig.cooldownSec or 60) * 1000 then
          lastPass[i] = now
          local plate = QBCore.Functions.GetPlate(veh)
          TriggerServerEvent('pt-tolls:server:charge', i, plate)
        end
      end
    end
    ::continue::
  end
end)
