local choice = {}

choice.rand = Random.new()

--[[
Pick one entry based on weight. Weights can be integer or float.
The key is the thing to pick, the value is the weight (number)

math.random() give [0,1) (includes 0, excludes 1)
]]
function choice.ChooseOne(opts)
	local total_weight = 0
	for k, v in pairs(opts) do
		if v > 0 then
			total_weight = total_weight + v
		end
	end

	local rv = math.random() * total_weight
	for k, v in pairs(opts) do
		if v > 0 then
			if rv < v then
				return k
			end
			rv = rv - v
		end
	end
	warn("Didn't pick anything")
	return
end

--[[
Find a random position within a part, returned as a CFrame
]]
function choice.getRandomCframeInPart(part)
	return part.CFrame * CFrame.new(
		choice.rand:NextNumber(-part.Size.X/2,part.Size.X/2),
		choice.rand:NextNumber(-part.Size.Y/2,part.Size.Y/2),
		choice.rand:NextNumber(-part.Size.Z/2,part.Size.Z/2)
	)
end

return choice
