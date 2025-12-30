local GameLog = require "gamelog"

local Combat = {}

Combat.isActive = false
Combat.turnQueue = {}   -- List of all actors (Player + Enemies)
Combat.turnIndex = 1    -- Index of whose turn it is
Combat.turnCounter = 0

function Combat.start(player, enemies)
    Combat.isActive = true
    Combat.turnQueue = {}
    Combat.turnCounter = 1
    
    -- 1. Add Player
    table.insert(Combat.turnQueue, player)
    
    -- 2. Add Enemies
    for _, e in ipairs(enemies) do
        table.insert(Combat.turnQueue, e)
    end
    
    -- 3. Sort by Reflexes (Highest goes first)
    table.sort(Combat.turnQueue, function(a, b) 
        local reflexA = a.stats and a.stats.reflexes or 0
        local reflexB = b.stats and b.stats.reflexes or 0
        return reflexA > reflexB 
    end)
    
    GameLog.add("COMBAT STARTED!", {1, 0, 0})
    Combat.startTurn()
end

function Combat.startTurn()
    local actor = Combat.turnQueue[Combat.turnIndex]
    
    -- REPLENISH STAMINA
    if actor.isPlayer then
        -- Player uses the function we made
        local Player = require "player"
        Player.refreshStamina()
        GameLog.add("Your Turn! Stamina: " .. Player.currentStamina .. "/" .. Player.maxStamina, {0, 1, 0})
    else
        -- Enemies: Give them a default amount if they don't have stats
        actor.currentStamina = actor.maxStamina or 5
        GameLog.add(actor.name .. " is preparing to act.", {1, 0.5, 0})
    end
end

function Combat.endTurn()
    -- Move to next actor
    Combat.turnIndex = Combat.turnIndex + 1
    
    -- If we reached the end of the list, loop back to start
    if Combat.turnIndex > #Combat.turnQueue then
        Combat.turnIndex = 1
        Combat.turnCounter = Combat.turnCounter + 1
    end
    
    Combat.startTurn()
end

-- Core Function: Check cost, deduct Stamina, perform action
function Combat.performAction(staminaCost, actionCallback)
    local actor = Combat.turnQueue[Combat.turnIndex]
    
    if actor.currentStamina >= staminaCost then
        actor.currentStamina = actor.currentStamina - staminaCost
        
        -- Run the actual code (move/attack)
        actionCallback()
        
        -- Feedback
        if actor.isPlayer then
            print("Action used " .. staminaCost .. " Stamina. Remaining: " .. actor.currentStamina)
        end
        
        -- Check if out of Stamina
        if actor.currentStamina <= 0 then
            -- AUTOMATICALLY END TURN FOR EVERYONE
            -- (If player runs out, turn ends. If they have 1 AP left, they stay in control)
            Combat.endTurn()
        end
    else
        if actor.isPlayer then
            GameLog.add("Not enough Stamina! Need " .. staminaCost, {1, 0, 0})
        end
    end
end

function Combat.removeFromQueue(entity)
    for i, actor in ipairs(Combat.turnQueue) do
        if actor == entity then
            table.remove(Combat.turnQueue, i)
            
            -- Adjust index if we removed someone before the current turn
            if i < Combat.turnIndex then
                Combat.turnIndex = Combat.turnIndex - 1
            end
            
            -- Victory Check: Only player left
            if #Combat.turnQueue <= 1 then 
                Combat.isActive = false
                require("gamelog").add("Victory!", {0, 1, 0})
            end
            return
        end
    end
end

return Combat