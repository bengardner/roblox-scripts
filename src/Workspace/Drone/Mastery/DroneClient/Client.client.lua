wait(1)
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local cam = workspace.CurrentCamera
local server = script:WaitForChild("Object")

local use = false

game:GetService("RunService").Stepped:connect(function()
	if use == true then
		server.Value.Mastery.Event:FireServer("CoFrame",cam.CoordinateFrame)
		server.Value.Mastery.Event:FireServer("CoFrameLook",cam.CoordinateFrame.lookVector)
	end
end)


game:GetService("UserInputService").InputBegan:connect(function(input,process)
	if use == false then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.W and process == false then
			server.Value.Mastery.Event:FireServer("W")
		elseif input.KeyCode == Enum.KeyCode.S and process == false then
			server.Value.Mastery.Event:FireServer("S")
		elseif input.KeyCode == Enum.KeyCode.Q and process == false then
			server.Value.Mastery.Event:FireServer("Q")
		elseif input.KeyCode == Enum.KeyCode.E and process == false then
			server.Value.Mastery.Event:FireServer("E")
		elseif input.KeyCode == Enum.KeyCode.R and process == false then
			server.Value.Mastery.Event:FireServer("Arm")
		end
	end
end)

script.Parent.Selected:connect(function()
	use = true
	server.Value.Mastery.Event:FireServer("Selected",player)
	cam.CameraSubject = server.Value.Core
end)

script.Parent.Deselected:connect(function()
	use = false
	server.Value.Mastery.Event:FireServer("Deselected",player)
	cam.CameraSubject = player.Character.Humanoid
end)

mouse.Button1Down:connect(function()
	if use == false then return end
	server.Value.Mastery.Event:FireServer("FireStandard",mouse.Origin)
end)

mouse.Move:connect(function()
	if use == true then
		server.Value.Mastery.Event:FireServer("MouseHit",mouse.Hit)
	end
end)
