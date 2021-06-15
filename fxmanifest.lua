fx_version 'bodacious'
game 'gta5'

author 'POGO#0644'
version '1.0.0'

--[[ RageUI ]]
client_scripts {
    "src/RMenu.lua",
    "src/menu/RageUI.lua",
    "src/menu/Menu.lua",
    "src/menu/MenuController.lua",
    "src/components/*.lua",
    "src/menu/elements/*.lua",
    "src/menu/items/*.lua",
    "src/menu/panels/*.lua",
    "src/menu/panels/*.lua",
    "src/menu/windows/*.lua",
}

server_script '@mysql-async/lib/MySQL.lua'

client_script 'cl_*.lua'
server_script 'sv_*.lua'
shared_script 'sh_*.lua'
