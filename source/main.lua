import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "sounds"
import "menu"
import "gameplay"
import "utils"

assert(sounds)
sounds:init()

local gfx <const> = playdate.graphics

math.randomseed(playdate.getSecondsSinceEpoch())

-- Gameplay area utilities
local statusBarHeight = 20
local screenWidth = 400
local screenHeight = 240

local gamestate = {
    gameMode = Utils.gmMenu,
    gameModeState = nil,
}

function gamestate:setGameMode(gm)
    if gm == Utils.gmPlaying then
        self.gameMode = gm
        self.gameModeState = GameplaySetup()
    end
end

local function myGameSetUp()
    local menu = playdate.getSystemMenu()
    menu:addCheckmarkMenuItem("debug info",
        Utils.showDebugInfo,
        function(checked) Utils.showDebugInfo = checked end)
    menu:addCheckmarkMenuItem("show grid",
        Utils.showGrid,
        function(checked)
            if Utils.showGrid and not checked then
                -- mark entire background as dirty
                playdate.graphics.sprite.redrawBackground()
            end
            Utils.showGrid = checked
        end)

    -- Start with menu eventually. For now, just start the game.
    gamestate:setGameMode(Utils.gmPlaying)
end

myGameSetUp()

function playdate.update()

    if gamestate.gameMode == Utils.gmPlaying then
        GameplayUpdate(gamestate)
    elseif gamestate.gameMode == Utils.gmMenu then
        menu:update()
    end


    playdate.timer.updateTimers()

end
