local function getQB()
  if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
    return exports['qb-core']:GetCoreObject()
  elseif GetCoreObject then
    return GetCoreObject()
  end
end

local QBCore = getQB()

local SAVE_FILE = 'furniture.json'

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

local Furniture = loadJson(SAVE_FILE) -- array de objetos: {id, owner, item, model, pos, rot}

local function genId()
  return tostring(math.floor(os.clock()*1000))..math.random(100,999)
end

local function broadcast(event, ...)
  TriggerClientEvent(event, -1, ...)
end
-- Tornar itens de mobília utilizáveis
local function registerUseables()
  if not QBCore or not QBCore.Functions or not QBCore.Functions.CreateUseableItem then return end
  for item, _ in pairs(FurnitureConfig.Items or {}) do
    QBCore.Functions.CreateUseableItem(item, function(source)
      TriggerClientEvent('pt-furniture:useItem', source, item)
    end)
  end
end

CreateThread(registerUseables)


-- Callbacks
QBCore.Functions.CreateCallback('pt-furniture:list', function(_, cb)
  cb(Furniture)
end)

-- Helpers
local function ensurePlayer(src)
  local P = QBCore.Functions.GetPlayer(src)
  return P
end

-- Eventos
RegisterNetEvent('pt-furniture:place')
AddEventHandler('pt-furniture:place', function(data)
  local src = source
  local P = ensurePlayer(src)
  if not P then return end
  local pos = data and data.pos
  local rot = data and data.rot
  local item = data and data.item
  if not pos or not item then return end
  if not FurnitureConfig.CanDecorate(src, pos) then
    TriggerClientEvent('QBCore:Notify', src, 'Não tem permissão para decorar aqui.', 'error')
    return
  end
  -- consumir item
  local removed = pcall(function() P.Functions.RemoveItem(item, 1) end)
  if not removed then
    TriggerClientEvent('QBCore:Notify', src, 'Precisa do item no inventário.', 'error')
    return
  end
  local id = genId()
  local obj = {
    id = id,
    owner = P.PlayerData.citizenid,
    item = item,
    model = FurnitureConfig.Items[item] and FurnitureConfig.Items[item].model or `prop_table_04`,
    pos = pos,
    rot = rot or {x=0.0,y=0.0,z=0.0}
  }
  table.insert(Furniture, obj)
  saveJson(SAVE_FILE, Furniture)
  broadcast('pt-furniture:spawn', obj)
  TriggerClientEvent('QBCore:Notify', src, 'Mobília colocada.', 'success')
end)

RegisterNetEvent('pt-furniture:move')
AddEventHandler('pt-furniture:move', function(id, pos, rot)
  local src = source
  local P = ensurePlayer(src)
  if not P then return end
  for _, o in ipairs(Furniture) do
    if o.id == id then
      if o.owner ~= P.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'Não é o proprietário desta mobília.', 'error')
        return
      end
      o.pos = pos or o.pos
      o.rot = rot or o.rot
      saveJson(SAVE_FILE, Furniture)
      broadcast('pt-furniture:update', o)
      TriggerClientEvent('QBCore:Notify', src, 'Mobília movida.', 'success')
      return
    end
  end
end)

RegisterNetEvent('pt-furniture:remove')
AddEventHandler('pt-furniture:remove', function(id)
  local src = source
  local P = ensurePlayer(src)
  if not P then return end
  for i, o in ipairs(Furniture) do
    if o.id == id then
      if o.owner ~= P.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'Não é o proprietário desta mobília.', 'error')
        return
      end
      -- devolver o item
      pcall(function() P.Functions.AddItem(o.item, 1) end)
      table.remove(Furniture, i)
      saveJson(SAVE_FILE, Furniture)
      broadcast('pt-furniture:despawn', id)
      TriggerClientEvent('QBCore:Notify', src, 'Mobília removida.', 'success')
      return
    end
  end
end)
