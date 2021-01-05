--[[
A simple infinite mine module.

Notes:
 - Ores are stored in a folder. Then have VALUE children to

 - Depth is positive, but negated when translated to Y.

TODO:
 * add support for transparent blocks
   - if a new block is transparent, then populate around it as if it were removed
 * Add a memory limit to clear and reset the mine.
 * Add teleport button
 * Add fall detection (can't use Workspace.FallenPartsDestroyHeight for deep mines)
 * Add an absolute max horizontal extent for the mine, so they can be put next to each other?

]]

local MineEvents = require(game.ReplicatedStorage:WaitForChild("MineEvents"))
local PlayerData = require(game.ServerScriptService.PlayerData)
local Choice = require(game.ReplicatedStorage.Choice)
local Utils = require(game.ReplicatedStorage.Utils)

local ref_cd = Instance.new("ClickDetector")
--[[
local function GetOrCreate(parent, name, typename)
	local xx = parent:FindFirstChild(name)
	if xx == nil then
		xx = Instance.new(typename)
		xx.Name = name
		xx.Parent = parent
	end
	return xx
end
]]
local mine_root = Utils.GetOrCreate(game.Workspace, "mine_cubes", "Folder")

--------------------------------------------------------------------------------
-- The ore cache is a global resource shared across all mines.
-- We have two required ore names "Default" and "Border".
--
local ore_folder = game.ServerStorage:WaitForChild("Ores")
local default_ore -- = ore_folder:WaitForChild("Default")
local border_ore --= ore_folder:WaitForChild("Border")

local ore_cache = {} -- key=name, val=part in ServerStorage

local function ore_get(name)
	if name == nil then
		warn("NIL ORE NAME")
		return default_ore
	end
	local ore = ore_cache[name]
	if ore == nil then
		ore = ore_folder:FindFirstChild(name)
		if ore == nil then
			warn("MISSING ORE:", name)
			return default_ore
		end
		ore_cache[name] = ore
	end
	return ore
end

--------------------------------------------------------------------------------

local MineModule = {}
MineModule.__index = MineModule

-- these are fixed at a 6x6x6 block
local positions = {
	Vector3.new(1,0,0);
	Vector3.new(-1,0,0);
	Vector3.new(0,1,0);
	Vector3.new(0,-1,0);
	Vector3.new(0,0,1);
	Vector3.new(0,0,-1);
}

local function gen_key(grid)
	return string.format('%d;%d;%d', grid.X, grid.Y, grid.Z)
end

function MineModule:CalcDepthWeight(depth)
	print("CalcDepthWeight:", depth)
	local ww = {} -- key=name, val=weight

	for _, info in ipairs(self.cubes) do
		-- print(" =", info.name)
		if info.depth_min ~= nil and depth < info.depth_min then
			-- skip it
			--print("CalcDepthWeight:", "skip min")
		elseif info.depth_max ~= nil and depth > info.depth_max then
			-- skip it
			--print("CalcDepthWeight:", "skip max")
		elseif info.depth_opt == nil then
			-- anywhere between is the same
			ww[info] = info.weight
			--print("CalcDepthWeight:", "between", info.name)
		elseif depth >= info.depth_opt then
			--print("CalcDepthWeight:", "below opt")
			if info.depth_max == nil or info.depth_max <= info.depth_opt then
				ww[info] = info.weight
			else
				-- depth >= depth_opt and depth <= depth_max and depth_max > depth_opt
				local ss = (depth - info.depth_opt)
				local xx = (info.depth_max - info.depth_opt)

				ww[info] = info.weight - (info.weight * (ss / xx))
			end
		else -- depth < info.depth_opt
			--print("CalcDepthWeight:", "above opt")
			if info.depth_min == nil or info.depth_min >= info.depth_opt then
				ww[info] = info.weight
			else
				-- depth < depth_opt and depth >= depth_min and depth_min < depth_opt
				local ss = (info.depth_opt - depth)
				local xx = (info.depth_opt - info.depth_min)

				ww[info] = info.weight - (info.weight * (ss / xx))
			end
		end
	end
	return ww
end

function MineModule:GetDepthWeight(depth)
	--print("GetDepthWeight:", depth)
	local ww = self.odds[depth]
	if ww == nil then
		ww = self:CalcDepthWeight(depth)
		self.odds[depth] = ww
	end
	return ww
end

function MineModule:SelectOre(depth)
	local info = { depth=depth }
	local oo = Choice.ChooseOne(self:GetDepthWeight(depth))
	for k, v in pairs(oo) do
		if k == 'ore' then
			info[k] = v:Clone()
		else
			info[k] = v
		end
	end
	return info
end

-- generate one random ore at x,y,z - grid coords
function MineModule:GenerateAt(grid)
	-- see if we already generated this block
	local key = gen_key(grid)
	if self.key2part[key] ~= nil then
		return
	end

	-- get whether this is a block, border, or out-of-bounds
	local uu = self.info:GetUsable(grid)
	if uu == nil then
		return
	end

	local depth = self.info:GetDepth(grid)

	local ore
	local ore_info
	if uu == false then
		ore = self.border_ore:Clone()
	else
		ore_info = self:SelectOre(depth)
		ore = ore_info.ore
	end

	local cf = self.info:GridToCFrame(grid)

	local opp
	if ore:IsA("Model") then
		opp = ore.PrimaryPart
		if opp == nil then
			--print("AIR", grid)
			self.key2part[key] = false
			self:GenerateAround(grid)
			return
		end
		ore:SetPrimaryPartCFrame(cf)
	else
		opp = ore
		opp.CFrame = cf
	end


	if uu == true then
		local gv = Instance.new("Vector3Value")
		gv.Name = "GridPos"
		gv.Value = grid
		gv.Parent = ore
	end

	ore.Parent = self.parent
	self.key2part[key] = ore

	if ore_info ~= nil then
		self.info:AddBlock(ore_info)

		ore_info.GridPos = grid
		self.ore2info[ore] = ore_info

		if ore_info.transparent == true then
			self:GenerateAround(grid)
		end
	end

	-- REVISIT: should border blocks be counted?
	self.generated_count = self.generated_count + 1
end

-- destroys a ore block, generates more around it
function MineModule:Zap(ore)
	local oi = self.ore2info[ore]
	if oi == nil then
		warn(self.name, "Zap:", ore, "no info")
		return
	end

	local grid = oi.GridPos

	self.mined_count = self.mined_count + 1

	-- release the ref to the ore
	local key = gen_key(grid)
	if oi ~= nil and oi.ore ~= ore then
		warn(self.name, "Zap", ore, "at", grid, "found", oi)
	end
	self.key2part[key] = false
	self.ore2info[ore] = nil
	self.miners[ore] = nil
	ore.Parent = nil

	self:GenerateAround(grid)
end

function MineModule:GenerateAround(grid)
	for _, gp in pairs(positions) do
		self:GenerateAt(grid + gp)
	end
end

function MineModule:RebuildMine(level)
	level = level or 0
	print("RebuildMine:", self.name, 'level:', level)
	-- erase all generated blocks
	for key, part in pairs(self.key2part) do
		if part ~= false then
			part.Parent = nil
		end
	end
	self.level = level
	self.key2part = {}
	self.ore2info = {}
	self.miners = {}
	self.mined_count = 0
	self.generated_count = 0

	-- generate the first layer
	for _, vec in pairs(self.info:GetSeed()) do
		--print("Seed:", vec)
		self:GenerateAt(vec)
	end
end

--------------------------------------------------------------------------------

function MineModule:AddMiner(block, player, value)
	local mm = self.miners[block]
	if mm == nil then
		mm = {}
		self.miners[block] = mm
	end
	mm[player.UserId] = (mm[player.UserId] or 0) + value
end

function MineModule:GetMiners(block)
	return self.miners[block] or {}
end

--------------------------------------------------------------------------------
-- This small module is used to instantiate a MineModule
--
local getmodule = {}
getmodule.__index = getmodule

-- key=name, val=mine object
getmodule.mines = {}

-- default properties if missing on the ore
local default_ore_props = {
	weight = 10,
	-- insane values to remind that they need to be specified
	Count = 1,
	Price = 999,
	Health = 999,
}

-- Generic function that extracts Int/Number/String/Bool Values and adds then to a table
local function extract_child_values(ii, parent)
	for _, vv in pairs(parent:GetChildren()) do
		if vv:IsA("IntValue") or vv:IsA("NumberValue") or vv:IsA("StringValue") or vv:IsA("BoolValue") then
			ii[vv.Name] = vv.Value
		end
	end
end

-- TODO: move this to MineModule as a class function
local function parse_ore_info(folder)
	local ores = {} -- array/table
	for _, cv in pairs(folder:GetChildren()) do
		local name = cv.Name
		local ore = cv
		local obj
		-- follow the link if the child is an ObjectValue
		if cv:IsA("ObjectValue") then
			obj = cv
			ore = cv.Value
		end

		if ore ~= nil and (ore:IsA("BasePart") or ore:IsA("Model")) then
			local ii = { name = name, ore = ore }
			extract_child_values(ii, ore)
			if obj ~= nil then
				extract_child_values(ii, obj)
			end
			for k, v in pairs(default_ore_props) do
				if ii[k] == nil then
					warn("Setting default", k, "for", ore)
					ii[k] = v
				end
			end
			table.insert(ores, ii)
		end
	end
	for idx, vv in ipairs(ores) do
		print("ORE:", idx, vv)
	end
	return ores
end

--[[
Create a new mine.
@vmin and @vmax are Vector3's that describe the opening.
Anything below vmin.y is OK.
Anything above vmax.Y cannot be used. Between the two, the X and Z limit the growth.
Other stuff should be there.
This pre-generates the top layer.

@cubes is a list of cubes  with the following info
   name = name of the cube (ore)
   ore = reference to the ore block to be cloned
   depth_min = ore will not appear above this depth
   depth_opt = optimum depth for the ore
   depth_max = ore will not appear below this depth
   weight = relative weight when picking a random ore

The weight is adjusted based on the depth. If below min or above max, the weight is 0.
At depth_opt it is weight. It is linearly adjusted between depths.
]]
function getmodule.new(mine_model, info)
	local mm = setmetatable({}, MineModule)

	mm.name = mine_model.Name
	mm.info = info
	mm.cubes = parse_ore_info(mine_model:FindFirstChild("Ores"))

	-- key = '%d,%d,%d', x,y,z, val=part (to delete on reset) or false if erased
	mm.key2part = {}
	mm.ore2info = {}  -- key=part (only minable ores), val={info}
	mm.togenerate = {} -- key val=Vector3 grid position that needs to be populated
	mm.miners = {}     -- ? tracks who has mined what ?

	mm.parent = Utils.GetOrCreate(mine_model, "Blocks", "Folder")
	mm.odds = {} -- key=depth, val=cube odds

	mm.exit_part = mine_model:FindFirstChild("Exit")

	mm.mined_count = 0
	mm.generated_count = 0 -- TODO: reset the mine when this exceeds some value

	local vv = mine_model:FindFirstChild("Border")
	if vv and vv:IsA("ObjectValue") then
		mm.border_ore = vv.Value
	end
	if mm.border_ore == nil then
		mm.border_ore = border_ore
	end

	getmodule.mines[mm.name] = mm

	return mm
end

function getmodule:FindMineForBlock(part)
	if part ~= nil then
		for name, mm in pairs(self.mines) do
			if mm.ore2info[part] ~= nil then
				return mm
			end
		end
	end
	return nil
end

local function check_mine_pos(pos, mm)
	local grid = mm.info:CFrameToGrid(CFrame.new(pos))
	local uu = mm.info:GetUsable(grid)
	if uu ~= nil then
		print("FindMineForPosition", pos, "in", mm.name, "grid", grid)
		return true
	end
	return false
end

function getmodule:FindMineForPosition(pos, last_mine)
	if pos ~= nil then
		local mm
		if last_mine ~= nil and check_mine_pos(pos, last_mine) then
			return last_mine
		end
		for name, mm in pairs(self.mines) do
			if mm ~= last_mine then
				if check_mine_pos(pos, mm) then
					return mm
				end
			end
		end
	end
	return nil
end

return getmodule
