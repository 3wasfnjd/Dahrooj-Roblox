-- الطابور والجولة لكل بوابة: تقف على لسان الدحروج ← عد تنازلي ← ينقلك للساحة ← نتيجة ← ترجع للوبي
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.Data)

local Match = {}
Match.__index = Match

local function inZone(zone, pos: Vector3): boolean
	local p = zone.cframe:PointToObjectSpace(pos)
	local h = zone.size / 2
	return math.abs(p.X) <= h.X and p.Y >= -2 and p.Y <= h.Y and math.abs(p.Z) <= h.Z
end

local function rootOf(player: Player): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function alive(player: Player): boolean
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	return h ~= nil and h.Health > 0
end

-- remotes: { notify, state, results }
function Match.new(modeId: string, mode, portal, remotes)
	local self = setmetatable({}, Match)
	self.id = modeId
	self.cfg = Config.Modes[modeId]
	self.mode = mode
	self.portal = portal
	self.remotes = remotes
	self.phase = "idle"
	self.countdown = 0
	self.players = {}
	self.scores = {}
	task.spawn(function()
		while true do
			local ok, err = pcall(function()
				self:_tick()
			end)
			if not ok then
				warn("[Match " .. modeId .. "] " .. tostring(err))
				self.phase = "idle"
			end
			task.wait(0.25)
		end
	end)
	return self
end

function Match:_queued(): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		local r = rootOf(p)
		if r and alive(p) and not p:GetAttribute("Mode") and inZone(self.portal.zone, r.Position) then
			table.insert(list, p)
		end
	end
	return list
end

function Match:_tick()
	local status = self.portal.status
	if self.phase == "running" then
		return
	end
	local queued = self:_queued()
	local n, max = #queued, self.cfg.maxPlayers
	if n < Config.Queue.MinPlayers then
		self.phase = "idle"
		status.Text = "قف على اللسان 👅  " .. n .. "/" .. max
		return
	end
	if self.phase == "idle" then
		self.phase = "countdown"
		self.countdown = Config.Queue.Countdown
		self.lastSecond = os.clock()
	end
	if os.clock() - self.lastSecond >= 1 then
		self.lastSecond = os.clock()
		self.countdown -= 1
	end
	status.Text = "تبدأ بعد " .. math.max(0, self.countdown) .. "  •  " .. math.min(n, max) .. "/" .. max
	if self.countdown <= 0 or n >= max then
		local chosen = {}
		for i = 1, math.min(n, max) do
			chosen[i] = queued[i]
		end
		task.spawn(function()
			self:_run(chosen)
		end)
	end
end

function Match:_broadcast(timeLeft: number)
	local board = {}
	for _, p in self.players do
		table.insert(board, { name = p.DisplayName, score = self.scores[p] or 0, userId = p.UserId })
	end
	table.sort(board, function(a, b)
		return a.score > b.score
	end)
	for _, p in self.players do
		self.remotes.state:FireClient(p, {
			mode = self.id,
			name = self.cfg.name,
			timeLeft = math.max(0, math.ceil(timeLeft)),
			score = self.scores[p] or 0,
			board = board,
		})
	end
end

function Match:_run(players: { Player })
	self.phase = "running"
	self.players = players
	self.scores = {}
	self.portal.status.Text = "جولة جارية… ⏳"

	for i, p in players do
		p:SetAttribute("Mode", self.id)
		self.scores[p] = 0
		local c = p.Character
		if c then
			c:PivotTo(self.mode.SpawnFor(p, i))
		end
		self.remotes.notify:FireClient(p, "يلا! " .. self.cfg.name .. " 🎉")
	end

	local ctx = {
		addScore = function(p: Player, n: number)
			if self.scores[p] then
				self.scores[p] += n
			end
		end,
		notify = function(p: Player, text: string)
			self.remotes.notify:FireClient(p, text)
		end,
	}
	self.mode.Start(players, ctx)

	local endAt = os.clock() + self.cfg.duration
	while os.clock() < endAt do
		-- اللي طلع أو مات يخرج من الجولة
		for i = #self.players, 1, -1 do
			local p = self.players[i]
			if p.Parent ~= Players or not alive(p) or p:GetAttribute("Mode") ~= self.id then
				table.remove(self.players, i)
				if p.Parent == Players then
					p:SetAttribute("Mode", nil)
				end
			end
		end
		if #self.players == 0 then
			break
		end
		self.portal.status.Text = "جولة جارية… ⏳ " .. math.ceil(endAt - os.clock())
		self:_broadcast(endAt - os.clock())
		task.wait(0.5)
	end
	self.mode.Stop()
	self:_finish()
	self.phase = "idle"
end

function Match:_finish()
	local ranking = {}
	for _, p in self.players do
		table.insert(ranking, { player = p, score = self.scores[p] or 0 })
	end
	table.sort(ranking, function(a, b)
		return a.score > b.score
	end)
	local rows = {}
	for i, r in ranking do
		table.insert(rows, { name = r.player.DisplayName, score = r.score, place = i })
	end
	local rw = Config.Rewards
	for i, r in ranking do
		local p = r.player
		local coins = rw.Participation + r.score * rw.PerPoint
		if r.score > 0 and rw.Place[i] then
			coins += rw.Place[i]
		end
		local won = i == 1 and r.score > 0 and (#ranking == 1 or r.score > ranking[2].score)
		if won and #ranking > 1 then
			Data.AddWin(p)
		end
		Data.AddCoins(p, coins)
		local best = Data.SetBest(p, self.id, r.score)
		self.remotes.results:FireClient(p, {
			mode = self.cfg.name,
			place = i,
			total = #ranking,
			score = r.score,
			coins = coins,
			won = won,
			best = best,
			rows = rows,
		})
	end
	-- يرجعون للوبي قدّام البوابة بعد شوي
	task.delay(4, function()
		for i, r in ranking do
			local p = r.player
			if p.Parent == Players then
				p:SetAttribute("Mode", nil)
				local c = p.Character
				local z = self.portal.zone
				if c and z then
					c:PivotTo(z.cframe * CFrame.new((i - 1) * 3 - 6, 4, -14))
				end
				Data.Save(p)
			end
		end
	end)
end

return Match
