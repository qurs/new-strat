notify = notify or {}
notify._notifies = notify._notifies or {}

local defaultNotifyFont = gui.registerFont('notify.default', {
	font = 'Montserrat-Medium',
	size = 18,
})

notify.types = {
	generic = {
		color = {224, 187, 92},
		font = defaultNotifyFont,
	},
	error = {
		color = {201, 20, 20},
		font = defaultNotifyFont,
	},
	warn = {
		color = {219, 58, 13},
		font = defaultNotifyFont,
	},
}

function notify.show(type, time, text)
	type = type or 'generic'

	local notifyData = notify.types[type] or notify.types['generic']
	local clr = notifyData.color
	local font = notifyData.font
	local tw, th = font:getWidth(text), font:getHeight(text)
	local _, count = string.gsub(text, '\n', '')
	th = th * (count + 1)

	local w, h = tw + 30, th + 40
	local x, y = ScrW() + w, 15

	for k, v in ipairs(notify._notifies) do
		y = y + v.size[2] + 15
	end

	notify._notifies[#notify._notifies + 1] = {
		color = clr,
		text = text,
		endtime = os.time() + time,
		size = {w, h},
		textSize = {tw, th},
		pos = {x, y},
		endpos = {ScrW() - w - 20, y},
		startpos = {x, y},
		font = font,
	}
end

hook.Add('PostDrawUI', 'notifies', function()
	local shSize = 0
	for k, v in ipairs( notify._notifies ) do
		love.graphics.setColor(6 / 255, 34 / 255, 43 / 255, 1)
		love.graphics.rectangle('fill', v.pos[1], v.pos[2], v.size[1], v.size[2])

		if not v.textObj then
			v.textObj = love.graphics.newText(v.font, v.text)
		end

		love.graphics.setColor(v.color[1] / 255, v.color[2] / 255, v.color[3] / 255, 1)
		love.graphics.draw(v.textObj, v.pos[1] + ( v.size[1] / 2 - v.textSize[1] / 2 ), v.pos[2] + ( v.size[2] / 2 - v.textSize[2] / 2 ))

		shSize = shSize + v.size[2]
	end
end)

hook.Add('Think', 'notifies', function(dt)
	local shSize = 0
	for k, v in ipairs( notify._notifies ) do
		if os.time() < v.endtime then
			v.pos = LerpPos( 8.5 * dt, v.pos, { v.endpos[1], 15 + shSize + (15 * k) } )
		else
			v.pos = LerpPos( 4 * dt, v.pos, {v.startpos[1], v.pos[2]} )

			if v.pos[1] >= ScrW() then
				v.toRemove = true
			end
		end

		shSize = shSize + v.size[2]
	end

	while true do
		local toRemove
		for k, v in ipairs( notify._notifies ) do
			if v.toRemove then
				toRemove = k
				break
			end
		end

		if toRemove then
			table.remove(notify._notifies, toRemove)
		else
			break
		end
	end
end)