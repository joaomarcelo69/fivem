fx_version 'cerulean'
game 'gta5'

name 'pt-vehicle-docs'
author 'PT Server Toolkit'
version '0.1.0'

description 'Registo, seguro e inspeção de veículos com verificação em paragem STOP'

shared_scripts {
  'config.lua'
}

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/app.js',
  'html/style.css'
}

client_scripts {
  'client.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server.lua'
}
