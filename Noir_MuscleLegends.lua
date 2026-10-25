local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer

local C = {
    base = Color3.fromRGB(10, 9, 8), surface = Color3.fromRGB(15, 13, 11),
    btn = Color3.fromRGB(20, 17, 14), off = Color3.fromRGB(30, 26, 22),
    border = Color3.fromRGB(50, 34, 23), accent = Color3.fromRGB(224, 116, 24),
    accent2 = Color3.fromRGB(255, 170, 54), text = Color3.fromRGB(245, 242, 238),
    dim = Color3.fromRGB(130, 124, 118), ok = Color3.fromRGB(139, 224, 104),
    err = Color3.fromRGB(240, 110, 110),
}

local penv = (type(getgenv) == "function" and getgenv()) or _G
if penv.__NoirMLLoaded then return end
penv.__NoirMLLoaded = true

local function charParts()
    local ch = LP.Character
    if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    local root = ch:FindFirstChild("HumanoidRootPart")
    if hum and root and hum.Health > 0 then return ch, hum, root end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NoirML"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 200
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local alive = true
ScreenGui.Destroying:Connect(function() alive = false end)

local function New(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then o[k] = v end
    end
    o.Parent = parent
    return o
end
local function corner(o, r) return New("UICorner", { CornerRadius = UDim.new(0, r), Parent = o }) end
local function stroke(o, col, tr, th)
    return New("UIStroke", { Color = col or C.border, Transparency = tr or 0.4, Thickness = th or 1, Parent = o })
end

local notifyHolder = New("Frame", {
    BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -14, 0, 14), Size = UDim2.fromOffset(250, 0),
}, ScreenGui)
New("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Right }, notifyHolder)
local function Notify(text, dur)
    task.spawn(function()
        pcall(function()
            local f = New("Frame", {
                Size = UDim2.fromOffset(250, 44), BackgroundColor3 = C.surface,
                BackgroundTransparency = 0.08, BorderSizePixel = 0,
            }, notifyHolder)
            corner(f, 10)
            stroke(f, C.accent, 0.45, 1)
            New("TextLabel", {
                BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0),
                Font = Enum.Font.GothamBold, Text = tostring(text), TextColor3 = C.text, TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
            }, f)
            f.Position = UDim2.new(1, 260, 0, 0)
            TweenService:Create(f, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
            task.wait(dur or 2.4)
            TweenService:Create(f, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
            task.wait(0.25)
            f:Destroy()
        end)
    end)
end

local function draggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local Win = New("Frame", {
    Name = "Window", Size = UDim2.fromOffset(500, 330), AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.base, BackgroundTransparency = 0.06,
    BorderSizePixel = 0,
}, ScreenGui)
corner(Win, 14)
stroke(Win, C.accent, 0.55, 1.2)

local TopBar = New("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1 }, Win)
local dot = New("Frame", { Size = UDim2.fromOffset(9, 9), Position = UDim2.fromOffset(12, 13), BackgroundColor3 = C.accent, BorderSizePixel = 0 }, TopBar)
corner(dot, 9)
New("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(28, 0), Size = UDim2.fromOffset(220, 34),
    Font = Enum.Font.GothamBold, Text = "NOIR · MUSCLE LEGENDS", TextColor3 = C.text, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
}, TopBar)
local hideBtn = New("TextButton", {
    Position = UDim2.new(1, -34, 0, 6), Size = UDim2.fromOffset(24, 22), BackgroundColor3 = C.btn,
    Text = "-", Font = Enum.Font.GothamBold, TextColor3 = C.accent2, TextSize = 13, AutoButtonColor = false,
}, TopBar)
corner(hideBtn, 8)
stroke(hideBtn, C.border, 0.5, 1)

local miniBtn = New("Frame", {
    Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 16, 0.5, -23), BackgroundColor3 = C.base,
    BackgroundTransparency = 0.06, BorderSizePixel = 0, Visible = false, Active = true,
}, ScreenGui)
corner(miniBtn, 23)
stroke(miniBtn, C.accent, 0.35, 1.5)
local miniLbl = New("TextLabel", {
    BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBold,
    Text = "N", TextColor3 = C.accent, TextSize = 22,
}, miniBtn)
draggable(miniBtn)
local function openMini(v)
    Win.Visible = not v
    miniBtn.Visible = v
end
hideBtn.MouseButton1Click:Connect(function() openMini(true) end)
miniBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        task.delay(0.05, function()
            if (os.clock() - (miniBtn:GetAttribute("dragT") or 0)) > 0.2 then return end
        end)
        local startP = i.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End and (i.Position - startP).Magnitude < 8 then
                openMini(false)
            end
        end)
    end
end)

local TabBar = New("Frame", {
    Position = UDim2.fromOffset(0, 34), Size = UDim2.new(0, 104, 1, -34), BackgroundTransparency = 1,
}, Win)
New("UIListLayout", { Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, TabBar)
local PageHost = New("Frame", {
    Position = UDim2.fromOffset(110, 36), Size = UDim2.new(1, -120, 1, -48), BackgroundTransparency = 1,
}, Win)

draggable(Win, TopBar)

local pages = {}
local currentPage = nil
local tabCount = 0

local function AddTab(name)
    tabCount += 1
    local b = New("TextButton", {
        Size = UDim2.new(0, 96, 0, 30), BackgroundColor3 = C.btn, BackgroundTransparency = 0.15,
        Text = name, Font = Enum.Font.GothamBold, TextColor3 = C.dim, TextSize = 10, AutoButtonColor = false,
        LayoutOrder = tabCount,
    }, TabBar)
    corner(b, 8)
    local bst = stroke(b, C.border, 0.6, 1)
    local page = New("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = C.accent, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, ScrollingDirection = Enum.ScrollingDirection.Y,
    }, PageHost)
    New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    New("UIPadding", { PaddingRight = UDim.new(0, 4) }, page)
    pages[name] = { btn = b, frame = page, stroke = bst }
    b.MouseButton1Click:Connect(function()
        for n, p in pairs(pages) do
            local on = (n == name)
            p.frame.Visible = on
            p.btn.TextColor3 = on and C.accent2 or C.dim
            p.btn.BackgroundColor3 = on and C.off or C.btn
            p.stroke.Color = on and C.accent or C.border
        end
        currentPage = name
    end)
    if tabCount == 1 then b.MouseButton1Click:Wait() end
    return page
end

local itemOrder = 0
local function rowBase(page, h)
    itemOrder += 1
    local f = New("Frame", {
        Size = UDim2.new(1, -2, 0, h), BackgroundColor3 = C.surface, BackgroundTransparency = 0.1,
        BorderSizePixel = 0, LayoutOrder = itemOrder,
    }, page)
    corner(f, 8)
    stroke(f, C.border, 0.65, 1)
    return f
end

local function AddLabel(page, text)
    local f = rowBase(page, 22)
    f.BackgroundTransparency = 1
    local s = f:FindFirstChildOfClass("UIStroke")
    if s then s:Destroy() end
    New("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(6, 0),
        Font = Enum.Font.GothamBold, Text = text, TextColor3 = C.dim, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    return f
end

local ToggleRegistry = {}
local function AddToggle(page, title, default, cb)
    local state = default == true
    local f = rowBase(page, 30)
    New("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -64, 1, 0),
        Font = Enum.Font.GothamBold, Text = title, TextColor3 = C.text, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    local pill = New("Frame", {
        Position = UDim2.new(1, -44, 0.5, -9), Size = UDim2.fromOffset(34, 18),
        BackgroundColor3 = state and C.accent or C.off, BorderSizePixel = 0,
    }, f)
    corner(pill, 9)
    stroke(pill, state and C.accent or C.border, 0.5, 1)
    local knob = New("Frame", {
        Size = UDim2.fromOffset(12, 12), Position = state and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3),
        BackgroundColor3 = C.text, BorderSizePixel = 0,
    }, pill)
    corner(knob, 6)
    local function set(v, fire)
        state = v
        pill.BackgroundColor3 = v and C.accent or C.off
        TweenService:Create(knob, TweenInfo.new(0.12), { Position = v and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3) }):Play()
        if fire ~= false then task.spawn(cb, v) end
    end
    local btn = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, f)
    btn.MouseButton1Click:Connect(function() set(not state) end)
    ToggleRegistry[title] = ToggleRegistry[title] or { set = set, get = function() return state end }
    ToggleRegistry[title].set = set
    ToggleRegistry[title].get = function() return state end
    return { Set = function(v) set(v, false) end, Get = function() return state end }
end

local function AddSlider(page, title, min, max, default, cb)
    local value = default or min
    local f = rowBase(page, 42)
    New("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -80, 0, 22),
        Font = Enum.Font.GothamBold, Text = title, TextColor3 = C.text, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    local val = New("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(1, -70, 0, 0), Size = UDim2.fromOffset(60, 22),
        Font = Enum.Font.GothamBold, Text = tostring(value), TextColor3 = C.accent2, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, f)
    local track = New("Frame", {
        Position = UDim2.new(0, 10, 0, 28), Size = UDim2.new(1, -20, 0, 5),
        BackgroundColor3 = C.off, BorderSizePixel = 0,
    }, f)
    corner(track, 3)
    local fill = New("Frame", { Size = UDim2.new((value - min) / (max - min), 0, 1, 0), BackgroundColor3 = C.accent, BorderSizePixel = 0 }, track)
    corner(fill, 3)
    local sliding = false
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + rel * (max - min) + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        val.Text = tostring(value)
        task.spawn(cb, value)
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = false end
    end)
    return { Get = function() return value end }
end

local function AddButton(page, title, cb)
    local f = rowBase(page, 30)
    f.BackgroundColor3 = C.btn
    local lbl = New("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBold,
        Text = title, TextColor3 = C.accent2, TextSize = 11,
    }, f)
    local btn = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, f)
    btn.MouseButton1Click:Connect(function() task.spawn(cb) end)
    return { SetText = function(t) lbl.Text = t end }
end

local function AddDropdown(page, title, options, cb)
    local f = rowBase(page, 30)
    f.ClipsDescendants = false
    New("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.4, 0, 1, 0),
        Font = Enum.Font.GothamBold, Text = title, TextColor3 = C.text, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    local sel = New("TextButton", {
        Position = UDim2.new(0.45, 0, 0.5, -11), Size = UDim2.new(0.52, -10, 0, 22),
        BackgroundColor3 = C.btn, Text = options[1] or "?", Font = Enum.Font.GothamBold,
        TextColor3 = C.accent2, TextSize = 10, AutoButtonColor = false,
    }, f)
    corner(sel, 7)
    stroke(sel, C.border, 0.5, 1)
    local listFrame = New("ScrollingFrame", {
        Position = UDim2.new(0.45, 0, 1, 4), Size = UDim2.new(0.52, -10, 0, math.min(6, #options) * 24),
        BackgroundColor3 = C.surface, BorderSizePixel = 0, Visible = false, ZIndex = 20,
        ScrollBarThickness = 2, ScrollBarImageColor3 = C.accent, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, f)
    corner(listFrame, 8)
    stroke(listFrame, C.accent, 0.4, 1)
    New("UIListLayout", { Padding = UDim.new(0, 2) }, listFrame)
    local open = false
    local selected = options[1]
    for _, opt in ipairs(options) do
        local ob = New("TextButton", {
            Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = opt,
            Font = Enum.Font.GothamBold, TextColor3 = C.dim, TextSize = 10, ZIndex = 21, AutoButtonColor = false,
        }, listFrame)
        ob.MouseButton1Click:Connect(function()
            selected = opt
            sel.Text = opt
            open = false
            listFrame.Visible = false
            task.spawn(cb, opt)
        end)
    end
    sel.MouseButton1Click:Connect(function()
        open = not open
        listFrame.Visible = open
    end)
    return {
        Get = function() return selected end,
        SetOptions = function(newOptions)
            for _, child in ipairs(listFrame:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            selected = newOptions[1]
            sel.Text = selected or "?"
            listFrame.Size = UDim2.new(0.52, -10, 0, math.min(6, math.max(1, #newOptions)) * 24)
            for _, opt in ipairs(newOptions) do
                local ob = New("TextButton", {
                    Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = opt,
                    Font = Enum.Font.GothamBold, TextColor3 = C.dim, TextSize = 10, ZIndex = 21, AutoButtonColor = false,
                }, listFrame)
                ob.MouseButton1Click:Connect(function()
                    selected = opt
                    sel.Text = opt
                    open = false
                    listFrame.Visible = false
                    task.spawn(cb, opt)
                end)
            end
        end,
    }
end

local MACHINES = {
    { section = "Halloween Event", label = "Hallowed Bar Lift", object = "Hallowed Bar Lift", eventObject = "HalloweenMap", fallback = CFrame.new(5740.0498, 107.7155, 6414.3057) },
    { section = "Halloween Event", label = "Hallowed Squat", object = "Hallowed Squat", eventObject = "HalloweenMap", fallback = CFrame.new(4812.0342, 112.3051, 5839.0522) },
    { section = "Halloween Event", label = "Hallowed Bench", object = "Hallowed Bench", eventObject = "HalloweenMap", fallback = CFrame.new(5314.5537, 126.1767, 6807.8208) },
    { section = "Halloween Event", label = "Hallowed Boulder", object = "Hallowed Boulder", eventObject = "HalloweenMap", fallback = CFrame.new(5292.2090, 105.2552, 5680.9731) },
    { section = "Halloween Event", label = "Hallowed Pullup", object = "Hallowed Pullup", eventObject = "HalloweenMap", fallback = CFrame.new(5016.0200, 109.1427, 6934.3916) },
    { section = "Overcharge Event", label = "Overcharged Bar Lift", object = "Overcharged Bar Lift", eventObject = "OverchargedMap" },
    { section = "Overcharge Event", label = "Overcharged Squat", object = "Overcharged Squat", eventObject = "OverchargedMap" },
    { section = "Overcharge Event", label = "Overcharged Bench", object = "Overcharged Bench", eventObject = "OverchargedMap" },
    { section = "Overcharge Event", label = "Overcharged Boulder", object = "Overcharged Boulder", eventObject = "OverchargedMap" },
    { section = "Industrial", label = "Industrial Bar Lift", object = "Industrial Bar Lift", fallback = CFrame.new(-5492.7051, 82.9405, 4643.6421) },
    { section = "Industrial", label = "Industrial Bench", object = "Industrial Bench", fallback = CFrame.new(-5014.7197, 101.4016, 4467.3472) },
    { section = "Industrial", label = "Industrial Boulder", object = "Industrial Boulder", fallback = CFrame.new(-5456.4297, 85.4802, 5231.5352) },
    { section = "Industrial", label = "Industrial Squat", object = "Industrial Squat", fallback = CFrame.new(-5422.1152, 76.9691, 5443.0771) },
    { section = "Jungle Gym", label = "Jungle Bar Lift", object = "Jungle Bar Lift", fallback = CFrame.new(-8652.8672, 29.2667, 2089.2617) },
    { section = "Jungle Gym", label = "Jungle Bench", object = "Jungle Bench", fallback = CFrame.new(-8174.8818, 47.7279, 1912.9667) },
    { section = "Jungle Gym", label = "Jungle Boulder", object = "Jungle Boulder", fallback = CFrame.new(-8616.5918, 31.8064, 2677.1548) },
    { section = "Jungle Gym", label = "Jungle Squat", object = "Jungle Squat", fallback = CFrame.new(-8377.2773, 34.8563, 2863.6965) },
    { section = "Legends Gym", label = "Legends Lift", object = "Legends Lift", fallback = CFrame.new(4532.2178, 1012.4910, -4002.7122) },
    { section = "Legends Gym", label = "Legends Press", object = "Legends Press", fallback = CFrame.new(4109.9131, 1012.2094, -3802.1533) },
    { section = "Legends Gym", label = "Legends Squat", object = "Legends Squat", fallback = CFrame.new(4437.1465, 1015.8768, -3633.6763) },
    { section = "Legends Gym", label = "Legends Throw", object = "Legends Throw", fallback = CFrame.new(4189.9614, 1004.3785, -3903.0166) },
    { section = "Muscle King", label = "Muscle King Lift", object = "Muscle King Lift", fallback = CFrame.new(-8772.9707, 39.1910, -5663.5625) },
    { section = "Muscle King", label = "Muscle King Bench", object = "Muscle King Bench", fallback = CFrame.new(-8590.2354, 37.7592, -6044.5952) },
    { section = "Muscle King", label = "King Boulder", object = "King Boulder", fallback = CFrame.new(-8942.1289, 43.7785, -5691.6362) },
    { section = "Muscle King", label = "Muscle King Squat", object = "Muscle King Squat", fallback = CFrame.new(-8758.4424, 32.8662, -6043.0693) },
}

local rEvents = ReplicatedStorage:WaitForChild("rEvents")
local function remote(name) return rEvents and rEvents:FindFirstChild(name) end
local function muscleEvent()
    return LP:FindFirstChild("muscleEvent") or ReplicatedStorage:FindFirstChild("muscleEvent")
end

local gameConfig
pcall(function()
    gameConfig = require(ReplicatedStorage.shared.config.GameConfig)
end)

local S = {
    autoPunch = false, punchGen = 0,
    autoTrain = false, trainGen = 0, machine = MACHINES[1].label, repRate = 10,
    autoRebirth = false, rebirthGen = 0,
    autoRewards = false, rewardsGen = 0,
    antiAfk = false,
}

local function leaderstats()
    local ls = LP:FindFirstChild("leaderstats")
    if not ls then return end
    return ls:FindFirstChild("Strength"), ls:FindFirstChild("Rebirths")
end

local function requiredRebirthStrength(rebirths)
    local base = (type(gameConfig) == "table" and tonumber(gameConfig.BASE_REBIRTH_STRENGTH)) or 10000
    local inc = (type(gameConfig) == "table" and tonumber(gameConfig.REBIRTH_STRENGTH_INCREMENT)) or 5000
    local required = base + rebirths * inc
    local equipped = LP:FindFirstChild("equippedPets")
    if equipped then
        local discount = 0
        for _, pet in ipairs(equipped:GetChildren()) do
            local ref = pet:FindFirstChild("petReference")
            if pet:IsA("ObjectValue") and pet.Value and ref and ref.Value and pet.Value.Name == "Speedy Sally" then
                discount += 10
            end
        end
        required = math.max(0, required - discount)
    end
    return required
end

local function findMachine(def)
    local model = workspace:FindFirstChild(def.object, true)
    if not model then return nil end
    if model:IsA("Seat") then return model, model end
    local seat
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("Seat") then seat = d break end
    end
    if not seat and model:IsA("BasePart") then seat = model model = model end
    return model, seat
end

local function machineActive(seat, humanoid)
    return seat and seat.Occupant == humanoid
end

local trainState = { seat = nil, mounted = false }

local function mountMachine(def)
    local ch, hum, root = charParts()
    if not ch then return false end
    local model, seat = findMachine(def)
    if not model or not seat then return false end
    if machineActive(seat, hum) then
        trainState.seat = seat
        trainState.mounted = true
        return true
    end
    if seat.Occupant and seat.Occupant ~= hum then return false end
    local remoteInst = remote("machineInteractRemote")
    if not remoteInst or not remoteInst:IsA("RemoteFunction") then return false end
    local seatCF
    if seat:IsA("Seat") then
        seatCF = seat.CFrame
    elseif seat:IsA("BasePart") then
        seatCF = seat.CFrame
    else
        seatCF = def.fallback
    end
    root.Anchored = false
    pcall(function() ch:PivotTo(seatCF + Vector3.new(0, 3, 0)) end)
    task.wait(0.12)
    local ok, accepted = pcall(remoteInst.InvokeServer, remoteInst, "useMachine", seat)
    if ok and accepted == true then
        local deadline = os.clock() + 1
        while os.clock() < deadline do
            if machineActive(seat, hum) then
                trainState.seat = seat
                trainState.mounted = true
                return true
            end
            task.wait(0.05)
        end
    end
    return false
end

local function leaveMachine()
    local remoteInst = remote("machineInteractRemote")
    if remoteInst and remoteInst:IsA("RemoteFunction") then
        pcall(remoteInst.InvokeServer, remoteInst, "leaveMachine")
    end
    local _, hum = charParts()
    if hum then hum.Sit = false end
    trainState.seat = nil
    trainState.mounted = false
end

local function repPump(generation, getSeat)
    local ev = muscleEvent()
    if not ev then return end
    local acc = 0
    local last = os.clock()
    while alive and getgenvCheck(generation) do
        local now = os.clock()
        acc = math.min(30, acc + (now - last) * S.repRate)
        last = now
        local n = math.floor(acc)
        if n > 0 then
            acc -= n
            local seat = getSeat and getSeat() or nil
            for _ = 1, math.min(n, 5) do
                if seat then
                    pcall(ev.FireServer, ev, "rep", seat)
                else
                    pcall(ev.FireServer, ev, "rep")
                end
            end
        end
        RunService.Heartbeat:Wait()
    end
end

local pumpGens = { n = 0 }
function getgenvCheck(g) return pumpGens.n == g end

local function startTrainLoop()
    S.trainGen += 1
    pumpGens.n += 1
    local gen = S.trainGen
    local pg = pumpGens.n
    task.spawn(function()
        while alive and S.autoTrain and S.trainGen == gen do
            local def
            for _, m in ipairs(MACHINES) do
                if m.label == S.machine then def = m break end
            end
            if def then
                if def.eventObject and not workspace:FindFirstChild(def.eventObject) then
                    task.wait(4)
                else
                    local _, hum = charParts()
                    if hum and not (trainState.seat and machineActive(trainState.seat, hum)) then
                        trainState.mounted = false
                        mountMachine(def)
                    end
                end
            end
            task.wait(0.5)
        end
        leaveMachine()
    end)
    task.spawn(function()
        repPump(pg, function() return trainState.mounted and trainState.seat or nil end)
    end)
end

local function startPunchLoop()
    S.punchGen += 1
    local gen = S.punchGen
    task.spawn(function()
        while alive and S.autoPunch and S.punchGen == gen do
            local ev = muscleEvent()
            if ev and ev:IsA("RemoteEvent") then
                pcall(ev.FireServer, ev, "punch", "rightHand")
                task.wait(0.05)
                pcall(ev.FireServer, ev, "punch", "leftHand")
            end
            task.wait(0.25)
        end
    end)
end

local function startRebirthLoop()
    S.rebirthGen += 1
    local gen = S.rebirthGen
    task.spawn(function()
        local busy = false
        while alive and S.autoRebirth and S.rebirthGen == gen do
            local waitTime = 0.15
            pcall(function()
                local rem = remote("rebirthRemote")
                local strength, rebirths = leaderstats()
                if not rem or not rem:IsA("RemoteFunction") or not strength or not rebirths then
                    waitTime = 0.6
                    return
                end
                if busy then return end
                local required = requiredRebirthStrength(rebirths.Value)
                if required and strength.Value >= required then
                    busy = true
                    local sent, accepted = pcall(rem.InvokeServer, rem, "rebirthRequest")
                    busy = false
                    waitTime = (sent and accepted == true) and 0.3 or 0.2
                end
            end)
            task.wait(waitTime)
        end
    end)
end

local GIFT_COUNT = 12
local function startRewardsLoop()
    S.rewardsGen += 1
    local gen = S.rewardsGen
    task.spawn(function()
        while alive and S.autoRewards and S.rewardsGen == gen do
            pcall(function()
                local gift = remote("freeGiftClaimRemote")
                if gift and gift:IsA("RemoteFunction") then
                    for n = 1, GIFT_COUNT do
                        pcall(gift.InvokeServer, gift, "claimGift", n)
                        task.wait(0.1)
                    end
                end
                local quests = remote("questsEvent")
                local questsFolder = LP:FindFirstChild("quests")
                if quests and quests:IsA("RemoteEvent") and questsFolder then
                    for _, q in ipairs(questsFolder:GetChildren()) do
                        local done = q:FindFirstChild("completed") or q:FindFirstChild("isCompleted")
                        if done and done.Value == true then
                            pcall(quests.FireServer, quests, "collectQuest", q)
                            task.wait(0.1)
                        end
                    end
                end
                local countdown = remote("giveCountdownRewardEvent")
                if countdown and countdown:IsA("RemoteEvent") then
                    pcall(countdown.FireServer, countdown, "giveCountdownReward")
                end
            end)
            task.wait(20)
        end
    end)
end

local function redeemCodes()
    local rem = remote("codeRemote")
    if not rem or not rem:IsA("RemoteFunction") then
        Notify("Code remote not ready", 2)
        return
    end
    local codes = { "MLREVIVED", "Industrialgym500" }
    local done = 0
    for _, code in ipairs(codes) do
        local ok, accepted, msg = pcall(rem.InvokeServer, rem, code)
        if ok and (accepted == true or (type(msg) == "string" and msg:lower():find("already", 1, true))) then
            done += 1
        end
        task.wait(0.6)
    end
    Notify("Codes: " .. done .. "/" .. #codes .. " redeemed", 2.5)
end

local antiAfkConn
local function setAntiAfk(v)
    if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn = nil end
    if v then
        antiAfkConn = LP.Idled:Connect(function()
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end)
    end
end

LP.CharacterAdded:Connect(function()
    task.wait(1.5)
    trainState.mounted = false
    trainState.seat = nil
end)

local HomePage = AddTab("Home")
AddLabel(HomePage, "NOIR · Muscle Legends · v1")
local statsLbl = AddLabel(HomePage, "Loading stats...")
AddButton(HomePage, "Hide UI  (tap the N bubble to reopen)", function() openMini(true) end)
AddButton(HomePage, "Unload Noir", function()
    pcall(function() penv.__NoirMLLoaded = false end)
    pcall(function() ScreenGui:Destroy() end)
end)

task.spawn(function()
    while alive do
        pcall(function()
            local strength, rebirths = leaderstats()
            if strength and rebirths then
                local req = requiredRebirthStrength(rebirths.Value)
                statsLbl.TextLabel.Text = string.format(
                    "Strength: %s   Rebirths: %s\nNext rebirth at: %s strength",
                    tostring(strength.Value), tostring(rebirths.Value), req and tostring(req) or "?")
            end
        end)
        task.wait(1)
    end
end)

local FarmPage = AddTab("Farm")
AddLabel(FarmPage, "TRAINING")
local trainToggle
AddDropdown(FarmPage, "Machine", (function()
    local t = {}
    for _, m in ipairs(MACHINES) do t[#t + 1] = m.label end
    return t
end)(), function(v) S.machine = v end)
trainToggle = AddToggle(FarmPage, "Auto Train (mount + reps)", false, function(v)
    S.autoTrain = v
    if v then startTrainLoop() else trainState.mounted = false leaveMachine() pumpGens.n += 1 end
end)
AddSlider(FarmPage, "Rep rate (per second)", 2, 25, 10, function(v) S.repRate = v end)
AddLabel(FarmPage, "FISTS")
AddToggle(FarmPage, "Auto Punch", false, function(v)
    S.autoPunch = v
    if v then startPunchLoop() end
end)
AddLabel(FarmPage, "REBIRTH")
AddToggle(FarmPage, "Auto Rebirth (at requirement)", false, function(v)
    S.autoRebirth = v
    if v then startRebirthLoop() end
end)
AddLabel(FarmPage, "REWARDS")
AddToggle(FarmPage, "Auto claim gifts & quests", false, function(v)
    S.autoRewards = v
    if v then startRewardsLoop() end
end)
AddButton(FarmPage, "Redeem all codes (eggs)", redeemCodes)

local ROCKS = {
    { label = "Hallowed Rock", req = 0, minDur = 0, objectName = "Hallowed Rock", eventObject = "HalloweenMap" },
    { label = "Overcharged Rock", req = 0, minDur = 0, objectName = "Overcharged Rock", eventObject = "OverchargedMap" },
    { label = "Industrial Rock", req = 25000000, minDur = 25000000 },
    { label = "Ancient Rock", req = 10000000, minDur = 10000000 },
    { label = "Muscle King Rock", req = 5000000, minDur = 5000000 },
    { label = "Legend Rock", req = 1000000, minDur = 1000000 },
    { label = "Eternal Rock", req = 750000, minDur = 750000 },
    { label = "Mythical Rock", req = 400000, minDur = 400000 },
    { label = "Frost Rock", req = 150000, minDur = 150000 },
    { label = "Beach Rock", req = 5000, minDur = 5000 },
    { label = "Starter Rock", req = 100, minDur = 100 },
    { label = "Tiny Rock", req = 0, minDur = 0 },
}

local function getPunchTool()
    local ch = LP.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    local backpack = LP:FindFirstChild("Backpack")
    local tool = (ch and ch:FindFirstChild("Punch")) or (backpack and backpack:FindFirstChild("Punch"))
    if not hum or hum.Health <= 0 or not tool then return nil end
    if tool.Parent ~= ch then
        pcall(function() hum:EquipTool(tool) end)
    end
    return tool.Parent == ch and tool or nil
end

local function punchBurst()
    local ev = muscleEvent()
    if ev and ev:IsA("RemoteEvent") then
        pcall(ev.FireServer, ev, "punch", "rightHand")
        pcall(ev.FireServer, ev, "punch", "leftHand")
    end
end

local function findRock(req, objectName)
    local folder = workspace:FindFirstChild("machinesFolder")
    if not folder then return nil end
    for _, model in ipairs(folder:GetChildren()) do
        local need = model:FindFirstChild("neededDurability")
        local rock = model:FindFirstChild("Rock")
        local nameOk = not objectName or model.Name == objectName
        if nameOk and need and need:IsA("ValueBase") and need.Value == req and rock and rock:IsA("BasePart") then
            return rock
        end
    end
    return nil
end

S.selectedRock = ROCKS[#ROCKS].label
S.autoRock = false
S.rockGen = 0
S.autoBrawl = false
S.brawlGen = 0
S.autoBoss = false
S.bossGen = 0

local touchInterest = type(firetouchinterest) == "function" and firetouchinterest
    or (type(penv.firetouchinterest) == "function" and penv.firetouchinterest) or nil
local touchWarned = false

local function startRockLoop()
    S.rockGen += 1
    local gen = S.rockGen
    task.spawn(function()
        while alive and S.autoRock and S.rockGen == gen do
            pcall(function()
                local def
                for _, r in ipairs(ROCKS) do
                    if r.label == S.selectedRock then def = r break end
                end
                if not def then return end
                if def.eventObject and not workspace:FindFirstChild(def.eventObject) then
                    task.wait(3)
                    return
                end
                local durability = LP:FindFirstChild("Durability")
                if not durability or durability.Value < def.minDur then
                    task.wait(1.5)
                    return
                end
                local ch, hum, root = charParts()
                local tool = getPunchTool()
                local rock = findRock(def.req, def.objectName)
                if not (ch and tool and rock) then
                    task.wait(0.5)
                    return
                end
                local lh = ch:FindFirstChild("LeftHand") or ch:FindFirstChild("Left Arm")
                local rh = ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm")
                if touchInterest and lh and rh then
                    pcall(touchInterest, rh, rock, 0)
                    pcall(touchInterest, lh, rock, 0)
                else
                    if not touchWarned then
                        touchWarned = true
                        Notify("firetouchinterest unavailable - rocks use proximity mode", 3)
                    end
                    pcall(function()
                        ch:PivotTo(CFrame.new(rock.Position + rock.CFrame.LookVector * (rock.Size.Z * 0.5 + 2.6), rock.Position))
                    end)
                end
                pcall(function()
                    local at = tool:FindFirstChild("attackTime")
                    if at then at.Value = 0 end
                    tool:Deactivate()
                    tool:Activate()
                end)
                punchBurst()
                task.wait(0.06)
                if touchInterest and lh and rh and rock.Parent then
                    pcall(touchInterest, rh, rock, 1)
                    pcall(touchInterest, lh, rock, 1)
                end
            end)
            task.wait(0.09)
        end
    end)
end

local brawlEvent = remote("brawlEvent")
local function hasShield(ch)
    return ch and (ch:FindFirstChildWhichIsA("ForceField") ~= nil or ch:GetAttribute("InTinyIsland") == true)
end

local function startBrawlLoop()
    S.brawlGen += 1
    local gen = S.brawlGen
    task.spawn(function()
        while alive and S.autoBrawl and S.brawlGen == gen do
            pcall(function()
                local ch, hum, root = charParts()
                if not ch then return end
                local inside = ch:GetAttribute("LastMapCFrame") ~= nil
                local inBattle = ch:GetAttribute("InBattle") == true
                if not inside then
                    if brawlEvent and brawlEvent:IsA("RemoteEvent") then
                        pcall(brawlEvent.FireServer, brawlEvent, "joinBrawl")
                    end
                    task.wait(6)
                    return
                end
                if not inBattle then
                    task.wait(0.6)
                    return
                end
                local target, tHum, tRoot
                local best = math.huge
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl ~= LP and pl.Character then
                        local pch = pl.Character
                        local ph = pch:FindFirstChildOfClass("Humanoid")
                        local pr = pch:FindFirstChild("HumanoidRootPart")
                        if ph and pr and ph.Health > 0 and not hasShield(pch) then
                            local d = (pr.Position - root.Position).Magnitude
                            if d < best then
                                best = d
                                target, tHum, tRoot = pch, ph, pr
                            end
                        end
                    end
                end
                if target and tRoot then
                    local part = target:FindFirstChild("UpperTorso") or target:FindFirstChild("Torso") or tRoot
                    local behind = part.Position - part.CFrame.LookVector * 3.2
                    pcall(function()
                        ch:PivotTo(CFrame.new(behind, part.Position))
                        root.AssemblyLinearVelocity = Vector3.zero
                    end)
                    local tool = getPunchTool()
                    if tool then
                        pcall(function()
                            local at = tool:FindFirstChild("attackTime")
                            if at then at.Value = 0 end
                            tool:Activate()
                        end)
                    end
                    punchBurst()
                    task.wait(0.12)
                else
                    task.wait(0.4)
                end
            end)
            task.wait(0.05)
        end
    end)
end

local CollectionService = game:GetService("CollectionService")

local function findBoss()
    local candidates = {}
    for _, b in ipairs(CollectionService:GetTagged("BossEventBoss")) do
        candidates[#candidates + 1] = b
    end
    if #candidates == 0 then
        local events = workspace:FindFirstChild("Events")
        local arena = events and events:FindFirstChild("BossArena")
        if arena then
            for _, m in ipairs(arena:GetChildren()) do
                if m:IsA("Model") and m:FindFirstChild("BossDamageHitbox", true) then
                    candidates[#candidates + 1] = m
                end
            end
        end
    end
    for _, boss in ipairs(candidates) do
        local hb = boss:FindFirstChild("BossDamageHitbox", true)
            or boss.PrimaryPart
            or boss:FindFirstChildWhichIsA("BasePart", true)
        if hb and hb:IsA("BasePart") then
            return boss, hb
        end
    end
    return nil, nil
end

local function startBossLoop()
    S.bossGen += 1
    local gen = S.bossGen
    task.spawn(function()
        while alive and S.autoBoss and S.bossGen == gen do
            pcall(function()
                local ch, hum, root = charParts()
                if not ch then return end
                local boss, hb = findBoss()
                if not boss then
                    task.wait(2)
                    return
                end
                local nearest = hb
                pcall(function()
                    local offset = nearest.CFrame.LookVector * (math.max(nearest.Size.X, nearest.Size.Z) * 0.5 + 3.2)
                    ch:PivotTo(CFrame.new(nearest.Position + offset - Vector3.new(0, nearest.Size.Y * 0.5, 0), nearest.Position))
                    root.AssemblyLinearVelocity = Vector3.zero
                end)
                local tool = getPunchTool()
                if tool then
                    pcall(function()
                        local at = tool:FindFirstChild("attackTime")
                        if at then at.Value = 0 end
                        tool:Activate()
                    end)
                end
                punchBurst()
                task.wait(0.1)
            end)
            task.wait(0.05)
        end
    end)
end

local CombatPage = AddTab("Combat")
AddLabel(CombatPage, "ROCKS (needs durability)")
AddDropdown(CombatPage, "Rock", (function()
    local t = {}
    for i = #ROCKS, 1, -1 do t[#t + 1] = ROCKS[i].label end
    return t
end)(), function(v) S.selectedRock = v end)
S.selectedRock = ROCKS[#ROCKS].label
AddToggle(CombatPage, "Auto smash rock", false, function(v)
    S.autoRock = v
    if v then startRockLoop() end
end)
AddLabel(CombatPage, "BRAWL (Kills)")
AddToggle(CombatPage, "Auto Brawl (join + fight)", false, function(v)
    S.autoBrawl = v
    if v then startBrawlLoop() end
end)
AddLabel(CombatPage, "BOSS")
AddToggle(CombatPage, "Auto Boss (event arena)", false, function(v)
    S.autoBoss = v
    if v then startBossLoop() end
end)

local MAP_CHEST_RESOLVERS = {
    ["Golden Chest"] = function() return workspace:FindFirstChild("goldenChest") end,
    ["Enchanted Chest"] = function() return workspace:FindFirstChild("enchantedChest") end,
    ["Magma Chest"] = function() return workspace:FindFirstChild("magmaChest") end,
    ["Mythical Chest"] = function() return workspace:FindFirstChild("mythicalChest") end,
    ["Legends Chest"] = function() return workspace:FindFirstChild("legendsChest") end,
    ["Jungle Chest"] = function() return workspace:FindFirstChild("jungleChest") end,
    ["Industrial Chest"] = function()
        local industrial = workspace:FindFirstChild("IndustrialMap")
        local model = industrial and industrial:FindFirstChild("Model")
        return model and model:FindFirstChild("industrialChest")
    end,
    ["Overcharged Chest"] = function()
        local map = workspace:FindFirstChild("OverchargedMap")
        return map and map:FindFirstChild("overchargedChest")
    end,
}

local function mapChestNames()
    local names, seen = {}, {}
    local shared = ReplicatedStorage:FindFirstChild("shared")
    local catalogs = shared and shared:FindFirstChild("catalogs")
    local chestRewards = catalogs and catalogs:FindFirstChild("chestRewards")
    if chestRewards then
        for _, entry in ipairs(chestRewards:GetChildren()) do
            if entry.Name ~= "" and not seen[entry.Name] then
                seen[entry.Name] = true
                names[#names + 1] = entry.Name
            end
        end
    end
    if #names == 0 then
        for name in pairs(MAP_CHEST_RESOLVERS) do names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

local function mapChestModel(name)
    local resolve = MAP_CHEST_RESOLVERS[name]
    if resolve then
        local ok, model = pcall(resolve)
        if ok and model then return model end
    end
    local normalized = tostring(name):lower():gsub("[^%w]", "")
    for _, object in ipairs(workspace:GetDescendants()) do
        if (object:IsA("Model") or object:IsA("Folder"))
            and object.Name:lower():gsub("[^%w]", "") == normalized
            and object:FindFirstChild("circleInner") then
            return object
        end
    end
    return nil
end

local function mapChestReady(model)
    if not model then return false end
    local label = model:FindFirstChild("timeLabel", true)
    if not label or not label:IsA("TextLabel") then return true end
    local text = tostring(label.Text or ""):lower()
    if text == "" then return true end
    if text:find(":", 1, true) or text:find("collect in", 1, true) then return false end
    return text:find("ready", 1, true) ~= nil or text:find("collect", 1, true) ~= nil
end

S.autoChests = false
S.chestGen = 0

local function startChestLoop()
    S.chestGen += 1
    local gen = S.chestGen
    task.spawn(function()
        while alive and S.autoChests and S.chestGen == gen do
            pcall(function()
                local chestRemote = remote("checkChestRemote")
                local ch, hum, root = charParts()
                if not (ch and root) or not (chestRemote and chestRemote:IsA("RemoteFunction")) then
                    return
                end
                local originalPivot = ch:GetPivot()
                for _, chestName in ipairs(mapChestNames()) do
                    if not (alive and S.autoChests and S.chestGen == gen and hum.Health > 0) then break end
                    local model = mapChestModel(chestName)
                    if mapChestReady(model) then
                        local trigger = model:FindFirstChild("circleInner")
                        if trigger and trigger:IsA("BasePart") then
                            local deadline = os.clock() + 4
                            while os.clock() < deadline do
                                local cool = LP:GetAttribute("ChestRequestCooldownUntil")
                                if typeof(cool) ~= "number" or workspace:GetServerTimeNow() >= cool then break end
                                task.wait(0.1)
                            end
                            local target = trigger.CFrame + Vector3.new(0, 3, 0)
                            local t0 = os.clock()
                            while os.clock() - t0 < 1.2 and root.Parent do
                                root.AssemblyLinearVelocity = Vector3.zero
                                root.CFrame = target
                                task.wait(0.1)
                            end
                            local ok, accepted = pcall(chestRemote.InvokeServer, chestRemote, chestName)
                            task.wait(0.5)
                            if ok and accepted == true then
                                Notify("Chest claimed: " .. chestName, 2)
                            end
                        end
                    end
                end
                if ch == LP.Character and root.Parent then
                    ch:PivotTo(originalPivot)
                end
            end)
            local waited = 0
            while alive and S.autoChests and S.chestGen == gen and waited < 60 do
                task.wait(1)
                waited += 1
            end
        end
    end)
end

AddToggle(FarmPage, "Auto map chests (teleport claimed)", false, function(v)
    S.autoChests = v
    if v then startChestLoop() end
end)

local machineInteract = remote("machineInteractRemote")
local function repInterval() return 1 / math.max(2, S.repRate or 10) end

local FULLTRAIN_AREAS = {
    { section = "Eternal Gym", center = Vector3.new(-6768, 0, -1287) },
    { section = "Mythical Gym", center = Vector3.new(2255, 0, 1071) },
    { section = "Frost Gym", center = Vector3.new(-2650, 0, -393) },
    { section = "Playa", center = Vector3.new(9, 0, 100) },
    { section = "Magma Ring", center = Vector3.new(4400, 0, -8400) },
    { section = "Desert Ring", center = Vector3.new(900, 0, -7000) },
    { section = "Boxing Ring", center = Vector3.new(-1900, 0, -5820) },
    { section = "Tiny Island", center = Vector3.new(50, 0, 1918) },
}

local function seatByName(name)
    local folder = workspace:FindFirstChild("machinesFolder")
    local model = folder and folder:FindFirstChild(name)
    if not model then return nil end
    if model:IsA("Seat") then return model end
    local seat = model:FindFirstChildWhichIsA("Seat", true)
    if seat then return seat end
    return (model:IsA("BasePart") and model) or model:FindFirstChildWhichIsA("BasePart", true)
end

local function buildAreaMachines(center)
    local folder = workspace:FindFirstChild("machinesFolder")
    if not folder then return {} end
    local unique = {}
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") and m:FindFirstChild("machineType") then
            local seat = seatByName(m.Name)
            local gv = m:FindFirstChild("strengthGain")
            local gain = tonumber(gv and gv.Value)
            if seat and gain then
                local dist = (Vector3.new(seat.Position.X, 0, seat.Position.Z) - center).Magnitude
                if dist <= 1400 then
                    local existing = unique[m.Name]
                    if not existing or gain > existing.gain then
                        unique[m.Name] = { name = m.Name, gain = gain }
                    end
                end
            end
        end
    end
    local out = {}
    for _, v in pairs(unique) do out[#out + 1] = v end
    table.sort(out, function(a, b)
        if a.gain ~= b.gain then return a.gain > b.gain end
        return a.name < b.name
    end)
    return out
end

S.fullTrain = false
S.ftGen = 0
S.fullTrainArea = FULLTRAIN_AREAS[4].section

local function verifySit(hum, seat)
    for _ = 1, 8 do
        local occ = seat:IsA("Seat") and seat.Occupant
        if hum.Sit and occ == hum then return true end
        task.wait(0.45)
    end
    return false
end

local function startFullTrain()
    S.ftGen += 1
    local gen = S.ftGen
    task.spawn(function()
        while alive and S.fullTrain and S.ftGen == gen do
            local area
            for _, a in ipairs(FULLTRAIN_AREAS) do
                if a.section == S.fullTrainArea then area = a break end
            end
            local defs = area and buildAreaMachines(area.center) or {}
            if #defs == 0 then
                Notify("Full Train: no machines found in area", 2.5)
                task.wait(3)
            end
            for _, def in ipairs(defs) do
                if not (alive and S.fullTrain and S.ftGen == gen) then break end
                local seat = seatByName(def.name)
                if seat and machineInteract and machineInteract:IsA("RemoteFunction") then
                    local ch, hum, root = charParts()
                    if ch then
                        autoChoseMachine = false
                        pcall(function() ch:PivotTo(seat.CFrame) end)
                        task.wait(0.3)
                        pcall(machineInteract.InvokeServer, machineInteract, "useMachine", seat)
                        if verifySit(hum, seat) then
                            local t0 = os.clock()
                            while alive and S.fullTrain and S.ftGen == gen and os.clock() - t0 < 20 do
                                local ch2, hum2 = charParts()
                                local occ = seat:IsA("Seat") and seat.Occupant
                                if not (ch2 and hum2 and hum2.Sit and occ == hum2) then
                                    task.wait(0.4)
                                    pcall(function()
                                        if ch2 then ch2:PivotTo(seat.CFrame) end
                                        machineInteract:InvokeServer("useMachine", seat)
                                    end)
                                else
                                    local ev = muscleEvent()
                                    if ev and ev:IsA("RemoteEvent") then
                                        pcall(ev.FireServer, ev, "rep", seat)
                                        pcall(ev.FireServer, ev, "rep")
                                    end
                                end
                                task.wait(repInterval())
                            end
                        end
                        pcall(machineInteract.InvokeServer, machineInteract, "leaveMachine")
                        local _, hum3 = charParts()
                        if hum3 then pcall(function() hum3.Sit = false end) end
                    end
                end
                task.wait(0.4)
            end
            task.wait(0.5)
        end
    end)
end

local FullTrainPage = AddTab("Full Train")
AddLabel(FullTrainPage, "ROTATION (20s each, best gain first)")
local ftAreaNames = {}
for _, a in ipairs(FULLTRAIN_AREAS) do ftAreaNames[#ftAreaNames + 1] = a.section end
AddDropdown(FullTrainPage, "Area", ftAreaNames, function(v) S.fullTrainArea = v end)
AddToggle(FullTrainPage, "Full Train (rotate machines)", false, function(v)
    S.fullTrain = v
    if v then startFullTrain() end
end)

local consumeBoostEvent = remote("consumeBoostEvent")
local openFortuneWheelRemote = remote("openFortuneWheelRemote")
local fortuneCatalog = (function()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    return shared and shared:FindFirstChild("catalogs") or nil
end)()

S.autoEgg = false
S.eggGen = 0
S.autoFortune = false
S.fortuneGen = 0

local function findProteinEgg()
    local folder = LP:FindFirstChild("consumablesFolder")
    if not folder then return nil end
    for _, item in ipairs(folder:GetChildren()) do
        if item:IsA("StringValue") and item.Name == "Protein Egg" and not item:FindFirstChild("isGift") then
            return item
        end
    end
    return nil
end

local function eggTimeRemaining()
    local ok, result = pcall(function()
        local ReplicatorClient = require(ReplicatedStorage:WaitForChild("packages"):WaitForChild("ReplicatorClient"))
        local getter = ReplicatorClient and (ReplicatorClient.get or ReplicatorClient.Get)
        if type(getter) ~= "function" then return nil end
        local data = getter(ReplicatorClient, "Data") or getter("Data")
        if not data then return nil end
        local timers = data:TryIndex({ "boostTimersFolder" })
        if type(timers) == "table" then
            local t = timers["Protein Egg"]
            if typeof(t) == "number" then return math.max(0, t) end
            return 0
        end
        return nil
    end)
    if ok then return result end
    return nil
end

local function startEggLoop()
    S.eggGen += 1
    local gen = S.eggGen
    task.spawn(function()
        local lastAte = 0
        while alive and S.autoEgg and S.eggGen == gen do
            local remaining = eggTimeRemaining()
            if remaining == nil then
                if os.clock() - lastAte >= 1700 then
                    local egg = findProteinEgg()
                    if egg and consumeBoostEvent and consumeBoostEvent:IsA("RemoteEvent") then
                        pcall(consumeBoostEvent.FireServer, consumeBoostEvent, egg, 1)
                        lastAte = os.clock()
                    end
                    task.wait(5)
                else
                    task.wait(15)
                end
            elseif remaining > 10 then
                task.wait(math.clamp(remaining - 8, 2, 30))
            else
                local egg = findProteinEgg()
                if egg and consumeBoostEvent and consumeBoostEvent:IsA("RemoteEvent") then
                    pcall(consumeBoostEvent.FireServer, consumeBoostEvent, egg, 1)
                    lastAte = os.clock()
                    task.wait(3)
                else
                    Notify("No Protein Eggs left", 2.5)
                    task.wait(15)
                end
            end
        end
    end)
end

local function fortuneSpinCount()
    local ok, total = pcall(function()
        local ReplicatorClient = require(ReplicatedStorage:WaitForChild("packages"):WaitForChild("ReplicatorClient"))
        local getter = ReplicatorClient and (ReplicatorClient.get or ReplicatorClient.Get)
        if type(getter) ~= "function" then return nil end
        local data = getter(ReplicatorClient, "Data") or getter("Data")
        if not data then return nil end
        local free = tonumber(data:TryIndex({ "freeWheelSpins" })) or 0
        local purchased = tonumber(data:TryIndex({ "purchasedSpins" })) or 0
        return math.max(0, math.floor(free)) + math.max(0, math.floor(purchased))
    end)
    if ok and total then return total end
    local gui = LP:FindFirstChild("PlayerGui")
    gui = gui and gui:FindFirstChild("fortuneWheelMenuGui")
    gui = gui and gui:FindFirstChild("fortuneMenu")
    gui = gui and gui:FindFirstChild("youHaveLabel")
    local lbl = gui and gui:FindFirstChild("spinAmountLabel")
    if lbl and lbl:IsA("TextLabel") then
        return tonumber(lbl.Text:match("^%s*(%d+)"))
    end
    return nil
end

local function startFortuneLoop()
    S.fortuneGen += 1
    local gen = S.fortuneGen
    task.spawn(function()
        while alive and S.autoFortune and S.fortuneGen == gen do
            local count = fortuneSpinCount()
            if count ~= nil and count <= 0 then
                task.wait(12)
            elseif not (openFortuneWheelRemote and openFortuneWheelRemote:IsA("RemoteFunction")) or not fortuneCatalog then
                task.wait(5)
            else
                local ok, reward = pcall(openFortuneWheelRemote.InvokeServer, openFortuneWheelRemote, "openFortuneWheel", fortuneCatalog)
                if ok and type(reward) == "table" then
                    task.wait(4)
                else
                    task.wait(10)
                end
            end
        end
    end)
end

local BoostsPage = AddTab("Boosts")
AddLabel(BoostsPage, "PROTEIN EGG (30 min buff)")
AddToggle(BoostsPage, "Auto eat Protein Egg", false, function(v)
    S.autoEgg = v
    if v then startEggLoop() end
end)
AddLabel(BoostsPage, "FORTUNE WHEEL")
AddToggle(BoostsPage, "Auto spin wheel", false, function(v)
    S.autoFortune = v
    if v then startFortuneLoop() end
end)

local giftRemote = remote("giftRemote")
S.giftItem = "Protein Egg"
S.giftTarget = nil
S.giftAmount = 1
S.giftBusy = false

local function getGiftableItems(name)
    local folder = LP:FindFirstChild("consumablesFolder")
    local out = {}
    if folder then
        for _, item in ipairs(folder:GetChildren()) do
            if item:IsA("StringValue") and item.Name == name and item.Value ~= "" and not item:FindFirstChild("isGift") then
                out[#out + 1] = item
            end
        end
    end
    return out
end

local GiftsPage = AddTab("Gifts")
AddLabel(GiftsPage, "SEND ITEMS TO PLAYER")
AddDropdown(GiftsPage, "Item", { "Protein Egg", "Tropical Shake" }, function(v)
    S.giftItem = v
end)
local playerDropdown
local function refreshPlayers()
    local names = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP then names[#names + 1] = pl.Name end
    end
    table.sort(names)
    return names
end
playerDropdown = AddDropdown(GiftsPage, "Player", refreshPlayers(), function(v)
    S.giftTarget = v
end)
AddButton(GiftsPage, "Refresh player list", function()
    playerDropdown.SetOptions(refreshPlayers())
    Notify("Player list refreshed", 1.5)
end)
AddSlider(GiftsPage, "Amount", 1, 50, 1, function(v)
    S.giftAmount = math.floor(v)
end)
AddButton(GiftsPage, "Send gifts", function()
    if S.giftBusy then
        Notify("Already sending, please wait", 2)
        return
    end
    if not S.giftTarget then
        Notify("Select a player first", 2)
        return
    end
    local target = Players:FindFirstChild(S.giftTarget)
    if not target then
        Notify("Player left the server", 2)
        return
    end
    if not (giftRemote and giftRemote:IsA("RemoteFunction")) then
        Notify("Gift system unavailable", 2)
        return
    end
    local items = getGiftableItems(S.giftItem)
    if #items == 0 then
        Notify("No " .. S.giftItem .. " in inventory", 2)
        return
    end
    local amount = math.min(S.giftAmount, #items)
    S.giftBusy = true
    task.spawn(function()
        local sent = 0
        for i = 1, amount do
            if not alive or target.Parent ~= Players then
                Notify("Player left, stopped", 2)
                break
            end
            local ok, accepted = pcall(giftRemote.InvokeServer, giftRemote, "giftRequest", target, items[i])
            if not (ok and accepted == true) then
                Notify("Server rejected the gift (" .. sent .. " sent)", 2.5)
                break
            end
            sent += 1
            task.wait(0.6)
        end
        if sent > 0 then
            Notify("Sent " .. sent .. "x " .. S.giftItem .. " to " .. target.Name, 2.5)
        end
        S.giftBusy = false
    end)
end)

local openCrystalRemote = remote("openCrystalRemote")
local CRYSTALS = {
    { name = "Hallowed Crystal", stat = "CandyCorn", currency = "Candy Corn" },
    { name = "Overcharged Crystal", stat = "OverchargedShards", currency = "Overcharged Shards" },
}
S.crystalName = CRYSTALS[1].name
S.crystalAmount = 1
S.autoCrystal = false
S.crystalGen = 0

local function crystalPrice(name)
    local ok, price = pcall(function()
        local shared = ReplicatedStorage:FindFirstChild("shared")
        local catalogs = shared and shared:FindFirstChild("catalogs")
        local prices = catalogs and catalogs:FindFirstChild("crystalPrices")
        local entry = prices and prices:FindFirstChild(name)
        for _, v in ipairs(entry and entry:GetChildren() or {}) do
            if v:IsA("ValueBase") and tonumber(v.Value) then return tonumber(v.Value) end
        end
        return nil
    end)
    if ok and price then return price end
    return 500
end

local function crystalCount()
    local def
    for _, c in ipairs(CRYSTALS) do
        if c.name == S.crystalName then def = c break end
    end
    if not def then return 0, 500 end
    local stat = LP:FindFirstChild(def.stat)
    local have = stat and tonumber(stat.Value) or 0
    return have, crystalPrice(def.name)
end

local function openCrystalNow(amount)
    if not (openCrystalRemote and openCrystalRemote:IsA("RemoteFunction")) then
        return false, "Crystal system unavailable"
    end
    local have, price = crystalCount()
    if have < price * amount then
        return false, "Not enough currency (" .. math.floor(have) .. ")"
    end
    if amount <= 1 then
        local ok, result = pcall(openCrystalRemote.InvokeServer, openCrystalRemote, "openCrystal", S.crystalName)
        if ok and type(result) == "string" and result ~= "" then
            return true, result
        end
        return false, ok and "Rejected" or "Request failed"
    end
    local ok, response = pcall(openCrystalRemote.InvokeServer, openCrystalRemote, "openCrystalBulk", S.crystalName, amount)
    if ok and type(response) == "table" and type(response.Results) == "table" and #response.Results > 0 then
        return true, #response.Results .. " rewards received"
    end
    local reason = type(response) == "table" and response.StopReason or "Rejected"
    return false, tostring(reason)
end

local function startCrystalLoop()
    S.crystalGen += 1
    local gen = S.crystalGen
    task.spawn(function()
        while alive and S.autoCrystal and S.crystalGen == gen do
            local ok, msg = openCrystalNow(math.max(1, S.crystalAmount))
            if not ok then
                if tostring(msg):find("NoCapacity") then
                    Notify("Inventory full - stopping crystal farm", 3)
                    S.autoCrystal = false
                    break
                end
                task.wait(6)
            end
            task.wait(2.5)
        end
        if S.autoCrystal then S.autoCrystal = false end
    end)
end

local EventsPage = AddTab("Events")
AddLabel(EventsPage, "EVENT CRYSTALS")
AddDropdown(EventsPage, "Crystal", { CRYSTALS[1].name, CRYSTALS[2].name }, function(v)
    S.crystalName = v
end)
AddDropdown(EventsPage, "Amount", { "1", "5", "10" }, function(v)
    S.crystalAmount = tonumber(v) or 1
end)
AddButton(EventsPage, "Open crystal now", function()
    local ok, msg = openCrystalNow(math.max(1, S.crystalAmount))
    Notify((ok and "Opened: " or "Failed: ") .. tostring(msg), 2.5)
end)
AddToggle(EventsPage, "Auto open crystals", false, function(v)
    S.autoCrystal = v
    if v then startCrystalLoop() end
end)

local PET_MODULE_URLS = {
    "https://raw.githubusercontent.com/Young0xHUB/Young0x-HUB/refs/heads/main/modules/pets.lua",
    "https://raw.githubusercontent.com/Young0xHUB/Young0x-HUB/main/modules/pets.lua",
}
local PET_NAMES = {
    "Neon Guardian", "Cybernetic Showdown Dragon", "Darkstar Hunter", "Muscle Sensei",
    "Infernal Dragon", "Aether Spirit Bunny", "Magic Butterfly", "Ultra Birdie",
}
local AURA_NAMES = { "Muscle King", "Entropic Blast" }
S.petChoice = PET_NAMES[1]
S.auraChoice = AURA_NAMES[1]
local petLoading = false

local function ensurePetShop()
    local current = type(penv.getgenv) == "function" and penv.getgenv().Young0xPetShop or nil
    if type(current) == "table" and type(current.BuyPet) == "function" then
        return current
    end
    if type(getgenv) == "function" then
        current = getgenv().Young0xPetShop
        if type(current) == "table" and type(current.BuyPet) == "function" then
            return current
        end
    end
    if petLoading then return nil, "loading" end
    petLoading = true
    local lastErr
    for _, url in ipairs(PET_MODULE_URLS) do
        local ok, source = pcall(function() return game:HttpGet(url) end)
        if ok and type(source) == "string" and #source > 50 and not source:find("^404") then
            local chunk, cerr = loadstring(source)
            if type(chunk) == "function" then
                local ok2, rerr = pcall(chunk)
                if ok2 then
                    lastErr = nil
                    break
                end
                lastErr = tostring(rerr)
            else
                lastErr = tostring(cerr)
            end
        else
            lastErr = ok and "not found / empty" or tostring(source)
        end
    end
    petLoading = false
    local gg = type(getgenv) == "function" and getgenv() or nil
    local mod = gg and gg.Young0xPetShop
    if type(mod) == "table" then
        return mod
    end
    return nil, lastErr or "module unavailable"
end

local equipPetEvent = remote("equipPetEvent")

local PetsPage = AddTab("Pets")
AddLabel(PetsPage, "PET SHOP (via author module)")
AddDropdown(PetsPage, "Pet", PET_NAMES, function(v) S.petChoice = v end)
AddButton(PetsPage, "Buy selected pet", function()
    task.spawn(function()
        local mod, err = ensurePetShop()
        if not mod then
            Notify("Pet module failed: " .. tostring(err), 3)
            return
        end
        if mod.SelectPet then pcall(mod.SelectPet, S.petChoice) end
        local ok = pcall(mod.BuyPet)
        Notify(ok and "Pet purchase sent" or "Pet purchase failed", 2.5)
    end)
end)
AddToggle(PetsPage, "Auto buy pets", false, function(v)
    task.spawn(function()
        local mod, err = ensurePetShop()
        if mod and type(mod.SetAutoPet) == "function" then
            pcall(mod.SetAutoPet, v)
            Notify("Auto pets " .. (v and "ON" or "OFF"), 2)
        else
            Notify("Pet module failed: " .. tostring(err), 3)
        end
    end)
end)
AddDropdown(PetsPage, "Aura", AURA_NAMES, function(v) S.auraChoice = v end)
AddButton(PetsPage, "Buy selected aura", function()
    task.spawn(function()
        local mod, err = ensurePetShop()
        if not mod then
            Notify("Pet module failed: " .. tostring(err), 3)
            return
        end
        if mod.SelectAura then pcall(mod.SelectAura, S.auraChoice) end
        local ok = pcall(mod.BuyAura)
        Notify(ok and "Aura purchase sent" or "Aura purchase failed", 2.5)
    end)
end)
AddToggle(PetsPage, "Auto buy auras", false, function(v)
    task.spawn(function()
        local mod, err = ensurePetShop()
        if mod and type(mod.SetAutoAura) == "function" then
            pcall(mod.SetAutoAura, v)
            Notify("Auto auras " .. (v and "ON" or "OFF"), 2)
        else
            Notify("Pet module failed: " .. tostring(err), 3)
        end
    end)
end)
AddLabel(PetsPage, "INVENTORY")
AddButton(PetsPage, "Equip all owned pets", function()
    if not (equipPetEvent and equipPetEvent:IsA("RemoteEvent")) then
        Notify("Pet system unavailable", 2)
        return
    end
    task.spawn(function()
        local equipped = LP:FindFirstChild("equippedPets")
        if equipped then
            for _, slot in ipairs(equipped:GetChildren()) do
                local ref = slot:FindFirstChild("petReference")
                local pet = ref and ref:IsA("ObjectValue") and ref.Value
                if pet and pet:IsA("StringValue") then
                    pcall(equipPetEvent.FireServer, equipPetEvent, "unequipPet", pet)
                    task.wait(0.08)
                end
            end
        end
        task.wait(0.25)
        local inventory = LP:FindFirstChild("petsFolder")
        local count = 0
        if inventory then
            for _, folder in ipairs(inventory:GetChildren()) do
                for _, pet in ipairs(folder:GetChildren()) do
                    if pet:IsA("StringValue") then
                        pcall(equipPetEvent.FireServer, equipPetEvent, "equipPet", pet)
                        count += 1
                        task.wait(0.08)
                    end
                end
            end
        end
        Notify("Equip request sent for " .. count .. " pets", 2.5)
    end)
end)

local TeleportPage = AddTab("Teleport")
AddLabel(TeleportPage, "GYMS & AREAS")
local tpArea = FULLTRAIN_AREAS[4].section
AddDropdown(TeleportPage, "Area", ftAreaNames, function(v) tpArea = v end)
AddButton(TeleportPage, "Teleport to area", function()
    local area
    for _, a in ipairs(FULLTRAIN_AREAS) do
        if a.section == tpArea then area = a break end
    end
    if not area then return end
    local ch = charParts()
    if ch then
        pcall(function()
            ch:PivotTo(CFrame.new(area.center + Vector3.new(0, 12, 0)))
        end)
        Notify("Teleported to " .. area.section, 1.5)
    end
end)

local PlayerPage = AddTab("Player")
AddLabel(PlayerPage, "CHARACTER")
AddSlider(PlayerPage, "WalkSpeed", 16, 200, 16, function(v)
    local _, hum = charParts()
    if hum then hum.WalkSpeed = v end
end)
AddSlider(PlayerPage, "JumpPower", 50, 300, 50, function(v)
    local _, hum = charParts()
    if hum then hum.JumpPower = v end
end)
AddSlider(PlayerPage, "Character size", 1, 100, 1, function(v)
    local rem = remote("changeSpeedSizeRemote")
    if not rem then return end
    if rem:IsA("RemoteFunction") then
        task.spawn(function() pcall(rem.InvokeServer, rem, "changeSize", v) end)
    elseif rem:IsA("RemoteEvent") then
        pcall(rem.FireServer, rem, "changeSize", v)
    end
end)

local MiscPage = AddTab("Misc")
AddLabel(MiscPage, "UTILITY")
AddToggle(MiscPage, "Anti-AFK", false, function(v) setAntiAfk(v) end)
AddToggle(MiscPage, "Hide my pets", false, function(v)
    local rem = remote("showPetsEvent")
    local currentlyVisible = LP:GetAttribute("PetsVisible") == true
    if currentlyVisible == v and rem and rem:IsA("RemoteEvent") then
        pcall(rem.FireServer, rem, v and "hidePets" or "showPets")
    end
    Notify(v and "Pets hidden" or "Pets visible", 1.5)
end)
AddToggle(MiscPage, "Hide damage popups", false, function(v)
    local desiredShown = not v
    local currentlyShown = LP:GetAttribute("ShowPopups") ~= false
    if currentlyShown ~= desiredShown then
        LP:SetAttribute("ShowPopups", desiredShown)
        local rem = remote("savePlayerSizeEvent")
        if rem and rem:IsA("RemoteEvent") then
            pcall(rem.FireServer, rem, "showPopupsOption")
        end
    end
    Notify(v and "Popups hidden" or "Popups shown", 1.5)
end)
AddToggle(MiscPage, "FPS Boost (no 3D render)", false, function(v)
    pcall(function()
        RunService:Set3dRenderingEnabled(not v)
    end)
    Notify(v and "3D rendering disabled" or "3D rendering enabled", 2)
end)
local overlayOn = false
local overlayToggle = AddToggle(MiscPage, "FPS & Ping overlay", false, function(v) overlayOn = v overlayGuiSet(v) end)

local Overlay = New("ScreenGui", { Name = "NoirMLStats", ResetOnSpawn = false, IgnoreGuiInset = true, Enabled = false, DisplayOrder = 300 }, CoreGui)
local Panel = New("Frame", {
    Size = UDim2.fromOffset(118, 46), Position = UDim2.new(0, 20, 0.5, -23),
    BackgroundColor3 = C.base, BackgroundTransparency = 0.15, BorderSizePixel = 0, Active = true,
}, Overlay)
corner(Panel, 10)
local panelStroke = stroke(Panel, C.accent, 0.45, 1)
New("TextLabel", {
    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15), Position = UDim2.fromOffset(0, 2),
    Font = Enum.Font.GothamBold, Text = "FPS & PING", TextColor3 = C.accent2, TextSize = 9,
}, Panel)
local holder = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 16), Size = UDim2.new(1, -16, 0, 24) }, Panel)
New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6) }, holder)
local function chip(tag)
    local c = New("Frame", { Size = UDim2.fromOffset(46, 24), BackgroundColor3 = C.surface, BorderSizePixel = 0 }, holder)
    corner(c, 8)
    stroke(c, C.border, 0.3, 1)
    New("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 2), Size = UDim2.new(1, -8, 0, 9),
        Font = Enum.Font.GothamBold, Text = tag, TextColor3 = C.dim, TextSize = 8,
    }, c)
    local v = New("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 13),
        Font = Enum.Font.GothamBold, Text = "--", TextColor3 = C.text, TextSize = 12,
    }, c)
    return v
end
local fpsVal = chip("FPS")
local pingVal = chip("PING")
draggable(Panel)
function overlayGuiSet(v) Overlay.Enabled = v end

task.spawn(function()
    local frames, elapsed, fps = 0, 0, 0
    RunService.RenderStepped:Connect(function(dt)
        frames += 1
        elapsed += dt
        if elapsed >= 0.5 then
            fps = math.round(frames / elapsed)
            frames = 0
            elapsed = 0
        end
    end)
    while ScreenGui.Parent do
        if Overlay.Enabled then
            pcall(function()
                local ping = math.round((LP:GetNetworkPing() or 0) * 1000)
                fpsVal.Text = tostring(fps)
                pingVal.Text = tostring(ping)
                fpsVal.TextColor3 = fps >= 50 and C.ok or (fps >= 25 and C.accent2 or C.err)
                pingVal.TextColor3 = ping <= 100 and C.ok or (ping <= 180 and C.accent2 or C.err)
            end)
        end
        task.wait(0.25)
    end
end)

do
    pcall(function()
        local env = penv
        local t = os.clock()
        env.__NoirHubRuntimeLock = { state = "running", startedAt = t, heartbeat = t }
        task.spawn(function()
            while task.wait(5) do
                local lock = env.__NoirHubRuntimeLock
                if type(lock) ~= "table" or lock.state ~= "running" then break end
                lock.heartbeat = os.clock()
            end
        end)
    end)
end

do
    local PERSIST_KEY = "NoirMLState"
    local saved = ((type(penv.getgenv) == "function" and penv.getgenv())
        or (type(getgenv) == "function" and getgenv()) or {})[PERSIST_KEY]
    if type(saved) == "table" then
        if type(saved.values) == "table" then
            for k, v in pairs(saved.values) do
                if S[k] ~= nil then S[k] = v end
            end
        end
        if type(saved.toggles) == "table" then
            for title, on in pairs(saved.toggles) do
                if on == true and ToggleRegistry[title] then
                    task.delay(0.5, function()
                        local entry = ToggleRegistry[title]
                        if entry and not entry.get() then
                            pcall(entry.set, true, true)
                        end
                    end)
                end
            end
        end
    end
    task.spawn(function()
        while alive do
            if type(getgenv) == "function" or type(penv.getgenv) == "function" then
                local toggles = {}
                for title, entry in pairs(ToggleRegistry) do
                    local ok, state = pcall(entry.get)
                    if ok then toggles[title] = state end
                end
                local env = (type(penv.getgenv) == "function" and penv.getgenv())
                    or (type(getgenv) == "function" and getgenv())
                if env then
                    env[PERSIST_KEY] = {
                        toggles = toggles,
                        values = {
                            machine = S.machine,
                            selectedRock = S.selectedRock,
                            repRate = S.repRate,
                            fullTrainArea = S.fullTrainArea,
                            crystalName = S.crystalName,
                            petChoice = S.petChoice,
                            auraChoice = S.auraChoice,
                        },
                    }
                end
            end
            task.wait(3)
        end
    end)
end

Notify("Noir Muscle Legends loaded", 2.5)
