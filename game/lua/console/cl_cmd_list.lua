hook.Add('Initialize', 'devConsole.cmdlist', function()
	devConsole.registerCommand('test', nil, 'Test command', function(args, argStr)
		return 'Test command: ' .. argStr
	end)
	
	devConsole.registerCommand('test_form', {'some_var', 'bebra'}, 'Test command with form', function(args, argStr)
		return 'Test command with form: ' .. argStr
	end)

	devConsole.registerCommand('run_lua', {'code'}, 'Runs Lua from a string', function(args, argStr)
		assert( loadstring(argStr) )()
	end)

	devConsole.registerCommand('country_list', nil, 'Prints a country list in format "id = name"', function(args, argStr)
		local str = ''
		for id, c in pairs(country._countries) do
			str = str .. ('%s = %s'):format(id, c:GetName())
			if next(country._countries, id) then
				str = str .. '\n'
			end
		end

		return {'Country list:\n' .. str, '#FFFF00'}
	end)

	devConsole.registerCommand('full_region_list', nil, 'Prints the full region list in format "id = name | countryID"', function(args, argStr)
		local str = ''
		for id, reg in pairs(country._regions) do
			local owner = reg:GetCountry()
			local ownerID = 'no owner'
			if owner then
				ownerID = owner:GetID()
			end

			str = str .. ('%s = %s | %s'):format(id, reg:GetName(), ownerID)
			if next(country._regions, id) then
				str = str .. '\n'
			end
		end

		return {'Full region list:\n' .. str, '#FFFF00'}
	end)

	devConsole.registerCommand('country_region_list', {'countryID'}, 'Prints the country region list in format "id = name"', function(args, argStr)
		local countryID = tonumber(args[1])
		if not countryID then return false end

		local c = country.get(countryID)
		if not c then return {('Country with id "%s" not found!'):format(countryID), '#FF0000'} end

		local regions = c:GetRegions()
		local str = ''
		for id, reg in pairs(regions) do
			str = str .. ('%s = %s'):format(id, reg:GetName())
			if next(regions, id) then
				str = str .. '\n'
			end
		end

		return {'Country region list:\n' .. str, '#FFFF00'}
	end)

	devConsole.registerCommand('province_change_region', {'provinceID', 'regionID'}, 'Transfers the province to the region', function(args, argStr)
		local provinceID, regionID = unpack(args)
		provinceID = tonumber(provinceID)
		regionID = tonumber(regionID)

		if not provinceID or not regionID then return false end

		local prov = country.getProvince(provinceID)
		if not prov then return {('Province with id "%s" not found!'):format(provinceID), '#FF0000'} end

		local reg = country.getRegion(regionID)
		if not reg then return {('Region with id "%s" not found!'):format(regionID), '#FF0000'} end

		prov:ChangeRegion(reg)

		return {('The province "%s" has been transfered to the region "%s"'):format(provinceID, reg:GetName()), '#00FF00'}
	end)

	devConsole.registerCommand('region_change_country', {'regionID', 'countryID'}, 'Transfers the region to the country', function(args, argStr)
		local regionID, countryID = unpack(args)
		regionID = tonumber(regionID)
		countryID = tonumber(countryID)

		if not regionID or not countryID then return false end

		local reg = country.getRegion(regionID)
		if not reg then return {('Region with id "%s" not found!'):format(regionID), '#FF0000'} end

		local c = country.get(countryID)
		if not c then return {('Country with id "%s" not found!'):format(countryID), '#FF0000'} end

		reg:ChangeCountry(c)

		return {('The region "%s" has been transfered to the country "%s"'):format(reg:GetName(), c:GetName()), '#00FF00'}
	end)
	
	devConsole.registerCommand('remove_radial_option', {'id'}, 'Removes the option from the radial menu', function(args, argStr)
		local id = args[1]
		if not radialMenu.removeOption(id) then
			return {('Radial menu option "%s" not found!'):format(id), '#FF0000'}
		end
	
		return {('Radial menu option "%s" has been removed!'):format(id), '#00FF00'}
	end)

	devConsole.registerCommand('set_speed', {'number'}, 'Sets game speed', function(args, argStr)
		local speed = tonumber(args[1])
		if not speed then return false end

		gamecycle.speed = speed
	
		return {'Speed was set to ' .. speed, '#00FF00'}
	end)
end)