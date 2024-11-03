pathFind = pathFind or {}
pathFind.AStar = require 'astar'

pathFind._map = {}
pathFind._cachedNodes = {}

local map, cachedNodes, AStar = pathFind._map, pathFind._cachedNodes, pathFind.AStar

function pathFind._getNodeByID(id)
	cachedNodes[id] = cachedNodes[id] or {id = id}
	return cachedNodes[id]
end

function pathFind._getNode(x, y)
	local prov = map.getProvinceByPos(x, y)
	local id = prov:GetID()

	return pathFind._getNodeByID(id)
end

function map:get_neighbors(node, fromNode, callback)
	local prov = country.getProvince(node.id)
	for _, neighbor in ipairs(prov:GetNeighbors()) do
		callback(pathFind._getNodeByID(neighbor:GetID()))
	end
end

function map:get_cost(fromNode, toNode)
	local fromProv = country.getProvince(fromNode.id)
	local fromCenter = fromProv:GetCenter()

	local toProv = country.getProvince(toNode.id)
	local toCenter = toProv:GetCenter()

	return fromCenter:Distance(toCenter)
end

function map:estimate_cost(node, goalNode)
	return self:get_cost(node, goalNode)
end

function pathFind.find(startProv, goalProv, finder)
	local finder = finder or pathFind._finder
	if not finder then return end

	local startID, goalID
	if type(startProv) == 'number' then
		startID, goalID = startProv, goalProv
	else
		startID, goalID = startProv:GetID(), goalProv:GetID()
	end

	local start, goal = pathFind._getNodeByID(startID), pathFind._getNodeByID(goalID)
	local path = finder:find(start, goal)

	if not path then return end

	local result = {}
	for _, node in ipairs(path) do
		result[#result + 1] = country.getProvince(node.id)
	end

	return result
end

function pathFind.customFind(startProv, goalProv, getNeighbors)
	local customMap = {}
	customMap.get_cost = map.get_cost
	customMap.estimate_cost = map.estimate_cost
	customMap.get_neighbors = getNeighbors

	local finder = AStar.new(customMap)
	return pathFind.find(startProv, goalProv, finder)
end

hook.Add('AssetsLoaded', 'pathFinding', function()
	pathFind._finder = AStar.new(map)
end)