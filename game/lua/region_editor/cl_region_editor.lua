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

function regionEditor.open(region, settings, callback)
	regionEditor._editor = {
		region = region,
		settings = settings,
		callback = callback,

		_selectedProvinces = {},
	}
end

function regionEditor.close()
	regionEditor._editor = nil
	gamecycle._blocked = nil
end

hook.Add('AssetsLoaded', 'regionEditor', function()
	style.font = gui.getFont('region_editor')

	hintText = love.graphics.newText(gui.getFont('region_editor'))
end)

hook.Add('UI', 'regionEditor', function()
	local editor = regionEditor._editor
	if not editor then return end

	local w, h = btnW * 2 + 15, btnH
	local x, y = ScrW() - w - 10, ScrH() - h - 10

	ui:stylePush(style)
		if ui:windowBegin('region_editor', x, y, w, h) then
			ui:layoutSpaceBegin('static', h, 2)
				ui:layoutSpacePush(w - btnW, 0, btnW, btnH)
				if ui:button('Создать') then
					if editor.settings.needProvinces and table.IsEmpty(editor._selectedProvinces) then
						notify.show('error', 2, 'Нужно выбрать провинции!')
						goto continue
					end

					if editor.settings.needCapital and not editor._selectedCapital then
						notify.show('error', 2, 'Нужно выбрать столицу!')
						goto continue
					end

					if editor.callback then
						editor.callback(editor)
					end

					::continue::
				end

				ui:layoutSpacePush(0, 0, btnW, btnH)
				if ui:button('Отмена') then
					regionEditor.close()
				end
			ui:layoutSpaceEnd()
		end
		ui:windowEnd()
	ui:stylePop()
end)

hook.Add('DrawUI', 'regionEditor', function()
	if not hintText then return end

	local editor = regionEditor._editor
	if not editor then return end

	hintText:setf(editor.settings.hint or 'Выберите провинции для нового региона\nЛКМ - выделить/снять выделение ПКМ - выбрать столицу', ScrW() - 10, 'center')

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
	local editor = regionEditor._editor
	if not editor then return end

	local region = editor.region

	for id, province in pairs(region:GetProvinces()) do
		local col = {0.5, 0.5, 0.5}

		if editor._selectedCapital == id then
			col = {1, 1, 1}
		elseif editor._selectedProvinces[id] then
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