ServerPlayer = class('ServerPlayer')

function ServerPlayer:init(ip, port, peer, name, isHost)
	self.ip = ip
	self.port = port
	self.peer = peer
	self.name = name

	self.isHost = isHost
	self.hostname = ip .. ':' .. port
end

function ServerPlayer:IsHost()
	return self.isHost
end

function ServerPlayer:GetIP()
	return self.ip
end

function ServerPlayer:GetPort()
	return self.port
end

function ServerPlayer:GetHostname()
	return self.hostname
end

function ServerPlayer:GetPeer()
	return self.peer
end

function ServerPlayer:GetName()
	return self.name
end

function ServerPlayer:Send(name, ...)
	local data = {...}

	if self:IsHost() then return end

	local peer = self:GetPeer()
	peer:send(json.encode {
		name = name,
		data = data,
	})
end

function ServerPlayer:Disconnect(reason)
	if self:IsHost() then return end

	local peer = self:GetPeer()

	peer:send(json.encode {
		name = '_disconnect',
		data = reason or 'No reason',
	})
	peer:disconnect_later()
end