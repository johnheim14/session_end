local Camera = {}

Camera.x = 0
Camera.y = 0
Camera.scale = 2 -- [CHANGE] Zoom level (2x makes everything twice as big)

function Camera.setFollowTarget(px, py)
    -- Get the center of the screen
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Calculate offset to center the target
    -- We divide screen size by scale because the screen shows less "world" when zoomed in
    Camera.x = px - (screenW / 2) / Camera.scale
    Camera.y = py - (screenH / 2) / Camera.scale
end

function Camera.set()
    love.graphics.push() -- Save the current transformation
    love.graphics.scale(Camera.scale) -- [CHANGE] Zoom in!
    love.graphics.translate(-Camera.x, -Camera.y) -- Move the world
end

function Camera.unset()
    love.graphics.pop() -- Restore the transformation (for UI drawing)
end

-- Helper to convert screen clicks to world coordinates
function Camera.getMouseWorldPos()
    local mx, my = love.mouse.getPosition()
    -- Apply scale to mouse coordinates
    return (mx / Camera.scale) + Camera.x, (my / Camera.scale) + Camera.y
end

return Camera