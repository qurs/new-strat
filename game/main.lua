if os.getenv('LOCAL_LUA_DEBUGGER_VSCODE') == '1' then
	require('lldebugger').start()
end

Bmp = require('bmp')
enet = require('enet')

local libloader = require('libloader')
gameloader = require('gameloader')
nuklear = require('nuklear')

function love.load()
	love.keyboard.setKeyRepeat(true)

	libloader.load()
	gameloader.load()

	ui = nuklear.newUI()

	assetloader.load({
		stages = {
			{
				name = 'Map',
				files = {
					{path = 'assets/map.dxt1', name = 'map', type = 'img', compressed = true},
					{path = 'assets/provinces.bmp', name = 'map_provinces', type = 'img'},
				},
			},
			{
				name = 'Textures',
				files = {
					{path = 'assets/pause.png', name = 'pause_img', type = 'img'},
				},
			},
		},
	}, function()
		hook.Run('AssetsLoaded')
	end)

	hook.Run('Initialize')

	scene.change('mainmenu')
end

function love.update(dt)
	hook.Run('Think', dt)
end

function love.draw()
	local suppress = hook.Run('PreDraw')
	if suppress == true then return end

	camera.push()
		hook.Run('Draw')
		hook.Run('PostDraw')
	camera.pop()

	suppress = hook.Run('PreDrawUI')
	if suppress == true then return end

	hook.Run('DrawUI')
	ui:draw()

	hook.Run('PostDrawUI')
end

function love.resize(w, h)
	hook.Run('WindowResized', w, h)
end

function love.mousepressed(x, y, button, istouch, presses)
	if ui:mousepressed(x, y, button, istouch, presses) then return end

	hook.Run('MouseDown', x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
	if ui:mousereleased(x, y, button, istouch, presses) then return end

	hook.Run('MouseUp', x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
	hook.Run('MouseMoved', x, y, dx, dy, istouch)
	ui:mousemoved(x, y, dx, dy, istouch)
end

function love.keypressed(key, scancode, isrepeat)
	hook.Run('KeyDown', key, scancode, isrepeat)
	ui:keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
	hook.Run('KeyUp', key, scancode, isrepeat)
	ui:keyreleased(key, scancode)
end

function love.textinput(text)
	hook.Run('TextInput', text)
	ui:textinput(text)
end

function love.wheelmoved(x, y)
	hook.Run('WheelMoved', x, y)
	ui:wheelmoved(x, y)
end