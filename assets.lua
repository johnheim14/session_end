local Assets = {}

Assets.quads = {}
Assets.player = {
    idle = {},
    walk = {}
}

function Assets.load()
    -- 1. Load Textures (Now in the assets/ folder)
    Assets.tileTexture = love.graphics.newImage("assets/tileset.png")
    Assets.playerIdle  = love.graphics.newImage("assets/Idle.png")
    Assets.playerWalk  = love.graphics.newImage("assets/Walk.png")
    
    -- 2. Define Item/Tile Quads (Existing code, just ensuring paths are correct)
    Assets.quads.player = love.graphics.newQuad(0, 0, 32, 32, Assets.tileTexture:getDimensions()) -- Fallback
    Assets.quads.item   = love.graphics.newQuad(32, 0, 32, 32, Assets.tileTexture:getDimensions())
    
    -- 3. Cut up the Player Sprites
    -- We map rows to directions: 1=Front(Down), 2=Back(Up), 3=Right, 4=Left
    local directions = {"down", "up", "right", "left"}
    
    -- A. Process IDLE Sheet (2 frames wide, 4 rows tall)
    for row = 1, 4 do
        local dir = directions[row]
        Assets.player.idle[dir] = {}
        for col = 1, 2 do
            table.insert(Assets.player.idle[dir], 
                love.graphics.newQuad((col-1)*32, (row-1)*32, 32, 32, Assets.playerIdle:getDimensions())
            )
        end
    end
    
    -- B. Process WALK Sheet (4 frames wide, 4 rows tall)
    for row = 1, 4 do
        local dir = directions[row]
        Assets.player.walk[dir] = {}
        for col = 1, 4 do
            table.insert(Assets.player.walk[dir], 
                love.graphics.newQuad((col-1)*32, (row-1)*32, 32, 32, Assets.playerWalk:getDimensions())
            )
        end
    end
end

return Assets