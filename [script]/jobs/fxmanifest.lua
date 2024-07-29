fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Korioz'
description 'Roleplay personal menu supporting ESX'
version '2.3'

dependency 'es_extended'

shared_scripts {
    'config.lua',
   '@es_extended/imports.lua',

}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/server.lua'
}

client_scripts {
    "dependencies/menu/RageUI.lua",
    "dependencies/menu/Menu.lua",
    "dependencies/menu/MenuController.lua",

    "dependencies/menu/elements/*.lua",
    "dependencies/menu/items/*.lua",

    'client/client.lua',

}
