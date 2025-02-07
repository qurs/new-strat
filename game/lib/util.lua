function ScrW()
	return love.graphics.getWidth()
end

function ScrH()
	return love.graphics.getHeight()
end

function PrintTable( t, indent, done )
	local Msg = io.write

	done = done or {}
	indent = indent or 0
	local keys = table.GetKeys( t )

	table.sort( keys, function( a, b )
		if ( type( a ) == 'number' and type( b ) == 'number' ) then return a < b end
		return tostring( a ) < tostring( b )
	end )

	done[ t ] = true

	for i = 1, #keys do
		local key = keys[ i ]
		local value = t[ key ]
		Msg( string.rep( '\t', indent ) )

		if  ( type( value ) == 'table' and not done[ value ] ) then

			done[ value ] = true
			Msg( tostring(key) .. ':\n' )
			PrintTable ( value, indent + 2, done )
			done[ value ] = nil

		else

			Msg( tostring(key) .. '\t=\t' .. tostring(value) .. '\n' )

		end

	end

end

function RGBFromNum(num)
	num = math.floor(num)
	if num < 0 or num > 16777215 then return end

	local r = math.floor(num / (256 * 256)) % 256
	local g = math.floor(num / 256) % 256
	local b = num % 256

	return r, g, b
end

_type = _type or type
function type(obj)
	if _type(obj) == 'table' and obj.__type then
		return obj.__type
	end

	return _type(obj)
end