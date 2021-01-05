--[[
This is a DEBUG or TEST module that shows a ray from the player shoulder to the mouse.
I think it only works on PC with mouse. Not sure what I am going to do for mobile.
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- grab local player
local localPlayer = Players.LocalPlayer

-- create beam
local beam = Instance.new("Beam")
beam.Segments = 1
beam.Width0 = 0.2
beam.Width1 = 0.2
beam.Color = ColorSequence.new(Color3.new(1, 0, 0))
beam.FaceCamera = true

-- create attachments
local attachment0 = Instance.new("Attachment")
local attachment1 = Instance.new("Attachment")
beam.Attachment0 = attachment0
beam.Attachment1 = attachment1

-- parent attachments to Terrain
beam.Parent = workspace.Terrain
attachment0.Parent = workspace.Terrain
attachment1.Parent = workspace.Terrain

-- grab the mouse
local mouse = localPlayer:GetMouse()

-- connect to RenderStepped (update every frame)
RunService.RenderStepped:Connect(function()

	-- make sure the character exists
	local character = localPlayer.Character
	if not character then
		-- disable the beam
		beam.Enabled = false
		return
	end

	-- make sure the head exists
	local head = character:FindFirstChild("RightUpperArm")
	if not head then
		-- disable the beam
		beam.Enabled = false
		return
	end

	-- enable the beam
	beam.Enabled = true

	-- define origin and finish
	local origin = head.Position
	local finish = mouse.Hit.p

	-- move the attachments
	attachment0.Position = origin
	attachment1.Position = finish
end)
