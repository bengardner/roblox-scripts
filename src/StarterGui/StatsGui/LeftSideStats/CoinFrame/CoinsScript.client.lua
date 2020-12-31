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

local value = LocalPlayerData:GetValue("coins")
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
	slew_rate = (target_value - current_value) * 2  -- 0.5 seconds 
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
		
		if current_value == target_value then
			local function bigtweendone()
				label:TweenSize(
					UDim2.new(1, 0, 1, 0),  -- endSize (required)
					Enum.EasingDirection.Out,   -- easingDirection (default Out)
					Enum.EasingStyle.Sine,      -- easingStyle (default Quad)
					0.1,                          -- time (default: 1)
					true,                       -- should this tween override ones in-progress? (default: false)
					nil                 -- a function to call when the tween completes (default: nil)
				)
			end
			label:TweenSize(
				UDim2.new(1.2, 0, 1.2, 0),  -- endSize (required)
				Enum.EasingDirection.In,    -- easingDirection (default Out)
				Enum.EasingStyle.Sine,      -- easingStyle (default Quad)
				0.1,                        -- time (default: 1)
				true,                       -- should this tween override ones in-progress? (default: false)
				bigtweendone                -- a function to call when the tween completes (default: nil)
			)
		end
		
		-- TODO: handle really big numbers: int64 can be a lot of digits
		label.Text = string.format("%d", current_value)
	end	
end)

-- hook an event hander and kick set the initial value
value.Changed:Connect(onUpdateValue)
onUpdateValue()