gamecycle = gamecycle or {}
gamecycle.event = gamecycle.event or {}
gamecycle.event.ui = gamecycle.event.ui or {}

gui.registerFont('gamecycle.event.ui', {
	font = 'Montserrat-Medium',
	size = 14,
})

local style = {
	window = {
		['fixed background'] = '#00000000',
		['scrollbar size'] = {x = 8, y = 0},
		padding = {x = 0, y = 0},
	},
}

function gamecycle.event.ui.showWindow(text, buttons)
	gamecycle.event.ui._window = {
		text = text,
		buttons = buttons,
	}
end

hook.Add('AssetsLoaded', 'gamecycle.event.ui', function()
	style.font = gui.getFont('gamecycle.event.ui')
end)

hook.Add('UI', 'gamecycle.event.ui', function(dt)
	if not style.font then return end

	local window = gamecycle.event.ui._window
	if not window then return end

	local popupW, popupH = ScrW() / 2, ScrH() / 2
	local popupX, popupY = ScrW() / 2 - popupW / 2, ScrH() / 2 - popupH / 2

	local _, wrapLimit = style.font:getWrap( window.text, popupW - 40 )
	local th = #wrapLimit * style.font:getHeight()

	ui:stylePush(style)
		if ui:windowBegin('gamecycle_event_ui', popupX, popupY, popupW, popupH, 'background') then
			if ui:popupBegin('dynamic', 'Событие', 0, 0, popupW, popupH, 'title', 'scrollbar') then
				for _, v in ipairs(wrapLimit) do
					ui:layoutRow('dynamic', style.font:getHeight(), 1)
					ui:label(v)
				end

				for _, btn in ipairs(window.buttons) do
					ui:layoutRow('dynamic', 28, 1)
					if ui:button(btn.text) then
						if btn.callback then btn.callback() end
						
						gamecycle.event.ui._window = nil
					end
				end
				ui:popupEnd()
			end
		end
		ui:windowEnd()
	ui:stylePop()
end)