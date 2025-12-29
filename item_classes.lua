local GameLog = require "gamelog"
local Player = require "player"

local Classes = {}

-- === BASE HELPER ===
-- This acts as a template for all items
local function createBase(args)
    return {
        name = args.name,
        symbol = args.symbol,
        color = args.color,
        description = args.description,
        weight = args.weight or 0,
        isBlocking = args.isBlocking or false
    }
end

-- === CLASS: CONSUMABLE ===
-- Automatically sets actionLabel to "CONSUME" and handles the logic
function Classes.Consumable(args)
    local item = createBase(args)
    
    item.actionLabel = "CONSUME"
    
    -- We generate the onUse function based on the data provided
    item.onUse = function()
        local used = false
        
        -- Handle Healing
        if args.heal then
            if Player.currentHealth < Player.maxHealth then
                Player.currentHealth = math.min(Player.currentHealth + args.heal, Player.maxHealth)
                GameLog.add("Restored " .. args.heal .. " HP.", {0, 1, 0})
                used = true
            else
                GameLog.add("Health is already full.", {1, 1, 0})
            end
        end
        
        -- Handle Stress
        if args.stress then
            Player.currentStress = math.max(Player.currentStress - args.stress, 0)
            GameLog.add("Relieved " .. args.stress .. " Stress.", {0, 1, 1})
            used = true
        end
        
        return used -- Returns true to Player.lua to remove item
    end
    
    return item
end

-- === CLASS: WEAPON ===
-- Automatically sets actionLabel to "EQUIP"
function Classes.Weapon(args)
    local item = createBase(args)
    
    item.actionLabel = "EQUIP"
    item.damage = args.damage -- Specific to weapons
    
    item.onUse = function()
        -- Logic to equip the item (we can expand this later)
        GameLog.add("You equipped " .. item.name .. ".", {1, 1, 1})
        
        -- Return FALSE because we don't want to consume/delete the weapon
        return false 
    end
    
    return item
end

-- === CLASS: JUNK ===
-- Has no action, just flavor text
function Classes.Junk(args)
    local item = createBase(args)
    
    -- No actionLabel, so the menu will just show "DROP"
    item.onUse = function()
        GameLog.add("You fiddle with the " .. item.name .. ".", {0.5, 0.5, 0.5})
        return false
    end
    
    return item
end

-- === CLASS: FURNITURE ===
-- Automatically blocking
function Classes.Furniture(args)
    local item = createBase(args)
    item.isBlocking = true
    
    item.onInteract = function()
        if args.msg then
            GameLog.add(args.msg, {1, 1, 0})
        else
            GameLog.add("It's a " .. item.name .. ".", {1, 1, 1})
        end
        return false -- Never delete furniture
    end
    
    return item
end

return Classes