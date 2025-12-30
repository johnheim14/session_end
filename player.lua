local GameLog = require "gamelog"
local Map = require "map"
local Assets = require "assets"
local Player = {}

function Player.load()
    Player.gridX = 25
    Player.gridY = 25
    Player.name = "Wanderer"

    -- [FIXED] 1. DEFINE STATS FIRST so derived stats can use them
    Player.stats = { strength = 5, intelligence = 5, dexterity = 5, senses = 5, reflexes = 5, endurance = 5 }
    Player.statPoints = 0; Player.taggedSkills = {}

    -- 2. Derived Stats
    Player.maxHealth = 100; Player.currentHealth = 80
    Player.maxStress = 100; Player.currentStress = 10
    
    -- Now this works because Player.stats exists!
    Player.maxStamina = 5 + math.floor(Player.stats.endurance / 2)
    Player.currentStamina = Player.maxStamina

    Player.inventory = {}
    Player.maxWeight = 50.0; Player.currentWeight = 0.0

    -- === NEW ANIMATION VARIABLES ===
    Player.facing = "down" -- "up", "down", "left", "right"
    Player.animTimer = 0.0
    Player.isMoving = false
end

function Player.refreshStamina()
    Player.maxStamina = 5 + math.floor(Player.stats.endurance / 2)
    Player.currentStamina = Player.maxStamina
end

-- (Keep addItem, removeItem, dropItem exactly as they are)
function Player.addItem(id, name, description, weight, actionName, onUse)
    local w = weight or 0
    if Player.currentWeight + w > Player.maxWeight then return false end
    table.insert(Player.inventory,
        { id = id, name = name, description = description, weight = w, actionName = actionName, onUse = onUse })
    Player.currentWeight = Player.currentWeight + w
    return true
end

function Player.removeItem(index)
    local item = Player.inventory[index]
    if item then
        Player.currentWeight = Player.currentWeight - item.weight; table.remove(Player.inventory, index)
    end
end

function Player.dropItem(index)
    local item = Player.inventory[index]
    if not item then return end
    local ObjManager = require "objects"
    ObjManager.spawnFromDB(item.id, Player.gridX, Player.gridY)
    GameLog.add("Dropped " .. item.name .. ".", { 1, 1, 1 })
    Player.removeItem(index)
end

function Player.attemptMove(dx, dy)
    -- 1. UPDATE FACING DIRECTION
    if dy < 0 then
        Player.facing = "up"
    elseif dy > 0 then
        Player.facing = "down"
    elseif dx < 0 then
        Player.facing = "left"
    elseif dx > 0 then
        Player.facing = "right"
    end

    local targetX = Player.gridX + dx
    local targetY = Player.gridY + dy

    -- Map Collision
    if Map.isBlocked(targetX, targetY) then return end

    -- Object Collision & Interaction
    local ObjManager = require "objects"
    local Combat = require "combat"
    local allObjects = ObjManager.getAllAt(targetX, targetY)
    
    for _, obj in ipairs(allObjects) do
        if obj.isBlocking then
            -- [NEW] MELEE COMBAT LOGIC
            if obj.isEnemy then
                 -- 1. If in Combat, spend AP to attack
                 if Combat.isActive then
                     Combat.performAction(2, function() -- Costs 2 Stamina
                         local damage = math.max(1, Player.stats.strength) -- Simple Dmg Formula
                         obj.currentHP = obj.currentHP - damage
                         
                         GameLog.add("You hit " .. obj.name .. " for " .. damage .. " dmg!", {1, 0, 0})
                         
                         -- Death Check
                         if obj.currentHP <= 0 then
                             GameLog.add(obj.name .. " dies.", {1, 0.5, 0})
                             ObjManager.remove(obj)
                             Combat.removeFromQueue(obj)
                         end
                     end)
                 else
                     -- 2. If NOT in Combat, Start it!
                     Combat.start(Player, {obj}) -- Just start combat
                 end
                 return -- Stop movement
            end

            GameLog.add("Blocked by " .. obj.name .. "."); return
        end
    end

    -- DEFINE THE MOVE FUNCTION (To be called depending on cost)
    local function executeMove()
        Player.gridX = targetX
        Player.gridY = targetY

        -- [NEW] Update FOV on move
        Map.updateFOV(Player.gridX, Player.gridY)
        local Triggers = require "triggers"
        local trigger = Triggers.check(Player.gridX, Player.gridY)
        if trigger then
            Triggers.activate(trigger)
        end
        local items = {}
        for _, obj in ipairs(allObjects) do if not obj.isBlocking then table.insert(items, obj) end end

        if #items > 0 then
            -- Only show message if the items are actually visible!
            if Map.isVisible(targetX, targetY) then
                local msg = "You see a " .. items[1].name
                if #items > 1 then msg = msg .. " and others" end
                GameLog.add(msg .. ".", { 0, 1, 1 })
            end
        end
    end

    -- [FIX] CHARGE STAMINA FOR MOVEMENT ONLY IN COMBAT
    if Combat.isActive then
         Combat.performAction(1, executeMove)
    else
         executeMove()
    end
end

-- (Keep trainStat)
function Player.trainStat(statName) end

-- === NEW UPDATE FUNCTION ===
-- We need to update the animation timer every frame
function Player.update(dt)
    Player.animTimer = Player.animTimer + dt
end

-- === UPDATED DRAW FUNCTION ===
function Player.draw()
    local pixelX = (Player.gridX - 1) * Map.tileSize
    local pixelY = (Player.gridY - 1) * Map.tileSize

    -- Draw Color (White)
    love.graphics.setColor(1, 1, 1)

    -- 1. Determine which Sheet to use
    local spriteSheet = Assets.playerIdle
    local frames = Assets.player.idle[Player.facing]

    -- 2. Determine which Frame to use based on Timer
    local frameIndex = math.floor(Player.animTimer / 0.5) % #frames + 1
    local currentQuad = frames[frameIndex]

    -- 3. Draw
    love.graphics.draw(spriteSheet, currentQuad, pixelX, pixelY)
end

return Player