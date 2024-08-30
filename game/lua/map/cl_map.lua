map = map or {}
map._provinces = map._provinces or {}
map._provincesMap = map._provincesMap or {}

map.debugProvinces = false
map.debugRecursiveMap = false

local vector_origin = Vector()

function map.screenToImage(x, y)
	if not map._img then return end

	local img = map._img.provinces
	if not img then return end

	local mapW, mapH = unpack(img.size)
	local ratio = ScrH() / mapH

	local worldX, worldY = camera.mouseToWorld(x, y)

	local imgX = math.floor((worldX - ScrW() / 2) / ratio) + mapW / 2
	local imgY = math.floor(worldY / ratio)

	local w, h = unpack(map._mapSize.orig)
	if imgX > w then
		imgX = imgX - w
	elseif imgX < 0 then
		imgX = imgX + w
	end

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
	local x = ScrW() / 2 - w / 2

	map._centerX = x
	map._minX = x - w
	map._maxX = x + w

	map._mapSize = {
		orig = {mapW, mapH},
		new = {w, h},
	}

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
	local data = assetloader.get('map_provinces').data

	local r, g, b = data:getPixel(x, y)
	if not r then return end

	r, g, b = love.math.colorToBytes(r, g, b)

	local hex = nuklear.colorRGBA(r, g, b)

	local id = map._provincesMap[hex]
	if not id then return end

	local province = map._provinces[id]
	if not province then return end

	return province
end

function map.getProvinceByScreenPos(x, y)
	local imgX, imgY = map.screenToImage(x, y)
	return map.getProvinceByPos(imgX, imgY)
end

hook.Add('AssetsLoaded', 'map', function()
	camera.setPos(vector_origin)

	local provincesImg = assetloader.get('map_provinces').img
	provincesImg:setFilter('nearest', 'nearest')

	local img = assetloader.get('map').img
	local w, h = img:getWidth(), img:getHeight()

	local pw, ph = provincesImg:getWidth(), provincesImg:getHeight()

	map._img = {
		img = img,
		size = {w, h},
		provinces = {
			img = provincesImg,
			size = {pw, ph},
		},
	}
	
	for _, province in ipairs(map._provinces) do
		province:CreateCanvas()
	end

	map.createCanvas()
end)

hook.Add('WindowResized', 'map', function()
	for _, province in ipairs(map._provinces) do
		province:CreateCanvas()
	end

	for id, country in pairs(country._countries) do
		for id, reg in pairs(country:GetRegions()) do
			reg:CreateCanvas()
		end
	end

	map.createCanvas()
end)

hook.Add('Draw', 'map', function()
	if scene.getName() ~= 'map' and scene.getName() ~= 'start_game' then return end
	if regionEditor._editor then
		local imgData = map._img
		if not imgData then return end
	
		local mapImg = imgData.img
		local mapH = imgData.size[2]
		local ratio = ScrH() / mapH

		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(mapImg, map._centerX, 0, 0, ratio)

		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(mapImg, map._minX, 0, 0, ratio)

		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(mapImg, map._maxX, 0, 0, ratio)
		return
	end

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(map._canvas, map._centerX)

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(map._canvas, map._minX)

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(map._canvas, map._maxX)

	local province = map._selectedProvince
	if province then
		love.graphics.push()
			love.graphics.translate(map._centerX, 0)
			love.graphics.setColor(1, 1, 1)
			province:Draw(true)
		love.graphics.pop()

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
		country:DrawName(map._centerX)
		country:DrawName(map._minX)
		country:DrawName(map._maxX)

		for id, region in pairs(country:GetRegions()) do
			region:DrawCapital(map._centerX)
			region:DrawCapital(map._minX)
			region:DrawCapital(map._maxX)
		end

		local units = country:GetUnits()
		local provIndexes = {}
		for i, unit in ipairs(units) do
			local prov = unit:GetProvince()
			local id = prov:GetID()
			provIndexes[id] = (provIndexes[id] or 0) + 1

			unit:Draw(provIndexes[id], map._centerX)
			unit:Draw(provIndexes[id], map._minX)
			unit:Draw(provIndexes[id], map._maxX)
		end
	end

	if map.debugRecursiveMap then
		love.graphics.setColor(1, 1, 1, 0.8)
		love.graphics.rectangle('fill', map._centerX, 0, map._canvas:getWidth(), map._canvas:getHeight())
	
		love.graphics.setColor(0, 0, 1, 0.5)
		love.graphics.rectangle('fill', map._minX, 0, map._canvas:getWidth(), map._canvas:getHeight())
	
		love.graphics.setColor(1, 0, 0, 0.5)
		love.graphics.rectangle('fill', map._maxX, 0, map._canvas:getWidth(), map._canvas:getHeight())
	end
end)

hook.Add('DrawUI', 'map', function()
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
	if button == 'escape' then
		if map._selectedProvince then map._selectedProvince = nil end
		if map._selectedCountry then map._selectedCountry = nil end
		if units._selectedUnits then units._selectedUnits = nil end
	end
end)