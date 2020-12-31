local module = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()
local leaderstats = player:WaitForChild("leaderstats")
local playerstats = player:WaitForChild("stats")

--[[
	Color Tables are an array of two values:
	   { value, color }
	The value must be in increasing order.
	The color is lerp'd between the two neighboring entries.
	Anything less than the first value gets the first color.
	Anything greater than the last value gets the last color.
--]]
module.HealthValueTable = {
	{ 0.0, Color3.fromRGB(255, 0, 0) },
	{ 0.3, Color3.fromRGB(255, 255, 0) },
	{ 0.7, Color3.fromRGB(0, 255, 0) },
}

module.PainValueTable = {
	{ 0.0, Color3.fromRGB(0, 255, 0) },
	{ 0.8, Color3.fromRGB(255, 255, 0) },
	{ 1.0, Color3.fromRGB(255, 0, 0) },
}

module.FocusValueTable = {
	{ 0.0, Color3.fromRGB(155, 155, 0) },
	{ 0.7, Color3.fromRGB(255, 255, 0) },
	{ 1.0, Color3.fromRGB(0, 255, 0) },
}

module.DistrValueTable = {
	{ 0.0, Color3.fromRGB(155, 155, 0) },
	{ 0.5, Color3.fromRGB(255, 170, 0) },
	{ 1.0, Color3.fromRGB(255, 0, 0) },
}

function module.GetColor(value, valueTable)
	if value < valueTable[1][1] then
		return valueTable[1][2]
	end
	if value >= valueTable[#valueTable][1] then
		return valueTable[#valueTable][2]
	end
	for idx = 2, #valueTable do
		local v2 = valueTable[idx][1]
		if value <= v2 then
			local c1 = valueTable[idx-1][2]
			local c2 = valueTable[idx][2]
			local v1 = valueTable[idx-1][1]
			return c2:lerp(c1, (v2 - value) / (v2 - v1))
		end
	end

	warn("Made it to the end for value", value)
	return valueTable[1][2]
end

--[[
Does a very simple link between a number field and a text label.
]]
function module.LinkValue(text_label, value, color_func)
	if value:IsA("IntValue") then
		value.Changed:Connect(function()
			text_label.Text = string.format("%d", value.Value)
		end)

	elseif value:IsA("NumberValue") then
		value.Changed:Connect(function()
			text_label.Text = string.format("%.3g", math.floor(value.Value))
			if color_func ~= nil then
				color_func(text_label, value)
			end
		end)
	else
		warn("LinkValue: unsupported value", value)
	end
end

function module.LinkLeaderStatsValue(text_label, value_name, color_func)
	module.LinkValue(text_label, leaderstats:WaitForChild(value_name))
end

function module.LinkPlayerStatsValue(text_label, value_name, color_func)
	module.LinkValue(text_label, playerstats:WaitForChild(value_name))
end

return module
