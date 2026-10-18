-- الدحروج المرافق: يطفو جنب كتف اللاعب ويلحقه، ولونه حسب الستايل المختار
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local DahroojModel = require(ReplicatedStorage.Shared.DahroojModel)

local Pets = {}
local pets: { [Player]: Model } = {}

local function styleColor(styleId: string): Color3
	for _, s in Config.Styles do
		if s.id == styleId then
			return s.color
		end
	end
	return Config.Styles[1].color
end
Pets.StyleColor = styleColor

function Pets.Attach(player: Player, styleId: string)
	local old = pets[player]
	if old then
		old:Destroy()
		pets[player] = nil
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local start = root.CFrame * CFrame.new(2.6, 2.2, 1)
	local model = DahroojModel.Build(start, {
		name = "PetDahrooj",
		radius = 1.15,
		color = styleColor(styleId),
		anchored = false,
		collide = false,
	})
	local body = model.PrimaryPart :: BasePart
	body.CanQuery = false
	body.CanTouch = false
	body.Massless = true

	local a0 = Instance.new("Attachment")
	a0.Parent = body
	local a1 = Instance.new("Attachment")
	a1.Name = "PetSlot"
	a1.Position = Vector3.new(2.6, 2.2, 1)
	a1.Parent = root

	local align = Instance.new("AlignPosition")
	align.Attachment0 = a0
	align.Attachment1 = a1
	align.Responsiveness = 18
	align.MaxForce = 1e5
	align.Parent = body
	local orient = Instance.new("AlignOrientation")
	orient.Attachment0 = a0
	orient.Attachment1 = a1
	orient.Responsiveness = 14
	orient.MaxTorque = 1e5
	orient.Parent = body

	model.Parent = char
	pcall(function()
		body:SetNetworkOwner(player)
	end)
	pets[player] = model

	-- نطّة خفيفة: الخادم يحرك نقطة المرافق لفوق وتحت
	task.spawn(function()
		local t = math.random() * 10
		while model.Parent and a1.Parent do
			t += 0.1
			a1.Position = Vector3.new(2.6, 2.2 + math.sin(t * 2.2) * 0.35, 1)
			task.wait(0.1)
		end
	end)
end

function Pets.Remove(player: Player)
	if pets[player] then
		pets[player]:Destroy()
		pets[player] = nil
	end
end

return Pets
