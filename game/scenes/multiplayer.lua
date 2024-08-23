local curScene = {}
local style = {}

local nameEntry = {value = ''}

function curScene:Initialize()
	style = {
		font = gui.getFont('mainmenu'),
		window = {
			['fixed background'] = '#00000000',
			padding = {x = 35, y = 35},
		},
	}
end

function curScene:UI(dt)
	local w, h = ScrW() / 2, ScrH() / 2
	local x, y = ScrW() / 2 - w / 2, ScrH() / 2 - h / 2

	ui:stylePush(style)
		if ui:windowBegin('STRAT', x, y, w, h) then
			ui:layoutSpaceBegin('dynamic', 30, 1)
				ui:layoutSpacePush(0, 0, 1, 1)
					ui:layoutRow('dynamic', 40, 2)
					ui:label('Имя игрока:')
					ui:edit('simple', nameEntry)

					if ui:button('Создать сервер') then
						if utf8.len(nameEntry.value) < 3 then return notify.show('error', 2, 'Нужно ввести ник! (Хотя бы 3 символа)') end

						gameloader.load('client')
						gameloader.load('server')
						net.settings.Set('nickname', nameEntry.value)
						net.server.OpenServer(1337)
					end
					if ui:button('Присоединиться') then
						if utf8.len(nameEntry.value) < 3 then return notify.show('error', 2, 'Нужно ввести ник! (Хотя бы 3 символа)') end

						gameloader.load('client')
						net.settings.Set('nickname', nameEntry.value)
						net.Connect('127.0.0.1:1337')
					end

					if ui:button('Назад') then
						scene.change('mainmenu')
					end
				ui:layoutSpaceEnd()
			ui:layoutSpaceEnd()
		end
		ui:windowEnd()
	ui:stylePop()
end

return curScene