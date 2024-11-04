pauseMenu = pauseMenu or {}

local imguiFont
local w, h = 180, 230

gui.registerFont('pausemenu', {
	font = 'Montserrat-Medium',
	size = 15,
})

function pauseMenu.open()
	if pauseMenu._open then return end

	pauseMenu._open = true
	gamecycle.pause()
end

function pauseMenu.close()
	if not pauseMenu._open then return end
	pauseMenu._open = nil
end

hook.Add('Initialize', 'pauseMenu', function()
	imguiFont = gui.getFontImgui('pausemenu')
end, -1)

hook.Add('DrawUI', 'pauseMenu', function()
	if not pauseMenu._open then return end
	if not imguiFont then return end

	local flags = imgui.love.WindowFlags('NoTitleBar', 'NoMove', 'NoResize', 'NoCollapse')

	imgui.SetNextWindowPos({ScrW() / 2 - w / 2, ScrH() / 2 - h / 2})
	imgui.SetNextWindowSize({w, h})

	imgui.PushFont(imguiFont)
	if imgui.Begin('pausemenu', nil, flags) then
		local style = imgui.GetStyle()

		if imgui.Button('Продолжить игру', {-1, 24}) then
			pauseMenu.close()
		end

		if imgui.Button('Выйти в главное меню', {-1, 24}) then
			game.endGame()
		end
	end
	imgui.End()
	imgui.PopFont()
end)

hook.Add('KeyDown', 'pauseMenu', function(key)
	if scene.getName() ~= 'map' then return end

	if key == 'escape' then
		if pauseMenu._open then return pauseMenu.close() end
		pauseMenu.open()
	end
end, -1)