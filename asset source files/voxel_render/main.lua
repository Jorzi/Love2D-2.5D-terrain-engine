function love.load()
    voxelShader = love.graphics.newShader("voxel.glsl")
	--images = {}
	--images_nor = {}
	--[[ i=1
	while true do
		filename = string.format("test_scene/%04d.png", i)
		--filename_nor = string.format("temple1_nor/%04d.png", i)
		--io.write(filename)
		if love.filesystem.isFile(filename) then
			images[i] = filename
			--images_nor[i] = filename_nor
			i = i + 1
		else
			break
		end
	end
	numberOfLayers = i-1
	local settings = {}
	settings.mipmaps = true
	volume = love.graphics.newVolumeImage(images, settings) ]]
	Vox_model   = require("vox_model")
	Vox_texture3D = require("vox_texture3d")
	volume = newFromVox("village_hub_merge.vox")
	volume:setFilter("nearest")
	volume:setWrap("clamp")
	volume_nor = generateVoxelNormalsAndAO(volume)
	volume_nor:setFilter("nearest")
	volume_nor:setWrap("clamp")
	cubeScale = 3
	cube = generateMeshCube(volume:getWidth()*cubeScale, volume:getHeight()*cubeScale, volume:getDepth()*cubeScale)
    rot = 0;
	voxelShader:send("volume", volume)
	voxelShader:send("volume_nor", volume_nor)
	voxelShader:send("size", {volume:getWidth(), volume:getHeight(), volume:getDepth()})
	cube:setTexture(volume)

	viewAngle = math.rad(60)
	font = love.graphics.getFont()
	text_out = love.graphics.newText(font)	
end

function newFromVox(path)
   local file = love.filesystem.newFile(path)
   file:open("r")
		local model = Vox_model.new(file:read())
	file:close()
	--io.write(dump(model))
	local texture = Vox_texture3D.new(model)
   return texture
end

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

function generateVoxelNormals(volume)
	volume:setWrap("clampzero")
	local normalMap = love.graphics.newCanvas(volume:getWidth(), volume:getHeight(), {format="rgba8"})
	local volumeNormals = love.graphics.newShader("volume_normals.glsl")
	volumeNormals:send("volume", volume)
	local numberOfLayers = volume:getDepth()
	volumeNormals:send("size", {volume:getWidth(), volume:getHeight(), numberOfLayers})
	local vertices = {
		{0,0,0,0},
		{volume:getWidth(),0,1,0},
		{volume:getWidth(),volume:getHeight(),1,1},
		{0,volume:getHeight(),0,1},
	}
	local mesh = love.graphics.newMesh(vertices)
	local images = {}
	for i=1,numberOfLayers do
		volumeNormals:send("zcoord", (i-0.5)/numberOfLayers)
		love.graphics.setCanvas(normalMap)
		love.graphics.clear( )
		love.graphics.setShader(volumeNormals)
		love.graphics.draw(mesh)
		love.graphics.setCanvas()
		love.graphics.setShader()
		data = normalMap:newImageData()
		images[i] = data
	end
	return love.graphics.newVolumeImage(images)
end

function generateVoxelAO(volume)
	local filter = volume:getFilter()
	volume:setWrap("clampzero")
	volume:setFilter("linear")
	local sliceCanvas = love.graphics.newCanvas(volume:getWidth(), volume:getHeight(), {format="r8"})
	local voxelAO = love.graphics.newShader("voxel_ao.glsl")
	voxelAO:send("volume", volume)
	local numberOfLayers = volume:getDepth()
	voxelAO:send("size", {volume:getWidth(), volume:getHeight(), numberOfLayers})
	--voxelAO:send("maxLOD", 4)
	local vertices = {
		{0,0,0,0},
		{volume:getWidth(),0,1,0},
		{volume:getWidth(),volume:getHeight(),1,1},
		{0,volume:getHeight(),0,1},
	}
	local mesh = love.graphics.newMesh(vertices)
	local images = {}
	for i=1,numberOfLayers do
		voxelAO:send("zcoord", (i-0.5)/numberOfLayers)
		love.graphics.setCanvas(sliceCanvas)
		love.graphics.clear( )
		love.graphics.setShader(voxelAO)
		love.graphics.draw(mesh)
		love.graphics.setCanvas()
		love.graphics.setShader()
		data = sliceCanvas:newImageData()
		images[i] = data
	end
	volume:setFilter(filter)
	return love.graphics.newVolumeImage(images)
end

function generateVoxelNormalsAndAO(volume)
	local filter = volume:getFilter()
	volume:setWrap("clampzero")
	volume:setFilter("linear")
	local normalMap = love.graphics.newCanvas(volume:getWidth(), volume:getHeight(), {format="rgba8"})
	local volumeNormalsAO = love.graphics.newShader("volume_normals_ao.glsl")
	volumeNormalsAO:send("volume", volume)
	local numberOfLayers = volume:getDepth()
	volumeNormalsAO:send("size", {volume:getWidth(), volume:getHeight(), numberOfLayers})
	local vertices = {
		{0,0,0,0},
		{volume:getWidth(),0,1,0},
		{volume:getWidth(),volume:getHeight(),1,1},
		{0,volume:getHeight(),0,1},
	}
	local mesh = love.graphics.newMesh(vertices)
	local images = {}
	for i=1,numberOfLayers do
		volumeNormalsAO:send("zcoord", (i-0.5)/numberOfLayers)
		love.graphics.setCanvas(normalMap)
		love.graphics.clear( )
		love.graphics.setShader(volumeNormalsAO)
		love.graphics.setBlendMode("replace", "premultiplied")
		love.graphics.draw(mesh)
		love.graphics.setCanvas()
		love.graphics.setShader()
		love.graphics.setBlendMode("alpha")
		data = normalMap:newImageData()
		images[i] = data
	end
	volume:setFilter(filter)
	return love.graphics.newVolumeImage(images)
end

function generateMeshCube(width, depth, height)
	local vertexformat = {
        {"VertexPosition", "float", 3}, -- The x,y position of each vertex.
        {"VertexTexCoord", "float", 3} -- The u,v texture coordinates of each vertex.
    }
    local vertices = {
		{
			-width/2, -depth/2, 0, -- position of the vertex
			0, 0, 0 -- texture coordinate at the vertex position
		},
		{
			width/2, -depth/2, 0, -- position of the vertex
			1, 0, 0 -- texture coordinate at the vertex position
		},
		{
			width/2, depth/2, 0, -- position of the vertex
			1, 1, 0 -- texture coordinate at the vertex position
		},
		{
			-width/2, depth/2, 0, -- position of the vertex
			0, 1, 0 -- texture coordinate at the vertex position
		},
        {
			-width/2, -depth/2, height, -- position of the vertex
			0, 0, 1 -- texture coordinate at the vertex position
		},
		{
			width/2, -depth/2, height, -- position of the vertex
			1, 0, 1 -- texture coordinate at the vertex position
		},
		{
			width/2, depth/2, height, -- position of the vertex
			1, 1, 1 -- texture coordinate at the vertex position
		},
		{
			-width/2, depth/2, height, -- position of the vertex
			0, 1, 1 -- texture coordinate at the vertex position
		},
	}
    local vertexMap = {
        3, 2, 1, --bottom
        1, 4, 3, --bottom
        5, 6, 7, --top
        7, 8, 5, --top
        1, 2, 6,
        6, 5, 1,
        4, 1, 5,
        5, 8, 4,
        3, 4, 8,
        8, 7, 3,
        2, 3, 7,
        7, 6, 2
    }

    cube = love.graphics.newMesh(vertexformat, vertices, "triangles", "static")
    cube:setVertexMap(vertexMap)
	return cube
end

function love.update(dt)
    rot = rot + math.pi/360
	if love.keyboard.isDown("r") then
		viewAngle = viewAngle - math.rad(1)
	elseif love.keyboard.isDown("f") then
		viewAngle = viewAngle + math.rad(1)
	end
	voxelShader:send("viewAngle", viewAngle)
end

function love.draw()
    love.graphics.setShader(voxelShader)
	love.graphics.setMeshCullMode("front")
	for i = 1,1 do
    	love.graphics.draw(cube, love.graphics.getWidth()/2, love.graphics.getHeight()/2 + 100, rot+i)
	end
    love.graphics.setShader()
	text_out:set(string.format("viewAngle: %.3f rad, FPS = %d r/f: change view angle", viewAngle, love.timer.getFPS( )))
	text_out:add(string.format("Number of mipmap levels: %d", volume:getMipmapCount()), 0, 20)
	love.graphics.draw(text_out)
end