gui = gui or {}
gui._fonts = gui._fonts or {}
gui._queue = gui._queue or {}

local initialized = false

function gui.registerFontImgui(name, data)
	if not initialized then
		gui._queue[#gui._queue + 1] = {name, data}
		return
	end

	local path = 'assets/fonts/' .. data.font .. '.ttf'

	local imio = imgui.GetIO()
	local imioFonts = imio.Fonts

	local config = imgui.ImFontConfig()
	config.FontDataOwnedByAtlas = false

	gui._fonts[name] = gui._fonts[name] or {}
	local fontData = gui._fonts[name]

	local content, size = love.filesystem.read(path)
	fontData.imguiObj = imioFonts:AddFontFromMemoryTTF(ffi.cast('void*', content), size, data.size, config, imioFonts.GetGlyphRangesCyrillic())
	imgui.love.BuildFontAtlas()
end

function gui.registerFont(name, data)
	local path = 'assets/fonts/' .. data.font .. '.ttf'
	local font = love.graphics.newFont(path, data.size, data.hinting, data.dpiScale)

	local fontData = {
		data = data,
		obj = font,
	}

	gui._fonts[name] = fontData
	gui.registerFontImgui(name, data)

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

function gui.getFontImgui(name)
	return gui._fonts[name] and gui._fonts[name].imguiObj
end

hook.Add('Initialize', 'gui.fontQueue', function()
	initialized = true

	for _, v in ipairs(gui._queue) do
		gui.registerFontImgui(unpack(v))
	end
	gui._queue = nil
end)