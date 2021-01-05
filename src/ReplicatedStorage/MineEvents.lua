--[[
Helper to relay events between client and server.


]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Choice = require(ReplicatedStorage:WaitForChild("Choice"))

----------------------------------------------------------------

local module = {}
module.__index = module

module.re_mineblock = script:WaitForChild("re_mineblock")
module.rf_exitmine = script:WaitForChild("rf_exitmine")

--[[
Starts or stops mining a block.
if block is nil, this stops. If block is not nil, then this starts.
]]
function module.ClientMineBlock(block)
	module.re_mineblock:FireServer(block)
end

function module.ClientExitMine()
	print("Invoking rf_exitmine")
	return module.rf_exitmine:InvokeServer()
end

----------------------------------------------------------------

function module.ServerAttachMine(func)
	module.re_mineblock.OnServerEvent:Connect(function(player, block)
		local tstamp = os.clock()
		print(player, "MineBlock", block, "at", tstamp)
		func(player, block, tstamp)
	end)
end

function module.ServerAttachExit(func)
	module.rf_exitmine.OnServerInvoke = function(player)
		print(player, "Wants to exit the mine")
		func(player)
	end
end

return module
