-- يبني شخصية دحروج من قطع Roblox: كرة ملوّنة + عيون كريمية بحدقة داكنة ولمعة + خدود + فم.
-- نفس روح وجه دحروج في الكويست (face.js): العين بيضاوية، الحدقة كبيرة، ولمعة بيضاء.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local DahroojModel = {}

local function sphere(name: string, color: Color3, scale: Vector3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = scale
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

-- نقطة على سطح الكرة: pitch لفوق/تحت، yaw يمين/يسار (بالدرجات)
local function surface(center: CFrame, radius: number, pitch: number, yaw: number, out: number?): CFrame
	local dir = (CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0)).LookVector
	local pos = center:PointToWorldSpace(dir * (radius + (out or 0)))
	local worldDir = center:VectorToWorldSpace(dir)
	return CFrame.lookAt(pos, pos + worldDir)
end

--[[ options:
	radius (number), color (Color3), mouth ("smile" | "open" | "sleep"),
	anchored (bool, default true), collide (bool: الكرة نفسها تتصادم), material
]]
function DahroojModel.Build(cf: CFrame, options)
	local r = options.radius or 2
	local model = Instance.new("Model")
	model.Name = options.name or "Dahrooj"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.one * r * 2
	body.CFrame = cf
	body.Color = options.color or Config.Styles[1].color
	body.Material = options.material or Enum.Material.SmoothPlastic
	body.Reflectance = 0.04
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Anchored = options.anchored ~= false
	body.CanCollide = options.collide ~= false
	body.Parent = model
	model.PrimaryPart = body

	local parts = {}
	local function add(p: Part, at: CFrame)
		p.CFrame = at
		p.Anchored = body.Anchored
		p.Parent = model
		table.insert(parts, p)
		return p
	end

	local mouth = options.mouth or "smile"
	local eyeR = r * 0.19
	local eyePitch = mouth == "open" and 22 or 8
	local eyes = {}
	for _, side in { -1, 1 } do
		local yaw = side * 18
		local base = surface(cf, r, eyePitch, yaw, -eyeR * 0.15)
		if mouth == "sleep" then
			-- عين مغمضة: قوس داكن
			add(sphere("EyeClosed", Config.Ink, Vector3.new(eyeR * 1.6, eyeR * 0.28, eyeR * 0.5)), base)
		else
			local white = add(sphere("EyeWhite", Config.EyeWhite, Vector3.new(eyeR * 2, eyeR * 2.24, eyeR * 0.7)), base)
			local pupilCF = base * CFrame.new(0, -eyeR * 0.1, -eyeR * 0.3)
			local pupil = add(sphere("Pupil", Config.Ink, Vector3.new(eyeR * 1.1, eyeR * 1.1, eyeR * 0.45)), pupilCF)
			local shine = add(
				sphere("Shine", Color3.new(1, 1, 1), Vector3.new(eyeR * 0.36, eyeR * 0.36, eyeR * 0.2)),
				pupilCF * CFrame.new(-eyeR * 0.22, eyeR * 0.26, -eyeR * 0.22)
			)
			table.insert(eyes, { white = white, pupil = pupil, shine = shine, base = base, radius = eyeR })
		end
		-- خدود وردية
		add(
			sphere("Blush", Config.Blush, Vector3.new(eyeR * 1.3, eyeR * 0.7, eyeR * 0.3)),
			surface(cf, r, eyePitch - 22, side * 34, -eyeR * 0.12)
		).Transparency = 0.35
	end

	if mouth == "open" then
		-- فم كبير مفتوح: داخل داكن + لسان وردي
		local mouthCF = surface(cf, r, -28, 0, -r * 0.05)
		add(sphere("Mouth", Color3.fromRGB(70, 22, 38), Vector3.new(r * 0.95, r * 0.7, r * 0.22)), mouthCF)
		add(
			sphere("Tongue", Color3.fromRGB(255, 120, 150), Vector3.new(r * 0.6, r * 0.28, r * 0.24)),
			mouthCF * CFrame.new(0, -r * 0.2, -r * 0.03)
		)
	elseif mouth == "sleep" then
		add(sphere("Mouth", Config.Ink, Vector3.new(r * 0.16, r * 0.1, r * 0.12)), surface(cf, r, -18, 0, -r * 0.03))
	else
		-- ابتسامة: نصف بيضاوي داكن صغير
		add(sphere("Mouth", Config.Ink, Vector3.new(r * 0.36, r * 0.16, r * 0.14)), surface(cf, r, -16, 0, -r * 0.04))
	end

	if not body.Anchored then
		for _, p in parts do
			local w = Instance.new("WeldConstraint")
			w.Part0 = body
			w.Part1 = p
			w.Parent = p
		end
	end

	return model, eyes
end

-- يحرك الحدقات لتطالع نقطة معيّنة (للدحاريج الكبيرة الثابتة)
function DahroojModel.LookAt(eyes, target: Vector3)
	for _, e in eyes do
		local localTarget = e.base:PointToObjectSpace(target)
		local dir = Vector3.new(localTarget.X, localTarget.Y, 0)
		local offset = dir.Magnitude > 0 and dir.Unit * e.radius * 0.4 or Vector3.zero
		local cf = e.base * CFrame.new(offset.X, offset.Y - e.radius * 0.1, -e.radius * 0.3)
		e.pupil.CFrame = cf
		e.shine.CFrame = cf * CFrame.new(-e.radius * 0.22, e.radius * 0.26, -e.radius * 0.22)
	end
end

return DahroojModel
