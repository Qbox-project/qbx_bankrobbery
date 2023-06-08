local IsInsideZone
local ClosestBankIndex = 1
local CurrentBank = Config.BankLocations[ClosestBankIndex]

local function DrawText3D(coords, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function StartBankThread()
    CreateThread(function()
        while IsInsideZone do
            local WaitTime = 800
            local PlayerCoords = GetEntityCoords(cache.ped)
            if #(PlayerCoords - CurrentBank.CashStack.coords.xyz) <= 0.9 and not CurrentBank.CashStack.taken then
                WaitTime = 0
                DrawText3D(CurrentBank.CashStack.coords, Lang:t('text.take_cashstack'))
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent('qb-bankrobbery:server:takeCashStack')
                end
            end
            for i = 1, #CurrentBank.Lockers do
                if #(PlayerCoords - CurrentBank.Lockers[i].coords.xyz) <= 0.8 and not CurrentBank.Lockers[i].taken then
                    WaitTime = 0
                    DrawText3D(CurrentBank.Lockers[i].coords.xyz, Lang:t('text.crack_locker'))
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('qb-bankrobbery:server:crackLocker')
                    end
                end
            end
            Wait(WaitTime)
        end
    end)
end

local function GetClosestBankIndex()
    local PlayerCoords = GetEntityCoords(cache.ped)
    for i = 1, #Config.BankLocations do
        if #(PlayerCoords - Config.BankLocations[i].Door.coords) < #(PlayerCoords - Config.BankLocations[ClosestBankIndex].Door.coords) then
            ClosestBankIndex = i
        end
    end
end

local function onExit()
    IsInsideZone = false
end

local function onEnter()
    IsInsideZone = true
    GetClosestBankIndex()
    CurrentBank = Config.BankLocations[ClosestBankIndex]
    CreateModelSwap(CurrentBank.Door.coords.x, CurrentBank.Door.coords.y, CurrentBank.Door.coords.z, 4.0, `v_ilev_gb_vauldr`, `hei_prop_heist_sec_door`, true)
    StartBankThread()
end

for i = 1, #Config.BankLocations do
    lib.zones.poly({
        points = Config.BankLocations[i].Zone.points,
        thickness = Config.BankLocations[i].Zone.thickness,
        debug = false,
        onEnter = onEnter,
        onExit = onExit,
    })
end

lib.callback.register('qb-bankrobbery:callback:startDoorHack', function()
    local Result = promise.new()
    -- local AnimDict, AnimName, PropName = 'missheist_agency2aig_2', 'look_at_phone_c', 'ch_prop_ch_phone_ing_01a'
    -- lib.requestAnimDict(AnimDict)
    -- TaskPlayAnim(cache.ped, AnimDict, AnimName, 1.0, 1.0, -1, 49, 1.0)
    -- RemoveAnimDict(AnimDict)
    -- lib.requestModel(PropName)
    local Coords = GetEntityCoords(cache.ped)
    -- local Phone = CreateObject(PropName, Coords.x, Coords.y, Coords.z, true, true, false)
    -- AttachEntityToEntity(Phone, cache.ped, GetPedBoneIndex(cache.ped, 60309), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 0, true)
    -- SetModelAsNoLongerNeeded(PropName)
    -- if lib.progressCircle({
    --     duration = 2000,
    --     position = 'bottom',
    --     useWhileDead = false,
    --     canCancel = false,
    --     disable = {
    --         car = true,
    --         move = true
    --     }
    -- }) then
    --     TriggerEvent("mhacking:show")
    --     TriggerEvent("mhacking:start", math.random(6, 7), math.random(12, 15), function(Success)
    --         TriggerEvent('mhacking:hide')
    --         ClearPedTasks(cache.ped)
    --         DeleteEntity(Phone)
    --         Result:resolve(true)
    --     end)
    -- end
    Result:resolve(true)
    local BankDoor = GetClosestObjectOfType(Coords.x, Coords.y, Coords.z, 4.0, CurrentBank.Door.hash, false, false, false)
    local DoorID = NetworkGetEntityIsNetworked(BankDoor) and NetworkGetNetworkIdFromEntity(BankDoor)
    if not DoorID then
        NetworkRegisterEntityAsNetworked(BankDoor)
        DoorID = NetworkGetNetworkIdFromEntity(BankDoor)
        NetworkUseHighPrecisionBlending(DoorID, false)
        SetNetworkIdExistsOnAllMachines(DoorID, true)
        SetNetworkIdCanMigrate(DoorID, true)
    end
    return Citizen.Await(Result), DoorID
end)

AddStateBagChangeHandler('vaultOpening', nil, function(bagName, key, value)
    local Entity = GetEntityFromStateBagName(bagName) -- Errors for players out of scope once going into scope. Cuz not really networked entity. Future problem, eh.
    if Entity == 0 then return end
    if not DoesEntityExist(Entity) then return end
    lib.requestAnimDict('anim@heists@fleeca_bank@bank_vault_door')
    PlayEntityAnim(Entity, 'bank_vault_door_opens', 'anim@heists@fleeca_bank@bank_vault_door', 4.0, false, true, false, 0.0, 8)
    Wait(GetAnimDuration('anim@heists@fleeca_bank@bank_vault_door', 'bank_vault_door_opens') * 1000)
    FreezeEntityPosition(Entity, true)
    StopEntityAnim(Entity, 'bank_vault_door_opens', 'anim@heists@fleeca_bank@bank_vault_door', -1000.0)
    SetEntityHeading(Entity, GetEntityHeading(Entity) + -78.2)
end)

lib.callback.register('qb-bankrobbery:callback:startCashStack', function(BagID)
    local Bag = NetworkGetEntityFromNetworkId(BagID)
    local CashStack = GetClosestObjectOfType(CurrentBank.CashStack.coords.x, CurrentBank.CashStack.coords.y, CurrentBank.CashStack.coords.z, 4.0, `h4_prop_h4_cash_stack_01a`, false, false, false)
    if CashStack == 0 then return end
    local CashRotation = GetEntityRotation(CashStack)
    SetPedComponentVariation(cache.ped, 5, 0, 0, 0)
    local GrabCashEnter = NetworkCreateSynchronisedScene(CurrentBank.CashStack.coords.x, CurrentBank.CashStack.coords.y, CurrentBank.CashStack.coords.z, CashRotation.x, CashRotation.y, CashRotation.z, 2, true, false, 1.0, 0.0, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, GrabCashEnter, 'anim@scripted@player@mission@tun_table_grab@cash@', 'enter', 4.0, -4.0, 1033, 0, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(Bag, GrabCashEnter, 'anim@scripted@player@mission@tun_table_grab@cash@', 'enter_bag', 1000.0, -1000.0, 0)
    NetworkStartSynchronisedScene(GrabCashEnter)
    Wait(GetAnimDuration('anim@scripted@player@mission@tun_table_grab@cash@', 'enter') * 1000)
    local GrabCashAction = NetworkCreateSynchronisedScene(CurrentBank.CashStack.coords.x, CurrentBank.CashStack.coords.y, CurrentBank.CashStack.coords.z, CashRotation.x, CashRotation.y, CashRotation.z, 2, true, false, 1.0, 0.0, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, GrabCashAction, 'anim@scripted@player@mission@tun_table_grab@cash@', 'grab', 4.0, -4.0, 1033, 0, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(Bag, GrabCashAction, 'anim@scripted@player@mission@tun_table_grab@cash@', 'grab_bag', 1000.0, -1000.0, 0)
    NetworkAddEntityToSynchronisedScene(CashStack, GrabCashAction, 'anim@scripted@player@mission@tun_table_grab@cash@', 'grab_cash', 1000.0, -1000.0, 2)
    NetworkStartSynchronisedScene(GrabCashAction)
    Wait(GetAnimDuration('anim@scripted@player@mission@tun_table_grab@cash@', 'grab') * 985)
    local GrabCashEnd = NetworkCreateSynchronisedScene(CurrentBank.CashStack.coords.x, CurrentBank.CashStack.coords.y, CurrentBank.CashStack.coords.z, CashRotation.x, CashRotation.y, CashRotation.z, 2, false, false, 1.0, 0.0, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, GrabCashEnd, 'anim@scripted@player@mission@tun_table_grab@cash@', 'exit', 4.0, -4.0, 1033, 0, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(Bag, GrabCashEnd, 'anim@scripted@player@mission@tun_table_grab@cash@', 'exit_bag', 1000.0, -1000.0, 0)
    NetworkStartSynchronisedScene(GrabCashEnd)
    return NetworkGetNetworkIdFromEntity(CashStack), GetAnimDuration('anim@scripted@player@mission@tun_table_grab@cash@', 'exit') * 950
end)

lib.callback.register('qb-bankrobbery:callback:startlockpick', function()
    LockPicking = promise.new()
    TaskPlayAnim(cache.ped, 'mini@safe_cracking', 'step_into', 8.0, 8.0, -1, 0, 0.0, false, false, false)
    Wait(GetAnimDuration('mini@safe_cracking', 'step_into') * 1000)
    TaskPlayAnim(cache.ped, 'mini@safe_cracking', 'dial_turn_clock_normal', 8.0, 8.0, -1, 1, 0.0, false, false, false)
    TriggerEvent('SafeCracker:StartMinigame', { math.random(150, 450), math.random(1.0, 100.0), math.random(360, 450), math.random(300.0, 340.0), math.random(350, 400), math.random(320.0, 340.0), math.random(350, 600) }, math.random(7, 15), function(Result)
        LockPicking:resolve(Result)
    end)
    local Result = Citizen.Await(LockPicking)
    TaskPlayAnim(cache.ped, 'mini@safe_cracking', 'step_out', 8.0, 8.0, -1, 0, 0.0, false, false, false)
    return Result
end)

lib.callback.register('qb-bankrobbery:callback:startdrill', function(BagID, DrillID, ClosestLocker)
    local Bag = NetworkGetEntityFromNetworkId(BagID)
    local Drill = NetworkGetEntityFromNetworkId(DrillID)
    local WaitTime
    SetPedComponentVariation(cache.ped, 5, 0, 0, 0)
    local Rotation = GetEntityRotation(cache.ped, 2)
    local DrillEnter = NetworkCreateSynchronisedScene(CurrentBank.Lockers[ClosestLocker].coords.x, CurrentBank.Lockers[ClosestLocker].coords.y, CurrentBank.Lockers[ClosestLocker].coords.z + 0.24, Rotation.x, Rotation.y, Rotation.z, 2, true, false, 1.0, 0.0, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, DrillEnter, 'anim@heists@fleeca_bank@drilling', 'intro', 1000.0, -1.5, 0, 0, 0, 0)
    NetworkAddEntityToSynchronisedScene(Bag, DrillEnter, 'anim@heists@fleeca_bank@drilling', 'bag_intro', 1000.0, -1.5, 0)
    NetworkStartSynchronisedScene(DrillEnter)
    Wait(GetAnimDuration('anim@heists@fleeca_bank@drilling', 'intro') * 1000)
    local DrillIdle = NetworkCreateSynchronisedScene(CurrentBank.Lockers[ClosestLocker].coords.x, CurrentBank.Lockers[ClosestLocker].coords.y, CurrentBank.Lockers[ClosestLocker].coords.z + 0.24, Rotation.x, Rotation.y, Rotation.z, 2, false, true, 1.0, 0.0, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, DrillIdle, 'anim@heists@fleeca_bank@drilling', 'drill_straight_start', 1000.0, 0.0, 0, 0, 0, 0)
    NetworkStartSynchronisedScene(DrillIdle)
    local Result = StartDrillingMinigame(Drill)
    local DrillOutro = NetworkCreateSynchronisedScene(CurrentBank.Lockers[ClosestLocker].coords.x, CurrentBank.Lockers[ClosestLocker].coords.y, CurrentBank.Lockers[ClosestLocker].coords.z + 0.24, Rotation.x, Rotation.y, Rotation.z, 2, true, false, 1.0, 0.0, 1.0)
    Wait(600)
    if Result then
        NetworkAddPedToSynchronisedScene(cache.ped, DrillOutro, 'anim@heists@fleeca_bank@drilling', 'outro', 1000.0, -8.0, 3341, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(Bag, DrillOutro, 'anim@heists@fleeca_bank@drilling', 'bag_outro', 1000.0, -8.0, 0)
        WaitTime = GetAnimDuration('anim@heists@fleeca_bank@drilling', 'outro') * 1000
    else
        NetworkAddPedToSynchronisedScene(cache.ped, DrillOutro, 'anim@heists@fleeca_bank@drilling', 'exit', 1000.0, -8.0, 3341, 16, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(Bag, DrillOutro, 'anim@heists@fleeca_bank@drilling', 'bag_exit', 1000.0, -8.0, 0)
        WaitTime = GetAnimDuration('anim@heists@fleeca_bank@drilling', 'exit') * 1000
    end
    NetworkStartSynchronisedScene(DrillOutro)
    Wait(WaitTime)
    return Result
end)

AddStateBagChangeHandler('drillAttachEntity', nil, function(bagName, key, value)
    local Entity = GetEntityFromStateBagName(bagName)
    if Entity == 0 then return end
    if not DoesEntityExist(Entity) then return end
    if NetworkGetEntityOwner(Entity) ~= cache.playerId then return end
    AttachEntityToEntity(Entity, GetPlayerPed(GetPlayerFromServerId(value)), GetPedBoneIndex(cache.ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
end)
