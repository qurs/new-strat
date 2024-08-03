local function isnumber(val)
	return type(val) == 'number'
end

local function istable(val)
	return type(val) == 'table'
end

function PrintTable( t, indent, done )
	local Msg = io.write

	done = done or {}
	indent = indent or 0
	local keys = table.GetKeys( t )

	table.sort( keys, function( a, b )
		if ( isnumber( a ) and isnumber( b ) ) then return a < b end
		return tostring( a ) < tostring( b )
	end )

	done[ t ] = true

	for i = 1, #keys do
		local key = keys[ i ]
		local value = t[ key ]
		key = (type( key ) == "string") and "[\"" ..  key .. "\"]" or "[" .. tostring( key ) .. "]"
		Msg( string.rep( "\t", indent ) )

		if  ( istable( value ) and not done[ value ] ) then

			done[ value ] = true
			Msg( key, ":\n" )
			PrintTable ( value, indent + 2, done )
			done[ value ] = nil

		else

			Msg( key, "\t=\t", tostring(value), "\n" )

		end

	end

end