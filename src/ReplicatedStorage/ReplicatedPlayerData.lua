--[[
This defines the data that is continuously replicated from the server to the
client under the player. Interface to player data from the server.

This information is used to:
	- setup the player.stat and player.leaderstat folders
	- hook the dataitems to the Values
	- add items to PlayerData datastore

Design details:
	player.PlayerDataLoaded (BoolValue) is created when all the data items have
	been created under player.

	LeaderStat items are placed under player.leaderstats.
	Other items are placed under player.stats.

	Complicated data, such as pets are not currently replicated here.
	Eventually, a folder structure will be used.
]]
local ReplicatedPlayerData = {}

-- define the data type flags the first 3 are
ReplicatedPlayerData.DT_SERVER = 0 -- server-private data (not replicated)
ReplicatedPlayerData.DT_CLIENT = 1 -- replicated to the client under player.stats
ReplicatedPlayerData.DT_SAVE   = 4 -- saved to the datastore
ReplicatedPlayerData.DT_SAVE_SERVER = ReplicatedPlayerData.DT_SERVER + ReplicatedPlayerData.DT_SAVE
ReplicatedPlayerData.DT_SAVE_CLIENT = ReplicatedPlayerData.DT_CLIENT + ReplicatedPlayerData.DT_SAVE
-- Examples:
--  * "Gems" is saved and replicated, and a leaderstat item, so the flags are DT_SAVE_CLIENT
--  * "Coins" is StringValue, derived from "coins" (on the server) and not saved,
--    but is a leaderstat item, dtype = DT_LEADER. This is to use custom formatting.
--  * "coins" is saved and replicated, dtype = DT_SAVE_CLIENT
--  * "fatigue" is NOT saved, but is replicated, so the flags are DT_CLIENT.

--[[
This is a *list* of data items that should be replicated from the the server and are stored under player.stats or player.leaderstats.
It must be a list to preserve the order for leaderstats. (at least, that's how I think it works!)

Fields:
	@inst is the instance type passed to Instance.new(). If omitted, the value is not replicated to the client.
	   NOTE: "Folder" is used for complex objects
	@save indicates that the data should be save to the datastore, default is true (turn off with "save=false")

The other fields are for datastore use:
	@default is the default value if not 0 or ''.
	@minval is the minimum value for numbers (datastore use)
	@maxval is the maximum value for numbers (datastore use)
]]
ReplicatedPlayerData.items = {
	-- stats items
	coins        = { inst='NumberValue', default=100 },
	gems         = { inst='NumberValue' },	
	
	xp           = { inst='NumberValue' },
	level        = { inst='NumberValue' },
	rebirths     = { inst='NumberValue' },

	ore_max      = { inst='NumberValue' },
	ore          = { inst='NumberValue' },
	health_max   = { inst='NumberValue' },

	pets         = { inst='Folder',
		children = {			
		}		
	},
	items        = { inst='Folder',
		children = {
		}		
	},

	-- derived data
	xp_next      = { inst='NumberValue', save=false },
	rebirth_cost = { inst='NumberValue', save=false },
	tool_damage  = { inst='NumberValue', save=false },
	tool_range   = { inst='NumberValue', save=false, default=30 },

	-- server-only data (example)
	active_block = { default={} }, -- block that the player is currently mining
}

local function format_number(val)
	return string.format('%u', math.floor(val))
end

-- this is a *list* of leaderstats items.
-- @name is the name for the leaderstats field
-- @inst is the Value instance type
-- @dsvar is the variable to attach to
-- @func is used to format the field. If nil, the value is passed through.
ReplicatedPlayerData.leaderstats = {
	{ name = 'Coins',    inst = 'StringValue', dsvar = 'coins',    func = format_number },
	{ name = 'Gems',     inst = 'StringValue', dsvar = 'gems',     func = format_number },
	{ name = 'Rebirths', inst = 'IntValue',    dsvar = 'rebirths', func = format_number },
}

return ReplicatedPlayerData
