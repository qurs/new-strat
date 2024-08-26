assetloader = {}
assetloader._cache = {}

local threadCode = [[
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
			ans.content = love.sound.newDecoder(v.path)

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
]]

local thread = love.thread.newThread(threadCode)

local curLoading = {
	bLoading = false,
}

local curStage = {}

local stages

function assetloader.get(assetName)
	return assetloader._cache[assetName]
end

function assetloader.isLoading()
	return curLoading.bLoading
end

function assetloader.getStage()
	return curStage.name
end

function assetloader.getProgress()
	return curStage.step or 0
end

function assetloader.getMaxProgress()
	return curStage.maxStep or 0
end

function assetloader.nextStage(bFirst)
	if not stages then return end
	if not bFirst then table.remove(stages, 1) end

	local newStage = stages[1]
	if not newStage then
		curLoading.bLoading = false
		curStage = {}

		if curLoading.callback then
			curLoading.callback()
			curLoading.callback = nil
		end

		return
	end

	curStage.type = newStage.type
	curStage.step = 0
	curStage.name = newStage.name

	if curStage.type == 'custom' then
		curStage.handler = newStage.handler
		curStage.maxStep = newStage.maxStep

		local newThread = love.thread.newThread(newStage.code)

		if newStage.args then
			if type(newStage.args) == 'table' then
				newThread:start(unpack(newStage.args))
			else
				newThread:start( newStage.args() )
			end
		else
			newThread:start()
		end
	else
		curStage.maxStep = #newStage.files
		curStage.files = newStage.files

		thread:start(curStage.files)
	end
end

--[[ Example:
	assetloader.load({
		stages = {
			{
				name = 'test1',
				files = {
					{path = 'assets/1.jpg', name = 'testfile', type = 'img'},
					{path = 'assets/2.jpg', name = 'testfile2', type = 'img'},
					{path = 'assets/3.jpg', name = 'testfile3', type = 'img'},
				},
			},
		},
	})
]]

function assetloader.load(queue, callback)
	curLoading.bLoading = true
	curLoading.callback = callback
	stages = queue.stages

	assetloader.nextStage(true)
end

hook.Add('Think', '_assetloader', function()
	if assetloader._web then return end
	if not curStage.name then return end

	if curStage.step >= curStage.maxStep then
		return assetloader.nextStage()
	end

	local channel = love.thread.getChannel('assetloader')
	if not channel then return end

	if curStage.type == 'custom' then
		local handler = curStage.handler
		local result = channel:pop()
		if not result then return end

		handler(result)
		curStage.step = curStage.step + 1

		return
	end

	local loadedFile = channel:pop()
	if not loadedFile then return end

	if loadedFile.err then
		print('Ошибка при попытке загрузить файл-ассет:', loadedFile.err)
	elseif loadedFile.content then
		local content = loadedFile.content

		if loadedFile.type == 'img' then
			content = {img = love.graphics.newImage(content), data = content}
		elseif loadedFile.type == 'array_img' then
			content = {img = love.graphics.newArrayImage(content), data = content}
		end

		assetloader._cache[loadedFile.name] = content
	end

	curStage.step = curStage.step + 1
end)

return assetloader