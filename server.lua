ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('esx_oilwells:getOilwellOwner', function(source, cb, oilwellName)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local ownerIdentifier = nil

    MySQL.Async.fetchScalar('SELECT owner FROM oilwells WHERE name = @name', {
        ['@name'] = oilwellName
    }, function(result)
        if result then
            ownerIdentifier = result
        end
        cb(ownerIdentifier)
    end)
end)


RegisterCommand("giveoilwell", function(source, args, rawCommand)
    local _source = source
    local targetId = tonumber(args[1])
    local oilwellName = args[2]

    if _source ~= 0 then
        local xPlayer = ESX.GetPlayerFromId(_source)
        if xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin' then
            local target = ESX.GetPlayerFromId(targetId)
            if target then
                local found = false
                for k, v in pairs(Config.Oilwells) do
                    if k == oilwellName then
                        found = true
                        break
                    end
                end
                if found then
                    MySQL.Async.execute('UPDATE oilwells SET owner = @owner WHERE name = @name', {
                        ['@owner'] = target.getIdentifier(),
                        ['@name'] = oilwellName
                    }, function(rowsChanged)
                        if rowsChanged > 0 then
                            TriggerClientEvent('esx_oilwells:updateBlip', -1, oilwellName, targetId)
                            xPlayer.showNotification("~g~You have given the oilwell to the player!")
                            target.showNotification("~g~You have received an oilwell!")
                        else
                            xPlayer.showNotification("~r~Error giving the oilwell.")
                        end
                    end)
                else
                    xPlayer.showNotification("~r~Invalid oilwell name.")
                end
            else
                xPlayer.showNotification("~r~Invalid player ID.")
            end
        else
            xPlayer.showNotification("~r~You do not have permissions to use this command!")
        end
    end
end, false)


RegisterCommand("deloilwell", function(source, args, rawCommand)
    local _source = source
    local targetId = tonumber(args[1])
    local oilwellName = args[2]

    if _source ~= 0 then
        local xPlayer = ESX.GetPlayerFromId(_source)
        if xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin' then
            local target = ESX.GetPlayerFromId(targetId)
            if target then
                MySQL.Async.execute('UPDATE oilwells SET owner = "" WHERE name = @name', {
                    ['@name'] = oilwellName
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        TriggerClientEvent('esx_oilwells:updateBlip', -1, oilwellName)
                        xPlayer.showNotification("~g~You have removed the owner from the oilwell.")
                        target.showNotification("~r~Your oilwell has been removed!")
                    else
                        xPlayer.showNotification("~r~Error removing the owner from the oilwell.")
                    end
                end)
            else
                xPlayer.showNotification("~r~Invalid player ID!")
            end
        else
            xPlayer.showNotification("~r~You do not have permissions to use this command.")
        end
    end
end, false)

ESX.RegisterServerCallback('esx_oilwells:getMoneyGenerated', function(source, cb, oilwellName)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    MySQL.Async.fetchScalar('SELECT money_generated FROM oilwells WHERE owner = @owner AND name = @name', {
        ['@owner'] = xPlayer.identifier,
        ['@name'] = oilwellName
    }, function(moneyGenerated)
        if moneyGenerated then
            cb(moneyGenerated)
        else
            cb(0)
        end
    end)
end)

ESX.RegisterServerCallback('esx_oilwells:claimMoney', function(source, cb, oilwellName)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    MySQL.Async.fetchScalar('SELECT money_generated FROM oilwells WHERE owner = @owner AND name = @name', {
        ['@owner'] = xPlayer.identifier,
        ['@name'] = oilwellName
    }, function(moneyGenerated)
        if moneyGenerated and moneyGenerated > 0 then
            MySQL.Async.execute('UPDATE oilwells SET money_generated = 0 WHERE owner = @owner AND name = @name', {
                ['@owner'] = xPlayer.identifier,
                ['@name'] = oilwellName
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    xPlayer.addMoney(moneyGenerated)
                    local formattedMoney = ESX.Math.GroupDigits(moneyGenerated)
                    xPlayer.showNotification('You have received ~g~$' .. formattedMoney .. ' ~w~from your oilwell.', 'success', 'centerLeft')
                    cb(true)
                else
                    cb(false)
                end
            end)
        else
            cb(false)
        end
    end)
end)


local function GenerateOilwellMoney()
    MySQL.Async.fetchAll('SELECT * FROM oilwells WHERE owner IS NOT NULL', {}, function(oilwells)
        for _, oilwell in ipairs(oilwells) do
            local newMoney = oilwell.money_generated + Config.MoneyGenerationAmount
            if newMoney > Config.MaxMoneyGenerated then
                newMoney = Config.MaxMoneyGenerated
            end

            MySQL.Async.execute('UPDATE oilwells SET money_generated = @money_generated WHERE id = @id', {
                ['@money_generated'] = newMoney,
                ['@id'] = oilwell.id
            })
        end
    end)
end

-- Generate money for oilwells periodically
Citizen.CreateThread(function()
    while true do
        GenerateOilwellMoney()
        Citizen.Wait(Config.MoneyGenerationInterval * 60 * 1000) -- Convert minutes to milliseconds
    end
end)
