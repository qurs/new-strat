country = country or {}
country._provinceMeta = country._provinceMeta or {}

local Province = country._provinceMeta

Province.__type = 'province'
Province.__index = Province

function Province:__init(id, clr)
	self.id = id
	self.clr = clr

	--[[ OPTIONAL FIELDS
		self.countryOwner = nil
		self.regionOwner = nil
	]]
end

function Province:__tostring()
	local r, g, b = self:GetRGB255()
	return ('Province[%s][%s %s %s][%s]'):format(self:GetID(), r, g, b, self:GetHEX())
end

-- GETTERS

function Province:GetID()
	return self.id
end

function Province:GetColorData()
	return self.clr
end

function Province:GetRGB()
	local clr = self:GetColorData()

	return unpack(clr.rgb)
end

function Province:GetRGB255()
	local clr = self:GetColorData()

	return unpack(clr.rgb255)
end

function Province:GetHEX()
	local clr = self:GetColorData()

	return clr.hex
end

function Province:GetCountry()
	return self.countryOwner
end

function Province:GetRegion()
	return self.regionOwner
end

-- SETTERS

function Province:_SetRegion(region)
	self.regionOwner = region
end

-- OTHER

function Province:ChangeRegion(region)
	local oldRegion = self:GetRegion()
	if oldRegion and oldRegion == region then return end

	if oldRegion then
		oldRegion:RemoveProvince(self:GetID())
	end

	region:AddProvince(self)

	map.createCanvas()
end

-- Hooks

function Province:Draw(mapW, mapH, clr)
	local r, g, b = self:GetRGB()
	if clr then
		r, g, b = unpack(clr)
	end

	love.graphics.setColor(r, g, b)
	love.graphics.rectangle('fill', 0, 0, mapW, mapH)
end

function Province:OnClick(button)
	local country = country.get(1)
	local reg = country:GetRegions()[1]

	reg:AddProvince(self)
end