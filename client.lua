-- Rocket League Game Mode - Client Script

local playerVehicle = nil
local ball = nil
local timer = 180 -- 3 minutes match duration
local goalScored = false
local activeMatch = false
local countdownTime = 5

-- Game variables for teams
local team1Score = 0
local team2Score = 0
local team1MVP = nil
local team2MVP = nil

-- Spawn player vehicle logic
RegisterNetEvent("rocketleague:spawnPlayerVehicle")
AddEventHandler("rocketleague:spawnPlayerVehicle", function(playerID)
    local playerPed = GetPlayerPed(-1) -- Get the player's ped
    local spawnCoords = RocketLeague.Teams[playerID] and RocketLeague.Teams[playerID].spawn

    -- Debug: Check if spawn coordinates are defined
    if not spawnCoords then
        print("[RocketLeague Debug] Spawn coordinates not found for player ID: " .. tostring(playerID))
        return
    end

    -- Delete existing vehicle if any
    if playerVehicle then
        SetEntityAsMissionEntity(playerVehicle, true, true)
        DeleteVehicle(playerVehicle)
        playerVehicle = nil -- Reset the vehicle reference
    end

    -- Request and load the vehicle model
    local vehicleModel = GetHashKey("rcbandito")
    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do
        Wait(500)
        print("[RocketLeague Debug] Loading vehicle model: rcbandito...")
    end

    -- Debug: Check if vehicle model is loaded
    if not IsModelInCdimage(vehicleModel) or not IsModelAVehicle(vehicleModel) then
        print("[RocketLeague Debug] Vehicle model 'rcbandito' is invalid or not found.")
        return
    end

    -- Spawn the vehicle at the assigned spawn point
    print("[RocketLeague Debug] Spawning vehicle at coordinates: ", spawnCoords.x, spawnCoords.y, spawnCoords.z)
    playerVehicle = CreateVehicle(vehicleModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)

    -- Debug: Check if vehicle was successfully created
    if not DoesEntityExist(playerVehicle) then
        print("[RocketLeague Debug] Failed to create vehicle.")
        return
    end

    -- Teleport the player into the vehicle
    TaskWarpPedIntoVehicle(playerPed, playerVehicle, -1)
    SetVehicleNumberPlateText(playerVehicle, "ROCKETLEAGUE")
    print("[RocketLeague Debug] Player teleported into vehicle successfully.")
end)

-- Ball mechanics (spawning, resetting)
RegisterNetEvent("rocketleague:spawnBall")
AddEventHandler("rocketleague:spawnBall", function()
    if ball then
        DeleteEntity(ball)
    end

    -- Request and spawn the ball at the center
    RequestModel(RocketLeague.BallModel)
    while not HasModelLoaded(RocketLeague.BallModel) do
        Wait(500)
    end

    ball = CreateObject(GetHashKey(RocketLeague.BallModel), RocketLeague.BallSpawn.x, RocketLeague.BallSpawn.y, RocketLeague.BallSpawn.z, true, true, true)
    SetEntityAsMissionEntity(ball, true, true)
    SetEntityDynamic(ball, true)
end)

-- Reset ball position after a goal
RegisterNetEvent("rocketleague:resetBall")
AddEventHandler("rocketleague:resetBall", function()
    SetEntityCoords(ball, RocketLeague.BallSpawn.x, RocketLeague.BallSpawn.y, RocketLeague.BallSpawn.z)
    SetEntityVelocity(ball, 0.0, 0.0, 0.0)
end)

-- Update score UI
RegisterNetEvent("rocketleague:updateScore")
AddEventHandler("rocketleague:updateScore", function(teamIndex, score)
    if teamIndex == 1 then
        team1Score = score
    elseif teamIndex == 2 then
        team2Score = score
    end
    SendNUIMessage({
        type = "updateScore",
        team1Score = team1Score,
        team2Score = team2Score
    })
end)

-- Match timer and countdown logic
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) -- Update every second

        if activeMatch then
            timer = timer - 1
            TriggerEvent("rocketleague:updateTimer", timer)

            if timer <= 0 then
                TriggerServerEvent("rocketleague:endMatch", "timeout")
                activeMatch = false
            end
        end

        -- Handle countdown for game start
        if countdownTime > 0 then
            TriggerEvent("rocketleague:startCountdown", countdownTime)
            countdownTime = countdownTime - 1
        end
    end
end)

-- Update match timer UI
RegisterNetEvent("rocketleague:updateTimer")
AddEventHandler("rocketleague:updateTimer", function(timeLeft)
    local minutes = math.floor(timeLeft / 60)
    local seconds = timeLeft % 60
    SendNUIMessage({
        type = "updateTimer",
        timeLeft = timeLeft
    })
end)

-- Goal notification and sound FX
RegisterNetEvent("rocketleague:goalScored")
AddEventHandler("rocketleague:goalScored", function(teamIndex)
    local goalSound = RocketLeague.Sounds.goal
    PlaySoundFromEntity(-1, goalSound, playerVehicle, "DLC_Lowrider_10_CAR_AUDIO", 0, 0)
    TriggerEvent("rocketleague:showGoalAnimation", teamIndex)

    -- Update team score and notify the UI
    if teamIndex == 1 then
        team1Score = team1Score + 1
    elseif teamIndex == 2 then
        team2Score = team2Score + 1
    end
    TriggerServerEvent("rocketleague:updateScore", teamIndex, teamIndex == 1 and team1Score or team2Score)
end)

-- rd-interact integration for game start and leaderboard
Citizen.CreateThread(function()
    exports["rd-interact"]:AddPeekEntryByModel(-668163313, {
        {
            id = "rocketleague_start_game",
            label = "🎮 Start Rocket League Game",
            icon = "gamepad",
            event = "rocketleague:startMatch",
            parameters = {},
            isEnabled = function()
                return not activeMatch -- Only enable if no match is active
            end
        },
        {
            id = "rocketleague_view_leaderboard",
            label = "📊 View Leaderboard",
            icon = "list",
            event = "rocketleague:showLeaderboard",
            parameters = {},
            isEnabled = function()
                return true -- Always available for viewing the leaderboard
            end
        }
    }, {
        distance = { radius = 2.5 }
    })
end)
