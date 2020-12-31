--[[
A stupid hack to properly handle adding and removing players.

There are 3 main functions:

	Register_onPlayerAdded(onPlayerAdded)
		Attach an onPlayerAdded callback and calls the function for all current players.

	Register_Player(onPlayerAdded, onPlayerRemoving)
		Attach to all the onPlayerAdded and onPlayerRemoving events.
		Combines Register_onPlayerAdded() with what should be Register_onPlayerRemoving()
 		Either one may be nil.

	Register_onCharacterAdded(player, onCharacterAdded)
		Attach the onCharacterAdded() event for one or all characters.
		If player is nil, this will use Register_onPlayerAdded() to attach the character functions.
		The onCharacterAdded() function gets both the player and character (might need to revisit that!)
--]]
local Players = game:GetService("Players")

local module = {}

function module.Register_onCharacterAdded(player, onCharacterAdded)
	if player ~= nil then
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
	else
		module.Register_onPlayerAdded(function(new_player)
			module.Register_onCharacterAdded(new_player, onCharacterAdded)
		end)
	end
end

function module.Register_onPlayerAdded(onPlayerAdded)
	Players.PlayerAdded:Connect(onPlayerAdded)

	-- call onPlayerAdded() for players added before this call
	for _, player in pairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

function module.OnPlayerAdded(onPlayerAdded)
	Players.PlayerAdded:Connect(onPlayerAdded)

	-- call onPlayerAdded() for players added before this call
	for _, player in pairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

-- Register both onPlayerAdded and onPlayerRemoving
function module.Register_Player(onPlayerAdded, onPlayerRemoving)
	if onPlayerRemoving then
		Players.PlayerRemoving:Connect(onPlayerRemoving)
	end
	if onPlayerAdded then
		module.Register_onPlayerAdded(onPlayerAdded)
	end
end
function module.OnPlayer(onPlayerAdded, onPlayerRemoving)
	if onPlayerRemoving then
		Players.PlayerRemoving:Connect(onPlayerRemoving)
	end
	if onPlayerAdded then
		module.OnPlayerAdded(onPlayerAdded)
	end
end

-- Register both onPlayerAdded and onPlayerRemoving
function module.OnPlayerAdded(onPlayerAdded, onPlayerRemoving)
	if onPlayerRemoving then
		Players.PlayerRemoving:Connect(onPlayerRemoving)
	end
	if onPlayerAdded then
		module.Register_onPlayerAdded(onPlayerAdded)
	end
end

-- register the OnCharacterAdded for *any* player or just one
function module.OnCharacterAdded(onCharacterAdded, player)
	if player ~= nil then
		player.CharacterAdded:Connect(function(character)
			-- sadly, this event gets called before char.Parent is set in studio
			wait()
			onCharacterAdded(character)
		end)
		if player.Character then
			onCharacterAdded(player.Character)
		end
	else
		module.OnPlayerAdded(function(new_player)
			module.OnCharacterAdded(onCharacterAdded, new_player)
		end)
	end
end

-- register the OnCharacterLoaded for *any* player or just one
function module.OnCharacterLoaded(onCharacterLoaded, player)
	if player ~= nil then
		player.CharacterAppearanceLoaded:Connect(function(character)
			-- sadly, this event gets called before char.Parent is set in studio
			wait()
			onCharacterLoaded(character)
		end)
		if player:HasAppearanceLoaded() then
			onCharacterLoaded(player.Character)
		end
	else
		module.OnPlayerAdded(function(new_player)
			module.OnCharacterLoaded(onCharacterLoaded, new_player)
		end)
	end
end

-- NOTE: this won't work if the player appearance hadn't been loaded
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
