local QBCore = exports['qb-core']:GetCoreObject()

local lastHit = {}

local function vehSpeedKmh()
  local ped = PlayerPedId()
  local veh = GetVehiclePedIsIn(ped, false)
  if veh == 0 then return 0 end
  return math.floor(GetEntitySpeed(veh) * 3.6)
end

CreateThread(function()
  while true do
    Wait(250)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then goto continue end
    local ppos = GetEntityCoords(ped)
    for idx, cam in ipairs(SpeedCamsConfig.cameras or {}) do
      local pos = vector3(cam.x+0.0, cam.y+0.0, cam.z+0.0)
      local dist = #(ppos - pos)
      if dist < 30.0 then
        -- opcional: marker discreto
        DrawMarker(6, pos.x, pos.y, pos.z+1.0, 0,0,0, 0,0,0, 0.6,0.6,0.6, 255,255,255, 40, false, true, 2, nil, nil, false)
      end
      if dist < 15.0 then
        local spd = vehSpeedKmh()
        local limit = (cam.limit or 50) + (SpeedCamsConfig.tolerance or 0)
        if spd > limit then
          local now = GetGameTimer()
          if not lastHit[idx] or (now - lastHit[idx]) > (SpeedCamsConfig.cooldownSec or 90) * 1000 then
            lastHit[idx] = now
            local plate = QBCore.Functions.GetPlate(veh)
            TriggerServerEvent('pt-speedcams:server:overspeed', idx, plate, spd, cam.limit or 50)
          end
        end
      end
    end
    ::continue::
  end
end)
