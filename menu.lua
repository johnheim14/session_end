local Player = require "player"
local GameLog = require "gamelog"

local Menu = {}

Menu.currentTab = 1
Menu.tabs = {"STATS", "INVENTORY", "MAP"}

-- Inventory State
Menu.selectionIndex = 1

-- Submenu State
Menu.isSubmenuOpen = false
Menu.submenuOptions = {} -- Will populate dynamically
Menu.submenuIndex = 1

function Menu.draw()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- 1. Main Background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", 50, 50, screenW - 100, screenH - 100)
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("line", 50, 50, screenW - 100, screenH - 100)
    
    -- 2. Tabs
    for i, tabName in ipairs(Menu.tabs) do
        local xPos = 60 + ((i-1) * 120)
        if i == Menu.currentTab then
            love.graphics.setColor(0, 1, 0); love.graphics.rectangle("fill", xPos, 50, 110, 30)
            love.graphics.setColor(0, 0, 0)
        else
            love.graphics.setColor(0, 0.3, 0); love.graphics.rectangle("fill", xPos, 50, 110, 30)
            love.graphics.setColor(0, 1, 0)
        end
        love.graphics.print(tabName, xPos + 10, 58)
    end
    
    -- 3. Content
    love.graphics.setColor(0, 1, 0)
    if Menu.currentTab == 1 then Menu.drawStatsContent()
    elseif Menu.currentTab == 2 then Menu.drawInventoryContent()
    elseif Menu.currentTab == 3 then love.graphics.print(">> MAP DATA CORRUPTED <<", 400, 300) end
    
    -- 4. Footer
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("[ARROWS] Navigate   [ENTER] Actions   [TAB] Close", 60, screenH - 80)
end

function Menu.drawStatsContent()
    -- (Keep your existing stats draw code)
    love.graphics.print("--- VITALS ---", 70, 120)
    love.graphics.print("NAME:   " .. Player.name, 70, 150)
    love.graphics.print("HEALTH: " .. Player.currentHealth .. " / " .. Player.maxHealth, 70, 170)
end

function Menu.drawInventoryContent()
    love.graphics.print("--- INVENTORY ---", 70, 100)
    love.graphics.print("WEIGHT: " .. Player.currentWeight .. " / " .. Player.maxWeight, 300, 100)
    
    if #Player.inventory == 0 then
        love.graphics.print("(Empty)", 70, 130)
        return
    end
    
    for i, item in ipairs(Player.inventory) do
        local y = 130 + ((i-1) * 20)
        if i == Menu.selectionIndex then
            love.graphics.print("> " .. item.name, 70, y)
            -- Details
            love.graphics.print("DETAILS:", 400, 120)
            love.graphics.print("Weight: " .. item.weight, 400, 140)
            love.graphics.printf(item.description or "No description available.", 400, 170, 300, "left")
        else
            love.graphics.print("  " .. item.name, 70, y)
        end
    end
    
    -- [NEW] Draw Submenu ON TOP if open
    if Menu.isSubmenuOpen then
        Menu.drawSubmenu()
    end
end

function Menu.drawSubmenu()
    -- Draw a small box near the selected item
    local x = 200
    local y = 130 + ((Menu.selectionIndex-1) * 20)
    local w, h = 120, (#Menu.submenuOptions * 20) + 10
    
    love.graphics.setColor(0, 0, 0, 1) -- Opaque black
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(1, 1, 1) -- White border
    love.graphics.rectangle("line", x, y, w, h)
    
    for i, option in ipairs(Menu.submenuOptions) do
        if i == Menu.submenuIndex then
            love.graphics.setColor(1, 1, 0) -- Selected Yellow
            love.graphics.print("> " .. option, x + 10, y + 5 + ((i-1)*20))
        else
            love.graphics.setColor(1, 1, 1) -- White
            love.graphics.print("  " .. option, x + 10, y + 5 + ((i-1)*20))
        end
    end
end

function Menu.keypressed(key)
    -- If Submenu is open, hijack controls
    if Menu.isSubmenuOpen then
        if key == "up" or key == "w" then
            Menu.submenuIndex = Menu.submenuIndex - 1
            if Menu.submenuIndex < 1 then Menu.submenuIndex = #Menu.submenuOptions end
        elseif key == "down" or key == "s" then
            Menu.submenuIndex = Menu.submenuIndex + 1
            if Menu.submenuIndex > #Menu.submenuOptions then Menu.submenuIndex = 1 end
        elseif key == "escape" or key == "x" then
            Menu.isSubmenuOpen = false -- Close submenu
        elseif key == "return" or key == "space" or key == "e" then
            Menu.executeSubmenuAction()
        end
        return -- Stop here so we don't scroll inventory behind the menu
    end

    -- Tab Switching
    if key == "right" or key == "d" then
        Menu.currentTab = Menu.currentTab + 1
        if Menu.currentTab > #Menu.tabs then Menu.currentTab = 1 end
    elseif key == "left" or key == "a" then
        Menu.currentTab = Menu.currentTab - 1
        if Menu.currentTab < 1 then Menu.currentTab = #Menu.tabs end
    end
    
    -- Inventory Navigation
    if Menu.currentTab == 2 and #Player.inventory > 0 then
        if key == "up" or key == "w" then
            Menu.selectionIndex = Menu.selectionIndex - 1
            if Menu.selectionIndex < 1 then Menu.selectionIndex = #Player.inventory end
        elseif key == "down" or key == "s" then
            Menu.selectionIndex = Menu.selectionIndex + 1
            if Menu.selectionIndex > #Player.inventory then Menu.selectionIndex = 1 end
        elseif key == "return" or key == "space" or key == "e" then
            -- Open Submenu
            local item = Player.inventory[Menu.selectionIndex]
            Menu.submenuOptions = {}
            
            -- Add "Use/Equip" option if valid
            if item.actionName then
                table.insert(Menu.submenuOptions, item.actionName) -- e.g. "CONSUME"
            else
                table.insert(Menu.submenuOptions, "USE")
            end
            
            table.insert(Menu.submenuOptions, "DROP")
            table.insert(Menu.submenuOptions, "CANCEL")
            
            Menu.submenuIndex = 1
            Menu.isSubmenuOpen = true
        end
    end
end

function Menu.executeSubmenuAction()
    local action = Menu.submenuOptions[Menu.submenuIndex]
    local item = Player.inventory[Menu.selectionIndex]
    
    if action == "DROP" then
        Player.dropItem(Menu.selectionIndex)
        Menu.isSubmenuOpen = false
        if Menu.selectionIndex > #Player.inventory then Menu.selectionIndex = math.max(1, #Player.inventory) end
        
    elseif action == "CANCEL" then
        Menu.isSubmenuOpen = false
        
    else -- USE / CONSUME / EQUIP
        if item.onUse then
            -- Execute the function
            item.onUse()
            
            -- Logic: If it was a consumable (like a Medkit), we should remove it.
            -- If it was a weapon (Equip), we keep it.
            -- For simplicity: If actionName is "CONSUME", remove it.
            if item.actionName == "CONSUME" then
                Player.removeItem(Menu.selectionIndex)
            end
        else
            GameLog.add("You can't use that.")
        end
        Menu.isSubmenuOpen = false
    end
end

return Menu