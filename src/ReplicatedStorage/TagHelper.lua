--[[
Helper for tags.
]]
local CollectionService = game:GetService("CollectionService")

local module = {}

-- TODO: make this a map of lists to allow multiple tag handlers
module.tags = {}

function module.AddHandler(name, onAdded, onRemoved)
	if module.tags[name] ~= nil then
		warn("TAG", name, "already added!")
		return
	end
	if onAdded == nil then
		warn("TAG", name, "requires onAdded!")
		return
	end

	local info = { name=name, onAdded=onAdded, onRemoved=onRemoved }
	module.tags[name] = info

	-- Handle existing tags and connect the tag events.
	-- Attach the callback before iterating in case onAdded() tags another part.
	CollectionService:GetInstanceAddedSignal(name):Connect(function(inst)
		onAdded(inst)
	end)
	for _, inst in pairs(CollectionService:GetTagged(name)) do
		onAdded(inst)
	end

	if onRemoved ~= nil then
		CollectionService:GetInstanceRemovedSignal(name):Connect(function(inst)
			onRemoved(inst)
		end)
	end
end

return module
