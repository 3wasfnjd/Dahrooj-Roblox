-- مطر الدحاريج: دحاريج ملوّنة (لابسة إكسسوارات) تنزل من السماء ببطء، وكل اللاعبين يرمون عليها.
-- العادي = نقطة، الذهبي = 3 نقاط. فرقعات ورا بعض بسرعة = سلسلة، ومن 5 وفوق النقاط تتضاعف.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local DahroojModel = require(ReplicatedStorage.Shared.DahroojModel)
local Throw = require(script.Parent.Parent.Throw)

local Rain = {}
local MODE = Config.Modes.rain
local O = MODE.arenaOrigin
local FIELD = 46 -- نصف عرض منطقة المطر
local MAX_ALIVE = 28
local GOLD = Color3.fromRGB(255, 205, 60)

local folder: Folder
local drops: Folder
local spawns = {}
local running = false
local loopThread: thread? = nil
local combo: { [Player]: { n: number, last: number } } = {}

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		if k ~= "Parent" then
			(p :: any)[k] = v
		end
	end
	p.Parent = props.Parent
	return p
end

-- إكسسوار بسيط فوق راس الدحروج النازل (مثل مطر الكويست)
local function accessory(model: Model, body: BasePart, r: number, kind: number)
	local top = body.CFrame * CFrame.new(0, r * 0.95, 0)
	local p
	if kind == 1 then -- قبعة حفلة (هرم مدبّب)
		p = Instance.new("WedgePart")
		p.Size = Vector3.new(r * 0.6, r * 0.9, r * 0.6)
		p.Color = Color3.fromRGB(120, 200, 255)
		p.Material = Enum.Material.Neon
		p.CFrame = top * CFrame.new(0, r * 0.35, 0)
	elseif kind == 2 then -- تاج
		p = Instance.new("Part")
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(r * 0.35, r * 0.9, r * 0.9)
		p.Color = GOLD
		p.Material = Enum.Material.Metal
		p.CFrame = top * CFrame.Angles(0, 0, math.rad(90))
	elseif kind == 3 then -- كاب
		p = Instance.new("Part")
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(r * 0.25, r * 1.3, r * 1.3)
		p.Color = Color3.fromRGB(230, 70, 70)
		p.CFrame = top * CFrame.new(0, -r * 0.05, -r * 0.15) * CFrame.Angles(0, 0, math.rad(90))
	else -- زهرة
		p = Instance.new("Part")
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.one * r * 0.45
		p.Color = Color3.fromRGB(255, 240, 120)
		p.Material = Enum.Material.Neon
		p.CFrame = top * CFrame.new(r * 0.35, 0, 0)
	end
	p.CanCollide, p.CanTouch, p.CanQuery, p.Massless, p.Anchored = false, false, false, true, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = body, p
	w.Parent = p
	p.Parent = model
end

local function popEffect(pos: Vector3, color: Color3)
	local p = part({
		Name = "Pop",
		Size = Vector3.one * 0.2,
		Position = pos,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = folder,
	})
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	e.Speed = NumberRange.new(14, 26)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Lifetime = NumberRange.new(0.5, 0.9)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	e.Color = ColorSequence.new(color)
	e.LightEmission = 0.5
	e.Acceleration = Vector3.new(0, -25, 0)
	e.Parent = p
	e:Emit(26)
	Debris:AddItem(p, 1.5)
end

local function spawnDrop()
	local golden = math.random() < 0.08
	local r = golden and 2.8 or 2.3
	local style = Config.Styles[math.random(1, #Config.Styles)]
	local x = O.X + math.random(-FIELD, FIELD)
	local z = O.Z + math.random(-FIELD, 0) -- قدّام اللاعبين
	local startPos = Vector3.new(x, O.Y + math.random(70, 95), z)
	local model, _ = DahroojModel.Build(CFrame.lookAt(startPos, Vector3.new(O.X, startPos.Y, O.Z + 40)), {
		name = "RainDahrooj",
		radius = r,
		color = golden and GOLD or style.color,
		material = golden and Enum.Material.Neon or nil,
		anchored = false,
		collide = false,
	})
	local body = model.PrimaryPart :: BasePart
	accessory(model, body, r, math.random(1, 4))
	body:SetAttribute("Points", golden and 3 or 1)
	model.Parent = drops
	body.Anchored = true

	local fall = math.random(10, 15)
	local endPos = Vector3.new(x + math.random(-8, 8), O.Y + 2, z + math.random(-6, 6))
	local tween = TweenService:Create(body, TweenInfo.new(fall, Enum.EasingStyle.Linear), {
		CFrame = CFrame.lookAt(endPos, Vector3.new(O.X, endPos.Y, O.Z + 40)),
	})
	tween:Play()
	tween.Completed:Connect(function()
		if model.Parent then
			model:Destroy()
		end
	end)

	body.Touched:Connect(function(hit)
		if not running or not model.Parent then
			return
		end
		local owner, modeId, ball = Throw.OwnerOf(hit)
		if not owner or modeId ~= "rain" then
			return
		end
		local pts = body:GetAttribute("Points") or 1
		local c = combo[owner] or { n = 0, last = 0 }
		combo[owner] = c
		local now = os.clock()
		c.n = (now - c.last < 1.6) and c.n + 1 or 1
		c.last = now
		if c.n >= 5 then
			pts *= 2
		end
		popEffect(body.Position, body.Color)
		model:Destroy()
		if ball then
			Throw.Pop(ball)
		end
		Rain.ctx.addScore(owner, pts)
		if pts >= 3 then
			Rain.ctx.notify(owner, "✨ ذهبي! +" .. pts)
		elseif c.n >= 3 then
			Rain.ctx.notify(owner, "سلسلة × " .. c.n .. (c.n >= 5 and "  نقاط مضاعفة!" or ""))
		end
	end)
end

function Rain.Build()
	folder = Instance.new("Folder")
	folder.Name = "RainArena"
	folder.Parent = workspace
	drops = Instance.new("Folder")
	drops.Name = "Drops"
	drops.Parent = folder

	part({
		Name = "Floor",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, 120, 120),
		CFrame = CFrame.new(O + Vector3.new(0, -1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(150, 210, 120),
		Material = Enum.Material.Grass,
		Parent = folder,
	})
	-- سياج دائري خفيف
	for i = 0, 35 do
		local a = math.rad(i * 10)
		part({
			Name = "Fence",
			Size = Vector3.new(10.6, 5, 1),
			CFrame = CFrame.new(O + Vector3.new(math.cos(a) * 59, 2.5, math.sin(a) * 59)) * CFrame.Angles(0, -a + math.pi / 2, 0),
			Color = Color3.fromRGB(255, 240, 210),
			Material = Enum.Material.WoodPlanks,
			Parent = folder,
		})
	end
	-- منصة اللاعبين في الجنوب
	for i = 1, MODE.maxPlayers do
		local x = O.X + (i - (MODE.maxPlayers + 1) / 2) * 9
		local pos = Vector3.new(x, O.Y + 3, O.Z + 30)
		spawns[i] = CFrame.lookAt(pos, Vector3.new(x, O.Y + 3, O.Z - 20))
		part({
			Name = "SpotPad",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, 5, 5),
			CFrame = CFrame.new(x, O.Y + 0.15, O.Z + 30) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Config.Styles[(i - 1) % #Config.Styles + 1].color,
			Material = Enum.Material.Neon,
			Parent = folder,
		})
	end
end

function Rain.SpawnFor(_player: Player, index: number): CFrame
	return spawns[index]
end

function Rain.Start(_players: { Player }, ctx)
	Rain.ctx = ctx
	running = true
	combo = {}
	loopThread = task.spawn(function()
		while running do
			if #drops:GetChildren() < MAX_ALIVE then
				spawnDrop()
			end
			task.wait(0.35)
		end
	end)
end

function Rain.Stop()
	running = false
	drops:ClearAllChildren()
end

return Rain
