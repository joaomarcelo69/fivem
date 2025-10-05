-- Simple documents client (no QBCore dependency for testing)

local function safeNotify(msg)
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
        QBCore.Functions.Notify(msg, 'info')
        return
    end
    print('[pt_core] '..msg)
end

RegisterNetEvent('pt_core:client:receiveBI')
AddEventHandler('pt_core:client:receiveBI', function(data)
    safeNotify('Recebeste um BI: Nome: '..data.name..' NIF: '..data.nif)
end)

RegisterCommand('abrirdocumentos', function()
    TriggerServerEvent('pt_core:server:getDocuments', function(docs)
        local msg = 'BI: '..docs.bi.name..' NIF: '..docs.bi.nif
        safeNotify(msg)
    end)
end)

RegisterKeyMapping('abrirdocumentos', 'Abrir documentos', 'keyboard', 'F10')

RegisterNetEvent('pt_core:client:receiveNIF')
AddEventHandler('pt_core:client:receiveNIF', function(nif)
    safeNotify('NIF gerado: '..nif)
end)
