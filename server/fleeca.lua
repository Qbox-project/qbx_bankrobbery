local function GetClosestBankIndex(Source)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(Source))
    local ClosestBankIndex = 1
    for i = 1, #Config.BankLocations do
        if #(PlayerCoords - Config.BankLocations[i].Door.coords) < #(PlayerCoords - Config.BankLocations[ClosestBankIndex].Door.coords) then
            ClosestBankIndex = i
        end
    end
    if #(PlayerCoords - Config.BankLocations[ClosestBankIndex].Door.coords) > 10 then return false end
    return ClosestBankIndex
end

local function SetupFleeca(Bank)
    local CashStack = CreateObject(`h4_prop_h4_cash_stack_01a`, Bank.CashStack.coords.x, Bank.CashStack.coords.y, Bank.CashStack.coords.z, true, true, false)
    while not DoesEntityExist(CashStack) do Wait(0) end
    print(Bank.CashStack.coords, Bank.label)
    SetEntityHeading(CashStack, Bank.CashStack.coords.w)
    FreezeEntityPosition(CashStack, true)
end

AddEventHandler('electronickit:UseElectronickit', function(PlayerSource)
    local ClosestBankIndex = GetClosestBankIndex(PlayerSource)
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
    local ClosestBankIndex = GetClosestBankIndex(PlayerSource)
    if not ClosestBankIndex then return end
    local ClosestBank = Config.BankLocations[ClosestBankIndex]

    local PlayerCoords = GetEntityCoords(GetPlayerPed(PlayerSource))
    if #(PlayerCoords - vec3(ClosestBank.CashStack.coords.x, ClosestBank.CashStack.coords.y, ClosestBank.CashStack.coords.z)) > 3.0 then return end
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
