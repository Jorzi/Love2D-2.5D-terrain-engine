json = require "json"
mapSizeX = 512
mapSizeY = 512
mapGridScale = 10 --screen pixels per map texel
grid_density = 0.5 -- vertices per pixel for screen grid
mouseState = {startX = 0, startY = 0, GUIClick = false}
editState = {toolStrength = 1, activeTool = "none", placementRot = 0, radius = 5}
chunkSize = 64;

love.filesystem.load("fluid.lua")()
love.filesystem.load("terrain.lua")()
love.filesystem.load("unit.lua")()
love.filesystem.load("decal.lua")()
love.filesystem.load("mapgrid.lua")()
love.filesystem.load("gui.lua")()
love.filesystem.load("assets.lua")()
love.filesystem.load("customSpriteBatch.lua")()

function love.load()
	love.window.setMode(love.graphics.getWidth(), love.graphics.getHeight(),
		{resizable=true, msaa=4})
	love.profiler = require('profile') 
	--love.profiler.start()

	generateHeightmap()
	generateMasks()
	initializeMapGrid()
	gridSizeX = love.graphics.getWidth()
	gridSizeY = love.graphics.getHeight() + 256 * mapGridScale / 2
	gameTime = 0

	
	camera = {rot=math.rad(135), x=0, y=0}
	font = love.graphics.getFont()
	text_out = love.graphics.newText(font)	
	terrainGeomShader = love.graphics.newShader("terrain_geombuffer.glsl")
	terrainShader = love.graphics.newShader("terrain.glsl")
	loadTextures()
	spritestackToSpriteShader = love.graphics.newShader("spritestack_to_sprite.glsl")
	spritestackToSpriteShader:send("cameraRot", camera.rot)
	initAssetList()
	terrainGeomShader:send("rot", camera.rot)
	terrainGeomShader:send("zscale", mapGridScale/2)
	--terrainGeomShader:send("mapSize", {mapSizeX, mapSizeY})

	terrainShader:send("cliffTex", cliffTex)
	terrainShader:send("grassTex", grassTex)
	terrainShader:send("sandTex", sandTex)
	terrainShader:send("soilTex", soilTex)
	terrainShader:send("worldSize", {mapSizeX, mapSizeY})

	spritestackShader = love.graphics.newShader("spritestack_object.glsl")
	spritestackShader:send("cameraRot", camera.rot)
	spritestackShadowShader = love.graphics.newShader("spritestack_object_shadow.glsl")
	spritestackShadowShader:send("cameraRot", camera.rot)
	spriteShader = love.graphics.newShader("sprite_object.glsl")
	decalShader = love.graphics.newShader("decal.glsl")
	decalShader:send("rot", camera.rot)
	decalShader:send("zscale", mapGridScale/2)
	spriteShadowShader = love.graphics.newShader("sprite_object_shadow.glsl")
	spriteShadowShader:send("cameraRot", camera.rot)
	
	dynamicSpriteShader = love.graphics.newShader("dynamic_sprite_object.glsl")
	dynamicSpriteShader:send("cameraRot", camera.rot)
	dynamicSpriteShadowShader = love.graphics.newShader("dynamic_sprite_object_shadow.glsl")
	dynamicSpriteShadowShader:send("cameraRot", camera.rot)
	minimapShader = love.graphics.newShader("minimap.glsl")
	initializeBuffers()
	generateRandomTrees(10000)
	loadGui()
end

function loadSpriteStack(filename, image)
	local contents = love.filesystem.read(filename)
	local data = json.decode(contents)
	--io.write(dump(data.frames["0001.png"]))
	local i = 1
	vertices = {}
	while data.frames[string.format("%04d", i)] do
		--io.write(dump(data.frames[string.format("%04d.png", i)]))
		--io.write(string.format("%d\n", i))
		local sprite = data.frames[string.format("%04d", i)]
		-- centered vertex coordinates
		x1 = sprite.spriteSourceSize.x - sprite.sourceSize.w / 2
		x2 = (sprite.spriteSourceSize.x + sprite.spriteSourceSize.w) - sprite.sourceSize.w / 2
		y1 = sprite.spriteSourceSize.y - sprite.sourceSize.h / 2
		y2 = (sprite.spriteSourceSize.y + sprite.spriteSourceSize.h) - sprite.sourceSize.h / 2
		-- normalized texture coordinates 
		u1 = sprite.frame.x / image:getWidth()
		u2 = (sprite.frame.x + sprite.frame.w) / image:getWidth()
		v1 = sprite.frame.y / image:getHeight()
		v2 = (sprite.frame.y + sprite.frame.h) / image:getHeight()
		--first triangle
		table.insert(vertices, {x1, y1, u1, v1, i/256,1,1})
		table.insert(vertices, {x2, y1, u2, v1, i/256,1,1})
		table.insert(vertices, {x1, y2, u1, v2, i/256,1,1})
		--second triangle
		table.insert(vertices, {x2, y1, u2, v1, i/256,1,1})
		table.insert(vertices, {x2, y2, u2, v2, i/256,1,1})
		table.insert(vertices, {x1, y2, u1, v2, i/256,1,1})
		i = i + 1
	end
	local spritestack = love.graphics.newMesh(vertices, "triangles", "static")
	spritestack:setTexture(image)
	return spritestack
end
function prerenderSpritestack(mesh, normalmap, Nangles, Nmoisture, canvas, normalCanvas)
	
	local maxRadiusSquared = 0
	local maxHeight = 0
	for i = 1, mesh:getVertexCount( ) do
		local x, y, u, v, r = mesh:getVertex(i)
		local rSquared = x*x + y*y
		maxRadiusSquared = math.max(maxRadiusSquared, rSquared)
		maxHeight = math.max(maxHeight, r)
	end
	local maxRadius = math.sqrt(maxRadiusSquared)
	if not canvas or not normalCanvas then
		canvas = love.graphics.newCanvas( 2* maxRadius * Nangles, (maxHeight*256 + maxRadius) * Nmoisture, {format="rgba8"})
		normalCanvas = love.graphics.newCanvas( 2* maxRadius * Nangles, (maxHeight*256 + maxRadius) * Nmoisture, {format="rgba8"})
		canvas:setWrap("repeat")
		normalCanvas:setWrap("repeat")
	end
	local SpriteObject = {}
    SpriteObject.normalmap = normalCanvas
	SpriteObject.Nangles = Nangles
	SpriteObject.Nmoisture = Nmoisture
	-- centered vertex coordinates (origin at bottom center of bounding cylinder)
	local x1 = -maxRadius
	local x2 = maxRadius
	local y1 = -maxHeight*256-maxRadius/2
	local y2 = maxRadius/2
	-- normalized texture coordinates 
	local u1 = 0
	local u2 = 1/Nangles
	local v1 = 0
	local v2 = 1/Nmoisture
	local vertices = {}
	table.insert(vertices, {x1, y1, u1, v1, 1,1,1})
	table.insert(vertices, {x2, y1, u2, v1, 1,1,1})
	table.insert(vertices, {x2, y2, u2, v2, 1,1,1})
	table.insert(vertices, {x1, y2, u1, v2, 1,1,1})
	SpriteObject.sprite = love.graphics.newMesh(vertices)
	SpriteObject.sprite:setTexture(canvas)

	love.graphics.setShader(spritestackToSpriteShader)
	spritestackToSpriteShader:send("normalMap", normalmap)
	spritestackToSpriteShader:send("cameraRot", camera.rot)
	love.graphics.setColor(1,1,1,1)
	love.graphics.setCanvas(canvas)
	love.graphics.clear()
	love.graphics.setCanvas(normalCanvas)
	love.graphics.clear()
	for i = 1, Nangles do
		for j = 1, Nmoisture do
			love.graphics.setCanvas({canvas, normalCanvas})
			spritestackToSpriteShader:send("objectRot", (i-1) * math.pi*2 / Nangles)
			spritestackToSpriteShader:send("humidity", math.pow(j/Nmoisture, 2))
			local x, y = maxRadius + 2* maxRadius * (i-1), j*(maxHeight*256 + maxRadius) - maxRadius/2
			love.graphics.draw(mesh, x, y) --draw sprite
		end
	end
	love.graphics.setCanvas()
	return canvas, normalCanvas, SpriteObject
end

-- debug function for displaying contents of anything as text
function dump(o)
	if type(o) == 'table' then
	   local s = '{ '
	   for k,v in pairs(o) do
		  if type(k) ~= 'number' then k = '"'..k..'"' end
		  s = s .. '['..k..'] = ' .. dump(v) .. ','
	   end
	   return s .. '} '
	else
	   return tostring(o)
	end
end

function loadTextures()

	sandTex = love.graphics.newImage("textures/wavy-sand_albedo.png")
	sandTex:setWrap("repeat")
	cliffTex = love.graphics.newImage("textures/Canyon_Rock_001_COLOR.jpg")
	cliffTex:setWrap("repeat")
	grassTex = love.graphics.newImage("textures/Ground03_col.jpg")
	grassTex:setWrap("repeat")
	soilTex = love.graphics.newImage("textures/Ground048_2K-PNG_Color.png")
	soilTex:setWrap("repeat")
	road_tiles = love.graphics.newImage("textures/road_tiles.png")
	road_tiles:setWrap("clamp")
	road_tiles:setFilter("nearest")
	assets = {}

	peasant_worker_col = love.graphics.newImage("textures/peasant_worker_col.png")
	peasant_worker_nor = love.graphics.newImage("textures/peasant_worker_nor.png")
	assets.peasant_worker = newUnit("textures/peasant_worker_col.json", peasant_worker_col, peasant_worker_nor, "peasant_worker")
end


function initializeBuffers()
	local img = love.graphics.newImage(heightData)
	love.graphics.setColor(1,1,1,1)
	love.graphics.setCanvas(heightMap)
	love.graphics.setShader()
	love.graphics.draw(img)
	img = love.graphics.newImage(soilData)
	love.graphics.setCanvas(soilMap)
	love.graphics.draw(img)
	love.graphics.setCanvas()
	bufferScale = 2

	local sourceSinks = {
		{level=0.17, x=128, y=mapSizeY-3, width=320, height=3},
		{level=0.00, x=0, y=0, width=mapSizeX, height=3}
	}
	if not fluidSim then
		fluidSim = initializeFluid(heightMap, 0.1, sourceSinks)
	else
		reloadFluid(fluidSim)
	end
	terrainShader:send("waterDepth", fluidSim.tmpBuffer)
	terrainGeomShader:send("waterDepth", fluidSim.tmpBuffer)
	minimapShader:send("fluidsim", fluidSim.tmpBuffer)
	

	normalMap = love.graphics.newCanvas(heightMap:getWidth()*bufferScale, heightMap:getHeight()*bufferScale, {format="rgba8"})
	shadowMap = love.graphics.newCanvas(heightMap:getWidth(), heightMap:getHeight(), {format="r8"})
	outline = love.graphics.newCanvas(heightMap:getWidth()*bufferScale, heightMap:getHeight()*bufferScale, {format="r16f"})
	blur = love.graphics.newCanvas(heightMap:getWidth()*bufferScale, heightMap:getHeight()*bufferScale, {format="r16f"})
	terrainMasks = love.graphics.newCanvas(heightMap:getWidth()*bufferScale, heightMap:getHeight()*bufferScale, {format="rgba16f"})
	geomBuffer = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight(), {format="rgba16f"})
	updateBuffers()
	terrainGeomShader:send("heightmap", heightMap)
	terrainShader:send("shadowmap", shadowMap)
	terrainShader:send("normalmap", normalMap)
	terrainShader:send("terrainMasks", terrainMasks)
	terrainShader:send("soilmap", soilMap)
	spritestackShader:send("shadowmap", shadowMap)
	spritestackShader:send("screenSize", {love.graphics.getWidth(), love.graphics.getHeight()})
	terrainGeomShader:send("screenSize", {love.graphics.getWidth(), love.graphics.getHeight() + 256 * mapGridScale / 2})
	spritestackShader:send("geomBuffer", geomBuffer)
	spriteShader:send("shadowmap", shadowMap)
	spriteShader:send("screenSize", {love.graphics.getWidth(), love.graphics.getHeight()})
	spriteShader:send("geomBuffer", geomBuffer)
	decalShader:send("heightmap", heightMap)
	decalShader:send("shadowmap", shadowMap)
	decalShader:send("normalmap", normalMap)
	decalShader:send("geomBuffer", geomBuffer)
	decalShader:send("screenSize", {love.graphics.getWidth(), love.graphics.getHeight()})
	dynamicSpriteShader:send("shadowmap", shadowMap)
	dynamicSpriteShader:send("screenSize", {love.graphics.getWidth(), love.graphics.getHeight()})
	dynamicSpriteShader:send("geomBuffer", geomBuffer)
	globalSpritebatchShader:send("shadowmap", shadowMap)
	globalSpritebatchShader:send("screenSize", {love.graphics.getWidth(), love.graphics.getHeight()})
	globalSpritebatchShader:send("geomBuffer", geomBuffer)
	gridSizeX = love.graphics.getWidth()
	gridSizeY = love.graphics.getHeight() + 256 * mapGridScale / 2
	screenGrid = generateScreenGridMesh(math.floor(gridSizeX * grid_density), math.floor(gridSizeY * grid_density))
	--testGrid, testGrid2 = generateWorldGridMesh(chunkSize*2, chunkSize*2)
	objectShadows = love.graphics.newCanvas(gridSizeX, gridSizeY, {format="r8"})
	terrainGeomShader:send("objectShadows", objectShadows)
	--screenGrid:setTexture(sandTex)
end
function updateBuffers()
	-- buffers operate directly on global canvases to avoid reassigning them on the gpu
	calculateTerrainNormals(bufferScale)
	calculateTerrainShadows()
end



function place_building(x, y, rot)
	local height = heightData:getPixel(x, y)
	addBuilding("small_hut1", x, y, rot, false)
	setHeight_rect(x-3, y-2, x+3, y+2, height)
end


function generateScreenGridMesh(resX, resY)
	local stepX = gridSizeX / resX
	local stepY = gridSizeY / resY
	local vertices = {}
	for j = 0, resY do
		for i = 0, resX do
			table.insert(vertices, {i * stepX, j * stepY, i/resX, j/resY, 1,1,1})
		end
	end
	local vertexMap = {}
	for j = 1, resY do
		for i = 1, resX do
			-- form a quad out of two triangles
			pos = i + (j-1)*(resX+1)
			table.insert(vertexMap, pos)
			table.insert(vertexMap, pos+1)
			table.insert(vertexMap, pos+resX+1)
			
			table.insert(vertexMap, pos+1)
			table.insert(vertexMap, pos+resX+2)
			table.insert(vertexMap, pos+resX+1)
		end
	end
	local Grid = love.graphics.newMesh(vertices, "triangles", "static")
	Grid:setVertexMap(vertexMap)
	vertexCount = Grid:getVertexCount()
	return Grid
end

function generateWorldGridMesh(resX, resY)
	local stepX = mapGridScale 
	local stepY = mapGridScale 
	local vertices = {}
	for j = 0, resY do
		for i = 0, resX do
			table.insert(vertices, {i * stepX, j * stepY, i/resX, j/resY, 1,1,1})
		end
	end
	local vertexMap = {}
	for j = 1, resY do
		for i = 1, resX do
			-- form a quad out of two triangles
			pos = i + (j-1)*(resX+1)
			table.insert(vertexMap, pos)
			table.insert(vertexMap, pos+1)
			table.insert(vertexMap, pos+resX+1)
			
			table.insert(vertexMap, pos+1)
			table.insert(vertexMap, pos+resX+2)
			table.insert(vertexMap, pos+resX+1)
		end
	end
	local Grid = love.graphics.newMesh(vertices, "triangles", "static")
	Grid:setVertexMap(vertexMap)
	local vertices2 = {}
	for j = resY, 0, -1 do
		for i = resX, 0, -1 do
			table.insert(vertices2, {i * stepX, j * stepY, i/resX, j/resY, 1,1,1})
		end
	end
	local Grid2 = love.graphics.newMesh(vertices2, "triangles", "static")
	Grid2:setVertexMap(vertexMap)
	return Grid, Grid2
end

function generateRandomTrees(n)
	for i = 1, n do
		local x = math.random() * mapSizeX
		local y = math.random() * mapSizeY
		local rot = math.random() * 2 * math.pi
		if i % 3 == 0 then
			addPlant("birch1", x, y, rot)
		elseif i % 3 == 1 then
			addPlant("pine1", x, y, rot)
		else
			addPlant("bush1", x, y, rot)
		end
		--addUnit(peasant_worker, x, y, rot)
	end
end

function recalculateHeights(x1, y1, x2, y2)
	for i = x1, x2 do
		for j = y1, y2 do
			if getObject(i, j) then
				getObject(i, j).height = getTerrainHeight(i, j)
			end
		end
	end
end

love.frame = 0
function love.update(dt)
	cameraspeed = 50 -- map texels per second
	if love.keyboard.isDown('s') then
		camera.x = camera.x + cameraspeed * dt * -math.sin(camera.rot)
		camera.y = camera.y + cameraspeed * dt * math.cos(camera.rot)
	end
	if love.keyboard.isDown('w') then
		camera.x = camera.x + cameraspeed * dt * math.sin(camera.rot)
		camera.y = camera.y + cameraspeed * dt * -math.cos(camera.rot)
	end
	if love.keyboard.isDown('d') then
		camera.x = camera.x + cameraspeed * dt * math.cos(camera.rot)
		camera.y = camera.y + cameraspeed * dt * math.sin(camera.rot)
	end
	if love.keyboard.isDown('a') then
		camera.x = camera.x + cameraspeed * dt * -math.cos(camera.rot)
		camera.y = camera.y + cameraspeed * dt * -math.sin(camera.rot)
	end
	cameraShaderTransform(camera.x, camera.y)
	cursorX, cursorY = mouseWorldPosition(love.mouse.getPosition())
	if love.mouse.isDown(1) and not mouseState.GUIClick then
		if editState.activeTool == "changeHeight_brush" then
			changeHeight_brush(cursorX, cursorY, editState.radius, editState.toolStrength)
		elseif editState.activeTool == "levelHeight_brush" then
			levelHeight_brush(cursorX, cursorY, editState.radius)
		elseif editState.activeTool == "place_road" then
			addRoad(cursorX, cursorY)
		elseif editState.activeTool == "delete_brush" then
			delete_brush(cursorX, cursorY, editState.radius)
		end
	end	
	text_out:set(string.format("Rot: %.3f rad, FPS = %d, cursor = %d, %d, r/f: raise/lower water, t/g: increase/decrease tool strength", camera.rot, love.timer.getFPS( ), cursorX, cursorY))
	text_out:add(string.format("Active tool: %s Tool strength: %d (1: changeHeight_rect, 2: levelHeight_rect, esc: deselect)", editState.activeTool, editState.toolStrength), 0, 20)
	gameTime = gameTime + dt
	terrainShader:send("time", gameTime)

	updateFluid(fluidSim)
	calculateTerrainMasks(bufferScale)
	updatePlants(dt)
	love.frame = love.frame + 1
	--[[ if love.frame%100 == 0 then
		love.report = love.profiler.report(20)
		io.write(love.report)
		love.profiler.reset()
	end ]]
	luis.update(dt)
end

function love.mousepressed( x, y, button, istouch, presses )
	if luis.mousepressed(x, y, button, istouch) then
		mouseState.GUIClick = true
		return
	elseif editState.activeTool == "changeHeight_rect" or editState.activeTool == "levelHeight_rect" or editState.activeTool == "place_soil" then
		if button == 1 then
			mouseState.startX = x
			mouseState.startY = y
		end
	end
	
end

function love.mousereleased(x, y, button, isTouch)
	if luis.mousereleased(x, y, button, istouch) or mouseState.GUIClick then
		io.write("GUI Click!\n")
		mouseState.GUIClick = false
		return
	elseif editState.activeTool == "changeHeight_rect" or editState.activeTool == "levelHeight_rect" or editState.activeTool == "place_soil" then
		if button == 1 then
			local x1, y1 = mouseWorldPosition(mouseState.startX, mouseState.startY)
			local x2, y2 = mouseWorldPosition(x, y)
			if editState.activeTool == "changeHeight_rect" then
				changeHeight_rect(x1, y1, x2, y2, editState.toolStrength)
			elseif editState.activeTool == "levelHeight_rect" then
				levelHeight_rect(x1, y1, x2, y2)
			elseif editState.activeTool == "place_soil" then
				placeSoil(x1, y1, x2, y2)
			end
		end
	elseif editState.activeTool == "place_building" then
		if button == 1 then
			local x2, y2 = mouseWorldPosition(x, y)
			place_building(x2, y2, editState.placementRot)
		end
	elseif editState.activeTool == "place_unit" then
		if button == 1 then
			local x2, y2 = mouseWorldPosition(x, y)
			addUnit(assets.peasant_worker, x2, y2, editState.placementRot)
		end
	end
	
end

function love.wheelmoved(x, y)
	camera.rot = camera.rot + math.rad(3*y)
	while camera.rot < 0 do
		camera.rot = camera.rot + 2*math.pi
	end
	terrainGeomShader:send("rot", camera.rot)
	spritestackShader:send("cameraRot", camera.rot)
	spritestackShadowShader:send("cameraRot", camera.rot)
	spriteShadowShader:send("cameraRot", camera.rot)
	dynamicSpriteShader:send("cameraRot", camera.rot)
	dynamicSpriteShadowShader:send("cameraRot", camera.rot)
	--globalSpritebatchShader:send("cameraRot", camera.rot)
	decalShader:send("rot", camera.rot)
	redrawAssets()
end

function love.keypressed(key, scancode, isrepeat)
	luis.keypressed(key, scancode, isrepeat)
	if key == "t" then
		editState.toolStrength = editState.toolStrength + 1
	end
	if key == "g" then
		editState.toolStrength = editState.toolStrength - 1
	end
	if key == "r" then
		editState.placementRot = editState.placementRot + math.pi/4
		editState.placementRot = math.mod(editState.placementRot, math.pi*2)
	end
	if key == "escape" then
		editState.activeTool = 'none'
	end
	if key == "1" then
		editState.activeTool = 'changeHeight_brush'
	end
	if key == "2" then
		editState.activeTool = 'levelHeight_brush'
	end
	if key == "3" then
		editState.activeTool = 'ditch'
	end
	if key == "4" then
		editState.activeTool = 'wall'
	end
	if key == "5" then
		editState.activeTool = 'place_building'
	end
	if key == "6" then
		editState.activeTool = 'place_soil'
	end
	if key == "7" then
		editState.activeTool = 'place_road'
	end
	if key == "8" then
		editState.activeTool = 'place_unit'
	end
end

function love.keyreleased(key, scancode)
	luis.keyreleased( key, scancode )
end

function love.resize(w, h)
	love.window.setMode(w, h, {resizable=true, msaa=4})
	initializeBuffers()
	resizeGuiLayout()
	redrawAssets()
end

function love.draw()
	local spriteCount = 0
	--define camera window
	local cameraSizeX = 1/mapGridScale * gridSizeX/2
	local cameraSizeY = 1/mapGridScale * gridSizeY
	local screenRadius = math.ceil(math.sqrt(cameraSizeX*cameraSizeX*0.2 + cameraSizeY*cameraSizeY*0.2))
	--screenRadius = 120
	local minX, maxX = math.floor(camera.x)-screenRadius, math.floor(camera.x)+screenRadius
	local minY, maxY = math.floor(camera.y)-screenRadius, math.floor(camera.y)+screenRadius
	local fluidData = fluidSim.fluidData
	--update shadow and object sprite batches
	screenShadowBuffer:clear()
	screenObjectBuffer:clear()
	local function drawObject(j, i)
		if(getObject(j, i)) then
			local object = getObject(j, i)
			local sprite, anchorX, anchorY = getAssetSprite(object.name, object.rot, object.humidity)
			local x, y = spriteVertexTransform(object.x, object.y, camera.rot, camera.x, camera.y)
			y_screen = y - object.height * mapGridScale / 2 --displace current sprite according to its height value
			local _, _, marginX, marginY = sprite:getViewport();
			marginX = math.max(marginX, 2*marginY) --account for shadow rotation
			if x < 0-marginX or x > love.graphics.getWidth() + marginX or y_screen < 0-marginY or y_screen > love.graphics.getHeight() + marginY then return end
			screenObjectBuffer:setColor(object.x/mapSizeX, object.y/mapSizeY, object.height/255, 1)
			screenObjectBuffer:add(sprite, x-anchorX, y_screen-anchorY)
			--shadow
			local angle = camera.rot + math.rad(45)
			local xRot, yRot = 2*anchorY * math.sin(angle) + anchorX * math.cos(angle), 2*anchorY * math.cos(angle) - anchorX * math.sin(angle)
			screenShadowBuffer:add(sprite, x-xRot, 2*y-yRot, -angle, 1, 2)
			spriteCount = spriteCount + 1
		end
	end
	local sector = math.floor(math.fmod(camera.rot, math.pi*2)/(math.pi*2) * 16)
	local loopConditions = {}
	loopConditions[0] = {i_start = maxX, j_start = minY, columnStep1 = {0, 1}, rowStep = {-1, 0}}
	loopConditions[1] = {i_start = maxX, j_start = minY, columnStep1 = {-1, 0}, columnStep2 = {0, 1}, rowStep = {1, 1}}
	loopConditions[2] = {i_start = maxX, j_start = minY, columnStep1 = {0, 1}, columnStep2 = {-1, 0}, rowStep = {-1, -1}}
	loopConditions[3] = {i_start = maxX, j_start = minY, columnStep1 = {-1, 0}, rowStep = {0, 1}}
	loopConditions[4] = {i_start = maxX, j_start = maxY, columnStep1 = {-1, 0}, rowStep = {0, -1}}
	loopConditions[5] = {i_start = maxX, j_start = maxY, columnStep1 = {0, -1}, columnStep2 = {-1, 0}, rowStep = {-1, 1}}
	loopConditions[6] = {i_start = maxX, j_start = maxY, columnStep1 = {-1, 0}, columnStep2 = {0, -1}, rowStep = {1, -1}}
	loopConditions[7] = {i_start = maxX, j_start = maxY, columnStep1 = {0, -1}, rowStep = {-1, 0}}
	loopConditions[8] = {i_start = minX, j_start = maxY, columnStep1 = {0, -1}, rowStep = {1, 0}}
	loopConditions[9] = {i_start = minX, j_start = maxY, columnStep1 = {1, 0}, columnStep2 = {0, -1}, rowStep = {-1, -1}}
	loopConditions[10] = {i_start = minX, j_start = maxY, columnStep1 = {0, -1}, columnStep2 = {1, 0}, rowStep = {1, 1}}
	loopConditions[11] = {i_start = minX, j_start = maxY, columnStep1 = {1, 0}, rowStep = {0, -1}}
	loopConditions[12] = {i_start = minX, j_start = minY, columnStep1 = {1, 0}, rowStep = {0, 1}}
	loopConditions[13] = {i_start = minX, j_start = minY, columnStep1 = {0, 1}, columnStep2 = {1, 0}, rowStep = {1, -1}}
	loopConditions[14] = {i_start = minX, j_start = minY, columnStep1 = {1, 0}, columnStep2 = {0, 1}, rowStep = {-1, 1}}
	loopConditions[15] = {i_start = minX, j_start = minY, columnStep1 = {0, 1}, rowStep = {1, 0}}
	local i_start, j_start, columnStep1, columnStep2, rowStep = loopConditions[sector].i_start, loopConditions[sector].j_start, loopConditions[sector].columnStep1, loopConditions[sector].columnStep2, loopConditions[sector].rowStep
	while i_start >= minX and i_start <= maxX and j_start >= minY and j_start <= maxY do
		i, j = i_start, j_start
		while i >= minX and i <= maxX and j >= minY and j <= maxY do
			drawObject(i, j)
			--drawSprite(i, j)
			i, j = i + rowStep[1], j + rowStep[2]
		end
		i_start, j_start = i_start + columnStep1[1], j_start + columnStep1[2]
	end
	if (columnStep2) then
		i_start, j_start = i_start - columnStep1[1], j_start - columnStep1[2] -- back up one step
		while i_start >= minX and i_start <= maxX and j_start >= minY and j_start <= maxY do
			i, j = i_start, j_start
			while i >= minX and i <= maxX and j >= minY and j <= maxY do
				drawObject(i, j)
				--drawSprite(i, j)
				i, j = i + rowStep[1], j + rowStep[2]
			end
			i_start, j_start = i_start + columnStep2[1], j_start + columnStep2[2]
		end
	end
	
	--draw shadows
	love.graphics.setCanvas(objectShadows)
	love.graphics.clear(1,1,1,1)
	love.graphics.setColor(1,1,1,1)
	love.graphics.setShader(globalSpritebatchShadowShader)
	love.graphics.draw(screenShadowBuffer)

	--draw terrain
	love.graphics.setCanvas(geomBuffer)
	love.graphics.clear()
	love.graphics.setBlendMode('replace', 'premultiplied')
	love.graphics.setShader(terrainGeomShader)
	love.graphics.setMeshCullMode('front')
	--love.graphics.setWireframe( true )
	love.graphics.draw(screenGrid)
	--love.graphics.setWireframe( false )
	love.graphics.setMeshCullMode('none')
	love.graphics.setBlendMode('alpha')
	love.graphics.setCanvas()
	love.graphics.setShader(terrainShader)
	love.graphics.draw(geomBuffer)

	-- draw decals
	love.graphics.setShader(decalShader)
	--love.graphics.setColor(0.8, 0.7, 0.6, 1)
	for i = minX, maxX do
		for j = minY, maxY do
			if getDecal(i, j) then
				--io.write(string.format("roadCoords %f, %f\n", i, j))
				local x, y = spriteVertexTransform(i, j, camera.rot, camera.x, camera.y)
				decalShader:send("spriteRot", getDecal(i, j).rot)
				love.graphics.draw(getDecal(i, j).mesh, x, y)
			end
		end
	end
	love.graphics.setColor(1,1,1,1)

	--draw objects
	local function drawSprite(j, i)
		if(getUnit(j, i)) then
			local unit = getUnit(j, i)
			love.graphics.setColor(1,1,1,1)
			love.graphics.setShader(spriteShader)
			spriteShader:send("objectRot", unit.rot)
			local height = getTerrainHeight(unit.x, unit.y)
			spriteShader:send("objectWorldPos", {unit.x/mapSizeX, unit.y/mapSizeY, height/256})
			spriteShader:send("normalMap", unit.unit.normalmap)
			local x, y = spriteVertexTransform(unit.x, unit.y, camera.rot, camera.x, camera.y)
			y = y - height * mapGridScale / 2 --displace current sprite according to its height value
			local margin = 100
			if x < 0-margin or x > love.graphics.getWidth() + margin or y < 0-margin or y > love.graphics.getHeight() + margin then return end
			drawUnit(unit.unit, x, y, unit.rot, camera.rot) --draw sprite
		end
	end

	love.graphics.setShader(globalSpritebatchShader)
	love.graphics.setColor(1,1,1,1)
	love.graphics.setBlendMode("alpha", "premultiplied")
	love.graphics.draw(screenObjectBuffer)
	love.graphics.setBlendMode("alpha")
	love.graphics.setShader()
	
	--overlays
	text_out:add(string.format("Sprites on screen: %d, sector: %d", spriteCount, sector), 0, 40)
	text_out:add(string.format("Tool radius: %f", editState.radius), 0, 60)
	--text_out:add(dump(buildings), 0, 60)
	local minimapSize = 256
	love.graphics.setShader(minimapShader)
	love.graphics.draw(normalMap, 0, 0, 0, 1/normalMap:getWidth()*minimapSize)
	love.graphics.setShader()
	drawMinimapObjects(minimapSize)
	love.graphics.setColor(1,1,1,1)
	love.graphics.circle( "fill", camera.x/mapSizeX*minimapSize, camera.y/mapSizeY*minimapSize, 2 )
	love.graphics.draw(text_out)
	--love.graphics.draw(assetList.lightBuffer, 0, 256, 0, 0.5)
	--love.graphics.print(love.report or "Please wait...", 0, 60)
	--highlight active tile
	local z1 = getTerrainHeight(cursorX-0.5, cursorY-0.5)
	local z2 = getTerrainHeight(cursorX+0.5, cursorY-0.5) 
	local z3 = getTerrainHeight(cursorX+0.5, cursorY+0.5) 
	local z4 = getTerrainHeight(cursorX-0.5, cursorY+0.5) 
	x1, y1 = spriteVertexTransform(cursorX-0.5, cursorY-0.5, camera.rot, camera.x, camera.y)
	x2, y2 = spriteVertexTransform(cursorX+0.5, cursorY-0.5, camera.rot, camera.x, camera.y)
	x3, y3 = spriteVertexTransform(cursorX+0.5, cursorY+0.5, camera.rot, camera.x, camera.y)
	x4, y4 = spriteVertexTransform(cursorX-0.5, cursorY+0.5, camera.rot, camera.x, camera.y)
	local vertices = {
		{x1, y1 - z1 * mapGridScale / 2},
		{x2, y2 - z2 * mapGridScale / 2},
		{x3, y3 - z3 * mapGridScale / 2},
		{x4, y4 - z4 * mapGridScale / 2},
	}
	--love.graphics.line(x, y, x, y - z * mapGridScale / 2)
	local activeQuad = love.graphics.newMesh(vertices, "fan")
	love.graphics.draw(activeQuad)
	local x, y = love.mouse.getPosition()
	love.graphics.setShader(spriteShader)
	spriteShader:send("objectRot", 0)
	local worldX, worldY = mouseWorldPosition(x, y)
	spriteShader:send("objectWorldPos", {worldX/mapSizeX, worldY/mapSizeY, getTerrainHeight(worldX, worldY)/256})
	spriteShader:send("normalMap", assets.peasant_worker.normalmap)
	drawUnit(assets.peasant_worker, x, y, 0, camera.rot)
	love.graphics.setShader()
	luis.draw()
	love.graphics.setColor(1,1,1,1)
end


function cameraVertexTransform(vx, vy, rot, x, y)
	local scaleX = 1/(mapSizeX * mapGridScale)
	local scaleY = 1/(mapSizeY * mapGridScale)
	local x1 = vx * love.graphics.getWidth()/2 * scaleX
	local y1 = vy * love.graphics.getHeight() * scaleY
	local x2 = x1 * math.cos(rot) - y1 * math.sin(rot)
	local y2 = x1 * math.sin(rot) + y1 * math.cos(rot)
	local x2 = x2 + x / mapSizeX
	local y2 = y2 + y / mapSizeY
	return x2, y2
end

function spriteVertexTransform(vx, vy, rot, cameraX, cameraY)
	local x1 = (vx - cameraX) * mapGridScale
	local y1 = (vy - cameraY) * mapGridScale
	local x2 = x1 * math.cos(-rot) - y1 * math.sin(-rot)
	local y2 = x1 * math.sin(-rot) + y1 * math.cos(-rot)
	x2 = x2 * 2 + gridSizeX/2
	y2 = y2 + gridSizeY/2
	return x2, y2
end

function screenToWorldVertexTransform(vx, vy, rot, cameraX, cameraY)
	vx = vx - gridSizeX/2
	vy = vy - gridSizeY/2
	local x1 = vx / mapGridScale / 2
	local y1 = vy / mapGridScale
	local x2 = x1 * math.cos(rot) - y1 * math.sin(rot)
	local y2 = x1 * math.sin(rot) + y1 * math.cos(rot)
	local x2 = x2 + cameraX
	local y2 = y2 + cameraY
	return x2, y2
end

function mouseWorldPosition(screenX, screenY)
	local projX, projY = screenToWorldVertexTransform(screenX, screenY, camera.rot, camera.x, camera.y)
	local dist = 128
	local dirX = math.cos(camera.rot - math.pi / 2)
	local dirY = math.sin(camera.rot - math.pi / 2)
	local x = projX - dirX * dist
	local y = projY - dirY * dist
	local z = 256
	--return math.floor(x+0.5), math.floor(y+0.5)
 	while true do
		local height = getTerrainHeight(x, y)
		if height >= z then
			return math.floor(x+0.5), math.floor(y+0.5)
		end
		x = x + dirX
		y = y + dirY
		z = z - 2
	end
end
	
function cameraShaderTransform(x, y)
	local scaleX = 1/(mapSizeX * mapGridScale) * gridSizeX/2
	local scaleY = 1/(mapSizeY * mapGridScale) * (gridSizeY)
	terrainGeomShader:send("cameraSize", {scaleX, scaleY})
	terrainGeomShader:send("pos", {x / mapSizeX, y / mapSizeY})
	terrainShader:send("cameraPos", {x / mapSizeX, y / mapSizeY})
	decalShader:send("pos", {x / mapSizeX, y / mapSizeY})
	decalShader:send("cameraSize", {scaleX, scaleY})
	--terrainGeomShader:send("pos", {x , y })
end

function saveGame(name)
	local mapList = {}
	for k, v in pairs(mapGrid) do
		local intX, intY = math.mod(k, mapSizeX), math.floor(k/mapSizeX)
		local row = {}
		row.intX = intX
		row.intY = intY
		if v.decal then
			row.decal = {decalType = v.decal.decalType, rot = v.decal.rot}
		end
		if v.object then
			row.object = {name = v.object.name, objectType = v.object.objectType, x=v.object.x, y=v.object.y, rot=v.object.rot, drowning = v.object.drowning, blockerList = v.object.blockerList}
		end
		if v.unit then
			row.unit = {name = v.unit.name, x=v.unit.x, y=v.unit.y, rot=v.unit.rot}
		end
		if row.decal or row.object or row.unit then
			table.insert(mapList, row)
		end
	end
	love.filesystem.write(string.format("%s_objectlist.json", name), json.encode(mapList))
	love.filesystem.write(string.format("%s_fluiddata", name), fluidSim.fluidData:getString())
	love.filesystem.write(string.format("%s_heightdata", name), heightData:getString())
	love.filesystem.write(string.format("%s_soildata", name), soilData:getString())
	love.filesystem.write(string.format("%s_sourcesinks.json", name), json.encode(fluidSim.sourceSinks))
	love.filesystem.write(string.format("%s.save", name), "")
end

function loadGame(name)
	--local dir = love.filesystem.getSaveDirectory()
	local data = love.filesystem.read(string.format("%s_heightdata", name))
	local width, height = heightData:getDimensions()
	heightData = love.image.newImageData(width, height, heightData:getFormat(), data)

	data = love.filesystem.read(string.format("%s_soildata", name))
	width, height = soilData:getDimensions()
	soilData = love.image.newImageData(width, height, soilData:getFormat(), data)

	data = love.filesystem.read(string.format("%s_fluiddata", name))
	width, height = fluidSim.fluidData:getDimensions()
	fluidSim.fluidData = love.image.newImageData(width, height, fluidSim.fluidData:getFormat(), data)

	initializeBuffers()
	fluidSim.sourceSinks = json.decode(love.filesystem.read(string.format("%s_sourcesinks.json", name)))
	local contents = love.filesystem.read(string.format("%s_objectlist.json", name))
	local mapList = json.decode(contents)
	initializeMapGrid()
	for k, v in ipairs(mapList) do
		if v.decal then
			if v.decal.decalType == "road" then
				addRoad(v.intX, v.intY)
			end
		end
		if v.object then
			if v.object.objectType == "plant" then
				local assetName = v.object.name
				addPlant(assetName, v.object.x, v.object.y, v.object.rot, v.object.blockerList)
			else if v.object.objectType == "building" then
				local assetName = v.object.name
				addBuilding(assetName, v.object.x, v.object.y, v.object.rot)
			end
		end
		if v.unit then
			local unit = assets[v.unit.name]
			addUnit(unit, v.unit.x, v.unit.y, v.unit.rot)
		end
	end
end
end

function love.textinput(text)
    luis.textinput(text)
end