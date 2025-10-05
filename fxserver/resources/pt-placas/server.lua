local function log(msg)
  print(('[pt-placas] %s'):format(msg))
end

local function ensure_schema()
  local ddl = [[
    CREATE TABLE IF NOT EXISTS vehicle_plates (
      id INT AUTO_INCREMENT PRIMARY KEY,
      plate VARCHAR(16) NOT NULL UNIQUE,
      owner_citizenid VARCHAR(64) NULL,
      model VARCHAR(64) NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]]
  if MySQL and MySQL.query then
    pcall(function() MySQL.query(ddl) end)
  else
    os.execute("mysql -uroot -pfivemrootpass -h127.0.0.1 -P3307 qbcore -e \""..ddl:gsub('"','\\"').."\" 2>/dev/null || true")
  end
end

CreateThread(function()
  ensure_schema()
end)

local letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
local digits = '0123456789'

local function rand_char(pool)
  local i = math.random(1, #pool)
  return pool:sub(i,i)
end

local function format_plate()
  
  return string.format('%s%s-%s%s-%s%s',
    rand_char(letters), rand_char(letters),
    rand_char(digits), rand_char(digits),
    rand_char(letters), rand_char(letters)
  )
end

local function plate_exists(plate)
  if not plate then return false end
  if MySQL and (MySQL.scalar or MySQL.query) then
    if MySQL.scalar then
      local ok, res = pcall(function()
        if MySQL.scalar.await then
          return MySQL.scalar.await('SELECT 1 FROM vehicle_plates WHERE plate = ? LIMIT 1', { plate })
        else
          return MySQL.scalar('SELECT 1 FROM vehicle_plates WHERE plate = ? LIMIT 1', { plate })
        end
      end)
      return ok and (res == 1 or res == '1')
    else
      local rows
      if MySQL.query.await then
        rows = MySQL.query.await('SELECT 1 FROM vehicle_plates WHERE plate = ? LIMIT 1', { plate })
      else
        rows = MySQL.query('SELECT 1 FROM vehicle_plates WHERE plate = ? LIMIT 1', { plate })
      end
      return rows and rows[1] ~= nil
    end
  else
    return false
  end
end

exports('ReservePlate', function(plate, owner_cid, model)
  if not plate then return false end
  ensure_schema()
  local ok = false
  local sql = 'INSERT IGNORE INTO vehicle_plates (plate, owner_citizenid, model) VALUES (?, ?, ?)'
  if MySQL and MySQL.insert then
    local id
    if MySQL.insert.await then
      id = MySQL.insert.await(sql, { plate, owner_cid, model })
    else
      id = MySQL.insert(sql, { plate, owner_cid, model })
    end
    ok = id ~= nil
  else
    local cmd = string.format("mysql -uroot -pfivemrootpass -h127.0.0.1 -P3307 qbcore -e \"INSERT IGNORE INTO vehicle_plates (plate, owner_citizenid, model) VALUES ('%s','%s','%s')\" 2>/dev/null || true",
      tostring(plate):gsub("'","\\'"), tostring(owner_cid or ''):gsub("'","\\'"), tostring(model or ''):gsub("'","\\'"))
    os.execute(cmd)
    ok = true
  end
  if ok then log('reservada placa '..plate) end
  return ok
end)

exports('GeneratePlate', function(owner_cid, model)
  ensure_schema()
  math.randomseed(os.time() + (GetGameTimer and GetGameTimer() or 0))
  for i=1,5 do
    local plate = format_plate()
    if not plate_exists(plate) then
      local ok = exports['pt-placas']:ReservePlate(plate, owner_cid, model)
      if ok then return plate end
    end
  end
  
  local plate = format_plate()
  exports['pt-placas']:ReservePlate(plate, owner_cid, model)
  return plate
end)

RegisterCommand('placa', function(source, args)
  if source ~= 0 and not IsPlayerAceAllowed(source, 'command') then
    return
  end
  local owner = args[1]
  local model = args[2]
  local plate = exports['pt-placas']:GeneratePlate(owner, model)
  if source > 0 then
    TriggerClientEvent('chat:addMessage', source, { args = { '^2pt-placas', 'Placa gerada: '..tostring(plate) } })
  else
    print('[pt-placas] Placa gerada: '..tostring(plate))
  end
end)
