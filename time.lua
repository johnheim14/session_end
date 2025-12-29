local Time = {}

-- Time states
Time.DAY = "day"
Time.NIGHT = "night"

-- Current time
Time.currentTime = Time.DAY

-- Optional: Track time progression if you want automatic cycles
Time.timeElapsed = 0
Time.dayDuration = 300   -- 5 minutes of day
Time.nightDuration = 300 -- 5 minutes of night
Time.autoProgress = false -- Set to true for automatic day/night cycling

function Time.setTime(newTime)
    if newTime == Time.DAY or newTime == Time.NIGHT then
        Time.currentTime = newTime
        Time.timeElapsed = 0
        
        -- Update FOV when time changes (only if player is loaded)
        local Player = require "player"
        local Map = require "map"
        
        -- [FIX] Check if player position is valid before updating FOV
        if Player.gridX and Player.gridY then
            Map.updateFOV(Player.gridX, Player.gridY)
            
            local GameLog = require "gamelog"
            if newTime == Time.DAY then
                GameLog.add("The sun rises...", {1, 1, 0.5})
            else
                GameLog.add("Night falls...", {0.3, 0.3, 0.6})
            end
        end
    end
end

function Time.toggle()
    if Time.currentTime == Time.DAY then
        Time.setTime(Time.NIGHT)
    else
        Time.setTime(Time.DAY)
    end
end

function Time.isDay()
    return Time.currentTime == Time.DAY
end

function Time.isNight()
    return Time.currentTime == Time.NIGHT
end

function Time.update(dt)
    if not Time.autoProgress then return end
    
    Time.timeElapsed = Time.timeElapsed + dt
    
    local duration = Time.isDay() and Time.dayDuration or Time.nightDuration
    
    if Time.timeElapsed >= duration then
        Time.toggle()
    end
end

return Time