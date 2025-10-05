local QBCore = exports['qb-core']:GetCoreObject()

local function calcFine(kmhOver, limit, zone)
  
  local base
  if kmhOver <= 10 then base = 60
  elseif kmhOver <= 20 then base = 120
  elseif kmhOver <= 30 then base = 240
  elseif kmhOver <= 40 then base = 400
  elseif kmhOver <= 60 then base = 600
  else base = 1000 end
  if zone == 'Urbana' and kmhOver >= 30 then base = base + 150 end
  return base
end

RegisterNetEvent('pt-speedcams:server:overspeed')
AddEventHandler('pt-speedcams:server:overspeed', function(camId, plate, speed, limit)
  local src = source
  local P = QBCore.Functions.GetPlayer(src)
  if not P then return end
  local kmhOver = math.max(0, (tonumber(speed) or 0) - (tonumber(limit) or 0))
  local cam = SpeedCamsConfig.cameras[tonumber(camId) or 1] or {}
  local fine = calcFine(kmhOver, limit, cam.zone)
  local citizenid = P.PlayerData.citizenid
  
  if TriggerEvent then
    TriggerEvent('pt-multas:emitir', citizenid, fine, ('Excesso de velocidade (%dkm/h em zona %d)'):format(speed, limit))
  end
  
  TriggerEvent('qb-phone:server:sendNewMail', {
    sender = 'Radar',
    subject = 'Aviso de excesso de velocidade',
    message = ('Foi detetado a %dkm/h numa zona %dkm/h. Multa: %d€'):format(speed, limit, fine),
    button = {}
  })
end)
