local FM_API_URL = 'https://fivem.fraktionmanager.com'

local FM = {
    ready      = false,
    guildId    = nil,
    disabled   = false,
    lastNotice = nil,
}

local function log(msg)
    print('[fraktion_manager] ' .. msg)
end

local function debug(msg)
    if Config.Debug then log(msg) end
end

local function noticeOnce(msg)
    if FM.lastNotice == msg then return end
    FM.lastNotice = msg
    log(msg)
end

print(' ')
print('^1  ███████╗██████╗  █████╗ ██╗  ██╗████████╗██╗ ██████╗ ███╗   ██╗^0')
print('^1  ██╔════╝██╔══██╗██╔══██╗██║ ██╔╝╚══██╔══╝██║██╔═══██╗████╗  ██║^0')
print('^1  █████╗  ██████╔╝███████║█████╔╝    ██║   ██║██║   ██║██╔██╗ ██║^0')
print('^1  ██╔══╝  ██╔══██╗██╔══██║██╔═██╗    ██║   ██║██║   ██║██║╚██╗██║^0')
print('^1  ██║     ██║  ██║██║  ██║██║  ██╗   ██║   ██║╚██████╔╝██║ ╚████║^0')
print('^1  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝^0')
print(' ')
print('^7  ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗^0')
print('^7  ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗^0')
print('^7  ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝^0')
print('^7  ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗^0')
print('^7  ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║^0')
print('^7  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝^0')
print(' ')
print('^3  Discord : discord.gg/fraktionmanager          Website : fraktionmanager.com^0')
print(' ')

local function extractGuildId(token)
    if type(token) ~= 'string' then return nil end
    local guildId, hmac = token:match('^(%d+)%.(%x+)$')
    if not guildId or #hmac < 32 then return nil end
    return guildId
end

local function checkConfig()
    if not Config.Enabled then
        log('^3Integration ist in config.lua deaktiviert (Config.Enabled = false).^0')
        return false
    end

    if type(Config.ApiToken) ~= 'string' or Config.ApiToken == '' or Config.ApiToken == 'HIER_DEINEN_TOKEN_EINFUEGEN' then
        log('^1Config.ApiToken fehlt.^0 Token im Dashboard holen: Einstellungen, FiveM Integration.')
        return false
    end

    local guildId = extractGuildId(Config.ApiToken)
    if not guildId then
        log('^1Config.ApiToken hat ein unbekanntes Format.^0 Bitte den Token im Dashboard neu kopieren.')
        return false
    end

    FM.guildId = guildId
    return true
end

FM.ready = checkConfig()
if FM.ready then
    log('^2Konfiguration geladen, Server-ID ' .. FM.guildId .. '^0')
end

local function apiPost(endpoint, body, cb)
    if not FM.ready then return end

    PerformHttpRequest(FM_API_URL .. endpoint, function(status, responseText, _)
        local data = nil
        if responseText and responseText ~= '' then
            local okDecode, decoded = pcall(json.decode, responseText)
            if okDecode then data = decoded end
        end

        if status == 403 then

            FM.disabled = true
            noticeOnce('^3' .. ((data and data.error) or 'Zugriff abgelehnt') .. '^0')
        elseif status == 401 then
            FM.disabled = true
            noticeOnce('^1Token wurde nicht akzeptiert.^0 Bitte im Dashboard neu kopieren.')
        elseif status == 503 then
            noticeOnce('^3Die FiveM-Integration ist auf dem Fraktion Manager gerade nicht verfügbar.^0')
        elseif status == 0 or status == -1 then
            noticeOnce('^3Fraktion Manager nicht erreichbar, nächster Versuch beim nächsten Abgleich.^0')
        elseif status >= 200 and status < 300 then
            if FM.disabled then
                FM.disabled = false
                FM.lastNotice = nil
                log('^2Verbindung zum Fraktion Manager wieder hergestellt.^0')
            end
            debug(('POST %s → %d'):format(endpoint, status))
        else
            debug(('POST %s → %d %s'):format(endpoint, status, responseText or ''))
        end

        if cb then cb(status, data) end
    end, 'POST', json.encode(body or {}), {
        ['Content-Type']  = 'application/json',
        ['Authorization'] = 'Bearer ' .. Config.ApiToken,
    })
end

local ESX = nil
local function getESX()
    if ESX then return ESX end
    local ok, obj = pcall(function() return exports['es_extended']:getSharedObject() end)
    if ok and obj then ESX = obj end
    return ESX
end

local function dbQuery(query, params, cb)
    if GetResourceState('oxmysql') == 'started' then
        exports['oxmysql']:execute(query, params, cb)
    elseif GetResourceState('mysql-async') == 'started' and MySQL and MySQL.Async then
        MySQL.Async.fetchAll(query, params, cb)
    else
        debug('Keine unterstützte Datenbank-Resource gefunden (oxmysql oder mysql-async).')
        cb(nil)
    end
end

local function getDiscordId(playerId)
    if not playerId then return nil end
    for _, v in ipairs(GetPlayerIdentifiers(playerId)) do
        if v:sub(1, 8) == 'discord:' then return v:sub(9) end
    end
    return nil
end

local function getCharName(identifier, playerId, cb)
    dbQuery('SELECT firstname, lastname FROM users WHERE identifier = ? LIMIT 1', { identifier }, function(rows)
        local name = nil
        local r = rows and rows[1]
        if r then
            if r.firstname and r.firstname ~= '' and r.lastname and r.lastname ~= '' then
                name = r.firstname .. ' ' .. r.lastname
            elseif r.firstname and r.firstname ~= '' then
                name = r.firstname
            end
        end
        if not name or name == '' then
            name = (playerId and GetPlayerName(playerId)) or identifier
        end
        cb(name)
    end)
end

local function buildGradeList(jobData)
    local grades = {}
    for gradeNum, gradeData in pairs(jobData.grades or {}) do
        table.insert(grades, {
            grade = tonumber(gradeNum),
            label = gradeData.label or ('Grade ' .. tostring(gradeNum)),
            name  = gradeData.name  or ('grade_' .. tostring(gradeNum)),
        })
    end
    table.sort(grades, function(a, b) return (a.grade or 0) < (b.grade or 0) end)
    return grades
end

local onlineUpdateQueued = false

local function sendOnlineUpdate()
    if not FM.ready then return end
    local esx = getESX()
    if not esx then return end

    local online, players, jobGrades = {}, {}, {}
    local allJobs = esx.GetJobs() or {}

    for _, playerId in ipairs(GetPlayers()) do
        local player = esx.GetPlayerFromId(tonumber(playerId))
        if player then
            local job = player.getJob()
            if job and job.name and job.name ~= '' and job.name ~= 'unemployed' then
                online[job.name] = (online[job.name] or 0) + 1
                table.insert(players, {
                    fivem_id   = player.getIdentifier(),
                    server_id  = tonumber(playerId),
                    name       = GetPlayerName(tonumber(playerId)) or player.getIdentifier(),
                    job        = job.name,
                    job_label  = job.label or job.name,
                    job_grade  = job.grade or 0,
                    grade_name = job.grade_name or '',
                })
                if not jobGrades[job.name] and allJobs[job.name] then
                    jobGrades[job.name] = {
                        label  = allJobs[job.name].label or job.name,
                        grades = buildGradeList(allJobs[job.name]),
                    }
                end
            end
        end
    end

    apiPost('/api/fivem/online-update', { online = online, players = players, job_grades = jobGrades })
end

local function queueOnlineUpdate()
    if onlineUpdateQueued then return end
    onlineUpdateQueued = true
    SetTimeout(2000, function()
        onlineUpdateQueued = false
        sendOnlineUpdate()
    end)
end

local function syncJobs()
    local esx = getESX()
    if not esx then
        log('^1ESX nicht gefunden.^0 Läuft es_extended? Die Integration bleibt inaktiv.')
        return
    end

    local jobList, jobGrades = {}, {}
    for jobName, jobData in pairs(esx.GetJobs() or {}) do
        table.insert(jobList, { job_name = jobName, job_label = jobData.label or jobName })
        jobGrades[jobName] = { label = jobData.label or jobName, grades = buildGradeList(jobData) }
    end

    apiPost('/api/fivem/jobs/sync', { jobs = jobList }, function(status)
        if status >= 200 and status < 300 then
            log(('^2%d Jobs synchronisiert^0'):format(#jobList))
        end
    end)
    apiPost('/api/fivem/online-update', { online = {}, players = {}, job_grades = jobGrades })
end

local function syncMembers()
    local query  = "SELECT identifier, job, job_grade FROM users WHERE job IS NOT NULL AND job != ''"
    local params = {}

    if Config.TrackedJobs and #Config.TrackedJobs > 0 then
        local placeholders = {}
        for _, j in ipairs(Config.TrackedJobs) do
            table.insert(placeholders, '?')
            table.insert(params, j)
        end
        query = query .. ' AND job IN (' .. table.concat(placeholders, ',') .. ')'
    end

    dbQuery(query, params, function(rows)
        if not rows or #rows == 0 then return end

        local esx = getESX()
        local onlineByIdentifier = {}
        if esx then
            for _, playerId in ipairs(GetPlayers()) do
                local player = esx.GetPlayerFromId(tonumber(playerId))
                if player then onlineByIdentifier[player.getIdentifier()] = tonumber(playerId) end
            end
        end

        local memberList = {}
        local pending = #rows

        for _, row in ipairs(rows) do
            local r = row
            local onlineId = onlineByIdentifier[r.identifier]
            getCharName(r.identifier, onlineId, function(playerName)
                table.insert(memberList, {
                    fivem_id     = r.identifier,
                    player_name  = playerName,
                    steam_name   = onlineId and GetPlayerName(onlineId) or nil,
                    discord_id   = onlineId and getDiscordId(onlineId) or nil,
                    faction_name = r.job,
                    job_grade    = r.job_grade or 0,
                })
                pending = pending - 1
                if pending == 0 then
                    apiPost('/api/fivem/members/bulk-sync', { members = memberList }, function(status)
                        if status >= 200 and status < 300 then
                            log(('^2%d Mitglieder synchronisiert^0'):format(#memberList))
                        end
                    end)
                    queueOnlineUpdate()
                end
            end)
        end
    end)
end

CreateThread(function()
    if not FM.ready then return end

    Wait(5000)

    if Config.SyncJobsOnStart then
        syncJobs()
        Wait(2000)
        syncMembers()
    end

    local interval = math.max(tonumber(Config.OnlineSyncInterval) or 60, 30)
    while true do
        Wait(interval * 1000)
        sendOnlineUpdate()
    end
end)

local function reportMember(playerId, job, previousJobName)
    local esx = getESX()
    if not esx then return end
    local player = esx.GetPlayerFromId(playerId)
    if not player then return end

    local identifier = player.getIdentifier()
    getCharName(identifier, playerId, function(name)
        apiPost('/api/fivem/member/update', {
            faction_name          = job.name,
            previous_faction_name = previousJobName,
            fivem_id              = identifier,
            player_name           = name,
            steam_name            = GetPlayerName(playerId),
            discord_id            = getDiscordId(playerId),
            job_grade             = job.grade,
        })
    end)
    queueOnlineUpdate()
end

AddEventHandler('esx:setJob', function(playerId, job, lastJob)
    if not job or not job.name then return end
    reportMember(playerId, job, lastJob and lastJob.name or nil)
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    if not xPlayer then return end
    local job = xPlayer.getJob()
    if not job or not job.name then return end
    reportMember(playerId, job, nil)
end)

AddEventHandler('playerDropped', function()
    queueOnlineUpdate()
end)

RegisterNetEvent('fraktionmanager:requestIngameToken')
AddEventHandler('fraktionmanager:requestIngameToken', function()
    local src = source
    if not FM.ready then
        TriggerClientEvent('fraktionmanager:ingameTokenReady', src, nil, nil)
        return
    end

    local licenseId = GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 0)
    if not licenseId then
        TriggerClientEvent('fraktionmanager:ingameTokenReady', src, nil, nil)
        return
    end

    debug('Ingame-Login angefordert von Spieler ' .. tostring(src))
    apiPost('/api/auth/ingame-token-create', { licenseId = licenseId }, function(status, data)
        if status == 200 and data and data.success and data.url then
            TriggerClientEvent('fraktionmanager:ingameTokenReady', src, data.token, data.url)
        else
            TriggerClientEvent('fraktionmanager:ingameTokenReady', src, nil, nil)
        end
    end)
end)

local function isAuthorized(req)
    local headers = req.headers or {}
    local auth = headers['Authorization'] or headers['authorization']

    if type(auth) == 'table' then auth = auth[1] end
    if type(auth) ~= 'string' then return false end
    local token = auth:match('^[Bb]earer%s+(.+)$')
    if not token then return false end

    return #token == #Config.ApiToken and token == Config.ApiToken
end

local function sendJson(res, status, body)
    res.writeHead(status, { ['Content-Type'] = 'application/json' })
    res.send(json.encode(body))
end

local function collectOnlinePlayers()
    local esx = getESX()
    local players = {}
    if not esx then return players end
    for _, playerId in ipairs(GetPlayers()) do
        local player = esx.GetPlayerFromId(tonumber(playerId))
        if player then
            local job = player.getJob()
            table.insert(players, {
                fivem_id   = player.getIdentifier(),
                server_id  = tonumber(playerId),
                name       = GetPlayerName(tonumber(playerId)) or player.getIdentifier(),
                job        = job and job.name or '',
                job_label  = job and (job.label or job.name) or '',
                job_grade  = job and (job.grade or 0) or 0,
                grade_name = job and (job.grade_name or '') or '',
            })
        end
    end
    return players
end

local function urlDecode(value)
    return (value or ''):gsub('+', ' '):gsub('%%(%x%x)', function(h)
        return string.char(tonumber(h, 16))
    end)
end

local function queryParam(address, key)
    local raw = (address or ''):match('[?&]' .. key .. '=([^&]*)')
    return urlDecode(raw)
end

SetHttpHandler(function(req, res)
    local path = req.path or ''

    if not FM.ready then
        sendJson(res, 503, { error = 'Resource ist nicht konfiguriert' })
        return
    end

    if path:match('^/fm/job%-grades') then
        if req.method ~= 'GET' then sendJson(res, 405, { error = 'Method not allowed' }); return end
        if not isAuthorized(req) then sendJson(res, 403, { error = 'Unauthorized' }); return end

        local jobName = queryParam(req.address, 'job')
        if jobName == '' then sendJson(res, 400, { error = 'job parameter required' }); return end

        dbQuery('SELECT grade, name, label FROM job_grades WHERE job_name = ? ORDER BY grade ASC', { jobName }, function(rows)
            if not rows or #rows == 0 then
                sendJson(res, 404, { error = 'Job not found or no grades', job = jobName })
                return
            end
            local grades = {}
            for _, row in ipairs(rows) do
                table.insert(grades, {
                    grade = tonumber(row.grade),
                    label = row.label or ('Grade ' .. tostring(row.grade)),
                    name  = row.name  or ('grade_' .. tostring(row.grade)),
                })
            end
            sendJson(res, 200, { grades = grades, job = jobName })
        end)
        return
    end

    if path:match('^/fm/online%-players') then
        if req.method ~= 'GET' then sendJson(res, 405, { error = 'Method not allowed' }); return end
        if not isAuthorized(req) then sendJson(res, 403, { error = 'Unauthorized' }); return end
        sendJson(res, 200, { players = collectOnlinePlayers() })
        return
    end

    if path:match('^/fm/set%-job') then
        if req.method ~= 'POST' then sendJson(res, 405, { error = 'Method not allowed' }); return end
        if not isAuthorized(req) then sendJson(res, 403, { error = 'Unauthorized' }); return end

        req.setDataHandler(function(rawBody)
            local okDecode, body = pcall(json.decode, rawBody or '{}')
            if not okDecode or type(body) ~= 'table' then
                sendJson(res, 400, { error = 'invalid json' })
                return
            end

            local fivemId  = body.fivem_id or ''
            local jobName  = body.job_name or ''
            local jobGrade = tonumber(body.job_grade) or 0
            if fivemId == '' or jobName == '' then
                sendJson(res, 400, { error = 'fivem_id and job_name required' })
                return
            end

            local esx = getESX()
            if not esx then sendJson(res, 503, { error = 'ESX not available' }); return end

            for _, playerId in ipairs(GetPlayers()) do
                local player = esx.GetPlayerFromId(tonumber(playerId))
                if player and player.getIdentifier() == fivemId then
                    player.setJob(jobName, jobGrade)
                    debug(('setJob: %s → %s grade %d'):format(fivemId, jobName, jobGrade))
                    sendJson(res, 200, { success = true })
                    queueOnlineUpdate()
                    return
                end
            end
            sendJson(res, 404, { error = 'Player not online', fivem_id = fivemId })
        end)
        return
    end

    sendJson(res, 404, { error = 'Not found' })
end)
