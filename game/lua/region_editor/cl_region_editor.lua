regionEditor = regionEditor or {}

gui.registerFont('region_editor', {
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

country.actions.addRegionAction('Выделить регион', function(region)
	if region:GetProvinceCount() < 2 then return notify.show('error', 3, 'В регионе должно быть больше 1-й провинции, чтобы выделить еще один регион!') end

	map._selectedProvince = nil

	gamecycle._blocked = true
	gamecycle.pause()

	regionEditor._editing = region
	regionEditor._selectedProvinces = {}
end)

hook.Add('AssetsLoaded', 'regionEditor', function()
	style.font = gui.getFont('region_editor')

	hintText = love.graphics.newText(gui.getFont('region_editor'))
	hintText:setf('Выберите провинции для нового региона\nЛКМ - выделить/снять выделение ПКМ - выбрать столицу', ScrW() - 10, 'center')
end)

hook.Add('WindowResized', 'regionEditor', function(w, h)
	if not hintText then return end

	hintText:setf('Выберите провинции для нового региона\nЛКМ - выделить/снять выделение ПКМ - выбрать столицу', w - 10, 'center')
end)

hook.Add('UI', 'regionEditor', function()
	if not regionEditor._editing then return end

	local w, h = btnW * 2 + 15, btnH
	local x, y = ScrW() - w - 10, ScrH() - h - 10

	ui:stylePush(style)
		if ui:windowBegin('region_editor', x, y, w, h) then
			ui:layoutSpaceBegin('static', h, 2)
				ui:layoutSpacePush(w - btnW, 0, btnW, btnH)
				if ui:button('Создать') then
					if table.IsEmpty(regionEditor._selectedProvinces) then
						notify.show('error', 2, 'Нужно выбрать провинции!')
						goto continue
					end

					if not regionEditor._selectedCapital then
						notify.show('error', 2, 'Нужно выбрать столицу!')
						goto continue
					end

					uiLib.popup.query('Создание региона', {
						{
							type = 'edit',
							tooltip = 'Название региона',
							entry = {value = ''},
						},
						{
							type = 'edit',
							tooltip = 'Название столицы',
							entry = {value = ''},
						},
					},
					function(widgets)
						local regionName, capitalName = widgets[1].entry.value, widgets[2].entry.value
						if utf8.len(regionName) < 3 or utf8.len(regionName) > 32 then
							return notify.show('error', 2.5, 'Название региона должно быть не короче 3-х и не длиннее 32-х символов!')
						end
						if utf8.len(capitalName) < 3 or utf8.len(capitalName) > 32 then
							return notify.show('error', 2.5, 'Название столицы должно быть не короче 3-х и не длиннее 32-х символов!')
						end

						local region = regionEditor._editing
						local с = region:GetCountry()

						region:RemoveProvinces(table.GetKeys(regionEditor._selectedProvinces))

						local newRegion = country.newRegion(regionName, capitalName, regionEditor._selectedProvinces)
						newRegion:SetCapitalProvince(regionEditor._selectedCapital)

						с:AddRegion(newRegion)

						regionEditor._editing = nil
						regionEditor._selectedProvinces = nil
						regionEditor._selectedCapital = nil
						gamecycle._blocked = nil
					end)

					::continue::
				end

				ui:layoutSpacePush(0, 0, btnW, btnH)
				if ui:button('Отмена') then
					regionEditor._editing = nil
					regionEditor._selectedProvinces = nil
					regionEditor._selectedCapital = nil
					gamecycle._blocked = nil
				end
			ui:layoutSpaceEnd()
		end
		ui:windowEnd()
	ui:stylePop()
end)

hook.Add('DrawUI', 'regionEditor', function()
	if not hintText then return end
	if not regionEditor._editing then return end

	local padH = math.max(48, hintText:getHeight() + 10)
	local buttonPadH = 32 + 20

	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.rectangle('fill', 0, 0, ScrW(), padH)

	love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
	love.graphics.rectangle('fill', 0, ScrH() - buttonPadH, ScrW(), buttonPadH)

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(hintText, 0, padH / 2 - hintText:getHeight() / 2)
end)

hook.Add('Draw', 'regionEditor', function()
	local region = regionEditor._editing
	if not region then return end

	for id, province in pairs(region:GetProvinces()) do
		local col = {0.5, 0.5, 0.5}

		if regionEditor._selectedCapital == id then
			col = {1, 1, 1}
		elseif regionEditor._selectedProvinces[id] then
			col = {0.8, 0.8, 0.8}
		end

		if region:GetCapitalProvince() == id then
			col = {0.2, 0.2, 0.2}
		end

		love.graphics.push()
			love.graphics.translate(map._centerX, 0)
			love.graphics.setColor(unpack(col))
			province:Draw()
		love.graphics.pop()

		love.graphics.push()
			love.graphics.translate(map._minX, 0)
			love.graphics.setColor(unpack(col))
			province:Draw()
		love.graphics.pop()

		love.graphics.push()
			love.graphics.translate(map._maxX, 0)
			love.graphics.setColor(unpack(col))
			province:Draw()
		love.graphics.pop()
	end
end)