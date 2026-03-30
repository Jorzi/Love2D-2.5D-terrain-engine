local vox_texture3d = {}

local function getPoints(model)
  local points = {}
  for _,voxel in ipairs(model.voxels) do
    local color8 = model.palette[voxel[4]]
    local color = {color8[1]/255, color8[2]/255, color8[3]/255, color8[4]/255}
    local x,y,z = voxel[1], voxel[2], voxel[3]
    if not points[z] then points[z] = {} end
    table.insert(points[z], {x + 0.5, y + 0.5, color[1], color[2], color[3], color[4]>0 and color[4] or 255}) -- r,g,b,a
  end
  return points
end


-- model is a vox model parsed by vox_model.new(binaryString)
function vox_texture3d.new(model)
  local canvas = love.graphics.newCanvas(model.sizeX, model.sizeY)
  local points = getPoints(model)
  local images = {}
  for i = 1, model.sizeZ do
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.points(points[i-1])
    love.graphics.setCanvas()
    images[i] = canvas:newImageData()
  end
  local settings = {}
	settings.mipmaps = true
	local volume = love.graphics.newVolumeImage(images, settings)
  return volume
end

return vox_texture3d
