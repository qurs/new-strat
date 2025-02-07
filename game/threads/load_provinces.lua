require('love.image')
require('lib/string')

local args = {...}
local path = args[1]
local imgData = args[2]
local pixelCount = args[3]
local w = args[4]

local ffi = require('ffi')

for line in love.filesystem.lines(path) do
	local data = string.Split(line, ';')
	local id = tonumber(data[1])
	local r, g, b = tonumber(data[2]), tonumber(data[3]), tonumber(data[4])
	local colorID = ('%s,%s,%s'):format(r, g, b)
	local type = data[5]
	local isCoastal = data[6] and tobool(data[6]) or false

	local pixels = {}
	local pixelsMap = {}
	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge

	do
		local pointer = ffi.cast('uint8_t*', imgData:getFFIPointer())

		for i = 0, (4 * pixelCount) - 1, 4 do
			local pr, pg, pb = pointer[i], pointer[i + 1], pointer[i + 2]

			if pr == r and pg == g and pb == b then
				local pos = i / 4
				local y = math.floor(math.max(pos - 1, 0) / w)
				local x = pos - (w * y)

				minX, minY = math.min(minX, x), math.min(minY, y)
				maxX, maxY = math.max(maxX, x), math.max(maxY, y)

				local index = #pixels + 1
				pixels[index] = {x, y}
				pixelsMap[x .. '|' .. y] = index
			end
		end
	end

	love.thread.getChannel('assetloader'):push({
		id = id,
		colorID = colorID,
		rgb255 = {r, g, b},
		pixels = pixels,
		pixelsMap = pixelsMap,
		minPos = {minX, minY},
		maxPos = {maxX, maxY},
		type = type,
		isCoastal = isCoastal,
	})
end