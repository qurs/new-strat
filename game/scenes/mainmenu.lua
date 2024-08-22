local curScene = {}
local style = {}

gui.registerFont('mainmenu', {
	font = 'Montserrat-Medium',
	size = 15,
})

function curScene:Initialize()
	style = {
		font = gui.getFont('mainmenu'),
		window = {
			['fixed background'] = '#00000000',
			padding = {x = 35, y = 35},
		},
	}
end

function curScene:Think(dt)
	local w, h = ScrW() / 2, ScrH() / 2
	local x, y = ScrW() / 2 - w / 2, ScrH() / 2 - h / 2

	ui:frameBegin()
	ui:stylePush(style)
		if ui:windowBegin('STRAT', x, y, w, h) then
			ui:layoutSpaceBegin('dynamic', 30, 1)
				ui:layoutSpacePush(0, 0, 1, 1)
					if ui:button('Начать игру') then
						scene.change('start_game')
					end

					if ui:button('Сетевая игра') then
						scene.change('multiplayer')
					end
				ui:layoutSpaceEnd()
			ui:layoutSpaceEnd()
		end
		ui:windowEnd()
	ui:stylePop()
	ui:frameEnd()
end

return curScene