--[[
Manages the replication side of the pets.
This should be used by the PlayerData class.
]]
local PlayerPets = {}
PlayerPets.__index = PlayerPets

-- this really needs to be in a utils module
local function get_or_create(parent, name, inst)
	local ii = parent:FindFirstChild(name)
	if ii == nil then
		ii = Instance.new(inst)
		ii.Name = name
		ii.Parent = parent
	end
	return ii
end

-- this defines the pet slots and the position relative to the HRP.
local pet_offs = {
	Vector3.new(-2, 2.5, 1.5),
	Vector3.new(2, 2.5, 1.5),
	Vector3.new(-3, 0.5, 1.5),
	Vector3.new(3, 0.5, 1.5),
	Vector3.new(0, 3.0, 1.5),
	Vector3.new(0, 0.0, 2.5),
}

local max_slot = #pet_offs

-- create a new PlayerPets instance for a player.
-- this should be parented to the PlayerData for the player.
function PlayerPets.new(data, name)
	local pp = setmetatable({}, PlayerPets)

	local petdata = data:Get(name)
	-- TODO: decode pet data?

	pp.data = data
	pp.player = data.player

	pp.Pets = get_or_create(pp.player, "Pets", "Folder")
	pp.PetSlot = get_or_create(pp.player, "PetSlot", "Folder")
	pp.Slots = {}
	for slot, vec in ipairs(pet_offs) do
		local ss = get_or_create(pp.PetSlot, string.format("%d", slot), "ObjectValue")
		pp.Slots[slot] = ss
		local sv = get_or_create(ss, "Pos", "Vector3Value")
		sv.Value = vec
	end

	return pp
end

-- shifts back pets to fill the slots
function PlayerPets:PetSlotCompress()
	for dst = 1, max_slot do
		if self.Slots[dst].Value == nil then
			local found = false
			for src = dst + 1, max_slot do
				if self.Slots[src].Value ~= nil then
					self.Slots[dst].Value = self.Slots[src].Value
					self.Slots[src].Value = nil
					found = true
					break
				end
			end
			if not found then
				return
			end
		end
	end
end

-- insert a nil into the lineup
-- follow with a PetEquip() to fill the hole
function PlayerPets:PetSlotInsert(slot)
	if self.Slots[slot].Value ~= nil then
		for dst = max_slot, slot + 1, -1 do
			self.Slots[dst].Value = self.Slots[dst - 1].Value
		end
		self.Slots[slot].Value = nil
	end
end

-- find the pet in a slot and remove it
function PlayerPets:PetUnequip(pet_name)
	for slot, ov in pairs(self.Slots) do
		if ov.Value ~= nil and ov.Value.Name == pet_name then
			print(self.player, "PetUnequip:", pet_name, "slot", slot)
			ov.Value = nil
			self:PetSlotCompress()
			return
		end
	end
end

-- find the first free slot and add the pet there
-- @return whether it was added
function PlayerPets:PetEquip(pet_name)
	local pet = self.Pets:FindFirstChild(pet_name)
	if pet == nil then
		warn(self.player, "PetEquip:", pet_name, "not found")
		return false
	end

	for slot, ov in pairs(self.Slots) do
		if ov.Value == nil then
			print(self.player, "PetEquip:", pet_name, "in slot", slot)
			ov.Value = pet
			return true
		end
	end

	warn(self.player, "PetEquip:", pet_name, "no slots")
	return false
end

-- unequips and then deletes the pet
function PlayerPets:PetDel(pet_name)
	local oldpet = self.Pets:FindFirstChild(pet_name)
	if oldpet ~= nil then
		self:PetUnequip(pet_name)
		oldpet:Destroy()
	end
end

-- equips the pet, which is a Clone of the ref pet.
-- the unique name must already be set.
function PlayerPets:PetAdd(pet, equip)
	self:PetDel(pet.Name)

	pet.Parent = self.Pets

 	return self:PetEquip(pet.Name)
end

return PlayerPets
