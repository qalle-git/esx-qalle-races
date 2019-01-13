ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('esx-qalle-races:getMoney', function(source, cb, money)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer ~= nil then
        if xPlayer.getMoney() >= money then
            xPlayer.removeMoney(money)
            cb(true)
        else
            cb(false)
        end
    else
        cb(false)
    end

end)

RegisterServerEvent('esx-qalle-races:addTime')
AddEventHandler('esx-qalle-races:addTime', function(time, race)
    local xPlayer = ESX.GetPlayerFromId(source)

    local name = "none"

    time = time

    local sql = [[
        SELECT
            firstname, lastname
        FROM
            users
        WHERE
            identifier = @identifier
    ]]

    MySQL.Async.fetchAll(sql, { ["@identifier"] = xPlayer["identifier"] }, function(response)
        if response[1] ~= nil then
            name = response[1]["firstname"] .. " " .. response[1]["lastname"]
        end
    end)

    Citizen.Wait(1000)

    MySQL.Async.fetchAll(
        'SELECT name, time FROM user_races WHERE name = @identifier and race = @race', {['@identifier'] = name, ['@race'] = race},
    function(result)
        if result[1] ~= nil and result[1].time > time then
            MySQL.Async.execute(
                'UPDATE user_races SET time = @time WHERE name = @identifier and race = @race',
                {
                    ['@identifier'] = name,
                    ['@race'] = race,
                    ['@time'] = time
                }
            )
        elseif result[1] == nil then
            MySQL.Async.execute('INSERT INTO user_races (name, time, race) VALUES (@name, @time, @race)',
                {
                    ['@name'] = name,
                    ['@time'] = time,
                    ['@race'] = race
                }
            )
        end
    end)
end)

ESX.RegisterServerCallback('esx-qalle-races:getScoreboard', function(source, cb, race)
    local identifier = ESX.GetPlayerFromId(source).identifier

    MySQL.Async.fetchAll(
        'SELECT * FROM user_races WHERE race = @race ORDER BY time ASC LIMIT 10', {['@race'] = race},
    function(result)

        local Races = {}

        for i=1, #result, 1 do
            table.insert(Races, {
                name   = result[i].name,
                time = result[i].time,
            })
        end

        cb(Races)
    end)  
end)
