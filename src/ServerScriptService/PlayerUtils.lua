--[[
Properly handle adding and removing players.
Also, a few misc player/character functions.

	Register_onPlayerAdded(onPlayerAdded)
		Attach an onPlayerAdded callback and calls the function for all current players.
			onPlayerAdded(player)

	Register_onPlayerRemoving(onPlayerRemoving)
		Attach an onPlayerRemoving callback.
		Added to be complete.
			onPlayerRemoving(player)

	Register_Player(onPlayerAdded, onPlayerRemoving)
		Attach to the onPlayerAdded and onPlayerRemoving events.
		Combines Register_onPlayerAdded() and Register_onPlayerRemoving()
 		Either one may be nil.
			onPlayerAdded(player)
			onPlayerRemoving(player)

	Register_onCharacterAdded(player, onCharacterAdded)
		Attach the onCharacterAdded() event for one or all characters.
		This is triggered when the character is first added.
		If player is nil, this will use Register_onPlayerAdded() to attach the character functions.
		The onCharacterAdded() function gets both the player and character (might need to revisit that!)
			onCharacterAdded(player, character)

	Register_onCharacterLoaded(player, onCharacterLoaded)
		Attach to the CharacterAppearanceLoaded event for one or all players.
		This is triggered after the character is fully loaded.
		If player is nil, this will use Register_onPlayerAdded() to attach the character functions.
		The onCharacterLoaded() function gets both the player and character (might need to revisit that!)
			onCharacterLoaded(player, character)

	function module.CharAlive(char)
		Check to see if a character is "alive".

	function module.PlayerCharInfo(player)
		return the Character, Humanoid, HumanoidRootPart for a player if it is alive.
--]]
local Players = game:GetService("Players")

local module = {}

-- Register a callback for Players.PlayerAdded and call a function for existing players
function module.Register_onPlayerAdded(onPlayerAdded)
	Players.PlayerAdded:Connect(onPlayerAdded)

	-- call onPlayerAdded() for players added before this call
	for _, player in pairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

-- Register a callback for Players.PlayerAdded and call a function for existing players
function module.Register_onPlayerRemoving(onPlayerRemoving)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

-- Register both onPlayerAdded and onPlayerRemoving
function module.Register_Player(onPlayerAdded, onPlayerRemoving)
	if onPlayerRemoving then
		module.Register_onPlayerRemoving(onPlayerRemoving)
	end
	if onPlayerAdded then
		module.Register_onPlayerAdded(onPlayerAdded)
	end
end

--[[
Attach a function to the CharacterAdded event.
Call the function for all existing characters.
]]
function module.Register_onCharacterAdded(player, onCharacterAdded)
	if player ~= nil then
		player.CharacterAdded:Connect(function(character)
			-- REVISIT: this event gets called before char.Parent is set in studio
			task.wait()
			onCharacterAdded(player, character)
		end)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
	else
		-- add a callback to call onCharacterAdded() when a player is added
		module.Register_onPlayerAdded(function(new_player)
			module.Register_onCharacterAdded(new_player, onCharacterAdded)
		end)
	end
end

--[[
Attach a callback to the CharacterAppearanceLoaded event.
Call the function for all currently loaded characters.
]]
function module.Register_onCharacterLoaded(onCharacterLoaded, player)
	if player ~= nil then
		player.CharacterAppearanceLoaded:Connect(function(character)
			-- sadly, this event gets called before char.Parent is set in studio
			task.wait()
			onCharacterLoaded(player, character)
		end)
		if player:HasAppearanceLoaded() then
			onCharacterLoaded(player, player.Character)
		end
	else
		module.OnPlayerAdded(function(new_player)
			module.OnCharacterLoaded(onCharacterLoaded, new_player)
		end)
	end
end

--[[
Check to see if the character is "alive".
NOTE: this won't work if the player appearance hadn't been loaded
]]
function module.CharAlive(char)
	-- an alive character has to have a parent and primary part
	--print('CharAlive:', char, char.Parent, char.PrimaryPart)
	if char and char.Parent and char.PrimaryPart then
		-- it also must have a humanoid part and not be dead
		local hum = char:FindFirstChildOfClass("Humanoid")
		--print('CharAlive:', 'hum', hum, hum:GetState(), hum.Health)
		if hum and hum:GetState() ~= Enum.HumanoidStateType.Dead and hum.Health > 0 then
			return true
		end
	end
	return false
end

--[[
Fetch the character, humanoid, and humanoidrootpart for a player if the character is alive
returns nil if the character is dead or not present.
]]
function module.PlayerCharInfo(player)
	local char = player.Character
	if char ~= nil then
		local hum = char:FindFirstChildOfClass("Humanoid")
		local hrp = char.PrimaryPart or char:FindFirstChild("HumanoidRootPart")

		if hrp ~= nil and hum ~= nil and hum:GetState() ~= Enum.HumanoidStateType.Dead and hum.Health > 0 then
			return char, hum, hrp
		end
	end
	return nil
end

return module
