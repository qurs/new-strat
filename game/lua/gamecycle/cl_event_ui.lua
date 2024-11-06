gamecycle = gamecycle or {}
gamecycle.event = gamecycle.event or {}
gamecycle.event.ui = gamecycle.event.ui or {}

gamecycle.event.ui._window = gamecycle.event.ui._window or {}

gui.registerFont('gamecycle.event.ui', {
	font = 'Montserrat-Medium',
	size = 16,
})

gui.registerFont('gamecycle.event.ui.planned', {
	font = 'Montserrat-Medium',
	size = 13,
})

local fontObj, imguiFont, plannedFontObj, plannedImguiFont

function gamecycle.event.ui.showWindow(text, buttons)
	gamecycle.event.ui._window[#gamecycle.event.ui._window + 1] = {
		text = text,
		buttons = buttons,
	}
end

hook.Add('AssetsLoaded', 'gamecycle.event.ui', function()
	fontObj = gui.getFont('gamecycle.event.ui')
	imguiFont = gui.getFontImgui('gamecycle.event.ui')

	plannedFontObj = gui.getFont('gamecycle.event.ui.planned')
	plannedImguiFont = gui.getFontImgui('gamecycle.event.ui.planned')
end)

hook.Add('DrawUI', 'gamecycle.event.ui', function(dt)
	if not fontObj then return end

	local windows = gamecycle.event.ui._window
	if #windows < 1 then return end

	local flags = imgui.love.WindowFlags('NoResize', 'NoCollapse')

	local popupW, popupH = 450, math.min(ScrH() / 2, 400)
	local popupX, popupY = ScrW() / 2 - popupW / 2, ScrH() / 2 - popupH / 2

	local toRemove = {}

	for i, window in ipairs(windows) do
		imgui.SetNextWindowPos({popupX, popupY}, imgui.ImGuiCond_Once)
		imgui.SetNextWindowSize({popupW, popupH}, imgui.ImGuiCond_Once)

		imgui.PushFont(imguiFont)
		if imgui.Begin(('Событие ##%02i'):format(i), nil, flags) then
			local _, wrapLimit = fontObj:getWrap( window.text, imgui.GetContentRegionAvail().x )
			for _, v in ipairs(wrapLimit) do
				imgui.Text(v)
			end

			for _, btn in ipairs(window.buttons) do
				if imgui.Button(btn.text) then
					uiLib.sound.click(1)
					if btn.callback then btn.callback() end
					toRemove[#toRemove + 1] = i
				end
			end
		end
		imgui.End()
		imgui.PopFont()
	end

	for i = #toRemove, 1, -1 do
		local index = toRemove[i]
		table.remove(gamecycle.event.ui._window, index)
	end
end)

local windowW, windowH = 250, 64

hook.Add('DrawUI', 'gamecycle.event.ui.planned', function()
	if not plannedFontObj then return end
	if #gamecycle._plannedEventsUI < 1 then return end

	local flags = imgui.love.WindowFlags('NoMove', 'NoResize')

	local toRemove = {}

	local w, h = windowW, windowH
	local x, y = ScrW() - w, gamecycle.uiPadSize[2] + 15

	local style = imgui.GetStyle()

	local padding, spacing = style.WindowPadding, style.ItemSpacing
	local contentH = padding.y

	imgui.SetNextWindowPos({x, y})
	imgui.SetNextWindowSize({w, h})

	imgui.PushFont(plannedImguiFont)
	if imgui.Begin('Выполняющиеся действия', nil, flags) then
		for k, v in ipairs(gamecycle._plannedEventsUI) do
			local name, endTime, delay = unpack(v)
			local progress

			if gamecycle._time >= endTime then
				toRemove[#toRemove + 1] = k
				progress = 1
			else
				progress = math.Remap( (endTime - gamecycle._time) / delay, 1, 0, 0, 1 )
			end

			local _, wrapLimit = plannedFontObj:getWrap( name, imgui.GetContentRegionAvail().x )
			for _, v in ipairs(wrapLimit) do
				imgui.Text(v)
				contentH = contentH + plannedFontObj:getHeight(v) + spacing.y
			end

			imgui.ProgressBar(progress, {-1, 16})

			contentH = contentH + 16 + padding.y
		end
	end
	imgui.End()
	imgui.PopFont()

	windowH = math.Clamp(contentH, 64, ScrH() / 2.5)

	for i = #toRemove, 1, -1 do
		local index = toRemove[i]
		table.remove(gamecycle._plannedEventsUI, index)
	end
end)