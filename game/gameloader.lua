local gameloader = {}

function gameloader.loadFile(moduleName, fileName)
	local path = 'lua/'
	if moduleName then
		path = path .. moduleName .. '/' .. fileName
	else
		path = path .. fileName
	end

	local chunk, err = love.filesystem.load(path)
	if not chunk then
		print( ('Ошибка при загрузке файла %s: %s'):format(path, err) )
		return
	end

	MODULE_NAME = moduleName
		local ok, err = pcall(chunk)
		if not ok then
			print( ('Ошибка при загрузке файла %s: %s'):format(path, err) )
			return
		end
	MODULE_NAME = nil
end

function gameloader.loadDir(dirName)
	local files = love.filesystem.getDirectoryItems('lua/' .. dirName)
	for _, fileName in SortedPairs(files) do
		gameloader.loadFile(dirName, fileName)
	end
end

function gameloader.load()
	local files = love.filesystem.getDirectoryItems('lua')
	for _, fileName in SortedPairs(files) do
		if fileName:sub(-4) == '.lua' then
			gameloader.loadFile(nil, fileName)
		else
			gameloader.loadDir(fileName)
		end
	end
end

return gameloader