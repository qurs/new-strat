units = units or {}
units.lastLandID = units.lastLandID or 0

function units.create(...)
	local id = units.lastLandID + 1

	local meta = setmetatable({}, units._landUnitMeta)
	meta:__init(id, ...)

	units.lastLandID = units.lastLandID + 1

	return meta
end

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

	local worldX, worldY = camera.screenToWorld(mx, my)

	local unitList = c:GetUnits()
	for _, unit in ipairs(unitList) do
		local pos = unit.worldPos
		if pos then
			local startX, startY, endX, endY = unpack(pos)
			if (worldX >= startX and worldX <= endX) and (worldY >= startY and worldY <= endY) then
				uiLib.sound.click(3)
				units._selectedUnits[unit] = true
				return
			end
		end
	end

	if table.IsEmpty(units._selectedUnits) then
		units._selectedUnits = nil
	end

	units._mouseDown = {worldX, worldY, mx, my}
end)

hook.Add('MouseUp', 'units', function(mx, my)
	if not units._mouseDown then return end

	local startX, startY = unpack(units._mouseDown)
	units._mouseDown = nil

	local worldX, worldY = camera.screenToWorld(mx, my)

	local minX, minY = math.min(worldX, startX), math.min(worldY, startY)
	local maxX, maxY = math.max(worldX, startX), math.max(worldY, startY)

	local c = game.myCountry
	if not c then return end

	units._selectedUnits = {}

	local unitList = c:GetUnits()

	local minPos, maxPos = Vector(minX, minY), Vector(maxX, maxY)
	local areaPoint1 = Vector(minX, minY)
	local areaPoint2 = Vector(maxX, minY)
	local areaPoint3 = Vector(maxX, maxY)
	local areaPoint4 = Vector(minX, maxY)

	for _, unit in ipairs(unitList) do
		local pos = unit.worldPos
		if pos then
			local startX, startY, endX, endY = unpack(pos)
			local startPos, endPos = Vector(startX, startY), Vector(endX, endY)
			local point1 = Vector(startX, startY)
			local point2 = Vector(endX, startY)
			local point3 = Vector(endX, endY)
			local point4 = Vector(startX, endY)

			local anyPointOfUnitInsideArea = point1:IsInsideSquare(minPos, maxPos)
				or point2:IsInsideSquare(minPos, maxPos)
				or point3:IsInsideSquare(minPos, maxPos)
				or point4:IsInsideSquare(minPos, maxPos)
			
			local anyPointOfAreaInsideUnit = areaPoint1:IsInsideSquare(startPos, endPos)
				or areaPoint2:IsInsideSquare(startPos, endPos)
				or areaPoint3:IsInsideSquare(startPos, endPos)
				or areaPoint4:IsInsideSquare(startPos, endPos)

			if anyPointOfUnitInsideArea or anyPointOfAreaInsideUnit then
				uiLib.sound.click(3)
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