-- Updates a label with the "gems" value.
local player = game:GetService("Players").LocalPlayer
local DataStoreLabel = require(player.PlayerScripts.DataStoreLabel)

local dsl_gems = DataStoreLabel.new("gems", script.Parent.Label)
