country = country or {}
country._regionMeta = country._regionMeta or {}

local Region = country._regionMeta

Region.__type = 'region'
Region.__index = Region

function Region:__init(id, name, provinces)
	if not id then return print( ('Ошибка при создании региона %s! Не хватает свойства: id'):format(id) ) end
	if not name then return print( ('Ошибка при создании региона %s! Не хватает свойства: name'):format(id) ) end

	self.id = id
	self.name = name
	self.provinces = provinces or {}

	--[[ OPTIONAL FIELDS
		
	]]
end

function Region:__tostring()
	return ('Region[%s][%s]'):format(self:GetID(), self:GetName())
end

-- GETTERS

function Region:GetID()
	return self.id
end

function Region:GetName()
	return self.name
end

function Region:GetProvinces()
	return self.provinces
end

function Region:GetCountry()
	return self.country
end

-- SETTERS

function Region:SetName(name)
	self.name = name
end

function Region:_SetCountry(country)
	self.country = country
end

-- OTHER

function Region:ChangeCountry(country)
	local oldCountry = self:GetCountry()
	if oldCountry then
		oldCountry:RemoveRegion(self:GetID())
	end

	country:AddRegion(self)

	local provinces = self:GetProvinces()
	for id, province in pairs(provinces) do
		province:CreateCanvas()
	end

	self:CreateCanvas()
	map.createCanvas()
end

function Region:AddProvince(province)
	local id = province:GetID()
	if self.provinces[id] then return end
	if province:GetRegion() then return end

	province:_SetRegion(self)
	province:CreateCanvas()
	self.provinces[id] = province

	self:CreateCanvas()
	map.createCanvas()
end

function Region:RemoveProvince(id)
	local province = self.provinces[id]
	if not province then return end

	province:_SetRegion()
	province:CreateCanvas()
	self.provinces[id] = nil

	self:CreateCanvas()
	map.createCanvas()
end

-- Hooks

function Region:CreateCanvas()
	local imgData = map._img
	if not imgData then return end

	local mapW, mapH = unpack(imgData.size)

	local ratio = ScrH() / mapH
	local w, h = mapW * ratio, mapH * ratio

	self.canvas = love.graphics.newCanvas(w, ScrH())
	-- self.canvas:setFilter('linear', 'nearest')

	love.graphics.setCanvas({self.canvas, stencil = true})
		love.graphics.clear(0, 0, 0, 0)
		love.graphics.setColor(1, 1, 1)

		local provinces = self:GetProvinces()
		for id, province in pairs(provinces) do
			province:Draw()
		end
	love.graphics.setCanvas()
end

function Region:Draw()
	local canvas = self.canvas
	if not canvas then return end

	local w, h = canvas:getWidth(), canvas:getHeight()

	local shader = shaders.get('outline_mul')
	shader:send('coordStep', {1 / w, 1 / h})
	shader:send('size', 3)
	shader:send('mul', 0.8)

	love.graphics.setShader(shader)
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(canvas)
	love.graphics.setShader()
end