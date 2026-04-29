unitTypes = {
	randomWalker = {asset = "walkingDude1", speed = 0.1, animLength = 15}
}


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
			unit.targetX = unit.x  + randX
			unit.targetY = unit.y  + randY
			unit.targetX = math.min(math.max(0, unit.targetX), mapSizeX-1)
    		unit.targetY = math.min(math.max(0, unit.targetY), mapSizeY-1)
			unit.state = "moving"
			unit.animCycle = 0
		end
	end
	if unit.state == "moving" then
		_, unit.animCycle = math.modf(unit.animCycle + 1/unit.animLength)
		local dx, dy = unit.targetX - unit.x, unit.targetY - unit.y
		local unitSpeed = unit.speed --tiles per game tick
		local dist = math.sqrt(dx*dx+dy*dy)
		dx, dy = dx/dist*unitSpeed, dy/dist*unitSpeed
		local rot = math.atan2(dy, dx) + 2*math.pi + math.pi/2
		if dist <= unitSpeed then
			unit.x, unit.y = unit.targetX, unit.targetY
		else
			unit.x, unit.y = unit.x + dx, unit.y + dy
		end
		if unit.x == unit.targetX and unit.y == unit.targetY then 
			unit.state = "idle" 
			unit.animCycle = 0
		end
		unit.rot = rot
		unit.height = getTerrainHeight(unit.x, unit.y)
		local tileX, tileY = checkTile(math.floor(unit.x), math.floor(unit.y))
		if not(tileX == unit.tileX and tileY == unit.tileY) and not getUnit(tileX, tileY) then --only change tiles if there is a free tile
			mapGrid[tileX+tileY*mapSizeX].unit = unit
			mapGrid[unit.tileX+unit.tileY*mapSizeX].unit = nil
			unit.tileX, unit.tileY = tileX, tileY
		end
	end
end