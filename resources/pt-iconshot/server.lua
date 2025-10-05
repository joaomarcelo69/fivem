local OUTPUTS = { 'out' }

-- Utilidade para salvar via screenshot-basic (se existir)
local function hasScreenshot() return GetResourceState('screenshot-basic') == 'started' end

RegisterNetEvent('pt-iconshot:capture')
AddEventHandler('pt-iconshot:capture', function(fileName)
  local src = source
  if not fileName or fileName == '' then fileName = 'icon.png' end
  if hasScreenshot() then
    exports['screenshot-basic']:requestClientScreenshot(src, { encoding = 'png', quality = 100 }, function(data)
      if not data then
        TriggerClientEvent('pt-iconshot:captureResult', src, false)
        return
      end
      for _, outDir in ipairs(OUTPUTS) do
        local rel = outDir .. '/' .. fileName
        SaveResourceFile(GetCurrentResourceName(), rel, data, -1)
      end
      -- se qb-inventory estiver presente, também tentar gravar diretamente na pasta de imagens (quando rodando no mesmo FS)
      local invRel1 = '../qb-inventory/html/images/' .. fileName
      local invRel2 = '../../fxserver/resources/qb-inventory/html/images/' .. fileName
      -- Tenta ambos os caminhos relativos mais comuns deste workspace
      SaveResourceFile(GetCurrentResourceName(), invRel1, data, -1)
      SaveResourceFile(GetCurrentResourceName(), invRel2, data, -1)
      TriggerClientEvent('pt-iconshot:captureResult', src, true)
    end)
  else
    print('[pt-iconshot] screenshot-basic não está ativo; instala/garante ensure screenshot-basic para capturar imagens reais.')
    TriggerClientEvent('pt-iconshot:captureResult', src, false)
  end
end)

QBCore = QBCore or (exports['qb-core'] and exports['qb-core']:GetCoreObject())

RegisterCommand('iconshot_all', function(source)
  if source ~= 0 then
    -- Permissões via ACE ou QBCore
    if not IsPlayerAceAllowed(source, 'pticonshot.capture') and not IsPlayerAceAllowed(source, 'command') then
      if QBCore then
        local P = QBCore.Functions.GetPlayer(source)
        if not P or (not P.PlayerData or not (P.PlayerData.job and (P.PlayerData.job.name == 'admin' or P.PlayerData.job.name == 'police')) ) then
          TriggerClientEvent('QBCore:Notify', source, 'Apenas staff.', 'error')
          return
        end
      end
    end
    -- enviar só para o jogador que invocou
    TriggerClientEvent('pt-iconshot:captureAll', source, IconShot.Models or {})
  else
    -- invocado pelo console: envia para todos
    TriggerClientEvent('pt-iconshot:captureAll', -1, IconShot.Models or {})
  end
end, false)

exports('GetOutputDir', function()
  return OUTPUTS[1]
end)
