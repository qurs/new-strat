gui.registerFont('country.actionsTitle', {
	font = 'Montserrat-Medium',
	size = 16,
})

country = country or {}
country.actions = country.actions or {}

local style = {}

local padW, padH = 256, 400
local textObj

hook.Add('AssetsLoaded', 'country.countryActions', function()
	style.font = gui.getFont('country.actionsTitle')
	textObj = love.graphics.newText(gui.getFont('country.actionsTitle'))
end)

hook.Add('UI', 'country.countryActions', function(dt)
	if scene.getName() ~= 'map' then return end
	if regionEditor._editor then return end

	local c = map._selectedCountry
	if not c then return end

	local w, h = padW, padH
	local x, y = 0, ScrH() - h

	local font = style.font

	ui:stylePush(style)
		if ui:windowBegin('country_actions', x, y, w, h, 'scrollbar') then
			for _, action in ipairs(country.actions.list.country) do
				ui:layoutRow('dynamic', 28, 1)
				if ui:button(action.name) then
					action.callback(c)
				end
			end
		end
		ui:windowEnd()
	ui:stylePop()
end)

hook.Add('PreDrawUI', 'country.countryActions', function()
	if scene.getName() ~= 'map' then return end
	if regionEditor._editor then return end

	local country = map._selectedCountry
	if not country then return end

	local w, h = padW, padH
	local x, y = 0, ScrH() - h

	textObj:setf(country:GetName(), w - 10, 'left')

	local titleH = math.max(16, textObj:getHeight() + 10)
	local titleY = y - titleH

	love.graphics.setColor(0.1, 0.1, 0.1)
	love.graphics.rectangle('fill', x, titleY, w, titleH)

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(textObj, x + 5, titleY + 5)
end)