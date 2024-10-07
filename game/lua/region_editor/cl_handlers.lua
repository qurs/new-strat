regionEditor = regionEditor or {}
regionEditor.handler = regionEditor.handler or {}

function regionEditor.handler.provinceLeftClick(prov)
	local editor = regionEditor._editor
	if not editor.settings.needProvinces then return end

	if prov:GetCountry() ~= editor.region:GetCountry() then return end

	local id = prov:GetID()
	local region = prov:GetRegion()
	if not region then return end

	if 
		(editor.settings.takeProvincesFromOther and region:GetID() == editor.region:GetID())
		or (not editor.settings.takeProvincesFromOther and region:GetID() ~= editor.region:GetID())
	then
		return
	end

	if region:GetCapitalProvince() == id then return end

	if editor._selectedProvinces[id] then
		editor._selectedProvinces[id] = nil
	else
		editor._selectedProvinces[id] = prov
	end
end

function regionEditor.handler.provinceRightClick(prov)
	local editor = regionEditor._editor
	if not editor.settings.needCapital then return end

	if prov:GetCountry() ~= editor.region:GetCountry() then return end

	local id = prov:GetID()
	local region = prov:GetRegion()
	if not region then return end

	if 
		(editor.settings.takeProvincesFromOther and region:GetID() == editor.region:GetID())
		or (not editor.settings.takeProvincesFromOther and region:GetID() ~= editor.region:GetID())
	then
		return
	end

	if region:GetCapitalProvince() == id then return end
	if not editor._selectedProvinces[id] then return notify.show('error', 2, 'Нужно сначала выделить эту провинцию!') end

	editor._selectedCapital = id
end