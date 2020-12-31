-- moves all folders to ServerStorage.
-- This is so we can edit things in the workspace.
local ServerStorage = game.ServerStorage

for _, inst in pairs(script.Parent:GetChildren()) do
	if inst:IsA("Folder") then
		inst.Parent = game.ServerStorage
	end
end

script.Disabled = true
script.Parent = nil