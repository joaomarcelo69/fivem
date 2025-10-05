AddEventHandler('onResourceStart', function(res)
  if res ~= GetCurrentResourceName() then return end
  
  local shopId = 'default'
  local payload = { shopId = shopId, item = 'water', price = 1, count = 1, citizenid = 'SMOKETEST_1' }
  local ok = pcall(function() TriggerEvent('pt-shops:test_buy', 1, payload) end)
  local smoke_log = '/workspaces/fivem/fxserver/resources/smoke_tests/smoke_results.log'
  os.execute('echo "'..os.date('%Y-%m-%d %H:%M:%S')..' - pt-shops-trigger fired pt-shops:test_buy ok='..tostring(ok)..'" >> '..smoke_log..' 2>/dev/null || true')
  print('[pt-shops-trigger] fired pt-shops:test_buy, ok='..tostring(ok))
end)
