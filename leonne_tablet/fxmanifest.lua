fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'leonne_tablet'
author 'Leonne'
description 'QBCore tablet with ox_inventory and folder-based apps.'
version '1.3.0'

dependency 'qb-core'
dependency 'ox_inventory'
dependency 'vrp'

ui_page 'html/index.html'

shared_scripts { 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts {
    '@vrp/lib/utils.lua',
    'server/main.lua',
    'server/integrations.lua'
}

files {
    'html/index.html', 'html/style.css', 'html/icon.css', 'html/app.js', 'html/judicial-bridge.js',
    'apps/**/index.html', 'apps/**/style.css', 'apps/**/app.js', 'apps/**/icon.*'
}
