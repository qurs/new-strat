country = country or {}
country._regionMeta = country._regionMeta or {}

local Region = country._regionMeta

Region.__type = 'region'
Region.__index = Region

function Region:__init(id, name, provinces, country)
	if not id then return print( ('Ошибка при создании региона %s! Не хватает свойства: id'):format(id) ) end
	if not name then return print( ('Ошибка при создании региона %s! Не хватает свойства: name'):format(id) ) end

	self.id = id
	self.name = name
	self.provinces = provinces or {}
	self.country = country

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

	map.createCanvas()
end

function Region:AddProvince(province)
	local id = province:GetID()
	if self.provinces[id] then return end

	province:_SetRegion(self)
	self.provinces[id] = province

	map.createCanvas()
end

function Region:RemoveProvince(id)
	local province = self.provinces[id]
	if not province then return end

	province:_SetRegion()
	self.provinces[id] = nil

	map.createCanvas()
end

-- Hooks

function Region:Draw()
	local provinces = self:GetProvinces()
	for id, province in pairs(provinces) do
		province:Draw()
	end
end