local FluentSource = game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua")
FluentSource = FluentSource:gsub("#488AB6", "#4C1D95"):gsub("488AB6", "4C1D95")
FluentSource = FluentSource:gsub("72%s*,%s*138%s*,%s*182", "76, 29, 149")
FluentSource = FluentSource:gsub("60%s*,%s*205%s*,%s*255", "76, 29, 149")
FluentSource = FluentSource:gsub("96%s*,%s*205%s*,%s*255", "76, 29, 149")
local Fluent = loadstring(FluentSource)()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
-- Anti AFK always on (no toggle)
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    pcall(function()
        LocalPlayer.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end)
    while task.wait(300) do
        if Fluent and Fluent.Unloaded then break end
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)
local Window = Fluent:CreateWindow({
    Title = "VoltScriptZ | Ride A Egg",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 420),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})
local Tabs = {
    Main = Window:AddTab({ Title = "Auto Farm", Icon = "egg" }),
    Shop = Window:AddTab({ Title = "Shop", Icon = "shopping-cart" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}
local Options = Fluent.Options
local Config = {
    Enabled=false,
    PlaceEnabled=false,
    HatchEnabled=false,
    BuyEnabled=false,
    FeedEnabled=false,
    RebirthEnabled=false,
    TweenSpeed=300,
    Rarities={Common=false,Rare=false,Epic=false,Legendary=false,Mythic=false,Divine=false,Ethereal=false},
    PlaceRarities={Common=false,Rare=false,Epic=false,Legendary=false,Mythic=false,Divine=false,Ethereal=false},
    BuyFoods={Grass=false,Bone=false,Meat=false,["Magic Apple"]=false,Dragonfruit=false},
    FeedFoods={Grass=false,Bone=false,Meat=false,["Magic Apple"]=false,Dragonfruit=false}
}
local Farming=false
local Placing=false
local Hatching=false
local Buying=false
local Feeding=false
local Rebirthing=false
local NoclipConn=nil
local function setNoclip(state)
    if state then
        if NoclipConn then NoclipConn:Disconnect() end
        NoclipConn = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _,v in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then
                        v.CanCollide=false
                    end
                end
            end
        end)
    else
        if NoclipConn and not Config.Enabled and not Config.PlaceEnabled and not Config.HatchEnabled and not Config.BuyEnabled and not Config.FeedEnabled then
            NoclipConn:Disconnect() NoclipConn=nil
        end
    end
end
local function getEggsData()
    local ok, mod = pcall(function() return require(ReplicatedStorage.GameData.Eggs) end)
    if ok and type(mod)=="table" then return mod end
    return {}
end
local function getActiveEggsFolder()
    local sd = ReplicatedStorage:FindFirstChild("ServerData")
    if sd and sd:FindFirstChild("ActiveEggs") then return sd.ActiveEggs end
    return ReplicatedStorage:FindFirstChild("ActiveEggs")
end
local function getMyPlot()
    local ok, General = pcall(function() return require(ReplicatedStorage.GameServices.General) end)
    if ok and General and General.GetPlot then
        local p = General:GetPlot(LocalPlayer)
        if p then return p end
    end
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        for _,pl in ipairs(plots:GetChildren()) do
            local d = pl:FindFirstChild("Data")
            if d and d:FindFirstChild("Owner") and d.Owner.Value == LocalPlayer then
                return pl
            end
        end
    end
    return nil
end
local function getAvailableNestId(plot)
    if not plot then return nil end
    local nests = plot:FindFirstChild("Nests")
    if not nests then return nil end
    for _,nest in ipairs(nests:GetChildren()) do
        if nest:GetAttribute("Unlocked") == true and not nest:GetAttribute("Occupied") then
            return nest.Name
        end
    end
    for _,nest in ipairs(nests:GetChildren()) do
        if not nest:GetAttribute("Occupied") then
            return nest.Name
        end
    end
    return nil
end
local function getNestPosition(plot)
    if not plot then return nil end
    return plot.Baseplate.Position + Vector3.new(0,5,0)
end
local function getNestModelPosition(plot, nestId)
    if not plot or not nestId then return getNestPosition(plot) end
    local nest = plot.Nests:FindFirstChild(nestId)
    if not nest then return getNestPosition(plot) end
    local m = nest:FindFirstChild("Model")
    if m then
        local ok, bb = pcall(function() return m:GetBoundingBox() end)
        if ok and bb then return bb.Position end
        local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
        if pp then return pp.Position end
    end
    local pp = nest:FindFirstChildWhichIsA("BasePart", true)
    if pp then return pp.Position end
    return getNestPosition(plot)
end
local function isOnNest(plot, nestId)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not plot then return false end
    local basePos = plot.Baseplate.Position
    if (hrp.Position - basePos).Magnitude <= 65 then
        return true
    end
    local nestPos = getNestModelPosition(plot, nestId)
    if not nestPos then return false end
    return (hrp.Position - nestPos).Magnitude <= 25
end
local function tweenTo(targetPos, speed)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hrp or not targetPos then return false end
    local dist = (hrp.Position - targetPos).Magnitude
    if dist < 2 then return true end
    local duration = math.clamp(dist / (speed or Config.TweenSpeed), 0.1, 30)
    local startCF = hrp.CFrame
    local endCF = CFrame.new(targetPos + Vector3.new(0,3,0))
    local elapsed = 0
    local done = false
    local oldAutoRotate = hum and hum.AutoRotate
    if hum then hum.AutoRotate = false hum.PlatformStand = true end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not hrp.Parent or Fluent.Unloaded then
            done = true
            if conn then conn:Disconnect() end
            if hum then hum.AutoRotate = oldAutoRotate hum.PlatformStand = false end
            return
        end
        if (not Config.Enabled and not Config.PlaceEnabled and not Config.HatchEnabled and not Config.BuyEnabled) or (not Farming and not Placing and not Hatching and not Buying) then
            if not Config.BuyEnabled then
                -- allow tween continue for buy? buy doesn't use tween
            end
        end
        elapsed += dt
        local alpha = math.clamp(elapsed / duration, 0, 1)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = startCF:Lerp(endCF, alpha)
        if alpha >= 1 then
            done = true
            if conn then conn:Disconnect() end
            if hum then hum.AutoRotate = oldAutoRotate hum.PlatformStand = false end
        end
    end)
    while not done do
        if Fluent.Unloaded then break end
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then break end
        task.wait()
    end
    if conn then conn:Disconnect() end
    if hum then hum.AutoRotate = oldAutoRotate hum.PlatformStand = false end
    return done
end
local function getWantedEggs()
    local eggsData = getEggsData()
    local folder = getActiveEggsFolder()
    if not folder then return {} end
    local list = {}
    for _,cfg in ipairs(folder:GetChildren()) do
        local eggName = cfg:GetAttribute("Egg")
        if not eggName then continue end
        local info = eggsData[eggName]
        local rarity = info and info.Rarity or "Common"
        if Config.Rarities[rarity] then
            local pos = cfg:GetAttribute("Position")
            if pos then
                table.insert(list, {cfg=cfg, name=eggName, rarity=rarity, pos=pos})
            end
        end
    end
    return list
end
local function getNearestEgg(list)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or #list==0 then return nil end
    table.sort(list, function(a,b)
        return (a.pos - hrp.Position).Magnitude < (b.pos - hrp.Position).Magnitude
    end)
    return list[1]
end
local function getNextEggToolForPlace()
    local eggsData = getEggsData()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return nil end
    for _,tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:HasTag("Egg") then
            local info = eggsData[tool.Name]
            local rarity = info and info.Rarity or "Common"
            if Config.PlaceRarities[rarity] then
                return tool
            end
        end
    end
    return nil
end
local function startFarm()
    if Farming then return end
    Farming = true
    setNoclip(true)
    task.spawn(function()
        local EggPickup = ReplicatedStorage.Remotes.Game:WaitForChild("EggPickup")
        while Farming and Config.Enabled and not Fluent.Unloaded do
            local ok, err = pcall(function()
                local plot = getMyPlot()
                if not plot then task.wait(0.5) return end
                local nestPos = getNestPosition(plot)
                local wanted = getWantedEggs()
                if #wanted == 0 then task.wait(0.5) return end
                local target = getNearestEgg(wanted)
                if not target then task.wait(0.3) return end
                tweenTo(target.pos, Config.TweenSpeed)
                if not Config.Enabled or not Farming then return end
                if not target.cfg.Parent then return end
                pcall(function() EggPickup:FireServer(target.cfg.Name) end)
                task.wait(0.25)
                if nestPos then
                    tweenTo(nestPos, Config.TweenSpeed)
                end
                task.wait(0.2)
            end)
            if not ok then warn("[VoltScriptZ] Farm error:", err) task.wait(0.5) end
            task.wait(0.1)
        end
        Farming=false
        if not Config.Enabled and not Config.PlaceEnabled and not Config.HatchEnabled and not Config.BuyEnabled and not Config.FeedEnabled then setNoclip(false) end
    end)
end
local function stopFarm()
    Farming=false
    if not Config.Enabled and not Config.PlaceEnabled and not Config.HatchEnabled and not Config.BuyEnabled and not Config.FeedEnabled then setNoclip(false) end
end
local function startPlace()
    if Placing then return end
    Placing = true
    task.spawn(function()
        local EggPlaced = ReplicatedStorage.Remotes.Game:WaitForChild("EggPlaced")
        while Placing and Config.PlaceEnabled and not Fluent.Unloaded do
            local ok, err = pcall(function()
                local plot = getMyPlot()
                if not plot then task.wait(0.5) return end
                local nestId = getAvailableNestId(plot)
                if not nestId then task.wait(1) return end
                if not isOnNest(plot, nestId) then
                    task.wait(0.25)
                    return
                end
                local tool = getNextEggToolForPlace()
                if not tool then task.wait(0.5) return end
                local char = LocalPlayer.Character
                if tool.Parent ~= char then
                    tool.Parent = char
                    task.wait(0.2)
                end
                local equipped = char and char:FindFirstChildWhichIsA("Tool")
                if not equipped or not equipped:HasTag("Egg") then return end
                pcall(function() EggPlaced:FireServer({NestId = nestId}) end)
                task.wait(0.4)
            end)
            if not ok then warn("[VoltScriptZ] Place error:", err) task.wait(0.5) end
            task.wait(0.1)
        end
        Placing=false
    end)
end
local function stopPlace()
    Placing=false
end
local function startHatch()
    if Hatching then return end
    Hatching = true
    task.spawn(function()
        local Hatch = ReplicatedStorage.Remotes.Game:WaitForChild("Hatch")
        while Hatching and Config.HatchEnabled and not Fluent.Unloaded do
            local ok, err = pcall(function()
                local plot = getMyPlot()
                if not plot then task.wait(0.5) return end
                local eggsFolder = plot:FindFirstChild("Eggs")
                if not eggsFolder or #eggsFolder:GetChildren() == 0 then
                    task.wait(0.8)
                    return
                end
                local hatchedAny = false
                for _,egg in ipairs(eggsFolder:GetChildren()) do
                    if not Config.HatchEnabled or not Hatching then break end
                    local eggKey = egg:GetAttribute("EggKey")
                    if eggKey and not egg:HasTag("Hatching") then
                        pcall(function() Hatch:FireServer({EggKey = eggKey}) end)
                        hatchedAny = true
                        task.wait(0.25)
                    end
                end
                if not hatchedAny then
                    task.wait(0.5)
                else
                    task.wait(0.4)
                end
            end)
            if not ok then warn("[VoltScriptZ] Hatch error:", err) task.wait(0.5) end
            task.wait(0.3)
        end
        Hatching=false
    end)
end
local function stopHatch()
    Hatching=false
end
local function startRebirth()
    if Rebirthing then return end
    Rebirthing = true
    task.spawn(function()
        local Rebirth = ReplicatedStorage.Remotes.Game:WaitForChild("Rebirth")
        local RebirthsData = require(ReplicatedStorage.GameData.Rebirths)
        local General = require(ReplicatedStorage.GameData.General)
        local Cash = LocalPlayer:WaitForChild("SavedData"):WaitForChild("Cash")
        local RebirthsVal = LocalPlayer:WaitForChild("SavedData"):WaitForChild("Rebirths")
        local OwnedPetsVal = LocalPlayer:WaitForChild("SavedData"):WaitForChild("OwnedPets")
        while Rebirthing and Config.RebirthEnabled and not Fluent.Unloaded do
            local ok, err = pcall(function()
                local reqs = General.RebirthRequirements
                local idx = math.clamp(RebirthsVal.Value + 1, 1, #reqs)
                local requiredPet = reqs[idx]
                local hasPet = string.find(OwnedPetsVal.Value, requiredPet .. ",", 1, true) ~= nil
                local cost = math.floor(RebirthsData.InitialCost * (RebirthsData.CostMultiplier ^ RebirthsVal.Value))
                if not hasPet then task.wait(1) return end
                if Cash.Value < cost then task.wait(0.8) return end
                pcall(function() Rebirth:FireServer() end)
                task.wait(1.5)
            end)
            if not ok then warn("[VoltScriptZ] Rebirth error:", err) task.wait(0.5) end
            task.wait(0.5)
        end
        Rebirthing=false
    end)
end
local function stopRebirth()
    Rebirthing=false
end
local function getFoodTool()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _,tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:HasTag("Food") then
                if Config.FeedFoods[tool.Name] then return tool end
            end
        end
    end
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildWhichIsA("Tool")
        if tool and tool:HasTag("Food") and Config.FeedFoods[tool.Name] then return tool end
    end
    return nil
end
local function getMyPets()
    local ok, PetRenderer = pcall(function() return require(LocalPlayer.PlayerScripts.Game.Pets.PetRenderer) end)
    if ok and PetRenderer and PetRenderer.GetAll then
        local all = PetRenderer.GetAll()
        local list = {}
        for _,pet in pairs(all) do
            if pet.OwnerUserId == LocalPlayer.UserId and pet.PetKey and pet.Model and pet.Model.Parent then
                table.insert(list, pet)
            end
        end
        if #list > 0 then return list end
    end
    local plot = getMyPlot()
    if plot and plot:FindFirstChild("Pets") then
        local list = {}
        for _,model in ipairs(plot.Pets:GetChildren()) do
            local key = model:GetAttribute("PetKey") or model.Name
            table.insert(list, {PetKey = key, Model = model})
        end
        return list
    end
    return {}
end
local function startFeed()
    if Feeding then return end
    Feeding = true
    task.spawn(function()
        local FeedPet = ReplicatedStorage.Remotes.Game:WaitForChild("FeedPet")
        while Feeding and Config.FeedEnabled and not Fluent.Unloaded do
            local ok, err = pcall(function()
                local pets = getMyPets()
                if #pets == 0 then task.wait(0.8) return end
                local foodTool = getFoodTool()
                if not foodTool then task.wait(0.6) return end
                local char = LocalPlayer.Character
                if foodTool.Parent ~= char then
                    foodTool.Parent = char
                    task.wait(0.2)
                end
                local equipped = char and char:FindFirstChildWhichIsA("Tool")
                if not equipped or not equipped:HasTag("Food") then return end
                local fedAny = false
                for _,pet in ipairs(pets) do
                    if not Config.FeedEnabled or not Feeding then break end
                    local petKey = pet.PetKey
                    if petKey then
                        pcall(function() FeedPet:FireServer(petKey, equipped.Name) end)
                        fedAny = true
                        task.wait(0.35)
                    end
                end
                if not fedAny then task.wait(0.5) else task.wait(0.4) end
            end)
            if not ok then warn("[VoltScriptZ] Feed error:", err) task.wait(0.5) end
            task.wait(0.2)
        end
        Feeding=false
    end)
end
local function stopFeed()
    Feeding=false
end
local function startBuy()
    if Buying then return end
    Buying = true
    task.spawn(function()
        local BuyWithCash = ReplicatedStorage.Remotes.Game:WaitForChild("BuyWithCash")
        local Cash = LocalPlayer:WaitForChild("SavedData"):WaitForChild("Cash")
        local Shop = require(ReplicatedStorage.GameData.Shop)
        while Buying and Config.BuyEnabled and not Fluent.Unloaded do
            local ok, err = pcall(function()
                local hasSelection = false
                for _,v in pairs(Config.BuyFoods) do if v then hasSelection=true break end end
                if not hasSelection then task.wait(0.5) return end
                local bought = false
                for foodName, enabled in pairs(Config.BuyFoods) do
                    if not enabled then continue end
                    local item = Shop.Food[foodName]
                    if not item then continue end
                    local price = item.Price or 0
                    if Cash.Value >= price then
                        pcall(function() BuyWithCash:FireServer("Food", foodName) end)
                        bought = true
                        task.wait(0.35)
                    end
                end
                if not bought then
                    task.wait(0.7)
                else
                    task.wait(0.5)
                end
            end)
            if not ok then warn("[VoltScriptZ] Buy error:", err) task.wait(0.5) end
            task.wait(0.2)
        end
        Buying=false
    end)
end
local function stopBuy()
    Buying=false
end
-- Main Tab
local ToggleFarm = Tabs.Main:AddToggle("AutoFarmEgg", {Title="Auto Farm Egg", Default=false})
ToggleFarm:OnChanged(function()
    Config.Enabled = Options.AutoFarmEgg.Value
    if Config.Enabled then startFarm() else stopFarm() end
end)
local RarityDropdown = Tabs.Main:AddDropdown("RaritySelect", {
    Title="Select Rarity",
    Values={"Common","Rare","Epic","Legendary","Mythic","Divine","Ethereal"},
    Multi=true,
    Default={}
})
RarityDropdown:OnChanged(function(Value)
    local selected = {}
    for k,v in pairs(Value) do if v then selected[k]=true end end
    for _,rar in ipairs({"Common","Rare","Epic","Legendary","Mythic","Divine","Ethereal"}) do
        Config.Rarities[rar] = selected[rar] == true
    end
    if #selected==0 then
        for _,v in pairs(Value) do
            if type(v)=="string" then Config.Rarities[v]=true end
        end
    end
end)
local SpeedSlider = Tabs.Main:AddSlider("TweenSpeed", {
    Title="Tween Speed",
    Default=300,
    Min=50,
    Max=500,
    Rounding=0,
    Callback=function(Value) Config.TweenSpeed = Value end
})
SpeedSlider:OnChanged(function(Value) Config.TweenSpeed = Value end)
SpeedSlider:SetValue(300)
local TogglePlace = Tabs.Main:AddToggle("AutoPlace", {Title="Auto Place", Default=false})
TogglePlace:OnChanged(function()
    Config.PlaceEnabled = Options.AutoPlace.Value
    if Config.PlaceEnabled then startPlace() else stopPlace() end
end)
local PlaceRarityDropdown = Tabs.Main:AddDropdown("PlaceRaritySelect", {
    Title="Select Place Rarity",
    Values={"Common","Rare","Epic","Legendary","Mythic","Divine","Ethereal"},
    Multi=true,
    Default={}
})
PlaceRarityDropdown:OnChanged(function(Value)
    local selected = {}
    for k,v in pairs(Value) do if v then selected[k]=true end end
    for _,rar in ipairs({"Common","Rare","Epic","Legendary","Mythic","Divine","Ethereal"}) do
        Config.PlaceRarities[rar] = selected[rar] == true
    end
    if #selected==0 then
        for _,v in pairs(Value) do
            if type(v)=="string" then Config.PlaceRarities[v]=true end
        end
    end
end)
local ToggleHatch = Tabs.Main:AddToggle("AutoHatch", {Title="Auto Hatch", Default=false})
ToggleHatch:OnChanged(function()
    Config.HatchEnabled = Options.AutoHatch.Value
    if Config.HatchEnabled then startHatch() else stopHatch() end
end)
local ToggleRebirth = Tabs.Main:AddToggle("AutoRebirth", {Title="Auto Rebirth", Default=false})
ToggleRebirth:OnChanged(function()
    Config.RebirthEnabled = Options.AutoRebirth.Value
    if Config.RebirthEnabled then startRebirth() else stopRebirth() end
end)
local FeedSection = Tabs.Main:AddSection("Feed")
local ToggleFeed = FeedSection:AddToggle("AutoFeed", {Title="Auto Feed", Default=false})
ToggleFeed:OnChanged(function()
    Config.FeedEnabled = Options.AutoFeed.Value
    if Config.FeedEnabled then startFeed() else stopFeed() end
end)
local FeedFoodDropdown = FeedSection:AddDropdown("FeedFoodSelect", {
    Title="Select Food",
    Values={"Grass","Bone","Meat","Magic Apple","Dragonfruit"},
    Multi=true,
    Default={}
})
FeedFoodDropdown:OnChanged(function(Value)
    for _,food in ipairs({"Grass","Bone","Meat","Magic Apple","Dragonfruit"}) do Config.FeedFoods[food]=false end
    local selected={}
    for k,v in pairs(Value) do if v then selected[k]=true end end
    for food,_ in pairs(Config.FeedFoods) do if selected[food] then Config.FeedFoods[food]=true end end
    if next(selected)==nil then
        for _,v in pairs(Value) do if type(v)=="string" then Config.FeedFoods[v]=true end end
    end
end)
-- Shop Tab - Food
local ShopSection = Tabs.Shop:AddSection("Food")
local ToggleBuy = Tabs.Shop:AddToggle("AutoBuyFood", {Title="Buy Food", Default=false})
ToggleBuy:OnChanged(function()
    Config.BuyEnabled = Options.AutoBuyFood.Value
    if Config.BuyEnabled then startBuy() else stopBuy() end
end)
local FoodDropdown = Tabs.Shop:AddDropdown("BuyFoodSelect", {
    Title="Select Food",
    Values={"Grass","Bone","Meat","Magic Apple","Dragonfruit"},
    Multi=true,
    Default={}
})
FoodDropdown:OnChanged(function(Value)
    for _,food in ipairs({"Grass","Bone","Meat","Magic Apple","Dragonfruit"}) do
        Config.BuyFoods[food] = false
    end
    local selected = {}
    for k,v in pairs(Value) do if v then selected[k]=true end end
    for food,_ in pairs(Config.BuyFoods) do
        if selected[food] then Config.BuyFoods[food]=true end
    end
    if next(selected)==nil then
        for _,v in pairs(Value) do
            if type(v)=="string" then Config.BuyFoods[v]=true end
        end
    end
end)
-- Settings Tab
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("VoltScriptZ")
SaveManager:SetFolder("VoltScriptZ/RideAEgg")
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
task.spawn(function()
    local purple = Color3.fromHex("#4C1D95")
    local function isBlue(c)
        return c and c.B > 0.55 and c.G > 0.4 and c.R < 0.45
    end
    local function recolor()
        for _,v in ipairs(game.CoreGui:GetDescendants()) do
            if (v:IsA("Frame") or v:IsA("TextButton")) and isBlue(v.BackgroundColor3) then
                v.BackgroundColor3 = purple
            end
            if v:IsA("ImageLabel") and isBlue(v.ImageColor3) then
                v.ImageColor3 = purple
            end
            if v:IsA("UIStroke") and isBlue(v.Color) then
                v.Color = purple
            end
            if v:IsA("Frame") and v:FindFirstChildWhichIsA("UIStroke") then
                for _,s in ipairs(v:GetChildren()) do
                    if s:IsA("UIStroke") and isBlue(s.Color) then
                        s.Color = purple
                    end
                end
            end
        end
    end
    -- Hook TweenService to prevent blue flash during Toggle animation
    pcall(function()
        local TS = game:GetService("TweenService")
        local oldCreate = TS.Create
        if hookfunction then
            hookfunction(TS.Create, function(self, inst, info, props)
                if props then
                    if props.BackgroundColor3 and isBlue(props.BackgroundColor3) then
                        props.BackgroundColor3 = purple
                    end
                    if props.ImageColor3 and isBlue(props.ImageColor3) then
                        props.ImageColor3 = purple
                    end
                    if props.Color and isBlue(props.Color) then
                        props.Color = purple
                    end
                end
                return oldCreate(self, inst, info, props)
            end)
        end
    end)
    recolor()
    game.CoreGui.DescendantAdded:Connect(function(v)
        task.wait()
        if (v:IsA("Frame") or v:IsA("TextButton")) and isBlue(v.BackgroundColor3) then
            v.BackgroundColor3 = purple
        end
        if v:IsA("UIStroke") and isBlue(v.Color) then
            v.Color = purple
        end
    end)
    RunService.Heartbeat:Connect(function()
        if Fluent.Unloaded then return end
        recolor()
    end)
end)
SaveManager:LoadAutoloadConfig()
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if Config.Enabled then setNoclip(true) startFarm() end
    if Config.PlaceEnabled then startPlace() end
    if Config.HatchEnabled then startHatch() end
    if Config.BuyEnabled then startBuy() end
    if Config.FeedEnabled then startFeed() end
    if Config.RebirthEnabled then startRebirth() end
end)
