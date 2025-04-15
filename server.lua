local activeMatches = {}  -- Stores active match data (e.g., team scores, players)
local leaderboard = {}    -- Stores player statistics (wins, goals)
local matchDuration = 180 -- 3 minutes match duration

-- Initialize leaderboard (Example data, replace with your actual data)
function initializeLeaderboard()
    leaderboard = {
        ["Player1"] = { wins = 5, goals = 10 },
        ["Player2"] = { wins = 4, goals = 8 }
    }
end

-- Handle player joining a match
RegisterServerEvent("rocketleague:joinMatch")
AddEventHandler("rocketleague:joinMatch", function(playerID)
    local source = source
    if not activeMatches[playerID] then
        activeMatches[playerID] = {
            team = math.random(1, 2),  -- Randomly assign team 1 or team 2
            score = 0,
            vehicle = nil
        }
        TriggerClientEvent("rocketleague:spawnPlayerVehicle", source, playerID)
        TriggerClientEvent("rocketleague:sendPlayerData", source, activeMatches[playerID])
    else
        print("Player already in match!")
    end
end)

-- Handle starting the match
RegisterServerEvent("rocketleague:startMatch")
AddEventHandler("rocketleague:startMatch", function()
    local source = source
    local playerID = source

    -- Initialize the match with the starting values
    activeMatches[playerID].score = 0
    activeMatches[playerID].vehicle = nil -- Assuming vehicle is set on spawn, change as needed

    -- Set match duration and start the countdown
    TriggerClientEvent("rocketleague:startMatch", source)
    TriggerClientEvent("rocketleague:startCountdown", source, 3) -- Start countdown
    -- After 3 seconds, start the match timer
    Citizen.Wait(3000)
    TriggerClientEvent("rocketleague:startGame", source)
end)

-- Handle match timeout or end of game
RegisterServerEvent("rocketleague:endMatch")
AddEventHandler("rocketleague:endMatch", function(result)
    local source = source
    local playerID = source
    local matchResult = result or "Timeout"
    
    -- Update leaderboard after the match ends
    if matchResult == "timeout" then
        TriggerClientEvent("rocketleague:showMatchResult", source, "Match Ended: Timeout!")
    else
        -- Logic for declaring winner
        local winningTeam = (activeMatches[playerID].score > 0 and 1 or 2)
        leaderboard[GetPlayerName(playerID)].wins = leaderboard[GetPlayerName(playerID)].wins + 1
        TriggerClientEvent("rocketleague:showMatchResult", source, "Team " .. winningTeam .. " wins!")
    end

    -- Reset match-related data
    activeMatches[playerID].score = 0
end)

-- Score update on goal
RegisterServerEvent("rocketleague:goalScored")
AddEventHandler("rocketleague:goalScored", function(teamIndex)
    local playerID = source
    if teamIndex == 1 then
        activeMatches[playerID].score = activeMatches[playerID].score + 1
        TriggerClientEvent("rocketleague:updateScore", playerID, teamIndex, activeMatches[playerID].score)
    elseif teamIndex == 2 then
        activeMatches[playerID].score = activeMatches[playerID].score + 1
        TriggerClientEvent("rocketleague:updateScore", playerID, teamIndex, activeMatches[playerID].score)
    end
end)

-- Send the leaderboard to clients
RegisterServerEvent("rocketleague:sendLeaderboard")
AddEventHandler("rocketleague:sendLeaderboard", function()
    local source = source
    local sortedLeaderboard = {}
    for playerName, stats in pairs(leaderboard) do
        table.insert(sortedLeaderboard, { player_name = playerName, wins = stats.wins, goals = stats.goals })
    end
    -- Sort players by wins
    table.sort(sortedLeaderboard, function(a, b) return a.wins > b.wins end)

    TriggerClientEvent("rocketleague:receiveLeaderboard", source, sortedLeaderboard)
end)

-- Display MVP at the end of the match
RegisterServerEvent("rocketleague:showMVP")
AddEventHandler("rocketleague:showMVP", function(playerID)
    local mvpName = GetPlayerName(playerID)
    TriggerClientEvent("rocketleague:showMVP", playerID, mvpName)
end)

-- Manage team switching
RegisterServerEvent("rocketleague:switchTeams")
AddEventHandler("rocketleague:switchTeams", function(playerID, newTeam)
    if activeMatches[playerID] then
        activeMatches[playerID].team = newTeam
        TriggerClientEvent("rocketleague:spawnPlayerVehicle", playerID)
    end
end)

-- Reset ball to the center after a goal
RegisterServerEvent("rocketleague:resetBall")
AddEventHandler("rocketleague:resetBall", function()
    TriggerClientEvent("rocketleague:resetBall", -1)
end)

-- Leaderboard data initialization (this can be extended with database integration)
function initializeLeaderboard()
    -- Sample players, this would be replaced by your data storage
    leaderboard = {
        ["Player1"] = { wins = 5, goals = 10 },
        ["Player2"] = { wins = 4, goals = 8 },
        ["Player3"] = { wins = 2, goals = 5 }
    }
end

-- Load leaderboard when the resource starts
AddEventHandler("onResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        initializeLeaderboard()
    end
end)

-- Listen to player joining or leaving
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    deferrals.defer()
    Wait(0)
    -- Handle player joining logic here
    print(playerName .. " is connecting.")
    deferrals.done()
end)

-- Save leaderboard data to file (or integrate with database)
RegisterServerEvent("rocketleague:saveLeaderboard")
AddEventHandler("rocketleague:saveLeaderboard", function()
    -- This is just an example, replace with file writing or database calls
    print("Leaderboard saved!")
end)

-- Broadcast leaderboard to all players periodically (every 5 minutes)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000) -- 5 minutes
        TriggerEvent("rocketleague:sendLeaderboard")
    end
end)

-- Start a new match when players are ready
RegisterServerEvent("rocketleague:startNewMatch")
AddEventHandler("rocketleague:startNewMatch", function()
    local source = source
    TriggerEvent("rocketleague:startMatch")
    -- Reset team scores
    team1Score = 0
    team2Score = 0
    timer = matchDuration
end)

-- Send match stats to all players after the match ends
RegisterServerEvent("rocketleague:sendMatchStats")
AddEventHandler("rocketleague:sendMatchStats", function()
    local source = source
    local stats = {
        team1Score = team1Score,
        team2Score = team2Score,
        mvp = team1Score > team2Score and team1MVP or team2MVP
    }

    TriggerClientEvent("rocketleague:sendMatchStats", source, stats)
end)

-- Restart the match after a goal or timeout
RegisterServerEvent("rocketleague:restartMatch")
AddEventHandler("rocketleague:restartMatch", function()
    local source = source
    team1Score = 0
    team2Score = 0
    timer = matchDuration
    TriggerClientEvent("rocketleague:resetBall", -1)
    TriggerClientEvent("rocketleague:startCountdown", -1, 3)
end)

-- Command to end match manually (if needed)
RegisterCommand("endMatch", function(source, args, rawCommand)
    local result = args[1] or "Timeout"
    TriggerEvent("rocketleague:endMatch", result)
end, false)

-- Event handler for player disconnecting
AddEventHandler('playerDropped', function(playerName)
    print(playerName .. " has left the server.")
    -- You can implement logic here to handle player disconnections during active matches
end)

-- Example: Player has won the match, give reward or save data
RegisterServerEvent("rocketleague:playerWon")
AddEventHandler("rocketleague:playerWon", function(playerID)
    local playerName = GetPlayerName(playerID)
    leaderboard[playerName].wins = leaderboard[playerName].wins + 1
    print(playerName .. " has won the match!")
    -- Save or update database with new stats
end)

-- Example: Record a player's performance after each match
RegisterServerEvent("rocketleague:recordPerformance")
AddEventHandler("rocketleague:recordPerformance", function(playerID, goals)
    local playerName = GetPlayerName(playerID)
    leaderboard[playerName].goals = leaderboard[playerName].goals + goals
    print(playerName .. " scored " .. goals .. " goals in the match.")
end)

-- Simulate a match start for testing
Citizen.CreateThread(function()
    Citizen.Wait(2000) -- Simulate a small delay for testing
    local source = 1  -- Simulating a player with ID 1
    TriggerClientEvent ("rocketleague:startNewMatch", source)
end)

-- Handle arcade interaction and UI updates when requested
RegisterServerEvent("rocketleague:arcadeInteraction")
AddEventHandler("rocketleague:arcadeInteraction", function()
    -- Handle any logic related to arcade interactions, like opening leaderboards or resetting match
    TriggerClientEvent("rocketleague:showLeaderboard", -1)
end)

-- Handle player forfeiting the match
RegisterServerEvent("rocketleague:forfeitMatch")
AddEventHandler("rocketleague:forfeitMatch", function(playerID)
    local playerName = GetPlayerName(playerID)
    -- Handle the logic when a player forfeits the match (e.g., record a loss)
    print(playerName .. " has forfeited the match.")
end)

-- Game over, reset everything
RegisterServerEvent("rocketleague:resetGame")
AddEventHandler("rocketleague:resetGame", function()
    activeMatches = {} -- Reset active matches
    leaderboard = {}    -- Reset leaderboard
    print("Game and leaderboard have been reset.")
end)
RegisterNetEvent("rocketleague:startGame")
AddEventHandler("rocketleague:startGame", function()
    -- Handle the start game logic here
    -- For example, set up the match countdown, spawn cars, etc.
    TriggerClientEvent("rocketleague:startCountdown", source)
end)
