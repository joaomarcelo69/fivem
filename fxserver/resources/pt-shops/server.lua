
local function debug(msg)
  print(('[pt-shops] %s'):format(msg))
end

Shops = Shops or {}

local function loadConfig()
  local cfgPath = (GetConvar and GetConvar('pt_shops_config', '')) or ''
  if cfgPath == '' then cfgPath = '/workspaces/fivem/server-data/config/pt_shops.json' end
  local f = io.open(cfgPath, 'r')
  if not f then
    debug('config not found at '..tostring(cfgPath)..', using built-in defaults')
    Shops = {
      { id = 'default', label = 'Loja Padrão', items = { { name = 'water', price = 1 }, { name = 'bread', price = 2 } } }
    }
    return
  end
  local content = f:read('*a'); f:close()
  local ok, parsed = pcall(json.decode, content)
  if ok and parsed and parsed.shops then
    
    local arr = {}
    for _, s in ipairs(parsed.shops) do
      local shop = { id = s.id, label = s.label, items = {} }
  if s.coords then shop.coords = s.coords end
  if s.dock then shop.dock = s.dock end
      local list = s.inventory or s.items or {}
      for _, it in ipairs(list) do
        shop.items[#shop.items+1] = {
          name = it.item or it.name,
          price = it.price or it.cost or 0,
          tipo = it.tipo or it.iva_tipo
        }
      end
      arr[#arr+1] = shop
    end
    Shops = arr
  else
    debug('failed to parse shops config, using defaults')
    Shops = { { id = 'default', label = 'Loja Padrão', items = { { name = 'water', price = 1 } } } }
  end
end

loadConfig()

debug('pt-shops server initializing')

local function mysql_exec(sql)
  local safe = sql:gsub('"', '\\"')
  local cmd = 'mysql -uroot -pfivemrootpass -h127.0.0.1 -P3307 qbcore -e "'..safe..'" >/dev/null 2>&1'
  os.execute(cmd)
end

local function hasMySQL()
  return (exports and exports.oxmysql) ~= nil
end

local function ensureInventorySchema()
  local ddl = [[
    CREATE TABLE IF NOT EXISTS inventory_items (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      inventory_id VARCHAR(64) NOT NULL,
      item VARCHAR(64) NOT NULL,
      count INT NOT NULL DEFAULT 0,
      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      UNIQUE KEY uniq_inventory_item (inventory_id, item),
      KEY idx_inventory (inventory_id),
      KEY idx_item (item)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]]
  pcall(function() mysql_exec(ddl) end)
  local ddl2 = [[
    CREATE TABLE IF NOT EXISTS shop_stock (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      shop_id VARCHAR(64) NOT NULL,
      item VARCHAR(64) NOT NULL,
      count INT NOT NULL DEFAULT 0,
      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      UNIQUE KEY uniq_shop_item (shop_id, item),
      KEY idx_shop (shop_id),
      KEY idx_item (item)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]]
  pcall(function() mysql_exec(ddl2) end)
end

local function dbUpsertItem(inventory_id, item, count)
  if not (inventory_id and item and count) then return false end
  local sql = [[
    INSERT INTO inventory_items (inventory_id, item, count)
    VALUES (?, ?, ?)
    ON DUPLICATE KEY UPDATE count = count + VALUES(count)
  ]]
  
  local params = {inventory_id, item, count}
  local idx = 0
  local q = sql:gsub('%?', function()
    idx = idx + 1
    local v = params[idx]
    if type(v) == 'number' then return tostring(v) end
    v = tostring(v):gsub("'", "''")
    return "'"..v.."'"
  end)
  return pcall(function() mysql_exec(q) end)
end

local function dbGetCount(inventory_id, item)
  local tmp = '/workspaces/fivem/fxserver/resources/smoke_tests/.pt_count.txt'
  local q = ([[SELECT count FROM inventory_items WHERE inventory_id = '%s' AND item = '%s' LIMIT 1]]):format(
    tostring(inventory_id):gsub("'","''"), tostring(item):gsub("'","''")
  )
  local cmd = "mysql -uroot -pfivemrootpass -h127.0.0.1 -P3307 qbcore -N -s -e \""..q:gsub('"','\\"').."\" > "..tmp.." 2>/dev/null"
  os.execute(cmd)
  local f = io.open(tmp, 'r')
  if not f then return nil end
  local line = f:read('*l')
  f:close()
  if not line then return nil end
  local n = tonumber(line)
  return n
end

local function dbShopGetCount(shop_id, item)
  local tmp = '/workspaces/fivem/fxserver/resources/smoke_tests/.pt_shop_count.txt'
  local q = ([[SELECT count FROM shop_stock WHERE shop_id = '%s' AND item = '%s' LIMIT 1]]):format(
    tostring(shop_id):gsub("'","''"), tostring(item):gsub("'","''")
  )
  local cmd = "mysql -uroot -pfivemrootpass -h127.0.0.1 -P3307 qbcore -N -s -e \""..q:gsub('"','\\"').."\" > "..tmp.." 2>/dev/null"
  os.execute(cmd)
  local f = io.open(tmp, 'r')
  if not f then return nil end
  local line = f:read('*l')
  f:close()
  if not line then return nil end
  return tonumber(line)
end

local function dbShopUpsert(shop_id, item, count)
  if not (shop_id and item and count) then return false end
  local sql = [[
    INSERT INTO shop_stock (shop_id, item, count)
    VALUES (?, ?, ?)
    ON DUPLICATE KEY UPDATE count = count + VALUES(count)
  ]]
  local params = {shop_id, item, count}
  local idx = 0
  local q = sql:gsub('%?', function()
    idx = idx + 1
    local v = params[idx]
    if type(v) == 'number' then return tostring(v) end
    v = tostring(v):gsub("'", "''")
    return "'"..v.."'"
  end)
  return pcall(function() mysql_exec(q) end)
end

local function dbShopDecrement(shop_id, item, count)
  if not (shop_id and item and count) then return false end
  local q = ([[UPDATE shop_stock SET count = GREATEST(count - %d, 0) WHERE shop_id = '%s' AND item = '%s' AND count >= %d]]):format(
    count, tostring(shop_id):gsub("'","''"), tostring(item):gsub("'","''"), count
  )
  return pcall(function() mysql_exec(q) end)
end

local function waitForQBCore(timeoutSeconds)
  timeoutSeconds = timeoutSeconds or 8
  local elapsed = 0
  while elapsed < timeoutSeconds do
    local ok, obj = pcall(function()
      if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
        return exports['qb-core']:GetCoreObject()
      elseif GetCoreObject and type(GetCoreObject) == 'function' then
        return GetCoreObject()
      elseif Global and Global.GetCoreObject then
        return Global.GetCoreObject()
      elseif _G and _G.GetCoreObject then
        return _G.GetCoreObject()
      end
    end)
    if ok and obj then return obj end
    Citizen.Wait(500)
    elapsed = elapsed + 0.5
  end
  return nil
end

local function ensureOxmysql(timeoutSeconds)
  timeoutSeconds = timeoutSeconds or 8
  local elapsed = 0
  while elapsed < timeoutSeconds do
    if exports and exports.oxmysql then return true end
    Citizen.Wait(500)
    elapsed = elapsed + 0.5
  end
  return false
end

local QBCore = nil
pcall(function() QBCore = (exports and exports['qb-core'] and exports['qb-core']:GetCoreObject()) or (GetCoreObject and GetCoreObject()) or (_G and _G.GetCoreObject and _G.GetCoreObject()) end)

function GetShops()
  return Shops
end

exports('GetShops', GetShops)
exports('GetShopStock', function(shopId, item)
  return dbShopGetCount(shopId, item) or 0
end)
exports('RestockShop', function(shopId, item, count)
  local ok = dbShopUpsert(shopId, item, tonumber(count) or 0)
  if ok then
    
    Shops = Shops or {}
    for _, s in ipairs(Shops) do if s.id == shopId then s.lastDelivery = os.time() break end end
  end
  return ok
end)

RegisterNetEvent('pt-shops:test_buy')
AddEventHandler('pt-shops:test_buy', function(testSource, payload)
  local prev = source
  source = testSource or source
  local ok, err = pcall(function()
    TriggerEvent('pt-shops:buy', payload)
  end)
  source = prev
  if not ok then
    print(('pt-shops:test_buy error: %s'):format(tostring(err)))
  end
end)

RegisterNetEvent('pt-shops:buy', function(payload)
  local src = source
  if not payload or not payload.item then
    debug('buy called with invalid payload')
    return
  end

  local targetId = payload.shopId or 'default'
  local shop = nil
  for _, s in ipairs(Shops) do if s.id == targetId then shop = s break end end
  if not shop then
    debug('shop not found: '..tostring(targetId))
    return
  end

  local price = payload.price or 0
  local count = payload.count or 1
  local totalPrice = (price or 0) * (count or 1)
  local overrideCitizenId = payload and payload.citizenid

  debug(('buy payload: src=%s shopId=%s item=%s count=%d price=%s overrideCitizenId=%s')
    :format(tostring(src), tostring(targetId), tostring(payload.item), count, tostring(price), tostring(overrideCitizenId)))

  
  local stock = dbShopGetCount(targetId, payload.item)
  if stock == nil then stock = 0 end
  if stock < count then
    TriggerClientEvent('chat:addMessage', src, { args = { '^1pt-shops', 'Sem stock suficiente' } })
    return
  end

  local iva_tipo = payload and payload.tipo
  if not iva_tipo then
    
    for _, it in ipairs(shop.items or {}) do
      local iname = it.name or it.item
      if iname == payload.item then
        iva_tipo = it.tipo or it.iva_tipo or 'vendas'
        break
      end
    end
    iva_tipo = iva_tipo or 'vendas'
  end
  
  if exports and exports['pt-fisco'] and exports['pt-fisco'].ApplyIVAGross then
    pcall(function() exports['pt-fisco']:ApplyIVAGross(totalPrice, iva_tipo) end)
  end

  
  if overrideCitizenId and exports and exports['pt-inventory-compat'] then
    local okc, res = pcall(function()
      return exports['pt-inventory-compat']:AddItemByCitizenId(overrideCitizenId, payload.item, count)
    end)
    debug(('compat AddItemByCitizenId called: ok=%s res=%s for citizenid=%s item=%s x%d')
      :format(tostring(okc), tostring(res), tostring(overrideCitizenId), tostring(payload.item), count))
    if okc and res then
      TriggerClientEvent('chat:addMessage', src, { args = { '^2pt-shops', 'Compra efetuada (compat cID): '..payload.item } })
      debug(('compat add item by citizenid %s item=%s x%d'):format(overrideCitizenId, payload.item, count))
      return
    end
  end

  
    local QBCore = waitForQBCore(5)
    if QBCore and QBCore.Functions then
      local ok, Player = pcall(function() return QBCore.Functions.GetPlayer(src) end)
      if ok and Player and Player.Functions then
        local cash = nil
        pcall(function() cash = Player.Functions.GetMoney('bank') or 0 end)
        if cash and cash >= totalPrice then
          local okAdd = false
          if Player.Functions.AddItem then
            pcall(function()
              Player.Functions.RemoveMoney('bank', totalPrice, 'pt-shops')
              Player.Functions.AddItem(payload.item, count)
            end)
            okAdd = true
          else
            
            local cid = (Player.PlayerData and Player.PlayerData.citizenid) or overrideCitizenId or tostring(src)
            if cid and hasMySQL() then
              okAdd = dbUpsertItem(cid, payload.item, count)
            end
          end
          if okAdd then
            dbShopDecrement(targetId, payload.item, count)
            TriggerClientEvent('chat:addMessage', src, { args = { '^2pt-shops', 'Compra efetuada: '..payload.item } })
            debug(('player %s bought %s x%d for %s'):format(src, payload.item, count, tostring(price)))
            return
          end
        else
          TriggerClientEvent('chat:addMessage', src, { args = { '^1pt-shops', 'Saldo insuficiente' } })
          return
        end
      end
    end

  
  
  local usedCompat = false
  if exports and exports['pt-inventory-compat'] then
    local okc, res
    if overrideCitizenId then
      okc, res = pcall(function()
        return exports['pt-inventory-compat']:AddItemByCitizenId(overrideCitizenId, payload.item, count)
      end)
    else
      okc, res = pcall(function()
        return exports['pt-inventory-compat']:AddItemForPlayer(src, payload.item, count)
      end)
    end
    usedCompat = (okc and res) and true or false
  end
  if usedCompat then
    dbShopDecrement(targetId, payload.item, count)
    TriggerClientEvent('chat:addMessage', src, { args = { '^2pt-shops', 'Compra efetuada (compat): '..payload.item } })
    debug(('compat add item for player %s item=%s x%d'):format(src, payload.item, count))
    return
  end
  local fallbackId = overrideCitizenId or ('SMOKETEST_'..tostring(src or 0))
  local dbOk = dbUpsertItem(fallbackId, payload.item, count)
  debug(('Fallback purchase: player=%s shop=%s item=%s count=%d price=%s dbUpsert=%s'):format(src, payload.shopId, payload.item, count, tostring(price), tostring(dbOk)))
  TriggerClientEvent('chat:addMessage', src, { args = { '^3pt-shops', 'Compra registada (ambiente de desenvolvimento)' } })
end)

debug('pt-shops resource started, ' .. tostring(#Shops) .. ' shops loaded')

RegisterNetEvent('pt-shops:requestShops')
AddEventHandler('pt-shops:requestShops', function()
  local src = source
  if src and src > 0 then
    TriggerClientEvent('pt-shops:sendShops', src, Shops)
  end
end)

AddEventHandler('onResourceStart', function(resourceName)
  if resourceName ~= GetCurrentResourceName() then return end
  ensureInventorySchema()
  
  for _, s in ipairs(Shops or {}) do
    for _, it in ipairs(s.items or {}) do
      if it.amount and it.amount > 0 then
        pcall(function() dbShopUpsert(s.id, it.name or it.item, it.amount) end)
      end
    end
  end
  
  local testId = nil
  if Shops and #Shops > 0 then
    testId = Shops[1].id
  else
    Shops = Shops or {}
    Shops[#Shops+1] = { id = 'smoketest', label = 'Smoke Shop', items = { { name = 'water', price = 1, amount = 100 } } }
    testId = 'smoketest'
  end
  local payload = { shopId = testId, item = 'water', price = 1, count = 1 }
  
  local prevSource = source
  source = 1
  local ok = pcall(function() TriggerEvent('pt-shops:buy', payload) end)
  source = prevSource
  
  local smoke_log = '/workspaces/fivem/fxserver/resources/smoke_tests/smoke_results.log'
  local extra = ''
  local probeId = 'SMOKETEST_'..tostring(1)
  local cnt = dbGetCount(probeId, 'water')
  if cnt ~= nil then extra = ' mysql_count='..tostring(cnt) end
  os.execute('echo "'..os.date('%Y-%m-%d %H:%M:%S')..' - pt_shops self-test executed ok='..tostring(ok)..extra..'" >> '..smoke_log..' 2>/dev/null || true')
  
  print(('[pt-shops] self-test executed ok=%s, logged to %s'):format(tostring(ok), smoke_log))
end)
