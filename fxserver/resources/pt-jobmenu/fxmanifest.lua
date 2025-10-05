fx_version 'cerulean'
game 'gta5'

name 'pt-jobmenu'
author 'PT Server Toolkit'
version '0.1.0'

description 'Menus por emprego (polícia, EMS, etc) com NUI e permissões por hierarquia'

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
