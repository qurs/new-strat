vector = vector or {}

vector._meta = vector._meta or {}
local meta = vector._meta

meta.__isvector = true

function meta.__index(tbl, key)
	if key == 'x' then
		return tbl[1]
	end

	if key == 'y' then
		return tbl[2]
	end

	return meta[key]
end

function meta.__newindex(tbl, key, val)
	if key == 'x' or key == 1 then
		tbl[1] = val
	end

	if key == 'y' or key == 2 then
		tbl[2] = val
	end
end

function meta:__eq(other)
	if other.__isvector then
		return self[1] == other[1] and self[2] == other[2]
	end

	return false
end

function meta:__add(other)
	local first, second = self, other
	local pos

	if type(first) == 'number' then
		pos = {second.x + first, second.y + first}
	elseif type(second) == 'number' then
		pos = {first.x + second, first.y + second}
	elseif first.__isvector and second.__isvector then
		pos = {first.x + second.x, first.y + second.y}
	end

	if not pos then return error(('Попытка сложить %s + %s'):format(first, second)) end

	return setmetatable(pos, vector._meta)
end

function meta:__sub(other)
	local first, second = self, other
	local pos

	if type(first) == 'number' then
		pos = {second.x - first, second.y - first}
	elseif type(second) == 'number' then
		pos = {first.x - second, first.y - second}
	elseif first.__isvector and second.__isvector then
		pos = {first.x - second.x, first.y - second.y}
	end

	if not pos then return error(('Попытка вычесть %s - %s'):format(first, second)) end

	return setmetatable(pos, vector._meta)
end

function meta:__mul(other)
	local first, second = self, other
	local pos

	if type(first) == 'number' then
		pos = {second.x * first, second.y * first}
	elseif type(second) == 'number' then
		pos = {first.x * second, first.y * second}
	elseif first.__isvector and second.__isvector then
		pos = {first.x * second.x, first.y * second.y}
	end

	if not pos then return error(('Попытка умножить %s * %s'):format(first, second)) end

	return setmetatable(pos, vector._meta)
end

function meta:__div(other)
	local first, second = self, other
	local pos

	if type(first) == 'number' then
		pos = {second.x / first, second.y / first}
	elseif type(second) == 'number' then
		pos = {first.x / second, first.y / second}
	elseif first.__isvector and second.__isvector then
		pos = {first.x / second.x, first.y / second.y}
	end

	if not pos then return error(('Попытка поделить %s / %s'):format(first, second)) end

	return setmetatable(pos, vector._meta)
end

function meta:__unm()
	self.x = -self.x
	self.y = -self.y
	return self
end

function meta:__tostring()
	return ('Vector[%s, %s]'):format(self:Unpack())
end

function meta:Unpack()
	return self[1], self[2]
end

function meta:Length()
	return math.sqrt( self:LengthSqr() )
end

function meta:LengthSqr()
	return self[1]^2 + self[2]^2
end

function meta:DistanceSqr(other)
	local xd = other.x - self.x
	local yd = other.y - self.y
	return xd^2 + yd^2
end

function meta:Distance(other)
	return math.sqrt( self:DistanceSqr(other) )
end

function meta:Angle(other)
	return math.atan2(other.y - self.y, other.x - self.x)
end

function meta:Clamp(min, max)
	if self.x < min.x then self.x = min.x end
	if self.x > max.x then self.x = max.x end

	if self.y < min.y then self.y = min.y end
	if self.y > max.y then self.y = max.y end

	return self
end

function meta:Rotate(ang)
	local cos, sin = math.cos(ang), math.sin(ang)
	local matrix = { {cos, -sin}, {sin, cos} }

	local x, y = self.x, self.y

	self.x = matrix[1][1] * x + matrix[1][2] * y
	self.y = matrix[2][1] * x + matrix[2][2] * y

	return self
end

function meta:Rotated(ang)
	local cos, sin = math.cos(ang), math.sin(ang)
	local matrix = { {cos, -sin}, {sin, cos} }

	local x, y = self.x, self.y
	local pos = {matrix[1][1] * x + matrix[1][2] * y, matrix[2][1] * x + matrix[2][2] * y}

	return setmetatable(pos, vector._meta)
end

function Vector(x, y)
	local pos = {x or 0, y or 0}

	return setmetatable({
		x or 0,
		y or 0,
	}, meta)
end