local Player = require "player"
local GameLog = require "gamelog"
local Map = require "map"
local Objects = require "objects"
local Camera = require "camera"
local Menu = require "menu"
local Assets = require "assets"
local Time = require "time"
local Combat = require "combat"
local ItemDB = require "item_db"

-- Current Game State
local gameState = "AWAKE"
local lastState = "AWAKE"

local lootList = {}
local lootIndex = 1

-- [NEW] Track current container being looted
local currentContainer = nil

-- [NEW] PUT menu state
local putMenuIndex = 1

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

    Map.updateFOV(Player.gridX, Player.gridY)
end

function setupTestWorld()
    Player.addItem("Starter Knife", "A rusty blade.", nil)
    
    -- [NEW] Spawn a test container with items
    Objects.spawnFromDB("footlocker", 15, 15)
    local locker = Objects.getObjectAt(15, 15)
    if locker and locker.isContainer then
        locker.addItem("stimpak")
        locker.addItem("pistol")
        locker.addItem("bandage")
        locker.addItem("whiskey")
    end
    
    GameLog.add("DEBUG MODE: Map Loaded.", { 1, 0, 0 })
end

function love.update(dt)
    if Combat.isActive then
        if gameState == "AWAKE" then
            gameState = "COMBAT"
        end
    else
        if gameState == "COMBAT" or gameState == "TARGETING" then
            gameState = "AWAKE"
        end
    end

    if gameState == "COMBAT" then
        Player.update(dt)
        
        local currentActor = Combat.turnQueue[Combat.turnIndex]
        if currentActor and not currentActor.isPlayer then
            currentActor.aiTimer = (currentActor.aiTimer or 0) + dt
            if currentActor.aiTimer > 1 then
                currentActor.aiTimer = 0
                Combat.endTurn()
            end
        end

    elseif gameState == "AWAKE" then
        Player.update(dt)
        Time.update(dt)
    end

    local px = (Player.gridX - 1) * Map.tileSize + (Map.tileSize / 2)
    local py = (Player.gridY - 1) * Map.tileSize + (Map.tileSize / 2)
    Camera.setFollowTarget(px, py)
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.1)

    Map.draw(-Camera.x, -Camera.y, Camera.scale, Camera.scale)

    Camera.set()
    Objects.draw()
    Player.draw()
    Camera.unset()

    love.graphics.setBlendMode("multiply", "premultiplied")
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1)

    GameLog.draw()

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: " .. Player.currentHealth, 10, 10)

    if gameState == "COMBAT" or gameState == "TARGETING" then
        love.graphics.setColor(0, 1, 0)
        love.graphics.print("STAMINA: " .. Player.currentStamina .. " / " .. Player.maxStamina, 10, 30)
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
    elseif gameState == "CONTAINER_PUT" then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(">> PUT MODE: Select item to store <<", 10, 70)
        love.graphics.setColor(1, 1, 1)
    end

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
        love.graphics.rectangle("fill", screenX, screenY, 150, #lootList * 20 + 50)
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("line", screenX, screenY, 150, #lootList * 20 + 50)

        -- [NEW] Show container name if looting a container
        if currentContainer then
            love.graphics.setColor(1, 1, 0)
            love.graphics.print(currentContainer.name, screenX + 5, screenY + 5)
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("[E]Take [R]Put", screenX + 5, screenY + 20)
            love.graphics.setColor(0, 1, 0)
        end

        for i, obj in ipairs(lootList) do
            local yOffset = currentContainer and 40 or 5
            if i == lootIndex then
                love.graphics.setColor(1, 1, 0)
                love.graphics.print("> " .. obj.name, screenX + 5, screenY + yOffset + ((i - 1) * 20))
            else
                love.graphics.setColor(0, 1, 0)
                love.graphics.print("  " .. obj.name, screenX + 5, screenY + yOffset + ((i - 1) * 20))
            end
        end
        love.graphics.setColor(1, 1, 1)
    end

    -- [NEW] Draw PUT menu overlay
    if gameState == "CONTAINER_PUT" then
        local screenX = ((Player.gridX * Map.tileSize) - Camera.x) * Camera.scale + 200
        local screenY = ((Player.gridY * Map.tileSize) - Camera.y) * Camera.scale - 20

        local itemCount = math.max(1, #Player.inventory)
        
        love.graphics.setColor(0, 0, 0, 0.95)
        love.graphics.rectangle("fill", screenX, screenY, 180, itemCount * 20 + 50)
        love.graphics.setColor(1, 1, 0)
        love.graphics.rectangle("line", screenX, screenY, 180, itemCount * 20 + 50)
        
        love.graphics.print("YOUR INVENTORY", screenX + 5, screenY + 5)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("[E]Put [ESC]Cancel", screenX + 5, screenY + 20)
        
        if #Player.inventory == 0 then
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print("(Empty)", screenX + 5, screenY + 40)
        else
            for i, item in ipairs(Player.inventory) do
                local yPos = screenY + 40 + ((i - 1) * 20)
                if i == putMenuIndex then
                    love.graphics.setColor(1, 1, 0)
                    love.graphics.print("> " .. item.name, screenX + 5, yPos)
                else
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print("  " .. item.name, screenX + 5, yPos)
                end
            end
        end
        love.graphics.setColor(1, 1, 1)
    end

    love.graphics.print("Time: " .. Time.currentTime:upper(), 300, 10)
end

-- [NEW] Open a container and populate loot list
function openContainer(container)
    if not container.isContainer then return end
    
    if container.isEmpty() then
        GameLog.add("The " .. container.name .. " is empty.", {0.5, 0.5, 0.5})
        gameState = lastState
        return
    end
    
    -- Convert item IDs to display objects
    lootList = {}
    for i, itemId in ipairs(container.inventory) do
        local itemDef = ItemDB.definitions[itemId]
        if itemDef then
            -- Create a proper item object with all properties
            local item = {
                id = itemId,
                name = itemDef.name,
                description = itemDef.description or "No description.",
                weight = itemDef.weight or 0,
                actionLabel = itemDef.actionLabel,
                onUse = itemDef.onUse,
                symbol = itemDef.symbol or "?",
                color = itemDef.color or {1, 1, 1},
                containerIndex = i -- Track position in container
            }
            table.insert(lootList, item)
        else
            print("Warning: Item ID '" .. itemId .. "' not found in ItemDB")
        end
    end
    
    if #lootList == 0 then
        GameLog.add("The " .. container.name .. " is empty.", {0.5, 0.5, 0.5})
        gameState = lastState
        return
    end
    
    currentContainer = container
    lootIndex = 1
    gameState = "LOOTING"
    GameLog.add("Opened " .. container.name .. ".", {0, 1, 1})
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
        
        -- [NEW] Check if it's a container
        if obj.isContainer then
            openContainer(obj)
        else
            if obj.onInteract then obj.onInteract() end
            if not obj.isBlocking then Objects.remove(obj) end
            gameState = lastState
        end
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
        if gameState == "MENU" or gameState == "LOOKING" or gameState == "INTERACT_QUERY" or gameState == "LOOTING" or gameState == "TARGETING" or gameState == "CONTAINER_PUT" then
            -- [NEW] If in PUT mode, go back to LOOTING
            if gameState == "CONTAINER_PUT" then
                gameState = "LOOTING"
                return
            end
            
            gameState = lastState
            -- Clear container reference when closing
            if gameState ~= "LOOTING" then
                currentContainer = nil
            end
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

    if gameState == "LOOKING" then
        if key == "l" or key == "x" then gameState = lastState; GameLog.add("Cancelled looking."); return end
        if key == "space" or key == "return" or key == "e" then handleLookCommand(0, 0); return end
        if key == "up" or key == "w" then handleLookCommand(0, -1) end
        if key == "down" or key == "s" then handleLookCommand(0, 1) end
        if key == "left" or key == "a" then handleLookCommand(-1, 0) end
        if key == "right" or key == "d" then handleLookCommand(1, 0) end
        return
    end

    if gameState == "COMBAT" then
        local currentActor = Combat.turnQueue[Combat.turnIndex]
        
        if currentActor and currentActor.isPlayer then
            if key == "up" or key == "w" then
                Player.attemptMove(0, -1)
            elseif key == "down" or key == "s" then
                Player.attemptMove(0, 1)
            elseif key == "left" or key == "a" then
                Player.attemptMove(-1, 0)
            elseif key == "right" or key == "d" then
                Player.attemptMove(1, 0)
            end
            
            if key == "space" then
                GameLog.add("You catch your breath.", {0.5, 0.5, 1})
                Combat.endTurn()
            end

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

    if gameState == "TARGETING" then
        if key == "up" or key == "w" then
            targetIndex = targetIndex - 1
            if targetIndex < 1 then targetIndex = #targetList end
        elseif key == "down" or key == "s" then
            targetIndex = targetIndex + 1
            if targetIndex > #targetList then targetIndex = 1 end
        elseif key == "space" or key == "return" or key == "f" then
            local target = targetList[targetIndex]
            gameState = "COMBAT"
            
            Combat.performAction(3, function()
                local damage = 5
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
                currentContainer = nil -- [NEW] Not a container
                gameState = "LOOTING"
                GameLog.add("Multiple items here.", { 1, 1, 0 })
                return
            elseif #itemsUnderfoot == 1 then
                local obj = itemsUnderfoot[1]
                
                -- [NEW] Check if it's a container
                if obj.isContainer then
                    openContainer(obj)
                    return
                end
                
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

    -- [UPDATED] Looting with container support - TAKE and PUT
    if gameState == "LOOTING" then
        if key == "escape" or key == "x" or key == "tab" then 
            gameState = lastState
            lootList = {}
            currentContainer = nil
            return 
        end
        
        if key == "up" or key == "w" then 
            lootIndex = lootIndex - 1
            if lootIndex < 1 then lootIndex = #lootList end 
        end
        
        if key == "down" or key == "s" then 
            lootIndex = lootIndex + 1
            if lootIndex > #lootList then lootIndex = 1 end 
        end

        -- [NEW] TAKE from container (E or Space)
        if key == "space" or key == "return" or key == "e" then
            local obj = lootList[lootIndex]
            local shouldRemove = false
            
            if currentContainer then
                -- TAKE: Add to player inventory
                local success = Player.addItem(
                    obj.id,
                    obj.name,
                    obj.description,
                    obj.weight,
                    obj.actionLabel,
                    obj.onUse
                )
                
                if success then
                    GameLog.add("Took " .. obj.name .. ".", {0, 1, 0})
                    -- Remove from container's inventory
                    for i, itemId in ipairs(currentContainer.inventory) do
                        if itemId == obj.id then
                            table.remove(currentContainer.inventory, i)
                            break
                        end
                    end
                    shouldRemove = true
                else
                    GameLog.add("Inventory Full!", {1, 0, 0})
                end
            else
                -- Regular ground item interaction
                if obj and obj.onInteract then 
                    shouldRemove = obj.onInteract() 
                else
                    GameLog.add("Can't interact with " .. (obj.name or "that") .. ".", {1, 0, 0})
                end
            end
            
            if shouldRemove then
                if not currentContainer then
                    Objects.remove(obj)
                end
                table.remove(lootList, lootIndex)
            end
            
            if #lootList == 0 then 
                gameState = lastState
                currentContainer = nil
            elseif lootIndex > #lootList then 
                lootIndex = #lootList 
            end
        end
        
        -- [NEW] PUT into container (R key)
        if key == "r" and currentContainer then
            -- Switch to PUT mode
            gameState = "CONTAINER_PUT"
            putMenuIndex = 1
            GameLog.add("Select item to put in " .. currentContainer.name, {1, 1, 0})
        end
        
        return
    end
    
    -- [NEW] CONTAINER_PUT state - Player choosing item to store
    if gameState == "CONTAINER_PUT" then
        if #Player.inventory == 0 then
            GameLog.add("You have no items to put.", {1, 0, 0})
            gameState = "LOOTING"
            return
        end
        
        if key == "up" or key == "w" then
            putMenuIndex = putMenuIndex - 1
            if putMenuIndex < 1 then putMenuIndex = #Player.inventory end
        elseif key == "down" or key == "s" then
            putMenuIndex = putMenuIndex + 1
            if putMenuIndex > #Player.inventory then putMenuIndex = 1 end
        elseif key == "e" or key == "space" or key == "return" then
            -- Put the selected item into the container
            local item = Player.inventory[putMenuIndex]
            
            if item and currentContainer then
                -- Add item ID to container
                currentContainer.addItem(item.id)
                
                GameLog.add("Put " .. item.name .. " in " .. currentContainer.name .. ".", {0, 1, 1})
                
                -- Remove from player inventory
                Player.removeItem(putMenuIndex)
                
                -- Adjust putMenuIndex if needed
                if putMenuIndex > #Player.inventory then
                    putMenuIndex = math.max(1, #Player.inventory)
                end
                
                -- Return to looting and refresh the container view
                gameState = "LOOTING"
                openContainer(currentContainer)
            end
        end
        return
    end
end

function love.resize(w, h)
    Map.resize(w, h)
end