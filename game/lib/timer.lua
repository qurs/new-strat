timer = {}
timer._timers = {}

function timer.Create(id, time, reps, callback)
	timer._timers[id] = {
		time = time,
		endTime = os.clock() + time,
		reps = reps,
		repsLeft = (reps > 0) and reps,
		callback = callback,
	}
end

function timer.Simple(time, callback)
	local id = os.clock() .. math.random()
	timer.Create(id, time, 1, callback)
end

hook.Add('Think', 'timer', function()
	for id, data in pairs(timer._timers) do
		if data.endTime <= os.clock() then
			data.callback()

			if data.reps > 0 then
				data.repsLeft = data.repsLeft - 1

				if data.repsLeft <= 0 then
					timer._timers[id] = nil
				else
					data.endTime = os.clock() + data.time
				end
			else
				data.endTime = os.clock() + data.time
			end
		end
	end
end)