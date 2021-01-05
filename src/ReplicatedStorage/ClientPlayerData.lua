--[[
This is a client Module.
Interface to player data from the server.

It currently only retrieves items under player.stats.

TODO: add remote support for complex data (pets, items). This will consist of
a RemoteFunction and RemoteEvent.  The Client can call the remote function to
grab certain data. The server sends updates via the RemoveEvent.
Depending on how pets end up, it may be easier to have a pet tree.
  player.stats.pets (folder)
    + UUID (name) StringValue (pet name for display)
	  + Model
	  + Level
      + XP
      + Rarity (stars)
	  + ??? (other Stats)
  player.petslots (folder)
    + slotID (name) StringValue (UUID)
]]
local ReplicatedPlayerData = require(game.ReplicatedStorage.ReplicatedPlayerData)
local Players = game:GetService("Players")

--------------------------------------------------------------------------------
local ClientPlayerData = {}
ClientPlayerData.__index = ClientPlayerData

function ClientPlayerData:_check(no_wait)
	-- bail if the stats folder has been acquired
	if self.stats ~= nil then
		return
	end
	if self.loaded ~= true then
		if no_wait == true then
			self.loaded = self.player:FindFirstChild("PlayerDataLoaded") ~= nil
		else
			self.loaded = self.player:WaitForChild("PlayerDataLoaded", 10) ~= nil
		end
	end
	if self.loaded == true then
		self.stats = self.player:WaitForChild("stats")
	end
end

-- Get the NumberValue or StringValue or IntValue, etc, instance
function ClientPlayerData:GetValue(field, no_wait)
	if field == nil then return nil end

	-- did we already find it?
	local vv = self.values[field]
	if vv ~= nil then
		return vv
	end

	-- need to look up the ReplicatedPlayerData info to know where to look for it
	local ii = ReplicatedPlayerData.items[field]
	if ii == nil then
		warn("Unknown field", field)
		return nil
	end

	if ii.inst == nil then
		warn("Server field", field)
		return nil
	end
	self:_check(no_wait)
	if no_wait then
		vv = self.stats:FindFirstChild(field)
	else
		vv = self.stats:WaitForChild(field)
	end

	if vv ~= nil then
		self.values[field] = vv
		return vv
	end

	warn("Field", field, "not found")
	return nil
end

-- Grab the value of the data item
function ClientPlayerData:Get(field, no_wait)
	local vv = self:GetValue(field, no_wait)
	if vv ~= nil then
		return vv.Value
	end
	return nil
end

-- calls self:GetValue(field) and Changed.Connect(func)
function ClientPlayerData:Attach(field, func)
	if field ~= nil then
		local vv = self:GetValue(field)
		if vv ~= nil then
			vv.Changed:Connect(func)
			return true
		end
		warn("Failed to Attach", field)
	end
	return false
end

--------------------------------------------------------------------------------
local getter = {}
getter.cache = {}

--[[
It is assumed that if the localscript has access to the player, then the player exists.
We need to handle a player joining and then exiting before the data is replicated.
]]
function getter.Get(player, no_wait)
	local data = getter.cache[player]
	if data == nil then
		data = setmetatable({}, ClientPlayerData)

		data.player = player
		data.values = {}

		getter.cache[player] = data
		data:_check(no_wait)
	end
	return data
end

--[[
TODO: spawn a loop that scans players every 30 seconds and removes missing players from the cache.
]]

return getter
