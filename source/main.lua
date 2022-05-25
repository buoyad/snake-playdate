import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/easing"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics

math.randomseed(playdate.getSecondsSinceEpoch())

-- Development utilities
local showGrid = false
local showDebugInfo = true
local debugFont = gfx.font.new("fonts/Small")
assert(debugFont, "debug font")

-- Gameplay area utilities
local statusBarHeight = 20
local screenWidth = 400
local screenHeight = 240
local appleImageDim = 20
local linksToAddPerApple = 3
local level = 1
local wrapAroundScreen = true

local appleWillBeEaten = nil

local function gameplayAreaWidth() return screenWidth end
local function gameplayAreaHeight() return screenHeight - statusBarHeight end

local up <const>, right <const>, left <const>, down <const> = 1, 2, 3, 4

-- Grid parameters
local gridUnit = 10
local gridWidth = gameplayAreaWidth() / gridUnit
local gridHeight = gameplayAreaHeight() / gridUnit

-- Returns the screen coordinate of the top left corner of the grid cell
local function gridCoordToScreen(x, y)
    local xCoord = x * gridUnit
    local yCoord = statusBarHeight + y * gridUnit
    return xCoord, yCoord
end

local function printPoint(p) return "("..p.x..", "..p.y..")" end

-- Snake movement loop parameters
local movementInterval = 300 -- how often the snake moves in ms
local movementDutyCycle = .9 -- % of time the snake spends moving, rather than sitting in place
local movementTimer = nil

local gamestate = {
    player = nil,
    apple = nil,
    movementTimer = movementTimer,
    level = level,
}

local apple = {
    gridLoc = nil,
    sprite = nil,
}
gamestate.apple = apple

local function getRandGridCell()
    return {x= math.random(0, math.floor(gridWidth-1)), y= math.random(0, math.floor(gridHeight-1))}
end

local function intersectsSegments(segments, gridLoc)
    for k, v in pairs(segments) do
        if v.x == gridLoc.x and v.y == gridLoc.y then
            return true
        end
    end
    return false
end

function apple:move(segments)
    self.gridLoc = getRandGridCell()
    if segments then
        while intersectsSegments(segments, self.gridLoc) do
            self.gridLoc = getRandGridCell()
        end
    end
    local rx, ry = gridCoordToScreen(self.gridLoc.x, self.gridLoc.y)
    self.sprite:moveTo( rx + gridUnit / 2, ry + gridUnit /2 ) -- this is where the center of the sprite is placed; so we need to correct by half the grid unit size. 
end

-- Snake segment config
local segmentPadding = 0

function drawSegment(x, y)
    local x, y = gridCoordToScreen(x, y)
    gfx.fillRect(
        x+1+segmentPadding, 
        y+1+segmentPadding, 
        gridUnit-1-segmentPadding*2, 
        gridUnit-1-segmentPadding*2)

end

local player = {
    segmentCoords = {},
    sprite = nil,
    moving = false,
    direction = right,
    prevDirection = nil,
    score = 0,
}
gamestate.player = player

function player:printSegmentCoords()
    print("Player coordinates:")
    for i = 1, #player.segmentCoords do
        local coord = player.segmentCoords[i]
        print("i: "..printPoint(coord))
    end
end

function player:setTarget()
    if not self.direction then return end
    local ret = {}
    local headX, headY = self.segmentCoords[1].x, self.segmentCoords[1].y
    if self.direction == up then
        ret = {x = headX, y = headY - 1}
    elseif self.direction == right then
        ret = {x = headX + 1, y = headY}
    elseif self.direction == down then
        ret = {x = headX, y = headY + 1}
    elseif self.direction == left then
        ret = {x = headX - 1, y = headY}
    end
    
    if wrapAroundScreen then
        if ret.x >= gridWidth then ret.x = 0 end
        if ret.x < 0 then ret.x = gridWidth-1 end
        if ret.y >= gridHeight then ret.y = 0 end
        if ret.y < 0 then ret.y = gridHeight-1 end
    end

    return ret
end

function player:move()
    -- set targets for all the player segments
    -- player:printSegmentCoords()
    for i = #player.segmentCoords,2,-1 do
        player.segmentCoords[i] = player.segmentCoords[i-1]
    end
    player.prevDirection = player.direction
    player.segmentCoords[1] = player:setTarget()
    if player.segmentCoords[1].x == apple.gridLoc.x and 
       player.segmentCoords[1].y == apple.gridLoc.y then
        self:eat()
    end
    -- player:printSegmentCoords()
end

function player:draw()
    for i = 1,#player.segmentCoords do
        drawSegment(player.segmentCoords[i].x, player.segmentCoords[i].y)     
    end
end

function player:setMoving()
    self.moving = true
end

function player:addTailLinks(howMany)
    local lc = player.segmentCoords[#player.segmentCoords]
    for i = 1, howMany do
        player.segmentCoords[#player.segmentCoords+1] = {x = lc.x, y = lc.y}
    end
end

local function resetMovementTimer()
    local function movePlayer()
        player.moving = true
    end
    
    if movementTimer then movementTimer:remove() end

    movementTimer = playdate.timer.new(movementInterval, movePlayer)
    movementTimer.repeats = true
end

function player:eat()
    apple:move(player.segmentCoords)
    self:addTailLinks(linksToAddPerApple)
    self.score += 1;
    if self.score % 3 == 0 then
        movementInterval -= math.log(2+self.score, 1.5)
        level += 1
        resetMovementTimer()
    end
end

local function drawStatusText()
    -- store current draw mode to reset it later
    local origDrawMode = gfx.getImageDrawMode()
    -- set text to white
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    
    gfx.drawText("Score: "..player.score, 0, 0)
    gfx.drawTextAligned(level, screenWidth, 0, kTextAlignment.right)

    -- set draw mode back
    gfx.setImageDrawMode(origDrawMode)

    if showDebugInfo then
        debugFont:drawText("mvmt interval: "..math.floor(movementInterval).."ms\n\z
            player length: "..#player.segmentCoords, 0, statusBarHeight)
    end
end

local function drawGrid()
    -- verticals
    for i = 1, gridWidth-1 do
        local xCoord = i * gridUnit
        gfx.drawLine(xCoord, statusBarHeight, xCoord, screenHeight)
    end

    -- horizontals
    for i = 1, gridHeight-1 do
        local yCoord = statusBarHeight + i * gridUnit
        gfx.drawLine(0, yCoord, screenWidth, yCoord)
    end
end

local function gameplaySetup()
    -- We want an environment displayed behind our sprite.
    -- There are generally two ways to do this:
    -- 1) Use setBackgroundDrawingCallback() to draw a background image. (This is what we're doing below.)
    -- 2) Use a tilemap, assign it to a sprite with sprite:setTilemap(tilemap),
    --       and call :setZIndex() with some low number so the background stays behind
    --       your other sprites.

    local backgroundImage = gfx.image.new("images/background")
    assert(backgroundImage)

    gfx.sprite.setBackgroundDrawingCallback(
        function( x, y, width, height )
            gfx.setClipRect( x, y, width, height ) -- let's only draw the part of the screen that's dirty
            backgroundImage:draw(0, 0)
            gfx.clearClipRect() -- clear so we don't interfere with drawing that comes after this

            if showGrid then drawGrid() end
        end
    )

    -- Set up the player sprite.
    -- The :setCenter() call specifies that the sprite will be anchored at its center.
    -- The :moveTo() call moves our sprite to the center of the display.

    local appleImage = gfx.image.new("images/apple")
    assert( appleImage ) -- make sure the image was where we thought

    apple.sprite = gfx.sprite.new(appleImage)
    apple.sprite:setScale(gridUnit / appleImageDim)
    apple.sprite:add() -- This is critical!
    apple:move()

    for i = 1, 3 do
        player.segmentCoords[i] = {x = math.floor(gridWidth/2), y = math.floor(gridHeight/2)}
    end
    resetMovementTimer()

end

local function myGameSetUp()
    -- Start with menu eventually. For now, just start the game.
    gameplaySetup()

end

myGameSetUp()

function playdate.update()

    -- Poll the d-pad and move our player accordingly.
    -- (There are multiple ways to read the d-pad; this is the simplest.)
    -- Note that it is possible for more than one of these directions
    -- to be pressed at once, if the user is pressing diagonally.

    if playdate.buttonIsPressed( playdate.kButtonUp ) and player.prevDirection ~= down then
        player.direction = up
    end
    if playdate.buttonIsPressed( playdate.kButtonRight ) and player.prevDirection ~= left then
        player.direction = right
    end
    if playdate.buttonIsPressed( playdate.kButtonDown ) and player.prevDirection ~= up then
        player.direction = down
    end
    if playdate.buttonIsPressed( playdate.kButtonLeft ) and player.prevDirection ~= right then
        player.direction = left
    end
    gfx.sprite.update()

    player:draw()
    
    if player.moving then
        player:move()
        player.moving = false
    end

    drawStatusText()

    playdate.timer.updateTimers()

end