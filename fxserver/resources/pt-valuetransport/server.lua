local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('pt-valuetransport:startMission', function(pickup, drop, value)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.Job then return end
    local missionId = MySQL.insert.await('INSERT INTO value_transports (pickup, dropoff, value, status, started_by) VALUES (?, ?, ?, ?, ?)', {
        pickup.name, drop.name, value, 'in_progress', player.PlayerData.citizenid
    })
    TriggerClientEvent('pt-valuetransport:missionStarted', src, missionId, pickup, drop, value)
    -- Notificar polícias
    for _, job in ipairs(Config.PoliceJobs) do
        local cops = QBCore.Functions.GetPlayersByJob(job)
        for _, copSrc in ipairs(cops) do
            TriggerClientEvent('pt-valuetransport:alertPolice', copSrc, pickup, drop)
        end
    end
end)

RegisterNetEvent('pt-valuetransport:completeMission', function(missionId)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    MySQL.update.await('UPDATE value_transports SET status = ? WHERE id = ?', { 'delivered', missionId })
    player.Functions.AddMoney('bank', Config.MinValue)
    TriggerClientEvent('pt-valuetransport:missionCompleted', src)
end)

RegisterNetEvent('pt-valuetransport:failMission', function(missionId)
    MySQL.update.await('UPDATE value_transports SET status = ? WHERE id = ?', { 'failed', missionId })
end)

-- API para despachos, logs, etc. pode ser expandida
