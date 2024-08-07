local gameloader = {}

function gameloader.loadFile(dir, moduleName, fileName)
	local path = dir .. '/'
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

function gameloader.loadDir(dir, dirName)
	local files = love.filesystem.getDirectoryItems(dir .. '/' .. dirName)
	for _, fileName in SortedPairs(files) do
		gameloader.loadFile(dir, dirName, fileName)
	end
end

function gameloader.load(dir)
	dir = dir or 'lua'

	local files = love.filesystem.getDirectoryItems(dir)
	for _, fileName in SortedPairs(files) do
		if fileName:sub(-4) == '.lua' then
			gameloader.loadFile(dir, nil, fileName)
		else
			gameloader.loadDir(dir, fileName)
		end
	end
end

return gameloader