-- دحروج في Roblox — الخادم الرئيسي: يبني اللوبي والساحات، ويربط اللاعبين والرمي والجولات
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- مجموعات التصادم: الكرات تعدّي خطوط الرمي وفواصل الممرات، واللاعبين لا
for _, g in { "Balls", "Barrier", "Keeper" } do
	pcall(function()
		PhysicsService:RegisterCollisionGroup(g)
	end)
end
PhysicsService:CollisionGroupSetCollidable("Balls", "Barrier", false)
PhysicsService:CollisionGroupSetCollidable("Balls", "Balls", false)

local Config = require(ReplicatedStorage.Shared.Config)
local DahroojModel = require(ReplicatedStorage.Shared.DahroojModel)
local Lobby = require(script.Parent.Lobby)
local Throw = require(script.Parent.Throw)
local Pets = require(script.Parent.Pets)
local Data = require(script.Parent.Data)
local Match = require(script.Parent.Match)
local Modes = {
	goal = require(script.Parent.Modes.Goal),
	rain = require(script.Parent.Modes.Rain),
}

local function remote(name: string): RemoteEvent
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = folder
	return r
end
local remotes = {
	throw = remote("Throw"),
	notify = remote("Notify"),
	state = remote("MatchState"),
	results = remote("Results"),
}

local lobby = Lobby.Build()
for id, mode in Modes do
	local ok, err = pcall(mode.Build)
	if not ok then
		warn("[Mode " .. id .. "] build failed: " .. tostring(err))
	end
end

Throw.Init(remotes.throw, function(player: Player)
	local p = Data.Get(player)
	return player:GetAttribute("Mode"), Pets.StyleColor(p and p.style or "jelly")
end)

-- منصات الستايل
local styleDebounce: { [Player]: number } = {}
for _, pad in lobby.stylePads do
	pad.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		local now = os.clock()
		if now - (styleDebounce[player] or 0) < 1 then
			return
		end
		styleDebounce[player] = now
		local p = Data.Get(player)
		local style = pad:GetAttribute("Style")
		if p and p.style ~= style then
			p.style = style
			Pets.Attach(player, style)
			for _, s in Config.Styles do
				if s.id == style then
					remotes.notify:FireClient(player, "دحروجك صار: " .. s.name .. " ✨")
				end
			end
		end
	end)
end

local function onPlayer(player: Player)
	local p = Data.Load(player)
	player.CharacterAdded:Connect(function(char)
		player:SetAttribute("Mode", nil)
		char:WaitForChild("HumanoidRootPart", 10)
		task.wait(0.2)
		Pets.Attach(player, p.style)
	end)
	if player.Character then
		task.spawn(Pets.Attach, player, p.style)
	end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do
	task.spawn(onPlayer, p)
end
Players.PlayerRemoving:Connect(function(player)
	styleDebounce[player] = nil
	Pets.Remove(player)
end)

-- البوابات: كل بوابة مفتوحة لها طابور وجولة
for _, portal in lobby.portals do
	if portal.open and Modes[portal.id] then
		Match.new(portal.id, Modes[portal.id], portal, remotes)
	end
end

-- عيون البوابات تطالع أقرب لاعب
task.spawn(function()
	while true do
		for _, portal in lobby.portals do
			if #portal.eyes > 0 then
				local center = portal.model.PrimaryPart.Position
				local best, bestD = nil, 90
				for _, pl in Players:GetPlayers() do
					local c = pl.Character
					local r = c and c:FindFirstChild("HumanoidRootPart")
					if r then
						local d = (r.Position - center).Magnitude
						if d < bestD then
							best, bestD = r.Position, d
						end
					end
				end
				DahroojModel.LookAt(portal.eyes, best or (center + portal.model.PrimaryPart.CFrame.LookVector * 60))
			end
		end
		task.wait(0.25)
	end
end)
