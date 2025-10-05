fx_version 'cerulean'
game 'gta5'

name 'pt-housing'
author 'PT Server Toolkit'
version '0.1.0'

description 'Sistema de habitação: múltiplas casas por jogador, comprar/vender, arrendar, mailbox e integrações'

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/app.js',
  'html/style.css'
}

shared_scripts {
  'config.lua'
}

client_scripts {
  'client.lua'
}

server_scripts {
  'server.lua'
}
