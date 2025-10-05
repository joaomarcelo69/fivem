RegisterNetEvent('pt_core:client:receivePlate')
AddEventHandler('pt_core:client:receivePlate', function(plate)
    -- Notificação simples com fallback
    local ok, QBCore = pcall(function()
        if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
            return exports['qb-core']:GetCoreObject()
        elseif GetCoreObject and type(GetCoreObject) == 'function' then
            return GetCoreObject()
        elseif _G and _G.GetCoreObject then
            return _G.GetCoreObject()
        end
    end)
    if ok and QBCore and QBCore.Functions and QBCore.Functions.Notify then
        QBCore.Functions.Notify('Nova matrícula gerada: '..plate, 'success')
        return
    end
    print('[pt_core] Nova matrícula gerada: '..plate)
end)

RegisterCommand('gerarmatricula', function()
    TriggerServerEvent('pt_core:server:requestPlate')
end)
