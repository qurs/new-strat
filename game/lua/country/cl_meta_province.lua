country = country or {}
country._provinceMeta = country._provinceMeta or {}

local Province = country._provinceMeta

Province.__type = 'province'
Province.__index = Province

function Province:__init(id, clr, pixels, pixelsMap, minPos, maxPos)
	self.id = id
	self.clr = clr

	self.pixels = pixels
	self.pixelsMap = pixelsMap
	self.minPos = minPos
	self.maxPos = maxPos

	self.neighbors = {}

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

function Province:GetPixelsList()
	return self.pixels
end

function Province:GetPixelsMap()
	return self.pixelsMap
end

function Province:GetMinPos()
	return self.minPos
end

function Province:GetMaxPos()
	return self.maxPos
end

function Province:GetBounds()
	return self:GetMinPos(), self:GetMaxPos()
end

function Province:GetRegion()
	return self.regionOwner
end

function Province:GetCountry()
	local region = self:GetRegion()
	if not region then return end

	return region:GetCountry()
end

function Province:GetNeighbors()
	return self.neighbors
end

-- SETTERS

function Province:_SetRegion(region)
	self.regionOwner = region
end

-- OTHER

function Province:GetPixel(x, y)
	return self:GetPixelsMap()[x .. '|' .. y]
end

function Province:ChangeRegion(region)
	local oldRegion = self:GetRegion()
	if oldRegion and oldRegion == region then return end

	if oldRegion then
		oldRegion:RemoveProvince(self:GetID())
	end

	region:AddProvince(self)

	self:CreateCanvas()
	region:CreateCanvas()
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

function Province:CreateCanvas()
	local imgData = map._img
	if not imgData then return end

	local provincesImgData = imgData.provinces
	local mapW, mapH = unpack(imgData.size)

	local ratio = ScrH() / mapH
	local w, h = mapW * ratio, mapH * ratio

	local r, g, b = 1, 1, 1

	local country = self:GetCountry()
	if country then
		r, g, b = country:GetColor()
	end

	self.canvas = love.graphics.newCanvas(w, ScrH())

	love.graphics.setCanvas({self.canvas, stencil = true})
		love.graphics.stencil(function() drawMask({self:GetRGB()}, provincesImgData) end)
		love.graphics.setStencilTest('greater', 0)
			love.graphics.setColor(r, g, b)
			love.graphics.rectangle('fill', 0, 0, mapW, mapH)
		love.graphics.setStencilTest()
	love.graphics.setCanvas()
end

function Province:Draw(outlined)
	local canvas = self.canvas
	if not canvas then return end

	local w, h = canvas:getWidth(), canvas:getHeight()

	local shader = shaders.get('outline_mul')
	shader:send('coordStep', {1 / w, 1 / h})
	shader:send('size', 2)
	shader:send('mul', 0.65)

	if outlined then
		love.graphics.setShader(shader)
	end

	-- love.graphics.setColor(1, 1, 1)
	love.graphics.draw(canvas)

	if outlined then
		love.graphics.setShader()
	end
end

function Province:OnClick(button)
	if button == 1 then
		if regionEditor._editing then
			local id = self:GetID()
			local region = self:GetRegion()
			if region:GetCapitalProvince() == id then return end

			if regionEditor._selectedProvinces[id] then
				regionEditor._selectedProvinces[id] = nil
			else
				regionEditor._selectedProvinces[id] = self
			end

			return
		end

		map._selectedProvince = self
	elseif button == 2 then
		if regionEditor._editing then
			local id = self:GetID()
			local region = self:GetRegion()
			if region:GetCapitalProvince() == id then return end
			if not regionEditor._selectedProvinces[id] then return notify.show('error', 2, 'Нужно сначала выделить эту провинцию!') end

			regionEditor._selectedCapital = id

			return
		end

		local country = country.get(1)
		local reg = country:GetRegions()[1]
	
		self:ChangeRegion(reg)
	elseif button == 4 then
		local country = country.get(2)
		local reg = country:GetRegions()[2]
	
		self:ChangeRegion(reg)
	end
end