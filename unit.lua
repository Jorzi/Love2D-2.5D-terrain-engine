unitTypes = {
	randomWalker = {asset = "walkingDude1", speed = 0.1, animLength = 15}
}
local Luafinding = require( "luafinding/luafinding" )
local Vector = require( "luafinding/vector" )
local function checkAccessibility(pos)
	local x, y = pos.x, pos.y
	if x >= 0 and x < mapSizeX and y >= 0 and y < mapSizeY then
		if not getBlocker(x, y) or getBlocker(x, y) == "build" then
			if fluidSim.fluidData:getPixel(x, y) < 0.1/255 then
				return true
			end
		end
	end 
	return false
end

function calculatePath(unit, targetX, targetY)
	local start = Vector(math.floor(unit.x), math.floor(unit.y))
	local finish = Vector(targetX, targetY)
	path = Luafinding( start, finish, checkAccessibility ):GetPath()
	return path
end

function newUnit(name, x, y, rot)
    local unit = {}
	unit.state = "idle"
	unit.animCycle = 0
    unit.asset = unitTypes[name].asset
	unit.speed = unitTypes[name].speed
	unit.animLength = unitTypes[name].animLength
	unit.name = name
	unit.x, unit.y, unit.rot = x, y, rot
	unit.height = getTerrainHeight(x, y)
	unit.tileX, unit.tileY = checkTile(math.floor(x), math.floor(y))
	unit.targetX, unit.targetY = x, y
	return unit
end

function updateUnit(unit)
	if unit.name == "randomWalker" then
		if unit.state == "idle" then
			randX = (math.random() - 0.5) * 16
			randY = (math.random() - 0.5) * 16
			unit.targetX = math.floor(unit.x  + randX)
			unit.targetY = math.floor(unit.y  + randY)
			unit.targetX = math.min(math.max(0, unit.targetX), mapSizeX-1)
    		unit.targetY = math.min(math.max(0, unit.targetY), mapSizeY-1)
			unit.path = calculatePath(unit, unit.targetX, unit.targetY)
			local target = nil
			if unit.path then
				target = table.remove(unit.path, 1)
			end
			if target then
				unit.targetX, unit.targetY = target.x, target.y
				unit.state = "moving"
				unit.animCycle = 0
			end
		end
	end
	if unit.state == "moving" then
		_, unit.animCycle = math.modf(unit.animCycle + 1/unit.animLength)
		local dx, dy = unit.targetX - unit.x, unit.targetY - unit.y
		local unitSpeed = unit.speed --tiles per game tick
		local dist = math.sqrt(dx*dx+dy*dy)
		dx, dy = dx/dist*unitSpeed, dy/dist*unitSpeed
		if dist <= unitSpeed then
			local target = table.remove(unit.path, 1)
			if target then
				unit.targetX, unit.targetY = target.x, target.y
			else
				unit.x, unit.y = unit.targetX, unit.targetY
				unit.state = "idle" 
				unit.animCycle = 0
			end
		else
			unit.x, unit.y = unit.x + dx, unit.y + dy
			unit.rot = math.atan2(dy, dx) + 2*math.pi + math.pi/2
		end

		unit.height = getTerrainHeight(unit.x, unit.y)
		local tileX, tileY = checkTile(math.floor(unit.x), math.floor(unit.y))
		if not(tileX == unit.tileX and tileY == unit.tileY) and not getUnit(tileX, tileY) then --only change tiles if there is a free tile
			mapGrid[tileX+tileY*mapSizeX].unit = unit
			mapGrid[unit.tileX+unit.tileY*mapSizeX].unit = nil
			unit.tileX, unit.tileY = tileX, tileY
		end
	end
end