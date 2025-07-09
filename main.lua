json = require "json"
mapSizeX = 512
mapSizeY = 512
mapGridScale = 10 --screen pixels per map texel
grid_density = 0.5 -- vertices per pixel for screen grid
mouseState = {StartX = 0, StartY = 0}
editState = {toolStrength = 1, activeTool = "none", placementRot = 0}
chunkSize = 64;

love.filesystem.load("fluid.lua")()
love.filesystem.load("terrain.lua")()
love.filesystem.load("unit.lua")()
love.filesystem.load("decal.lua")()
love.filesystem.load("mapgrid.lua")()

function love.load()
	love.window.setMode(love.graphics.getWidth(), love.graphics.getHeight(),
		{resizable=true, msaa=4})
	

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
	initializeBuffers()
	generateRandomTrees(3000)
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
	palm1 = love.graphics.newImage("textures/palm1.png")
	palm1:setWrap("clamp")
	palm1:setFilter("nearest")
	palm1_nor = love.graphics.newImage("textures/palm1_nor.png")
	palm1_nor:setWrap("clamp")
	palm1_nor:setFilter("nearest")
	pine1 = love.graphics.newImage("textures/pine1_transp.png")
	pine1:setWrap("clamp")
	pine1:setFilter("nearest")
	pine1_nor = love.graphics.newImage("textures/pine1_nor.png")
	pine1_nor:setWrap("clamp")
	pine1_nor:setFilter("nearest")
	small_hut1 = love.graphics.newImage("textures/small_hut1.png")
	small_hut1:setWrap("clamp")
	small_hut1:setFilter("nearest")
	small_hut1_nor = love.graphics.newImage("textures/small_hut1_nor.png")
	small_hut1_nor:setWrap("clamp")
	small_hut1_nor:setFilter("nearest")
	bush1 = love.graphics.newImage("textures/bush1.png")
	bush1:setWrap("clamp")
	bush1:setFilter("nearest")
	bush1_nor = love.graphics.newImage("textures/bush1_nor.png")
	bush1_nor:setWrap("clamp")
	bush1_nor:setFilter("nearest")
	birch1 = love.graphics.newImage("textures/birch1.png")
	birch1:setWrap("clamp")
	birch1:setFilter("nearest")
	birch1_nor = love.graphics.newImage("textures/birch1_nor.png")
	birch1_nor:setWrap("clamp")
	birch1_nor:setFilter("nearest")
	corn1 = love.graphics.newImage("textures/corn1.png")
	corn1:setWrap("clamp")
	corn1:setFilter("nearest")
	corn1_nor = love.graphics.newImage("textures/corn1_nor.png")
	corn1_nor:setWrap("clamp")
	corn1_nor:setFilter("nearest")
	road_tiles = love.graphics.newImage("textures/road_tiles.png")
	road_tiles:setWrap("clamp")
	road_tiles:setFilter("nearest")
	voxelpalm = loadSpriteStack("textures/palm1.json", palm1)
	voxelpine = loadSpriteStack("textures/pine1.json", pine1)
	voxelbush = loadSpriteStack("textures/bush1.json", bush1)
	voxelcorn = loadSpriteStack("textures/corn1.json", corn1)
	voxelbirch = loadSpriteStack("textures/birch1.json", birch1)

	peasant_worker_col = love.graphics.newImage("textures/peasant_worker_col.png")
	peasant_worker_nor = love.graphics.newImage("textures/peasant_worker_nor.png")
	peasant_worker = newUnit("textures/peasant_worker_col.json", peasant_worker_col, peasant_worker_nor)
end

function initializeBuffers()
	local img = love.graphics.newImage(heightData)
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
	local building = loadSpriteStack("textures/small_hut1.json", small_hut1)
	rot = rot + math.random() * 0.1 - 0.05
	addBuilding({image=building, height=height * 256, normalmap=small_hut1_nor}, x, y, rot, false)
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
			addPlant({image=voxelbirch, height=getTerrainHeight(x, y), normalmap=birch1_nor}, x, y, rot, false)
		elseif i % 3 == 1 then
			addPlant({image=voxelpine, height=getTerrainHeight(x, y), normalmap=pine1_nor}, x, y, rot, false)
		else
			addPlant({image=voxelbush, height=getTerrainHeight(x, y), normalmap=bush1_nor}, x, y, rot, true)
		end
	end
end

function recalculateHeights(x1, y1, x2, y2)
	for i = x1, x2 do
		for j = y1, y2 do
			if getObject(i, j) then
				getObject(i, j).object.height = getTerrainHeight(i, j)
			end
		end
	end
end


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
	if love.mouse.isDown(1) then
		if editState.activeTool == "changeHeight_brush" then
			changeHeight_brush(cursorX, cursorY, 5, editState.toolStrength)
		elseif editState.activeTool == "levelHeight_brush" then
			levelHeight_brush(cursorX, cursorY, 5)
		elseif editState.activeTool == "place_road" then
			addRoad(cursorX, cursorY)
		end
	end	
	text_out:set(string.format("Rot: %.3f rad, FPS = %d, cursor = %d, %d, r/f: raise/lower water, t/g: increase/decrease tool strength", camera.rot, love.timer.getFPS( ), cursorX, cursorY))
	text_out:add(string.format("Active tool: %s Tool strength: %d (1: changeHeight_rect, 2: levelHeight_rect, esc: deselect)", editState.activeTool, editState.toolStrength), 0, 20)
	gameTime = gameTime + dt
	terrainShader:send("time", gameTime)

	updateFluid(fluidSim)
	calculateTerrainMasks(bufferScale)
	updatePlants(dt)
end

function love.mousepressed( x, y, button, istouch, presses )
	if editState.activeTool == "changeHeight_rect" or editState.activeTool == "levelHeight_rect" or editState.activeTool == "place_soil" then
		if button == 1 then
			mouseState.startX = x
			mouseState.startY = y
		end
	end
end

function love.mousereleased(x, y, button)
	if editState.activeTool == "changeHeight_rect" or editState.activeTool == "levelHeight_rect" or editState.activeTool == "place_soil" then
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
			addUnit(peasant_worker, x2, y2, editState.placementRot)
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
	decalShader:send("rot", camera.rot)
end

function love.keypressed(key, u)
	if key == "t" then
		editState.toolStrength = editState.toolStrength + 1;
	end
	if key == "g" then
		editState.toolStrength = editState.toolStrength - 1;
	end
	if key == "r" then
		editState.placementRot = editState.placementRot + math.pi/2;
		editState.placementRot = math.mod(editState.placementRot, math.pi*2);
	end
	if key == "escape" then
		editState.activeTool = 'none';
	end
	if key == "1" then
		editState.activeTool = 'changeHeight_brush';
	end
	if key == "2" then
		editState.activeTool = 'levelHeight_brush';
	end
	if key == "3" then
		editState.activeTool = 'ditch';
	end
	if key == "4" then
		editState.activeTool = 'wall';
	end
	if key == "5" then
		editState.activeTool = 'place_building';
	end
	if key == "6" then
		editState.activeTool = 'place_soil';
	end
	if key == "7" then
		editState.activeTool = 'place_road';
	end
	if key == "8" then
		editState.activeTool = 'place_unit';
	end
end

function love.resize(w, h)
	love.window.setMode(w, h, {resizable=true, msaa=4})
	initializeBuffers()
end

function love.draw()
	local spriteCount = 0
	--define camera window
	local screenRadius = 120
	local minX, maxX = math.floor(camera.x)-screenRadius, math.floor(camera.x)+screenRadius
	local minY, maxY = math.floor(camera.y)-screenRadius, math.floor(camera.y)+screenRadius
	--draw shadows
	love.graphics.setCanvas(objectShadows)
	love.graphics.clear(1,1,1,1)
	love.graphics.setColor(1,1,1,1)
	for i = minX, maxX do
		for j = minY, maxY do
			if(getObject(i, j)) then
				local object = getObject(i, j)
				love.graphics.setShader(spritestackShadowShader)
				spritestackShadowShader:send("objectRot", object.rot)
				spritestackShadowShader:send("humidity", getHumidity(fluidSim, object.x, object.y))
				local x, y = spriteVertexTransform(object.x, object.y, camera.rot, camera.x, camera.y)
				love.graphics.draw(object.object.image, x, y, 0, 1, 1, 0, 0) --draw sprite
				spriteCount = spriteCount + 1
			end
			if getUnit(i, j) then
				local unit = getUnit(i, j)
				love.graphics.setShader(spriteShadowShader)
				local x, y = spriteVertexTransform(unit.x, unit.y, camera.rot, camera.x, camera.y)
				drawUnit(unit.unit, x, y, unit.rot+math.pi/4, camera.rot)
				spriteCount = spriteCount + 1
			end
		end
	end

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
	local function drawSpritestack(j, i)
		if(getObject(j, i)) then
			local object = getObject(j, i)
			love.graphics.setShader(spritestackShader)
			love.graphics.setColor(1,1,1,1)
			spritestackShader:send("objectRot", object.rot)
			spritestackShader:send("humidity", getHumidity(fluidSim, object.x, object.y))
			spritestackShader:send("objectWorldPos", {object.x/mapSizeX, object.y/mapSizeY, object.object.height/256})
			spritestackShader:send("normalMap", object.object.normalmap)
			local x, y = spriteVertexTransform(object.x, object.y, camera.rot, camera.x, camera.y)
			y = y - object.object.height * mapGridScale / 2 --displace current sprite according to its height value
			local margin = 100
			if x < 0-margin or x > love.graphics.getWidth() + margin or y < 0-margin or y > love.graphics.getHeight() + margin then return end
			love.graphics.draw(object.object.image, x, y, 0, 1, 1, 0, 0) --draw sprite
		end
	end
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
			drawSpritestack(i, j)
			drawSprite(i, j)
			i, j = i + rowStep[1], j + rowStep[2]
		end
		i_start, j_start = i_start + columnStep1[1], j_start + columnStep1[2]
	end
	if (columnStep2) then
		i_start, j_start = i_start - columnStep1[1], j_start - columnStep1[2] -- back up one step
		while i_start >= minX and i_start <= maxX and j_start >= minY and j_start <= maxY do
			i, j = i_start, j_start
			while i >= minX and i <= maxX and j >= minY and j <= maxY do
				drawSpritestack(i, j)
				drawSprite(i, j)
				i, j = i + rowStep[1], j + rowStep[2]
			end
			i_start, j_start = i_start + columnStep2[1], j_start + columnStep2[2]
		end
	end


	love.graphics.setShader()
	love.graphics.setColor(1,1,1,1)
	
	--overlays
	text_out:add(string.format("Sprites on screen: %d, sector: %d", spriteCount, sector), 0, 40)
	--text_out:add(dump(buildings), 0, 60)
	local minimapSize = 256
	love.graphics.draw(normalMap, 0, 0, 0, 1/normalMap:getWidth()*minimapSize)
	love.graphics.draw(fluidSim.tmpBuffer, 0, 0, 0, 1/fluidSim.tmpBuffer:getWidth()*minimapSize)
	love.graphics.circle( "fill", camera.x/mapSizeX*minimapSize, camera.y/mapSizeY*minimapSize, 2 )
	love.graphics.draw(text_out)
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
	spriteShader:send("normalMap", peasant_worker.normalmap)
	drawUnit(peasant_worker, x, y, 0, camera.rot)
	love.graphics.setShader()
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