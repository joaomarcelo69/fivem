local function getQB()
  if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
    return exports['qb-core']:GetCoreObject()
  elseif GetCoreObject then
    return GetCoreObject()
  end
end

local QBCore = getQB()

local SAVE_FILE = 'housing.json'

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

local Owned = loadJson(SAVE_FILE)

local function player(src)
  return QBCore.Functions.GetPlayer(src)
end

local function citizenid(src)
  local p = player(src)
  return p and p.PlayerData.citizenid or nil
end

local function ensureProperty(id)
  if not Owned[id] then Owned[id] = { tenants = {}, keys = {}, pendingIncome = 0 } end
  Owned[id].tenants = Owned[id].tenants or {}
  Owned[id].keys = Owned[id].keys or {}
  Owned[id].pendingIncome = Owned[id].pendingIncome or 0
end

local function countOwnedBy(cid)
  local n = 0
  for _, data in pairs(Owned) do if data.owner == cid then n = n + 1 end end
  return n
end

exports('GetPropertyMailbox', function(propertyId)
  for _, p in ipairs(HousingConfig.Properties or {}) do
    if p.id == propertyId then return p.mailbox end
  end
  return nil
end)

exports('GetPlayerProperties', function(src)
  local cid = type(src)=='string' and src or citizenid(src)
  if not cid then return {} end
  local list = {}
  for pid, data in pairs(Owned) do
    if data.owner == cid or (data.tenants and data.tenants[cid]) then
      table.insert(list, pid)
    end
  end
  return list
end)

RegisterNetEvent('pt-housing:buy')
AddEventHandler('pt-housing:buy', function(propertyId)
  local src = source
  local P = player(src)
  local cid = citizenid(src)
  if not P or not cid then return end
  local prop
  for _, p in ipairs(HousingConfig.Properties or {}) do if p.id==propertyId then prop = p break end end
  if not prop then return end
  
  if countOwnedBy(cid) >= (HousingConfig.MaxOwnedPerPlayer or 999) then
    TriggerClientEvent('QBCore:Notify', src, 'Atingiste o limite de propriedades.', 'error')
    return
  end
  local price = prop.price
  if Owned[propertyId] and Owned[propertyId].listed and Owned[propertyId].listed.type=='sale' then
    price = Owned[propertyId].listed.price
  end
  local removed = P.Functions.RemoveMoney('bank', price, 'pt-housing-buy')
  if not removed then
    TriggerClientEvent('QBCore:Notify', src, 'Saldo insuficiente.', 'error')
    return
  end
  ensureProperty(propertyId)
  
  local prev = Owned[propertyId].owner
  if prev and prev ~= cid and Owned[propertyId].listed and Owned[propertyId].listed.type=='sale' then
    Owned[propertyId].pendingIncome = (Owned[propertyId].pendingIncome or 0) + price
  end
  Owned[propertyId].owner = cid
  Owned[propertyId].listed = nil
  Owned[propertyId].tenants = {}
  Owned[propertyId].keys = {}
  saveJson(SAVE_FILE, Owned)
  
  if prop.mailbox and GetResourceState and GetResourceState('pt-commerce') == 'started' then
    pcall(function()
      exports['pt-commerce']:SetMailboxForCitizen(cid, prop.mailbox)
    end)
  end
  TriggerClientEvent('QBCore:Notify', src, 'Propriedade adquirida.', 'success')
end)

RegisterNetEvent('pt-housing:listForSale')
AddEventHandler('pt-housing:listForSale', function(propertyId, price)
  local src = source
  local P = player(src)
  local cid = citizenid(src)
  if not P or not cid then return end
  local o = Owned[propertyId]
  if not o or o.owner ~= cid then
    TriggerClientEvent('QBCore:Notify', src, 'Não és o proprietário.', 'error')
    return
  end
  P.Functions.RemoveMoney('bank', HousingConfig.ListingFee or 1000, 'pt-housing-listing')
  Owned[propertyId].listed = { type = 'sale', price = tonumber(price) or 0 }
  saveJson(SAVE_FILE, Owned)
  TriggerClientEvent('QBCore:Notify', src, 'Propriedade listada para venda.', 'success')
end)

RegisterNetEvent('pt-housing:listForRent')
AddEventHandler('pt-housing:listForRent', function(propertyId, rentPrice)
  local src = source
  local P = player(src)
  local cid = citizenid(src)
  if not P or not cid then return end
  local o = Owned[propertyId]
  if not o or o.owner ~= cid then
    TriggerClientEvent('QBCore:Notify', src, 'Não és o proprietário.', 'error')
    return
  end
  Owned[propertyId].listed = { type = 'rent', price = tonumber(rentPrice) or 0 }
  saveJson(SAVE_FILE, Owned)
  TriggerClientEvent('QBCore:Notify', src, 'Propriedade listada para arrendamento.', 'success')
end)

RegisterNetEvent('pt-housing:rent')
AddEventHandler('pt-housing:rent', function(propertyId)
  local src = source
  local P = player(src)
  local cid = citizenid(src)
  if not P or not cid then return end
  local o = Owned[propertyId]
  if not o or not o.listed or o.listed.type ~= 'rent' then
    TriggerClientEvent('QBCore:Notify', src, 'Não está para arrendar.', 'error')
    return
  end
  local removed = P.Functions.RemoveMoney('bank', o.listed.price, 'pt-housing-rent')
  if not removed then
    TriggerClientEvent('QBCore:Notify', src, 'Saldo insuficiente.', 'error')
    return
  end
  o.tenants = o.tenants or {}
  local expiry = os.time() + ((HousingConfig.RentPeriodMinutes or 120) * 60)
  o.tenants[cid] = expiry
  
  if o.owner and o.owner ~= cid then
    o.pendingIncome = (o.pendingIncome or 0) + (o.listed.price or 0)
  end
  saveJson(SAVE_FILE, Owned)
  TriggerClientEvent('QBCore:Notify', src, 'Arrendamento ativo.', 'success')
end)

RegisterNetEvent('pt-housing:unlist')
AddEventHandler('pt-housing:unlist', function(propertyId)
  local src = source
  local P = player(src)
  local cid = citizenid(src)
  if not P or not cid then return end
  local o = Owned[propertyId]
  if not o or o.owner ~= cid then
    TriggerClientEvent('QBCore:Notify', src, 'Não és o proprietário.', 'error')
    return
  end
  o.listed = nil
  saveJson(SAVE_FILE, Owned)
  TriggerClientEvent('QBCore:Notify', src, 'Listagem cancelada.', 'success')
end)

RegisterNetEvent('pt-housing:renewRent')
AddEventHandler('pt-housing:renewRent', function(propertyId)
  local src = source
  local P = player(src)
  local cid = citizenid(src)
  if not P or not cid then return end
  local o = Owned[propertyId]
  if not o or not o.listed or o.listed.type ~= 'rent' or not (o.tenants and o.tenants[cid]) then
    TriggerClientEvent('QBCore:Notify', src, 'Não tens arrendamento ativo aqui.', 'error')
    return
  end
  local removed = P.Functions.RemoveMoney('bank', o.listed.price, 'pt-housing-rent-renew')
  if not removed then
    TriggerClientEvent('QBCore:Notify', src, 'Saldo insuficiente.', 'error')
    return
  end
  o.tenants[cid] = (o.tenants[cid] or os.time()) + ((HousingConfig.RentPeriodMinutes or 120) * 60)
  if o.owner and o.owner ~= cid then
    o.pendingIncome = (o.pendingIncome or 0) + (o.listed.price or 0)
  end
  saveJson(SAVE_FILE, Owned)
  TriggerClientEvent('QBCore:Notify', src, 'Arrendamento renovado.', 'success')
end)

RegisterNetEvent('pt-housing:transfer')
AddEventHandler('pt-housing:transfer', function(propertyId, targetCid)
  local src = source
  local cid = citizenid(src)
  if not cid or not targetCid or targetCid == '' then return end
  local o = Owned[propertyId]
  if not o or o.owner ~= cid then
    TriggerClientEvent('QBCore:Notify', src, 'Não és o proprietário.', 'error')
    return
  end
  ensureProperty(propertyId)
  o.owner = targetCid
  o.listed = nil
  o.tenants = {}
  o.keys = {}
  saveJson(SAVE_FILE, Owned)
  TriggerClientEvent('QBCore:Notify', src, 'Propriedade transferida.', 'success')
end)

RegisterNetEvent('pt-housing:giveKeys')
AddEventHandler('pt-housing:giveKeys', function(propertyId, targetCid)
  local src = source
  local cid = citizenid(src)
  if not cid or not targetCid or targetCid == '' then return end
  local o = Owned[propertyId]
  if not o or o.owner ~= cid then
    TriggerClientEvent('QBCore:Notify', src, 'Não és o proprietário.', 'error')
    return
  end
  ensureProperty(propertyId)
  o.keys[targetCid] = true
  saveJson(SAVE_FILE, Owned)
  TriggerClientEvent('QBCore:Notify', src, 'Chaves atribuídas.', 'success')
end)

RegisterNetEvent('pt-housing:revokeKeys')
AddEventHandler('pt-housing:revokeKeys', function(propertyId, targetCid)
  local src = source
  local cid = citizenid(src)
  if not cid or not targetCid or targetCid == '' then return end
  local o = Owned[propertyId]
  if not o or o.owner ~= cid then
    TriggerClientEvent('QBCore:Notify', src, 'Não és o proprietário.', 'error')
    return
  end
  if o.keys then o.keys[targetCid] = nil end
  saveJson(SAVE_FILE, Owned)
  TriggerClientEvent('QBCore:Notify', src, 'Chaves revogadas.', 'success')
end)

RegisterNetEvent('pt-housing:evictTenant')
AddEventHandler('pt-housing:evictTenant', function(propertyId, targetCid)
  local src = source
  local cid = citizenid(src)
  if not cid or not targetCid or targetCid == '' then return end
  local o = Owned[propertyId]
  if not o or o.owner ~= cid then
    TriggerClientEvent('QBCore:Notify', src, 'Não és o proprietário.', 'error')
    return
  end
  if o.tenants then o.tenants[targetCid] = nil end
  saveJson(SAVE_FILE, Owned)
  TriggerClientEvent('QBCore:Notify', src, 'Inquilino removido.', 'success')
end)

RegisterNetEvent('pt-housing:withdrawIncome')
AddEventHandler('pt-housing:withdrawIncome', function(propertyId)
  local src = source
  local P = player(src)
  local cid = citizenid(src)
  if not P or not cid then return end
  local o = Owned[propertyId]
  if not o or o.owner ~= cid then
    TriggerClientEvent('QBCore:Notify', src, 'Não és o proprietário.', 'error')
    return
  end
  local amount = math.floor(o.pendingIncome or 0)
  if amount <= 0 then
    TriggerClientEvent('QBCore:Notify', src, 'Sem receitas para levantar.', 'error')
    return
  end
  o.pendingIncome = 0
  saveJson(SAVE_FILE, Owned)
  P.Functions.AddMoney('bank', amount, 'pt-housing-withdraw')
  TriggerClientEvent('QBCore:Notify', src, ('%d€ depositados.'):format(amount), 'success')
end)

QBCore.Functions.CreateCallback('pt-housing:list', function(_, cb)
  local props = {}
  for _, p in ipairs(HousingConfig.Properties or {}) do
    local state = Owned[p.id] or {}
    props[#props+1] = { id=p.id, label=p.label, price=p.price, listed=state.listed, owner=state.owner, tenants=state.tenants, keys=state.keys, pendingIncome=state.pendingIncome or 0, entrance=p.entrance, mailbox=p.mailbox }
  end
  cb(props)
end)

exports('CanDecorateAt', function(src, position)
  local cid = citizenid(src)
  if not cid then return false end
  for _, p in ipairs(HousingConfig.Properties or {}) do
    local state = Owned[p.id]
    if state and (state.owner == cid or (state.keys and state.keys[cid]) or (state.tenants and state.tenants[cid] and state.tenants[cid] > os.time())) then
      local dx = position.x - p.entrance.x
      local dy = position.y - p.entrance.y
      local dz = position.z - p.entrance.z
      if (dx*dx + dy*dy + dz*dz) <= (30.0*30.0) then return true end
    end
  end
  return false
end)

exports('HasAccess', function(src, propertyId)
  local cid = citizenid(src)
  if not cid then return false end
  local st = Owned[propertyId]
  if not st then return false end
  if st.owner == cid then return true end
  if st.keys and st.keys[cid] then return true end
  if st.tenants and st.tenants[cid] and st.tenants[cid] > os.time() then return true end
  return false
end)

CreateThread(function()
  while true do
    Wait(10 * 60 * 1000) 
    local now = os.time()
    local changed = false
    for _, st in pairs(Owned) do
      if st.tenants then
        for tcid, expiry in pairs(st.tenants) do
          if expiry <= now then st.tenants[tcid] = nil changed = true end
        end
      end
    end
    if changed then saveJson(SAVE_FILE, Owned) end
  end
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(P)
  local cid = P and P.PlayerData and P.PlayerData.citizenid
  if not cid then return end
  local total = 0
  for _, st in pairs(Owned) do
    if st.owner == cid then total = total + (st.pendingIncome or 0) end
  end
  if total > 0 then
    TriggerClientEvent('QBCore:Notify', P.PlayerData.source, ('Tens %d€ em receitas de propriedades. Usa /housewithdraw <id>.'):format(total), 'primary')
  end
end)
