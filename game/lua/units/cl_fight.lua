units = units or {}
units.fight = units.fight or {}

units.fight._map = units.fight._map or {}

function units.fight.calculateCapabilityFine(attack, defence)
	if attack > defence then
		return 0, (attack - defence) / attack * 100
	elseif defence > attack then
		return (defence - attack) / defence * 100, 0
	else
		return 0, 0
	end
end

function units.fight.calculateArmorFine(pierce, armor)
	if pierce > armor then
		return 0, -(pierce - armor) / pierce * 100
	elseif armor > pierce then
		return -(armor - pierce) / armor * 100, 0
	else
		return 0, 0
	end
end

function units.calculateCapabilityLost(attack, defence, pierce, armor)
	local attackFine, defenceFine = units.fight.calculateArmorFine(pierce, armor)
	local newAttack, newDefence = attack * ( (100 + attackFine) / 100 ), defence * ( (100 + defenceFine) / 100 )

	local attackerCapFine, defenderCapFine = units.fight.calculateCapabilityFine(newAttack, newDefence)
	return (-1 / 24) * ( (100 + attackerCapFine) / 100 ), (-1 / 24) * ( (100 + defenderCapFine) / 100 )
end

function units.fight.create(...)
	local meta = setmetatable({}, units.fight._meta)
	meta:__init(...)

	units.fight._map[meta:GetID()] = meta

	return meta
end

function units.fight.remove(fightOrID)
	local id = (type(fightOrID) == 'fight' and fightOrID:GetID()) or fightOrID
	units.fight._map[id] = nil
end

function units.fight.getFight(provOrID)
	local id = (type(provOrID) == 'province' and provOrID:GetID()) or provOrID
	return units.fight._map[id]
end

hook.Add('gamecycle.step', 'units.fight', function()
	for id, fight in pairs(units.fight._map) do
		fight:CycleStep()
	end
end)

hook.Add('units.movedToProvince', 'units', function(unit, prov)
	local fight = units.fight.getFight(prov)
	if not fight then return end

	fight:AddDefender(unit)
end)

hook.Add('PreDrawOverCountry', 'units.fight', function()
	local imgData = map._img
	if not imgData then return end

	local mapW, mapH = unpack(imgData.size)
	local ratio = ScrH() / mapH

	local drawnProvs = {}
	for id, fight in pairs(units.fight._map) do
		fight:Draw(ratio, drawnProvs)
	end
end)

hook.Add('PostDrawOverCountry', 'units.fight', function()
	local imgData = map._img
	if not imgData then return end

	local mapW, mapH = unpack(imgData.size)
	local ratio = ScrH() / mapH

	for id, fight in pairs(units.fight._map) do
		fight:PostDraw(ratio)
	end
end)