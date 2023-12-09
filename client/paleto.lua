local config = require 'config.client'
local sharedConfig = require 'config.shared'
local inBankCardAZone = false
local currentLocker = 0
local copsCalled = false

-- Functions

--- This will load an animation dictionary so you can play an animation in that dictionary
--- @param dict string
--- @return nil
local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
end

-- Events

RegisterNetEvent('qb-bankrobbery:UseBankcardA', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    if math.random(1, 100) > 85 or IsWearingGloves() then return end
    TriggerServerEvent("evidence:server:CreateFingerDrop", pos)
    if not inBankCardAZone then return end
    local isBusy = lib.callback.await('qb-bankrobbery:server:isRobberyActive', false)
    if not isBusy then
        if CurrentCops >= config.minPaletoPolice then
            if not sharedConfig.bigBanks["paleto"]["isOpened"] then
                -- Config.ShowRequiredItems(nil, false)
                if lib.progressBar({
                    duration = 7500,
                    label = Lang:t("general.validating_bankcard"),
                    canCancel = true,
                    useWhileDead = false,
                    disable = {
                        move = true,
                        car = true,
                        mouse = false,
                        combat = true
                    },
                    anim = {
                        dict = "anim@gangops@facility@servers@",
                        clip = "hotwire",
                        flag = 1
                    }
                }) then
                    TriggerServerEvent('qb-bankrobbery:server:setBankState', 'paleto')
                    TriggerServerEvent('qb-bankrobbery:server:removeBankCard', '01')
                    --Config.DoorlockAction(4, false)
                    if copsCalled or not sharedConfig.bigBanks["paleto"]["alarm"] then return end
                    TriggerServerEvent("qb-bankrobbery:server:callCops", "paleto", 0, pos)
                    copsCalled = true
                else
                    exports.qbx_core:Notify(Lang:t("error.cancel_message"), "error")
                end
            else
                exports.qbx_core:Notify(Lang:t("error.bank_already_open"), "error")
            end
        else
            exports.qbx_core:Notify(Lang:t("error.minimum_police_required", {police = config.minPaletoPolice}), "error")
        end
    else
        exports.qbx_core:Notify(Lang:t("error.security_lock_active"), "error", 5500)
    end
end)

-- Threads

CreateThread(function()
    local bankCardAZone = BoxZone:Create(sharedConfig.bigBanks["paleto"]["coords"], 1.0, 1.0, {
        name = 'paleto_coords_bankcarda',
        heading = sharedConfig.bigBanks["paleto"]["coords"].closed,
        minZ = sharedConfig.bigBanks["paleto"]["coords"].z - 1,
        maxZ = sharedConfig.bigBanks["paleto"]["coords"].z + 1,
        debugPoly = false
    })
    bankCardAZone:onPlayerInOut(function(inside)
        inBankCardAZone = inside
        if inside and not sharedConfig.bigBanks["paleto"]["isOpened"] then
            -- Config.ShowRequiredItems({
            --     [1] = {name = exports.ox_inventory:Items().security_card_01.name, image = exports.ox_inventory:Items().security_card_01.image}
            -- }, true)
        else
            -- Config.ShowRequiredItems({
            --     [1] = {name = exports.ox_inventory:Items().security_card_01.name, image = exports.ox_inventory:Items().security_card_01.image}
            -- }, false)
        end
    end)
    local thermite1Zone = BoxZone:Create(sharedConfig.bigBanks["paleto"]["thermite"][1]["coords"], 1.0, 1.0, {
        name = 'paleto_coords_thermite_1',
        heading = sharedConfig.bigBanks["paleto"]["heading"].closed,
        minZ = sharedConfig.bigBanks["paleto"]["thermite"][1]["coords"].z - 1,
        maxZ = sharedConfig.bigBanks["paleto"]["thermite"][1]["coords"].z + 1,
        debugPoly = false
    })
    thermite1Zone:onPlayerInOut(function(inside)
        if inside and not sharedConfig.bigBanks["paleto"]["thermite"][1]["isOpened"] then
            currentThermiteGate = sharedConfig.bigBanks["paleto"]["thermite"][1]["doorId"]
            -- Config.ShowRequiredItems({
            --     [1] = {name = exports.ox_inventory:Items().thermite.name, image = exports.ox_inventory:Items().thermite.image},
            -- }, true)
        else
            if currentThermiteGate == sharedConfig.bigBanks["paleto"]["thermite"][1]["doorId"] then
                currentThermiteGate = 0
                -- Config.ShowRequiredItems({
                --     [1] = {name = exports.ox_inventory:Items().thermite.name, image = exports.ox_inventory:Items().thermite.image},
                -- }, false)
            end
        end
    end)
    for k in pairs(sharedConfig.bigBanks["paleto"]["lockers"]) do
        if config.useTarget then
            exports['qb-target']:AddBoxZone('paleto_coords_locker_'..k, sharedConfig.bigBanks["paleto"]["lockers"][k]["coords"], 1.0, 1.0, {
                name = 'paleto_coords_locker_'..k,
                heading = sharedConfig.bigBanks["paleto"]["heading"].closed,
                minZ = sharedConfig.bigBanks["paleto"]["lockers"][k]["coords"].z - 1,
                maxZ = sharedConfig.bigBanks["paleto"]["lockers"][k]["coords"].z + 1,
                debugPoly = false
            }, {
                options = {
                    {
                        action = function()
                            openLocker("paleto", k)
                        end,
                        canInteract = function()
                            return not IsDrilling and sharedConfig.bigBanks["paleto"]["isOpened"] and not sharedConfig.bigBanks["paleto"]["lockers"][k]["isBusy"] and not sharedConfig.bigBanks["paleto"]["lockers"][k]["isOpened"]
                        end,
                        icon = 'fa-solid fa-vault',
                        label = Lang:t("general.break_safe_open_option_target"),
                    },
                },
                distance = 1.5
            })
        else
            local lockerZone = BoxZone:Create(sharedConfig.bigBanks["paleto"]["lockers"][k]["coords"], 1.0, 1.0, {
                name = 'paleto_coords_locker_'..k,
                heading = sharedConfig.bigBanks["paleto"]["heading"].closed,
                minZ = sharedConfig.bigBanks["paleto"]["lockers"][k]["coords"].z - 1,
                maxZ = sharedConfig.bigBanks["paleto"]["lockers"][k]["coords"].z + 1,
                debugPoly = false
            })
            lockerZone:onPlayerInOut(function(inside)
                if inside and not IsDrilling and sharedConfig.bigBanks["paleto"]["isOpened"] and not sharedConfig.bigBanks["paleto"]["lockers"][k]["isBusy"] and not sharedConfig.bigBanks["paleto"]["lockers"][k]["isOpened"] then
                    exports['qbx-core']:DrawText(Lang:t("general.break_safe_open_option_drawtext"), 'right')
                    currentLocker = k
                else
                    if currentLocker == k then
                        currentLocker = 0
                        exports['qbx-core']:HideText()
                    end
                end
            end)
        end
    end
    if not config.useTarget then
        while true do
            local sleep = 1000
            if isLoggedIn then
                if currentLocker ~= 0 and not IsDrilling and sharedConfig.bigBanks["paleto"]["isOpened"] and not sharedConfig.bigBanks["paleto"]["lockers"][currentLocker]["isBusy"] and not sharedConfig.bigBanks["paleto"]["lockers"][currentLocker]["isOpened"] then
                    sleep = 0
                    if IsControlJustPressed(0, 38) then
                        exports['qbx-core']:KeyPressed()
                        Wait(500)
                        exports['qbx-core']:HideText()
                        if CurrentCops >= config.minPaletoPolice then
                            openLocker("paleto", currentLocker)
                        else
                            exports.qbx_core:Notify(Lang:t("error.minimum_police_required", {police = config.minPaletoPolice}), "error")
                        end
                        sleep = 1000
                    end
                end
            end
            Wait(sleep)
        end
    end
end)
