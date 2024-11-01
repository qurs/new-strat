gamecycle = gamecycle or {}
gamecycle.uiPadSize = {240, 40}

gui.registerFont('gamecycle.pad', {
	font = 'Montserrat-Medium',
	size = 15,
})

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
local padW, padH = unpack(gamecycle.uiPadSize)

function gamecycle.ui()
	if scene.getName() ~= 'map' then return end
	if mapEditor._editor then return end

	local x, y = ScrW() - padW, 0
	local flags = imgui.love.WindowFlags('NoTitleBar', 'NoBackground', 'NoMove', 'NoResize', 'NoCollapse', 'NoScrollbar')

	local col = {0, 0, 0, 0}
	
	imgui.SetNextWindowPos({x, y})
	imgui.SetNextWindowSize({padW, padH})

	imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_WindowPadding, {0, 0})
	imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_FramePadding, {0, 0})
	imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_ItemSpacing, {0, 0})
	imgui.PushStyleVar_Float(imgui.ImGuiStyleVar_WindowBorderSize, 0)

	if imgui.Begin('gamecycle', nil, flags) then
		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_Button, col)
		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_ButtonHovered, col)
		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_ButtonActive, col)
			if imgui.Button('##01', {16, padH - 7}) then
				gamecycle.decreaseSpeed()
			end
			imgui.SameLine()
			if imgui.Button('##02', {padW - 32, padH - 7}) then
				gamecycle.toggle()
			end
			imgui.SameLine()
			if imgui.Button('##03', {16, padH - 7}) then
				gamecycle.increaseSpeed()
			end
		imgui.PopStyleColor(3)

		col = {0.4, 1, 0.39, gamecycle.speed == gamecycle.speeds[1] and 1 or 0.2}
		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_Button, col)
		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_ButtonHovered, col)
		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_ButtonActive, col)
			if imgui.Button('##04', {padW / 4, 7}) then
				gamecycle.setSpeed(1)
			end
			imgui.SameLine()
		imgui.PopStyleColor(3)

		col = {0.94, 1, 0.39, gamecycle.speed == gamecycle.speeds[2] and 1 or 0.2}
		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_Button, col)
		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_ButtonHovered, col)
		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_ButtonActive, col)
			if imgui.Button('##05', {padW / 4, 7}) then
				gamecycle.setSpeed(2)
			end
			imgui.SameLine()
		imgui.PopStyleColor(3)

		col = {1, 0.54, 0.39, gamecycle.speed == gamecycle.speeds[3] and 1 or 0.2}
		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_Button, col)
		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_ButtonHovered, col)
		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_ButtonActive, col)
			if imgui.Button('##06', {padW / 4, 7}) then
				gamecycle.setSpeed(3)
			end
			imgui.SameLine()
		imgui.PopStyleColor(3)

		col = {1, 0.39, 0.39, gamecycle.speed == gamecycle.speeds[4] and 1 or 0.2}
		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_Button, col)
		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_ButtonHovered, col)
		imgui.PushStyleColor_Vec4(imgui.ImGuiCol_ButtonActive, col)
			if imgui.Button('##07', {padW / 4, 7}) then
				gamecycle.setSpeed(4)
			end
		imgui.PopStyleColor(3)
	end
	imgui.End()

	imgui.PopStyleVar(4)
end

hook.Add('AssetsLoaded', 'gamecycle', function()
	pauseImg = assetloader.get('pause_img').img

	text = love.graphics.newText(gui.getFont('gamecycle.pad'))
	textMinus = love.graphics.newText(gui.getFont('gamecycle.pad'), '-')
	textPlus = love.graphics.newText(gui.getFont('gamecycle.pad'), '+')
end)

hook.Add('PreDrawUI', 'gamecycle', function()
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
	if devConsole._open then return end

	if key == 'space' then
		gamecycle.toggle()
	end
end)