fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'
author 'CeebDev'

version '1.0.0'
description 'Create, delete and visualize groups for ox_core with ox_lib'

shared_script { "@ox_lib/init.lua", "@ox_core/lib/init.lua" }
client_scripts { "client/*.lua" }
server_scripts { "@oxmysql/lib/MySQL.lua", "server/*.lua" }
