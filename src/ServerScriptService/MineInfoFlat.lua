--[[
A "Flat" mine is a straight-down regular mine.
The neck part determines the top of the mine as well as the size of the neck.
For best results, the part size should be a multiple of the cube size.

Block coordinates are in 'grid', where 1 unit is 1 block.
The top center is 0,0,0.

The mine looks like this from the side, with the neck restricting how big it can get.
The '|' and '-' indicate the border. 'x' indicates areas that will never be populated by this module.

v=depth
0 xxxxx|  0  |xxxxx
1 xxxxx|     |xxxxx
2 xxxxx|     |xxxxx
3 -----+     +-----
4

Config items:
	- neck_part (Part) or neck_size (Vector3) and neck_pos (Vector3)
	- max_size (Vector3 GRID units) X/Z = max extent for putting mines near each other, Y=max depth

Depth is grid.Y

Internal Data items:
	- neck_min (Vector3, grid) -- neck_min.Y is forced to 0
	- neck_max (Vector3, grid)
	- max_size (Vector3, grid) -- 'radius' centered at 0,0,0, so Y=max_depth

Required functions:
    - GetSeed() - return a list of Vector3 grid positions that need to be generated on mine reset
	- GetDepth(grid) - returns a number used to choose the block
    - GetUsable(grid) - true:regular block, false:border, nil:out of range, do not populate
    - GridToCFrame(grid) - converts grid coords to a CFrame
    - CFrameToGrid(cf) - converts a block CFrame to grid coords
    - AddBlock(inst, depth) - called to finish populating the block parameters

Usage:

local MineInfoFlat = required(game.ServerScriptService.MineInfoFlat)

local max_size  = Vector3.new(100, 1000, 100)
local cube_size = Vector3.new(6, 6, 6)

local info = MineInfoFlat.new(neck_part, max_size, cube_size)

function info:AddBlock(inst, depth)
	-- add click detector?
	-- add value and density?
end
]]

local MineInfoFlat = {}
MineInfoFlat.__index = MineInfoFlat

local function round(val)
	return math.floor(val + 0.5)
end

local function round_vec3(vec3)
	return Vector3.new(round(vec3.X), round(vec3.Y), round(vec3.Z))
end

-- create a new mine info
function MineInfoFlat.new(neck_part, max_size, cube_size)
	local mi = setmetatable({}, MineInfoFlat)

	-- block 0,0,0 position, used to calculate all other positions
	-- shift it to the top of the neck_part
	mi.center_cf = neck_part.CFrame * CFrame.new(-cube_size.X / 2, neck_part.Size.Y / 2 - cube_size.Y / 2, -cube_size.Z / 2)
	mi.center_cfi = mi.center_cf:Inverse()

	-- calculate the neck size
	local grid_neck = neck_part.Size / cube_size
	local xmin = 1 - round(grid_neck.X / 2)
	local xmax = grid_neck.X + xmin - 1
	local zmin = 1 - round(grid_neck.Z / 2)
	local zmax = grid_neck.Z + zmin - 1
	mi.neck_min = Vector3.new(xmin, 0, zmin)
	mi.neck_max = Vector3.new(xmax, grid_neck.Y, zmax)

	mi.cube_size = cube_size
	mi.max_size = max_size

	return mi
end

-- populate the top layer
function MineInfoFlat:GetSeed()
	--print("GetSeed:", self.seed, "min", self.neck_min, "max", self.neck_max)
	if self.seed == nil then
		local seed = {}
		for x = self.neck_min.X, self.neck_max.X, 1 do
			for z = self.neck_min.Z, self.neck_max.Z, 1 do
				local grid = Vector3.new(x, 0, z)
				--print("GetSeed Gen", grid)
				table.insert(seed, grid)
			end
		end
		self.seed = seed
	end
	return self.seed
end

-- translate grid coords to depth for block generation
-- mainly useful for spherical mines
function MineInfoFlat:GetDepth(grid)
	return grid.Y
end

function MineInfoFlat:GridToCFrame(grid)
	return self.center_cf * CFrame.new(Vector3.new(grid.X * self.cube_size.X, -grid.Y * self.cube_size.Y, grid.Z * self.cube_size.Z))
	-- return CFrame.new(self.center + grid * self.cube_size)
end

-- REVIST: This shouldn't be needed, as we store the grid position in a Vector3Value under the block.
function MineInfoFlat:CFrameToGrid(cf)
	local cs = self.cube_size
	local p = (self.center_cfi * cf).p
	return Vector3.new(round(p.X / cs.X), round(-p.Y / cs.Y), round(p.Z / cs.Z))
	-- return round_vec3((cf.p - self.center) / self.cube_size)
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
			if grid.X == self.neck_min.X or grid.X == self.neck_max.X or grid.Z == self.neck_min.Z or grid.Z == self.neck_max.Z or grid.Y == self.neck_max.Y then
				return false -- border
			else
				return nil -- outside of mine limits
			end
		else
			return true -- inside mine
		end
	end

	-- below the neck, check absolute limits
	if grid.X <= -self.max_size.X or grid.X >= self.max_size.X or grid.Z <= -self.max_size.Z or grid.Z >= self.max_size.Z or grid.Y >= self.max_size.Y then
		if grid.X == -self.max_size.X or grid.X == self.max_size.X or grid.Z == -self.max_size.Z or grid.Z == self.max_size.Z or grid.Y == self.max_size.Y then
			return false -- border
		else
			return nil -- outside mine limits
		end
	else
		return true -- inside mine
	end
end

return MineInfoFlat
