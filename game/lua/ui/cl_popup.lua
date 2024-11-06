gui.registerFont('uiLib', {
	font = 'Montserrat-Medium',
	size = 16,
})

uiLib = uiLib or {}
uiLib.popup = uiLib.popup or {}

uiLib.popup._popups = uiLib.popup._popups or {}

local fontObj, imguiFont
hook.Add('Initialize', 'uiLib.popup.init', function()
	fontObj, imguiFont = gui.getFont('uiLib'), gui.getFontImgui('uiLib')
end)

function uiLib.popup.showMessage(title, text, callback)
	table.insert(uiLib.popup._popups, {
		id = tostring(os.clock()) .. '|' .. #uiLib.popup._popups,
		type = 'message',
		title = title,
		text = text,
		callback = callback,
	})
end

function uiLib.popup.query(title, settings, widgets, callback)
	table.insert(uiLib.popup._popups, {
		id = tostring(os.clock()) .. '|' .. #uiLib.popup._popups,
		type = 'query',
		title = title,
		settings = settings,
		widgets = widgets,
		callback = callback,
	})
end

hook.Add('DrawUI', 'uiLib.popup', function(dt)
	if not imguiFont then return end

	local flags = imgui.love.WindowFlags('NoResize', 'NoCollapse')

	local w, h = 450, math.min(ScrH() / 2, 400)
	local x, y = ScrW() / 2 - w / 2, ScrH() / 2 - h / 2

	local style = imgui.GetStyle()
	local padding = style.WindowPadding
	local spacing = style.ItemSpacing

	local toRemove = {}

	for k, popup in ipairs(uiLib.popup._popups) do
		local id = ('%s ##%s'):format(popup.title, popup.id)
		local settings = popup.settings or {}
		local popupFlags = settings.flags or flags

		if settings.closable and not popup._closePointer then
			popup._closePointer = ffi.new('bool[1]', true)
		end

		local pointer = popup._closePointer

		imgui.SetNextWindowPos({x, y}, imgui.ImGuiCond_FirstUseEver)
		imgui.SetNextWindowSize({w, -1}, imgui.ImGuiCond_FirstUseEver)

		imgui.PushFont(imguiFont)
		if imgui.Begin(id, pointer, popupFlags) then
			local cw = imgui.GetContentRegionAvail().x

			if popup.type == 'message' then
				local _, wrapLimit = fontObj:getWrap(popup.text, cw)
				for _, v in ipairs(wrapLimit) do
					imgui.Text(v)
				end

				if imgui.Button('Ок', {-1, 28}) then
					uiLib.sound.click(1)
					toRemove[#toRemove + 1] = k
					if popup.callback then popup.callback() end
				end
			elseif popup.type == 'query' then
				for widgetIndex, widget in ipairs(popup.widgets) do
					if widget.type == 'label' then
						local _, wrapLimit = fontObj:getWrap(widget.text, cw)
						for _, v in ipairs(wrapLimit) do
							imgui.Text(v)
						end
					elseif widget.type == 'edit' then
						if widget.editType == 'multiline' then
							imgui.InputTextMultiline(widget.tooltip or '', widget.entry, widget.maxLength)
						else
							imgui.InputText(widget.tooltip or '', widget.entry, widget.maxLength)
						end
					elseif widget.type == 'button' then
						if imgui.Button(widget.text, {-1, 28}) then
							uiLib.sound.click(1)
							if widget.callback then widget.callback() end
							if widget.close then
								toRemove[#toRemove + 1] = k
							end
						end
					elseif widget.type == 'checkbox' then
						imgui.Checkbox(widget.tooltip, widget.entry)
					elseif widget.type == 'radio' then
						for k, v in ipairs(widget.selection) do
							imgui.RadioButton_IntPtr(v.tooltip, widget.entry, v.val)
							if next(widget.selection, k) then imgui.SameLine() end
						end
					elseif widget.type == 'slider' then
						if widget.float then
							imgui.SliderFloat(widget.tooltip, widget.entry, widget.min, widget.max, widget.format)
						else
							imgui.SliderInt(widget.tooltip, widget.entry, widget.min, widget.max)
						end
					elseif widget.type == 'color' then
						local size = widget.size or 96
						local flags = {'DisplayRGB', 'NoDragDrop', 'NoOptions', 'NoInputs'}
						if not widget.alpha then
							flags[#flags + 1] = 'NoAlpha'
						end

						flags = imgui.love.ColorEditFlags(unpack(flags))
						imgui.ColorEdit4(widget.tooltip, widget.entry, flags)
					elseif widget.type == 'combo' then
						widget.selected = widget.selected or 1
						if imgui.BeginCombo(widget.tooltip or ('##%02i'):format(widgetIndex), widget.items[widget.selected]) then
							for i, v in ipairs(widget.items) do
								local selected = i == widget.selected
								if imgui.Selectable_Bool(v, selected) then
									widget.selected = i
								end

								if selected then
									imgui.SetItemDefaultFocus()
								end
							end
							imgui.EndCombo()
						end
					end
				end

				if imgui.Button('Отправить') then
					uiLib.sound.click(1)
					toRemove[#toRemove + 1] = k
					if popup.callback then popup.callback(popup.widgets) end
				end
			end

			if popup.autosized then
				local size = imgui.GetWindowSize()
				imgui.SetWindowSize_Str(id, {w, math.min(size.y, h)})
			else
				popup.autosized = true
			end
		end
		imgui.End()
		imgui.PopFont()

		if pointer and not pointer[0] then
			toRemove[#toRemove + 1] = k
		end
	end

	for i = #toRemove, 1, -1 do
		table.remove(uiLib.popup._popups, toRemove[i])
	end
end)

--[[ Пример вызова функции uiLib.popup.query со всеми возможными виджетами
	uiLib.popup.query('Запрос текста', nil, {
		{
			type = 'label',
			text = 'Напишите данные банковской карты, фактический адрес проживания, контактные данные, серия и номера паспорта:',
		},
		{
			type = 'edit',
			--editType = 'multiline',
			maxLength = 32,
			entry = ffi.new('char[32]'),
		},
		{
			type = 'checkbox',
			tooltip = 'Чекбокс',
			entry = ffi.new('bool[1]'),
		},
		{
			type = 'radio',
			selection = {
				{
					tooltip = 'Радио',
					val = 1,
				},
				{
					tooltip = 'Радио2',
					val = 2,
				},
			},
			entry = ffi.new('int[1]'),
		},
		{
			type = 'slider',
			tooltip = 'Слайдер',
			min = 0,
			max = 3,
			float = true,
			entry = ffi.new('float[1]'),
		},
		{
			type = 'color',
			tooltip = 'Цвет',
			--alpha = true,
			size = 64,
			entry = ffi.new('float[4]'),
		},
		{
			type = 'combo',
			tooltip = 'Комбобокс',
			items = {
				'Предмет 1',
				'Предмет 2',
				'Предмет 3'
			},
			selected = 1,
		},
	},
	function(widgets)
		print('текст: ', ffi.string(widgets[2].entry))
		print('чекбокс:', widgets[3].entry[0])
		print('радио:', widgets[4].entry[0])
		print('слайдер:', widgets[5].entry[0])
		print('цвет:', widgets[6].entry)
		print('комбобокс:', widgets[7].selected, ' = ', widgets[7].items[ widgets[7].selected ])
	end)
]]