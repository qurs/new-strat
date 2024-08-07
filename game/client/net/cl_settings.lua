net = net or {}
net.settings = net.settings or {}
net.settings._map = net.settings._map or {}

function net.settings.Set(key, value)
	net.settings._map[key] = value
end

function net.settings.Get(key, fallback)
	return net.settings._map[key] or fallback
end