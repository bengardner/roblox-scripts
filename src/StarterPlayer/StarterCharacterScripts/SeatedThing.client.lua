local DroneControl = require(game:GetService("Players").LocalPlayer.PlayerScripts.DroneControl)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

DroneControl:Disable()

function onSeated(isSeated, seat)
	if isSeated then
		print("I'm now sitting on: " .. seat.Name .. "!")
		DroneControl:Enable()
	else
		print("I'm not sitting on anything")
		DroneControl:Disable()
	end
end
humanoid.Seated:Connect(onSeated)
