gui.registerFont('uiLib', {
	font = 'Montserrat-Medium',
	size = 16,
})

uiLib = uiLib or {}
uiLib.popup = uiLib.popup or {}

uiLib.popup._popups = uiLib.popup._popups or {}

local style = {
	font = gui.getFont('uiLib'),
	window = {
		spacing = {x = 5, y = 5},
		padding = {x = 5, y = 5},
	},
}

function uiLib.popup.showMessage(title, text, callback, style)
	table.insert(uiLib.popup._popups, {
		id = tostring(os.clock()) .. '|' .. #uiLib.popup._popups,
		type = 'message',
		title = title,
		text = text,
		callback = callback,
		style = style,
	})
end

function uiLib.popup.query(title, widgets, callback, style)
	table.insert(uiLib.popup._popups, {
		id = tostring(os.clock()) .. '|' .. #uiLib.popup._popups,
		type = 'query',
		title = title,
		widgets = widgets,
		callback = callback,
		style = style,
	})
end

hook.Add('UI', 'uiLib.popup', function(dt)
	local w, h = ScrW() / 2, ScrH() / 2
	local x, y = ScrW() / 2 - w / 2, ScrH() / 2 - h / 2

	local toRemove = {}

	for k, popup in ipairs(uiLib.popup._popups) do
		local curStyle = popup.style or style
		curStyle.window = curStyle.window or style.window
		curStyle.window.spacing = curStyle.window.spacing or style.window.spacing
		curStyle.window.padding = curStyle.window.padding or style.window.padding

		ui:stylePush(curStyle)
			if ui:windowBegin('uiLib.popup' .. popup.id, popup.title, x, y, w, h, 'title', 'movable', 'scrollbar') then
				local cx, cy, cw, ch = ui:windowGetContentRegion()

				local contentH = 0

				if popup.type == 'message' then
					local font = curStyle.font

					local _, wrapLimit = font:getWrap( popup.text, cw )
					local th = #wrapLimit * font:getHeight()

					for _, v in ipairs(wrapLimit) do
						ui:layoutRow('dynamic', font:getHeight(), 1)
						ui:label(v)

						contentH = contentH + font:getHeight() + curStyle.window.spacing.y
					end

					ui:layoutRow('dynamic', 28, 1)
					if ui:button('Ок') then
						toRemove[#toRemove + 1] = k
						if popup.callback then popup.callback() end
					end

					contentH = contentH + 28
				elseif popup.type == 'query' then
					local font = curStyle.font

					for _, widget in ipairs(popup.widgets) do
						if widget.type == 'label' then
							local _, wrapLimit = font:getWrap( widget.text, cw )
							local th = #wrapLimit * font:getHeight()
		
							for _, v in ipairs(wrapLimit) do
								ui:layoutRow('dynamic', font:getHeight(), 1)
								ui:label(v)
		
								contentH = contentH + font:getHeight() + curStyle.window.spacing.y
							end
						elseif widget.type == 'edit' then
							local h = 28
							
							if widget.tooltip then
								h = math.max(h, font:getHeight())

								ui:layoutRow('dynamic', h, 2)
								ui:label(widget.tooltip)
							else
								ui:layoutRow('dynamic', h, 1)
							end

							ui:edit(widget.editType or 'simple', widget.entry)
		
							contentH = contentH + h + curStyle.window.spacing.y
						elseif widget.type == 'button' then
							ui:layoutRow('dynamic', 28, 1)
							if ui:button(widget.text) then
								if widget.callback then widget.callback() end
								if widget.close then
									toRemove[#toRemove + 1] = k
								end
							end
		
							contentH = contentH + 28 + curStyle.window.spacing.y
						elseif widget.type == 'checkbox' then
							ui:layoutRow('dynamic', font:getHeight(), 1)
							ui:checkbox(widget.tooltip, widget.entry)
		
							contentH = contentH + font:getHeight() + curStyle.window.spacing.y
						elseif widget.type == 'radio' then
							ui:layoutRow('dynamic', font:getHeight(), #widget.selection)
							for _, v in ipairs(widget.selection) do
								ui:radio(v.val, v.tooltip, widget.entry)
							end
		
							contentH = contentH + font:getHeight() + curStyle.window.spacing.y
						elseif widget.type == 'slider' then
							ui:layoutRow('dynamic', font:getHeight(), 2)
							ui:label(widget.tooltip)
							ui:slider(widget.min, widget.entry, widget.max, widget.step or 1)
		
							contentH = contentH + font:getHeight() + curStyle.window.spacing.y
						elseif widget.type == 'color' then
							local size = widget.size or 96

							ui:layoutRow('dynamic', size, 2)
							ui:label(widget.tooltip)
							ui:colorPicker(widget.entry, widget.colorType or 'RGB')
		
							contentH = contentH + size + curStyle.window.spacing.y
						elseif widget.type == 'combo' then
							ui:layoutRow('dynamic', 28, 1)
							ui:combobox(widget.entry, widget.items)
		
							contentH = contentH + 28 + curStyle.window.spacing.y
						end
					end

					ui:layoutRow('dynamic', 28, 1)
					if ui:button('Отправить') then
						toRemove[#toRemove + 1] = k
						if popup.callback then popup.callback(popup.widgets) end
					end

					contentH = contentH + 28
				end

				if not popup._resized then
					popup._resized = true

					ui:windowSetSize('uiLib.popup' .. popup.id, w, math.min(46 + curStyle.window.padding.y + contentH + curStyle.window.padding.y, h))
				end
			end
			ui:windowEnd()
		ui:stylePop()
	end

	for i = #toRemove, 1, -1 do
		table.remove(uiLib.popup._popups, toRemove[i])
	end
end)

--[[ Пример вызова функции uiLib.popup.query со всеми возможными виджетами
	uiLib.popup.query('Запрос текста', {
		{
			type = 'label',
			text = 'Напишите данные банковской карты, фактический адрес проживания, контактные данные, серия и номера паспорта:',
		},
		{
			type = 'edit',
			editType = 'simple',
			entry = {value = ''},
		},
		{
			type = 'checkbox',
			tooltip = 'Чекбокс',
			entry = {value = false},
		},
		{
			type = 'radio',
			selection = {
				{
					tooltip = 'Радио',
					val = 'radio1',
				},
				{
					tooltip = 'Радио2',
					val = 'radio2',
				},
			},
			entry = {value = ''},
		},
		{
			type = 'slider',
			tooltip = 'Слайдер',
			min = 0,
			max = 3,
			step = 0.5,
			entry = {value = 0},
		},
		{
			type = 'color',
			tooltip = 'Цвет',
			colorType = 'RGB',
			size = 64,
			entry = {value = '#ff0000'},
		},
		{
			type = 'combo',
			tooltip = 'Комбобокс',
			items = {
				'Предмет 1',
				'Предмет 2',
				'Предмет 3'
			},
			entry = {value = 1},
		},
	},
	function(widgets)
		print('текст: ', widgets[2].entry.value)
		print('чекбокс:', widgets[3].entry.value)
		print('радио:', widgets[4].entry.value)
		print('слайдер:', widgets[5].entry.value)
		print('цвет:', widgets[6].entry.value)
		print('комбобокс:', widgets[7].entry.value, ' = ', widgets[7].items[ widgets[7].entry.value ])
	end)
]]