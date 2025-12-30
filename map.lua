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

function Map.load()
    local Objects = require "objects"
    local Triggers = require "triggers" -- [NEW]

    print("--- LOADING MAP ---")
    Map.currentLevel = sti("assets/maps/overworld.lua")
    Map.tileSize = 32

    local layer = Map.currentLevel.layers["Floor"]
    if not layer then
        layer = Map.currentLevel.layers["Floors"] -- Try alternate name
    end
    
    if layer then
        -- [FIX] Get map dimensions properly for both formats
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
    
    -- [NEW] Load triggers
    Triggers.load()
    
    print("-------------------")
end

-- [NEW] Get current view radius based on time/location
function Map.getCurrentViewRadius()
    local Time = require "time"
    
    -- Indoor: standard radius
    if Map.currentLocation == Map.INDOOR then
        return Map.viewRadius
    end
    
    -- Outdoor Day: much larger radius (more visible area)
    if Map.currentLocation == Map.OUTDOOR and Time.isDay() then
        return Map.viewRadius * 2 -- Double the view distance during day
    end
    
    -- Outdoor Night: standard radius
    return Map.viewRadius
end

function Map.isTransparent(x, y)
    local wallLayer = Map.currentLevel.layers["Walls"]
    if not wallLayer then return true end
    
    -- Get map dimensions
    local mapWidth = wallLayer.width or Map.currentLevel.width
    local mapHeight = wallLayer.height or Map.currentLevel.height
    
    -- Check bounds
    if y < 1 or y > mapHeight or x < 1 or x > mapWidth then
        return false
    end
    
    -- Try STI's getTileInstance method first
    if wallLayer.getTileInstance then
        local tile = wallLayer:getTileInstance(x, y)
        return tile == nil  -- No tile means transparent
    end
    
    -- Fallback: Convert 2D grid coordinates to 1D array index
    local index = (y - 1) * mapWidth + x
    local tileID = wallLayer.data[index]
    
    -- If there's no tile (0 or nil), it's transparent
    if not tileID or tileID == 0 then
        return true
    end
    
    return false
end

function Map.updateFOV(px, py)
    -- [FIX] Validate input parameters
    if not px or not py then
        print("Warning: Invalid player position for FOV update")
        return
    end
    
    -- Get current view radius based on time/location
    local currentRadius = Map.getCurrentViewRadius()
    
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
        -- [FIX] Check row exists first, then check bounds
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
    
    -- [NEW] Different fade parameters for day vs night
    local fadeStart, fadeEnd, maxAlpha
    
    if Map.currentLocation == Map.OUTDOOR and Time.isDay() then
        -- Daytime: Very gentle fade, starts later, lighter overall
        fadeStart = currentRadius * 0.7  -- Only fade near the edge
        fadeEnd = currentRadius
        maxAlpha = 0.25  -- Much lighter fog
    else
        -- Nighttime/Indoor: Standard fade
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
        layer = Map.currentLevel.layers["Floors"] -- Try alternate name
    end
    
    if layer then
        local mapHeight = layer.height or Map.currentLevel.height
        local mapWidth = layer.width or Map.currentLevel.width
        
        for y = 1, mapHeight do
            for x = 1, mapWidth do
                local state = Map.visibilityGrid[y][x]
                local drawX = (x - 1) * Map.tileSize
                local drawY = (y - 1) * Map.tileSize
                
                if state == Map.HIDDEN then
                    love.graphics.setColor(0, 0, 0, 1)
                    love.graphics.rectangle("fill", drawX, drawY, Map.tileSize, Map.tileSize)
                    
                elseif state == Map.SEEN then
                    -- [NEW] Different fog opacity for seen areas based on time
                    local Time = require "time"
                    local alpha
                    
                    if Map.currentLocation == Map.OUTDOOR and Time.isDay() then
                        alpha = 0.2  -- Very light fog for daytime explored areas
                    else
                        alpha = 0.7  -- Darker fog for nighttime/indoor explored areas
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
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

-- [NEW] Change location type (call this when entering buildings, etc.)
function Map.setLocation(locationType)
    if locationType == Map.INDOOR or locationType == Map.OUTDOOR then
        Map.currentLocation = locationType
        
        -- Update FOV immediately
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

    -- 1. Clear current state
    Objects.clear()
    Triggers.clear()
    
    -- 2. Load the new map file via STI
    -- Ensure we pass the full path or relative path correctly
    print("Switching to map: " .. mapFile)
    Map.currentLevel = sti(mapFile)

    -- 3. Reset Grid / Collision / FOV data
    -- (Reuse your existing initialization logic here)
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

    -- 4. Parse new Layers (Entities, Triggers)
    local entityLayer = Map.currentLevel.layers["Entities"]
    if entityLayer then
        for _, obj in pairs(entityLayer.objects) do
            local gx = math.floor(obj.x / Map.tileSize) + 1
            local gy = math.floor(obj.y / Map.tileSize) + 1
            Objects.spawnFromDB(obj.name, gx, gy)
        end
        entityLayer.visible = false
    end

    -- Reload triggers for the new map
    Triggers.load()

    -- 5. Move Player to the spawn point of the new map
    Player.gridX = targetGridX
    Player.gridY = targetGridY
    
    -- Update FOV immediately so the screen isn't black
    Map.updateFOV(Player.gridX, Player.gridY)
end

function Map.isBlocked(gridX, gridY)
    local wallLayer = Map.currentLevel.layers["Walls"]
    if not wallLayer then return false end

    -- Get map dimensions
    local mapWidth = wallLayer.width or Map.currentLevel.width
    local mapHeight = wallLayer.height or Map.currentLevel.height

    -- Check bounds
    if gridY < 1 or gridY > mapHeight or gridX < 1 or gridX > mapWidth then
        return true
    end

    -- Try STI's getTileInstance method first (handles all formats)
    if wallLayer.getTileInstance then
        local tile = wallLayer:getTileInstance(gridX, gridY)
        return tile ~= nil
    end
    
    -- Fallback: Convert 2D grid coordinates to 1D array index
    local index = (gridY - 1) * mapWidth + gridX
    local tileID = wallLayer.data[index]
    
    -- If there's no tile (0 or nil), it's not blocked
    if not tileID or tileID == 0 then
        return false
    end
    
    return true
end

return Map