hook.Add('AssetsLoaded', 'gamecycle.event.default', function()
	gamecycle.event.registerRegularEvent('population_up', 24 * 30, function()
		for _, country in pairs(country._countries) do
			for _, region in pairs(country:GetRegions()) do
				region:AddPopulation(100)
			end
		end
	end)
end)