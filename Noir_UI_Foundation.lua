--[[
    NOIR UI — UI ONLY
    Standalone Roblox LocalScript for Roblox Studio.
    Contains no game-affecting features: only interface, navigation, animations,
    demo toggles/sliders, and UI notifications.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remove an older copy of this UI.
local old = playerGui:FindFirstChild("NoirUI")
if old then old:Destroy() end

local Theme = {
    Background = Color3.fromRGB(10, 11, 16),
    Panel = Color3.fromRGB(17, 19, 27),
    Panel2 = Color3.fromRGB(22, 25, 35),
    PanelHover = Color3.fromRGB(30, 34, 47),
    Stroke = Color3.fromRGB(48, 53, 70),
    Text = Color3.fromRGB(240, 242, 250),
    Muted = Color3.fromRGB(145, 151, 171),
    Accent = Color3.fromRGB(151, 105, 255),
    Accent2 = Color3.fromRGB(90, 194, 255),
    Success = Color3.fromRGB(105, 225, 170),
    Danger = Color3.fromRGB(255, 105, 130),
}

local function tween(object, duration, properties, style, direction)
    local info = TweenInfo.new(
        duration,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )
    local animation = TweenService:Create(object, info, properties)
    animation:Play()
    return animation
end

local function corner(parent, radius)
    local item = Instance.new("UICorner")
    item.CornerRadius = UDim.new(0, radius or 10)
    item.Parent = parent
    return item
end

local function stroke(parent, color, transparency, thickness)
    local item = Instance.new("UIStroke")
    item.Color = color or Theme.Stroke
    item.Transparency = transparency or 0
    item.Thickness = thickness or 1
    item.Parent = parent
    return item
end

local function padding(parent, left, right, top, bottom)
    local item = Instance.new("UIPadding")
    item.PaddingLeft = UDim.new(0, left or 0)
    item.PaddingRight = UDim.new(0, right or 0)
    item.PaddingTop = UDim.new(0, top or 0)
    item.PaddingBottom = UDim.new(0, bottom or 0)
    item.Parent = parent
    return item
end

local function make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function label(parent, text, size, color, font)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color or Theme.Text,
        TextSize = size or 14,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.None,
    }, parent)
end

local screen = make("ScreenGui", {
    Name = "NoirUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 50,
}, playerGui)

-- Soft backdrop glow.
local glow = make("Frame", {
    Name = "Glow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(740, 520),
    BackgroundColor3 = Theme.Accent,
    BackgroundTransparency = 0.91,
    BorderSizePixel = 0,
    ZIndex = 0,
}, screen)
corner(glow, 36)

local main = make("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.53),
    Size = UDim2.fromOffset(760, 500),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 1,
}, screen)
corner(main, 16)
stroke(main, Theme.Stroke, 0.18, 1)

local mainScale = make("UIScale", { Scale = 0.92 }, main)
tween(mainScale, 0.42, { Scale = 1 }, Enum.EasingStyle.Back)

-- Header.
local header = make("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 66),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0,
    ZIndex = 2,
}, main)
corner(header, 16)

local headerCover = make("Frame", {
    Position = UDim2.new(0, 0, 1, -16),
    Size = UDim2.new(1, 0, 0, 16),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0,
    ZIndex = 2,
}, header)

local logo = make("Frame", {
    Position = UDim2.fromOffset(18, 15),
    Size = UDim2.fromOffset(36, 36),
    BackgroundColor3 = Theme.Accent,
    BorderSizePixel = 0,
    ZIndex = 3,
}, header)
corner(logo, 11)
local logoGradient = make("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(1, Theme.Accent2),
    }),
    Rotation = 35,
}, logo)
local logoText = label(logo, "N", 21, Color3.new(1, 1, 1), Enum.Font.GothamBlack)
logoText.Size = UDim2.fromScale(1, 1)
logoText.TextXAlignment = Enum.TextXAlignment.Center

local brand = label(header, "NOIR", 18, Theme.Text, Enum.Font.GothamBlack)
brand.Position = UDim2.fromOffset(66, 12)
brand.Size = UDim2.fromOffset(110, 24)
local subtitle = label(header, "INTERFACE  /  CONTROL CENTER", 9, Theme.Muted, Enum.Font.GothamMedium)
subtitle.Position = UDim2.fromOffset(67, 35)
subtitle.Size = UDim2.fromOffset(230, 15)

local statusDot = make("Frame", {
    Position = UDim2.new(1, -150, 0, 28),
    Size = UDim2.fromOffset(7, 7),
    BackgroundColor3 = Theme.Success,
    BorderSizePixel = 0,
    ZIndex = 3,
}, header)
corner(statusDot, 10)
local statusText = label(header, "UI READY", 10, Theme.Muted, Enum.Font.GothamMedium)
statusText.Position = UDim2.new(1, -137, 0, 22)
statusText.Size = UDim2.fromOffset(72, 18)

local function headerButton(text, xOffset, hoverColor)
    local button = make("TextButton", {
        Position = UDim2.new(1, xOffset, 0, 19),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = Theme.Panel2,
        Text = text,
        TextColor3 = Theme.Muted,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, header)
    corner(button, 8)
    button.MouseEnter:Connect(function()
        tween(button, 0.14, { BackgroundColor3 = hoverColor or Theme.PanelHover, TextColor3 = Theme.Text })
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.16, { BackgroundColor3 = Theme.Panel2, TextColor3 = Theme.Muted })
    end)
    return button
end

local minimizeButton = headerButton("—", -82)
local closeButton = headerButton("×", -46, Theme.Danger)

-- Sidebar.
local sidebar = make("Frame", {
    Name = "Sidebar",
    Position = UDim2.fromOffset(14, 80),
    Size = UDim2.new(0, 176, 1, -94),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0,
    ZIndex = 2,
}, main)
corner(sidebar, 13)
stroke(sidebar, Theme.Stroke, 0.5, 1)
padding(sidebar, 9, 9, 12, 10)

local navCaption = label(sidebar, "WORKSPACE", 9, Theme.Muted, Enum.Font.GothamBold)
navCaption.Size = UDim2.new(1, 0, 0, 20)
navCaption.Position = UDim2.fromOffset(8, 0)

local navList = make("Frame", {
    Position = UDim2.fromOffset(0, 28),
    Size = UDim2.new(1, 0, 1, -80),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, sidebar)
local navLayout = make("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, navList)

local profile = make("Frame", {
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 0, 1, 0),
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = Theme.Panel2,
    BorderSizePixel = 0,
}, sidebar)
corner(profile, 10)
local avatar = make("Frame", {
    Position = UDim2.fromOffset(8, 8),
    Size = UDim2.fromOffset(31, 31),
    BackgroundColor3 = Theme.Accent2,
    BorderSizePixel = 0,
}, profile)
corner(avatar, 10)
local avatarLetter = label(avatar, string.sub(player.DisplayName or player.Name, 1, 1):upper(), 14, Theme.Background, Enum.Font.GothamBlack)
avatarLetter.Size = UDim2.fromScale(1, 1)
avatarLetter.TextXAlignment = Enum.TextXAlignment.Center
local profileName = label(profile, player.DisplayName or player.Name, 10, Theme.Text, Enum.Font.GothamBold)
profileName.Position = UDim2.fromOffset(47, 8)
profileName.Size = UDim2.new(1, -52, 0, 15)
local profileCaption = label(profile, "LOCAL SESSION", 8, Theme.Muted, Enum.Font.GothamMedium)
profileCaption.Position = UDim2.fromOffset(47, 23)
profileCaption.Size = UDim2.new(1, -52, 0, 13)

-- Content panel.
local content = make("Frame", {
    Name = "Content",
    Position = UDim2.new(0, 204, 0, 80),
    Size = UDim2.new(1, -218, 1, -94),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 2,
}, main)

local pageHeader = make("Frame", {
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, content)
local pageTitle = label(pageHeader, "Overview", 22, Theme.Text, Enum.Font.GothamBold)
pageTitle.Position = UDim2.fromOffset(2, 0)
pageTitle.Size = UDim2.new(1, -4, 0, 30)
local pageDescription = label(pageHeader, "A clean workspace for your interface.", 11, Theme.Muted, Enum.Font.Gotham)
pageDescription.Position = UDim2.fromOffset(3, 31)
pageDescription.Size = UDim2.new(1, -4, 0, 19)

local pageContainer = make("Frame", {
    Position = UDim2.new(0, 0, 0, 64),
    Size = UDim2.new(1, 0, 1, -64),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, content)

local pages = {}
local navButtons = {}
local currentPage = nil
local minimized = false
local expandedSize = UDim2.fromOffset(760, 500)
local pageData = {
    Overview = {
        description = "A clean workspace for your interface.",
        icon = "⌂",
    },
    Visuals = {
        description = "Visual controls demo — no game features connected.",
        icon = "◈",
    },
    Settings = {
        description = "Interface preferences and motion settings.",
        icon = "⚙",
    },
    About = {
        description = "A lightweight UI foundation for Noir.",
        icon = "✦",
    },
}

local function makePage(name)
    local page = make("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, pageContainer)
    padding(page, 1, 7, 2, 12)
    local layout = make("UIListLayout", {
        Padding = UDim.new(0, 11),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    pages[name] = page
    return page
end

local function section(parent, titleText, descriptionText)
    local wrap = make("Frame", {
        Size = UDim2.new(1, -1, 0, 54),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, parent)
    corner(wrap, 11)
    stroke(wrap, Theme.Stroke, 0.6, 1)
    local title = label(wrap, titleText, 12, Theme.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(13, 8)
    title.Size = UDim2.new(1, -26, 0, 18)
    local desc = label(wrap, descriptionText or "", 10, Theme.Muted, Enum.Font.Gotham)
    desc.Position = UDim2.fromOffset(13, 27)
    desc.Size = UDim2.new(1, -26, 0, 16)
    return wrap
end

local function card(parent, height)
    local item = make("Frame", {
        Size = UDim2.new(1, -1, 0, height or 70),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, parent)
    corner(item, 11)
    stroke(item, Theme.Stroke, 0.62, 1)
    return item
end

local function addToggle(parent, titleText, descriptionText, defaultValue)
    local row = card(parent, 66)
    local title = label(row, titleText, 12, Theme.Text, Enum.Font.GothamSemibold)
    title.Position = UDim2.fromOffset(13, 10)
    title.Size = UDim2.new(1, -85, 0, 19)
    local desc = label(row, descriptionText or "Demo control only", 10, Theme.Muted, Enum.Font.Gotham)
    desc.Position = UDim2.fromOffset(13, 32)
    desc.Size = UDim2.new(1, -85, 0, 17)

    local track = make("TextButton", {
        Position = UDim2.new(1, -58, 0.5, -12),
        Size = UDim2.fromOffset(44, 24),
        BackgroundColor3 = defaultValue and Theme.Accent or Theme.Panel2,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, row)
    corner(track, 12)
    local knob = make("Frame", {
        Position = defaultValue and UDim2.new(1, -21, 0, 3) or UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = Color3.fromRGB(248, 248, 255),
        BorderSizePixel = 0,
    }, track)
    corner(knob, 10)
    local enabled = defaultValue == true
    track.Activated:Connect(function()
        enabled = not enabled
        tween(track, 0.2, { BackgroundColor3 = enabled and Theme.Accent or Theme.Panel2 })
        tween(knob, 0.22, { Position = enabled and UDim2.new(1, -21, 0, 3) or UDim2.fromOffset(3, 3) }, Enum.EasingStyle.Back)
    end)
    return row
end

local function addAction(parent, titleText, descriptionText, buttonText, callback)
    local row = card(parent, 70)
    local title = label(row, titleText, 12, Theme.Text, Enum.Font.GothamSemibold)
    title.Position = UDim2.fromOffset(13, 10)
    title.Size = UDim2.new(1, -135, 0, 19)
    local desc = label(row, descriptionText or "", 10, Theme.Muted, Enum.Font.Gotham)
    desc.Position = UDim2.fromOffset(13, 33)
    desc.Size = UDim2.new(1, -135, 0, 16)

    local button = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(96, 32),
        BackgroundColor3 = Theme.Panel2,
        Text = buttonText or "Open",
        TextColor3 = Theme.Text,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, row)
    corner(button, 9)
    stroke(button, Theme.Stroke, 0.4, 1)
    button.MouseEnter:Connect(function()
        tween(button, 0.15, { BackgroundColor3 = Theme.Accent, Size = UDim2.fromOffset(100, 34) })
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.16, { BackgroundColor3 = Theme.Panel2, Size = UDim2.fromOffset(96, 32) })
    end)
    button.Activated:Connect(function()
        tween(button, 0.07, { Size = UDim2.fromOffset(91, 29) })
        task.delay(0.08, function()
            if button.Parent then tween(button, 0.15, { Size = UDim2.fromOffset(100, 34) }) end
        end)
        if callback then callback() end
    end)
    return row
end

local notificationLayer = make("Frame", {
    Name = "Notifications",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -18, 0, 18),
    Size = UDim2.fromOffset(300, 360),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 30,
}, screen)
local notificationLayout = make("UIListLayout", {
    Padding = UDim.new(0, 9),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Top,
}, notificationLayer)

local notificationCount = 0
local function notify(titleText, messageText, kind)
    notificationCount += 1
    local accent = kind == "success" and Theme.Success or (kind == "error" and Theme.Danger or Theme.Accent)
    local toast = make("Frame", {
        LayoutOrder = -notificationCount,
        Size = UDim2.fromOffset(292, 76),
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ZIndex = 31,
    }, notificationLayer)
    corner(toast, 12)
    stroke(toast, Theme.Stroke, 0.25, 1)
    local bar = make("Frame", {
        Position = UDim2.fromOffset(0, 13),
        Size = UDim2.fromOffset(3, 50),
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        ZIndex = 32,
    }, toast)
    corner(bar, 3)
    local title = label(toast, titleText or "NOIR", 12, Theme.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(14, 12)
    title.Size = UDim2.new(1, -26, 0, 19)
    title.ZIndex = 32
    local message = label(toast, messageText or "Notification preview.", 10, Theme.Muted, Enum.Font.Gotham)
    message.Position = UDim2.fromOffset(14, 34)
    message.Size = UDim2.new(1, -26, 0, 27)
    message.TextWrapped = true
    message.ZIndex = 32

    toast.Position = UDim2.fromOffset(24, 0)
    toast.BackgroundTransparency = 1
    tween(toast, 0.28, { Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0.05 }, Enum.EasingStyle.Quint)
    task.delay(3.2, function()
        if toast.Parent then
            tween(toast, 0.24, { Position = UDim2.fromOffset(25, 0), BackgroundTransparency = 1 })
            task.wait(0.25)
            if toast.Parent then toast:Destroy() end
        end
    end)
end

local function addSlider(parent, titleText, minValue, maxValue, initialValue)
    local row = card(parent, 76)
    local title = label(row, titleText, 12, Theme.Text, Enum.Font.GothamSemibold)
    title.Position = UDim2.fromOffset(13, 8)
    title.Size = UDim2.new(1, -80, 0, 19)
    local valueLabel = label(row, tostring(initialValue), 11, Theme.Accent2, Enum.Font.GothamBold)
    valueLabel.Position = UDim2.new(1, -60, 0, 8)
    valueLabel.Size = UDim2.fromOffset(45, 19)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local track = make("TextButton", {
        Position = UDim2.fromOffset(13, 43),
        Size = UDim2.new(1, -26, 0, 8),
        BackgroundColor3 = Theme.Panel2,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, row)
    corner(track, 8)
    local fill = make("Frame", {
        Size = UDim2.new((initialValue - minValue) / (maxValue - minValue), 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, track)
    corner(fill, 8)
    local dot = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((initialValue - minValue) / (maxValue - minValue), 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Theme.Text,
        BorderSizePixel = 0,
    }, track)
    corner(dot, 10)
    local dragging = false
    local function setFromX(x)
        local width = math.max(track.AbsoluteSize.X, 1)
        local alpha = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
        local value = math.floor(minValue + (maxValue - minValue) * alpha + 0.5)
        valueLabel.Text = tostring(value)
        tween(fill, 0.07, { Size = UDim2.new(alpha, 0, 1, 0) }, Enum.EasingStyle.Linear)
        tween(dot, 0.07, { Position = UDim2.new(alpha, 0, 0.5, 0) }, Enum.EasingStyle.Linear)
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    return row
end

local function addNav(name, order)
    local data = pageData[name]
    local button = make("TextButton", {
        Name = name .. "Nav",
        LayoutOrder = order,
        Size = UDim2.new(1, 0, 0, 39),
        BackgroundColor3 = Theme.Panel,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, navList)
    corner(button, 9)
    local iconText = label(button, data.icon, 17, Theme.Muted, Enum.Font.GothamBold)
    iconText.Position = UDim2.fromOffset(10, 0)
    iconText.Size = UDim2.fromOffset(24, 39)
    iconText.TextXAlignment = Enum.TextXAlignment.Center
    local nameLabel = label(button, name, 11, Theme.Muted, Enum.Font.GothamSemibold)
    nameLabel.Position = UDim2.fromOffset(42, 0)
    nameLabel.Size = UDim2.new(1, -50, 1, 0)
    local activeBar = make("Frame", {
        Position = UDim2.new(0, 0, 0.5, -9),
        Size = UDim2.fromOffset(3, 18),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, button)
    corner(activeBar, 3)

    button.MouseEnter:Connect(function()
        if currentPage ~= name then tween(button, 0.14, { BackgroundColor3 = Theme.Panel2 }) end
    end)
    button.MouseLeave:Connect(function()
        if currentPage ~= name then tween(button, 0.14, { BackgroundColor3 = Theme.Panel }) end
    end)
    button.Activated:Connect(function()
        if currentPage == name then return end
        currentPage = name
        for pageName, page in pairs(pages) do
            local selected = pageName == name
            page.Visible = selected
            if selected then
                page.CanvasPosition = Vector2.new(0, 0)
                page.Position = UDim2.fromOffset(10, 0)
                tween(page, 0.22, { Position = UDim2.fromOffset(0, 0) })
            end
        end
        for navName, nav in pairs(navButtons) do
            local selected = navName == name
            tween(nav.button, 0.16, { BackgroundColor3 = selected and Theme.PanelHover or Theme.Panel })
            tween(nav.icon, 0.16, { TextColor3 = selected and Theme.Accent2 or Theme.Muted })
            tween(nav.label, 0.16, { TextColor3 = selected and Theme.Text or Theme.Muted })
            tween(nav.bar, 0.16, { BackgroundTransparency = selected and 0 or 1 })
        end
        pageTitle.Text = name
        pageDescription.Text = data.description
    end)
    navButtons[name] = { button = button, icon = iconText, label = nameLabel, bar = activeBar }
end

-- Build pages.
local overview = makePage("Overview")
section(overview, "Welcome to Noir", "A new interface foundation — no gameplay functions are connected.")
local statusCard = card(overview, 94)
local statusTitle = label(statusCard, "Interface status", 13, Theme.Text, Enum.Font.GothamBold)
statusTitle.Position = UDim2.fromOffset(14, 12)
statusTitle.Size = UDim2.new(1, -28, 0, 20)
local statusDesc = label(statusCard, "Animations, navigation and notifications are ready.", 10, Theme.Muted, Enum.Font.Gotham)
statusDesc.Position = UDim2.fromOffset(14, 36)
statusDesc.Size = UDim2.new(1, -28, 0, 18)
local pill = make("Frame", {
    Position = UDim2.fromOffset(14, 62),
    Size = UDim2.fromOffset(86, 20),
    BackgroundColor3 = Color3.fromRGB(25, 54, 47),
    BorderSizePixel = 0,
}, statusCard)
corner(pill, 7)
local pillText = label(pill, "●  UI ONLY", 9, Theme.Success, Enum.Font.GothamBold)
pillText.Position = UDim2.fromOffset(7, 0)
pillText.Size = UDim2.new(1, -10, 1, 0)
addAction(overview, "Notification preview", "Preview the animated toast notification.", "Preview", function()
    notify("Noir UI", "This is a sample notification. No game action was performed.", "success")
end)
addAction(overview, "Button animation", "Try the hover and press transitions.", "Test button", function()
    notify("Animation test", "Button press animation is working.", "info")
end)

local visuals = makePage("Visuals")
section(visuals, "Visual controls", "These are UI demos only; they are not connected to game logic.")
addToggle(visuals, "Example toggle", "Toggle state is visual only.", false)
addToggle(visuals, "Smooth transitions", "Demo setting for the interface.", true)
addToggle(visuals, "Compact notifications", "Placeholder preference only.", false)
addSlider(visuals, "Animation intensity", 0, 100, 65)
addSlider(visuals, "UI scale preview", 80, 120, 100)

local settings = makePage("Settings")
section(settings, "Interface settings", "UI preferences can be wired up later.")
addToggle(settings, "Blur backdrop", "Placeholder toggle — no blur effect connected.", false)
addToggle(settings, "Reduced motion", "Placeholder toggle — animations still run in this UI demo.", false)
addToggle(settings, "Show status indicator", "Placeholder preference.", true)
addAction(settings, "Reset interface preview", "Reopen the UI in its default size.", "Reset", function()
    main.Size = UDim2.fromOffset(760, 500)
    main.Position = UDim2.fromScale(0.5, 0.53)
    main.Visible = true
    minimized = false
    notify("Noir UI", "Window layout reset.", "success")
end)

local about = makePage("About")
section(about, "Built for Noir", "Minimal dark UI with motion designed to feel smooth, not noisy.")
local aboutCard = card(about, 112)
local aboutTitle = label(aboutCard, "NOIR UI FOUNDATION", 13, Theme.Text, Enum.Font.GothamBlack)
aboutTitle.Position = UDim2.fromOffset(14, 14)
aboutTitle.Size = UDim2.new(1, -28, 0, 20)
local aboutText = label(aboutCard, "• Animated tab transitions\n• Hover and press feedback\n• Toast notification system\n• Draggable window\n• Responsive scaling\n• Toggle and slider components", 10, Theme.Muted, Enum.Font.Gotham)
aboutText.Position = UDim2.fromOffset(14, 40)
aboutText.Size = UDim2.new(1, -28, 0, 65)
aboutText.TextYAlignment = Enum.TextYAlignment.Top

for index, name in ipairs({ "Overview", "Visuals", "Settings", "About" }) do
    addNav(name, index)
end

-- Select initial tab.
navButtons.Overview.button:Activate()

-- Drag window from header, while not grabbing a header button.
local dragging = false
local dragStart
local startPosition
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local mouseX = input.Position.X
        if mouseX > closeButton.AbsolutePosition.X - 4 then return end
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
        glow.Position = main.Position
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

minimizeButton.Activated:Connect(function()
    minimized = not minimized
    if minimized then
        expandedSize = main.Size
        tween(main, 0.25, { Size = UDim2.fromOffset(400, 66) }, Enum.EasingStyle.Quint)
        sidebar.Visible = false
        content.Visible = false
        glow.Visible = false
    else
        sidebar.Visible = true
        content.Visible = true
        glow.Visible = true
        tween(main, 0.28, { Size = expandedSize }, Enum.EasingStyle.Back)
    end
end)

closeButton.Activated:Connect(function()
    tween(mainScale, 0.18, { Scale = 0.92 })
    tween(main, 0.18, { BackgroundTransparency = 1 })
    task.wait(0.19)
    if screen.Parent then screen:Destroy() end
end)

-- Small intro toast after the open animation.
task.delay(0.55, function()
    if screen.Parent then
        notify("Welcome to Noir", "UI loaded. All controls are placeholders for now.", "success")
    end
end)
