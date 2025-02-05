country = country or {}
country.actions = country.actions or {}

function country.actions._createRegionPopup(callback)
	uiLib.popup.query('Создание региона', nil, {
		{
			type = 'edit',
			tooltip = 'Название региона',
			maxLength = 32,
			entry = ffi.new('char[32]'),
		},
		{
			type = 'edit',
			tooltip = 'Название столицы',
			maxLength = 32,
			entry = ffi.new('char[32]'),
		},
	}, callback)
end

hook.Add('AssetsLoaded', 'country.actionList', function()
	-- Regions

	country.actions.addRegionAction('Выделить регион', function(region)
		if region:GetProvinceCount() < 2 then return notify.show('error', 3, 'В регионе должно быть больше 1-й провинции, чтобы выделить еще один регион!') end

		mapEditor.open(
			{
				select2 = true,
				selectTarget = 'province',
				selectTargets = table.GetKeys(region:GetProvinces()),

				renderTargets = {region:GetID()},

				hint = 'Выберите провинции для нового региона\nЛКМ - выделить/снять выделение ПКМ - выбрать столицу',

				proccessProvince = function(regID, reg, id, prov)
					if region:GetCapitalProvince() == id then
						return {0.2, 0.2, 0.2}
					end
				end,

				filter = function(editor)
					if table.IsEmpty(editor._selected) then
						return false, 'Нужно выбрать провинции!'
					end

					if not editor._selected2 then
						return false, 'Нужно выбрать столицу!'
					end

					return true
				end,
			},
			function(editor)
				country.actions._createRegionPopup(function(widgets)
					local regionName, capitalName = ffi.string(widgets[1].entry), ffi.string(widgets[2].entry)
					if utf8.len(regionName) < 3 or utf8.len(regionName) > 32 then
						return notify.show('error', 2.5, 'Название региона должно быть не короче 3-х и не длиннее 32-х символов!')
					end
					if utf8.len(capitalName) < 3 or utf8.len(capitalName) > 32 then
						return notify.show('error', 2.5, 'Название столицы должно быть не короче 3-х и не длиннее 32-х символов!')
					end
			
					local c = region:GetCountry()
			
					region:RemoveProvinces(table.GetKeys(editor._selected))
			
					local population = math.floor(region:GetPopulation() / 2)
					region:AddPopulation(-population)
			
					local newRegion = country.newRegion(regionName, capitalName, editor._selected)
					newRegion:SetCapitalProvince(editor._selected2)
					newRegion:SetPopulation(population)
			
					c:AddRegion(newRegion)
			
					mapEditor.close()
				end)
			end
		)
	end)

	country.actions.addRegionAction('Расширить', function(region)
		local targets = {}

		for id, reg in pairs(region:GetCountry():GetRegions()) do
			if id == region:GetID() then goto continue end

			for provID, prov in pairs(reg:GetProvinces()) do
				if provID ~= reg:GetCapitalProvince() then
					targets[#targets + 1] = provID
				end
			end

			::continue::
		end

		mapEditor.open({
			selectTarget = 'province',
			selectTargets = targets,

			country = region:GetCountry(),
			renderBlockTargets = {
				[region:GetID()] = true,
			},

			hint = 'Выберите новые провинции для региона\nЛКМ - выделить/снять выделение',

			proccessProvince = function(regID, reg, id, prov)
				if reg:GetCapitalProvince() == id then
					return {0.2, 0.2, 0.2}
				end
			end,

			filter = function(editor)
				if table.IsEmpty(editor._selected) then
					return false, 'Нужно выбрать провинции!'
				end

				return true
			end,
		}, function(editor)
				local tbl = {}
				for id, province in pairs(editor._selected) do
					local reg = province:GetRegion()
					reg:RemoveProvince(province)

					tbl[#tbl + 1] = province
				end

				region:AddProvinces(tbl)
				mapEditor.close()
			end
		)
	end)

	country.actions.addRegionAction('Мобилизация войск', function(region)
		if region:GetPopulation() < 50 then return notify.show('error', 2, 'Для мобилизации войск нужно хотя бы 50 населения в регионе!') end

		local prov = region:GetProvinces()[ region:GetCapitalProvince() ]
		local c = region:GetCountry()

		region:AddPopulation(-50)
		units.create(c, prov, 0.5, 10, 1, 1.5, 0, 0)
	end)

	local mergeComboSelected = 1
	country.actions.addRegionAction('Удалить', function(region)
		local myCountry = game.myCountry

		if imgui.Button('Освободить') then
			region:Remove()
			imgui.CloseCurrentPopup()
		end

		if imgui.CollapsingHeader_TreeNodeFlags('Слияние с другим регионом', imgui.ImGuiTreeNodeFlags_None) then
			local regionsMap = {}
			local comboItems = {}

			for regID, reg in pairs(myCountry:GetRegions()) do
				if regID == region:GetID() then goto continue end
	
				local name = reg:GetName()
				local index = #comboItems + 1
	
				comboItems[index] = name
				regionsMap[index] = regID
	
				::continue::
			end

			if imgui.BeginCombo('С каким регионом выполнить слияние', comboItems[mergeComboSelected]) then
				for i, v in ipairs(comboItems) do
					local isSelected = i == mergeComboSelected
					if imgui.Selectable_Bool(v .. ' ##' .. i, isSelected) then
						mergeComboSelected = i
					end

					if isSelected then
						imgui.SetItemDefaultFocus()
					end
				end
				imgui.EndCombo()
			end

			if imgui.Button('Слияние') then
				imgui.CloseCurrentPopup()

				local regID = regionsMap[mergeComboSelected]
				if not regID then
					notify.show('error', 2, 'Выбран несуществующий регион!')
					goto continue
				end

				local targetRegion = myCountry:GetRegions()[regID]
				if not targetRegion then
					notify.show('error', 2, 'Выбран несуществующий регион!')
					goto continue
				end

				local population = region:GetPopulation()
				targetRegion:AddPopulation(population)
				region:TransferProvinces(nil, targetRegion)

				::continue::
			end
        end
	end, true)

	-- Countries

	country.actions.addCountryAction('Объявить войну', function(target)
		if target == game.myCountry then return end
		if game.myCountry:InWarWith(target) then return end

		country.declareWar(game.myCountry, target)
	end)

	country.actions.addCountryAction('Предложить перемирие', function(target)
		if target == game.myCountry then return end
		if not game.myCountry:InWarWith(target) then return end

		uiLib.popup.query('Предложение мира', {closable = true}, {
			{
				type = 'combo',
				tooltip = 'Предложение',
				items = {
					'Статус-кво',
					'Текущие границы',
				},
				selected = 1,
			},
		},
		function(widgets)
			local val = widgets[1].selected
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