--[[
 Coins are stored in player.leaderstate.ZEN
 
 The number is put in the label.
--]]
local LocalPlayerData = require(game.ReplicatedStorage.LocalPlayerData)

local Utils = require(script.Parent.Parent.Parent.Utils)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()
local leaderstats = player:WaitForChild("leaderstats")

local value = LocalPlayerData:GetValue("gems")
local label = script.Parent.Label

local current_value = 0
local target_value = 0
local slew_rate = 0

local function onUpdateValue()
	target_value = value.Value
	if current_value == 0 then
		-- set to 1 less to force an update
		current_value = target_value - 1 
	end
	-- hit target in 6 seconds, slightly more than the 5 sec cashout
	slew_rate = (target_value - current_value) / 6
end

RunService.Heartbeat:Connect(function(elapsed)	
	if target_value ~= current_value then
		if slew_rate > 0 then
			if current_value < target_value then
				current_value = math.min(target_value, current_value + slew_rate * elapsed)
			else
				current_value = target_value
			end
		else -- slew_rate < 0
			if current_value > target_value then
				current_value = math.max(target_value, current_value + slew_rate * elapsed)
			else
				current_value = target_value
			end
		end
		
		-- TODO: handle really big numbers: int64 can be a lot of digits
		label.Text = string.format("%d", current_value)
	end	
end)

-- hook an event hander and kick set the initial value
value.Changed:Connect(onUpdateValue)
onUpdateValue()