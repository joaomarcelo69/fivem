local capturing = false

local function ensureModel(model)
  if not IsModelValid(model) then return false end
  RequestModel(model)
  local t = GetGameTimer()
  while not HasModelLoaded(model) do
    Wait(0)
    if GetGameTimer() - t > 5000 then return false end
  end
  return true
end

local function vec(x,y,z) return vector3(x,y,z) end

local function captureModel(model, fileName)
  if capturing then return false, 'busy' end
  capturing = true

  
  local origin = vec(4000.0, 4000.0, 200.0)

  
  if not ensureModel(model) then capturing=false return false,'model' end
  local obj = CreateObject(model, origin.x, origin.y, origin.z, false, false, false)
  if obj == 0 then capturing=false return false,'spawn' end

  
  SetEntityHeading(obj, 180.0)
  SetEntityCollision(obj, false, false)
  FreezeEntityPosition(obj, true)

  
  local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
  local min,max = GetModelDimensions(model)
  local size = #(max - min)
  local dist = math.max(2.0, size * 1.9)
  local camPos = origin + vec(dist, 0.0, 0.95)
  SetCamCoord(cam, camPos.x, camPos.y, camPos.z)
  PointCamAtEntity(cam, obj, 0.0, 0.0, 0.0, true)
  SetCamFov(cam, 34.0)
  RenderScriptCams(true, false, 0, true, false, 0)

  
  ClearOverrideWeather()
  SetWeatherTypePersist('EXTRASUNNY')
  SetWeatherTypeNow('EXTRASUNNY')
  SetWeatherTypeNowPersist('EXTRASUNNY')
  NetworkOverrideClockTime(12, 0, 0)
  
  DisplayRadar(false)
  
  SetUseHiDof()
  SetTimecycleModifier('')

  
  local groundHash = joaat('prop_ld_planter')
  local ground
  if IsModelInCdimage(groundHash) then
    RequestModel(groundHash)
    local t2 = GetGameTimer()
    while not HasModelLoaded(groundHash) and GetGameTimer()-t2 < 3000 do Wait(0) end
    ground = CreateObject(groundHash, origin.x, origin.y, origin.z - 0.6, false, false, false)
    if ground ~= 0 then
      SetEntityCollision(ground, false, false)
      FreezeEntityPosition(ground, true)
      SetEntityAlpha(ground, 200, false) 
      SetEntityHeading(ground, 0.0)
      SetEntityVisible(ground, true, false)
      SetEntityAsNoLongerNeeded(ground)
    end
  end

  
  Wait(150)

  
  TriggerServerEvent('pt-iconshot:capture', fileName)

  
  local ok = false
  local done = false
  local t0 = GetGameTimer()
  local function handler(success)
    ok = success; done = true
  end
  RegisterNetEvent('pt-iconshot:captureResult', handler)
  while not done and GetGameTimer()-t0 < 5000 do Wait(50) end
  RemoveEventHandler(handler)

  
  RenderScriptCams(false, false, 0, true, false, 0)
  DestroyCam(cam, true)
  DeleteObject(obj)
  if ground and DoesEntityExist(ground) then DeleteObject(ground) end
  SetModelAsNoLongerNeeded(model)
  capturing = false
  return ok, ok and 'ok' or 'timeout'
end

RegisterCommand('iconshot', function(_, args)
  local m = args[1]
  local f = args[2]
  if not m or not f then
    print('Uso: /iconshot <modelName/hash> <fileName.png>')
    return
  end
  local model = tonumber(m) or joaat(m)
  local ok, why = captureModel(model, f)
  print('iconshot result', ok, why)
end)

RegisterNetEvent('pt-iconshot:captureAll')
AddEventHandler('pt-iconshot:captureAll', function(list)
  for _, it in ipairs(list or {}) do
    captureModel(it.model, it.file)
    Wait(200)
  end
end)
