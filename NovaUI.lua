--[[
    Noir UI — интерфейс хаба Noir отдельным файлом, без игровых функций.
    Окно, боковое меню, вкладки, карточки, переключатели, ползунки, списки, поля, клавиши, выбор цвета,
    уведомления, пружинные анимации, чёрно-белая тема с вращающимся кольцом «чёрная дыра».

    Свои элементы добавляются в блоке «демо-наполнение» в конце файла:
        local tab = host.CreateTab()
        local s = tab:AddSection("MAIN • Название", "Описание")
        s:AddToggle("Текст", function(v) print(v) end)
        s:AddSlider("Текст", 0, 100, 50, function(v) print(v) end)
        s:AddDropdown("Текст", { "A", "B" }, function(v) print(v) end)
        s:AddButton("Текст", function() host.Notify("Привет", 2) end)
]]
local function __noirW1a()
if type(NoirGenv) ~= "\x66unction" then
    NoirGenv = function()
        if type(getgenv) == "\x66unction" then
            local ok, t = pcall(getgenv)
            if ok and type(t) == "\x74able" then return t end
        end
        return _G
    end
end
if type(NoirTr) ~= "\x66unction" then
    NoirTr = function(s)
        if type(s) ~= "\x73tring" then return s end
        local st = NoirGenv().__NoirLangState
        local dict = st and st.dicts and st.dicts[st.lang]
        if type(dict) == "\x74able" then return dict[s] or s end
        if st and st.lang == "\x72u" then return (st.dict or {})[s] or s end
        return s
    end
end
if type(NoirGenv().__NoirLangState) ~= "\x74able" then
    NoirGenv().__NoirLangState = { lang = "\x65n", dict = {}, dicts = {}, renderedToSource = {}, originalTextDirections = setmetatable({}, { __mode = "k" }) }
end
local Players           = game:GetService("\x50layers")
local UIS               = game:GetService("\x55serInputService")
local TweenService      = game:GetService("\x54weenService")
local RunService        = game:GetService("\x52unService")
local Stats             = game:GetService("\x53tats")
local Workspace         = game:GetService("\x57orkspace")
local CoreGui           = game:GetService("\x43oreGui")
local ReplicatedStorage = game:GetService("\x52eplicatedStorage")
local HttpService       = game:GetService("\x48ttpService")
local Lighting          = game:GetService("\x4cighting")
local LocalPlayer       = Players.LocalPlayer
local NoirFX = (function()
    local fx, springs, spinners = { gui = nil }, {}, {}
    fx.RING = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)), ColorSequenceKeypoint.new(.25, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(.5, Color3.fromRGB(0, 0, 0)), ColorSequenceKeypoint.new(.75, Color3.fromRGB(110, 110, 110)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
    })
    function fx.new(initial, speed, damp, apply)
        local sp = { pos = initial, vel = 0, target = initial, speed = speed, damp = math.min(damp, 1), apply = apply }
        function sp:Set(v) self.target = v; springs[self] = true end
        function sp:Snap(v) self.pos, self.target, self.vel = v, v, 0; springs[self] = nil; apply(v) end
        apply(initial)
        return sp
    end
    function fx.spin(gradient) spinners[#spinners + 1] = gradient; return gradient end
    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        if fx.gui and not fx.gui.Parent then conn:Disconnect() return end
        dt = math.min(dt, 1 / 20)
        for _, g in ipairs(spinners) do g.Rotation = (g.Rotation + 60 * dt) % 360 end
        local list = {}
        for sp in pairs(springs) do list[#list + 1] = sp end
        for _, sp in ipairs(list) do
            local w, d = sp.speed, sp.damp
            local x0, v0 = sp.pos - sp.target, sp.vel
            local x, v
            if d >= 1 then
                local e = math.exp(-w * dt)
                x = (x0 + (v0 + w * x0) * dt) * e
                v = (v0 - (v0 + w * x0) * w * dt) * e
            else
                local c = math.sqrt(1 - d * d)
                local i, j = math.cos(c * w * dt), math.sin(c * w * dt)
                local e = math.exp(-d * w * dt)
                x = (x0 * (i + d / c * j) + v0 * j / (c * w)) * e
                v = (v0 * (i - d / c * j) - x0 * w / c * j) * e
            end
            sp.pos, sp.vel = x + sp.target, v
            if math.abs(x) < .001 and math.abs(v) < .001 then sp.pos, sp.vel = sp.target, 0; springs[sp] = nil end
            sp.apply(sp.pos)
        end
    end)
    return fx
end)()

 
local function __noirSharedEnvironment()
    local ok, environment = pcall(function()
        if type(getgenv) == "\x66unction" then return NoirGenv() end
    end)
    if ok and type(environment) == "\x74able" then return environment end
    return _G
end
local __NOIR_SHARED = __noirSharedEnvironment()
local __NOIR_GUARD_KEY = "__NoirUIRuntimeLock"
local __NOIR_OLD_GUARD = __NOIR_SHARED[__NOIR_GUARD_KEY]
local function __noirGuardGuiAlive(record)
    if type(record) ~= "\x74able" or not record.gui then return false end
    local ok, parent = pcall(function() return record.gui.Parent end)
    return ok and parent ~= nil
end
if type(__NOIR_OLD_GUARD) == "\x74able" then
    local oldState = __NOIR_OLD_GUARD.state
    local age = os.clock() - (tonumber(__NOIR_OLD_GUARD.startedAt) or os.clock())
    local heartbeatAge = os.clock() - (tonumber(__NOIR_OLD_GUARD.heartbeat) or tonumber(__NOIR_OLD_GUARD.startedAt) or os.clock())
    if (oldState == "\x72unning" and (__noirGuardGuiAlive(__NOIR_OLD_GUARD) or heartbeatAge < 120))
        or (oldState == "\x73tarting" and (__noirGuardGuiAlive(__NOIR_OLD_GUARD) or age < 120)) then
        pcall(function() warn("\x5bNoir] already starting/running; duplicate launch ignored") end)
        return
    end
    __NOIR_SHARED[__NOIR_GUARD_KEY] = nil
end
local __NOIR_GUARD = { state = "\x73tarting", startedAt = os.clock() }
__NOIR_SHARED[__NOIR_GUARD_KEY] = __NOIR_GUARD
task.delay(120, function()
    if __NOIR_SHARED[__NOIR_GUARD_KEY] == __NOIR_GUARD
        and __NOIR_GUARD.state == "\x73tarting"
        and not __noirGuardGuiAlive(__NOIR_GUARD) then
        __NOIR_SHARED[__NOIR_GUARD_KEY] = nil
    end
end)

local IS_TOUCH = UIS.TouchEnabled == true
local IS_KEYBOARD = UIS.KeyboardEnabled == true
local IS_MOUSE = UIS.MouseEnabled == true
local INPUT_DEVICE = (IS_TOUCH and not IS_MOUSE and not IS_KEYBOARD) and "\x54ouch"
    or (IS_TOUCH and "\x48ybrid")
    or "\x44esktop"

local function isPrimaryPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local STORAGE_ROOT = "Noir UI"
local ASSETS_FOLDER = STORAGE_ROOT .. "\x2fassets"
local CONFIGS_FOLDER = STORAGE_ROOT .. "\x2fconfigs"
local PRESETS_FOLDER = STORAGE_ROOT .. "\x2fpresets"
local LEGACY_STORAGE_ROOT = "\x4eOIR.CONFIG"

local function ensureFolder(path)
    if type(makefolder) ~= "\x66unction" then return end
    if type(isfolder) == "\x66unction" then
        local ok, exists = pcall(isfolder, path)
        if ok and exists then return end
    end
    pcall(makefolder, path)
end

local function ensureStorageFolders()
    ensureFolder(STORAGE_ROOT)
    ensureFolder(ASSETS_FOLDER)
    ensureFolder(CONFIGS_FOLDER)
    ensureFolder(PRESETS_FOLDER)
end

local function fileExists(path)
    if type(isfile) ~= "\x66unction" then return false end
    local ok, exists = pcall(isfile, path)
    return ok and exists == true
end

local function copyLegacyFile(source, destination)
    if type(readfile) ~= "\x66unction" or type(writefile) ~= "\x66unction" then return end
    if not fileExists(source) or fileExists(destination) then return end
    local ok, contents = pcall(readfile, source)
    if ok then pcall(writefile, destination, contents) end
end

local function migrateLegacyStorage()
    copyLegacyFile(LEGACY_STORAGE_ROOT .. "\x2fautosave.json", CONFIGS_FOLDER .. "\x2fautosave.json")
    for _, name in ipairs({
        "\x4fDH_FEAnimations_settings.json",
        "\x4fDH_BJP_settings.json",
        "\x4fDH_InventoryUnlimiter_settings.json",
        "\x4fDH_Pm-Wallhop_settings.json",
    }) do
        copyLegacyFile(name, CONFIGS_FOLDER .. "\x2f" .. name)
    end
    if type(listfiles) ~= "\x66unction" or type(readfile) ~= "\x66unction" or type(writefile) ~= "\x66unction" then return end
    local ok, files = pcall(listfiles, LEGACY_STORAGE_ROOT)
    if not ok or type(files) ~= "\x74able" then return end
    for _, source in ipairs(files) do
        local normalized = tostring(source):gsub("\\", "\x2f")
        local name = normalized:match("\x28[^/]+%.preset)$")
        if name then copyLegacyFile(source, PRESETS_FOLDER .. "\x2f" .. name) end
    end
end

ensureStorageFolders()
migrateLegacyStorage()

local guiParent = CoreGui
if type(gethui) == "\x66unction" then local ok,v=pcall(gethui); if ok and typeof(v)=="\x49nstance" then guiParent=v end end
-- Необязательный переключатель родителя UI: NoirGenv().__NoirUIParent = "playergui"
-- ставит интерфейс в PlayerGui вместо CoreGui (убирает вмешательство в core-UI клиента).
do
    local pref
    pcall(function()
        local env = (type(NoirGenv) == "\x66unction") and NoirGenv() or nil
        if type(env) == "\x74able" then pref = env.__NoirUIParent end
    end)
    if pref == "playergui" or pref == "player" or pref == "plrgui" then
        local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("\x50layerGui")
        if playerGui then guiParent = playerGui end
    end
end
local existingMainGui = guiParent:FindFirstChild("\x4eoirSilentAimUI")
if not existingMainGui and guiParent ~= CoreGui then
    pcall(function() existingMainGui = CoreGui:FindFirstChild("\x4eoirSilentAimUI") end)
end
if existingMainGui then
    -- Раньше здесь был return: новая версия молча не запускалась, а на экране
    -- оставался старый интерфейс. Теперь чистим прежние окна и строим заново.
    if __NOIR_SHARED[__NOIR_GUARD_KEY] == __NOIR_GUARD then __NOIR_SHARED[__NOIR_GUARD_KEY] = nil end
    local staleNames = {
        "\x4eoirSilentAimUI",
        

    }
    for _, root in ipairs({ guiParent, CoreGui, LocalPlayer:FindFirstChildOfClass("\x50layerGui") }) do
        if root then
            for _, name in ipairs(staleNames) do
                local old = root:FindFirstChild(name)
                if old then pcall(function() old:Destroy() end) end
            end
        end
    end
    pcall(function() warn("\x5bNoir] previous UI replaced with the current build") end)
end

local NoirPersistence = {
    data = { toggles = {}, sliders = {}, dropdowns = {}, textboxes = {}, keybinds = {}, positions = {}, colors = {} },
    token = 0,
    path = CONFIGS_FOLDER .. "\x2fautosave.json",
    safeLegacy = {},
}
do
    if type(readfile) == "\x66unction" then
        pcall(function()
            local loaded = HttpService:JSONDecode(readfile(NoirPersistence.path))
            if typeof(loaded) == "\x74able" then NoirPersistence.data = loaded end
        end)
    end
    for _, key in ipairs({"\x74oggles","\x73liders","\x64ropdowns","\x74extboxes","\x6beybinds","\x70ositions","\x63olors"}) do
        if typeof(NoirPersistence.data[key]) ~= "\x74able" then NoirPersistence.data[key] = {} end
    end
end
do
    local st = NoirGenv().__NoirLangState
    st.lang = "en"
    st.dict = {}
    st.dicts = { en = {}, ru = {}, ar = {} }
    st.renderedToSource = {}
    st.originalTextDirections = setmetatable({}, { __mode = "k" })
    st.originalTextXAlignments = setmetatable({}, { __mode = "k" })
    NoirTr = function(value) return value end
end
function NoirPersistence.WriteNow()
    if type(writefile) ~= "\x66unction" then return end
    pcall(function()
        ensureStorageFolders()
        writefile(NoirPersistence.path, HttpService:JSONEncode(NoirPersistence.data))
    end)
end
function NoirPersistence.Save(immediate)
    if type(writefile) ~= "\x66unction" then return end
    NoirPersistence.dirty = true
    if immediate then
        NoirPersistence.WriteNow()
        NoirPersistence.dirty = false
        return
    end
    NoirPersistence.token += 1
    local token = NoirPersistence.token
    task.delay(.35, function()
        if token ~= NoirPersistence.token then return end
        NoirPersistence.WriteNow()
        NoirPersistence.dirty = false
    end)
end
function NoirPersistence.GetValue(bucket, key, fallback)
    local store = NoirPersistence.data[bucket]
    if type(store) ~= "\x74able" then return fallback end
    local value = store[key]
    if value == nil then return fallback end
    return value
end
function NoirPersistence.SetValue(bucket, key, value, immediate)
    if type(NoirPersistence.data[bucket]) ~= "\x74able" then NoirPersistence.data[bucket] = {} end
    NoirPersistence.data[bucket][key] = value
    NoirPersistence.Save(immediate)
end
function NoirPersistence.GetPosition(key, fallback)
    local p = NoirPersistence.data.positions[key]
    if typeof(p) == "\x74able" and #p == 4 then return UDim2.new(p[1], p[2], p[3], p[4]) end
    return fallback
end
function NoirPersistence.SetPosition(key, p)
    NoirPersistence.data.positions[key] = { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset }
    NoirPersistence.Save()
end

local C = {
    base = Color3.fromRGB(6,6,6), surface = Color3.fromRGB(13,13,13), panel = Color3.fromRGB(8,8,8),
    card = Color3.fromRGB(13,13,13), border = Color3.fromRGB(46,46,46), accent = Color3.fromRGB(236,236,236),
    accent2 = Color3.fromRGB(255,255,255), text = Color3.fromRGB(242,242,242), dim = Color3.fromRGB(158,158,158),
    off = Color3.fromRGB(30,30,30), btn = Color3.fromRGB(19,19,19),
}
local gui
function New(class, props)
    local x = Instance.new(class)
    for k, v in pairs(props or {}) do if k ~= "\x50arent" then x[k] = v end end
    local langState = NoirGenv().__NoirLangState
    if type(langState) == "\x74able" then
        langState.renderedToSource = langState.renderedToSource or {}
        local function rememberText(property, sourceAttribute, renderedAttribute)
            local ok, value = pcall(function() return x[property] end)
            if not ok or type(value) ~= "\x73tring" then return end
            local source = langState.renderedToSource[value] or value
            pcall(function()
                x:SetAttribute(sourceAttribute, source)
                x:SetAttribute(renderedAttribute, value)
            end)
        end
        local isTextLabel = false
        local isTextButton = false
        local isTextBox = false
        pcall(function()
            isTextLabel = x:IsA("TextLabel")
            isTextButton = x:IsA("TextButton")
            isTextBox = x:IsA("TextBox")
        end)
        if isTextBox then
            local ok, value = pcall(function() return x.PlaceholderText end)
            if ok and type(value) == "\x73tring" then
                local source = langState.renderedToSource[value] or value
                pcall(function() x.PlaceholderText = NoirTr(source) end)
            end
            rememberText("PlaceholderText", "__NoirPlaceholderSource", "__NoirPlaceholderRendered")
        elseif isTextLabel or isTextButton then
            local ok, value = pcall(function() return x.Text end)
            if ok and type(value) == "\x73tring" then
                local source = langState.renderedToSource[value] or value
                pcall(function() x.Text = NoirTr(source) end)
            end
            rememberText("Text", "__NoirTextSource", "__NoirTextRendered")
        end
        if isTextLabel or isTextButton or isTextBox then
            langState.originalTextDirections = langState.originalTextDirections or setmetatable({}, { __mode = "k" })
            langState.originalTextXAlignments = langState.originalTextXAlignments or setmetatable({}, { __mode = "k" })
            local alignmentOk, originalAlignment = pcall(function() return x.TextXAlignment end)
            if alignmentOk and langState.originalTextXAlignments[x] == nil then
                langState.originalTextXAlignments[x] = originalAlignment
            end
            if alignmentOk and langState.lang == "ar" and originalAlignment == Enum.TextXAlignment.Left then
                pcall(function() x.TextXAlignment = Enum.TextXAlignment.Right end)
            end
            local directionOk, originalDirection = pcall(function() return x.TextDirection end)
            if directionOk and langState.originalTextDirections[x] == nil then
                langState.originalTextDirections[x] = originalDirection
            end
            if langState.lang == "ar" then
                local txt2 = ""
                pcall(function() txt2 = x.Text or "" end)
                local hasArabic2 = txt2:match("[\216-\219][\128-\191]") ~= nil
                local hasLatin2 = txt2:match("[A-Za-z]") ~= nil
                if hasLatin2 and not hasArabic2 then
                    pcall(function() x.TextDirection = Enum.TextDirection.LeftToRight end)
                else
                    pcall(function() x.TextDirection = Enum.TextDirection.RightToLeft end)
                end
            end
        end
    end
    x.Parent = props and props.Parent
    return x
end
local function refreshNoirLanguage()
    local state = NoirGenv().__NoirLangState
    if type(state) ~= "table" then return false end
    state.renderedToSource = state.renderedToSource or {}
    state.originalTextDirections = state.originalTextDirections or setmetatable({}, { __mode = "k" })
    state.originalTextXAlignments = state.originalTextXAlignments or setmetatable({}, { __mode = "k" })
    local roots, seenRoots = {}, {}
    local function addRoot(root)
        if typeof(root) == "Instance" and not seenRoots[root] then
            seenRoots[root] = true
            roots[#roots + 1] = root
        end
    end
    addRoot(gui)
    if type(gethui) == "function" then local ok, root = pcall(gethui); if ok then addRoot(root) end end
    if type(getcore) == "function" then local ok, root = pcall(getcore); if ok then addRoot(root) end end
    addRoot(CoreGui)
    local playerGuiOk, playerGui = pcall(function() return LocalPlayer:FindFirstChildOfClass("PlayerGui") end)
    if playerGuiOk then addRoot(playerGui) end

    local namedScreens = {
        ["@fling"] = true, ["@odh_bjp_bigstorage"] = true, ["@odh_bjp_bindstorage"] = true,
        ["@wallhopstorage"] = true, ["@bindstorage_v6"] = true, ["@bindstorage_v5"] = true,
        ["@flingstorage_v1"] = true
    }
    local function belongsToNoirScreen(instance)
        local cursor = instance
        while cursor do
            local ok, isScreenGui, name = pcall(function() return cursor:IsA("ScreenGui"), cursor.Name end)
            if ok and isScreenGui then
                return name == "NoirSilentAimUI" or name:sub(1, 4) == "Noir" or namedScreens[name] == true
            end
            local parentOk, parent = pcall(function() return cursor.Parent end)
            if not parentOk then break end
            cursor = parent
        end
        return false
    end
    local function hasNoirLanguageMarker(instance)
        local ok, source, placeholder = pcall(function()
            return instance:GetAttribute("__NoirTextSource"), instance:GetAttribute("__NoirPlaceholderSource")
        end)
        return ok and (type(source) == "\x73tring" or type(placeholder) == "\x73tring")
    end
    local function refreshProperty(instance, property, sourceAttribute, renderedAttribute)
        local readOk, current = pcall(function() return instance[property] end)
        if not readOk or type(current) ~= "string" or current == "" then return end
        local source, lastRendered
        pcall(function()
            source = instance:GetAttribute(sourceAttribute)
            lastRendered = instance:GetAttribute(renderedAttribute)
        end)
        if type(source) ~= "string" or current ~= lastRendered then
            source = state.renderedToSource[current] or current
        end
        local translated = NoirTr(source)
        pcall(function() instance[property] = translated end)
        pcall(function()
            instance:SetAttribute(sourceAttribute, source)
            instance:SetAttribute(renderedAttribute, translated)
        end)
    end
    local function applyDirection(instance)
        local alignmentOk, currentAlignment = pcall(function() return instance.TextXAlignment end)
        if alignmentOk then
            if state.originalTextXAlignments[instance] == nil then state.originalTextXAlignments[instance] = currentAlignment end
            local originalAlignment = state.originalTextXAlignments[instance]
            if state.lang == "ar" and originalAlignment == Enum.TextXAlignment.Left then
                pcall(function() instance.TextXAlignment = Enum.TextXAlignment.Right end)
            elseif originalAlignment ~= nil then
                pcall(function() instance.TextXAlignment = originalAlignment end)
            end
        end
        local ok, current = pcall(function() return instance.TextDirection end)
        if not ok then return end
        if state.originalTextDirections[instance] == nil then state.originalTextDirections[instance] = current end
        if state.lang == "ar" then
            local txt = ""
            pcall(function() txt = instance.Text or "" end)
            local hasArabic = txt:match("[\216-\219][\128-\191]") ~= nil
            local hasLatin = txt:match("[A-Za-z]") ~= nil
            if hasLatin and not hasArabic then
                pcall(function() instance.TextDirection = Enum.TextDirection.LeftToRight end)
            else
                pcall(function() instance.TextDirection = Enum.TextDirection.RightToLeft end)
            end
        else
            local original = state.originalTextDirections[instance]
            if original ~= nil then pcall(function() instance.TextDirection = original end) end
        end
    end

    local seenInstances = {}
    for _, root in ipairs(roots) do
        local objects = { root }
        local ok, descendants = pcall(function() return root:GetDescendants() end)
        if ok then for _, child in ipairs(descendants) do objects[#objects + 1] = child end end
        for _, instance in ipairs(objects) do
            if not seenInstances[instance] and (belongsToNoirScreen(instance) or hasNoirLanguageMarker(instance)) then
                seenInstances[instance] = true
                local ok, isTextLabel, isTextButton, isTextBox = pcall(function()
                    return instance:IsA("TextLabel"), instance:IsA("TextButton"), instance:IsA("TextBox")
                end)
                if ok then
                    if isTextBox then
                        refreshProperty(instance, "PlaceholderText", "__NoirPlaceholderSource", "__NoirPlaceholderRendered")
                    elseif isTextLabel or isTextButton then
                        refreshProperty(instance, "Text", "__NoirTextSource", "__NoirTextRendered")
                    end
                    if isTextLabel or isTextButton or isTextBox then applyDirection(instance) end
                end
            end
        end
    end
    return true
end
NoirGenv().__NoirRefreshLanguage = refreshNoirLanguage

function corner(x, r) New("\x55ICorner", { CornerRadius = UDim.new(0, r or 12), Parent = x }) end
local gradientStrokes = { fast = {} }
function ringStroke(x, thickness, transparency)
    local ring = New("\x55IStroke", {
        Parent = x,
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = thickness or 1.6,
        Transparency = transparency or .18,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    New("\x55IGradient", { Parent = ring, Rotation = 25, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(116, 116, 116)),
        ColorSequenceKeypoint.new(0.22, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(150, 150, 150)),
        ColorSequenceKeypoint.new(0.72, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(110, 110, 110)),
    }) })
    return ring
end

function stroke(x, col, tr, thickness)
    -- ВАЖНО: не передаём ApplyStrokeMode в таблицу свойств.
    -- Новые билды Roblox кидают "Position is not a valid member of UIStroke",
    -- когда UIStroke создаётся с таблицей свойств и BorderMode.
    local s = New("\x55IStroke", { Color = col or C.border, Transparency = tr or .55, Thickness = thickness or 1, Parent = x })
    pcall(function() s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border end)
    return s
end
local gradientAccum = 0
RunService.RenderStepped:Connect(function(dt)
    local fast = gradientStrokes.fast
    if #fast == 0 then return end
    gradientAccum += dt
    if gradientAccum < 0.12 then return end
    local step = gradientAccum * 30
    gradientAccum = 0
    for i = #fast, 1, -1 do
        local g = fast[i]
        if g.Parent then
            g.Rotation = (g.Rotation + step) % 360
        else
            table.remove(fast, i)
        end
    end
end)
function kitiTitle(parent, value)
    local l = text(parent, value, 14, UDim2.fromOffset(8, 6))
    l.Font = Enum.Font.GothamBold
    l.Size = UDim2.new(1, -16, 0, 15)
    l.TextTransparency = 0
    return l
end
function kitiDesc(parent, value)
    local l = text(parent, value, 11, UDim2.fromOffset(8, 27), true)
    l.Size = UDim2.new(1, -16, 0, 14)
    return l
end
function text(parent, value, size, pos, dim)
    return New("\x54extLabel", { Parent = parent, BackgroundTransparency = 1, Text = NoirTr(value), TextColor3 = dim and C.dim or C.text,
        TextSize = size, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
        TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = .82,
        Position = pos or UDim2.new(), Size = UDim2.new(1, 0, 0, size + 8) })
end

gui = New("\x53creenGui", { Name = "\x4eoirSilentAimUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = guiParent })
__NOIR_GUARD.gui = gui
NoirFX.gui = gui

-- Stream Mode keeps every panel visible and only hides button visuals.
-- Buttons remain visible/active/clickable; their original styling is restored on exit.
local streamModeButton = nil
local function createStreamModeController()
local STREAM_MODE_GLOBAL = "__NoirStreamModeController"
local streamEnvironment = NoirGenv()
local previousStreamMode = rawget(streamEnvironment, STREAM_MODE_GLOBAL)
if type(previousStreamMode) == "table" and type(previousStreamMode.Destroy) == "function" then
    pcall(previousStreamMode.Destroy, previousStreamMode)
end

local StreamMode = {
    active = false,
    saved = setmetatable({}, { __mode = "k" }),
    watched = setmetatable({}, { __mode = "k" }),
    roots = setmetatable({}, { __mode = "k" }),
    markedRoots = setmetatable({}, { __mode = "k" }),
    rootConnections = {},
    propertyConnections = {},
    inputConnections = {},
    playerGuiConnection = nil,
}
local STREAM_MODE_MAIN_GUI = "NoirSilentAimUI"
local STREAM_MODE_NAMED_SCREENS = {
    ["@fling"] = true,
    ["@odh_bjp_bigstorage"] = true,
    ["@odh_bjp_bindstorage"] = true,
    ["@wallhopstorage"] = true,
    ["@bindstorage_v6"] = true,
    ["@bindstorage_v5"] = true,
    ["@flingstorage_v1"] = true,

}
local STREAM_MODE_MARKER_PREFIX = "@fling_"

local function streamSetVisual(self, instance, property, hiddenValue)
    local properties = self.saved[instance]
    if not properties then
        properties = {}
        self.saved[instance] = properties
    end
    local state = properties[property]
    if not state then
        local ok, original = pcall(function() return instance[property] end)
        if not ok then return false end
        state = { original = original, hidden = hiddenValue }
        properties[property] = state
    else
        state.hidden = hiddenValue
    end
    local watched = self.watched[instance]
    if not watched then
        watched = {}
        self.watched[instance] = watched
    end
    if not watched[property] then
        watched[property] = true
        local ok, connection = pcall(function()
            return instance:GetPropertyChangedSignal(property):Connect(function()
                if not self.active then return end
                local savedProperties = self.saved[instance]
                local currentState = savedProperties and savedProperties[property]
                if not currentState then return end
                local readOk, current = pcall(function() return instance[property] end)
                if readOk and current ~= currentState.hidden then
                    -- Keep the original snapshot stable: hover/press animations
                    -- must not become the appearance restored when Stream Mode ends.
                    pcall(function() instance[property] = currentState.hidden end)
                end
            end)
        end)
        if ok and connection then table.insert(self.propertyConnections, connection) end
    end
    pcall(function() instance[property] = hiddenValue end)
    return true
end
local function streamHideVisual(self, instance)
    local ok, className, isGuiObject = pcall(function()
        return instance.ClassName, instance:IsA("GuiObject")
    end)
    if not ok then return false end
    local changed = false
    if isGuiObject then
        changed = streamSetVisual(self, instance, "BackgroundTransparency", 1) or changed
    end
    if className == "TextButton" or className == "TextLabel" or className == "TextBox" then
        changed = streamSetVisual(self, instance, "TextTransparency", 1) or changed
        changed = streamSetVisual(self, instance, "TextStrokeTransparency", 1) or changed
    end
    if className == "ImageButton" or className == "ImageLabel" or className == "ViewportFrame" then
        changed = streamSetVisual(self, instance, "ImageTransparency", 1) or changed
    end
    if className == "ScrollingFrame" then
        changed = streamSetVisual(self, instance, "ScrollBarImageTransparency", 1) or changed
    end
    if className == "UIStroke" then
        changed = streamSetVisual(self, instance, "Transparency", 1) or changed
    end
    return changed
end

local function streamIsButtonDecoration(instance)
    local ok, className = pcall(function() return instance.ClassName end)
    return ok and (className == "TextLabel" or className == "ImageLabel" or className == "ViewportFrame" or className == "UIStroke")
end

local function streamHideButtonVisuals(self, button)
    local changed = streamHideVisual(self, button)
    -- Only touch direct label/icon/stroke children. Do not recurse into Frames or
    -- nested content: some GUI panels use a GuiButton as a container.
    local ok, children = pcall(function() return button:GetChildren() end)
    if ok then
        for _, child in ipairs(children) do
            if streamIsButtonDecoration(child) then
                changed = streamHideVisual(self, child) or changed
            end
        end
    end
    return changed
end

local function streamFindMarkedRoot(self, instance)
    local cursor = instance
    while cursor do
        if self.markedRoots[cursor] then return cursor end
        local ok, parent = pcall(function() return cursor.Parent end)
        if not ok then break end
        cursor = parent
    end
    return nil
end

local function streamIsManagedGui(self, instance)
    if streamFindMarkedRoot(self, instance) then return true end
    local cursor = instance
    while cursor do
        local ok, isScreenGui, name = pcall(function()
            return cursor:IsA("ScreenGui"), cursor.Name
        end)
        if ok and isScreenGui then
            -- Keep the main Noir Hub panel and every control inside it untouched.
            if name == STREAM_MODE_MAIN_GUI then return false end
            return name:sub(1, 4) == "Noir" or STREAM_MODE_NAMED_SCREENS[name] == true
        end
        local parentOk, parent = pcall(function() return cursor.Parent end)
        if not parentOk then break end
        cursor = parent
    end
    return false
end
function StreamMode:IsActive()
    return self.active == true
end

function StreamMode:ApplyInstance(instance)
    if not self.active or typeof(instance) ~= "Instance" then return false end
    local ok, name, className, isButton = pcall(function()
        return instance.Name, instance.ClassName, instance:IsA("GuiButton")
    end)
    if not ok then return false end

    if className == "StringValue" and name:sub(1, #STREAM_MODE_MARKER_PREFIX) == STREAM_MODE_MARKER_PREFIX then
        local parentOk, parent = pcall(function() return instance.Parent end)
        if parentOk and parent then
            local guiOk, parentIsGuiObject = pcall(function() return parent:IsA("GuiObject") end)
            if guiOk and parentIsGuiObject then
                self.markedRoots[parent] = true
                return streamHideButtonVisuals(self, parent)
            end
        end
    end

    -- The minimize/restore handle lives in the main ScreenGui, but should
    -- remain visually hidden (and clickable) while the main panel stays intact.
    if className == "TextButton" and name == "NoirRestoreButton" then
        return streamHideButtonVisuals(self, instance)
    end
    if not streamIsManagedGui(self, instance) then return false end
    if isButton then
        return streamHideButtonVisuals(self, instance)
    end

    local parentOk, parent = pcall(function() return instance.Parent end)
    if parentOk and parent and streamIsButtonDecoration(instance) then
        local parentButtonOk, parentIsButton = pcall(function() return parent:IsA("GuiButton") end)
        if parentButtonOk and parentIsButton then
            return streamHideVisual(self, instance)
        end
    end

    local markedRoot = streamFindMarkedRoot(self, instance)
    if markedRoot and parentOk and parent == markedRoot and streamIsButtonDecoration(instance) then
        return streamHideVisual(self, instance)
    end
    -- ScreenGuis, panels, Frames, and nested non-button UI stay untouched.
    return false
end
function StreamMode:ApplyGui(instance)
    return self:ApplyInstance(instance)
end

function StreamMode:AttachRoot(root)
    if not self.active or typeof(root) ~= "Instance" or self.roots[root] then return end
    self.roots[root] = true
    local ok, connection = pcall(function()
        return root.DescendantAdded:Connect(function(descendant)
            local function applyNewControl()
                if self.active then self:ApplyInstance(descendant) end
            end
            local deferred = false
            if type(task) == "table" and type(task.defer) == "function" then
                deferred = pcall(function() task.defer(applyNewControl) end)
            end
            if not deferred then applyNewControl() end
        end)
    end)
    if ok and connection then table.insert(self.rootConnections, connection) end
    self:ApplyInstance(root)
    local descendantsOk, descendants = pcall(function() return root:GetDescendants() end)
    if descendantsOk then
        for _, descendant in ipairs(descendants) do self:ApplyInstance(descendant) end
    end
end

function StreamMode:AttachRoots()
    if not self.active then return end
    local roots, seen = {}, {}
    local function add(root)
        if typeof(root) == "Instance" and not seen[root] then
            seen[root] = true
            roots[#roots + 1] = root
        end
    end
    if type(gethui) == "function" then local ok, root = pcall(gethui); if ok then add(root) end end
    if type(getcore) == "function" then local ok, root = pcall(getcore); if ok then add(root) end end
    add(CoreGui)
    local playerGuiOk, playerGui = pcall(function() return LocalPlayer:FindFirstChildOfClass("PlayerGui") end)
    if playerGuiOk then add(playerGui) end
    for _, root in ipairs(roots) do self:AttachRoot(root) end
    if not self.playerGuiConnection then
        local ok, connection = pcall(function()
            return LocalPlayer.ChildAdded:Connect(function(child)
                local childOk, isPlayerGui = pcall(function() return child:IsA("PlayerGui") end)
                if self.active and childOk and isPlayerGui then self:AttachRoot(child) end
            end)
        end)
        if ok then self.playerGuiConnection = connection end
    end
end

function StreamMode:DisconnectRoots()
    for _, connection in ipairs(self.rootConnections) do pcall(function() connection:Disconnect() end) end
    table.clear(self.rootConnections)
    if self.playerGuiConnection then pcall(function() self.playerGuiConnection:Disconnect() end) end
    self.playerGuiConnection = nil
    table.clear(self.roots)
end

function StreamMode:DisconnectPropertyWatchers()
    for _, connection in ipairs(self.propertyConnections) do pcall(function() connection:Disconnect() end) end
    table.clear(self.propertyConnections)
end

function StreamMode:SetActive(value, silent)
    value = value == true
    if value == self.active then
        if value then self:AttachRoots() end
        return false
    end
    self.active = value
    if value then
        self:AttachRoots()
    else
        self:DisconnectRoots()
        self:DisconnectPropertyWatchers()
        for instance, properties in pairs(self.saved) do
            for property, state in pairs(properties) do
                pcall(function() instance[property] = state.original end)
            end
        end
        table.clear(self.saved)
        table.clear(self.watched)
        table.clear(self.markedRoots)
    end
    if not silent and type(self.onChanged) == "function" then pcall(self.onChanged, value) end
    return true
end

function StreamMode:Toggle()
    return self:SetActive(not self.active)
end

function StreamMode:Destroy()
    self:SetActive(false, true)
    for _, connection in ipairs(self.inputConnections) do pcall(function() connection:Disconnect() end) end
    table.clear(self.inputConnections)
    self.onChanged = nil
end

local function updateStreamModeButton()
    if streamModeButton and streamModeButton.Parent then
        streamModeButton.Text = NoirTr(StreamMode.active and "Stream Mode: ON" or "Stream Mode: OFF")
    end
end
StreamMode.onChanged = function(enabled)
    NoirPersistence.data.toggles["Noir::StreamMode"] = enabled
    NoirPersistence.Save()
    updateStreamModeButton()
end
rawset(streamEnvironment, STREAM_MODE_GLOBAL, StreamMode)

local activeStreamTouches = {}
local streamTouchHolding, streamTouchFired, streamTouchToken = false, false, nil
local function streamTouchCount()
    local count = 0
    for _ in pairs(activeStreamTouches) do count = count + 1 end
    return count
end
local inputBeganOk, streamInputBegan = pcall(function()
    return UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.RightShift then
            local textFocused = false
            pcall(function() textFocused = UIS:GetFocusedTextBox() ~= nil end)
            if not textFocused then StreamMode:Toggle() end
            return
        end
        if input.UserInputType == Enum.UserInputType.Touch then
            activeStreamTouches[input] = true
            if streamTouchCount() >= 3 and not streamTouchHolding then
                streamTouchHolding, streamTouchFired = true, false
                local token = {}
                streamTouchToken = token
                task.delay(1.3, function()
                    if streamTouchToken ~= token or not streamTouchHolding or streamTouchFired or streamTouchCount() < 3 then return end
                    streamTouchFired = true
                    StreamMode:Toggle()
                end)
            end
        end
    end)
end)
if inputBeganOk and streamInputBegan then table.insert(StreamMode.inputConnections, streamInputBegan) end
local inputEndedOk, streamInputEnded = pcall(function()
    return UIS.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        activeStreamTouches[input] = nil
        if streamTouchCount() < 3 then
            streamTouchHolding, streamTouchFired, streamTouchToken = false, false, nil
        end
    end)
end)
if inputEndedOk and streamInputEnded then table.insert(StreamMode.inputConnections, streamInputEnded) end

StreamMode:SetActive(NoirPersistence.data.toggles["Noir::StreamMode"] == true, true)
return StreamMode, updateStreamModeButton
end
local StreamMode, updateStreamModeButton = createStreamModeController()

local scale = New("\x55IScale", { Parent = gui, Scale = 1 })
function rescale()
    local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local usable = math.max(v.Y - 70, 320)
    scale.Scale = math.min(v.X / 1080, usable / 720, 0.96)
end
rescale()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("\x56iewportSize"):Connect(rescale) end

local winShadow = New("\x49mageLabel", { Parent = gui, Image = "\x72bxassetid://112971167999062", ImageColor3 = Color3.fromRGB(0,0,0),
    ImageTransparency = .88, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(Vector2.new(112,112), Vector2.new(147,147)), SliceScale = .6, ZIndex = 1, Visible = false })
local win = New("\x46rame", { Parent = gui, Name = "\x57indow", AnchorPoint = Vector2.new(.5, .5),
    Position = NoirPersistence.GetPosition("\x77indow", UDim2.fromScale(.5, .5)), Size = UDim2.fromOffset(1000, 700),
    BackgroundColor3 = C.base, BackgroundTransparency = .70, ClipsDescendants = true, Visible = false, ZIndex = 2 })
winShadow.Position = win.Position
winShadow.Size = UDim2.new(0, win.Size.X.Offset + 44, 0, win.Size.Y.Offset + 44)
winShadow.AnchorPoint = win.AnchorPoint
local winScale = New("\x55IScale", { Parent = win, Scale = .82 })
corner(win, 16)
local winStroke = ringStroke(win, 2, 0)
do
    local g = winStroke:FindFirstChildOfClass("UIGradient")
    if g then g.Color = NoirFX.RING; NoirFX.spin(g) end
end
local winGlow = New("\x55IStroke", { Parent = win, Color = C.accent, Thickness = 4, Transparency = .62, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
do
    local winTint = New("Frame", { Parent = win, Name = "NoirTint", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.accent, BorderSizePixel = 0, Active = false, ZIndex = 0 })
    corner(winTint, 16)
    New("UIGradient", { Parent = winTint, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, .90), NumberSequenceKeypoint.new(.45, .97), NumberSequenceKeypoint.new(1, 1) }) })
    pcall(function()
        TweenService:Create(winGlow, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = .80 }):Play()
    end)
end
win.Changed:Connect(function(prop)
    if prop == "Position" then winShadow.Position = win.Position end
    if prop == "Visible" then winShadow.Visible = win.Visible end
    if prop == "AbsoluteSize" then
        winShadow.Size = UDim2.new(0, win.AbsoluteSize.X + 44, 0, win.AbsoluteSize.Y + 44)
    end
end)

local navButtons, navIcons = {}, {}
local sidebar = New("\x46rame", { Parent = win, Size = UDim2.new(0, 78, 1, 0), BackgroundTransparency = 1 })
local logo = New("\x54extLabel", { Parent = sidebar, AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 23), Size = UDim2.fromOffset(60, 60),
    BackgroundColor3 = C.accent, Text = "\x4e", TextColor3 = Color3.fromRGB(10,9,8), TextSize = 30, Font = Enum.Font.GothamBold })
corner(logo, 14); local logoStroke = stroke(logo, C.accent2, .4)
NoirFX.spin(New("UIGradient", { Parent = logoStroke, Color = NoirFX.RING }))
pcall(function()
    TweenService:Create(logoStroke, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = .78 }):Play()
end)
logo.TextStrokeTransparency = 1
do
    local navDefs = {
        { "\x68ome",   16898613509, Vector2.new(820, 147), "\x48ome" },
        { "\x6dain",   16898613509, Vector2.new(820, 147), "Main" },
        { "\x61im",    16898613777, Vector2.new(967, 759), "Page A" },
        { "\x77orld",  16898613509, Vector2.new(771, 563), "Page B" },
        { "\x6dap",    16898613509, Vector2.new(771, 563), "Page C" },
        { "\x66arm",   16898613509, Vector2.new(771, 563), "Page D" },
        { "\x76isual", 16898613353, Vector2.new(771, 563), "\x56isuals" },
        { "\x73kins",  16898613353, Vector2.new(771, 563), "Page E" },
        { "\x65motes", 16898613777, Vector2.new(967, 759), "Page F" },
        { "\x6disc",   16898613509, Vector2.new(820, 147), "\x4disc" },
        { "\x74roll",  16898613777, Vector2.new(869, 563), "Page G" },
        { "\x73ettings", 16898613509, Vector2.new(121, 906), "\x53ettings" },
    }
    for i, d in ipairs(navDefs) do
        local b = New("\x54extButton", { Parent = sidebar, Position = UDim2.fromOffset(19, 104 + (i - 1) * 42), Size = UDim2.fromOffset(40, 40),
            BackgroundColor3 = C.accent, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Name = d[4] })
        corner(b, 14)
        local ic = New("\x49mageLabel", { Parent = b, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(24, 24),
            BackgroundTransparency = 1, Image = "\x72bxassetid://" .. d[2], ImageRectSize = Vector2.new(48, 48), ImageRectOffset = d[3],
            ImageColor3 = C.dim })
        local lbl = New("\x54extLabel", { Parent = b, Position = UDim2.fromOffset(50, 0), Size = UDim2.new(1, -60, 1, 0), Visible = false,
            BackgroundTransparency = 1, Text = NoirTr(d[4]), TextColor3 = C.dim, TextSize = 15, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left })
        local bar = New("\x46rame", { Parent = b, Position = UDim2.fromOffset(0, 8), Size = UDim2.fromOffset(3, 22), BackgroundColor3 = C.accent, Visible = false, BackgroundTransparency = 1 })
        corner(bar, 2)
        local glyphs = nil
        local rings = nil
        if d[1] == "\x65motes" then
             
            ic.Visible = false
            glyphs = {}
            local function glyphPart(position, size, rounded)
                local part = New("\x46rame", { Parent = b, Position = position, Size = size, BackgroundColor3 = C.dim, BorderSizePixel = 0 })
                if rounded then corner(part, rounded) end
                glyphs[#glyphs + 1] = part
            end
            glyphPart(UDim2.fromOffset(20, 8), UDim2.fromOffset(10, 10), 5)
            glyphPart(UDim2.fromOffset(21, 18), UDim2.fromOffset(8, 10), 3)
            glyphPart(UDim2.fromOffset(15, 20), UDim2.fromOffset(20, 4), 2)
            glyphPart(UDim2.fromOffset(19, 27), UDim2.fromOffset(4, 8), 2)
            glyphPart(UDim2.fromOffset(27, 27), UDim2.fromOffset(4, 8), 2)
        elseif d[1] == "\x73kins" then
            ic.Visible = false
            glyphs = {}
            local function glyphPart(position, size, rounded)
                local part = New("\x46rame", { Parent = b, Position = position, Size = size, BackgroundColor3 = C.dim, BorderSizePixel = 0 })
                if rounded then corner(part, rounded) end
                glyphs[#glyphs + 1] = part
            end
            glyphPart(UDim2.fromOffset(22, 10), UDim2.fromOffset(8, 24), 3)
            glyphPart(UDim2.fromOffset(20, 8), UDim2.fromOffset(12, 6), 2)
        elseif d[1] == "\x6dap" then
            ic.Visible = false
            glyphs = {}
            local function glyphPart(position, size, rounded)
                local part = New("\x46rame", { Parent = b, Position = position, Size = size, BackgroundColor3 = C.dim, BorderSizePixel = 0 })
                if rounded then corner(part, rounded) end
                glyphs[#glyphs + 1] = part
            end
            glyphPart(UDim2.fromOffset(20, 9), UDim2.fromOffset(12, 12), 6)
            glyphPart(UDim2.fromOffset(23, 20), UDim2.fromOffset(6, 10), 2)
        elseif d[1] == "\x66arm" then
            ic.Visible = false
            glyphs = {}
            local function glyphPart(position, size, rounded)
                local part = New("\x46rame", { Parent = b, Position = position, Size = size, BackgroundColor3 = C.dim, BorderSizePixel = 0 })
                if rounded then corner(part, rounded) end
                glyphs[#glyphs + 1] = part
            end
            glyphPart(UDim2.fromOffset(18, 14), UDim2.fromOffset(16, 16), 8)
            glyphPart(UDim2.fromOffset(22, 18), UDim2.fromOffset(8, 8), 4)
        elseif d[1] == "\x6disc" then
             
            ic.Visible = false
            glyphs, rings = {}, {}
            local ring = New("\x46rame", { Parent = b, Position = UDim2.fromOffset(14, 10), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, BorderSizePixel = 0 })
            corner(ring, 13)
            local ringStroke = New("\x55IStroke", { Parent = ring, Color = C.dim, Thickness = 1.5, Transparency = .08 })
            rings[#rings + 1] = ringStroke
            for index = 0, 2 do
                local dot = New("\x46rame", { Parent = ring, Position = UDim2.fromOffset(5 + index * 6, 11), Size = UDim2.fromOffset(4, 4), BackgroundColor3 = C.dim, BorderSizePixel = 0 })
                corner(dot, 2); glyphs[#glyphs + 1] = dot
            end
        elseif d[1] == "\x73ettings" then
            ic.Visible = false
            glyphs, rings = {}, {}
            local ring = New("\x46rame", { Parent = b, Position = UDim2.fromOffset(14, 6), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, BorderSizePixel = 0 })
            corner(ring, 12)
            local ringStroke = New("\x55IStroke", { Parent = ring, Color = C.dim, Thickness = 1.5, Transparency = .08 })
            rings[#rings + 1] = ringStroke
            local centerDot = New("\x46rame", { Parent = ring, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, 0, .5, 0), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = C.dim, BorderSizePixel = 0 })
            corner(centerDot, 4); glyphs[#glyphs + 1] = centerDot
            local tickPos = { UDim2.fromOffset(10, -2), UDim2.fromOffset(10, 22), UDim2.fromOffset(-2, 10), UDim2.fromOffset(22, 10) }
            for index = 1, 4 do
                local tick = New("\x46rame", { Parent = ring, Position = tickPos[index], Size = UDim2.fromOffset(4, 4), BackgroundColor3 = C.dim, BorderSizePixel = 0 })
                corner(tick, 2); glyphs[#glyphs + 1] = tick
            end
        end
        -- центрируем кастомную иконку внутри круглой кнопки 40x40
        do
            local items = {}
            for _, child in ipairs(b:GetChildren()) do
                if child:IsA("\x46rame") and child ~= bar then items[#items + 1] = child end
            end
            if #items > 0 then
                local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
                for _, item in ipairs(items) do
                    local px, py = item.Position.X.Offset, item.Position.Y.Offset
                    local sx, sy = item.Size.X.Offset, item.Size.Y.Offset
                    minX = math.min(minX, px); minY = math.min(minY, py)
                    maxX = math.max(maxX, px + sx); maxY = math.max(maxY, py + sy)
                end
                local dx = math.floor((40 - (maxX - minX)) / 2 - minX + .5)
                local dy = math.floor((40 - (maxY - minY)) / 2 - minY + .5)
                for _, item in ipairs(items) do
                    pcall(function()
                        item.Position = UDim2.fromOffset(item.Position.X.Offset + dx, item.Position.Y.Offset + dy)
                    end)
                end
            end
        end
        navButtons[d[1]] = b; navIcons[d[1]] = { icon = ic, label = lbl, bar = bar, glyphs = glyphs, rings = rings }
    end
end
local status = New("\x46rame", { Parent = sidebar, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, Visible = false, BackgroundColor3 = C.panel, BackgroundTransparency = .18 })
corner(status, 16); stroke(status, C.border, .6)
local statusDot = New("\x46rame", { Parent = status, Position = UDim2.fromOffset(16, 21), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = C.accent })
corner(statusDot, 4)
text(status, "\x43onnected", 13, UDim2.fromOffset(30, 15))
text(status, "\x4eoir Client • v4", 15, UDim2.fromOffset(16, 45))

local header = New("\x46rame", { Parent = win, Position = UDim2.fromOffset(79, 0), Size = UDim2.new(1, -79, 0, 60), BackgroundTransparency = 1 })
local headerTitle = text(header, "NOIR UI", 24, UDim2.fromOffset(28, 24)); headerTitle.Visible = false
local headerSub = text(header, "Interface template", 13, UDim2.fromOffset(29, 56), true); headerSub.Visible = false
local creatorImage = ""
do
    local customAsset = (type(getcustomasset) == "\x66unction" and getcustomasset) or (type(getsynasset) == "\x66unction" and getsynasset)
    if type(writefile) == "\x66unction" and customAsset then
        local encoded = "\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\x6fCiiig//2Q=="
        local alphabet = "\x41BCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local decoded = encoded:gsub("\x5b^" .. alphabet .. "\x3d]", ""):gsub("\x2e", function(x)
            if x == "\x3d" then return "" end
            local r, f = "", alphabet:find(x, 1, true) - 1
            for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "\x31" or "\x30") end
            return r
        end):gsub("\x25d%d%d?%d?%d?%d?%d?%d?", function(x)
            if #x ~= 8 then return "" end
            local c = 0
            for i = 1, 8 do c = c + (x:sub(i, i) == "\x31" and 2 ^ (8 - i) or 0) end
            return string.char(c)
        end)
        local imagePath = ASSETS_FOLDER .. "\x2fNOIR_CREATOR.jpg"
        local wrote = pcall(writefile, imagePath, decoded)
        if wrote and type(isfile) == "\x66unction" then
            local okFile, exists = pcall(isfile, imagePath)
            wrote = okFile and exists == true
        end
        if wrote then
            local ok, asset = pcall(customAsset, imagePath)
            if ok and type(asset) == "\x73tring" and asset ~= "" then creatorImage = asset end
        end
    end
end
local search = New("\x54extBox", { Parent = header, Position = UDim2.fromOffset(15, 15), Size = UDim2.fromOffset(313, 30),
    BackgroundColor3 = C.base, BackgroundTransparency = .45, PlaceholderText = "\x53earch", Text = "", TextColor3 = C.text,
    PlaceholderColor3 = C.dim, TextSize = 14, Font = Enum.Font.Gotham, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left })
corner(search, 4); local searchStroke = stroke(search, C.border, 0)
New("\x55IPadding", { Parent = search, PaddingLeft = UDim.new(0, 8) })
local loadUserThumbnail
do
    local jobs = {}
    local resolved = nil
    function loadUserThumbnail(label, letterLabel)
        if resolved then
            local ok = pcall(function() label.Image = resolved end)
            if ok and letterLabel then letterLabel.Visible = false end
            return
        end
        table.insert(jobs, { label = label, letter = letterLabel })
    end
    task.spawn(function()
        local attempts = {
            function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) end,
            function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180) end,
            function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420) end,
        }
        local got
        for _, loader in ipairs(attempts) do
            local ok, img = pcall(loader)
            if ok and type(img) == "\x73tring" and img ~= "" then got = img break end
            task.wait(0.35)
        end
        resolved = got
        for _, job in ipairs(jobs) do
            if got then
                local ok = pcall(function() job.label.Image = got end)
                if ok and job.letter then job.letter.Visible = false end
            end
        end
    end)
end

local icon = New("\x49mageLabel", { Parent = sidebar, AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -18), Size = UDim2.fromOffset(34, 34),
    BackgroundColor3 = C.surface, Image = creatorImage, ScaleType = Enum.ScaleType.Crop })
corner(icon, 17); stroke(icon, C.border, .2)
local iconLetter = New("\x54extLabel", { Parent = icon, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
    Text = "\x4e", TextColor3 = C.accent, TextSize = 16, Font = Enum.Font.GothamBold })
if creatorImage ~= "" then
    pcall(function() iconLetter.Visible = false end)
else
    loadUserThumbnail(icon, iconLetter)
end
function styleCircularButton(b, diameter)
    b.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    b.BackgroundTransparency = .82
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.ClipsDescendants = false
    b.ZIndex = 20
    corner(b, math.floor(diameter / 2))
    local outer = New("\x55IStroke", { Parent = b, Color = Color3.fromRGB(255, 255, 255), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    local gradient = New("\x55IGradient", { Parent = outer, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
        ColorSequenceKeypoint.new(.22, Color3.fromRGB(250, 250, 252)),
        ColorSequenceKeypoint.new(.48, Color3.fromRGB(70, 70, 78)),
        ColorSequenceKeypoint.new(.72, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 52)),
    }) })
    table.insert(gradientStrokes.fast, gradient)
    local inner = New("\x55IStroke", { Parent = b, Color = Color3.fromRGB(105, 105, 112), Transparency = .5, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    local innerGradient = gradient:Clone(); innerGradient.Rotation = 180; innerGradient.Parent = inner
    table.insert(gradientStrokes.fast, innerGradient)
    local sound = Instance.new("\x53ound")
    sound.Name = "\x4eoirButtonSound"; sound.SoundId = "\x72bxassetid://3868133279"; sound.Volume = .35; sound.Parent = b
    local baseTextSize = b.TextSize
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(.18), { BackgroundTransparency = .68, TextSize = baseTextSize + 1 }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(.22), { BackgroundTransparency = .82, TextSize = baseTextSize }):Play()
    end)
    b.MouseButton1Down:Connect(function()
        sound:Play()
        TweenService:Create(b, TweenInfo.new(.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(27, 27, 31), Size = UDim2.fromOffset(diameter + 6, diameter + 6) }):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b, TweenInfo.new(.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(8, 8, 10), Size = UDim2.fromOffset(diameter, diameter) }):Play()
    end)
    return b
end
function topButton(txt, x, color, fontSize)
    local b = New("\x54extButton", { Parent = header, Position = UDim2.new(1, x, 0, 26), Size = UDim2.fromOffset(44, 44),
        BackgroundColor3 = color or C.btn, Text = txt, TextColor3 = C.text, TextSize = fontSize or 22, Font = Enum.Font.GothamBold })
    return styleCircularButton(b, 44)
end

 
 
local miniArrowImage = ""
do
    local customAsset = (type(getcustomasset) == "\x66unction" and getcustomasset) or (type(getsynasset) == "\x66unction" and getsynasset)
    if type(writefile) == "\x66unction" and customAsset then
        local encodedArrow = "\x69VBORw0KGgoAAAANSUhEUgAAAJYAAACWCAQAAACWCLlpAAAAIGNIUk0AAHomAACA\x68AAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0\x53U1FB+oFCgkRIyI5lL0AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDUtMTBUMDk6\x4dTc6MzUrMDA6MDC/MZyeAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA1LTEwVDA5\x4fjE3OjM1KzAwOjAwzmwkIgAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNS0x\x4dFQwOToxNzozNSswMDowMJl5Bf0AAAlKSURBVHja7Z17jBVnGYefmbM3dpcCW26l\x79K4FiqWsAtpVRKSXpCACFaoJQQMNjRQsjYmJRo1tTWOJtQlNDaS0pFELbcVgYoxG\x326hJvZBINFYSixEr4ALSlksBAWF3z88/ztlznTlnbufM7Jx55q9zf78n7/d+35n5\x5asYQxRgk2GGGHcBIIpHlgkSWC/KyrmMBrWGHE3GU2VL6ndL6gZL6XomsrF4NSDqo\x56NjxRJnhbriSFNCS1LBKNAFgsgwDaMNM5l0VEEJTdEWSdFrtonhLyJPpdouz42B7\x4etMSLDEBgzuyva2JzrADijImYLIo92hy2AFFGROYQk/u0dSwA4oyJjC3YOZ+Q9gB\x52RkTgw/m5gcGs5K5gj0mML/gcU/YAUUZE5NZBY97k8yqgCbqkvJc0IRkUmqHyWRG\x46Tzu5OawQ4ouZllJvy3piHaYTC3qawYfCTuk6FI+Df0QzWEHFVVMppR0ux7eG3ZQ\x55cVkTNkzt4cdVFQxub7kGYMlSYm3pjyzYDEdYYcVTaxkjWNx2GFFE5O2sucMViUd\x30RJdVjn/0ejk7045pmUOTeLOsAOLIqZl8hisSzqiBTovK/6rqUk3LMXkiuXz7Xwu\x79a0y9Kas+YfakswqxuSczSszWB52cFHD5KzNKwZfTI5PF2Pyru1rH80dfE0AwOSt\x43q99LVmCVIhJf4UqfmeSW4WYnKwwRUjxiJqSoz051Ke07BnS8kRWXtYUXVUl/pqZ\x62yWyALXqaEVZaW1JZA3LMvRrVeZtTUlkQWZhyOtV3jOBrckUAgChtRVLvCQNammS\x57RlZt2pA1TissYkshFp0oqos6RkZpcu+G06ekKEfO5A1oJWNLssExGsOWt3EMw2/\x50FcIzdGgg9ySXlVrI2dWpsmtOuxIVlqPlVauhkKZqrWj6vRhuHKtbnRZ6BMOZUln\x31Nvosjp1yqEs6bAmN6as4b8xl/iF48/MYG/+hKioFfyaxpP72rs15Di3pH3l42Ij\x79WrVERey0nq2dB9qI8kytNVxkc/oelJmo8pCs/Q/F7KktB4v1xU29ZJl6OeuZElp\x66VupxpSFlrsq8pI0pG1qbkxZzTroUpaU1vcKD2mETa6XZLcgv9soad797PKw1Ohn\x66JYLNj9QczlldLKMu7iVTt7lIK/wK65WEODux4q2Dv3LdW5J0h81LZx5V8nvpXS/\x6ahWN6mkd0iqrcdtDfGUf/4KrCUSeY+qz2pdaV1nt2mMZ/aC2Wc8K/crqtF3eVo0L\x57lf/qUTBbzXphxUq687igSgYWWiDx9ySBvW0RoUma1PFuNPaaZVdfmW16nWPsqS0\x39mt6KLLG6mTV2Cx0+ZWFljrczWzNaa3Nd8c6yTK03kF/sPhH61+WqZ/4kCUN6YXh\x459PrJutFh5lfkl2uMEq27JfMtFkf75xjWmk/YAfXTXOy/uwwLttS7yAeG1mGvu65\x7aA8zqD2FS0pqKsvUIcdx2ZR677LQKP3JpyxJekeb1RKpzKqiy5ss1Je9Xps/0jqg\x3260P/Qcqa4/LqHZ62HlZQZahR313xQwD2qvZtVkrkYt1nctYvcy7KshCbfpDILIk\x36bK2q7tcWECy0BhHy1tKdTUHJwvdrDOB6ZIuaFupsMBkoQdc9wOL7PIjC63xNUEt\x356J26Ja8sABlNekl19H4m3eVBWPoqYAqV56r2qs77Idvz1u7fupfl48yIdSm3wQs\x535KGdEAb1WU/TnraOoLW5T7NJztcZeM+zDPapY+rJUBlXrOrOShZaK7O1kSXJA3p\x6bB7XB5QKSFmg2eWtgC6xvKhBUKQ1oL9pq/rUGoCyAHV5k4XW61oNdWUY0jE9r7Wa\x4atOXtMB0eZVl6Euujyt6Ia20rugv+q4+o241e5QWkC6vspCph+uiKx/8VR3RPn1V\x79zRN7TKEC3VeddkeNK562KzErck3+UbdL2IgIM0pjvIGR/g7JzjJOwyStgszSwcv\x738L1bz3HFgatXnIrC0we5pHQzuURBgKucpnznOAUFznDWc5ziWsMcI0BAFI00UwL\x593mMrqB0uZcFBl/hW5E6Mz8fpFH2rJdeIHbxYLkuL7LAYAPbLS4mFR8ss8ubLDBY\x77QsWFyqLD+I5Hsp26lyjq37Glj728Z6w21RDyrLLT6E+wCIOhN2iGmKwke2Ftdnf\x71HaMu9jtduY2gjDYyI68Lt8zJqXYzHeKLmYdLwo6o39ZYLCA7zMz7FbVjJyuICaX\x59j8LeLlgPh0vDDayDTOYzMqQYg1PMSHsltWINPexOzhZAN08zcqYXv7uOHOClQUp\x31vJELG9IIzYG/Yd4iN3M49nimW8sMPhk0Jk1/MULeYIFMeuQRwJvTk5eM2t5lJ4Y\x43btUO1kAo9nEl2MzQp6urSyA8TzEg3TFIMP2114WGEzkATYzaUQLE0/WQxaAwVg2\x73InpI1bYNfrqJStDGyvZwgJSI1DZbtbXVxaAyTw+z71cP6KE/ZOFvF1/WQAGY1jF\x66fTROiKU9bOEQyHcJrpApslN3Msaem3udxAV+lnKGxCurAxNvI97WM0cmiOp7DhL\x4dqqiICsThUkPd7OCPrrCiMqWXFYRRlgVapoBXMd8lrKI99MeAWVFqqIlKx+TwTj6\x2bBi3MTc7aoYhrkRVNGUVxtbBdOYzj7lMZ1L2fur1oUxVtGUVxziKifRyE7cwkxmM\x5aRRNgIFq0oaCsl4aSB3xfZDRAFK0cQM30k0P45nGVMbTRXt2Ib//dllkVSiy/FIk\x4fx99M6PpoIsbmcwEJjGRMXQxnm5a/KkacYKKZTnYMlcLMfVpD+e1/VuzPS+TjBou\x56pWu9rC+ukRVY8gyPKnqL1XVGLICUtUIsgLpgI0gy1sHtFEVd1mBqhrhsirKC6Cs\x785oiWff4L+uxpqChs3XOfweMNQXnFb0SRK2KNblmftjBbUsclPVKxOV+OgarSbn6\x78HHrPQuxJjcOvuanrDdWZsF4F+/tt9q1V50ondvlD+e12fP+qvhk1lsO39fvvVbF\x529bvHeWWD1UxIFeae6vc1NKmrDcUBf8LfxT0vCp2FDR8WsUrlcZxf5UPWWihTtuo\x4fhrL/VW+ZKE5OlB2Aau0XrW7pniDycpjZNS1ap1+qysakjSki/qlPlV4WQu/vxAT\x4dgejBWAyjumM5hxvcrH41D4/DY6RrExzqp306KfBsZmUZiTUtgbFRlY9SnVsZNWD\x2fwNVQ1uk90AZPQAAAABJRU5ErkJggg=="
        local alphabet = "\x41BCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local decodedArrow = encodedArrow:gsub("\x5b^" .. alphabet .. "\x3d]", ""):gsub("\x2e", function(x)
            if x == "\x3d" then return "" end
            local r, f = "", alphabet:find(x, 1, true) - 1
            for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "\x31" or "\x30") end
            return r
        end):gsub("\x25d%d%d?%d?%d?%d?%d?%d?", function(x)
            if #x ~= 8 then return "" end
            local c = 0
            for i = 1, 8 do c = c + (x:sub(i, i) == "\x31" and 2 ^ (8 - i) or 0) end
            return string.char(c)
        end)
        local arrowPath = ASSETS_FOLDER .. "\x2fNOIR_MINIMIZE_ARROW.png"
        local wrote = pcall(writefile, arrowPath, decodedArrow)
        if wrote then
            local ok, asset = pcall(customAsset, arrowPath)
            if ok and type(asset) == "\x73tring" then miniArrowImage = asset end
        end
    end
end

local mini = topButton(miniArrowImage == "" and "↘" or "", -98, C.btn, 35)
if miniArrowImage ~= "" then
    New("\x49mageLabel", {
        Parent = mini,
        Name = "\x4dinimizeArrow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(35, 35),
        BackgroundTransparency = 1,
        Active = false,
        Image = miniArrowImage,
        ImageColor3 = C.text,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = mini.ZIndex + 1,
    })
end

local dragging, dragStart, startPos
header.Active = true
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = win.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local half = win.AbsoluteSize / 2
        local desired = Vector2.new(startPos.X.Scale * view.X + startPos.X.Offset * scale.Scale + delta.X,
            startPos.Y.Scale * view.Y + startPos.Y.Offset * scale.Scale + delta.Y)
        desired = Vector2.new(math.clamp(desired.X, half.X, view.X - half.X), math.clamp(desired.Y, half.Y, view.Y - half.Y))
        win.Position = UDim2.fromOffset(desired.X / scale.Scale, desired.Y / scale.Scale)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if dragging then NoirPersistence.SetPosition("\x77indow", win.Position) end
        dragging = false
    end
end)

local restore = New("\x54extButton", { Parent = gui, Name = "NoirRestoreButton", AnchorPoint = Vector2.new(1, .5), Position = NoirPersistence.GetPosition("\x72estore", UDim2.new(1, -22, .5, 0)),
    Size = UDim2.fromOffset(62, 62), BackgroundColor3 = C.panel, Text = "\x4e", TextColor3 = C.text, TextSize = 30,
    Font = Enum.Font.GothamBold, Visible = false, AutoButtonColor = false })
styleCircularButton(restore, 62)
local restoreDragging, restoreMoved, restoreStart, restorePos = false, false, nil, nil
restore.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        restoreDragging = true; restoreMoved = false; restoreStart = input.Position; restorePos = restore.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if restoreDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - restoreStart
        if delta.Magnitude > 7 then restoreMoved = true end
        local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local x = math.clamp(restorePos.X.Offset * scale.Scale + delta.X, 34, view.X - 34)
        local y = math.clamp(restorePos.Y.Scale * view.Y + restorePos.Y.Offset * scale.Scale + delta.Y, 34, view.Y - 34)
        restore.Position = UDim2.fromOffset(x / scale.Scale, y / scale.Scale)
    end
end)
UIS.InputEnded:Connect(function(input)
    if restoreDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
        restoreDragging = false; NoirPersistence.SetPosition("\x72estore", restore.Position)
    end
end)
-- Гарантированная запись: при закрытии игры, телепорте и раз в 15 секунд,
-- чтобы правки не терялись, если экзекутор убивает скрипт без выгрузки.
task.spawn(function()
    pcall(function() game:BindToClose(function() NoirPersistence.WriteNow() end) end)
    while true do
        task.wait(15)
        if NoirPersistence.dirty then NoirPersistence.WriteNow(); NoirPersistence.dirty = false end
    end
end)

mini.MouseButton1Click:Connect(function()
    TweenService:Create(winScale, TweenInfo.new(.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Scale = .72 }):Play()
    task.delay(.28, function() if win.Parent then win.Visible = false; restore.Visible = true end end)
end)
restore.MouseButton1Click:Connect(function()
    if restoreMoved then restoreMoved = false return end
    restore.Visible = false; win.Visible = true; winScale.Scale = .72
    TweenService:Create(winScale, TweenInfo.new(.46, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end)

local function __noirW1b()
local content = New("\x53crollingFrame", { Parent = win, Position = UDim2.fromOffset(79, 62), Size = UDim2.new(1, -79, 1, -62),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
    CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.None,
    ScrollingDirection = Enum.ScrollingDirection.Y, ScrollingEnabled = false, Active = false,
    ElasticBehavior = Enum.ElasticBehavior.Never, VerticalScrollBarInset = Enum.ScrollBarInset.Always })
local cols, configContent, configCols, visualContent, visualCols, mainContent, mainCols, worldContent, worldCols, emotesContent, emotesCols, miscContent, miscCols, trollContent, trollCols, mapCols, farmCols, emotesGameCol, showEmotesTab, emotesTabBar

do
 
 
local function makeDualScrollColumns(parent, single)
    local function makeColumn(name, position, size, padLeft, padRight)
        local col = New("\x53crollingFrame", { Parent = parent, Name = name,
            Position = position, Size = size,
            BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = C.accent,
            CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y, ScrollingEnabled = true, Active = true,
            ElasticBehavior = Enum.ElasticBehavior.WhenScrollable, VerticalScrollBarInset = Enum.ScrollBarInset.Always })
        New("\x55IListLayout", { Parent = col, Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder })
        New("\x55IPadding", { Parent = col, PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, padLeft), PaddingRight = UDim.new(0, padRight) })
        return col
    end
    if single then
        local col = makeColumn("\x4eoirColumn1", UDim2.fromOffset(0, 0), UDim2.new(1, -6, 1, 0), 14, 7)
        return { col, col }
    end
    local left = makeColumn("\x4eoirColumn1", UDim2.fromOffset(0, 0), UDim2.new(.5, -7, 1, 0), 14, 7)
    local right = makeColumn("\x4eoirColumn2", UDim2.new(.5, 7, 0, 0), UDim2.new(.5, -7, 1, 0), 7, 14)
    return { left, right }
end
local function configureDualScrollPage(page)
    page.ScrollingEnabled = false
    page.Active = false
    page.ScrollBarThickness = 0
    page.AutomaticCanvasSize = Enum.AutomaticSize.None
    page.CanvasSize = UDim2.fromOffset(0, 0)
end

cols = makeDualScrollColumns(content)
configContent = content:Clone(); configContent.Name = "\x43onfigContent"; configContent.Parent = win; configContent.Visible = false; configContent:ClearAllChildren(); configureDualScrollPage(configContent)
configCols = makeDualScrollColumns(configContent)
content.Position = UDim2.fromOffset(79, 62); content.Size = UDim2.new(1, -79, 1, -62); content.Visible = false
configContent.Position = content.Position; configContent.Size = content.Size
visualContent = content:Clone(); visualContent.Name = "\x56isualContent"; visualContent.Parent = win; visualContent.Visible = false; visualContent:ClearAllChildren(); configureDualScrollPage(visualContent)
visualCols = makeDualScrollColumns(visualContent)
mainContent = content:Clone();
 mainContent.Name = "\x4dainContent"; mainContent.Parent = win; mainContent.Visible = false; mainContent:ClearAllChildren(); configureDualScrollPage(mainContent)
mainCols = makeDualScrollColumns(mainContent)
worldContent = content:Clone(); worldContent.Name = "\x57orldContent"; worldContent.Parent = win; worldContent.Visible = false; worldContent:ClearAllChildren(); configureDualScrollPage(worldContent)
worldCols = makeDualScrollColumns(worldContent)
emotesContent = content:Clone(); emotesContent.Name = "\x45motesContent"; emotesContent.Parent = win; emotesContent.Visible = false; emotesContent:ClearAllChildren(); configureDualScrollPage(emotesContent)
emotesCols = makeDualScrollColumns(emotesContent, true)
-- ---- Emotes sub-tabs: real tab bar above the page + opaque GAME EMOTES overlay ----
do
    local tabBar = New("\x46rame", { Parent = win, Name = "NoirEmotesTabBar", Position = UDim2.fromOffset(94, 62),
        Size = UDim2.new(1, -109, 0, 24), BackgroundTransparency = 1, Visible = false, ZIndex = 5 })
    New("\x55IListLayout", { Parent = tabBar, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
    emotesTabBar = tabBar
    local nativeBtn, gameBtn, nativeLine, gameLine
    local function makeItem(label, x, w)
        local b = New("\x54extButton", { Parent = tabBar, Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(w, 24),
            BackgroundColor3 = C.surface, BackgroundTransparency = 1, Text = label, TextColor3 = C.dim, TextSize = 14, Font = Enum.Font.Gotham, AutoButtonColor = false, ZIndex = 6 })
        local line = New("\x46rame", { Parent = b, AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -4),
            Size = UDim2.new(1, -28, 0, 2), BackgroundColor3 = C.accent, BorderSizePixel = 0, Visible = false, ZIndex = 7 })
        corner(line, 1)
        corner(b, 999); stroke(b, C.border, 1)
        return b, line
    end
    nativeBtn, nativeLine = makeItem("\x45MOTES", 6, 150)
    gameBtn, gameLine = makeItem("\x47AME EMOTES", 164, 190)

    emotesContent.Position = UDim2.fromOffset(79, 100)
    emotesContent.Size = UDim2.new(1, -79, 1, -100)

    emotesGameCol = New("\x53crollingFrame", { Parent = emotesContent, Name = "NoirGameEmotes", Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -6, 1, 0), BackgroundColor3 = C.base, BackgroundTransparency = 0, BorderSizePixel = 0,
        ScrollBarThickness = 5, ScrollBarImageColor3 = C.accent, CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollingEnabled = true, Active = true, Visible = false, ZIndex = 40 })
    New("\x55IListLayout", { Parent = emotesGameCol, Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder })
    New("\x55IPadding", { Parent = emotesGameCol, PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 18) })

    local hiddenNative = {}
    local function setNativeVisible(show)
        if show then
            for inst in pairs(hiddenNative) do
                if inst and inst.Parent then inst.Visible = true end
            end
            table.clear(hiddenNative)
        else
            for _, child in ipairs(emotesContent:GetChildren()) do
                if child ~= emotesGameCol and child:IsA("GuiObject") and child.Visible then
                    hiddenNative[child] = true
                    child.Visible = false
                end
            end
        end
    end
    function showEmotesTab(which)
        local game = which == "\x67ame"
        if emotesGameCol then emotesGameCol.Visible = game end
        setNativeVisible(not game)
        nativeLine.Visible = not game
        gameLine.Visible = game
        nativeBtn.TextColor3 = game and C.dim or C.text
        gameBtn.TextColor3 = game and C.text or C.dim
    end
    -- the emotes browser is built by a satellite chunk after this runs: hide its widgets too
    emotesContent.ChildAdded:Connect(function(child)
        if emotesGameCol and emotesGameCol.Visible and child ~= emotesGameCol and child:IsA("GuiObject") and child.Visible then
            hiddenNative[child] = true
            child.Visible = false
        end
    end)
    nativeBtn.MouseButton1Click:Connect(function() showEmotesTab("\x6eative") end)
    gameBtn.MouseButton1Click:Connect(function() showEmotesTab("\x67ame") end)
    if emotesCols[1] then
        emotesCols[1].Position = UDim2.fromOffset(0, 0)
        emotesCols[1].Size = UDim2.new(1, -6, 1, 0)
    end
    showEmotesTab("\x6eative")
    pcall(function() NoirGenv().__NoirEmotesTabs = { Show = showEmotesTab, Game = emotesGameCol, Bar = tabBar } end)
end
miscContent = content:Clone(); miscContent.Name = "\x4discContent"; miscContent.Parent = win; miscContent.Visible = false; miscContent:ClearAllChildren(); configureDualScrollPage(miscContent)
miscCols = makeDualScrollColumns(miscContent)
trollContent = content:Clone(); trollContent.Name = "\x54rollContent"; trollContent.Parent = win; trollContent.Visible = false; trollContent:ClearAllChildren(); configureDualScrollPage(trollContent)
settingsContent = content:Clone(); settingsContent.Name = "\x53ettingsContent"; settingsContent.Parent = win; settingsContent.Visible = false; settingsContent:ClearAllChildren()
settingsContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
New("\x55IListLayout", { Parent = settingsContent, Padding = UDim.new(0, 10) })
New("\x55IPadding", { Parent = settingsContent, PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 16) })
trollCols = makeDualScrollColumns(trollContent)
do
    local mapPage = content:Clone()
    mapPage.Name = "\x4dapContent"
    mapPage.Parent = win
    mapPage.Visible = false
    mapPage:ClearAllChildren()
    configureDualScrollPage(mapPage)
    mapCols = makeDualScrollColumns(mapPage)
    local farmPage = content:Clone()
    farmPage.Name = "\x46armContent"
    farmPage.Parent = win
    farmPage.Visible = false
    farmPage:ClearAllChildren()
    configureDualScrollPage(farmPage)
    farmCols = makeDualScrollColumns(farmPage)
end
end

local dashboard = New("\x46rame", { Parent = win, Position = content.Position, Size = content.Size, BackgroundTransparency = 1 })
local profile = New("\x46rame", { Parent = dashboard, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(400, 168), BackgroundColor3 = C.panel, BackgroundTransparency = .86 })
corner(profile, 18); stroke(profile, C.border, .5)
local avatar = New("\x49mageLabel", { Parent = profile, Position = UDim2.fromOffset(22, 24), Size = UDim2.fromOffset(120, 120), BackgroundColor3 = C.surface })
corner(avatar, 20); stroke(avatar, C.border, .45)
local avatarLetter = New("\x54extLabel", { Parent = avatar, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
    Text = string.upper(string.sub(LocalPlayer.Name, 1, 1)), TextColor3 = C.accent, TextSize = 46, Font = Enum.Font.GothamBold })
loadUserThumbnail(avatar, avatarLetter)
text(profile, LocalPlayer.DisplayName, 24, UDim2.fromOffset(162, 32))
text(profile, "\x40" .. LocalPlayer.Name, 15, UDim2.fromOffset(163, 70), true)
local pill = New("\x46rame", { Parent = profile, Position = UDim2.fromOffset(162, 104), Size = UDim2.fromOffset(158, 30), BackgroundColor3 = C.accent, BackgroundTransparency = .8 })
corner(pill, 15); stroke(pill, C.accent, .35)
local pillDot = New("\x46rame", { Parent = pill, Position = UDim2.fromOffset(12, 11), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = C.accent }); corner(pillDot, 4)
text(pill, "\x43onnected", 13, UDim2.fromOffset(26, 7))
local heroCard = New("\x46rame", { Parent = dashboard, Position = UDim2.fromOffset(446, 0), Size = UDim2.new(1, -446, 0, 168), BackgroundColor3 = C.card, BackgroundTransparency = .84 })
corner(heroCard, 18); stroke(heroCard, C.border, .45)
New("\x55IGradient", { Parent = heroCard, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(46,46,46)), ColorSequenceKeypoint.new(1, Color3.fromRGB(12,12,12)) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, .72), NumberSequenceKeypoint.new(1, .86) }), Rotation = 25 })
text(heroCard, "\x4eOIR SILENT AIM", 26, UDim2.fromOffset(26, 24))
text(heroCard, "Noir UI • interface template", 14, UDim2.fromOffset(27, 62), true)
local statText = text(heroCard, "", 14, UDim2.fromOffset(27, 96), true)
local fpsCard = New("\x46rame", { Parent = dashboard, Position = UDim2.fromOffset(0, 184), Size = UDim2.fromOffset(262, 132), BackgroundColor3 = C.panel, BackgroundTransparency = .86 })
corner(fpsCard, 18); stroke(fpsCard, C.border, .5)
text(fpsCard, "\x46PS", 14, UDim2.fromOffset(22, 20), true)
local fpsText = text(fpsCard, "\x360", 42, UDim2.fromOffset(22, 50)); fpsText.TextColor3 = C.text
local pingCard = New("\x46rame", { Parent = dashboard, Position = UDim2.fromOffset(272, 184), Size = UDim2.fromOffset(262, 132), BackgroundColor3 = C.panel, BackgroundTransparency = .86 })
corner(pingCard, 18); stroke(pingCard, C.border, .5)
text(pingCard, "\x4eETWORK LATENCY", 14, UDim2.fromOffset(22, 20), true)
local pingText = text(pingCard, "\x2d- ms", 42, UDim2.fromOffset(22, 50)); pingText.TextColor3 = C.text
local playerCard = New("\x46rame", { Parent = dashboard, Position = UDim2.fromOffset(544, 184), Size = UDim2.fromOffset(262, 132), BackgroundColor3 = C.panel, BackgroundTransparency = .86 })
corner(playerCard, 18); stroke(playerCard, C.border, .5)
text(playerCard, "\x50LAYERS", 14, UDim2.fromOffset(22, 20), true)
local playerText = text(playerCard, "\x30", 42, UDim2.fromOffset(22, 50)); playerText.TextColor3 = C.text
local infoCard = New("\x46rame", { Parent = dashboard, Position = UDim2.fromOffset(0, 332), Size = UDim2.new(1, 0, 1, -348), BackgroundColor3 = C.panel, BackgroundTransparency = .86 })
corner(infoCard, 18); stroke(infoCard, C.border, .5)
text(infoCard, "\x51UICK START", 18, UDim2.fromOffset(24, 22))
text(infoCard, "\x4fpen Main for player tools, World for gun & fling tools, Visuals\x20for ESP.", 14, UDim2.fromOffset(25, 54), true)
text(infoCard, "\x53ettings are saved automatically to Noir Hub/configs.", 14, UDim2.fromOffset(25, 78), true)
local frameCounter, lastFps = 0, os.clock()
RunService.RenderStepped:Connect(function()
    frameCounter += 1
    local now = os.clock()
    if now - lastFps >= 1 then
        fpsText.Text = tostring(math.floor(frameCounter / (now - lastFps) + .5))
        frameCounter = 0; lastFps = now
        local ok, v = pcall(function() return Stats.Network.ServerStatsItem["\x44ata Ping"]:GetValue() end)
        pingText.Text = ok and (tostring(math.floor(v + .5)) .. "\x20ms") or "\x2d- ms"
        local pl = #Players:GetPlayers()
        playerText.Text = tostring(pl)
        statText.Text = "\x4coaded • " .. tostring(pl) .. "\x20players in server"
    end
end)

local activePage = "\x68ome"
local selectPage
do
    local pageObjects = { home = dashboard, main = mainContent, aim = content, world = worldContent, map = win:FindFirstChild("\x4dapContent"), farm = win:FindFirstChild("\x46armContent"), visual = visualContent, emotes = emotesContent, misc = miscContent, troll = trollContent, settings = settingsContent }
    pcall(function()
        NoirGenv().__NoirRegisterPage = function(name, object)
            if type(name) == "\x73tring" and typeof(object) == "\x49nstance" then pageObjects[name] = object end
        end
    end)
    local pageBasePosition = content.Position
    local emotesBasePosition = emotesContent.Position
    local function basePositionFor(object)
        if object == emotesContent then return emotesBasePosition end
        return pageBasePosition
    end
    local pageTransitionId = 0
    local function pageScaleFor(object)
        local scaler = object:FindFirstChild("\x4eoirPageScale")
        if not scaler then scaler = New("\x55IScale", { Name = "\x4eoirPageScale", Scale = 1, Parent = object }) end
        return scaler
    end
    function selectPage(page)
        if not pageObjects[page] then page = "\x68ome" end
        if NoirPersistence.data.dropdowns["\x4eoir::LastPage"] ~= page then
            NoirPersistence.data.dropdowns["\x4eoir::LastPage"] = page
            NoirPersistence.Save()
        end
        pageTransitionId += 1
        local transitionId = pageTransitionId
        local oldPage = activePage
        local oldObject = pageObjects[oldPage]
        local newObject = pageObjects[page]
        activePage = page

        for _, object in pairs(pageObjects) do
            if object ~= oldObject and object ~= newObject then
                object.Visible = false
                object.Position = basePositionFor(object)
                pageScaleFor(object).Scale = 1
            end
        end
        if oldObject and oldObject ~= newObject and oldObject.Visible then
            local oldScale = pageScaleFor(oldObject)
            oldObject.Position = basePositionFor(oldObject)
            TweenService:Create(oldScale, TweenInfo.new(.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = .96 }):Play()
            task.delay(.18, function()
                if transitionId == pageTransitionId and oldObject ~= pageObjects[activePage] then
                    oldObject.Visible = false
                    oldObject.Position = basePositionFor(oldObject)
                    oldScale.Scale = 1
                end
            end)
        end
        if newObject then
            local newScale = pageScaleFor(newObject)
            newObject.Position = basePositionFor(newObject)
            if newObject:IsA("\x53crollingFrame") then
                newObject.CanvasPosition = Vector2.new(0, newObject.CanvasPosition.Y)
            end
            newScale.Scale = .94
            newObject.Visible = true
            TweenService:Create(newScale, TweenInfo.new(.62, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        end
        if emotesTabBar then emotesTabBar.Visible = (page == "\x65motes") end
        configContent.Visible = false
        for name, b in pairs(navButtons) do
            local active = name == page
            TweenService:Create(b, TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundColor3 = C.accent, BackgroundTransparency = active and 0 or 1 }):Play()
            local data = navIcons[name]
            if data then
                TweenService:Create(data.icon, TweenInfo.new(.2), { ImageColor3 = active and Color3.fromRGB(10,9,8) or C.dim }):Play()
                if data.glyphs then
                    for _, glyph in ipairs(data.glyphs) do TweenService:Create(glyph, TweenInfo.new(.2), { BackgroundColor3 = active and C.accent or C.dim }):Play() end
                end
                if data.rings then
                    for _, ring in ipairs(data.rings) do TweenService:Create(ring, TweenInfo.new(.2), { Color = active and C.accent or C.dim }):Play() end
                end
                TweenService:Create(data.label, TweenInfo.new(.2), { TextColor3 = active and C.text or C.dim }):Play()
                TweenService:Create(data.bar, TweenInfo.new(.2), { BackgroundTransparency = active and 0 or 1 }):Play()
            end
        end
    end
end
for name, b in pairs(navButtons) do b.MouseButton1Click:Connect(function() if activePage == name then selectPage("\x68ome") else selectPage(name) end end) end
for name, b in pairs(navButtons) do
    b.MouseEnter:Connect(function()
        if activePage ~= name then TweenService:Create(b, TweenInfo.new(.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundColor3 = C.accent, BackgroundTransparency = .86 }):Play() end
    end)
    b.MouseLeave:Connect(function()
        if activePage ~= name then TweenService:Create(b, TweenInfo.new(.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play() end
    end)
end
-- Восстанавливаем последнюю вкладку. selectPage живёт в своей области видимости
-- и сам откатывается на home, если сохранённого имени больше нет в билде.
local __savedPage = NoirPersistence.data.dropdowns["\x4eoir::LastPage"]
if type(__savedPage) ~= "\x73tring" or __savedPage == "" then __savedPage = "\x68ome" end
local __restoreOk = pcall(selectPage, __savedPage)
if not __restoreOk then pcall(selectPage, "\x68ome") end

local sectionCount, mainSectionCount, worldSectionCount, visualSectionCount, emotesSectionCount, miscSectionCount, configSectionCount, trollSectionCount, mapSectionCount, farmSectionCount = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
local sectionPanels, controls = {}, {}
function refreshCanvas()
    if sectionPanels.__canvasQueued then return end
    sectionPanels.__canvasQueued = true
    task.defer(function()
        sectionPanels.__canvasQueued = false
        for _, page in ipairs({ content, configContent, visualContent, mainContent, worldContent, emotesContent, miscContent, settingsContent }) do
            if page and page.Parent then page.CanvasSize = UDim2.fromOffset(0, 0) end
        end
    end)
end
search:GetPropertyChangedSignal("\x54ext"):Connect(function()
    sectionPanels.__searchToken = (sectionPanels.__searchToken or 0) + 1
    local token = sectionPanels.__searchToken
    task.delay(0.12, function()
        if token ~= sectionPanels.__searchToken then return end
        local q = string.lower(search.Text or "")
        local counts = { main = 0, aim = 0, world = 0, visual = 0, emotes = 0, misc = 0, map = 0, farm = 0 }
        local firstPage, firstSub
        for _, entry in ipairs(sectionPanels) do
            local hay = entry.name
            for _, d in ipairs(entry.panel:GetDescendants()) do
                if d:IsA("\x54extLabel") or d:IsA("\x54extButton") then hay = hay .. "\x20" .. string.lower(d.Text or "") end
            end
            local match = q == "" or string.find(hay, q, 1, true) ~= nil
            entry.panel.Visible = match
            if match then
                counts[entry.page] = (counts[entry.page] or 0) + 1
                if q ~= "" and not firstPage then firstPage, firstSub = entry.page, entry.sub end
            end
        end
        if q ~= "" and firstPage then
            if activePage == "\x68ome" or activePage == "\x73kins" or activePage ~= firstPage then
                selectPage(firstPage)
            end
            local shower = NoirGenv().__NoirSubShow and NoirGenv().__NoirSubShow[firstPage]
            if type(shower) == "\x66unction" and firstSub then pcall(shower, firstSub) end
        elseif q == "" then
            local cur = NoirGenv().__NoirSubCurrent and NoirGenv().__NoirSubCurrent[activePage]
            local shower = NoirGenv().__NoirSubShow and NoirGenv().__NoirSubShow[activePage]
            if type(shower) == "\x66unction" and cur then pcall(shower, cur) end
        end
        refreshCanvas()
    end)
end)

local host = {}

local notificationHolder = New("\x46rame", {
    Parent = gui, Name = "\x4eotificationRail", AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -20, 0, 82), Size = UDim2.new(0, 360, 0, 270),
    BackgroundTransparency = 1, ClipsDescendants = false, ZIndex = 1000,
})
local notificationLayout = New("\x55IListLayout", {
    Parent = notificationHolder, Padding = UDim.new(0, 9),
    FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder,
})
local notificationSerial = 0
local activeNotifications = {}
local function trimNotifications()
    while #activeNotifications > 3 do
        local oldest = table.remove(activeNotifications, 1)
        if oldest and oldest.Parent then oldest:Destroy() end
    end
end
function host.Notify(title, duration)
    notificationSerial += 1
    local life = math.max(1.5, tonumber(duration) or 3)
    local card = New("\x46rame", {
        Parent = notificationHolder, Name = "\x54oast_" .. tostring(notificationSerial),
        Size = UDim2.new(1, 0, 0, 76), BackgroundColor3 = C.panel,
        BackgroundTransparency = .04, BorderSizePixel = 0, LayoutOrder = notificationSerial,
        ZIndex = 1000,
    })
    corner(card, 14); stroke(card, C.accent, .18)
    New("\x46rame", { Parent = card, Position = UDim2.fromOffset(0, 13), Size = UDim2.fromOffset(3, 50),
        BackgroundColor3 = C.accent, BorderSizePixel = 0, ZIndex = 1001 })
    local badge = New("\x54extLabel", { Parent = card, Position = UDim2.fromOffset(18, 9), Size = UDim2.new(1, -30, 0, 17),
        BackgroundTransparency = 1, Text = "\x4eOIR  •  NOTIFICATION", TextColor3 = C.accent2,
        TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1001 })
    local message = New("\x54extLabel", { Parent = card, Position = UDim2.fromOffset(18, 29), Size = UDim2.new(1, -30, 0, 30),
        BackgroundTransparency = 1, Text = tostring(title), TextColor3 = C.text,
        TextSize = 14, Font = Enum.Font.Gotham, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 1001 })
    local progress = New("\x46rame", { Parent = card, Position = UDim2.fromOffset(18, 69), Size = UDim2.new(1, -30, 0, 2),
        BackgroundColor3 = C.accent, BorderSizePixel = 0, ZIndex = 1001 })
    table.insert(activeNotifications, card); trimNotifications()
    TweenService:Create(progress, TweenInfo.new(life, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
    task.delay(life, function()
        for i = #activeNotifications, 1, -1 do
            if activeNotifications[i] == card then table.remove(activeNotifications, i) break end
        end
        if card.Parent then
            local out = TweenService:Create(card, TweenInfo.new(.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 24, 0, 0), BackgroundTransparency = 1,
            })
            out:Play(); out.Completed:Connect(function() if card.Parent then card:Destroy() end end)
        end
    end)
end
function host.CreateTab()
    local buildOps = 0
    local function yieldDuringBuild()
        buildOps += 1
        if buildOps % 16 ~= 0 then return end
        local waitFn = type(task) == "table" and task.wait or nil
        if type(waitFn) == "function" then waitFn()
        elseif type(wait) == "function" then wait() end
    end
    local tab = {}
    function tab:AddSection(name, description)
        yieldDuringBuild()
        local isVisual = name == "\x56isuals" or name == "\x4fbject ESP" or string.find(name, "\x56ISUAL", 1, true) == 1
        local isMain = string.sub(name, 1, 5) == "\x4dAIN "
        local function hasTag(p) return string.find(name, p, 1, true) ~= nil end
        local isFling = hasTag("\x46ling") or hasTag("⚡") or hasTag("🤖") or hasTag("📋") or hasTag("⚙") or hasTag("🔘") or hasTag("🔑")
        local isWorld = string.sub(name, 1, 6) == "\x57ORLD " or name == "\x42omb Jump+" or name == "\x47old Bomb Jump+" or isFling
        local isEmotes = string.sub(name, 1, 7) == "\x45MOTES " or name == "\x46E Animations" or name == "\x41bout"
        local isGameEmotes = isEmotes and string.find(name, "\x47AME EMOTES", 1, true) ~= nil
        local isMisc = string.sub(name, 1, 5) == "\x4dISC " or name == "\x49nventory Unlimiter V5" or name == "\x50m-WallHop"
        local isTroll = string.sub(name, 1, 6) == "\x54ROLL " or name == "\x42ackshots"
        local isMap = string.sub(name, 1, 4) == "\x4dAP "
        local isFarm = string.sub(name, 1, 5) == "\x46ARM "
        local col, page = nil, "\x61im"
        if isVisual then visualSectionCount += 1; col = visualCols[(visualSectionCount - 1) % 2 + 1]; page = "\x76isual"
        elseif isMain then mainSectionCount += 1; col = mainCols[(mainSectionCount - 1) % 2 + 1]; page = "\x6dain"
        elseif isWorld then worldSectionCount += 1; col = worldCols[(worldSectionCount - 1) % 2 + 1]; page = "\x77orld"
        elseif isGameEmotes then col = emotesGameCol or emotesCols[1]; page = "\x65motes"
        elseif isEmotes then emotesSectionCount += 1; col = emotesCols[(emotesSectionCount - 1) % 2 + 1]; page = "\x65motes"
        elseif isMisc then miscSectionCount += 1; col = miscCols[(miscSectionCount - 1) % 2 + 1]; page = "\x6disc"
        elseif isTroll then trollSectionCount += 1; col = trollCols[(trollSectionCount - 1) % 2 + 1]; page = "\x74roll"
        elseif isMap then mapSectionCount += 1; col = mapCols[(mapSectionCount - 1) % 2 + 1]; page = "\x6dap"
        elseif isFarm then farmSectionCount += 1; col = farmCols[(farmSectionCount - 1) % 2 + 1]; page = "\x66arm"
        if not col then
            sectionCount += 1
            col = cols[(sectionCount - 1) % 2 + 1]
            page = "\x61im"
            warn("[Noir] section panel fallback: " .. tostring(name))
        end
        else sectionCount += 1; col = cols[(sectionCount - 1) % 2 + 1] end
        local panel = New("\x46rame", { Parent = col, Size = UDim2.new(1, 0, 0, 90), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = C.panel, BackgroundTransparency = .86, ClipsDescendants = true })
        corner(panel, 10); stroke(panel, C.border, .15)
        local tick = New("\x46rame", { Parent = panel, Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.border, BorderSizePixel = 0 })
        table.insert(sectionPanels, { panel = panel, page = page, name = string.lower(name .. "\x20" .. (description or "")) })
        local shownName = name:gsub("\x5eMAIN • ", ""):gsub("\x5eWORLD • ", ""):gsub("\x5eVISUAL • ", ""):gsub("\x5eEMOTES • ", ""):gsub("\x5eMISC • ", ""):gsub("\x5eTROLL • ", ""):gsub("\x5eMAP • ", ""):gsub("\x5eFARM • ", "")
        kitiTitle(panel, shownName)
        if description and description ~= "" then kitiDesc(panel, description) end
        local holder = New("\x46rame", { Parent = panel, Position = UDim2.fromOffset(10, description ~= "" and 48 or 38), Size = UDim2.new(1, -20, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
        New("\x55IListLayout", { Parent = holder, Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder })
        New("\x55IPadding", { Parent = holder, PaddingBottom = UDim.new(0, 12) })
        holder:GetPropertyChangedSignal("\x41bsoluteSize"):Connect(refreshCanvas); refreshCanvas()
        local api = { Name = name }
        local storagePrefix = name .. "\x3a:"
        -- при повторяющихся подписях внутри секции ключи не должны слипаться
        local usedStorageKeys = {}
        local function keyFor(label)
            local base = storagePrefix .. tostring(label)
            local n = (usedStorageKeys[base] or 0) + 1
            usedStorageKeys[base] = n
            if n == 1 then return base end
            return base .. "#" .. n
        end
        local function row(label, h)
            yieldDuringBuild()
            local r = New("\x46rame", { Parent = holder, Size = UDim2.new(1, 0, 0, h or 20), BackgroundTransparency = 1 })
            local rowLabel = text(r, label, 14, UDim2.fromOffset(0, 0))
            rowLabel.TextTransparency = .1
            rowLabel.Size = UDim2.new(1, -160, 0, h or 20)
            rowLabel.TextYAlignment = Enum.TextYAlignment.Center
            local hover = NoirFX.new(0, 20, 1, function(v)
                local c = math.clamp(v, 0, 1)
                rowLabel.TextTransparency = .1 - .1 * c
                rowLabel.Position = UDim2.fromOffset(3 * c, 0)
            end)
            r.MouseEnter:Connect(function() hover:Set(1) end)
            r.MouseLeave:Connect(function() hover:Set(0) end)
            return r
        end
        function api:AddToggle(label, callback)
            local key = keyFor(label)
            local savedToggle = NoirPersistence.data.toggles[key]
            if savedToggle == nil and NoirPersistence.safeLegacy[label] then
                savedToggle = NoirPersistence.data.toggles[label]
                if savedToggle ~= nil then NoirPersistence.data.toggles[key] = savedToggle; NoirPersistence.Save() end
            end
            local state = savedToggle == true
            local r = row(label, 20)
            local pill = New("\x54extButton", { Parent = r, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 2), Size = UDim2.fromOffset(30, 16),
                BackgroundColor3 = C.off, Text = "", AutoButtonColor = false })
            corner(pill, 8); local pillStroke = stroke(pill, C.border, 0)
            local dot = New("\x46rame", { Parent = pill, AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 2, .5, 0), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = C.text })
            corner(dot, 6)
            local togSpring = NoirFX.new(state and 1 or 0, 24, .62, function(t)
                local c = math.clamp(t, 0, 1)
                local stretch = math.sin(c * math.pi) * 6
                dot.Position = UDim2.new(0, 2 + t * 14 - stretch * c, .5, 0)
                dot.Size = UDim2.fromOffset(12 + stretch, 12)
                pill.BackgroundColor3 = C.off:Lerp(C.accent, c)
                pillStroke.Color = C.border:Lerp(C.accent2, c)
                dot.BackgroundColor3 = C.text:Lerp(Color3.new(0, 0, 0), c)
            end)
            local function set(v, persist, animate)
                state = v == true
                if animate == false then togSpring:Snap(state and 1 or 0) else togSpring:Set(state and 1 or 0) end
                callback(state)
                if persist ~= false then NoirPersistence.data.toggles[key] = state; NoirPersistence.Save() end
            end
            local lastClick = 0
            local function toggleClick()
                local now = os.clock()
                if now - lastClick < .18 then return end
                lastClick = now
                set(not state, true)
            end
            pill.Activated:Connect(toggleClick)
            set(state, false, false)
            return function(v) set(v == nil and not state or v, true) end
        end
        function api:AddButton(label, callback)
            yieldDuringBuild()
            local b = New("\x54extButton", { Parent = holder, Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = C.btn,
                BackgroundTransparency = .72, Text = NoirTr(label), TextColor3 = C.text, TextSize = 13, Font = Enum.Font.Gotham, AutoButtonColor = false })
            corner(b, 8); ringStroke(b, 1.2, .55)
            b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(.18), { BackgroundTransparency = .58, BackgroundColor3 = Color3.fromRGB(48,52,56) }):Play() end)
            b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(.18), { BackgroundTransparency = .72, BackgroundColor3 = C.btn }):Play() end)
            local lastClick = 0
            local function fire()
                local now = os.clock()
                if now - lastClick < .18 then return end
                lastClick = now
                callback()
            end
            b.Activated:Connect(fire)
            return b
        end
        function api:AddSlider(label, min, max, default, callback)
            local key = keyFor(label)
            local savedSlider = NoirPersistence.data.sliders[key]
            if savedSlider == nil then
                savedSlider = NoirPersistence.data.sliders[label]
                if savedSlider ~= nil then NoirPersistence.data.sliders[key] = savedSlider; NoirPersistence.Save() end
            end
            default = tonumber(savedSlider) or default
            local r = row(label, 30)
            local value = New("\x54extBox", { Parent = r, Position = UDim2.new(1, -56, 0, 0), Size = UDim2.fromOffset(56, 18), BackgroundColor3 = C.surface,
                BackgroundTransparency = 1, Text = tostring(default), TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Right, ClearTextOnFocus = false })
            local track = New("\x46rame", { Parent = r, Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = C.off })
            corner(track, 1)
            local fill = New("\x46rame", { Parent = track, Size = UDim2.fromScale((default - min) / (max - min), 1), BackgroundColor3 = C.accent, BorderSizePixel = 0 })
            corner(fill, 1)
            local knob = New("\x46rame", { Parent = track, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new((default - min) / (max - min), 0, .5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = C.accent })
            knob.Size = UDim2.fromOffset(15, 15); corner(knob, 8); stroke(knob, C.border, .3)
            do
                local function glow(parent)
                    New("ImageLabel", { Parent = parent, BackgroundTransparency = 1, Image = "rbxassetid://112971167999062", ImageColor3 = C.accent, ImageTransparency = .68,
                        AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.new(1, 15, 1, 15), ScaleType = Enum.ScaleType.Slice,
                        SliceCenter = Rect.new(Vector2.new(112, 112), Vector2.new(147, 147)), SliceScale = .6, ZIndex = 2 })
                end
                glow(fill); glow(knob)
            end
            local current = default
            local halo = New("UIStroke", { Parent = knob, Color = C.accent2, Thickness = 4, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
            local alphaSpring = NoirFX.new((default - min) / (max - min), 24, .78, function(a)
                local c = math.clamp(a, 0, 1)
                fill.Size = UDim2.fromScale(c, 1)
                knob.Position = UDim2.new(c, 0, .5, 0)
            end)
            local grabSpring = NoirFX.new(0, 26, .8, function(g)
                local c = math.clamp(g, 0, 1)
                local size = 15 + 5 * g
                knob.Size = UDim2.fromOffset(size, size)
                halo.Transparency = 1 - .7 * c
                value.TextSize = 14 + 2 * c
            end)
            local function set(v, persist)
                current = math.clamp(math.floor((tonumber(v) or current or default) + .5), min, max)
                alphaSpring:Set((current - min) / (max - min))
                value.Text = tostring(current)
                callback(current)
                if persist ~= false then NoirPersistence.data.sliders[key] = current; NoirPersistence.Save() end
            end
            set(default, false)
            alphaSpring:Snap((current - min) / (max - min))
            value.FocusLost:Connect(function() set(value.Text) end)
            local drag = false
            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
                    drag = true; grabSpring:Set(1); set(min + (max - min) * math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if drag and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
                    set(min + (max - min) * math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false; grabSpring:Set(0) end
            end)
            return { SetValue = function(_, v, persist) set(v, persist) end, GetValue = function() return current end }
        end
        function api:AddDropdown(label, values, callback)
            local key = keyFor(label)
            local r = row(label, 46)
            local rowText = r:FindFirstChildWhichIsA("TextLabel")
            if rowText then rowText.Size = UDim2.new(1, 0, 0, 18); rowText.TextYAlignment = Enum.TextYAlignment.Top end
            local idx = table.find(values, NoirPersistence.data.dropdowns[key]) or 1
            local b = New("TextButton", { Parent = r, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 24),
                BackgroundColor3 = C.surface, Text = "", AutoButtonColor = false, ZIndex = 4 })
            corner(b, 10)
            local bStroke = stroke(b, C.border, 0)
            local valueLabel = New("TextLabel", { Parent = b, Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -32, 1, 0), BackgroundTransparency = 1,
                Text = tostring(values[idx] or "None"), TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 5 })
            local arrow = New("TextLabel", { Parent = b, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -8, .5, 0), Size = UDim2.fromOffset(12, 12),
                BackgroundTransparency = 1, Text = "⌄", TextColor3 = C.dim, TextSize = 14, Font = Enum.Font.GothamBold, ZIndex = 5 })
            local quart = TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            b.MouseEnter:Connect(function() TweenService:Create(b, quart, { BackgroundColor3 = Color3.fromRGB(22, 19, 16) }):Play() end)
            b.MouseLeave:Connect(function() TweenService:Create(b, quart, { BackgroundColor3 = C.surface }):Play() end)
            local popup
            local function close()
                if popup then popup:Destroy(); popup = nil end
                TweenService:Create(arrow, quart, { Rotation = 0 }):Play()
                TweenService:Create(bStroke, quart, { Color = C.border }):Play()
            end
            local function set(v, silent)
                local found = table.find(values, v)
                if found then idx = found end
                valueLabel.Text = tostring(values[idx] or "None")
                if values[idx] ~= nil then
                    callback(values[idx])
                    if not silent then
                        NoirPersistence.data.dropdowns[key] = values[idx]
                        NoirPersistence.Save()
                    end
                end
            end
            local function open()
                close()
                local rowH = 30
                local fullH = math.min(#values * rowH + 8, 200)
                local w = b.AbsoluteSize.X / scale.Scale
                popup = New("ScrollingFrame", { Parent = gui, Position = UDim2.fromOffset(b.AbsolutePosition.X / scale.Scale, (b.AbsolutePosition.Y + b.AbsoluteSize.Y + 4) / scale.Scale),
                    Size = UDim2.fromOffset(w, 0), CanvasSize = UDim2.fromOffset(0, #values * rowH + 8), BackgroundColor3 = C.surface, BorderSizePixel = 0,
                    ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent, ClipsDescendants = true, ZIndex = 50 })
                corner(popup, 10); stroke(popup, C.accent, .35)
                New("UIPadding", { Parent = popup, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) })
                New("UIListLayout", { Parent = popup, SortOrder = Enum.SortOrder.LayoutOrder })
                for i, v in ipairs(values) do
                    local selected = i == idx
                    local item = New("TextButton", { Parent = popup, LayoutOrder = i, Size = UDim2.new(1, 0, 0, rowH), BackgroundColor3 = C.accent,
                        BackgroundTransparency = selected and .86 or 1, Text = tostring(v), TextColor3 = selected and C.accent2 or C.text, TextSize = 14,
                        Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, ZIndex = 51 })
                    corner(item, 8)
                    New("UIPadding", { Parent = item, PaddingLeft = UDim.new(0, 8) })
                    item.MouseEnter:Connect(function() if not selected then TweenService:Create(item, TweenInfo.new(.12), { BackgroundTransparency = .92 }):Play() end end)
                    item.MouseLeave:Connect(function() if not selected then TweenService:Create(item, TweenInfo.new(.12), { BackgroundTransparency = 1 }):Play() end end)
                    item.Activated:Connect(function() set(v); close() end)
                end
                TweenService:Create(popup, quart, { Size = UDim2.fromOffset(w, fullH) }):Play()
                TweenService:Create(arrow, quart, { Rotation = 180 }):Play()
                TweenService:Create(bStroke, quart, { Color = C.accent }):Play()
            end
            local lastOpen = 0
            local function togglePopup()
                local now = os.clock()
                if now - lastOpen < .18 then return end
                lastOpen = now
                if popup then close() else open() end
            end
            b.Activated:Connect(togglePopup)
            if NoirPersistence.data.dropdowns[key] ~= nil and values[idx] ~= nil then
                pcall(callback, values[idx])
            end
            local ctl = {}
            function ctl:SetValue(v) set(v) end
            function ctl:Select(v) set(v) end
            function ctl:Refresh(newValues, selected) values = newValues or {}; idx = 1; set(selected or values[1], true) end
            function ctl:ChangeItems(newValues) values = newValues or {}; idx = 1; set(values[1], true) end
            return ctl
        end
        function api:AddTextBox(label, callback)
            local key = keyFor(label)
            local r = row(label, 24)
            local savedText = NoirPersistence.data.textboxes[key]
            local box = New("\x54extBox", { Parent = r, Position = UDim2.new(1, -180, 0, 2), Size = UDim2.fromOffset(180, 20), BackgroundColor3 = C.surface,
                Text = type(savedText) == "\x73tring" and savedText or "", PlaceholderText = NoirTr(label), TextColor3 = C.text, PlaceholderColor3 = C.dim, TextSize = 14, Font = Enum.Font.Gotham, ClearTextOnFocus = false })
            corner(box, 4); stroke(box, C.border, 0)
            if type(savedText) == "\x73tring" and savedText ~= "" then
                pcall(callback, savedText)
            end
            box.FocusLost:Connect(function()
                NoirPersistence.data.textboxes[key] = box.Text
                NoirPersistence.Save()
                callback(box.Text)
            end)
            return { SetValue = function(_, v) box.Text = tostring(v); NoirPersistence.data.textboxes[key] = box.Text; NoirPersistence.Save() end }
        end
        function api:AddLabel(label)
            local r = row(label, 18)
            local labelObject = r:FindFirstChildWhichIsA("\x54extLabel")
            return { SetValue = function(_, value) if labelObject and labelObject.Parent then labelObject.Text = tostring(value) end end,
                GetValue = function() return labelObject and labelObject.Text or "" end,
                Instance = r }
        end
        function api:AddParagraph(title, body)
            local r = row(tostring(title or ""), 68)
            if body and tostring(body) ~= "" then
                local detail = text(r, tostring(body), 12, UDim2.fromOffset(0, 32), true)
                detail.TextWrapped = true
                detail.Size = UDim2.new(1, 0, 0, 30)
            end
            return r
        end
        function api:AddColorpicker(label, default, callback)
            local key = keyFor(label)
            local r = row(label, 18)
            local colorKey = key
            local colour = default or C.accent
            local savedColor = NoirPersistence.data.colors[colorKey]
            if typeof(savedColor) == "\x74able" then
                local red, green, blue = tonumber(savedColor[1]), tonumber(savedColor[2]), tonumber(savedColor[3])
                if red and green and blue then colour = Color3.new(math.clamp(red, 0, 1), math.clamp(green, 0, 1), math.clamp(blue, 0, 1)) end
            end
            local swatch = New("\x54extButton", { Parent = r, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 2), Size = UDim2.fromOffset(24, 14),
                BackgroundColor3 = colour, Text = "", TextColor3 = C.text, TextSize = 11, Font = Enum.Font.GothamBold, AutoButtonColor = false })
            corner(swatch, 4); stroke(swatch, C.border, 0)
            local popup, inputChanged, inputEnded, colorDirty = nil, nil, nil, false
            local function storeColor()
                NoirPersistence.data.colors[colorKey] = { colour.R, colour.G, colour.B }
            end
            local function commitColor()
                if colorDirty then colorDirty = false; NoirPersistence.Save() end
            end
            local function setColor(value, mode)
                if typeof(value) ~= "\x43olor3" then return end
                colour = value
                swatch.BackgroundColor3 = colour
                if callback then callback(colour) end
                if mode == "\x64efer" then
                    storeColor(); colorDirty = true
                elseif mode == true then
                    storeColor(); NoirPersistence.Save()
                end
            end
            local function closePicker()
                commitColor()
                if inputChanged then inputChanged:Disconnect(); inputChanged = nil end
                if inputEnded then inputEnded:Disconnect(); inputEnded = nil end
                if popup then popup:Destroy(); popup = nil end
            end
            local function openPicker()
                closePicker()
                local hue, saturation, value = colour:ToHSV()
                popup = New("\x46rame", { Parent = gui, Name = "\x4eoirColorPicker", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
                    BackgroundTransparency = .42, BorderSizePixel = 0, Active = true, ZIndex = 70 })
                local dialog = New("\x46rame", { Parent = popup, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(640, 450),
                    BackgroundColor3 = C.panel, BorderSizePixel = 0, Active = true, ZIndex = 71 })
                corner(dialog, 18); stroke(dialog, C.border, .18)
                New("\x54extLabel", { Parent = dialog, Position = UDim2.fromOffset(22, 17), Size = UDim2.fromOffset(250, 27), BackgroundTransparency = 1,
                    Text = label, TextColor3 = C.text, TextSize = 20, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 72 })
                New("\x54extLabel", { Parent = dialog, Position = UDim2.fromOffset(22, 43), Size = UDim2.fromOffset(370, 17), BackgroundTransparency = 1,
                    Text = "\x43hoose with the color box, HEX, or RGB values", TextColor3 = C.dim, TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 72 })
                local closeButton = New("\x54extButton", { Parent = dialog, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -17, 0, 15), Size = UDim2.fromOffset(38, 34),
                    BackgroundColor3 = C.surface, Text = "×", TextColor3 = C.text, TextSize = 24, Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 73 })
                corner(closeButton, 10); stroke(closeButton, C.border, .45)
                local currentCard = New("\x46rame", { Parent = dialog, Position = UDim2.fromOffset(20, 80), Size = UDim2.fromOffset(220, 346), BackgroundColor3 = C.surface, BorderSizePixel = 0, ZIndex = 72 })
                corner(currentCard, 14); stroke(currentCard, C.border, .35)
                New("\x54extLabel", { Parent = currentCard, Position = UDim2.fromOffset(17, 16), Size = UDim2.fromOffset(170, 22), BackgroundTransparency = 1,
                    Text = "\x43URRENT COLOR", TextColor3 = C.text, TextSize = 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 73 })
                local preview = New("\x46rame", { Parent = currentCard, Position = UDim2.fromOffset(17, 49), Size = UDim2.fromOffset(186, 204), BackgroundColor3 = colour, BorderSizePixel = 0, ZIndex = 73 })
                corner(preview, 11); stroke(preview, C.border, .2)
                local previewHex = New("\x54extLabel", { Parent = preview, AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -14), Size = UDim2.fromOffset(118, 32),
                    BackgroundColor3 = Color3.fromRGB(24, 26, 30), BackgroundTransparency = .15, Text = "", TextColor3 = C.text, TextSize = 12, Font = Enum.Font.GothamBold, ZIndex = 74 })
                corner(previewHex, 8)
                New("\x54extLabel", { Parent = currentCard, Position = UDim2.fromOffset(17, 273), Size = UDim2.fromOffset(186, 18), BackgroundTransparency = 1,
                    Text = "\x4cIVE PREVIEW", TextColor3 = C.dim, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 73 })
                New("\x54extLabel", { Parent = currentCard, Position = UDim2.fromOffset(17, 298), Size = UDim2.fromOffset(186, 27), BackgroundTransparency = 1,
                    Text = "\x54he Shift Lock cursor updates instantly.", TextColor3 = C.dim, TextSize = 12, Font = Enum.Font.Gotham, TextWrapped = true, ZIndex = 73 })
                local valueCard = New("\x46rame", { Parent = dialog, Position = UDim2.fromOffset(258, 80), Size = UDim2.fromOffset(362, 346), BackgroundColor3 = C.surface, BorderSizePixel = 0, ZIndex = 72 })
                corner(valueCard, 14); stroke(valueCard, C.border, .35)
                New("\x54extLabel", { Parent = valueCard, Position = UDim2.fromOffset(17, 15), Size = UDim2.fromOffset(180, 22), BackgroundTransparency = 1,
                    Text = "\x43OLOR VALUE", TextColor3 = C.text, TextSize = 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 73 })
                local hueReadout = New("\x54extLabel", { Parent = valueCard, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -17, 0, 16), Size = UDim2.fromOffset(82, 20), BackgroundTransparency = 1,
                    Text = "\x48ue 0°", TextColor3 = C.dim, TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 73 })
                local spectrum = New("\x46rame", { Parent = valueCard, Position = UDim2.fromOffset(17, 48), Size = UDim2.fromOffset(328, 160),
                    BackgroundColor3 = Color3.fromHSV(hue, 1, 1), BorderSizePixel = 0, Active = true, ZIndex = 73 })
                corner(spectrum, 10); stroke(spectrum, C.border, .25)
                local whiteBlend = New("\x46rame", { Parent = spectrum, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 74 })
                corner(whiteBlend, 10)
                New("\x55IGradient", { Parent = whiteBlend, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) })
                local darkBlend = New("\x46rame", { Parent = spectrum, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 75 })
                corner(darkBlend, 10)
                New("\x55IGradient", { Parent = darkBlend, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) })
                local spectrumKnob = New("\x46rame", { Parent = spectrum, AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(17, 17), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 76 })
                corner(spectrumKnob, 9); New("\x55IStroke", { Parent = spectrumKnob, Color = C.text, Thickness = 2 })
                 
                local hueBar = New("\x46rame", { Parent = valueCard, Position = UDim2.fromOffset(17, 223), Size = UDim2.fromOffset(328, 16), BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, ZIndex = 73 })
                local rainbowTrack = New("\x46rame", { Parent = hueBar, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 73 })
                corner(rainbowTrack, 8); stroke(rainbowTrack, C.border, .25)
                local rainbow = {
                    Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 72, 0), Color3.fromRGB(255, 150, 0), Color3.fromRGB(255, 225, 0),
                    Color3.fromRGB(170, 255, 0), Color3.fromRGB(65, 255, 0), Color3.fromRGB(0, 255, 90), Color3.fromRGB(0, 255, 180),
                    Color3.fromRGB(0, 235, 255), Color3.fromRGB(0, 155, 255), Color3.fromRGB(0, 65, 255), Color3.fromRGB(75, 0, 255),
                    Color3.fromRGB(150, 0, 255), Color3.fromRGB(220, 0, 255), Color3.fromRGB(255, 0, 190), Color3.fromRGB(255, 0, 105),
                    Color3.fromRGB(255, 0, 42), Color3.fromRGB(255, 0, 0),
                }
                for index, rainbowColor in ipairs(rainbow) do
                    New("\x46rame", { Parent = rainbowTrack, Position = UDim2.new((index - 1) / #rainbow, 0, 0, 0), Size = UDim2.new(1 / #rainbow, 0, 1, 0),
                        BackgroundColor3 = rainbowColor, BorderSizePixel = 0, ZIndex = 74 })
                end
                local hueKnob = New("\x46rame", { Parent = hueBar, AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(11, 24), BackgroundColor3 = C.text, BorderSizePixel = 0, ZIndex = 76 })
                corner(hueKnob, 5); New("\x55IStroke", { Parent = hueKnob, Color = Color3.new(0, 0, 0), Thickness = 1 })
                New("\x54extLabel", { Parent = valueCard, Position = UDim2.fromOffset(17, 252), Size = UDim2.fromOffset(44, 16), BackgroundTransparency = 1, Text = "\x48EX", TextColor3 = C.dim, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 73 })
                local hexInput = New("\x54extBox", { Parent = valueCard, Position = UDim2.fromOffset(64, 246), Size = UDim2.fromOffset(281, 30), BackgroundColor3 = C.card, Text = "", PlaceholderText = "\x23FFFFFF", TextColor3 = C.text, TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false, ZIndex = 73 })
                corner(hexInput, 8); stroke(hexInput, C.border, .4)
                New("\x54extLabel", { Parent = valueCard, Position = UDim2.fromOffset(17, 287), Size = UDim2.fromOffset(120, 15), BackgroundTransparency = 1, Text = "\x52GB", TextColor3 = C.dim, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 73 })
                local channelInputs = {}
                local channelLabels = { "\x52", "\x47", "\x42" }
                local channelColors = { Color3.fromRGB(239, 72, 72), Color3.fromRGB(82, 204, 112), Color3.fromRGB(84, 150, 255) }
                for index = 1, 3 do
                    local x = 17 + (index - 1) * 110
                    New("\x54extLabel", { Parent = valueCard, Position = UDim2.fromOffset(x, 309), Size = UDim2.fromOffset(18, 22), BackgroundTransparency = 1, Text = channelLabels[index], TextColor3 = channelColors[index], TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 73 })
                    local field = New("\x54extBox", { Parent = valueCard, Position = UDim2.fromOffset(x + 22, 303), Size = UDim2.fromOffset(86, 32), BackgroundColor3 = C.card, Text = "\x30", PlaceholderText = "\x30", TextColor3 = C.text, TextSize = 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false, ZIndex = 73 })
                    corner(field, 8); stroke(field, channelColors[index], .5)
                    channelInputs[index] = field
                end
                local function setHSV(nextHue, nextSaturation, nextValue, mode)
                    hue = math.clamp(nextHue, 0, 1)
                    saturation = math.clamp(nextSaturation, 0, 1)
                    value = math.clamp(nextValue, 0, 1)
                    local selected = Color3.fromHSV(hue, saturation, value)
                    spectrum.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                    spectrumKnob.Position = UDim2.fromScale(saturation, 1 - value)
                    hueKnob.Position = UDim2.fromScale(hue, .5)
                    preview.BackgroundColor3 = selected
                    local hex = string.format("\x23%02X%02X%02X", math.floor(selected.R * 255 + .5), math.floor(selected.G * 255 + .5), math.floor(selected.B * 255 + .5))
                    previewHex.Text = hex .. "\x20 •  100%"
                    hexInput.Text = hex
                    channelInputs[1].Text = tostring(math.floor(selected.R * 255 + .5))
                    channelInputs[2].Text = tostring(math.floor(selected.G * 255 + .5))
                    channelInputs[3].Text = tostring(math.floor(selected.B * 255 + .5))
                    hueReadout.Text = "\x48ue " .. tostring(math.floor(hue * 360 + .5)) .. "°"
                    setColor(selected, mode)
                end
                local function setRGB(red, green, blue, mode)
                    local selected = Color3.fromRGB(math.clamp(math.floor((tonumber(red) or 0) + .5), 0, 255), math.clamp(math.floor((tonumber(green) or 0) + .5), 0, 255), math.clamp(math.floor((tonumber(blue) or 0) + .5), 0, 255))
                    local nextHue, nextSaturation, nextValue = selected:ToHSV()
                    setHSV(nextHue, nextSaturation, nextValue, mode)
                end
                local function updateSpectrum(position)
                    local size, origin = spectrum.AbsoluteSize, spectrum.AbsolutePosition
                    setHSV(hue, math.clamp((position.X - origin.X) / math.max(1, size.X), 0, 1), 1 - math.clamp((position.Y - origin.Y) / math.max(1, size.Y), 0, 1), "\x64efer")
                end
                local function updateHue(position)
                    local size, origin = hueBar.AbsoluteSize, hueBar.AbsolutePosition
                    setHSV(math.clamp((position.X - origin.X) / math.max(1, size.X), 0, 1), saturation, value, "\x64efer")
                end
                local dragMode = nil
                spectrum.InputBegan:Connect(function(input) if isPrimaryPress(input) then dragMode = "\x73pectrum"; updateSpectrum(input.Position) end end)
                hueBar.InputBegan:Connect(function(input) if isPrimaryPress(input) then dragMode = "\x68ue"; updateHue(input.Position) end end)
                hexInput.FocusLost:Connect(function()
                    local raw = tostring(hexInput.Text or ""):gsub("\x25s", ""):gsub("\x23", "")
                    local redHex, greenHex, blueHex = raw:match("\x5e(%x%x)(%x%x)(%x%x)$")
                    if redHex and greenHex and blueHex then setRGB(tonumber(redHex, 16), tonumber(greenHex, 16), tonumber(blueHex, 16), true) else setHSV(hue, saturation, value, false) end
                end)
                for _, field in ipairs(channelInputs) do
                    field.FocusLost:Connect(function()
                        setRGB(tonumber(channelInputs[1].Text) or math.floor(colour.R * 255 + .5), tonumber(channelInputs[2].Text) or math.floor(colour.G * 255 + .5), tonumber(channelInputs[3].Text) or math.floor(colour.B * 255 + .5), true)
                    end)
                end
                inputChanged = UIS.InputChanged:Connect(function(input)
                    if dragMode and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                        if dragMode == "\x73pectrum" then updateSpectrum(input.Position) else updateHue(input.Position) end
                    end
                end)
                inputEnded = UIS.InputEnded:Connect(function(input)
                    if isPrimaryPress(input) then dragMode = nil; commitColor() end
                end)
                closeButton.Activated:Connect(closePicker)
                setHSV(hue, saturation, value, false)
            end
            swatch.Activated:Connect(openPicker)
            setColor(colour, false)
            return { SetRGBValue = function(_, value) setColor(value, true) end, GetValue = function() return colour end }
        end
        function api:AddKeybind(label, default, callback)
            local key = keyFor(label)
            local savedKey = NoirPersistence.data.keybinds[key] or default
            local r = row(label, 20)
            local btn = New("\x54extButton", { Parent = r, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 1), Size = UDim2.fromOffset(44, 18),
                BackgroundColor3 = C.surface, Text = tostring(savedKey), TextColor3 = C.text, TextSize = 12, Font = Enum.Font.Gotham, AutoButtonColor = false })
            corner(btn, 4); stroke(btn, C.border, 0)
            local listening, currentKey, conn = false, savedKey, nil
            if NoirPersistence.data.keybinds[key] ~= nil and currentKey ~= nil then
                pcall(callback, currentKey)
            end
            btn.MouseButton1Click:Connect(function()
                listening = true; btn.Text = "\x50ress a key..."
                if conn then conn:Disconnect() end
                conn = UIS.InputBegan:Connect(function(input)
                    if not listening then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode.Name; btn.Text = currentKey; listening = false
                        NoirPersistence.data.keybinds[key] = currentKey; NoirPersistence.Save()
                        callback(currentKey); conn:Disconnect()
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        currentKey = "\x4douseButton1"; btn.Text = currentKey; listening = false
                        NoirPersistence.data.keybinds[key] = currentKey; NoirPersistence.Save()
                        callback(currentKey); conn:Disconnect()
                    end
                end)
            end)
            return { SetValue = function(_, v) currentKey = v; btn.Text = tostring(v) end, GetValue = function() return currentKey end }
        end
        return api
    end
    return tab
end

-- ════════════════════════ демо-наполнение (замени своим) ════════════════════════
-- Разделы раскладываются по страницам по префиксу названия:
--   "MAIN • ", "VISUAL • ", "WORLD • ", "MAP • ", "FARM • ", "MISC • ", "TROLL • ", "EMOTES • ", без префикса — страница Page A.
local demoTab = host.CreateTab()
local function demoSection(title, description)
    local s = demoTab:AddSection(title, description)
    s:AddToggle("Переключатель", function(v) end)
    s:AddSlider("Ползунок", 0, 100, 40, function(v) end)
    s:AddDropdown("Выпадающий список", { "Один", "Два", "Три", "Четыре" }, function(v) end)
    return s
end
do
    local s = demoSection("MAIN • Все элементы", "Пример каждого типа элемента")
    s:AddButton("Кнопка", function() host.Notify("Кнопка нажата", 2) end)
    s:AddTextBox("Текстовое поле", function(v) end)
    s:AddKeybind("Клавиша", "None", function(k) end)
    s:AddColorpicker("Цвет", Color3.fromRGB(255, 255, 255), function(c) end)
    s:AddLabel("Подпись")
    s:AddParagraph("Абзац", "Здесь только интерфейс: вешай свои действия в callback каждого элемента.")
end
demoSection("MAIN • Второй раздел", "Разделы идут в две колонки")
demoSection("VISUAL • Пример", "Страница Visuals")
demoSection("WORLD • Пример", "Страница Page B")
demoSection("MAP • Пример", "Страница Page C")
demoSection("FARM • Пример", "Страница Page D")
demoSection("MISC • Пример", "Страница Misc")
demoSection("TROLL • Пример", "Страница Page G")
demoSection("EMOTES • Пример", "Страница Page F")
demoSection("Раздел без префикса", "Страница Page A")

-- живые данные на главной (FPS, пинг, число игроков)
do
    local acc, frames = 0, 0
    RunService.Heartbeat:Connect(function(dt)
        if not gui.Parent then return end
        acc += dt; frames += 1
        if acc >= .5 then
            fpsText.Text = tostring(math.floor(frames / acc + .5))
            local ok, ping = pcall(function() return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            pingText.Text = (ok and tostring(ping) or "--") .. " ms"
            playerText.Text = tostring(#Players:GetPlayers())
            acc, frames = 0, 0
        end
    end)
end

-- открытие окна (пружинная анимация)
refreshCanvas()
task.defer(function()
    RunService.RenderStepped:Wait()
    if not win.Parent then return end
    local targetPosition = win.Position
    win.Position = targetPosition + UDim2.fromOffset(0, 10)
    win.BackgroundTransparency = 1
    win.Rotation = 0
    winScale.Scale = .965
    win.Visible = true
    TweenService:Create(win, TweenInfo.new(.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = targetPosition, BackgroundTransparency = .45, Rotation = 0 }):Play()
    TweenService:Create(winScale, TweenInfo.new(.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    local tint = win:FindFirstChild("NoirTint")
    if tint then
        tint.BackgroundTransparency = 1
        TweenService:Create(tint, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
    end
end)

end
__noirW1b()
end
__noirW1a()
