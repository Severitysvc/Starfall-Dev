local Updater = {}
Updater.__index = Updater

local Request = request or http_request or (syn and syn.request)
assert(Request, "no request function found")

function Updater.New()
	local Body = setmetatable({}, Updater)

	Body.Owner = "Severitysvc"
	Body.Repo = "Starfall"
	Body.Header = "Starfall-Dev"
	Body.BaseUrl = "https://raw.githubusercontent.com/" .. Body.Owner .. "/" .. Body.Repo .. "/refs/heads/main/"
	Body.VersionFile = "Version.lua"

	return Body
end

function Updater:Get(Url)
	local Result = Request({ Url = Url, Method = "GET" })
	if Result and Result.StatusCode == 200 then
		return Result.Body
	end
	return nil
end

function Updater:GetInstalledVersion()
	if isfile(self.Header .. "/" .. self.VersionFile) then
		return readfile(self.Header .. "/" .. self.VersionFile)
	end
	return "none"
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

function Updater:Reinstall()
	local Files = listfiles(self.Header)
	for _, File in ipairs(Files) do
		delfile(File)
	end

	self:DownaldAsset(self.Header .. "/" .. self.VersionFile)
	local Queue = listfiles(self.Header)

	self:StartQueue(Queue)
end

function Updater:Init()
	local InstalledVersion = self:GetInstalledVersion()

	if InstalledVersion == "none" then
		makefolder(self.Header)
		makefolder(self.Header .. "/build")
		makefolder(self.Header .. "/bundle")
		makefolder(self.Header .. "/bundle/src")
		makefolder(self.Header .. "/bundle/profiles")

		writefile(self.Header .. "/Version.lua", "")
		return "Installed version: " .. self:DownaldAsset(self.Header .. "/" .. self.VersionFile)
	else
		local GithubVersion = self:DownaldAsset(self.Header .. "/" .. self.VersionFile)
		if InstalledVersion ~= GithubVersion then
			self:Reinstall()

			return "Reinstalled with version: " .. GithubVersion
		else
			return "Already up-to-date: " .. InstalledVersion
		end
	end

	return "none"
end

return Updater
