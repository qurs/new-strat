require('love.image')
require('love.math')

local ffi = require('ffi')

local args = {...}

local inputData, avgProvinceLandSize, avgProvinceOceanSize, lloydIterations = unpack(args)

local width, height = inputData:getDimensions()
local pixelCount = width * height

local inputDataPointer = ffi.cast('uint8_t*', inputData:getFFIPointer())

local currentStep = 0
local maxSteps = 8 + (lloydIterations * 2)

local progressChannel = love.thread.getChannel('prov_generator_progress')

local function getColorKey(r, g, b)
	return r * 65536 + g * 256 + b
end
  
local function getColorFromKey(key)
	local r = math.floor(key / 65536)
	local g = math.floor((key % 65536) / 256)
	local b = key % 256
	return r, g, b
end

local function updateProgress()
	progressChannel:push(currentStep / maxSteps)
end

local function getIndexByPosition(x, y)
	return (y * width + x) * 4
end

local function getPixel(pointer, x, y)
	local i = getIndexByPosition(x, y)
	return pointer[i], pointer[i + 1], pointer[i + 2], pointer[i + 3]
end

local function setPixel(pointer, x, y, r, g, b, a)
	local i = getIndexByPosition(x, y)
	pointer[i] = r
	pointer[i + 1] = g
	pointer[i + 2] = b
	if a then pointer[i + 3] = a end
end

local function iterateOverPixels(pointer, callback)
	local max = (4 * pixelCount) - 1

	for y = 0, height - 1 do
		for x = 0, width - 1 do
			local i = getIndexByPosition(x, y)
			local r, g, b, a = pointer[i], pointer[i + 1], pointer[i + 2], pointer[i + 3]
	
			local newR, newG, newB, newA = callback(x, y, r, g, b, a)
			if newR then
				pointer[i] = newR
				pointer[i + 1] = newG
				pointer[i + 2] = newB
				pointer[i + 3] = newA
			end
		end

		progressChannel:push((currentStep + (getIndexByPosition(width - 1, y) / max)) / maxSteps)
	end

	currentStep = currentStep + 1
	updateProgress()
end

-- Flood fill (4-смежность) для выделения связной компоненты, начинающейся с (x, y)
local function floodFill(x, y, origR, origG, origB, width, height, imageDataPointer, visited)
	local compPixels = {}
	local compKey = getColorKey(origR, origG, origB)
	
	local stack = {}
	local stackSize = 0

	local function push(px, py)
		stackSize = stackSize + 1
		stack[stackSize] = {x = px, y = py}
	end

	local function pop()
		local pos = stack[stackSize]
		stack[stackSize] = nil
		stackSize = stackSize - 1
		return pos
	end

	push(x, y)

	while stackSize > 0 do
		local pos = pop()
		local px, py = pos.x, pos.y

		if px >= 0 and px < width and py >= 0 and py < height then
			local idx = px + py * width + 1
			if visited[idx] == 0 then
				local r, g, b, a = getPixel(imageDataPointer, px, py)
				if getColorKey(r, g, b) == compKey then
					visited[idx] = 1
					compPixels[#compPixels + 1] = {x = px, y = py}

					-- Добавляем соседей (4-смежность) в стек.
					push(px + 1, py)
					push(px - 1, py)
					push(px, py + 1)
					push(px, py - 1)
				end
			end
		end
	end

	return { key = compKey, pixels = compPixels, size = #compPixels }
end

-- Функция устранения анклавов: для каждого цвета оставляем основную (наибольшую) компоненту,
-- а остальные (анклавы) переопределяем на основе голосования среди соседей.
local function removeEnclaves(imageDataPointer, origImageDataPointer)
	local visited = ffi.new('uint8_t[?]', pixelCount)

	-- Собираем компоненты для каждого цвета
	local compsByColor = {}  -- [colorKey] = { main = comp, extras = { comp1, comp2, ... } }
	iterateOverPixels(imageDataPointer, function(x, y, r, g, b, a)
		local idx = x + y * width + 1
		if visited[idx] == 0 then
			local comp = floodFill(x, y, r, g, b, width, height, imageDataPointer, visited)
			if not compsByColor[comp.key] then
				compsByColor[comp.key] = { main = comp, extras = {} }
			else
				local extras = compsByColor[comp.key].extras
				if comp.size > compsByColor[comp.key].main.size then
					extras[#extras + 1] = compsByColor[comp.key].main
					compsByColor[comp.key].main = comp
				else
					extras[#extras + 1] = comp
				end
			end
		end
	end)

	-- Для каждого анклава определяем новый цвет, голосуя среди соседей
	for _, group in pairs(compsByColor) do
		for _, comp in ipairs(group.extras) do
			local neighborVotes = {}  -- голоса за цвета соседей
			local inComp = ffi.new('uint8_t[?]', pixelCount)
			for _, pos in ipairs(comp.pixels) do
				local idx = pos.x + pos.y * width + 1
				inComp[idx] = 1
			end
			for _, pos in ipairs(comp.pixels) do
				local x, y = pos.x, pos.y
				local origR = getPixel(origImageDataPointer, x, y)
				local neighbors = {
					{x = x + 1, y = y},
					{x = x - 1, y = y},
					{x = x, y = y + 1},
					{x = x, y = y - 1},
				}
				for _, n in ipairs(neighbors) do
					if n.x >= 0 and n.x < width and n.y >= 0 and n.y < height then
						local nIdx = n.x + n.y * width + 1
						if inComp[nIdx] == 0 then
							local origNeighborR = getPixel(origImageDataPointer, n.x, n.y)
							
							if origR == origNeighborR then
								local nr, ng, nb, na = getPixel(imageDataPointer, n.x, n.y)
								local nKey = getColorKey(nr, ng, nb)
								neighborVotes[nKey] = (neighborVotes[nKey] or 0) + 1
							end
						end
					end
				end
			end
			local bestKey, maxVotes = nil, 0
			for k, votes in pairs(neighborVotes) do
				if votes > maxVotes then
					maxVotes = votes
					bestKey = k
				end
			end
			if bestKey then
				local newR, newG, newB = getColorFromKey(bestKey)
				for _, pos in ipairs(comp.pixels) do
					setPixel(imageDataPointer, pos.x, pos.y, newR, newG, newB, 255)
				end
			end
		end
	end
end

-- Функция одной итерации Ллойда для перераспределения семян
local function lloydIteration(inputDataPointer, seeds, regionTest)
	local accumulators = {}
	for i = 1, #seeds do
		accumulators[i] = { sumX = 0, sumY = 0, count = 0 }
	end

	iterateOverPixels(inputDataPointer, function(x, y, r, g, b, a)
		if regionTest(x, y, r, g, b) then
			local bestIndex, bestDist = 1, math.huge
			for i, seed in ipairs(seeds) do
				local dx = x - seed.x
				local dy = y - seed.y
				local dist = dx * dx + dy * dy
				if dist < bestDist then
					bestDist = dist
					bestIndex = i
				end
			end
			accumulators[bestIndex].sumX = accumulators[bestIndex].sumX + x
			accumulators[bestIndex].sumY = accumulators[bestIndex].sumY + y
			accumulators[bestIndex].count = accumulators[bestIndex].count + 1
		end
	end)

	for i, seed in ipairs(seeds) do
		if accumulators[i].count > 0 then
			seed.x = accumulators[i].sumX / accumulators[i].count
			seed.y = accumulators[i].sumY / accumulators[i].count
		end
	end
end

local function start()
	-- Подсчёт пикселей: белые (суша) и чёрные (океан)
	local totalLand, totalOcean = 0, 0
	iterateOverPixels(inputDataPointer, function(x, y, r, g, b, a)
		if r == 255 then
			totalLand = totalLand + 1
		else
			totalOcean = totalOcean + 1
		end
	end)

	local nLandProvinces = math.max(1, math.floor(totalLand / avgProvinceLandSize))
	local nOceanProvinces = math.max(1, math.floor(totalOcean / avgProvinceOceanSize))

	-- Генерация семян для провинций на суше
	local landSeeds = {}

	while #landSeeds < nLandProvinces do
		local x = love.math.random(0, width - 1)
		local y = love.math.random(0, height - 1)
		local r = getPixel(inputDataPointer, x, y)
		if r == 255 then
			landSeeds[#landSeeds + 1] = {
				x = x,
				y = y,
				color = {
					love.math.random(20, 255),
					love.math.random(20, 255),
					love.math.random(20, 255),
				}
			}
		end
	end

	currentStep = currentStep + 1
	updateProgress()

	-- Генерация семян для провинций в океане
	local oceanSeeds = {}
	while #oceanSeeds < nOceanProvinces do
		local x = love.math.random(0, width - 1)
		local y = love.math.random(0, height - 1)
		local r = getPixel(inputDataPointer, x, y)
		if r == 0 then
			oceanSeeds[#oceanSeeds + 1] = {
				x = x,
				y = y,
				color = {
					love.math.random(20, 255),
					love.math.random(20, 255),
					love.math.random(20, 255),
				}
			}
		end
	end

	currentStep = currentStep + 1
	updateProgress()

	for i = 1, lloydIterations do
		lloydIteration(inputDataPointer, landSeeds, function(x, y, r, g, b)
			return r == 255
		end)
	end
	for i = 1, lloydIterations do
		lloydIteration(inputDataPointer, oceanSeeds, function(x, y, r, g, b)
			return r == 0
		end)
	end

	local newImageData = love.image.newImageData(width, height)
	local newImageDataPointer = ffi.cast('uint8_t*', newImageData:getFFIPointer())

	iterateOverPixels(newImageDataPointer, function(x, y, r, g, b, a)
		local origR = getPixel(inputDataPointer, x, y)
		if origR == 255 then
			local bestIndex, bestDist = 1, math.huge
			for i, seed in ipairs(landSeeds) do
				local dx = x - seed.x
				local dy = y - seed.y
				local dist = dx * dx + dy * dy
				if dist < bestDist then
					bestDist = dist
					bestIndex = i
				end
			end
			local col = landSeeds[bestIndex].color
			return col[1], col[2], col[3], 255
		else
			local bestIndex, bestDist = 1, math.huge
			for i, seed in ipairs(oceanSeeds) do
				local dx = x - seed.x
				local dy = y - seed.y
				local dist = dx * dx + dy * dy
				if dist < bestDist then
					bestDist = dist
					bestIndex = i
				end
			end
			local col = oceanSeeds[bestIndex].color
			return col[1], col[2], col[3], 255
		end
	end)

	removeEnclaves(newImageDataPointer, inputDataPointer)

	currentStep = currentStep + 1
	updateProgress()

	local provinces = {}

	iterateOverPixels(newImageDataPointer, function(x, y, r, g, b, a)
		local curCol = getColorKey(r, g, b)
		local curProv = provinces[curCol]

		if not curProv then
			local origR = getPixel(inputDataPointer, x, y)
			local provType = origR == 0 and 'sea' or 'land'

			provinces[curCol] = {
				type = provType,
				isCoastal = false,
			}

			curProv = provinces[curCol]
		end

		if curProv.type == 'sea' then return end
		if curProv.isCoastal then return end

		local neighbors = {
			{x, y - 1}, {x - 1, y},
			{x, y + 1}, {x + 1, y},
		}

		for _, point in ipairs(neighbors) do
			local x, y = unpack(point)
			if x < 0 or x > width - 1 or y < 0 or y > height - 1 then goto continue end

			local col = getColorKey( getPixel(newImageDataPointer, x, y) )
			local neighborType = provinces[col] and provinces[col].type
			if neighborType == 'sea' then
				curProv.isCoastal = true
				break
			end

			::continue::
		end
	end)

	local id = 0
	local csv = ''
	for rgb, province in pairs(provinces) do
		id = id + 1
		local r, g, b = getColorFromKey(rgb)
		csv = csv .. ('%s;%s;%s;%s;%s;%s\n'):format(id, r, g, b, province.type, province.isCoastal)
	end

	love.thread.getChannel('prov_generator'):push({
		csv = csv,
		imgData = newImageData,
	})
end

start()