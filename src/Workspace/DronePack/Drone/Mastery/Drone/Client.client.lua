local Player = game.Players.LocalPlayer
local Tool = script.Parent
repeat wait() until Tool.Parent.ClassName == "Backpack"
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera
local Drone = Tool:WaitForChild('Object').Value
local Core = Drone:WaitForChild('Core')
local Event = Drone:WaitForChild('Event')
local Function = Drone:WaitForChild('Function')

local Left = Drone:WaitForChild('Left')
	local LB = Left:WaitForChild('Barrel')
	local LS = Left:WaitForChild('Shoulder')
	local LG1 = Left:WaitForChild('Gun1')
	local LG2 = Left:WaitForChild('Gun2')

local Right = Drone:WaitForChild('Right')
	local RB = Right:WaitForChild('Barrel')
	local RS = Right:WaitForChild('Shoulder')
	local RG1 = Left:WaitForChild('Gun1')
	local RG2 = Left:WaitForChild('Gun2')

local Gui = Instance.new('ScreenGui',Player.PlayerGui)
local XS,YS = Gui.AbsoluteSize.X,Gui.AbsoluteSize.Y
	Gui.Name = 'DroneGui'
	local Frame = Instance.new('Frame',Gui)
		Frame.Visible = false
		Frame.BackgroundTransparency = 1
		Frame.Size = UDim2.new(1,0,1,0)
		local Temp = Frame:clone()
			Temp.Parent = Frame
			Temp.Visible = true
		local Cursor = Instance.new('ImageLabel',Frame)
			Cursor.Name = 'Cursor'
			Cursor.BackgroundTransparency = 1
			Cursor.Size = UDim2.new(0,30,0,30)
			Cursor.Image = 'rbxassetid://490539022'
		local CScroll = Instance.new('ScrollingFrame',Frame)
			CScroll.Name = 'ChatScroll'
			CScroll.BackgroundTransparency = 0.9
			CScroll.BorderColor3 = Color3.new(0,0,0)
			CScroll.Size = UDim2.new(0,math.ceil(XS * 0.15),0,math.ceil(YS * 0.1))
			CScroll.Position = UDim2.new(0.75,-CScroll.Size.X.Offset/2,0.5,-CScroll.Size.Y.Offset/2)
			CScroll.ScrollBarThickness = 0
			CScroll.Visible = false
		local TargetLine = Instance.new('Frame',Frame)
			TargetLine.Name = 'TargetLine'
			TargetLine.BorderSizePixel = 0
			TargetLine.Size = UDim2.new(0,0,0,0)
			TargetLine.BackgroundColor3 = Color3.new(1,1,1)
		local TargetLineDistance = Instance.new('TextLabel',Frame)
			TargetLineDistance.Name = 'TargetLineDistance'
			TargetLineDistance.BackgroundTransparency = 1
			TargetLineDistance.TextColor3 = Color3.new(1,1,1)
			TargetLineDistance.Font = Enum.Font.SourceSansLight
			TargetLineDistance.TextScaled = true
			TargetLineDistance.TextWrapped = true

local Settings = require(Drone:WaitForChild('Mastery'):WaitForChild('Settings'))

local Equipped = false
local Gun = 1
local Chats = {}
local LastTarget = nil
_G['Chats'] = _G['Chats'] or {}
Mouse.TargetFilter = Drone

function Castray(C1, C2, I, D)
	local newRay = Ray.new(C1.p, (C2.p - C1.p).unit * D)
	local hitObject, positionHit = workspace:FindPartOnRay(newRay, I)
	return positionHit, hitObject
end

function GetTime()
	local Type = 0
	local Sec = false
	local t = tick()
	local sec = math.floor((t%60))
	local min = math.floor((t/60)%60)
	local hour = math.floor((t/3600)%24)
	sec = tostring((sec < 10 and "0" or "") .. sec)
	min = tostring((min < 10 and "0" or "") .. min)
	local tag = (Type == 0 and (hour < 12 and "AM" or "PM") or "")
	hour = ((Type == 1 and hour < 10 and "0" or "") .. tostring(Type == 0 and (hour == 0 and 12 or hour > 12 and (hour-12) or hour) or hour))
	local c,s = ":",(Type == 0 and " " or "")	-- Colon, (space if 12 hr clock)
	return (hour .. c .. min .. (Sec and c .. sec or "") .. s .. tag)
end

function MakeText(Text,Size,Position,Parent)
	local Label = Instance.new('TextLabel',Parent)
	Label.Size = Size
	Label.Position = Position
	Label.BackgroundTransparency = 1
	Label.TextColor3 = Color3.new(1,1,1)
	Label.TextStrokeColor3 = Color3.new(0,0,0)
	Label.TextStrokeTransparency = 0.9
	Label.Font = Enum.Font.SourceSansLight
	Label.TextWrapped = true
	for i = 1, string.len(Text) do
		if Label == nil then break end
		Label.Text = Label.Text .. string.sub(Text,i,i)
		wait(0.03)
	end
end

function MakeTextFit(Text,Obj)
	local Height = Obj.Size.Y.Offset
	Obj.Size = UDim2.new(
		Obj.Size.X.Scale,
		Obj.Size.X.Offset,
		Obj.Size.Y.Scale,
		math.ceil(string.len(Text)/Height) * Height
	)
	if Obj.Size.Y.Offset == 0 then
		Obj.Size = Obj.Size + UDim2.new(0,0,0,Height)
	end
end

function MakeLine(Parent,x1,y1,x2,y2,Text)
	local distance = math.sqrt(((x2-x1)^2)+((y2-y1)^2))
	local slope = (y2-y1)/(x2-x1)
	local rot = math.deg(math.atan(slope))
	local midpoint = {X = x1+((x2-x1)/2),Y = y1+(y2-y1)/2}

	local Line = Instance.new('Frame',Parent)
		Line.Size = UDim2.new(0,distance,0,1)
		Line.Position = UDim2.new(0,midpoint.X-(distance/2),0,midpoint.Y)
		Line.BackgroundColor3 = Color3.new(0,0,0)
		Line.BorderSizePixel = 0
		Line.Rotation = rot
	if Text then
		local LineText = Instance.new('TextLabel',Line)
			LineText.Name = 'TextLabel'
			LineText.BackgroundTransparency = 1
			LineText.TextColor3 = Color3.new(1,1,1)
			LineText.Font = Enum.Font.SourceSansLight
			LineText.Text = Text
			--LineText.Position = UDim2.new(0,midpoint.X-2,0,midpoint.Y-2)
			LineText.TextScaled = true
			LineText.Size = UDim2.new(1,0,0,10)
			LineText.Position = UDim2.new(0,0,0,-5)
	end

	--[[local mp = Instance.new("Frame",midpointParent)
		mp.Size = UDim2.new(0,4,0,4)
		mp.Position = UDim2.new(0,midpoint.X-2,0,midpoint.Y-2)--]]

	return Line
end

function GetTarget(Hit)
	if Hit ~= nil and not Hit:IsDescendantOf(Player.Character) and Hit.Parent then
		if (Hit.Parent:findFirstChild('Humanoid') or (Hit.Parent.Parent and Hit.Parent.Parent:findFirstChild('Humanoid'))) then
			local Human = Hit.Parent:findFirstChild('Humanoid') or Hit.Parent.Parent:findFirstChild('Humanoid')
			local TargetPlayer = game.Players:GetPlayerFromCharacter(Human.Parent)
			return Human,TargetPlayer
		end
	end
end

for _,Plr in pairs (game.Players:GetPlayers()) do
	Plr.Chatted:connect(function(Text)
		if Plr == Player then
			if Equipped == true then
				if game.Players.BubbleChat == false then
					Event:FireServer('Chat',Text)
				end
			end
		else
			table.insert(_G.Chats[Plr.Name],{Message = Text, Time = GetTime()})
		end
	end)
end

function FillChats(Plr)
	spawn(function()
		CScroll:ClearAllChildren()
		local CScrollPos = 0
		CScroll.Visible = true
		for _,Chat in pairs (_G.Chats[Plr.Name]) do
			local Text = Chat[2]..': '..Chat[1]
			local Label = MakeText(
				Text,
				UDim2.new(1,0,0,20),
				UDim2.new(-1,0,0,CScrollPos),
				CScroll
			)
			MakeTextFit(Text,Label)
			Label:TweenPosition(Label.Position + UDim2.new(1,0,0,0),"In","Quint",0.25,true)
			CScrollPos = CScrollPos + Label.Size.Y.Offset
			CScroll.CanvasSize = CScrollPos
			CScroll.CanvasPosition = Vector2.new(0,CScrollPos)
			wait()
		end
	end)
end

game.Players.PlayerAdded:connect(function(Plr)
	Plr.Chatted:connect(function(Text)
		table.insert(_G.Chats[Plr.Name],{Message = Text, Time = GetTime()})
	end)
end)

Tool.Activated:connect(function()
	local Position1,Hit1 = Castray(LG1.CFrame,Mouse.Hit,Right,Settings.Range)
	local Position2,Hit2 = Castray(RG1.CFrame,Mouse.Hit,Right,Settings.Range)
	local Hits = {Hit1,Hit2}

	local Fired = Function:InvokeServer('Fire',Mouse.Hit)

	if Fired == true then
		for _,Hit in pairs (Hits) do
			local Human,Plr = GetTarget(Hit)
			if Human then
				if Settings.TeamKill == true and Plr and Plr.TeamColor == Player.TeamColor then return end
				Event:FireServer('Damage',Human,Settings.ShotDamage)
			end
		end
	end
end)

game:GetService("UserInputService").InputBegan:connect(function(input,process)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		if process == false and Equipped == true then
			for KeyName,Key in pairs (Settings.Keys) do
				if input.KeyCode == Key then
					Event:FireServer('KeyDown',KeyName,Mouse.Hit)
				end
			end
		end
	end
end)

game:GetService('RunService').RenderStepped:connect(function()
	if Gui ~= nil and Equipped == true then
		--Camera.CFrame = Core.CFrame * CFrame.new (3,4,7) * CFrame.fromEulerAnglesXYZ(math.rad(-15),0,0)
		Cursor.Position = UDim2.new(0, Mouse.X - 15, 0, Mouse.Y - 15)
		local P1,S1 = Camera:WorldToScreenPoint(Core.Position)
		local P2,S2 = Camera:WorldToScreenPoint(Mouse.Hit.p)
		if S1 == true and S2 == true then
			local distance = math.sqrt(((P2.X-P1.X)^2)+((P2.Y-P1.Y)^2))
			local slope = (P2.Y-P1.Y)/(P2.X-P1.X)
			local midpoint = {X = P1.X+((P2.X-P1.X)/2),Y = P1.Y+(P2.Y-P1.Y)/2}

			TargetLine.Size = UDim2.new(0,distance,0,1)
			TargetLine.Position = UDim2.new(0,midpoint.X-(distance/2),0,midpoint.Y)
			TargetLine.Rotation = math.deg(math.atan(slope))
			TargetLineDistance.Position = UDim2.new(0,midpoint.X-(distance/2),0,midpoint.Y-10)
			TargetLineDistance.Rotation = math.deg(math.atan(slope))
			TargetLineDistance.Size = UDim2.new(0,distance,0,20)
			TargetLineDistance.Text = math.ceil((Core.Position - Mouse.Hit.p).magnitude)
			local Human,Plr = GetTarget(Mouse.Target)
			if Human then
				if Plr then
					TargetLine.BackgroundColor3 = Color3.new(200/255,0,0)
				else
					TargetLine.BackgroundColor3 = Color3.new(0,170/255,1)
				end
			else
				TargetLine.BackgroundColor3 = Color3.new(1,1,1)
			end
		end

		if Mouse.Target then
			local Human,Plr = GetTarget(Mouse.Target)
			if Human and Human ~= LastTarget then
				LastTarget = Human
				if Plr then
					FillChats(Plr)
				else
					if CScroll.Visible == true then CScroll.Visible = false end
				end
				if Human.TargetPoint.X > 0 or Human.TargetPoint.Y > 0 or Human.TargetPoint.Z > 0 then
					local Attempt = CFrame.new(Human.Torso.Position,Human.TargetPoint).lookVector * 16
					local P3,S3 = Camera:WorldToScreenPoint(Human.Head.Position)
					local P4,S4 = Camera:WorldToScreenPoint(Attempt.p)
					if S3 and S4 then
						Temp:ClearAllChildren()
						MakeLine(Temp,P3.X,P3.Y,P4.X,P4.Y,"Direction")
					end
				end
			end
		end
	end
end)

Tool.Equipped:connect(function()
	Equipped = true
	Frame.Visible = true
	local Callback = Function:InvokeServer("Entrance")
	if Callback == true then
		Camera.CameraSubject = Core
		--Camera.CameraType = Enum.CameraType.Scriptable
	end
end)

Tool.Unequipped:connect(function()
	Equipped = false
	Frame.Visible = false
	local Callback = Function:InvokeServer("Exit")
	if Callback == true then
		Camera.CameraSubject = Player.Character.Humanoid
		Camera.CameraType = Enum.CameraType.Custom
	end
end)
