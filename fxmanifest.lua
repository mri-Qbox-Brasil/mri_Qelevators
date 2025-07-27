fx_version 'cerulean'
game 'gta5'

name 'mri_Qelevators'
author 'mri'
version '2.0.0'
description 'Sistema de elevadores avançado para FiveM'

dependencies {
    'ox_lib',
    'oxmysql'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/utils.lua',
    'client/elevator.lua',
    'client/menu.lua',
    'client/events.lua',
    'client/creator.lua',
}

server_scripts {
    'server/utils.lua',
    'server/database.lua',
    'server/events.lua',
    'server/commands.lua'
}

files {
    'client/*.lua',
    'data/*.lua'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
