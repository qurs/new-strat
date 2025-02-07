map = map or {}
map._provinces = map._provinces or {}
map._provincesMap = map._provincesMap or {}

map.debugProvinces = false
map.debugRecursiveMap = false

local vector_origin = Vector()

function map.screenToImage(x, y)
	if not map._img then return end

	local imgData = map._img
	if not imgData then return end

	local mapW, mapH = unpack(imgData.size)
	local ratio = ScrH() / mapH

	local worldX, worldY = camera.screenToWorld(x, y)

	local imgX = math.floor(worldX / ratio)
	local imgY = math.floor(worldY / ratio)

	if imgX > mapW then
		imgX = imgX - mapW
	elseif imgX < 0 then
		imgX = imgX + mapW
	end

	if imgX < 0 or imgX > mapW - 1 or imgY < 0 or imgY > mapH - 1 then return end

	return imgX, imgY
end

function map.imageToWorld(x, y)
	if not map._img then return end

	local imgData = map._img
	if not imgData then return end

	local mapW, mapH = unpack(imgData.size)
	local ratio = ScrH() / mapH

	local imgX = math.floor(x * ratio)
	local imgY = math.floor(y * ratio)

	return imgX, imgY
end

function map.createCanvas()
	local imgData = map._img
	if not imgData then return end

	local provincesImgData = imgData.provinces

	local mapImg = imgData.img
	local mapW, mapH = unpack(imgData.size)

	local provincesImg = provincesImgData.img
	local provincesW, provincesH = unpack(provincesImgData.size)

	local ratio = ScrH() / mapH
	local w, h = mapW * ratio, mapH * ratio

	map._minX = -w
	map._maxX = w

	map._newMapSize = {w, h}

	if map._canvas then map._canvas:release() end
	map._canvas = love.graphics.newCanvas(w, ScrH())
	map._canvas:setFilter('linear', 'nearest')

	love.graphics.setCanvas(map._canvas)
		love.graphics.clear(0, 0, 0, 0)

		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(mapImg, 0, 0, 0, ratio)

		for id, country in pairs(country._countries) do
			country:Draw()
		end
	love.graphics.setCanvas()
end

function map.getProvinceByPos(x, y)
	local data = map._generatedProvincesData

	local ok, r, g, b = pcall(data.getPixel, data, x, y)
	if not ok or not r then return end

	r, g, b = love.math.colorToBytes(r, g, b)

	local colorID = ('%s,%s,%s'):format(r, g, b)

	local id = map._provincesMap[colorID]
	if not id then return end

	local province = map._provinces[id]
	if not province then return end

	return province
end

function map.getProvinceByScreenPos(x, y)
	local imgX, imgY = map.screenToImage(x, y)
	return map.getProvinceByPos(imgX, imgY)
end

function map.unload(bDontCallGC)
	map._loaded = nil

	if map._canvas then map._canvas:release() end

	if map._generatedProvincesData then map._generatedProvincesData:release() end
	if map._generatedMapData then map._generatedMapData:release() end

	if map._img and map._img.img then map._img.img:release() end
	if map._img and map._img.provinces and map._img.provinces.img then map._img.provinces.img:release() end

	map._img = nil
	map._canvas = nil
	map._generatedProvincesData = nil
	map._generatedMapData = nil
	map._newMapSize = nil
	map._minX = nil
	map._maxX = nil

	map._selectedProvince = nil
	map._selectedCountry = nil

	map._provinces = {}
	map._provincesMap = {}
	country._provinces = {}

	if bDontCallGC then return end
	collectgarbage()
end

function map.load(generatedProvincesData, generatedMapData)
	camera.setPos(vector_origin)

	map._generatedProvincesData = generatedProvincesData
	map._generatedMapData = generatedMapData

	local provincesImg = love.graphics.newImage(generatedProvincesData)
	provincesImg:setFilter('nearest', 'nearest')

	local mapImg = love.graphics.newImage(generatedMapData)
	local w, h = mapImg:getWidth(), mapImg:getHeight()

	local pw, ph = provincesImg:getWidth(), provincesImg:getHeight()

	map._img = {
		img = mapImg,
		size = {w, h},
		provinces = {
			img = provincesImg,
			size = {pw, ph},
		},
	}

	map._loaded = true

	for _, province in ipairs(map._provinces) do
		util.queuePrioritizedPreDrawMethodCall(province, 'CreateCanvas', 1)
	end

	util.queuePrioritizedPreDrawFunctionCall(map.createCanvas, 99)
end

hook.Add('WindowResized', 'map', function()
	if not map._loaded then return end

	for _, province in ipairs(map._provinces) do
		util.queuePrioritizedPreDrawMethodCall(province, 'CreateCanvas', 1)
	end

	for id, country in pairs(country._countries) do
		for id, reg in pairs(country:GetRegions()) do
			util.queuePrioritizedPreDrawMethodCall(reg, 'CreateCanvas', 2)
		end
	end

	util.queuePrioritizedPreDrawFunctionCall(map.createCanvas, 99)
end)

hook.Add('Draw', 'map', function()
	if not map._loaded then return end

	if scene.getName() ~= 'map' and scene.getName() ~= 'start_game' then return end
	if mapEditor._editor then
		local imgData = map._img
		if not imgData then return end
	
		local mapImg = imgData.img
		local mapH = imgData.size[2]
		local ratio = ScrH() / mapH

		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(mapImg, 0, 0, 0, ratio)

		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(mapImg, map._minX, 0, 0, ratio)

		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(mapImg, map._maxX, 0, 0, ratio)
		return
	end

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(map._canvas)

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(map._canvas, map._minX)

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(map._canvas, map._maxX)

	local province = map._selectedProvince
	if province then
		love.graphics.setColor(1, 1, 1)
		province:Draw(true)

		love.graphics.push()
			love.graphics.translate(map._minX, 0)
			love.graphics.setColor(1, 1, 1)
			province:Draw(true)
		love.graphics.pop()

		love.graphics.push()
			love.graphics.translate(map._maxX, 0)
			love.graphics.setColor(1, 1, 1)
			province:Draw(true)
		love.graphics.pop()
	end

	hook.Run('PreDrawOverCountry')

	for id, country in pairs(country._countries) do
		country:DrawName(0)
		country:DrawName(map._minX)
		country:DrawName(map._maxX)

		for id, region in pairs(country:GetRegions()) do
			region:DrawCapital(0)
			region:DrawCapital(map._minX)
			region:DrawCapital(map._maxX)
		end

		local units = country:GetUnits()
		local provIndexes = {}
		for i, unit in ipairs(units) do
			local prov = unit:GetProvince()
			local id = prov:GetID()
			provIndexes[id] = (provIndexes[id] or 0) + 1

			unit:Draw(provIndexes[id], 0)
			unit:Draw(provIndexes[id], map._minX)
			unit:Draw(provIndexes[id], map._maxX)
		end
	end

	hook.Run('PostDrawOverCountry')

	if map.debugRecursiveMap then
		love.graphics.setColor(1, 1, 1, 0.8)
		love.graphics.rectangle('fill', 0, 0, map._canvas:getWidth(), map._canvas:getHeight())
	
		love.graphics.setColor(0, 0, 1, 0.5)
		love.graphics.rectangle('fill', map._minX, 0, map._canvas:getWidth(), map._canvas:getHeight())
	
		love.graphics.setColor(1, 0, 0, 0.5)
		love.graphics.rectangle('fill', map._maxX, 0, map._canvas:getWidth(), map._canvas:getHeight())
	end
end)

hook.Add('DrawUI', 'map', function()
	if not map._loaded then return end

	if scene.getName() ~= 'map' and scene.getName() ~= 'start_game' then return end
	if not map.debugProvinces then return end

	local imgData = map._img
	if not imgData then return end

	local provincesImgData = imgData.provinces

	local mapImg = imgData.img
	local mapW, mapH = unpack(imgData.size)

	local provincesImg = provincesImgData.img
	local provincesW, provincesH = unpack(provincesImgData.size)

	love.graphics.push()
		love.graphics.scale(0.1)

		love.graphics.setColor(1, 0, 0)
		love.graphics.rectangle('fill', 0, 0, provincesW, provincesH)

		love.graphics.setColor(1, 1, 1, 0.5)
		love.graphics.draw(provincesImg)

		local lastClick = map._debugProvincesLastClick
		if lastClick and lastClick.endtime > os.clock() then
			love.graphics.setColor(1, 0, 0)
			love.graphics.setPointSize(8)
			love.graphics.points(lastClick.x, lastClick.y)
		end
	love.graphics.pop()
end)

hook.Add('MouseDown', 'map', function(x, y, button)
	if not map._loaded then return end

	if scene.getName() ~= 'map' and scene.getName() ~= 'start_game' then return end
	if button == 3 then return end
	if not map._provincesMap then return end

	local imgX, imgY = map.screenToImage(x, y)
	if not imgX then return end

	if map.debugProvinces then
		map._debugProvincesLastClick = {
			endtime = os.clock() + 1,
			x = imgX,
			y = imgY,
		}
	end

	local province = map.getProvinceByPos(imgX, imgY)
	if not province then return end

	province:OnClick(button)
end)

hook.Add('KeyDown', 'map', function(button)
	if not map._loaded then return end

	if scene.getName() ~= 'map' and scene.getName() ~= 'start_game' then return end
	if button == 'escape' and (map._selectedProvince or map._selectedCountry or units._selectedUnits) then
		if map._selectedProvince then map._selectedProvince = nil end
		if map._selectedCountry then map._selectedCountry = nil end
		if units._selectedUnits then units._selectedUnits = nil end

		return true
	end
end)