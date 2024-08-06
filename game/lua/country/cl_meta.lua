country = country or {}
country._countryMeta = country._countryMeta or {}

local Country = country._countryMeta

Country.__type = 'country'
Country.__index = Country

function Country:__init(id, name, rgb)
	self.id = id
	self.name = name
	self.clr = rgb
	self.regions = {}

	--[[ OPTIONAL FIELDS

	]]
end

function Country:__tostring()
	return ('Country[%s][%s][%s %s %s]'):format(self:GetID(), self:GetName(), self:GetColor())
end

-- GETTERS

function Country:GetID()
	return self.id
end

function Country:GetName()
	return self.name
end

function Country:GetColor()
	return unpack(self.clr)
end

function Country:GetRegions()
	return self.regions
end

-- SETTERS

function Country:SetName(name)
	self.name = name
end

function Country:AddRegion(region)
	local id = region:GetID()
	if self.regions[id] then return end

	region:_SetCountry(self)
	self.regions[id] = region

	local provinces = region:GetProvinces()
	for id, province in pairs(provinces) do
		province:CreateCanvas()
	end

	region:CreateCanvas()
	map.createCanvas()
end

function Country:RemoveRegion(id)
	local region = self.regions[id]
	if not region then return end

	region:_SetCountry()
	self.regions[id] = nil

	local provinces = region:GetProvinces()
	for id, province in pairs(provinces) do
		province:CreateCanvas()
	end

	region:CreateCanvas()
	map.createCanvas()
end

-- OTHER

-- Hooks

function Country:Draw()
	local regions = self:GetRegions()
	for id, region in pairs(regions) do
		region:Draw(mapW, mapH)
	end
end