-- VoltScriptZ | Ghost Driver - Fluent UI (ดำทอง ไม่กระพริบฟ้า)
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local LocalPlayer=Players.LocalPlayer
local Fluent=loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
-- Patch Dark theme เป็นทองก่อนสร้าง Window (กันกระพริบฟ้า)
local Gold=Color3.fromRGB(212,175,55)
local function patchGold()
 for _,tbl in ipairs(getgc(true)) do
  if type(tbl)=="table" and rawget(tbl,"Name")=="Dark" and rawget(tbl,"Accent") then
   tbl.Accent=Gold
   tbl.ToggleSlider=Gold
   tbl.SliderRail=Gold
   tbl.Tab=Gold
   tbl.Hover=Gold
   tbl.DropdownOption=Gold
   tbl.DropdownFrame=Color3.fromRGB(45,45,45)
   tbl.Element=Color3.fromRGB(28,28,28)
   tbl.ElementBorder=Color3.fromRGB(35,35,35)
   tbl.InElementBorder=Color3.fromRGB(50,50,50)
   tbl.AcrylicMain=Color3.fromRGB(12,12,12)
   tbl.AcrylicBorder=Color3.fromRGB(30,30,30)
   tbl.TitleBarLine=Gold
   return true
  end
 end
 -- fallback ลองแบบไม่ใส่ true
 for _,tbl in ipairs(getgc()) do
  if type(tbl)=="table" and rawget(tbl,"Name")=="Dark" and rawget(tbl,"Accent") then
   tbl.Accent=Gold
   tbl.ToggleSlider=Gold
   tbl.SliderRail=Gold
   return true
  end
 end
 return false
end
pcall(patchGold)
local Window=Fluent:CreateWindow({
 Title="VoltScriptZ | Ghost Driver",
 TabWidth=160,
 Size=UDim2.fromOffset(480,380),
 Acrylic=false,
 Theme="Dark",
 MinimizeKey=Enum.KeyCode.LeftControl
})
-- patch ซ้ำหลังสร้าง Window กันหลุด
pcall(patchGold)
pcall(function() Fluent:SetTheme("Dark") end)
-- บังคับพื้นหลังดำทึบ 100% (ปิด Transparency ของ Fluent)
pcall(function()
 Fluent:ToggleTransparency(false)
 if Window.AcrylicPaint and Window.AcrylicPaint.Frame and Window.AcrylicPaint.Frame.Background then
  Window.AcrylicPaint.Frame.Background.BackgroundTransparency=0
  Window.AcrylicPaint.Frame.Background.BackgroundColor3=Color3.fromRGB(12,12,12)
 end
end)
-- Loop สำรองย้อมฟ้าที่หลงเหลือ (0.08วิ) กัน tween แวบฟ้า
task.spawn(function()
 task.wait(0.3)
 while true do
  pcall(function()
   if Window.AcrylicPaint and Window.AcrylicPaint.Frame and Window.AcrylicPaint.Frame.Background then
    Window.AcrylicPaint.Frame.Background.BackgroundTransparency=0
    Window.AcrylicPaint.Frame.Background.BackgroundColor3=Color3.fromRGB(12,12,12)
   end
   -- จับฟ้าทุกเฉด (96,205,255 / 72,138,182 / tween ระหว่าง)
   local function isBlue(c) return c and c.B*255>140 and c.R*255<130 and c.G*255>120 and c.B>c.R+30 end
   local function paintGui(gui)
    for _,v in ipairs(gui:GetDescendants()) do
     if v:IsA("Frame") and isBlue(v.BackgroundColor3) then v.BackgroundColor3=Gold end
     if v:IsA("UIStroke") and isBlue(v.Color) then v.Color=Gold end
     if v:IsA("TextLabel") and isBlue(v.TextColor3) then v.TextColor3=Gold end
     if v:IsA("ImageLabel") and v.ImageColor3 and isBlue(v.ImageColor3) then v.ImageColor3=Gold end
     if v:IsA("BlurEffect") then v.Enabled=false end
    end
   end
   if Window.Container then paintGui(Window.Container) end
   for _,g in ipairs(game:GetService("CoreGui"):GetChildren()) do if g.Name:find("Fluent") then paintGui(g) end end
  end)
  task.wait(0.08)
  if Fluent.Unloaded then break end
 end
end)
local Tabs={
 Main=Window:AddTab({Title="Auto Pilot", Icon="navigation"}),
 Farm=Window:AddTab({Title="Game Setting", Icon="settings"})
}
local Options=Fluent.Options
local state={enabled=false,lane="Auto",lookAhead=45,speed=165,swerveFarm=true,avoidTraffic=true,smooth=0.18,avoidDist=38,avoidStrength=14}
local function notify(t,c,i) end -- notifications disabled
local function getMyCar()
 for _,m in ipairs(Workspace:GetChildren()) do if m:IsA("Model") and m:GetAttribute("OwnerUserId")==LocalPlayer.UserId then return m end end
 for _,m in ipairs(Workspace:GetChildren()) do if m:IsA("Model") and m.Name:find(LocalPlayer.Name) and m:FindFirstChild("DriveSeat") then return m end end
 return nil
end
local function isSeated(car)
 local s=car and car:FindFirstChild("DriveSeat")
 local occ=s and s.Occupant
 return occ and occ.Parent==LocalPlayer.Character
end
local CarPlacement
pcall(function() CarPlacement=require(ReplicatedStorage:WaitForChild("CarPlacement")) end)
local mapCache,trafficCache
local function fetchCaches()
 local ok1,d1=pcall(function() return ReplicatedStorage:WaitForChild("GetMapCacheFunc"):InvokeServer() end)
 if ok1 and type(d1)=="table" then mapCache=d1
  for _,lane in pairs(d1) do if lane.Waypoints and not lane.Segments then
   local segs,total={},0
   for i=1,#lane.Waypoints-1 do local v=lane.Waypoints[i+1]-lane.Waypoints[i] segs[i]={Length=v.Magnitude,Direction=v.Unit} total+=v.Magnitude end
   lane.Segments=segs
   lane.TotalLength=total
  end end
 end
 local ok2,d2=pcall(function() return ReplicatedStorage:WaitForChild("SyncTrafficFunc"):InvokeServer() end)
 if ok2 and type(d2)=="table" then trafficCache=d2 end
 return mapCache
end
local function getLane()
 if not mapCache then fetchCaches() end
 if not mapCache then return nil end
 local laneName=state.lane
 if laneName=="Auto" then
  local car=getMyCar()
  local pos=car and car:GetPivot().Position or (LocalPlayer.Character and LocalPlayer.Character:GetPivot().Position)
  if pos and mapCache.Lane1 then
   local function d(l) return (l.Waypoints[1]-pos).Magnitude end
   local d1,d2,d3=d(mapCache.Lane1),d(mapCache.Lane2),d(mapCache.Lane3)
   local m=math.min(d1,d2,d3)
   if m==d1 then laneName="Lane1" elseif m==d2 then laneName="Lane2" else laneName="Lane3" end
  else laneName="Lane2" end
 end
 local lane=mapCache[laneName] or mapCache.Lane2 or mapCache.Lane1
 state._laneName=laneName
 return lane
end
local function getTargetPoint(carPos,lane)
 if not lane or not lane.Waypoints then return nil end
 local bestDist,bestIdx,bestProj=math.huge,1,0
 for i=1,#lane.Waypoints-1 do
  local a,b=lane.Waypoints[i],lane.Waypoints[i+1]
  local ab=b-a
  local t=math.clamp((carPos-a):Dot(ab)/ab:Dot(ab),0,1)
  local proj=a+ab*t
  local d=(carPos-proj).Magnitude
  if d<bestDist then bestDist,bestIdx,bestProj=d,i,t end
 end
 local remaining=state.lookAhead
 local segLen=lane.Segments[bestIdx].Length*(1-bestProj)
 if remaining<=segLen then
  local start=lane.Waypoints[bestIdx]+(lane.Waypoints[bestIdx+1]-lane.Waypoints[bestIdx])*bestProj
  return start+lane.Segments[bestIdx].Direction*remaining
 end
 remaining-=segLen
 for i=bestIdx+1,#lane.Segments do
  if remaining<=lane.Segments[i].Length then return lane.Waypoints[i]+lane.Segments[i].Direction*remaining
  else remaining-=lane.Segments[i].Length end
 end
 return lane.Waypoints[#lane.Waypoints]
end
local function getTrafficPos(entry, serverNow)
 local lane=mapCache and mapCache[entry.LaneName]
 if not lane or not lane.Waypoints or not lane.Segments then return nil end
 local elapsed=serverNow-entry.SpawnTime
 if elapsed<0 then return nil end
 local dist=elapsed*(lane.Speed or 110)
 if dist>(lane.TotalLength or 95000) then return nil end
 local cur=0
 for i,seg in ipairs(lane.Segments) do
  if dist<=cur+seg.Length then
   local t=dist-cur
   return lane.Waypoints[i]+seg.Direction*t, seg.Direction
  end
  cur+=seg.Length
 end
 return lane.Waypoints[#lane.Waypoints], lane.Segments[#lane.Segments].Direction
end
local autopilotConn
local function startAutopilot()
 if autopilotConn then autopilotConn:Disconnect() end
 fetchCaches()
 local lane=getLane()
 if not lane then notify("Auto Pilot","โหลด Waypoints ไม่ได้","triangle-alert") return end
 notify("Auto Pilot","Start "..(state._laneName or lane).." เปลี่ยนเลนอัตโนมัติ","play")
 local lastClock=os.clock()
 autopilotConn=RunService.Heartbeat:Connect(function()
  if not state.enabled then return end
  local car=getMyCar()
  if not car then return end
  local seat=car:FindFirstChild("DriveSeat")
  if not seat then return end
  if not isSeated(car) then pcall(function() seat:Sit(LocalPlayer.Character:FindFirstChild("Humanoid")) end) return end
  local cf=car:GetPivot()
  local pos=cf.Position
  local look=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z).Unit
  if state.lane=="Auto" and math.random()<0.008 then lane=getLane() end
  local target=getTargetPoint(pos,lane)
  if not target then return end
  local steerTarget=target
  if state.avoidTraffic then
   local curLane=state._laneName or "Lane2"
   local function hasTrafficInLane(laneName, checkDist)
    if not mapCache or not mapCache[laneName] then return false, math.huge end
    local best=math.huge
    local now=Workspace:GetServerTimeNow()
    for _,e in ipairs(trafficCache or {}) do
     if e.LaneName==laneName then
      local p0=getTrafficPos(e, now)
      if p0 then
       local toT=p0-pos
       local flat=Vector3.new(toT.X,0,toT.Z)
       local d=flat.Magnitude
       if d<checkDist and look:Dot(flat.Unit)>0.3 and d<best then best=d end
      end
     end
    end
    return best < 1e9, best
   end
   local has, dist = hasTrafficInLane(curLane, state.avoidDist)
   if has and dist < state.avoidDist then
    local order={"Lane1","Lane2","Lane3"}
    local idx=3
    for i,v in ipairs(order) do if v==curLane then idx=i break end end
    local cands={}
    if idx>1 then table.insert(cands, order[idx-1]) end
    if idx<3 then table.insert(cands, order[idx+1]) end
    local bestLane=nil
    for _,ln in ipairs(cands) do
     local h,_ = hasTrafficInLane(ln, 45)
     if not h then bestLane=ln break end
    end
    if bestLane and mapCache[bestLane] then
     local altTarget=getTargetPoint(pos, mapCache[bestLane])
     if altTarget then
      steerTarget=altTarget
      state._laneName=bestLane
      lane=mapCache[bestLane]
     end
    else
     local bestD=math.huge
     local tpos
     local now=Workspace:GetServerTimeNow()
     for _,e in ipairs(trafficCache or {}) do if e.LaneName==curLane then local p0=getTrafficPos(e,now) if p0 then local d=(Vector3.new(p0.X-pos.X,0,p0.Z-pos.Z)).Magnitude if d<bestD and look:Dot((p0-pos).Unit)>0.2 then bestD=d tpos=p0 end end end end
     if tpos then
      local lateral=cf.RightVector:Dot((tpos-pos).Unit)
      local strength=state.avoidStrength * math.clamp((state.avoidDist-dist)/state.avoidDist,0.2,1)
      if dist<14 then strength=strength*1.7 end
      local off=(lateral>0 and -1 or 1)*strength
      steerTarget=target+cf.RightVector*off
     end
    end
   elseif has and dist<18 and state.swerveFarm then
    local tpos
    do local bestD=math.huge local now=Workspace:GetServerTimeNow() for _,e in ipairs(trafficCache or {}) do if e.LaneName==curLane then local p0=getTrafficPos(e,now) if p0 then local d=(Vector3.new(p0.X-pos.X,0,p0.Z-pos.Z)).Magnitude if d<bestD and d<18 then bestD=d tpos=p0 end end end end end
    if tpos then
     local lateral=cf.RightVector:Dot((tpos-pos).Unit)
     if math.abs(lateral*dist)<12 then
      local off=(lateral>0 and -1 or 1)*7
      steerTarget=target+cf.RightVector*off
     end
    end
   end
  end
  local dt=math.clamp(os.clock()-lastClock,0.016,0.05)
  lastClock=os.clock()
  local dir=(steerTarget-pos)
  dir=Vector3.new(dir.X,0,dir.Z)
  if dir.Magnitude<0.5 then return end
  dir=dir.Unit
  local curDir=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z).Unit
  local lerpDir=curDir:Lerp(dir, math.clamp(state.smooth*2.2,0.1,0.7)).Unit
  local step=state.speed*dt
  local angleDiff=math.acos(math.clamp(curDir:Dot(dir),-1,1))
  if angleDiff>0.5 then step=step*0.65 end
  local newPos=pos+lerpDir*math.min(step, (steerTarget-pos).Magnitude)
  local groundY
  if CarPlacement and CarPlacement.groundYAt then groundY=CarPlacement.groundYAt(newPos, car) end
  if not groundY then groundY=pos.Y end
  local pivotOff
  if CarPlacement and CarPlacement.pivotToBottom then pivotOff=CarPlacement.pivotToBottom(car) else pivotOff=1.6 end
  local newY=groundY+pivotOff+0.35
  local newCf=CFrame.lookAt(Vector3.new(newPos.X,newY,newPos.Z), Vector3.new(steerTarget.X,newY,steerTarget.Z))
  pcall(function() car:PivotTo(newCf) end)
  local kmh=state.speed*0.35*1.609
  if kmh<78 then kmh=85 end
  local mag=kmh/0.35/1.609
  pcall(function()
   seat.AssemblyLinearVelocity=lerpDir*mag
   for _,v in ipairs(car:GetDescendants()) do if v:IsA("BasePart") then v.AssemblyLinearVelocity=lerpDir*mag end end
  end)
 end)
end
local function stopAutopilot()
 if autopilotConn then autopilotConn:Disconnect() autopilotConn=nil end
 local car=getMyCar()
 if car and car:FindFirstChild("DriveSeat") then pcall(function()
  local s=car.DriveSeat
  s.AssemblyLinearVelocity=Vector3.zero
  for _,v in ipairs(car:GetDescendants()) do if v:IsA("BasePart") then v.AssemblyLinearVelocity=Vector3.zero end end
 end) end
 notify("Auto Pilot","Stop")
end
-- Fluent UI Elements
Tabs.Main:AddToggle("AutoPilotEnabled", {
 Title="Auto Pilot",
 Default=false,
 Callback=function(Value)
  state.enabled=Value
  if Value then startAutopilot() else stopAutopilot() end
 end
})
Tabs.Main:AddDropdown("LaneSelect", {
 Title="Lane",
 Values={"Auto","Lane1","Lane2","Lane3"},
 Multi=false,
 Default=1,
 Callback=function(Value)
  state.lane=Value
  if state.enabled then fetchCaches() end
 end
})
Tabs.Main:AddSlider("SpeedSlider", {
 Title="Speed",
 Default=165,
 Min=90,
 Max=200,
 Rounding=0,
 Callback=function(Value)
  state.speed=Value
 end
})
Tabs.Farm:AddToggle("Swerve", {
 Title="Swerve",
 Default=true,
 Callback=function(Value) state.swerveFarm=Value end
})
Tabs.Farm:AddToggle("AvoidTraffic", {
 Title="Dodge traffic",
 Default=true,
 Callback=function(Value) state.avoidTraffic=Value end
})
Window:SelectTab(1)
task.spawn(function() task.wait(1) pcall(fetchCaches) end)
