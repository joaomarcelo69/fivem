local function log(msg)
  print(('[pt-multas] %s'):format(msg))
end

local function ensure_schema()
  local ddl = [[
    CREATE TABLE IF NOT EXISTS fines (
      id INT AUTO_INCREMENT PRIMARY KEY,
      citizenid VARCHAR(64) NOT NULL,
      officer VARCHAR(64) NULL,
      reason VARCHAR(255) NOT NULL,
      amount INT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      KEY idx_citizen (citizenid)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]]
  if MySQL and MySQL.query then
    pcall(function() MySQL.query(ddl) end)
  elseif exports and exports.oxmysql and exports.oxmysql.execute then
    exports.oxmysql:execute(ddl)
  else
    os.execute("mysql -uroot -pfivemrootpass -h127.0.0.1 -P3307 qbcore -e \""..ddl:gsub('"','\\"').."\" 2>/dev/null || true")
  end
end

CreateThread(function()
  ensure_schema()
end)

local function get_qb()
  local ok, core = pcall(function()
    if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
      return exports['qb-core']:GetCoreObject()
    elseif GetCoreObject then
      return GetCoreObject()
    end
  end)
  if ok then return core end
  return nil
end

local function charge_player_by_citizenid(citizenid, amount)
  local QBCore = get_qb()
  if QBCore and QBCore.Functions and QBCore.Functions.GetPlayerByCitizenId then
    local ok, Player = pcall(function() return QBCore.Functions.GetPlayerByCitizenId(citizenid) end)
    if ok and Player and Player.Functions and Player.Functions.RemoveMoney then
      local r = pcall(function() Player.Functions.RemoveMoney('bank', amount, 'multa') end)
      return r and true or false
    end
  end
  return false
end

local function insert_fine(citizenid, officer, reason, amount)
  local sql = 'INSERT INTO fines (citizenid, officer, reason, amount) VALUES (?, ?, ?, ?)'
  if MySQL and MySQL.insert then
    local id = MySQL.insert(sql, { citizenid, officer, reason, amount })
    return id
  elseif exports and exports.oxmysql and exports.oxmysql.insert then
    local insertedId = nil
    exports.oxmysql:insert(sql, { citizenid, officer, reason, amount }, function(id) insertedId = id end)
    -- We can't synchronously return the id here; best-effort just return true
    return insertedId or true
  else
    local cmd = string.format("mysql -uroot -pfivemrootpass -h127.0.0.1 -P3307 qbcore -e \"INSERT INTO fines (citizenid, officer, reason, amount) VALUES ('%s','%s','%s',%d)\" 2>/dev/null || true",
      tostring(citizenid):gsub("'","\\'"), tostring(officer or ''):gsub("'","\\'"), tostring(reason or ''):gsub("'","\\'"), tonumber(amount) or 0
    )
    os.execute(cmd)
    -- CLI path doesn’t return id; return true to indicate success
    return true
  end
end

RegisterCommand('multa', function(source, args)
  if source <= 0 then
    print('Uso: /multa <citizenid> <valor> <motivo...>')
    return
  end
  -- Verificar se é polícia via QBCore ou se tem ACE admin
  local allowed = IsPlayerAceAllowed(source, 'command')
  local QBCore = get_qb()
  if not allowed and QBCore and QBCore.Functions then
    local Player = QBCore.Functions.GetPlayer(source)
    if Player and Player.PlayerData and Player.PlayerData.job and Player.PlayerData.job.name == 'police' then
      allowed = true
    end
  end
  if not allowed then
    TriggerClientEvent('chat:addMessage', source, { args = { '^1pt-multas', 'Sem permissão.' } })
    return
  end
  local citizenid = args[1]
  local amount = tonumber(args[2]) or 0
  local reason = table.concat(args, ' ', 3)
  if not citizenid or amount <= 0 or reason == '' then
    TriggerClientEvent('chat:addMessage', source, { args = { '^3pt-multas', 'Uso: /multa <citizenid> <valor> <motivo>' } })
    return
  end
  local charged = charge_player_by_citizenid(citizenid, amount)
  local fineId = insert_fine(citizenid, GetPlayerName(source), reason, amount)
  if fineId then
    -- Record revenue to government
    if exports and exports['pt-fisco'] and exports['pt-fisco'].AddGovRevenue then
      pcall(function() exports['pt-fisco']:AddGovRevenue(amount, 'multa') end)
    end
    -- Create printed ticket item in the citizen's inventory
    local QBCore = get_qb()
    local Player = QBCore and QBCore.Functions.GetPlayerByCitizenId and QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if Player and Player.Functions and Player.Functions.AddItem then
      local info = {
        fine_id = fineId == true and 0 or fineId,
        citizenid = citizenid,
        officer = GetPlayerName(source),
        reason = reason,
        amount = amount,
        issued_at = os.date('%Y-%m-%d %H:%M:%S')
      }
      local ok = pcall(function() Player.Functions.AddItem('talao_multa', 1, false, info, 'fine-issued') end)
      if not ok then log('Falha a adicionar talao_multa ao jogador '..tostring(citizenid)) end
    end
    local msg = string.format('Multa emitida para %s: %d€ — %s%s', citizenid, amount, reason, charged and ' (cobrado no banco)' or '')
    TriggerClientEvent('chat:addMessage', source, { args = { '^2pt-multas', msg } })
    log(msg)
  else
    TriggerClientEvent('chat:addMessage', source, { args = { '^1pt-multas', 'Falha ao registar a multa.' } })
  end
end)

RegisterNetEvent('pt-multas:emitir')
AddEventHandler('pt-multas:emitir', function(citizenid, amount, reason)
  local src = source
  local fineId = insert_fine(citizenid, GetPlayerName(src), reason, amount)
  if fineId then
    if exports and exports['pt-fisco'] and exports['pt-fisco'].AddGovRevenue then
      pcall(function() exports['pt-fisco']:AddGovRevenue(amount, 'multa') end)
    end
    local QBCore = get_qb()
    local Player = QBCore and QBCore.Functions.GetPlayerByCitizenId and QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if Player and Player.Functions and Player.Functions.AddItem then
      local info = {
        fine_id = fineId == true and 0 or fineId,
        citizenid = citizenid,
        officer = GetPlayerName(src),
        reason = reason,
        amount = amount,
        issued_at = os.date('%Y-%m-%d %H:%M:%S')
      }
      pcall(function() Player.Functions.AddItem('talao_multa', 1, false, info, 'fine-issued') end)
    end
    log(('Multa emitida via evento para %s: %d€ — %s'):format(citizenid, amount, reason))
  end
end)

local function fetch_last_fine(citizenid, id)
  local row
  local sql, params
  if id then
    sql = 'SELECT id, citizenid, officer, reason, amount FROM fines WHERE id = ? AND citizenid = ? LIMIT 1'
    params = { tonumber(id), citizenid }
  else
    sql = 'SELECT id, citizenid, officer, reason, amount FROM fines WHERE citizenid = ? ORDER BY id DESC LIMIT 1'
    params = { citizenid }
  end
  if MySQL and MySQL.query then
    local ok, result = pcall(function() return MySQL.query.await(sql, params) end)
    if ok and result and result[1] then row = result[1] end
  elseif exports and exports.oxmysql and exports.oxmysql.executeSync then
    local ok, result = pcall(function() return exports.oxmysql:executeSync(sql, params) end)
    if ok and result and result[1] then row = result[1] end
  end
  return row
end

RegisterCommand('talao', function(source, args)
  if source <= 0 then
    print('Uso: /talao <citizenid> [id_multa]')
    return
  end
  local allowed = IsPlayerAceAllowed(source, 'command')
  local QBCore = get_qb()
  if not allowed and QBCore and QBCore.Functions then
    local Player = QBCore.Functions.GetPlayer(source)
    if Player and Player.PlayerData and Player.PlayerData.job and Player.PlayerData.job.name == 'police' then
      allowed = true
    end
  end
  if not allowed then
    TriggerClientEvent('chat:addMessage', source, { args = { '^1pt-multas', 'Sem permissão.' } })
    return
  end
  local citizenid = args[1]
  local fineId = tonumber(args[2])
  if not citizenid then
    TriggerClientEvent('chat:addMessage', source, { args = { '^3pt-multas', 'Uso: /talao <citizenid> [id_multa]' } })
    return
  end
  local fine = fetch_last_fine(citizenid, fineId)
  if not fine then
    TriggerClientEvent('chat:addMessage', source, { args = { '^1pt-multas', 'Multa não encontrada.' } })
    return
  end
  local Target = QBCore.Functions.GetPlayerByCitizenId(citizenid)
  if not Target then
    TriggerClientEvent('chat:addMessage', source, { args = { '^1pt-multas', 'Cidadão não está online.' } })
    return
  end
  local info = {
    fine_id = fine.id,
    citizenid = citizenid,
    officer = fine.officer or 'Desconhecido',
    reason = fine.reason or 'Motivo não especificado',
    amount = tonumber(fine.amount) or 0,
    issued_at = os.date('%Y-%m-%d %H:%M:%S')
  }
  local ok = pcall(function() Target.Functions.AddItem('talao_multa', 1, false, info, 'fine-reprint') end)
  if ok then
    TriggerClientEvent('chat:addMessage', source, { args = { '^2pt-multas', 'Talão entregue.' } })
  else
    TriggerClientEvent('chat:addMessage', source, { args = { '^1pt-multas', 'Falha ao entregar talão.' } })
  end
end)

-- Event reprint: entrega um talão baseado na última multa (ou id fornecido) sem criar nova entrada
RegisterNetEvent('pt-multas:reprint')
AddEventHandler('pt-multas:reprint', function(citizenid, id)
  local src = source
  local QBCore = get_qb()
  if not QBCore then return end
  -- Permission: console or police sergeant+ (grade >=2)
  if src ~= 0 then
    local Player = QBCore.Functions.GetPlayer(src)
    local lvl = 0
    local isPolice = false
    if Player and Player.PlayerData and Player.PlayerData.job then
      isPolice = (Player.PlayerData.job.name == 'police' or Player.PlayerData.job.type == 'police')
      if Player.PlayerData.job.grade and Player.PlayerData.job.grade.level then
        lvl = tonumber(Player.PlayerData.job.grade.level) or 0
      end
    end
    if not (isPolice and lvl >= 2) then return end
  end
  local fine = fetch_last_fine(citizenid, id)
  if not fine then return end
  local Target = QBCore.Functions.GetPlayerByCitizenId(citizenid)
  if not Target then return end
  local info = {
    fine_id = fine.id,
    citizenid = citizenid,
    officer = fine.officer or 'Desconhecido',
    reason = fine.reason or 'Motivo não especificado',
    amount = tonumber(fine.amount) or 0,
    issued_at = os.date('%Y-%m-%d %H:%M:%S')
  }
  pcall(function() Target.Functions.AddItem('talao_multa', 1, false, info, 'fine-reprint') end)
end)

-- Register the use of the talão item to display its contents in chat
CreateThread(function()
  local QBCore = get_qb()
  if not QBCore or not QBCore.Functions or not QBCore.Functions.CreateUseableItem then return end
  QBCore.Functions.CreateUseableItem('talao_multa', function(source, item)
    local info = (item and item.info) or {}
    local reason = info.reason or 'Motivo não especificado'
    local amount = info.amount or 0
    local officer = info.officer or 'Desconhecido'
    local fineId = info.fine_id or 0
    local issued_at = info.issued_at or ''
    TriggerClientEvent('chat:addMessage', source, {
      template = '<div class="chat-message advert" style="background: linear-gradient(to right, rgba(5, 5, 5, 0.6), #7a6161); display: flex; padding: 6px 10px;"><div style="margin-right: 10px;"><i class="far fa-file-alt" style="height: 100%;"></i><strong> {0}</strong><br> <strong>ID Multa:</strong> {1} <br><strong>Valor:</strong> {2}€ <br><strong>Motivo:</strong> {3} <br><strong>Agente:</strong> {4} <br><strong>Data:</strong> {5}</div></div>',
      args = { 'Talão de Multa', tostring(fineId), tostring(amount), reason, officer, issued_at }
    })
    TriggerClientEvent('pt-multas:client:showTicket', source, info)
  end)
end)

