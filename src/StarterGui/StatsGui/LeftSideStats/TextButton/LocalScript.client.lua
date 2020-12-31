local MineClient = require(game:GetService("Players").LocalPlayer.PlayerScripts.MineClient)
local btn = script.Parent

btn.Activated:Connect(function()
	MineClient.ExitMine()
end)