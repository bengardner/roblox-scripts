--[[
Handles Mine block damage.
]]

local MineEvents = require(game.ReplicatedStorage:WaitForChild("MineEvents"))
local PlayerData = require(game.ServerScriptService.PlayerData)
local MineModule = require(game.ServerScriptService.MineModule)
local PlayerUtils = require(game.ServerScriptService.PlayerUtils)


--------------------------------------------------------------------------------
-- Applies damage to a block. Destroys the block.
--
-- @mine is the mine that the block belongs to
-- @block is the ore block getting damaged
-- @player is who is doing the damage
-- @dt is the delta time
function block_do_damage(mine, block, player, dt)
	local data = PlayerData:Get(player)

	local hvv = block:FindFirstChild("Health")
	local cvv = block:FindFirstChild("Count")
	local dvv = block:FindFirstChild("Damage")

	if hvv and cvv and dvv then
		local hv = hvv.Value
		local cv = cvv.Value
		local dv = dvv.Value

		local damage = data:Get("tool_damage") * dt
		print("Player", player, "does", damage, "damage to", block)

		local dv = dv + damage
		while dv >= hv and cv > 0 do
			cv = cv - 1
			dv = dv - hv
		end

		if cv <= 0 then
			-- FIXME: for this to be more generic, this shold call a 'scoring' function that passes:
			--  * the player that finished off the block
			--  * an object that contains the player-to-damage done
			--  * the block details (to figure out ore content)
			print("Player", player, "destroyed", block)
			mine:Zap(block)
			-- FIXME: dummy coins_add until this is done right
			local pvv = block:FindFirstChild("Price")
			if pvv ~= nil then
				data:coins_add(pvv.Value)
			else
				data:coins_add(7)
			end
		else
			local ff = block:FindFirstChild("players")
			if ff == nil then
				ff = Instance.new("Folder")
				ff.Name = "players"
				ff.Parent = block
			end
			local pu = ff:FindFirstChild(player.Name)
			if pu == nil then
				pu = Instance.new("NumberValue")
				pu.Name = player.Name
				pu.Parent = ff
			end
			pu.Value = pu.Value + damage
			cvv.Value = cv
			dvv.Value = dv
			return true
		end
	end
	return false
end

-- attach to the event that allows the client to indicate what he is doing.
MineEvents.ServerAttachMine(function(player, block, tstamp)
	local data = PlayerData:Get(player)
	local mm
	if block ~= nil then
		mm = MineModule:FindMineForBlock(block)
		if mm == nil then
			warn("Unable to find the mine for", block)
			block = nil
		end
	end
	print(mm and mm.Name or "None", "MineEvent", player, block or "nil", tstamp)

	-- no char cancels the mining, as the player died
	local char = player.Character
	if char == nil then
		block = nil
	end

	local mt = data:Get("tool")
	if mt.tool == nil then
		warn(player, "No tool")
		block = nil
	end

	-- TODO: retrieve or look up the tool that the player has equipped to determine the
	-- mine speed and power. This may depend on the block type, so the function should receive
	-- the following:
	--  * player
	--  * mine
	--  * block info

	-- Update the block that the player is mining
	local old = data:Get("active_block")
	if old ~= nil and old.tstamp ~= nil then
		-- player was working on something
		if old.block == block then
			-- same block - shouldn't get this message!
			print("Player", player, "still working on", block)
			return
		end

		-- different block, calculate the damage done to the previous block
		local dt = tstamp - old.tstamp
		print("Player", player, "no longer working on", old.block)
		block_do_damage(old.mine, old.block, player, dt)
	end

	local ab = nil
	if block ~= nil then
		local pp = block
		if block:IsA("Model") then
			pp = block.PrimaryPart
		end
		ab = { mine=mm, block=block, pp=pp, tstamp=tstamp }
		mt:SetTarget(pp.Position)
	else
		print("Player", player, "not working")
		mt:SetTarget(nil)
	end
	data:Set("active_block", ab)
end)

MineEvents.ServerAttachExit(function(player)
	print("ExitMine:", player)
	local char = player.Character
	if char ~= nil and char.PrimaryPart ~= nil then
		local pp = char.PrimaryPart
		local mm = MineModule:FindMineForPosition(pp.Position)
		if mm == nil then
			print(player, "Not in a mine")
		elseif mm.exit_part == nil then
			print(player, "Exit part not set")
		else
			local ee = mm.exit_part
			print(player, "Exit part", ee)
			if ee ~= nil and ee:IsA("ObjectValue") then
				ee = ee.Value
			end
			if ee ~= nil then
				print(player, "Exit part2", ee)
				pp.CFrame = CFrame.new(ee.Position + Vector3.new(0, 8, 0))
			else
				warn(player, "exit_part is not set")
			end
		end
	end
end)

-- We need to kill the active_block when the character dies
PlayerUtils.Register_onCharacterAdded(nil, function(player, character)
	character:WaitForChild("Humanoid").Died:Connect(function()
		local data = PlayerData:Get(player)
		data:Set("active_block", nil)
	end)
end)

--------------------------------------------------------------------------------
-- damage loop
while true do
	-- NOTE: using the Heartbeat would be overkill
	wait(0.2)

	local now = os.clock()
	for player, data in pairs(PlayerData:GetAll()) do
		local ii = data:Get("active_block")
		if ii ~= nil and ii.tstamp ~= nil then
			local dt = now - ii.tstamp
			if block_do_damage(ii.mine, ii.block, player, dt) then
				ii.tstamp = now
			else
				-- block was destroyed
				data:Set("active_block", nil)
			end
		end
	end
end
