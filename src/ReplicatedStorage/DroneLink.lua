local module = {}

-- remove event to control the drone
-- params: name, drone, Vector3 thrust (scaled unit vector)
module.re_drone = script:WaitForChild("re_drone")

-- select the next drone
function module:Next()
	return self.re_drone:FireServer("next")
end

-- select the prev drone
function module:Prev()
	return self.re_drone:FireServer("prev")
end

-- send the thrust vector to the server, cancels auto-brakes
function module:Move(vec)
	return self.re_drone:FireServer("move", vec)
end

-- tell the server to apply auto-brakes
function module:Stop()
	return self.re_drone:FireServer("stop")
end

return module
