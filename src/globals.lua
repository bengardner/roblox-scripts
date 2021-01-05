--[[
This file is to quiet complaints about unknown symbols in the lua plugin.
]]
game = {}
function game:GetService()
end

UDim2 = {}
function UDim2.new(x_scale, x_pixels, y_scale, y_pixels)
end