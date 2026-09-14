-- Patch Fluent: ลบสีฟ้า (96,205,255 / 76,194,255) -> ม่วงเข้ม (110,45,175) สำหรับ Toggle/Slider/Tab (คง Theme Dark)
local _fluentSrc = game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua")
-- แบบ robust: แทน substring โดยตรง ไม่สน space
_fluentSrc = _fluentSrc:gsub("96,205,255", "110, 45, 175")
_fluentSrc = _fluentSrc:gsub("96, 205, 255", "110, 45, 175")
_fluentSrc = _fluentSrc:gsub("76,194,255", "110, 45, 175")
_fluentSrc = _fluentSrc:gsub("76, 194, 255", "110, 45, 175")
-- fallback pattern แบบเต็ม
_fluentSrc = _fluentSrc:gsub("Color3%.fromRGB%(96,205,255%)", "Color3.fromRGB(110, 45, 175)")
_fluentSrc = _fluentSrc:gsub("Color3%.fromRGB%(76,194,255%)", "Color3.fromRGB(110, 45, 175)")
local Fluent = loadstring(_fluentSrc)()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- หน่วง 3 วิก่อน UI ขึ้น (ตามคำขอ)
task.wait(3)

local Window = Fluent:CreateWindow({
    Title = "VoltScript | Dungeon Lootr",
    SubTitle = "Auto Farm - Dungeon",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- บังคับม่วงเข้ม runtime แบบไม่มีกระพริบ (Heartbeat + hook property) คง Theme Dark
do
    local purple = Color3.fromRGB(110, 45, 175)
    local blue1 = Color3.fromRGB(96,205,255)
    local blue2 = Color3.fromRGB(76,194,255)
    local function isBlue(c) return c == blue1 or c == blue2 end
    -- 1) แก้ต้นตอ Creator ทันทีหลัง Window สร้าง (ลบกระพริบตอน Toggle)
    task.spawn(function()
        while not Fluent.GUI do task.wait(0.05) end
        task.wait(0.1)
        pcall(function()
            local gc = getgc and getgc(true) or {}
            for _, tbl in ipairs(gc) do
                if type(tbl)=="table" and rawget(tbl,"GetThemeProperty") and rawget(tbl,"Registry") and rawget(tbl,"UpdateTheme") then
                    local ok, upvals = pcall(function() return debug.getupvalues(tbl.GetThemeProperty) end)
                    if ok and type(upvals)=="table" then
                        for _, uv in ipairs(upvals) do
                            if type(uv)=="table" and uv.Dark and uv.Dark.Accent then
                                uv.Dark.Accent = purple
                                if uv.Darker then uv.Darker.Accent = purple end
                                tbl.UpdateTheme()
                            end
                        end
                    end
                    for inst, data in pairs(tbl.Registry) do
                        if type(data)=="table" and type(data.Properties)=="table" then
                            for prop, tag in pairs(data.Properties) do
                                if tag == "Accent" then pcall(function() inst[prop] = purple end) end
                            end
                        end
                    end
                end
            end
        end)
    end)
    -- 2) Hook ทุกครั้งที่สีเปลี่ยน (GetPropertyChangedSignal) + Heartbeat ทุกเฟรม กันกระพริบ tween 0.25s
    local RunServiceHB = game:GetService("RunService")
    local hooked = {}
    local function hookObj(v)
        if hooked[v] then return end
        hooked[v] = true
        pcall(function()
            if v:IsA("Frame") then
                v:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
                    if isBlue(v.BackgroundColor3) then v.BackgroundColor3 = purple end
                end)
                if isBlue(v.BackgroundColor3) then v.BackgroundColor3 = purple end
            end
            if v:IsA("ImageLabel") then
                v:GetPropertyChangedSignal("ImageColor3"):Connect(function()
                    if isBlue(v.ImageColor3) then v.ImageColor3 = purple end
                end)
                if isBlue(v.ImageColor3) then v.ImageColor3 = purple end
            end
            if v:IsA("UIStroke") then
                v:GetPropertyChangedSignal("Color"):Connect(function()
                    if isBlue(v.Color) then v.Color = purple end
                end)
                if isBlue(v.Color) then v.Color = purple end
            end
        end)
    end
    task.spawn(function()
        while not Fluent.GUI do task.wait(0.05) end
        -- hook ของเดิม
        for _, v in ipairs(Fluent.GUI:GetDescendants()) do hookObj(v) end
        Fluent.GUI.DescendantAdded:Connect(function(v) task.wait() hookObj(v) end)
    end)
    -- ทุกเฟรมบังคับม่วง กัน tween ระหว่างเฟรม
    RunServiceHB.Heartbeat:Connect(function()
        if Fluent.Unloaded then return end
        if not Fluent.GUI then return end
        pcall(function()
            for _, v in ipairs(Fluent.GUI:GetDescendants()) do
                if v:IsA("Frame") and isBlue(v.BackgroundColor3) then v.BackgroundColor3 = purple end
                if v:IsA("ImageLabel") and isBlue(v.ImageColor3) then v.ImageColor3 = purple end
                if v:IsA("UIStroke") and isBlue(v.Color) then v.Color = purple end
            end
        end)
    end)
end

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "swords" }),
    Dungeon = Window:AddTab({ Title = "Dungeon", Icon = "map" }),
    Lobby = Window:AddTab({ Title = "Lobby", Icon = "users" }),
    Shop = Window:AddTab({ Title = "Shop", Icon = "shopping-cart" }),
    BossRaid = Window:AddTab({ Title = "Boss Raid", Icon = "skull" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local PlayerRemotes = ReplicatedStorage:WaitForChild("Player"):WaitForChild("Remotes"):WaitForChild("Inputs")
local AttackRemote = PlayerRemotes:WaitForChild("Attack")
local SkillRemote = PlayerRemotes:WaitForChild("Skill")

getgenv().VoltConfig = getgenv().VoltConfig or {
    AutoFarm = false,
    TweenSpeed = 200,
    AttackDelay = 0.15,
    PositionMode = "Behind",
    Distance = 15,
    OrbitSpeed = 2,
    OrbitRadius = 15,
    AutoSkill = false,
    SkillChoice = {"Skill 1"},
    SkillDelay = 0.5,
    AutoChest = false,
    AutoReplay = false,
    AutoReturn = false,
    AutoContinue = false,
    AutoBuff = false,
    CollectChests = false,
    CollectChallengerChests = false,
    AutoPotion = false,
    PotionThreshold = 50,
    AutoRefill = false,
    AutoCreateDungeon = false,
    AutoCreateBestDungeon = false,
    SelectedDungeon = "Bandits Den",
    SelectedDifficulty = "Nightmare",
    AutoSolo = true,
    FriendsOnly = false,
    SelectedChallengerBoss = "Scarlet Knight, The Crimson Revenant",
    AutoCreateChallenger = false,
    SelectedBossRushBoss = "Cursed King",
    SelectedBossRushSkipFloor = 0,
    AutoCreateBossRush = false,
    AutoUpStats = false,
    UpStatsMode = "Recommend",
    UpStatsTarget = "DEX",
    UpStatsAmount = 1,
    AutoEquipBest = false,
    EquipBestInterval = 1,
    AutoBuy = false,
    BuyRarities = {["Rare"]=true, ["Epic"]=true, ["Legendary"]=true},
    BuyInterval = 2,
    AutoSell = false,
    SellRarities = {["Common"]=true, ["Uncommon"]=true},
    SellInterval = 2,
    EndlessTargetCheckpoint = 5,
    AutoBossRaid = false,
    SelectedRaid = "The First Test",
    SelectedRaidDifficulty = "Normal",
    AutoCreateRaid = false,
}
local Config = getgenv().VoltConfig
local State = Config

local CurrentTarget = nil
local CurrentRoom = nil
local LockConn = nil
local IsCollectingChest = false
local IsCollectingChallengerChest = false
local IsCollectingBossRushChest = false
local IsRefilling = false
local lastPodTeleport = 0
local IsCreatingDungeon = false
local IsCreatingBestDungeon = false
local IsCreatingBossRush = false
local lastBossRushPodTeleport = 0
local IsCreatingRaid = false
local lastRaidPodTeleport = 0
IsRaidFarming = false
CurrentRaidTarget = nil

function getHRP()
    local char = LP.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

function getModelPivotPos(model)
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.Position end
    local ok, cf = pcall(function() return model:GetPivot().Position end)
    if ok then return cf end
    return nil
end

local function isEnemyAlive(model)
    if not model or not model.Parent then return false end
    if model == LP.Character then return false end
    if model.Parent and (model.Parent.Name == "Dialogue_NPCS" or model.Parent.Name == "PlayerModels") then return false end
    if model.Parent and model.Parent.Name == "Combat_Dummies" then return false end
    if model.Parent and (model.Parent.Name == "Debris" or model.Parent.Name == "Loot" or model.Parent.Name == "Dead") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        if hum.Health <= 0 then return false end
        -- Humanoid ศพบางที Health 0 แต่ยังไม่ลบ ให้ตรวจเพิ่ม
        if hum:GetState() == Enum.HumanoidStateType.Dead then return false end
        return true
    end
    -- Raid Boss พิเศษ Dark Professor
    if model.Name == "Dark Professor" or model:GetAttribute("BossId") or model:GetAttribute("RaidBoss") then
        if model:GetAttribute("IsDormant") == true then return false end
        local ho = model:GetAttribute("HealthOverride") or model:GetAttribute("Health")
        if ho and ho <= 0 then return false end
        local hum2 = model:FindFirstChildOfClass("Humanoid")
        if hum2 and hum2.Health <= 0 then return false end
        return true
    end
    local anim = model:FindFirstChildOfClass("AnimationController")
    if anim then
        if model:GetAttribute("IsDormant") == true then return false end
        if model:GetAttribute("IsDead") == true or model:GetAttribute("Dead") == true then return false end
        local ho = model:GetAttribute("HealthOverride")
        if ho and ho <= 0 then return false end
        local h = model:GetAttribute("Health")
        if h and h <= 0 then return false end
        -- ศพ AnimationController มักลบ Highlight ออก หรือ HealthOverride เป็น 0
        local hasHighlight = model:FindFirstChild("EntityHighlight", true) ~= nil
        local hasLevel = model:GetAttribute("Level") and model:GetAttribute("ItemId")
        if hasLevel then
            if ho and ho <= 0 then return false end
            return true
        end
        if hasHighlight then
            if ho and ho <= 0 then return false end
            return true
        end
        return false
    end
    return false
end

function getGeneratedDungeon()
    for _, v in ipairs(workspace:GetChildren()) do
        if v.Name:find("Generated_") then return v end
    end
    return nil
end

function getRoomFolders()
    local gen = getGeneratedDungeon()
    if not gen then return {} end
    local rooms = {}
    for _, v in ipairs(gen:GetChildren()) do
        if v.Name:match("^Room_%d+$") and v:IsA("Model") then
            local spawns = v:FindFirstChild("Spawns")
            if spawns then
                local hasEnemy = false
                for _, sp in ipairs(spawns:GetChildren()) do
                    if sp.Name == "Enemy_Spawn" or sp.Name == "Boss_Spawn" then hasEnemy = true break end
                end
                if hasEnemy then table.insert(rooms, v) end
            end
        end
    end
    table.sort(rooms, function(a,b) return tonumber(a.Name:match("%d+")) < tonumber(b.Name:match("%d+")) end)
    return rooms
end

function getEnemiesInRoom(room)
    if not room then return {} end
    local zone = room:FindFirstChild("Zone")
    local spawns = room:FindFirstChild("Spawns")
    local spawnParts = {}
    if spawns then
        for _, sp in ipairs(spawns:GetChildren()) do
            if sp.Name == "Enemy_Spawn" and sp:IsA("BasePart") then table.insert(spawnParts, sp) end
        end
    end
    local list = {}
    local gen = getGeneratedDungeon()
    local searchList = {}
    if gen and gen:FindFirstChild("NPCs") then
        searchList = gen.NPCs:GetChildren()
    else
        for _, obj in ipairs(workspace:GetDescendants()) do if obj:IsA("Model") and isEnemyAlive(obj) then table.insert(searchList, obj) end end
    end
    for _, obj in ipairs(searchList) do
        if obj:IsA("Model") and isEnemyAlive(obj) then
            local pos = getModelPivotPos(obj)
            if not pos then continue end
            local inside = false
            if zone and zone:IsA("BasePart") then
                local rel = zone.CFrame:PointToObjectSpace(pos)
                local half = zone.Size * 0.5
                if math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y + 30 and math.abs(rel.Z) <= half.Z then inside = true end
            end
            if not inside then
                for _, sp in ipairs(spawnParts) do if (pos - sp.Position).Magnitude < 150 then inside = true break end end
            end
            if not inside and #spawnParts == 0 and zone == nil then
                if (pos - room:GetPivot().Position).Magnitude < 150 then inside = true end
            end
            if inside then table.insert(list, obj) end
        end
    end
    return list
end

function getNearestInRoom(room)
    local hrp = getHRP()
    if not hrp or not room then return nil end
    local mobs = getEnemiesInRoom(room)
    local nearest = nil
    local bestDist = math.huge
    for _, mob in ipairs(mobs) do
        local pos = getModelPivotPos(mob)
        if pos then
            local dist = (pos - hrp.Position).Magnitude
            if dist < bestDist then bestDist = dist nearest = mob end
        end
    end
    return nearest
end

function getChallengeArena()
    return workspace:FindFirstChild("Challenge_Dungeons")
end

function getEnemiesInChallenge()
    local arena = getChallengeArena()
    local list = {}
    -- ถ้าอยู่ใน Challenge จริงให้เช็คก่อน (กัน lobby ที่มี Folder แต่ไม่มีมอน)
    local inChallenge = LP:GetAttribute("InChallenge")
    if arena then
        for _, obj in ipairs(arena:GetDescendants()) do
            if obj:IsA("Model") and isEnemyAlive(obj) then
                table.insert(list, obj)
            end
        end
        if #list == 0 and inChallenge then
            local pivotOk, pivot = pcall(function() return arena:GetPivot().Position end)
            if pivotOk and pivot then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") and isEnemyAlive(obj) then
                        local pos = getModelPivotPos(obj)
                        if pos and (pos - pivot).Magnitude < 500 then
                            table.insert(list, obj)
                        end
                    end
                end
            end
            -- fallback เพิ่ม: ถ้ายังไม่เจอให้ใช้ Challenge_NPCs โดยตรง
            if #list == 0 then
                local cnpcs = workspace:FindFirstChild("Challenge_NPCs")
                if cnpcs then
                    for _, obj in ipairs(cnpcs:GetDescendants()) do
                        if obj:IsA("Model") and isEnemyAlive(obj) then
                            table.insert(list, obj)
                        end
                    end
                end
            end
        end
        if #list > 0 then return list end
        if not inChallenge then return {} end
    end
    local hrp = getHRP()
    if not hrp then return list end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isEnemyAlive(obj) then
            local pos = getModelPivotPos(obj)
            if pos and (pos - hrp.Position).Magnitude < 350 then
                table.insert(list, obj)
            end
        end
    end
    return list
end

function getNearestInChallenge()
    local hrp = getHRP()
    if not hrp then return nil end
    local mobs = getEnemiesInChallenge()
    local nearest, best = nil, math.huge
    for _, mob in ipairs(mobs) do
        local pos = getModelPivotPos(mob)
        if pos then
            local d = (pos - hrp.Position).Magnitude
            if d < best then best=d nearest=mob end
        end
    end
    return nearest
end

-- Boss Rush Helpers [แยกอิสระ]
function getBossRushArena()
    return workspace:FindFirstChild("BossRush_NPCs") or workspace:FindFirstChild("BossRush") or workspace:FindFirstChild("Enemy Models")
end

function getEnemiesInBossRush()
    if not LP:GetAttribute("InBossRush") then return {} end
    local arena = getBossRushArena()
    local list = {}
    if arena then
        for _, obj in ipairs(arena:GetDescendants()) do
            if obj:IsA("Model") and isEnemyAlive(obj) then
                table.insert(list, obj)
            end
        end
        if #list > 0 then return list end
        -- fallback pivot check ถ้า arena เป็น Model
        local ok, pivot = pcall(function() return arena:GetPivot().Position end)
        if ok and pivot then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and isEnemyAlive(obj) then
                    local pos = getModelPivotPos(obj)
                    if pos and (pos - pivot).Magnitude < 500 then
                        table.insert(list, obj)
                    end
                end
            end
            if #list > 0 then return list end
        end
    end
    local hrp = getHRP()
    if not hrp then return list end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isEnemyAlive(obj) then
            local pos = getModelPivotPos(obj)
            if pos and (pos - hrp.Position).Magnitude < 300 then
                table.insert(list, obj)
            end
        end
    end
    return list
end

function getNearestInBossRush()
    local hrp = getHRP()
    if not hrp then return nil end
    local mobs = getEnemiesInBossRush()
    local nearest, best = nil, math.huge
    for _, mob in ipairs(mobs) do
        local pos = getModelPivotPos(mob)
        if pos then
            local d = (pos - hrp.Position).Magnitude
            if d < best then best=d nearest=mob end
        end
    end
    return nearest
end

function getChallengerChests()
    local out={}
    for _,v in ipairs(workspace:GetDescendants()) do
        if v.Name:find("DungeonChest") and v:IsA("Model") then
            -- Challenger chests are in Challenge_NPCs, normal in Generated_
            local hasEffect = v:FindFirstChild("Chest_Effect", true)
            local prompt = v:FindFirstChild("ChestPrompt", true) or v:FindFirstChildWhichIsA("ProximityPrompt", true)
            local enabled = prompt and prompt.Enabled
            if enabled == nil then enabled = hasEffect ~= nil end
            if hasEffect and enabled then
                -- Ensure not locked chest (Challenger has no lock, but check)
                table.insert(out, v)
            end
        end
    end
    return out
end

local function tryReplayReturn()
    local KnitOk, Knit = pcall(function() return require(ReplicatedStorage.Packages.Knit) end)
    if not KnitOk or not Knit then return false end
    local done=false
    pcall(function()
        local svc=Knit.GetService("DungeonRunService")
        if Config.AutoReplay then
            local ok,a=pcall(function() return svc:RequestReplay():await() end)
            if ok and a then done=true end
        elseif Config.AutoReturn then
            local ok,a=pcall(function() return svc:RequestReturn():await() end)
            if ok and a then done=true end
        end
    end)
    pcall(function()
        local svc=Knit.GetService("ChallengeRunService")
        if svc then
            if Config.AutoReplay and svc.RequestReplay then
                local ok,a=pcall(function() return svc:RequestReplay():await() end)
                if ok and a then done=true end
            end
            if Config.AutoReturn and svc.RequestReturn then
                local ok,a=pcall(function() return svc:RequestReturn():await() end)
                if ok and a then done=true end
            end
        end
    end)
    pcall(function()
        local svc=Knit.GetService("BossRushService")
        if svc then
            if Config.AutoReplay and svc.RequestReplay then
                local ok,a=pcall(function() return svc:RequestReplay():await() end)
                if ok and a then done=true end
            end
            if Config.AutoReturn and svc.RequestReturn then
                local ok,a=pcall(function() return svc:RequestReturn():await() end)
                if ok and a then done=true end
            end
        end
    end)
    pcall(function()
        local svc=Knit.GetService("RaidRunService")
        if svc then
            if Config.AutoReplay and svc.RequestReplay then
                local ok,a=pcall(function() return svc:RequestReplay():await() end)
                if ok and a then done=true end
            end
            if Config.AutoReturn and svc.RequestReturn then
                local ok,a=pcall(function() return svc:RequestReturn():await() end)
                if ok and a then done=true end
            end
        end
    end)
    pcall(function()
        local pg=LP.PlayerGui
        for _,name in ipairs({"Replay","Return","ReplayButton","ReturnButton","PlayAgain"}) do
            local btn=pg:FindFirstChild(name, true)
            if btn and btn:IsA("GuiButton") and btn.Visible then
                local lname = name:lower()
                local should = false
                if Config.AutoReplay and (lname:find("replay") or lname:find("playagain")) then should = true end
                if Config.AutoReturn and lname:find("return") then should = true end
                if should then
                    for _,cn in ipairs(getconnections(btn.Activated)) do pcall(function() cn:Fire() end) end
                    for _,cn in ipairs(getconnections(btn.MouseButton1Click)) do pcall(function() cn:Fire() end) end
                    done=true
                end
            end
        end
        local cont=pg:FindFirstChild("Main") and pg.Main:FindFirstChild("HUD") and pg.Main.HUD:FindFirstChild("Dungeon_Container")
        if cont then
            for _,v in ipairs(cont:GetDescendants()) do
                if v:IsA("GuiButton") and v.Visible and (v.Name:lower():find("replay") or v.Name:lower():find("return")) then
                    local lname = v.Name:lower()
                    local should = false
                    if Config.AutoReplay and lname:find("replay") then should = true end
                    if Config.AutoReturn and lname:find("return") then should = true end
                    if Config.AutoReplay and lname:find("playagain") then should = true end
                    if should then
                        for _,cn in ipairs(getconnections(v.Activated)) do pcall(function() cn:Fire() end) end
                        done=true
                    end
                end
            end
        end
    end)
    return done
end

local lastChallengePodTeleport = 0

function getPositionCFrame(target)
    local pos = getModelPivotPos(target)
    if not pos then return nil end
    local d = Config.Distance
    local mode = Config.PositionMode
    if mode == "Above" then
        return CFrame.new(pos + Vector3.new(0, d, 0), pos)
    elseif mode == "Below" then
        local belowPos = pos + Vector3.new(0, -d, 0)
        return CFrame.new(belowPos, belowPos + Vector3.new(0, 1, 0))
    elseif mode == "Orbit Above" then
        local angle = tick() * (Config.OrbitSpeed or 2)
        local r = Config.OrbitRadius or d
        local offset = Vector3.new(math.cos(angle)*r, d, math.sin(angle)*r)
        return CFrame.new(pos + offset, pos)
    elseif mode == "Orbit Below" then
        local angle = tick() * (Config.OrbitSpeed or 2)
        local r = Config.OrbitRadius or d
        local offset = Vector3.new(math.cos(angle)*r, -d, math.sin(angle)*r)
        return CFrame.new(pos + offset, pos)
    else
        local mhrp = target:FindFirstChild("HumanoidRootPart")
        if mhrp then return mhrp.CFrame * CFrame.new(0, 2, d) end
        return CFrame.new(pos + Vector3.new(0, 2, d), pos)
    end
end

local function enableLock(target)
    disableLock()
    LockConn = RunService.Heartbeat:Connect(function()
        if not (Config.AutoFarm or Config.AutoBossRaid) or not target or not isEnemyAlive(target) then return end
        local hrp = getHRP()
        local cf = getPositionCFrame(target)
        if hrp and cf then
            hrp.CFrame = cf
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

function disableLock()
    if LockConn then LockConn:Disconnect() LockConn = nil end
end

local function teleportTo(target)
    local hrp = getHRP()
    local cf = getPositionCFrame(target)
    if not hrp or not cf then return end
    hrp.CFrame = cf
    enableLock(target)
end

local function teleportToRoom(room)
    disableLock()
    local hrp = getHRP()
    if not hrp or not room then return end
    local zone = room:FindFirstChild("Zone")
    local dest = nil
    if zone and zone:IsA("BasePart") then
        dest = zone.Position + Vector3.new(0, 3, 0)
    else
        local spawns = room:FindFirstChild("Spawns")
        if spawns then
            for _, sp in ipairs(spawns:GetChildren()) do
                if sp.Name == "Enemy_Spawn" and sp:IsA("BasePart") then dest = sp.Position + Vector3.new(0, 2, 0) break end
            end
        end
        if not dest then dest = room:GetPivot().Position + Vector3.new(0, 3, 0) end
    end
    hrp.CFrame = CFrame.new(dest)
end

local function waitForRoomSpawn(room, timeout)
    timeout = timeout or 4
    local start = tick()
    while tick() - start < timeout do
        if not Config.AutoFarm then break end
        if #getEnemiesInRoom(room) > 0 then return true end
        task.wait(0.2)
    end
    return #getEnemiesInRoom(room) > 0
end

local function tweenTo(target)
    disableLock()
    local hrp = getHRP()
    local cf = getPositionCFrame(target)
    if not hrp or not cf then return end
    local dist = (cf.Position - hrp.Position).Magnitude
    local time = math.clamp(dist / Config.TweenSpeed, 0.15, 1.2)
    local tween = TweenService:Create(hrp, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = cf})
    tween:Play()
    tween.Completed:Wait()
    enableLock(target)
end

local lastGenNil = tick()
local function startFarm()
    task.spawn(function()
        local rooms = getRoomFolders()
        CurrentRoom = rooms[1]
        if CurrentRoom then
            teleportToRoom(CurrentRoom)
            waitForRoomSpawn(CurrentRoom, 3)
        end
        while Config.AutoFarm do
            if Fluent.Unloaded then disableLock() break end
            -- Boss Rush branch [แยกอิสระ ไม่ยุ่ง Dungeon/Challenger]
            if LP:GetAttribute("InBossRush") then
                if IsCollectingBossRushChest then task.wait(0.2) continue end
                local bossEnemies = getEnemiesInBossRush()
                if #bossEnemies > 0 then
                    local target = getNearestInBossRush()
                    if target and isEnemyAlive(target) then
                        if CurrentTarget ~= target then
                            if CurrentTarget ~= nil then tweenTo(target) else teleportTo(target) end
                            CurrentTarget = target
                        else
                            enableLock(target)
                        end
                        while Config.AutoFarm and target and isEnemyAlive(target) and LP:GetAttribute("InBossRush") do
                            if IsCollectingBossRushChest then break end
                            pcall(function() AttackRemote:FireServer(target) end)
                            task.wait(Config.AttackDelay)
                            if not isEnemyAlive(target) then break end
                        end
                        disableLock()
                        CurrentTarget = nil
                    else
                        task.wait(0.2)
                    end
                    task.wait(0.05)
                    continue
                end
                task.wait(0.3)
                continue
            end
            -- Challenger branch [แยก flag ไม่ปนกับ Dungeon] - เช็ค InChallenge จริงเท่านั้น
            if LP:GetAttribute("InChallenge") then
                if IsCollectingChallengerChest then task.wait(0.2) continue end
                local challengeEnemies = getEnemiesInChallenge()
                if #challengeEnemies > 0 then
                    local target = getNearestInChallenge()
                    if target and isEnemyAlive(target) then
                        if CurrentTarget ~= target then
                            if CurrentTarget ~= nil then tweenTo(target) else teleportTo(target) end
                            CurrentTarget = target
                        else
                            enableLock(target)
                        end
                        while Config.AutoFarm and target and isEnemyAlive(target) do
                            if IsCollectingChallengerChest then break end
                            pcall(function() AttackRemote:FireServer(target) end)
                            task.wait(Config.AttackDelay)
                            if not isEnemyAlive(target) then break end
                        end
                        disableLock()
                        CurrentTarget = nil
                    else
                        task.wait(0.2)
                    end
                    task.wait(0.05)
                    continue
                end
                if Config.AutoReplay or Config.AutoReturn then
                    pcall(function() tryReplayReturn() end)
                end
                task.wait(0.3)
                continue
            end
            local gen = getGeneratedDungeon()
            if not gen then
                CurrentRoom = nil disableLock()
                if tick() - lastGenNil > 3 and (Config.AutoReplay or Config.AutoReturn) then
                    pcall(function() tryReplayReturn() end)
                end
                task.wait(0.7) continue
            else
                lastGenNil = tick()
            end
            rooms = getRoomFolders()
            if #rooms == 0 then task.wait(0.7) continue end
            if not CurrentRoom then CurrentRoom = rooms[1] teleportToRoom(CurrentRoom) waitForRoomSpawn(CurrentRoom, 3) end
            while Config.AutoFarm and CurrentRoom and #getEnemiesInRoom(CurrentRoom) > 0 do
                if Fluent.Unloaded then disableLock() break end
                local target = getNearestInRoom(CurrentRoom)
                if not target or not isEnemyAlive(target) then task.wait(0.1) break end
                if CurrentTarget ~= target then
                    if CurrentTarget ~= nil then tweenTo(target) else teleportTo(target) end
                    CurrentTarget = target
                else
                    enableLock(target)
                end
                while Config.AutoFarm and target and isEnemyAlive(target) do
                    local inRoom = false
                    for _, m in ipairs(getEnemiesInRoom(CurrentRoom)) do if m == target then inRoom = true break end end
                    if not inRoom then break end
                    pcall(function() AttackRemote:FireServer(target) end)
                    task.wait(Config.AttackDelay)
                    if not isEnemyAlive(target) then break end
                end
                disableLock()
                local nextInRoom = getNearestInRoom(CurrentRoom)
                if nextInRoom and nextInRoom ~= target and isEnemyAlive(nextInRoom) then
                    local hrp = getHRP()
                    local cf = getPositionCFrame(nextInRoom)
                    if hrp and cf then
                        local dist = (cf.Position - hrp.Position).Magnitude
                        local fastTime = math.clamp(dist / 400, 0.08, 0.6)
                        local tw = TweenService:Create(hrp, TweenInfo.new(fastTime, Enum.EasingStyle.Linear), {CFrame = cf})
                        tw:Play()
                        tw.Completed:Wait()
                        enableLock(nextInRoom)
                    else
                        tweenTo(nextInRoom)
                    end
                    CurrentTarget = nextInRoom
                else
                    CurrentTarget = nil
                end
            end
            if Config.AutoFarm and CurrentRoom and #getEnemiesInRoom(CurrentRoom) == 0 then
                task.wait(0.15)
                while (IsCollectingChest or IsRefilling) and Config.AutoFarm do task.wait(0.1) end
                local t0=tick()
                while tick()-t0 < 1.2 and Config.AutoFarm do
                    local hasPendingChest=false
                    local gen=getGeneratedDungeon()
                    if gen and CurrentRoom and Config.CollectChests then
                        local curIdx=CurrentRoom.Name:match("%d+")
                        for _,v in ipairs(gen:GetChildren()) do
                            if v.Name:find("DungeonChest") and tostring(v:GetAttribute("RoomIndex") or "")==curIdx and v:FindFirstChild("Chest_Effect", true) then
                                local p=v:FindFirstChild("ChestPrompt", true)
                                if not p or p.Enabled then hasPendingChest=true break end
                            end
                        end
                    end
                    local needRefill=false
                    if Config.AutoRefill and CurrentRoom then
                        function getCnt()
                            local ok, reg = pcall(function() return require(game.Players.LocalPlayer.PlayerScripts.Client.Controllers.Registry):Get("PlayerData") end)
                            if ok and reg and reg.Data and reg.Data.Potions then
                                local eq=reg.Data.EquippedPotion
                                if eq and reg.Data.Potions[eq]~=nil then return reg.Data.Potions[eq] end
                                local s=0 for _,vv in pairs(reg.Data.Potions) do s=s+vv end return s
                            end
                            return 99
                        end
                        if getCnt() <= 2 then
                            for _,v in ipairs(gen and gen:GetDescendants() or {}) do
                                if v.Name=="Potion_Station" then
                                    local rp=v:GetPivot().Position
                                    local crp=CurrentRoom:GetPivot().Position
                                    if (rp - crp).Magnitude < 120 then needRefill=true break end
                                end
                            end
                        end
                    end
                    if not hasPendingChest and not needRefill and not IsCollectingChest and not IsRefilling then break end
                    task.wait(0.15)
                end
                if #getEnemiesInRoom(CurrentRoom) == 0 then
                    while (IsCollectingChest or IsRefilling) and Config.AutoFarm do task.wait(0.1) end
                    local foundIdx = nil
                    for i, r in ipairs(rooms) do if r == CurrentRoom then foundIdx = i break end end
                    if foundIdx then
                        local nextIdx = foundIdx + 1
                        if nextIdx <= #rooms then
                            CurrentRoom = rooms[nextIdx]
                            CurrentTarget = nil
                            disableLock()
                            teleportToRoom(CurrentRoom)
                            waitForRoomSpawn(CurrentRoom, 4)
                        else
                            task.wait(0.8)
                            task.wait(1.0)
                            local hasAny = false
                            for _, r in ipairs(rooms) do if #getEnemiesInRoom(r) > 0 then hasAny = true break end end
                            if not hasAny then
                                local found = false
                                -- วาร์ปเช็คเฉพาะ Boss_Spawn ตั้งแต่ห้องแรกถึงสุดท้าย (ไม่เช็คมินิมอน)
                                for _, r2 in ipairs(rooms) do
                                    local bossSp = r2:FindFirstChild("Spawns") and r2.Spawns:FindFirstChild("Boss_Spawn")
                                    if bossSp and bossSp:IsA("BasePart") then
                                        local hrp = getHRP()
                                        if hrp then hrp.CFrame = CFrame.new(bossSp.Position + Vector3.new(0, 5, 0)) end
                                        task.wait(0.5)
                                        if #getEnemiesInRoom(r2) > 0 then CurrentRoom = r2 found = true break end
                                        task.wait(0.8)
                                        if #getEnemiesInRoom(r2) > 0 then CurrentRoom = r2 found = true break end
                                    end
                                end
                                if not found then
                                    CurrentRoom = rooms[1]
                                    teleportToRoom(CurrentRoom)
                                    waitForRoomSpawn(CurrentRoom, 1)
                                end
                            else
                                for _, r in ipairs(rooms) do if #getEnemiesInRoom(r) > 0 then CurrentRoom = r break end end
                                teleportToRoom(CurrentRoom)
                            end
                        end
                    end
                end
            end
            task.wait(0.05)
        end
        disableLock()
    end)
end

local function stopFarm()
    Config.AutoFarm = false
    disableLock()
    CurrentTarget = nil
    CurrentRoom = nil
end

-- Auto Replay/Return อิสระ ไม่ต้องเปิด Auto Farm [กดเฉพาะตอน UI เกมขึ้นเองหลังตาย/จบ]
task.spawn(function()
    while true do
        task.wait(0.8)
        if Fluent.Unloaded then continue end
        if Config.AutoReplay or Config.AutoReturn then
            pcall(function()
                local pg = LP.PlayerGui
                if not pg then return end
                -- หาปุ่มที่ Visible จริงเท่านั้น ไม่เรียก RequestReplay เองให้ UI เด้ง
                local candidates = {}
                for _, name in ipairs({"Replay","Return","ReplayButton","ReturnButton","PlayAgain"}) do
                    local btn = pg:FindFirstChild(name, true)
                    if btn and btn:IsA("GuiButton") and btn.Visible and btn.Enabled ~= false then
                        table.insert(candidates, btn)
                    end
                end
                local cont = pg:FindFirstChild("Main") and pg.Main:FindFirstChild("HUD") and pg.Main.HUD:FindFirstChild("Dungeon_Container")
                if cont then
                    for _, v in ipairs(cont:GetDescendants()) do
                        if v:IsA("GuiButton") and v.Visible and v.Enabled ~= false and (v.Name:lower():find("replay") or v.Name:lower():find("return")) then
                            table.insert(candidates, v)
                        end
                    end
                end
                for _, btn in ipairs(candidates) do
                    local lname = btn.Name:lower()
                    local should = false
                    if Config.AutoReplay and (lname:find("replay") or lname:find("playagain")) then should = true end
                    if Config.AutoReturn and lname:find("return") then should = true end
                    if should then
                        for _, cn in ipairs(getconnections(btn.Activated)) do pcall(function() cn:Fire() end) end
                        for _, cn in ipairs(getconnections(btn.MouseButton1Click)) do pcall(function() cn:Fire() end) end
                    end
                end
            end)
        end
    end
end)

do
    Tabs.Main:AddToggle("AutoFarm", { Title = "Auto Farm", Default = false }):OnChanged(function()
        Config.AutoFarm = Options.AutoFarm.Value
        if Config.AutoFarm then
            CurrentTarget = nil
            startFarm()
        else
            stopFarm()
        end
    end)

    Tabs.Main:AddDropdown("PositionMode", {
        Title = "Position",
        Values = {"Above", "Behind", "Below", "Orbit Above", "Orbit Below"},
        Multi = false,
        Default = 2,
    }):OnChanged(function(v)
        Config.PositionMode = v
        if CurrentTarget and isEnemyAlive(CurrentTarget) and Config.AutoFarm then enableLock(CurrentTarget) end
    end)

    Tabs.Main:AddSlider("Distance", {
        Title = "Distance",
        Default = 15,
        Min = 8,
        Max = 25,
        Rounding = 0,
        Callback = function(v) Config.Distance = math.floor(v) end
    })

    Tabs.Main:AddSlider("OrbitSpeed", {
        Title = "Orbit Speed",
        Default = 2,
        Min = 0.5,
        Max = 5,
        Rounding = 1,
        Callback = function(v) Config.OrbitSpeed = v end
    })

    Tabs.Main:AddSlider("OrbitRadius", {
        Title = "Orbit Radius",
        Default = 15,
        Min = 5,
        Max = 30,
        Rounding = 0,
        Callback = function(v) Config.OrbitRadius = math.floor(v) end
    })

    Tabs.Main:AddSection("Skill")
    function getSkillDir()
        local hrp = getHRP()
        local target = nil
        if LP:GetAttribute("InRaid") and Config.AutoBossRaid and CurrentRaidTarget and isEnemyAlive(CurrentRaidTarget) then
            target = CurrentRaidTarget
        else
            target = CurrentTarget
        end
        if target and isEnemyAlive(target) and hrp then
            local pos = getModelPivotPos(target)
            if pos then return (pos - hrp.Position).Unit end
        end
        return hrp and hrp.CFrame.LookVector or Vector3.new(0,0,-1)
    end
    local SkillLoop = nil
    local keyMap = {["1"]=Enum.KeyCode.One, ["2"]=Enum.KeyCode.Two, ["3"]=Enum.KeyCode.Three, ["4"]=Enum.KeyCode.Four}
    local function startAutoSkill()
        if SkillLoop then task.cancel(SkillLoop) SkillLoop = nil end
        SkillLoop = task.spawn(function()
            while Config.AutoSkill do
                if Fluent.Unloaded then break end
                local isRaid = LP:GetAttribute("InRaid") and Config.AutoBossRaid
                local target = isRaid and CurrentRaidTarget or CurrentTarget
                if not (Config.AutoFarm or Config.AutoBossRaid) or not target or not isEnemyAlive(target) or not LockConn then
                    task.wait(0.3)
                    continue
                end
                local choices = Config.SkillChoice
                if type(choices) == "string" then choices = {choices} end
                if type(choices) == "table" then
                    local list = {}
                    for k,v in pairs(choices) do
                        if type(k)=="number" and type(v)=="string" then table.insert(list, v)
                        elseif v==true then table.insert(list, k) end
                    end
                    if #list==0 and #choices>0 then list = choices end
                    table.sort(list)
                    for _, label in ipairs(list) do
                        if not Config.AutoSkill then break end
                        local sid = tostring(label):match("%d+")
                        local key = keyMap[sid]
                        if key then
                            pcall(function()
                                local vim = game:GetService("VirtualInputManager")
                                vim:SendKeyEvent(true, key, false, game)
                                task.wait(0.05)
                                vim:SendKeyEvent(false, key, false, game)
                            end)
                            if not pcall(function() end) then
                                local dir = getSkillDir()
                                if dir.Magnitude>0 then dir=Vector3.new(dir.X,0,dir.Z).Unit end
                                if dir.Magnitude==0 then dir=Vector3.new(0,0,-1) end
                                pcall(function() SkillRemote:FireServer(sid, "tap", dir) end)
                            end
                        end
                        task.wait(0.25)
                    end
                end
                task.wait(Config.SkillDelay)
            end
            SkillLoop = nil
        end)
    end
    local function stopAutoSkill()
        if SkillLoop then task.cancel(SkillLoop) SkillLoop = nil end
    end
    local function formatChoices(v)
        if type(v)=="string" then return v end
        if type(v)=="number" then return tostring(v) end
        local t={}
        for k,val in pairs(v) do
            if type(k)=="number" and type(val)=="string" then table.insert(t,tostring(val))
            elseif type(k)=="string" and type(val)=="string" then table.insert(t,val)
            elseif val==true then table.insert(t,tostring(k)) end
        end
        table.sort(t)
        return table.concat(t,", ")
    end
    Tabs.Main:AddToggle("AutoSkill", { Title = "Auto Skill", Default = false }):OnChanged(function()
        Config.AutoSkill = Options.AutoSkill.Value
        if Config.AutoSkill then
            startAutoSkill()
        else
            stopAutoSkill()
        end
    end)
    Tabs.Main:AddDropdown("SkillChoice", {
        Title = "Select Skill",
        Values = {"Skill 1","Skill 2","Skill 3","Skill 4"},
        Multi = true,
        Default = {"Skill 1"},
    }):OnChanged(function(v)
        Config.SkillChoice = v
    end)
    Tabs.Main:AddSection("Complete")
    Tabs.Main:AddToggle("AutoChest", { Title = "Skip Chest", Default = false }):OnChanged(function()
        Config.AutoChest = Options.AutoChest.Value
    end)
    Tabs.Main:AddToggle("AutoReplay", { Title = "Replay", Default = false }):OnChanged(function()
        Config.AutoReplay = Options.AutoReplay.Value
        if Config.AutoReplay and Config.AutoReturn then
            Config.AutoReturn = false
            if Options.AutoReturn then Options.AutoReturn:SetValue(false) end
        end
    end)
    Tabs.Main:AddToggle("AutoReturn", { Title = "Return", Default = false }):OnChanged(function()
        Config.AutoReturn = Options.AutoReturn.Value
        if Config.AutoReturn and Config.AutoReplay then
            Config.AutoReplay = false
            if Options.AutoReplay then Options.AutoReplay:SetValue(false) end
        end
    end)
    Tabs.Main:AddToggle("AutoContinue", { Title = "Continue (Endless Only)", Default = false }):OnChanged(function()
        Config.AutoContinue = Options.AutoContinue.Value
    end)
    Tabs.Main:AddToggle("AutoBuff", { Title = "Auto Select Buff", Default = false }):OnChanged(function()
        Config.AutoBuff = Options.AutoBuff.Value
    end)
    Tabs.Main:AddSection("Chest")
    Tabs.Main:AddToggle("CollectChests", { Title = "Collect Chests [Dungeon]", Default = false }):OnChanged(function()
        Config.CollectChests = Options.CollectChests.Value
    end)
    Tabs.Main:AddToggle("CollectChallengerChests", { Title = "Collect Chests [Challenger]", Default = false }):OnChanged(function()
        Config.CollectChallengerChests = Options.CollectChallengerChests.Value
    end)
    Tabs.Main:AddSection("Potion")
    Tabs.Main:AddToggle("AutoPotion", { Title = "Auto Use Potion", Default = false }):OnChanged(function()
        Config.AutoPotion = Options.AutoPotion.Value
    end)
    Tabs.Main:AddSlider("PotionThreshold", {
        Title = "Health Threshold",
        Default = 50,
        Min = 10,
        Max = 100,
        Rounding = 0,
        Callback = function(v) Config.PotionThreshold = math.floor(v) end
    })
    Tabs.Main:AddToggle("AutoRefill", { Title = "Auto Refill Potions", Default = false }):OnChanged(function()
        Config.AutoRefill = Options.AutoRefill.Value
    end)
end

-- Dungeon Tab: Auto Create Dungeon (UI Simulation like human)
do
    Tabs.Dungeon:AddSection("Dungeon")

    local DungeonList = {"Bandits Den", "Goblins", "Knights", "Catacombs", "Snow", "Demon", "Mage"}
    local DifficultyList = {"Easy", "Normal", "Hard", "Nightmare", "Endless"}

    Tabs.Dungeon:AddDropdown("SelectedDungeon", {
        Title = "Select Dungeon",
        Values = DungeonList,
        Multi = false,
        Default = 1,
    }):OnChanged(function(v) Config.SelectedDungeon = v end)

    Tabs.Dungeon:AddDropdown("SelectedDifficulty", {
        Title = "Select Difficulty",
        Values = DifficultyList,
        Multi = false,
        Default = 4,
    }):OnChanged(function(v) Config.SelectedDifficulty = v end)

    Tabs.Dungeon:AddInput("EndlessTargetCheckpoint", {
        Title = "Target Checkpoint (Endless)",
        Default = "5",
        Placeholder = "1-20",
        Numeric = true,
        Finished = false,
        Callback = function(v)
            local n = tonumber(v) or 5
            n = math.clamp(math.floor(n), 1, 20)
            Config.EndlessTargetCheckpoint = n
        end
    })

    Tabs.Dungeon:AddToggle("AutoSolo", { Title = "Solo Mode", Default = true }):OnChanged(function()
        Config.AutoSolo = Options.AutoSolo.Value
    end)

    Tabs.Dungeon:AddToggle("FriendsOnly", { Title = "Friends Only", Default = false }):OnChanged(function()
        Config.FriendsOnly = Options.FriendsOnly.Value
    end)

    local function clickButton(btn)
        if not btn then return false end
        local fired = false
        pcall(function()
            for _,c in ipairs(getconnections(btn.Activated)) do pcall(function() c:Fire() fired=true end) end
        end)
        pcall(function()
            for _,c in ipairs(getconnections(btn.MouseButton1Click)) do pcall(function() c:Fire() fired=true end) end
        end)
        if not fired then pcall(function() btn:Activate() fired=true end) end
        return fired
    end

    local function simulateUICreate(dungeon, diff)
        if IsCreatingDungeon then return end
        IsCreatingDungeon = true
        task.spawn(function()
            local ok, Knit = pcall(function() return require(ReplicatedStorage.Packages.Knit) end)
            local ctrl = nil
            pcall(function() ctrl = Knit.GetController("DungeonSelectController") end)
            local pg = LP:FindFirstChild("PlayerGui")
            if not pg then IsCreatingDungeon = false return end

            -- If already in dungeon, fallback to direct RequestDungeonChange (UI not for changing)
            if LP:GetAttribute("InDungeon") == true then
                local DRS = nil pcall(function() DRS = Knit.GetService("DungeonRunService") end)
                if DRS then
                    pcall(function() DRS:RequestDungeonChange(dungeon, diff):await() end)
                end
                return
            end

            -- 1) Teleport ไป Pod_Zone แทนเปิด UI
            local hrp = getHRP()
            if hrp then
                local podsFolder = workspace:FindFirstChild("pods")
                local targetPos = nil
                if podsFolder then
                    local nearest, best = nil, math.huge
                    for _,v in ipairs(podsFolder:GetChildren()) do
                        if v.Name=="Pod_Zone" and v:IsA("Model") then
                            -- เช็ค Pod เต็ม: ข้ามถ้ามี Player >=1/4
                            local occupied = false
                            local bill = v:FindFirstChild("GuiAttachment", true)
                            if bill then bill = bill:FindFirstChild("BillboardGui", true) end
                            local cntLabel = bill and bill:FindFirstChild("PlayerCount")
                            if cntLabel and cntLabel.Text then
                                local cnt = tonumber(cntLabel.Text:match("(%d+)/"))
                                if cnt and cnt >= 1 then occupied = true end
                            end
                            if occupied then continue end
                            local ok,pos = pcall(function() return v:GetPivot().Position end)
                            if ok and pos then
                                local d = (pos - hrp.Position).Magnitude
                                if d < best then best=d targetPos=pos end
                            end
                        end
                    end
                end
                if not targetPos then
                    -- ไม่มี Pod ว่าง (ทุก Pod มีคน >=1) รอรอบหน้า ไม่วาร์ปไป Pod เต็ม
                    return
                end
                -- กันเทเลพอร์ตรัว: ถ้าอยู่ใกล้ Pod แล้วหรือเพิ่งวาร์ปไปไม่เกิน 4 วิ ข้าม
                local dist = (targetPos - hrp.Position).Magnitude
                if dist < 30 or tick() - lastPodTeleport < 4 then
                    -- อยู่ Pod แล้ว ไม่ต้องวาร์ปซ้ำ
                else
                    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0,5,0))
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    lastPodTeleport = tick()
                    task.wait(0.25)
                end
            end
            local ds = pg:FindFirstChild("Main") and pg.Main:FindFirstChild("Frames") and pg.Main.Frames:FindFirstChild("Dungeon_Select")
            -- ถ้า UI เปิดอยู่แล้วและกำลังเลือกอยู่ อย่าเปิดซ้อน
            if ds and ds.Visible then
                -- เช็คว่าเลือกตรงที่ต้องการแล้วหรือยัง ถ้าตรงแล้วไม่ต้องเปิดใหม่
                local curTitle = ds.Contents.RightSection.Info:FindFirstChild("Title")
                if curTitle and curTitle.Text:find(dungeon:sub(1,5)) then
                    -- เปิดอยู่แล้ว ใช้ต่อได้เลย
                else
                    -- ปิดแล้วเปิดใหม่เพื่อรีเฟรช
                    pcall(function() ctrl:Close() end)
                    task.wait(0.05)
                    pcall(function() ctrl:Open() end)
                    task.wait(0.03)
                    ds = pg.Main.Frames.Dungeon_Select
                end
            else
                pcall(function() ctrl:Open() end)
                task.wait(0.03)
                ds = pg.Main.Frames.Dungeon_Select
            end
            if not ds or not ds.Visible then
                IsCreatingDungeon = false
                return
            end
            ds = pg.Main.Frames.Dungeon_Select
            local scroll = ds.Contents.LeftSection.ScrollingFrame
            local rightInfo = ds.Contents.RightSection.Info

            -- 1.5) Friends Only / Solo อัตโนมัติก่อนเลือกดัน (ไม่กวน Auto Create)
            do
                local friendsBtn = ds:FindFirstChild("FriendsOnlyButton") or ds.Contents:FindFirstChild("FriendsOnlyButton")
                local soloBtn = ds:FindFirstChild("SoloButton") or ds.Contents:FindFirstChild("SoloButton")
                -- fallback to full path
                if not friendsBtn then friendsBtn = pg.Main.Frames.Dungeon_Select.Contents:FindFirstChild("FriendsOnlyButton") end
                if not soloBtn then soloBtn = pg.Main.Frames.Dungeon_Select.Contents:FindFirstChild("SoloButton") end
                local function isFriendsOn()
                    local lbl = ds:FindFirstChild("FriendsOnlyTitle") or pg.Main.Frames.Dungeon_Select.Contents:FindFirstChild("FriendsOnlyTitle")
                    if lbl and lbl.Text then return lbl.Text:find("ON") ~= nil end
                    return false
                end
                local function isSoloOn()
                    local lbl = ds:FindFirstChild("SoloTitle") or pg.Main.Frames.Dungeon_Select.Contents:FindFirstChild("SoloTitle")
                    if lbl then return lbl.TextColor3.G > 0.5 end
                    return false
                end
                if friendsBtn and isFriendsOn() ~= Config.FriendsOnly then
                    clickButton(friendsBtn)
                    task.wait(0.15)
                end
                if soloBtn and isSoloOn() ~= Config.AutoSolo then
                    clickButton(soloBtn)
                    task.wait(0.15)
                end
            end

            -- 2) Select Dungeon -> ต้องกดจนขึ้น SELECTED ไม่งั้นสร้างไม่ได้
            local dungeonFrame = scroll:FindFirstChild(dungeon)
            if not dungeonFrame then
                pcall(function() ctrl:SelectDungeon(dungeon) end)
            else
                local selBtn = dungeonFrame:FindFirstChild("Main") and dungeonFrame.Main:FindFirstChild("Select")
                if selBtn then
                    clickButton(selBtn)
                    pcall(function() ctrl:SelectDungeon(dungeon) end)
                    -- รอจนปุ่มเปลี่ยนเป็น SELECTED
                    local t0 = tick()
                    while tick() - t0 < 1.2 do
                        local txt = ""
                        pcall(function()
                            local lbl = selBtn:FindFirstChild("TextLabel") or selBtn:FindFirstChild("Title")
                            if lbl then txt = lbl.Text
                            elseif selBtn:FindFirstChild("Text") then txt = selBtn.Text
                            else txt = selBtn.Name end
                        end)
                        if txt:find("SELECTED") then break end
                        -- เช็คผ่าน controller title ก็ได้
                        local curTitle = ds.Contents.RightSection.Info:FindFirstChild("Title")
                        if curTitle and curTitle.Text:find(dungeon:sub(1,4)) then break end
                        task.wait(0.06)
                    end
                    -- ย้ำอีกรอบกันหลุด
                    pcall(function() ctrl:SelectDungeon(dungeon) end)
                else
                    pcall(function() ctrl:SelectDungeon(dungeon) end)
                end
            end
            task.wait(0.4)

            -- 3) Select Difficulty -> auto select level
            local diffBtn = rightInfo:FindFirstChild(diff)
            if diffBtn then
                clickButton(diffBtn)
            end
            -- บังคับผ่าน controller โดยตรง กันคลิกไม่ติด
            pcall(function() ctrl:SelectDifficulty(diff) end)
            task.wait(0.02)
            -- บังคับล็อคไม่ให้ดีดกลับ Easy: ย้ำอีกรอบหลัง Refresh เสร็จ
            task.wait(0.35)
            pcall(function() ctrl:SelectDifficulty(diff) end)
            pcall(function()
                local DQS2 = Knit.GetService("DungeonQueueService")
                DQS2:RequestSelectDifficulty(diff):await()
            end)
            -- ย้ำอีกรอบกันหลุด
            task.wait(0.05)
            pcall(function() ctrl:SelectDifficulty(diff) end)

            -- Handle Solo toggle if needed
            -- Solo is top-right switch, but we keep config; if mismatch try click
            -- Not critical for queue, solo will be forced via service call below if UI fails

            -- 4) Click ENTER like human (visual) - ensure u179/u180 set via UI before click
            local enterBtn = rightInfo:FindFirstChild("Buttons") and rightInfo.Buttons:FindFirstChild("Enter")
            if enterBtn then
                clickButton(enterBtn)
                -- fallback if UI click blocked by pod mismatch (x2) -> force SoloRun directly
                task.wait(0.4)
                if LP:GetAttribute("InDungeon")==false and not getGeneratedDungeon() then
                    local DQS = nil pcall(function() DQS = Knit.GetService("DungeonQueueService") end)
                    if DQS and Config.AutoSolo then
                        pcall(function() DQS:RequestStartSoloRun():await() end)
                    end
                end
            else
                local DQS = nil pcall(function() DQS = Knit.GetService("DungeonQueueService") end)
                if DQS then
                    if Config.AutoSolo then pcall(function() DQS:RequestStartSoloRun():await() end)
                    else pcall(function() DQS:RequestStartPodQueue():await() end) end
                end
            end
            -- 5) Auto START
            task.spawn(function()
                local pg2 = LP:FindFirstChild("PlayerGui")
                if not pg2 then return end
                local startBtn = pg2:FindFirstChild("Main") and pg2.Main:FindFirstChild("HUD") and pg2.Main.HUD:FindFirstChild("Dungeon_Container") and pg2.Main.HUD.Dungeon_Container:FindFirstChild("Start")
                local t0 = tick()
                while tick() - t0 < 10 do
                    if startBtn and startBtn.Visible then
                        clickButton(startBtn)
                        -- fallback service
                        pcall(function()
                            local DQS = require(ReplicatedStorage.Packages.Knit).GetService("DungeonQueueService")
                            DQS:RequestStartNow():await()
                        end)
                        break
                    end
                    -- also try service directly if button not visible but queued
                    if tick() - t0 > 3 then
                        pcall(function()
                            local DQS = require(ReplicatedStorage.Packages.Knit).GetService("DungeonQueueService")
                            DQS:RequestStartNow():await()
                        end)
                    end
                    task.wait(0.25)
                end
            end)
            IsCreatingDungeon = false
        end)
        task.delay(5, function() IsCreatingDungeon = false end)
    end

    Tabs.Dungeon:AddToggle("AutoCreateDungeon", { Title = "Auto Create Dungeon", Default = false }):OnChanged(function()
        Config.AutoCreateDungeon = Options.AutoCreateDungeon.Value
        if Config.AutoCreateDungeon then
            task.spawn(function()
                while Config.AutoCreateDungeon do
                    if Fluent.Unloaded then break end
                    if LP:GetAttribute("InDungeon") == false and not getGeneratedDungeon() then
                        -- ถ้า UI เปิดอยู่ให้หยุดก่อน อย่าเปิดซ้อนทับการเลือกของ user
                        local ctrlCheck = nil
                        pcall(function() ctrlCheck = require(ReplicatedStorage.Packages.Knit).GetController("DungeonSelectController") end)
                        if not IsCreatingDungeon then
                            simulateUICreate(Config.SelectedDungeon, Config.SelectedDifficulty)
                            task.wait(3)
                        else
                            task.wait(1)
                        end
                    else
                        task.wait(1.5)
                    end
                end
            end)
        else
        end
    end)

    Tabs.Dungeon:AddButton({ Title = "Create Now", Callback = function()
        simulateUICreate(Config.SelectedDungeon, Config.SelectedDifficulty)
    end})

    Tabs.Dungeon:AddSection("Best Dungeon")

    Tabs.Dungeon:AddToggle("AutoCreateBestDungeon", { Title = "Auto Create Best Dungeon", Default = false }):OnChanged(function()
        Config.AutoCreateBestDungeon = Options.AutoCreateBestDungeon.Value
        if Config.AutoCreateBestDungeon then
            task.spawn(function()
                while Config.AutoCreateBestDungeon do
                    if Fluent.Unloaded then break end
                    if LP:GetAttribute("InDungeon") == false and not getGeneratedDungeon() and not IsCreatingBestDungeon and not IsCreatingDungeon then
                        local lvl = 1
                        do
                            local okK, KnitTmp = pcall(function() return require(ReplicatedStorage.Packages.Knit) end)
                            if okK and KnitTmp then
                                local okR, reg = pcall(function() return KnitTmp.Registry:Get("PlayerData") end)
                                if okR and reg and reg.Data and reg.Data.PlayerLevel then lvl = reg.Data.PlayerLevel end
                            end
                            if lvl == 1 then
                                local ok2, pd2 = pcall(function() return require(game.Players.LocalPlayer.PlayerScripts.Client.Controllers.Registry):Get("PlayerData") end)
                                if ok2 and pd2 and pd2.Data and pd2.Data.PlayerLevel then lvl = pd2.Data.PlayerLevel end
                            end
                        end
                        local bestDungeon = "Bandits Den"
                        local bestDiff = "Easy"
                        local order = {"Bandits Den", "Goblins", "Knights", "Catacombs", "Snow", "Demon", "Mage"}
                        local diffOrder = {"Easy", "Normal", "Hard", "Nightmare"}
                        for _, d in ipairs(order) do
                            local bestForThis = nil
                            pcall(function()
                                local dd = require(game.ReplicatedStorage.GameInfo.DungeonData)
                                local info = dd.GetDungeon(d)
                                if not info then return end
                                -- เช็คปลดล็อค RequiresClear ก่อน (ใช้ Data จริง)
                                local dataForCheck = nil
                                local okCan, can = pcall(function()
                                    local KnitTmp = require(game.ReplicatedStorage.Packages.Knit)
                                    local reg = KnitTmp.Registry:Get("PlayerData")
                                    local data = reg and reg.Data or {PlayerLevel = lvl}
                                    dataForCheck = data
                                    return dd.CanEnter({Data = data}, d)
                                end)
                                if okCan and can ~= true then return end
                                -- หา difficulty สูงสุดที่เวลถึง + เคลียร์ระดับก่อนหน้าแล้ว (เช่น Demon Nightmare ต้องผ่าน Hard ก่อน)
                                local clearsForDungeon = dataForCheck and dataForCheck.DungeonModeClears and dataForCheck.DungeonModeClears[d] or {}
                                local function isDiffUnlocked(diff)
                                    if diff == "Easy" then return true end
                                    if diff == "Normal" then return clearsForDungeon["Easy"] == true end
                                    if diff == "Hard" then return clearsForDungeon["Normal"] == true end
                                    if diff == "Nightmare" then return clearsForDungeon["Hard"] == true end
                                    return false
                                end
                                for _, diff in ipairs(diffOrder) do
                                    local bracket = info.DifficultyLevelBrackets and info.DifficultyLevelBrackets[diff]
                                    local req = bracket and bracket.Min or (diff == "Nightmare" and info.MinLevel or 0)
                                    local levelOk = false
                                    if bracket and lvl >= req then levelOk = true
                                    elseif not bracket and diff == "Easy" and lvl >= (info.MinLevel or 0) then levelOk = true end
                                    if levelOk and isDiffUnlocked(diff) then
                                        bestForThis = diff
                                    end
                                end
                            end)
                            if bestForThis then
                                bestDungeon = d
                                bestDiff = bestForThis
                            end
                        end
                        IsCreatingBestDungeon = true
                        task.spawn(function()
                            -- ใช้ UI flow เดียวกับ Auto Create Dungeon ปกติ (เลือก Dungeon + Difficulty ผ่าน UI) แทน headless service
                            simulateUICreate(bestDungeon, bestDiff)
                            task.wait(2)
                            IsCreatingBestDungeon = false
                        end)
                        task.wait(3)
                    else
                        task.wait(1.5)
                    end
                end
            end)
        end
    end)

    Tabs.Dungeon:AddSection("Challenger")
    Tabs.Dungeon:AddDropdown("SelectedChallengerBoss", {
        Title = "Select Boss",
        Values = {"Frigid Monarch", "Scarlet Knight, The Crimson Revenant", "Imperator, The Sovereign of Ruin", "Shadow Knight", "Unrestricted EX", "Awakened Devil"},
        Multi = false,
        Default = 2,
    }):OnChanged(function(v) Config.SelectedChallengerBoss = v end)

    Tabs.Dungeon:AddToggle("AutoCreateChallenger", { Title = "Auto Create Challenger", Default = false }):OnChanged(function()
        Config.AutoCreateChallenger = Options.AutoCreateChallenger.Value
        if Config.AutoCreateChallenger then
            task.spawn(function()
                while Config.AutoCreateChallenger do
                    if Fluent.Unloaded then break end
                    if LP:GetAttribute("InDungeon") == false and not getGeneratedDungeon() then
                        local ok, Knit = pcall(function() return require(ReplicatedStorage.Packages.Knit) end)
                        local Ctl = ok and Knit and pcall(function() return Knit.GetController("ChallengeDungeonController") end) and Knit.GetController("ChallengeDungeonController") or nil
                        -- Teleport to challenger pod first
                        do
                            local hrp = getHRP()
                            if hrp then
                                local podsFolder = workspace:FindFirstChild("pods_challenge")
                                local targetPos=nil
                                local bestDist=math.huge
                                if podsFolder then
                                    for _,v in ipairs(podsFolder:GetChildren()) do
                                        if v.Name=="Pod_Zone" and v:IsA("Model") then
                                            local bill=v:FindFirstChild("GuiAttachment", true)
                                            if bill then bill=bill:FindFirstChild("BillboardGui", true) end
                                            local cntLabel=bill and bill:FindFirstChild("PlayerCount")
                                            local cnt=cntLabel and tonumber(cntLabel.Text:match("(%d+)/"))
                                            if cnt and cnt >= 1 then continue end
                                            local ok2,pos=pcall(function() return v:GetPivot().Position end)
                                            if ok2 and pos then
                                                local d=(pos-hrp.Position).Magnitude
                                                if d < bestDist then bestDist=d targetPos=pos end
                                            end
                                        end
                                    end
                                end
                                if targetPos then
                                    local dist=(targetPos-hrp.Position).Magnitude
                                    if dist >= 30 and tick()-lastChallengePodTeleport >= 4 then
                                        hrp.CFrame=CFrame.new(targetPos+Vector3.new(0,5,0))
                                        hrp.AssemblyLinearVelocity=Vector3.zero
                                        lastChallengePodTeleport=tick()
                                        task.wait(0.25)
                                    end
                                end
                            end
                        end
                        if Ctl and not Ctl:IsOpen() then
                            pcall(function() Ctl:Open() end)
                            task.wait(0.5)
                        end
                        local pg2 = LP:FindFirstChild("PlayerGui")
                        -- Select Boss
                        do
                            local targetBoss = Config.SelectedChallengerBoss or "Scarlet Knight, The Crimson Revenant"
                            local t0=tick()
                            while tick()-t0 < 4 do
                                local curBoss=""
                                pcall(function()
                                    local display = pg2.Main.Frames.ChallengeDungeon.Content.LeftFrame:FindFirstChild("Display")
                                    if display then
                                        local bossLabel = display:FindFirstChild("BossName")
                                        if bossLabel then curBoss=bossLabel.Text or "" end
                                    end
                                end)
                                local firstWord = targetBoss:match("^(%a+)") or targetBoss:sub(1,5)
                                if curBoss:find(firstWord) then break end
                                local fwd = pg2.Main.Frames.ChallengeDungeon.Content.LeftFrame:FindFirstChild("CycleForward")
                                if fwd then for _,cn in ipairs(getconnections(fwd.Activated)) do pcall(function() cn:Fire() end) end end
                                task.wait(0.25)
                            end
                        end
                        local enter = pg2 and pg2:FindFirstChild("Main") and pg2.Main:FindFirstChild("Frames") and pg2.Main.Frames:FindFirstChild("ChallengeDungeon") and pg2.Main.Frames.ChallengeDungeon:FindFirstChild("Content") and pg2.Main.Frames.ChallengeDungeon.Content:FindFirstChild("Buttons") and pg2.Main.Frames.ChallengeDungeon.Content.Buttons:FindFirstChild("Enter")
                        if enter and enter.Visible then
                            for _,cn in ipairs(getconnections(enter.Activated)) do pcall(function() cn:Fire() end) end
                            task.wait(0.5)
                            local startBtn = pg2.Main.HUD:FindFirstChild("Dungeon_Container") and pg2.Main.HUD.Dungeon_Container:FindFirstChild("Start")
                            if startBtn and startBtn.Visible then
                                for _,cn in ipairs(getconnections(startBtn.Activated)) do pcall(function() cn:Fire() end) end
                            end
                        end
                        task.wait(4)
                    else
                        task.wait(1.5)
                    end
                end
            end)
        end
    end)

    -- Boss Rush Auto Create [แยกอิสระ ไม่ยุ่ง Dungeon/Challenger]
    Tabs.Dungeon:AddSection("Boss Rush")

    local function simulateBossRushCreate(bossName, skipFloor)
        if IsCreatingBossRush then return end
        IsCreatingBossRush = true
        task.spawn(function()
            local ok, Knit = pcall(function() return require(ReplicatedStorage.Packages.Knit) end)
            local Ctl = nil
            pcall(function() Ctl = Knit.GetController("BossRushSelectController") end)
            local svc = nil
            pcall(function() svc = Knit.GetService("BossRushService") end)
            local pg = LP:FindFirstChild("PlayerGui")
            if not pg then IsCreatingBossRush = false return end
            if LP:GetAttribute("InDungeon") or LP:GetAttribute("InChallenge") or LP:GetAttribute("InBossRush") then
                IsCreatingBossRush = false
                return
            end
            if getGeneratedDungeon() then
                IsCreatingBossRush = false
                return
            end
            do
                local hrp = getHRP()
                if hrp then
                    local promptPart = workspace:FindFirstChild("Prompts") and workspace.Prompts:FindFirstChild("BossRush")
                    local targetPos = nil
                    if promptPart and promptPart:IsA("BasePart") then
                        targetPos = promptPart.Position
                    else
                        local area = workspace:FindFirstChild("Areas") and workspace.Areas:FindFirstChild("Areas_Model") and workspace.Areas.Areas_Model:FindFirstChild("BossRush")
                        if area and area:IsA("BasePart") then targetPos = area.Position end
                    end
                    if targetPos then
                        local dist = (targetPos - hrp.Position).Magnitude
                        if dist >= 25 and tick() - lastBossRushPodTeleport >= 4 then
                            hrp.CFrame = CFrame.new(targetPos + Vector3.new(0,5,0))
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            lastBossRushPodTeleport = tick()
                            task.wait(0.3)
                        end
                    end
                end
            end
            if Ctl and not Ctl:IsOpen() then
                pcall(function() Ctl:Open() end)
                task.wait(0.6)
            end
            local bossRushFrame = pg:FindFirstChild("Main") and pg.Main:FindFirstChild("Frames") and pg.Main.Frames:FindFirstChild("BossRush")
            if not bossRushFrame or not bossRushFrame.Visible then
                pcall(function() if Ctl then Ctl:Open() end end)
                task.wait(0.5)
                bossRushFrame = pg.Main.Frames:FindFirstChild("BossRush")
            end
            if not bossRushFrame or not bossRushFrame.Visible then
                IsCreatingBossRush = false
                return
            end
            do
                local targetBoss = bossName or Config.SelectedBossRushBoss or "Cursed King"
                pcall(function()
                    local DQS = Knit.GetService("DungeonQueueService")
                    DQS:RequestSelectFinalBoss(targetBoss):await()
                end)
                if svc and svc.SelectFinalBoss then
                    pcall(function() svc:SelectFinalBoss(targetBoss) end)
                    task.wait(0.05)
                    pcall(function() svc:RequestSelectFinalBoss(targetBoss) end)
                    task.wait(0.05)
                end
                local t0 = tick()
                while tick() - t0 < 4 do
                    local curBoss = ""
                    pcall(function()
                        local display = bossRushFrame.Content.LeftFrame:FindFirstChild("Display")
                        if display then
                            local lbl = display:FindFirstChild("BossName")
                            if lbl then curBoss = lbl.Text or "" end
                        end
                    end)
                    local firstWord = targetBoss:match("^(%a+)") or targetBoss:sub(1,4)
                    if curBoss:find(firstWord) then break end
                    local fwd = bossRushFrame.Content.LeftFrame:FindFirstChild("CycleForward")
                    if fwd then for _,cn in ipairs(getconnections(fwd.Activated)) do pcall(function() cn:Fire() end) end end
                    task.wait(0.25)
                end
                pcall(function()
                    local DQS = Knit.GetService("DungeonQueueService")
                    DQS:RequestSelectFinalBoss(targetBoss):await()
                end)
                if svc and svc.SelectFinalBoss then
                    pcall(function() svc:SelectFinalBoss(targetBoss) end)
                end
                if Ctl and Ctl.RequestSelectFinalBoss then
                    pcall(function() Ctl:RequestSelectFinalBoss(targetBoss) end)
                end
                task.wait(0.3)
            end
            do
                local skip = skipFloor
                if skip == nil then skip = Config.SelectedBossRushSkipFloor or 0 end
                skip = math.floor(skip)
                if skip ~= 0 and skip % 10 ~= 0 then skip = math.floor(skip/10)*10 end
                if skip < 0 then skip = 0 end
                if skip > 50 then skip = 50 end
                pcall(function()
                    local DQS = Knit.GetService("DungeonQueueService")
                    DQS:RequestSelectSkipFloor(skip):await()
                end)
                pcall(function()
                    if svc and svc.SelectSkipFloor then svc:SelectSkipFloor(skip) end
                end)
                local skipToggle = bossRushFrame.Content.LeftFrame:FindFirstChild("SkipToggle")
                local skipEnabled = skip > 0
                local curSkip = -1
                pcall(function()
                    local lbl = bossRushFrame.Content.LeftFrame:FindFirstChild("Skip") and bossRushFrame.Content.LeftFrame.Skip:FindFirstChild("Skip_Floor")
                    if not lbl then lbl = bossRushFrame.Content.LeftFrame:FindFirstChild("Skip_Floor") end
                    if lbl and lbl.Text then curSkip = tonumber(lbl.Text:match("%d+")) or -1 end
                end)
                if skipToggle and ((skipEnabled and curSkip ~= skip) or (not skipEnabled and curSkip ~= -1 and curSkip ~= 0)) then
                    pcall(function() clickButton(skipToggle) end)
                    task.wait(0.2)
                    if skipEnabled then
                        local t0 = tick()
                        while tick() - t0 < 3 do
                            local cur = -1
                            pcall(function()
                                local l = bossRushFrame.Content.LeftFrame:FindFirstChild("Skip") and bossRushFrame.Content.LeftFrame.Skip:FindFirstChild("Skip_Floor")
                                if l and l.Text then cur = tonumber(l.Text:match("%d+")) or -1 end
                            end)
                            if cur == skip then break end
                            local cyc = bossRushFrame.Content.LeftFrame:FindFirstChild("Skip") and bossRushFrame.Content.LeftFrame.Skip:FindFirstChild("ImageButton")
                            if cyc then clickButton(cyc) end
                            pcall(function()
                                local DQS = Knit.GetService("DungeonQueueService")
                                DQS:RequestSelectSkipFloor(skip):await()
                            end)
                            task.wait(0.25)
                        end
                    end
                end
                task.wait(0.2)
            end
            local enterBtn = bossRushFrame.Content:FindFirstChild("Buttons") and bossRushFrame.Content.Buttons:FindFirstChild("Enter")
            if not enterBtn then enterBtn = bossRushFrame:FindFirstChild("Enter", true) end
            if enterBtn and enterBtn.Visible then
                clickButton(enterBtn)
                task.wait(0.3)
                pcall(function()
                    local DQS = Knit.GetService("DungeonQueueService")
                    DQS:RequestEnter():await()
                end)
                task.wait(0.3)
                local startBtn = pg.Main.HUD:FindFirstChild("Dungeon_Container") and pg.Main.HUD.Dungeon_Container:FindFirstChild("Start")
                if startBtn and startBtn.Visible then
                    clickButton(startBtn)
                    pcall(function()
                        local DQS2 = Knit.GetService("DungeonQueueService")
                        DQS2:RequestStartNow():await()
                    end)
                end
                task.wait(0.2)
                if not LP:GetAttribute("InBossRush") and not getGeneratedDungeon() then
                    pcall(function()
                        local DQS = Knit.GetService("DungeonQueueService")
                        DQS:RequestEnter():await()
                    end)
                end
            else
                pcall(function()
                    local DQS = Knit.GetService("DungeonQueueService")
                    DQS:RequestEnter():await()
                end)
            end
            IsCreatingBossRush = false
        end)
        task.delay(5, function() IsCreatingBossRush = false end)
    end

    Tabs.Dungeon:AddDropdown("SelectedBossRushBoss", {
        Title = "Select Boss (Boss Rush)",
        Values = {"Cursed King", "Satori", "Anti Mage", "Great Mage"},
        Multi = false,
        Default = 1,
    }):OnChanged(function(v) Config.SelectedBossRushBoss = v end)

    Tabs.Dungeon:AddSlider("SelectedBossRushSkipFloor", {
        Title = "Skip Floor (0=No Skip)",
        Default = 0,
        Min = 0,
        Max = 50,
        Rounding = 0,
        Callback = function(v)
            local val = math.floor(v)
            if val ~= 0 and val % 10 ~= 0 then val = math.floor(val/10)*10 end
            if val < 0 then val = 0 end
            if val > 50 then val = 50 end
            Config.SelectedBossRushSkipFloor = val
        end
    })

    Tabs.Dungeon:AddToggle("AutoCreateBossRush", { Title = "Auto Create Boss Rush", Default = false }):OnChanged(function()
        Config.AutoCreateBossRush = Options.AutoCreateBossRush.Value
        if Config.AutoCreateBossRush then
            task.spawn(function()
                while Config.AutoCreateBossRush do
                    if Fluent.Unloaded then break end
                    if not LP:GetAttribute("InDungeon") and not LP:GetAttribute("InChallenge") and not LP:GetAttribute("InBossRush") and not getGeneratedDungeon() then
                        local ok, Knit = pcall(function() return require(ReplicatedStorage.Packages.Knit) end)
                        local Ctl = ok and Knit and pcall(function() return Knit.GetController("BossRushSelectController") end) and Knit.GetController("BossRushSelectController") or nil
                        if Ctl and pcall(function() return Ctl:IsOpen() end) and Ctl:IsOpen() then
                            task.wait(1.5)
                        elseif not IsCreatingBossRush then
                            simulateBossRushCreate(Config.SelectedBossRushBoss, Config.SelectedBossRushSkipFloor)
                            task.wait(4)
                        else
                            task.wait(1)
                        end
                    else
                        task.wait(1.5)
                    end
                end
            end)
        end
    end)

    Tabs.Dungeon:AddButton({ Title = "Create Boss Rush Now", Callback = function()
        simulateBossRushCreate(Config.SelectedBossRushBoss, Config.SelectedBossRushSkipFloor)
    end})
end

-- Lobby Tab: Stats Auto Up [แยกอิสระ]
do
    Tabs.Lobby:AddSection("Stats")

    Tabs.Lobby:AddToggle("AutoUpStats", { Title = "Auto Up Stats", Default = false }):OnChanged(function()
        Config.AutoUpStats = Options.AutoUpStats.Value
    end)

    Tabs.Lobby:AddDropdown("UpStatsMode", {
        Title = "Mode",
        Values = {"Recommend", "Manual"},
        Multi = false,
        Default = 1,
    }):OnChanged(function(v) Config.UpStatsMode = v end)

    Tabs.Lobby:AddDropdown("UpStatsTarget", {
        Title = "Target Stat (Manual)",
        Values = {"STR", "DEX", "INT", "VIT", "LCK"},
        Multi = false,
        Default = 2,
    }):OnChanged(function(v) Config.UpStatsTarget = v end)

    Tabs.Lobby:AddSlider("UpStatsAmount", {
        Title = "Amount per Tick",
        Default = 1,
        Min = 1,
        Max = 10,
        Rounding = 0,
        Callback = function(v) Config.UpStatsAmount = math.floor(v) end
    })

    -- Auto Up Stats Loop [แยกอิสระ ไม่ยุ่ง Auto Farm]
    task.spawn(function()
        local lastNotify = 0
        while true do
            task.wait(0.6)
            if Fluent.Unloaded then continue end
            if not Config.AutoUpStats then continue end
            local okKnit, Knit = pcall(function() return require(ReplicatedStorage.Packages.Knit) end)
            if not okKnit or not Knit then continue end
            local okCtl, StatController = pcall(function() return Knit.GetController("StatController") end)
            if not okCtl or not StatController then continue end
            local okPts, pts, unspent = pcall(function() return StatController:GetSkillPoints() end)
            if not okPts then continue end
            -- GetSkillPoints returns SkillPoints table and unspent number
            if not unspent or unspent <= 0 then
                if pts and type(pts)=="table" then
                    -- fallback if unspent is actually table
                    local ok2, s, u = pcall(function() return StatController:GetSkillPoints() end)
                    if s and type(s)=="table" and type(u)=="number" then unspent = u end
                end
                if not unspent or unspent <= 0 then continue end
            end
            local target = Config.UpStatsTarget or "DEX"
            if Config.UpStatsMode == "Recommend" then
                local okP, PlayerData = pcall(function() return require(ReplicatedStorage.Classes.Class_Data) end)
                local okR, Registry = pcall(function() return Knit.Registry:Get("PlayerData") end)
                if okR and Registry and Registry.Data then
                    local active = Registry.Data.ActiveClass or ""
                    local classInfo = nil
                    pcall(function() classInfo = require(ReplicatedStorage.Classes.Class_Data).Get(active) end)
                    if classInfo and classInfo.DamageType then
                        local map = {Physical="STR", Ranged="DEX", Magic="INT"}
                        local rec = map[classInfo.DamageType]
                        if rec then target = rec end
                    end
                end
            end
            local amount = math.clamp(Config.UpStatsAmount or 1, 1, 10)
            if amount > unspent then amount = unspent end
            if amount <= 0 then continue end
            local okA, s, r, applied = pcall(function() return StatController:AllocatePoints(target, amount) end)
            if okA and s then
                -- สำเร็จ
                if tick() - lastNotify > 2 then
                    lastNotify = tick()
                end
            else
                -- ลอง AllocatePoint ทีละแต้ม fallback
                if amount == 1 then
                    pcall(function() StatController:AllocatePoint(target) end)
                end
                task.wait(0.3)
            end
            task.wait(0.2)
        end
    end)

    Tabs.Lobby:AddSection("Equip Best")

    Tabs.Lobby:AddToggle("AutoEquipBest", { Title = "Auto Equip Best", Default = false }):OnChanged(function()
        Config.AutoEquipBest = Options.AutoEquipBest.Value
    end)

    -- Auto Equip Best Loop [แยกอิสระ ใช้ Inventory:OnEquipBestClicked โดยตรง]
    task.spawn(function()
        local lastEquip = 0
        local needCheck = false
        pcall(function()
            local Knit = require(ReplicatedStorage.Packages.Knit)
            local Registry = Knit.Registry:Get("PlayerData")
            if Registry then
                Registry:OnChange(function(_, path)
                    local k = path[1]
                    if k == "EquipmentInventory" or k == "Equipment" or k == "PlayerLevel" then
                        needCheck = true
                    end
                end)
            end
        end)
        while true do
            task.wait(0.7)
            if Fluent.Unloaded then continue end
            if not Config.AutoEquipBest then
                needCheck = false
                continue
            end
            local should = false
            if needCheck then
                should = true
                needCheck = false
            else
                local interval = Config.EquipBestInterval or 1
                if tick() - lastEquip >= interval then
                    should = true
                end
            end
            if not should then continue end
            local okInv, Inv = pcall(function() return require(LP.PlayerScripts.Client.UI.Inventory) end)
            if okInv and Inv and Inv.OnEquipBestClicked then
                local ok3 = pcall(function() Inv.OnEquipBestClicked() end)
                if ok3 then lastEquip = tick() end
            end
            task.wait(0.5)
        end
    end)
end

-- Shop Tab: Buy Shop Auto Buy [แยกอิสระ ไม่ยุ่งส่วนอื่น]
do
    Tabs.Shop:AddSection("Buy Shop")

    Tabs.Shop:AddToggle("AutoBuy", { Title = "Auto Buy", Default = false }):OnChanged(function()
        Config.AutoBuy = Options.AutoBuy.Value
    end)

    Tabs.Shop:AddDropdown("BuyRarities", {
        Title = "Rarities",
        Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Celestial"},
        Multi = true,
        Default = {"Rare", "Epic", "Legendary"},
    }):OnChanged(function(v)
        local tbl = {}
        if type(v) == "table" then
            for k,val in pairs(v) do
                if type(k)=="number" and type(val)=="string" then tbl[val]=true
                elseif val==true then tbl[k]=true end
            end
        end
        if next(tbl) then Config.BuyRarities = tbl end
    end)

    -- Auto Buy Loop [headless ไม่เปิด Shop UI]
    task.spawn(function()
        local lastBuy = 0
        while true do
            task.wait(1)
            if Fluent.Unloaded then continue end
            if not Config.AutoBuy then continue end
            local interval = Config.BuyInterval or 2
            if tick() - lastBuy < interval then continue end
            local okKnit, Knit = pcall(function() return require(ReplicatedStorage.Packages.Knit) end)
            if not okKnit or not Knit then continue end
            local okSvc, ShopService = pcall(function() return Knit.GetService("ShopService") end)
            if not okSvc or not ShopService then continue end
            local okData, PlayerData = pcall(function() return Knit.Registry:Get("PlayerData") end)
            local playerLevel = 1
            if okData and PlayerData and PlayerData.Data then
                playerLevel = PlayerData.Data.PlayerLevel or 1
                local maxSlots = PlayerData.Data.MaxInventorySlots or 999
                local invCount = 0
                if PlayerData.Data.EquipmentInventory then
                    for _ in pairs(PlayerData.Data.EquipmentInventory) do invCount = invCount + 1 end
                end
                if invCount >= maxSlots then continue end
            end
            local okInfo, succ, shopInfo = pcall(function() return ShopService:GetEquipmentShopInfo():await() end)
            local info = nil
            if okInfo and succ == true and type(shopInfo)=="table" then info = shopInfo
            elseif okInfo and type(succ)=="table" then info = succ
            end
            if not info or #info==0 then continue end
            local rarities = Config.BuyRarities or {["Rare"]=true, ["Epic"]=true, ["Legendary"]=true}
            for _, item in ipairs(info) do
                if not Config.AutoBuy then break end
                if item.Locked then continue end
                if item.LevelReq and playerLevel < item.LevelReq then continue end
                if not rarities[item.Rarity] then continue end
                local okBuy, a, b = pcall(function() return ShopService:BuyEquipment(item.GUID):await() end)
                if okBuy and a then
                    lastBuy = tick()
                    task.wait(0.4)
                end
            end
            lastBuy = tick()
        end
    end)

    Tabs.Shop:AddSection("Sell Shop")

    Tabs.Shop:AddToggle("AutoSell", { Title = "Auto Sell", Default = false }):OnChanged(function()
        Config.AutoSell = Options.AutoSell.Value
    end)

    Tabs.Shop:AddDropdown("SellRarities", {
        Title = "Rarities to Sell",
        Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Celestial"},
        Multi = true,
        Default = {"Common", "Uncommon"},
    }):OnChanged(function(v)
        local tbl = {}
        if type(v)=="table" then
            for k,val in pairs(v) do
                if type(k)=="number" and type(val)=="string" then tbl[val]=true
                elseif val==true then tbl[k]=true end
            end
        end
        if next(tbl) then Config.SellRarities = tbl end
    end)

    -- Auto Sell Loop headless ไม่เปิด Shop UI
    task.spawn(function()
        local lastSell = 0
        while true do
            task.wait(1)
            if Fluent.Unloaded then continue end
            if not Config.AutoSell then continue end
            if tick() - lastSell < (Config.SellInterval or 2) then continue end
            local okKnit, Knit = pcall(function() return require(ReplicatedStorage.Packages.Knit) end)
            if not okKnit or not Knit then continue end
            local okSvc, ShopService = pcall(function() return Knit.GetService("ShopService") end)
            if not okSvc or not ShopService then continue end
            local okReg, Registry = pcall(function() return Knit.Registry:Get("PlayerData") end)
            if not okReg or not Registry or not Registry.Data or not Registry.Data.EquipmentInventory then continue end
            local rarities = Config.SellRarities or {["Common"]=true, ["Uncommon"]=true}
            local toSell = {}
            local EquipmentInventory = Registry.Data.EquipmentInventory
            local Equipment = Registry.Data.Equipment or {}
            local function isEquipped(guid)
                for _, slot in pairs({"Head","Body","Ring"}) do
                    local eq = Equipment[slot]
                    if eq and eq.GUID == guid then return true end
                end
                return false
            end
            for _, item in pairs(EquipmentInventory) do
                if type(item)=="table" and item.GUID and not item.Locked and not isEquipped(item.GUID) then
                    local tmpl = nil
                    pcall(function() tmpl = require(ReplicatedStorage.GameInfo.EquipmentTemplates).GetTemplate(item.ItemId) end)
                    if tmpl and tmpl.Unsellable then continue end
                    if not rarities[item.Rarity] then continue end
                    table.insert(toSell, item.GUID)
                    if #toSell >= 10 then break end
                end
            end
            if #toSell == 0 then continue end
            local okSell, a, b = pcall(function() return ShopService:SellEquipment(toSell):await() end)
            if okSell and a then
                lastSell = tick()
                task.wait(0.5)
            end
        end
    end)
end

-- Boss Raid Tab: Auto Boss Raid [แยกอิสระ ไม่ยุ่ง Auto Farm เดิม]
do
    function getRaidArena()
        return workspace:FindFirstChild("Raid_NPCs") or workspace:FindFirstChild("Raid") or workspace:FindFirstChild("NPCs") or workspace:FindFirstChild("Enemy Models")
    end

    function getEnemiesInRaid()
        if not LP:GetAttribute("InRaid") then return {} end
        local arena = getRaidArena()
        local list = {}
        if arena then
            for _, obj in ipairs(arena:GetDescendants()) do
                if obj:IsA("Model") and isEnemyAlive(obj) then
                    table.insert(list, obj)
                end
            end
            if #list > 0 then return list end
            local ok, pivot = pcall(function() return arena:GetPivot().Position end)
            if ok and pivot then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") and isEnemyAlive(obj) then
                        local pos = getModelPivotPos(obj)
                        if pos and (pos - pivot).Magnitude < 600 then
                            table.insert(list, obj)
                        end
                    end
                end
                if #list > 0 then return list end
            end
        end
        local hrp = getHRP()
        if not hrp then return list end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and isEnemyAlive(obj) then
                local pos = getModelPivotPos(obj)
                if pos and (pos - hrp.Position).Magnitude < 600 then
                    table.insert(list, obj)
                end
            end
        end
        -- fallback สุดท้าย หา Dark Professor โดยตรง
        if #list == 0 then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and (obj.Name == "Dark Professor" or obj:GetAttribute("BossId")) and isEnemyAlive(obj) then
                    table.insert(list, obj)
                end
            end
        end
        return list
    end

    function getNearestInRaid()
        local hrp = getHRP()
        if not hrp then return nil end
        local mobs = getEnemiesInRaid()
        local nearest, best = nil, math.huge
        for _, mob in ipairs(mobs) do
            local pos = getModelPivotPos(mob)
            if pos then
                local d = (pos - hrp.Position).Magnitude
                if d < best then best = d nearest = mob end
            end
        end
        return nearest
    end

    function getRaidAdds()
        local list = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LP.Character and not Players:GetPlayerFromCharacter(obj) then
                if obj.Name == "Dark Professor" or obj:GetAttribute("BossId") then continue end
                local isAdd = false
                if obj:FindFirstChild("ATTACK", true) then isAdd = true end
                if obj.Name:lower():find("pillar") or obj.Name:lower():find("totem") or obj.Name:lower():find("add") then isAdd = true end
                if obj:GetAttribute("IsAdd") or obj:GetAttribute("IsMinion") then isAdd = true end
                if isEnemyAlive(obj) and (obj:GetAttribute("Level") or obj:FindFirstChild("EntityHighlight", true)) then isAdd = true end
                if isAdd and isEnemyAlive(obj) then
                    table.insert(list, obj)
                elseif isAdd then
                    local ho = obj:GetAttribute("HealthOverride") or obj:GetAttribute("Health")
                    if ho and ho > 0 then
                        table.insert(list, obj)
                    elseif obj:FindFirstChild("EntityHighlight", true) then
                        table.insert(list, obj)
                    end
                end
            end
        end
        return list
    end

    function getNearestRaidAdd()
        local hrp = getHRP()
        if not hrp then return nil end
        local adds = getRaidAdds()
        local nearest, best = nil, math.huge
        for _, mob in ipairs(adds) do
            local pos = getModelPivotPos(mob)
            if pos then
                local d = (pos - hrp.Position).Magnitude
                if d < best then best = d nearest = mob end
            end
        end
        return nearest
    end

    local function startRaidFarm()
        if IsRaidFarming then return end
        IsRaidFarming = true
        task.spawn(function()
            while Config.AutoBossRaid do
                if Fluent.Unloaded then break end
                if not LP:GetAttribute("InRaid") then task.wait(0.7) continue end
                if not getHRP() then task.wait(0.5) continue end
                if CurrentRaidTarget and not isEnemyAlive(CurrentRaidTarget) then CurrentRaidTarget = nil disableLock() end
                local adds = getRaidAdds()
                if #adds > 0 then
                    local target = getNearestRaidAdd()
                    if target and isEnemyAlive(target) then
                        if CurrentRaidTarget ~= target then
                            if CurrentRaidTarget ~= nil then tweenTo(target) else teleportTo(target) end
                            CurrentRaidTarget = target
                        else
                            enableLock(target)
                        end
                        while Config.AutoBossRaid and IsRaidFarming and target and isEnemyAlive(target) and LP:GetAttribute("InRaid") and getHRP() do
                            local stillAdd = false
                            for _, a in ipairs(getRaidAdds()) do if a == target then stillAdd = true break end end
                            if not stillAdd and target.Name ~= "Dark Professor" and not target:GetAttribute("BossId") then break end
                            pcall(function() AttackRemote:FireServer(target) end)
                            task.wait(Config.AttackDelay)
                            if not isEnemyAlive(target) then break end
                            if not getHRP() then break end
                        end
                        disableLock()
                        CurrentRaidTarget = nil
                        task.wait(0.2)
                        continue
                    end
                end
                local mobs = getEnemiesInRaid()
                if #mobs == 0 then task.wait(0.5) continue end
                local target = getNearestInRaid()
                if not target or not isEnemyAlive(target) then task.wait(0.3) continue end
                if CurrentRaidTarget ~= target then
                    if CurrentRaidTarget ~= nil then tweenTo(target) else teleportTo(target) end
                    CurrentRaidTarget = target
                else
                    enableLock(target)
                end
                while Config.AutoBossRaid and IsRaidFarming and target and isEnemyAlive(target) and LP:GetAttribute("InRaid") and getHRP() do
                    if #getRaidAdds() > 0 and target.Name == "Dark Professor" then break end
                    pcall(function() AttackRemote:FireServer(target) end)
                    task.wait(Config.AttackDelay)
                    if not isEnemyAlive(target) then break end
                    if not getHRP() then break end
                end
                disableLock()
                CurrentRaidTarget = nil
                task.wait(0.2)
            end
            IsRaidFarming = false
            disableLock()
            CurrentRaidTarget = nil
        end)
    end

    local function stopRaidFarm()
        IsRaidFarming = false
        disableLock()
        CurrentRaidTarget = nil
    end

    Tabs.BossRaid:AddSection("Boss Raid")

    Tabs.BossRaid:AddToggle("AutoBossRaid", { Title = "Auto Boss Raid", Default = false }):OnChanged(function()
        Config.AutoBossRaid = Options.AutoBossRaid.Value
        if Config.AutoBossRaid then
            CurrentRaidTarget = nil
            startRaidFarm()
        else
            stopRaidFarm()
        end
    end)

    Tabs.BossRaid:AddSection("Create")

    Tabs.BossRaid:AddDropdown("SelectedRaid", {
        Title = "Select Raid",
        Values = {"The First Test"},
        Multi = false,
        Default = 1,
    }):OnChanged(function(v) Config.SelectedRaid = v end)

    Tabs.BossRaid:AddDropdown("SelectedRaidDifficulty", {
        Title = "Select Difficulty",
        Values = {"Normal", "Extreme", "Impossible"},
        Multi = false,
        Default = 1,
    }):OnChanged(function(v) Config.SelectedRaidDifficulty = v end)

    local function simulateRaidCreate(raid, diff)
        if IsCreatingRaid then return end
        IsCreatingRaid = true
        task.spawn(function()
            local ok, Knit = pcall(function() return require(ReplicatedStorage.Packages.Knit) end)
            local Ctl = nil
            pcall(function() Ctl = Knit.GetController("RaidSelectController") end)
            local pg = LP:FindFirstChild("PlayerGui")
            if not pg then IsCreatingRaid = false return end
            if LP:GetAttribute("InDungeon") or LP:GetAttribute("InChallenge") or LP:GetAttribute("InBossRush") or LP:GetAttribute("InRaid") then
                IsCreatingRaid = false
                return
            end
            if getGeneratedDungeon() then
                IsCreatingRaid = false
                return
            end
            do
                local hrp = getHRP()
                if hrp then
                    local promptPart = workspace:FindFirstChild("Prompts") and workspace.Prompts:FindFirstChild("Raid")
                    local targetPos = nil
                    if promptPart and promptPart:IsA("BasePart") then
                        targetPos = promptPart.Position
                    else
                        local area = workspace:FindFirstChild("Areas") and workspace.Areas:FindFirstChild("Areas_Model") and workspace.Areas.Areas_Model:FindFirstChild("Raid")
                        if area and area:IsA("BasePart") then targetPos = area.Position end
                    end
                    if targetPos then
                        local dist = (targetPos - hrp.Position).Magnitude
                        if dist >= 25 and tick() - lastRaidPodTeleport >= 4 then
                            hrp.CFrame = CFrame.new(targetPos + Vector3.new(0,5,0))
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            lastRaidPodTeleport = tick()
                            task.wait(0.3)
                        end
                    end
                end
            end
            if Ctl and not Ctl:IsOpen() then
                pcall(function() Ctl:Open() end)
                task.wait(0.6)
            end
            local raidFrame = pg:FindFirstChild("Main") and pg.Main:FindFirstChild("Frames") and (pg.Main.Frames:FindFirstChild("Raid") or pg.Main.Frames:FindFirstChild("RaidSelect") or pg.Main.Frames:FindFirstChild("Raid_Select"))
            if not raidFrame or not raidFrame.Visible then
                pcall(function() if Ctl then Ctl:Open() end end)
                task.wait(0.5)
                raidFrame = pg.Main.Frames:FindFirstChild("Raid") or pg.Main.Frames:FindFirstChild("RaidSelect") or pg.Main.Frames:FindFirstChild("Raid_Select")
            end
            if not raidFrame or not raidFrame.Visible then
                IsCreatingRaid = false
                return
            end
            local raidToUse = raid or Config.SelectedRaid or "The First Test"
            local diffToUse = diff or Config.SelectedRaidDifficulty or "Normal"
            pcall(function()
                local DQS = Knit.GetService("DungeonQueueService")
                DQS:RequestSelectRaid(raidToUse):await()
            end)
            task.wait(0.2)
            pcall(function()
                local DQS = Knit.GetService("DungeonQueueService")
                DQS:RequestSelectRaidDifficulty(diffToUse):await()
            end)
            task.wait(0.3)
            local enterBtn = raidFrame:FindFirstChild("Enter", true) or (raidFrame:FindFirstChild("Content", true) and raidFrame.Content:FindFirstChild("Buttons", true) and raidFrame.Content.Buttons:FindFirstChild("Enter"))
            if not enterBtn then enterBtn = raidFrame:FindFirstChild("Buttons", true) and raidFrame:FindFirstChild("Buttons", true):FindFirstChild("Enter") end
            if enterBtn and enterBtn.Visible then
                for _, cn in ipairs(getconnections(enterBtn.Activated)) do pcall(function() cn:Fire() end) end
                for _, cn in ipairs(getconnections(enterBtn.MouseButton1Click)) do pcall(function() cn:Fire() end) end
                task.wait(0.5)
                pcall(function()
                    local svc = Knit.GetService("RaidService")
                    if svc and svc.Enter then svc:Enter():await() end
                    local dq = Knit.GetService("DungeonQueueService")
                    if dq and dq.RequestEnter then dq:RequestEnter():await() end
                end)
                task.wait(0.3)
                local startBtn = pg.Main.HUD:FindFirstChild("Dungeon_Container") and pg.Main.HUD.Dungeon_Container:FindFirstChild("Start")
                if startBtn and startBtn.Visible then
                    for _, cn in ipairs(getconnections(startBtn.Activated)) do pcall(function() cn:Fire() end) end
                    task.wait(0.2)
                    pcall(function()
                        local dq = Knit.GetService("DungeonQueueService")
                        if dq and dq.RequestStartNow then dq:RequestStartNow():await() end
                    end)
                end
            else
                pcall(function()
                    local svc = Knit.GetService("RaidService")
                    if svc and svc.Enter then svc:Enter():await() end
                end)
            end
            IsCreatingRaid = false
        end)
        task.delay(5, function() IsCreatingRaid = false end)
    end

    Tabs.BossRaid:AddToggle("AutoCreateRaid", { Title = "Auto Create Raid", Default = false }):OnChanged(function()
        Config.AutoCreateRaid = Options.AutoCreateRaid.Value
        if Config.AutoCreateRaid then
            task.spawn(function()
                while Config.AutoCreateRaid do
                    if Fluent.Unloaded then break end
                    if not LP:GetAttribute("InDungeon") and not LP:GetAttribute("InChallenge") and not LP:GetAttribute("InBossRush") and not LP:GetAttribute("InRaid") and not getGeneratedDungeon() then
                        if not IsCreatingRaid then
                            simulateRaidCreate(Config.SelectedRaid, Config.SelectedRaidDifficulty)
                            task.wait(4)
                        else
                            task.wait(1)
                        end
                    else
                        task.wait(1.5)
                    end
                end
            end)
        end
    end)

    Tabs.BossRaid:AddButton({ Title = "Create Raid Now", Callback = function()
        simulateRaidCreate(Config.SelectedRaid, Config.SelectedRaidDifficulty)
    end})
end

-- Dungeon creation removed per request
-- Collect Chests [Dungeon]: แยกอิสระจาก Challenger - ใช้ Generated_ + RoomIndex + CurrentRoom เท่านั้น
task.spawn(function()
    local function isLockRoomChest(chest)
        local ri = chest:GetAttribute("RoomIndex")
        if not ri then return false end
        local gen = getGeneratedDungeon()
        if not gen then return false end
        for _, r in ipairs(gen:GetChildren()) do
            if r.Name == "Room_"..ri then
                if r:GetAttribute("Locked") or (r:FindFirstChild("Door") and r.Door:GetAttribute("Locked")) then return true end
                if r:FindFirstChild("Spawns") and r.Spawns:FindFirstChild("Keyhole") then return true end
                for _,c in ipairs(r:GetChildren()) do if c.Name:find("Keyhole") then return true end end
                return false
            end
        end
        return false
    end
    local function shouldCollect(chest)
        return not isLockRoomChest(chest)
    end
    function getCollectableChests()
        local gen=getGeneratedDungeon()
        if not gen or not CurrentRoom then return {} end
        local curIdx=CurrentRoom.Name:match("%d+")
        local out={}
        for _,v in ipairs(gen:GetChildren()) do
            if v.Name:find("DungeonChest") then
                local chestIdx=tostring(v:GetAttribute("RoomIndex") or "")
                if chestIdx ~= curIdx then continue end
                local prompt=v:FindFirstChild("ChestPrompt", true)
                local enabled = prompt and prompt.Enabled
                if enabled == nil then enabled=true end
                local hasEffect=v:FindFirstChild("Chest_Effect", true)
                if enabled and hasEffect and shouldCollect(v) then
                    table.insert(out, v)
                end
            end
        end
        return out
    end
    while true do
        task.wait(0.6)
        if not Config.CollectChests or not Config.AutoFarm or Fluent.Unloaded then continue end
        if IsRefilling then continue end
        if not CurrentRoom or not CurrentRoom.Parent then continue end
        if CurrentTarget and isEnemyAlive(CurrentTarget) then continue end
        if #getEnemiesInRoom(CurrentRoom) > 0 then continue end
        local chests=getCollectableChests()
        if #chests==0 then continue end
        IsCollectingChest = true
        while true do
            chests=getCollectableChests()
            if #chests==0 then
                local gen=getGeneratedDungeon()
                local pending=false
                if gen and CurrentRoom then
                    local curIdx=CurrentRoom.Name:match("%d+")
                    for _,v in ipairs(gen:GetChildren()) do
                        if v.Name:find("DungeonChest") and tostring(v:GetAttribute("RoomIndex") or "")==curIdx then
                            local p=v:FindFirstChild("ChestPrompt", true)
                            if p and not p.Enabled and v:FindFirstChild("Chest_Effect", true) then pending=true break end
                        end
                    end
                end
                if pending then task.wait(0.3) chests=getCollectableChests() if #chests==0 then break end else break end
            end
            local hrp=getHRP()
            if not hrp then break end
            table.sort(chests, function(a,b) return (a:GetPivot().Position - hrp.Position).Magnitude < (b:GetPivot().Position - hrp.Position).Magnitude end)
            local chest=chests[1]
            local prompt=chest:FindFirstChild("ChestPrompt", true)
            local t0=tick()
            while prompt and not prompt.Enabled and tick()-t0 < 2 do task.wait(0.1) prompt=chest:FindFirstChild("ChestPrompt", true) end
            if prompt and not prompt.Enabled then break end
            local cpos=chest:GetPivot().Position
            local dest=CFrame.new(cpos + Vector3.new(0,8,0))
            local dist=(dest.Position - hrp.Position).Magnitude
            local t=math.clamp(dist / 80, 0.2, 2)
            local tw=TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = dest})
            tw:Play()
            tw.Completed:Wait()
            hrp.AssemblyLinearVelocity = Vector3.new(0, -10, 0)
            task.wait(0.5)
            if chest.Parent and chest:FindFirstChild("Chest_Effect", true) then
                task.wait(0.3)
            end
            task.wait(0.2)
            t0=tick()
            while chest.Parent and chest:FindFirstChild("Chest_Effect", true) and tick()-t0 < 1.5 do task.wait(0.1) end
            task.wait(0.15)
            if not Config.CollectChests or not Config.AutoFarm then break end
            if #getEnemiesInRoom(CurrentRoom) > 0 then break end
        end
        IsCollectingChest = false
    end
end)

-- Collect Chests [Challenger]: แยกอิสระจาก Dungeon - ใช้ Challenge_Dungeons เท่านั้น ไม่ใช้ Generated_/CurrentRoom
task.spawn(function()
    while true do
        task.wait(0.6)
        if not Config.CollectChallengerChests or not Config.AutoFarm or Fluent.Unloaded then continue end
        if IsCollectingChallengerChest then continue end
        -- Challenger: เก็บทันทีเมื่อกล่อง spawn ไม่รอเคลียร์มอน (ตาม request)
        -- ลบเช็ค CurrentTarget / #enemies ออกเพื่อไปเก็บเลยแล้วค่อยกลับมาฟาร์มต่อ
        -- ต้องอยู่ใน Challenger จริงๆ ถึงจะเก็บ
        if not getChallengeArena() then continue end
        local chests = getChallengerChests()
        -- กรองเฉพาะหีบ Challenger (อยู่ใน Challenge_NPCs) กันหลงไปเก็บหีบ Dungeon
        do
            local cnpcs = workspace:FindFirstChild("Challenge_NPCs")
            if cnpcs then
                local filtered = {}
                for _, chest in ipairs(chests) do
                    if chest:IsDescendantOf(cnpcs) then table.insert(filtered, chest) end
                end
                -- ถ้าไม่มี Challenge_NPCs ให้ใช้ทั้งหมด (fallback)
                if #filtered > 0 then chests = filtered end
            end
        end
        if #chests==0 then continue end
        IsCollectingChallengerChest = true
        while true do
            chests = getChallengerChests()
            do
                local cnpcs = workspace:FindFirstChild("Challenge_NPCs")
                if cnpcs then
                    local filtered = {}
                    for _, chest in ipairs(chests) do
                        if chest:IsDescendantOf(cnpcs) then table.insert(filtered, chest) end
                    end
                    if #filtered > 0 then chests = filtered end
                end
            end
            if #chests==0 then break end
            -- หยุดล็อคมอนชั่วคราวเพื่อไปเก็บหีบ (เก็บกลางไฟต์ได้)
            pcall(function() disableLock() end)
            local hrp=getHRP()
            if not hrp then break end
            table.sort(chests, function(a,b) return (a:GetPivot().Position - hrp.Position).Magnitude < (b:GetPivot().Position - hrp.Position).Magnitude end)
            local chest=chests[1]
            local prompt=chest:FindFirstChild("ChestPrompt", true) or chest:FindFirstChildWhichIsA("ProximityPrompt", true)
            local t0=tick()
            while prompt and not prompt.Enabled and tick()-t0 < 2 do task.wait(0.1) prompt=chest:FindFirstChild("ChestPrompt", true) or chest:FindFirstChildWhichIsA("ProximityPrompt", true) end
            if prompt and not prompt.Enabled then break end
            local cpos=chest:GetPivot().Position
            local dest=CFrame.new(cpos + Vector3.new(0,8,0))
            local dist=(dest.Position - hrp.Position).Magnitude
            local t=math.clamp(dist / 80, 0.2, 2)
            local tw=TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = dest})
            tw:Play()
            tw.Completed:Wait()
            hrp.AssemblyLinearVelocity = Vector3.new(0, -10, 0)
            task.wait(0.5)
            if chest.Parent and chest:FindFirstChild("Chest_Effect", true) then
                task.wait(0.3)
            end
            task.wait(0.2)
            t0=tick()
            while chest.Parent and chest:FindFirstChild("Chest_Effect", true) and tick()-t0 < 1.5 do task.wait(0.1) end
            task.wait(0.15)
            if not Config.CollectChallengerChests or not Config.AutoFarm then break end
            if not getChallengeArena() then break end
        end
        IsCollectingChallengerChest = false
    end
end)

-- Auto Chest / Replay / Return: handle dungeon end flow
task.spawn(function()
    local Knit = require(ReplicatedStorage.Packages.Knit)
    function getChestCtrl()
        local ok, ctrl = pcall(function() return Knit.GetController("ChestSelectionController") end)
        if ok and ctrl then return ctrl end
        return nil
    end
    function getDungeonRunService()
        local ok, svc = pcall(function() return Knit.GetService("DungeonRunService") end)
        if ok and svc then return svc end
        return nil
    end
    repeat task.wait(0.5) until getChestCtrl() and getDungeonRunService()
    local ChestCtrl = getChestCtrl()
    local DungeonRunService = getDungeonRunService()
    local function autoPick()
        if not Config.AutoChest or not ChestCtrl or not ChestCtrl.IsActive or not ChestCtrl:IsActive() then return end
        task.wait(0.15)
        local maxPicks = ChestCtrl._maxPicks or 2
        if ChestCtrl._ownsExtraLoot then maxPicks = 3 end
        local t0 = tick()
        while not ChestCtrl._ready and tick()-t0 < 1 do task.wait(0.05) end
        for i=1, maxPicks do
            if not Config.AutoChest or not ChestCtrl:IsActive() then break end
            if not ChestCtrl._selected[i] then
                pcall(function() ChestCtrl:_OnChestClicked(i) end)
                task.wait(0.4)
            end
        end
        task.wait(0.1)
        pcall(function() ChestCtrl:_OnFinish() end)
        task.wait(0.4)
        pcall(function() tryReplayReturn() end)
    end
    local function handleDungeonComplete()
        if not ChestCtrl or not ChestCtrl.IsActive or not ChestCtrl:IsActive() then
            task.wait(1)
            pcall(function() tryReplayReturn() end)
        end
    end
    if DungeonRunService then
        pcall(function()
            DungeonRunService.ChestSelection:Connect(function()
                if Config.AutoChest then task.spawn(autoPick) end
            end)
            DungeonRunService.MidRunChestSelection:Connect(function()
                if Config.AutoChest then task.spawn(autoPick) end
            end)
            DungeonRunService.DungeonComplete:Connect(function()
                if Config.AutoReplay or Config.AutoReturn then task.spawn(handleDungeonComplete) end
            end)
        end)
    end
    while true do
        task.wait(0.8)
        if Config.AutoChest and ChestCtrl and ChestCtrl.IsActive and ChestCtrl:IsActive() and ChestCtrl._ready then
            if ChestCtrl._selectedCount < (ChestCtrl._maxPicks or 2) then
                task.spawn(autoPick)
                task.wait(2)
            end
        end
    end
end)

local onDungeonRegenerated
-- Auto Continue (Endless Only) + force farm resume
task.spawn(function()
    local Knit = require(ReplicatedStorage.Packages.Knit)
    repeat task.wait(0.5) until pcall(function() return Knit.GetService("DungeonRunService") end)
    local DungeonRunService = Knit.GetService("DungeonRunService")
    local function isEndlessMode()
        return LP:GetAttribute("CurrentDifficultyMode") == "Endless"
    end
    pcall(function()
        DungeonRunService.EndlessDecision:Connect(function(data)
            if not Config.AutoContinue then return end
            if not isEndlessMode() then return end
            task.wait(0.5)
            local target = Config.EndlessTargetCheckpoint or 5
            local cur = (data and data.ExtensionIndex or 0) + 1
            local shouldContinue = cur < target
            pcall(function() DungeonRunService:SubmitEndlessChoice(shouldContinue) end)
            if shouldContinue then
                task.wait(1)
                if Config.AutoFarm then
                    pcall(function() onDungeonRegenerated() end)
                end
            end
        end)
        pcall(function()
            DungeonRunService.EndlessTransition:Connect(function(state)
                if state == "Done" and Config.AutoFarm and Config.AutoContinue and isEndlessMode() then
                    task.wait(0.3)
                    pcall(function() onDungeonRegenerated() end)
                end
            end)
        end)
    end)
end)

-- Auto Select Buff (Blessing)
task.spawn(function()
    local Knit = require(ReplicatedStorage.Packages.Knit)
    repeat task.wait(0.5) until pcall(function() return Knit.GetController("BoostSelectionController") end)
    local BoostCtrl = Knit.GetController("BoostSelectionController")
    local BuffService
    pcall(function() BuffService = Knit.GetService("DungeonBuffService") end)
    if BoostCtrl and BuffService then
        pcall(function()
            BuffService.BuffSelection:Connect(function(candidates)
                if not Config.AutoBuff then return end
                task.wait(0.15)
                local t0=tick()
                while not BoostCtrl._ready and tick()-t0 < 1 do task.wait(0.05) end
                local pick = 1
                if candidates then
                    for i, c in ipairs(candidates) do
                        if c.Title == "Overwhelming Force" then pick=i break end
                    end
                    if pick==1 and candidates[1] and candidates[1].Title ~= "Overwhelming Force" then
                        for i,c in ipairs(candidates) do if c.Title=="Fleetfoot" then pick=i break end end
                    end
                end
                pcall(function() BoostCtrl:_OnCardClicked(pick) end)
            end)
        end)
    end
    while true do
        task.wait(0.5)
        if Config.AutoBuff and BoostCtrl and BoostCtrl._active and BoostCtrl._ready and not BoostCtrl._selecting then
            local t0=tick()
            while not BoostCtrl._ready and tick()-t0 < 0.5 do task.wait(0.05) end
            if BoostCtrl._active and BoostCtrl._ready then
                pcall(function() BoostCtrl:_OnCardClicked(1) end)
                task.wait(1)
            end
        end
    end
end)

-- Auto Use Potion
task.spawn(function()
    local lastUse = 0
    while true do
        task.wait(0.3)
        if not Config.AutoPotion or Fluent.Unloaded then continue end
        local char = LP.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local pct = (hum.Health / hum.MaxHealth) * 100
        if pct < Config.PotionThreshold and tick() - lastUse > 1 then
            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                vim:SendKeyEvent(true, Enum.KeyCode.Five, false, game)
                task.wait(0.05)
                vim:SendKeyEvent(false, Enum.KeyCode.Five, false, game)
            end)
            pcall(function()
                local Knit = require(ReplicatedStorage.Packages.Knit)
                local svc = Knit.GetService("PotionService")
                if svc and svc.UsePotion then svc:UsePotion() end
            end)
            lastUse = tick()
            task.wait(1)
        end
    end
end)

-- Auto Refill Potions (only in current farming room, when potions <=2)
task.spawn(function()
    function getPotionCount()
        local ok, reg = pcall(function() return require(game.Players.LocalPlayer.PlayerScripts.Client.Controllers.Registry):Get("PlayerData") end)
        if ok and reg and reg.Data and reg.Data.Potions then
            local eq = reg.Data.EquippedPotion
            if eq and reg.Data.Potions[eq] ~= nil then return reg.Data.Potions[eq] end
            local sum=0 for _,v in pairs(reg.Data.Potions) do sum=sum+v end return sum
        end
        return 99
    end
    function getStationInCurrentRoom()
        if not CurrentRoom or not CurrentRoom.Parent then return nil end
        local gen=getGeneratedDungeon()
        if not gen then return nil end
        for _,v in ipairs(gen:GetDescendants()) do
            if v.Name=="Potion_Station" then
                local stationPos=v:GetPivot().Position
                local roomPos=CurrentRoom:GetPivot().Position
                if (stationPos - roomPos).Magnitude < 120 then return v end
                local zone=CurrentRoom:FindFirstChild("Zone")
                if zone and zone:IsA("BasePart") then
                    local rel=zone.CFrame:PointToObjectSpace(stationPos)
                    local half=zone.Size*0.5
                    if math.abs(rel.X)<=half.X and math.abs(rel.Y)<=half.Y+30 and math.abs(rel.Z)<=half.Z then return v end
                end
            end
        end
        return nil
    end
    while true do
        task.wait(0.15)
        if not Config.AutoRefill or not Config.AutoFarm or Fluent.Unloaded then continue end
        if IsCollectingChest or IsRefilling then continue end
        if CurrentTarget and isEnemyAlive(CurrentTarget) then continue end
        if not CurrentRoom or #getEnemiesInRoom(CurrentRoom) > 0 then continue end
        if getPotionCount() > 2 then continue end
        local station=getStationInCurrentRoom()
        if not station then continue end
        local prompt=station:FindFirstChild("ProximityPrompt", true)
        if prompt and not prompt.Enabled then continue end
        IsRefilling=true
        while IsCollectingChest do task.wait(0.1) end
        disableLock()
        local hrp=getHRP()
        if hrp then
            local spos=station:GetPivot().Position
            local dest=CFrame.new(spos + Vector3.new(0,2,0))
            local dist=(dest.Position - hrp.Position).Magnitude
            local t=math.clamp(dist / 80, 0.2, 1.5)
            local tw=TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = dest})
            tw:Play()
            tw.Completed:Wait()
            task.wait(0.2)
            pcall(function() fireproximityprompt(prompt, 0.5) end)
            if prompt then
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration + 0.1)
                prompt:InputHoldEnd()
            end
            task.wait(0.5)
        end
        IsRefilling=false
    end
end)
pcall(function() SaveManager:SetLibrary(Fluent) end)
pcall(function() InterfaceManager:SetLibrary(Fluent) end)
pcall(function() InterfaceManager:SetFolder("VoltScript") end)
pcall(function() SaveManager:SetFolder("VoltScript/DungeonLootr") end)
pcall(function() InterfaceManager:BuildInterfaceSection(Tabs.Settings) end)
pcall(function() SaveManager:BuildConfigSection(Tabs.Settings) end)
pcall(function() Window:SelectTab(1) end)
pcall(function() SaveManager:LoadAutoloadConfig() end)
-- Auto Save ทุกครั้งที่เปิดฟังก์ชั่น ไม่ต้องกด Config เอง
pcall(function() SaveManager:IgnoreThemeSettings() end)
pcall(function() SaveManager:SetIgnoreIndexes({}) end)
task.spawn(function()
    local lastSave = 0
    local lastJson = ""
    while true do
        task.wait(1)
        if Fluent.Unloaded then break end
        local ok, json = pcall(function() return game.HttpService:JSONEncode(Config) end)
        if ok and json ~= lastJson then
            lastJson = json
            if tick() - lastSave > 1 then
                lastSave = tick()
                pcall(function() SaveManager:Save("Default") end)
                pcall(function() writefile("VoltScript/DungeonLootr/settings/autoload.txt", "Default") end)
            end
        end
    end
end)

-- Respawn fix (fast): immediate resume after death
LP.CharacterAdded:Connect(function(char)
    disableLock()
    CurrentTarget = nil
    CurrentRaidTarget = nil
    if not Config.AutoFarm and not Config.AutoBossRaid then return end
    local hrp = char:WaitForChild("HumanoidRootPart", 3) or getHRP()
    if not hrp then return end
    task.wait(0.1)
    if Config.AutoFarm and CurrentRoom and CurrentRoom.Parent then
        pcall(function() teleportToRoom(CurrentRoom) end)
        task.wait(0.1)
        local mob = getNearestInRoom(CurrentRoom)
        if mob and isEnemyAlive(mob) then
            pcall(function() teleportTo(mob) end)
            CurrentTarget = mob
        elseif #getEnemiesInRoom(CurrentRoom) == 0 then
            waitForRoomSpawn(CurrentRoom, 0.6)
            mob = getNearestInRoom(CurrentRoom)
            if mob then pcall(function() teleportTo(mob) end) CurrentTarget = mob end
        end
    elseif Config.AutoBossRaid and LP:GetAttribute("InRaid") then
        local hrp2 = char:WaitForChild("HumanoidRootPart", 3) or getHRP()
        task.wait(0.5)
        for i=1,4 do
            local mob = getNearestRaidAdd() or getNearestInRaid()
            if mob and isEnemyAlive(mob) then
                pcall(function() teleportTo(mob) end)
                CurrentRaidTarget = mob
                break
            end
            task.wait(0.6)
        end
    else
        CurrentRoom = nil
    end
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 3)
    if hum then
        hum.Died:Once(function()
            disableLock()
            CurrentTarget = nil
            CurrentRaidTarget = nil
        end)
    end
end)
if LP.Character then
    local hum0 = LP.Character:FindFirstChildOfClass("Humanoid")
    if hum0 then
        hum0.Died:Once(function()
            disableLock()
            CurrentTarget = nil
            CurrentRaidTarget = nil
        end)
    end
end

-- Endless Continue fix: non-blocking to avoid lock gap after Continue
onDungeonRegenerated = function()
    if not Config.AutoFarm then return end
    CurrentTarget = nil
    task.spawn(function()
        disableLock()
        CurrentRoom = nil
        task.wait(1)
        local t0 = tick()
        while tick() - t0 < 2 do
            local hrp = getHRP()
            local rooms = getRoomFolders()
            if hrp and hrp.Position.Y > 200 and #rooms > 0 and rooms[1]:FindFirstChild("Zone") then
                break
            end
            task.wait(0.2)
        end
        task.wait(0.3)
        local rooms = getRoomFolders()
        if #rooms > 0 and Config.AutoFarm then
            CurrentRoom = rooms[1]
            pcall(function() teleportToRoom(CurrentRoom) end)
            task.wait(0.2)
            local mob = getNearestInRoom(CurrentRoom)
            if mob and isEnemyAlive(mob) then
                pcall(function() teleportTo(mob) end)
                CurrentTarget = mob
            elseif #getEnemiesInRoom(CurrentRoom) == 0 then
                waitForRoomSpawn(CurrentRoom, 0.6)
                mob = getNearestInRoom(CurrentRoom)
                if mob then pcall(function() teleportTo(mob) end) CurrentTarget = mob end
            end
        end
    end)
end
workspace.ChildAdded:Connect(function(obj)
    if obj.Name:find("Generated_") then
        task.wait(0.3)
        onDungeonRegenerated()
    end
end)
workspace.ChildRemoved:Connect(function(obj)
    if obj.Name:find("Generated_") then
        disableLock()
        CurrentTarget = nil
    end
end)

-- Watchdog: HRP not moving or falling -> auto resume
local lastHRPPos = nil
local lastMoveTick = tick()
task.spawn(function()
    while true do
        task.wait(1)
        if not Config.AutoFarm or Fluent.Unloaded then
            lastHRPPos = nil
            lastMoveTick = tick()
            continue
        end
        local hrp = getHRP()
        if not hrp then continue end
        if hrp.Position.Y < 100 then
            disableLock()
            CurrentTarget = nil
            task.wait(0.4)
            local t0=tick()
            while tick()-t0 < 4 do
                hrp=getHRP()
                if hrp and hrp.Position.Y > 200 then break end
                task.wait(0.2)
            end
            CurrentRoom=nil
            task.wait(0.5)
            pcall(function() onDungeonRegenerated() end)
            lastMoveTick=tick()
            lastHRPPos=hrp and hrp.Position or nil
            continue
        end
        local pos = hrp.Position
        if lastHRPPos and (pos - lastHRPPos).Magnitude < 1.5 then
            local need = (LP:GetAttribute("CurrentDifficultyMode") == "Endless") and 3 or 5
            if tick() - lastMoveTick > need then
                disableLock()
                CurrentTarget = nil
                local mob = CurrentRoom and getNearestInRoom(CurrentRoom)
                if mob and isEnemyAlive(mob) then
                    pcall(function() teleportTo(mob) end)
                    CurrentTarget = mob
                elseif CurrentRoom and CurrentRoom.Parent then
                    pcall(function() teleportToRoom(CurrentRoom) end)
                    task.wait(0.15)
                    mob = getNearestInRoom(CurrentRoom)
                    if mob then pcall(function() teleportTo(mob) end) CurrentTarget = mob end
                else
                    CurrentRoom = nil
                end
                lastMoveTick = tick()
            end
        else
            lastMoveTick = tick()
        end
        lastHRPPos = pos
    end
end)
