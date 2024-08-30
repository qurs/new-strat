game = game or {}

function game.endGame()
	country._countries = {}

	for id, province in pairs(country._provinces) do
		province.regionOwner = nil
		province.canvas = nil

		util.queuePreDrawMethodCall(province, 'CreateCanvas')
	end

	country.lastRegionID = 0
	country.lastCountryID = 0

	map._selectedProvince = nil
	util.queuePreDrawFunctionCall(map.createCanvas)

	scene.change('mainmenu')

	gamecycle.setSpeed(1)
	gamecycle._blocked = nil
end