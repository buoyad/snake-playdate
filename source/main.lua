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

local savedata = Utils:readSaveData()
if savedata ~= nil then
    Utils.savedata = savedata
end

local gfx <const> = playdate.graphics

math.randomseed(playdate.getSecondsSinceEpoch())

-- Gameplay area utilities
local statusBarHeight = 20
local screenWidth = 400
local screenHeight = 240

local ctx = {
    gameMode = Utils.gmMenu,
    gameModeState = nil,
    savedata = nil,
}

function ctx:setGameMode(gm)
    if gm == Utils.gmPlaying then
        self.gameMode = gm
        self.gameModeState = GameplaySetup()
    elseif gm == Utils.gmMenu then
        self.gameMode = gm
        self.gameModeState = MenuSetup()
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

    ctx:setGameMode(Utils.gmMenu)
end

myGameSetUp()

function playdate.update()

    if ctx.gameMode == Utils.gmPlaying then
        GameplayUpdate(ctx)
    elseif ctx.gameMode == Utils.gmMenu then
        menu:update(ctx)
    end


    playdate.timer.updateTimers()

end
