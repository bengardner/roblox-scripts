--[[
This file implements a ProgressBar using the datastore.
]]
local LocalPlayerData = require(game:GetService("ReplicatedStorage"):WaitForChild("LocalPlayerData"))

----------------------------------------------------------------

local module = {}
module.__index = module

--[[
Configures a new progress bar.
@root is the root UI element for the progress bar.
	It must have a decendant named "progress_percent".
	It may have a decendant named "progress_text".
@info is a table that may contain:
	- "ds_cur" - LocalPlayerData datastore name for the "current" value.
	- "ds_max" - LocalPlayerData datastore name for the "maximum" value.
	- "ds_pct" - LocalPlayerData datastore name for the "percent" value (range 0.0 - 1.0).
		If omitted, ds_cur/ds_max is used.
	- "fcn_text" - function that converts the current and maximum values into a string for "progess_text"
		fcn_text(cur, max, pct)
	- "enable" - if set to "false", this will NOT call Enable()
	- "colors" - array of { pct=x, color=x }. finds nearest entries and interpolates the colors. must be sorted by pct (range 0-1)
Either ds_pct OR ds_cur AND ds_max must be specified.
]]
function module.new(frame, info)
	local pp = setmetatable({}, module)

	pp.frame = frame
	pp.text = frame:FindFirstChild("progress_text", true)
	pp.pct = frame:FindFirstChild("progress_percent", true)
	pp.ds_cur = info.ds_cur
	pp.ds_max = info.ds_max
	pp.ds_pct = info.ds_pct
	pp.fcn_text = info.fcn_text

	local function do_update()
		pp:Update()
	end

	LocalPlayerData:Attach(pp.ds_cur, do_update)
	LocalPlayerData:Attach(pp.ds_max, do_update)
	LocalPlayerData:Attach(pp.ds_pct, do_update)
	pp:Update()

	return pp
end

function module:Update()
	local vcur = LocalPlayerData:Get(self.ds_cur)
	local vmax = LocalPlayerData:Get(self.ds_max)
	local vpct = LocalPlayerData:Get(self.ds_pct)

	-- calculate the percent if not provided
	if vpct == nil then
		if vcur ~= nil and vmax ~= nil then
			vpct = vcur / vmax
		end
	end

	if self.text ~= nil then
		if self.fcn_text ~= nil then
			self.text.Text = self.fcn_text(vcur, vmax, vpct)
		else
			self.text.Text = string.format("%d / %d", math.floor(vcur),  math.floor(vmax))
		end
	end
	self.pct.Size = UDim2.new(vpct, 0, 1, 0)
end

return module
