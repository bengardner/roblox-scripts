-- moves all folders to ServerStorage.
-- This is so we can edit things in the workspace.
local new_parent = game.ServerStorage

for _, inst in pairs(script.Parent:GetChildren()) do
	if inst:IsA("Folder") then
		inst.Parent = new_parent
	end
end

script.Disabled = true
script.Parent = nil
