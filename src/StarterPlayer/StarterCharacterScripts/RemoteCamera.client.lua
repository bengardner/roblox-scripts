--[[
This handles changing the camera to be from the perspective of the drone.
It requires "camera" to be set to the attachment that represents the camera.
The parent should be a BasePart (need CFrame info)
The CFrame of that attachment is used to calculate the camera view with this one-liner:
	camera.CFrame = gg.pp.CFrame:ToWorldSpace(gg.cat.CFrame)

If using a "drone control tool" or a "security camera", when "equipped", the player.stats.camera
ObjectValue should be set to the attachment.

TODO: Add something to customize the field of view?
]]
local LocalPlayerData = require(game.ReplicatedStorage:FindFirstChild("LocalPlayerData"))
local RunService = game:GetService("RunService")
local player = LocalPlayerData.player
local camera = workspace.CurrentCamera

local gg = {}

-- grab the ObjectValue that will hold the camera attachment
gg.view = LocalPlayerData:GetValue("camera")
if gg.view == nil then
	warn("Did not find camera ObjectValue")
	return
end

-- note that a few status vars will be used (useless code)
gg.last = nil
gg.orig_ctype = nil

-- detach from RenderStep, as we no longer are using an alternate perspective.
local function rs_detach()
	if gg.rs ~= nil then
		gg.rs:Disconnect()
		gg.rs = nil
		gg.cat = nil
		gg.pp = nil
		-- restore the camera type
		camera.CameraType = gg.orig_ctype
	end
end

local function rs_update()
	-- detect when the part is destroyed
	if gg.pp == nil or gg.cat == nil or gg.pp.Parent == nil then
		rs_detach()
	end

	-- This is the important part
	camera.CFrame = gg.pp.CFrame:ToWorldSpace(gg.cat.CFrame)
end

-- Setup the gg info and attach the RenderStep
local function rs_attach(cat)
	if gg.rs == nil then
		gg.pp = cat.Parent
		gg.cat = cat
		if gg.pp == nil or gg.pp.Parent == nil then
			return
		end

		gg.orig_ctype = camera.CameraType
		camera.CameraType = Enum.CameraType.Scriptable

		gg.rs = RunService.RenderStepped:Connect(rs_update)
	end
end

-- this is called whenever the ObjectValue may have changed.
local function refresh_view()
	local vcur = gg.view.Value
	if gg.last ~= vcur then
		gg.last = vcur
		if vcur ~= nil then
			rs_attach(vcur)
		else
			rs_detach()
		end
	end
end

-- connect the Changed event and call the function once, just in case the camera has been set up.
gg.view.Changed:Connect(function()
	refresh_view()
end)
refresh_view()
