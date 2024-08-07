player = player or {}

player._meta = player._meta or {}
local Player = player._meta

Player.__type = 'player'
Player.__index = Player

function Player:__init(ip, port, peer, name)
	self.ip = ip
	self.port = port
	self.peer = peer
	self.name = name

	self.host = ip .. ':' .. port
end

function Player:GetIP()
	return self.ip
end

function Player:GetPort()
	return self.port
end

function Player:GetHost()
	return self.host
end

function Player:GetPeer()
	return self.peer
end

function Player:GetName()
	return self.name
end

function Player:Send(data)
	local peer = self:GetPeer()
	peer:send(data)
end

function Player:Disconnect(reason)
	local peer = self:GetPeer()

	peer:send(json.encode {
		name = '_disconnect',
		data = reason or 'No reason',
	})
	peer:disconnect_later()
end