gui.registerFont('country.name', {
	font = 'Montserrat-Medium',
	size = 64,
})

country = country or {}

Country = class('Country')

function Country:init(id, name, rgb, capitalRegion)
	self.id = id
	self.name = name
	self.clr = rgb
	self.capitalRegion = capitalRegion
	self.regions = {}

	self.stability = 50
	self.units = {}

	self.peaceOfferCooldownList = {}

	self.text = love.graphics.newText(gui.getFont('country.name'), name)

	self.textRatio = self.text:getWidth() / self.text:getHeight()

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

function Country:GetCapitalRegion()
	return self.capitalRegion
end

function Country:GetStability()
	return self.stability
end

function Country:GetUnits()
	return self.units
end

-- SETTERS

function Country:SetName(name)
	self.name = name

	if self.text then
		self.text:set(name)
	else
		self.text = love.graphics.newText(gui.getFont('country.name'), name)
	end
end

function Country:SetCapitalRegion(reg)
	if not self:GetRegions()[reg:GetID()] then return end

	self.capitalRegion = reg
end

function Country:SetStability(stab)
	self.stability = math.Clamp(stab, 0, 100)

	if self.stability == 0 then
		self:Destroy('Страна погрязла в бунтах и восстаниях из-за политической нестабильности. На этом история заканчивается...')
	end
end

-- OTHER

function Country:GetBounds()
	local regions = self:GetRegions()
	if table.IsEmpty(regions) then return end

	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge

	for id, region in pairs(regions) do
		local minPos, maxPos = region:GetBounds()

		minX, minY = math.min(minX, minPos.x), math.min(minY, minPos.y)
		maxX, maxY = math.max(maxX, maxPos.x), math.max(maxY, maxPos.y)
	end

	return Vector(minX, minY), Vector(maxX, maxY)
end

function Country:AddStability(add)
	self:SetStability(self:GetStability() + add)
end

function Country:Destroy(reason)
	for id in pairs(self:GetRegions()) do
		self:RemoveRegion(id)
	end

	local other = self.inWarWith
	if other then
		other.inWarWith = nil
		self.inWarWith = nil

		if other == game.myCountry then
			uiLib.popup.showMessage('Война окончена', ('Государство %s, с которым мы воевали уничтожено! Война окончена.'):format(self:GetName()))
		end
	end

	country.removeCountry(self:GetID())

	if self == game.myCountry then
		gamecycle._blocked = true
		gamecycle.pause()

		gamecycle.event.ui.showWindow(reason, {
			{
				text = 'Наблюдать',
				callback = function()
					gamecycle._blocked = nil
					game.spectatorMode()
				end,
			},
			{
				text = 'Закончить игру',
				callback = function()
					game.endGame()
				end,
			},
		})
	end

	collectgarbage()
end

function Country:AddRegion(region)
	local id = region:GetID()
	if self.regions[id] then return end
	if region:GetCountry() then return end

	region:_SetCountry(self)
	self.regions[id] = region

	local provinces = region:GetProvinces()
	for id, province in pairs(provinces) do
		util.queuePrioritizedPreDrawMethodCall(province, 'CreateCanvas', 1)
	end

	util.queuePrioritizedPreDrawMethodCall(region, 'CreateCanvas', 2)
	util.queuePrioritizedPreDrawFunctionCall(map.createCanvas, 99)
end

function Country:RemoveRegion(id)
	local region = self.regions[id]
	if not region then return end

	region:_SetCountry()
	self.regions[id] = nil

	local provinces = region:GetProvinces()
	for id, province in pairs(provinces) do
		util.queuePrioritizedPreDrawMethodCall(province, 'CreateCanvas', 1)
	end

	if table.IsEmpty( self:GetRegions() ) then
		self:Destroy('Последний субъект государства был потерян. На этом история страны заканчивается...')
	end

	util.queuePrioritizedPreDrawMethodCall(region, 'CreateCanvas', 2)
	util.queuePrioritizedPreDrawFunctionCall(map.createCanvas, 99)
end

function Country:AddUnit(unit)
	self.units[#self.units + 1] = unit
end

function Country:RemoveUnit(unitOrID)
	local id = type(unitOrID) == 'string' and unitOrID or unitOrID:GetID()

	local i
	for k, v in ipairs(self:GetUnits()) do
		if id == v:GetID() then
			i = k
			break
		end
	end
	if not i then return end

	table.remove(self.units, i)
end

function Country:InWarWith(other)
	return self.inWarWith and self.inWarWith:GetID() == other:GetID()
end

function Country:MakePeaceOffer(target)
	if target == self then return end
	if not self:InWarWith(target) then return end

	local targetID = target:GetID()
	local cd = self.peaceOfferCooldownList[targetID]
	if cd then
		if cd > gamecycle._time then
			return notify.show('error', 2, 'Вы не можете предлагать мир этому государство еще ' .. cd - gamecycle._time .. ' д.')
		else
			self.peaceOfferCooldownList[targetID] = nil
		end
	end

	-- т.к. это бот просто делаем шанс
	if love.math.random() < 0.5 then
		game.myCountry.inWarWith = nil
		target.inWarWith = nil

		uiLib.popup.showMessage('Мир был принят!', ('%s принял наше предложение о мире с сохранением текущих границ'):format(target:GetName()))
	else
		uiLib.popup.showMessage('Мир был отвергнут!', ('%s отверг наше предложение о мире!'):format(target:GetName()))

		self.peaceOfferCooldownList[targetID] = gamecycle._time + 90 -- кд на 90 игровых дней
	end
end

-- Hooks

function Country:DrawName(offset)
	offset = offset or 0

	local minPos, maxPos = self:GetBounds()
	if not minPos then return end

	local imgData = map._img
	if not imgData then return end

	local provincesImgData = imgData.provinces
	local mapW, mapH = unpack(imgData.size)

	local ratio = ScrH() / mapH

	minPos, maxPos = minPos * ratio, maxPos * ratio
	local size = maxPos - minPos

	local text = self.text
	local tw, th = text:getWidth(), text:getHeight()
	local sx = (size.x * 0.7) / tw

	if camera._scale > math.max(1.25, 85 / (tw * sx)) then
		if not self.nameAlpha or self.nameAlpha > 0 then
			self.nameAlpha = Lerp(0.01, self.nameAlpha or 1, 0)

			if self.nameAlpha < 0.05 then
				self.nameAlpha = 0
			end
		end
	elseif self.nameAlpha then
		self.nameAlpha = Lerp(0.01, self.nameAlpha, 1)

		if self.nameAlpha > 0.95 then
			self.nameAlpha = nil
		end
	end

	local x, y = minPos.x + offset + (size.x / 2 - (tw * sx) / 2), minPos.y + (size.y / 2 - (th * sx) / 2)

	love.graphics.setColor(1, 1, 1, self.nameAlpha or 1)
	love.graphics.draw(text, x, y, 0, sx)
end

function Country:Draw()
	local regions = self:GetRegions()
	for id, region in pairs(regions) do
		region:Draw()
	end
end