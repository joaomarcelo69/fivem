local function showTicket(info)
  local reason = info.reason or 'Motivo não especificado'
  local amount = info.amount or 0
  local officer = info.officer or 'Desconhecido'
  local fineId = info.fine_id or 0
  local issued_at = info.issued_at or ''
  
  BeginTextCommandThefeedPost('STRING')
  AddTextComponentSubstringPlayerName(('~b~Talão de Multa~s~\nID: %s\nValor: ~g~%s€~s~\nMotivo: %s\nAgente: %s\nData: %s'):format(tostring(fineId), tostring(amount), reason, officer, issued_at))
  EndTextCommandThefeedPostTicker(false, false)
end

RegisterNetEvent('pt-multas:client:showTicket', function(info)
  showTicket(info or {})
end)
