devConsole = devConsole or {}
devConsole._commands = devConsole._commands or {}
devConsole._executeHistory = devConsole._executeHistory or {}

gui.registerFont('devConsole', {
	font = 'Montserrat-Medium',
	size = 12,
})

local inputPointer = ffi.new('char[256]')
local openPointer = ffi.new('bool[1]', true)

local consoleHistory = {}
local curSelectedExecute
local firstFocus = false

local imguiFont
hook.Add('Initialize', 'devConsole', function()
	imguiFont = gui.getFontImgui('devConsole')
end, -1)

function devConsole.open()
	openPointer[0] = true
	devConsole._open = true
	firstFocus = true
end

function devConsole.close()
	devConsole._open = nil
end

function devConsole.selectExecute(data, offset)
	if curSelectedExecute then
		curSelectedExecute = math.Clamp(curSelectedExecute + offset, 1, #devConsole._executeHistory)
	else
		if offset < 0 then
			curSelectedExecute = #devConsole._executeHistory
		else
			curSelectedExecute = 1
		end
	end

	local newStr = devConsole._executeHistory[curSelectedExecute] or ''

	data:DeleteChars(0, data.BufTextLen)
	data:InsertChars(0, newStr)

	return 0
end

function devConsole.execute(char)
	local line = ffi.string(char)
	devConsole._executeHistory[#devConsole._executeHistory + 1] = char

	local args = string.Explode('%s', line, true)
	local cmd = table.remove(args, 1)
	local cmdData = devConsole._commands[cmd]
	if not cmdData then
		consoleHistory[#consoleHistory + 1] = {os.date('[%X]') .. ' Unknown command: ' .. cmd, {1, 0, 0}}
		return
	end

	local function unknownSyntax()
		consoleHistory[#consoleHistory + 1] = {('%s Unknown syntax: %s [%s]'):format(os.date('[%X]'), cmd, table.concat(cmdData.form, ' ')), {1, 0, 0}}

		if cmdData.desc then
			consoleHistory[#consoleHistory + 1] = ('	- %s: %s'):format(cmd, cmdData.desc)
		end
	end

	local argStr = table.concat(args, ' ')
	if cmdData.form and #args ~= #cmdData.form then
		return unknownSyntax()
	end

	consoleHistory[#consoleHistory + 1] = ('%s > %s'):format(os.date('[%X]'), cmd .. ' ' .. argStr)

	local msg = cmdData.callback(args, argStr)
	if msg == false then
		return unknownSyntax()
	end

	if msg then
		if type(msg) == 'string' then
			consoleHistory[#consoleHistory + 1] = os.date('[%X]') .. ' ' .. msg
		else
			msg[1] = os.date('[%X]') .. ' ' .. msg[1]
			consoleHistory[#consoleHistory + 1] = msg
		end		
	end
end

function devConsole.registerCommand(cmd, form, desc, callback)
	devConsole._commands[cmd] = {
		form = form,
		desc = desc,
		callback = callback,
	}
end

local function inputCallback(data)
	local flag, key = data.EventFlag, data.EventKey
	if flag == imgui.ImGuiInputTextFlags_CallbackHistory then
		if key == imgui.ImGuiKey_UpArrow then
			return devConsole.selectExecute(data, -1)
		elseif key == imgui.ImGuiKey_DownArrow then
			return devConsole.selectExecute(data, 1)
		end
	end
	
	return 0
end
local inputCallback_CFunc = ffi.cast('ImGuiInputTextCallback', inputCallback)

hook.Add('DrawUI', 'devConsole', function()
	if not imguiFont then return end
	if not devConsole._open then return end

	local sw, sh = ScrW(), ScrH()

	local w, h = sw / 2, sh / 2
	local x, y = sw / 2 - w / 2, sh / 2 - h / 2

	local flags = imgui.love.WindowFlags('NoCollapse', 'NoScrollbar')
	local childWindowFlags = imgui.love.WindowFlags('HorizontalScrollbar')
	local inputFlags = imgui.love.InputTextFlags('EnterReturnsTrue', 'CallbackHistory', 'CallbackResize')
	local style = imgui.GetStyle()

	local editH = 24
	local spacing = style.ItemSpacing
	local padding = style.WindowPadding

	imgui.SetNextWindowPos({x, y}, imgui.ImGuiCond_FirstUseEver)
	imgui.SetNextWindowSize({w, h}, imgui.ImGuiCond_FirstUseEver)
	imgui.SetNextWindowFocus()

	imgui.PushFont(imguiFont)
	if imgui.Begin('Console', openPointer, flags) then
		local avail = imgui.GetContentRegionAvail()

		if imgui.BeginChild_Str('ConsoleScrollingRegion', {avail.x, avail.y - editH - spacing.y}, nil, childWindowFlags) then
			for _, msg in ipairs(consoleHistory) do
				local text, color
				if type(msg) == 'table' then
					text, color = unpack(msg)
					color[4] = 1
				else
					text = msg
				end

				if color then imgui.PushStyleColor_Vec4(imgui.ImGuiCol_Text, color) end
					imgui.TextUnformatted(text)
				if color then imgui.PopStyleColor(1) end
			end

			imgui.EndChild()
		end
		imgui.Separator()

		local reclaimFocus = false
		imgui.PushItemWidth(-1)
			if imgui.InputText('##console_input', inputPointer, 256, inputFlags, inputCallback_CFunc) then
				devConsole.execute(inputPointer)
				inputPointer = ffi.new('char[256]')
				reclaimFocus = true
			end
		imgui.PopItemWidth()

		imgui.SetItemDefaultFocus()
		if firstFocus then
			firstFocus = false
			imgui.SetKeyboardFocusHere(-1)
        elseif reclaimFocus then
        	imgui.SetKeyboardFocusHere(-1)
		end
	end

	imgui.End()
	imgui.PopFont()

	if not openPointer[0] then
		devConsole.close()
	end
end, -1)

hook.Add('KeyDown', 'devConsole', function(key)
	if devConsole._open then
		if key == 'escape' then
			devConsole.close()
		end
	elseif not devConsole._open and key == love.keyboard.getScancodeFromKey('`') then
		devConsole.open()
	end
end)