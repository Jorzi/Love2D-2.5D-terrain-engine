function newCustomSpritebatch(image, maxsprites)
    local vertexFormat = {
        {"VertexPosition", "float", 2},
        {"VertexTexCoord", "float", 2},
        {"WorldPosition", "float", 3},
    }
    local customSpriteBatch = love.graphics.newMesh(vertexFormat, maxsprites * 6, "triangles", "stream" )
    customSpriteBatch:setDrawRange( 1, 1 )
    return customSpriteBatch
end

function addQuad(customSpriteBatch, quad, anchor, worldPosition)
    local _, lastIndex = customSpriteBatch:getDrawRange( )
    if lastIndex == customSpriteBatch:getVertexCount( ) then
        customSpriteBatch = newCustomSpritebatch(customSpriteBatch:getTexture(), lastIndex/6 * 2) --this discards all previous data, but I don't care since it will be cleared each frame anyway.
    end
    local texWidth, texHeight = quad:getTextureDimensions( )
    local x, y, width, height = quad:getViewport()
    y = 1 - y
    local vertices = {
        {-anchor[1], -anchor[2], x/texWidth, y/texHeight, worldPosition[1], worldPosition[2], worldPosition[3]},
        {width-anchor[1], -anchor[2], (x+width)/texWidth, y/texHeight, worldPosition[1], worldPosition[2], worldPosition[3]},
        {width-anchor[1], height-anchor[2], (x+width)/texWidth, (y+height)/texHeight, worldPosition[1], worldPosition[2], worldPosition[3]},
        {width-anchor[1], height-anchor[2], (x+width)/texWidth, (y+height)/texHeight, worldPosition[1], worldPosition[2], worldPosition[3]},
        {-anchor[1], height-anchor[2], x/texWidth, (y+height)/texHeight, worldPosition[1], worldPosition[2], worldPosition[3]},
        {-anchor[1], -anchor[2], x/texWidth, y/texHeight, worldPosition[1], worldPosition[2], worldPosition[3]},
    }
    customSpriteBatch:setVertices( vertices, lastIndex + 1 )
    customSpriteBatch:setDrawRange( 1, lastIndex + 6 )
end

function clearCustomSpriteBatch(customSpriteBatch)
    customSpriteBatch:setDrawRange( 1, 1 )
end
