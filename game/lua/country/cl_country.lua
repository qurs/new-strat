country = country or {}
country._countries = country._countries or {}
country._regions = country._regions or {}
country._provinces = country._provinces or {}

country.lastRegionID = country.lastRegionID or 0
country.lastCountryID = country.lastCountryID or 0

function country.newCountry(...)
	local id = country.lastCountryID + 1

	local meta = setmetatable({}, country._countryMeta)
	meta:__init(id, ...)

	country._countries[id] = meta

	country.lastCountryID = country.lastCountryID + 1

	return meta
end

function country.removeCountry(id)
	country._countries[id] = nil
end

function country.get(id)
	return country._countries[id]
end

function country.getRegion(id)
	return country._regions[id]
end

function country.getProvince(id)
	return country._provinces[id]
end

function country.newRegion(...)
	local id = country.lastRegionID + 1

	local meta = setmetatable({}, country._regionMeta)
	meta:__init(id, ...)

	country._regions[id] = meta
	country.lastRegionID = id

	return meta
end

function country.newProvince(id, ...)
	local meta = setmetatable({}, country._provinceMeta)
	meta:__init(id, ...)

	country._provinces[id] = meta

	return meta
end

function country.declareWar(attacker, defender)
	attacker.inWarWith = defender
	defender.inWarWith = attacker

	attacker:AddStability(-15)
	defender:AddStability(-10)

	uiLib.popup.showMessage('Объявление войны', ('%s объявил войну %s!'):format(attacker:GetName(), defender:GetName()))
end