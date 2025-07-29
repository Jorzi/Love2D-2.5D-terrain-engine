function generateHeightmap()
	heightMap = love.graphics.newCanvas(mapSizeX, mapSizeY, {format = "r8"})
	heightMap:setWrap("clampzero")
	love.graphics.setCanvas(heightMap)
	local canyon = love.graphics.newImage("nile_segment_512.png")
	--love.graphics.clear(0.2, 0.2, 0.2)
	love.graphics.setColor(1, 1, 1, 0.8)
	love.graphics.draw(canyon)
	love.graphics.setCanvas()
	love.graphics.setColor(1,1,1,1)
	heightData = heightMap:newImageData()
end

function generateMasks()
	soilMap = love.graphics.newCanvas(mapSizeX, mapSizeY, {format = "r8"})
	soilMap:setWrap("clampzero")
	soilData = soilMap:newImageData()
end

function clamp(value, min, max)
	value = math.min(value, max)
	value = math.max(value, min)
	return value
end

function changeHeight_rect(x1, y1, x2, y2, delta)
	x1 = clamp(x1, 0, heightData:getWidth()-1)
	x2 = clamp(x2, 0, heightData:getWidth()-1)
	y1 = clamp(y1, 0, heightData:getHeight()-1)
	y2 = clamp(y2, 0, heightData:getHeight()-1)
	local function addHeight(x,y, r,g,b,a)
		r = r + delta/256
		return r,g,b,a
	end
	local x = math.min(x1, x2)
	local y = math.min(y1, y2)
	local width = math.abs(x1 - x2)
	local height = math.abs(y1 - y2)
	heightData:mapPixel(addHeight, x, y, width, height)
	local img = love.graphics.newImage(heightData)
	love.graphics.setCanvas(heightMap)
	love.graphics.setShader()
	love.graphics.draw(img)
	love.graphics.setCanvas()
	updateBuffers()
	recalculateHeights(x, y, x + width, y + height)
end

function changeHeight_brush(x, y, size, delta)
	local centerX = x
	local centerY = y
	local x1 = x - (size-1)
	local x2 = x + (size-1)
	local y1 = y - (size-1)
	local y2 = y + (size-1)
	x1 = clamp(x1, 0, heightData:getWidth()-1)
	x2 = clamp(x2, 0, heightData:getWidth()-1)
	y1 = clamp(y1, 0, heightData:getHeight()-1)
	y2 = clamp(y2, 0, heightData:getHeight()-1)

	local function addHeight(x,y, r,g,b,a)
		local dx = centerX-x
		local dy = centerY-y
		local dist = math.sqrt(dx*dx + dy*dy)
		local falloff = 0.5*math.cos(math.pi*dist/size)+0.5
		if dist > size then falloff = 0 end
		r = r + 0.5*(delta + 0.4*math.random() - 0.2)/256 * falloff
		return r,g,b,a
	end
	heightData:mapPixel(addHeight, x1, y1, x2-x1+1, y2-y1+1)
	local img = love.graphics.newImage(heightData)
	love.graphics.setCanvas(heightMap)
	love.graphics.setShader()
	love.graphics.draw(img)
	love.graphics.setCanvas()
	updateBuffers()
	recalculateHeights(x1, y1, x2, y2)
end

function levelHeight_rect(x1, y1, x2, y2)
	x1 = clamp(x1, 0, heightData:getWidth()-1)
	x2 = clamp(x2, 0, heightData:getWidth()-1)
	y1 = clamp(y1, 0, heightData:getHeight()-1)
	y2 = clamp(y2, 0, heightData:getHeight()-1)
	local startHeight = heightData:getPixel(x1, y1)
	local function setHeight(x,y, r,g,b,a)
		r = startHeight
		return r,g,b,a
	end
	local x = math.min(x1, x2)
	local y = math.min(y1, y2)
	local width = math.abs(x1 - x2)
	local height = math.abs(y1 - y2)
	if (height > 0 and width > 0) then
		heightData:mapPixel(setHeight, x, y, width, height)
	end
	local img = love.graphics.newImage(heightData)
	love.graphics.setCanvas(heightMap)
	love.graphics.setShader()
	love.graphics.draw(img)
	love.graphics.setCanvas()
	updateBuffers()
	recalculateHeights(x, y, x + width, y + height)
end

function levelHeight_brush(x, y, size)
	local centerX = x
	local centerY = y
	local x1 = x - (size-1)
	local x2 = x + (size-1)
	local y1 = y - (size-1)
	local y2 = y + (size-1)
	x1 = clamp(x1, 0, heightData:getWidth()-1)
	x2 = clamp(x2, 0, heightData:getWidth()-1)
	y1 = clamp(y1, 0, heightData:getHeight()-1)
	y2 = clamp(y2, 0, heightData:getHeight()-1)
	local startHeight = heightData:getPixel(x, y)

	local function addHeight(x,y, r,g,b,a)
		local dx = centerX-x
		local dy = centerY-y
		local dist = math.sqrt(dx*dx + dy*dy)
		local falloff = 0.5*math.cos(math.pi*dist/size)+0.5
		if dist > size then falloff = 0 end
		r = startHeight * falloff + r * (1-falloff)
		return r,g,b,a
	end
	heightData:mapPixel(addHeight, x1, y1, x2-x1+1, y2-y1+1)
	local img = love.graphics.newImage(heightData)
	love.graphics.setCanvas(heightMap)
	love.graphics.setShader()
	love.graphics.draw(img)
	love.graphics.setCanvas()
	updateBuffers()
	recalculateHeights(x1, y1, x2, y2)
end

function setHeight_rect(x1, y1, x2, y2, targetHeight)
	x1 = clamp(x1, 0, heightData:getWidth()-1)
	x2 = clamp(x2, 0, heightData:getWidth()-1)
	y1 = clamp(y1, 0, heightData:getHeight()-1)
	y2 = clamp(y2, 0, heightData:getHeight()-1)
	local function setHeight(x,y, r,g,b,a)
		r = targetHeight
		return r,g,b,a
	end
	local x = math.min(x1, x2)
	local y = math.min(y1, y2)
	local width = math.abs(x1 - x2)
	local height = math.abs(y1 - y2)
	heightData:mapPixel(setHeight, x, y, width, height)
	local img = love.graphics.newImage(heightData)
	love.graphics.setCanvas(heightMap)
	love.graphics.setShader()
	love.graphics.draw(img)
	love.graphics.setCanvas()
	updateBuffers()
	recalculateHeights(x, y, x + width, y + height)
end

function placeSoil(x1, y1, x2, y2)
	x1 = clamp(x1, 0, heightData:getWidth()-1)
	x2 = clamp(x2, 0, heightData:getWidth()-1)
	y1 = clamp(y1, 0, heightData:getHeight()-1)
	y2 = clamp(y2, 0, heightData:getHeight()-1)
	local function setValue(x,y, r,g,b,a)
		r = 1
		return r,g,b,a
	end
	local x = math.min(x1, x2)
	local y = math.min(y1, y2)
	local width = math.abs(x1 - x2)
	local height = math.abs(y1 - y2)
	soilData:mapPixel(setValue, x, y, width, height)
	local img = love.graphics.newImage(soilData)
	love.graphics.setCanvas(soilMap)
	love.graphics.setShader()
	love.graphics.draw(img)
	love.graphics.setCanvas()

	for i = x, x + width do
		for j = y, y + height do
			local rot = math.random() * 2*math.pi
			local chunkX = math.ceil(i/chunkSize)
			local chunkY = math.ceil(j/chunkSize)
			local varX = math.random() * 0.2 - 0.1
			local varY = math.random() * 0.2 - 0.1
			addPlant({image=cornSprite.sprite, height=getTerrainHeight(i, j), normalmap=cornSprite.normalmap, Nangles = cornSprite.Nangles, Nmoisture = cornSprite.Nmoisture}, i+varX, j+varY, rot, true)
		end
	end

end

function bridge_points(points, heightOffset)
	local startHeight = heightData:getPixel(points[0], points[1]) * 255 + heightOffset
	love.graphics.setCanvas(heightMap)
	love.graphics.setShader()
	love.graphics.setColor(startHeight/255, 0, 0, 1)
	love.graphics.line( points )
	love.graphics.setCanvas()
	love.graphics.setColor(1,1,1,1)
	heightData = heightMap:newImageData()
	updateBuffers()
end


function calculateTerrainNormals(scale)
	local nmshader = love.graphics.newShader("heightmap_normal.glsl")
	nmshader:send("res", {heightMap:getWidth()*scale, heightMap:getHeight()*scale})
	love.graphics.setCanvas(normalMap)
	love.graphics.setShader(nmshader)
	love.graphics.draw(heightMap, 0, 0, 0, scale)
	love.graphics.setShader()
	love.graphics.setCanvas()
	normalMap:setWrap("clampzero")
end

function calculateTerrainShadows()
	
	local shader = love.graphics.newShader("heightmap_shadow.glsl")
	shader:send("res", {heightMap:getWidth(), heightMap:getHeight()})
	shader:send("lightDir", {1, 1, 1})
	love.graphics.setCanvas(shadowMap)
	love.graphics.setShader(shader)
	love.graphics.draw(heightMap)
	love.graphics.setShader()
	love.graphics.setCanvas()
	shadowMap:setWrap("clampzero")
end

function calculateTerrainMasks(scale)
	local maskshader = love.graphics.newShader("terrain_masks.glsl")
	local waterEdge = love.graphics.newShader("water_edge.glsl")
	local lineBlur = love.graphics.newShader("gaussianblur_line.glsl")
	
	--maskshader:send("res", {heightMap:getWidth()*scale, heightMap:getHeight()*scale})
	--maskshader:send("normalmap", normalMap)
	--maskshader:send("waterLevel", waterLevel)
	--waterEdge:send("res", {heightMap:getWidth()*scale, heightMap:getHeight()*scale})
	waterEdge:send("waterDepth", fluidSim.tmpBuffer)
	lineBlur:send("res", {heightMap:getWidth()*scale, heightMap:getHeight()*scale})
	love.graphics.setCanvas(terrainMasks)
	love.graphics.setShader(waterEdge)
	love.graphics.draw(heightMap, 0, 0, 0, scale)

	for i = 1, 2 do --repeat the blur if needed
		love.graphics.setCanvas(terrainMasks)
		love.graphics.setShader(waterEdge)
		love.graphics.setBlendMode("lighten", "premultiplied")
		love.graphics.draw(heightMap, 0, 0, 0, scale)
		love.graphics.setBlendMode("alpha")
		lineBlur:send("res", {heightMap:getWidth()*scale/i, heightMap:getHeight()*scale/math.pow(2,i-1)})
		love.graphics.setCanvas(blur)
		love.graphics.setShader(lineBlur)
		lineBlur:send("dir", {1, 0})
		love.graphics.draw(terrainMasks)
		love.graphics.setCanvas(terrainMasks)
		lineBlur:send("dir", {0, 1})
		love.graphics.draw(blur)
	end

	love.graphics.setShader()
	love.graphics.setCanvas()
	love.graphics.setBlendMode("alpha")
	terrainMasks:setWrap("clampzero")
end

function getTerrainHeight(x, y)
	x = math.max(x, 0)
	x = math.min(x, heightData:getWidth()-1)
	y = math.max(y, 0)
	y = math.min(y, heightData:getHeight()-1)
	local xfloor = math.floor(x)
	local xfact = x - xfloor
	local xceil = math.ceil(x)
	local yfloor = math.floor(y)
	local yfact = y - yfloor
	local yceil = math.ceil(y)
	local height1 = heightData:getPixel(xfloor, yfloor)
	local height2 = heightData:getPixel(xceil, yfloor)
	local height3 = heightData:getPixel(xfloor, yceil)
	local height4 = heightData:getPixel(xceil, yceil)
	return ((height1 * (1-xfact) + height2*xfact)*(1-yfact) + (height3 * (1-xfact) + height4*xfact)*yfact)*256 -- interpolate in x and y
	--return height1 * 256
end

function maxValueMipMap(image)
	local n = image:getMipmapCount()
	for i = 1 , n-1 do
		love.graphics.setCanvas(image, n+1)
		love.graphics.draw(image)
	end
end