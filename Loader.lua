if shared.Aether then
	shared.Aether:Uninject(_, function()
		return
	end)
end

local Updater = require()
Updater:Init()

shared.Updater = Updater

Updater:StartQueue("")
