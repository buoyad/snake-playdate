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

-- Game modes
local gmMenu = "menu"
local gmPlaying = "playing"

local gamestate = {
    gameMode = gmMenu,
    gameModeState = nil,
}

local function myGameSetUp()
    gamestate.gameModeState = GameplaySetup()
    gamestate.gameMode = gmPlaying
end

-- Start with menu eventually. For now, just start the game.
myGameSetUp()

function playdate.update()

    if gamestate.gameMode == gmPlaying then
        GameplayUpdate(gamestate.gameModeState)
    elseif gamestate.gameMode == gmMenu then
        menu:update()
    end


    playdate.timer.updateTimers()

end
