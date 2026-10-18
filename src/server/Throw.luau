-- الرمي على الخادم: اللاعب يرسل نقطة التصويب ومقدار الشحن، والخادم يطلق دحروج صغير
-- (بلون ستايل اللاعب) ويتحقق من سرعة الرمي. كل كرة تحمل Owner و Mode كخصائص.
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Trajectory = require(ReplicatedStorage.Shared.Trajectory)
local DahroojModel = require(ReplicatedStorage.Shared.DahroojModel)

local Throw = {}

local folder = Instance.new("Folder")
folder.Name = "Balls"
folder.Parent = workspace

local lastThrow: { [Player]: number } = {}
local live: { [Player]: { Model } } = {}

-- getContext(player) -> (modeId?, color)
function Throw.Init(remote: RemoteEvent, getContext)
	remote.OnServerEvent:Connect(function(player, aimPoint, charge)
		if typeof(aimPoint) ~= "Vector3" or type(charge) ~= "number" or charge ~= charge then
			return
		end
		local now = os.clock()
		if now - (lastThrow[player] or 0) < Config.Throw.Cooldown then
			return
		end
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not root or not hum or hum.Health <= 0 then
			return
		end
		lastThrow[player] = now

		local modeId, color = getContext(player)
		local origin = Trajectory.Origin(root)
		-- نقطة التصويب لازم تكون منطقية (مو ورا اللاعب بمسافة خيالية)
		if (aimPoint - origin).Magnitude > 1000 then
			return
		end
		local velocity = Trajectory.Velocity(origin, aimPoint, charge)

		local model = DahroojModel.Build(CFrame.lookAt(origin, origin + velocity), {
			name = "ThrownDahrooj",
			radius = Config.Throw.BallRadius,
			color = color,
			anchored = false,
		})
		local body = model.PrimaryPart :: BasePart
		body.CustomPhysicalProperties = PhysicalProperties.new(0.6, 0.4, 0.55, 1, 1)
		model:SetAttribute("Owner", player.UserId)
		model:SetAttribute("Mode", modeId or "lobby")
		body:SetAttribute("Owner", player.UserId)
		body:SetAttribute("Mode", modeId or "lobby")
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.CollisionGroup = "Balls"
			end
		end
		-- جاذبية أخف: قوة لفوق تعوّض جزء من الجاذبية
		local att = Instance.new("Attachment")
		att.Parent = body
		local lift = Instance.new("VectorForce")
		lift.Attachment0 = att
		lift.RelativeTo = Enum.ActuatorRelativeTo.World
		lift.ApplyAtCenterOfMass = true
		lift.Force = Vector3.new(0, body:GetMass() * workspace.Gravity * (1 - Config.Throw.GravityScale), 0)
		lift.Parent = body
		model.Parent = folder
		body:SetNetworkOwner(nil)
		body.AssemblyLinearVelocity = velocity
		body.AssemblyAngularVelocity = velocity:Cross(Vector3.yAxis) * -0.15

		local list = live[player] or {}
		live[player] = list
		table.insert(list, model)
		if #list > Config.Throw.MaxBallsPerPlayer then
			local old = table.remove(list, 1)
			if old then
				old:Destroy()
			end
		end
		Debris:AddItem(model, Config.Throw.BallLife)
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastThrow[player] = nil
		for _, m in live[player] or {} do
			m:Destroy()
		end
		live[player] = nil
	end)
end

-- يرجّع صاحب الكرة إذا القطعة جزء من دحروج مرمي
function Throw.OwnerOf(hit: BasePart): (Player?, string?, Model?)
	local model = hit:FindFirstAncestorWhichIsA("Model")
	if not model or model.Name ~= "ThrownDahrooj" then
		return nil
	end
	local id = model:GetAttribute("Owner")
	return id and Players:GetPlayerByUserId(id), model:GetAttribute("Mode"), model
end

function Throw.Pop(model: Model)
	if model and model.Parent then
		model:Destroy()
	end
end

return Throw
