local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CollectLeaf = Remotes:WaitForChild("CollectLeaf")
local EmptyBackpack = Remotes:WaitForChild("EmptyBackpack")
local LeafSim = require(LocalPlayer.PlayerScripts:WaitForChild("LeafSim"))
local Folder = LeafSim.folder

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Leaf Farm",
    Icon = "leaf",
    Folder = "LeafFarm",
    Size = UDim2.fromOffset(480, 340),
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.RightShift,
    Author = "Made by VoltScriptZ",
})

local TabFarm = Window:Tab({
    Title = "Auto Farm",
    Icon = "sprout",
})

TabFarm:Select()

local TabPlayer = Window:Tab({
    Title = "Player",
    Icon = "user",
})

local TabSettings = Window:Tab({
    Title = "Settings",
    Icon = "settings",
})

local autoCollect = false
local autoSell = false
local collectRadius = 5
local speedEnabled = false
local walkSpeed = 16
local humanoid = nil
local collectCooldown = 0

TabFarm:Toggle({
    Title = "Auto Collect",
    Desc = "Collect leaves automatically",
    Value = false,
    Callback = function(state)
        autoCollect = state
    end,
})

TabFarm:Toggle({
    Title = "Auto Sell",
    Desc = "Sell leaves automatically",
    Value = false,
    Callback = function(state)
        autoSell = state
    end,
})

TabFarm:Slider({
    Title = "Collect Radius",
    Desc = "Leaf collection range (studs)",
    Value = { Min = 1, Max = 30, Default = 5 },
    Step = 1,
    Callback = function(value)
        collectRadius = value
    end,
})

TabPlayer:Toggle({
    Title = "Speed Hack",
    Desc = "Increase walk speed",
    Value = false,
    Callback = function(state)
        speedEnabled = state
        if humanoid then
            humanoid.WalkSpeed = state and walkSpeed or 16
        end
    end,
})

TabPlayer:Slider({
    Title = "WalkSpeed",
    Desc = "Walk speed",
    Value = { Min = 16, Max = 33, Default = 16 },
    Step = 1,
    Callback = function(value)
        walkSpeed = value
        if humanoid and speedEnabled then
            humanoid.WalkSpeed = value
        end
    end,
})

local KeyCodes = {
    "RightShift", "LeftShift", "RightControl", "LeftControl",
    "F6", "F7", "F8", "F9",
}

TabSettings:Dropdown({
    Title = "Toggle Menu Key",
    Desc = "Key to open/close this menu",
    Values = KeyCodes,
    Value = "RightShift",
    Callback = function(selected)
        Window:SetToggleKey(Enum.KeyCode[selected])
    end,
})

TabSettings:Paragraph({
    Title = "Credits",
    Desc = "Made by VoltScriptZ",
})

local function getHumanoid()
    local char = LocalPlayer.Character
    if char then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then
            humanoid = h
            if speedEnabled then
                humanoid.WalkSpeed = walkSpeed
            end
            return h
        end
    end
    return nil
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    getHumanoid()
end)

getHumanoid()

local function doAutoCollect()
    if not autoCollect then return end
    collectCooldown = collectCooldown + 1
    if collectCooldown < 3 then return end
    collectCooldown = 0

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local parts = Folder:GetChildren()
    if #parts == 0 then return end

    local nearby = {}
    for _, v in ipairs(parts) do
        if v:IsA("BasePart") and (v.Position - hrp.Position).Magnitude <= collectRadius then
            table.insert(nearby, v)
            if #nearby >= 5 then break end
        end
    end

    if #nearby > 0 then
        LeafSim.collectMany(nearby)
    end
end

local function doAutoSell()
    if not autoSell then return end
    local leaves = LocalPlayer:GetAttribute("Leaves") or 0
    if leaves > 0 then
        EmptyBackpack:FireServer()
    end
end

RunService.Heartbeat:Connect(function()
    if autoCollect then
        task.spawn(doAutoCollect)
    end
    if autoSell then
        task.spawn(doAutoSell)
    end
end)

WindUI:Notify({
    Title = "Leaf Farm",
    Content = "Press RightShift to toggle menu",
    Duration = 3,
    Icon = "leaf",
})
