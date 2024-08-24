country = country or {}
country.actions = country.actions or {}

country.actions.list = country.actions.list or {}

function country.actions.addRegionAction(name, callback)
	table.insert(country.actions.list, {
		name = name,
		callback = callback,
	})
end