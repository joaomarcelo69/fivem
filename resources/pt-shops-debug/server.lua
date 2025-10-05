AddEventHandler('onResourceStart', function(resourceName)
  if resourceName ~= GetCurrentResourceName() then return end
  local payload = { shopId = 'smoketest', item = 'water', price = 1, count = 1 }
  local ok = pcall(function() TriggerEvent('pt-shops:test_buy', 1, payload) end)
  local smoke_log = '/workspaces/fivem/fxserver/resources/smoke_tests/smoke_results.log'
  os.execute('echo "'..os.date('%Y-%m-%d %H:%M:%S')..' - top-res pt-shops-debug fired pt-shops:test_buy ok='..tostring(ok)..'" >> '..smoke_log..' 2>/dev/null || true')
  print(('[pt-shops-debug-top] fired pt-shops:test_buy, ok=%s'):format(tostring(ok)))
end)
