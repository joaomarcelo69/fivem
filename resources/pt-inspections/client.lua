local QBCore = exports['qb-core']:GetCoreObject()

CreateThread(function()
  while true do
    Wait(0)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    for _, z in ipairs(InspectionsConfig.zones or {}) do
      local center = vector3(z.x+0.0, z.y+0.0, z.z+0.0)
      local dist = #(pos - center)
      if dist < z.radius + 15.0 then
        DrawMarker(1, center.x, center.y, center.z-1.0, 0,0,0, 0,0,0, z.radius*2.0, z.radius*2.0, 1.0, 0,255,150, 60, false, true, 2, nil, nil, false)
      end
      if dist < z.radius then
        QBCore.Functions.DrawText3D(center.x, center.y, center.z, 'Fiscalização: Carrega [E] para verificação')
        if IsControlJustReleased(0, 38) then
          local veh = GetVehiclePedIsIn(ped, false)
          if veh == 0 then QBCore.Functions.Notify('Precisas de estar num veículo.', 'error') goto cont end
          local plate = QBCore.Functions.GetPlate(veh)
          TriggerServerEvent('pt-inspections:server:check', plate)
        end
      end
      ::cont::
    end
  end
end)
