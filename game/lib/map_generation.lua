mapGen = mapGen or {}
mapGen._meta = mapGen._meta or {}

local MapGenerator = mapGen._meta
MapGenerator.__index = MapGenerator

function MapGenerator:init()
	self.path = 'mapgenerator/map.png'
	self.width = 1920
	self.height = 1080

	self.removeLakes = false

	self.minIslandSize = 128
	self.minLakeSize = 256
	self.freq = 0.0015
	self.octave = 5
end

function MapGenerator:SetSavePath(path)
	self.path = path
	return self
end

function MapGenerator:SetSize(w, h)
	self.width = w
	self.height = h
	return self
end

function MapGenerator:SetWidth(w)
	self.width = w
	return self
end

function MapGenerator:SetHeight(h)
	self.height = h
	return self
end

function MapGenerator:SetRemoveLakes(b)
	self.removeLakes = b
	return self
end

function MapGenerator:SetMinIslandSize(size)
	self.minIslandSize = size
	return self
end

function MapGenerator:SetMinLakeSize(size)
	self.minLakeSize = size
	return self
end

function MapGenerator:SetFreq(freq)
	self.freq = freq
	return self
end

function MapGenerator:SetOctave(octave)
	self.octave = octave
	return self
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
		return 0, 0, 0, 1
	else
		return 1, 1, 1, 1
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

function MapGenerator:Generate()
	local baseX = 1337 * love.math.random()
	local baseY = 1337 * love.math.random()

	local path = self.path

	local removeLakes = self.removeLakes
	local minIslandSize = self.minIslandSize
	local minLakeSize = self.minLakeSize
	local freq = self.freq
	local octave = self.octave

	local w, h = self.width, self.height
	local imgData = love.image.newImageData(w, h)

	imgData:mapPixel(function(x, y, r, g, b, a)
		return pixelMap(w, h, baseX, baseY, freq, octave, x, y, r, g, b, a)
	end)

	local cache = {}

	-- remove little islands
	imgData:mapPixel(function(x, y, r, g, b, a)
		if r == 0 then return r, g, b, a end

		local size = floodFill(imgData, w, h, x, y, cache, 1, 1, 1)
		if size < minIslandSize then
			return 0, 0, 0, 1
		end

		return r, g, b, a
	end)

	cache = {}

	-- remove little lakes
	imgData:mapPixel(function(x, y, r, g, b, a)
		if r == 1 then return r, g, b, a end

		local size, visited = floodFill(imgData, w, h, x, y, cache, 0, 0, 0)
		if (removeLakes and (not visited[0] or not visited[0][0])) or (not removeLakes and size < minLakeSize) then
			return 1, 1, 1, 1
		end

		return r, g, b, a
	end)

	local data = imgData:encode('png')
	love.filesystem.write(path, data)

	return true
end

function mapGen.newGenerator()
	love.filesystem.createDirectory('mapgenerator')

	local meta = setmetatable({}, mapGen._meta)
	meta:init()

	return meta
end