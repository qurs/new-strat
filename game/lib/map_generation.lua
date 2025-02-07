mapGen = mapGen or {}
mapGen._meta = mapGen._meta or {}

local MapGenerator = mapGen._meta
MapGenerator.__index = MapGenerator

local fn = function() end

function MapGenerator:init()
	self.path = 'mapgenerator/map.png'
	self.width = 1920
	self.height = 1080

	self.removeLakes = false

	self.minIslandSize = 128
	self.minLakeSize = 256
	self.freq = 0.0015
	self.octave = 5

	self.callback = fn
end

function MapGenerator:SetCallback(callback)
	self.callback = callback
	return self
end

function MapGenerator:SetSavePath(path)
	self.path = path
	return self
end

function MapGenerator:SetSize(w, h)
	self.width = w
	self.height = h
	return self
end

function MapGenerator:SetWidth(w)
	self.width = w
	return self
end

function MapGenerator:SetHeight(h)
	self.height = h
	return self
end

function MapGenerator:SetRemoveLakes(b)
	self.removeLakes = b
	return self
end

function MapGenerator:SetMinIslandSize(size)
	self.minIslandSize = size
	return self
end

function MapGenerator:SetMinLakeSize(size)
	self.minLakeSize = size
	return self
end

function MapGenerator:SetFreq(freq)
	self.freq = freq
	return self
end

function MapGenerator:SetOctave(octave)
	self.octave = octave
	return self
end

function MapGenerator:Generate()
	if mapGen._isGenerating then return end

	mapGen._generationProgress = 0
	mapGen._isGenerating = self

	love.thread.newThread('threads/map_generation.lua'):start(self.removeLakes, self.minIslandSize, self.minLakeSize, self.freq, self.octave, self.width, self.height)
end

function mapGen.newGenerator()
	love.filesystem.createDirectory('mapgenerator')

	local meta = setmetatable({}, mapGen._meta)
	meta:init()

	return meta
end

function mapGen.getProgress()
	return mapGen._generationProgress or 0
end

hook.Add('Think', 'mapGen', function()
	local meta = mapGen._isGenerating
	if not meta then return end

	do
		local channel = love.thread.getChannel('map_generator')
		if channel then
			local imgData = channel:pop()
			if imgData then
				local data = imgData:encode('png')
				love.filesystem.write(meta.path, data)
	
				meta.callback(meta)
				mapGen._isGenerating = nil

				return
			end
		end
	end

	do
		local channel = love.thread.getChannel('map_generator_progress')
		if channel then
			local progress = channel:pop()
			if progress then
				mapGen._generationProgress = progress
			end
		end
	end
end)