local PlayerData = require(game.ServerScriptService.PlayerData)

local DroneLink = require(game.ReplicatedStorage.DroneLink)
local Utils = require(game.ReplicatedStorage.Utils)

--------------------------------------------------------------------------------

local vec3_0 = Vector3.new(0,0,0)

local drone_fcn = {}

function drone_fcn.enable(data)

end

function drone_fcn.select(data, arg)
	if typeof(arg) == "number" then
		data:drone_select(arg)
	end
end

function drone_fcn.next(data)
	data:drone_next()
end

function drone_fcn.prev(data)
	data:drone_prev()
end

function set_drone_autostop(drone, enabled)
	if drone ~= nil then
		print("autostop", drone, typeof(drone))
		local bv = Utils.GetOrCreate(drone.PrimaryPart, "bv_autostop", "BodyVelocity")
		local bav = Utils.GetOrCreate(drone.PrimaryPart, "bav_autostop", "BodyAngularVelocity")
		bv.Velocity = vec3_0
		bav.AngularVelocity = vec3_0
		if enabled then
			-- REVISIT: these values need to be based on the engines
			bv.MaxForce = Vector3.new(100,100,100)
			bv.P = 500
			bav.MaxTorque = Vector3.new(100,100,100)
			bav.P = 500
		else
			bv.MaxForce = vec3_0
			bv.P = 0
			bav.MaxTorque = vec3_0
			bav.P = 0
		end
	end
end

function set_drone_thrust(drone, vec3)
	-- REVISIT: using a BodyVelocity might work better. BodyForce takes mass into account.
	if drone ~= nil then
		local bf = Utils.GetOrCreate(drone.PrimaryPart, "bf_thrusters", "BodyForce")
		-- TODO: sanitize vec3 -- cannot be larger than the engines can provide
		if vec3 ~= nil then
			bf.Force = vec3 * 500
		else
			bf.Force = vec3_0
		end
	end
end

function drone_fcn.move(data, vec3)
	if typeof(vec3) == "Vector3" then
		local drone = data:drone_cur()
		if drone ~= nil then
			set_drone_autostop(drone, false)
			set_drone_thrust(drone, vec3)
		end
	end
end

function drone_fcn.stop(data)
	local drone = data:drone_cur()
	if drone ~= nil then
		print("stop:", drone, typeof(drone))
		set_drone_autostop(drone, true)
		set_drone_thrust(drone, nil)
	end
end

DroneLink.re_drone.OnServerEvent:Connect(function(player, name, arg)
	local fcn = drone_fcn[name]
	if fcn ~= nil then
		local data = PlayerData:Get(player)
		if data ~= nil then
			fcn(data, arg)
		end
	end
end)
