devConsole = devConsole or {}
devConsole._commands = devConsole._commands or {}

gui.registerFont('devConsole', {
	font = 'Montserrat-Medium',
	size = 11,
})

function devConsole.open()
	devConsole._open = true
end

function devConsole.close()
	devConsole._open = nil
end

function devConsole.registerCommand(cmd, form, desc, callback)
	devConsole._commands[cmd] = {
		form = form,
		desc = desc,
		callback = callback,
	}
end

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

local function drawLabel(curStyle, text)
	local font = curStyle.font
	if not font then return end

	local cx, cy, cw, ch = ui:windowGetContentRegion()

	local _, wrapLimit = font:getWrap( text, cw )

	for _, v in ipairs(wrapLimit) do
		ui:layoutRow('dynamic', font:getHeight(), 1)
		ui:label(v)
	end
end

hook.Add('UI', 'devConsole', function()
	local sw, sh = ScrW(), ScrH()

	local w, h = sw / 2, sh / 2
	local x, y = sw / 2 - w / 2, sh / 2 - h / 2

	local editH = 16
	local spacing = style.window.spacing
	local padding = style.window.padding

	ui:stylePush(style)
		if ui:windowBegin('devconsole', 'Console', x, y, w, h, 'title', 'movable', 'scrollbar') then
			local cx, cy, cw, ch = ui:windowGetContentRegion()

			ui:layoutSpaceBegin('static', ch - editH - spacing.y - padding.y * 2, 1)
				local _, _, lsw, lsh = ui:layoutSpaceBounds()

				ui:layoutSpacePush(0, 0, lsw, lsh)
				if ui:groupBegin('console_labels', 'scrollbar') then
					drawLabel(style, 'asdiuashdiasudhasiudhasiudahsiaudhasiduhaiduhasidusahdiusahdauisdhsauidshaiduashdsaiudhasdiusahdaiudhaiudhsauidhasdiuashd')
					drawLabel(style, 'asdiuashdiasudhasiudhasiudahsiaudhasiduhaiduhasidusahdiusahdauisdhsauidshaiduashdsaiudhasdiusahdaiudhaiudhsauidhasdiuashd')
					drawLabel(style, 'asdiuashdiasudhasiudhasiudahsiaudhasiduhaiduhasidusahdiusahdauisdhsauidshaiduashdsaiudhasdiusahdaiudhaiudhsauidhasdiuashd')
					drawLabel(style, 'asdiuashdiasudhasiudhasiudahsiaudhasiduhaiduhasidusahdiusahdauisdhsauidshaiduashdsaiudhasdiusahdaiudhaiudhsauidhasdiuashd')

					ui:groupEnd()
				end
			ui:layoutSpaceEnd()

			ui:layoutRow('dynamic', editH, 1)
			ui:edit('simple', consoleField)
		end
		ui:windowEnd()
	ui:stylePop()
end, -1)

hook.Add('KeyDown', 'devConsole', function(key)
	if devConsole._open and key == 'escape' then
		devConsole.close()
	elseif not devConsole._open and key == '`' then
		devConsole.open()
	end
end)