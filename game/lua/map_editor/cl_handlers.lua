mapEditor = mapEditor or {}
mapEditor.handler = mapEditor.handler or {}

function mapEditor.handler.provinceLeftClick(prov)
	local editor = mapEditor._editor
	local settings = editor.settings

	if settings.selectTarget ~= 'province' then return end

	local id = prov:GetID()
	if settings.singleSelect then
		if editor._selected == id or editor._selected2 == id then return end
	end

	local selectTargetsMap, excludeSelectTarget = mapEditor.getSelectTarget()

	local excludeCheckID = id
	if settings.selectExcludeType == 'region' then
		local region = prov:GetRegion()
		if not region then return end

		excludeCheckID = region:GetID()
	end

	if (selectTargetsMap and not selectTargetsMap[id]) or (excludeSelectTarget and excludeSelectTarget[excludeCheckID]) then
		return
	end

	if settings.singleSelect then
		editor._selected = id
		mapEditor.createSelectedCanvas()
		return
	end

	if editor._selected[id] then
		editor._selected[id] = nil

		if editor._selected2 == id then
			editor._selected2 = nil
		end
	else
		editor._selected[id] = prov
	end

	mapEditor.createSelectedCanvas()
end

function mapEditor.handler.provinceRightClick(prov)
	local editor = mapEditor._editor
	local settings = editor.settings

	if not settings.select2 then return end
	if settings.selectTarget ~= 'province' then return end

	local id = prov:GetID()

	if settings.singleSelect and editor._selected == id then return end
	if editor._selected2 == id then return end

	local excludeCheckID = id
	if settings.selectExcludeType == 'region' then
		local region = prov:GetRegion()
		if not region then return end

		excludeCheckID = region:GetID()
	end

	local selectTargetsMap, excludeSelectTarget = mapEditor.getSelectTarget()
	if (selectTargetsMap and not selectTargetsMap[id]) or (excludeSelectTarget and excludeSelectTarget[excludeCheckID]) then
		return
	end

	if settings.singleSelect then
		editor._selected2 = id
		mapEditor.createSelectedCanvas()
		return
	end

	if not editor._selected[id] then editor._selected[id] = prov end
	editor._selected2 = id

	mapEditor.createSelectedCanvas()
end