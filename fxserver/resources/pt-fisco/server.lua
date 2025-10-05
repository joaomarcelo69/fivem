local function getQB()
  if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
    return exports['qb-core']:GetCoreObject()
  elseif GetCoreObject then
    return GetCoreObject()
  end
end

local QBCore = getQB()

local Government = { balance = 0 }
local Debts = { byCitizen = {} } 

local function ensure_schema()
  if not FiscoConfig.Enable.Persistencia then return end
  local ddl = [[
    CREATE TABLE IF NOT EXISTS gov_ledger (
      id INT AUTO_INCREMENT PRIMARY KEY,
      amount INT NOT NULL,
      reason VARCHAR(64) NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]]
  if MySQL and MySQL.query then
    pcall(function() MySQL.query(ddl) end)
  elseif exports and exports.oxmysql and exports.oxmysql.execute then
    exports.oxmysql:execute(ddl)
  end
  local ddl2 = [[
    CREATE TABLE IF NOT EXISTS gov_debts (
      id INT AUTO_INCREMENT PRIMARY KEY,
      citizenid VARCHAR(64) NOT NULL,
      dtype VARCHAR(32) NOT NULL,
      amount INT NOT NULL,
      reason VARCHAR(128) NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      paid TINYINT(1) DEFAULT 0
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]]
  if MySQL and MySQL.query then
    pcall(function() MySQL.query(ddl2) end)
  elseif exports and exports.oxmysql and exports.oxmysql.execute then
    exports.oxmysql:execute(ddl2)
  end
end

local function persist(amount, reason)
  if not FiscoConfig.Enable.Persistencia then return end
  local sql = 'INSERT INTO gov_ledger (amount, reason) VALUES (?, ?)'
  if MySQL and MySQL.insert then
    pcall(function() MySQL.insert(sql, { amount, reason }) end)
  elseif exports and exports.oxmysql and exports.oxmysql.insert then
    exports.oxmysql:insert(sql, { amount, reason })
  end
end

local function persistDebt(cid, entry)
  if not FiscoConfig.Enable.Persistencia then return end
  local sql = 'INSERT INTO gov_debts (citizenid, dtype, amount, reason, paid) VALUES (?, ?, ?, ?, 0)'
  if MySQL and MySQL.insert then
    pcall(function() MySQL.insert(sql, { cid, entry.type, entry.amount, entry.reason }) end)
  elseif exports and exports.oxmysql and exports.oxmysql.insert then
    exports.oxmysql:insert(sql, { cid, entry.type, entry.amount, entry.reason })
  end
end

local function addGov(amount, reason)
  amount = math.floor(tonumber(amount) or 0)
  if amount <= 0 then return 0 end
  Government.balance = Government.balance + amount
  TriggerEvent('pt-fisco:gov:changed', Government.balance, reason)
  persist(amount, reason)
  return amount
end

exports('GetGovBalance', function() return Government.balance end)

local function calcIMT(base)
  base = math.floor(tonumber(base) or 0)
  local b = (FiscoConfig.IMT and FiscoConfig.IMT.Brackets) or {}
  for _, row in ipairs(b) do
    if base <= row.upTo then
      return math.floor(base * (row.rate or 0))
    end
  end
  return 0
end

local function calcSelo(base)
  base = math.floor(tonumber(base) or 0)
  local r = (FiscoConfig.ImpostoSelo and FiscoConfig.ImpostoSelo.Rate) or 0
  return math.floor(base * r)
end

local function calcIMIAnnual(base)
  base = math.floor(tonumber(base) or 0)
  local r = (FiscoConfig.IMI and FiscoConfig.IMI.AnnualRate) or 0
  return math.floor(base * r)
end

exports('CalcIMT', calcIMT)
exports('CalcImpostoSelo', calcSelo)
exports('CalcIMIAnnual', calcIMIAnnual)

local function registerDebt(cid, dtype, amount, reason)
  amount = math.floor(tonumber(amount) or 0)
  if amount <= 0 then return nil end
  Debts.byCitizen[cid] = Debts.byCitizen[cid] or {}
  local entry = { id = ('D%s_%d'):format(cid, (#Debts.byCitizen[cid]+1)), type=dtype, amount=amount, reason=reason, createdAt=os.time(), paid=false }
  table.insert(Debts.byCitizen[cid], entry)
  persistDebt(cid, entry)
  return entry
end

exports('RegisterDebt', registerDebt)
exports('GetDebts', function(cid)
  return (Debts.byCitizen[cid] or {})
end)

exports('PayDebt', function(src, debtId)
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player then return false, 'PLAYER_NOT_FOUND' end
  local cid = Player.PlayerData.citizenid
  local list = Debts.byCitizen[cid] or {}
  for _, d in ipairs(list) do
    if d.id == debtId and not d.paid then
      if Player.Functions.RemoveMoney('bank', d.amount, 'pt-fisco-pay-debt') then
        d.paid = true
        addGov(d.amount, d.type)
        return true
      else
        return false, 'NO_FUNDS'
      end
    end
  end
  return false, 'NOT_FOUND'
end)

local function getIVARate(tipo)
  local reg = (FiscoConfig.Regiao or 'continente')
  local cat = (FiscoConfig.IVAMap and FiscoConfig.IVAMap[tipo]) or 'normal'
  local tbl = FiscoConfig.IVACategorias and FiscoConfig.IVACategorias[reg]
  return (tbl and tbl[cat]) or 0.23
end

local function calcIVA(base, tipo)
  if not FiscoConfig.Enable.IVA then return 0 end
  local rate = getIVARate(tipo or 'vendas')
  return math.floor((tonumber(base) or 0) * rate)
end

local function calcIRS(base, tipo)
  if not FiscoConfig.Enable.IRS then return 0 end
  local rate = (FiscoConfig.IRS and FiscoConfig.IRS[tipo]) or 0
  return math.floor((tonumber(base) or 0) * rate)
end

exports('CalcIVA', calcIVA)
exports('CalcIRS', calcIRS)

exports('ApplyIVA', function(total, tipo)
  total = math.floor(tonumber(total) or 0)
  local iva = calcIVA(total, tipo)
  addGov(iva, 'IVA')
  return total, iva
end)

exports('GetIVARate', getIVARate)
exports('ApplyIVAGross', function(grossTotal, tipo)
  local rate = getIVARate(tipo or 'vendas')
  grossTotal = math.floor(tonumber(grossTotal) or 0)
  local iva = math.floor(grossTotal * rate / (1.0 + rate))
  addGov(iva, 'IVA')
  return grossTotal, iva
end)

exports('ApplyIRS', function(src, amount, tipo)
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player then return 0, 0 end
  amount = math.floor(tonumber(amount) or 0)
  local irs = calcIRS(amount, tipo)
  local net = amount - irs
  if net < 0 then net = 0 end
  if irs > 0 then addGov(irs, 'IRS') end
  return net, irs
end)

exports('AddGovRevenue', function(amount, reason)
  return addGov(amount, reason or 'REVENUE')
end)

RegisterCommand('govsaldo', function(src)
  if src == 0 then
    print(('[pt-fisco] Governo: €%d'):format(Government.balance))
    return
  end
  
  if IsPlayerAceAllowed(src, 'command') then
    TriggerClientEvent('chat:addMessage', src, { args = { '^2[Governo]', ('Saldo: €%d'):format(Government.balance) } })
  end
end)

CreateThread(function()
  ensure_schema()
end)
