if os.getenv('LOCAL_LUA_DEBUGGER_VSCODE') == '1' then
	require('lldebugger').start()
end

local extension = jit.os == 'Windows' and 'dll' or jit.os == 'Linux' and 'so' or jit.os == 'OSX' and 'dylib'
package.cpath = string.format('%s;%s/?.%s', package.cpath, love.filesystem.getSourceBaseDirectory(), extension)
package.cpath = string.format('%s;%s/?.%s', package.cpath, love.filesystem.getSourceBaseDirectory() .. '/game', extension)

local libloader = require('libloader')
gameloader = require('gameloader')
enet = require('enet')
imgui = require('cimgui')
ffi = require('ffi')

VERSION = require('version')

function love.load()
	love.keyboard.setKeyRepeat(true)

	libloader.load()
	gameloader.load()

	imgui.love.Init()

	local provincesPath = 'assets/map/provinces.csv'
	local maxStepProvinces = 0

	for line in love.filesystem.lines(provincesPath) do
		maxStepProvinces = maxStepProvinces + 1
	end

	local neighborsStage
	local neighbors = {}

	local neighborsFilePath = 'data/province_neighbors.json'
	local hasNeighbors = false

	do
		local neighborsRaw = love.filesystem.read(neighborsFilePath)
		if neighborsRaw then
			local ok, tbl = pcall(json.decode, neighborsRaw)
			if ok then
				hasNeighbors = true
				neighbors = tbl
			end
		end

		if not hasNeighbors then
			neighborsStage = {
				name = 'Provinces Neighbors',
				type = 'custom',
				maxStep = maxStepProvinces,

				handler = function(result)
					neighbors[result.id] = result.result
				end,

				args = function()
					local provinces = {}
					for i, province in ipairs(map._provinces) do
						provinces[i] = {
							pixels = province:GetPixelsList(),
							pixelsMap = province:GetPixelsMap(),
						}
					end

					return provinces
				end,

				threadPath = 'threads/load_neighbors.lua',
			}
		end
	end

	assetloader.load({
		stages = {
			{
				name = 'Map',
				files = {
					{path = 'assets/map/map.dxt1', name = 'map', type = 'img', compressed = true},
					{path = 'assets/map/provinces.bmp', name = 'map_provinces', type = 'img'},
				},
			},
			{
				name = 'Textures',
				files = {
					{path = 'assets/ui/pause.png', name = 'pause_img', type = 'img'},
					{path = 'assets/ui/wild_colonization.png', name = 'wild_colonization_icon', type = 'img'},
					{path = 'assets/ui/knight_sword.png', name = 'knight_sword_icon', type = 'img'},
					{path = 'assets/ui/knight_sword2.png', name = 'knight_sword2_icon', type = 'img'},
					{path = 'assets/ui/unit_type.png', name = 'unit_type_icon', type = 'img'},
					{path = 'assets/ui/unit_capability.png', name = 'unit_capability_icon', type = 'img'},
					{path = 'assets/ui/unit_attack.png', name = 'unit_attack_icon', type = 'img'},
					{path = 'assets/ui/unit_defence.png', name = 'unit_defence_icon', type = 'img'},
					{path = 'assets/ui/unit_armor.png', name = 'unit_armor_icon', type = 'img'},
					{path = 'assets/ui/unit_armorpierce.png', name = 'unit_armorpierce_icon', type = 'img'},
				},
			},
			{
				name = 'Sounds',
				files = {
					{path = 'assets/sounds/click1.mp3', name = 'sound_click1', type = 'sound'},
					{path = 'assets/sounds/click2.mp3', name = 'sound_click2', type = 'sound'},
					{path = 'assets/sounds/click3.mp3', name = 'sound_click3', type = 'sound'},
					{path = 'assets/sounds/walking.mp3', name = 'sound_walking', type = 'sound'},
				},
			},
			{
				name = 'Provinces',
				type = 'custom',
				maxStep = maxStepProvinces,

				handler = function(result)
					map = map or {}
					map._provinces = map._provinces or {}
					map._provincesMap = map._provincesMap or {}

					local meta = country.newProvince(result.id, {
							rgb255 = result.rgb255,
							rgb = { love.math.colorFromBytes(unpack(result.rgb255)) },
							colorID = result.colorID,
						},
						result.pixels,
						result.pixelsMap,
						Vector(unpack(result.minPos)),
						Vector(unpack(result.maxPos))
					)

					map._provinces[result.id] = meta
					map._provincesMap[result.colorID] = result.id
				end,

				args = function()
					local imgData = assetloader.get('map_provinces').data
					local w, h = imgData:getWidth(), imgData:getHeight()
					local pixelCount = w * h

					return provincesPath, imgData, pixelCount, w
				end,

				threadPath = 'threads/load_provinces.lua',
			},
			neighborsStage,
		},
	}, function()
		if not hasNeighbors then
			love.filesystem.write(neighborsFilePath, json.encode(neighbors))
		end

		do
			for id, v in ipairs(neighbors) do
				local tbl = {}
				for _, neighborID in ipairs(v) do
					tbl[#tbl + 1] = map._provinces[neighborID]
				end

				map._provinces[id].neighbors = tbl
			end
		end

		hook.Run('AssetsLoaded')
	end)

	hook.Run('Initialize')
	scene.change('mainmenu')
end

function love.update(dt)
	hook.Run('Think', dt)

	imgui.love.Update(dt)
	imgui.NewFrame()
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

	love.graphics.setColor(1, 1, 1, 1)
	imgui.Render()
	imgui.love.RenderDrawLists()

	hook.Run('PostDrawUI')
end

function love.resize(w, h)
	hook.Run('WindowResized', w, h)
end

function love.mousepressed(x, y, button, istouch, presses)
	if not radialMenu._opened then
		imgui.love.MousePressed(button)
		if imgui.love.GetWantCaptureMouse() then return end
	end

	hook.Run('MouseDown', x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
	if not radialMenu._opened then
		imgui.love.MouseReleased(button)
		if imgui.love.GetWantCaptureMouse() then return end
	end

	hook.Run('MouseUp', x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
	if not radialMenu._opened then
		imgui.love.MouseMoved(x, y)
		if imgui.love.GetWantCaptureMouse() then return end
	end

	hook.Run('MouseMoved', x, y, dx, dy, istouch)
end

function love.keypressed(key, scancode, isrepeat)
	imgui.love.KeyPressed(key)
	if imgui.love.GetWantCaptureKeyboard() then return end

	hook.Run('KeyDown', key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
	imgui.love.KeyReleased(key)
	if imgui.love.GetWantCaptureKeyboard() then return end

	hook.Run('KeyUp', key, scancode, isrepeat)
end

function love.textinput(text)
	imgui.love.TextInput(text)
	if imgui.love.GetWantCaptureKeyboard() then return end

	hook.Run('TextInput', text)
end

function love.wheelmoved(x, y)
	imgui.love.WheelMoved(x, y)
	if imgui.love.GetWantCaptureMouse() then return end

	hook.Run('WheelMoved', x, y)
end

function love.quit()
	return imgui.love.Shutdown()
end