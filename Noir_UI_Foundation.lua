--[[
    NOIR x KITI — UI FOUNDATION (UI ONLY)
    Inspired by the compact KITI sidebar and Noir's dark, restrained visual style.
    No gameplay functions, remotes, executor APIs, external assets, or HTTP requests.
    Put this LocalScript in StarterPlayerScripts or run it in a compatible client environment.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local previous = playerGui:FindFirstChild("NoirKitiUI")
if previous then previous:Destroy() end

local Theme = {
    bg = Color3.fromRGB(8, 10, 11),
    shell = Color3.fromRGB(12, 14, 16),
    panel = Color3.fromRGB(16, 19, 21),
    card = Color3.fromRGB(19, 22, 24),
    raised = Color3.fromRGB(25, 29, 31),
    hover = Color3.fromRGB(31, 36, 37),
    border = Color3.fromRGB(48, 55, 54),
    text = Color3.fromRGB(235, 239, 235),
    muted = Color3.fromRGB(135, 145, 140),
    dim = Color3.fromRGB(88, 99, 93),
    accent = Color3.fromRGB(103, 190, 112),
    accentBright = Color3.fromRGB(145, 222, 150),
    accentDark = Color3.fromRGB(29, 57, 35),
    red = Color3.fromRGB(225, 91, 103),
    blue = Color3.fromRGB(115, 177, 218),
}

local function tw(instance, duration, goal, style, direction)
    if not instance or not instance.Parent then return nil end
    local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
    local animation = TweenService:Create(instance, info, goal)
    animation:Play()
    return animation
end

local function new(className, props, parent)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do object[key] = value end
    object.Parent = parent
    return object
end

local function round(parent, radius)
    return new("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, parent)
end

local function outline(parent, color, transparency, thickness)
    return new("UIStroke", {
        Color = color or Theme.border,
        Transparency = transparency == nil and 0 or transparency,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function inset(parent, left, right, top, bottom)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    }, parent)
end

local function text(parent, value, size, color, font, xAlign)
    return new("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = value or "",
        TextSize = size or 12,
        TextColor3 = color or Theme.text,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = xAlign or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
end

local function button(parent, value, size, bg, fg)
    return new("TextButton", {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Text = value or "",
        TextSize = 12,
        Font = Enum.Font.GothamSemibold,
        TextColor3 = fg or Theme.text,
        BackgroundColor3 = bg or Theme.raised,
        Size = size,
    }, parent)
end

local gui = new("ScreenGui", {
    Name = "NoirKitiUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 90,
}, playerGui)

local root = new("CanvasGroup", {
    Name = "Root",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.51),
    Size = UDim2.fromOffset(820, 540),
    BackgroundColor3 = Theme.shell,
    BorderSizePixel = 0,
    GroupTransparency = 1,
    ClipsDescendants = true,
}, gui)
round(root, 12)
outline(root, Theme.border, 0.18, 1)
local rootScale = new("UIScale", {Scale = 0.94}, root)


-- KITI-inspired compact icon rail.
local rail = new("Frame", {
    Name = "Rail",
    Size = UDim2.new(0, 78, 1, 0),
    BackgroundColor3 = Theme.bg,
    BorderSizePixel = 0,
}, root)
new("Frame", {
    Position = UDim2.new(1, -1, 0, 0),
    Size = UDim2.new(0, 1, 1, 0),
    BackgroundColor3 = Theme.border,
    BackgroundTransparency = 0.25,
    BorderSizePixel = 0,
}, rail)

local logo = new("Frame", {
    Position = UDim2.fromOffset(16, 15),
    Size = UDim2.fromOffset(46, 46),
    BackgroundColor3 = Theme.accentDark,
    BorderSizePixel = 0,
}, rail)
round(logo, 13)
outline(logo, Theme.accent, 0.35, 1)
local logoGrad = new("UIGradient", {
    Rotation = 35,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.accentDark),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(17, 30, 22)),
    }),
}, logo)
local logoMark = text(logo, "N", 24, Theme.accentBright, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
logoMark.Size = UDim2.fromScale(1, 1)

local railLine = new("Frame", {
    Position = UDim2.fromOffset(24, 75),
    Size = UDim2.fromOffset(30, 1),
    BackgroundColor3 = Theme.border,
    BackgroundTransparency = 0.25,
    BorderSizePixel = 0,
}, rail)

local navHolder = new("Frame", {
    Position = UDim2.fromOffset(9, 91),
    Size = UDim2.new(1, -18, 1, -162),
    BackgroundTransparency = 1,
}, rail)
local navLayout = new("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, navHolder)

local railFooter = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -13),
    Size = UDim2.fromOffset(46, 46),
    BackgroundColor3 = Theme.panel,
    BorderSizePixel = 0,
}, rail)
round(railFooter, 23)
outline(railFooter, Theme.border, 0.3, 1)
local avatarText = text(railFooter, string.sub(player.DisplayName or player.Name, 1, 1):upper(), 16, Theme.accentBright, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
avatarText.Size = UDim2.fromScale(1, 1)

-- Main header and content.
local main = new("Frame", {
    Name = "Main",
    Position = UDim2.fromOffset(78, 0),
    Size = UDim2.new(1, -78, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, root)

local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 64),
    BackgroundColor3 = Theme.shell,
    BorderSizePixel = 0,
}, main)
new("Frame", {
    Position = UDim2.new(0, 22, 1, -1),
    Size = UDim2.new(1, -44, 0, 1),
    BackgroundColor3 = Theme.border,
    BackgroundTransparency = 0.4,
    BorderSizePixel = 0,
}, header)

local title = text(header, "Overview", 20, Theme.text, Enum.Font.GothamBold)
title.Position = UDim2.fromOffset(23, 11)
title.Size = UDim2.new(1, -170, 0, 27)
local subtitle = text(header, "NOIR  /  INTERFACE", 9, Theme.muted, Enum.Font.GothamMedium)
subtitle.Position = UDim2.fromOffset(24, 38)
subtitle.Size = UDim2.new(1, -170, 0, 14)

local livePill = new("Frame", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -94, 0.5, 0),
    Size = UDim2.fromOffset(72, 25),
    BackgroundColor3 = Theme.accentDark,
    BorderSizePixel = 0,
}, header)
round(livePill, 8)
local liveDot = new("Frame", {
    Position = UDim2.fromOffset(9, 9),
    Size = UDim2.fromOffset(7, 7),
    BackgroundColor3 = Theme.accent,
    BorderSizePixel = 0,
}, livePill)
round(liveDot, 4)
local liveText = text(livePill, "READY", 9, Theme.accentBright, Enum.Font.GothamBold)
liveText.Position = UDim2.fromOffset(22, 0)
liveText.Size = UDim2.new(1, -24, 1, 0)

local minimize = button(header, "—", UDim2.fromOffset(27, 27), Theme.panel, Theme.muted)
minimize.Position = UDim2.new(1, -57, 0.5, -13)
round(minimize, 8)
local close = button(header, "×", UDim2.fromOffset(27, 27), Theme.panel, Theme.muted)
close.Position = UDim2.new(1, -24, 0.5, -13)
round(close, 8)

local body = new("Frame", {
    Position = UDim2.fromOffset(0, 64),
    Size = UDim2.new(1, 0, 1, -64),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, main)

local pages = {}
local navItems = {}
local currentPage = nil
local minimized = false
local expandedSize = root.Size
local pageInfo = {
    Overview = {icon = "⌂", subtitle = "NOIR  /  INTERFACE"},
    Visuals = {icon = "◈", subtitle = "NOIR  /  VISUAL CONTROLS"},
    Controls = {icon = "☷", subtitle = "NOIR  /  COMPONENTS"},
    Settings = {icon = "⚙", subtitle = "NOIR  /  PREFERENCES"},
    About = {icon = "✦", subtitle = "NOIR  /  BUILD INFO"},
}

local function makePage(name)
    local page = new("ScrollingFrame", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, body)
    inset(page, 22, 22, 18, 22)
    new("UIListLayout", {
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    pages[name] = page
    return page
end

local function section(parent, heading, detail)
    local box = new("Frame", {
        Size = UDim2.new(1, -1, 0, 52),
        BackgroundColor3 = Theme.panel,
        BorderSizePixel = 0,
    }, parent)
    round(box, 9)
    outline(box, Theme.border, 0.48, 1)
    local marker = new("Frame", {
        Position = UDim2.fromOffset(0, 13),
        Size = UDim2.fromOffset(3, 26),
        BackgroundColor3 = Theme.accent,
        BorderSizePixel = 0,
    }, box)
    round(marker, 2)
    local head = text(box, heading, 12, Theme.text, Enum.Font.GothamBold)
    head.Position = UDim2.fromOffset(14, 7)
    head.Size = UDim2.new(1, -25, 0, 18)
    local sub = text(box, detail or "", 10, Theme.muted, Enum.Font.Gotham)
    sub.Position = UDim2.fromOffset(14, 26)
    sub.Size = UDim2.new(1, -25, 0, 16)
    return box
end

local function card(parent, height)
    local box = new("Frame", {
        Size = UDim2.new(1, -1, 0, height or 66),
        BackgroundColor3 = Theme.panel,
        BorderSizePixel = 0,
    }, parent)
    round(box, 9)
    outline(box, Theme.border, 0.52, 1)
    return box
end

local function addToggle(parent, heading, detail, initial)
    local row = card(parent, 62)
    local name = text(row, heading, 12, Theme.text, Enum.Font.GothamSemibold)
    name.Position = UDim2.fromOffset(14, 8)
    name.Size = UDim2.new(1, -95, 0, 20)
    local desc = text(row, detail or "Interface demo only", 10, Theme.muted)
    desc.Position = UDim2.fromOffset(14, 31)
    desc.Size = UDim2.new(1, -95, 0, 16)

    local switch = button(row, "", UDim2.fromOffset(38, 21), initial and Theme.accent or Theme.raised, Theme.text)
    switch.Position = UDim2.new(1, -53, 0.5, -10)
    round(switch, 11)
    local knob = new("Frame", {
        Position = initial and UDim2.new(1, -18, 0, 3) or UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(15, 15),
        BackgroundColor3 = Theme.text,
        BorderSizePixel = 0,
    }, switch)
    round(knob, 9)
    local state = initial == true
    switch.Activated:Connect(function()
        state = not state
        tw(switch, 0.18, {BackgroundColor3 = state and Theme.accent or Theme.raised})
        tw(knob, 0.22, {Position = state and UDim2.new(1, -18, 0, 3) or UDim2.fromOffset(3, 3)}, Enum.EasingStyle.Back)
    end)
    return row
end

local function addButtonRow(parent, heading, detail, actionText, callback)
    local row = card(parent, 66)
    local name = text(row, heading, 12, Theme.text, Enum.Font.GothamSemibold)
    name.Position = UDim2.fromOffset(14, 8)
    name.Size = UDim2.new(1, -130, 0, 20)
    local desc = text(row, detail or "", 10, Theme.muted)
    desc.Position = UDim2.fromOffset(14, 31)
    desc.Size = UDim2.new(1, -130, 0, 16)
    local action = button(row, actionText or "Test", UDim2.fromOffset(88, 30), Theme.raised, Theme.text)
    action.AnchorPoint = Vector2.new(1, 0.5)
    action.Position = UDim2.new(1, -12, 0.5, 0)
    round(action, 7)
    local edge = outline(action, Theme.border, 0.3, 1)
    action.MouseEnter:Connect(function()
        tw(action, 0.14, {BackgroundColor3 = Theme.accentDark, TextColor3 = Theme.accentBright, Size = UDim2.fromOffset(92, 31)})
        tw(edge, 0.14, {Color = Theme.accent, Transparency = 0.15})
    end)
    action.MouseLeave:Connect(function()
        tw(action, 0.16, {BackgroundColor3 = Theme.raised, TextColor3 = Theme.text, Size = UDim2.fromOffset(88, 30)})
        tw(edge, 0.16, {Color = Theme.border, Transparency = 0.3})
    end)
    action.Activated:Connect(function()
        tw(action, 0.07, {Size = UDim2.fromOffset(84, 28)})
        task.delay(0.08, function()
            if action.Parent then tw(action, 0.15, {Size = UDim2.fromOffset(92, 31)}) end
        end)
        if callback then callback() end
    end)
    return row
end

local function addSlider(parent, heading, minimum, maximum, startValue)
    local row = card(parent, 72)
    local name = text(row, heading, 12, Theme.text, Enum.Font.GothamSemibold)
    name.Position = UDim2.fromOffset(14, 7)
    name.Size = UDim2.new(1, -90, 0, 20)
    local val = text(row, tostring(startValue), 11, Theme.accentBright, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
    val.Position = UDim2.new(1, -61, 0, 7)
    val.Size = UDim2.fromOffset(45, 20)

    local track = button(row, "", UDim2.new(1, -28, 0, 6), Theme.raised)
    track.Position = UDim2.fromOffset(14, 47)
    round(track, 4)
    local alpha = math.clamp((startValue - minimum) / math.max(maximum - minimum, 1), 0, 1)
    local fill = new("Frame", {
        Size = UDim2.new(alpha, 0, 1, 0),
        BackgroundColor3 = Theme.accent,
        BorderSizePixel = 0,
    }, track)
    round(fill, 4)
    local thumb = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(alpha, 0, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Theme.text,
        BorderSizePixel = 0,
    }, track)
    round(thumb, 7)
    local dragging = false
    local function update(x)
        local width = math.max(track.AbsoluteSize.X, 1)
        local ratio = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
        local current = math.floor(minimum + (maximum - minimum) * ratio + 0.5)
        val.Text = tostring(current)
        tw(fill, 0.06, {Size = UDim2.new(ratio, 0, 1, 0)}, Enum.EasingStyle.Linear)
        tw(thumb, 0.06, {Position = UDim2.new(ratio, 0, 0.5, 0)}, Enum.EasingStyle.Linear)
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    return row
end

-- Animated toast notifications, styled with Noir's accent line.
local toastHolder = new("Frame", {
    Name = "ToastHolder",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -18, 0, 18),
    Size = UDim2.fromOffset(310, 300),
    BackgroundTransparency = 1,
    ZIndex = 100,
}, gui)
new("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Top,
}, toastHolder)

local toastOrder = 0
local function notify(heading, detail, kind)
    toastOrder += 1
    local accent = kind == "error" and Theme.red or (kind == "info" and Theme.blue or Theme.accent)
    local toast = new("CanvasGroup", {
        LayoutOrder = -toastOrder,
        Size = UDim2.fromOffset(300, 72),
        Position = UDim2.fromOffset(20, 0),
        BackgroundColor3 = Theme.panel,
        BackgroundTransparency = 0.04,
        GroupTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 101,
    }, toastHolder)
    round(toast, 9)
    outline(toast, Theme.border, 0.25, 1)
    local stripe = new("Frame", {
        Position = UDim2.fromOffset(0, 12),
        Size = UDim2.fromOffset(3, 48),
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        ZIndex = 102,
    }, toast)
    round(stripe, 2)
    local headingLabel = text(toast, heading or "NOIR", 12, Theme.text, Enum.Font.GothamBold)
    headingLabel.Position = UDim2.fromOffset(14, 10)
    headingLabel.Size = UDim2.new(1, -25, 0, 20)
    headingLabel.ZIndex = 102
    local detailLabel = text(toast, detail or "Preview notification", 10, Theme.muted)
    detailLabel.Position = UDim2.fromOffset(14, 32)
    detailLabel.Size = UDim2.new(1, -25, 0, 27)
    detailLabel.TextWrapped = true
    detailLabel.TextYAlignment = Enum.TextYAlignment.Top
    detailLabel.ZIndex = 102
    tw(toast, 0.26, {Position = UDim2.fromOffset(0, 0), GroupTransparency = 0}, Enum.EasingStyle.Quint)
    task.delay(3.3, function()
        if toast.Parent then
            tw(toast, 0.22, {Position = UDim2.fromOffset(22, 0), GroupTransparency = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.wait(0.24)
            if toast.Parent then toast:Destroy() end
        end
    end)
end

-- Pages use KITI-style compact sections and Noir dashboard cards.
local overview = makePage("OverviewPage")
section(overview, "Dashboard", "A compact control surface for the new Noir UI.")
local identity = card(overview, 104)
local identityMark = new("Frame", {
    Position = UDim2.fromOffset(15, 17),
    Size = UDim2.fromOffset(54, 54),
    BackgroundColor3 = Theme.accentDark,
    BorderSizePixel = 0,
}, identity)
round(identityMark, 13)
outline(identityMark, Theme.accent, 0.4, 1)
local identityGlyph = text(identityMark, "N", 26, Theme.accentBright, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
identityGlyph.Size = UDim2.fromScale(1, 1)
local identityName = text(identity, "NOIR HUB", 18, Theme.text, Enum.Font.GothamBlack)
identityName.Position = UDim2.fromOffset(83, 18)
identityName.Size = UDim2.new(1, -100, 0, 25)
local identityDesc = text(identity, "KITI layout × Noir visual language", 11, Theme.muted)
identityDesc.Position = UDim2.fromOffset(84, 46)
identityDesc.Size = UDim2.new(1, -100, 0, 18)
local identityStatus = text(identity, "●  UI FOUNDATION  /  NO GAME FEATURES", 9, Theme.accentBright, Enum.Font.GothamBold)
identityStatus.Position = UDim2.fromOffset(84, 69)
identityStatus.Size = UDim2.new(1, -100, 0, 18)

local metrics = new("Frame", {Size = UDim2.new(1, -1, 0, 88), BackgroundTransparency = 1}, overview)
local metricsLayout = new("UIGridLayout", {
    CellPadding = UDim2.fromOffset(10, 0),
    CellSize = UDim2.new(0.3333, -7, 1, 0),
    FillDirectionMaxCells = 3,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, metrics)
local function metric(parent, order, caption, value, accent)
    local box = new("Frame", {
        LayoutOrder = order,
        BackgroundColor3 = Theme.panel,
        BorderSizePixel = 0,
    }, parent)
    round(box, 9)
    outline(box, Theme.border, 0.5, 1)
    local cap = text(box, caption:upper(), 9, Theme.muted, Enum.Font.GothamBold)
    cap.Position = UDim2.fromOffset(12, 12)
    cap.Size = UDim2.new(1, -20, 0, 16)
    local number = text(box, value, 21, accent or Theme.text, Enum.Font.GothamBold)
    number.Position = UDim2.fromOffset(12, 34)
    number.Size = UDim2.new(1, -20, 0, 29)
    return box
end
metric(metrics, 1, "Build", "01", Theme.accentBright)
metric(metrics, 2, "Mode", "UI", Theme.blue)
metric(metrics, 3, "Status", "Ready", Theme.text)
addButtonRow(overview, "Toast system", "Preview the KITI × Noir notification style.", "Preview", function()
    notify("Noir notification", "This is a preview only. Nothing in the game was changed.", "success")
end)
addButtonRow(overview, "Motion preview", "Test the press feedback and easing.", "Play", function()
    notify("Motion system", "Button press and toast transitions are enabled.", "info")
end)

local visuals = makePage("VisualsPage")
section(visuals, "Visual components", "Example controls only. They are not wired to gameplay.")
addToggle(visuals, "Example switch", "Compact KITI-style toggle with Noir accent.", false)
addToggle(visuals, "Soft transitions", "Visual preference placeholder.", true)
addToggle(visuals, "Show status pill", "Visual preference placeholder.", true)
addSlider(visuals, "Animation strength", 0, 100, 70)
addSlider(visuals, "Interface scale", 80, 120, 100)

local controls = makePage("ControlsPage")
section(controls, "Control library", "Reusable components to connect later.")
addToggle(controls, "Toggle component", "Switch component sample.", false)
addSlider(controls, "Slider component", 0, 100, 40)
addButtonRow(controls, "Button component", "Hover, click and release animation.", "Click", function()
    notify("Button pressed", "Component callback fired successfully.", "success")
end)
local dropdownRow = card(controls, 64)
local dropdownTitle = text(dropdownRow, "Dropdown component", 12, Theme.text, Enum.Font.GothamSemibold)
dropdownTitle.Position = UDim2.fromOffset(14, 8)
dropdownTitle.Size = UDim2.new(1, -150, 0, 20)
local dropdownDesc = text(dropdownRow, "Small animated option menu.", 10, Theme.muted)
dropdownDesc.Position = UDim2.fromOffset(14, 31)
dropdownDesc.Size = UDim2.new(1, -150, 0, 16)
local dropdown = button(dropdownRow, "Default  ▾", UDim2.fromOffset(112, 30), Theme.raised, Theme.text)
dropdown.AnchorPoint = Vector2.new(1, 0.5)
dropdown.Position = UDim2.new(1, -12, 0.5, 0)
round(dropdown, 7)
local dropOptions = {"Default", "Compact", "Comfort"}
local dropIndex = 1
dropdown.Activated:Connect(function()
    dropIndex = dropIndex % #dropOptions + 1
    dropdown.Text = dropOptions[dropIndex] .. "  ▾"
    tw(dropdown, 0.1, {BackgroundColor3 = Theme.accentDark})
    task.delay(0.12, function()
        if dropdown.Parent then tw(dropdown, 0.14, {BackgroundColor3 = Theme.raised}) end
    end)
end)

local settings = makePage("SettingsPage")
section(settings, "Window preferences", "A few basic interface controls.")
addButtonRow(settings, "Reset window position", "Return the panel to the center of the screen.", "Reset", function()
    root.Position = UDim2.fromScale(0.5, 0.51)
    notify("Window reset", "The window was centered.", "success")
end)
addToggle(settings, "Compact mode", "Demo switch; layout remains unchanged.", false)
addToggle(settings, "Reduced motion", "Demo preference; current animations remain active.", false)
addButtonRow(settings, "Notification preview", "Check the notification entrance and exit.", "Show", function()
    notify("Settings", "Notification preview from the Settings page.", "info")
end)

local about = makePage("AboutPage")
section(about, "Noir × KITI", "A merged visual direction, not copied gameplay logic.")
local aboutCard = card(about, 144)
local aboutTitle = text(aboutCard, "DESIGN NOTES", 12, Theme.text, Enum.Font.GothamBold)
aboutTitle.Position = UDim2.fromOffset(15, 13)
aboutTitle.Size = UDim2.new(1, -30, 0, 20)
local aboutBody = text(aboutCard,
    "• KITI: compact icon rail, section spacing and reusable controls\n• Noir: charcoal palette, restrained green accent and dashboard cards\n• Motion: short tweens, eased tab transitions and toast notifications\n• Scope: interface only — no game actions, remotes or external downloads",
    10, Theme.muted, Enum.Font.Gotham)
aboutBody.Position = UDim2.fromOffset(15, 39)
aboutBody.Size = UDim2.new(1, -30, 0, 93)
aboutBody.TextYAlignment = Enum.TextYAlignment.Top
aboutBody.TextWrapped = true

local function addNav(name, order)
    local data = pageInfo[name]
    local nav = button(navHolder, "", UDim2.fromOffset(54, 48), Theme.bg, Theme.muted)
    nav.Name = name .. "Button"
    nav.LayoutOrder = order
    round(nav, 10)
    local glyph = text(nav, data.icon, 20, Theme.muted, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    glyph.Size = UDim2.fromScale(1, 1)
    local activeBar = new("Frame", {
        Position = UDim2.new(0, -8, 0.5, -10),
        Size = UDim2.fromOffset(3, 20),
        BackgroundColor3 = Theme.accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, nav)
    round(activeBar, 2)
    nav.MouseEnter:Connect(function()
        if currentPage ~= name then
            tw(nav, 0.14, {BackgroundColor3 = Theme.panel})
            tw(glyph, 0.14, {TextColor3 = Theme.text})
        end
    end)
    nav.MouseLeave:Connect(function()
        if currentPage ~= name then
            tw(nav, 0.14, {BackgroundColor3 = Theme.bg})
            tw(glyph, 0.14, {TextColor3 = Theme.muted})
        end
    end)
    nav.Activated:Connect(function()
        if currentPage == name then return end
        local old = currentPage
        currentPage = name
        for pageName, page in pairs(pages) do
            if pageName == name then
                page.Visible = true
                page.Position = UDim2.fromOffset(10, 0)
                page.CanvasPosition = Vector2.zero
                tw(page, 0.22, {Position = UDim2.fromOffset(0, 0)}, Enum.EasingStyle.Quint)
            elseif pageName == old then
                page.Visible = false
            else
                page.Visible = false
            end
        end
        for navName, item in pairs(navItems) do
            local selected = navName == name
            tw(item.button, 0.16, {BackgroundColor3 = selected and Theme.raised or Theme.bg})
            tw(item.glyph, 0.16, {TextColor3 = selected and Theme.accentBright or Theme.muted})
            tw(item.bar, 0.16, {BackgroundTransparency = selected and 0 or 1})
        end
        title.Text = name
        subtitle.Text = data.subtitle
    end)
    navItems[name] = {button = nav, glyph = glyph, bar = activeBar}
end

for i, name in ipairs({"Overview", "Visuals", "Controls", "Settings", "About"}) do addNav(name, i) end

-- Drag from the title area; buttons are kept out of the drag hit zone.
local dragging = false
local dragStart
local startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if input.Position.X >= minimize.AbsolutePosition.X - 4 then return end
        dragging = true
        dragStart = input.Position
        startPos = root.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- Resize grip at bottom-right.
local resizeGrip = button(root, "◢", UDim2.fromOffset(22, 22), Theme.shell, Theme.dim)
resizeGrip.AnchorPoint = Vector2.new(1, 1)
resizeGrip.Position = UDim2.new(1, -3, 1, -3)
resizeGrip.TextSize = 12
resizeGrip.ZIndex = 20
local resizing = false
local resizeStart
local sizeStart
resizeGrip.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStart = input.Position
        sizeStart = root.AbsoluteSize
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - resizeStart
        local width = math.clamp(sizeStart.X + delta.X, 340, 1200)
        local height = math.clamp(sizeStart.Y + delta.Y, 300, 900)
        root.Size = UDim2.fromOffset(width, height)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resizing = false end
end)

minimize.MouseEnter:Connect(function() tw(minimize, 0.12, {BackgroundColor3 = Theme.raised, TextColor3 = Theme.text}) end)
minimize.MouseLeave:Connect(function() tw(minimize, 0.12, {BackgroundColor3 = Theme.panel, TextColor3 = Theme.muted}) end)
close.MouseEnter:Connect(function() tw(close, 0.12, {BackgroundColor3 = Color3.fromRGB(67, 28, 31), TextColor3 = Theme.red}) end)
close.MouseLeave:Connect(function() tw(close, 0.12, {BackgroundColor3 = Theme.panel, TextColor3 = Theme.muted}) end)

minimize.Activated:Connect(function()
    minimized = not minimized
    if minimized then
        expandedSize = root.Size
        rail.Visible = false
        body.Visible = false
        main.Position = UDim2.fromOffset(0, 0)
        main.Size = UDim2.new(1, 0, 1, 0)
        tw(root, 0.24, {Size = UDim2.fromOffset(400, 64)}, Enum.EasingStyle.Quint)
    else
        rail.Visible = true
        body.Visible = true
        main.Position = UDim2.fromOffset(78, 0)
        main.Size = UDim2.new(1, -78, 1, 0)
        tw(root, 0.26, {Size = expandedSize}, Enum.EasingStyle.Back)
    end
end)

close.Activated:Connect(function()
    local out = tw(root, 0.18, {GroupTransparency = 1, Position = UDim2.fromScale(0.5, 0.53)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    tw(rootScale, 0.18, {Scale = 0.96}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    if out then out.Completed:Wait() end
    if gui.Parent then gui:Destroy() end
end)

-- Responsive scaling for smaller screens.
local camera = workspace.CurrentCamera
local function updateScale()
    if not rootScale or not rootScale.Parent then return end
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local ratio = math.min(viewport.X / 840, viewport.Y / 560, 1)
    rootScale.Scale = math.clamp(ratio, 0.42, 1)
end
updateScale()
if camera then
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

-- Initial page and entrance.
navItems.Overview.button:Activate()
task.defer(function()
    if root.Parent then
        tw(root, 0.32, {GroupTransparency = 0}, Enum.EasingStyle.Quint)
        tw(rootScale, 0.42, {Scale = math.max(rootScale.Scale, 0.88)}, Enum.EasingStyle.Back)
    end
end)
task.delay(0.6, function()
    if gui.Parent then notify("Noir × KITI", "The UI is ready. All controls are demo-only.", "success") end
end)
