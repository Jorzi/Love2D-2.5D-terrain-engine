

--[[ function newDecal(x, y, mesh, decalType, rot)
    x = math.min(math.max(0, x), mapSizeX-1)
    y = math.min(math.max(0, y), mapSizeY-1)
	decals[x+y*mapSizeX] = {mesh = mesh, decalType = decalType, rot=rot}
end ]]

function getRoadType (x, y)
    local nNeighbours = 0
    local neighbour1 = getDecal(x, y-1) and getDecal(x, y-1).decalType == "road"
    if neighbour1 then nNeighbours = nNeighbours + 1 end
    local neighbour2 = getDecal(x+1, y) and getDecal(x+1, y).decalType == "road"
    if neighbour2 then nNeighbours = nNeighbours + 1 end
    local neighbour3 = getDecal(x, y+1) and getDecal(x, y+1).decalType == "road"
    if neighbour3 then nNeighbours = nNeighbours + 1 end
    local neighbour4 = getDecal(x-1, y) and getDecal(x-1, y).decalType == "road"
    if neighbour4 then nNeighbours = nNeighbours + 1 end
    local roadType = 0;
    local rot = 0;
    if nNeighbours == 0 then
        roadType = 5
    elseif nNeighbours == 1 then
        roadType = 4
        if neighbour1 then
            rot = math.pi;
        elseif neighbour4 then
            rot = math.pi/2;
        elseif neighbour2 then
            rot = math.pi*1.5;
        end
    elseif nNeighbours == 2 then
        if neighbour1 and neighbour3 then
            roadType = 0;
            rot = 0;
        elseif neighbour2 and neighbour4 then
            roadType = 0;
            rot = math.pi/2;
        elseif neighbour4 and neighbour1 then
            roadType = 2;
            rot = 0;
        elseif neighbour1 and neighbour2 then
            roadType = 2;
            rot = math.pi/2;
        elseif neighbour2 and neighbour3 then
            roadType = 2;
            rot = math.pi;
        elseif neighbour3 and neighbour4 then
            roadType = 2;
            rot = math.pi*1.5;
        end
    elseif nNeighbours == 3 then
        roadType = 3
        if not neighbour1 then
            rot = math.pi/2;
        elseif not neighbour2 then
            rot = math.pi;
        elseif not neighbour3 then
            rot = math.pi*1.5;
        end
    elseif nNeighbours == 4 then
        roadType = 1
    end
    return roadType, rot
end

function generateRoadMesh(roadType, rot)
    --override with simplified case
    --roadType = 5
    local x1 = -1.05* mapGridScale
    local x2 = 1.05* mapGridScale
    local y1 = -1.05* mapGridScale
    local y2 = 1.05* mapGridScale
    -- normalized texture coordinates 
    local u1 = 0.05
    local u2 = 0.95
    local v1 = roadType/6 + 0.01
    local v2 = 1/6+roadType/6 - 0.01
    local r = 0.8
    local g = 0.7
    local b = 0.6
    local vertices = {}
    --first triangle
    table.insert(vertices, {x1, y1, u1, v1, r,g,b})
    table.insert(vertices, {x2, y1, u2, v1, r,g,b})
    table.insert(vertices, {x1, y2, u1, v2, r,g,b})
    --second triangle
    table.insert(vertices, {x2, y1, u2, v1, r,g,b})
    table.insert(vertices, {x2, y2, u2, v2, r,g,b})
    table.insert(vertices, {x1, y2, u1, v2, r,g,b})
    local spriteMesh = love.graphics.newMesh(vertices, "triangles", "static")
    spriteMesh:setTexture(road_tiles)
    return spriteMesh
end

function addRoad(x, y)
    x = math.min(math.max(0, x), mapSizeX-1)
    y = math.min(math.max(0, y), mapSizeY-1)
    if getDecal(x, y) and getDecal(x, y).decalType == "road" then
        return
    else
        local roadType, rot = getRoadType(x, y)
        --io.write(string.format("roadType = %f, rot = %f\n", roadType, rot))
        local mesh = generateRoadMesh(roadType, rot)
        addDecal(x, y, mesh, "road", rot)
        updateRoad(x+1, y)
        updateRoad(x-1, y)
        updateRoad(x, y+1)
        updateRoad(x, y-1)
    end
end

function updateRoad(x, y)
    if getDecal(x, y) and getDecal(x, y).decalType == "road" then
        local roadType, rot = getRoadType(x, y)
        local mesh = generateRoadMesh(roadType, rot)
        getDecal(x, y).mesh = mesh
        getDecal(x, y).rot = rot
    end
end