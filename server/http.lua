local fetcher = {}
local httpClient = {}

function fetcher:run(sendFullData)
    local data = AzLink.GetServerData(sendFullData)
    local result = promise.new()

    httpClient:request('POST', '', data):next(function(commands)
        fetcher:dispatchCommands(commands)

        result:resolve(commands)
    end, function(code)
        if code == 0 then
            print('Unable to connect to the website...')
        else
            print('An HTTP error occurred, code ' .. code)
        end
    end)

    return result
end

function fetcher:dispatchCommands(data)
    if not data.commands then
        return
    end

    local total = 0

    for _, commandData in pairs(data.commands) do
        local playerId

        if data.game == 'fivem-cfx' then
            playerId = AzLink.GetPlayerByCfxId(commandData.uid)
        else
            playerId = AzLink.GetPlayerBySteamId64(commandData.uid)
        end

        local info = playerId and AzLink.GetPlayerInfo(playerId) or { }
        local name = playerId and GetPlayerName(playerId) or commandData.name
        local display = name .. ' (' .. commandData.uid .. ')'

        for _, command in pairs(commandData.values) do
            local playerCommand = command:gsub('{player}', name)
            playerCommand = playerCommand:gsub('{id}', playerId or -1)
            playerCommand = playerCommand:gsub('{fivem_id}', info.fivem or commandData.uid)
            playerCommand = playerCommand:gsub('{steam_id}', info.steam64 or commandData.uid)

            print('Dispatching command to ' .. display .. ': ' .. playerCommand)

            ExecuteCommand(playerCommand)
        end

        total = total + 1
    end

    if total > 0 then
        print('Dispatched commands to ' .. total .. ' players.')
    end
end

function httpClient:request(requestMethod, endpoint, data)
    local result = promise.new()

    PerformHttpRequest(AzLink.Config.url .. '/api/azlink' .. endpoint, function(code, body)
        if code < 200 or code >= 300 then
            result:reject(code)

            return
        end

        result:resolve(body and json.decode(body) or body)
    end, requestMethod, data and json.encode(data) or '', {
        ['Azuriom-Link-Token'] = AzLink.Config.site_key,
        ['Accept'] = 'application/json',
        ['Content-type'] = 'application/json',
        ['User-Agent'] = 'AzLink FiveM v' .. AZLINK_VERSION,
    })

    return result
end

AzLink.Fetcher = fetcher
AzLink.HttpClient = httpClient
