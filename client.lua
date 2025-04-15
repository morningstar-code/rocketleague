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

-- Game vehicle spawn logic
RegisterNetEvent("rocketleague:spawnPlayerVehicle")
AddEventHandler("rocketleague:spawnPlayerVehicle", function(playerID)
    local playerPed = GetPlayerPed(playerID)
    local spawnCoords = RocketLeague.Teams[playerID].spawn

    -- Delete existing vehicle if any
    if playerVehicle then
        SetEntityAsMissionEntity(playerVehicle, true, true)
        DeleteVehicle(playerVehicle)
    end

    -- Spawn new vehicle at assigned spawn point
    RequestModel("rcbandito")
    while not HasModelLoaded("rcbandito") do
        Wait(500)
    end

    playerVehicle = CreateVehicle("rcbandito", spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
    TaskWarpPedIntoVehicle(playerPed, playerVehicle, -1)
    SetVehicleNumberPlateText(playerVehicle, "ROCKETLEAGUE")
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

-- Goal animation and effects (slow-motion)
RegisterNetEvent("rocketleague:showGoalAnimation")
AddEventHandler("rocketleague:showGoalAnimation", function(teamIndex)
    SetTimecycleModifier("force_dof_4")
    Citizen.Wait(3000)
    ClearTimecycleModifier()
end)

-- Display MVP of the match
RegisterNetEvent("rocketleague:showMVP")
AddEventHandler("rocketleague:showMVP", function(mvpID)
    local mvpName = GetPlayerName(mvpID)
    team1MVP = mvpName
    SendNUIMessage({
        type = "showMVP",
        mvpName = mvpName
    })
end)

-- Display leaderboard UI
RegisterNetEvent("rocketleague:showLeaderboard")
AddEventHandler("rocketleague:showLeaderboard", function()
    SendNUIMessage({
        type = "updateLeaderboard",
        players = { -- Dummy player data for now, will be replaced with actual data
            { player_name = "Player1", wins = 5, goals = 10 },
            { player_name = "Player2", wins = 4, goals = 8 }
        }
    })
    SetNuiFocus(true, true)
end)

-- Close leaderboard UI
RegisterNUICallback("closeLeaderboard", function(_, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

-- Handle leaderboard updates (server-side triggered)
RegisterNetEvent("rocketleague:receiveLeaderboard")
AddEventHandler("rocketleague:receiveLeaderboard", function(data)
    SendNUIMessage({
        type = "updateLeaderboard",
        players = data
    })
end)

-- Handle game start
RegisterNetEvent("rocketleague:startMatch")
AddEventHandler("rocketleague:startMatch", function()
    activeMatch = true
    SendNUIMessage({
        type = "startGame"
    })
    -- Reset scores and other match variables
    team1Score = 0
    team2Score = 0
    timer = 180 -- Reset match timer to 3 minutes
end)

-- End match logic and show results
RegisterNetEvent("rocketleague:endMatch")
AddEventHandler("rocketleague:endMatch", function(result)
    activeMatch = false
    SendNUIMessage({
        type = "showMatchResult",
        result = result
    })
    -- Show final scores and MVP
    TriggerEvent("rocketleague:showMVP", team1Score > team2Score and team1MVP or team2MVP)
end)

-- Interactions with the arcade for viewing leaderboards and starting the game
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

-- Update team MVP based on performance
function updateMVP(teamIndex, playerID)
    if teamIndex == 1 then
        team1MVP = GetPlayerName(playerID)
    else
        team2MVP = GetPlayerName(playerID)
    end
end

-- Manage team switching, if needed
function switchTeams(playerID, newTeam)
    if newTeam == 1 then
        -- Move the player to Team 1
        TriggerEvent("rocketleague:spawnPlayerVehicle", playerID)
    elseif newTeam == 2 then
        -- Move the player to Team 2
        TriggerEvent("rocketleague:spawnPlayerVehicle", playerID)
    end
end

-- UI control and transition handling for match start, goals, etc.
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if activeMatch then
            -- Play sounds, handle transitions, etc. while the match is active
        end

        -- Handle input for menu interactions or game state changes
        if IsControlJustPressed(0, 38) then -- E key for example to interact
            TriggerEvent("rocketleague:showLeaderboard")
        end
    end
end)

-- Arcade interaction for starting a game or viewing the leaderboard
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if IsControlJustPressed(0, 38) then -- E key for interaction
            if activeMatch then
                TriggerEvent("rocketleague:showLeaderboard")
            else
                TriggerEvent("rocketleague:startMatch")
            end
        end
    end
end)

-- Add additional functionality for match end and reset
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if activeMatch and timer <= 0 then
            TriggerServerEvent("rocketleague:endMatch", "timeout")
        end
    end
end)

-- Listen for the "Start Game" button click from the UI
RegisterNUICallback("startGameClicked", function(_, cb)
    -- Trigger the server event to start the game
    TriggerServerEvent("rocketleague:startGame")

    -- Hide the start button and show other game UI elements
    SetNuiFocus(false, false)  -- Close NUI focus
    cb("ok")  -- Callback to acknowledge the interaction
end)


-- Countdown logic
RegisterNetEvent("rocketleague:startCountdown")
AddEventHandler("rocketleague:startCountdown", function()
    local countdownTime = 3 -- Starting countdown at 3
    SetNuiFocus(true, true) -- Focus the UI for player interaction
    
    -- Start countdown
    Citizen.CreateThread(function()
        while countdownTime > 0 do
            -- Update the countdown in the UI
            SendNUIMessage({
                type = "updateCountdown",
                countdownTime = countdownTime
            })
            
            Citizen.Wait(1000) -- Wait 1 second
            countdownTime = countdownTime - 1
        end
        
        -- Start the game once countdown is over
        SendNUIMessage({
            type = "startGame"
        })
    end)
end)
-- Update score UI when server sends score update
RegisterNetEvent("rocketleague:updateScore")
AddEventHandler("rocketleague:updateScore", function(teamIndex, score)
    if teamIndex == 1 then
        SendNUIMessage({
            type = "updateScore",
            teamIndex = 1,
            score = score
        })
    elseif teamIndex == 2 then
        SendNUIMessage({
            type = "updateScore",
            teamIndex = 2,
            score = score
        })
    end
end)
RegisterNetEvent("rocketleague:goalNotification")
AddEventHandler("rocketleague:goalNotification", function(teamIndex)
    local teamName = teamIndex == 1 and "Team A" or "Team B"
    SendNUIMessage({
        type = "goalNotification",
        teamIndex = teamIndex
    })
end)
-- Show leaderboard in NUI
RegisterNetEvent("rocketleague:showLeaderboard")
AddEventHandler("rocketleague:showLeaderboard", function(data)
    SendNUIMessage({
        type = "updateLeaderboard",
        players = data
    })
end)
-- Initially, do not display the UI
Citizen.CreateThread(function()
    -- Hide the UI when the player joins or when the server starts
    SetNuiFocus(false, false)  -- Ensures no NUI focus initially
end)

-- Show UI when "Start Game" button is clicked
RegisterNUICallback("startGameClicked", function(_, cb)
    -- Set focus for NUI when starting the game
    SetNuiFocus(true, true)

    -- Trigger the server to start the match
    TriggerServerEvent("rocketleague:startGame")

    -- Update the UI elements here
    SendNUIMessage({
        type = "gameStarted"
    })
    
    cb("ok")  -- Acknowledge the button press
end)
-- Countdown logic, triggered after clicking Start Game button
RegisterNetEvent("rocketleague:startCountdown")
AddEventHandler("rocketleague:startCountdown", function()
    local countdownTime = 3 -- Starting countdown at 3
    SetNuiFocus(true, true) -- Focus the UI for player interaction
    
    -- Start countdown
    Citizen.CreateThread(function()
        while countdownTime > 0 do
            -- Update the countdown in the UI
            SendNUIMessage({
                type = "updateCountdown",
                countdownTime = countdownTime
            })
            
            Citizen.Wait(1000) -- Wait 1 second
            countdownTime = countdownTime - 1
        end
        
        -- Start the game once countdown is over
        SendNUIMessage({
            type = "startGame"
        })
    end)
end)

