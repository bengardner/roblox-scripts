--[[
A "Rotated" mine is a "Flat" mine with a more complicated translation.
Might just merge it in with the Flat module.
]]
local MineInfoFlat = require(game.ServerScriptService.MineInfoFlat)
local MineInfoRot = {}
MineInfoRot.__index = MineInfoFlat

local function round(val)
	return math.floor(val + 0.5)
end

local function round_vec3(vec3)
	return Vector3.new(round(vec3.X), round(vec3.Y), round(vec3.Z))
end

-- create a new mine info
function MineInfoRot.new(neck_part, max_size, cube_size)
	local mi = setmetatable(MineInfoFlat.new(neck_part, max_size, cube_size), MineInfoRot)

	-- block 0,0,0 position, used to calculate all other positions
	mi.center = Vector3.new(
		neck_part.Position.X,
		neck_part.Position.Y + neck_part.Size.Y / 2 - cube_size/Y / 2,
		neck_part.Position.Z)

	-- calculate the neck size
	local grid_neck = neck_part.Size / cube_size
	local xmin = round(grid_neck.X / 2)
	local xmax = grid_neck.X - xmin
	local zmin = round(grid_neck.Z / 2)
	local zmax = grid_neck.Z - zmin
	mi.neck_min = Vector3.new(xmin, 0, zmin)
	mi.neck_max = Vector3.new(xmax, 0, zmax)

	mi.cube_size = cube_size
	mi.max_size = max_size

	return mi
end

-- translate grid coords to depth for block generation
function MineInfoFlat:GetDepth(grid)
	return grid.Y
end

function MineInfoFlat:GridToCFrame(grid)
	return CFrame.new(self.center + grid * self.cube_size)
end

function MineInfoFlat:CFrameToGrid(cf)
	return round_vec3((cf.p - self.center) / self.cube_size)
end

local grid_cf = neck_part.CFrame
local grid_cfi = grid_cf:Inverse()

local center = neck_part.Position
print ("Neck:", center, "Cube:", ore.Size)

function grid2cf(grid)
	return neck_part.CFrame * CFrame.new(grid * ore.Size)
end

function cf2grid(cf)
	local p = (grid_cfi * cf).p
	return Vector3.new(round(p.X / ore.Size.X), round(p.Y / ore.Size.Y), round(p.Z / ore.Size.Z))
end


function MineInfoFlat:GetUsable(grid)
	-- we only deal in positive coordinates
	if grid.Y < 0 then
		return nil
	end

	-- are we above the bottom of the neck?
	if grid.Y <= self.neck_max.Y then
		-- are we outside the neck or on the border?
		if grid.X <= self.neck_min.X or grid.X >= self.neck_max.X or grid.Z <= self.neck_min.Z or grid.Z >= self.neck_max.Z then
			if grid.X == self.neck_min.X or grid.X == self.neck_max.X or grid.Z == self.neck_min.Z or grid.Z == self.neck_max.Z then
				return false -- border
			else
				return nil -- outside neck, don't touch
			end
		else
			return true -- populate
		end
	end

	-- below the neck, check absolute limits
	if grid.X <= -self.max_size.X or grid.X >= self.max_size.X or grid.Z <= -self.max_size.Z or grid.Z >= self.max_size.Z or grid.Y >= self.max_size.Y then
		if grid.X == -self.max_size.X or grid.X == self.max_size.X or grid.Z == -self.max_size.Z or grid.Z == self.max_size.Z or grid.Y == self.max_size.Y then
			return false -- border
		else
			return nil -- do not populate
		end
	end
	-- valid
	return true
end

return MineInfoFlat
