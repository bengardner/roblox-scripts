local MineClient = require(game:GetService("Players").LocalPlayer.PlayerScripts.MineClient)

-----------------
--| Variables |--
-----------------

local PlayersService = game:GetService('Players')
local DebrisService = game:GetService('Debris')

local Tool = script.Parent
local Handle = Tool:WaitForChild('Handle')
local Beam = Tool:WaitForChild('Beam')
Beam.Enabled = false

local FireSound = Handle:WaitForChild('Fire')

local function OnEquipped()
	print("OnEquipped")
	Beam.Enabled = false
	Tool.Enabled = true
	MineClient.ToolDeactivate(Beam)
end

local function OnActivated()
	print("OnActivated")
	FireSound:Play()
	MineClient.ToolActivate(Beam)
end

local function OnDeactivated()
	print("OnDeactivated")
	MineClient.ToolDeactivate(Beam)
	FireSound:Stop()
end

local function OnUnequipped()
	print("OnUnequipped")
	MineClient.ToolDeactivate(Beam)
	FireSound:Stop()
end

--------------------
--| Script Logic |--
--------------------

Tool.Equipped:connect(OnEquipped)
Tool.Unequipped:connect(OnUnequipped)
Tool.Activated:connect(OnActivated)
Tool.Deactivated:connect(OnDeactivated)