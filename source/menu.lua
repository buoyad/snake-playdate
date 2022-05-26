import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

menu = {}

function menu:update()
    gfx.drawTextAligned("SNAKE", 200, 120, kTextAlignment.center)
end
