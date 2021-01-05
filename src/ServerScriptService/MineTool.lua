--[[
This is a server-side helper script for Tools.
]]
local PlayerData = require(game.ServerScriptService.PlayerData)
local Utils = require(game.ReplicatedStorage.Utils)

local MineTool = {}
MineTool.__index = MineTool

function MineTool.new(tool)
	local mt = setmetatable({}, MineTool)
	print("MineTool:", tool)
	mt.tool = tool
	mt.handle = tool:WaitForChild('Handle')

	-- grab configuration items
	mt.damage = tool:WaitForChild("Damage")
	mt.range = tool:WaitForChild("Range")

	mt.target = Utils.GetOrCreate(tool, "Target", "Vector3Value")
	mt.active = Utils.GetOrCreate(tool, "Active", "BoolValue")

	-- TODO: support other tool types?
	mt.beam = tool:WaitForChild("Beam")
	mt.attachment = Instance.new("Attachment", game.Workspace.Terrain)
	mt.beam.Enabled = false

	mt.FireSound = mt.handle:WaitForChild('Fire')

	mt.con = {}

	mt.con.target = mt.target.Changed:Connect(function()
		mt:OnTarget(mt.con.target.Value)
	end)
	mt.con.equipped = tool.Equipped:connect(function()
		mt:OnEquipped()
	end)

	mt.con.unequipped = tool.Unequipped:connect(function()
		mt:OnUnequipped()
	end)

	mt.con.activated = tool.Activated:connect(function()
		mt:OnActivated()
	end)

	mt.con.deactivated = tool.Deactivated:connect(function()
		mt:OnDeactivated()
	end)
	return mt
end

function MineTool:UnRegister()
	self:SetTarget(nil)
	for _, con in pairs(self.con) do
		con:Disconnect()
	end
	self.con = {}
end

function MineTool:OnEquipped()
	self.player = game.Players:GetPlayerFromCharacter(self.tool.Parent)

	local data = PlayerData:Get(self.player)
	data:Set("tool_damage", self.damage.Value)
	data:Set("tool_range", self.range.Value)
	data:Set("tool", self)
	print(self.player, "MineTool:OnEquipped damage:", data:Get("tool_damage"), "range:", data:Get("tool_range"))
end

function MineTool:OnUnequipped()
	local data = PlayerData:Get(self.player)
	self:SetFiring(false)
	data:Set("tool", {})
	data:Set("tool_damage", 0)
	data:Set("tool_range", 0)
	print(self.player, "MineTool:OnUnequipped")
end

function MineTool:OnActivated()
	print("MineTool:OnActivate")
	self.activated = true
end

function MineTool:OnDeactivated()
	print("MineTool:OnDeactivate")
	self.activated = false
	self:SetTarget(nil)
end

function MineTool:OnTarget(tgt)
	print("MineTool:OnTarget", tgt)
	if tgt ~= nil then
		self.attachment.Position = tgt
		self.beam.Attachment1 = self.attachment
		self:SetFiring(true)
	else
		self:SetFiring(false)
	end
end

function MineTool:SetTarget(tgt)
	print("MineTool:SetTarget", tgt)
	if tgt ~= nil then
		self.attachment.Position = tgt
		self.beam.Attachment1 = self.attachment
		self:SetFiring(true)
	else
		self:SetFiring(false)
	end
end

function MineTool:SetFiring(val)
	if val then
		if self.beam.Enabled == false then
			self.beam.Enabled = true
			self.FireSound:Play()
		end
	else
		if self.beam.Enabled == true then
			self.beam.Enabled = false
			self.FireSound:Stop()
		end
	end
end

return MineTool
