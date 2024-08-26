units = units or {}

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

function units.create(...)
	local id = units.lastLandID + 1

	local meta = setmetatable({}, units._landUnitMeta)
	meta:__init(id, ...)

	units.lastLandID = units.lastLandID + 1

	return meta
end

hook.Add('GameStarted', 'test', function()
	local c = country.get(1)
	local r = c:GetRegions()[1]
	local p = r:GetProvinces()[ r:GetCapitalProvince() ]

	local unit1 = units.create(c, p, 1, 10, 1.5, 1, 0, 0)

	do
		local c = country.newCountry('Test 2', {0, 1, 0})
		local r = country.newRegion('Мордор', 'Мордор')
		local p = p:GetNeighbors()[math.random(#p:GetNeighbors())]
		r:AddProvince(p)

		c:AddRegion(r)

		local unit2 = units.create(c, p, 1, 10, 1.5, 1, 0, 0)

		unit1:Fight(unit2)
	end
end)

hook.Add('Think', 'units', function(dt)
	for id, country in pairs(country._countries) do
		local units = country:GetUnits()
		for _, unit in ipairs(units) do
			unit:Think(dt)
		end
	end
end)

hook.Add('gamecycle.step', 'units', function(dt)
	for id, country in pairs(country._countries) do
		local units = country:GetUnits()
		for _, unit in ipairs(units) do
			unit:CycleStep(dt)
		end
	end
end)