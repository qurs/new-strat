camera = camera or {}
camera._pos = camera._pos or Vector()
camera._scale = camera._scale or 1

camera.minScale = camera.minScale or 1
camera.maxScale = camera.maxScale or 6.5

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

	if map._mapSize then
		local w, h = unpack(map._mapSize.new)

		local minX = map._centerX - (w / 2)
		local maxX = map._centerX + (w * 1.5)
	
		if pos.x < minX then
			camera._pos.x = (camera._pos.x - minX) + maxX
		elseif pos.x > maxX then
			camera._pos.x = (camera._pos.x - maxX) + minX
		end
	end

	-- camera._pos.x = math.Clamp(camera._pos.x, minW, maxW)
	camera._pos.y = math.Clamp(camera._pos.y, 0, ScrH())
end

function camera.move(offset)
	camera.setPos(camera._pos + offset)
end

function camera.mouseToWorld(x, y)
	local scale = camera._scale
	local camX, camY = camera.getPos()

	return (x - ScrW() / 2) / scale + camX, (y - ScrH() / 2) / scale + camY
end

function camera.push()
	local pos = camera._pos
	if not pos then return end

	local x, y = pos:Unpack()

	love.graphics.push()

	love.graphics.translate(ScrW() / 2, ScrH() / 2)
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
	local force = 0.1 * camera._scale

	camera._scale = math.Clamp(camera._scale + y * force, camera.minScale, camera.maxScale)
end)

hook.Add('MouseMoved', 'camera', function(x, y, dx, dy, istouch)
	if not love.mouse.isDown(3) then return end

	camera.move(Vector(-dx / camera._scale, -dy / camera._scale))
end)