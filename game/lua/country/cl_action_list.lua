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

		uiLib.popup.query('Предложение мира', {
			{
				type = 'combo',
				tooltip = 'Предложение',
				items = {
					'Статус-кво',
					'Текущие границы',
				},
				entry = {value = 1},
			},
		},
		function(widgets)
			local val = widgets[1].entry.value
			if val == 2 then
				-- потом сделать предложение
				game.myCountry.inWarWith = nil
				target.inWarWith = nil

				uiLib.popup.showMessage('Перемирие', ('%s принял наше предложение о перемирии с сохранением текущих границ'):format(target:GetName()))
			end
		end)
	end)
end)

hook.Add('GameStarted', 'asdas', function()
	local myCountry = game.myCountry
	local _, reg = next( myCountry:GetRegions() )
	local _, province = next( reg:GetProvinces() )
	local neighbor = province:GetNeighbors()[math.random(#province:GetNeighbors())]

	local reg = country.newRegion('Мордор', 'Мордор')
	reg:AddProvince(neighbor)

	local c = country.newCountry('Узбекистан', {0, 1, 0}, reg)
	c:AddRegion(reg)

	units.create(c, neighbor, 0.5, 5, 1, 5, 0, 0)
end)