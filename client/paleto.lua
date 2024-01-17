local config = require 'config.client'
local paletoConfig = require 'config.shared'.bigBanks.paleto
local inBankCardAZone = false
local currentLocker = 0
local copsCalled = false
local currentCops = 0

RegisterNetEvent('qb-bankrobbery:UseBankcardA', function()
    DropFingerprint()

    if not inBankCardAZone then return end

    local isBusy = lib.callback.await('qb-bankrobbery:server:isRobberyActive', false)
    if isBusy then return exports.qbx_core:Notify(Lang:t('error.security_lock_active'), 'error', 5500) end

    currentCops = exports.qbx_core:GetDutyCountType('leo')
    if currentCops < config.minPaletoPolice then return exports.qbx_core:Notify(Lang:t('error.minimum_police_required', {police = config.minPaletoPolice}), 'error') end
    if paletoConfig.isOpened then return exports.qbx_core:Notify(Lang:t('error.bank_already_open'), 'error') end

    if lib.progressBar({
        duration = 7500,
        label = Lang:t('general.validating_bankcard'),
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
        TriggerServerEvent('qb-bankrobbery:server:setBankState', 'paleto')
        TriggerServerEvent('qb-bankrobbery:server:removeBankCard', '01')

        if copsCalled or not paletoConfig.alarm then return end
        TriggerServerEvent('qb-bankrobbery:server:callCops', 'paleto', 0, paletoConfig.coords)
        copsCalled = true
    else -- if canceled
        exports.qbx_core:Notify(Lang:t('error.cancel_message'), 'error')
    end
end)

-- Threads

CreateThread(function()
    lib.zones.box({
        name = 'paleto_coords_bankcarda',
        coords = paletoConfig.coords,
        size = vec3(1, 1, 2),
        rotation = paletoConfig.heading.closed,
        debug = false,
    })
    lib.zones.box({
        name = 'paleto_coords_thermite_1',
        coords = paletoConfig.thermite[1].coords,
        size = vec3(1, 1, 2),
        rotation = paletoConfig.heading.closed,
        debug = false,
        onEnter = function()
            if not paletoConfig.thermite[1].isOpened then
                currentThermiteGate = paletoConfig.thermite[1].doorId
                -- Config.ShowRequiredItems({
                --     [1] = {name = exports.ox_inventory:Items().thermite.name, image = exports.ox_inventory:Items().thermite.image},
                -- }, true)
            end
        end,
        onExit = function()
            if currentThermiteGate == paletoConfig.thermite[1].doorId then
                currentThermiteGate = 0
                -- Config.ShowRequiredItems({
                --     [1] = {name = exports.ox_inventory:Items().thermite.name, image = exports.ox_inventory:Items().thermite.image},
                -- }, false)
            end
        end,
    })
    for k in pairs(paletoConfig.lockers) do
        if config.useTarget then
            exports.ox_target:addBoxZone({
                coords = paletoConfig.lockers[k].coords,
                size = vec3(1, 1, 2),
                rotationg = paletoConfig.heading.closed,
                debug = false,
                drawSprite = true,
                options = {
                    {
                        label = Lang:t('general.break_safe_open_option_target'),
                        name = 'paleto_coords_locker_'..k,
                        icon = 'fa-solid fa-vault',
                        distance = 1.5,
                        canInteract = function()
                            return not isDrilling and paletoConfig.isOpened and not paletoConfig.lockers[k].isBusy and not paletoConfig.lockers[k].isopened
                        end,
                        onSlect = function()
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
                debug = false,
                onEnter = function()
                    if not isDrilling and paletoConfig.isOpened and not paletoConfig.lockers[k].isBusy and not paletoConfig.lockers[k].isopened then
                        lib.showTextUI(Lang:t('general.break_safe_open_option_drawtext'), {position = 'right-center'})
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
                        exports.qbx_core:KeyPressed()
                        Wait(500)
                        lib.hideTextUI()
                        if currentCops >= config.minPaletoPolice then
                            OpenLocker('paleto', currentLocker)
                        else
                            exports.qbx_core:Notify(Lang:t('error.minimum_police_required', {police = config.minPaletoPolice}), 'error')
                        end
                        sleep = 1000
                    end
                end
            end
            Wait(sleep)
        end
    end
end)
