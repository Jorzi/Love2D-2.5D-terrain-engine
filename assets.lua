
function initAssetList()
    assetList = {}
    assetList.bufferResX = 2048
    assetList.bufferResY = 2048
    assetList.diffuseBuffer = love.graphics.newCanvas(assetList.bufferResX, assetList.bufferResY)
    assetList.lightBuffer = love.graphics.newCanvas(assetList.bufferResX, assetList.bufferResY)

    globalSpritebatchShader = love.graphics.newShader("global_spritebatch_object.glsl")
    globalSpritebatchShader:send("normalMap", assetList.lightBuffer)
    globalSpritebatchShadowShader = love.graphics.newShader("global_spritebatch_shadow.glsl")

    spritestackToSpriteShader = love.graphics.newShader("spritestack_to_sprite.glsl")
    spritestackToSpriteShadowShader = love.graphics.newShader("spritestack_to_sprite_shadow.glsl")
    voxelToSpriteShader = love.graphics.newShader("voxel_to_sprite.glsl")
    voxelToSpriteShadowShader = love.graphics.newShader("voxel_to_sprite_shadow.glsl")
    
    --globalSpritebatchShader:send("cameraRot", camera.rot)
    screenObjectBuffer = love.graphics.newSpriteBatch(assetList.diffuseBuffer, 4000, "stream")
    screenShadowBuffer = love.graphics.newSpriteBatch(assetList.lightBuffer, 4000, "stream")
    --[[ local vertexFormat = {
        {"VertexPosition", "float", 3},
    }
    screenObjectMesh = love.graphics.newMesh(vertexFormat, 4000, "triangles", "stream" )
    screenObjectWorldPositions = {} ]]

    --assetList.palm1 = loadAssetSpritestack("textures/palm1.json", "textures/palm1.png", "textures/palm1_nor.png", 8, 4)
	assetList.pine1 = loadAssetSpritestack("textures/pine1.json", "textures/pine1_transp.png", "textures/pine1_nor.png", 8, 8)
	assetList.bush1 = loadAssetSpritestack("textures/bush1.json", "textures/bush1.png", "textures/bush1_nor.png", 8, 8)
	assetList.corn1 = loadAssetSpritestack("textures/corn1.json", "textures/corn1.png", "textures/corn1_nor.png", 16, 1)
	assetList.birch1 = loadAssetSpritestack("textures/birch1.json", "textures/birch1.png", "textures/birch1_nor.png", 8, 8)
	assetList.small_hut1 = loadAssetSpritestack("textures/small_hut1.json", "textures/small_hut1.png", "textures/small_hut1_nor.png", 8, 1)
    assetList.dude1 = loadAssetVoxel("asset source files/dude1.vox", 16, 1)
    assetList.hut2 = loadAssetVoxel("asset source files/hut2.vox", 8, 1)
    assetList.walkingDude1 = loadAnimatedAssetVoxel({
        idle={"asset source files/dude1.vox"}, 
        moving={"asset source files/dude1_walk-frame1.vox", "asset source files/dude1_walk-frame2.vox"}
    }, 16, 1)
    io.write(dump(assetList.walkingDude1))
    generateDynamicSpritesheet()
    redrawAssets()
end

function loadAssetSpritestack(filePath, texturePath, normalmapPath, Nangles, Nmoisture)
    local asset = {}
    asset.type = "spritestack"
    asset.Nangles = Nangles
    asset.Nmoisture = Nmoisture
    asset.texture = love.graphics.newImage(texturePath)
    asset.normalmap = love.graphics.newImage(normalmapPath)
    asset.texture:setWrap("clamp")
	asset.texture:setFilter("nearest")
    asset.normalmap:setWrap("clamp")
	asset.normalmap:setFilter("nearest")
    asset.drawable = loadSpriteStack(filePath, asset.texture)
    return asset
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

function loadAssetVoxel(filePath, Nangles, scale)
    local asset = {}
    asset.type = "voxel"
    asset.Nangles = Nangles
    asset.Nmoisture = 1 --no moisture implementation yet
    asset.texture = textureFromVox(filePath)
    asset.normalmap = generateVoxelNormalsAndAO(asset.texture)
    asset.texture:setWrap("clamp")
	asset.texture:setFilter("nearest")
    asset.normalmap:setWrap("clamp")
	asset.normalmap:setFilter("nearest")
    asset.drawable = generateMeshCube(asset.texture:getWidth()*scale, asset.texture:getHeight()*scale, asset.texture:getDepth()*scale)
    return asset
end
--animFileList example: {idle={"frame1.vox", "frame2.vox", "frame3.vox"}, walk={"frame1.vox", "frame2.vox", "frame3.vox"}}
function loadAnimatedAssetVoxel(animFileList, Nangles, scale)
    local asset = {}
    asset.type = "voxelAnim"
    asset.states = {}
    for k, v in pairs(animFileList) do
        table.insert(asset.states, k)
        asset[k] = {}
        for i = 1, #v do
            asset[k][i] = loadAssetVoxel(v[i], Nangles, scale)
        end
    end
    return asset
end

function textureFromVox(path)
    local Vox_model   = require("asset source files/voxel_render/vox_model")
	local Vox_texture3D = require("asset source files/voxel_render/vox_texture3d")
    local file = love.filesystem.newFile(path)
    file:open("r")
		local model = Vox_model.new(file:read())
	file:close()
	local texture = Vox_texture3D.new(model)
    return texture
end

--asset = {width, height, type, drawable}
function allocateSpriteArea(asset, bp)
    for i = 1, asset.Nangles do
        for j = 1, asset.Nmoisture do
            local angle = 2 * math.pi / asset.Nangles * (i-1)
            local width, height, anchorX, anchorY = getDimensions(asset.drawable, asset.type, angle)
            local rect = bp:insert(width, height)
            --put all data as numerical indices directly in the list entry for faster drawing of quads
            local index = i + (j-1)*asset.Nangles
            local Nsprites = asset.Nangles * asset.Nmoisture
            asset[index] = love.graphics.newQuad(rect.x, rect.y, width, height, assetList.diffuseBuffer)
            asset[index + Nsprites] = anchorX
            asset[index + 2 * Nsprites] = anchorY
        end
    end
end
function generateDynamicSpritesheet()
	local binpack_new = require('binpack')
	local bp = binpack_new(assetList.bufferResX, assetList.bufferResY)
	for k, v in pairs(assetList) do
        if type(v) == "table" and v.type then
            if v.type == "voxelAnim" then
                for _, state in pairs(v.states) do
                    for _, frame in pairs(v[state]) do
                        allocateSpriteArea(frame, bp)
                    end
                end
            else
                allocateSpriteArea(v, bp)
            end
        end
	end
end

function getDimensions(drawable, type, angle)
    if type == "spritestack" then
        local maxRadiusSquared = 0
        local maxHeight = 0
        for i = 1, drawable:getVertexCount( ) do
            local x, y, u, v, r = drawable:getVertex(i)
            local rSquared = x*x + y*y
            maxRadiusSquared = math.max(maxRadiusSquared, rSquared)
            maxHeight = math.max(maxHeight, r)
        end
        local maxRadius = math.sqrt(maxRadiusSquared)
        return 2*maxRadius, maxHeight*256 + maxRadius, maxRadius, maxHeight*256 + maxRadius/2
    end
    if type == "voxel" then
        local maxRadiusSquared = 0
        local maxHeight = 0
        for i = 1, drawable:getVertexCount( ) do
            local x, y, z = drawable:getVertex(i)
            local rSquared = x*x + y*y
            maxRadiusSquared = math.max(maxRadiusSquared, rSquared)
            maxHeight = math.max(maxHeight, z)
        end
        local maxRadius = math.sqrt(maxRadiusSquared)
        return 2*maxRadius, maxHeight + maxRadius, maxRadius, maxHeight + maxRadius/2
    end
end

function drawAsset(asset)
    local function clearQuad(x, y, width, height)
        love.graphics.setShader()
        love.graphics.setBlendMode("replace")
        love.graphics.setCanvas(assetList.diffuseBuffer)
        love.graphics.setColor(0,0,0,0)
        love.graphics.rectangle("fill", x, y, width, height)
        --Debug: draw frames of sprites
        --love.graphics.setColor(0,0,0,1)
        --love.graphics.rectangle("line", x, y, width, height)
        love.graphics.setCanvas(assetList.lightBuffer)
        love.graphics.setColor(0,0,0,1)
        love.graphics.rectangle("fill", x, y, width, height)
        love.graphics.setColor(1,1,1,1)
    end
    local function drawVoxel(asset)
        voxelToSpriteShader:send("volume_nor", asset.normalmap)
            voxelToSpriteShader:send("volume", asset.texture)
            voxelToSpriteShader:send("cameraRot", camera.rot)
            voxelToSpriteShader:send("size", {asset.texture:getWidth(), asset.texture:getHeight(), asset.texture:getDepth()})
            voxelToSpriteShadowShader:send("volume", asset.texture)
            voxelToSpriteShadowShader:send("size", {asset.texture:getWidth(), asset.texture:getHeight(), asset.texture:getDepth()})
            for i = 1, asset.Nangles do
                for j = 1, asset.Nmoisture do
                    local index = i + (j-1)*asset.Nangles
                    local Nsprites = asset.Nangles * asset.Nmoisture
                    local x, y, width, height = asset[index]:getViewport()
                    local objectRot = (i-1) * math.pi*2 / asset.Nangles
                    clearQuad(x, y, width, height)
                    love.graphics.setCanvas({assetList.diffuseBuffer, assetList.lightBuffer})
                    love.graphics.setShader(voxelToSpriteShader)
                    love.graphics.setBlendMode("alpha")
                    love.graphics.setMeshCullMode("front")
                    x = x + asset[index + Nsprites] --X anchor
                    y = y + asset[index + 2*Nsprites] --Y anchor
                    love.graphics.draw(asset.drawable, x, y, objectRot) --draw sprite
                    love.graphics.setShader(voxelToSpriteShadowShader)
                    love.graphics.setBlendMode("add")
                    love.graphics.draw(asset.drawable, x, y, objectRot + math.rad(45)) --draw sprite
                end
            end
    end
    if type(asset) == "table" and asset.type then
        if asset.type == "spritestack" then
            spritestackToSpriteShader:send("normalMap", asset.normalmap)
            spritestackToSpriteShader:send("cameraRot", camera.rot)
            for i = 1, asset.Nangles do
                for j = 1, asset.Nmoisture do
                    local index = i + (j-1)*asset.Nangles
                    local Nsprites = asset.Nangles * asset.Nmoisture
                    spritestackToSpriteShader:send("objectRot", (i-1) * math.pi*2 / asset.Nangles)
                    spritestackToSpriteShader:send("humidity", math.pow(j/asset.Nmoisture, 2))
                    spritestackToSpriteShadowShader:send("objectRot", (i-1) * math.pi*2 / asset.Nangles)
                    spritestackToSpriteShadowShader:send("humidity", math.pow(j/asset.Nmoisture, 2))
                    local x, y, width, height = asset[index]:getViewport()
                    clearQuad(x, y, width, height)
                    love.graphics.setCanvas({assetList.diffuseBuffer, assetList.lightBuffer})
                    love.graphics.setShader(spritestackToSpriteShader)
                    love.graphics.setBlendMode("alpha")
                    x = x + asset[index + Nsprites] --X anchor
                    y = y + asset[index + 2*Nsprites] --Y anchor
                    love.graphics.draw(asset.drawable, x, y) --draw sprite
                    love.graphics.setShader(spritestackToSpriteShadowShader)
                    love.graphics.setBlendMode("add")
                    love.graphics.draw(asset.drawable, x, y) --draw sprite
                end
            end
        elseif asset.type == "voxel" then
            drawVoxel(asset)
        elseif asset.type == "voxelAnim" then
            for _, state in pairs(asset.states) do
                for _, frame in pairs(asset[state]) do
                    drawVoxel(frame)
                end
            end
        end
        love.graphics.setCanvas()
        love.graphics.setBlendMode("alpha")
        love.graphics.setShader()
    end
end

function redrawAssets()
    for k, v in pairs(assetList) do
		drawAsset(v)
	end
end

--animCycle is a number between 0 and 1 that determines how far the animation has progressed
--returns Quad, anchorX, anchorY
function getAssetSprite(name, angle, moisture, state, animCycle)
    local asset = assetList[name]
    if asset.type == "voxelAnim" then
        local frame = math.floor(animCycle * #asset[state]) + 1
        asset = asset[state][frame]
    end
    _, angle = math.modf(angle/(2*math.pi))
    local angleIndex = math.floor(angle * asset.Nangles)
    local moistureIndex = math.max(math.ceil(moisture * asset.Nmoisture) - 1, 0)
    local index = 1 + angleIndex + asset.Nangles*(moistureIndex)
    local Nsprites = asset.Nangles * asset.Nmoisture
    --io.write(string.format("%f, %f\n", angleIndex, moistureIndex))
    return asset[index], asset[index + Nsprites], asset[index + 2*Nsprites]
end


function generateVoxelNormalsAndAO(volume)
	local filter = volume:getFilter()
	volume:setWrap("clampzero")
	volume:setFilter("linear")
	local normalMap = love.graphics.newCanvas(volume:getWidth(), volume:getHeight(), {format="rgba8"})
	local volumeNormalsAO = love.graphics.newShader("asset source files/voxel_render/volume_normals_ao.glsl")
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