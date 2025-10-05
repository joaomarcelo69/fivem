-- Documents server: use QBCore/oxmysql when available, otherwise fallback

local QBCore = nil
local hasOx = false

local function safeGetCore()
    local ok, obj = pcall(function()
        if exports and exports['qb-core'] and type(exports['qb-core'].GetCoreObject) == 'function' then
            return exports['qb-core']:GetCoreObject()
        elseif type(GetCoreObject) == 'function' then
            return GetCoreObject()
        elseif Global and type(Global.GetCoreObject) == 'function' then
            return Global.GetCoreObject()
        end
    end)
    if ok and obj then return obj end
    return nil
end

local function waitForQBCore(timeoutSec)
    timeoutSec = timeoutSec or 5
    local start = os.time()
    while os.time() - start < timeoutSec do
        local obj = safeGetCore()
        if obj then return obj end
        Citizen.Wait(200)
    end
    return nil
end

    QBCore = waitForQBCore(5)
    QBCore = QBCore or {}
pcall(function() hasOx = exports and (exports.oxmysql ~= nil) end)

local function getDocs(citizenId)
    if QBCore and QBCore.Functions and hasOx then
        -- Example: fetch from DB (if you have a citizens table)
        local ok, result = pcall(function()
            return exports.oxmysql:scalarSync('SELECT name FROM citizens WHERE citizenid = ? LIMIT 1', {citizenId})
        end)
        if ok and result then
            return { bi = { name = result, nif = 'unknown', birth = 'unknown' }, driving = { license = false } }
        end
    end
    -- fallback
    return { bi = { name = 'João Silva', nif = '123456789', birth = '1990-01-01' }, driving = { license = true, categories = {'B'} } }
end

RegisterNetEvent('pt_core:server:getDocuments')
AddEventHandler('pt_core:server:getDocuments', function(cb, citizenId)
    local docs = getDocs(citizenId)
    if cb then cb(docs) end
end)

RegisterCommand('emitirbi', function(source, args)
    local target = tonumber(args[1])
    if not target then return end
    TriggerClientEvent('pt_core:client:receiveBI', target, {
        name = 'Emitido: '..os.date('%Y-%m-%d'),
        nif = tostring(math.random(100000000,999999999)),
        birth = os.date('%Y-%m-%d')
    })
end, false)

RegisterCommand('gerarnif', function(source, args)
    local target = tonumber(args[1]) or source
    local nif = tostring(math.random(100000000,999999999))
    TriggerClientEvent('pt_core:client:receiveNIF', target, nif)
end, false)

-- If QBCore is available, register a proper admin command; guard in case QBCore is not fully loaded
if QBCore and QBCore.Commands then
    QBCore.Commands.Add('gerarnif', 'Gerar NIF (admin)', {}, true, function(source, args)
        local target = tonumber(args[1]) or source
        local nif = tostring(math.random(100000000,999999999))
        TriggerClientEvent('pt_core:client:receiveNIF', target, nif)
    end)
end
