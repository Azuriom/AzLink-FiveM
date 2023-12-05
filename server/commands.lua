local function setupAzLink(baseUrl, siteKey)
    AzLink.Config.url = baseUrl
    AzLink.Config.site_key = siteKey

    AzLink.Ping():next(function(response)
        print('Linked to the website successfully.')

        AzLink.Config.type = response.game == 'fivem' and 'steam' or 'cfx'
        AzLink.SaveConfig()
    end)
end

RegisterCommand('azlink', function(source, args)
    if args[1] == 'setup' then
        if args[2] == nil or args[3] == nil then
            print('You must first add this server in your Azuriom admin dashboard, in the "Servers" section.')

            return
        end

        setupAzLink(args[2], args[3])

        return
    end

    if args[1] == 'status' then
        local result = AzLink.Ping()

        if result == nil then
            print('AzLink is not configured yet, use the "setup" subcommand first.')
            return
        end

        result:next(function()
            print('Connected to the website successfully.')
        end)

        return
    end

    if args[1] == 'fetch' then
        local result = AzLink.Fetch(true)

        if result == nil then
            print('AzLink is not configured yet, use the "setup" subcommand first.')
            return
        end

        result:next(function()
            print('Data has been fetched successfully.')
        end)

        return
    end

    print('Unknown subcommand. Must be "setup", "status" or "fetch".')
end, true)
