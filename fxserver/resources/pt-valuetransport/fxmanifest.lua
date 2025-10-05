fx_version 'cerulean'
game 'gta5'

author 'RP Portugal'
description 'Transporte de valores realista PT'
version '1.0.0'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

client_scripts {
    'client.lua'
}

shared_scripts {
    'config.lua'
}

dependency 'qb-core'
dependency 'qb-phone'
