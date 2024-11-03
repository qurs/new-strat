function table.RemoveByValue(tbl, val)
	local i
	for k, v in ipairs(tbl) do
		if v == val then
			i = k
			break
		end
	end
	if not i then return end

	table.remove(tbl, i)
	return true
end

function table.RemoveByMemberValue(tbl, key, val)
	local i
	for k, v in ipairs(tbl) do
		if v[key] == val then
			i = k
			break
		end
	end
	if not i then return end

	table.remove(tbl, i)
	return true
end

function table.HasMemberValue(tbl, key, val)
	for _, v in ipairs(tbl) do
		if v[key] == val then
			return true
		end
	end

	return false
end

function table.HasValue(tbl, val)
	for _, v in ipairs(tbl) do
		if v == val then
			return true
		end
	end

	return false
end

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

--[[---------------------------------------------------------
	A Pairs function
		Sorted by TABLE KEY
-----------------------------------------------------------]]
function SortedPairs( pTable, Desc )

	local keys = table.GetKeys( pTable )

	if ( Desc ) then
		table.sort( keys, function( a, b )
			return a > b
		end )
	else
		table.sort( keys, function( a, b )
			return a < b
		end )
	end

	local i, key = 1
	return function()
		key, i = keys[ i ], i + 1
		return key, pTable[ key ]
	end

end