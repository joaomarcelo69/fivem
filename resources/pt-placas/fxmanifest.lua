fx_version 'cerulean'
game 'gta5'

name 'pt-placas'
author 'PT Server Toolkit'
version '0.1.0'

description 'Matrículas PT: geração AA-00-AA, reserva e registo em DB'

server_only 'yes'

server_scripts {
  'server.lua'
}

exports {
  'GeneratePlate',
  'ReservePlate'
}
