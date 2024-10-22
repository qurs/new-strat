devConsole = devConsole or {}
devConsole._commands = devConsole._commands or {}
devConsole._executeHistory = devConsole._executeHistory or {}

gui.registerFont('devConsole', {
	font = 'Montserrat-Medium',
	size = 11,
})

local style = {
	font = gui.getFont('devConsole'),
	window = {
		spacing = {x = 5, y = 5},
		padding = {x = 5, y = 5},
	},
}

local consoleField = {
	value = ''
}

local consoleHistory = {}
local curSelectedExecute

function devConsole.open()
	devConsole._open = true
end

function devConsole.close()
	devConsole._open = nil
end

function devConsole.selectExecute(offset)
	if curSelectedExecute then
		curSelectedExecute = math.Clamp(curSelectedExecute + offset, 1, #devConsole._executeHistory)
	else
		if offset < 0 then
			curSelectedExecute = #devConsole._executeHistory
		else
			curSelectedExecute = 1
		end
	end

	consoleField.value = devConsole._executeHistory[curSelectedExecute] or ''
end

function devConsole.execute(line)
	devConsole._executeHistory[#devConsole._executeHistory + 1] = line

	local args = string.Explode('%s', line, true)
	local cmd = table.remove(args, 1)
	local cmdData = devConsole._commands[cmd]
	if not cmdData then
		consoleHistory[#consoleHistory + 1] = {os.date('[%X]') .. ' Unknown command: ' .. cmd, '#FF0000'}
		return
	end

	local argStr = table.concat(args, ' ')
	if cmdData.form and #args ~= #cmdData.form then
		consoleHistory[#consoleHistory + 1] = {('%s Unknown syntax: %s [%s]'):format(os.date('[%X]'), cmd, table.concat(cmdData.form, ' ')), '#FF0000'}

		if cmdData.desc then
			consoleHistory[#consoleHistory + 1] = ('	- %s: %s'):format(cmd, cmdData.desc)
		end

		return
	end

	consoleHistory[#consoleHistory + 1] = ('%s > %s'):format(os.date('[%X]'), cmd .. ' ' .. argStr)

	local msg = cmdData.callback(args, argStr)
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

local function drawLabel(curStyle, text, color)
	local font = curStyle.font
	if not font then return end

	local cx, cy, cw, ch = ui:windowGetContentRegion()

	local _, wrapLimit = font:getWrap( text, cw )

	for _, v in ipairs(wrapLimit) do
		ui:layoutRow('dynamic', font:getHeight(), 1)

		if color then
			ui:label(v, 'left', color)
		else
			ui:label(v, 'left')
		end
		
	end
end

hook.Add('UI', 'devConsole', function()
	if not devConsole._open then return end

	local sw, sh = ScrW(), ScrH()

	local w, h = sw / 2, sh / 2
	local x, y = sw / 2 - w / 2, sh / 2 - h / 2

	local editH = 24
	local spacing = style.window.spacing
	local padding = style.window.padding

	ui:stylePush(style)
		if ui:windowBegin('devconsole', 'Console', x, y, w, h, 'title', 'movable', 'scalable', 'closable', 'scrollbar') then
			local cx, cy, cw, ch = ui:windowGetContentRegion()

			ui:layoutSpaceBegin('static', ch - editH - spacing.y - padding.y * 2, 1)
				local _, _, lsw, lsh = ui:layoutSpaceBounds()

				ui:layoutSpacePush(0, 0, lsw, lsh)
				if ui:groupBegin('console_labels', 'scrollbar') then
					for _, msg in ipairs(consoleHistory) do
						local text, color
						if type(msg) == 'table' then
							text, color = unpack(msg)
						else
							text = msg
						end

						drawLabel(style, text, color)
					end

					ui:groupEnd()
				end
			ui:layoutSpaceEnd()

			ui:layoutRow('dynamic', editH, 1)

			local state, changed = ui:edit('simple', consoleField)
			consoleField.state = state
			if changed then
				curSelectedExecute = nil
			end
		elseif devConsole._open then
			devConsole.close()
		end
		ui:windowEnd()
	ui:stylePop()
end, -1)

hook.Add('KeyDown', 'devConsole', function(key)
	if devConsole._open then
		if key == 'escape' then
			devConsole.close()
		elseif consoleField.state == 'active' then
			if key == 'return' then
				devConsole.execute(consoleField.value)
				consoleField.value = ''
			elseif key == 'up' then
				devConsole.selectExecute(-1)
			elseif key == 'down' then
				devConsole.selectExecute(1)
			end
		end
	elseif not devConsole._open and key == love.keyboard.getScancodeFromKey('`') then
		devConsole.open()
	end
end)