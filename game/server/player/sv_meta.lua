player = player or {}

player._meta = player._meta or {}
local Player = player._meta

Player.__type = 'player'
Player.__index = Player

function Player:__init(ip, port, peer, name, isHost)
	self.ip = ip
	self.port = port
	self.peer = peer
	self.name = name

	self.isHost = isHost
	self.hostname = ip .. ':' .. port
end

function Player:IsHost()
	return self.isHost
end

function Player:GetIP()
	return self.ip
end

function Player:GetPort()
	return self.port
end

function Player:GetHostname()
	return self.hostname
end

function Player:GetPeer()
	return self.peer
end

function Player:GetName()
	return self.name
end

function Player:Send(name, ...)
	local data = {...}

	if self:IsHost() then return end

	local peer = self:GetPeer()
	peer:send(json.encode {
		name = name,
		data = data,
	})
end

function Player:Disconnect(reason)
	if self:IsHost() then return end

	local peer = self:GetPeer()

	peer:send(json.encode {
		name = '_disconnect',
		data = reason or 'No reason',
	})
	peer:disconnect_later()
end