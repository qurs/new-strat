game = game or {}

function game.isSpectating()
	return game._spectating
end

function game.spectatorMode()
	game._spectating = true
end

function game.endGame()
	pauseMenu.close()
	scene.change('mainmenu')

	game._spectating = nil

	camera._scale = 1
	camera._pos = Vector()

	gamecycle.setSpeed(1)
	gamecycle._blocked = nil

	for id, province in pairs(country._provinces) do
		province.canvas:release()

		local clr = province:GetColorData()
		local clrID = clr.colorID
		local neighbors = province.neighbors

		local meta = country.newProvince(id, {
				rgb255 = clr.rgb255,
				rgb = { love.math.colorFromBytes(unpack(clr.rgb255)) },
				colorID = clrID,
			},
			province.pixels,
			province.pixelsMap,
			province.minPos,
			province.maxPos
		)

		local newNeighbors = {}
		for _, neighbor in ipairs(neighbors) do
			newNeighbors[#newNeighbors + 1] = neighbor:GetID()
		end
		meta.neighbors = newNeighbors

		map._provinces[id] = meta
		map._provincesMap[clrID] = id

		util.queuePrioritizedPreDrawMethodCall(meta, 'CreateCanvas', 1)
	end

	for id, province in pairs(country._provinces) do
		for k, v in ipairs(province.neighbors) do
			province.neighbors[k] = country.getProvince(v)
		end
	end

	for _, reg in pairs(country._regions) do reg.canvas:release() end
	country._regions = {}
	country._countries = {}

	map._selectedProvince = nil
	map._selectedCountry = nil
	units._selectedUnits = nil

	country.lastRegionID = 0
	country.lastCountryID = 0

	util.queuePrioritizedPreDrawFunctionCall(map.createCanvas, 99)
	collectgarbage()
end