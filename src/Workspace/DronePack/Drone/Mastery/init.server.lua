local Drone = script.Parent
local Settings = require(script.Settings)
local Event = Drone:WaitForChild('Event')
local Function = Drone:WaitForChild('Function')
local Tool = script:WaitForChild('Drone')
	Tool.Object.Value = Drone
local User = Drone:WaitForChild('User').Value

local Core = Drone:WaitForChild('Core')
	local ArmedSound = Core:WaitForChild('Armed')
	local FireSound = Core:WaitForChild('Fire')
	local ScanSound = Core:WaitForChild('Scan')
	local IdleSound = Core:WaitForChild('Idle')
	local Gyro = Core:WaitForChild('BodyGyro')
	local Velocity = Core:WaitForChild('BodyVelocity')

local Body = Drone:WaitForChild('Body')
	local REye = Body:WaitForChild('REye')
	local LEye = Body:WaitForChild('LEye')
	local Thrust = Body:WaitForChild('Thrust')

local Left = Drone:WaitForChild('Left')
	local LB = Left:WaitForChild('Barrel')
	local LS = Left:WaitForChild('Shoulder')
	local LG1 = Left:WaitForChild('Gun1')
	local LG2 = Left:WaitForChild('Gun2')

local Right = Drone:WaitForChild('Right')
	local RB = Right:WaitForChild('Barrel')
	local RS = Right:WaitForChild('Shoulder')
	local RG1 = Right:WaitForChild('Gun1')
	local RG2 = Right:WaitForChild('Gun2')

local Gui = Instance.new('BillboardGui',Core)
	Gui.Size = UDim2.new(4,0,1.5,0)
	Gui.StudsOffset = Vector3.new(0,4,0)

local Armed = 0
local Mode = 1
local MousePoint = Core.CFrame
local DroneWeld = nil
local CurrentDirection = 'Stop'
local Writing = false

local Cooldowns = {[1] = true,[2] = true}

function Castray(C1, C2, I, D)
	local newRay = Ray.new(C1.p, (C2.p - C1.p).unit * D)
	local hitObject, positionHit = workspace:FindPartOnRay(newRay, I)
	return positionHit, hitObject
end

function Bolt(P1,P2)
	local ray = Instance.new("Part")
	ray.TopSurface = Enum.SurfaceType.Smooth
	ray.BottomSurface = Enum.SurfaceType.Smooth
	ray.FormFactor = Enum.FormFactor.Custom
	ray.Size = Vector3.new(0.05, 0.05, 0.05)
	ray.CanCollide = false
	ray.Locked = true
	ray.Anchored = true
	ray.Name = "Laser"
	ray.BrickColor = Settings.LaserColor
	ray.Material = Enum.Material.Neon
	local raymesh = Instance.new("SpecialMesh")
	raymesh.Name = "Mesh"
	raymesh.MeshType = Enum.MeshType.Brick
	raymesh.Scale = Vector3.new(0.2, 0.2, 1)
	raymesh.Parent = ray
	local Vec = (P2 - P1)
	local Distance = Vec.magnitude
	local Direction = Vec.unit
	local PX = (P1 + (0.25 * Distance) * Direction)
	local PY = (P1 + (0.5 * Distance) * Direction)
	local PZ = (P1 + (0.75 * Distance) * Direction)
	local DX = (P1 - PX).magnitude
	local DY = (PX - PY).magnitude
	local DZ = (PY - PZ).magnitude
	local Limit = 2
	local AX = (PX + Vector3.new(math.random(math.max(-Limit, (-0.21 * DX)), math.min(Limit, (0.21 * DX))),math.random(math.max(-Limit, (-0.21 * DX)),math.min(Limit, (0.21 * DX))), math.random(math.max(-Limit, (-0.21 * DX)), math.min(Limit, (0.21 * DX)))))
	local AY = (PY + Vector3.new(math.random(math.max(-Limit, (-0.21 * DY)), math.min(Limit, (0.21 * DY))),math.random(math.max(-Limit, (-0.21 * DY)),math.min(Limit, (0.21 * DY))), math.random(math.max(-Limit, (-0.21 * DY)), math.min(Limit, (0.21 * DY)))))
	local AZ = (PZ + Vector3.new(math.random(math.max(-Limit, (-0.21 * DZ)), math.min(Limit, (0.21 * DZ))),math.random(math.max(-Limit, (-0.21 * DZ)),math.min(Limit, (0.21 * DZ))), math.random(math.max(-Limit, (-0.21 * DZ)), math.min(Limit, (0.21 * DZ)))))
	local Rays = {
		{Distance = (AX - P1).magnitude, Direction = CFrame.new(P1, AX)},
		{Distance = (AY - AX).magnitude, Direction = CFrame.new(AX, AY)},
		{Distance = (AZ - AY).magnitude, Direction = CFrame.new(AY, AZ)},
		{Distance = (P2 - AZ).magnitude, Direction = CFrame.new(AZ, P2)},
	}
	local th = 0.05
	for i, v in pairs(Rays) do
		local Ray = ray:Clone()
		local Mesh = Ray.Mesh
		Mesh.Scale = (Vector3.new(th, th, (v.Distance / 1)) * 5)
		Ray.CFrame = (v.Direction * CFrame.new(0, 0, (-0.5 * v.Distance)))
		game:GetService('Debris'):AddItem(Ray, (0.2 / (#Rays - (i - 1))))
		Ray.Parent = workspace
	end
end

function Laser(V1,V2)
	local Part = Instance.new ("Part",workspace)
	Part.Material = Enum.Material.Neon
	Part.BrickColor = Settings.LaserColor
	Part.Anchored = true
	Part.Size = Vector3.new (0.2,0.2,(V1 - V2).magnitude)
	Part.CanCollide = false
	Part.CFrame = CFrame.new((V1 + V2)/2,V1)
	local m = Instance.new ("BlockMesh",Part)
	m.Scale = Vector3.new(0.5,0.5,1)
	game:GetService("Debris"):AddItem(Part,0.1)
end

function Eyes(Color)
	LEye.BrickColor = Color
	REye.BrickColor = Color
end

function MoveShoulder(dir)
	for i = 1,7 do
		LS.Weld.C1 = LS.Weld.C1 * CFrame.new(0.1 * dir,0,0)
		RS.Weld.C1 = RS.Weld.C1 * CFrame.new(-0.1 * dir,0,0)
		wait()
	end
end

function MoveGun(dir)
	for i = 1,20 do
		LB.Weld.C1 = LB.Weld.C1 * CFrame.new(0,0,0.1 * dir)
		RB.Weld.C1 = RB.Weld.C1 * CFrame.new(0,0,0.1 * dir)
		wait()
	end
end

function Recoil()
	spawn(function()
		for i = 1,5 do
			LB.Weld.C1 = LB.Weld.C1 * CFrame.new(0,0,-0.1)
			RB.Weld.C1 = RB.Weld.C1 * CFrame.new(0,0,-0.1)
			wait()
		end
		for i = 1,5 do
			LB.Weld.C1 = LB.Weld.C1 * CFrame.new(0,0,0.1)
			RB.Weld.C1 = RB.Weld.C1 * CFrame.new(0,0,0.1)
			wait()
		end
	end)
end

function VisibleHats(Player,Transparency)
	for _,bpart in pairs(Player.Character:GetChildren()) do
		if bpart:IsA("Part") and bpart.Name ~= "HumanoidRootPart" then
			bpart.Transparency = Transparency
		elseif bpart:IsA("Hat") then
			for _,hat in pairs(bpart:GetChildren()) do
				if hat:IsA("Part") then
					hat.Transparency = Transparency
				end
			end
		end
	end
end

local RemoteFunctions = {}
local KeyFunctions = {}

function KeyFunctions.Go(KeyName,MouseHit)
	CurrentDirection = KeyName
	Velocity.Velocity = MousePoint.lookVector  * Settings.Speed
	Gyro.CFrame = MouseHit
end

function KeyFunctions.Stop(KeyName)
	CurrentDirection = KeyName
	Velocity.Velocity = Vector3.new(0,0,0)
end

function KeyFunctions.Up(KeyName)
	CurrentDirection = KeyName
	Velocity.Velocity = Vector3.new(0,Settings.Speed/2,0)
end

function KeyFunctions.Down(KeyName)
	CurrentDirection = KeyName
	Velocity.Velocity = Vector3.new(0,-Settings.Speed/2,0)
end

function KeyFunctions.Arm(KeyName,MouseHit)
	if Armed ~= 2 then
		if Armed == 0 then
			Armed = 2
			ArmedSound:Play()
			Gyro.CFrame = MouseHit
			Eyes(Settings.ArmedColor)
			MoveShoulder(1)
			MoveGun(1)
			Armed = 1
			return true
		elseif Armed == 1 then
			Armed = 2
			Eyes(Settings.UnarmedColor)
			MoveShoulder(-1)
			MoveGun(-1)
			Armed = 0
			return false
		end
	end
	return false
end

function KeyFunctions.Light()
	if Core.SpotLight.Enabled == false then
		Core.SpotLight.Enabled = true
	elseif Core.SpotLight.Enabled == true then
		Core.SpotLight.Enabled = false
	end
end

function KeyFunctions.Switch()
	if Mode == 1 then
		Mode = 2
	elseif Mode == 2 then
		Mode = 1
	end
end

function RemoteFunctions.KeyDown(Player,KeyName,MouseHit)
	return KeyFunctions[KeyName](KeyName, MouseHit)
end

function RemoteFunctions.Entrance(Player)
	IdleSound:Play()
	DroneWeld = Instance.new ("Weld",Player.Character.Torso)
	DroneWeld.Part0 = User.Character.Torso
	DroneWeld.Part1 = Core
	DroneWeld.Name = "DroneWeld"
	User.Character.Humanoid.CameraOffset = Vector3.new (5,5,-5)
	User.CameraMinZoomDistance = 10
	User.Character.Humanoid.PlatformStand = true
	VisibleHats(Player,1)
	Thrust.BrickColor = BrickColor.new('Cyan')
	Thrust.Material = Enum.Material.Neon
	return true
end

function RemoteFunctions.Exit(Player)
	IdleSound:Stop()
	if DroneWeld then
		DroneWeld.C0 = Core.CFrame * CFrame.new (0,6,0)
		DroneWeld:Destroy()
		DroneWeld = nil
	end
	Player.Character.Humanoid.PlatformStand = false
	CurrentDirection = 'Stop'
	Velocity.Velocity = Vector3.new(0,0,0)
	VisibleHats(Player,0)
	Player.CameraMinZoomDistance = 0.5
	Player.Character.Humanoid.CameraOffset = Vector3.new (0,0,0)
	Thrust.BrickColor = BrickColor.new('Really black')
	Thrust.Material = Enum.Material.SmoothPlastic
	return true
end

function RemoteFunctions.Fire(Player,Target)
	MousePoint = Target
	Gyro.CFrame = Target
	if CurrentDirection == 'Go' then
		Velocity.Velocity = MousePoint.lookVector  * Settings.Speed
	end
	if Armed == 1 and Cooldowns[Mode] == true then
		Cooldowns[Mode] = false
		local Position1,Hit1 = Castray(LG1.CFrame,Target,Left,Settings.Range)
		local Position2,Hit2 = Castray(RG1.CFrame,Target,Right,Settings.Range)
		FireSound:Play()
		Recoil()
		if Mode == 1 then
			Laser(LG1.Position,Position1)
			Laser(RG1.Position,Position2)
		else
			Bolt(LG2.Position,Position1)
			Bolt(RG2.Position,Position2)
		end
		delay(Settings.ShotCooldown,function()
			Cooldowns[Mode] = true
		end)
		return true
	end
	return false
end

function RemoteFunctions.Chat(Player,Text)
	spawn(function()
		repeat wait() until Writing == false
		Writing = true
		local Label = Instance.new('TextLabel',Gui)
		Label.BackgroundTransparency = 1
		Label.Text = ""
		Label.Size = UDim2.new(1,0,1,0)
		Label.TextColor3 = Color3.new(1,1,1)
		Label.TextStrokeColor3 = Color3.new(0,0,0)
		Label.TextStrokeTransparency = 0.5
		Label.TextWrapped = true
		Label.TextScaled = true
		--Label.TextXAlignment = Enum.TextXAlignment[X]
		--Label.TextYAlignment = Enum.TextYAlignment[Y]
		game:GetService('Debris'):AddItem(Label,(string.len(Text) * 0.03)+ 2)
		--game:GetService('Debris'):AddItem(Label,string.len(Text))
		for i = 1, string.len(Text) do
			Label.Text = Label.Text .. string.sub(Text,i,i)
			wait(0.03)
		end
		wait(2)
		Writing = false
	end)
end

function RemoteFunctions.Damage(Player,Humanoid,Damage)
	if Humanoid then Humanoid:TakeDamage(Damage) end
end

Event.OnServerEvent:connect(function(Player,FunctionName,a1,a2,a3,a4)
	RemoteFunctions[FunctionName](Player,a1,a2,a3,a4)
end)

function Function.OnServerInvoke(Player,FunctionName,a1,a2,a3,a4)
	return RemoteFunctions[FunctionName](Player,a1,a2,a3,a4)
end

game:GetService('RunService').Stepped:connect(function()
	if CurrentDirection == 'Go' then
		Velocity.Velocity = Gyro.CFrame.lookVector * Settings.Speed
	end
end)

local NewTool = Tool:Clone()
NewTool.Parent = User.Backpack

spawn(function()
	while wait(math.random(20,100)) do
		ScanSound:Play()
	end
end)
