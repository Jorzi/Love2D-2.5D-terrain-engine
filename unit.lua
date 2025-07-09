function newUnit(filename, texture, normalmap)
    local unit = {}
    unit.texture = texture
    unit.normalmap = normalmap
    local contents = love.filesystem.read(filename)
	local data = json.decode(contents)
	local i = 1
	unit.sprites = {}
	while data.frames[string.format("stand%02d_col", i)] do

		local sprite = data.frames[string.format("stand%02d_col", i)]
		-- centered vertex coordinates (horizontally centered, vertically at width/4 from the bottom)
		local x1 = sprite.spriteSourceSize.x - sprite.sourceSize.w / 2
		local x2 = (sprite.spriteSourceSize.x + sprite.spriteSourceSize.w) - sprite.sourceSize.w / 2
		local y1 = sprite.spriteSourceSize.y - (sprite.sourceSize.h - sprite.sourceSize.w / 4)
		local y2 = (sprite.spriteSourceSize.y + sprite.spriteSourceSize.h) - (sprite.sourceSize.h - sprite.sourceSize.w / 4)
		-- normalized texture coordinates 
		local u1 = sprite.frame.x / texture:getWidth()
		local u2 = (sprite.frame.x + sprite.frame.w) / texture:getWidth()
		local v1 = sprite.frame.y / texture:getHeight()
		local v2 = (sprite.frame.y + sprite.frame.h) / texture:getHeight()
        local vertices = {}
		--first triangle
		table.insert(vertices, {x1, y1, u1, v1, 1,1,1})
		table.insert(vertices, {x2, y1, u2, v1, 1,1,1})
		table.insert(vertices, {x1, y2, u1, v2, 1,1,1})
		--second triangle
		table.insert(vertices, {x2, y1, u2, v1, 1,1,1})
		table.insert(vertices, {x2, y2, u2, v2, 1,1,1})
		table.insert(vertices, {x1, y2, u1, v2, 1,1,1})
        local spriteMesh = love.graphics.newMesh(vertices, "triangles", "static")
        spriteMesh:setTexture(texture)
        table.insert(unit.sprites, spriteMesh)
		i = i + 1
	end
    unit.n_angles = i-1
	return unit
end


	function drawUnit(unit, x, y, rot, cameraRot)
		rot = rot + cameraRot
		while rot < 0 do
			rot = rot + math.pi*2
		end
		local angle_index = (1-math.mod(rot, math.pi*2)/(math.pi*2)) * unit.n_angles
		angle_index = math.ceil(angle_index)
		love.graphics.draw(unit.sprites[angle_index], x, y)
		--io.write(string.format("Sprites found = %f\n",unit.n_angles))
		--io.write(string.format("Sprite index = %f\n",angle_index))
	end