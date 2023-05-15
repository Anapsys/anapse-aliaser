--[[
Anapse manual anti-aliser for Aseprite
Given canvas or selection, aliases on the borders of the foreground color WITH the selected secondary color.
Useful for quickly applying this style to large areas in larger drawings.

Adapted/refactored from Rik Nicol's work https://github.com/rikfuzz/aseprite-scripts/blob/master/antialias.lua
]]--

-- constants
function protect(tbl)
    return setmetatable({}, {
        __index = tbl,
        __newindex = function(t, key, value)
            error("attempting to change constant " ..
                   tostring(key) .. " to " .. tostring(value), 2)
        end
    })
end

GR = {
    empty = 0,
	a = 1,
    b = 2,
	c = 3,
	d = 4,
	e = 5,
}
GR = protect(GR)

-- config
local anycolor = true;
local extraSmooth = true;

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
    return imageClone:getPixel(x, y)
end

-- 
local function putPixel(color,x,y)
    return imageClone:putPixel(x, y, color)
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

-- grid operation definitions
local function getGrid(cx,cy)
    local grid = {	0,0,0,0,0,
					0,0,0,0,0,
					0,0,0,0,0,
					0,0,0,0,0,
					0,0,0,0,0};
    for y=0, 4 do
        for x=0, 4 do
            local clr = getPixel(cx + x-2,cy + y-2);
            local cell = 0;

            if (clreq(clr,targetColor)) then
                cell = 1;
            elseif(not anycolor and clreq(clr,outerColor)) then
                cell = 5;
            elseif(clreq(clr,aliasColor)) then
                cell = 4;
            end      

            grid[y*5+x+1] = cell;
        end
    end
    return grid;
end

local function rotateGrid(testGrid)
    local newGrid = {	0,0,0,0,0,
						0,0,0,0,0,
						0,0,0,0,0,
						0,0,0,0,0,
						0,0,0,0,0};
    local i = 1
    for x=0, 4 do
        for y=4, 0,-1 do
            local gridPos = y*5+x;
            newGrid[i] = testGrid[gridPos+1];
            i = i + 1
        end
    end
    return newGrid;
end

-- rotates input grid by 90 degrees
local function flipGrid(testGrid)
    local newGrid = {	0,0,0,0,0,
						0,0,0,0,0,
						0,0,0,0,0,
						0,0,0,0,0,
						0,0,0,0,0};
    local i =1
    for y=0, 4 do
        for x=4,0,-1 do
            local gridPos = y*5+x;
            newGrid[i] = testGrid[gridPos+1];
            i = i + 1
        end
    end
    return newGrid;
end

-- grid test definitions
-- 
local function testPixels(testGrid,imageGrid)
    for i=1,#testGrid do
		local tG = testGrid[i]
		local iG = imageGrid[i]
        if t == 0 then
            --nothing
        else
            if ((tG == 1 or tG == 3) 
				and tG ~= iG) 
				then
                return false;
            elseif (tG==2 
				and ((anycolor and (iG==1 or iG==3))
					or (not(anycolor) and iG~=5))) 
					then               
                return false;
            elseif (tG==4 and iG==3) 
				then
                return false;
            end
        end

    end
    return true
end

-- given a "test grid", tests every transformation of said grid via testPixels()
local function testPixelsAnyRotation(testGrid,imageGrid)
    local grids = {};
    local grid1 = testGrid;
    local grid2 = rotateGrid(grid1);
    local grid3 = rotateGrid(grid2);
    local grid4 = rotateGrid(grid3);
    local grid5 = flipGrid(grid1);
    local grid6 = flipGrid(grid2);
    local grid7 = flipGrid(grid3);
    local grid8 = flipGrid(grid4);
    grids = {grid1,grid2,grid3,grid4,grid5,grid6,grid7,grid8};
    for i=1,8 do
        if testPixels(grids[i],imageGrid) then
            return true
        end
    end
    return false 
end

-- ?
local aliasPlacesX = {};
local aliasPlacesY = {};
local bodyPlacesX = {};
local bodyPlacesY = {};
local function pushAA(x,y)
    table.insert(aliasPlacesX,x)
    table.insert(aliasPlacesY,y)
end
local function pushB(x,y)
    table.insert(bodyPlacesX,x)
    table.insert(bodyPlacesY,y)
end

-- main
local function aa()
    local testGrid = {};
    local imageGrid = {};

    for y=1+canvas.y, canvas.y+canvas.height-2 do
        for x=1+canvas.x, canvas.x+canvas.width-2 do

            if (clreq(getPixel(x,y),targetColor) and 
            not(clreq(getPixel(x-1,y),targetColor) and 
            clreq(getPixel(x+1,y),targetColor) and
            clreq(getPixel(x,y-1),targetColor) and
            clreq(getPixel(x,y+1),targetColor))) then
                imageGrid = getGrid(x,y);
                testGrid = {
                    0,0,0,0,0,
                    0,0,2,2,0,
                    0,2,0,1,0,
                    0,0,1,0,0,
                    0,0,0,0,0
                }; 
                if testPixelsAnyRotation(testGrid,imageGrid) then
                    pushAA(x,y);
                else
                    testGrid = {
                        0,0,0,0,0,
                        0,2,2,2,0,
                        2,1,0,0,0,
                        0,0,0,0,0,
                        0,0,0,0,0
                    };
                    if testPixelsAnyRotation(testGrid,imageGrid) then
                        pushAA(x,y);
                    else
                        testGrid = {
                            0,0,0,0,0,
                            0,2,2,2,2,
                            0,0,0,2,0,
                            0,0,0,0,0,
                            0,0,0,0,0
                        };
                        if testPixelsAnyRotation(testGrid,imageGrid) then
                            pushAA(x,y);
                        end
                    end                    
                end
            end
        end
    end

    for i=1,#aliasPlacesX do
        putPixel(aliasColor, aliasPlacesX[i], aliasPlacesY[i])
    end

    if(extraSmooth)then
        aliasPlacesX={}
        aliasPlacesY={}
        for y=1+canvas.y, canvas.y+canvas.height-2 do
            for x=1+canvas.x, canvas.x+canvas.width-2 do
                if not clreq(getPixel(x,y), targetColor) then
                    imageGrid = getGrid(x,y);
                    testGrid = {
                        0,0,0,0,0,
                        0,0,2,2,1,
                        0,2,0,1,0,
                        0,1,1,0,0,
                        0,0,0,0,0
                    }; 
                    if testPixelsAnyRotation(testGrid, imageGrid) then
                        pushAA(x,y);
                    end
                end
            end
        end
        for i=1,#aliasPlacesX do
            putPixel(aliasColor,aliasPlacesX[i],aliasPlacesY[i])
        end
    end
end

-- entry point
aa()
app.activeImage:putImage(imageClone)