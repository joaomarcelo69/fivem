local function getQB()
  if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
    return exports['qb-core']:GetCoreObject()
  elseif GetCoreObject then
    return GetCoreObject()
  end
end

local QBCore = getQB()

local SAVE_FILE = 'warehouse.json'
local function loadJson(name)
  local raw = LoadResourceFile(GetCurrentResourceName(), name)
  if not raw or raw == '' then return {} end
  local ok, data = pcall(function() return json.decode(raw) end)
  if ok and data then return data end
  return {}
end
local function saveJson(name, tbl)
  SaveResourceFile(GetCurrentResourceName(), name, json.encode(tbl), -1)
end

local Warehouse = loadJson(SAVE_FILE) 

local function addWarehouse(sku, count)
  Warehouse[sku] = (Warehouse[sku] or 0) + (count or 0)
  saveJson(SAVE_FILE, Warehouse)
end

local function takeWarehouse(sku, count)
  count = math.floor(count or 0)
  if count <= 0 then return false end
  local have = Warehouse[sku] or 0
  if have < count then return false end
  Warehouse[sku] = have - count
  saveJson(SAVE_FILE, Warehouse)
  return true
end

local function getProductBySku(sku)
  for _, p in ipairs(LogiConfig.Products or {}) do if p.sku == sku then return p end end
  return nil
end

RegisterNetEvent('pt-logistics:import')
AddEventHandler('pt-logistics:import', function(hubId, sku, units)
  local src = source
  local P = QBCore.Functions.GetPlayer(src)
  if not P then return end
  local product = getProductBySku(sku)
  if not product then
    TriggerClientEvent('QBCore:Notify', src, 'SKU inválido.', 'error')
    return
  end
  local cap = LogiConfig.VehicleCapacity.truck
  units = math.min(math.floor(units or cap), cap)
  addWarehouse(sku, units)
  TriggerClientEvent('QBCore:Notify', src, ('Descarga no armazém: +%d %s'):format(units, product.label), 'success')
end)

RegisterNetEvent('pt-logistics:createRoute')
AddEventHandler('pt-logistics:createRoute', function(shopId, sku, vehicleType)
  local src = source
  local P = QBCore.Functions.GetPlayer(src)
  if not P then return end
  local product = getProductBySku(sku)
  if not product then return TriggerClientEvent('QBCore:Notify', src, 'SKU inválido.', 'error') end
  local capacity = LogiConfig.VehicleCapacity[vehicleType or 'van'] or LogiConfig.VehicleCapacity.van
  local units = math.min(capacity, Warehouse[sku] or 0)
  if units <= 0 then return TriggerClientEvent('QBCore:Notify', src, 'Sem stock no armazém.', 'error') end
  if not takeWarehouse(sku, units) then return TriggerClientEvent('QBCore:Notify', src, 'Falha a reservar stock.', 'error') end
  
  local dock
  if GetResourceState('pt-shops') == 'started' then
    local shops = {}
    pcall(function() shops = exports['pt-shops']:GetShops() end)
    for _, s in ipairs(shops or {}) do if s.id == shopId then dock = s.dock or s.coords break end end
  end
  TriggerClientEvent('pt-logistics:route', src, { shopId=shopId, sku=sku, units=units, vehicleType=vehicleType or 'van', dock=dock })
end)

RegisterNetEvent('pt-logistics:deliver')
AddEventHandler('pt-logistics:deliver', function(payload)
  local src = source
  local P = QBCore.Functions.GetPlayer(src)
  if not P then return end
  local shopId, sku, units = payload.shopId, payload.sku, payload.units
  local product = getProductBySku(sku)
  if not product then return end
  if GetResourceState('pt-shops') ~= 'started' then
    TriggerClientEvent('QBCore:Notify', src, 'Lojas indisponíveis.', 'error')
    addWarehouse(sku, units) 
    return
  end
  
  for _, y in ipairs(product.yields or {}) do
    local total = math.floor((y.count or 0) * (units / (LogiConfig.VehicleCapacity.van))) 
    if total > 0 then
      pcall(function() exports['pt-shops']:RestockShop(shopId, y.item, total) end)
    end
  end
  
  local basePay = 250
  local perUnit = 0.5
  local pay = math.floor(basePay + (perUnit * units))
  P.Functions.AddMoney('bank', pay, 'pt-logistics-delivery')
  TriggerClientEvent('QBCore:Notify', src, ('Entrega concluída. Recebeste %d€'):format(pay), 'success')
end)

QBCore.Functions.CreateCallback('pt-logistics:warehouse', function(_, cb)
  local out = {}
  for sku, amount in pairs(Warehouse or {}) do
    local product = getProductBySku(sku)
    out[#out+1] = { label = (product and product.label) or sku, amount = amount }
  end
  cb(out)
end)

RegisterNetEvent('pt-logistics:reqShopCoords')
AddEventHandler('pt-logistics:reqShopCoords', function(shopId)
  local src = source
  if GetResourceState('pt-shops') ~= 'started' then return end
  local shops = {}
  pcall(function() shops = exports['pt-shops']:GetShops() end)
  for _, s in ipairs(shops or {}) do
    if s.id == shopId then
      TriggerClientEvent('pt-logistics:shopCoords', src, s)
      break
    end
  end
end)

RegisterNetEvent('pt-logistics:dashboard')
AddEventHandler('pt-logistics:dashboard', function()
  local src = source
  if GetResourceState('pt-shops') ~= 'started' then return end
  local shops = {}
  pcall(function() shops = exports['pt-shops']:GetShops() end)
  table.sort(shops, function(a,b)
    local ta = a.lastDelivery or 0
    local tb = b.lastDelivery or 0
    return ta < tb
  end)
  for _, s in ipairs(shops or {}) do
    local ago = (os.time() - (s.lastDelivery or 0))
    TriggerClientEvent('chat:addMessage', src, { args = { '^3[Logística]', string.format('%s (%s) - última entrega há %d segs', s.label or s.id, s.id, ago) } })
  end
  TriggerClientEvent('QBCore:Notify', src, 'Dashboard enviado para o chat. Usa /logi:dashboard de novo quando precisares.', 'primary')
end)

CreateThread(function()
  while true do
    Wait((LogiConfig.NPC and LogiConfig.NPC.checkIntervalSeconds or 120) * 1000)
    if GetResourceState('pt-shops') ~= 'started' then goto continue end
    local shops = {}
    local products = LogiConfig.Products or {}
    pcall(function() shops = exports['pt-shops']:GetShops() end)
    for _, s in ipairs(shops or {}) do
      local needs = false
      
      local last = s.lastDelivery or 0
      local age = os.time() - last
      if age >= (LogiConfig.NPC and LogiConfig.NPC.minLastDeliverySeconds or 1800) then
        needs = true
      end
      
      for _, p in ipairs(products) do
        for _, y in ipairs(p.yields or {}) do
          local min = (LogiConfig.MinStock and LogiConfig.MinStock[y.item]) or 0
          if min > 0 then
            local cnt = 0
            pcall(function() cnt = exports['pt-shops']:GetShopStock(s.id, y.item) end)
            if cnt < min then needs = true break end
          end
        end
        if needs then break end
      end
      if needs then
        
        for _, p in ipairs(products) do
          local have = Warehouse[p.sku] or 0
          if have > 0 then
            
            local units = math.min(have, LogiConfig.VehicleCapacity.van)
            takeWarehouse(p.sku, units)
            for _, y in ipairs(p.yields or {}) do
              local total = math.floor((y.count or 0) * (units / (LogiConfig.VehicleCapacity.van)))
              if total > 0 then
                pcall(function() exports['pt-shops']:RestockShop(s.id, y.item, total) end)
              end
            end
            break
          end
        end
      end
    end
    ::continue::
  end
end)
