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
	startProvince:AddUnit(self)

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

function Unit:GetState()
	return self.state
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
	local oldProv = self.province
	if oldProv then
		oldProv:RemoveUnit(self)
	end

	local c = self:GetCountry()
	if c:InWarWith(province:GetCountry()) then
		province:ChangeRegion( c:GetCapitalRegion() )
	end

	self.province = province
	province:AddUnit(self)
end

function Unit:SetState(state)
	local old = self:GetState()
	if old == state then return end

	self:OnChangeState(old, new)
	self.state = state
end

-- OTHER

function Unit:AddCapability(add)
	self:SetCapability( self:GetCapability() + add )
end

function Unit:Move(province)
	if self:GetState() == 'moving' and self:GetCapability() < 1 then
		return
	end

	local provCountry = province:GetCountry()
	if provCountry ~= self:GetCountry() and province:HasAnyUnit() then return end -- Добавить потом проверку на наличие войны между государствами

	local curProvince = self:GetProvince()
	if not curProvince:HasNeighbor(province) then return end

	if self:GetState() == 'attacking' and self.targetAttack and self.targetAttack ~= province then
		local prov = self.targetAttack
		local fight, i = units.getFightByProv(prov)
		if fight then
			table.RemoveByValue(fight.attackerTeam, self)

			if #fight.attackerTeam < 1 then
				for _, unit in ipairs(fight.defenderTeam) do
					unit:Idle()
				end

				hook.Run('units.wonFight', fight.defenderTeam, prov)
				table.remove(units._fights, i)
			end
		end
	elseif self:GetState() == 'defending' then
		local prov = self:GetProvince()
		local fight, i = units.getFightByProv(prov)
		if fight then
			table.RemoveByValue(fight.derenderTeam, unit)

			if #fight.derenderTeam < 1 then
				for _, unit in ipairs(fight.attackerTeam) do
					unit:Move(prov)
				end

				hook.Run('units.wonFight', fight.defenderTeam, prov)
				table.remove(units._fights, i)
			end
		end
	end

	self.movingEndTime = gamecycle._time + ( (1 / self:GetSpeed()) * 24 )
	self.moveTarget = province
	self:SetState('moving')
end

function Unit:Idle()
	if self:GetState() == 'idle' then return end
	self:SetState('idle')
end

function Unit:Remove()
	self:GetCountry():RemoveUnit(self)
	self:GetProvince():RemoveUnit(self)
end

-- Hooks

function Unit:OnChangeState(old, new)
	if old == 'attacking' then
		self.targetAttack = nil
	end

	if old == 'moving' then
		self.movingEndTime = nil
		self.moveTarget = nil
	end
end

function Unit:Think(dt)
end

function Unit:CycleStep()
	if self:GetState() == 'moving' then
		self:AddCapability( (1 / 24) * (self:GetCapability() * (-0.05)) )

		if gamecycle._time >= self.movingEndTime then
			self:SetProvince(self.moveTarget)
			hook.Run('units.movedToProvince', self, self.moveTarget)

			self:Idle()
		end

		return
	end

	if self:GetState() == 'idle' then
		self:AddCapability(1 / 24)
		return
	end
end

function Unit:Draw(i, offset)
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

	if self:GetState() == 'moving' then
		local r, g, b = 1, 1, 1

		local target = self.moveTarget

		local minPos, maxPos = target:GetBounds()
		minPos, maxPos = minPos * ratio, maxPos * ratio

		local endPos = (minPos + maxPos) / 2

		local outlineColor = {0, 0, 0}
		if self:GetState() == 'attacking' then
			outlineColor = {0.3, 0, 0}
		elseif self:GetState() == 'defending' then
			outlineColor = {0, 0, 0.3}
		end

		love.graphics.setLineWidth(2)
		love.graphics.setColor(unpack(outlineColor))
		love.graphics.line(offset + centerPos.x, centerPos.y, offset + endPos.x, endPos.y)

		love.graphics.setLineWidth(1)
		love.graphics.setColor(r, g, b)
		love.graphics.line(offset + centerPos.x, centerPos.y, offset + endPos.x, endPos.y)
	end

	love.graphics.push()
		love.graphics.translate(cx, cy)
		love.graphics.scale(1 / scale)
		love.graphics.translate(-cx * scale, -cy * scale)

		local centerX, centerY = centerPos.x * scale, centerPos.y * scale
		offset = offset * scale

		local x, y = centerX - w / 2, centerY - h / 2

		local unitCount = province.unitsCount
		if unitCount > 1 then
			local totalH = unitCount * h + ( (unitCount - 1) * 5 )
			y = centerY - totalH / 2

			y = y + (i - 1) * h

			if i > 1 then
				y = y + (5 * (i - 1))
			end
		end

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