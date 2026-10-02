fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'reborn_judicial'
author 'Codex'
description 'Registro inicial de processos judiciais com notificacoes via Discord.'
version '0.1.0'

dependency 'vrp'

shared_script 'config.lua'
server_scripts {
    '@vrp/lib/utils.lua',
    'server.lua'
}
