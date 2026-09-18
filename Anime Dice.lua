--!nonstrict
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "VoltScripz | Anime Dice",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

do
    local purple = Color3.fromRGB(110, 45, 190)
    local blue1 = Color3.fromRGB(96, 205, 255)
    local blue2 = Color3.fromRGB(72, 138, 182)
    local function isBlue(c)
        return (c.R==blue1.R and c.G==blue1.G and c.B==blue1.B) or (c.R==blue2.R and c.G==blue2.G and c.B==blue2.B)
    end
    task.spawn(function()
        while not Fluent.Unloaded do
            pcall(function()
                local gui = Fluent.GUI
                if gui then
                    for _, v in ipairs(gui:GetDescendants()) do
                        local tag = v:GetAttribute("ThemeTag")
                        if tag=="Accent" then
                            pcall(function()
                                if v:IsA("Frame") then v.BackgroundColor3 = purple end
                                if v:IsA("ImageLabel") then v.ImageColor3 = purple end
                                if v:IsA("UIStroke") then v.Color = purple end
                                if v:IsA("TextLabel") then v.TextColor3 = purple end
                            end)
                        end
                        if v:IsA("Frame") and tag=="Accent" then
                            if v.BackgroundColor3 and isBlue(v.BackgroundColor3) then v.BackgroundColor3 = purple end
                        end
                    end
                end
            end)
            task.wait(0.3)
        end
    end)
    pcall(function()
        local gc = getgc and getgc(true) or {}
        for _, tbl in ipairs(gc) do
            if type(tbl)=="table" then
                if rawget(tbl, "Accent") then
                    if tbl.Accent==blue1 or tbl.Accent==blue2 then
                        tbl.Accent = purple
                    end
                end
            end
        end
    end)
end

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "dices" }),
    Unit = Window:AddTab({ Title = "Unit", Icon = "users" }),
    Tower = Window:AddTab({ Title = "Tower", Icon = "swords" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "settings-2" }),
    Setting = Window:AddTab({ Title = "Setting", Icon = "settings" })
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RollDice = ReplicatedStorage.Network.RollService.RF.RollDice
local CollectBalance = ReplicatedStorage.Network.PlotService.RE.CollectBalance
local SellInventory = ReplicatedStorage.Network.SellService.RF.SellInventory
local BuyDice = ReplicatedStorage.Network.DiceShopService.RE.BuyDice
local RebirthRE = ReplicatedStorage.Network.RebirthService.RE.Rebirth
local BuyUpgrade = ReplicatedStorage.Network.RE.BuyUpgrade
local EquipBest = ReplicatedStorage.Network.PlotService.RE.EquipBest
local ClaimQuest = ReplicatedStorage.Network.QuestService.RE.Claim
local LevelUpSlot = ReplicatedStorage.Network.PlotService.RE.LevelUpSlot
local TraitRoll = ReplicatedStorage.Network.TraitService.RE.Roll
local GradeRoll = ReplicatedStorage.Network.GradeService.RE.Roll
local UnitConfig = require(ReplicatedStorage.Framework.Features.Inventory.Kinds.Unit.UnitConfig)
local Dice = require(ReplicatedStorage.Framework.Features.Rolling.Dice)
local Rebirths = require(ReplicatedStorage.Framework.Features.Rebirth.Rebirths)
local Upgrades = require(ReplicatedStorage.Framework.Features.Upgrades.Upgrades)
local TreeStructure = require(ReplicatedStorage.Framework.Features.Upgrades.TreeStructure)
local QuestConfig = require(ReplicatedStorage.Framework.Features.Quests.QuestConfig)
local Towers = require(ReplicatedStorage.Framework.Features.Towers.Towers)

local autoRoll = false
local rollLoop = nil
local autoCollect = false
local collectLoop = nil
local collectInterval = 1
local autoSell = false
local sellLoop = nil
local sellThreshold = 250
local autoBuy = false
local buyLoop = nil
local autoRebirth = false
local rebirthLoop = nil
local autoUpgrade = false
local upgradeLoop = nil
local autoEquipBest = false
local equipBestLoop = nil
local autoClaimQuest = false
local claimQuestLoop = nil
local autoUpLevel = false
local upLevelLoop = nil
local upLevelTarget = "All"
local upLevelDropdown = nil
local autoTraits = false
local traitsLoop = nil
local traitUnitTarget = nil
local traitDesired = "Monarch"
local traitUnitDropdown = nil
local traitDesiredDropdown = nil
local traitUnitMap = {}
local autoGrade = false
local gradeLoop = nil
local gradeUnitTarget = nil
local gradeDesired = "Z"
local gradeUnitDropdown = nil
local gradeDesiredDropdown = nil
local gradeUnitMap = {}
local autoTower = false
local towerLoop = nil
local selectedTower = "Dragon Tower"
local towerDropdown = nil
local towerOldOpen = nil
local towerMenuController = nil

local function stopRollLoop()
    if rollLoop then
        pcall(task.cancel, rollLoop)
        rollLoop = nil
    end
end

local function startRollLoop()
    stopRollLoop()
    rollLoop = task.spawn(function()
        while autoRoll and not Fluent.Unloaded do
            local ok = pcall(function()
                RollDice:InvokeServer()
            end)
            if not ok then
                task.wait(1)
            else
                task.wait(2.7)
            end
        end
    end)
end

local function enableRoll()
    if autoRoll then return end
    autoRoll = true
    startRollLoop()
end

local function disableRoll()
    if not autoRoll then return end
    autoRoll = false
    stopRollLoop()
end

local function stopCollectLoop()
    if collectLoop then
        pcall(task.cancel, collectLoop)
        collectLoop = nil
    end
end

local function startCollectLoop()
    stopCollectLoop()
    collectLoop = task.spawn(function()
        while autoCollect and not Fluent.Unloaded do
            for i = 1, 14 do
                pcall(function()
                    CollectBalance:FireServer(i)
                end)
            end
            task.wait(collectInterval)
        end
    end)
end

local function enableCollect()
    if autoCollect then return end
    autoCollect = true
    startCollectLoop()
end

local function disableCollect()
    if not autoCollect then return end
    autoCollect = false
    stopCollectLoop()
end

local function stopSellLoop()
    if sellLoop then
        pcall(task.cancel, sellLoop)
        sellLoop = nil
    end
end

local function startSellLoop()
    stopSellLoop()
    sellLoop = task.spawn(function()
        while autoSell and not Fluent.Unloaded do
            local ok, root = pcall(function()
                return (filtergc :: any)("table", {Keys={"Money","Rolls"}}, true).Money.___X
            end)
            if ok and root and root.Inventory then
                local ids = {}
                local equipped = {}
                for _, slot in pairs(root.Slots) do
                    if slot.unitId then equipped[slot.unitId] = true end
                end
                for id, entry in pairs(root.Inventory) do
                    if not entry.attributes.locked and not equipped[id] then
                        local cfg = UnitConfig.entries[entry.name]
                        if cfg then
                            local s, chance = pcall(function() return cfg:chance() end)
                            if s and type(chance) == "number" and chance <= sellThreshold then
                                table.insert(ids, id)
                            end
                        end
                    end
                end
                if #ids > 0 then
                    pcall(function()
                        SellInventory:InvokeServer(ids)
                    end)
                end
            end
            task.wait(2)
        end
    end)
end

local function enableSell()
    if autoSell then return end
    autoSell = true
    startSellLoop()
end

local function disableSell()
    if not autoSell then return end
    autoSell = false
    stopSellLoop()
end

local function stopBuyLoop()
    if buyLoop then
        pcall(task.cancel, buyLoop)
        buyLoop = nil
    end
end

local function startBuyLoop()
    stopBuyLoop()
    buyLoop = task.spawn(function()
        while autoBuy and not Fluent.Unloaded do
            local ok, root = pcall(function()
                return (filtergc :: any)("table", {Keys={"Money","Rolls"}}, true).Money.___X
            end)
            if ok and root then
                local all = Dice:GetAll()
                local sorted = {}
                for name, info in pairs(all) do
                    if info.price then
                        table.insert(sorted, {name=name, price=info.price})
                    end
                end
                table.sort(sorted, function(a,b) return a.price < b.price end)
                for _, d in ipairs(sorted) do
                    if not root.OwnedDice[d.name] and root.Money >= d.price then
                        pcall(function()
                            BuyDice:FireServer(d.name)
                        end)
                        task.wait(0.5)
                        break
                    end
                end
            end
            task.wait(1)
        end
    end)
end

local function enableBuy()
    if autoBuy then return end
    autoBuy = true
    startBuyLoop()
end

local function disableBuy()
    if not autoBuy then return end
    autoBuy = false
    stopBuyLoop()
end

local function stopRebirthLoop()
    if rebirthLoop then
        pcall(task.cancel, rebirthLoop)
        rebirthLoop = nil
    end
end

local function startRebirthLoop()
    stopRebirthLoop()
    rebirthLoop = task.spawn(function()
        while autoRebirth and not Fluent.Unloaded do
            local ok, root = pcall(function()
                return (filtergc :: any)("table", {Keys={"Money","Rolls"}}, true).Money.___X
            end)
            if ok and root then
                local nextRebirth = root.Rebirth + 1
                local cfg = Rebirths.Get(nextRebirth)
                if cfg and root.Money >= cfg.cost then
                    pcall(function()
                        RebirthRE:FireServer()
                    end)
                end
            end
            task.wait(1)
        end
    end)
end

local function enableRebirth()
    if autoRebirth then return end
    autoRebirth = true
    startRebirthLoop()
end

local function disableRebirth()
    if not autoRebirth then return end
    autoRebirth = false
    stopRebirthLoop()
end

local function stopUpgradeLoop()
    if upgradeLoop then
        pcall(task.cancel, upgradeLoop)
        upgradeLoop = nil
    end
end

local function startUpgradeLoop()
    stopUpgradeLoop()
    upgradeLoop = task.spawn(function()
        while autoUpgrade and not Fluent.Unloaded do
            local ok, root = pcall(function()
                return (filtergc :: any)("table", {Keys={"Money","Rolls"}}, true).Money.___X
            end)
            if ok and root then
                local candidates = {}
                for name, cfg in pairs(Upgrades) do
                    if not root.Upgrades[name] and cfg.price and root.Money >= cfg.price then
                        local parent = TreeStructure.GetParent(name)
                        if not parent or parent == "Start" or root.Upgrades[parent] then
                            table.insert(candidates, {name=name, price=cfg.price})
                        end
                    end
                end
                table.sort(candidates, function(a,b) return a.price < b.price end)
                if #candidates > 0 then
                    pcall(function()
                        BuyUpgrade:FireServer(candidates[1].name)
                    end)
                end
            end
            task.wait(1)
        end
    end)
end

local function enableUpgrade()
    if autoUpgrade then return end
    autoUpgrade = true
    startUpgradeLoop()
end

local function disableUpgrade()
    if not autoUpgrade then return end
    autoUpgrade = false
    stopUpgradeLoop()
end

local function stopEquipBestLoop()
    if equipBestLoop then
        pcall(task.cancel, equipBestLoop)
        equipBestLoop = nil
    end
end

local function startEquipBestLoop()
    stopEquipBestLoop()
    equipBestLoop = task.spawn(function()
        while autoEquipBest and not Fluent.Unloaded do
            pcall(function()
                EquipBest:FireServer()
            end)
            task.wait(3)
        end
    end)
end

local function enableEquipBest()
    if autoEquipBest then return end
    autoEquipBest = true
    startEquipBestLoop()
end

local function disableEquipBest()
    if not autoEquipBest then return end
    autoEquipBest = false
    stopEquipBestLoop()
end

local function stopClaimQuestLoop()
    if claimQuestLoop then
        pcall(task.cancel, claimQuestLoop)
        claimQuestLoop = nil
    end
end

local function startClaimQuestLoop()
    stopClaimQuestLoop()
    claimQuestLoop = task.spawn(function()
        while autoClaimQuest and not Fluent.Unloaded do
            local ok, root = pcall(function()
                return (filtergc :: any)("table", {Keys={"Money","Rolls"}}, true).Money.___X
            end)
            if ok and root and root.Quests then
                for period, pdata in pairs(QuestConfig.Periods) do
                    local qRoot = root.Quests[period]
                    if qRoot then
                        for _, q in ipairs(pdata.quests) do
                            local prog = qRoot.progress[q.id] or 0
                            local claimed = qRoot.claimed[q.id]
                            if not claimed and prog >= q.target then
                                pcall(function() ClaimQuest:FireServer(q.id) end)
                                pcall(function() ClaimQuest:FireServer(period, q.id) end)
                            end
                        end
                    end
                end
            end
            task.wait(5)
        end
    end)
end

local function enableClaimQuest()
    if autoClaimQuest then return end
    autoClaimQuest = true
    startClaimQuestLoop()
end

local function disableClaimQuest()
    if not autoClaimQuest then return end
    autoClaimQuest = false
    stopClaimQuestLoop()
end

local function stopUpLevelLoop()
    if upLevelLoop then
        pcall(task.cancel, upLevelLoop)
        upLevelLoop = nil
    end
end

local function getUpLevelValues()
    local vals = {"All"}
    local ok, root = pcall(function()
        return (filtergc :: any)("table", {Keys={"Money","Rolls"}}, true).Money.___X
    end)
    if ok and root and root.Slots then
        for slotId, slot in pairs(root.Slots) do
            local ent = root.Inventory[slot.unitId]
            if ent then
                table.insert(vals, string.format("%s: %s", tostring(slotId), ent.name))
            end
        end
        table.sort(vals, function(a,b)
            if a=="All" then return true end
            if b=="All" then return false end
            return a<b
        end)
    end
    if #vals==1 then
        for i=1,5 do table.insert(vals, tostring(i)..": Empty") end
    end
    return vals
end

local function startUpLevelLoop()
    stopUpLevelLoop()
    upLevelLoop = task.spawn(function()
        while autoUpLevel and not Fluent.Unloaded do
            if upLevelTarget == "All" then
                for slotId = 1, 14 do
                    pcall(function()
                        LevelUpSlot:FireServer(slotId)
                    end)
                    task.wait(0.2)
                end
                task.wait(0.3)
            else
                local sid = tonumber(upLevelTarget:match("^(%d+):"))
                if sid then
                    pcall(function()
                        LevelUpSlot:FireServer(sid)
                    end)
                end
                task.wait(0.6)
            end
        end
    end)
end

local function enableUpLevel()
    if autoUpLevel then return end
    autoUpLevel = true
    startUpLevelLoop()
end

local function disableUpLevel()
    if not autoUpLevel then return end
    autoUpLevel = false
    stopUpLevelLoop()
end

local function getTraitUnitValues()
    local vals = {}
    traitUnitMap = {}
    local ok, root = pcall(function()
        return (filtergc :: any)("table", {Keys={"Money","Rolls"}}, true).Money.___X
    end)
    if ok and root and root.Inventory then
        for id, entry in pairs(root.Inventory) do
            if entry.attributes and entry.attributes.level then
                local trait = entry.attributes.trait or "No Trait"
                local display = string.format("%s: %s (%s)", id:sub(1,6), entry.name, trait)
                table.insert(vals, display)
                traitUnitMap[display] = id
            end
        end
        table.sort(vals)
    end
    if #vals==0 then vals={"No Units"} end
    return vals
end

local function stopTraitsLoop()
    if traitsLoop then
        pcall(task.cancel, traitsLoop)
        traitsLoop = nil
    end
end

local function startTraitsLoop()
    stopTraitsLoop()
    traitsLoop = task.spawn(function()
        while autoTraits and not Fluent.Unloaded do
            local ok, root = pcall(function()
                return (filtergc :: any)("table", {Keys={"Money","Rolls"}}, true).Money.___X
            end)
            if ok and root and traitUnitTarget and traitDesired then
                local unitId = traitUnitMap[traitUnitTarget]
                if not unitId then
                    local short = traitUnitTarget:match("^(%x+):") or traitUnitTarget:sub(1,6)
                    if short then
                        for id in pairs(root.Inventory) do
                            if id:sub(1,6)==short then unitId=id break end
                        end
                    end
                end
                if unitId then
                    local entry = root.Inventory[unitId]
                    local curTrait = entry and entry.attributes.trait or nil
                    local rerolls = 0
                    for _, e in pairs(root.Inventory) do if e.name=="Trait Reroll" then rerolls=e.amount break end end
                    if rerolls>0 and curTrait ~= traitDesired then
                        pcall(function() TraitRoll:FireServer(unitId) end)
                    elseif curTrait == traitDesired then
                        autoTraits=false
                        stopTraitsLoop()
                        break
                    elseif rerolls<=0 then
                        autoTraits=false
                        stopTraitsLoop()
                        break
                    end
                else
                    autoTraits=false
                    stopTraitsLoop()
                    break
                end
            end
            task.wait(0.6)
        end
    end)
end

local function enableTraits()
    if autoTraits then return end
    if not traitUnitTarget or traitUnitTarget=="No Units" then
        return
    end
    autoTraits=true
    startTraitsLoop()
end

local function disableTraits()
    if not autoTraits then return end
    autoTraits=false
    stopTraitsLoop()
end

local function getGradeUnitValues()
    local vals = {}
    gradeUnitMap = {}
    local ok, root = pcall(function()
        return (filtergc :: any)("table", {Keys={"Money","Rolls"}}, true).Money.___X
    end)
    if ok and root and root.Inventory then
        for id, entry in pairs(root.Inventory) do
            if entry.attributes and entry.attributes.level then
                local grade = entry.attributes.grade or "No Grade"
                local display = string.format("%s: %s (%s)", id:sub(1,6), entry.name, grade)
                table.insert(vals, display)
                gradeUnitMap[display] = id
            end
        end
        table.sort(vals)
    end
    if #vals==0 then vals={"No Units"} end
    return vals
end

local function stopGradeLoop()
    if gradeLoop then
        pcall(task.cancel, gradeLoop)
        gradeLoop=nil
    end
end

local function startGradeLoop()
    stopGradeLoop()
    gradeLoop = task.spawn(function()
        while autoGrade and not Fluent.Unloaded do
            local ok, root = pcall(function()
                return (filtergc :: any)("table", {Keys={"Money","Rolls"}}, true).Money.___X
            end)
            if ok and root and gradeUnitTarget and gradeDesired then
                local unitId = gradeUnitMap[gradeUnitTarget]
                if not unitId then
                    local short = gradeUnitTarget:match("^(%x+):") or gradeUnitTarget:sub(1,6)
                    if short then
                        for id in pairs(root.Inventory) do
                            if id:sub(1,6)==short then unitId=id break end
                        end
                    end
                end
                if unitId then
                    local entry = root.Inventory[unitId]
                    local curGrade = entry and entry.attributes.grade or nil
                    if curGrade == gradeDesired or (curGrade == nil and gradeDesired == "D") then
                        autoGrade=false
                        stopGradeLoop()
                        break
                    else
                        local gems = 0
                        for _, e in pairs(root.Inventory) do
                            if e.name == "Gems" then gems = e.amount or 0 break end
                        end
                        if gems < 1 then
                            autoGrade=false
                            stopGradeLoop()
                            break
                        end
                        pcall(function() GradeRoll:FireServer(unitId, true) end)
                    end
                else
                    autoGrade=false
                    stopGradeLoop()
                    break
                end
            end
            task.wait(0.3)
        end
    end)
end

local function enableGrade()
    if autoGrade then return end
    if not gradeUnitTarget or gradeUnitTarget=="No Units" then
        return
    end
    autoGrade=true
    startGradeLoop()
end

local function disableGrade()
    if not autoGrade then return end
    autoGrade=false
    stopGradeLoop()
end

local function getTowerValues()
    local vals = {}
    local ok, all = pcall(function() return Towers:GetAll() end)
    if ok and all then
        for name, data in pairs(all) do
            table.insert(vals, {name=name, order=data.order or 99})
        end
        table.sort(vals, function(a,b) return a.order < b.order end)
        for i,v in ipairs(vals) do vals[i]=v.name end
    else
        vals={"Dragon Tower","Cursed Tower","Pirate Tower","Hidden Leaf Tower","Infinity Tower"}
    end
    return vals
end

local function stopTowerLoop()
    if towerLoop then pcall(task.cancel, towerLoop) towerLoop=nil end
end

local function startTowerLoop()
    stopTowerLoop()
    towerLoop = task.spawn(function()
        local Network = require(ReplicatedStorage.Packages.Network)
        local TowerController = require(ReplicatedStorage.Framework.Features.Towers.TowerController)
        local MenuController, UIReferences
        pcall(function() MenuController = require(ReplicatedStorage.Framework.Features.UI.MenuController) end)
        pcall(function() UIReferences = require(ReplicatedStorage.Framework.Features.UI.UIReferences) end)
        if MenuController and UIReferences and UIReferences.Menus then
            local block = {}
            if UIReferences.Menus.Towers then block[UIReferences.Menus.Towers]=true end
            if UIReferences.Menus.PlayTower then block[UIReferences.Menus.PlayTower]=true end
            towerMenuController = MenuController
            towerOldOpen = MenuController.OpenMenu
            MenuController.OpenMenu = function(menu, ...)
                if block[menu] then return end
                return towerOldOpen(menu, ...)
            end
        end
        local comm = Network.ClientComm.new(ReplicatedStorage.Network, false, "Towers")
        local EquipBestSig = comm:GetSignal("EquipBestTowerTeam")
        local towerScreen
        pcall(function() towerScreen = UIReferences.Root.Tower.Screen end)
        while autoTower and not Fluent.Unloaded do
            pcall(function() EquipBestSig:Fire() end)
            task.wait(0.5)
            local curTower = selectedTower
            if towerDropdown and towerDropdown.Value then
                curTower = towerDropdown.Value
            elseif Fluent.Options and Fluent.Options.TowerSelect then
                local v = Fluent.Options.TowerSelect.Value
                if type(v)=="string" and v~="" then curTower = v end
            end
            local ok, started = pcall(function() return TowerController.startTower(curTower) end)
            if not ok or not started then
                task.wait(3)
                continue
            end
            task.wait(1)
            while autoTower and not Fluent.Unloaded do
                if towerScreen then
                    if towerScreen.Visible then
                        task.wait(1)
                        continue
                    else
                        break
                    end
                else
                    task.wait(3)
                    break
                end
            end
            task.wait(1)
        end
        if towerOldOpen and towerMenuController then
            towerMenuController.OpenMenu = towerOldOpen
            towerOldOpen = nil
            towerMenuController = nil
        end
    end)
end

local function enableTower()
    if autoTower then return end
    autoTower=true
    startTowerLoop()
end

local function disableTower()
    if not autoTower then return end
    autoTower=false
    stopTowerLoop()
    if towerOldOpen and towerMenuController then
        pcall(function() towerMenuController.OpenMenu = towerOldOpen end)
        towerOldOpen = nil
        towerMenuController = nil
    end
    pcall(function()
        local Network = require(ReplicatedStorage.Packages.Network)
        local comm = Network.ClientComm.new(ReplicatedStorage.Network, false, "Towers")
        local CancelFn = comm:GetFunction("CancelTower")
        CancelFn:InvokeServer()
    end)
end

local MainFarmSection = Tabs.Main:AddSection("Main Farm")

MainFarmSection:AddToggle("AutoRoll", {
    Title = "Auto Roll",
    Default = false,
    Callback = function(state)
        if state then
            enableRoll()
        else
            disableRoll()
        end
    end
})

MainFarmSection:AddToggle("AutoCollect", {
    Title = "Auto Collect Money",
    Default = false,
    Callback = function(state)
        if state then
            enableCollect()
        else
            disableCollect()
        end
    end
})

MainFarmSection:AddInput("CollectInterval", {
    Title = "Collect Interval",
    Default = "1",
    Placeholder = "1",
    Numeric = true,
    Finished = false,
    Callback = function(v)
        local n = tonumber(v)
        if n and n >= 0.5 and n <= 30 then
            collectInterval = n
        end
    end
})

MainFarmSection:AddToggle("AutoSell", {
    Title = "Auto Sell",
    Default = false,
    Callback = function(state)
        if state then
            enableSell()
        else
            disableSell()
        end
    end
})

MainFarmSection:AddInput("Rarity", {
    Title = "Rarity",
    Default = "",
    Placeholder = "",
    Numeric = true,
    Finished = false,
    Callback = function(v)
        local n = tonumber(v)
        if n and n >= 1 and n <= 1000000000000000 then
            sellThreshold = n
            if autoSell then
            end
        end
    end
})

local ProgressionSection = Tabs.Main:AddSection("Progression")

ProgressionSection:AddToggle("AutoBuyDice", {
    Title = "Auto Buy Dice",
    Default = false,
    Callback = function(state)
        if state then
            enableBuy()
        else
            disableBuy()
        end
    end
})

ProgressionSection:AddToggle("AutoRebirth", {
    Title = "Auto Rebirth",
    Default = false,
    Callback = function(state)
        if state then
            enableRebirth()
        else
            disableRebirth()
        end
    end
})

ProgressionSection:AddToggle("AutoUpgrade", {
    Title = "Auto Upgrade",
    Default = false,
    Callback = function(state)
        if state then
            enableUpgrade()
        else
            disableUpgrade()
        end
    end
})

ProgressionSection:AddToggle("AutoEquipBest", {
    Title = "Auto Equip Best",
    Default = false,
    Callback = function(state)
        if state then
            enableEquipBest()
        else
            disableEquipBest()
        end
    end
})

ProgressionSection:AddToggle("AutoClaimQuest", {
    Title = "Auto Claim Quest",
    Default = false,
    Callback = function(state)
        if state then
            enableClaimQuest()
        else
            disableClaimQuest()
        end
    end
})

local UnitSection = Tabs.Unit:AddSection("Unit")

UnitSection:AddToggle("AutoUpLevel", {
    Title = "Auto Up Level",
    Default = false,
    Callback = function(state)
        if state then
            enableUpLevel()
        else
            disableUpLevel()
        end
    end
})

upLevelDropdown = UnitSection:AddDropdown("UpLevelTarget", {
    Title = "Up Level Target",
    Values = getUpLevelValues(),
    Multi = false,
    Default = 1,
})

upLevelDropdown:OnChanged(function(v)
    upLevelTarget = v
end)

UnitSection:AddButton({
    Title = "Reset Unit",
    Callback = function()
        local vals = getUpLevelValues()
        if upLevelDropdown.SetValues then
            pcall(function() upLevelDropdown:SetValues(vals) end)
        end
        local cur = vals[1]
        for _,v in ipairs(vals) do if v==upLevelTarget then cur=v break end end
        pcall(function() upLevelDropdown:SetValue(cur) end)
    end
})

local TraitSection = Tabs.Unit:AddSection("Trait")

TraitSection:AddToggle("AutoTraits", {
    Title = "Auto Traits",
    Default = false,
    Callback = function(state)
        if state then
            enableTraits()
        else
            disableTraits()
        end
    end
})

traitDesiredDropdown = TraitSection:AddDropdown("DesiredTrait", {
    Title = "Desired Trait",
    Values = {"Monarch","Eternal","Transcendent","Shogun","Samurai","Money III","Damage III","Health III","Money I","Damage I","Health I"},
    Multi = false,
    Default = 1,
})

traitDesiredDropdown:OnChanged(function(v)
    traitDesired = v
end)

traitUnitDropdown = TraitSection:AddDropdown("TraitUnit", {
    Title = "Trait Unit",
    Values = getTraitUnitValues(),
    Multi = false,
    Default = 1,
})

traitUnitDropdown:OnChanged(function(v)
    traitUnitTarget = v
end)

do
    local vals = getTraitUnitValues()
    if vals[1] then traitUnitTarget = vals[1] end
end

TraitSection:AddButton({
    Title = "Reset Unit",
    Callback = function()
        local vals = getTraitUnitValues()
        if traitUnitDropdown.SetValues then
            pcall(function() traitUnitDropdown:SetValues(vals) end)
        end
        local cur = vals[1]
        for _,v in ipairs(vals) do if v==traitUnitTarget then cur=v break end end
        pcall(function() traitUnitDropdown:SetValue(cur) end)
        traitUnitTarget = cur
    end
})

local GradeSection = Tabs.Unit:AddSection("Grade")

GradeSection:AddToggle("AutoGrade", {
    Title = "Auto Grade",
    Default = false,
    Callback = function(state)
        if state then
            enableGrade()
        else
            disableGrade()
        end
    end
})

gradeDesiredDropdown = GradeSection:AddDropdown("GradeDesired", {
    Title = "Grade",
    Values = {"D","C","B","A","A+","S","S+","Z","Z+","\234\165\158"},
    Multi = false,
    Default = 8,
})

gradeDesiredDropdown:OnChanged(function(v)
    gradeDesired = v
end)

gradeUnitDropdown = GradeSection:AddDropdown("GradeUnit", {
    Title = "Grade Unit",
    Values = getGradeUnitValues(),
    Multi = false,
    Default = 1,
})

gradeUnitDropdown:OnChanged(function(v)
    gradeUnitTarget = v
end)

do
    local vals = getGradeUnitValues()
    if vals[1] then gradeUnitTarget = vals[1] end
end

GradeSection:AddButton({
    Title = "Reset Unit",
    Callback = function()
        local vals = getGradeUnitValues()
        if gradeUnitDropdown.SetValues then
            pcall(function() gradeUnitDropdown:SetValues(vals) end)
        end
        local cur = vals[1]
        for _,v in ipairs(vals) do if v==gradeUnitTarget then cur=v break end end
        pcall(function() gradeUnitDropdown:SetValue(cur) end)
        gradeUnitTarget = cur
    end
})

local TowerSection = Tabs.Tower:AddSection("Tower")

TowerSection:AddToggle("AutoTower", {
    Title = "Auto Tower",
    Default = false,
    Callback = function(state)
        if state then enableTower() else disableTower() end
    end
})

towerDropdown = TowerSection:AddDropdown("TowerSelect", {
    Title = "Tower",
    Values = getTowerValues(),
    Multi = false,
    Default = 1,
})

towerDropdown:OnChanged(function(v) selectedTower = v end)

do
    local vals = getTowerValues()
    if vals[1] then selectedTower = vals[1] end
end

local MiscSection = Tabs.Misc:AddSection("Misc")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local enableWalkSpeed = false
local speedValue = 16
local enableJumpPower = false
local powerValue = 50

local function getHumanoid()
    local char = LocalPlayer.Character
    if char then return char:FindFirstChildOfClass("Humanoid") end
    return nil
end

local function applyWalkSpeed(v)
    speedValue = v
    if not enableWalkSpeed then return end
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = v end
end

local function applyJumpPower(v)
    powerValue = v
    if not enableJumpPower then return end
    local hum = getHumanoid()
    if hum then
        if hum.UseJumpPower then
            hum.JumpPower = v
        else
            hum.JumpHeight = v / 2
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.wait(0.2)
    if enableWalkSpeed then applyWalkSpeed(speedValue) end
    if enableJumpPower then applyJumpPower(powerValue) end
end)

MiscSection:AddToggle("WalkSpeedToggle", {
    Title = "WalkSpeed",
    Default = false,
    Callback = function(state)
        enableWalkSpeed = state
        local hum = getHumanoid()
        if hum then
            if state then
                hum.WalkSpeed = speedValue
            else
                hum.WalkSpeed = 16
            end
        end
    end
})

MiscSection:AddSlider("Speed", {
    Title = "Speed",
    Default = 16,
    Min = 1,
    Max = 200,
    Rounding = 0,
    Callback = function(v) applyWalkSpeed(v) end
})

MiscSection:AddToggle("JumpPowerToggle", {
    Title = "JumpPower",
    Default = false,
    Callback = function(state)
        enableJumpPower = state
        local hum = getHumanoid()
        if hum then
            if state then
                if hum.UseJumpPower then hum.JumpPower = powerValue else hum.JumpHeight = powerValue/2 end
            else
                if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
            end
        end
    end
})

MiscSection:AddSlider("Power", {
    Title = "Power",
    Default = 50,
    Min = 1,
    Max = 200,
    Rounding = 0,
    Callback = function(v) applyJumpPower(v) end
})

local BootsSection = Tabs.Misc:AddSection("Boots")

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local bootsBlackGui = nil

local function setBootsFps(state)
    if state then
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        pcall(function() Lighting.GlobalShadows = false end)
        pcall(function() Lighting.FogEnd = 9e9 end)
    else
        pcall(function() Lighting.GlobalShadows = true end)
        pcall(function() Lighting.FogEnd = 1000 end)
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level07 end)
    end
end

local function setSaveCpuGpu(state)
    if state then
        pcall(function() RunService:Set3dRenderingEnabled(false) end)
        if not bootsBlackGui then
            local gui = Instance.new("ScreenGui")
            gui.Name = "BootsBlackBg"
            gui.ResetOnSpawn = false
            gui.IgnoreGuiInset = true
            gui.DisplayOrder = -1000
            pcall(function() gui.Parent = game:GetService("CoreGui") end)
            if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
            local frame = Instance.new("Frame")
            frame.Size = UDim2.fromScale(1,1)
            frame.Position = UDim2.fromScale(0,0)
            frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
            frame.BorderSizePixel = 0
            frame.Parent = gui
            bootsBlackGui = gui
        end
    else
        pcall(function() RunService:Set3dRenderingEnabled(true) end)
        if bootsBlackGui then
            pcall(function() bootsBlackGui:Destroy() end)
            bootsBlackGui = nil
        end
    end
end

BootsSection:AddToggle("BootsFps", {
    Title = "Boots Fps",
    Default = false,
    Callback = function(state) setBootsFps(state) end
})

BootsSection:AddToggle("SaveCpuGpu", {
    Title = "Save Cpu & Gpu",
    Default = false,
    Callback = function(state) setSaveCpuGpu(state) end
})

local AfkSection = Tabs.Misc:AddSection("AFK")

local antiAfkConn = nil
local antiAfkEnabled = false

local function setAntiAfk(state)
    antiAfkEnabled = state
    if state then
        if antiAfkConn then pcall(function() antiAfkConn:Disconnect() end) antiAfkConn=nil end
        antiAfkConn = LocalPlayer.Idled:Connect(function()
            pcall(function()
                local VU = game:GetService("VirtualUser")
                VU:CaptureController()
                VU:ClickButton2(Vector2.new())
            end)
        end)
    else
        if antiAfkConn then pcall(function() antiAfkConn:Disconnect() end) antiAfkConn=nil end
    end
end

AfkSection:AddToggle("AntiAfk", {
    Title = "Anti AFK",
    Default = true,
    Callback = function(state) setAntiAfk(state) end
})

setAntiAfk(true)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager.Settings.Theme = "Darker"
InterfaceManager.Settings.Acrylic = false
InterfaceManager.Settings.Transparency = false
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:BuildInterfaceSection(Tabs.Setting)
SaveManager:BuildConfigSection(Tabs.Setting)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

