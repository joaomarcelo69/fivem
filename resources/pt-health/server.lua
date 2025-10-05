local LOG = '/workspaces/fivem/verification_report.txt'

local function log(msg)
  print(('[pt-health] %s'):format(msg))
  local ok, f = pcall(io.open, LOG, 'a')
  if ok and f then f:write(os.date('%Y-%m-%d %H:%M:%S')..' [pt-health] '..msg..'\n'); f:close() end
end

local function ox_ready(timeout)
  local t = 0
  while t < (timeout or 15000) do
    if exports and exports.oxmysql and exports.oxmysql.scalar then return true end
    Wait(250)
    t = t + 250
  end
  return false
end

CreateThread(function()
  local ok = ox_ready(20000)
  if not ok then
    log('oxmysql não disponível após timeout (20s)')
  else
    log('oxmysql disponível, iniciando health checks')
  end
  while true do
    local status, res = pcall(function()
      if exports and exports.oxmysql and exports.oxmysql.scalar then
        return exports.oxmysql:scalar('SELECT 1')
      end
      return nil
    end)
    if status and res == 1 then
      log('DB OK (SELECT 1)')
    else
      log('DB FALHOU (SELECT 1)')
    end
    Wait(30000)
  end
end)
