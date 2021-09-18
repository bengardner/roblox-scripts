local RunService = game:GetService("RunService")
local Utils = require(script.Parent.Utils)

local module = {}

local items = {}
local connector = nil

local function doHeartbeat(step)
	for frame, xx in pairs(items) do
		if xx.cur == -1 then
			xx.cur = xx.tgt
		elseif xx.cur < xx.tgt then
			xx.cur = math.min(xx.tgt, xx.cur + step) -- moves to tgt in one second
		elseif xx.cur > xx.tgt then
			xx.cur = math.max(xx.tgt, xx.cur - step)
		end
		if xx.last ~= xx.cur and xx.cur >= 0 then
			xx.ui.Size = UDim2.new(UDim.new(xx.cur, 0), xx.udim_y)
			xx.last = xx.cur
			if xx.ctab ~= nil then
				xx.ui.BackgroundColor3 = Utils.GetColor(xx.cur, xx.ctab)
			end
		end
	end
end

-- create a new smooth bar
function module.new(frame, udim_y, max_pct)
	local xx = {}

	xx.ui = frame
	xx.udim_y = udim_y or UDim.new(1,0)
	xx.last = -1
	xx.cur = 0
	xx.tgt = 0
	xx.max_pct = max_pct or 1

	items[frame] = xx

	if connector == nil then
		connector = RunService.Heartbeat:Connect(doHeartbeat)
	end

	return setmetatable(xx, module)
end

function module.del(frame)
	items[frame] = nil
end

function module:set_color_table(ctab)
	self.ctab = ctab
	self.last = -1
end

function module:set_percent(pct)
	self.tgt = math.min(pct, self.max_pct)
	--print("set_percent", self.ui, "tgt:", self.tgt, "max:", self.max_pct)
end

function module:set_cur_max(cur, max)
	if max > 0 then
		self:set_percent(cur / max)
	else
		self:set_percent(0)
	end
end

module.__index = module

return module
