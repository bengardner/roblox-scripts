--[[
This defines the data that is continuously replicated from the server to the
client under the player. Interface to player data from the server.

NOTE: this must be customized for each game! This is an example.

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

-- define the data type flags
ReplicatedPlayerData.DT_SERVER = 0 -- server-private data (not replicated)
ReplicatedPlayerData.DT_CLIENT = 1 -- replicated to the client under player.stats
ReplicatedPlayerData.DT_SAVE   = 4 -- saved to the datastore
ReplicatedPlayerData.DT_SAVE_SERVER = ReplicatedPlayerData.DT_SERVER + ReplicatedPlayerData.DT_SAVE
ReplicatedPlayerData.DT_SAVE_CLIENT = ReplicatedPlayerData.DT_CLIENT + ReplicatedPlayerData.DT_SAVE

--[[
This is a map of data items that should be replicated from the the server and are stored under player.stats or player.leaderstats.
The key name is the item name.

Fields:
	@inst is the instance type passed to Instance.new(). Setting this causes it to be replicated to the client.
		One of: BoolValue, NumberValue, StringValue, IntValue, ObjectValue, or Folder
		NOTE: "Folder" is used for complex objects
	@save indicates that the data should be save to the datastore, default is true (turn off with "save=false")
	@children will be used to replicate complicated structures. (not implemented)

The other fields are for datastore use:
	@default is the default value if not 0 or ''.
	@minval is the minimum value for IntValue/NumberValue -- used for validation in the datastore
	@maxval is the maximum value for IntValue/NumberValue -- used for validation in the datastore
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

	-- set to the Attachment that is the camera. the parent must be a BasePart
	camera       = { inst='ObjectValue', save=false },

	-- server-only data (example)
	active_block = { default={} }, -- block that the player is currently mining
}

-- format a number as an integer, dropping any fractional part
local function format_number(val)
	return string.format('%u', math.floor(val))
end

-- this is a *list* of leaderstats items. It must be a list to preserve the order.
-- @name is the name for the leaderstats field
-- @inst is the Value instance type
-- @dsvar is the variable to attach to
-- @func is used to format the field. If nil, the value is passed through. For example,
--    you might want the "3.34 Si" style format for large numbers.
ReplicatedPlayerData.leaderstats = {
	{ name = 'Coins',    inst = 'StringValue', dsvar = 'coins',    func = format_number },
	{ name = 'Gems',     inst = 'StringValue', dsvar = 'gems',     func = format_number },
	{ name = 'Rebirths', inst = 'IntValue',    dsvar = 'rebirths', func = format_number },
}

return ReplicatedPlayerData
