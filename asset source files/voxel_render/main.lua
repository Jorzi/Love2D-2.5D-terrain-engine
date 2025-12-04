function love.load()
    voxelShader = love.graphics.newShader("voxel.glsl")
	images = {}
	i=1
	while true do
		filename = string.format("temple_voxel_layers/%04d.png", i)
		--io.write(filename)
		if love.filesystem.isFile(filename) then
			images[i] = filename
			i = i + 1
		else
			break
		end
	end
	numberOfLayers = i-1
	volume = love.graphics.newVolumeImage(images)
	cube = generateMeshCube(volume:getWidth(), volume:getHeight(), numberOfLayers)
    rot = 0;
	testGridTex = love.graphics.newImage("testgrid.png")
	--cube:setTexture(testGridTex)

	cube:setTexture(volume)
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
    rot = rot + math.pi/180
end

function love.draw()
    love.graphics.setShader(voxelShader)
	love.graphics.setMeshCullMode("front")
    love.graphics.draw(cube, love.graphics.getWidth()/2, love.graphics.getHeight(), rot)
    love.graphics.setShader()
end