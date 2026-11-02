fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name        'fraktion_manager'
description 'FiveM Integration für Fraktion Manager'
version     '2.0.0'
author      'Fraktion Manager'
repository  'https://github.com/blokify11/fraktion-manager-fivem'

shared_scripts {
    'config.lua',
}

server_scripts {
    'server.lua',
}

client_scripts {
    'client.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
}

dependencies {
    'es_extended',
}
