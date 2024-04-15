local config = require 'config.client'
local sharedConfig = require 'config.shared'
CurrentThermiteGate = 0
CurrentCops = 0
local closestBank = 0
local inElectronickitZone = false
local copsCalled = false
local refreshed = false
local currentLocker = 0

--- This is triggered once the hack at a small bank is done
--- @param success boolean
--- @return nil
local function onHackDone(success)
    TriggerEvent('mhacking:hide')
    if not success then return end
    TriggerServerEvent('qbx_bankrobbery:server:setBankState', closestBank)
end

RegisterNetEvent('electronickit:UseElectronickit', function()
    DropFingerprint()

    if closestBank == 0 or not inElectronickitZone then return end

    local isBusy = lib.callback.await('qbx_bankrobbery:server:isRobberyActive', false)
    if isBusy then return exports.qbx_core:Notify(locale('error.security_lock_active'), 'error', 5500) end

    if CurrentCops < config.minFleecaPolice then return exports.qbx_core:Notify(locale('error.minimum_police_required', {police = config.minFleecaPolice}), 'error') end
    if sharedConfig.smallBanks[closestBank].isOpened then return exports.qbx_core:Notify(locale('error.bank_already_open'), 'error') end

    local hasItems = (exports.ox_inventory:Search('count', 'trojan_usb') > 0) and (exports.ox_inventory:Search('count', 'electronickit') > 0)
    if not hasItems then return exports.qbx_core:Notify(locale('error.missing_item'), 'error') end

    if lib.progressBar({
        duration = 7500,
        label = locale('general.connecting_hacking_device'),
        canCancel = true,
        useWhileDead = false,
        disable = {
            move = true,
            car = true,
            mouse = false,
            combat = true
        },
        anim = {
            dict = 'anim@gangops@facility@servers@',
            clip = 'hotwire',
            flag = 1
        }
    }) then
        TriggerServerEvent('qbx_bankrobbery:server:removeElectronicKit')
        TriggerEvent('mhacking:show')
        TriggerEvent('mhacking:start', math.random(6, 7), math.random(15, 30), onHackDone)
        if copsCalled or not sharedConfig.smallBanks[closestBank].alarm then return end
        TriggerServerEvent('qbx_bankrobbery:server:callCops', 'small', closestBank, sharedConfig.smallBanks[closestBank].coords)
        copsCalled = true
        SetTimeout(60000 * config.outlawCooldown, function() copsCalled = false end)
    else
        exports.qbx_core:Notify(locale('error.cancel_message'), 'error')
    end
end)

RegisterNetEvent('qbx_bankrobbery:client:enableAllBankSecurity', function()
    for k in pairs(sharedConfig.smallBanks) do
        sharedConfig.smallBanks[k].alarm = true
    end
end)

RegisterNetEvent('qbx_bankrobbery:client:disableAllBankSecurity', function()
    for k in pairs(sharedConfig.smallBanks) do
        sharedConfig.smallBanks[k].alarm = false
    end
end)

RegisterNetEvent('qbx_bankrobbery:client:BankSecurity', function(key, status)
    if type(key) == 'table' and table.type(key) == 'array' then
        for _, v in pairs(key) do
            sharedConfig.smallBanks[v].alarm = status
        end
    elseif type(key) == 'number' then
        sharedConfig.smallBanks[key].alarm = status
    else
        error(locale('error.wrong_type', {receiver = 'qbx_bankrobbery:client:BankSecurity', argument = 'key', receivedType = type(key), receivedValue = key, expected = 'table/array'}))
    end
end)

RegisterNetEvent('qbx_bankrobbery:client:ResetFleecaLockers', function(BankId)
    sharedConfig.smallBanks[BankId].isOpened = false
    for k in pairs(sharedConfig.smallBanks[BankId].lockers) do
        sharedConfig.smallBanks[BankId].lockers[k].isOpened = false
        sharedConfig.smallBanks[BankId].lockers[k].isBusy = false
    end
end)

CreateThread(function()
    while true do
        if closestBank ~= 0 then
            if not refreshed then
                ResetBankDoors()
                refreshed = true
            end
        else
            refreshed = false
        end
        Wait(1000)
    end
end)

CreateThread(function()
    while true do -- This is kept for the ResetBankDoors function to be executed outside of the polyzone
        local pos = GetEntityCoords(cache.ped)
        local inRange = false
        if isLoggedIn then
            for k, v in pairs(sharedConfig.smallBanks) do
                local dist = #(pos - v.coords)
                if dist < 15 then
                    closestBank = k
                    inRange = true
                end
            end
            if not inRange then closestBank = 0 end
        end
        Wait(1000)
    end
end)

CreateThread(function()
    for i = 1, #sharedConfig.smallBanks do
        lib.zones.box({
            name = 'fleeca_'..i..'_coords_electronickit',
            coords = sharedConfig.smallBanks[i].coords,
            size = vec3(1, 1, 2),
            rotation = sharedConfig.smallBanks[i].coords.closed,
            debug = config.debugPoly,
            onEnter = function()
                inElectronickitZone = true
            end,
            onExit = function()
                inElectronickitZone = false
            end,
        })
        for k in pairs(sharedConfig.smallBanks[i].lockers) do
            if config.useTarget then
                exports.ox_target:addBoxZone({
                    coords = sharedConfig.smallBanks[i].lockers[k].coords,
                    size = vec3(1, 1, 2),
                    rotation = sharedConfig.smallBanks[i].heading.closed,
                    debug = config.debugPoly,
                    drawSprite = true,
                    options = {
                        {
                            label = locale('general.break_safe_open_option_target'),
                            name = 'fleeca_'..i..'_coords_locker_'..k,
                            icon = 'fa-solid fa-vault',
                            distance = 1.5,
                            canInteract = function()
                                return closestBank ~= 0 and not isDrilling and sharedConfig.smallBanks[i].isOpened and not sharedConfig.smallBanks[i].lockers[k].isOpened and not sharedConfig.smallBanks[i].lockers[k].isBusy
                            end,
                            onSelect = function()
                                OpenLocker(closestBank, k)
                            end,
                        },
                    },
                })
            else
                lib.zones.box({
                    name = 'fleeca_'..i..'_coords_locker_'..k,
                    coords = sharedConfig.smallBanks[i].lockers[k].coords,
                    size = vec3(1, 1, 2),
                    rotation = sharedConfig.smallBanks[i].heading.closed,
                    debug = config.debugPoly,
                    onEnter = function()
                        if closestBank ~= 0 and not isDrilling and sharedConfig.smallBanks[i].isOpened and not sharedConfig.smallBanks[i].lockers[k].isOpened and not sharedConfig.smallBanks[i].lockers[k].isBusy then
                            lib.showTextUI(locale('general.break_safe_open_option_drawtext'), {position = 'right-center'})
                            currentLocker = k
                        end
                    end,
                    onExit = function()
                        if currentLocker == k then
                            currentLocker = 0
                            lib.hideTextUI()
                        end
                    end,
                })
            end
        end
    end
    if not config.useTarget then
        while true do
            local sleep = 1000
            if isLoggedIn then
                for i = 1, #sharedConfig.smallBanks do
                    if currentLocker ~= 0 and not isDrilling and sharedConfig.smallBanks[i].isOpened and not sharedConfig.smallBanks[i].lockers[currentLocker].isOpened and not sharedConfig.smallBanks[i].lockers[currentLocker].isBusy then
                        sleep = 0
                        if IsControlJustPressed(0, 38) then
                            lib.hideTextUI()
                            Wait(500)
                            if CurrentCops >= config.minFleecaPolice then
                                OpenLocker(closestBank, currentLocker)
                            else
                                exports.qbx_core:Notify(locale('error.minimum_police_required', {police = config.minFleecaPolice}), 'error')
                            end
                            sleep = 1000
                        end
                    end
                end
            end
            Wait(sleep)
        end
    end
end)
