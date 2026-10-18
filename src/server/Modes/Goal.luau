-- نمط المرمى: كل لاعب له ممر، ومرمى قدامه فيه حارس دحروج يتحرك يمين ويسار.
-- تسجّل بس في مرماك. الحارس يسرع كل ما مر الوقت. الأعلى أهداف يفوز.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local DahroojModel = require(ReplicatedStorage.Shared.DahroojModel)
local Throw = require(script.Parent.Parent.Throw)

local Goal = {}
local MODE = Config.Modes.goal
local O = MODE.arenaOrigin
local LANE_W = 30
local THROW_Z = 26 -- مكان اللاعب
local GOAL_Z = -28 -- مكان المرمى
local GOAL_W, GOAL_H = 16, 9
local IVORY = Color3.fromRGB(244, 221, 195)

local lanes = {}
local running = false
local heartbeat: RBXScriptConnection? = nil
local t0 = 0

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

local function laneX(i: number): number
	return O.X + (i - (MODE.maxPlayers + 1) / 2) * LANE_W
end

function Goal.Build()
	local folder = Instance.new("Folder")
	folder.Name = "GoalArena"
	folder.Parent = workspace

	local width = LANE_W * MODE.maxPlayers + 10
	part({
		Name = "Pitch",
		Size = Vector3.new(width, 2, 90),
		Position = O + Vector3.new(0, -1, 0),
		Color = Color3.fromRGB(96, 178, 86),
		Material = Enum.Material.Grass,
		Parent = folder,
	})
	-- خطوط ملعب فاتحة
	for i = 0, MODE.maxPlayers do
		part({
			Name = "LaneDivider",
			Size = Vector3.new(0.6, 6, 90),
			Position = Vector3.new(laneX(i + 0.5), O.Y + 3, O.Z),
			Color = Color3.fromRGB(200, 235, 255),
			Material = Enum.Material.Glass,
			Transparency = 0.75,
			CollisionGroup = "Barrier",
			Parent = folder,
		})
	end
	-- جدار خلفي يمسك الكرات + جدار لاعبين قدّام
	part({
		Name = "BackWall",
		Size = Vector3.new(width, 22, 1),
		Position = O + Vector3.new(0, 11, -45),
		Color = Color3.fromRGB(255, 210, 230),
		Material = Enum.Material.SmoothPlastic,
		Parent = folder,
	})
	part({
		Name = "FrontWall",
		Size = Vector3.new(width, 10, 1),
		Position = O + Vector3.new(0, 5, 45),
		Color = Color3.fromRGB(255, 210, 230),
		Transparency = 0.6,
		Parent = folder,
	})

	for i = 1, MODE.maxPlayers do
		local x = laneX(i)
		local lane = { index = i }
		-- منصة الرمي
		part({
			Name = "ThrowPad",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.4, 8, 8),
			CFrame = CFrame.new(x, O.Y + 0.2, O.Z + THROW_Z) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Config.Styles[(i - 1) % #Config.Styles + 1].color,
			Material = Enum.Material.Neon,
			Parent = folder,
		})
		-- خط الرمي: يوقف اللاعب بس الكرات تعدّي
		part({
			Name = "ThrowLine",
			Size = Vector3.new(LANE_W - 1, 4, 0.5),
			Position = Vector3.new(x, O.Y + 2, O.Z + THROW_Z - 7),
			Color = Color3.new(1, 1, 1),
			Material = Enum.Material.Glass,
			Transparency = 0.8,
			CollisionGroup = "Barrier",
			Parent = folder,
		})
		-- المرمى: قائمين وعارضة عاجية + شبكة
		local gz = O.Z + GOAL_Z
		for _, side in { -1, 1 } do
			part({
				Name = "Post",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(GOAL_H, 0.9, 0.9),
				CFrame = CFrame.new(x + side * GOAL_W / 2, O.Y + GOAL_H / 2, gz) * CFrame.Angles(0, 0, math.rad(90)),
				Color = IVORY,
				Parent = folder,
			})
		end
		part({
			Name = "Crossbar",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(GOAL_W + 0.9, 0.9, 0.9),
			CFrame = CFrame.new(x, O.Y + GOAL_H, gz),
			Color = IVORY,
			Parent = folder,
		})
		part({
			Name = "Net",
			Size = Vector3.new(GOAL_W, GOAL_H, 0.3),
			Position = Vector3.new(x, O.Y + GOAL_H / 2, gz - 5),
			Color = Color3.new(1, 1, 1),
			Material = Enum.Material.ForceField,
			Transparency = 0.4,
			Parent = folder,
		})
		local trigger = part({
			Name = "GoalTrigger",
			Size = Vector3.new(GOAL_W - 0.6, GOAL_H - 0.4, 3.5),
			Position = Vector3.new(x, O.Y + GOAL_H / 2, gz - 2.6),
			Transparency = 1,
			CanCollide = false,
			Parent = folder,
		})
		lane.trigger = trigger
		-- الحارس: دحروج يتحرك يمين ويسار
		local keeperY = O.Y + 3.2
		local keeper = DahroojModel.Build(CFrame.lookAt(Vector3.new(x, keeperY, gz + 1.5), Vector3.new(x, keeperY, gz + 10)), {
			name = "Keeper",
			radius = 3,
			color = Config.Styles[3].color,
			anchored = false,
		})
		keeper.PrimaryPart.Anchored = true
		keeper.PrimaryPart.CollisionGroup = "Keeper"
		keeper.Parent = folder
		lane.keeper = keeper
		lane.keeperBase = Vector3.new(x, keeperY, gz + 1.5)
		lane.spawn = CFrame.lookAt(Vector3.new(x, O.Y + 3, O.Z + THROW_Z + 2), Vector3.new(x, O.Y + 3, gz))

		-- لوحة رقم الأهداف فوق المرمى
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(200, 70)
		bb.StudsOffsetWorldSpace = Vector3.new(0, GOAL_H + 4, 0)
		bb.LightInfluence = 0
		bb.Parent = trigger
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeColor3 = Config.Ink
		label.TextStrokeTransparency = 0
		label.Text = ""
		label.Parent = bb
		lane.label = label

		trigger.Touched:Connect(function(hit)
			if not running or not lane.player then
				return
			end
			local owner, modeId, ball = Throw.OwnerOf(hit)
			if owner ~= lane.player or modeId ~= "goal" or not ball or ball:GetAttribute("Scored") then
				return
			end
			ball:SetAttribute("Scored", true)
			lane.goals += 1
			lane.label.Text = lane.player.DisplayName .. "\n⚽ " .. lane.goals
			Goal.ctx.addScore(owner, 1)
			Goal.ctx.notify(owner, "قوووول! ⚽")
			task.delay(0.2, function()
				Throw.Pop(ball)
			end)
		end)

		lanes[i] = lane
	end
end

function Goal.SpawnFor(_player: Player, index: number): CFrame
	return lanes[index].spawn
end

function Goal.Start(players: { Player }, ctx)
	Goal.ctx = ctx
	running = true
	t0 = os.clock()
	for i, lane in lanes do
		lane.player = players[i]
		lane.goals = 0
		lane.label.Text = lane.player and (lane.player.DisplayName .. "\n⚽ 0") or ""
	end
	heartbeat = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		-- الحارس يسرع شوي شوي
		local speed = 1.1 + t / 40
		for i, lane in lanes do
			local x = math.sin(t * speed + i * 1.7) * (GOAL_W / 2 - 3.2)
			local base = lane.keeperBase + Vector3.new(x, 0, 0)
			lane.keeper:PivotTo(CFrame.lookAt(base, base + Vector3.new(0, 0, 10)))
		end
	end)
end

function Goal.Stop()
	running = false
	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
	for _, lane in lanes do
		lane.player = nil
		lane.label.Text = ""
	end
end

return Goal
