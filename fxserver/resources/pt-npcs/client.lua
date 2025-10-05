
local npcs = {}
local pool = {}
local POOL_CAP = 12 

local function debug(msg)
  print(('[pt-npcs][client] %s'):format(msg))
end

local function ensureModelLoaded(hash, timeout)
  RequestModel(hash)
  timeout = timeout or 1000
  local t = 0
  while not HasModelLoaded(hash) and t < timeout do
    Citizen.Wait(10)
    t = t + 10
  end
  return HasModelLoaded(hash)
end

local function createOrReusePed(hash, x, y, z, heading)
  
  for i=#pool,1,-1 do
    local entry = pool[i]
    if entry and not DoesEntityExist(entry.ped) then
      table.remove(pool, i)
    end
  end
  for i,entry in ipairs(pool) do
    if DoesEntityExist(entry.ped) and GetEntityModel(entry.ped) == hash then
      SetEntityCoords(entry.ped, x, y, z - 1.0, false, false, false, true)
      SetEntityHeading(entry.ped, heading or 0.0)
      FreezeEntityPosition(entry.ped, true)
      return entry.ped
    end
  end
  
  local ped = CreatePed(4, hash, x, y, z - 1.0, heading or 0.0, false, true)
  SetBlockingOfNonTemporaryEvents(ped, true)
  SetEntityInvincible(ped, true)
  FreezeEntityPosition(ped, true)
  return ped
end

local function prunePool()
  while #pool > POOL_CAP do
    local entry = table.remove(pool, 1)
    if entry and entry.ped and DoesEntityExist(entry.ped) then
      DeleteEntity(entry.ped)
    end
  end
end

local function updateSpawns(list)
  local playerPed = PlayerPedId()
  local px,py,pz = table.unpack(GetEntityCoords(playerPed))

  
  local keep = {}

  for _, row in ipairs(list or {}) do
    local dist = #(vector3(px,py,pz) - vector3(row.x, row.y, row.z))
    if dist < 80.0 then 
      
      local modelHash = GetHashKey('a_m_m_business_01')
      if ensureModelLoaded(modelHash, 1000) then
        if not npcs[row.id] or not DoesEntityExist(npcs[row.id].ped) then
          local ped = createOrReusePed(modelHash, row.x, row.y, row.z, row.heading or 0.0)
          npcs[row.id] = { ped = ped, shop_id = row.shop_id, x = row.x, y = row.y, z = row.z }
        else
          
        end
        keep[row.id] = true
      end
    end
  end

  
  for id,info in pairs(npcs) do
    if not keep[id] then
      if DoesEntityExist(info.ped) then
        
        table.insert(pool, { ped = info.ped })
        
        SetEntityCoords(info.ped, 0.0, 0.0, -500.0, false, false, false, true)
        FreezeEntityPosition(info.ped, true)
      end
      npcs[id] = nil
    end
  end
  prunePool()
end

RegisterNetEvent('pt-npcs:sendNpcs', function(list)
  
  updateSpawns(list)
  debug('got '..tostring(#(list or {}))..' npcs from server')
end)

Citizen.CreateThread(function()
  while true do
    TriggerServerEvent('pt-npcs:requestNpcs')
    Citizen.Wait(20000) 
  end
end)

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(200)
    local playerPed = PlayerPedId()
    local px,py,pz = table.unpack(GetEntityCoords(playerPed))
    for id, info in pairs(npcs) do
      if DoesEntityExist(info.ped) then
        local ex,ey,ez = table.unpack(GetEntityCoords(info.ped))
        local dist = #(vector3(px,py,pz) - vector3(ex,ey,ez))
        if dist < 2.0 then
          DrawText3D(ex,ey,ez+1.0, '[E] Abrir loja')
          if IsControlJustReleased(0, 38) then
            TriggerServerEvent('pt-shops:requestShops') 
          end
        end
      end
    end
  end
end)

function DrawText3D(x,y,z, text)
  SetTextScale(0.35, 0.35)
  SetTextFont(4)
  SetTextProportional(1)
  SetTextEntry("STRING")
  SetTextCentre(true)
  AddTextComponentString(text)
  SetDrawOrigin(x,y,z, 0)
  DrawText(0.0, 0.0)
  ClearDrawOrigin()
end

debug('pt-npcs client loaded')

AddEventHandler('onResourceStop', function(resName)
  if resName == GetCurrentResourceName() then
    for id,info in pairs(npcs) do
      if DoesEntityExist(info.ped) then
        DeleteEntity(info.ped)
      end
    end
    for _,entry in ipairs(pool) do
      if entry.ped and DoesEntityExist(entry.ped) then
        DeleteEntity(entry.ped)
      end
    end
    npcs = {}
    pool = {}
    debug('cleaned up spawned peds on resource stop')
  end
end)
