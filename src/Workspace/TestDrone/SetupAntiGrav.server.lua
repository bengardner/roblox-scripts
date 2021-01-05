local Utils = require(game.ReplicatedStorage.Utils)


local inst = script.Parent
local ag_force = inst:FindFirstChild("AntiGrav", true)

local mass = Utils.GetMassOfModel(inst)
print("ag", ag_force, "workspace.Gravity:", workspace.Gravity, "mass:", mass)
ag_force.Force = Vector3.new(0, mass * workspace.Gravity, 0)
