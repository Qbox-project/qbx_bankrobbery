QBCore = exports['qbx-core']:GetCoreObject()
IsABankActive = false

QBCore.Functions.CreateUseableItem('electronickit', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not Player.Functions.GetItemByName('electronickit') then return end -- cool
    TriggerClientEvent('electronickit:UseElectronickit', source)
    TriggerEvent('electronickit:UseElectronickit', source)
end)
