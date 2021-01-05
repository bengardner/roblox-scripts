local Players = game:GetService("Players")
local PlayerUtils = require(game.ServerScriptService.PlayerUtils)
local ServerStorage = game.ServerStorage

local function giveTool(player, tool)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		tool.Parent = backpack
		return true
	end
	return false
end

local function onCharacterAdded(player, char)
	local head = char:WaitForChild("Head")
	if head ~= nil then
		local light = Instance.new("PointLight")
		light.Parent = head
	end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char.PrimaryPart

	hum.WalkSpeed = 60
	--hrp.Anchored = true

	-- give the fool a tool
	for _, tool in pairs(ServerStorage:WaitForChild("Tools"):GetChildren()) do
		if tool:IsA("Tool") then
			giveTool(player, tool:Clone())
		end
	end
end

PlayerUtils.Register_onCharacterAdded(nil, onCharacterAdded)
