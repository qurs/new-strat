mapEditor = mapEditor or {}
mapEditor.handler = mapEditor.handler or {}

function mapEditor.handler.provinceLeftClick(prov)
	local editor = mapEditor._editor
	local settings = editor.settings

	if settings.selectTarget ~= 'province' then return end

	local region = prov:GetRegion()
	if not region then return end

	local regionID = region:GetID()

	local id = prov:GetID()
	local selectTargetsMap, excludeSelectTarget = mapEditor.getSelectTarget()
	if (selectTargetsMap and not selectTargetsMap[id]) or (excludeSelectTarget and excludeSelectTarget[id]) then
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
end

function mapEditor.handler.provinceRightClick(prov)
	local editor = mapEditor._editor
	local settings = editor.settings

	if not settings.select2 then return end
	if settings.selectTarget ~= 'province' then return end

	local id = prov:GetID()
	if editor._selected2 == id then return end

	local region = prov:GetRegion()
	if not region then return end

	local selectTargetsMap, excludeSelectTarget = mapEditor.getSelectTarget()
	if (selectTargetsMap and not selectTargetsMap[id]) or (excludeSelectTarget and excludeSelectTarget[id]) then
		return
	end

	if not editor._selected[id] then editor._selected[id] = prov end
	editor._selected2 = id
end