util = util or {}

util._preDrawQueue = util._preDrawQueue or {}
util._prioritizedPreDrawQueue = util._prioritizedPreDrawQueue or {}

function util.queuePreDrawMethodCall(obj, methodName, ...)
	util._preDrawQueue[#util._preDrawQueue + 1] = {obj, methodName, {...}}
end

function util.queuePrioritizedPreDrawFunctionCall(func, ...)
	util._preDrawQueue[#util._preDrawQueue + 1] = {nil, func, {...}}
end

function util.queuePrioritizedPreDrawMethodCall(obj, methodName, priority, ...)
	util._prioritizedPreDrawQueue[#util._prioritizedPreDrawQueue + 1] = {obj, methodName, priority, {...}}
end

function util.queuePrioritizedPreDrawFunctionCall(func, priority, ...)
	util._prioritizedPreDrawQueue[#util._prioritizedPreDrawQueue + 1] = {nil, func, priority, {...}}
end

hook.Add('PreDraw', '_util.preDrawQueue', function()
	local calledYet = {}

	for _, v in ipairs(util._preDrawQueue) do
		local obj, methodNameOrFunc, args = unpack(v)
		if obj then
			local methodName = methodNameOrFunc
			local callable = obj[methodName]

			local bytecode = string.dump(callable)
			if calledYet[bytecode] then goto continue end

			pcall( callable, obj, unpack(args) )

			calledYet[bytecode] = true
		else
			local func = methodNameOrFunc

			local bytecode = string.dump(func)
			if calledYet[bytecode] then goto continue end

			pcall( func, unpack(args) )

			calledYet[bytecode] = true
		end

		::continue::
	end
	util._preDrawQueue = {}

	table.sort(util._prioritizedPreDrawQueue, function(a, b)
		return a[3] < b[3]
	end)

	calledYet = {}

	for _, v in ipairs(util._prioritizedPreDrawQueue) do
		local obj, methodNameOrFunc, _, args = unpack(v)
		if obj then
			local methodName = methodNameOrFunc
			local callable = obj[methodName]

			local name = tostring(obj) .. ':' .. methodName
			if calledYet[name] then goto continue end

			pcall( callable, obj, unpack(args) )

			calledYet[name] = true
		else
			local func = methodNameOrFunc

			local name = tostring(func)
			if calledYet[name] then goto continue end

			pcall( func, unpack(args) )

			calledYet[name] = true
		end

		::continue::
	end
	util._prioritizedPreDrawQueue = {}
end)