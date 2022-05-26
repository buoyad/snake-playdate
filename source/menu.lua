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

    local menuState = {
        gameMode = Utils.gmMenu,
    }

    return menuState
end

function drawMenu()
    Utils.largeBoldFont:drawTextAligned("SNEK", Utils.screenWidth / 2, Utils.screenHeight / 2 - 40, kTextAlignment.center)
    Utils.uiFont:drawTextAligned("Press Ⓐ to start", Utils.screenWidth / 2, Utils.screenHeight / 2 + 40, kTextAlignment.center)
end

function menu:update(ctx)
    if ctx.gameMode ~= Utils.gmMenu then
        error("Incorrect game state in GameplayUpdate: expected " .. Utils.gmMenu .. ", got " .. ctx.gameMode)
    end
    gfx.sprite.update()

    drawMenu()

    if pd.buttonIsPressed(pd.kButtonA) then
        ctx:setGameMode(Utils.gmPlaying)
    end
end
