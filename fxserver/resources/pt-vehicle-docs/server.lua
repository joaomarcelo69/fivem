local QBCore = exports['qb-core']:GetCoreObject()

CreateThread(function()
  local ddl = [[
    CREATE TABLE IF NOT EXISTS vehicle_docs (
      plate VARCHAR(16) PRIMARY KEY,
      owner VARCHAR(64) NOT NULL,
      insurance_exp INT DEFAULT 0,
      inspection_exp INT DEFAULT 0
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]]
  if MySQL and MySQL.query then
    pcall(function() MySQL.query(ddl) end)
  elseif exports and exports.oxmysql and exports.oxmysql.execute then
    exports.oxmysql:execute(ddl)
  end
  local ddl2 = [[
    CREATE TABLE IF NOT EXISTS vehicle_impounds (
      plate VARCHAR(16) PRIMARY KEY,
      owner VARCHAR(64) NOT NULL,
      seized_at INT NOT NULL,
      reason VARCHAR(255) DEFAULT 'Apreensão',
      by_officer VARCHAR(64) DEFAULT NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]]
  if MySQL and MySQL.query then
    pcall(function() MySQL.query(ddl2) end)
  elseif exports and exports.oxmysql and exports.oxmysql.execute then
    exports.oxmysql:execute(ddl2)
  end
end)

local function now()
  return os.time()
end

local function addMonths(ts, months)
  local d = os.date("*t", ts)
  d.month = d.month + months
  return os.time(d)
end

local function fmt(ts)
  if not ts or ts == 0 then return '—' end
  return os.date('%Y-%m-%d', ts)
end

local function upsertDocs(plate, owner, insuranceExp, inspectionExp)
  local sql = [[INSERT INTO vehicle_docs (plate, owner, insurance_exp, inspection_exp)
                VALUES (?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE owner=VALUES(owner), insurance_exp=VALUES(insurance_exp), inspection_exp=VALUES(inspection_exp)]]
  if MySQL and MySQL.update then
    MySQL.update(sql, { plate, owner, insuranceExp, inspectionExp })
  elseif exports and exports.oxmysql and exports.oxmysql.update then
    exports.oxmysql:update(sql, { plate, owner, insuranceExp, inspectionExp })
  end
end

local function getDocs(plate)
  local row
  local sql = 'SELECT plate, owner, insurance_exp, inspection_exp FROM vehicle_docs WHERE plate = ? LIMIT 1'
  if MySQL and MySQL.query then
    local ok, res = pcall(function() return MySQL.query.await(sql, { plate }) end)
    if ok and res and res[1] then row = res[1] end
  elseif exports and exports.oxmysql and exports.oxmysql.scalar then
    local ok, res = pcall(function() return exports.oxmysql:executeSync('SELECT plate, owner, insurance_exp, inspection_exp FROM vehicle_docs WHERE plate = ? LIMIT 1', { plate }) end)
    if ok and res and res[1] then row = res[1] end
  end
  return row
end

local VehicleProps = {}

RegisterNetEvent('pt-vehicle-docs:savePropsAtImpound', function(plate, props)
  if type(plate) ~= 'string' or type(props) ~= 'table' then return end
  VehicleProps[plate] = props
end)

local function impoundUpsert(plate, owner, officerCid, reason)
  local sql = [[INSERT INTO vehicle_impounds (plate, owner, seized_at, reason, by_officer)
                VALUES (?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE owner=VALUES(owner), seized_at=VALUES(seized_at), reason=VALUES(reason), by_officer=VALUES(by_officer)]]
  local nowTs = now()
  if MySQL and MySQL.update then
    MySQL.update(sql, { plate, owner, nowTs, reason or 'Apreensão', officerCid })
  elseif exports and exports.oxmysql and exports.oxmysql.update then
    exports.oxmysql:update(sql, { plate, owner, nowTs, reason or 'Apreensão', officerCid })
  end
end

local function impoundGet(plate)
  local sql = 'SELECT plate, owner, seized_at, reason, by_officer FROM vehicle_impounds WHERE plate = ? LIMIT 1'
  if MySQL and MySQL.query then
    local ok, res = pcall(function() return MySQL.query.await(sql, { plate }) end)
    if ok and res and res[1] then return res[1] end
  elseif exports and exports.oxmysql and exports.oxmysql.execute then
    local ok, res = pcall(function() return exports.oxmysql:executeSync(sql, { plate }) end)
    if ok and res and res[1] then return res[1] end
  end
  return nil
end

local function impoundDelete(plate)
  local sql = 'DELETE FROM vehicle_impounds WHERE plate = ?'
  if MySQL and MySQL.update then
    MySQL.update(sql, { plate })
  elseif exports and exports.oxmysql and exports.oxmysql.update then
    exports.oxmysql:update(sql, { plate })
  end
end

local function getPlayerCid(src)
  local P = QBCore.Functions.GetPlayer(src)
  return P and P.PlayerData and P.PlayerData.citizenid or nil
end

RegisterCommand('seguro', function(source)
  local src = source
  local cid = getPlayerCid(src)
  if not cid then return end
  TriggerClientEvent('QBCore:Notify', src, 'Aproxima-te do teu veículo e usa /renovarseguro ou /renovarinspecao.', 'primary')
end)

local function getPlayerVehiclePlate(src)
  local ped = GetPlayerPed(src)
  local veh = GetVehiclePedIsIn(ped, false)
  if veh == 0 then
    
    local pos = GetEntityCoords(ped)
    local off = GetOffsetFromEntityInWorldCoords(ped, 0.0, 3.0, 0.0)
    local ray = StartShapeTestLosProbe(pos.x, pos.y, pos.z, off.x, off.y, off.z, 10, ped, 7)
    local _, hit, _, _, ent = GetShapeTestResult(ray)
    if hit == 1 and ent ~= 0 and IsEntityAVehicle(ent) then veh = ent end
  end
  if veh == 0 then return nil end
  return QBCore.Functions.GetPlate(veh)
end

RegisterCommand('renovarseguro', function(source)
  local src = source
  local cid = getPlayerCid(src)
  local plate = getPlayerVehiclePlate(src)
  if not plate then TriggerClientEvent('QBCore:Notify', src, 'Aproxime-se do seu veículo.', 'error') return end
  
  local P = QBCore.Functions.GetPlayer(src)
  if not P.Functions.RemoveMoney('bank', 300, 'seguro') then TriggerClientEvent('QBCore:Notify', src, 'Saldo insuficiente.', 'error') return end
  local exp = addMonths(now(), (VehicleDocsConfig and VehicleDocsConfig.insuranceMonths) or 1)
  upsertDocs(plate, cid, exp, (getDocs(plate) or {}).inspection_exp or 0)
  TriggerClientEvent('QBCore:Notify', src, 'Seguro renovado até '..fmt(exp)..'.', 'success')
end)

RegisterCommand('renovarinspecao', function(source)
  local src = source
  local cid = getPlayerCid(src)
  local plate = getPlayerVehiclePlate(src)
  if not plate then TriggerClientEvent('QBCore:Notify', src, 'Aproxime-se do seu veículo.', 'error') return end
  local P = QBCore.Functions.GetPlayer(src)
  if not P.Functions.RemoveMoney('bank', 200, 'inspecao') then TriggerClientEvent('QBCore:Notify', src, 'Saldo insuficiente.', 'error') return end
  local exp = addMonths(now(), (VehicleDocsConfig and VehicleDocsConfig.inspectionMonths) or 2)
  upsertDocs(plate, cid, (getDocs(plate) or {}).insurance_exp or 0, exp)
  TriggerClientEvent('QBCore:Notify', src, 'Inspeção válida até '..fmt(exp)..'.', 'success')
end)

RegisterNetEvent('pt-vehicle-docs:requestDocs')
AddEventHandler('pt-vehicle-docs:requestDocs', function(targetSrc)
  local src = source
  local P = QBCore.Functions.GetPlayer(src)
  if not P or not P.PlayerData or P.PlayerData.job.name ~= 'police' then return end
  local tgt = tonumber(targetSrc)
  if not tgt then return end
  local plate = getPlayerVehiclePlate(tgt)
  local d = plate and getDocs(plate) or nil
  local data = {
    ownerCid = d and d.owner or 'N/D',
    plate = plate or 'N/D',
    insurance = d and { valid = (d.insurance_exp or 0) > now(), expiresAt = fmt(d.insurance_exp) } or { valid=false, expiresAt='—' },
    inspection = d and { valid = (d.inspection_exp or 0) > now(), expiresAt = fmt(d.inspection_exp) } or { valid=false, expiresAt='—' },
  }
  TriggerClientEvent('pt-vehicle-docs:showDocs', src, data)
  
  if d then
    if not data.insurance.valid then TriggerEvent('pt-multas:emitir', d.owner, VehicleDocsConfig.baseFines.noInsurance or 500, 'Falta de seguro') end
    if not data.inspection.valid then TriggerEvent('pt-multas:emitir', d.owner, VehicleDocsConfig.baseFines.noInspection or 300, 'Inspeção em falta') end
  end
end)

QBCore.Functions.CreateCallback('pt-vehicle-docs:getDocsForSrc', function(source, cb, targetSrc)
  local src = source
  local P = QBCore.Functions.GetPlayer(src)
  if not P or not P.PlayerData or not P.PlayerData.job then cb(nil) return end
  if P.PlayerData.job.name ~= 'police' and P.PlayerData.job.name ~= 'psp' and P.PlayerData.job.name ~= 'gnr' and P.PlayerData.job.name ~= 'pj' then cb(nil) return end
  local tgt = tonumber(targetSrc)
  if not tgt then cb(nil) return end
  local plate = getPlayerVehiclePlate(tgt)
  local d = plate and getDocs(plate) or nil
  local data = {
    ownerCid = d and d.owner or 'N/D',
    plate = plate or 'N/D',
    insurance = d and { valid = (d.insurance_exp or 0) > now(), expiresAt = fmt(d.insurance_exp) } or { valid=false, expiresAt='—' },
    inspection = d and { valid = (d.inspection_exp or 0) > now(), expiresAt = fmt(d.inspection_exp) } or { valid=false, expiresAt='—' },
  }
  cb(data)
end)

QBCore.Functions.CreateCallback('pt-vehicle-docs:impoundIfInvalid', function(source, cb, targetSrc)
  local src = source
  local P = QBCore.Functions.GetPlayer(src)
  if not P or not P.PlayerData or not P.PlayerData.job or not P.PlayerData.job.onduty then cb(false, 'Sem permissões') return end
  local j = P.PlayerData.job.name
  if j ~= 'police' and j ~= 'psp' and j ~= 'gnr' and j ~= 'pj' then cb(false, 'Sem permissões') return end
  local tgt = tonumber(targetSrc)
  if not tgt then cb(false, 'Alvo inválido') return end
  local plate = getPlayerVehiclePlate(tgt)
  if not plate then cb(false, 'Sem veículo') return end
  local d = getDocs(plate)
  local okIns = d and (d.insurance_exp or 0) > now()
  local okInsp = d and (d.inspection_exp or 0) > now()
  if okIns and okInsp then
    cb(false, 'Documentos em dia')
    return
  end
  
  local officerCid = P.PlayerData.citizenid
  local owner = (d and d.owner) or 'N/D'
  local reason = (not okIns and not okInsp) and 'Seguro e Inspeção em falta' or (not okIns and 'Seguro em falta' or 'Inspeção em falta')
  impoundUpsert(plate, owner, officerCid, reason)
  
  
  if d then
    if not okIns then TriggerEvent('pt-multas:emitir', d.owner, VehicleDocsConfig.baseFines.noInsurance or 500, 'Falta de seguro') end
    if not okInsp then TriggerEvent('pt-multas:emitir', d.owner, VehicleDocsConfig.baseFines.noInspection or 300, 'Inspeção em falta') end
  end
  cb(true, plate)
end)

RegisterCommand('levantarapreensao', function(source, args)
  local src = source
  local plate = tostring(args[1] or '')
  if plate == '' then TriggerClientEvent('QBCore:Notify', src, 'Uso: /levantarapreensao [MATRICULA]', 'error') return end
  local rec = impoundGet(plate)
  if not rec then TriggerClientEvent('QBCore:Notify', src, 'Veículo não se encontra apreendido.', 'error') return end
  
  local days = math.max(1, math.floor((now() - (rec.seized_at or now())) / 86400))
  local fee = (VehicleDocsConfig.impound.baseFee or 600) + (days-1) * (VehicleDocsConfig.impound.perDay or 100)
  local P = QBCore.Functions.GetPlayer(src)
  if not P then return end
  if not P.Functions.RemoveMoney('bank', fee, 'impound-release') then
    TriggerClientEvent('QBCore:Notify', src, ('Saldo insuficiente. Taxa: %d€'):format(fee), 'error')
    return
  end
  impoundDelete(plate)
  TriggerClientEvent('QBCore:Notify', src, ('Apreensão levantada. Pago %d€'):format(fee), 'success')
  
  TriggerClientEvent('pt-vehicle-docs:client:offerValet', src, plate)
end)

RegisterNetEvent('pt-vehicle-docs:server:startValet')
AddEventHandler('pt-vehicle-docs:server:startValet', function(plate)
  local src = source
  if type(plate) ~= 'string' or plate == '' then return end
  
  if impoundGet(plate) then
    TriggerClientEvent('QBCore:Notify', src, 'Veículo continua apreendido.', 'error')
    return
  end
  local props = VehicleProps[plate] or { plate = plate, model = 'police' }
  local cfg = VehicleDocsConfig.impound
  TriggerClientEvent('pt-vehicle-docs:client:spawnValet', src, plate, props, cfg.depot, cfg.valet or {})
  
  local P = QBCore.Functions.GetPlayer(src)
  if P and P.PlayerData and P.PlayerData.citizenid then
    TriggerEvent('qb-phone:server:sendNewMail', {
      sender = 'Parque Apreensões',
      subject = ('Valet a caminho: %s'):format(plate),
      message = 'O seu veículo está a caminho. Aguarde no local, por favor.',
      button = {}
    })
  end
end)
