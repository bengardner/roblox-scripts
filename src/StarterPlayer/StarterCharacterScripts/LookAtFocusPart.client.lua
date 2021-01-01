--[[
This script will look at a focus part as long as the focus part is visible (in front of the target)
This makes the player character look at the part. R15 only.

This script creates an ObjectValue named "LookAtPart" if the server hasn't already done so.
Set the Value to a model or basepart.
NOTE that if the server does not set LookAtPart, then it cannot tell the client to look at a part.
]]
local RunService = game:GetService("RunService")
local Player = game.Players.LocalPlayer
local char = Player.Character or Player.CharacterAdded:Wait()

-- the last seen LookAtPart.Value
local lookat_value = nil
-- the last resolved target part
local lookat_part = nil

local Head = char:WaitForChild("Head")
local Neck = Head:WaitForChild("Neck")
local Torso = char:WaitForChild("UpperTorso")
local Waist = Torso:WaitForChild("Waist")
local hrp = char.PrimaryPart
local NeckOriginC0 = Neck.C0
local WaistOriginC0 = Waist.C0

-- Create the LookAtPart, if needed (the server may have created it)
local LookAtPartValue = char:FindFirstChild("LookAtPart")
if LookAtPartValue == nil then
	LookAtPartValue = Instance.new("ObjectValue")
	LookAtPartValue.Name = "LookAtPart"
	LookAtPartValue.Parent = char
end

local function find_first_visible_part(parent)
	for _, part in pairs(parent:GetChildren()) do
		if part:IsA("BasePart") and part.Transparency < 0.9 then
			return part
		end
	end
	return nil
end

--[[
"Resolves" the target part as follows:
 - if it is a BasePart, then return that
 - if it is a Model:
   + return the PrimaryPart, if present.
   + return a child named "Head", if present
   + return the first BasePart in the model that is not transparent
 - if it is a Tool:
   + return the part named "Handle", if present
   + return the first BasePart in the model that is not transparent

This is done when the current target becomes invalid OR LookAtPart.Value changes.
]]
local function lookat_resolve(target)
	if target ~= nil then
		local xx
		if target:IsA("BasePart") then
			xx = target

		elseif target:IsA("Model") then
			xx = target.PrimaryPart
			if xx == nil then
				xx = target:FindFirstChild("Head")
				if xx == nil then
					xx = find_first_visible_part(target)
				end
			end

		elseif target:IsA("Tool") then
			local xx = target:FindFirstChild("Handle")
			if xx == nil then
				xx = find_first_visible_part(target)
			end
		end
		return xx
	end
	return nil
end

-- this is used to NOT override the motors once we are no longer looking at a target.
local restore_time = 0
local ov_conn = nil

local function lookat_heartbeat(step)
	if Torso.Parent and Head.Parent then
		local ovv = LookAtPartValue.Value

		-- check for deleted target
		if ovv ~= nil and ovv.Parent == nil then
			LookAtPartValue.Value = nil
			lookat_part = nil
		end

		-- check for deleted part
		if lookat_part ~= nil and lookat_part.Parent == nil then
			lookat_part = nil
		end

		if ovv ~= lookat_value then
			lookat_part = lookat_resolve(ovv)
			lookat_value = ovv
		end

		local tgt = lookat_part
		-- don't look if behind player
		if tgt ~= nil then
			-- using unit vectors, so the dot is cos(a). 0.3 is about 33 deg behind.
			local dd = hrp.CFrame.lookVector:Dot((hrp.Position - tgt.Position).Unit)
			if dd > 0.3 then
				--print('DOT:', dd)
				tgt = nil
			end
		end

		if tgt ~= nil then
			local TorsoLookVector = Torso.CFrame.lookVector
			local HeadPosition = Head.CFrame.p
			local Point = tgt.Position
			local tgt_vec = HeadPosition - Point
			local tgt_unit = tgt_vec.Unit

			local Distance = tgt_vec.magnitude
			--local YDifference = Head.CFrame.Y - Point.Y
			local YDifference = tgt_vec.Y
			local atd = -(math.atan(YDifference / Distance) * 0.5)
			local hpy = (tgt_unit:Cross(TorsoLookVector)).Y

			Neck.C0 = Neck.C0:lerp(NeckOriginC0 * CFrame.Angles(atd, hpy * 1, 0), 0.25)
			Waist.C0 = Waist.C0:lerp(WaistOriginC0 * CFrame.Angles(atd, hpy * 0.5, 0), 0.25)

			-- give 2 seconds to go back to normal
			restore_time = 2
			--print("LOOKING")
			return
		end

		--print("NOT LOOKING")

		-- not looking at anything, return to normal pose
		Neck.C0 = Neck.C0:lerp(NeckOriginC0, 0.25)
		Waist.C0 = Waist.C0:lerp(WaistOriginC0, 0.25)

		if lookat_part == nil then
			-- lerp to the rest position for a little while then let animations take over
			restore_time = restore_time - step
			if restore_time < 0 then
				if ov_conn ~= nil then
					print("hb_Disconnect")
					ov_conn:Disconnect()
					ov_conn = nil
				end
			end
		end
	end
end

--[[
Handle a change in the target value, connect or disconnect the heartbeat function.
]]
local function handle_new_target()
	--print("handle_new_target: ov_conn:", ov_conn, "lpv:", LookAtPartValue.Value)
	if LookAtPartValue.Value ~= nil and ov_conn == nil then
		--print("**** hb_Connect")
		ov_conn = RunService.Heartbeat:Connect(lookat_heartbeat)
	end
end

-- start calling the heartbeat function if we have the required parts
if Neck and Waist and Torso and Head and LookAtPartValue then
	Neck.MaxVelocity = 1/3

	LookAtPartValue.Changed:Connect(function()
		handle_new_target()
	end)
	handle_new_target()
end
