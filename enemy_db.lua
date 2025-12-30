-- enemy_db.lua
local EnemyDB = {}

EnemyDB.definitions = {
    ["RadRoach"] = {
        name = "RadRoach",
        symbol = "r",
        color = {1, 0.4, 0.4}, -- Light Red
        maxHP = 20,
        stats = { strength = 2, reflexes = 3, endurance = 2 },
        isBlocking = true,
        xp = 10
    },
    ["Raider"] = {
        name = "Raider",
        symbol = "R",
        color = {1, 0, 0}, -- Red
        maxHP = 50,
        stats = { strength = 4, reflexes = 4, endurance = 4 },
        isBlocking = true,
        xp = 50
    }
}

return EnemyDB