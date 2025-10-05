-- Minimal smoke_tests server script

local LOG = GetResourcePath(GetCurrentResourceName()) .. '/smoke_results.log'

local function log(msg)
    print('[smoke_tests] ' .. tostring(msg))
    local f = io.open(LOG, 'a')
    if f then f:write(os.date('%Y-%m-%d %H:%M:%S') .. ' - ' .. tostring(msg) .. '\n') f:close() end
end

CreateThread(function()
    log('smoke_tests started')

    -- DB ping via oxmysql
    if GetResourceState('oxmysql') == 'started' then
        exports['oxmysql']:query('SELECT 1 AS ok', {}, function(result)
            local ok = result and result[1] and tonumber(result[1].ok) == 1
            log('oxmysql SELECT 1 ok=' .. tostring(ok))
        end)
    else
        log('oxmysql not started')
    end

    -- Shop self-test hook if present
    if GetResourceState('pt-shops') == 'started' then
        TriggerEvent('pt-shops:selftest')
        log('triggered pt-shops:selftest')
    end

    -- Fisco presence
    log('pt-fisco state ' .. GetResourceState('pt-fisco'))
end)
