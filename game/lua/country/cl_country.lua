country = country or {}
country._countries = country._countries or {}

country.lastRegionID = country.lastRegionID or 0
country.lastCountryID = country.lastCountryID or 0

function country.newCountry(...)
	local id = country.lastCountryID + 1

	local meta = setmetatable({}, country._countryMeta)
	meta:__init(id, ...)

	country._countries[id] = meta
	return meta
end

function country.removeCountry(id)
	country._countries[id] = nil
end

function country.get(id)
	return country._countries[id]
end

function country.newRegion(...)
	local meta = setmetatable({}, country._regionMeta)
	meta:__init(country.lastRegionID + 1, ...)

	return meta
end

function country.newProvince(id, ...)
	local meta = setmetatable({}, country._provinceMeta)
	meta:__init(id, ...)

	return meta
end