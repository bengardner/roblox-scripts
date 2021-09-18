--[[
Updates a label with the "coins" value in the top bar.
Does some slewing. Disable the size bump.
]]
local player = game:GetService("Players").LocalPlayer
local DataStoreLabel = require(player.PlayerScripts.DataStoreLabel)

local dsl_coins = DataStoreLabel.new("coins", script.Parent.Label, { BumpSize = 0 })
