local sti = require "sti"
local fov = require "fov"

local Map = {}

-- Visibility States
Map.HIDDEN = 0
Map.SEEN = 1
Map.VISIBLE = 2

Map.visibilityGrid = {}
Map.viewRadius = 8
Map.distanceGrid = {}

-- Location type
Map.INDOOR = "indoor"
Map.OUTDOOR = "outdoor"
Map.currentLocation = Map.OUTDOOR

-- [NEW] Optimization flag to prevent redundant daytime reveals
Map.dayMapRevealed = false

function Map.load()
    local Objects = require "objects"
    local Triggers = require "triggers"

    print("--- LOADING MAP ---")
    Map.currentLevel = sti("assets/maps/overworld.lua")
    Map.tileSize = 32

    local layer = Map.currentLevel.layers["Floor"]
    if not layer then
        layer = Map.currentLevel.layers["Floors"]
    end
    
    if layer then
        local mapWidth = layer.width or Map.currentLevel.width
        local mapHeight = layer.height or Map.currentLevel.height
        
        for y = 1, mapHeight do
            Map.visibilityGrid[y] = {}
            Map.distanceGrid[y] = {}
            for x = 1, mapWidth do
                Map.visibilityGrid[y][x] = Map.HIDDEN
                Map.distanceGrid[y][x] = 0
            end
        end
    end

    for name, layer in pairs(Map.currentLevel.layers) do
        print("Layer Found: " .. name)
    end

    local entityLayer = Map.currentLevel.layers["Entities"]

    if entityLayer then
        print("SUCCESS: Found Entities layer. parsing objects...")
        
        for _, obj in pairs(entityLayer.objects) do
            print(" - Spawning: " .. obj.name .. " at " .. obj.x .. "," .. obj.y)
            
            local gridX = math.floor(obj.x / Map.tileSize) + 1
            local gridY = math.floor(obj.y / Map.tileSize) + 1
            
            Objects.spawnFromDB(obj.name, gridX, gridY)
        end
        
        entityLayer.visible = false
    else
        print("ERROR: 'Entities' layer NOT found. Please check level1.lua text content.")
    end
    
    Triggers.load()
    
    print("-------------------")
end

function Map.getCurrentViewRadius()
    local Time = require "time"
    
    if Map.currentLocation == Map.INDOOR then
        return Map.viewRadius
    end
    
    if Map.currentLocation == Map.OUTDOOR and Time.isDay() then
        return Map.viewRadius * 2
    end
    
    return Map.viewRadius
end

function Map.isTransparent(x, y)
    local wallLayer = Map.currentLevel.layers["Walls"]
    if not wallLayer then return true end
    
    local mapWidth = wallLayer.width or Map.currentLevel.width
    local mapHeight = wallLayer.height or Map.currentLevel.height
    
    if y < 1 or y > mapHeight or x < 1 or x > mapWidth then
        return false
    end
    
    if wallLayer.data and wallLayer.data[y] then
        local tile = wallLayer.data[y][x]
        return tile == nil
    end
    
    return true
end

function Map.updateFOV(px, py)
    if not px or not py then
        print("Warning: Invalid player position for FOV update")
        return
    end
    
    local Time = require "time"
    local currentRadius = Map.getCurrentViewRadius()
    
    -- [OPTIMIZED] Only reveal entire map once when entering daytime
    if Map.currentLocation == Map.OUTDOOR and Time.isDay() and not Map.dayMapRevealed then
        for y = 1, #Map.visibilityGrid do
            for x = 1, #Map.visibilityGrid[y] do
                if Map.visibilityGrid[y][x] == Map.HIDDEN then
                    Map.visibilityGrid[y][x] = Map.SEEN
                end
            end
        end
        Map.dayMapRevealed = true
    elseif Map.currentLocation == Map.INDOOR or Time.isNight() then
        Map.dayMapRevealed = false
    end
    
    -- Downgrade current VISIBLE tiles to SEEN
    for y = 1, #Map.visibilityGrid do
        for x = 1, #Map.visibilityGrid[y] do
            if Map.visibilityGrid[y][x] == Map.VISIBLE then
                Map.visibilityGrid[y][x] = Map.SEEN
            end
        end
    end
    
    -- Calculate new VISIBLE tiles with current radius
    fov.calculate(px, py, currentRadius, Map.isTransparent, function(x, y)
        if Map.visibilityGrid[y] and 
           Map.visibilityGrid[y][x] ~= nil then
            
            Map.visibilityGrid[y][x] = Map.VISIBLE
            
            local dx = x - px
            local dy = y - py
            Map.distanceGrid[y][x] = math.sqrt(dx * dx + dy * dy)
        end
    end)
end

function Map.isVisible(x, y)
    if not Map.visibilityGrid[y] or not Map.visibilityGrid[y][x] then return false end
    return Map.visibilityGrid[y][x] == Map.VISIBLE
end

function Map.getFogAlpha(dist)
    local Time = require "time"
    local currentRadius = Map.getCurrentViewRadius()
    
    local fadeStart, fadeEnd, maxAlpha
    
    if Map.currentLocation == Map.OUTDOOR and Time.isDay() then
        fadeStart = currentRadius * 0.7
        fadeEnd = currentRadius
        maxAlpha = 0.25
    else
        fadeStart = currentRadius * 0.5
        fadeEnd = currentRadius
        maxAlpha = 0.5
    end
    
    if dist < fadeStart then
        return 0
    elseif dist > fadeEnd then
        return 1
    else
        local t = (dist - fadeStart) / (fadeEnd - fadeStart)
        t = t * t * (3 - 2 * t)
        return t * maxAlpha
    end
end

function Map.draw(tx, ty, sx, sy)
    Map.currentLevel:draw(tx, ty, sx, sy)
    
    love.graphics.push()
    love.graphics.scale(sx, sy)
    love.graphics.translate(tx, ty)
    
    local layer = Map.currentLevel.layers["Floor"]
    if not layer then
        layer = Map.currentLevel.layers["Floors"]
    end
    
    if layer then
        local mapHeight = layer.height or Map.currentLevel.height
        local mapWidth = layer.width or Map.currentLevel.width
        
        -- [OPTIMIZATION] Batch hidden tiles into regions instead of drawing each one
        local hiddenRegions = {}
        
        for y = 1, mapHeight do
            for x = 1, mapWidth do
                local state = Map.visibilityGrid[y][x]
                local drawX = (x - 1) * Map.tileSize
                local drawY = (y - 1) * Map.tileSize
                
                if state == Map.HIDDEN then
                    -- Collect hidden tiles for batch drawing
                    table.insert(hiddenRegions, {drawX, drawY})
                    
                elseif state == Map.SEEN then
                    local Time = require "time"
                    local alpha
                    
                    if Map.currentLocation == Map.OUTDOOR and Time.isDay() then
                        alpha = 0.2
                    else
                        alpha = 0.7
                    end
                    
                    love.graphics.setColor(0, 0, 0, alpha)
                    love.graphics.rectangle("fill", drawX, drawY, Map.tileSize, Map.tileSize)
                    
                elseif state == Map.VISIBLE then
                    local dist = Map.distanceGrid[y][x]
                    local alpha = Map.getFogAlpha(dist)
                    
                    if alpha > 0 then
                        love.graphics.setColor(0, 0, 0, alpha)
                        love.graphics.rectangle("fill", drawX, drawY, Map.tileSize, Map.tileSize)
                    end
                end
            end
        end
        
        -- [OPTIMIZATION] Draw all hidden tiles at once
        if #hiddenRegions > 0 then
            love.graphics.setColor(0, 0, 0, 1)
            for _, region in ipairs(hiddenRegions) do
                love.graphics.rectangle("fill", region[1], region[2], Map.tileSize, Map.tileSize)
            end
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

function Map.setLocation(locationType)
    if locationType == Map.INDOOR or locationType == Map.OUTDOOR then
        Map.currentLocation = locationType
        
        -- Reset reveal flag when changing locations
        Map.dayMapRevealed = false
        
        local Player = require "player"
        Map.updateFOV(Player.gridX, Player.gridY)
    end
end

function Map.resize(w, h)
    Map.currentLevel:resize(w, h)
end

function Map.changeLevel(mapFile, targetGridX, targetGridY)
    local Player = require "player"
    local Objects = require "objects"
    local Triggers = require "triggers"

    Objects.clear()
    Triggers.clear()
    
    print("Switching to map: " .. mapFile)
    Map.currentLevel = sti(mapFile)

    local layer = Map.currentLevel.layers["Floor"] or Map.currentLevel.layers["Floors"]
    local mapWidth = layer.width or Map.currentLevel.width
    local mapHeight = layer.height or Map.currentLevel.height

    Map.visibilityGrid = {}
    Map.distanceGrid = {}
    
    for y = 1, mapHeight do
        Map.visibilityGrid[y] = {}
        Map.distanceGrid[y] = {}
        for x = 1, mapWidth do
            Map.visibilityGrid[y][x] = Map.HIDDEN
            Map.distanceGrid[y][x] = 0
        end
    end
    
    -- Reset reveal flag for new map
    Map.dayMapRevealed = false

    local entityLayer = Map.currentLevel.layers["Entities"]
    if entityLayer then
        for _, obj in pairs(entityLayer.objects) do
            local gx = math.floor(obj.x / Map.tileSize) + 1
            local gy = math.floor(obj.y / Map.tileSize) + 1
            Objects.spawnFromDB(obj.name, gx, gy)
        end
        entityLayer.visible = false
    end

    Triggers.load()

    Player.gridX = targetGridX
    Player.gridY = targetGridY
    
    Map.updateFOV(Player.gridX, Player.gridY)
end

function Map.isBlocked(gridX, gridY)
    local wallLayer = Map.currentLevel.layers["Walls"]
    if not wallLayer then return false end

    local mapWidth = wallLayer.width or Map.currentLevel.width
    local mapHeight = wallLayer.height or Map.currentLevel.height

    if gridY < 1 or gridY > mapHeight or gridX < 1 or gridX > mapWidth then
        return true
    end

    if wallLayer.data and wallLayer.data[gridY] then
        local tile = wallLayer.data[gridY][gridX]
        return tile ~= nil
    end

    return false
end

return Map