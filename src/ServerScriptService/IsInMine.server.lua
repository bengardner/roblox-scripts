local Players = game:GetService("Players")
local MineModule = require(game.ServerScriptService.MineModule)

local last_pm = {}
while true do
	wait(3)
	local cur_pm = {}
	for _, player in pairs(Players:GetPlayers()) do
		local char = player.Character
		if char ~= nil and char.PrimaryPart ~= nil then
			local mm = MineModule:FindMineForPosition(char.PrimaryPart.Position, last_pm[player])
			cur_pm[player] = mm
			if mm ~= nil and last_pm[player] ~= mm then
				print("Player", player, "is in", mm.name)
			elseif mm == nil and last_pm[player] ~= nil then
				print("Player", player, "is NOT in a mine")
			end
		else
			print("Player", player, "is not alive")
		end
	end
	last_pm = cur_pm
end
