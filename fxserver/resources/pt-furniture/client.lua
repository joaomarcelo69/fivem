local preview = nil
local previewModel = nil
local placing = false
local placingItem = nil
local heightOffset = 0.0
local snapEnabled = true
local lastValidPos = nil

local function loadModel(model)
  if type(model) == 'string' then model = GetHashKey(model) end
  if not IsModelInCdimage(model) then return false end
  RequestModel(model)
  local t = GetGameTimer() + 5000
  while not HasModelLoaded(model) and GetGameTimer() < t do Wait(0) end
  return HasModelLoaded(model)
end

local function raycastForward(dist)
  local ped = PlayerPedId()
  local coords = GetEntityCoords(ped)
  local dir = GetEntityForwardVector(ped)
  local dest = coords + (dir * dist)
  local handle = StartShapeTestRay(coords.x, coords.y, coords.z + 0.5, dest.x, dest.y, dest.z, -1, ped, 0)
  local _, hit, endPos = GetShapeTestResult(handle)
  if hit == 1 then return endPos end
  return dest
end

local function clearPreview()
  if DoesEntityExist(preview) then DeleteEntity(preview) end
  if previewModel then SetModelAsNoLongerNeeded(previewModel) end
  preview = nil
  previewModel = nil
end

local function startPlacement(item)
  local cfg = FurnitureConfig.Items[item]
  if not cfg then return end
  local model = cfg.model
  if not loadModel(model) then return end
  previewModel = model
  placing = true
  placingItem = item
  heightOffset = 0.0
  lastValidPos = nil
  local ped = PlayerPedId()
  local pos = raycastForward(2.0)
  preview = CreateObject(model, pos.x, pos.y, pos.z, false, false, false)
  SetEntityAlpha(preview, 180, false)
  SetEntityCollision(preview, false, false)
  SetEntityHeading(preview, GetEntityHeading(ped))
end

local function finishPlacement(confirm)
  if not placing then return end
  local item = placingItem
  placing = false
  placingItem = nil
  if confirm and DoesEntityExist(preview) then
    local pos = GetEntityCoords(preview)
    local rx, ry, rz = table.unpack(GetEntityRotation(preview, 2))
    TriggerServerEvent('pt-furniture:place', { item = item, pos = {x=pos.x,y=pos.y,z=pos.z}, rot = {x=rx,y=ry,z=rz} })
  end
  clearPreview()
end

CreateThread(function()
  while true do
    Wait(0)
    if placing and DoesEntityExist(preview) then
      
      local base = raycastForward(FurnitureConfig.PlaceMaxDistance)
      
      local groundZ = nil
      local foundGround, gz = GetGroundZFor_3dCoord(base.x, base.y, base.z, false)
      if foundGround then groundZ = gz end
      local target = vector3(base.x, base.y, (groundZ or base.z) + heightOffset)

      
      local grid = IsControlPressed(0, 21) and 0.05 or 0.25 
      if snapEnabled then
        target = vector3(math.floor(target.x / grid + 0.5) * grid, math.floor(target.y / grid + 0.5) * grid, target.z)
      end

      SetEntityCoords(preview, target.x, target.y, target.z, false, false, false, false)

      
      local step = IsControlPressed(0, 21) and 0.5 or 2.5
      if IsControlPressed(0, 44) or IsControlPressed(0, 174) then 
        SetEntityHeading(preview, GetEntityHeading(preview) - step)
      elseif IsControlPressed(0, 38) or IsControlPressed(0, 175) then 
        SetEntityHeading(preview, GetEntityHeading(preview) + step)
      end

      
      if IsControlPressed(0, 172) then 
        heightOffset = math.min(heightOffset + 0.01, 3.0)
      elseif IsControlPressed(0, 173) then 
        heightOffset = math.max(heightOffset - 0.01, -1.0)
      end

      
      if IsControlJustPressed(0, 47) and groundZ then 
        heightOffset = (groundZ + 0.02) - base.z
      end

      
      if IsControlJustPressed(0, 45) then 
        snapEnabled = not snapEnabled
      end

      
      local valid = groundZ ~= nil and #(GetEntityCoords(PlayerPedId()) - target) <= FurnitureConfig.PlaceMaxDistance + 0.5
      if valid then lastValidPos = target end

      
      local r,g,b = 200,50,50
      if valid then r,g,b = 50,200,80 end
      DrawMarker(28, target.x, target.y, (groundZ or target.z) + 0.03, 0.0,0.0,0.0, 0.0,0.0,0.0, 0.18,0.18,0.18, r,g,b,120, false, false, 2, true, nil, nil, false)

      
      if IsControlJustPressed(0, 18) and valid then 
        finishPlacement(true)
      elseif IsControlJustPressed(0, 177) then 
        finishPlacement(false)
      end

      
      SetTextFont(4); SetTextScale(0.34,0.34); SetTextColour(255,255,255,215); SetTextCentre(true)
      BeginTextCommandDisplayText('STRING')
      AddTextComponentSubstringPlayerName(('Q/E/←/→ rodar (Shift = fino) | ↑/↓ altura | G chão | R grelha: %s | Enter confirmar | Backspace cancelar'):format(snapEnabled and 'ON' or 'OFF'))
      EndTextCommandDisplayText(0.5, 0.88)
    end
  end
end)

RegisterCommand('place', function(_, args)
  local item = args[1]
  if not item or not FurnitureConfig.Items[item] then
    TriggerEvent('chat:addMessage', { args = { '^3[Furniture]', 'Uso: /place <item>' } })
    return
  end
  startPlacement(item)
end)

RegisterNetEvent('pt-furniture:useItem')
AddEventHandler('pt-furniture:useItem', function(item)
  if FurnitureConfig.Items[item] then
    startPlacement(item)
  end
end)

local function getLookingFurniture()
  local ped = PlayerPedId()
  local pos = GetEntityCoords(ped)
  local fwd = GetEntityForwardVector(ped)
  local endPos = pos + (fwd * FurnitureConfig.ManipulateDistance)
  local handle = StartShapeTestCapsule(pos.x,pos.y,pos.z+0.5,endPos.x,endPos.y,endPos.z+0.5,0.6,16,ped,7)
  local _, hit, _, _, entityHit = GetShapeTestResult(handle)
  if hit == 1 and DoesEntityExist(entityHit) then
    local entId = DecorGetInt(entityHit, 'ptf_id') or 0
    return entityHit, tostring(entId)
  end
end

RegisterCommand('fmove', function()
  local ent, id = getLookingFurniture()
  if ent and id and id ~= '0' then
    local pos = GetEntityCoords(ent)
    local newPos = raycastForward(2.0)
    TriggerServerEvent('pt-furniture:move', id, {x=newPos.x,y=newPos.y,z=newPos.z})
  else
    TriggerEvent('chat:addMessage', { args = { '^3[Furniture]', 'Aponte para um objeto de mobília.' } })
  end
end)

RegisterCommand('fremove', function()
  local ent, id = getLookingFurniture()
  if ent and id and id ~= '0' then
    TriggerServerEvent('pt-furniture:remove', id)
  else
    TriggerEvent('chat:addMessage', { args = { '^3[Furniture]', 'Aponte para um objeto de mobília.' } })
  end
end)

local spawned = {}

local function ensureDecor()
  if not DecorIsRegisteredAsType('ptf_id', 3) then
    DecorRegister('ptf_id', 3)
  end
end

local function spawnOne(obj)
  ensureDecor()
  local model = obj.model
  if type(model) == 'string' then model = GetHashKey(model) end
  if not loadModel(model) then return end
  local e = CreateObject(model, obj.pos.x, obj.pos.y, obj.pos.z, false, false, false)
  SetEntityHeading(e, obj.rot and obj.rot.z or 0.0)
  DecorSetInt(e, 'ptf_id', tonumber(obj.id) or 0)
  FreezeEntityPosition(e, true)
  spawned[obj.id] = e
end

RegisterNetEvent('pt-furniture:spawn')
AddEventHandler('pt-furniture:spawn', function(obj)
  spawnOne(obj)
end)

RegisterNetEvent('pt-furniture:update')
AddEventHandler('pt-furniture:update', function(obj)
  local e = spawned[obj.id]
  if e and DoesEntityExist(e) then
    SetEntityCoords(e, obj.pos.x, obj.pos.y, obj.pos.z)
    SetEntityHeading(e, obj.rot and obj.rot.z or GetEntityHeading(e))
  else
    spawnOne(obj)
  end
end)

RegisterNetEvent('pt-furniture:despawn')
AddEventHandler('pt-furniture:despawn', function(id)
  local e = spawned[id]
  if e and DoesEntityExist(e) then
    DeleteEntity(e)
  end
  spawned[id] = nil
end)

CreateThread(function()
  local res = lib and lib.callback or nil
  TriggerServerEvent('pt-furniture:__init')
  
  QBCore.Functions.TriggerCallback('pt-furniture:list', function(list)
    for _, o in ipairs(list or {}) do spawnOne(o) end
  end)
end)
