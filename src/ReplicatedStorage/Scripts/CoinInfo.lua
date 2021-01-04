local CoinInfo = {}

CoinInfo.BindableEvent = Instance.new("BindableEvent")
CoinInfo.BindableEvent.Parent = script

CoinInfo.TagName = "PlayerCoin"

-- these are fields that can be sent as children of the part
CoinInfo.overrides = {
	Value   = 'IntValue',
	LifeSec = 'IntValue',
	-- REVISIT: these next 4 area questionable
	BobY    = 'IntValue',
	BobSec  = 'IntValue',
	RotVec  = 'Vector3Value',
	RotSec  = 'IntValue',
}

CoinInfo.defaults = {
	Value   = 1,
	--LifeSec = 120,
	BobY    = 2,
	BobSec  = 3,
	RotVec  = Vector3.new(0, 360, 0),
	RotSec  = 3,
	Sound   = "CoinPickup", -- see ReplicatedStorage.Sound
	Pickup  = "GrowRotUpFade",
}

--[[
Configuration for a coin "Class":
	- Model  : Required. the name of the BasePart in ServerStorage.
	- Color  : sets the "Color" field, default: no change.
	- Size   : multiplier for the size as either a number or vector3, default: no change
	- Height : how high above the ground to spawn, default: (BobY + Size.Y) / 2 + 1 (1 stud above the lowest point)
	- BobY   : how far the coin goes up and down, default: 3 [It doesn't make sense to bob in any other direction than up/down or Y]
	- BobSec : how long it takes for the bob to complete, default: 3 sec, 0=off
	- RotVec : degrees that the rotation will cover, default: Vector3(0,360,0) The values should be a multiple of 360.
	- RotSec : how long it takes for the rotation to complete, default: 3 sec, 0=off
	- Type   : the variable to increment in the PlayerData, default nil (do nothing)
	- Value  : the value for the coin
	- LifeSec: the number of seconds the coin will exist before automatic deletion, default: nil or no autodelete
	- Sound  : the name of the sound to plan on pickup
	- Pickup : the name of the "animation" to play on pickup: "GrowRotUpFade", "RotUpHold"
	           this is implemented in the localscript tag_PlayerCoin.

Upon pickup, the code will emit a BindableEvent (player, Class_Name, Value })
The info will contain the class name, the 'type' (which may be overridden) and the value.

A tagged coin must have the 'Class' StringValue. It may also have a 'Value' NumberValue or IntValue.
]]
CoinInfo.info = {
	pet = {
		Model = 'Pet',
		BobY = 2,
		BobSec = 5,
	},
	coin = {
		Model = 'Coin',
		BobY   = 3,
		BobSec = 5, -- seconds
		-- pick info
		Type   = 'coin',
		Value  = 1,
		Pickup  = "RotUpHold",
	},
	bigcoin = {
		Model = 'Coin',
		Size   = Vector3.new(2, 2, 2),
		BobY = 1,
		BobSec = 5, -- seconds
		RotSec = 6,
		RotVec  = Vector3.new(360, 360*2, 0),
		-- pick info
		Type   = 'coin',
		Value  = 10,
		Pickup  = "RotUpHold",
	},
	supercoin = {
		Model = 'Coin',
		Size   = Vector3.new(4, 4, 4),
		BobY = 0,
		BobSec = 0, -- seconds
		RotSec = 6,
		RotVec  = Vector3.new(360, 360*2, 360*3),
		-- pick info
		Type   = 'coin',
		Value  = 100,
		Pickup  = "None",
	},
	diamond_blue = {
		Model = 'Diamond',
		Color = Color3.fromRGB(10, 14, 255),
		Size   = Vector3.new(0.75, 0.75, 0.75),
		BobSec = 0, -- seconds
		RotSec = 5, -- seconds
		-- pick info
		Type   = 'gems',
		Value  = 1,
	},
	diamond_yellow = {
		Model = 'Diamond',
		Color = Color3.fromRGB(255, 236, 19),
		BobSec = 5, -- seconds
		RotSec = 5, -- seconds
		-- pick info
		Type   = 'gems',
		Value  = 10,
	},
	diamond_red = {
		Model = 'Diamond',
		Color = Color3.fromRGB(255, 99, 38),
		Size   = Vector3.new(1.25, 1.25, 1.25),
		BobSec = 5, -- seconds
		RotSec = 5, -- seconds
		-- pick info
		Type   = 'gems',
		Value  = 25,
	},
}

local function apply_defaults(t0, defaults)
	for k, v in pairs(defaults) do
		if t0[k] == nil then
			t0[k] = v
		end
	end
end

-- apply defaults
for class, info in pairs(CoinInfo.info) do
	apply_defaults(info, CoinInfo.defaults)
end

local function deepcopy(t0)
	local copy = {}
	if t0 then
		for k, v in pairs(t0) do
			if type(v) == "table" then
				copy[k] = deepcopy(v)
			else
				copy[k] = v
			end
		end
	end
	return copy
end

function CoinInfo.fromClass(class_name)
	local rinfo = CoinInfo.info[class_name]
	if rinfo ~= nil then
		return setmetatable(deepcopy(rinfo), CoinInfo)
	end
	print("did not find", class_name)
	return nil
end

-- REVISIT: Use LocalTransparencyModifier to modify transparency?
function CoinInfo:TransSave()
	local trans = {}
	if self.part:IsA("BasePart") then
		trans[self.part] = self.part.Transparency
	end
	for k, v in pairs(self.part:GetDescendants()) do
		if v:IsA('Decal') or v:IsA('BasePart') then
			trans[v] = v.Transparency
		end
	end
	self.trans = trans
end

-- set transparency by scaling the existing value.
-- if a part starts with 0.2, the value 0:1 would scale between 0.2:1.0
function CoinInfo:TransSet(value)
	for pp, vv in pairs(self.trans) do
		pp.Transparency = vv + (1 - vv) * value
	end
end

function CoinInfo:TransRestore(trans)
	for pp, vv in pairs(self.trans) do
		pp.Transparency = vv
	end
end

function CoinInfo:TweenAdd(tween)
	table.insert(self.tweens, tween)
	tween:Play()
end

function CoinInfo:TweensCancel()
	for i, tw in ipairs(self.tweens) do
		tw:Cancel()
		tw:Destroy()
	end
	self.tweens = {}
end

--[[
Get the info for a PlayerPickup from the part.
Looks up the class in the above and then applies overrides.
]]
function CoinInfo.PartInfo(part)
	local vv = part:FindFirstChild("Class")
	if vv == nil then
		warn(part, "Missing Class")
		return nil
	end

	local info = CoinInfo.fromClass(vv.Value)
	if info == nil then
		warn(part, "Missing Info", vv.Value)
		return
	end

	for k, v in pairs(CoinInfo.overrides) do
		local pp = part:FindFirstChild(k)
		if pp ~= nil then
			info[k] = pp.Value
		end
	end

	info.part = part
	info.tweens = {}

	info:TransSave()

	return info
end

--[[
Grab the coin class and apply overrides.
Server-side function.
]]
function CoinInfo.GetInfo(class_name, overrides)
	local info = CoinInfo.fromClass(class_name)
	if info == nil then
		warn(class_name, "Missing Info")
		return nil
	end

	if overrides ~= nil then
		for k, v in pairs(overrides) do
			if CoinInfo.overrides[k] ~= nil then
				info[k] = v
			end
		end
	end
	return info
end

CoinInfo.__index = CoinInfo

return CoinInfo
