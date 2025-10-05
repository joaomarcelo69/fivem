local LOG = '/workspaces/fivem/verification_report.txt'

local function log(msg)
  print(('[pt-health] %s'):format(msg))
  local ok, f = pcall(io.open, LOG, 'a')
  if ok and f then f:write(os.date('%Y-%m-%d %H:%M:%S')..' [pt-health] '..msg..'\n'); f:close() end
end

local function mysql_ready(timeout)
  local t = 0
  while t < (timeout or 15000) do
    if type(MySQL) == 'table' and (MySQL.scalar or MySQL.query) then return true end
    Wait(250)
    t = t + 250
  end
  return false
end

CreateThread(function()
  local ok = mysql_ready(20000)
  if not ok then
    log('MySQL não disponível após timeout (20s)')
  else
    log('MySQL disponível, iniciando health checks')
  end
  while true do
    local status, res = pcall(function()
      if MySQL and MySQL.scalar and MySQL.scalar.await then
        return MySQL.scalar.await('SELECT 1')
      elseif MySQL and MySQL.scalar then
        -- Fallback, non-await (may return a promise on newer oxmysql)
        return MySQL.scalar('SELECT 1')
      end
      return nil
    end)
    -- Some drivers may return '1' as a string; accept both string and number.
    local ok1 = status and (res == 1 or res == '1')
    if ok1 then
      log('DB OK (SELECT 1)')
    else
      log('DB FALHOU (SELECT 1)')
    end
    Wait(30000)
  end
end)
