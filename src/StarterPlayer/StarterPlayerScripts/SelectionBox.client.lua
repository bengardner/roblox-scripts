--[[
Uses the mouse to select a block.
]]
local MineClient = require(game:GetService("Players").LocalPlayer.PlayerScripts:WaitForChild("MineClient"))
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer

local mouse = player:GetMouse() --Getting the player's mouse

RunService.Heartbeat:Connect(function()
	MineClient.SelectBlock(mouse.Target)
end)
