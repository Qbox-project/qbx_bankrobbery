local config = require 'config.client'
local paletoConfig = require 'config.shared'.bigBanks.paleto
local inBankCardAZone = false
local currentLocker = 0
local copsCalled = false

RegisterNetEvent('qbx_bankrobbery:UseBankcardA', function()
    DropFingerprint()

    if not inBankCardAZone then return end

    local isBusy = lib.callback.await('qbx_bankrobbery:server:isRobberyActive', false)
    if isBusy then return exports.qbx_core:Notify(locale('error.security_lock_active'), 'error', 5500) end

    if CurrentCops < config.minPaletoPolice then return exports.qbx_core:Notify(locale('error.minimum_police_required', {police = config.minPaletoPolice}), 'error') end
    if paletoConfig.isOpened then return exports.qbx_core:Notify(locale('error.bank_already_open'), 'error') end

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
    }) then -- if completed
        TriggerServerEvent('qbx_bankrobbery:server:setBankState', 'paleto')
        TriggerServerEvent('qbx_bankrobbery:server:removeBankCard', '01')

        if copsCalled or not paletoConfig.alarm then return end
        TriggerServerEvent('qbx_bankrobbery:server:callCops', 'paleto', 0, paletoConfig.coords)
        copsCalled = true
    else -- if canceled
        exports.qbx_core:Notify(locale('error.cancel_message'), 'error')
    end
end)

-- Threads

CreateThread(function()
    lib.zones.box({
        name = 'paleto_coords_bankcarda',
        coords = paletoConfig.coords,
        size = vec3(1, 1, 2),
        rotation = paletoConfig.heading.closed,
        debug = config.debugPoly,
        onEnter = function()
            inBankCardAZone = true
        end,
        onExit = function()
            inBankCardAZone = false
        end
    })
    lib.zones.box({
        name = 'paleto_coords_thermite_1',
        coords = paletoConfig.thermite[1].coords,
        size = vec3(1, 1, 2),
        rotation = paletoConfig.heading.closed,
        debug = config.debugPoly,
        onEnter = function()
            if not paletoConfig.thermite[1].isOpened then
                CurrentThermiteGate = paletoConfig.thermite[1].doorId
            end
        end,
        onExit = function()
            if CurrentThermiteGate == paletoConfig.thermite[1].doorId then
                CurrentThermiteGate = 0
            end
        end,
    })
    for k in pairs(paletoConfig.lockers) do
        if config.useTarget then
            exports.ox_target:addBoxZone({
                coords = paletoConfig.lockers[k].coords,
                size = vec3(1, 1, 2),
                rotationg = paletoConfig.heading.closed,
                debug = config.debugPoly,
                drawSprite = true,
                options = {
                    {
                        label = locale('general.break_safe_open_option_target'),
                        name = 'paleto_coords_locker_'..k,
                        icon = 'fa-solid fa-vault',
                        distance = 1.5,
                        canInteract = function()
                            return not isDrilling and paletoConfig.isOpened and not paletoConfig.lockers[k].isBusy and not paletoConfig.lockers[k].isopened
                        end,
                        onSelect = function()
                            OpenLocker('paleto', k)
                        end,
                    },
                },
            })
        else
            lib.zones.box({
                name = 'paleto_coords_locker_'..k,
                coords = paletoConfig.lockers[k].coords,
                size = vec3(1, 1, 2),
                rotation = paletoConfig.heading.closed,
                debug = config.debugPoly,
                onEnter = function()
                    if not isDrilling and paletoConfig.isOpened and not paletoConfig.lockers[k].isBusy and not paletoConfig.lockers[k].isopened then
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
                if currentLocker ~= 0 and not isDrilling and paletoConfig.isOpened and not paletoConfig.lockers[currentLocker].isBusy and not paletoConfig.lockers[currentLocker].isOpened then
                    sleep = 0
                    if IsControlJustPressed(0, 38) then
                        lib.hideTextUI()
                        Wait(500)
                        if CurrentCops >= config.minPaletoPolice then
                            OpenLocker('paleto', currentLocker)
                        else
                            exports.qbx_core:Notify(locale('error.minimum_police_required', {police = config.minPaletoPolice}), 'error')
                        end
                        sleep = 1000
                    end
                end
            end
            Wait(sleep)
        end
    end
end)
