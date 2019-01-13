ESX                           = nil

local RaceVehicle = nil

Citizen.CreateThread(function ()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) 
            ESX = obj 
        end)

        Citizen.Wait(1)
    end
end) 
  
Citizen.CreateThread(function()

    for race, val in pairs(Config.RaceInformations) do
        local Blip = AddBlipForCoord(val['StartRace']['x'], val['StartRace']['y'], val['StartRace']['z'])
    
        SetBlipSprite (Blip, val['Sprite'])
        SetBlipDisplay(Blip, 4)
        SetBlipScale  (Blip, 0.8)
        SetBlipColour (Blip, 75)
        SetBlipAsShortRange(Blip, true)
    
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(race)
        EndTextCommandSetBlipName(Blip)
    end

    Citizen.Wait(0) -- init load esx

    while true do
        local sleep = 500

        for race, val in pairs(Config.RaceInformations) do
            local distance = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), val['StartRace']['x'], val['StartRace']['y'], val['StartRace']['z'], true)

            if distance < 10.0 then
                sleep = 5

                ESX.Game.Utils.DrawText3D(val['StartRace'], '[E] Race Menu', 0.4)

                if distance < 1.5 then
                    if IsControlJustReleased(0, 38) then
                        OpenRaceMenu(race)
                    end
                end
            end
        end
        Citizen.Wait(sleep)
    end

end)

function StartRace(currentRace)
    local currentCheckPoint = 1
    local nextCheckPoint = 2
    local isRacing = true

    StartTime = GetGameTimer()

    Citizen.CreateThread(function()

        CheckPoint = CreateCheckpoint(5, Config.CheckPoints[currentRace][currentCheckPoint].x,  Config.CheckPoints[currentRace][currentCheckPoint].y,  Config.CheckPoints[currentRace][currentCheckPoint].z + 2, Config.CheckPoints[currentRace][nextCheckPoint].x, Config.CheckPoints[currentRace][nextCheckPoint].y, Config.CheckPoints[currentRace][nextCheckPoint].z, 8.0, 255, 255, 255, 100, 0)
        Blip = AddBlipForCoord(Config.CheckPoints[currentRace][currentCheckPoint].x, Config.CheckPoints[currentRace][currentCheckPoint].y, Config.CheckPoints[currentRace][currentCheckPoint].z)   

        while isRacing do
            Citizen.Wait(5)

            local PlayerCoords = GetEntityCoords(PlayerPedId())

            local currentTime = formatTimer(StartTime, GetGameTimer())

            if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), Config.RaceInformations[currentRace]['StartPosition']['x'], Config.RaceInformations[currentRace]['StartPosition']['y'], Config.RaceInformations[currentRace]['StartPosition']['z'], true) >= 650.0 then
                ESX.Game.DeleteVehicle(RaceVehicle)
                ESX.ShowNotification("You drove too far away from the race.")
                DeleteCheckpoint(CheckPoint)
                RemoveBlip(Blip)
                isRacing = false
                return
            end


            if not IsPedInAnyVehicle(PlayerPedId(), false) then
                ESX.Game.DeleteVehicle(RaceVehicle)
                ESX.ShowNotification("You left your vehicle, which canceled the race!")
                DeleteCheckpoint(CheckPoint)
                RemoveBlip(Blip)
                isRacing = false
                return
            end

            ESX.Game.Utils.DrawText3D({x = PlayerCoords.x, y = PlayerCoords.y, z = PlayerCoords.z + 1.2}, currentCheckPoint .. ' / ' ..GetMaxCheckPoints(Config.CheckPoints, currentRace), 0.4)
            ESX.Game.Utils.DrawText3D({x = PlayerCoords.x, y = PlayerCoords.y, z = PlayerCoords.z + 1.4}, currentTime, 0.4)

            if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), Config.CheckPoints[currentRace][currentCheckPoint].x,  Config.CheckPoints[currentRace][currentCheckPoint].y,  Config.CheckPoints[currentRace][currentCheckPoint].z) < 7.5 then

                if currentCheckPoint == GetMaxCheckPoints(Config.CheckPoints, currentRace) - 1 then
                    currentCheckPoint = GetMaxCheckPoints(Config.CheckPoints, currentRace)
                    PlaySoundFrontend(-1, "RACE_PLACED", "HUD_AWARDS")
                    DeleteCheckpoint(CheckPoint)
                    RemoveBlip(Blip)
                    CheckPoint = CreateCheckpoint(9, Config.CheckPoints[currentRace][currentCheckPoint].x,  Config.CheckPoints[currentRace][currentCheckPoint].y,  Config.CheckPoints[currentRace][currentCheckPoint].z + 2, Config.CheckPoints[currentRace][nextCheckPoint].x, Config.CheckPoints[currentRace][nextCheckPoint].y, Config.CheckPoints[currentRace][nextCheckPoint].z, 8.0, 255, 255, 255, 100, 0)
                elseif currentCheckPoint == GetMaxCheckPoints(Config.CheckPoints, currentRace) then
                    PlaySoundFrontend(-1, "ScreenFlash", "WastedSounds")
                    DeleteCheckpoint(CheckPoint)
                    RemoveBlip(Blip)
                    ESX.ShowNotification("You finished the " .. currentRace .. " with a time of " .. currentTime .. " seconds !")
                    TriggerServerEvent('esx-qalle-races:addTime', currentTime, currentRace)
                    DeleteEntity(RaceVehicle)

                    return
                else
                    PlaySoundFrontend(-1, "RACE_PLACED", "HUD_AWARDS")
                    DeleteCheckpoint(CheckPoint)
                    RemoveBlip(Blip)
                    currentCheckPoint = currentCheckPoint + 1

                    nextCheckPoint = nextCheckPoint + 1
                    CheckPoint = CreateCheckpoint(5, Config.CheckPoints[currentRace][currentCheckPoint].x,  Config.CheckPoints[currentRace][currentCheckPoint].y,  Config.CheckPoints[currentRace][currentCheckPoint].z + 2, Config.CheckPoints[currentRace][nextCheckPoint].x, Config.CheckPoints[currentRace][nextCheckPoint].y, Config.CheckPoints[currentRace][nextCheckPoint].z, 8.0, 255, 255, 255, 100, 0)
                    Blip = AddBlipForCoord(Config.CheckPoints[currentRace][currentCheckPoint].x, Config.CheckPoints[currentRace][currentCheckPoint].y, Config.CheckPoints[currentRace][currentCheckPoint].z)   
                end

            end
        end
    end)
end

function StartCountdown(race)
    DoScreenFadeOut(1)

    local raceInfo = Config.RaceInformations[race]

    LoadModel(raceInfo['Vehicle'])

    RaceVehicle = CreateVehicle(GetHashKey(raceInfo['Vehicle']), raceInfo['StartPosition']['x'], raceInfo['StartPosition']['y'], raceInfo['StartPosition']['z'], raceInfo['StartPosition']['h'], true, false)

    TriggerEvent("advancedFuel:setEssence", 100, GetVehicleNumberPlateText(RaceVehicle), GetDisplayNameFromVehicleModel(GetEntityModel(RaceVehicle)))

    TaskWarpPedIntoVehicle(PlayerPedId(), RaceVehicle, -1)

    Citizen.Wait(1500)

    DoScreenFadeIn(100)

    local countDownTimer = 4
   
    FreezeEntityPosition(GetVehiclePedIsUsing(PlayerPedId()), true)

    for i = 1, countDownTimer, 1 do
        countDownTimer = countDownTimer - 1
        
        ESX.Scaleform.ShowFreemodeMessage("Get Ready!", countDownTimer, 0.8)
    end

    FreezeEntityPosition(GetVehiclePedIsUsing(PlayerPedId()), false)

    StartRace(race)
end

function OpenRaceMenu(race)
    ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'racing_menu',
        {
            title    = race,
            align    = 'top-right',
            elements = {
                {label = 'Start Race ( ' .. Config.Price .. ' SEK)', value = 'start'},
                {label = 'Check Scoreboard', value = 'scoreboard'}
            }
        },
        function(data, menu)
            local action = data.current.value

            if action == 'start' then
                if ESX.Game.IsSpawnPointClear(Config.RaceInformations[race]['StartPosition'], 5.0) then
                    ESX.TriggerServerCallback('esx-qalle-races:getMoney', function(hasEnough)
                        if hasEnough then
                            menu.close()
                            StartCountdown(race)
                        else
                            ESX.ShowNotification("You don't have enough money to race in " .. race)
                        end
                    end, Config.Price)
                else
                    ESX.ShowNotification("It's already someone thats racing!")
                end

            elseif action == 'scoreboard' then
                OpenScoreboard(race)
            end
        end,
    function(data, menu)
        menu.close()
    end)
end

function OpenScoreboard(race)

    local elem = {}

    ESX.TriggerServerCallback('esx-qalle-races:getScoreboard', function(Races)

        for i=1, #Races, 1 do
            table.insert(elem, {label = Races[i].name .. ' ' .. tonumber(string.format("%.2f", Races[i].time)) .. 's'})
        end

        ESX.UI.Menu.Open(
            'default', GetCurrentResourceName(), 'racing_scoreboard',
            {
                title    = race .. ' Tider',
                align    = 'top-right',
                elements = elem
            },
            function(data, menu)

            end,
        function(data, menu)
            menu.close()
        end)
    end, race)
end

--Counts the Config.checkpoints
function GetMaxCheckPoints(table, race)
    local checkpoints = 0

    for index, values in pairs(table[race]) do
        checkpoints = checkpoints + 1 
    end

    return checkpoints
end

function formatTimer(startTime, currTime)
    local newString = currTime - startTime
    local ms = string.sub(newString, -3, -2)
    local sec = string.sub(newString, -5, -4)
    local min = string.sub(newString, -7, -6)
    newString = string.format("%s%s.%s", min, sec, ms)

    return newString
end

LoadModel = function(model)
    while not HasModelLoaded(model) do
          RequestModel(model)
          Citizen.Wait(10)
    end
end
