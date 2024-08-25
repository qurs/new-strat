gui.registerFont('region.capitalName', {
	font = 'Montserrat-Medium',
	size = 20,
})

country = country or {}
country._regionMeta = country._regionMeta or {}

local Region = country._regionMeta

Region.__type = 'region'
Region.__index = Region

function Region:__init(id, name, capitalName, provinces)
	if not id then return print( ('Ошибка при создании региона %s! Не хватает свойства: id'):format(id) ) end
	if not name then return print( ('Ошибка при создании региона %s! Не хватает свойства: name'):format(id) ) end
	if not capitalName then return print( ('Ошибка при создании региона %s! Не хватает свойства: capitalName'):format(id) ) end

	self.id = id
	self.name = name
	self.capitalName = capitalName

	self.provinces = provinces or {}
	self.provinceCount = table.Count(self.provinces)

	self.capitalText = love.graphics.newText(gui.getFont('region.capitalName'), capitalName)

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

function Region:GetCapitalName()
	return self.capitalName
end

function Region:GetProvinces()
	return self.provinces
end

function Region:GetProvinceCount()
	return self.provinceCount
end

function Region:GetCountry()
	return self.country
end

function Region:GetCapitalProvince()
	return self.capitalProvince
end

-- SETTERS

function Region:SetName(name)
	self.name = name
end

function Region:SetCapitalName(name)
	self.capitalName = name
end

function Region:_SetCountry(country)
	self.country = country
end

function Region:SetCapitalProvince(province)
	self.capitalProvince = province
end

-- OTHER

function Region:GetBounds()
	local provinces = self:GetProvinces()
	if table.IsEmpty(provinces) then return end

	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge

	for id, province in pairs(provinces) do
		local minPos, maxPos = province:GetBounds()

		minX, minY = math.min(minX, minPos.x), math.min(minY, minPos.y)
		maxX, maxY = math.max(maxX, maxPos.x), math.max(maxY, maxPos.y)
	end

	return Vector(minX, minY), Vector(maxX, maxY)
end

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

	self.provinceCount = self.provinceCount + 1

	if not self:GetCapitalProvince() then
		self:SetCapitalProvince(id)
	end

	self:CreateCanvas()
	map.createCanvas()
end

function Region:RemoveProvince(id)
	local province = self.provinces[id]
	if not province then return end

	province:_SetRegion()
	province:CreateCanvas()
	self.provinces[id] = nil

	self.provinceCount = self.provinceCount - 1

	if self:GetCapitalProvince() == id then
		local keys = table.GetKeys(self.provinces)
		local newID = keys[#math.random(keys)]
		if newID then
			self:SetCapitalProvince(newID)
		end
	end

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

	love.graphics.setCanvas(self.canvas)
		love.graphics.clear(0, 0, 0, 0)
		love.graphics.setColor(1, 1, 1)

		local provinces = self:GetProvinces()
		for id, province in pairs(provinces) do
			province:Draw()
		end
	love.graphics.setCanvas()
end

function Region:DrawCapital(offset)
	local id = self:GetCapitalProvince()
	if not id then return end

	local text = self.capitalText
	if not text then return end

	local imgData = map._img
	if not imgData then return end

	local mapW, mapH = unpack(imgData.size)
	local ratio = ScrH() / mapH

	local province = self.provinces[id]
	if not province then return end

	local minPos, maxPos = province:GetBounds()
	minPos, maxPos = minPos * ratio, maxPos * ratio

	local centerPos = (minPos + maxPos) / 2

	local pointSize = 2

	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle('fill', offset + centerPos.x - pointSize / 2, centerPos.y, pointSize, pointSize)

	local sx = 0.2

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(text, offset + centerPos.x - (text:getWidth() * sx) / 2, centerPos.y - (text:getHeight() * sx), 0, sx)
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