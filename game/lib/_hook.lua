hook = {}
hook._handlers = {}

function hook.Add(name, id, callback, order)
	order = order or 0

	hook._handlers[name] = hook._handlers[name] or {}
	hook._handlers[name][order] = hook._handlers[name][order] or {}

	hook._handlers[name][order][id] = callback
end

function hook.Run(name, ...)
	local orders = hook._handlers[name]
	if not orders then return end

	for order, handlers in SortedPairs(orders, true) do
		for id, callback in SortedPairs(handlers) do
			local val = callback(...)
			if val ~= nil then
				return val
			end
		end	
	end
end