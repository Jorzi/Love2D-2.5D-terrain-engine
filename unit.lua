function newUnit(asset, name)
    local unit = {}
	unit.state = "idle"
    unit.idle.asset = asset
	unit.name = name
	return unit
end
