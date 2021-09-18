--[[
Connects a datastore value and a label.
Does slewing and a little bump when the target value is reached.
]]
local LocalPlayerData = require(game.ReplicatedStorage.LocalPlayerData)
local RunService = game:GetService("RunService")

-------------------------------------------------------------------------------
DataStoreLabel = {}
DataStoreLabel.__index = DataStoreLabel

--[[
Set the slew rate based on the target_val and current_val.
Override this to get custom functionality.
]]
function DataStoreLabel:update_slew_rate()
    -- check for nil to only update the slew rate at the start
    -- remove the slew_rate check to change the rate frame-by-frame.
    if self.slew_rate == nil or self.SlewSlew then
        self.slew_rate = (self.target - self.current) * self.SlewMult
    end
end

--[[
Set the text in the label.
Override this to get custom functionality.
]]
function DataStoreLabel:update_text()
    if self.current ~= self.text_val then
        self.label.Text = string.format("%d", math.floor(self.current))
        self.text_val = self.current
    end
end

--[[
The target value just changed.
Calculate the new slew rate and start the heartbeat task.
]]
function DataStoreLabel:onUpdateValue()
	self.target = self.Value.Value

    -- note that new values were received
    self.slew_rate = nil

    -- update the slew rate
    if self.update_slew_rate ~= nil then
        self:update_slew_rate()
    else
        self.current = self.target
    end

    self:update_text()

    if self.current ~= self.target then
        self:EnableHeartbeat()
    end
end

-- step the value, update the text. Do some size trickery when done.
function DataStoreLabel:slew_label(elapsed)
	if self.target ~= self.current then
		if math.abs(self.current - self.target) <= 1 then
			self.current = self.target
		elseif self.slew_rate > 0 then
			self.current = math.min(self.target, self.current + self.slew_rate * elapsed)
		else -- slew_rate < 0
			self.current = math.max(self.target, self.current + self.slew_rate * elapsed)
		end

		if self.current == self.target then
            self.slew_rate = nil
            if self.BumpSize > 0 and self.BumpTime > 0 then
                local function bigtweendone()
                    self.label:TweenSize(
                        UDim2.new(1, 0, 1, 0),    -- endSize (required)
                        Enum.EasingDirection.Out, -- easingDirection (default Out)
                        Enum.EasingStyle.Sine,    -- easingStyle (default Quad)
                        self.BumpTime,            -- time (default: 1)
                        true,                     -- should this tween override ones in-progress? (default: false)
                        nil                       -- a function to call when the tween completes (default: nil)
                    )
                end
                self.label:TweenSize(
                    UDim2.new(self.BumpSize, 0, self.BumpSize, 0),  -- endSize (required)
                    Enum.EasingDirection.In,    -- easingDirection (default Out)
                    Enum.EasingStyle.Sine,      -- easingStyle (default Quad)
                    self.BumpTime,              -- time (default: 1)
                    true,                       -- should this tween override ones in-progress? (default: false)
                    bigtweendone                -- a function to call when the tween completes (default: nil)
                )
            end
		end
    end
    self:update_text()
end

function DataStoreLabel:EnableHeartbeat()
    if self.hb_handle == nil then
        self.hb_handle = RunService.Heartbeat:Connect(function(elapsed)
            self:update_slew_rate()
            self:slew_label(elapsed)

            -- disable the hearbeat if no longer needed
            if self.slew_rate == nil then
                self.hb_handle:Disconnect()
                self.hb_handle = nil
            end
        end)
    end
end

-------------------------------------------------------------------------------
local getter = {}

--[[
@ds_name : the name of the datastore item
@label : the TextLabel to update
@options : table with the following config items:
   "BumpSize" (number) The multiplier for the label at the end of the slew, default 1.2
   "BumpTime" (number) How long to tween the bump (seconds both ways), default 0.1
        Both BumpTime and BumpSize must be > 0 for the Bump to happen.
   "SlewMult" (number) slew_rate = (target - current) * SlewMult, set to 1/seconds for a timed slew
   "SlewSlew" (bool) if true, recalculate the slew rate on each frame. Slows down near the target.
]]
function getter.new(ds_name: string, label: TextLabel, options: table|nil)
    local Value = LocalPlayerData:GetValue(ds_name)
    if Value == nil then
        warn("Invalid Field", ds_name)
        return
    end
    options = options or {}

    local dsvl = setmetatable({}, DataStoreLabel)
    dsvl.Name = ds_name
    dsvl.label = label
    dsvl.Value = Value
    dsvl.current = 0
    dsvl.BumpSize = options.BumpSize or 1.2
    dsvl.BumpTime = options.BumpTime or 0.1
    dsvl.SlewMult = options.SlewMult or 2
    dsvl.SlewSlew = options.SlewSlew or true

    Value.Changed:Connect(function()
        dsvl:onUpdateValue()
    end)
    dsvl:onUpdateValue()

    return dsvl
end

return getter
