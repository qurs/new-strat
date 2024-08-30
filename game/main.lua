if os.getenv('LOCAL_LUA_DEBUGGER_VSCODE') == '1' then
	require('lldebugger').start()
end

enet = require('enet')

local libloader = require('libloader')
gameloader = require('gameloader')
nuklear = require('nuklear')

function love.load()
	love.keyboard.setKeyRepeat(true)

	libloader.load()
	gameloader.load()

	ui = nuklear.newUI()

	local provincesPath = 'game/assets/provinces.csv'
	local maxStepProvinces = 0

	local file = io.open(provincesPath, 'r')
	for line in file:lines() do
		maxStepProvinces = maxStepProvinces + 1
	end
	file:close()

	local neighborsStage
	local neighbors = {}

	local neighborsFilePath = 'game/assets/province_neighbors.json'
	local hasNeighbors = false

	do
		local neighborsFile = io.open(neighborsFilePath, 'r')
		if neighborsFile then
			local raw = neighborsFile:read('*a')
			if raw then
				local ok, tbl = pcall(json.decode, raw)
				if ok then
					hasNeighbors = true
					neighbors = tbl
				end
			end

			neighborsFile:close()
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
							hex = result.hex,
						},
						result.pixels,
						result.pixelsMap,
						Vector(unpack(result.minPos)),
						Vector(unpack(result.maxPos))
					)

					map._provinces[result.id] = meta
					map._provincesMap[result.hex] = result.id
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
			local file = io.open(neighborsFilePath, 'w')
			if file then
				file:write(json.encode(neighbors))
				file:flush()
				file:close()
			end
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

	ui:frameBegin()
		hook.Run('UI', dt)
	ui:frameEnd()
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
	if ui:wheelmoved(x, y) then return end

	hook.Run('WheelMoved', x, y)
end