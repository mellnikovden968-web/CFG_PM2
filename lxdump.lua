-- lxdump.lua — живой демп цепочки Ixry/loadstring.
-- Запуск: 1) этот файл, 2) потом твой loader (stage_1). Ждёшь 30 сек, забираешь workspace/IxryDump/*
-- Ничего не кикает, не репортирует, только пишет файлы.

if getgenv()._LXD_ON then warn("[lxdump] уже запущен"); return end
getgenv()._LXD_ON = true

local W = writefile
local AF = appendfile or function(p, s)
    local ok, old = pcall(function() return readfile(p) end)
    W(p, (ok and old or "") .. s)
end
local OK = function(f, ...) local r = {pcall(f, ...)} return unpack(r) end

pcall(makefolder, "IxryDump")
W("IxryDump/_log.txt", ("[lxdump] start %s\n"):format(os.time()))

local LOG = function(s)
    OK(appendfile, "IxryDump/_log.txt", s .. "\n")
    warn(s)
end

-- ---------------------------------------------------------------
-- 1. Перехват loadstring / load: каждый загружаемый чанк уходит на диск
-- ---------------------------------------------------------------
local chunkN = 0
local function dumpChunk(src, tag)
    chunkN = chunkN + 1
    local f = ("IxryDump/chunk_%03d_%s.lua"):format(chunkN, tag or "n")
    OK(W, f, src)
    LOG(("[lxdump] chunk #%d (%d байт, %s) -> %s"):format(chunkN, #src, tag or "?", f))
end

if hookfunction then
    local old_ls = hookfunction(loadstring, function(src, ...)
        local ok, s = OK(tostring, src)
        if ok and type(s) == "string" and #s > 200 then
            dumpChunk(s, "ls")
        end
        return old_ls(src, ...)
    end)
    getgenv()._LXD_LS = old_ls
    LOG("[lxdump] loadstring захукан")
else
    local raw_ls = loadstring
    getgenv().loadstring = function(src, ...)
        pcall(function() if type(src) == "string" and #src > 200 then dumpChunk(src, "lsf") end end)
        return raw_ls(src, ...)
    end
    LOG("[lxdump] hookfunction нет, loadstring завёрнут напрямую")
end

-- ---------------------------------------------------------------
-- 2. Перехват HTTP: URL и тело каждого ответа (там следующий слой/payload)
-- ---------------------------------------------------------------
local httpN = 0
local function saveHttp(tag, url, body)
    httpN = httpN + 1
    OK(AF, "IxryDump/urls.txt", ("%s\t%s\t%d байт\n"):format(tag, tostring(url), body and #body or -1))
    if body and #body > 60 then
        local f = ("IxryDump/http_%03d.lua"):format(httpN)
        OK(W, f, ("-- URL: %s\n-- method: %s\n"):format(tostring(url), tag) .. body)
        LOG(("[lxdump] http #%d %s (%d байт)"):format(httpN, tostring(url), #body))
    end
end

if hookfunction then
    local old_hg = hookfunction(game.HttpGet, function(self, url, ...)
        local body = old_hg(self, url, ...)
        OK(saveHttp, "HttpGet", url, body)
        return body
    end)
    local old_hga = hookfunction(game.HttpGetAsync, function(self, url, ...)
        local body = old_hga(self, url, ...)
        OK(saveHttp, "HttpGetAsync", url, body)
        return body
    end)
    getgenv()._LXD_HG, getgenv()._LXD_HGA = old_hg, old_hga
    LOG("[lxdump] HttpGet/HttpGetAsync захуканы")
end

-- RequestAsync (если есть)
if hookfunction and (game.RequestAsync or game.HttpPostAsync) then
    pcall(function()
        local old_ra = hookfunction(game.RequestAsync or game.HttpPostAsync, function(self, req, ...)
            local resp = old_ra(self, req, ...)
            OK(saveHttp, "RequestAsync", req and req.Url, resp and (resp.Body or tostring(resp)))
            return resp
        end)
        getgenv()._LXD_RA = old_ra
        LOG("[lxdump] RequestAsync захукан")
    end)
end

-- ---------------------------------------------------------------
-- 3. Пост-скан памяти: расшифрованные строки фич по ключевым словам
-- ---------------------------------------------------------------
local KEYS = {
    "silent", "aim", "esp", "raycast", "hitbox", "noclip", "fly",
    "speed", "teleport", "god", "kill", "sheriff", "murder", "innocent",
    "knife", "gun", "camera", "mouse", "players", "character", "head",
    "torso", "wall", "chams", "box", "tracer", "fov", "trigger", "flick",
    "prediction", "autoshoot", "pickup", "drop", "key", "hwid", "discord",
    "webhook", "http", "token", "id", "license"
}

local function kwHit(s)
    local l = s:lower()
    local hits = {}
    for _, k in ipairs(KEYS) do
        if l:find(k, 1, true) then hits[#hits + 1] = k end
    end
    if #hits > 0 then return table.concat(hits, ",") end
    return nil
end

local scanned = false
local function scanMem()
    if scanned then return end
    scanned = true
    LOG("[lxdump] ===== скан памяти (getgc) =====")
    local out = {}
    local seenS, seenT = {}, {}

    -- 3a. строки в таблицах (расшифрованные конфиги)
    if getgc then
        local ok, gc = pcall(getgc, true)
        if ok then
            for _, x in ipairs(gc) do
                local tx = type(x)
                if tx == "string" and #x >= 4 and #x <= 4000 then
                    if not seenS[x] then
                        seenS[x] = true
                        local h = kwHit(x)
                        if h then out[#out + 1] = ("[STR %s] %s"):format(h, x) end
                    end
                elseif tx == "table" and not seenT[x] then
                    seenT[x] = true
                    OK(function()
                        local plain = {}
                        local n = 0
                        for k, v in pairs(x) do
                            n = n + 1
                            if n > 600 then break end
                            local ks, vs = tostring(k), (type(v) == "string" and v or tostring(v))
                            if #ks < 200 and #vs < 500 then
                                local h = kwHit(ks) or kwHit(vs)
                                if h then plain[#plain + 1] = ("%s = %q"):format(ks, vs) end
                            end
                        end
                        if #plain > 0 then
                            out[#out + 1] = "[TABLE] " .. table.concat(plain, " | ")
                        end
                    end)
                end
            end
        end
        LOG("[lxdump] таблиц/строк пробито: " .. #out)
    end

    -- 3b. константы функций: debug.getconstants
    local fnScanned, kwFns = 0, 0
    local getconst = getconstants or (debug and debug.getconstants)
    if getconst then
        for _, x in ipairs((getgc and getgc(false)) or {}) do
            if type(x) == "function" and iscclosure and not iscclosure(x) and fnScanned < 2500 then
                fnScanned = fnScanned + 1
                OK(function()
                    local cs = getconst(x)
                    local hits = {}
                    for _, c in ipairs(cs) do
                        if type(c) == "string" then
                            local h = kwHit(c)
                            if h then hits[#hits + 1] = ("{%s}%q"):format(h, c) end
                        end
                    end
                    if #hits > 0 then
                        kwFns = kwFns + 1
                        out[#out + 1] = ("[FN #%d %s] %s"):format(kwFns, tostring(x):gsub("function: 0x", "0x"), table.concat(hits, " ; "))
                    end
                end)
            end
        end
        LOG(("[lxdump] функций просмотрено: %d, с ключами: %d"):format(fnScanned, kwFns))
    else
        LOG("[lxdump] getconstants нет, секция 3b пропущена")
    end

    W("IxryDump/keywords.txt", table.concat(out, "\n"))
    LOG(("[lxdump] keywords.txt записан (%d строк)"):format(#out))

    -- 3c. просто все непустые строки длиной 6..120 (сырой срез)
    local all = {}
    for s in pairs(seenS) do
        if #s >= 6 and #s <= 120 then all[#all + 1] = s end
    end
    table.sort(all)
    W("IxryDump/strings_all.txt", table.concat(all, "\n"))
    LOG(("[lxdump] strings_all.txt: %d строк"):format(#all))
end

-- запуск скана: сразу через 12 сек, потом повторно через 25 (после полной расшифровки payload)
task.delay(12, scanMem)
task.delay(25, function() scanned = false; scanMem() end)
task.delay(40, function() LOG("[lxdump] ===== готово. Забирай файлы из workspace/IxryDump/ ====="); pcall(print, "[lxdump] готово") end)

LOG("[lxdump] хуки стоят, жду запуск loader'а")
