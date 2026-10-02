local QBCore = exports['qb-core']:GetCoreObject()
Proxy = module('vrp', 'lib/Proxy')
local vRP = Proxy.getInterface('vRP')

local function getRebornUserId(source)
    if GetResourceState('vrp') ~= 'started' then return nil end
    local ok, userId = pcall(function() return vRP.getUserId(source) end)
    if ok then return userId end
    return nil
end

QBCore.Functions.CreateCallback('qb-tablet:server:getIntegrationData', function(source, cb, appId)
    local userId = getRebornUserId(source)
    if not userId then cb({ ok=false, error='vrp_unavailable' }); return end

    if appId == 'homes' then
        if GetResourceState('will_homes') ~= 'started' then cb({ok=false,error='homes_unavailable'}); return end
        local ok, houses = pcall(function() return exports['will_homes']:Homes() end)
        if not ok or type(houses) ~= 'table' then cb({ok=false,error='homes_unavailable'}); return end
        local result = {}
        for id, home in pairs(houses) do
            if type(home) == 'table' and tostring(home.owner) == tostring(userId) then
                local coords = home.coords and (home.coords.house_out or home.coords.house_in)
                result[#result + 1] = {
                    id=tostring(id), name=tostring(home.name or ('Imóvel '..id)),
                    x=coords and coords.x or nil, y=coords and coords.y or nil,
                    price=tonumber(home.price) or 0, theme=tostring(home.theme or '')
                }
            end
        end
        cb({ok=true,items=result})
        return
    end

    if appId == 'garage' then
        if GetResourceState('will_garages_v2') ~= 'started' then cb({ok=false,error='garage_unavailable'}); return end
        local ok, vehicles = pcall(function() return vRP.query('will/get_owned_vehicles', { user_id=userId }) end)
        if not ok or type(vehicles) ~= 'table' then cb({ok=false,error='garage_unavailable'}); return end
        local result = {}
        for _, vehicle in pairs(vehicles) do
            local label = tostring(vehicle.vehicle or 'Veículo')
            pcall(function() label = exports['will_garages_v2']:getVehicleName(vehicle.vehicle) or label end)
            result[#result + 1] = {
                model=tostring(vehicle.vehicle or ''), label=label,
                plate=tostring(vehicle.plate or ''), garage=tostring(vehicle.garage or ''),
                stored=tostring(vehicle.stored or ''), arrest=tonumber(vehicle.arrest) or 0,
                engine=tonumber(vehicle.engine) or 0, body=tonumber(vehicle.body) or 0,
                fuel=tonumber(vehicle.fuel) or 0
            }
        end
        cb({ok=true,items=result})
        return
    end

    if appId == 'gov' then
        local identity = nil
        local identityOk, identityResult = pcall(function() return vRP.getUserIdentity(userId) end)
        if identityOk and type(identityResult) == 'table' then identity = identityResult end

        local firstName = identity and (identity.name or identity.firstname or identity.firstName) or nil
        local lastName = identity and (identity.name2 or identity.lastname or identity.lastName) or nil
        local fullName = table.concat({ tostring(firstName or ''), tostring(lastName or '') }, ' '):gsub('%s+', ' '):match('^%s*(.-)%s*$')
        if fullName == '' then fullName = 'Cadastro indisponivel' end

        local vehicles = {}
        local vehiclesAvailable = false
        if GetResourceState('will_garages_v2') == 'started' then
            local ok, rows = pcall(function() return vRP.query('will/get_owned_vehicles', { user_id=userId }) end)
            if ok and type(rows) == 'table' then
                vehiclesAvailable = true
                for _, vehicle in pairs(rows) do
                    local label = tostring(vehicle.vehicle or 'Veiculo')
                    pcall(function() label = exports['will_garages_v2']:getVehicleName(vehicle.vehicle) or label end)
                    vehicles[#vehicles + 1] = {
                        label=label,
                        model=tostring(vehicle.vehicle or ''),
                        plate=tostring(vehicle.plate or ''),
                        stored=tostring(vehicle.stored or ''),
                        arrest=tonumber(vehicle.arrest) or 0
                    }
                end
            end
        end

        cb({
            ok=true,
            profile={
                passport=tostring(userId),
                name=fullName,
                age=tostring((identity and identity.age) or ''),
                phone=tostring((identity and identity.phone) or ''),
                registration=tostring((identity and identity.registration) or '')
            },
            vehicles=vehicles,
            vehiclesAvailable=vehiclesAvailable
        })
        return
    end

    cb({ok=false,error='invalid_app'})
end)

local function callJudicialExport(source, exportName, ...)
    if GetResourceState('reborn_judicial') ~= 'started' then
        return { ok = false, error = 'judicial_unavailable' }
    end
    local args = { ... }
    local ok, result = pcall(function()
        local judicial = exports['reborn_judicial']
        return judicial[exportName](judicial, source, table.unpack(args))
    end)
    if not ok or type(result) ~= 'table' then
        return { ok = false, error = 'judicial_unavailable' }
    end
    return result
end

QBCore.Functions.CreateCallback('qb-tablet:server:getJudicialCases', function(source, cb)
    cb(callJudicialExport(source, 'getCases'))
end)

QBCore.Functions.CreateCallback('qb-tablet:server:createJudicialCase', function(source, cb, data)
    if type(data) ~= 'table' then cb({ ok = false, error = 'invalid_data' }); return end
    cb(callJudicialExport(source, 'createCase', data.party, data.caseType, data.summary))
end)
