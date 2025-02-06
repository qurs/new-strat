player = player or {}
player.client = player.client or {}

player.client._meta = player.client._meta or {}
local Player = player.client._meta

Player.__type = 'player'
Player.__index = Player

function Player:__init(name, isLocal)
	self.name = name
	self.isLocal = isLocal
end

function Player:GetName()
	return self.name
end

function Player:IsLocal()
	return self.isLocal
end