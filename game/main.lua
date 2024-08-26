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

				code = [[
					local args = {...}
					local provinces = args[1]

					for i, province in ipairs(provinces) do
						local neighbors = {}
						local myPixels = province.pixels

						for i2, otherProvince in ipairs(provinces) do
							if i == i2 then goto continue end

							for _, pixel in ipairs(myPixels) do
								local x, y = unpack(pixel)
								if otherProvince.pixelsMap[(x - 1) .. '|' .. y] or otherProvince.pixelsMap[(x + 1) .. '|' .. y] or otherProvince.pixelsMap[x .. '|' .. (y - 1)] or otherProvince.pixelsMap[x .. '|' .. (y + 1)] then
									neighbors[#neighbors + 1] = i2
									break
								end

								::continue::
							end

							::continue::
						end

						love.thread.getChannel('assetloader'):push({
							id = i,
							result = neighbors,
						})
					end
				]],
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

				code = [[
					require('love.image')

					require('lib/string')
					local nuklear = require('nuklear')

					local args = {...}
					local path = args[1]
					local imgData = args[2]
					local pixelCount = args[3]
					local w = args[4]

					local file = io.open(path, 'r')

					local ffi = require('ffi')

					for line in file:lines() do
						local data = string.Split(line, ';')
						local id = tonumber(data[1])
						local r, g, b = tonumber(data[2]), tonumber(data[3]), tonumber(data[4])
						local hex = nuklear.colorRGBA(r, g, b)

						local pixels = {}
						local pixelsMap = {}
						local minX, minY = math.huge, math.huge
						local maxX, maxY = -math.huge, -math.huge

						do
							local pointer = ffi.cast('uint8_t*', imgData:getFFIPointer())

							for i = 0, (4 * pixelCount) - 1, 4 do
								local pr, pg, pb = pointer[i], pointer[i + 1], pointer[i + 2]

								if pr == r and pg == g and pb == b then
									local pos = i / 4
									local y = math.floor(math.max(pos - 1, 0) / w)
									local x = pos - (w * y)

									minX, minY = math.min(minX, x), math.min(minY, y)
									maxX, maxY = math.max(maxX, x), math.max(maxY, y)

									local index = #pixels + 1
									pixels[index] = {x, y}
									pixelsMap[x .. '|' .. y] = index
								end
							end
						end

						love.thread.getChannel('assetloader'):push({
							id = id,
							hex = hex,
							rgb255 = {r, g, b},
							pixels = pixels,
							pixelsMap = pixelsMap,
							minPos = {minX, minY},
							maxPos = {maxX, maxY},
						})
					end

					file:close()
				]],
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