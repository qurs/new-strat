units = units or {}
units.fight = units.fight or {}
units.fight._meta = units.fight._meta or {}

local Fight = units.fight._meta

Fight.__type = 'fight'
Fight.__index = Fight

function Fight:__init(province, attackers, defenders)
	self.id = province:GetID()

	self.startTime = gamecycle._time
	self.balance = 0

	self.province = province
	self.attackers = attackers or {}
	self.defenders = defenders or {}

	self.attackersIndicators = {strength = 0, pierce = 0}
	self.defendersIndicators = {strength = 0, armor = 0}

	if attackers then
		local indicators = self.attackersIndicators
		for _, unit in ipairs(attackers) do
			indicators.strength = indicators.strength + unit:GetAttack()
			indicators.pierce = indicators.pierce + unit:GetArmorPierce()

			unit:SetState('attacking')
			unit.fight = self
		end
	end

	if defenders then
		local indicators = self.defendersIndicators
		for _, unit in ipairs(defenders) do
			indicators.strength = indicators.strength + unit:GetDefence()
			indicators.armor = indicators.armor + unit:GetArmor()

			unit:SetState('defending')
			unit.fight = self
		end
	end
end

function Fight:__tostring()
	return ('Fight[%s]'):format(self:GetID())
end

-- GETTERS

function Fight:GetID()
	return self.id
end

function Fight:GetStartTime()
	return self.startTime
end

function Fight:GetBalance()
	return self.balance
end

function Fight:GetProvince()
	return self.province
end

function Fight:GetAttackers()
	return self.attackers
end

function Fight:GetDefenders()
	return self.defenders
end

function Fight:GetAttackerIndicators()
	return self.attackersIndicators
end

function Fight:GetDefenderIndicators()
	return self.defendersIndicators
end

-- SETTERS

function Fight:SetAttackerIndicators(indicators)
	self.attackersIndicators = indicators
end

function Fight:SetDefenderIndicators(indicators)
	self.defendersIndicators = indicators
end

function Fight:SetAttackers(attackers)
	self.attackers = attackers
end

function Fight:SetDefenders(defenders)
	self.defenders = defenders
end

-- OTHER

function Fight:End(attackersWin)
	hook.Run('units.wonFight', self, attackersWin)

	units.fight.remove(self)

	if attackersWin then
		for _, unit in ipairs(self:GetAttackers()) do
			unit:Move(self:GetProvince())
			unit.fight = nil
		end
	else
		for _, unit in ipairs(self:GetDefenders()) do
			unit:Idle()
			unit.fight = nil
		end
	end
end

function Fight:GetAge()
	return gamecycle._time - self.startTime
end

function Fight:GetAttackerStrength()
	local indicators = self:GetAttackerIndicators()
	return indicators.strength
end

function Fight:GetAttackerPierce()
	local indicators = self:GetAttackerIndicators()
	return indicators.pierce
end

function Fight:GetDefenderStrength()
	local indicators = self:GetDefenderIndicators()
	return indicators.strength
end

function Fight:GetDefenderArmor()
	local indicators = self:GetDefenderIndicators()
	return indicators.armor
end

function Fight:AddAttacker(attacker)
	if table.HasValue(self.attackers, attacker) then return end
	self.attackers[#self.attackers + 1] = attacker

	local indicators = self:GetAttackerIndicators()
	indicators.strength = indicators.strength + attacker:GetAttack()
	indicators.pierce = indicators.pierce + attacker:GetArmorPierce()

	attacker:SetState('attacking')
	attacker.fight = self
end

function Fight:AddAttackers(attackers)
	for _, attacker in ipairs(attackers) do
		self:AddAttacker(attacker)
	end
end

function Fight:RemoveAttacker(attacker)
	if table.RemoveByValue(self.attackers, attacker) then
		local indicators = self:GetAttackerIndicators()
		indicators.strength = indicators.strength - attacker:GetAttack()
		indicators.pierce = indicators.pierce - attacker:GetArmorPierce()

		attacker.fight = nil

		if #self.attackers < 1 then
			return self:End(false)
		end
	end
end

function Fight:RemoveAttackerByIndex(index)
	if not self.attackers[index] then return end

	local attacker = table.remove(self.attackers, index)
	local indicators = self:GetAttackerIndicators()
	indicators.strength = indicators.strength - attacker:GetAttack()
	indicators.pierce = indicators.pierce - attacker:GetArmorPierce()

	attacker.fight = nil

	if #self.attackers < 1 then
		return self:End(false)
	end
end

function Fight:RemoveAttackers(attackers)
	for _, attacker in ipairs(attackers) do
		self:RemoveAttacker(attacker)
	end
end

function Fight:AddDefender(defender)
	if table.HasValue(self.defenders, defender) then return end
	self.defenders[#self.defenders + 1] = defender

	local indicators = self:GetDefenderIndicators()
	indicators.strength = indicators.strength + defender:GetDefence()
	indicators.armor = indicators.armor + defender:GetArmor()

	defender:SetState('defending')
	defender.fight = self
end

function Fight:AddDefenders(defenders)
	for _, defender in ipairs(defenders) do
		self:AddDefender(defender)
	end
end

function Fight:RemoveDefender(defender)
	if table.RemoveByValue(self.defenders, defender) then
		local indicators = self:GetDefenderIndicators()
		indicators.strength = indicators.strength - defender:GetDefence()
		indicators.armor = indicators.armor - defender:GetArmor()

		defender.fight = nil

		if #self.defenders < 1 then
			return self:End(true)
		end
	end
end

function Fight:RemoveDefenderByIndex(index)
	if not self.defenders[index] then return end

	local defender = table.remove(self.defenders, index)
	local indicators = self:GetDefenderIndicators()
	indicators.strength = indicators.strength - defender:GetDefence()
	indicators.armor = indicators.armor - defender:GetArmor()

	defender.fight = nil

	if #self.defenders < 1 then
		return self:End(true)
	end
end

function Fight:RemoveDefenders(defenders)
	for _, defender in ipairs(defenders) do
		self:RemoveDefender(defender)
	end
end

-- Hooks

function Fight:CycleStep()
	local attackerStrength, defenderStrength = self:GetAttackerStrength(), self:GetDefenderStrength()
	local attackerPierce, defenderArmor = self:GetAttackerPierce(), self:GetDefenderArmor()

	local attackerCapLost, defenderCapLost = units.calculateCapabilityLost(attackerStrength, defenderStrength, attackerPierce, defenderArmor)

	local attackerCap, defenderCap = 0, 0

	local defenders = self:GetDefenders()
	local toRemove = {}

	for k, unit in ipairs(defenders) do
		local count = #defenders - #toRemove
		unit:AddCapability(defenderCapLost / count)

		local cap = unit:GetCapability()
		if cap == 0 then
			unit:Retreat()
			toRemove[#toRemove + 1] = k
			count = #defenders - #toRemove

			if count < 1 then
				return self:End(true)
			end
		else
			defenderCap = defenderCap + cap
		end
	end
	for i = #toRemove, 1, -1 do
		self:RemoveDefenderByIndex(toRemove[i])
	end

	local attackers = self:GetAttackers()
	toRemove = {}

	for k, unit in ipairs(attackers) do
		local count = #attackers - #toRemove
		unit:AddCapability(attackerCapLost / count)

		local cap = unit:GetCapability()
		if cap == 0 then
			unit:Idle()
			toRemove[#toRemove + 1] = k
			count = #defenders - #toRemove

			if count < 1 then
				return self:End(false)
			end
		else
			attackerCap = attackerCap + cap
		end
	end
	for i = #toRemove, 1, -1 do
		self:RemoveAttackerByIndex(toRemove[i])
	end

	local capSum = attackerCap + defenderCap
	local attackerCapFrac, defenderCapFrac = attackerCap / capSum, defenderCap / capSum
	self.balance = defenderCapFrac - attackerCapFrac
end

function Fight:Draw(ratio, drawnProvs)
	local offsets = {map._centerX, map._minX, map._maxX}
	local prov = self:GetProvince()

	local minPos, maxPos = prov:GetBounds()
	minPos, maxPos = minPos * ratio, maxPos * ratio

	local endPos = (minPos + maxPos) / 2

	for _, unit in ipairs(self:GetAttackers()) do
		local unitProv = unit:GetProvince()
		local provID = unitProv:GetID()

		if drawnProvs[provID] then goto continue end
		drawnProvs[provID] = true

		local minPos, maxPos = unitProv:GetBounds()
		minPos, maxPos = minPos * ratio, maxPos * ratio

		local centerPos = (minPos + maxPos) / 2

		for _, offset in ipairs(offsets) do
			love.graphics.setLineWidth(2)
			love.graphics.setColor(0, 0, 0)
			love.graphics.line(offset + centerPos.x, centerPos.y, offset + endPos.x, endPos.y)

			love.graphics.setLineWidth(1)
			love.graphics.setColor(0.81, 0.23, 0.23)
			love.graphics.line(offset + centerPos.x, centerPos.y, offset + endPos.x, endPos.y)
		end

		::continue::
	end
end

function Fight:PostDraw(ratio)
	local prov = self:GetProvince()

	local minPos, maxPos = prov:GetBounds()
	minPos, maxPos = minPos * ratio, maxPos * ratio

	local provCenterPos = (minPos + maxPos) / 2

	local offsets = {map._centerX, map._minX, map._maxX}
	for _, offset in ipairs(offsets) do
		-- balance line
		local startX = offset + provCenterPos.x - 15
		local endX = offset + provCenterPos.x + 15

		love.graphics.setLineWidth(2)
		love.graphics.setColor(0, 0, 0)
		love.graphics.line(startX, provCenterPos.y, endX, provCenterPos.y)

		love.graphics.setLineWidth(1)
		love.graphics.setColor(0.26, 0.64, 1)
		love.graphics.line(startX, provCenterPos.y, endX, provCenterPos.y)

		local frac = math.Remap(self.balance, -1, 1, 1, 0)

		love.graphics.setLineWidth(1)
		love.graphics.setColor(0.81, 0.17, 0.1)
		love.graphics.line(startX, provCenterPos.y, startX + (frac * 30), provCenterPos.y)
	end
end