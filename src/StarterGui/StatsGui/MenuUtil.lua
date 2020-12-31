local module = {}

module.targets = {}

function module:onButtonActivate(target)
	local gui = self.targets[target]
	if gui ~= nil then
		gui.Enabled = not gui.Enabled
	end
end

function module:AddButton(name, btn)
	btn.Activated:Connect(function ()
		self:onButtonActivate(name)
	end)
end

function module:AddMenu(name, gui)
	self.targets[name] = gui
end

return module
