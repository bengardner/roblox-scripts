--[[
Overrides the player camera (temporarily!) when a new camera part is set.

The camera part

]]
-- this stuff should be activated when the tool is equipped
local LocalPlayerData = require(game.ReplicatedStorage:FindFirstChild("LocalPlayerData"))
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local gg = {}

gg.view = LocalPlayerData:GetValue("camera")
gg.last = nil
gg.orig_ctype = nil

local function rs_detach()
	if gg.rs ~= nil then
		gg.rs:Disconnect()
		gg.rs = nil
		-- restore the camera type
		camera.CameraType = gg.orig_ctype
	end
end

local function rs_update()
	if gg.pp == nil or gg.pp.Parent == nil then
		rs_detach()
		return
	end
	camera.CFrame = gg.pp.CFrame:ToWorldSpace(gg.cat.CFrame)
end

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

gg.view.Changed:Connect(function()
	refresh_view()
end)
refresh_view()
