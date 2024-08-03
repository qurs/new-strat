local libloader = {}

function libloader.loadLib(libName)
	local path = 'lib/' .. libName

	local chunk, err = love.filesystem.load(path)
	if not chunk then
		print( ('Ошибка при загрузке файла %s: %s'):format(libName, err) )
		return
	end

	local ok, err = pcall(chunk)
	if not ok then
		print( ('Ошибка при загрузке файла %s: %s'):format(libName, err) )
		return
	end
end

function libloader.load()
	local files = love.filesystem.getDirectoryItems('lib')
	for _, fileName in ipairs(files) do
		libloader.loadLib(fileName)
	end
end

return libloader