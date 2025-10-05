local QBCore = exports['qb-core']:GetCoreObject()

local function getDocs(plate)
  local sql = 'SELECT owner, insurance_exp, inspection_exp FROM vehicle_docs WHERE plate = ? LIMIT 1'
  local row
  if MySQL and MySQL.query then
    local ok, res = pcall(function() return MySQL.query.await(sql, { plate }) end)
    if ok and res and res[1] then row = res[1] end
  elseif exports and exports.oxmysql and exports.oxmysql.executeSync then
    local ok, res = pcall(function() return exports.oxmysql:executeSync(sql, { plate }) end)
    if ok and res and res[1] then row = res[1] end
  end
  return row
end

RegisterNetEvent('pt-inspections:server:check')
AddEventHandler('pt-inspections:server:check', function(plate)
  local src = source
  local P = QBCore.Functions.GetPlayer(src)
  if not P then return end
  local docs = getDocs(plate)
  local totalFine = 0
  if docs then
    local now = os.time()
    if (docs.insurance_exp or 0) <= now then
      totalFine = totalFine + (InspectionsConfig.fines.noInsurance or 400)
    end
    if (docs.inspection_exp or 0) <= now then
      totalFine = totalFine + (InspectionsConfig.fines.noInspection or 300)
    end
  end
  
  local pdata = P.PlayerData
  local isTaxi = pdata and pdata.job and (pdata.job.name == 'taxi')
  
  if not isTaxi then
    totalFine = totalFine + (InspectionsConfig.fines.taxiNoLicense or 500)
  end
  if totalFine > 0 then
    TriggerEvent('pt-multas:emitir', P.PlayerData.citizenid, totalFine, 'Irregularidades em fiscalização')
    TriggerClientEvent('QBCore:Notify', src, ('Multa emitida: %d€'):format(totalFine), 'error')
  else
    TriggerClientEvent('QBCore:Notify', src, 'Tudo em conformidade. Boa condução!', 'success')
  end
end)
