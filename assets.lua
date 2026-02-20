
function initAssetList()
    assetList = {}
    assetList.bufferResX = 2048
    assetList.bufferResY = 2048
    assetList.diffuseBuffer = love.graphics.newCanvas(assetList.bufferResX, assetList.bufferResY)
    assetList.lightBuffer = love.graphics.newCanvas(assetList.bufferResX, assetList.bufferResY)
    voxelShader = love.graphics.newShader("asset source files/voxel_render/voxel.glsl")
    globalSpritebatchShader = love.graphics.newShader("global_spritebatch_object.glsl")
    globalSpritebatchShader:send("normalMap", assetList.lightBuffer)
    screenObjectBuffer = love.graphics.newSpriteBatch(assetList.diffuseBuffer, 4000, "stream")

    --assetList.palm1 = loadAssetSpritestack("textures/palm1.json", "textures/palm1.png", "textures/palm1_nor.png", 8, 4)
	assetList.pine1 = loadAssetSpritestack("textures/pine1.json", "textures/pine1_transp.png", "textures/pine1_nor.png", 8, 1)
	assetList.bush1 = loadAssetSpritestack("textures/bush1.json", "textures/bush1.png", "textures/bush1_nor.png", 8, 1)
	assetList.corn1 = loadAssetSpritestack("textures/corn1.json", "textures/corn1.png", "textures/corn1_nor.png", 16, 1)
	assetList.birch1 = loadAssetSpritestack("textures/birch1.json", "textures/birch1.png", "textures/birch1_nor.png", 8, 1)
	assetList.small_hut1 = loadAssetSpritestack("textures/small_hut1.json", "textures/small_hut1.png", "textures/small_hut1_nor.png", 4, 1)
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



--asset = {width, height, type, drawable}
function generateDynamicSpritesheet()
	local binpack_new = require('binpack')
	local bp = binpack_new(assetList.bufferResX, assetList.bufferResY)
	for k, v in pairs(assetList) do
        if type(v) == "table" and v.type then
            for i = 1, v.Nangles do
                for j = 1, v.Nmoisture do
                    local angle = 2 * math.pi / v.Nangles * (i-1)
                    local width, height, anchorX, anchorY = getDimensions(v.drawable, v.type, angle)
                    local rect = bp:insert(width, height)
                    --put all data as numerical indices directly in the list entry for faster drawing of quads
                    local index = i + (j-1)*v.Nmoisture
                    local Nsprites = v.Nangles * v.Nmoisture
                    v[index] = love.graphics.newQuad(rect.x, rect.y, width, height, assetList.diffuseBuffer)
                    v[index + Nsprites] = anchorX
                    v[index + 2 * Nsprites] = anchorY
                end
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
    elseif type == "voxel" then
        local radius = math.sqrt(drawable.width*drawable.width + drawable.height*drawable.height)
        local zHeight = drawable.depth
        return 2*radius, zHeight + radius, radius, zHeight + radius/2
    end
end

function drawAsset(asset)
    if type(asset) == "table" and asset.type then
        if asset.type == "spritestack" then
            spritestackToSpriteShader:send("normalMap", asset.normalmap)
            spritestackToSpriteShader:send("cameraRot", camera.rot)
            love.graphics.setCanvas({assetList.diffuseBuffer, assetList.lightBuffer})
            for i = 1, asset.Nangles do
                for j = 1, asset.Nmoisture do
                    local index = i + (j-1)*asset.Nmoisture
                    local Nsprites = asset.Nangles * asset.Nmoisture
                    spritestackToSpriteShader:send("objectRot", (i-1) * math.pi*2 / asset.Nangles)
                    spritestackToSpriteShader:send("humidity", math.pow(j/asset.Nmoisture, 2))
                    local x, y, width, height = asset[index]:getViewport()
                    love.graphics.setShader()
                    love.graphics.setBlendMode("replace")
                    love.graphics.setColor(0,0,0,0)
                    love.graphics.rectangle("fill", x, y, width, height)
                    --Debug: draw frames of sprites
                    --love.graphics.setColor(0,0,0,1)
                    --love.graphics.rectangle("line", x, y, width, height)
                    love.graphics.setColor(1,1,1,1)
                    love.graphics.setShader(spritestackToSpriteShader)
                    love.graphics.setBlendMode("alpha")
                    x = x + asset[index + Nsprites] --X anchor
                    y = y + asset[index + 2*Nsprites] --Y anchor
                    love.graphics.draw(asset.drawable, x, y) --draw sprite
                end
            end
        elseif asset.type == "voxel" then
            love.graphics.setShader(voxelShader)
            love.graphics.setMeshCullMode("front")
            love.graphics.setBlendMode("alpha")
            for i = 1, asset.Nangles do
                local x, y = asset[i]:getViewport()
                x = x + asset[i + asset.Nangles] --X anchor
                y = y + asset[i + 2*asset.Nangles] --Y anchor
                love.graphics.draw(asset.drawable, x, y, (i-1) * math.pi*2 / asset.Nangles)
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

--returns Quad, anchorX, anchorY
function getAssetSprite(name, angle, moisture)
    local asset = assetList[name]
    _, angle = math.modf(angle/(2*math.pi))
    local index = 1 + math.floor(angle * asset.Nangles) + asset.Nangles*(math.max(math.ceil(moisture * asset.Nmoisture) - 1, 0))
    local Nsprites = asset.Nangles * asset.Nmoisture
    --io.write(string.format("%f\n", index))
    return asset[index], asset[index + Nsprites], asset[index + 2*Nsprites]
end