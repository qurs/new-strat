units = units or {}
units.handler = units.handler or {}

function units.handler.provinceRightClick(prov)
	if not units._selectedUnits then return false end

	local myCountry = prov:GetCountry()
	if not myCountry then return false end

	local firstUnit = next(units._selectedUnits)
	local targetCountry = firstUnit:GetCountry()

	if myCountry == targetCountry or (myCountry:InWarWith(targetCountry) and not prov:HasAnyUnit()) then
		for unit in pairs(units._selectedUnits) do
			unit:Move(prov)
		end
	elseif myCountry:InWarWith(targetCountry) then
		local fight = units.getFightByProv(prov)
		if fight then
			for unit in pairs(units._selectedUnits) do
				local curProvince = unit:GetProvince()
				if curProvince:HasNeighbor(prov) then
					unit.targetAttack = prov
					fight.attackerTeam[#fight.attackerTeam + 1] = unit
				end
			end

			return true
		end

		local unitList = {}
		for id, unit in pairs(prov:GetUnits()) do
			unitList[#unitList + 1] = unit
		end

		local attackList = {}
		for unit in pairs(units._selectedUnits) do
			local curProvince = unit:GetProvince()
			if curProvince:HasNeighbor(prov) then
				attackList[#attackList + 1] = unit
			end
		end

		units.fight(attackList, unitList, prov)
	end

	return true
end