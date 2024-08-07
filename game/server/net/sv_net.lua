local enet = require('enet')

net = net or {}
net.socket = require('socket')

function net.OpenServer(port)
	net.host = enet.host_create('0.0.0.0:' .. port)
end

local _receives = {}

function net.Receive(name, callback)
	_receives[name] = callback
end

function net.Send(receivers, name, data)
	if not net.host then return end

	local dataToSend = {}
	dataToSend.name = name
	dataToSend.data = data

	local dataToSend = json.encode(dataToSend)

	if type(receivers) == 'table' then
		for _, client in ipairs(receivers) do
			client:Send(dataToSend)
		end
	else
		receivers:Send(dataToSend)
	end
end

function net.Broadcast(name, data)
	if not net.host then return end

	local dataToSend = {}
	dataToSend.name = name
	dataToSend.data = data

	local dataToSend = json.encode(dataToSend)

	net.host:broadcast(dataToSend)
end

function net.Validate(peer, ip, port, validateData)
	if not validateData then return end
	if not validateData.nickname then return end

	timer.Remove(tostring(peer) .. 'validate')

	local ply = player.Get(ip, port)
	if ply then
		peer:send(json.encode {
			name = '_disconnect',
			data = 'This host already connected!',
		})
		peer:disconnect_later()
		return
	end

	local ply = player.New(ip, port, peer, validateData.nickname)
	hook.Run('PlayerConnected', ply)
end

hook.Add('Think', 'net', function()
	local host = net.host
	if not host then return end

	local event = host:service()
	if not event then return end

	local peer = event.peer
	local host = tostring(peer)
	local ip = host:match('^([%d%.]+):')
	local port = tonumber(host:match(':([%d]+)$'))

	if not ip or not port then return end

	if event.type == 'receive' then
		local info = json.decode(event.data)

		if not info then return end
		if not info.name then return end
		
		local name = info.name
		if name == '_validate' then
			return net.Validate(peer, ip, port, info.data)
		end

		local func = _receives[name]
		if not func then return end

		local ply = player.Get(ip, port)
		if not ply then return end

		func(ply, info.data)
	elseif event.type == 'connect' then
		local ply = player.Get(ip, port)
		if ply then
			peer:send(json.encode {
				name = '_disconnect',
				data = 'This host already connected!',
			})
			peer:disconnect_later()
			return
		end

		timer.Create(host .. 'validate', 3, 1, function()
			if not peer then return end
			if player.Get(ip, port) then return end

			peer:send(json.encode {
				name = '_disconnect',
				data = 'Validation error',
			})
			peer:disconnect_later()
		end)
	elseif event.type == 'disconnect' then
		local ply = player.Get(ip, port)
		if not ply then return end

		hook.Run('PlayerDisconnected', ply)
		player.Remove(ply)
	end
end)