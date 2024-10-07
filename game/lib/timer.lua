timer = {}
timer._timers = {}

function timer.Ipairs(tbl, delay, callback)
	local i = 1
	local id = os.clock() .. math.random() .. 'ipairs' .. tostring(tbl)

	timer.Create(id, delay, 0, function()
		if tbl[i] == nil then return timer.Remove(id) end
		callback(i, tbl[i])
		i = i + 1
	end)
end

function timer.Pairs(tbl, delay, callback)
	local id = os.clock() .. math.random() .. 'pairs' .. tostring(tbl)
	local lastKey

	timer.Create(id, delay, 0, function()
		local k, v = next(tbl, lastKey)
		if k == nil then return timer.Remove(id) end

		lastKey = k
		callback(k, v)
	end)
end

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

function timer.Remove(id)
	timer._timers[id] = nil
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