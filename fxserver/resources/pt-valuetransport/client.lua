local QBCore = exports['qb-core']:GetCoreObject()

-- Missão iniciada: spawn carrinha, NPCs seguranças, UI
RegisterNetEvent('pt-valuetransport:missionStarted', function(missionId, pickup, drop, value, contractVIP)
    QBCore.Functions.Notify('Missão iniciada! Recolhe valores em ' .. pickup.name .. ' e entrega em ' .. drop.name)
    -- Spawn carrinha blindada
    -- Spawn NPCs seguranças (exemplo)
    for i = 1, Config.Vehicles[1].npcs do
        -- Spawn NPC com arma junto à carrinha
        -- ...
    end
    -- Mostrar UI base (pode ser NUI)
end)

-- Minigame hacking/cofre para assalto
function StartAssaultMinigame()
    -- Exemplo: minigame simples
    QBCore.Functions.Notify('Minigame: hackear cofre da carrinha!')
    -- ...
end

RegisterNetEvent('pt-valuetransport:missionCompleted', function(reward)
    QBCore.Functions.Notify('Missão concluída! Dinheiro entregue: ' .. reward .. '€')
end)

RegisterNetEvent('pt-valuetransport:alertPolice', function(pickup, drop)
    QBCore.Functions.Notify('Alerta: Transporte de valores em curso de ' .. pickup.name .. ' para ' .. drop.name, 'error')
end)

RegisterNetEvent('pt-valuetransport:alertAssault', function()
    QBCore.Functions.Notify('Alerta: Assalto à carrinha de valores!', 'error')
end)

-- UI/NUI pode ser expandida aqui
