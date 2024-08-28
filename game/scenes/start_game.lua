local curScene = {}
local style = {}
local countryEntry = {
	name = {value = ''},
	regionName = {value = ''},
	capitalName = {value = ''},
	color = {value = '#ff0000'},
}

local popupClosed = true

local hintText

gui.registerFont('start_game', {
	font = 'Montserrat-Medium',
	size = 20,
})

function curScene:Initialize()
	hintText = love.graphics.newText(gui.getFont('start_game'))
	hintText:setf('Выберите место старта', ScrW(), 'center')

	style[1] = {
		font = gui.getFont('start_game'),
		window = {
			['fixed background'] = '#00000000',
			-- ['background'] = '#00000000',
			padding = {x = 0, y = 0},
		},
	}
end

function curScene:WindowResized(w, h)
	if not hintText then return end

	hintText:setf('Выберите место старта', w, 'center')
end

function curScene:DrawUI()
	if not hintText then return end

	local padH = 48
	local buttonPadH = 32 + 20

	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.rectangle('fill', 0, 0, ScrW(), padH)

	love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
	love.graphics.rectangle('fill', 0, ScrH() - buttonPadH, ScrW(), buttonPadH)

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(hintText, 0, padH / 2 - hintText:getHeight() / 2)
end

function curScene:UI(dt)
	local w, h = ScrW(), 32 + 10
	local x, y = 0, ScrH() - h

	local buttonW, buttonH = 128, 32

	local popupW, popupH = ScrW() / 2, ScrH() / 2
	local popupX, popupY = ScrW() / 2 - popupW / 2, ScrH() / 2 - popupH / 2

	ui:stylePush(style[1])
		if not popupClosed and ui:windowBegin('start_game_popups', 0, 0, ScrW(), ScrH(), 'background') then
			if not popupClosed and ui:popupBegin('dynamic', 'Создание страны', popupX, popupY, popupW, popupH, 'title', 'closable') then
				ui:layoutRow('dynamic', 26, 2)
				ui:label('Название страны:')
				ui:edit('simple', countryEntry.name)

				ui:layoutRow('dynamic', 26, 2)
				ui:label('Название столичного региона:')
				ui:edit('simple', countryEntry.regionName)

				ui:layoutRow('dynamic', 26, 2)
				ui:label('Название столицы:')
				ui:edit('simple', countryEntry.capitalName)

				ui:layoutRow('dynamic', 128, 2)
				ui:label('Цвет страны:')
				ui:colorPicker(countryEntry.color, 'RGB')

				ui:layoutRow('dynamic', 28, 1)
				if ui:button('Создать') then
					local name, regionName, capitalName, colorHex = countryEntry.name.value, countryEntry.regionName.value, countryEntry.capitalName.value, countryEntry.color.value
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

					local r, g, b = nuklear.colorParseRGBA(colorHex)
					if not r then return end

					if r < 50 and g < 50 and b < 50 then
						r, g, b = 50, 50, 50
					end

					r, g, b = love.math.colorFromBytes(r, g, b)
					if not r then return end

					local r = country.newRegion(regionName, capitalName)
					r:AddProvince(map._selectedProvince)

					local c = country.newCountry(name, {r, g, b}, r)
					c:AddRegion(r)

					game.myCountry = c
					scene.change('map', true)
					hook.Run('GameStarted')
				end
				
				::continue::
				ui:popupEnd()
			else
				popupClosed = true
			end
		end
		ui:windowEnd()

		if ui:windowBegin('start_game', x, y, w, h) then
			ui:layoutSpaceBegin('static', h, 1)
				ui:layoutSpacePush(w - buttonW - 10, 0, buttonW, buttonH)
				if ui:button('Начать') then
					if not map._selectedProvince then return notify.show('error', 2, 'Нужно выбрать провинцию!') end

					popupClosed = nil
				end
			ui:layoutSpaceEnd()
		end
		ui:windowEnd()
	ui:stylePop()
end

return curScene