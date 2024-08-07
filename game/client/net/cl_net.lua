local enet = require('enet')

net = net or {}

net.host = net.host or enet.host_create()
net.socket = net.socket or require('socket')

net._receives = net._receives or {}

function net.Connect(address)
	if net.server then return notify.show('error', 3, 'Невозможно подключиться: уже подключен') end

	local host = net.host
	local ok, val = pcall(host.connect, host, address)
	
	if ok then
		net.server = val
	else
		print('Cannot connect! Error: ' .. val)
	end
end

function net.Receive(name, callback)
	net._receives[name] = callback
end

function net.Send(name, data)
	if not net.server then return end

	local dataToSend = {}
	dataToSend.name = name
	dataToSend.data = data

	local dataToSend = json.encode(dataToSend)

	net.server:send(dataToSend)
end

function net.GetPing()
	return net.server and net.server:round_trip_time() or -1
end

hook.Add('Think', 'net', function()
	if not net.server then return end

	local event = net.host:service()
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

		local func = net._receives[name]
		if not func then return end

		func(info.data)
	elseif event.type == 'connect' then
		if not NET_CONNECTED then
			NET_CONNECTED = true

			net.Send('_validate', {
				nickname = net.settings.Get('nickname', 'fat'),
			})

			hook.Run('ServerConnected')
		end
	elseif event.type == 'disconnect' then
		NET_CONNECTED = nil

		hook.Run('ServerDisconnected')
	end
end)