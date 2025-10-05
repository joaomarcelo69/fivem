AddEventHandler('onResourceStart', function(res)
  if res ~= GetCurrentResourceName() then return end
  local payload = { shopId = 'smoketest', item = 'water', price = 1, count = 1 }
  local ok = pcall(function() TriggerEvent('pt-shops:test_buy', 1, payload) end)
  
  os.execute('echo "'..os.date('%Y-%m-%d %H:%M:%S')..' - manual_test fired pt-shops:test_buy ok='..tostring(ok)..'" >> /workspaces/fivem/fxserver/resources/smoke_tests/smoke_results.log 2>/dev/null || true')
end)
