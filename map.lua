local sti = require "sti"

local Map = {}

function Map.load()
    -- [FIX] Load objects inside the function to avoid circular dependency loop
    local Objects = require "objects"

    print("--- LOADING MAP ---")
    Map.currentLevel = sti("level1.lua") 
    Map.tileSize = 32 
    
    -- DEBUG: List all layers found by STI
    for name, layer in pairs(Map.currentLevel.layers) do
        print("Layer Found: " .. name)
    end

    -- Attempt to find the layer
    local entityLayer = Map.currentLevel.layers["Entities"]

    if entityLayer then
        print("SUCCESS: Found Entities layer. parsing objects...")
        
        -- Iterate over the objects
        for _, obj in pairs(entityLayer.objects) do
            print(" - Spawning: " .. obj.name .. " at " .. obj.x .. "," .. obj.y)
            
            -- Calculate Grid Coordinates
            local gridX = math.floor(obj.x / Map.tileSize) + 1
            local gridY = math.floor(obj.y / Map.tileSize) + 1
            
            -- Spawn it
            Objects.spawnFromDB(obj.name, gridX, gridY)
        end
        
        entityLayer.visible = false
    else
        print("ERROR: 'Entities' layer NOT found. Please check level1.lua text content.")
    end
    print("-------------------")
end

function Map.draw(tx, ty)
    Map.currentLevel:draw(tx, ty)
end

function Map.isBlocked(gridX, gridY)
    local wallLayer = Map.currentLevel.layers["Walls"]
    if not wallLayer then return false end

    if gridY < 1 or gridY > #wallLayer.data or gridX < 1 or gridX > #wallLayer.data[1] then
        return true
    end

    local tile = wallLayer.data[gridY][gridX]
    if tile and tile.properties.solid then
        return true
    end
    return false
end

return Map