player = player or {}
player._map = player._map or {}

function player.Get(ip, port)
	return player._map[ip .. ':' .. port]
end

function player.New(ip, port, peer, name)
	local meta = setmetatable({}, player._meta)
	meta:__init(ip, port, peer, name)

	player._map[meta:GetHost()] = meta

	return meta
end

function player.Remove(ply)
	local host = ply:GetHost()
	player._map[host] = nil
end