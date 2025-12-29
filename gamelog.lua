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
    local start_y = love.graphics.getHeight() - 200
    
    -- Draw a semi-transparent background box for the log
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, start_y, 800, 200)
    
    -- Draw the text
    for i, msg in ipairs(GameLog.history) do
        love.graphics.setColor(msg.color)
        love.graphics.print(msg.text, 10, start_y + (i * 15))
    end
    
    -- Reset color to white
    love.graphics.setColor(1, 1, 1, 1)
end

return GameLog