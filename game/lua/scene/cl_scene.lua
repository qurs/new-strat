scene = scene or {}

local function loadFile(fileName)
	local path = 'scenes/' .. fileName

	local chunk, err = love.filesystem.load(path)
	if not chunk then
		print( ('Ошибка при загрузке файла %s: %s'):format(path, err) )
		return
	end

	local ok, err = pcall(chunk)
	if not ok then
		print( ('Ошибка при загрузке файла %s: %s'):format(path, err) )
		return
	end

	return err
end

function scene.change(newScene, withoutMeta)
	local current = scene.get()
	local from
	if current then
		from = current.name

		if current.meta and current.meta.OnChanged then
			current:OnChanged(from, newScene)
		end
	end

	local sceneMeta = not withoutMeta and loadFile(newScene .. '.lua')

	scene._current = {
		name = newScene,
		meta = sceneMeta,
	}

	if sceneMeta and sceneMeta.Initialize then
		sceneMeta:Initialize()
	end

	hook.Run('OnSceneChanged', from, newScene)
end

function scene.get()
	return scene._current
end

function scene.getName()
	local current = scene.get()
	return current and current.name
end

hook.Add('Think', 'scene', function(dt)
	local current = scene.get()
	if not current or not current.meta or not current.meta.Think then return end

	current.meta:Think(dt)
end)