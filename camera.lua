local Camera = {}

Camera.x = 0
Camera.y = 0
Camera.scale = 1

function Camera.setFollowTarget(px, py)
    -- Get the center of the screen
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Calculate offset to center the target
    -- We subtract half the screen width/height to center it
    Camera.x = px - (screenW / 2)
    Camera.y = py - (screenH / 2)
end

function Camera.set()
    love.graphics.push() -- Save the current transformation
    love.graphics.translate(-Camera.x, -Camera.y) -- Move the world
end

function Camera.unset()
    love.graphics.pop() -- Restore the transformation (for UI drawing)
end

-- Helper to convert screen clicks to world coordinates (useful later)
function Camera.getMouseWorldPos()
    local mx, my = love.mouse.getPosition()
    return mx + Camera.x, my + Camera.y
end

return Camera