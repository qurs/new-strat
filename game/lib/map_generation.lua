mapGen = mapGen or {}

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
		return 0, 0, 0, 1
	else
		return 1, 1, 1, 1
	end
end

local function floodFill(imgData, w, h, startX, startY, visited, cache, targetR, targetG, targetB)
	if cache[startX] and cache[startX][startY] then
		return cache[startX][startY]
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
		cache[x][y] = size
	end

	return size
end

function mapGen.generateLand(path, w, h, freq, octave, minIslandSize, minLakeSize)
	local baseX = 1337 * love.math.random()
	local baseY = 1337 * love.math.random()

	minIslandSize = minIslandSize or 64
	minLakeSize = minLakeSize or 256
	freq = freq or 0.0015
	octave = octave or 5

	local imgData = love.image.newImageData(w, h)

	imgData:mapPixel(function(x, y, r, g, b, a)
		return pixelMap(w, h, baseX, baseY, freq, octave, x, y, r, g, b, a)
	end)

	local visited = {}
	local cache = {}

	-- remove little islands
	imgData:mapPixel(function(x, y, r, g, b, a)
		local size = floodFill(imgData, w, h, x, y, visited, cache, 1, 1, 1)
		if size < minIslandSize then
			return 0, 0, 0, 1
		end

		return r, g, b, a
	end)

	visited = {}
	cache = {}

	-- remove little lakes
	imgData:mapPixel(function(x, y, r, g, b, a)
		local size = floodFill(imgData, w, h, x, y, visited, cache, 0, 0, 0)
		if size < minLakeSize then
			return 1, 1, 1, 1
		end

		return r, g, b, a
	end)

	local data = imgData:encode('png')
	love.filesystem.write(path, data)
end

hook.Add('Initialize', 'asd', function()
	mapGen.generateLand('test.png', 1920, 1080)
	-- mapGen.generateProvs(love.image.newImageData('test.png'), 1002, 2)
end)