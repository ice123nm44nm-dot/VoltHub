local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ice123nm44nm-dot/VoltHub/main/VoltUi.lua"))()

local Gen = (getgenv().VoltGen or 0) + 1
getgenv().VoltGen = Gen

-- Close the window from the previous run first. Its auto-save loop would otherwise
-- keep writing the config file every 10s and overwrite the settings you just changed.
if getgenv().VoltWin then
    pcall(function()
        if type(getgenv().VoltWin.Destroy) == "function" then
            getgenv().VoltWin:Destroy()
        end
    end)
    getgenv().VoltWin = nil
end

local Win = Library:CreateWindow({
    Title = "Volt",
    TitleAccent = "ScriptZ",
    Subtitle = "Prehistoric Farm | Made By VoltScript Hub",
    Name = "VoltScriptZ",
    Logo = "rbxassetid://100712256015627"
})
getgenv().VoltWin = Win

Win:AddSection("General")
local MainTab = Win:AddTab({ Name = "Main" })
local ShopTab = Win:AddTab({ Name = "Shop" })
local BossTab = Win:AddTab({ Name = "Boss" })
local WebhookTab = Win:AddTab({ Name = "Webhook" })
Win:AddSection("Utilities")
local UtilitiesTab = Win:AddTab({ Name = "Utilities" })
local SettingsTab = Win:AddTab({ Name = "Settings" })
local DigCard = MainTab:AddCard({
    Title = "Auto Dig",
    Subtitle = "Automatically Digs",
    Toggle = false,
})

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local FTD = ReplicatedStorage:WaitForChild("FTD")
local Config = require(FTD.Config)

if not getgenv().VoltAFK then
    getgenv().VoltAFK = true
    pcall(function()
        LocalPlayer.Idled:Connect(function()
            if getgenv().VoltDig and getgenv().VoltDig.AntiAFK == false then
                return
            end
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end)
        end)
    end)
end

local State = {
    AutoDig = false,
    DigIsland = "Auto",
    DigQuality = "Perfect",
    AutoBuyShovels = false,
    AutoBuyRods = false,
    RodTarget = "Amethyst",
    RodMode = "Auto",
    AutoBuyBoats = false,
    BoatTarget = "Skiff",
    BoatMode = "Auto",
    AutoTrade = false,
    TradeRarity = { "All" },
    AutoIncubate = false,
    EggRarity = { "All" },
    AutoHatch = false,
    AutoBuyIncubators = false,
    AutoPlace = false,
    TeleportZone = "Ranch",
    Teleporting = false,
    AutoBuyFood = false,
    BuyFood = "Both",
    BuyLimit = 50,
    AutoFeed = false,
    AutoSell = false,
    FossilRarity = { "None" },
    FishRarity = { "None" },
    SellEggRarity = { "None" },
    DinoRarity = { "None" },
    AutoFish = false,
    FishTarget = { "All" },
    FishPower = 0.95,
    FishNeedSpot = false,
    AutoNest = false,
    NestTarget = "All",
    AutoBoss = false,
    BossTarget = "Mosa",
    BossAim = "Head",
    MosaH = 0,
    BossMode = "Throw",
    WebhookOn = true,
    WebhookURL = "",
    AutoNessie = false,
    AutoSummon = false,
    AutoFarmFrag = false,
    NessieAim = "Head",
    NessieH = 0,
    NessieMode = "Throw",
    LastNessie = "",
    AutoRaptor = false,
    RaptorAim = "Head",
    RaptorH = 0,
    RaptorMode = "Throw",
    LastRaptor = "",
    AutoRaptorSummon = false,
    AutoHopRaptor = false,
    AutoExe = true,
    AutoSkipIntro = true,
    AutoTrue = false,
    TrueAim = "Head",
    TrueH = 0,
    TrueMode = "Throw",
    LastTrue = "",
    BlackScreen = false,
    FpsLock = false,
    FpsCap = 60,
    StreamMode = false,
    AntiAFK = true,
}
getgenv().VoltDig = State

local WebhookStart = os.clock()

local function WebhookUptime()
    local s = math.floor(os.clock() - WebhookStart)
    local h = s // 3600
    local m = (s % 3600) // 60
    local sec = s % 60
    return tostring(h) .. "H " .. tostring(m) .. "M " .. tostring(sec) .. "S"
end

local function WebhookTag()
    return "【" .. tostring(LocalPlayer.Name) .. "｜online " .. WebhookUptime() .. "】 "
end

local function WebhookSend(msg)
    if not State.WebhookOn then
        return
    end
    local url = State.WebhookURL
    if not url or url == "" then
        return
    end
    task.spawn(function()
        pcall(function()
            local body = game:GetService("HttpService"):JSONEncode({ content = WebhookTag() .. tostring(msg) })
            request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
        end)
    end)
end

local HoldTime = {
    Perfect = 0.55,
    Great = 0.4,
    Good = 0.3,
    Weak = 0.2
}

local IslandOrder = { "Cambrian", "Devonian", "Triassic", "Jurassic", "Cretaceous", "LateCretaceous", "Pacific" }

local function GetHRP()
    local char = LocalPlayer.Character
    if not char then
        return nil
    end
    return char:FindFirstChild("HumanoidRootPart")
end

local function GetTool()
    local char = LocalPlayer.Character
    if not char then
        return nil
    end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        return tool
    end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then
        return nil
    end
    for _, t in pairs(backpack:GetChildren()) do
        if t:IsA("Tool") and string.find(string.lower(t.Name), "shovel") then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:EquipTool(t)
                task.wait(0.2)
            end
            return char:FindFirstChildOfClass("Tool")
        end
    end
    return nil
end

local function ShovelSpeed()
    local tier = LocalPlayer:GetAttribute("EquippedShovel")
    if type(tier) ~= "string" then
        local tool = GetTool()
        if tool then
            tier = tool:GetAttribute("Tier")
        end
    end
    if type(tier) == "string" and Config.Shovels and Config.Shovels[tier] then
        return Config.Shovels[tier].Speed or 1
    end
    return 1
end

local function CanDig(island)
    local tier = LocalPlayer:GetAttribute("EquippedShovel")
    if type(tier) ~= "string" then
        local tool = GetTool()
        tier = (tool and tool:GetAttribute("Tier")) or "Wooden"
    end
    local data = Config.Shovels and Config.Shovels[tier]
    if not data then
        return true
    end
    if data.Islands and data.Islands[island] then
        return true
    end
    return false
end

local function BestIsland()
    for i = #IslandOrder, 1, -1 do
        if CanDig(IslandOrder[i]) then
            return IslandOrder[i]
        end
    end
    return nil
end

local function MashNeed(layer, quality)
    local ok, need = pcall(function()
        return Config.MashNeed(layer, quality, ShovelSpeed())
    end)
    if ok and type(need) == "number" then
        return need
    end
    return 10
end

-- The game's own dig controller keeps the live dig phase and the quality the meter is
-- currently sitting in as upvalues. Reading them means the hold can be released the moment
-- the game itself reports Perfect, and the mash can stop the moment the game leaves Mash,
-- instead of guessing both from a timer. The slots are found by their values, so a game
-- update that renumbers them does not break it; if anything cannot be read we fall back to
-- the old fixed timings.
local DigRefs = nil

local function DigScan()
    if DigRefs == false then
        return nil
    end
    if DigRefs then
        return DigRefs
    end
    local ok, refs = pcall(function()
        local folder = LocalPlayer:FindFirstChild("PlayerScripts")
        folder = folder and folder:FindFirstChild("FTD_Controllers")
        local mod = folder and folder:FindFirstChild("DigController")
        if not mod then
            return nil
        end
        local M = require(mod)
        local press = M and M.Press
        if typeof(press) ~= "function" then
            return nil
        end
        local outer = debug.getupvalues(press)
        if not outer then
            return nil
        end
        local inner = nil
        for i = 1, 16 do
            if typeof(outer[i]) == "function" then
                inner = outer[i]
                break
            end
        end
        if not inner then
            return nil
        end
        local up = debug.getupvalues(inner)
        if not up then
            return nil
        end
        local states = { Idle = true, Holding = true, Mash = true, Swing = true, Ready = true, Resolving = true }
        local quals = { Weak = true, Good = true, Great = true, Perfect = true }
        local sIdx, qIdx = nil, nil
        for i = 1, 96 do
            local v = up[i]
            if type(v) == "string" then
                if not sIdx and states[v] then
                    sIdx = i
                elseif not qIdx and quals[v] then
                    qIdx = i
                end
            end
        end
        if not sIdx and not qIdx then
            return nil
        end
        return { fn = inner, s = sIdx, q = qIdx }
    end)
    DigRefs = (ok and refs) or false
    return DigRefs or nil
end

local function DigRead()
    local refs = DigScan()
    if not refs then
        return nil, nil
    end
    local ok, st, q = pcall(function()
        local up = debug.getupvalues(refs.fn)
        return up[refs.s], up[refs.q]
    end)
    if not ok then
        DigRefs = false
        return nil, nil
    end
    return st, q
end

local function DigState()
    local st = DigRead()
    return st
end

local function DigQuality()
    local _, q = DigRead()
    return q
end

local function DigMaxHold()
    local ok, v = pcall(function()
        return Config.Dig and Config.Dig.MaxHold
    end)
    if ok and type(v) == "number" then
        return v
    end
    return 5
end

local function DigRelease(tool)
    pcall(function()
        local t = tool or GetTool()
        if t then
            t:Deactivate()
        end
    end)
end

-- Walk the meter until the game reports the Perfect band, then let go. No fixed hold time.
local function HoldToPerfect(holdTime)
    if DigState() == nil then
        local t = GetTool()
        if t then
            t:Activate()
        end
        task.wait(holdTime)
        DigRelease(t)
        return true
    end
    local tool = GetTool()
    if not tool then
        return false
    end
    local limit = os.clock() + DigMaxHold() - 0.4
    local pressAt = 0
    while os.clock() < limit do
        if not State.AutoDig or (State.AnyBossBusy and State.AnyBossBusy()) then
            break
        end
        local st = DigState()
        if st == nil then
            break
        end
        if st == "Holding" then
            if DigQuality() == "Perfect" then
                break
            end
        elseif st == "Mash" or st == "Resolving" then
            break
        elseif os.clock() >= pressAt then
            -- Between layers the game sits on "Swing"/"Ready" and waits for a fresh press,
            -- and it ignores a press made while the tool is still held from the last mash.
            -- Release first, press again, and keep retrying: giving up here makes the hub
            -- walk to the next hole, which cancels the pending layer and shows
            -- "You walked away - the hole filled back in.".
            pcall(function()
                tool:Deactivate()
            end)
            task.wait()
            pcall(function()
                tool:Activate()
            end)
            pressAt = os.clock() + 0.25
        end
        task.wait()
    end
    if DigState() == "Holding" then
        pcall(function()
            tool:Deactivate()
        end)
    end
    return true
end

-- Keep pressing until the game leaves the Mash phase, with a hard cap so a broken phase
-- can never spin forever. Presses are only ever sent while the game is genuinely mashing.
local function MashToDone(layer, quality)
    local st = DigState()
    if st == nil then
        local need = MashNeed(layer, quality)
        for _ = 1, need do
            if not State.AutoDig or (State.AnyBossBusy and State.AnyBossBusy()) then
                return false
            end
            local t = GetTool()
            if t then
                t:Activate()
            end
            task.wait(0.07)
        end
        task.wait(2.2)
        return true
    end
    local waitLimit = os.clock() + 0.9
    while os.clock() < waitLimit do
        if st == "Mash" or st == "Swing" or st == "Ready" or st == "Idle" or st == "Resolving" then
            break
        end
        task.wait()
        st = DigState()
    end
    if st ~= "Mash" then
        return true
    end
    -- the game only opens the mash window ~0.2s in; presses before that are ignored
    task.wait(0.2)
    local cap = os.clock() + 5.5
    local pressed = 0
    while st == "Mash" and pressed < 140 and os.clock() < cap do
        if not State.AutoDig or (State.AnyBossBusy and State.AnyBossBusy()) then
            return false
        end
        local t = GetTool()
        if t then
            t:Activate()
            pressed = pressed + 1
        end
        task.wait(0.05)
        st = DigState()
    end
    -- Leave the tool released. If it stays held, the game ignores the press that starts
    -- the next layer and the pending layer dies with "You walked away...".
    DigRelease()
    return true
end

-- One layer: hold to Perfect, mash it through, then let the game settle. "Swing" means the
-- layer passed and another layer is coming; "Resolving"/"Idle" means the dig is over.
local function DigOneLayer(layer, quality, holdTime)
    if DigState() == "Mash" then
        MashToDone(layer, quality)
    else
        if not HoldToPerfect(holdTime) then
            return false
        end
        MashToDone(layer, quality)
    end
    local limit = os.clock() + 2.0
    while os.clock() < limit do
        local s = DigState()
        if s == nil or s == "Swing" or s == "Ready" or s == "Holding" or s == "Idle" or s == "Resolving" then
            break
        end
        if not State.AutoDig then
            return false
        end
        task.wait(0.05)
    end
    return true
end

local function PreTeleport()
    pcall(function()
        local folder = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("FTD_Controllers")
        local mod = folder and folder:FindFirstChild("PartnerController")
        local pc = mod and require(mod)
        if pc and pc.IsRiding and pc.IsRiding() then
            if pc.StopRide then
                pc.StopRide()
            end
            task.wait(0.3)
        end
    end)
end

local function IslandCenter(island)
    if island == "Pacific" then
        return Vector3.new(-4300, -400, 0)
    end
    local cx, cz = nil, nil
    pcall(function()
        local z = Config.Zones and Config.Zones[island]
        if z and z.Center then
            cx, cz = z.Center.x, z.Center.z
        end
    end)
    if cx then
        return Vector3.new(cx, 10, cz)
    end
    local map = workspace:FindFirstChild("Map")
    if map then
        local folder = map:FindFirstChild(island)
        if folder then
            local ok, cf = pcall(function()
                return folder:GetPivot()
            end)
            if ok and cf then
                return cf.Position + Vector3.new(0, 8, 0)
            end
            for _, d in pairs(folder:GetDescendants()) do
                if d:IsA("BasePart") then
                    return d.Position + Vector3.new(0, 8, 0)
                end
            end
        end
    end
    return nil
end

local function GetSites(island)
    local hrp = GetHRP()
    if not hrp then
        return {}
    end
    local list = {}
    for _, m in pairs(CollectionService:GetTagged("FTD_DigSite")) do
        if m:IsA("Model") and m.Parent then
            local busy = false
            pcall(function()
                busy = m:GetAttribute("Busy") == true
            end)
            if not busy then
                local isl = nil
                pcall(function()
                    isl = m:GetAttribute("Island")
                end)
                if isl == nil or isl == island then
                    local ok, pivot = pcall(function()
                        return m:GetPivot()
                    end)
                    if ok and pivot then
                        local dist = (pivot.Position - hrp.Position).Magnitude
                        table.insert(list, { Model = m, Dist = dist, Pos = pivot.Position })
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b)
        return a.Dist < b.Dist
    end)
    return list
end

-- The hole the player is standing on, ignoring island and the Busy flag, so an unfinished
-- dig can always be finished before the hub walks away from it.
local function NearestSiteAny()
    local hrp = GetHRP()
    if not hrp then
        return nil
    end
    local best, bestD, bestPos = nil, math.huge, nil
    for _, m in pairs(CollectionService:GetTagged("FTD_DigSite")) do
        if m:IsA("Model") and m.Parent then
            local ok, pivot = pcall(function()
                return m:GetPivot()
            end)
            if ok and pivot then
                local d = (pivot.Position - hrp.Position).Magnitude
                if d < bestD then
                    bestD, best, bestPos = d, m, pivot.Position
                end
            end
        end
    end
    if best then
        return { Model = best, Dist = bestD, Pos = bestPos }
    end
    return nil
end

local function Teleport(pos, lookAt)
    local hrp = GetHRP()
    if not hrp or not pos then
        return
    end
    pcall(function()
        local folder = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("FTD_Controllers")
        local mod = folder and folder:FindFirstChild("PartnerController")
        local pc = mod and require(mod)
        if pc and pc.IsRiding and pc.IsRiding() then
            if pc.StopRide then
                pc.StopRide()
            end
            task.wait(0.3)
        end
    end)
    hrp = GetHRP()
    if not hrp then
        return
    end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    if lookAt then
        hrp.CFrame = CFrame.lookAt(pos, Vector3.new(lookAt.X, pos.Y, lookAt.Z))
    else
        hrp.CFrame = CFrame.new(pos)
    end
end

local function DigOneSite(site, quality, holdTime)
    -- A hole can be three layers deep and every layer past the first needs its own hold, so
    -- keep working while the game still reports a hole in progress instead of counting to
    -- three blindly. Stopping early is what makes the hub walk off in the middle of a dig.
    local layer = 0
    local guard = os.clock() + 25
    while layer < 6 and os.clock() < guard do
        if not State.AutoDig then
            return false
        end
        if State.AnyBossBusy and State.AnyBossBusy() then
            return false
        end
        local gone = false
        pcall(function()
            gone = site.Parent == nil
        end)
        if gone then
            return true
        end
        pcall(function()
            local pv = site:GetPivot()
            local hrp0 = GetHRP()
            if pv and hrp0 then
                if (hrp0.Position - pv.Position).Magnitude > 6 then
                    local dir0 = Vector3.new(hrp0.Position.X - pv.Position.X, 0, hrp0.Position.Z - pv.Position.Z)
                    if dir0.Magnitude < 0.1 then
                        dir0 = Vector3.new(4, 0, 0)
                    end
                    dir0 = dir0.Unit
                    Teleport(pv.Position + dir0 * 3 + Vector3.new(0, 3, 0), pv.Position)
                    task.wait(0.3)
                end
            end
        end)
        if not State.AutoDig then
            return false
        end
        if State.AnyBossBusy and State.AnyBossBusy() then
            return false
        end
        if layer > 0 then
            local before = DigState()
            if before == "Idle" or before == "Resolving" then
                return true
            end
        end
        layer = layer + 1
        if not DigOneLayer(layer, quality, holdTime) then
            return false
        end
    end
    return true
end

local function OwnedShovelSet()
    local set = { Wooden = true }
    local raw = LocalPlayer:GetAttribute("OwnedShovels") or ""
    for name in string.gmatch(raw, "[^,]+") do
        set[name] = true
    end
    return set
end

local function NextShovelTier()
    local owned = OwnedShovelSet()
    local order = Config.ShovelOrder or { "Wooden", "Bronze", "Silver", "Iron", "Titanium" }
    local defs = Config.Shovels or {}
    for _, name in ipairs(order) do
        if not owned[name] then
            local def = defs[name]
            if def and (def.Quest or def.Drop) then
                continue
            end
            return name
        end
    end
    return nil
end

local function MaterialCounts()
    local ok, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(LocalPlayer:GetAttribute("Materials") or "{}")
    end)
    if ok and type(data) == "table" then
        return data
    end
    return {}
end

local function TryBuyShovel()
    local tier = NextShovelTier()
    if not tier then
        return
    end
    local def = Config.Shovels and Config.Shovels[tier]
    if not def then
        return
    end
    local coins = LocalPlayer:GetAttribute("Coins") or 0
    if coins < (def.Price or 0) then
        return
    end
    if def.Requires then
        local counts = MaterialCounts()
        for mat, need in pairs(def.Requires) do
            if (counts[mat] or 0) < need then
                return
            end
        end
    end
    local shop = FTD:WaitForChild("Remotes")
    local res = nil
    local ok = pcall(function()
        res = shop.ShopRequest:InvokeServer("BuyShovel", tier)
    end)
    if ok and res and res.ok then
        pcall(function()
            shop.ShopRequest:InvokeServer("EquipShovel", tier)
        end)
        Win:Notify({
            Title = "VoltScriptZ",
            Text = "Bought " .. tier,
            Duration = 5
        })
    end
end

task.spawn(function()
    -- how many times in a row the hub refused to walk away from a hole still being dug
    local liveResumes = 0
    while Gen == getgenv().VoltGen do
        task.wait(0.25)
        if not State.AutoDig then
            State._digBusy = false
            continue
        end
        if State._fragWarp then
            continue
        end
        if State.AnyBossBusy and State.AnyBossBusy() then
            State._digBusy = false
            -- A fight (or a summon that is physically moving us) owns the character. A boss that is
            -- merely armed (ready + key, nothing happening) must not park the digger forever, so give
            -- the summon loop a window to act and then carry on digging.
            local fighting = State.AnyBossFighting and State.AnyBossFighting()
            if fighting or State._raptorSummonBusy or State._nessieSummonBusy then
                State._digHoldAt = nil
                continue
            end
            State._digHoldAt = State._digHoldAt or os.clock()
            if os.clock() - State._digHoldAt < 45 then
                continue
            end
            State._digHoldAt = nil
        else
            State._digHoldAt = nil
        end
        if DigState() == "Resolving" then
            -- the previous dig is still revealing; leave it alone
            State._digBusy = false
            task.wait(1)
            continue
        end
        local island = State.DigIsland
        if island == "Auto" then
            island = BestIsland()
            if not island then
                task.wait(2)
                continue
            end
        end
        local quality = State.DigQuality
        local holdTime = HoldTime[quality] or 0.55
        if not CanDig(island) then
            Win:Notify({
                Title = "VoltScriptZ",
                Text = "Need better shovel for " .. island,
                Duration = 3
            })
            State.AutoDig = false
            continue
        end
        GetTool()
        local sites = GetSites(island)
        if #sites == 0 then
            local center = IslandCenter(island)
            if center then
                State._digBusy = true
                Teleport(center)
                State._digBusy = false
            end
            task.wait(2)
            continue
        end
        local target = sites[1]
        State._digBusy = true
        -- Walking out of range of a hole cancels the dig ("You walked away - the hole filled
        -- back in."), so if the game still reports an unfinished hole, finish it first.
        local live = DigState()
        live = live == "Swing" or live == "Ready" or live == "Holding" or live == "Mash"
        if live and liveResumes < 2 then
            local here = NearestSiteAny()
            if here and here.Dist <= 18 then
                liveResumes = liveResumes + 1
                pcall(function()
                    DigOneSite(here.Model, quality, holdTime)
                end)
                State._digBusy = false
                task.wait(0.2)
                continue
            end
        end
        if not live then
            liveResumes = 0
        end
        if target.Dist > 11 then
            local hrp = GetHRP()
            if hrp then
                local dir = Vector3.new(hrp.Position.X - target.Pos.X, 0, hrp.Position.Z - target.Pos.Z)
                if dir.Magnitude < 0.1 then
                    dir = Vector3.new(4, 0, 0)
                end
                dir = dir.Unit
                Teleport(target.Pos + dir * 3 + Vector3.new(0, 3, 0), target.Pos)
                task.wait(0.4)
            end
        end
        pcall(function()
            DigOneSite(target.Model, quality, holdTime)
        end)
        State._digBusy = false
        task.wait(0.3)
    end
end)

task.spawn(function()
    while Gen == getgenv().VoltGen do
        task.wait(5)
        if State.AutoBuyShovels then
            pcall(TryBuyShovel)
        end
    end
end)

local RodFallbackOrder = { "Driftwood", "JadeBamboo", "Tidecaller", "Amethyst", "Goldscale" }

local function OwnedRodSet()
    local set = { Driftwood = true }
    local raw = LocalPlayer:GetAttribute("OwnedRods") or ""
    for name in string.gmatch(raw, "[^,]+") do
        set[name] = true
    end
    return set
end

local function NextRodTier()
    local owned = OwnedRodSet()
    local order = Config.RodOrder or RodFallbackOrder
    local defs = Config.Rods or {}
    if State.RodMode == "Selected" then
        if not owned[State.RodTarget] then
            local def = defs[State.RodTarget]
            if def and not (def.Quest or def.Drop) then
                return State.RodTarget
            end
        end
        return nil
    end
    local stopAt = 0
    for i, name in ipairs(order) do
        if name == State.RodTarget then
            stopAt = i
            break
        end
    end
    if stopAt == 0 then
        stopAt = #order
    end
    for i = 1, stopAt do
        local name = order[i]
        if not owned[name] then
            local def = defs[name]
            if def and (def.Quest or def.Drop) then
                continue
            end
            return name
        end
    end
    return nil
end

local function TryBuyRod()
    local tier = NextRodTier()
    if not tier then
        return
    end
    local def = Config.Rods and Config.Rods[tier]
    if not def then
        return
    end
    local coins = LocalPlayer:GetAttribute("Coins") or 0
    if coins < (def.Price or 0) then
        return
    end
    local shop = FTD:WaitForChild("Remotes")
    local res = nil
    local ok = pcall(function()
        res = shop.ShopRequest:InvokeServer("BuyRod", tier)
    end)
    if ok and res and res.ok then
        pcall(function()
            shop.ShopRequest:InvokeServer("EquipRod", tier)
        end)
        Win:Notify({
            Title = "VoltScriptZ",
            Text = "Bought " .. tier,
            Duration = 5
        })
    end
end

task.spawn(function()
    while Gen == getgenv().VoltGen do
        task.wait(5)
        if State.AutoBuyRods then
            pcall(TryBuyRod)
        end
    end
end)

local BoatFallbackOrder = { "Dinghy", "Dory", "Skiff", "Lobster" }

local function OwnedBoatSet()
    local set = { Dinghy = true }
    local raw = LocalPlayer:GetAttribute("OwnedBoats") or ""
    for name in string.gmatch(raw, "[^,]+") do
        set[name] = true
    end
    return set
end

local function NextBoatTier()
    local owned = OwnedBoatSet()
    local order = Config.BoatOrder or BoatFallbackOrder
    local defs = Config.Boats or {}
    if State.BoatMode == "Selected" then
        if not owned[State.BoatTarget] then
            local def = defs[State.BoatTarget]
            if def and not (def.Quest or def.Drop) then
                return State.BoatTarget
            end
        end
        return nil
    end
    local stopAt = 0
    for i, name in ipairs(order) do
        if name == State.BoatTarget then
            stopAt = i
            break
        end
    end
    if stopAt == 0 then
        stopAt = #order
    end
    for i = 1, stopAt do
        local name = order[i]
        if not owned[name] then
            local def = defs[name]
            if def and (def.Quest or def.Drop) then
                continue
            end
            return name
        end
    end
    return nil
end

local function TryBuyBoat()
    local tier = NextBoatTier()
    if not tier then
        return
    end
    local def = Config.Boats and Config.Boats[tier]
    if not def then
        return
    end
    local coins = LocalPlayer:GetAttribute("Coins") or 0
    if coins < (def.Price or 0) then
        return
    end
    local shop = FTD:WaitForChild("Remotes")
    local res = nil
    local ok = pcall(function()
        res = shop.BoatRequest:InvokeServer("Buy", tier)
    end)
    if ok and res and res.ok then
        pcall(function()
            shop.BoatRequest:InvokeServer("Equip", tier)
        end)
        Win:Notify({
            Title = "VoltScriptZ",
            Text = "Bought " .. tier,
            Duration = 5
        })
    end
end

task.spawn(function()
    while Gen == getgenv().VoltGen do
        task.wait(5)
        if State.AutoBuyBoats then
            pcall(TryBuyBoat)
        end
    end
end)

local function NormFilter(filter)
    if type(filter) ~= "table" or #filter == 0 then
        return filter
    end
    local hasAll, hasSpec = false, false
    for _, r in ipairs(filter) do
        if r == "All" then
            hasAll = true
        else
            hasSpec = true
        end
    end
    if hasAll and hasSpec then
        local t = {}
        for _, r in ipairs(filter) do
            if r ~= "All" then
                table.insert(t, r)
            end
        end
        return t
    end
    return filter
end

local function RarityOk(actual, filter)
    filter = NormFilter(filter)
    if filter == nil or filter == "All" then
        return true
    end
    if type(filter) == "table" then
        if #filter == 0 then
            return true
        end
        for _, r in ipairs(filter) do
            if r == "All" or r == actual then
                return true
            end
        end
        return false
    end
    return actual == filter
end

local function FossilCount(species)
    local data = LocalPlayer:FindFirstChild("FTD_Data")
    local folder = data and data:FindFirstChild("Fossils")
    local v = folder and folder:FindFirstChild(species)
    return (v and v.Value) or 0
end

local function FindTradeCandidate()
    local order = Config.CreatureOrder or {}
    for _, species in ipairs(order) do
        local cr = Config.Creatures and Config.Creatures[species]
        if cr and not cr.Marine and not cr.Hybrid and not cr.Sky then
            if RarityOk(cr.Rarity, State.TradeRarity) then
                local need = 5
                pcall(function()
                    need = Config.FossilsFor(species)
                end)
                if FossilCount(species) >= need then
                    return species
                end
            end
        end
    end
    return nil
end

local function DecodeAttr(name, fallback)
    local ok, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(LocalPlayer:GetAttribute(name) or "")
    end)
    if ok and type(data) == "table" then
        return data
    end
    return fallback
end

local function FindFreeSlot()
    local unlocked = DecodeAttr("IncUnlocked", {})
    local slots = DecodeAttr("Incubators", {})
    for i = 1, #unlocked do
        if unlocked[i] == true and slots[i] == false then
            return i
        end
    end
    return nil
end

local function TryIncubateEgg(egg)
    if not egg or not egg.Id or not egg.Species then
        return false
    end
    local cr = Config.Creatures and Config.Creatures[egg.Species]
    if not RarityOk(cr and cr.Rarity, State.EggRarity) then
        return false
    end
    local slot = FindFreeSlot()
    if not slot then
        return false
    end
    local shop = FTD:WaitForChild("Remotes")
    local res = nil
    local ok = pcall(function()
        res = shop.LabRequest:InvokeServer("Incubate", { Slot = slot, Egg = egg.Id })
    end)
    if ok and res and res.reason == "Slow down" then
        task.wait(5)
        return false
    end
    return ok and res and res.ok == true
end

local function TryTradeOnce()
    if not State.AutoTrade then
        return
    end
    local species = FindTradeCandidate()
    if not species then
        return
    end
    local shop = FTD:WaitForChild("Remotes")
    local res = nil
    local ok = pcall(function()
        res = shop.LabRequest:InvokeServer("Trade", species)
    end)
    if ok and res and res.reason == "Slow down" then
        task.wait(5)
        return
    end
    if ok and res and res.ok and res.egg and State.AutoIncubate then
        task.wait(1)
        pcall(function()
            TryIncubateEgg(res.egg)
        end)
    end
end

local function TryIncubateOnce()
    if not State.AutoIncubate then
        return
    end
    if not FindFreeSlot() then
        return
    end
    local eggs = DecodeAttr("Eggs", {})
    for _, egg in ipairs(eggs) do
        if TryIncubateEgg(egg) then
            return
        end
        task.wait(1)
    end
end

task.spawn(function()
    while Gen == getgenv().VoltGen do
        task.wait(4)
        if State.AutoTrade then
            pcall(TryTradeOnce)
        end
    end
end)

task.spawn(function()
    task.wait(2)
    while Gen == getgenv().VoltGen do
        task.wait(4)
        if State.AutoIncubate then
            pcall(TryIncubateOnce)
        end
    end
end)

local function TryHatchOnce()
    if not State.AutoHatch then
        return
    end
    local slots = DecodeAttr("Incubators", {})
    local now = os.time()
    for i, slot in ipairs(slots) do
        if type(slot) == "table" and slot.Id and (slot.Ends or 0) <= now then
            local shop = FTD:WaitForChild("Remotes")
            local res = nil
            local ok = pcall(function()
                res = shop.LabRequest:InvokeServer("Hatch", i)
            end)
            if ok and res and res.reason == "Slow down" then
                task.wait(5)
                return
            end
            if ok and res and res.ok then
                return
            end
            task.wait(1)
        end
    end
end

local ZonePresets = {
    PacificDeep = Vector3.new(-4300, -150, -150),
}

-- live positions: the map moves between updates, so read them from the game instead of hardcoding
local function NessiePillarPos()
    local pos = nil
    local function look()
        pcall(function()
            local map = workspace:FindFirstChild("Map")
            local myst = map and map:FindFirstChild("Mystery", true)
            local pil = myst and myst:FindFirstChild("Pillar", true)
            local pp = pil and pil:FindFirstChild("PromptPart", true)
            if pp and pp:IsA("BasePart") then
                pos = pp.Position
            end
        end)
    end
    look()
    if pos then
        return pos
    end
    -- streaming: the pillar is unloaded when far away, so ask for it and read the real position
    local anchor = nil
    pcall(function()
        anchor = FTD:GetAttribute("NessieCenter")
    end)
    if not anchor then
        anchor = Vector3.new(4736, 0, 4224)
    end
    pcall(function()
        LocalPlayer:RequestStreamAroundAsync(anchor, 5)
    end)
    local t0 = os.clock()
    while os.clock() - t0 < 6 do
        look()
        if pos then
            break
        end
        task.wait(0.25)
    end
    return pos
end

local function WhirlpoolPos()
    local pos = nil
    pcall(function()
        local fp = workspace:FindFirstChild("FTD_Pacific")
        local dp = fp and fp:FindFirstChild("DivePrompt")
        local part = dp and (dp:IsA("BasePart") and dp or dp:FindFirstChildWhichIsA("BasePart", true))
        if part then
            pos = part.Position
        end
    end)
    return pos
end

local function ResolvePreset(zoneKey)
    if zoneKey == "NessiePillar" then
        return NessiePillarPos()
    end
    if zoneKey == "Whirlpool" then
        return WhirlpoolPos()
    end
    return ZonePresets[zoneKey]
end

local function SafeTeleportZone(zoneKey)
    local cx, cz, hoverY = nil, nil, 120
    local pre = ResolvePreset(zoneKey)
    if pre then
        local hrp0 = GetHRP()
        if not hrp0 then
            return false
        end
        hrp0.AssemblyLinearVelocity = Vector3.zero
        hrp0.AssemblyAngularVelocity = Vector3.zero
        hrp0.CFrame = CFrame.new(pre)
        return true
    end
    if zoneKey == "Ranch" then
        pcall(function()
            local id = LocalPlayer:GetAttribute("RanchId") or 1
            local ranches = workspace:FindFirstChild("Map")
            ranches = ranches and ranches:FindFirstChild("Ranches")
            local mine = ranches and ranches:FindFirstChild("Ranch" .. tostring(id))
            if mine then
                local pv = mine:GetPivot()
                cx, cz = pv.Position.X, pv.Position.Z
            end
        end)
    else
        pcall(function()
            local z = Config.Zones and Config.Zones[zoneKey]
            if z and z.Center then
                cx, cz = z.Center.x, z.Center.z
            end
        end)
    end
    if not cx then
        return false
    end
    if zoneKey == "Spires" then
        hoverY = 850
    end
    local hrp = GetHRP()
    if not hrp then
        return false
    end
    local home = hrp.CFrame
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { workspace:FindFirstChild("Map") }
    local groundY = nil
    for _ = 1, 50 do
        local h = GetHRP()
        if not h then
            break
        end
        h.AssemblyLinearVelocity = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero
        h.CFrame = CFrame.new(cx, hoverY, cz)
        local ok, hit = pcall(function()
            return workspace:Raycast(Vector3.new(cx, hoverY, cz), Vector3.new(0, -(hoverY + 100), 0), params)
        end)
        if ok and hit and hit.Position.Y > -5 then
            groundY = hit.Position.Y
            break
        end
        task.wait(0.2)
    end
    local final = GetHRP()
    if groundY and final then
        final.AssemblyLinearVelocity = Vector3.zero
        final.AssemblyAngularVelocity = Vector3.zero
        final.CFrame = CFrame.new(cx, groundY + 3, cz)
        return true
    end
    if final then
        final.CFrame = home
    end
    return false
end

task.spawn(function()
    task.wait(3)
    while Gen == getgenv().VoltGen do
        task.wait(5)
        if State.AutoHatch then
            pcall(TryHatchOnce)
        end
    end
end)

local function NextLockedIncubator()
    local unlocked = DecodeAttr("IncUnlocked", {})
    local cfg = Config.Incubators or {}
    local prices = cfg.CoinPrice or {}
    local count = cfg.Count or #unlocked
    for i = 1, count do
        if unlocked[i] ~= true and prices[i] then
            return i
        end
    end
    return nil
end

local function TryBuyIncubator()
    local slot = NextLockedIncubator()
    if not slot then
        return
    end
    local cfg = Config.Incubators or {}
    local price = cfg.CoinPrice and cfg.CoinPrice[slot]
    if not price then
        return
    end
    local coins = LocalPlayer:GetAttribute("Coins") or 0
    if coins < price then
        return
    end
    local shop = FTD:WaitForChild("Remotes")
    local res = nil
    local ok = pcall(function()
        res = shop.LabRequest:InvokeServer("BuyIncubator", slot)
    end)
    if ok and res and res.ok then
        Win:Notify({
            Title = "VoltScriptZ",
            Text = "Unlocked incubator " .. slot,
            Duration = 5
        })
    end
end

task.spawn(function()
    task.wait(3)
    while Gen == getgenv().VoltGen do
        task.wait(5)
        if State.AutoBuyIncubators then
            pcall(TryBuyIncubator)
        end
    end
end)

local RarityScore = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6 }

local function BestStored()
    local list = DecodeAttr("Creatures", {})
    local best, bestScore, bestFrac = nil, 0, -1
    for _, dino in ipairs(list) do
        if type(dino) == "table" and dino.Placed ~= true and dino.Id and dino.Species then
            local cr = Config.Creatures and Config.Creatures[dino.Species]
            local score = RarityScore[cr and cr.Rarity] or 0
            local frac = dino.Frac or 0
            if score > bestScore or (score == bestScore and frac > bestFrac) then
                best, bestScore, bestFrac = dino, score, frac
            end
        end
    end
    return best
end

local function TryPlaceOnce()
    if not State.AutoPlace then
        return
    end
    local list = DecodeAttr("Creatures", {})
    local placed = 0
    for _, dino in ipairs(list) do
        if type(dino) == "table" and dino.Placed == true then
            placed = placed + 1
        end
    end
    local cap = tonumber(LocalPlayer:GetAttribute("RanchCap")) or 8
    if placed >= cap then
        return
    end
    local best = BestStored()
    if not best then
        return
    end
    local shop = FTD:WaitForChild("Remotes")
    pcall(function()
        shop.RanchRequest:InvokeServer("Place", best.Id)
    end)
end

task.spawn(function()
    task.wait(4)
    while Gen == getgenv().VoltGen do
        task.wait(6)
        if State.AutoPlace then
            pcall(TryPlaceOnce)
        end
    end
end)

local FoodPrice = { Meat = 12, Veggies = 8 }
local FoodPacks = { 50, 10, 1 }

local function FoodStock()
    local stock = DecodeAttr("Food", {})
    return {
        Meat = stock.Meat or 0,
        Veggies = stock.Veggies or 0,
    }
end

local function WantedFoods()
    if State.BuyFood == "Meat" then
        return { "Meat" }
    elseif State.BuyFood == "Veggies" then
        return { "Veggies" }
    elseif State.BuyFood == "Fish" then
        return {}
    end
    return { "Meat", "Veggies" }
end

local function TryBuyFoodOnce()
    if not State.AutoBuyFood then
        return
    end
    local stock = FoodStock()
    local coins = LocalPlayer:GetAttribute("Coins") or 0
    for _, item in ipairs(WantedFoods()) do
        local have = stock[item] or 0
        local want = (State.BuyLimit or 50) - have
        if want > 0 then
            for _, pack in ipairs(FoodPacks) do
                if pack <= want and coins >= (FoodPrice[item] or 0) * pack and have + pack <= 999 then
                    local shop = FTD:WaitForChild("Remotes")
                    local res = nil
                    local ok = pcall(function()
                        res = shop.FeedRequest:InvokeServer("Buy", item, pack)
                    end)
                    if ok and res and res.reason == "Slow down" then
                        task.wait(5)
                    end
                    return
                end
            end
        end
    end
end

local CheapestFish -- forward: defined after FishCounts
local function PickFood(species, stock)
    local menu = nil
    pcall(function()
        menu = require(FTD.DinoLife).Menu(species)
    end)
    if type(menu) == "table" then
        for _, m in ipairs(menu) do
            if m == "Fish" then
                local f = CheapestFish()
                if f then
                    return f
                end
            elseif State.BuyFood ~= "Fish" and (m == "Veggies" or m == "Meat") and (stock[m] or 0) > 0 then
                return m
            end
        end
    elseif State.BuyFood ~= "Fish" and (stock.Meat or 0) > 0 then
        return "Meat"
    end
    return nil
end

local function LiveFed(dino)
    local fed = dino.Fed or 1
    pcall(function()
        local now = workspace:GetServerTimeNow()
        local _, live = require(FTD.DinoLife).Now(dino, now, true)
        if type(live) == "number" then
            fed = live
        end
    end)
    return fed
end

local function IsElder(dino)
    local elder = false
    pcall(function()
        local now = workspace:GetServerTimeNow()
        local DL = require(FTD.DinoLife)
        local growth = DL.Now(dino, now, true)
        if DL.StageOf(dino.Species, growth) >= 5 then
            elder = true
        end
    end)
    return elder
end

local FeedHold = {}
local FeedHoldTime = 2

local function TryFeedOnce()
    if not State.AutoFeed then
        return
    end
    local list = DecodeAttr("Creatures", {})
    local stock = FoodStock()
    for _, dino in ipairs(list) do
        if not State.AutoFeed then
            return
        end
        local dinoId = type(dino) == "table" and dino.Id or nil
        local held = dinoId and FeedHold[tostring(dinoId)] or nil
        if dinoId and dino.Placed == true and not IsElder(dino) and LiveFed(dino) < 0.6 and not (held and os.clock() - held < FeedHoldTime) then
            local item = dino.Species and PickFood(dino.Species, stock)
            if item then
                local shop = FTD:WaitForChild("Remotes")
                local res = nil
                local ok = pcall(function()
                    res = shop.RanchRequest:InvokeServer("Feed", dinoId, item)
                end)
                if ok and res and res.ok then
                    FeedHold[tostring(dinoId)] = os.clock()
                    stock = FoodStock()
                elseif ok and res and res.reason == "Slow down" then
                    task.wait(1.2)
                    return
                end
            end
        end
    end
end

task.spawn(function()
    task.wait(5)
    while Gen == getgenv().VoltGen do
        task.wait(6)
        if State.AutoBuyFood then
            pcall(TryBuyFoodOnce)
        end
    end
end)

task.spawn(function()
    task.wait(2)
    while Gen == getgenv().VoltGen do
        task.wait(1)
        if State.AutoFeed then
            pcall(TryFeedOnce)
        end
    end
end)

local function FishCounts()
    local raw = DecodeAttr("Fish", nil)
    local counts = {}
    if type(raw) == "table" then
        if #raw > 0 then
            for _, sp in ipairs(raw) do
                counts[sp] = (counts[sp] or 0) + 1
            end
        else
            for sp, n in pairs(raw) do
                if type(n) == "number" and n > 0 then
                    counts[sp] = n
                end
            end
        end
    end
    return counts
end

CheapestFish = function()
    local counts = FishCounts()
    local best, bestPrice = nil, math.huge
    local defs = Config.Fish or {}
    for species, n in pairs(counts) do
        if type(n) == "number" and n > 0 then
            local def = defs[species]
            local price = (def and def.Price) or math.huge
            if price < bestPrice then
                best, bestPrice = species, price
            end
        end
    end
    return best
end

local function FilterIsAll(filter)
    filter = NormFilter(filter)
    if filter == nil or filter == "All" then
        return true
    end
    if type(filter) == "table" then
        if #filter == 0 then
            return true
        end
        for _, r in ipairs(filter) do
            if r == "All" then
                return true
            end
        end
    end
    return false
end

local function TrySellOnce()
    if not State.AutoSell then
        return
    end
    local shop = FTD:WaitForChild("Remotes")
    local function sell(kind, id, qty)
        local res = nil
        local ok = pcall(function()
            res = shop.SellRequest:InvokeServer(kind, id, qty)
        end)
        if ok and res and res.reason == "Slow down" then
            task.wait(5)
            return "slow"
        end
        return (ok and res and res.ok) and "ok" or "fail"
    end
    for _, species in ipairs(Config.CreatureOrder or {}) do
        local cr = Config.Creatures and Config.Creatures[species]
        if cr and RarityOk(cr.Rarity, State.FossilRarity) then
            local n = FossilCount(species)
            if n > 0 then
                sell("Fossil", species, n)
                return
            end
        end
    end
    local fish = FishCounts()
    local hasFish = false
    for _ in pairs(fish) do
        hasFish = true
        break
    end
    if hasFish then
        if FilterIsAll(State.FishRarity) then
            sell("AllFish")
            return
        end
        for _, sp in ipairs(Config.FishOrder or {}) do
            local fdef = Config.Fish and Config.Fish[sp]
            if fish[sp] and fdef and RarityOk(fdef.Rarity, State.FishRarity) then
                sell("Fish", sp, fish[sp])
                return
            end
        end
    end
    local eggs = DecodeAttr("Eggs", {})
    if #eggs > 0 then
        local bySpecies = {}
        for _, egg in ipairs(eggs) do
            if type(egg) == "table" and egg.Species then
                bySpecies[egg.Species] = (bySpecies[egg.Species] or 0) + 1
            end
        end
        for species, n in pairs(bySpecies) do
            local cr = Config.Creatures and Config.Creatures[species]
            if cr and RarityOk(cr.Rarity, State.SellEggRarity) then
                sell("Egg", species, n)
                return
            end
        end
    end
    local dinos = DecodeAttr("Creatures", {})
    for _, dino in ipairs(dinos) do
        if type(dino) == "table" and dino.Placed ~= true and dino.Id and dino.Species then
            local cr = Config.Creatures and Config.Creatures[dino.Species]
            if cr and RarityOk(cr.Rarity, State.DinoRarity) then
                sell("Dino", dino.Id)
                return
            end
        end
    end
end

task.spawn(function()
    task.wait(1)
    while Gen == getgenv().VoltGen do
        task.wait(4)
        if State.AutoSell then
            pcall(TrySellOnce)
        end
    end
end)

local function EquipRod()
    local char = LocalPlayer.Character
    if not char then
        return false
    end
    if char:FindFirstChild("Rod") then
        return true
    end
    local pack = LocalPlayer:FindFirstChild("Backpack")
    local rod = pack and pack:FindFirstChild("Rod")
    if not rod then
        return false
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:EquipTool(rod)
        task.wait(0.3)
    end
    return char:FindFirstChild("Rod") ~= nil
end

local function WantedFishSet()
    local f = NormFilter(State.FishTarget)
    if f == nil or f == "All" then
        return nil
    end
    if type(f) == "table" then
        if #f == 0 then
            return nil
        end
        for _, r in ipairs(f) do
            if r == "All" then
                return nil
            end
        end
        local set = {}
        for _, r in ipairs(f) do
            set[r] = true
        end
        return set
    end
    return { [f] = true }
end

local function TryFishOnce()
    if not State.AutoFish then
        return
    end
    do
        local hrp = GetHRP()
        if hrp then
            hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(hrp.Position.X, hrp.Position.Y, 500))
        end
    end
    if not EquipRod() then
        return
    end
    local remotes = FTD:WaitForChild("Remotes")
    if (LocalPlayer:GetAttribute("Bait") or 0) <= 0 then
        if (LocalPlayer:GetAttribute("Coins") or 0) >= 5 then
            pcall(function()
                remotes.ShopRequest:InvokeServer("BuyBait")
            end)
            task.wait(2)
        end
        return
    end
    local cast = nil
    local remBefore = 0
    pcall(function()
        local d = game:GetService("HttpService"):JSONDecode(LocalPlayer:GetAttribute("Rudeus") or "")
        remBefore = tonumber(d and d.Remnants) or 0
    end)
    local wantPre = WantedFishSet()
    if wantPre == false then
        return
    end
    local ok = pcall(function()
        cast = remotes.FishRequest:InvokeServer("Cast", State.FishPower or 0.95)
    end)
    if not ok or type(cast) ~= "table" then
        return
    end
    if not cast.ok then
        if cast.reason == "Slow down" then
            task.wait(5)
        elseif cast.reason == "Already fishing" then
            task.wait(4)
        elseif cast.reason == "Cast into the open sea!" then
            task.wait(10)
        end
        return
    end
    if not cast.session then
        return
    end
    pcall(function()
        if State._fishDist and cast.dist then
            local txt = tostring(math.floor(cast.dist)) .. "m"
            if cast.depth then
                txt = txt .. " / " .. tostring(math.floor(cast.depth)) .. "m"
            end
            if cast.zone then
                txt = txt .. " " .. tostring(cast.zone)
            end
            State._fishDist:Set(txt)
        end
        if State._fishSt then
            State._fishSt:Set("cast ok")
        end
    end)
    task.wait(4)
    if not State.AutoFish then
        return
    end
    local land = nil
    local landOk = pcall(function()
        land = remotes.FishRequest:InvokeServer("Land", cast.session, 0)
    end)
    if not landOk or type(land) ~= "table" or not land.ok then
        if land and land.reason == "Slow down" then
            task.wait(5)
        end
        return
    end
    local hooks = land.hooks or 3
    local want = WantedFishSet()
    local picks = {}
    if type(land.fish) == "table" then
        for _, f in ipairs(land.fish) do
            if #picks >= hooks then
                break
            end
            if f.t == "remnant" and f.i then
                table.insert(picks, f.i)
            end
        end
        for _, f in ipairs(land.fish) do
            if #picks >= hooks then
                break
            end
            if f.t == "fish" and f.i and f.id and (want == nil or want[f.id]) then
                table.insert(picks, f.i)
            end
        end
    end
    task.wait(3)
    if not State.AutoFish then
        return
    end
    local finOk, finRes = pcall(function()
        return remotes.FishRequest:InvokeServer("Finish", cast.session, picks)
    end)
    if finOk and finRes and finRes.ok then
        pcall(function()
            local d = game:GetService("HttpService"):JSONDecode(LocalPlayer:GetAttribute("Rudeus") or "")
            local remAfter = tonumber(d and d.Remnants) or 0
            if remAfter > remBefore then
                WebhookSend("✨ Raptor X Remnant ติด (" .. tostring(remAfter) .. "/5)")
            end
        end)
    end
end

task.spawn(function()
    task.wait(2)
    while Gen == getgenv().VoltGen do
        task.wait(4)
        if State.AutoFish then
            pcall(TryFishOnce)
        end
    end
end)

local NestOrder = { "Triassic", "Jurassic", "Cretaceous" }
local LastNestEvent = nil

pcall(function()
    FTD:WaitForChild("Remotes"):WaitForChild("NestEvent").OnClientEvent:Connect(function(kind, a, b, c)
        LastNestEvent = { Kind = kind, A = a, B = b, C = c }
    end)
end)

local BossResultNames = { BossEvent = "Mosasaurus", NessieEvent = "Nessie", RaptorEvent = "Raptor X", TrueEvent = "True" }
for remoteName, bossLabel in pairs(BossResultNames) do
    pcall(function()
        FTD:WaitForChild("Remotes"):WaitForChild(remoteName).OnClientEvent:Connect(function(kind, a, b)
            if kind == "Result" then
                local s = ""
                pcall(function()
                    s = game:GetService("HttpService"):JSONEncode(a)
                    if #s > 250 then
                        s = s:sub(1, 250)
                    end
                end)
                WebhookSend("🏁 " .. bossLabel .. " จบแล้ว " .. s)
            end
        end)
    end)
end

local function NestTargets()
    if State.NestTarget == nil or State.NestTarget == "All" then
        return NestOrder
    end
    return { State.NestTarget }
end

local function NestEggsLeft(id)
    local maxEggs = 4
    pcall(function()
        maxEggs = Config.Nests and Config.Nests.Eggs or 4
    end)
    return math.max(0, maxEggs - (LocalPlayer:GetAttribute("Nest_" .. id) or 0))
end

local function WaitNestModel(id, timeout)
    local t0 = os.clock()
    while os.clock() - t0 < (timeout or 12) do
        if not State.AutoNest then
            return nil
        end
        local folder = workspace:FindFirstChild("FTD_Nests")
        local m = folder and folder:FindFirstChild("Nest_" .. id)
        if m then
            return m
        end
        task.wait(0.5)
    end
    return nil
end

local function NestPrompt(m)
    local nc = m:FindFirstChild("NestCenter", true)
    return nc and nc:FindFirstChildOfClass("ProximityPrompt") or nil
end

local function WaitStole(timeout)
    local t0 = os.clock()
    while os.clock() - t0 < timeout do
        if not State.AutoNest then
            return nil
        end
        if LastNestEvent and LastNestEvent.Kind == "Stole" then
            local e = LastNestEvent
            LastNestEvent = nil
            return e
        end
        task.wait(0.2)
    end
    return nil
end

local function WaitVerdict(timeout)
    local t0 = os.clock()
    while os.clock() - t0 < (timeout or 15) do
        if not State.AutoNest then
            return nil
        end
        if LastNestEvent then
            local k = LastNestEvent.Kind
            if k == "Escaped" or k == "Caught" or k == "Dropped" then
                local e = LastNestEvent
                LastNestEvent = nil
                return e
            end
        end
        task.wait(0.2)
    end
    return nil
end

local function GlideNestEscape(nestPos, dir, needDist, speed)
    local rs = nil
    pcall(function()
        rs = game:GetService("RunService")
    end)
    if not rs then
        return false
    end
    local t0 = os.clock()
    while os.clock() - t0 < 20 do
        if not State.AutoNest then
            return false
        end
        if LastNestEvent then
            local k = LastNestEvent.Kind
            if k == "Escaped" or k == "Caught" or k == "Dropped" then
                return true
            end
        end
        local dt = rs.Heartbeat:Wait()
        local h = GetHRP()
        if not h then
            return false
        end
        local flat = Vector3.new(h.Position.X - nestPos.X, 0, h.Position.Z - nestPos.Z)
        if flat.Magnitude >= needDist then
            return true
        end
        local step = dir * speed * math.min(dt, 0.1)
        local np = h.Position + step
        h.AssemblyLinearVelocity = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero
        h.CFrame = CFrame.lookAt(np, Vector3.new(np.X + dir.X, np.Y, np.Z + dir.Z))
    end
    return false
end

local function TryNestOnce(id)
    if not State.AutoNest then
        return "off"
    end
    if NestEggsLeft(id) <= 0 then
        return "skip"
    end
    local sitePos = nil
    pcall(function()
        sitePos = Config.Nests and Config.Nests.Sites and Config.Nests.Sites[id] and Config.Nests.Sites[id].Pos
    end)
    if not sitePos then
        return "fail"
    end
    do
        local hrp0 = GetHRP()
        local dir0 = Vector3.new(4, 0, 0)
        if hrp0 then
            local d = Vector3.new(hrp0.Position.X - sitePos.X, 0, hrp0.Position.Z - sitePos.Z)
            if d.Magnitude >= 0.1 then
                dir0 = d.Unit
            end
        end
        Teleport(sitePos + dir0 * 20 + Vector3.new(0, 3, 0), sitePos)
    end
    if not State.AutoNest then
        return "off"
    end
    local m = WaitNestModel(id, 12)
    if not m then
        return "fail"
    end
    local nestPos = sitePos
    pcall(function()
        nestPos = m:GetAttribute("Pos") or nestPos
    end)
    if not nestPos then
        return "fail"
    end
    local pr = NestPrompt(m)
    if not pr or not pr.Enabled then
        if NestEggsLeft(id) <= 0 then
            return "skip"
        end
        return "fail"
    end
    local hrp = GetHRP()
    if not hrp then
        return "fail"
    end
    local dir = Vector3.new(hrp.Position.X - nestPos.X, 0, hrp.Position.Z - nestPos.Z)
    if dir.Magnitude < 0.1 then
        dir = Vector3.new(4, 0, 0)
    end
    dir = dir.Unit
    Teleport(nestPos + dir * 20 + Vector3.new(0, 3, 0), nestPos)
    task.wait(0.6)
    LastNestEvent = nil
    pcall(function()
        fireproximityprompt(pr)
    end)
    local stole = WaitStole(12)
    if not stole then
        return "fail"
    end
    local h2 = GetHRP()
    if not h2 then
        return "fail"
    end
    local away = Vector3.new(h2.Position.X - nestPos.X, 0, h2.Position.Z - nestPos.Z)
    if away.Magnitude < 0.1 then
        away = Vector3.new(4, 0, 0)
    end
    away = away.Unit
    LastNestEvent = nil
    local leash = tonumber(stole.C) or 200
    GlideNestEscape(nestPos, away, leash + 20, 70)
    local verdict = WaitVerdict(15)
    if verdict and verdict.Kind == "Escaped" then
        return "escaped"
    end
    if verdict then
        return string.lower(tostring(verdict.Kind))
    end
    return "fail"
end

task.spawn(function()
    task.wait(2)
    while Gen == getgenv().VoltGen do
        if State.AutoNest then
            pcall(function()
                for _, id in ipairs(NestTargets()) do
                    if not State.AutoNest then
                        break
                    end
                    TryNestOnce(id)
                end
            end)
            task.wait()
        else
            task.wait(0.5)
        end
    end
end)


local function DigPartnerId()
    return tonumber(LocalPlayer:GetAttribute("PartnerId")) or 0
end

local function DismissPartnerForDig()
    if State._savedPartnerId then
        return
    end
    local pid = DigPartnerId()
    if pid == 0 then
        return
    end
    State._savedPartnerId = pid
    State._fightRestored = false
    pcall(function()
        FTD:WaitForChild("Remotes").RanchRequest:InvokeServer("Partner", pid)
    end)
end

local function RestorePartnerAfterDig()
    local saved = State._savedPartnerId
    State._savedPartnerId = nil
    State._fightRestored = false
    if not saved or saved == 0 then
        return
    end
    if DigPartnerId() ~= 0 then
        return
    end
    pcall(function()
        FTD:WaitForChild("Remotes").RanchRequest:InvokeServer("Partner", saved)
    end)
end

DigCard:AddToggle({
    Name = "Auto Dig",
    Name = "Auto Dig",    Flag = "DigCard_AutoDig",
    Default = false,
    Callback = function(v)
        State.AutoDig = v
        if v then
            task.spawn(DismissPartnerForDig)
        else
            task.spawn(RestorePartnerAfterDig)
        end
    end
})

DigCard:AddDropdown({
    Name = "Dig Islands",
    Name = "Dig Islands",    Flag = "DigCard_DigIslands",
    Options = { "Auto", "Cambrian", "Devonian", "Triassic", "Jurassic", "Cretaceous", "LateCretaceous", "Pacific" },
    Default = "Auto",
    Callback = function(v)
        State.DigIsland = v
    end
})

DigCard:AddDropdown({
    Name = "Dig Quality",
    Name = "Dig Quality",    Flag = "DigCard_DigQuality",
    Options = { "Perfect", "Great", "Good", "Weak" },
    Default = "Perfect",
    Callback = function(v)
        State.DigQuality = v
    end
})

DigCard:AddToggle({
    Name = "Auto Buy Shovels",
    Name = "Auto Buy Shovels",    Flag = "DigCard_AutoBuyShovels",
    Default = false,
    Callback = function(v)
        State.AutoBuyShovels = v
    end
})

local LabCard = MainTab:AddCard({
    Title = "Auto Lab",
    Subtitle = "Trade fossils and hatch eggs",
    Toggle = false,
    Column = 2,
})

LabCard:AddToggle({
    Name = "Trade Fossils",
    Name = "Trade Fossils",    Flag = "LabCard_TradeFossils",
    Default = false,
    Callback = function(v)
        State.AutoTrade = v
    end
})

LabCard:AddDropdown({
    Name = "Fossils Rarity",
    Name = "Fossils Rarity",    Flag = "LabCard_FossilsRarity",
    Options = { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" },
    Default = { "All" },
    Multi = true,
    Callback = function(v)
        State.TradeRarity = v
    end
})

LabCard:AddToggle({
    Name = "Incubate",
    Name = "Incubate",    Flag = "LabCard_Incubate",
    Default = false,
    Callback = function(v)
        State.AutoIncubate = v
    end
})

LabCard:AddDropdown({
    Name = "Egg Rarity",
    Name = "Egg Rarity",    Flag = "LabCard_EggRarity",
    Options = { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" },
    Default = { "All" },
    Multi = true,
    Callback = function(v)
        State.EggRarity = v
    end
})

LabCard:AddToggle({
    Name = "Buy Incubators",
    Name = "Buy Incubators",    Flag = "LabCard_BuyIncubators",
    Default = false,
    Callback = function(v)
        State.AutoBuyIncubators = v
    end
})

LabCard:AddToggle({
    Name = "Hatch",
    Name = "Hatch",    Flag = "LabCard_Hatch",
    Default = false,
    Callback = function(v)
        State.AutoHatch = v
    end
})

LabCard:AddToggle({
    Name = "Place Best",
    Name = "Place Best",    Flag = "LabCard_PlaceBest",
    Default = false,
    Callback = function(v)
        State.AutoPlace = v
    end
})

local TpCard = MainTab:AddCard({
    Title = "Teleport",
    Subtitle = "Travel between islands",
    Toggle = false,
    Column = 1,
})

TpCard:AddDropdown({
    Name = "Zone",
    Name = "Zone",    Flag = "TpCard_Zone",
    Options = { "Ranch", "Cambrian", "Devonian", "Triassic", "Jurassic", "Cretaceous", "Auction", "Spires", "LateCretaceous", "Blackgate", "PacificDeep", "Whirlpool", "NessiePillar" },
    Default = "Ranch",
    Callback = function(v)
        State.TeleportZone = v
    end
})

TpCard:AddButton({
    Name = "Go",
    Callback = function()
        if State.Teleporting then
            return
        end
        State.Teleporting = true
        pcall(SafeTeleportZone, State.TeleportZone)
        State.Teleporting = false
    end
})

local FishCard = MainTab:AddCard({
    Title = "Fishing",
    Subtitle = "Catch fish automatically",
    Toggle = false,
    Column = 2,
})

FishCard:AddToggle({
    Name = "Auto Fish",
    Name = "Auto Fish",    Flag = "FishCard_AutoFish",
    Default = false,
    Callback = function(v)
        State.AutoFish = v
    end
})

FishCard:AddDropdown({
    Name = "Fish Target",
    Name = "Fish Target",    Flag = "FishCard_FishTarget",
    Options = { "All", "Sardine", "Knightia", "Mackerel", "HorseshoeCrab", "Ammonite", "Belemnite", "Lepidotes", "Pufferfish", "Nautilus", "Cephalaspis", "Orthoceras", "Swordfish", "Eurypterid", "Stethacanthus", "Helicoprion", "Coelacanth", "Onchopristis", "Leedsichthys", "GoldenAmmonite" },
    Default = { "All" },
    Multi = true,
    Callback = function(v)
        State.FishTarget = v
    end
})

FishCard:AddSlider({
    Name = "Cast Power",
    Name = "Cast Power",    Flag = "FishCard_CastPower",
    Min = 10,
    Max = 100,
    Increment = 5,
    Default = 95,
    Callback = function(v)
        State.FishPower = v / 100
    end
})

State._fishDist = FishCard:AddInfo({ Text = "Distance", Value = "-" })
State._fishSt = FishCard:AddInfo({ Text = "Status", Value = "idle" })

local WebhookCard = WebhookTab:AddCard({
    Title = "Webhook",
    Subtitle = "Discord notifications",
    Toggle = false,
    Column = 1,
})

WebhookCard:AddToggle({
    Name = "Enabled",
    Name = "Enabled",    Flag = "WebhookCard_Enabled",
    Default = true,
    Callback = function(v)
        State.WebhookOn = v
    end
})

do
    local urlBox = Instance.new("TextBox")
    urlBox.Size = UDim2.new(1, 0, 0, 28)
    urlBox.BackgroundColor3 = Color3.fromRGB(13, 10, 26)
    urlBox.Text = ""
    urlBox.PlaceholderText = "Enter Webhook Url"
    urlBox.Font = Enum.Font.BuilderSansMedium
    urlBox.TextSize = 13
    urlBox.TextColor3 = Color3.fromRGB(242, 238, 255)
    urlBox.PlaceholderColor3 = Color3.fromRGB(165, 155, 205)
    urlBox.TextXAlignment = Enum.TextXAlignment.Left
    urlBox.ClearTextOnFocus = false
    urlBox.LayoutOrder = 1
    urlBox.Parent = WebhookCard.Body
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = urlBox
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = urlBox
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(44, 33, 82)
    stroke.Thickness = 1
    stroke.Parent = urlBox
    urlBox.FocusLost:Connect(function()
        State.WebhookURL = urlBox.Text
    end)
end

WebhookCard:AddButton({
    Name = "Test Webhook",
    Callback = function()
        WebhookSend("🔔 ทดสอบ webhook")
    end
})

local WebhookNotes = WebhookTab:AddCard({
    Title = "Webhook Notes",
    Toggle = false,
    Column = 2,
})

WebhookNotes:AddLabel("Every message starts with name + online time.\nBoss spawned (Mosa / Nessie / Raptor X / True, no toggle needed)\nBoss fight ended + rewards (Result)\nRaptor X Remnant caught (n/5)\nNessie Fragment collected (n/12)")

local NestCard = MainTab:AddCard({
    Title = "Steal Nest",
    Subtitle = "Steal eggs from nests",
    Toggle = false,
    Column = 1,
})

NestCard:AddToggle({
    Name = "Auto Nest",
    Name = "Auto Nest",    Flag = "NestCard_AutoNest",
    Default = false,
    Callback = function(v)
        State.AutoNest = v
    end
})

NestCard:AddDropdown({
    Name = "Nest Target",
    Name = "Nest Target",    Flag = "NestCard_NestTarget",
    Options = { "All", "Triassic", "Jurassic", "Cretaceous" },
    Default = "All",
    Callback = function(v)
        State.NestTarget = v
    end
})

local BossCard = BossTab:AddCard({
    Title = "Mosasaurus",
    Subtitle = "Teleport to Mosasaurus arena",
    Toggle = false,
    Column = 1,
})

BossCard:AddToggle({
    Name = "Auto Mosa",
    Name = "Auto Mosa",    Flag = "BossCard_AutoMosa",
    Default = false,
    Callback = function(v)
        State.AutoBoss = v
    end
})

BossCard:AddDropdown({
    Name = "Target Part",
    Name = "Target Part",    Flag = "BossCard_TargetPart",
    Options = { "Head", "Body" },
    Default = "Head",
    Callback = function(v)
        State.BossAim = v
    end
})

BossCard:AddDropdown({
    Name = "Mode",
    Name = "Mode",    Flag = "BossCard_Mode",
    Options = { "Throw", "Ride" },
    Default = "Throw",
    Callback = function(v)
        State.BossMode = v
    end
})

BossCard:AddSlider({
    Name = "Height Offset",
    Name = "Height Offset",    Flag = "BossCard_HeightOffset",
    Min = -90,
    Max = 90,
    Increment = 1,
    Default = 0,
    Callback = function(v)
        State.MosaH = v
    end
})

State._mosaHp = BossCard:AddInfo({ Text = "HP", Value = "-" })
State._mosaSt = BossCard:AddInfo({ Text = "Status", Value = "idle" })
State._mosaCd = BossCard:AddInfo({ Text = "Spawn In", Value = "-" })

local NessieCard = BossTab:AddCard({
    Title = "Nessie",
    Subtitle = "Summon and fight Nessie",
    Toggle = false,
    Column = 2,
})

NessieCard:AddToggle({
    Name = "Auto Nessie",
    Name = "Auto Nessie",    Flag = "NessieCard_AutoNessie",
    Default = false,
    Callback = function(v)
        State.AutoNessie = v
    end
})

NessieCard:AddToggle({
    Name = "Auto Summon",
    Name = "Auto Summon",    Flag = "NessieCard_AutoSummon",
    Default = false,
    Callback = function(v)
        State.AutoSummon = v
    end
})

NessieCard:AddToggle({
    Name = "Auto Farm Fragments",
    Name = "Auto Farm Fragments",    Flag = "NessieCard_AutoFarmFragments",
    Default = false,
    Callback = function(v)
        State.AutoFarmFrag = v
    end
})

NessieCard:AddDropdown({
    Name = "Target Part",
    Name = "Target Part",    Flag = "NessieCard_TargetPart",
    Options = { "Head", "Body" },
    Default = "Head",
    Callback = function(v)
        State.NessieAim = v
    end
})

NessieCard:AddDropdown({
    Name = "Mode",
    Name = "Mode",    Flag = "NessieCard_Mode",
    Options = { "Throw", "Ride" },
    Default = "Throw",
    Callback = function(v)
        State.NessieMode = v
    end
})

NessieCard:AddSlider({
    Name = "Height Offset",
    Name = "Height Offset",    Flag = "NessieCard_HeightOffset",
    Min = -90,
    Max = 90,
    Increment = 1,
    Default = 0,
    Callback = function(v)
        State.NessieH = v
    end
})

State._nessieHp = NessieCard:AddInfo({ Text = "HP", Value = "-" })
State._nessieSt = NessieCard:AddInfo({ Text = "Status", Value = "idle" })

local RaptorCard = BossTab:AddCard({
    Title = "Raptor",
    Subtitle = "Fight Raptor boss",
    Toggle = false,
    Column = 1,
})

RaptorCard:AddToggle({
    Name = "Auto Raptor",
    Name = "Auto Raptor",    Flag = "RaptorCard_AutoRaptor",
    Default = false,
    Callback = function(v)
        State.AutoRaptor = v
    end
})

RaptorCard:AddToggle({
    Name = "Auto Summon",
    Flag = "RaptorCard_AutoSummon",
    Default = false,
    Callback = function(v)
        State.AutoRaptorSummon = v
    end
})

RaptorCard:AddToggle({
    Name = "Auto Hop",
    Flag = "RaptorCard_AutoHop",
    Default = false,
    Callback = function(v)
        State.AutoHopRaptor = v
        if not v then
            State._hopCount = 0
            State._hopNext = 0
            if State._raptorHop then
                pcall(function()
                    State._raptorHop:Set("-")
                end)
            end
        end
    end
})

RaptorCard:AddDropdown({
    Name = "Target Part",
    Name = "Target Part",    Flag = "RaptorCard_TargetPart",
    Options = { "Head", "Body" },
    Default = "Head",
    Callback = function(v)
        State.RaptorAim = v
    end
})

RaptorCard:AddDropdown({
    Name = "Mode",
    Name = "Mode",    Flag = "RaptorCard_Mode",
    Options = { "Throw", "Ride" },
    Default = "Throw",
    Callback = function(v)
        State.RaptorMode = v
    end
})

RaptorCard:AddSlider({
    Name = "Height Offset",
    Name = "Height Offset",    Flag = "RaptorCard_HeightOffset",
    Min = -90,
    Max = 90,
    Increment = 1,
    Default = 0,
    Callback = function(v)
        State.RaptorH = v
    end
})

State._raptorHp = RaptorCard:AddInfo({ Text = "HP", Value = "-" })
State._raptorSt = RaptorCard:AddInfo({ Text = "Status", Value = "idle" })
State._raptorCd = RaptorCard:AddInfo({ Text = "Key Ready In", Value = "-" })
State._raptorHop = RaptorCard:AddInfo({ Text = "Hop", Value = "-" })

local TrueCard = BossTab:AddCard({
    Title = "True",
    Subtitle = "Fight True boss rotation",
    Toggle = false,
    Column = 2,
})

TrueCard:AddToggle({
    Name = "Auto True",
    Name = "Auto True",    Flag = "TrueCard_AutoTrue",
    Default = false,
    Callback = function(v)
        State.AutoTrue = v
    end
})

TrueCard:AddDropdown({
    Name = "Target Part",
    Name = "Target Part",    Flag = "TrueCard_TargetPart",
    Options = { "Head", "Body" },
    Default = "Head",
    Callback = function(v)
        State.TrueAim = v
    end
})

TrueCard:AddDropdown({
    Name = "Mode",
    Name = "Mode",    Flag = "TrueCard_Mode",
    Options = { "Throw", "Ride" },
    Default = "Throw",
    Callback = function(v)
        State.TrueMode = v
    end
})

TrueCard:AddSlider({
    Name = "Height Offset",
    Name = "Height Offset",    Flag = "TrueCard_HeightOffset",
    Min = -90,
    Max = 90,
    Increment = 1,
    Default = 0,
    Callback = function(v)
        State.TrueH = v
    end
})

State._trueHp = TrueCard:AddInfo({ Text = "HP", Value = "-" })
State._trueSt = TrueCard:AddInfo({ Text = "Status", Value = "idle" })
State._trueCd = TrueCard:AddInfo({ Text = "Spawn In", Value = "-" })
State._trueNext = TrueCard:AddInfo({ Text = "Next", Value = "-" })

local DinoCombatCache = nil
local function BossHeadPos(key)
    if DinoCombatCache == nil then
        pcall(function()
            DinoCombatCache = require(FTD:WaitForChild("DinoCombat"))
        end)
    end
    local DC = DinoCombatCache
    if not DC then
        return nil
    end
    local pos, look = nil, nil
    pcall(function()
        local b = DC.Bosses and DC.Bosses[key]
        if not b then
            return
        end
        if FTD:GetAttribute(b.state) ~= "Fight" then
            return
        end
        local cf = DC.BossPose(key, workspace:GetServerTimeNow())
        if not cf then
            return
        end
        local headPt = cf.Position + cf.LookVector * 50
        pos = headPt + Vector3.new(0, 30 + (State.MosaH or 0), 0)
        look = headPt
    end)
    if pos then
        return pos, look
    end
    return nil
end

local function MosaPose()
    if DinoCombatCache == nil then
        pcall(function()
            DinoCombatCache = require(FTD:WaitForChild("DinoCombat"))
        end)
    end
    local DC = DinoCombatCache
    if not DC then
        return nil
    end
    local cf = nil
    pcall(function()
        local b = DC.Bosses and DC.Bosses["Mosa"]
        if not b then
            return
        end
        if FTD:GetAttribute(b.state) ~= "Fight" then
            return
        end
        cf = DC.BossPose("Mosa", workspace:GetServerTimeNow())
    end)
    return cf
end

local function RidePC()
    local pc = nil
    pcall(function()
        pc = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("FTD_Controllers"):WaitForChild("PartnerController"))
    end)
    return pc
end

local function RideMounted()
    local pc = RidePC()
    if not pc then
        return false
    end
    local ok, r = pcall(function()
        return pc.IsRiding()
    end)
    return ok and r == true
end

local function RideEnsure()
    if RideMounted() then
        return true
    end
    local pc = RidePC()
    if not pc then
        return false
    end
    pcall(function()
        pc.Mount()
    end)
    local t0 = os.clock()
    while os.clock() - t0 < 3 do
        if RideMounted() then
            State._rideMounted = true
            return true
        end
        task.wait(0.2)
    end
    return RideMounted()
end

local function RideKeys(wDown)
    if wDown == State._wHeld then
        return
    end
    State._wHeld = wDown
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(wDown and true or false, Enum.KeyCode.W, false, game)
    end)
end

local function RideMelee(bossKey, idx)
    pcall(function()
        local PC = RidePC()
        if PC then
            PC.PlayAttack(LocalPlayer, idx)
        end
    end)
    pcall(function()
        FTD:WaitForChild("Remotes"):WaitForChild("PvEEvent"):FireServer("Swing", idx)
    end)
    task.wait(0.5)
    pcall(function()
        local DC2 = DinoCombatCache
        local b = DC2 and DC2.Bosses and DC2.Bosses[bossKey]
        if not b then
            return
        end
        if FTD:GetAttribute(b.state) ~= "Fight" then
            return
        end
        FTD:WaitForChild("Remotes"):WaitForChild("PvEEvent"):FireServer("Hit", bossKey, idx)
    end)
end

local function RideToBoss(poseFn)
    if RideMounted() then
        return true
    end
    PreTeleport()
    local cf = poseFn()
    if not cf then
        return false
    end
    -- staging: wait near boss WITHOUT heartbeat lock (gated until mounted)
    local hrp = GetHRP()
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(cf.Position + Vector3.new(0, 25, 0))
        local t0 = os.clock()
        while os.clock() - t0 < 10 do
            task.wait(0.5)
            local h = GetHRP()
            if not h then
                return false
            end
            local now = poseFn()
            if not now then
                return false
            end
            if (h.Position - now.Position).Magnitude < 60 then
                break
            end
        end
        task.wait(1)
    end
    local mounted = RideEnsure()
    if mounted then
        -- mounted: move above fresh boss pose, heartbeat lock takes over from here
        pcall(function()
            local now = poseFn()
            local h = GetHRP()
            if now and h then
                h.AssemblyLinearVelocity = Vector3.zero
                h.AssemblyAngularVelocity = Vector3.zero
                h.CFrame = CFrame.new(now.Position + Vector3.new(0, 25, 0))
            end
        end)
    end
    return mounted
end

local function RideStop()
    RideKeys(false)
    if State._rideMounted then
        State._rideMounted = false
        local pc = RidePC()
        if pc then
            pcall(function()
                pc.StopRide()
            end)
        end
    end
end

local BossHeadConn = nil
pcall(function()
    BossHeadConn = game:GetService("RunService").Heartbeat:Connect(function()
        if Gen ~= getgenv().VoltGen then
            if BossHeadConn then
                BossHeadConn:Disconnect()
                BossHeadConn = nil
            end
            return
        end
        if State.AutoBoss then
            if State.BossMode == "Ride" and not RideMounted() then
                return
            end
            if State.BossMode == "Ride" then
                local own = State.RideOwner and State.RideOwner()
                if own and own ~= "Mosa" then
                    return
                end
            end
            local ok, pos, look = pcall(BossHeadPos, "Mosa")
            if ok and pos then
                local hrp = GetHRP()
                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.CFrame = CFrame.lookAt(pos, look or Vector3.new(pos.X, pos.Y - 16, pos.Z))
                end
            end
        end
    end)
end)

local BossCtlCache = {}
local BossCtlNames = {
    Mosa = "BossController",
    Nessie = "NessieController",
    Raptor = "RaptorBossController",
    True = "TrueBossController",
}

local function BossThrow(key)
    local ctl = BossCtlCache[key]
    if ctl == nil then
        pcall(function()
            local folder = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("FTD_Controllers")
            local mod = folder and folder:FindFirstChild(BossCtlNames[key])
            if mod then
                ctl = require(mod)
            end
        end)
        BossCtlCache[key] = ctl or false
    end
    if State.BossAim == "Body" then
        pcall(function()
            if DinoCombatCache == nil then
                DinoCombatCache = require(FTD:WaitForChild("DinoCombat"))
            end
            local DC = DinoCombatCache
            local b = DC and DC.Bosses and DC.Bosses[key]
            if not b then
                return
            end
            if FTD:GetAttribute(b.state) ~= "Fight" then
                return
            end
            local cf = DC.BossPose(key, workspace:GetServerTimeNow())
            if not cf then
                return
            end
            local bodyPos = cf.Position - Vector3.new(0, 10, 0)
            if bodyPos.Y < 0 then
                bodyPos = Vector3.new(bodyPos.X, 0, bodyPos.Z)
            end
            FTD:WaitForChild("Remotes"):WaitForChild("BossEvent"):FireServer("Throw", bodyPos, nil)
        end)
    else
        if ctl and ctl.ThrowAuto then
            pcall(ctl.ThrowAuto)
        end
    end
end

local function EnsureSpear()
    local ch = LocalPlayer.Character
    if not ch then
        return false
    end
    for _, t in ipairs(ch:GetChildren()) do
        if t:IsA("Tool") and string.find(t.Name, "Spear") then
            return true
        end
    end
    local pack = LocalPlayer:FindFirstChild("Backpack")
    if pack then
        for _, t in ipairs(pack:GetChildren()) do
            if t:IsA("Tool") and string.find(t.Name, "Spear") then
                local hum = ch:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:EquipTool(t)
                    task.wait(0.4)
                end
                return ch:FindFirstChild(t.Name) ~= nil
            end
        end
    end
    return false
end

task.spawn(function()
    while Gen == getgenv().VoltGen do
        task.wait(1.5)
        local ok, fighting = pcall(function()
            local DC = DinoCombatCache
            if not DC then
                return false
            end
            local b = DC.Bosses and DC.Bosses["Mosa"]
            return b and FTD:GetAttribute(b.state) == "Fight"
        end)
        if fighting and State._mosaPrev ~= true then
            WebhookSend("🟢 Mosasaurus เกิดแล้ว")
        elseif not fighting and State._mosaPrev == true then
            WebhookSend("🏁 Mosasaurus จบแล้ว")
        end
        State._mosaPrev = (fighting and true) or false
        if State.AutoBoss then
            if ok and fighting then
                if State.BossMode == "Ride" then
                    local own = State.RideOwner and State.RideOwner()
                    if own and own ~= "Mosa" then
                        State.LastBoss = "wait " .. tostring(own)
                    elseif RideToBoss(MosaPose) then
                        State.LastBoss = "riding"
                    else
                        State.LastBoss = "riding: no mount"
                    end
                elseif EnsureSpear() then
                    State.LastBoss = "fighting"
                    BossThrow("Mosa")
                else
                    State.LastBoss = "fighting, no spear"
                end
            elseif State.BossMode == "Ride" then
                local own = State.RideOwner and State.RideOwner()
                if not own then
                    RideStop()
                end
            end
            local hp, max = nil, nil
            pcall(function()
                hp = FTD:GetAttribute("BossHP")
                max = FTD:GetAttribute("BossMaxHP")
            end)
            if type(hp) == "number" and type(max) == "number" and max > 0 then
                if State._mosaHp then
                    pcall(function()
                        State._mosaHp:Set(tostring(math.floor(hp)) .. "/" .. tostring(max))
                    end)
                end
            end
            if State._mosaSt then
                pcall(function()
                    State._mosaSt:Set(State.LastBoss or "idle")
                end)
            end
        end
    end
end)

local function MosaCountdown()
    local txt = "-"
    pcall(function()
        local now = workspace:GetServerTimeNow()
        local st = FTD:GetAttribute("BossState")
        if st == "Fight" then
            local ends = tonumber(FTD:GetAttribute("BossEnd")) or 0
            local left = math.max(0, math.floor(ends - now))
            txt = "ends " .. tostring(left // 60) .. ":" .. string.format("%02d", left % 60)
        else
            local start = tonumber(FTD:GetAttribute("BossStart")) or 0
            local left = math.floor(start + 3600 - now)
            if left < 0 then
                txt = "soon"
            else
                txt = tostring(left // 60) .. ":" .. string.format("%02d", left % 60)
            end
        end
    end)
    return txt
end

task.spawn(function()
    while Gen == getgenv().VoltGen do
        task.wait(1)
        if State._mosaCd then
            pcall(function()
                State._mosaCd:Set(MosaCountdown())
            end)
        end
    end
end)

local function NessiePose()
    if DinoCombatCache == nil then
        pcall(function()
            DinoCombatCache = require(FTD:WaitForChild("DinoCombat"))
        end)
    end
    local DC = DinoCombatCache
    if not DC then
        return nil
    end
    local cf = nil
    pcall(function()
        local b = DC.Bosses and DC.Bosses["Nessie"]
        if not b then
            return
        end
        if FTD:GetAttribute(b.state) ~= "Fight" then
            return
        end
        cf = DC.BossPose("Nessie", workspace:GetServerTimeNow())
    end)
    return cf
end

local function NessieFrags()
    local n = 0
    pcall(function()
        local raw = LocalPlayer:GetAttribute("Pacific") or ""
        local data = game:GetService("HttpService"):JSONDecode(raw)
        n = tonumber(data and data.Fragments) or 0
    end)
    return n
end

local function NessieShare()
    local hp, max = nil, nil
    pcall(function()
        hp = FTD:GetAttribute("NessieHP")
        max = FTD:GetAttribute("NessieMaxHP")
    end)
    if type(hp) == "number" and type(max) == "number" and max > 0 then
        return hp, max
    end
    return nil, nil
end

local function NessieThrow()
    local ctl = BossCtlCache["Nessie"]
    if ctl == nil then
        pcall(function()
            local folder = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("FTD_Controllers")
            local mod = folder and folder:FindFirstChild(BossCtlNames["Nessie"])
            if mod then
                ctl = require(mod)
            end
        end)
        BossCtlCache["Nessie"] = ctl or false
    end
    if State.NessieAim == "Body" then
        pcall(function()
            local cf = NessiePose()
            if not cf then
                return
            end
            local bodyPos = cf.Position - Vector3.new(0, 20, 0)
            if bodyPos.Y < 0 then
                bodyPos = Vector3.new(bodyPos.X, 0, bodyPos.Z)
            end
            FTD:WaitForChild("Remotes"):WaitForChild("NessieEvent"):FireServer("Throw", bodyPos, nil)
        end)
    elseif ctl and ctl.ThrowAuto then
        pcall(ctl.ThrowAuto)
    end
end

local function NessieSpearOk()
    local ch = LocalPlayer.Character
    if not ch then
        return false
    end
    if ch:FindFirstChild("NessieSpear") then
        return true
    end
    local pack = LocalPlayer:FindFirstChild("Backpack")
    local tool = pack and pack:FindFirstChild("NessieSpear")
    if tool then
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:EquipTool(tool)
            task.wait(0.4)
        end
        return ch:FindFirstChild("NessieSpear") ~= nil
    end
    return false
end

local NessieHeadConn = nil
pcall(function()
    NessieHeadConn = game:GetService("RunService").Heartbeat:Connect(function()
        if Gen ~= getgenv().VoltGen then
            if NessieHeadConn then
                NessieHeadConn:Disconnect()
                NessieHeadConn = nil
            end
            return
        end
        if State.AutoNessie then
            if State.NessieMode == "Ride" and not RideMounted() then
                return
            end
            if State.NessieMode == "Ride" then
                local own = State.RideOwner and State.RideOwner()
                if own and own ~= "Nessie" then
                    return
                end
            end
            local cf = NessiePose()
            if cf then
                local hrp = GetHRP()
                if hrp then
                    local pos = cf.Position + Vector3.new(0, 58 + (State.NessieH or 0), 0)
                    if State.NessieAim == "Body" then
                        pos = cf.Position + Vector3.new(0, 16 + (State.NessieH or 0), 0)
                    end
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.CFrame = CFrame.lookAt(pos, cf.Position)
                end
            end
        end
    end)
end)

task.spawn(function()
    while Gen == getgenv().VoltGen do
        task.wait(1.5)
        local nFighting = NessiePose() ~= nil
        if nFighting and not State._nessiePrev then
            WebhookSend("🟢 Nessie เกิดแล้ว")
        elseif not nFighting and State._nessiePrev then
            WebhookSend("🏁 Nessie จบแล้ว")
        end
        State._nessiePrev = nFighting
        if State.AutoNessie then
            if NessiePose() then
                if State.NessieMode == "Ride" then
                    local own = State.RideOwner and State.RideOwner()
                    if own and own ~= "Nessie" then
                        State.LastNessie = "wait " .. tostring(own)
                    elseif RideToBoss(NessiePose) then
                        State.LastNessie = "riding"
                    else
                        State.LastNessie = "riding: no mount"
                    end
                elseif NessieSpearOk() then
                    State.LastNessie = "fighting"
                    NessieThrow()
                else
                    State.LastNessie = "fighting, no spear"
                end
            elseif State.NessieMode == "Ride" then
                local own = State.RideOwner and State.RideOwner()
                if not own then
                    RideStop()
                end
            end
            local hp, max = NessieShare()
            if hp and max then
                State.LastNessie = "HP " .. tostring(math.floor(hp)) .. "/" .. tostring(max)
                if State._nessieHp then
                    pcall(function()
                        State._nessieHp:Set(tostring(math.floor(hp)) .. "/" .. tostring(max))
                    end)
                end
            end
            if State._nessieSt then
                pcall(function()
                    State._nessieSt:Set(State.LastNessie)
                end)
            end
        end
    end
end)

local function FindPrompt(root, action)
    if not root then
        return nil
    end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("ProximityPrompt") and (not action or d.ActionText == action) then
            return d
        end
    end
    return nil
end

local function FindFragModel(deep)
    local holder = workspace:FindFirstChild("FTD_Pacific")
    local model = holder and holder:FindFirstChild("FTD_NessieFragment")
    if model then
        return model
    end
    if deep then
        for _, d in ipairs(workspace:GetDescendants()) do
            if d.Name == "FTD_NessieFragment" then
                return d
            end
        end
    end
    return nil
end

task.spawn(function()
    local fragDirty = false
    local fragConns = {}
    pcall(function()
        for _, attr in ipairs({ "NessieId", "NessiePos", "NessieUntil" }) do
            fragConns[#fragConns + 1] = FTD:GetAttributeChangedSignal(attr):Connect(function()
                fragDirty = true
            end)
        end
    end)
    local lastSweep = os.clock()
    while Gen == getgenv().VoltGen do
        task.wait(0.2)
        if not fragDirty and (os.clock() - lastSweep) < 2 then
            continue
        end
        fragDirty = false
        lastSweep = os.clock()
        if State.AutoFarmFrag and not State._digBusy and not State._nessieSummonBusy then
            State._fragWarp = true
            pcall(function()
                local pos = FTD:GetAttribute("NessiePos")
                local untilT = tonumber(FTD:GetAttribute("NessieUntil")) or 0
                local id = FTD:GetAttribute("NessieId")
                local now = workspace:GetServerTimeNow()
                if typeof(pos) ~= "Vector3" or untilT <= now then
                    return
                end
                local got = nil
                pcall(function()
                    local data = game:GetService("HttpService"):JSONDecode(LocalPlayer:GetAttribute("Pacific") or "")
                    got = data and data.NessieGot
                end)
                if got == id then
                    return
                end
                if State._fragFailId ~= id then
                    State._fragFailId = id
                    State._fragFail = 0
                elseif (State._fragFail or 0) >= 3 then
                    return
                end
                local hrp = GetHRP()
                if not hrp then
                    return
                end
                PreTeleport()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                task.wait(1)
                local fragBefore = NessieFrags()
                local fragPrompt = nil
                local fragModel = FindFragModel(true)
                for _ = 1, 10 do
                    if fragModel then
                        fragPrompt = FindPrompt(fragModel, "Take")
                        if fragPrompt then
                            break
                        end
                    end
                    if NessieFrags() > fragBefore then
                        break
                    end
                    task.wait(0.3)
                    fragModel = FindFragModel()
                end
                if fragPrompt then
                    pcall(function()
                        fireproximityprompt(fragPrompt)
                    end)
                    task.wait(1.5)
                end
                local fragAfter = NessieFrags()
                if fragAfter > fragBefore then
                    State._fragFail = 0
                    WebhookSend("🟣 Nessie Fragment (มี " .. tostring(fragAfter) .. " ชิ้น)")
                else
                    State._fragFail = (State._fragFail or 0) + 1
                end
                State.LastNessie = "frag:" .. tostring(NessieFrags())
                if State._nessieSt then
                    pcall(function()
                        State._nessieSt:Set(State.LastNessie)
                    end)
                end
            end)
            State._fragWarp = false
        end
    end
    for _, c in ipairs(fragConns) do
        pcall(function()
            c:Disconnect()
        end)
    end
end)

task.spawn(function()
    while Gen == getgenv().VoltGen do
        task.wait(10)
        if State.AutoSummon then
            pcall(function()
                if NessieFrags() < 12 then
                    return
                end
                if NessiePose() then
                    return
                end
                local hrp = GetHRP()
                if not hrp then
                    return
                end
                local pillarPos = NessiePillarPos()
                if not pillarPos then
                    State.LastNessie = "summon: pillar not loaded"
                    if State._nessieSt then
                        pcall(function()
                            State._nessieSt:Set(State.LastNessie)
                        end)
                    end
                    return
                end
                PreTeleport()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(pillarPos)
                State._nessieSummonBusy = true
                task.wait(1)
                local map = workspace:FindFirstChild("Map")
                local pillar = map and map:FindFirstChild("Mystery", true)
                pillar = pillar and pillar:FindFirstChild("Pillar", true)
                local pr = FindPrompt(pillar)
                if pr then
                    for attempt = 1, 3 do
                        if not State.AutoSummon or NessiePose() then
                            break
                        end
                        pcall(function()
                            fireproximityprompt(pr)
                        end)
                        task.wait(3)
                        local still = FindPrompt(pillar)
                        if still and still.Enabled then
                            pr = still
                        else
                            pr = nil
                            break
                        end
                    end
                    State.LastNessie = "summoned, waiting fight"
                    if State._nessieSt then
                        pcall(function()
                            State._nessieSt:Set(State.LastNessie)
                        end)
                    end
                    local t0 = os.clock()
                    while os.clock() - t0 < 30 do
                        if not State.AutoSummon then
                            State._nessieSummonBusy = false
                            return
                        end
                        if NessiePose() then
                            State.LastNessie = "fight started"
                            State._nessieSummonBusy = false
                            return
                        end
                        task.wait(2)
                    end
                    State.LastNessie = "summon: no fight"
                end
                State._nessieSummonBusy = false
            end)
        end
    end
end)

local function RaptorPose()
    if DinoCombatCache == nil then
        pcall(function()
            DinoCombatCache = require(FTD:WaitForChild("DinoCombat"))
        end)
    end
    local DC = DinoCombatCache
    if not DC then
        return nil
    end
    local cf = nil
    pcall(function()
        local b = DC.Bosses and DC.Bosses["Raptor"]
        if not b then
            return
        end
        if FTD:GetAttribute(b.state) ~= "Fight" then
            return
        end
        cf = DC.BossPose("Raptor", workspace:GetServerTimeNow())
    end)
    return cf
end

local function RaptorSpearOk()
    local ch = LocalPlayer.Character
    if not ch then
        return false
    end
    if ch:FindFirstChild("RaptorSpear") then
        return true
    end
    local pack = LocalPlayer:FindFirstChild("Backpack")
    local tool = pack and pack:FindFirstChild("RaptorSpear")
    if tool then
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:EquipTool(tool)
            task.wait(0.4)
        end
        return ch:FindFirstChild("RaptorSpear") ~= nil
    end
    return false
end

local function RaptorThrow()
    local ctl = BossCtlCache["Raptor"]
    if ctl == nil then
        pcall(function()
            local folder = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("FTD_Controllers")
            local mod = folder and folder:FindFirstChild(BossCtlNames["Raptor"])
            if mod then
                ctl = require(mod)
            end
        end)
        BossCtlCache["Raptor"] = ctl or false
    end
    if State.RaptorAim == "Body" then
        pcall(function()
            local cf = RaptorPose()
            if not cf then
                return
            end
            FTD:WaitForChild("Remotes"):WaitForChild("RaptorEvent"):FireServer("Throw", cf.Position, nil)
        end)
    elseif ctl and ctl.ThrowAuto then
        pcall(ctl.ThrowAuto)
    end
end

local RaptorHeadConn = nil
pcall(function()
    RaptorHeadConn = game:GetService("RunService").Heartbeat:Connect(function()
        if Gen ~= getgenv().VoltGen then
            if RaptorHeadConn then
                RaptorHeadConn:Disconnect()
                RaptorHeadConn = nil
            end
            return
        end
        if State.AutoRaptor then
            if State.RaptorMode == "Ride" and not RideMounted() then
                return
            end
            if State.RaptorMode == "Ride" then
                local own = State.RideOwner and State.RideOwner()
                if own and own ~= "Raptor" then
                    return
                end
            end
            local cf = RaptorPose()
            if cf then
                local hrp = GetHRP()
                if hrp then
                    local pos = cf.Position + Vector3.new(0, 10 + (State.RaptorH or 0), 0)
                    local look = cf.Position + Vector3.new(0, 5, 0)
                    if State.RaptorAim == "Head" then
                        look = cf.Position + Vector3.new(0, 6, 0)
                    end
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.CFrame = CFrame.lookAt(pos, look)
                end
            end
        end
    end)
end)

task.spawn(function()
    while Gen == getgenv().VoltGen do
        task.wait(1.5)
        local rFighting = RaptorPose() ~= nil
        if rFighting and not State._raptorPrev then
            WebhookSend("🟢 Raptor X เกิดแล้ว")
        elseif not rFighting and State._raptorPrev then
            WebhookSend("🏁 Raptor X จบแล้ว")
        end
        State._raptorPrev = rFighting
        if State.AutoRaptor then
            if RaptorPose() then
                if State.RaptorMode == "Ride" then
                    local own = State.RideOwner and State.RideOwner()
                    if own and own ~= "Raptor" then
                        State.LastRaptor = "wait " .. tostring(own)
                    elseif RideToBoss(RaptorPose) then
                        State.LastRaptor = "riding"
                    else
                        State.LastRaptor = "riding: no mount"
                    end
                elseif RaptorSpearOk() then
                    State.LastRaptor = "fighting"
                    RaptorThrow()
                else
                    State.LastRaptor = "fighting, no spear"
                end
            elseif State.RaptorMode == "Ride" then
                local own = State.RideOwner and State.RideOwner()
                if not own then
                    RideStop()
                end
            end
            local hp, max = nil, nil
            pcall(function()
                hp = FTD:GetAttribute("RaptorHP")
                max = FTD:GetAttribute("RaptorMaxHP")
            end)
            if rFighting and type(hp) == "number" and type(max) == "number" and max > 0 then
                State.LastRaptor = "HP " .. tostring(math.floor(hp)) .. "/" .. tostring(max)
                if State._raptorHp then
                    pcall(function()
                        State._raptorHp:Set(tostring(math.floor(hp)) .. "/" .. tostring(max))
                    end)
                end
            end
            if State._raptorSt then
                pcall(function()
                    State._raptorSt:Set(State.LastRaptor)
                end)
            end
        end
    end
end)

local function RaptorCountdown()
    local txt = "-"
    pcall(function()
        local now = workspace:GetServerTimeNow()
        local st = FTD:GetAttribute("RaptorState")
        if st == "Fight" then
            local ends = tonumber(FTD:GetAttribute("RaptorEnd")) or 0
            local left = math.max(0, math.floor(ends - now))
            txt = "ends " .. tostring(left // 60) .. ":" .. string.format("%02d", left % 60)
        else
            local ready = tonumber(FTD:GetAttribute("RaptorReadyAt")) or 0
            local left = math.floor(ready - now)
            if ready == 0 or left < 0 then
                txt = "soon"
            else
                txt = tostring(left // 60) .. ":" .. string.format("%02d", left % 60)
            end
        end
    end)
    return txt
end

task.spawn(function()
    while Gen == getgenv().VoltGen do
        task.wait(1)
        -- wait-at-arena removed: teleport only when fight starts (fight loops handle it)
        if State._raptorCd then
            pcall(function()
                State._raptorCd:Set(RaptorCountdown())
            end)
        end
    end
end)

local function BlackScreenSet(on)
    pcall(function()
        local root = nil
        if gethui then
            local ok, h = pcall(gethui)
            if ok and h then
                root = h
            end
        end
        if not root then
            root = game:GetService("CoreGui")
        end
        local old = root:FindFirstChild("VoltBlack")
        if old then
            old:Destroy()
        end
        if on then
            local gui = Instance.new("ScreenGui")
            gui.Name = "VoltBlack"
            gui.ResetOnSpawn = false
            gui.IgnoreGuiInset = true
            gui.DisplayOrder = 500
            local f = Instance.new("Frame")
            f.Size = UDim2.fromScale(1, 1)
            f.BackgroundColor3 = Color3.new(0, 0, 0)
            f.BorderSizePixel = 0
            f.Active = false
            f.Parent = gui
            gui.Parent = root
        end
    end)
end

local function LowQSet(on)
    pcall(function()
        local R = settings().Rendering
        local L = game:GetService("Lighting")
        if on then
            if not State._gfxOrig then
                State._gfxOrig = { q = R.QualityLevel, sh = L.GlobalShadows }
            end
            R.QualityLevel = Enum.QualityLevel.Level01
            L.GlobalShadows = false
        elseif State._gfxOrig then
            R.QualityLevel = State._gfxOrig.q
            L.GlobalShadows = State._gfxOrig.sh
            State._gfxOrig = nil
        end
    end)
end

local function FpsApply()
    pcall(function()
        if State.FpsLock then
            if not State._fpsOrig then
                local ok, cur = pcall(getfpscap)
                State._fpsOrig = (ok and cur) or 60
            end
            setfpscap(State.FpsCap or 60)
        elseif State._fpsOrig then
            setfpscap(State._fpsOrig)
            State._fpsOrig = nil
        end
    end)
end

local StreamLink = "https://discord.gg/xBqjvTqWdA"

local function StreamTick(restoreOnly)
    pcall(function()
        State._streamOrig = State._streamOrig or {}
        local Players = game:GetService("Players")
        local names = {}
        names[LocalPlayer.Name] = true
        names[LocalPlayer.DisplayName] = true
        if restoreOnly then
            for inst, txt in pairs(State._streamOrig) do
                pcall(function()
                    if inst and inst.Parent then
                        inst.Text = txt
                    end
                end)
            end
            table.clear(State._streamOrig)
            pcall(function()
                local ch = LocalPlayer.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.DisplayName = LocalPlayer.DisplayName
                end
            end)
            return
        end
        local function inVoltUI(inst)
            local p = inst
            while p do
                if p.Name == "VoltScriptZ" then
                    return true
                end
                p = p.Parent
            end
            return false
        end
        local function mask(t)
            if t:IsA("TextLabel") or t:IsA("TextButton") or t:IsA("TextBox") then
                if not inVoltUI(t) and names[t.Text] then
                    if State._streamOrig[t] == nil then
                        State._streamOrig[t] = t.Text
                    end
                    t.Text = StreamLink
                end
            end
        end
        for _, p in ipairs({ LocalPlayer }) do
            local ch = p.Character
            if ch then
                for _, d in ipairs(ch:GetDescendants()) do
                    mask(d)
                end
                local hum = ch:FindFirstChildOfClass("Humanoid")
                if hum and hum.DisplayName ~= StreamLink then
                    hum.DisplayName = StreamLink
                end
            end
        end
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            for _, d in ipairs(pg:GetDescendants()) do
                mask(d)
            end
        end
    end)
end

task.spawn(function()
    while Gen == getgenv().VoltGen do
        task.wait(2)
        if State.StreamMode then
            StreamTick(false)
        end
    end
end)

task.spawn(function()
    while Gen == getgenv().VoltGen do
        task.wait(2)
        pcall(function()
            local root = nil
            if gethui then
                local ok, h = pcall(gethui)
                if ok and h then
                    root = h
                end
            end
            if not root then
                root = game:GetService("CoreGui")
            end
            local gui = root:FindFirstChild("VoltBlack")
            if State.BlackScreen and not gui then
                BlackScreenSet(true)
            elseif not State.BlackScreen and gui then
                gui:Destroy()
            end
        end)
    end
end)

local function TruePose()
    if DinoCombatCache == nil then
        pcall(function()
            DinoCombatCache = require(FTD:WaitForChild("DinoCombat"))
        end)
    end
    local DC = DinoCombatCache
    if not DC then
        return nil
    end
    local cf = nil
    pcall(function()
        local b = DC.Bosses and DC.Bosses["True"]
        if not b then
            return
        end
        if FTD:GetAttribute(b.state) ~= "Fight" then
            return
        end
        cf = DC.BossPose("True", workspace:GetServerTimeNow())
    end)
    return cf
end

-- Boss > Dig priority: pause dig while any boss fight or summon teleport owns HRP
local function AnyBossFighting()
    if State.AutoBoss then
        local ok, cf = pcall(MosaPose)
        if ok and cf then
            return true
        end
    end
    if State.AutoNessie then
        local ok, cf = pcall(NessiePose)
        if ok and cf then
            return true
        end
    end
    if State.AutoRaptor then
        local ok, cf = pcall(RaptorPose)
        if ok and cf then
            return true
        end
    end
    if State.AutoTrue then
        local ok, cf = pcall(TruePose)
        if ok and cf then
            return true
        end
    end
    return false
end

local function AnySummonBusy()
    if State._raptorSummonBusy then
        return true
    end
    if State._nessieSummonBusy then
        return true
    end
    -- armed: summon toggle on + preconditions met + no fight yet -> hold HRP across gaps
    if State.AutoRaptorSummon then
        local ok, armed = pcall(function()
            if RaptorPose() then
                return false
            end
            local keyName = "BoneboundKey"
            if Config.Rudeus and Config.Rudeus.Key then
                keyName = Config.Rudeus.Key
            end
            local ch = LocalPlayer.Character
            local pack = LocalPlayer:FindFirstChild("Backpack")
            local has = (ch and ch:FindFirstChild(keyName)) or (pack and pack:FindFirstChild(keyName))
            if not has then
                return false
            end
            local ready = tonumber(FTD:GetAttribute("RaptorReadyAt")) or 0
            if ready > 0 and ready - workspace:GetServerTimeNow() > 0 then
                return false
            end
            return true
        end)
        if ok and armed then
            return true
        end
    end
    if State.AutoSummon then
        local ok, armed = pcall(function()
            if NessiePose() then
                return false
            end
            return NessieFrags() >= 12
        end)
        if ok and armed then
            return true
        end
    end
    return false
end

State.AnyBossBusy = function()
    local ok, busy = pcall(function()
        return AnyBossFighting() or AnySummonBusy()
    end)
    return ok and busy or false
end

-- exposed so the dig loop can tell "boss is actually fighting" apart from "boss is only armed"
State.AnyBossFighting = AnyBossFighting

-- single ride owner: first Ride-mode boss still fighting keeps the mount
State.RideOwner = function()
    local fights = {}
    pcall(function()
        if State.AutoBoss and State.BossMode == "Ride" and MosaPose() then
            fights.Mosa = true
        end
    end)
    pcall(function()
        if State.AutoNessie and State.NessieMode == "Ride" and NessiePose() then
            fights.Nessie = true
        end
    end)
    pcall(function()
        if State.AutoRaptor and State.RaptorMode == "Ride" and RaptorPose() then
            fights.Raptor = true
        end
    end)
    pcall(function()
        if State.AutoTrue and State.TrueMode == "Ride" and TruePose() then
            fights.True = true
        end
    end)
    local any = fights.Mosa or fights.Nessie or fights.Raptor or fights.True
    if not any then
        State._rideOwner = nil
        return nil
    end
    if State._rideOwner and fights[State._rideOwner] then
        return State._rideOwner
    end
    for _, k in ipairs({ "Mosa", "Nessie", "Raptor", "True" }) do
        if fights[k] then
            State._rideOwner = k
            return k
        end
    end
    return nil
end

-- partner follow <-> dig handoff: restore while boss/summon owns HRP, re-dismiss after
task.spawn(function()
    local prevBusy = false
    while Gen == getgenv().VoltGen do
        task.wait(1)
        if State.AutoDig and State._savedPartnerId then
            local busy = false
            pcall(function()
                busy = State.AnyBossBusy and State.AnyBossBusy() or false
            end)
            if busy and not prevBusy then
                if DigPartnerId() == 0 then
                    pcall(function()
                        FTD:WaitForChild("Remotes").RanchRequest:InvokeServer("Partner", State._savedPartnerId)
                    end)
                    State._fightRestored = true
                end
            elseif not busy and prevBusy then
                if State._fightRestored and DigPartnerId() ~= 0 then
                    pcall(function()
                        FTD:WaitForChild("Remotes").RanchRequest:InvokeServer("Partner", State._savedPartnerId)
                    end)
                    State._fightRestored = false
                end
            end
            prevBusy = busy
        else
            prevBusy = false
        end
    end
end)

local function TrueSpearOk()
    local ch = LocalPlayer.Character
    if not ch then
        return false
    end
    if ch:FindFirstChild("TrueSpear") then
        return true
    end
    local pack = LocalPlayer:FindFirstChild("Backpack")
    local tool = pack and pack:FindFirstChild("TrueSpear")
    if tool then
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:EquipTool(tool)
            task.wait(0.4)
        end
        return ch:FindFirstChild("TrueSpear") ~= nil
    end
    return false
end

local function TrueThrow()
    local ctl = BossCtlCache["True"]
    if ctl == nil then
        pcall(function()
            local folder = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("FTD_Controllers")
            local mod = folder and folder:FindFirstChild(BossCtlNames["True"])
            if mod then
                ctl = require(mod)
            end
        end)
        BossCtlCache["True"] = ctl or false
    end
    if State.TrueAim == "Body" then
        pcall(function()
            local cf = TruePose()
            if not cf then
                return
            end
            FTD:WaitForChild("Remotes"):WaitForChild("TrueEvent"):FireServer("Throw", cf.Position, nil)
        end)
    elseif ctl and ctl.ThrowAuto then
        pcall(ctl.ThrowAuto)
    end
end

local TrueHeadConn = nil
pcall(function()
    TrueHeadConn = game:GetService("RunService").Heartbeat:Connect(function()
        if Gen ~= getgenv().VoltGen then
            if TrueHeadConn then
                TrueHeadConn:Disconnect()
                TrueHeadConn = nil
            end
            return
        end
        if State.AutoTrue then
            if State.TrueMode == "Ride" and not RideMounted() then
                return
            end
            if State.TrueMode == "Ride" then
                local own = State.RideOwner and State.RideOwner()
                if own and own ~= "True" then
                    return
                end
            end
            local cf = TruePose()
            if cf then
                local hrp = GetHRP()
                if hrp then
                    local pos = cf.Position + Vector3.new(0, 26 + (State.TrueH or 0), 0)
                    local look = cf.Position + Vector3.new(0, 12, 0)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.CFrame = CFrame.lookAt(pos, look)
                end
            end
        end
    end)
end)

task.spawn(function()
    while Gen == getgenv().VoltGen do
        task.wait(1.5)
        local tFighting = TruePose() ~= nil
        if tFighting and not State._truePrev then
            WebhookSend("🟢 True เกิดแล้ว (" .. tostring(FTD:GetAttribute("TrueSpecies") or "?") .. ")")
        elseif not tFighting and State._truePrev then
            WebhookSend("🏁 True จบแล้ว")
        end
        State._truePrev = tFighting
        if State.AutoTrue then
            if TruePose() then
                if State.TrueMode == "Ride" then
                    local own = State.RideOwner and State.RideOwner()
                    if own and own ~= "True" then
                        State.LastTrue = "wait " .. tostring(own)
                    elseif RideToBoss(TruePose) then
                        State.LastTrue = "riding"
                    else
                        State.LastTrue = "riding: no mount"
                    end
                elseif TrueSpearOk() then
                    State.LastTrue = "fighting"
                    TrueThrow()
                else
                    State.LastTrue = "fighting, no spear"
                end
            elseif State.TrueMode == "Ride" then
                local own = State.RideOwner and State.RideOwner()
                if not own then
                    RideStop()
                end
            end
            local hp, max = nil, nil
            pcall(function()
                hp = FTD:GetAttribute("TrueHP")
                max = FTD:GetAttribute("TrueMaxHP")
            end)
            if type(hp) == "number" and type(max) == "number" and max > 0 then
                State.LastTrue = "HP " .. tostring(math.floor(hp)) .. "/" .. tostring(max)
                if State._trueHp then
                    pcall(function()
                        State._trueHp:Set(tostring(math.floor(hp)) .. "/" .. tostring(max))
                    end)
                end
            end
            if State._trueSt then
                pcall(function()
                    State._trueSt:Set(State.LastTrue)
                end)
            end
        end
    end
end)

local function TrueCountdown()
    local txt = "-"
    pcall(function()
        local now = workspace:GetServerTimeNow()
        local st = FTD:GetAttribute("TrueState")
        if st == "Fight" then
            local ends = tonumber(FTD:GetAttribute("TrueEnd")) or 0
            local left = math.max(0, math.floor(ends - now))
            txt = "ends " .. tostring(left // 60) .. ":" .. string.format("%02d", left % 60)
        else
            local nxt = tonumber(FTD:GetAttribute("TrueNext")) or 0
            local left = math.floor(nxt - now)
            if nxt == 0 or left < 0 then
                txt = "soon"
            else
                txt = tostring(left // 60) .. ":" .. string.format("%02d", left % 60)
            end
        end
    end)
    return txt
end

task.spawn(function()
    while Gen == getgenv().VoltGen do
        task.wait(1)
        -- wait-at-arena removed: teleport only when fight starts (fight loops handle it)
        if State._trueCd then
            pcall(function()
                State._trueCd:Set(TrueCountdown())
            end)
        end
        if State._trueNext then
            pcall(function()
                State._trueNext:Set(tostring(FTD:GetAttribute("TrueNextSpecies") or "-"))
            end)
        end
    end
end)

task.spawn(function()
    while Gen == getgenv().VoltGen do
        task.wait(1)
        if State.AutoRaptorSummon then
            pcall(function()
                if RaptorPose() then
                    State._raptorStreamDone = nil
                    return
                end
                local keyName = "BoneboundKey"
                pcall(function()
                    if Config.Rudeus and Config.Rudeus.Key then
                        keyName = Config.Rudeus.Key
                    end
                end)
                local ch = LocalPlayer.Character
                local pack = LocalPlayer:FindFirstChild("Backpack")
                local has = (ch and ch:FindFirstChild(keyName)) or (pack and pack:FindFirstChild(keyName))
                if not has then
                    State._raptorStreamDone = nil
                    State.LastRaptor = "summon: no key"
                    if State._raptorSt then
                        pcall(function()
                            State._raptorSt:Set(State.LastRaptor)
                        end)
                    end
                    return
                end
                local tool = nil
                -- no equip: fire prompt without holding key
                local ready = tonumber(FTD:GetAttribute("RaptorReadyAt")) or 0
                if ready > 0 and ready - workspace:GetServerTimeNow() > 0 then
                    State._raptorStreamDone = nil
                    State.LastRaptor = "summon: cooldown"
                    if State._raptorSt then
                        pcall(function()
                            State._raptorSt:Set(State.LastRaptor)
                        end)
                    end
                    return
                end
                local hrp = GetHRP()
                if not hrp then
                    return
                end
                -- streaming: LockConsole parts unload when we are away, so only trust a loaded PromptPart
                local function ConsolePos()
                    local pos = nil
                    pcall(function()
                        local map = workspace:FindFirstChild("Map")
                        local bg = map and map:FindFirstChild("Blackgate", true)
                        local gar = bg and bg:FindFirstChild("Garage", true)
                        local lc = gar and gar:FindFirstChild("LockConsole", true)
                        local pp = lc and lc:FindFirstChild("PromptPart", true)
                        if pp and pp:IsA("BasePart") then
                            pos = pp.Position
                        end
                    end)
                    return pos
                end
                local consolePos = ConsolePos()
                if not consolePos then
                    -- ask the server to stream the area in (we do not move yet), then read the real position
                    local anchor = Vector3.new(-900, 0, 4350)
                    pcall(function()
                        if Config.Zones and Config.Zones.Blackgate and Config.Zones.Blackgate.Center then
                            anchor = Config.Zones.Blackgate.Center
                        end
                    end)
                    pcall(function()
                        local rc = FTD:GetAttribute("RaptorCenter")
                        if type(rc) == "Vector3" then
                            anchor = rc + Vector3.new(0, 4, 0)
                        end
                    end)
                    -- this request can block forever in some clients, so fire it from its own thread and
                    -- never wait on the call itself. Fire it once per boss cycle only, otherwise every
                    -- attempt leaves another stuck thread behind.
                    if not State._raptorStreamDone then
                        State._raptorStreamDone = true
                        task.spawn(function()
                            pcall(function()
                                LocalPlayer:RequestStreamAroundAsync(anchor, 5)
                            end)
                        end)
                    end
                    local tLoad = os.clock()
                    while os.clock() - tLoad < 4 do
                        if not State.AutoRaptorSummon then
                            return
                        end
                        consolePos = ConsolePos()
                        if consolePos then
                            break
                        end
                        task.wait(0.25)
                    end
                    if not consolePos then
                        -- streaming did not hand us the console, so stand in the zone until it loads
                        State.LastRaptor = "summon: moving to console"
                        if State._raptorSt then
                            pcall(function()
                                State._raptorSt:Set(State.LastRaptor)
                            end)
                        end
                        local tWalk = os.clock()
                        while os.clock() - tWalk < 8 do
                            if not State.AutoRaptorSummon then
                                return
                            end
                            consolePos = ConsolePos()
                            if consolePos then
                                break
                            end
                            pcall(function()
                                local hrpw = GetHRP()
                                if hrpw then
                                    hrpw.AssemblyLinearVelocity = Vector3.zero
                                    hrpw.AssemblyAngularVelocity = Vector3.zero
                                    hrpw.CFrame = CFrame.new(anchor + Vector3.new(0, 4, 0))
                                end
                            end)
                            task.wait(0.5)
                        end
                    end
                end
                if not consolePos then
                    State.LastRaptor = "summon: console not loaded"
                    if State._raptorSt then
                        pcall(function()
                            State._raptorSt:Set(State.LastRaptor)
                        end)
                    end
                    return
                end
                State._raptorSummonBusy = true
                PreTeleport()
                local hrp2 = GetHRP()
                if hrp2 then
                    hrp = hrp2
                end
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(consolePos + Vector3.new(0, 3, 0))
                task.wait(1)
                local pr = nil
                pcall(function()
                    local map = workspace:FindFirstChild("Map")
                    local bg = map and map:FindFirstChild("Blackgate", true)
                    pr = FindPrompt(bg, "Turn the Bonebound Key")
                end)
                if pr then
                    pcall(function()
                        fireproximityprompt(pr)
                    end)
                    State.LastRaptor = "summoned, waiting fight"
                    if State._raptorSt then
                        pcall(function()
                            State._raptorSt:Set(State.LastRaptor)
                        end)
                    end
                    local t0 = os.clock()
                    local started = false
                    while os.clock() - t0 < 3 do
                        if not State.AutoRaptorSummon then
                            break
                        end
                        if RaptorPose() then
                            State.LastRaptor = "fight started"
                            started = true
                            break
                        end
                        local rst = nil
                        pcall(function()
                            rst = FTD:GetAttribute("RaptorState")
                        end)
                        if rst and rst ~= "Idle" then
                            State.LastRaptor = "fight started"
                            started = true
                            break
                        end
                        task.wait(0.5)
                    end
                    if not started and State.AutoRaptorSummon then
                        State.LastRaptor = "summon: no fight"
                    end
                end
                State._raptorSummonBusy = false
            end)
        end
    end
end)

-- ===== Auto Hop (Boss Raptor only): jump to a fresh server while the boss cools down =====
local HopMinDwell = 25   -- stay this long in a server before hopping again
local HopGap = 30        -- minimum seconds between two hops
local HopMax = 8         -- consecutive hops before a forced break
local HopBreak = 300     -- forced break length
local HopMargin = 90     -- hop only while the boss is at least this far from ready

local function HopHasKey()
    local has = false
    pcall(function()
        local keyName = "BoneboundKey"
        if Config.Rudeus and Config.Rudeus.Key then
            keyName = Config.Rudeus.Key
        end
        local ch = LocalPlayer.Character
        local pack = LocalPlayer:FindFirstChild("Backpack")
        has = (ch and ch:FindFirstChild(keyName) ~= nil) or (pack and pack:FindFirstChild(keyName) ~= nil)
    end)
    return has
end

local function HopStatus(text)
    if State._raptorHop then
        pcall(function()
            State._raptorHop:Set(text)
        end)
    end
end

local function HopCandidates()
    local out = {}
    pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?limit=100&excludeFullGames=true"
        local body = game:HttpGet(url, true)
        local data = game:GetService("HttpService"):JSONDecode(body)
        local list = {}
        for _, s in ipairs(data.data or {}) do
            local id = s.id
            local playing = tonumber(s.playing) or 999
            if type(id) == "string" and id ~= game.JobId then
                list[#list + 1] = { id = id, playing = playing }
            end
        end
        table.sort(list, function(a, b)
            return a.playing < b.playing
        end)
        for i = 1, math.min(#list, 5) do
            out[#out + 1] = list[i].id
        end
    end)
    return out
end

-- ══════════════════════════════════════════════════════════════════════
--  AUTO EXE — รันสคริปต์ตัวเองใหม่หลัง Hop
--  · ปุ่มเปิด/ปิดอยู่ที่การ์ด "Misc" → "Auto Exe"
--  · ทำงานโดย "ฝากตัวโหลด" ไว้กับตัวรันก่อน hop ทุกครั้ง (queue_on_teleport)
--  · ตัวโหลดจะเลือกแหล่งเอง: ไฟล์สำเนาในเครื่อง (ไว้ทดสอบ) → ถ้าไม่มี ค่อยดึงลิงก์
--  · ลิงก์เผยแพร่ (แก้ที่นี่บรรทัดเดียว):
-- ══════════════════════════════════════════════════════════════════════
local AUTOEXE_URL = "https://raw.githubusercontent.com/ice123nm44nm-dot/VoltHub/main/PrehistoricFarm.lua"
local AUTOEXE_LOCAL = "VoltScriptZ_PrehistoricFarm_src.luau"

local function BuildAutoExePayload()
    return table.concat({
        "task.wait(3)",
        "local function grab()",
        "    local ok1, a = pcall(readfile, " .. string.format("%q", AUTOEXE_LOCAL) .. ")",
        "    if ok1 and type(a) == \"string\" and #a > 200 then return a end",
        "    return game:HttpGet(" .. string.format("%q", AUTOEXE_URL) .. ")",
        "end",
        "local ok, src = pcall(grab)",
        "if ok and type(src) == \"string\" and #src > 200 then",
        "    local fn = loadstring(src)",
        "    if fn then pcall(fn) end",
        "end",
    }, "\n")
end

local function ArmAutoExe()
    if State.AutoExe ~= true then
        return
    end
    if type(queue_on_teleport) ~= "function" then
        HopStatus("auto exe: unsupported")
        return
    end
    pcall(queue_on_teleport, BuildAutoExePayload())
    HopStatus("auto exe: armed")
end

local function DoHop()
    if State._hopBusy then
        return
    end
    State._hopBusy = true
    State._hopCount = (State._hopCount or 0) + 1
    State._hopNext = os.clock() + HopGap
    State.LastRaptor = "hop: leaving"
    HopStatus("hop: leaving")
    pcall(PreTeleport)
    pcall(ArmAutoExe)
    local TS = game:GetService("TeleportService")
    local failed = false
    local conn = nil
    pcall(function()
        conn = TS.TeleportInitFailed:Connect(function(plr)
            if plr == LocalPlayer then
                failed = true
            end
        end)
    end)
    local cands = HopCandidates()
    if #cands == 0 then
        cands = { false }
    end
    for i = 1, math.min(#cands, 3) do
        failed = false
        local jobId = cands[i]
        pcall(function()
            if jobId then
                TS:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
            else
                TS:Teleport(game.PlaceId, LocalPlayer)
            end
        end)
        local t0 = os.clock()
        while os.clock() - t0 < 5 do
            if failed then
                break
            end
            task.wait(0.25)
        end
        if not failed then
            break
        end
    end
    if failed then
        HopStatus("hop: failed")
        State._hopNext = os.clock() + 60
    end
    if conn then
        pcall(function()
            conn:Disconnect()
        end)
    end
    State._hopBusy = false
end

task.spawn(function()
    local joinedAt = os.clock()
    while Gen == getgenv().VoltGen do
        task.wait(1)
        pcall(function()
            if not State.AutoHopRaptor or State._hopBusy then
                return
            end
            local now = workspace:GetServerTimeNow()
            local st = FTD:GetAttribute("RaptorState")
            local ready = tonumber(FTD:GetAttribute("RaptorReadyAt")) or 0
            local left = ready > 0 and math.floor(ready - now) or 0
            if st == "Fight" then
                return
            end
            if left <= HopMargin then
                State._hopCount = 0
                HopStatus(left > 0 and ("ready in " .. tostring(left) .. "s") or "ready")
                return
            end
            if not State.AutoRaptorSummon then
                HopStatus("need Auto Summon")
                return
            end
            if not HopHasKey() then
                HopStatus("no key")
                return
            end
            if State._raptorSummonBusy then
                return
            end
            if os.clock() - joinedAt < HopMinDwell then
                return
            end
            if os.clock() < (State._hopNext or 0) then
                HopStatus("hop cooldown " .. tostring(math.ceil((State._hopNext or 0) - os.clock())) .. "s")
                return
            end
            if State._hopPauseUntil and os.clock() < State._hopPauseUntil then
                HopStatus("hop paused " .. tostring(math.ceil(State._hopPauseUntil - os.clock())) .. "s")
                return
            end
            if (State._hopCount or 0) >= HopMax then
                State._hopPauseUntil = os.clock() + HopBreak
                State._hopCount = 0
                HopStatus("hop paused")
                return
            end
            if AnyBossFighting() then
                HopStatus("fighting")
                return
            end
            DoHop()
        end)
    end
end)


task.spawn(function()
    local qTick = 0
    local meleeIdx = 0
    while Gen == getgenv().VoltGen do
        task.wait(0.5)
        qTick = qTick + 1
        local anyRide = false
        local function rideBoss(autoKey, modeKey, poseFn, bossKey)
            if not State[autoKey] or State[modeKey] ~= "Ride" then
                return
            end
            local cf = poseFn()
            if not cf then
                return
            end
            if not RideMounted() then
                return
            end
            local hrp = GetHRP()
            if not hrp then
                return
            end
            anyRide = true
            meleeIdx = (meleeIdx % 4) + 1
            RideMelee(bossKey, meleeIdx)
            if qTick % 24 == 0 then
                RideMelee(bossKey, 5)
            end
        end
        pcall(rideBoss, "AutoBoss", "BossMode", MosaPose, "Mosa")
        pcall(rideBoss, "AutoNessie", "NessieMode", NessiePose, "Nessie")
        pcall(rideBoss, "AutoRaptor", "RaptorMode", RaptorPose, "Raptor")
        pcall(rideBoss, "AutoTrue", "TrueMode", TruePose, "True")
        if not anyRide then
            RideKeys(false)
        end
    end
end)

local FoodCard = ShopTab:AddCard({
    Title = "Buy Dino Food",
    Subtitle = "Stock food and feed dinos",
    Toggle = false,
    Column = 1,
})

FoodCard:AddToggle({
    Name = "Buy Dino Food",
    Name = "Buy Dino Food",    Flag = "FoodCard_BuyDinoFood",
    Default = false,
    Callback = function(v)
        State.AutoBuyFood = v
    end
})

FoodCard:AddDropdown({
    Name = "Select Food",
    Name = "Select Food",    Flag = "FoodCard_SelectFood",
    Options = { "Both", "Meat", "Veggies", "Fish" },
    Default = "Both",
    Callback = function(v)
        State.BuyFood = v
    end
})

FoodCard:AddSlider({
    Name = "Buy Limit",
    Name = "Buy Limit",    Flag = "FoodCard_BuyLimit",
    Min = 0,
    Max = 200,
    Increment = 10,
    Default = 50,
    Callback = function(v)
        State.BuyLimit = v
    end
})

FoodCard:AddToggle({
    Name = "Auto Feed",
    Name = "Auto Feed",    Flag = "FoodCard_AutoFeed",
    Default = false,
    Callback = function(v)
        State.AutoFeed = v
    end
})

local RodCard = ShopTab:AddCard({
    Title = "Buy Rods",
    Subtitle = "Upgrade fishing rods",
    Toggle = false,
    Column = 1,
})

RodCard:AddToggle({
    Name = "Auto Buy Rods",
    Name = "Auto Buy Rods",    Flag = "RodCard_AutoBuyRods",
    Default = false,
    Callback = function(v)
        State.AutoBuyRods = v
    end
})

RodCard:AddDropdown({
    Name = "Rod Target",
    Name = "Rod Target",    Flag = "RodCard_RodTarget",
    Options = { "JadeBamboo", "Tidecaller", "Amethyst", "Goldscale" },
    Default = "Amethyst",
    Callback = function(v)
        State.RodTarget = v
    end
})

RodCard:AddDropdown({
    Name = "Buy Mode",
    Name = "Buy Mode",    Flag = "RodCard_BuyMode",
    Options = { "Auto", "Selected" },
    Default = "Auto",
    Callback = function(v)
        State.RodMode = v
    end
})

RodCard:AddLabel("Auto: buys step by step up to the target. Selected: buys only the target rod. Skipped if coins are not enough.\nJade Bamboo 1,950\nTidecaller 10,400\nAmethyst 78,000\nGoldscale 260,000")

local BoatCard = ShopTab:AddCard({
    Title = "Buy Boats",
    Subtitle = "Upgrade your boat",
    Toggle = false,
    Column = 2,
})

BoatCard:AddToggle({
    Name = "Auto Buy Boats",
    Name = "Auto Buy Boats",    Flag = "BoatCard_AutoBuyBoats",
    Default = false,
    Callback = function(v)
        State.AutoBuyBoats = v
    end
})

BoatCard:AddDropdown({
    Name = "Boat Target",
    Name = "Boat Target",    Flag = "BoatCard_BoatTarget",
    Options = { "Dory", "Skiff", "Lobster" },
    Default = "Skiff",
    Callback = function(v)
        State.BoatTarget = v
    end
})

BoatCard:AddDropdown({
    Name = "Buy Mode",
    Name = "Buy Mode",    Flag = "BoatCard_BuyMode",
    Options = { "Auto", "Selected" },
    Default = "Auto",
    Callback = function(v)
        State.BoatMode = v
    end
})

BoatCard:AddLabel("Auto: buys step by step up to the target. Selected: buys only the target boat. Skipped if coins are not enough.\nDory 4,000\nSkiff 60,000\nLobster 300,000")

local SellCard = ShopTab:AddCard({
    Title = "Sell Item",
    Subtitle = "Sell fossils, fish, eggs and dinos",
    Toggle = false,
    Column = 2,
})

SellCard:AddToggle({
    Name = "Auto Sell",
    Name = "Auto Sell",    Flag = "SellCard_AutoSell",
    Default = false,
    Callback = function(v)
        State.AutoSell = v
    end
})

SellCard:AddDropdown({
    Name = "Fossils Rarity",
    Name = "Fossils Rarity",    Flag = "SellCard_FossilsRarity",
    Options = { "All", "None", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" },
    Default = { "None" },
    Multi = true,
    Callback = function(v)
        if #v == 0 then
            v = { "None" }
        end
        State.FossilRarity = v
    end
})

SellCard:AddDropdown({
    Name = "Fish Rarity",
    Name = "Fish Rarity",    Flag = "SellCard_FishRarity",
    Options = { "All", "None", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" },
    Default = { "None" },
    Multi = true,
    Callback = function(v)
        if #v == 0 then
            v = { "None" }
        end
        State.FishRarity = v
    end
})

SellCard:AddDropdown({
    Name = "Egg Rarity",
    Name = "Egg Rarity",    Flag = "SellCard_EggRarity",
    Options = { "All", "None", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" },
    Default = { "None" },
    Multi = true,
    Callback = function(v)
        if #v == 0 then
            v = { "None" }
        end
        State.SellEggRarity = v
    end
})

SellCard:AddDropdown({
    Name = "Dino Rarity",
    Name = "Dino Rarity",    Flag = "SellCard_DinoRarity",
    Options = { "All", "None", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" },
    Default = { "None" },
    Multi = true,
    Callback = function(v)
        if #v == 0 then
            v = { "None" }
        end
        State.DinoRarity = v
    end
})

local PerfCard = UtilitiesTab:AddCard({
    Title = "Performance",
    Subtitle = "Reduce lag and save power",
    Toggle = false,
    Column = 1,
})

PerfCard:AddToggle({
    Name = "Black Screen",
    Name = "Black Screen",    Flag = "PerfCard_BlackScreen",
    Default = false,
    Callback = function(v)
        State.BlackScreen = v
        BlackScreenSet(v)
    end
})

PerfCard:AddToggle({
    Name = "Low Quality",
    Name = "Low Quality",    Flag = "PerfCard_LowQuality",
    Default = false,
    Callback = function(v)
        LowQSet(v)
    end
})

PerfCard:AddToggle({
    Name = "Fps Lock",
    Name = "Fps Lock",    Flag = "PerfCard_FpsLock",
    Default = false,
    Callback = function(v)
        State.FpsLock = v
        FpsApply()
    end
})

PerfCard:AddSlider({
    Name = "Fps Cap",
    Name = "Fps Cap",    Flag = "PerfCard_FpsCap",
    Min = 30,
    Max = 240,
    Increment = 5,
    Default = 60,
    Callback = function(v)
        State.FpsCap = v
        FpsApply()
    end
})

local MiscCard = UtilitiesTab:AddCard({
    Title = "Misc",
    Subtitle = "Extra helpers",
    Toggle = false,
    Column = 2,
})

MiscCard:AddToggle({
    Name = "Stream Mode (Hide Name)",
    Name = "Stream Mode (Hide Name)",    Flag = "MiscCard_StreamModeHideName",
    Default = false,
    Callback = function(v)
        State.StreamMode = v
        if not v then
            StreamTick(true)
        end
    end
})

MiscCard:AddToggle({
    Name = "Anti AFK",
    Name = "Anti AFK",    Flag = "MiscCard_AntiAFK",
    Default = true,
    Callback = function(v)
        State.AntiAFK = v
    end
})

MiscCard:AddToggle({
    Name = "Auto Exe",
    Flag = "MiscCard_AutoExe",
    Default = true,
    Callback = function(v)
        State.AutoExe = v
    end
})

MiscCard:AddToggle({
    Name = "Auto Skip Intro",
    Flag = "MiscCard_AutoSkipIntro",
    Default = true,
    Callback = function(v)
        State.AutoSkipIntro = v
    end
})

local ConfigCard = SettingsTab:AddCard({
    Title = "Configs",
    Subtitle = "Save and load settings",
    Toggle = false,
    Column = 1,
})

local ConfigNameBox = ConfigCard:AddTextbox({
    Name = "Config",
    Default = "default",
    Placeholder = "my-config",
})

local ConfigList = ConfigCard:AddDropdown({
    Name = "Saved",
    Options = { "(no configs)" },
    Default = "(no configs)",
    Callback = function(v)
        if v and v ~= "(no configs)" then
            ConfigNameBox:Set(v)
        end
    end
})

local function RefreshConfigs(select)
    local names = Win:ListConfigs()
    if #names == 0 then
        names = { "(no configs)" }
    end
    ConfigList:Refresh(names)
    if select then
        if table.find(names, select) then
            ConfigList:Set(select, true)
        else
            ConfigList:Set(names[1], true)
        end
    end
    return names
end
RefreshConfigs("default")

local function ChosenConfig()
    local v = ConfigNameBox:Get()
    if v == nil or tostring(v) == "" then
        v = ConfigList:Get()
        if v == "(no configs)" then
            v = "default"
        end
    end
    return tostring(v)
end

ConfigCard:AddButton({
    Name = "Save",
    Callback = function()
        local n = ChosenConfig()
        Win:SaveConfig(n)
        RefreshConfigs(n)
        Win:Notify({ Title = "Config", Text = "Saved: " .. n })
    end
})

local function PushFlagValue(obj)
    local ok, v = pcall(function()
        return obj:Get()
    end)
    if not ok then
        return
    end
    if type(v) == "number" then
        -- sliders in the library fire their callback only when the value really
        -- changes, so nudge once (silently) and set the real value back
        pcall(function()
            obj:Set(v - 1, true)
            if obj:Get() == v then
                obj:Set(v + 1, true)
            end
            obj:Set(v, false)
        end)
    else
        pcall(function()
            obj:Set(v, false)
        end)
    end
end

local function SyncUIToState()
    pcall(function()
        for _, obj in pairs(Win.Flags) do
            PushFlagValue(obj)
        end
    end)
end

ConfigCard:AddButton({
    Name = "Load",
    Callback = function()
        local n = ChosenConfig()
        if Win:LoadConfig(n) then
            SyncUIToState()
            RefreshConfigs(n)
            Win:Notify({ Title = "Config", Text = "Loaded: " .. n })
        else
            Win:Notify({ Title = "Config", Text = "Not found: " .. n })
        end
    end
})

ConfigCard:AddButton({
    Name = "Delete",
    Callback = function()
        local n = ChosenConfig()
        if Win:DeleteConfig(n) then
            RefreshConfigs()
            Win:Notify({ Title = "Config", Text = "Deleted: " .. n })
        else
            Win:Notify({ Title = "Config", Text = "Delete failed: " .. n })
        end
    end
})

ConfigCard:AddButton({
    Name = "Set up Auto Load",
    Callback = function()
        local n = ChosenConfig()
        local ok = pcall(function()
            writefile("VoltScriptZ_autoload.txt", n)
        end)
        if ok then
            Win:Notify({ Title = "Config", Text = "Autoload: " .. n })
        else
            Win:Notify({ Title = "Config", Text = "Autoload save failed" })
        end
    end
})

-- Auto Save: remember every setting the user changes and restore it on the next launch
pcall(function()
    local cfgName = "Farm"
    local okRead, f = pcall(readfile, "VoltScriptZ_autoload.txt")
    if okRead and f and tostring(f) ~= "" then
        cfgName = tostring(f)
    end
    Win:EnableAutoSave(cfgName, { AutoLoad = false })
    if Win:LoadConfig(cfgName) then
        SyncUIToState()
    end
end)

pcall(function()
    local n = readfile("VoltScriptZ_autoload.txt")
    if n and tostring(n) ~= "" then
        if Win:LoadConfig(tostring(n)) then
            SyncUIToState()
        end
    end
end)

local UICard = SettingsTab:AddCard({
    Title = "UI Scale",
    Toggle = false,
    Column = 2,
})

UICard:AddSlider({
    Name = "Scale",
    Name = "Scale",    Flag = "UICard_Scale",
    Min = 50,
    Max = 100,
    Increment = 5,
    Default = 100,
    Suffix = "%",
    Callback = function(v)
        pcall(function()
            local sc = Win.Main and Win.Main:FindFirstChildOfClass("UIScale")
            if sc then
                sc.Scale = Win.BaseScale * (v / 100)
            end
        end)
    end
})

Win:Notify({
    Title = "VoltScriptZ",
    Text = "Loaded",
    Duration = 5
})

-- ══════════════════════════════════════════════════════════════════════
--  AUTO SKIP INTRO — ข้ามหน้าโหลดของเกมให้เอง  (v2)
--   · ช่วง "Loading the islands.. NN%" = เกมยังโหลดจริง → รอ (กดไม่ผ่าน)
--   · หน้า 1 "Press any key to continue" → ส่งคีย์ให้เอง
--   · หน้า 2 เมนู PLAY/SETTINGS/CODES/UPDATES → กดปุ่ม PLAY ให้เอง
--   · ลองเรื่อย ๆ ไม่จำกัด · ล้มติดกันจะถอยเวลาห่างขึ้น (ไม่กดรัว)
--   · ถ้าหน้าจอเปลี่ยน (โหลดเสร็จ / ขึ้นเมนู) จะเริ่มนับใหม่ทันที
--   · ใช้ได้ทั้งตอนรันสคริปต์เอง และหลัง Hop (Auto Exe โหลดสคริปต์กลับมา)
--   · ปุ่มเปิด/ปิด: การ์ด "Misc" → "Auto Skip Intro"
-- ══════════════════════════════════════════════════════════════════════

local INTRO_LOADING_TEXTS = { "Loading the islands", "Almost there", "Loading your farm" }
local INTRO_BACKOFF = { 5, 10, 20, 30, 60 }

local function IntroFindPlayButton(gui)
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("GuiButton") and d.Name == "Hit" then
            local p, chain, depth = d.Parent, "", 0
            while p and p ~= gui and depth < 6 do
                chain = p.Name .. "<" .. chain
                p = p.Parent
                depth = depth + 1
            end
            if string.find(chain, "Play") then
                return d
            end
        end
    end
    return nil
end

-- เกมกำลังโหลดของจริงอยู่หรือเปล่า (ช่วงนี้กดอะไรก็ไม่ผ่าน ต้องรอ)
local function IntroIsLoading(gui)
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            if d.Visible and d.TextTransparency < 0.9 then
                local t = tostring(d.Text)
                for _, k in ipairs(INTRO_LOADING_TEXTS) do
                    if string.find(t, k, 1, true) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- ป้ายให้กดโชว์อยู่จริงไหม (Visible เฉย ๆ ไม่พอ — ตอนโหลดมันก็ Visible อยู่)
local function IntroPromptLive(prompt)
    return prompt ~= nil and prompt.Visible and prompt.TextTransparency < 0.9
end

local function IntroPressAnyKey()
    local ok = pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true, Enum.KeyCode.X, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.X, false, game)
    end)
    if ok then
        return
    end
    if type(keypress) == "function" then
        pcall(keypress, 88)
        pcall(keyrelease, 88)
    end
end

local function IntroClickButton(btn, mode)
    local c = btn.AbsolutePosition + btn.AbsoluteSize / 2
    if mode == "touch" then
        pcall(touchtap, c.X, c.Y)
    elseif mode == "signal" then
        for _, sname in ipairs({ "MouseButton1Down", "MouseButton1Up", "Activated", "MouseButton1Click" }) do
            local sig = btn[sname]
            if sig then
                pcall(firesignal, sig)
            end
        end
    else
        pcall(function()
            mousemoveabs(c.X, c.Y)
            task.wait(0.2)
            mouse1click()
        end)
    end
end

-- คืนค่า: "ok" = ข้ามสำเร็จ · "done" = ไม่มีอะไรต้องทำ · "loading" = เกมยังโหลด · "fail" = ลองแล้วไม่ผ่าน
local function IntroTrySkipOnce()
    local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then
        return "done"
    end
    local gui = pg:FindFirstChild("FTD_Loading")
    if not gui then
        return "done"
    end
    local prompt = gui:FindFirstChild("Prompt", true)
    local playBtn = IntroFindPlayButton(gui)
    local loading = IntroIsLoading(gui)
    local promptLive = IntroPromptLive(prompt)

    -- เกมยังโหลดของจริง (ป้าย "Loading the islands..") → อย่าเพิ่งกด
    if loading and not promptLive then
        return "loading"
    end

    if not playBtn then
        if not promptLive then
            if loading then
                return "loading"
            end
            return "done"
        end
        IntroPressAnyKey()
        local t0 = os.clock()
        while os.clock() - t0 < 6 do
            local btn = IntroFindPlayButton(gui)
            if btn then
                playBtn = btn
                break
            end
            if not gui.Parent then
                return "done"
            end
            task.wait(0.4)
        end
    end

    if not playBtn then
        if IntroIsLoading(gui) then
            return "loading"
        end
        if IntroPromptLive(prompt) then
            return "fail"
        end
        return "done"
    end

    local methods = {}
    if type(touchtap) == "function" then
        methods[#methods + 1] = "touch"
    end
    methods[#methods + 1] = "mouse"
    methods[#methods + 1] = "signal"
    for _, mode in ipairs(methods) do
        IntroClickButton(playBtn, mode)
        task.wait(2.5)
        if not IntroFindPlayButton(gui) then
            return "ok"
        end
        if IntroIsLoading(gui) then
            return "loading"
        end
    end
    return "fail"
end

-- ลายเซ็นสถานะหน้าจอ: เปลี่ยน = ขึ้นหน้าใหม่/โหลดเสร็จ/มีเมนู → เริ่มนับความล้มเหลวใหม่
local function IntroStateSig()
    local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    local gui = pg and pg:FindFirstChild("FTD_Loading")
    if not gui then
        return "none"
    end
    local prompt = gui:FindFirstChild("Prompt", true)
    local menu = gui:FindFirstChild("Menu", true)
    return tostring(gui)
        .. (menu and "|M" or "|-")
        .. (IntroPromptLive(prompt) and "|P" or "|-")
        .. (IntroIsLoading(gui) and "|L" or "|-")
end

task.spawn(function()
    local fails = 0
    local lastSig = nil
    while true do
        task.wait(2)
        if not State.AutoSkipIntro then
            fails = 0
            lastSig = nil
        else
            local sig = IntroStateSig()
            if sig ~= lastSig then
                lastSig = sig
                fails = 0
            end
            local ok, res = pcall(IntroTrySkipOnce)
            if not ok then
                res = "fail"
            end
            if res == "ok" then
                fails = 0
            elseif res == "loading" or res == "done" then
                fails = 0
            else
                fails = fails + 1
                local gap = INTRO_BACKOFF[math.min(fails, #INTRO_BACKOFF)]
                if fails == #INTRO_BACKOFF + 1 then
                end
                task.wait(gap)
            end
        end
    end
end)
