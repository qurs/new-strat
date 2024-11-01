gamecycle = gamecycle or {}

gamecycle.speed = 1

gamecycle.speeds = {1, 4, 8, 16}
gamecycle._currentSpeedIndex = 1

gamecycle._time = gamecycle._time or 1

function gamecycle.start()
	if gamecycle._blocked then return end

	gamecycle._started = true
end

function gamecycle.pause()
	gamecycle._started = nil
end

function gamecycle.toggle()
	if gamecycle._started then
		gamecycle.pause()
	else
		gamecycle.start()
	end
end

function gamecycle.setSpeed(speed)
	gamecycle._currentSpeedIndex = speed
	gamecycle.speed = gamecycle.speeds[gamecycle._currentSpeedIndex]
end

function gamecycle.decreaseSpeed()
	gamecycle._currentSpeedIndex = math.max(gamecycle._currentSpeedIndex - 1, 1)
	gamecycle.speed = gamecycle.speeds[gamecycle._currentSpeedIndex]
end

function gamecycle.increaseSpeed()
	gamecycle._currentSpeedIndex = math.min(gamecycle._currentSpeedIndex + 1, 4)
	gamecycle.speed = gamecycle.speeds[gamecycle._currentSpeedIndex]
end

function gamecycle.getDate()
	local time = gamecycle._time or 1

	local year = math.floor(time / 8640)
	time = time - (year * 8640)

	local month = math.floor(time / 720)
	time = time - (month * 720)

	local day = math.floor(time / 24)
	time = time - (day * 24)

	return {
		year = year + 1,
		month = month + 1,
		day = day + 1,
		hour = time,
	}
end

hook.Add('DrawUI', 'gamecycle', function()
	if not gamecycle.ui then return end
	gamecycle.ui()
end)

hook.Add('Think', 'gamecycle', function(dt)
	if not gamecycle._started then return end
	if gamecycle._nextStep and gamecycle._nextStep > os.clock() then return end

	gamecycle._time = gamecycle._time + 1
	gamecycle._nextStep = os.clock() + (1 / gamecycle.speed)

	hook.Run('gamecycle.step')
end)