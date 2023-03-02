fx_version 'cerulean'
game 'gta5'

description 'https://github.com/Qbox-project/qb-bankrobbery'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}
server_scripts {
    'server/main.lua',
    'server/fleeca.lua',
}

lua54 'yes'
