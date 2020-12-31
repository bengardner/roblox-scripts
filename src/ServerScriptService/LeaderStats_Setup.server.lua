--[[
This sets up the LeaderStats and non-LeaderStats data that is relayed to the players.
]]
local ReplicatedPlayerData = require(game.ReplicatedStorage.ReplicatedPlayerData)
local PlayerData = require(game.ServerScriptService.PlayerData)
local PlayerUtils = require(game.ServerScriptService.PlayerUtils)
local Utils = require(game.ReplicatedStorage.Utils)

PlayerUtils.Register_onPlayerAdded(function(player)
	local data = PlayerData:get(player)

	-- create the two folders
	local fld_leaderstats = Utils.GetOrCreate(player, "leaderstats", "Folder")
	local fld_stats = Utils.GetOrCreate(player, "stats", "Folder")

	-- populate the stats folder
	for name, x in pairs(ReplicatedPlayerData.items) do
		if x.inst ~= nil then
			local vv = Instance.new(x.inst)
			vv.Name = name
			if x.inst ~= "Folder" then
				vv.Value = data:Get(name)
			end
			vv.Parent = fld_stats

			-- set the update function
			data:OnUpdate(name, function(newval)
				vv.Value = newval
			end)
		end
	end

	-- populate the leaderstat folder
	for _, x in ipairs(ReplicatedPlayerData.leaderstats) do
		local vv = Instance.new(x.inst)
		local dsvar = x.dsvar or x.name
		vv.Name = x.name
		vv.Parent = fld_leaderstats

		local function updatefield(newval)
			if x.func ~= nil then
				vv.Value = x.func(newval)
			else
				vv.Value = newval
			end
		end
		-- set the update function
		data:OnUpdate(dsvar, updatefield)
		updatefield(data:Get(dsvar))
	end

	-- note that we have loaded everything and the splash screen can go away
	local done = Instance.new("BoolValue")
	done.Value = true
	done.Name = "PlayerDataLoaded"
	done.Parent = player
end)