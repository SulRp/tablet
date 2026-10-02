local QBCore = exports['qb-core']:GetCoreObject()
local isOpen, tabletSlot = false, nil
local function closeTablet()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({action='close'})
end
exports('useTablet', function(data, slot)
    exports.ox_inventory:useItem(data, function(usedData)
        if usedData then TriggerServerEvent('qb-tablet:server:use', slot) end
    end)
end)
RegisterNetEvent('qb-tablet:client:open', function(slot, state, apps)
    if isOpen then return end
    isOpen, tabletSlot = true, slot
    SetNuiFocus(true, true)
    SendNUIMessage({action='open',state=state,apps=apps,resource=GetCurrentResourceName()})
end)
if Config.OpenCommand then RegisterCommand(Config.OpenCommand, function() QBCore.Functions.Notify('Use o item tablet para abrir o aparelho.', 'primary') end, false) end
RegisterNUICallback('close', function(_, cb) closeTablet(); cb({ok=true}) end)
RegisterNUICallback('save', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-tablet:server:save', function(result) cb(result or {ok=false}) end, tabletSlot, data.action, data.id, data.value)
end)
RegisterNUICallback('integrationData', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-tablet:server:getIntegrationData', function(result) cb(result or {ok=false}) end, data.id)
end)
RegisterNUICallback('judicialCases', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-tablet:server:getJudicialCases', function(result) cb(result or {ok=false}) end)
end)
RegisterNUICallback('createJudicialCase', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-tablet:server:createJudicialCase', function(result) cb(result or {ok=false}) end, data)
end)
RegisterNUICallback('markLocation', function(data, cb)
    local x, y = tonumber(data.x), tonumber(data.y)
    if not x or not y or math.abs(x) > 10000 or math.abs(y) > 10000 then cb({ok=false}); return end
    SetNewWaypoint(x, y)
    cb({ok=true})
end)
AddEventHandler('onResourceStop', function(resource) if resource == GetCurrentResourceName() then SetNuiFocus(false,false) end end)
RegisterNUICallback('launchResource', function(data, cb)
    local command = Config.LaunchCommands and Config.LaunchCommands[data.id]
    if type(command) ~= 'string' then cb({ok=false}); return end
    closeTablet()
    CreateThread(function()
        Wait(350)
        ExecuteCommand(command)
    end)
    cb({ok=true})
end)
