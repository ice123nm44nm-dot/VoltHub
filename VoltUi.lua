--// VoltScriptZ UI v3.4 : complete UI library (no auto demo).
--// Usage: local Library = loadstring(game:HttpGet("..."))()
--// Then: local Win = Library:CreateWindow({...})  /  Library:Demo() for preview
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

local Theme = {
    Window      = Color3.fromRGB(12, 9, 23),
    Sidebar     = Color3.fromRGB(15, 11, 29),
    Card        = Color3.fromRGB(18, 13, 35),
    CardHeader  = Color3.fromRGB(29, 21, 56),
    Row         = Color3.fromRGB(13, 10, 26),
    Stroke      = Color3.fromRGB(44, 33, 82),
    Accent      = Color3.fromRGB(124, 58, 237),
    AccentLight = Color3.fromRGB(167, 110, 255),
    AccentDark  = Color3.fromRGB(88, 40, 190),
    Text        = Color3.fromRGB(242, 238, 255),
    SubText     = Color3.fromRGB(150, 120, 230),
    Muted       = Color3.fromRGB(165, 155, 205),
    Off         = Color3.fromRGB(46, 41, 72),
    Para        = Color3.fromRGB(172, 152, 236),
    Value       = Color3.fromRGB(204, 196, 238),
}

-- Fonts: change here once, applies to the whole UI
local Fonts = {
    Regular = Enum.Font.BuilderSans,
    Medium  = Enum.Font.BuilderSansMedium,
    Bold    = Enum.Font.BuilderSansBold,
}

local Library = { Theme = Theme, Fonts = Fonts, Version = "v3.4" }
Library.Windows = {}
local Window, Tab, Card = {}, {}, {}
Window.__index, Tab.__index, Card.__index = Window, Tab, Card

-- NOTE: Card header Switch is intentionally a VALUE FLAG (Default/Flag/Callback).
-- It does NOT collapse/expand Body. Body shows automatically when content is added.
-- Card rounded-corner fix (HeaderBg/HeaderFill + _showBody) kept as-is.

local W, H, SIDEBAR, HEADER, GAP = 740, 532, 168, 54, 13
local Left, Right, Center = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right, Enum.TextXAlignment.Center

---------------------------------------------------------------- helpers
local function New(class, props, children)
    local inst = Instance.new(class)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else inst[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    inst.Parent = parent
    return inst
end

local function Corner(r) return New("UICorner", { CornerRadius = UDim.new(0, r) }) end

local function Stroke(color, thickness, transparency)
    return New("UIStroke", {
        Color = color, Thickness = thickness or 1, Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function Pad(t, r, b, l)
    return New("UIPadding", {
        PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r),
        PaddingBottom = UDim.new(0, b), PaddingLeft = UDim.new(0, l),
    })
end

local function Tween(obj, goal, time, style, dir)
    local t = TweenService:Create(obj, TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
    t:Play()
    return t
end

local function Label(props)
    local d = {
        BackgroundTransparency = 1, BorderSizePixel = 0, Font = Fonts.Medium,
        TextSize = 13, TextColor3 = Theme.Text, TextXAlignment = Left,
    }
    for k, v in pairs(props) do d[k] = v end
    return New("TextLabel", d)
end

-- a thin rotated bar: used to draw X, check, chevron without relying on fonts
local function Bar(parent, w, h, pos, rot, color)
    return New("Frame", {
        Size = UDim2.fromOffset(w, h), AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Rotation = rot,
        BackgroundColor3 = color, BorderSizePixel = 0, Parent = parent,
    }, { Corner(1) })
end

local function Chevron(parent, pos, color)
    Bar(parent, 7, 2, UDim2.new(pos.X.Scale, pos.X.Offset - 2.5, pos.Y.Scale, pos.Y.Offset), 45, color)
    Bar(parent, 7, 2, UDim2.new(pos.X.Scale, pos.X.Offset + 2.5, pos.Y.Scale, pos.Y.Offset), -45, color)
end

local function GetParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local ok = pcall(function() return game:GetService("CoreGui").Name end)
    if ok then return game:GetService("CoreGui") end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function IsPress(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function IsMove(i)
    return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

local function SanitizeConfigName(name)
    name = tostring(name or "config")
    -- strip path traversal / folders, keep only safe chars
    name = string.gsub(name, "[\\/]", "_")
    name = string.gsub(name, "%.%.", "_")
    name = string.gsub(name, "[^%w%-%_ ]", "_")
    name = string.gsub(name, "^%s+", "")
    name = string.gsub(name, "%s+$", "")
    if name == "" then name = "config" end
    if #name > 64 then name = string.sub(name, 1, 64) end
    return name
end

local function Switch(parent, default, callback)
    local obj = { Value = default and true or false }
    local track = New("TextButton", {
        Size = UDim2.fromOffset(36, 18), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        BackgroundColor3 = obj.Value and Theme.Accent or Theme.Off, Text = "", AutoButtonColor = false, Parent = parent,
    }, { Corner(9) })
    local knob = New("Frame", {
        Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0, 0.5),
        Position = obj.Value and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(238, 232, 255), Parent = track,
    }, { Corner(6) })
    function obj:Set(v, silent)
        v = v and true or false
        self.Value = v
        Tween(track, { BackgroundColor3 = v and Theme.Accent or Theme.Off })
        Tween(knob, { Position = v and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
        if not silent and callback then task.spawn(callback, v) end
    end
    function obj:Get() return self.Value end
    track.MouseButton1Click:Connect(function() obj:Set(not obj.Value) end)
    return obj
end

---------------------------------------------------------------- window
function Library:CreateWindow(o)
    o = o or {}
    local self = setmetatable({ Tabs = {}, Flags = {}, Current = nil, Order = 0, Sections = 0, Connections = {}, ToggleKey = o.ToggleKey or Enum.KeyCode.RightControl }, Window)
    table.insert(Library.Windows, self)
    local guiName = o.Name or "VoltLib"
    local root = GetParent()
    for _, g in ipairs(root:GetChildren()) do
        if g.Name == guiName then g:Destroy() end
    end

    self.Gui = New("ScreenGui", {
        Name = guiName, ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, Parent = root,
    })

    local cam = workspace.CurrentCamera
    local vs = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    local scale = math.min(1, (vs.X - 24) / W, (vs.Y - 24) / H)

    self.Main = New("Frame", {
        Name = "Main", Size = UDim2.fromOffset(W, H), Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        ClipsDescendants = true, Parent = self.Gui,
    }, {
        Corner(12),
        New("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, {
            New("UIGradient", { Rotation = 45, Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(155, 95, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(92, 58, 235)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(155, 95, 255)),
            }) }),
        }),
        New("UIScale", { Scale = scale }),
        New("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(26, 18, 52), Color3.fromRGB(14, 10, 30)) }),
    })
    local uiScale = self.Main:FindFirstChildOfClass("UIScale")
    self.UIScale, self.BaseScale, self.Shown, self.Closing = uiScale, scale, true, false

    -- soft ambient glow: one full-window layer, no hard rectangle edges
    New("Frame", {
        Name = "Glow", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0, ZIndex = 0, Parent = self.Main,
    }, {
        New("UIGradient", { Rotation = 45, Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.93),
            NumberSequenceKeypoint.new(0.35, 1),
            NumberSequenceKeypoint.new(0.6, 1),
            NumberSequenceKeypoint.new(1, 0.84),
        }) }),
    })

    -- sidebar
    local sidebarColor = Color3.fromRGB(15, 11, 28)
    self.Sidebar = New("Frame", {
        Size = UDim2.new(0, SIDEBAR, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = self.Main,
    }, {
        New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = sidebarColor, BorderSizePixel = 0 }, { Corner(12) }),
        New("Frame", { Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(24, 0), BackgroundColor3 = sidebarColor, BorderSizePixel = 0 }),
        New("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0 }),
    })
    self.TabList = New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -72), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = self.Sidebar,
    }, {
        New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
        Pad(10, 10, 8, 10),
    })

    -- footer
    local footer = New("Frame", {
        Size = UDim2.new(1, -1, 0, 72), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1, Parent = self.Sidebar,
    }, {
        New("Frame", { Size = UDim2.new(1, -24, 0, 1), Position = UDim2.fromOffset(12, 0), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0 }),
    })
    local user = o.User or {}
    local userName = user.Name or Players.LocalPlayer.DisplayName
    local avatar = New("Frame", {
        Size = UDim2.fromOffset(38, 38), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 2),
        BackgroundColor3 = Theme.Row, ClipsDescendants = true, Parent = footer,
    }, { Corner(19), Stroke(Theme.Accent, 2, 0.1) })
    local avatarLogo = user.Logo or o.Logo
    if avatarLogo then
        New("ImageLabel", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = avatarLogo, Parent = avatar,
        }, { Corner(19) })
    else
        Label({ Text = string.upper(string.sub(userName, 1, 1)), TextSize = 17, Font = Fonts.Bold,
            TextColor3 = Theme.AccentLight, TextXAlignment = Center, Size = UDim2.fromScale(1, 1), Parent = avatar })
    end
    Label({
        Text = userName, Font = Fonts.Bold, TextSize = 13, Position = UDim2.fromOffset(58, 18),
        Size = UDim2.new(1, -64, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, Parent = footer,
    })
    Label({
        Text = user.Tag or "Premium User", TextSize = 11, TextColor3 = Theme.AccentLight,
        Position = UDim2.fromOffset(58, 36), Size = UDim2.new(1, -64, 0, 14), Parent = footer,
    })

    -- header
    local header = New("Frame", {
        Size = UDim2.new(1, -SIDEBAR, 0, HEADER), Position = UDim2.fromOffset(SIDEBAR, 0),
        BackgroundTransparency = 1, Parent = self.Main,
    }, {
        New("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0 }),
    })
    Label({
        RichText = true, Font = Fonts.Bold, TextSize = 24, Position = UDim2.fromOffset(GAP, 5),
        Size = UDim2.new(1, -150, 0, 28),
        Text = string.format('%s<font color="rgb(167,110,255)">%s</font>', o.Title or "Volt", o.TitleAccent or "ScriptZ"),
        Parent = header,
    })
    Label({
        Text = o.Subtitle or "Premium Script Hub | Made for Roblox", TextSize = 12, TextColor3 = Theme.SubText,
        Position = UDim2.fromOffset(GAP, 32), Size = UDim2.new(1, -150, 0, 16), Parent = header,
    })

    local function HeaderBtn(x, draw, cb)
        local b = New("TextButton", {
            Size = UDim2.fromOffset(32, 32), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0),
            BackgroundColor3 = Theme.Row, Text = "", AutoButtonColor = false, Parent = header,
        }, { Corner(7), Stroke(Theme.Stroke, 1) })
        draw(b)
        b.MouseEnter:Connect(function() Tween(b, { BackgroundColor3 = Theme.CardHeader }) end)
        b.MouseLeave:Connect(function() Tween(b, { BackgroundColor3 = Theme.Row }) end)
        b.MouseButton1Click:Connect(cb)
    end
    HeaderBtn(-14, function(b)
        Bar(b, 14, 2, UDim2.fromScale(0.5, 0.5), 45, Theme.AccentLight)
        Bar(b, 14, 2, UDim2.fromScale(0.5, 0.5), -45, Theme.AccentLight)
    end, function() self:Close() end)
    HeaderBtn(-54, function(b)
        Bar(b, 12, 2, UDim2.fromScale(0.5, 0.5), 0, Theme.AccentLight)
    end, function() self:Toggle(false) end)

    self.Content = New("Frame", {
        Size = UDim2.new(1, -SIDEBAR, 1, -HEADER), Position = UDim2.fromOffset(SIDEBAR, HEADER),
        BackgroundTransparency = 1, Parent = self.Main,
    })

    -- floating reopen button (shown while window is hidden): draggable, click to reopen
    self.Float = New("TextButton", {
        Size = UDim2.fromOffset(44, 44), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 60),
        BackgroundColor3 = Theme.Window, Text = o.Logo and "" or (o.FloatText or "V"), Font = Fonts.Bold, TextSize = 20,
        TextColor3 = Theme.AccentLight, AutoButtonColor = false, Visible = false, Parent = self.Gui,
    }, { Corner(22), Stroke(Theme.Accent, 2, 0.2) })
    if o.Logo then
        New("ImageLabel", {
            Size = UDim2.fromOffset(32, 32), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            BackgroundTransparency = 1, Image = o.Logo, Parent = self.Float,
        }, { Corner(16) })
    end
    -- drag to move; release without moving reopens the window
    local floatDragging, floatDragStart, floatStartPos, floatMoved
    self:_connect(self.Float.InputBegan, function(i)
        if IsPress(i) then
            floatDragging, floatDragStart, floatStartPos, floatMoved = true, i.Position, self.Float.Position, false
        end
    end)
    self:_connect(UserInputService.InputChanged, function(i)
        if floatDragging and IsMove(i) then
            local d = i.Position - floatDragStart
            if d.Magnitude > 8 then floatMoved = true end
            if floatMoved then
                self.Float.Position = UDim2.new(floatStartPos.X.Scale, floatStartPos.X.Offset + d.X,
                    floatStartPos.Y.Scale, floatStartPos.Y.Offset + d.Y)
            end
        end
    end)
    self:_connect(UserInputService.InputEnded, function(i)
        if floatDragging and IsPress(i) then
            floatDragging = false
            if not floatMoved then self:Toggle(true) end
        end
    end)

    -- popup blocker (closes the open dropdown)
    self.Blocker = New("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Visible = false, ZIndex = 50, Parent = self.Gui,
    })
    local function closeAnyPopup()
        if self.CloseDropdown then self.CloseDropdown() end
        if self.ClosePopup then self.ClosePopup() end
    end
    self._closeAnyPopup = closeAnyPopup
    self:_connect(self.Blocker.MouseButton1Click, function()
        closeAnyPopup()
    end)
    -- auto-close dropdown/popup when window moves
    self:_connect(self.Main:GetPropertyChangedSignal("Position"), function()
        closeAnyPopup()
    end)
    -- auto-close on viewport resize
    local cam = workspace.CurrentCamera
    if cam then
        pcall(function()
            self:_connect(cam:GetPropertyChangedSignal("ViewportSize"), function()
                closeAnyPopup()
            end)
        end)
    end

    -- dragging (header) + close dropdown when drag starts
    local dragging, dragStart, startPos
    self:_connect(header.InputBegan, function(i)
        if IsPress(i) then
            closeAnyPopup()
            dragging, dragStart, startPos = true, i.Position, self.Main.Position
        end
    end)
    self:_connect(UserInputService.InputChanged, function(i)
        if dragging and IsMove(i) then
            local d = (i.Position - dragStart) / uiScale.Scale
            self.Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    self:_connect(UserInputService.InputEnded, function(i)
        if IsPress(i) then dragging = false end
    end)

    self:_connect(UserInputService.InputBegan, function(i, gp)
        if gp then return end
        if i.KeyCode == self.ToggleKey then self:Toggle() end
        if i.KeyCode == Enum.KeyCode.Escape then
            if self.CloseDropdown then self.CloseDropdown() end
            if self.ClosePopup then self.ClosePopup() end
        end
    end)

    self:_animate(true)
    return self
end

function Window:_connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(self.Connections, c)
    return c
end

function Window:_next()
    self.Order = self.Order + 1
    return self.Order
end

-- open / close animation (pop scale). Float button pops in when the window is hidden.
function Window:_animate(show)
    self.AnimToken = (self.AnimToken or 0) + 1
    local token = self.AnimToken
    local small = self.BaseScale * 0.9
    if show then
        self.Float.Visible = false
        self.Main.Visible = true
        self.UIScale.Scale = small
        Tween(self.UIScale, { Scale = self.BaseScale }, 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    else
        if self.CloseDropdown then self.CloseDropdown() end
        local t = Tween(self.UIScale, { Scale = small }, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        t.Completed:Connect(function(state)
            if state ~= Enum.PlaybackState.Completed or token ~= self.AnimToken then return end
            self.Main.Visible = false
            self.UIScale.Scale = self.BaseScale
            self.Float.Size = UDim2.fromOffset(0, 0)
            self.Float.TextTransparency = 1
            self.Float.Visible = true
            Tween(self.Float, { Size = UDim2.fromOffset(44, 44), TextTransparency = 0 }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end)
    end
end

function Window:Toggle(state)
    if self.Closing then return end
    if state == nil then state = not self.Shown end
    if state == self.Shown then return end
    self.Shown = state
    self:_animate(state)
end

function Window:Close()
    if self.Closing then return end
    self.Closing = true
    if self.CloseDropdown then self.CloseDropdown() end
    if self.ClosePopup then self.ClosePopup() end
    local t = Tween(self.UIScale, { Scale = self.BaseScale * 0.9 }, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    t.Completed:Connect(function() self:Destroy() end)
end

function Window:Destroy()
    self:DisableAutoSave()
    self.AnimToken = (self.AnimToken or 0) + 1
    self.CloseDropdown = nil
    self.ClosePopup = nil
    for _, c in ipairs(self.Connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(self.Connections)
    for i, w in ipairs(Library.Windows) do
        if w == self then table.remove(Library.Windows, i) break end
    end
    if self.Gui then
        pcall(function() self.Gui:Destroy() end)
    end
end

function Window:SetToggleKey(key)
    self.ToggleKey = key
end

function Window:GetFlag(flag)
    local obj = self.Flags[flag]
    if obj and obj.Get then return obj:Get() end
    return nil
end

function Window:SetFlag(flag, value)
    local obj = self.Flags[flag]
    if obj and obj.Set then obj:Set(value) end
end

-- toast notification (bottom-right of screen, auto fade)
function Window:Notify(o)
    o = type(o) == "table" and o or { Text = tostring(o) }
    local holder = self.Gui:FindFirstChild("NotifyHolder")
    if not holder then
        holder = New("Frame", {
            Name = "NotifyHolder", Size = UDim2.new(0, 260, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16),
            BackgroundTransparency = 1, ZIndex = 100, Parent = self.Gui,
        }, { New("UIListLayout", { Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder }) })
    end
    self._notifyOrder = (self._notifyOrder or 0) + 1
    local n = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.CardHeader,
        BorderSizePixel = 0, ZIndex = 101, LayoutOrder = self._notifyOrder, Parent = holder,
    }, { Corner(8), Stroke(Theme.Accent, 1, 0.4), Pad(10, 10, 10, 10),
        New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }) })
    Label({ Text = o.Title or "Notice", Font = Fonts.Bold, TextSize = 13, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1, ZIndex = 102, Parent = n })
    Label({ Text = o.Text or "", TextSize = 12, TextColor3 = Theme.Para, TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, ZIndex = 102, Parent = n })
    task.delay(o.Duration or 3, function()
        if n.Parent then
            Tween(n, { BackgroundTransparency = 1 }, 0.3)
            for _, d in ipairs(n:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    Tween(d, { TextTransparency = 1, BackgroundTransparency = 1 }, 0.3)
                elseif d:IsA("UIStroke") then
                    Tween(d, { Transparency = 1 }, 0.3)
                elseif d:IsA("Frame") then
                    pcall(function() Tween(d, { BackgroundTransparency = 1 }, 0.3) end)
                end
            end
            local stroke = n:FindFirstChildOfClass("UIStroke")
            if stroke then Tween(stroke, { Transparency = 1 }, 0.3) end
            task.delay(0.32, function()
                if n.Parent then n:Destroy() end
            end)
        end
    end)
    return n
end

function Library:Unload()
    for _, w in ipairs(table.clone(Library.Windows)) do
        pcall(function() w:Destroy() end)
    end
end

-- Change accent for FUTURE windows (existing windows keep their colors).
function Library:SetTheme(t)
    for k, v in pairs(t or {}) do Theme[k] = v end
    Library.Theme = Theme
end

-- Simple splash / loading screen. Returns handle with :Close().
function Library:Loading(o)
    o = o or {}
    local root = GetParent()
    local gui = New("ScreenGui", { Name = "VoltLoading", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1000, Parent = root })
    local bg = New("Frame", { Size = UDim2.fromOffset(320, 140), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = gui }, { Corner(12), Stroke(Theme.Accent, 1, 0.3) })
    Label({ Text = o.Title or "VoltScriptZ", Font = Fonts.Bold, TextSize = 20, TextXAlignment = Center, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 18), Parent = bg })
    Label({ Text = o.Subtitle or "Loading...", TextSize = 12, TextColor3 = Theme.SubText, TextXAlignment = Center, Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 50), Parent = bg })
    local track = New("Frame", { Size = UDim2.new(1, -48, 0, 6), Position = UDim2.new(0, 24, 0, 90), BackgroundColor3 = Theme.Off, BorderSizePixel = 0, Parent = bg }, { Corner(3) })
    local fill = New("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track },
        { Corner(3), New("UIGradient", { Color = ColorSequence.new(Theme.AccentDark, Theme.AccentLight) }) })
    Tween(fill, { Size = UDim2.new(1, 0, 1, 0) }, o.Duration or 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local handle = {}
    function handle:Close()
        if gui.Parent then
            Tween(bg, { BackgroundTransparency = 1 }, 0.25)
            for _, d in ipairs(bg:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    Tween(d, { TextTransparency = 1, BackgroundTransparency = 1 }, 0.25)
                elseif d:IsA("UIStroke") then
                    Tween(d, { Transparency = 1 }, 0.25)
                elseif d:IsA("Frame") then
                    pcall(function() Tween(d, { BackgroundTransparency = 1 }, 0.25) end)
                end
            end
            task.delay(0.27, function()
                if gui.Parent then gui:Destroy() end
            end)
        end
    end
    if o.Duration then task.delay(o.Duration + 0.15, function() handle:Close() end) end
    return handle
end

function Window:AddSection(name)
    self.Sections = self.Sections + 1
    local first = self.Sections == 1
    local top = first and 0 or 10
    local holder = New("Frame", { Size = UDim2.new(1, 0, 0, first and 26 or 36), BackgroundTransparency = 1, LayoutOrder = self:_next(), Parent = self.TabList })
    local w = TextService:GetTextSize(name, 12, Fonts.Medium, Vector2.new(300, 20)).X
    Label({ Text = name, TextSize = 12, TextColor3 = Theme.SubText, Position = UDim2.fromOffset(6, top), Size = UDim2.new(0, w + 4, 1, -top), Parent = holder })
    if self.Sections > 1 then
        New("Frame", {
            Position = UDim2.new(0, w + 16, 0.5, top / 2), Size = UDim2.new(1, -(w + 22), 0, 1),
            BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = holder,
        })
    end
end

function Window:AddTab(o)
    local tab = setmetatable({ Window = self, Name = o.Name }, Tab)

    tab.Button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = Theme.CardHeader, BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, LayoutOrder = self:_next(), Parent = self.TabList,
    }, { Corner(7) })
    tab.Highlight = New("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = tab.Button,
    }, {
        Corner(7),
        New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.78) }) }),
        Stroke(Theme.AccentLight, 1, 1),
    })
    tab.HStroke = tab.Highlight:FindFirstChildOfClass("UIStroke")
    tab.Bar = New("Frame", {
        Size = UDim2.new(0, 3, 0.2, 0), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Theme.AccentLight, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = tab.Highlight,
    }, { Corner(2) })
    tab.Label = Label({ Text = o.Name, Font = Fonts.Medium, TextSize = 14, Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -22, 1, 0), ZIndex = 3, Parent = tab.Button })

    self:_connect(tab.Button.MouseEnter, function()
        if self.Current ~= tab then Tween(tab.Button, { BackgroundTransparency = 0.6 }) end
    end)
    self:_connect(tab.Button.MouseLeave, function() Tween(tab.Button, { BackgroundTransparency = 1 }) end)
    self:_connect(tab.Button.MouseButton1Click, function() self:SelectTab(tab) end)

    tab.Group = New("CanvasGroup", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        GroupTransparency = 0, Visible = false, Parent = self.Content,
    })
    tab.Page = New("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
        Parent = tab.Group,
    })
    -- padding lives on a plain Frame (a ScrollingFrame ignores right padding for scale-sized children)
    local wrapper = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = tab.Page,
    }, { Pad(GAP, GAP, GAP, GAP) })
    local container = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = wrapper,
    }, { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, GAP), SortOrder = Enum.SortOrder.LayoutOrder }) })
    tab.Columns = {}
    for i = 1, 2 do
        tab.Columns[i] = New("Frame", {
            Size = UDim2.new(0.5, -GAP / 2, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
            LayoutOrder = i, Parent = container,
        }, { New("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }) })
    end
    tab.Order = 0

    -- close dropdown/popup when this tab scrolls (prevents floating misalignment)
    self:_connect(tab.Page:GetPropertyChangedSignal("CanvasPosition"), function()
        if self.CloseDropdown then self.CloseDropdown() end
        if self.ClosePopup then self.ClosePopup() end
    end)

    table.insert(self.Tabs, tab)
    if not self.Current then self:SelectTab(tab, true) end
    return tab
end

local function SetTabActive(tab, on, instant)
    if not tab then return end
    local goals = {
        { tab.Highlight, { BackgroundTransparency = on and 0 or 1 } },
        { tab.HStroke,   { Transparency = on and 0.35 or 1 } },
        { tab.Bar,       { BackgroundTransparency = on and 0 or 1, Size = UDim2.new(0, 3, on and 0.56 or 0.2, 0) } },
        { tab.Label,     { Position = UDim2.fromOffset(on and 20 or 16, 0) } },
    }
    for _, g in ipairs(goals) do
        if instant then
            for k, v in pairs(g[2]) do g[1][k] = v end
        else
            Tween(g[1], g[2], 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end
end

function Window:SelectTab(tab, instant)
    if self.Current == tab then return end
    if self.CloseDropdown then self.CloseDropdown() end
    if self.ClosePopup then self.ClosePopup() end
    local old = self.Current
    self.Current = tab

    SetTabActive(old, false, instant)
    SetTabActive(tab, true, instant)
    tab.Button.BackgroundTransparency = 1

    -- old page: quick fade out, then hide (unless the user switched back to it meanwhile)
    if old then
        if instant then
            old.Group.Visible = false
        else
            local t = Tween(old.Group, { GroupTransparency = 1 }, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            t.Completed:Connect(function(state)
                if state == Enum.PlaybackState.Completed and self.Current ~= old then old.Group.Visible = false end
            end)
        end
    end

    -- new page: fade in + slide up slightly
    tab.Group.Visible = true
    if instant then
        tab.Group.GroupTransparency = 0
        tab.Group.Position = UDim2.fromOffset(0, 0)
    else
        tab.Group.GroupTransparency = 1
        tab.Group.Position = UDim2.fromOffset(0, 14)
        TweenService:Create(tab.Group,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.07),
            { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }):Play()
    end
end

function Window:SaveConfig(name)
    name = SanitizeConfigName(name)
    local data = {}
    for flag, obj in pairs(self.Flags) do
        -- keybind with mode: save key + mode together
        if type(obj.Mode) == "string" and type(obj.GetMode) == "function" then
            local ok, v = pcall(function() return obj:Get() end)
            if ok then
                local keyStr = (typeof(v) == "EnumItem") and (v.EnumType.Name .. "." .. v.Name) or nil
                data[flag] = { __keybind = { key = keyStr, mode = obj:GetMode() } }
            end
        else
            local ok, v = pcall(function() return obj:Get() end)
            if ok then
                if typeof(v) == "EnumItem" then
                    data[flag] = { __enum = v.EnumType.Name .. "." .. v.Name }
                elseif typeof(v) == "Color3" then
                    data[flag] = { __color = { math.floor(v.R * 255 + 0.5), math.floor(v.G * 255 + 0.5), math.floor(v.B * 255 + 0.5) } }
                else
                    data[flag] = v
                end
            end
        end
    end
    local okEnc, json = pcall(HttpService.JSONEncode, HttpService, data)
    if not okEnc then return false end
    if writefile == nil then return false end
    return pcall(function() writefile(name .. ".json", json) end)
end

function Window:ListConfigs()
    if listfiles == nil then return {} end
    local ok, files = pcall(listfiles, "")
    if not ok or type(files) ~= "table" then return {} end
    local out = {}
    for _, f in ipairs(files) do
        local base = string.match(tostring(f), "([^\\/]+)%.json$")
        if base then table.insert(out, base) end
    end
    table.sort(out)
    return out
end

function Window:DeleteConfig(name)
    name = SanitizeConfigName(name)
    if delfile == nil then return false end
    return pcall(function() delfile(name .. ".json") end)
end

function Window:LoadConfig(name)
    name = SanitizeConfigName(name)
    local ok, raw = pcall(readfile, name .. ".json")
    if not ok then return false end
    local okDecode, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not okDecode or type(data) ~= "table" then return false end
    for flag, v in pairs(data) do
        local obj = self.Flags[flag]
        if obj and obj.Set then
            if type(v) == "table" and v.__keybind then
                local kb = v.__keybind
                if kb.key then
                    local enumType, enumName = string.match(kb.key, "^(%w+)%.(%w+)$")
                    if enumType and Enum[enumType] and enumName then
                        pcall(function() obj:Set(Enum[enumType][enumName], true) end)
                    end
                else
                    pcall(function() obj:Set(nil, true) end)
                end
                if kb.mode and type(obj.SetMode) == "function" then
                    pcall(function() obj:SetMode(kb.mode, true) end)
                end
            elseif type(v) == "table" and v.__enum then
                local enumType, enumName = string.match(v.__enum, "^(%w+)%.(%w+)$")
                if enumType and Enum[enumType] and enumName then
                    pcall(function() obj:Set(Enum[enumType][enumName], true) end)
                end
            elseif type(v) == "table" and v.__color then
                local c = v.__color
                pcall(function() obj:Set(Color3.fromRGB(c[1] or 0, c[2] or 0, c[3] or 0), true) end)
            elseif type(v) == "string" and typeof(obj:Get()) == "EnumItem" then
                pcall(function() obj:Set(Enum.KeyCode[v], true) end)
            else
                pcall(function() obj:Set(v, true) end)
            end
        end
    end
    return true
end

-- Auto-save all flags (debounced + every 10s backup). Call AFTER creating all UI.
-- opts: { AutoLoad = true } to load on enable (default true for backward-compat)
function Window:EnableAutoSave(name, opts)
    name = SanitizeConfigName(name)
    opts = opts or {}
    local autoLoad = opts.AutoLoad
    if autoLoad == nil then autoLoad = true end
    self:DisableAutoSave()
    self._autoSaveToken = (self._autoSaveToken or 0) + 1
    local myToken = self._autoSaveToken
    self._autoSaveName = name
    if autoLoad and readfile ~= nil then self:LoadConfig(name) end
    self._autoSaveTimer = nil
    local function schedule()
        if self._autoSaveTimer then return end
        self._autoSaveTimer = true
        task.delay(1, function()
            self._autoSaveTimer = nil
            if self._autoSaveToken == myToken and self._autoSaveName then
                pcall(function() self:SaveConfig(name) end)
            end
        end)
    end
    for _, obj in pairs(self.Flags) do
        if not obj._autoHooked then
            obj._autoHooked = true
            local origSet = obj.Set
            -- supports both obj:Set(v) and obj.Set(v) call styles
            obj.Set = function(a, b, c)
                if rawequal(a, obj) then
                    local r = origSet(a, b, c)
                    if not c then schedule() end
                    return r
                else
                    local r = origSet(obj, a, b)
                    if not b then schedule() end
                    return r
                end
            end
            -- keybind mode changes should also trigger autosave
            if type(obj.SetMode) == "function" then
                local origMode = obj.SetMode
                obj.SetMode = function(a, b, c)
                    local selfObj, m, sil
                    if rawequal(a, obj) then selfObj, m, sil = a, b, c
                    else selfObj, m, sil = obj, a, b end
                    local r = origMode(selfObj, m, sil)
                    if not sil then schedule() end
                    return r
                end
            end
        end
    end
    task.spawn(function()
        while self._autoSaveToken == myToken and self._autoSaveName == name do
            task.wait(10)
            if self._autoSaveToken == myToken and self._autoSaveName == name then
                pcall(function() self:SaveConfig(name) end)
            end
        end
    end)
end

function Window:DisableAutoSave()
    self._autoSaveToken = (self._autoSaveToken or 0) + 1
    self._autoSaveName = nil
    self._autoSaveTimer = nil
end

---------------------------------------------------------------- card
function Tab:AddCard(o)
    o = o or {}
    local colIdx = math.clamp(math.floor(tonumber(o.Column) or 1), 1, 2)
    local col = self.Columns[colIdx]
    self.Order = self.Order + 1
    local card = setmetatable({ Window = self.Window, Order = 0 }, Card)

    card.Frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = self.Order, Parent = col,
    }, { Corner(8), Stroke(Theme.Stroke, 1), New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })

    -- Header: ClipsDescendants does NOT follow UICorner, so a square header pokes out of the rounded card.
    -- Fix: header background has its own rounded corners; a square "fill" covers the bottom half
    -- (only once the card has a body), so the header is rounded on top and flat where it meets the body.
    local headerGradient = function()
        return New("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(32, 23, 62), Color3.fromRGB(22, 16, 43)) })
    end
    local header = New("Frame", {
        Size = UDim2.new(1, 0, 0, 49), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 1, Parent = card.Frame,
    }, {
        New("Frame", { Name = "HeaderBg", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 },
            { Corner(8), headerGradient() }),
    })
    card.HeaderFill = New("Frame", {
        Name = "HeaderFill", Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.fromScale(0, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Visible = false, Parent = header,
    }, {
        headerGradient(),
        New("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0 }),
    })
    Label({ Text = o.Title, Font = Fonts.Bold, TextSize = 16, Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -58, 0, 20), TextTruncate = Enum.TextTruncate.AtEnd, Parent = header })
    Label({ Text = o.Subtitle or "", TextSize = 11, TextColor3 = Theme.SubText, Position = UDim2.fromOffset(14, 27), Size = UDim2.new(1, -58, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, Parent = header })

    if o.Toggle ~= false then
        card.Switch = Switch(header, o.Default, o.Callback)
        if o.Flag then self.Window.Flags[o.Flag] = card.Switch end
    end

    card.Body = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        Visible = false, LayoutOrder = 2, Parent = card.Frame,
    }, { New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }), Pad(7, 8, 7, 8) })

    return card
end

function Card:_showBody()
    self.Body.Visible = true
    self.HeaderFill.Visible = true
end

function Card:_row(height, accentBar)
    self:_showBody()
    self.Order = self.Order + 1
    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Theme.Row, BorderSizePixel = 0,
        LayoutOrder = self.Order, Parent = self.Body,
    }, { Corner(6), Stroke(Theme.Stroke, 1, 0.65) })
    if accentBar ~= false then
        New("Frame", {
            Size = UDim2.new(0, 2, 0.6, 0), Position = UDim2.new(0, 0, 0.2, 0),
            BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = row,
        }, { Corner(1) })
    end
    return row
end

function Card:AddToggle(o)
    local row = self:_row(28)
    Label({ Text = o.Name, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -64, 1, 0), Parent = row })
    local obj = Switch(row, o.Default, o.Callback)
    if o.Flag then self.Window.Flags[o.Flag] = obj end
    return obj
end

function Card:AddCheckbox(o)
    local row = self:_row(28)
    Label({ Text = o.Name, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -50, 1, 0), Parent = row })
    local box = New("TextButton", {
        Size = UDim2.fromOffset(17, 17), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        BackgroundColor3 = Theme.Window, Text = "", AutoButtonColor = false, Parent = row,
    }, { Corner(4) })
    local stroke = Stroke(Theme.Muted, 1, 0.45)
    stroke.Parent = box
    local mark = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = box })
    local white = Color3.new(1, 1, 1)
    Bar(mark, 5, 2, UDim2.fromOffset(5.5, 10), 45, white)
    Bar(mark, 10, 2, UDim2.fromOffset(10, 8.5), -45, white)

    local obj = { Value = false }
    function obj:Set(v, silent)
        v = v and true or false
        self.Value = v
        Tween(box, { BackgroundColor3 = v and Theme.Accent or Theme.Window })
        Tween(stroke, { Color = v and Theme.AccentLight or Theme.Muted })
        mark.Visible = v
        if not silent and o.Callback then task.spawn(o.Callback, v) end
    end
    function obj:Get() return self.Value end
    box.MouseButton1Click:Connect(function() obj:Set(not obj.Value) end)
    if o.Default then obj:Set(true, true) end
    if o.Flag then self.Window.Flags[o.Flag] = obj end
    return obj
end

function Card:AddDropdown(o)
    local window = self.Window
    local options = o.Options or {}
    local isMulti = o.Multi == true
    local row = self:_row(29)
    Label({ Text = o.Name, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.4, 0, 1, 0), Parent = row })

    local box = New("TextButton", {
        Size = UDim2.new(0.6, 0, 0, 24), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = Theme.Window, Text = "", AutoButtonColor = false, Parent = row,
    }, { Corner(5), Stroke(Theme.Stroke, 1) })
    local valLbl = Label({ Text = "", TextSize = 13, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -30, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = box })
    Chevron(box, UDim2.new(1, -13, 0.5, -1), Theme.AccentLight)

    local list = New("ScrollingFrame", {
        Visible = false, BackgroundColor3 = Theme.CardHeader, BorderSizePixel = 0, ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
        ZIndex = 60, Parent = window.Gui,
    }, { Corner(6), Stroke(Theme.Accent, 1, 0.5), New("UIListLayout", { Padding = UDim.new(0, 2) }), Pad(4, 4, 4, 4) })

    local obj = { Multi = isMulti, Value = isMulti and {} or (o.Default or options[1]) }
    if isMulti and type(o.Default) == "table" then obj.Value = table.clone(o.Default) end
    local itemRows = {}

    local function renderLabel()
        if not isMulti then
            if obj.Value == nil or (#options > 0 and table.find(options, obj.Value) == nil and #options == 0) then
                valLbl.Text = (#options == 0) and "No options" or tostring(obj.Value or "")
            else
                valLbl.Text = tostring(obj.Value or "")
            end
            if #options == 0 then valLbl.Text = "No options" end
        else
            if #obj.Value == 0 then valLbl.Text = (#options == 0) and "No options" or "None"
            elseif #obj.Value <= 2 then valLbl.Text = table.concat(obj.Value, ", ")
            else valLbl.Text = string.format("%d selected", #obj.Value) end
        end
    end
    local function paintItems()
        for _, row in ipairs(itemRows) do
            local opt, b = row.opt, row.btn
            if b and b.Parent then
                local selected = isMulti and table.find(obj.Value, opt) ~= nil or (not isMulti and obj.Value == opt)
                b.BackgroundTransparency = selected and 0.6 or 1
            end
        end
    end
    renderLabel()

    local function close()
        list.Visible = false
        window.Blocker.Visible = false
        if window.CloseDropdown == close then window.CloseDropdown = nil end
        if window.ClosePopup == close then window.ClosePopup = nil end
    end
    local function open()
        if window.CloseDropdown then window.CloseDropdown() end
        if window.ClosePopup then window.ClosePopup() end
        local ap, as = box.AbsolutePosition, box.AbsoluteSize
        local cam = workspace.CurrentCamera
        local vs = cam and cam.ViewportSize or Vector2.new(1280, 800)
        local h = (#options == 0) and 32 or math.min(#options * 26 + 8, 140)
        local x = math.max(math.min(ap.X, vs.X - as.X - 10), 10)
        local y = ap.Y + as.Y + 4
        y = math.max(10, math.min(y, vs.Y - h - 10))
        list.Position = UDim2.fromOffset(x, y)
        list.Size = UDim2.fromOffset(as.X, h)
        list.Visible = true
        window.Blocker.Visible = true
        window.CloseDropdown = close
        window.ClosePopup = close
    end

    function obj:Set(v, silent)
        if isMulti then self.Value = type(v) == "table" and table.clone(v) or {}
        else self.Value = v end
        renderLabel()
        paintItems()
        if not silent and o.Callback then task.spawn(o.Callback, self:Get()) end
    end
    function obj:Get()
        if isMulti then return table.clone(self.Value) end
        return self.Value
    end
    function obj:Refresh(newOptions)
        options = newOptions or {}
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        table.clear(itemRows)
        if isMulti then
            local kept = {}
            for _, v in ipairs(self.Value) do
                if table.find(options, v) then table.insert(kept, v) end
            end
            self.Value = kept
        else
            if table.find(options, self.Value) == nil then self.Value = options[1] end
        end
        renderLabel()
        if #options == 0 then
            local empty = New("TextLabel", {
                Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1,
                Text = "No options", Font = Fonts.Medium, TextSize = 12, TextColor3 = Theme.Muted,
                ZIndex = 61, Parent = list,
            })
            table.insert(itemRows, { opt = nil, btn = empty })
        end
        for _, opt in ipairs(options) do
            local b = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1,
                Text = tostring(opt), Font = Fonts.Medium, TextSize = 13, TextColor3 = Theme.Text,
                AutoButtonColor = false, ZIndex = 61, Parent = list,
            }, { Corner(4) })
            table.insert(itemRows, { opt = opt, btn = b })
            b.MouseEnter:Connect(function() if b.BackgroundTransparency == 1 then Tween(b, { BackgroundTransparency = 0.85 }, 0.1) end end)
            b.MouseLeave:Connect(function() paintItems() end)
            b.MouseButton1Click:Connect(function()
                if isMulti then
                    local idx = table.find(obj.Value, opt)
                    if idx then table.remove(obj.Value, idx) else table.insert(obj.Value, opt) end
                    renderLabel()
                    paintItems()
                    if o.Callback then task.spawn(o.Callback, obj:Get()) end
                else
                    obj:Set(opt)
                    close()
                end
            end)
        end
        paintItems()
    end
    obj:Refresh(options)

    box.MouseButton1Click:Connect(function()
        if list.Visible then close() else open() end
    end)
    if o.Flag then window.Flags[o.Flag] = obj end
    return obj
end

function Card:AddSlider(o)
    local min, max, inc = o.Min or 0, o.Max or 100, o.Increment or 1
    local suffix = o.Suffix and (" " .. o.Suffix) or ""
    local row = self:_row(36)
    Label({ Text = o.Name, Position = UDim2.fromOffset(12, 2), Size = UDim2.new(0.55, 0, 0, 16), Parent = row })
    local valLbl = Label({ Text = "", TextSize = 12, TextColor3 = Theme.Value, TextXAlignment = Right,
        Position = UDim2.new(0.45, -10, 0, 2), Size = UDim2.new(0.55, 0, 0, 16), Parent = row })

    local bar = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 16), Parent = row })
    local function StepBtn(text, pos)
        return New("TextButton", {
            Text = text, Font = Fonts.Bold, TextSize = 15, TextColor3 = Theme.AccentLight, BackgroundTransparency = 1,
            Size = UDim2.fromOffset(20, 16), Position = pos, AutoButtonColor = false, Parent = bar,
        })
    end
    local minus = StepBtn("-", UDim2.fromOffset(8, 0))
    local plus = StepBtn("+", UDim2.new(1, -28, 0, 0))

    local track = New("Frame", {
        Size = UDim2.new(1, -72, 0, 6), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 36, 0.5, 0),
        BackgroundColor3 = Theme.Off, BorderSizePixel = 0, Parent = bar,
    }, { Corner(3) })
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track },
        { Corner(3), New("UIGradient", { Color = ColorSequence.new(Theme.AccentDark, Theme.AccentLight) }) })
    local handle = New("Frame", {
        Size = UDim2.fromOffset(12, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
        BackgroundColor3 = Color3.fromRGB(196, 176, 255), BorderSizePixel = 0, Parent = track,
    }, { Corner(4), Stroke(Theme.AccentLight, 1, 0.3) })
    for dx = -2, 2, 2 do
        New("Frame", {
            Size = UDim2.fromOffset(1, 7), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, dx, 0.5, 0),
            BackgroundColor3 = Theme.AccentDark, BorderSizePixel = 0, Parent = handle,
        })
    end

    local obj = { Value = min }
    function obj:Set(v, silent)
        v = math.clamp(math.floor((v - min) / inc + 0.5) * inc + min, min, max)
        local changed = v ~= self.Value
        self.Value = v
        local ratio = (max == min) and 0 or (v - min) / (max - min)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        handle.Position = UDim2.new(ratio, 0, 0.5, 0)
        valLbl.Text = tostring(v) .. suffix
        if changed and not silent and o.Callback then task.spawn(o.Callback, v) end
    end
    function obj:Get() return self.Value end

    local dragging = false
    local function fromX(x)
        local r = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        obj:Set(min + (max - min) * r)
    end
    local hit = New("TextButton", {
        BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 0, 20), AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5), Parent = track,
    })
    hit.InputBegan:Connect(function(i)
        if IsPress(i) then dragging = true; fromX(i.Position.X) end
    end)
    self.Window:_connect(UserInputService.InputChanged, function(i)
        if dragging and IsMove(i) then fromX(i.Position.X) end
    end)
    self.Window:_connect(UserInputService.InputEnded, function(i)
        if IsPress(i) then dragging = false end
    end)
    minus.MouseButton1Click:Connect(function() obj:Set(obj.Value - inc) end)
    plus.MouseButton1Click:Connect(function() obj:Set(obj.Value + inc) end)

    obj:Set(o.Default or min, true)
    if o.Flag then self.Window.Flags[o.Flag] = obj end
    return obj
end

function Card:AddLabel(textOrOpts)
    -- compat: AddLabel("hello") or AddLabel({ Text = "hello" })
    local text = type(textOrOpts) == "table" and (textOrOpts.Text or "") or tostring(textOrOpts or "")
    self:_showBody()
    self.Order = self.Order + 1
    local lbl = Label({
        Text = text, TextSize = 12, TextColor3 = Theme.Para, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = self.Order, Parent = self.Body,
    })
    Pad(2, 6, 3, 6).Parent = lbl
    local obj = {}
    function obj:Set(t) lbl.Text = type(t) == "table" and (t.Text or "") or tostring(t) end
    function obj:Get() return lbl.Text end
    return obj
end

Card.AddParagraph = Card.AddLabel

function Card:AddDivider(text)
    self:_showBody()
    self.Order = self.Order + 1
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, text and 18 or 10), BackgroundTransparency = 1,
        LayoutOrder = self.Order, Parent = self.Body,
    })
    New("Frame", {
        Size = UDim2.new(1, 0, 0, 1), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
        BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = holder,
    })
    if text then
        local pill = Label({ Text = tostring(text), TextSize = 11, TextColor3 = Theme.SubText, TextXAlignment = Center,
            Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Theme.Card,
            BorderSizePixel = 0, Parent = holder })
        pill.AnchorPoint = Vector2.new(0.5, 0.5)
        pill.Position = UDim2.fromScale(0.5, 0.5)
        Pad(0, 8, 0, 8).Parent = pill
    end
end

function Card:AddInfo(o)
    local row = self:_row(28, false)
    local lbl = Label({ RichText = true, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -20, 1, 0), Parent = row })
    local obj = {}
    function obj:Set(value)
        lbl.Text = string.format('%s <font color="rgb(167,110,255)">%s</font>', o.Text or "", tostring(value))
    end
    obj:Set(o.Value or "")
    return obj
end

function Card:AddButton(o)
    self:_showBody()
    self.Order = self.Order + 1
    local b = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Accent, Text = o.Name, Font = Fonts.Bold,
        TextSize = 13, TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = false, LayoutOrder = self.Order, Parent = self.Body,
    }, { Corner(6) })
    b.MouseEnter:Connect(function() Tween(b, { BackgroundColor3 = Theme.AccentLight }) end)
    b.MouseLeave:Connect(function() Tween(b, { BackgroundColor3 = Theme.Accent }) end)
    b.MouseButton1Click:Connect(function()
        if o.Callback then task.spawn(o.Callback) end
    end)
    local obj = {}
    function obj:Set(t) b.Text = tostring(t) end
    function obj:Get() return b.Text end
    function obj:Click() if o.Callback then task.spawn(o.Callback) end end
    return obj
end

function Card:AddTextbox(o)
    o = o or {}
    local row = self:_row(29)
    Label({ Text = o.Name or "Input", Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.4, 0, 1, 0),
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = row })
    local box = New("TextBox", {
        Size = UDim2.new(0.6, 0, 0, 24), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
        BackgroundColor3 = Theme.Window, Text = tostring(o.Default or ""), PlaceholderText = o.Placeholder or "",
        Font = Fonts.Medium, TextSize = 13, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Muted,
        TextXAlignment = Left, ClearTextOnFocus = false, Parent = row,
    }, { Corner(5), Stroke(Theme.Stroke, 1) })
    local obj = { Value = tostring(o.Default or "") }
    function obj:Set(v, silent)
        self.Value = tostring(v)
        box.Text = self.Value
        if not silent and o.Callback then task.spawn(o.Callback, self.Value) end
    end
    function obj:Get() return self.Value end
    box.FocusLost:Connect(function(enter)
        obj.Value = box.Text
        if o.Callback and (enter or not o.EnterOnly) then task.spawn(o.Callback, obj.Value) end
    end)
    if o.Flag then self.Window.Flags[o.Flag] = obj end
    return obj
end

function Card:AddKeybind(o)
    o = o or {}
    local row = self:_row(28)
    Label({ Text = o.Name or "Keybind", Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -130, 1, 0), Parent = row })
    local modeBtn = New("TextButton", {
        Size = UDim2.fromOffset(48, 20), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -78, 0.5, 0),
        BackgroundColor3 = Theme.Window, Text = o.Mode or "Toggle",
        Font = Fonts.Medium, TextSize = 11, TextColor3 = Theme.SubText, AutoButtonColor = false, Parent = row,
    }, { Corner(5), Stroke(Theme.Stroke, 1) })
    local keyBtn = New("TextButton", {
        Size = UDim2.fromOffset(60, 20), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
        BackgroundColor3 = Theme.Window, Text = (o.Default and o.Default.Name) or "None",
        Font = Fonts.Medium, TextSize = 12, TextColor3 = Theme.AccentLight, AutoButtonColor = false, Parent = row,
    }, { Corner(5), Stroke(Theme.Stroke, 1) })
    local modes = { "Toggle", "Hold", "Always" }
    local obj = { Value = o.Default, Mode = o.Mode or "Toggle", State = false, Listening = false }
    if table.find(modes, obj.Mode) == nil then obj.Mode = "Toggle" end
    modeBtn.Text = obj.Mode
    function obj:Set(v, silent)
        self.Value = v
        keyBtn.Text = (v and v.Name) or "None"
        if self.Mode == "Always" and v ~= nil then
            self.State = true
            if not silent and o.Callback then task.spawn(o.Callback, v, true) end
        elseif not silent and o.Callback and v ~= nil and self.Mode == "Toggle" then
            -- keep backward-compat: single press fires with key; state available as 2nd arg
        end
        if not silent and o.Callback and self.Mode ~= "Hold" and self.Mode ~= "Always" and v == nil then
            task.spawn(o.Callback, v, self.State)
        end
    end
    function obj:Get() return self.Value end
    function obj:GetMode() return self.Mode end
    function obj:GetState() return self.State end
    function obj:SetMode(m, silent)
        if table.find(modes, m) == nil then return end
        self.Mode = m
        modeBtn.Text = m
        if m == "Always" then
            self.State = true
            if not silent and o.Callback and self.Value ~= nil then
                task.spawn(o.Callback, self.Value, true)
            end
        elseif m == "Toggle" or m == "Hold" then
            self.State = false
        end
    end
    keyBtn.MouseButton1Click:Connect(function()
        obj.Listening = true
        keyBtn.Text = "..."
    end)
    modeBtn.MouseButton1Click:Connect(function()
        local idx = table.find(modes, obj.Mode) or 1
        obj:SetMode(modes[(idx % #modes) + 1])
    end)
    self.Window:_connect(UserInputService.InputBegan, function(i, gp)
        if obj.Listening and not gp and i.KeyCode ~= Enum.KeyCode.Unknown then
            -- Escape cancels listening instead of binding; RightControl conflict guard
            if i.KeyCode == Enum.KeyCode.Escape then
                obj.Listening = false
                keyBtn.Text = (obj.Value and obj.Value.Name) or "None"
                return
            end
            obj.Listening = false
            keyBtn.Text = i.KeyCode.Name
            obj.Value = i.KeyCode
            if obj.Mode == "Always" then
                obj.State = true
                if o.Callback then task.spawn(o.Callback, obj.Value, true) end
            elseif obj.Mode == "Hold" then
                obj.State = true
                if o.Callback then task.spawn(o.Callback, obj.Value, true) end
            else -- Toggle
                obj.State = not obj.State
                if o.Callback then task.spawn(o.Callback, obj.Value, obj.State) end
            end
            return
        end
        if not obj.Listening and obj.Value and i.KeyCode == obj.Value and not gp then
            if obj.Mode == "Hold" then
                obj.State = true
                if o.Callback then task.spawn(o.Callback, obj.Value, true) end
            elseif obj.Mode == "Always" then
                if o.Callback then task.spawn(o.Callback, obj.Value, true) end
            else
                obj.State = not obj.State
                if o.Callback then task.spawn(o.Callback, obj.Value, obj.State) end
            end
        end
    end)
    self.Window:_connect(UserInputService.InputEnded, function(i)
        if obj.Mode == "Hold" and obj.Value and i.KeyCode == obj.Value then
            if obj.State then
                obj.State = false
                if o.Callback then task.spawn(o.Callback, obj.Value, false) end
            end
        end
    end)
    if o.Flag then self.Window.Flags[o.Flag] = obj end
    return obj
end

function Card:AddColorPicker(o)
    o = o or {}
    local window = self.Window
    local row = self:_row(28)
    Label({ Text = o.Name or "Color", Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -70, 1, 0), Parent = row })
    local preview = New("TextButton", {
        Size = UDim2.fromOffset(46, 20), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
        BackgroundColor3 = o.Default or Color3.fromRGB(124, 58, 237), Text = "", AutoButtonColor = false, Parent = row,
    }, { Corner(5), Stroke(Theme.AccentLight, 1, 0.2) })

    local popup = New("Frame", {
        Visible = false, Size = UDim2.fromOffset(210, 196), BackgroundColor3 = Theme.CardHeader,
        BorderSizePixel = 0, ZIndex = 60, Parent = window.Gui,
    }, { Corner(8), Stroke(Theme.Accent, 1, 0.4), Pad(10, 10, 10, 10),
        New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })

    local topRow = New("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, LayoutOrder = 1, Parent = popup })
    local big = New("Frame", { Size = UDim2.fromOffset(36, 36), BackgroundColor3 = preview.BackgroundColor3, Parent = topRow }, { Corner(6), Stroke(Theme.Stroke, 1) })
    local hexBox = New("TextBox", {
        Size = UDim2.new(1, -44, 0, 24), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 6),
        BackgroundColor3 = Theme.Window, Text = "", PlaceholderText = "#7C3AED",
        Font = Fonts.Medium, TextSize = 12, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Muted,
        ClearTextOnFocus = false, Parent = topRow,
    }, { Corner(5), Stroke(Theme.Stroke, 1) })

    local slidersBox = New("Frame", { Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1, LayoutOrder = 2, Parent = popup },
        { New("UIListLayout", { Padding = UDim.new(0, 4) }) })
    local rgbBoxes = {}
    for _, ch in ipairs({ "R", "G", "B" }) do
        local r = New("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Parent = slidersBox })
        Label({ Text = ch, TextSize = 12, TextColor3 = Theme.Muted, Size = UDim2.new(0, 14, 1, 0), Parent = r })
        local tb = New("TextBox", {
            Size = UDim2.new(1, -18, 1, 0), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = Theme.Window, Text = "0", Font = Fonts.Medium, TextSize = 12,
            TextColor3 = Theme.Text, ClearTextOnFocus = false, Parent = r,
        }, { Corner(4), Stroke(Theme.Stroke, 1) })
        rgbBoxes[ch] = tb
    end

    local grid = New("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = 3, Parent = popup },
        { New("UIGridLayout", { CellSize = UDim2.fromOffset(24, 24), CellPadding = UDim2.fromOffset(6, 6) }) })
    local presets = {
        Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(255, 165, 0), Color3.fromRGB(255, 255, 0), Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 200, 255), Color3.fromRGB(0, 120, 255), Color3.fromRGB(124, 58, 237),
        Color3.fromRGB(255, 0, 200), Color3.fromRGB(120, 120, 120), Color3.fromRGB(101, 67, 33),
    }

    local obj = { Value = o.Default or Color3.fromRGB(124, 58, 237) }
    local function toHex(c)
        return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
    end
    local function paint()
        preview.BackgroundColor3 = obj.Value
        big.BackgroundColor3 = obj.Value
        rgbBoxes.R.Text = tostring(math.floor(obj.Value.R * 255 + 0.5))
        rgbBoxes.G.Text = tostring(math.floor(obj.Value.G * 255 + 0.5))
        rgbBoxes.B.Text = tostring(math.floor(obj.Value.B * 255 + 0.5))
        hexBox.Text = toHex(obj.Value)
    end
    function obj:Set(v, silent)
        if typeof(v) == "Color3" then
            obj.Value = v
            paint()
            if not silent and o.Callback then task.spawn(o.Callback, obj.Value) end
        elseif type(v) == "table" and v.R and v.G and v.B then
            obj:Set(Color3.new(v.R, v.G, v.B), silent)
        end
    end
    function obj:Get() return obj.Value end

    local function readRGB()
        local r = math.clamp(tonumber(rgbBoxes.R.Text) or 0, 0, 255)
        local g = math.clamp(tonumber(rgbBoxes.G.Text) or 0, 0, 255)
        local b = math.clamp(tonumber(rgbBoxes.B.Text) or 0, 0, 255)
        obj:Set(Color3.fromRGB(r, g, b))
    end
    for _, tb in pairs(rgbBoxes) do
        tb.FocusLost:Connect(function(enter) if enter then readRGB() end end)
    end
    hexBox.FocusLost:Connect(function(enter)
        if not enter then return end
        local h = hexBox.Text:gsub("#", "")
        if #h == 6 and h:match("^[0-9a-fA-F]+$") then
            obj:Set(Color3.fromRGB(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)))
        else
            paint()
        end
    end)
    for _, c in ipairs(presets) do
        local b = New("TextButton", { BackgroundColor3 = c, Text = "", AutoButtonColor = false, ZIndex = 61, Parent = grid }, { Corner(5), Stroke(Theme.Stroke, 1) })
        b.MouseButton1Click:Connect(function() obj:Set(c) end)
    end
    paint()

    local function close()
        popup.Visible = false
        window.Blocker.Visible = false
        if window.ClosePopup == close then window.ClosePopup = nil end
        if window.CloseDropdown == close then window.CloseDropdown = nil end
    end
    local function open()
        if window.CloseDropdown then window.CloseDropdown() end
        if window.ClosePopup then window.ClosePopup() end
        local ap, as = preview.AbsolutePosition, preview.AbsoluteSize
        local cam = workspace.CurrentCamera
        local vs = cam and cam.ViewportSize or Vector2.new(1280, 800)
        local pw, ph = 210, 196
        local x = math.min(ap.X - pw + as.X, vs.X - pw - 10)
        local y = ap.Y + as.Y + 4
        y = math.max(10, math.min(y, vs.Y - ph - 10))
        popup.Position = UDim2.fromOffset(math.max(x, 10), y)
        popup.Visible = true
        window.Blocker.Visible = true
        window.ClosePopup = close
        window.CloseDropdown = close
    end
    preview.MouseButton1Click:Connect(function()
        if popup.Visible then close() else open() end
    end)
    if o.Flag then window.Flags[o.Flag] = obj end
    return obj
end

-- Multi-config UI: textbox + Save/Load/Delete + dropdown list + autoload toggle.
-- o = { Default = "default", AutoLoad = true }
function Card:AddConfigBox(o)
    o = o or {}
    local window = self.Window
    local current = o.Default or "default"

    local nameBox = self:AddTextbox({ Name = "Config Name", Default = current, Placeholder = "my-config" })
    local list = self:AddDropdown({ Name = "Saved", Options = {}, Default = nil })
    local autoObj = self:AddToggle({ Name = "Autoload + Autosave", Default = o.AutoLoad ~= false })

    local function refreshList(select)
        local names = window:ListConfigs()
        if #names == 0 then names = { "(no configs)" } end
        list:Refresh(names)
        if select then
            if table.find(names, select) then list:Set(select, true)
            else list:Set(names[1], true) end
        end
        return names
    end
    refreshList(current)

    local function chosenName()
        local v = nameBox:Get()
        if v == nil or tostring(v) == "" then
            v = list:Get()
            if v == "(no configs)" then v = current end
        end
        return tostring(v)
    end

    self:AddButton({ Name = "Save", Callback = function()
        local n = chosenName()
        current = n
        window:SaveConfig(n)
        refreshList(n)
        window:Notify({ Title = "Config", Text = "Saved: " .. n })
    end })
    self:AddButton({ Name = "Load", Callback = function()
        local n = chosenName()
        current = n
        if window:LoadConfig(n) then
            refreshList(n)
            window:Notify({ Title = "Config", Text = "Loaded: " .. n })
        else
            window:Notify({ Title = "Config", Text = "Not found: " .. n })
        end
    end })
    self:AddButton({ Name = "Delete", Callback = function()
        local n = chosenName()
        window:DeleteConfig(n)
        refreshList()
        window:Notify({ Title = "Config", Text = "Deleted: " .. n })
    end })
    self:AddButton({ Name = "Enable Autosave", Callback = function()
        local n = chosenName()
        window:EnableAutoSave(n)
        window:Notify({ Title = "Config", Text = "Autosave on: " .. n })
    end })

    -- keep textbox in sync when picking from the list (no polling loop)
    do
        local origSet = list.Set
        list.Set = function(s, v, silent)
            local selfObj, val, sil
            if rawequal(s, list) then selfObj, val, sil = s, v, silent
            else selfObj, val, sil = list, s, v end
            local r = origSet(selfObj, val, sil)
            if val ~= nil and val ~= "(no configs)" then
                pcall(function() nameBox:Set(tostring(val), true) end)
                current = tostring(val)
            end
            return r
        end
    end
    -- autoload toggle: on -> EnableAutoSave(current), off -> DisableAutoSave()
    do
        local origSet = autoObj.Set
        autoObj.Set = function(s, v, silent)
            local selfObj, val, sil
            if rawequal(s, autoObj) then selfObj, val, sil = s, v, silent
            else selfObj, val, sil = autoObj, s, v end
            local r = origSet(selfObj, val, sil)
            if not sil then
                if val then window:EnableAutoSave(chosenName())
                else window:DisableAutoSave() end
            end
            return r
        end
    end

    if autoObj:Get() then
        window:EnableAutoSave(current, { AutoLoad = true })
    end
    return { NameBox = nameBox, List = list, Refresh = refreshList }
end

---------------------------------------------------------------- demo / example (call manually, no auto-run)
function Library:Demo()
    local Win = Library:CreateWindow({
        Title = "Volt",
        TitleAccent = "ScriptZ",
        Subtitle = "Premium Script Hub | Made for Roblox",
        User = { Name = "VoltScriptZ", Tag = "Premium User" },
        ToggleKey = Enum.KeyCode.RightControl,
        Logo = "rbxassetid://100712256015627",
    })

    Win:AddSection("General")
    local Farm = Win:AddTab({ Name = "Auto Farm" })
    Win:AddTab({ Name = "Auto Raids" })
    Win:AddTab({ Name = "Auto Party" })
    Win:AddTab({ Name = "Auto Sell" })
    Win:AddTab({ Name = "Auto Crates" })
    Win:AddTab({ Name = "Webhook" })

    Win:AddSection("Utilities")
    Win:AddTab({ Name = "Utilities" })
    Win:AddTab({ Name = "Servers" })
    local Settings = Win:AddTab({ Name = "Settings" })

    -- column 1
    local Combat = Farm:AddCard({ Title = "Combat", Subtitle = "Dungeon Farming", Column = 1, Default = true, Flag = "Combat" })
    Combat:AddToggle({ Name = "Auto Farm", Default = true, Flag = "AutoFarm", Callback = function(v) print("Auto Farm", v) end })
    Combat:AddToggle({ Name = "Auto Attack", Flag = "AutoAttack", Callback = function(v) print("Auto Attack", v) end })

    local Abilities = Farm:AddCard({ Title = "Abilities", Subtitle = "Skill automation", Column = 1, Default = true, Flag = "Abilities" })
    Abilities:AddLabel("This function will use Buff skill first before use another skill.")
    Abilities:AddToggle({ Name = "Auto Skills", Default = true, Flag = "AutoSkills" })
    Abilities:AddSlider({ Name = "Attack Range", Min = 5, Max = 100, Default = 35, Suffix = "Studs", Flag = "AttackRange", Callback = function(v) print("Range", v) end })
    Abilities:AddSlider({ Name = "Walk Speed", Min = 16, Max = 100, Default = 20, Suffix = "Studs", Flag = "WalkSpeed" })

    Farm:AddCard({ Title = "Auto Restart", Subtitle = "Restart game after seconds.", Column = 1, Default = true, Flag = "AutoRestart" })

    -- column 2
    local Launch = Farm:AddCard({ Title = "Launch", Subtitle = "Create a Dungeon", Column = 2, Default = true, Flag = "Launch" })
    Launch:AddCheckbox({ Name = "Auto Start", Flag = "AutoStart" })
    Launch:AddCheckbox({ Name = "Auto Select Best Dungeon", Flag = "AutoBest" })
    Launch:AddDropdown({ Name = "Dungeon", Options = { "Desert Temple", "Frozen Cave", "Lava Pit" }, Default = "Desert Temple", Flag = "Dungeon" })
    Launch:AddDropdown({ Name = "Difficulty", Options = { "Easy", "Medium", "Hard", "Insane" }, Default = "Easy", Flag = "Difficulty" })
    Launch:AddCheckbox({ Name = "Hardcore", Flag = "Hardcore" })

    local Loop = Farm:AddCard({ Title = "Loop", Subtitle = "Repeat dungeon runs", Column = 2, Default = true, Flag = "Loop" })
    Loop:AddInfo({ Text = "Current Replayed:", Value = "4 Times" })
    Loop:AddToggle({ Name = "Auto Replay", Default = true, Flag = "AutoReplay" })
    Loop:AddCheckbox({ Name = "Auto Back to Lobby", Flag = "AutoLobby" })
    Loop:AddSlider({ Name = "Back to Lobby After", Min = 1, Max = 20, Default = 5, Suffix = "Times", Flag = "LobbyAfter" })
    Loop:AddTextbox({ Name = "Webhook URL", Placeholder = "https://...", Flag = "WebhookURL" })
    Loop:AddKeybind({ Name = "Farm Key", Default = Enum.KeyCode.F, Mode = "Toggle", Flag = "FarmKey", Callback = function(key, state) print("Farm Key", key, state) end })
    Loop:AddKeybind({ Name = "Hold Key", Default = Enum.KeyCode.G, Mode = "Hold", Flag = "HoldKey", Callback = function(key, held) print("Hold", key, held) end })
    Loop:AddDivider("Appearance")
    Loop:AddColorPicker({ Name = "ESP Color", Default = Color3.fromRGB(255, 0, 0), Flag = "ESPColor" })
    Loop:AddDropdown({ Name = "Target Multi", Options = { "A", "B", "C", "D" }, Multi = true, Default = { "A", "C" }, Flag = "TargetMulti" })

    -- settings tab
    local Cfg = Settings:AddCard({ Title = "Config", Subtitle = "Save and load your settings", Column = 1, Toggle = false })
    Cfg:AddConfigBox({ Default = "VoltScriptZ", AutoLoad = false })
    Cfg:AddButton({ Name = "Test Notify", Callback = function() Win:Notify({ Title = "VoltScriptZ", Text = "Library v3.4 ready!" }) end })

    return Win
end

-- Uncomment to preview instantly when running this file directly:
-- Library:Demo()

return Library
