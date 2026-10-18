-- حساب سرعة الرمية — نفس الدالة عند اللاعب (خط المسار) وعند الخادم (الرمية الحقيقية)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local Trajectory = {}

function Trajectory.Velocity(origin: Vector3, aimPoint: Vector3, charge: number): Vector3
	charge = math.clamp(charge, 0, 1)
	local t = Config.Throw
	local dir = aimPoint - origin
	if dir.Magnitude < 0.01 then
		dir = Vector3.new(0, 0, -1)
	end
	local speed = t.MinSpeed + (t.MaxSpeed - t.MinSpeed) * charge
	return dir.Unit * speed + Vector3.new(0, t.Lift, 0)
end

-- نقاط على مسار الرمية للرسم
function Trajectory.Points(origin: Vector3, velocity: Vector3, count: number, step: number): { Vector3 }
	local g = Vector3.new(0, -workspace.Gravity * Config.Throw.GravityScale, 0)
	local pts = {}
	for i = 1, count do
		local t = i * step
		table.insert(pts, origin + velocity * t + 0.5 * g * t * t)
	end
	return pts
end

-- من وين تطلع الرمية: قدّام صدر الشخصية
function Trajectory.Origin(root: BasePart): Vector3
	return root.Position + Vector3.new(0, 1.6, 0) + root.CFrame.LookVector * 2.2
end

return Trajectory
