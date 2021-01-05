--[[
Tool handling:
 - the tool fires whenever is has a block within range
 - activating the tool sets beam.Enabled
 - deactivating the tool clears beam.Enabled
 - moving the mouse around picks a block and sets Attachment1, which shows the beam
 - an event is sent whenever the Attachment1 is changed

Tool activation is as follows:
 - module.tool_activated is a bool that records whether the tool is active.
 - module.tool_firing is a bool that indicates whether the tool is firing
   * module.tool_activated and in-range, valid target
]]

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game:GetService("Players").LocalPlayer
local MineEvents = require(ReplicatedStorage:FindFirstChild("MineEvents"))
local LocalPlayerData = require(ReplicatedStorage:FindFirstChild("LocalPlayerData"))

----------------------------------------------------------------

local module = {}
module.__index = module

module.tool_activated = false
module.tool_firing = false
module.block = {}

module.target_attachment = Instance.new("Attachment", game.Workspace.Terrain)

----------------------------------------------------------------
-- Set functions to link the GUI elements
--

function module.SetGui(gui)
	module.gui = gui
	-- REVISIT: scan for the GUI elements with FindFirstChild(name, true) ?
end

function module.SetBlockFrame(frame)
	module.block.frame = frame
end

function module.SetBlockTitle(textlabel)
	module.block.title = textlabel
end

function module.SetBlockValue(textlabel)
	module.block.value = textlabel
end

function module.SetBlockDepth(textlabel)
	module.block.depth = textlabel
end

function module.SetBlockProgBar(fr)
	module.block.progbar = fr
end

function module.SetBlockProgText(textlabel)
	module.block.progtext = textlabel
end

----------------------------------------------------------------
-- Input hooks, Enter and Leave
-- these should be activated when the player changes location.

function module.EnterMine()
	-- reset the selection, hide the block info, and show the GUI
	module.block.frame.Visible = false
	module.gui.Enabled = true
end

function module.LeaveMine()
	module.gui.Enabled = false
end

function module.ExitMine()
	print("MineClient.ExitMine()")
	MineEvents.ClientExitMine()
end

----------------------------------------------------------------
-- Block selection
--

-- Setup the selection box
module.Selection = Instance.new("SelectionBox")
module.Selection.Color3 = Color3.new(0.6,0.6,0,6)
module.Selection.Parent = game.Workspace.Terrain
module.Selection.Transparency = 0
module.Selection.SurfaceTransparency = 0.8

function GetValue(parent, name, defval)
	local vv = parent:FindFirstChild(name)
	if vv ~= nil then
		return vv.Value
	end
	warn("GetValue: failed to get", name, "on", parent)
	return defval
end

function ValidateTarget(target)
	if target == nil then
		return nil
	end

	local char = player.Character
	if char == nil or char.PrimaryPart == nil then
		return nil
	end

	local real_target
	local tgt_pp
	if target.Parent:IsA("Model") then
		real_target = target.Parent
		tgt_pp = real_target.PrimaryPart
		--print("Target", target, "is a model", tgt_pp)
	elseif target:IsA("BasePart") then
		real_target = target
		tgt_pp = target
		--print("Target is a basepart", tgt_pp)
	end

	local gp = real_target:FindFirstChild("GridPos")
	if gp == nil then
		return nil
	end

	local info = {
		target = target,   -- this is the block that we are pointing at -- not needed
		ore = real_target, -- this is the part or model for the ore block
		tgt_pp = tgt_pp,   -- this is the primary part that should be 'selected'
		price = GetValue(real_target, "Price"),
		count = GetValue(real_target, "Count", 0),
		health = GetValue(real_target, "Health"),
		damage = GetValue(real_target, "Damage"),
		char = char,
		grid = gp.Value,
	}

	return info
end

local color_green = Color3.fromRGB(0,255,0)
local color_red = Color3.fromRGB(255,0,0)

function module.SelectBlock(target)
	local info = ValidateTarget(target)
	module.target = info

	if info ~= nil then
		local dist = (info.char.PrimaryPart.Position - info.tgt_pp.Position).Magnitude
		local tool_range = LocalPlayerData:Get("tool_range")
		if dist > tool_range then
			module.block.title.Text = string.format("Too Far Away %d vs %d", dist, tool_range)
			module.Selection.Color3 = color_red
			module.Selection.SurfaceColor3 = color_red
			info.in_range = false
		else
			module.block.title.Text = string.format("%s - %d", info.ore.Name, info.count)
			module.Selection.Color3 = color_green
			module.Selection.SurfaceColor3 = color_green
			info.in_range = true
		end

		module.block.value.Text = string.format("$ %d", info.price)
		module.block.depth.Text = string.format("depth %d", info.grid.Y)

		module.block.progtext.Text = string.format("%d / %d", info.damage, info.health)
		if info.health > 0 then
			local pct = info.damage / info.health
			module.block.progbar.Size = UDim2.new(pct, 0, 1, 0)
		else
			module.block.progbar.Size = UDim2.new(1, 0, 1, 0)
		end

		local lap = info.char:FindFirstChild("LookAtPart")
		if lap ~= nil then
			lap.Value = info.tgt_pp
		end

		module.Selection.Adornee = info.tgt_pp
		module.block.frame.Visible = true

	else
		if module.block.frame then
			module.block.frame.Visible = false
		end
		module.Selection.Adornee = nil
	end

	module.UpdateToolStatus()
end

--
function module.ToolUpdateBeam()
	if module.beam ~= nil then
		if module.target then
			module.target_attachment.Position = module.target.tgt_pp.Position
			--module.beam.Attachment1 = module.target_attachment
			--module.beam.Enabled = true
		else
			--module.beam.Attachment1 = nil
		end
	end
end

function module.ToolActivate(beam)
	-- turn off old beam (needed?)
	if module.beam ~= nil then
		--module.beam.Enabled = false
		--module.beam.Attachment1 = nil
	end
	module.beam = beam

	module.tool_activated = (beam ~= nil)
	module.UpdateToolStatus()
end

function module.ToolDeactivate()
	module.ToolActivate(nil)
end

function module.UpdateToolStatus()
	if module.tool_activated and module.target and module.target.in_range then
		module.target_attachment.Position = module.target.tgt_pp.Position
		if module.beam then
			--module.beam.Attachment1 = module.target_attachment
			--module.beam.Enabled = true
		end

		if module.last_target == nil or module.last_target.ore ~= module.target.ore then
			print("Firing ClientMineBlock")
			MineEvents.ClientMineBlock(module.target.ore)
			module.last_target = module.target
		end
	else
		if module.beam then
			--module.beam.Enabled = false
		end
		if module.last_target ~= nil then
			MineEvents.ClientMineBlock(nil)
			module.last_target = nil
		end
	end
end

return module
