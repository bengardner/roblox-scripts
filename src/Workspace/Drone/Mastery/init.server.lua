wait(1)
local sp = script.Parent
local settings = require(script.Settings)
local armed = false
local gunsmoving = false
local standard = true
local occupant
local current = nil
local flying = false
local coframe = nil
local coframelook = nil
local mousehit = nil
local fireready = true
local idlesoundready = true

FastSpawn = function(func) -- Big thanks to ArceusInator
	local event = Instance.new 'BindableEvent'
	event.Event:connect(func)
	event:Fire()
	event:Destroy()
end

sp.Base.Click.MouseClick:connect(function(player)
	if occupant == nil then
		occupant = player
		sp.Base.Click.MaxActivationDistance = 0
		sp.Parent = player.Character
		local tool = script.DroneClient
		local objval = Instance.new ("ObjectValue",tool.Client)
		objval.Value = sp
		tool.Parent = player.Backpack
		objval.Name = "Object"
		tool.Client.Disabled = false
		--client.Client.Disabled = false
	end
end)

function castray(cframeFirst, cframeSecond, ignoreObject)
	local newRay = Ray.new(cframeFirst.p, (cframeSecond.p - cframeFirst.p).unit * settings.Range)
	local hitObject, positionHit = workspace:FindPartOnRay(newRay, ignoreObject)
	return positionHit, hitObject
end

function laser(start,stop)
	FastSpawn(function()
		local part = Instance.new ("Part",workspace)
		part.FormFactor = 3
		part.Material = Enum.Material.Neon
		part.BrickColor = settings.LaserColor
		part.Anchored = true
		part.Size = Vector3.new (0.2,0.2,(start.Position - stop).magnitude)
		part.CanCollide = false
		part.CFrame = CFrame.new((start.Position + stop)/2,start.Position)
		local m = Instance.new ("BlockMesh",part)
		m.Scale = Vector3.new(0.5,0.5,1)
		game:GetService("Debris"):AddItem(part,1)
		for i = 1,5 do
			m.Scale = Vector3.new (m.Scale.X-0.1,m.Scale.Y-0.1,1)
			wait()
		end
	end)
end

function Entrance(target)
	local weld = Instance.new ("Weld",target.Character.Torso)
	weld.Part0 = target.Character.Torso
	weld.Part1 = sp.Core
	weld.Name = "DroneWeld"
	target.Character.Humanoid.CameraOffset = Vector3.new (5,5,-5)
	target.CameraMinZoomDistance = 10
	target.Character.Humanoid.PlatformStand = true
	for _,bpart in pairs(target.Character:GetChildren()) do
		if bpart:IsA("Part") and bpart.Name ~= "HumanoidRootPart" then
			bpart.Transparency = 1
		elseif bpart:IsA("Hat") then
			for _,hat in pairs(bpart:GetChildren()) do
				if hat:IsA("Part") then
					hat.Transparency = 1
				end
			end
		end
	end
end

game:GetService("RunService").Stepped:connect(function()
	if current ~= nil and flying == true and occupant and coframe ~= nil and coframelook ~= nil then
		if idlesoundready == true then
			idlesoundready = false
			sp.Core.Idle:Play()
			delay(math.random(4,8),function()
				idlesoundready = true
			end)
		end
		local bv = sp.Core.BodyVelocity
		local bg = sp.Core.BodyGyro
		sp.Body.Thrust.Particles.Acceleration = Vector3.new (sp.Core.CFrame.lookVector.X*10,-5,sp.Core.CFrame.lookVector.Z*10)
		if current == "W" then
			bv.velocity = sp.Core.CFrame.lookVector  * settings.Speed
			--bg.CFrame = bg.CFrame * CFrame.Angles(math.rad(-13),0,0)
		elseif current == "S" then
			bv.velocity = Vector3.new (0,0,0)
		elseif current == "Q" then
			bv.velocity = Vector3.new(0,settings.Speed,0)
		elseif current == "E" then
			bv.velocity = Vector3.new(0,settings.Speed*-1,0)
		end

	end
end)

function Exit(target)
	sp.Core.Idle:Stop()
	if target.Character.Torso:FindFirstChild("DroneWeld") ~= nil then target.Character.Torso:FindFirstChild("DroneWeld"):Destroy() end
	target.Character.Humanoid.PlatformStand = false
	sp.Core.CFrame = sp.Core.CFrame * CFrame.new (7,0,0)
	for _,bpart in pairs(target.Character:GetChildren()) do
		if bpart:IsA("Part") and bpart.Name ~= "HumanoidRootPart" then
			bpart.Transparency = 0
		elseif bpart:IsA("Hat") then
			for _,hat in pairs(bpart:GetChildren()) do
				if hat:IsA("Part") then
					hat.Transparency = 0
				end
			end
		end
	end
	target.CameraMinZoomDistance = 0.5
	target.Character.Humanoid.CameraOffset = Vector3.new (0,0,0)
end


function MoveShoulder(dir)
	if dir == "Out" then
		for i = 1,7 do
			sp.Left.Shoulder.Weld.C1 = sp.Left.Shoulder.Weld.C1 * CFrame.new(0.1,0,0)
			sp.Right.Shoulder.Weld.C1 = sp.Right.Shoulder.Weld.C1 * CFrame.new(-0.1,0,0)
			wait()
		end
	elseif dir == "In" then
		for i = 1,7 do
			sp.Left.Shoulder.Weld.C1 = sp.Left.Shoulder.Weld.C1 * CFrame.new(-0.1,0,0)
			sp.Right.Shoulder.Weld.C1 = sp.Right.Shoulder.Weld.C1 * CFrame.new(0.1,0,0)
			wait()
		end
	end
end

function MoveGun(dir)
	--FastSpawn(function()
		if dir == "Out" then
			for i = 1,20 do
				sp.Left.Barrel.Weld.C1 = sp.Left.Barrel.Weld.C1 * CFrame.new(0,0,0.1)
				sp.Right.Barrel.Weld.C1 = sp.Right.Barrel.Weld.C1 * CFrame.new(0,0,0.1)
				wait()
			end
		elseif dir == "In" then
			for i = 1,20 do
				sp.Left.Barrel.Weld.C1 = sp.Left.Barrel.Weld.C1 * CFrame.new(0,0,-0.1)
				sp.Right.Barrel.Weld.C1 = sp.Right.Barrel.Weld.C1 * CFrame.new(0,0,-0.1)
				wait()
			end
		end
	--end)
end

function Recoil()
	FastSpawn(function()
		for i = 1,5 do
			sp.Left.Barrel.Weld.C1 = sp.Left.Barrel.Weld.C1 * CFrame.new(0,0,-0.1)
			sp.Right.Barrel.Weld.C1 = sp.Right.Barrel.Weld.C1 * CFrame.new(0,0,-0.1)
			wait()
		end
		for i = 1,5 do
			sp.Left.Barrel.Weld.C1 = sp.Left.Barrel.Weld.C1 * CFrame.new(0,0,0.1)
			sp.Right.Barrel.Weld.C1 = sp.Right.Barrel.Weld.C1 * CFrame.new(0,0,0.1)
			wait()
		end
	end)
end

function Weaponize()
	if gunsmoving == false then
		gunsmoving = true
		if armed == false then
			sp.Core.Armed:Play()
			sp.Body.LEye.BrickColor = settings.ArmedColor
			sp.Body.REye.BrickColor = settings.ArmedColor
			MoveShoulder("Out")
			MoveGun("Out")
			gunsmoving = false
			armed = true
		elseif armed == true then
			armed = false
			sp.Body.LEye.BrickColor = settings.UnarmedColor
			sp.Body.REye.BrickColor = settings.UnarmedColor
			MoveShoulder("In")
			MoveGun("In")
			gunsmoving = false
		end
	end
end

function Fire(gun,target)
	if gunsmoving == false and armed == true and fireready == true and mousehit ~= nil then
		fireready = false
		sp.Core.Fire:Play()
		sp.Core.BodyGyro.CFrame = mousehit
		local start1 = sp.Right:FindFirstChild(gun)
		local start2 = sp.Left:FindFirstChild(gun)
		local pos1,hit1 = castray(start1.CFrame,mousehit,sp.Right)
		local pos2,hit2 = castray(start2.CFrame,mousehit,sp.Left)
		Recoil()
		laser(start1,pos1)
		laser(start2,pos2)
		if hit1 then
			if hit1.Parent:FindFirstChild("Humanoid")and hit1.Parent ~= sp.Parent or hit1.Parent.Parent:FindFirstChild("Humanoid") and hit1.Parent ~= sp.Parent then
				local tplr = game.Players:GetPlayerFromCharacter(hit1.Parent)
				if tplr == nil then tplr = game.Players:GetPlayerFromCharacter(hit1.Parent.Parent) end
					if tplr then
						local hum = tplr.Character:FindFirstChild("Humanoid")
						if settings.TeamKill == true then
						if hum then
							hum:TakeDamage(settings.Damage)
						end
					else
						if hum then
							if tplr.TeamColor ~= occupant.TeamColor then hum:TakeDamage(settings.Damage) end
						end
					end
				elseif tplr == nil then
					local hum = hit1.Parent:FindFirstChild("Humanoid")
					if hum == nil then hum = hit1.Parent.Parent:FindFirstChild("Humanoid") end
					if hum then
						hum:TakeDamage(settings.Damage)
					end
				end
			end
		end
		if hit2 then
			if hit2.Parent:FindFirstChild("Humanoid")and hit2.Parent ~= sp.Parent or hit2.Parent.Parent:FindFirstChild("Humanoid") and hit2.Parent ~= sp.Parent then
				local tplr = game.Players:GetPlayerFromCharacter(hit2.Parent)
				if tplr == nil then tplr = game.Players:GetPlayerFromCharacter(hit2.Parent.Parent) end
					if tplr then
						local hum = tplr.Character:FindFirstChild("Humanoid")
						if settings.TeamKill == true then
						if hum then
							hum:TakeDamage(settings.Damage)
						end
					else
						if hum then
							if tplr.TeamColor ~= occupant.TeamColor then hum:TakeDamage(settings.Damage) end
						end
					end
				elseif tplr == nil then
					local hum = hit2.Parent:FindFirstChild("Humanoid")
					if hum == nil then hum = hit2.Parent.Parent:FindFirstChild("Humanoid") end
					if hum then
						hum:TakeDamage(settings.Damage)
					end
				end
			end
		end
		delay(settings.ShotCooldown,function()
			fireready = true
		end)
	end
end

script.Event.OnServerEvent:connect(function(player,a1,a2,a3,a4,a5)
	if a1 == "FireStandard" then
		Fire("Gun1",a2)
	elseif a1 == "Arm" then
		Weaponize()
	elseif a1 == "Selected" then
		Entrance(a2)
		flying = true
		sp.Body.Thrust.Particles.Enabled = true
		sp.Core.BodyVelocity.maxForce = Vector3.new(999999,999999,999999)
		sp.Core.BodyGyro.maxTorque = Vector3.new(0.1,0.1,0.1)
	elseif a1 == "Deselected" then
		Exit(a2)
		flying = false
		current = false
		sp.Body.Thrust.Particles.Enabled = false
		sp.Core.BodyVelocity.maxForce = Vector3.new(0,0,0)
	elseif a1 == "W" or a1 == "S" or a1 == "A" or a1 == "D" or a1 == "Q" or a1 == "E" then
		current = a1
	elseif a1 == "MouseHit" then
		if occupant ~= nil then
			mousehit = a2
			sp.Core.BodyGyro.cframe = a2
		end
	elseif a1 == "CoFrame" then
		coframe = a2
	elseif a1 == "CoFrameLook" then
		coframelook = a2
	end
end)
