local curScene = {}

local countryEntry = {
	name = ffi.new('char[64]'),
	regionName = ffi.new('char[32]'),
	capitalName = ffi.new('char[32]'),
	color = ffi.new('float[3]'),
}

local loaded = false

local hintText, loadingText
local buttonW, buttonH = 128, 32

gui.registerFont('start_game', {
	font = 'Montserrat-Medium',
	size = 20,
})

gui.registerFont('start_game_hint', {
	font = 'Montserrat-Medium',
	size = 16,
})

local maxStepProvinces = 0
local currentProvStep

local generatedMapData, generatedProvincesData

local function provinceLoadHandler(result)
	if result.type == 'sea' then return end -- пока что не обрабатываем воду

	map = map or {}
	map._provinces = map._provinces or {}
	map._provincesMap = map._provincesMap or {}

	-- local id = result.id
	local id = #map._provinces + 1

	local meta = country.newProvince(id, {
			rgb255 = result.rgb255,
			rgb = { love.math.colorFromBytes(unpack(result.rgb255)) },
			colorID = result.colorID,
		},
		result.pixels,
		result.pixelsMap,
		Vector(unpack(result.minPos)),
		Vector(unpack(result.maxPos))
	)

	meta._temp_neighbors = result.neighbors

	map._provinces[id] = meta
	map._provincesMap[result.colorID] = id
end

local function finishLoading()
	print('prov loaded!')

	for i, province in ipairs(map._provinces) do
		local tbl = {}
		for colorID in pairs(province._temp_neighbors) do
			tbl[#tbl + 1] = map._provinces[ map._provincesMap[colorID] ]
		end

		province.neighbors = tbl
		province._temp_neighbors = nil
	end

	map.load(generatedProvincesData, generatedMapData)
	loaded = true
end

local function generateMap()
	mapGen.newGenerator()
		:SetSize(4096, 2048)
		:SetRemoveLakes(true)
		:SetMinIslandSize(5000)
	:SetCallback(function()
		print('Map generated!')

		provinceMapGen.newGenerator()
			:SetLandSize(3500)
			:SetOceanSize(40000)
			:SetLloydIterations(3)
			:SetCallback(function(self)
				print('Province map generated!')

				generatedMapData = love.image.newImageData('mapgenerator/map.png')
				generatedProvincesData = love.image.newImageData('mapgenerator/province_map.png')
			
				for line in love.filesystem.lines('mapgenerator/provinces.csv') do
					maxStepProvinces = maxStepProvinces + 1
				end

				currentProvStep = 0
				love.thread.newThread('threads/load_provinces.lua'):start(self.csvPath, generatedProvincesData)
			end)
			:Generate()
	end)
	:Generate()
end

function curScene:Initialize()
	hintText = love.graphics.newText(gui.getFont('start_game'))
	hintText:setf('Выберите место старта', ScrW(), 'center')

	loadingText = love.graphics.newText(gui.getFont('start_game'))
	loadingText:setf('Подождите, идет генерация карты...', ScrW(), 'center')

	generateMap()
end

function curScene:Think(dt)
	if loaded then return end
	if not currentProvStep then return end

	if currentProvStep >= maxStepProvinces then
		return finishLoading()
	end

	local channel = love.thread.getChannel('province_loader')
	if channel then
		local result = channel:pop()
		if result then
			currentProvStep = currentProvStep + 1
			provinceLoadHandler(result)

			if currentProvStep >= maxStepProvinces then
				finishLoading()
			end
		end
	end
end

function curScene:WindowResized(w, h)
	if hintText then
		hintText:setf('Выберите место старта', w, 'center')
	end

	if loadingText then
		loadingText:setf('Подождите, идет генерация карты...', w, 'center')
	end
end

function curScene:PreDrawUI()
	if not loaded then
		local progressBarW, progressBarH = 256, 16
		local th = loadingText:getHeight()

		local ty = ScrH() / 2 - th - progressBarH - 8
		local progressBarX, progressBarY = ScrW() / 2 - progressBarW / 2, ty + th + 8

		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(loadingText, 0, ty)

		local mapGenProgress = mapGen._isGenerating and mapGen.getProgress() or 1
		local provGenProgress = provinceMapGen._isGenerating and provinceMapGen.getProgress() or (mapGen._isGenerating and 0 or 1)
		local provProcessProgress = currentProvStep and currentProvStep / maxStepProvinces or 0

		local progress = (mapGenProgress + provGenProgress + provProcessProgress) / 3

		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.rectangle('fill', progressBarX - 1, progressBarY - 1, progressBarW + 2, progressBarH + 2)

		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle('fill', progressBarX, progressBarY, progressBarW * progress, progressBarH)

		return
	end
	
	if not hintText then return end

	local style = imgui.GetStyle()

	local buttonPadH = buttonH + style.WindowPadding.y * 4
	local padH = 48

	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.rectangle('fill', 0, 0, ScrW(), padH)

	love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
	love.graphics.rectangle('fill', 0, ScrH() - buttonPadH, ScrW(), buttonPadH)

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(hintText, 0, padH / 2 - hintText:getHeight() / 2)
end

function curScene:UI()
	if not loaded then return end

	local font = gui.getFontImgui('start_game')
	local hintFont = gui.getFontImgui('start_game_hint')

	local flags = imgui.love.WindowFlags('NoBackground', 'NoTitleBar', 'NoMove', 'NoResize', 'NoCollapse')
	local popupFlags = imgui.love.WindowFlags('NoMove', 'NoResize', 'NoCollapse')

	local style = imgui.GetStyle()

	local w, h = ScrW(), buttonH + style.WindowPadding.y * 4
	local x, y = 0, ScrH() - h

	local popupW, popupH = 450, math.min(ScrH() / 2, 400)
	local popupX, popupY = ScrW() / 2 - popupW / 2, ScrH() / 2 - popupH / 2

	imgui.SetNextWindowPos({x, y})
	imgui.SetNextWindowSize({w, h})

	imgui.PushFont(font)
	if imgui.Begin('start_game', nil, flags) then
		local cw = imgui.GetContentRegionAvail().x

		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_Button, {0.3, 0.3, 0.3, 1})
			imgui.SetCursorPosY(imgui.GetContentRegionAvail().y - buttonH)

			if imgui.Button('Назад', {buttonW, buttonH}) then
				uiLib.sound.click(1)
				scene.change('mainmenu')
			end

			imgui.SameLine()
			imgui.SetCursorPosX(cw + style.WindowPadding.x - buttonW)

			if imgui.Button('Начать', {buttonW, buttonH}) then
				uiLib.sound.click(1)

				if not map._selectedProvince then return notify.show('error', 2, 'Нужно выбрать провинцию!') end

				imgui.OpenPopup_Str('start_game')
			end
		imgui.PopStyleColor(1)

		imgui.SetNextWindowPos({popupX, popupY})
		imgui.SetNextWindowSize({popupW, popupH})

		if imgui.BeginPopup('start_game', popupFlags) then
			local availX = imgui.GetContentRegionAvail().x

			imgui.PushFont(hintFont)
				local maxWidth = -math.huge
				maxWidth = math.max(maxWidth, imgui.CalcTextSize('Название страны').x)
				maxWidth = math.max(maxWidth, imgui.CalcTextSize('Название столичного региона').x)
				maxWidth = math.max(maxWidth, imgui.CalcTextSize('Название столицы').x)
				maxWidth = math.max(maxWidth, imgui.CalcTextSize('Цвет страны').x)
				
				local label = 'Название страны'
				imgui.PushItemWidth(availX - maxWidth)
					imgui.InputText(label, countryEntry.name, 64)
				imgui.PopItemWidth()

				label = 'Название столичного региона'
				imgui.PushItemWidth(availX - maxWidth)
					imgui.InputText(label, countryEntry.regionName, 32)
				imgui.PopItemWidth()

				label = 'Название столицы'
				imgui.PushItemWidth(availX - maxWidth)
					imgui.InputText(label, countryEntry.capitalName, 32)
				imgui.PopItemWidth()

				label = 'Цвет страны'
				imgui.PushItemWidth(availX - maxWidth)
					imgui.ColorEdit3(label, countryEntry.color)
				imgui.PopItemWidth()
			imgui.PopFont()

			if imgui.Button('Создать') then
				uiLib.sound.click(1)

				local name, regionName, capitalName, r, g, b = ffi.string(countryEntry.name), ffi.string(countryEntry.regionName), ffi.string(countryEntry.capitalName), countryEntry.color[0], countryEntry.color[1], countryEntry.color[2]
				if utf8.len(name) < 3 or utf8.len(name) > 64 then
					notify.show('error', 2.5, 'Название страны должно быть не короче 3-х и не длиннее 64-х символов!')
					goto continue
				end
				if utf8.len(regionName) < 3 or utf8.len(regionName) > 32 then
					notify.show('error', 2.5, 'Название столичного региона должно быть не короче 3-х и не длиннее 32-х символов!')
					goto continue
				end
				if utf8.len(capitalName) < 3 or utf8.len(capitalName) > 32 then
					notify.show('error', 2.5, 'Название столицы должно быть не короче 3-х и не длиннее 32-х символов!')
					goto continue
				end

				if r < 0.2 and g < 0.2 and b < 0.2 then
					r, g, b = 0.2, 0.2, 0.2
				end

				local reg = country.newRegion(regionName, capitalName)
				reg:AddProvince(map._selectedProvince)

				local c = country.newCountry(name, {r, g, b}, reg)
				c:AddRegion(reg)

				game.myCountry = c
				scene.change('map', true)
				hook.Run('GameStarted')

				::continue::
			end

			imgui.EndPopup()
		end

	end
	imgui.End()
	imgui.PopFont()
end

return curScene