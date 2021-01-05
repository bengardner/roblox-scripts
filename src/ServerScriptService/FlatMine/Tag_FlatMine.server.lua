--[[
Server Tag hander for FlatMine.
This should tag the model that contains all the mine info.
]]
local Utils = require(game.ReplicatedStorage.Utils)
local MineModule = require(game.ServerScriptService.MineModule)
local MineInfoFlat = require(game.ServerScriptService.MineInfoFlat)

TAG_NAME = "FlatMine"

--[[
The Ores folder should contain either BaseParts, Models, or ObjectValues pointing to a BasePart or Model.

The name of the ore is taken from the child node (BasePart/Model/ObjectValue).
It should have children as follows:

   depth_min (IntValue) ore will not appear above this depth
   depth_opt (IntValue) optimum depth for the ore
   depth_max (IntValue) ore will not appear below this depth
   weight    (IntValue) relative weight when picking a random ore

If the child is an ObjectValue, then the target children are first parsed and then the children of the
ObjectValue are parse and override.
]]

local function onTagAdded(model)
	-- do some sanity checks
	if not model:IsA("Model") then
		warn("NOT A MODEL:", model)
		return
	end

	local neck_part = model:FindFirstChild("Entrance")
	local mine_size = model:FindFirstChild("MineSize").Value
	local cube_size = model:FindFirstChild("CubeSize").Value

	local info = MineInfoFlat.new(neck_part, mine_size, cube_size)
	local mine = MineModule.new(model, info)

	print("MINE", mine, info)

	-- info.ore = ore block (already position
	-- info.depth = ore depth
	-- info.grid = grid position
	-- info.xxx = other info
	function info:AddBlock(bi)
		--print("AddBlock: before", bi)
		local mult = 1.01 ^ bi.depth * (1.5 ^ mine.level)
		-- price scales 1% per depth
		bi.Price = math.floor(bi.Price * mult)
		bi.Health = math.floor(bi.Health * mult)
		if bi.single == true then
			bi.Count = 1
		else
			bi.Count = math.floor(2 * mult)
		end
		--print("AddBlock: after", bi)

		local ore = bi.ore
		Utils.AddNumberValue(ore, "Price", bi.Price)
		Utils.AddNumberValue(ore, "Count", bi.Count)
		Utils.AddNumberValue(ore, "Health", bi.Health)
		Utils.AddNumberValue(ore, "Damage", 0)
	end

	-- destroy the neck part
	neck_part.Parent = nil

	print(model, "rebuild")
	mine:RebuildMine()
	print(model, "rebuild done")
end

local function onTagRemoved(model)
	-- this shouldn't happen
	-- TODO: handle the removal of mines (dynamic creation and destruction)
end

require(game.ReplicatedStorage.TagHelper).AddHandler(TAG_NAME, onTagAdded, onTagRemoved)
