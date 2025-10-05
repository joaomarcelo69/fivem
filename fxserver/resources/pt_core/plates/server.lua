-- Plates server: gera e valida placas no formato PT
local oxmysql_ok, oxmysql = pcall(function() return exports.oxmysql end)

local function generatePlate()
    -- Formato simples: AA-00-00
    local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local a = letters[math.random(1, #letters)]
    local b = letters[math.random(1, #letters)]
    local n1 = math.random(10,99)
    local n2 = math.random(10,99)
    return string.format("%s%s-%02d-%02d", a, b, n1, n2)
end

RegisterNetEvent('pt_core:server:requestPlate')
AddEventHandler('pt_core:server:requestPlate', function()
    local src = source
    local plate = generatePlate()
    -- opcional: salvar no DB
    if oxmysql_ok then
        pcall(function()
            exports.oxmysql:insert('INSERT INTO vehicle_plates (plate, created_at) VALUES (?, NOW())', {plate}, function(id) end)
        end)
    else
        -- fallback: try to write via mysql client if available (dev only)
        os.execute(string.format("mysql -uroot -pfivemrootpass -h127.0.0.1 -P3307 qbcore -e \"INSERT INTO vehicle_plates (plate) VALUES ('%s')\"", plate))
    end
    TriggerClientEvent('pt_core:client:receivePlate', src, plate)
end)
