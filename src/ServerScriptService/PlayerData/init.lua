--[[
Infinite Miner Test PlayerData.

Replicated data items are defined in ReplicatedPlayerData.
Other data is defined below in field_info.
]]
local Players = game:GetService("Players")
local DataStore2 = require(game.ServerScriptService.DataStore2)
local ReplicatedPlayerData = require(game.ReplicatedStorage.ReplicatedPlayerData)
--------------------------------------------------------------------------------

local PlayerDataModel
if script:FindFirstChild("PlayerDataModel") ~= nil then
	PlayerDataModel = require(script.PlayerDataModel)
end

--------------------------------------------------------------------------------

local field_info = {}

-- convert replicated items to field_info
for name, item in pairs(ReplicatedPlayerData.items) do
	local ii = { name = name }
	if item.default then
		ii.default = item.default
	else
		if item.inst ~= nil and item.inst == 'StringValue' then
			ii.default = ''
		elseif item.inst == 'NumberValue' or item.inst == 'IntValue' then
			ii.default = 0
		else
			ii.default = nil
		end
	end
	ii.min = item.minval
	ii.max = item.maxval
	ii.save = item.save

	field_info[name] = ii
end

--------------------------------------------------------------------------------

-- Init the datastore by combining all the DS keys
local ds_names = {}
for k, v in pairs(field_info) do
	if v.save then
		print("PlayerData:Saved:", k)
		DataStore2.Combine("DATA", k)
		ds_names[k] = v
	else
		print("PlayerData:Local:", k)
	end
end

--------------------------------------------------------------------------------

-- check to see if a field name is valid
local function field_valid(name)
	return field_info[name] ~= nil
end

-- grab the default value for a field
local function field_default(name)
	local ii = field_info[name]
	if ii ~= nil then
		return ii.default
	end
	return nil
end

-- grab the min/max values for a field
local function field_minmax(name)
	local ii = field_info[name]
	if ii ~= nil then
		return { min = ii.min, max = ii.max }
	end
	return nil
end

--------------------------------------------------------------------------------
-- PlayerData class
--------------------------------------------------------------------------------

local PlayerData = {}
PlayerData.__index = PlayerData

--------------------------------------------------------------------------------
-- BEGIN COMMON CODE THAT SHOULD BE MOVED TO A SUB-MODULE
--------------------------------------------------------------------------------

-- attaches a function to an event.
function PlayerData:OnUpdate(name, ds_func)
	if ds_names[name] ~= nil then
		print("OnUpdate:", name)
		local ds = DataStore2(name, self.player)
		ds:OnUpdate(ds_func)
	else
		-- not in the datastore, attach to the BindableEvent
		local be = self.be[name]
		if be == nil then
			be = Instance.new("BindableEvent")
			self.be[name] = be
		end
		be.Event:Connect(ds_func)
	end
end


--------------------------------------------------------------------------------
-- DataStore functions
--------------------------------------------------------------------------------

function PlayerData:ds(name)
	return DataStore2(name, self.player)
end

function PlayerData:ds_get(name)
	return self:ds(name):Get(field_default(name))
end

function PlayerData:ds_set(name, value)
	print("Set:", name, value)
	return self:ds(name):Set(value)
end


--------------------------------------------------------------------------------
-- Non-DataStore functions
--------------------------------------------------------------------------------

function PlayerData:pd_get(name)
	return self.pd[name] or field_default(name)
end

function PlayerData:pd_set(name, value)
	local old_value = self:pd_get(name)
	if value ~= old_value then
		-- TODO: sanity check on the type? Don't want it changing.

		self.pd[name] = value
		-- trigger the change event
		local be = self.be[name]
		if be ~= nil then
			be:Fire(value)
		end
	end
	return value
end


--------------------------------------------------------------------------------
-- Combined functions
--------------------------------------------------------------------------------

-- get the value of a data item, whether stored or not
function PlayerData:Get(name)
	if ds_names[name] ~= nil then
		return self:ds_get(name)
	else
		return self:pd_get(name)
	end
end

-- set bounds for the Add function
function PlayerData:SetMinMax(name, minval, maxval)
	self.minmax[name] = { min=minval, max=maxval }
end

-- get bounds for the Add function
function PlayerData:GetMinMax(name)
	-- default is min=0, no max
	return self.minmax[name] or field_minmax(name)
end

-- Set the value of a data item, whether stored or not
function PlayerData:Set(name, val)
	--print("Set.top:", name, val)
	local mm = self:GetMinMax(name)
	if mm ~= nil then
		if mm.min ~= nil then
			val = math.max(mm.min, val)
		end
		if mm.max ~= nil then
			val = math.min(mm.max, val)
		end
	end
	if ds_names[name] ~= nil then
		--print("Set.ds:", name, val)
		return self:ds_set(name, val)
	else
		--print("Set.pd:", name, val)
		return self:pd_set(name, val)
	end
end

-- Add to the value of a data item
function PlayerData:Add(name, val)
	--print("Add:", name, val)
	local new_val = self:Get(name)
	if val > 0 then
		new_val = self:Set(name, new_val + val)
	end
	return new_val
end

-- Subtract the value from a data item, but only if there is enough
function PlayerData:Spend(name, val)
	local cur = self:Get(name)
	if val > 0 then
		local cur = self:Get(name)
		if cur >= val then
			cur = self:Set(name, cur - val)
			return true, cur
		end
	end
	return false, cur
end

--------------------------------------------------------------------------------
-- END OF COMMON CODE
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--
-- This returns the module that only has the 'get' item
--
local module = {}

module.cache = {}

-- Get or create a new DataStore2 wrapper for the player
function module:get(player)
	--print("PlayerData:Get", player)
	local data = module.cache[player]
	if data == nil then
		print("DATASTORE: creating", player)
		data = setmetatable({}, PlayerData)
		data.player = player
		data.pd = {} -- map of value name to data
		data.be = {} -- map of value name to BindableEvent
		data.minmax = {} -- map of name to { min=min_val, max=max_val }

		module.cache[player] = data

		if PlayerDataModel ~= nil then
			local init_fcn
			for n, v in pairs(PlayerDataModel) do
				if n == 'init' then
					init_fcn = v
				else
					data[n] = v
				end
			end

			if init_fcn then
				init_fcn(data)
			end
		end
	end
	return data
end

-- I'm tired of mixing this up
module.Get = module.get

-- Hack for iteration
function module:GetAll()
	return module.cache
end

-- clean up player_cache
Players.PlayerRemoving:Connect(function(player)
	print("DATASTORE: discarding", player)
	module.cache[player] = nil
end)

return module
