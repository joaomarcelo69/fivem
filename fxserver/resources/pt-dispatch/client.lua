local QBCore = exports['qb-core']:GetCoreObject()

local activeCalls = {}

CreateThread(function()
  TriggerEvent('chat:addSuggestion', '/112', 'Pedir assistência às autoridades (PSP/GNR/PJ)', {{ name = 'descrição', help = 'Explique o que aconteceu' }})
  TriggerEvent('chat:addSuggestion', '/mec', 'Chamar um mecânico', {{ name = 'descrição', help = 'Tipo de avaria/localização' }})
  TriggerEvent('chat:addSuggestion', '/taxi', 'Chamar um táxi', {{ name = 'descrição', help = 'Para onde quer ir' }})
  TriggerEvent('chat:addSuggestion', '/reboque', 'Pedir reboque', {{ name = 'descrição', help = 'Localização e veículo' }})
  TriggerEvent('chat:addSuggestion', '/inem', 'Pedir assistência médica (INEM/EMS)', {{ name = 'descrição', help = 'Sintomas/localização' }})
  TriggerEvent('chat:addSuggestion', '/bombeiros', 'Pedir assistência dos Bombeiros', {{ name = 'descrição', help = 'Incêndio/risco/localização' }})
  TriggerEvent('chat:addSuggestion', '/aceitar', 'Aceitar um pedido pendente', {{ name = 'id', help = 'ID do pedido' }})
end)

local function openPromptAndSend(job, presetText)
  local text = presetText
  if (not text or text == '') then
    if lib and lib.inputDialog then
      local msg = lib.inputDialog('Pedido '..(DispatchConfig.jobs[job] and DispatchConfig.jobs[job].label or job), {
        { type = 'input', label = 'Descrição do pedido', required = true },
      })
      if type(msg) == 'table' then text = msg[1] else text = msg end
    else
      
      QBCore.Functions.Notify('Uso: /'..(job == 'police' and '112' or job)..' [descrição]', 'primary')
      return
    end
  end
  if not text or text == '' then return end
  local coords = GetEntityCoords(PlayerPedId())
  TriggerServerEvent('pt-dispatch:server:newCall', job, text, { x = coords.x, y = coords.y, z = coords.z })
  QBCore.Functions.Notify('Pedido enviado para '..(DispatchConfig.jobs[job] and DispatchConfig.jobs[job].label or job)..'.', 'success')
end

RegisterCommand('112', function(_, args)
  openPromptAndSend('police', table.concat(args or {}, ' '))
end)
RegisterCommand('mec', function(_, args)
  openPromptAndSend('mec', table.concat(args or {}, ' '))
end)
RegisterCommand('taxi', function(_, args)
  openPromptAndSend('taxi', table.concat(args or {}, ' '))
end)
RegisterCommand('reboque', function(_, args)
  openPromptAndSend('reboque', table.concat(args or {}, ' '))
end)
RegisterCommand('inem', function(_, args)
  openPromptAndSend('ems', table.concat(args or {}, ' '))
end)
RegisterCommand('bombeiros', function(_, args)
  openPromptAndSend('fire', table.concat(args or {}, ' '))
end)

RegisterNetEvent('pt-dispatch:client:open', function(job)
  openPromptAndSend(job, nil)
end)

local function openServiceMenu()
  if lib and lib.registerContext and lib.showContext then
    lib.registerContext({
      id = 'pt_dispatch_menu',
      title = 'Serviços & SOS',
      options = {
        { title = '112 (PSP/GNR/PJ)', icon = 'shield', onSelect = function() TriggerEvent('pt-dispatch:client:open', 'police') end },
        { title = 'INEM/EMS', icon = 'kit-medical', onSelect = function() TriggerEvent('pt-dispatch:client:open', 'ems') end },
        { title = 'Bombeiros', icon = 'fire-extinguisher', onSelect = function() TriggerEvent('pt-dispatch:client:open', 'fire') end },
        { title = 'Mecânico', icon = 'wrench', onSelect = function() TriggerEvent('pt-dispatch:client:open', 'mec') end },
        { title = 'Reboque', icon = 'truck-pickup', onSelect = function() TriggerEvent('pt-dispatch:client:open', 'reboque') end },
        { title = 'Táxi', icon = 'taxi', onSelect = function() TriggerEvent('pt-dispatch:client:open', 'taxi') end },
      }
    })
    lib.showContext('pt_dispatch_menu')
  else
    QBCore.Functions.Notify('Usa /112, /inem, /mec, /reboque, /taxi (ou instala ox_lib para menu F3).', 'primary')
  end
end

RegisterCommand('dispatchmenu', function()
  openServiceMenu()
end)
RegisterKeyMapping('dispatchmenu', 'Menu de Serviços (SOS/112/INEM/Mec/Taxi/Reboque)', 'keyboard', 'F3')

RegisterNetEvent('pt-dispatch:client:incomingCall', function(callId, job, text, coords, callerId)
  local label = (DispatchConfig.jobs[job] and DispatchConfig.jobs[job].label) or job
  local accepted = false
  if lib and lib.alertDialog then
    local r = lib.alertDialog({
      header = label..' - Novo pedido',
      content = text,
      centered = true,
      cancel = true,
      labels = { confirm = 'Aceitar', cancel = 'Ignorar' }
    })
    accepted = (r == 'confirm')
  else
    
    QBCore.Functions.Notify(('Novo pedido %s: %s (/aceitar %d)'):format(label, text, callId), 'primary')
  end
  if accepted then
    TriggerServerEvent('pt-dispatch:server:accept', callId)
  end
end)

RegisterCommand('aceitar', function(_, args)
  local id = tonumber(args[1] or '')
  if not id then return end
  TriggerServerEvent('pt-dispatch:server:accept', id)
end)

RegisterNetEvent('pt-dispatch:client:startRoute', function(callId, job, coords)
  if activeCalls[callId] and activeCalls[callId].blip then
    RemoveBlip(activeCalls[callId].blip)
  end
  
  local blip = AddBlipForCoord(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
  SetBlipSprite(blip, (DispatchConfig.jobs[job] and DispatchConfig.jobs[job].blip) or 161)
  SetBlipColour(blip, (DispatchConfig.jobs[job] and DispatchConfig.jobs[job].color) or 3)
  SetBlipScale(blip, 1.0)
  SetBlipRoute(blip, true)
  BeginTextCommandSetBlipName('STRING')
  AddTextComponentString('Despacho: '..(DispatchConfig.jobs[job] and DispatchConfig.jobs[job].label or job))
  EndTextCommandSetBlipName(blip)
  SetNewWaypoint(coords.x + 0.0, coords.y + 0.0)
  activeCalls[callId] = { blip = blip }
  QBCore.Functions.Notify('Rota definida no GPS.', 'success')
end)

RegisterNetEvent('pt-dispatch:client:clear', function(callId)
  if activeCalls[callId] and activeCalls[callId].blip then
    RemoveBlip(activeCalls[callId].blip)
  end
  activeCalls[callId] = nil
end)
