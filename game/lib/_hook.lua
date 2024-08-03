hook = {}
hook._handlers = {}

function hook.Add(name, id, callback)
	hook._handlers[name] = hook._handlers[name] or {}
	hook._handlers[name][id] = callback
end

function hook.Run(name, ...)
	local handlers = hook._handlers[name]
	if not handlers then return end

	for id, callback in SortedPairs(handlers) do
		local val = callback(...)
		if val ~= nil then
			return val
		end
	end
end