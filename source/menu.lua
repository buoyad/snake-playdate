import "CoreLibs/graphics"
import "CoreLibs/ui"

local pd <const> = playdate
local gfx <const> = pd.graphics

menu = {}

function MenuSetup()

    local backgroundImage = gfx.image.new("images/background")
    assert(backgroundImage)

    gfx.sprite.setBackgroundDrawingCallback(
        function(x, y, width, height)
            gfx.setClipRect(x, y, width, height) -- let's only draw the part of the screen that's dirty
            backgroundImage:draw(0, 0)
            gfx.clearClipRect() -- clear so we don't interfere with drawing that comes after this
        end
    )

    local ui = pd.ui.gridview.new(0, 44)

    ui:setNumberOfColumns(1)
    ui:setNumberOfRows(2)

    function ui:drawCell(section, row, col, selected, x, y, width, height)
        if selected then
            gfx.drawCircleInRect(x - 2, y - 2, width + 4, height + 4, 3)
        else
            gfx.drawCircleInRect(x + 4, y + 4, width - 8, height - 8, 0)
        end
        local cellText
        if row == 1 then
            cellText = "Play"
        elseif row == 2 then
            cellText = "Play but in red"
        end
        Utils.uiFont:drawTextAligned(cellText, x + width / 2, y + height / 2 - 11, kTextAlignment.left)
    end

    local menuState = {
        gameMode = Utils.gmMenu,
        ui = ui,
    }

    return menuState
end

function menu:update(ctx)
    -- gfx.drawTextAligned("SNAKE", 200, 120, kTextAlignment.center)
    if ctx.gameMode ~= Utils.gmMenu then
        error("Incorrect game state in GameplayUpdate: expected " .. Utils.gmMenu .. ", got " .. ctx.gameMode)
    end
    local state = ctx.gameModeState
    state.ui:drawInRect(0, 0, Utils.screenWidth, Utils.screenHeight)
    Utils.largeBoldFont:drawTextAligned("SNEK", Utils.screenWidth / 2, 40, kTextAlignment.center)


end
