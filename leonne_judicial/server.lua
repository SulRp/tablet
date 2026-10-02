Proxy = module('vrp', 'lib/Proxy')
local vRP = Proxy.getInterface('vRP')

local DATA_FILE = 'processos.json'
local cases = {}
local nextId = 1

local function loadCases()
    local raw = LoadResourceFile(GetCurrentResourceName(), DATA_FILE)
    if not raw or raw == '' then return end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        print('[leonne_judicial] Nao foi possivel ler processos.json; iniciando lista vazia.')
        return
    end

    cases = type(decoded.cases) == 'table' and decoded.cases or {}
    nextId = tonumber(decoded.nextId) or 1
    for _, case in ipairs(cases) do
        local caseId = tonumber(case.id)
        if caseId and caseId >= nextId then nextId = caseId + 1 end
    end
end

local function saveCases()
    local encoded = json.encode({ cases = cases, nextId = nextId })
    local ok, result = pcall(SaveResourceFile, GetCurrentResourceName(), DATA_FILE, encoded, -1)
    return ok and result ~= false
end

local function getUserId(source)
    if GetResourceState('vrp') ~= 'started' then return nil end
    local ok, userId = pcall(function() return vRP.getUserId(source) end)
    return ok and userId or nil
end

local function hasLawyerPermission(source)
    local userId = getUserId(source)
    if not userId then return false end
    local ok, allowed = pcall(function()
        return vRP.hasPermission(userId, Config.LawyerPermission)
    end)
    return ok and allowed == true, userId
end

local function notify(source, message)
    TriggerClientEvent('chat:addMessage', source, {
        color = { 190, 160, 90 },
        args = { 'Judicial', message }
    })
end

local function cleanText(value, maxLength)
    value = tostring(value or ''):gsub('[\r\n]', ' '):gsub('%s+', ' '):match('^%s*(.-)%s*$')
    if #value > maxLength then value = value:sub(1, maxLength) end
    return value
end

local function sendDiscordNotification(case)
    if Config.DiscordWebhook == '' then return end

    local content = ''
    local allowedMentions = { parse = {} }
    if Config.LawyerRoleId ~= '' then
        content = '<@&' .. Config.LawyerRoleId .. '>'
        allowedMentions.roles = { Config.LawyerRoleId }
    end

    local payload = {
        username = Config.DiscordUsername,
        content = content,
        allowed_mentions = allowedMentions,
        embeds = {{
            title = ('Novo processo #%06d'):format(case.id),
            color = 12555720,
            fields = {
                { name = 'Advogado', value = case.lawyerName, inline = true },
                { name = 'Identificacao', value = ('ID %s'):format(case.lawyerId), inline = true },
                { name = 'Parte envolvida', value = case.party, inline = true },
                { name = 'Tipo de processo', value = case.caseType, inline = true },
                { name = 'Resumo', value = case.summary, inline = false }
            },
            footer = { text = 'Registro criado dentro do servidor' },
            timestamp = case.createdAt
        }}
    }

    PerformHttpRequest(Config.DiscordWebhook, function(status)
        if status < 200 or status >= 300 then
            print(('[leonne_judicial] Discord respondeu com status %s ao enviar o processo #%06d.'):format(status, case.id))
        end
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

local function createCase(source, party, caseType, summary)
    local allowed, userId = hasLawyerPermission(source)
    if not allowed then return { ok = false, error = 'no_permission' } end

    party = cleanText(party, Config.MaxPartyLength)
    caseType = cleanText(caseType, 60)
    summary = cleanText(summary, Config.MaxSummaryLength)
    if party == '' or caseType == '' or summary == '' then
        return { ok = false, error = 'missing_fields' }
    end

    local case = {
        id = nextId,
        lawyerId = tostring(userId),
        lawyerName = cleanText(GetPlayerName(source) or ('ID %s'):format(userId), 80),
        party = party,
        caseType = caseType,
        summary = summary,
        status = 'Aberto',
        createdAt = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }

    cases[#cases + 1] = case
    nextId = nextId + 1
    if not saveCases() then
        cases[#cases] = nil
        nextId = nextId - 1
        return { ok = false, error = 'save_failed' }
    end

    sendDiscordNotification(case)
    return { ok = true, case = case }
end

exports('getCases', function(source)
    local allowed = hasLawyerPermission(source)
    if not allowed then return { ok = false, error = 'no_permission' } end

    local items = {}
    local first = math.max(1, #cases - 49)
    for index = #cases, first, -1 do
        local case = cases[index]
        items[#items + 1] = {
            id = case.id,
            party = case.party,
            caseType = case.caseType,
            summary = case.summary,
            status = case.status,
            lawyerName = case.lawyerName,
            createdAt = case.createdAt
        }
    end
    return { ok = true, items = items }
end)

exports('createCase', function(source, party, caseType, summary)
    return createCase(source, party, caseType, summary)
end)

RegisterCommand('processo', function(source, args)
    if source == 0 then
        print('[leonne_judicial] O comando deve ser usado por um jogador dentro do servidor.')
        return
    end

    local allowed = hasLawyerPermission(source)
    if not allowed then
        notify(source, 'Apenas advogados podem registrar e consultar processos.')
        return
    end

    local action = (args[1] or ''):lower()
    if action == 'ajuda' or action == '' then
        notify(source, 'Uso: /processo criar Parte | Tipo | Resumo')
        notify(source, 'Use /processos para consultar os processos recentes.')
        return
    end

    if action ~= 'criar' then
        notify(source, 'Acao invalida. Use /processo criar Parte | Tipo | Resumo')
        return
    end

    local input = table.concat(args, ' ', 2)
    local party, caseType, summary = input:match('^%s*(.-)%s*|%s*(.-)%s*|%s*(.-)%s*$')
    local result = createCase(source, party, caseType, summary)
    if not result.ok then
        notify(source, result.error == 'save_failed' and 'Nao foi possivel salvar o processo. Avise a administracao.' or 'Preencha os tres campos: Parte | Tipo | Resumo.')
        return
    end
    notify(source, ('Processo #%06d registrado e enviado ao canal judicial.'):format(result.case.id))
end, false)

RegisterCommand('processos', function(source)
    if source == 0 then return end
    local allowed = hasLawyerPermission(source)
    if not allowed then
        notify(source, 'Apenas advogados podem consultar processos.')
        return
    end

    if #cases == 0 then
        notify(source, 'Ainda nao ha processos registrados.')
        return
    end

    local first = math.max(1, #cases - 4)
    for index = #cases, first, -1 do
        local case = cases[index]
        notify(source, ('#%06d | %s | %s | %s'):format(case.id, case.status, case.caseType, case.party))
    end
end, false)

loadCases()
