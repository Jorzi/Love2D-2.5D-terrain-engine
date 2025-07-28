function initializeFluid(heightmap, level, sourceSinks)
    local fluid = {}
    fluid.sourceSinks = sourceSinks
    fluid.heightmap = heightmap
    fluid.mapSizeX = heightmap:getWidth()
    fluid.mapSizeY = heightmap:getHeight()
    fluid.fluidLayer = love.graphics.newCanvas(mapSizeX, mapSizeY, {format = "rgba32f"})
	fluid.fluidLayer:setWrap("clampzero")
    fluid.tmpBuffer = love.graphics.newCanvas(mapSizeX, mapSizeY, {format = "rgba32f"})
	fluid.tmpBuffer:setWrap("clampzero")
    fluid.outBuffer = love.graphics.newCanvas(mapSizeX, mapSizeY, {format = "rgba32f"})
	fluid.outBuffer:setWrap("clampzero")
    fluid.fluidsimShader = love.graphics.newShader("fluidsim.glsl")
    fluid.blurShader = love.graphics.newShader("blur2.glsl")
    fluid.levelDraw = love.graphics.newShader("setLevel.glsl")
    fluid.edgeExtend = love.graphics.newShader("edge_extend.glsl")
    fluid.moistureDiffusion = love.graphics.newShader("moisture_diffusion.glsl")
    fluid.fluidsimShader:send("res", {fluid.mapSizeX, fluid.mapSizeY})
    fluid.blurShader:send("res", {fluid.mapSizeX, fluid.mapSizeY})
    fluid.levelDraw:send("res", {fluid.mapSizeX, fluid.mapSizeY})
    fluid.edgeExtend:send("res", {fluid.mapSizeX, fluid.mapSizeY})
    fluid.moistureDiffusion:send("res", {fluid.mapSizeX, fluid.mapSizeY})
    fluid.fluidsimShader:send("dt", 0.05)
    fluid.fluidsimShader:send("terrain", fluid.heightmap)
    fluid.levelDraw:send("terrain", fluid.heightmap)
    fluid.edgeExtend:send("terrain", fluid.heightmap)
    --fluid.moistureDiffusion:send("heightmap", fluid.heightmap)
    fluid.levelDraw:send("fluidBuffer", fluid.tmpBuffer)

    love.graphics.setCanvas(fluid.fluidLayer)
    love.graphics.setShader(fluid.levelDraw)
    love.graphics.setBlendMode("alpha") 
    love.graphics.setColor(level,0,0)
    love.graphics.rectangle("fill", 0, 0, fluid.mapSizeX, fluid.mapSizeY)
    love.graphics.setShader()
    love.graphics.setColor(1,1,1)
    love.graphics.setCanvas()
    fluid.fluidData = fluid.fluidLayer:newImageData()
    fluid.tickCounter = 0
    return fluid;
end


function updateFluid(fluid)
    love.graphics.setBlendMode('replace', 'premultiplied') 
    for i = 1, 2 do
        --3 fluid sim steps, 1 blur
        love.graphics.setShader(fluid.fluidsimShader)
        love.graphics.setCanvas(fluid.tmpBuffer)
        love.graphics.draw(fluid.fluidLayer)
        love.graphics.setCanvas(fluid.fluidLayer)
        love.graphics.draw(fluid.tmpBuffer)
        love.graphics.setShader(fluid.moistureDiffusion)
        love.graphics.setCanvas(fluid.tmpBuffer)
        love.graphics.draw(fluid.fluidLayer)
        love.graphics.setShader(fluid.blurShader)
        love.graphics.setCanvas(fluid.fluidLayer)
        love.graphics.draw(fluid.tmpBuffer)
    end

    love.graphics.setShader(fluid.levelDraw)
    for i,v in pairs(fluid.sourceSinks) do
        love.graphics.setColor(v.level,0,0)
        love.graphics.rectangle("fill", v.x, v.y, v.width, v.height)
    end
    love.graphics.setShader(fluid.edgeExtend)
    love.graphics.setCanvas(fluid.tmpBuffer)
    love.graphics.draw(fluid.fluidLayer)
    love.graphics.setShader()
    love.graphics.setColor(1,1,1)
    love.graphics.setCanvas()
    love.graphics.setBlendMode("alpha") 
    fluid.tickCounter = fluid.tickCounter + 1
    if fluid.tickCounter >= 10 then
        local tmp = fluid.fluidData
        fluid.fluidData = fluid.fluidLayer:newImageData()
        tmp:release()
        fluid.tickCounter = 0
    end
end


function addFluid(fluid, x, y )
    love.graphics.setCanvas(fluid.fluidLayer)
    love.graphics.setColor(1, 0, 0)
    love.graphics.setBlendMode("add")
    love.graphics.circle("fill", x, y, 10, 16)
    love.graphics.setBlendMode("alpha") 
    love.graphics.setColor(1,1,1)
    love.graphics.setCanvas()
end

function eraseFluid(fluid, x, y )
    love.graphics.setCanvas(fluid.fluidLayer)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", x, y, 20, 16)
    love.graphics.setColor(1,1,1)
    love.graphics.setCanvas()
end

function getFluidDepth(fluid, x, y )
    return fluid.fluidData:getPixel(x, y)
end

function getHumidity(fluid, x, y )
    x = math.max(x, 0)
	x = math.min(x, fluid.fluidData:getWidth()-1)
	y = math.max(y, 0)
	y = math.min(y, fluid.fluidData:getHeight()-1)
    r, g, b, a = fluid.fluidData:getPixel(x, y)
    return a
end

function reloadFluid(fluid)
    local img = love.graphics.newImage(fluid.fluidData)
	love.graphics.setCanvas(fluid.fluidLayer)
	love.graphics.draw(img)
	love.graphics.setCanvas()
end