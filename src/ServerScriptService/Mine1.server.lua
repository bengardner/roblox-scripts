--[[
Defines a mine.

  * folder containing blocks
    + "border" defines all the unminable border blocks
    + any other name is an ore, named how it should be displayed
    + each block may have these children:
      - BoolValue : Transparent - indicates whether the cube is transparent
      - IntValue  : Weight - used to randomly pick one

]]
local PlayerData = require(game.ServerScriptService.PlayerData)

local MineEvents = require(game.ReplicatedStorage:WaitForChild("MineEvents"))
local MineModule = require(game.ServerScriptService.MineModule)
local MineInfoFlat = require(game.ServerScriptService.MineInfoFlat)

local neck_part = game.Workspace:WaitForChild("mines"):WaitForChild("mine1"):WaitForChild("Entrance")
local mine_size = Vector3.new(50, 100, 50) -- for testing
local cube_size = Vector3.new(6, 6, 6)
local info = MineInfoFlat.new(neck_part, mine_size, cube_size)

neck_part.Transparency = 1
neck_part.CanCollide = false
neck_part.Parent = nil

local cd_ref = Instance.new("ClickDetector")

--[[
	name = name of the cube (ore) for display, also the model/part name
	weight = relative weight when picking a random ore
	depth_min = ore will not appear above this depth
	depth_opt = optimum depth for the ore
	depth_max = ore will not appear below this depth
]]
local cubes = {
	{ name = "Ore1", weight = 500 },
	{ name = "Ore2", weight = 200}, --depth_min = 20, depth_max = 100 },
	{ name = "Ore3", weight = 50, transparent = true }, --depth_min = 30, depth_max = 1000, depth_opt = 50 },
	{ name = "Heart Crystal", weight = 50, transparent = true }, --depth_min = 30, depth_max = 1000, depth_opt = 50 },
}

local mine = MineModule.new("mine1", info, cubes)
print("mine1 created")

local function AddIntValue(parent, name, value)
	local vv = Instance.new("NumberValue")
	vv.Name = name
	vv.Value = value
	vv.Parent = parent
end

function info:AddBlock(ore, depth)
	AddIntValue(ore, "Price", (1 + depth) * 10)
	AddIntValue(ore, "Count", 3)
	AddIntValue(ore, "Health", 20)
	AddIntValue(ore, "Damage", 0)

	--[[
	-- add a click detector until I get the other stuff working
	local cd = cd_ref:Clone()
	if ore:IsA("Model") then
		cd.Parent = ore.PrimaryPart
	else
		cd.Parent = ore
	end
	cd.MouseClick:Connect(function(player)
		print("Player", player, "clicked on", ore, "at", ore:FindFirstChild("GridPos").Value)
		mine:Zap(ore)
	end)
	]]
end

print("mine1 rebuild")
mine:RebuildMine()
print("mine1 rebuild done")

--[[
--------------------------------------------------------------------------------
-- FIXME: this should be a generic module for all mines. (in MineModule)

function block_do_damage(player, block, dt)
	local data = PlayerData:Get(player)

	local hvv = block:FindFirstChild("Health")
	local cvv = block:FindFirstChild("Count")
	local dvv = block:FindFirstChild("Damage")

	if hvv and cvv and dvv then
		local hv = hvv.Value
		local cv = cvv.Value
		local dv = dvv.Value

		local damage = data:Get("tool_damage") * dt
		print("Player", player, "does", damage, "damage to", block)

		local dv = dv + damage
		while dv >= hv and cv > 0 do
			cv = cv - 1
			dv = dv - hv
		end

		if cv <= 0 then
			print("Player", player, "destroyed", block)
			mine:Zap(block)
			data:coins_add(7)
		else
			local ff = block:FindFirstChild("players")
			if ff == nil then
				ff = Instance.new("Folder")
				ff.Name = "players"
				ff.Parent = block
			end
			local pu = ff:FindFirstChild(player.Name)
			if pu == nil then
				pu = Instance.new("NumberValue")
				pu.Name = player.Name
				pu.Parent = ff
			end
			pu.Value = pu.Value + damage
			cvv.Value = cv
			dvv.Value = dv
			return true
		end
	end
	return false
end

-- key:player val:{block=block, tstamp=tstamp}
local active_miners = {}

MineEvents.ServerAttachMine(function(player, block, tstamp)
	print("MineEvent", player, block, tstamp)
	local char = player.Character
	if char == nil then
		block = nil
	end

	-- TODO: retrieve or look up the tool that the player has equipped to determine the
	-- mine speed and power.

	local old = active_miners[player]
	if old ~= nil then
		-- player was working on something
		if old.block == block then
			-- same block - shouldn't get this message!
			print("Player", player, "still working on", block)
			return
		end

		-- different block, calculate the damage done to the previous block
		local dt = tstamp - old.tstamp
		print("Player", player, "no longer working on", old.block)
		block_do_damage(player, old.block, dt)
	end
	if block ~= nil then
		active_miners[player] = { block=block, tstamp=tstamp }
	else
		print("Player", player, "not working")
		active_miners[player] = nil
	end
end)

while true do
	wait(0.2)

	local now = os.clock()
	for player, ii in pairs(active_miners) do
		local dt = now - ii.tstamp
		if block_do_damage(player, ii.block, dt) then
			ii.tstamp = now
		else
			-- block was destroyed
			active_miners[player] = nil
		end
	end
end
]]
