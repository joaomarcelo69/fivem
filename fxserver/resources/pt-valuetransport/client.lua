local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('pt-valuetransport:missionStarted', function(missionId, pickup, drop, value)
    -- Spawn carrinha, mostrar UI básica
    QBCore.Functions.Notify('Missão iniciada! Recolhe valores em ' .. pickup.name .. ' e entrega em ' .. drop.name)
    -- Aqui podes expandir para spawn de NPCs, minigames, etc.
end)

RegisterNetEvent('pt-valuetransport:missionCompleted', function()
    QBCore.Functions.Notify('Missão concluída! Dinheiro entregue.')
end)

RegisterNetEvent('pt-valuetransport:alertPolice', function(pickup, drop)
    QBCore.Functions.Notify('Alerta: Transporte de valores em curso de ' .. pickup.name .. ' para ' .. drop.name, 'error')
end)

-- Aqui podes expandir para UI NUI, minigames, spawn NPCs, etc.
