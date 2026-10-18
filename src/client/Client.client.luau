-- واجهة اللاعب والرمي:
-- الكمبيوتر: اضغط زر الماوس الأيسر مطوّلاً للشحن، وأفلت للرمي باتجاه المؤشر.
-- الجوال: اضغط زر «ارمِ» مطوّلاً، وصوّب بالكاميرا (العلامة في نص الشاشة)، وأفلت.
-- وأثناء الشحن يطلع خط نقاط يوضح مسار الدحروج.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Trajectory = require(ReplicatedStorage.Shared:WaitForChild("Trajectory"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local throwRemote = remotes:WaitForChild("Throw") :: RemoteEvent
local notifyRemote = remotes:WaitForChild("Notify") :: RemoteEvent
local stateRemote = remotes:WaitForChild("MatchState") :: RemoteEvent
local resultsRemote = remotes:WaitForChild("Results") :: RemoteEvent

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local INK = Config.Ink
local PINK = Config.Styles[1].color
local CREAM = Color3.fromRGB(255, 250, 242)

---------------------------------------------------------------- الواجهة
local gui = Instance.new("ScreenGui")
gui.Name = "DahroojHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function new(class: string, parent: Instance?, props)
	local o = Instance.new(class)
	for k, v in props or {} do
		(o :: any)[k] = v
	end
	o.Parent = parent
	return o
end
local function round(o: Instance, r: number)
	new("UICorner", o, { CornerRadius = UDim.new(0, r) })
end
local function label(parent: Instance, props)
	local l = new("TextLabel", parent, {
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextColor3 = CREAM,
		TextStrokeColor3 = INK,
		TextStrokeTransparency = 0.3,
		TextScaled = true,
	})
	for k, v in props do
		(l :: any)[k] = v
	end
	return l
end

-- علامة التصويب
local cross = new("Frame", gui, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(14, 14),
	BackgroundColor3 = CREAM,
	BackgroundTransparency = 0.15,
	Visible = touch,
})
round(cross, 7)
new("UIStroke", cross, { Color = INK, Thickness = 2 })

-- شريط الشحن
local powerBack = new("Frame", gui, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0.5, 24),
	Size = UDim2.fromOffset(120, 10),
	BackgroundColor3 = INK,
	BackgroundTransparency = 0.3,
	Visible = false,
})
round(powerBack, 5)
local powerFill = new("Frame", powerBack, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = PINK })
round(powerFill, 5)

-- لوحة الجولة فوق
local matchBar = new("Frame", gui, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 52),
	Size = UDim2.fromOffset(300, 64),
	BackgroundColor3 = INK,
	BackgroundTransparency = 0.25,
	Visible = false,
})
round(matchBar, 16)
local matchTitle = label(matchBar, { Size = UDim2.new(1, -20, 0.5, 0), Position = UDim2.fromOffset(10, 4) })
local matchInfo = label(matchBar, {
	Size = UDim2.new(1, -20, 0.42, 0),
	Position = UDim2.new(0, 10, 0.52, 0),
	TextColor3 = Color3.fromRGB(255, 200, 225),
})
local boardFrame = new("Frame", gui, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 130),
	Size = UDim2.fromOffset(190, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = INK,
	BackgroundTransparency = 0.35,
	Visible = false,
})
round(boardFrame, 12)
new("UIListLayout", boardFrame, { Padding = UDim.new(0, 2) })
new("UIPadding", boardFrame, { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) })

-- رسالة سريعة
local toast = label(gui, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.3),
	Size = UDim2.fromOffset(460, 46),
	TextTransparency = 1,
	TextStrokeTransparency = 1,
})
local toastId = 0
local function showToast(text: string)
	toastId += 1
	local id = toastId
	toast.Text = text
	toast.TextTransparency = 0
	toast.TextStrokeTransparency = 0.3
	toast.Size = UDim2.fromOffset(380, 38)
	TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(460, 46) }):Play()
	task.delay(1.8, function()
		if id == toastId then
			TweenService:Create(toast, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end
notifyRemote.OnClientEvent:Connect(showToast)

-- شاشة النتيجة
local results = new("Frame", gui, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(340, 300),
	BackgroundColor3 = CREAM,
	Visible = false,
})
round(results, 24)
new("UIStroke", results, { Color = PINK, Thickness = 4 })
local resTitle = label(results, {
	Size = UDim2.new(1, -24, 0, 54),
	Position = UDim2.fromOffset(12, 10),
	TextColor3 = PINK,
	TextStrokeTransparency = 1,
})
local resBody = label(results, {
	Size = UDim2.new(1, -24, 0, 160),
	Position = UDim2.fromOffset(12, 70),
	TextColor3 = INK,
	TextStrokeTransparency = 1,
	TextScaled = false,
	TextSize = 20,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
})
local resCoins = label(results, {
	Size = UDim2.new(1, -24, 0, 40),
	Position = UDim2.new(0, 12, 1, -54),
	TextColor3 = Color3.fromRGB(230, 160, 20),
	TextStrokeTransparency = 1,
})

local inMatch = false
stateRemote.OnClientEvent:Connect(function(s)
	inMatch = true
	matchBar.Visible = true
	boardFrame.Visible = true
	matchTitle.Text = s.name .. "  •  " .. s.timeLeft .. "ث"
	matchInfo.Text = "نقاطك: " .. s.score
	for _, c in boardFrame:GetChildren() do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	for i, row in s.board do
		label(boardFrame, {
			Size = UDim2.new(1, -12, 0, 24),
			LayoutOrder = i,
			Text = i .. ". " .. row.name .. "  " .. row.score,
			TextColor3 = row.userId == player.UserId and Color3.fromRGB(255, 200, 225) or CREAM,
		})
	end
end)

resultsRemote.OnClientEvent:Connect(function(r)
	inMatch = false
	matchBar.Visible = false
	boardFrame.Visible = false
	resTitle.Text = r.won and "🏆 فزت!" or ("المركز " .. r.place .. " من " .. r.total)
	local lines = { r.mode .. " — نقاطك: " .. r.score .. (r.best and "  ⭐ رقم جديد!" or ""), "" }
	for _, row in r.rows do
		table.insert(lines, row.place .. ". " .. row.name .. "   " .. row.score)
	end
	resBody.Text = table.concat(lines, "\n")
	resCoins.Text = "+" .. r.coins .. " 🪙"
	results.Visible = true
	results.Size = UDim2.fromOffset(200, 180)
	TweenService:Create(results, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(340, 300) }):Play()
	task.delay(5, function()
		results.Visible = false
	end)
end)

---------------------------------------------------------------- الرمي
local dots = {}
local dotFolder = new("Folder", camera, { Name = "ThrowPreview" })
for i = 1, 22 do
	dots[i] = new("Part", dotFolder, {
		Name = "Dot",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * (0.55 - i * 0.012),
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Material = Enum.Material.Neon,
		Color = PINK,
		Transparency = 1,
	})
end

local charging = false
local chargeStart = 0
local aimScreen: Vector2? = nil

local function root(): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function aimPoint(): Vector3
	local pos = aimScreen or (camera.ViewportSize / 2)
	local ray = camera:ViewportPointToRay(pos.X, pos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character, dotFolder, workspace:FindFirstChild("Balls") }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 400, params)
	return hit and hit.Position or (ray.Origin + ray.Direction * 400)
end

local function charge(): number
	return math.clamp((os.clock() - chargeStart) / Config.Throw.ChargeTime, 0, 1)
end

local function petColor(): Color3
	local pet = player.Character and player.Character:FindFirstChild("PetDahrooj")
	return pet and pet.PrimaryPart and pet.PrimaryPart.Color or PINK
end

local function beginCharge(screenPos: Vector2?)
	if charging or not root() then
		return
	end
	charging = true
	chargeStart = os.clock()
	aimScreen = screenPos
	powerBack.Visible = true
	local color = petColor()
	powerFill.BackgroundColor3 = color
	for _, d in dots do
		d.Color = color
	end
end

local function release()
	if not charging then
		return
	end
	charging = false
	powerBack.Visible = false
	for _, d in dots do
		d.Transparency = 1
	end
	local r = root()
	if not r then
		return
	end
	local target = aimPoint()
	-- لف الشخصية باتجاه الرمية قبل ما ترمي
	local flat = Vector3.new(target.X, r.Position.Y, target.Z)
	if (flat - r.Position).Magnitude > 1 then
		r.CFrame = CFrame.lookAt(r.Position, flat)
	end
	throwRemote:FireServer(target, charge())
end

RunService.RenderStepped:Connect(function()
	if not charging then
		return
	end
	local r = root()
	if not r then
		return
	end
	local c = charge()
	powerFill.Size = UDim2.fromScale(c, 1)
	if not touch then
		aimScreen = UserInputService:GetMouseLocation()
	end
	local target = aimPoint()
	-- نفترض الشخصية بتلف قبل الرمي
	local flat = Vector3.new(target.X, r.Position.Y, target.Z)
	local facing = (flat - r.Position).Magnitude > 1 and CFrame.lookAt(r.Position, flat) or r.CFrame
	local origin = facing.Position + Vector3.new(0, 1.6, 0) + facing.LookVector * 2.2
	local v = Trajectory.Velocity(origin, target, c)
	local pts = Trajectory.Points(origin, v, #dots, 0.06)
	for i, d in dots do
		d.Position = pts[i]
		d.Transparency = 0.15 + i * 0.03
	end
end)

if touch then
	-- زر الرمي على الجوال
	local btn = new("TextButton", gui, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -150),
		Size = UDim2.fromOffset(96, 96),
		BackgroundColor3 = PINK,
		Text = "ارمِ",
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		TextColor3 = CREAM,
		AutoButtonColor = false,
	})
	round(btn, 48)
	new("UIStroke", btn, { Color = CREAM, Thickness = 3 })
	new("UIPadding", btn, {
		PaddingTop = UDim.new(0, 22),
		PaddingBottom = UDim.new(0, 22),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
	})
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			beginCharge(nil)
			btn.BackgroundColor3 = petColor():Lerp(Color3.new(1, 1, 1), 0.3)
		end
	end)
	btn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			btn.BackgroundColor3 = PINK
			release()
		end
	end)
else
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
			beginCharge(UserInputService:GetMouseLocation())
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
			release()
		end
	end)
end

player.CharacterAdded:Connect(function()
	charging = false
	powerBack.Visible = false
	for _, d in dots do
		d.Transparency = 1
	end
	if not inMatch then
		matchBar.Visible = false
		boardFrame.Visible = false
	end
end)

task.delay(3, function()
	showToast(touch and "اضغط «ارمِ» مطوّلاً وأفلت 🫧" or "اضغط الماوس مطوّلاً وأفلت عشان ترمي 🫧")
end)
