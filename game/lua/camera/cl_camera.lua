camera = camera or {}
camera._pos = camera._pos or Vector()
camera._scale = camera._scale or 1

camera.minScale = camera.minScale or 1
camera.maxScale = camera.maxScale or 6.5

function camera.clampPos()
	local newMapSize = map._newMapSize
	local size = newMapSize or {ScrW(), ScrH()}

	camera._pos.y = math.Clamp(camera._pos.y, 0, math.max(size[2] - math.ceil(ScrH() / camera._scale), 0))
end

function camera.getPos()
	local pos = camera._pos
	if pos then
		return pos:Unpack()
	else
		return 0, 0
	end
end

function camera.setPos(pos)
	camera._pos = pos

	if map._newMapSize then
		local w, h = unpack(map._newMapSize)

		local minX = -w
		local maxX = w
	
		if pos.x < minX then
			camera._pos.x = (camera._pos.x - minX) + maxX
		elseif pos.x > maxX then
			camera._pos.x = (camera._pos.x - maxX) + minX
		end
	end

	camera.clampPos()
end

function camera.move(offset)
	camera.setPos(camera._pos + offset)
end

function camera.screenToWorld(x, y)
	local camX, camY = camera._pos:Unpack()
	local scale = camera._scale

	return x / scale + camX, y / scale + camY
end

function camera.worldToScreen(x, y)
	local camX, camY = camera._pos:Unpack()
	local scale = camera._scale

	return (x - camX) * scale, (y - camY) * scale
end

function camera.push()
	local pos = camera._pos
	if not pos then return end

	local x, y = pos:Unpack()

	love.graphics.push()

	love.graphics.scale(camera._scale or 1)
	love.graphics.translate(-x, -y)
end

function camera.pop()
	if not camera._pos then return end

	love.graphics.pop()
end

function camera.clampScale()
	camera._scale = math.Clamp(camera._scale, camera.minScale, camera.maxScale)
end

hook.Add('WheelMoved', 'camera', function(x, y)
	local mx, my = love.mouse.getPosition()
	local worldX, worldY = camera.screenToWorld(mx, my)

	local force = 0.1 * camera._scale

	local oldScale = camera._scale
	local newScale = math.Clamp(oldScale + y * force, camera.minScale, camera.maxScale)

	camera.setPos( Vector( worldX - (mx / newScale), worldY - (my / newScale) ) )

	camera._scale = math.Clamp(camera._scale + y * force, camera.minScale, camera.maxScale)
	camera.clampPos()
end)

hook.Add('MouseMoved', 'camera', function(x, y, dx, dy, istouch)
	if not love.mouse.isDown(3) then return end

	camera.move(Vector(-dx / camera._scale, -dy / camera._scale))
end)