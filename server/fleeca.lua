local function GetClosestBankIndex(Source)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(Source))
    local ClosestBankIndex = 1
    for i = 1, #Config.BankLocations do
        if #(PlayerCoords - Config.BankLocations[i].Door.coords) < #(PlayerCoords - Config.BankLocations[ClosestBankIndex].Door.coords) then
            ClosestBankIndex = i
        end
    end
    if #(PlayerCoords - Config.BankLocations[ClosestBankIndex].Door.coords) > 2 then return false end
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
    local ClosestBankIndex = GetClosestBankIndex(source)
    if not ClosestBankIndex then return end

    local PlayerCoords = GetEntityCoords(GetPlayerPed(Source))
    if #(PlayerCoords - Config.BankLocations[ClosestBankIndex].CashStack.coords) > 3.0
end)