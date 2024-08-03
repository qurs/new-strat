local text1, text2
local font = love.graphics.newFont('assets/fonts/Montserrat-Black.ttf', 25)

local stage, progress, maxProgress

local startedLoading = false
local stopLoadingTime = false

local timeToStop = 1

hook.Add('PreDraw', 'loading', function()
	if assetloader.isLoading() and not startedLoading then startedLoading = true end
	if not startedLoading then return end

	if not text1 then text1 = love.graphics.newText(font, 'Loading...') end
	if not text2 then text2 = love.graphics.newText(font, '0 / 0') end

	if not stopLoadingTime and not assetloader.isLoading() then
		stopLoadingTime = os.clock() + timeToStop

		timer.Simple(timeToStop, function()
			startedLoading = false
			stopLoadingTime = false
		end)
	end

	if not stopLoadingTime then
		stage, progress, maxProgress = assetloader.getStage(), assetloader.getProgress(), assetloader.getMaxProgress()
	end

	local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
	local alpha = 1

	if stopLoadingTime then
		alpha = (stopLoadingTime - os.clock()) / timeToStop
	end

	do
		local tw, th = text1:getWidth(), text1:getHeight()

		love.graphics.setColor(1, 1, 1, alpha)
		love.graphics.draw(text1, sw * 0.5 - tw * 0.5, sh * 0.5 - th * 0.5 - 15)
	end

	do
		text2:set( ('%s: %s/%s'):format( stage, progress, maxProgress ) )

		local tw, th = text2:getWidth(), text2:getHeight()

		love.graphics.setColor(1, 1, 1, alpha)
		love.graphics.draw(text2, sw * 0.5 - tw * 0.5, sh * 0.5 - th * 0.5 + 15)
	end

	return true
end)