-- إعدادات دحروج في Roblox — كل الأرقام القابلة للضبط هنا

local Config = {}

-- ألوان الستايلات (نفس ألوان دحروج كويست)
Config.Styles = {
	{ id = "jelly", name = "جيلي", color = Color3.fromRGB(255, 105, 180) },
	{ id = "fabric", name = "قماش", color = Color3.fromRGB(179, 107, 255) },
	{ id = "clay", name = "صلصال", color = Color3.fromRGB(255, 155, 61) },
	{ id = "fur", name = "فرو", color = Color3.fromRGB(241, 235, 225) },
	{ id = "bubble", name = "فقاعة", color = Color3.fromRGB(207, 232, 255) },
}
Config.Ink = Color3.fromRGB(44, 45, 61)
Config.EyeWhite = Color3.fromRGB(255, 250, 242)
Config.Blush = Color3.fromRGB(255, 127, 154)

-- الرمي
Config.Throw = {
	MinSpeed = 45,
	MaxSpeed = 110,
	Lift = 10, -- دفعة لفوق تعطي قوس خفيف
	ChargeTime = 0.9, -- ثواني للشحن الكامل
	Cooldown = 0.55,
	BallRadius = 1.1,
	BallLife = 7,
	MaxBallsPerPlayer = 6,
	GravityScale = 0.4, -- الدحروج المرمي أخف من الجاذبية العادية: قوس ناعم مثل الكويست
}

-- الطابور عند بوابات اللوبي
Config.Queue = {
	MinPlayers = 1, -- 1 عشان تقدر تجرّب لحالك
	Countdown = 10,
}

Config.Modes = {
	goal = {
		name = "المرمى",
		maxPlayers = 4,
		duration = 90,
		arenaOrigin = Vector3.new(0, 0, 700),
		color = Config.Styles[1].color,
	},
	rain = {
		name = "مطر الدحاريج",
		maxPlayers = 8,
		duration = 120,
		arenaOrigin = Vector3.new(700, 0, 0),
		color = Config.Styles[5].color,
	},
}

-- العملات
Config.Rewards = {
	Participation = 10,
	Place = { 15, 10, 5 },
	PerPoint = 1,
}

return Config
