fx_version 'cerulean'
game 'gta5'

name 'pt-health'
author 'PT Server Toolkit'
version '0.1.0'

server_only 'yes'

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server.lua'
}
