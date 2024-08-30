util = util or {}

util._preDrawQueue = util._preDrawQueue or {}

function util.queuePreDrawMethodCall(obj, methodName, ...)
	util._preDrawQueue[#util._preDrawQueue + 1] = {obj, methodName, {...}}
end

function util.queuePreDrawFunctionCall(func, ...)
	util._preDrawQueue[#util._preDrawQueue + 1] = {nil, func, {...}}
end

hook.Add('PreDraw', '_util.preDrawQueue', function()
	for _, v in ipairs(util._preDrawQueue) do
		local obj, methodNameOrFunc, args = unpack(v)
		if obj then
			local methodName = methodNameOrFunc
			pcall( obj[methodName], obj, unpack(args) )
		else
			local func = methodNameOrFunc
			pcall( func, unpack(args) )
		end
	end

	util._preDrawQueue = {}
end)