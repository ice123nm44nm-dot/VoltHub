local Genv = getgenv()
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ice123nm44nm-dot/VoltHub/main/VoltUi.lua"))()
local Window = Library:CreateWindow({
    Name = "VoltScriptZ",
    Title = "Volt",
    TitleAccent = "ScriptZ",
    Subtitle = "Map Hunting Together | Made By VoltScript Hub",
    Logo = "rbxassetid://100712256015627",
    ToggleKey = Enum.KeyCode.RightControl
})
Window:AddSection("General")
local MainTab = Window:AddTab({ Name = "Main" })
local ShopTab = Window:AddTab({ Name = "Shop" })
Window:AddSection("Utilities")
local UtilitiesTab = Window:AddTab({ Name = "Utilities" })
local SettingsTab = Window:AddTab({ Name = "Settings" })
local FarmCard = MainTab:AddCard({
    Title = "Farm",
    Subtitle = "Auto Farm by Teleport",
    Toggle = false
})
local CheatTeleportInfo = FarmCard:AddInfo({
    Text = "Cheat Tag Teleport",
    Value = "None"
})
local CheatRapidInfo = FarmCard:AddInfo({
    Text = "Cheat Tag Teleport Rapid",
    Value = "None"
})
local CheatTagPlayer = game:GetService("Players").LocalPlayer
local function RefreshCheatTag()
    local Tag = CheatTagPlayer:GetAttribute("CheatTag")
    Tag = Tag and tostring(Tag) or ""
    local TeleportCount = string.match(Tag, "Teleport (%d+)")
    local RapidCount = string.match(Tag, "Rapid teleport (%d+)")
    CheatTeleportInfo:Set(TeleportCount or "None")
    CheatRapidInfo:Set(RapidCount or "None")
end
RefreshCheatTag()
CheatTagPlayer:GetAttributeChangedSignal("CheatTag"):Connect(RefreshCheatTag)
local BossCard = MainTab:AddCard({
    Title = "Boss",
    Subtitle = "Auto Boss Room",
    Toggle = false,
    Column = 2
})
local OtherCard = MainTab:AddCard({
    Title = "Other",
    Subtitle = "Extra tools",
    Toggle = false,
    Column = 2
})
local VSWalkTo
local VSPauseBot
local VSResumeBot
OtherCard:AddToggle({
    Name = "Auto Collect Chest",
    Default = false,
    Flag = "AutoCollectChest",
    Callback = function(Value)
        Genv.VS_Chest = Genv.VS_Chest or {}
        Genv.VS_Chest.Running = Value == true
        if not Genv.VS_Chest.Running then
            Genv.VS_ChestBusy = false
            return
        end
        if Genv.VS_Chest.Thread then
            return
        end
        Genv.VS_Chest.Thread = task.spawn(function()
            local CollectionService = game:GetService("CollectionService")
            local Players = game:GetService("Players")
            local LocalPlayer = Players.LocalPlayer

            -- Measured in this map, not guessed:
            --   the "LootBox" tag sits on the box Part itself
            --   prompt:InputHoldBegin/InputHoldEnd opens it at 5.4 studs flat
            --   (Prompt.Triggered fired once and the Part was destroyed);
            --   the same call at 8-9.4 studs did nothing, so stop at 5.
            --   Remotes.OpenLootBox:FireServer does nothing even at 3.2 studs,
            --   so the prompt is the only working path.
            local SCAN_RANGE = 25
            local OPEN_RANGE = 5
            local SCAN_INTERVAL = 0.12
            local ATTEMPTS = 5
            local RETRY_GAP = 0.35
            local BLACKLIST_TIME = 20
            local WALK_TIMEOUT = 25

            local Blacklist = {}

            local function FlatDistance(A, B)
                return (Vector3.new(A.X, 0, A.Z) - Vector3.new(B.X, 0, B.Z)).Magnitude
            end

            local function GetRoot()
                local Character = LocalPlayer.Character
                local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                local Root = Character and Character:FindFirstChild("HumanoidRootPart")
                if Humanoid and Root and Humanoid.Health > 0 and not Root.Anchored then
                    return Humanoid, Root
                end
                return nil, nil
            end

            local function IsBoxOpen(Box)
                if not Box.Parent or not Box:IsDescendantOf(workspace) then
                    return true
                end
                local Prompt = Box:FindFirstChildWhichIsA("ProximityPrompt", true)
                return Prompt == nil or Prompt.Enabled == false
            end

            local function FindTarget(Root)
                local BestBox, BestDist
                for _, Box in ipairs(CollectionService:GetTagged("LootBox")) do
                    if Box:IsA("BasePart") and Box.Parent then
                        local SkipUntil = Blacklist[Box]
                        if not SkipUntil or os.clock() >= SkipUntil then
                            local Prompt = Box:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if Prompt and Prompt.Enabled then
                                local Dist = FlatDistance(Box.Position, Root.Position)
                                if Dist <= SCAN_RANGE and (not BestDist or Dist < BestDist) then
                                    BestBox, BestDist = Box, Dist
                                end
                            end
                        end
                    end
                end
                return BestBox, BestDist
            end

            local function TryOpen(Box)
                for _ = 1, ATTEMPTS do
                    if not Genv.VS_Chest.Running then
                        return false
                    end
                    if IsBoxOpen(Box) then
                        return true
                    end
                    local Prompt = Box:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if not Prompt then
                        return true
                    end
                    local _, Root = GetRoot()
                    if not Root then
                        return false
                    end
                    if FlatDistance(Box.Position, Root.Position) > OPEN_RANGE + 3 then
                        return false
                    end
                    pcall(function()
                        Prompt:InputHoldBegin()
                    end)
                    task.wait(math.max(0.12, tonumber(Prompt.HoldDuration) or 0) + 0.08)
                    pcall(function()
                        if Prompt.Parent then
                            Prompt:InputHoldEnd()
                        end
                    end)
                    task.wait(RETRY_GAP)
                end
                return IsBoxOpen(Box)
            end

            while Genv.VS_Chest.Running do
                local _, Root = GetRoot()
                if not Root
                    or Genv.VS_ChestBusy
                    or Genv.VS_WalkBusy
                    or Genv.VS_ShopBusy
                    or Genv.VS_BossPriority then
                    task.wait(SCAN_INTERVAL)
                    continue
                end

                local Target, TargetDist = FindTarget(Root)
                if not Target then
                    task.wait(SCAN_INTERVAL)
                    continue
                end

                -- Teleport farm mode moves the character by CFrame, so only
                -- grab boxes that are already in reach instead of walking.
                local Farming = (Genv.VS_AutoFarm and Genv.VS_AutoFarm.Running)
                    or (Genv.VS_FieldFarm and Genv.VS_FieldFarm.Running)
                    or (Genv.VS_BossFarm and Genv.VS_BossFarm.Running)
                local NeedWalk = TargetDist > OPEN_RANGE
                if NeedWalk and Farming and (Genv.VS_FarmMoveMode or "teleport") ~= "walk" then
                    task.wait(SCAN_INTERVAL)
                    continue
                end

                Genv.VS_ChestBusy = true
                local WasAutoOn = LocalPlayer:GetAttribute("AutoOn") == true
                local Opened = false
                local WalkFailed = false
                pcall(function()
                    if NeedWalk then
                        local Reached = VSWalkTo(Target.Position, {
                            AcceptDistance = OPEN_RANGE,
                            Timeout = WALK_TIMEOUT,
                            SkipPillar = true,
                            SkipBotResume = true,
                            IsActive = function()
                                return Genv.VS_Chest.Running
                            end,
                        })
                        if not Reached then
                            WalkFailed = true
                            return
                        end
                        -- Let the humanoid settle before the prompt input,
                        -- the trigger was measured while standing still.
                        task.wait(0.1)
                    else
                        VSPauseBot()
                        task.wait(0.1)
                    end
                    Opened = TryOpen(Target)
                end)
                if not Opened and not WalkFailed then
                    Blacklist[Target] = os.clock() + BLACKLIST_TIME
                end
                if WasAutoOn then
                    pcall(VSResumeBot)
                end
                Genv.VS_ChestBusy = false
                task.wait(0.1)
            end
            Genv.VS_ChestBusy = false
            Genv.VS_Chest.Thread = nil
        end)
    end
})
OtherCard:AddToggle({
    Name = "Auto Gear",
    Default = false,
    Flag = "AutoGear",
    Callback = function(Value)
        if Value then
            Genv.VS_GearAuto = true
            if not Genv.VS_GearThread then
                Genv.VS_GearThread = task.spawn(function()
                    local Players = game:GetService("Players")
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local HttpService = game:GetService("HttpService")
                    local LocalPlayer = Players.LocalPlayer
                    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
                    local Shared = ReplicatedStorage:WaitForChild("Shared")
                    local ItemData = require(Shared:WaitForChild("ItemData"))
                    local PreviewAll = Remotes:WaitForChild("GearPreviewAll")
                    local Fired = {}
                    local function Decode(Name)
                        local Ok, Data = pcall(function()
                            return HttpService:JSONDecode(LocalPlayer:GetAttribute(Name) or "{}")
                        end)
                        if Ok and type(Data) == "table" then
                            return Data
                        end
                        return {}
                    end
                    local function CanFire(Id)
                        if Fired[Id] and os.clock() - Fired[Id] < 30 then
                            return false
                        end
                        Fired[Id] = os.clock()
                        return true
                    end
                    local function Step()
                        local Ok, Scores = pcall(function()
                            return PreviewAll:InvokeServer()
                        end)
                        if not Ok or type(Scores) ~= "table" then
                            return
                        end
                        local Gear = Decode("GearJson")
                        local Equip = Decode("EquipJson")
                        local WeaponId = LocalPlayer:GetAttribute("WeaponId") or ""
                        local CurrentWeapon = WeaponId ~= "" and Gear[WeaponId] or nil
                        local CurrentType = CurrentWeapon
                            and ItemData[CurrentWeapon.Id]
                            and ItemData[CurrentWeapon.Id].WeaponType
                            or nil
                        local Best = {}
                        local BestWeapon = nil
                        local AccList = {}
                        for Id, Info in pairs(Gear) do
                            local Score = Scores[Id]
                            local Data = Info.Id and ItemData[Info.Id]
                            if type(Score) == "number" and Score > 0 and Data then
                                if Data.Kind == "weapon" then
                                    if not CurrentType or Data.WeaponType == CurrentType then
                                        if not BestWeapon or Score > BestWeapon.Score then
                                            BestWeapon = { Id = Id, Score = Score }
                                        end
                                    end
                                elseif Data.Kind == "armor" then
                                    if Data.Slot == "Acc" then
                                        table.insert(AccList, { Id = Id, Score = Score })
                                    elseif Data.Slot then
                                        if not Best[Data.Slot] or Score > Best[Data.Slot].Score then
                                            Best[Data.Slot] = { Id = Id, Score = Score }
                                        end
                                    end
                                end
                            end
                        end
                        for Slot, Entry in pairs(Best) do
                            if Equip[Slot] ~= Entry.Id and CanFire(Entry.Id) then
                                Remotes.EquipItem:FireServer(Entry.Id)
                                task.wait(0.3)
                            end
                        end
                        if BestWeapon and WeaponId ~= BestWeapon.Id and CanFire(BestWeapon.Id) then
                            Remotes.EquipWeapon:FireServer(BestWeapon.Id)
                            task.wait(0.3)
                        end
                        if (Equip.Acc1 or "") == "" or (Equip.Acc2 or "") == "" then
                            table.sort(AccList, function(A, B)
                                return A.Score > B.Score
                            end)
                            local Have = { [Equip.Acc1 or ""] = true, [Equip.Acc2 or ""] = true }
                            local Picked = 0
                            for _, Entry in ipairs(AccList) do
                                if Picked >= 2 then
                                    break
                                end
                                if not Have[Entry.Id] and CanFire(Entry.Id) then
                                    Remotes.EquipItem:FireServer(Entry.Id)
                                    task.wait(0.3)
                                end
                                Picked = Picked + 1
                            end
                        end
                    end
                    while Genv.VS_GearAuto do
                        pcall(Step)
                        task.wait(15)
                    end
                    Genv.VS_GearThread = nil
                end)
            end
        else
            Genv.VS_GearAuto = false
        end
    end
})
OtherCard:AddToggle({
    Name = "Auto Card",
    Default = false,
    Flag = "AutoCard",
    Callback = function(Value)
        if Value then
            Genv.VS_CardAuto = true
            if not Genv.VS_CardThread then
                Genv.VS_CardThread = task.spawn(function()
                    local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
                    local CardAction = Remotes:WaitForChild("CardAction")
                    while Genv.VS_CardAuto do
                        pcall(function()
                            CardAction:FireServer("auto")
                        end)
                        task.wait(20)
                    end
                    Genv.VS_CardThread = nil
                end)
            end
        else
            Genv.VS_CardAuto = false
        end
    end
})
OtherCard:AddDropdown({
    Name = "Mode",
    Options = { "Town (free)", "Here (pay silver)" },
    Default = "Town (free)",
    Flag = "RespawnMode",
    Callback = function(Value)
        Genv.VS_RespawnMode = Value == "Here (pay silver)" and "here" or "town"
    end
})
OtherCard:AddToggle({
    Name = "Auto Respawn",
    Default = false,
    Flag = "AutoRespawn",
    Callback = function(Value)
        if Value then
            Genv.VS_RespawnAuto = true
            if not Genv.VS_RespawnThread then
                Genv.VS_RespawnThread = task.spawn(function()
                    local Players = game:GetService("Players")
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local LocalPlayer = Players.LocalPlayer
                    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
                    local RespawnChoice = Remotes:WaitForChild("RespawnChoice")
                    local LastFire = 0
                    local Attempts = 0
                    while Genv.VS_RespawnAuto do
                        local Character = LocalPlayer.Character
                        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                        local Dead = (not Humanoid) or Humanoid.Health <= 0
                        if not Dead then
                            Attempts = 0
                        end
                        local Waiting = LocalPlayer:GetAttribute("HuntRespawnOpen") == true
                            or LocalPlayer:GetAttribute("HuntRespawnWaiting") == true
                        local PaidCountdown = (LocalPlayer:GetAttribute("RespawnHereAt") or 0) > 0
                        if (Dead or Waiting) and not PaidCountdown and os.clock() - LastFire > 3 then
                            LastFire = os.clock()
                            local Mode = Genv.VS_RespawnMode or "town"
                            if Attempts >= 3 then
                                Mode = "town"
                            end
                            local Ok = pcall(function()
                                RespawnChoice:FireServer(Mode)
                            end)
                            if Ok then
                                Attempts = Attempts + 1
                            end
                        end
                        task.wait(1)
                    end
                    Genv.VS_RespawnThread = nil
                end)
            end
        else
            Genv.VS_RespawnAuto = false
        end
    end
})
local LeaveToggle = OtherCard:AddToggle({
    Name = "Leave on Admin",
    Default = true,
    Flag = "LeaveOnAdmin",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local function LeaveNow(AdminName)
            if Genv.VS_Leaving then
                return
            end
            Genv.VS_Leaving = true
            if Genv.VS_AutoFarm then
                Genv.VS_AutoFarm.Running = false
            end
            if Genv.VS_FieldFarm then
                Genv.VS_FieldFarm.Running = false
            end
            if Genv.VS_BossFarm then
                Genv.VS_BossFarm.Running = false
            end
            Genv.VS_GearAuto = false
            Genv.VS_CardAuto = false
            Genv.VS_RespawnAuto = false
            Genv.VS_DodgeEnabled = false
            warn("[Volt] admin detected: " .. tostring(AdminName) .. " - leaving")
            pcall(function()
                LocalPlayer:Kick("VoltScriptZ: admin joined")
            end)
        end
        local function Check(Player)
            if not Genv.VS_AdminLeave then
                return
            end
            if Player ~= LocalPlayer and Player:GetAttribute("IsAdmin") == true then
                LeaveNow(Player.Name)
            end
        end
        if Value then
            Genv.VS_AdminLeave = true
            Genv.VS_Leaving = false
            local Tracked = {}
            local function Watch(Player)
                if Tracked[Player] then
                    return
                end
                Tracked[Player] = true
                Check(Player)
                Player:GetAttributeChangedSignal("IsAdmin"):Connect(function()
                    Check(Player)
                end)
            end
            for _, Player in ipairs(Players:GetPlayers()) do
                Watch(Player)
            end
            Players.PlayerAdded:Connect(Watch)
            if not Genv.VS_AdminPoll then
                Genv.VS_AdminPoll = task.spawn(function()
                    while Genv.VS_AdminLeave do
                        for _, Player in ipairs(Players:GetPlayers()) do
                            if Player ~= LocalPlayer and Player:GetAttribute("IsAdmin") == true then
                                LeaveNow(Player.Name)
                                break
                            end
                        end
                        task.wait(1)
                    end
                    Genv.VS_AdminPoll = nil
                end)
            end
        else
            Genv.VS_AdminLeave = false
            Genv.VS_Leaving = false
        end
    end
})
LeaveToggle:Set(true)
BossCard:AddDropdown({
    Name = "Boss Room",
    Options = {"Gorilla King","Whitefang Sabertooth","Obsidian Pharaoh","Tempest Dragon King","Volcano Turtle King"},
    Default = "Gorilla King",
    Flag = "BossRoom",
    Callback = function(Value)
        local BossMap = {
            ["Gorilla King"] = "Boss01",
            ["Whitefang Sabertooth"] = "Boss02",
            ["Obsidian Pharaoh"] = "Boss03",
            ["Tempest Dragon King"] = "Boss04",
            ["Volcano Turtle King"] = "Boss05"
        }
        Genv.VS_BossRoom = BossMap[Value] or "Boss01"
    end
})
local BossRoomToggle = BossCard:AddToggle({
    Name = "Auto Boss Room",
    Default = false,
    Flag = "AutoBossRoom",
    Callback = function(Value)
        if Value then
            Genv.VS_BossFarm = Genv.VS_BossFarm or {}
            Genv.VS_BossFarm.Running = true
            Genv.VS_BossRoom = Genv.VS_BossRoom or "Boss01"
            if not Genv.VS_BossFarm.Thread then
                Genv.VS_BossFarm.Thread = task.spawn(function()
                    local Players = game:GetService("Players")
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local LocalPlayer = Players.LocalPlayer
                    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
                    local BossPositions = {
                        Boss01 = Vector3.new(0, 59.6, -906),
                        Boss02 = Vector3.new(0, 115.6, -1800),
                        Boss03 = Vector3.new(0, 171.8, -2694),
                        Boss04 = Vector3.new(0, 227.8, -3588),
                        Boss05 = Vector3.new(0, 283.4, -4480)
                    }
                    local function IsDead()
                        if LocalPlayer:GetAttribute("HuntRespawnOpen") == true then
                            return true
                        end
                        local Character = LocalPlayer.Character
                        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                        return not Humanoid or Humanoid.Health <= 0
                    end
                     local function EnsureAutoOn()
                         if LocalPlayer:GetAttribute("AutoOn") ~= true then
                             local Bindable = LocalPlayer:FindFirstChild("LumiMenuToggle")
                            if Bindable then
                                Bindable:Fire("autoToggle")
                            end
                        end
                    end
                     local CurrentRoom = nil
                     local LastCharacter = LocalPlayer.Character
                     local BossMonsterIds = {
                         Boss01 = "terra_colossus",
                         Boss02 = "bigboss_thornback_behemoth",
                         Boss03 = "bigboss_obsidian_pharaoh",
                         Boss04 = "bigboss_tempest_dragon_king",
                         Boss05 = "bigboss_volcano_turtle_king",
                     }
                     local FarmAssist = function()
                         return (Genv.VS_AutoFarm and Genv.VS_AutoFarm.Running)
                             or (Genv.VS_FieldFarm and Genv.VS_FieldFarm.Running)
                     end
                     local BossIsAlive = function(BossRoom)
                         local MonsterId = BossMonsterIds[BossRoom]
                         local Alive = MonsterId and workspace:GetAttribute("BossAlive_" .. MonsterId)
                         return Alive == true
                     end
                     Genv.VS_BossFarm.BotWasOn = LocalPlayer:GetAttribute("AutoOn") == true
                     if (Genv.VS_FarmMoveMode or "teleport") ~= "walk" or Genv.VS_BossFarm.BotWasOn then
                         Remotes.BotState:FireServer(true)
                         EnsureAutoOn()
                     end
                      while Genv.VS_BossFarm.Running do
                          if Genv.VS_ChestBusy then
                              task.wait(0.5)
                              continue
                          end
                          local AssistMode = FarmAssist()
                          local BossRoom = Genv.VS_BossRoom or "Boss01"
                          local Position = BossPositions[BossRoom] or Vector3.new(0, 50, 0)
                          if AssistMode and BossIsAlive(BossRoom) and not Genv.VS_BossPriority then
                              local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                              Genv.VS_BossReturnPosition = Root and Root.Position or nil
                              Genv.VS_BossPausedFieldFarm = Genv.VS_FieldFarm and Genv.VS_FieldFarm.Running
                              Genv.VS_BossPriority = true
                              pcall(function() Remotes.BotState:FireServer(false) end)
                              if LocalPlayer:GetAttribute("AutoOn") == true then
                                  local Bindable = LocalPlayer:FindFirstChild("LumiMenuToggle")
                                  if Bindable then Bindable:Fire("autoToggle") end
                              end
                              CurrentRoom = nil
                          elseif AssistMode and Genv.VS_BossPriority and not BossIsAlive(BossRoom) then
                              local ReturnPosition = Genv.VS_BossReturnPosition
                              Genv.VS_BossPriority = false
                              Genv.VS_BossReturnPosition = nil
                              CurrentRoom = nil
                     if ReturnPosition then
                                   local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                   if Root then
                                       local ReachedReturn
                                       if (Genv.VS_FarmMoveMode or "teleport") == "walk" then
                                           ReachedReturn = VSWalkTo(ReturnPosition, {
                                               AcceptDistance = 45,
                                               Timeout = 120,
                                               IsActive = function()
                                                   return Genv.VS_BossFarm and Genv.VS_BossFarm.Running
                                               end,
                                           })
                                       else
                                           Root.CFrame = CFrame.new(ReturnPosition)
                                           local ReturnStart = os.clock()
                                           ReachedReturn = false
                                           while os.clock() - ReturnStart < 8 do
                                               local NewRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                               if NewRoot and (NewRoot.Position - ReturnPosition).Magnitude <= 80 then
                                                   ReachedReturn = true
                                                   break
                                               end
                                               task.wait(0.2)
                                           end
                                       end
                                       if ReachedReturn then
                                           pcall(function() Remotes.BotState:FireServer(true) end)
                                          if LocalPlayer:GetAttribute("AutoOn") ~= true then
                                              local Bindable = LocalPlayer:FindFirstChild("LumiMenuToggle")
                                              if Bindable then Bindable:Fire("autoToggle") end
                                          end
                                      end
                                  end
                              end
                              task.wait(1)
                          end
                          if AssistMode and not Genv.VS_BossPriority then
                              task.wait(1)
                              continue
                          end
                          local CharacterNow = LocalPlayer.Character
                         if CharacterNow ~= LastCharacter then
                             LastCharacter = CharacterNow
                             CurrentRoom = nil
                             local ReadyStart = os.clock()
                             while Genv.VS_BossFarm.Running and os.clock() - ReadyStart < 10 do
                                 local NewCharacter = LocalPlayer.Character
                                 local NewHumanoid = NewCharacter and NewCharacter:FindFirstChildOfClass("Humanoid")
                                 local NewRoot = NewCharacter and NewCharacter:FindFirstChild("HumanoidRootPart")
                                 local RespawnBusy = LocalPlayer:GetAttribute("HuntRespawnOpen") == true
                                     or LocalPlayer:GetAttribute("HuntRespawnWaiting") == true
                                 if NewHumanoid and NewRoot and NewHumanoid.Health > 0
                                     and not NewRoot.Anchored and not RespawnBusy then
                                     task.wait(1)
                                     break
                                 end
                                 task.wait(0.2)
                             end
                         end
                         if not IsDead() then
                             local Character = LocalPlayer.Character
                            local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
                             if HumanoidRootPart then
                                  if BossRoom ~= CurrentRoom or (HumanoidRootPart.Position - Position).Magnitude > 80 then
                                      if (Genv.VS_FarmMoveMode or "teleport") == "walk" then
                                          local Reached = VSWalkTo(Position, {
                                              AcceptDistance = 45,
                                              Timeout = 180,
                                              IsActive = function()
                                                  return Genv.VS_BossFarm and Genv.VS_BossFarm.Running
                                              end,
                                          })
                                          if Reached then
                                              CurrentRoom = BossRoom
                                          else
                                              CurrentRoom = nil
                                          end
                                      else
                                          HumanoidRootPart.CFrame = CFrame.new(Position)
                                          task.wait(0.5)
                                          local NewRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                          if NewRoot and (NewRoot.Position - Position).Magnitude <= 80 then
                                              CurrentRoom = BossRoom
                                          else
                                              CurrentRoom = nil
                                          end
                                      end
                                  end
                            end
                            EnsureAutoOn()
                        end
                        task.wait(2)
                     end
                     if Genv.VS_BossPriority then
                         Genv.VS_BossPriority = false
                         Genv.VS_BossReturnPosition = nil
                         if Genv.VS_BossPausedFieldFarm and Genv.VS_FieldFarm then
                             Genv.VS_FieldFarm.Running = true
                         end
                         Genv.VS_BossPausedFieldFarm = nil
                         pcall(function() Remotes.BotState:FireServer(true) end)
                         if LocalPlayer:GetAttribute("AutoOn") ~= true then
                             local Bindable = LocalPlayer:FindFirstChild("LumiMenuToggle")
                             if Bindable then Bindable:Fire("autoToggle") end
                         end
                     end
                     Genv.VS_BossFarm.Thread = nil
                end)
            end
        else
            if Genv.VS_BossFarm then
                Genv.VS_BossFarm.Running = false
                local LocalPlayer = game:GetService("Players").LocalPlayer
                local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
                Remotes.BotState:FireServer(false)
                if LocalPlayer:GetAttribute("AutoOn") == true then
                    local Bindable = LocalPlayer:FindFirstChild("LumiMenuToggle")
                    if Bindable then
                        Bindable:Fire("autoToggle")
                    end
                end
            end
        end
    end
})
local DodgeToggle = BossCard:AddToggle({
    Name = "Auto Dodge Skill",
    Default = false,
    Flag = "AutoDodgeSkill",
    Callback = function(Value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local LocalPlayer = Players.LocalPlayer
        local BindName = "VS_AutoDodge"
        local function StopMoving()
            local Character = LocalPlayer.Character
            local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then
                Humanoid:Move(Vector3.new(0, 0, 0), false)
            end
        end
        local function CircleExit(Pos, Center, Radius)
            local Flat = Vector3.new(Pos.X - Center.X, 0, Pos.Z - Center.Z)
            if Flat.Magnitude > Radius + 4 then
                return nil
            end
            local Dir = Flat.Magnitude > 0.1 and Flat.Unit or Vector3.new(1, 0, 0)
            return Center + Dir * (Radius + 12)
        end
        local function BoxExit(Pos, BaseCF, Width, Length)
            local Rel = BaseCF:PointToObjectSpace(Pos)
            local HalfW = Width / 2
            local HalfL = Length / 2
            if math.abs(Rel.X) > HalfW + 4 or math.abs(Rel.Z) > HalfL + 4 then
                return nil
            end
            local OutX = HalfW + 12 - math.abs(Rel.X)
            local OutZ = HalfL + 12 - math.abs(Rel.Z)
            if OutX <= OutZ then
                local Sign = Rel.X >= 0 and 1 or -1
                return (BaseCF * CFrame.new(Sign * (HalfW + 12), 0, Rel.Z)).Position
            end
            local Sign = Rel.Z >= 0 and 1 or -1
            return (BaseCF * CFrame.new(Rel.X, 0, Sign * (HalfL + 12))).Position
        end
        local function ConeExit(Pos, Data)
            local Center = Data.Center
            local Dir = Data.Dir
            if typeof(Center) ~= "Vector3" or typeof(Dir) ~= "Vector3" then
                return nil
            end
            local Radius = Data.Radius or 8
            local Half = Data.Half or 1
            local DirUnit = Dir.Magnitude > 0 and Dir.Unit or Vector3.new(0, 0, 1)
            local ToPlayer = Pos - Center
            local Dist = ToPlayer.Magnitude
            if Dist > Radius + 4 then
                return nil
            end
            local Angle = Dist > 0.1 and math.acos(math.clamp(ToPlayer.Unit:Dot(DirUnit), -1, 1)) or 0
            if Angle > Half + 0.1 then
                return nil
            end
            local Back = Vector3.new(-DirUnit.X, 0, -DirUnit.Z)
            if Back.Magnitude < 0.1 then
                Back = Vector3.new(1, 0, 0)
            end
            return Pos + Back.Unit * 20
        end
        local function BestTarget(Pos, Entries)
            local SafeTarget, SafeDist = nil, math.huge
            local ExitTarget, ExitDist = nil, math.huge
            for _, Entry in ipairs(Entries) do
                local Data = Entry.Data
                if Data then
                    if Data.Safe then
                        local Center = Data.Center
                        if not Center and typeof(Data.CFrame) == "CFrame" then
                            Center = Data.CFrame.Position
                        end
                        if Center then
                            local Dist = (Vector3.new(Center.X, 0, Center.Z) - Vector3.new(Pos.X, 0, Pos.Z)).Magnitude
                            if Dist < SafeDist then
                                SafeDist = Dist
                                SafeTarget = Center
                            end
                        end
                    else
                        local Point = nil
                        if type(Data.Inner) == "number" then
                            local Center = Data.Center
                            if not Center and typeof(Data.CFrame) == "CFrame" then
                                Center = Data.CFrame.Position
                            end
                            if Center then
                                local Dist = (Vector3.new(Center.X, 0, Center.Z) - Vector3.new(Pos.X, 0, Pos.Z)).Magnitude
                                local Outer = Data.Radius or 8
                                if Dist >= (Data.Inner - 4) and Dist <= (Outer + 4) then
                                    Point = Center
                                end
                            end
                        elseif typeof(Data.Center) == "Vector3" and typeof(Data.Dir) == "Vector3" and type(Data.Half) == "number" then
                            Point = ConeExit(Pos, Data)
                        elseif typeof(Data.Center) == "Vector3" then
                            Point = CircleExit(Pos, Data.Center, Data.Radius or 8)
                        elseif typeof(Data.CFrame) == "CFrame" then
                            Point = BoxExit(Pos, Data.CFrame, Data.Width or 10, Data.Length or 10)
                        end
                        if Point then
                            local Dist = (Point - Pos).Magnitude
                            if Dist < ExitDist then
                                ExitDist = Dist
                                ExitTarget = Point
                            end
                        end
                    end
                end
            end
            if SafeTarget then
                return SafeTarget
            end
            return ExitTarget
        end
        local function OnRender()
            if not Genv.VS_DodgeEnabled then
                return
            end
            local Queue = Genv.VS_DodgeQueue
            if not Queue or #Queue == 0 then
                return
            end
            local Character = LocalPlayer.Character
            local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
            if not Humanoid or not HumanoidRootPart or Humanoid.Health <= 0 then
                return
            end
            local Now = os.clock()
            for Index = #Queue, 1, -1 do
                if Now > Queue[Index].HitAt then
                    table.remove(Queue, Index)
                end
            end
            if #Queue == 0 then
                return
            end
            local Target = BestTarget(HumanoidRootPart.Position, Queue)
            if not Target then
                return
            end
            local Pos = HumanoidRootPart.Position
            local Flat = Vector3.new(Target.X - Pos.X, 0, Target.Z - Pos.Z)
            if Flat.Magnitude < 3 then
                Humanoid:Move(Vector3.new(0, 0, 0), false)
                return
            end
            Humanoid:Move(Flat.Unit, false)
        end
        if Value then
            Genv.VS_DodgeEnabled = true
            Genv.VS_DodgeQueue = {}
            if not Genv.VS_DodgeHooked then
                Genv.VS_DodgeHooked = true
                local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
                local BossFx = Remotes:WaitForChild("BossFx")
                Genv.VS_DodgeConn = BossFx.OnClientEvent:Connect(function(Action, A2, A3, Zones, WarnTime)
                    if not Genv.VS_DodgeEnabled then
                        return
                    end
                    if type(Zones) ~= "table" then
                        return
                    end
                    local Queue = Genv.VS_DodgeQueue
                    if not Queue then
                        return
                    end
                    if Action == "cancel" then
                        for i = #Queue, 1, -1 do
                            table.remove(Queue, i)
                        end
                        return
                    end
                    if Action ~= "warn" then
                        return
                    end
                    local Time = tonumber(WarnTime) or 1.5
                    if Time <= 0 then
                        Time = 1.5
                    end
                    local Character = LocalPlayer.Character
                    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
                    local Pos = HRP and HRP.Position
                    for _, Zone in ipairs(Zones) do
                        if type(Zone) == "table" then
                            local Center = Zone.Center
                            if not Center and typeof(Zone.CFrame) == "CFrame" then
                                Center = Zone.CFrame.Position
                            end
                            local Near = true
                            if Pos and Center then
                                if (Center - Pos).Magnitude > 200 then
                                    Near = false
                                end
                            end
                            if Near then
                                table.insert(Queue, { Data = Zone, HitAt = os.clock() + Time })
                            end
                        end
                    end
                end)
            end
            pcall(function()
                RunService:UnbindFromRenderStep(BindName)
            end)
RunService:BindToRenderStep(BindName, Enum.RenderPriority.Last.Value + 100, OnRender)
            Genv.VS_DodgeBound = true
        else
            Genv.VS_DodgeEnabled = false
            Genv.VS_DodgeQueue = {}
            if Genv.VS_DodgeBound then
                Genv.VS_DodgeBound = false
                pcall(function()
                    RunService:UnbindFromRenderStep(BindName)
                end)
            end
            StopMoving()
        end
    end
})
local function VSGetRemotes()
    return game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
end
VSPauseBot = function()
    local Player = game:GetService("Players").LocalPlayer
    pcall(function()
        VSGetRemotes().BotState:FireServer(false)
    end)
    if Player:GetAttribute("AutoOn") == true then
        local Bindable = Player:FindFirstChild("LumiMenuToggle")
        if Bindable then
            Bindable:Fire("autoToggle")
        end
    end
end
VSResumeBot = function()
    local Player = game:GetService("Players").LocalPlayer
    pcall(function()
        VSGetRemotes().BotState:FireServer(true)
    end)
    if Player:GetAttribute("AutoOn") ~= true then
        local Bindable = Player:FindFirstChild("LumiMenuToggle")
        if Bindable then
            Bindable:Fire("autoToggle")
        end
    end
end
VSWalkTo = function(Position, Options)
    Options = Options or {}
    local SkipPillar = Options.SkipPillar or false
    if typeof(Position) ~= "Vector3" then
        return false, "invalid target"
    end

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local PathfindingService = game:GetService("PathfindingService")
    local CollectionService = game:GetService("CollectionService")
    local Player = Players.LocalPlayer

    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local Root = Character and Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not Root or Humanoid.Health <= 0 then
        return false, "dead or not ready"
    end

    local IsActive = Options.IsActive or function()
        return true
    end

    -- AcceptDistance is a tolerance, not a distance to stop early at:
    -- 45 is the caller's legacy value, the walker still needs a real arrival.
    -- 5 is used by Auto Collect Chest, which needs to stand inside the
    -- ProximityPrompt range measured for LootBoxes.
    local AcceptDistance = math.clamp(tonumber(Options.AcceptDistance) or 10, 4, 45)

    -- VSWalkTo drives a single shared render step ("VS_FarmWalk"), so two
    -- callers walking at once would unbind each other. Only one walk runs;
    -- the other caller is told to retry instead of silently breaking both.
    if Genv.VS_WalkBusy and os.clock() - (Genv.VS_WalkBusyAt or 0) < 600 then
        return false, "walker busy"
    end

    -- Values measured in this game, not guessed:
    --   flat ground speed 19.5 studs/s, ramp speed ~17.8 studs/s
    --   PathfindingService has no navmesh on Bridge.Ramp inclines (NoPath),
    --   so a path is only requested when a real wall blocks the straight line.
    local WALK_SPEED = 19.5
    local AGENT = {
        AgentRadius = 2.5,
        AgentHeight = 5,
        AgentCanJump = false,
        WaypointSpacing = 8,
    }
    local BIND_NAME = "VS_FarmWalk"
    local ZERO = Vector3.new(0, 0, 0)
    local WALL_NORMAL_Y = 0.6
    local NO_PROGRESS_LIMIT = 12
    local REPLAN_INTERVAL = 0.8
    local WAYPOINT_REACHED = 5
    local CENTER_THRESHOLD = 1.5

    local StartPosition = Root.Position
    local StartFlat = Vector3.new(StartPosition.X, 0, StartPosition.Z)
    local GoalFlat = Vector3.new(Position.X, 0, Position.Z)
    local TotalDistance = (GoalFlat - StartFlat).Magnitude

    local Timeout = math.clamp(TotalDistance / WALK_SPEED * 2 + 20, 20, 420)
    local CallerTimeout = tonumber(Options.Timeout)
    if CallerTimeout and CallerTimeout > Timeout then
        Timeout = math.min(CallerTimeout, 600)
    end

    local WasAutoOn = Player:GetAttribute("AutoOn") == true

    -- Already standing on the spot: return before pausing the bot so it is
    -- never interrupted when the farm loop re-targets the same field.
    if TotalDistance <= AcceptDistance
        and (math.abs(Position.Y - StartPosition.Y) <= 20 or TotalDistance <= 4) then
        return true, "already there"
    end

    -- Warp Pillar integration: if a pillar would save significant distance,
    -- walk to the nearest pillar, warp, then walk to the goal.
    if not SkipPillar and TotalDistance > 200 and math.abs(Position.X) <= 5 then
        local PillarPositions = {
            Town   = Vector3.new(22, 2, 71),
            Boss01 = Vector3.new(19, 58, -799),
            Boss02 = Vector3.new(19, 114, -1693),
            Boss03 = Vector3.new(19, 170, -2587),
            Boss04 = Vector3.new(19, 226, -3481),
            Boss05 = Vector3.new(19, 281, -4373),
        }
        local function isUnlocked(name)
            local attr = Player:GetAttribute("WarpPillars") or ""
            return attr:find(name, 1, true) ~= nil
        end
        local function nearestPillar(pos)
            local best, bestDist = nil, math.huge
            for name, ppos in pairs(PillarPositions) do
                if isUnlocked(name) then
                    local d = (ppos - pos).Magnitude
                    if d < bestDist then bestDist = d; best = name end
                end
            end
            return best, bestDist
        end
        local function closestPillarToGoal(goal)
            local best, bestDist = nil, math.huge
            for name, ppos in pairs(PillarPositions) do
                if isUnlocked(name) then
                    local d = math.abs(ppos.Z - goal.Z)
                    if d < bestDist then bestDist = d; best = name end
                end
            end
            return best
        end

        local nearPillar, nearDist = nearestPillar(StartPosition)
        local destPillar = closestPillarToGoal(Position)

        -- Only use pillar if: different pillars, pillar is in direction of travel,
        -- and saves at least 30% distance
        if nearPillar and destPillar and nearPillar ~= destPillar then
            local inDirection = (Position.Z - StartPosition.Z) * (PillarPositions[destPillar].Z - StartPosition.Z) > 0
            local pillarDist = (PillarPositions[nearPillar] - StartPosition).Magnitude
                + (PillarPositions[destPillar] - Position).Magnitude
            local directDist = TotalDistance
            if inDirection and pillarDist < directDist * 0.7 then
                -- Reach a pillar in three natural phases: center first, travel
                -- along the lane to the pillar's Z, then step out to the pillar.
                -- A pillar sits at X≈19/22, so targeting it directly would bypass
                -- the normal center-first rule and cut diagonally across the lane.
                local PillarPosition = PillarPositions[nearPillar]
                local CenterApproach = Vector3.new(0, StartPosition.Y, PillarPosition.Z)
                local centered = VSWalkTo(CenterApproach, {
                    AcceptDistance = 6,
                    Timeout = 90,
                    IsActive = Options.IsActive or function() return true end,
                    SkipPillar = true,
                    SkipBotResume = true,
                })
                local r1 = centered and VSWalkTo(PillarPosition, {
                    AcceptDistance = 6,
                    Timeout = 60,
                    IsActive = Options.IsActive or function() return true end,
                    SkipPillar = true,
                    SkipBotResume = true,
                })
                if r1 then
                    -- Wait a moment for cleanup to settle before warp
                    task.wait(1)
                    -- Warp to dest pillar
                    local rem = VSGetRemotes()
                    local beforeWarp = (Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character.HumanoidRootPart.Position) or StartPosition
                    rem.PillarWarp:FireServer(destPillar)
                    task.wait(3)
                    local afterWarp = (Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character.HumanoidRootPart.Position) or beforeWarp
                    local warped = (beforeWarp - afterWarp).Magnitude > 10
                    if warped then
                        -- Walk to goal (SkipPillar to avoid recursion)
                        return VSWalkTo(Position, {
                            AcceptDistance = Options.AcceptDistance,
                            Timeout = Options.Timeout,
                            IsActive = Options.IsActive,
                            SkipPillar = true,
                        })
                    end
                end
            end
        end
    end

    local ProbeParams = RaycastParams.new()
    ProbeParams.FilterType = Enum.RaycastFilterType.Exclude
    ProbeParams.FilterDescendantsInstances = { Character }
    ProbeParams.IgnoreWater = true

    -- Shared with the render step; the closure is created once.
    local State = {
        Humanoid = Humanoid,
        Root = Root,
        Target = nil,
        Running = true,
    }

    pcall(function()
        RunService:UnbindFromRenderStep(BIND_NAME)
    end)
    RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Last.Value + 50, function()
        if not State.Running then
            return
        end
        local CurrentHumanoid = State.Humanoid
        local CurrentRoot = State.Root
        if not CurrentHumanoid or not CurrentHumanoid.Parent or CurrentHumanoid.Health <= 0 then
            return
        end
        if not CurrentRoot or not CurrentRoot.Parent then
            return
        end
        local Target = State.Target
        if not Target then
            CurrentHumanoid:Move(ZERO, false)
            return
        end
        local Delta = Target - CurrentRoot.Position
        Delta = Vector3.new(Delta.X, 0, Delta.Z)
        if Delta.Magnitude > 0.2 then
            CurrentHumanoid:Move(Delta.Unit, false)
        else
            CurrentHumanoid:Move(ZERO, false)
        end
    end)

    local Waypoints = nil
    local WaypointIndex = 1
    local PlanToken = 0
    local LastPlanAt = 0
    local Planning = false
    local PlanningSince = 0
    local BestDistance = TotalDistance
    local LastImproveAt = os.clock()
    local StuckStage = 0
    local OverrideTarget = nil
    local OverrideUntil = 0
    local SamplePosition = Root.Position
    local BestCenterDistance = math.abs(Root.Position.X)
    local WasCentering = false

    local function IsWallAhead(FromPosition, TowardPosition)
        local Delta = Vector3.new(TowardPosition.X - FromPosition.X, 0, TowardPosition.Z - FromPosition.Z)
        local Length = math.min(Delta.Magnitude, 26)
        if Length < 1.5 then
            return false
        end
        local Hit = workspace:Raycast(FromPosition + Vector3.new(0, 1.5, 0), Delta.Unit * Length, ProbeParams)
        if not Hit then
            return false
        end
        -- BossLock_* / Barrier parts are invisible walls that only block when
        -- CanCollide is true; a decorative part must not trigger a detour.
        if not Hit.Instance.CanCollide then
            return false
        end
        -- A ramp surface has normal.Y = 0.894, a wall has ~0.
        return Hit.Normal.Y < WALL_NORMAL_Y
    end

    local function StartPlan(FromPosition, PlanTarget)
        PlanTarget = PlanTarget or Position
        local Now = os.clock()
        -- Planning is cleared by the task itself; the timeout only exists so a
        -- task that dies mid-flight cannot block every future detour.
        if Planning and Now - PlanningSince > 3 then
            Planning = false
        end
        if Planning or Now - LastPlanAt < REPLAN_INTERVAL then
            return
        end
        LastPlanAt = Now
        Planning = true
        PlanningSince = Now

        -- Aim the path at a point a short way along the line of travel instead
        -- of at the final goal. The goal can sit on the far side of a ramp or a
        -- bridge islet where the navmesh has a hole, which turns every detour
        -- into NoPath. A nearby point is usually on the same navmesh island, so
        -- the detour works and the walker rejoins the straight line afterwards.
        local PlanTargetFlat = Vector3.new(PlanTarget.X, 0, PlanTarget.Z)
        local FromFlat = Vector3.new(FromPosition.X, 0, FromPosition.Z)
        local Offset = PlanTargetFlat - FromFlat
        local Remaining = Offset.Magnitude

        -- During centering the target is close (<=16 studs), so skip the hop
        -- ladder and just request a direct path.
        local Candidates = {}
        if Remaining > 20 then
            for _, Distance in ipairs({ 120, 84, 56, 32 }) do
                if Distance < Remaining - 1 then
                    Candidates[#Candidates + 1] = Distance
                end
            end
        end
        Candidates[#Candidates + 1] = Remaining

        PlanToken = PlanToken + 1
        local Token = PlanToken
        local From = FromPosition
        task.spawn(function()
            local Path = PathfindingService:CreatePath(AGENT)
            for _, Distance in ipairs(Candidates) do
                if Token ~= PlanToken or not State.Running then
                    break
                end
                local Target
                if Distance >= Remaining - 1 then
                    Target = PlanTarget
                else
                    local Ahead = FromFlat + Offset.Unit * Distance
                    local Ground = workspace:Raycast(
                        Vector3.new(Ahead.X, FromPosition.Y + 30, Ahead.Z),
                        Vector3.new(0, -80, 0),
                        ProbeParams
                    )
                    local GroundY = Ground and Ground.Position.Y or (FromPosition.Y - 3)
                    Target = Vector3.new(Ahead.X, GroundY + 3, Ahead.Z)
                end
                pcall(function()
                    Path:ComputeAsync(From, Target)
                end)
                if Token ~= PlanToken or not State.Running then
                    break
                end
                if Path.Status == Enum.PathStatus.Success then
                    break
                end
            end
            Planning = false
            if Token ~= PlanToken or not State.Running then
                return
            end
            if Path.Status ~= Enum.PathStatus.Success then
                Waypoints = nil
                WaypointIndex = 1
                return
            end
            local List = Path:GetWaypoints()
            local Index = 1
            while List[Index] do
                local WaypointFlat = Vector3.new(List[Index].Position.X, 0, List[Index].Position.Z)
                local SelfFlat = Vector3.new(From.X, 0, From.Z)
                if (WaypointFlat - SelfFlat).Magnitude > 4 then
                    break
                end
                Index = Index + 1
            end
            if List[Index] then
                Waypoints = List
                WaypointIndex = Index
            else
                Waypoints = nil
                WaypointIndex = 1
            end
        end)
    end
    local function FindLockedGate(CurrentPosition)
        -- Verified in game: the real barriers are Map.Barriers parts tagged
        -- "BossLock" (45x12.9x1.2 at every ramp). GateLockClient sets
        -- CanCollide = not unlocked, so a locked one is a genuine wall.
        local Tagged = CollectionService:GetTagged("BossLock")
        for _, Part in ipairs(Tagged) do
            if Part:IsA("BasePart") and Part.CanCollide then
                if math.abs(Part.Position.Z - CurrentPosition.Z) < 40 then
                    return Part.Name
                end
            end
        end
        return nil
    end

    local function Sidestep(Distance)
        local CurrentRoot = State.Root
        if not CurrentRoot or not CurrentRoot.Parent then
            return
        end
        local CurrentPosition = CurrentRoot.Position
        local Origin = CurrentPosition + Vector3.new(0, 1.5, 0)
        local RightHit = workspace:Raycast(Origin, Vector3.new(Distance, 0, 0), ProbeParams)
        local LeftHit = workspace:Raycast(Origin, Vector3.new(-Distance, 0, 0), ProbeParams)
        local Sign
        if RightHit and not LeftHit then
            Sign = -1
        elseif LeftHit and not RightHit then
            Sign = 1
        elseif RightHit and LeftHit then
            Sign = (RightHit.Distance >= LeftHit.Distance) and 1 or -1
        else
            Sign = 1
        end
        OverrideTarget = Vector3.new(CurrentPosition.X + Sign * Distance, CurrentPosition.Y, CurrentPosition.Z)
        OverrideUntil = os.clock() + 0.6
        Waypoints = nil
        WaypointIndex = 1
    end

    VSPauseBot()
    Genv.VS_WalkBusy = true
    Genv.VS_WalkBusyAt = os.clock()
    task.wait(0.1)

    local StartedAt = os.clock()
    local Reached = false
    local Reason = "stopped"

    while os.clock() - StartedAt < Timeout do
        if not IsActive() then
            Reason = "cancelled"
            break
        end

        Character = Player.Character
        Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        local CurrentRoot = Character and Character:FindFirstChild("HumanoidRootPart")
        if not Humanoid or not CurrentRoot or Humanoid.Health <= 0 then
            Reason = "dead or not ready"
            break
        end

        local RootPosition = CurrentRoot.Position

        if Humanoid ~= State.Humanoid or CurrentRoot ~= State.Root then
            State.Humanoid = Humanoid
            State.Root = CurrentRoot
            ProbeParams.FilterDescendantsInstances = { Character }
            Waypoints = nil
            WaypointIndex = 1
            PlanToken = PlanToken + 1
            SamplePosition = RootPosition
            BestDistance = (GoalFlat - Vector3.new(RootPosition.X, 0, RootPosition.Z)).Magnitude
            BestCenterDistance = math.abs(RootPosition.X)
            LastImproveAt = os.clock()
            StuckStage = 0
            WasCentering = false
            OverrideTarget = nil
        end

        local SelfFlat = Vector3.new(RootPosition.X, 0, RootPosition.Z)
        local Distance = (GoalFlat - SelfFlat).Magnitude
        local HeightGap = math.abs(Position.Y - RootPosition.Y)

        if Distance <= AcceptDistance and (HeightGap <= 20 or Distance <= 4) then
            Reached = true
            Reason = "reached"
            break
        end

        local Now = os.clock()
        local IsCentering = math.abs(RootPosition.X) > CENTER_THRESHOLD and math.abs(Position.X) <= 5
        if IsCentering then
            if not WasCentering then
                BestCenterDistance = math.abs(RootPosition.X)
                WasCentering = true
            end
            local CenterDist = math.abs(RootPosition.X)
            if CenterDist < BestCenterDistance - 0.5 then
                BestCenterDistance = CenterDist
                LastImproveAt = Now
                StuckStage = 0
            end
        else
            if WasCentering then
                BestDistance = Distance
                StuckStage = 0
            end
            WasCentering = false
            if Distance < BestDistance - 2 then
                BestDistance = Distance
                LastImproveAt = Now
                StuckStage = 0
            end
        end
        if (RootPosition - SamplePosition).Magnitude > 0.6 then
            SamplePosition = RootPosition
        end

        local SinceImprove = Now - LastImproveAt
        if SinceImprove > NO_PROGRESS_LIMIT then
            local GateName = FindLockedGate(RootPosition)
            Reason = GateName and ("gate locked: " .. GateName)
                or string.format(
                    "stuck %.1fs at %.0f,%.0f,%.0f",
                    SinceImprove,
                    RootPosition.X,
                    RootPosition.Y,
                    RootPosition.Z
                )
            break
        elseif SinceImprove > 4 and StuckStage < 2 then
            StuckStage = 2
            if IsCentering then
                PlanToken = PlanToken + 1
                StartPlan(RootPosition, Vector3.new(0, RootPosition.Y, RootPosition.Z))
            else
                Sidestep(8)
                PlanToken = PlanToken + 1
                StartPlan(RootPosition)
            end
        elseif SinceImprove > 1.2 and StuckStage < 1 then
            StuckStage = 1
            if not IsCentering then
                Sidestep(4)
            end
        end

        local MoveTarget = nil
        if OverrideTarget and Now < OverrideUntil then
            MoveTarget = OverrideTarget
        elseif math.abs(RootPosition.X) > CENTER_THRESHOLD and math.abs(Position.X) <= 5 then
            -- Phase 1: center on x=0 first (walk laterally to center line)
            OverrideTarget = nil
            local CenterTarget = Vector3.new(0, RootPosition.Y, RootPosition.Z)
            local Waypoint = Waypoints and Waypoints[WaypointIndex]
            while Waypoint do
                local WaypointFlat = Vector3.new(Waypoint.Position.X, 0, Waypoint.Position.Z)
                if (WaypointFlat - SelfFlat).Magnitude <= WAYPOINT_REACHED then
                    WaypointIndex = WaypointIndex + 1
                    Waypoint = Waypoints[WaypointIndex]
                else
                    break
                end
            end
            if Waypoint then
                MoveTarget = Waypoint.Position
            else
                Waypoints = nil
                MoveTarget = CenterTarget
                if IsWallAhead(RootPosition, CenterTarget) then
                    StartPlan(RootPosition, CenterTarget)
                end
            end
        else
            OverrideTarget = nil
            local Waypoint = Waypoints and Waypoints[WaypointIndex]
            while Waypoint do
                local WaypointFlat = Vector3.new(Waypoint.Position.X, 0, Waypoint.Position.Z)
                if (WaypointFlat - SelfFlat).Magnitude <= WAYPOINT_REACHED then
                    WaypointIndex = WaypointIndex + 1
                    Waypoint = Waypoints[WaypointIndex]
                else
                    break
                end
            end
            if Waypoint then
                MoveTarget = Waypoint.Position
            else
                Waypoints = nil
                MoveTarget = Position
                if Distance > 14 and IsWallAhead(RootPosition, Position) then
                    StartPlan(RootPosition)
                end
            end
        end

        State.Target = MoveTarget
        task.wait(0.1)
    end

    State.Running = false
    State.Target = nil
    Genv.VS_WalkBusy = false
    Genv.VS_WalkBusyAt = nil
    PlanToken = PlanToken + 1
    pcall(function()
        RunService:UnbindFromRenderStep(BIND_NAME)
    end)

    local FinalCharacter = Player.Character
    local FinalHumanoid = FinalCharacter and FinalCharacter:FindFirstChildOfClass("Humanoid")
    if FinalHumanoid then
        pcall(function()
            FinalHumanoid:Move(ZERO, false)
        end)
    end
    -- Walk mode pauses the bot so it cannot fight the walker for movement.
    -- Once we stand on the farm spot the bot must come back even if the player
    -- had it off before the walk started, otherwise nothing gets farmed.
    if IsActive() and (Reached or WasAutoOn) and not (Options and Options.SkipBotResume) then
        pcall(VSResumeBot)
    end

    return Reached, Reason
end
Genv.VS_FarmMoveMode = Genv.VS_FarmMoveMode or "teleport"
FarmCard:AddDropdown({
    Name = "Farm Mode",
    Options = { "Walk", "Teleport" },
    Default = "Teleport",
    Flag = "FarmMoveMode",
    Callback = function(Value)
        Genv.VS_FarmMoveMode = Value == "Walk" and "walk" or "teleport"
    end
})
FarmCard:AddToggle({
    Name = "Auto Farm Level 1-99",
    Default = false,
    Flag = "AutoFarmLevel",
    Callback = function(Value)
        if Value then
            Genv.VS_AutoFarm = Genv.VS_AutoFarm or {}
            Genv.VS_AutoFarm.Generation = (Genv.VS_AutoFarm.Generation or 0) + 1
            Genv.VS_AutoFarm.Running = true
            local StartPlayer = game:GetService("Players").LocalPlayer
             local StartRemotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
             Genv.VS_AutoFarm.BotWasOn = StartPlayer:GetAttribute("AutoOn") == true
             if (Genv.VS_FarmMoveMode or "teleport") ~= "walk" then
                 StartRemotes.BotState:FireServer(true)
             end
             if (Genv.VS_FarmMoveMode or "teleport") ~= "walk" and StartPlayer:GetAttribute("AutoOn") ~= true then
                 local StartBindable = StartPlayer:FindFirstChild("LumiMenuToggle")
                 if StartBindable then
                    StartBindable:Fire("autoToggle")
                end
            end
            if not Genv.VS_AutoFarm.Thread then
                Genv.VS_AutoFarm.Thread = task.spawn(function()
                    local ThreadGeneration = Genv.VS_AutoFarm.Generation
                    local Players = game:GetService("Players")
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local HttpService = game:GetService("HttpService")
                    local LocalPlayer = Players.LocalPlayer
                    local RunService = game:GetService("RunService")
                    local CollectionService = game:GetService("CollectionService")
                    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
                    local SetTarget = Remotes:WaitForChild("SetTarget")
                    local FieldPositions = {
                        Field01 = Vector3.new(0, 3.6, -203),
                        Field02 = Vector3.new(0, 31.6, -459),
                        Field03 = Vector3.new(0, 59.6, -715),
                        Field04 = Vector3.new(0, 59.8, -1097),
                        Field05 = Vector3.new(0, 87.8, -1353),
                        Field06 = Vector3.new(0, 115.8, -1609),
                        Field07 = Vector3.new(0, 115.9, -1991),
                        Field08 = Vector3.new(0, 143.9, -2247),
                        Field09 = Vector3.new(0, 171.9, -2503),
                        Field10 = Vector3.new(0, 171.7, -2885),
                        Field11 = Vector3.new(0, 199.7, -3141),
                        Field12 = Vector3.new(0, 227.7, -3397),
                        Field13 = Vector3.new(0, 227.2, -3778),
                        Field14 = Vector3.new(0, 255.2, -4034),
                        Field15 = Vector3.new(0, 283.2, -4290)
                    }
                    local function GetLevel()
                        return LocalPlayer:GetAttribute("Level") or 1
                    end
                    local BossGateMap = {
                        Field04 = "Boss01",
                        Field07 = "Boss02",
                        Field10 = "Boss03",
                        Field13 = "Boss04",
                    }
                    local BossPositions = {
                        Boss01 = Vector3.new(0, 59.6, -906),
                        Boss02 = Vector3.new(0, 115.6, -1800),
                        Boss03 = Vector3.new(0, 171.8, -2694),
                        Boss04 = Vector3.new(0, 227.8, -3588),
                    }
                    local FieldOrder = {"Field01","Field02","Field03","Field04","Field05","Field06",
                                       "Field07","Field08","Field09","Field10","Field11","Field12",
                                       "Field13","Field14","Field15"}
                    local function IsFieldUnlocked(Name)
                        local Gates = {}
                        pcall(function()
                            Gates = HttpService:JSONDecode(LocalPlayer:GetAttribute("BossGatesJson") or "{}")
                        end)
                        local BossId = BossGateMap[Name]
                        if BossId and Gates[BossId] ~= true then
                            return false
                        end
                        return true
                    end
                    local function GetBossForField(Field)
                        return BossGateMap[Field]
                    end
                    local BossMonsterId = {
                        Boss01 = "terra_colossus",
                        Boss02 = "bigboss_thornback_behemoth",
                        Boss03 = "bigboss_obsidian_pharaoh",
                        Boss04 = "bigboss_tempest_dragon_king",
                        Boss05 = "bigboss_volcano_turtle_king",
                    }
                    local BOSS_APPROACH_SECONDS = 120
                    local BOSS_WAIT_MAX = 180
                    local function IsBossAlive(BossId)
                        local MonsterId = BossMonsterId[BossId]
                        if not MonsterId then
                            return false
                        end
                        local Flag = workspace:GetAttribute("BossAlive_" .. MonsterId)
                        if type(Flag) == "boolean" then
                            return Flag
                        end
                        for _, v in ipairs(CollectionService:GetTagged("Monster")) do
                            if v:GetAttribute("MonsterId") == MonsterId and (tonumber(v:GetAttribute("HP")) or 1) > 0 then
                                return true
                            end
                        end
                        return false
                    end
                    local function GetFieldByLevel(Level)
                        if Level <= 8 then return "Field01"
                        elseif Level <= 16 then return "Field02"
                        elseif Level <= 25 then return "Field03"
                        elseif Level <= 33 then return "Field04"
                        elseif Level <= 41 then return "Field05"
                        elseif Level <= 50 then return "Field06"
                        elseif Level <= 58 then return "Field07"
                        elseif Level <= 66 then return "Field08"
                        elseif Level <= 75 then return "Field09"
                        elseif Level <= 83 then return "Field10"
                        elseif Level <= 91 then return "Field11"
                        elseif Level < 99 then return "Field12"
                        else
                            return "Field13"
                        end
                    end
                    local function GetUnlockedField(Level)
                        local Candidate = GetFieldByLevel(Level)
                        if IsFieldUnlocked(Candidate) then
                            return Candidate, nil
                        end
                        local BossId = GetBossForField(Candidate)
                        if BossId then
                            return Candidate, BossId
                        end
                        local Index = table.find(FieldOrder, Candidate) or 1
                        while Index > 1 and not IsFieldUnlocked(FieldOrder[Index]) do
                            Index = Index - 1
                        end
                        return FieldOrder[Index], nil
                    end
                    local function GetFieldPosition(Name)
                        local Zones = workspace:FindFirstChild("Zones")
                        if Zones then
                            local Zone = Zones:FindFirstChild(Name)
                            if Zone then
                                return Zone.Position + Vector3.new(0, 5, 0)
                            end
                        end
                        return FieldPositions[Name] or Vector3.new(0, 50, 0)
                    end
                    local function TeleportNow(Position)
                        local Character = LocalPlayer.Character
                        local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
                        if HumanoidRootPart then
                            HumanoidRootPart.CFrame = CFrame.new(Position)
                        end
                    end
                     local function EnsureAutoOn()
                         if LocalPlayer:GetAttribute("AutoOn") ~= true then
                            local Bindable = LocalPlayer:FindFirstChild("LumiMenuToggle")
                            if Bindable then
                                Bindable:Fire("autoToggle")
                            end
                        end
                    end
                    local function PauseBot()
                        VSPauseBot()
                    end
                    local function ResumeBot()
                        VSResumeBot()
                    end
                     local function WarpTo(Position)
                         if not Position then
                             return
                         end
                         if (Genv.VS_FarmMoveMode or "teleport") == "walk" then
                             local Reached, Reason = VSWalkTo(Position, {
                                 AcceptDistance = 45,
                                 Timeout = 240,
                                 IsActive = function()
                                     return Genv.VS_AutoFarm
                                         and Genv.VS_AutoFarm.Running
                                         and Genv.VS_AutoFarm.Generation == ThreadGeneration
                                 end,
                             })
                             Genv.VS_AutoFarm.RewarpRequired = not Reached
                             return Reached, Reason
                         end
                         PauseBot()
                        task.wait(0.1)
                        TeleportNow(Position)
                        local ReadyStart = os.clock()
                        while os.clock() - ReadyStart < 8 do
                            local NewCharacter = LocalPlayer.Character
                            local NewRoot = NewCharacter and NewCharacter:FindFirstChild("HumanoidRootPart")
                            local Params = RaycastParams.new()
                            Params.FilterType = Enum.RaycastFilterType.Exclude
                            Params.FilterDescendantsInstances = {NewCharacter}
                            local Ground = NewRoot and workspace:Raycast(
                                NewRoot.Position + Vector3.new(0, 2, 0),
                                Vector3.new(0, -20, 0),
                                Params
                            )
                            if NewRoot and Ground and not NewRoot.Anchored then
                                break
                            end
                            task.wait(0.2)
                        end
                        local FinalCharacter = LocalPlayer.Character
                        local FinalRoot = FinalCharacter and FinalCharacter:FindFirstChild("HumanoidRootPart")
                        local Reached = FinalRoot and (FinalRoot.Position - Position).Magnitude <= 80
                        Genv.VS_AutoFarm.RewarpRequired = not Reached
                        if Reached
                            and Genv.VS_AutoFarm.Running
                            and Genv.VS_AutoFarm.Generation == ThreadGeneration then
                            ResumeBot()
                        end
                        return Reached
                    end
                    local function GetBossRespawnLeft(BossId)
                        local MonsterId = BossMonsterId[BossId]
                        if not MonsterId then
                            return nil
                        end
                        local NextSpawn = workspace:GetAttribute("BossNext_" .. MonsterId)
                        if type(NextSpawn) ~= "number" then
                            return nil
                        end
                        return NextSpawn - os.time()
                    end
                    local function IsDead()
                        if LocalPlayer:GetAttribute("HuntRespawnOpen") == true then
                            return true
                        end
                        local Character = LocalPlayer.Character
                        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                        return not Humanoid or Humanoid.Health <= 0
                    end
                     local CurrentField = nil
                     local LastCharacter = LocalPlayer.Character
                    local BossFailCooldown = {}
                    while Genv.VS_AutoFarm.Running and Genv.VS_AutoFarm.Generation == ThreadGeneration do
                        if Genv.VS_ShopBusy or Genv.VS_ChestBusy then
                            task.wait(1)
                            continue
                        end
                        if Genv.VS_BossPriority then
                            task.wait(1)
                            continue
                        end
                        if Genv.VS_AutoFarm.RewarpRequired then
                            CurrentField = nil
                            Genv.VS_AutoFarm.RewarpRequired = false
                        end
                        local Character = LocalPlayer.Character
                        if Character ~= LastCharacter then
                            LastCharacter = Character
                            CurrentField = nil
                            local ReadyStart = os.clock()
                            while Genv.VS_AutoFarm.Running
                                and Genv.VS_AutoFarm.Generation == ThreadGeneration
                                and os.clock() - ReadyStart < 10 do
                                local NewCharacter = LocalPlayer.Character
                                local NewHumanoid = NewCharacter and NewCharacter:FindFirstChildOfClass("Humanoid")
                                local NewRoot = NewCharacter and NewCharacter:FindFirstChild("HumanoidRootPart")
                                local RespawnBusy = LocalPlayer:GetAttribute("HuntRespawnOpen") == true
                                    or LocalPlayer:GetAttribute("HuntRespawnWaiting") == true
                                if NewHumanoid and NewRoot and NewHumanoid.Health > 0
                                    and not NewRoot.Anchored and not RespawnBusy then
                                    task.wait(1)
                                    break
                                end
                                task.wait(0.2)
                            end
                        end
                        if not IsDead() then
                            local Level = GetLevel()
                            if Level ~= (Genv.VS_AutoFarm.LastLevel or 0) then
                                BossFailCooldown = {}
                                Genv.VS_AutoFarm.LastLevel = Level
                            end
                            local Field, BossId = GetUnlockedField(Level)
                            if BossId then
                                local Gates = {}
                                pcall(function() Gates = HttpService:JSONDecode(LocalPlayer:GetAttribute("BossGatesJson") or "{}") end)
                                if Gates[BossId] == true then
                                    local Idx = table.find(FieldOrder, Field) or 1
                                    while Idx > 1 and not IsFieldUnlocked(FieldOrder[Idx]) do
                                        Idx = Idx - 1
                                    end
                                    local FallbackField = FieldOrder[Idx]
                                    if FallbackField ~= CurrentField then
                                        local Reached = WarpTo(GetFieldPosition(FallbackField))
                                        CurrentField = Reached and FallbackField or nil
                                        task.wait(1)
                                    end
                                    EnsureAutoOn()
                                elseif BossFailCooldown[BossId] and os.clock() < BossFailCooldown[BossId] then
                                    if IsFieldUnlocked(Field) then
                                        if Field ~= CurrentField then
                                            local Reached = WarpTo(GetFieldPosition(Field))
                                            CurrentField = Reached and Field or nil
                                            task.wait(1)
                                        end
                                        EnsureAutoOn()
                                    else
                                        local FallbackField = Field
                                        local Idx = table.find(FieldOrder, Field) or 1
                                        while Idx > 1 and not IsFieldUnlocked(FieldOrder[Idx]) do
                                            Idx = Idx - 1
                                        end
                                        FallbackField = FieldOrder[Idx]
                                        if FallbackField ~= CurrentField then
                                            local Reached = WarpTo(GetFieldPosition(FallbackField))
                                            CurrentField = Reached and FallbackField or nil
                                            task.wait(1)
                                        end
                                        EnsureAutoOn()
                                    end
                                else
                                    local BossAlive = IsBossAlive(BossId)
                                    local RespawnLeft = GetBossRespawnLeft(BossId)
                                    if not BossAlive and RespawnLeft and RespawnLeft > BOSS_APPROACH_SECONDS then
                                        local Idx = table.find(FieldOrder, Field) or 1
                                        while Idx > 1 and not IsFieldUnlocked(FieldOrder[Idx]) do
                                            Idx = Idx - 1
                                        end
                                        local FallbackField = FieldOrder[Idx]
                                        if FallbackField ~= CurrentField then
                                            local Reached = WarpTo(GetFieldPosition(FallbackField))
                                            CurrentField = Reached and FallbackField or nil
                                            task.wait(1)
                                        end
                                        EnsureAutoOn()
                                    else
                                        CurrentField = nil
                                        WarpTo(BossPositions[BossId])
                                        task.wait(1)
                                        if not IsBossAlive(BossId) then
                                            PauseBot()
                                            local spawnWait = os.clock()
                                            while Genv.VS_AutoFarm.Running and not IsDead()
                                                and not IsBossAlive(BossId) and not IsFieldUnlocked(Field)
                                                and os.clock() - spawnWait < BOSS_WAIT_MAX do
                                                task.wait(2)
                                            end
                                        end
                                        if IsBossAlive(BossId) and not IsDead() then
                                            ResumeBot()
                                            local fightStart = os.clock()
                                            while Genv.VS_AutoFarm.Running and not IsDead() and not IsFieldUnlocked(Field) and os.clock() - fightStart < 300 do
                                                task.wait(2)
                                            end
                                        end
                                        if not Genv.VS_AutoFarm.Running then
                                            break
                                        end
                                        if IsFieldUnlocked(Field) then
                                            local Reached = WarpTo(GetFieldPosition(Field))
                                            CurrentField = Reached and Field or nil
                                            task.wait(1)
                                        else
                                             BossFailCooldown[BossId] = os.clock() + 120
                                            local Idx = table.find(FieldOrder, Field) or 1
                                            while Idx > 1 and not IsFieldUnlocked(FieldOrder[Idx]) do
                                                Idx = Idx - 1
                                            end
                                            local FallbackField = FieldOrder[Idx]
                                            local Reached = WarpTo(GetFieldPosition(FallbackField))
                                            CurrentField = Reached and FallbackField or nil
                                            task.wait(1)
                                        end
                                    end
                                end
                            else
                                if Field ~= CurrentField then
                                    local Reached = WarpTo(GetFieldPosition(Field))
                                    CurrentField = Reached and Field or nil
                                    task.wait(1)
                                end
                                EnsureAutoOn()
                            end
                        end
                        task.wait(1)
                    end
                    if Genv.VS_AutoFarm.Generation == ThreadGeneration then
                        Genv.VS_AutoFarm.Thread = nil
                    end
                end)
            end
        else
            if Genv.VS_AutoFarm then
                Genv.VS_AutoFarm.Generation = (Genv.VS_AutoFarm.Generation or 0) + 1
                Genv.VS_AutoFarm.Running = false
                Genv.VS_AutoFarm.Thread = nil
                local StopPlayer = game:GetService("Players").LocalPlayer
                local StopRemotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
                StopRemotes.BotState:FireServer(false)
                if StopPlayer:GetAttribute("AutoOn") == true then
                    local StopBindable = StopPlayer:FindFirstChild("LumiMenuToggle")
                    if StopBindable then
                        StopBindable:Fire("autoToggle")
                    end
                end
            end
        end
    end
})
FarmCard:AddDropdown({
    Name = "Field",
    Options = {"Rabbit Field","Boar Forest","Bear Forest","Hyena Den","Rhino Thicket","Tiger Thicket","Scorpion Dunes","Ram Cliffs","Stone Golem Valley","Polar Bear Plain","Snow Wolf Forest","Ice Golem Peak","Lava Turtle Hill","Fire Bat Cliffs","Hellhound Ash Fields"},
    Default = "Rabbit Field",
    Flag = "SelectedField",
    Callback = function(Value)
        local FieldMap = {
            ["Rabbit Field"] = "Field01",
            ["Boar Forest"] = "Field02",
            ["Bear Forest"] = "Field03",
            ["Hyena Den"] = "Field04",
            ["Rhino Thicket"] = "Field05",
            ["Tiger Thicket"] = "Field06",
            ["Scorpion Dunes"] = "Field07",
            ["Ram Cliffs"] = "Field08",
            ["Stone Golem Valley"] = "Field09",
            ["Polar Bear Plain"] = "Field10",
            ["Snow Wolf Forest"] = "Field11",
            ["Ice Golem Peak"] = "Field12",
            ["Lava Turtle Hill"] = "Field13",
            ["Fire Bat Cliffs"] = "Field14",
            ["Hellhound Ash Fields"] = "Field15"
        }
        Genv.VS_Field = FieldMap[Value] or "Field01"
    end
})
FarmCard:AddToggle({
    Name = "Auto Farm Field",
    Default = false,
    Flag = "AutoFarmField",
    Callback = function(Value)
        if Value then
            Genv.VS_FieldFarm = Genv.VS_FieldFarm or {}
            Genv.VS_FieldFarm.Running = true
            if not Genv.VS_FieldFarm.Thread then
                Genv.VS_FieldFarm.Thread = task.spawn(function()
                    local Players = game:GetService("Players")
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local LocalPlayer = Players.LocalPlayer
                    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
                    Genv.VS_Field = Genv.VS_Field or "Field01"
                    local FieldPositions = {
                        Field01 = Vector3.new(0, 3.6, -203),
                        Field02 = Vector3.new(0, 31.6, -459),
                        Field03 = Vector3.new(0, 59.6, -715),
                        Field04 = Vector3.new(0, 59.8, -1097),
                        Field05 = Vector3.new(0, 87.8, -1353),
                        Field06 = Vector3.new(0, 115.8, -1609),
                        Field07 = Vector3.new(0, 115.9, -1991),
                        Field08 = Vector3.new(0, 143.9, -2247),
                        Field09 = Vector3.new(0, 171.9, -2503),
                        Field10 = Vector3.new(0, 171.7, -2885),
                        Field11 = Vector3.new(0, 199.7, -3141),
                        Field12 = Vector3.new(0, 227.7, -3397),
                        Field13 = Vector3.new(0, 227.2, -3778),
                        Field14 = Vector3.new(0, 255.2, -4034),
                        Field15 = Vector3.new(0, 283.2, -4290)
                    }
                     local function EnsureAutoOn()
                         if LocalPlayer:GetAttribute("AutoOn") ~= true then
                             local Bindable = LocalPlayer:FindFirstChild("LumiMenuToggle")
                            if Bindable then
                                Bindable:Fire("autoToggle")
                            end
                        end
                    end
                    local function IsDead()
                        if LocalPlayer:GetAttribute("HuntRespawnOpen") == true then
                            return true
                        end
                        local Character = LocalPlayer.Character
                        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                        return not Humanoid or Humanoid.Health <= 0
                    end
                    local CurrentField = nil
                    local LastCharacter = LocalPlayer.Character
                     Genv.VS_FieldFarm.BotWasOn = LocalPlayer:GetAttribute("AutoOn") == true
                     if (Genv.VS_FarmMoveMode or "teleport") ~= "walk" or Genv.VS_FieldFarm.BotWasOn then
                         Remotes.BotState:FireServer(true)
                         EnsureAutoOn()
                     end
                     while Genv.VS_FieldFarm.Running do
                         if Genv.VS_BossPriority or Genv.VS_ChestBusy then
                             task.wait(1)
                             continue
                         end
                         local Character = LocalPlayer.Character
                         if Character ~= LastCharacter then
                             LastCharacter = Character
                             CurrentField = nil
                             local ReadyStart = os.clock()
                             while Genv.VS_FieldFarm.Running and os.clock() - ReadyStart < 10 do
                                 local NewCharacter = LocalPlayer.Character
                                 local NewHumanoid = NewCharacter and NewCharacter:FindFirstChildOfClass("Humanoid")
                                 local NewRoot = NewCharacter and NewCharacter:FindFirstChild("HumanoidRootPart")
                                 local RespawnBusy = LocalPlayer:GetAttribute("HuntRespawnOpen") == true
                                     or LocalPlayer:GetAttribute("HuntRespawnWaiting") == true
                                 if NewHumanoid and NewRoot and NewHumanoid.Health > 0
                                     and not NewRoot.Anchored and not RespawnBusy then
                                     task.wait(1)
                                     break
                                 end
                                 task.wait(0.2)
                             end
                         end
                        if not IsDead() then
                            local SelectedField = Genv.VS_Field or "Field01"
                            if SelectedField ~= CurrentField then
                                local Zones = workspace:FindFirstChild("Zones")
                                local Position = nil
                                if Zones then
                                    local Zone = Zones:FindFirstChild(SelectedField)
                                    if Zone then
                                        Position = Zone.Position + Vector3.new(0, 5, 0)
                                    end
                                end
                                if not Position then
                                    Position = FieldPositions[SelectedField] or Vector3.new(0, 50, 0)
                                 end
                                 local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
                                 if HumanoidRootPart then
                                      if (Genv.VS_FarmMoveMode or "teleport") == "walk" then
                                          local Reached = VSWalkTo(Position, {
                                              AcceptDistance = 45,
                                              Timeout = 240,
                                              IsActive = function()
                                                  return Genv.VS_FieldFarm and Genv.VS_FieldFarm.Running
                                              end,
                                          })
                                          if Reached then
                                              CurrentField = SelectedField
                                          else
                                              CurrentField = nil
                                          end
                                      else
                                          VSPauseBot()
                                          task.wait(0.1)
                                          HumanoidRootPart.CFrame = CFrame.new(Position)
                                          task.wait(0.5)
                                          local NewRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                          if NewRoot and (NewRoot.Position - Position).Magnitude <= 80 then
                                              CurrentField = SelectedField
                                          else
                                              CurrentField = nil
                                          end
                                          VSResumeBot()
                                      end
                                  end
                                 task.wait(1)
                            end
                            EnsureAutoOn()
                        end
                        task.wait(1)
                    end
                    Genv.VS_FieldFarm.Thread = nil
                end)
            end
        else
            if Genv.VS_FieldFarm then
                Genv.VS_FieldFarm.Running = false
                local LocalPlayer = game:GetService("Players").LocalPlayer
                local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
                Remotes.BotState:FireServer(false)
                if LocalPlayer:GetAttribute("AutoOn") == true then
                    local Bindable = LocalPlayer:FindFirstChild("LumiMenuToggle")
                    if Bindable then
                        Bindable:Fire("autoToggle")
                    end
                end
            end
        end
    end
})
FarmCard:AddSlider({
    Name = "WalkSpeed",
    Min = 0,
    Max = 100,
    Increment = 1,
    Default = 18,
    Flag = "WalkSpeed",
    Callback = function(Value)
        Genv.VS_WalkSpeed = Value
        local Character = game:GetService("Players").LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            Humanoid.WalkSpeed = Value
        end
    end
})
local StatusCard = MainTab:AddCard({
    Title = "Status",
    Subtitle = "Auto stat points",
    Toggle = false,
    Column = 1
})
local StatTargets = { STR = 0, AGI = 0, VIT = 0, INT = 0, DEX = 0, LUK = 0 }
local PointsInfo = StatusCard:AddInfo({ Text = "Free points", Value = "0" })
for _, Stat in ipairs({ "STR", "AGI", "VIT", "INT", "DEX", "LUK" }) do
    StatusCard:AddTextbox({
        Name = Stat,
        Default = "0",
        Placeholder = "0 = skip",
        Flag = "StatTarget_" .. Stat,
        Callback = function(Value)
            local Number = tonumber(Value) or 0
            StatTargets[Stat] = math.clamp(math.floor(Number), 0, 99)
        end
    })
end
StatusCard:AddToggle({
    Name = "Enable",
    Default = false,
    Flag = "AutoStat",
    Callback = function(Value)
        if Value then
            Genv.VS_StatAuto = true
            if not Genv.VS_StatThread then
                Genv.VS_StatThread = task.spawn(function()
                    local Players = game:GetService("Players")
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local LocalPlayer = Players.LocalPlayer
                    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
                    local Shared = ReplicatedStorage:WaitForChild("Shared")
                    local StatFormulas = require(Shared:WaitForChild("StatFormulas"))
                    local StatPlan = Remotes:WaitForChild("StatPlan")
                    while Genv.VS_StatAuto do
                        local Points = LocalPlayer:GetAttribute("StatPoints") or 0
                        PointsInfo:Set(tostring(Points))
                        local Plan = {}
                        if Points > 0 then
                            local Left = Points
                            for _ = 1, 300 do
                                local BestStat, BestCost = nil, math.huge
                                for _, Stat in ipairs(StatFormulas.StatNames) do
                                    local Current = (LocalPlayer:GetAttribute(Stat) or 1) + (Plan[Stat] or 0)
                                    local Target = StatTargets[Stat] or 0
                                    if Target > 0 and Current < Target and Current < 99 then
                                        local Cost = StatFormulas.StatUpgradeCost(Current)
                                        if Cost <= Left and Cost < BestCost then
                                            BestStat = Stat
                                            BestCost = Cost
                                        end
                                    end
                                end
                                if not BestStat then
                                    break
                                end
                                Plan[BestStat] = (Plan[BestStat] or 0) + 1
                                Left = Left - BestCost
                            end
                        end
                        if next(Plan) ~= nil then
                            pcall(function()
                                StatPlan:InvokeServer(Plan, true)
                            end)
                            task.wait(0.5)
                        end
                        task.wait(2)
                    end
                    Genv.VS_StatThread = nil
                end)
            end
        else
            Genv.VS_StatAuto = false
        end
    end
})
local SellTiers = { [1] = true, [2] = false, [3] = false, [4] = false, [5] = false }
local SellMaterials = true
local SellPercent = 90
local function DecodeAttr(Name)
    local Ok, Data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(
            game:GetService("Players").LocalPlayer:GetAttribute(Name) or "{}"
        )
    end)
    if Ok and type(Data) == "table" then
        return Data
    end
    return {}
end
local MerchantFallback = Vector3.new(-50.4, 4.7, 30.5)
local function BuildSellList()
    local Player = game:GetService("Players").LocalPlayer
    local ItemData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ItemData"))
    local Items = DecodeAttr("ItemsJson")
    local Gear = DecodeAttr("GearJson")
    local Locks = DecodeAttr("LocksJson")
    local Equip = DecodeAttr("EquipJson")
    local RefineJson = DecodeAttr("RefineJson")
    local WeaponId = Player:GetAttribute("WeaponId") or ""
    local Equipped = {}
    for _, Id in pairs(Equip) do
        if type(Id) == "string" and Id ~= "" then
            Equipped[Id] = true
        end
    end
    if WeaponId ~= "" then
        Equipped[WeaponId] = true
    end
    local List, Count, Seen = {}, 0, {}
    for Id, Amount in pairs(Items) do
        local GearInfo = Gear[Id]
        local Def = GearInfo and ItemData[GearInfo.Id] or ItemData[Id]
        if Def and (Def.Sell or 0) > 0 and not Locks[Id] and not Equipped[Id] then
            local Take = false
            if Def.Kind == "armor" or Def.Kind == "weapon" then
                local Tier = GearInfo and GearInfo.T or Def.Tier
                local Refine = RefineJson[Id] or 0
                if Tier and SellTiers[Tier] and Refine == 0 then
                    Take = true
                end
            elseif Def.Kind == "etc" then
                Take = SellMaterials
            end
            if Take then
                table.insert(List, { Id, Amount })
                Seen[Id] = true
                Count = Count + 1
            end
        end
    end
    for Id, Info in pairs(Gear) do
        local Def = Info.Id and ItemData[Info.Id]
        if Def and (Def.Sell or 0) > 0 and not Seen[Id] and not Locks[Id] and not Equipped[Id] then
            local Tier = Info.T or Def.Tier
            local Refine = RefineJson[Id] or 0
            if Tier and SellTiers[Tier] and Refine == 0 then
                table.insert(List, { Id, 1 })
                Count = Count + 1
            end
        end
    end
    return List, Count
end
local function OpenShop(Mode)
    local Player = game:GetService("Players").LocalPlayer
    local Merchant = workspace:FindFirstChild("merchant", true)
    if not Merchant then
        pcall(function()
            Player:RequestStreamAroundAsync(MerchantFallback, 2)
        end)
        local StreamStart = os.clock()
        while os.clock() - StreamStart < 8 do
            Merchant = workspace:FindFirstChild("merchant", true)
            if Merchant then
                break
            end
            task.wait(0.2)
        end
    end
    if not Merchant then
        return false
    end
    local HRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not HRP then
        return false
    end
    -- Use HomeWarp to teleport to merchant instead of CFrame teleport
    local IsPremium = Player:GetAttribute("Premium") == true
    if not IsPremium then
        -- Check cooldown
        local ReadyAt = Player:GetAttribute("HomeWarpReadyAt") or 0
        local ServerTime = workspace:GetServerTimeNow()
        if ReadyAt > ServerTime then
            -- Wait for cooldown (max 65s)
            local WaitStart = os.clock()
            while Player:GetAttribute("HomeWarpReadyAt") and Player:GetAttribute("HomeWarpReadyAt") > workspace:GetServerTimeNow() and os.clock() - WaitStart < 65 do
                task.wait(1)
            end
            if Player:GetAttribute("HomeWarpReadyAt") and Player:GetAttribute("HomeWarpReadyAt") > workspace:GetServerTimeNow() then
                return false -- cooldown didn't expire
            end
        end
        -- Trigger HomeWarp to merchant
        local Bindable = Player:FindFirstChild("LumiMenuToggle")
        if Bindable then
            Bindable:Fire("homeWarpMerchant")
        end
        -- Wait for cast (5s) + teleport
        local EndsAt = Player:GetAttribute("HomeWarpEndsAt") or 0
        local CastStart = os.clock()
        while (EndsAt == 0 or workspace:GetServerTimeNow() < EndsAt) and os.clock() - CastStart < 10 do
            task.wait(0.5)
            local NewEndsAt = Player:GetAttribute("HomeWarpEndsAt")
            if NewEndsAt and NewEndsAt > 0 then
                EndsAt = NewEndsAt
            end
        end
        -- Wait for teleport to complete
        task.wait(1)
    end
    HRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not HRP then
        return false
    end
    local RayParams = RaycastParams.new()
    RayParams.FilterType = Enum.RaycastFilterType.Exclude
    RayParams.FilterDescendantsInstances = { Player.Character }
    local ReadyStart = os.clock()
    while os.clock() - ReadyStart < 8 do
        HRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not HRP then
            return false
        end
        local Ground = workspace:Raycast(
            HRP.Position + Vector3.new(0, 2, 0),
            Vector3.new(0, -20, 0),
            RayParams
        )
        local Distance = (HRP.Position - Merchant:GetPivot().Position).Magnitude
        if Ground and not HRP.Anchored and Distance <= 20 then
            break
        end
        task.wait(0.2)
    end
    HRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not HRP then
        return false
    end
    local Ground = workspace:Raycast(
        HRP.Position + Vector3.new(0, 2, 0),
        Vector3.new(0, -20, 0),
        RayParams
    )
    if not Ground or HRP.Anchored or (HRP.Position - Merchant:GetPivot().Position).Magnitude > 20 then
        return false
    end
    pcall(function()
        Player:RequestStreamAroundAsync(Merchant:GetPivot().Position, 2)
    end)
    task.wait(1)
    local ShopEvent = Player:FindFirstChild("HuntShop")
    if not ShopEvent then
        return false
    end
    pcall(function()
        ShopEvent:Fire(Mode or "sell")
    end)
    local Start = os.clock()
    while Player:GetAttribute("HuntShopOpen") ~= true and os.clock() - Start < 5 do
        task.wait(0.1)
    end
    if Player:GetAttribute("HuntShopOpen") ~= true then
        return false
    end
    task.wait(1)
    return Player:GetAttribute("HuntShopOpen") == true
end
local function CloseShop()
    local Player = game:GetService("Players").LocalPlayer
    local ShopEvent = Player:FindFirstChild("HuntShop")
    if ShopEvent then
        pcall(function()
            ShopEvent:Fire("close")
        end)
    end
end
local function RunSell()
    local Player = game:GetService("Players").LocalPlayer
    local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
    local List, Count = BuildSellList()
    if Count == 0 then
        return 0, "nothing to sell"
    end
    local Character = Player.Character
    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HRP then
        return 0, "no character"
    end
    Genv.VS_ShopBusy = true
    VSPauseBot()
    task.wait(0.2)
    local Ok, Opened = pcall(function()
        local Result = OpenShop("sell")
        if Result then
            Remotes.ShopSellMany:FireServer(List)
            task.wait(1.5)
        end
        return Result
    end)
    pcall(CloseShop)
    task.wait(0.2)
    -- Auto Farm owns the return journey so it uses its normal Mode Walk / Pillar flow.
    local AutoFarm = Genv.VS_AutoFarm
    local RewarpRequested = AutoFarm and AutoFarm.Running == true
    if RewarpRequested then
        AutoFarm.RewarpRequired = true
    end
    Genv.VS_DebugLog = Genv.VS_DebugLog or {}
    table.insert(Genv.VS_DebugLog, "RunSell: completed; AutoFarm rewarp requested=" .. tostring(RewarpRequested))
    Genv.VS_ShopBusy = false
    if not Ok then
        return 0, "error: " .. tostring(Opened)
    end
    if not Opened then
        return 0, "shop did not open"
    end
    return Count, "ok"
end
local MiscCard = ShopTab:AddCard({
    Title = "Sell",
    Subtitle = "Bulk sell by rarity",
    Toggle = false,
    Column = 1
})
for Tier = 1, 5 do
    MiscCard:AddCheckbox({
        Name = "Tier " .. Tier,
        Default = Tier == 1,
        Flag = "SellTier_" .. Tier,
        Callback = function(Value)
            SellTiers[Tier] = Value
        end
    })
end
MiscCard:AddCheckbox({
    Name = "Materials",
    Default = true,
    Flag = "SellMaterials",
    Callback = function(Value)
        SellMaterials = Value
    end
})
MiscCard:AddSlider({
    Name = "Sell at",
    Min = 50,
    Max = 100,
    Increment = 5,
    Default = 90,
    Flag = "SellPercent",
    Suffix = "%",
    Callback = function(Value)
        SellPercent = Value
    end
})
MiscCard:AddToggle({
    Name = "Enable",
    Default = false,
    Flag = "AutoSell",
    Callback = function(Value)
        if Value then
            Genv.VS_SellAuto = true
            if not Genv.VS_SellThread then
                Genv.VS_SellThread = task.spawn(function()
                    local NextTry = 0
                    while Genv.VS_SellAuto do
                        local Player = game:GetService("Players").LocalPlayer
                        local Used = Player:GetAttribute("BagSlotsUsed") or 0
                        local Max = Player:GetAttribute("BagSlotsMax") or 220
                        if os.clock() >= NextTry and Max > 0 and (Used / Max * 100) >= SellPercent then
                            local Sold, Reason = RunSell()
                            if Sold > 0 then
                                task.wait(3)
                            elseif Reason ~= "nothing to sell" then
                                NextTry = os.clock() + 60
                            end
                        end
                        task.wait(5)
                    end
                    Genv.VS_SellThread = nil
                end)
            end
        else
            Genv.VS_SellAuto = false
        end
    end
})
local BuyItems = {
    red_potion = { name = "Red Potion (S)", on = true, below = 300, limit = 500 },
    red_potion_m = { name = "Red Potion (M)", on = true, below = 300, limit = 500 },
    white_potion = { name = "Red Potion (L)", on = true, below = 100, limit = 200 },
    blue_potion = { name = "Blue Potion", on = true, below = 300, limit = 500 },
}
local function DoBuy()
    local Player = game:GetService("Players").LocalPlayer
    local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
    local ItemData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ItemData"))
    local Items = DecodeAttr("ItemsJson")
    local Silver = Player:GetAttribute("Silver") or 0
    local Discount = Player:GetAttribute("BuyDiscountPct") or 0
    local Plan = {}
    for Id, Cfg in pairs(BuyItems) do
        if Cfg.on and Cfg.limit > 0 then
            local Have = Items[Id] or 0
            local Below = math.min(Cfg.below, Cfg.limit - 1)
            if Have < Below then
                local Def = ItemData[Id]
                local Price = math.max(1, math.floor(((Def and Def.Buy) or 0) * (100 - Discount) / 100))
                local Need = Cfg.limit - Have
                if Price * Need > Silver then
                    Need = math.floor(Silver / Price)
                end
                if Need > 0 then
                    table.insert(Plan, { Id = Id, Count = Need })
                    Silver = Silver - Price * Need
                end
            end
        end
    end
    if #Plan == 0 then
        return 0, "nothing to buy"
    end
    local Character = Player.Character
    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HRP then
        return 0, "no character"
    end
    Genv.VS_ShopBusy = true
    VSPauseBot()
    task.wait(0.2)
    local Ok, Opened = pcall(function()
        local Result = OpenShop("open")
        if Result then
            for _, Entry in ipairs(Plan) do
                Remotes.ShopBuy:FireServer(Entry.Id, Entry.Count)
                task.wait(0.4)
            end
            task.wait(1)
        end
        return Result
    end)
    pcall(CloseShop)
    task.wait(0.2)
    -- Auto Farm owns the return journey so it uses its normal Mode Walk / Pillar flow.
    local AutoFarm = Genv.VS_AutoFarm
    local RewarpRequested = AutoFarm and AutoFarm.Running == true
    if RewarpRequested then
        AutoFarm.RewarpRequired = true
    end
    Genv.VS_DebugLog = Genv.VS_DebugLog or {}
    table.insert(Genv.VS_DebugLog, "DoBuy: completed; AutoFarm rewarp requested=" .. tostring(RewarpRequested))
    Genv.VS_ShopBusy = false
    if not Ok or not Opened then
        return 0, "shop did not open"
    end
    return #Plan, "ok"
end
local BuyCard = ShopTab:AddCard({
    Title = "Buy",
    Subtitle = "Refill potions",
    Toggle = false,
    Column = 2
})
for _, Id in ipairs({ "red_potion", "red_potion_m", "white_potion", "blue_potion" }) do
    local Cfg = BuyItems[Id]
    BuyCard:AddCheckbox({
        Name = Cfg.name,
        Default = true,
        Flag = "BuyItem_" .. Id,
        Callback = function(Value)
            Cfg.on = Value
        end
    })
    BuyCard:AddTextbox({
        Name = "Below",
        Default = tostring(Cfg.below),
        Placeholder = "buy when below",
        Flag = "BuyBelow_" .. Id,
        Callback = function(Value)
            Cfg.below = math.max(0, math.floor(tonumber(Value) or 0))
        end
    })
    BuyCard:AddTextbox({
        Name = "Limit",
        Default = tostring(Cfg.limit),
        Placeholder = "refill up to",
        Flag = "BuyLimit_" .. Id,
        Callback = function(Value)
            Cfg.limit = math.max(0, math.floor(tonumber(Value) or 0))
        end
    })
end
BuyCard:AddToggle({
    Name = "Enable",
    Default = false,
    Flag = "AutoBuy",
    Callback = function(Value)
        if Value then
            Genv.VS_BuyAuto = true
            if not Genv.VS_BuyThread then
                Genv.VS_BuyThread = task.spawn(function()
                    local NextTry = 0
                    while Genv.VS_BuyAuto do
                        if os.clock() >= NextTry then
                            local Ok, Bought, Reason = pcall(DoBuy)
                            if not Ok then
                                Bought, Reason = 0, "error"
                            end
                            if Bought == 0 and Reason ~= "nothing to buy" then
                                NextTry = os.clock() + 60
                            end
                        end
                        task.wait(10)
                    end
                    Genv.VS_BuyThread = nil
                end)
            end
        else
            Genv.VS_BuyAuto = false
        end
    end
})
local UtilPlayers = game:GetService("Players")
local UtilLighting = game:GetService("Lighting")
local UtilLocalPlayer = UtilPlayers.LocalPlayer
local PerfCard = UtilitiesTab:AddCard({
    Title = "Performance",
    Subtitle = "Reduce lag and save power",
    Toggle = false,
    Column = 1
})
local function SetBlackScreen(On)
    local Gui = Genv.VS_BlackGui
    if On then
        if Gui and Gui.Parent then
            return
        end
        Gui = Instance.new("ScreenGui")
        Gui.Name = "VS_BlackScreen"
        Gui.IgnoreGuiInset = true
        Gui.ResetOnSpawn = false
        Gui.DisplayOrder = 900
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.fromScale(1, 1)
        Frame.BackgroundColor3 = Color3.new(0, 0, 0)
        Frame.BorderSizePixel = 0
        Frame.Parent = Gui
        local Parent = game:GetService("CoreGui")
        pcall(function()
            if gethui then
                Parent = gethui()
            end
        end)
        Gui.Parent = Parent
        Genv.VS_BlackGui = Gui
    elseif Gui then
        pcall(function()
            Gui:Destroy()
        end)
        Genv.VS_BlackGui = nil
    end
end
PerfCard:AddToggle({
    Name = "Black Screen",
    Default = false,
    Flag = "BlackScreen",
    Callback = function(Value)
        SetBlackScreen(Value)
    end
})
local function SetLowQuality(On)
    pcall(function()
        if On then
            if not Genv.VS_OldQuality then
                Genv.VS_OldQuality = settings().Rendering.QualityLevel
            end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        else
            settings().Rendering.QualityLevel = Genv.VS_OldQuality or Enum.QualityLevel.Level21
        end
    end)
end
PerfCard:AddToggle({
    Name = "Low Quality",
    Default = false,
    Flag = "LowQuality",
    Callback = function(Value)
        SetLowQuality(Value)
    end
})
PerfCard:AddToggle({
    Name = "FPS Lock",
    Default = false,
    Flag = "FPSLock",
    Callback = function(Value)
        pcall(function()
            if Value then
                setfpscap(60)
            else
                setfpscap(Genv.VS_FpsCap or 240)
            end
        end)
    end
})
PerfCard:AddSlider({
    Name = "FPS Cap",
    Min = 30,
    Max = 240,
    Increment = 10,
    Default = 240,
    Flag = "FPSCap",
    Callback = function(Value)
        Genv.VS_FpsCap = Value
        pcall(function()
            setfpscap(Value)
        end)
    end
})
local UtilCard = UtilitiesTab:AddCard({
    Title = "Misc",
    Subtitle = "Extra helpers",
    Toggle = false,
    Column = 2
})
local AntiAfkToggle = UtilCard:AddToggle({
    Name = "Anti AFK",
    Default = true,
    Flag = "AntiAFK",
    Callback = function(Value)
        Genv.VS_AntiAfk = Value
        if Value and not Genv.VS_AntiAfkHooked then
            Genv.VS_AntiAfkHooked = true
            local VirtualUser = game:GetService("VirtualUser")
            UtilLocalPlayer.Idled:Connect(function()
                if not Genv.VS_AntiAfk then
                    return
                end
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            end)
        end
        if not Genv.VS_AfkBlockHooked then
            local Ok = pcall(function()
                local Meta = getrawmetatable(game)
                local OldNamecall = Meta.__namecall
                assert(typeof(OldNamecall) == "function", "no __namecall")
                Genv.VS_AfkOldNamecall = OldNamecall
                setreadonly(Meta, false)
                Meta.__namecall = newcclosure(function(self, ...)
                    if Genv.VS_AntiAfk
                        and not checkcaller()
                        and typeof(self) == "Instance"
                        and getnamecallmethod() == "FireServer"
                        and self.Name == "AfkRejoin"
                        and self:IsA("RemoteEvent") then
                        Genv.VS_AfkBlocked = (Genv.VS_AfkBlocked or 0) + 1
                        return nil
                    end
                    return OldNamecall(self, ...)
                end)
                setreadonly(Meta, true)
            end)
            Genv.VS_AfkBlockHooked = Ok
        end
    end
})
pcall(function() AntiAfkToggle:Set(true) end)
UtilCard:AddToggle({
    Name = "Fullbright",
    Default = false,
    Flag = "Fullbright",
    Callback = function(Value)
        if Value then
            if not Genv.VS_OldLighting then
                Genv.VS_OldLighting = {
                    Ambient = UtilLighting.Ambient,
                    OutdoorAmbient = UtilLighting.OutdoorAmbient,
                    Brightness = UtilLighting.Brightness,
                    ClockTime = UtilLighting.ClockTime,
                    FogEnd = UtilLighting.FogEnd,
                    GlobalShadows = UtilLighting.GlobalShadows,
                }
            end
            UtilLighting.Ambient = Color3.new(1, 1, 1)
            UtilLighting.OutdoorAmbient = Color3.new(1, 1, 1)
            UtilLighting.Brightness = 2
            UtilLighting.ClockTime = 14
            UtilLighting.FogEnd = 100000
            UtilLighting.GlobalShadows = false
        else
            local Old = Genv.VS_OldLighting
            if Old then
                UtilLighting.Ambient = Old.Ambient
                UtilLighting.OutdoorAmbient = Old.OutdoorAmbient
                UtilLighting.Brightness = Old.Brightness
                UtilLighting.ClockTime = Old.ClockTime
                UtilLighting.FogEnd = Old.FogEnd
                UtilLighting.GlobalShadows = Old.GlobalShadows
            end
        end
    end
})
local STREAM_NAME = "VoltScriptZ"
-- Anything left bound by an earlier execution of this script would keep the
-- 60x/s sweep alive, so drop it as soon as the new version loads.
pcall(function()
    game:GetService("RunService"):UnbindFromRenderStep("VoltStreamSweep")
end)
Genv.VS_StreamMode = false
Genv.VS_StreamThread = nil
-- Measured in this map: one full sweep cost 25.5 ms (4,700 text objects in
-- PlayerGui, 1,900 SurfaceGui, 25.8k workspace instances). Running that from
-- a render step (60x per second) is what made Stream Mode lag. The sweep now
-- runs on a timer over a cached label list (1.7 ms measured) instead of
-- re-walking the whole tree, and never touches workspace every frame.
local STREAM_TICK = 0.35
local STREAM_SURFACE_REFRESH = 30

local StreamLabels = setmetatable({}, { __mode = "k" })
local StreamChanged = setmetatable({}, { __mode = "k" })
local StreamConnections = {}
local StreamSurfaceAt = 0
local StreamHub = nil

local function StreamIsText(Obj)
    return Obj:IsA("TextLabel") or Obj:IsA("TextButton") or Obj:IsA("TextBox")
end

local function SetStreamName(On)
    local Character = UtilLocalPlayer.Character
    if not Character then
        return
    end
    local DisplayName = On and STREAM_NAME or UtilLocalPlayer.DisplayName
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if Humanoid and Humanoid.DisplayName ~= DisplayName then
        Humanoid.DisplayName = DisplayName
    end
    local Tag = Character:FindFirstChild("LumiNameTag", true)
    local Label = Tag and Tag:FindFirstChild("Name", true)
    local TagText = On and STREAM_NAME or UtilLocalPlayer.Name
    if Label and Label:IsA("TextLabel") and Label.Text ~= TagText then
        Label.Text = TagText
    end
end

local function StreamReplaceText(Obj, Name, Display)
    local Text = Obj.Text
    if not Text or Text == "" then
        return
    end
    if string.find(Text, Name, 1, true) then
        Obj.Text = string.gsub(Text, Name, STREAM_NAME)
        StreamChanged[Obj] = true
    elseif Display ~= Name and string.find(Text, Display, 1, true) then
        Obj.Text = string.gsub(Text, Display, STREAM_NAME)
        StreamChanged[Obj] = true
    end
end

-- VoltScriptZ's own window lives in CoreGui.RobloxGui, not PlayerGui, so it
-- needs to be tracked explicitly or the hub keeps printing the real name.
local function FindStreamHub()
    local CoreGui = game:GetService("CoreGui")
    local RobloxGui = CoreGui:FindFirstChild("RobloxGui")
    return RobloxGui and RobloxGui:FindFirstChild("VoltScriptZ") or nil
end

local function StreamRestore()
    local Name = UtilLocalPlayer.Name
    for Obj in pairs(StreamChanged) do
        if Obj.Parent then
            local Text = Obj.Text
            if Text and string.find(Text, STREAM_NAME, 1, true) then
                pcall(function()
                    Obj.Text = string.gsub(Text, STREAM_NAME, Name)
                end)
            end
        end
        StreamChanged[Obj] = nil
    end
end

local function StreamTrack(Root)
    if not Root then
        return
    end
    for _, Obj in ipairs(Root:GetDescendants()) do
        if StreamIsText(Obj) then
            StreamLabels[Obj] = true
        end
    end
end

local function StreamDisconnect()
    for _, Conn in ipairs(StreamConnections) do
        pcall(function()
            Conn:Disconnect()
        end)
    end
    table.clear(StreamConnections)
end

local function StreamConnect(Root)
    if not Root then
        return
    end
    table.insert(StreamConnections, Root.DescendantAdded:Connect(function(Obj)
        if not Genv.VS_StreamMode or not StreamIsText(Obj) then
            return
        end
        StreamLabels[Obj] = true
        pcall(function()
            StreamReplaceText(Obj, UtilLocalPlayer.Name, UtilLocalPlayer.DisplayName)
        end)
    end))
end

local function StreamTrackHub()
    local Hub = FindStreamHub()
    if not Hub or Hub == StreamHub then
        return
    end
    StreamHub = Hub
    StreamTrack(Hub)
    StreamConnect(Hub)
    for _, Obj in ipairs(Hub:GetDescendants()) do
        if StreamIsText(Obj) then
            table.insert(StreamConnections, Obj:GetPropertyChangedSignal("Text"):Connect(function()
                if Genv.VS_StreamMode then
                    pcall(StreamReplaceText, Obj, UtilLocalPlayer.Name, UtilLocalPlayer.DisplayName)
                end
            end))
        end
    end
end

local function SweepNames()
    local Name = UtilLocalPlayer.Name
    local Display = UtilLocalPlayer.DisplayName
    pcall(function()
        for Obj in pairs(StreamLabels) do
            if not Obj.Parent then
                StreamLabels[Obj] = nil
            else
                StreamReplaceText(Obj, Name, Display)
            end
        end
    end)
    if os.clock() - StreamSurfaceAt > STREAM_SURFACE_REFRESH then
        StreamSurfaceAt = os.clock()
        pcall(StreamTrackHub)
        pcall(function()
            for _, Obj in ipairs(workspace:GetDescendants()) do
                if Obj:IsA("SurfaceGui") then
                    StreamTrack(Obj)
                end
            end
        end)
    end
end

local function SetStreamMode(On)
    Genv.VS_StreamMode = On
    pcall(SetStreamName, On)
    pcall(function()
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not On)
    end)
    if On then
        pcall(function()
            local Gui = UtilLocalPlayer:FindFirstChild("PlayerGui")
            if Gui then
                StreamTrack(Gui)
                StreamConnect(Gui)
            end
            local CoreGui = game:GetService("CoreGui")
            local PlayerList = CoreGui:FindFirstChild("PlayerList")
            if PlayerList then
                StreamTrack(PlayerList)
                StreamConnect(PlayerList)
            end
            table.insert(StreamConnections, CoreGui.ChildAdded:Connect(function(Obj)
                if Genv.VS_StreamMode and Obj.Name == "PlayerList" then
                    StreamTrack(Obj)
                    pcall(SweepNames)
                end
            end))
            for _, Obj in ipairs(workspace:GetDescendants()) do
                if Obj:IsA("SurfaceGui") then
                    StreamTrack(Obj)
                end
            end
            StreamTrackHub()
            StreamSurfaceAt = os.clock()
        end)
        if not Genv.VS_StreamThread then
            Genv.VS_StreamThread = task.spawn(function()
                while Genv.VS_StreamMode do
                    pcall(SetStreamName, true)
                    pcall(SweepNames)
                    task.wait(STREAM_TICK)
                end
                Genv.VS_StreamThread = nil
            end)
        end
    else
        pcall(function()
            game:GetService("RunService"):UnbindFromRenderStep("VoltStreamSweep")
        end)
        StreamDisconnect()
        pcall(StreamRestore)
        StreamHub = nil
        StreamLabels = setmetatable({}, { __mode = "k" })
    end
end
UtilCard:AddToggle({
    Name = "Stream Mode (Hide Name)",
    Default = false,
    Flag = "StreamMode",
    Callback = function(Value)
        SetStreamMode(Value)
    end,
})
UtilLocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if Genv.VS_StreamMode then
        pcall(function()
            SetStreamName(true)
        end)
    end
end)
UtilCard:AddButton({
    Name = "Copy Job ID",
    Callback = function()
        pcall(function()
            setclipboard(game.JobId)
        end)
    end
})
UtilCard:AddButton({
    Name = "Rejoin Server",
    Callback = function()
        local Remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        local AfkRejoin = Remotes and Remotes:FindFirstChild("AfkRejoin")
        if AfkRejoin then
            pcall(function()
                AfkRejoin:FireServer(true)
            end)
            return
        end
        pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, UtilLocalPlayer)
        end)
    end
})
UtilCard:AddLabel(
    "Anti AFK prevents idle kicks - Stream Mode shows \"VoltScriptZ\" instead of your name on the overhead nameplate"
)
local InterfaceCard = SettingsTab:AddCard({
    Title = "Interface",
    Subtitle = "Menu appearance",
    Toggle = false,
    Column = 1
})
InterfaceCard:AddSlider({
    Name = "UI Scale",
    Min = 50,
    Max = 100,
    Increment = 5,
    Default = 100,
    Flag = "UIScale",
    Suffix = "%",
    Callback = function(Value)
        pcall(function()
            Window.UIScale.Scale = Window.BaseScale * (Value / 100)
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
local ConfigNameBox = ConfigCard:AddTextbox({
    Name = "Config",
    Default = "main",
    Placeholder = "config name",
})
local SavedList = ConfigCard:AddDropdown({
    Name = "Saved",
    Options = { "(no configs)" },
    Default = "(no configs)",
    Callback = function(Value)
        if Value and Value ~= "(no configs)" then
            pcall(function()
                ConfigNameBox:Set(tostring(Value), true)
            end)
        end
    end,
})
local AutoLoadInfo = ConfigCard:AddInfo({ Text = "Auto Load", Value = "None" })
local function RefreshConfigList(Select)
    local Names = {}
    pcall(function()
        Names = Window:ListConfigs()
    end)
    if type(Names) == "table" then
        local Clean = {}
        for _, N in ipairs(Names) do
            if type(N) == "string" and string.sub(N, 1, 1) ~= "_" then
                table.insert(Clean, N)
            end
        end
        Names = Clean
    end
    if type(Names) ~= "table" or #Names == 0 then
        Names = { "(no configs)" }
    end
    pcall(function()
        SavedList:Refresh(Names)
    end)
    if Select and table.find(Names, Select) then
        pcall(function()
            SavedList:Set(Select, true)
        end)
    end
end
local function CurrentConfigName()
    local Name = nil
    pcall(function()
        Name = ConfigNameBox:Get()
    end)
    if Name == nil or tostring(Name) == "" then
        return "main"
    end
    return tostring(Name)
end
local function SnapshotFlags()
    local Snap = {}
    for Flag, Obj in pairs(Window.Flags) do
        if Obj and Obj.Get then
            local Ok, Value = pcall(function()
                return Obj:Get()
            end)
            if Ok then
                Snap[Flag] = Value
            end
        end
    end
    return Snap
end
local function ApplyChangedFlags(Before)
    local Count = 0
    for Flag, Obj in pairs(Window.Flags) do
        if Obj and Obj.Get and Obj.Set then
            local Ok, Now = pcall(function()
                return Obj:Get()
            end)
            if Ok then
                local Old = Before[Flag]
                local Changed
                if type(Now) == "table" or type(Old) == "table" then
                    Changed = tostring(Now) ~= tostring(Old)
                else
                    Changed = Now ~= Old
                end
                if Changed then
                    pcall(function()
                        Obj:Set(Now)
                    end)
                    Count += 1
                end
            end
        end
    end
    return Count
end
local function NotifyConfig(Text)
    pcall(function()
        Window:Notify({ Title = "Config", Text = Text })
    end)
end
local AutoLoadFile = "_volt_autoload.json"
local ConfigHttp = game:GetService("HttpService")
local function SaveAutoLoadName(Name)
    pcall(function()
        writefile(AutoLoadFile, ConfigHttp:JSONEncode({ Name = Name }))
    end)
end
local function ReadAutoLoadName()
    local Ok, Raw = pcall(readfile, AutoLoadFile)
    if not Ok or type(Raw) ~= "string" then
        return nil
    end
    local Ok2, Data = pcall(function()
        return ConfigHttp:JSONDecode(Raw)
    end)
    if Ok2 and type(Data) == "table" and type(Data.Name) == "string" and Data.Name ~= "" then
        return Data.Name
    end
    return nil
end
local function ClearAutoLoadName()
    pcall(function()
        if delfile then
            delfile(AutoLoadFile)
        end
    end)
end
local function ConfigFileExists(Name)
    if type(isfile) ~= "function" then
        return true
    end
    local Ok, Exists = pcall(function()
        return isfile(Name .. ".json")
    end)
    return Ok and Exists
end
RefreshConfigList()
ConfigCard:AddButton({
    Name = "Save",
    Callback = function()
        local Name = CurrentConfigName()
        local Ok = false
        pcall(function()
            Ok = Window:SaveConfig(Name) == true
        end)
        if Ok then
            RefreshConfigList(Name)
            NotifyConfig("Saved: " .. Name)
        else
            NotifyConfig("Save failed: " .. Name)
        end
    end,
})
ConfigCard:AddButton({
    Name = "Load",
    Callback = function()
        local Name = CurrentConfigName()
        local Before = SnapshotFlags()
        local Ok = false
        pcall(function()
            Ok = Window:LoadConfig(Name) == true
        end)
        if Ok then
            local Applied = ApplyChangedFlags(Before)
            RefreshConfigList(Name)
            NotifyConfig("Loaded: " .. Name .. " (" .. Applied .. " changed)")
        else
            NotifyConfig("Not found: " .. Name)
        end
    end,
})
ConfigCard:AddButton({
    Name = "Delete",
    Callback = function()
        local Name = CurrentConfigName()
        pcall(function()
            Window:DeleteConfig(Name)
        end)
        if ReadAutoLoadName() == Name then
            ClearAutoLoadName()
            pcall(function()
                AutoLoadInfo:Set("None")
            end)
        end
        RefreshConfigList()
        NotifyConfig("Deleted: " .. Name)
    end,
})
ConfigCard:AddButton({
    Name = "Set Up Auto Load",
    Callback = function()
        local Name = CurrentConfigName()
        local Before = SnapshotFlags()
        local Ok = false
        pcall(function()
            Window:EnableAutoSave(Name)
            Ok = true
        end)
        if Ok and ConfigFileExists(Name) then
            ApplyChangedFlags(Before)
            SaveAutoLoadName(Name)
            pcall(function()
                AutoLoadInfo:Set(Name)
            end)
            NotifyConfig("Auto Load: " .. Name)
        elseif Ok then
            pcall(function()
                Window:DisableAutoSave()
            end)
            ClearAutoLoadName()
            pcall(function()
                AutoLoadInfo:Set("None")
            end)
            NotifyConfig("Save this config first: " .. Name)
        else
            NotifyConfig("Auto Load failed")
        end
    end,
})
do
    local Name = ReadAutoLoadName()
    if Name and ConfigFileExists(Name) then
        local Before = SnapshotFlags()
        local Ok = false
        pcall(function()
            Window:EnableAutoSave(Name)
            Ok = true
        end)
        if Ok then
            ApplyChangedFlags(Before)
            pcall(function()
                AutoLoadInfo:Set(Name)
            end)
            NotifyConfig("Auto Loaded: " .. Name)
        end
    elseif Name then
        ClearAutoLoadName()
    end
end
local function AutoStatePlayerName()
    local Ok, Name = pcall(function()
        return game:GetService("Players").LocalPlayer.Name
    end)
    if Ok and type(Name) == "string" and Name ~= "" then
        return Name
    end
    return "default"
end
local AutoStatePlayer = AutoStatePlayerName()
local AutoStateName = "_volt_state_" .. AutoStatePlayer
local AutoStateSupported = (type(writefile) == "function") and (type(readfile) == "function")
local AutoStateBlocked = {
    LeaveOnAdmin = true,
}
local AutoStateInfo = ConfigCard:AddInfo({ Text = "Auto Save", Value = "..." })
local function AutoStateSnapshot()
    local Snap = {}
    for Flag, Obj in pairs(Window.Flags) do
        local Ok, V = pcall(function()
            return Obj:Get()
        end)
        if Ok then
            Snap[Flag] = V
        end
    end
    return Snap
end
local function AutoStateSame(A, B)
    for K, V in pairs(A) do
        if tostring(V) ~= tostring(B[K]) then
            return false
        end
    end
    for K in pairs(B) do
        if A[K] == nil then
            return false
        end
    end
    return true
end
local function AutoStateSave()
    if not AutoStateSupported then
        return
    end
    pcall(function()
        Window:SaveConfig(AutoStateName)
    end)
end
local function AutoStateSetInfo(Text)
    pcall(function()
        AutoStateInfo:Set(Text)
    end)
end
if not AutoStateSupported then
    AutoStateSetInfo("Not supported")
else
    local Exists = false
    if type(isfile) == "function" then
        pcall(function()
            Exists = isfile(AutoStateName .. ".json") == true
        end)
    else
        Exists = true
    end
    if not Exists then
        AutoStateSetInfo("New - " .. AutoStatePlayer)
    else
        local Before = AutoStateSnapshot()
        local Loaded = false
        pcall(function()
            Loaded = Window:LoadConfig(AutoStateName) == true
        end)
        if Loaded then
            for Flag in pairs(AutoStateBlocked) do
                local Obj = Window.Flags[Flag]
                if Obj and Obj.Set and Before[Flag] ~= nil then
                    pcall(function()
                        Obj:Set(Before[Flag], true)
                    end)
                end
            end
            ApplyChangedFlags(Before)
            AutoStateSetInfo("Restored - " .. AutoStatePlayer)
        else
            AutoStateSetInfo("Load failed")
        end
    end
end
if AutoStateSupported then
    task.spawn(function()
        local Last = AutoStateSnapshot()
        while true do
            task.wait(2)
            local Now = AutoStateSnapshot()
            if not AutoStateSame(Last, Now) then
                Last = Now
                AutoStateSave()
            end
        end
    end)
end
