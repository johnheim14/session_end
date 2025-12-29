local Player = require "player"
local GameLog = require "gamelog"
local Map = require "map"
local Objects = require "objects"
local Camera = require "camera"
local Menu = require "menu"
local Assets = require "assets" -- [Req 1] Import the assets script
local Time = require "time"

-- Current Game State
local gameState = "AWAKE"
local lastState = "AWAKE"

local lootList = {} -- Stores the items currently in the pile
local lootIndex = 1 -- Which item is currently selected

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.keyboard.setKeyRepeat(true)

    Assets.load() -- [Req 2] LOAD THE IMAGES FIRST!
    Map.load()
    Time.setTime(Time.DAY)
    Player.load()

    --setupDreamSequence()
    setupTestWorld()

    -- [NEW] Initialize FOV
    -- This ensures the screen isn't pitch black on start
    Map.updateFOV(Player.gridX, Player.gridY)
end

function setupTestWorld()
    -- Simulate Stats
    Player.stats = { strength = 5, intelligence = 5, dexterity = 5, senses = 5, reflexes = 5, endurance = 5 }

    -- Player Inventory Test (Optional)
    Player.addItem("Starter Knife", "A rusty blade.", nil)

    GameLog.add("DEBUG MODE: Map Loaded.", { 1, 0, 0 })

    -- NO MANUAL SPAWNS NEEDED!
    -- The Map.load() function triggered above already read Tiled and placed the items.
end

function setupDreamSequence()
    GameLog.add("DREAM SEQUENCE...", { 1, 0, 1 })

    -- 1. Medkit (Consumable Item)
    Objects.spawn("Medkit", 3, 5, "M", { 1, 0, 0 }, false, function()
        -- Instead of using it instantly, we ADD it to inventory
        Player.addItem("Medkit", "Restores 10 HP. Single use.", function()
            Player.currentHealth = math.min(Player.currentHealth + 10, Player.maxHealth)
            GameLog.add("Used Medkit. Health is now " .. Player.currentHealth, { 0, 1, 0 })
        end)

        GameLog.add("Picked up Medkit.", { 0, 1, 0 })
    end)

    -- 2. Strange Pill (New Test Item)
    Objects.spawn("Strange Pill", 5, 5, "P", { 0, 0, 1 }, false, function()
        Player.addItem("Strange Pill", "A mysterious blue pill. Reduces Stress.", function()
            Player.currentStress = math.max(0, Player.currentStress - 20)
            GameLog.add("You feel calmer. Stress -20.", { 0, 0.5, 1 })
        end)
        GameLog.add("Picked up Strange Pill.", { 0, 1, 1 })
    end)

    -- 3. Guitar (Still a 'Tag' item, maybe keeps instant effect?)
    -- Or we can make it an inventory item you "Use" to learn the skill.
    Objects.spawn("Old Guitar", 7, 5, "G", { 1, 0.5, 0 }, false, function()
        Player.addItem("Old Guitar", "Use to practice and gain the Performance skill.", function()
            table.insert(Player.taggedSkills, "Performance")
            GameLog.add("You played a tune. Learned: Performance!", { 1, 0.5, 0 })
        end)
        GameLog.add("Picked up Guitar.", { 1, 1, 0 })
    end)
end

function transitionToShelter()
    gameState = "SHELTER"
    Objects.clear()
    Player.gridX = 2; Player.gridY = 2
    GameLog.add("SHELTER: Train your stats.", { 1, 1, 0 })

    Objects.spawn("Bench Press", 4, 4, "S", { 0.8, 0.2, 0.2 }, true, function()
        Player.trainStat("strength")
    end)

    Objects.spawn("Chess Board", 6, 4, "I", { 0.2, 0.2, 0.8 }, true, function()
        Player.trainStat("intelligence")
    end)

    Objects.spawn("Treadmill", 8, 4, "E", { 0.2, 0.8, 0.2 }, true, function()
        Player.trainStat("endurance")
    end)

    Objects.spawn("Bunker Door", 10, 2, "D", { 0.5, 0.5, 0.5 }, true, function()
        if Player.statPoints == 0 then
            gameState = "AWAKE"
            GameLog.add("You leave the shelter...", { 1, 0, 0 })
            Objects.clear()
        else
            GameLog.add("Spend all points first!", { 1, 0, 0 })
        end
    end)
end

function handleInteractCommand(dx, dy)
    local targetX = Player.gridX + dx
    local targetY = Player.gridY + dy

    -- Get ALL objects at the target tile
    local items = Objects.getAllAt(targetX, targetY)

    if #items == 0 then
        GameLog.add("Nothing there.", { 0.5, 0.5, 0.5 })
        gameState = lastState
    elseif #items == 1 then
        -- ONLY ONE ITEM: Immediate Interaction
        local obj = items[1]
        if obj.onInteract then obj.onInteract() end

        -- If it's not blocking (an item), remove it after use
        if not obj.isBlocking then Objects.remove(obj) end

        gameState = lastState
    else
        -- MULTIPLE ITEMS: Open Loot Menu
        lootList = items
        lootIndex = 1
        gameState = "LOOTING"
        GameLog.add("Multiple items detected.", { 1, 1, 0 })
    end
end

function love.update(dt)
    Player.update(dt) -- [NEW] Update player animation timer
    local px = (Player.gridX - 1) * Map.tileSize + (Map.tileSize / 2)
    local py = (Player.gridY - 1) * Map.tileSize + (Map.tileSize / 2)
    Camera.setFollowTarget(px, py)
    Time.update(dt)
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.1)

    -- 1. Draw World

    -- [UPDATED] Pass Camera.scale to STI to zoom the map tiles
    Map.draw(-Camera.x, -Camera.y, Camera.scale, Camera.scale)

    -- [UPDATED] Draw Objects & Player (Use Camera.set for these)
    Camera.set()
    -- Objects and Player draw at their World Coordinates,
    -- so we need the camera transform active to shift them to Screen Coordinates.
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

    -- (Keep the rest of your UI drawing code exactly the same)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: " .. Player.currentHealth .. " | Stress: " .. Player.currentStress, 10, 10)

    if gameState == "MENU" then
        Menu.draw()
    elseif gameState == "LOOKING" then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(">> LOOK MODE: Press a direction <<", 10, 30)
        love.graphics.setColor(1, 1, 1)
    elseif gameState == "SHELTER" then
        love.graphics.print("Points: " .. Player.statPoints, 10, 30)
    elseif gameState == "INTERACT_QUERY" then
        love.graphics.setColor(0, 1, 0)
        love.graphics.print(">> INTERACT: Press Direction (WASD) <<", 10, 30)
        love.graphics.setColor(1, 1, 1)
    end

    if gameState == "LOOTING" then
        -- Draw a small window near the player
        -- [FIX] Adjust menu position based on scale or keep it screen relative
        -- For now, we draw it relative to player but in screen coordinates manually?
        -- Actually, since we are outside Camera.set(), we need screen coordinates.
        -- We can use Camera.x/y to convert player grid to screen.

        local screenX = ((Player.gridX * Map.tileSize) - Camera.x) * Camera.scale + 20
        local screenY = ((Player.gridY * Map.tileSize) - Camera.y) * Camera.scale - 20

        -- Background Box
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", screenX, screenY, 150, #lootList * 20 + 10)
        love.graphics.setColor(0, 1, 0) -- Green Border
        love.graphics.rectangle("line", screenX, screenY, 150, #lootList * 20 + 10)

        -- List Items
        for i, obj in ipairs(lootList) do
            if i == lootIndex then
                love.graphics.setColor(1, 1, 0) -- Yellow for selected
                love.graphics.print("> " .. obj.name, screenX + 5, screenY + 5 + ((i - 1) * 20))
            else
                love.graphics.setColor(0, 1, 0) -- Green for others
                love.graphics.print("  " .. obj.name, screenX + 5, screenY + 5 + ((i - 1) * 20))
            end
        end

        love.graphics.setColor(1, 1, 1) -- Reset
    end

    love.graphics.print("Time: " .. Time.currentTime:upper(), 10, 50)
end

function handleLookCommand(dx, dy)
    local targetX = Player.gridX + dx
    local targetY = Player.gridY + dy

    -- 1. Check Objects (Get ALL of them)
    local allObjects = Objects.getAllAt(targetX, targetY)

    if #allObjects > 0 then
        -- Build the description string
        local msg = "You see: " .. allObjects[1].name

        if #allObjects == 2 then
            -- Two items: "You see: Medkit, Rifle"
            msg = msg .. ", " .. allObjects[2].name
        elseif #allObjects > 2 then
            -- Many items: "You see: Medkit, Rifle, and 3 more"
            local othersCount = #allObjects - 2
            msg = msg .. ", " .. allObjects[2].name .. ", and " .. othersCount .. " more"
        end

        GameLog.add(msg, { 0, 1, 1 }) -- Cyan text

        -- 2. Check Map (if no objects)
    else
        if Map.isBlocked(targetX, targetY) then
            GameLog.add("You see a wall.", { 0.5, 0.5, 0.5 })
        else
            GameLog.add("You see empty floor.", { 0.3, 0.3, 0.3 })
        end
    end

    gameState = lastState -- Return to normal game
end

function love.keypressed(key)
    if key == "escape" then
        if gameState == "MENU" or gameState == "LOOKING" or gameState == "INTERACT_QUERY" or gameState == "LOOTING" then
            gameState = lastState
            return
        else
            love.event.quit()
        end
    end

    -- DEBUG Time toggle
    if key == "t" then
        Time.toggle()
        return
    end

    if gameState == "INTERACT_QUERY" then
        if key == "x" or key == "space" then
            gameState = lastState
            GameLog.add("Cancelled interaction.")
            return
        end
        if key == "up" or key == "w" or key == "kp8" then handleInteractCommand(0, -1) end
        if key == "down" or key == "s" or key == "kp2" then handleInteractCommand(0, 1) end
        if key == "left" or key == "a" or key == "kp4" then handleInteractCommand(-1, 0) end
        if key == "right" or key == "d" or key == "kp6" then handleInteractCommand(1, 0) end
        return
    end

    if gameState == "MENU" then
        if key == "tab" or key == "m" then gameState = lastState else Menu.keypressed(key) end
        return
    end

    -- STATE: LOOKING
    if gameState == "LOOKING" then
        if key == "l" or key == "x" then
            gameState = lastState
            GameLog.add("Cancelled looking.")
            return
        end

        -- [NEW] Look at self / underfoot
        if key == "space" or key == "return" or key == "e" then
            handleLookCommand(0, 0)
            return
        end

        -- Directional Looking
        if key == "up" or key == "w" or key == "kp8" then handleLookCommand(0, -1) end
        if key == "down" or key == "s" or key == "kp2" then handleLookCommand(0, 1) end
        if key == "left" or key == "a" or key == "kp4" then handleLookCommand(-1, 0) end
        if key == "right" or key == "d" or key == "kp6" then handleLookCommand(1, 0) end
        if key == "kp7" then handleLookCommand(-1, -1) end
        if key == "kp9" then handleLookCommand(1, -1) end
        if key == "kp1" then handleLookCommand(-1, 1) end
        if key == "kp3" then handleLookCommand(1, 1) end
        return
    end

    if gameState == "AWAKE" or gameState == "SHELTER" or gameState == "DREAM" then
        if key == "tab" or key == "m" then
            lastState = gameState; gameState = "MENU"; return
        end
        if key == "l" or key == "lctrl" then
            lastState = gameState; gameState = "LOOKING"; GameLog.add("Look where?", { 1, 1, 0 }); return
        end

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
                -- SINGLE ITEM INTERACTION
                local obj = itemsUnderfoot[1]

                if obj.onInteract then
                    -- [UPDATED] We capture the return value!
                    local shouldRemove = obj.onInteract()

                    -- Only remove if the logic said so (e.g. pickup successful)
                    if shouldRemove then
                        Objects.remove(obj)
                    end
                end
                return
            end

            -- Nothing underfoot...
            lastState = gameState
            gameState = "INTERACT_QUERY"
            GameLog.add("Interact where? (WASD)", { 0, 1, 0 })
            return
        end
    end
    -- STATE: LOOTING
    if gameState == "LOOTING" then
        if key == "escape" or key == "x" or key == "tab" then
            gameState = lastState
            lootList = {}
            return
        end

        -- Navigation
        if key == "up" or key == "w" then
            lootIndex = lootIndex - 1
            if lootIndex < 1 then lootIndex = #lootList end
        end
        if key == "down" or key == "s" then
            lootIndex = lootIndex + 1
            if lootIndex > #lootList then lootIndex = 1 end
        end

        -- Taking an Item
        if key == "space" or key == "return" or key == "e" then
            local obj = lootList[lootIndex]

            -- [UPDATED] Same logic here
            local shouldRemove = false
            if obj.onInteract then
                shouldRemove = obj.onInteract()
            end

            if shouldRemove then
                Objects.remove(obj)               -- Remove from world
                table.remove(lootList, lootIndex) -- Remove from menu
            end

            -- Close menu if empty
            if #lootList == 0 then
                gameState = lastState
            elseif lootIndex > #lootList then
                lootIndex = #lootList
            end
        end
        return
    end
end

-- [NEW] Handle Window Resizing
function love.resize(w, h)
    Map.resize(w, h)
end
