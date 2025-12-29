local GameLog = {}
GameLog.history = {}
GameLog.max_lines = 12

function GameLog.add(message, color)
    -- Default to white if no color provided
    local c = color or {1, 1, 1, 1} 
    local timestamp = os.date("%H:%M:%S")
    
    -- Insert new message at the end
    table.insert(GameLog.history, {text = "["..timestamp.."] " .. message, color = c})
    
    -- Remove old messages if we exceed the limit
    if #GameLog.history > GameLog.max_lines then
        table.remove(GameLog.history, 1)
    end
end

function GameLog.draw()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local start_y = screenH - 200
    
    -- Draw a semi-transparent background box for the log
    love.graphics.setColor(0, 0, 0, 0.8)
    -- [UPDATED] Use screenW instead of hardcoded 800 so it stretches on maximize
    love.graphics.rectangle("fill", 0, start_y, screenW, 200)
    
    -- Draw the text
    for i, msg in ipairs(GameLog.history) do
        love.graphics.setColor(msg.color)
        love.graphics.print(msg.text, 10, start_y + (i * 15))
    end
    
    -- Reset color to white
    love.graphics.setColor(1, 1, 1, 1)
end

return GameLog