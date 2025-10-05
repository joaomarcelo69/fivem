local function debug(msg)
  print(('[pt-npcs] %s'):format(msg))
end

RegisterNetEvent('pt-npcs:requestNpcs', function()
  local src = source
  local ok, res = pcall(function()
    return exports.oxmysql:executeSync('SELECT id, shop_id, x, y, z, heading FROM shops_npcs')
  end)
  if not ok then
    debug('DB query failed')
    TriggerClientEvent('pt-npcs:sendNpcs', src, {})
    return
  end
  TriggerClientEvent('pt-npcs:sendNpcs', src, res or {})
end)

local function waitForOxmysql(timeoutSeconds)
  timeoutSeconds = timeoutSeconds or 8
  local elapsed = 0
  while elapsed < timeoutSeconds do
    if exports and exports.oxmysql then return true end
    Citizen.Wait(500)
    elapsed = elapsed + 0.5
  end
  return false
end

if not waitForOxmysql(6) then
  debug('oxmysql not available at startup; DB queries will fallback/return empty')
else
  debug('oxmysql detected')
end

debug('pt-npcs server started')

debug('pt-npcs resource started')
