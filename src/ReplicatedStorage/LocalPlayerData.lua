-- Wraps ClientPlayerData for the LocalPlayer
local ClientPlayerData = require(game.ReplicatedStorage.ClientPlayerData)
local Players = game:GetService("Players")

return ClientPlayerData.Get(Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait())