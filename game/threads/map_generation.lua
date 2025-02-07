require('love.image')
require('love.math')
require('love.timer')

local ffi = require('ffi')

local args = {...}

local removeLakes, minIslandSize, minLakeSize, freq, octave, w, h = unpack(args)
local pixelCount = w * h

local currentStep = 0
local maxSteps = 3

local function updateProgress()
	love.thread.getChannel('map_generator_progress'):push(currentStep / maxSteps)
end

local function iterateOverPixels(pointer, callback)
	local lastUpdate = 0
	local max = (4 * pixelCount) - 1

	for i = 0, max, 4 do
		local r, g, b, a = pointer[i], pointer[i + 1], pointer[i + 2], pointer[i + 3]

		local pos = i / 4
		local x = pos % w
		local y = math.floor(pos / w)

		local newR, newG, newB, newA = callback(x, y, r, g, b, a)
		if newR then
			pointer[i] = newR
			pointer[i + 1] = newG
			pointer[i + 2] = newB
			pointer[i + 3] = newA
		end

		if love.timer.getTime() - lastUpdate > 0.25 then
			lastUpdate = love.timer.getTime()
			love.thread.getChannel('map_generator_progress'):push((currentStep + (i / max)) / maxSteps)
		end
	end

	currentStep = currentStep + 1
	updateProgress()
end

local function Lerp( delta, from, to )

	if ( delta > 1 ) then return to end
	if ( delta < 0 ) then return from end

	return from + ( to - from ) * delta

end

local function dist(w, h, x, y)
	local nx = 2 * x / w - 1
	local ny = 2 * y / h - 1
	return 1 - (1 - nx^2) * (1 - ny^2)
end

local function pixelMap(w, h, baseX, baseY, freq, octave, x, y, r, g, b, a)
	local noise = love.math.noise(baseX + freq * x, baseY + freq * y)
	local sum = 1

	for i = 1, octave do
		noise = noise + 1 / (2^i) * love.math.noise(baseX + freq * (2^i) * x, baseY + freq * (2^i) * y)
		sum = sum + 1 / (2^i)
	end

	noise = noise / sum

	local d = dist(w, h, x, y)
	local e = noise

	if d > 0.5 then
		e = Lerp(0.5, noise, 1 - d)
	end

	if e < 0.5 then
		return 0, 0, 0, 255
	else
		return 255, 255, 255, 255
	end
end

local function floodFill(imgData, w, h, startX, startY, cache, targetR, targetG, targetB)
	local visited = {}

	if cache[startX] and cache[startX][startY] then
		return unpack(cache[startX][startY])
	end

	local stack = {}
	local points = {}
	local size = 0

	table.insert(stack, {startX, startY})

    while #stack > 0 do
		local point = table.remove(stack)
		local x, y = unpack(point)

		if x < 0 or x > (w - 1) or y < 0 or y > (h - 1) or (visited[x] and visited[x][y]) then
			goto continue
		end

		visited[x] = visited[x] or {}
		visited[x][y] = true

		local r, g, b = imgData:getPixel(x, y)
		if r ~= targetR and g ~= targetG and b ~= targetB then
			goto continue
		end

		size = size + 1
		points[#points + 1] = {x, y}

		table.insert(stack, {x + 1, y})
		table.insert(stack, {x - 1, y})
		table.insert(stack, {x, y + 1})
		table.insert(stack, {x, y - 1})

		::continue::
    end

	for _, point in ipairs(points) do
		local x, y = unpack(point)
		cache[x] = cache[x] or {}
		cache[x][y] = {size, visited}
	end

	return size, visited
end

local function start()
	local baseX = 1337 * love.math.random()
	local baseY = 1337 * love.math.random()

	local imgData = love.image.newImageData(w, h)
	local pointer = ffi.cast('uint8_t*', imgData:getFFIPointer())

	iterateOverPixels(pointer, function(x, y, r, g, b, a)
		return pixelMap(w, h, baseX, baseY, freq, octave, x, y, r, g, b, a)
	end)

	local cache = {}

	-- remove little islands
	iterateOverPixels(pointer, function(x, y, r, g, b, a)
		if r == 0 then return end

		local size = floodFill(imgData, w, h, x, y, cache, 1, 1, 1)
		if size < minIslandSize then
			return 0, 0, 0, 255
		end
	end)

	cache = {}

	-- remove little lakes
	iterateOverPixels(pointer, function(x, y, r, g, b, a)
		if r == 255 then return end

		local size, visited = floodFill(imgData, w, h, x, y, cache, 0, 0, 0)
		if (removeLakes and (not visited[0] or not visited[0][0])) or (not removeLakes and size < minLakeSize) then
			return 255, 255, 255, 255
		end
	end)

	love.thread.getChannel('map_generator'):push(imgData)
end

start()