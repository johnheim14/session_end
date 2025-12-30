local Classes = require "item_classes"

local ItemDB = {}

ItemDB.definitions = {
    -- === MEDICAL (Consumables) ===
    ["medkit"] = Classes.Consumable({
        name = "Medkit", symbol = "M", color = {1, 0, 0}, weight = 2.0,
        description = "Restores massive health.",
        heal = 50
    }),
    
    ["bandage"] = Classes.Consumable({
        name = "Bandage", symbol = "b", color = {0.8, 0.8, 0.7}, weight = 0.2,
        description = "Stops bleeding.",
        heal = 10
    }),

    ["stimpak"] = Classes.Consumable({
        name = "Stimpak", symbol = "t", color = {0.8, 0.8, 0.7}, weight = 0.2,
        description = "Instantly heals player.",
        heal = 25
    }),

    -- === FOOD (Consumables) ===
    ["whiskey"] = Classes.Consumable({
        name = "Whiskey", symbol = "w", color = {0.8, 0.5, 0}, weight = 1.0,
        description = "Reduces stress.",
        stress = 30
    }),

    -- === WEAPONS ===
    ["rifle"] = Classes.Weapon({
        name = "Hunting Rifle", symbol = "R", color = {0.4, 0.3, 0.2}, weight = 8.0,
        description = "A long range rifle.",
        damage = 10
    }),
    
    ["knife"] = Classes.Weapon({
        name = "Combat Knife", symbol = "/", color = {0.8, 0.8, 0.8}, weight = 1.0,
        description = "Sharp blade.",
        damage = 4
    }),

    ["pistol"] = Classes.Weapon({
        name = "10mm Pistol", symbol = "r", color = {0.8, 0.8, 0.8}, weight = 1.0,
        description = "The standard issue pistol.",
        damage = 8
    }),

    ["sledgehammer"] = Classes.Weapon({
        name = "Sledgehammer", symbol = "%", color = {0.8, 0.8, 0.8}, weight = 1.0,
        description = "Large hammer.",
        damage = 12
    }),

    -- === JUNK ===
    ["scrap"] = Classes.Junk({
        name = "Scrap Metal", symbol = "%", color = {0.5, 0.5, 0.6}, weight = 0.5,
        description = "Useful for repairs."
    }),

    -- === FURNITURE ===
    ["vending_machine"] = Classes.Furniture({
        name = "Vending Machine", symbol = "V", color = {0.2, 0.2, 0.8},
        msg = "The machine is empty."
    }),

    -- === CONTAINERS ===
    ["footlocker"] = Classes.Container({
        name = "Footlocker",
        symbol = "=",
        color = {0.6, 0.4, 0.2},
        description = "A sturdy metal footlocker."
    }),

    ["safe"] = Classes.Container({
        name = "Safe",
        symbol = "$",
        color = {0.3, 0.3, 0.3},
        description = "A secure safe."
    }),

    ["crate"] = Classes.Container({
        name = "Wooden Crate",
        symbol = "C",
        color = {0.5, 0.3, 0.1},
        description = "A weathered wooden crate."
    }),

    ["backpack"] = Classes.Container({
        name = "Backpack",
        symbol = "B",
        color = {0.2, 0.4, 0.2},
        description = "A worn backpack."
    }),
}

return ItemDB