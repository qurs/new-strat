map = map or {}
map._provinces = map._provinces or {}
map._provincesMap = map._provincesMap or {}

map.debugProvinces = false

local vector_origin = Vector()

function map.worldToImage(x, y)
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

	love.graphics.setCanvas({map._canvas, stencil = true})
		love.graphics.clear(0, 0, 0, 0)
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(mapImg, 0, 0, 0, ratio)

		for id, country in pairs(country._countries) do
			country:Draw()
		end
	love.graphics.setCanvas()
end

local function parseProvinces(path)
	local file = io.open(path, 'r')
	local tbl = {}
	local map = {}

	for line in file:lines() do
		local data = string.Split(line, ';')
		local id = tonumber(data[1])
		local r, g, b = tonumber(data[2]), tonumber(data[3]), tonumber(data[4])
		local hex = nuklear.colorRGBA(r, g, b)

		local meta = country.newProvince(id, {
			rgb255 = {r, g, b},
			rgb = {r / 255, g / 255, b / 255},
			hex = hex,
		})

		tbl[id] = meta
		map[hex] = id
	end

	file:close()

	return tbl, map
end

hook.Add('AssetsLoaded', 'map', function()
	camera.setPos(vector_origin)

	map._provincesBMP = Bmp.from_file('game/assets/provinces.bmp')
	map._provinces, map._provincesMap = parseProvinces('game/assets/provinces.csv')

	local img = assetloader.get('map')
	local w, h = img:getWidth(), img:getHeight()

	local provincesImg = assetloader.get('map_provinces')
	provincesImg:setFilter('nearest', 'nearest')

	local pw, ph = provincesImg:getWidth(), provincesImg:getHeight()

	map._img = {
		img = img,
		size = {w, h},
		provinces = {
			img = provincesImg,
			size = {pw, ph},
		},
	}

	do
		local c = country.newCountry(1, 'Test Country', {1, 0, 0})

		local r = country.newRegion(1, 'Region 1')
		for i = 1, 10 do
			r:AddProvince(map._provinces[i])
		end

		c:AddRegion(r)
	end
	
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
	if scene.getName() ~= 'map' then return end

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
			province:Draw(true)
		love.graphics.pop()

		love.graphics.push()
			love.graphics.translate(map._minX, 0)
			province:Draw(true)
		love.graphics.pop()

		love.graphics.push()
			love.graphics.translate(map._maxX, 0)
			province:Draw(true)
		love.graphics.pop()
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

	local bmp = map._provincesBMP
	if not bmp then return end

	local imgX, imgY = map.worldToImage(x, y)

	if map.debugProvinces then
		map._debugProvincesLastClick = {
			endtime = os.clock() + 1,
			x = imgX,
			y = imgY,
		}
	end

	local r, g, b = bmp:get_pixel(imgX, imgY)
	if not r then return end

	local hex = nuklear.colorRGBA(r, g, b)

	local id = map._provincesMap[hex]
	if not id then
		if button == 1 and map._selectedProvince then
			map._selectedProvince = nil
		end
		return
	end

	local province = map._provinces[id]
	if not province then return end

	province:OnClick(button)
end)