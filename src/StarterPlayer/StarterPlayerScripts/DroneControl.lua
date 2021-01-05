local LocalPlayerData = require(game.ReplicatedStorage:WaitForChild("LocalPlayerData"))
local DroneLink = require(game.ReplicatedStorage:WaitForChild("DroneLink"))
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local module = {}

-- heartbeat connection
module.con_hb = nil
module.drone_value = LocalPlayerData:GetValue("drone")

local function onInputEnded(inputObject, gameProcessedEvent)
	-- First check if the "gameProcessedEvent" is true
	-- This indicates that another script had already processed the input, so this one can be ignored
	if gameProcessedEvent then return end
	-- Next, check that the input was a keyboard event
	if inputObject.UserInputType == Enum.UserInputType.Keyboard then
		print("A key was released: " .. inputObject.KeyCode.Name)
	end
end
UserInputService.InputEnded:Connect(onInputEnded)

function onHeartbeat(step)
	if module.drone == nil then return end
	local drone = module.drone

	local do_stop = false
	local vec3 = Vector3.new(0,0,0)
	local kk = UserInputService:GetKeysPressed()
	if #kk > 0 then
		local cf = drone.PrimaryPart.CFrame
		for _, inputObject in pairs(kk) do
			if inputObject.UserInputType == Enum.UserInputType.Keyboard then
				if inputObject.KeyCode == Enum.KeyCode.W then
					vec3 = vec3 + cf.LookVector
				elseif inputObject.KeyCode == Enum.KeyCode.S then
					vec3 = vec3 - cf.LookVector
				elseif inputObject.KeyCode == Enum.KeyCode.D then
					vec3 = vec3 + cf.RightVector
				elseif inputObject.KeyCode == Enum.KeyCode.A then
					vec3 = vec3 - cf.RightVector
				elseif inputObject.KeyCode == Enum.KeyCode.Q then
					vec3 = vec3 + cf.UpVector
				elseif inputObject.KeyCode == Enum.KeyCode.E then
					vec3 = vec3 - cf.UpVector
				elseif inputObject.KeyCode == Enum.KeyCode.Z then
					-- uh, rotate CCW
				elseif inputObject.KeyCode == Enum.KeyCode.C then
					-- uh, rotate CW
				elseif inputObject.KeyCode == Enum.KeyCode.X then
					do_stop = true
				end
			end
		end
	end
	if do_stop then
		vec3 = Vector3.new(0,0,0)
		DroneLink:Stop(vec3)
	end
	if vec3 ~= module.last_vec3 then
		print("drone move", vec3)
		DroneLink:Move(vec3)
		module.last_vec3 = vec3
	end
end

function module:Enable()
	if module.con_hb == nil then
		print("Enable")
		module.con_hb = RunService.Heartbeat:Connect(onHeartbeat)
	end
end

function module:Disable()
	if module.con_hb ~= nil then
		print("Disable")
		module.con_hb:Disconnect()
		module.con_hb = nil

		-- REVISIT: should I really stop the drone when we drop control?
		DroneLink:Stop()
	end
end

function module:check_drone_value()
	local nv = self.drone_value.Value
	if nv ~= self.drone then
		print("drone changed", nv, "old", self.drone)
		-- TODO: update camera? cancel mover? server should automatically stop the old drone.
		self.last_vec3 = nil
		self.drone = nv
	end
end

module.drone_value.Changed:Connect(function()
	module:check_drone_value()
end)
module:check_drone_value()

return module
