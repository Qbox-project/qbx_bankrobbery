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
    TriggerServerEvent('qb-bankrobbery:server:setBankState', 'pacific')
end

RegisterNetEvent('qb-bankrobbery:UseBankcardB', function()
    local pos = GetEntityCoords(cache.ped)
    if math.random(1, 100) > 85 or IsWearingGloves() then return end
    TriggerServerEvent('evidence:server:CreateFingerDrop', pos)
    if not inBankCardBZone then return end
    local isBusy = lib.callback.await('qb-bankrobbery:server:isRobberyActive', false)
    if not isBusy then
        if CurrentCops >= config.minPacificPolice then
            if not pacificConfig.isOpened then
                -- Config.ShowRequiredItems({
                --     [1] = {name = exports.ox_inventory:Items().security_card_02.name, image = exports.ox_inventory:Items().security_card_02.image}
                -- }, false)
                lib.requestAnimDict('anim@gangops@facility@servers@')
                TaskPlayAnim(cache.ped, 'anim@gangops@facility@servers@', 'hotwire', 3.0, 3.0, -1, 1, 0, false, false, false)
                if lib.progressBar({
                    duration = 75000,
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
                }) then
                    --Config.DoorlockAction(1, false)
                    TriggerServerEvent('qb-bankrobbery:server:removeBankCard', '02')
                    if copsCalled or not pacificConfig.alarm then return end
                    TriggerServerEvent('qb-bankrobbery:server:callCops', 'pacific', 0, pos)
                    copsCalled = true
                else
                    exports.qbx_core:Notify(Lang:t('error.cancel_message'), 'error')
                end
            else
                exports.qbx_core:Notify(Lang:t('error.bank_already_open'), 'error')
            end
        else
            exports.qbx_core:Notify(Lang:t('error.minimum_police_required', {police = config.minPacificPolice}), 'error')
        end
    else
        exports.qbx_core:Notify(Lang:t('error.security_lock_active'), 'error', 5500)
    end
end)

RegisterNetEvent('electronickit:UseElectronickit', function()
    local pos = GetEntityCoords(cache.ped)
    if not inElectronickitZone then return end
    local isBusy = lib.callback.await('qb-bankrobbery:server:isRobberyActive', false)
    if not isBusy then
        if CurrentCops >= config.minPacificPolice then
            if not pacificConfig.isOpened then
                local hasItem = HasItem({'trojan_usb', 'electronickit'})
                if hasItem then
                    -- Config.ShowRequiredItems(nil, false)
                    -- lib.requestAnimDict('anim@gangops@facility@servers@')
                    -- TaskPlayAnim(ped, 'anim@gangops@facility@servers@', 'hotwire', 3.0, 3.0, -1, 1, 0, false, false, false)
                    if lib.progressBar({
                        duration = 7500,
                        label = Lang:t('general.breaking_open_safe'),
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
                        StopAnimTask(cache.ped, 'anim@gangops@facility@servers@', 'hotwire', 1.0)
                        TriggerEvent('mhacking:show')
                        TriggerEvent('mhacking:start', math.random(5, 9), math.random(10, 15), onHackPacificDone)
                        if copsCalled or not pacificConfig.alarm then return end
                        TriggerServerEvent('qb-bankrobbery:server:callCops', 'pacific', 0, pos)
                        copsCalled = true
                    else
                        exports.qbx_core:Notify(Lang:t('error.cancel_message'), 'error')
                    end
                else
                    exports.qbx_core:Notify(Lang:t('error.missing_item'), 'error')
                end
            else
                exports.qbx_core:Notify(Lang:t('error.bank_already_open'), 'error')
            end
        else
            exports.qbx_core:Notify(Lang:t('error.minimum_police_required', {police = config.minPacificPolice}), 'error')
        end
    else
        exports.qbx_core:Notify(Lang:t('error.security_lock_active'), 'error', 5500)
    end
end)

-- Threads

CreateThread(function()
    local bankCardBZone = lib.zones.box({
        name = 'pacific_coords_bankcardb',
        coords = pacificConfig.coords[1],
        size = vec3(1, 1, 2),
        rotation = pacificConfig.heading.closed,
        debug = false,
        onEnter = function()
            if not pacificConfig.isOpened then
                -- Config.ShowRequiredItems({
                --     [1] = {name = exports.ox_inventory:Items().security_card_02.name, image = exports.ox_inventory:Items().security_card_02.image}
                -- }, true)
            end
        end,
        onExit = function()
            -- Config.ShowRequiredItems({
            --     [1] = {name = exports.ox_inventory:Items().security_card_02.name, image = exports.ox_inventory:Items().security_card_02.image}
            -- }, false)
        end,
    })
    local electronickitZone = lib.zones.box({
        name = 'pacific_coords_electronickit',
        coords = pacificConfig.coords[2],
        size = vec3(1, 1, 2),
        rotation = pacificConfig.heading.closed,
        debug = false,
        onEnter = function()
            if not pacificConfig.isOpened then
                -- Config.ShowRequiredItems({
                --     [1] = {name = exports.ox_inventory:Items().electronickit.name, image = exports.ox_inventory:Items().electronickit.image},
                --     [2] = {name = exports.ox_inventory:Items().trojan_usb.name, image = exports.ox_inventory:Items().trojan_usb.image}
                -- }, true)
            end
        end,
        onExit = function()
            -- Config.ShowRequiredItems({
            --     [1] = {name = exports.ox_inventory:Items().electronickit.name, image = exports.ox_inventory:Items().electronickit.image},
            --     [2] = {name = exports.ox_inventory:Items().trojan_usb.name, image = exports.ox_inventory:Items().trojan_usb.image}
            -- }, false)
        end,
    })
    local thermite1Zone = lib.zones.box({
        name = 'pacific_coords_thermite_1',
        coords = pacificConfig.thermite[1].coords,
        size = vec3(1, 1, 2),
        rotation = pacificConfig.heading.closed,
        debug = false,
        onEnter = function()
            if not pacificConfig.thermite[1].isOpened then
                currentThermiteGate = pacificConfig.thermite[1].doorId
                -- Config.ShowRequiredItems({
                --     [1] = {name = exports.ox_inventory:Items().thermite.name, image = exports.ox_inventory:Items().thermite.image},
                -- }, true)
            end
        end,
        onExit = function()
            if currentThermiteGate == pacificConfig.thermite[1].doorId then
                currentThermiteGate = 0
                -- Config.ShowRequiredItems({
                --     [1] = {name = exports.ox_inventory:Items().thermite.name, image = exports.ox_inventory:Items().thermite.image},
                -- }, false)
            end
        end,
    })
    local thermite2Zone = lib.zones.box({
        name = 'pacific_coords_thermite_2',
        coords = pacificConfig.thermite[2].coords,
        size = vec3(1, 1, 2),
        rotation = pacificConfig.heading.closed,
        debug = false,
        onEnter = function()
            if not pacificConfig.thermite[2].isOpened then
                currentThermiteGate = pacificConfig.thermite[2].doorId
                -- Config.ShowRequiredItems({
                --     [1] = {name = exports.ox_inventory:Items().thermite.name, image = exports.ox_inventory:Items().thermite.image},
                -- }, true)
            end
        end,
        onExit = function()
            if currentThermiteGate == pacificConfig.thermite[2].doorId then
                currentThermiteGate = 0
                -- Config.ShowRequiredItems({
                --     [1] = {name = exports.ox_inventory:Items().thermite.name, image = exports.ox_inventory:Items().thermite.image},
                -- }, false)
            end
        end,
    })
    for k in pairs(pacificConfig.lockers) do
        if config.useTarget then
            exports.ox_target:addBoxZone({
                coords = pacificConfig.lockers[k].coords,
                size = vec3(1, 1, 2),
                rotation = pacificConfig.heading.closed,
                debug = false,
                drawSprite = true,
                options = {
                    {
                        label = Lang:t('general.break_safe_open_option_target'),
                        name = 'pacific_coords_locker_'..k,
                        icon = 'fa-solid fa-vault',
                        distance = 1.5,
                        canInteract = function()
                            return not isDrilling and pacificConfig.isOpened and not pacificConfig.lockers[k].isBusy and not pacificConfig.lockers[k].isOpened
                        end,
                        onSelect = function()
                            openLocker('pacific', k)
                        end,
                    },
                },
            })
        else
            local lockerZone = lib.zones.box({
                name = 'pacific_coords_locker_'..k,
                coords = pacificConfig.lockers[k].coords,
                size = vec3(1, 1, 2),
                rotation = pacificConfig.heading.closed,
                debug = false,
                onEnter = function()
                    if not isDrilling and pacificConfig.isOpened and not pacificConfig.lockers[k].isBusy and not pacificConfig.lockers[k].isOpened then
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
                if currentLocker ~= 0 and not isDrilling and pacificConfig.isOpened and not pacificConfig.lockers[currentLocker].isBusy and not pacificConfig.lockers[currentLocker].isOpened then
                    sleep = 0
                    if IsControlJustPressed(0, 38) then
                        exports.qbx_core:KeyPressed()
                        Wait(500)
                        lib.hideTextUI()
                        if CurrentCops >= config.minPacificPolice then
                            openLocker('pacific', currentLocker)
                        else
                            exports.qbx_core:Notify(Lang:t('error.minimum_police_required', {police = config.minPacificPolice}), 'error')
                        end
                        sleep = 1000
                    end
                end
            end
            Wait(sleep)
        end
    end
end)
