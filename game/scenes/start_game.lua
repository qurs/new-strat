local curScene = {}

local countryEntry = {
	name = ffi.new('char[64]'),
	regionName = ffi.new('char[32]'),
	capitalName = ffi.new('char[32]'),
	color = ffi.new('float[3]'),
}

local hintText
local buttonW, buttonH = 128, 32

gui.registerFont('start_game', {
	font = 'Montserrat-Medium',
	size = 20,
})

gui.registerFont('start_game_hint', {
	font = 'Montserrat-Medium',
	size = 16,
})

function curScene:Initialize()
	hintText = love.graphics.newText(gui.getFont('start_game'))
	hintText:setf('Выберите место старта', ScrW(), 'center')
end

function curScene:WindowResized(w, h)
	if not hintText then return end
	hintText:setf('Выберите место старта', w, 'center')
end

function curScene:PreDrawUI()
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
				scene.change('mainmenu')
			end

			imgui.SameLine()
			imgui.SetCursorPosX(cw + style.WindowPadding.x - buttonW)

			if imgui.Button('Начать', {buttonW, buttonH}) then
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