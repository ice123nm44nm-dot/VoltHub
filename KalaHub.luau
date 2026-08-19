local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Wait for the game's core module to be ready before requiring it. Running too early
-- (before ReplicatedFirst.AllSideCode.UtilsSystem replicates) makes require throw
-- "Couldn't find the asset path", which is what other machines hit.
local function loadUtilsSystem()
    local rs = game:GetService("ReplicatedFirst")
    local allside = rs:FindFirstChild("AllSideCode")
    for _ = 1, 60 do
        if allside then
            local us = allside:FindFirstChild("UtilsSystem")
            if us then
                local ok, mod = pcall(require, us)
                if ok and type(mod) == "table" then
                    return mod
                end
            end
        end
        task.wait(0.5)
        allside = rs:FindFirstChild("AllSideCode")
    end
    error("KalaHub: could not load AllSideCode.UtilsSystem - wait for the game to finish loading and run again")
end

local UtilsSystem = loadUtilsSystem()
local NetWork = UtilsSystem.NetWork
local NetMsg = UtilsSystem.NetMsg
local LocalPlayer = UtilsSystem.LocalPlayer
local ItemType = UtilsSystem.EnumMgr.ItemType
local HumanModule = UtilsSystem.HumanModule
local EquipShop = UtilsSystem.EquipShop
local PlayerData = UtilsSystem.PlayerData
local CfgFind = UtilsSystem.CfgFind

local MAX_STAGE = 24

local cfg = {
    farm = false,
    maxStage = 24,
    speed = 60,
    attackInterval = 0.16,
    autoLoot = false,
    rarityFilter = {},
    minGold = 0,
    autoBuy = false,
    buyWeapon = true,
    buyArmor = true,
    autoSell = false,
    sellRarity = {},
    sellMinPrice = nil,
    autoRebirth = false,
    autoClaim = false,
}

local RARITY_NAMES = {
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Mythic",
    [7] = "Secret",
    [8] = "Ancient",
    [9] = "Supreme",
    [10] = "Stellar",
}

local Status = ""
local AutoDungeonToggle = nil
local AutoLootToggle = nil
local StatusParagraph = nil

local function notify(title, content)
    pcall(function()
        Fluent:Notify({ Title = title, Content = content, Duration = 3 })
    end)
end

local function setStatus(s)
    Status = s
    if StatusParagraph then
        pcall(function()
            StatusParagraph:SetDesc(s)
        end)
    end
end

local function getHrp()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getNum(name)
    local v = LocalPlayer:FindFirstChild(name)
    if v then
        local ok, val = pcall(function()
            return v.Value
        end)
        if ok then
            return val or 0
        end
    end
    return 0
end

local function getBagNum(name)
    local bag = LocalPlayer:FindFirstChild("Bag")
    if not bag then
        return 0
    end
    local v = bag:FindFirstChild(name)
    if v then
        local ok, val = pcall(function()
            return v.Value
        end)
        if ok then
            return val or 0
        end
    end
    return 0
end

local function getLimitBagUsed()
    return getNum("LimitBagUsed")
end

local function getLimitBagSize()
    return getBagNum("5")
end

local function isBagFull()
    local used = getLimitBagUsed()
    local size = getLimitBagSize()
    return size > 0 and used >= size
end

local function isInDungeon()
    return getNum("InDungeonChallenge") > 0
end

local function isStageJumping()
    if getNum("StageJumping") == 1 then
        return true
    end
    local char = LocalPlayer.Character
    if char and char:GetAttribute("StageJumpAnimating") then
        return true
    end
    return false
end

local function getNextStage()
    return math.floor(getNum("DungeonRunMaxClear")) + 1
end

local function getCurrentStage()
    return math.floor(getNum("DungeonAggroStage"))
end

local function fireDungeonSpawn(stage)
    local ok, err = pcall(function()
        NetWork.FireServer(NetMsg.DUNGEON_SPAWN_STAGE, stage)
    end)
    return ok and not err
end

local function returnToTown()
    pcall(function()
        NetWork.FireServer(NetMsg.DUNGEON_RETURN_TOWN)
    end)
end

local function canTap()
    if not HumanModule.IsPlrCharAlive(LocalPlayer) then
        return false
    end
    local pop = LocalPlayer:FindFirstChild("是否弹窗打开中")
    if pop and pop.Value then
        return false
    end
    if LocalPlayer:FindFirstChild("退出炼金短暂不允许施法") then
        return false
    end
    local cam = workspace.CurrentCamera
    if cam and cam.CameraType == Enum.CameraType.Scriptable then
        return false
    end
    return true
end

local function isHoldingWeapon()
    return getNum("当前手持类型") == ItemType.Weapon
end

local function tapAttack()
    if not canTap() then
        return
    end
    local ok, res = pcall(function()
        return NetWork.InvokeServer(NetMsg.TRAIN_MANUAL_CLICK, {})
    end)
    return ok and type(res) == "table" and res.ok == true
end

local function getBattleArea(stage)
    local scene = workspace:FindFirstChild("场景")
    if not scene then
        return nil
    end
    local st = scene:FindFirstChild(tostring(stage))
    if not st then
        return nil
    end
    return st:FindFirstChild("战斗区域", true)
end

local function getMonsterRoot(m)
    local pp = m.PrimaryPart
    if pp and pp:IsA("BasePart") then
        return pp
    end
    return m:FindFirstChild("HumanoidRootPart")
end

local function getStageMonsters(stage)
    local folder = workspace:FindFirstChild("LocalMonster")
    if not folder then
        return {}
    end
    local list = {}
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") then
            local s = tonumber(m:GetAttribute("Stage"))
            if s and s == stage then
                local hum = m:FindFirstChildOfClass("Humanoid")
                local root = getMonsterRoot(m)
                if hum and hum.Health > 0 and root then
                    table.insert(list, { model = m, hum = hum, root = root })
                end
            end
        end
    end
    return list
end

local function getDrops()
    local folder = workspace:FindFirstChild("DropsClient")
    local list = {}
    if not folder then
        return list
    end
    for _, rarity in ipairs(folder:GetChildren()) do
        for _, d in ipairs(rarity:GetChildren()) do
            if d:IsA("Model") then
                table.insert(list, {
                    model = d,
                    id = d.Name,
                    xyd = tonumber(d:GetAttribute("Xyd")) or 0,
                    gold = tonumber(d:GetAttribute("GoldValue")) or 0,
                    stage = tonumber(d:GetAttribute("Stage")) or 0,
                })
            end
        end
    end
    return list
end

local function collectDrops(force)
    if not force and not cfg.autoLoot then
        return 0
    end
    local curStage = getCurrentStage()
    local collected = 0
    local drops = getDrops()
    for _, d in ipairs(drops) do
        local passes = next(cfg.rarityFilter) == nil or cfg.rarityFilter[d.xyd] == true
        if passes and d.gold >= cfg.minGold and d.stage <= curStage and d.model.Parent then
            pcall(function()
                NetWork.FireServer(NetMsg.DROP_PICKUP, d.id)
            end)
            collected = collected + 1
            task.wait(0.25)
        end
    end
    return collected
end

local function enterDungeon(stage)
    local area = getBattleArea(stage)
    if not area then
        return false
    end
    local hrp = getHrp()
    if hrp then
        hrp.CFrame = CFrame.new(area.Position + Vector3.new(0, 5, 0)) * (hrp.CFrame - hrp.CFrame.Position)
    end
    fireDungeonSpawn(stage)
    task.wait(2)
    return isInDungeon()
end

local function lootLoop()
    while cfg.autoLoot do
        local n = collectDrops()
        if n > 0 then
            setStatus("เก็บ " .. n .. " ชิ้น (bag " .. getLimitBagUsed() .. "/" .. getLimitBagSize() .. ")")
        end
        task.wait(2)
    end
end

local function getCoin()
    local bag = PlayerData.GetPlrDataByKey(LocalPlayer, "Bag")
    if type(bag) ~= "table" then
        return 0
    end
    for _, v in pairs(bag) do
        if type(v) == "table" and tonumber(v.id) == UtilsSystem.EnumMgr.ItemID.Coin then
            return tonumber(v.count) or 0
        end
    end
    return 0
end

local BUY_SHOPS = {
    {
        itemType = ItemType.Weapon,
        saveKey = "Weapon",
        confName = "weaponConf",
        label = "อาวุธ",
    },
    {
        itemType = ItemType.Armor,
        saveKey = "Armor",
        confName = "armorConf",
        label = "เกราะ",
    },
}

local function findBestBuy(shop, coin)
    local best = nil
    local equippedId = EquipShop.GetEquippedCfgId(LocalPlayer, shop.saveKey)
    local equippedCfg = equippedId > 0 and EquipShop.FindShopCfg(equippedId, shop.itemType)
    for _, v in ipairs(EquipShop.BuildShopList(shop.confName)) do
        local c = v.cfg
        if EquipShop.IsCoinPurchasable(c) then
            local price = tonumber(c.Price) or 0
            if price > 0 and price <= coin and not EquipShop.OwnsInBag(LocalPlayer, v.id, shop.itemType) then
                if not equippedCfg or EquipShop.IsAttrEffectBetter(c, equippedCfg, LocalPlayer) then
                    if not best or EquipShop.IsAttrEffectBetter(c, best.cfg, LocalPlayer) then
                        best = v
                    end
                end
            end
        end
    end
    return best
end

local function buyEquipOnce()
    local coin = getCoin()
    local bought = 0
    for _, shop in ipairs(BUY_SHOPS) do
        if shop.itemType == ItemType.Weapon and not cfg.buyWeapon then
            continue
        end
        if shop.itemType == ItemType.Armor and not cfg.buyArmor then
            continue
        end
        local best = findBestBuy(shop, coin)
        if best then
            local ok, res = pcall(function()
                return NetWork.InvokeServer(NetMsg.EQUIP_SHOP_BUY, { equipID = best.id, itemType = shop.itemType })
            end)
            if ok and res == true then
                pcall(function()
                    NetWork.InvokeServer(NetMsg.EQUIP_SHOP_EQUIP, { equipID = best.id, itemType = shop.itemType })
                end)
                notify("Auto Buy", "ซื้อ " .. shop.label .. " แล้ว")
                setStatus("ซื้อ " .. shop.label .. " แล้ว")
                bought = bought + 1
                task.wait(1)
            end
        end
    end
    return bought
end

local function buyLoop()
    while cfg.autoBuy do
        if isInDungeon() then
            task.wait(3)
        else
            buyEquipOnce()
            task.wait(4)
        end
    end
end

local function isLocked(e)
    return e.lock == 1 or e.lock == true
end

local function sellMaterialsOnce()
    local bag = PlayerData.GetPlrDataByKey(LocalPlayer, "Bag")
    if type(bag) ~= "table" then
        return 0
    end
    local toSell = {}
    for _, v in pairs(bag) do
        if type(v) == "table" and tonumber(v.tp) == ItemType.Material and tonumber(v.count or 0) > 0 then
            if not isLocked(v) then
                local id = tonumber(v.id)
                local onlyID = tonumber(v.onlyID)
                if id and onlyID then
                    local mcfg = CfgFind.FindCfgByID(id, ItemType.Material)
                    if mcfg then
                        local xyd = tonumber(mcfg.xyd) or 0
                        local price = tonumber(mcfg.GoldValue) or 0
                        local passesRarity = next(cfg.sellRarity) == nil or cfg.sellRarity[xyd] ~= true
                        local passesPrice = cfg.sellMinPrice == nil or price <= cfg.sellMinPrice
                        if passesRarity and passesPrice then
                            table.insert(toSell, onlyID)
                        end
                    end
                end
            end
        end
    end
    if #toSell == 0 then
        return 0
    end
    local ok, res = pcall(function()
        return NetWork.InvokeServer(NetMsg.SELL_MATERIAL, { onlyIDList = toSell })
    end)
    if ok and res == true then
        return #toSell
    end
    return 0
end

local function sellLoop()
    while cfg.autoSell do
        local n = sellMaterialsOnce()
        if n > 0 then
            setStatus("ขายแล้ว " .. n .. " ชิ้น")
        end
        task.wait(5)
    end
end

local function getBagNumValue(id)
    local bag = PlayerData.GetPlrDataByKey(LocalPlayer, "Bag")
    if type(bag) ~= "table" then
        return 0
    end
    for _, v in pairs(bag) do
        if type(v) == "table" and tonumber(v.id) == id then
            return tonumber(v.count) or 0
        end
    end
    return 0
end

local function getLevel()
    return getBagNumValue(UtilsSystem.EnumMgr.ItemID.Level)
end

local function getRebirth()
    return getBagNumValue(UtilsSystem.EnumMgr.ItemID.Rebirth)
end

local function getNextRebirthNeed()
    local rb = math.floor(getRebirth())
    local cfg2 = UtilsSystem.ConfigInstance.rebirthConf and UtilsSystem.ConfigInstance.rebirthConf[rb + 1]
    if type(cfg2) ~= "table" then
        return nil
    end
    return tonumber(cfg2.LvNeed) or 0
end

local function canRebirth()
    local need = getNextRebirthNeed()
    if not need then
        return false
    end
    return math.floor(getLevel()) >= need
end

local function doRebirth()
    local ok, res = pcall(function()
        return NetWork.InvokeServer(NetMsg.PLAYER_REBIRTH)
    end)
    return ok and res == true
end

local function rebirthLoop()
    while cfg.autoRebirth do
        if canRebirth() then
            if doRebirth() then
                notify("Auto Rebirth", "Rebirth แล้ว")
                setStatus("Rebirth แล้ว")
            end
        end
        task.wait(5)
    end
end

local hoverPlatform = nil

local function ensureHoverPlatform()
    if hoverPlatform and hoverPlatform.Parent then
        return hoverPlatform
    end
    hoverPlatform = Instance.new("Part")
    hoverPlatform.Name = "KalaHoverPlatform"
    hoverPlatform.Size = Vector3.new(8, 1, 8)
    hoverPlatform.Transparency = 1
    hoverPlatform.Anchored = true
    hoverPlatform.CanCollide = true
    hoverPlatform.CanQuery = false
    hoverPlatform.CanTouch = false
    hoverPlatform.Material = Enum.Material.SmoothPlastic
    hoverPlatform.Parent = workspace
    return hoverPlatform
end

local function destroyHoverPlatform()
    if hoverPlatform then
        pcall(function()
            hoverPlatform:Destroy()
        end)
        hoverPlatform = nil
    end
end

local function hoverPoint(m)
    local root = getMonsterRoot(m.model or m)
    if not root then
        return nil
    end
    local top
    local ok, cf, size = pcall(function()
        return m:GetBoundingBox()
    end)
    if ok and typeof(cf) == "CFrame" and typeof(size) == "Vector3" then
        top = cf.Position.Y + size.Y * 0.5
    else
        top = root.Position.Y + 5
    end
    -- player stands on an invisible platform well above the monster's head
    return Vector3.new(root.Position.X, top + 8, root.Position.Z)
end

local function holdAbove(m)
    local h = getHrp()
    if not h then
        return
    end
    local hp = hoverPoint(m)
    if not hp then
        return
    end
    local plat = ensureHoverPlatform()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local standH = (hum and hum.HipHeight or 0) + 3
    plat.CFrame = CFrame.new(hp.X, hp.Y - standH, hp.Z)
    h.CFrame = CFrame.new(hp) * (h.CFrame - h.CFrame.Position)
end

local function tweenTo(target, speed)
    local hrp = getHrp()
    if not hrp then
        return false
    end
    local startPos = hrp.Position
    local startT = os.clock()
    local lastProg, lastCheck, lastProgT = 0, os.clock(), os.clock()
    while cfg.farm do
        local h = getHrp()
        if not h then
            return false
        end
        local cur = h.Position
        local dx, dz = target.X - cur.X, target.Z - cur.Z
        local xzd = math.sqrt(dx * dx + dz * dz)
        if xzd < 2 then
            h.CFrame = CFrame.new(target) * (h.CFrame - h.CFrame.Position)
            return true
        end
        if os.clock() - startT > 15 then
            h.CFrame = CFrame.new(target) * (h.CFrame - h.CFrame.Position)
            return true
        end
        local now = os.clock()
        local dt = now - lastCheck
        lastCheck = now
        local step = math.min(1, (speed * dt) / xzd)
        local newPos = Vector3.new(
            cur.X + dx * step,
            cur.Y + (target.Y - cur.Y) * step,
            cur.Z + dz * step
        )
        h.CFrame = CFrame.new(newPos) * (h.CFrame - h.CFrame.Position)
        local totalXZ = math.sqrt((target.X - startPos.X) ^ 2 + (target.Z - startPos.Z) ^ 2)
        local prog = totalXZ > 0 and (1 - xzd / totalXZ) or 1
        if now - lastProgT >= 0.05 then
            if prog - lastProg < 0.15 then
                h.CFrame = CFrame.new(target) * (h.CFrame - h.CFrame.Position)
                return true
            end
            lastProg = prog
            lastProgT = now
        end
        task.wait()
    end
    return false
end

local function stopFarm()
    cfg.farm = false
    destroyHoverPlatform()
    if AutoDungeonToggle then
        pcall(function()
            AutoDungeonToggle:SetValue(false)
        end)
    end
    setStatus("ปิด Auto Dungeon")
end

local function waitForRespawn(stage)
    local area = getBattleArea(stage)
    if not area then
        return
    end
    local safe = area.Parent:FindFirstChild("安全区域")
    local target
    if safe and safe:IsA("BasePart") then
        target = safe.Position
    else
        target = area.Position + Vector3.new(0, 2, area.Size.Z * 0.5 + 6)
    end
    setStatus("Stage " .. stage .. " รอ Respaw น")
    tweenTo(target + Vector3.new(0, 2, 0), cfg.speed)
    local deadline = os.clock() + 40
    while cfg.farm and os.clock() < deadline do
        collectDrops()
        if #getStageMonsters(stage) > 0 then
            return
        end
        task.wait(0.5)
    end
end

local function fightStage(stage)
    if not isHoldingWeapon() then
        setStatus("ต้องถืออาวุธก่อน")
        return false
    end
    local monsters = getStageMonsters(stage)
    if #monsters == 0 then
        return false
    end
    local hrp = getHrp()
    if not hrp then
        return false
    end
    local best, bestD = nil, math.huge
    for _, m in ipairs(monsters) do
        local d = (m.root.Position - hrp.Position).Magnitude
        if d < bestD then
            best, bestD = m, d
        end
    end
    if not best then
        return false
    end
    setStatus("Stage " .. stage)
    tweenTo(hoverPoint(best), cfg.speed)
    local lastTap = 0
    while cfg.farm do
        if isBagFull() then
            return true
        end
        if not best.hum or best.hum.Health <= 0 or not best.model.Parent then
            break
        end
        holdAbove(best)
        if isHoldingWeapon() and canTap() then
            local now = os.clock()
            if now - lastTap >= cfg.attackInterval then
                tapAttack()
                lastTap = now
            end
        else
            task.wait(0.2)
        end
        task.wait()
    end
    task.wait(0.3)
    collectDrops()
    return true
end

local function farmLoop()
    while cfg.farm do
        if isStageJumping() then
            task.wait(0.3)
        else
            local nextStage = getNextStage()
            if nextStage > MAX_STAGE then
                setStatus("ถึง Stage สูงสุดแล้ว")
                stopFarm()
            else
                local targetStage = nextStage
                if targetStage > cfg.maxStage then
                    targetStage = cfg.maxStage
                end
                local curStage = getCurrentStage()
                if curStage ~= targetStage then
                    local area = getBattleArea(targetStage)
                    if not area then
                        setStatus("ไม่มีพื้นที่ Stage " .. targetStage)
                        stopFarm()
                    else
                        setStatus("Go Stage " .. targetStage)
                        tweenTo(area.Position + Vector3.new(0, 5, 0), cfg.speed)
                        task.wait(0.4)
                        if not isInDungeon() then
                            fireDungeonSpawn(targetStage)
                            setStatus("เข้า Stage " .. targetStage)
                            task.wait(1.5)
                        end
                        if isBagFull() then
                            setStatus("กระเป๋าเต็ม กลับเมือง")
                            returnToTown()
                            task.wait(4)
                            if cfg.farm then
                                local ar2 = getBattleArea(targetStage)
                                if ar2 then
                                    tweenTo(ar2.Position + Vector3.new(0, 5, 0), cfg.speed)
                                    fireDungeonSpawn(targetStage)
                                    task.wait(1.5)
                                end
                            end
                        end
                    end
                else
                    if not isInDungeon() then
                        fireDungeonSpawn(curStage)
                        setStatus("เข้า Stage " .. curStage)
                        task.wait(1.5)
                    end
                    local fought = fightStage(curStage)
                    if isBagFull() then
                        setStatus("กระเป๋าเต็ม กลับเมือง")
                        returnToTown()
                        task.wait(4)
                    elseif not fought then
                        if targetStage == cfg.maxStage then
                            waitForRespawn(curStage)
                        else
                            collectDrops()
                            task.wait(0.5)
                        end
                    else
                        collectDrops()
                    end
                end
            end
        end
    end
end

local Window = Fluent:CreateWindow({
    Title = "Kala Hub",
    SubTitle = "Magic Loot",
    TabWidth = 130,
    Size = UDim2.fromOffset(620, 480),
    Acrylic = true,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.RightControl,
})

local TabDungeon = Window:AddTab({ Title = "Auto", Icon = "swords" })

local TabShop = Window:AddTab({ Title = "Shop", Icon = "shopping-cart" })

local TabMisc = Window:AddTab({ Title = "Misc", Icon = "wrench" })

local TabSettings = Window:AddTab({ Title = "Settings", Icon = "settings" })

-- Welcome notification + flair on first open
task.spawn(function()
    task.wait(1)
    Fluent:Notify({
        Title = "Kala Hub",
        Content = "Welcome back, " .. tostring(LocalPlayer.Name) .. "!",
        Duration = 4,
    })
end)

local SectionMovement = TabMisc:AddSection("Movement")

local SpeedHook = {
    hum = nil,
    mt = nil,
    orig = nil,
    enabled = false,
    baseSpeed = 16,
    targetSpeed = 16,
}

local function getMoveMult()
    if not SpeedHook.enabled then
        return 1
    end
    return SpeedHook.targetSpeed / SpeedHook.baseSpeed
end

local function hookCharacterSpeed()
    local char = LocalPlayer.Character
    if not char then
        return false
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        return false
    end
    if SpeedHook.hum == hum then
        return true
    end
    local orig = getrawmetatable(hum)
    if type(orig) ~= "table" then
        return false
    end
    local newmt = {}
    for k, v in pairs(orig) do
        newmt[k] = v
    end
    local oldNI = newmt.__newindex
    newmt.__newindex = function(self, key, value)
        if key == "WalkSpeed" and type(value) == "number" and value >= 10 then
            local mult = getMoveMult()
            if mult ~= 1 then
                value = value * mult
            end
        end
        return oldNI(self, key, value)
    end
    local ok = pcall(setrawmetatable, hum, newmt)
    if ok then
        SpeedHook.hum = hum
        SpeedHook.mt = newmt
        SpeedHook.orig = orig
    end
    return ok
end

local MoveToggle = SectionMovement:AddToggle("MoveToggle", {
    Title = "Movement",
    Default = false,
    Callback = function(state)
        SpeedHook.enabled = state
        if state then
            hookCharacterSpeed()
        else
            if SpeedHook.hum and SpeedHook.orig then
                pcall(setrawmetatable, SpeedHook.hum, SpeedHook.orig)
            end
            SpeedHook.hum = nil
            SpeedHook.mt = nil
            SpeedHook.orig = nil
        end
    end,
})

local SpeedSlider = SectionMovement:AddSlider("SpeedSlider", {
    Title = "Speed",
    Min = 1,
    Max = 300,
    Default = SpeedHook.baseSpeed,
    Rounding = 0,
    Callback = function(value)
        SpeedHook.targetSpeed = math.floor(value)
    end,
})

if STATE and STATE.connect then
    STATE.connect(LocalPlayer.CharacterAdded, function()
        if SpeedHook.enabled then
            hookCharacterSpeed()
        end
    end)
else
    LocalPlayer.CharacterAdded:Connect(function()
        if SpeedHook.enabled then
            hookCharacterSpeed()
        end
    end)
end

local SectionMain = TabDungeon:AddSection("Auto Farm")

AutoDungeonToggle = SectionMain:AddToggle("AutoDungeon", {
    Title = "Auto Dungeon",
    Desc = "Auto Stage",
    Default = false,
    Callback = function(state)
        cfg.farm = state
        if state then
            task.spawn(farmLoop)
        else
            setStatus("ปิด Auto Dungeon")
        end
    end,
})

local StopSlider = SectionMain:AddSlider("StopAtStage", {
    Title = "Stop At Stage",
    Desc = "Stop At Stage",
    Min = 1,
    Max = MAX_STAGE,
    Default = 24,
    Rounding = 0,
    Callback = function(value)
        cfg.maxStage = math.floor(value)
    end,
})

local SectionLoot = TabDungeon:AddSection("Auto Loot")

AutoLootToggle = SectionLoot:AddToggle("AutoLoot", {
    Title = "Auto Loot",
    Desc = "Auto Loot Automatic",
    Default = false,
    Callback = function(state)
        cfg.autoLoot = state
        if state then
            setStatus("Auto Loot เปิด")
            task.spawn(lootLoop)
        else
            setStatus("Auto Loot ปิด")
        end
    end,
})

local RarityDropdown = SectionLoot:AddDropdown("Rarity", {
    Title = "Rarity",
    Desc = "Select the item tier",
    Values = {
        RARITY_NAMES[1],
        RARITY_NAMES[2],
        RARITY_NAMES[3],
        RARITY_NAMES[4],
        RARITY_NAMES[5],
        RARITY_NAMES[6],
        RARITY_NAMES[7],
        RARITY_NAMES[8],
        RARITY_NAMES[9],
        RARITY_NAMES[10],
    },
    Multi = true,
    Default = {},
    Callback = function(selected)
        cfg.rarityFilter = {}
        local list = selected
        if type(list) ~= "table" then
            list = list and { list } or {}
        end
        for k2, v2 in pairs(list) do
            local name = k2
            if type(name) ~= "string" then
                name = v2
            end
            if type(name) == "string" then
                for k, v in ipairs(RARITY_NAMES) do
                    if v == name then
                        cfg.rarityFilter[k] = true
                        break
                    end
                end
            end
        end
    end,
})

local LootValueInput = SectionLoot:AddInput("LootValue", {
    Title = "Value",
    Placeholder = "0",
    Default = "0",
    Callback = function(text)
        cfg.minGold = tonumber(text) or 0
    end,
})

SectionLoot:AddButton({
    Title = "Loot Now",
    Callback = function()
        task.spawn(function()
            local n = collectDrops(true)
            notify("Auto Loot", "เก็บแล้ว " .. n .. " ชิ้น")
        end)
    end,
})

local SectionBuy = TabShop:AddSection("Auto Buy")

local AutoBuyToggle = SectionBuy:AddToggle("AutoBuy", {
    Title = "Auto Buy Equipment",
    Default = false,
    Callback = function(state)
        cfg.autoBuy = state
        if state then
            setStatus("Auto Buy เปิด")
            task.spawn(buyLoop)
        else
            setStatus("Auto Buy ปิด")
        end
    end,
})

local BuyWeaponToggle = SectionBuy:AddToggle("BuyWeapon", {
    Title = "Buy Weapon",
    Default = true,
    Callback = function(state)
        cfg.buyWeapon = state
    end,
})

local BuyArmorToggle = SectionBuy:AddToggle("BuyArmor", {
    Title = "Buy Armor",
    Default = true,
    Callback = function(state)
        cfg.buyArmor = state
    end,
})

SectionBuy:AddButton({
    Title = "Buy Now",
    Callback = function()
        task.spawn(function()
            local n = buyEquipOnce()
            notify("Auto Buy", n > 0 and "ซื้อแล้ว " .. n .. " ชิ้น" or "ไม่มีของที่ดีกว่าที่ซื้อได้")
        end)
    end,
})

local SectionSell = TabShop:AddSection("Auto Sell")

local AutoSellToggle = SectionSell:AddToggle("AutoSell", {
    Title = "Auto Sell Materials",
    Default = false,
    Callback = function(state)
        cfg.autoSell = state
        if state then
            setStatus("Auto Sell เปิด")
            task.spawn(sellLoop)
        else
            setStatus("Auto Sell ปิด")
        end
    end,
})

local SellRarityDropdown = SectionSell:AddDropdown("SellRarity", {
    Title = "Rarity",
    Values = {
        RARITY_NAMES[1],
        RARITY_NAMES[2],
        RARITY_NAMES[3],
        RARITY_NAMES[4],
        RARITY_NAMES[5],
        RARITY_NAMES[6],
        RARITY_NAMES[7],
        RARITY_NAMES[8],
        RARITY_NAMES[9],
        RARITY_NAMES[10],
    },
    Multi = true,
    Default = {},
    Callback = function(selected)
        cfg.sellRarity = {}
        local list = selected
        if type(list) ~= "table" then
            list = list and { list } or {}
        end
        for k2, v2 in pairs(list) do
            local name = k2
            if type(name) ~= "string" then
                name = v2
            end
            if type(name) == "string" then
                for k, v in ipairs(RARITY_NAMES) do
                    if v == name then
                        cfg.sellRarity[k] = true
                        break
                    end
                end
            end
        end
    end,
})

local SellPriceInput = SectionSell:AddInput("SellPrice", {
    Title = "Rarity to Sell",
    Placeholder = "Enter the number",
    Default = "",
    Callback = function(text)
        local n = tonumber(text)
        if n and n > 0 then
            cfg.sellMinPrice = n
        else
            cfg.sellMinPrice = nil
        end
    end,
})

local SectionRebirth = TabDungeon:AddSection("Auto Rebirth")

local AutoRebirthToggle = SectionRebirth:AddToggle("AutoRebirth", {
    Title = "Auto Rebirth",
    Default = false,
    Callback = function(state)
        cfg.autoRebirth = state
        if state then
            setStatus("Auto Rebirth เปิด")
            task.spawn(rebirthLoop)
        else
            setStatus("Auto Rebirth ปิด")
        end
    end,
})

SectionRebirth:AddButton({
    Title = "Rebirth Now",
    Callback = function()
        task.spawn(function()
            if doRebirth() then
                notify("Auto Rebirth", "Rebirth แล้ว")
            else
                notify("Auto Rebirth", "ยังไม่ถึงเงื่อนไข Rebirth")
            end
        end)
    end,
})

local IndexView
pcall(function()
    IndexView = require(game.ReplicatedStorage.ClientSideCode.GuiScripts.ModuleScript.Index.IndexView)
end)

local function getIndexSnapshots()
    local ok, data = pcall(function()
        return PlayerData.GetPlrDataByKey(LocalPlayer, "Index")
    end)
    if not ok or type(data) ~= "table" then
        return nil
    end
    local ok2, snap = pcall(function()
        return IndexView.buildAllTabSnapshots(data)
    end)
    if not ok2 or type(snap) ~= "table" then
        return nil
    end
    return snap
end

local function tryClaimIndexTab(tag)
    local snap = getIndexSnapshots()
    if not snap or type(snap[tag]) ~= "table" then
        return false
    end
    local progress = snap[tag].progress
    if not progress or not progress.canClaim then
        return false
    end
    if not progress.targetProgress then
        return false
    end
    local ok, resp = pcall(function()
        return NetWork.InvokeServer(NetMsg.INDEX_CLAIM_REWARD, {
            tag = tag,
            progress = progress.targetProgress,
        })
    end)
    if ok then
        setStatus(("Auto Claim %s สำเร็จ"):format(tag))
        return true
    end
    return false
end

local function claimLoop()
    while cfg.autoClaim do
        task.wait(3)
        if cfg.autoClaim then
            local claimedMat = tryClaimIndexTab("Material")
            if not cfg.autoClaim then
                break
            end
            local claimedPot = tryClaimIndexTab("Potion")
            if cfg.autoClaim and (claimedMat or claimedPot) then
                task.wait(1)
            end
        end
    end
end

local SectionClaim = TabDungeon:AddSection("Auto Claim")

AutoClaimToggle = SectionClaim:AddToggle("AutoClaim", {
    Title = "Auto Claim",
    Desc = "Claim Materials & Potions",
    Default = false,
    Callback = function(state)
        cfg.autoClaim = state
        if state then
            setStatus("Auto Claim เปิด")
            task.spawn(claimLoop)
        else
            setStatus("Auto Claim ปิด")
        end
    end,
})

local SectionConfig = TabSettings:AddSection("Config")

local CONFIG_FOLDER = "KalaHubConfigs"

local function configNameToPath(name)
    local safe = tostring(name):gsub("[^%w%-_%.]", "")
    return CONFIG_FOLDER .. "/" .. safe .. ".json"
end

local function getConfigList()
    local out = {}
    if isfolder(CONFIG_FOLDER) then
        for _, p in ipairs(listfiles(CONFIG_FOLDER)) do
            if p:sub(-5) == ".json" then
                local name = p:match("([^/\\]+)%.json$")
                if name then
                    out[#out + 1] = name
                end
            end
        end
    end
    return out
end

local function configToData()
    return {
        farm = cfg.farm,
        maxStage = cfg.maxStage,
        speed = cfg.speed,
        attackInterval = cfg.attackInterval,
        autoLoot = cfg.autoLoot,
        rarityFilter = cfg.rarityFilter,
        minGold = cfg.minGold,
        autoBuy = cfg.autoBuy,
        buyWeapon = cfg.buyWeapon,
        buyArmor = cfg.buyArmor,
        autoSell = cfg.autoSell,
        sellRarity = cfg.sellRarity,
        sellMinPrice = cfg.sellMinPrice,
        autoRebirth = cfg.autoRebirth,
    }
end

local function cleanRarityTable(t)
    -- json.decode in Real injects a sentinel userdata key into empty tables;
    -- keep only the real number keys (rarity indices) so the "no filter" logic works
    local out = {}
    if type(t) ~= "table" then
        return out
    end
    for k, v in pairs(t) do
        if type(k) == "number" then
            out[k] = v
        end
    end
    return out
end

local function applyConfigData(data)
    if type(data) ~= "table" then
        return
    end
    if type(data.farm) == "boolean" then cfg.farm = data.farm end
    if type(data.maxStage) == "number" then cfg.maxStage = data.maxStage end
    if type(data.speed) == "number" then cfg.speed = data.speed end
    if type(data.attackInterval) == "number" then cfg.attackInterval = data.attackInterval end
    if type(data.autoLoot) == "boolean" then cfg.autoLoot = data.autoLoot end
    if type(data.rarityFilter) == "table" then cfg.rarityFilter = cleanRarityTable(data.rarityFilter) end
    if type(data.minGold) == "number" then cfg.minGold = data.minGold end
    if type(data.autoBuy) == "boolean" then cfg.autoBuy = data.autoBuy end
    if type(data.buyWeapon) == "boolean" then cfg.buyWeapon = data.buyWeapon end
    if type(data.buyArmor) == "boolean" then cfg.buyArmor = data.buyArmor end
    if type(data.autoSell) == "boolean" then cfg.autoSell = data.autoSell end
    if type(data.sellRarity) == "table" then cfg.sellRarity = cleanRarityTable(data.sellRarity) end
    if type(data.sellMinPrice) == "number" then cfg.sellMinPrice = data.sellMinPrice end
    if type(data.autoRebirth) == "boolean" then cfg.autoRebirth = data.autoRebirth end
end

local function syncUIFromCfg()
    pcall(function()
        AutoDungeonToggle:SetValue(cfg.farm)
    end)
    pcall(function()
        StopSlider:SetValue(cfg.maxStage)
    end)
    pcall(function()
        AutoLootToggle:SetValue(cfg.autoLoot)
    end)
    pcall(function()
        local sel = {}
        for k, v in pairs(cfg.rarityFilter) do
            if v then
                sel[RARITY_NAMES[k]] = true
            end
        end
        RarityDropdown:SetValue(sel)
    end)
    pcall(function()
        LootValueInput:SetValue(tostring(cfg.minGold))
    end)
    pcall(function()
        AutoBuyToggle:SetValue(cfg.autoBuy)
    end)
    pcall(function()
        BuyWeaponToggle:SetValue(cfg.buyWeapon)
    end)
    pcall(function()
        BuyArmorToggle:SetValue(cfg.buyArmor)
    end)
    pcall(function()
        AutoSellToggle:SetValue(cfg.autoSell)
    end)
    pcall(function()
        local sel = {}
        for k, v in pairs(cfg.sellRarity) do
            if v then
                sel[RARITY_NAMES[k]] = true
            end
        end
        SellRarityDropdown:SetValue(sel)
    end)
    pcall(function()
        if cfg.sellMinPrice then
            SellPriceInput:SetValue(tostring(cfg.sellMinPrice))
        else
            SellPriceInput:SetValue("")
        end
    end)
    pcall(function()
        AutoRebirthToggle:SetValue(cfg.autoRebirth)
    end)
    pcall(function()
        SpeedSlider:SetValue(SpeedHook.baseSpeed)
    end)
end

local function saveConfig(name)
    local path = configNameToPath(name)
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
    writefile(path, json.encode(configToData()))
end

local function loadConfig(name)
    local path = configNameToPath(name)
    if not isfile(path) then
        return false
    end
    local ok, data = pcall(function()
        return json.decode(readfile(path))
    end)
    if not ok or type(data) ~= "table" then
        return false
    end
    applyConfigData(data)
    syncUIFromCfg()
    return true
end

local function deleteConfig(name)
    local path = configNameToPath(name)
    if isfile(path) then
        delfile(path)
    end
end

local ConfigNameInput = SectionConfig:AddInput("ConfigName", {
    Title = "Config Name",
    Placeholder = "main",
    Default = "main",
})

local ConfigListDropdown = SectionConfig:AddDropdown("ConfigSelect", {
    Title = "Config",
    Values = getConfigList(),
    Default = getConfigList()[1],
})

SectionConfig:AddButton({
    Title = "Save Config",
    Callback = function()
        local name = ConfigNameInput.Value
        if not name or name == "" then
            name = "main"
        end
        saveConfig(name)
        notify("Config", "Saved: " .. name)
        ConfigListDropdown:SetValue(name)
    end,
})

SectionConfig:AddButton({
    Title = "Load Config",
    Callback = function()
        local name = ConfigNameInput.Value
        if not name or name == "" then
            notify("Config", "กรอกชื่อ Config ก่อน")
            return
        end
        if loadConfig(name) then
            notify("Config", "Loaded: " .. name)
        else
            notify("Config", "ไม่พบ Config: " .. name)
        end
    end,
})

SectionConfig:AddButton({
    Title = "Delete Config",
    Callback = function()
        local name = ConfigNameInput.Value
        if not name or name == "" then
            notify("Config", "กรอกชื่อ Config ก่อน")
            return
        end
        deleteConfig(name)
        notify("Config", "Deleted: " .. name)
    end,
})

-- load last saved config on script start
local names = getConfigList()
if #names > 0 then
    loadConfig(names[#names])
end

local DISCORD_INVITE = "https://discord.gg/xBqjvTqWdA"

local SectionContact = TabSettings:AddSection("Contact")

SectionContact:AddButton({
    Title = "Discord",
    Callback = function()
        pcall(setclipboard, DISCORD_INVITE)
        pcall(function()
            game:GetService("HttpService"):PromptWebBrowser(DISCORD_INVITE)
        end)
        notify("Contact", "Discord: " .. DISCORD_INVITE)
    end,
})

local SectionUISettings = TabSettings:AddSection("UI Settings")

local ThemeDropdown = SectionUISettings:AddDropdown("Theme", {
    Title = "Theme",
    Values = { "Amethyst", "Dark", "Darker", "Light", "Aqua", "Rose" },
    Default = "Amethyst",
    Callback = function(color)
        pcall(Fluent.SetTheme, Fluent, color)
    end,
})

StatusParagraph = SectionMain:AddParagraph({
    Title = "Status",
    Content = "Idle",
})

SectionMain:AddButton({
    Title = "Return",
    Callback = function()
        returnToTown()
        notify("Kala Hub", "กำลังกลับเมือง")
    end,
})

getgenv().KalaHubCfg = cfg
getgenv().KalaHubStart = function()
    cfg.farm = true
    if not getgenv()._kalaRunning then
        getgenv()._kalaRunning = true
        task.spawn(function()
            farmLoop()
            getgenv()._kalaRunning = nil
        end)
    end
end
getgenv().KalaHubStop = function()
    stopFarm()
end
getgenv().KalaLootStart = function()
    cfg.autoLoot = true
    if not getgenv()._kalaLootRunning then
        getgenv()._kalaLootRunning = true
        task.spawn(function()
            lootLoop()
            getgenv()._kalaLootRunning = nil
        end)
    end
end
getgenv().KalaLootStop = function()
    cfg.autoLoot = false
end
getgenv().KalaBuyStart = function()
    cfg.autoBuy = true
    if not getgenv()._kalaBuyRunning then
        getgenv()._kalaBuyRunning = true
        task.spawn(function()
            buyLoop()
            getgenv()._kalaBuyRunning = nil
        end)
    end
end
getgenv().KalaBuyStop = function()
    cfg.autoBuy = false
end
getgenv().KalaBuyNow = function()
    return buyEquipOnce()
end
getgenv().KalaSellStart = function()
    cfg.autoSell = true
    if not getgenv()._kalaSellRunning then
        getgenv()._kalaSellRunning = true
        task.spawn(function()
            sellLoop()
            getgenv()._kalaSellRunning = nil
        end)
    end
end
getgenv().KalaSellStop = function()
    cfg.autoSell = false
end
getgenv().KalaSellNow = function()
    return sellMaterialsOnce()
end
getgenv().KalaRebirthStart = function()
    cfg.autoRebirth = true
    if not getgenv()._kalaRebirthRunning then
        getgenv()._kalaRebirthRunning = true
        task.spawn(function()
            rebirthLoop()
            getgenv()._kalaRebirthRunning = nil
        end)
    end
end
getgenv().KalaRebirthStop = function()
    cfg.autoRebirth = false
end
getgenv().KalaRebirthNow = function()
    return doRebirth()
end
getgenv().KalaRebirthCan = function()
    return canRebirth()
end

-- clean up the hover platform if this script is re-run/reloaded
for _, p in ipairs(workspace:GetChildren()) do
    if p.Name == "KalaHoverPlatform" then
        pcall(function()
            p:Destroy()
        end)
    end
end

if STATE and STATE.onCleanup then
    STATE.onCleanup(function()
        destroyHoverPlatform()
        if SpeedHook.hum and SpeedHook.orig then
            pcall(setrawmetatable, SpeedHook.hum, SpeedHook.orig)
            SpeedHook.hum = nil
            SpeedHook.mt = nil
            SpeedHook.orig = nil
        end
    end)
end