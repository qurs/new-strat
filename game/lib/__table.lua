function table.IsEmpty( tab )
	return next( tab ) == nil
end

function table.Count(tbl)
	local i = 0

	for k, v in pairs(tbl) do
		i = i + 1
	end

	return i
end

function table.GetKeys( tab )

	local keys = {}
	local id = 1

	for k, v in pairs( tab ) do
		keys[ id ] = k
		id = id + 1
	end

	return keys

end

local function keyValuePairs( state )

	state.Index = state.Index + 1

	local keyValue = state.KeyValues[ state.Index ]
	if not keyValue then return end

	return keyValue.key, keyValue.val

end

local function toKeyValues( tbl )

	local result = {}

	for k,v in pairs( tbl ) do
		table.insert( result, { key = k, val = v } )
	end

	return result

end

--[[---------------------------------------------------------
	A Pairs function
		Sorted by TABLE KEY
-----------------------------------------------------------]]
function SortedPairs( pTable, Desc )

	local sortedTbl = toKeyValues( pTable )

	if ( Desc ) then
		table.sort( sortedTbl, function( a, b ) return a.key > b.key end )
	else
		table.sort( sortedTbl, function( a, b ) return a.key < b.key end )
	end

	return keyValuePairs, { Index = 0, KeyValues = sortedTbl }

end