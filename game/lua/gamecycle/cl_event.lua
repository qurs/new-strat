gamecycle = gamecycle or {}
gamecycle.event = gamecycle.event or {}

gamecycle._events = gamecycle._events or {}

gamecycle._events.single = gamecycle._events.single or {}
gamecycle._events.regular = gamecycle._events.regular or {}

gamecycle._plannedEvents = gamecycle._plannedEvents or {}

function gamecycle.event.registerEvent(name, callback)
	gamecycle._events.single[name] = callback
end

function gamecycle.event.registerRegularEvent(name, delay, callback)
	gamecycle._events.regular[name] = {callback = callback, delay = delay, lastTime = gamecycle._time or 1}
end

function gamecycle.event.startEvent(name, ...)
	local callback = gamecycle._events.single[name]
	if not callback then return end

	callback(...)
end

function gamecycle.event.startDelayedEvent(name, delay, ...)
	gamecycle._plannedEvents[#gamecycle._plannedEvents + 1] = {name, (gamecycle._time or 1) + delay, {...}}
end

hook.Add('gamecycle.step', 'gamecycle.event', function()
	for k, v in ipairs(gamecycle._plannedEvents) do
		local toRemove = {}

		local name, endTime, args = unpack(v)
		if gamecycle._time >= endTime then
			gamecycle.event.startEvent(name, unpack(args))
			toRemove[#toRemove + 1] = k
		end

		for i = #toRemove, 1, -1 do
			table.remove(gamecycle._plannedEvents, toRemove[i])
		end
	end

	for name, v in pairs(gamecycle._events.regular) do
		local diff = gamecycle._time - v.lastTime
		if diff >= v.delay then
			v.lastTime = gamecycle._time
			v.callback()
		end
	end
end)