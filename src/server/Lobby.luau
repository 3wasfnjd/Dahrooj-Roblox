-- ساحة دحروج: عشب، ساحة حجرية، بركة، أشجار، فوانيس، منصات الستايل، وبوابات الأنماط
-- كل بوابة دحروج كبير فاتح فمه، ولسانه ممدود على الأرض: تقف على اللسان = تنضم للجولة
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local DahroojModel = require(ReplicatedStorage.Shared.DahroojModel)

local Lobby = {}

local GRASS = Color3.fromRGB(120, 196, 96)
local STONE = Color3.fromRGB(226, 214, 196)
local PATH = Color3.fromRGB(240, 222, 186)

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

local function cylinderUp(cf: CFrame): CFrame
	return cf * CFrame.Angles(0, 0, math.rad(90))
end

local function billboard(parent: Instance, text: string, size: UDim2, offset: Vector3, color: Color3?): TextLabel
	local bb = Instance.new("BillboardGui")
	bb.Size = size
	bb.StudsOffsetWorldSpace = offset
	bb.AlwaysOnTop = false
	bb.MaxDistance = 220
	bb.LightInfluence = 0
	bb.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.TextStrokeColor3 = Config.Ink
	label.Parent = bb
	return label
end

local function tree(parent: Instance, pos: Vector3, rng: Random)
	local model = Instance.new("Model")
	model.Name = "Tree"
	model.Parent = parent
	local h = rng:NextNumber(9, 14)
	part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(h, 1.6, 1.6),
		CFrame = cylinderUp(CFrame.new(pos + Vector3.new(0, h / 2, 0))),
		Color = Color3.fromRGB(122, 84, 58),
		Material = Enum.Material.Wood,
		Parent = model,
	})
	local leaf = ({
		Color3.fromRGB(90, 170, 80),
		Color3.fromRGB(255, 170, 200), -- شجرة كرز
		Color3.fromRGB(120, 190, 90),
	})[rng:NextInteger(1, 3)]
	for i = 1, 3 do
		local s = rng:NextNumber(6, 9)
		part({
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * s,
			Position = pos + Vector3.new(rng:NextNumber(-2.5, 2.5), h + rng:NextNumber(-1, 2.5), rng:NextNumber(-2.5, 2.5)),
			Color = leaf,
			Material = Enum.Material.SmoothPlastic,
			CanCollide = i == 1,
			Parent = model,
		})
	end
end

local function lantern(parent: Instance, pos: Vector3)
	part({
		Name = "LanternPole",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(9, 0.5, 0.5),
		CFrame = cylinderUp(CFrame.new(pos + Vector3.new(0, 4.5, 0))),
		Color = Config.Ink,
		Material = Enum.Material.Metal,
		Parent = parent,
	})
	local lamp = part({
		Name = "Lantern",
		Size = Vector3.new(1.4, 1.8, 1.4),
		Position = pos + Vector3.new(0, 9.6, 0),
		Color = Color3.fromRGB(255, 223, 115),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = parent,
	})
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 150)
	light.Range = 18
	light.Brightness = 1
	light.Parent = lamp
end

-- بوابة نمط: دحروج عملاق فاتح فمه + لسان على الأرض
local function portal(parent: Instance, modeId: string, pos: Vector3, facing: Vector3, open: boolean)
	local mode = Config.Modes[modeId]
	local r = 15
	local cf = CFrame.lookAt(pos + Vector3.new(0, r - 2, 0), pos + Vector3.new(0, r - 2, 0) + facing)
	local model, eyes = DahroojModel.Build(cf, {
		name = "Portal_" .. modeId,
		radius = r,
		color = mode and mode.color or Color3.fromRGB(200, 200, 210),
		mouth = open and "open" or "sleep",
	})
	model.Parent = parent

	local title = billboard(
		model.PrimaryPart,
		mode and mode.name or "الجبل",
		UDim2.fromOffset(320, 80),
		Vector3.new(0, r + 5, 0),
		Color3.new(1, 1, 1)
	)
	local status = billboard(
		model.PrimaryPart,
		open and "قف على اللسان" or "قريباً… 💤",
		UDim2.fromOffset(300, 48),
		Vector3.new(0, r + 1, 0),
		Color3.fromRGB(255, 240, 200)
	)

	local tongue, zone = nil, nil
	if open then
		-- لسان وردي ممدود من الفم على الأرض = منطقة الانتظار
		local tcf = CFrame.lookAt(pos, pos + facing) * CFrame.new(0, 0.25, -(r + 4))
		tongue = part({
			Name = "Tongue",
			Size = Vector3.new(14, 0.5, 16),
			CFrame = tcf,
			Color = Color3.fromRGB(255, 120, 150),
			Material = Enum.Material.SmoothPlastic,
			Parent = model,
		})
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = tongue
		-- خط الوسط في اللسان
		part({
			Name = "TongueLine",
			Size = Vector3.new(0.6, 0.55, 10),
			CFrame = tcf * CFrame.new(0, 0.05, 1),
			Color = Color3.fromRGB(230, 90, 125),
			CanCollide = false,
			Parent = model,
		})
		zone = { cframe = tcf, size = Vector3.new(14, 12, 16) }
	end

	return {
		id = modeId,
		model = model,
		eyes = eyes,
		title = title,
		status = status,
		zone = zone,
		open = open,
	}
end

local function stylePads(parent: Instance, center: Vector3)
	local pads = {}
	for i, style in Config.Styles do
		local angle = math.rad(-60 + (i - 1) * 30)
		local pos = center + Vector3.new(math.sin(angle) * 16, 0, math.cos(angle) * 16)
		local pad = part({
			Name = "StylePad_" .. style.id,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, 7, 7),
			CFrame = cylinderUp(CFrame.new(pos + Vector3.new(0, 0.3, 0))),
			Color = style.color,
			Material = Enum.Material.Neon,
			Parent = parent,
		})
		pad:SetAttribute("Style", style.id)
		local mini = DahroojModel.Build(CFrame.lookAt(pos + Vector3.new(0, 3.6, 0), center + Vector3.new(0, 3.6, 0)), {
			radius = 1.8,
			color = style.color,
			collide = false,
		})
		mini.Parent = parent
		billboard(mini.PrimaryPart, style.name, UDim2.fromOffset(120, 34), Vector3.new(0, 3, 0), Color3.new(1, 1, 1))
		table.insert(pads, pad)
	end
	return pads
end

function Lobby.Build()
	local folder = Instance.new("Folder")
	folder.Name = "Lobby"
	folder.Parent = workspace
	local rng = Random.new(2026)

	part({
		Name = "Grass",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, 260, 260),
		CFrame = cylinderUp(CFrame.new(0, -2, 0)),
		Color = GRASS,
		Material = Enum.Material.Grass,
		Parent = folder,
	})
	part({
		Name = "Plaza",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 70, 70),
		CFrame = cylinderUp(CFrame.new(0, 0.15, 0)),
		Color = STONE,
		Material = Enum.Material.Pavement,
		Parent = folder,
	})
	-- ممرات للبوابات
	for _, dir in { Vector3.new(-1, 0, -1.2), Vector3.new(1, 0, -1.2), Vector3.new(0, 0, -1) } do
		local d = dir.Unit
		part({
			Name = "Path",
			Size = Vector3.new(10, 0.3, 50),
			CFrame = CFrame.lookAt(d * 50 + Vector3.new(0, 0.12, 0), d * 100 + Vector3.new(0, 0.12, 0)),
			Color = PATH,
			Material = Enum.Material.Pavement,
			Parent = folder,
		})
	end
	-- البركة
	part({
		Name = "Pond",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 30, 30),
		CFrame = cylinderUp(CFrame.new(70, 0.2, 40)),
		Color = Color3.fromRGB(110, 190, 235),
		Material = Enum.Material.Glass,
		Transparency = 0.15,
		Parent = folder,
	})
	-- نافورة دحروج في وسط الساحة
	local fountain = DahroojModel.Build(CFrame.new(0, 5.5, 0), {
		name = "FountainDahrooj",
		radius = 4,
		color = Config.Styles[1].color,
	})
	fountain.Parent = folder
	part({
		Name = "FountainBase",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.6, 14, 14),
		CFrame = cylinderUp(CFrame.new(0, 0.8, 0)),
		Color = Color3.fromRGB(150, 200, 235),
		Material = Enum.Material.Marble,
		Parent = folder,
	})

	for _ = 1, 26 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(60, 120)
		local p = Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		-- بعيد عن البوابات والممرات (الجهة الشمالية)
		if not (p.Z < -30 and math.abs(p.X) < 75) and (p - Vector3.new(70, 0, 40)).Magnitude > 22 then
			tree(folder, p, rng)
		end
	end
	for i = 0, 7 do
		local a = math.rad(i * 45 + 22.5)
		lantern(folder, Vector3.new(math.cos(a) * 37, 0, math.sin(a) * 37))
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 0.5, -18)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = folder

	local portals = {
		portal(folder, "goal", Vector3.new(-48, 0, -62), Vector3.new(0.45, 0, 1), true),
		portal(folder, "rain", Vector3.new(48, 0, -62), Vector3.new(-0.45, 0, 1), true),
		portal(folder, "summit", Vector3.new(0, 0, -86), Vector3.new(0, 0, 1), false),
	}
	local pads = stylePads(folder, Vector3.new(0, 0, 10))

	return { folder = folder, portals = portals, stylePads = pads, spawn = spawn }
end

return Lobby
