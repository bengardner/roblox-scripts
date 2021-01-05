local Clicker = script.Parent.Button:WaitForChild('ClickDetector')
local Drone = script.Parent.Parent:WaitForChild('Drone')
Drone.Parent = game.ServerStorage
local SpawnCoolDown = 10
local Ready = true

Clicker.MouseClick:connect(function(Player)
	if Ready == true and Player.Character and Player.Character:FindFirstChild(Drone.Name) == nil then
		Ready = false
		local bool,arg = pcall(function()
			Clicker.MaxActivationDistance = 0
			local NewDrone = Drone:clone()
			NewDrone.User.Value = Player
			NewDrone.Parent = Player.Character
			NewDrone.Core.CFrame = script.Parent.Center.CFrame*CFrame.new (0,7,0)
			NewDrone.Mastery.Disabled = false
		end)
		if bool == false then print(arg) end
		delay(SpawnCoolDown,function()
			Ready = true
			Clicker.MaxActivationDistance = 10
		end)
	end
end)
