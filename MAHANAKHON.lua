-- D0TFrosty | MAHANAKHON RACING
-- LOGIC SCRIPT
local env=getgenv()
local previous=env.__D0TFrostyMahanakhon
if previous and previous.Destroy then previous:Destroy()end
local template=env.__D0TFrostyRayVinzTemplate
if template and template.Destroy then template:Destroy()end
if env.MahanakhonGrab and env.MahanakhonGrab.Destroy then env.MahanakhonGrab.Destroy()end
local Runtime={Alive=true,Booting=true,Connections={},Switches={},Controls={},Pages={},Farm={Job="Grab",Enabled={}},Tune={Busy=false,Status="Idle",Feedback={},Gain=1,Code=""}}
env.__D0TFrostyMahanakhon=Runtime
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
local player=Players.LocalPlayer
while not player do task.wait(.1);player=Players.LocalPlayer end
Runtime.Farm.LastStartedJob=previous and previous.Farm and previous.Farm.LastStartedJob or player:GetAttribute("Job")
local GameShared=require(RS:WaitForChild("GameShared"))
local JobShared=require(RS:WaitForChild("JobShared"))
local EcuShared=require(RS:WaitForChild("EcuShared"))
local BikeShared=require(RS:WaitForChild("PCX160Shared"))
local Net=require(RS:WaitForChild("NetSeal"))
local Remotes=RS:WaitForChild("GameRemotes")
-- Enter through the game's normal citizen selection and menu lifecycle.
Runtime.Entry={Status="รอหน้าเริ่ม"}
function Runtime:ChooseLowGraphics()
    local gui=player:FindFirstChildOfClass("PlayerGui")
    local picker=gui and gui:FindFirstChild("GraphicsPicker")
    if not picker or not picker.Enabled then return false end
    for _,label in ipairs(picker:GetDescendants())do
        if label:IsA("TextLabel")and label.Text=="Play on LOW"then
            local button=label:FindFirstAncestorWhichIsA("GuiButton")
            if button then
                for _,connection in ipairs(getconnections(button.Activated))do
                    if type(connection.Function)=="function"then
                        local ok=pcall(connection.Function)
                        if ok then self.Entry.Graphics="Low";return true end
                    end
                end
            end
        end
    end
    return false
end
task.spawn(function()
    local deadline=os.clock()+45
    while Runtime.Alive and os.clock()<deadline do
        if Runtime:ChooseLowGraphics()then return end
        task.wait(.25)
    end
end)

function Runtime:EnterAsCitizen()
    local gui=player:FindFirstChildOfClass("PlayerGui")
    local main=gui and gui:FindFirstChild("MainMenu")
    if not main or not main.Enabled then return false end
    self.Entry.Status="เลือกประชาชน"
    if player:GetAttribute("Job")~="Citizen"or not player:GetAttribute("JobChosen")then
        local remote=Remotes:FindFirstChild(JobShared.REMOTE)
        if not remote then return false end
        local ok=pcall(Net.invoke,remote,"Set","Citizen")
        if not ok or not self.Alive then return false end
        local deadline=os.clock()+4
        repeat task.wait(.1)until not self.Alive or (player:GetAttribute("JobChosen")and player:GetAttribute("Job")=="Citizen")or os.clock()>deadline
    end
    if not self.Alive or not player:GetAttribute("JobChosen")or player:GetAttribute("Job")~="Citizen"then return false end
    local ui=RS:FindFirstChild("GameUI")
    local menu=ui and ui:FindFirstChild("Menu")
    if not menu then return false end
    require(menu).close()
    self.Entry.Status="เข้าเกมแล้ว"
    return true
end
task.spawn(function()
    local deadline=os.clock()+45
    local attempt=0
    while Runtime.Alive and os.clock()<deadline do
        local gui=player:FindFirstChildOfClass("PlayerGui")
        local main=gui and gui:FindFirstChild("MainMenu")
        if main and main.Enabled and os.clock()>=attempt then
            attempt=os.clock()+2
            if Runtime:EnterAsCitizen()then return end
        end
        task.wait(.25)
    end
    if Runtime.Alive and Runtime.Entry.Status=="รอหน้าเริ่ม"then Runtime.Entry.Status="อยู่ในเกมแล้ว"end
end)

Runtime.Shop={Marked=false}
Runtime.ShopLocations=previous and previous.ShopLocations or{
    Spot_1=Vector3.new(71.25747,.8,-2722.2749),Spot_2=Vector3.new(71.25747,.8,-1292.275),
    Spot_3=Vector3.new(-71.25747,.8,252.275),Spot_4=Vector3.new(71.25747,.8,1487.725),
    Spot_5=Vector3.new(-71.25747,.8,2742.2749)
}
local Settings={Title="D0TFrosty X",Logo="rbxassetid://88510876496121",Folder="D0TFrosty X/MAHANAKHON RACING"}
local cachePath=Settings.Folder.."/Ecu_"..player.UserId..".json"
Runtime.SelectedVehicle="Current"
Runtime.Cache={}
if isfile and readfile and isfile(cachePath)then
    local ok,data=pcall(function()return Http:JSONDecode(readfile(cachePath))end)
    if ok and type(data)=="table"then Runtime.Cache=data end
end
function Runtime:Connect(signal,callback)
    local connection=signal:Connect(function(...)if self.Alive then callback(...)end end)
    table.insert(self.Connections,connection);return connection
end
function Runtime:Destroy()
    if not self.Alive then return end
    self.Alive=false;self.Tune.Cancel=true
    if self.ReleaseGiveInputs then self:ReleaseGiveInputs()end
    if self.GiveMoney and self.GiveMoney.TravelCleanup then self.GiveMoney.TravelCleanup()end
    if self.RestoreDriveTune then self:RestoreDriveTune()end
    if self.ClearShopMarker then self:ClearShopMarker()end
    if self.Grab then self.Grab.Shutdown()end
    if self.OtherWork then self.OtherWork.Shutdown()end
    if self.ShopDriver then self.ShopDriver.Shutdown()end
    for _,connection in ipairs(self.Connections)do connection:Disconnect()end
    table.clear(self.Connections)
    if self.PartialUICleanup then self.PartialUICleanup();self.PartialUICleanup=nil end
    if self.Window then local window=self.Window;self.Window=nil;pcall(window.Unload,window)end
    if env.__D0TFrostyMahanakhon==self then env.__D0TFrostyMahanakhon=nil end
end
if STATE and STATE.onCleanup then STATE.onCleanup(function()Runtime:Destroy()end)end
-- BEGIN FARM CHECK
do
    local function autoWorkEnabled()
        if not Runtime.Alive then return false end
        for _,enabled in pairs(Runtime.Farm.Enabled)do
            if enabled==true then return true end
        end
        return false
    end
    local function shown(object)
        local ancestor=object
        while ancestor do
            if ancestor:IsA("GuiObject")and not ancestor.Visible then return false end
            if ancestor:IsA("ScreenGui")and not ancestor.Enabled then return false end
            ancestor=ancestor.Parent
        end
        return true
    end
    local function clean(text)
        return (text:gsub(utf8.char(0xFE0F),""):match("^%s*(.-)%s*$"))
    end
    local categoryEmojis={
        Animals="🐶 🐱 🐭 🐹 🐰 🦊 🐻 🐼 🐨 🐯 🦁 🐮 🐷 🐸 🐵 🐒 🐔 🐧 🐦 🐤 🦆 🦅 🦉 🦇 🐺 🐗 🐴 🦄 🐝 🐛 🦋 🐌 🐞 🐜 🦟 🦗 🕷 🦂 🐢 🐍 🦎 🐙 🦑 🦐 🦞 🦀 🐡 🐠 🐟 🐬 🐳 🐋 🦈 🐊 🐅 🐆 🦓 🦍 🦧 🐘 🦛 🦏 🐪 🐫 🦒 🦘 🐃 🐂 🐄 🐎 🐖 🐏 🐑 🦙 🐐 🦌 🐕 🐩 🐈 🐓 🦃 🦚 🦜 🦢 🕊 🐇 🦝 🦨 🦡 🦫 🦦 🦥 🐁 🐀 🐿 🦔 🐾",
        Fruits="🍏 🍎 🍐 🍊 🍋 🍌 🍉 🍇 🍓 🫐 🍈 🍒 🍑 🥭 🍍 🥥 🥝",
        Vehicles="🚗 🚕 🚙 🚌 🚎 🏎 🚓 🚑 🚒 🚐 🛻 🚚 🚛 🚜 🛵 🏍 🚲 🛴 🛺 🚂 🚆 🚇 🚈 🚉 🚊 🚝 🚄 🚅 🚃 🚋 🚞 🚟 🚠 🚡 🚁 ✈ 🛩 🛫 🛬 🚀 🛸 🚢 ⛴ 🛥 🚤 ⛵ 🛶 🛳 🦽 🦼",
    }
    categoryEmojis.Vegetables="🥕 🌽 🥦 🥬 🥒 🥔 🍆 🧄 🧅 🫑 🫛"
    categoryEmojis.Tools="🔨 🔧 🪛 🔩 ⚙ 🛠 ⚒ ⛏ 🪓 🪚 ✂ 🗜 🧰 🪜 🧲 📏 📐"
    categoryEmojis.Food=categoryEmojis.Fruits.." "..categoryEmojis.Vegetables.." 🍔 🍟 🍕 🌭 🥪 🌮 🌯 🫔 🥙 🧆 🥚 🍳 🥘 🍲 🫕 🥣 🥗 🍿 🧈 🧂 🥓 🥩 🍗 🍖 🦴 🥐 🥯 🍞 🥖 🥨 🧀 🥞 🧇 🍱 🍘 🍙 🍚 🍛 🍜 🍝 🍠 🍢 🍣 🍤 🍥 🥟 🥠 🥡 🍦 🍧 🍨 🍩 🍪 🎂 🍰 🧁 🥧 🍫 🍬 🍭 🍮 🍯 🍼 🥛 ☕ 🍵 🧃 🥤 🧋 🥥"
    local categoryNames={['สัตว์']='Animals',['ผลไม้']='Fruits',['ผัก']='Vegetables',['อาหาร']='Food',['ของกิน']='Food',['ยานพาหนะ']='Vehicles',['ยานพาหณะ']='Vehicles',['ยาณพาหณะ']='Vehicles',['เครื่องมือ']='Tools'}
    local categorySets={}
    for category,emojis in pairs(categoryEmojis)do
        local set={}
        for emoji in emojis:gmatch("%S+")do set[clean(emoji)]=true end
        categorySets[category]=set
    end
    function Runtime:FindFarmCheckChoice()
        local gui=player:FindFirstChildOfClass("PlayerGui")
        local screen=gui and gui:FindFirstChild("FarmCheck")
        local outer=screen and screen:FindFirstChild("Frame")
        local panel=outer and outer:FindFirstChild("Frame")
        if not panel or not panel:IsA("GuiObject")or not shown(panel)then return end
        local title=panel:FindFirstChild("TextLabel")
        -- Several sibling labels share this name; select the actual question.
        for _,label in ipairs(panel:GetChildren())do
            if label:IsA("TextLabel")and string.find(label.ContentText,"แตะรูป",1,true)then
                title=label;break
            end
        end
        local options=panel:FindFirstChild("Frame")
        if not title or not title:IsA("TextLabel")or not options then return end
        local prompt=clean(title.ContentText)
        if prompt==""then return end
        local requested=prompt:match("^แตะรูป%s*(.-)%s*เพื่อรับงานต่อ")
        local category=requested and categoryNames[clean(requested)]
        local allowed=category and categorySets[category]
        local selected,choice
        local unknown={}
        for _,button in ipairs(options:GetChildren())do
            if button:IsA("GuiButton")and button.Active and shown(button)then
                local matched,known,content
                for _,label in ipairs(button:GetDescendants())do
                    if label:IsA("TextLabel")then
                        local text=clean(label.ContentText)
                        if text~=""then
                            content=content or text
                            for _,set in pairs(categorySets)do if set[text]then known=true;break end end
                        end
                        if text~=""and((allowed and allowed[text])or(not allowed and string.find(prompt,text,1,true)))then matched=text;break end
                    end
                end
                if content and not known then table.insert(unknown,{Button=button,Text=content})end
                if matched then
                    if selected then return end -- Never guess between multiple matching buttons.
                    selected,choice=button,matched
                end
            end
        end
        -- For an unknown Thai category, choose only a unique unclassified option.
        if not selected and not category and requested and clean(requested)~=""and #unknown==1 then
            local categoryQuestion=true
            for _,code in utf8.codes(clean(requested))do
                if code~=32 and(code<0x0E00 or code>0x0E7F)then categoryQuestion=false;break end
            end
            if categoryQuestion then selected,choice=unknown[1].Button,unknown[1].Text end
        end
        return selected,prompt,choice,screen
    end
    Runtime.FarmCheck={Busy=false,LastAttempt=-math.huge,Clicks=0}
    function Runtime:StepFarmCheck()
        local state=self.FarmCheck
        if not autoWorkEnabled()then return end
        if not self.Alive or state.Busy or os.clock()-state.LastAttempt<1.5 then return end
        local button,prompt,choice=self:FindFarmCheckChoice()
        if not button then return end
        state.Prompt,state.Choice=prompt,choice
        -- Call the button's Lua listeners directly; Real's firesignal/Connection:Fire are no-ops.
        local callbacks={}
        for _,connection in ipairs(getconnections(button.Activated))do
            if connection.Enabled and type(connection.Function)=="function"then
                table.insert(callbacks,connection.Function)
            end
        end
        if #callbacks==0 then state.Status="No callable Activated listener";return end
        state.Busy=true;state.LastAttempt=os.clock()
        task.defer(function()
            local ok,message=pcall(function()
                if not autoWorkEnabled()then return end
                local current,currentPrompt=self:FindFarmCheckChoice()
                if current~=button or currentPrompt~=prompt then return end
                for _,callback in ipairs(callbacks)do
                    if not autoWorkEnabled()or not button.Parent or not shown(button)then break end
                    callback()
                end
                state.Clicks+=1;state.Status="Invoked matching choice"
            end)
            state.Busy=false
            if not ok then state.Error=tostring(message)end
        end)
    end
    local elapsed=0
    Runtime:Connect(RunService.Heartbeat,function(dt)
        elapsed+=dt
        if elapsed<.2 then return end
        elapsed=0
        if not autoWorkEnabled()then return end
        local ok,message=pcall(Runtime.StepFarmCheck,Runtime)
        if not ok then Runtime.FarmCheck.Busy=false;Runtime.FarmCheck.Error=tostring(message)end
    end)
end
-- END FARM CHECK

-- Current vehicle handling: modest local multipliers, native speed cap retained.
Runtime.DriveTune={Values=previous and previous.DriveTune and previous.DriveTune.Values or setmetatable({},{__mode="k"}),Drafts=previous and previous.DriveTune and previous.DriveTune.Drafts or setmetatable({},{__mode="k"}),Patches={},Limits={Steer={80,200},Brake={80,250},Launch={80,250}}}
function Runtime:DrivenVehicle()
    local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local seat=h and h.SeatPart
    local folder=workspace:FindFirstChild("SpawnedVehicles")
    if not seat or not folder then return end
    for _,model in ipairs(folder:GetChildren())do
        if seat:IsDescendantOf(model)and model:GetAttribute("OwnerUserId")==player.UserId then
            local driver=model:FindFirstChild("DriverSeat",true)
            if seat:IsA("VehicleSeat")or seat==driver then return model end
        end
    end
end
function Runtime:GetDriveTune(model)
    model=model or self:DrivenVehicle()
    if not model then return end
    local values=self.DriveTune.Values[model]
    if not values then values={Steer=100,Brake=100,Launch=100};self.DriveTune.Values[model]=values end
    return values
end
function Runtime:GetDriveTuneDraft(model)
    model=model or self:DrivenVehicle()
    if not model then return end
    local draft=self.DriveTune.Drafts[model]
    if not draft then draft=table.clone(self:GetDriveTune(model));self.DriveTune.Drafts[model]=draft end
    return draft
end
function Runtime:ApplyDriveTune()
    local model=self:DrivenVehicle()
    if not model then self:Notify("ขึ้นรถที่ต้องการปรับก่อน","Warning");return false end
    local draft=self:GetDriveTuneDraft(model)
    local applied={}
    for key,limit in pairs(self.DriveTune.Limits)do applied[key]=math.clamp(draft[key]or 100,limit[1],limit[2])end
    self.DriveTune.Values[model]=applied
    self:Notify("ปรับแต่งแล้ว","Info")
    return true
end

function Runtime:SetDriveTune(key,value)
    local values=self:GetDriveTuneDraft()
    local limit=self.DriveTune.Limits[key]
    if not values or not limit then return false end
    value=tonumber(value)
    if not value or value~=value then return false end
    values[key]=math.clamp(math.floor(value+.5),limit[1],limit[2])
    return true
end
function Runtime:ClearDriveTune()
    local model=self:DrivenVehicle()
    if model then self.DriveTune.Values[model]={Steer=100,Brake=100,Launch=100};self.DriveTune.Drafts[model]={Steer=100,Brake=100,Launch=100}end
end
function Runtime:AutoBrakeDecel()
    for _,worker in pairs({self.Grab,self.ShopDriver,self.OtherWork and self.OtherWork.Driver})do
        if worker and worker.Running and worker.Config then
            local now=os.clock()
            if not worker.BrakeRampLast or now-worker.BrakeRampLast>.2 then worker.BrakeRampSince=now end
            worker.BrakeRampLast=now
            local ramp=math.clamp((now-(worker.BrakeRampSince or now))/.65,0,1)
            if worker.EmergencyBrake then return 55*(.8+.2*ramp)end
            return math.clamp(worker.Config.ComfortDecel or 38,24,42)*(.55+.45*ramp)
        end
    end
end
function Runtime:InstallDriveTune()
    local function valuesFor(kind)
        if not self.Alive or self.Tune.Busy or self.ShopTravelOn
            or(self.Grab and self.Grab.Running)or(self.OtherWork and self.OtherWork.Running)then return end
        local model=self:DrivenVehicle()
        local def=model and GameShared.vehicle(model:GetAttribute("VehicleId"))
        if not def or(def.category=="Car")~=(kind=="Car")then return end
        return self:GetDriveTune(model)
    end
    for _,entry in ipairs({{Name="PCX160Shared",Kind="Bike"},{Name="CarShared",Kind="Car"}})do
        local shared=require(RS:WaitForChild(entry.Name))
        local oldStep,oldBrake,oldYaw=shared.stepSpeed,shared.brake,shared.yawRate
        local step=function(speed,throttle,top,dt,accel,brake)
            local v=valuesFor(entry.Kind)
            if v and throttle>0 and speed>=0 then
                local kmh=speed*EcuShared.KMH_PER_STUD
                local fade=1-math.clamp((kmh-20)/60,0,1)
                accel=(accel or 1)*(1+(v.Launch/100-1)*fade)
            end
            if v and entry.Kind=="Car"and throttle<0 and speed>0 then brake=(brake or 1)*v.Brake/100 end
            local result=oldStep(speed,throttle,top,dt,accel,brake)
            local comfort=throttle<0 and speed>0 and self:AutoBrakeDecel()or nil
            if comfort and throttle<0 and speed>0 then result=math.max(result,speed-comfort*dt)end
            return result
        end
        local brake=function(speed,dt,...)
            local v=valuesFor(entry.Kind)
            local result=oldBrake(speed,v and dt*v.Brake/100 or dt,...)
            local comfort=self:AutoBrakeDecel()
            if comfort then
                if speed>0 then result=math.max(result,speed-comfort*dt)elseif speed<0 then result=math.min(result,speed+comfort*dt)end
            end
            return result
        end
        local yaw=function(...)
            local v=valuesFor(entry.Kind)
            return oldYaw(...)*(v and v.Steer/100 or 1)
        end
        shared.stepSpeed=step;shared.brake=brake;shared.yawRate=yaw
        table.insert(self.DriveTune.Patches,{Shared=shared,Step=step,Brake=brake,Yaw=yaw,OldStep=oldStep,OldBrake=oldBrake,OldYaw=oldYaw})
    end
end
function Runtime:RestoreDriveTune()
    for _,p in ipairs(self.DriveTune.Patches)do
        if p.Shared.stepSpeed==p.Step then p.Shared.stepSpeed=p.OldStep end
        if p.Shared.brake==p.Brake then p.Shared.brake=p.OldBrake end
        if p.Shared.yawRate==p.Yaw then p.Shared.yawRate=p.OldYaw end
    end
    table.clear(self.DriveTune.Patches)
end
Runtime:InstallDriveTune()



-- Repeated zero-driving races with one chosen recipient.
Runtime.GiveMoney={Enabled=false,Target=nil,PerRound=1000,Total=1000,Sent=0,Seen={},Status="ปิด",NextAction=0,Revision=0}
function Runtime:GiveOpponent(packet)
    if type(packet)~="table"or type(packet.racers)~="table"or(packet.me~=1 and packet.me~=2)then return end
    return packet.racers[3-packet.me],packet.racers[packet.me],3-packet.me
end
function Runtime:ReleaseGiveInputs()
    local run=self.GiveMoney.Hold
    if not run then return end
    self.GiveMoney.Hold=nil
    if getupvalues(run.Step)[run.Index]==run.Replacement then setupvalue(run.Step,run.Index,run.Original)end
    run.Session.braking=run.OldBraking
    if run.Session.seat and run.Session.seat.Parent then run.Session.seat.ThrottleFloat=0;run.Session.seat.SteerFloat=0 end
end
function Runtime:HoldGiveVehicle()
    local model=self:DrivenVehicle()
    if not model then return end
    if self.GiveMoney.Hold and self.GiveMoney.Hold.Model==model then return end
    self:ReleaseGiveInputs()
    local def=GameShared.vehicle(model:GetAttribute("VehicleId"))
    local name=def and def.category=="Car"and"CarClient"or"PCX160Client"
    local driver=require(player.PlayerScripts[name].Driver)
    local session,step
    for _,v in pairs(getupvalues(driver.start))do
        if type(v)=="table"and v.model==model and v.seat==player.Character.Humanoid.SeatPart then session=v end
        if type(v)=="function"and debug.info(v,"n")=="step"then step=v end
    end
    if not session or not step then return end
    for index,input in pairs(getupvalues(step))do
        if type(input)=="function"and debug.info(input,"n")=="keysToSeat"then
            local run={Model=model,Session=session,Step=step,Index=index,Original=input,OldBraking=session.braking}
            run.Replacement=function(current)
                if self.Alive and self.GiveMoney.Enabled and self.GiveMoney.Hold==run and current==session then
                    current.seat.ThrottleFloat=0;current.seat.SteerFloat=0;current.braking=true
                else return input(current)end
            end
            setupvalue(step,index,run.Replacement);self.GiveMoney.Hold=run
            return
        end
    end
end

function Runtime:TweenGiveFoot(goal,active)
    local character=assert(player.Character,"ไม่มีตัวละคร")
    local root=assert(character:FindFirstChild("HumanoidRootPart"),"ตัวละครยังไม่พร้อม")
    local humanoid=assert(character:FindFirstChildOfClass("Humanoid"),"ตัวละครยังไม่พร้อม")
    assert(not humanoid.SeatPart,"ลงจากรถก่อนเดินทาง")
    local originals={}
    local tween,connection
    local support=Instance.new("Part");support.Name="D0TFrostyGiveFoot";support.Anchored=true;support.CanCollide=true
    support.CanTouch=false;support.CanQuery=false;support.Transparency=1;support.Size=Vector3.new(6,.4,6);support.Parent=workspace
    local floorOffset=humanoid.HipHeight+root.Size.Y*.5+.15
    local function cleanup()
        if tween then tween:Cancel()end
        if connection then connection:Disconnect()end
        for part,collide in pairs(originals)do if part.Parent then part.CanCollide=collide end end
        support:Destroy()
        if self.GiveMoney.TravelCleanup==cleanup then self.GiveMoney.TravelCleanup=nil end
    end
    self.GiveMoney.TravelCleanup=cleanup
    connection=RunService.Stepped:Connect(function()
        if not character.Parent or not root.Parent then return end
        for _,part in ipairs(character:GetDescendants())do
            if part:IsA("BasePart")then if originals[part]==nil then originals[part]=part.CanCollide end;part.CanCollide=false end
        end
        root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
        support.CFrame=CFrame.new(root.Position-Vector3.new(0,floorOffset,0))
    end)
    local ok,message=xpcall(function()
        local start=root.Position
        local steps=math.max(1,math.ceil((goal-start).Magnitude/35))
        for i=1,steps do
            assert(active(),"Stopped")
            assert(humanoid.Health>0 and player.Character==character,"ตัวละครเปลี่ยนระหว่างเดินทาง")
            local target=start:Lerp(goal,i/steps)
            local distance=(target-root.Position).Magnitude
            tween=game:GetService("TweenService"):Create(root,TweenInfo.new(math.max(.12,distance/55),Enum.EasingStyle.Linear),{CFrame=CFrame.new(target)*root.CFrame.Rotation})
            tween:Play()
            while tween.PlaybackState==Enum.PlaybackState.Playing do assert(active(),"Stopped");task.wait(.04)end
            task.wait(.08)
            assert((root.Position-target).Magnitude<18,"เกมดึงตัวกลับระหว่างเดินทาง")
        end
    end,tostring)
    cleanup()
    assert(ok,message)
end
function Runtime:TravelGiveLobby(active)
    local state=self.GiveMoney
    state.Status="กำลังรีตัว"
    local old=player.Character
    local h=old and old:FindFirstChildOfClass("Humanoid")
    if h and h.Health>0 then h.Health=0 end
    local deadline=os.clock()+40
    repeat
        assert(active(),"Stopped")
        task.wait(.1)
        local character=player.Character
        h=character and character:FindFirstChildOfClass("Humanoid")
    until(player.Character~=old and h and h.Health>0 and player.Character:FindFirstChild("HumanoidRootPart"))or os.clock()>deadline
    assert(h and h.Health>0 and player.Character~=old,"รอเกิดใหม่เกินเวลา")
    local map=workspace:WaitForChild("Map")
    local gate=map:WaitForChild("DragLobbyGate",10)
    assert(gate,"ไม่พบทางเข้า Racing Lobby")
    local prompt=gate:FindFirstChildWhichIsA("ProximityPrompt",true)
    assert(prompt,"ไม่พบปุ่ม Teleport Racing Lobby")
    local promptPart=prompt.Parent
    if promptPart:IsA("Attachment")then promptPart=promptPart.Parent end
    assert(promptPart:IsA("BasePart"),"จุด Teleport ไม่พร้อม")
    state.Status="กำลังไป Teleport Racing Lobby"
    self:TweenGiveFoot(promptPart.Position+Vector3.new(0,0,4),active)
    assert(active(),"Stopped")
    fireproximityprompt(prompt)
    local hub=map.DragLobby.Hub:GetAttribute("Arrive")
    assert(typeof(hub)=="CFrame","ไม่พบปลายทาง Racing Lobby")
    deadline=os.clock()+12
    repeat assert(active(),"Stopped");task.wait(.1)until(player.Character.HumanoidRootPart.Position-hub.Position).Magnitude<100 or os.clock()>deadline
    assert((player.Character.HumanoidRootPart.Position-hub.Position).Magnitude<100,"เกมยังไม่ Teleport ไป Lobby")
    local target=state.Target and Players:GetPlayerByUserId(state.Target)
    local targetRoot=target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local arenas=map.DragLobby.Arenas
    local chosen,nearest
    for _,arena in ipairs(arenas:GetChildren())do
        local frame=arena:GetAttribute("Frame")
        if typeof(frame)=="CFrame"then
            local entrance=frame:PointToWorldSpace(Vector3.new(-123,3,728))
            local distance=(entrance-(targetRoot and targetRoot.Position or player.Character.HumanoidRootPart.Position)).Magnitude
            if not nearest or distance<nearest then chosen,nearest=arena,distance end
        end
    end
    assert(chosen,"ไม่พบสนามแข่ง")
    local frame=chosen:GetAttribute("Frame")
    local approach=frame:PointToWorldSpace(Vector3.new(-123,3,750))
    state.Status="กำลังไป "..chosen.Name
    self:TweenGiveFoot(approach,active)
    pcall(player.RequestStreamAroundAsync,player,approach,3)
    local pads={}
    deadline=os.clock()+6
    repeat
        assert(active(),"Stopped")
        for lane=1,2 do
            local pad=chosen.Waiting:FindFirstChild("Pad"..lane)
            pads[lane]=pad and pad:FindFirstChild("Base")
        end
        if not pads[1]or not pads[2]then task.wait(.1)end
    until(pads[1]and pads[2])or os.clock()>deadline
    assert(pads[1]and pads[2],"ยังโหลดแท่นแข่งไม่ครบ")
    local selected=1
    if targetRoot and(targetRoot.Position-pads[1].Position).Magnitude<14 then selected=2
    elseif targetRoot and(targetRoot.Position-pads[2].Position).Magnitude<14 then selected=1 end
    local root=player.Character.HumanoidRootPart
    local humanoid=player.Character.Humanoid
    local base=pads[selected]
    local halfHeight=(math.abs(base.CFrame.RightVector.Y)*base.Size.X+math.abs(base.CFrame.UpVector.Y)*base.Size.Y+math.abs(base.CFrame.LookVector.Y)*base.Size.Z)*.5
    local goal=base.Position+Vector3.new(0,halfHeight+humanoid.HipHeight+root.Size.Y*.5,0)
    state.Status="กำลังขึ้นแท่น "..selected
    self:TweenGiveFoot(goal,active)
    state.Anchor=goal;state.Arena=chosen.Name;state.Lane=selected;state.Status="ถึงแท่นแล้ว · รอคนที่เลือก"
end

function Runtime:SetGiveMoney(on)
    local state=self.GiveMoney
    self:ReleaseGiveInputs()
    state.Revision+=1;state.Enabled=on==true
    if state.TravelCleanup then state.TravelCleanup()end
    if not state.Enabled then
        state.Status="ปิด"
        local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if h and not h.SeatPart then h:MoveTo(player.Character:GetPivot().Position)end
        return
    end
    if not state.Target or not Players:GetPlayerByUserId(state.Target)then state.Enabled=false;state.Status="เลือกผู้เล่นที่อยู่ในเซิร์ฟก่อน";return end
    if state.PerRound<1 or state.Total<1 then state.Enabled=false;state.Status="ใส่ยอดเงินให้ถูกก่อน";return end
    if self.ShopTravelOn or(self.Grab and self.Grab.Running)or(self.OtherWork and self.OtherWork.Running)then state.Enabled=false;state.Status="หยุดงานอัตโนมัติก่อน";return end
    state.Sent=0;state.Seen={};state.Round=nil;state.Anchor=nil;state.Travelling=true
    local revision=state.Revision
    task.spawn(function()
        local function active()return self.Alive and state.Enabled and state.Revision==revision end
        local ok,message=xpcall(function()self:TravelGiveLobby(active)end,tostring)
        if state.Revision~=revision or not self.Alive then return end
        state.Travelling=false
        if not ok and state.Enabled then self:SetGiveMoney(false);state.Status="เดินทางไม่สำเร็จ · "..tostring(message)end
    end)
end
function Runtime:GiveResult(packet)
    local state=self.GiveMoney
    local round=state.Round
    if not state.Enabled or not round or packet.id==nil or packet.id~=round.Id or state.Seen[packet.id]then return end
    local other,me,index=self:GiveOpponent(packet)
    if not other or tonumber(other.userId)~=state.Target then return end
    state.Seen[packet.id]=true
    local result=packet.result
    if round.Locked and type(result)=="table"and result.winner==index and(tonumber(result.amount)or 0)>0 and tonumber(packet.bet)==round.Amount then
        state.Sent+=round.Amount;state.Status="ให้สำเร็จ "..state.Sent.." / "..state.Total.." ฿"
    else state.Status="รอบนี้ไม่นับ · ไม่ได้แพ้ให้คนที่เลือกหรือมีการคืนเงิน"end
    state.Round=nil;self:ReleaseGiveInputs()
    if state.Sent>=state.Total then self:SetGiveMoney(false);state.Status="ครบแล้ว · ให้ทั้งหมด "..state.Sent.." ฿"end
end
function Runtime:WalkBackGivePad()
    local state=self.GiveMoney
    local anchor=state.Anchor
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if not anchor or not humanoid or not root or humanoid.SeatPart or state.Walking then return end
    local distance=(anchor-root.Position).Magnitude
    if distance<=4 then return end
    if distance>150 then state.Status="กลับไปยืนที่แท่นเดิมเพื่อทำรอบต่อ";return end
    state.Walking=true;local revision=state.Revision
    task.spawn(function()
        pcall(function()self:TweenGiveFoot(anchor,function()return self.Alive and state.Enabled and state.Revision==revision and not state.Packet end)end)
        state.Walking=false
    end)
end
function Runtime:UpdateGiveMoney()
    local state=self.GiveMoney
    if not state.Enabled or state.Travelling then return end
    if not Players:GetPlayerByUserId(state.Target)then self:SetGiveMoney(false);state.Status="ผู้เล่นที่เลือกออกจากเซิร์ฟแล้ว";return end
    if os.clock()<state.NextAction then return end
    state.NextAction=os.clock()+.6
    local packet=state.Packet
    if not packet then
        self:ReleaseGiveInputs()
        local remaining=(state.CooldownUntil or 0)-workspace:GetServerTimeNow()
        state.Status=remaining>0 and"รอ Bet delay"or"รอแข่งกับคนที่เลือก"
        if remaining<=0 then self:WalkBackGivePad()end
        return
    end
    if type(packet.cooldownEnds)=="number"then state.CooldownUntil=packet.cooldownEnds end
    local other,me,index=self:GiveOpponent(packet)
    if not other or tonumber(other.userId)~=state.Target then
        self:ReleaseGiveInputs();state.Status="คู่แข่งไม่ใช่คนที่เลือก · ไม่ยืนยันเบท";return
    end
    if packet.state=="result"then self:GiveResult(packet);return end
    if packet.state=="bet"then
        local wait=(state.CooldownUntil or 0)-workspace:GetServerTimeNow()
        if wait>0 then state.Status="รอ Bet delay";return end
        local amount=math.floor(math.min(state.PerRound,state.Total-state.Sent,tonumber(packet.betMax)or 10000,
            tonumber(packet.cap)or math.huge,tonumber(me.cash)or 0,tonumber(other.cash)or 0))
        if amount<1 then self:SetGiveMoney(false);state.Status="ยอดคงเหลือหรือเงินที่ใช้เบทไม่พอ";return end
        state.Round={Id=packet.id,Amount=amount,Target=state.Target}
        state.Anchor=player.Character and player.Character:GetPivot().Position or state.Anchor
        if(tonumber(me.offer)or 0)~=amount then Net.fire(Remotes.Duel,"Offer",amount);state.Status="ตั้งเบท "..amount.." ฿";return end
        if(tonumber(other.offer)or 0)~=amount then state.Status="รออีกฝั่งตั้งเบท "..amount.." ฿";return end
        if not me.ready then Net.fire(Remotes.Duel,"Ready",true)end
        state.Status="ยืนยันเบท "..amount.." ฿";return
    end
    if packet.state=="pick"or packet.state=="stage"or packet.state=="race"then
        local round=state.Round
        if not round or round.Id~=packet.id or tonumber(packet.bet)~=round.Amount then
            self:ReleaseGiveInputs();state.Status="เบทไม่ตรงกับรอบที่ยืนยัน · รอจัดการเอง";return
        end
        round.Locked=true
        if packet.state=="pick"and not me.picked then
            local chosen
            for _,vehicle in ipairs(packet.vehicles or{})do if not chosen or vehicle.fav then chosen=vehicle end end
            if chosen then Net.fire(Remotes.Duel,"Pick",chosen.id)end
            state.Status="เลือกรถ · รอเริ่มแข่ง";return
        end
        self:HoldGiveVehicle();state.Status="จอดรอให้คนที่เลือกชนะ";return
    end
end
do
    local duel=Remotes:FindFirstChild("Duel")
    if duel then
        Runtime:Connect(duel.OnClientEvent,function(action,data)
            local state=Runtime.GiveMoney
            if action=="State"and type(data)=="table"then
                state.Packet=data
                if type(data.cooldownEnds)=="number"then state.CooldownUntil=data.cooldownEnds end
                if data.state=="result"then Runtime:GiveResult(data)end
            elseif action=="Clear"or action=="Return"then state.Packet=nil;Runtime:ReleaseGiveInputs()end
        end)
        for _,connection in ipairs(getconnections(duel.OnClientEvent))do
            if connection.Function then for _,value in pairs(getupvalues(connection.Function))do
                if type(value)=="table"and value.state and value.racers and value.me then Runtime.GiveMoney.Packet=value end
            end end
        end
    end
    Runtime:Connect(RunService.Heartbeat,function()Runtime:UpdateGiveMoney()end)
end

local priorWebhook=previous and previous.Webhook
Runtime.Webhook={Enabled=false,URL=priorWebhook and priorWebhook.URL or"",Status="ยังไม่เปิด",Sent=priorWebhook and priorWebhook.Sent or{},Images=priorWebhook and priorWebhook.Images or{}}
function Runtime:WebhookURL(value)
    local url=tostring(value or""):match("^%s*(.-)%s*$")
    local valid=url:match("^https://discord%.com/api/webhooks/%d+/[%w_%-]+$")
        or url:match("^https://discord%.com/api/v%d+/webhooks/%d+/[%w_%-]+$")
        or url:match("^https://discordapp%.com/api/webhooks/%d+/[%w_%-]+$")
    return valid and url or nil
end
function Runtime:SaveWebhookURL(value)
    local url=value==""and""or self:WebhookURL(value)
    if url==nil then return false end
    self.Webhook.URL=url
    if not writefile then return false end
    local ok=pcall(function()
        if makefolder then
            if not isfolder or not isfolder("D0TFrosty X")then makefolder("D0TFrosty X")end
            if not isfolder or not isfolder(Settings.Folder)then makefolder(Settings.Folder)end
        end
        writefile(Settings.Folder.."/WebhookURL_"..player.UserId..".txt",url)
    end)
    return ok
end
do
    local path=Settings.Folder.."/WebhookURL_"..player.UserId..".txt"
    if isfile and readfile then
        local ok,value=pcall(function()return isfile(path)and readfile(path)or nil end)
        if ok and value~=nil then Runtime.Webhook.URL=Runtime:WebhookURL(value)or""end
    end
end
function Runtime:WebhookImage(kind)
    local state=self.Webhook
    if state.Images[kind]then return state.Images[kind]end
    local transport=request or http_request
    if not transport then return end
    local path=kind=="logo"and("assets?assetIds="..Settings.Logo:match("%d+").."&size=420x420&format=Png&isCircular=false")
        or("users/avatar-headshot?userIds="..player.UserId.."&size=420x420&format=Png&isCircular=false")
    local ok,response=pcall(transport,{Url="https://thumbnails.roblox.com/v1/"..path,Method="GET"})
    if ok and type(response)=="table"and response.StatusCode==200 then
        local decoded,data=pcall(Http.JSONDecode,Http,response.Body or"")
        local url=decoded and data.data and data.data[1]and data.data[1].imageUrl
        if type(url)=="string"and url:match("^https://")then state.Images[kind]=url;return url end
    end
end
function Runtime:BuildWorkWebhook(work,amount,seconds,stamp,cash)
    local duration=math.max(0,math.floor(seconds))
    local embed={title="✅ ส่งงานสำเร็จ",description=player.DisplayName.."  ||@"..player.Name.."||",color=16744192,
        author={name="D0TFrosty X MAHANAKHON RACING"},
        fields={{name="อาชีพ",value=work,inline=true},{name="เงินรอบนี้",value=tostring(amount),inline=true},
            {name="เวลารอบนี้",value=string.format("%d นาที %02d วินาที",math.floor(duration/60),duration%60),inline=true}},
        footer={text="D0TFrosty • สรุปต่อหนึ่งงาน"},timestamp=stamp or DateTime.now():ToIsoDate()}
    -- Luau does not implement the locale grouping flag in string.format.
    embed.fields[2].value=tostring(math.floor(amount)):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","").." ฿"
    local balance=math.floor(tonumber(cash)or tonumber(player:GetAttribute("Cash"))or 0)
    table.insert(embed.fields,{name="เงินทั้งหมดตอนนี้",value=tostring(balance):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","").." ฿",inline=true})
    local avatar=self.Webhook.Images.avatar;local logo=self.Webhook.Images.logo
    if avatar then embed.thumbnail={url=avatar}end
    if logo then embed.author.icon_url=logo;embed.footer.icon_url=logo end
    local body={username="D0TFrosty X MAHANAKHON RACING",allowed_mentions={parse={}},embeds={embed}}
    if logo then body.avatar_url=logo end
    return body
end
function Runtime:SendWorkWebhook(key,work,amount,seconds)
    local state=self.Webhook;local url=self:WebhookURL(state.URL)
    if not state.Enabled or not url or state.Sent[key]then return end
    local transport=request or http_request
    if not transport then state.Status="ไม่พบระบบส่ง HTTP";return end
    state.Sent[key]="pending";local stamp=DateTime.now():ToIsoDate();local cash=player:GetAttribute("Cash")or 0
    task.spawn(function()
        self:WebhookImage("logo");self:WebhookImage("avatar")
        local body=Http:JSONEncode(self:BuildWorkWebhook(work,amount,seconds,stamp,cash))
        for attempt=1,3 do
            if not self.Alive then return end
            state.Status="กำลังส่งสรุปงาน"
            local ok,response=pcall(transport,{Url=url.."?wait=true",Method="POST",Headers={["Content-Type"]="application/json"},Body=body})
            local code=ok and type(response)=="table"and response.StatusCode or 0
            if code>=200 and code<300 then state.Sent[key]="sent";state.Status="ส่งสรุปงานแล้ว";return end
            if code~=429 then state.Status="ส่งไม่สำเร็จ (HTTP "..tostring(code)..")";state.Sent[key]=nil;return end
            local parsed,data=pcall(Http.JSONDecode,Http,response.Body or"")
            task.wait(math.clamp(parsed and tonumber(data.retry_after)or 2,1,30))
        end
        state.Sent[key]=nil;state.Status="Discord จำกัดการส่ง ลองใหม่ในงานถัดไป"
    end)
end
function Runtime:Notify(text,kind)
    if self.Alive and self.Window then self.Window:Notify({Title="จูนรถ",Content=tostring(text),Type=kind or"Info",Duration=5})end
end
function Runtime:SetFPS(value)setfpscap(math.clamp(math.floor(tonumber(value)or 120),30,2000))end
function Runtime:PreventIdle()
    local ok,message=pcall(function()
        local virtual=game:GetService("VirtualUser")
        local camera=workspace.CurrentCamera
        virtual:CaptureController()
        virtual:ClickButton2(Vector2.new(0,0),camera and camera.CFrame or CFrame.new())
    end)
    self.IdleProtection={Ready=ok,LastAttempt=os.clock(),Error=not ok and tostring(message)or nil}
    return ok
end
Runtime:Connect(player.Idled,function()Runtime:PreventIdle()end)
function Runtime:GetCashText()
    local amount=tostring(math.floor(tonumber(player:GetAttribute("Cash"))or 0))
    return "Cash : "..amount:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
end
function Runtime:JoinDiscord()
    if self.DiscordBusy then return end
    self.DiscordBusy=true
    task.spawn(function()
        local Request=request or http_request or(syn and syn.request)
        local opened=false
        if Request then
            for port=6463,6472 do
                if not self.Alive then break end
                local success,response=pcall(Request,{
                    Url="http://127.0.0.1:"..port.."/rpc?v=1",Method="POST",
                    Headers={["Content-Type"]="application/json",["Origin"]="https://discord.com"},
                    Body=Http:JSONEncode({cmd="INVITE_BROWSER",nonce=Http:GenerateGUID(false),args={code="tgv4ywuGSg"}}),
                    Timeout=1
                })
                if success and type(response)=="table"and response.StatusCode==200 then opened=true;break end
            end
        end
        self.DiscordBusy=false
        if opened then self:Notify("เปิดคำเชิญใน Discord แล้ว")
        else
            if setclipboard then setclipboard("https://discord.gg/tgv4ywuGSg")end
            self:Notify("เปิด Discord ไม่สำเร็จ คัดลอกลิงก์คำเชิญแล้ว","Warning")
        end
    end)
end
local function copy(file)
    local out={};for _,def in ipairs(EcuShared.TABLES)do out[def.key]=table.clone(file[def.key])end;return out
end
local function decode(value)
    local ok,result=pcall(function()return EcuShared.decode(value)end);return ok and result or nil
end
local function validFile(file)
    if type(file)~="table"then return false end
    for _,def in ipairs(EcuShared.TABLES)do
        if type(file[def.key])~="table"or#file[def.key]~=EcuShared.POINTS then return false end
        for _,value in ipairs(file[def.key])do if type(value)~="number"or value~=value or value<def.min-.0001 or value>def.max+.0001 then return false end end
    end;return true
end
local function vehicleId(vehicle)return vehicle:GetAttribute("VehicleId")or vehicle.Name end
-- Server-verified ECU presets: version 877, six tables at 100%, 66/66 values read back.
-- User-supplied formulas; credit KINGJOPEN where supplied.
Runtime.Presets={}
Runtime.Presets.LEAD25F={sourceVersion=948,verifiedSlots=66,file={Air={1.08,1.12,1.06,1.07,1,1.02,1.12,1.15,1.25,1.26,1.38},Fuel={1.12,1.02,1.04,1.13,1.17,1.18,1.17,1.11,1.05,1.09,1.2},Afr={12.6,11.9,12.3,13,13,12.3,12.3,12.5,12.1,11.4,11.7},Tps={1.06,1.12,1.03,0.92,0.89,0.97,1.13,1.27,1.33,1.26,1.14},Oil={0.08,0.16,0.22,0.1,0.08,0.2,0.3,0.29,0.36,0.47,0.41},Ign={14.2,17.3,20.2,22.2,23.2,22.5,22.8,26.4,30,30.5,31.1}}}
Runtime.Presets.DREAM_RACE={sourceVersion=877,verifiedSlots=66,file={Air={1,0.95,0.89,0.91,1.05,1.12,1.11,1.11,1.05,0.92,0.91},Fuel={1,0.99,0.93,0.96,1.03,1.07,1.17,1.23,1.13,1.06,1.09},Afr={12.6,12.7,13,13.3,12.7,12.3,12.1,11.7,11.9,11.7,11.2},Tps={0.81,0.85,0.94,1.16,1.24,1.23,1.12,1.05,1.14,1.28,1.47},Oil={0.11,0.16,0.19,0.14,0.21,0.3,0.42,0.49,0.49,0.55,0.6},Ign={12.7,15.1,18.4,21.6,23.1,21.9,20.6,21.5,23.3,26,28.6}}}
Runtime.Presets.FK8={sourceVersion=877,verifiedSlots=66,file={Air={1.03,1.12,1.15,1.03,0.93,0.89,0.96,1.09,1.15,1.17,1.09},Fuel={0.99,1.02,0.98,1.13,1.11,1.16,1.19,1.28,1.24,1.26,1.35},Afr={12.3,11.7,11.6,12.1,12.6,12.6,12.5,12.5,12.4,11.9,11.5},Tps={1.06,1.12,1.07,1.1,1.28,1.37,1.27,1.17,1.24,1.34,1.29},Oil={0.09,0.08,0.19,0.36,0.44,0.4,0.31,0.27,0.32,0.45,0.56},Ign={16,16.9,17.8,19.9,20.2,19.2,21.9,24.7,24.9,26.5,28.9}}}
Runtime.Presets.FLAT150={sourceVersion=877,verifiedSlots=66,file={Air={1.07,1,0.98,1.02,1.04,1.06,1.06,1.06,1.12,1.14,1.06},Fuel={1.05,1.15,1.19,1.16,1.18,1.1,1.21,1.25,1.18,1.18,1.09},Afr={11.9,12.5,13.5,13.7,12.9,12.4,12.2,11.9,12.1,12.6,12.6},Tps={0.91,1.08,1.08,1,1.05,1.09,1.04,1,1.13,1.22,1.16},Oil={0.1,0.12,0.2,0.22,0.2,0.28,0.37,0.4,0.48,0.57,0.55},Ign={14.8,16.2,15,14.8,16.5,21.6,24.8,25.3,28.4,28.4,26.2}}}
Runtime.Presets.GIORNO23={sourceVersion=877,verifiedSlots=66,file={Air={1.24,1.19,1.17,1.2,1.17,1.17,1.12,1.16,1.25,1.29,1.32},Fuel={1.09,1.19,1.22,1.11,1.14,1.19,1.11,1.1,1.12,1,0.99},Afr={12.7,12.6,12.6,11.7,11.6,11.8,11.5,11.9,12,11.4,12},Tps={1.04,1.08,1.06,1.01,1.01,1.07,1.1,1.1,1.18,1.31,1.31},Oil={0.08,0.08,0.08,0.11,0.24,0.28,0.33,0.29,0.28,0.25,0.24},Ign={12.2,12.4,13.6,16.2,17.3,17.9,20.7,23.2,22.5,22.4,24.7}}}
Runtime.Presets.LEAD25={sourceVersion=877,verifiedSlots=66,file={Air={1.02,1.06,1.17,1.25,1.24,1.21,1.22,1.2,1.12,1.08,1.14},Fuel={1.12,1.14,1.08,1.15,1.13,1.02,1.09,1.17,1.15,1.25,1.31},Afr={13.3,12.3,12.1,12.4,12.6,12.2,13.1,13.3,12.7,12.8,12.7},Tps={0.85,0.9,0.85,1.03,1.05,1.19,1.15,1.18,1.09,1.05,0.98},Oil={0.08,0.1,0.16,0.24,0.2,0.3,0.28,0.2,0.24,0.34,0.41},Ign={12.8,15.3,16.3,19.4,19.5,19.5,22.3,22.7,25.2,28,30.4}}}
Runtime.Presets.LEAD25G={sourceVersion=877,verifiedSlots=66,file={Air={0.97,1.02,1.06,1.14,1.17,1.07,0.96,0.97,1.03,1.08,1.13},Fuel={1.17,1.17,1.21,1.19,1.21,1.16,1.15,1.15,1.19,1.26,1.26},Afr={12.7,13,13.3,12.3,12,12.8,12.8,12.9,13.6,13.3,12.2},Tps={1.12,1.23,1.27,1.18,1.24,1.23,1.15,1.06,1.09,1.17,1.12},Oil={0.34,0.33,0.32,0.37,0.45,0.46,0.4,0.33,0.32,0.37,0.41},Ign={12.3,14.8,16.3,19.5,21.2,20.2,23.1,24.6,26.7,28,30.6}}}
Runtime.Presets.MAXI250={sourceVersion=877,verifiedSlots=66,file={Air={1.12,1.05,1.03,1.12,1.18,1.23,1.3,1.27,1.15,1.13,1.17},Fuel={1.15,1.12,1.06,0.97,1.05,1.11,1.17,1.27,1.21,1.1,1.03},Afr={12.8,12.3,12.6,12.3,11.9,12.2,12.5,12.4,12.1,12.6,12.2},Tps={0.91,0.86,0.87,1.01,1.11,1.09,1.12,1.27,1.32,1.24,1.26},Oil={0.18,0.23,0.33,0.41,0.38,0.35,0.41,0.47,0.43,0.41,0.49},Ign={11.4,11.4,12.7,15.1,18.3,21.3,23.2,23.3,22.3,21.7,22.9}}}
Runtime.Presets.NMAX20={sourceVersion=877,verifiedSlots=66,file={Air={1.14,1.1,1.18,1.16,1.08,1.17,1.08,1.03,1.12,1.04,1.07},Fuel={1.09,1.01,0.97,0.99,0.91,0.9,1.08,1.17,1.15,1.18,1.14},Afr={13,12.9,12.6,12.4,12.4,12.4,12.7,13,12.7,12,11.9},Tps={1.17,1.08,0.95,0.96,0.95,0.96,1.13,1.28,1.31,1.38,1.37},Oil={0.1,0.16,0.21,0.27,0.28,0.22,0.16,0.2,0.32,0.4,0.38},Ign={12.6,12.5,15.3,19.3,20.8,22.1,22.5,25.6,28.3,28.3,32}}}
Runtime.Presets.PCX160={sourceVersion=877,verifiedSlots=66,file={Air={1.03,1.07,1.15,1.05,1.04,1.03,1.11,1.23,1.26,1.29,1.18},Fuel={1.01,1.11,1.17,1.16,1.21,1.12,1.08,1.08,1.02,1.08,1.09},Afr={12.7,13.1,12.9,12.8,12.7,12,11.3,11.6,12.8,13.5,12.5},Tps={0.98,1.02,0.97,0.99,1.21,1.23,1.14,1.15,1.08,1.06,1.24},Oil={0.16,0.14,0.09,0.14,0.15,0.33,0.36,0.48,0.5,0.54,0.59},Ign={14.4,16.4,17.7,18.1,20.1,23.2,23.7,21.7,22.2,25.7,28}}}
Runtime.Presets.PCX160SA={sourceVersion=877,verifiedSlots=66,file={Air={1.13,1.15,1.16,1.18,1.06,1.08,1.21,1.2,1.21,1.21,1.3},Fuel={1.01,1.03,0.97,1.02,1.11,1.11,1.13,1.14,1.14,1.1,1},Afr={12.4,12.8,12.5,12.9,13.1,12.9,13.5,13.6,12.9,12.8,12.5},Tps={1.04,1.17,1.16,1.1,1.22,1.26,1.15,1.18,1.24,1.13,1.08},Oil={0.08,0.17,0.2,0.11,0.17,0.24,0.2,0.22,0.31,0.39,0.41},Ign={12.2,13.1,16.8,17.3,19,18.7,20.6,22.1,21.9,23.5,24.1}}}
Runtime.Presets.SPORT155={sourceVersion=877,verifiedSlots=66,file={Air={0.9,1,1.14,1.2,1.16,1.09,1.05,1.05,1.15,1.29,1.36},Fuel={1.1,1.15,1.24,1.17,1.19,1.24,1.26,1.21,1.05,1.07,1.07},Afr={13.4,13.5,13.5,13.5,12.8,12.8,12.4,12,11.7,11.7,12},Tps={0.97,1.05,1.05,0.92,1.06,1.01,1,0.93,1.11,1.18,1.14},Oil={0.1,0.12,0.14,0.15,0.19,0.23,0.26,0.26,0.24,0.23,0.22},Ign={13.3,15.9,16.3,18.2,18.2,20.1,22,26,29.2,31.7,32.5}}}
Runtime.Presets.SPORT_STEP={sourceVersion=877,verifiedSlots=66,file={Air={1.17,1.11,0.97,0.94,1.04,1.17,1.22,1.18,1.1,1.05,1.08},Fuel={1.05,1,1.02,1.1,1.13,1.09,1.07,1.12,1.17,1.15,1.07},Afr={12.2,12.3,13,13,13.4,12.4,12.1,11.5,11.5,12,11.9},Tps={0.92,0.92,1.07,1.25,1.26,1.18,1.18,1.18,1.17,1.25,1.39},Oil={0.08,0.15,0.17,0.25,0.29,0.2,0.24,0.3,0.4,0.59,0.59},Ign={13.1,14.9,15.6,18.8,22.2,21.8,22.8,22.2,22.5,24.5,23}}}
Runtime.Presets.STREET160={sourceVersion=877,verifiedSlots=66,file={Air={1.02,1.04,1.09,1.07,0.94,0.89,0.99,1.11,1.13,1.12,1.09},Fuel={1.25,1.12,1.11,1.11,1.2,1.26,1.23,1.19,1.08,1.13,1.14},Afr={12.5,11.6,11.9,12.2,12.8,12.7,12.5,12.6,12.7,13.1,12.3},Tps={1.02,0.97,1.03,1.13,1.2,1.22,1.19,1.14,1.09,1.06,1.05},Oil={0.08,0.1,0.2,0.25,0.23,0.2,0.2,0.25,0.35,0.44,0.5},Ign={12,16,15.9,18.9,21.7,23.5,25.7,25.5,29.1,29.5,29.4}}}
Runtime.Presets.TOURER350={sourceVersion=877,verifiedSlots=66,file={Air={0.99,1.04,1.08,1,1.02,1.07,1.11,1.25,1.33,1.23,1.22},Fuel={1.23,1.11,1.2,1.11,1.05,1.03,1.16,1.06,1.16,1.19,1.12},Afr={11.8,11.8,12.2,11.6,12.2,12.4,13.1,12.8,12.4,12.5,12.1},Tps={1.02,1.07,1.1,1.13,1.12,1.06,1.04,1.09,1.17,1.21,1.25},Oil={0.32,0.22,0.21,0.26,0.36,0.33,0.35,0.47,0.48,0.44,0.38},Ign={14.3,17.7,17.3,18.1,17.5,18.9,19.4,18.4,20.9,22.9,27.2}}}
Runtime.Presets.TYPER23={sourceVersion=877,verifiedSlots=66,file={Air={1.02,1.05,1.08,1.07,1.07,1.13,1.19,1.14,1,0.9,0.94},Fuel={1.05,1.17,1.22,1.18,1.24,1.33,1.25,1.12,1.18,1.27,1.22},Afr={13.3,14,13.9,13.2,12.5,12.1,12.4,13,13.1,12.6,12.2},Tps={1.07,1.17,1.17,1.2,1.21,1.15,1.15,1.25,1.24,1.14,1.18},Oil={0.17,0.24,0.26,0.24,0.22,0.24,0.28,0.28,0.26,0.26,0.31},Ign={12.5,12.7,15.3,17.4,21.7,22.8,25,24,25.6,26.3,30.2}}}
Runtime.Presets.VESPA_S={sourceVersion=877,verifiedSlots=66,file={Air={1.09,1.17,1.22,1.2,1.19,1.23,1.2,1.11,1.14,1.21,1.17},Fuel={1.21,1.12,1.15,1.12,1.11,1.02,1.04,1.17,1.17,1.25,1.26},Afr={14,13.6,12.2,12.3,13,13.6,14,12.5,11.5,11.4,11.8},Tps={0.89,0.94,1.02,1.02,1.05,1.08,1.03,0.97,1.01,1.07,1.07},Oil={0.08,0.11,0.19,0.33,0.43,0.36,0.37,0.38,0.33,0.45,0.61},Ign={18,19,20.1,22.7,20.7,21.4,24.4,22.7,24,25.9,28.3}}}
Runtime.Presets.WAVE_KAGE={sourceVersion=877,verifiedSlots=66,file={Air={1.13,1.19,1.15,1.16,1.16,1.24,1.35,1.29,1.23,1.14,1.17},Fuel={0.96,1.06,1.04,1.02,1.07,1.18,1.18,1.16,1.22,1.29,1.28},Afr={13.6,13.5,13,12.5,12.3,12.4,12.4,12.2,12.1,12.4,12.7},Tps={0.94,1.04,1.17,1.23,1.19,1.24,1.09,1.03,1.09,1.11,1.24},Oil={0.18,0.1,0.13,0.17,0.16,0.18,0.25,0.32,0.39,0.43,0.45},Ign={10.6,14.2,16,16.5,19.1,21.5,20.5,19,21.3,25.1,27}}}
Runtime.Presets.WAVE_SILVER={sourceVersion=877,verifiedSlots=66,file={Air={1.09,1.2,1.17,1.15,1.17,1.12,1.08,1.08,1.16,1.24,1.16},Fuel={1.07,1.01,0.99,1.02,1.09,1.17,1.21,1.22,1.2,1.14,1.06},Afr={14.1,13.9,13.4,12.9,12.4,12.6,13,12.8,12.7,12.4,11.9},Tps={0.99,1.09,1.15,1.18,1.21,1.28,1.3,1.2,1.15,1.21,1.18},Oil={0.23,0.17,0.21,0.16,0.18,0.16,0.27,0.44,0.49,0.46,0.3},Ign={15.1,14.7,18.2,20.1,19.9,22.7,25.5,24.6,25.1,28.1,28.4}}}
Runtime.Presets.WAVE_STREET={sourceVersion=877,verifiedSlots=66,file={Air={1.11,1.08,1.04,1.04,1.13,1.19,1.29,1.27,1.25,1.21,1.18},Fuel={1.04,1.14,1.08,0.97,1,1.03,1.02,1.08,1.12,1.09,1.18},Afr={13.5,13.4,13.3,12.6,11.5,11.5,12.2,12.2,12,12.8,13.3},Tps={0.84,0.94,1.09,1.1,1.17,1.26,1.25,1.19,1.14,1.15,1.14},Oil={0.08,0.08,0.15,0.32,0.34,0.31,0.35,0.35,0.4,0.53,0.59},Ign={12.6,14.2,17.3,17.8,20.5,21.1,19.8,21.9,23.5,27.9,30.5}}}
Runtime.Presets.WAVE_WHITE={sourceVersion=877,verifiedSlots=66,file={Air={1.22,1.18,1.2,1.23,1.19,1.12,1.16,1.25,1.27,1.21,1.22},Fuel={0.98,0.98,1.06,1.07,1.04,1.13,1.14,0.98,0.94,1.04,1.01},Afr={12.2,11.8,12.9,12.9,12.7,12.9,12.8,12.1,12.2,13.1,12.6},Tps={1.01,0.97,0.97,0.99,0.96,1.07,1.24,1.26,1.2,1.21,1.2},Oil={0.21,0.32,0.38,0.45,0.42,0.38,0.44,0.43,0.48,0.53,0.6},Ign={10.6,14.2,15.9,15.4,15,16.1,18.7,21.7,23.8,24.4,23.8}}}
Runtime.Presets.XMAX={sourceVersion=877,verifiedSlots=66,file={Air={1.09,1.1,1.13,1.05,1.08,1.05,1.09,1.2,1.18,1.21,1.11},Fuel={1.08,1.11,1.06,1.03,1.07,1.04,0.94,0.94,1.02,1,0.93},Afr={13.2,12.8,12.7,12.2,11.7,12,12.2,12.5,12.9,12.7,12.7},Tps={1.17,1.14,1.1,1.04,0.97,1.02,1.08,1.12,1.25,1.25,1.06},Oil={0.27,0.29,0.32,0.22,0.25,0.2,0.31,0.32,0.46,0.48,0.61},Ign={13.3,15.5,14.6,14.5,17.4,19.8,20.4,22.3,26.1,29,31.1}}}
Runtime.Presets.XMAX23W={sourceVersion=877,verifiedSlots=66,file={Air={1.22,1.14,1.18,1.09,1.16,1.19,1.3,1.34,1.3,1.24,1.14},Fuel={1.2,1.19,1.12,1.03,1.01,1.09,1.15,1.15,1.16,1.22,1.27},Afr={13.3,13.4,13.3,13.4,13.5,12.9,12.1,12.2,12.5,12.3,12.1},Tps={1.11,1.18,1.1,1.17,1.09,1.15,1.06,1.12,1.05,1.14,1.11},Oil={0.1,0.09,0.09,0.08,0.08,0.11,0.13,0.15,0.23,0.29,0.31},Ign={10.3,11,13.1,17.7,20,22.5,21.2,21.3,21.7,24.4,28.7}}}
-- Entitlement required: retain these formulas without applying or marking them verified.
-- User-supplied KINGJOPEN formulas; live 100% feedback has not been verified for these three.
Runtime.Presets.CITY150={sourceVersion=877,verifiedSlots=66,credit="KINGJOPEN",userReported100=true,file={Air={1.02,1.08,1.09,1.03,0.92,0.87,0.95,1.07,1.13,1.13,1.1},Fuel={1.02,1.06,1.01,1.05,0.96,0.93,0.96,0.96,1.1,1.1,1.14},Afr={11.7,12,12.6,12.6,13.1,12.6,12.8,12.1,12.4,11.7,12.1},Tps={0.95,1.02,1.1,1.18,1.19,1.17,1.25,1.34,1.3,1.21,1.18},Oil={0.29,0.21,0.16,0.15,0.16,0.19,0.29,0.39,0.42,0.38,0.35},Ign={12.2,14.4,16.1,18.3,20.7,21.2,21.3,23.1,24.6,24.9,25.5}}}
Runtime.Presets.WAVE_110I={sourceVersion=877,verifiedSlots=66,credit="KINGJOPEN",userReported100=true,file={Air={1.04,1.13,1.11,1.04,0.98,0.97,1.05,1.15,1.17,1.19,1.18},Fuel={1.17,1.09,1.12,1.12,1.08,1.17,1.29,1.22,1.08,1.07,1.09},Afr={12.8,12.4,13.1,13.8,13.6,13.5,13.3,12.1,11.5,11.7,11.6},Tps={1,1.02,1,0.98,0.99,1.07,1.21,1.31,1.32,1.24,1.18},Oil={0.1,0.09,0.21,0.08,0.13,0.18,0.17,0.14,0.28,0.29,0.26},Ign={13.7,15.1,16.8,16.8,18.2,19.6,23.2,25.5,27.5,27.1,27.2}}}
Runtime.Presets.FK8T={sourceVersion=877,verifiedSlots=66,credit="KINGJOPEN",userReported100=true,file={Air={1.11,1.14,1.07,1.13,1.14,1.12,1.18,1.14,1.24,1.32,1.31},Fuel={1.09,1.12,1.12,1.12,1.17,1.24,1.25,1.23,1.25,1.27,1.25},Afr={13.5,13.8,14,13.5,13.3,13.5,13,12.5,12.4,11.9,11.8},Tps={0.82,0.94,1,1.02,1.13,1.3,1.31,1.22,1.23,1.29,1.23},Oil={0.11,0.12,0.17,0.3,0.31,0.2,0.15,0.21,0.22,0.19,0.29},Ign={14.8,19,21,19.9,19.8,21.4,21.9,22.7,26.1,29.7,31.8}}}
Runtime.PendingPresets={}
Runtime.PendingPresets.GIORNO25D={sourceVersion=861,reason="Needs Giorno Custom pass; not verified",file={Air={1.04,1,0.99,1,1,1.03,1.11,1.15,1.12,1.12,1.2},Fuel={1.01,1.03,1.14,1.27,1.32,1.26,1.19,1.18,1.19,1.18,1.16},Afr={14.5,14.4,12.9,12.4,12.4,12.5,12.9,13.2,13.3,12.1,10.9},Tps={0.95,0.94,0.99,1.08,1.14,1.11,1.05,1.02,1.02,1.07,1.18},Oil={0.39,0.36,0.27,0.24,0.28,0.37,0.48,0.58,0.58,0.54,0.55},Ign={12,12.4,13.8,16.6,18.8,19.4,19.9,21.3,23.1,24.4,25.5}}}
Runtime.PendingPresets.GIORNO25T={sourceVersion=861,reason="Needs Giorno Custom pass; not verified",file={Air={1.04,1,0.99,1,1,1.03,1.11,1.15,1.12,1.12,1.2},Fuel={1.01,1.03,1.14,1.27,1.32,1.26,1.19,1.18,1.19,1.18,1.16},Afr={14.5,14.4,12.9,12.4,12.4,12.5,12.9,13.2,13.3,12.1,10.9},Tps={0.95,0.94,0.99,1.08,1.14,1.11,1.05,1.02,1.02,1.07,1.18},Oil={0.39,0.36,0.27,0.24,0.28,0.37,0.48,0.58,0.58,0.54,0.55},Ign={12,12.4,13.8,16.6,18.8,19.4,19.9,21.3,23.1,24.4,25.5}}}
-- BEGIN CALIBRATED ECU PRESETS
Runtime.Presets.PCX160B={sourceVersion=877,verifiedSlots=66,file={Air={0.96,0.97,1.02,1.14,1.13,1.06,1.12,1.17,1.13,1.15,1.22},Fuel={1.02,0.98,1.04,1.09,1.07,1.06,1.08,1.06,1.07,1.14,1.17},Afr={12.5,12.8,12.7,12.5,12.4,12.7,12.5,12.4,11.7,11.8,11.8},Tps={0.97,0.93,0.91,0.97,0.96,1.02,1.2,1.27,1.26,1.32,1.34},Oil={0.11,0.2,0.27,0.22,0.14,0.14,0.19,0.21,0.21,0.21,0.21},Ign={17,17,17.7,18,20.1,24.5,26,27.7,31.8,31.9,30.6}}}
Runtime.Presets.DREAM_DRAG={sourceVersion=877,verifiedSlots=66,file={Air={1.16,1.13,1.14,1.25,1.18,1.19,1.24,1.18,1.12,1.1,1.11},Fuel={1.13,1.16,1.17,1.14,1.08,0.97,0.91,0.95,1.07,1.17,1.14},Afr={12.9,12.4,12.3,12.9,12.7,12.9,13.3,12.8,12.8,13,12.3},Tps={1.05,0.98,1.03,1.12,1.07,1,1.11,1.28,1.32,1.3,1.41},Oil={0.15,0.25,0.24,0.29,0.26,0.3,0.29,0.28,0.23,0.16,0.15},Ign={13.7,14.7,16.8,18.2,19.8,19.7,19.6,20.4,21.2,23.4,24.3}}}
Runtime.Presets.WAVE_BARE={sourceVersion=877,verifiedSlots=66,file={Air={0.84,0.91,1.02,1.04,1.09,1.12,1.04,0.96,0.95,0.93,0.97},Fuel={0.96,0.92,1.02,1.09,1.05,1.13,1.23,1.2,1.17,1.2,1.17},Afr={13,12.9,12.9,13.3,13,12.5,13.4,13.4,13.1,12.1,11.6},Tps={1.06,0.98,0.95,1,1,0.94,0.99,1.12,1.16,1.17,1.25},Oil={0.25,0.18,0.16,0.22,0.31,0.36,0.36,0.36,0.41,0.47,0.51},Ign={15.1,16.4,16.9,17.9,19.4,22.3,23.9,24.2,26.2,27.1,27.1}}}
Runtime.Presets.WAVE125S={sourceVersion=877,verifiedSlots=66,file={Air={0.99,1,0.99,1.04,1.13,1.15,1.09,1.02,1.01,1.06,1.09},Fuel={1,1.01,1.01,1.08,1.16,1.14,1.09,1.07,1.05,1.06,1.17},Afr={11.9,12,11.9,12.5,13,13.1,13.3,13.1,13,13.1,12.5},Tps={1.2,1.23,1.12,1.02,1.02,1.04,1.05,1.1,1.14,1.12,1.07},Oil={0.08,0.15,0.22,0.16,0.13,0.19,0.2,0.14,0.18,0.31,0.34},Ign={16.6,16,17.8,20,20.2,21,24,26.5,27.3,28.2,29.5}}}
Runtime.Presets.XMAX23G={sourceVersion=877,verifiedSlots=66,file={Air={1.01,0.99,1.11,1.14,1.1,1.08,1.16,1.2,1.1,1.17,1.26},Fuel={1.03,1.05,1.02,1.09,1.14,1.09,1.06,1.11,1.2,1.27,1.29},Afr={13.6,14,13.5,12.7,12.5,12.9,12.8,12.1,11.6,11.9,12.5},Tps={1.03,1.05,1.03,1.02,1.05,1.06,1.03,1.06,1.16,1.2,1.19},Oil={0.08,0.13,0.14,0.19,0.31,0.34,0.43,0.48,0.48,0.57,0.58},Ign={13.6,15.9,16.1,15.2,17.2,17.8,20.3,21.7,26.1,25.4,26.9}}}
-- END CALIBRATED ECU PRESETS
function Runtime:FindVehicle()
    local folder=workspace:FindFirstChild("SpawnedVehicles");if not folder then return nil end
    local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    for _,vehicle in ipairs(folder:GetChildren())do
        if vehicle:GetAttribute("OwnerUserId")==player.UserId and(self.SelectedVehicle=="Current"or vehicleId(vehicle)==self.SelectedVehicle)then
            if self.SelectedVehicle~="Current"or not humanoid or not humanoid.SeatPart or humanoid.SeatPart:IsDescendantOf(vehicle)then return vehicle end
        end
    end
    if self.SelectedVehicle=="Current"then for _,v in ipairs(folder:GetChildren())do if v:GetAttribute("OwnerUserId")==player.UserId then return v end end end
end
local function signature(vehicle)
    local fields={vehicleId(vehicle)}
    local attrs=vehicle:GetAttributes();local keys={}
    for key in pairs(attrs)do if key=="EngineLevel"or key:find("Piston")or key:find("Bore")then table.insert(keys,key)end end
    table.sort(keys);for _,key in ipairs(keys)do table.insert(fields,key.."="..tostring(attrs[key]))end
    return table.concat(fields,"|")
end
function Runtime:SaveTune(vehicle,file,gain,feedback)
    if not validFile(file)then return end
    local id=vehicleId(vehicle);local old=self.Cache[id]
    if old and old.signature==signature(vehicle)and(old.gain or 0)>gain then return end
    self.Cache[id]={vehicleId=id,signature=signature(vehicle),file=copy(file),gain=gain,feedback=feedback,updated=os.time(),code=old and old.code or nil}
    local ok,err=pcall(function()makefolder(Settings.Folder);writefile(cachePath,Http:JSONEncode(self.Cache))end)
    if not ok then self.Tune.CacheError=tostring(err)end
end
function Runtime:GetTrack()
    local vehicle=self:FindVehicle();local entry=vehicle and self.Cache[vehicleId(vehicle)]or self.Cache[self.SelectedVehicle]
    local feedback,gain={},1
    if self.Tune.Busy then feedback,gain=self.Tune.Feedback,self.Tune.Gain
    elseif vehicle then feedback,gain=decode(vehicle:GetAttribute("EcuFeedback"))or{},EcuShared.gain(vehicle)
    elseif entry then feedback,gain=entry.feedback or{},entry.gain or 1 end
    local top
    if vehicle then
        local _,_,mult=GameShared.upgradeScales(vehicle)
        local def=GameShared.vehicle(vehicleId(vehicle));local tuck=def and def.category~="Car"and vehicle:GetAttribute("Tuck")==true
        top=GameShared.driveTop(vehicle,mult,tuck and BikeShared.TUCK_SPEED_BONUS or 1)*EcuShared.KMH_PER_STUD
    end
    return {Status=self.Tune.Status,Feedback=feedback,Gain=gain,TopKmh=top,Code=self.Tune.Code or"",Saved=entry~=nil,Tests=self.Tune.Tests or 0,Vehicle=vehicle and vehicleId(vehicle)or self.SelectedVehicle}
end
function Runtime:TuneError(message)
    local raw=tostring(message or "")
    self.Tune.LastError=raw
    local value=raw:gsub("^.-:%d+:%s*","")
    for _,point in utf8.codes(value)do if point>=0x0E00 and point<=0x0E7F then return value end end
    local lower=value:lower()
    if lower:find("cooldown",1,true)or lower:find("slow down",1,true)or lower:find("still writing",1,true)then return "ระบบกำลังเขียนค่าจูน รอสักครู่แล้วลองใหม่"end
    if lower:find("money",1,true)or lower:find("cash",1,true)or lower:find("afford",1,true)or lower:find("fund",1,true)then return "เงินไม่พอสำหรับรายการนี้"end
    if lower:find("code",1,true)then return "ใช้โค้ดจูนไม่ได้ ตรวจโค้ดและรุ่นรถแล้วลองใหม่"end
    if lower:find("own",1,true)or lower:find("locked",1,true)or lower:find("pass",1,true)then return "ใช้รถคันนี้ไม่ได้ ตรวจว่ามีรถและปลดล็อกแล้วหรือยัง"end
    return "จูนไม่สำเร็จ ลงจากรถแล้วเข้าใกล้จุดจูนข้างห้องไดโน ที่อู่ AUTOWORKS จากนั้นกดจูนใหม่"
end
function Runtime:SelectVehicle(id)
    if self.Tune.Busy then self:Notify("หยุดจูนก่อนเปลี่ยนรถ","Warning");return false end
    self.SelectedVehicle=id;self.Tune.Code="";self.Tune.Status=self.Cache[id]and"Saved tune available"or"Idle";return true
end
function Runtime:MoveToTuneBay(vehicle)
    local character=assert(player.Character,"ไม่พบตัวละคร รอเกิดใหม่แล้วลองอีกครั้ง")
    local humanoid=assert(character:FindFirstChildOfClass("Humanoid"),"ไม่พบตัวละคร รอเกิดใหม่แล้วลองอีกครั้ง")
    local root=assert(character:FindFirstChild("HumanoidRootPart"),"ไม่พบตัวละคร รอเกิดใหม่แล้วลองอีกครั้ง")
    local state=player:GetAttribute("DeliveryState")
    assert(state~="ToShop"and state~="ToHome","ส่งผู้โดยสารให้เสร็จก่อนจูนรถ")
    local parked=vehicle and GameShared.inTuneBay(vehicle)
    local bay,radius=GameShared.tuneBay(parked and vehicle:GetPivot().Position or root.Position)
    assert(bay,"ลงจากรถแล้วเข้าใกล้จุดจูนข้างห้องไดโน ที่อู่ AUTOWORKS")
    local distance=(root.Position-bay.Position).Magnitude
    assert(distance<=180,"อยู่ไกลจุดจูนเกินไป ลงจากรถแล้วเข้าใกล้จุดจูนข้างห้องไดโน ที่อู่ AUTOWORKS")
    if parked and humanoid.SeatPart and humanoid.SeatPart:IsDescendantOf(vehicle)then return end
    local target=bay.Position+Vector3.new(0,3,0)
    if parked then
        local pivot=vehicle:GetPivot()
        local near=pivot.Position+pivot.RightVector*4
        local offset=Vector3.new(near.X-bay.Position.X,0,near.Z-bay.Position.Z)
        local limit=math.max(1,radius-3)
        if offset.Magnitude>limit then offset=offset.Unit*limit end
        target=bay.Position+offset+Vector3.new(0,3,0)
    end
    if (root.Position-target).Magnitude<4 then return end
    self.Tune.Status="กำลังพาตัวละครไปจุดจูน"
    if humanoid.SeatPart then
        local seated=humanoid.SeatPart:FindFirstAncestorOfClass("Model")
        local definition=seated and GameShared.vehicle(vehicleId(seated))
        if definition and definition.category=="Car"then Net.fire(RS.CarRemote,"Exit",seated)
        else Net.fire(RS.PCX160Remote,"Dismount","Start")end
        local deadline=os.clock()+6
        while humanoid.SeatPart and os.clock()<deadline and self.Alive and not self.Tune.Cancel do task.wait(.1)end
        assert(not humanoid.SeatPart,"ลงจากรถก่อน แล้วเข้าใกล้จุดจูนข้างห้องไดโน")
        task.wait(1.2)
    end
    assert(self.Alive and not self.Tune.Cancel,"หยุดจูนแล้ว")
    local service=game:GetService("TweenService")
    local deadline=os.clock()+math.max(15,(root.Position-target).Magnitude/25+10)
    while (root.Position-target).Magnitude>2 do
        assert(self.Alive and not self.Tune.Cancel,"หยุดจูนแล้ว")
        assert(character==player.Character and root.Parent and humanoid.Health>0,"ตัวละครเปลี่ยนหรือเสียชีวิต กดจูนใหม่อีกครั้ง")
        assert(os.clock()<deadline,"เดินทางไปโซนจูนไม่สำเร็จ ลองเข้าใกล้อู่ก่อน")
        local delta=target-root.Position
        local nextPoint=root.Position+delta.Unit*math.min(20,delta.Magnitude)
        local destination=CFrame.new(nextPoint)*root.CFrame.Rotation
        local tween=service:Create(root,TweenInfo.new((nextPoint-root.Position).Magnitude/35,Enum.EasingStyle.Linear),{CFrame=destination})
        self.Tune.MoveTween=tween;tween:Play()
        repeat task.wait(.03)until tween.PlaybackState~=Enum.PlaybackState.Playing or not self.Alive or self.Tune.Cancel or character~=player.Character or humanoid.Health<=0
        tween:Cancel();self.Tune.MoveTween=nil
        root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
    end
    assert(self.Alive and not self.Tune.Cancel,"หยุดจูนแล้ว")
    task.wait(.5)
    local delta=root.Position-bay.Position
    assert(Vector3.new(delta.X,0,delta.Z).Magnitude<math.max(2,radius-2)and math.abs(delta.Y)<12,"เข้าโซนจูนไม่สำเร็จ ลงจากรถแล้วเข้าใกล้จุดจูนข้างห้องไดโน")
end
function Runtime:PrepareTuneVehicle()
    local character=assert(player.Character,"ไม่พบตัวละคร รอเกิดใหม่แล้วลองอีกครั้ง");local humanoid=character:FindFirstChildOfClass("Humanoid")
    local root=assert(character:FindFirstChild("HumanoidRootPart"),"ไม่พบตัวละคร รอเกิดใหม่แล้วลองอีกครั้ง")
    local vehicle=self:FindVehicle()
    self:MoveToTuneBay(vehicle)
    if not vehicle or not GameShared.inTuneBay(vehicle)then
        local bay,radius=GameShared.tuneBay(root.Position)
        assert(bay and(Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(bay.Position.X,0,bay.Position.Z)).Magnitude<math.max(2,radius-2),"ลงจากรถแล้วเข้าใกล้จุดจูนข้างห้องไดโน ที่อู่ AUTOWORKS")
        local state=player:GetAttribute("DeliveryState")
        assert(state~="ToShop"and state~="ToHome","ส่งผู้โดยสารให้เสร็จก่อนเรียกรถมาจูน")
        if humanoid.SeatPart then
            local seated=humanoid.SeatPart:FindFirstAncestorOfClass("Model")
            if seated and GameShared.vehicle(vehicleId(seated))and GameShared.vehicle(vehicleId(seated)).category=="Car"then Net.fire(RS.CarRemote,"Exit",seated)
            else Net.fire(RS.PCX160Remote,"Dismount","Start")end
            local deadline=os.clock()+6;while humanoid.SeatPart and os.clock()<deadline do task.wait(.1)end
            assert(not humanoid.SeatPart,"ลงจากรถก่อน แล้วกดจูนใหม่");task.wait(1.2)
        end
        local list=Net.invoke(Remotes.Garage,"List");assert(type(list)=="table","โหลดข้อมูลโรงรถไม่ได้ ลองใหม่อีกครั้ง")
        local id=self.SelectedVehicle=="Current"and(list.active or player:GetAttribute("ActiveVehicle")or"PCX160")or self.SelectedVehicle
        local allowed=false;for _,entry in ipairs(list.vehicles or{})do if entry.id==id then allowed=true end end;assert(allowed,"ไม่มีรถรุ่นนี้ในโรงรถ หรือยังไม่ได้ปลดล็อก")
        task.wait(math.max(.85,tonumber(list.cooldown)or 0))
        local ok,message=Net.invoke(Remotes.Garage,"Spawn",id);assert(ok,tostring(message));task.wait(.8)
        for _,v in ipairs(workspace.SpawnedVehicles:GetChildren())do if v:GetAttribute("OwnerUserId")==player.UserId and vehicleId(v)==id then vehicle=v;break end end
    end
    assert(vehicle and GameShared.inTuneBay(vehicle),"ลงจากรถแล้วเข้าใกล้จุดจูนข้างห้องไดโน ที่อู่ AUTOWORKS")
    if not humanoid.SeatPart or not humanoid.SeatPart:IsDescendantOf(vehicle)then
        self:MoveToTuneBay(vehicle)
        local def=GameShared.vehicle(vehicleId(vehicle));local car=def and def.category=="Car"
        if car then Net.fire(RS.CarRemote,"Enter",vehicle,"Driver")else Net.fire(RS.PCX160Remote,"Mount",vehicle,"Drive")end
        local deadline=os.clock()+5;while not humanoid.SeatPart and os.clock()<deadline do task.wait(.1)end
        assert(humanoid.SeatPart and humanoid.SeatPart:IsDescendantOf(vehicle),"ขึ้นรถไม่ได้ ลงจากรถแล้วเข้าใกล้รถในโซนจูน จากนั้นกดจูนใหม่")
    end
    self.Tune.PreviousTuning=player:GetAttribute("Tuning");self.Tune.PreviousHold=vehicle:GetAttribute("TuneHold")==true
    local held,message=Net.invoke(Remotes.TuneShop,"Hold",vehicle,true);assert(held,tostring(message))
    player:SetAttribute("Tuning",true);self.Tune.Vehicle=vehicle;self.Tune.Prepared=true
    return vehicle
end
function Runtime:CheckTune()
    assert(self.Alive and not self.Tune.Cancel,"หยุดจูนแล้ว")
    local vehicle=self.Tune.Vehicle
    assert(vehicle and vehicle.Parent and vehicle:GetAttribute("OwnerUserId")==player.UserId,"ไม่พบรถที่เลือก เรียกรถออกมาก่อนแล้วลองใหม่")
    assert(GameShared.inTuneBay(vehicle),"ลงจากรถแล้วเข้าใกล้จุดจูนข้างห้องไดโน ที่อู่ AUTOWORKS")
end
function Runtime:Flash(vehicle,file,allowStopped)
    if not allowStopped then self:CheckTune()end
    assert(validFile(file),"สูตรจูนไม่ครบหรือไม่ถูกต้อง ลองเลือกสูตรใหม่")
    local lastMessage
    for attempt=1,4 do
        local remaining=(self.Tune.LastSend or 0)+(EcuShared.SEND_COOLDOWN or 2)+.3-os.clock()
        while remaining>0 do
            if not allowStopped then self:CheckTune()end
            task.wait(math.min(.1,remaining))
            remaining=(self.Tune.LastSend or 0)+(EcuShared.SEND_COOLDOWN or 2)+.3-os.clock()
        end
        if not allowStopped then self:CheckTune()end
        self.Tune.LastSend=os.clock()
        local ok,message,gain,feedback=Net.invoke(Remotes.Ecu,"Send",vehicle,file)
        if ok then
            assert(type(gain)=="number"and type(feedback)=="table","เกมส่งผลจูนกลับมาไม่ครบ ลองใหม่อีกครั้ง")
            self.Tune.Tests=(self.Tune.Tests or 0)+1;return gain,feedback
        end
        lastMessage=tostring(message)
        local text=lastMessage:lower()
        if not(text:find("still writing",1,true)or text:find("slow down",1,true)or text:find("cooldown",1,true))then error(lastMessage,0)end
    end
    error(lastMessage or"ติดต่อระบบจูนไม่ได้ ลองใหม่อีกครั้ง",0)
end
local function totalScore(gain)
    if gain<1 then return(gain-.6)/.8 end;return .5+.5*math.sqrt(math.max(0,gain-1))
end
function Runtime:Optimize(vehicle)
    local decoded=decode(vehicle:GetAttribute("EcuFile"))
    local best=validFile(decoded)and copy(decoded)or EcuShared.stockFile()
    local cached=self.Cache[vehicleId(vehicle)]
    if cached and validFile(cached.file)then best=copy(cached.file)end
    local gain,feedback=self:Flash(vehicle,best)
    local function remember()
        self.Tune.Best=copy(best);self.Tune.Gain=gain;self.Tune.Feedback=feedback;self:SaveTune(vehicle,best,gain,feedback)
    end
    remember()
    if gain>=EcuShared.GAIN_MAX then return end
    -- Coarse probes locate the useful range of each table; retain only improvements.
    if gain<1.1 then
        local categoryBest=table.clone(feedback);local categoryFile=copy(best)
        for grid=0,10 do
            self.Tune.Status="Coarse tune "..grid.."/10"
            local file=EcuShared.stockFile()
            for _,def in ipairs(EcuShared.TABLES)do local value=math.round((def.min+(def.max-def.min)*grid/10)/def.step)*def.step
                for index=1,EcuShared.POINTS do file[def.key][index]=value end
            end
            local _,scores=self:Flash(vehicle,file)
            for _,def in ipairs(EcuShared.TABLES)do if scores[def.key]>(categoryBest[def.key]or 0)then categoryBest[def.key]=scores[def.key];categoryFile[def.key]=table.clone(file[def.key])end end
        end
        local g,f=self:Flash(vehicle,categoryFile);if g>gain then best,gain,feedback=categoryFile,g,f;remember()end
    end
    for _,def in ipairs(EcuShared.TABLES)do
        if(feedback[def.key]or 0)>=1 then continue end
        for index=1,EcuShared.POINTS do
            self:CheckTune();if gain>=EcuShared.GAIN_MAX then break end
            self.Tune.Status="Tuning "..def.key.." "..index.."/"..EcuShared.POINTS
            local current=best[def.key][index];local base=copy(best);base[def.key][index]=def.max
            local zero=self:Flash(vehicle,base);local zeroScore=totalScore(zero)
            local quality=math.clamp((totalScore(gain)-zeroScore)*#EcuShared.TABLES*EcuShared.POINTS,0,1)
            local probe=current
            if quality<.02 then for _,offset in ipairs({-.75,.75,-1.5,1.5,-2.25,2.25})do
                local value=math.clamp(math.round((current+offset*def.tol)/def.step)*def.step,def.min,def.max)
                local file=copy(best);file[def.key][index]=value;local g,f=self:Flash(vehicle,file)
                local q=math.clamp((totalScore(g)-zeroScore)*#EcuShared.TABLES*EcuShared.POINTS,0,1)
                if g>gain then best,gain,feedback=file,g,f;remember()end
                if q>.04 then probe,quality=value,q;break end
            end end
            local distance=def.tol*(1-quality);local seen={}
            for _,sign in ipairs({-1,1})do
                local centre=math.round((probe+sign*distance)/def.step)*def.step
                local offsets=gain<1.2 and{-1,0,1}or{0}
                for _,offset in ipairs(offsets)do
                    local value=math.clamp(math.round((centre+offset*def.step)/def.step)*def.step,def.min,def.max)
                    local key=string.format("%.4f",value)
                    if not seen[key]and math.abs(value-best[def.key][index])>def.step*.1 then
                        seen[key]=true;local file=copy(best);file[def.key][index]=value
                        local g,f=self:Flash(vehicle,file);if g>gain then best,gain,feedback=file,g,f;remember()end
                    end
                end
            end
            remember()
        end
    end
    -- Resolve the last native slider-step differences after the coarse percentage reaches its ceiling.
    for round=1,2 do
        if gain>=EcuShared.GAIN_MAX then break end
        for _,def in ipairs(EcuShared.TABLES)do
            if(feedback[def.key]or 0)>=1 then continue end
            for index=1,EcuShared.POINTS do
                if gain>=EcuShared.GAIN_MAX then break end
                self.Tune.Status="Fine tune "..def.key.." "..index.."/"..EcuShared.POINTS
                local current=best[def.key][index]
                for _,offset in ipairs({-def.step,def.step})do
                    local file=copy(best);file[def.key][index]=math.clamp(math.round((current+offset)/def.step)*def.step,def.min,def.max)
                    local g,f=self:Flash(vehicle,file);if g>gain then best,gain,feedback=file,g,f;remember()end
                end
            end
        end
    end
    local g,f=self:Flash(vehicle,best);gain,feedback=g,f;remember()
end
function Runtime:StopTune()if self.Tune.Busy then self.Tune.Cancel=true;self.Tune.Status="กำลังหยุดจูน"end end
function Runtime:ResolveTuneFile(vehicle)
    local id=vehicleId(vehicle)
    local entry=self.Cache[id]
    -- Keep a complete saved recipe; otherwise load the model's supplied recipe.
    local complete=entry and validFile(entry.file)and(entry.gain or 0)>=EcuShared.GAIN_MAX
    if complete then for _,def in ipairs(EcuShared.TABLES)do
        if type(entry.feedback)~="table"or(entry.feedback[def.key]or 0)<1 then complete=false;break end
    end end
    if complete then return entry.file,"Saved"end
    local preset=self.Presets[id]or self.PendingPresets[id]
    if preset and validFile(preset.file)then return preset.file,"Preset"end
    if entry and validFile(entry.file)then return entry.file,"Saved"end
end
function Runtime:ApplySavedTune(vehicle)
    local file=self:ResolveTuneFile(vehicle)
    assert(validFile(file),"ยังไม่มีชุดค่าจูนสำหรับรถคันนี้")
    file=copy(file)
    self.Tune.Status="กำลังใช้ชุดค่าจูนที่บันทึกไว้"
    local gain,feedback=self:Flash(vehicle,file)
    self.Tune.Gain,self.Tune.Feedback=gain,feedback
    self.Tune.Applied=true
end
function Runtime:BeginTuneAction(action)
    if self.PistonHop and self.PistonHop.Enabled then self:Notify("หยุดค้นหาลูกสูบก่อนจูนรถ","Warning");return end
    if self.ShopTravelOn then self:Notify("หยุดเดินทางไปร้านก่อนจูนรถ","Warning");return end
    if self.Grab and self.Grab.Running then self:Notify("หยุดทำงานอัตโนมัติก่อนจูนรถ","Warning");return end
    if self.Tune.Busy then self:Notify("กำลังจูนอยู่ รอให้เสร็จก่อน","Warning");return end
    if env.__MahanakhonEcuWorker and env.__MahanakhonEcuWorker.Tune.Busy then self:Notify("กำลังหยุดการจูนครั้งก่อน รอสักครู่","Warning");return end
    self.Tune.Busy=true;self.Tune.Action=action;self.Tune.Cancel=false;self.Tune.Tests=0;self.Tune.Status="Preparing vehicle";self.Tune.Best=nil;self.Tune.Applied=false
    self.Tune.Vehicle=nil;self.Tune.Prepared=false
    env.__MahanakhonEcuWorker=self
    task.spawn(function()
        local ok,err=xpcall(function()
            local vehicle=self:PrepareTuneVehicle()
            if action=="Saved"then self:ApplySavedTune(vehicle)
            elseif action=="Optimize"then self:Optimize(vehicle)
            elseif action=="Share"then
                assert(vehicle:GetAttribute("EcuFile")~=nil,"จูนรถคันนี้ก่อนสร้างโค้ดจูน")
                local accepted,message,code=Net.invoke(Remotes.Ecu,"Share",vehicle)
                assert(accepted,tostring(message));assert(type(code)=="string","เกมยังไม่ส่งโค้ดจูนกลับมา ลองใหม่อีกครั้ง")
                self.Tune.Code=code
                local entry=self.Cache[vehicleId(vehicle)];if entry then entry.code=code;pcall(function()writefile(cachePath,Http:JSONEncode(self.Cache))end)end
                if setclipboard then setclipboard(code)end
            else
                local code=EcuShared.cleanCode(self.Tune.Code)
                if code then
                    local accepted,message,gain,feedback=Net.invoke(Remotes.Ecu,"Redeem",vehicle,self.Tune.Code)
                    assert(accepted,tostring(message));self.Tune.Gain,self.Tune.Feedback=gain,feedback
                else
                    assert(self.Tune.Code=="","โค้ดจูนไม่ถูกต้อง ตรวจโค้ดแล้วลองใหม่")
                    self:ApplySavedTune(vehicle)
                end
            end
        end,function(message)return self:TuneError(message)end)
        local vehicle=self.Tune.Vehicle
        if self.Tune.Best and vehicle and vehicle.Parent and GameShared.inTuneBay(vehicle)then
            local restored,gain,feedback=pcall(function()return self:Flash(vehicle,self.Tune.Best,true)end)
            if restored then self.Tune.Gain,self.Tune.Feedback=gain,feedback;self:SaveTune(vehicle,self.Tune.Best,gain,feedback)end
        end
        if vehicle and vehicle.Parent and not self.Tune.PreviousHold then pcall(Net.invoke,Remotes.TuneShop,"Hold",vehicle,false)end
        if self.Tune.Prepared then
            if self.Tune.PreviousTuning~=nil then player:SetAttribute("Tuning",self.Tune.PreviousTuning)else player:SetAttribute("Tuning",nil)end
        end
        self.Tune.Busy=false
        self.Tune.Status=ok and(action=="Share"and"Tune code created"or self.Tune.Gain>=EcuShared.GAIN_MAX and"Tune complete: 100%"or self.Tune.Applied and"ใช้ค่าจูนแล้ว"or"Tune saved")or(self.Tune.Cancel and"หยุดจูนแล้ว"or tostring(err))
        if env.__MahanakhonEcuWorker==self then env.__MahanakhonEcuWorker=nil end
        if not ok and not self.Tune.Cancel then self:Notify(err,"Error")end
    end)
end


local function shopPosition(shop,locations)
    local spots=workspace:FindFirstChild("Map")and workspace.Map:FindFirstChild("PistonShopSpots")
    if spots then for _,spot in ipairs(spots:GetChildren())do if spot:IsA("BasePart")then locations[spot.Name]=spot.Position end end end
    if not shop then return nil end
    local id=shop:GetAttribute("Spot")
    if id and locations[id]then return locations[id]end
    local part=shop:FindFirstChild("HumanoidRootPart",true)or shop:FindFirstChildWhichIsA("BasePart",true)
    if part then if id then locations[id]=part.Position end;return part.Position end
    local seller=shop:FindFirstChild("Seller")
    if seller and seller:IsA("Model")then
        local position=seller:GetPivot().Position
        if position.Magnitude>1 then if id then locations[id]=position end;return position end
    end
end
function Runtime:SaveShopHistory()
    if not writefile then return end
    pcall(function()
        if makefolder then makefolder("D0TFrosty X");makefolder(Settings.Folder)end
        writefile(Settings.Folder.."/PistonClock.json",Http:JSONEncode({JobId=game.JobId,History=self.ShopHistory}))
    end)
end
function Runtime:LoadShopHistory()
    self.ShopHistory={}
    if isfile and readfile then
        pcall(function()
            local path=Settings.Folder.."/PistonClock.json"
            if isfile(path)then
                local data=Http:JSONDecode(readfile(path))
                if data.JobId==game.JobId and type(data.History)=="table"then self.ShopHistory=data.History end
            end
        end)
    end
end
Runtime:LoadShopHistory()
function Runtime:GetPistonTrack()
    local shop=workspace:FindFirstChild("PistonShop");local now=workspace:GetServerTimeNow()
    local closes=shop and tonumber(shop:GetAttribute("ClosesAt"))
    local spot=shop and shop:GetAttribute("Spot")
    local open=shop~=nil and(not closes or closes>now)
    local history=self.ShopHistory
    local changed=false
    if closes and history.KnownClosesAt~=closes then history.KnownClosesAt=closes;changed=true end
    if spot and history.LastSpot~=spot then history.LastSpot=spot;changed=true end
    local position=shopPosition(shop,self.ShopLocations)
    if position then
        local old=history.LastPosition
        if not old or old.X~=position.X or old.Y~=position.Y or old.Z~=position.Z then
            history.LastPosition={X=position.X,Y=position.Y,Z=position.Z};changed=true
        end
    end
    if not open and tonumber(history.KnownClosesAt)and history.KnownClosesAt<=now
        and(not history.LastClosedAt or history.LastClosedAt<history.KnownClosesAt)then
        history.LastClosedAt=history.KnownClosesAt;history.CloseSource="Server";changed=true
    end
    if self.Shop.WasOpen==true and not open then
        local closed=tonumber(history.KnownClosesAt)
        if not closed or math.abs(now-closed)>10 then closed=now;history.CloseSource="Observed"end
        if not history.LastClosedAt or closed>history.LastClosedAt then history.LastClosedAt=closed;changed=true end
    end
    self.Shop.WasOpen=open
    if changed then self:SaveShopHistory()end
    local key=open and(tostring(spot)..":"..tostring(closes))or"closed"
    if self.Shop.Key~=key then self.Shop.Key=key;self.Shop.Marked=open end
    if not position and history.LastPosition then
        local last=history.LastPosition
        if type(last.X)=="number"and type(last.Y)=="number"and type(last.Z)=="number"then position=Vector3.new(last.X,last.Y,last.Z)end
    end
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local distance=root and position and(Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(position.X,0,position.Z)).Magnitude*.28
    local nextOpen=not open and history.LastClosedAt and(history.LastClosedAt+900)or nil
    return {Open=open,Spot=spot or history.LastSpot,Position=position,ClosesIn=closes and math.max(0,closes-now),
        Distance=distance,Key=key,LastClosedAt=history.LastClosedAt,CloseSource=history.CloseSource,
        OpensAt=nextOpen,OpensIn=nextOpen and math.max(0,nextOpen-now),AwaitingOpen=nextOpen and nextOpen<=now}
end
Runtime.PistonStock=previous and previous.PistonStock or{Items={},Status="ยังไม่ได้ตรวจสต๊อก"}
function Runtime:RefreshPistonStock()
    local stock=self.PistonStock
    if stock.Busy then return end
    local state=self:GetPistonTrack()
    if not state.Open then stock.Status="ร้านปิดอยู่";stock.Items={};return end
    if self:CapturePistonStockUI(state.Key)then return end
    stock.Busy=true;stock.Status="กำลังตรวจสต๊อก"
    task.spawn(function()
        local ok,success,data=pcall(Net.invoke,Remotes.Piston,"Shop")
        if not self.Alive then return end
        stock.Busy=false
        local current=self:GetPistonTrack()
        if not current.Open or current.Key~=state.Key then stock.Items={};stock.Status="ร้านเปลี่ยนรอบแล้ว";return end
        if ok and success and type(data)=="table"and type(data.items)=="table"then
            local items={}
            for _,item in pairs(data.items)do
                if type(item)=="table"and type(item.size)=="number"and type(item.left)=="number"then items[item.size]=math.max(0,math.floor(item.left))end
            end
            stock.Items=items;stock.Key=state.Key;stock.UpdatedAt=workspace:GetServerTimeNow();stock.Status="สต๊อกล่าสุดจากร้าน"
        else
            stock.Items={};stock.Key=nil;stock.Status="ยังอ่านสต๊อกไม่ได้ · ลองเข้าใกล้ร้าน"
        end
    end)
end
function Runtime:ClearShopMarker()
    if self.Shop.MarkerPart then self.Shop.MarkerPart:Destroy()end
    self.Shop.MarkerPart=nil;self.Shop.Marker=nil
end
function Runtime:SetShopMarked(enabled)
    self.Shop.Marked=enabled==true
    if not self.Shop.Marked then self:ClearShopMarker()end
end
function Runtime:UpdateShopMarker()
    local state=self:GetPistonTrack()
    if not self.Shop.Marked or not state.Open or not state.Position then self:ClearShopMarker();return end
    if not self.Shop.MarkerPart then
        local template=player.PlayerGui:FindFirstChild("WorkMarker")
        local part=Instance.new("Part");part.Name="D0TFrostyPistonMark";part.Size=Vector3.one
        part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Transparency=1;part.Parent=workspace.CurrentCamera
        local marker
        if template and template:IsA("BillboardGui")then marker=template:Clone()else
            marker=Instance.new("BillboardGui")
            local label=Instance.new("TextLabel");label.Name="Title";label.BackgroundTransparency=1;label.Size=UDim2.fromScale(1,1);label.Font=Enum.Font.GothamBold;label.TextColor3=Color3.fromRGB(255,214,80);label.TextStrokeColor3=Color3.fromRGB(15,18,24);label.TextStrokeTransparency=.1;label.TextWrapped=true;label.Parent=marker
        end
        marker.Name="PistonShopMark";marker.Enabled=true;marker.AlwaysOnTop=true;marker.LightInfluence=0;marker.MaxDistance=100000;marker.StudsOffsetWorldSpace=Vector3.new(0,7,0);marker.Adornee=part;marker.Size=UDim2.fromOffset(180,80);marker.Parent=part
        for _,label in ipairs(marker:GetChildren())do if label:IsA("TextLabel")then label.Size=UDim2.new(1,0,0,44);label.TextSize=14 end end
        self.Shop.MarkerPart=part;self.Shop.Marker=marker
    end
    self.Shop.MarkerPart.CFrame=CFrame.new(state.Position)
    for _,label in ipairs(self.Shop.Marker:GetChildren())do if label:IsA("TextLabel")then
        label.Text="ร้านค้าลูกสูบ\n"..(state.Distance and("%.0f ม."):format(state.Distance)or"")
    end end
end

Runtime.ShopVehicleFuel=previous and previous.ShopVehicleFuel or{}
Runtime.ShopVehicleLast=previous and previous.ShopVehicleLast
function Runtime:IsPassengerLeg(state,encoded)
    if state~="ToHome"then return false end
    local ok,data=pcall(Http.JSONDecode,Http,encoded or"")
    if not ok or type(data)~="table"then return true end
    return data.kind~="food"and data.kind~="parcel"
end
function Runtime:CanEmptyVehicleTween(model)
    if self:IsPassengerLeg(player:GetAttribute("DeliveryState"),player:GetAttribute("DeliveryJob"))then return false end
    local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not model then return false end
    if model:GetAttribute("HasPassenger")==true then return false end
    for _,part in ipairs(model:GetDescendants())do
        if(part:IsA("Seat")or part:IsA("VehicleSeat"))and part.Occupant and part.Occupant~=humanoid then return false end
    end
    return true
end

function Runtime:CanVehicleTween(model)
    local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    return model~=nil and model.Parent~=nil and model:GetAttribute("OwnerUserId")==player.UserId
        and h~=nil and h.Health>0 and h.SeatPart~=nil and h.SeatPart:IsDescendantOf(model)
end
function Runtime:IsSharpDriveTurn(angle)
    return type(angle)=="number"and angle>=math.rad(35)
end

function Runtime:CanShopVehicleTween(origin,finish,heading,arrival)
    local delta=Vector3.new(finish.X-origin.X,0,finish.Z-origin.Z)
    if delta.Magnitude<.1 then return false end
    -- The main road uses opposite signs of X for its two carriageways.
    if math.abs(origin.X)<=90 and math.abs(finish.X)<=90 and origin.X*finish.X<0 then return false end
    if not arrival then
        local forward=Vector3.new(heading.X,0,heading.Z)
        if forward.Magnitude<.1 or forward.Unit:Dot(delta.Unit)<.92 then return false end
        if math.abs(delta.X)>math.max(5,delta.Magnitude*.2)then return false end
        if delta.Magnitude>35 then return false end
    elseif delta.Magnitude>45 then return false end
    return true
end

function Runtime:PickShopVehicle(list,bikesOnly)
    local spawned=workspace:FindFirstChild("SpawnedVehicles")
    for _,vehicle in ipairs(spawned and spawned:GetChildren()or{})do
        if vehicle:GetAttribute("OwnerUserId")==player.UserId then
            local id=vehicle:GetAttribute("VehicleId")
            local fuel=tonumber(vehicle:GetAttribute("Fuel"))
            if id and fuel then self.ShopVehicleFuel[id]=fuel end
        end
    end
    local choices,alternatives={},{}
    for _,entry in ipairs(list.vehicles or{})do
        local definition=GameShared.vehicle(entry.id)
        if definition and not entry.locked and(not bikesOnly or definition.category~="Car")and(self.ShopVehicleFuel[entry.id]==nil or self.ShopVehicleFuel[entry.id]>5)then
            table.insert(choices,entry.id)
            if entry.id~=self.ShopVehicleLast and entry.id~=list.active then table.insert(alternatives,entry.id)end
        end
    end
    local pool=#alternatives>0 and alternatives or choices
    assert(#pool>0,"ไม่พบรถที่พร้อมเดินทาง · รถที่ตรวจแล้วน้ำมันหมด")
    local id=pool[math.random(1,#pool)]
    self.ShopVehicleLast=id
    return id
end

local buildStationWorker
local function buildGrabWorker(owner,vehicleId,jobId)
    jobId=jobId or"Grab"
    local mode=jobId=="Courier"and"parcel"or jobId=="Delivery"and"food"or"grab"
    local jobLabel=JobShared.job(jobId).th
    local Graph=require(RS.RoadGraph)
    local PistonShared=require(RS.PistonShared)
    local GearShared=require(RS.GearShared)
    local PathfindingService=game:GetService("PathfindingService")
    local CareShared=require(RS.CareShared)
    local ShopShared=require(RS.ShopShared)
    local HttpService=Http
    local Config={JobId=jobId,Mode=mode,VehicleId=vehicleId or"Current",ObstacleTween=true,TurnTween=true,KeepShopLane=false,DirectMainRoad=true,MaxTrips=0,ComfortDecel=38,TurnGain=1,CurveAccel=32,BrakeZone=230,
        StopRadius=22,LaneOffset=28,TripTimeout=600,ApproachSpeed=12,StallTimeout=180}
    local Worker:any={JobId=jobId,Config=Config,Running=false,Cancelled=false,Status="พร้อม",Trips=0,Earned=0,PeakSpeed=0,FuelSpent=0,Recoveries=0}
local session
local sessionHumanoid
local sessionKind
local boosted = {}
local constraints = {}
local excluded = {}
local originalFilter
local inputPatches = {}
local motionPatches = {}
local castParams=RaycastParams.new();castParams.FilterType=Enum.RaycastFilterType.Exclude;castParams.RespectCanCollide=true
local oldWheelie
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function cancelled()
    return Worker.Cancelled or not owner.Alive
end
local function status(message)
    Worker.Status = message
    owner.Farm.Status=message
end
local function manualVerificationVisible()
    local gui=player:FindFirstChild("PlayerGui")
    local prompt=gui and gui:FindFirstChild("FarmCheck")
    if not prompt or not prompt:IsA("ScreenGui")or not prompt.Enabled then return false end
    for _,child in ipairs(prompt:GetChildren())do
        if child:IsA("GuiObject")and child.Visible then return true end
    end
    return false
end
local function check()
    assert(not cancelled(), "Stopped")
    assert(player.Parent and player.Character, "Character unavailable")
    local paused=0
    if Config.ShopKey then local shop=owner:GetPistonTrack();assert(shop.Open and shop.Key==Config.ShopKey,"ร้านปิดหรือย้ายจุดแล้ว")end
    if manualVerificationVisible()then
        local began=os.clock();local previous=Worker.Status
        Worker.WaitingForVerification=true
        status("รอมึงยืนยันว่าเป็นคนในหน้าต่างของเกม")
        while manualVerificationVisible()and not cancelled()do
            local speed=session and session.speed or 0
            local throttle=math.abs(speed)>.5 and(speed>0 and-1 or 1)or 0
            Worker.CommandThrottle,Worker.CommandSteer=throttle,0
            if session and session.seat.Parent and session.seat.Occupant==sessionHumanoid then
                session.seat.ThrottleFloat=throttle;session.seat.SteerFloat=0
            end
            task.wait(.1)
        end
        paused=os.clock()-began
        Worker.ManualPauseTotal=(Worker.ManualPauseTotal or 0)+paused
        if Worker.LegWatch then Worker.LegWatch.ProgressAt+=paused end
        Worker.WaitingForVerification=false
        assert(not cancelled(),"Stopped")
        status(previous)
    end
    local watch=Worker.LegWatch
    if watch and player:GetAttribute("DeliveryState")==watch.State and player:GetAttribute("DeliveryArrived")~=true
        and os.clock()-watch.ProgressAt>=Config.StallTimeout then
        Worker.NeedsReset=true
        error("งานค้างเกิน 3 นาที กำลังยกเลิกและรีเซ็ตตัวละคร",0)
    end
    if session then
        if session.crashed or not session.model.Parent or session.model:GetAttribute("Crashed")==true then
            Worker.NeedsFreshVehicle=true;Worker.NoWalk=true
            Worker.CommandThrottle,Worker.CommandSteer=0,0
            error("รถชน กำลังเรียกรถคันใหม่",0)
        end
        if session.seat.Occupant~=sessionHumanoid then
            Worker.NeedsFreshVehicle=true;Worker.NoWalk=true
            error("หลุดจากรถ กำลังเรียกรถคันใหม่",0)
        end
    end
    return paused
end
local function invoke(remote, action, ...)
    check()
    return Net.invoke(remote, action, ...)
end
local function stopInputs()
    Worker.CommandThrottle, Worker.CommandSteer = 0, 0
    if session and session.seat.Parent then
        session.seat.ThrottleFloat = 0
        session.seat.SteerFloat = 0
    end
end
local function brake()
    if not session or not session.seat.Parent then return end
    local deadline = os.clock() + math.abs(session.speed or 0) / Config.ComfortDecel + 4
    while not Worker.ShuttingDown and session.chassis.Parent and session.seat.Occupant == sessionHumanoid
        and math.abs(session.speed or 0) > .35 and os.clock() < deadline do
        session.seat.SteerFloat = 0
        session.seat.ThrottleFloat = (session.speed or 0) > 0 and -1 or 1
        Worker.CommandSteer, Worker.CommandThrottle = 0, session.seat.ThrottleFloat
        RunService.Heartbeat:Wait()
    end
    stopInputs()
    Worker.LastBrakeSpeed = session.chassis.Parent and flat(session.chassis.AssemblyLinearVelocity).Magnitude or 0
end
local function restore()
    for _, patch in motionPatches do
        if getupvalue(patch.step, patch.index) == patch.replacement then
            setupvalue(patch.step, patch.index, patch.original)
        end
    end
    table.clear(motionPatches)
    for _, patch in inputPatches do
        if getupvalue(patch.step, patch.index) == patch.replacement then
            setupvalue(patch.step, patch.index, patch.original)
        end
    end
    table.clear(inputPatches)
    for _, constraint in constraints do constraint:Destroy() end
    table.clear(constraints)
    table.clear(excluded)
    if session and originalFilter then
        session.params.FilterDescendantsInstances = originalFilter
    end
    originalFilter = nil
    if session and oldWheelie~=nil then session.wheelieHeld=oldWheelie end
    for vehicle, old in boosted do
        if vehicle.Parent then
            if old.turnAssist then vehicle:SetAttribute("MaxSteer", old.steer) end
        end
    end
    table.clear(boosted)
end
function Worker.Stop()
    Worker.Cancelled = true
    if Worker.RoadExitTween then Worker.RoadExitTween:Cancel();Worker.RoadExitTween=nil end
    if Worker.Enrollment then Worker.Enrollment.Stop()end
    if Worker.VehicleTweenCleanup then Worker.VehicleTweenCleanup()end
    if Worker.VehicleTurnCleanup then Worker.VehicleTurnCleanup()end
    stopInputs()
end
function Worker.Shutdown()Worker.ShuttingDown=true;Worker.Stop();restore()end

local function walk(goal)
    local character = player.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:WaitForChild("HumanoidRootPart")
    local path = PathfindingService:CreatePath({
        AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 12,
    })
    path:ComputeAsync(root.Position, goal)
    assert(path.Status == Enum.PathStatus.Success, "Cannot walk to the road")
    for _, point in path:GetWaypoints() do
        check()
        if point.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
        humanoid:MoveTo(point.Position)
        local deadline = os.clock() + 9
        while (flat(root.Position) - flat(point.Position)).Magnitude > 3.5 do
            check()
            assert(os.clock() < deadline, "Walking route blocked")
            task.wait(.08)
        end
    end
    humanoid:MoveTo(root.Position)
end

local function vehicleModel(seat)
    local model = seat and seat:FindFirstAncestorOfClass("Model")
    while model and model.Parent ~= workspace.SpawnedVehicles do
        model = model.Parent:FindFirstAncestorOfClass("Model")
    end
    return model
end

local function isCar(vehicle)
    local definition = GameShared.vehicle(vehicle:GetAttribute("VehicleId") or vehicle.Name)
    return definition and definition.category == "Car"
end

local function nativeLimits(vehicle)
    local _, _, multiplier = GameShared.upgradeScales(vehicle)
    local tucked = not isCar(vehicle) and vehicle:GetAttribute("Tuck") == true
    local tuckMultiplier = tucked and BikeShared.TUCK_SPEED_BONUS or 1
    local capKmh = math.min(EcuShared.ABS_KMH,
        tucked and EcuShared.TUCK_TOP_KMH or EcuShared.TOP_KMH,
        PistonShared.capKmh(vehicle, tucked) or math.huge)
    local nativeTop = GameShared.driveTop(vehicle, multiplier, tuckMultiplier)
    return math.min(nativeTop, capKmh / EcuShared.KMH_PER_STUD), capKmh
end

local function controlDriverInput(driver)
    check()
    for _, value in getupvalues(driver.start) do
        if type(value) == "function" and debug.info(value, "n") == "step" then
            for index, input in getupvalues(value) do
                if type(input) == "function" and debug.info(input, "n") == "keysToSeat" then
                    for _, patch in inputPatches do if patch.step == value then return end end
                    local replacement = function(state)
                        if state == session then
                            state.seat.ThrottleFloat = Worker.CommandThrottle or 0
                            state.seat.SteerFloat = Worker.CommandSteer or 0
                            if sessionKind=="Bike"then state.wheelieHeld=false end
                        else return input(state)end
                    end
                    table.insert(inputPatches, {step = value, index = index,
                        original = input, replacement = replacement})
                    setupvalue(value, index, replacement)
                    return
                end
            end
        end
    end
end

local function prepareVehicle()
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    local existing = vehicleModel(humanoid.SeatPart)
    if Config.VehicleId == "Current" then
        Config.VehicleId = existing and existing:GetAttribute("OwnerUserId") == player.UserId
            and existing:GetAttribute("VehicleId") or player:GetAttribute("ActiveVehicle") or "PCX160"
    end
    if existing then
        local client = isCar(existing) and player.PlayerScripts.CarClient or player.PlayerScripts.PCX160Client
        local driver = require(client.Driver)
        for _, value in getupvalues(driver.start) do
            if type(value) == "table" and value.model == existing and value.seat == humanoid.SeatPart then
                session, sessionHumanoid = value, humanoid
                controlDriverInput(driver)
                brake()
                session = nil
                break
            end
        end
    end
    local list
    for _ = 1, 3 do
        list = invoke(Remotes.Garage, "List")
        if type(list) == "table" then break end
        task.wait(.8)
    end
    assert(type(list) == "table", "Garage list unavailable")
    if Config.RandomVehicle and not Config.RandomChosen then
        local fare=player:GetAttribute("DeliveryState")
        if fare=="ToShop"or fare=="ToHome"then
            Config.VehicleId=existing and existing:GetAttribute("VehicleId")or list.active or player:GetAttribute("ActiveVehicle")
            assert(Config.VehicleId,"ไม่พบรถของงานปัจจุบัน")
        else Config.VehicleId=owner:PickShopVehicle(list,Config.WorkVehicle)end
        Config.RandomChosen=true
    end
    task.wait(math.max(.8, tonumber(list.cooldown) or 0))
    local available = {}
    local selectedAllowed = false
    for _, entry in list.vehicles or {} do
        local definition = GameShared.vehicle(entry.id)
        available[entry.id] = definition and definition.th or entry.id
        if entry.id == Config.VehicleId then selectedAllowed = true end
    end
    Worker.Vehicles = available
    Worker.GarageLimit = list.max
    assert(selectedAllowed, "This vehicle is not available in your Garage: " .. tostring(Config.VehicleId))
    local seatedVehicle = vehicleModel(humanoid.SeatPart)
    if seatedVehicle and (seatedVehicle:GetAttribute("VehicleId") ~= Config.VehicleId
        or seatedVehicle:GetAttribute("OwnerUserId") ~= player.UserId) then
        local fareState = player:GetAttribute("DeliveryState")
        assert(fareState ~= "ToShop" and fareState ~= "ToHome", "Finish the active fare before switching vehicles")
        session = nil
        if isCar(seatedVehicle) then
            Net.fire(RS.CarRemote, "Exit", seatedVehicle)
        else
            Net.fire(RS.PCX160Remote, "Dismount", "Start")
        end
        local deadline = os.clock() + 6
        while humanoid.SeatPart and os.clock() < deadline do task.wait(.1) end
        assert(not humanoid.SeatPart, "Could not leave the previous vehicle")
        task.wait(1.2) -- let the server finish releasing the old driver seat
    end
    if not humanoid.SeatPart then
        status("กำลังกลับขึ้นรถ")
        local vehicle
        for _,candidate in workspace:WaitForChild("SpawnedVehicles"):GetChildren()do
            if candidate:GetAttribute("OwnerUserId")==player.UserId and candidate:GetAttribute("VehicleId")==Config.VehicleId then vehicle=candidate;break end
        end
        if not vehicle then
            if Config.SpawnOnRoad then Worker.MoveCharacterToRoad()end
            Worker.SpawnOrigin=tostring(player.Character.HumanoidRootPart.Position)
            local ok,message
            for attempt=1,3 do
                ok,message=invoke(Remotes.Garage,"Spawn",Config.VehicleId)
                if ok then break end
                task.wait(1.2)
            end
            assert(ok,tostring(message));task.wait(.8)
        end
        for _, candidate in workspace:WaitForChild("SpawnedVehicles"):GetChildren() do
            if candidate:GetAttribute("OwnerUserId") == player.UserId
                and candidate:GetAttribute("VehicleId") == Config.VehicleId then
                vehicle = candidate
                break
            end
        end
        if not vehicle then
            local deadline=os.clock()+6
            repeat
                check()
                for _,candidate in ipairs(workspace.SpawnedVehicles:GetChildren())do
                    if candidate:GetAttribute("OwnerUserId")==player.UserId and candidate:GetAttribute("VehicleId")==Config.VehicleId then vehicle=candidate;break end
                end
                if not vehicle then task.wait(.2)end
            until vehicle or os.clock()>deadline
        end
        assert(vehicle, "Your vehicle did not spawn")
        Worker.SpawnLocation = tostring(vehicle:GetPivot().Position)
        if (player.Character.HumanoidRootPart.Position - vehicle:GetPivot().Position).Magnitude > 14 then
            local approach = vehicle:GetPivot():PointToWorldSpace(Vector3.new(-8, 0, 0))
            if Worker.NoWalk then Worker.NeedsFreshVehicle=true;error("เกมเรียกรถไกลเกินระยะขึ้นรถ กำลังลองเรียกใหม่โดยไม่เดิน",0)end
            walk(approach)
        end
        if isCar(vehicle) then
            Net.fire(RS.CarRemote, "Enter", vehicle, "Driver")
        else
            Net.fire(RS.PCX160Remote, "Mount", vehicle, "Drive")
        end
        local deadline = os.clock() + 5
        while not humanoid.SeatPart and os.clock() < deadline do check() task.wait(.1) end
    end
    assert(humanoid.SeatPart, "Could not enter the selected vehicle")
    local vehicle = assert(vehicleModel(humanoid.SeatPart), "Vehicle model unavailable")
    sessionKind = isCar(vehicle) and "Car" or "Bike"
    local client = sessionKind == "Car" and player.PlayerScripts.CarClient or player.PlayerScripts.PCX160Client
    local driver = require(client.Driver)
    session = nil
    for _, value in getupvalues(driver.start) do
        if type(value) == "table" and value.model == vehicle and value.chassis then
            session = value
            break
        end
    end
    assert(type(session) == "table" and session.chassis, "Driver state unavailable")
    sessionHumanoid = humanoid
    controlDriverInput(driver)
    assert(session.seat == humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat"), "Sit in the driver seat")
    if not vehicle:GetAttribute("EngineOn") then
        if sessionKind == "Car" then Net.fire(RS.CarRemote, "Engine", vehicle, true)
        else Net.fire(RS.PCX160Remote, "Engine", true) end
        task.wait(2.5)
    end
    if sessionKind == "Bike" and vehicle:GetAttribute("StandDown") then
        Net.fire(RS.PCX160Remote, "Stand", false)
        task.wait(.6)
    end
    assert(isnetworkowner(session.chassis), "The client is not controlling the bike")
    originalFilter = table.clone(session.params.FilterDescendantsInstances)
    castParams.FilterDescendantsInstances={session.model,player.Character,workspace.CurrentCamera}
    oldWheelie=session.wheelieHeld==true
    Worker.Vehicle=session.model
    Worker.NoWalk=false
    boosted[vehicle] = {steer = vehicle:GetAttribute("MaxSteer"), turnAssist = sessionKind == "Car"}
end

local function speedLimit()
    local vehicle = session.model
    local nativeTop, capKmh = nativeLimits(vehicle)
    local allowed = nativeTop * .98 -- a small margin below this vehicle's actual native limit
    Worker.Limits = {
        BaseStuds = vehicle:GetAttribute("MaxSpeed"),
        NativeTopStuds = nativeTop, NativeTopKmh = nativeTop * EcuShared.KMH_PER_STUD,
        NativeCapKmh = capKmh, TargetStuds = allowed,
        TargetKmh = allowed * EcuShared.KMH_PER_STUD,
        VehicleId = vehicle:GetAttribute("VehicleId"), Kind = sessionKind,
    }
    return allowed
end

-- The GPS graph describes road centres, including the raised median.
-- Choose a carriageway, and cross only beyond a physical median section.
local function alleyMouth(target)
    if math.abs(target.X)<=85 then return nil end
    local route=Graph.route(Vector3.new(0,target.Y,target.Z),target)
    local lastMain
    for _,point in ipairs(route or{})do
        if math.abs(point.X)<2 then lastMain=point
        elseif lastMain and math.abs(point.X)>12 then return Vector3.new(target.X<0 and-Config.LaneOffset or Config.LaneOffset,target.Y,lastMain.Y)end
    end
end

local function laneRoute(target)
    local source = session.chassis.Position
    if Config.DirectMainRoad and math.abs(source.X)<85 and math.abs(target.X)<400 and math.abs(source.Z)<3300 and math.abs(target.Z)<3300 then
        local lane=target.X<0 and-Config.LaneOffset or Config.LaneOffset
        local mouth=alleyMouth(target)
        local entryZ=mouth and mouth.Z or target.Z
        local result={}
        for _,point in ipairs({Vector2.new(source.X,source.Z),Vector2.new(lane,source.Z),Vector2.new(lane,entryZ),Vector2.new(target.X,entryZ),Vector2.new(target.X,target.Z)})do
            if #result==0 or(result[#result]-point).Magnitude>3 then table.insert(result,point)end
        end
        return result
    end
    local sourceSide = source.X < 0 and -1 or 1
    local targetSide = target.X < 0 and -1 or 1
    -- Nearest centre-line can wrongly snap the edge of the main road to a side street.
    local start = math.abs(source.X) < 72
        and Vector3.new(sourceSide * Config.LaneOffset, source.Y, source.Z) or source
    local raw = Graph.route(start, target)
    assert(raw and #raw > 0, "No GPS route")
    if (flat(start) - flat(source)).Magnitude > 3 then
        table.insert(raw, 1, Vector2.new(source.X, source.Z))
    end
    local firstAxis
    for i, point in raw do if math.abs(point.X) < 1 then firstAxis = i break end end
    local lastAxis=firstAxis
    if firstAxis then
        while lastAxis<#raw and math.abs(raw[lastAxis+1].X)<1 do lastAxis+=1 end
    end
    local crossing
    if firstAxis and sourceSide ~= targetSide then
        local z = raw[firstAxis].Y
        local intervals = {}
        local median = workspace.Map.Road:FindFirstChild("Median")
        if median then
            for _, part in median:GetDescendants() do
                if part:IsA("BasePart") and part.Size.Z > 8 and math.abs(part.Position.X) < 12 then
                    table.insert(intervals, {part.Position.Z - part.Size.Z / 2, part.Position.Z + part.Size.Z / 2})
                end
            end
        end
        table.sort(intervals, function(a, b) return a[1] < b[1] end)
        local merged = {}
        for _, interval in intervals do
            local last = merged[#merged]
            if last and interval[1] <= last[2] + 2 then
                last[2] = math.max(last[2], interval[2])
            else
                table.insert(merged, {interval[1], interval[2]})
            end
        end
        local finish=raw[lastAxis].Y
        local candidates={finish,z};local bestCost
        for _,interval in ipairs(merged)do table.insert(candidates,interval[1]-18);table.insert(candidates,interval[2]+18)end
        for _,at in ipairs(candidates)do
            local open=true
            for _,interval in ipairs(merged)do if at>interval[1]-17 and at<interval[2]+17 then open=false;break end end
            local cost=math.abs(at-z)+math.abs(finish-at)+math.abs(finish-at)*.001
            if open and(not bestCost or cost<bestCost)then crossing,bestCost=at,cost end
        end
    end
    local points = {}
    local inserted = false
    for index, point in raw do
        if math.abs(point.X) < 1 then
            if sourceSide~=targetSide and crossing then
                if index==firstAxis then
                table.insert(points, Vector2.new(sourceSide * Config.LaneOffset, point.Y))
                table.insert(points, Vector2.new(sourceSide * Config.LaneOffset, crossing))
                table.insert(points, Vector2.new(targetSide * Config.LaneOffset, crossing))
                table.insert(points, Vector2.new(targetSide * Config.LaneOffset,raw[lastAxis].Y))
                end
                continue
            end
            inserted = true
            point = Vector2.new(targetSide * Config.LaneOffset, point.Y)
        end
        if #points == 0 or (points[#points] - point).Magnitude > 3 then table.insert(points, point) end
    end
    -- Other GPS roads also have kerbs/medians along their centre line.
    local centres = table.clone(points)
    for i = 2, #points - 1 do
        local before, here, after = centres[i - 1], centres[i], centres[i + 1]
        if math.abs(here.X) > Config.LaneOffset + 2 then
            local incoming, outgoing = here - before, after - here
            if incoming.Magnitude > .1 and outgoing.Magnitude > .1 then
                local a = Vector2.new(incoming.Unit.Y, -incoming.Unit.X)
                local b = Vector2.new(outgoing.Unit.Y, -outgoing.Unit.X)
                local sum = a + b
                if sum.Magnitude > .2 then
                    local normal = sum.Unit
                    points[i] = here + normal * math.min(9, 6 / math.max(.65, normal:Dot(a)))
                end
            end
        end
    end
    return points
end

local safetyAt = 0
local gearAt = 0
local function automaticGear(speed, top)
    if not session.gears or os.clock() - gearAt < .3 then return end
    local gear = session.gear or 1
    local direction
    if gear < session.gears and speed > top * GearShared.share(session.gears, gear) * .88 then
        direction = 1
    elseif gear > 1 and speed < top * GearShared.share(session.gears, gear - 1) * .55 then
        direction = -1
    end
    if direction then
        local nextGear = GearShared.shift(session.gears, gear, direction, speed, top)
        if nextGear then
            session.gear = nextGear
            session.model:SetAttribute("Gear", nextGear)
            gearAt = os.clock()
        end
    end
end

local function safety()
    if session and sessionKind=="Bike"then session.wheelieHeld=false end
end
local function castSize()return sessionKind=="Car"and Vector3.new(6.5,1.8,3)or Vector3.new(2.6,1.5,2)end
local function reverseFromObstacle()
    brake()
    local start=session.chassis.Position
    local back=-(CFrame.Angles(0,session.heading,0)).LookVector
    local hit=workspace:Blockcast(CFrame.lookAt(start+Vector3.new(0,1,0),start+Vector3.new(0,1,0)+back),castSize(),back*16,castParams)
    local room=hit and math.max(0,hit.Distance-4)or 12
    if room<3 then return end
    local deadline=os.clock()+3
    local heading=Worker.Telemetry and Worker.Telemetry.HeadingError or 0
    local steer=math.abs(heading)>.7 and math.clamp(heading,-1,1)or 0
    while(flat(session.chassis.Position)-flat(start)).Magnitude<math.min(12,room)and os.clock()<deadline do
        check();safety();Worker.CommandThrottle,Worker.CommandSteer=-.55,steer
        session.seat.ThrottleFloat=-.55;session.seat.SteerFloat=steer;task.wait(.03)
    end
    brake()
end
local function groundY(position)
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances={workspace:FindFirstChild("Map")}
    params.RespectCanCollide=true
    local hit=workspace:Raycast(position+Vector3.new(0,4,0),Vector3.new(0,-24,0),params)
    -- Follow bridge decks, but do not treat a kerb/median top as a new road level.
    return hit and hit.Material==Enum.Material.Asphalt and hit.Normal.Y>.8 and hit.Position.Y or position.Y-1
end
local function routeCast(from,to)
    local delta=to-from
    if delta.Magnitude>900 then
        local middle=from+delta.Unit*900
        return routeCast(from,middle)or routeCast(middle,to)
    end
    if delta.Magnitude<.1 then return nil end
    local fromY,toY=groundY(from),groundY(to)
    local bodyFrom,bodyTo=Vector3.new(from.X,fromY+1.6,from.Z),Vector3.new(to.X,toY+1.6,to.Z)
    local body=workspace:Blockcast(CFrame.lookAt(bodyFrom,bodyTo),castSize(),bodyTo-bodyFrom,castParams)
    local a,b=Vector3.new(from.X,fromY+.32,from.Z),Vector3.new(to.X,toY+.32,to.Z)
    local low=workspace:Blockcast(CFrame.lookAt(a,b),Vector3.new(castSize().X,.5,1.4),b-a,castParams)
    local function blocks(hit)
        if not hit or hit.Normal.Y>=.65 then return false end
        local part=hit.Instance
        if part:IsA("BasePart")then
            local cf,size=part.CFrame,part.Size
            local height=math.abs(cf.RightVector.Y)*size.X+math.abs(cf.UpVector.Y)*size.Y+math.abs(cf.LookVector.Y)*size.Z
            if height<.18 then return false end
        end
        return true
    end
    if not blocks(body)then body=nil end
    if not blocks(low)then low=nil end
    if low and(not body or low.Distance<body.Distance)then return low end
    return body
end
local function detourRoute(route,index,obstacle)
    local source=session.chassis.Position;local origin=flat(source)
    local destination=index
    local goal
    local previous=origin
    local distanceToGoal=0
    for future=index,#route do
        destination=future
        local point=Vector3.new(route[future].X,0,route[future].Y)
        local segment=point-previous
        if distanceToGoal+segment.Magnitude>=105 then
            local at=previous+segment.Unit*(105-distanceToGoal)
            goal=Vector3.new(at.X,source.Y,at.Z)
            -- The sampled point is inside this segment; keep its end in the route.
            destination=future-1
            break
        end
        distanceToGoal+=segment.Magnitude;previous=point
    end
    goal=goal or Vector3.new(route[destination].X,source.Y,route[destination].Y)
    local direction=flat(goal-source)
    if obstacle and obstacle:IsA("BasePart")then
        local nodes={source,goal}
        local radius=castSize().X/2+4
        -- Free-space samples let recovery go around furniture/buildings when
        -- their useful outside corners are not represented by the hit part.
        for _,reach in ipairs({24,48,96})do for i=0,7 do
            local angle=i*math.pi/4
            table.insert(nodes,source+Vector3.new(math.cos(angle)*reach,0,math.sin(angle)*reach))
        end end
        local parts={obstacle};local neighbours={}
        -- Median fill and its concrete kerbs live in different road models.
        local nearby=OverlapParams.new()
        nearby.FilterType=Enum.RaycastFilterType.Exclude
        nearby.FilterDescendantsInstances={session.model,player.Character,workspace.CurrentCamera}
        nearby.RespectCanCollide=true
        for _,part in ipairs(workspace:GetPartBoundsInRadius(source,160,nearby))do
            if part~=obstacle and part.CanCollide and part.Size.Y>=.18 and part.Size.Y<5
                and part.Material~=Enum.Material.Asphalt and math.max(part.Size.X,part.Size.Z)<350 then
                table.insert(neighbours,part)
            end
        end
        table.sort(neighbours,function(a,b)return(a.Position-source).Magnitude<(b.Position-source).Magnitude end)
        for i=1,math.min(19,#neighbours)do table.insert(parts,neighbours[i])end
        for n,part in ipairs(parts)do
            if n>20 then break end
            for _,x in ipairs({-1,1})do for _,z in ipairs({-1,1})do
                local point=part.CFrame:PointToWorldSpace(Vector3.new(x*(part.Size.X/2+radius),0,z*(part.Size.Z/2+radius)))
                local at=Vector3.new(point.X,source.Y,point.Z)
                if(at-source).Magnitude<=360 and(at-goal).Magnitude<=360 then table.insert(nodes,at)end
            end end
        end
        if math.abs(source.X)<110 then
            local lane=source.X<0 and-28 or 28
            table.insert(nodes,Vector3.new(lane,source.Y,source.Z))
            table.insert(nodes,Vector3.new(lane,source.Y,goal.Z))
        end
        local distance={[1]=0};local previous={};local closed={};local edges={}
        for step=1,#nodes do
            local best,value
            for i,d in pairs(distance)do if not closed[i]and(not value or d<value)then best,value=i,d end end
            if not best or best==2 then break end
            closed[best]=true
            for j,node in ipairs(nodes)do if not closed[j]and j~=best then
                local key=math.min(best,j)..":"..math.max(best,j)
                local clear=edges[key]
                if clear==nil then clear=not routeCast(nodes[best],node);edges[key]=clear end
                local cost=value+(node-nodes[best]).Magnitude
                if clear and(not distance[j]or cost<distance[j])then distance[j]=cost;previous[j]=best end
            end end
        end
        if distance[2]then
            local result={};local at=2
            while at do table.insert(result,1,Vector2.new(nodes[at].X,nodes[at].Z));at=previous[at]end
            for future=destination+1,#route do table.insert(result,route[future])end
            return result
        end
    end
    if obstacle and obstacle:IsA("BasePart")and direction.Magnitude>1 then
        local forward=direction.Unit;local side=Vector3.new(-forward.Z,0,forward.X)
        local halfForward,halfSide=0,0
        for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
            local corner=obstacle.CFrame:PointToWorldSpace(obstacle.Size*Vector3.new(x,y,z)/2)-obstacle.Position
            halfForward=math.max(halfForward,math.abs(corner:Dot(forward)))
            halfSide=math.max(halfSide,math.abs(corner:Dot(side)))
        end end end
        if halfSide<150 and halfForward<220 then
            local choices={}
            for _,sign in ipairs({-1,1})do
                local centre=Vector3.new(obstacle.Position.X,source.Y,obstacle.Position.Z)
                local offset=side*sign*(halfSide+castSize().X/2+5)
                local a=centre-forward*(halfForward+8)+offset
                local b=centre+forward*(halfForward+12)+offset
                if not routeCast(source,a)and not routeCast(a,b)and not routeCast(b,goal)then
                    table.insert(choices,{source,a,b,goal})
                end
            end
            if#choices>0 then
                table.sort(choices,function(a,b)return(a[2]-source).Magnitude<(b[2]-source).Magnitude end)
                local result={}
                for _,point in ipairs(choices[1])do table.insert(result,Vector2.new(point.X,point.Z))end
                for future=destination+1,#route do table.insert(result,route[future])end
                return result
            end
        end
    end
    -- A local grid also covers driveways which have no useful model corners.
    local spacing=sessionKind=="Car"and 10 or 8
    local heap={};local seen={};local expanded=0
    local function push(node)
        table.insert(heap,node);local at=#heap
        while at>1 do local parent=math.floor(at/2);if heap[parent].f<=node.f then break end;heap[at]=heap[parent];at=parent end
        heap[at]=node
    end
    local function pop()
        local result=heap[1];local last=table.remove(heap)
        if#heap>0 then
            local at=1
            while at*2<=#heap do
                local child=at*2;if child<#heap and heap[child+1].f<heap[child].f then child+=1 end
                if heap[child].f>=last.f then break end
                heap[at]=heap[child];at=child
            end
            heap[at]=last
        end
        return result
    end
    local root={x=0,z=0,point=source,g=0,f=(goal-source).Magnitude}
    push(root);seen["0:0"]=root
    local found
    while#heap>0 and expanded<3000 do
        local node=pop()
        if not node.closed then
            node.closed=true;expanded+=1
            if(node.point-goal).Magnitude<spacing*1.6 and not routeCast(node.point,goal)then found=node;break end
            for dx=-1,1 do for dz=-1,1 do if dx~=0 or dz~=0 then
                local x,z=node.x+dx,node.z+dz
                if math.abs(x)<=28 and math.abs(z)<=28 then
                    local key=x..":"..z;local old=seen[key]
                    local point=source+Vector3.new(x*spacing,0,z*spacing)
                    local cost=node.g+spacing*math.sqrt(dx*dx+dz*dz)
                    if(not old or cost<old.g)and not routeCast(node.point,point)then
                        local nextNode={x=x,z=z,point=point,g=cost,f=cost+(point-goal).Magnitude,parent=node}
                        seen[key]=nextNode;push(nextNode)
                    end
                end
            end end end
            if expanded%100==0 then check();task.wait()end
        end
    end
    if found then
        local raw={goal};local node=found
        while node do table.insert(raw,1,node.point);node=node.parent end
        local result={Vector2.new(source.X,source.Z)};local at=1
        while at<#raw do
            local far=at+1
            for future=at+2,#raw do if routeCast(raw[at],raw[future])then break else far=future end end
            table.insert(result,Vector2.new(raw[far].X,raw[far].Z));at=far
        end
        for future=destination+1,#route do table.insert(result,route[future])end
        return result
    end
    local path=PathfindingService:CreatePath({AgentRadius=sessionKind=="Car"and 4.5 or 2.5,AgentHeight=5,AgentCanJump=false,WaypointSpacing=10})
    local ok=pcall(path.ComputeAsync,path,source,goal)
    if not ok or path.Status~=Enum.PathStatus.Success then return nil end
    local result={Vector2.new(source.X,source.Z)};local previous=source
    for _,point in ipairs(path:GetWaypoints())do
        if point.Action==Enum.PathWaypointAction.Jump then return nil end
        local at=Vector3.new(point.Position.X,source.Y,point.Position.Z)
        if routeCast(previous,at)then return nil end
        local nextPoint=Vector2.new(at.X,at.Z)
        if(nextPoint-result[#result]).Magnitude>2 then table.insert(result,nextPoint)end
        previous=at
    end
    if#result<3 then return nil end
    for future=destination+1,#route do table.insert(result,route[future])end
    return result
end

local function smoothRoute(raw)
    local points = {raw[1]}
    local function append(point)
        if (points[#points] - point).Magnitude > .1 then table.insert(points, point) end
    end
    for i = 2, #raw - 1 do
        local a, b, c = raw[i - 1], raw[i], raw[i + 1]
        local incoming, outgoing = b - a, c - b
        if incoming.Magnitude > .1 and outgoing.Magnitude > .1 then
            local angle = math.acos(math.clamp(incoming.Unit:Dot(outgoing.Unit), -1, 1))
            if angle > .035 and angle < 2.8 then
                -- Keep the curve inside a narrow corridor around the original lane.
                local share = angle < .5 and .5 or .3
                local trim = math.min(incoming.Magnitude * share, outgoing.Magnitude * share,
                    35, 8 / math.max(.15, math.sin(angle / 2)))
                local entry, exit = b - incoming.Unit * trim, b + outgoing.Unit * trim
                append(entry)
                local steps = math.max(3, math.ceil(trim * 2 / 5))
                for step = 1, steps do
                    local t = step / steps
                    append(entry * (1 - t)^2 + b * (2 * (1 - t) * t) + exit * t^2)
                end
            else append(b) end
        else append(b) end
    end
    append(raw[#raw])
    -- Rounding a collision-free corner can still cut through a median end cap.
    for i=2,#points do
        local a,b=points[i-1],points[i]
        local y=session.chassis.Position.Y
        if routeCast(Vector3.new(a.X,y,a.Y),Vector3.new(b.X,y,b.Y))then return raw end
    end
    return points
end

local function roadsideTarget(target,recovery)
    local best,bestScore
    for _,radius in ipairs({0,8,16,24,29,30})do
        local samples=radius==0 and 1 or 32
        for i=1,samples do
            local angle=(i-1)*math.pi*2/samples
            local point=target+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
            local hit=workspace:Raycast(point+Vector3.new(0,10,0),Vector3.new(0,-30,0),castParams)
            if hit and(hit.Material==Enum.Material.Asphalt or recovery and math.abs(hit.Position.Y-target.Y)<2)
                and hit.Normal.Y>.9 then
                local candidate=Vector3.new(point.X,hit.Position.Y,point.Z)
                local clear=true
                -- Keep the vehicle footprint off the pavement/median, too.
                for _,offset in ipairs({Vector3.new(1.8,0,0),Vector3.new(-1.8,0,0),Vector3.new(0,0,1.8),Vector3.new(0,0,-1.8)})do
                    local edge=workspace:Raycast(candidate+offset+Vector3.new(0,4,0),Vector3.new(0,-8,0),castParams)
                    if not edge or(not recovery and edge.Material~=Enum.Material.Asphalt)or math.abs(edge.Position.Y-hit.Position.Y)>.25 then clear=false;break end
                end
                if recovery and routeCast(session.chassis.Position,candidate+Vector3.new(0,1,0))then clear=false end
                local distance=(flat(candidate)-flat(session.chassis.Position)).Magnitude
                local score=recovery and distance or radius+distance*.002
                if clear and(not bestScore or score<bestScore)then best,bestScore=candidate,score end
            end
        end
    end
    return best or target
end

local function routePoint(model,arc)
    arc=math.clamp(arc,0,model.Length)
    local low,high=1,#model.Points-1
    while low<high do
        local middle=math.floor((low+high)/2)
        if model.Arc[middle+1]<arc then low=middle+1 else high=middle end
    end
    local a,b=model.Points[low],model.Points[low+1]
    local span=model.Arc[low+1]-model.Arc[low]
    return a+(b-a)*(span>.001 and(arc-model.Arc[low])/span or 0),low
end
local function routeModel(points)
    local filtered={}
    for _,point in ipairs(points)do if#filtered==0 or(point-filtered[#filtered]).Magnitude>.1 then table.insert(filtered,point)end end
    assert(#filtered>=2,"เส้นทางสั้นเกินไป")
    local model={Points=filtered,Arc={0},Progress=0,Cursor=1,TurnIndex=1,Turns={}}
    for i=2,#filtered do model.Arc[i]=model.Arc[i-1]+(filtered[i]-filtered[i-1]).Magnitude end
    model.Length=model.Arc[#filtered]
    for i=2,#filtered-1 do
        local arc=model.Arc[i]
        local a=filtered[i]-routePoint(model,arc-22)
        local b=routePoint(model,arc+22)-filtered[i]
        if a.Magnitude>2 and b.Magnitude>2 then
            local angle=math.acos(math.clamp(a.Unit:Dot(b.Unit),-1,1))
            if angle>.06 then
                local bendSpeed=angle>1.1 and 24 or angle>.65 and 32 or angle>.35 and 45
                    or math.clamp(math.sqrt(Config.CurveAccel*(a.Magnitude+b.Magnitude)/(2*angle)),32,100)
                local corner=model.Turns[#model.Turns]
                if corner and arc-corner.Last<30 then
                    corner.Last=arc;corner.Exit=math.min(model.Length,arc+18);corner.Angle=math.max(corner.Angle,angle)
                else
                    corner={Entry=math.max(0,arc-18),Exit=math.min(model.Length,arc+18),Last=arc,Angle=angle}
                    table.insert(model.Turns,corner)
                end
                corner.Speed=math.min(corner.Speed or math.huge,bendSpeed)
            end
        end
    end
    return model
end
local function projectRoute(model,position,speed)
    local best,bestScore,bestSegment,bestDistance
    local maxArc=model.Progress+math.max(40,speed*.25)
    for index=math.max(1,model.Cursor-1),math.min(#model.Points-1,model.Cursor+20)do
        local a,b=model.Points[index],model.Points[index+1];local segment=b-a
        local t=math.clamp((position-a):Dot(segment)/math.max(.001,segment:Dot(segment)),0,1)
        local projected=a+segment*t;local arc=model.Arc[index]+segment.Magnitude*t
        if arc>=model.Progress-4 and arc<=maxArc then
            local distance=(position-projected).Magnitude
            local score=distance*distance+math.max(0,arc-model.Progress)*.01
            if not bestScore or score<bestScore then best,bestScore,bestSegment,bestDistance=arc,score,index,distance end
        end
    end
    if best then model.Progress=math.max(model.Progress,best);model.Cursor=bestSegment end
    return bestDistance or(position-routePoint(model,model.Progress)).Magnitude
end
local function nextTurn(model)
    while model.TurnIndex<=#model.Turns and model.Progress>model.Turns[model.TurnIndex].Exit+4 do model.TurnIndex+=1 end
    return model.Turns[model.TurnIndex]
end
local function brakeDistance(speed,target,car)
    local velocity=math.max(0,speed);local distance=0
    for _=1,200 do
        if velocity<=target then break end
        local nextSpeed=car and math.max(target,velocity-(Config.ComfortDecel or 38)*.05)or math.max(target,BikeShared.brake(velocity,.05,1))
        distance+=(velocity+nextSpeed)*.025;velocity=nextSpeed
    end
    return distance*1.08+speed*.45+8
end
local function turnLimit(model,speed,car)
    local corner=nextTurn(model)
    if model.LatchedTurn and model.Progress>model.LatchedTurn.Exit+4 then model.LatchedTurn=nil end
    if corner and not model.LatchedTurn then
        local ahead=corner.Entry-model.Progress
        if ahead<=brakeDistance(speed,corner.Speed,car)then model.LatchedTurn=corner end
    end
    -- A mild bend must not hide a sharper junction immediately after it.
    for index=model.TurnIndex,math.min(#model.Turns,model.TurnIndex+8)do
        local future=model.Turns[index]
        local distance=future.Entry-model.Progress
        local lead=brakeDistance(speed,future.Speed,car)
        if distance<=lead and(not model.LatchedTurn or future.Speed<model.LatchedTurn.Speed)then model.LatchedTurn=future end
    end
    return model.LatchedTurn and model.LatchedTurn.Speed or nil,corner and math.max(0,corner.Entry-model.Progress)or nil
end

local function driveThrottle(control,speed,target,now)
    local stop=target<.5
    local trigger=stop and .5 or target+6
    if not control.Held and speed>trigger and(now>=(control.RearmAt or 0)or stop or speed>target+14)then
        control.Held=true;control.Release=stop and .35 or math.max(.5,target-3)
        control.Episodes=(control.Episodes or 0)+1
    end
    if control.Held then
        control.Release=stop and .35 or math.max(.5,target-3)
        if speed>control.Release then return -1,true end
        control.Held=false;control.RearmAt=now+.8
    end
    if stop then return 0,false end
    return math.clamp((target-speed)/12,0,1),false
end

local function buildingClear(from,to)
    local delta=flat(to-from)
    if delta.Magnitude<1 then return true end
    local excludedParts={player.Character,workspace.CurrentCamera}
    if session then table.insert(excludedParts,session.model)end
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.RespectCanCollide=true
    for _=1,32 do
        params.FilterDescendantsInstances=excludedParts
        local hit=workspace:Blockcast(CFrame.new(from+Vector3.new(0,2,0)),Vector3.new(4,3,4),delta,params)
        if not hit then return true end
        local part=hit.Instance
        if not part:IsA("BasePart")then return hit.Normal.Y>.7 end
        local cf,size=part.CFrame,part.Size
        local height=math.abs(cf.RightVector.Y)*size.X+math.abs(cf.UpVector.Y)*size.Y+math.abs(cf.LookVector.Y)*size.Z
        if height>10 and hit.Normal.Y<.7 then Worker.LastTweenRejected="มีตึกขวาง ต้องขี่ไปตามถนน";return false end
        table.insert(excludedParts,part)
    end
    Worker.LastTweenRejected="ตรวจทางไม่ครบ ต้องขี่ไปตามถนน";return false
end

local function tweenVehiclePast(hit,direction,arrival)
    if Worker.VehicleTweenDisabled or not session then return false end
    if not owner:CanVehicleTween(session.model)then Worker.LastTweenRejected="ไม่ได้ควบคุมรถคันนี้";return false end
    local obstacle=hit and hit.Instance
    if not arrival and(not obstacle or not obstacle:IsA("BasePart"))then return false end
    direction=flat(arrival and(arrival-session.chassis.Position)or direction)
    if direction.Magnitude<.1 then return false end;direction=direction.Unit
    local distance
    if arrival then distance=flat(arrival-session.chassis.Position).Magnitude
    else
        local cf,size=obstacle.CFrame,obstacle.Size
        local height=math.abs(cf.RightVector.Y)*size.X+math.abs(cf.UpVector.Y)*size.Y+math.abs(cf.LookVector.Y)*size.Z
        if height>10 then Worker.LastTweenRejected="อาคารหรือสิ่งกีดขวางสูง";return false end
        local origin=cf:PointToObjectSpace(session.chassis.Position)
        local ray=cf:VectorToObjectSpace(direction)
        local enter,leave=-math.huge,math.huge
        for _,axis in ipairs({"X","Y","Z"})do
            local half=size[axis]*.5
            if math.abs(ray[axis])<.0001 then
                if math.abs(origin[axis])>half+2 then return false end
            else
                local a,b=(-half-origin[axis])/ray[axis],(half-origin[axis])/ray[axis]
                enter=math.max(enter,math.min(a,b));leave=math.min(leave,math.max(a,b))
            end
        end
        if leave<math.max(enter,0)then return false end
        distance=leave+9
    end
    if distance<1 or distance>(arrival and 300 or 120)then return false end
    local finish=session.chassis.Position+direction*distance
    if not buildingClear(session.chassis.Position,finish)then return false end
    if Config.KeepShopLane and not owner:CanShopVehicleTween(session.chassis.Position,finish,session.chassis.CFrame.LookVector,arrival~=nil)then Worker.LastTweenRejected="เป้าหมายข้ามเลนหรือย้อนทิศ";return false end
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={workspace.Map,workspace.Terrain};params.RespectCanCollide=true
    local floor=workspace:Raycast(finish+Vector3.new(0,8,0),Vector3.new(0,-24,0),params)
    if not floor or floor.Normal.Y<.7 then return false end
    local beforeFloor=workspace:Raycast(session.chassis.Position+Vector3.new(0,3,0),Vector3.new(0,-14,0),params)
    if not beforeFloor or math.abs(floor.Position.Y-beforeFloor.Position.Y)>4 then return false end
    brake();check()
    if math.abs(session.speed or 0)>1 then return false end
    local remainingDelta=flat(finish-session.chassis.Position)
    if remainingDelta:Dot(direction)<-2 then return false end
    distance=remainingDelta.Magnitude
    if distance<1 then return true end
    direction=remainingDelta.Unit
    if not buildingClear(session.chassis.Position,finish)then return false end
    beforeFloor=workspace:Raycast(session.chassis.Position+Vector3.new(0,3,0),Vector3.new(0,-14,0),params)or beforeFloor
    local vehicle=session.model;local character=player.Character;local original={}
    local pivot=vehicle:GetPivot();local relative= pivot:ToObjectSpace(character:GetPivot())
    local delta=direction*distance+Vector3.new(0,floor.Position.Y-beforeFloor.Position.Y,0)
    local destination=pivot+delta
    local bounds,extents=vehicle:GetBoundingBox();local bottom=bounds.Position.Y-extents.Y/2-pivot.Position.Y
    local value=Instance.new("CFrameValue");value.Value=pivot
    local support=Instance.new("Part");support.Name="D0TFrostyVehicleFloat";support.Size=Vector3.new(12,.5,14);support.Transparency=1;support.Anchored=true;support.CanTouch=false;support.CanQuery=false;support.Parent=workspace
    local tween;local connection;local cleaned=false
    local function cleanup()
        if cleaned then return end;cleaned=true
        if tween then tween:Cancel()end;if connection then connection:Disconnect()end
        for part,collision in pairs(original)do if part.Parent then part.CanCollide=collision end end
        support:Destroy();value:Destroy()
        if Worker.VehicleTweenCleanup==cleanup then Worker.VehicleTweenCleanup=nil end
    end
    Worker.VehicleTweenCleanup=cleanup
    Worker.VehicleTweenAttempts=(Worker.VehicleTweenAttempts or 0)+1
    local ok,message=xpcall(function()
        connection=RunService.Stepped:Connect(function()
            if not vehicle.Parent then return end
            for _,container in ipairs({vehicle,character})do for _,part in ipairs(container:GetDescendants())do if part:IsA("BasePart")then
                if original[part]==nil then original[part]=part.CanCollide end;part.CanCollide=false
                part.AssemblyLinearVelocity=Vector3.zero;part.AssemblyAngularVelocity=Vector3.zero
            end end end
            session.speed=0;vehicle:PivotTo(value.Value);character:PivotTo(value.Value*relative)
            support.CFrame=CFrame.new(value.Value.Position+Vector3.new(0,bottom-.3,0))
        end)
        local speed=arrival and(Config.ArrivalTweenSpeed or 35)or 80
        local duration=arrival and math.max(.6,distance/speed)or distance/speed
        tween=game:GetService("TweenService"):Create(value,TweenInfo.new(duration,arrival and Enum.EasingStyle.Quad or Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{Value=destination})
        tween:Play()
        while tween.PlaybackState==Enum.PlaybackState.Playing do check();assert(owner:CanVehicleTween(vehicle),"หยุด Tween · ไม่ได้ควบคุมรถ");task.wait(.04)end
        check();assert((vehicle:GetPivot().Position-destination.Position).Magnitude<10,"Vehicle Tween corrected")
    end,tostring)
    cleanup()
    if not ok then Worker.VehicleTweenDisabled=true;Worker.VehicleTweenFailure=tostring(message);return false end
    task.wait(.5);check()
    if(vehicle:GetPivot().Position-destination.Position).Magnitude>12 then Worker.VehicleTweenDisabled=true;Worker.VehicleTweenFailure="Vehicle moved back";return false end
    Worker.VehicleTweens=(Worker.VehicleTweens or 0)+1;Worker.LastTweenObstacle=arrival and"shop-arrival"or obstacle:GetFullName();if arrival then Worker.ArrivalTween=true end
    return true
end
function Worker.PlanAlleyExit(target,expected)
    Worker.AlleyExit=nil
    if not expected or not session or math.abs(session.chassis.Position.X)<=85 then return end
    local source=session.chassis.Position
    local mouth=alleyMouth(source)
    if not mouth then return end
    local destinationMouth=alleyMouth(target)
    if destinationMouth and source.X*target.X>0 and math.abs(destinationMouth.Z-mouth.Z)<20 then return end
    Worker.AlleyExit={Mouth=mouth,Side=source.X<0 and-1 or 1}
end
function Worker.TryExitAlley(target)
    local plan=Worker.AlleyExit
    if not plan or plan.Done or not session then return false end
    local position=session.chassis.Position
    if math.abs(position.X)>170 or math.abs(position.Z-plan.Mouth.Z)>25 then return false end
    local side=target.X<0 and-1 or 1
    local destination=Vector3.new(side*Config.LaneOffset,position.Y,plan.Mouth.Z)
    Worker.EmergencyBrake=true;status("เบรคก่อนออกซอย")
    local ok,result=pcall(tweenVehiclePast,nil,destination-position,destination)
    Worker.EmergencyBrake=false
    if ok and result then
        local direction=math.abs(target.Z-plan.Mouth.Z)>25 and Vector3.new(0,0,target.Z-plan.Mouth.Z)or target-session.chassis.Position
        Worker.FaceDirection(direction)
        plan.Done=true;Worker.AlleyExitTweens=(Worker.AlleyExitTweens or 0)+1
        status("ออกซอยแล้ว · กำลังขี่ต่อ")
        return true
    end
    return false
end

function Worker.TryEnterAlley(target,expected)
    if not expected or not session or math.abs(session.chassis.Position.X)>=85 then return false end
    local mouth=alleyMouth(target)
    if not mouth then return false end
    local key=expected..":"..tostring(target.X)..":"..tostring(target.Z)
    if Worker.AlleyEntered==key then return false end
    local position=session.chassis.Position
    local approach=math.clamp(brakeDistance(math.abs(session.speed or 0),0,sessionKind=="Car")+8,24,180)
    if math.abs(position.Z-mouth.Z)>approach then return false end
    status("ค่อย ๆ เบรคก่อนถึงปากซอย")
    brake();check()
    -- First reach the mouth on the road; rotate before crossing the kerb.
    local front=Vector3.new(position.X<0 and-Config.LaneOffset or Config.LaneOffset,session.chassis.Position.Y,mouth.Z)
    if flat(front-session.chassis.Position).Magnitude>3 and not tweenVehiclePast(nil,front-session.chassis.Position,front)then return false end
    local side=target.X<0 and-1 or 1
    if not Worker.FaceDirection(Vector3.new(side,0,0))then return false end
    local destination=Vector3.new(side*math.min(110,math.abs(target.X)),session.chassis.Position.Y,mouth.Z)
    if not tweenVehiclePast(nil,destination-session.chassis.Position,destination)then return false end
    Worker.FaceDirection(Vector3.new(side,0,0))
    Worker.AlleyEntered=key
    Worker.AlleyEntryTweens=(Worker.AlleyEntryTweens or 0)+1
    status("เข้าปากซอยแล้ว · ขี่ต่อไปหาจุดรับส่ง")
    return true
end

function Worker.TryDirectArrival(target,expected)
    if not expected or not session or flat(target-session.chassis.Position).Magnitude>45 then return false end
    local distance=flat(target-session.chassis.Position).Magnitude
    local speed=math.abs(session.speed or 0)
    if speed*speed/(2*Config.ComfortDecel)+8>distance then return false end
    local mouth=alleyMouth(target)
    if mouth and math.abs(session.chassis.Position.X)<85 then return false end
    local destination=roadsideTarget(target)
    local direction=destination-session.chassis.Position
    if flat(direction).Magnitude<2 then return false end
    if tweenVehiclePast(nil,direction,destination)then
        Worker.FaceDirection(direction)
        brake();Worker.DirectArrival=true
        return true
    end
    return false
end

function Worker.DriveTo(target,leg,expected)
    assert(session,"Prepare the vehicle first")
    local chassis=session.chassis
    local dropoff=expected=="ToHome"
    Worker.PlanAlleyExit(target,expected)
    Worker.TryExitAlley(target)
    if expected and Config.ObstacleTween and math.abs(chassis.Position.X)<85 and chassis.Position.X*target.X<0 then
        local across=Vector3.new(target.X<0 and-Config.LaneOffset or Config.LaneOffset,chassis.Position.Y,chassis.Position.Z)
        if tweenVehiclePast(nil,across-chassis.Position,across)then Worker.CrossLaneTweens=(Worker.CrossLaneTweens or 0)+1;Worker.FaceDirection(Vector3.new(0,0,target.Z-session.chassis.Position.Z))end
    end
    Worker.TryEnterAlley(target,expected)
    if Worker.TryDirectArrival(target,expected)then return end
    local terminalStopRadius=dropoff and 4 or(expected and 10 or Config.StopRadius)
    if expected then
        local key=tostring(player:GetAttribute("DeliveryJob"))..":"..expected
        if not Worker.LegWatch or Worker.LegWatch.Key~=key then
            Worker.LegWatch={Key=key,State=expected,Best=(flat(chassis.Position)-flat(target)).Magnitude,ProgressAt=os.clock()}
        end
    end
    if expected and not dropoff and player:GetAttribute("DeliveryArrived")==true then brake();return end
    if Config.TweenArrival and(flat(chassis.Position)-flat(target)).Magnitude<40 then
        if tweenVehiclePast(nil,target-chassis.Position,Config.ArrivalGoal or target)then return end
    end
    if(flat(chassis.Position)-flat(target)).Magnitude<22 and math.abs(chassis.Position.Y-target.Y)<12 then brake();return end
    local driveTarget=target
    if expected then
        driveTarget=roadsideTarget(target)
    end
    Worker.DriveTarget=driveTarget
    local model
    local function replaceRoute(points,recovery)
        model=routeModel(points);model.Recovery=recovery==true;Worker.Route=model.Points
        Worker.RouteGeneration=(Worker.RouteGeneration or 0)+1
    end
    local function replan()replaceRoute(smoothRoute(laneRoute(driveTarget)))end
    replan()
    local started=os.clock();local pauseBase=Worker.ManualPauseTotal or 0;local improvedAt=os.clock();local lastProgress=0
    local motionAt,motionPosition=os.clock(),flat(chassis.Position)
    local obstacleAt,cachedHit,cachedDistance=0,nil,math.huge
    local braking=false;local throttleControl={};local goalApproach=false;local offRouteAt;local planAt=-math.huge
    local approachRefreshed=false
    Worker.Recoveries=0;status(leg or"กำลังขับรถ")
    while true do
        local paused=check()
        if paused>0 then improvedAt+=paused;motionAt+=paused;offRouteAt=nil;planAt+=paused;obstacleAt=0 end
        if expected then
            assert(player:GetAttribute("DeliveryState")==expected,"Fare state changed")
            -- At dropoff, continue a little inside the circle to the roadside parking point.
            if not dropoff and player:GetAttribute("DeliveryArrived")==true then brake();return end
        end
        assert(os.clock()-started-((Worker.ManualPauseTotal or 0)-pauseBase)<Config.TripTimeout,"Route timed out")
        local position=flat(chassis.Position);local pos2=Vector2.new(position.X,position.Z)
        local speed=flat(chassis.AssemblyLinearVelocity).Magnitude
        local crossTrack=projectRoute(model,pos2,speed)
        local remaining=math.max(0,model.Length-model.Progress)
        local terminal=(pos2-model.Points[#model.Points]).Magnitude
        local realRemaining=(position-flat(target)).Magnitude
        if Config.TweenArrival and realRemaining<40 then
            if tweenVehiclePast(nil,target-chassis.Position,Config.ArrivalGoal or target)then return end
        end
        local watch=Worker.LegWatch
        if expected and watch and realRemaining<watch.Best-20 then watch.Best=realRemaining;watch.ProgressAt=os.clock()end
        -- Distant destination geometry may not be streamed when the fare starts.
        if expected and realRemaining<160 and not approachRefreshed then
            approachRefreshed=true;driveTarget=roadsideTarget(target);Worker.DriveTarget=driveTarget
            replan();lastProgress=0;improvedAt=os.clock();cachedHit=nil;cachedDistance=math.huge;obstacleAt=0;goalApproach=false
            continue
        end
        if Worker.TryExitAlley(target)then
            replan();lastProgress=0;improvedAt=os.clock();motionAt=os.clock();motionPosition=flat(chassis.Position)
            cachedHit=nil;cachedDistance=math.huge;obstacleAt=0;goalApproach=false;continue
        end
        if Worker.TryEnterAlley(target,expected)then
            replan();lastProgress=0;improvedAt=os.clock();motionAt=os.clock();motionPosition=flat(chassis.Position)
            cachedHit=nil;cachedDistance=math.huge;obstacleAt=0;goalApproach=false;continue
        end
        if Worker.TryDirectArrival(target,expected)then return end
        if terminal<terminalStopRadius and(not expected or realRemaining<31)then brake();return end
        if model.Progress>lastProgress+1 then lastProgress,improvedAt=model.Progress,os.clock()end
        if os.clock()-motionAt>2.5 then
            if(position-motionPosition).Magnitude<4 and((Worker.CommandThrottle or 0)>.3 or cachedDistance<50)then improvedAt=0 end
            motionAt,motionPosition=os.clock(),position
        end
        if crossTrack>18 then offRouteAt=offRouteAt or os.clock()else offRouteAt=nil end
        local aligning=Worker.Telemetry and math.abs(Worker.Telemetry.HeadingError or 0)>1 and speed<15
        if(os.clock()-improvedAt>(aligning and 12 or 3.5)or(offRouteAt and os.clock()-offRouteAt>1))and os.clock()-planAt>2 then
            Worker.Recoveries+=1;status("กำลังจัดรถกลับเข้าเส้นทาง")
            brake()
            local stuck=os.clock()-improvedAt>3.5
            local canPass=Config.ObstacleTween and owner:CanVehicleTween(session.model)
            if stuck and canPass then
                local routeAim=routePoint(model,math.min(model.Length,model.Progress+35))
                local direction=Vector3.new(routeAim.X-chassis.Position.X,0,routeAim.Y-chassis.Position.Z)
                local direct=direction.Magnitude>.1 and routeCast(chassis.Position,chassis.Position+direction.Unit*35)
                if direct and tweenVehiclePast(direct,direction)then
                    replan();planAt=os.clock();offRouteAt=nil;lastProgress=0;improvedAt=os.clock();motionAt=os.clock();motionPosition=flat(chassis.Position)
                    cachedHit=nil;cachedDistance=math.huge;obstacleAt=0;goalApproach=false;continue
                end
            end
            if stuck and not canPass then reverseFromObstacle()end
            local nearby=expected and realRemaining<100 and roadsideTarget(target,true)
            local detour
            if nearby and nearby~=target then
                driveTarget=nearby;Worker.DriveTarget=nearby
                detour={Vector2.new(chassis.Position.X,chassis.Position.Z),Vector2.new(nearby.X,nearby.Z)}
            elseif not canPass then detour=cachedHit and detourRoute(model.Points,model.Cursor+1,cachedHit.Instance)end
            if detour then replaceRoute(detour,true);Worker.Detours=(Worker.Detours or 0)+1 else replan()end
            planAt=os.clock();offRouteAt=nil;lastProgress=0;improvedAt=os.clock();motionAt=os.clock();motionPosition=flat(chassis.Position)
            cachedHit,cachedDistance=nil,math.huge;obstacleAt=0;goalApproach=false;braking=false;throttleControl={}
            continue
        end
        local top=speedLimit()
        automaticGear(speed,Worker.Limits.NativeTopStuds)
        local wanted,reason=top,"cruise"
        if Worker.AlleyExit and not Worker.AlleyExit.Done then
            local plan=Worker.AlleyExit
            local edge=Vector3.new(plan.Side*85,chassis.Position.Y,plan.Mouth.Z)
            local exitDistance=flat(edge-chassis.Position).Magnitude
            local allowed=math.sqrt(2*Config.ComfortDecel*math.max(0,exitDistance-18))
            if allowed<wanted then wanted,reason=allowed,"เบรคก่อนออกซอย"end
        end
        if expected then
            local mouth=alleyMouth(target)
            local distance=mouth and math.abs(chassis.Position.X)<85 and math.abs(chassis.Position.Z-mouth.Z)or realRemaining
            local comfortable=math.sqrt(2*Config.ComfortDecel*math.max(0,distance-12))
            if comfortable<wanted then wanted,reason=comfortable,"ค่อย ๆ เบรคก่อนเข้าซอย"end
        end
        if model.Recovery then wanted,reason=24,"recovery"end
        local sharp=nextTurn(model)
        local pendingMouth=expected and math.abs(chassis.Position.X)<85 and alleyMouth(target)
        if not pendingMouth and Config.TurnTween and sharp and owner:IsSharpDriveTurn(sharp.Angle)and sharp.Entry-model.Progress<=math.max(16,brakeDistance(speed,0,sessionKind=="Car")+16) and sharp.Exit>model.Progress then
            local exitArc=math.min(model.Length,sharp.Exit+12)
            local exit=routePoint(model,exitArc)
            local destination=Vector3.new(exit.X,chassis.Position.Y,exit.Y)
            if tweenVehiclePast(nil,destination-chassis.Position,destination)then
                Worker.CornerTweens=(Worker.CornerTweens or 0)+1
                local nextPoint=routePoint(model,math.min(model.Length,exitArc+18))
                Worker.FaceDirection(Vector3.new(nextPoint.X-chassis.Position.X,0,nextPoint.Y-chassis.Position.Z))
                model.Progress=exitArc;model.LatchedTurn=nil;model.TurnIndex+=1
                local _,exitSegment=routePoint(model,exitArc);model.Cursor=exitSegment
                lastProgress=exitArc;improvedAt=os.clock();motionAt=os.clock();motionPosition=flat(chassis.Position)
                cachedHit=nil;cachedDistance=math.huge;obstacleAt=0;goalApproach=false;continue
            end
        end
        local cornerCap,turnDistance=turnLimit(model,speed,sessionKind=="Car")
        if cornerCap and cornerCap<wanted and not(Config.TurnTween and model.LatchedTurn and owner:IsSharpDriveTurn(model.LatchedTurn.Angle))then wanted,reason=cornerCap,"next-turn"end
        local slopePoint=routePoint(model,model.Progress+40)
        local slopeY=groundY(Vector3.new(slopePoint.X,chassis.Position.Y,slopePoint.Y))
        local roadY=groundY(chassis.Position)
        local down=roadY-slopeY>1
        local upcoming=nextTurn(model)
        if down and upcoming and not(Config.TurnTween and owner:IsSharpDriveTurn(upcoming.Angle))and upcoming.Entry-model.Progress<brakeDistance(speed,math.min(upcoming.Speed,45),sessionKind=="Car")*1.2 then
            model.LatchedTurn=upcoming
            wanted=math.min(wanted,upcoming.Speed,45);reason="bridge-turn"
        end
        if not Config.TweenArrival and remaining<=brakeDistance(speed,8,sessionKind=="Car")+12 then goalApproach=true end
        if goalApproach then
            local approach=remaining<12 and 5 or 18
            if approach<wanted then wanted,reason=approach,"destination"end
        end
        local lookahead=math.clamp(12+speed*.13,14,36)
        local aimArc=model.Progress+lookahead
        local corner=nextTurn(model)
        if corner and model.Progress<corner.Entry and speed>corner.Speed+10 then aimArc=math.min(aimArc,corner.Entry)end
        local aim2=routePoint(model,aimArc)
        -- A lookahead chord must not cut across the inside of a kerbed turn.
        while aimArc-model.Progress>3 do
            if not routeCast(chassis.Position,Vector3.new(aim2.X,chassis.Position.Y,aim2.Y))then break end
            aimArc=model.Progress+(aimArc-model.Progress)*.6
            aim2=routePoint(model,aimArc)
            if wanted>12 then wanted,reason=12,"narrow-turn"end
        end
        local aim=Vector3.new(aim2.X,0,aim2.Y)
        local aimDelta=aim-position
        if aimDelta.Magnitude<1 then aimDelta=(CFrame.Angles(0,session.heading,0)).LookVector*2 end
        local desired=math.atan2(-aimDelta.X,-aimDelta.Z)
        local angle=math.atan2(math.sin(desired-session.heading),math.cos(desired-session.heading))
        if model.Recovery and crossTrack<5 and math.abs(angle)<.2 then
            local ground=workspace:Raycast(chassis.Position+Vector3.new(0,2,0),Vector3.new(0,-8,0),castParams)
            if ground and ground.Material==Enum.Material.Asphalt then model.Recovery=false end
        end
        if math.abs(angle)>.5 and wanted>18 then wanted,reason=18,"align-route"end
        if crossTrack>8 and wanted>35 then wanted,reason=35,"align-route"end
        if math.abs(angle)>1.15 and wanted>8 then wanted,reason=8,"align-route"end
        local scanDistance=math.clamp(speed*(sessionKind=="Car"and 2.1 or 1.9)+30,45,550)
        if os.clock()>=obstacleAt then
            obstacleAt=os.clock()+.15;cachedHit,cachedDistance=nil,math.huge
            local from=chassis.Position;local travelled=0;local arc=model.Progress
            while travelled<scanDistance and arc<model.Length do
                local _,segment=routePoint(model,arc+.001)
                local step=math.min(16,scanDistance-travelled,model.Length-arc,model.Arc[segment+1]-arc)
                if step<.1 then break end
                local point=routePoint(model,arc+step);local to=Vector3.new(point.X,from.Y,point.Y)
                local found=routeCast(from,to)
                if found then cachedHit,cachedDistance=found,travelled+found.Distance;break end
                travelled+=step;arc+=step;from=Vector3.new(to.X,groundY(to)+1,to.Z)
            end
        end
        if Config.ObstacleTween and owner:CanVehicleTween(session.model)then
            local forward=flat(chassis.CFrame.LookVector)
            if forward.Magnitude>.1 then
                local direct=routeCast(chassis.Position,chassis.Position+forward.Unit*35)
                if direct then cachedHit=direct;cachedDistance=direct.Distance end
            end
        end
        if cachedHit then
            Worker.Obstacle=cachedHit.Instance:GetFullName()
            if Config.ObstacleTween and cachedDistance<40 and owner:CanVehicleTween(session.model)then
                local passDirection=aimDelta
                if tweenVehiclePast(cachedHit,passDirection)then
                    replan();lastProgress=0;improvedAt=os.clock();motionAt=os.clock();cachedHit=nil;cachedDistance=math.huge;obstacleAt=0;goalApproach=false
                    continue
                end
            end
            if cachedDistance<=math.max(18,brakeDistance(speed,0,sessionKind=="Car")+8)then
                local cap=cachedDistance<18 and 0 or 14
                if cap<wanted then wanted,reason=cap,"obstacle"end
            end
            if not(Config.ObstacleTween and owner:CanVehicleTween(session.model))and cachedDistance<65 and speed<26 and os.clock()-planAt>2 then
                brake()
                local detour=detourRoute(model.Points,model.Cursor+1,cachedHit.Instance)
                planAt=os.clock()
                if detour then
                    replaceRoute(detour,true);Worker.Detours=(Worker.Detours or 0)+1
                    lastProgress=0;improvedAt=os.clock();cachedHit,cachedDistance=nil,math.huge;obstacleAt=0;goalApproach=false
                    continue
                end
            end
        else Worker.Obstacle=nil end
        if math.abs(angle)>.8 and speed<8 and owner:CanVehicleTween(session.model)and os.clock()-(Worker.LastTurnTweenAt or 0)>1.5 then
            Worker.LastTurnTweenAt=os.clock()
            if Worker.FaceDirection(aimDelta)then improvedAt=os.clock();motionAt=os.clock();continue end
        end
        local yaw
        if sessionKind=="Bike"then yaw=math.abs(BikeShared.yawRate(math.max(speed,2),1,session.wheelbase))
        else
            local shared=require(RS.CarShared);local steer=session.model:GetAttribute("MaxSteer")or shared.MAX_STEER
            local maxAngle=math.min(steer,shared.maxSteer(speed)*steer/shared.MAX_STEER)
            yaw=math.abs(shared.yawRate(math.max(speed,2),maxAngle,session.wheelbase))
        end
        local requestedYaw=2*math.max(speed,2)*math.sin(angle)/math.max(aimDelta.Magnitude,3)
        local steer=math.clamp(-requestedYaw/math.max(yaw,.01),-1,1)
        if math.abs(angle)>.9 then steer=math.clamp(-angle*1.5,-1,1)end
        if math.abs(angle)>1.5 and speed>25 then steer=0 end
        local throttle
        throttle,braking=driveThrottle(throttleControl,speed,wanted,os.clock())
        session.seat.SteerFloat=steer;session.seat.ThrottleFloat=throttle
        Worker.CommandSteer,Worker.CommandThrottle=steer,throttle
        safety()
        Worker.PeakSpeed=math.max(Worker.PeakSpeed,speed)
        if speed>4 then Worker.LastRecovery=nil;Worker.Status=leg or"กำลังขับรถ"end
        Worker.Telemetry={Leg=leg,Speed=speed,TargetSpeed=wanted,Remaining=realRemaining,
            Waypoint=model.Cursor+1,Waypoints=#model.Points,RouteProgress=model.Progress,PathRemaining=remaining,
            NextTurnDistance=turnDistance,BrakeReason=reason,BrakeEpisodes=throttleControl.Episodes or 0,Downhill=down,StalledFor=watch and(os.clock()-watch.ProgressAt)or 0,Braking=braking,HeadingError=angle,Lookahead=lookahead,
            CrossTrack=crossTrack,Position=tostring(position),CommandSteer=steer,CommandThrottle=throttle,NetworkOwner=isnetworkowner(chassis)}
        task.wait(.03)
    end
end

local function waitFor(predicate, seconds, description)
    local deadline = os.clock() + seconds
    repeat
        deadline+=check()
        if predicate() then return end
        task.wait(.15)
    until os.clock() > deadline
    error(description)
end

local function prepareReadyVehicle()
    prepareVehicle()
    if not Config.RandomVehicle then return end
    local tries=0
    while CareShared.fuel(session.model)<=5 do
        check();tries+=1;assert(tries<32,"ไม่มีรถที่มีน้ำมันพร้อมเดินทาง")
        owner.ShopVehicleFuel[Config.VehicleId]=CareShared.fuel(session.model)
        Config.RandomChosen=false;prepareVehicle()
    end
end
local function serviceFuel(force)
    check()
    if not session or not session.model.Parent then return end
    local vehicle=session.model
    if CareShared.fuel(vehicle)>(force and 99 or Config.RefuelBelow or 30)then return end
    local delivery=player:GetAttribute("DeliveryState")
    if not force and(delivery=="ToShop"or delivery=="ToHome")and CareShared.fuel(vehicle)>5 then return end
    brake();status("กำลังเติมน้ำมัน")
    Worker.CommandThrottle,Worker.CommandSteer=0,0
    local before=player:GetAttribute("Cash")or 0
    if ShopShared.count(player,"FuelCan")<1 then
        local item=assert(ShopShared.item("FuelCan"))
        assert(before>=item.price,"เงินไม่พอซื้อถังน้ำมัน")
        local bought,message=invoke(Remotes.Shop,"Buy","FuelCan");assert(bought,tostring(message))
        Worker.FuelSpent+=math.max(0,before-(player:GetAttribute("Cash")or before))
        task.wait(.2)
    end
    local character=player.Character;local humanoid=character:FindFirstChildOfClass("Humanoid")
    restore();session=nil
    if humanoid.SeatPart then
        if isCar(vehicle)then Net.fire(RS.CarRemote,"Exit",vehicle)else Net.fire(RS.PCX160Remote,"Dismount","Start")end
        local deadline=os.clock()+8
        repeat check();task.wait(.1)until not humanoid.SeatPart or os.clock()>deadline
        assert(not humanoid.SeatPart,"ยังลงจากรถเพื่อเติมน้ำมันไม่ได้")
        task.wait(.4)
    end
    local root=character:FindFirstChild("HumanoidRootPart")
    if root and(root.Position-vehicle:GetPivot().Position).Magnitude>12 then walk(vehicle:GetPivot():PointToWorldSpace(Vector3.new(-5,0,0)))end
    local tool
    for _,container in ipairs({character,player:FindFirstChildOfClass("Backpack")})do
        if container then for _,item in ipairs(container:GetChildren())do
            if item:IsA("Tool")and(item:GetAttribute("FuelCan")or item:GetAttribute("ShopItem")=="FuelCan")then tool=item;break end
        end end
    end
    if tool and tool.Parent~=character then humanoid:EquipTool(tool);task.wait(.15)end
    local used,message=invoke(Remotes.Shop,"Use","FuelCan",vehicle)
    assert(used,tostring(message))
    local deadline=os.clock()+12
    repeat check();task.wait(.2)until CareShared.fuel(vehicle)>=95 or os.clock()>deadline
    assert(CareShared.fuel(vehicle)>=95,"เกมยังไม่ยืนยันการเติมน้ำมัน")
    humanoid:UnequipTools()
    Worker.Refuels=(Worker.Refuels or 0)+1
    prepareVehicle()
end
function Worker.RefuelNow()return serviceFuel(true)end

local function oneFare()
    serviceFuel(false)
    local before = player:GetAttribute("Cash") or 0
    local beforeEarned=player:GetAttribute("DeliveryEarned")or 0
    local count = player:GetAttribute("DeliveryJobs") or 0
    local nextStart, nextAccept = 0, 0
    while true do
        check()
        local state = player:GetAttribute("DeliveryState") or "Off"
        if state == "ToShop" or state == "ToHome" then break end
        local now = os.clock()
        if state == "Off" and now >= nextStart then
            status("กำลังหางาน · "..jobLabel)
            local ok, message = invoke(Remotes.Delivery, "Start", mode)
            nextStart = now + 1
            if not ok then Worker.LastAcceptMessage = tostring(message) end
        elseif state == "Offer" and now >= nextAccept then
            status("กำลังรับงาน · "..jobLabel)
            Worker.OfferSeenAt = now
            local ok, message = invoke(Remotes.Delivery, "Accept", nil)
            nextAccept = os.clock() + .5
            Worker.LastAcceptMessage = ok and nil or tostring(message)
            if ok then Worker.AcceptedAt = os.clock() end
        end
        RunService.Heartbeat:Wait()
    end
    waitFor(function() return player:GetAttribute("DeliveryJob") ~= nil end, 5, "Accepted fare data unavailable")
    local data = HttpService:JSONDecode(assert(player:GetAttribute("DeliveryJob"), "No accepted fare"))
    local roundStarted=tonumber(data.acceptedAt)or workspace:GetServerTimeNow()
    assert(data.kind==(mode=="grab"and"ride"or mode),"ประเภทงานไม่ตรงกับอาชีพที่เลือก")
    Worker.Fare = data.fee
    if player:GetAttribute("DeliveryState") == "ToShop" then
        if player:GetAttribute("DeliveryArrived") ~= true then
            Worker.DriveTo(Vector3.new(data.shop.x, data.shop.y, data.shop.z), "Pickup", "ToShop")
        end
        waitFor(function() return player:GetAttribute("DeliveryArrived") == true end, 12, "Pickup arrival not confirmed")
        local ok, message = invoke(Remotes.Delivery, "Confirm", nil)
        assert(ok, tostring(message))
        waitFor(function() return player:GetAttribute("DeliveryState") == "ToHome" end, 15, "Passenger did not board")
    end
    assert(player:GetAttribute("DeliveryState") == "ToHome", "Passenger is not on board")
    Worker.DriveTo(Vector3.new(data.home.x, data.home.y, data.home.z), "Dropoff", "ToHome")
    waitFor(function() return player:GetAttribute("DeliveryArrived") == true end, 12, "Dropoff arrival not confirmed")
    local ok, message = invoke(Remotes.Delivery, "Confirm", nil)
    assert(ok, tostring(message))
    waitFor(function() return (player:GetAttribute("DeliveryJobs") or 0) > count end, 15, "Payment not confirmed")
    Worker.Trips += 1
    Worker.Earned=math.max(0,(player:GetAttribute("DeliveryEarned")or 0)-(Worker.StartEarned or 0))
    owner:SendWorkWebhook(tostring(data.acceptedAt or count)..":"..tostring(count),jobLabel,math.max(0,(player:GetAttribute("DeliveryEarned")or 0)-beforeEarned),workspace:GetServerTimeNow()-roundStarted)
    status(("Completed %d fare(s), earned %d"):format(Worker.Trips, Worker.Earned))
    RunService.Heartbeat:Wait()
end

local function recoverFreshVehicle(resetCharacter)
    local oldSession=session
    if oldSession and not oldSession.crashed then pcall(brake)end
    stopInputs();restore();session=nil;Worker.LegWatch=nil
    local function garage(action,...)
        local args=table.pack(...);local message
        for attempt=1,5 do
            if cancelled()then error("Stopped",0)end
            local ok,value,detail=pcall(Net.invoke,Remotes.Garage,action,table.unpack(args,1,args.n))
            if ok and(value==true or type(value)=="table")then task.wait(1.1);return value,detail end
            message=ok and detail or value
            task.wait(1.2)
        end
        error(tostring(message),0)
    end
    if resetCharacter then
        status("งานค้าง: ยกเลิกงานและรีเซ็ตตัวละคร")
        local state=player:GetAttribute("DeliveryState")
        if state=="ToShop"or state=="ToHome"then
            local ok,message=Net.invoke(Remotes.Delivery,"Cancel",nil)
            assert(ok,tostring(message))
            local untilAt=os.clock()+6
            repeat task.wait(.1);state=player:GetAttribute("DeliveryState")until(state~="ToShop"and state~="ToHome")or os.clock()>untilAt or cancelled()
            assert(state~="ToShop"and state~="ToHome","เกมยังไม่ยืนยันการยกเลิกงาน")
            Worker.CancelledFares=(Worker.CancelledFares or 0)+1
        end
        if cancelled()then return end
        local character=player.Character;local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health>0 then humanoid.Health=0 end
        local untilAt=os.clock()+40
        repeat
            if cancelled()then return end
            task.wait(.2)
            local current=player.Character
            local h=current and current:FindFirstChildOfClass("Humanoid")
            if current~=character and h and h.Health>0 and current:FindFirstChild("HumanoidRootPart")then break end
        until os.clock()>untilAt
        local current=player.Character;local h=current and current:FindFirstChildOfClass("Humanoid")
        assert(current~=character and h and h.Health>0,"ยังรอเกิดใหม่")
        Worker.Resets=(Worker.Resets or 0)+1;Worker.NeedsReset=false
    else
        status("รถชน: เก็บคันเดิมและเรียกรถใหม่")
        local untilAt=os.clock()+8
        while oldSession and oldSession.crashed and os.clock()<untilAt and not cancelled()do task.wait(.2)end
        local character=player.Character;local h=character and character:FindFirstChildOfClass("Humanoid")
        if h and h.SeatPart then
            if oldSession and isCar(oldSession.model)then Net.fire(RS.CarRemote,"Exit",oldSession.model,"Driver")
            else Net.fire(RS.PCX160Remote,"Dismount","Start")end
            local dismountAt=os.clock()+6
            while h.SeatPart and os.clock()<dismountAt and not cancelled()do task.wait(.1)end
            assert(not h.SeatPart,"ยังออกจากรถคันเก่าไม่ได้")
        end
    end
    if cancelled()then return end
    local list
    local oldVehicle=oldSession and oldSession.model
    if(oldVehicle and oldVehicle.Parent)or(player:GetAttribute("VehicleCount")or 0)>0 then
        local ok,message=garage("Despawn")
        assert(ok,tostring(message))
        local untilAt=os.clock()+6
        while oldVehicle and oldVehicle.Parent and os.clock()<untilAt and not cancelled()do task.wait(.1)end
        assert(not oldVehicle or not oldVehicle.Parent,"เกมยังไม่เก็บรถคันเก่า")
    end
    list=garage("List")
    local untilAt=os.clock()+math.max(.8,tonumber(list and list.cooldown)or 0)
    while os.clock()<untilAt and not cancelled()do task.wait(.1)end
    if cancelled()then return end
    if Config.SpawnOnRoad then Worker.MoveCharacterToRoad()end
    local ok,message=garage("Spawn",Config.VehicleId)
    assert(ok,tostring(message));Worker.NoWalk=true
    Worker.FreshVehicles=(Worker.FreshVehicles or 0)+1
    Worker.NeedsFreshVehicle=false
    task.wait(.8)
end

function Worker.Run(maxTrips)
    assert(not Worker.Running,"Already running")
    Worker.Running,Worker.Cancelled=true,false
    Worker.StartedAt=os.clock();Worker.StartEarned=player:GetAttribute("DeliveryEarned")or 0
    local limit=maxTrips==nil and Config.MaxTrips or maxTrips
    local fatal
    while not cancelled()and(limit==0 or Worker.Trips<limit)do
        local ok,message=xpcall(function()
            waitFor(function()return player:GetAttribute("ProfileReady")and player.Character and player.Character:FindFirstChildOfClass("Humanoid")and player.Character.Humanoid.Health>0 end,30,"รอเกิดใหม่")
            if Worker.NeedsReset or Worker.NeedsFreshVehicle then recoverFreshVehicle(Worker.NeedsReset==true)end
            if player:GetAttribute("Job")~=jobId then
                if jobId=="Grab"then
                    local accepted,reason=invoke(Remotes.Job,"Plan",jobId);assert(accepted,tostring(reason))
                else
                    restore();session=nil
                    local enrollment=buildStationWorker(owner,jobId);Worker.Enrollment=enrollment
                    local accepted,reason=enrollment.Run(0);Worker.Enrollment=nil
                    assert(accepted,tostring(reason));check()
                end
            end
            if not session or not session.model.Parent or session.seat.Occupant~=player.Character.Humanoid then
                restore();session=nil;prepareReadyVehicle()
            end
            oneFare()
        end,tostring)
        if not ok and not cancelled()then
            Worker.LastRecovery=tostring(message);Worker.Remounts=(Worker.Remounts or 0)+1
            if Worker.NeedsReset or Worker.NeedsFreshVehicle then
                local recovered,reason=pcall(recoverFreshVehicle,Worker.NeedsReset==true)
                if not recovered then Worker.LastRecovery=tostring(reason)end
            else
                status("กำลังกลับขึ้นรถเพื่อทำงานต่อ")
                stopInputs();restore();session=nil
            end
            task.wait(2)
        end
    end
    pcall(brake);restore();Worker.StoppedAt=os.clock()
    local state=player:GetAttribute("DeliveryState")
    if state=="Searching"or state=="Offer"then pcall(Net.invoke,Remotes.Delivery,"Stop",nil)end
    Worker.Running=false;status("หยุดทำงานแล้ว")
    return fatal==nil,fatal
end

function Worker.ShopTrip(target)
    assert(not Worker.Running,"Already running")
    Worker.Running,Worker.Cancelled=true,false
    Config.TripTimeout=180;Config.StopRadius=12;Config.ObstacleTween=true;Config.TweenArrival=true;Config.DirectMainRoad=true
    Config.ArrivalGoal=target+Vector3.new(target.X<0 and 4 or -4,0,0)
    local ok,message=xpcall(function()
        prepareVehicle()
        local tries=0
        while CareShared.fuel(session.model)<=5 do
            check();tries+=1;assert(tries<32,"ลองรถครบแล้ว · ไม่มีรถที่มีน้ำมันพร้อมเดินทาง")
            owner.ShopVehicleFuel[Config.VehicleId]=CareShared.fuel(session.model)
            Config.RandomChosen=false;prepareVehicle()
        end
        local roadside=Vector3.new(target.X<0 and-48 or 48,target.Y,target.Z)
        Worker.ExitToRoad(roadside)
        Worker.DriveTo(roadside,"กำลังขับไปร้านลูกสูบ")
        brake()
        local vehicle=session.model;local kind=sessionKind
        restore();session=nil
        status("กำลังลงรถเข้าร้าน")
        if kind=="Car"then Net.fire(RS.CarRemote,"Exit",vehicle)
        else Net.fire(RS.PCX160Remote,"Dismount","Start")end
        local humanoid=player.Character:FindFirstChildOfClass("Humanoid")
        local deadline=os.clock()+6
        while humanoid.SeatPart and os.clock()<deadline do assert(not cancelled(),"Stopped");task.wait(.1)end
        assert(not humanoid.SeatPart,"ลงจากรถไม่ได้")
        walk(target+Vector3.new(target.X<0 and 5 or-5,0,0))
        check()
        local shop=workspace:FindFirstChild("PistonShop")
        local prompt=shop and shop:FindFirstChildWhichIsA("ProximityPrompt",true)
        assert(prompt,"ไม่พบปุ่มเปิดร้าน")
        local part=prompt.Parent
        assert(part:IsA("BasePart")and(player.Character.HumanoidRootPart.Position-part.Position).Magnitude<=prompt.MaxActivationDistance+1,"ยังไม่ถึงระยะเปิดร้าน")
        status("กำลังเปิดร้าน")
        fireproximityprompt(prompt)
        task.wait(.5)
        local stockRequestedAt=workspace:GetServerTimeNow()
        owner:RefreshPistonStock()
        for _=1,10 do
            check()
            if not owner.PistonStock.Busy and owner.PistonStock.Key==Config.ShopKey and(owner.PistonStock.UpdatedAt or 0)>=stockRequestedAt and next(owner.PistonStock.Items)then return end
            if owner:CapturePistonStockUI(Config.ShopKey)then return end
            task.wait(.25)
        end
        error("ถึงร้านแล้ว แต่ยังอ่านสต๊อกไม่ได้",0)
    end,tostring)
    if session then pcall(brake)end
    restore();Worker.Running=false
    return ok,message
end

function Worker.FaceDirection(direction)
    if not session or not owner:CanVehicleTween(session.model)then return false end
    direction=flat(direction)
    if direction.Magnitude<1 or math.abs(session.speed or 0)>10 then return false end
    local vehicle=session.model;local character=player.Character
    local chassis=session.chassis
    local from=chassis.CFrame
    local target=CFrame.lookAt(from.Position,from.Position+direction.Unit)
    local relative=from:ToObjectSpace(vehicle:GetPivot())
    local rider=from:ToObjectSpace(character:GetPivot())
    local originals={}
    local value=Instance.new("CFrameValue");value.Value=from
    local priorBrake=session.braking
    stopInputs();session.speed=0;session.braking=true
    local connection,tween;local cleaned=false
    local function cleanup()
        if cleaned then return end;cleaned=true
        if tween then tween:Cancel()end
        if connection then connection:Disconnect()end
        for part,collide in pairs(originals)do if part.Parent then part.CanCollide=collide end end
        session.braking=priorBrake
        value:Destroy()
        if Worker.VehicleTurnCleanup==cleanup then Worker.VehicleTurnCleanup=nil end
    end
    Worker.VehicleTurnCleanup=cleanup
    local ok=xpcall(function()
        connection=RunService.Stepped:Connect(function()
            if not vehicle.Parent then return end
            for _,container in ipairs({vehicle,character})do for _,part in ipairs(container:GetDescendants())do if part:IsA("BasePart")then
                if originals[part]==nil then originals[part]=part.CanCollide end
                part.CanCollide=false;part.AssemblyLinearVelocity=Vector3.zero;part.AssemblyAngularVelocity=Vector3.zero
            end end end
            local cf=value.Value
            local look=cf.LookVector
            session.heading=math.atan2(-look.X,-look.Z);session.travel=session.heading;session.steerIn=0;session.speed=0
            vehicle:PivotTo(cf*relative);character:PivotTo(cf*rider)
        end)
        tween=game:GetService("TweenService"):Create(value,TweenInfo.new(.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Value=target})
        tween:Play()
        while tween.PlaybackState==Enum.PlaybackState.Playing do check();task.wait(.03)end
        session.heading=math.atan2(-direction.X,-direction.Z);session.travel=session.heading;session.steerIn=0
    end,tostring)
    cleanup()
    if ok then Worker.TurnTweens=(Worker.TurnTweens or 0)+1 end
    return ok
end

function Worker.MoveCharacterToRoad()
    check()
    assert(not session,"ลงจากรถก่อนออกไปเสกรถบนถนน")
    local character=player.Character
    local humanoid=assert(character:FindFirstChildOfClass("Humanoid"),"ไม่พบตัวละคร")
    local root=assert(character:FindFirstChild("HumanoidRootPart"),"ไม่พบตัวละคร")
    assert(not humanoid.SeatPart,"ลงจากรถก่อนออกไปเสกรถบนถนน")
    local nearest=assert(Graph.nearest(root.Position),"ไม่พบถนนใกล้ตัว")
    local x=math.abs(nearest.X)<1 and(root.Position.X<0 and-Config.LaneOffset or Config.LaneOffset)or nearest.X
    local goal=Vector3.new(x,root.Position.Y,nearest.Y)
    assert(flat(goal-root.Position).Magnitude<180,"อยู่ไกลถนนเกินไป ขยับเข้าใกล้ถนนก่อนเปิด Grab")
    if flat(goal-root.Position).Magnitude<5 then Worker.RoadSpawnReady=true;return end
    status("กำลัง Tween หลบตึกออกถนนก่อนเสกรถ")
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.RespectCanCollide=true
    params.FilterDescendantsInstances={character,workspace.CurrentCamera}
    local ground=workspace:Raycast(goal+Vector3.new(0,12,0),Vector3.new(0,-40,0),params)
    assert(ground and ground.Normal.Y>.7,"ไม่พบพื้นถนนที่ปลอดภัย")
    local path=PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=false,WaypointSpacing=5})
    path:ComputeAsync(root.Position,ground.Position)
    assert(path.Status==Enum.PathStatus.Success,"หาเส้นทางออกถนนโดยไม่ผ่านตึกไม่ได้ ขยับออกมาหน้าตึกก่อน")
    local points=path:GetWaypoints();Worker.RoadExitPoints=#points
    local deadline=os.clock()+math.max(20,flat(goal-root.Position).Magnitude/12+10)
    local height=humanoid.HipHeight+root.Size.Y*.5
    local tween
    local ok,message=xpcall(function()
        for index=2,#points do
            local target=points[index].Position+Vector3.new(0,height,0)
            while (root.Position-target).Magnitude>1.5 do
                check();assert(os.clock()<deadline,"ออกถนนไม่สำเร็จ ลองขยับออกมาหน้าตึกก่อน")
                assert(player.Character==character and humanoid.Health>0,"ตัวละครเปลี่ยนระหว่างออกถนน")
                local delta=target-root.Position
                local step=delta.Unit*math.min(8,delta.Magnitude)
                assert(buildingClear(root.Position,root.Position+step),"มีตึกขวางทางออกถนน หยุด Tween เพื่อไม่ให้ทะลุตึก")
                local hit=workspace:Blockcast(root.CFrame,Vector3.new(2,3,2),step,params)
                if hit and hit.Normal.Y<.7 then
                    local obstacle=hit.Instance
                    local size=obstacle:IsA("BasePart")and obstacle.Size
                    local cf=size and obstacle.CFrame
                    local height=size and(math.abs(cf.RightVector.Y)*size.X+math.abs(cf.UpVector.Y)*size.Y+math.abs(cf.LookVector.Y)*size.Z)or math.huge
                    assert(height<=7,"มีตึกขวางทางออกถนน หยุด Tween เพื่อไม่ให้ทะลุตึก")
                end
                local destination=CFrame.new(root.Position+step)*root.CFrame.Rotation
                tween=game:GetService("TweenService"):Create(root,TweenInfo.new(step.Magnitude/28,Enum.EasingStyle.Linear),{CFrame=destination})
                Worker.RoadExitTween=tween;tween:Play()
                repeat task.wait(.03)until tween.PlaybackState~=Enum.PlaybackState.Playing or cancelled()or humanoid.Health<=0
                tween:Cancel();Worker.RoadExitTween=nil
                root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
            end
        end
        check();task.wait(.25)
        assert(flat(goal-root.Position).Magnitude<8,"ตัวละครยังไม่ถึงถนน จึงยังไม่เสกรถ")
    end,tostring)
    if tween then tween:Cancel()end;Worker.RoadExitTween=nil;path:Destroy()
    assert(ok,message)
    Worker.RoadSpawnReady=true;Worker.RoadSpawnPosition=tostring(root.Position)
end

function Worker.ExitToRoad(target)
    local position=session.chassis.Position
    local nearest=Graph.nearest(position)
    assert(nearest,"ไม่พบหน้าถนน")
    local goal=Vector3.new(nearest.X,position.Y,nearest.Y)
    if math.abs(goal.X)<1 then goal=Vector3.new(position.X<0 and-Config.LaneOffset or Config.LaneOffset,position.Y,goal.Z)end
    local distance=flat(goal-position).Magnitude
    assert(distance<180,"จุดเสกรถอยู่ไกลถนนเกินไป")
    status("ขึ้นรถแล้ว · กำลัง Tween ออกหน้าถนน")
    local steps=math.max(1,math.ceil(distance/30))
    for i=1,steps do
        check()
        local waypoint=position:Lerp(goal,i/steps)
        if flat(waypoint-session.chassis.Position).Magnitude>2 then
            assert(tweenVehiclePast(nil,waypoint-session.chassis.Position,waypoint),"Tween ออกหน้าถนนไม่ได้")
        end
    end
    local points=laneRoute(target)
    for _,point in ipairs(points)do
        local direction=Vector3.new(point.X-session.chassis.Position.X,0,point.Y-session.chassis.Position.Z)
        if direction.Magnitude>8 then
            Worker.FaceDirection(direction)
            break
        end
    end
    Worker.ExitedToRoad=true
end

function Worker.TestDrive(target)
    assert(not Worker.Running, "Already running")
    Worker.Running, Worker.Cancelled, Worker.PeakSpeed = true, false, 0
    local ok, message = xpcall(function()
        prepareReadyVehicle()
        if Config.ExitToRoad then Worker.ExitToRoad(target)end
        Worker.DriveTo(target, "กำลังขี่ไปหน้าที่ทำงาน")
    end, tostring)
    brake()
    restore()
    Worker.Running = false
    return {
        ok = ok, message = message, peakSpeed = Worker.PeakSpeed,
        limits = Worker.Limits, brakeSpeed = Worker.LastBrakeSpeed,
        remaining = session and (flat(session.chassis.Position) - flat(target)).Magnitude,
        position = session and tostring(session.chassis.Position),
        owner = session and isnetworkowner(session.chassis),
    }
end


    return Worker
end
function Runtime:BuildRoadWorker(id)
    assert(id=="Grab"or id=="Delivery"or id=="Courier","อาชีพนี้ไม่ใช่งานขับรถ")
    local selected=self.Farm[id.."Vehicle"]or"Random"
    local worker=buildGrabWorker(self,selected=="Random"and"Current"or selected,id)
    worker.Config.RandomVehicle=selected=="Random"or selected=="Current"
    worker.Config.WorkVehicle=true
    worker.Config.SpawnOnRoad=id=="Grab"
    return worker
end
function Runtime:CapturePistonStockUI(key)
    local state=self:GetPistonTrack()
    if not state.Open or state.Key~=key then return false end
    local gui=player.PlayerGui:FindFirstChild("PistonShop")
    local window=gui and gui:FindFirstChild("PistonShopWindow")
    if not gui or not gui.Enabled or not window or not window.Visible then return false end
    local remaining=state.ClosesIn
    local fresh=false
    for _,label in ipairs(window:GetDescendants())do
        if label:IsA("TextLabel")then
            local minutes,seconds=label.Text:match("ร้านปิดใน (%d+):(%d+)")
            if minutes and seconds and remaining and math.abs(tonumber(minutes)*60+tonumber(seconds)-remaining)<=4 then fresh=true;break end
        end
    end
    if not fresh then return false end
    local body=window:FindFirstChild("Body")
    local list=body and body:FindFirstChildWhichIsA("ScrollingFrame")
    if not list then return false end
    local items={}
    for _,row in ipairs(list:GetChildren())do
        local chip=row:IsA("Frame")and row:FindFirstChild("Chip")
        if chip then
            local size
            for _,label in ipairs(row:GetDescendants())do
                if label:IsA("TextLabel")and tonumber(label.Text)then size=tonumber(label.Text)end
            end
            local label=chip:FindFirstChildWhichIsA("TextLabel")
            local value=label and label.Text
            local left=value and tonumber(value:match("เหลือ (%d+)"))
            if value and value:find("หมด")then left=0 end
            if size and left then items[size]=left end
        end
    end
    if not next(items)then return false end
    self.PistonStock.Items=items;self.PistonStock.Key=key
    self.PistonStock.UpdatedAt=workspace:GetServerTimeNow();self.PistonStock.Status="สต๊อกจากหน้าร้าน"
    return true
end
function Runtime:SetShopTravel(on,fromHop)
    if on and self.PistonHop and self.PistonHop.Enabled and not fromHop then self:Notify("หยุดค้นหาก่อนเดินทางเอง","Warning");return end
    if not on then
        if self.ShopDriver then self.ShopDriver.Shutdown()end
        local character=player.Character;local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and not humanoid.SeatPart then humanoid:MoveTo(character:GetPivot().Position)end
        self.ShopTravelOn=false
        return
    end
    if self.ShopTravelOn then return end
    if self.Tune.Busy then self:Notify("หยุดจูนรถก่อนเดินทาง","Warning");return end
    local state=self:GetPistonTrack()
    if not state.Open or not state.Position then self:Notify("ร้านยังไม่เปิด","Warning");return end
    self:SetFarmEnabled("Grab",false)
    self.ShopTravelOn=true;self.ShopTravelStatus="กำลังเตรียมรถ"
    local worker=buildGrabWorker(self,"Current");self.ShopDriver=worker;worker.Config.ShopKey=state.Key;worker.Config.RandomVehicle=true;worker.Config.WorkVehicle=true;worker.Config.KeepShopLane=false
    task.spawn(function()
        local started=os.clock()
        while self.Grab and self.Grab.Running and os.clock()-started<8 and self.ShopTravelOn do task.wait(.1)end
        if not self.Alive or not self.ShopTravelOn then return end
        local ok,message=worker.ShopTrip(state.Position)
        if not self.Alive or self.ShopDriver~=worker then return end
        self.ShopTravelOn=false
        self.ShopTravelStatus=ok and"ถึงร้านและอ่านสต๊อกแล้ว"or(worker.Cancelled and"หยุดเดินทางแล้ว"or tostring(message))
        if self.Controls.ShopTravel then self.Controls.ShopTravel.Set(false,true)end
        if not ok and not worker.Cancelled then self:Notify(tostring(message),"Warning")end
    end)
end
buildStationWorker=function(owner,jobId)
    local worker={Running=false,Cancelled=false,Trips=0,Earned=0,FuelSpent=0,Status="พร้อม",JobId=jobId}
    local tags=game:GetService("CollectionService")
    local function check()
        assert(owner.Alive and not worker.Cancelled,"Stopped")
        local character=player.Character
        assert(character and character:FindFirstChildOfClass("Humanoid")and character.Humanoid.Health>0,"ตัวละครไม่พร้อม")
        local prompt=player.PlayerGui:FindFirstChild("FarmCheck")
        if prompt and prompt:IsA("ScreenGui")and prompt.Enabled then
            local function visible()
                for _,child in ipairs(prompt:GetChildren())do if child:IsA("GuiObject")and child.Visible then return true end end
                return false
            end
            while visible()do
                assert(owner.Alive and not worker.Cancelled,"Stopped")
                worker.Status="รอยืนยันในเกม";character.Humanoid:MoveTo(character:GetPivot().Position);task.wait(.2)
            end
        end
    end
    local function pause(seconds)
        local finish=os.clock()+seconds
        repeat check();task.wait(.1)until os.clock()>=finish
    end
    local function duty()
        local ok,data=pcall(Http.JSONDecode,Http,player:GetAttribute("WorkTask")or"")
        return ok and type(data)=="table"and data or nil
    end
    local function find(tag,attribute,value)
        local chosen,dist
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        for _,part in ipairs(tags:GetTagged(tag))do
            if part:IsA("BasePart")and part:GetAttribute(attribute)==value and(tag~="WorkStation"or part:GetAttribute("Job")==jobId)then
                local distance=root and(part.Position-root.Position).Magnitude or 0
                if not dist or distance<dist then chosen,dist=part,distance end
            end
        end
        return chosen
    end
    local function dismount()
        local humanoid=player.Character.Humanoid
        local seat=humanoid.SeatPart
        if not seat then return end
        local vehicle=seat:FindFirstAncestorOfClass("Model")
        while vehicle and vehicle.Parent~=workspace:FindFirstChild("SpawnedVehicles")do vehicle=vehicle.Parent:FindFirstAncestorOfClass("Model")end
        assert(vehicle,"ไม่พบรถที่นั่ง")
        local definition=GameShared.vehicle(vehicle:GetAttribute("VehicleId"))
        if definition and definition.category=="Car"then Net.fire(RS.CarRemote,"Exit",vehicle)else Net.fire(RS.PCX160Remote,"Dismount","Start")end
        local limit=os.clock()+6
        while humanoid.SeatPart do check();assert(os.clock()<limit,"ลงรถไม่ได้");task.wait(.1)end
    end
    local function groundRoute(target,reach)
        local root=player.Character.HumanoidRootPart
        local origin=root.Position
        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances={player.Character,workspace.CurrentCamera,workspace:FindFirstChild("SpawnedVehicles")}
        params.RespectCanCollide=true
        local floorParams=RaycastParams.new();floorParams.FilterType=Enum.RaycastFilterType.Include
        floorParams.FilterDescendantsInstances={workspace:FindFirstChild("Map"),workspace.Terrain};floorParams.RespectCanCollide=true
        local step=4;local cells={};local open={};local closed={}
        local function node(x,z)
            local key=x..":"..z
            if cells[key]~=nil then return cells[key]or nil end
            local px,pz=origin.X+x*step,origin.Z+z*step
            if math.abs(px-target.X)>math.abs(origin.X-target.X)+28 or math.abs(pz-target.Z)>math.abs(origin.Z-target.Z)+28 then cells[key]=false;return end
            local hit=workspace:Raycast(Vector3.new(px,origin.Y+4,pz),Vector3.new(0,-24,0),floorParams)
            if not hit or hit.Normal.Y<.7 then cells[key]=false;return end
            local v={x=x,z=z,key=key,position=hit.Position,h=(Vector3.new(px,0,pz)-Vector3.new(target.X,0,target.Z)).Magnitude}
            cells[key]=v;return v
        end
        local first=node(0,0);if not first then return nil end
        first.g=0;table.insert(open,first)
        for iteration=1,1400 do
            check();if #open==0 then return nil end
            local best=1
            for i=2,#open do if open[i].g+open[i].h<open[best].g+open[best].h then best=i end end
            local current=table.remove(open,best);closed[current.key]=true
            if current.h<=reach then
                local points={}
                while current do table.insert(points,1,{Position=current.position,Action=current.Jump and Enum.PathWaypointAction.Jump or Enum.PathWaypointAction.Walk});current=current.parent end
                return points
            end
            for dx=-1,1 do for dz=-1,1 do if dx~=0 or dz~=0 then
                local nextNode=node(current.x+dx,current.z+dz)
                if nextNode and not closed[nextNode.key]and math.abs(nextNode.position.Y-current.position.Y)<3 then
                    local from=current.position+Vector3.new(0,3,0)
                    local to=nextNode.position+Vector3.new(0,3,0)
                    local hit=workspace:Blockcast(CFrame.new(from),Vector3.new(2.2,3.4,2.2),to-from,params)
                    if not hit then
                        local cost=current.g+(nextNode.position-current.position).Magnitude
                        if not nextNode.g or cost<nextNode.g then
                            local added=nextNode.g~=nil
                            nextNode.g=cost;nextNode.parent=current;nextNode.Jump=nextNode.position.Y-current.position.Y>.7
                            if not added then table.insert(open,nextNode)end
                        end
                    end
                end
            end end end
            if iteration%100==0 then task.wait()end
        end
    end
    local function clearPath(points)
        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances={player.Character,workspace.CurrentCamera,workspace:FindFirstChild("SpawnedVehicles")};params.RespectCanCollide=true
        local last=player.Character.HumanoidRootPart.Position
        for _,point in ipairs(points)do
            local destination=point.Position+Vector3.new(0,2.5,0)
            local delta=destination-last
            if delta.Magnitude>.1 then
                local hit=workspace:Blockcast(CFrame.new(last),Vector3.new(2,3,2),delta,params)
                if hit and hit.Normal.Y<.6 then return false end
            end
            last=destination
        end
        return true
    end
    local function shortTween(target,reach)
        local character=player.Character;local humanoid=character.Humanoid;local root=character.HumanoidRootPart
        if worker.TweenDisabled or humanoid.SeatPart then return false end
        local flatDelta=Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)
        local localRange=jobId=="Mechanic"and 100 or 80
        if flatDelta.Magnitude>localRange or math.abs(target.Y-root.Position.Y)>8 then return false end
        if flatDelta.Magnitude<=reach then return true end
        local near=target-flatDelta.Unit*math.min(4,reach*.6)
        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances={character,workspace.CurrentCamera,workspace:FindFirstChild("SpawnedVehicles")};params.RespectCanCollide=true
        local floor=workspace:Raycast(Vector3.new(near.X,root.Position.Y+2,near.Z),Vector3.new(0,-14,0),params)
        if not floor or floor.Normal.Y<.7 then return false end
        local height=humanoid.HipHeight+root.Size.Y/2
        local destination=Vector3.new(near.X,floor.Position.Y+height,near.Z)
        if math.abs(destination.Y-root.Position.Y)>4 then return false end
        local original={};local auto=humanoid.AutoRotate;humanoid.AutoRotate=false
        humanoid:MoveTo(root.Position)
        local support=Instance.new("Part");support.Name="D0TFrostyWorkFloat";support.Size=Vector3.new(6,.5,6)
        support.Anchored=true;support.Transparency=1;support.CanTouch=false;support.CanQuery=false;support.Parent=workspace
        local tween;local connection;local cleaned=false
        local function cleanup()
            if cleaned then return end;cleaned=true
            if tween then tween:Cancel()end
            if connection then connection:Disconnect()end
            for part,collision in pairs(original)do if part.Parent then part.CanCollide=collision end end
            humanoid.AutoRotate=auto
            support:Destroy()
            if root.Parent then root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end
            if worker.TravelCleanup==cleanup then worker.TravelCleanup=nil end
        end
        worker.TravelCleanup=cleanup
        local ok,message=xpcall(function()
            connection=RunService.Stepped:Connect(function()
                if not root.Parent then return end
                for _,part in ipairs(character:GetDescendants())do if part:IsA("BasePart")then
                    if original[part]==nil then original[part]=part.CanCollide end;part.CanCollide=false
                end end
                support.CFrame=CFrame.new(root.Position-Vector3.new(0,height+.25,0))
                root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
            end)
            local distance=(root.Position-destination).Magnitude
            worker.LastTweenDistance=distance
            tween=game:GetService("TweenService"):Create(root,TweenInfo.new(distance/80,Enum.EasingStyle.Linear),{CFrame=CFrame.lookAt(destination,destination+flatDelta.Unit)})
            tween:Play()
            while tween.PlaybackState==Enum.PlaybackState.Playing do check();assert(player.Character==character,"Character changed");task.wait(.05)end
            check()
            assert((root.Position-destination).Magnitude<8,"Tween position corrected")
            worker.ShortTweens=(worker.ShortTweens or 0)+1
        end,tostring)
        cleanup()
        if not ok then
            if worker.Cancelled or not owner.Alive then error(message,0)end
            worker.TweenDisabled=true;worker.TweenFailure=tostring(message);return false
        end
        pause(.4)
        if(root.Position-destination).Magnitude>10 then worker.TweenDisabled=true;worker.TweenFailure="Position changed after Tween";return false end
        return(root.Position-target).Magnitude<=JobShared.REACH
    end
    local function go(part)
        check();local proxy=type(part)=="table";local reach=proxy and(part.Reach or 8)or(part:GetAttribute("StationId")=="Board"and 13 or 7)
        local goal=proxy and part.Position or part.Position+part.CFrame.LookVector*(part:GetAttribute("StationId")and 3.5 or 7)
        local root=player.Character.HumanoidRootPart
        if not proxy and worker.AtWorksite and shortTween(part.Position,reach)then return end
        if not proxy and root.Position.X>154 and root.Position.X<235 and root.Position.Z>-215 and root.Position.Z< -95 and(part.Position.Z> -95 or part.Position.Z< -215 or part.Position.X<154)then
            local bay=-177.5;for _,z in ipairs({-144.5,-112.5})do if math.abs(z-root.Position.Z)<math.abs(bay-root.Position.Z)then bay=z end end
            local inside=Vector3.new(160,3.42,bay);local outside=Vector3.new(140,3.42,bay)
            go({Position=inside,CFrame=CFrame.new(inside),Reach=3.5});go({Position=outside,CFrame=CFrame.new(outside),Reach=3.5})
        end
        if not proxy and root.Position.X>85 and root.Position.X<235 and root.Position.Z> -245 and root.Position.Z< -60 and(part.Position.Z> -60 or part.Position.Z< -245)then
            local inside=Vector3.new(100,3.8,-155);local outside=Vector3.new(72,3,-155)
            go({Position=inside,CFrame=CFrame.new(inside),Reach=3.5,Straight=true});go({Position=outside,CFrame=CFrame.new(outside),Reach=3.5,Straight=true})
        end
        if not proxy and jobId=="Mechanic"and tostring(part:GetAttribute("StationId")):find("^Bay")and root.Position.X<154 then
            local outside=Vector3.new(140,part.Position.Y,part.Position.Z);local inside=Vector3.new(160,part.Position.Y,part.Position.Z)
            go({Position=outside,CFrame=CFrame.new(outside),Reach=3.5});go({Position=inside,CFrame=CFrame.new(inside),Reach=3.5})
        end
        if(root.Position-goal).Magnitude>1000 then
            worker.Status="กำลังเดินทางไปที่ทำงาน"
            local driver=buildGrabWorker(owner,"Current");driver.Config.RandomVehicle=true;driver.Config.WorkVehicle=true;worker.Driver=driver
            local result=driver.TestDrive(Vector3.new(goal.X<0 and-48 or 48,goal.Y,goal.Z))
            assert(result.ok,tostring(result.message));worker.Driver=nil
        end
        dismount()
        if(root.Position-part.Position).Magnitude<=reach then return end
        local path=game:GetService("PathfindingService"):CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=5})
        local points
        if proxy and part.Straight then points={{Position=goal,Action=Enum.PathWaypointAction.Walk}}
        else
            local candidates={goal}
            if not proxy then for _,offset in ipairs({Vector3.new(8,0,0),Vector3.new(-8,0,0),Vector3.new(0,0,8),Vector3.new(0,0,-8)})do table.insert(candidates,part.Position+offset)end end
            for _,candidate in ipairs(candidates)do path:ComputeAsync(root.Position,candidate);if path.Status==Enum.PathStatus.Success then local trial=path:GetWaypoints();if clearPath(trial)then points=trial;break end end end
            if not points then points=groundRoute(part.Position,proxy and math.max(4.5,reach)or 10)end
            assert(points,"หาเส้นทางเดินไปจุดงานไม่ได้")
        end
        for _,point in ipairs(points)do
            check();if(root.Position-part.Position).Magnitude<=10 then break end
            if point.Action==Enum.PathWaypointAction.Jump then player.Character.Humanoid.Jump=true end
            player.Character.Humanoid:MoveTo(point.Position)
            local deadline=os.clock()+10;local movedAt=os.clock();local last=root.Position;worker.MoveTarget=tostring(point.Position)
            while(Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(point.Position.X,0,point.Position.Z)).Magnitude>4.5 and(root.Position-part.Position).Magnitude>reach do
                check();assert(os.clock()<deadline,"เดินติดสิ่งกีดขวาง")
                if(root.Position-last).Magnitude>1 then last=root.Position;movedAt=os.clock()elseif os.clock()-movedAt>.65 then player.Character.Humanoid.Jump=true;player.Character.Humanoid:MoveTo(point.Position);movedAt=os.clock()end
                task.wait(.08)
            end
        end
        player.Character.Humanoid:MoveTo(root.Position)
        assert((root.Position-part.Position).Magnitude<=JobShared.REACH,"ยังไม่ถึงจุดงาน")
    end
    function worker.Stop()
        worker.Cancelled=true
        if worker.TravelCleanup then worker.TravelCleanup()end
        if worker.Driver then worker.Driver.Shutdown()end
        local character=player.Character
        if character and character:FindFirstChildOfClass("Humanoid")then character.Humanoid:MoveTo(character:GetPivot().Position)end
    end
    worker.Shutdown=worker.Stop
    function worker.Run(limit)
        worker.Running=true;worker.StartedAt=os.clock();local startEarned=player:GetAttribute("WorkEarned")or 0
        local ok,message=xpcall(function()
            local places=RS:WaitForChild("JobPlaces")
            local workplace=assert(places:GetAttribute(jobId),"ไม่พบตำแหน่งตู้ของอาชีพ "..jobId)
            local arrivalRadius=jobId=="Mechanic"and 300 or 120
            if(player.Character.HumanoidRootPart.Position-workplace).Magnitude>arrivalRadius then
                worker.Status="กำลังขับรถไปหน้าที่ทำงาน"
                local selected=owner.Farm[jobId.."Vehicle"]or"Random"
                local driver=buildGrabWorker(owner,selected=="Random"and"Current"or selected);driver.Config.RandomVehicle=selected=="Random"or selected=="Current";driver.Config.WorkVehicle=true;driver.Config.StopRadius=16;driver.Config.ExitToRoad=true;worker.Driver=driver
                local front=jobId=="Courier"and Vector3.new(JobShared.DEPOT.dx,3,JobShared.DEPOT.dz)or Vector3.new(48,3,jobId=="Mechanic"and-155 or workplace.Z)
                local result=driver.TestDrive(front)
                assert(result.ok,tostring(result.message))
                worker.ParkedVehicle=driver.Vehicle;worker.Driver=nil
                dismount()
                local vehicle=worker.ParkedVehicle
                if vehicle and vehicle.Parent then
                    local definition=GameShared.vehicle(vehicle:GetAttribute("VehicleId"))
                    if definition and definition.category=="Car"then Net.fire(RS.CarRemote,"Engine",vehicle,false)
                    else Net.fire(RS.PCX160Remote,"Engine",false)end
                end
            else dismount()end
            worker.AtWorksite=true
            if player:GetAttribute("Job")~=jobId then
                worker.Status="กำลังสมัครงาน"
                local accepted,reason=Net.invoke(Remotes.Job,"Plan",jobId);assert(accepted,tostring(reason))
                local locker=find("JobLocker","Job",jobId)
                if not locker then
                    local known=workplace
                    go({Position=known,CFrame=CFrame.new(known)})
                    pcall(player.RequestStreamAroundAsync,player,known,3)
                    local deadline=os.clock()+5
                    repeat check();locker=find("JobLocker","Job",jobId);if not locker then task.wait(.2)end until locker or os.clock()>deadline
                end
                assert(locker,"ยังไม่พบตู้เปลี่ยนชุดงาน");go(locker)
                local prompt=assert(locker:FindFirstChildWhichIsA("ProximityPrompt"),"ไม่พบปุ่มเปลี่ยนชุด")
                fireproximityprompt(prompt)
                local deadline=os.clock()+6
                repeat check();task.wait(.1)until player:GetAttribute("Job")==jobId or os.clock()>deadline
                assert(player:GetAttribute("Job")==jobId,"เกมยังไม่ยืนยันอาชีพ")
            end
            startEarned=player:GetAttribute("WorkEarned")or 0
            local failures=0
            while not worker.Cancelled and(not limit or worker.Trips<limit)do
                check();local roundStarted=workspace:GetServerTimeNow()
                local taskData=duty()
                if not taskData then
                    worker.Status="กำลังรับงาน"
                    go(assert(find("WorkStation","StationId","Board"),"ไม่พบป้ายรับงาน"));pause(.4)
                    local accepted,reason=Net.invoke(Remotes.Work,"Take",nil)
                    if not accepted and duty()then accepted=true end
                    if not accepted then
                        local seconds=tonumber(tostring(reason):match("wait (%d+) s"))
                        if seconds then worker.Status="รอรับงานถัดไป";pause(seconds+.3);continue end
                        error(tostring(reason),0)
                    end
                    pause(.25);taskData=duty()
                    assert(taskData,"เกมยังไม่ส่งรายละเอียดงาน")
                end
                assert(taskData.job==jobId,"อาชีพของงานไม่ตรงกัน")
                local definition=JobShared.task(jobId,taskData.task)
                assert(definition,"ไม่รู้จักงานย่อย")
                local station=assert(find("WorkStation","StationId",taskData.station),"ยังไม่พบจุดทำงาน "..tostring(taskData.station))
                worker.Status=definition.th;go(station);pause(.3)
                local beforeCount=player:GetAttribute("WorkCount")or 0
                local beforeEarned=player:GetAttribute("WorkEarned")or 0
                local began=workspace:GetServerTimeNow()
                if taskData.step~="carry"then
                    local accepted,reason
                    if taskData.step=="doing"then accepted,reason=Net.invoke(Remotes.Work,"Resume",nil)else accepted,reason=Net.invoke(Remotes.Work,"Do",taskData.station)end
                    if not accepted then pause(.4);local current=duty();if current and(current.step=="doing"or current.step=="carry")then accepted=true elseif taskData.step=="doing"then accepted,reason=Net.invoke(Remotes.Work,"Resume",nil)else accepted,reason=Net.invoke(Remotes.Work,"Do",taskData.station)end end
                    assert(accepted,tostring(reason))
                    pause(.15)
                    local updated=duty()
                    if updated and updated.step=="carry"then
                        go(assert(find("WorkStation","StationId",updated.station),"ไม่พบจุดส่งวัสดุ"))
                    end
                    pause(math.max(0,(JobShared.MIN_TIME or 3)+.35-(workspace:GetServerTimeNow()-began)))
                end
                local previousTask=player:GetAttribute("WorkTask")
                local accepted,reason=Net.invoke(Remotes.Work,"Done",1)
                assert(accepted,tostring(reason));pause(.3)
                if(player:GetAttribute("WorkCount")or 0)>beforeCount then
                    worker.Trips+=1;worker.Earned=math.max(0,(player:GetAttribute("WorkEarned")or 0)-startEarned)
                    local paid=math.max(0,(player:GetAttribute("WorkEarned")or 0)-beforeEarned)
                    owner:SendWorkWebhook(jobId..":"..tostring(player:GetAttribute("WorkCount")),JobShared.job(jobId).th.." · "..definition.th,paid,workspace:GetServerTimeNow()-roundStarted)
                    failures=0
                    local syncDeadline=os.clock()+1.5
                    while player:GetAttribute("WorkTask")==previousTask and os.clock()<syncDeadline do pause(.1)end
                else
                    local nextDuty=duty()
                    if nextDuty and nextDuty.step==taskData.step and nextDuty.station==taskData.station then failures+=1;assert(failures<3,"งานไม่คืบหน้า")end
                end
            end
        end,tostring)
        if worker.TravelCleanup then worker.TravelCleanup()end
        worker.StoppedAt=os.clock();worker.Running=false;worker.Status=worker.Cancelled and"หยุดแล้ว"or ok and"เสร็จแล้ว"or tostring(message)
        if worker.Driver then worker.Driver.Shutdown()end
        return ok,message
    end
    return worker
end
function Runtime:ResetForJobChange(id,revision)
    self.Farm.Resetting=true;self.Farm.Status="รีตัวละครก่อนเปลี่ยนอาชีพ"
    local function active()return self.Alive and self.Farm.Enabled[id]and self.Farm.StartRevision==revision end
    local ok,message=xpcall(function()
        assert(active(),"Stopped")
        local delivery=player:GetAttribute("DeliveryState")
        if delivery=="ToShop"or delivery=="ToHome"then
            local accepted,reason=Net.invoke(Remotes.Delivery,"Cancel",nil);assert(accepted,tostring(reason))
        end
        if player:GetAttribute("WorkTask")then pcall(Net.invoke,Remotes.Work,"Quit",nil)end
        assert(active(),"Stopped")
        local old=player.Character;local humanoid=old and old:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health>0 then humanoid.Health=0 end
        local deadline=os.clock()+40
        while os.clock()<deadline do
            assert(active(),"Stopped")
            local character=player.Character
            local h=character and character:FindFirstChildOfClass("Humanoid")
            local root=character and character:FindFirstChild("HumanoidRootPart")
            if character~=old and h and h.Health>0 and root then
                self.Farm.LastResetPosition=tostring(root.Position)
                self.Farm.LastResetAt=workspace:GetServerTimeNow()
                self.Farm.ResetCount=(self.Farm.ResetCount or 0)+1
                task.wait(.4);return
            end
            task.wait(.1)
        end
        error("รอเกิดใหม่เกินเวลา",0)
    end,tostring)
    self.Farm.Resetting=false
    assert(ok,message)
end
function Runtime:SetFarmEnabled(id,on)
    if on and self.PistonHop and self.PistonHop.Enabled then self:Notify("หยุดค้นหาลูกสูบก่อนเริ่มงาน","Warning");return end
    if on and self.ShopTravelOn then self:Notify("หยุดเดินทางไปร้านก่อนเริ่มงาน","Warning");return end
    self.Farm.StartRevision=(self.Farm.StartRevision or 0)+1
    local revision=self.Farm.StartRevision
    self.Farm.Enabled[id]=on==true
    if not on then
        local worker=(id=="Grab"or id=="Delivery"or id=="Courier")and self.Grab or self.OtherWork
        if worker and worker.JobId==id then worker.Stop()end
        return
    end
    if self.Tune.Busy then self.Farm.Enabled[id]=false;self:Notify("หยุดจูนรถก่อนเริ่มทำงาน","Warning");return end
    if id~="Grab"and id~="Delivery"and id~="Courier"and id~="Mechanic"and id~="Builder"then
        self.Farm.Enabled[id]=false;self:Notify("อาชีพนี้ยังไม่มีตัวทำงานอัตโนมัติ","Warning");return
    end
    if self.Grab then self.Grab.Shutdown()end
    if self.OtherWork then self.OtherWork.Shutdown()end
    for job,enabled in pairs(self.Farm.Enabled)do if job~=id and enabled then self.Farm.Enabled[job]=false end end
    task.spawn(function()
        local function active()return self.Alive and self.Farm.Enabled[id]and self.Farm.StartRevision==revision end
        local worker
        local ok,message=xpcall(function()
            local deadline=os.clock()+8
            while((self.Grab and self.Grab.Running)or(self.OtherWork and self.OtherWork.Running))and os.clock()<deadline do
                assert(active(),"Stopped");task.wait(.1)
            end
            assert(active(),"Stopped")
            assert(not(self.Grab and self.Grab.Running)and not(self.OtherWork and self.OtherWork.Running),"ตัวทำงานก่อนหน้ายังไม่หยุด")
            local previousJob=self.Farm.LastStartedJob
            local didReset=previousJob~=nil and previousJob~="Citizen"and previousJob~=id
            if didReset then self:ResetForJobChange(id,revision)end
            assert(active(),"Stopped")
            local readyDeadline=os.clock()+40
            while true do
                assert(active(),"Stopped")
                local character=player.Character
                local humanoid=character and character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health>0 and character:FindFirstChild("HumanoidRootPart")then break end
                assert(os.clock()<readyDeadline,"รอตัวละครเกิดใหม่เกินเวลา")
                task.wait(.1)
            end
            self.Farm.LastStartedJob=id
            if id=="Grab"or id=="Delivery"or id=="Courier"then worker=self:BuildRoadWorker(id);self.Grab=worker
            else worker=buildStationWorker(self,id);self.OtherWork=worker end
            local succeeded,reason=worker.Run()
            assert(succeeded or worker.Cancelled,tostring(reason))
        end,tostring)
        if not self.Alive or self.Farm.StartRevision~=revision then return end
        self.Farm.Enabled[id]=false
        if self.Controls.Jobs[id]then self.Controls.Jobs[id].Set(false,true)end
        if not ok and(not worker or not worker.Cancelled)then self:Notify(tostring(message),"Warning")end
    end)
end

local TeleportService=game:GetService("TeleportService")
local transfer=env.__D0TFrostyHopTransfer
env.__D0TFrostyHopTransfer=nil
Runtime.PistonHop={Enabled=false,Targets={},Seen={},Hops=0,Revision=0,Status="ปิด",QueueSequence=0}
local hopFlagPath=Settings.Folder.."/PistonHop_"..player.UserId..".txt"
do
    local hop=Runtime.PistonHop
    if type(transfer)=="table"and transfer.PlaceId==game.PlaceId then
        for _,size in ipairs(transfer.Targets or{})do hop.Targets[tonumber(size)]=true end
        for _,id in ipairs(transfer.Seen or{})do hop.Seen[id]=true end
        hop.Hops=tonumber(transfer.Hops)or 0
    end
    if isfile and readfile then
        local ok,value=pcall(function()return isfile(hopFlagPath)and readfile(hopFlagPath)or"false"end)
        hop.Resume=ok and value=="true"
        hop.Enabled=hop.Resume and next(hop.Targets)~=nil
    end
end
function Runtime:SavePistonHopFlag(enabled)
    if not writefile then return false end
    return pcall(function()
        if makefolder then
            if not isfolder or not isfolder("D0TFrosty X")then makefolder("D0TFrosty X")end
            if not isfolder or not isfolder(Settings.Folder)then makefolder(Settings.Folder)end
        end
        writefile(hopFlagPath,enabled and"true"or"false")
    end)
end
function Runtime:PistonHopMatch(state)
    local hop=self.PistonHop;local stock=self.PistonStock
    if not state.Open or stock.Key~=state.Key then return nil end
    if hop.ProbeStartedAt and(stock.UpdatedAt or 0)<hop.ProbeStartedAt then return nil end
    local found={}
    for size in pairs(hop.Targets)do
        local left=stock.Items[size]
        if type(left)=="number"and left>0 then table.insert(found,{size=size,left=left})end
    end
    table.sort(found,function(a,b)return a.size<b.size end)
    return #found>0 and found or nil
end

Runtime.PistonBuy={Enabled=type(transfer)=="table"and transfer.PlaceId==game.PlaceId and transfer.AutoBuy==true or false,Revision=0,Status="ปิด",Bought=0,Spent=0}
function Runtime:SetPistonAutoBuy(on)
    local buy=self.PistonBuy
    buy.Revision+=1;local revision=buy.Revision
    buy.Enabled=on==true;buy.Buying=false
    if not buy.Enabled then buy.Status="ปิด";if buy.OwnsTravel then self:SetShopTravel(false);buy.OwnsTravel=false end;return end
    buy.Status="รอพบขนาดที่เลือก";buy.Bought=0;buy.Spent=0
    local function active()return self.Alive and buy.Enabled and buy.Revision==revision end
    task.spawn(function()
        local function finish(message)
            if not active()then return end
            buy.Enabled=false;buy.Buying=false;buy.Status=message
            if buy.OwnsTravel then self:SetShopTravel(false);buy.OwnsTravel=false end
        end
        while active()do
            local state=self:GetPistonTrack()
            if not next(self.PistonHop.Targets)then buy.Status="เปิดรอ · เลือกขนาดลูกสูบ"
            elseif not state.Open then buy.Status="เปิดรอ · ร้านยังไม่เปิด"
            else
                buy.Status="เปิดรอ · รอพบขนาดที่เลือก"
                if not self.PistonHop.Enabled and os.clock()>=(buy.NextRefresh or 0)then
                    buy.NextRefresh=os.clock()+3;self:RefreshPistonStock()
                end
            end
            local found=self:PistonHopMatch(state)
            if found then
                buy.Buying=true
                if self.PistonHop.Enabled then self:SetPistonHop(false,found)end
                if(state.Distance or math.huge)>12 then
                    buy.Status="กำลังไปร้านเพื่อซื้อ";buy.OwnsTravel=true;self:SetShopTravel(true)
                    local limit=os.clock()+150
                    while active()and self.ShopTravelOn and os.clock()<limit do task.wait(.2)end
                    if not active()then return end
                    if self.ShopTravelOn then self:SetShopTravel(false)end
                    buy.OwnsTravel=false
                end
                state=self:GetPistonTrack()
                if not state.Open or(state.Distance or math.huge)>20 then finish("ซื้อไม่ได้ · อยู่นอกระยะร้านหรือร้านปิด");return end
                local ok,success,data=pcall(Net.invoke,Remotes.Piston,"Shop")
                if not active()then return end
                if not ok or not success or type(data)~="table"or type(data.items)~="table"then finish("อ่านสต๊อคก่อนซื้อไม่ได้");return end
                local shared=require(RS.PistonShared)
                local targets={}
                for size in pairs(self.PistonHop.Targets)do table.insert(targets,size)end
                table.sort(targets)
                local key=state.Key
                for _,size in ipairs(targets)do
                    local left=0
                    for _,item in pairs(data.items)do if item.size==size then left=math.max(0,math.floor(tonumber(item.left)or 0))end end
                    for _=1,left do
                        if not active()then return end
                        state=self:GetPistonTrack()
                        if not state.Open or state.Key~=key then finish("หยุดซื้อ · ร้านปิดหรือเปลี่ยนรอบ");return end
                        local price=shared.PRICES[size]
                        if type(price)~="number"or price<=0 then finish("ไม่พบราคาขนาด "..size);return end
                        if(tonumber(player:GetAttribute("Cash"))or 0)<price then finish("หยุดซื้อ · เงินไม่พอ · ซื้อแล้ว "..buy.Bought.." ชิ้น");return end
                        buy.Status="กำลังซื้อ "..size.." มม. · ได้แล้ว "..buy.Bought.." ชิ้น"
                        local called,accepted,message,updated=pcall(Net.invoke,Remotes.Piston,"Buy",size)
                        if not active()then return end
                        if not called or not accepted then finish("หยุดซื้อ · "..tostring(message or "ร้านไม่รับคำสั่ง"));return end
                        buy.Bought+=1;buy.Spent+=price
                        if type(updated)=="table"and type(updated.items)=="table"then
                            data=updated
                            local items={}
                            for _,item in pairs(updated.items)do if type(item.size)=="number"and type(item.left)=="number"then items[item.size]=math.max(0,item.left)end end
                            self.PistonStock.Items=items;self.PistonStock.Key=key;self.PistonStock.UpdatedAt=workspace:GetServerTimeNow()
                        end
                        task.wait(.3)
                    end
                end
                finish("ซื้อเสร็จ "..buy.Bought.." ชิ้น · ใช้เงิน "..buy.Spent.." ฿");return
            end
            task.wait(1)
        end
    end)
end

function Runtime:GetPublicServers()
    local requestFn=request or http_request
    assert(type(requestFn)=="function","ตัวรันไม่รองรับ HTTP")
    local rows={};local cursor
    for _=1,2 do
        local url="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        if cursor then url..="&cursor="..Http:UrlEncode(cursor)end
        local response=requestFn({Url=url,Method="GET"})
        assert(type(response)=="table"and response.StatusCode==200,"อ่านรายชื่อเซิร์ฟไม่ได้")
        local data=Http:JSONDecode(response.Body)
        for _,server in ipairs(data.data or{})do
            if type(server.id)=="string"and server.id~=game.JobId and type(server.playing)=="number"and type(server.maxPlayers)=="number"and server.playing<server.maxPlayers and not self.PistonHop.Seen[server.id]then table.insert(rows,server)end
        end
        cursor=data.nextPageCursor
        if #rows>0 or not cursor then break end
    end
    table.sort(rows,function(a,b)
        if a.playing~=b.playing then return a.playing<b.playing end
        return(tonumber(a.ping)or 9999)<(tonumber(b.ping)or 9999)
    end)
    return rows
end
function Runtime:GetServerInfo()
    local ping="—"
    pcall(function()ping=game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()end)
    local job=game.JobId;local place=game.PlaceId
    return {JobId=job,PlaceId=place,UniverseId=game.GameId,Version=game.PlaceVersion,
        Players=#Players:GetPlayers(),MaxPlayers=Players.MaxPlayers,Ping=ping,
        Private=game.PrivateServerId~=""and"ใช่"or"ไม่ใช่",
        JoinLink="roblox://experiences/start?placeId="..place.."&gameInstanceId="..job,
        WebLink="https://www.roblox.com/games/start?placeId="..place.."&gameInstanceId="..job,
        JoinCode=('game:GetService("TeleportService"):TeleportToPlaceInstance(%s, %q, game:GetService("Players").LocalPlayer)'):format(place,job)}
end
function Runtime:JoinServer(id)
    id=tostring(id or""):match("^%s*(.-)%s*$")
    if not id:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$")then self:Notify("Job ID ไม่ถูกต้อง","Warning");return end
    self:SetPistonHop(false)
    local ok,message=pcall(function()self:QueuePistonContinuation();TeleportService:TeleportToPlaceInstance(game.PlaceId,id,player)end)
    if not ok then self:Notify(tostring(message),"Warning")end
end
function Runtime:SetPistonHop(enabled,found)
    local hop=self.PistonHop
    hop.Revision+=1;local revision=hop.Revision
    if not enabled then
        hop.Enabled=false;hop.Resume=false;self:SavePistonHopFlag(false)
        if hop.OwnsTravel then self:SetShopTravel(false);hop.OwnsTravel=false end
        if found then hop.Found=found;local names={};for _,item in ipairs(found)do table.insert(names,item.size.." มม. ("..item.left..")")end;hop.Status="พบ: "..table.concat(names,", ")
        else hop.Status="ปิด"end
        if found then self:Notify(hop.Status,"Info")end
        return
    end
    if self.Tune.Busy then hop.Enabled=false;self:Notify("หยุดจูนรถก่อนค้นหาลูกสูบ","Warning");return end
    if not next(hop.Targets)then hop.Enabled=false;self:SavePistonHopFlag(false);self:Notify("เลือกขนาดลูกสูบก่อน","Warning");return end
    local saved=self:SavePistonHopFlag(true)
    if not saved then hop.Enabled=false;self:Notify("บันทึกสถานะย้ายเซิร์ฟไม่ได้","Warning");return end
    hop.Enabled=true;hop.Found=nil;hop.Seen[game.JobId]=true;hop.Status="กำลังตรวจร้าน"
    for _,job in ipairs(JobShared.JOBS)do if job.id~="Citizen"then self:SetFarmEnabled(job.id,false)end end
    local function active()return self.Alive and hop.Enabled and hop.Revision==revision end
    local function pause(seconds)local limit=os.clock()+seconds;while active()and os.clock()<limit do task.wait(.2)end;return active()end
    task.spawn(function()
        if not pause(2)then return end
        while active()do
            local state=self:GetPistonTrack()
            if state.Open and state.Position and(state.ClosesIn or 900)>8 then
                hop.Status="ตรวจสต๊อกร้าน"
                hop.ProbeStartedAt=workspace:GetServerTimeNow()
                self:RefreshPistonStock()
                local deadline=os.clock()+4
                while active()and self.PistonStock.Busy and os.clock()<deadline do task.wait(.1)end
                local match=self:PistonHopMatch(self:GetPistonTrack())
                if match then self:SetPistonHop(false,match);return end
                for attempt=1,2 do
                    if not active()then return end
                    state=self:GetPistonTrack();if not state.Open then break end
                    hop.Status="กำลังไปร้าน · เซิร์ฟที่ "..(hop.Hops+1)
                    hop.OwnsTravel=true;self:SetShopTravel(true,true)
                    local untilAt=os.clock()+math.min(150,math.max(5,(state.ClosesIn or 150)-2))
                    while active()and self.ShopTravelOn and os.clock()<untilAt do
                        local current=self:GetPistonTrack()
                        match=self:PistonHopMatch(current)
                        if match then self:SetPistonHop(false,match);return end
                        if not current.Open then break end
                        task.wait(.2)
                    end
                    if not active()then return end
                    if self.ShopTravelOn then self:SetShopTravel(false)end
                    hop.OwnsTravel=false
                    match=self:PistonHopMatch(self:GetPistonTrack())
                    if match then self:SetPistonHop(false,match);return end
                    if self.PistonStock.Key==state.Key then break end
                    if not pause(1)then return end
                end
            end
            if not active()then return end
            hop.Status="ไม่พบขนาดที่เลือก · กำลังหาเซิร์ฟใหม่"
            local ok,servers=pcall(self.GetPublicServers,self)
            if not active()then return end
            if ok and#servers>0 then
                local candidate=servers[1];hop.Seen[candidate.id]=true;hop.Status="กำลังย้ายเซิร์ฟ"
                local oldJob=game.JobId
                local joined,message=pcall(function()
                    self:QueuePistonContinuation()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId,candidate.id,player)
                end)
                if not joined then hop.Status="ย้ายไม่สำเร็จ · ลองใหม่";hop.LastError=tostring(message)
                else
                    local untilAt=os.clock()+20
                    while active()and game.JobId==oldJob and os.clock()<untilAt do task.wait(.3)end
                end
            else hop.Status=ok and"ยังไม่มีเซิร์ฟว่างที่ยังไม่เคยไป"or"อ่านรายชื่อเซิร์ฟไม่ได้ · กำลังลองใหม่"end
            if not pause(5)then return end
        end
    end)
end

-- =====================================================================
-- UI: VoltScriptZ (VoltUi) replaces the native phone pages.
-- =====================================================================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ice123nm44nm-dot/VoltHub/main/VoltUi.lua"))()

if getgenv().VoltScriptZWin and getgenv().VoltScriptZWin.Destroy then
    pcall(function()
        getgenv().VoltScriptZWin:Destroy()
    end)
end

local Win = Library:CreateWindow({
    Name = "VoltScriptZ",
    Title = "Volt",
    TitleAccent = "Frosty",
    Subtitle = "Map MAHANAKHON RACING | Made By VoltScript Hub",
    Logo = "rbxassetid://100712256015627",
    ToggleKey = Enum.KeyCode.RightControl,
})
getgenv().VoltScriptZWin = Win

Runtime.Window = {
    Notify = function(_, options)
        options = options or {}
        Win:Notify({
            Title = options.Title or "Frosty",
            Text = options.Content or options.Text or "",
            Duration = options.Duration or 4,
        })
    end,
    Unload = function()
        pcall(function()
            Win:Destroy()
        end)
    end,
}
Runtime.PartialUICleanup = function() end

--------------------------------------------------------------- helpers
local function currentVehicleId()
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local folder = workspace:FindFirstChild("SpawnedVehicles")
    if folder then
        for _, vehicle in ipairs(folder:GetChildren()) do
            if
                vehicle:GetAttribute("OwnerUserId") == player.UserId
                and humanoid
                and humanoid.SeatPart
                and humanoid.SeatPart:IsDescendantOf(vehicle)
            then
                return vehicle:GetAttribute("VehicleId")
            end
        end
    end
    return player:GetAttribute("ActiveVehicle")
end

local vehicleOptions = { "Current" }
local ids = { ["Current"] = "Current" }
local names = { Current = "Current" }
for _, definition in ipairs(GameShared.VEHICLES) do
    local label = definition.id
    table.insert(vehicleOptions, label)
    ids[label] = definition.id
    names[definition.id] = label
end

-- every toggle registers here so job switches / reloads can silence Set
Runtime.Switches = {}

local function toggle(card, title, callback)
    local obj = card:AddToggle({ Name = title, Default = false, Callback = callback })
    table.insert(Runtime.Switches, obj)
    return obj
end

local function refreshOptions(obj, options)
    local ok = pcall(function()
        obj:Refresh(options)
    end)
    return ok
end

--------------------------------------------------------------- tabs
Win:AddSection("General")
local tabFarm = Win:AddTab({ Name = "Farm" })
local tabTune = Win:AddTab({ Name = "Tune" })
local tabHandling = Win:AddTab({ Name = "Handling" })

Win:AddSection("Utilities")
local tabUtilities = Win:AddTab({ Name = "Utilities" })
local tabSettings = Win:AddTab({ Name = "Settings" })



Runtime.Pages = {
    Farm = tabFarm,
    Tuner = tabTune,
    Handling = tabHandling,
}

--------------------------------------------------------------- FARM
local jobs, jobIds, jobNames = {}, {}, {}
for _, id in ipairs({ "Builder", "Mechanic", "Grab", "Courier", "Delivery" }) do
    local job = JobShared.job(id)
    if job then
        local label = id
        table.insert(jobs, label)
        jobIds[label] = id
        jobNames[id] = label
    end
end

local farmCard = tabFarm:AddCard({ Title = "Jobs", Subtitle = "Manage auto-farm jobs", Column = 1, Toggle = false })
Runtime.Controls.Jobs = {}

local farmVehicleLabels = table.clone(vehicleOptions)
table.insert(farmVehicleLabels, 1, "Random")
local farmVehicleIds = table.clone(ids)
farmVehicleIds["Random"] = "Random"

local function jobVehicleLabel(id)
    local value = Runtime.Farm[id .. "Vehicle"]
    if not value or value == "Random" then
        return "Random"
    end
    return names[value] or "Current"
end

local farmVehicle = farmCard:AddDropdown({
    Name = "Vehicle used",
    Options = farmVehicleLabels,
    Default = "Random",
    Callback = function(value)
        local id = Runtime.Farm.Job
        if id then
            Runtime.Farm[id .. "Vehicle"] = (value == "Random") and "Random" or farmVehicleIds[value]
        end
    end,
})

local function applyJob(label)
    local selected = jobIds[label] or label
    Runtime.Farm.Job = selected
    refreshOptions(farmVehicle, farmVehicleLabels)
    farmVehicle:Set(jobVehicleLabel(selected))
    for _, control in pairs(Runtime.Controls.Jobs or {}) do
        control:Set(false, true)
    end
end

Runtime.Controls.Job = farmCard:AddDropdown({
    Name = "Job",
    Options = jobs,
    Default = jobNames.Builder or jobs[1],
    Callback = applyJob,
})

for _, label in ipairs(jobs) do
    local id = jobIds[label]
    Runtime.Controls.Jobs[id] = toggle(farmCard, label, function(on)
        Runtime:SetFarmEnabled(id, on)
    end)
end

local progressCard = tabFarm:AddCard({ Title = "Progress", Subtitle = "Farm progress & stats", Column = 2, Toggle = false })
local progressLabels = {}
local progressNames = {
    Status = "Status",
    Trips = "Trips",
    Earnings = "Earnings",
    FuelCost = "Fuel cost",
    Elapsed = "Elapsed",
    Condition = "Condition",
    Destination = "Destination",
}
for _, key in ipairs({ "Status", "Trips", "Earnings", "FuelCost", "Elapsed", "Condition", "Destination" }) do
    progressLabels[key] = progressCard:AddInfo({ Text = progressNames[key], Value = "—" })
end
Runtime.FarmProgressLabels = progressLabels

applyJob(jobNames.Builder or jobs[1])

--------------------------------------------------------------- TUNE
local trackCard = tabTune:AddCard({ Title = "Tune tracking", Subtitle = "ECU gain & feedback", Column = 1, Toggle = false })
local labels = {}
labels.Status = trackCard:AddInfo({ Text = "Status", Value = "Ready" })
labels.ECU = trackCard:AddInfo({ Text = "ECU gain", Value = "x1.000" })
labels["Top speed"] = trackCard:AddInfo({ Text = "Top speed", Value = "—" })
for _, key in ipairs({ "Air", "Fuel", "Afr", "Tps", "Oil", "Ign" }) do
    labels[key] = trackCard:AddInfo({ Text = key:upper(), Value = "—" })
end
Runtime.TrackLabels = labels

local tuneCard = tabTune:AddCard({ Title = "Vehicle & tune", Subtitle = "Select vehicle & tune", Column = 2, Toggle = false })
local carControl = tuneCard:AddDropdown({
    Name = "Select vehicle",
    Options = vehicleOptions,
    Default = "Current",
    Callback = function(label)
        local id = ids[label]
        if not id or id == Runtime.SelectedVehicle then
            return
        end
        if not Runtime:SelectVehicle(id) then
            carControl:Set(names[Runtime.SelectedVehicle] or "Current")
        end
    end,
})
Runtime.Controls.TuneVehicle = carControl
Runtime.Controls.TuneEnabled = toggle(tuneCard, "Tune vehicle", function(on)
    if on then
        Runtime:BeginTuneAction("Saved")
    else
        Runtime:StopTune()
    end
end)

local code = tuneCard:AddTextbox({
    Name = "Tune code",
    Default = "",
    Placeholder = "ABCD-EFGH",
    Callback = function(value)
        Runtime.Tune.Code = value
    end,
})
Runtime.Controls.TuneCode = {
    Get = function()
        return code:Get()
    end,
    Set = function(value)
        code:Set(value)
        Runtime.Tune.Code = value
    end,
}
tuneCard:AddButton({ Name = "Create tune code", Callback = function()
    Runtime:BeginTuneAction("Share")
end })
tuneCard:AddButton({ Name = "Apply tune", Callback = function()
    Runtime.Tune.Code = code:Get()
    Runtime:BeginTuneAction("Apply")
end })
tuneCard:AddInfo({ Text = "Code cost", Value = tostring(EcuShared.SHARE_PRICE) .. " B" })
local codeLabel = tuneCard:AddInfo({ Text = "Tune code", Value = "—" })

local function thaiStatus(value)
    local fixed = {
        Idle = "Ready",
        ["Saved tune available"] = "Saved tune available",
        ["Preparing vehicle"] = "Preparing vehicle",
        ["Tune code created"] = "Tune code created",
        ["Tune complete: 100%"] = "Tune complete: 100%",
        ["Tune saved"] = "Tune saved",
        ["Tune stopped"] = "Tune stopped",
        ["Stopping tune"] = "Stopping tune",
    }
    if fixed[value] then
        return fixed[value]
    end
    local key, index, total = value:match("^Tuning (%w+) (%d+)/(%d+)$")
    if key then
        return ("Tuning %s %s/%s"):format(key:upper(), index, total)
    end
    key, index, total = value:match("^Fine tune (%w+) (%d+)/(%d+)$")
    if key then
        return ("Fine tuning %s %s/%s"):format(key:upper(), index, total)
    end
    index = value:match("^Coarse tune (%d+)/10$")
    if index then
        return "Coarse tune " .. index .. "/10"
    end
    return value
end

--------------------------------------------------------------- HANDLING
local handlingCard = tabHandling:AddCard({ Title = "Handling tune", Subtitle = "Steer, brake & launch", Column = 1, Toggle = false })
local adjustVehicle = handlingCard:AddInfo({ Text = "Vehicle", Value = "Get in a vehicle first" })
local handlingSliders = {}
for _, item in ipairs({ { "Steer", "Steer" }, { "Brake", "Brake" }, { "Launch", "Launch" } }) do
    local title, key = item[1], item[2]
    local limits = Runtime.DriveTune.Limits[key]
    local slider = handlingCard:AddSlider({
        Name = title,
        Min = limits[1],
        Max = limits[2],
        Increment = 1,
        Suffix = "%",
        Default = 100,
        Callback = function(value)
            Runtime:SetDriveTune(key, value)
        end,
    })
    handlingSliders[key] = slider
    Runtime.Controls["Handling" .. key] = {
        Get = function()
            local values = Runtime:GetDriveTuneDraft()
            return values and values[key] or 100
        end,
        Set = function(value)
            slider:Set(value, true)
            Runtime:SetDriveTune(key, value)
        end,
    }
end
handlingCard:AddButton({ Name = "Apply", Callback = function()
    Runtime:ApplyDriveTune()
end })
handlingCard:AddButton({ Name = "Reset", Callback = function()
    Runtime:ClearDriveTune()
end })

--------------------------------------------------------------- UTILITIES
local PerfCard = tabUtilities:AddCard({ Title = "Performance", Subtitle = "Reduce lag and save power", Column = 1, Toggle = false })
local UtilLighting = game:GetService("Lighting")

local function SetBlackScreen(On)
    local Gui = getgenv().VS_BlackGui
    if On then
        if Gui and Gui.Parent then return end
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
            if gethui then Parent = gethui() end
        end)
        Gui.Parent = Parent
        getgenv().VS_BlackGui = Gui
    elseif Gui then
        pcall(function() Gui:Destroy() end)
        getgenv().VS_BlackGui = nil
    end
end
PerfCard:AddToggle({ Name = "Black Screen", Default = false, Flag = "BlackScreen", Callback = function(Value) SetBlackScreen(Value) end })
local function SetLowQuality(On)
    pcall(function()
        if On then
            if not getgenv().VS_OldQuality then getgenv().VS_OldQuality = settings().Rendering.QualityLevel end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        else
            settings().Rendering.QualityLevel = getgenv().VS_OldQuality or Enum.QualityLevel.Level21
        end
    end)
end
PerfCard:AddToggle({ Name = "Low Quality", Default = false, Flag = "LowQuality", Callback = function(Value) SetLowQuality(Value) end })
PerfCard:AddToggle({ Name = "FPS Lock", Default = false, Flag = "FPSLock", Callback = function(Value)
    pcall(function()
        if Value then setfpscap(60) else setfpscap(getgenv().VS_FpsCap or 240) end
    end)
end })
PerfCard:AddSlider({ Name = "FPS Cap", Min = 30, Max = 240, Increment = 10, Default = 240, Flag = "FPSCap", Callback = function(Value)
    getgenv().VS_FpsCap = Value
    pcall(function() setfpscap(Value) end)
end })

local UtilCard = tabUtilities:AddCard({ Title = "Misc", Subtitle = "Extra helpers", Toggle = false, Column = 2 })
UtilCard:AddToggle({ Name = "Anti AFK", Default = true, Flag = "AntiAFK", Callback = function(Value)
    getgenv().VS_AntiAfk = Value
    if Value and not getgenv().VS_AntiAfkHooked then
        getgenv().VS_AntiAfkHooked = true
        local VirtualUser = game:GetService("VirtualUser")
        player.Idled:Connect(function()
            if not getgenv().VS_AntiAfk then return end
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end
    if not getgenv().VS_AfkBlockHooked then
        local Ok = pcall(function()
            local Meta = getrawmetatable(game)
            local OldNamecall = Meta.__namecall
            assert(typeof(OldNamecall) == "function", "no __namecall")
            getgenv().VS_AfkOldNamecall = OldNamecall
            setreadonly(Meta, false)
            Meta.__namecall = newcclosure(function(self, ...)
                if getgenv().VS_AntiAfk and not checkcaller() and typeof(self) == "Instance" and getnamecallmethod() == "FireServer" and self.Name == "AfkRejoin" and self:IsA("RemoteEvent") then
                    getgenv().VS_AfkBlocked = (getgenv().VS_AfkBlocked or 0) + 1
                    return nil
                end
                return OldNamecall(self, ...)
            end)
            setreadonly(Meta, true)
        end)
        getgenv().VS_AfkBlockHooked = Ok
    end
end })
pcall(function() UtilCard:GetChildren() end)
UtilCard:AddToggle({ Name = "Fullbright", Default = false, Flag = "Fullbright", Callback = function(Value)
    if Value then
        if not getgenv().VS_OldLighting then
            getgenv().VS_OldLighting = {
                Ambient = game:GetService("Lighting").Ambient,
                OutdoorAmbient = game:GetService("Lighting").OutdoorAmbient,
                Brightness = game:GetService("Lighting").Brightness,
                ClockTime = game:GetService("Lighting").ClockTime,
                FogEnd = game:GetService("Lighting").FogEnd,
                GlobalShadows = game:GetService("Lighting").GlobalShadows,
            }
        end
        game:GetService("Lighting").Ambient = Color3.new(1, 1, 1)
        game:GetService("Lighting").OutdoorAmbient = Color3.new(1, 1, 1)
        game:GetService("Lighting").Brightness = 2
        game:GetService("Lighting").ClockTime = 14
        game:GetService("Lighting").FogEnd = 100000
        game:GetService("Lighting").GlobalShadows = false
    else
        local Old = getgenv().VS_OldLighting
        if Old then
            game:GetService("Lighting").Ambient = Old.Ambient
            game:GetService("Lighting").OutdoorAmbient = Old.OutdoorAmbient
            game:GetService("Lighting").Brightness = Old.Brightness
            game:GetService("Lighting").ClockTime = Old.ClockTime
            game:GetService("Lighting").FogEnd = Old.FogEnd
            game:GetService("Lighting").GlobalShadows = Old.GlobalShadows
        end
    end
end })
UtilCard:AddButton({ Name = "Copy Job ID", Callback = function()
    pcall(function() setclipboard(game.JobId) end)
end })
UtilCard:AddButton({ Name = "Rejoin Server", Callback = function()
    pcall(function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end)
end })
UtilCard:AddLabel("Anti AFK prevents idle kicks")

local InterfaceCard = tabSettings:AddCard({ Title = "Interface", Subtitle = "Menu appearance", Toggle = false, Column = 1 })
InterfaceCard:AddSlider({ Name = "UI Scale", Min = 50, Max = 100, Increment = 5, Default = 100, Flag = "UIScale", Suffix = "%", Callback = function(Value)
    pcall(function()
        Win.UIScale.Scale = Win.BaseScale * (Value / 100)
    end)
end })
InterfaceCard:AddLabel("RightCtrl shows or hides the menu.")

local ConfigCard = tabSettings:AddCard({ Title = "Configs", Subtitle = "Save and load your settings", Toggle = false, Column = 2 })
local ConfigNameBox = ConfigCard:AddTextbox({ Name = "Config", Default = "main", Placeholder = "config name" })
local SavedList = ConfigCard:AddDropdown({ Name = "Saved", Options = { "(no configs)" }, Default = "(no configs)", Callback = function(Value)
    if Value and Value ~= "(no configs)" then
        pcall(function() ConfigNameBox:Set(tostring(Value), true) end)
    end
end })
ConfigCard:AddButton({ Name = "Save", Callback = function()
    local Name = ConfigNameBox:Get()
    local Ok = false
    pcall(function() Ok = Win:SaveConfig(Name) == true end)
    if Ok then Win:Notify({ Title = "Config", Text = "Saved: " .. Name }) else Win:Notify({ Title = "Config", Text = "Save failed: " .. Name }) end
end })
ConfigCard:AddButton({ Name = "Load", Callback = function()
    local Name = ConfigNameBox:Get()
    local Ok = false
    pcall(function() Ok = Win:LoadConfig(Name) == true end)
    if Ok then Win:Notify({ Title = "Config", Text = "Loaded: " .. Name }) else Win:Notify({ Title = "Config", Text = "Not found: " .. Name }) end
end })
ConfigCard:AddButton({ Name = "Delete", Callback = function()
    local Name = ConfigNameBox:Get()
    pcall(function() Win:DeleteConfig(Name) end)
    Win:Notify({ Title = "Config", Text = "Deleted: " .. Name })
end })

--------------------------------------------------------------- sync loop
local elapsed = 0
local lastCode = ""
local function workStatus(worker)
    if Runtime.Farm.Resetting then
        return "Reset character before changing job"
    end
    local value = worker and (worker.LastRecovery or worker.Status) or "Starting work"
    local fixed = {
        Pickup = "Heading to pickup",
        Dropoff = "Heading to dropoff",
        ["Searching for Grab"] = "Waiting for job offer",
        ["Accepting Grab now"] = "Accepting job",
        Stopped = "Stopped",
    }
    if fixed[value] then
        return fixed[value]
    end
    if value:find("^Completed") then
        return "Passenger delivered"
    end
    return value
end

Runtime:Connect(RunService.Heartbeat, function(dt)

    elapsed += dt
    if elapsed < .5 then
        return
    end
    elapsed = 0

    -- ECU
    local state = Runtime:GetTrack()
    Runtime.Controls.TuneEnabled:Set(
        Runtime.Tune.Busy and Runtime.Tune.Action == "Saved" and not Runtime.Tune.Cancel,
        true
    )
    labels.Status:Set(thaiStatus(state.Status))
    labels.ECU:Set(("x%.3f · Saved: %s"):format(state.Gain, state.Saved and "Yes" or "No"))
    labels["Top speed"]:Set(state.TopKmh and ("%.2f km/h"):format(state.TopKmh) or "—")
    for key, title in pairs({ Air = "Air", Fuel = "Fuel", Afr = "Afr", Tps = "Tps", Oil = "Oil", Ign = "Ign" }) do
        local value = state.Feedback[key]
        labels[title]:Set(type(value) == "number" and ("%d%%"):format(math.floor(value * 100 + .5)) or "—")
    end
    codeLabel:Set(state.Code ~= "" and state.Code or "—")
    if state.Code ~= lastCode then
        lastCode = state.Code
        code:Set(state.Code)
    end

    -- Farm
    local worker = (Runtime.Farm.Job == "Grab" or Runtime.Farm.Job == "Delivery" or Runtime.Farm.Job == "Courier")
        and Runtime.Grab or Runtime.OtherWork
    for id, control in pairs(Runtime.Controls.Jobs) do
        control:Set(Runtime.Farm.Enabled[id] == true, true)
    end
    local tripsSeconds = math.floor(worker and worker.StartedAt
        and math.max(0, (worker.StoppedAt or os.clock()) - worker.StartedAt) or 0)
    progressLabels.Status:Set(workStatus(worker))
    progressLabels.Trips:Set(("Completed: %d jobs"):format(worker and worker.Trips or 0))
    progressLabels.Earnings:Set("Earned: " .. GameShared.formatCash(worker and worker.Earned or 0))
    progressLabels.FuelCost:Set("Fuel cost: " .. GameShared.formatCash(worker and worker.FuelSpent or 0))
    progressLabels.Elapsed:Set(("%02d:%02d:%02d"):format(tripsSeconds // 3600, (tripsSeconds // 60) % 60, tripsSeconds % 60))
    local vehicle = worker and worker.Vehicle
    progressLabels.Condition:Set(vehicle
        and ("Fuel %.0f%% · Engine %.0f%%"):format(
            tonumber(vehicle:GetAttribute("Fuel")) or 100,
            tonumber(vehicle:GetAttribute("EngineHealth")) or 100
        )
        or "Preparing vehicle")
    local telemetry = worker and worker.Telemetry
    progressLabels.Destination:Set(telemetry
        and ("Distance to destination: %.0f m"):format((telemetry.Remaining or 0) * .28)
        or "Finding destination")

    -- Handling
    local model = Runtime:DrivenVehicle()
    adjustVehicle:Set(model and (model:GetAttribute("BikeName") or model:GetAttribute("DisplayName")
        or model:GetAttribute("VehicleId")) or "Get in a vehicle first")
    local draft = Runtime:GetDriveTuneDraft()
    for key, slider in pairs(handlingSliders) do
        local value = draft and draft[key] or 100
        if math.abs((slider:Get() or 100) - value) >= 1 then
            slider:Set(value, true)
        end
    end
end)

Runtime.Booting = false
return Runtime
