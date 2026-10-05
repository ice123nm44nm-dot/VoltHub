local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

if getgenv().VoltScriptZ_Shutdown then
	pcall(getgenv().VoltScriptZ_Shutdown)
	getgenv().VoltScriptZ_Shutdown = nil
end

local Flags = {
	Enabled = false,
	Mode = "Always",
	TargetPart = "Head",
	FOV = 120,
	MaxDistance = 2000,
	ESPMaxDistance = 2000,
	WallCheck = true,
	Smooth = 20,
	NoRecoil = true,
	NoSpread = false,
	Sticky = true,
	AimTarget = "Mouse",
	ShowCircle = true,
	CircleColor = Color3.fromRGB(255, 0, 0),
	ESP = false,
	ESPBox = true,
	ESPName = true,
	ESPHealth = true,
	ESPTracer = false,
	ESPSkeleton = false,
	HealEnabled = false,
	HealThreshold = 50,
	LootEnabled = false,
	LootRadius = 10,
	ShieldEnabled = false,
	ShieldDrop = 15,
	ShieldCooldown = 8,
}

-- Config save/autoload (own JSON: remembers every flag across re-runs).
-- MacLib's LoadAutoLoadConfig only loads what was SAVED via its config UI,
-- which this script never opens, so nothing persisted. This covers it.
local CONFIG_FILE = "VoltScriptZ_config.json"

local function LoadFlags()
	local Http = nil
	pcall(function()
		Http = game:GetService("HttpService")
	end)
	if Http == nil then
		return
	end
	local Raw = nil
	pcall(function()
		Raw = readfile(CONFIG_FILE)
	end)
	if typeof(Raw) ~= "string" or Raw == "" then
		return
	end
	local Data = nil
	pcall(function()
		Data = Http:JSONDecode(Raw)
	end)
	if typeof(Data) ~= "table" then
		return
	end
	local function Bool(Key)
		if typeof(Data[Key]) == "boolean" then
			Flags[Key] = Data[Key]
		end
	end
	local function Num(Key, Min, Max)
		local V = tonumber(Data[Key])
		if V ~= nil then
			Flags[Key] = math.clamp(V, Min, Max)
		end
	end
	local function Str(Key, Options)
		if typeof(Data[Key]) == "string" then
			for _, O in ipairs(Options) do
				if O == Data[Key] then
					Flags[Key] = Data[Key]
					return
				end
			end
		end
	end
	Bool("Enabled")
	Str("Mode", { "Always", "Hold Right Click" })
	Str("TargetPart", { "Head", "UpperTorso" })
	Str("AimTarget", { "Mouse", "Crosshair" })
	Num("FOV", 20, 600)
	Num("MaxDistance", 100, 5000)
	Num("ESPMaxDistance", 100, 5000)
	Bool("WallCheck")
	Num("Smooth", 1, 100)
	Bool("NoRecoil")
	Bool("NoSpread")
	Bool("Sticky")
	Bool("ShowCircle")
	if typeof(Data.CircleColor) == "table" then
		local R = tonumber(Data.CircleColor.R) or 255
		local G = tonumber(Data.CircleColor.G) or 0
		local B = tonumber(Data.CircleColor.B) or 0
		Flags.CircleColor = Color3.fromRGB(math.clamp(R, 0, 255), math.clamp(G, 0, 255), math.clamp(B, 0, 255))
	end
	Bool("ESP")
	Bool("ESPBox")
	Bool("ESPSkeleton")
	Bool("ESPName")
	Bool("ESPHealth")
	Bool("ESPTracer")
	Bool("HealEnabled")
	Num("HealThreshold", 10, 90)
	Bool("LootEnabled")
	Num("LootRadius", 3, 11)
	Bool("ShieldEnabled")
	Num("ShieldDrop", 5, 50)
	Num("ShieldCooldown", 2, 30)
end

local function SaveFlags()
	pcall(function()
		local Http = game:GetService("HttpService")
		local C = Flags.CircleColor
		local Data = {
			Enabled = Flags.Enabled,
			Mode = Flags.Mode,
			TargetPart = Flags.TargetPart,
			AimTarget = Flags.AimTarget,
			FOV = Flags.FOV,
			MaxDistance = Flags.MaxDistance,
			ESPMaxDistance = Flags.ESPMaxDistance,
			WallCheck = Flags.WallCheck,
			Smooth = Flags.Smooth,
			NoRecoil = Flags.NoRecoil,
			NoSpread = Flags.NoSpread,
			Sticky = Flags.Sticky,
			ShowCircle = Flags.ShowCircle,
			CircleColor = {
				R = math.floor(C.R * 255),
				G = math.floor(C.G * 255),
				B = math.floor(C.B * 255),
			},
			ESP = Flags.ESP,
			ESPBox = Flags.ESPBox,
			ESPSkeleton = Flags.ESPSkeleton,
			ESPName = Flags.ESPName,
			ESPHealth = Flags.ESPHealth,
			ESPTracer = Flags.ESPTracer,
			HealEnabled = Flags.HealEnabled,
			HealThreshold = Flags.HealThreshold,
			LootEnabled = Flags.LootEnabled,
			LootRadius = Flags.LootRadius,
			ShieldEnabled = Flags.ShieldEnabled,
			ShieldDrop = Flags.ShieldDrop,
			ShieldCooldown = Flags.ShieldCooldown,
		}
		writefile(CONFIG_FILE, Http:JSONEncode(Data))
	end)
end

pcall(LoadFlags)

-- Survive server hops: re-queue this script when teleporting (same process,
-- new world). No files involved; the queue lives in the executor.
pcall(function()
	if typeof(queue_on_teleport) ~= "function" then
		return
	end
	queue_on_teleport([==[
if game.PlaceId == 135187059974536 then
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local Waited = 0
	while not LocalPlayer and Waited < 30 do
		task.wait(1)
		Waited = Waited + 1
		LocalPlayer = game:GetService("Players").LocalPlayer
	end
	if LocalPlayer then
		task.wait(3)
		local ok, src = pcall(readfile, [[VoltScriptZ_main.luau]])
		if ok and typeof(src) == "string" and src ~= "" then
			local fn = loadstring(src)
			if fn then
				pcall(fn)
			end
		end
	end
end
]==])
end)

local SHAPE_BY_PART = {
	Head = "Bip01_Head",
	UpperTorso = "Chest",
}

local ESP_BONES = {
	{ "Head", "UpperTorso" },
	{ "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" },
	{ "LeftUpperArm", "LeftLowerArm" },
	{ "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" },
	{ "RightUpperArm", "RightLowerArm" },
	{ "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" },
	{ "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" },
	{ "RightUpperLeg", "RightLowerLeg" },
	{ "RightLowerLeg", "RightFoot" },
}

local Window = MacLib:Window({
	Title = "VoltScriptZ",
	Subtitle = "Map Warz",
	Size = UDim2.fromOffset(868, 650),
	DragStyle = 1,
	DisabledWindowControls = {},
	ShowUserInfo = true,
	Keybind = Enum.KeyCode.RightControl,
	AcrylicBlur = true,
})

MacLib:SetFolder("VoltScriptZ")

local Group = Window:TabGroup()
local AimTab = Group:Tab({ Name = "Aimbot" })
local VisualTab = Group:Tab({ Name = "Visual" })
local HealTab = Group:Tab({ Name = "Heal" })
local LootTab = Group:Tab({ Name = "Loot" })

local AimLeft = AimTab:Section({ Side = "Left" })
local AimRight = AimTab:Section({ Side = "Right" })
local VisualLeft = VisualTab:Section({ Side = "Left" })
local VisualRight = VisualTab:Section({ Side = "Right" })
local HealMain = HealTab:Section({ Side = "Left" })
local LootMain = LootTab:Section({ Side = "Left" })

AimLeft:Header({ Text = "Main" })

AimLeft:Toggle({
	Name = "Enabled",
	Default = Flags.Enabled,
	Callback = function(Value)
		Flags.Enabled = Value
	end,
}, "AimEnabled")

AimLeft:Dropdown({
	Name = "Mode",
	Multi = false,
	Required = true,
	Options = { "Always", "Hold Right Click" },
	Default = (table.find({ "Always", "Hold Right Click" }, Flags.Mode) or 1),
	Callback = function(Value)
		Flags.Mode = Value
	end,
}, "AimMode")

AimLeft:Dropdown({
	Name = "Target Part",
	Multi = false,
	Required = true,
	Options = { "Head", "UpperTorso" },
	Default = (table.find({ "Head", "UpperTorso" }, Flags.TargetPart) or 1),
	Callback = function(Value)
		Flags.TargetPart = Value
	end,
}, "AimPart")

AimLeft:Dropdown({
	Name = "Target By",
	Multi = false,
	Required = true,
	Options = { "Mouse", "Crosshair" },
	Default = (table.find({ "Mouse", "Crosshair" }, Flags.AimTarget) or 1),
	Callback = function(Value)
		Flags.AimTarget = Value
	end,
}, "AimTarget")

AimLeft:Toggle({
	Name = "No Recoil",
	Default = Flags.NoRecoil,
	Callback = function(Value)
		Flags.NoRecoil = Value
	end,
}, "NoRecoil")

AimLeft:Toggle({
	Name = "Sticky Lock",
	Default = Flags.Sticky,
	Callback = function(Value)
		Flags.Sticky = Value
	end,
}, "StickyLock")

AimLeft:Toggle({
	Name = "Zero Spread",
	Default = Flags.NoSpread,
	Callback = function(Value)
		Flags.NoSpread = Value
	end,
}, "NoSpread")

AimRight:Header({ Text = "Limits" })

AimRight:Slider({
	Name = "FOV",
	Default = Flags.FOV,
	Minimum = 20,
	Maximum = 600,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		Flags.FOV = Value
	end,
}, "AimFOV")

AimRight:Slider({
	Name = "Aim Distance",
	Default = Flags.MaxDistance,
	Minimum = 100,
	Maximum = 5000,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		Flags.MaxDistance = Value
	end,
}, "AimDistance")

AimRight:Slider({
	Name = "Smooth",
	Default = Flags.Smooth,
	Minimum = 1,
	Maximum = 100,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		Flags.Smooth = Value
	end,
}, "AimSmooth")

AimRight:Toggle({
	Name = "Wall Check",
	Default = Flags.WallCheck,
	Callback = function(Value)
		Flags.WallCheck = Value
	end,
}, "AimWallCheck")

VisualLeft:Header({ Text = "FOV Circle" })

VisualLeft:Toggle({
	Name = "Show Circle",
	Default = Flags.ShowCircle,
	Callback = function(Value)
		Flags.ShowCircle = Value
	end,
}, "ShowCircle")

VisualLeft:Colorpicker({
	Name = "Circle Color",
	Default = Flags.CircleColor,
	Callback = function(Color)
		Flags.CircleColor = Color
	end,
}, "CircleColor")

VisualRight:Header({ Text = "ESP" })

VisualRight:Toggle({
	Name = "ESP",
	Default = Flags.ESP,
	Callback = function(Value)
		Flags.ESP = Value
	end,
}, "ESPEnabled")

VisualRight:Toggle({
	Name = "Box",
	Default = Flags.ESPBox,
	Callback = function(Value)
		Flags.ESPBox = Value
	end,
}, "ESPBox")

VisualRight:Toggle({
	Name = "Skeleton",
	Default = Flags.ESPSkeleton,
	Callback = function(Value)
		Flags.ESPSkeleton = Value
	end,
}, "ESPSkeleton")

VisualRight:Toggle({
	Name = "Name",
	Default = Flags.ESPName,
	Callback = function(Value)
		Flags.ESPName = Value
	end,
}, "ESPName")

VisualRight:Toggle({
	Name = "Health",
	Default = Flags.ESPHealth,
	Callback = function(Value)
		Flags.ESPHealth = Value
	end,
}, "ESPHealth")

VisualRight:Toggle({
	Name = "Tracer",
	Default = Flags.ESPTracer,
	Callback = function(Value)
		Flags.ESPTracer = Value
	end,
}, "ESPTracer")

VisualRight:Slider({
	Name = "ESP Distance",
	Default = Flags.ESPMaxDistance,
	Minimum = 100,
	Maximum = 5000,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		Flags.ESPMaxDistance = Value
	end,
}, "ESPDistance")

VisualLeft:Button({
	Name = "Unload",
	Callback = function()
		Window:Unload()
	end,
})

HealMain:Header({ Text = "Auto Heal" })

HealMain:Toggle({
	Name = "Auto Heal",
	Default = Flags.HealEnabled,
	Callback = function(Value)
		Flags.HealEnabled = Value
	end,
}, "HealEnabled")

HealMain:Slider({
	Name = "Use Below %",
	Default = Flags.HealThreshold,
	Minimum = 10,
	Maximum = 90,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		Flags.HealThreshold = Value
	end,
}, "HealThreshold")

LootMain:Header({ Text = "Auto Loot" })

LootMain:Toggle({
	Name = "Auto Loot",
	Default = Flags.LootEnabled,
	Callback = function(Value)
		Flags.LootEnabled = Value
	end,
}, "LootEnabled")

LootMain:Slider({
	Name = "Radius",
	Default = Flags.LootRadius,
	Minimum = 3,
	Maximum = 11,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		Flags.LootRadius = Value
	end,
}, "LootRadius")

HealMain:Header({ Text = "Auto Shield" })

HealMain:Toggle({
	Name = "Auto Shield",
	Default = Flags.ShieldEnabled,
	Callback = function(Value)
		Flags.ShieldEnabled = Value
	end,
}, "ShieldEnabled")

HealMain:Slider({
	Name = "Drop HP",
	Default = Flags.ShieldDrop,
	Minimum = 5,
	Maximum = 50,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		Flags.ShieldDrop = Value
	end,
}, "ShieldDrop")

HealMain:Slider({
	Name = "Shield CD",
	Default = Flags.ShieldCooldown,
	Minimum = 2,
	Maximum = 30,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		Flags.ShieldCooldown = Value
	end,
}, "ShieldCooldown")

-- Auto shield (no camera snap): watches HP drops, faces the shooter
-- mathematically (YawFromLook, camera untouched), validates with the game's
-- own EvaluateAt, and places via UseItem from the bag. Proven live.
local PrevShieldHP = nil
local LastShieldPlace = 0
local ShieldNameToId = nil
local ShooterHist = {}
local LastShooterTrack = 0
-- After auto-place the server echoes an equip to the shield slot; switch
-- back to the gun we held so the player keeps fight readiness.
local PendingGunSlot = nil
local PendingGunT = 0

-- Block-local lazy module refs: this block sits above the file's shared
-- module locals, so it resolves what it needs itself instead.
local ShieldModsCache = nil
local ShieldRayParams = RaycastParams.new()
ShieldRayParams.FilterType = Enum.RaycastFilterType.Exclude
ShieldRayParams.IgnoreWater = true

local function ShieldMods()
	if ShieldModsCache ~= nil then
		return ShieldModsCache
	end
	local Found = {}
	pcall(function()
		for _, Mod in ipairs(getloadedmodules(true)) do
			if typeof(Mod) == "Instance" then
				if Mod.Name == "CombatSettings" then
					local ok, Table = pcall(require, Mod)
					if ok and typeof(Table) == "table" then
						Found.CombatSettings = Table
					end
				elseif Mod.Name == "WarzBarricade" then
					local ok, Table = pcall(require, Mod)
					if ok and typeof(Table) == "table" then
						Found.WarzBarricade = Table
					end
				end
			end
		end
	end)
	if Found.CombatSettings ~= nil and Found.WarzBarricade ~= nil then
		ShieldModsCache = Found
	end
	return Found
end

local function ShieldAlive(Player, Character)
	if Character == nil or Character.Parent == nil then
		return false
	end
	local InW = false
	pcall(function()
		InW = Character:IsDescendantOf(Workspace)
	end)
	if not InW then
		return false
	end
	if Player ~= nil and Player:GetAttribute("CSGO_Dead") == true then
		return false
	end
	if Character:GetAttribute("WarzDead") == true then
		return false
	end
	local Hum = Character:FindFirstChildOfClass("Humanoid")
	if Hum == nil or Hum.Health <= 0 then
		return false
	end
	if Character:FindFirstChild("HumanoidRootPart") == nil then
		return false
	end
	if Character:FindFirstChild("Head") == nil then
		return false
	end
	return true
end

local function FindShieldInBag()
	if ShieldNameToId == nil then
		ShieldNameToId = {}
		local Mods = ShieldMods()
		local CombatSettings = Mods.CombatSettings
		if CombatSettings ~= nil and typeof(CombatSettings.GetCatalog) == "function" then
			local ok, Catalog = pcall(CombatSettings.GetCatalog)
			if ok and typeof(Catalog) == "table" then
				local W = Catalog.Weapons or Catalog
				if typeof(W) == "table" then
					for Id, Weapon in pairs(W) do
						if typeof(Weapon) == "table" and Weapon.Kind == "Shield" and typeof(Weapon.Name) == "string" then
							ShieldNameToId[Weapon.Name] = tostring(Id)
						end
					end
				end
			end
		end
	end
	local BagHud = nil
	pcall(function()
		BagHud = LocalPlayer.PlayerGui.CSGO_UI.Root.BagHud
	end)
	if BagHud == nil then
		return nil, nil
	end
	local Quick = nil
	pcall(function()
		for _, D in ipairs(BagHud:GetDescendants()) do
			if D.Name == "Quickslots" then
				Quick = D
				break
			end
		end
	end)
	if Quick == nil then
		return nil, nil
	end
	for _, SlotBtn in ipairs(Quick:GetChildren()) do
		if SlotBtn:IsA("GuiObject") then
			local Num, Item, Qty = nil, nil, nil
			for _, D in ipairs(SlotBtn:GetDescendants()) do
				if D:IsA("TextLabel") then
					if D.Name == "Num" then
						Num = tonumber(D.Text)
					elseif D.Name == "ItemName" then
						Item = tostring(D.Text)
					elseif D.Name == "Qty" then
						Qty = tostring(D.Text)
					end
				end
			end
			if Num ~= nil and Num >= 3 and Num <= 6 and Item ~= nil and Item ~= "" then
				local Count = tonumber(string.match(Qty or "", "%d+")) or 1
				if Count > 0 and ShieldNameToId[Item] ~= nil then
					return Num, ShieldNameToId[Item]
				end
			end
		end
	end
	return nil, nil
end

-- Shooter position history: bullets in flight left the muzzle ~ping ago
-- plus their travel time, so face where the shooter WAS, not where they are.
-- Tracks the 5 nearest living enemies at 5Hz, keeps 1.2s.
local function TrackShooters(MyRootPos)
	local Now = os.clock()
	if Now - LastShooterTrack < 0.2 then
		return
	end
	LastShooterTrack = Now
	local Near = {}
	for _, Player in ipairs(Players:GetPlayers()) do
		if Player ~= LocalPlayer then
			local Character = Player.Character
			if Character ~= nil and ShieldAlive(Player, Character) then
				local Root = Character:FindFirstChild("HumanoidRootPart")
				if Root ~= nil then
					table.insert(Near, { P = Player, D = (Root.Position - MyRootPos).Magnitude, Pos = Root.Position })
				end
			end
		end
	end
	table.sort(Near, function(A, B)
		return A.D < B.D
	end)
	local Seen = {}
	for i = 1, math.min(5, #Near) do
		local E = Near[i]
		Seen[E.P] = true
		local H = ShooterHist[E.P]
		if H == nil then
			H = {}
			ShooterHist[E.P] = H
		end
		table.insert(H, { T = Now, Pos = E.Pos })
		while #H > 0 and Now - H[1].T > 1.2 do
			table.remove(H, 1)
		end
	end
	for P, _ in pairs(ShooterHist) do
		if not Seen[P] then
			ShooterHist[P] = nil
		end
	end
end

-- Where the bullet that just hit us actually came from: shooter position
-- at (fire time) = drop time minus ping guess + flight time (dist/500).
local function ShooterFirePos(Player, CharPos, MyPos, Now)
	local H = ShooterHist[Player]
	if H == nil or #H == 0 then
		return nil
	end
	local D = (CharPos - MyPos).Magnitude
	local Lookback = 0.08 + D / 500
	local Want = Now - Lookback
	local BestPos = H[#H].Pos
	local BestDiff = math.abs(H[#H].T - Want)
	for _, S in ipairs(H) do
		local Diff = math.abs(S.T - Want)
		if Diff < BestDiff then
			BestDiff = Diff
			BestPos = S.Pos
		end
	end
	return BestPos
end

local function FindShooter(MyRootPos, MaxD)
	local BestChar = nil
	local BestPos = nil
	local BestD = MaxD
	local Camera = Workspace.CurrentCamera
	if Camera == nil then
		return nil, nil
	end
	for _, Player in ipairs(Players:GetPlayers()) do
		if Player ~= LocalPlayer then
			local Character = Player.Character
			if Character ~= nil and ShieldAlive(Player, Character) then
				local Chest = Character:FindFirstChild("UpperTorso")
				if Chest ~= nil and Chest:IsA("BasePart") then
					local D = (Chest.Position - MyRootPos).Magnitude
					if D < BestD then
						ShieldRayParams.FilterDescendantsInstances = { LocalPlayer.Character, Camera }
						local Hit = Workspace:Raycast(Camera.CFrame.Position, Chest.Position - Camera.CFrame.Position, ShieldRayParams)
						if Hit ~= nil and Hit.Instance ~= nil and Hit.Instance:IsDescendantOf(Character) then
							BestD = D
							BestChar = Character
							BestPos = Chest.Position
						end
					end
				end
			end
		end
	end
	return BestChar, BestPos
end

local function CheckAutoShield()
	local Remotes0 = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
	local SwitchReq = Remotes0 and Remotes0:FindFirstChild("SwitchWeaponRequest")
	if PendingGunSlot ~= nil and SwitchReq ~= nil then
		if os.clock() >= PendingGunT then
			local SlotBack = PendingGunSlot
			PendingGunSlot = nil
			pcall(function()
				SwitchReq:FireServer(SlotBack)
			end)
		end
	end
	if not Flags.ShieldEnabled then
		PrevShieldHP = nil
		return
	end
	local Mods = ShieldMods()
	local WarzBarricade = Mods.WarzBarricade
	if WarzBarricade == nil then
		return
	end
	local MyChar = LocalPlayer.Character
	local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
	local Hum = MyChar and MyChar:FindFirstChildOfClass("Humanoid")
	if MyRoot == nil or Hum == nil or Hum.Health <= 0 then
		PrevShieldHP = nil
		return
	end
	if LocalPlayer:GetAttribute("CSGO_Dead") == true or MyChar:GetAttribute("WarzDead") == true then
		PrevShieldHP = nil
		return
	end
	-- Always track while enabled (needs history BEFORE the hit lands).
	if Flags.ShieldEnabled then
		TrackShooters(MyRoot.Position)
	end
	local Now = os.clock()
	local HP = Hum.Health
	-- Windowed damage: single big hit OR accumulated hits within 2s.
	-- Samples at most every 0.1s, keeps 2s of history.
	local Trigger = false
	if PrevShieldHP == nil then
		PrevShieldHP = { { T = Now, HP = HP } }
	else
		local Last = PrevShieldHP[#PrevShieldHP]
		if Now - Last.T >= 0.1 then
			table.insert(PrevShieldHP, { T = Now, HP = HP })
		else
			Last.HP = math.min(Last.HP, HP)
		end
		while #PrevShieldHP > 0 and Now - PrevShieldHP[1].T > 2 do
			table.remove(PrevShieldHP, 1)
		end
		local Need = tonumber(Flags.ShieldDrop) or 15
		local CdOwn = tonumber(Flags.ShieldCooldown) or 8
		if Now - LastShieldPlace > CdOwn then
			for _, S in ipairs(PrevShieldHP) do
				if S.HP - HP >= Need then
					Trigger = true
					break
				end
			end
		end
	end
	if not Trigger then
		return
	end
	local Cd = LocalPlayer:GetAttribute("WarzPlaceCdLeft")
	if typeof(Cd) == "number" and Cd > 0.05 then
		return
	end
	TrackShooters(MyRoot.Position)
	local ShooterChar, ShooterPos = FindShooter(MyRoot.Position, 200)
	if ShooterChar == nil or ShooterPos == nil then
		return
	end
	-- Prefer where the muzzle was when the bullet left, not where the
	-- shooter has strafed to since.
	local ShooterPlayer = Players:GetPlayerFromCharacter(ShooterChar)
	if ShooterPlayer ~= nil then
		local FirePos = ShooterFirePos(ShooterPlayer, ShooterPos, MyRoot.Position, Now)
		if FirePos ~= nil then
			ShooterPos = FirePos
		end
	end
	local Slot, ShieldId = FindShieldInBag()
	if Slot == nil or ShieldId == nil then
		return
	end
	local Dir = ShooterPos - MyRoot.Position
	Dir = Vector3.new(Dir.X, 0, Dir.Z)
	if Dir.Magnitude < 0.5 then
		return
	end
	Dir = Dir.Unit
	local Yaw = nil
	pcall(function()
		Yaw = WarzBarricade.YawFromLook(Dir)
	end)
	if typeof(Yaw) ~= "number" then
		return
	end
	local Feet = nil
	pcall(function()
		Feet = WarzBarricade.Feet(MyChar, MyRoot)
	end)
	if typeof(Feet) ~= "Vector3" then
		return
	end
	local Pos = Feet + Dir * 2.687
	local Valid = false
	pcall(function()
		local _, _, _, Ok = WarzBarricade.EvaluateAt(MyChar, MyRoot, ShieldId, Pos, Yaw, nil, nil)
		Valid = Ok == true
	end)
	if not Valid then
		return
	end
	local Remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
	local UseItem = Remotes and Remotes:FindFirstChild("UseItem")
	if UseItem == nil then
		return
	end
	pcall(function()
		UseItem:FireServer(Slot, ShieldId, Pos, Yaw)
	end)
	LastShieldPlace = Now
	-- Remember the gun to switch back to after the server echo equips shield.
	local Back = tonumber(LocalPlayer:GetAttribute("CSGO_ActiveSlot"))
	if Back ~= nil and Back >= 1 and Back <= 2 then
		PendingGunSlot = Back
		PendingGunT = Now + 1.0
	end
end

local Circle = Drawing.new("Circle")
Circle.Visible = true
Circle.Radius = Flags.FOV
Circle.Color = Flags.CircleColor
Circle.Thickness = 1
Circle.Filled = false
Circle.Transparency = 1

local EspPool = {}

local function IsDraw(Obj)
	local ok, Res = pcall(function()
		return isrenderobj(Obj)
	end)
	return ok and Res == true
end

local function EspSet(Player)
	local Set = EspPool[Player]
	if Set == nil then
		Set = {}
		local ok = pcall(function()
			local BoxOut = Drawing.new("Square")
			BoxOut.Visible = false
			BoxOut.Filled = false
			BoxOut.Thickness = 3
			BoxOut.Transparency = 1
			BoxOut.Color = Color3.fromRGB(0, 0, 0)
			Set.BoxOut = BoxOut
			local Box = Drawing.new("Square")
			Box.Visible = false
			Box.Filled = false
			Box.Thickness = 1
			Box.Transparency = 1
			Set.Box = Box
			local Back = Drawing.new("Line")
			Back.Visible = false
			Back.Thickness = 3
			Back.Transparency = 1
			Set.Back = Back
			local Bar = Drawing.new("Line")
			Bar.Visible = false
			Bar.Thickness = 1
			Bar.Transparency = 1
			Set.Bar = Bar
			local Tag = Drawing.new("Text")
			Tag.Visible = false
			Tag.Size = 14
			Tag.Center = true
			Tag.Outline = true
			Tag.Transparency = 1
			Set.Tag = Tag
			local Trace = Drawing.new("Line")
			Trace.Visible = false
			Trace.Thickness = 1
			Trace.Transparency = 0.7
			Set.Trace = Trace
			local Lines = {}
			for i = 1, #ESP_BONES do
				local Ln = Drawing.new("Line")
				Ln.Visible = false
				Ln.Thickness = 1
				Ln.Transparency = 1
				Lines[i] = Ln
			end
			Set.Lines = Lines
		end)
		if not ok then
			for _, Obj in pairs(Set) do
				if IsDraw(Obj) then
					pcall(function()
						Obj:Remove()
					end)
				elseif typeof(Obj) == "table" then
					for _, Ln in ipairs(Obj) do
						if IsDraw(Ln) then
							pcall(function()
								Ln:Remove()
							end)
						end
					end
				end
			end
			return nil
		end
		EspPool[Player] = Set
	end
	return Set
end

local function EspHide(Set)
	if Set ~= nil then
		for _, Obj in pairs(Set) do
			if IsDraw(Obj) then
				pcall(function()
					Obj.Visible = false
				end)
			elseif typeof(Obj) == "table" then
				for _, Ln in ipairs(Obj) do
					if IsDraw(Ln) then
						pcall(function()
							Ln.Visible = false
						end)
					end
				end
			end
		end
	end
end

local function EspDisconnect(Set)
	if Set ~= nil and Set.Conns ~= nil then
		for _, Conn in ipairs(Set.Conns) do
			pcall(function()
				Conn:Disconnect()
			end)
		end
		Set.Conns = nil
	end
end

local function EspRemove(Player)
	local Set = EspPool[Player]
	if Set ~= nil then
		EspDisconnect(Set)
		for Key, Obj in pairs(Set) do
			if Key ~= "Char" and Key ~= "Conns" then
				if IsDraw(Obj) then
					pcall(function()
						Obj:Remove()
					end)
				elseif typeof(Obj) == "table" then
					for _, Ln in ipairs(Obj) do
						if IsDraw(Ln) then
							pcall(function()
								Ln:Remove()
							end)
						end
					end
				end
			end
		end
		EspPool[Player] = nil
	end
end

local function HookCharacter(Player, Character)
	local Set = EspSet(Player)
	if Set == nil or Character == nil then
		return
	end
	EspDisconnect(Set)
	Set.Char = Character
	Set.Conns = {}
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if Humanoid ~= nil then
		local Conn = nil
		Conn = Humanoid.Died:Connect(function()
			if Set.Char == Character then
				EspHide(Set)
			end
		end)
		table.insert(Set.Conns, Conn)
	end
end

local PlayerConns = {}

local function HookPlayer(Player)
	if Player == LocalPlayer then
		return
	end
	EspSet(Player)
	if Player.Character ~= nil then
		HookCharacter(Player, Player.Character)
	end
	local C1 = Player.CharacterAdded:Connect(function(Character)
		HookCharacter(Player, Character)
	end)
	local C2 = Player.CharacterRemoving:Connect(function(Character)
		local Set = EspPool[Player]
		if Set ~= nil and Set.Char == Character then
			Set.Char = nil
			EspHide(Set)
		end
	end)
	table.insert(PlayerConns, C1)
	table.insert(PlayerConns, C2)
end

for _, Player in ipairs(Players:GetPlayers()) do
	pcall(function()
		HookPlayer(Player)
	end)
end

local PlayersLeavingConn = Players.PlayerRemoving:Connect(function(Player)
	EspRemove(Player)
end)

local WarzCamera = nil
local WarzHitboxes = nil
local CombatSettings = nil
local CombatInputMod = nil
local WarzBarricade = nil
pcall(function()
	for _, Mod in ipairs(getloadedmodules(true)) do
		if typeof(Mod) == "Instance" then
			if Mod.Name == "WarzCamera" then
				local ok, Table = pcall(require, Mod)
				if ok and typeof(Table) == "table" and typeof(Table.AddLookDelta) == "function" then
					WarzCamera = Table
				end
			elseif Mod.Name == "WarzHitboxes" then
				local ok, Table = pcall(require, Mod)
				if ok and typeof(Table) == "table" and typeof(Table.DataShapes) == "function" then
					WarzHitboxes = Table
				end
			elseif Mod.Name == "CombatSettings" then
				local ok, Table = pcall(require, Mod)
				if ok and typeof(Table) == "table" and typeof(Table.RecoilFor) == "function" then
					CombatSettings = Table
				end
			elseif Mod.Name == "CombatInput" then
				local ok, Table = pcall(require, Mod)
				if ok and typeof(Table) == "table" and typeof(Table.RequestUseMed) == "function" then
					CombatInputMod = Table
				end
			elseif Mod.Name == "WarzBarricade" then
				local ok, Table = pcall(require, Mod)
				if ok and typeof(Table) == "table" and typeof(Table.EvaluateAt) == "function" and typeof(Table.YawFromLook) == "function" then
					WarzBarricade = Table
				end
			end
		end
	end
end)

local PlayerStance = nil
pcall(function()
	for _, Mod in ipairs(getloadedmodules(true)) do
		if typeof(Mod) == "Instance" and Mod.Name == "PlayerStance" then
			local ok, Table = pcall(require, Mod)
			if ok and typeof(Table) == "table" and typeof(Table.InTps) == "function" then
				PlayerStance = Table
			end
		end
	end
end)

local function IsFirstPerson()
	if PlayerStance ~= nil then
		local ok, Res = pcall(PlayerStance.InTps)
		if ok then
			return Res ~= true
		end
	end
	return false
end

local function FovScale(Camera)
	local Fov = 50
	pcall(function()
		Fov = Camera.FieldOfView
	end)
	if typeof(Fov) ~= "number" or Fov <= 0 then
		return 1
	end
	return math.max(1, 50 / Fov)
end

local OrigRecoilFor = CombatSettings and CombatSettings.RecoilFor or nil
local OrigViewFor = CombatSettings and CombatSettings.ViewRecoilFor or nil

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.IgnoreWater = true

-- Dedicated ray params for the shield shooter search live with the shield
-- block above (ShieldRayParams); the shared RayParams stays wallcheck-only.

local CachedWallFilter = nil
local LastWallFilterBuild = 0
local CachedWallChar = nil

-- Cached exclude filter: self, camera, viewmodels, FX family (tracers/flashes
-- must never block the ray). Rebuilt at most every 2s or on respawn.
local function BuildWallFilter(MyChar)
	local Filter = { MyChar, Workspace.CurrentCamera }
	local Hvl = Workspace:FindFirstChild("HeroVisualsLocal")
	if Hvl ~= nil then
		table.insert(Filter, Hvl)
	end
	local Fx = Workspace:FindFirstChild("WarzFx")
	if Fx ~= nil then
		table.insert(Filter, Fx)
	end
	local Dust = Workspace:FindFirstChild("WarzDeathDust")
	if Dust ~= nil then
		table.insert(Filter, Dust)
	end
	for _, Child in ipairs(Workspace:GetChildren()) do
		if Child.Name == "WarzSfxAt" then
			table.insert(Filter, Child)
		end
	end
	return Filter
end

local StickyChar = nil
local PrevMouse = nil
local SavedShop = {}
local LastNoRecoil = false
local LastNoSpread = false

local function GetCamera()
	return Workspace.CurrentCamera
end

local function InWorld(Character)
	if Character == nil then
		return false
	end
	local ok, In = pcall(function()
		return Character:IsDescendantOf(Workspace)
	end)
	return ok and In == true
end

local function IsAlive(Player, Character)
	if Character == nil or Character.Parent == nil or not InWorld(Character) then
		return false
	end
	if Player ~= nil and Player:GetAttribute("CSGO_Dead") == true then
		return false
	end
	if Character:GetAttribute("CSGO_Dead") == true then
		return false
	end
	if Character:GetAttribute("WarzDead") == true then
		return false
	end
	if Character:GetAttribute("Dead") == true then
		return false
	end
	if Character:GetAttribute("IsDead") == true then
		return false
	end
	if Character:GetAttribute("Downed") == true then
		return false
	end
	if Character:GetAttribute("Knocked") == true then
		return false
	end
	local Stance = Character:GetAttribute("WarzStance")
	if Stance == "Dead" or Stance == "Downed" or Stance == "Knocked" or Stance == "Unconscious" then
		return false
	end
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if Humanoid == nil then
		return false
	end
	if Humanoid.Health <= 0 then
		return false
	end
	local StateOk = true
	pcall(function()
		if Humanoid:GetState() == Enum.HumanoidStateType.Dead then
			StateOk = false
		end
	end)
	if not StateOk then
		return false
	end
	local Root = Character:FindFirstChild("HumanoidRootPart")
	if Root == nil or Root.Parent == nil then
		return false
	end
	local Head = Character:FindFirstChild("Head")
	if Head == nil or Head.Parent == nil then
		return false
	end
	return true
end

local LastHealCheck = 0

local function CheckAutoHeal()
	if not Flags.HealEnabled then
		return
	end
	local Now = os.clock()
	if Now - LastHealCheck < 0.25 then
		return
	end
	LastHealCheck = Now
	if CombatInputMod == nil or typeof(CombatInputMod.RequestUseMed) ~= "function" then
		return
	end
	local MyChar = LocalPlayer.Character
	if MyChar == nil then
		return
	end
	if LocalPlayer:GetAttribute("CSGO_Dead") == true then
		return
	end
	if MyChar:GetAttribute("CSGO_Dead") == true then
		return
	end
	if MyChar:GetAttribute("WarzDead") == true then
		return
	end
	if MyChar:GetAttribute("Dead") == true then
		return
	end
	local Hum = MyChar:FindFirstChildOfClass("Humanoid")
	if Hum == nil or Hum.Health <= 0 then
		return
	end
	local Max = Hum.MaxHealth
	if typeof(Max) ~= "number" or Max <= 0 then
		return
	end
	if Hum.Health / Max * 100 >= Flags.HealThreshold then
		return
	end
	local Cd = LocalPlayer:GetAttribute("WarzMedCdLeft")
	if typeof(Cd) == "number" and Cd > 0.05 then
		return
	end
	pcall(CombatInputMod.RequestUseMed)
end

-- Auto loot: one hold-session per item, server enforced.
-- Proven live: prep -> wait ~1.1s -> use loots without E-hold/aim.
-- Parallel sessions do NOT work (last prep wins), so items queue serially.
-- Yields to manual E-hold so we never steal the server session from the
-- game's own pickup flow.
local LootPendingUid = nil
local LootPendingT = 0
local LastLootScan = 0
local LastCfgSave = 0

local function LootRootPos(Loot)
	if Loot:IsA("Model") then
		local Pp = Loot.PrimaryPart or Loot:FindFirstChildWhichIsA("BasePart", true)
		return Pp and Pp.Position or nil
	end
	if Loot:IsA("BasePart") then
		return Loot.Position
	end
	return nil
end

local function CheckAutoLoot()
	if not Flags.LootEnabled then
		LootPendingUid = nil
		return
	end
	local Remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
	local Pickup = Remotes and Remotes:FindFirstChild("PickupLoot")
	if Pickup == nil then
		return
	end
	local MyChar = LocalPlayer.Character
	local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
	if MyRoot == nil then
		LootPendingUid = nil
		return
	end
	local Hum = MyChar:FindFirstChildOfClass("Humanoid")
	if Hum == nil or Hum.Health <= 0 then
		LootPendingUid = nil
		return
	end
	if LocalPlayer:GetAttribute("CSGO_Dead") == true then
		LootPendingUid = nil
		return
	end
	-- Manual E-hold wins: never fight the game's own hold session.
	local EDown = false
	pcall(function()
		EDown = game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.E)
	end)
	if EDown then
		LootPendingUid = nil
		return
	end
	local Now = os.clock()
	if LootPendingUid ~= nil then
		if Now - LootPendingT >= 1.1 then
			pcall(function()
				Pickup:FireServer(LootPendingUid, "use", 1)
			end)
			LootPendingUid = nil
			LastLootScan = Now
		end
		return
	end
	if Now - LastLootScan < 0.3 then
		return
	end
	LastLootScan = Now
	local Folder = Workspace:FindFirstChild("WarzLoot")
	if Folder == nil then
		return
	end
	local Radius = math.clamp(tonumber(Flags.LootRadius) or 10, 1, 11)
	local BestUid = nil
	local BestD = Radius + 1
	for _, Loot in ipairs(Folder:GetChildren()) do
		local Uid = Loot:GetAttribute("LootUid")
		if typeof(Uid) == "string" and Uid ~= "" and Loot:GetAttribute("WarzReplayFutureLoot") ~= true then
			local Pos = LootRootPos(Loot)
			if Pos ~= nil then
				local Delta = Pos - MyRoot.Position
				local Flat = Vector3.new(Delta.X, 0, Delta.Z).Magnitude
				if Flat <= Radius and math.abs(Delta.Y) < 8 then
					if Flat < BestD then
						BestD = Flat
						BestUid = Uid
					end
				end
			end
		end
	end
	if BestUid ~= nil then
		LootPendingUid = BestUid
		LootPendingT = Now
		pcall(function()
			Pickup:FireServer(BestUid, "prep", 1)
		end)
	end
end

local function EnsureSaved(Id, Weapon)
	local Saved = SavedShop[Id]
	if Saved == nil then
		Saved = {}
		SavedShop[Id] = Saved
	end
	if Saved.R == nil and typeof(Weapon.Recoil) == "number" then
		Saved.R = Weapon.Recoil
	end
	if Saved.V == nil then
		Saved.V = Weapon.ViewRecoil
	end
	if Saved.S == nil and typeof(Weapon.Spread) == "number" then
		Saved.S = Weapon.Spread
	end
	return Saved
end

local function ZeroTables()
	local ok, Shared = pcall(function()
		for _, Mod in ipairs(getloadedmodules(true)) do
			if typeof(Mod) == "Instance" and Mod.Name == "Config" then
				local Lok, Table = pcall(require, Mod)
				if Lok and typeof(Table) == "table" then
					return Table
				end
			end
		end
		return nil
	end)
	if ok and typeof(Shared) == "table" and typeof(Shared.Shop) == "table" then
		for Id, Weapon in pairs(Shared.Shop) do
			if typeof(Weapon) == "table" and typeof(Weapon.Recoil) == "number" then
				EnsureSaved(Id, Weapon)
				Weapon.Recoil = 0
				Weapon.ViewRecoil = 0
			end
		end
	end
	if CombatSettings ~= nil then
		local ok2, Catalog = pcall(function()
			return CombatSettings:GetCatalog()
		end)
		if ok2 and typeof(Catalog) == "table" and typeof(Catalog.Weapons) == "table" then
			for _, Weapon in pairs(Catalog.Weapons) do
				if typeof(Weapon) == "table" and typeof(Weapon.Recoil) == "number" then
					Weapon.Recoil = 0
					Weapon.ViewRecoil = 0
				end
			end
		end
	end
end

local function RestoreTables()
	local ok, Shared = pcall(function()
		for _, Mod in ipairs(getloadedmodules(true)) do
			if typeof(Mod) == "Instance" and Mod.Name == "Config" then
				local Lok, Table = pcall(require, Mod)
				if Lok and typeof(Table) == "table" then
					return Table
				end
			end
		end
		return nil
	end)
	if ok and typeof(Shared) == "table" and typeof(Shared.Shop) == "table" then
		for Id, Saved in pairs(SavedShop) do
			local Weapon = Shared.Shop[Id]
			if Weapon ~= nil and Saved.R ~= nil then
				Weapon.Recoil = Saved.R
				Weapon.ViewRecoil = Saved.V
			end
		end
	end
	if CombatSettings ~= nil then
		local ok2, Catalog = pcall(function()
			return CombatSettings:GetCatalog()
		end)
		if ok2 and typeof(Catalog) == "table" and typeof(Catalog.Weapons) == "table" then
			for Id, Weapon in pairs(Catalog.Weapons) do
				if typeof(Weapon) == "table" then
					local Saved = SavedShop[Id]
					if Saved ~= nil and Saved.R ~= nil then
						Weapon.Recoil = Saved.R
						Weapon.ViewRecoil = Saved.V
					end
				end
			end
		end
	end
end

local function ApplyNoRecoil()
	if CombatSettings ~= nil then
		CombatSettings.RecoilFor = function(...)
			return 0
		end
		CombatSettings.ViewRecoilFor = function(...)
			return 0
		end
	end
	ZeroTables()
end

local function RestoreRecoil()
	if CombatSettings ~= nil then
		if OrigRecoilFor ~= nil then
			CombatSettings.RecoilFor = OrigRecoilFor
		end
		if OrigViewFor ~= nil then
			CombatSettings.ViewRecoilFor = OrigViewFor
		end
	end
	RestoreTables()
end

-- Zero Spread is data-only: no SpreadFor function exists to hook.
-- NOTE: server recomputes spread from its own tables + seed, so this
-- mainly affects client-side visuals (tracers/crosshair), not server hits.
local function ZeroSpread()
	local ok, Shared = pcall(function()
		for _, Mod in ipairs(getloadedmodules(true)) do
			if typeof(Mod) == "Instance" and Mod.Name == "Config" then
				local Lok, Table = pcall(require, Mod)
				if Lok and typeof(Table) == "table" then
					return Table
				end
			end
		end
		return nil
	end)
	if ok and typeof(Shared) == "table" and typeof(Shared.Shop) == "table" then
		for Id, Weapon in pairs(Shared.Shop) do
			if typeof(Weapon) == "table" and typeof(Weapon.Spread) == "number" then
				EnsureSaved(Id, Weapon)
				Weapon.Spread = 0
			end
		end
	end
	if CombatSettings ~= nil then
		local ok2, Catalog = pcall(function()
			return CombatSettings:GetCatalog()
		end)
		if ok2 and typeof(Catalog) == "table" and typeof(Catalog.Weapons) == "table" then
			for _, Weapon in pairs(Catalog.Weapons) do
				if typeof(Weapon) == "table" and typeof(Weapon.Spread) == "number" then
					Weapon.Spread = 0
				end
			end
		end
	end
end

local function RestoreSpread()
	local ok, Shared = pcall(function()
		for _, Mod in ipairs(getloadedmodules(true)) do
			if typeof(Mod) == "Instance" and Mod.Name == "Config" then
				local Lok, Table = pcall(require, Mod)
				if Lok and typeof(Table) == "table" then
					return Table
				end
			end
		end
		return nil
	end)
	if ok and typeof(Shared) == "table" and typeof(Shared.Shop) == "table" then
		for Id, Saved in pairs(SavedShop) do
			local Weapon = Shared.Shop[Id]
			if Weapon ~= nil and Saved.S ~= nil then
				Weapon.Spread = Saved.S
			end
		end
	end
	if CombatSettings ~= nil then
		local ok2, Catalog = pcall(function()
			return CombatSettings:GetCatalog()
		end)
		if ok2 and typeof(Catalog) == "table" and typeof(Catalog.Weapons) == "table" then
			for Id, Weapon in pairs(Catalog.Weapons) do
				if typeof(Weapon) == "table" then
					local Saved = SavedShop[Id]
					if Saved ~= nil and Saved.S ~= nil then
						Weapon.Spread = Saved.S
					end
				end
			end
		end
	end
end

local function ApplyNoSpread()
	ZeroSpread()
end

local function ServerBallCenter(Character, ShapeName)
	if WarzHitboxes == nil then
		return nil
	end
	local ok, Shapes = pcall(WarzHitboxes.DataShapes, Character)
	if not ok or typeof(Shapes) ~= "table" then
		return nil
	end
	for _, Shape in pairs(Shapes) do
		if typeof(Shape) == "table" and Shape.name == ShapeName and Shape.cf ~= nil then
			local Cf = Shape.cf
			if typeof(Cf) == "CFrame" then
				return Cf.Position
			end
		end
	end
	return nil
end

local FLICK_BREAK = 220
local STEAL_PX = 45

local function StickyValid(Character)
	if not InWorld(Character) then
		return false
	end
	local Player = Players:GetPlayerFromCharacter(Character)
	if Player == nil or not IsAlive(Player, Character) then
		return false
	end
	local Part = Character:FindFirstChild(Flags.TargetPart)
	if Part == nil or not Part:IsA("BasePart") then
		return false
	end
	return true
end

-- FlickVec is the per-frame mouse travel (Vector2, can be zero).
-- Lock breaks on a hard flick ONLY when flicking away from the target;
-- turning WITH a strafing target keeps the lock (critical in FPS).
local function StickyTarget(Camera, Muzzle, Mouse, FlickVec)
	local Character = StickyChar
	if Character == nil or not StickyValid(Character) then
		StickyChar = nil
		return nil, nil, nil
	end
	local Part = Character:FindFirstChild(Flags.TargetPart)
	if (Part.Position - Muzzle).Magnitude > Flags.MaxDistance then
		StickyChar = nil
		return nil, nil, nil
	end
	local Ball = ServerBallCenter(Character, SHAPE_BY_PART[Flags.TargetPart])
	local Aim = Ball or Part.Position
	local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Aim)
	if not OnScreen then
		StickyChar = nil
		return nil, nil, nil
	end
	local AimScreen = Vector2.new(ScreenPos.X, ScreenPos.Y)
	if FlickVec.Magnitude > FLICK_BREAK then
		local ToT = AimScreen - Mouse
		if ToT.Magnitude < 5 or FlickVec.Unit:Dot(ToT.Unit) < 0.3 then
			StickyChar = nil
			return nil, nil, nil
		end
	end
	return Character, Aim, AimScreen
end

local function GetTarget(Camera, Muzzle, Mouse, FlickVec)
	local Scale = FovScale(Camera)
	local Radius = Flags.FOV * Scale
	-- Reference point: cursor position or screen center (crosshair).
	local RefPt = Mouse
	if Flags.AimTarget == "Crosshair" then
		local Vs = Camera.ViewportSize
		RefPt = Vector2.new(Vs.X / 2, Vs.Y / 2)
	end
	local Lock = nil
	local LockAim = nil
	local LockScreen = nil
	if Flags.Sticky then
		Lock, LockAim, LockScreen = StickyTarget(Camera, Muzzle, Mouse, FlickVec)
	else
		StickyChar = nil
	end
	local Best = nil
	local BestChar = nil
	local BestAim = nil
	local BestScreen = nil
	local BestDist = Radius
	for _, Player in ipairs(Players:GetPlayers()) do
		if Player ~= LocalPlayer then
			local Character = Player.Character
			if Character ~= nil and IsAlive(Player, Character) then
				local Part = Character:FindFirstChild(Flags.TargetPart)
				if Part ~= nil and Part:IsA("BasePart") then
					if (Part.Position - Muzzle).Magnitude <= Flags.MaxDistance then
						-- Acquisition on the whole body, precision aim stays on
						-- TargetPart: lock if head, torso or root is nearest to
						-- the reference point, so center-mass aim still locks.
						local Closest = nil
						for _, Pn in ipairs({ Flags.TargetPart, "UpperTorso", "HumanoidRootPart" }) do
							local P = Character:FindFirstChild(Pn)
							if P ~= nil and P:IsA("BasePart") then
								local Sp, On = Camera:WorldToViewportPoint(P.Position)
								if On then
									local D = (Vector2.new(Sp.X, Sp.Y) - RefPt).Magnitude
									if Closest == nil or D < Closest then
										Closest = D
									end
								end
							end
						end
						if Closest ~= nil then
							local Dist = Closest
							if Dist < BestDist then
								BestDist = Dist
								Best = Part.Position
								BestChar = Character
							end
						end
					end
				end
			end
		end
	end
	if BestChar ~= nil and Flags.Sticky and BestChar ~= StickyChar and BestDist < STEAL_PX then
		StickyChar = nil
		Lock = nil
	end
	if Lock ~= nil then
		return Lock, LockAim, LockScreen
	end
	if BestChar == nil or Best == nil then
		StickyChar = nil
		return nil, nil, nil
	end
	if Flags.Sticky then
		StickyChar = BestChar
	end
	local ShapeName = SHAPE_BY_PART[Flags.TargetPart]
	local Ball = nil
	if ShapeName ~= nil then
		Ball = ServerBallCenter(BestChar, ShapeName)
	end
	BestAim = Ball or Best
	local ScreenPos, OnScreen = Camera:WorldToViewportPoint(BestAim)
	if not OnScreen then
		return nil, nil, nil
	end
	BestScreen = Vector2.new(ScreenPos.X, ScreenPos.Y)
	if (BestScreen - RefPt).Magnitude > Radius then
		if Flags.Sticky then
			StickyChar = nil
		end
		return nil, nil, nil
	end
	return BestChar, BestAim, BestScreen
end

local function AimActive()
	if not Flags.Enabled then
		StickyChar = nil
		return false
	end
	if Flags.Mode == "Hold Right Click" then
		local Pressed = false
		pcall(function()
			Pressed = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
		end)
		if not Pressed then
			StickyChar = nil
		end
		return Pressed
	end
	return true
end

local function InFront(Camera, Pos)
	local ok, Behind = pcall(function()
		return Camera.CFrame:PointToObjectSpace(Pos).Z < 0
	end)
	return ok and Behind == true
end

local function DrawSkeleton(Set, Character, Color)
	if Set.Lines == nil then
		return
	end
	local Camera = GetCamera()
	if Camera == nil then
		return
	end
	for i, Pair in ipairs(ESP_BONES) do
		local Ln = Set.Lines[i]
		if Ln ~= nil then
			local P1 = Character:FindFirstChild(Pair[1])
			local P2 = Character:FindFirstChild(Pair[2])
			if P1 ~= nil and P2 ~= nil and P1:IsA("BasePart") and P2:IsA("BasePart") then
				local S1, Ok1 = Camera:WorldToViewportPoint(P1.Position)
				local S2, Ok2 = Camera:WorldToViewportPoint(P2.Position)
				if Ok1 and Ok2 then
					Ln.From = Vector2.new(S1.X, S1.Y)
					Ln.To = Vector2.new(S2.X, S2.Y)
					Ln.Color = Color
					Ln.Visible = true
				else
					Ln.Visible = false
				end
			else
				Ln.Visible = false
			end
		end
	end
end

local function HideSkeleton(Set)
	if Set.Lines ~= nil then
		for _, Ln in ipairs(Set.Lines) do
			if IsDraw(Ln) then
				pcall(function()
					Ln.Visible = false
				end)
			end
		end
	end
end

local function UpdateESP(Camera, Viewport)
	for Player, _ in pairs(EspPool) do
		local Valid = false
		pcall(function()
			if Player.Parent == Players then
				Valid = true
			end
		end)
		if not Valid then
			EspRemove(Player)
		end
	end
	if not Flags.ESP then
		for _, Set in pairs(EspPool) do
			EspHide(Set)
		end
		return
	end
	local MyChar = LocalPlayer.Character
	local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
	for _, Player in ipairs(Players:GetPlayers()) do
		if Player ~= LocalPlayer then
			local Character = Player.Character
			local Set = EspSet(Player)
			if Set == nil or Character == nil or not IsAlive(Player, Character) then
				EspHide(Set)
			else
				if Set.Char ~= nil and Set.Char ~= Character then
					HookCharacter(Player, Character)
				end
				local Head = Character:FindFirstChild("Head")
				local Root = Character:FindFirstChild("HumanoidRootPart")
				local Humanoid = Character:FindFirstChildOfClass("Humanoid")
				if Head == nil or Root == nil or Humanoid == nil or MyRoot == nil then
					EspHide(Set)
				else
					local Dist = (Root.Position - MyRoot.Position).Magnitude
					if Dist > Flags.ESPMaxDistance then
						EspHide(Set)
					elseif not InFront(Camera, Head.Position) and not InFront(Camera, Root.Position) then
						EspHide(Set)
					else
						local Top3 = Head.Position + Vector3.new(0, 0.7, 0)
						local Bot3 = Root.Position - Vector3.new(0, 2.8, 0)
						local Top, TopOn = Camera:WorldToViewportPoint(Top3)
						local Bot, BotOn = Camera:WorldToViewportPoint(Bot3)
						if not TopOn or not BotOn then
							EspHide(Set)
						else
							local H = math.abs(Bot.Y - Top.Y)
							if H < 4 or H > 1200 then
								EspHide(Set)
							else
								local W = H * 0.62
								local Cx = (Top.X + Bot.X) / 2
								local Cy = (Top.Y + Bot.Y) / 2
								if Cx < -W or Cx > Viewport.X + W or Cy < -H or Cy > Viewport.Y + H then
									EspHide(Set)
								else
									local X = math.clamp(Cx - W / 2, 2, Viewport.X - W - 2)
									local Y = math.clamp(Cy - H / 2, 16, Viewport.Y - H - 22)
									local Frac = math.clamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1)
									local MainColor = Color3.fromRGB(255, 255, 255)
									if Flags.ESPBox then
										Set.BoxOut.Visible = true
										Set.BoxOut.Position = Vector2.new(X, Y)
										Set.BoxOut.Size = Vector2.new(W, H)
										Set.Box.Visible = true
										Set.Box.Position = Vector2.new(X, Y)
										Set.Box.Size = Vector2.new(W, H)
										Set.Box.Color = MainColor
									else
										Set.BoxOut.Visible = false
										Set.Box.Visible = false
									end
									if Flags.ESPHealth then
										Set.Back.Visible = true
										Set.Back.From = Vector2.new(X - 4, Y)
										Set.Back.To = Vector2.new(X - 4, Y + H)
										Set.Back.Color = Color3.fromRGB(0, 0, 0)
										Set.Bar.Visible = true
										Set.Bar.From = Vector2.new(X - 4, Y + H * (1 - Frac))
										Set.Bar.To = Vector2.new(X - 4, Y + H)
										Set.Bar.Color = Color3.fromRGB(255 * (1 - Frac), 255 * Frac, 0)
									else
										Set.Back.Visible = false
										Set.Bar.Visible = false
									end
									if Flags.ESPName then
										Set.Tag.Visible = true
										Set.Tag.Position = Vector2.new(X + W / 2, Y - 15)
										Set.Tag.Color = Color3.fromRGB(255, 255, 255)
										Set.Tag.Text = Player.DisplayName .. " " .. math.floor(Dist) .. "m"
									else
										Set.Tag.Visible = false
									end
									if Flags.ESPTracer then
										Set.Trace.Visible = true
										Set.Trace.From = Vector2.new(Viewport.X / 2, Viewport.Y)
										Set.Trace.To = Vector2.new(X + W / 2, Y + H)
										Set.Trace.Color = MainColor
									else
										Set.Trace.Visible = false
									end
									if Flags.ESPSkeleton then
										DrawSkeleton(Set, Character, MainColor)
									else
										HideSkeleton(Set)
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

RunService:BindToRenderStep("VoltScriptZ_Aim", Enum.RenderPriority.Last.Value, function()
	local ok = pcall(function()
		local Camera = GetCamera()
		if Camera == nil then
			return
		end
		if Flags.NoRecoil ~= LastNoRecoil then
			LastNoRecoil = Flags.NoRecoil
			if LastNoRecoil then
				ApplyNoRecoil()
			else
				RestoreRecoil()
			end
		end
		if Flags.NoSpread ~= LastNoSpread then
			LastNoSpread = Flags.NoSpread
			if LastNoSpread then
				ApplyNoSpread()
			else
				RestoreSpread()
			end
		end
		local Mouse = UIS:GetMouseLocation()
		local FlickVec = Vector2.new(0, 0)
		if PrevMouse ~= nil then
			FlickVec = Mouse - PrevMouse
		end
		PrevMouse = Mouse
		local RefPt = Mouse
		if Flags.AimTarget == "Crosshair" then
			local Vs = Camera.ViewportSize
			RefPt = Vector2.new(Vs.X / 2, Vs.Y / 2)
		end
		Circle.Position = RefPt
		Circle.Radius = Flags.FOV
		Circle.Color = Flags.CircleColor
		Circle.Visible = Flags.ShowCircle
		UpdateESP(Camera, Camera.ViewportSize)
		pcall(CheckAutoHeal)
		pcall(CheckAutoLoot)
		pcall(CheckAutoShield)
		local NowCfg = os.clock()
		if NowCfg - LastCfgSave > 1 then
			LastCfgSave = NowCfg
			pcall(SaveFlags)
		end
		if not AimActive() then
			return
		end
		if WarzCamera == nil then
			return
		end
		local MyChar = LocalPlayer.Character
		local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
		if MyRoot == nil then
			return
		end
	local Fps = IsFirstPerson()
	local Muzzle = MyRoot.Position
	if Fps then
		Muzzle = Camera.CFrame.Position
	end
	local TargetChar, AimPos, AimScreen = GetTarget(Camera, Muzzle, RefPt, FlickVec)
	if TargetChar == nil or AimPos == nil or AimScreen == nil then
		return
	end
	if Flags.WallCheck then
		-- Visibility semantics: ray from the camera (what you see on screen),
		-- not from HRP/barrel. Fixes FPS camera-in-wall self-block and keeps
		-- the check aligned with the AimScreen error the aimbot follows.
		-- NOTE: server validates from the barrel (BarrelBuried), so an edge
		-- case can still pass here and be rejected there; that is unavoidable
		-- client-side.
		local NowW = os.clock()
		if CachedWallFilter == nil or CachedWallChar ~= MyChar or NowW - LastWallFilterBuild > 2 then
			CachedWallFilter = BuildWallFilter(MyChar)
			CachedWallChar = MyChar
			LastWallFilterBuild = NowW
		end
		RayParams.FilterDescendantsInstances = CachedWallFilter
		local Origin = Camera.CFrame.Position
		local Result = Workspace:Raycast(Origin, AimPos - Origin, RayParams)
			if Result ~= nil and Result.Instance ~= nil and not Result.Instance:IsDescendantOf(TargetChar) then
				return
			end
		end
		local Error = AimScreen - RefPt
		if Error.Magnitude < 1 then
			return
		end
	-- Adaptive chase: far error pulls hard to stay glued to strafers,
	-- near error stays precise. Error in px.
	local ErrMag = Error.Magnitude
	local Chase = math.clamp(ErrMag / 250, 0, 2)
	local Gain = math.clamp(Flags.Smooth / 100, 0.01, 1) * 0.5 * (1 + Chase)
	local LimBase = 30
	if Fps then
		LimBase = 60
	end
	local Lim = LimBase * (1 + math.clamp(ErrMag / 400, 0, 1))
	local Dx = math.clamp(Error.X * Gain, -Lim, Lim)
	local Dy = math.clamp(Error.Y * Gain, -Lim, Lim)
		WarzCamera.AddLookDelta(Dx, Dy)
	end)
	if not ok then
		return
	end
end)

local function Shutdown()
	pcall(SaveFlags)
	pcall(function()
		RunService:UnbindFromRenderStep("VoltScriptZ_Aim")
	end)
	pcall(function()
		Circle:Remove()
	end)
	for _, Conn in ipairs(PlayerConns) do
		pcall(function()
			Conn:Disconnect()
		end)
	end
	if PlayersLeavingConn ~= nil then
		pcall(function()
			PlayersLeavingConn:Disconnect()
		end)
	end
	for Player, _ in pairs(EspPool) do
		pcall(function()
			EspRemove(Player)
		end)
	end
	pcall(RestoreRecoil)
	pcall(RestoreSpread)
	StickyChar = nil
	PrevMouse = nil
	LootPendingUid = nil
	PrevShieldHP = nil
	PendingGunSlot = nil
	ShooterHist = {}
	LastShooterTrack = 0
	CachedWallFilter = nil
	CachedWallChar = nil
	LastWallFilterBuild = 0
end

getgenv().VoltScriptZ_Shutdown = Shutdown

Window.onUnloaded(function()
	pcall(Shutdown)
	pcall(SaveFlags)
	getgenv().VoltScriptZ_Shutdown = nil
end)

AimTab:Select()
MacLib:LoadAutoLoadConfig()
