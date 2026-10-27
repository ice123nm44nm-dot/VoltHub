local Players = game:GetService("Players")
local Workspace = workspace
local LocalPlayer = Players.LocalPlayer

if getgenv().VoltDodge then
    getgenv().VoltDodge.active = false
    if type(getgenv().VoltDodge.cleanup) == "function" then
        pcall(getgenv().VoltDodge.cleanup)
    end
    for _, conn in ipairs(getgenv().VoltDodge.conns) do
        pcall(function() conn:Disconnect() end)
    end
    for _, conn in ipairs(getgenv().VoltDodge.opponentConns) do
        pcall(function() conn:Disconnect() end)
    end
    if getgenv().VoltDodge.blocking then
        pcall(function()
            local bridgeNet = game:GetService("ReplicatedFirst"):FindFirstChild("BridgeNet2")
            if bridgeNet then
                require(bridgeNet).ReferenceBridge("HandleBlock"):Fire(false)
            end
        end)
    end
    getgenv().VoltDodge = nil
end

if getgenv().VoltEsp then
    pcall(getgenv().VoltEsp.destroy)
    getgenv().VoltEsp = nil
end

if getgenv().VoltCustom then
    pcall(getgenv().VoltCustom.destroy)
    getgenv().VoltCustom = nil
end

-- overlay from the previous run
pcall(function()
    local root = game:GetService("CoreGui")
    if type(gethui) == "function" then
        local ok, hidden = pcall(gethui)
        if ok and hidden then
            root = hidden
        end
    end
    local overlay = root:FindFirstChild("VoltBlack")
    if overlay then
        overlay:Destroy()
    end
end)

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ice123nm44nm-dot/VoltHub/main/VoltUi.lua"))()

if getgenv().VoltWin then
    pcall(function()
        if type(getgenv().VoltWin.Destroy) == "function" then
            getgenv().VoltWin:Destroy()
        end
    end)
    getgenv().VoltWin = nil
end

local Window = Library:CreateWindow({
    Title = "Volt",
    TitleAccent = "ScriptZ",
    Subtitle = "Untitled boxing game | Made By VoltScript Hub",
    Name = "VoltScriptZ",
    Logo = "rbxassetid://100712256015627"
})
getgenv().VoltWin = Window

Window:AddSection("General")

local MainTab = Window:AddTab({ Name = "Combat" })
local EspTab = Window:AddTab({ Name = "ESP" })
local CustomTab = Window:AddTab({ Name = "Customization" })

Window:AddSection("Utilities")

local UtilTab = Window:AddTab({ Name = "Utilities" })
local SettingsTab = Window:AddTab({ Name = "Settings" })

local DodgeCard = MainTab:AddCard({
    Title = "Dodge",
    Subtitle = "Auto dodge punches",
    Toggle = false
})

local State = {
    AutoDodge = false,
    ReactionDelay = 60,
    MinStamina = 10,
    Direction = "Auto",
    BlockFeint = false,
    BlockHold = 450,
    DodgeFeint = false,
    Esp = false,
    EspBox = true,
    EspName = true,
    EspHealth = true,
    EspStamina = true,
    EspPunch = true,
    EspMaxDistance = 300,
    BlackScreen = false,
    LowQuality = false,
    Fullbright = false,
    FpsLock = false,
    FpsCap = 240,
    AntiAFK = true,
    StreamMode = false
}
getgenv().VoltDodgeState = State

DodgeCard:AddToggle({
    Name = "Auto Dodge",
    Flag = "Dodge_AutoDodge",
    Default = false,
    Callback = function(value)
        State.AutoDodge = value
    end
})

DodgeCard:AddSlider({
    Name = "Reaction Delay",
    Flag = "Dodge_ReactionDelay",
    Min = 0,
    Max = 120,
    Increment = 5,
    Suffix = "ms",
    Default = 60,
    Callback = function(value)
        State.ReactionDelay = value
    end
})

DodgeCard:AddSlider({
    Name = "Min Stamina",
    Flag = "Dodge_MinStamina",
    Min = 0,
    Max = 50,
    Increment = 5,
    Default = 10,
    Callback = function(value)
        State.MinStamina = value
    end
})

DodgeCard:AddDropdown({
    Name = "Direction",
    Flag = "Dodge_Direction",
    Options = { "Auto", "Always Left", "Always Right", "Backward", "In Place" },
    Default = "Auto",
    Callback = function(value)
        State.Direction = value
    end
})

local FeintCard = MainTab:AddCard({
    Title = "Dodge Feint",
    Subtitle = "Dodge the follow-up",
    Toggle = false
})

FeintCard:AddToggle({
    Name = "Dodge Feint",
    Flag = "Feint_Dodge",
    Default = false,
    Callback = function(value)
        State.DodgeFeint = value
    end
})

local BlockCard = MainTab:AddCard({
    Title = "Block Feint",
    Subtitle = "Guard on feints",
    Toggle = false,
    Column = 2
})

BlockCard:AddToggle({
    Name = "Block Feint",
    Flag = "Block_Enabled",
    Default = false,
    Callback = function(value)
        State.BlockFeint = value
    end
})

BlockCard:AddSlider({
    Name = "Hold Time",
    Flag = "Block_Hold",
    Min = 200,
    Max = 800,
    Increment = 50,
    Suffix = "ms",
    Default = 450,
    Callback = function(value)
        State.BlockHold = value
    end
})

local EspCard = EspTab:AddCard({
    Title = "ESP",
    Subtitle = "Opponent info overlay",
    Toggle = false,
    Column = 1
})

EspCard:AddToggle({
    Name = "Enable ESP",
    Flag = "Esp_Enabled",
    Default = false,
    Callback = function(value)
        State.Esp = value
    end
})

EspCard:AddToggle({
    Name = "Box",
    Flag = "Esp_Box",
    Default = true,
    Callback = function(value)
        State.EspBox = value
    end
})

EspCard:AddToggle({
    Name = "Name",
    Flag = "Esp_Name",
    Default = true,
    Callback = function(value)
        State.EspName = value
    end
})

EspCard:AddToggle({
    Name = "Health",
    Flag = "Esp_Health",
    Default = true,
    Callback = function(value)
        State.EspHealth = value
    end
})

EspCard:AddToggle({
    Name = "Stamina",
    Flag = "Esp_Stamina",
    Default = true,
    Callback = function(value)
        State.EspStamina = value
    end
})

EspCard:AddToggle({
    Name = "Punch Tag",
    Flag = "Esp_Punch",
    Default = true,
    Callback = function(value)
        State.EspPunch = value
    end
})

EspCard:AddSlider({
    Name = "Max Distance",
    Flag = "Esp_MaxDistance",
    Min = 20,
    Max = 500,
    Increment = 10,
    Suffix = " studs",
    Default = 300,
    Callback = function(value)
        State.EspMaxDistance = value
    end
})

-- ============================================================
-- Customization
-- Gloves and unusual effects are rendered entirely by the game's
-- own client script (StarterPlayerScripts.Gloves), which listens
-- to workspace.States.<player>.PlayerData.Gloves. Writing that
-- value locally makes the game clone and weld the real models,
-- so this file only needs to build the string.
-- Styles work the same way: Animate2 reads PlayerData.Style every
-- frame and swaps the movement animations from Modules.Styles.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Custom = {
    conns = {},
    original = nil,
    quiet = false,
    value = nil,
    valueConn = nil,
    gloveLeft = nil,
    gloveRight = nil,
    gloveLink = true,
    rarity = "All",
    enabled = false,
    effectName = "None",
    styleEnabled = false,
    styleName = nil,
    styleRarity = "All",
    originalStyle = nil,
    styleValue = nil,
    styleConn = nil,
    styleQuiet = false
}
getgenv().VoltCustom = Custom

local function getPlayerData()
    local states = Workspace:FindFirstChild("States")
    local mine = states and states:FindFirstChild(LocalPlayer.Name)
    return mine and mine:FindFirstChild("PlayerData")
end

local function getGlovesValue()
    local playerData = getPlayerData()
    return playerData and playerData:FindFirstChild("Gloves")
end

local function getStyleValue()
    local playerData = getPlayerData()
    return playerData and playerData:FindFirstChild("Style")
end

-- "Ryu" -> name "Ryu", no effect. "Ryu_Blue Fire" -> name "Ryu", effect "Blue Fire".
local function splitSide(raw)
    local name, effect = string.match(raw or "", "^([^_]*)_?(.*)$")
    if effect == nil or effect == "" then
        effect = nil
    end
    return { name = name or "", effect = effect }
end

local function originalSides()
    local parts = string.split(Custom.original or "", "|")
    return splitSide(parts[1]), splitSide(parts[2] or parts[1])
end

local function currentSides()
    local value = getGlovesValue()
    local parts = string.split(value and value.Value or "", "|")
    return splitSide(parts[1]), splitSide(parts[2] or parts[1])
end

local function captureOriginal()
    if Custom.original ~= nil then
        return
    end
    local value = getGlovesValue()
    if value then
        Custom.original = value.Value
    end
end

local function joinSide(name, effect)
    if name == nil or name == "" then
        return nil
    end
    if effect and effect ~= "" then
        return name .. "_" .. effect
    end
    return name
end

local function buildTarget()
    local left, right = originalSides()

    left.name = Custom.gloveLeft or left.name
    if Custom.gloveLink then
        right.name = Custom.gloveLeft or right.name
    else
        right.name = Custom.gloveRight or right.name
    end

    local effect = Custom.effectName ~= "None" and Custom.effectName or nil
    left.effect = effect
    right.effect = effect

    local leftString = joinSide(left.name, left.effect)
    local rightString = joinSide(right.name, right.effect)
    if leftString == nil and rightString == nil then
        return nil
    end
    if leftString == nil then
        leftString = rightString
    end
    if rightString == nil then
        rightString = leftString
    end
    return leftString .. "|" .. rightString
end

local applyNow

local function bindValue()
    local value = getGlovesValue()
    if value == Custom.value and Custom.valueConn then
        return
    end
    if Custom.valueConn then
        pcall(function()
            Custom.valueConn:Disconnect()
        end)
        Custom.valueConn = nil
    end
    Custom.value = value
    if not value then
        return
    end
    Custom.valueConn = value.Changed:Connect(function()
        if Custom.quiet then
            return
        end
        if Custom.enabled then
            task.defer(applyNow)
        end
    end)
end

applyNow = function()
    local value = getGlovesValue()
    if not value then
        return
    end

    if Custom.original == nil then
        Custom.original = value.Value
    end

    local target = Custom.original
    if Custom.enabled then
        target = buildTarget()
        if target == nil then
            return
        end
    end

    if value.Value == target then
        return
    end

    Custom.quiet = true
    local ok, err = pcall(function()
        value.Value = target
    end)
    Custom.quiet = false

    if not ok then
        warn("[VoltScriptZ] Customization write failed:", err)
    end
end

-- Style is purely cosmetic: StarterCharacterScripts.Animate2 reads
-- PlayerData.Style every frame and swaps the movement animations, so a
-- local write is enough. Punches stay server-driven.

local applyStyleNow

local function captureOriginalStyle()
    if Custom.originalStyle ~= nil then
        return
    end
    local value = getStyleValue()
    if value then
        Custom.originalStyle = value.Value
    end
end

local function bindStyleValue()
    local value = getStyleValue()
    if value == Custom.styleValue and Custom.styleConn then
        return
    end
    if Custom.styleConn then
        pcall(function()
            Custom.styleConn:Disconnect()
        end)
        Custom.styleConn = nil
    end
    Custom.styleValue = value
    if not value then
        return
    end
    Custom.styleConn = value.Changed:Connect(function()
        if Custom.styleQuiet then
            return
        end
        if Custom.styleEnabled then
            task.defer(applyStyleNow)
        end
    end)
end

applyStyleNow = function()
    local value = getStyleValue()
    if not value then
        return
    end

    if Custom.originalStyle == nil then
        Custom.originalStyle = value.Value
    end

    local target = Custom.originalStyle
    if Custom.styleEnabled and Custom.styleName and Custom.styleName ~= "" then
        target = Custom.styleName
    end
    if target == nil or value.Value == target then
        return
    end

    Custom.styleQuiet = true
    local ok, err = pcall(function()
        value.Value = target
    end)
    Custom.styleQuiet = false

    if not ok then
        warn("[VoltScriptZ] Style write failed:", err)
    end
end

function Custom.destroy()
    if Custom.valueConn then
        pcall(function()
            Custom.valueConn:Disconnect()
        end)
        Custom.valueConn = nil
    end
    if Custom.styleConn then
        pcall(function()
            Custom.styleConn:Disconnect()
        end)
        Custom.styleConn = nil
    end
    for _, conn in ipairs(Custom.conns) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    table.clear(Custom.conns)

    if Custom.enabled and Custom.original ~= nil then
        local value = getGlovesValue()
        if value and value.Value ~= Custom.original then
            pcall(function()
                value.Value = Custom.original
            end)
        end
    end

    if Custom.styleEnabled and Custom.originalStyle ~= nil then
        local value = getStyleValue()
        if value and value.Value ~= Custom.originalStyle then
            pcall(function()
                value.Value = Custom.originalStyle
            end)
        end
    end

    if Custom.mapCleanup then
        pcall(Custom.mapCleanup)
    end

    Custom.enabled = false
    Custom.styleEnabled = false
end

-- ------------------------------------------------------------ data

local RARITY_ORDER = { Exotic = 1, Legendary = 2, Mythic = 3, Rare = 4, Uncommon = 5, Common = 6 }
local FALLBACK_EFFECTS = {
    "Arctic", "Bats", "Black Flash", "Black Hole", "Blood", "Blue Fire", "Broken", "Cold",
    "Cosmic", "Crows", "Devotion", "Dragon Fire", "Dusk", "Ecto", "Firecracker", "Flames",
    "Fox", "Frostbite", "Galaxy", "Ghost", "Grinch", "Instinct", "Jade", "Lantern",
    "Legendary", "Lightning", "Love", "Magic", "Martian", "Merry", "Mistletoe", "Nebula",
    "Onyx", "Passion", "Petals", "Poison", "Possessed", "Prankster", "Pumpkins", "Quasar",
    "Ripple", "Santa's Rage", "Shards", "Snow", "Spark", "Spectral", "Starlight", "Toxic",
    "Troll", "Water"
}

local GloveList = {}
local RarityOptions = { "All" }
local EffectOptions = { "None" }

do
    local folder = ReplicatedStorage:FindFirstChild("Gloves")
    if folder then
        local seen = {}
        for _, model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") then
                local rarity = nil
                local metadata = model:FindFirstChild("Metadata")
                if metadata then
                    local ok, data = pcall(require, metadata)
                    if ok and type(data) == "table" and type(data.Rarity) == "string" then
                        rarity = data.Rarity
                    end
                end
                if rarity then
                    GloveList[#GloveList + 1] = { name = model.Name, rarity = rarity }
                    seen[rarity] = true
                end
            end
        end

        local extras = {}
        for rarity in pairs(seen) do
            extras[#extras + 1] = rarity
        end
        table.sort(extras, function(a, b)
            local rankA, rankB = RARITY_ORDER[a] or 99, RARITY_ORDER[b] or 99
            if rankA ~= rankB then
                return rankA < rankB
            end
            return a < b
        end)
        for _, rarity in ipairs(extras) do
            RarityOptions[#RarityOptions + 1] = rarity
        end

        table.sort(GloveList, function(a, b)
            return a.name < b.name
        end)
    end
end

do
    local names = {}
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local helper = modules and modules:FindFirstChild("UnusualHelper")
    local effects = helper and helper:FindFirstChild("Effects")
    if effects then
        for _, child in ipairs(effects:GetChildren()) do
            names[#names + 1] = child.Name
        end
    end
    if #names == 0 then
        names = FALLBACK_EFFECTS
    end
    table.sort(names)
    for _, name in ipairs(names) do
        EffectOptions[#EffectOptions + 1] = name
    end
end

local STYLE_RARITY_ORDER = { Limited = 1, Exotic = 2, Legendary = 3, Mythic = 4, Rare = 5, Uncommon = 6, Other = 7 }
local FALLBACK_STYLES = {
    { "Akuma", "AKUMA STYLE", "Limited" },
    { "AncientGhost", "Ghost of the Past", "Other" },
    { "Aoki", "Trickster Style", "Rare" },
    { "Basic", "Basic Style", "Uncommon" },
    { "Bullet", "Bullet Style", "Mythic" },
    { "Charge", "Charge Style", "Rare" },
    { "Chronos", "Chronos Style", "Legendary" },
    { "Date", "Corkscrew Style", "Rare" },
    { "Dragonfish", "Dragonfish Style", "Rare" },
    { "DrillShiny", "Drill Style", "Other" },
    { "Freedom", "Freedom Style", "Legendary" },
    { "Ghost", "Ghost Style", "Legendary" },
    { "GodspeedShiny", "Godspeed Style", "Other" },
    { "Hammer", "Hammer Style", "Rare" },
    { "Hawk", "Hawk Style", "Legendary" },
    { "Hitman", "Hitman Style", "Mythic" },
    { "Ippo", "Dempsey Style", "Mythic" },
    { "IronFist", "Iron Fist Style", "Legendary" },
    { "Joe", "White Ash Style", "Legendary" },
    { "LongGuard", "Long Guard Style", "Uncommon" },
    { "Miyata", "Counter Style", "Uncommon" },
    { "Monstrosity", "Deimos Style", "Legendary" },
    { "NanomachinesShiny", "Nanomachines Style", "Other" },
    { "Ryu", "RYU STYLE", "Limited" },
    { "Saeki", "Hands Low Style", "Mythic" },
    { "Sendo", "Smash Style", "Uncommon" },
    { "Shotgun", "Shotgun Style", "Legendary" },
    { "Supernova", "Supernova Style", "Legendary" },
    { "Surgeon", "Surgeon Style", "Mythic" },
    { "SwitchHit", "Switch Hit Style", "Mythic" },
    { "Takamura", "Slugger Style", "Legendary" },
    { "Turtle", "Turtle Style", "Uncommon" },
    { "VoidSamurai", "Void Samurai Style", "Other" },
    { "Volk", "Wolf Style", "Mythic" }
}

local StyleList = {}
local StyleRarityOptions = { "All" }
local StyleByLabel = {}

do
    local ReplicatedFirst = game:GetService("ReplicatedFirst")
    local animations = ReplicatedFirst:FindFirstChild("Animations")
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local stylesModule = modules and modules:FindFirstChild("Styles")

    local rows = {}
    if stylesModule and animations then
        local ok, styles = pcall(require, stylesModule)
        if ok and type(styles) == "table" then
            for name, data in pairs(styles) do
                if type(name) == "string" and type(data) == "table" then
                    local display = data.DisplayName
                    if type(display) == "string"
                        and data.Hidden ~= true
                        and data.Unobtainable ~= true
                        and data.MovementAnimations ~= nil
                        and animations:FindFirstChild(name) ~= nil
                    then
                        rows[#rows + 1] = {
                            name = name,
                            label = display,
                            rarity = type(data.Rarity) == "string" and data.Rarity or "Other"
                        }
                    end
                end
            end
        end
    end

    if #rows == 0 then
        for _, entry in ipairs(FALLBACK_STYLES) do
            rows[#rows + 1] = { name = entry[1], label = entry[2], rarity = entry[3] }
        end
    end

    -- Sort before de-duplicating so a shared display name keeps the base
    -- style (Monstrosity over MonstrosityMonster, LongGuard over VeryLongGuard).
    table.sort(rows, function(a, b)
        local rankA, rankB = STYLE_RARITY_ORDER[a.rarity] or 99, STYLE_RARITY_ORDER[b.rarity] or 99
        if rankA ~= rankB then
            return rankA < rankB
        end
        return a.name < b.name
    end)

    local seenLabels = {}
    local seenRarity = {}
    for _, row in ipairs(rows) do
        if not seenLabels[row.label] then
            seenLabels[row.label] = true
            StyleList[#StyleList + 1] = row
            StyleByLabel[row.label] = row.name
            seenRarity[row.rarity] = true
        end
    end

    -- Keep a hidden or unobtainable style that is currently equipped
    -- selectable instead of silently showing a different one.
    local current = getStyleValue()
    local currentName = current and current.Value or ""
    if currentName ~= "" and seenLabels[currentName] == nil then
        local known = false
        for _, style in ipairs(StyleList) do
            if style.name == currentName then
                known = true
                break
            end
        end
        if not known then
            StyleList[#StyleList + 1] = { name = currentName, label = currentName, rarity = "Other" }
            StyleByLabel[currentName] = currentName
            seenRarity["Other"] = true
        end
    end

    table.sort(StyleList, function(a, b)
        return a.label < b.label
    end)

    local extras = {}
    for rarity in pairs(seenRarity) do
        extras[#extras + 1] = rarity
    end
    table.sort(extras, function(a, b)
        local rankA, rankB = STYLE_RARITY_ORDER[a] or 99, STYLE_RARITY_ORDER[b] or 99
        if rankA ~= rankB then
            return rankA < rankB
        end
        return a < b
    end)
    for _, rarity in ipairs(extras) do
        StyleRarityOptions[#StyleRarityOptions + 1] = rarity
    end
end

local function filteredStyles()
    local list = {}
    for _, style in ipairs(StyleList) do
        if Custom.styleRarity == "All" or style.rarity == Custom.styleRarity then
            list[#list + 1] = style.label
        end
    end
    return list
end

local function labelForStyle(name)
    for _, style in ipairs(StyleList) do
        if style.name == name then
            return style.label
        end
    end
    return nil
end

local function filteredGloves()
    local list = {}
    for _, glove in ipairs(GloveList) do
        if Custom.rarity == "All" or glove.rarity == Custom.rarity then
            list[#list + 1] = glove.name
        end
    end
    return list
end

captureOriginal()

do
    local startLeft, startRight = currentSides()
    Custom.gloveLeft = startLeft.name ~= "" and startLeft.name or "Default"
    Custom.gloveRight = startRight.name ~= "" and startRight.name or Custom.gloveLeft
end

local initialLeft = Custom.gloveLeft
local initialRight = Custom.gloveRight

captureOriginalStyle()

do
    local value = getStyleValue()
    Custom.styleName = value and value.Value or nil
end

local initialStyle = labelForStyle(Custom.styleName) or (StyleList[1] and StyleList[1].label) or "Basic Style"

-- ------------------------------------------------------------ ui

local GloveCard = CustomTab:AddCard({
    Title = "Glove",
    Subtitle = "Gloves and effects",
    Toggle = false,
    Column = 1
})

local GloveLeftDropdown
local GloveRightDropdown

GloveCard:AddToggle({
    Name = "Enable",
    Flag = "Custom_Enabled",
    Default = false,
    Callback = function(value)
        Custom.enabled = value
        applyNow()
    end
})

GloveCard:AddDropdown({
    Name = "Rarity",
    Flag = "Custom_Rarity",
    Options = RarityOptions,
    Default = "All",
    Callback = function(value)
        Custom.rarity = value
        local list = filteredGloves()
        if GloveLeftDropdown then
            GloveLeftDropdown:Refresh(list)
            GloveLeftDropdown:Set(Custom.gloveLeft, true)
        end
        if GloveRightDropdown then
            GloveRightDropdown:Refresh(list)
            GloveRightDropdown:Set(Custom.gloveRight, true)
        end
    end
})

GloveLeftDropdown = GloveCard:AddDropdown({
    Name = "Left",
    Flag = "Custom_GloveLeft",
    Options = filteredGloves(),
    Default = initialLeft,
    Callback = function(value)
        Custom.gloveLeft = value
        if Custom.gloveLink and GloveRightDropdown then
            GloveRightDropdown:Set(value, true)
            Custom.gloveRight = value
        end
        applyNow()
    end
})

GloveCard:AddToggle({
    Name = "Link Hands",
    Flag = "Custom_GloveLink",
    Default = true,
    Callback = function(value)
        Custom.gloveLink = value
        if value and GloveRightDropdown then
            GloveRightDropdown:Set(Custom.gloveLeft, true)
            Custom.gloveRight = Custom.gloveLeft
        end
        applyNow()
    end
})

GloveRightDropdown = GloveCard:AddDropdown({
    Name = "Right",
    Flag = "Custom_GloveRight",
    Options = filteredGloves(),
    Default = initialRight,
    Callback = function(value)
        Custom.gloveRight = value
        if Custom.gloveLink then
            return
        end
        applyNow()
    end
})

GloveCard:AddDivider()

GloveCard:AddDropdown({
    Name = "Effect",
    Flag = "Custom_Effect",
    Options = EffectOptions,
    Default = "None",
    Callback = function(value)
        Custom.effectName = value
        applyNow()
    end
})

local StyleCard = CustomTab:AddCard({
    Title = "Style",
    Subtitle = "Movement style",
    Toggle = false,
    Column = 2
})

local StyleDropdown

StyleCard:AddToggle({
    Name = "Enable",
    Flag = "Style_Enabled",
    Default = false,
    Callback = function(value)
        Custom.styleEnabled = value
        applyStyleNow()
    end
})

StyleCard:AddDropdown({
    Name = "Rarity",
    Flag = "Style_Rarity",
    Options = StyleRarityOptions,
    Default = "All",
    Callback = function(value)
        Custom.styleRarity = value
        if StyleDropdown then
            StyleDropdown:Refresh(filteredStyles())
            StyleDropdown:Set(labelForStyle(Custom.styleName) or initialStyle, true)
        end
    end
})

StyleDropdown = StyleCard:AddDropdown({
    Name = "Style",
    Flag = "Style_Name",
    Options = filteredStyles(),
    Default = initialStyle,
    Callback = function(value)
        Custom.styleName = StyleByLabel[value] or value
        applyStyleNow()
    end
})

-- ------------------------------------------------------------ map visual

-- The server only replicates the map that is currently loaded, so the swap is
-- done locally: the chosen map is pulled from the game's own LazyStorage,
-- cloned, aligned to the arena ring and drawn over the real map. The real map
-- stays collidable (its parts are only hidden) and nothing is written to
-- PlayerData, so the server never sees the change.

local CollectionService = game:GetService("CollectionService")

local MapList = {}
local MapByLabel = {}

do
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local mapsModule = modules and modules:FindFirstChild("Maps")
    local ok, maps = pcall(function()
        return mapsModule and require(mapsModule)
    end)
    if ok and type(maps) == "table" then
        local seen = {}
        for name, data in pairs(maps) do
            if type(name) == "string" and type(data) == "table" then
                local display = type(data.DisplayName) == "string" and data.DisplayName or name
                if display ~= "" and display ~= "NONE" and not seen[display] then
                    seen[display] = true
                    MapList[#MapList + 1] = { name = name, label = display }
                    MapByLabel[display] = name
                end
            end
        end
    end
    if #MapList == 0 then
        for _, name in ipairs({ "TianHongYuan", "HeavensArena", "Dojo", "Lava", "Disco", "Void" }) do
            local label = string.upper(name)
            MapList[#MapList + 1] = { name = name, label = label }
            MapByLabel[label] = name
        end
    end
    table.sort(MapList, function(a, b)
        return a.label < b.label
    end)
end

local MapOverride = {
    enabled = false,
    name = nil,
    failed = nil,
    models = {},
    realMap = nil,
    realSample = nil,
    display = nil,
    displayParts = nil,
    hidden = {},
    token = 0,
    alive = true,
    lazy = nil
}
getgenv().VoltMapOverride = MapOverride

local function mapValue()
    local playerData = getPlayerData()
    return playerData and playerData:FindFirstChild("Map")
end

local function labelForMap(name)
    for _, entry in ipairs(MapList) do
        if entry.name == name then
            return entry.label
        end
    end
    return nil
end

local function getLazyStorage()
    if MapOverride.lazy then
        return MapOverride.lazy
    end
    local ok, module = pcall(function()
        return require(game:GetService("ReplicatedFirst"):WaitForChild("LazyStorage", 30))
    end)
    if ok then
        MapOverride.lazy = module
    end
    return MapOverride.lazy
end

-- the arena map the game is currently using: the tagged model once a fight is
-- running, otherwise the one waiting in workspace.MapCache
local function findRealMap()
    local fallback
    for _, inst in ipairs(CollectionService:GetTagged("Map")) do
        if inst:IsA("Model") and inst:IsDescendantOf(workspace) and inst ~= MapOverride.display then
            local ring = inst:FindFirstChild("Ring")
            if ring and ring:FindFirstChild("Hitboxes") then
                return inst
            end
            fallback = fallback or inst
        end
    end
    local cache = workspace:FindFirstChild("MapCache")
    if cache then
        for _, inst in ipairs(cache:GetChildren()) do
            if inst:IsA("Model") then
                return inst
            end
        end
    end
    return fallback
end

local function ringMain(map)
    local ring = map and map:FindFirstChild("Ring")
    local hitboxes = ring and ring:FindFirstChild("Hitboxes")
    return hitboxes and hitboxes:FindFirstChild("Main")
end

local function ringCFrame(map)
    local main = ringMain(map)
    return main and main.CFrame or nil
end

local function fetchMap(name)
    local key = "m_" .. name
    if MapOverride.models[key] then
        return MapOverride.models[key]
    end
    local lazy = getLazyStorage()
    if not lazy then
        return nil
    end
    -- never destroy the model that comes back: LazyStorage hands out the same
    -- instance on every later call, so the pristine copy is kept for cloning
    local ok, model = pcall(function()
        return lazy:Get(key)
    end)
    if ok and typeof(model) == "Instance" and model:IsA("Model") and #model:GetDescendants() > 0 then
        MapOverride.models[key] = model
        return model
    end
    return nil
end

local function restoreMap()
    for inst, original in pairs(MapOverride.hidden) do
        if inst.Parent then
            pcall(function()
                local current = inst.LocalTransparencyModifier
                if math.abs(current - (original + 1000)) < 0.5 then
                    inst.LocalTransparencyModifier = original
                else
                    inst.LocalTransparencyModifier = math.max(0, current - 1000)
                end
            end)
        end
    end
    table.clear(MapOverride.hidden)
end

local function hideRealMap(map)
    if not map then
        return
    end
    local function hide(inst)
        if inst:IsA("BasePart") or inst:IsA("Decal") then
            local original = MapOverride.hidden[inst]
            if original == nil then
                original = inst.LocalTransparencyModifier
                MapOverride.hidden[inst] = original
            end
            inst.LocalTransparencyModifier = original + 1000
        end
    end
    hide(map)
    for _, inst in ipairs(map:GetDescendants()) do
        hide(inst)
    end
end

local function clearDisplay()
    if MapOverride.display then
        MapOverride.display:Destroy()
        MapOverride.display = nil
    end
    MapOverride.displayParts = nil
end

local function buildDisplay(fetched, realMap)
    local clone = fetched:Clone()
    clone.Name = "VoltMapOverride"

    local parts = {}
    for _, inst in ipairs(clone:GetDescendants()) do
        if inst:IsA("BasePart") then
            -- the real map keeps its collision, this copy is only pixels
            inst.CanCollide = false
            inst.CanTouch = false
            inst.CanQuery = false
            inst.Anchored = true
            inst.LocalTransparencyModifier = 0
            parts[#parts + 1] = inst
        elseif inst:IsA("Decal") then
            inst.LocalTransparencyModifier = 0
            parts[#parts + 1] = inst
        elseif inst:IsA("Light") then
            -- the real map's lights are still enabled, skip the duplicates
            inst.Enabled = false
        end
    end

    local cloneRing = clone:FindFirstChild("Ring")
    local cloneHitboxes = cloneRing and cloneRing:FindFirstChild("Hitboxes")
    local cloneMain = cloneHitboxes and cloneHitboxes:FindFirstChild("Main")
    local target = ringCFrame(realMap)

    if cloneMain then
        clone.PrimaryPart = cloneMain
        if target then
            clone:PivotTo(target)
        end
    elseif target then
        -- a few event maps have no Ring; drop the bounding box on the arena
        local ok, box = pcall(function()
            return clone:GetBoundingBox()
        end)
        if ok then
            clone:PivotTo(clone:GetPivot() + (target.Position - box.Position))
        end
    end

    clone.Parent = workspace
    MapOverride.display = clone
    MapOverride.displayParts = parts
end

local function teardownMap()
    MapOverride.token = MapOverride.token + 1
    clearDisplay()
    restoreMap()
    MapOverride.realMap = nil
    MapOverride.realSample = nil
end

local applyOverride

applyOverride = function()
    if not MapOverride.enabled or not MapOverride.name then
        return
    end

    MapOverride.token = MapOverride.token + 1
    local token = MapOverride.token
    local name = MapOverride.name

    task.spawn(function()
        local realMap = findRealMap()
        if token ~= MapOverride.token or not MapOverride.enabled then
            return
        end
        MapOverride.realMap = realMap

        if not realMap then
            clearDisplay()
            restoreMap()
            return
        end

        -- the game already shows the chosen map: nothing to draw
        if realMap.Name == "m_" .. name then
            clearDisplay()
            restoreMap()
            MapOverride.realSample = nil
            return
        end

        local fetched = fetchMap(name)
        if token ~= MapOverride.token or not MapOverride.enabled then
            return
        end
        if not fetched then
            MapOverride.failed = name
            MapOverride.realMap = nil
            clearDisplay()
            restoreMap()
            if Window.Notify then
                Window:Notify({ Title = "Map", Text = name .. " is not available" })
            end
            return
        end

        clearDisplay()
        restoreMap()
        hideRealMap(realMap)
        MapOverride.realSample = ringMain(realMap) or (realMap:IsA("BasePart") and realMap or nil)
        buildDisplay(fetched, realMap)
    end)
end

local initialMapLabel
do
    local value = mapValue()
    initialMapLabel = labelForMap(value and value.Value or "")
        or (MapList[1] and MapList[1].label)
        or ""
end

local MapCard = CustomTab:AddCard({
    Title = "Map",
    Subtitle = "Map visual",
    Toggle = false,
    Column = 1
})

local MapDropdown

MapCard:AddToggle({
    Name = "Enable",
    Flag = "Map_Enabled",
    Default = false,
    Callback = function(value)
        MapOverride.enabled = value
        MapOverride.failed = nil
        if value then
            local label = MapDropdown and MapDropdown:Get()
            MapOverride.name = MapByLabel[label] or MapOverride.name or (MapList[1] and MapList[1].name)
            applyOverride()
        else
            teardownMap()
        end
    end
})

MapDropdown = MapCard:AddDropdown({
    Name = "Map",
    Flag = "Map_Name",
    Options = (function()
        local labels = {}
        for _, entry in ipairs(MapList) do
            labels[#labels + 1] = entry.label
        end
        return labels
    end)(),
    Default = initialMapLabel,
    Callback = function(value)
        MapOverride.name = MapByLabel[value] or value
        MapOverride.failed = nil
        if MapOverride.enabled then
            applyOverride()
        end
    end
})

-- Fights rebuild the world: the game parents a fresh map in and hides every
-- workspace child. Follow the real map and put the clone back on top.
task.spawn(function()
    while MapOverride.alive do
        task.wait(1)
        if MapOverride.enabled and MapOverride.name and MapOverride.failed ~= MapOverride.name then
            local real = findRealMap()
            if real ~= MapOverride.realMap then
                applyOverride()
            else
                local wanted = real ~= nil and real.Name ~= "m_" .. MapOverride.name
                if wanted and (MapOverride.display == nil or MapOverride.display.Parent ~= workspace) then
                    applyOverride()
                elseif MapOverride.display then
                    local parts = MapOverride.displayParts
                    local sample = parts and (parts[1] or parts[#parts])
                    -- the game's hideWorld pass adds +1000 to every workspace
                    -- child when a fight starts; undo it on our copy
                    if sample and sample.Parent and sample.LocalTransparencyModifier > 0.001 then
                        for _, inst in ipairs(parts) do
                            if inst.Parent then
                                inst.LocalTransparencyModifier = 0
                            end
                        end
                    end
                    -- ResetMap can make the real map visible again
                    local realSample = MapOverride.realSample
                    if MapOverride.realMap
                        and realSample
                        and realSample.Parent
                        and realSample.LocalTransparencyModifier < 1000 then
                        hideRealMap(MapOverride.realMap)
                    end
                end
            end
        end
    end
end)

Custom.mapCleanup = function()
    MapOverride.alive = false
    teardownMap()
    table.clear(MapOverride.models)
end

-- ------------------------------------------------------------ init

Custom.apply = applyNow
Custom.applyStyle = applyStyleNow
bindValue()
bindStyleValue()

Custom.conns[#Custom.conns + 1] = LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    bindValue()
    bindStyleValue()
    applyNow()
    applyStyleNow()
end)

-- ============================================================
-- Utilities
-- ============================================================

local Engine = {
    active = true,
    conns = {},
    opponentConns = {},
    token = 0,
    character = nil,
    opponent = nil,
    lastDirection = nil,
    lastDirectionAt = 0,
    lastFireAt = 0,
    handled = {},
    blockBridge = nil,
    tryBlockFn = nil,
    tryUnblockFn = nil,
    blocking = false,
    blockConfirmed = false,
    blockUntil = 0,
    feintArmUntil = 0,
    feintLandTime = nil,
    feintTargetValue = nil,
    pendingValue = nil,
    blockPending = false,
    stats = { seen = 0, fired = 0, skipped = 0, blocks = 0, feintDodges = 0, feintBlocks = 0, feintSkips = 0 }
}
getgenv().VoltDodge = Engine

local function getController()
    local character = LocalPlayer.Character
    if not character then
        return nil
    end
    local ok, list = pcall(filtergc, "table", { Keys = { "TapDashCooldown", "CurrentDashId", "CharacterData" } }, false)
    if not ok or type(list) ~= "table" then
        return nil
    end
    if type(list.Character) == "Instance" then
        if list.Character == character and type(list.TryDash) == "function" then
            return list
        end
        return nil
    end
    for _, candidate in ipairs(list) do
        if type(candidate) == "table" and candidate.Character == character and type(candidate.TryDash) == "function" then
            return candidate
        end
    end
    return nil
end

local function getCharacterData()
    local states = Workspace:FindFirstChild("States")
    local mine = states and states:FindFirstChild(LocalPlayer.Name)
    return mine and mine:FindFirstChild("CharacterData")
end

local function getStamina()
    local characterData = getCharacterData()
    local stamina = characterData and characterData:FindFirstChild("Stamina")
    return stamina and stamina.Value or nil
end

local function getOccupied()
    local states = Workspace:FindFirstChild("States")
    local mine = states and states:FindFirstChild(LocalPlayer.Name)
    return mine and mine:FindFirstChild("Occupied")
end

local function getOpponent()
    local characterData = getCharacterData()
    local opponent = characterData and characterData:FindFirstChild("Opponent")
    if opponent and opponent.Value then
        return opponent.Value
    end
    local occupied = getOccupied()
    local lockedOn = occupied and occupied:FindFirstChild("LockedOn")
    return lockedOn and lockedOn.Value or nil
end

local function getBlockFunctions()
    if not Engine.tryBlockFn then
        local ok, list = pcall(filtergc, "function", { Name = "TryBlock" }, false)
        if ok and type(list) == "table" then
            Engine.tryBlockFn = list[1]
        end
    end
    if not Engine.tryUnblockFn then
        local ok, list = pcall(filtergc, "function", { Name = "TryUnblock" }, false)
        if ok and type(list) == "table" then
            Engine.tryUnblockFn = list[1]
        end
    end
    return Engine.tryBlockFn, Engine.tryUnblockFn
end

local function getBlockBridge()
    if Engine.blockBridge then
        return Engine.blockBridge
    end
    local bridgeNet = game:GetService("ReplicatedFirst"):FindFirstChild("BridgeNet2")
    if not bridgeNet then
        return nil
    end
    local ok, bridge = pcall(function()
        return require(bridgeNet).ReferenceBridge("HandleBlock")
    end)
    if ok and bridge then
        Engine.blockBridge = bridge
        return bridge
    end
    return nil
end

local function setBlock(on)
    local tryBlock, tryUnblock = getBlockFunctions()
    if on then
        if tryBlock then
            task.spawn(function()
                pcall(tryBlock)
            end)
            return true
        end
    elseif tryUnblock then
        pcall(tryUnblock)
        return true
    end

    local bridge = getBlockBridge()
    if not bridge then
        return false
    end
    local occupied = getOccupied()
    local occupiedBlocking = occupied and occupied:FindFirstChild("Blocking")
    local ok = pcall(function()
        bridge:Fire(on)
    end)
    if occupiedBlocking then
        pcall(function()
            occupiedBlocking.Value = on
        end)
    end
    return ok
end

local function startBlock()
    if not State.BlockFeint then
        return
    end
    if Engine.blocking then
        if Engine.blockConfirmed then
            Engine.blockUntil = os.clock() + State.BlockHold / 1000
        end
        return
    end
    local dashController = getController()
    local dashOccupied = dashController and dashController.Occupied
    if dashOccupied and dashOccupied.Dashing and dashOccupied.Dashing.Value then
        -- The guard cannot be raised mid-dash. Retry as soon as the dash ends.
        if not Engine.blockPending then
            Engine.blockPending = true
            task.spawn(function()
                local deadline = os.clock() + 0.5
                while Engine.active and os.clock() < deadline do
                    local c = getController()
                    local o = c and c.Occupied
                    if not (o and o.Dashing and o.Dashing.Value) then
                        break
                    end
                    task.wait(0.02)
                end
                Engine.blockPending = false
                if Engine.active and State.BlockFeint then
                    startBlock()
                end
            end)
        end
        return
    end
    local characterData = getCharacterData()
    local cdBlocking = characterData and characterData:FindFirstChild("Blocking")
    if cdBlocking and cdBlocking.Value then
        return
    end
    Engine.blocking = true
    Engine.blockConfirmed = false
    Engine.blockUntil = os.clock() + 1.5
    Engine.stats.blocks = Engine.stats.blocks + 1
    setBlock(true)
end

local function stopBlock()
    if not Engine.blocking then
        return
    end
    Engine.blocking = false
    Engine.blockConfirmed = false
    Engine.blockUntil = 0
    setBlock(false)
end

local function pruneTable(target)
    local count = 0
    for _ in pairs(target) do
        count = count + 1
    end
    if count > 60 then
        return {}
    end
    return target
end

local function markHandled(stamp)
    if stamp == nil then
        return
    end
    Engine.handled[stamp] = true
    Engine.handled = pruneTable(Engine.handled)
end

local function perpendicularDirection(character)
    local opponent = Engine.opponent
    local myRoot = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
    local theirRoot = opponent and (opponent.PrimaryPart or opponent:FindFirstChild("HumanoidRootPart"))
    if not myRoot or not theirRoot then
        return "Left"
    end
    local offset = theirRoot.Position - myRoot.Position
    offset = Vector3.new(offset.X, 0, offset.Z)
    if offset.Magnitude < 0.01 then
        return "Left"
    end
    local right = myRoot.CFrame.RightVector
    right = Vector3.new(right.X, 0, right.Z)
    if right.Magnitude < 0.01 then
        return "Left"
    end
    if offset.Unit:Dot(right.Unit) > 0 then
        return "Left"
    end
    return "Right"
end

local function resolveDirection(character)
    if State.Direction == "Always Left" then
        return "Left"
    elseif State.Direction == "Always Right" then
        return "Right"
    elseif State.Direction == "Backward" or State.Direction == "Away" then
        return "Backward"
    end

    local cached = Engine.lastDirection
    if cached and (os.clock() - Engine.lastDirectionAt) > 0.5 then
        cached = nil
    end
    cached = cached or character:GetAttribute("NeededDirection")
    if cached == "Left" or cached == "Right" then
        return cached
    end
    return perpendicularDirection(character)
end

-- control-space vectors the game's Styles:GetDash understands
-- (-X left, +X right, +Z backward, |Z| > 0.8 for backward)
local DASH_MOVE_VECTORS = {
    Left = Vector3.new(-1, 0, 0),
    Right = Vector3.new(1, 0, 0),
    Backward = Vector3.new(0, 0, 1)
}

-- "In Place": the game always slides the character somewhere during a dash, so
-- a zero MoveVector still ends up moving (tapped with no input it goes forward).
-- The only reliable way to stay put is to pin the root for the length of the
-- dash - the dash state, i-frames and animation all keep running.
local InPlace = {
    root = nil,
    conn = nil,
    anchored = false
}

local function stopInPlace()
    if InPlace.conn then
        pcall(function()
            InPlace.conn:Disconnect()
        end)
        InPlace.conn = nil
    end
    if InPlace.root and InPlace.anchored and InPlace.root.Parent then
        pcall(function()
            InPlace.root.Anchored = false
        end)
    end
    InPlace.root = nil
    InPlace.anchored = false
end

local function startInPlace(character)
    local root = character and (character.PrimaryPart or character:FindFirstChild("HumanoidRootPart"))
    if not root then
        return
    end
    stopInPlace()
    InPlace.root = root
    if not root.Anchored then
        root.Anchored = true
        InPlace.anchored = true
    end

    local started = os.clock()
    InPlace.conn = game:GetService("RunService").Heartbeat:Connect(function()
        local now = os.clock()
        local occupied = getOccupied()
        local dashing = occupied and occupied.Dashing and occupied.Dashing.Value
        -- release once the dash is over, but never hold longer than 0.7s
        if not root.Parent or (now - started > 0.12 and not dashing) or (now - started > 0.7) then
            stopInPlace()
            pcall(function()
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end)
        end
    end)
end

getgenv().VoltInPlace = { start = startInPlace, stop = stopInPlace }

local function fire(token, force)
    if token ~= Engine.token then
        return
    end
    if not State.AutoDodge and not force then
        return
    end
    -- The dash is committed late on purpose, so a feint flag may have arrived
    -- while we were waiting. Keep the arm for the follow-up punch.
    if not force and Engine.feintArmUntil > os.clock() and type(Engine.feintTargetValue) == "number"
        and type(Engine.pendingValue) == "number" and Engine.pendingValue == Engine.feintTargetValue then
        Engine.stats.feintSkips = Engine.stats.feintSkips + 1
        return
    end

    local character = LocalPlayer.Character
    if not character then
        return
    end

    local function skip()
        Engine.stats.skipped = Engine.stats.skipped + 1
    end

    local controller = getController()
    if not controller then
        skip()
        return
    end

    local stamina = getStamina()
    if stamina and stamina < State.MinStamina then
        skip()
        return
    end

    local occupied = controller.Occupied
    if not force and occupied and occupied.Dashing and occupied.Dashing.Value then
        skip()
        return
    end

    local now = os.clock()
    if not force and (now - Engine.lastFireAt) < 0.08 then
        skip()
        return
    end

    local direction = resolveDirection(character)
    Engine.lastFireAt = now
    Engine.stats.fired = Engine.stats.fired + 1

    -- "In Place" uses the game's own Standing dash: the same call a player makes
    -- by tapping Space with no movement input (no Direction, no MoveVector). The
    -- game then labels it Standing and plays that animation, and the root is
    -- pinned for the duration so the residual slide (~3 studs) does not happen.
    if State.Direction == "In Place" then
        Engine.lastDash = { direction = "Standing", move = Vector3.new(0, 0, 0), at = now }
        pcall(function()
            controller:TryDash({ MoveVector = Vector3.new(0, 0, 0) })
        end)
        startInPlace(character)
        return
    end

    -- Direction only relabels the dash; the movement itself comes from MoveVector
    -- (control space: -X = left, +X = right, +Z = backward). Without this the
    -- character keeps its input vector and drifts forward instead of strafing.
    local move = DASH_MOVE_VECTORS[direction] or Vector3.new(0, 0, 0)

    Engine.lastDash = { direction = direction, move = move, at = now }

    pcall(function()
        controller:TryDash({ Direction = direction, MoveVector = move })
    end)
end

-- When "In Place" is selected the player's own Space dash has to behave the
-- same way, so the game's dash is left alone and only the root is pinned.
task.spawn(function()
    local dashKey = Enum.KeyCode.Space
    pcall(function()
        local keybinds = ReplicatedStorage:WaitForChild("Keybinds", 5)
        local key = keybinds and keybinds.GetKeybind and keybinds:GetKeybind("Dash")
        if typeof(key) == "EnumItem" then
            dashKey = key
        end
    end)

    Engine.conns[#Engine.conns + 1] = game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
        if processed or State.Direction ~= "In Place" then
            return
        end
        if input.KeyCode ~= dashKey then
            return
        end
        local character = LocalPlayer.Character
        local occupied = getOccupied()
        if character and getCharacterData() and occupied and occupied.Equipped.Value then
            startInPlace(character)
        end
    end)
end)

local function onPerfect(character)
    local value = character:GetAttribute("Perfect")
    if type(value) ~= "number" then
        return
    end

    Engine.stats.seen = Engine.stats.seen + 1

    local opponent = Engine.opponent or getOpponent()
    if opponent then
        markHandled(opponent:GetAttribute("Punching"))
    end

    Engine.token = Engine.token + 1
    local token = Engine.token

    local force = false
    local skip = false
    if Engine.feintArmUntil > os.clock() and type(Engine.feintLandTime) == "number" then
        if value >= Engine.feintLandTime - 0.02 then
            Engine.feintArmUntil = 0
            Engine.feintLandTime = nil
            Engine.feintTargetValue = nil
            if State.DodgeFeint then
                force = true
            elseif State.BlockFeint then
                skip = true
            end
        end
    end

    if skip then
        Engine.stats.feintBlocks = Engine.stats.feintBlocks + 1
        -- Keep the guard up through the follow-up landing.
        startBlock()
        return
    end

    Engine.pendingValue = value

    local delay = 0
    if force then
        Engine.stats.feintDodges = Engine.stats.feintDodges + 1
    else
        local remaining = value - Workspace:GetServerTimeNow()
        if State.DodgeFeint or State.BlockFeint then
            -- Wait until the punch has already landed. The game rolls a hit back
            -- when a dash arrives inside its RollbackTime window, and the extra
            -- time lets the feint flag arrive before we commit.
            delay = math.max(0, remaining + 0.05)
        else
            local budget = math.max(0, remaining - 0.055)
            delay = math.clamp(State.ReactionDelay / 1000, 0, budget)
        end
    end

    if delay <= 0 then
        fire(token, force)
    else
        task.delay(delay, function()
            fire(token, force)
        end)
    end
end

local function bindOpponent(opponent)
    for _, conn in ipairs(Engine.opponentConns) do
        pcall(function() conn:Disconnect() end)
    end
    Engine.opponentConns = {}
    Engine.opponent = opponent
    if not opponent then
        return
    end

    Engine.opponentConns[#Engine.opponentConns + 1] = opponent:GetAttributeChangedSignal("IsFeinting"):Connect(function()
        if opponent:GetAttribute("IsFeinting") == nil then
            return
        end
        Engine.feintArmUntil = os.clock() + 0.4
        Engine.feintLandTime = opponent:GetAttribute("LandTime")
        Engine.feintTargetValue = Engine.pendingValue
        if State.BlockFeint and not State.DodgeFeint then
            startBlock()
        end
    end)
end

local function bindCharacter(character)
    Engine.character = character
    Engine.lastDirection = nil
    Engine.lastDirectionAt = 0
    Engine.blocking = false
    Engine.blockConfirmed = false
    Engine.blockUntil = 0
    Engine.tryBlockFn = nil
    Engine.tryUnblockFn = nil
    Engine.feintArmUntil = 0
    Engine.feintLandTime = nil
    Engine.feintTargetValue = nil
    Engine.pendingValue = nil
    Engine.blockPending = false

    Engine.conns[#Engine.conns + 1] = character:GetAttributeChangedSignal("Perfect"):Connect(function()
        onPerfect(character)
    end)

    Engine.conns[#Engine.conns + 1] = character:GetAttributeChangedSignal("NeededDirection"):Connect(function()
        local direction = character:GetAttribute("NeededDirection")
        if direction == "Left" or direction == "Right" then
            Engine.lastDirection = direction
            Engine.lastDirectionAt = os.clock()
        end
    end)
end

Engine.conns[#Engine.conns + 1] = LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    bindCharacter(character)
end)

if LocalPlayer.Character then
    bindCharacter(LocalPlayer.Character)
end

task.spawn(function()
    local engine = Engine
    while engine.active do
        local opponent = getOpponent()
        if opponent ~= engine.opponent then
            bindOpponent(opponent)
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    local engine = Engine
    while engine.active do
        if engine.blocking then
            local characterData = getCharacterData()
            local cdBlocking = characterData and characterData:FindFirstChild("Blocking")
            if cdBlocking and cdBlocking.Value then
                if not engine.blockConfirmed then
                    engine.blockConfirmed = true
                    engine.blockUntil = os.clock() + State.BlockHold / 1000
                elseif os.clock() >= engine.blockUntil then
                    stopBlock()
                end
            elseif os.clock() >= engine.blockUntil then
                stopBlock()
            end
        end
        task.wait(0.03)
    end
end)

-- ===== ESP =====
local RunService = game:GetService("RunService")

local DrawingLib = rawget(getgenv(), "Drawing") or Drawing
local HasDrawing = false
if DrawingLib ~= nil then
    local ok, fn = pcall(function()
        return DrawingLib.new
    end)
    HasDrawing = ok and type(fn) == "function"
end

local EspPool = {}
local EspCleaned = false
local EspWarned = false

local function espDestroySet(set)
    if not set then
        return
    end
    for _, obj in pairs(set) do
        pcall(function()
            obj:Remove()
        end)
    end
end

local function espHideSet(set)
    if not set then
        return
    end
    for _, obj in pairs(set) do
        pcall(function()
            obj.Visible = false
        end)
    end
end

local function espNewSet()
    local set = {}
    local ok = pcall(function()
        set.BoxOut = DrawingLib.new("Square")
        set.BoxOut.Filled = false
        set.BoxOut.Thickness = 3
        set.BoxOut.Color = Color3.fromRGB(0, 0, 0)
        set.BoxOut.Visible = false

        set.Box = DrawingLib.new("Square")
        set.Box.Filled = false
        set.Box.Thickness = 1
        set.Box.Color = Color3.fromRGB(255, 255, 255)
        set.Box.Visible = false

        set.HealthBack = DrawingLib.new("Line")
        set.HealthBack.Thickness = 3
        set.HealthBack.Color = Color3.fromRGB(0, 0, 0)
        set.HealthBack.Visible = false

        set.HealthBar = DrawingLib.new("Line")
        set.HealthBar.Thickness = 3
        set.HealthBar.Color = Color3.fromRGB(0, 255, 100)
        set.HealthBar.Visible = false

        set.StaminaBack = DrawingLib.new("Line")
        set.StaminaBack.Thickness = 3
        set.StaminaBack.Color = Color3.fromRGB(0, 0, 0)
        set.StaminaBack.Visible = false

        set.StaminaBar = DrawingLib.new("Line")
        set.StaminaBar.Thickness = 3
        set.StaminaBar.Color = Color3.fromRGB(255, 170, 0)
        set.StaminaBar.Visible = false

        set.Tag = DrawingLib.new("Text")
        set.Tag.Size = 14
        set.Tag.Center = true
        set.Tag.Outline = true
        set.Tag.Color = Color3.fromRGB(255, 255, 255)
        set.Tag.Visible = false

        set.StateTag = DrawingLib.new("Text")
        set.StateTag.Size = 13
        set.StateTag.Center = true
        set.StateTag.Outline = true
        set.StateTag.Visible = false
    end)
    if not ok then
        espDestroySet(set)
        return nil
    end
    return set
end

local function espClearAll()
    for player, set in pairs(EspPool) do
        espDestroySet(set)
        EspPool[player] = nil
    end
end

getgenv().VoltEsp = { destroy = espClearAll }

local function espDrawPlayer(player, character, head, root, distance, camera, viewport, states)
    local topPos = head.Position + Vector3.new(0, 0.7, 0)
    local botPos = root.Position - Vector3.new(0, 2.8, 0)
    local top, topOn = camera:WorldToViewportPoint(topPos)
    local bot, botOn = camera:WorldToViewportPoint(botPos)

    local set = EspPool[player]
    if not topOn or not botOn then
        espHideSet(set)
        return
    end

    local height = math.abs(bot.Y - top.Y)
    if height < 4 or height > 1200 then
        espHideSet(set)
        return
    end

    local width = height * 0.62
    local centerX = (top.X + bot.X) / 2
    local centerY = (top.Y + bot.Y) / 2
    if centerX < -width or centerX > viewport.X + width or centerY < -height or centerY > viewport.Y + height then
        espHideSet(set)
        return
    end

    if not set then
        set = espNewSet()
        if not set then
            return
        end
        EspPool[player] = set
    end

    local x = centerX - width / 2
    local y = centerY - height / 2

    set.BoxOut.Visible = State.EspBox
    set.Box.Visible = State.EspBox
    if State.EspBox then
        set.BoxOut.Position = Vector2.new(x, y)
        set.BoxOut.Size = Vector2.new(width, height)
        set.Box.Position = Vector2.new(x, y)
        set.Box.Size = Vector2.new(width, height)
    end

    local state = states and states:FindFirstChild(player.Name)
    local characterData = state and state:FindFirstChild("CharacterData")
    local healthObj = characterData and characterData:FindFirstChild("Health")
    local staminaObj = characterData and characterData:FindFirstChild("Stamina")
    local blockingObj = characterData and characterData:FindFirstChild("Blocking")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    local healthFrac = 1
    if healthObj and type(healthObj.Value) == "number" then
        local maxHealth = humanoid and humanoid.MaxHealth or 100
        if maxHealth <= 0 then
            maxHealth = 100
        end
        healthFrac = math.clamp(healthObj.Value / maxHealth, 0, 1)
    elseif humanoid and humanoid.MaxHealth > 0 then
        healthFrac = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    end

    local staminaFrac = 0
    if staminaObj and type(staminaObj.Value) == "number" then
        staminaFrac = math.clamp(staminaObj.Value / 100, 0, 1)
    end

    set.HealthBack.Visible = State.EspHealth
    set.HealthBar.Visible = State.EspHealth
    if State.EspHealth then
        local barX = x - 6
        set.HealthBack.From = Vector2.new(barX, y)
        set.HealthBack.To = Vector2.new(barX, y + height)
        set.HealthBar.From = Vector2.new(barX, y + height * (1 - healthFrac))
        set.HealthBar.To = Vector2.new(barX, y + height)
    end

    set.StaminaBack.Visible = State.EspStamina
    set.StaminaBar.Visible = State.EspStamina
    if State.EspStamina then
        local barX = x + width + 6
        set.StaminaBack.From = Vector2.new(barX, y)
        set.StaminaBack.To = Vector2.new(barX, y + height)
        set.StaminaBar.From = Vector2.new(barX, y + height * (1 - staminaFrac))
        set.StaminaBar.To = Vector2.new(barX, y + height)
    end

    set.Tag.Visible = State.EspName
    if State.EspName then
        set.Tag.Text = string.format("%s [%d]", player.Name, math.floor(distance))
        set.Tag.Position = Vector2.new(centerX, y - 16)
    end

    set.StateTag.Visible = State.EspPunch
    if State.EspPunch then
        local label = "IDLE"
        local color = Color3.fromRGB(170, 170, 170)
        local feinting = character:GetAttribute("IsFeinting")
        local punching = character:GetAttribute("Punching")
        if feinting then
            label = "FEINT"
            color = Color3.fromRGB(255, 210, 0)
        elseif punching then
            label = "PUNCH"
            color = Color3.fromRGB(255, 60, 60)
        elseif blockingObj and blockingObj.Value then
            label = "BLOCK"
            color = Color3.fromRGB(80, 180, 255)
        end
        set.StateTag.Text = label
        set.StateTag.Color = color
        set.StateTag.Position = Vector2.new(centerX, y + height + 4)
    end
end

local function espUpdate()
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    local viewport = camera.ViewportSize

    for player, set in pairs(EspPool) do
        local ok, parent = pcall(function()
            return player.Parent
        end)
        if not ok or parent ~= Players then
            espDestroySet(set)
            EspPool[player] = nil
        end
    end

    if not State.Esp then
        for _, set in pairs(EspPool) do
            espHideSet(set)
        end
        return
    end

    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        for _, set in pairs(EspPool) do
            espHideSet(set)
        end
        return
    end

    local states = Workspace:FindFirstChild("States")

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local head = character and character:FindFirstChild("Head")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not character or not head or not root then
                espHideSet(EspPool[player])
            else
                local distance = (root.Position - myRoot.Position).Magnitude
                if distance > State.EspMaxDistance then
                    espHideSet(EspPool[player])
                else
                    pcall(espDrawPlayer, player, character, head, root, distance, camera, viewport, states)
                end
            end
        end
    end
end

Engine.conns[#Engine.conns + 1] = RunService.RenderStepped:Connect(function()
    if not Engine.active then
        if not EspCleaned then
            EspCleaned = true
            espClearAll()
        end
        return
    end
    if not HasDrawing then
        if not EspWarned then
            EspWarned = true
            print("[VoltScriptZ] Drawing API not available - ESP disabled")
        end
        return
    end
    pcall(espUpdate)
end)

-- ============================================================
-- Utilities
-- Client-side helpers only: nothing here fires a remote, so it is
-- safe to flip any of them during a match.
-- ============================================================

local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local function voltUiRoot()
    if type(gethui) == "function" then
        local ok, hidden = pcall(gethui)
        if ok and hidden then
            return hidden
        end
    end
    return game:GetService("CoreGui")
end

local function voltBlackScreen(on)
    pcall(function()
        local root = voltUiRoot()
        local old = root:FindFirstChild("VoltBlack")
        if old then
            old:Destroy()
        end
        if not on then
            return
        end
        local gui = Instance.new("ScreenGui")
        gui.Name = "VoltBlack"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 500
        local cover = Instance.new("Frame")
        cover.Size = UDim2.fromScale(1, 1)
        cover.BackgroundColor3 = Color3.new(0, 0, 0)
        cover.BorderSizePixel = 0
        cover.Active = false
        cover.Parent = gui
        gui.Parent = root
    end)
end

local function voltLowQuality(on)
    pcall(function()
        local rendering = settings().Rendering
        local lighting = game:GetService("Lighting")
        if on then
            if not State._gfxOrig then
                State._gfxOrig = { Quality = rendering.QualityLevel, Shadows = lighting.GlobalShadows }
            end
            rendering.QualityLevel = Enum.QualityLevel.Level01
            lighting.GlobalShadows = false
        elseif State._gfxOrig then
            rendering.QualityLevel = State._gfxOrig.Quality
            lighting.GlobalShadows = State._gfxOrig.Shadows
            State._gfxOrig = nil
        end
    end)
end

local function voltApplyFps()
    pcall(function()
        if State.FpsLock then
            if not State._fpsOrig then
                local ok, current = pcall(getfpscap)
                State._fpsOrig = (ok and current) or 60
            end
            setfpscap(State.FpsCap or 240)
        elseif State._fpsOrig then
            setfpscap(State._fpsOrig)
            State._fpsOrig = nil
        end
    end)
end

local function voltFullbright(on)
    pcall(function()
        local lighting = game:GetService("Lighting")
        if on then
            if not State._lightOrig then
                State._lightOrig = {
                    Brightness = lighting.Brightness,
                    Ambient = lighting.Ambient,
                    OutdoorAmbient = lighting.OutdoorAmbient,
                    ClockTime = lighting.ClockTime,
                    FogEnd = lighting.FogEnd
                }
            end
            lighting.Brightness = 2
            lighting.Ambient = Color3.fromRGB(178, 178, 178)
            lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
            lighting.ClockTime = 12
            lighting.FogEnd = 100000
        elseif State._lightOrig then
            local saved = State._lightOrig
            lighting.Brightness = saved.Brightness
            lighting.Ambient = saved.Ambient
            lighting.OutdoorAmbient = saved.OutdoorAmbient
            lighting.ClockTime = saved.ClockTime
            lighting.FogEnd = saved.FogEnd
            State._lightOrig = nil
        end
    end)
end

-- stream mode: swap our own name for a placeholder in every label we can reach.
-- Only what is DISPLAYED is rewritten (label text + humanoid display name); real
-- instance names (HumanoidRootPart, Head, ...) are left alone so animations and
-- the game's own lookups keep working.
local STREAM_ALIAS = "VoltScriptZ"

local function voltStreamMask(restoreOnly)
    pcall(function()
        State._streamOrig = State._streamOrig or {}
        if restoreOnly then
            for inst, text in pairs(State._streamOrig) do
                pcall(function()
                    if inst and inst.Parent then
                        inst.Text = text
                    end
                end)
            end
            State._streamOrig = {}
            pcall(function()
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.DisplayName = State._streamDisplayOrig or LocalPlayer.DisplayName
                end
            end)
            State._streamDisplayOrig = nil
            return
        end

        -- every string that identifies us, so "SinsodX1", "SINSODX1" and
        -- "SinsodX1 (You)" all match
        local keys = {}
        for _, raw in ipairs({ LocalPlayer.Name, LocalPlayer.DisplayName }) do
            raw = tostring(raw)
            if #raw >= 3 then
                keys[#keys + 1] = string.lower(raw)
            end
        end
        if #keys == 0 then
            return
        end

        local function inVoltUi(inst)
            local node = inst
            while node do
                if node.Name == "VoltScriptZ" then
                    return true
                end
                node = node.Parent
            end
            return false
        end

        -- replace every occurrence anywhere in the string, so text that wraps
        -- our name in a sentence ("NAME - 100 HP", "NAME (You)") is covered too
        local function scrub(text)
            local lower = string.lower(text)
            local pieces, i, changed = {}, 1, false
            while true do
                local at, len
                for _, key in ipairs(keys) do
                    local found = string.find(lower, key, i, true)
                    if found and (not at or found < at) then
                        at, len = found, #key
                    end
                end
                if not at then
                    pieces[#pieces + 1] = string.sub(text, i)
                    break
                end
                pieces[#pieces + 1] = string.sub(text, i, at - 1)
                pieces[#pieces + 1] = STREAM_ALIAS
                i = at + len
                changed = true
            end
            if not changed then
                return nil
            end
            return table.concat(pieces)
        end

        local function mask(inst)
            if not (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox")) then
                return
            end
            if inVoltUi(inst) then
                return
            end
            local text = tostring(inst.Text)
            if text == "" then
                return
            end
            local masked = scrub(text)
            if not masked then
                return
            end
            if State._streamOrig[inst] == nil then
                State._streamOrig[inst] = text
            end
            inst.Text = masked
        end

        local function scan(root)
            if not root then
                return
            end
            pcall(mask, root)
            local ok, list = pcall(function()
                return root:GetDescendants()
            end)
            if not ok or not list then
                return
            end
            for _, descendant in ipairs(list) do
                pcall(mask, descendant)
            end
        end

        local character = LocalPlayer.Character
        if character then
            scan(character)
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.DisplayName ~= STREAM_ALIAS then
                if State._streamDisplayOrig == nil then
                    State._streamDisplayOrig = humanoid.DisplayName
                end
                humanoid.DisplayName = STREAM_ALIAS
            end
        end

        -- HUD, menus, damage feed and anything else the game draws for us
        scan(LocalPlayer:FindFirstChildOfClass("PlayerGui"))

        -- the two slower spots are only rescanned every third pass: they are
        -- big trees and the game touches them far less often than its HUD
        State._streamTick = (State._streamTick or 0) + 1
        if State._streamTick % 3 == 0 then
            -- the overhead nameplate and other surface billboards live in Workspace
            scan(Workspace:FindFirstChild("SurfaceBillboards"))

            -- names the game does not own: leaderboard, chat, bubble chat
            local core = game:GetService("CoreGui")
            for _, name in ipairs({ "PlayerList", "ExperienceChat", "AppChat", "BubbleChat" }) do
                local ok, gui = pcall(function()
                    return core:FindFirstChild(name, true)
                end)
                if ok and gui then
                    scan(gui)
                end
            end
        end
    end)
end

local function voltCopyJobId()
    local jobId = game.JobId
    local ok = pcall(function()
        setclipboard(jobId)
    end)
    if Window.Notify then
        Window:Notify({ Title = "Job ID", Text = ok and "Copied" or jobId })
    end
end

local function voltRejoin()
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    if not ok and Window.Notify then
        Window:Notify({ Title = "Rejoin", Text = "Failed: " .. tostring(err) })
    end
end

local PerfCard = UtilTab:AddCard({
    Title = "Performance",
    Subtitle = "Reduce lag and save power",
    Toggle = false,
    Column = 1
})

PerfCard:AddToggle({
    Name = "Black Screen",
    Flag = "Util_BlackScreen",
    Default = false,
    Callback = function(value)
        State.BlackScreen = value
        voltBlackScreen(value)
    end
})

PerfCard:AddToggle({
    Name = "Low Quality",
    Flag = "Util_LowQuality",
    Default = false,
    Callback = function(value)
        State.LowQuality = value
        voltLowQuality(value)
    end
})

PerfCard:AddToggle({
    Name = "FPS Lock",
    Flag = "Util_FpsLock",
    Default = false,
    Callback = function(value)
        State.FpsLock = value
        voltApplyFps()
    end
})

PerfCard:AddSlider({
    Name = "FPS Cap",
    Flag = "Util_FpsCap",
    Min = 30,
    Max = 240,
    Increment = 10,
    Default = 240,
    Callback = function(value)
        State.FpsCap = value
        voltApplyFps()
    end
})

local MiscCard = UtilTab:AddCard({
    Title = "Misc",
    Subtitle = "Extra helpers",
    Toggle = false,
    Column = 2
})

MiscCard:AddToggle({
    Name = "Anti AFK",
    Flag = "Util_AntiAFK",
    Default = true,
    Callback = function(value)
        State.AntiAFK = value
    end
})

MiscCard:AddToggle({
    Name = "Fullbright",
    Flag = "Util_Fullbright",
    Default = false,
    Callback = function(value)
        State.Fullbright = value
        voltFullbright(value)
    end
})

MiscCard:AddToggle({
    Name = "Stream Mode (Hide Name)",
    Flag = "Util_StreamMode",
    Default = false,
    Callback = function(value)
        State.StreamMode = value
        if value then
            voltStreamMask(false)
        else
            voltStreamMask(true)
        end
    end
})

MiscCard:AddDivider()

MiscCard:AddButton({
    Name = "Copy Job ID",
    Callback = function()
        voltCopyJobId()
    end
})

MiscCard:AddButton({
    Name = "Rejoin Server",
    Callback = function()
        voltRejoin()
    end
})

MiscCard:AddLabel("Anti AFK keeps the server from kicking you while idle.\nStream Mode shows \"VoltScriptZ\" instead of your name in the HUD, overhead nameplate, leaderboard and chat.")

Engine.conns[#Engine.conns + 1] = LocalPlayer.Idled:Connect(function()
    if not State.AntiAFK then
        return
    end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

task.spawn(function()
    while Engine.active do
        task.wait(1)
        if State.StreamMode then
            voltStreamMask(false)
        end
    end
    if State.StreamMode then
        pcall(voltStreamMask, true)
    end
end)

-- ============================================================
-- Settings
-- ============================================================

-- A saved config writes straight into the UI flags silently, so State
-- would still hold the old values. Push every flag back through its own
-- callback to keep the engine and the menu in sync after a load.
local function voltResyncFromFlags()
    for _, obj in pairs(Window.Flags) do
        if type(obj) == "table" and type(obj.Get) == "function" and type(obj.Set) == "function" then
            pcall(function()
                local value = obj:Get()
                if type(value) == "number" then
                    -- sliders only fire their callback on a real change, and a
                    -- one-step nudge can round back to the same value, so push
                    -- them all the way down first
                    obj:Set(value - 1000000, true)
                    obj:Set(value, false)
                else
                    obj:Set(value, false)
                end
            end)
        end
    end
end

do
    local rawLoadConfig = Window.LoadConfig
    Window.LoadConfig = function(self, name)
        local ok = rawLoadConfig(self, name)
        if ok then
            pcall(voltResyncFromFlags)
        end
        return ok
    end
end

local InterfaceCard = SettingsTab:AddCard({
    Title = "Interface",
    Subtitle = "Menu appearance",
    Toggle = false,
    Column = 1
})

InterfaceCard:AddSlider({
    Name = "UI Scale",
    Flag = "Settings_UiScale",
    Min = 50,
    Max = 100,
    Increment = 5,
    Suffix = "%",
    Default = 100,
    Callback = function(value)
        pcall(function()
            local scale = Window.UIScale or (Window.Main and Window.Main:FindFirstChildOfClass("UIScale"))
            if scale then
                scale.Scale = (Window.BaseScale or 1) * (value / 100)
            end
        end)
    end
})

InterfaceCard:AddLabel("RightCtrl shows or hides the menu.")

local ConfigCard = SettingsTab:AddCard({
    Title = "Configs",
    Subtitle = "Save and load your settings",
    Toggle = false,
    Column = 2
})

local HttpService = game:GetService("HttpService")

local ConfigNameBox = ConfigCard:AddTextbox({
    Name = "Config",
    Default = "main",
    Placeholder = "my-config"
})

local ConfigList = ConfigCard:AddDropdown({
    Name = "Saved",
    Options = { "(no configs)" },
    Default = "(no configs)",
    Callback = function(value)
        if value and value ~= "(no configs)" then
            ConfigNameBox:Set(value, true)
        end
    end
})

-- VoltUi puts every script's .json in the same folder, so a file only counts
-- as one of ours when its contents carry flags this menu owns. That keeps the
-- list clean (main, pvp, ...) without tagging the names.
local CONFIG_MARKERS = { "Util_FpsCap", "Dodge_ReactionDelay", "Esp_MaxDistance" }

local function isOurConfig(baseName)
    local ok, raw = pcall(function()
        return readfile(baseName .. ".json")
    end)
    if not ok or type(raw) ~= "string" then
        return false
    end
    local decodedOk, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not decodedOk or type(decoded) ~= "table" then
        return false
    end
    for _, marker in ipairs(CONFIG_MARKERS) do
        if decoded[marker] ~= nil then
            return true
        end
    end
    return false
end

local function configNames()
    local out = {}
    local ok, names = pcall(function()
        return Window:ListConfigs()
    end)
    if not ok or type(names) ~= "table" then
        return out
    end
    for _, name in ipairs(names) do
        if isOurConfig(name) then
            out[#out + 1] = name
        end
    end
    return out
end

local function refreshConfigs(select)
    local names = configNames()
    if #names == 0 then
        names = { "(no configs)" }
    end
    ConfigList:Refresh(names)
    if select and table.find(names, select) then
        ConfigList:Set(select, true)
    end
end

local function chosenConfig()
    local value = tostring(ConfigNameBox:Get() or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if value == "" then
        value = "main"
    end
    return value
end

refreshConfigs()

-- "Set Up Auto Load" remembers one config name in a small text file; the
-- script reads it back on the next launch and loads that config itself.
-- Nothing is saved automatically after that - only the name is remembered.
local AUTOLOAD_FILE = "VoltScriptZ_UBG_autoload.txt"

local function readAutoLoad()
    local ok, value = pcall(function()
        return readfile(AUTOLOAD_FILE)
    end)
    if not ok or value == nil then
        return nil
    end
    value = string.gsub(tostring(value), "%s+$", "")
    if value == "" then
        return nil
    end
    return value
end

local autoLoadInfo = ConfigCard:AddInfo({ Text = "Auto Load", Value = readAutoLoad() or "None" })

ConfigCard:AddButton({
    Name = "Save",
    Callback = function()
        local file = chosenConfig()
        local ok = pcall(function()
            Window:SaveConfig(file)
        end)
        refreshConfigs(file)
        Window:Notify({ Title = "Config", Text = ok and ("Saved: " .. file) or ("Save failed: " .. file) })
    end
})

ConfigCard:AddButton({
    Name = "Load",
    Callback = function()
        local file = chosenConfig()
        local ok = Window:LoadConfig(file)
        refreshConfigs(file)
        Window:Notify({ Title = "Config", Text = ok and ("Loaded: " .. file) or ("Not found: " .. file) })
    end
})

ConfigCard:AddButton({
    Name = "Delete",
    Callback = function()
        local file = chosenConfig()
        local ok = pcall(function()
            Window:DeleteConfig(file)
        end)
        if readAutoLoad() == file then
            pcall(function()
                delfile(AUTOLOAD_FILE)
            end)
            autoLoadInfo:Set("None")
        end
        refreshConfigs()
        Window:Notify({ Title = "Config", Text = ok and ("Deleted: " .. file) or ("Delete failed: " .. file) })
    end
})

ConfigCard:AddButton({
    Name = "Set Up Auto Load",
    Callback = function()
        local file = chosenConfig()
        local ok = pcall(function()
            writefile(AUTOLOAD_FILE, file)
        end)
        if ok then
            autoLoadInfo:Set(file)
            Window:Notify({ Title = "Auto Load", Text = "Enabled: " .. file })
        else
            Window:Notify({ Title = "Auto Load", Text = "Could not write autoload file" })
        end
    end
})

-- load the config that was marked for auto load, if any
do
    local name = readAutoLoad()
    if name then
        if Window:LoadConfig(name) then
            refreshConfigs(name)
        else
            autoLoadInfo:Set("None (missing)")
        end
    end
end

-- reload hook: undo the client-side changes this run made
Engine.cleanup = function()
    pcall(voltBlackScreen, false)
    if State._streamOrig then
        pcall(voltStreamMask, true)
    end
    if State._gfxOrig then
        pcall(voltLowQuality, false)
    end
    if State._fpsOrig then
        pcall(setfpscap, State._fpsOrig)
        State._fpsOrig = nil
    end
    if State._lightOrig then
        pcall(voltFullbright, false)
    end
end

return "ui built"
