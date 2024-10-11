radialMenu = radialMenu or {}

radialMenu._appearLerp = 0
radialMenu._options = radialMenu._options or {}
radialMenu._optionsMap = radialMenu._optionsMap or {}

radialMenu.OPEN_KEY = 'r'

gui.registerFont('radialMenu.title', {
	font = 'Montserrat-Medium',
	size = 20,
})

gui.registerFont('radialMenu.desc', {
	font = 'Montserrat-Medium',
	size = 14,
})

function radialMenu.open()
	if mapEditor._editor then return end
	if #uiLib.popup._popups > 0 then return end
	if gamecycle.event.ui._window then return end

	radialMenu._opened = true
end

function radialMenu.close()
	radialMenu._opened = nil
end

function radialMenu.registerOption(id, printData, callback)
	if type(printData.name) == 'table' then
		local text = love.graphics.newText(gui.getFont(printData.name.font), printData.name.text)
		if printData.name.wrap then
			text:setf(printData.name.text, printData.name.wrap, printData.name.align)
		end
		printData.name = text
	end

	if type(printData.desc) == 'table' then
		local text = love.graphics.newText(gui.getFont(printData.desc.font), printData.desc.text)
		if printData.desc.wrap then
			text:setf(printData.desc.text, printData.desc.wrap, printData.desc.align)
		end
		printData.desc = text
	end

	local i = #radialMenu._options + 1
	radialMenu._options[i] = {
		id = id,
		printData = printData,
		_data = {},
	}

	radialMenu._optionsMap[id] = {
		index = i,
		callback = callback,
	}
end

function radialMenu.removeOption(id)
	local data = radialMenu._optionsMap[id]
	if not data then return end

	table.remove(radialMenu._options, data.index)

	for i, v in ipairs(radialMenu._options) do
		radialMenu._optionsMap[id].index = i
	end
end

local up = Vector(1, 0)

hook.Add('PostDrawUI', 'radialMenu', function()
	if radialMenu._appearLerp == 0 then return end

	local sw, sh = ScrW(), ScrH()
	local x, y = sw / 2, sh / 2
	local radius = radialMenu._appearLerp * (sh / 4)
	local lineWidth = radius / 2

	local padText

	love.graphics.setColor(0.15, 0.15, 0.15, 0.85)
	love.graphics.circle('fill', x, y, radius)

	local ang = 2 * math.pi / #radialMenu._options
	local lastAng = -math.pi / 2 - ang / 2

	local mouseX, mouseY = love.mouse.getPosition()
	local mouseRadius = math.sqrt( (mouseX - x) ^ 2 + (mouseY - y) ^ 2 )
	local mouseAng = math.atan2(mouseY - y, mouseX - x)

	for i, v in ipairs(radialMenu._options) do
		local startAng, endAng = lastAng, lastAng + ang
		local data = v._data
		
		love.graphics.stencil(function()
			love.graphics.setColor(1, 1, 1)
			love.graphics.arc('fill', x, y, radius - lineWidth, startAng, endAng)
		end, 'increment', 1)

		local mouseSelect = false
		if #radialMenu._options == 1 then
			mouseSelect = mouseRadius < radius
		elseif #radialMenu._options == 2 then
			mouseSelect = mouseRadius < radius and mouseAng > startAng and mouseAng < endAng
		else
			local diffBetween = math.abs( (startAng - endAng + math.pi) % (math.pi * 2) - math.pi )
			local diffToStart = math.abs( (startAng - mouseAng + math.pi) % (math.pi * 2) - math.pi )
			local diffToEnd = math.abs( (endAng - mouseAng + math.pi) % (math.pi * 2) - math.pi )

			mouseSelect = mouseRadius < radius and diffToStart < diffBetween and diffToEnd < diffBetween
		end

		if mouseSelect then
			data.appearLerp = Lerp(0.09, data.appearLerp or 0, 1)

			padText = {
				title = v.printData.name,
				desc = v.printData.desc,
			}
		elseif data.appearLerp then
			data.appearLerp = Lerp(0.09, data.appearLerp, 0)

			if data.appearLerp < 0.1 then
				data.appearLerp = nil
			end
		end

		local dir = up:Rotated(lastAng + ang / 2)
		local iconX, iconY = x + dir.x * (radius - lineWidth / 2), y + dir.y * (radius - lineWidth / 2)

		if data.appearLerp then
			local arcX, arcY = Lerp(data.appearLerp, iconX, x), Lerp(data.appearLerp, iconY, y)

			love.graphics.setStencilTest('less', 1)
				love.graphics.setColor(1, 1, 1, data.appearLerp * 0.1)
				love.graphics.arc('fill', arcX, arcY, data.appearLerp * radius, startAng, endAng)
			love.graphics.setStencilTest()
		end

		local asset = assetloader.get(v.printData.icon)
		if radialMenu._appearLerp > 0.5 and asset then
			local img = asset.img
			local imgW, imgH = img:getWidth(), img:getHeight()

			local col = v.printData.iconColor or {1, 1, 1}

			love.graphics.setColor(unpack(col))
			love.graphics.draw(img, iconX - imgW / 2, iconY - imgH / 2)
		end

		lastAng = endAng
	end

	if padText then
		local titleW, titleH = padText.title:getWidth(), padText.title:getHeight()
		local descW, descH = padText.desc:getWidth(), padText.desc:getHeight()

		local padW = math.max(titleW, descW) + 20
		local padH = 10 + titleH + 8 + descH + 10
		local padX = sw / 2 - padW / 2
		local padY = y - radius - padH - 20

		love.graphics.setColor(0.15, 0.15, 0.15, 0.85)
		love.graphics.rectangle('fill', padX, padY, padW, padH, 16, 16)

		local titleX, titleY = padX + (padW / 2 - titleW / 2), padY + 10

		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(padText.title, titleX, titleY)

		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(padText.desc, padX + (padW / 2 - descW / 2), titleY + titleH + 8)
	end
end)

hook.Add('MouseDown', 'radialMenu', function(mouseX, mouseY, button)
	if not radialMenu._opened then return end
	if button ~= 1 then return end

	local sw, sh = ScrW(), ScrH()
	local x, y = sw / 2, sh / 2
	local radius = sh / 4

	local mouseRadius = math.sqrt( (mouseX - x) ^ 2 + (mouseY - y) ^ 2 )
	if mouseRadius > radius then return end

	local mouseAng = math.atan2(mouseY - y, mouseX - x)

	local ang = 2 * math.pi / #radialMenu._options
	local lastAng = -math.pi / 2 - ang / 2

	for _, v in ipairs(radialMenu._options) do
		local startAng, endAng = lastAng, lastAng + ang

		local mouseSelect = false
		if #radialMenu._options == 1 then
			mouseSelect = true
		elseif #radialMenu._options == 2 then
			mouseSelect = mouseAng > startAng and mouseAng < endAng
		else
			local diffBetween = math.abs( (startAng - endAng + math.pi) % (math.pi * 2) - math.pi )
		local diffToStart = math.abs( (startAng - mouseAng + math.pi) % (math.pi * 2) - math.pi )
		local diffToEnd = math.abs( (endAng - mouseAng + math.pi) % (math.pi * 2) - math.pi )

			mouseSelect = diffToStart < diffBetween and diffToEnd < diffBetween
		end

		if mouseSelect then
			local map = radialMenu._optionsMap[v.id]
			if map then
				map.callback()
				return
			end
		end

		lastAng = endAng
	end
end)

hook.Add('Think', 'radialMenu', function(dt)
	if (radialMenu._opened and radialMenu._appearLerp == 1) or (not radialMenu._opened and radialMenu._appearLerp == 0) then return end

	if radialMenu._opened then
		radialMenu._appearLerp = Lerp(0.2, radialMenu._appearLerp, 1)

		if radialMenu._appearLerp > 0.95 then
			radialMenu._appearLerp = 1
		end
	else
		radialMenu._appearLerp = Lerp(0.2, radialMenu._appearLerp, 0)

		if radialMenu._appearLerp < 0.05 then
			radialMenu._appearLerp = 0
		end
	end
	
end)

hook.Add('KeyDown', 'radialMenu', function(key)
	if scene.getName() ~= 'map' then return end
	if radialMenu._opened then return end
	if key ~= radialMenu.OPEN_KEY then return end

	radialMenu.open()
end)

hook.Add('KeyUp', 'radialMenu', function(key)
	if scene.getName() ~= 'map' then return end
	if not radialMenu._opened then return end
	if key ~= radialMenu.OPEN_KEY then return end

	radialMenu.close()
end)

--[[ EXAMPLES:
radialMenu.registerOption(1, {
	name = love.graphics.newText(gui.getFont('radialMenu.title'), 'Test 1'),
	desc = love.graphics.newText(gui.getFont('radialMenu.desc'), 'Test Description 1'),
	icon = 'pause_img',
	iconColor = {1, 0, 0},
}, function()
	print('test 1')
end)

radialMenu.registerOption(2, {
	name = love.graphics.newText(gui.getFont('radialMenu.title'), 'Test 2'),
	desc = {font = 'radialMenu.desc', wrap = 300, align = 'left', text = 'Равным образом повышение уровня гражданского сознания требует от нас анализа модели развития.'},
	icon = 'pause_img',
}, function()
	print('test 2')
end)
]]