uiLib = uiLib or {}

function uiLib.verticalAlign(draws, align)
	local totalHeight = 0
	local style = imgui.GetStyle()

	for k, v in ipairs(draws) do
		local height = v()
		totalHeight = totalHeight + height

		if next(draws, k) then
			totalHeight = totalHeight + style.ItemSpacing.y
		end
	end

	local avail = imgui.GetContentRegionAvail().y
	local off = (avail - totalHeight) * align

	if off > 0 then
		imgui.SetCursorPosY(imgui.GetCursorPosY() + off)
	end

	for k, v in ipairs(draws) do
		local func = select(2, v())
		func()
	end
end

function uiLib.alignForWidth(width, align)
	align = align or 0.5

	local style = imgui.GetStyle()
	local avail = imgui.GetContentRegionAvail().x
	local off = (avail - width) * align
	if off > 0 then
		imgui.SetCursorPosX(imgui.GetCursorPosX() + off)
	end
end

function uiLib.alignForWidthButton(label, align)
	align = align or 0.5

	local style = imgui.GetStyle()
	local avail = imgui.GetContentRegionAvail().x

	local size = imgui.CalcTextSize(label).x + style.FramePadding.x * 2
	local off = (avail - size) * align
	if off > 0 then
		imgui.SetCursorPosX(imgui.GetCursorPosX() + off)
	end
end

function uiLib.alignedButton(label, align, size)
	align = align or 0.5

	local style = imgui.GetStyle()
	local avail = imgui.GetContentRegionAvail().x

	local width
	if size then
		width = size[1]
	else
		width = imgui.CalcTextSize(label).x + style.FramePadding.x * 2
	end

	local off = (avail - width) * align
	if off > 0 then
		imgui.SetCursorPosX(imgui.GetCursorPosX() + off)
	end

	return imgui.Button(label, size)
end