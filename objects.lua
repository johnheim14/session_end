local ItemDB = require "item_db"
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

-- [UPDATED] spawnFromDB to handle weight logic
function Objects.spawnFromDB(id, x, y)
    local def = ItemDB.definitions[id]
    if not def then print("Error: ID '"..id.."' not found"); return end

    local interactionLogic
    
    if def.isBlocking then
        interactionLogic = function()
            if def.onInteract then def.onInteract() end
            return false 
        end
    else
        interactionLogic = function()
            -- [UPDATED] Pass 'id' and 'actionLabel' to Player.addItem
            local success = Player.addItem(
                id,                  -- The DB ID (e.g. "medkit")
                def.name, 
                def.description, 
                def.weight, 
                def.actionLabel,     -- New field! (e.g. "Consume")
                def.onUse
            )
            
            if success then
                GameLog.add("Picked up " .. def.name .. ".", {0, 1, 0})
                return true
            else
                GameLog.add("Inventory Full!", {1, 0, 0})
                return false
            end
        end
    end

    Objects.spawn(def.name, x, y, def.symbol, def.color, def.isBlocking, interactionLogic)
end

function Objects.interactAt(x, y)
    -- Keep existing code
end

function Objects.draw()
    -- Keep existing code (with the pile indicator if you added it!)
    for _, obj in ipairs(Objects.list) do
        local drawX = (obj.x - 1) * Map.tileSize
        local drawY = (obj.y - 1) * Map.tileSize
        local scale = Map.tileSize / 32
        love.graphics.setColor(obj.color)
        love.graphics.draw(Assets.tileTexture, Assets.quads.item, drawX, drawY, 0, scale, scale)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(obj.symbol, drawX + 14, drawY + 10)
    end
    love.graphics.setColor(1, 1, 1)
end

function Objects.clear() Objects.list = {} end

return Objects