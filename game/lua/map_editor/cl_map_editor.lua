mapEditor = mapEditor or {}

gui.registerFont('map_editor', {
	font = 'Montserrat-Medium',
	size = 20,
})

local hintText
local btnW, btnH = 128, 28

local style = {
	window = {
		['fixed background'] = '#00000000',
		padding = {x = 0, y = 0},
	},
}

--[[ SETTINGS
	-- Что будет выбирать игрок в редакторе
	selectTarget = 'province'/'region',

	-- Доступен ли альтернативный выбор (ПКМ)
	select2 = false/true,

	-- Фильтр, определяющий логику выбора target/excludeRegions (отрисовка)
	targetFilter = function(editor)
		return targetRegions, excludeRegions
	end,

	-- Регионы, которые будут в редакторе, но будут недоступны
	blockRegions = {id, id2, id3},

	-- Регионы этой страны будут использоваться в редакторе (отрисовка)
	country = Country,

	-- Регионы, которые будут использоваться в редакторе (отрисовка)
	regions = {id, id2, id3},

	-- Регионы, которые НЕ будут использоваться в редакторе (замена regions) (отрисовка)
	excludeRegions = {id, id2, id3},

	-- Фильтр, определяющий логику выбора target/exclude (выделение)
	selectTargetFilter = function(editor)
		return target, exclude, targetMap
	end,

	-- Регионы/провинции этой страны будут использоваться в редакторе (выделение)
	selectCountry = Country,

	-- Регионы/провинции, которые будут использоваться в редакторе (выделение)
	selectTargets = {id, id2, id3},

	-- Регионы/провинции, которые НЕ будут использоваться в редакторе (замена selectTargets) (выделение)
	selectExclude = {id1, id2, id3},

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

	local targetRegions
	local excludeRegions

	if settings.country then
		targetRegions = table.GetKeys(settings.country:GetRegions())
	elseif settings.regions then
		targetRegions = settings.regions
	elseif settings.excludeRegions then
		excludeRegions = settings.excludeRegions
	end

	editor._target = {targetRegions, excludeRegions}
	return targetRegions, excludeRegions
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
	style.font = gui.getFont('map_editor')
	hintText = love.graphics.newText(gui.getFont('map_editor'))
end)

hook.Add('UI', 'mapEditor', function()
	local editor = mapEditor._editor
	if not editor then return end

	local settings = editor.settings

	local w, h = btnW * 2 + 15, btnH
	local x, y = ScrW() - w - 10, ScrH() - h - 10

	ui:stylePush(style)
		if ui:windowBegin('map_editor', x, y, w, h) then
			ui:layoutSpaceBegin('static', h, 2)
				ui:layoutSpacePush(w - btnW, 0, btnW, btnH)
				if ui:button(settings.sendBtnText or 'Применить') then
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

				ui:layoutSpacePush(0, 0, btnW, btnH)
				if ui:button(settings.cancelBtnText or 'Отмена') then
					mapEditor.close()
				end
			ui:layoutSpaceEnd()
		end
		ui:windowEnd()
	ui:stylePop()
end)

hook.Add('DrawUI', 'mapEditor', function()
	if not hintText then return end

	local editor = mapEditor._editor
	if not editor then return end

	local settings = editor.settings

	hintText:setf(settings.hint or 'Редактор', ScrW() - 10, 'center')

	local padH = math.max(48, hintText:getHeight() + 10)
	local buttonPadH = 32 + 20

	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.rectangle('fill', 0, 0, ScrW(), padH)

	love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
	love.graphics.rectangle('fill', 0, ScrH() - buttonPadH, ScrW(), buttonPadH)

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(hintText, 0, padH / 2 - hintText:getHeight() / 2)
end)

local function drawBlockedRegion(editor, regID, reg)
	local settings = editor.settings
	
	for id, province in pairs(reg:GetProvinces()) do
		local r, g, b = unpack(settings.blockedRegionCol or {0.2, 0.2, 0.2})

		love.graphics.push()
			love.graphics.translate(map._centerX, 0)
			love.graphics.setColor(r, g, b)
			province:Draw()
		love.graphics.pop()

		love.graphics.push()
			love.graphics.translate(map._minX, 0)
			love.graphics.setColor(r, g, b)
			province:Draw()
		love.graphics.pop()

		love.graphics.push()
			love.graphics.translate(map._maxX, 0)
			love.graphics.setColor(r, g, b)
			province:Draw()
		love.graphics.pop()
	end
end

local function drawRegion(editor, regID, reg)
	local settings = editor.settings

	for id, province in pairs(reg:GetProvinces()) do
		local col = settings.targetCol or {0.5, 0.5, 0.5}

		if editor._selected2 == id then
			col = settings.selectedCol2 or {1, 1, 1}
		elseif editor._selected[id] then
			col = settings.selectedCol or {0.8, 0.8, 0.8}
		end

		if settings.proccessProvince then
			local newCol = settings.proccessProvince(regID, reg, id, province)
			if newCol then
				col = newCol
			end
		end

		local r, g, b = unpack(col)

		love.graphics.push()
			love.graphics.translate(map._centerX, 0)
			love.graphics.setColor(r, g, b)
			province:Draw()
		love.graphics.pop()

		love.graphics.push()
			love.graphics.translate(map._minX, 0)
			love.graphics.setColor(r, g, b)
			province:Draw()
		love.graphics.pop()

		love.graphics.push()
			love.graphics.translate(map._maxX, 0)
			love.graphics.setColor(r, g, b)
			province:Draw()
		love.graphics.pop()
	end
end

hook.Add('Draw', 'mapEditor', function()
	local editor = mapEditor._editor
	if not editor then return end

	local settings = editor.settings

	local blockRegions = settings.blockRegions
	local targetRegions, excludeRegions = mapEditor.getTarget()

	if targetRegions then
		for _, regID in ipairs(targetRegions) do
			local reg = country.getRegion(regID)
			if not reg then goto continue end

			if blockRegions and blockRegions[regID] then
				drawBlockedRegion(editor, regID, reg)
				goto continue
			end

			drawRegion(editor, regID, reg)

			::continue::
		end
	elseif excludeRegions then
		for regID, reg in pairs(country._regions) do
			if excludeRegions[regID] then goto continue end

			if blockRegions and blockRegions[regID] then
				drawBlockedRegion(editor, regID, reg)
				goto continue
			end

			drawRegion(editor, regID, reg)

			::continue::
		end
	end
end)