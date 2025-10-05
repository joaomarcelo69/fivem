fx_version 'cerulean'
game 'gta5'

name 'pt-commerce'
author 'PT Server Toolkit'
version '0.1.0'

description 'E-commerce tipo "Amazon" com entregas CTT e caixa de correio por jogador'

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
