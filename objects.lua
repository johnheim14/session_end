local ItemDB = require "item_db"
local EnemyDB = require "enemy_db"
local Player = require "player"
local GameLog = require "gamelog"
local Map = require "map"
local Assets = require "assets"

local Objects = {}
Objects.list = {}

-- ... (Keep spawn, getObjectAt, getAllAt, remove, draw, clear) ...
function Objects.spawn(name, x, y, symbol, color, isBlocking, onInteract)
    table.insert(Objects.list, {
        name = name, x = x, y = y, symbol = symbol, color = color,
        isBlocking = isBlocking, onInteract = onInteract
    })
end

function Objects.getObjectAt(x, y)
    for _, obj in ipairs(Objects.list) do
        if obj.x == x and obj.y == y then return obj end
    end
    return nil
end

function Objects.getAllAt(x, y)
    local found = {}
    for _, obj in ipairs(Objects.list) do
        if obj.x == x and obj.y == y then table.insert(found, obj) end
    end
    return found
end

function Objects.remove(objectToRemove)
    for i, obj in ipairs(Objects.list) do
        if obj == objectToRemove then
            table.remove(Objects.list, i)
            return
        end
    end
end

-- [UPDATED] spawnFromDB to handle items AND enemies
function Objects.spawnFromDB(id, x, y)
    -- 1. Check Item Database First
    local itemDef = ItemDB.definitions[id]
    if itemDef then
        local interactionLogic
        
        if itemDef.isBlocking then
            interactionLogic = function()
                if itemDef.onInteract then itemDef.onInteract() end
                return false 
            end
        else
            interactionLogic = function()
                local success = Player.addItem(
                    id,
                    itemDef.name, 
                    itemDef.description, 
                    itemDef.weight, 
                    itemDef.actionLabel,
                    itemDef.onUse
                )
                
                if success then
                    GameLog.add("Picked up " .. itemDef.name .. ".", {0, 1, 0})
                    return true
                else
                    GameLog.add("Inventory Full!", {1, 0, 0})
                    return false
                end
            end
        end

        Objects.spawn(itemDef.name, x, y, itemDef.symbol, itemDef.color, itemDef.isBlocking, interactionLogic)
        return
    end

    -- 2. Check Enemy Database [NEW]
    local enemyDef = EnemyDB.definitions[id]
    if enemyDef then
        -- Define Enemy Interaction (Attack Trigger handled in Player.lua, so this is fallback)
        local interactionLogic = function()
             return false 
        end

        -- Create the Object manually to add HP/Stats
        local obj = {
            name = enemyDef.name,
            x = x, y = y,
            symbol = enemyDef.symbol,
            color = enemyDef.color,
            isBlocking = true,
            isEnemy = true, -- [IMPORTANT] Flag for logic
            onInteract = interactionLogic,
            
            -- Combat Stats
            maxHP = enemyDef.maxHP,
            currentHP = enemyDef.maxHP,
            stats = enemyDef.stats or {},
            maxStamina = 5, -- Default
            currentStamina = 5,
        }
        
        table.insert(Objects.list, obj)
        print("Spawned Enemy: " .. id)
        return
    end

    print("Error: ID '"..id.."' not found in ItemDB or EnemyDB")
end

function Objects.interactAt(x, y)
    -- Keep existing code
end

function Objects.draw()
    -- Keep existing code (with the pile indicator if you added it!)
    for _, obj in ipairs(Objects.list) do
        -- [NEW] VISIBILITY CHECK
        if Map.isVisible(obj.x, obj.y) then
            local drawX = (obj.x - 1) * Map.tileSize
            local drawY = (obj.y - 1) * Map.tileSize
            local scale = Map.tileSize / 32
            love.graphics.setColor(obj.color)
            love.graphics.draw(Assets.tileTexture, Assets.quads.item, drawX, drawY, 0, scale, scale)
            love.graphics.setColor(0, 0, 0)
            love.graphics.print(obj.symbol, drawX + 14, drawY + 10)
        end
    end
    love.graphics.setColor(1, 1, 1)
end

function Objects.clear() Objects.list = {} end

return Objects