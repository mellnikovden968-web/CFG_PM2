--// stage2 bytecode dumper | runtime: Delta, Luau
--// запуск: сначала tracer, потом ЭТОТ файл, потом таргет
--// снимает каждый loadstring в отдельный файл + байткод через getscriptbytecode

local LOG_FOLDER = "logdump"
pcall(function() if makefolder and not isfolder(LOG_FOLDER) then makefolder(LOG_FOLDER) end end)

local function w(path, data)
    if writefile then pcall(writefile, path, data) end
end
local function a(path, s)
    s = tostring(s)
    if appendfile then pcall(appendfile, path, s)
    elseif writefile then
        local old = ""
        if isfile and isfile(path) then pcall(function() old = readfile(path) end) end
        pcall(writefile, path, old .. s)
    end
end

local META = LOG_FOLDER .. "/stage2_meta.log"
local n = 0

local origLS = loadstring
local origLoad = load

local function dumpOne(tag, chunk, src)
    n += 1
    src = tostring(src or "")
    local id = n
    a(META, "[LOAD] #" .. id .. " tag=" .. tostring(tag) .. " chunk=" .. tostring(chunk) .. " len=" .. #src .. "\n")
    -- каждый чанк в СВОЙ файл, ничего не перезаписывается
    w(LOG_FOLDER .. "/stage_" .. id .. ".lua", src)
    return id
end

local function tryBytecode(fn, id, chunk)
    if getscriptbytecode and type(fn) == "function" then
        local ok, bc = pcall(getscriptbytecode, fn)
        if ok and type(bc) == "string" and #bc > 0 then
            w(LOG_FOLDER .. "/bytecode_" .. id .. ".luac", bc)
            a(META, "[BC] #" .. id .. " chunk=" .. tostring(chunk) .. " bclen=" .. #bc .. "\n")
        else
            a(META, "[BC FAIL] #" .. id .. " " .. tostring(bc):sub(1, 200) .. "\n")
        end
    end
end

if origLS then
    getgenv().loadstring = function(src, chunk, ...)
        local id = dumpOne("loadstring", chunk, src)
        local fn, err = origLS(src, chunk, ...)
        if fn then tryBytecode(fn, id, chunk) end
        return fn, err
    end
end
if origLoad then
    getgenv().load = function(src, chunk, ...)
        local id = dumpOne("load", chunk, src)
        local fn, err = origLoad(src, chunk, ...)
        if fn then tryBytecode(fn, id, chunk) end
        return fn, err
    end
end

a(META, "=== STAGE2 ON " .. os.date("%H:%M:%S") .. " ===\n")
print("[stage2] on. жду таргет. каждый loadstring -> stage_N.lua + bytecode_N.luac")
