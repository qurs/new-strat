local args = {...}
local provinces = args[1]

for i, province in ipairs(provinces) do
	local neighbors = {}
	local myPixels = province.pixels

	for i2, otherProvince in ipairs(provinces) do
		if i == i2 then goto continue end

		for _, pixel in ipairs(myPixels) do
			local x, y = unpack(pixel)
			if otherProvince.pixelsMap[(x - 1) .. '|' .. y] or otherProvince.pixelsMap[(x + 1) .. '|' .. y] or otherProvince.pixelsMap[x .. '|' .. (y - 1)] or otherProvince.pixelsMap[x .. '|' .. (y + 1)] then
				neighbors[#neighbors + 1] = i2
				break
			end

			::continue::
		end

		::continue::
	end

	love.thread.getChannel('assetloader'):push({
		id = i,
		result = neighbors,
	})
end