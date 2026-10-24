local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local HttpService        = game:GetService("HttpService")
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Stats              = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local DEFAULTS = {
    uiKey         = "RightControl",
    showMobileBtn = true,
    winPos        = "",
    apEnabled     = false,
    apMode        = "Remote",
    apCurve       = "Camera",
    apAccuracy    = 100,
    apAnim        = false,
    detInfinity   = false,
    detDeathSlash = false,
    detTimeHole   = false,
    detSoF        = false,
    apBtnPos      = "",
}
local CFG = {}
for k, v in pairs(DEFAULTS) do CFG[k] = v end
local SAVE = {}
local function reg(key, get, set) SAVE[key] = { get = get, set = set } end
local CONFIG_PATH = "NoirBladeBall/menu.json"
local function loadConfig()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then return end
    local ok, exists = pcall(isfile, CONFIG_PATH)
    if not ok or not exists then return end
    local rok, raw = pcall(readfile, CONFIG_PATH)
    if not rok or type(raw) ~= "string" then return end
    local dok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not dok or type(data) ~= "table" then return end
    for key, entry in pairs(SAVE) do
        local v = data[key]
        if v ~= nil and type(v) == type(entry.get()) then pcall(entry.set, v) end
    end
end
local saveQueued = false
local function saveConfig()
    if saveQueued then return end
    saveQueued = true
    task.delay(0.5, function()
        saveQueued = false
        if type(writefile) ~= "function" then return end
        if type(makefolder) == "function" and type(isfolder) == "function" then
            local okf, ex = pcall(isfolder, "NoirBladeBall")
            if okf and not ex then pcall(makefolder, "NoirBladeBall") end
        end
        local out = {}
        for key, entry in pairs(SAVE) do
            local ok, v = pcall(entry.get)
            if ok then out[key] = v end
        end
        pcall(function() writefile(CONFIG_PATH, HttpService:JSONEncode(out)) end)
    end)
end
local function setCfg(key, value)
    CFG[key] = value
    saveConfig()
end
local C = {
    base = Color3.fromRGB(10, 9, 8), surface = Color3.fromRGB(15, 13, 11), panel = Color3.fromRGB(10, 9, 8),
    card = Color3.fromRGB(15, 13, 11), border = Color3.fromRGB(50, 34, 23), accent = Color3.fromRGB(224, 116, 24),
    accent2 = Color3.fromRGB(255, 170, 54), text = Color3.fromRGB(245, 242, 238), dim = Color3.fromRGB(160, 154, 148),
    off = Color3.fromRGB(30, 26, 22), btn = Color3.fromRGB(20, 17, 14),
}
local function New(class, props)
    local o = Instance.new(class)
    props = props or {}
    for k, v in pairs(props) do
        if k ~= "Parent" then o[k] = v end
    end
    if props.Parent then o.Parent = props.Parent end
    return o
end
local function corner(obj, r)
    New("UICorner", { Parent = obj, CornerRadius = UDim.new(0, r or 10) })
end
local function stroke(obj, color, transparency, thickness)
    local s = New("UIStroke", { Parent = obj, Color = color or C.border, Transparency = transparency or 0.5, Thickness = thickness or 1 })
    pcall(function() s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border end)
    return s
end
local guiParent = game:GetService("CoreGui")
pcall(function()
    if type(gethui) == "function" then
        local h = gethui()
        if typeof(h) == "Instance" then guiParent = h end
    end
end)
local gui = New("ScreenGui", {
    Name = "NoirBladeBall", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
pcall(function() gui.Parent = guiParent end)
local uiScale = New("UIScale", { Parent = gui, Scale = 1 })
local function rescale()
    local cam = workspace.CurrentCamera
    local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local usable = math.max(v.Y - 60, 320)
    uiScale.Scale = math.min(v.X / 1040, usable / 700, 0.96)
end
rescale()
pcall(function()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
end)
local W, H = 960, 660
local win = New("Frame", {
    Parent = gui, Name = "Window", AnchorPoint = Vector2.new(.5, .5),
    Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(W, H),
    BackgroundColor3 = C.base, BackgroundTransparency = .70, ClipsDescendants = true,
    Visible = true, ZIndex = 2,
})
corner(win, 16)
stroke(win, C.border, 0, 2)
local glow = stroke(win, C.accent, .62, 4)
pcall(function()
    TweenService:Create(glow, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = .82 }):Play()
end)
do
    local tint = New("Frame", {
        Parent = win, Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.accent,
        BorderSizePixel = 0, ZIndex = 0,
    })
    corner(tint, 16)
    New("UIGradient", {
        Parent = tint, Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, .93), NumberSequenceKeypoint.new(.5, .975), NumberSequenceKeypoint.new(1, 1),
        }),
    })
end
local function winPosString()
    local p = win.Position
    return string.format("%.4f,%d,%.4f,%d", p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset)
end
local function applyWinPos(s)
    local a, b, c, d = string.match(tostring(s), "([%d%.%-]+),([%d%-]+),([%d%.%-]+),([%d%-]+)")
    local xs, xo, ys, yo = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
    if xs and xo and ys and yo then
        win.Position = UDim2.new(xs, xo, ys, yo)
    end
end
local function makeDraggable(handle, target)
    local dragging, startPos, startMouse = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startMouse = input.Position
            startPos = target.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                saveConfig()
            end
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - startMouse
        target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end)
end
local sidebar = New("Frame", { Parent = win, Size = UDim2.new(0, 82, 1, 0), BackgroundTransparency = 1, ZIndex = 3 })
local logo = New("TextLabel", {
    Parent = sidebar, AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 22),
    Size = UDim2.fromOffset(56, 56), BackgroundColor3 = C.accent, Text = "N",
    TextColor3 = Color3.fromRGB(10, 9, 8), TextSize = 28, Font = Enum.Font.GothamBold, ZIndex = 4,
})
corner(logo, 14)
stroke(logo, C.accent2, .4)
makeDraggable(logo, win)
local PAGES = {
    { id = "combat", glyph = "C", title = "COMBAT" },
    { id = "status", glyph = "S", title = "STATUS" },
    { id = "config", glyph = "G", title = "SETTINGS" },
}
local pageFrames = {}
local navButtons = {}
local function selectPage(id)
    for pid, frame in pairs(pageFrames) do
        frame.Visible = (pid == id)
    end
    for pid, btn in pairs(navButtons) do
        local on = (pid == id)
        btn.BackgroundColor3 = on and C.accent or C.btn
        btn.BackgroundTransparency = on and 0 or .35
        btn.TextColor3 = on and Color3.fromRGB(10, 9, 8) or C.dim
    end
end
for i, def in ipairs(PAGES) do
    local b = New("TextButton", {
        Parent = sidebar, Position = UDim2.fromOffset(21, 100 + (i - 1) * 46), Size = UDim2.fromOffset(40, 40),
        BackgroundColor3 = C.btn, BackgroundTransparency = .35, Text = def.glyph,
        TextColor3 = C.dim, TextSize = 17, Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 4,
    })
    corner(b, 12)
    stroke(b, C.border, .35)
    b.MouseButton1Click:Connect(function() selectPage(def.id) end)
    navButtons[def.id] = b
end
local content = New("Frame", {
    Parent = win, Position = UDim2.fromOffset(82, 0), Size = UDim2.new(1, -82, 1, 0),
    BackgroundTransparency = 1, ZIndex = 3,
})
New("TextLabel", {
    Parent = content, Position = UDim2.fromOffset(24, 22), Size = UDim2.new(1, -48, 0, 26),
    BackgroundTransparency = 1, Text = "BLADE BALL", TextColor3 = C.text, TextSize = 22,
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
})
New("TextLabel", {
    Parent = content, Position = UDim2.fromOffset(24, 48), Size = UDim2.new(1, -48, 0, 16),
    BackgroundTransparency = 1, Text = "auto parry · porting from stage_3",
    TextColor3 = C.dim, TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
})
local headerDrag = New("Frame", {
    Parent = content, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 78),
    BackgroundTransparency = 1, ZIndex = 3,
})
makeDraggable(headerDrag, win)
local closeBtn = New("TextButton", {
    Parent = content, Position = UDim2.new(1, -46, 0, 24), Size = UDim2.fromOffset(26, 26),
    BackgroundColor3 = C.btn, BackgroundTransparency = .3, Text = "×", TextColor3 = C.dim,
    TextSize = 18, Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 5,
})
corner(closeBtn, 8)
stroke(closeBtn, C.border, .4)
closeBtn.MouseButton1Click:Connect(function() win.Visible = false end)
local function makePage(id)
    local page = New("Frame", {
        Parent = content, Position = UDim2.fromOffset(0, 78), Size = UDim2.new(1, 0, 1, -78),
        BackgroundTransparency = 1, Visible = (id == "combat"), ZIndex = 3,
    })
    local scroll = New("ScrollingFrame", {
        Parent = page, Position = UDim2.fromOffset(16, 6), Size = UDim2.new(1, -32, 1, -18),
        BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
        ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.accent, ScrollBarImageTransparency = .25,
        CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ElasticBehavior = Enum.ElasticBehavior.Never, ZIndex = 3,
    })
    New("UIPadding", { Parent = scroll, PaddingBottom = UDim.new(0, 16), PaddingRight = UDim.new(0, 6) })
    local colWrap = New("Frame", {
        Parent = scroll, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, ZIndex = 3,
    })
    local col1 = New("Frame", {
        Parent = colWrap, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(.5, -8, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 3,
    })
    local col2 = New("Frame", {
        Parent = colWrap, Position = UDim2.new(.5, 8, 0, 0), Size = UDim2.new(.5, -8, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 3,
    })
    New("UIListLayout", { Parent = col1, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder })
    New("UIListLayout", { Parent = col2, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder })
    pageFrames[id] = page
    return { page = page, col1 = col1, col2 = col2, count = 0 }
end
local pages = {
    combat = makePage("combat"),
    status = makePage("status"),
    config = makePage("config"),
}
local repaintFns = {}
local function section(page, name, side)
    page.count += 1
    local parent = (side == 2) and page.col2 or page.col1
    local panel = New("Frame", {
        Parent = parent, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.panel, BackgroundTransparency = .88, ClipsDescendants = true,
        LayoutOrder = page.count, ZIndex = 4,
    })
    corner(panel, 12)
    stroke(panel, C.border, .35)
    New("TextLabel", {
        Parent = panel, Position = UDim2.fromOffset(14, 12), Size = UDim2.new(1, -28, 0, 18),
        BackgroundTransparency = 1, Text = name, TextColor3 = C.text, TextSize = 14,
        Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
    })
    New("Frame", {
        Parent = panel, Position = UDim2.fromOffset(14, 36), Size = UDim2.new(1, -28, 0, 1),
        BackgroundColor3 = C.border, BorderSizePixel = 0, ZIndex = 5,
    })
    local holder = New("Frame", {
        Parent = panel, Position = UDim2.fromOffset(14, 46), Size = UDim2.new(1, -28, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 5,
    })
    New("UIListLayout", { Parent = holder, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    New("UIPadding", { Parent = holder, PaddingBottom = UDim.new(0, 14) })
    return holder
end
local rowSerial = 0
local function nextOrder()
    rowSerial += 1
    return rowSerial
end
local function labelRow(holder, text)
    local row = New("Frame", {
        Parent = holder, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1,
        LayoutOrder = nextOrder(), ZIndex = 5,
    })
    New("TextLabel", {
        Parent = row, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, -96, 1, 0),
        BackgroundTransparency = 1, Text = text, TextColor3 = C.text, TextSize = 13,
        Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
    })
    return row
end
local function addToggle(holder, text, get, set, key)
    local row = labelRow(holder, text)
    local state = get()
    local pill = New("TextButton", {
        Parent = row, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, 0, .5, 0),
        Size = UDim2.fromOffset(40, 20), BackgroundColor3 = state and C.accent or C.off,
        Text = "", AutoButtonColor = false, ZIndex = 6,
    })
    corner(pill, 10)
    stroke(pill, state and C.accent2 or C.border, .4)
    local dot = New("Frame", {
        Parent = pill, Size = UDim2.fromOffset(14, 14),
        Position = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
        BackgroundColor3 = state and Color3.fromRGB(15, 13, 11) or C.dim, ZIndex = 7,
    })
    corner(dot, 7)
    local function paint(v)
        TweenService:Create(pill, TweenInfo.new(.18), { BackgroundColor3 = v and C.accent or C.off }):Play()
        TweenService:Create(dot, TweenInfo.new(.18), { Position = v and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = v and Color3.fromRGB(15, 13, 11) or C.dim }):Play()
    end
    pill.MouseButton1Click:Connect(function()
        local v = not get()
        set(v)
        paint(v)
    end)
    if key then repaintFns[key] = function() paint(get()) end end
end
local function addSlider(holder, text, min, max, step, get, set, fmt, key)
    local wrap = New("Frame", {
        Parent = holder, Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1,
        LayoutOrder = nextOrder(), ZIndex = 5,
    })
    New("TextLabel", {
        Parent = wrap, Size = UDim2.new(1, -80, 0, 18), BackgroundTransparency = 1,
        Text = text, TextColor3 = C.text, TextSize = 13, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
    })
    local val = New("TextLabel", {
        Parent = wrap, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(80, 18), BackgroundTransparency = 1, Text = "",
        TextColor3 = C.accent2, TextSize = 12, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6,
    })
    local bar = New("Frame", {
        Parent = wrap, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 5),
        BackgroundColor3 = C.off, BorderSizePixel = 0, ZIndex = 6,
    })
    corner(bar, 3)
    local fill = New("Frame", {
        Parent = bar, Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.accent,
        BorderSizePixel = 0, ZIndex = 7,
    })
    corner(fill, 3)
    local knob = New("Frame", {
        Parent = bar, Size = UDim2.fromOffset(11, 11), AnchorPoint = Vector2.new(.5, .5),
        Position = UDim2.new(0, 0, .5, 0), BackgroundColor3 = C.accent2, BorderSizePixel = 0, ZIndex = 8,
    })
    corner(knob, 6)
    local function fmtValue(v)
        if fmt then return fmt(v) end
        return tostring(v)
    end
    local function paint(v)
        local a = (v - min) / math.max(max - min, 0.0001)
        a = math.clamp(a, 0, 1)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, .5, 0)
        val.Text = fmtValue(v)
    end
    paint(get())
    local dragging = false
    local function applyFromX(x)
        local abs = bar.AbsolutePosition.X
        local w = bar.AbsoluteSize.X
        if w <= 0 then return end
        local a = math.clamp((x - abs) / w, 0, 1)
        local raw = min + (max - min) * a
        local v = math.floor(raw / step + 0.5) * step
        v = math.clamp(v, min, max)
        set(v)
        paint(v)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            applyFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            applyFromX(input.Position.X)
        end
    end)
    if key then repaintFns[key] = function() paint(get()) end end
end
local function addCycle(holder, text, values, get, set, key)
    local row = labelRow(holder, text)
    local idx = 1
    for i, v in ipairs(values) do
        if v == get() then idx = i break end
    end
    local btn = New("TextButton", {
        Parent = row, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, 0, .5, 0),
        Size = UDim2.fromOffset(88, 22), BackgroundColor3 = C.btn, BackgroundTransparency = .3,
        Text = tostring(values[idx]), TextColor3 = C.accent2, TextSize = 12,
        Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 6,
    })
    corner(btn, 7)
    stroke(btn, C.border, .4)
    btn.MouseButton1Click:Connect(function()
        idx = idx % #values + 1
        local v = values[idx]
        btn.Text = tostring(v)
        set(v)
    end)
    if key then
        repaintFns[key] = function()
            for i, v in ipairs(values) do
                if v == get() then idx = i break end
            end
            btn.Text = tostring(values[idx])
        end
    end
end
local captureKey = nil
local function addKeybind(holder, text, get, set, key)
    local row = labelRow(holder, text)
    local btn = New("TextButton", {
        Parent = row, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, 0, .5, 0),
        Size = UDim2.fromOffset(88, 22), BackgroundColor3 = C.btn, BackgroundTransparency = .3,
        Text = tostring(get()), TextColor3 = C.accent2, TextSize = 12,
        Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 6,
    })
    corner(btn, 7)
    stroke(btn, C.border, .4)
    btn.MouseButton1Click:Connect(function()
        btn.Text = "..."
        captureKey = function(keyCode)
            local name = keyCode.Name
            set(name)
            btn.Text = name
        end
    end)
    if key then
        repaintFns[key] = function()
            captureKey = nil
            btn.Text = tostring(get())
        end
    end
end
local function addInfo(holder, text)
    local row = New("Frame", {
        Parent = holder, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
        LayoutOrder = nextOrder(), ZIndex = 5,
    })
    New("TextLabel", {
        Parent = row, Size = UDim2.new(1, -100, 1, 0), BackgroundTransparency = 1,
        Text = text, TextColor3 = C.dim, TextSize = 12, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
    })
    local val = New("TextLabel", {
        Parent = row, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(110, 22), BackgroundTransparency = 1, Text = "-",
        TextColor3 = C.text, TextSize = 12, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6,
    })
    return val
end
local PingCache = 50
task.spawn(function()
    local network = Stats:WaitForChild("Network", 30)
    if not network then return end
    local serverStats = network:WaitForChild("ServerStatsItem", 30)
    if not serverStats then return end
    local dataPing = serverStats:WaitForChild("Data Ping", 30)
    if not dataPing then return end
    while true do
        local ok, v = pcall(function() return dataPing:GetValue() end)
        if ok and type(v) == "number" then PingCache = v end
        task.wait(0.5)
    end
end)
local EXT = {
    AutoParryMode = "Remote",
    TargetLockEnabled = false,
    BallVelocityAbove800 = false,
    AutoPreClick = false,
    CooldownProtection = false,
    AutoAbility = false,
    _PreClickSender = nil,
    _PreClickSpeeds = {},
    _GetTargetLockCharacter = nil,
    skinChangerEnabled = false,
    swordAnimations = nil,
}
do
    local ok_hook = pcall(function()
        if type(hookfunction) ~= "function" or type(getrenv) ~= "function" then
            error("no hookfunction/getrenv")
        end
        local renv = getrenv()
        local old_dinfo
        old_dinfo = hookfunction(renv.debug.info, function(f, t)
            if type(f) == "function" then
                return "[C]"
            elseif f == 4 and t == "s" then
                return "ReplicatedStorage.Controllers.SwordsController "
            end
            return old_dinfo(f, t)
        end)
        local old_gfenv
        old_gfenv = hookfunction(renv.getfenv, function(l)
            if l ~= nil and type(l) == "number" then
                if l >= 1 and l <= 10 then return old_gfenv(10) end
            end
            return old_gfenv(l)
        end)
    end)
    if not ok_hook then
        warn("[Noir AP] spoof hooks failed to install")
    end
end
local PF = nil
local _PARRY_PATCH = {
    keyTable = nil, transformFn = nil, netModule = nil,
    remoteId = nil, parryHash = nil, parryRemote = nil, ready = false,
}
local function _serVal(v, depth)
    depth = depth or 1
    local t = typeof(v)
    if t == "string" then
        if #v > 40 then return '"' .. v:sub(1, 40) .. '.."(len' .. #v .. ')' end
        return '"' .. v .. '"'
    end
    if t == "table" then
        if depth > 2 then return "{...}" end
        local parts = {}
        local c = 0
        for k, val in pairs(v) do
            c = c + 1
            if c > 6 then parts[#parts + 1] = "..." break end
            parts[#parts + 1] = tostring(k) .. "=" .. _serVal(val, depth + 1)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    if t == "Instance" then
        return v.ClassName .. "[" .. v.Name .. "]"
    end
    return tostring(v)
end
function _PARRY_PATCH.serargs(a)
    local parts = {}
    for i2 = 1, #a do parts[i2] = _serVal(a[i2]) end
    return table.concat(parts, ", ")
end
task.spawn(function()
    local ok, err = pcall(function()
        local Controllers = ReplicatedStorage:WaitForChild("Controllers", 15)
        if not Controllers then return end
        local SCm
        for _, child in ipairs(Controllers:GetChildren()) do
            if child.Name:sub(1, 16) == "SwordsController" then
                SCm = child
                break
            end
        end
        if not SCm then warn("[Noir AP] SwordsController not found") return end
        local PRY = SCm:WaitForChild("PRY", 15)
        if not PRY then warn("[Noir AP] PRY module not found") return end
        print("[NoirDBG] PRY found, module:", SCm:GetFullName())
        local Parry_Function = require(PRY)
        PF = Parry_Function
        print("[NoirDBG] require(PRY) ->", type(Parry_Function))
        local getupvals = debug.getupvalues or getupvalues
        if not getupvals then warn("[Noir AP] executor missing getupvalues") return end
        local ups = getupvals(Parry_Function)
        if not ups or #ups < 8 then warn("[Noir AP] unexpected upvalue count") return end
        local _gu = debug.getupvalue or getupvalue
        for _i = 1, #ups do
            local _v = ups[_i]
            local _d = type(_v)
            if _d == "table" then _d = "table#" .. tostring(#_v) end
            if typeof(_v) == "Instance" then _d = _v.ClassName end
            local _nm = "?"
            pcall(function() if _gu then _nm = select(1, _gu(Parry_Function, _i)) or "?" end end)
            print(string.format("[NoirDBG] upvalue[%d] %s = %s (%s)", _i, tostring(_nm), tostring(_v), _d))
        end
        _PARRY_PATCH.keyTable    = ups[3]
        _PARRY_PATCH.transformFn = ups[4]
        _PARRY_PATCH.parryHash   = ups[8]

        local knownStrings = {}
        for _i = 1, #ups do
            if type(ups[_i]) == "string" then knownStrings[tostring(ups[_i])] = _i end
        end

        _PARRY_PATCH.remotes = {}
        for _i = 1, #ups do
            local _v = ups[_i]
            if typeof(_v) == "Instance" and (_v.ClassName == "RemoteEvent" or _v.ClassName == "RemoteFunction") then
                table.insert(_PARRY_PATCH.remotes, _v)
                print("[CAPT] watching " .. _v.ClassName .. ":", _v.Name)
            end
        end
        if #_PARRY_PATCH.remotes == 0 then
            warn("[Noir AP] no remote upvalues found in PRY")
            return
        end

        local okHook, hookErr = pcall(function()
            if not hookfunction then error("no hookfunction") end
            local baseFS = _PARRY_PATCH.remotes[1].FireServer
            local origFS
            origFS = hookfunction(baseFS, function(self, ...)
                if typeof(self) == "Instance" then
                    for _, r in ipairs(_PARRY_PATCH.remotes) do
                        if self == r then
                            local a = {...}
                            if not _PARRY_PATCH.ready then
                                print("[CAPT] FireServer [" .. self.Name .. "] args=" .. _PARRY_PATCH.serargs(a))
                            end
                            if not _PARRY_PATCH.ready and typeof(a[1]) == "string" and #a >= 6 and knownStrings[tostring(a[1])] then
                                _PARRY_PATCH.parryRemote = self
                                _PARRY_PATCH.parryHash = a[1]
                                _PARRY_PATCH.ready = true
                                _G.__noirAPReady = true
                                print("[CAPT] >>> parry remote ADOPTED (hash=upvalue[" .. tostring(knownStrings[tostring(a[1])]) .. "])")
                            end
                            break
                        end
                    end
                end
                return origFS(self, ...)
            end)
        end)
        if not okHook then warn("[Noir AP] FireServer hook failed:", tostring(hookErr)) end
        print("[NoirDBG] sniffing FireServer. Parry manually once -> remote gets adopted.")
    end)
    if not ok then warn("[Noir AP] init error:", tostring(err)) end
end)
function _PARRY_PATCH.fire(curveCFrame, screenPositions, mouseLocation)
    if not _PARRY_PATCH.ready or not _PARRY_PATCH.parryRemote then
        if tick() - (_PARRY_PATCH._warnT or 0) > 3 then
            _PARRY_PATCH._warnT = tick()
            print("[NoirDBG] fire blocked: waiting for one manual parry (remote sniff)")
        end
        return false
    end
    local kt = _PARRY_PATCH.keyTable
    if type(kt) ~= "table" or type(_PARRY_PATCH.transformFn) ~= "function" then
        return false
    end
    local keyIndex = kt[3]
    local currentKey = kt[1] and kt[1][keyIndex]
    if currentKey == nil then
        return false
    end
    local tok, transformed = pcall(_PARRY_PATCH.transformFn, currentKey, "TIME")
    if not tok or not transformed then
        tok, transformed = pcall(_PARRY_PATCH.transformFn, currentKey)
        if not tok or not transformed then
            return false
        end
    end
    local serverTime = workspace:GetServerTimeNow() * 100
    local timeStr = tostring(math.floor(serverTime))
    local tc = {}
    for i = 1, #timeStr do
        local ki = (i - 1) % #transformed + 1
        local kb = string.byte(transformed, ki)
        local tb = (string.byte(timeStr, i) + i) % 256
        tc[i] = string.char(bit32.bxor(tb, kb))
    end
    local token = table.concat(tc)
    local fok, ferr = pcall(function()
        _PARRY_PATCH.parryRemote:FireServer(
            _PARRY_PATCH.parryHash,
            currentKey,
            token,
            0.5,
            curveCFrame,
            screenPositions,
            mouseLocation,
            false
        )
    end)
    if not fok then
        if tick() - (_PARRY_PATCH._errT or 0) > 3 then
            _PARRY_PATCH._errT = tick()
            print("[NoirDBG] FireServer failed:", tostring(ferr))
        end
        return false
    end
    _PARRY_PATCH._fired = (_PARRY_PATCH._fired or 0) + 1
    if _PARRY_PATCH._fired == 1 or _PARRY_PATCH._fired % 50 == 0 then
        print("[NoirDBG] FIRE x" .. tostring(_PARRY_PATCH._fired) .. " (raw packet OK)")
    end
    return true
end
local System = {
    __properties = {
        __autoparry_enabled = false,
        __curve_mode = 1,
        __accuracy = 100,
        __divisor_multiplier = 0.7 + (100 - 1) * 0.0035353535353535,
        __parried = false,
        __training_parried = false,
        __parries = 0,
        __grab_animation = nil,
        __play_animation = false,
        __tornado_time = tick(),
        __connections = {},
        __infinity_active = false,
        __deathslash_active = false,
        __timehole_active = false,
        __slashesoffury_active = false,
        __slashesoffury_count = 0,
        __is_mobile = IS_MOBILE,
    },
    __config = {
        __curve_names = {'Camera', 'Random', 'Accelerated', 'Backwards', 'Slow', 'High', 'Left', 'Right', 'Straight', 'RandomTarget'},
        __detections = {
            __infinity = false,
            __deathslash = false,
            __timehole = false,
            __slashesoffury = false,
            __phantom = false,
        }
    },
    __triggerbot = {
        __enabled = false,
        __is_parrying = false,
        __parries = 0,
        __max_parries = 10000,
        __parry_delay = 0.5
    }
}
local function update_divisor()
    System.__properties.__divisor_multiplier = 0.7 + (System.__properties.__accuracy - 1) * 0.0035353535353535
end
System.ball = {}
function System.ball.get()
    local balls = workspace:FindFirstChild('Balls')
    if not balls then return nil end
    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute("realBall") then
            pcall(function() ball.CanCollide = false end)
            return ball
        end
    end
    return nil
end
function System.ball.get_all()
    local balls_table = {}
    local balls = workspace:FindFirstChild('Balls')
    if not balls then return balls_table end
    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute("realBall") then
            pcall(function() ball.CanCollide = false end)
            table.insert(balls_table, ball)
        end
    end
    return balls_table
end
System.player = {}
function System.player.get_closest_to_cursor()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        return nil
    end
    local Alive = workspace:FindFirstChild("Alive")
    if not Alive then return nil end
    local closest_player = nil
    local minimal_dot = -math.huge
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local success, mouse_location = pcall(function()
        return UserInputService:GetMouseLocation()
    end)
    if not success or not mouse_location then return nil end
    local ray = camera:ScreenPointToRay(mouse_location.X, mouse_location.Y)
    local pointer = CFrame.lookAt(ray.Origin, ray.Origin + ray.Direction)
    for _, player in pairs(Alive:GetChildren()) do
        if player == LocalPlayer.Character then continue end
        if not player:FindFirstChild('HumanoidRootPart') then continue end
        local direction = (player.HumanoidRootPart.Position - camera.CFrame.Position).Unit
        local dot = pointer.LookVector:Dot(direction)
        if dot > minimal_dot then
            minimal_dot = dot
            closest_player = player
        end
    end
    return closest_player
end
System.curve = {}
function System.curve.get_cframe()
    local camera = workspace.CurrentCamera
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if not camera then return CFrame.new() end
    if not root then return camera.CFrame end
    if EXT.TargetLockEnabled and EXT._GetTargetLockCharacter then
        local ok, target = pcall(EXT._GetTargetLockCharacter)
        local targetRoot = nil
        if ok and target then
            targetRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
        end
        if targetRoot then
            return CFrame.new(root.Position, targetRoot.Position)
        end
    end
    local targetPart
    local closest = System.player.get_closest_to_cursor()
    if closest and closest:FindFirstChild('HumanoidRootPart') then
        targetPart = closest.HumanoidRootPart
    end
    local target_pos = targetPart and targetPart.Position or (root.Position + camera.CFrame.LookVector * 8928)
    local curve_functions = {
        function() return camera.CFrame end,
        function()
            local direction = (target_pos - root.Position).Unit
            local random_offset
            local attempts = 0
            repeat
                random_offset = Vector3.new(
                    math.random(-4000, 4000),
                    math.random(-4000, 4000),
                    math.random(-4000, 4000)
                )
                local curve_direction = (target_pos + random_offset - root.Position).Unit
                local dot = direction:Dot(curve_direction)
                attempts = attempts + 1
            until dot < 0.95 or attempts > 10
            return CFrame.new(root.Position, target_pos + random_offset)
        end,
        function()
            return CFrame.new(root.Position, target_pos + Vector3.new(0, 5, 0))
        end,
        function()
            local direction = (root.Position - target_pos).Unit
            local backwards_pos = root.Position + direction * 10000 + Vector3.new(0, 1000, 0)
            return CFrame.new(camera.CFrame.Position, backwards_pos)
        end,
        function()
            return CFrame.new(root.Position, target_pos + Vector3.new(0, -9e18, 0))
        end,
        function()
            return CFrame.new(root.Position, target_pos + Vector3.new(0, 9e18, 0))
        end,
        function()
            local left_vec = -camera.CFrame.RightVector * 9999
            return CFrame.new(root.Position, root.Position + left_vec)
        end,
        function()
            local right_vec = camera.CFrame.RightVector * 10000
            return CFrame.new(root.Position, root.Position + right_vec)
        end,
        function()
            local Aimed_Player = nil
            local Closest_Distance = math.huge
            local Mouse_Location = UserInputService:GetMouseLocation()
            local Mouse_Vector = Vector2.new(Mouse_Location.X, Mouse_Location.Y)
            local alive = workspace:FindFirstChild("Alive")
            if alive then
                for _, v in pairs(alive:GetChildren()) do
                    if v ~= LocalPlayer.Character and v.PrimaryPart then
                        local screenPos, isOnScreen = camera:WorldToScreenPoint(v.PrimaryPart.Position)
                        if isOnScreen then
                            local playerScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                            local distance = (Mouse_Vector - playerScreenPos).Magnitude
                            if distance < Closest_Distance then
                                Closest_Distance = distance
                                Aimed_Player = v
                            end
                        end
                    end
                end
            end
            if Aimed_Player then
                return CFrame.new(root.Position, Aimed_Player.PrimaryPart.Position)
            else
                return CFrame.new(root.Position, target_pos)
            end
        end,
        function()
            local candidates = {}
            local alive = workspace:FindFirstChild("Alive")
            if alive then
                for _, v in pairs(alive:GetChildren()) do
                    if v ~= LocalPlayer.Character and v.PrimaryPart then
                        local screenPos, isOnScreen = camera:WorldToScreenPoint(v.PrimaryPart.Position)
                        if isOnScreen then table.insert(candidates, v) end
                    end
                end
            end
            if #candidates > 0 then
                local pick = candidates[math.random(1, #candidates)]
                return CFrame.new(root.Position, pick.PrimaryPart.Position)
            else
                return camera.CFrame
            end
        end
    }
    local fn = curve_functions[System.__properties.__curve_mode] or curve_functions[1]
    return fn()
end
System.animation = {}
function System.animation.play_grab_parry()
    if not System.__properties.__play_animation then return end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass('Humanoid')
    local animator = humanoid and humanoid:FindFirstChildOfClass('Animator')
    if not humanoid or not animator then return end
    local sword_name
    if EXT.skinChangerEnabled then
        sword_name = EXT.swordAnimations
    else
        sword_name = character:GetAttribute('CurrentlyEquippedSword')
    end
    if not sword_name then return end
    local ok = pcall(function()
        local sword_api = ReplicatedStorage.Shared.SwordAPI.Collection
        local parry_animation = sword_api.Default:FindFirstChild('GrabParry')
        if not parry_animation then return end
        local sword_data = ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(sword_name)
        if not sword_data or not sword_data['AnimationType'] then return end
        for _, object in pairs(sword_api:GetChildren()) do
            if object.Name == sword_data['AnimationType'] then
                if object:FindFirstChild('GrabParry') or object:FindFirstChild('Grab') then
                    local animation_type = object:FindFirstChild('GrabParry') and 'GrabParry' or 'Grab'
                    parry_animation = object[animation_type]
                end
            end
        end
        if System.__properties.__grab_animation and System.__properties.__grab_animation.IsPlaying then
            System.__properties.__grab_animation:Stop()
        end
        System.__properties.__grab_animation = animator:LoadAnimation(parry_animation)
        System.__properties.__grab_animation.Priority = Enum.AnimationPriority.Action4
        System.__properties.__grab_animation:Play()
    end)
    if not ok then
    end
end
System.parry = {}
function System.parry.execute()
    if System.__properties.__parries > 10000 or not LocalPlayer.Character then
        return
    end
    if not _PARRY_PATCH or not _PARRY_PATCH.ready then
        return
    end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local success, mouse = pcall(function()
        return UserInputService:GetMouseLocation()
    end)
    if not success then return end
    local is_mobile = System.__properties.__is_mobile
    local screenPositions = {}
    local Alive = workspace:FindFirstChild("Alive")
    if Alive then
        for _, entity in pairs(Alive:GetChildren()) do
            if entity.PrimaryPart then
                local ok2, sp = pcall(function()
                    return camera:WorldToScreenPoint(entity.PrimaryPart.Position)
                end)
                if ok2 and sp then
                    screenPositions[entity.Name] = sp
                end
            end
        end
    end
    local curveCF = (System.curve and System.curve.get_cframe and System.curve.get_cframe()) or camera.CFrame
    local mouseLocation
    if is_mobile then
        local vp = camera.ViewportSize
        mouseLocation = {vp.X / 2, vp.Y / 2}
    else
        mouseLocation = {mouse.X, mouse.Y}
    end
    if EXT.TargetLockEnabled and EXT._GetTargetLockCharacter then
        local okT, target = pcall(EXT._GetTargetLockCharacter)
        local targetRoot = nil
        if okT and target then
            targetRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
        end
        if targetRoot then
            local ok2, point = pcall(function() return camera:WorldToScreenPoint(targetRoot.Position) end)
            if ok2 and point then mouseLocation = {point.X, point.Y} end
        end
    end
    _PARRY_PATCH.fire(curveCF, screenPositions, mouseLocation)
    if System.__properties.__parries > 10000 then return end
    System.__properties.__parries = System.__properties.__parries + 1
    task.delay(0.5, function()
        if System.__properties.__parries > 0 then
            System.__properties.__parries = System.__properties.__parries - 1
        end
    end)
end
local _keypressJitterMin = 0.012
local _keypressJitterMax = 0.040
function System.parry.keypress()
    if System.__properties.__parries > 10000 or not LocalPlayer.Character then
        return
    end
    local lo = _keypressJitterMin
    local hi = math.max(_keypressJitterMax, lo)
    local jitter = lo + math.random() * (hi - lo)
    task.delay(jitter, function()
        System.parry.execute()
    end)
end
function System.parry.execute_action()
    System.animation.play_grab_parry()
    System.parry.execute()
end
System.detection = {
    __ball_properties = {
        __aerodynamic_time = tick(),
        __last_warping = tick(),
        __lerp_radians = 0,
        __curving = tick()
    }
}
function System.detection.is_curved()
    local ball = System.ball.get()
    if not ball then return false end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return false end
    local zoomies = ball:FindFirstChild("zoomies")
    if not zoomies then return false end
    local ping = PingCache or 50
    local velocity = zoomies.VectorVelocity
    local speed = velocity.Magnitude
    if speed == 0 then return false end
    local ball_direction = velocity.Unit
    local playerPos = LocalPlayer.Character.PrimaryPart.Position
    local ballPos = ball.Position
    local direction = (playerPos - ballPos).Unit
    local dot = direction:Dot(ball_direction)
    local speed_threshold = math.min(speed / 100, 40)
    local distance = (playerPos - ballPos).Magnitude
    local reach_time = distance / speed - (ping / 1000)
    local ball_distance_threshold = 15 - math.min(distance / 1000, 15) + speed_threshold
    if not System.detection._ZX_PrevVel then System.detection._ZX_PrevVel = {} end
    local Previous_Velocity = System.detection._ZX_PrevVel
    table.insert(Previous_Velocity, velocity)
    if #Previous_Velocity > 4 then table.remove(Previous_Velocity, 1) end
    if not System.detection._ZX_CurveState then
        System.detection._ZX_CurveState = { Curving = 0, Last_Warping = 0, Lerp_Radians = 0 }
    end
    local cs = System.detection._ZX_CurveState
    if ball:FindFirstChild("AeroDynamicSlashVFX") then
        pcall(function() ball.AeroDynamicSlashVFX:Destroy() end)
        cs.Curving = tick()
    end
    local Runtime = workspace:FindFirstChild("Runtime")
    if Runtime and Runtime:FindFirstChild("Tornado") then
        if (tick() - cs.Curving) < ((Runtime.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159) then return true end
    end
    local enough_speed = speed > 160
    if enough_speed and reach_time > (ping / 10 + 0.03) then
        if speed < 300 then ball_distance_threshold = math.max(ball_distance_threshold - 13, 13)
        elseif speed <= 600 then ball_distance_threshold = math.max(ball_distance_threshold - 15, 15)
        elseif speed <= 1000 then ball_distance_threshold = math.max(ball_distance_threshold - 17, 17)
        else ball_distance_threshold = math.max(ball_distance_threshold - 19, 19) end
    end
    if distance < ball_distance_threshold then return false end
    local adjusted_reach_time = reach_time + 0.03
    if speed < 300 then
        if (tick() - cs.Curving) < (adjusted_reach_time / 1.15) then return true end
    elseif speed < 450 then
        if (tick() - cs.Curving) < (adjusted_reach_time / 1.18) then return true end
    elseif speed < 600 then
        if (tick() - cs.Curving) < (adjusted_reach_time / 1.3) then return true end
    else
        if (tick() - cs.Curving) < (adjusted_reach_time / 1.45) then return true end
    end
    local dot_threshold = (0 - ping / 1000)
    local direction_difference = (ball_direction - velocity.Unit)
    local direction_similarity = 0
    if direction_difference.Magnitude > 0 then direction_similarity = direction:Dot(direction_difference.Unit) end
    local dot_difference = dot - direction_similarity
    if dot_difference < dot_threshold then return true end
    local clamped_dot = math.clamp(dot, -1, 1)
    local radians = math.deg(math.asin(clamped_dot))
    cs.Lerp_Radians = cs.Lerp_Radians + (radians - cs.Lerp_Radians) * 0.8
    if speed < 300 then
        if cs.Lerp_Radians < 0.015 then cs.Last_Warping = tick() end
        if (tick() - cs.Last_Warping) < (adjusted_reach_time / 1.15) then return true end
    else
        if cs.Lerp_Radians < 0.012 then cs.Last_Warping = tick() end
        if (tick() - cs.Last_Warping) < (adjusted_reach_time / 1.45) then return true end
    end
    if #Previous_Velocity == 4 then
        for i = 1, 2 do
            local prev_dir = (ball_direction - Previous_Velocity[i].Unit)
            if prev_dir.Magnitude > 0 then
                prev_dir = prev_dir.Unit
                local prev_dot = direction:Dot(prev_dir)
                if (dot - prev_dot) < dot_threshold then return true end
            end
        end
    end
    local backwards_curve_detected = false
    local backwards_angle_threshold = 60
    local horiz_direction = Vector3.new(playerPos.X - ballPos.X, 0, playerPos.Z - ballPos.Z)
    if horiz_direction.Magnitude > 0 then
        horiz_direction = horiz_direction.Unit
        local away_from_player = -horiz_direction
        local horiz_ball_dir = Vector3.new(ball_direction.X, 0, ball_direction.Z)
        if horiz_ball_dir.Magnitude > 0 then
            horiz_ball_dir = horiz_ball_dir.Unit
            local backwards_angle = math.deg(math.acos(math.clamp(away_from_player:Dot(horiz_ball_dir), -1, 1)))
            if backwards_angle < backwards_angle_threshold then backwards_curve_detected = true end
        end
    end
    return (dot < dot_threshold) or backwards_curve_detected
end
do
    pcall(function()
        local r = ReplicatedStorage:WaitForChild("Remotes", 15)
        if r then
            local death = r:WaitForChild("DeathBall", 15)
            if death then
                death.OnClientEvent:Connect(function(_, d)
                    System.__properties.__deathslash_active = d or false
                end)
            end
            local infinity = r:WaitForChild("InfinityBall", 15)
            if infinity then
                infinity.OnClientEvent:Connect(function(_, b)
                    System.__properties.__infinity_active = b or false
                end)
            end
        end
    end)
    task.spawn(function()
        pcall(function()
            local net = ReplicatedStorage:WaitForChild("Packages", 15)
            net = net and net:WaitForChild("_Index", 15)
            net = net and net:WaitForChild("sleitnick_net@0.1.0", 15)
            net = net and net:WaitForChild("net", 15)
            if not net then return end
            net["RE/TimeHoleActivate"].OnClientEvent:Connect(function(player)
                if player == LocalPlayer or player == LocalPlayer.Name or (player and player.Name == LocalPlayer.Name) then
                    System.__properties.__timehole_active = true
                end
            end)
            net["RE/TimeHoleDeactivate"].OnClientEvent:Connect(function()
                System.__properties.__timehole_active = false
            end)
            net["RE/SlashesOfFuryActivate"].OnClientEvent:Connect(function(player)
                if player == LocalPlayer or player == LocalPlayer.Name or (player and player.Name == LocalPlayer.Name) then
                    System.__properties.__slashesoffury_active = true
                    System.__properties.__slashesoffury_count = 0
                end
            end)
            net["RE/SlashesOfFuryEnd"].OnClientEvent:Connect(function()
                System.__properties.__slashesoffury_active = false
                System.__properties.__slashesoffury_count = 0
            end)
            net["RE/SlashesOfFuryParry"].OnClientEvent:Connect(function()
                System.__properties.__slashesoffury_count = System.__properties.__slashesoffury_count + 1
            end)
        end)
    end)
end
System.autoparry = {}
function System.autoparry.start()
    if System.__properties.__connections.__autoparry then
        System.__properties.__connections.__autoparry:Disconnect()
    end
    System.__properties.__connections.__autoparry = RunService.PreSimulation:Connect(function()
        if not System.__properties.__autoparry_enabled or not LocalPlayer.Character or
           not LocalPlayer.Character.PrimaryPart then
            return
        end
        local balls = System.ball.get_all()
        local one_ball = System.ball.get()
        local training_ball = nil
        pcall(function()
            if workspace:FindFirstChild("TrainingBalls") then
                for _, inst in pairs(workspace.TrainingBalls:GetChildren()) do
                    if inst:GetAttribute("realBall") then
                        training_ball = inst
                        break
                    end
                end
            end
        end)
        for _, ball in pairs(balls) do
            if System.__triggerbot.__enabled then return end
            if EXT.BallVelocityAbove800 then return end
            if not ball then continue end
            local zoomies = ball:FindFirstChild("zoomies")
            if not zoomies then continue end
            ball:GetAttributeChangedSignal("target"):Once(function()
                System.__properties.__parried = false
            end)
            if System.__properties.__parried then continue end
            local ball_target = ball:GetAttribute("target")
            local velocity = zoomies.VectorVelocity
            local distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
            local ping = PingCache / 10
            local ping_threshold = math.clamp(ping / 10, 5, 17)
            local speed = velocity.Magnitude
            if EXT.AutoPreClick then
                if ball_target and ball_target ~= "" and ball_target ~= LocalPlayer.Name then
                    EXT._PreClickSender = ball_target
                end
                if not EXT._PreClickSpeeds[ball_target] then
                    EXT._PreClickSpeeds[ball_target] = {}
                end
                table.insert(EXT._PreClickSpeeds[ball_target], speed)
                if #EXT._PreClickSpeeds[ball_target] > 15 then
                    table.remove(EXT._PreClickSpeeds[ball_target], 1)
                end
            end
            local capped_speed_diff = math.min(math.max(speed - 9.5, 0), 650)
            local speed_divisor = (2.4 + capped_speed_diff * 0.002) * System.__properties.__divisor_multiplier
            local parry_accuracy = ping_threshold + math.max(speed / speed_divisor, 9.5)
            local curved = System.detection.is_curved()
            if ball:FindFirstChild("AeroDynamicSlashVFX") then
                pcall(function() ball.AeroDynamicSlashVFX:Destroy() end)
                System.__properties.__tornado_time = tick()
            end
            local Runtime = workspace:FindFirstChild("Runtime")
            if Runtime and Runtime:FindFirstChild('Tornado') then
                if (tick() - System.__properties.__tornado_time) <
                   ((Runtime.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159) then
                    continue
                end
            end
            if one_ball and one_ball:GetAttribute("target") == LocalPlayer.Name and curved then
                continue
            end
            if ball:FindFirstChild("ComboCounter") then continue end
            if LocalPlayer.Character.PrimaryPart:FindFirstChild("SingularityCape") then continue end
            if System.__config.__detections.__infinity and System.__properties.__infinity_active then continue end
            if System.__config.__detections.__deathslash and System.__properties.__deathslash_active then continue end
            if System.__config.__detections.__timehole and System.__properties.__timehole_active then continue end
            if System.__config.__detections.__slashesoffury and System.__properties.__slashesoffury_active then continue end
            if ball_target == LocalPlayer.Name and distance <= parry_accuracy then
                if EXT.CooldownProtection then
                    pcall(function()
                        local ParryCD = LocalPlayer.PlayerGui.Hotbar.Block.UIGradient
                        if ParryCD.Offset.Y < 0.4 then
                            ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
                        end
                    end)
                end
                if EXT.AutoAbility then
                    pcall(function()
                        local AbilityCD = LocalPlayer.PlayerGui.Hotbar.Ability.UIGradient
                        if AbilityCD.Offset.Y == 0.5 then
                            local abilities = LocalPlayer.Character:FindFirstChild("Abilities")
                            if abilities then
                                local lst = {"Raging Deflection", "Rapture", "Calming Deflection", "Aerodynamic Slash", "Fracture", "Death Slash"}
                                for _, aname in ipairs(lst) do
                                    local ab = abilities:FindFirstChild(aname)
                                    if ab and ab.Enabled then
                                        System.__properties.__parried = true
                                        ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
                                        task.wait(2.432)
                                        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DeathSlashShootActivation"):FireServer(true)
                                        break
                                    end
                                end
                            end
                        end
                    end)
                end
            end
            if ball_target == LocalPlayer.Name and tick() - (System.__properties.__dbgTick or 0) > 1 then
                System.__properties.__dbgTick = tick()
                print(string.format(
                    "[NoirDBG] ball@me dist=%.1f acc=%.1f curved=%s ready=%s mode=%s",
                    distance, parry_accuracy, tostring(curved),
                    tostring(_PARRY_PATCH.ready), tostring(EXT.AutoParryMode)
                ))
            end
            if ball_target == LocalPlayer.Name and distance <= parry_accuracy then
                if EXT.AutoParryMode == "Keypress" then
                    System.parry.keypress()
                else
                    System.parry.execute_action()
                end
                System.__properties.__parried = true
            end
            local last_parrys = tick()
            repeat
                RunService.Stepped:Wait()
            until (tick() - last_parrys) >= 1 or not System.__properties.__parried
            System.__properties.__parried = false
        end
        if training_ball then
            local zoomies = training_ball:FindFirstChild("zoomies")
            if zoomies then
                training_ball:GetAttributeChangedSignal("target"):Once(function()
                    System.__properties.__training_parried = false
                end)
                if not System.__properties.__training_parried then
                    local ball_target = training_ball:GetAttribute("target")
                    local velocity = zoomies.VectorVelocity
                    local distance = LocalPlayer:DistanceFromCharacter(training_ball.Position)
                    local speed = velocity.Magnitude
                    local ping = PingCache / 10
                    local ping_threshold = math.clamp(ping / 10, 5, 25)
                    local capped_speed_diff = math.min(math.max(speed - 9.5, 0), 650)
                    local speed_divisor = (2.4 + capped_speed_diff * 0.002) * System.__properties.__divisor_multiplier
                    local parry_accuracy = ping_threshold + math.max(speed / speed_divisor, 9.5)
                    if ball_target == LocalPlayer.Name and distance <= parry_accuracy then
                        if EXT.AutoParryMode == "Keypress" then
                            System.parry.keypress()
                        else
                            System.parry.execute_action()
                        end
                        System.__properties.__training_parried = true
                        local last_parrys = tick()
                        repeat
                            RunService.Stepped:Wait()
                        until (tick() - last_parrys) >= 1 or not System.__properties.__training_parried
                        System.__properties.__training_parried = false
                    end
                end
            end
        end
    end)
end
function System.autoparry.stop()
    if System.__properties.__connections.__autoparry then
        System.__properties.__connections.__autoparry:Disconnect()
        System.__properties.__connections.__autoparry = nil
    end
end
local AP = nil
local apMobile = nil
local apBtnPosStr = ""
local function apMobileApplyPos()
    if not apMobile then return end
    local a, b, c, d = string.match(apBtnPosStr, "([%d%.%-]+),([%d%-]+),([%d%.%-]+),([%d%-]+)")
    local xs, xo, ys, yo = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
    if xs and xo and ys and yo then
        apMobile.btn.Position = UDim2.new(xs, xo, ys, yo)
    end
end
local function refreshApMobileText()
    if apMobile and apMobile.btn then
        local on = System.__properties.__autoparry_enabled
        if on then
            apMobile.btn.Text = "AP\nON"
            apMobile.btn.BackgroundColor3 = C.accent
            apMobile.btn.TextColor3 = Color3.fromRGB(10, 9, 8)
        else
            apMobile.btn.Text = "AP"
            apMobile.btn.BackgroundColor3 = C.off
            apMobile.btn.TextColor3 = C.dim
        end
    end
end
local function destroyApMobile()
    if apMobile then
        pcall(function() apMobile.gui:Destroy() end)
        apMobile = nil
    end
end
local function ensureApMobile()
    if not IS_MOBILE then return end
    if apMobile then refreshApMobileText() return end
    local holder = New("ScreenGui", { Name = "NoirAPButton", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 998 })
    pcall(function() holder.Parent = guiParent end)
    local b = New("TextButton", {
        Parent = holder, Size = UDim2.fromOffset(56, 56), Position = UDim2.new(1, -76, 0.5, -28),
        BackgroundColor3 = C.accent, BackgroundTransparency = .12, Text = "AP\nON",
        TextColor3 = Color3.fromRGB(10, 9, 8), TextSize = 15, Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
    })
    corner(b, 28)
    stroke(b, C.accent2, .35)
    apMobile = { gui = holder, btn = b }
    apMobileApplyPos()
    refreshApMobileText()
    local dragging, moved, dragStart, startPos = false, false, nil, nil
    b.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging, moved = true, false
            dragStart, startPos = input.Position, b.Position
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if connection then connection:Disconnect() end
                    local p = b.Position
                    apBtnPosStr = string.format("%.4f,%d,%.4f,%d", p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset)
                    saveConfig()
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 8 or math.abs(delta.Y) > 8 then moved = true end
            b.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    b.MouseButton1Click:Connect(function()
        if moved then return end
        local nv = not System.__properties.__autoparry_enabled
        CFG.apEnabled = nv
        AP.setEnabled(nv)
        if repaintFns.apEnabled then pcall(repaintFns.apEnabled) end
        saveConfig()
    end)
end
AP = { System = System, EXT = EXT }
function AP.setEnabled(v)
    v = v == true
    System.__properties.__autoparry_enabled = v
    if v then
        System.autoparry.start()
        ensureApMobile()
    else
        System.autoparry.stop()
        destroyApMobile()
    end
    refreshApMobileText()
end
function AP.setMode(name)
    if name == "Remote" or name == "Keypress" then
        EXT.AutoParryMode = name
    end
end
function AP.setCurve(name)
    for i, curveName in ipairs(System.__config.__curve_names) do
        if curveName == name then
            System.__properties.__curve_mode = i
            return
        end
    end
    System.__properties.__curve_mode = 1
end
function AP.setAccuracy(v)
    v = math.clamp(tonumber(v) or 100, 1, 100)
    System.__properties.__accuracy = v
    update_divisor()
end
function AP.setAnim(v)
    System.__properties.__play_animation = v == true
end
function AP.setDetection(key, v)
    System.__config.__detections[key] = v == true
end
function AP.ping()
    return PingCache
end
function AP.getMobilePos()
    return apBtnPosStr
end
function AP.setMobilePos(s)
    apBtnPosStr = tostring(s or "")
    apMobileApplyPos()
end
local hParry = section(pages.combat, "AUTO PARRY", 1)
addToggle(hParry, "Enabled",
    function() return CFG.apEnabled end,
    function(v) setCfg("apEnabled", v) AP.setEnabled(v) end, "apEnabled")
reg("apEnabled",
    function() return CFG.apEnabled end,
    function(v) CFG.apEnabled = v == true AP.setEnabled(CFG.apEnabled) end)
addCycle(hParry, "Parry Mode", { "Remote", "Keypress" },
    function() return CFG.apMode end,
    function(v) setCfg("apMode", v) AP.setMode(v) end, "apMode")
reg("apMode",
    function() return CFG.apMode end,
    function(v) v = tostring(v) AP.setMode(v) CFG.apMode = EXT.AutoParryMode end)
addSlider(hParry, "Parry Accuracy", 1, 100, 1,
    function() return CFG.apAccuracy end,
    function(v) setCfg("apAccuracy", v) AP.setAccuracy(v) end,
    function(v) return tostring(math.floor(v)) end, "apAccuracy")
reg("apAccuracy",
    function() return CFG.apAccuracy end,
    function(v) CFG.apAccuracy = math.clamp(tonumber(v) or 100, 1, 100) AP.setAccuracy(CFG.apAccuracy) end)
addToggle(hParry, "Play grab animation",
    function() return CFG.apAnim end,
    function(v) setCfg("apAnim", v) AP.setAnim(v) end, "apAnim")
reg("apAnim",
    function() return CFG.apAnim end,
    function(v) CFG.apAnim = v == true AP.setAnim(CFG.apAnim) end)
local hCurve = section(pages.combat, "CURVE MODE", 2)
addCycle(hCurve, "Curve", AP.System.__config.__curve_names,
    function() return CFG.apCurve end,
    function(v) setCfg("apCurve", v) AP.setCurve(v) end, "apCurve")
reg("apCurve",
    function() return CFG.apCurve end,
    function(v) v = tostring(v) AP.setCurve(v) CFG.apCurve = AP.System.__config.__curve_names[AP.System.__properties.__curve_mode] end)
addInfo(hCurve, "Note").Text = "Camera = обычный parry"
local hDet = section(pages.combat, "ABILITY DETECTIONS", 2)
addToggle(hDet, "Skip during Infinity",
    function() return CFG.detInfinity end,
    function(v) setCfg("detInfinity", v) AP.setDetection("__infinity", v) end, "detInfinity")
reg("detInfinity", function() return CFG.detInfinity end,
    function(v) CFG.detInfinity = v == true AP.setDetection("__infinity", CFG.detInfinity) end)
addToggle(hDet, "Skip during Death Slash",
    function() return CFG.detDeathSlash end,
    function(v) setCfg("detDeathSlash", v) AP.setDetection("__deathslash", v) end, "detDeathSlash")
reg("detDeathSlash", function() return CFG.detDeathSlash end,
    function(v) CFG.detDeathSlash = v == true AP.setDetection("__deathslash", CFG.detDeathSlash) end)
addToggle(hDet, "Skip during Time Hole",
    function() return CFG.detTimeHole end,
    function(v) setCfg("detTimeHole", v) AP.setDetection("__timehole", v) end, "detTimeHole")
reg("detTimeHole", function() return CFG.detTimeHole end,
    function(v) CFG.detTimeHole = v == true AP.setDetection("__timehole", CFG.detTimeHole) end)
addToggle(hDet, "Skip during Slashes of Fury",
    function() return CFG.detSoF end,
    function(v) setCfg("detSoF", v) AP.setDetection("__slashesoffury", v) end, "detSoF")
reg("detSoF", function() return CFG.detSoF end,
    function(v) CFG.detSoF = v == true AP.setDetection("__slashesoffury", CFG.detSoF) end)
reg("apBtnPos", function() return AP.getMobilePos() end, function(v) AP.setMobilePos(v) end)
local stLive = section(pages.status, "LIVE (AUTO PARRY)", 1)
local infoEngine = addInfo(stLive, "Engine")
local infoPingL = addInfo(stLive, "Ping")
local infoBallS = addInfo(stLive, "Ball speed")
local infoDistL = addInfo(stLive, "Distance")
local infoTargetL = addInfo(stLive, "Targeted at me")
local infoStateL = addInfo(stLive, "State")
task.spawn(function()
    while gui and gui.Parent do
        task.wait(0.25)
        pcall(function()
            infoEngine.Text = (_G.__noirAPReady) and "captured" or "waiting PRY"
            infoPingL.Text = string.format("%.0f ms", AP.ping())
            local SysMod = AP.System
            local ball = SysMod.ball.get()
            if ball then
                local z = ball:FindFirstChild("zoomies")
                local spd = 0
                if z then pcall(function() spd = z.VectorVelocity.Magnitude end) end
                infoBallS.Text = string.format("%.0f", spd)
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    infoDistL.Text = string.format("%.0f st", (root.Position - ball.Position).Magnitude)
                else
                    infoDistL.Text = "-"
                end
                infoTargetL.Text = (ball:GetAttribute("target") == LocalPlayer.Name) and "yes" or "no"
            else
                infoBallS.Text = "-"
                infoDistL.Text = "-"
                infoTargetL.Text = "no ball"
            end
            infoStateL.Text = SysMod.__properties.__autoparry_enabled and "enabled" or "disabled"
        end)
    end
end)
local cfgPage = pages.config
local hUi = section(cfgPage, "INTERFACE", 1)
addKeybind(hUi, "Toggle menu", function() return CFG.uiKey end, function(v) setCfg("uiKey", v) end, "uiKey")
reg("uiKey", function() return CFG.uiKey end, function(v) CFG.uiKey = tostring(v) end)
addToggle(hUi, "Mobile button", function() return CFG.showMobileBtn end, function(v) setCfg("showMobileBtn", v) end, "showMobileBtn")
reg("showMobileBtn", function() return CFG.showMobileBtn end, function(v) CFG.showMobileBtn = v == true end)
reg("winPos", winPosString, applyWinPos)
local hAbout = section(cfgPage, "ABOUT", 2)
do
    local v = addInfo(hAbout, "Build")
    v.Text = "menu-only template"
end
do
    local row = New("Frame", {
        Parent = hAbout, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1,
        LayoutOrder = nextOrder(), ZIndex = 5,
    })
    local reset = New("TextButton", {
        Parent = row, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.btn,
        BackgroundTransparency = .3, Text = "RESET SETTINGS", TextColor3 = C.accent2,
        TextSize = 12, Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 6,
    })
    corner(reset, 8)
    stroke(reset, C.border, .4)
    reset.MouseButton1Click:Connect(function()
        for k, v in pairs(DEFAULTS) do CFG[k] = v end
        saveConfig()
    end)
end
local function keyOf(name)
    local ok, key = pcall(function() return Enum.KeyCode[name] end)
    if ok then return key end
    return Enum.KeyCode.Unknown
end
UserInputService.InputBegan:Connect(function(input, processed)
    if captureKey then
        captureKey(input.KeyCode)
        captureKey = nil
        return
    end
    if processed then return end
    if input.KeyCode == keyOf(CFG.uiKey) then
        win.Visible = not win.Visible
    end
end)
local mobileBtn
task.spawn(function()
    while gui.Parent do
        task.wait(0.5)
        local want = CFG.showMobileBtn
        if want and not mobileBtn then
            local holder = New("ScreenGui", { Name = "NoirBBMobile", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999 })
            pcall(function() holder.Parent = guiParent end)
            local b = New("TextButton", {
                Parent = holder, Size = UDim2.fromOffset(56, 56), Position = UDim2.new(1, -76, 1, -150),
                BackgroundColor3 = C.accent, BackgroundTransparency = .15, Text = "N",
                TextColor3 = Color3.fromRGB(10, 9, 8), TextSize = 22, Font = Enum.Font.GothamBold,
                AutoButtonColor = false,
            })
            corner(b, 28)
            stroke(b, C.accent2, .35)
            b.MouseButton1Click:Connect(function() win.Visible = not win.Visible end)
            mobileBtn = { gui = holder, btn = b }
        elseif not want and mobileBtn then
            pcall(function() mobileBtn.gui:Destroy() end)
            mobileBtn = nil
        end
    end
end)
loadConfig()
for _, fn in pairs(repaintFns) do pcall(fn) end
selectPage("combat")
