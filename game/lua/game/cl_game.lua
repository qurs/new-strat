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

	country._regions = {}
	country._countries = {}

	units._selectedUnits = nil

	country.lastRegionID = 0
	country.lastCountryID = 0

	map.unload(true)
	collectgarbage()
end