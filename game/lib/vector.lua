Vector = class('Vector')

function Vector:init(x, y)
	self[1] = x or 0
	self[2] = y or 0
end

function Vector.__index(self, key)
	if key == 'x' then
		return rawget(self, 1)
	end

	if key == 'y' then
		return rawget(self, 2)
	end

	return Vector[key]
end

function Vector.__newindex(self, key, val)
	if key == 'x' or key == 1 then
		rawset(self, 1, val)
	end

	if key == 'y' or key == 2 then
		rawset(self, 2, val)
	end
end

function Vector:__eq(other)
	if other:instanceOf(Vector) then
		return self[1] == other[1] and self[2] == other[2]
	end

	return false
end

function Vector:__add(other)
	local first, second = self, other
	local x, y

	if type(first) == 'number' then
		x, y = second.x + first, second.y + first
	elseif type(second) == 'number' then
		x, y = first.x + second, first.y + second
	elseif first:instanceOf(Vector) and second:instanceOf(Vector) then
		x, y = first.x + second.x, first.y + second.y
	end

	if not x then return error(('Попытка сложить %s + %s'):format(first, second)) end

	return Vector(x, y)
end

function Vector:__sub(other)
	local first, second = self, other
	local x, y

	if type(first) == 'number' then
		x, y = second.x - first, second.y - first
	elseif type(second) == 'number' then
		x, y = first.x - second, first.y - second
	elseif first:instanceOf(Vector) and second:instanceOf(Vector) then
		x, y = first.x - second.x, first.y - second.y
	end

	if not x then return error(('Попытка вычесть %s - %s'):format(first, second)) end

	return Vector(x, y)
end

function Vector:__mul(other)
	local first, second = self, other
	local x, y

	if type(first) == 'number' then
		x, y = second.x * first, second.y * first
	elseif type(second) == 'number' then
		x, y = first.x * second, first.y * second
	elseif first:instanceOf(Vector) and second:instanceOf(Vector) then
		x, y = first.x * second.x, first.y * second.y
	end

	if not x then return error(('Попытка умножить %s * %s'):format(first, second)) end

	return Vector(x, y)
end

function Vector:__div(other)
	local first, second = self, other
	local x, y

	if type(first) == 'number' then
		x, y = second.x / first, second.y / first
	elseif type(second) == 'number' then
		x, y = first.x / second, first.y / second
	elseif first:instanceOf(Vector) and second:instanceOf(Vector) then
		x, y = first.x / second.x, first.y / second.y
	end

	if not x then return error(('Попытка поделить %s / %s'):format(first, second)) end

	return Vector(x, y)
end

function Vector:__unm()
	return Vector(-self.x, -self.y)
end

function Vector:__tostring()
	return ('Vector[%s, %s]'):format(self:Unpack())
end

function Vector:Unpack()
	return self.x, self.y
end

function Vector:Length()
	return math.sqrt( self:LengthSqr() )
end

function Vector:LengthSqr()
	return self.x * self.x + self.y * self.y
end

function Vector:DistanceSqr(other)
	local xd = other.x - self.x
	local yd = other.y - self.y
	return xd * xd + yd * yd
end

function Vector:Distance(other)
	return math.sqrt( self:DistanceSqr(other) )
end

function Vector:Angle(other)
	return math.atan2(other.y - self.y, other.x - self.x)
end

function Vector:Clamp(min, max)
	if self.x < min.x then self.x = min.x end
	if self.x > max.x then self.x = max.x end

	if self.y < min.y then self.y = min.y end
	if self.y > max.y then self.y = max.y end

	return self
end

function Vector:Rotate(ang)
	local cos, sin = math.cos(ang), math.sin(ang)
	local matrix = { {cos, -sin}, {sin, cos} }

	local x, y = self.x, self.y

	self.x = matrix[1][1] * x + matrix[1][2] * y
	self.y = matrix[2][1] * x + matrix[2][2] * y

	return self
end

function Vector:Rotated(ang)
	local cos, sin = math.cos(ang), math.sin(ang)
	local matrix = { {cos, -sin}, {sin, cos} }

	local x, y = self.x, self.y
	local newX, newY = matrix[1][1] * x + matrix[1][2] * y, matrix[2][1] * x + matrix[2][2] * y

	return Vector(newX, newY)
end

function Vector:IsInsideSquare(minPos, maxPos)
	return math.HasSquarePoint(minPos, maxPos, self)
end