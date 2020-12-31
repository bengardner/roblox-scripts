--[[
Misc utils that don't belong anywhere in particular.
]]
local module = {}

function module.GetOrCreate(parent, name, typename)
	local xx = parent:FindFirstChild(name)
	if xx == nil then
		xx = Instance.new(typename)
		xx.Name = name
		xx.Parent = parent		
	end
	return xx
end

function module.AddValue(parent, name, value, vtype)
	local vv = Instance.new(vtype)
	vv.Name = name
	vv.Value = value
	vv.Parent = parent
	return vv
end

function module.AddNumberValue(parent, name, value)
	return module.AddValue(parent, name, value, "NumberValue")
end

function module.AddIntValue(parent, name, value)
	return module.AddValue(parent, name, value, "IntValue")
end

function module.AddStringValue(parent, name, value)
	return module.AddValue(parent, name, value, "StringValue")
end

function module.GetMassOfModel(model)
	local mass = 0
	for i, v in pairs(model:GetChildren()) do
		if v:IsA('BasePart') then
			mass = mass + v:GetMass()
		end
	end
	return mass
end

return module
