--[[
This script will add a repeating rotate tween to anypart tagged with 'PlayerCoin'
--]]
local CoinInfo = require(game.ReplicatedStorage.Scripts.CoinInfo)
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()

local TAG_NAME = CoinInfo.TagName

-- cache coin info
-- .info is the coin info, .spin_tween is the spinner tween, .fade_tween is a map of fade tweens
local tagged_item = {}

local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false, 0)
local tweenInfo_end = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)

local function get_pp(coin)
	local pp
	if coin:IsA("BasePart") then
		pp = coin
	elseif coin:IsA("Model") then
		pp = coin.PrimaryPart
	end
	return pp
end

local function fade_tweens_start_part(pi, part, twi)
	pi:TweenAdd(TweenService:Create(part, twi, { Transparency = 1 }))
end

local function tween_fade(pi, twi)
	local part = pi.part
	if part:IsA("BasePart") then
		fade_tweens_start_part(pi, part, twi)
	end

	for k, v in pairs(part:GetDescendants()) do
		if v:IsA('Decal') or v:IsA('BasePart') then
			fade_tweens_start_part(pi, v, twi)
		end
	end
end

local function onTagAdded(coin)
	--print("RotatingCoin:onTagAdded:", coin)
	-- annoying, but the tag gets replicated before the children. need to wait 1 cycle.
	wait()

	local pp = get_pp(coin)
	if pp == nil then return end

	local pi = CoinInfo.PartInfo(coin)
	if pi == nil then
		warn("Missing info:", coin)
		return
	end

	pi.pp = pp

	-- add the spin
	if pi.RotSec and pi.RotSec > 0 and pi.RotVec.Magnitude ~= 0 then
		local tweenInfo = TweenInfo.new(pi.RotSec, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false, 0)
		local goal = { Orientation = Vector3.new( pp.Orientation.X + pi.RotVec.X, pp.Orientation.Y + pi.RotVec.Y, pp.Orientation.Z + pi.RotVec.Z)}
		pi:TweenAdd(TweenService:Create(pp, tweenInfo, goal))
	end

	-- add the bob
	if pi.BobSec > 0 then
		local tweenInfo = TweenInfo.new(pi.BobSec, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0)
		local goal = { Position = Vector3.new( coin.Position.X, coin.Position.Y + pi.BobY, coin.Position.Z )}
		pi:TweenAdd(TweenService:Create(coin, tweenInfo, goal))
	end

	-- add the fade-out
	-- FIXME: handle LifeSec < 5
	if pi.LifeSec and pi.LifeSec > 0 then
		--- fade out the last 5 seconds
		tween_fade(pi, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, math.max(0, pi.LifeSec - 5)), pi.fade_tween)
	end

	tagged_item[coin] = pi
end

-- pickup animation: rotate the coin upwards, increase its size and fade it out
local function anim_GrowRotUpFade(pi)
	local tween = TweenService:Create(pi.pp, tweenInfo_end, {
		Size = Vector3.new( pi.pp.Size.X * 3, pi.pp.Size.Y * 3, pi.pp.Size.Z * 3),
		Orientation = Vector3.new( pi.pp.Orientation.X, pi.pp.Orientation.Y, pi.pp.Orientation.Z + 90),
		Position = Vector3.new( pi.pp.Position.X, pi.pp.Position.Y + 8, pi.pp.Position.Z),
		Transparency = 1 })
	tween:Play()

	tween_fade(pi, tweenInfo_end)

	-- revisit: do we need to find all meshes?
	local mesh = pi.part:FindFirstChild('Mesh')
	if mesh then
		local tsi = TweenService:Create(mesh, tweenInfo_end, {
			Scale = Vector3.new( mesh.Scale.X * 3, mesh.Scale.Y * 3, mesh.Scale.Z * 3) })
		tsi:Play()
	end
end

-- pickup animation: rotate the coin upwards and fade it out
local function anim_RotUpHold(pi)
	local pp = pi.pp
	local tween = TweenService:Create(pp, tweenInfo_end, {
		--Orientation = Vector3.new( pp.Orientation.X, pp.Orientation.Y, pp.Orientation.Z + 90),
		Orientation = Vector3.new( 0, 0, 90),
		Position = Vector3.new( pp.Position.X, pp.Position.Y + pp.Size.Y / 2, pp.Position.Z) })

	local ti_fade = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.5)
	tween_fade(pi, ti_fade)

	tween:Play()
end

-- pickup animation: quickly fade out the coin
local function anim_None(pi)
	pi:TransSet(0.5)
end

--[[
We use the onTagRemoved to indicate that the coin was picked up.
If it was deleted, then the coin will vanish soon anyway.
]]
local function onTagRemoved(coin)
	local pi = tagged_item[coin]
	if pi == nil then return end

	local owner = coin:FindFirstChild("Owner")

	print("RotatingCoin:onTagRemoved:", coin, 'parent:', coin.Parent, owner)

	-- if owner.Value is not my player.UserId, then simply remove our copy of the coin (Destory it)
	if owner == nil or player.UserId ~= owner.Value then
		coin:Destroy()
		return
	end

	local pp = pi.pp

	-- cancel any tweens
	pi:TweensCancel()

	-- undo any fading
	pi:TransRestore()

	if pi.Pickup == 'GrowRotUpFade' then
		anim_GrowRotUpFade(pi)

	elseif pi.Pickup == 'RotUpHold' then
		anim_RotUpHold(pi)

	else
		anim_None(pi)
	end

	Debris:AddItem(coin, 1)
end

-- Generic code below, should be put in a ModuleScript, maybe
local tagAddedSignal = CollectionService:GetInstanceAddedSignal(TAG_NAME)
local tagRemovedSignal = CollectionService:GetInstanceRemovedSignal(TAG_NAME)

-- Listen for existing tags, tag additions and tag removals for the door tag
for _,inst in pairs(CollectionService:GetTagged(TAG_NAME)) do
	onTagAdded(inst)
end
tagAddedSignal:Connect(onTagAdded)
tagRemovedSignal:Connect(onTagRemoved)
