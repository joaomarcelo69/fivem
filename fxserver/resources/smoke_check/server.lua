local LOG = GetResourcePath(GetCurrentResourceName()) .. '/smoke_check.log'
local WORK_LOG = '/workspaces/fivem/smoke_check_summary.log'

local function lw(msg)
    local line = os.date('%Y-%m-%d %H:%M:%S') .. ' - ' .. tostring(msg)
    print('[smoke_check] ' .. msg)
    local f = io.open(LOG, 'a')
    if f then f:write(line .. '\n') f:close() end
    os.execute('echo "'..line..'" >> '..WORK_LOG..' 2>/dev/null || true')
end

CreateThread(function()
    lw('smoke_check started')
    lw('oxmysql state ' .. GetResourceState('oxmysql'))
    lw('qb-core state ' .. GetResourceState('qb-core'))
    lw('pt-fisco state ' .. GetResourceState('pt-fisco'))
    lw('pt-shops state ' .. GetResourceState('pt-shops'))
end)

Citizen.CreateThread(function()
    lw('thread started')
    local timeout = 15 -- seconds
    lw('waiting up to ' .. tostring(timeout) .. 's for MySQL to be ready')
    local gotReady = false
    for i=1, timeout * 2 do -- check every 0.5s
        if exports and exports.oxmysql then
            gotReady = true
            break
        end
        Wait(500)
    end
    if not gotReady then
        lw('timeout waiting for MySQL')
    else
        lw('MySQL readiness check complete')
    end
    lw('smoke_check finished')
end)
