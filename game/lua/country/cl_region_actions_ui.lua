gui.registerFont('region.actionsTitle', {
	font = 'Montserrat-Medium',
	size = 16,
})

country = country or {}
country.actions = country.actions or {}

local padW, padH = 256, 400
local textObj

hook.Add('AssetsLoaded', 'country.regionActions', function()
	textObj = love.graphics.newText(gui.getFont('region.actionsTitle'))
end)

hook.Add('DrawUI', 'country.regionActions', function()
	if scene.getName() ~= 'map' then return end
	if mapEditor._editor then return end
	if map._selectedCountry then return end

	local province = map._selectedProvince
	if not province then return end

	local region = province:GetRegion()
	if not region then return end

	local w, h = padW, padH
	local x, y = 0, ScrH() - h

	local font = gui.getFontImgui('region.actionsTitle')
	local flags = imgui.love.WindowFlags('NoTitleBar', 'NoMove', 'NoResize', 'NoCollapse')

	local population = region:GetPopulation()
	local populationStr = tostring(population)
	if population > 1000000000 then
		local billions = math.floor(population / 1000000000)
		populationStr = billions .. 'kkk'
	elseif population > 1000000 then
		local millions = math.floor(population / 1000000)
		populationStr = millions .. 'kk'
	end

	imgui.SetNextWindowPos({x, y})
	imgui.SetNextWindowSize({w, h})

	imgui.PushFont(font)
	if imgui.Begin('region_actions', nil, flags) then
		imgui.Text( ('Население: %s'):format(populationStr) )

		for _, action in ipairs(country.actions.list.region) do
			if imgui.Button(action.name) then
				action.callback(region)
			end
		end
	end
	imgui.End()
	imgui.PopFont()
end)

hook.Add('PreDrawUI', 'country.regionActions', function()
	if scene.getName() ~= 'map' then return end
	if mapEditor._editor then return end
	if map._selectedCountry then return end

	local province = map._selectedProvince
	if not province then return end

	local region = province:GetRegion()
	if not region then return end

	local w, h = padW, padH
	local x, y = 0, ScrH() - h

	textObj:setf(region:GetName(), w - 10, 'left')

	local titleH = math.max(16, textObj:getHeight() + 10)
	local titleY = y - titleH

	love.graphics.setColor(0.1, 0.1, 0.1)
	love.graphics.rectangle('fill', x, titleY, w, titleH)

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(textObj, x + 5, titleY + 5)
end)