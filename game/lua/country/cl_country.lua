country = country or {}
country._countries = country._countries or {}

function country.newCountry(id, ...)
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

function country.newRegion(id, ...)
	local meta = setmetatable({}, country._regionMeta)
	meta:__init(id, ...)

	return meta
end

function country.newProvince(id, ...)
	local meta = setmetatable({}, country._provinceMeta)
	meta:__init(id, ...)

	return meta
end