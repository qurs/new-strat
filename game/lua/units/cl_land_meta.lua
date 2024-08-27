gui.registerFont('units', {
	font = 'Montserrat-Medium',
	size = 24,
})

units = units or {}
units._landUnitMeta = units._landUnitMeta or {}

local Unit = units._landUnitMeta

Unit.__type = 'unit'
Unit.__index = Unit

function Unit:__init(id, country, startProvince, speed, capability, attack, defence, armor, armorPierce)
	self.id = id
	self.country = country
	self.speed = math.min(speed, 24)
	self.capability = capability
	self.maxCapability = capability
	self.attack = attack
	self.defence = defence
	self.armor = armor
	self.armorPierce = armorPierce

	self.province = startProvince

	self.state = 'idle'
	self.text = love.graphics.newText(gui.getFont('units'), self.capability)

	country:AddUnit(self)

	--[[ OPTIONAL FIELDS

	]]
end

function Unit:__tostring()
	return ('Unit[%s][ %s ]'):format(self:GetID(), self:GetCountry())
end

-- GETTERS

function Unit:GetID()
	return self.id
end

function Unit:GetCountry()
	return self.country
end

function Unit:GetSpeed()
	return self.speed
end

function Unit:GetCapability()
	return self.capability
end

function Unit:GetMaxCapability()
	return self.maxCapability
end

function Unit:GetAttack()
	return self.attack
end

function Unit:GetDefence()
	return self.defence
end

function Unit:GetArmor()
	return self.armor
end

function Unit:GetArmorPierce()
	return self.armorPierce
end

function Unit:GetProvince()
	return self.province
end

-- SETTERS

function Unit:SetCountry(country)
	self.country = country
end

function Unit:SetSpeed(speed)
	self.speed = math.min(speed, 24)
end

function Unit:SetCapability(capability)
	self.capability = math.Clamp(capability, 0, self:GetMaxCapability())
end

function Unit:SetAttack(attack)
	self.attack = attack
end

function Unit:SetDefence(defence)
	self.defence = defence
end

function Unit:SetArmor(armor)
	self.armor = armor
end

function Unit:SetArmorPierce(armorPierce)
	self.armorPierce = armorPierce
end

function Unit:SetProvince(province)
	self.province = province
end

-- OTHER

function Unit:AddCapability(add)
	self:SetCapability( self:GetCapability() + add )
end

function Unit:CalculateCapabilityLost(otherUnit)
	local attackFine, defenceFine = units.calculateArmorFine(self:GetArmorPierce(), otherUnit:GetArmor())
	local newAttack, newDefence = self:GetAttack() * ( (100 + attackFine) / 100 ), otherUnit:GetDefence() * ( (100 + defenceFine) / 100 )

	local attackerCapFine, defenderCapFine = units.calculateCapabilityFine(newAttack, newDefence)
	return (-1 / 24) * ( (100 + attackerCapFine) / 100 ), (-1 / 24) * ( (100 + defenderCapFine) / 100 )
end

function Unit:Move(province)
	if province:GetCountry() ~= self:GetCountry() then return end

	local curProvince = self:GetProvince()
	if not curProvince:HasNeighbor(province) then return end

	self.movingEndTime = gamecycle._time + ( (1 / self:GetSpeed()) * 24 )
	self.moveTarget = province
	self.state = 'moving'
end

function Unit:Fight(otherUnit)
	if self.state == 'defending' then return end
	if self:GetCapability() == 0 then return end

	self.attackTarget = otherUnit
	self.fightStartTime = gamecycle._time

	self.state = 'attacking'
end

function Unit:Idle()
	if self.state == 'idle' then return end
	self.state = 'idle'

	self.attackTarget = nil
	self.fightStartTime = nil

	self.movingEndTime = nil
	self.moveTarget = nil
end

-- Hooks

function Unit:Think(dt)
end

function Unit:CycleStep()
	if self.state == 'moving' then
		if gamecycle._time >= self.movingEndTime then
			self:SetProvince(self.moveTarget)
			self:Idle()
		end

		return
	end

	if self.state == 'attacking' then
		local target = self.attackTarget

		if target.state ~= 'defending' then
			target.state = 'defending'
		end

		local attackerCapLost, defenderCapLost = self:CalculateCapabilityLost(target)

		self:AddCapability(attackerCapLost)
		target:AddCapability(defenderCapLost)

		if self:GetCapability() == 0 then
			-- позже надо сделать отступление
			self:Idle()
			target:Idle()

			hook.Run('units.wonFight', target, self)
			return
		end

		if target:GetCapability() == 0 then
			-- позже надо сделать отступление
			self:Idle()
			target:Idle()

			hook.Run('units.wonFight', self, target)
			return
		end

		return
	end

	if self.state == 'idle' then
		self:AddCapability(1 / 24)
		return
	end
end

function Unit:Draw(offset)
	if camera._scale < 2 then return end

	local province = self:GetProvince()

	local text = self.text
	if not text then return end

	local imgData = map._img
	if not imgData then return end

	local mapW, mapH = unpack(imgData.size)
	local ratio = ScrH() / mapH

	local minPos, maxPos = province:GetBounds()
	minPos, maxPos = minPos * ratio, maxPos * ratio

	local centerPos = (minPos + maxPos) / 2

	local sx = 0.5
	local tw, th = text:getWidth() * sx, text:getHeight() * sx

	local w, h = math.max(tw + 10, 64), 18

	text:set(math.floor(self.capability))

	local cx, cy = camera._pos:Unpack()
	local scale = camera._scale or 1

	if self.state == 'moving' then
		local target = self.moveTarget

		local minPos, maxPos = target:GetBounds()
		minPos, maxPos = minPos * ratio, maxPos * ratio

		local endPos = (minPos + maxPos) / 2

		love.graphics.setLineWidth(1)
		love.graphics.setColor(1, 1, 1)
		love.graphics.line(offset + centerPos.x, centerPos.y, offset + endPos.x, endPos.y)
	end

	love.graphics.push()
		love.graphics.translate(cx, cy)
		love.graphics.scale(1 / scale)
		love.graphics.translate(-cx * scale, -cy * scale)

		local centerX, centerY = centerPos.x * scale, centerPos.y * scale
		offset = offset * scale

		local x, y = centerX - w / 2, centerY - h / 2

		local screenX, screenY = offset + x + ScrW() / 2 - cx * scale, y + ScrH() / 2 - cy * scale
		local startX, startY = map.screenToImage(screenX, screenY)
		local endX, endY = map.screenToImage(screenX + w, screenY + h)

		self.screenPos = {startX, startY, endX, endY}

		if units._selectedUnits and units._selectedUnits[self] then
			love.graphics.setColor(0.6, 0.6, 0.6)
			love.graphics.rectangle('fill', offset + x - 2, y - 2, w + 4, h + 4)
		end

		love.graphics.setColor(0.25, 0.25, 0.25)
		love.graphics.rectangle('fill', offset + x, y, w, h)

		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(text, offset + x + (w / 2 - tw / 2), y + (h / 2 - th / 2), 0, sx)
	love.graphics.pop()
end