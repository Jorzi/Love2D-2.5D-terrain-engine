images = {}
i=1
while true do
    filename = string.format("spritestack_input/%04d.png", i)
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
volume:setWrap("clampzero")
normalMap = love.graphics.newCanvas(volume:getWidth(), volume:getHeight(), {format="rgba8"})
volumeNormals = love.graphics.newShader("volume_normals.glsl")
volumeNormals:send("volume", volume)
volumeNormals:send("size", {volume:getWidth(), volume:getHeight(), numberOfLayers})
vertices = {
    {0,0,0,0},
    {volume:getWidth(),0,1,0},
    {volume:getWidth(),volume:getHeight(),1,1},
    {0,volume:getHeight(),0,1},
}
mesh = love.graphics.newMesh(vertices)
for i=1,numberOfLayers do
    volumeNormals:send("zcoord", (i-0.5)/numberOfLayers)
    love.graphics.setCanvas(normalMap)
    love.graphics.clear( )
	love.graphics.setShader(volumeNormals)
	love.graphics.draw(mesh)
    love.graphics.setCanvas()
    love.graphics.setShader()
    data = normalMap:newImageData()
    outFile = love.filesystem.newFile(string.format("%04d.png", i))
    ok, err = outFile:open('w')
--    io.write(err)
--    io.write('\n')
    pngdata = data:encode('png')
    success, err = outFile:write(pngdata)
    outFile:close()
--    io.write(err)
--    io.write('\n')
end

function love.draw()
    love.graphics.draw(normalMap)
end