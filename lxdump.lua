-- lxdump v3 — минимальный след: БЕЗ hookfunction (его ловит анти-тампер).
-- Только обёртка loadstring (как в твоём рабочем дампере) + скан памяти + прото-дамп.
-- Запуск: 1) этот файл, 2) ждёшь "готов", 3) loader/официальный скрипт, 4) 60 сек, 5) забираешь IxryDump/*

if getgenv()._LXD_ON then warn("[lxdump] уже запущен"); return end
getgenv()._LXD_ON = true

local OK = function(f, ...) local r = {pcall(f, ...)} return unpack(r) end
pcall(makefolder, "IxryDump")
OK(writefile, "IxryDump/_log.txt", ("[lxdump v3] start %s\n"):format(os.time()))
local LOG = function(s)
    OK(appendfile, "IxryDump/_log.txt", s .. "\n")
    warn(s)
end

-- ===== память =====
local KEYS = {"silent","aim","esp","raycast","hitbox","noclip","fly","speed",
    "teleport","kill","sheriff","murder","innocent","camera","mouse","head",
    "torso","chams","tracer","fov","trigger","flick","prediction","autoshoot",
    "pickup","hwid","webhook","license","whitelisted","role","target","shoot"}
local function kwHit(s)
    local l, hits = s:lower(), {}
    for _, k in ipairs(KEYS) do
        if l:find(k, 1, true) then hits[#hits + 1] = k end
    end
    if #hits > 0 then return table.concat(hits, ",") end
end

local protoN = 0
function scanMem(reason)
    LOG("[lxdump] скан памяти (" .. tostring(reason) .. ")")
    local out, seenS = {}, {}
    if getgc then
        local ok, gc = pcall(getgc, true)
        if ok then
            for _, x in ipairs(gc) do
                local tx = type(x)
                if tx == "string" and #x >= 4 and #x <= 2000 and not seenS[x] then
                    seenS[x] = true
                    local h = kwHit(x)
                    if h then out[#out + 1] = ("[STR %s] %s"):format(h, x) end
                end
            end
        end
        -- прото-дамп: все Луа-функции с константами под ключи
        local getconst = getconstants or (debug and debug.getconstants)
        local getproto = debug and debug.getproto
        if getconst then
            local fnN, kwN = 0, 0
            for _, x in ipairs((getgc(false) or {})) do
                if type(x) == "function" and fnN < 3000 and not (iscclosure and iscclosure(x)) then
                    fnN = fnN + 1
                    OK(function()
                        local hits = {}
                        for _, c in ipairs(getconst(x)) do
                            if type(c) == "string" and #c >= 3 and #c <= 300 then
                                local h = kwHit(c)
                                if h then hits[#hits + 1] = ("{%s}%q"):format(h, c) end
                            end
                        end
                        if #hits > 0 then
                            kwN = kwN + 1
                            protoN = protoN + 1
                            out[#out + 1] = ("[FN #%d] %s"):format(kwN, table.concat(hits, " ; "))
                            -- полный дамп функции: константы + информация
                            local dump = {("-- FN #%d  %s"):format(protoN, tostring(x))}
                            OK(function() dump[#dump + 1] = "consts: " .. table.concat((function()
                                local t = {}
                                for i, c in ipairs(getconst(x) or {}) do
                                    t[i] = ("%d=%q"):format(i, tostring(c))
                                end
                                return t
                            end)(), " | ") end)
                            if getproto then
                                OK(function()
                                    for i = 1, 40 do
                                        local p = getproto(x, i)
                                        if not p then break end
                                        dump[#dump + 1] = ("-- proto %d: %s"):format(i, tostring(p))
                                    end
                                end)
                            end
                            OK(writefile, ("IxryDump/proto_%03d.txt"):format(protoN), table.concat(dump, "\n"))
                        end
                    end)
                end
            end
            LOG(("[lxdump] ф-ций: %d, ключевых: %d"):format(fnN, kwN))
        end
        local all = {}
        for s in pairs(seenS) do if #s >= 5 and #s <= 160 then all[#all + 1] = s end end
        table.sort(all)
        OK(appendfile, "IxryDump/strings_" .. tostring(reason) .. ".txt", table.concat(all, "\n") .. "\n")
    else
        LOG("[lxdump] getgc отсутствует")
    end
    OK(appendfile, "IxryDump/keywords_" .. tostring(reason) .. ".txt", table.concat(out, "\n") .. "\n")
end
getgenv().LXD_SCAN = scanMem

-- ===== обёртка loadstring: чанки + аргументы-ключи =====
local chunkN = 0
local raw_ls = loadstring
getgenv().loadstring = function(src, ...)
    local argv = {...}
    OK(function()
        if type(src) == "string" and #src > 4 then
            chunkN = chunkN + 1
            local f = ("IxryDump/chunk_%03d.lua"):format(chunkN)
            OK(writefile, f, src)
            local args = {}
            for i, v in ipairs(argv) do args[#args + 1] = ("arg%d=%q"):format(i, tostring(v)) end
            OK(appendfile, "IxryDump/_chain.log",
                ("[%s] chunk #%d len=%d %s\n"):format(os.date("%H:%M:%S"), chunkN, #src, table.concat(args, " ")))
            LOG(("[lxdump] chunk #%d (%d байт)"):format(chunkN, #src))
            if chunkN == 3 then OK(scanMem, "chain3") end
            if chunkN % 4 == 0 then OK(scanMem, "auto" .. chunkN) end
        end
    end)
    return raw_ls(src, ...)
end
LOG("[lxdump] loadstring обёрнут (без hookfunction)")

-- таймеры
local dl = (task and task.delay) or delay
if dl then
    OK(dl, 20, function() scanMem("t20") end)
    OK(dl, 40, function() scanMem("t40") end)
    OK(dl, 60, function() scanMem("t60"); LOG("[lxdump] финиш") end)
else
    LOG("[lxdump] delay нет — скан по чанкам + LXD_SCAN()")
end

LOG("[lxdump] v3 готов, жди 60 сек после запуска loader'а, потом архивируй IxryDump")
print("[lxdump v3] on")
