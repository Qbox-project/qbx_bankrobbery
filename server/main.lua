local config = require 'config.server'
local clientConfig = require 'config.client'
local sharedConfig = require 'config.shared'
local robberyBusy = false
local timeOut = false
local bankAuthorizations = {}
local gateAuthorizations = {}
local thermiteAuthorizations = {}
local lockerSessions = {}
local robberyAlarms = {}
local robberyAlertLocales = {
    small = 'general.fleeca_robbery_alert',
    paleto = 'general.paleto_robbery_alert',
    pacific = 'general.pacific_robbery_alert',
}

local function getBank(bankId)
    if bankId == 'paleto' or bankId == 'pacific' then
        return sharedConfig.bigBanks[bankId], bankId
    end

    if type(bankId) ~= 'number' or bankId % 1 ~= 0 then return end
    return sharedConfig.smallBanks[bankId], 'small'
end

local function getLocker(bankId, lockerId)
    if type(lockerId) ~= 'number' or lockerId % 1 ~= 0 then return end

    local bank, bankType = getBank(bankId)
    local locker = bank and bank.lockers[lockerId]
    if not locker then return end

    return bank, locker, bankType
end

local function isPlayerNearCoords(source, coords, distance)
    local ped = GetPlayerPed(source)
    if ped == 0 then return false end

    return #(GetEntityCoords(ped) - vec3(coords.x, coords.y, coords.z)) <= distance
end

local function getBankEntryCoords(bankId, bank)
    if bankId == 'pacific' then return bank.coords[2] end
    return bank.coords
end

local function hasRequiredPolice(bankType)
    local required = bankType == 'paleto' and clientConfig.minPaletoPolice
        or bankType == 'pacific' and clientConfig.minPacificPolice
        or clientConfig.minFleecaPolice
    local count = exports.qbx_core:GetDutyCountType('leo')
    return count >= required
end

local function getThermiteTarget(coords)
    for key, station in pairs(sharedConfig.powerStations) do
        if #(coords - station.coords) <= 3.0 then
            return 'station', key
        end
    end

    for bankName, bank in pairs(sharedConfig.bigBanks) do
        for i = 1, #bank.thermite do
            local thermite = bank.thermite[i]
            if #(coords - thermite.coords) <= 3.0 then
                return 'gate', thermite.doorId, bankName
            end
        end
    end
end

local function getDoorCoords(doorId)
    if doorId == 6 then return sharedConfig.bigBanks.pacific.coords[1], 'card' end

    for _, bank in pairs(sharedConfig.bigBanks) do
        for i = 1, #bank.thermite do
            if bank.thermite[i].doorId == doorId then return bank.thermite[i].coords, 'thermite' end
        end
    end
end

--- This will convert a table's keys into an array
--- @param tbl table
--- @return array
local function tableKeysToArray(tbl)
    local array = {}
    for k in pairs(tbl) do
        array[#array+1] = k
    end
    return array
end

--- This will loop over the given table to check if the power stations in the table have been hit
--- @param toLoop table
--- @return boolean
local function tableLoopStations(toLoop)
    local hits = 0
    for _, station in pairs(toLoop) do
        if type(station) == 'table' then
            local hits2 = 0
            for _, station2 in pairs(station) do
                if sharedConfig.powerStations[station2].hit then hits2 += 1 end
                if hits2 == #station then return true end
            end
        else
            if sharedConfig.powerStations[station].hit then hits += 1 end
            if hits == #toLoop then return true end
        end
    end
    return false
end

--- This will check what stations have been hit and update them accordingly
--- @return nil
local function checkStationHits()
    local policeHits = {}
    local bankHits = {}

    for k, v in pairs(config.cameraHits) do
        local allStationsHitPolice = false
        local allStationsHitBank = false
        if type(v.type) == 'table' then
            for _, cameraType in pairs(v.type) do
                if cameraType == 'police' then
                    if type(v.stationsToHitPolice) == 'table' then
                        allStationsHitPolice = tableLoopStations(v.stationsToHitPolice)
                    else
                        allStationsHitPolice = sharedConfig.powerStations[v.stationsToHitPolice].hit
                    end
                elseif cameraType == 'bank' then
                    if type(v.stationsToHitBank) == 'table' then
                        allStationsHitBank = tableLoopStations(v.stationsToHitBank)
                    else
                        allStationsHitBank = sharedConfig.powerStations[v.stationsToHitBank].hit
                    end
                end
            end
        else
            if v.type == 'police' then
                if type(v.stationsToHitPolice) == 'table' then
                    allStationsHitPolice = tableLoopStations(v.stationsToHitPolice)
                else
                    allStationsHitPolice = sharedConfig.powerStations[v.stationsToHitPolice].hit
                end
            elseif v.type == 'bank' then
                if type(v.stationsToHitBank) == 'table' then
                    allStationsHitBank = tableLoopStations(v.stationsToHitBank)
                else
                    allStationsHitBank = sharedConfig.powerStations[v.stationsToHitBank].hit
                end
            end
        end

        if allStationsHitPolice then
            policeHits[k] = true
        end

        if allStationsHitBank then
            bankHits[k] = true
        end
    end

    policeHits = tableKeysToArray(policeHits)
    bankHits = tableKeysToArray(bankHits)

    -- table.type checks if it's empty as well, if it's empty it will return the type 'empty' instead of 'array'

    if table.type(policeHits) == 'array' then TriggerClientEvent('police:client:SetCamera', -1, policeHits, false) end
    if table.type(bankHits) == 'array' then TriggerClientEvent('qbx_bankrobbery:client:BankSecurity', -1, bankHits, false) end
end

--- This will do a quick check to see if all stations have been hit
--- @return boolean
local function allStationsHit()
    local hit = 0
    for k in pairs(sharedConfig.powerStations) do
        if sharedConfig.powerStations[k].hit then
            hit += 1
        end
    end
    return hit >= config.hitsNeeded
end

---Changes the bank state
---@param bankId string | number
---@param state boolean
local function changeBankState(bankId, state)
    local bankName = type(bankId) == 'number' and 'bankrobbery' or bankId
    TriggerEvent('qb-scoreboard:server:SetActivityBusy', bankName, state)
    if bankName ~= 'bankrobbery' then return end
    TriggerEvent('qb-banking:server:SetBankClosed', bankId, state)
end

local function changeBlackoutState(state)
    local eventName = state and 'police:client:DisableAllCameras' or 'police:client:EnableAllCameras'
    TriggerClientEvent(eventName, -1)
end

RegisterNetEvent('qbx_bankrobbery:server:setBankState', function(bankId)
    if robberyBusy then return end
    local bank, bankType = getBank(bankId)
    local authorization = bankAuthorizations[source]
    if not bank or bank.isOpened or not authorization or authorization.bankId ~= bankId
        or authorization.expires < os.time() or not hasRequiredPolice(bankType)
        or not isPlayerNearCoords(source, getBankEntryCoords(bankId, bank), 3.0) then return end

    bankAuthorizations[source] = nil
    bank.isOpened = true
    if bankType == 'small' then
        TriggerEvent('qbx_bankrobbery:server:SetSmallBankTimeout', bankId)
    else
        TriggerEvent('qbx_bankrobbery:server:setTimeout')
    end

    TriggerClientEvent('qbx_bankrobbery:client:setBankState', -1, bankId)
    robberyBusy = true
    changeBankState(bankId, true)
end)

RegisterNetEvent('qbx_bankrobbery:server:setLockerState', function(bankId, lockerId, state, bool)
    if (state ~= 'isBusy' and state ~= 'isOpened') or type(bool) ~= 'boolean' then return end

    local bank, locker, bankType = getLocker(bankId, lockerId)
    if not bank or not bank.isOpened or not isPlayerNearCoords(source, locker.coords, 3.0) then return end

    local session = lockerSessions[locker]
    if state == 'isBusy' then
        if bool then
            if locker.isOpened or locker.isBusy or session then return end
            if bankType ~= 'small' and exports.ox_inventory:Search(source, 'count', 'drill') < 1 then return end

            locker.isBusy = true
            lockerSessions[locker] = {
                source = source,
                startedAt = os.time(),
                bankId = bankId,
                lockerId = lockerId
            }
        else
            if not session or session.source ~= source or locker.isOpened then return end
            locker.isBusy = false
            lockerSessions[locker] = nil
        end

        TriggerClientEvent('qbx_bankrobbery:client:setLockerState', -1, bankId, lockerId, 'isBusy', locker.isBusy)
        return
    end

    if not bool or not session or session.source ~= source or os.time() - session.startedAt < 15 then return end
    if bankType ~= 'small' and exports.ox_inventory:Search(source, 'count', 'drill') < 1 then return end

    locker.isOpened = true
    locker.isBusy = false
    locker.rewardOwner = source
    lockerSessions[locker] = nil
    TriggerClientEvent('qbx_bankrobbery:client:setLockerState', -1, bankId, lockerId, 'isOpened', true)
    TriggerClientEvent('qbx_bankrobbery:client:setLockerState', -1, bankId, lockerId, 'isBusy', false)
end)

RegisterNetEvent('qbx_bankrobbery:server:recieveItem', function(rewardType, bankId, lockerId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local bank, locker, bankType = getLocker(bankId, lockerId)
    if not bank or rewardType ~= bankType or not bank.isOpened or not locker.isOpened or locker.rewardClaimed
        or locker.rewardOwner ~= src or not isPlayerNearCoords(src, locker.coords, 3.0) then return end

    locker.rewardClaimed = true
    locker.rewardOwner = nil
    if rewardType == 'small' then
        local itemType = math.random(#config.rewardTypes)
        local weaponChance = math.random(1, 50)
        local odd1 = math.random(1, 50)
        local tierChance = math.random(1, 100)
        local tier
        if tierChance < 50 then tier = 1 elseif tierChance >= 50 and tierChance < 80 then tier = 2 elseif tierChance >= 80 and tierChance < 95 then tier = 3 else tier = 4 end
        if weaponChance ~= odd1 then
            if tier ~= 4 then
                if config.rewardTypes[itemType].type == 'item' then
                    local item = config.lockerRewards['tier'..tier][math.random(#config.lockerRewards['tier'..tier])]
                    local itemAmount = math.random(item.minAmount, item.maxAmount)
                    exports.ox_inventory:AddItem(src, item.item, itemAmount)
                elseif config.rewardTypes[itemType].type == 'money' then
                    exports.ox_inventory:AddItem(src, 'black_money', math.random(20000, 30000))
                end
            else
                exports.ox_inventory:AddItem(src, 'security_card_01', 1)
            end
        else
            exports.ox_inventory:AddItem(src, 'weapon_stungun', 1)
        end
    elseif rewardType == 'paleto' then
        local itemType = math.random(#config.rewardTypes)
        local tierChance = math.random(1, 100)
        local weaponChance = math.random(1, 10)
        local odd1 = math.random(1, 10)
        local tier
        if tierChance < 25 then tier = 1 elseif tierChance >= 25 and tierChance < 70 then tier = 2 elseif tierChance >= 70 and tierChance < 95 then tier = 3 else tier = 4 end
        if weaponChance ~= odd1 then
            if tier ~= 4 then
                 if config.rewardTypes[itemType].type == 'item' then
                    local item = config.lockerRewardsPaleto['tier'..tier][math.random(#config.lockerRewardsPaleto['tier'..tier])]
                    local itemAmount = math.random(item.minAmount, item.maxAmount)
                    exports.ox_inventory:AddItem(src, item.item, itemAmount)
                 elseif config.rewardTypes[itemType].type == 'money' then
                    exports.ox_inventory:AddItem(src, 'black_money', math.random(10000, 40000))
                 end
            else
                exports.ox_inventory:AddItem(src, 'security_card_02', 1)
            end
        else
            exports.ox_inventory:AddItem(src, 'weapon_vintagepistol', 1)
        end
    elseif rewardType == 'pacific' then
        local itemType = math.random(#config.rewardTypes)
        local weaponChance = math.random(1, 100)
        local odd1 = math.random(1, 100)
        local odd2 = math.random(1, 100)
        local tierChance = math.random(1, 100)
        local tier
        if tierChance < 10 then tier = 1 elseif tierChance >= 25 and tierChance < 50 then tier = 2 elseif tierChance >= 50 and tierChance < 95 then tier = 3 else tier = 4 end
        if weaponChance ~= odd1 or weaponChance ~= odd2 then
            if tier ~= 4 then
                if config.rewardTypes[itemType].type == 'item' then
                    local item = config.lockerRewardsPacific['tier'..tier][math.random(#config.lockerRewardsPacific['tier'..tier])]
                    local maxAmount
                    if tier == 3 then maxAmount = 7 elseif tier == 2 then maxAmount = 18 else maxAmount = 25 end
                    local itemAmount = math.random(maxAmount)
                    exports.ox_inventory:AddItem(src, item.item, itemAmount)
                elseif config.rewardTypes[itemType].type == 'money' then
                    exports.ox_inventory:AddItem(src, 'black_money', math.random(10000, 40000))
                end
            else
                exports.ox_inventory:AddItem(src, 'black_money', math.random(10000, 40000))
            end
        else
            local chance = math.random(1, 2)
            local odd = math.random(1, 2)
            if chance == odd then
                exports.ox_inventory:AddItem(src, 'weapon_microsmg', 1)
            else
                exports.ox_inventory:AddItem(src, 'weapon_minismg', 1)
            end
        end
    end
end)

AddEventHandler('qbx_bankrobbery:server:setTimeout', function()
    if robberyBusy or timeOut then return end
    timeOut = true
    CreateThread(function()
        SetTimeout(60000 * 90, function()
            for k in pairs(sharedConfig.bigBanks.pacific.lockers) do
                local locker = sharedConfig.bigBanks.pacific.lockers[k]
                locker.isBusy = false
                locker.isOpened = false
                locker.rewardClaimed = nil
                locker.rewardOwner = nil
                lockerSessions[locker] = nil
            end
            for k in pairs(sharedConfig.bigBanks.paleto.lockers) do
                local locker = sharedConfig.bigBanks.paleto.lockers[k]
                locker.isBusy = false
                locker.isOpened = false
                locker.rewardClaimed = nil
                locker.rewardOwner = nil
                lockerSessions[locker] = nil
            end
            TriggerClientEvent('qbx_bankrobbery:client:ClearTimeoutDoors', -1)
            sharedConfig.bigBanks.paleto.isOpened = false
            sharedConfig.bigBanks.pacific.isOpened = false
            robberyAlarms.paleto = nil
            robberyAlarms.pacific = nil
            timeOut = false
            robberyBusy = false
            changeBankState('paleto', false)
            changeBankState('pacific', false)
        end)
    end)
end)

AddEventHandler('qbx_bankrobbery:server:SetSmallBankTimeout', function(bankId)
    if robberyBusy or timeOut then return end
    timeOut = true
    CreateThread(function()
        SetTimeout(60000 * 30, function()
            for k in pairs(sharedConfig.smallBanks[bankId].lockers) do
                local locker = sharedConfig.smallBanks[bankId].lockers[k]
                locker.isOpened = false
                locker.isBusy = false
                locker.rewardClaimed = nil
                locker.rewardOwner = nil
                lockerSessions[locker] = nil
            end
            TriggerClientEvent('qbx_bankrobbery:client:ResetFleecaLockers', -1, bankId)
            timeOut = false
            robberyBusy = false
            robberyAlarms[bankId] = nil
            changeBankState(bankId, false)
        end)
    end)
end)

RegisterNetEvent('qbx_bankrobbery:server:callCops', function(alertType, bankId)
    local bank, bankType = getBank(alertType == 'small' and bankId or alertType)
    local alarmId = bankType == 'small' and bankId or bankType
    if not bank or alertType ~= bankType or not bank.alarm or robberyAlarms[alarmId]
        or not isPlayerNearCoords(source, getBankEntryCoords(alarmId, bank), 15.0) then return end

    robberyAlarms[alarmId] = true
    local coords = GetEntityCoords(GetPlayerPed(source))
    local players = exports.qbx_core:GetQBPlayers()
    for _, player in pairs(players) do
        if player.PlayerData.job.type == 'leo' and player.PlayerData.job.onduty then
            TriggerClientEvent('qbx_bankrobbery:client:robberyCall', player.PlayerData.source, alertType, coords)
        end
    end
    TriggerEvent('police:server:policeAlert', locale(robberyAlertLocales[alertType]), nil, source)

    SetTimeout(clientConfig.outlawCooldown * 60000, function()
        robberyAlarms[alarmId] = nil
    end)
end)

RegisterNetEvent('qbx_bankrobbery:server:SetStationStatus', function(key, isHit)
    if type(key) ~= 'number' or key % 1 ~= 0 or isHit ~= true then return end

    local station = sharedConfig.powerStations[key]
    local authorization = thermiteAuthorizations[source]
    if not station or station.hit or not authorization or not authorization.canComplete
        or authorization.kind ~= 'station' or authorization.id ~= key or authorization.expires < os.time() then return end

    thermiteAuthorizations[source] = nil
    station.hit = true
    TriggerClientEvent('qbx_bankrobbery:client:SetStationStatus', -1, key, true)
    if allStationsHit() then
        exports['qb-weathersync']:setBlackout(true)
        TriggerClientEvent('qbx_bankrobbery:client:disableAllBankSecurity', -1)
        changeBlackoutState(true)
        CreateThread(function()
            SetTimeout(60000 * config.blackoutTimer, function()
                exports['qb-weathersync']:setBlackout(false)
                TriggerClientEvent('qbx_bankrobbery:client:enableAllBankSecurity', -1)
                changeBlackoutState(false)
            end)
        end)
    else
        checkStationHits()
    end
end)

RegisterNetEvent('qbx_bankrobbery:server:removeElectronicKit', function(bankId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local bank, bankType = getBank(bankId)
    if not player or not bank or bankType == 'paleto' or bank.isOpened or not hasRequiredPolice(bankType)
        or not isPlayerNearCoords(src, getBankEntryCoords(bankId, bank), 3.0) then return end
    if exports.ox_inventory:Search(src, 'count', 'electronickit') < 1
        or exports.ox_inventory:Search(src, 'count', 'trojan_usb') < 1 then return end
    if not exports.ox_inventory:RemoveItem(src, 'electronickit', 1) then return end
    if not exports.ox_inventory:RemoveItem(src, 'trojan_usb', 1) then
        exports.ox_inventory:AddItem(src, 'electronickit', 1)
        return
    end

    bankAuthorizations[src] = { bankId = bankId, expires = os.time() + 300 }
end)

RegisterNetEvent('qbx_bankrobbery:server:removeBankCard', function(number)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or (number ~= '01' and number ~= '02') then return end

    local bankId = number == '01' and 'paleto' or 'pacific'
    local bank = sharedConfig.bigBanks[bankId]
    local coords = number == '01' and bank.coords or bank.coords[1]
    if bank.isOpened or not hasRequiredPolice(bankId) or not isPlayerNearCoords(src, coords, 3.0) then return end
    if not exports.ox_inventory:RemoveItem(src, 'security_card_'..number, 1) then return end

    if number == '01' then
        bankAuthorizations[src] = { bankId = bankId, expires = os.time() + 30 }
    else
        gateAuthorizations[src] = { doorId = 6, expires = os.time() + 30 }
    end
end)

RegisterNetEvent('thermite:StartServerFire', function()
    local src = source
    local authorization = thermiteAuthorizations[src]
    if not authorization or authorization.expires < os.time() or authorization.fireCount >= 7 then return end

    local ped = GetPlayerPed(src)
    if ped == 0 or not isPlayerNearCoords(src, authorization.coords, 20.0) then return end

    authorization.fireCount += 1
    TriggerClientEvent('thermite:StartFire', -1, authorization.coords, 24, false)
end)

RegisterNetEvent('qbx_bankrobbery:server:OpenGate', function(currentGate, state)
    if type(currentGate) ~= 'number' or state ~= false then return end

    local coords, authorizationType = getDoorCoords(currentGate)
    if not coords then return end

    if authorizationType == 'card' then
        if not isPlayerNearCoords(source, coords, 5.0) then return end
        local authorization = gateAuthorizations[source]
        if not authorization or authorization.doorId ~= currentGate or authorization.expires < os.time() then return end
        gateAuthorizations[source] = nil
    else
        local authorization = thermiteAuthorizations[source]
        if not authorization or not authorization.canComplete or authorization.kind ~= 'gate'
            or authorization.id ~= currentGate or authorization.expires < os.time() then return end
        thermiteAuthorizations[source] = nil
    end

    exports.ox_doorlock:setDoorState(currentGate, false)
end)

RegisterNetEvent('thermite:StopFires', function()
    local authorization = thermiteAuthorizations[source]
    if not authorization or authorization.expires < os.time() then return end
    TriggerClientEvent('thermite:StopFires', -1)
end)

-- Callbacks
lib.callback.register('qbx_bankrobbery:server:isRobberyActive', function()
    return robberyBusy
end)

lib.callback.register('qbx_bankrobbery:server:GetConfig', function()
    return sharedConfig.powerStations, sharedConfig.bigBanks, sharedConfig.smallBanks
end)

lib.callback.register('thermite:server:check', function(source, succeeded)
    local player = exports.qbx_core:GetPlayer(source)
    local ped = GetPlayerPed(source)
    if not player or ped == 0 or exports.ox_inventory:Search(source, 'count', 'lighter') < 1 then return false end

    local kind, id = getThermiteTarget(GetEntityCoords(ped))
    local policeCount = exports.qbx_core:GetDutyCountType('leo')
    if not kind or policeCount < clientConfig.minThermitePolice then return false end
    if not exports.ox_inventory:RemoveItem(source, 'thermite', 1) then return false end

    thermiteAuthorizations[source] = {
        kind = kind,
        id = id,
        canComplete = succeeded == true,
        expires = os.time() + 60,
        fireCount = 0,
        coords = GetEntityCoords(ped),
    }
    return true
end)

-- Items

exports.qbx_core:CreateUseableItem('thermite', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or not player.Functions.GetItemByName('thermite') then return end
	if player.Functions.GetItemByName('lighter') then
        TriggerClientEvent('thermite:UseThermite', source)
    else
        exports.qbx_core:Notify(source, locale('error.missing_ignition_source'), 'error')
    end
end)

exports.qbx_core:CreateUseableItem('security_card_01', function(source)
    local player = exports.qbx_core:GetPlayer(source)
	if not player or not player.Functions.GetItemByName('security_card_01') then return end
    TriggerClientEvent('qbx_bankrobbery:UseBankcardA', source)
end)

exports.qbx_core:CreateUseableItem('security_card_02', function(source)
    local player = exports.qbx_core:GetPlayer(source)
	if not player or not player.Functions.GetItemByName('security_card_02') then return end
    TriggerClientEvent('qbx_bankrobbery:UseBankcardB', source)
end)

exports.qbx_core:CreateUseableItem('electronickit', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or not player.Functions.GetItemByName('electronickit') then return end
    TriggerClientEvent('electronickit:UseElectronickit', source)
end)

AddEventHandler('playerDropped', function()
    bankAuthorizations[source] = nil
    gateAuthorizations[source] = nil
    thermiteAuthorizations[source] = nil

    for locker, session in pairs(lockerSessions) do
        if session.source == source then
            locker.isBusy = false
            lockerSessions[locker] = nil
            TriggerClientEvent('qbx_bankrobbery:client:setLockerState', -1, session.bankId, session.lockerId, 'isBusy', false)
        end
    end

    for _, bank in pairs(sharedConfig.smallBanks) do
        for _, locker in pairs(bank.lockers) do
            if locker.rewardOwner == source then locker.rewardOwner = nil end
        end
    end
    for _, bank in pairs(sharedConfig.bigBanks) do
        for _, locker in pairs(bank.lockers) do
            if locker.rewardOwner == source then locker.rewardOwner = nil end
        end
    end
end)
