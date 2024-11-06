mapEditor = mapEditor or {}

gui.registerFont('map_editor', {
	font = 'Montserrat-Medium',
	size = 20,
})

local hintText, imguiFont
local btnW, btnH = 128, 28

--[[ SETTINGS
	-- Что будет выбирать игрок в редакторе
	selectTarget = 'province'/'region',

	-- Доступен ли альтернативный выбор (ПКМ)
	select2 = false/true,

	-- Одиночный выбор (выбирается только одна цель)
	singleSelect = false/true,

	-- Фильтр, определяющий логику выбора target/excludeRegions (отрисовка)
	targetFilter = function(editor)
		return targetRegions, excludeRegions
	end,

	-- Объекты, которые будут в редакторе, но будут недоступны
	renderBlockTargets = {
		[id1] = true,
		[id2] = true,
		[id3] = true,
	},

	-- Регионы этой страны будут использоваться в редакторе (отрисовка)
	country = Country,

	-- Объекты, которые будут использоваться в редакторе (отрисовка)
	renderTargets = {id, id2, id3},

	-- Цели, которые НЕ будут использоваться в редакторе (замена regions) (отрисовка)
	renderExclude = {
		[id1] = true,
		[id2] = true,
		[id3] = true,
	},

	-- Тип цели в renderTargets/renderExclude
	renderType = 'region'/'province',

	-- Фильтр, определяющий логику выбора target/exclude (выделение)
	selectTargetFilter = function(editor)
		return target, exclude, targetMap
	end,

	-- Регионы/провинции этой страны будут использоваться в редакторе (выделение)
	selectCountry = Country,

	-- Регионы/провинции, которые будут использоваться в редакторе (выделение)
	selectTargets = {id, id2, id3},

	-- Регионы/провинции, которые НЕ будут использоваться в редакторе (замена selectTargets) (выделение)
	selectExclude = {
		[id1] = true,
		[id2] = true,
		[id3] = true,
	},

	-- Определяет тип объекта в selectExclude (понадобится для оптимизации, если провинций слишком много и они все относятся к каким-то регионам)
	selectExcludeType = 'region'/'province',

	-- Текст кнопки отправки в редакторе
	sendBtnText = 'Отправить',

	-- Текст кнопки отмены в редакторе
	cancelBtnText = 'Отменить',

	-- Фильтр кнопки, который проверяет входящие данные на ошибки перед вызовом callback
	filter = function(editor)
		if not true then
			return false, 'Текст ошибки', 3
		end

		return true
	end,

	-- Текст в редакторе сверху
	hint = 'Редактор',

	-- Цвет региона, который нельзя выбрать в редакторе
	blockedRegionCol = {0.2, 0.2, 0.2},

	-- Цвет региона, который можно выбрать в редакторе
	targetCol = {0.5, 0.5, 0.5},

	-- Цвет выбранного региона
	selectedCol = {0.8, 0.8, 0.8},

	-- Цвет выбранного альтернативного региона
	selectedCol2 = {1, 1, 1},

	-- Фильтр, определяющий цвет конкретной провинции в редакторе
	proccessProvince = function(regID, reg, id, prov)
		return {1, 1, 1}
	end,
]]

function mapEditor.open(settings, callback)
	map._selectedProvince = nil

	gamecycle._blocked = true
	gamecycle.pause()

	mapEditor._editor = {
		settings = settings,
		callback = callback,
		_selected = {},
	}
end

function mapEditor.close()
	mapEditor._editor = nil
	gamecycle._blocked = nil
end

function mapEditor.getTarget()
	local editor = mapEditor._editor
	if not editor then return end

	local settings = editor.settings
	if settings.targetFilter then
		return settings.targetFilter(editor)
	end

	if editor._target then
		return unpack(editor._target)
	end

	local renderTargets
	local renderExclude

	if settings.country then
		renderTargets = table.GetKeys(settings.country:GetRegions())
	elseif settings.renderTargets then
		renderTargets = settings.renderTargets
	elseif settings.renderExclude then
		renderExclude = settings.renderExclude
	end

	editor._target = {renderTargets, renderExclude}
	return renderTargets, renderExclude
end

function mapEditor.getSelectTarget()
	local editor = mapEditor._editor
	if not editor then return end

	local settings = editor.settings
	if settings.selectTargetFilter then
		return settings.selectTargetFilter(editor)
	end

	if editor._selectTarget then
		return unpack(editor._selectTarget)
	end

	local targetMap
	local exclude

	if settings.selectCountry then
		local selectCountry = settings.selectCountry
		targetMap = {}

		if settings.selectTarget == 'province' then
			for regID, reg in pairs(selectCountry:GetRegions()) do
				for provID, prov in pairs(reg:GetProvinces()) do
					targetMap[provID] = true
				end
			end
		elseif settings.selectTarget == 'region' then
			targetMap = {}

			for id in pairs(selectCountry:GetRegions()) do
				targetMap[id] = true
			end
		end
	elseif settings.selectTargets then
		targetMap = {}

		for _, id in ipairs(settings.selectTargets) do
			targetMap[id] = true
		end
	elseif settings.selectExclude then
		exclude = settings.selectExclude
	end

	editor._selectTarget = {targetMap, exclude}
	return targetMap, exclude
end

hook.Add('AssetsLoaded', 'mapEditor', function()
	imguiFont = gui.getFontImgui('map_editor')
	hintText = love.graphics.newText(gui.getFont('map_editor'))
end)

hook.Add('DrawUI', 'mapEditor', function()
	if not imguiFont then return end

	local editor = mapEditor._editor
	if not editor then return end

	local flags = imgui.love.WindowFlags('NoTitleBar', 'NoBackground', 'NoMove', 'NoResize', 'NoCollapse', 'NoScrollbar')
	local settings = editor.settings

	local w, h = ScrW(), btnH
	local x, y = 0, ScrH() - h - 10

	imgui.SetNextWindowPos({x, y})
	imgui.SetNextWindowSize({w, h})

	imgui.PushFont(imguiFont)
	imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_WindowPadding, {10, 0})
	if imgui.Begin('map_editor', nil, flags) then
		local cw = imgui.GetContentRegionAvail().x

		if imgui.Button(settings.cancelBtnText or 'Отмена', {btnW, btnH}) then
			uiLib.sound.click(1)
			mapEditor.close()
		end

		imgui.SameLine()
		imgui.SetCursorPosX(cw + 10 - btnW)
		if imgui.Button(settings.sendBtnText or 'Применить', {btnW, btnH}) then
			uiLib.sound.click(1)

			if settings.filter then
				local ok, err, errTime = settings.filter(editor)
				if not ok then
					notify.show('error', errTime or 2, err)
					goto continue
				end
			end

			if editor.callback then
				editor.callback(editor)
			end

			::continue::
		end

		imgui.End()
	end
	imgui.PopStyleVar(1)
	imgui.PopFont()
end)

hook.Add('PreDrawUI', 'mapEditor', function()
	if not hintText then return end

	local editor = mapEditor._editor
	if not editor then return end

	local settings = editor.settings

	hintText:setf(settings.hint or 'Редактор', ScrW() - 10, 'center')

	local padH = math.max(48, hintText:getHeight() + 10)
	local buttonPadH = btnH + 20

	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.rectangle('fill', 0, 0, ScrW(), padH)

	love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
	love.graphics.rectangle('fill', 0, ScrH() - buttonPadH, ScrW(), buttonPadH)

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(hintText, 0, padH / 2 - hintText:getHeight() / 2)
end)

local function drawBlockedProvince(editor, id, prov)
	local settings = editor.settings
	local r, g, b = unpack(settings.blockedRegionCol or {0.2, 0.2, 0.2})

	love.graphics.push()
		love.graphics.translate(map._centerX, 0)
		love.graphics.setColor(r, g, b)
		prov:Draw()
	love.graphics.pop()

	love.graphics.push()
		love.graphics.translate(map._minX, 0)
		love.graphics.setColor(r, g, b)
		prov:Draw()
	love.graphics.pop()

	love.graphics.push()
		love.graphics.translate(map._maxX, 0)
		love.graphics.setColor(r, g, b)
		prov:Draw()
	love.graphics.pop()
end

local function drawBlockedRegion(editor, regID, reg)
	for id, province in pairs(reg:GetProvinces()) do
		drawBlockedProvince(editor, id, province)
	end
end

local function drawProvince(editor, id, prov)
	local settings = editor.settings

	local reg = prov:GetRegion()
	local regID = reg and reg:GetID()

	local col = settings.targetCol or {0.5, 0.5, 0.5}
	local selected = false
	if settings.singleSelect then
		selected = editor._selected == id
	else
		selected = editor._selected[id]
	end

	if editor._selected2 == id then
		col = settings.selectedCol2 or {1, 1, 1}
	elseif selected then
		col = settings.selectedCol or {0.8, 0.8, 0.8}
	end

	if settings.proccessProvince then
		local newCol = settings.proccessProvince(regID, reg, id, prov)
		if newCol then
			col = newCol
		end
	end

	local r, g, b = unpack(col)

	love.graphics.push()
		love.graphics.translate(map._centerX, 0)
		love.graphics.setColor(r, g, b)
		prov:Draw()
	love.graphics.pop()

	love.graphics.push()
		love.graphics.translate(map._minX, 0)
		love.graphics.setColor(r, g, b)
		prov:Draw()
	love.graphics.pop()

	love.graphics.push()
		love.graphics.translate(map._maxX, 0)
		love.graphics.setColor(r, g, b)
		prov:Draw()
	love.graphics.pop()
end

local function drawRegion(editor, regID, reg)
	for id, province in pairs(reg:GetProvinces()) do
		drawProvince(editor, id, province)
	end
end

hook.Add('Draw', 'mapEditor', function()
	local editor = mapEditor._editor
	if not editor then return end

	local settings = editor.settings

	local renderBlockTargets = settings.renderBlockTargets
	local renderTarget, renderExclude = mapEditor.getTarget()

	local renderType = settings.renderType or 'region'

	if renderTarget then
		for _, id in ipairs(renderTarget) do
			if renderType == 'region' then
				local reg = country.getRegion(id)
				if not reg then goto continue end
	
				if renderBlockTargets and renderBlockTargets[id] then
					drawBlockedRegion(editor, id, reg)
					goto continue
				end
	
				drawRegion(editor, id, reg)
			elseif renderType == 'province' then
				local prov = country.getProvince(id)
				if not prov then goto continue end
	
				if renderBlockTargets and renderBlockTargets[id] then
					drawBlockedProvince(editor, id, prov)
					goto continue
				end
	
				drawProvince(editor, id, prov)
			end
			
			::continue::
		end
	elseif renderExclude then
		if renderType == 'region' then
			for regID, reg in pairs(country._regions) do
				if renderExclude[regID] then goto continue end

				if renderBlockTargets and renderBlockTargets[regID] then
					drawBlockedRegion(editor, regID, reg)
					goto continue
				end

				drawRegion(editor, regID, reg)

				::continue::
			end
		elseif renderType == 'province' then
			for provID, prov in pairs(country._provinces) do
				if renderExclude[provID] then goto continue end

				if renderBlockTargets and renderBlockTargets[provID] then
					drawBlockedProvince(editor, provID, prov)
					goto continue
				end

				drawProvince(editor, provID, prov)

				::continue::
			end
		end
	end
end)