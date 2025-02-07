require('love.image')
require('lib/string')

local args = {...}
local path = args[1]
local imgData = args[2]
local w, h = imgData:getDimensions()
local pixelCount = w * h

local ffi = require('ffi')

local function getIndexByPosition(x, y)
	local pos = y * w + x
	return pos * 4
end

local function getColorByPosition(pointer, x, y)
	local i = getIndexByPosition(x, y)
	return pointer[i], pointer[i + 1], pointer[i + 2], pointer[i + 3]
end

local offsets = {
	{-1, 0}, {0, -1}, {1, 0}, {0, 1}
}

for line in love.filesystem.lines(path) do
	local data = string.Split(line, ';')
	local id = tonumber(data[1])
	local r, g, b = tonumber(data[2]), tonumber(data[3]), tonumber(data[4])
	local colorID = ('%s,%s,%s'):format(r, g, b)
	local type = data[5]
	local isCoastal = data[6] == 'true' and true or false

	local pixels = {}
	local pixelsMap = {}
	local neighbors = {}
	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge

	do
		local pointer = ffi.cast('uint8_t*', imgData:getFFIPointer())

		for i = 0, (4 * pixelCount) - 1, 4 do
			local pr, pg, pb = pointer[i], pointer[i + 1], pointer[i + 2]

			if pr == r and pg == g and pb == b then
				local pos = i / 4
				local x = pos % w
				local y = math.floor(pos / w)

				for _, offset in ipairs(offsets) do
					local nx, ny = x + offset[1], y + offset[2]
					if nx < 0 or nx > w - 1 or ny < 0 or ny > h - 1 then goto continue end

					local colStr = ('%s,%s,%s'):format(getColorByPosition(pointer, nx, ny))
					if colStr == colorID then goto continue end
					if neighbors[colStr] then goto continue end

					neighbors[colStr] = true

					::continue::
				end

				minX, minY = math.min(minX, x), math.min(minY, y)
				maxX, maxY = math.max(maxX, x), math.max(maxY, y)

				local index = #pixels + 1
				pixels[index] = {x, y}
				pixelsMap[x .. '|' .. y] = index
			end
		end
	end

	love.thread.getChannel('province_loader'):push({
		id = id,
		colorID = colorID,
		rgb255 = {r, g, b},
		pixels = pixels,
		pixelsMap = pixelsMap,
		neighbors = neighbors,
		minPos = {minX, minY},
		maxPos = {maxX, maxY},
		type = type,
		isCoastal = isCoastal,
	})
end