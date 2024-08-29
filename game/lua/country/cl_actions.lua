country = country or {}
country.actions = country.actions or {}

country.actions.list = country.actions.list or {}
country.actions.list.region = country.actions.list.region or {}
country.actions.list.country = country.actions.list.country or {}

function country.actions.addRegionAction(name, callback)
	table.insert(country.actions.list.region, {
		name = name,
		callback = callback,
	})
end

function country.actions.addCountryAction(name, callback)
	table.insert(country.actions.list.country, {
		name = name,
		callback = callback,
	})
end