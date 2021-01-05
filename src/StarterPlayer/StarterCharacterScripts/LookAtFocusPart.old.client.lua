print("Starting AutoLook script!")
--[[
	NOTE: I am assuming that when the character dies, this script will be removed.
	I assume that means the RenderStepped thing will die
--]]
local RunService = game:GetService("RunService")
local Player = game.Players.LocalPlayer
local char = Player.Character or Player.CharacterAdded:Wait()
local Camera = workspace.CurrentCamera

local Head = char:WaitForChild("Head")
local Neck = Head:WaitForChild("Neck")
local Torso = char:WaitForChild("UpperTorso")
local Waist = Torso:WaitForChild("Waist")
local NeckOriginC0 = Neck.C0
local WaistOriginC0 = Waist.C0

Neck.MaxVelocity = 1/3

local lookat_part = nil

-- make sure we have a humanoid we can work with
local FocusPart = char:FindFirstChild("FocusPart")
if Neck and Waist and Torso and Head and FocusPart then
	print ("Activating looker script")
	RunService.Heartbeat:Connect(function()
		-- TODO: do we need to grab the camera again?

		-- make sure we still have a Head and UpperTorso (needed?)
		-- and make sure the camera is related to the char or player
		if char:FindFirstChild("UpperTorso") and char:FindFirstChild("Head") and
			(Camera.CameraSubject:IsDescendantOf(char) or Camera.CameraSubject:IsDescendantOf(Player)) then

			local CameraCFrame = Camera.CoordinateFrame

			-- check for FocusPart deletion
			if FocusPart.Value and FocusPart.Value.Parent == nil then
				FocusPart.Value = nil
				lookat_part = nil
			end
			if lookat_part then
				local TorsoLookVector = Torso.CFrame.lookVector
				local HeadPosition = Head.CFrame.p
				local Point = lookat_part.Position

				local Distance = (Head.CFrame.p - Point).magnitude
				local Difference = Head.CFrame.Y - Point.Y

				Neck.C0 = Neck.C0:lerp(NeckOriginC0 * CFrame.Angles(-(math.atan(Difference / Distance) * 0.5), (((HeadPosition - Point).Unit):Cross(TorsoLookVector)).Y * 1, 0), 0.5 / 2)
				Waist.C0 = Waist.C0:lerp(WaistOriginC0 * CFrame.Angles(-(math.atan(Difference / Distance) * 0.5), (((HeadPosition - Point).Unit):Cross(TorsoLookVector)).Y * 0.5, 0), 0.5 / 2)
			else
				-- not looking at anything, return to normal pose
				Neck.C0 = Neck.C0:lerp(NeckOriginC0, 0.5 / 2)
				Waist.C0 = Waist.C0:lerp(WaistOriginC0, 0.5 / 2)
			end
		end
	end)
end

FocusPart.Changed:Connect(function()
	local fp = FocusPart.Value
	if fp then
		if fp:IsA("Model") then
			fp = fp.PrimaryPart
		elseif fp:IsA("Tool") then
			local hh = fp:FindFirstChild("Handle")
			if hh then
				fp = hh
			end
		end
	end
	lookat_part = fp
end)
