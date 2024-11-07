fx_version "cerulean"
game "gta5"

author "Tizas"
description "A simple & optimised solution for banking."
version "1.0"
lua54 'yes'

client_scripts {
    "client/main.lua"
}

server_scripts {
    "server/main.lua",
    '@oxmysql/lib/MySQL.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qtm-lib/imports.lua',
    "shared/config.lua",
    "shared/locales.lua",
}

files {
    "html/*",
    "html/assets/*",
    "html/img/*",
    "html/index.html"
}

ui_page "html/index.html"