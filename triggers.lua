local Triggers = {}

Triggers.list = {}

function Triggers.load()
    local Map = require "map"
    
    print("--- LOADING TRIGGERS ---")
    
    -- Look for a Triggers layer in the Tiled map
    local triggerLayer = Map.currentLevel.layers["Triggers"]
    
    if triggerLayer then
        print("SUCCESS: Found Triggers layer.")
        
        for _, obj in pairs(triggerLayer.objects) do
            -- Convert pixel coordinates to grid coordinates
            local gridX = math.floor(obj.x / Map.tileSize) + 1
            local gridY = math.floor(obj.y / Map.tileSize) + 1
            
            -- Calculate width and height in tiles
            local gridWidth = math.ceil(obj.width / Map.tileSize)
            local gridHeight = math.ceil(obj.height / Map.tileSize)
            
            -- Store the trigger
            table.insert(Triggers.list, {
                name = obj.name or "Unnamed Trigger",
                x = gridX,
                y = gridY,
                width = gridWidth,
                height = gridHeight,
                properties = obj.properties or {}
            })
            
            print(" - Loaded trigger: " .. (obj.name or "Unnamed") .. 
                  " at " .. gridX .. "," .. gridY .. 
                  " (size: " .. gridWidth .. "x" .. gridHeight .. ")")
        end
        
        -- Hide the trigger layer so it doesn't render
        triggerLayer.visible = false
    else
        print("No 'Triggers' layer found (this is okay if you don't have triggers yet).")
    end
    
    print("------------------------")
end

-- Check if a position overlaps with any trigger
function Triggers.check(x, y)
    for _, trigger in ipairs(Triggers.list) do
        -- Check if point (x, y) is inside the trigger rectangle
        if x >= trigger.x and x < trigger.x + trigger.width and
           y >= trigger.y and y < trigger.y + trigger.height then
            return trigger
        end
    end
    return nil
end

-- Handle a trigger activation
function Triggers.activate(trigger)
    if not trigger or not trigger.properties then return end
    
    local props = trigger.properties
    
    -- Location change trigger
    if props.type == "location_trigger" and props.location then
        local Map = require "map"
        local GameLog = require "gamelog"
        
        if props.location == "indoor" then
            Map.setLocation(Map.INDOOR)
            GameLog.add("Entered: " .. (trigger.name or "Building"), {0.8, 0.8, 0.5})
        elseif props.location == "outdoor" then
            Map.setLocation(Map.OUTDOOR)
            GameLog.add("Exited: " .. (trigger.name or "Building"), {0.5, 0.8, 0.8})
        end
    end
    
    -- You can add more trigger types here later:
    -- if props.type == "cutscene_trigger" then ...
    -- if props.type == "enemy_spawn" then ...
end

-- Optional: Draw trigger bounds for debugging
function Triggers.drawDebug()
    local Map = require "map"
    
    love.graphics.setColor(1, 1, 0, 0.3)
    for _, trigger in ipairs(Triggers.list) do
        local drawX = (trigger.x - 1) * Map.tileSize
        local drawY = (trigger.y - 1) * Map.tileSize
        local drawW = trigger.width * Map.tileSize
        local drawH = trigger.height * Map.tileSize
        
        love.graphics.rectangle("fill", drawX, drawY, drawW, drawH)
    end
    
    love.graphics.setColor(1, 1, 0, 1)
    for _, trigger in ipairs(Triggers.list) do
        local drawX = (trigger.x - 1) * Map.tileSize
        local drawY = (trigger.y - 1) * Map.tileSize
        local drawW = trigger.width * Map.tileSize
        local drawH = trigger.height * Map.tileSize
        
        love.graphics.rectangle("line", drawX, drawY, drawW, drawH)
        love.graphics.print(trigger.name, drawX + 2, drawY + 2)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function Triggers.clear()
    Triggers.list = {}
end

return Triggers