-- Atualizar badge de encomendas no telemóvel
local function setOrdersBadge(citizenid, count)
  -- Usa a API interna do qb-phone para definir alertas por app
  TriggerEvent('qb-phone:server:SetPhoneAlerts', 'orders', count or 0)
  -- Para compatibilidade direta (se qb-phone não expuser eventos), tenta notificar online
  for _, pid in ipairs(QBCore.Functions.GetPlayers()) do
    local PP = QBCore.Functions.GetPlayer(pid)
    if PP and PP.PlayerData and PP.PlayerData.citizenid == citizenid then
      -- O cliente do qb-phone vai puxar o estado atual ao abrir; só garantimos refresh forçando AppData
      TriggerClientEvent('qb-phone:client:RefreshAppAlerts', pid)
      break
    end
  end
end
  if method == 'mailbox' then
    local mb = Mailboxes[citizenid] or {}
    local pendingCount = (mb.pending and #mb.pending) or 0
    setOrdersBadge(citizenid, pendingCount)
  end
end)
            -- Atualizar badge
            local pendingCount = #Mailboxes[o.citizenid].pending
            setOrdersBadge(o.citizenid, pendingCount)
  -- Atualizar badge
  local pendingCount = (Mailboxes[citizenid].pending and #Mailboxes[citizenid].pending) or 0
  setOrdersBadge(citizenid, pendingCount)
local function getQB()
  if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
    return exports['qb-core']:GetCoreObject()
  elseif GetCoreObject then
    return GetCoreObject()
  end
end

local QBCore = getQB()

-- Persistência simples via ficheiros JSON
local ORDERS_FILE = 'orders.json'
local MAILBOX_FILE = 'mailboxes.json'

local function loadJson(name)
  local raw = LoadResourceFile(GetCurrentResourceName(), name)
  if not raw or raw == '' then return {} end
  local ok, data = pcall(function() return json.decode(raw) end)
  if ok and data then return data end
  return {}
end

local function saveJson(name, tbl)
  local raw = json.encode(tbl)
  SaveResourceFile(GetCurrentResourceName(), name, raw, -1)
end

local Orders = loadJson(ORDERS_FILE)
local Mailboxes = loadJson(MAILBOX_FILE)
local DeliveryAttempts = {}

-- Utilitário
local function playerFromSource(src)
  return QBCore and QBCore.Functions.GetPlayer(src) or nil
end

local function ensureCitizenId(src)
  local P = playerFromSource(src)
  return P and P.PlayerData and P.PlayerData.citizenid or nil
end

-- Notificar um cidadão (se online)
local function notifyCitizen(citizenid, msg, t)
  for _, pid in ipairs(QBCore.Functions.GetPlayers()) do
    local PP = QBCore.Functions.GetPlayer(pid)
    if PP and PP.PlayerData and PP.PlayerData.citizenid == citizenid then
      TriggerClientEvent('QBCore:Notify', pid, msg, t or 'primary')
      return true
    end
  end
  return false
end
-- Export para outros recursos: obter mailbox do jogador
exports('GetMailboxFor', function(source)
  local citizenid = ensureCitizenId(source)
  if not citizenid then return nil end
  return Mailboxes[citizenid]
  -- Limpar badge
  setOrdersBadge(citizenid, 0)
end)


-- Itens: parcel utilizável que desembrulha conteúdos
QBCore.Functions.CreateUseableItem('parcel', function(source, item)
  local P = playerFromSource(source)
  if not P then return end
  local meta = (item and item.info) or (item and item.metadata) or {}
  local contents = meta.contents or meta.Contents or {}
  local label = meta.label or 'Encomenda'
  -- Remover o item antes de dar conteúdos para evitar exploits
  local removed = pcall(function() P.Functions.RemoveItem('parcel', 1, item.slot) end)
  if not removed then
    TriggerClientEvent('QBCore:Notify', source, 'Não foi possível abrir a encomenda.', 'error')
    return
  end
  local givenAll = true
  for _, c in ipairs(contents) do
    local ok = pcall(function() P.Functions.AddItem(c.item, c.count or 1) end)
    if not ok then givenAll = false end
  end
  if givenAll then
    TriggerClientEvent('QBCore:Notify', source, ('Abriu %s.'):format(label), 'success')
  else
    TriggerClientEvent('QBCore:Notify', source, 'Alguns itens não foram entregues (inventário cheio?).', 'error')
  end
end)

-- Catálogo para NUI
QBCore.Functions.CreateCallback('pt-commerce:shop:getCatalog', function(source, cb)
  cb(CommerceConfig.Catalog or {})
end)

-- Fazer encomenda
RegisterNetEvent('pt-commerce:shop:placeOrder')
AddEventHandler('pt-commerce:shop:placeOrder', function(data)
  local src = source
  local P = playerFromSource(src)
  if not P then return end
  local citizenid = ensureCitizenId(src)
  if not citizenid then return end
  -- data: { items = [{id, qty}], method = 'meet'|'mailbox' }
  local items = data.items or {}
  local method = data.method == 'mailbox' and 'mailbox' or 'meet'
  if method == 'mailbox' and not Mailboxes[citizenid] then
    TriggerClientEvent('QBCore:Notify', src, 'Defina a sua caixa de correio primeiro com /setmailbox.', 'error')
    return
  end
  local total = 0
  local contents = {}
  local catalog = CommerceConfig.Catalog or {}
  local byId = {}
  for _, it in ipairs(catalog) do byId[it.id] = it end
  for _, sel in ipairs(items) do
    local entry = byId[sel.id]
    local qty = tonumber(sel.qty or 1) or 1
    if entry and qty > 0 then
      total = total + (entry.price * qty)
      for _=1,qty do
        for __, c in ipairs(entry.contents) do
          table.insert(contents, { item = c.item, count = c.count })
        end
      end
    end
  end
  if total <= 0 or #contents == 0 then
    TriggerClientEvent('QBCore:Notify', src, 'Carrinho vazio.', 'error')
    return
  end
  -- Cobrar do banco
  local ok = pcall(function() P.Functions.RemoveMoney('bank', total, 'pt-commerce-order') end)
  if not ok then
    TriggerClientEvent('QBCore:Notify', src, 'Saldo insuficiente.', 'error')
    return
  end
  -- Criar encomenda
  local id = tostring(math.floor(os.clock()*1000))..math.random(100,999)
  local order = {
    id = id,
    citizenid = citizenid,
    items = contents,
    total = total,
    method = method,
    status = 'pending',
    createdAt = os.time(),
  }
  -- Se for meet, guardamos coords dinâmicas depois na reclamação do CTT; para mailbox, resolvemos já
  if method == 'mailbox' then
    order.target = { type = 'mailbox', coords = Mailboxes[citizenid] }
  else
    order.target = { type = 'meet' }
  end
  table.insert(Orders, order)
  saveJson(ORDERS_FILE, Orders)
  TriggerClientEvent('QBCore:Notify', src, ('Encomenda criada. Total: %d€'):format(total), 'success')
  notifyCitizen(citizenid, ('Encomenda %s criada: %s'):format(id, method == 'mailbox' and 'para a sua caixa' or 'entrega em mão'), 'primary')
end)

-- CTT painel: listar encomendas pendentes
QBCore.Functions.CreateCallback('pt-commerce:ctt:listPending', function(source, cb)
  local P = playerFromSource(source)
  if not P or P.PlayerData.job.name ~= 'ctt' or not P.PlayerData.job.onduty then cb({}) return end
  local list = {}
  for _, o in ipairs(Orders) do
    if o.status == 'pending' or (o.status == 'assigned' and o.assignedTo == P.PlayerData.citizenid) then
      table.insert(list, { id = o.id, method = o.method, total = o.total, target = o.target, assignedTo = o.assignedTo })
    end
  end
  cb(list)
end)

-- CTT: reclamar uma encomenda
RegisterNetEvent('pt-commerce:ctt:claimOrder')
AddEventHandler('pt-commerce:ctt:claimOrder', function(orderId)
  local src = source
  local P = playerFromSource(src)
  if not P or P.PlayerData.job.name ~= 'ctt' or not P.PlayerData.job.onduty then return end
  for _, o in ipairs(Orders) do
    if o.id == orderId and (o.status == 'pending' or (o.status == 'assigned' and o.assignedTo == P.PlayerData.citizenid)) then
      o.status = 'assigned'
      o.assignedTo = P.PlayerData.citizenid
      -- Se método meet, definimos snapshot do destino como a posição atual do cliente (se online)
      if o.method == 'meet' and (not o.target or not o.target.coords) then
        -- tentar obter posição do cliente
        for _, pid in ipairs(QBCore.Functions.GetPlayers()) do
          local PP = QBCore.Functions.GetPlayer(pid)
          if PP and PP.PlayerData.citizenid == o.citizenid then
            local ped = GetPlayerPed(pid)
            if ped and ped ~= 0 then
              local x,y,z = table.unpack(GetEntityCoords(ped))
              o.target = { type = 'meet', coords = { x = x, y = y, z = z } }
            end
            break
          end
        end
        -- fallback: warehouse se offline
        if not o.target or not o.target.coords then
          o.target = { type = 'warehouse', coords = { x = CommerceConfig.Warehouse.coords.x, y = CommerceConfig.Warehouse.coords.y, z = CommerceConfig.Warehouse.coords.z } }
        end
      end
      saveJson(ORDERS_FILE, Orders)
      TriggerClientEvent('pt-commerce:ctt:setWaypoint', src, o.target.coords)
      TriggerClientEvent('QBCore:Notify', src, 'Encomenda atribuída. Waypoint definido.', 'success')
      notifyCitizen(o.citizenid, ('A sua encomenda %s está a caminho.'):format(o.id), 'primary')
      return
    end
  end
end)

-- CTT: tentativa de entrega
RegisterNetEvent('pt-commerce:ctt:deliverAttempt')
AddEventHandler('pt-commerce:ctt:deliverAttempt', function(orderId)
  local src = source
  local P = playerFromSource(src)
  if not P or P.PlayerData.job.name ~= 'ctt' or not P.PlayerData.job.onduty then return end
  local ped = GetPlayerPed(src)
  local px,py,pz = table.unpack(GetEntityCoords(ped))
  for _, o in ipairs(Orders) do
    if o.id == orderId and o.status == 'assigned' and o.assignedTo == P.PlayerData.citizenid then
      local t = o.target or {}
      local c = t.coords or {}
      -- Verificar proximidade: aceitar se perto do alvo armazenado OU do cliente em tempo real (no caso de meet)
      local nearEnough = false
      local dx, dy, dz = (px - (c.x or 1e6)), (py - (c.y or 1e6)), (pz - (c.z or 1e6))
      local dist2 = dx*dx + dy*dy + dz*dz
      if dist2 <= (20.0*20.0) then nearEnough = true end
      local targetSrc
      if o.method == 'meet' then
        for _, pid in ipairs(QBCore.Functions.GetPlayers()) do
          local PP = QBCore.Functions.GetPlayer(pid)
          if PP and PP.PlayerData.citizenid == o.citizenid then targetSrc = pid break end
        end
        if targetSrc then
          local tped = GetPlayerPed(targetSrc)
          local tx,ty,tz = table.unpack(GetEntityCoords(tped))
          local ddx,ddy,ddz = px-tx,py-ty,pz-tz
          if (ddx*ddx + ddy*ddy + ddz*ddz) <= (20.0*20.0) then nearEnough = true end
        end
      end
      if not nearEnough then
        TriggerClientEvent('QBCore:Notify', src, 'Demasiado longe do destino.', 'error')
        return
      end
      if o.method == 'meet' then
        -- requer o cliente presente
        if not targetSrc then
          -- cliente offline: tentar deixar em caixa de correio se existir
          local mb = Mailboxes[o.citizenid]
          if mb and mb.coords then
            Mailboxes[o.citizenid].pending = Mailboxes[o.citizenid].pending or {}
            table.insert(Mailboxes[o.citizenid].pending, { label = 'Encomenda', items = o.items })
            saveJson(MAILBOX_FILE, Mailboxes)
            TriggerClientEvent('QBCore:Notify', src, 'Cliente offline. Encomenda deixada na caixa de correio.', 'primary')
          else
            TriggerClientEvent('QBCore:Notify', src, 'Cliente offline e sem caixa de correio definida.', 'error')
            return
          end
        else
          local tped = GetPlayerPed(targetSrc)
          local tx,ty,tz = table.unpack(GetEntityCoords(tped))
          local ddx,ddy,ddz = px-tx,py-ty,pz-tz
          if (ddx*ddx + ddy*ddy + ddz*ddz) > (CommerceConfig.MeetDistance*CommerceConfig.MeetDistance) then
            TriggerClientEvent('QBCore:Notify', src, 'Cliente demasiado longe para entrega em mão.', 'error')
            return
          end
          -- Signature/PIN flow: generate short PIN for this order if not exists
          if not o.pin then
            local pin = math.random(1000, 9999)
            o.pin = pin
            o.pendingSigner = o.citizenid
            saveJson(ORDERS_FILE, Orders)
            -- Notify customer with PIN
            notifyCitizen(o.citizenid, ('O estafeta chegou com a encomenda %s. PIN: %d'):format(o.id, pin), 'primary')
          end
          TriggerClientEvent('QBCore:Notify', src, 'Aguardando PIN do cliente...', 'primary')
          TriggerClientEvent('pt-commerce:ctt:promptPin', src, o.id)
          -- Store attempt window
          local key = o.id .. '|' .. (P.PlayerData.citizenid)
          DeliveryAttempts[key] = (DeliveryAttempts[key] or 0) + 1
          return
        end
      else
        -- mailbox
        local mb = Mailboxes[o.citizenid]
        if not mb then
          TriggerClientEvent('QBCore:Notify', src, 'Cliente sem caixa de correio definida.', 'error')
          return
        end
        Mailboxes[o.citizenid].pending = Mailboxes[o.citizenid].pending or {}
        table.insert(Mailboxes[o.citizenid].pending, { label = 'Encomenda', items = o.items })
        saveJson(MAILBOX_FILE, Mailboxes)
      end
      -- If we reached here, delivery concluded (either mailbox or dropped due to offline with mailbox)
      local distBonus = (math.sqrt(dist2)/1000.0) * (CommerceConfig.CttPayout.distancePerKm or 0)
      local pay = math.floor((CommerceConfig.CttPayout.base or 0) + distBonus)
      pcall(function() P.Functions.AddMoney('bank', pay, 'pt-commerce-ctt') end)
      o.status = 'delivered'
      saveJson(ORDERS_FILE, Orders)
      TriggerClientEvent('QBCore:Notify', src, 'Encomenda entregue.', 'success')
      notifyCitizen(o.citizenid, ('Encomenda %s entregue.'):format(o.id), 'success')
      return
    end
  end
end)

-- CTT: confirm signature PIN (called by courier after reading from customer)
RegisterNetEvent('pt-commerce:ctt:confirmPin')
AddEventHandler('pt-commerce:ctt:confirmPin', function(orderId, pin)
  local src = source
  local P = playerFromSource(src)
  if not P or P.PlayerData.job.name ~= 'ctt' or not P.PlayerData.job.onduty then return end
  for _, o in ipairs(Orders) do
    if o.id == orderId and o.status == 'assigned' and o.assignedTo == P.PlayerData.citizenid then
      pin = tonumber(pin)
      if o.pin and pin and tonumber(o.pin) == pin then
        -- Give parcel to customer if online
        for _, pid in ipairs(QBCore.Functions.GetPlayers()) do
          local PP = QBCore.Functions.GetPlayer(pid)
          if PP and PP.PlayerData.citizenid == o.citizenid then
            local rec = PP
            local parcel = { name = 'parcel', amount = 1, info = { label = 'Encomenda', contents = o.items } }
            pcall(function() rec.Functions.AddItem('parcel', 1, false, parcel.info) end)
            TriggerClientEvent('QBCore:Notify', pid, 'Recebeu a sua encomenda!', 'success')
            break
          end
        end
        -- Pagar e fechar
        local pay = math.floor((CommerceConfig.CttPayout.base or 0))
        pcall(function() P.Functions.AddMoney('bank', pay, 'pt-commerce-ctt') end)
        o.status = 'delivered'
        o.pin = nil
        saveJson(ORDERS_FILE, Orders)
        TriggerClientEvent('QBCore:Notify', src, 'Entrega confirmada por PIN.', 'success')
        notifyCitizen(o.citizenid, ('Encomenda %s entregue com assinatura.'):format(o.id), 'success')
      else
        -- Failed PIN: after 3 attempts fallback to mailbox (if exists)
        local key = o.id .. '|' .. (P.PlayerData.citizenid)
        DeliveryAttempts[key] = (DeliveryAttempts[key] or 0) + 1
        if DeliveryAttempts[key] >= 3 then
          local mb = Mailboxes[o.citizenid]
          if mb and mb.coords then
            Mailboxes[o.citizenid].pending = Mailboxes[o.citizenid].pending or {}
            table.insert(Mailboxes[o.citizenid].pending, { label = 'Encomenda', items = o.items })
            saveJson(MAILBOX_FILE, Mailboxes)
            o.status = 'delivered'
            o.pin = nil
            saveJson(ORDERS_FILE, Orders)
            TriggerClientEvent('QBCore:Notify', src, 'PIN incorreto várias vezes. Encomenda deixada na caixa de correio.', 'primary')
            notifyCitizen(o.citizenid, ('Encomenda %s deixada na caixa de correio.'):format(o.id), 'primary')
          else
            TriggerClientEvent('QBCore:Notify', src, 'PIN incorreto. Cliente sem caixa definida. Tente novamente mais tarde.', 'error')
          end
        else
          TriggerClientEvent('QBCore:Notify', src, 'PIN incorreto.', 'error')
        end
      end
      return
    end
  end
end)

-- Mailbox: definir e consultar
RegisterNetEvent('pt-commerce:mailbox:set')
AddEventHandler('pt-commerce:mailbox:set', function(coords)
  local src = source
  local citizenid = ensureCitizenId(src)
  if not citizenid then return end
  Mailboxes[citizenid] = { coords = coords, pending = Mailboxes[citizenid] and Mailboxes[citizenid].pending or {} }
  saveJson(MAILBOX_FILE, Mailboxes)
  TriggerClientEvent('QBCore:Notify', src, 'Caixa de correio definida.', 'success')
end)

QBCore.Functions.CreateCallback('pt-commerce:mailbox:get', function(source, cb)
  local citizenid = ensureCitizenId(source)
  if not citizenid then cb(nil) return end
  cb(Mailboxes[citizenid])
end)

QBCore.Functions.CreateCallback('pt-commerce:mailbox:hasPackages', function(source, cb)
  local citizenid = ensureCitizenId(source)
  if not citizenid then cb(0) return end
  local mb = Mailboxes[citizenid]
  local n = (mb and mb.pending) and #mb.pending or 0
  cb(n)
end)

RegisterNetEvent('pt-commerce:mailbox:pickup')
AddEventHandler('pt-commerce:mailbox:pickup', function()
  local src = source
  local citizenid = ensureCitizenId(src)
  local P = playerFromSource(src)
  if not citizenid or not P then return end
  local mb = Mailboxes[citizenid]
  if not mb or not mb.coords then return end
  -- Verificar distância
  local ped = GetPlayerPed(src)
  local px,py,pz = table.unpack(GetEntityCoords(ped))
  local c = mb.coords
  local dx,dy,dz = px-c.x, py-c.y, pz-(c.z or pz)
  if (dx*dx + dy*dy + dz*dz) > (8.0*8.0) then
    TriggerClientEvent('QBCore:Notify', src, 'Aproxime-se da sua caixa de correio.', 'error')
    return
  end
  mb.pending = mb.pending or {}
  if #mb.pending == 0 then
    TriggerClientEvent('QBCore:Notify', src, 'Sem encomendas na caixa.', 'primary')
    return
  end
  -- Entregar um ou todos? Aqui: todos, numa só parcela.
  local allItems = {}
  for _, pkg in ipairs(mb.pending) do
    for __, it in ipairs(pkg.items or {}) do table.insert(allItems, it) end
  end
  mb.pending = {}
  saveJson(MAILBOX_FILE, Mailboxes)
  local info = { label = 'Encomenda (Caixa)', contents = allItems }
  pcall(function() P.Functions.AddItem('parcel', 1, false, info) end)
  TriggerClientEvent('QBCore:Notify', src, 'Recolheu as encomendas da caixa.', 'success')
end)

-- Listar as minhas encomendas
QBCore.Functions.CreateCallback('pt-commerce:orders:listMine', function(source, cb)
  local cid = ensureCitizenId(source)
  if not cid then cb({}) return end
  local list = {}
  for _, o in ipairs(Orders) do
    if o.citizenid == cid then
      table.insert(list, { id = o.id, status = o.status, method = o.method, total = o.total, createdAt = o.createdAt })
    end
  end
  cb(list)
end)

-- Export: definir mailbox por cidadão (para integração com housing)
exports('SetMailboxForCitizen', function(citizenid, coords)
  if not citizenid or not coords then return false end
  Mailboxes[citizenid] = Mailboxes[citizenid] or { pending = {} }
  Mailboxes[citizenid].coords = { x = coords.x, y = coords.y, z = coords.z }
  saveJson(MAILBOX_FILE, Mailboxes)
  notifyCitizen(citizenid, 'A sua caixa de correio foi definida/atualizada.', 'primary')
  return true
end)
