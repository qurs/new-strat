xml = xml or {}

local xml2lua = require('xml2lua')
local tree = require('xmlhandler.tree')

function xml.parse(str)
	local handler = tree:new()

	local parser = xml2lua.parser(handler)
	parser:parse(str)

	return handler.root
end

function xml.parseFile(path)
	local str = love.filesystem.read(path)
	return xml.parse(str)
end