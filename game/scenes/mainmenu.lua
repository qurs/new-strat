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
					if ui:button('Создать сервер') then
						gameloader.load('server')
						net.OpenServer(1337)
					end
					if ui:button('Присоединиться') then
						gameloader.load('client')
						net.Connect('127.0.0.1:1337')
					end
					if ui:button('Начать игру') then
						scene.change('map', true)
					end
				ui:layoutSpaceEnd()
			ui:layoutSpaceEnd()
		end
		ui:windowEnd()
	ui:stylePop()
	ui:frameEnd()
end

return curScene