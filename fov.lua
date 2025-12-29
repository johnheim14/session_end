local FOV = {}

-- Recursive Shadowcasting constants
-- Transforms for the 8 octants
local MULTIPLIERS = {
    { 1, 0, 0, -1, -1, 0, 0, 1 },
    { 0, 1, -1, 0, 0, -1, 1, 0 },
    { 0, 1, 1, 0, 0, -1, -1, 0 },
    { 1, 0, 0, 1, -1, 0, 0, -1 },
}

-- Main function to calculate visibility
function FOV.calculate(cx, cy, radius, isTransparent, setVisible)
    -- Always see center
    setVisible(cx, cy)

    -- Cast light in all 8 octants
    for i = 1, 8 do
        FOV.castLight(
            cx, cy,
            radius,
            1,
            1.0,
            0.0,
            MULTIPLIERS[1][i],
            MULTIPLIERS[2][i],
            MULTIPLIERS[3][i],
            MULTIPLIERS[4][i],
            isTransparent,
            setVisible
        )
    end
end

-- Recursive function to cast light
function FOV.castLight(cx, cy, radius, row, start, finish,
                       xx, xy, yx, yy, isTransparent, setVisible)

    if start < finish then return end

    local radiusSq = radius * radius

    for j = row, radius do
        local dx = -j - 1
        local dy = -j
        local blocked = false
        local newStart = -1 -- Changed from start

        while dx <= 0 do
            dx = dx + 1

            local X = cx + dx * xx + dy * xy
            local Y = cy + dx * yx + dy * yy

            local l_slope = (dx - 0.5) / (dy + 0.5)
            local r_slope = (dx + 0.5) / (dy - 0.5)

            if start < r_slope then
                -- Skip: outside current beam
                goto continue
            elseif finish > l_slope then
                break
            end

            -- Check if within radius
            if dx*dx + dy*dy <= radiusSq then
                setVisible(X, Y)
            end

            if blocked then
                -- We're in a shadow
                if not isTransparent(X, Y) then
                    newStart = r_slope
                    goto continue
                end
                blocked = false
                start = newStart
            else
                -- Not in shadow
                if not isTransparent(X, Y) and j < radius then
                    blocked = true
                    FOV.castLight(
                        cx, cy,
                        radius,
                        j + 1,
                        start,
                        l_slope,
                        xx, xy, yx, yy,
                        isTransparent,
                        setVisible
                    )
                    newStart = r_slope
                end
            end

            ::continue::
        end

        if blocked then break end
    end
end

return FOV