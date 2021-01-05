-- this stuff should be activated when the toll is equipped
wait(3)

local LocalPlayerData = require(game.ReplicatedStorage:FindFirstChild("LocalPlayerData"))
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local camera = workspace.CurrentCamera

local drone = workspace:WaitForChild("TestDrone")
local drone_pp = drone.PrimaryPart
print("Found:", drone, "pp", drone_pp)
local attach = drone_pp:FindFirstChild("CameraAttachment", true)

if attach == nil then
	warn("Did not find camera")
	return
end
print("Drone:", drone, "Eye:", attach, attach.Position)
local cf = drone_pp.CFrame:ToWorldSpace(CFrame.new(attach.Position))
print("Drone Pos:", drone_pp.Position, "Eye:", cf.Position)

local char = player.Character
local hrp = char.PrimaryPart

RunService.RenderStepped:Connect(function()
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		print("CameraType:", camera.CameraType)
		camera.CameraType = Enum.CameraType.Scriptable
	end
	local camera_cf = drone_pp.CFrame:ToWorldSpace(attach.CFrame)
	--local startCFrame = CFrame.new((rootPart.CFrame.Position)) * CFrame.Angles(0, math.rad(cameraAngleX), 0) * CFrame.Angles(math.rad(cameraAngleY), 0, 0)
	--local cameraCFrame = startCFrame:ToWorldSpace(CFrame.new(cameraOffset.X, cameraOffset.Y, cameraOffset.Z))
	--local cameraFocus = startCFrame:ToWorldSpace(CFrame.new(cameraOffset.X, cameraOffset.Y, -10000))
	--camera.CFrame = CFrame.new(camera_cf.Position, hrp.Position)
	camera.CFrame = camera_cf
end)
