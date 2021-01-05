--[[
Dumping ground for generally useful functions that are shared between the client and server.
]]
local module = {}

-- Finds or creates an instance of type Instance name
-- returns the part, whether it was created (and needs init)
function module.get_or_create(parent, name, instance_name)
	local x = parent:FindFirstChild(name)
	if x == nil then
		x = Instance.new(instance_name)
		x.Name = name
		x.Parent = parent
		return x, true
	end
	return x, false
end

return module
