local config = require 'config.client'
local powerStationConfig = require 'config.shared'.powerStations
local closestStation = 0
local currentStation = 0
local currentFires = {}
local currentGate = 0

--- This will create a fire at the given coords and for the given time
--- @param coords vector3
--- @param time number
--- @return nil
local function createFire(coords, time)
    for _ = 1, math.random(1, 7), 1 do
        TriggerServerEvent('thermite:StartServerFire', coords, 24, false)
    end
    Wait(time)
    TriggerServerEvent('thermite:StopFires')
end

RegisterNetEvent('thermite:StartFire', function(coords, maxChildren, isGasFire)
    if #(vec3(coords.x, coords.y, coords.z) - GetEntityCoords(cache.ped)) < 100 then
        local pos = {
            x = coords.x,
            y = coords.y,
            z = coords.z,
        }
        pos.z = pos.z - 0.9
        local fire = StartScriptFire(pos.x, pos.y, pos.z, maxChildren, isGasFire)
        currentFires[#currentFires+1] = fire
    end
end)

RegisterNetEvent('thermite:StopFires', function()
    for i = 1, #currentFires do
        RemoveScriptFire(currentFires[i])
    end
end)

RegisterNetEvent('thermite:UseThermite', function()
    local pos = GetEntityCoords(cache.ped)
    if closestStation ~= 0 then
        if math.random(1, 100) < 85 or not qbx.isWearingGloves() then
            TriggerServerEvent('evidence:server:CreateFingerDrop', pos)
        end
        TriggerServerEvent('evidence:server:CreateFingerDrop', pos)
        local dist = #(pos - powerStationConfig[closestStation].coords)
        if dist < 1.5 then
            if CurrentCops >= config.minThermitePolice then
                if not powerStationConfig[closestStation].hit then
                    lib.playAnim(cache.ped, 'weapon@w_sp_jerrycan', 'fire', 3.0, 3.9, 180, 49, 0, false, false, false)
                    SetNuiFocus(true, true)
                    SendNUIMessage({
                        action = 'openThermite',
                        amount = math.random(5, 10),
                    })
                    currentStation = closestStation
                else
                    exports.qbx_core:Notify(locale('error.fuses_already_blown'), 'error')
                end
            else
                exports.qbx_core:Notify(locale('error.minium_police_required', {police = config.minThermitePolice}), 'error')
            end
        end
    elseif CurrentThermiteGate ~= 0 then
        if math.random(1, 100) < 85 or not qbx.isWearingGloves() then
            TriggerServerEvent('evidence:server:CreateFingerDrop', pos)
        end
        TriggerServerEvent('evidence:server:CreateFingerDrop', pos)
        if CurrentCops >= config.minThermitePolice then
            currentGate = CurrentThermiteGate
            lib.playAnim(cache.ped, 'weapon@w_sp_jerrycan', 'fire', 3.0, 3.9, -1, 49, 0, false, false, false)
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'openThermite',
                amount = math.random(5, 10),
            })
            TriggerServerEvent('qbx_bankrobbery:server:OpenGate', currentGate, false)
        else
            exports.qbx_core:Notify(locale('error.minium_police_required', {police = config.minThermitePolice}), 'error')
        end
    end
end)

RegisterNetEvent('qbx_bankrobbery:client:SetStationStatus', function(key, isHit)
    powerStationConfig[key].hit = isHit
end)

RegisterNUICallback('thermiteclick', function(_, cb)
    PlaySound(-1, 'CLICK_BACK', 'WEB_NAVIGATION_SOUNDS_PHONE', false, 0, true)
    cb('ok')
end)

RegisterNUICallback('thermitefailed', function(_, cb)
    local success = lib.callback.await('thermite:server:check', false)
    if success then
        PlaySound(-1, 'Place_Prop_Fail', 'DLC_Dmod_Prop_Editor_Sounds', false, 0, true)
        ClearPedTasks(cache.ped)
        local coords = GetEntityCoords(cache.ped)
        local randTime = math.random(10000, 15000)
        createFire(coords, randTime)
    end
    cb('ok')
end)

RegisterNUICallback('thermitesuccess', function(_, cb)
    local success = lib.callback.await('thermite:server:check', false)
    if success then
        ClearPedTasks(cache.ped)
        local time = 3
        local coords = GetEntityCoords(cache.ped)
        while time > 0 do
            exports.qbx_core:Notify(locale('general.thermite_detonating_in_seconds', {time = time}))
            Wait(1000)
            time -= 1
        end
        local randTime = math.random(10000, 15000)
        createFire(coords, randTime)
        if currentStation ~= 0 then
            exports.qbx_core:Notify(locale('success.fuses_are_blown'), 'success')
            TriggerServerEvent('qbx_bankrobbery:server:SetStationStatus', currentStation, true)
        elseif currentGate ~= 0 then
            exports.qbx_core:Notify(locale('success.door_has_opened'), 'success')
            --Config.DoorlockAction(currentGate, false)
            currentGate = 0
        end
    end
    cb('ok')
end)

RegisterNUICallback('closethermite', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

CreateThread(function()
    for k = 1, #powerStationConfig do
        lib.zones.box({
            name = 'powerstation_coords_'..k,
            coords = powerStationConfig[k].coords,
            size = vec3(1, 1, 2),
            rotation = 75.0,
            debug = config.debugPoly,
            onEnter = function()
                if not powerStationConfig[k].hit then
                    closestStation = k
                end
            end,
            onExit = function()
                if closestStation == k then
                    closestStation = 0
                end
            end,
        })
    end
end)
