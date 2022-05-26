import "CoreLibs/graphics"

local gfx <const> = playdate.graphics
local debugFont = gfx.font.new("fonts/Small")
assert(debugFont, "debug font")

local largeBoldFont = gfx.font.new("fonts/Nontendo-Bold-2x")
assert(largeBoldFont, "large bold font")

local uiFont = gfx.font.new("fonts/Roobert-11-Bold")
assert(uiFont, "UI font")

local savedata = {
    hiScore = 0,
}

Utils = {
    statusBarHeight = 20,
    screenWidth = 400,
    screenHeight = 240,
    gridUnit = 10,
    debugFont = debugFont,
    largeBoldFont = largeBoldFont,
    uiFont = uiFont,
    showDebugInfo = false,
    showGrid = false,
    gmMenu = "menu",
    gmPlaying = "playing",
    niceAppleSpawn = false,
    savedata = savedata,
}


function Utils.printPoint(p) return "(" .. p.x .. ", " .. p.y .. ")" end

function Utils:gameplayAreaWidth() return self.screenWidth end

function Utils:gameplayAreaHeight() return self.screenHeight - self.statusBarHeight end

function Utils:writeSaveData()
    -- print("write:")
    -- printTable(self.savedata)
    playdate.datastore.write(self.savedata)
end

function Utils:readSaveData()
    return playdate.datastore.read()
end

-- Grid parameters
function Utils:gridWidth() return self:gameplayAreaWidth() / self.gridUnit end

function Utils:gridHeight() return self:gameplayAreaHeight() / self.gridUnit end

-- Returns the screen coordinate of the top left corner of the grid cell
function Utils:gridCoordToScreen(x, y)
    local xCoord = x * self.gridUnit
    local yCoord = self.statusBarHeight + y * self.gridUnit
    return xCoord, yCoord
end
