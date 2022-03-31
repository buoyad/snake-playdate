import "CoreLibs/object"
import "CoreLibs/graphics"
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
local movementInterval = 300
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

class("Segment").extends()

-- Snake segment config
local segmentPadding = 0

function Segment:init(x, y)
    Segment.super.init(self)
    self.x, self.y = x, y
    self.animator = nil
end

function Segment:setTarget(direction)
    if not direction then return end
    if direction == up then
        self.target = {x = self.x, y = self.y - 1}
    elseif direction == right then
        self.target = {x = self.x + 1, y = self.y}
    elseif direction == down then
        self.target = {x = self.x, y = self.y + 1}
    elseif direction == left then
        self.target = {x = self.x - 1, y = self.y}
    end
    
    if wrapAroundScreen then
        if self.target.x >= gridWidth then self.target.x = 0 end
        if self.target.x < 0 then self.target.x = gridWidth-1 end
        if self.target.y >= gridHeight then self.target.y = 0 end
        if self.target.y < 0 then self.target.y = gridHeight-1 end
    end

    -- print("new target is "..printPoint(self.target))
    -- print("apple is at "..printPoint(apple.gridLoc))
    if self.target.x == apple.gridLoc.x and self.target.y == apple.gridLoc.y then
        appleWillBeEaten = true
    end
end

function Segment:draw()
    local x, y = gridCoordToScreen(self.x, self.y)
    if self.animator and not self.animator:ended() then
        local currPoint = self.animator:currentValue()
        if currPoint then
            x, y = currPoint.x, currPoint.y
        end
    end
    gfx.fillRect(
        x+1+segmentPadding, 
        y+1+segmentPadding, 
        gridUnit-1-segmentPadding*2, 
        gridUnit-1-segmentPadding*2)
end

function Segment:move()
    if not self.target then return end
    local x1, y1 = gridCoordToScreen(self.x, self.y)
    local animatorGeometry
    if self.target.x - self.x < -10 then
        local x2, y2 = x1 + gridUnit, y1
        -- print("target: "..printPoint(self.target))
        local x4, y4 = gridCoordToScreen(self.target.x, self.target.y)
        local x3, y3 = x4 - gridUnit, y4
        local p1 = playdate.geometry.lineSegment.new(x1, y1, x2, y2)
        local p2 = playdate.geometry.lineSegment.new(x3, y3, x4, y4)
        animatorGeometry = {p1, p2}
    else
        local x2, y2 = gridCoordToScreen(self.target.x, self.target.y)
        animatorGeometry = playdate.geometry.lineSegment.new(x1, y1, x2, y2)
    end
    self.animator = gfx.animator.new(movementDutyCycle*movementInterval, animatorGeometry)
    self.x, self.y = self.target.x, self.target.y -- animator takes over location for the time being
    if (appleWillBeEaten) then
        playdate.timer.new(movementDutyCycle*movementInterval, function()
            gamestate.player:eat()
        end)
        appleWillBeEaten = false
    end
end

local player = {
    headCoords = {},
    segments = {},
    sprite = nil,
    moving = false,
    direction = right,
    prevDirection = nil,
    score = 0,
}
gamestate.player = player

function player:printHeadCoords()
    -- print("Player coordinates:")
    for i = 1, #player.headCoords do
        local coord = player.headCoords[i]
        -- print("i: "..printPoint(coord))
    end
end

function player:move()
    -- set targets for all the player segments
    player:printHeadCoords()
    for i = #player.headCoords,2,-1 do
        player.headCoords[i] = player.headCoords[i-1]
        player.segments[i].target = player.headCoords[i]
    end
    player.segments[1]:setTarget(player.direction)
    player.prevDirection = player.direction
    player.headCoords[1] = player.segments[1].target
    player:printHeadCoords()
    -- move them
    for i, seg in pairs(player.segments) do
        seg:move()
    end
end

function player:setMoving()
    self.moving = true
end

function player:addTailLinks(howMany)
    local ls = player.segments[#player.segments]
    local lc = player.headCoords[#player.headCoords]
    for i = 1, howMany do
        player.segments[#player.segments+1] = Segment(ls.x, ls.y)
        player.headCoords[#player.headCoords+1] = {x = lc.x, y = lc.y}
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
    apple:move(player.segments)
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
            player length: "..#player.segments, 0, statusBarHeight)
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

    -- local backgroundImage = gfx.image.new( "images/background" )
    -- assert( backgroundImage )

    gfx.sprite.setBackgroundDrawingCallback(
        function( x, y, width, height )
            gfx.setClipRect( x, y, width, height ) -- let's only draw the part of the screen that's dirty
            gfx.fillRect(0, 0, 400, statusBarHeight)
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
        player.segments[i] = Segment(math.floor(gridWidth/2), math.floor(gridHeight/2))
        player.headCoords[i] = {x = math.floor(gridWidth/2), y = math.floor(gridHeight/2)}
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

    for i, seg in pairs(player.segments) do
        seg:draw()
    end

    if player.moving then
        player:move()
        player.moving = false
    end

    -- Call the functions below in playdate.update() to draw sprites and keep
    -- timers updated. (We aren't using timers in this example, but in most
    -- average-complexity games, you will.)

    
    drawStatusText()

    playdate.timer.updateTimers()

end