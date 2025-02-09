require('love.image')
require('love.math')
require('love.timer')

local ffi = require('ffi')

local args = {...}

local removeLakes, minIslandSize, minLakeSize, freq, octave, w, h = unpack(args)
local pixelCount = w * h

local currentStep = 0
local maxSteps = 3

local progressChannel = love.thread.getChannel('map_generator_progress')

local function updateProgress()
	progressChannel:push(currentStep / maxSteps)
end

local function getIndexByPosition(x, y)
	return (y * w + x) * 4
end

local function getPixel(pointer, x, y)
	local i = getIndexByPosition(x, y)
	return pointer[i], pointer[i + 1], pointer[i + 2], pointer[i + 3]
end

local function iterateOverPixels(pointer, callback)
	local max = (4 * pixelCount) - 1

	for y = 0, h - 1 do
		local rowOffset = y * w * 4
		for x = 0, w - 1 do
			local i = rowOffset + x * 4
			local r, g, b, a = pointer[i], pointer[i + 1], pointer[i + 2], pointer[i + 3]
	
			local newR, newG, newB, newA = callback(x, y, r, g, b, a)
			if newR then
				pointer[i] = newR
				pointer[i + 1] = newG
				pointer[i + 2] = newB
				pointer[i + 3] = newA
			end
		end

		local i = rowOffset + (w - 1) * 4
		progressChannel:push((currentStep + (i / max)) / maxSteps)
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
	return 1 - (1 - nx * nx) * (1 - ny * ny)
end

local octaveFreqs = ffi.new('float[?]', octave)
local octaveWeights = ffi.new('float[?]', octave)
local totalWeight = 1

for i = 1, octave do
	octaveFreqs[i - 1] = freq * (2^i)

	local weight = 1 / (2^i)
	octaveWeights[i - 1] = weight

	totalWeight = totalWeight + weight
end

local function pixelMap(w, h, baseX, baseY, freq, octave, x, y, r, g, b, a)
	local noise = love.math.noise(baseX + freq * x, baseY + freq * y)

	for i = 1, octave do
		noise = noise + octaveWeights[i - 1] * love.math.noise(baseX + octaveFreqs[i - 1] * x, baseY + octaveFreqs[i - 1] * y)
	end

	noise = noise / totalWeight

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

local function floodFill(imgDataPointer, w, h, startX, startY, cache, targetCol)
	local visited = {}

	if cache[startX] and cache[startX][startY] then
		return unpack(cache[startX][startY])
	end

	local points = {}
	local size = 0

	local stack = {}
	local stackSize = 0

	local function push(x, y)
		stackSize = stackSize + 1
		stack[stackSize] = x
		stackSize = stackSize + 1
		stack[stackSize] = y
	end

	local function pop()
		local y = stack[stackSize]
		stack[stackSize] = nil
		stackSize = stackSize - 1
		local x = stack[stackSize]
		stack[stackSize] = nil
		stackSize = stackSize - 1
		return x, y
	end

	push(startX, startY)

	while stackSize > 0 do
		local x, y = pop()
		if x >= 0 and x < w and y >= 0 and y < h then
			local idx = x + y * w  -- 0-индексация для FFI-массива
			if not visited[idx] then
				visited[idx] = true
				local r = getPixel(imgDataPointer, x, y)
				if r == targetCol then
					size = size + 1
					points[#points + 1] = {x, y}

					push(x + 1, y)
					push(x - 1, y)
					push(x, y + 1)
					push(x, y - 1)
				end
			end
		end
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

		local size = floodFill(pointer, w, h, x, y, cache, 255)
		if size < minIslandSize then
			return 0, 0, 0, 255
		end
	end)

	cache = {}

	-- remove little lakes
	iterateOverPixels(pointer, function(x, y, r, g, b, a)
		if r == 255 then return end

		local size, visited = floodFill(pointer, w, h, x, y, cache, 0)
		local idx = x + y * w
		if (removeLakes and not visited[0]) or (not removeLakes and size < minLakeSize) then
			return 255, 255, 255, 255
		end
	end)

	love.thread.getChannel('map_generator'):push(imgData)
end

start()