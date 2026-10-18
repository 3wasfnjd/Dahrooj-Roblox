-- حفظ بيانات اللاعب: العملات، الفوز، الستايل، وأفضل نتيجة لكل نمط.
-- في Studio يحتاج تفعيل: Game Settings > Security > Enable Studio Access to API Services
-- وإذا ما اشتغل الحفظ تكمل اللعبة عادي (بدون حفظ).
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Data = {}
local store
pcall(function()
	store = DataStoreService:GetDataStore("DahroojV1")
end)

local profiles: { [Player]: any } = {}

local function defaults()
	return { coins = 0, wins = 0, style = "jelly", best = {} }
end

local function leaderstats(player: Player, p)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "🪙 عملات"
	coins.Value = p.coins
	coins.Parent = ls
	local wins = Instance.new("IntValue")
	wins.Name = "🏆 فوز"
	wins.Value = p.wins
	wins.Parent = ls
	ls.Parent = player
end

function Data.Load(player: Player)
	local p = defaults()
	if store then
		local ok, saved = pcall(function()
			return store:GetAsync("u" .. player.UserId)
		end)
		if ok and type(saved) == "table" then
			for k, v in saved do
				p[k] = v
			end
		end
	end
	profiles[player] = p
	leaderstats(player, p)
	return p
end

function Data.Get(player: Player)
	return profiles[player]
end

local function refresh(player: Player)
	local p = profiles[player]
	local ls = player:FindFirstChild("leaderstats")
	if p and ls then
		ls["🪙 عملات"].Value = p.coins
		ls["🏆 فوز"].Value = p.wins
	end
end

function Data.AddCoins(player: Player, n: number)
	local p = profiles[player]
	if p then
		p.coins += n
		refresh(player)
	end
end

function Data.AddWin(player: Player)
	local p = profiles[player]
	if p then
		p.wins += 1
		refresh(player)
	end
end

function Data.SetBest(player: Player, modeId: string, score: number): boolean
	local p = profiles[player]
	if p and score > (p.best[modeId] or 0) then
		p.best[modeId] = score
		return true
	end
	return false
end

function Data.Save(player: Player)
	local p = profiles[player]
	if p and store then
		pcall(function()
			store:SetAsync("u" .. player.UserId, p)
		end)
	end
end

Players.PlayerRemoving:Connect(function(player)
	Data.Save(player)
	profiles[player] = nil
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		Data.Save(player)
	end
end)

return Data
