country = country or {}
country._provinceMeta = country._provinceMeta or {}

local Province = country._provinceMeta

Province.__type = 'province'
Province.__index = Province

function Province:__init(id, clr)
	self.id = id
	self.clr = clr

	--[[ OPTIONAL FIELDS
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

function Province:GetRegion()
	return self.regionOwner
end

function Province:GetCountry()
	local region = self:GetRegion()
	if not region then return end

	return region:GetCountry()
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

local function drawMask(clr, provincesImgData)
	local provincesImg = provincesImgData.img
	local provincesW, provincesH = unpack(provincesImgData.size)

	local ratio = ScrH() / provincesH
	local w, h = provincesW * ratio, provincesH * ratio
	local x = ScrW() / 2 - w / 2

	local shader = shaders.get('draw_province')
	shader:sendColor('targetColor', clr)

	love.graphics.setShader(shader)
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(provincesImg, 0, 0, 0, ratio)
	love.graphics.setShader()
end

function Province:Draw()
	local imgData = map._img
	if not imgData then return end

	local provincesImgData = imgData.provinces
	local mapW, mapH = unpack(imgData.size)

	local rgb = {self:GetRGB()}
	local r, g, b = unpack(rgb)
	local country = self:GetCountry()
	if country then
		r, g, b = country:GetColor()
	end

	love.graphics.stencil(function() drawMask(rgb, provincesImgData) end)
	love.graphics.setStencilTest('greater', 0)
		love.graphics.setColor(r, g, b)
		love.graphics.rectangle('fill', 0, 0, mapW, mapH)
	love.graphics.setStencilTest()
end

function Province:OnClick(button)
	local country = country.get(1)
	local reg = country:GetRegions()[1]

	reg:AddProvince(self)
end