ws = ws or {}
ws._clients = ws._clients or {}

local _websocket = require('websocket')

local STATUS = {
	CONNECTING = 0,
	OPEN       = 1,
	CLOSING    = 2,
	CLOSED     = 3,
	TCPOPENING = 4,
}

function ws.new(ip, port, path)
	local client = _websocket.new(ip, port, path)
	ws._clients[#ws._clients + 1] = client

	return client
end

hook.Add('Think', 'websocket', function()
	local toRemove = {}

	for k, client in ipairs(ws._clients) do
		client:update()

		if client.status == STATUS.CLOSED then
			toRemove[#toRemove + 1] = k
		end
	end

	if table.IsEmpty(toRemove) then return end
	for i = #toRemove, 1, -1 do
		local index = toRemove[i]
		table.remove(ws._clients, index)
	end
end)