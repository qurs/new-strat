units = units or {}
units._fights = units._fights or {}

units.lastLandID = units.lastLandID or 0

function units.calculateCapabilityFine(attack, defence)
	if attack > defence then
		return 0, (attack - defence) / attack * 100
	elseif defence > attack then
		return (defence - attack) / defence * 100, 0
	else
		return 0, 0
	end
end

function units.calculateArmorFine(pierce, armor)
	if pierce > armor then
		return 0, -(pierce - armor) / pierce * 100
	elseif armor > pierce then
		return -(armor - pierce) / armor * 100, 0
	else
		return 0, 0
	end
end

function units.calculateCapabilityLost(attack, defence, pierce, armor)
	local attackFine, defenceFine = units.calculateArmorFine(pierce, armor)
	local newAttack, newDefence = attack * ( (100 + attackFine) / 100 ), defence * ( (100 + defenceFine) / 100 )

	local attackerCapFine, defenderCapFine = units.calculateCapabilityFine(newAttack, newDefence)
	return (-1 / 24) * ( (100 + attackerCapFine) / 100 ), (-1 / 24) * ( (100 + defenderCapFine) / 100 )
end

function units.fight(attackerTeam, defenderTeam, prov)
	for _, unit in ipairs(attackerTeam) do
		unit.targetAttack = prov
	end

	units._fights[#units._fights + 1] = {
		attackerTeam = attackerTeam,
		defenderTeam = defenderTeam,
		prov = prov,
	}
end

function units.getFightByProv(prov)
	for i, fight in ipairs(units._fights) do
		local fightProv = fight.prov
		if fightProv:GetID() == prov:GetID() then
			return fight, i
		end
	end
end

function units.create(...)
	local id = units.lastLandID + 1

	local meta = setmetatable({}, units._landUnitMeta)
	meta:__init(id, ...)

	units.lastLandID = units.lastLandID + 1

	return meta
end

hook.Add('Think', 'units', function(dt)
	for id, country in pairs(country._countries) do
		local units = country:GetUnits()
		for _, unit in ipairs(units) do
			unit:Think(dt)
		end
	end
end)

hook.Add('gamecycle.step', 'units', function(dt)
	local toRemove = {}

	for i, fight in ipairs(units._fights) do
		local prov = fight.prov

		local attackerStrength, defenderStrength = 0, 0
		local attackerPierce, defenderArmor = 0, 0

		for _, unit in ipairs(fight.defenderTeam) do
			if unit:GetState() ~= 'defending' then unit:SetState('defending') end

			defenderStrength = defenderStrength + unit:GetDefence()
			defenderArmor = defenderArmor + unit:GetArmor()
		end

		for _, unit in ipairs(fight.attackerTeam) do
			if unit:GetState() ~= 'attacking' then unit:SetState('attacking') end

			attackerStrength = attackerStrength + unit:GetAttack()
			attackerPierce = attackerPierce + unit:GetArmorPierce()
		end

		local attackerCapLost, defenderCapLost = units.calculateCapabilityLost(attackerStrength, defenderStrength, attackerPierce, defenderArmor)

		for _, unit in ipairs(fight.defenderTeam) do
			unit:AddCapability( defenderCapLost / #fight.defenderTeam )

			if unit:GetCapability() == 0 then
				local neighbors = prov:GetNeighbors()
	
				local neighbor
				for _, v in ipairs(neighbors) do
					if v:GetCountry() == prov:GetCountry() then
						neighbor = v
						break
					end
				end
	
				if neighbor then
					unit:Move( neighbors[math.random(#neighbors)] )
				else
					unit:Remove()
				end
	
				table.RemoveByValue(fight.defenderTeam, unit)

				if #fight.defenderTeam < 1 then
					for _, unit in ipairs(fight.attackerTeam) do
						unit:Move(prov)
					end

					hook.Run('units.wonFight', fight.attackerTeam, prov)
					toRemove[#toRemove + 1] = i

					break
				end
			end
		end

		for _, unit in ipairs(fight.attackerTeam) do
			unit:AddCapability( attackerCapLost / #fight.attackerTeam )

			if unit:GetCapability() == 0 then
				unit:Idle()
				table.RemoveByValue(fight.attackerTeam, unit)

				if #fight.attackerTeam < 1 then
					for _, unit in ipairs(fight.defenderTeam) do
						unit:Idle()
					end

					hook.Run('units.wonFight', fight.defenderTeam, prov)
					toRemove[#toRemove + 1] = i

					break
				end
			end
		end
	end

	for i = #toRemove, 1, -1 do
		table.remove(units._fights, toRemove[i])
	end

	for id, country in pairs(country._countries) do
		local units = country:GetUnits()
		for _, unit in ipairs(units) do
			unit:CycleStep(dt)
		end
	end
end)

hook.Add('units.movedToProvince', 'units', function(unit, prov)
	local fight = units.getFightByProv(prov)
	if not fight then return end

	fight.defenderTeam[#fight.defenderTeam + 1] = unit
end)

hook.Add('PreDrawOverCountry', 'units.fight', function()
	local r, g, b = love.math.colorFromBytes(207, 58, 58)
	local offsets = {map._centerX, map._minX, map._maxX}

	local imgData = map._img
	if not imgData then return end

	local mapW, mapH = unpack(imgData.size)
	local ratio = ScrH() / mapH

	local drawnProvs = {}

	for _, fight in ipairs(units._fights) do
		local prov = fight.prov

		local minPos, maxPos = prov:GetBounds()
		minPos, maxPos = minPos * ratio, maxPos * ratio

		local endPos = (minPos + maxPos) / 2

		for _, unit in ipairs(fight.attackerTeam) do
			local province = unit:GetProvince()
			local provID = province:GetID()

			if drawnProvs[provID] then goto continue end
			drawnProvs[provID] = true

			local minPos, maxPos = province:GetBounds()
			minPos, maxPos = minPos * ratio, maxPos * ratio

			local centerPos = (minPos + maxPos) / 2

			for _, offset in ipairs(offsets) do
				love.graphics.setLineWidth(2)
				love.graphics.setColor(0, 0, 0)
				love.graphics.line(offset + centerPos.x, centerPos.y, offset + endPos.x, endPos.y)

				love.graphics.setLineWidth(1)
				love.graphics.setColor(r, g, b)
				love.graphics.line(offset + centerPos.x, centerPos.y, offset + endPos.x, endPos.y)
			end

			::continue::
		end
	end
end)

hook.Add('MouseDown', 'units', function(mx, my, button)
	if button ~= 1 then return end
	if scene.getName() ~= 'map' then return end

	local c = game.myCountry
	if not c then return end

	units._selectedUnits = {}

	local imgX, imgY = map.screenToImage(mx, my)
	local scale = camera._scale or 1

	local unitList = c:GetUnits()
	for _, unit in ipairs(unitList) do
		local pos = unit.screenPos
		if pos then
			local startX, startY, endX, endY = unpack(pos)
			if (imgX >= startX and imgX <= endX) and (imgY >= startY and imgY <= endY) then
				units._selectedUnits[unit] = true
				return
			end
		end
	end

	if table.IsEmpty(units._selectedUnits) then
		units._selectedUnits = nil
	end

	units._mouseDown = {imgX, imgY, mx, my}
end)

hook.Add('MouseUp', 'units', function(mx, my)
	if not units._mouseDown then return end

	local startX, startY = unpack(units._mouseDown)
	units._mouseDown = nil

	local imgX, imgY = map.screenToImage(mx, my)

	local minX, minY = math.min(imgX, startX), math.min(imgY, startY)
	local maxX, maxY = math.max(imgX, startX), math.max(imgY, startY)

	local c = game.myCountry
	if not c then return end

	units._selectedUnits = {}

	local unitList = c:GetUnits()
	for _, unit in ipairs(unitList) do
		local pos = unit.screenPos
		if pos then
			local startX, startY, endX, endY = unpack(pos)
			if (startX >= minX and endX <= maxX) and (startY >= minY and endY <= maxY) then
				units._selectedUnits[unit] = true
			end
		end
	end

	if table.IsEmpty(units._selectedUnits) then
		units._selectedUnits = nil
	end
end)

hook.Add('DrawUI', 'units.mouseArea', function()
	if not units._mouseDown then return end

	local _, _, startX, startY = unpack(units._mouseDown)
	local x, y = love.mouse.getPosition()

	local minX, minY = math.min(x, startX), math.min(y, startY)
	local maxX, maxY = math.max(x, startX), math.max(y, startY)

	love.graphics.setColor(0.8, 0.8, 0.8)
	love.graphics.rectangle('line', minX, minY, maxX - minX, maxY - minY)
end)