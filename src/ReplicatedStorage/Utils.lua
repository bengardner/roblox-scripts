--[[
Misc utils that don't belong anywhere in particular.
]]
local module = {}

-- Get or create a child of a particular type.
-- This is mainly for folders.
function module.GetOrCreate(parent, name, typename)
	local xx = parent:FindFirstChild(name)
	if xx == nil then
		xx = Instance.new(typename or "Folder")
		xx.Name = name
		xx.Parent = parent
	end
	return xx
end

-- Create and add a value instance. No check if one already exists.
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

-- recursively add up the mass of the model using part:GetMass()
function module.GetMassOfModel(model)
	local mass = 0
	if model:IsA('BasePart') then
		mass = mass + model:GetMass()
	end
	for i, v in pairs(model:GetDescendants()) do
		if v:IsA('BasePart') then
			mass = mass + v:GetMass()
		end
	end
	return mass
end

return module
