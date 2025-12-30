local Player = require "player"
local GameLog = require "gamelog"
local Map = require "map"
local Objects = require "objects"
local Camera = require "camera"
local Menu = require "menu"
local Assets = require "assets"
local Time = require "time"
local Combat = require "combat"

-- Current Game State
local gameState = "AWAKE"
local lastState = "AWAKE"

local lootList = {} -- Stores the items currently in the pile
local lootIndex = 1 -- Which item is currently selected

-- Targeting State Variables
local targetList = {}
local targetIndex = 1

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.keyboard.setKeyRepeat(true)

    Assets.load() 
    Map.load()
    Time.setTime(Time.DAY)
    Player.load()
    Player.isPlayer = true
    setupTestWorld()

    -- Initialize FOV
    Map.updateFOV(Player.gridX, Player.gridY)
end

function setupTestWorld()
    Player.addItem("Starter Knife", "A rusty blade.", nil)
    GameLog.add("DEBUG MODE: Map Loaded.", { 1, 0, 0 })
end

function love.update(dt)
    -- [FIX] SYNC GAME STATE WITH COMBAT STATUS
    -- If Player.lua starts combat, we detect it here and force the state change.
    if Combat.isActive then
        -- If we are running around (AWAKE), switch to COMBAT immediately
        if gameState == "AWAKE" then
            gameState = "COMBAT"
        end
    else
        -- If combat ended, ensure we aren't stuck in COMBAT state
        if gameState == "COMBAT" or gameState == "TARGETING" then
            gameState = "AWAKE"
        end
    end

    if gameState == "COMBAT" then
        -- 1. COMBAT LOGIC
        Player.update(dt) -- Animate player
        
        -- If it's the Enemy's turn, run their AI
        local currentActor = Combat.turnQueue[Combat.turnIndex]
        if currentActor and not currentActor.isPlayer then
            -- Simple AI: Wait 1 second then end turn (placeholder)
            currentActor.aiTimer = (currentActor.aiTimer or 0) + dt
            if currentActor.aiTimer > 1 then
                currentActor.aiTimer = 0
                Combat.endTurn()
            end
        end

    elseif gameState == "AWAKE" then
        -- 2. EXPLORATION LOGIC
        Player.update(dt)
        Time.update(dt) 
        
        -- TEST KEY: Press 'K' to force start combat for testing
        if love.keyboard.isDown("k") and not Combat.isActive then
            local dummyEnemy = { 
                name = "RadRoach", 
                maxStamina = 3, 
                currentStamina = 3,
                maxHP = 20, 
                currentHP = 20,
                stats = { reflexes = 2 },
                isEnemy = true
            }
            Combat.start(Player, { dummyEnemy })
            -- State will sync automatically next frame due to the check at top
        end
    end

    -- [FIX] CAMERA FOLLOW LOGIC
    -- Calculate target position (center of player tile)
    local px = (Player.gridX - 1) * Map.tileSize + (Map.tileSize / 2)
    local py = (Player.gridY - 1) * Map.tileSize + (Map.tileSize / 2)
    Camera.setFollowTarget(px, py)
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.1)

    -- 1. Draw World
    Map.draw(-Camera.x, -Camera.y, Camera.scale, Camera.scale)

    Camera.set()
    Objects.draw()
    Player.draw()
    Camera.unset()

    -- Lighting Overlay
    love.graphics.setBlendMode("multiply", "premultiplied")
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1)

    -- 2. Draw UI
    GameLog.draw()

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: " .. Player.currentHealth, 10, 10)

    -- DRAW STAMINA / STATE
    if gameState == "COMBAT" or gameState == "TARGETING" then
        love.graphics.setColor(0, 1, 0) -- Green
        love.graphics.print("STAMINA: " .. Player.currentStamina .. " / " .. Player.maxStamina, 10, 30)
        -- Helpful tip for passing turn
        love.graphics.print("COMBAT: [F] Shoot, [SPACE] Pass Turn", 10, 50)
    else
        love.graphics.print("Stress: " .. Player.currentStress, 10, 30)
    end

    if gameState == "MENU" then
        Menu.draw()
    elseif gameState == "LOOKING" then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(">> LOOK MODE: Press a direction <<", 10, 70)
        love.graphics.setColor(1, 1, 1)
    elseif gameState == "INTERACT_QUERY" then
        love.graphics.setColor(0, 1, 0)
        love.graphics.print(">> INTERACT: Press Direction (WASD) <<", 10, 70)
        love.graphics.setColor(1, 1, 1)
    end

    -- DRAW TARGETING MENU
    if gameState == "TARGETING" then
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", 50, 80, 200, 200)
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("line", 50, 80, 200, 200)
        
        love.graphics.print("SELECT TARGET:", 60, 90)
        
        for i, enemy in ipairs(targetList) do
            local y = 120 + (i-1)*20
            local prefix = (i == targetIndex) and "> " or "  "
            love.graphics.setColor(1, 1, 1)
            if i == targetIndex then love.graphics.setColor(1, 1, 0) end
            love.graphics.print(prefix .. enemy.name .. " (" .. enemy.currentHP .. " HP)", 60, y)
        end
        love.graphics.setColor(1, 1, 1)
    end

    if gameState == "LOOTING" then
        local screenX = ((Player.gridX * Map.tileSize) - Camera.x) * Camera.scale + 20
        local screenY = ((Player.gridY * Map.tileSize) - Camera.y) * Camera.scale - 20

        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", screenX, screenY, 150, #lootList * 20 + 10)
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("line", screenX, screenY, 150, #lootList * 20 + 10)

        for i, obj in ipairs(lootList) do
            if i == lootIndex then
                love.graphics.setColor(1, 1, 0)
                love.graphics.print("> " .. obj.name, screenX + 5, screenY + 5 + ((i - 1) * 20))
            else
                love.graphics.setColor(0, 1, 0)
                love.graphics.print("  " .. obj.name, screenX + 5, screenY + 5 + ((i - 1) * 20))
            end
        end
        love.graphics.setColor(1, 1, 1)
    end

    love.graphics.print("Time: " .. Time.currentTime:upper(), 300, 10)
end

function handleInteractCommand(dx, dy)
    local targetX = Player.gridX + dx
    local targetY = Player.gridY + dy
    local items = Objects.getAllAt(targetX, targetY)

    if #items == 0 then
        GameLog.add("Nothing there.", { 0.5, 0.5, 0.5 })
        gameState = lastState
    elseif #items == 1 then
        local obj = items[1]
        if obj.onInteract then obj.onInteract() end
        if not obj.isBlocking then Objects.remove(obj) end
        gameState = lastState
    else
        lootList = items
        lootIndex = 1
        gameState = "LOOTING"
        GameLog.add("Multiple items detected.", { 1, 1, 0 })
    end
end

function handleLookCommand(dx, dy)
    local targetX = Player.gridX + dx
    local targetY = Player.gridY + dy
    local allObjects = Objects.getAllAt(targetX, targetY)

    if #allObjects > 0 then
        local msg = "You see: " .. allObjects[1].name
        if #allObjects == 2 then
            msg = msg .. ", " .. allObjects[2].name
        elseif #allObjects > 2 then
            local othersCount = #allObjects - 2
            msg = msg .. ", " .. allObjects[2].name .. ", and " .. othersCount .. " more"
        end
        GameLog.add(msg, { 0, 1, 1 })
    else
        if Map.isBlocked(targetX, targetY) then
            GameLog.add("You see a wall.", { 0.5, 0.5, 0.5 })
        else
            GameLog.add("You see empty floor.", { 0.3, 0.3, 0.3 })
        end
    end
    gameState = lastState
end

function love.keypressed(key)
    if key == "escape" then
        if gameState == "MENU" or gameState == "LOOKING" or gameState == "INTERACT_QUERY" or gameState == "LOOTING" or gameState == "TARGETING" then
            gameState = lastState
            return
        else
            love.event.quit()
        end
    end

    if key == "t" then Time.toggle(); return end

    if gameState == "INTERACT_QUERY" then
        if key == "x" or key == "space" then gameState = lastState; GameLog.add("Cancelled interaction."); return end
        if key == "up" or key == "w" then handleInteractCommand(0, -1) end
        if key == "down" or key == "s" then handleInteractCommand(0, 1) end
        if key == "left" or key == "a" then handleInteractCommand(-1, 0) end
        if key == "right" or key == "d" then handleInteractCommand(1, 0) end
        return
    end

    if gameState == "MENU" then
        if key == "tab" or key == "m" then gameState = lastState else Menu.keypressed(key) end
        return
    end

    -- STATE: LOOKING
    if gameState == "LOOKING" then
        if key == "l" or key == "x" then gameState = lastState; GameLog.add("Cancelled looking."); return end
        if key == "space" or key == "return" or key == "e" then handleLookCommand(0, 0); return end
        if key == "up" or key == "w" then handleLookCommand(0, -1) end
        if key == "down" or key == "s" then handleLookCommand(0, 1) end
        if key == "left" or key == "a" then handleLookCommand(-1, 0) end
        if key == "right" or key == "d" then handleLookCommand(1, 0) end
        return
    end

    -- STATE: COMBAT
    if gameState == "COMBAT" then
        local currentActor = Combat.turnQueue[Combat.turnIndex]
        
        -- ONLY CONTROL IF IT IS PLAYER'S TURN
        if currentActor and currentActor.isPlayer then
            -- MOVE: Costs handled inside Player.attemptMove now
            if key == "up" or key == "w" then
                Player.attemptMove(0, -1)
            elseif key == "down" or key == "s" then
                Player.attemptMove(0, 1)
            elseif key == "left" or key == "a" then
                Player.attemptMove(-1, 0)
            elseif key == "right" or key == "d" then
                Player.attemptMove(1, 0)
            end
            
            -- SKIP TURN / WAIT
            if key == "space" then
                GameLog.add("You catch your breath.", {0.5, 0.5, 1})
                Combat.endTurn()
            end

            -- RANGED TRIGGER
            if key == "f" then
                targetList = {}
                for _, actor in ipairs(Combat.turnQueue) do
                    if actor.isEnemy then table.insert(targetList, actor) end
                end
                
                if #targetList > 0 then
                    lastState = "COMBAT"
                    gameState = "TARGETING"
                    targetIndex = 1
                    GameLog.add("Select Target...", {1, 1, 0})
                else
                    GameLog.add("No targets!", {0.5, 0.5, 0.5})
                end
            end
        end
        return
    end

    -- STATE: TARGETING
    if gameState == "TARGETING" then
        if key == "up" or key == "w" then
            targetIndex = targetIndex - 1
            if targetIndex < 1 then targetIndex = #targetList end
        elseif key == "down" or key == "s" then
            targetIndex = targetIndex + 1
            if targetIndex > #targetList then targetIndex = 1 end
        elseif key == "space" or key == "return" or key == "f" then
            -- FIRE!
            local target = targetList[targetIndex]
            gameState = "COMBAT"
            
            Combat.performAction(3, function() -- Costs 3 Stamina
                local damage = 5 -- Pistol Damage
                target.currentHP = target.currentHP - damage
                GameLog.add("You shot " .. target.name .. " for " .. damage .. " dmg!", {1, 0.5, 0})
                
                if target.currentHP <= 0 then
                    GameLog.add(target.name .. " dies.", {1, 0.5, 0})
                    Objects.remove(target)
                    Combat.removeFromQueue(target)
                end
            end)
        end
        return
    end

    -- STATE: AWAKE
    if gameState == "AWAKE" then
        if key == "tab" or key == "m" then lastState = gameState; gameState = "MENU"; return end
        if key == "l" or key == "lctrl" then lastState = gameState; gameState = "LOOKING"; GameLog.add("Look where? (WASD)", { 1, 1, 0 }); return end

        if key == "up" or key == "w" then Player.attemptMove(0, -1) end
        if key == "down" or key == "s" then Player.attemptMove(0, 1) end
        if key == "left" or key == "a" then Player.attemptMove(-1, 0) end
        if key == "right" or key == "d" then Player.attemptMove(1, 0) end

        if key == "space" or key == "return" or key == "e" then
            local itemsUnderfoot = Objects.getAllAt(Player.gridX, Player.gridY)
            if #itemsUnderfoot > 1 then
                lootList = itemsUnderfoot
                lootIndex = 1
                gameState = "LOOTING"
                GameLog.add("Multiple items here.", { 1, 1, 0 })
                return
            elseif #itemsUnderfoot == 1 then
                local obj = itemsUnderfoot[1]
                if obj.onInteract then
                    local shouldRemove = obj.onInteract()
                    if shouldRemove then Objects.remove(obj) end
                end
                return
            end
            lastState = gameState
            gameState = "INTERACT_QUERY"
            GameLog.add("Interact where? (WASD)", { 0, 1, 0 })
            return
        end
    end

    -- STATE: LOOTING
    if gameState == "LOOTING" then
        if key == "escape" or key == "x" or key == "tab" then gameState = lastState; lootList = {}; return end
        if key == "up" or key == "w" then lootIndex = lootIndex - 1; if lootIndex < 1 then lootIndex = #lootList end end
        if key == "down" or key == "s" then lootIndex = lootIndex + 1; if lootIndex > #lootList then lootIndex = 1 end end

        if key == "space" or key == "return" or key == "e" then
            local obj = lootList[lootIndex]
            local shouldRemove = false
            if obj.onInteract then shouldRemove = obj.onInteract() end
            if shouldRemove then Objects.remove(obj); table.remove(lootList, lootIndex) end
            if #lootList == 0 then gameState = lastState
            elseif lootIndex > #lootList then lootIndex = #lootList end
        end
        return
    end
end

function love.resize(w, h)
    Map.resize(w, h)
end