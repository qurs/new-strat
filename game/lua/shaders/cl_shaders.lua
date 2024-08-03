shaders = {}
shaders._list = {}

function shaders.get(name)
	return shaders._list[name]
end

function shaders.add(name, ...)
	shaders._list[name] = love.graphics.newShader(...)
	return shaders._list[name]
end