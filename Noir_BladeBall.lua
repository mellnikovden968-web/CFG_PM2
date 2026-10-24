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
    apAccuracy    = 60,
    apTrigger     = "Auto",
    apBtnPos      = "",
    wsOn          = false,
    wsValue       = 40,
    jpOn          = false,
    jpValue       = 140,
    infJump       = false,
    flyOn         = false,
    flySpeed      = 60,
    fov           = 70,
    fpsBoost      = false,
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
local Players2 = LocalPlayer
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
    print("[AP] BAC spoof hooks:", ok_hook and "ON" or "FAILED")
end
local ControlModule = nil
pcall(function()
    local pm = Players.PlayerScripts:WaitForChild("PlayerModule", 10)
    if pm then
        ControlModule = require(pm:WaitForChild("ControlModule", 10))
    end
end)
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
local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end
local function apGetBall()
    local balls = workspace:FindFirstChild("Balls")
    if not balls then return nil end
    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute("realBall") then
            return ball
        end
    end
    return nil
end
local function apBallSpeed(ball)
    if not ball then return 0 end
    local z = ball:FindFirstChild("zoomies")
    if not z then return 0 end
    local ok, v = pcall(function() return z.VectorVelocity.Magnitude end)
    return (ok and type(v) == "number") and v or 0
end
local VIM = game:GetService("VirtualInputManager")
local triggerEntries = {}
local triggerEntriesAt = 0
local triggerAnnounced = false
local TRIGGER_KEYS = { "parry", "block", "attack", "action", "hitbutton", "slash" }
local function scanTriggerButtons(force)
    if not getconnections then return end
    if not force and tick() - triggerEntriesAt < 3 then return end
    triggerEntriesAt = tick()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    local found = {}
    for _, inst in ipairs(pg:GetDescendants()) do
        if inst:IsA("GuiButton") then
            local n = string.lower(inst.Name)
            for _, k in ipairs(TRIGGER_KEYS) do
                if n:find(k, 1, true) then
                    local okc, conns = pcall(function() return getconnections(inst.MouseButton1Click) end)
                    if okc and conns and #conns > 0 then
                        table.insert(found, { btn = inst, conns = conns, name = inst:GetFullName() })
                    end
                    break
                end
            end
        end
    end
    triggerEntries = found
    if #found > 0 and not triggerAnnounced then
        triggerAnnounced = true
        for _, e in ipairs(found) do
            print("[AP] trigger button:", e.name)
        end
    end
end
local WANT_CTRL = { "sword", "parry", "controller", "combat", "weapon", "input" }
local WANT_FN_P1 = { "parry", "attempt", "block", "deflect", "riposte", "tapparry" }
local WANT_FN_P2 = { "attack", "swing", "slash", "swinglade", "ability" }
local CtrlFn = nil
local CtrlPath = nil
local ctrlScanned = false
local ctrlCandidates = {}
local function hasWord(s, list)
    s = string.lower(tostring(s))
    for _, w in ipairs(list) do
        if string.find(s, w, 1, true) then return true end
    end
    return false
end
local function scanTbl(t, path, words, depth)
    if CtrlFn then return end
    depth = depth or 0
    for k, v in pairs(t) do
        if type(v) == "function" and hasWord(k, words) then
            CtrlFn = v
            CtrlPath = path .. "." .. tostring(k)
            return
        end
    end
    if depth < 1 then
        for k, v in pairs(t) do
            if CtrlFn then return end
            if type(v) == "table" then
                for k2, f in pairs(v) do
                    if type(f) == "function" and hasWord(k2, words) then
                        CtrlFn = f
                        CtrlPath = path .. "." .. tostring(k) .. "." .. tostring(k2)
                        table.insert(ctrlCandidates, CtrlPath)
                        return
                    end
                end
            end
        end
    end
end
local function findCtrlTrigger(force)
    if ctrlScanned and not force then return end
    ctrlScanned = true
    local sources = {}
    if type(getsenv) == "function" then
        pcall(function()
            local containers = {}
            local pscripts = LocalPlayer:FindFirstChild("PlayerScripts")
            if pscripts then table.insert(containers, pscripts) end
            for _, cont in ipairs(containers) do
                for _, d in ipairs(cont:GetDescendants()) do
                    if d:IsA("LocalScript") and (d.Enabled or d.Disabled == false) and hasWord(d.Name, WANT_CTRL) then
                        local oke, env = pcall(getsenv, d)
                        if oke and type(env) == "table" then
                            table.insert(sources, { tbl = env, path = "env:" .. d.Name })
                        end
                    end
                end
            end
        end)
    end
    if type(getloadedmodules) == "function" then
        pcall(function()
            for _, m in ipairs(getloadedmodules()) do
                if m:IsA("ModuleScript") and hasWord(m.Name, WANT_CTRL) then
                    local okm, tbl = pcall(function() return require(m) end)
                    if okm and type(tbl) == "table" then
                        table.insert(sources, { tbl = tbl, path = "mod:" .. m.Name })
                    end
                end
            end
        end)
    end
    for _, src in ipairs(sources) do
        scanTbl(src.tbl, src.path, WANT_FN_P1, 0)
        if CtrlFn then break end
    end
    if not CtrlFn then
        for _, src in ipairs(sources) do
            scanTbl(src.tbl, src.path, WANT_FN_P2, 0)
            if CtrlFn then break end
        end
    end
    if CtrlFn then
        print("[AP] ctrl trigger: " .. tostring(CtrlPath))
    else
        print("[AP] ctrl trigger: not found (" .. tostring(#sources) .. " sources scanned)")
    end
end
task.delay(4, function() pcall(findCtrlTrigger) end)
local function apFire()
    local char, root = getChar()
    if not char or not root then return end
    local mode = tostring(CFG.apTrigger or "Auto")
    if mode == "Auto" then
        if not ctrlScanned then pcall(findCtrlTrigger) end
        if CtrlFn then mode = "Ctrl"
        else
            scanTriggerButtons(false)
            mode = (#triggerEntries > 0) and "Button" or "Tap"
        end
    end
    if mode == "Ctrl" then
        if not ctrlScanned then pcall(findCtrlTrigger) end
        if CtrlFn then
            task.spawn(function() pcall(CtrlFn) end)
            return
        end
        mode = "Tap"
    end
    if mode == "Button" then
        scanTriggerButtons(false)
        if #triggerEntries > 0 then
            for _, e in ipairs(triggerEntries) do
                for _, conn in ipairs(e.conns) do
                    task.spawn(function()
                        pcall(function() conn:Fire() end)
                    end)
                end
            end
            return
        end
        mode = "Tap"
    end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local mx = vp.X * 0.5 + math.random(-24, 24)
    local my = vp.Y * 0.5 + math.random(-24, 24)
    if IS_MOBILE then
        local okTap = pcall(function()
            local p1 = Vector2.new(mx, my)
            VIM:SendTouchEvent(1, 0, p1)
            task.wait(0.02 + math.random() * 0.05)
            local p2 = Vector2.new(mx + math.random(-3, 3), my + math.random(-3, 3))
            VIM:SendTouchEvent(1, 2, p2)
        end)
        if not okTap then
            pcall(function() VIM:SendTouchTap(mx, my, false) end)
        end
    else
        pcall(function()
            VIM:SendMouseButtonEvent(mx, my, 0, true, game, 1)
            task.wait(0.02 + math.random() * 0.05)
            VIM:SendMouseButtonEvent(mx, my, 0, false, game, 1)
        end)
    end
end
local APEng = { enabled = false, conn = nil, parried = false, lastFire = 0, fires = 0 }
local function apReach(ballSpeed)
    local acc = math.clamp(tonumber(CFG.apAccuracy) or 60, 1, 100)
    local pingc = math.clamp(PingCache / 10, 5, 20)
    local capped = math.min(math.max(ballSpeed - 9.5, 0), 650)
    local mult = 0.7 + (acc - 1) * 0.0035353535353535
    local div = (2.4 + capped * 0.002) * mult
    return pingc + math.max(ballSpeed / div, 9.5)
end
function APEng.start()
    if APEng.conn then APEng.conn:Disconnect() APEng.conn = nil end
    APEng.conn = RunService.PreSimulation:Connect(function()
        if not APEng.enabled then return end
        local char, root = getChar()
        if not char or not root then APEng.parried = false return end
        local ball = apGetBall()
        if not ball then APEng.parried = false return end
        local target = ball:GetAttribute("target")
        if target ~= LocalPlayer.Name then
            APEng.parried = false
            return
        end
        if APEng.parried then return end
        local dist = (root.Position - ball.Position).Magnitude
        local speed = apBallSpeed(ball)
        if dist <= apReach(speed) and tick() - APEng.lastFire >= 0.06 then
            APEng.parried = true
            APEng.lastFire = tick()
            APEng.fires = APEng.fires + 1
            if APEng.fires == 1 or APEng.fires % 25 == 0 then
                print(string.format("[AP] FIRE x%d dist=%.1f speed=%.0f", APEng.fires, dist, speed))
            end
            task.spawn(apFire)
        end
    end)
end
function APEng.stop()
    if APEng.conn then APEng.conn:Disconnect() APEng.conn = nil end
end
local fly = { bv = nil, bg = nil, conn = nil }
local function flySet(on)
    local char, root, hum = getChar()
    if on then
        if not root then return end
        if not fly.bv then
            fly.bv = Instance.new("BodyVelocity")
            fly.bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        end
        if not fly.bg then
            fly.bg = Instance.new("BodyGyro")
            fly.bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            fly.bg.P = 5e4
            fly.bg.D = 600
        end
        fly.bv.Velocity = Vector3.zero
        fly.bv.Parent = root
        fly.bg.CFrame = root.CFrame
        fly.bg.Parent = root
        if fly.conn then fly.conn:Disconnect() end
        fly.conn = RunService.Heartbeat:Connect(function()
            local cam = workspace.CurrentCamera
            if not cam or not root or not root.Parent then return end
            local mv = Vector3.zero
            if ControlModule then
                local okm, r = pcall(function() return ControlModule:GetMoveVector() end)
                if okm and r then mv = r end
            end
            local speed = tonumber(CFG.flySpeed) or 60
            fly.bv.Velocity = cam.CFrame:VectorToWorldSpace(mv) * speed
            fly.bg.CFrame = CFrame.new(root.Position, root.Position + cam.CFrame.LookVector)
        end)
    else
        if fly.conn then fly.conn:Disconnect() fly.conn = nil end
        if fly.bv then fly.bv:Destroy() fly.bv = nil end
        if fly.bg then fly.bg:Destroy() fly.bg = nil end
    end
end
LocalPlayer.CharacterAdded:Connect(function()
    if CFG.flyOn then
        task.wait(1)
        if CFG.flyOn then flySet(true) end
    end
end)
task.spawn(function()
    while true do
        task.wait(0.25)
        local char, root, hum = getChar()
        if hum then
            if CFG.wsOn then
                pcall(function() hum.WalkSpeed = tonumber(CFG.wsValue) or 40 end)
            end
            if CFG.jpOn then
                pcall(function()
                    pcall(function() hum.UseJumpPower = true end)
                    hum.JumpPower = tonumber(CFG.jpValue) or 140
                end)
            end
        end
    end
end)
UserInputService.JumpRequest:Connect(function()
    if not CFG.infJump then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end)
local lastFovApplied = -1
task.spawn(function()
    while true do
        task.wait(0.6)
        local f = tonumber(CFG.fov) or 70
        if f ~= lastFovApplied then
            lastFovApplied = f
            pcall(function()
                local cam = workspace.CurrentCamera
                if cam then cam.FieldOfView = f end
            end)
        end
    end
end)
local Lighting = game:GetService("Lighting")
local fpsState = {}
local function fpsApply(on)
    if on then
        pcall(function()
            fpsState.shadows = Lighting.GlobalShadows
            Lighting.GlobalShadows = false
        end)
        for _, eff in ipairs(Lighting:GetChildren()) do
            if eff:IsA("BloomEffect") or eff:IsA("BlurEffect") or eff:IsA("ColorCorrectionEffect")
               or eff:IsA("DepthOfFieldEffect") or eff:IsA("SunRaysEffect") then
                pcall(function()
                    if eff.Enabled then
                        fpsState[eff] = true
                        eff.Enabled = false
                    end
                end)
            end
        end
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
    else
        pcall(function()
            if fpsState.shadows ~= nil then Lighting.GlobalShadows = fpsState.shadows end
        end)
        for k in pairs(fpsState) do
            if typeof(k) == "Instance" then
                pcall(function() k.Enabled = true end)
            end
            fpsState[k] = nil
        end
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
        if APEng.enabled then
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
        local nv = not APEng.enabled
        AP.setEnabled(nv)
        if repaintFns.apEnabled then pcall(repaintFns.apEnabled) end
        saveConfig()
    end)
end
AP = { Engine = APEng }
function AP.setEnabled(v)
    APEng.enabled = v == true
    CFG.apEnabled = APEng.enabled
    if APEng.enabled then
        APEng.start()
        ensureApMobile()
        scanTriggerButtons(true)
    else
        APEng.stop()
        destroyApMobile()
    end
    refreshApMobileText()
end
function AP.setTrigger(name)
    if name == "Auto" or name == "Button" or name == "Tap" or name == "Ctrl" then
        CFG.apTrigger = name
    else
        CFG.apTrigger = "Auto"
    end
    scanTriggerButtons(true)
    if name == "Ctrl" and not ctrlScanned then task.spawn(function() pcall(findCtrlTrigger) end) end
end
function AP.ping()
    return PingCache
end
function AP.triggerText()
    scanTriggerButtons(false)
    local base = tostring(CFG.apTrigger or "Auto")
    if CtrlFn then
        return base .. " (ctrl)"
    end
    if #triggerEntries > 0 then
        return base .. " (btn x" .. tostring(#triggerEntries) .. ")"
    end
    return base .. " (tap)"
end
function AP.ballInfo()
    local ball = apGetBall()
    if not ball then return nil end
    return ball
end
AP.getBallSpeed = apBallSpeed
AP.flySet = flySet
AP.fpsApply = fpsApply
function AP.getMobilePos()
    return apBtnPosStr
end
function AP.setMobilePos(s)
    apBtnPosStr = tostring(s or "")
    apMobileApplyPos()
end
_G.__noirAPReady = true
local hParry = section(pages.combat, "AUTO PARRY", 1)
addToggle(hParry, "Enabled",
    function() return CFG.apEnabled end,
    function(v) AP.setEnabled(v) end, "apEnabled")
reg("apEnabled",
    function() return CFG.apEnabled end,
    function(v) CFG.apEnabled = v == true AP.setEnabled(CFG.apEnabled) end)
addSlider(hParry, "Parry reach", 1, 100, 1,
    function() return CFG.apAccuracy end,
    function(v) setCfg("apAccuracy", v) end,
    function(v) return tostring(math.floor(v)) end, "apAccuracy")
reg("apAccuracy",
    function() return CFG.apAccuracy end,
    function(v) CFG.apAccuracy = math.clamp(tonumber(v) or 60, 1, 100) end)
addCycle(hParry, "Trigger", { "Auto", "Ctrl", "Button", "Tap" },
    function() return CFG.apTrigger end,
    function(v) AP.setTrigger(v) if repaintFns.apTrigger then pcall(repaintFns.apTrigger) end saveConfig() end, "apTrigger")
reg("apTrigger",
    function() return CFG.apTrigger end,
    function(v) AP.setTrigger(tostring(v)) end)
reg("apBtnPos", function() return AP.getMobilePos() end, function(v) AP.setMobilePos(v) end)
local hMove = section(pages.combat, "MOVEMENT", 2)
addToggle(hMove, "Speed",
    function() return CFG.wsOn end,
    function(v) setCfg("wsOn", v) end, "wsOn")
reg("wsOn", function() return CFG.wsOn end, function(v) CFG.wsOn = v == true end)
addSlider(hMove, "WalkSpeed", 16, 250, 1,
    function() return CFG.wsValue end,
    function(v) setCfg("wsValue", v) end,
    function(v) return tostring(math.floor(v)) end, "wsValue")
reg("wsValue", function() return CFG.wsValue end, function(v) CFG.wsValue = math.clamp(tonumber(v) or 40, 16, 250) end)
addToggle(hMove, "Jump power",
    function() return CFG.jpOn end,
    function(v) setCfg("jpOn", v) end, "jpOn")
reg("jpOn", function() return CFG.jpOn end, function(v) CFG.jpOn = v == true end)
addSlider(hMove, "JumpPower", 50, 400, 5,
    function() return CFG.jpValue end,
    function(v) setCfg("jpValue", v) end,
    function(v) return tostring(math.floor(v)) end, "jpValue")
reg("jpValue", function() return CFG.jpValue end, function(v) CFG.jpValue = math.clamp(tonumber(v) or 140, 50, 400) end)
addToggle(hMove, "Infinite jump",
    function() return CFG.infJump end,
    function(v) setCfg("infJump", v) end, "infJump")
reg("infJump", function() return CFG.infJump end, function(v) CFG.infJump = v == true end)
local hFly = section(pages.combat, "FLIGHT", 2)
addToggle(hFly, "Fly",
    function() return CFG.flyOn end,
    function(v) setCfg("flyOn", v) AP.flySet(v) end, "flyOn")
reg("flyOn", function() return CFG.flyOn end, function(v) CFG.flyOn = v == true if CFG.flyOn then AP.flySet(true) end end)
addSlider(hFly, "Fly speed", 20, 300, 5,
    function() return CFG.flySpeed end,
    function(v) setCfg("flySpeed", v) end,
    function(v) return tostring(math.floor(v)) end, "flySpeed")
reg("flySpeed", function() return CFG.flySpeed end, function(v) CFG.flySpeed = math.clamp(tonumber(v) or 60, 20, 300) end)
local hVis = section(pages.combat, "VISUALS", 2)
addSlider(hVis, "FOV", 60, 120, 1,
    function() return CFG.fov end,
    function(v) setCfg("fov", v) end,
    function(v) return tostring(math.floor(v)) end, "fov")
reg("fov", function() return CFG.fov end, function(v) CFG.fov = math.clamp(tonumber(v) or 70, 60, 120) end)
addToggle(hVis, "FPS booster",
    function() return CFG.fpsBoost end,
    function(v) setCfg("fpsBoost", v) AP.fpsApply(v) end, "fpsBoost")
reg("fpsBoost", function() return CFG.fpsBoost end, function(v) CFG.fpsBoost = v == true if CFG.fpsBoost then AP.fpsApply(true) end end)
local stLive = section(pages.status, "LIVE (AUTO PARRY)", 1)
local infoTrig = addInfo(stLive, "Trigger")
local infoPingL = addInfo(stLive, "Ping")
local infoBallS = addInfo(stLive, "Ball speed")
local infoDistL = addInfo(stLive, "Distance")
local infoTargetL = addInfo(stLive, "Targeted at me")
local infoStateL = addInfo(stLive, "State")
task.spawn(function()
    while gui and gui.Parent do
        task.wait(0.25)
        pcall(function()
            infoTrig.Text = AP.triggerText()
            infoPingL.Text = string.format("%.0f ms", AP.ping())
            local ball = AP.ballInfo()
            if ball then
                infoBallS.Text = string.format("%.0f", AP.getBallSpeed(ball))
                local char, root = (function()
                    local c = LocalPlayer.Character
                    if not c then return nil, nil end
                    return c, c:FindFirstChild("HumanoidRootPart")
                end)()
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
            infoStateL.Text = AP.Engine.enabled and ("on, fires x" .. tostring(AP.Engine.fires)) or "off"
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
