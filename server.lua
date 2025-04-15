-- Rocket League Game Mode - Server Script

-- Game state
local activeMatch = false
local teamScores = { [1] = 0, [2] = 0 }
local leaderboards = {}

-- Utility function to broadcast to all players
local function broadcastToAll(event, ...)
    TriggerClientEvent(event, -1, ...)
end

-- Start Match Event
RegisterServerEvent("rocketleague:startMatch")
AddEventHandler("rocketleague:startMatch", function()
    if activeMatch then
        print("[RocketLeague Server] Match is already active, cannot start a new one.")
        return
    end

    activeMatch = true
    teamScores = { [1] = 0, [2] = 0 }

    print("[RocketLeague Server] Match started!")
    broadcastToAll("rocketleague:startMatch")
end)

-- End Match Event
RegisterServerEvent("rocketleague:endMatch")
AddEventHandler("rocketleague:endMatch", function(reason)
    if not activeMatch then
        print("[RocketLeague Server] No active match to end.")
        return
    end

    activeMatch = false
    print("[RocketLeague Server] Match ended. Reason: " .. reason)

    -- Determine winner based on scores
    local winner
    if teamScores[1] > teamScores[2] then
        winner = "Team 1 Wins!"
    elseif teamScores[2] > teamScores[1] then
        winner = "Team 2 Wins!"
    else
        winner = "It's a draw!"
    end

    -- Notify clients about the match result
    broadcastToAll("rocketleague:endMatch", winner)
end)

-- Update Score Event
RegisterServerEvent("rocketleague:updateScore")
AddEventHandler("rocketleague:updateScore", function(teamIndex, score)
    if not activeMatch then
        print("[RocketLeague Server] No active match to update score for.")
        return
    end

    teamScores[teamIndex] = score
    print("[RocketLeague Server] Updated score for Team " .. teamIndex .. ": " .. score)

    -- Notify clients about the updated score
    broadcastToAll("rocketleague:updateScore", teamIndex, score)
end)

-- Handle Goal Scored Event
RegisterServerEvent("rocketleague:goalScored")
AddEventHandler("rocketleague:goalScored", function(teamIndex)
    if not activeMatch then
        print("[RocketLeague Server] No active match to register a goal.")
        return
    end

    teamScores[teamIndex] = teamScores[teamIndex] + 1
    print("[RocketLeague Server] Team " .. teamIndex .. " scored a goal! Current score: " .. teamScores[teamIndex])

    -- Notify clients about the goal
    broadcastToAll("rocketleague:goalScored", teamIndex)
end)

-- Leaderboard Management
RegisterServerEvent("rocketleague:updateLeaderboard")
AddEventHandler("rocketleague:updateLeaderboard", function(playerData)
    table.insert(leaderboards, playerData)
    print("[RocketLeague Server] Leaderboard updated.")
    broadcastToAll("rocketleague:receiveLeaderboard", leaderboards)
end)

-- Reset Ball Event
RegisterServerEvent("rocketleague:resetBall")
AddEventHandler("rocketleague:resetBall", function()
    print("[RocketLeague Server] Resetting ball to the center.")
    broadcastToAll("rocketleague:resetBall")
end)

-- Debug: Force Update Leaderboards
RegisterCommand("updateLeaderboard", function(source, args)
    local dummyData = {
        { player_name = "Player1", wins = 3, goals = 15 },
        { player_name = "Player2", wins = 4, goals = 20 }
    }
    leaderboards = dummyData
    broadcastToAll("rocketleague:receiveLeaderboard", leaderboards)
    print("[RocketLeague Server] Leaderboard debug data sent.")
end, true)

-- Debug: Force Start Match
RegisterCommand("startMatch", function(source, args)
    TriggerEvent("rocketleague:startMatch")
    print("[RocketLeague Server] Debug command: Match started.")
end, true)

-- Debug: Force End Match
RegisterCommand("endMatch", function(source, args)
    TriggerEvent("rocketleague:endMatch", "Debug Command")
    print("[RocketLeague Server] Debug command: Match ended.")
end, true)
