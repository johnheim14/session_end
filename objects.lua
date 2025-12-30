local ItemDB = require "item_db"
local EnemyDB = require "enemy_db"
local Player = require "player"
local GameLog = require "gamelog"
local Map = require "map"
local Assets = require "assets"

local Objects = {}
Objects.list = {}
Objects.spatialGrid = {}

local function getGridKey(x, y)
    return x .. "," .. y
end

local function addToGrid(obj)
    local key = getGridKey(obj.x, obj.y)
    if not Objects.spatialGrid[key] then
        Objects.spatialGrid[key] = {}
    end
    table.insert(Objects.spatialGrid[key], obj)
end

local function removeFromGrid(obj)
    local key = getGridKey(obj.x, obj.y)
    if Objects.spatialGrid[key] then
        for i, o in ipairs(Objects.spatialGrid[key]) do
            if o == obj then
                table.remove(Objects.spatialGrid[key], i)
                if #Objects.spatialGrid[key] == 0 then
                    Objects.spatialGrid[key] = nil
                end
                return
            end
        end
    end
end

local function updateGridPosition(obj, oldX, oldY, newX, newY)
    local oldKey = getGridKey(oldX, oldY)
    if Objects.spatialGrid[oldKey] then
        for i, o in ipairs(Objects.spatialGrid[oldKey]) do
            if o == obj then
                table.remove(Objects.spatialGrid[oldKey], i)
                if #Objects.spatialGrid[oldKey] == 0 then
                    Objects.spatialGrid[oldKey] = nil
                end
                break
            end
        end
    end
    
    obj.x = newX
    obj.y = newY
    addToGrid(obj)
end

function Objects.spawn(name, x, y, symbol, color, isBlocking, onInteract)
    local obj = {
        name = name, x = x, y = y, symbol = symbol, color = color,
        isBlocking = isBlocking, onInteract = onInteract
    }
    table.insert(Objects.list, obj)
    addToGrid(obj)
end

function Objects.getObjectAt(x, y)
    local key = getGridKey(x, y)
    local objectsAtPos = Objects.spatialGrid[key]
    if objectsAtPos and #objectsAtPos > 0 then
        return objectsAtPos[1]
    end
    return nil
end

function Objects.getAllAt(x, y)
    local key = getGridKey(x, y)
    return Objects.spatialGrid[key] or {}
end

function Objects.remove(objectToRemove)
    for i, obj in ipairs(Objects.list) do
        if obj == objectToRemove then
            removeFromGrid(obj)
            table.remove(Objects.list, i)
            return
        end
    end
end

-- [UPDATED] Support for containers with Tiled properties
function Objects.spawnFromDB(id, x, y, properties)
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

        -- Create the object
        local obj = {
            name = itemDef.name,
            x = x, y = y,
            symbol = itemDef.symbol,
            color = itemDef.color,
            isBlocking = itemDef.isBlocking,
            onInteract = interactionLogic,
        }
        
        -- [NEW] If it's a container, copy container-specific properties
        if itemDef.isContainer then
            obj.isContainer = true
            obj.inventory = {}
            
            -- Create methods that work with THIS object's inventory
            obj.isEmpty = function()
                return #obj.inventory == 0
            end
            
            obj.addItem = function(itemId)
                table.insert(obj.inventory, itemId)
            end
            
            -- Parse 'contains' property from Tiled if present
            if properties and properties.contains then
                for itemId in string.gmatch(properties.contains, "[^,]+") do
                    itemId = itemId:match("^%s*(.-)%s*$") -- trim whitespace
                    obj.addItem(itemId)
                end
            end
        end
        
        table.insert(Objects.list, obj)
        addToGrid(obj)
        return
    end

    -- 2. Check Enemy Database
    local enemyDef = EnemyDB.definitions[id]
    if enemyDef then
        local interactionLogic = function()
             return false 
        end

        local obj = {
            name = enemyDef.name,
            x = x, y = y,
            symbol = enemyDef.symbol,
            color = enemyDef.color,
            isBlocking = true,
            isEnemy = true,
            onInteract = interactionLogic,
            
            maxHP = enemyDef.maxHP,
            currentHP = enemyDef.maxHP,
            stats = enemyDef.stats or {},
            maxStamina = 5,
            currentStamina = 5,
        }
        
        table.insert(Objects.list, obj)
        addToGrid(obj)
        print("Spawned Enemy: " .. id)
        return
    end

    print("Error: ID '"..id.."' not found in ItemDB or EnemyDB")
end

function Objects.draw()
    for _, obj in ipairs(Objects.list) do
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

function Objects.clear() 
    Objects.list = {}
    Objects.spatialGrid = {}
end

function Objects.moveObject(obj, newX, newY)
    if obj and obj.x and obj.y then
        updateGridPosition(obj, obj.x, obj.y, newX, newY)
    end
end

return Objects