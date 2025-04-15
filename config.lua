RocketLeague = {}

-- Teams
RocketLeague.Teams = {
    { name = "GROVE", color = "blue", spawn = vector4(-1619.506, -1080.122, 12.40639, 0.0) },
    { name = "VAGOS", color = "orange", spawn = vector4(-1627.436, -1089.037, 12.40554, 180.0) }
}

-- Ball spawn
RocketLeague.BallSpawn = vector3(-1624.645, -1085.268, 12.4047)

-- Ball model
RocketLeague.BallModel = "prop_beach_ball_02"

-- Match duration (seconds)
RocketLeague.MatchDuration = 180

-- Sounds
RocketLeague.Sounds = {
    goal = "Goal_Achieved_Sound_Set",
    start = "Start_Whistle_Sound_Set",
    endgame = "Game_Over_Sound_Set",
    boost = "Boost_Sound_Set"
}

-- Countdown
RocketLeague.CountdownTime = 3

-- Goal zones (adjust based on arena)
RocketLeague.GoalZones = {
    team1 = { min = vector3(-1630.0, -1090.0, 12.0), max = vector3(-1620.0, -1080.0, 14.0) },
    team2 = { min = vector3(-1610.0, -1080.0, 12.0), max = vector3(-1620.0, -1090.0, 14.0) }
}

-- Debug mode
RocketLeague.DebugMode = true
RocketLeague.DebugMode = true

-- Rocket League Configurations
RocketLeague = {
    BallModel = -668163313, -- Model hash for the ball
    MatchDuration = 300,    -- Match duration in seconds
}

RocketLeague = {
    BallModel = -668163313, -- Model hash for the ball
    MatchDuration = 300,    -- Match duration in seconds
    BallSpawn = { x = -1623.9271, y = -1084.8730, z = 13.2350 }, -- Replace with the actual spawn coordinates
}
