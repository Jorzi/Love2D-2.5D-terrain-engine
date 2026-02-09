assetList = {}
assetList.bufferResX = 2048
assetList.bufferResy = 2048
assetList.diffuseBuffer = love.graphics.newCanvas(assetList.bufferResX, assetList.bufferResY)


function newAsset (drawable, type, name)
    local asset = {}
    asset.type = type
    asset.drawable = drawable
    asset.Nangles = drawable.Nangles
    assetlist[name] = asset

end

--asset = {width, height, type, drawable}
function generateDynamicSpritesheet()
	local binpack_new = require('binpack')
	local bp = binpack_new(assetList.bufferResX, assetList.bufferResy)
	for k, v in pairs(assetList) do
		for i = 1, v.Nangles do
            local angle = 2 * math.pi / v.Nangles * (i-1)
			local width, height, anchorX, anchorY = getDimensions(v.drawable, v.type, angle)
            local rect = bp:insert(width, height)
            --put all data as numerical indices directly in the list entry for faster drawing of quads
			assetList.k[i] = love.graphics.newQuad(rect.x, rect.y, width, height)
            assetList.k[i + Nangles] = anchorX
            assetList.k[i + 2*Nangles] = anchorY
		end
	end
end