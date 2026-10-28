-- lxdump v2 — живой демп цепочки. Без жёстких зависимостей на task/delay:
-- если их нет, скан идёт по событию (каждый 5-й чанк) и вручную через LXD_SCAN().
-- Запуск: 1) этот файл, 2) loader, 3) ждёшь, 4) забираешь workspace/IxryDump/*

if getgenv()._LXD_ON then warn("[lxdump] уже запущен, хуки стоят"); return end
getgenv()._LXD_ON = true

local W = writefile
local OK = function(f, ...) local r = {pcall(f, ...)} return unpack(r) end
pcall(makefolder, "IxryDump")
OK(W, "IxryDump/_log.txt", ("[lxdump v2] start %s\n"):format(os.time()))

local LOG = function(s)
    OK(appendfile, "IxryDump/_log.txt", s .. "\n")
    warn(s)
end

-- ===== 1. чанки: СДВОЕННЫЙ захват (hookfunction И обёртка глобала) =====
local chunkN = 0
local seen = {}
local function dumpChunk(src, tag)
    if type(src) ~= "string" or #src < 4 then return end
    local sig = #src .. ":" .. src:sub(1, 48)
    if seen[sig] then return end
    seen[sig] = true
    chunkN = chunkN + 1
    local f = ("IxryDump/chunk_%03d_%s.lua"):format(chunkN, tag or "n")
    OK(W, f, src)
    LOG(("[lxdump] chunk #%d (%d байт, %s)"):format(chunkN, #src, tag or "?"))
    -- каждый 5-й чанк — мини-скан (на случай отсутствия task)
    if chunkN % 5 == 0 then OK(scanMem, "auto") end
end

do
    local raw_ls = loadstring
    local hooked = false
    if hookfunction then
        local ok, old = pcall(hookfunction, loadstring, function(src, ...)
            OK(dumpChunk, src, "ls")
            return old(src, ...)
        end)
        if ok then raw_ls = old; hooked = true; LOG("[lxdump] hookfunction(loadstring) ок") end
    end
    getgenv().loadstring = function(src, ...)
        OK(dumpChunk, src, "lsf")
        return raw_ls(src, ...)
    end
    if hooked then LOG("[lxdump] плюс обёртка getgenv().loadstring") else LOG("[lxdump] только обёртка глобала") end
end

-- ===== 2. HTTP: url+body каждой скачки =====
local httpN = 0
local function saveHttp(tag, url, body)
    httpN = httpN + 1
    OK(appendfile, "IxryDump/urls.txt", ("%s\t%s\t%s байт\n"):format(tag, tostring(url), body and #body or -1))
    if body and #body > 60 then
        local f = ("IxryDump/http_%03d.lua"):format(httpN)
        OK(W, f, ("-- URL: %s (via %s)\n"):format(tostring(url), tag) .. body)
        LOG(("[lxdump] http #%d %s (%d байт)"):format(httpN, tostring(url), #body))
    end
    OK(dumpChunk, body, "http") -- скачанный код = потенциальный чанк
end

if hookfunction then
    pcall(function()
        local old_hg = hookfunction(game.HttpGet, function(self, url, ...)
            local b = old_hg(self, url, ...)
            OK(saveHttp, "HttpGet", url, b)
            return b
        end)
        local old_hga = hookfunction(game.HttpGetAsync, function(self, url, ...)
            local b = old_hga(self, url, ...)
            OK(saveHttp, "HttpGetAsync", url, b)
            return b
        end)
    end)
    LOG("[lxdump] http-хуки поставлены")
else
    LOG("[lxdump] hookfunction отсутствует — http НЕ перехватывается")
end

-- ===== 3. скан памяти на строки фич =====
local KEYS = {
    "silent", "aim", "esp", "raycast", "hitbox", "noclip", "fly",
    "speed", "teleport", "god", "kill", "sheriff", "murder", "innocent",
    "camera", "mouse", "players", "head", "torso", "chams", "tracer",
    "fov", "trigger", "flick", "prediction", "autoshoot", "pickup",
    "hwid", "discord", "webhook", "license", "key"
}
local function kwHit(s)
    local l, hits = s:lower(), {}
    for _, k in ipairs(KEYS) do
        if l:find(k, 1, true) then hits[#hits + 1] = k end
    end
    if #hits > 0 then return table.concat(hits, ",") end
end

function scanMem(reason)
    LOG("[lxdump] ===== скан памяти (" .. tostring(reason) .. ") =====")
    local out, seenS, seenT = {}, {}, {}
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
                        local plain, n = {}, 0
                        for k, v in pairs(x) do
                            n = n + 1
                            if n > 600 then break end
                            local ks, vs = tostring(k), (type(v) == "string" and v or tostring(v))
                            if #ks < 200 and #vs < 500 then
                                local h = kwHit(ks) or kwHit(vs)
                                if h then plain[#plain + 1] = ("%s = %q"):format(ks, vs) end
                            end
                        end
                        if #plain > 0 then out[#out + 1] = "[TABLE] " .. table.concat(plain, " | ") end
                    end)
                end
            end
        end
    else
        LOG("[lxdump] getgc отсутствует")
    end
    local getconst = getconstants or (debug and debug.getconstants)
    if getconst and getgc then
        local fnN, kwN = 0, 0
        for _, x in ipairs((getgc(false) or {})) do
            if type(x) == "function" and fnN < 2500 and not (iscclosure and iscclosure(x)) then
                fnN = fnN + 1
                OK(function()
                    local hits = {}
                    for _, c in ipairs(getconst(x)) do
                        if type(c) == "string" then
                            local h = kwHit(c)
                            if h then hits[#hits + 1] = ("{%s}%q"):format(h, c) end
                        end
                    end
                    if #hits > 0 then
                        kwN = kwN + 1
                        out[#out + 1] = ("[FN #%d] %s"):format(kwN, table.concat(hits, " ; "))
                    end
                end)
            end
        end
        LOG(("[lxdump] функций: %d, с ключами: %d"):format(fnN, kwN))
    end
    OK(appendfile, "IxryDump/keywords.txt", table.concat(out, "\n") .. "\n")
    local all = {}
    for s in pairs(seenS) do if #s >= 6 and #s <= 120 then all[#all + 1] = s end end
    table.sort(all)
    OK(appendfile, "IxryDump/strings_all.txt", table.concat(all, "\n") .. "\n")
    LOG(("[lxdump] скан готов: %d хитов, %d строк"):format(#out, #all))
end
getgenv().LXD_SCAN = scanMem

-- forward-decl fix: dumpChunk ссылается на scanMem, объявляем до использования
-- (в Luau глобальная scanMem доступна и в dumpChunk — порядок файла уже это гарантирует на момент вызова)

-- ===== 4. таймеры, если есть =====
local dl = (task and task.delay) or delay
if dl then
    pcall(dl, 10, function() scanMem("t10") end)
    pcall(dl, 25, function() scanMem("t25") end)
    pcall(dl, 45, function() scanMem("t45"); LOG("[lxdump] ===== финиш. забирай IxryDump =====") end)
    LOG("[lxdump] таймеры на 10/25/45 сек стоят")
else
    LOG("[lxdump] task/delay НЕТ — скан идёт сам каждый 5-й чанк; вручную: LXD_SCAN()")
end

LOG("[lxdump] v2 готов, жду loader")
print("[lxdump v2] on. после loader'а жди 45 сек или выполни LXD_SCAN()")
