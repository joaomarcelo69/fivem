local json = require and require('json') or nil

local cfgPath = (GetConvar and GetConvar('pt_shops_config', 'server-data/config/pt_shops.json')) or 'server-data/config/pt_shops.json'

local function loadConfig()
  local f = io.open(cfgPath, 'r')
  if not f then
    print('[pt-shops] config not found at '..cfgPath..', using built-in defaults')
    return { shops = {} }
  end
  local data = f:read('*a')
  f:close()
  if json then
    local ok, parsed = pcall(json.decode, data)
    if ok and type(parsed) == 'table' then return parsed end
  end
  print('[pt-shops] failed to parse '..cfgPath..', using empty defaults')
  return { shops = {} }
end

Config = loadConfig()
Shops = Config.shops or {}
