--[[
Updates a label with the "coins" value.
Does some slewing with a size tween when the dest value is reached.
]]
local player = game:GetService("Players").LocalPlayer
local DataStoreLabel = require(player.PlayerScripts.DataStoreLabel)

local dsl_coins = DataStoreLabel.new("coins", script.Parent.Label)
