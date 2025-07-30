-- mapGrid is a sparse array containing all units, buildings, plants and decals, as well as data on movement and building blockers
function initializeMapGrid()
    mapGrid = {}
end

function getDecal(x, y)
    if mapGrid[x+y*mapSizeX] then
        return mapGrid[x+y*mapSizeX].decal
    end
end

function getObject(x, y)
    if mapGrid[x+y*mapSizeX] then
        return mapGrid[x+y*mapSizeX].object
    end
end

function getUnit(x, y)
    if mapGrid[x+y*mapSizeX] then
        return mapGrid[x+y*mapSizeX].unit
    end
end

function getBlocker(x, y)
    if mapGrid[x+y*mapSizeX] then
        return mapGrid[x+y*mapSizeX].blocker
    end
end

function checkTile(x, y)
    if not mapGrid[math.floor(x)+math.floor(y)*mapSizeX] then
        mapGrid[math.floor(x)+math.floor(y)*mapSizeX] = {}
    end
    x = math.min(math.max(0, x), mapSizeX-1)
    y = math.min(math.max(0, y), mapSizeY-1)
    return x, y
end

function clearTile(x, y)
    mapGrid[math.floor(x)+math.floor(y)*mapSizeX] = nil
end

function addDecal(x, y, mesh, decalType, rot)
    x, y = checkTile(x, y)
	mapGrid[math.floor(x)+math.floor(y)*mapSizeX].decal = {mesh = mesh, decalType = decalType, rot=rot}
    mapGrid[math.floor(x)+math.floor(y)*mapSizeX].blocker = {blockerType = "build", originX = math.floor(x), originY = math.floor(y)}
end

function addUnit(unit, x, y, rot)
    x, y = checkTile(x, y)
	mapGrid[math.floor(x)+math.floor(y)*mapSizeX].unit = {unit = unit, x=x, y=y, rot=rot}
end

function addPlant(plant, x, y, rot, walkable, blockerList)
    x, y = checkTile(x, y)
	mapGrid[math.floor(x)+math.floor(y)*mapSizeX].object = {drawable = plant.image, normalmap = plant.normalmap, Nangles = plant.Nangles, Nmoisture = plant.Nmoisture, objectType = "plant", height = plant.height, x=x, y=y, rot=rot, drowning = 0, blockerList = blockerList}
    if walkable then
        mapGrid[math.floor(x)+math.floor(y)*mapSizeX].blocker = {blockerType = "build", originX = math.floor(x), originY = math.floor(y)}
    else
        mapGrid[math.floor(x)+math.floor(y)*mapSizeX].blocker = {blockerType = "walk", originX = math.floor(x), originY = math.floor(y)}
    end
    if blockerList then
        for k, v in pairs(blockerList) do
            mapGrid[math.floor(x)+v[1]+(math.floor(y)+v[2])*mapSizeX].blocker = {blockerType = v[3], originX = math.floor(x), originY = math.floor(y)}
        end
    end
end

function addBuilding(building, x, y, rot, walkable)
    x, y = checkTile(x, y)
	mapGrid[math.floor(x)+math.floor(y)*mapSizeX].object = {drawable = building.image, normalmap = building.normalmap, Nangles = building.Nangles, Nmoisture = building.Nmoisture, objectType = "building", height = building.height, x=x, y=y, rot=rot}
    if walkable then
        mapGrid[math.floor(x)+math.floor(y)*mapSizeX].blocker = {blockerType = "build", originX = math.floor(x), originY = math.floor(y)}
    else
        mapGrid[math.floor(x)+math.floor(y)*mapSizeX].blocker = {blockerType = "walk", originX = math.floor(x), originY = math.floor(y)}
    end
end

function updatePlants (dt)
    local Nframes = 20 --distribute updates over N frames to reduce load
    local n = love.frame%Nframes
    local index = 0;
    for k, v in pairs(mapGrid) do
        if v.object and v.object.objectType == "plant" then
            index = (index+1)%Nframes
            if index == n then
                v.object.drowning = math.max(0, v.object.drowning + (getFluidDepth(fluidSim, v.object.x, v.object.y)*255-0.1)*Nframes)
                if v.object.drowning >= 256 then
                    v.object = nil
                    v.blocker = nil
                end
            end
        end
    end
end

function clearObject(x, y)
    if getObject(x, y) then
        for k, v in pairs(getObject(x, y).blockerList) do
            mapGrid[x+v[1]+(y+v[2])*mapSizeX].blocker = nil
        end
        mapGrid[x+y*mapSizeX].object = nil
    end
end