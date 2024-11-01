local curScene = {}

gui.registerFont('mainmenu', {
	font = 'Montserrat-Medium',
	size = 18,
})

function curScene:UI()
	local font = gui.getFontImgui('mainmenu')
	local flags = imgui.love.WindowFlags('NoTitleBar', 'NoBackground', 'NoMove', 'NoResize', 'NoCollapse')

	imgui.SetNextWindowPos({0, 0})
	imgui.SetNextWindowSize({ScrW(), ScrH()})

	imgui.PushFont(font)
	if imgui.Begin('STRAT', nil, flags) then
		local style = imgui.GetStyle()

		uiLib.verticalAlign({
			function()
				local height = 30
				return height, function()
					if uiLib.alignedButton('Начать игру', 0.5, {276, height}) then
						scene.change('start_game')
					end
				end
			end,

			function()
				local height = 30
				return height, function()
					if uiLib.alignedButton('Сетевая игра', 0.5, {276, height}) then
						scene.change('multiplayer')
					end
				end
			end,
		}, 0.5)
	end
	imgui.End()
	imgui.PopFont()
end

return curScene