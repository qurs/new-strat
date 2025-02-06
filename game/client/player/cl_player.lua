player = player or {}
player.client = player.client or {}

player.client._list = player.client._list or {}
player.client._map = player.client._map or {}

function player.client.GetAll()
	return player.client._list
end

function player.client.GetByName(name)
	return player.client._map[name]
end

function player.client.GetLocalPlayer()
	return player.client._localPlayer
end

function player.client.New(name, isLocal)
	local meta = setmetatable({}, player.client._meta)
	meta:__init(name, isLocal)

	if isLocal then
		player.client._localPlayer = meta
	end

	player.client._map[name] = meta

	player.client._list[#player.client._list + 1] = meta

	print('created new player', meta:GetName())
	return meta
end

function player.client.Remove(ply)
	local name = ply:GetName()

	player.client._map[name] = nil

	for k, v in ipairs(player.client._list) do
		if v:GetName() == name then
			table.remove(player.client._list, k)
			break
		end
	end

	print('removed player', name)
end

net.client.Receive('createPlayer', function(name, isLocal)
	player.client.New(name, isLocal)
end)

net.client.Receive('removePlayer', function(name)
	player.client.Remove(player.client.GetByName(name))
end)

hook.Add('ServerDisconnected', 'player', function()
	player.client._list = {}
	player.client._map = {}
end)