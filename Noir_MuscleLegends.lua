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

 
local function __noirSharedEnvironment()
    local ok, environment = pcall(function()
        if type(getgenv) == "\x66unction" then return NoirGenv() end
    end)
    if ok and type(environment) == "\x74able" then return environment end
    return _G
end
local __NOIR_SHARED = __noirSharedEnvironment()
local __NOIR_GUARD_KEY = "\x5f_NoirHubRuntimeLock"
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

local STORAGE_ROOT = "\x4eoir Hub"
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
        "\x4eoirSilentAimUI", "\x4dM2ShootMurdererButton", "\x4eoirKnifeSheriffBind",
        "\x4eoirGrabGunBindButton", "\x4eoirAimlockOverlay", "\x4eoirInvisibleBindButton",
        "\x4eoirDesyncBindButton", "\x4eoirEmotesButtons", "\x4eoirEmotesQuick",
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
    safeLegacy = {
        Enabled=true, ["\x57all Check"]=true, ["\x53how Shoot Murder Button"]=true,
        ["\x4cock Shoot Murder Button"]=true, ["\x4bnife Silent Aim"]=true, ["\x4bnife Wall Check"]=true,
        ["\x50rioritize Sheriff"]=true, ["\x45nable WalkSpeed"]=true, ["\x45nable JumpPower"]=true,
        ["\x53how Round Timer"]=true, ["\x49nstant Role Detection"]=true, ["\x41uto Notify Roles"]=true,
        ["\x41uto Fire"]=true, ["\x53how FOV"]=true, ["\x49gnore Dead"]=true,
        ["\x49gnore Friends"]=true, ["\x41nti AFK"]=true,
    },
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
    local savedLang = NoirPersistence.data.dropdowns["\x4eoir::Lang"]
    if savedLang == "\x72u" or savedLang == "\x65n" or savedLang == "\x61r" then st.lang = savedLang end
    if st.lang ~= "\x72u" and st.lang ~= "\x61r" and st.lang ~= "\x65n" then st.lang = "\x65n" end
    st.dict = {
        ["Home"] = "Главная",
        ["Main"] = "Основное",
        ["Combat"] = "Бой",
        ["World"] = "Мир",
        ["Map"] = "Карта",
        ["Autofarm"] = "Автофарм",
        ["Visuals"] = "Визуалы",
        ["Skins"] = "Скины",
        ["Emotes"] = "Эмоции",
        ["Misc"] = "Разное",
        ["Trolling"] = "Троллинг",
        ["Settings"] = "Настройки",
        ["Round-aware · tween · dead-skip"] = "Учитывает раунд · твин · пропуск мёртвых",
        ["Auto Farm"] = "Автофарм",
        ["Farm Speed"] = "Скорость фарма",
        ["Farm Delay"] = "Задержка (сек)",
        ["Aura Radius"] = "Радиус ауры",
        ["Mode: Smooth"] = "Режим: Smooth",
        ["Mode: Lay"] = "Режим: Lay",
        ["Return To: Start"] = "Возврат: Старт",
        ["Return To: Map"] = "Возврат: Карта",
        ["Return To: Lobby"] = "Возврат: Лобби",
        ["TP To Lobby"] = "ТП в лобби",
        ["Reset Character"] = "Ресет персонажа",
        ["Auto Reset (Full Bag)"] = "Авто-ресет (полная сумка)",
        ["Avoid Murderer"] = "Избегать убийцу",
        ["Anti-AFK"] = "Анти-AFK",
        ["No Render While Farming"] = "Без рендера во время фарма",
        ["Coin Aura"] = "Аура монет",
        ["Reset As Murderer"] = "Ресет за убийцу",
        ["Reset As Sheriff"] = "Ресет за шерифа",
        ["Kill All On Full Bag"] = "Убить всех (полная сумка)",
        ["Shoot Murderer On Full"] = "Выстрел в убийцу (полная)",
        ["Idle"] = "Ожидание",
        ["Wait round..."] = "Ждём раунд...",
        ["No coins · waiting"] = "Нет монет · ждём",
        ["Wait respawn..."] = "Ждём респаун...",
        ["AIM • ANTI-AIM"] = "БОЙ • ANTI-AIM",
        ["Velocity desync against aimbots and silent aim"] = "Десинхрон скорости против аимботов и silent aim",
        ["Enable Anti-Aim"] = "Включить Anti-Aim",
        ["Mode"] = "Режим",
        ["Rotate"] = "Вращение",
        ["Only As Murderer"] = "Только за убийцу",
        ["Pause Near Players"] = "Пауза рядом с игроками",
        ["Pause Radius"] = "Радиус паузы",
        ["Enable Ignore List"] = "Список игнора",
        ["Ignore Player 1"] = "Игнор: игрок 1",
        ["Ignore Player 2"] = "Игнор: игрок 2",
        ["Ignore Player 3"] = "Игнор: игрок 3",
        ["SETTINGS • HUB"] = "НАСТРОЙКИ • ХАБ",
        ["Language and hub preferences"] = "Язык и параметры хаба",
        ["Language"] = "Язык",
        ["Language: English"] = "Язык: English",
        ["Language: Russian"] = "Язык: Русский",
        ["Executor"] = "Исполнитель",
        ["Anti-Aim"] = "Anti-Aim (защита от прицела)",
        ["-- ms"] = "-- мс",
        ["Aimlock Bind Button Size"] = "Размер кнопки Aimlock",
        ["Aimlock FOV Check"] = "Aimlock: проверка FOV",
        ["Aimlock FOV Radius"] = "Aimlock: радиус FOV",
        ["Aimlock Horizontal Prediction"] = "Aimlock: гориз. предикшн",
        ["Aimlock Prediction"] = "Aimlock: предикшн",
        ["Aimlock Smoothness"] = "Aimlock: плавность",
        ["Aimlock Target Body Part"] = "Aimlock: часть тела цели",
        ["Aimlock Target Player"] = "Aimlock: цель-игрок",
        ["Aimlock Wall Check"] = "Aimlock: проверка стен",
        ["Anti AFK"] = "Анти-AFK",
        ["AntiFling"] = "Анти-флинг",
        ["Apply Prediction On Gun Trigger Bot"] = "Предикшн в Gun Trigger Bot",
        ["Aura"] = "Аура",
        ["Aura Interval"] = "Интервал ауры",
        ["Auto GG picks up GunDrop while you do not have a Gun."] = "Auto GG подбирает GunDrop, пока у тебя нет пушки.",
        ["Auto GG, pickup, aura, notifications and bind button"] = "Auto GG, подбор, аура, уведомления и кнопка-бинд",
        ["Auto Kill Everyone"] = "Авто-убийство всех",
        ["Auto Kill Sheriff"] = "Авто-убийство шерифа",
        ["Auto Murderer"] = "Авто-убийца",
        ["Auto Murderer Delay"] = "Задержка авто-убийцы",
        ["Auto Notify Dropped Gun"] = "Уведомлять о выброшенной пушке",
        ["Auto Notify Roles"] = "Авто-уведомление ролей",
        ["Auto Remove Chroma Effects"] = "Убирать Chroma-эффекты",
        ["Auto Remove Coins"] = "Убирать монеты",
        ["Auto Remove Corpses"] = "Убирать трупы",
        ["Auto Remove Pets Display"] = "Убирать отображение питомцев",
        ["Auto Return"] = "Авто-возврат",
        ["Auto Sheriff"] = "Авто-шериф",
        ["Auto Sheriff Delay"] = "Задержка авто-шерифа",
        ["Auto-Get "] = "Авто-подбор ",
        ["Bind "] = "Бинд ",
        ["Bind Size (%)"] = "Размер бинда (%)",
        ["Bind Touch Fling"] = "Бинд Touch Fling",
        ["Bomb Jump+"] = "Bomb Jump+",
        ["Camera lock for Murderer or a selected player • all controls are local"] = "Захват камеры на убийцу или выбранного игрока • всё локально",
        ["Clear Aimlock Player Selection"] = "Сбросить цель Aimlock",
        ["Click"] = "Клик",
        ["Client-side limit • Saved preferences"] = "Клиентский лимит • сохранённые настройки",
        ["Connected"] = "Подключено",
        ["Cursor Artwork Scale"] = "Масштаб курсора",
        ["Cursor Design"] = "Дизайн курсора",
        ["Custom Cursor ID"] = "Свой ID курсора",
        ["Desync"] = "Desync",
        ["Desync Bind Button Size"] = "Размер кнопки Desync",
        ["Desync invisibility and floating bind button"] = "Desync-невидимость и плавающая кнопка-бинд",
        ["Enable "] = "Включить ",
        ["Enable Aimlock"] = "Включить Aimlock",
        ["Enable Aimlock Bind Button"] = "Кнопка-бинд Aimlock",
        ["Enable Auto "] = "Включить авто-",
        ["Enable Auto GG"] = "Включить Auto GG",
        ["Enable Cursor Color"] = "Включить цвет курсора",
        ["Enable Custom Cursor"] = "Включить свой курсор",
        ["Enable Desync Bind Button"] = "Кнопка-бинд Desync",
        ["Enable Desync to save the current position; you can then move locally while its saved position is sent on desync frames."] = "Включи Desync, чтобы сохранить позицию; сможешь двигаться локально, пока сохранённая позиция отправляется на десинк-кадрах.",
        ["Enable FE Anims"] = "Включить FE-анимации",
        ["Enable Frame Enhancement"] = "Улучшение кадров",
        ["Enable Grab Gun Bind Button"] = "Кнопка-бинд Grab Gun",
        ["Enable Invisible Bind Button"] = "Кнопка-бинд невидимости",
        ["Enable JumpPower"] = "Включить JumpPower",
        ["Enable Kill Sheriff Bindable Button"] = "Кнопка убийства шерифа",
        ["Enable WalkSpeed"] = "Включить WalkSpeed",
        ["Enabled"] = "Включено",
        ["Executor: "] = "Исполнитель: ",
        ["FE Animations"] = "FE-анимации",
        ["FPS"] = "FPS",
        ["FPS Boost"] = "Ускорение FPS",
        ["FPS Boost is shared with the hub's MISC • FPS control."] = "Ускорение FPS синхронизировано с разделом MISC • FPS.",
        ["Fast Throw"] = "Быстрый бросок",
        ["Fling Duration"] = "Длительность флинга",
        ["Fling Power"] = "Сила флинга",
        ["Fps Boost"] = "FPS буст",
        ["Full animation reset"] = "Полный сброс анимаций",
        ["GUN"] = "ПУШКА",
        ["GUN TRIGGER BOT"] = "GUN TRIGGER BOT",
        ["GUN UTILITIES • native Noir implementation"] = "Утилиты пушки • нативная реализация Noir",
        ["Grab Gun"] = "Grab Gun (забрать пушку)",
        ["Grab Gun Bind Button Size"] = "Размер кнопки Grab Gun",
        ["Gun Aura"] = "Аура пушки",
        ["Gun Aura Range"] = "Радиус ауры пушки",
        ["Gun Pickup Notify"] = "Уведомление подбора пушки",
        ["Gun Trigger Bot"] = "Gun Trigger Bot",
        ["Gun Trigger Bot Wall Check"] = "Gun Trigger Bot: проверка стен",
        ["Gun targeting controls"] = "Управление прицеливанием пушки",
        ["If a wall is between you and the target, the shot starts on their side of the wall. Turn this on with Silent Aim."] = "Если между тобой и целью стена, выстрел начинается с её стороны стены. Включай вместе с Silent Aim.",
        ["Independent KnifeThrown prediction"] = "Независимый предикшн KnifeThrown",
        ["Independent server-shot prediction"] = "Независимый предикшн серверного выстрела",
        ["Infinite Jump"] = "Бесконечный прыжок",
        ["Initializing..."] = "Инициализация...",
        ["Instant Role Detection"] = "Мгновенное определение ролей",
        ["Instant Throw"] = "Мгновенный бросок",
        ["Inventory Unlimiter V5"] = "Inventory Unlimiter V5",
        ["Invisible"] = "Невидимость",
        ["Invisible Bind Button Size"] = "Размер кнопки невидимости",
        ["JumpPower"] = "JumpPower",
        ["KNIFE PREDICTION"] = "ПРЕДИКШН НОЖА",
        ["KNIFE SILENT AIM"] = "KNIFE SILENT AIM",
        ["Keeps the server-facing character position at the activation point"] = "Держит серверную позицию персонажа в точке активации",
        ["Key "] = "Клавиша ",
        ["Kill Everyone"] = "Убить всех",
        ["Kill Player"] = "Убить игрока",
        ["Kill Sheriff"] = "Убить шерифа",
        ["Knife Silent Aim"] = "Knife Silent Aim",
        ["Knife Throw Aura"] = "Аура броска ножа",
        ["Knife Wall Check"] = "Нож: проверка стен",
        ["KnifeThrown Aura"] = "Аура KnifeThrown",
        ["Less Lag"] = "Меньше лагов",
        ["Load "] = "Загрузить ",
        ["Loading settings..."] = "Загрузка настроек...",
        ["Local visual-performance controls; server-side objects and round rules are not changed"] = "Локальные настройки производительности; серверные объекты и правила раунда не меняются",
        ["Lock Shoot Murder Button"] = "Закрепить кнопку выстрела в убийцу",
        ["Loop"] = "Цикл",
        ["Loop Interval"] = "Интервал цикла",
        ["MAIN • INVISIBLE"] = "ОСНОВНОЕ • НЕВИДИМОСТЬ",
        ["MAIN • SELF MODS"] = "ОСНОВНОЕ • СЕБЯ-МОДЫ",
        ["MAIN • SERVER"] = "ОСНОВНОЕ • СЕРВЕР",
        ["MAIN • UNIVERSAL"] = "ОСНОВНОЕ • УНИВЕРСАЛ",
        ["MISC • AIMLOCK"] = "РАЗНОЕ • AIMLOCK",
        ["MISC • CUSTOMIZE CURSOR"] = "РАЗНОЕ • СВОЙ КУРСОР",
        ["MISC • DESYNC"] = "РАЗНОЕ • DESYNC",
        ["MISC • FPS"] = "РАЗНОЕ • FPS",
        ["MM2 round information"] = "Информация о раунде MM2",
        ["Max Items"] = "Максимум предметов",
        ["Mode: "] = "Режим: ",
        ["Movement and survival utilities"] = "Утилиты движения и выживания",
        ["Mute Button SFX"] = "Без звука кнопок",
        ["NATIVE KNIFE UTILITIES • equipped Knife only"] = "Нативные утилиты ножа • только экипированный нож",
        ["NETWORK LATENCY"] = "ЗАДЕРЖКА СЕТИ",
        ["NOIR HUB"] = "NOIR HUB",
        ["NOIR SILENT AIM"] = "NOIR SILENT AIM",
        ["Nearest player or Sheriff-only targeting"] = "Прицеливание по ближайшему или только по шерифу",
        ["No Shadows"] = "Без теней",
        ["Noir Client • v4"] = "Noir Client • v4",
        ["Notifications"] = "Уведомления",
        ["Adaptive"] = "Адаптивный",
        ["Adaptive Engine"] = "Адаптивный движок",
        ["Auto Prediction"] = "Автопредикшн",
        ["Classic"] = "Классический",
        ["Config"] = "Конфиг",
        ["Data Ping"] = "Data Ping",
        ["Dynamic"] = "Динамический",
        ["Fallback"] = "Запасное значение",
        ["Jitter"] = "Джиттер",
        ["Last known"] = "Последнее значение",
        ["LOCKED"] = "ЗАФИКСИРОВАНО",
        ["Lock Config"] = "Фиксировать конфиг",
        ["ms"] = "мс",
        ["Network"] = "Сеть",
        ["Noir Auto"] = "Noir Auto",
        ["Noir Auto prediction profile"] = "Noir Auto: профиль предикшна",
        ["Noir Auto updates gun prediction using ping. Turning it off stops updates and keeps the last values."] = "Noir Auto обновляет предикшн пистолета по пингу. При выключении обновления остановятся, последние значения сохранятся.",
        ["NOIR AUTO PREDICTION"] = "NOIR AUTO PREDICTION",
        ["OFF"] = "ВЫКЛ",
        ["ON"] = "ВКЛ",
        ["Ping"] = "Пинг",
        ["Ping-adaptive Silent Aim prediction"] = "Предикшн Silent Aim с адаптацией под пинг",
        ["Print Telemetry"] = "Печать телеметрии",
        ["Profile"] = "Профиль",
        ["Raw"] = "Сырой",
        ["Source"] = "Источник",
        ["Performance"] = "Производительность",
        ["+Upgrade"] = "+Усиление",
        ["UPGRADE"] = "УСИЛЕНИЕ",
        ["UNLOCKED"] = "НЕ ЗАФИКСИРОВАНО",
        ["Upgrade Mode"] = "Режим усиления",
        ["Open Main for player tools, World for gun & fling tools, Visuals for ESP."] = "Открой Main для инструментов игрока, World для пушки и флингов, Visuals для ESP.",
        ["Optimize Coins"] = "Оптимизировать монеты",
        ["PISTOL PREDICTION"] = "ПРЕДИКШН ПИСТОЛЕТА",
        ["PLAYERS"] = "ИГРОКИ",
        ["Persistence"] = "Сохранения",
        ["Piercer Bullet"] = "Piercer Bullet (сквозь стены)",
        ["Pm-WallHop"] = "Pm-WallHop",
        ["Pm-WallHop Script by @Phemtom (Improved)"] = "Скрипт Pm-WallHop от @Phemtom (улучшенный)",
        ["Prediction"] = "Предикшн",
        ["Preset Name"] = "Имя пресета",
        ["Prioritize Sheriff"] = "Приоритет шерифа",
        ["QUICK START"] = "БЫСТРЫЙ СТАРТ",
        ["R O B L O X   H U B"] = "R O B L O X   Х А Б",
        ["Reapply / Retry"] = "Повторить / применить",
        ["Refresh Aimlock Player List"] = "Обновить список целей Aimlock",
        ["Refresh Kill Player List"] = "Обновить список убийства",
        ["Refresh Roles"] = "Обновить роли",
        ["Replaces the existing Shift Lock/crosshair image; no second cursor is added"] = "Заменяет изображение Shift Lock/прицела; второй курсор не добавляется",
        ["Return To: "] = "Возврат: ",
        ["Role Cache TTL"] = "TTL кэша ролей",
        ["Roles are sampled during the 10 second countdown."] = "Роли считываются во время 10-секундного отсчёта.",
        ["Round Grab Gun button: drag it to move; its size and position are saved."] = "Кнопка Grab Gun в раунде: перетащи, чтобы переместить; размер и позиция сохраняются.",
        ["Round Invisible button: tap to toggle; drag it to move. Its size and position are saved."] = "Кнопка невидимости в раунде: тап — переключить; перетащи, чтобы переместить. Размер и позиция сохраняются.",
        ["SFX 🔇"] = "SFX 🔇",
        ["SILENT AIM"] = "SILENT AIM",
        ["Save "] = "Сохранить ",
        ["Saved settings"] = "Сохранённые настройки",
        ["Server FireServer redirect"] = "Серверный редирект FireServer",
        ["Settings are saved automatically to Noir Hub/configs."] = "Настройки сохраняются автоматически в Noir Hub/configs.",
        ["Show Murderer Chance"] = "Показывать шанс убийцы",
        ["Show Round Timer"] = "Показывать таймер раунда",
        ["Show Shoot Murder Button"] = "Показывать кнопку выстрела в убийцу",
        ["Silent Aim • ESP • Prediction"] = "Silent Aim • ESP • Предикшн",
        ["Start Height"] = "Стартовая высота",
        ["Target Cooldown"] = "Кулдаун цели",
        ["Tip: select Auto Murderer for automatic role targeting. Drag the round AIM button to move it."] = "Совет: выбери Auto Murderer для авто-прицеливания по роли. Кнопку AIM в раунде можно перетаскивать.",
        ["Touch Fling"] = "Touch Fling",
        ["Universal player controls"] = "Универсальные контроли игроков",
        ["Unlimit Inventory"] = "Без лимита инвентаря",
        ["WORLD • GUN"] = "МИР • ПУШКА",
        ["WalkSpeed"] = "WalkSpeed",
        ["Wall Check"] = "Проверка стен",
        ["Windows: Xeno, Solara, Madium, Real, SirHurt, Potassium, Volt • Android: Delta, Codex, Arceus X • iOS: Delta • Mac: Opiumware, Macsploit"] = "Windows: Xeno, Solara, Madium, Real, SirHurt, Potassium, Volt • Android: Delta, Codex, Arceus X • iOS: Delta • Mac: Opiumware, Macsploit",
        ["Your Presets"] = "Твои пресеты",
        ["aux0on presets • R15 • full track reset • auto-save"] = "Пресеты aux0on • R15 • полный сброс треков • автосохранение",
        ["v4 • gun & knife prediction, player and object ESP, presets"] = "v4 • предикшн пушки и ножа, ESP игроков и объектов, пресеты",
        ["⏹ Cancel"] = " Отмена",
        ["▶ Start (list)"] = "▶ Старт (список)",
        ["▸ Player"] = " Игрок",
        ["🎯 Selected"] = "🎯 Выбрано",
        ["👋 Touch Fling"] = "👋 Touch Fling",
        ["👥 Everyone"] = "👥 Все",
        ["📍 Nearest"] = "📍 Ближайший",
        ["🔪 Murderer"] = "🔪 Убийца",
        ["🔫 Sheriff"] = "🔫 Шериф",
        ["🛑 Panic"] = "🛑 Паника",
        ["🧩 Reset bind layout"] = "🧩 Сбросить раскладку биндов",
        ["🧹 Clear WL"] = "🧹 Очистить WL",
        ["🧹 Clear keys"] = "🧹 Очистить клавиши",
        ["🧹 Clear loop"] = "🧹 Очистить цикл",
        ["Enable Speed Glitch UI"] = "Включить Speed Glitch UI",
        ["Only Work Sideways"] = "Только в стороны",
        ["Side Speed"] = "Скорость в стороны",
        ["Toggle Size"] = "Размер кнопки",
        ["Select Emote"] = "Выбор эмоции",
        ["Custom Emote ID"] = "Свой ID эмоции",
        ["Everyone"] = "Все",
        ["Murderer Only"] = "Только убийца",
        ["Sheriff Only"] = "Только шериф",
        ["Hero Only"] = "Только герой",
        ["Dead Only"] = "Только мёртвые",
        ["Dropped Gun"] = "Выброшенная пушка",
        ["Throwing Knives"] = "Летящие ножи",
        ["Object ESP"] = "ESP объектов",
        ["BY PLAYER"] = "ПО ИГРОКАМ",
        ["VISUAL • CHAM"] = "ВИЗУАЛ • CHAM",
        ["VISUAL • ESP"] = "ВИЗУАЛ • ESP",
        ["VISUAL • OUTLINE"] = "ВИЗУАЛ • КОНТУР",
        ["VISUAL • HIGHLIGHT"] = "ВИЗУАЛ • ПОДСВЕТКА",
        ["VISUAL • TRACER"] = "ВИЗУАЛ • ТРАССЕР",
        ["VISUAL • ESP BOX"] = "ВИЗУАЛ • БОКС",
        ["VISUAL • ESP AVATAR"] = "ВИЗУАЛ • АВАТАР",
        ["VISUAL • ESP FIRE"] = "ВИЗУАЛ • ОГОНЬ",
        ["VISUAL • BY OBJECT"] = "ВИЗУАЛ • ПО ОБЪЕКТАМ",
        ["Knives"] = "Ножи",
        ["Guns"] = "Пушки",
        ["Search skins by name..."] = "Поиск скинов по имени...",
        ["Enable"] = "Включить",
        ["Keep"] = "Держать",
        ["Backshots"] = "Backshots (сзади)",
        ["TROLL • BACKSHOTS"] = "ТРОЛЛИНГ • BACKSHOTS",
        ["Stream Mode: ON"] = "Режим записи: ВКЛ",
        ["Stream Mode: OFF"] = "Режим записи: ВЫКЛ",
        ["Hides button visuals only; buttons remain clickable."] = "Скрывает только вид кнопок; нажимать на них по-прежнему можно.",
        ["Restore buttons: Right Shift or hold three fingers for 1.3 seconds."] = "Вернуть вид кнопок: Right Shift или удерживайте три пальца 1,3 секунды.",
    }
    st.dict["Language: Arabic"] = "Язык: арабский"
    st.dict["Language updated."] = "Язык изменён"
    st.dict["type: Basic"] = "Тип: Basic"
    st.dict["type: Down"] = "Тип: Down"
    st.dict["Silent Aim Mode"] = "Режим Silent Aim"
    st.dict["Noir"] = "Noir"
    st.dict["Tering"] = "Tering"
    st.dict["BULLET TRACER"] = "Трейсер пуль"
    st.dict["Shoot Murder on full bag"] = "Стрелять в маньяка при полном мешке"
    st.dict["Auto Fling Sheriff on full bag"] = "Авто-флинг шерифа при полном мешке"
    st.dict["Flings sheriff on full bag to steal gun"] = "Флингает шерифа при полном мешке чтобы забрать пушку"
    local AR_DICT = {
        ["Home"] = "الرئيسية",
        ["Main"] = "الرئيسي",
        ["Combat"] = "القتال",
        ["World"] = "العالم",
        ["Map"] = "الخريطة",
        ["Autofarm"] = "الجمع التلقائي",
        ["Visuals"] = "المرئيات",
        ["Skins"] = "المظاهر",
        ["Emotes"] = "الحركات",
        ["Misc"] = "متفرقات",
        ["Trolling"] = "المقالب",
        ["Settings"] = "الإعدادات",
        ["Round-aware · tween · dead-skip"] = "مراعاة الجولة · حركة انتقالية · تخطي اللاعبين الموتى",
        ["Auto Farm"] = "الجمع التلقائي",
        ["Farm Speed"] = "سرعة الجمع",
        ["Farm Delay"] = "تأخير الجمع",
        ["Aura Radius"] = "نصف قطر الهالة",
        ["Mode: Smooth"] = "الوضع: سلس",
        ["Mode: Lay"] = "الوضع: استلقاء",
        ["Return To: Start"] = "العودة إلى: البداية",
        ["Return To: Map"] = "العودة إلى: الخريطة",
        ["Return To: Lobby"] = "العودة إلى: الردهة",
        ["TP To Lobby"] = "انتقال إلى الردهة",
        ["Reset Character"] = "إعادة تعيين الشخصية",
        ["Auto Reset (Full Bag)"] = "إعادة تعيين تلقائية (الحقيبة ممتلئة)",
        ["Avoid Murderer"] = "تجنب القاتل",
        ["Anti-AFK"] = "منع الخمول",
        ["No Render While Farming"] = "إيقاف العرض أثناء الجمع",
        ["Coin Aura"] = "هالة العملات",
        ["Reset As Murderer"] = "إعادة التعيين كقاتل",
        ["Reset As Sheriff"] = "إعادة التعيين كشرطي",
        ["Kill All On Full Bag"] = "القضاء على الجميع عند امتلاء الحقيبة",
        ["Shoot Murderer On Full"] = "إطلاق النار على القاتل عند الامتلاء",
        ["Idle"] = "خامل",
        ["Wait round..."] = "بانتظار الجولة...",
        ["No coins · waiting"] = "لا توجد عملات · بانتظارها",
        ["Wait respawn..."] = "بانتظار إعادة الظهور...",
        ["AIM • ANTI-AIM"] = "التصويب • مضاد التصويب",
        ["Velocity desync against aimbots and silent aim"] = "إلغاء تزامن السرعة ضد التصويب الآلي والتصويب الصامت",
        ["Enable Anti-Aim"] = "تفعيل مضاد التصويب",
        ["Mode"] = "الوضع",
        ["Rotate"] = "تدوير",
        ["Only As Murderer"] = "كقاتل فقط",
        ["Pause Near Players"] = "إيقاف مؤقت قرب اللاعبين",
        ["Pause Radius"] = "نصف قطر الإيقاف",
        ["Enable Ignore List"] = "تفعيل قائمة التجاهل",
        ["Ignore Player 1"] = "تجاهل اللاعب 1",
        ["Ignore Player 2"] = "تجاهل اللاعب 2",
        ["Ignore Player 3"] = "تجاهل اللاعب 3",
        ["SETTINGS • HUB"] = "الإعدادات • Noir Hub",
        ["Language and hub preferences"] = "اللغة وتفضيلات الواجهة",
        ["Language"] = "اللغة",
        ["Language: English"] = "اللغة: الإنجليزية",
        ["Language: Russian"] = "اللغة: الروسية",
        ["Executor"] = "المنفذ",
        ["Anti-Aim"] = "مضاد التصويب",
        ["-- ms"] = "-- مللي ثانية",
        ["Aimlock Bind Button Size"] = "حجم زر ربط Aimlock",
        ["Aimlock FOV Check"] = "Aimlock: فحص مجال الرؤية",
        ["Aimlock FOV Radius"] = "Aimlock: نصف قطر مجال الرؤية",
        ["Aimlock Horizontal Prediction"] = "Aimlock: التنبؤ الأفقي",
        ["Aimlock Prediction"] = "Aimlock: التنبؤ",
        ["Aimlock Smoothness"] = "Aimlock: السلاسة",
        ["Aimlock Target Body Part"] = "Aimlock: جزء جسم الهدف",
        ["Aimlock Target Player"] = "Aimlock: اللاعب المستهدف",
        ["Aimlock Wall Check"] = "Aimlock: فحص الجدران",
        ["Anti AFK"] = "منع الخمول",
        ["AntiFling"] = "مضاد الإقصاء",
        ["Apply Prediction On Gun Trigger Bot"] = "تطبيق التنبؤ على Gun Trigger Bot",
        ["Aura"] = "الهالة",
        ["Aura Interval"] = "فترة الهالة",
        ["Auto GG picks up GunDrop while you do not have a Gun."] = "يلتقط Auto GG عنصر GunDrop عندما لا تملك سلاحًا.",
        ["Auto GG, pickup, aura, notifications and bind button"] = "Auto GG، الالتقاط، الهالة، الإشعارات وزر الربط",
        ["Auto Kill Everyone"] = "القضاء التلقائي على الجميع",
        ["Auto Kill Sheriff"] = "القضاء التلقائي على الشرطي",
        ["Auto Murderer"] = "القاتل التلقائي",
        ["Auto Murderer Delay"] = "تأخير القاتل التلقائي",
        ["Auto Notify Dropped Gun"] = "إشعار تلقائي عند إسقاط السلاح",
        ["Auto Notify Roles"] = "إشعار تلقائي بالأدوار",
        ["Auto Remove Chroma Effects"] = "إزالة تأثيرات Chroma تلقائيًا",
        ["Auto Remove Coins"] = "إزالة العملات تلقائيًا",
        ["Auto Remove Corpses"] = "إزالة الجثث تلقائيًا",
        ["Auto Remove Pets Display"] = "إزالة عرض الحيوانات الأليفة تلقائيًا",
        ["Auto Return"] = "العودة تلقائيًا",
        ["Auto Sheriff"] = "الشرطي التلقائي",
        ["Auto Sheriff Delay"] = "تأخير الشرطي التلقائي",
        ["Auto-Get "] = "تحديد تلقائي ",
        ["Bind "] = "ربط ",
        ["Bind Size (%)"] = "حجم زر الربط (%)",
        ["Bind Touch Fling"] = "ربط Touch Fling",
        ["Bomb Jump+"] = "قفزة القنبلة+",
        ["Camera lock for Murderer or a selected player • all controls are local"] = "قفل الكاميرا للقاتل أو للاعب محدد • جميع عناصر التحكم محلية",
        ["Clear Aimlock Player Selection"] = "مسح اختيار لاعب Aimlock",
        ["Click"] = "نقرة",
        ["Client-side limit • Saved preferences"] = "حد العميل • التفضيلات محفوظة",
        ["Connected"] = "متصل",
        ["Cursor Artwork Scale"] = "مقياس رسمة المؤشر",
        ["Cursor Design"] = "تصميم المؤشر",
        ["Custom Cursor ID"] = "معرّف مؤشر مخصص",
        ["Desync"] = "إلغاء التزامن",
        ["Desync Bind Button Size"] = "حجم زر ربط Desync",
        ["Desync invisibility and floating bind button"] = "اختفاء Desync وزر ربط عائم",
        ["Enable "] = "تفعيل ",
        ["Enable Aimlock"] = "تفعيل Aimlock",
        ["Enable Aimlock Bind Button"] = "تفعيل زر ربط Aimlock",
        ["Enable Auto "] = "تفعيل تلقائي ",
        ["Enable Auto GG"] = "تفعيل Auto GG",
        ["Enable Cursor Color"] = "تفعيل لون المؤشر",
        ["Enable Custom Cursor"] = "تفعيل مؤشر مخصص",
        ["Enable Desync Bind Button"] = "تفعيل زر ربط Desync",
        ["Enable Desync to save the current position; you can then move locally while its saved position is sent on desync frames."] = "فعّل Desync لحفظ الموضع الحالي؛ بعدها يمكنك التحرك محليًا بينما يُرسل الموضع المحفوظ أثناء إطارات إلغاء التزامن.",
        ["Enable FE Anims"] = "تفعيل حركات FE",
        ["Enable Frame Enhancement"] = "تفعيل تحسين الإطارات",
        ["Enable Grab Gun Bind Button"] = "تفعيل زر ربط Grab Gun",
        ["Enable Invisible Bind Button"] = "تفعيل زر الربط للاختفاء",
        ["Enable JumpPower"] = "تفعيل قوة القفز",
        ["Enable Kill Sheriff Bindable Button"] = "تفعيل زر قتل الشرطي",
        ["Enable WalkSpeed"] = "تفعيل سرعة المشي",
        ["Enabled"] = "مفعّل",
        ["Executor: "] = "المنفّذ: ",
        ["FE Animations"] = "حركات FE",
        ["FPS"] = "FPS",
        ["FPS Boost"] = "تعزيز FPS",
        ["FPS Boost is shared with the hub's MISC • FPS control."] = "تعزيز FPS مشترك مع تحكم MISC • FPS في الواجهة.",
        ["Fast Throw"] = "رمي سريع",
        ["Fling Duration"] = "مدة Fling",
        ["Fling Power"] = "قوة Fling",
        ["Fps Boost"] = "تعزيز FPS",
        ["Full animation reset"] = "إعادة ضبط الحركة بالكامل",
        ["GUN"] = "السلاح",
        ["GUN TRIGGER BOT"] = "إطلاق تلقائي للسلاح",
        ["GUN UTILITIES • native Noir implementation"] = "أدوات السلاح • تنفيذ Noir أصلي",
        ["Grab Gun"] = "التقاط السلاح",
        ["Grab Gun Bind Button Size"] = "حجم زر ربط Grab Gun",
        ["Gun Aura"] = "هالة السلاح",
        ["Gun Aura Range"] = "مدى هالة السلاح",
        ["Gun Pickup Notify"] = "إشعار التقاط السلاح",
        ["Gun Trigger Bot"] = "الإطلاق التلقائي للسلاح",
        ["Gun Trigger Bot Wall Check"] = "فحص الجدران لإطلاق السلاح التلقائي",
        ["Gun targeting controls"] = "إعدادات استهداف السلاح",
        ["If a wall is between you and the target, the shot starts on their side of the wall. Turn this on with Silent Aim."] = "إذا وُجد جدار بينك وبين الهدف، يبدأ الإطلاق من جهته الأخرى. فعّل هذا الخيار مع Silent Aim.",
        ["Independent KnifeThrown prediction"] = "تنبؤ مستقل برمية السكين",
        ["Independent server-shot prediction"] = "تنبؤ مستقل لطلقة الخادم",
        ["Infinite Jump"] = "قفز لا نهائي",
        ["Initializing..."] = "جارٍ التهيئة...",
        ["Instant Role Detection"] = "كشف فوري للدور",
        ["Instant Throw"] = "رمي فوري",
        ["Inventory Unlimiter V5"] = "إزالة حد المخزون V5",
        ["Invisible"] = "غير مرئي",
        ["Invisible Bind Button Size"] = "حجم زر ربط الاختفاء",
        ["JumpPower"] = "قوة القفز",
        ["KNIFE PREDICTION"] = "تنبؤ السكين",
        ["KNIFE SILENT AIM"] = "التصويب الصامت بالسكين",
        ["Keeps the server-facing character position at the activation point"] = "يحافظ على موضع الشخصية لدى الخادم عند نقطة التفعيل",
        ["Key "] = "المفتاح ",
        ["Kill Everyone"] = "القضاء على الجميع",
        ["Kill Player"] = "القضاء على اللاعب",
        ["Kill Sheriff"] = "القضاء على الشرطي",
        ["Knife Silent Aim"] = "التصويب الصامت بالسكين",
        ["Knife Throw Aura"] = "هالة رمي السكين",
        ["Knife Wall Check"] = "فحص الجدران للسكين",
        ["KnifeThrown Aura"] = "هالة رمي السكين",
        ["Less Lag"] = "تقليل التأخير",
        ["Load "] = "تحميل ",
        ["Loading settings..."] = "جارٍ تحميل الإعدادات...",
        ["Local visual-performance controls; server-side objects and round rules are not changed"] = "عناصر تحكم محلية للأداء المرئي؛ لا تتغير عناصر الخادم أو قواعد الجولة",
        ["Lock Shoot Murder Button"] = "قفل زر إطلاق النار على القاتل",
        ["Loop"] = "تكرار",
        ["Loop Interval"] = "فترة التكرار",
        ["MAIN • INVISIBLE"] = "الرئيسي • الاختفاء",
        ["MAIN • SELF MODS"] = "الرئيسي • تعديلات الذات",
        ["MAIN • SERVER"] = "الرئيسي • الخادم",
        ["MAIN • UNIVERSAL"] = "الرئيسي • عام",
        ["MISC • AIMLOCK"] = "متفرقات • Aimlock",
        ["MISC • CUSTOMIZE CURSOR"] = "متفرقات • تخصيص المؤشر",
        ["MISC • DESYNC"] = "متفرقات • إلغاء التزامن",
        ["MISC • FPS"] = "متفرقات • FPS",
        ["MM2 round information"] = "معلومات جولة MM2",
        ["Max Items"] = "الحد الأقصى للعناصر",
        ["Mode: "] = "الوضع: ",
        ["Movement and survival utilities"] = "أدوات الحركة والبقاء",
        ["Mute Button SFX"] = "كتم أصوات الأزرار",
        ["NATIVE KNIFE UTILITIES • equipped Knife only"] = "أدوات السكين الأصلية • السكين المجهز فقط",
        ["NETWORK LATENCY"] = "زمن استجابة الشبكة",
        ["NOIR HUB"] = "NOIR HUB",
        ["NOIR SILENT AIM"] = "التصويب الصامت Noir",
        ["Nearest player or Sheriff-only targeting"] = "استهداف أقرب لاعب أو الشرطي فقط",
        ["No Shadows"] = "بدون ظلال",
        ["Noir Client • v4"] = "Noir Client • v4",
        ["Notifications"] = "الإشعارات",
        ["Adaptive"] = "تكيفي",
        ["Adaptive Engine"] = "محرك تكيفي",
        ["Auto Prediction"] = "التنبؤ التلقائي",
        ["Classic"] = "كلاسيكي",
        ["Config"] = "الإعدادات",
        ["Data Ping"] = "زمن اتصال البيانات",
        ["Dynamic"] = "ديناميكي",
        ["Fallback"] = "احتياطي",
        ["Jitter"] = "تذبذب",
        ["Last known"] = "آخر قيمة معروفة",
        ["LOCKED"] = "مقفل",
        ["Lock Config"] = "قفل الإعدادات",
        ["ms"] = "مللي ثانية",
        ["Network"] = "الشبكة",
        ["Noir Auto"] = "Noir Auto",
        ["Noir Auto prediction profile"] = "ملف تنبؤ Noir Auto",
        ["Noir Auto updates gun prediction using ping. Turning it off stops updates and keeps the last values."] = "يحدّث Noir Auto تنبؤ السلاح حسب زمن الاستجابة. إيقافه يوقف التحديثات ويُبقي آخر القيم.",
        ["NOIR AUTO PREDICTION"] = "تنبؤ Noir التلقائي",
        ["OFF"] = "إيقاف",
        ["ON"] = "تشغيل",
        ["Ping"] = "زمن الاستجابة",
        ["Ping-adaptive Silent Aim prediction"] = "تنبؤ Silent Aim متكيف مع زمن الاستجابة",
        ["Print Telemetry"] = "عرض بيانات القياس",
        ["Profile"] = "الملف الشخصي",
        ["Raw"] = "خام",
        ["Source"] = "المصدر",
        ["Performance"] = "الأداء",
        ["+Upgrade"] = "+ترقية",
        ["UPGRADE"] = "ترقية",
        ["UNLOCKED"] = "مفتوح",
        ["Upgrade Mode"] = "وضع الترقية",
        ["Open Main for player tools, World for gun & fling tools, Visuals for ESP."] = "افتح الرئيسي لأدوات اللاعبين، والعالم لأدوات السلاح وFling، والمرئيات لـ ESP.",
        ["Optimize Coins"] = "تحسين العملات",
        ["PISTOL PREDICTION"] = "تنبؤ المسدس",
        ["PLAYERS"] = "اللاعبون",
        ["Persistence"] = "حفظ الحالة",
        ["Piercer Bullet"] = "رصاصة خارقة",
        ["Pm-WallHop"] = "Pm-WallHop",
        ["Pm-WallHop Script by @Phemtom (Improved)"] = "نص Pm-WallHop بواسطة @Phemtom (محسّن)",
        ["Prediction"] = "التنبؤ",
        ["Preset Name"] = "اسم الإعداد المسبق",
        ["Prioritize Sheriff"] = "إعطاء الأولوية للشرطي",
        ["QUICK START"] = "بدء سريع",
        ["R O B L O X   H U B"] = "مركز ROBLOX",
        ["Reapply / Retry"] = "إعادة التطبيق / المحاولة",
        ["Refresh Aimlock Player List"] = "تحديث قائمة لاعبي Aimlock",
        ["Refresh Kill Player List"] = "تحديث قائمة لاعبي القضاء",
        ["Refresh Roles"] = "تحديث الأدوار",
        ["Replaces the existing Shift Lock/crosshair image; no second cursor is added"] = "يستبدل صورة Shift Lock/علامة التصويب الحالية؛ لا يضيف مؤشرًا ثانيًا",
        ["Return To: "] = "العودة إلى: ",
        ["Role Cache TTL"] = "مدة صلاحية ذاكرة الأدوار",
        ["Roles are sampled during the 10 second countdown."] = "تُحدّث الأدوار خلال العد التنازلي لعشر ثوانٍ.",
        ["Round Grab Gun button: drag it to move; its size and position are saved."] = "زر Grab Gun للجولة: اسحبه لتحريكه؛ يُحفظ حجمه وموضعه.",
        ["Round Invisible button: tap to toggle; drag it to move. Its size and position are saved."] = "زر الاختفاء للجولة: اضغط للتبديل واسحب للتحريك؛ يُحفظ حجمه وموضعه.",
        ["SFX 🔇"] = "المؤثرات الصوتية 🔇",
        ["SILENT AIM"] = "التصويب الصامت",
        ["Save "] = "حفظ ",
        ["Saved settings"] = "الإعدادات المحفوظة",
        ["Server FireServer redirect"] = "إعادة توجيه FireServer للخادم",
        ["Settings are saved automatically to Noir Hub/configs."] = "تُحفظ الإعدادات تلقائيًا في Noir Hub/configs.",
        ["Show Murderer Chance"] = "إظهار احتمال القاتل",
        ["Show Round Timer"] = "إظهار مؤقت الجولة",
        ["Show Shoot Murder Button"] = "إظهار زر إطلاق النار على القاتل",
        ["Silent Aim • ESP • Prediction"] = "التصويب الصامت • ESP • التنبؤ",
        ["Start Height"] = "ارتفاع البداية",
        ["Target Cooldown"] = "فترة تهدئة الهدف",
        ["Tip: select Auto Murderer for automatic role targeting. Drag the round AIM button to move it."] = "نصيحة: اختر Auto Murderer للاستهداف التلقائي حسب الدور. اسحب زر AIM الدائري لتحريكه.",
        ["Touch Fling"] = "Touch Fling",
        ["Universal player controls"] = "عناصر تحكم عامة للاعب",
        ["Unlimit Inventory"] = "فتح حد المخزون",
        ["WORLD • GUN"] = "العالم • السلاح",
        ["WalkSpeed"] = "سرعة المشي",
        ["Wall Check"] = "فحص الجدران",
        ["Windows: Xeno, Solara, Madium, Real, SirHurt, Potassium, Volt • Android: Delta, Codex, Arceus X • iOS: Delta • Mac: Opiumware, Macsploit"] = "Windows: Xeno, Solara, Madium, Real, SirHurt, Potassium, Volt • Android: Delta, Codex, Arceus X • iOS: Delta • Mac: Opiumware, Macsploit",
        ["Your Presets"] = "إعداداتك المسبقة",
        ["aux0on presets • R15 • full track reset • auto-save"] = "إعدادات aux0on • R15 • إعادة ضبط المسار بالكامل • حفظ تلقائي",
        ["v4 • gun & knife prediction, player and object ESP, presets"] = "v4 • تنبؤ السلاح والسكين، ESP للاعبين والعناصر، إعدادات مسبقة",
        ["⏹ Cancel"] = "⏹ إلغاء",
        ["▶ Start (list)"] = "▶ ابدأ (القائمة)",
        ["▸ Player"] = "▸ اللاعب",
        ["🎯 Selected"] = "🎯 محدد",
        ["👋 Touch Fling"] = "👋 Touch Fling",
        ["👥 Everyone"] = "👥 الجميع",
        ["📍 Nearest"] = "📍 الأقرب",
        ["🔪 Murderer"] = "🔪 القاتل",
        ["🔫 Sheriff"] = "🔫 الشرطي",
        ["🛑 Panic"] = "🛑 طوارئ",
        ["🧩 Reset bind layout"] = "🧩 إعادة ضبط تخطيط الأزرار",
        ["🧹 Clear WL"] = "🧹 مسح القائمة البيضاء",
        ["🧹 Clear keys"] = "🧹 مسح المفاتيح",
        ["🧹 Clear loop"] = "🧹 إيقاف التكرار",
        ["Enable Speed Glitch UI"] = "تفعيل واجهة Speed Glitch",
        ["Only Work Sideways"] = "يعمل جانبيًا فقط",
        ["Side Speed"] = "السرعة الجانبية",
        ["Toggle Size"] = "حجم زر التبديل",
        ["Select Emote"] = "اختر حركة",
        ["Custom Emote ID"] = "معرّف حركة مخصص",
        ["Everyone"] = "الجميع",
        ["Murderer Only"] = "القاتل فقط",
        ["Sheriff Only"] = "الشرطي فقط",
        ["Hero Only"] = "البطل فقط",
        ["Dead Only"] = "الموتى فقط",
        ["Dropped Gun"] = "السلاح المُلقى",
        ["Throwing Knives"] = "سكاكين الرمي",
        ["Object ESP"] = "ESP للعناصر",
        ["BY PLAYER"] = "حسب اللاعب",
        ["VISUAL • CHAM"] = "المرئيات • CHAM",
        ["VISUAL • ESP"] = "المرئيات • ESP",
        ["VISUAL • OUTLINE"] = "المرئيات • الحدود",
        ["VISUAL • HIGHLIGHT"] = "المرئيات • الإبراز",
        ["VISUAL • TRACER"] = "المرئيات • خطوط التتبع",
        ["VISUAL • ESP BOX"] = "المرئيات • صندوق ESP",
        ["VISUAL • ESP AVATAR"] = "المرئيات • صورة اللاعب",
        ["VISUAL • ESP FIRE"] = "المرئيات • نار ESP",
        ["VISUAL • BY OBJECT"] = "المرئيات • حسب العنصر",
        ["Knives"] = "السكاكين",
        ["Guns"] = "الأسلحة",
        ["Search skins by name..."] = "ابحث عن المظاهر بالاسم...",
        ["Enable"] = "تفعيل",
        ["Keep"] = "إبقاء",
        ["Backshots"] = "Backshots",
        ["TROLL • BACKSHOTS"] = "المقالب • Backshots",
        ["Stream Mode: ON"] = "وضع البث: تشغيل",
        ["Stream Mode: OFF"] = "وضع البث: إيقاف",
        ["Hides button visuals only; buttons remain clickable."] = "يخفي مظهر الأزرار فقط؛ وتبقى قابلة للنقر.",
        ["Restore buttons: Right Shift or hold three fingers for 1.3 seconds."] = "إظهار الأزرار مجددًا: اضغط Right Shift أو اضغط بثلاثة أصابع لمدة 1.3 ثانية.",
        ["Language updated."] = "تم تغيير اللغة.",
    }
    AR_DICT["Language: Arabic"] = "اللغة: العربية"
    AR_DICT["type: Basic"] = "النوع: أساسي"
    AR_DICT["type: Down"] = "النوع: نزول"
    st.dicts = { en = {}, ru = st.dict, ar = AR_DICT }
    -- Fix Arabic missing feature names: fill from RU/EN if missing
    for k,v in pairs(st.dict) do if AR_DICT[k]==nil then AR_DICT[k]=k end end
    AR_DICT["Silent Aim Mode"] = "وضع التصويب الصامت"
    AR_DICT["Noir"] = "نوار"
    AR_DICT["Tering"] = "تيرينغ"
    AR_DICT["BULLET TRACER"] = "تتبع الرصاص"
    AR_DICT["Shoot Murder on full bag"] = "إطلاق النار على القاتل عند امتلاء الحقيبة"
    AR_DICT["Auto Fling Sheriff on full bag"] = "رمي الشريف تلقائيا عند امتلاء الحقيبة"
    AR_DICT["Flings sheriff on full bag to steal gun"] = "يرمي الشريف عند امتلاء الحقيبة لسرقة السلاح"
    AR_DICT["Touch Fling"] = AR_DICT["Touch Fling"] or "اللمس السريع"
    AR_DICT["👋 Touch Fling"] = AR_DICT["👋 Touch Fling"] or "👋 اللمس السريع"
    AR_DICT["Bind Touch Fling"] = AR_DICT["Bind Touch Fling"] or "ربط اللمس السريع"
    st.renderedToSource = {}
    st.originalTextDirections = setmetatable({}, { __mode = "k" })
    st.originalTextXAlignments = setmetatable({}, { __mode = "k" })
    if st.lang ~= "en" and st.lang ~= "ru" and st.lang ~= "ar" then st.lang = "en" end
    NoirTr = function(value)
        if type(value) ~= "string" then return value end
        local state = NoirGenv().__NoirLangState
        if type(state) ~= "table" then return value end
        state.renderedToSource = state.renderedToSource or {}
        local source = state.renderedToSource[value] or value
        local dictionaries = state.dicts or {}
        local dictionary = dictionaries[state.lang] or {}
        local rendered = dictionary[source] or source
        state.renderedToSource[rendered] = source
        state.renderedToSource[source] = source
        return rendered
    end

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
    base = Color3.fromRGB(10,9,8), surface = Color3.fromRGB(15,13,11), panel = Color3.fromRGB(10,9,8),
    card = Color3.fromRGB(15,13,11), border = Color3.fromRGB(50,34,23), accent = Color3.fromRGB(224,116,24),
    accent2 = Color3.fromRGB(255,170,54), text = Color3.fromRGB(245,242,238), dim = Color3.fromRGB(130,124,118),
    off = Color3.fromRGB(30,26,22), btn = Color3.fromRGB(20,17,14),
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
        ["@flingstorage_v1"] = true, ["MM2ShootMurderButton"] = true,
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
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(120, 118, 112)),
        ColorSequenceKeypoint.new(0.22, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(150, 146, 138)),
        ColorSequenceKeypoint.new(0.72, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(110, 108, 104)),
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
        TextSize = size, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
        Position = pos or UDim2.new(), Size = UDim2.new(1, 0, 0, size + 8) })
end

gui = New("\x53creenGui", { Name = "\x4eoirSilentAimUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = guiParent })
__NOIR_GUARD.gui = gui

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
    ["MM2ShootMurdererButton"] = true,
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
    ImageTransparency = .97, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(Vector2.new(112,112), Vector2.new(147,147)), SliceScale = .6, ZIndex = 1, Visible = false })
local win = New("\x46rame", { Parent = gui, Name = "\x57indow", AnchorPoint = Vector2.new(.5, .5),
    Position = NoirPersistence.GetPosition("\x77indow", UDim2.fromScale(.5, .5)), Size = UDim2.fromOffset(1000, 700),
    BackgroundColor3 = C.base, BackgroundTransparency = .70, ClipsDescendants = true, Visible = false, ZIndex = 2 })
winShadow.Position = win.Position
winShadow.Size = UDim2.new(0, win.Size.X.Offset + 44, 0, win.Size.Y.Offset + 44)
winShadow.AnchorPoint = win.AnchorPoint
local winScale = New("\x55IScale", { Parent = win, Scale = .82 })
corner(win, 10)
local winStroke = ringStroke(win, 1.6, .12)
local winGlow = New("\x55IStroke", { Parent = win, Color = C.accent, Thickness = 4, Transparency = .88, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
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
logo.TextStrokeTransparency = 1
do
    local navDefs = {
        { "\x68ome",   16898613509, Vector2.new(820, 147), "\x48ome" },
        { "\x61im",    16898613777, Vector2.new(967, 759), "\x54rain" },
        { "\x66arm",   16898613509, Vector2.new(771, 563), "\x46arm" },
        { "\x77orld",  16898613509, Vector2.new(771, 563), "\x43ombat" },
        { "\x6dap",    16898613509, Vector2.new(771, 563), "\x53hop" },
        { "\x6disc",   16898613509, Vector2.new(820, 147), "\x4disc" },
    }    for i, d in ipairs(navDefs) do
        local b = New("\x54extButton", { Parent = sidebar, Position = UDim2.fromOffset(19, 104 + (i - 1) * 42), Size = UDim2.fromOffset(40, 40),
            BackgroundColor3 = C.accent, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Name = d[4] })
        corner(b, 12)
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
local headerTitle = text(header, "\x4eOIR HUB", 24, UDim2.fromOffset(28, 24)); headerTitle.Visible = false
local headerSub = text(header, "Muscle Legends \x2022 automation suite", 13, UDim2.fromOffset(29, 56), true); headerSub.Visible = false
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
        local encodedArrow = "\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\x2fwNVQ1uk90AZPQAAAABJRU5ErkJggg=="
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
New("\x55IGradient", { Parent = heroCard, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(60,48,32)), ColorSequenceKeypoint.new(1, Color3.fromRGB(24,18,14)) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, .72), NumberSequenceKeypoint.new(1, .86) }), Rotation = 25 })
text(heroCard, "\x4eOIR SILENT AIM", 26, UDim2.fromOffset(26, 24))
text(heroCard, "\x764 • gun & knife prediction, player and object ESP, presets", 14, UDim2.fromOffset(27, 62), true)
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
        local col, page = nil, "\x61im"
        if string.sub(name, 1, 7) == "TRAIN \x2022 " then
            sectionCount += 1; col = cols[(sectionCount - 1) % 2 + 1]; page = "\x61im"
        elseif string.sub(name, 1, 6) == "FARM \x2022 " then
            farmSectionCount += 1; col = farmCols[(farmSectionCount - 1) % 2 + 1]; page = "\x66arm"
        elseif string.sub(name, 1, 8) == "COMBAT \x2022 " then
            worldSectionCount += 1; col = worldCols[(worldSectionCount - 1) % 2 + 1]; page = "\x77orld"
        elseif string.sub(name, 1, 6) == "SHOP \x2022 " then
            mapSectionCount += 1; col = mapCols[(mapSectionCount - 1) % 2 + 1]; page = "\x6dap"
        elseif string.sub(name, 1, 6) == "MISC \x2022 " then
            miscSectionCount += 1; col = miscCols[(miscSectionCount - 1) % 2 + 1]; page = "\x6disc"
        end
        if not col then
            sectionCount += 1
            col = cols[(sectionCount - 1) % 2 + 1]
            page = "\x61im"
        end
        local panel = New("\x46rame", { Parent = col, Size = UDim2.new(1, 0, 0, 90), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = C.panel, BackgroundTransparency = .86, ClipsDescendants = true })
        corner(panel, 10); stroke(panel, C.border, .15)
        local tick = New("\x46rame", { Parent = panel, Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.border, BorderSizePixel = 0 })
        table.insert(sectionPanels, { panel = panel, page = page, name = string.lower(name .. "\x20" .. (description or "")) })
        local shownName = name:gsub("^%u+ \x2022 ", "")
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
            rowLabel.TextTransparency = .35
            rowLabel.Size = UDim2.new(1, -160, 0, h or 20)
            rowLabel.TextYAlignment = Enum.TextYAlignment.Center
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
            local function set(v, persist, animate)
                state = v == true
                if animate == false then
                    pill.BackgroundColor3 = state and C.accent or C.off
                    dot.Position = state and UDim2.new(1, -14, .5, 0) or UDim2.new(0, 2, .5, 0)
                    dot.BackgroundColor3 = C.text
                    dot.Size = UDim2.fromOffset(12, 12)
                else
                    TweenService:Create(pill, TweenInfo.new(.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundColor3 = state and C.accent or C.off }):Play()
                    TweenService:Create(dot, TweenInfo.new(.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = state and UDim2.new(1, -14, .5, 0) or UDim2.new(0, 2, .5, 0), BackgroundColor3 = C.text, Size = UDim2.fromOffset(12, 120, 30) }):Play()
                    task.delay(.20, function() if dot.Parent then TweenService:Create(dot, TweenInfo.new(.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(12, 12) }):Play() end end)
                end
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
                TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false })
            local track = New("\x46rame", { Parent = r, Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = C.off })
            corner(track, 1)
            local fill = New("\x46rame", { Parent = track, Size = UDim2.fromScale((default - min) / (max - min), 1), BackgroundColor3 = C.accent, BorderSizePixel = 0 })
            corner(fill, 1)
            local knob = New("\x46rame", { Parent = track, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new((default - min) / (max - min), 0, .5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = C.text })
            knob.Size = UDim2.fromOffset(15, 15); corner(knob, 8); stroke(knob, C.border, .3)
            local current = default
            local function set(v, persist)
                current = math.clamp(math.floor((tonumber(v) or current or default) + .5), min, max)
                fill.Size = UDim2.fromScale((current - min) / (max - min), 1)
                knob.Position = UDim2.new((current - min) / (max - min), 0, .5, 0)
                value.Text = tostring(current)
                callback(current)
                if persist ~= false then NoirPersistence.data.sliders[key] = current; NoirPersistence.Save() end
            end
            set(default, false)
            value.FocusLost:Connect(function() set(value.Text) end)
            local drag = false
            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
                    drag = true; set(min + (max - min) * math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if drag and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
                    set(min + (max - min) * math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
            end)
            return { SetValue = function(_, v, persist) set(v, persist) end, GetValue = function() return current end }
        end
        function api:AddDropdown(label, values, callback)
            local key = keyFor(label)
            local r = row(label, 18)
            local idx = table.find(values, NoirPersistence.data.dropdowns[key]) or 1
            local b = New("\x54extButton", { Parent = r, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(150, 18),
                BackgroundColor3 = C.surface, BackgroundTransparency = 1, Text = tostring(values[1] or "\x4eone") .. "\x20⌄", TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 5 })
            local popup
            local function close() if popup then popup:Destroy(); popup = nil end end
            local function set(v, silent)
                local found = table.find(values, v)
                if found then idx = found end
                b.Text = tostring(values[idx] or "\x4eone") .. "\x20⌄"
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
                popup = New("\x53crollingFrame", { Parent = gui, Position = UDim2.fromOffset(b.AbsolutePosition.X / scale.Scale, (b.AbsolutePosition.Y + b.AbsoluteSize.Y + 4) / scale.Scale),
                    Size = UDim2.fromOffset(b.AbsoluteSize.X / scale.Scale, math.min(#values * 38, 190)), CanvasSize = UDim2.fromOffset(0, #values * 38),
                    BackgroundColor3 = C.surface, BorderSizePixel = 0, ScrollBarThickness = 4, ZIndex = 50 })
                corner(popup, 10); stroke(popup, C.accent, .2)
                New("\x55IListLayout", { Parent = popup, SortOrder = Enum.SortOrder.LayoutOrder })
                for _, v in ipairs(values) do
                    local item = New("\x54extButton", { Parent = popup, Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = tostring(v),
                        TextColor3 = C.text, TextSize = 14, Font = Enum.Font.Gotham, ZIndex = 51 })
                    item.Activated:Connect(function() set(v); close() end)
                end
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

local config = {
    enabled = false,
    targetMode = "\x4durderer",
    hitPart = "\x48umanoidRootPart",
    fovSize = 0,
    showFov = false,
    aimKey = "\x4eone",
    toggleKey = "\x4eone",
    autoFire = false,
    autoFireKey = "\x4eone",
    shotMethod = "\x52emote",
    wallCheck = false,
    piercerBullet = false,
    ignoreDead = true,
    ignoreFriends = false,
    maxDistance = 0,
    adaptive = true,
    fixedLead = 0.075,
    extraLead = 0.02,
    targetPart = "\x48umanoidRootPart",
    alignDirection = true,
    prioritizePing = true,
    predictJump = false,
    predictLag = true,
    maxSimulationMs = 180,
    predictionIntervalMs = 72,
    manualPingMs = 80,
    offsetX = 0, offsetY = 0, offsetZ = 0,
    horizontalMultiplier = 100, verticalMultiplier = 100,
    knifeAim = {
        adaptive = true,
        fixedLead = 0.075,
        extraLead = 0.02,
        prioritizePing = true,
        predictJump = false,
        predictLag = true,
        maxSimulationMs = 180,
        predictionIntervalMs = 72,
        manualPingMs = 80,
        offsetX = 0, offsetY = 0, offsetZ = 0,
        horizontalMultiplier = 100, verticalMultiplier = 100,
    },
    knifeEnabled = false,
    knifeWallCheck = false,
    knifePrioritizeSheriff = false,
    knifeAutoThrow = false,
     
    knifeDualEffect = false,
    knifeInstantThrow = false,
    knifeFastThrow = false,
    knifeAutoKillEveryone = false,
    knifeAutoKillSheriff = false,
    knifeKillPlayer = "\x4e/A",
    knifeSheriffBind = false,
    knifeSheriffBindShape = "\x43ircle",
     
    knifeThrownAura = true,
    knifeRadius = 15,
    showShootButton = false,
    lockShootButton = false,
     
    gunDualEffect = false,
    gunTriggerBot = false,
    gunTriggerBotWallCheck = true,
    gunTriggerBotPrediction = true,
    selectedPlayer = nil,
}

 
NoirPersistence.data.toggles["\x53ILENT AIM::Use Gun Dual Effect"] = false
NoirPersistence.data.toggles["\x4bNIFE SILENT AIM::Use Knife Dual Effect"] = false
 
do
    local oldProjectedDual = NoirGenv().__NoirCameraProjectedDual
    if type(oldProjectedDual) == "\x74able" and type(oldProjectedDual.Stop) == "\x66unction" then pcall(oldProjectedDual.Stop, oldProjectedDual) end
    NoirGenv().__NoirCameraProjectedDual = nil
end
NoirPersistence.Save()

local murderer, sheriff, hero
local cachedPing = 0.05
local redirected = 0
local hooked = false
local running = true
local shootButton, shootGui, shootBusy = nil, nil, false
local buttonShotActive, buttonShotTarget = false, nil
local presetName = "\x64efault"
local PRESET_FOLDER = PRESETS_FOLDER
local revertControls, revertToggleStates, syncRevertControls = {}, {}, nil
local noirMirrorControls = {}
local presetDropdown
local motionPart, motionPosition, motionTime
local measuredVelocity = Vector3.zero
local motionSamples = {}
local previousEstimatedVelocity = Vector3.zero
local estimatedAcceleration = Vector3.zero
local lastAutoTune = 0
local roundTimerEndsAt, roundPendingStart
local roundState = "\x77aiting"
local roundResetToken = 0
local lastRoundResetAt = os.clock()
local instantRoleDetection = false
local autoNotifyRoles = false
local announcedRoles = {}
local roleCache = {}
local playerData = {}
local aimHeld = true
local autoFireHeld = false

local cachedPlayers = {}
local function refreshPlayerCache() cachedPlayers = Players:GetPlayers() end
refreshPlayerCache()
local function getPlayers() return cachedPlayers end
Players.PlayerAdded:Connect(refreshPlayerCache)
Players.PlayerRemoving:Connect(function(player)
    refreshPlayerCache()
    playerData[player.UserId], roleCache[player.UserId], announcedRoles[player.UserId] = nil, nil, nil
    local changed = murderer == player or sheriff == player or hero == player
    if murderer == player then murderer = nil end
    if sheriff == player then sheriff = nil end
    if hero == player then hero = nil end
    if changed then
        local bus = NoirGenv().__NoirV4RoleBus
        if bus and bus.Emit then bus:Emit() end
    end
end)

function notify(msg, time)
    if type(host.Notify) == "\x66unction" then pcall(host.Notify, "\x4dM2 Silent Aim: " .. tostring(msg), time or 3) end
end
-- Satellite chunks (Troll / SNPWARE / Emotes) call shared.Notify directly; expose it so they never hit a nil call.
pcall(function()
    shared.Notify = function(textValue, duration)
        if type(host.Notify) == "\x66unction" then pcall(host.Notify, tostring(textValue), tonumber(duration) or 3) end
    end
    NoirGenv().Notify = shared.Notify
end)

NoirGenv().__NoirCore = {
    host = host, C = C, New = New, corner = corner, stroke = stroke, text = text,
    TweenService = TweenService, dashboard = dashboard, win = win, gui = gui,
    NoirPersistence = NoirPersistence, Players = Players, LocalPlayer = LocalPlayer,
    ReplicatedStorage = ReplicatedStorage, RunService = RunService, Stats = Stats,
    CoreGui = CoreGui, UIS = UIS,
}
end
__noirW1b()
end
__noirW1a()

-- ===== Noir Muscle Legends: logic =====
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
    dim = Color3.fromRGB(172, 164, 156), ok = Color3.fromRGB(139, 224, 104),
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

-- ALIVE

local alive = true

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

function startTrainLoop()
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

function startPunchLoop()
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

function startRebirthLoop()
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
function startRewardsLoop()
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

function startRockLoop()
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

function startBrawlLoop()
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

function startBossLoop()
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

function startChestLoop()
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

function startFullTrain()
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

function startEggLoop()
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

function startFortuneLoop()
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

function startCrystalLoop()
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

-- ===== Noir Muscle Legends: wiring =====

local __core = NoirGenv().__NoirCore
local host = __core and __core.host
function Notify(t, d) pcall(function() host.Notify(tostring(t), tonumber(d) or 2.5) end) end
if not host then warn("[Noir ML] UI core missing") return end

do
    local dash = __core.dashboard
    local C = __core.C
    if dash then
        local card = New("Frame", { Parent = dash, Position = UDim2.fromOffset(0, 326), Size = UDim2.fromOffset(400, 120), BackgroundColor3 = C.panel, BackgroundTransparency = .86, BorderSizePixel = 0 })
        corner(card, 16)
        stroke(card, C.border, .6)
        text(card, "MUSCLE LEGENDS", 15, UDim2.fromOffset(16, 12))
        local sub = text(card, "strength / rebirths tracker", 12, UDim2.fromOffset(16, 34), true)
        local body = text(card, "loading...", 13, UDim2.fromOffset(16, 54), true)
        task.spawn(function()
            while alive do
                pcall(function()
                    local strength, rebirths = leaderstats()
                    if strength and rebirths then
                        local req = requiredRebirthStrength(rebirths.Value)
                        body.Text = string.format(
                            "Strength: %s   Rebirths: %s\nNext rebirth at: %s strength",
                            tostring(strength.Value), tostring(rebirths.Value), req and tostring(req) or "?")
                    end
                end)
                task.wait(1)
            end
        end)
    end
end

local hubTab = host.CreateTab()

do
    local s = hubTab:AddSection("TRAIN • Training", "machine automation")
    local names = {}
    for _, m in ipairs(MACHINES) do names[#names + 1] = m.label end
    s:AddDropdown("Machine", names, function(v) S.machine = v end)
    s:AddToggle("Auto Train (mount + reps)", function(v)
        S.autoTrain = v
        if v then startTrainLoop() else trainState.mounted = false leaveMachine() pumpGens.n += 1 end
    end)
    s:AddSlider("Rep rate (per second)", 2, 25, 10, function(v) S.repRate = v end)
    local s2 = hubTab:AddSection("TRAIN • Fists", "empty hand training")
    s2:AddToggle("Auto Punch", function(v)
        S.autoPunch = v
        if v then startPunchLoop() end
    end)
end

do
    local s = hubTab:AddSection("FARM • Full Train", "rotate best machines")
    local ftNames = {}
    for _, a in ipairs(FULLTRAIN_AREAS) do ftNames[#ftNames + 1] = a.section end
    s:AddDropdown("Area", ftNames, function(v) S.fullTrainArea = v end)
    s:AddToggle("Full Train (rotate machines)", function(v)
        S.fullTrain = v
        if v then startFullTrain() end
    end)

    local r = hubTab:AddSection("FARM • Rebirths", "automatic and instant")
    r:AddToggle("Auto Rebirth (at requirement)", function(v)
        S.autoRebirth = v
        if v then startRebirthLoop() end
    end)
    r:AddButton("Rebirth now", function()
        local rem = remote("rebirthRemote")
        if rem and rem:IsA("RemoteFunction") then
            local ok = pcall(rem.InvokeServer, rem, "rebirthRequest")
            Notify(ok and "Rebirth request sent" or "Rebirth failed", 2)
        else
            Notify("Rebirth unavailable", 2)
        end
    end)

    local w = hubTab:AddSection("FARM • Rewards", "gifts, quests, daily, chests")
    w:AddToggle("Auto claim gifts & quests", function(v)
        S.autoRewards = v
        if v then startRewardsLoop() end
    end)
    w:AddButton("Redeem all codes (eggs)", function() redeemCodes() end)
    w:AddToggle("Auto map chests (teleport claim)", function(v)
        S.autoChests = v
        if v then startChestLoop() end
    end)

    local b = hubTab:AddSection("FARM • Consumables", "buffs upkeep")
    b:AddToggle("Auto eat Protein Egg (30m buff)", function(v)
        S.autoEgg = v
        if v then startEggLoop() end
    end)
end

do
    local s = hubTab:AddSection("COMBAT • Rocks", "durability breaking")
    local rockNames = {}
    for i = #ROCKS, 1, -1 do rockNames[#rockNames + 1] = ROCKS[i].label end
    s:AddDropdown("Rock", rockNames, function(v) S.selectedRock = v end)
    S.selectedRock = ROCKS[#ROCKS].label
    s:AddToggle("Auto smash rock", function(v)
        S.autoRock = v
        if v then startRockLoop() end
    end)

    local k = hubTab:AddSection("COMBAT • Brawl", "Kills")
    k:AddToggle("Auto Brawl (join + fight)", function(v)
        S.autoBrawl = v
        if v then startBrawlLoop() end
    end)

    local b = hubTab:AddSection("COMBAT • Boss", "event arena farm")
    b:AddToggle("Auto Boss (event arena)", function(v)
        S.autoBoss = v
        if v then startBossLoop() end
    end)
end

do
    local s = hubTab:AddSection("SHOP • Pet Shop", "author module loader")
    s:AddDropdown("Pet", PET_NAMES, function(v) S.petChoice = v end)
    S.petChoice = PET_NAMES[1]
    s:AddButton("Buy selected pet", function()
        task.spawn(function()
            local mod, err = ensurePetShop()
            if not mod then Notify("Pet module failed: " .. tostring(err), 3) return end
            if mod.SelectPet then pcall(mod.SelectPet, S.petChoice) end
            local ok = pcall(mod.BuyPet)
            Notify(ok and "Pet purchase sent" or "Pet purchase failed", 2.5)
        end)
    end)
    s:AddToggle("Auto buy pets", function(v)
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
    s:AddDropdown("Aura", AURA_NAMES, function(v) S.auraChoice = v end)
    S.auraChoice = AURA_NAMES[1]
    s:AddButton("Buy selected aura", function()
        task.spawn(function()
            local mod, err = ensurePetShop()
            if not mod then Notify("Pet module failed: " .. tostring(err), 3) return end
            if mod.SelectAura then pcall(mod.SelectAura, S.auraChoice) end
            local ok = pcall(mod.BuyAura)
            Notify(ok and "Aura purchase sent" or "Aura purchase failed", 2.5)
        end)
    end)
    s:AddToggle("Auto buy auras", function(v)
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

    local inv = hubTab:AddSection("SHOP • Inventory", "pets management")
    inv:AddButton("Equip all owned pets", function()
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

    local f = hubTab:AddSection("SHOP • Fortune Wheel", "Ruleta")
    f:AddToggle("Auto spin wheel", function(v)
        S.autoFortune = v
        if v then startFortuneLoop() end
    end)

    local g = hubTab:AddSection("SHOP • Gifts", "send items to players")
    local function refreshPlayers()
        local names = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LP then names[#names + 1] = pl.Name end
        end
        table.sort(names)
        if #names == 0 then names = { "(alone)" } end
        return names
    end
    local pdd = g:AddDropdown("Player", refreshPlayers(), function(v)
        if v ~= "(alone)" then S.giftTarget = v end
    end)
    g:AddButton("Refresh player list", function()
        pdd.Refresh(refreshPlayers())
        Notify("Player list refreshed", 1.5)
    end)
    g:AddDropdown("Item", { "Protein Egg", "Tropical Shake" }, function(v) S.giftItem = v end)
    g:AddSlider("Amount", 1, 50, 1, function(v) S.giftAmount = math.floor(v) end)
    g:AddButton("Send gifts", function()
        if S.giftBusy then Notify("Already sending, please wait", 2) return end
        if not S.giftTarget then Notify("Select a player first", 2) return end
        local target = Players:FindFirstChild(S.giftTarget)
        if not target then Notify("Player left the server", 2) return end
        if not (giftRemote and giftRemote:IsA("RemoteFunction")) then Notify("Gift system unavailable", 2) return end
        local items = getGiftableItems(S.giftItem)
        if #items == 0 then Notify("No " .. S.giftItem .. " in inventory", 2) return end
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
            if sent > 0 then Notify("Sent " .. sent .. "x " .. S.giftItem .. " to " .. target.Name, 2.5) end
            S.giftBusy = false
        end)
    end)

    local c = hubTab:AddSection("SHOP • Event Crystals", "event currency exchange")
    c:AddDropdown("Crystal", { CRYSTALS[1].name, CRYSTALS[2].name }, function(v) S.crystalName = v end)
    c:AddDropdown("Amount", { "1", "5", "10" }, function(v) S.crystalAmount = tonumber(v) or 1 end)
    c:AddButton("Open crystal now", function()
        local ok, msg = openCrystalNow(math.max(1, S.crystalAmount))
        Notify((ok and "Opened: " or "Failed: ") .. tostring(msg), 2.5)
    end)
    c:AddToggle("Auto open crystals", function(v)
        S.autoCrystal = v
        if v then startCrystalLoop() end
    end)
end

do
    local t = hubTab:AddSection("MISC • Teleport", "gyms & areas")
    local tpNames = {}
    for _, a in ipairs(FULLTRAIN_AREAS) do tpNames[#tpNames + 1] = a.section end
    local tpSel = FULLTRAIN_AREAS[4].section
    t:AddDropdown("Area", tpNames, function(v) tpSel = v end)
    t:AddButton("Teleport to area", function()
        local area
        for _, a in ipairs(FULLTRAIN_AREAS) do
            if a.section == tpSel then area = a break end
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

    local p = hubTab:AddSection("MISC • Player", "character modifiers")
    p:AddSlider("WalkSpeed", 16, 200, 16, function(v)
        local _, hum = charParts()
        if hum then hum.WalkSpeed = v end
    end)
    p:AddSlider("JumpPower", 50, 300, 50, function(v)
        local _, hum = charParts()
        if hum then hum.JumpPower = v end
    end)
    p:AddSlider("Character size", 1, 100, 1, function(v)
        local rem = remote("changeSpeedSizeRemote")
        if rem and rem:IsA("RemoteFunction") then
            task.spawn(function() pcall(rem.InvokeServer, rem, "changeSize", v) end)
        elseif rem and rem:IsA("RemoteEvent") then
            pcall(rem.FireServer, rem, "changeSize", v)
        end
    end)

    local pf = hubTab:AddSection("MISC • Performance", "visual load reduction")
    pf:AddToggle("Hide my pets", function(v)
        local rem = remote("showPetsEvent")
        local currentlyVisible = LP:GetAttribute("PetsVisible") == true
        if currentlyVisible == v and rem and rem:IsA("RemoteEvent") then
            pcall(rem.FireServer, rem, v and "hidePets" or "showPets")
        end
        Notify(v and "Pets hidden" or "Pets visible", 1.5)
    end)
    pf:AddToggle("Hide damage popups", function(v)
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
    pf:AddToggle("FPS Boost (no 3D render)", function(v)
        pcall(function()
            RunService:Set3dRenderingEnabled(not v)
        end)
        Notify(v and "3D rendering disabled" or "3D rendering enabled", 2)
    end)

    local st = hubTab:AddSection("MISC • Settings", "hub controls")
    st:AddToggle("Anti-AFK", function(v) setAntiAfk(v) end)
    st:AddButton("Unload Noir", function()
        alive = false
        pcall(function() penv.__NoirMLLoaded = false end)
        pcall(function()
            local lock = penv.__NoirHubRuntimeLock
            if type(lock) == "table" then lock.state = "stopped" end
        end)
        pcall(function() __core.gui:Destroy() end)
    end)
end

if __core.gui and __core.gui.Destroying then
    __core.gui.Destroying:Connect(function() alive = false end)
end

task.spawn(function()
    local env = (type(getgenv) == "function" and getgenv()) or _G
    env.__NoirHubRuntimeLock = { state = "running", startedAt = os.clock(), heartbeat = os.clock(), game = "MuscleLegends" }
    while alive do
        task.wait(5)
        if env.__NoirHubRuntimeLock then env.__NoirHubRuntimeLock.heartbeat = os.clock() end
    end
end)

Notify("Noir Muscle Legends loaded", 2.5)
