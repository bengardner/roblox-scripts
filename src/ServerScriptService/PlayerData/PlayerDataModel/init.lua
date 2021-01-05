local PlayerPets = require(script.PlayerPets)
--------------------------------------------------------------------------------

local pdm = {}

-- this is called from the .Get(player) function
function pdm.init(data)
	data.drones = {}
	data.drone_idx = 1

	local tt = workspace:WaitForChild("TestDrone")
	warn("Drone", tt)
	-- FIXME: this is a hack for testing, drones should be constructed from the datastore
	table.insert(data.drones, tt)
	warn("Set drone to", data.drones[1])
	data:Set("drone", data.drones[1])

	-- probably not going to use "pet", but rather the drones are like pets
	data.pets = PlayerPets.new(data, data:Get("pets"))
end

--------------------------------------------------------------------------------
--- Drone functions

function pdm:drone_cur()
	return self:Get("drone")
end

function pdm:drone_select(idx)
	local drone = self.drones[self.drone_idx]

	if drone ~= nil then
		drone.PrimaryPart:SetNetworkOwner(nil)
	end
	-- REVISIT: test the next line, not sure if it will work for prev wrapping
	self.drone_idx = 1 + ((idx - 1) % #self.drones)
	drone = self.drones[self.drone_idx]
	self:Set("drone", drone)
	if drone ~= nil then
		drone.PrimaryPart:SetNetworkOwner(self.player)
	end
end

function pdm:drone_next()
	self:drone_select(self.drone_idx + 1)
end

function pdm:drone_prev()
	self:drone_select(self.drone_idx - 1)
end

--------------------------------------------------------------------------------
--- Coin functions

function pdm:coins_onUpdate(func)
	self:OnUpdate("coins", func)
end

function pdm:coins_get()
	return self:Get("coins")
end

-- We should only allow coins to go up here (delta >= 0)
function pdm:coins_add(delta)
	print("coins_add:", delta)
	self:Add("coins", delta)
end

function pdm:coins_spend(amount)
	return self:Spend("coins", amount)
end

--------------------------------------------------------------------------------
--- Gem functions

function pdm:gems_onUpdate(func)
	self:OnUpdate("gems", func)
end

function pdm:gems_get()
	return self:Get("gems")
end

-- We should only allow gems to go up here (delta >= 0)
function pdm:gems_add(delta)
	print("gems_add:", delta)
	self:Add("gems", delta)
end

function pdm:gems_spend(amount)
	return self:Spend("gems", amount)
end

--------------------------------------------------------------------------------------------------
-- PETS!  Named after the number Pet0, Pet1, Pet2, ... Pet12
--

-- returns the pet data. this is used to set the pet anchors.
function pdm:pets_get()
	return self:Get("pets")
end

function pdm:pets_enable(pet_name)
	local pets = self:Get("pets")
	if pets[pet_name] == nil then
		pets[pet_name] = { owned = true }
		self:Set("pets", pets)
	end
end

return pdm
