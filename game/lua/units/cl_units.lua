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

		-- unit1:Fight(unit2)
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