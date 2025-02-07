provinceMapGen = provinceMapGen or {}
provinceMapGen._meta = provinceMapGen._meta or {}

local ProvinceMapGenerator = provinceMapGen._meta
ProvinceMapGenerator.__index = ProvinceMapGenerator

local fn = function() end

function ProvinceMapGenerator:init()
	self.inputMapPath = 'mapgenerator/map.png'
	self.path = 'mapgenerator/province_map.png'
	self.csvPath = 'mapgenerator/provinces.csv'

	self.avgProvinceLandSize = 500
	self.avgProvinceOceanSize = 12000
	self.lloydIterations = 5

	self.callback = fn
end

function ProvinceMapGenerator:SetCallback(callback)
	self.callback = callback
	return self
end

function ProvinceMapGenerator:SetInputMapPath(path)
	self.inputMapPath = path
	return self
end

function ProvinceMapGenerator:SetSavePath(path)
	self.path = path
	return self
end

function ProvinceMapGenerator:SetSaveCSVPath(path)
	self.csvPath = path
	return self
end

function ProvinceMapGenerator:SetLandSize(size)
	self.avgProvinceLandSize = size
	return self
end

function ProvinceMapGenerator:SetOceanSize(size)
	self.avgProvinceOceanSize = size
	return self
end

function ProvinceMapGenerator:SetLloydIterations(iterations)
	self.lloydIterations = iterations
	return self
end

function ProvinceMapGenerator:Generate()
	if provinceMapGen._isGenerating then return end

	provinceMapGen._generationProgress = 0
	provinceMapGen._isGenerating = self

	love.thread.newThread('threads/prov_generation.lua'):start(love.image.newImageData(self.inputMapPath), self.avgProvinceLandSize, self.avgProvinceOceanSize, self.lloydIterations)
end

function provinceMapGen.newGenerator()
	love.filesystem.createDirectory('mapgenerator')

	local meta = setmetatable({}, provinceMapGen._meta)
	meta:init()

	return meta
end

function provinceMapGen.getProgress()
	return provinceMapGen._generationProgress or 0
end

hook.Add('Think', 'provGen', function()
	local meta = provinceMapGen._isGenerating
	if not meta then return end

	do
		local channel = love.thread.getChannel('prov_generator')
		if channel then
			local result = channel:pop()
			if result then
				local data = result.imgData:encode('png')
				love.filesystem.write(meta.path, data)
				love.filesystem.write(meta.csvPath, result.csv)
	
				meta.callback(meta)
				provinceMapGen._isGenerating = nil

				return
			end
		end
	end

	do
		local channel = love.thread.getChannel('prov_generator_progress')
		if channel then
			local progress = channel:pop()
			if progress then
				provinceMapGen._generationProgress = progress
			end
		end
	end
end)

--[[ Пример использования
	mapGen.newGenerator()
		:SetRemoveLakes(true)
		:SetMinIslandSize(256)
	:Generate()

	provinceMapGen.newGenerator()
	:Generate()
]]