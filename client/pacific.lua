local config = require 'config.client'
local pacificConfig = require 'config.shared'.bigBanks.pacific
local inBankCardBZone = false
local inElectronickitZone = false
local currentLocker = 0
local copsCalled = false

--- This will be triggered once the hack in the pacific bank is done
--- @param success boolean
--- @return nil
local function onHackPacificDone(success)
    TriggerEvent('mhacking:hide')
    if not success then return end
    TriggerServerEvent('qbx_bankrobbery:server:setBankState', 'pacific')
end

RegisterNetEvent('qbx_bankrobbery:UseBankcardB', function()
    DropFingerprint()

    if not inBankCardBZone then return end

    local isBusy = lib.callback.await('qbx_bankrobbery:server:isRobberyActive', false)
    if isBusy then return exports.qbx_core:Notify(locale('error.security_lock_active'), 'error', 5500) end

    if CurrentCops < config.minPacificPolice then return exports.qbx_core:Notify(locale('error.minimum_police_required', {police = config.minPacificPolice}), 'error') end
    if pacificConfig.isOpened then return exports.qbx_core:Notify(locale('error.bank_already_open'), 'error') end

    if lib.progressBar({
        duration = 7500,
        label = locale('general.validating_bankcard'),
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
        TriggerServerEvent('qbx_bankrobbery:server:removeBankCard', '02')
        TriggerServerEvent('qbx_bankrobbery:server:OpenGate', 6, false)
        if copsCalled or not pacificConfig.alarm then return end
        TriggerServerEvent('qbx_bankrobbery:server:callCops', 'pacific', 0, pacificConfig.coords)
        copsCalled = true
    else
        exports.qbx_core:Notify(locale('error.cancel_message'), 'error')
    end
end)

RegisterNetEvent('electronickit:UseElectronickit', function()
    local pos = GetEntityCoords(cache.ped)
    if not inElectronickitZone then return end
    local isBusy = lib.callback.await('qbx_bankrobbery:server:isRobberyActive', false)
    if not isBusy then
        if CurrentCops >= config.minPacificPolice then
            if not pacificConfig.isOpened then
                local hasItems = (exports.ox_inventory:Search('count', 'trojan_usb') > 0) and (exports.ox_inventory:Search('count', 'electronickit') > 0)
                if hasItems then
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
                        TriggerEvent('mhacking:show')
                        TriggerEvent('mhacking:start', math.random(5, 9), math.random(15, 30), onHackPacificDone)
                        if copsCalled or not pacificConfig.alarm then return end
                        TriggerServerEvent('qbx_bankrobbery:server:callCops', 'pacific', 0, pos)
                        copsCalled = true
                    else
                        exports.qbx_core:Notify(locale('error.cancel_message'), 'error')
                    end
                else
                    exports.qbx_core:Notify(locale('error.missing_item'), 'error')
                end
            else
                exports.qbx_core:Notify(locale('error.bank_already_open'), 'error')
            end
        else
            exports.qbx_core:Notify(locale('error.minimum_police_required', {police = config.minPacificPolice}), 'error')
        end
    else
        exports.qbx_core:Notify(locale('error.security_lock_active'), 'error', 5500)
    end
end)

-- Threads

CreateThread(function()
    lib.zones.box({
        name = 'pacific_coords_bankcardb',
        coords = pacificConfig.coords[1],
        size = vec3(1, 1, 2),
        rotation = pacificConfig.heading.closed,
        debug = config.debugPoly,
        onEnter = function()
            inBankCardBZone = true
        end,
        onExit = function()
            inBankCardBZone = false
        end
    })
    lib.zones.box({
        name = 'pacific_coords_electronickit',
        coords = pacificConfig.coords[2],
        size = vec3(1, 1, 2),
        rotation = pacificConfig.heading.closed,
        debug = config.debugPoly,
        onEnter = function()
            inElectronickitZone = true
        end,
        onExit = function()
            inElectronickitZone = false
        end
    })
    lib.zones.box({
        name = 'pacific_coords_thermite_1',
        coords = pacificConfig.thermite[1].coords,
        size = vec3(1, 1, 2),
        rotation = pacificConfig.heading.closed,
        debug = config.debugPoly,
        onEnter = function()
            if not pacificConfig.thermite[1].isOpened then
                CurrentThermiteGate = pacificConfig.thermite[1].doorId
            end
        end,
        onExit = function()
            if CurrentThermiteGate == pacificConfig.thermite[1].doorId then
                CurrentThermiteGate = 0
            end
        end,
    })
    lib.zones.box({
        name = 'pacific_coords_thermite_2',
        coords = pacificConfig.thermite[2].coords,
        size = vec3(1, 1, 2),
        rotation = pacificConfig.heading.closed,
        debug = config.debugPoly,
        onEnter = function()
            if not pacificConfig.thermite[2].isOpened then
                CurrentThermiteGate = pacificConfig.thermite[2].doorId
            end
        end,
        onExit = function()
            if CurrentThermiteGate == pacificConfig.thermite[2].doorId then
                CurrentThermiteGate = 0
            end
        end,
    })
    for k in pairs(pacificConfig.lockers) do
        if config.useTarget then
            exports.ox_target:addBoxZone({
                coords = pacificConfig.lockers[k].coords,
                size = vec3(1, 1, 2),
                rotation = pacificConfig.heading.closed,
                debug = config.debugPoly,
                drawSprite = true,
                options = {
                    {
                        label = locale('general.break_safe_open_option_target'),
                        name = 'pacific_coords_locker_'..k,
                        icon = 'fa-solid fa-vault',
                        distance = 1.5,
                        canInteract = function()
                            return not isDrilling and pacificConfig.isOpened and not pacificConfig.lockers[k].isBusy and not pacificConfig.lockers[k].isOpened
                        end,
                        onSelect = function()
                            OpenLocker('pacific', k)
                        end,
                    },
                },
            })
        else
            lib.zones.box({
                name = 'pacific_coords_locker_'..k,
                coords = pacificConfig.lockers[k].coords,
                size = vec3(1, 1, 2),
                rotation = pacificConfig.heading.closed,
                debug = config.debugPoly,
                onEnter = function()
                    if not isDrilling and pacificConfig.isOpened and not pacificConfig.lockers[k].isBusy and not pacificConfig.lockers[k].isOpened then
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
    if not config.useTarget then
        while true do
            local sleep = 1000
            if isLoggedIn then
                if currentLocker ~= 0 and not isDrilling and pacificConfig.isOpened and not pacificConfig.lockers[currentLocker].isBusy and not pacificConfig.lockers[currentLocker].isOpened then
                    sleep = 0
                    if IsControlJustPressed(0, 38) then
                        lib.hideTextUI()
                        Wait(500)
                        if CurrentCops >= config.minPacificPolice then
                            OpenLocker('pacific', currentLocker)
                        else
                            exports.qbx_core:Notify(locale('error.minimum_police_required', {police = config.minPacificPolice}), 'error')
                        end
                        sleep = 1000
                    end
                end
            end
            Wait(sleep)
        end
    end
end)
