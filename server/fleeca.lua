local function GetClosestBankIndex(PlayerCoords)
    local ClosestBankIndex = 1
    for i = 1, #Config.BankLocations do
        if #(PlayerCoords - Config.BankLocations[i].Door.coords) < #(PlayerCoords - Config.BankLocations[ClosestBankIndex].Door.coords) then
            ClosestBankIndex = i
        end
    end
    if #(PlayerCoords - Config.BankLocations[ClosestBankIndex].Door.coords) > 6 then return false end
    return ClosestBankIndex
end

local function GetClosestLockerIndex(PlayerCoords, ClosestBankIndex)
    local ClosestLockerIndex = 1
    for i = 1, #Config.BankLocations[ClosestBankIndex].Lockers do
        if #(PlayerCoords - Config.BankLocations[ClosestBankIndex].Lockers[i].coords.xyz) < #(PlayerCoords - Config.BankLocations[ClosestBankIndex].Lockers[ClosestLockerIndex].coords.xyz) then
            ClosestLockerIndex = i
        end
    end
    if #(PlayerCoords - Config.BankLocations[ClosestBankIndex].Lockers[ClosestLockerIndex].coords.xyz) > 3 then return false end
    return ClosestLockerIndex
end

local function SetupFleeca(Bank)
    local CashStack = CreateObject(`h4_prop_h4_cash_stack_01a`, Bank.CashStack.coords.x, Bank.CashStack.coords.y, Bank.CashStack.coords.z, true, true, false)
    while not DoesEntityExist(CashStack) do Wait(0) end
    SetEntityHeading(CashStack, Bank.CashStack.coords.w)
    FreezeEntityPosition(CashStack, true)
end

AddEventHandler('electronickit:UseElectronickit', function(PlayerSource)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(PlayerSource))
    local ClosestBankIndex = GetClosestBankIndex(PlayerCoords)
    if not ClosestBankIndex then return end

    if IsABankActive then QBCore.Functions.Notify(PlayerSource, Lang:t('notify.bank_active'), 'error') return end
    if Config.BankLocations[ClosestBankIndex].Door.opened then QBCore.Functions.Notify(PlayerSource, Lang:t('notify.door_open'), 'error') return end

    local AmountOfPolice = QBCore.Functions.GetDutyCountType('leo')
    if AmountOfPolice < Config.Fleeca.RequiredPolice then if Config.NotEnoughCopsNotify then QBCore.Functions.Notify(PlayerSource, Lang:t('notify.no_police', { Required = Config.Fleeca.RequiredPolice }), 'error') end return end

    local MissingItem = false
    local Player = QBCore.Functions.GetPlayer(PlayerSource)
    for i = 1, #Config.Fleeca.RequiredItems do if not Player.Functions.GetItemByName(Config.Fleeca.RequiredItems[i]) then MissingItem = true end end
    if MissingItem then QBCore.Functions.Notify(PlayerSource, Lang:t('notify.missing_item'), 'error') return end

    local Result, DoorID = lib.callback.await('qb-bankrobbery:callback:startDoorHack', PlayerSource)
    if not Result then QBCore.Functions.Notify(PlayerSource, Lang:t('notify.failed_doorhack'), 'error') return end

    Config.BankLocations[ClosestBankIndex].Door.opened = true

    Entity(NetworkGetEntityFromNetworkId(DoorID)).state:set('vaultOpening', Config.BankLocations[ClosestBankIndex].Door.heading.open, true)
    SetupFleeca(Config.BankLocations[ClosestBankIndex])
end)

RegisterNetEvent('qb-bankrobbery:server:takeCashStack', function()
    local PlayerSource = source
    local PlayerCoords = GetEntityCoords(GetPlayerPed(PlayerSource))
    local ClosestBankIndex = GetClosestBankIndex(PlayerCoords)
    if not ClosestBankIndex then return end
    local ClosestBank = Config.BankLocations[ClosestBankIndex]

    if #(PlayerCoords - ClosestBank.CashStack.coords.xyz) > 3.0 then return end
    if ClosestBank.CashStack.taken then return end
    if not ClosestBank.Door.opened then return end

    Config.BankLocations[ClosestBankIndex].CashStack.taken = true
    local Cashbag = CreateObject(`hei_p_m_bag_var22_arm_s`, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, true, true, false)
    while not DoesEntityExist(Cashbag) do Wait(0) end
    local CashStack, WaitTime = lib.callback.await('qb-bankrobbery:callback:startCashStack', PlayerSource, NetworkGetNetworkIdFromEntity(Cashbag))
    DeleteEntity(NetworkGetEntityFromNetworkId(CashStack))
    Wait(WaitTime)
    DeleteEntity(Cashbag)
    SetPedComponentVariation(GetPlayerPed(PlayerSource), 5, 45, 0, 0)
end)

RegisterNetEvent('qb-bankrobbery:server:crackLocker', function()
    local PlayerSource = source
    local PlayerCoords = GetEntityCoords(GetPlayerPed(PlayerSource))
    local ClosestBankIndex = GetClosestBankIndex(PlayerCoords)
    if not ClosestBankIndex then return end
    local ClosestBank = Config.BankLocations[ClosestBankIndex]
    local ClosestLockerIndex = GetClosestLockerIndex(PlayerCoords, ClosestBankIndex)
    if not ClosestLockerIndex then return end

    -- if not ClosestBank.Door.opened then return end
    if ClosestBank.Lockers[ClosestLockerIndex].taken then return end

    local Player = QBCore.Functions.GetPlayer(PlayerSource)
    if not Player.Functions.GetItemByName(ClosestBank.Lockers[ClosestLockerIndex].action.requireditem) then return end

    SetEntityHeading(GetPlayerPed(PlayerSource), ClosestBank.Lockers[ClosestLockerIndex].coords.w)

    local Drillbag, Drillobject
    if ClosestBank.Lockers[ClosestLockerIndex].action.event == 'drill' then
        Drillbag = CreateObject(`hei_p_m_bag_var22_arm_s`, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, true, false, false)
        Drillobject = CreateObject(`hei_prop_heist_drill`, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, true, false, false)
        while not DoesEntityExist(Drillbag) do Wait(0) end
        while not DoesEntityExist(Drillobject) do Wait(0) end
        Entity(Drillobject).state:set('drillAttachEntity', PlayerSource, true)
    end

    Config.BankLocations[ClosestBankIndex].Lockers[ClosestLockerIndex].taken = true
    local Result = lib.callback.await(string.format('qb-bankrobbery:callback:start%s', ClosestBank.Lockers[ClosestLockerIndex].action.event), PlayerSource, NetworkGetNetworkIdFromEntity(Drillbag), NetworkGetNetworkIdFromEntity(Drillobject), ClosestLockerIndex)

    if ClosestBank.Lockers[ClosestLockerIndex].action.event == 'drill' then
        DeleteEntity(Drillbag)
        DeleteEntity(Drillobject)
    end
    SetPedComponentVariation(GetPlayerPed(PlayerSource), 5, 45, 0, 0)
end)

