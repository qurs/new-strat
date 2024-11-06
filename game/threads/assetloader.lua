require('love.image')
require('love.sound')

local args = {...}
local files = args[1]

for _, v in ipairs(files) do
	local ans = {
		name = v.name,
		type = v.type,
	}

	if v.type == 'img' then
		ans.content = v.compressed and love.image.newCompressedData(v.path) or love.image.newImageData(v.path)

		love.thread.getChannel('assetloader'):push(ans)
		goto continue
	elseif v.type == 'array_img' then
		local arrayImgData = {}
		for _, path in ipairs(v.path) do
			arrayImgData[#arrayImgData + 1] = v.compressed and love.image.newCompressedData(path) or love.image.newImageData(path)
		end

		ans.content = arrayImgData

		love.thread.getChannel('assetloader'):push(ans)
		goto continue
	elseif v.type == 'sound' then
		ans.content = love.sound.newSoundData(v.path)

		love.thread.getChannel('assetloader'):push(ans)
		goto continue
	end

	local read, err = love.filesystem.read(v.path)
	if read then
		ans.content = read
	else
		ans.err = err
	end

	love.thread.getChannel('assetloader'):push(ans)
	::continue::
end