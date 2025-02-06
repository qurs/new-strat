net = net or {}
net.server = net.server or {}
net.server._receives = net.server._receives or {}

function net.server.Receive(name, callback)
	net.server._receives[name] = callback
end

function net.server.OpenServer(port)
	if net.server.host then return notify.show('error', 3, 'Невозможно создать сервер: уже создан!') end

	net.port = port
	net.server.host = enet.host_create('*:' .. port)
end

function net.server.CloseServer()
	if not net.server.host then return end

	net.port = nil

	net.server.host:destroy()
	net.server.host = nil

	player._list = {}
	player._map = {}
	player._nameMap = {}

	collectgarbage()
end

function net.server.Send(receivers, name, ...)
	if not net.server.host then return end

	if type(receivers) == 'table' then
		for _, client in ipairs(receivers) do
			client:Send(name, ...)
		end
	else
		receivers:Send(name, ...)
	end
end

function net.server.Broadcast(name, ...)
	if not net.server.host then return end

	local dataToSend = {}
	dataToSend.name = name
	dataToSend.data = {...}

	local dataToSend = json.encode(dataToSend)
	net.server.host:broadcast(dataToSend)
end

function net.server.Validate(peer, ip, port, validateData)
	if not validateData then return end
	if not validateData.nickname then return end
	if type(validateData.nickname) ~= 'string' then return end
	if utf8.len(validateData.nickname) < 3 then return end

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

	if player.GetByName(validateData.nickname) then
		peer:send(json.encode {
			name = '_disconnect',
			data = 'Игрок с таким именем уже есть!',
		})
		peer:disconnect_later()
		return
	end

	local ply = player.New(ip, port, peer, validateData.nickname)
	hook.Run('PlayerConnected', ply)
end

hook.Add('Think', 'net.server', function()
	local host = net.server.host
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
			return net.server.Validate(peer, ip, port, unpack(info.data or {}))
		end

		local func = net.server._receives[name]
		if not func then return end

		local ply = player.Get(ip, port)
		if not ply then return end

		func(ply, unpack(info.data or {}))
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