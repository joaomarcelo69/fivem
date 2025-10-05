local QBCore
local isShopOpen = false
local isCttOpen = false
local mailboxBlip
local pendingPackages = 0
local mailboxCoords

local function getQB()
  if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
    return exports['qb-core']:GetCoreObject()
  elseif GetCoreObject then
    return GetCoreObject()
  end
end

CreateThread(function()
  QBCore = getQB()
  RegisterKeyMapping('ptshop:open', 'Abrir loja online (Amazon PT)', 'keyboard', 'F7')
  RegisterCommand('ptshop:open', function()
    if isShopOpen then closeShop() return end
    openShop()
  end)
  RegisterCommand('setmailbox', function()
    local ped = PlayerPedId()
    local x,y,z = table.unpack(GetEntityCoords(ped))
    TriggerServerEvent('pt-commerce:mailbox:set', { x=x, y=y, z=z })
  end)
  RegisterCommand('ctt', function()
    local pdata = QBCore.Functions.GetPlayerData()
    if pdata and pdata.job and pdata.job.name == 'ctt' and pdata.job.onduty then
      openCtt()
    else
      QBCore.Functions.Notify('Precisa de estar de serviço nos CTT.', 'error')
    end
  end)
end)

-- SHOP UI
function openShop()
  QBCore.Functions.TriggerCallback('pt-commerce:shop:getCatalog', function(list)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'shop:open', catalog = list or {} })
    isShopOpen = true
  end)
end

function closeShop()
  SetNuiFocus(false, false)
  SendNUIMessage({ action = 'shop:close' })
  isShopOpen = false
end

-- CTT UI
function openCtt()
  QBCore.Functions.TriggerCallback('pt-commerce:ctt:listPending', function(list)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'ctt:open', orders = list or {} })
    isCttOpen = true
  end)
end

function closeCtt()
  SetNuiFocus(false, false)
  SendNUIMessage({ action = 'ctt:close' })
  isCttOpen = false
end

-- NUI callbacks
RegisterNUICallback('shop:close', function(_, cb) closeShop() cb(true) end)
RegisterNUICallback('shop:checkout', function(data, cb)
  TriggerServerEvent('pt-commerce:shop:placeOrder', data)
  cb(true)
end)

RegisterNUICallback('ctt:close', function(_, cb) closeCtt() cb(true) end)
RegisterNUICallback('ctt:claim', function(data, cb)
  TriggerServerEvent('pt-commerce:ctt:claimOrder', data.id)
  cb(true)
end)
RegisterNUICallback('ctt:deliver', function(data, cb)
  TriggerServerEvent('pt-commerce:ctt:deliverAttempt', data.id)
  cb(true)
end)

-- PIN modal: called by server to request PIN entry
RegisterNetEvent('pt-commerce:ctt:promptPin', function(orderId)
  SetNuiFocus(true, true)
  SendNUIMessage({ action = 'ctt:pin', orderId = orderId })
end)

-- NUI callback: submit PIN
RegisterNUICallback('ctt:pin', function(data, cb)
  local id = data and data.id
  local pin = data and data.pin
  if id and pin then
    TriggerServerEvent('pt-commerce:ctt:confirmPin', id, tonumber(pin))
  end
  cb(true)
end)

-- Waypoint para estafeta
RegisterNetEvent('pt-commerce:ctt:setWaypoint', function(coords)
  if coords then
    SetNewWaypoint(coords.x + 0.0, coords.y + 0.0)
    QBCore.Functions.Notify('Destino da entrega definido.', 'primary')
  end
end)

-- Mailbox HUD e interação
CreateThread(function()
  while true do
    Wait(1500)
    if not QBCore then goto cont end
    QBCore.Functions.TriggerCallback('pt-commerce:mailbox:get', function(mb)
      mailboxCoords = mb and mb.coords or nil
    end)
    QBCore.Functions.TriggerCallback('pt-commerce:mailbox:hasPackages', function(n)
      pendingPackages = n or 0
    end)
    ::cont::
  end
end)

CreateThread(function()
  while true do
    Wait(0)
    if mailboxCoords and pendingPackages and pendingPackages > 0 then
      local ped = PlayerPedId()
      local p = GetEntityCoords(ped)
      local c = mailboxCoords
      local dist = #(p - vector3(c.x, c.y, c.z))
      DrawMarker(2, c.x, c.y, c.z + 0.2, 0,0,0, 0,0,0, 0.25,0.25,0.25, 255, 180, 0, 160, false, true, 2, nil, nil, false)
      if dist < 1.8 then
        SetTextComponentFormat('STRING')
        AddTextComponentString(('[E] Levantar encomendas (%d)'):format(pendingPackages))
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)
        if IsControlJustReleased(0, 38) then
          TriggerServerEvent('pt-commerce:mailbox:pickup')
          Wait(600)
        end
      end
    else
      Wait(300)
    end
  end
end)

-- NUI setup
RegisterNUICallback('ui:closeFocus', function(_, cb)
  SetNuiFocus(false, false)
  cb(true)
end)
