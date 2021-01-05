local CollectionService = game:GetService("CollectionService")

local LookAt = {}

LookAt.TAG_NAME = "LookAt"

function LookAt.Add(part, target)
	if target == nil then
		LookAt.Del(part)
		return
	end

	if (part:IsA("BasePart") or part:IsA("Model")) and target:IsA("BasePart") then
		local ov = part:FindFirstChild(LookAt.TAG_NAME)
		if ov == nil then
			ov = Instance.new("ObjectValue")
			ov.Name = LookAt.TAG_NAME
			ov.Value = target
			ov.Parent = part
			CollectionService:AddTag(part, LookAt.TAG_NAME)
		else
			ov.Value = target
		end
	end
end

function LookAt.Del(part)
	local ov = part:FindFirstChild(LookAt.TAG_NAME)
	if ov ~= nil then
		ov:Destroy()
		CollectionService:RemoveTag(part, LookAt.TAG_NAME)
	end
end

return LookAt
