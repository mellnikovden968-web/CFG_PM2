-- lxdump v4 — под меню выбора игры: ловит чанки + HTTP (через __namecall,
-- БЕЗ hookfunction на C-функции — анти-тампер не трогаем в C).
-- Порядок: 1) этот файл -> "вкл", 2) запусти loader, 3) ВЫБЕРИ ИГРУ в меню,
--          4) жди ~90 сек после выбора, 5) забирай весь IxryDump архивом.

if getgenv()._LXD_ON then warn("[lxdump] уже запущен"); return end
getgenv()._LXD_ON = true

local OK = function(f, ...) local r = {pcall(f, ...)} return unpack(r) end
pcall(makefolder, "IxryDump")
OK(writefile, "IxryDump/_log.txt", ("[lxdump v4] start %s\n"):format(os.time()))
local LOG = function(s)
    OK(appendfile, "IxryDump/_log.txt", s .. "\n")
    warn(s)
end

-- ===== скан памяти (после загрузки основного скрипта) =====
local KEYS = {"silent","aim","esp","raycast","hitbox","noclip","fly","speed",
    "teleport","kill","sheriff","murder","innocent","camera","head","torso",
    "chams","tracer","fov","trigger","flick","prediction","autoshoot","pickup",
    "hwid","webhook","license","whitelisted","role","target","shoot","godmode"}
local function kwHit(s)
    local l, hits = s:lower(), {}
    for _, k in ipairs(KEYS) do
        if l:find(k, 1, true) then hits[#hits + 1] = k end
    end
    if #hits > 0 then return table.concat(hits, ",") end
end

function scanMem(tag)
    LOG("[lxdump] скан " .. tostring(tag))
    local out, seenS = {}, {}
    if getgc then
        local ok, gc = pcall(getgc, true)
        if ok then
            for _, x in ipairs(gc) do
                if type(x) == "string" and #x >= 4 and #x <= 2000 and not seenS[x] then
                    seenS[x] = true
                    local h = kwHit(x)
                    if h then out[#out + 1] = ("[%s] %s"):format(h, x) end
                end
            end
        end
        local getconst = getconstants or (debug and debug.getconstants)
        if getconst then
            local fnN, kwN = 0, 0
            for _, x in ipairs((pcall(getgc, false) and getgc(false)) or {}) do
                if type(x) == "function" and fnN < 3500 and not (iscclosure and iscclosure(x)) then
                    fnN = fnN + 1
                    OK(function()
                        local hits = {}
                        for _, c in ipairs(getconst(x) or {}) do
                            if type(c) == "string" and #c >= 3 and #c <= 300 then
                                local h = kwHit(c)
                                if h then hits[#hits + 1] = ("{%s}%q"):format(h, c) end
                            end
                        end
                        if #hits > 0 then
                            kwN = kwN + 1
                            out[#out + 1] = ("[FN %d] %s"):format(kwN, table.concat(hits, " ; "))
                        end
                    end)
                end
            end
            LOG(("[lxdump] ф-ций %d с ключами %d"):format(fnN, kwN))
        end
    end
    OK(writefile, ("IxryDump/keywords_%s.txt"):format(tag), table.concat(out, "\n"))
end

-- ===== обёртка loadstring =====
local chunkN = 0
local raw_ls = loadstring
getgenv().loadstring = function(src, ...)
    local argv = {...}
    OK(function()
        if type(src) == "string" and #src > 4 then
            chunkN = chunkN + 1
            OK(writefile, ("IxryDump/chunk_%03d.lua"):format(chunkN), src)
            local args = {}
            for i, v in ipairs(argv) do args[#args + 1] = ("arg%d=%q"):format(i, tostring(v)) end
            OK(appendfile, "IxryDump/_chain.log",
                ("[%s] #%d len=%d %s\n"):format(os.date("%H:%M:%S"), chunkN, #src, table.concat(args, " ")))
            LOG(("[lxdump] chunk #%d (%d байт)"):format(chunkN, #src))
        end
    end)
    if chunkN % 3 == 0 then OK(scanMem, "ch" .. chunkN) end
    return raw_ls(src, ...)
end
LOG("[lxdump] loadstring обёрнут")

-- ===== HTTP через __namecall (без hookfunction) =====
local httpN = 0
local function saveHttp(tag, url, body)
    httpN = httpN + 1
    OK(appendfile, "IxryDump/urls.txt", ("[%s] %s\t%s\t%s байт\n"):format(os.date("%H:%M:%S"), tag, tostring(url), body and #body or -1))
    if type(body) == "string" and #body > 30 then
        OK(writefile, ("IxryDump/http_%03d.lua"):format(httpN),
            ("-- URL: %s (via %s)\n"):format(tostring(url), tag) .. body)
        LOG(("[lxdump] HTTP #%d %s %s (%d байт)"):format(httpN, tag, tostring(url), #body))
    end
end

local httpOn = false
pcall(function()
    if hookmetamethod then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local args = {...}
            local method = getnamecallmethod and getnamecallmethod() or ""
            local res = old(self, ...)
            if self == game and (method == "HttpGet" or method == "HttpGetAsync") then
                OK(saveHttp, method, args[1], res)
            elseif method == "RequestAsync" then
                OK(function()
                    local req = args[1]
                    saveHttp("RequestAsync", (type(req) == "table" and req.Url) or req, type(res) == "table" and (res.Body) or nil)
                end)
            end
            return res
        end)
        httpOn = true
    end
end)
LOG("[lxdump] http перехват: " .. (httpOn and "да (__namecall)" or "НЕТ"))

-- таймеры
local dl = (task and task.delay) or delay
if dl then
    OK(dl, 30, function() scanMem("t30") end)
    OK(dl, 60, function() scanMem("t60") end)
    OK(dl, 90, function() scanMem("t90"); LOG("[lxdump] финиш — архивируй IxryDump") end)
else
    LOG("[lxdump] delay нет — скан по чанкам/вручную LXD_SCAN")
end
getgenv().LXD_SCAN = scanMem
LOG("[lxdump] v4 вкл: запускай loader, ВЫБИРАЙ ИГРУ, жди 90 сек")
print("[lxdump v4] вкл")
