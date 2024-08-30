game = game or {}

function game.endGame()
	country._countries = {}

	for id, province in pairs(country._provinces) do
		province.regionOwner = nil
		province.canvas = nil

		util.queuePrioritizedPreDrawMethodCall(province, 'CreateCanvas', 1)
	end

	country.lastRegionID = 0
	country.lastCountryID = 0

	map._selectedProvince = nil
	util.queuePrioritizedPreDrawFunctionCall(map.createCanvas, 99)

	scene.change('mainmenu')

	gamecycle.setSpeed(1)
	gamecycle._blocked = nil
end