AZLINK_VERSION = '0.1.0'

AzLink = AzLink or { }
AzLink.Config = { }

AzLink.lastSent = 0
AzLink.lastFullSent = 0

function AzLink.Fetch(force)
    local timer = GetGameTimer()
    local siteKey = AzLink.Config.site_key
    local baseUrl = AzLink.Config.url

    if siteKey == nil or baseUrl == nil then
        return nil
    end

    if not force and timer - AzLink.lastSent < 15 * 1000 then
        return nil
    end

    local sendFull = os.date("*t").min % 15 == 0 and timer - AzLink.lastFullSent > 60 * 1000

    AzLink.lastSent = timer

    if sendFull then
        AzLink.lastFullSent = timer
    end

    return AzLink.Fetcher:run(sendFull)
end

function AzLink.Ping()
    local siteKey = AzLink.Config.site_key
    local baseUrl = AzLink.Config.url

    if siteKey == nil or baseUrl == nil then
        return nil
    end

    local result = promise.new()

    AzLink.HttpClient:request('GET', '', data):next(function(response)
        result:resolve(response)
    end, function(status)
        if status == 0 then
            print('Unable to connect to the website...')
        else
            print('An HTTP error occurred: ' .. status)
        end
    end)

    return result
end

function AzLink.GetServerData(includeFullData)
    local players = {}

    for _, playerId in ipairs(GetPlayers()) do
        local playerInfo = AzLink.GetPlayerInfo(playerId)

        table.insert(players, {
            uid = AzLink.Config.type == 'cfx' and playerInfo.fivem or playerInfo.steam64,
            name = GetPlayerName(playerId),
        })
    end

    local baseData = {
        platform = {
            type = 'FIVEM',
            name = 'FiveM',
            version = 'cerulean',
        },
        version = AZLINK_VERSION,
        players = players,
        maxPlayers = GetConvarInt('sv_maxclients', 32),
        full = includeFullData,
    }

    if includeFullData then
        baseData.system = exports.azlink.systemUsage()
    end

    return baseData
end

function AzLink.SaveConfig()
    local jsonConfig = json.encode(AzLink.Config, { indent = true })
    SaveResourceFile(GetCurrentResourceName(), 'config.json', jsonConfig)
end

function AzLink.GetPlayerByCfxId(id)
    return AzLink.GetPlayerByIdentifier('fivem:' .. id)
end

function AzLink.GetPlayerBySteamId64(steamId64)
    local id = string.format('%x', steamId64)

    return AzLink.GetPlayerByIdentifier('steam:' .. id)
end

function AzLink.GetPlayerByIdentifier(id)
    for _, playerId in ipairs(GetPlayers()) do
        for _, value in pairs(GetPlayerIdentifiers(playerId)) do
            if value == id then
                return playerId
            end
        end
    end

    return nil
end

function AzLink.GetPlayerInfo(player)
    local info = {}

    for _, value in pairs(GetPlayerIdentifiers(player)) do
        if string.sub(value, 1, 6) == 'steam:' then
            info.hex = string.sub(value, 7)
            info.steam64 = tonumber(info.hex, 16)
        elseif string.sub(value, 1, 6) == 'fivem:' then
            info.fivem = string.sub(value, 7)
        end
    end

    return info
end

local jsonConfig = LoadResourceFile(GetCurrentResourceName(), 'config.json')

if jsonConfig ~= nil then
    AzLink.Config = json.decode(jsonConfig)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60 * 1000) -- 1 minute (in ms)
        AzLink.Fetch()
    end
end)

print('AzLink successfully enabled.')
