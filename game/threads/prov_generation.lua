require('love.image')
require('love.math')
require('love.timer')

local ffi = require('ffi')

local args = {...}

local inputData, avgProvinceLandSize, avgProvinceOceanSize, lloydIterations = unpack(args)

local width, height = inputData:getDimensions()
local pixelCount = width * height

local inputDataPointer = ffi.cast('uint8_t*', inputData:getFFIPointer())

local currentStep = 0
local maxSteps = 8 + (lloydIterations * 2)

local function getColorKey(r, g, b)
	return ('%s;%s;%s'):format(r, g, b)
end

local function getColorFromKey(key)
	local rStr, gStr, bStr = key:match('^(%d+);(%d+);(%d+)$')
	return tonumber(rStr), tonumber(gStr), tonumber(bStr)
end

local function updateProgress()
	love.thread.getChannel('prov_generator_progress'):push(currentStep / maxSteps)
end

local function iterateOverPixels(pointer, callback)
	local lastUpdate = 0
	local max = (4 * pixelCount) - 1

	for i = 0, max, 4 do
		local r, g, b, a = pointer[i], pointer[i + 1], pointer[i + 2], pointer[i + 3]

		local pos = i / 4
		local x = pos % width
		local y = math.floor(pos / width)

		local newR, newG, newB, newA = callback(x, y, r, g, b, a)
		if newR then
			pointer[i] = newR
			pointer[i + 1] = newG
			pointer[i + 2] = newB
			pointer[i + 3] = newA
		end

		if love.timer.getTime() - lastUpdate > 0.25 then
			lastUpdate = love.timer.getTime()
			love.thread.getChannel('prov_generator_progress'):push((currentStep + (i / max)) / maxSteps)
		end
	end

	currentStep = currentStep + 1
	updateProgress()
end

-- Flood fill (4-смежность) для выделения связной компоненты, начинающейся с (x, y)
local function floodFill(x, y, origR, origG, origB, width, height, imageData, visited)
	local stack = {{x = x, y = y}}
	local compPixels = {}
	local compKey = getColorKey(origR, origG, origB)
	while #stack > 0 do
		local pos = table.remove(stack)
		local px, py = pos.x, pos.y
		if px >= 0 and px < width and py >= 0 and py < height then
			local idx = px + py * width + 1
			if not visited[idx] then
				local r, g, b, a = imageData:getPixel(px, py)
				if getColorKey(love.math.colorToBytes(r, g, b)) == compKey then
					visited[idx] = true
					table.insert(compPixels, {x = px, y = py})
					table.insert(stack, {x = px + 1, y = py})
					table.insert(stack, {x = px - 1, y = py})
					table.insert(stack, {x = px, y = py + 1})
					table.insert(stack, {x = px, y = py - 1})
				end
			end
		end
	end
	return { key = compKey, pixels = compPixels, size = #compPixels }
end

-- Функция устранения анклавов: для каждого цвета оставляем основную (наибольшую) компоненту,
-- а остальные (анклавы) переопределяем на основе голосования среди соседей.
local function removeEnclaves(imageData, imageDataPointer, origImageData)
	local width, height = imageData:getDimensions()
	local visited = {}

	-- Собираем компоненты для каждого цвета
	local compsByColor = {}  -- [colorKey] = { main = comp, extras = { comp1, comp2, ... } }
	iterateOverPixels(imageDataPointer, function(x, y, r, g, b, a)
		local idx = x + y * width + 1
		if not visited[idx] then
			local comp = floodFill(x, y, r, g, b, width, height, imageData, visited)
			if not compsByColor[comp.key] then
				compsByColor[comp.key] = { main = comp, extras = {} }
			else
				if comp.size > compsByColor[comp.key].main.size then
					table.insert(compsByColor[comp.key].extras, compsByColor[comp.key].main)
					compsByColor[comp.key].main = comp
				else
					table.insert(compsByColor[comp.key].extras, comp)
				end
			end
		end
	end)

	-- Для каждого анклава определяем новый цвет, голосуя среди соседей
	for _, group in pairs(compsByColor) do
		for _, comp in ipairs(group.extras) do
			local neighborVotes = {}  -- голоса за цвета соседей
			local inComp = {}
			for _, pos in ipairs(comp.pixels) do
				local idx = pos.x + pos.y * width + 1
				inComp[idx] = true
			end
			for _, pos in ipairs(comp.pixels) do
				local x, y = pos.x, pos.y
				local origR = origImageData:getPixel(x, y)
				local neighbors = {
					{x = x + 1, y = y},
					{x = x - 1, y = y},
					{x = x, y = y + 1},
					{x = x, y = y - 1},
				}
				for _, n in ipairs(neighbors) do
					if n.x >= 0 and n.x < width and n.y >= 0 and n.y < height then
						local nIdx = n.x + n.y * width + 1
						if not inComp[nIdx] then
							local origNeighborR = origImageData:getPixel(n.x, n.y)
							
							if origR == origNeighborR then
								local nr, ng, nb, na = imageData:getPixel(n.x, n.y)
								local nKey = getColorKey(love.math.colorToBytes(nr, ng, nb))
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
				local newR, newG, newB = love.math.colorFromBytes(getColorFromKey(bestKey))
				for _, pos in ipairs(comp.pixels) do
					imageData:setPixel(pos.x, pos.y, newR, newG, newB, 1)
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
		local r, g, b, a = inputData:getPixel(x, y)
		if r == 1 then
			table.insert(landSeeds, {
				x = x,
				y = y,
				color = {
					love.math.random(20, 255),
					love.math.random(20, 255),
					love.math.random(20, 255),
				}
			})
		end
	end

	currentStep = currentStep + 1
	updateProgress()

	-- Генерация семян для провинций в океане
	local oceanSeeds = {}
	while #oceanSeeds < nOceanProvinces do
		local x = love.math.random(0, width - 1)
		local y = love.math.random(0, height - 1)
		local r, g, b, a = inputData:getPixel(x, y)
		if r == 0 then
			table.insert(oceanSeeds, {
				x = x,
				y = y,
				color = {
					love.math.random(20, 255),
					love.math.random(20, 255),
					love.math.random(20, 255),
				}
			})
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
		local origR = inputData:getPixel(x, y)
		if origR == 1 then
			local bestIndex, bestDist = 1, math.huge
			for i, seed in ipairs(landSeeds) do
				local dx = x - seed.x
				local dy = y - seed.y
				local dist = dx ^ 2 + dy ^ 2
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
				local dist = dx ^ 2 + dy ^ 2
				if dist < bestDist then
					bestDist = dist
					bestIndex = i
				end
			end
			local col = oceanSeeds[bestIndex].color
			return col[1], col[2], col[3], 255
		end
	end)

	removeEnclaves(newImageData, newImageDataPointer, inputData)

	currentStep = currentStep + 1
	updateProgress()

	local provinces = {}

	iterateOverPixels(newImageDataPointer, function(x, y, r, g, b, a)
		local curCol = getColorKey(r, g, b)
		local curProv = provinces[curCol]

		if not curProv then
			local origR = inputData:getPixel(x, y)
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

			local col = getColorKey( love.math.colorToBytes(newImageData:getPixel(x, y)) )
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
		csv = csv .. ('%s;%s;%s;%s\n'):format(id, rgb, province.type, province.isCoastal)
	end

	love.thread.getChannel('prov_generator'):push({
		csv = csv,
		imgData = newImageData,
	})
end

start()