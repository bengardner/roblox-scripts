local MineClient = require(game:GetService("Players").LocalPlayer.PlayerScripts.MineClient)

local MineGui = script.Parent
MineClient.SetGui(MineGui)

local holder = MineGui:WaitForChild("Holder")

-- link the block output
local fr_block = holder:WaitForChild("Block")
MineClient.SetBlockFrame(fr_block)
MineClient.SetBlockTitle(fr_block:WaitForChild("Title"))
MineClient.SetBlockValue(fr_block:WaitForChild("Value"))
MineClient.SetBlockDepth(fr_block:WaitForChild("Depth"))

local fr_progress = fr_block:WaitForChild("Progress")
MineClient.SetBlockProgBar(fr_progress:WaitForChild("Bar"))
MineClient.SetBlockProgText(fr_progress:WaitForChild("Label"))

-- FIXME: this needs to be done elsewhere
wait(2)
MineClient.EnterMine()
