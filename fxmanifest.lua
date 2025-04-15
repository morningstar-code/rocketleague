-- fxmanifest.lua

fx_version 'cerulean'
game 'gta5'

author 'YourNameHere'
description 'Rocket League-Style Minigame for FiveM (1v1)'

version '1.0.0'

-- Shared config
shared_script 'config.lua'

-- Server
server_script 'server.lua'

-- Client
client_script 'client.lua'

-- UI (NUI)
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/sounds/*.mp3',
    'html/fonts/*.ttf',
    'html/images/*.png'
}
