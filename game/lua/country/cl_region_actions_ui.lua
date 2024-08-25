gui.registerFont('region.actionsTitle', {
	font = 'Montserrat-Medium',
	size = 16,
})

country = country or {}
country.actions = country.actions or {}

local style = {}

local padW, padH = 256, 400
local textObj

hook.Add('AssetsLoaded', 'country.regionActions', function()
	style.font = gui.getFont('region.actionsTitle')
	textObj = love.graphics.newText(gui.getFont('region.actionsTitle'))
end)

hook.Add('UI', 'country.regionActions', function(dt)
	if scene.getName() ~= 'map' then return end
	if regionEditor._editing then return end

	local province = map._selectedProvince
	if not province then return end

	local region = province:GetRegion()
	if not region then return end

	local w, h = padW, padH
	local x, y = 0, ScrH() - h

	local font = style.font

	local _, wrapLimit = font:getWrap( ('Население: %s'):format(region:GetPopulation()), w )

	ui:stylePush(style)
		if ui:windowBegin('region_actions', x, y, w, h, 'scrollbar') then
			for _, v in ipairs(wrapLimit) do
				ui:layoutRow('dynamic', font:getHeight(), 1)
				ui:label(v)
			end

			for _, action in ipairs(country.actions.list) do
				ui:layoutRow('dynamic', 28, 1)
				if ui:button(action.name) then
					action.callback(region)
				end
			end
		end
		ui:windowEnd()
	ui:stylePop()
end)

hook.Add('PostDrawUI', 'country.regionActions', function()
	if scene.getName() ~= 'map' then return end
	if regionEditor._editing then return end

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