local QBCore = exports['qb-core']:GetCoreObject()
local function appCatalog()
    local apps = {}
    for _, app in ipairs(Config.Apps) do
        apps[#apps + 1] = { id=app.id, label=app.label, description=app.description, icon=app.icon, iconImage=app.iconImage, url=('apps/%s/index.html'):format(app.folder) }
    end
    for _, app in ipairs(Config.CoreApps) do apps[#apps + 1] = app end
    return apps
end
local function validApp(id)
    for _, app in ipairs(Config.Apps) do if app.id == id then return true end end
    return false
end
local function getState(metadata)
    local state = metadata[Config.MetadataKey]
    if type(state) ~= 'table' then state = { installed={}, data={} } end
    if type(state.installed) ~= 'table' then state.installed = {} end
    if type(state.data) ~= 'table' then state.data = {} end
    for _, app in ipairs(Config.Apps) do
        if state.installed[app.id] == nil then state.installed[app.id] = app.defaultInstalled == true end
    end
    return state
end
local function persist(source, slot, metadata, state)
    metadata[Config.MetadataKey] = state
    exports.ox_inventory:SetMetadata(source, slot, metadata)
end
RegisterNetEvent('qb-tablet:server:use', function(slot)
    local src = source
    slot = tonumber(slot)
    local item = slot and exports.ox_inventory:GetSlot(src, slot)
    if not item or item.name ~= Config.ItemName then return end
    local metadata = item.metadata or {}
    local state = getState(metadata)
    if not state.id then
        state.id = ('TAB-%05d-%04d'):format(os.time() % 100000, math.random(1000, 9999))
        persist(src, slot, metadata, state)
    elseif not metadata[Config.MetadataKey] then
        persist(src, slot, metadata, state)
    end
    TriggerClientEvent('qb-tablet:client:open', src, slot, state, appCatalog())
end)
QBCore.Functions.CreateCallback('qb-tablet:server:save', function(source, cb, slot, action, appId, value)
    slot = tonumber(slot)
    local item = slot and exports.ox_inventory:GetSlot(source, slot)
    if not item or item.name ~= Config.ItemName then cb({ok=false}); return end
    local metadata = item.metadata or {}
    local state = getState(metadata)
    if not state.id then cb({ok=false}); return end
    if action == 'install' or action == 'remove' then
        if not validApp(appId) then cb({ok=false}); return end
        state.installed[appId] = action == 'install'
    elseif action == 'data' then
        if not validApp(appId) or type(value) ~= 'table' then cb({ok=false}); return end
        if #json.encode(value) > 12000 then cb({ok=false,error='too_large'}); return end
        state.data[appId] = value
    else cb({ok=false}); return end
    persist(source, slot, metadata, state)
    cb({ok=true,state=state})
end)
