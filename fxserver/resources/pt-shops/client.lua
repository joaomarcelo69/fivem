

local function debug(msg)
  print(('[pt-shops][client] %s'):format(msg))
end

local lastShops = nil

RegisterCommand('pt-openshop', function()
  
  TriggerServerEvent('pt-shops:requestShops')
end, false)

RegisterNetEvent('pt-shops:sendShops', function(shops)
  if not shops or #shops == 0 then
    TriggerEvent('chat:addMessage', { args = { '^1pt-shops', 'Nenhuma loja carregada.' } })
    return
  end
  lastShops = shops
  local shop = shops[1]
  
  if exports and exports['qb-menu'] and exports['qb-menu'].OpenMenu then
    local elements = {}
    for _, it in ipairs(shop.inventory or shop.items or {}) do
      local itemName = it.item or it.name
      table.insert(elements, { header = (it.label or itemName) .. ' - ' .. tostring(it.price) .. '€', txt = '', params = { event = 'pt-shops:clientBuy', args = { shopId = shop.id, item = itemName, price = it.price } } })
    end
    exports['qb-menu']:OpenMenu(elements)
    return
  end

  TriggerEvent('chat:addMessage', { args = { '^2pt-shops', 'Abrindo loja: '..(shop.label or shop.id) } })
  for _, it in ipairs(shop.inventory or shop.items or {}) do
    local itemName = it.item or it.name
    TriggerEvent('chat:addMessage', { args = { '^3pt-shops', ('%s - %s€ (use /pt-buy %s %s)'):format(it.label or itemName, tostring(it.price), shop.id, itemName) } })
  end
end)

RegisterNetEvent('pt-shops:clientBuy', function(data)
  local shopId = data.shopId
  local item = data.item
  local price = data.price or 0
  if exports and exports['qb-menu'] and exports['qb-menu'].OpenMenu then
    local elements = {
      { header = ('Confirmar compra: %s - %s€'):format(item, tostring(price)), txt = '' },
      { header = 'Confirmar', txt = 'Confirmar compra', params = { event = 'pt-shops:confirmBuy', args = { shopId = shopId, item = item, price = price } } },
      { header = 'Cancelar', txt = 'Cancelar compra', params = { event = 'pt-shops:cancelBuy' } },
    }
    exports['qb-menu']:OpenMenu(elements)
    return
  end

  
  TriggerEvent('chat:addMessage', { args = { '^2pt-shops', ('Para comprar: use /pt-buy %s %s'):format(shopId, item) } })
end)

RegisterNetEvent('pt-shops:confirmBuy', function(payload)
  if payload and payload.shopId and payload.item then
    TriggerServerEvent('pt-shops:buy', payload)
  end
end)

RegisterNetEvent('pt-shops:cancelBuy', function()
  TriggerEvent('chat:addMessage', { args = { '^3pt-shops', 'Compra cancelada' } })
end)

RegisterCommand('pt-buy', function(_, args)
  if not args[1] or not args[2] then
    TriggerEvent('chat:addMessage', { args = { '^1pt-shops', 'Uso: /pt-buy <shopId> <item>' } })
    return
  end
  local shopId = args[1]
  local item = args[2]
  
  local price = 0
  if lastShops then
    for _, s in ipairs(lastShops) do
      if s.id == shopId then
        for _, it in ipairs(s.inventory or s.items or {}) do
          local name = it.item or it.name
          if name == item then
            price = it.price or 0
            break
          end
        end
        break
      end
    end
  end
  TriggerServerEvent('pt-shops:buy', { shopId = shopId, item = item, price = price, count = 1 })
end, false)

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(500)
    if IsControlJustReleased(0, 38) then
      
      ExecuteCommand('pt-openshop')
    end
  end
end)

debug('pt-shops client loaded')
