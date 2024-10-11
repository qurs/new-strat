gamecycle = gamecycle or {}

gui.registerFont('gamecycle.pad', {
	font = 'Montserrat-Medium',
	size = 15,
})

local style = {
	window = {
		['fixed background'] = '#00000000',
		padding = {x = 0, y = 0},
		spacing = {x = 0, y = 0},
	},
	button = {
		['border color'] = '#00000000',
	},
}

local monthNames = {
	'января',
	'февраля',
	'марта',
	'апреля',
	'мая',
	'июня',
	'июля',
	'августа',
	'сентября',
	'октября',
	'ноября',
	'декабря',
}

local text, textMinus, textPlus, pauseImg
local padW, padH = 240, 40

function gamecycle.ui(dt)
	if scene.getName() ~= 'map' then return end
	if mapEditor._editor then return end

	local x, y = ScrW() - padW, 0

	ui:stylePush(style)
		if ui:windowBegin('gamecycle', x, y, padW, padH) then
			ui:layoutRow('static', padH - 6, {16, padW - 32, 16})
			if ui:button(nil, '#00000000') then
				gamecycle.decreaseSpeed()
			end
			if ui:button(nil, '#00000000') then
				gamecycle.toggle()
			end
			if ui:button(nil, '#00000000') then
				gamecycle.increaseSpeed()
			end

			ui:layoutRow('dynamic', 6, 4)
			if ui:button(nil, '#66ff63' .. (gamecycle.speed == gamecycle.speeds[1] and 'ff' or '30')) then
				gamecycle.setSpeed(1)
			end
			if ui:button(nil, '#efff63' .. (gamecycle.speed == gamecycle.speeds[2] and 'ff' or '30')) then
				gamecycle.setSpeed(2)
			end
			if ui:button(nil, '#ff8a63' .. (gamecycle.speed == gamecycle.speeds[3] and 'ff' or '30')) then
				gamecycle.setSpeed(3)
			end
			if ui:button(nil, '#ff6363' .. (gamecycle.speed == gamecycle.speeds[4] and 'ff' or '30')) then
				gamecycle.setSpeed(4)
			end
		end
		ui:windowEnd()
	ui:stylePop()
end

hook.Add('AssetsLoaded', 'gamecycle', function()
	pauseImg = assetloader.get('pause_img').img

	text = love.graphics.newText(gui.getFont('gamecycle.pad'))
	textMinus = love.graphics.newText(gui.getFont('gamecycle.pad'), '-')
	textPlus = love.graphics.newText(gui.getFont('gamecycle.pad'), '+')
end)

hook.Add('DrawUI', 'gamecycle', function()
	if scene.getName() ~= 'map' then return end
	if mapEditor._editor then return end
	if not text then return end

	local date = gamecycle.getDate()
	text:set( ('%d-е %s %04i г. %02i:00'):format(date.day, monthNames[ date.month ], date.year, date.hour) )

	local x, y = ScrW() - padW, 0
	local radius = 8

	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.rectangle('fill', x, y, padW, padH)

	love.graphics.setColor(0.3, 0.3, 0.3)
	love.graphics.circle('fill', x + radius, y + padH / 2, radius)

	love.graphics.setColor(0.3, 0.3, 0.3)
	love.graphics.circle('fill', x + padW - radius, y + padH / 2, radius)

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(textMinus, x + radius - textMinus:getWidth() / 2, y + (padH / 2 - textMinus:getHeight() / 2))

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(textPlus, x + padW - radius - textPlus:getWidth() / 2, y + (padH / 2 - textPlus:getHeight() / 2))

	local tx, ty = x + (padW / 2 - text:getWidth() / 2), y + (padH / 2 - text:getHeight() / 2)

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(text, tx, ty)
end)

hook.Add('PostDrawUI', 'gamecycle', function()
	if scene.getName() ~= 'map' then return end
	if mapEditor._editor then return end
	if not text then return end

	local x, y = ScrW() - padW, 0
	local tx, ty = x + (padW / 2 - text:getWidth() / 2), y + (padH / 2 - text:getHeight() / 2)

	if not gamecycle._started then
		love.graphics.setColor(0, 0, 0, 0.5)
		love.graphics.rectangle('fill', x, y, padW, padH)

		local sx = 0.5
		local iw, ih = pauseImg:getWidth() * sx, pauseImg:getHeight() * sx

		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(pauseImg, tx + (text:getWidth() / 2 - iw / 2), ty + (text:getHeight() / 2 - ih / 2), 0, sx)
	end
end)

hook.Add('KeyDown', 'gamecycle', function(key)
	if key == 'space' then
		gamecycle.toggle()
	end
end)