player = player or {}

player._list = player._list or {}
player._map = player._map or {}
player._nameMap = player._nameMap or {}

function player.GetAll()
	return player._list
end

function player.Get(ip, port)
	local hostname = ip
	if port then hostname =  ip .. ':' .. port end

	return player._map[hostname]
end

function player.GetByName(name)
	local hostname = player._nameMap[name]
	if not hostname then return end

	return player.Get(hostname)
end

function player.New(ip, port, peer, name)
	local isHost = ip == true
	local ip, port, peer, name = ip, port, peer, name
	if isHost then
		name = port
		ip = '127.0.0.1'
		port = net.port
		peer = net.server.host
	end

	local meta = ServerPlayer(ip, port, peer, name, isHost)

	if isHost then
		player._hostPlayer = meta
	end

	player._map[meta:GetHostname()] = meta
	player._nameMap[meta:GetName()] = meta:GetHostname()

	player._list[#player._list + 1] = meta

	print('created new player', meta:GetHostname(), meta:GetName())
	return meta
end

function player.Remove(ply)
	local host = ply:GetHostname()
	local name = ply:GetName()

	player._map[host] = nil
	player._nameMap[name] = nil

	for k, v in ipairs(player._list) do
		if v:GetHostname() == host then
			table.remove(player._list, k)
			break
		end
	end

	print('removed player', host)
end