local Translations = {
    text = {
        take_cashstack = '~g~E~w~ - Take Cash',
        crack_locker = '~g~E~w~ - Crack locker'
    },
    notify = {
        bank_active = 'All security systems are on ultra lockdown!',
        no_police = 'There aren\'t enough police around (%{Required} Required)',
        missing_item = 'You are missing something',
        failed_doorhack = 'Better luck next time',
        door_open = 'Door has already been opened'
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
