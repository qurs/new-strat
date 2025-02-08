wildColonization = wildColonization or {}

wildColonization.cooldown = 30 * 24 -- 30 игровых дней
wildColonization.colonizationTime = {15, 45} -- от 15 до 45 игровых дней

hook.Add('AssetsLoaded', 'wildColonization', function()
	local startSound = love.audio.newSource( assetloader.get('sound_colonization_start'), 'static' )
	startSound:setVolume(0.4)

	local successSound = love.audio.newSource( assetloader.get('sound_colonization_end'), 'static' )
	local failSound = love.audio.newSource( assetloader.get('sound_colonization_fail'), 'static' )

	gamecycle.event.registerEvent('wild_colonization', function(prov)
		if not prov then return end

		local myCountry = game.myCountry
		if not myCountry then return end

		wildColonization._blocked = nil
		wildColonization._cd = gamecycle._time + wildColonization.cooldown

		local regionsMap = {}
		local comboItems = {}

		for regID, reg in pairs(myCountry:GetRegions()) do
			local name = reg:GetName()
			local index = #comboItems + 1

			comboItems[index] = name
			regionsMap[index] = regID
		end

		successSound:stop()
		successSound:play()

		gamecycle.event.ui.showWindow('В ходе разведки территории не было обнаружено местных жителей, соответственно территория достается нам даром!', {
			{
				text = 'Присоединить к существующему региону',
				callback = function()
					uiLib.popup.query('Присоединение новой территории', nil, {
						{
							type = 'label',
							text = 'Выбери регион:',
						},
						{
							type = 'combo',
							tooltip = 'Регион',
							items = comboItems,
							selected = 1,
						},
					},
					function(widgets)
						local selectedIndex = widgets[2].selected
						if not selectedIndex then return end

						local regID = regionsMap[selectedIndex]
						if not regID then return end

						local reg = country.getRegion(regID)
						if not reg then return end

						reg:AddPopulation(100)
						reg:AddProvince(prov)
					end)
				end,
			},

			{
				text = 'Создать новый регион',
				callback = function()
					country.actions._createRegionPopup(function(widgets)
						local regionName, capitalName = ffi.string(widgets[1].entry), ffi.string(widgets[2].entry)
						if utf8.len(regionName) < 3 or utf8.len(regionName) > 32 then
							return notify.show('error', 2.5, 'Название региона должно быть не короче 3-х и не длиннее 32-х символов!')
						end
						if utf8.len(capitalName) < 3 or utf8.len(capitalName) > 32 then
							return notify.show('error', 2.5, 'Название столицы должно быть не короче 3-х и не длиннее 32-х символов!')
						end

						local provID = prov:GetID()
						local newRegion = country.newRegion(regionName, capitalName, {[provID] = prov})
						newRegion:SetCapitalProvince(provID)
						newRegion:SetPopulation(100)

						myCountry:AddRegion(newRegion)
					end)
				end,
			},
		})
	end)

	radialMenu.registerOption('wild_colonization', {
		name = love.graphics.newText(gui.getFont('radialMenu.title'), 'Освоение диких земель'),
		desc = {font = 'radialMenu.desc', wrap = 300, align = 'left', text = 'Проведите разведку новых земель и установите над ней свой контроль'},
		icon = 'wild_colonization_icon',
	}, function()
		radialMenu.close()

		if wildColonization._blocked then
			notify.show('warn', 2, 'Сейчас уже идет колонизация!')
			return
		end

		if wildColonization._cd and wildColonization._cd > gamecycle._time then
			local diff = wildColonization._cd - gamecycle._time
			notify.show('warn', 2, ('Колонизация будет доступна тебе через %s д.'):format(math.ceil(diff / 24)))
			return
		end

		local exclude = {}

		for provID, prov in pairs(country._provinces) do
			if not prov:GetRegion() then goto continue end

			exclude[provID] = prov

			::continue::
		end

		mapEditor.open({
			singleSelect = true,

			selectTarget = 'province',
			selectExclude = exclude,

			renderType = 'province',
			renderExclude = exclude,

			hint = 'Выбери провинцию, которую хочешь колонизировать',

			filter = function(editor)
				local selectedID = editor._selected
				if not selectedID or not country.getProvince(selectedID) then
					return false, 'Нужно выбрать провинцию!'
				end

				return true
			end,
		}, function(editor)
			local provID = editor._selected
			local prov = country.getProvince(provID)

			local days = math.random(unpack(wildColonization.colonizationTime))

			wildColonization._blocked = true
			gamecycle.event.startDelayedEvent('wild_colonization', days * 24, {name = 'Колонизация'}, prov)

			startSound:stop()
			startSound:play()

			mapEditor.close()
		end)
	end)
end)