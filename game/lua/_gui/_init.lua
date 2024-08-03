gui = gui or {}
gui._fonts = gui._fonts or {}

function gui.registerFont(name, data)
	local font = love.graphics.newFont('assets/fonts/' .. data.font .. '.ttf', data.size, data.hinting, data.dpiScale)

	gui._fonts[name] = {
		data = data,
		obj = font,
	}

	return font
end

function gui.removeFont(name)
	local fontData = gui._fonts[name]
	if not fontData then return end

	fontData.obj:release()
	gui._fonts[name] = nil
end

function gui.getFont(name)
	return gui._fonts[name] and gui._fonts[name].obj
end