import "CoreLibs/graphics"
import "utils"

local gfx <const> = playdate.graphics

-- Snake segment config
local segmentPadding = 0

-- Snake movement loop parameters
local movementInterval = 300 -- how often the snake moves in ms
local movementTimer = nil

-- Directions
local up <const>, right <const>, left <const>, down <const> = 1, 2, 3, 4

-- Level parameters
local lvlUpPerApples = 3
local maxLvl = 15
local appleImageDim = 20
local linksToAddPerApple = 3
local level = 1
local wrapAroundScreen = true

local function drawSegment(x, y)
    x, y = Utils:gridCoordToScreen(x, y)
    gfx.fillRect(
        x+1+segmentPadding, 
        y+1+segmentPadding, 
        Utils.gridUnit-1-segmentPadding*2, 
        Utils.gridUnit-1-segmentPadding*2)

end

local function intersectsSegments(segments, gridLoc)
    for k, v in pairs(segments) do
        if v.x == gridLoc.x and v.y == gridLoc.y then
            return true
        end
    end
    return false
end

local player = {
    segmentCoords = {},
    sprite = nil,
    moving = false,
    direction = right,
    prevDirection = nil,
    score = 0,
}

function player:printSegmentCoords()
    print("Player coordinates:")
    for i = 1, #player.segmentCoords do
        local coord = player.segmentCoords[i]
        print("i: "..Utils.printPoint(coord))
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
        if ret.x >= Utils:gridWidth() then ret.x = 0 end
        if ret.x < 0 then ret.x = Utils:gridWidth()-1 end
        if ret.y >= Utils:gridHeight() then ret.y = 0 end
        if ret.y < 0 then ret.y = Utils:gridHeight()-1 end
    end

    return ret
end

function player:move(state)
    -- move all the segment coordinates up a spot
    -- player:printSegmentCoords()
    for i = #player.segmentCoords,2,-1 do
        player.segmentCoords[i] = player.segmentCoords[i-1]
    end
    player.prevDirection = player.direction

    -- check if our target eats ourself
    local target = player:setTarget()
    if intersectsSegments(player.segmentCoords, target) then
        -- we died :(
        sounds:death()
    end

    player.segmentCoords[1] = target -- move the head forward

    -- if we ran into the apple, eat it
    if player.segmentCoords[1].x == state.apple.gridLoc.x and 
       player.segmentCoords[1].y == state.apple.gridLoc.y then
        self:eat(state)
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

function player:eat(state)
    state.apple:move(player.segmentCoords)
    self:addTailLinks(linksToAddPerApple)
    self.score += 1;
    if self.score % lvlUpPerApples == 0 and level < maxLvl then
        movementInterval -= .15 * movementInterval -- lvlSpeedups[level] -- math.log(3+3*self.score, 1.5)
        level += 1
        resetMovementTimer()
    end
end

local apple = {
    gridLoc = nil,
    sprite = nil,
}

local function getRandGridCell()
    return { x = math.random(0, math.floor(Utils:gridWidth() - 1)), y = math.random(0, math.floor(Utils:gridHeight() - 1)) }
end

function apple:move(segments)
    self.gridLoc = getRandGridCell()
    if segments then
        while intersectsSegments(segments, self.gridLoc) do
            self.gridLoc = getRandGridCell()
        end
    end
    local rx, ry = Utils:gridCoordToScreen(self.gridLoc.x, self.gridLoc.y)
    self.sprite:moveTo(rx + Utils.gridUnit / 2, ry + Utils.gridUnit / 2) -- this is where the center of the sprite is placed; so we need to correct by half the grid unit size. 
end

local function drawStatusText()
    -- store current draw mode to reset it later
    local origDrawMode = gfx.getImageDrawMode()
    -- set text to white
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

    local lvlTxt = "Lvl " .. level
    if level == maxLvl then
        lvlTxt = lvlTxt .. " !!MAX!! "
    end

    gfx.drawText("Score: " .. player.score, 0, 0)
    gfx.drawTextAligned(lvlTxt, Utils.screenWidth, 0, kTextAlignment.right)

    -- set draw mode back
    gfx.setImageDrawMode(origDrawMode)

    if Utils.showDebugInfo then
        Utils.debugFont:drawText("mvmt interval: " .. math.floor(movementInterval) .. "ms\n\z
            player length: " .. #player.segmentCoords, 0, Utils.statusBarHeight)
    end
end

local function drawGrid()
    -- verticals
    for i = 1, Utils:gridWidth() - 1 do
        local xCoord = i * Utils.gridUnit
        gfx.drawLine(xCoord, Utils.statusBarHeight, xCoord, Utils.screenHeight)
    end

    -- horizontals
    for i = 1, Utils:gridHeight() - 1 do
        local yCoord = Utils.statusBarHeight + i * Utils.gridUnit
        gfx.drawLine(0, yCoord, Utils.screenWidth, yCoord)
    end
end

function GameplaySetup()
    -- We want an environment displayed behind our sprite.
    -- There are generally two ways to do this:
    -- 1) Use setBackgroundDrawingCallback() to draw a background image. (This is what we're doing below.)
    -- 2) Use a tilemap, assign it to a sprite with sprite:setTilemap(tilemap),
    --       and call :setZIndex() with some low number so the background stays behind
    --       your other sprites.

    local backgroundImage = gfx.image.new("images/background")
    assert(backgroundImage)

    gfx.sprite.setBackgroundDrawingCallback(
        function(x, y, width, height)
            gfx.setClipRect(x, y, width, height) -- let's only draw the part of the screen that's dirty
            backgroundImage:draw(0, 0)
            gfx.clearClipRect() -- clear so we don't interfere with drawing that comes after this

            if Utils.showGrid then drawGrid() end
        end
    )

    -- Set up the player sprite.
    -- The :setCenter() call specifies that the sprite will be anchored at its center.
    -- The :moveTo() call moves our sprite to the center of the display.

    local appleImage = gfx.image.new("images/apple")
    assert(appleImage) -- make sure the image was where we thought

    apple.sprite = gfx.sprite.new(appleImage)
    apple.sprite:setScale(Utils.gridUnit / appleImageDim)
    apple.sprite:add() -- This is critical!
    apple:move()

    for i = 1, 3 do
        player.segmentCoords[i] = { x = math.floor(Utils:gridWidth() / 2), y = math.floor(Utils:gridHeight() / 2) }
    end
    resetMovementTimer()

    local gameplayState = {
        player = player,
        apple = apple,
        movementTimer = movementTimer,
        level = level,
    }

    return gameplayState

end

function GameplayUpdate(state)
    if playdate.buttonIsPressed(playdate.kButtonUp) and state.player.prevDirection ~= down then
        state.player.direction = up
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) and state.player.prevDirection ~= left then
        state.player.direction = right
    end
    if playdate.buttonIsPressed(playdate.kButtonDown) and state.player.prevDirection ~= up then
        state.player.direction = down
    end
    if playdate.buttonIsPressed(playdate.kButtonLeft) and state.player.prevDirection ~= right then
        state.player.direction = left
    end

    gfx.sprite.update()

    state.player:draw()

    if state.player.moving then
        state.player:move(state)
        state.player.moving = false
    end
    drawStatusText()
end
