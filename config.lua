-- config.lua

RocketLeague = {}

-- Teams
RocketLeague.Teams = {
    {
        name = "GROVE",
        color = "blue",
        spawn = vector4(-1619.506, -1080.122, 12.40639, 0.0)
    },
    {
        name = "VAGOS",
        color = "orange",
        spawn = vector4(-1627.436, -1089.037, 12.40554, 180.0)
    }
}

-- Ball spawn location
RocketLeague.BallSpawn = vector3(-1624.645, -1085.268, 12.4047)

-- Ball model to use
RocketLeague.BallModel = "prop_beach_ball_02"

-- Match duration in seconds (e.g. 300 = 5 minutes)
RocketLeague.MatchDuration = 300

-- Sound FX (preloaded sound set names)
RocketLeague.Sounds = {
    goal = "Goal_Achieved_Sound_Set",
    start = "Start_Whistle_Sound_Set",
    endgame = "Game_Over_Sound_Set"
}

-- Countdown speed (3..2..1..GO)
RocketLeague.CountdownTime = 3

-- Allow solo testing
RocketLeague.DebugMode = true
