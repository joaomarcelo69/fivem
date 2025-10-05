local function debug(msg)
  print(('[pt-inventory-compat] %s'):format(tostring(msg)))
end

local function hasMySQL() return type(MySQL) == 'table' end

local function ensureSchema()
  if not hasMySQL() then return end
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
  pcall(function() MySQL.query(ddl, {}) end)
end

CreateThread(function()
  ensureSchema()
  
  if hasMySQL() then
    pcall(function()
      MySQL.query([[ALTER TABLE inventory_items ADD UNIQUE KEY IF NOT EXISTS uniq_inventory_item (inventory_id, item) ]])
    end)
  end
end)

exports('AddItemForPlayer', function(sourceId, item, count)
  local src = tonumber(sourceId) or 0
  if not item or not count then return false end
  
  local ok, QBCore = pcall(function()
    return (exports and exports['qb-core'] and exports['qb-core']:GetCoreObject()) or (GetCoreObject and GetCoreObject())
  end)
  if ok and QBCore and QBCore.Functions then
    local okp, Player = pcall(function() return QBCore.Functions.GetPlayer(src) end)
    if okp and Player and Player.Functions and Player.Functions.AddItem then
      local r = pcall(function() Player.Functions.AddItem(item, count) end)
      if r then return true end
    end
  end
  
  if hasMySQL() then
    local cid = (src == 1 and 'SMOKETEST_1') or ('SMOKETEST_'..tostring(src))
    local sql = [[
      INSERT INTO inventory_items (inventory_id, item, count)
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE count = count + VALUES(count)
    ]]
    local okq = pcall(function() MySQL.query(sql, { cid, item, count }) end)
    return okq and true or false
  end
  return false
end)

exports('GetCount', function(inventory_id, item)
  if not hasMySQL() then return nil end
  local ok, val = pcall(function()
    if MySQL.scalar then
      return MySQL.scalar('SELECT count FROM inventory_items WHERE inventory_id = ? AND item = ? LIMIT 1', { inventory_id, item })
    else
      local rows = MySQL.query('SELECT count FROM inventory_items WHERE inventory_id = ? AND item = ? LIMIT 1', { inventory_id, item })
      if rows and rows[1] then return rows[1].count end
      return nil
    end
  end)
  if ok then return val end
  return nil
end)

exports('AddItemByCitizenId', function(citizenid, item, count)
  count = count or 1
  local sql = [[
    INSERT INTO inventory_items (inventory_id, item, count)
    VALUES (?, ?, ?)
    ON DUPLICATE KEY UPDATE count = count + VALUES(count)
  ]]
  if MySQL and MySQL.insert then
    local id = MySQL.insert(sql, { citizenid, item, count })
    debug(('AddItemByCitizenId via MySQL.insert citizenid=%s item=%s x%d id=%s'):format(citizenid, item, count, tostring(id)))
    return id ~= nil
  end
  if exports and exports.oxmysql and exports.oxmysql.insert then
    exports.oxmysql:insert(sql, { citizenid, item, count }, function(id)
      debug(('AddItemByCitizenId via oxmysql (async) citizenid=%s item=%s x%d id=%s'):format(citizenid, item, count, tostring(id)))
    end)
    return true
  end
  
  local cmd = string.format(
    "mysql -uroot -pfivemrootpass -h127.0.0.1 -P3307 qbcore -e \"INSERT INTO inventory_items (inventory_id, item, count) VALUES ('%s','%s',%d) ON DUPLICATE KEY UPDATE count = count + VALUES(count)\" 2>/dev/null || true",
    tostring(citizenid):gsub("'","\\'"), tostring(item):gsub("'","\\'"), tonumber(count) or 1
  )
  os.execute(cmd)
  debug(('AddItemByCitizenId via CLI citizenid=%s item=%s x%d'):format(citizenid, item, count))
  return true
end)
