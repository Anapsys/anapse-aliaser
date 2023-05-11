--[[
Anapse manual anti-aliser for Aseprite
Given selection, aliases on the borders of the foreground color WITH the selected secondary color.
Useful for quickly applying this style to large areas in larger drawings.

Adapted from Rik Nicol's iteration https://github.com/rikfuzz/aseprite-scripts/blob/master/antialias.lua
]]--

-- definitions
local canvas; 
local targetSprite = app.activeSprite
local targetSpriteSelection = targetSprite.selection
local targetImage = app.activeImage
local imageClone = targetImage:clone()
--local dlg = Dialog("Custom Widgets")
--local mouse = {position = Point(0, 0), leftClick = false}
--local focusedWidget = nil

-- defnition assignment
if targetSpriteSelection.bounds.width>0 then 
    canvas = {
        x = targetSpriteSelection.bounds.x,
        y = targetSpriteSelection.bounds.y,
        width = targetSpriteSelection.bounds.width,
        height = targetSpriteSelection.bounds.height
    };
else 
    canvas = {
        x = 0,
        y = 0,
        width = targetImage.width,
        height = targetImage.height
    };
end

-- color management
local function colorToRGBA(color)
    return app.pixelColor.rgba(color.red, color.green, color.blue, color.alpha)
end
local targetColor = app.fgColor
targetColor = colorToRGBA(targetColor)
local aliasColor = app.bgColor
aliasColor = colorToRGBA(aliasColor)

-- base operation definitions
-- 
local function getPixel(x,y)
    return newImage:getPixel(x, y)
end

-- 
local function putPixel(color,x,y)
    return newImage:putPixel(x, y, color)
end
 -- 
local function clreq(a, b)
	-- TODO: wtf does this do
    --if a==false then return false end
    --if b==false then return false end

    return app.pixelColor.rgbaR(a) == app.pixelColor.rgbaR(b) and
        app.pixelColor.rgbaG(a) == app.pixelColor.rgbaG(b) and
        app.pixelColor.rgbaB(a) == app.pixelColor.rgbaB(b) 
end