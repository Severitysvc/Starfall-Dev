local Updater = {}
Updater.__index = Updater

local Request = request or http_request or (syn and syn.request)
assert(Request, "No request function found")

function Updater.New()
	local Body = setmetatable({}, Updater)

	Body.Owner = "Severitysvc"
	Body.Repo = "Starfall-Dev"
	Body.BaseUrl = "https://raw.githubusercontent.com/" .. Body.Owner .. "/" .. Body.Repo .. "/refs/heads/main/"
	Body.VersionFile = "Version.lua"

	Body.BaseFiles = {
		Body.Repo .. "/Build",
		Body.Repo .. "/Build/Modules",
		Body.Repo .. "/Bundle",
		Body.Repo .. "/Bundle/Profiles",
		Body.Repo .. "/Loader.lua",
		Body.Repo .. "/Version.lua",
	}

	return Body
end

function Updater:Get(Url)
	local Result = Request({ Url = Url, Method = "GET" })
	if Result and Result.StatusCode == 200 then
		return Result.Body
	end
	return nil
end

function Updater:DownaldAsset(Path)
	local Encoded = string.gsub(Path, " ", "%%20")
	local Url = self.BaseUrl .. Encoded
	local Body = self:Get(Url)
	assert(Body, "Failed to download " .. Url)

	local Parts = string.split(Path, "/")
	local Current = ""
	for i = 1, #Parts - 1 do
		Current = Current == "" and Parts[i] or Current .. "/" .. Parts[i]
		if not isfolder(Current) then
			makefolder(Current)
		end
	end

	writefile(Path, Body)
	return Body
end

function Updater:GetInstalledVersion()
	if isfile(self.Repo .. "/" .. self.VersionFile) then
		return readfile(self.Repo .. "/" .. self.VersionFile)
	end
	return "none"
end

function Updater:CollectFiles(Folder)
	local Files = {}
	for _, Path in ipairs(listfiles(Folder)) do
		if isfile(Path) then
			local Path = string.gsub(Path, "^" .. self.Repo .. "[/\\]", self.Repo .. "/")
			table.insert(Files, Path)
		elseif isfolder(Path) then
			for _, Sub in ipairs(self:CollectFiles(Path)) do
				table.insert(Files, Sub)
			end
		end
	end

	return Files
end

function Updater:Reinstall()
	local Files = self:CollectFiles(self.Repo)

	for _, File in ipairs(Files) do
		if isfile(File) then
			delfile(File)
		end
	end

	for _, File in ipairs(Files) do
		self:DownaldAsset(File)
	end
end

function Updater:Init()
	local Installed = self:GetInstalledVersion()
	local Latest = self:DownaldAsset(self.Repo .. "/" .. self.VersionFile)

	if Installed == "none" then
		for _, File in ipairs(self.BaseFiles) do
			self:DownaldAsset(File)
		end
	elseif Installed ~= Latest then
		self:Reinstall()
	end
end

return Updater
