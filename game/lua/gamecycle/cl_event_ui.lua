gamecycle = gamecycle or {}
gamecycle.event = gamecycle.event or {}
gamecycle.event.ui = gamecycle.event.ui or {}

gamecycle.event.ui._window = gamecycle.event.ui._window or {}

gui.registerFont('gamecycle.event.ui', {
	font = 'Montserrat-Medium',
	size = 14,
})

gui.registerFont('gamecycle.event.ui.planned', {
	font = 'Montserrat-Medium',
	size = 12,
})

local style = {
	window = {
		['fixed background'] = '#00000000',
		['scrollbar size'] = {x = 8, y = 0},
		padding = {x = 10, y = 10},
	},
}

local style2 = {
	font = gui.getFont('gamecycle.event.ui.planned'),
	window = {
		['scrollbar size'] = {x = 8, y = 0},
		padding = {x = 10, y = 10},
		spacing = {x = 10, y = 10},
	},
}

function gamecycle.event.ui.showWindow(text, buttons)
	gamecycle.event.ui._window[#gamecycle.event.ui._window + 1] = {
		text = text,
		buttons = buttons,
	}
end

hook.Add('AssetsLoaded', 'gamecycle.event.ui', function()
	style.font = gui.getFont('gamecycle.event.ui')
end)

hook.Add('UI', 'gamecycle.event.ui', function(dt)
	if not style.font then return end

	local windows = gamecycle.event.ui._window
	if #windows < 1 then return end

	local popupW, popupH = ScrW() / 2, ScrH() / 2
	local popupX, popupY = ScrW() / 2 - popupW / 2, ScrH() / 2 - popupH / 2

	local toRemove = {}

	ui:stylePush(style)
		for i, window in ipairs(windows) do
			local _, wrapLimit = style.font:getWrap( window.text, popupW - 40 )
			local th = #wrapLimit * style.font:getHeight()

			if ui:windowBegin('gamecycle_event_ui' .. i, popupX, popupY, popupW, popupH, 'background') then
				if ui:popupBegin('dynamic', 'Событие', 0, 0, popupW, popupH, 'title', 'scrollbar') then
					for _, v in ipairs(wrapLimit) do
						ui:layoutRow('dynamic', style.font:getHeight(), 1)
						ui:label(v)
					end
	
					for _, btn in ipairs(window.buttons) do
						ui:layoutRow('dynamic', 28, 1)
						if ui:button(btn.text) then
							if btn.callback then btn.callback() end
							toRemove[#toRemove + 1] = i
						end
					end
					ui:popupEnd()
				end
			end
			ui:windowEnd()
		end
	ui:stylePop()

	for i = #toRemove, 1, -1 do
		local index = toRemove[i]
		table.remove(gamecycle.event.ui._window, index)
	end
end)

local windowW, windowH = 250, 64

hook.Add('UI', 'gamecycle.event.ui.planned', function(dt)
	if #gamecycle._plannedEventsUI < 1 then return end

	local toRemove = {}

	local w, h = windowW, windowH
	local x, y = ScrW() - w, gamecycle.uiPadSize[2] + 15

	local padding, spacing = style2.window.padding, style2.window.spacing
	local contentH = padding.y

	ui:stylePush(style2)
		if ui:windowBegin('Выполняющиеся действия', x, y, w, h, 'scrollbar', 'minimizable') then
			local cx, cy, cw, ch = ui:windowGetContentRegion()

			for k, v in ipairs(gamecycle._plannedEventsUI) do
				local name, endTime, delay = unpack(v)
				local progress

				if gamecycle._time >= endTime then
					toRemove[#toRemove + 1] = k
					progress = 1
				else
					progress = math.Remap( (endTime - gamecycle._time) / delay, 1, 0, 0, 1 )
				end

				local _, wrapLimit = style.font:getWrap( name, cw )
				for i, v in ipairs(wrapLimit) do
					local th = style.font:getHeight()
					ui:layoutRow('dynamic', th, 1)
					ui:label(v)

					contentH = contentH + th + spacing.y
				end

				ui:layoutRow('dynamic', 16, 1)
				ui:progress(progress * 100, 100)

				contentH = contentH + 16 + padding.y
			end
		end
		ui:windowEnd()
	ui:stylePop()

	windowH = math.Clamp(contentH, 64, ScrH() / 2.5)

	for i = #toRemove, 1, -1 do
		local index = toRemove[i]
		table.remove(gamecycle._plannedEventsUI, index)
	end
end)