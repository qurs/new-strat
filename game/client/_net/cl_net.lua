net.client = net.client or {}
net.client.host = net.client.host or enet.host_create()
net.client._receives = net.client._receives or {}

function net.client.Receive(name, callback)
	net.client._receives[name] = callback
end

function net.client.Connect(address)
	if net.client.connectedServer then return notify.show('error', 3, 'Невозможно подключиться: уже подключен') end

	local host = net.client.host
	local ok, val = pcall(host.connect, host, address)
	
	if ok then
		net.client.connectedServer = val
	else
		print('Cannot connect! Error: ' .. val)
	end
end

function net.client.Disconnect()
	if not net.client.connectedServer then return end

	net.client.connectedServer:disconnect_now()
	net.client.connectedServer = nil
end

function net.client.Send(name, ...)
	if net.IsHost() then
		local func = net.server._receives[name]
		if not func then return end

		local ply = player._hostPlayer
		return func(ply, ...)
	end

	if not net.client.connectedServer then return end

	local dataToSend = {}
	dataToSend.name = name
	dataToSend.data = {...}

	local dataToSend = json.encode(dataToSend)

	net.client.connectedServer:send(dataToSend)
end

function net.client.GetPing()
	return net.client.connectedServer and net.client.connectedServer:round_trip_time() or -1
end

hook.Add('Think', 'net.client', function()
	if not net.client.connectedServer then return end

	local event = net.client.host:service()
	if not event then return end

	if event.type == 'receive' then
		local info = json.decode(event.data)

		if not info then return end
		if not info.name then return end
		
		local name = info.name
		if name == '_disconnect' then
			notify.show('warn', 3.5, 'Ты был отключен: ' .. info.data)
			return
		end

		local func = net.client._receives[name]
		if not func then return end

		func(unpack(info.data or {}))
	elseif event.type == 'connect' then
		if not NET_CONNECTED then
			NET_CONNECTED = true

			net.client.Send('_validate', {
				nickname = net.settings.Get('nickname', 'fat'),
			})

			hook.Run('ServerConnected')
		end
	elseif event.type == 'disconnect' then
		NET_CONNECTED = nil
		net.client.connectedServer = nil

		hook.Run('ServerDisconnected')
	end
end)

hook.Add('ServerDisconnected', 'net', function()
	scene.change('mainmenu')
end)