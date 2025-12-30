local GameLog = require "gamelog"
local Player = require "player"

local Classes = {}

-- === BASE HELPER ===
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
function Classes.Consumable(args)
    local item = createBase(args)
    
    item.actionLabel = "CONSUME"
    
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
        
        return used
    end
    
    return item
end

-- === CLASS: WEAPON ===
function Classes.Weapon(args)
    local item = createBase(args)
    
    item.actionLabel = "EQUIP"
    item.damage = args.damage
    
    item.onUse = function()
        GameLog.add("You equipped " .. item.name .. ".", {1, 1, 1})
        return false 
    end
    
    return item
end

-- === CLASS: JUNK ===
function Classes.Junk(args)
    local item = createBase(args)
    
    item.onUse = function()
        GameLog.add("You fiddle with the " .. item.name .. ".", {0.5, 0.5, 0.5})
        return false
    end
    
    return item
end

-- === CLASS: FURNITURE ===
function Classes.Furniture(args)
    local item = createBase(args)
    item.isBlocking = true
    
    item.onInteract = function()
        if args.msg then
            GameLog.add(args.msg, {1, 1, 0})
        else
            GameLog.add("It's a " .. item.name .. ".", {1, 1, 1})
        end
        return false
    end
    
    return item
end

-- === CLASS: CONTAINER ===
-- [NEW] Containers can hold items
function Classes.Container(args)
    local item = createBase(args)
    item.isBlocking = true
    item.actionLabel = "OPEN"
    item.isContainer = true -- Flag to identify containers
    item.inventory = {} -- Stores item IDs
    
    item.onInteract = function()
        -- Interaction is handled by main.lua looting system
        return false
    end
    
    -- Helper function to add items to container
    item.addItem = function(itemId)
        table.insert(item.inventory, itemId)
    end
    
    -- Helper to check if empty
    item.isEmpty = function()
        return #item.inventory == 0
    end
    
    return item
end

return Classes