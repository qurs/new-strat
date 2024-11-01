local curScene = {}

local pointer = ffi.new('char[16]')

function curScene:UI()
	local w, h = ScrW() / 2, ScrH() / 2
	local x, y = ScrW() / 2 - w / 2, ScrH() / 2 - h / 2

	local font = gui.getFontImgui('mainmenu')

	local flags = imgui.love.WindowFlags('NoTitleBar', 'NoBackground', 'NoMove', 'NoResize', 'NoCollapse')

	imgui.SetNextWindowPos({0, 0})
	imgui.SetNextWindowSize({ScrW(), ScrH()})

	imgui.PushFont(font)
	if imgui.Begin('STRAT_MP', nil, flags) then
		local style = imgui.GetStyle()

		uiLib.verticalAlign({
			function()
				local label = 'Имя игрока'
				local width = 276
				local height = imgui.CalcTextSize(label).y + style.FramePadding.y * 2

				return height, function()
					uiLib.alignForWidth(width, 0.5)

					imgui.PushItemWidth(width)
						imgui.InputText(label, pointer, 16)
					imgui.PopItemWidth()
				end
			end,

			function()
				local width = 276
				local height = 30

				return height, function()
					if uiLib.alignedButton('Создать сервер', 0.5, {width, height}) then
						local name = ffi.string(pointer)
						if utf8.len(name) < 3 then return notify.show('error', 2, 'Нужно ввести ник! (Хотя бы 3 символа)') end

						gameloader.load('client')
						gameloader.load('server')
						net.settings.Set('nickname', name)
						net.server.OpenServer(1337)
					end
				end
			end,

			function()
				local width = 276
				local height = 30

				return height, function()
					if uiLib.alignedButton('Присоединиться', 0.5, {width, height}) then
						local name = ffi.string(pointer)
						if utf8.len(name) < 3 then return notify.show('error', 2, 'Нужно ввести ник! (Хотя бы 3 символа)') end

						gameloader.load('client')
						net.settings.Set('nickname', name)
						net.Connect('127.0.0.1:1337')
					end
				end
			end,

			function()
				local height = 30
				return height, function()
					if uiLib.alignedButton('Назад', 0.5, {276, height}) then
						scene.change('mainmenu')
					end
				end
			end,
		}, 0.5)
	end
	imgui.End()
	imgui.PopFont()
end

return curScene