ClientPlayer = class('ClientPlayer')

function ClientPlayer:init(name, isLocal)
	self.name = name
	self.isLocal = isLocal
end

function ClientPlayer:GetName()
	return self.name
end

function ClientPlayer:IsLocal()
	return self.isLocal
end