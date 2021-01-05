script.Parent.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChild("Humanoid") then
		local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
		if plr then
			if not plr.PlayerGui:FindFirstChild("GUIClonedfromtouchblock") then
				local clonedgui = script.Parent:FindFirstChildOfClass("ScreenGui"):Clone()
				clonedgui.Name = "GUIClonedfromtouchblock"
				clonedgui.Parent = plr.PlayerGui
				script.Parent.TouchEnded:Connect(function(hit2)
					if hit == hit2 then
						game.Debris:AddItem(clonedgui,0)
					end
				end)
			end
		end
	end
end)
