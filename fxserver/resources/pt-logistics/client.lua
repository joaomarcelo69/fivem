
local QBCore
CreateThread(function()
  if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
    QBCore = exports['qb-core']:GetCoreObject()
  end
end)

RegisterNetEvent('pt-logistics:openPanel', function(payload)
  SetNuiFocus(true, true)
  SendNUIMessage({ type = 'showLogisticsPanel', payload = payload })
end)

RegisterNUICallback('closePanel', function(_, cb)
  SetNuiFocus(false, false)
  SendNUIMessage({ type = 'hideLogisticsPanel' })
  cb({})
end)

RegisterCommand('logi:nui', function()
  QBCore.Functions.TriggerCallback('pt-logistics:warehouse', function(warehouse)
    local routes = {} 
    TriggerEvent('pt-logistics:openPanel', { warehouse = formatWarehouse(warehouse), routes = routes })
  end)
end)

function formatWarehouse(tbl)
  local out = {}
  for sku, amount in pairs(tbl or {}) do
    out[#out+1] = { label = sku, amount = amount }
  end
  return out
end

local function DrawText3D(x, y, z, text)
  SetDrawOrigin(x, y, z, 0)
  SetTextScale(0.35, 0.35)
  SetTextFont(4)
  SetTextProportional(1)
  SetTextColour(255, 255, 255, 215)
  SetTextEntry('STRING')
  SetTextCentre(1)
  AddTextComponentString(text)
  DrawText(0.0, 0.0)
  ClearDrawOrigin()
end

CreateThread(function()
  while true do
    Wait(0)
    local ped = PlayerPedId()
    local p = GetEntityCoords(ped)
    
    for _, h in ipairs(LogiConfig.ImportHubs or {}) do
      local d = #(p - h.coords)
      if d < 25.0 then DrawMarker(1, h.coords.x, h.coords.y, h.coords.z-1.0, 0,0,0, 0,0,0, 1.2,1.2,0.3, 20, 120, 255, 120, false,false,2) end
      if d < 2.0 then
        DrawText3D(h.coords.x, h.coords.y, h.coords.z+0.4, '~b~E~s~ - Importar carga ('..h.label..')')
        if IsControlJustReleased(0, 38) then
          local sku = (LogiConfig.Products[1] and LogiConfig.Products[1].sku) or 'agua_palet'
          
          local t = (LogiConfig.LoadingTimes and LogiConfig.LoadingTimes.import_truck) or 20
          QBCore.Functions.Progressbar('logi_import', 'A descarregar contentores...', t*1000, false, true, { disableMovement=true, disableCarMovement=true, disableMouse=false, disableCombat=true }, {}, {}, {}, function()
            TriggerServerEvent('pt-logistics:import', h.id, sku, LogiConfig.VehicleCapacity.truck)
          end)
          Wait(600)
        end
      end
    end
    
    local w = LogiConfig.Warehouse and LogiConfig.Warehouse.coords
    if w then
      local dw = #(p - w)
      if dw < 25.0 then DrawMarker(1, w.x, w.y, w.z-1.0, 0,0,0, 0,0,0, 1.2,1.2,0.3, 255, 200, 20, 120, false,false,2) end
      if dw < 2.0 then
        DrawText3D(w.x, w.y, w.z+0.4, '~y~E~s~ - Criar rota de distribuição (carrinha)')
        if IsControlJustReleased(0, 38) then
          local sku = (LogiConfig.Products[1] and LogiConfig.Products[1].sku) or 'agua_palet'
          local shopId = 'mercearia_lisboa'
          local t = (LogiConfig.LoadingTimes and LogiConfig.LoadingTimes.route_van) or 12
          QBCore.Functions.Progressbar('logi_load', 'A carregar viatura...', t*1000, false, true, { disableMovement=true, disableCarMovement=true, disableMouse=false, disableCombat=true }, {}, {}, {}, function()
            TriggerServerEvent('pt-logistics:createRoute', shopId, sku, 'van')
          end)
          Wait(600)
        end
      end
    end
  end
end)

RegisterNetEvent('pt-logistics:route', function(route)
  local shopId = route.shopId
  
  local hasGPS = false
  if QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData then
    local pdata = QBCore.Functions.GetPlayerData()
    if pdata and pdata.items then
      for _, it in pairs(pdata.items) do if it and (it.name == 'gps' or it.name == 'phone') and (it.amount or it.count or 1) > 0 then hasGPS = true break end end
    end
  end
  if hasGPS then
    
    TriggerServerEvent('pt-logistics:reqShopCoords', shopId)
    QBCore.Functions.Notify(('Rota criada para %s. Waypoint definido (GPS necessário).'):format(shopId), 'primary')
  else
    QBCore.Functions.Notify('Sem GPS: terás de ir loja a loja verificar necessidades e entregar manualmente.', 'error')
  end
  CreateThread(function()
    local delivered = false
    while not delivered do
      Wait(0)
      
      if route.dock then
        local ped = PlayerPedId(); local p = GetEntityCoords(ped)
        local d = #(p - vector3(route.dock.x, route.dock.y, route.dock.z))
        if d < 25.0 then DrawMarker(1, route.dock.x, route.dock.y, route.dock.z-1.0, 0,0,0, 0,0,0, 1.5,1.5,0.4, 20, 200, 60, 120, false,false,2) end
        if d < 2.5 then
          DrawText3D(route.dock.x, route.dock.y, route.dock.z+0.6, '~g~G~s~ - Entregar mercadoria na doca')
          if IsControlJustReleased(0, 47) then
            TriggerServerEvent('pt-logistics:deliver', route)
            delivered = true
          end
        else
          DrawText3D(p.x, p.y, p.z+0.8, 'Vai para a doca de entrega')
        end
      else
        DrawText3D(GetEntityCoords(PlayerPedId()).x, GetEntityCoords(PlayerPedId()).y, GetEntityCoords(PlayerPedId()).z+0.8, '~g~G~s~ - Confirmar entrega')
        if IsControlJustReleased(0, 47) then
          TriggerServerEvent('pt-logistics:deliver', route)
          delivered = true
        end
      end
    end
  end)
end)

RegisterNetEvent('pt-logistics:shopCoords', function(shop)
  if shop and shop.coords then
    SetNewWaypoint(shop.coords.x + 0.0, shop.coords.y + 0.0)
  end
end)

RegisterCommand('logi:dashboard', function()
  TriggerServerEvent('pt-logistics:dashboard')
end)
