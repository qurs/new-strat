hook.Add('AssetsLoaded', 'country.actionList', function()
	-- Regions

	country.actions.addRegionAction('Выделить регион', function(region)
		if region:GetProvinceCount() < 2 then return notify.show('error', 3, 'В регионе должно быть больше 1-й провинции, чтобы выделить еще один регион!') end

		map._selectedProvince = nil

		gamecycle._blocked = true
		gamecycle.pause()

		regionEditor._editing = region
		regionEditor._selectedProvinces = {}
	end)

	country.actions.addRegionAction('Мобилизация войск', function(region)
		if region:GetPopulation() < 50 then return notify.show('error', 2, 'Для мобилизации войск нужно хотя бы 50 населения в регионе!') end

		local prov = region:GetProvinces()[ region:GetCapitalProvince() ]
		local c = region:GetCountry()

		region:AddPopulation(-50)
		units.create(c, prov, 0.5, 10, 1, 1.5, 0, 0)
	end)

	-- Countries

	country.actions.addCountryAction('Объявить войну', function(target)
		if target == game.myCountry then return end
		if game.myCountry:InWarWith(target) then return end

		country.declareWar(game.myCountry, target)
	end)

	country.actions.addCountryAction('Предложить перемирие', function(target)
		if target == game.myCountry then return end
		if not game.myCountry:InWarWith(target) then return end
	end)
end)