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