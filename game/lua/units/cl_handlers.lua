units = units or {}
units.handler = units.handler or {}

function units.handler.provinceRightClick(prov)
	if not units._selectedUnits then return false end

	local provCountry = prov:GetCountry()
	if not provCountry then return false end

	local firstUnit = next(units._selectedUnits)
	local unitCountry = firstUnit:GetCountry()

	if provCountry == unitCountry or (provCountry:InWarWith(unitCountry) and not prov:HasAnyUnit()) then
		for unit in pairs(units._selectedUnits) do
			unit:Move(prov)
		end
	elseif provCountry:InWarWith(unitCountry) then
		local attackers = {}
		for unit in pairs(units._selectedUnits) do
			local unitProv = unit:GetProvince()
			if prov:HasNeighbor(unitProv) then
				attackers[#attackers + 1] = unit
			end
		end

		if #attackers > 0 then
			local fight = units.fight.getFight(prov)
			if fight then
				fight:AddAttackers(attackers)
				return true
			end

			local defenders = {}
			for id, unit in pairs(prov:GetUnits()) do
				defenders[#defenders + 1] = unit
			end

			units.fight.create(prov, attackers, defenders)
		end
	end

	return true
end