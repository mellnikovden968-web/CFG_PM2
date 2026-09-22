local SR_UI = {
    separateTabs = false,
    title        = "SteelRework",
    icon         = "/mellnikovden968-web/CFG_PM2/refs/heads/main/icon",
    tagSubtitles = true,
    tab          = nil,
    services     = {},
}

function SR_UI.service(name)
    local cached = SR_UI.services[name]
    if cached then return cached end
    local ok, service = pcall(function() return game:GetService(name) end)
    if not ok or not service then
        ok, service = pcall(function() return game:FindService(name) end)
    end
    if not service then
        local fine, direct = pcall(function() return game[name] end)
        if fine then service = direct end
    end
    SR_UI.services[name] = service or false
    return service
end

local SR_TEXT_WIDTH = 58

local function SR_Paragraph(sec, title, text)
    if type(title) ~= "string" or type(text) ~= "string" then return end
    sec:AddLabel(title)
    local LINE_LEN_CACHE = {}
    local function lineLen(s)
        if LINE_LEN_CACHE[s] then return LINE_LEN_CACHE[s] end
        local ok, n = pcall(utf8.len, s)
        local result = (ok and n) or #s
        LINE_LEN_CACHE[s] = result
        return result
    end
    local line = ""
    for word in tostring(text):gmatch("%S+") do
        if line == "" then
            line = word
        elseif lineLen(line) + lineLen(word) + 1 <= SR_TEXT_WIDTH then
            line = line .. " " .. word
        else
            sec:AddLabel(line)
            line = word
        end
    end
    if line ~= "" then sec:AddLabel(line) end
end

local SR_Rota = { list = {}, byObj = {}, conn = nil, RunService = nil }
function SR_Rota.Attach(obj, maid, speed)
    local stub = {}
    stub.Destroy = function() end
    stub.Disconnect = stub.Destroy
    if not obj then return stub end
    local existing = SR_Rota.byObj[obj]
    if existing then return existing.handle end
    local entry = { obj = obj, speed = speed or 60, accum = 0, alive = true }
    local handle = {}
    function handle.Destroy()
        if not entry.alive then return end
        entry.alive = false
        SR_Rota.byObj[obj] = nil
        local list = SR_Rota.list
        entry.markedForRemoval = true
        local list = SR_Rota.list
        local writeIdx = 1
        for j = 1, #list do
            if not list[j].markedForRemoval then
                list[writeIdx] = list[j]
                writeIdx = writeIdx + 1
            end
        end
        for j = writeIdx, #list do list[j] = nil end

        if #list == 0 and SR_Rota.conn then
            SR_Rota.conn:Disconnect()
            SR_Rota.conn = nil
        end
    end
    handle.Disconnect = handle.Destroy
    entry.handle = handle
    SR_Rota.byObj[obj] = entry
    SR_Rota.list[#SR_Rota.list + 1] = entry
    if not SR_Rota.conn then
        if not SR_Rota.RunService then SR_Rota.RunService = SR_UI.service("RunService") end
        local frameSkip = 2
        local frameCount = 0
        SR_Rota.conn = SR_Rota.RunService.RenderStepped:Connect(function(dt)
            frameCount = frameCount + 1
            if frameCount < frameSkip then return end
            frameCount = 0
            local list = SR_Rota.list
            local i = 1
            while i <= #list do
                local e = list[i]
                local target = e.obj
                if not e.alive or not target or not target.Parent then
                    if target then SR_Rota.byObj[target] = nil end
                    table.remove(list, i)
                else
                    e.accum = e.accum + dt * e.speed
                    if e.accum >= 1 then
                        target.Rotation = (target.Rotation + e.accum) % 360
                        e.accum = 0
                    end
                    i = i + 1
                end
            end
            if #list == 0 and SR_Rota.conn then
                SR_Rota.conn:Disconnect()
                SR_Rota.conn = nil
            end
        end)
    end
    if maid then maid:GiveTask(handle) end
    return handle
end

local SR_Store = { W = {}, R = {}, D = {}, F = {}, A = {}, WNames = {}, RNames = {}, DNames = {}, FNames = {}, ANames = {}, env = nil, mem = nil, scans = 0, logLeft = 30 }
function SR_Store.logLine(msg)
    if (SR_Store.logLeft or 0) <= 0 then return end
    SR_Store.logLeft = SR_Store.logLeft - 1
    if type(print) == "function" then pcall(print, "[Noir_Creator] " .. tostring(msg)) end
end
function SR_Store.names(list)
    if #list == 0 then return "(none)" end
    local out = {}
    for i = 1, #list do out[i] = list[i] end
    return table.concat(out, ", ")
end

function SR_Store.scanAliases()
    local W, R, D = SR_Store.W, SR_Store.R, SR_Store.D
    local F, A = SR_Store.F, SR_Store.A
    local WN, RN, DN = SR_Store.WNames, SR_Store.RNames, SR_Store.DNames
    local FN, AN = SR_Store.FNames, SR_Store.ANames
    local function add(list, names, fn, label)
        if type(fn) ~= "function" then return end
        for i = 1, #list do if list[i] == fn then return end end
        list[#list + 1] = fn
        names[#names + 1] = label
    end
    local env = SR_Store.env
    if not env and type(getgenv) == "function" then
        local ok, g = pcall(getgenv)
        if ok and type(g) == "table" then env = g SR_Store.env = g end
    end
    if not env then
        local ok, g = pcall(function() return _G end)
        if ok and type(g) == "table" then env = g SR_Store.env = g end
    end
    local synTab = rawget(_G, "syn")
    add(W, WN, writefile, "writefile")
    add(W, WN, write_file, "write_file")
    add(W, WN, rawget(_G, "writefile"), "G.writefile")
    add(W, WN, rawget(_G, "write_file"), "G.write_file")
    add(R, RN, readfile, "readfile")
    add(R, RN, read_file, "read_file")
    add(R, RN, rawget(_G, "readfile"), "G.readfile")
    add(R, RN, rawget(_G, "read_file"), "G.read_file")
    add(D, DN, delfile, "delfile")
    add(D, DN, del_file, "del_file")
    add(D, DN, rawget(_G, "delfile"), "G.delfile")
    add(F, FN, isfile, "isfile")
    add(F, FN, is_file, "is_file")
    add(F, FN, rawget(_G, "isfile"), "G.isfile")
    add(A, AN, appendfile, "appendfile")
    add(A, AN, append_file, "append_file")
    add(A, AN, rawget(_G, "appendfile"), "G.appendfile")
    if type(synTab) == "table" then
        add(W, WN, synTab.write_file, "syn.write_file")
        add(R, RN, synTab.read_file, "syn.read_file")
        add(D, DN, synTab.del_file, "syn.del_file")
        add(F, FN, synTab.is_file, "syn.is_file")
        add(A, AN, synTab.append_file, "syn.append_file")
    end
    if env then
        add(W, WN, env.writefile, "env.writefile")
        add(W, WN, env.write_file, "env.write_file")
        add(R, RN, env.readfile, "env.readfile")
        add(R, RN, env.read_file, "env.read_file")
        add(D, DN, env.delfile, "env.delfile")
        add(D, DN, env.del_file, "env.del_file")
        add(F, FN, env.isfile, "env.isfile")
        add(F, FN, env.is_file, "env.is_file")
        add(A, AN, env.appendfile, "env.appendfile")
        add(A, AN, env.append_file, "env.append_file")

        local okInit = pcall(function()
            if type(env.Noir_Creator_Saved) ~= "table" then env.Noir_Creator_Saved = {} end
        end)
        if okInit and type(env.Noir_Creator_Saved) == "table" then SR_Store.mem = env.Noir_Creator_Saved end
    end
end
SR_Store.scanAliases()
SR_Store.logLine("[store] file functions: writers " .. SR_Store.names(SR_Store.WNames) .. " | readers " .. SR_Store.names(SR_Store.RNames))
function SR_Store.ensureAliases()
    if (SR_Store.scans or 0) >= 3 then return end
    SR_Store.scans = (SR_Store.scans or 0) + 1
    local beforeW, beforeR = #SR_Store.W, #SR_Store.R
    SR_Store.scanAliases()
    if #SR_Store.W ~= beforeW or #SR_Store.R ~= beforeR then
        SR_Store.logLine("[store] file functions appeared: writers " .. SR_Store.names(SR_Store.WNames) .. " | readers " .. SR_Store.names(SR_Store.RNames))
    end
end

SR_Store.probed = false
function SR_Store.probe()
    if SR_Store.probed then return end
    SR_Store.probed = true
    local test = "Noir_Creator_write_test.txt"
    for i = 1, #SR_Store.W do
        local ok, result = pcall(SR_Store.W[i], test, "test")
        SR_Store.logLine("[store] test write via " .. tostring(SR_Store.WNames[i]) .. " -> " .. (ok and tostring(result) or ("error: " .. tostring(result))))
    end
    for i = 1, #SR_Store.R do
        local ok, result = pcall(SR_Store.R[i], test)
        SR_Store.logLine("[store] test read via " .. tostring(SR_Store.RNames[i]) .. " -> " .. (ok and tostring(result) or ("error: " .. tostring(result))))
    end
    for i = 1, #SR_Store.D do pcall(SR_Store.D[i], test) end
    SR_Store.logLine("[store] writers " .. SR_Store.names(SR_Store.WNames) .. " | readers " .. SR_Store.names(SR_Store.RNames) .. " | deleters " .. SR_Store.names(SR_Store.DNames) .. " | isfile " .. SR_Store.names(SR_Store.FNames) .. " | append " .. SR_Store.names(SR_Store.ANames))
end
function SR_Store.CanWrite() return #SR_Store.W > 0 end
function SR_Store.CanRead() return #SR_Store.R > 0 end

function SR_Store.read(path)
    local function tryReaders()
        for i = 1, #SR_Store.R do
            local ok, text = pcall(SR_Store.R[i], path)
            if ok and type(text) == "string" and #text > 0 then return text end
        end
        return nil
    end
    local text = tryReaders()
    if not text and #SR_Store.R == 0 then
        SR_Store.ensureAliases()
        text = tryReaders()
    end
    if text then return text end
    local mem = SR_Store.mem
    if mem and type(mem[path]) == "string" and #mem[path] > 0 then return mem[path], "memory" end
    return nil
end

function SR_Store.write(path, text)
    if type(text) ~= "string" then return false, "payload is not a string" end
    SR_Store.ensureAliases()
    local mem = SR_Store.mem
    if mem then

        if not pcall(function() mem[path] = text end) then SR_Store.mem = nil end
    end
    local canVerify = #SR_Store.R > 0
    local canLook = #SR_Store.F > 0
    local lastError = "no file writer available"

    local function exists(target)
        for i = 1, #SR_Store.F do
            local ok, res = pcall(SR_Store.F[i], target)
            if ok and res == true then return true end
        end
        return false
    end
    local function verified(target)
        if canVerify then
            local rok, back = pcall(SR_Store.R[1], target)
            return rok and back == text
        end
        return false
    end
    local function attempt(fn, target)
        local ok, result = pcall(fn, target, text)
        if not ok then return false, tostring(result) end
        if canVerify then
            if verified(target) then return true end
            return false, "read-back mismatch"
        end
        if result ~= false then return true end
        if canLook and exists(target) then return true end
        return false, "writefile returned false"
    end
    local function drop(target)
        for i = 1, #SR_Store.D do pcall(SR_Store.D[i], target) end
    end

    local targets = { path }
    local bare = string.match(path, "[^/\\]+$")
    if bare and bare ~= path then targets[#targets + 1] = bare end
    for t = 1, #targets do
        local target = targets[t]
        for i = 1, #SR_Store.W do
            local ok, why = attempt(SR_Store.W[i], target)
            if ok then
                if t > 1 then SR_Store.logLine("[store] saved " .. tostring(path) .. " as " .. tostring(target)) end
                return true
            end
            lastError = tostring(SR_Store.WNames[i]) .. ": " .. why
        end
        drop(target)
        for i = 1, #SR_Store.W do
            local ok, why = attempt(SR_Store.W[i], target)
            if ok then return true end
            lastError = tostring(SR_Store.WNames[i]) .. " after delete: " .. why
        end

        if #SR_Store.A > 0 then
            drop(target)
            local cut, done = 0, false
            while cut < #text do
                local piece = string.sub(text, cut + 1, cut + 32768)
                local written = false
                for i = 1, #SR_Store.A do
                    local ok = pcall(SR_Store.A[i], target, piece)
                    if ok then written = true break end
                end
                if not written then break end
                cut = cut + #piece
            end
            if cut >= #text then
                if verified(target) or (not canVerify and (#SR_Store.F == 0 or exists(target))) then
                    SR_Store.logLine("[store] saved " .. tostring(path) .. " in pieces (appendfile)")
                    return true
                end
                lastError = "appendfile: read-back mismatch"
            end
        end

        if canLook and exists(target) then
            SR_Store.logLine("[store] " .. tostring(path) .. " is on disk (the executor gives no way to read it back)")
            return true
        end
    end
    SR_Store.probe()
    return false, lastError
end

SR_Store.posFile = "Noir_Creator_button_positions.json"
SR_Store.pos = nil
SR_Store.posRetries = 0
SR_Store.posThread = nil
SR_Store.http = nil
pcall(function() SR_Store.http = SR_UI.service("HttpService") end)
function SR_Store.posLoad()
    if SR_Store.pos then return SR_Store.pos end
    local data, source = {}, "no file yet"
    if SR_Store.http then
        local text = SR_Store.read(SR_Store.posFile)
        if text then
            local decoded = nil
            local ok = pcall(function() decoded = SR_Store.http:JSONDecode(text) end)
            if not ok or type(decoded) ~= "table" or decoded.version ~= 1 or type(decoded.modules) ~= "table" then
                source = "file is not readable"
            else
                data = decoded.modules
                local total = 0
                for _, bucket in pairs(data) do
                    if type(bucket) == "table" then for _ in pairs(bucket) do total = total + 1 end end
                end
                source = total .. " saved place(s)"
            end
        end
    end
    SR_Store.pos = data
    SR_Store.posLog("startup: " .. source .. " in " .. SR_Store.posFile)
    return data
end

function SR_Store.posGet(module, id)
    if type(id) ~= "string" or id == "" then return nil end
    local bucket = SR_Store.posLoad()[module]
    local saved = bucket and bucket[id]
    if type(saved) ~= "table" then return nil end
    if type(saved.xs) ~= "number" or type(saved.ys) ~= "number" then return nil end
    SR_Store.posLog("restore " .. module .. "." .. id .. " = " .. tostring(saved.xs) .. ", " .. tostring(saved.ys))
    return { xs = saved.xs, xo = saved.xo or 0, ys = saved.ys, yo = saved.yo or 0 }
end
function SR_Store.posSet(module, id, position)
    if type(id) ~= "string" or id == "" or not position then return end
    local bucket = SR_Store.posLoad()[module]
    if not bucket then bucket = {} SR_Store.pos[module] = bucket end
    bucket[id] = { xs = position.X.Scale, xo = position.X.Offset, ys = position.Y.Scale, yo = position.Y.Offset }
end

function SR_Store.posFlush()
    if not SR_Store.http or not SR_Store.CanWrite() then return false end
    local ok, payload = pcall(function() return SR_Store.http:JSONEncode({ version = 1, modules = SR_Store.posLoad() }) end)
    if not ok or type(payload) ~= "string" then return false end
    local written, why = SR_Store.write(SR_Store.posFile, payload)
    if written then
        SR_Store.posRetries = 0
        return true
    end
    SR_Store.posLog("file write failed (" .. tostring(why) .. "), retry " .. tostring(SR_Store.posRetries + 1))
    if SR_Store.posRetries < 4 and type(task) == "table" and type(task.delay) == "function" then
        SR_Store.posRetries = SR_Store.posRetries + 1
        if SR_Store.posThread then pcall(task.cancel, SR_Store.posThread) end
        SR_Store.posThread = task.delay(SR_Store.posRetries * 1.5, function()
            SR_Store.posThread = nil
            SR_Store.posFlush()
        end)
    end
    return false
end
function SR_Store.posSave(module, id, position)
    SR_Store.posSet(module, id, position)
    local where = position and (" = " .. tostring(position.X.Scale) .. ", " .. tostring(position.Y.Scale)) or ""
    SR_Store.posLog("save " .. module .. "." .. id .. where)
    return SR_Store.posFlush()
end

SR_Store.posLogLeft = 40
function SR_Store.posLog(msg)
    if (SR_Store.posLogLeft or 0) <= 0 then return end
    SR_Store.posLogLeft = SR_Store.posLogLeft - 1
    SR_Store.logLine("[pos] " .. tostring(msg))
end

function SR_Store.posApply(module, id, gui)
    if not gui then return false end
    local saved = SR_Store.posGet(module, id)
    if not saved then return false end
    return pcall(function()
        gui.Position = UDim2.new(saved.xs, saved.xo, saved.ys, saved.yo)
    end)
end

SR_UI.bootMessage = "Noir plugin load Successfully"
SR_UI.notifyMode  = "bootOnly"
SR_UI.bootSeconds = 12
SR_UI.notify      = odh_shared_plugins and odh_shared_plugins.Notify

local function SR_Log(text)
    pcall(print, "[Noir_Creator] " .. tostring(text))
end

local function SR_ToastsEnabled()
    if SR_UI.notifyMode == "all" then return not SR_UI.bootQuiet end
    return false
end

local function SR_Gate(text)
    if SR_ToastsEnabled() then return true end
    SR_Log(text)
    return false
end
if type(SR_UI.notify) == "function" then
    local function SR_HostNotify(text, seconds, ...)
        if not SR_Gate(text) then return end
        return SR_UI.notify(text, seconds, ...)
    end
    pcall(function() odh_shared_plugins.Notify = SR_HostNotify end)

    pcall(function() rawset(odh_shared_plugins, "Notify", SR_HostNotify) end)
    if rawequal(odh_shared_plugins.Notify, SR_HostNotify) then
        SR_UI.hooked = true
    else
        SR_UI.hooked = false
        SR_Log("host Notify is protected: module-level gates are used instead")
    end
end

local function SR_BootNotify()
    if SR_UI.notifyMode ~= "none" and type(SR_UI.notify) == "function" then
        pcall(SR_UI.notify, SR_UI.bootMessage, 6)
    end
    if type(task) == "table" and type(task.delay) == "function" then
        task.delay(SR_UI.bootSeconds, function() SR_UI.bootQuiet = false end)
    else
        SR_UI.bootQuiet = false
    end
end

SR_UI.modulesLoaded = 0
SR_UI.modulesSeen = 0
SR_UI.moduleFailures = {}
-- Every module runs inside its own function. A module can no longer stop the rest of
-- the file: an error (or an early return, e.g. "only works in MM2") is reported in the
-- console and the remaining modules keep loading.
function SR_UI.tryModule(name, body)
    SR_UI.modulesSeen = SR_UI.modulesSeen + 1
    local ok, err = pcall(body)
    if ok then
        SR_UI.modulesLoaded = SR_UI.modulesLoaded + 1
    else
        SR_UI.moduleFailures[#SR_UI.moduleFailures + 1] = name .. ": " .. tostring(err)
        SR_Log("module " .. name .. " failed: " .. tostring(err))
    end
    return ok
end
-- A section that swallows every call. Used when the host menu gives a tab we cannot
-- use: the module keeps running with no UI instead of erroring out.
SR_UI.stubSection = setmetatable({}, {
    __index = function()
        return function() return SR_UI.stubSection end
    end,
})
local function SR_Tab(moduleTitle)
    local host = odh_shared_plugins
    if not (host and type(host.CreateTab)=="function") then
        if not SR_UI.hostWarned then
            SR_UI.hostWarned = true
            SR_Log((moduleTitle or SR_UI.title) .. ": load through the current Overdrive H plugin menu")
        end
        return nil
    end
    local function create(title)
        local ok, tab = pcall(host.CreateTab, title, SR_UI.icon)
        if not ok or type(tab) ~= "table" or type(tab.AddSection) ~= "function" then
            if not SR_UI.hostWarned then
                SR_UI.hostWarned = true
                SR_Log("menu is unavailable in this game (" .. tostring(tab) .. "); modules keep running without sections")
            end
            return nil
        end
        return tab
    end
    if SR_UI.separateTabs then return create(moduleTitle or SR_UI.title) end
    if SR_UI.tab then return SR_UI.tab end
    SR_UI.tab = create(SR_UI.title)
    return SR_UI.tab
end

local function CreateODHX(id, title, file, replay, external)
    local X = { ready=false, silent=false, restoring=false, replay=replay, records={}, byKey={}, data={version=1, controls={}}, external=external }
    X.id, X.title, X.file = id, title, file
    local host = odh_shared_plugins
    assert(host and type(host.CreateTab)=="function", X.title .. ": load through the current Overdrive H plugin menu")
    local env = {}
    if type(getgenv)=="function" then local ok,g=pcall(getgenv); if ok and type(g)=="table" then env=g end end
    local rd = type(readfile)=="function" and readfile or env.readfile
    local wr = type(writefile)=="function" and writefile or env.writefile
    local exists = type(isfile)=="function" and isfile or env.isfile
    local http = SR_UI.service("HttpService")
    local reported = {}
    local function report(message)
        if reported[message] then return end
        reported[message]=true
        warn("[" .. X.title .. "] " .. message)

        if SR_Gate(X.title .. ": " .. message) and type(host.Notify)=="function" then
            pcall(host.Notify, X.title .. ": " .. message, 5)
        end
    end
    X.Report = report
    local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
    local function encode(v, depth)
        depth=depth or 0
        if depth>20 then error("settings nesting too deep") end
        if typeof(v)=="Color3" then return {__odhColor={v.R,v.G,v.B}} end
        local t=type(v)
        if t=="boolean" or t=="string" then return v end
        if t=="number" then if finite(v) then return v end; return nil end
        if t=="table" then
            local result={}
            for k,item in pairs(v) do
                if type(k)=="string" or type(k)=="number" then result[k]=encode(item,depth+1) end
            end
            return result
        end
        return nil
    end
    local function decode(v, depth)
        depth=depth or 0
        if depth>20 then error("settings nesting too deep") end
        if type(v)~="table" then return v end
        if v.__odhColor then
            local c=v.__odhColor
            assert(type(c)=="table" and finite(c[1]) and finite(c[2]) and finite(c[3]),"invalid color")
            return Color3.new(math.clamp(c[1],0,1),math.clamp(c[2],0,1),math.clamp(c[3],0,1))
        end
        local result={}
        for k,item in pairs(v) do result[k]=decode(item,depth+1) end
        return result
    end
    X.Encode, X.Decode = encode, decode
    if not X.external then
        if SR_Store.CanRead() then
            local text=SR_Store.read(X.file)
            if text then
                local good,data=pcall(function() return decode(http:JSONDecode(text)) end)
                if good and type(data)=="table" and data.version==1 and type(data.controls)=="table" then
                    X.data=data
                else

                    local recovered=false
                    local bakText=SR_Store.read(X.file..".bak")
                    if bakText then
                        local good2,data2=pcall(function() return decode(http:JSONDecode(bakText)) end)
                        if good2 and type(data2)=="table" and data2.version==1 and type(data2.controls)=="table" then
                            X.data=data2
                            recovered=true
                            report("Settings file was corrupted; restored from the backup copy.")
                        end
                    end
                    if not recovered then
                        X.badFile=true
                        report("Invalid settings file; defaults loaded. A manual change will replace it.")
                    end
                end
            end
        else report("readfile/writefile unavailable; settings last only for this session.") end
    end
    local tab
    X.shared=setmetatable({}, {__index=host})
    X.shared.Notify=function(text,seconds)
        if X.restoring then return end
        if not SR_Gate(text) then return end
        if type(host.Notify)=="function" then return host.Notify(text,seconds or 3) end
    end
    local function key(section,name,kind) return section .. " / " .. kind .. " / " .. name end
    local function safeValue(r,v)
        if r.kind=="Toggle" then if type(v)=="boolean" then return v end
        elseif r.kind=="Slider" then if finite(v) then return math.clamp(v,r.min,r.max) end
        elseif r.kind=="Colorpicker" then if typeof(v)=="Color3" then return v end
        elseif r.kind=="Dropdown" then
            for _,item in ipairs(r.items) do if v==item then return v end end
        end
        return nil
    end
    local function show(r,v)
        if v==nil or r.shown==v then return end
        local prior=X.silent; X.silent=true
        local ok,err=pcall(function()
            if r.kind=="Toggle" then
                if r.visual~=v then assert(type(r.handle)=="function","AddToggle must return a closure"); r.handle() end
            elseif r.kind=="Slider" then r.handle:SetValue(v)
            elseif r.kind=="Colorpicker" then r.handle:SetRGBValue(v)
            elseif r.kind=="Dropdown" then r.handle:Select(v) end
        end)
        X.silent=prior
        if ok then r.shown=v else report("UI sync failed: " .. r.name .. ": " .. tostring(err)) end
    end
    function X.Bind(section,name,kind,getter)
        local r=X.byKey[key(section,name,kind)]
        assert(r,"Unknown binding " .. section .. " / " .. name)
        r.get=getter
    end
    function X.Sync()
        for _,r in ipairs(X.records) do
            if r.get then
                local ok,v=pcall(r.get)
                if ok then
                    v=safeValue(r,v)
                    if v~=nil then
                        r.value=v
                        if not r.exclude then X.data.controls[r.key]=v end
                        show(r,v)
                    end
                end
            end
        end
    end

    local function commitNow()
        if not X.ready or X.silent or X.restoring or X.stopped or X.committing then return end
        X.committing=true
        local ok,err=pcall(function()
            X.Sync()
            if X.capture then X.data.snapshot=X.capture() end
            if X.external then
                if not X.backend or not X.backend(X.data) then error("native settings file could not be saved") end
            elseif SR_Store.CanWrite() then
                local payload=http:JSONEncode(encode(X.data))
                assert(type(payload)=="string","JSON encode failed")

                local saved,why=SR_Store.write(X.file,payload)
                if not saved then error(why or "write failed") end
            end
        end)
        X.committing=false
        if not ok then report("Settings save failed: " .. tostring(err)) end
    end
    X.Flush=commitNow

    function X.Commit()
        if not X.ready or X.silent or X.restoring or X.stopped or X.committing then return end
        if X.commitPending then return end
        X.commitPending=true
        local function flush()
            X.commitPending=nil
            commitNow()
        end
        if type(task)=="table" and type(task.delay)=="function" then
            task.delay(0.4,flush)
        else
            flush()
        end
    end
    function X.Restore()
        X.restoring=true
        for _,togglePass in ipairs({false,true}) do
            for _,r in ipairs(X.records) do
                if not r.exclude and ((r.kind=="Toggle")==togglePass) then
                    local v=safeValue(r,X.data.controls[r.key])
                    if v==nil and r.get then local ok,x=pcall(r.get); if ok then v=safeValue(r,x) end end
                    if v==nil then v=r.default end
                    if v~=nil then
                        show(r,v)
                        local ok,err=pcall(r.callback,v)
                        if not ok then report("Restore failed: " .. r.name .. ": " .. tostring(err)) end
                        r.value=v; X.data.controls[r.key]=v
                    end
                end
            end
        end
        X.restoring=false
    end
    function X.Finish()
        if X.replay then X.Restore() else X.Sync() end
        X.ready=true
        if not X.badFile then X.Flush() end
    end
    function X.Set(section,name,kind,v,apply)
        local r=X.byKey[key(section,name,kind)]
        if not r then return end
        v=safeValue(r,v); if v==nil then return end
        show(r,v); r.value=v; X.data.controls[r.key]=v
        if apply then r.callback(v) end
    end
    function X.ResetControls()
        X.data.controls={}
        for _,r in ipairs(X.records) do
            if r.kind=="Toggle" and not r.exclude then X.Set(r.section,r.name,r.kind,false,true) end
        end
    end
    function X.shared.AddSection(name,subtitle)
        if not tab then tab=SR_Tab(X.title) end
        if not tab then return SR_UI.stubSection end

        if (subtitle==nil or subtitle=="") and SR_UI.tagSubtitles and not SR_UI.separateTabs then subtitle=X.title end
        local raw
        local created=pcall(function() raw=tab:AddSection(name,subtitle or "") end)
        if not created or type(raw) ~= "table" then
            SR_Log("section \"" .. tostring(name) .. "\" is unavailable; the module keeps running without it")
            return SR_UI.stubSection
        end
        local section={Name=name,Raw=raw}
        local function register(kind,label,callback,default,min,max,items)
            local r={section=name,name=label,kind=kind,callback=callback,default=default,min=min,max=max,items=items,visual=false}
            r.key=key(name,label,kind)
            r.exclude=(name=="ð Keys")
            X.records[#X.records+1]=r; X.byKey[r.key]=r
            local function changed(v)
                if kind=="Toggle" then r.visual=(v==true) end
                if not X.ready or X.silent or X.restoring or X.stopped then return end
                v=safeValue(r,v); if v==nil then return end
                r.shown=v
                local ok,err=pcall(callback,v)
                if ok then
                    r.value=v
                    if not r.exclude then X.data.controls[r.key]=v end
                    X.Commit()
                else report("Callback failed: " .. label .. ": " .. tostring(err)) end
            end
            local created,createErr=pcall(function()
                if kind=="Toggle" then r.handle=raw:AddToggle(label,changed)
                elseif kind=="Slider" then r.handle=raw:AddSlider(label,min,max,default,changed)
                elseif kind=="Colorpicker" then r.handle=raw:AddColorpicker(label,default,changed)
                elseif kind=="Dropdown" then r.handle=raw:AddDropdown(label,items,changed) end
            end)
            if not created then
                r.handle=nil
                report("Could not create " .. kind .. " \"" .. tostring(label) .. "\": " .. tostring(createErr))
            end
            return r.handle
        end
        function section:AddToggle(label,cb) return register("Toggle",label,cb,false) end
        function section:AddSlider(label,min,max,default,cb) return register("Slider",label,cb,default,min,max) end
        function section:AddColorpicker(label,default,cb) return register("Colorpicker",label,cb,default) end
        function section:AddDropdown(label,items,cb)
            if type(items)~="table" then
                report("Dropdown \"" .. tostring(label) .. "\": item list missing (got " .. typeof(items) .. "); using a placeholder")
                items={"(empty)"}
            end
            return register("Dropdown",label,cb,items[1],nil,nil,items)
        end
        local function action(cb)
            return function(...)
                if not X.ready or X.stopped then return end
                local ok,err=pcall(cb,...)
                if not ok then report("Action failed: " .. tostring(err)) end
                X.Commit()
            end
        end
        function section:AddButton(label,cb) return raw:AddButton(label,action(cb)) end
        function section:AddKeybind(label,default,cb) return raw:AddKeybind(label,default,action(cb)) end
        function section:AddPlayerDropdown(label,cb) return raw:AddPlayerDropdown(label,action(cb)) end
        function section:AddTextBox(label,cb) return raw:AddTextBox(label,action(cb)) end
        function section:AddLabel(...) return raw:AddLabel(...) end
        function section:AddParagraph(title,text)
            if type(title)=="string" and type(text)=="string" then return SR_Paragraph(section,title,text) end
            return raw:AddParagraph(title,text)
        end
        return section
    end
    function X.Path(object)
        local parts={}
        local player=SR_UI.service("Players").LocalPlayer
        while object and object~=game do
            table.insert(parts,1,object==player and "$LocalPlayer" or object.Name)
            object=object.Parent
            if #parts>32 then return nil end
        end
        if object~=game then return nil end
        return parts
    end
    function X.Resolve(parts)
        if type(parts)~="table" then return nil end
        local object=game
        for _,name in ipairs(parts) do
            if name=="$LocalPlayer" then object=SR_UI.service("Players").LocalPlayer
            elseif type(name)=="string" and object then object=object:FindFirstChild(name)
            else return nil end
        end
        return object
    end
    X.connections={}
    function X.Connect(signal,callback)
        local c=signal:Connect(function(...) if not X.stopped then return callback(...) end end)
        X.connections[#X.connections+1]=c
        return c
    end
    function X.Stop()
        if X.stopped then return end
        X.Flush()
        X.stopped=true
        for _,c in ipairs(X.connections) do pcall(function() c:Disconnect() end) end
        X.connections={}

        if type(X.cleanup)=="function" then pcall(X.cleanup) end
        local registry=rawget(_G,"ODH_2026_PluginRuntimes")
        if type(registry)=="table" then registry[X.id]=nil end
    end
    local registry=rawget(_G,"ODH_2026_PluginRuntimes")
    if type(registry)~="table" then registry={}; rawset(_G,"ODH_2026_PluginRuntimes",registry) end
    local previous=registry[X.id]
    if previous and type(previous.Stop)=="function" then pcall(previous.Stop) end
    registry[X.id]=X
    return X
end

SR_UI.tryModule("Aimlock", function()
do
    local ODHX = CreateODHX("Aimlock", "MM2 Aimlock", "ODH_Aimlock_settings.json", true, false)

    local shared = ODHX.shared
    local section = shared.AddSection("MM2 AIMLOCK")

    local Players = SR_UI.service("Players")
    local RunService = SR_UI.service("RunService")
    local UserInputService = SR_UI.service("UserInputService")
    local TweenService = SR_UI.service("TweenService")
    local Workspace = SR_UI.service("Workspace")
    local CoreGui = SR_UI.service("CoreGui")

    local LocalPlayer = Players.LocalPlayer

    local CurrentCamera = Workspace.CurrentCamera
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        CurrentCamera = Workspace.CurrentCamera
    end)

    local Maid = {}
    Maid.__index = Maid
    function Maid.new() return setmetatable({_tasks = {}, _destroyed = false}, Maid) end
    function Maid:GiveTask(task)
        if self._destroyed then
            if typeof(task) == "RBXScriptConnection" then task:Disconnect()
            elseif typeof(task) == "Instance" then task:Destroy()
            elseif type(task) == "function" then task()
            elseif type(task) == "table" and type(task.Destroy) == "function" then task:Destroy() end
            return
        end
        table.insert(self._tasks, task)
        return task
    end
    function Maid:DoCleaning()
        if self._destroyed then return end
        self._destroyed = true
        for _, t in pairs(self._tasks) do
            if typeof(t) == "RBXScriptConnection" then t:Disconnect()
            elseif typeof(t) == "Instance" then t:Destroy()
            elseif type(t) == "function" then t()
            elseif type(t) == "table" and type(t.Destroy) == "function" then t:Destroy() end
        end
        self._tasks = {}
    end
    function Maid:Destroy() self:DoCleaning() end

    local RootMaid = Maid.new()

    local function getfserv(s) return SR_UI.service(s) end

    local BindableButtons = {Buttons = {}, Maids = {}, Count = 0}

    local __SHAPES = {
        [0] = "rbxassetid://86221076925479",
        [1] = "rbxassetid://96242665417546",
        [2] = "rbxassetid://97129189935336",
        [3] = "rbxassetid://76165862027868",
        [4] = "rbxassetid://125868092127496"
    }

    local __NORMAL_COLOR = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(0.133333, 0.827451, 0.494118)),
        ColorSequenceKeypoint.new(0.6, Color3.new(0.231373, 0.509804, 0.498039)),
        ColorSequenceKeypoint.new(1, Color3.new(0.501961, 0.501961, 0.501961))
    })

    local __ACTIVE_COLOR = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.new(0.0, 0.8, 0.4)),
        ColorSequenceKeypoint.new(0.6, Color3.new(0.0, 0.5, 0.3)),
        ColorSequenceKeypoint.new(1,   Color3.new(0.2, 0.8, 0.6))
    })

    local function safecallback(callback)
        if not callback then return end
        local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
        if not ok then warn("[BIND ERROR] " .. tostring(err)) end
    end

    local function GetStorage()
        local parent = gethui and gethui()
        if not parent or typeof(parent) ~= "Instance" then parent = CoreGui end
        if not parent or typeof(parent) ~= "Instance" then
            parent = Players.LocalPlayer:WaitForChild("PlayerGui", 5)
        end
        if typeof(parent) ~= "Instance" then
            parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        end
        local sg = parent:FindFirstChild("@odh_aimlock_bindstorage")
        if not sg then
            sg = Instance.new("ScreenGui")
            sg.Name = "@odh_aimlock_bindstorage"
            sg.ResetOnSpawn = false
            sg.IgnoreGuiInset = true
            pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
            sg.Parent = parent
            RootMaid:GiveTask(sg)
        end
        return sg
    end

    local function MakeDraggable(gui, maid, ripple, sound, clickFunc)
        local dragging, dragInput, dragStart, startPos
        local hasMoved = false

        maid:GiveTask(ODHX.Connect(gui.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging, dragStart, startPos = true, input.Position, gui.Position
                hasMoved = false

                sound:Play()
                local absPos = gui.AbsolutePosition
                ripple.Position = UDim2.new(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
                ripple.Size = UDim2.new(0, 0, 0, 0)
                ripple.BackgroundTransparency = 0.5
                ripple.Visible = true

                TweenService:Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 45, 0, 45),
                    BackgroundTransparency = 1
                }):Play()

                local releaseConn
                releaseConn = ODHX.Connect(UserInputService.InputEnded, function(endInput)
                    if endInput.UserInputType == input.UserInputType then
                        dragging = false
                        if not hasMoved then
                            clickFunc()
                        else
                            SR_Store.posSave("aimlock", gui.Name, gui.Position)
                        end
                        if releaseConn then releaseConn:Disconnect() releaseConn = nil end
                    end
                end)
                maid:GiveTask(releaseConn)
            end
        end))

        maid:GiveTask(ODHX.Connect(gui.InputChanged, function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end))

        maid:GiveTask(ODHX.Connect(UserInputService.InputChanged, function(input)
            if dragging and input == dragInput then
                local delta = input.Position - dragStart
                if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then hasMoved = true end
                local screen = gui.Parent.AbsoluteSize
                gui.Position = UDim2.new(startPos.X.Scale + (delta.X / screen.X), 0, startPos.Y.Scale + (delta.Y / screen.Y), 0)
            end
        end))
    end

    function BindableButtons.AddBButton(id, text, onFunc, offFunc)
        if BindableButtons.Buttons[id] then return BindableButtons.Buttons[id]:FindFirstChild("BindValue") end

        local buttonMaid = Maid.new()
        local screen = Workspace.CurrentCamera.ViewportSize

        local buttonSizeY = 0.11
        local widthScale = buttonSizeY * (screen.Y / screen.X)

        local xPos = 0.1 + ((BindableButtons.Count % 8) * (widthScale + 0.005))
        local yPos = 0.9 - (math.floor(BindableButtons.Count / 8) * (buttonSizeY + 0.015))

        local ImageButton = Instance.new("ImageButton")
        ImageButton.Name = id
        ImageButton.Size = UDim2.new(widthScale, 0, buttonSizeY, 0)
        ImageButton.Position = UDim2.new(xPos, 0, yPos, 0)
        local savedPos = SR_Store.posGet("aimlock", id)
        if savedPos then
            ImageButton.Position = UDim2.new(savedPos.xs, savedPos.xo, savedPos.ys, savedPos.yo)
        end
        ImageButton.AnchorPoint = Vector2.new(0.5, 0.5)
        ImageButton.Image = __SHAPES[0]
        ImageButton.BackgroundTransparency = 1
        ImageButton.BorderSizePixel = 0
        ImageButton.ClipsDescendants = false
        ImageButton.AutoButtonColor = false
        ImageButton.Parent = GetStorage()
        buttonMaid:GiveTask(ImageButton)

        local BindValue = Instance.new("BoolValue")
        BindValue.Name = "BindValue"
        BindValue.Parent = ImageButton

        local TextLabel = Instance.new("TextLabel")
        TextLabel.Name = "@Text"
        TextLabel.Size = UDim2.new(0.8, 0, 0.8, 0)
        TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
        TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        TextLabel.BackgroundTransparency = 1
        TextLabel.Font = Enum.Font.Jura
        TextLabel.Text = text
        TextLabel.TextColor3 = Color3.new(1, 1, 1)
        TextLabel.TextSize = 10
        TextLabel.TextWrapped = true
        TextLabel.ZIndex = 3
        TextLabel.Parent = ImageButton

        local Aspect = Instance.new("UIAspectRatioConstraint")
        Aspect.AspectRatio = 1
        Aspect.AspectType = Enum.AspectType.ScaleWithParentSize
        Aspect.Parent = ImageButton

        local Gradient = Instance.new("UIGradient")
        Gradient.Name = "@Stroke"
        Gradient.Color = __NORMAL_COLOR
        Gradient.Parent = ImageButton

        local ripple = Instance.new("Frame")
        ripple.Name = "@ripple"
        ripple.BackgroundColor3 = Color3.fromRGB(0, 155, 255)
        ripple.BackgroundTransparency = 0.5
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.Visible = false
        ripple.ZIndex = 2
        ripple.Parent = ImageButton
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ripple

        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://3868133279"
        sound.Volume = 0.5
        sound.Parent = ImageButton

        local debounce = false
        local tInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

        local function onClick()
            if debounce then return end
            debounce = true
            local fOut = TweenService:Create(ImageButton, tInfo, {ImageTransparency = 1})
            fOut:Play()
            fOut.Completed:Wait()

            BindValue.Value = not BindValue.Value
            Gradient.Color = BindValue.Value and __ACTIVE_COLOR or __NORMAL_COLOR
            if BindValue.Value then safecallback(onFunc) else safecallback(offFunc) end

            local fIn = TweenService:Create(ImageButton, tInfo, {ImageTransparency = 0})
            fIn:Play()
            fIn.Completed:Wait()
            debounce = false
        end

        MakeDraggable(ImageButton, buttonMaid, ripple, sound, onClick)

        SR_Rota.Attach(Gradient, buttonMaid, 90)

        BindableButtons.Buttons[id], BindableButtons.Maids[id] = ImageButton, buttonMaid
        BindableButtons.Count = BindableButtons.Count + 1
        return BindValue
    end

    function BindableButtons.DeleteBButton(id)
        if BindableButtons.Maids[id] then
            BindableButtons.Maids[id]:Destroy()
            BindableButtons.Maids[id] = nil
        end
        if BindableButtons.Buttons[id] then
            BindableButtons.Buttons[id] = nil
        end
    end

    local AimEnabled = false
    local WallCheck = false
    local TargetPart = "Head"
    local PredictionLevel = 0.145
    local SelectedPlayer = nil
    local TargetPlayer = nil
    local LastSearchTime = 0
    local SearchInterval = 0.1
    local Smoothness = 0.25
    local FOVEnabled = false
    local FOVRadius = 250
    local FOVCircle = nil
    local LastAimPos = nil
    local LastTarget = nil

    local HorizontalPrediction = false

    local SmoothRate = 18

    local TargetCache = {
        player = nil,
        char = nil,
        root = nil,
        head = nil,
        part = nil,
    }

    local function InvalidateCache()
        TargetCache.player = nil
        TargetCache.char = nil
        TargetCache.root = nil
        TargetCache.head = nil
        TargetCache.part = nil

        LastAimPos = nil
        LastTarget = nil
    end

    local function isAlive(player)
        if not player or not player.Character then return false end
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        return hum and hum.Health > 0
    end

    local function findMurderer()
        local candidates = {}

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and isAlive(player) then
                local role = nil
                local char = player.Character

                if char then
                    for _, tool in ipairs(char:GetChildren()) do
                        if tool:IsA("Tool") then
                            local n = tool.Name:lower()
                            if n == "knife" or n == "default knife" then
                                role = "Murderer"
                                break
                            end
                        end
                    end

                    if not role then
                        local head = char:FindFirstChild("Head")
                        if head then
                            for _, gui in ipairs(head:GetChildren()) do
                                if gui:IsA("BillboardGui") then
                                    for _, lbl in ipairs(gui:GetDescendants()) do
                                        if lbl:IsA("TextLabel") then
                                            local t = lbl.Text:lower()
                                            if t:find("murder") or t:find("killer") then
                                                role = "Murderer"
                                                break
                                            end
                                        end
                                    end
                                end
                                if role then break end
                            end
                        end
                    end

                    if not role then
                        for _, v in ipairs(char:GetChildren()) do
                            if v:IsA("ValueBase") then
                                local vn = v.Name:lower()
                                if vn == "role" or vn == "roletag" or vn == "rolevalue" then
                                    if tostring(v.Value):lower():find("murder") then
                                        role = "Murderer"
                                        break
                                    end
                                end
                            end
                        end
                    end
                end

                if not role and player:FindFirstChild("Backpack") then
                    for _, tool in ipairs(player.Backpack:GetChildren()) do
                        if tool:IsA("Tool") then
                            local n = tool.Name:lower()
                            if n == "knife" or n == "default knife" then
                                role = "Murderer"
                                break
                            end
                        end
                    end
                end

                if role == "Murderer" then
                    table.insert(candidates, player)
                end
            end
        end

        if #candidates > 0 then
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myRoot then
                local closest, closestDist = nil, math.huge
                for _, p in ipairs(candidates) do
                    local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = (root.Position - myRoot.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closest = p
                        end
                    end
                end
                return closest
            end
            return candidates[1]
        end

        return nil
    end

    local function resolveAimPart(player)
        if not player or not player.Character then return nil end

        if TargetCache.player ~= player or TargetCache.char ~= player.Character then
            InvalidateCache()
            TargetCache.player = player
            TargetCache.char = player.Character
            TargetCache.root = player.Character:FindFirstChild("HumanoidRootPart")
            TargetCache.head = player.Character:FindFirstChild("Head")
        end

        local part
        if TargetPart == "HumanoidRootPart" then
            part = TargetCache.root
        else
            part = TargetCache.head or TargetCache.root
        end
        TargetCache.part = part
        return part
    end

    local function isVisible(targetPart, targetPlayer)
        if not WallCheck then return true end
        if not targetPart or not targetPlayer then return false end

        local targetChar = targetPlayer.Character
        if not targetChar then return false end

        local myChar = LocalPlayer.Character

        local filterList = {}
        if myChar then table.insert(filterList, myChar) end
        table.insert(filterList, targetChar)

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = filterList
        params.IgnoreWater = true

        local origin = CurrentCamera.CFrame.Position
        local checkParts = {"Head", "UpperTorso", "Torso", "HumanoidRootPart"}
        local visiblePoints = 0
        local checked = 0

        for _, partName in ipairs(checkParts) do
            local part = targetChar:FindFirstChild(partName)
            if part then
                checked = checked + 1
                local direction = part.Position - origin
                local result = Workspace:Raycast(origin, direction, params)
                if not result then
                    visiblePoints = visiblePoints + 1
                end
            end
        end

        if checked == 0 then return true end
        return visiblePoints >= (checked > 2 and 2 or 1)
    end

    local function isWithinFOV(worldPos)
        if not FOVEnabled then return true end
        local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(worldPos)
        if not onScreen then return false end
        local screen = Workspace.CurrentCamera.ViewportSize
        local center = Vector2.new(screen.X / 2, screen.Y / 2)
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        return dist <= FOVRadius
    end

    local function getEffectiveTarget()
        if SelectedPlayer then
            if isAlive(SelectedPlayer) and Players:FindFirstChild(SelectedPlayer.Name) then
                return SelectedPlayer
            end

            SelectedPlayer = nil
        end
        return TargetPlayer
    end

    local function CreateFOVCircle()
        if FOVCircle then return FOVCircle end
        local storage = GetStorage()
        local frame = Instance.new("Frame")
        frame.Name = "@FOVCircle"
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Position = UDim2.new(0.5, 0, 0.5, 0)
        frame.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
        frame.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.ZIndex = 0
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(0, 200, 120)
        stroke.Thickness = 1.5
        stroke.Transparency = 0.2
        stroke.Parent = frame
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = frame
        frame.Parent = storage
        RootMaid:GiveTask(frame)
        FOVCircle = frame
        return frame
    end

    local function UpdateFOVCircle()
        if not FOVEnabled then
            if FOVCircle then FOVCircle.Visible = false end
            return
        end
        local c = FOVCircle or CreateFOVCircle()
        c.Visible = true
        c.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
    end

    local function AimLockBody(dt)
        local currentTime = tick()

        if currentTime - LastSearchTime > SearchInterval then
            LastSearchTime = currentTime

            if SelectedPlayer then
                if not isAlive(SelectedPlayer) or not Players:FindFirstChild(SelectedPlayer.Name) then
                    SelectedPlayer = nil
                    TargetPlayer = findMurderer()
                end
            else
                TargetPlayer = findMurderer()
            end
        end

        local target = getEffectiveTarget()
        if not target then
            LastAimPos = nil
            return
        end

        local aimPart = resolveAimPart(target)
        if not aimPart then
            LastAimPos = nil
            LastTarget = nil
            return
        end

        if LastTarget ~= target then
            LastAimPos = nil
            LastTarget = target
        end

        if not isVisible(aimPart, target) then
            LastAimPos = nil
            return
        end

        local vel = aimPart.AssemblyLinearVelocity or Vector3.new()
        local predX, predZ = 0, 0
        if HorizontalPrediction then
            predX, predZ = vel.X * PredictionLevel, vel.Z * PredictionLevel
        end
        local pred = Vector3.new(predX, vel.Y * 0.3 * PredictionLevel, predZ)
        local aimPos = aimPart.Position + pred

        if not isWithinFOV(aimPos) then
            LastAimPos = nil
            return
        end

        if LastAimPos and Smoothness > 0 then
            local alpha = 1 - math.exp(-SmoothRate * dt)
            alpha = math.clamp(alpha, 0, 1)
            aimPos = LastAimPos:Lerp(aimPos, alpha)
        end
        LastAimPos = aimPos

        CurrentCamera.CFrame = CFrame.lookAt(
            CurrentCamera.CFrame.Position,
            aimPos,
            Vector3.new(0, 1, 0)
        )
    end

    local function aimlockTrace(e) return debug.traceback(e) end

    local function AimLockLoop(dt)
        if not AimEnabled then return end

        local ok, err = xpcall(AimLockBody, aimlockTrace, dt)
        if not ok then
            warn("[MM2 Aimlock] loop error: " .. tostring(err))
        end
    end

    local function UpdateAimButtonState()
        ODHX.Commit()
        local btn = BindableButtons.Buttons["aim_toggle"]
        if not btn then return end
        local value=btn:FindFirstChild("BindValue")
        if value then value.Value=AimEnabled end
        local textLabel = btn:FindFirstChild("@Text")
        if textLabel then
            textLabel.Text = AimEnabled and "ON" or "OFF"
        end
        local gradient = btn:FindFirstChild("@Stroke")
        if gradient then
            gradient.Color = AimEnabled and __ACTIVE_COLOR or __NORMAL_COLOR
        end
    end

    local function ToggleAimLock()
        AimEnabled = not AimEnabled
        if AimEnabled then
            TargetPlayer = findMurderer()
        else
            TargetPlayer = nil
            LastAimPos = nil
            InvalidateCache()
        end
        UpdateAimButtonState()
    end

    local ShowBindableButton = true
    local bindButtonSize = 0.11

    local function ToggleBindableVisibility()
        local btn = BindableButtons.Buttons["aim_toggle"]
        if btn then
            btn.Visible = ShowBindableButton
        end
    end

    local function ResizeBindButton()
        local btn = BindableButtons.Buttons["aim_toggle"]
        if btn then
            local screen = Workspace.CurrentCamera.ViewportSize
            btn.Size = UDim2.new(bindButtonSize * (screen.Y / screen.X), 0, bindButtonSize, 0)
        end
    end

    local function CreateBindButton()
        if BindableButtons.Buttons["aim_toggle"] then return end

        BindableButtons.AddBButton("aim_toggle", "Aim", function()
            AimEnabled = true
            TargetPlayer = findMurderer()
            UpdateAimButtonState()
        end, function()
            AimEnabled = false
            TargetPlayer = nil
            LastAimPos = nil
            InvalidateCache()
            UpdateAimButtonState()
        end)

        ResizeBindButton()
        UpdateAimButtonState()
        ToggleBindableVisibility()
    end

    section:AddLabel("Developer: Noir_Creator | V4 Edition (improved)")
    SR_Paragraph(section, "Info", "Mode: HARD LOCK | Auto-Murderer | Wallcheck | Player Select | Smoothing | FOV")

    section:AddToggle("🎯 Enable Aimlock", function(b)
        AimEnabled = b
        if AimEnabled then
            TargetPlayer = findMurderer()
        else
            TargetPlayer = nil
            LastAimPos = nil
            InvalidateCache()
        end
        UpdateAimButtonState()
    end)

    section:AddToggle("📱 Show Screen Button", function(b)
        ShowBindableButton = b
        ToggleBindableVisibility()
    end)

    section:AddSlider("🔘 Button Size (%)", 5, 25, 11, function(value)
        bindButtonSize = value / 100
        ResizeBindButton()
    end)

    section:AddToggle("🧱 Wall Check", function(b)
        WallCheck = b
        shared.Notify("Wall Check: " .. (b and "ENABLED" or "DISABLED"), 2)
    end)

    section:AddToggle("🎯 FOV Check", function(b)
        FOVEnabled = b
        UpdateFOVCircle()
        shared.Notify("FOV Check: " .. (b and "ENABLED" or "DISABLED"), 2)
    end)

    section:AddSlider("🎯 FOV Radius (px)", 50, 800, 250, function(value)
        FOVRadius = value
        UpdateFOVCircle()
    end)

    section:AddSlider("🌀 Smoothness", 0, 95, 25, function(value)

        local pct = value / 100
        if pct <= 0.001 then
            SmoothRate = 1000
        else
            SmoothRate = math.clamp(24 * (1 - pct) + 1, 1, 1000)
        end
        Smoothness = pct
    end)

    section:AddToggle("↔️ Horizontal Prediction", function(b)
        HorizontalPrediction = b
        shared.Notify("Horizontal prediction: " .. (b and "ON (leads strafing)" or "OFF (glued to body)"), 2)
    end)

    section:AddPlayerDropdown("🎯 Select Player (overrides Murderer)", function(player)
        SelectedPlayer = player
        InvalidateCache()
        shared.Notify("Locked onto: " .. player.Name, 1)
    end)

    section:AddButton("🔄 Clear Player Selection", function()
        SelectedPlayer = nil
        InvalidateCache()
        shared.Notify("Player selection cleared — targeting Murderer", 2)
    end)

    section:AddDropdown("🎯 Target Body Part", {"Head", "HumanoidRootPart"}, function(s)
        TargetPart = s
        InvalidateCache()
    end)

    section:AddDropdown("⚡ Prediction", {"Low (0.08)", "Medium (0.145)", "High (0.20)", "Disabled"}, function(s)
        if s:find("Low") then PredictionLevel = 0.08
        elseif s:find("Medium") then PredictionLevel = 0.145
        elseif s:find("High") then PredictionLevel = 0.20
        else PredictionLevel = 0 end
    end)

    section:AddKeybind("⌨️ Quick Toggle", "T", function()
        ToggleAimLock()
    end)

    RootMaid:GiveTask(ODHX.Connect(LocalPlayer.CharacterAdded, function()
        TargetPlayer = nil
        SelectedPlayer = nil
        InvalidateCache()
        LastAimPos = nil
        task.delay(1, function()
            if AimEnabled then
                TargetPlayer = findMurderer()
            end
        end)
    end))

    local function hookPlayerCharacter(player)
        RootMaid:GiveTask(ODHX.Connect(player.CharacterAdded, function()
            InvalidateCache()
            task.delay(0.5, function()
                if AimEnabled and not SelectedPlayer then
                    TargetPlayer = findMurderer()
                end
            end)
        end))
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            hookPlayerCharacter(player)
        end
    end

    RootMaid:GiveTask(ODHX.Connect(Players.PlayerAdded, function(player)
        hookPlayerCharacter(player)
    end))

    local function watchPlayerTools(player)
        RootMaid:GiveTask(ODHX.Connect(player.ChildAdded, function(child)
            if child:IsA("Tool") and AimEnabled and not SelectedPlayer then
                task.delay(0.3, function()
                    if AimEnabled then TargetPlayer = findMurderer() end
                end)
            end
        end))
        RootMaid:GiveTask(ODHX.Connect(player.ChildRemoved, function(child)
            if child:IsA("Tool") and AimEnabled and not SelectedPlayer then
                task.delay(0.3, function()
                    if AimEnabled then TargetPlayer = findMurderer() end
                end)
            end
        end))
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            watchPlayerTools(player)
        end
    end
    RootMaid:GiveTask(ODHX.Connect(Players.PlayerAdded, watchPlayerTools))

    RootMaid:GiveTask(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        ResizeBindButton()
    end))

    RunService:BindToRenderStep("MM2_Aimlock", Enum.RenderPriority.Camera.Value + 1, AimLockLoop)

    RootMaid:GiveTask(function()
        pcall(function() RunService:UnbindFromRenderStep("MM2_Aimlock") end)
        InvalidateCache()
        LastAimPos = nil
    end)

    CreateBindButton()
    ToggleBindableVisibility()
    UpdateFOVCircle()
    SR_Log("MM2 Aimlock V4 loaded")
    print("MM2 Aimlock V4 — Auto-Murderer + Player Select + Wallcheck + Smoothing + FOV")

    ODHX.Bind("MM2 AIMLOCK", "🎯 Enable Aimlock", "Toggle", function() return AimEnabled end)
    ODHX.Bind("MM2 AIMLOCK", "📱 Show Screen Button", "Toggle", function() return ShowBindableButton end)
    ODHX.Bind("MM2 AIMLOCK", "🔘 Button Size (%)", "Slider", function() return bindButtonSize * 100 end)
    ODHX.Bind("MM2 AIMLOCK", "🧱 Wall Check", "Toggle", function() return WallCheck end)
    ODHX.Bind("MM2 AIMLOCK", "🎯 FOV Check", "Toggle", function() return FOVEnabled end)
    ODHX.Bind("MM2 AIMLOCK", "🎯 FOV Radius (px)", "Slider", function() return FOVRadius end)
    ODHX.Bind("MM2 AIMLOCK", "🌀 Smoothness", "Slider", function() return Smoothness * 100 end)
    ODHX.Bind("MM2 AIMLOCK", "↔️ Horizontal Prediction", "Toggle", function() return HorizontalPrediction end)
    ODHX.Bind("MM2 AIMLOCK", "🎯 Target Body Part", "Dropdown", function() return TargetPart end)
    ODHX.Bind("MM2 AIMLOCK", "⚡ Prediction", "Dropdown", function() return PredictionLevel == 0.08 and "Low (0.08)" or PredictionLevel == 0.145 and "Medium (0.145)" or PredictionLevel == 0.20 and "High (0.20)" or "Disabled" end)
    ODHX.cleanup=function() RootMaid:DoCleaning() end
    ODHX.Finish()

    for btnId, btn in pairs(BindableButtons.Buttons) do SR_Store.posApply("aimlock", btnId, btn) end

end
end)

SR_UI.tryModule("BindableButtonsColor", function()
do
    local ODHX = CreateODHX("BindableButtonsColor", "Bindable Buttons Color", "ODH_BindableButtonsColor_settings.json", false, false)

    local shared = ODHX.shared
    if not shared then
    	warn("[Bindable Buttons Color] Run this file as a plugin through the Overdrive H menu!")
    	return
    end

    local DEFAULT_BG         = Color3.fromRGB(255, 70, 70)
    local DEFAULT_ON_LIGHT   = Color3.fromRGB(120, 235, 200)
    local DEFAULT_ON_DARK    = Color3.fromRGB(28, 12, 48)
    local DEFAULT_TEXT       = Color3.fromRGB(255, 255, 255)
    local DEFAULT_STROKE     = Color3.fromRGB(0, 0, 0)
    local APPLY_INTERVAL     = 2
    local LIGHT_RESCAN_TICKS = 6
    local BIG_AUTO_MAX_WIDTH = 150

    local PICK_SECONDS       = 6
    local COMMIT_DELAY       = 0.35

    local MY_GEN = 0
    pcall(function()
    	if type(getgenv) == "function" then
    		local g = getgenv()

    		if type(g.BindableButtonColor) == "table" and type(g.BindableButtonColor.Shutdown) == "function" then
    			pcall(g.BindableButtonColor.Shutdown)
    		end
    		g.__BBC_GEN = (g.__BBC_GEN or 0) + 1
    		MY_GEN = g.__BBC_GEN
    	end
    end)

    local function genAlive()
    	if MY_GEN == 0 then
    		return true
    	end
    	local ok, res = pcall(function()
    		return getgenv().__BBC_GEN == MY_GEN
    	end)
    	return ok and res
    end

    local State = {
    	BgColor     = DEFAULT_BG,
    	OnLight     = DEFAULT_ON_LIGHT,
    	OnDark      = DEFAULT_ON_DARK,
    	TextColor   = DEFAULT_TEXT,
    	StrokeColor = DEFAULT_STROKE,
    	Active      = false,
    	ManualBind  = nil,
    	Saved       = {},
    	Dead        = false,
    }

    State.SavedPaths = {}
    State.ManualPath = nil
    if type(ODHX.data.snapshot) == "table" then
        local saved = ODHX.data.snapshot
        if typeof(saved.BgColor) == typeof(State.BgColor) then State.BgColor = saved.BgColor end
        if typeof(saved.OnLight) == typeof(State.OnLight) then State.OnLight = saved.OnLight end
        if typeof(saved.OnDark) == typeof(State.OnDark) then State.OnDark = saved.OnDark end
        if typeof(saved.TextColor) == typeof(State.TextColor) then State.TextColor = saved.TextColor end
        if typeof(saved.StrokeColor) == typeof(State.StrokeColor) then State.StrokeColor = saved.StrokeColor end
        if typeof(saved.Active) == typeof(State.Active) then State.Active = saved.Active end
        if type(saved.SavedPaths) == "table" then State.SavedPaths = saved.SavedPaths end
        if type(saved.ManualPath) == "table" then State.ManualPath = saved.ManualPath end
    end
    ODHX.capture = function()
        return {
            BgColor=State.BgColor,
            OnLight=State.OnLight,
            OnDark=State.OnDark,
            TextColor=State.TextColor,
            StrokeColor=State.StrokeColor,
            Active=State.Active,
            SavedPaths=State.SavedPaths, ManualPath=State.ManualPath,
        }
    end

    local Players     = SR_UI.service("Players")
    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
    	LocalPlayer = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    end

    local originals = setmetatable({}, { __mode = "k" })

    local weSet   = setmetatable({}, { __mode = "k" })
    local pending = setmetatable({}, { __mode = "k" })
    local btnMode = setmetatable({}, { __mode = "k" })
    local SignalConns = setmetatable({}, { __mode = "k" })

    local Cache = {
    	list  = {},
    	dirty = true,
    	tick  = 0,
    }

    local paintTree, restoreTree

    local TARGET = "shootmurderer"

    local TEXT_CLASSES = { TextLabel = true, TextButton = true, TextBox = true }
    local BTN_CLASSES  = { TextButton = true, ImageButton = true }

    local function normalize(s)
    	return (tostring(s):lower():gsub("%s+", ""))
    end

    local function stripRich(s)
    	s = tostring(s):gsub("<[^>]*>", "")
    	s = s:gsub("&%a+;", " ")
    	return s
    end

    local function sanitize(s)
    	s = tostring(s):gsub("%c", ""):gsub("%s", "")
    	if #s > 16 then
    		s = s:sub(1, 16) .. "…"
    	end
    	if s == "" then
    		s = "(unnamed)"
    	end
    	return s
    end

    local function isa(inst, cls)
    	local ok, res = pcall(function()
    		return inst:IsA(cls)
    	end)
    	return ok and res or false
    end

    local function isButtonClass(inst)
    	return isa(inst, "TextButton") or isa(inst, "ImageButton")
    end

    local function getPureText(inst)
    	local ok, txt = pcall(function()
    		return inst.Text
    	end)
    	if ok and txt ~= nil then
    		return normalize(stripRich(txt))
    	end
    	return nil
    end

    local function getName(inst)
    	local ok, n = pcall(function()
    		return normalize(inst.Name)
    	end)
    	if ok and n then
    		return n
    	end
    	return nil
    end

    local function hasSize(inst)
    	local ok, s = pcall(function()
    		return inst.AbsoluteSize
    	end)
    	if not ok or not s then
    		return false
    	end
    	local okx, w = pcall(function()
    		return s.X
    	end)
    	local oky, h = pcall(function()
    		return s.Y
    	end)
    	return okx and oky and w >= 8 and h >= 8
    end

    local function isVisible(inst)
    	local cur = inst
    	local depth = 0
    	while cur and depth < 60 do
    		local ok, isGui = pcall(function()
    			return cur:IsA("GuiObject") or cur:IsA("ScreenGui")
    		end)
    		if ok and isGui then
    			local okv, vis = pcall(function()
    				return cur.Visible
    			end)
    			if okv and vis == false then
    				return false
    			end
    		end
    		local okp, par = pcall(function()
    			return cur.Parent
    		end)
    		if not okp then
    			break
    		end
    		cur = par
    	end
    	return true
    end

    local function isInsideOverdriveMenu(inst)
    	local cur = inst.Parent
    	local depth = 0
    	while cur and depth < 60 do
    		local okg, isGui = pcall(function()
    			return cur:IsA("GuiObject") or cur:IsA("ScreenGui")
    		end)
    		if okg and isGui then
    			local n = getName(cur)
    			if n and (n:find("overdrive", 1, true) or n:find("odh", 1, true)) then
    				return true
    			end
    			local okc, cls = pcall(function()
    				return cur.ClassName
    			end)
    			if okc and TEXT_CLASSES[cls] then
    				local t = getPureText(cur)
    				if t and (t:find("overdriveh", 1, true) or t:find("overdrivehub", 1, true)) then
    					return true
    				end
    			end
    		end
    		local okp, par = pcall(function()
    			return cur.Parent
    		end)
    		if not okp then
    			break
    		end
    		cur = par
    	end
    	return false
    end

    local function insideRobloxGui(inst)
    	local cur = inst.Parent
    	local depth = 0
    	while cur and depth < 60 do
    		local okS, isS = pcall(function()
    			return cur:IsA("ScreenGui")
    		end)
    		if okS and isS then
    			local n = getName(cur)
    			if n and n:find("roblox", 1, true) then
    				return true
    			end
    		end
    		local okp, par = pcall(function()
    			return cur.Parent
    		end)
    		if not okp then
    			break
    		end
    		cur = par
    	end
    	return false
    end

    local RootCache = { list = nil }

    local function getRoots()
    	if RootCache.list then
    		return RootCache.list
    	end
    	local roots = {}
    	local function add(r)
    		if r then
    			table.insert(roots, r)
    		end
    	end
    	pcall(function()
    		add(SR_UI.service("CoreGui"))
    	end)
    	pcall(function()
    		if gethui then
    			add(gethui())
    		end
    	end)
    	pcall(function()
    		add(LocalPlayer:FindFirstChildOfClass("PlayerGui"))
    	end)
    	RootCache.list = roots
    	return roots
    end

    local function toColor3(c)
    	local ok, res = pcall(function()
    		if c ~= nil and typeof(c) == "Color3" then
    			return c
    		end
    		return nil
    	end)
    	if ok and res then
    		return res
    	end
    	return nil
    end

    local function closeColors(a, b)
    	return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.05
    end

    local function luminance(c)
    	return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
    end

    local function isDarkColor(c)
    	return luminance(c) < 0.45
    end

    local function probeCandidate(inst)
    	local ok, res = pcall(function()
    		local cls = inst.ClassName
    		local isBtn  = BTN_CLASSES[cls] or false
    		local isText = TEXT_CLASSES[cls] or false

    		if not (isBtn or isText or cls == "Frame" or cls == "ImageLabel") then
    			return false
    		end

    		local selfText = isText and normalize(stripRich(inst.Text)) or nil

    		local childText = nil
    		if isBtn then
    			local lbl = inst:FindFirstChildWhichIsA("TextLabel", true)
    			if lbl then
    				childText = normalize(stripRich(lbl.Text))
    			end
    		end

    		local n = normalize(inst.Name)
    		local matched = false

    		if selfText == TARGET or childText == TARGET then
    			matched = isBtn or not isInsideOverdriveMenu(inst)
    		end

    		if not matched and isBtn then
    			if (selfText and selfText:find(TARGET, 1, true))
    				or (childText and childText:find(TARGET, 1, true)) then
    				matched = true
    			elseif n:find(TARGET, 1, true) then
    				matched = not isInsideOverdriveMenu(inst)
    			end
    		end

    		if not matched and not isBtn then
    			local nameHit = n:find(TARGET, 1, true)
    			local textHit = selfText and selfText:sub(1, #TARGET) == TARGET
    			if nameHit or textHit then
    				matched = not isInsideOverdriveMenu(inst)
    			end
    		end

    		return matched
    	end)
    	return ok and res or false
    end

    local function isBigAutoButton(inst)
    	local ok, s = pcall(function()
    		return inst.AbsoluteSize
    	end)
    	if not ok or not s then
    		return false
    	end
    	local limit = BIG_AUTO_MAX_WIDTH
    	pcall(function()
    		local cam = SR_UI.service("Workspace").CurrentCamera
    		if cam and cam.ViewportSize then
    			limit = math.max(limit, cam.ViewportSize.X * 0.18)
    		end
    	end)
    	return s.X >= limit
    end

    local function isAliveInstance(inst)
        local ok, alive = pcall(function() return inst.Parent ~= nil end)
        return ok and alive == true
    end

    local function addCandidate(inst)
    	for _, c in ipairs(Cache.list) do
    		if c == inst then
    			return
    		end
    	end
    	table.insert(Cache.list, inst)

    	if State.Active then
    		pcall(function()
    			paintTree(inst)
    		end)
    	end
    end

    local function fullScan()
        for _,path in ipairs(State.SavedPaths) do
            local target = ODHX.Resolve(path)
            if target and target:IsA("GuiObject") then
                local found=false
                for _,current in ipairs(State.Saved) do if current==target then found=true break end end
                if not found then table.insert(State.Saved,target) end
            end
        end
    	local list = {}
    	local seen = {}
    	for _, root in ipairs(getRoots()) do
    		local ok, all = pcall(function()
    			return root:GetDescendants()
    		end)
    		if ok and all then
    			for _, inst in ipairs(all) do
    				local okG, isGui = pcall(function()
    					return inst:IsA("GuiObject")
    				end)
    				if okG and isGui then
    					local matched = false
    					pcall(function()
    						matched = probeCandidate(inst)
    					end)
    					if matched and not seen[inst] and not insideRobloxGui(inst)
    						and hasSize(inst) and isVisible(inst)
    						and not isBigAutoButton(inst) then
    						seen[inst] = true
    						table.insert(list, inst)
    					end
    				end
    			end
    		end
    	end
    	local mb = State.ManualBind
    	if mb and mb.Parent and isVisible(mb) and not seen[mb] then
    		seen[mb] = true
    		table.insert(list, mb)
    	end

    	local keptSaved = {}
    	for _, c in ipairs(State.Saved) do
    		local alive = false
    		pcall(function()
    			alive = c.Parent ~= nil
    		end)
    		if alive then
    			table.insert(keptSaved, c)
    			if not seen[c] then
    				seen[c] = true
    				table.insert(list, c)
    			end
    		end
    	end
    	State.Saved = keptSaved
    	Cache.list = list
    	Cache.dirty = false
    	return list
    end

    local function lightScan()
        for _,path in ipairs(State.SavedPaths) do
            local target=ODHX.Resolve(path)
            if target and target:IsA("GuiObject") then addCandidate(target) end
        end
    	local containers = {}
    	for _, root in ipairs(getRoots()) do
    		if root ~= LocalPlayer:FindFirstChildOfClass("PlayerGui") then
    			local ok, kids = pcall(function()
    				return root:GetChildren()
    			end)
    			if ok and kids then
    				for _, gui in ipairs(kids) do
    					local okS, isS = pcall(function()
    						return gui:IsA("ScreenGui")
    					end)
    					if okS and isS then
    						local nm = getName(gui) or ""
    						if nm:find("overdrive", 1, true) or nm:find("odh", 1, true)
    							or not nm:find("roblox", 1, true) then
    							table.insert(containers, gui)
    						end
    					end
    				end
    			end
    		end
    	end
    	for _, gui in ipairs(containers) do
    		local ok, all = pcall(function()
    			return gui:GetDescendants()
    		end)
    		if ok and all then
    			for _, inst in ipairs(all) do
    				local okG, isGui = pcall(function()
    					return inst:IsA("GuiObject")
    				end)
    				if okG and isGui then
    					local matched = false
    					pcall(function()
    						matched = probeCandidate(inst)
    					end)
    					if matched and not insideRobloxGui(inst) and hasSize(inst)
    						and isVisible(inst) and not isBigAutoButton(inst) then
    						addCandidate(inst)
    					end
    				end
    			end
    		end
    	end
    end

    local connectWatchdogs, disconnectWatchdogs

    local function getSnapshot(obj)
    	if originals[obj] then
    		if not SignalConns[obj] then
    			connectWatchdogs(obj, originals[obj])
    		end
    		return originals[obj]
    	end
    	local snap = {}
    	pcall(function()
    		if isa(obj, "GuiObject") then
    			snap.Background = obj.BackgroundColor3
    		end
    		if isa(obj, "ImageLabel") or isa(obj, "ImageButton") then
    			snap.Image = obj.ImageColor3
    		end
    		if isa(obj, "TextLabel") or isa(obj, "TextButton") or isa(obj, "TextBox") then
    			snap.Text       = obj.TextColor3
    			snap.TextStroke = obj.TextStrokeColor3
    		end
    		if isa(obj, "UIStroke") then
    			snap.UiStroke = obj.Color
    		end
    	end)
    	if next(snap) then
    		originals[obj] = snap
    		return snap
    	end
    	return nil
    end

    local WATCH_PROPS = {
    	Background = "BackgroundColor3",
    	Image      = "ImageColor3",
    	Text       = "TextColor3",
    	UiStroke   = "Color",
    }

    disconnectWatchdogs = function(obj)
    	local conns = SignalConns[obj]
    	if conns then
    		for _, c in ipairs(conns) do
    			pcall(function()
    				c:Disconnect()
    			end)
    		end
    		SignalConns[obj] = nil
    	end
    end

    local function trackedRootOf(obj)
    	local root = obj
    	local cur = obj.Parent
    	local depth = 0
    	while cur and depth < 40 do
    		if originals[cur] then
    			root = cur
    		end
    		cur = cur.Parent
    		depth = depth + 1
    	end
    	return root
    end

    local function normalKindColor(kind)
    	if kind == "Text" then
    		return State.TextColor
    	elseif kind == "UiStroke" then
    		return State.StrokeColor
    	end
    	return State.BgColor
    end

    local function classifyNow(obj, kind)
    	pending[obj] = nil
    	local w = weSet[obj]
    	local snap = originals[obj]
    	if not w or not snap then
    		return
    	end
    	local prop = WATCH_PROPS[kind]
    	local now
    	pcall(function()
    		now = obj[prop]
    	end)
    	if not now then
    		return
    	end

    	if w[kind] and closeColors(now, w[kind]) then
    		return
    	end
    	local mode = 2
    	if snap[kind] and closeColors(now, snap[kind]) then
    		mode = 1
    	end
    	if closeColors(now, normalKindColor(kind)) then
    		mode = 1
    	end
    	btnMode[obj] = mode
    	local root = trackedRootOf(obj)
    	btnMode[root] = mode
    	pending[root] = nil
    	pcall(function()
    		paintTree(root)
    	end)
    end

    local function observe(obj, kind)
    	local observed = {}
    	pending[obj] = observed
    	local ok = pcall(function()
    		task.delay(COMMIT_DELAY, function()
    			if State.Dead or pending[obj] ~= observed then
    				return
    			end
    			pcall(function()
    				classifyNow(obj, kind)
    			end)
    		end)
    	end)
    	if not ok then
    		pcall(function()
    			classifyNow(obj, kind)
    		end)
    	end
    end

    connectWatchdogs = function(obj, snap)
    	if SignalConns[obj] then
    		return
    	end
    	local conns = {}
    	for kind, prop in pairs(WATCH_PROPS) do
    		if snap[kind] then
    			pcall(function()
    				local conn = obj:GetPropertyChangedSignal(prop):Connect(function()
    					if State.Dead then
    						return
    					end
    					local w = weSet[obj]
    					if not w or not w[kind] then
    						return
    					end
    					local cur
    					pcall(function()
    						cur = obj[prop]
    					end)
    					if not cur then
    						return
    					end
    					if closeColors(cur, w[kind]) then

    						pending[obj] = nil
    						return
    					end

    					observe(obj, kind)
    				end)
    				table.insert(conns, conn)
    			end)
    		end
    	end
    	if #conns > 0 then
    		SignalConns[obj] = conns
    	end
    end

    local function onColor()
    	if isDarkColor(State.BgColor) then
    		return State.OnLight
    	end
    	return State.OnDark
    end

    local function paint(obj)
    	pcall(function()

    		if pending[obj] then
    			return
    		end
    		local snap = getSnapshot(obj)
    		if not snap then
    			return
    		end
    		local mode = btnMode[obj] or 1
    		local mainColor = State.BgColor
    		local strokeColor = State.StrokeColor
    		if mode == 2 then

    			mainColor = onColor()
    			strokeColor = onColor()
    		end

    		local w = {}
    		if snap.Background then
    			w.Background = mainColor
    		end
    		if snap.Image then
    			w.Image = mainColor
    		end
    		if snap.Text then
    			w.Text = State.TextColor
    		end
    		if snap.UiStroke then
    			w.UiStroke = strokeColor
    		end
    		weSet[obj] = w
    		if snap.Background then
    			obj.BackgroundColor3 = mainColor
    		end
    		if snap.Image then
    			obj.ImageColor3 = mainColor
    		end
    		if snap.Text then
    			obj.TextColor3       = State.TextColor
    			obj.TextStrokeColor3 = State.StrokeColor
    		end
    		if snap.UiStroke then
    			obj.Color = strokeColor
    		end
    	end)
    end

    paintTree = function(rootObj)
    	paint(rootObj)
    	local ok, all = pcall(function()
    		return rootObj:GetDescendants()
    	end)
    	if ok and all then
    		for _, d in ipairs(all) do
    			paint(d)
    		end
    	end
    end

    local function restoreOne(obj)
    	local snap = originals[obj]
    	if not snap or not obj then
    		return
    	end
    	disconnectWatchdogs(obj)
    	weSet[obj] = nil
    	pending[obj] = nil
    	btnMode[obj] = nil
    	pcall(function()
    		if obj.Parent then
    			if snap.Background then
    				obj.BackgroundColor3 = snap.Background
    			end
    			if snap.Image then
    				obj.ImageColor3 = snap.Image
    			end
    			if snap.Text then
    				obj.TextColor3       = snap.Text
    				obj.TextStrokeColor3 = snap.TextStroke
    			end
    			if snap.UiStroke then
    				obj.Color = snap.UiStroke
    			end
    		end
    	end)
    end

    restoreTree = function(rootObj)
    	restoreOne(rootObj)
    	local ok, all = pcall(function()
    		return rootObj:GetDescendants()
    	end)
    	if ok and all then
    		for _, d in ipairs(all) do
    			restoreOne(d)
    		end
    	end
    end

    local function restoreAll()
    	for obj, snap in pairs(originals) do
    		if snap then
    			restoreOne(obj)
    		end
    	end
    end

    local function applyCached()
    	if not State.Active then
    		return 0
    	end
    	local final = {}
    	local painted = {}
    	local n = 0
    	for _, inst in ipairs(Cache.list) do
    		local alive = isAliveInstance(inst)
    		if alive then
    			table.insert(final, inst)
    			local underPainted = false
    			local cur = inst.Parent
    			local depth = 0
    			while cur and depth < 40 do
    				if painted[cur] then
    					underPainted = true
    					break
    				end
    				cur = cur.Parent
    				depth = depth + 1
    			end
    			if not underPainted then
    				painted[inst] = true
    				paintTree(inst)
    				n = n + 1
    			end
    		else

    			disconnectWatchdogs(inst)
    		end
    	end
    	Cache.list = final
    	return n
    end

    local Connections = {}

    local function onDescendantAdded(inst)
    	if State.Dead or not genAlive() then
    		return
    	end

    	local okG, isGui = pcall(function()
    		return inst:IsA("GuiObject")
    	end)
    	if not (okG and isGui) then
    		return
    	end
    	local matched = false
    	pcall(function()
    		matched = probeCandidate(inst)
    	end)
    	if matched and not insideRobloxGui(inst) and hasSize(inst)
    		and isVisible(inst) and not isBigAutoButton(inst) then
    		addCandidate(inst)
    	end
    end

    local function connectEvents()
    	for _, root in ipairs(getRoots()) do
    		pcall(function()
    			local conn = root.DescendantAdded:Connect(onDescendantAdded)
    			table.insert(Connections, conn)
    		end)
    	end
    	return #Connections > 0
    end

    local function disconnectEvents()
    	for _, conn in ipairs(Connections) do
    		pcall(function()
    			conn:Disconnect()
    		end)
    	end
    	Connections = {}
    end

    local eventsOk = false
    pcall(function()
    	eventsOk = connectEvents()
    end)
    pcall(function()
    	task.spawn(function()
    		while not State.Dead and genAlive() do
    			pcall(function()
    				Cache.tick = Cache.tick + 1
    				applyCached()
    				if Cache.tick % LIGHT_RESCAN_TICKS == 0 then
    					if Cache.dirty then
    						fullScan()
    					else
    						lightScan()
    					end
    					applyCached()
    				end
    			end)
    			task.wait(APPLY_INTERVAL)
    		end
    	end)
    end)
    if not eventsOk then

    	pcall(function()
    		if type(spawn) == "function" and type(wait) == "function" then
    			spawn(function()
    				while not State.Dead and genAlive() do
    					pcall(function()
    						Cache.tick = Cache.tick + 1
    						if Cache.dirty or Cache.tick % 4 == 0 then
    							fullScan()
    						end
    						applyCached()
    					end)
    					wait(APPLY_INTERVAL)
    				end
    			end)
    		end
    	end)
    end

    local function later(sec, fn)
    	local ok = pcall(function()
    		task.delay(sec, fn)
    	end)
    	if not ok then
    		pcall(function()
    			spawn(function()
    				wait(sec)
    				fn()
    			end)
    		end)
    	end
    end

    local function hitTest(x, y)
    	local best, bestArea, bestIsBtn = nil, nil, nil
    	for _, root in ipairs(getRoots()) do
    		local ok, all = pcall(function()
    			return root:GetDescendants()
    		end)
    		if ok and all then
    			for _, inst in ipairs(all) do
    				if isa(inst, "GuiObject") and isVisible(inst)
    					and inst.Name ~= "BTPicker" and inst.Name ~= "BBCPicker" then
    					local okP, pos = pcall(function()
    						return inst.AbsolutePosition
    					end)
    					local okS, size = pcall(function()
    						return inst.AbsoluteSize
    					end)
    					if okP and okS and pos and size then
    						local pad = 20
    						if x >= pos.X - pad and x <= pos.X + size.X + pad
    							and y >= pos.Y - pad and y <= pos.Y + size.Y + pad then
    							local area = size.X * size.Y
    							local isBtn = isButtonClass(inst)
    							local better = false
    							if not best then
    								better = true
    							elseif isBtn and not bestIsBtn then
    								better = true
    							elseif isBtn == bestIsBtn and area < bestArea then
    								better = true
    							end
    							if better then
    								best, bestArea, bestIsBtn = inst, area, isBtn
    							end
    						end
    					end
    				end
    			end
    		end
    	end
    	return best
    end

    local function pickAt(x, y)
    	local best = hitTest(x, y)
    	if best then

    		local alreadySaved = false
    		for _, s in ipairs(State.Saved) do
    			if s == best then
    				alreadySaved = true
    				break
    			end
    		end
    		local old = State.ManualBind
    		local replaced = false
    		if old and old ~= best then
    			replaced = true
    			pcall(function()
    				restoreTree(old)
    			end)
    			local kept = {}
    			for _, inst in ipairs(Cache.list) do
    				if inst ~= old then
    					table.insert(kept, inst)
    				end
    			end
    			Cache.list = kept
    		end
    		State.ManualBind = best
    		pcall(function()
    			if State.Active then
    				paintTree(best)
    			end
    		end)
    		local inCache = false
    		for _, inst in ipairs(Cache.list) do
    			if inst == best then
    				inCache = true
    				break
    			end
    		end
    		if not inCache then
    			table.insert(Cache.list, best)
    		end
    		local nm, cls, w, h = "?", "?", 0, 0
    		pcall(function()
    			nm = sanitize(best.Name)
    		end)
    		pcall(function()
    			cls = tostring(best.ClassName)
    		end)
    		pcall(function()
    			w = math.floor(best.AbsoluteSize.X + 0.5)
    			h = math.floor(best.AbsoluteSize.Y + 0.5)
    		end)
    		shared.Notify("Picked: " .. nm .. " [" .. cls .. "] " .. w .. "x" .. h
    			.. (alreadySaved and " (already saved)" or " — press SAVE CURRENT BUTTON to keep it")
    			.. (replaced and " • unsaved pick replaced" or ""), 4)
    		return nm .. "[" .. cls .. "]"
    	end
    	shared.Notify("No button found under that tap. Try again.", 3)
    	return nil
    end

    local pickActive = false

    local function startPick()
    	if pickActive then
    		shared.Notify("Pick mode is already on — tap a button!", 2)
    		return
    	end
    	pickActive = true
    	local ok, err = pcall(function()
    		local gui = Instance.new("ScreenGui")
    		gui.Name = "BBCPicker"
    		gui.ResetOnSpawn = false
    		gui.DisplayOrder = 2000000000
    		gui.IgnoreGuiInset = true
    		local btn = Instance.new("TextButton")
    		btn.Name = "BBCPicker"
    		btn.Size = UDim2.fromScale(1, 1)
    		btn.BackgroundTransparency = 1
    		btn.Text = ""
    		btn.AutoButtonColor = false
    		btn.Active = true
    		btn.ZIndex = 2147483647
    		btn.Parent = gui
    		local parent = SR_UI.service("CoreGui")
    		if not parent then
    			parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    		end
    		gui.Parent = parent

    		local conn
    		local finish = function(px, py)
    			if conn then
    				pcall(function()
    					conn:Disconnect()
    				end)
    				conn = nil
    			end
    			pcall(function()
    				gui:Destroy()
    			end)
    			pickActive = false
    			if px then
    				pickAt(px, py)
    			end
    		end

    		conn = btn.Activated:Connect(function(inputObject)
    			local px, py = nil, nil
    			pcall(function()
    				px = inputObject.Position.X
    				py = inputObject.Position.Y
    			end)
    			finish(px, py)
    		end)

    		pcall(function()
    			task.delay(PICK_SECONDS, function()
    				if pickActive then
    					shared.Notify("Pick cancelled: time is up.", 2)
    					finish(nil, nil)
    				end
    			end)
    		end)
    	end)
    	if not ok then
    		pickActive = false
    		shared.Notify("Could not start pick mode: " .. sanitize(tostring(err)), 3)
    		return
    	end
    	shared.Notify("Tap a button within " .. PICK_SECONDS .. " seconds!", 4)
    end

    local function saveCurrent()
    	local mb = State.ManualBind
    	if not mb then
    		shared.Notify("Nothing to save — pick a button by tap first.", 3)
    		return
    	end
    	local alive = false
    	pcall(function()
    		alive = mb.Parent ~= nil
    	end)
    	if not alive then
    		State.ManualBind = nil
    		shared.Notify("That button no longer exists — pick another one.", 3)
    		return
    	end
    	local already = false
    	for _, s in ipairs(State.Saved) do
    		if s == mb then
    			already = true
    			break
    		end
    	end
    	if not already then
    		table.insert(State.Saved, mb)
            local path=ODHX.Path(mb)
            if path then
                local signature=table.concat(path,"/")
                local found=false
                for _,p in ipairs(State.SavedPaths) do if table.concat(p,"/")==signature then found=true end end
                if not found then table.insert(State.SavedPaths,path) end
            end
    	end
    	State.ManualBind = nil
    	shared.Notify("Button saved! Total saved: " .. #State.Saved
    		.. (already and " (was already saved)" or ""), 4)
    end

    local function clearCurrent()
    	local mb = State.ManualBind
    	State.ManualBind = nil
    	if mb then
    		restoreTree(mb)
    	end
    	local kept = {}
    	for _, inst in ipairs(Cache.list) do
    		if inst ~= mb then
    			table.insert(kept, inst)
    		end
    	end
    	Cache.list = kept
    	shared.Notify("Unsaved pick removed" .. (mb and ", its color restored." or "."), 2)
    end

    local function clearSaved()
        State.SavedPaths = {}
    	local count = #State.Saved
    	local ours = {}
    	for _, s in ipairs(State.Saved) do
    		ours[s] = true
    		pcall(function()
    			restoreTree(s)
    		end)
    	end
    	local mb = State.ManualBind
    	if mb then
    		ours[mb] = true
    		pcall(function()
    			restoreTree(mb)
    		end)
    	end
    	State.Saved = {}
    	State.ManualBind = nil
    	local kept = {}
    	for _, inst in ipairs(Cache.list) do
    		if not ours[inst] then
    			table.insert(kept, inst)
    		end
    	end
    	Cache.list = kept
    	shared.Notify("Cleared saved buttons: " .. count .. " — original colors restored.", 3)
    end

    local function hardReset()
        State.SavedPaths = {}
    	State.Active     = false
    	State.ManualBind = nil
    	State.Saved      = {}
    	Cache.list       = {}
    	Cache.dirty      = true
    	restoreAll()
    	for obj in pairs(SignalConns) do
    		disconnectWatchdogs(obj)
    	end
    	for k in pairs(weSet) do
    		weSet[k] = nil
    	end
    	for k in pairs(pending) do
    		pending[k] = nil
    	end
    	for k in pairs(btnMode) do
    		btnMode[k] = nil
    	end
    	shared.Notify("Reset. Colors stay off until you touch a colorpicker.", 3)
    	local passes = { 0.3, 0.8, 1.5, 3 }
    	for i, sec in ipairs(passes) do
    		later(sec, function()
    			if not State.Active and not State.Dead then
    				restoreAll()
    				if i == #passes then
    					for obj in pairs(originals) do
    						local alive = false
    						pcall(function()
    							alive = obj and obj.Parent ~= nil
    						end)
    						if not alive then
    							originals[obj] = nil
    						end
    					end
    				end
    			end
    		end)
    	end
    end

    local function shutdown()
    	State.Dead = true
    	disconnectEvents()
    	restoreAll()
    	for obj in pairs(SignalConns) do
    		disconnectWatchdogs(obj)
    	end
    end

    pcall(function()
    	if type(getgenv) == "function" then
    		getgenv().BindableButtonColor = {
    			State       = State,
    			Cache       = Cache,
    			FullScan    = fullScan,
    			LightScan   = lightScan,
    			Apply       = applyCached,
    			Restore     = restoreAll,
    			Reset       = hardReset,
    			PickAt      = pickAt,
    			StartPick   = startPick,
    			SaveCurrent = saveCurrent,
    			ClearSaved  = clearSaved,
    			Shutdown    = shutdown,
    		}
    	end
    end)

    local section = shared.AddSection("Bindable Buttons Color")

    SR_Paragraph(section, "Change button colors", "The colorpickers paint the small Shoot Murderer bind buttons: " ..
    	"background, text and stroke. When you press a painted button, " ..
    	"it flips to the CONTRAST color: a dark button turns light, a " ..
    	"light button turns dark - the toggle state is always visible. " ..
    	"The big Shoot Murderer HUD " ..
    	"button is NOT colored automatically — pick it by tapping. " ..
    	"Tap-pick a button, then press Save current button to keep " ..
    	"it: every saved button stays colored. Picking again replaces " ..
    	"only the UNSAVED pick.")

    section:AddColorpicker("Button color (background/icon)", State.BgColor, function(c)
    	local col = toColor3(c)
    	if col then
    		State.BgColor = col
    	end
    	State.Active = true

    	if Cache.dirty and #Cache.list == 0 then
    		Cache.dirty = false
    		pcall(fullScan)
    	end
    	applyCached()
    end)

    section:AddColorpicker("Toggle ON light color (for dark buttons)", State.OnLight, function(c)
    	local col = toColor3(c)
    	if col then
    		State.OnLight = col
    	end
    	State.Active = true
    	if Cache.dirty and #Cache.list == 0 then
    		Cache.dirty = false
    		pcall(fullScan)
    	end
    	applyCached()
    end)

    section:AddColorpicker("Toggle ON dark color (for light buttons)", State.OnDark, function(c)
    	local col = toColor3(c)
    	if col then
    		State.OnDark = col
    	end
    	State.Active = true
    	if Cache.dirty and #Cache.list == 0 then
    		Cache.dirty = false
    		pcall(fullScan)
    	end
    	applyCached()
    end)

    section:AddColorpicker("Text color", State.TextColor, function(c)
    	local col = toColor3(c)
    	if col then
    		State.TextColor = col
    	end
    	State.Active = true
    	if Cache.dirty and #Cache.list == 0 then
    		Cache.dirty = false
    		pcall(fullScan)
    	end
    	applyCached()
    end)

    section:AddColorpicker("Stroke color", State.StrokeColor, function(c)
    	local col = toColor3(c)
    	if col then
    		State.StrokeColor = col
    	end
    	State.Active = true
    	if Cache.dirty and #Cache.list == 0 then
    		Cache.dirty = false
    		pcall(fullScan)
    	end
    	applyCached()
    end)

    section:AddButton("Pick a button by tap", function()
    	startPick()
    end)

    section:AddButton("Save current button", function()
    	saveCurrent()
    end)

    section:AddButton("Clear current pick (unsaved)", function()
    	clearCurrent()
    end)

    section:AddButton("Clear saved buttons", function()
    	clearSaved()
    end)

    section:AddButton("Reset (restore original)", function()
    	hardReset()
    end)

    section:AddLabel("Saved buttons keep their color • Reset clears everything")

    SR_Log("Bindable Buttons Color v5 loaded")

    later(1, function()
    	if not State.Dead then
    		pcall(fullScan)
    		pcall(applyCached)
    	end
    end)

    ODHX.Bind("Bindable Buttons Color", "Button color (background/icon)", "Colorpicker", function() return State.BgColor end)
    ODHX.Bind("Bindable Buttons Color", "Toggle ON light color (for dark buttons)", "Colorpicker", function() return State.OnLight end)
    ODHX.Bind("Bindable Buttons Color", "Toggle ON dark color (for light buttons)", "Colorpicker", function() return State.OnDark end)
    ODHX.Bind("Bindable Buttons Color", "Text color", "Colorpicker", function() return State.TextColor end)
    ODHX.Bind("Bindable Buttons Color", "Stroke color", "Colorpicker", function() return State.StrokeColor end)
    ODHX.cleanup=shutdown
    ODHX.Finish()

end
end)

SR_UI.tryModule("BJP", function()
do
    local ODHX = CreateODHX("BJP", "Bomb Jump+", "ODH_BJP_settings.json", true, false)
    local table_insert = table.insert

    local Maid = {}
    Maid.__index = Maid

    function Maid.new()
        return setmetatable({_tasks = {}, _destroyed = false}, Maid)
    end

    function Maid:GiveTask(task)
        if self._destroyed then
            self:_cleanupTask(task)
            return
        end
        table_insert(self._tasks, task)
        return task
    end

    function Maid:GiveTasks(...)
        for _, task in ipairs({...}) do
            self:GiveTask(task)
        end
    end

    function Maid:_cleanupTask(task)
        local taskType = typeof(task)
        if taskType == "RBXScriptConnection" then
            task:Disconnect()
        elseif taskType == "Instance" then
            task:Destroy()
        elseif taskType == "function" then
            task()
        elseif taskType == "table" and type(task.Destroy) == "function" then
            task:Destroy()
        end
    end

    function Maid:DoCleaning()
        if self._destroyed then return end
        self._destroyed = true
        for _, task in ipairs(self._tasks) do
            self:_cleanupTask(task)
        end
        self._tasks = {}
    end

    function Maid:Destroy()
        self:DoCleaning()
    end

    local RootMaid = Maid.new()

    local shared = ODHX.shared

    local Services = {
        Players = SR_UI.service("Players"),
        ReplicatedStorage = SR_UI.service("ReplicatedStorage"),
        RunService = SR_UI.service("RunService"),
        UserInputService = SR_UI.service("UserInputService"),
        StarterGui = SR_UI.service("StarterGui"),
        CoreGui = SR_UI.service("CoreGui"),
        Workspace = SR_UI.service("Workspace"),
        TweenService = SR_UI.service("TweenService"),
        SoundService = SR_UI.service("SoundService")
    }

    local LocalPlayer = Services.Players.LocalPlayer

    local __PCLR = Color3.new
    local __RGB = Color3.fromRGB
    local __UD2 = UDim2.new
    local __UD = UDim.new
    local __V2 = Vector2.new

    local function getfserv(s) return SR_UI.service(s) end

    local __RS   = getfserv("RunService")
    local __UIS  = getfserv("UserInputService")
    local __PLRS = getfserv("Players")
    local __TS   = getfserv("TweenService")

    local BBSystem = {Buttons = {}, Connections = {}}

    local function bb_safecallback(callback)
        if not callback then return end
        local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
        if not ok then warn("[BB ERROR] " .. tostring(err)) end
    end

    local function BB_GetStorage()
        local parent = gethui and gethui()
        if not parent or typeof(parent) ~= "Instance" then
            parent = getfserv("CoreGui")
        end
        if not parent or typeof(parent) ~= "Instance" then
            parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui", 5)
        end
        if typeof(parent) ~= "Instance" then
            parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui")
        end

        local sg = parent:FindFirstChild("@odh_bjp_bigstorage")
        if not sg then
            sg = Instance.new("ScreenGui")
            sg.Name = "@odh_bjp_bigstorage"
            sg.ResetOnSpawn = false
            sg.IgnoreGuiInset = true
            pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
            sg.Parent = parent
        end
        return sg
    end

    local __BB_GRAD_SEQ = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    __PCLR(0.0784314, 0.0784314, 0.0784314)),
        ColorSequenceKeypoint.new(0.75, __PCLR(0.0784314, 0.0784314, 0.54902)),
        ColorSequenceKeypoint.new(1,    __PCLR(0.470588,  0.156863,  0.470588))
    })

    local function BB_MakeDraggable(gui, func, ripple, sound)
        local dragging, dragInput, dragStart, startPos
        local hasMoved = false
        local tInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local normalSize    = __UD2(0, 200, 0, 75)
        local normalTxtSize = 24
        local bigSize       = __UD2(0, 220, 0, 82.5)
        local bigTxtSize    = 26.4

        ODHX.Connect(gui.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging  = true
                hasMoved  = false
                dragStart = input.Position
                startPos  = gui.Position
                __TS:Create(gui, tInfo, {Size = bigSize, TextSize = bigTxtSize}):Play()
                local absPos = gui.AbsolutePosition
                ripple.Position = __UD2(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
                ripple.Size = __UD2(0, 0, 0, 0)
                ripple.BackgroundTransparency = 0.5
                ripple.Visible = true
                sound:Play()
                __TS:Create(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    Size = __UD2(0, 300, 0, 300),
                    BackgroundTransparency = 1
                }):Play()
                local rel
                rel = ODHX.Connect(__UIS.InputEnded, function(endInput)
                    if endInput.UserInputType == input.UserInputType then
                        dragging = false
                        __TS:Create(gui, tInfo, {Size = normalSize, TextSize = normalTxtSize}):Play()
                        if not hasMoved then bb_safecallback(func)
                        else SR_Store.posSave("bjp", gui.Name, gui.Position) end
                        rel:Disconnect()
                    end
                end)
            end
        end)
        ODHX.Connect(gui.InputChanged, function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        ODHX.Connect(__UIS.InputChanged, function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                if delta.Magnitude > 7 then hasMoved = true end
                gui.Position = __UD2(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    local BindableButtons
    local muteButtonSounds = false

    local function UpdateAllButtonSounds()
        local volume = muteButtonSounds and 0 or 0.5
        for id, btn in pairs(BBSystem.Buttons) do
            local sound = btn:FindFirstChild("Sound")
            if sound then
                sound.Volume = volume
            end
        end
        for id, btn in pairs(BindableButtons.Buttons) do
            local sound = btn:FindFirstChild("Sound")
            if sound then
                sound.Volume = volume
            end
        end
    end

    local function AddBigButton(id, text, func, isGold, customSize)
        if BBSystem.Buttons[id] then return end
        local storage = BB_GetStorage()
        local bb = Instance.new("TextButton")
        bb.Name = id
        bb.Size = customSize or __UD2(0, 200, 0, 75)
        bb.Position = __UD2(0.5, 0, 0.5, 0)
        local savedBBPos = SR_Store.posGet("bjp", id)
        if savedBBPos then
            bb.Position = __UD2(savedBBPos.xs, savedBBPos.xo, savedBBPos.ys, savedBBPos.yo)
        end
        bb.AnchorPoint = __V2(0.5, 0.5)
        bb.BackgroundColor3 = __RGB(255, 255, 255)
        bb.BackgroundTransparency = 0.9
        bb.BorderSizePixel = 0
        bb.Font = Enum.Font.Jura
        bb.Text = text
        bb.TextSize = 24
        bb.TextColor3 = __RGB(255, 255, 255)
        bb.TextWrapped = true
        bb.ClipsDescendants = true
        bb.AutoButtonColor = false
        bb.ZIndex = 5
        bb.Parent = storage

        Instance.new("UICorner", bb).CornerRadius = __UD(0, 5)
        local stroke = Instance.new("UIStroke")
        stroke.Color = __RGB(255, 255, 255)
        stroke.Thickness = 1.5
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = bb
        local gradient = Instance.new("UIGradient")

        if isGold then
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,    __RGB(255, 215, 0)),
                ColorSequenceKeypoint.new(0.5,  __RGB(255, 140, 0)),
                ColorSequenceKeypoint.new(1,    __RGB(184, 134, 11))
            })
        else
            gradient.Color = __BB_GRAD_SEQ
        end
        gradient.Parent = stroke

        local ripple = Instance.new("Frame")
        ripple.Name = "@ripple"
        ripple.BackgroundColor3 = isGold and __RGB(255, 215, 0) or __RGB(0, 155, 255)
        ripple.BackgroundTransparency = 0.5
        ripple.ZIndex = 4
        ripple.Size = __UD2(0, 0, 0, 0)
        ripple.AnchorPoint = __V2(0.5, 0.5)
        ripple.Visible = false
        ripple.Parent = bb
        Instance.new("UICorner", ripple).CornerRadius = __UD(1, 0)

        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://3868133279"
        sound.Volume = muteButtonSounds and 0 or 0.5
        sound.Parent = bb

        BB_MakeDraggable(bb, func, ripple, sound)
        BBSystem.Connections[id] = SR_Rota.Attach(gradient, nil, 60)
        BBSystem.Buttons[id] = bb
        return bb
    end

    local function DeleteBigButton(id)
        if BBSystem.Buttons[id] then
            if BBSystem.Connections[id] then
                BBSystem.Connections[id]:Disconnect()
                BBSystem.Connections[id] = nil
            end
            BBSystem.Buttons[id]:Destroy()
            BBSystem.Buttons[id] = nil
        end
    end

    BindableButtons = {Buttons = {}, Maids = {}, Count = 0}

    local __SHAPES = {
        [0] = "rbxassetid://86221076925479",
        [1] = "rbxassetid://96242665417546",
        [2] = "rbxassetid://97129189935336",
        [3] = "rbxassetid://76165862027868",
        [4] = "rbxassetid://125868092127496"
    }

    local __NORMAL_COLOR = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   __PCLR(0.133333, 0.827451, 0.494118)),
        ColorSequenceKeypoint.new(0.6, __PCLR(0.231373, 0.509804, 0.498039)),
        ColorSequenceKeypoint.new(1,   __PCLR(0.501961, 0.501961, 0.501961))
    })

    local __WAIT_COLOR = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   __PCLR(0.827451, 0.133333, 0.133333)),
        ColorSequenceKeypoint.new(0.6, __PCLR(0.509804, 0.231373, 0.231373)),
        ColorSequenceKeypoint.new(1,   __PCLR(0.501961, 0.501961, 0.501961))
    })

    local __GOLD_NORMAL_COLOR = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   __RGB(255, 215, 0)),
        ColorSequenceKeypoint.new(0.6, __RGB(255, 140, 0)),
        ColorSequenceKeypoint.new(1,   __RGB(184, 134, 11))
    })

    local __GOLD_WAIT_COLOR = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   __RGB(255, 69, 0)),
        ColorSequenceKeypoint.new(0.6, __RGB(139, 69, 19)),
        ColorSequenceKeypoint.new(1,   __RGB(160, 82, 45))
    })

    local function bind_safecallback(callback)
        if not callback then return end
        local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
        if not ok then warn("[BIND ERROR] " .. tostring(err)) end
    end

    local function Bind_GetStorage()
        local parent = gethui and gethui()
        if not parent or typeof(parent) ~= "Instance" then
            parent = getfserv("CoreGui")
        end
        if not parent or typeof(parent) ~= "Instance" then
            parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui", 5)
        end
        if typeof(parent) ~= "Instance" then
            parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui")
        end

        local sg = parent:FindFirstChild("@odh_bjp_bindstorage")
        if not sg then
            sg = Instance.new("ScreenGui")
            sg.Name = "@odh_bjp_bindstorage"
            sg.ResetOnSpawn = false
            sg.IgnoreGuiInset = true
            pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
            sg.Parent = parent
        end
        return sg
    end

    local function Bind_MakeDraggable(gui, maid, ripple, sound, clickFunc)
        local dragging, dragInput, dragStart, startPos
        local hasMoved = false

        maid:GiveTask(ODHX.Connect(gui.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging, dragStart, startPos = true, input.Position, gui.Position
                hasMoved = false
                sound:Play()
                local absPos = gui.AbsolutePosition
                ripple.Position = __UD2(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
                ripple.Size = __UD2(0, 0, 0, 0)
                ripple.BackgroundTransparency = 0.5
                ripple.Visible = true
                __TS:Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    Size = __UD2(0, 45, 0, 45),
                    BackgroundTransparency = 1
                }):Play()

                local rel
                rel = ODHX.Connect(__UIS.InputEnded, function(endInput)
                    if endInput.UserInputType == input.UserInputType then
                        dragging = false
                        if not hasMoved then
                            bind_safecallback(clickFunc)
                        else
                            SR_Store.posSave("bjp", gui.Name, gui.Position)
                        end
                        rel:Disconnect()
                    end
                end)
            end
        end))

        maid:GiveTask(ODHX.Connect(gui.InputChanged, function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end))

        maid:GiveTask(ODHX.Connect(__UIS.InputChanged, function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                if delta.Magnitude > 7 then hasMoved = true end
                local screen = gui.Parent.AbsoluteSize
                gui.Position = __UD2(startPos.X.Scale + (delta.X / screen.X), 0, startPos.Y.Scale + (delta.Y / screen.Y), 0)
            end
        end))
    end

    function BindableButtons.AddBButton(id, text, clickFunc, isGold, customSize)
        if BindableButtons.Buttons[id] then return end

        local buttonMaid = Maid.new()
        local camera = workspace.CurrentCamera
        local screen = camera.ViewportSize
        local buttonSizeY = customSize or 0.11
        local widthScale = buttonSizeY * (screen.Y / screen.X)
        local xPos = 0.1 + ((BindableButtons.Count % 8) * (widthScale + 0.005))
        local yPos = 0.9 - (math.floor(BindableButtons.Count / 8) * (buttonSizeY + 0.015))

        local ImageButton = Instance.new("ImageButton")
        ImageButton.Name = id
        ImageButton.Size = __UD2(widthScale, 0, buttonSizeY, 0)
        ImageButton.Position = __UD2(xPos, 0, yPos, 0)
        local savedPos = SR_Store.posGet("bjp", id)
        if savedPos then
            ImageButton.Position = __UD2(savedPos.xs, savedPos.xo, savedPos.ys, savedPos.yo)
        end
        ImageButton.AnchorPoint = __V2(0.5, 0.5)
        ImageButton.Image = __SHAPES[0]
        ImageButton.BackgroundTransparency = 1
        ImageButton.BorderSizePixel = 0
        ImageButton.ClipsDescendants = false
        ImageButton.AutoButtonColor = false
        ImageButton.Parent = Bind_GetStorage()
        buttonMaid:GiveTask(ImageButton)

        local TextLabel = Instance.new("TextLabel", ImageButton)
        TextLabel.Name = "@Text"
        TextLabel.Size = __UD2(0.8, 0, 0.8, 0)
        TextLabel.Position = __UD2(0.5, 0, 0.5, 0)
        TextLabel.AnchorPoint = __V2(0.5, 0.5)
        TextLabel.BackgroundTransparency = 1
        TextLabel.Font = Enum.Font.Jura
        TextLabel.Text = text
        TextLabel.TextColor3 = __PCLR(1, 1, 1)
        TextLabel.TextSize = math.floor(buttonSizeY * 90)
        TextLabel.TextWrapped = true
        TextLabel.ZIndex = 3

        local Aspect = Instance.new("UIAspectRatioConstraint", ImageButton)
        Aspect.AspectRatio = 1
        Aspect.AspectType = Enum.AspectType.ScaleWithParentSize

        local Stroke = Instance.new("UIGradient", ImageButton)
        Stroke.Name = "@Stroke"
        if isGold then
            Stroke.Color = __GOLD_NORMAL_COLOR
        else
            Stroke.Color = __NORMAL_COLOR
        end

        local ripple = Instance.new("Frame")
        ripple.Name = "@ripple"
        ripple.BackgroundColor3 = isGold and __RGB(255, 215, 0) or __RGB(0, 155, 255)
        ripple.BackgroundTransparency = 0.5
        ripple.Size = __UD2(0, 0, 0, 0)
        ripple.AnchorPoint = __V2(0.5, 0.5)
        ripple.Visible = false
        ripple.ZIndex = 2
        ripple.Parent = ImageButton
        Instance.new("UICorner", ripple).CornerRadius = __UD(1, 0)

        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://3868133279"
        sound.Volume = muteButtonSounds and 0 or 0.5
        sound.Parent = ImageButton

        Bind_MakeDraggable(ImageButton, buttonMaid, ripple, sound, clickFunc)
        buttonMaid:GiveTask(SR_Rota.Attach(Stroke, nil, 60))

        BindableButtons.Buttons[id] = ImageButton
        BindableButtons.Maids[id] = buttonMaid
        BindableButtons.Count = BindableButtons.Count + 1
        return ImageButton
    end

    function BindableButtons.DeleteBButton(id)
        if BindableButtons.Maids[id] then
            BindableButtons.Maids[id]:Destroy()
            BindableButtons.Maids[id] = nil
            BindableButtons.Buttons[id] = nil
        end
    end

    function BindableButtons.UpdateBButtonText(id, text, isWaiting, isGold)
        local btn = BindableButtons.Buttons[id]
        if not btn then return end

        local textLabel = btn:FindFirstChild("@Text")
        if textLabel then
            textLabel.Text = text
        end

        local stroke = btn:FindFirstChild("@Stroke")
        if stroke then
            if isGold then
                stroke.Color = isWaiting and __GOLD_WAIT_COLOR or __GOLD_NORMAL_COLOR
            else
                stroke.Color = isWaiting and __WAIT_COLOR or __NORMAL_COLOR
            end
        end
    end

    local function GetSafeGuiRoot()
        local success, result = pcall(function()
            return gethui()
        end)
        if success and result and typeof(result) == "Instance" then
            return result
        end
        return Services.CoreGui
    end

    local hiddenGui = Instance.new("ScreenGui")
    hiddenGui.Name = "HiddenGui"
    hiddenGui.ResetOnSpawn = false
    hiddenGui.IgnoreGuiInset = true
    hiddenGui.Parent = GetSafeGuiRoot()
    RootMaid:GiveTask(hiddenGui)

    local function isMurderMysteryPlace()
        local name = type(shared.game_name) == "string" and shared.game_name or ""
        if name:find("Murder Mystery", 1, true) then return true end
        return game.PlaceId == 142823291 or game.GameId == 66654135
    end

    if isMurderMysteryPlace() then

    local aboutSection = shared.AddSection("About")

    SR_Paragraph(aboutSection, "Bomb Jump+", "Plugin Made by Noir_Creator")

    aboutSection:AddToggle("Mute Button SFX", function(bool)
        muteButtonSounds = bool
        UpdateAllButtonSounds()
    end)

    SR_Log("Bomb Jump+ loaded")

    local CONFIG = {
        CooldownTime = 22.0,
        LaunchPower = 58,
        MinSize = 50,
        MaxSize = 300,
        DefaultSize = 90,
        BindDefaultSize = 0.11
    }

    local BOMB_NAMES = {
        "FakeBomb",
        "Bomb",
        "GiftBomb",
        "PresentBomb",
        "Snowball",
        "CandyBomb"
    }

    local BOMB_CONFIGS = {
        FakeBomb = {
            Cooldown = 22,
            Power = 58,
            IsGold = false,
            RemotePath = "Remote",
            DisplayName = "Bomb Jump"
        },
        GoldBomb = {
            Cooldown = 4,
            Power = 65,
            IsGold = true,
            RemotePath = "Remote",
            DisplayName = "Gold Bomb Jump"
        }
    }

    local function CreateBombJumpSystem(config)

        local bombConfig = BOMB_CONFIGS[config.bombType]
        if not bombConfig then return nil end

        local isGold = bombConfig.IsGold
        local bombName = config.bombType
        local cooldownTime = bombConfig.Cooldown
        local launchPower = bombConfig.Power
        local displayName = config.displayName or bombConfig.DisplayName

        local state = {
            enabled = false,
            onCooldown = false,
            debounce = false,
            autoGetBomb = false,
            justRespawned = false,
            bigButtonSize = config.bigButtonSize or 200,
            bindButtonSize = config.bindButtonSize or 0.11,
            bigBtnExists = false,
            bindBtnExists = false,
            bindButton = nil,
            activeTouches = {}
        }

        local systemMaid = Maid.new()
        RootMaid:GiveTask(systemMaid)

        local Sounds = {
            Click = Instance.new("Sound"),
            Cooldown = Instance.new("Sound")
        }
        Sounds.Click.SoundId = "rbxassetid://6895079853"
        Sounds.Click.Volume = 1.0
        Sounds.Cooldown.SoundId = "rbxassetid://138090596"
        Sounds.Cooldown.Volume = 1.0

        local function PlaySound(snd)
            pcall(function()
                if snd then
                    Services.SoundService:PlayLocalSound(snd)
                end
            end)
        end

        local function IsPlayerInAir()
            local character = LocalPlayer.Character
            if not character then return false end

            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid then return false end

            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return false end

            local state = humanoid:GetState()
            if state == Enum.HumanoidStateType.Jumping or
               state == Enum.HumanoidStateType.FallingDown or
               state == Enum.HumanoidStateType.Freefall then
                return true
            end

            local velocityY = rootPart.Velocity.Y
            return math.abs(velocityY) > 0.5
        end

        local function ResetCooldown()
            state.onCooldown = false
            local bigBtn = BBSystem.Buttons[config.bigButtonId]
            if bigBtn then bigBtn.Text = displayName end
            if state.bindButton then
                BindableButtons.UpdateBButtonText(config.bindButtonId,
                    isGold and "GBJ" or "BJ", false, isGold)
            end
        end

        local function StartCooldown()
            state.onCooldown = true
            state.debounce = false
            local bigBtn = BBSystem.Buttons[config.bigButtonId]
            if bigBtn then bigBtn.Text = "Wait" end
            if state.bindButton then
                BindableButtons.UpdateBButtonText(config.bindButtonId,
                    "Wait", true, isGold)
            end

            task.spawn(function()
                for i = cooldownTime, 1, -1 do
                    if not state.onCooldown then break end
                    local bigBtn = BBSystem.Buttons[config.bigButtonId]
                    if bigBtn then bigBtn.Text = tostring(i) end
                    if state.bindButton then
                        BindableButtons.UpdateBButtonText(config.bindButtonId,
                            tostring(i), true, isGold)
                    end
                    task.wait(1)
                end
                if state.onCooldown then ResetCooldown() end
            end)
        end

        local function GetCenterPosition()
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local root = character.HumanoidRootPart

                local lookDir = Services.Workspace.CurrentCamera.CFrame.LookVector
                return root.Position + (lookDir * 3) + Vector3.new(0, -2, 0)
            end
            return nil
        end

        local function MakeCharacterJump()
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end

        local function UnequipBomb(bombName)
            task.spawn(function()
                task.wait(0.5)
                local character = LocalPlayer.Character
                if character then
                    local bomb = character:FindFirstChild(bombName)
                    if bomb then
                        bomb.Parent = LocalPlayer.Backpack or character
                    end
                end
            end)
        end

        local function GetAnyBomb(bombName)
            local character = LocalPlayer.Character
            if not character then return false, nil end

            local bombNamesToCheck = {bombName}
            if bombName == "FakeBomb" then

                bombNamesToCheck = BOMB_NAMES
            end

            for _, name in ipairs(bombNamesToCheck) do
                local bomb = character:FindFirstChild(name)
                if bomb then return true, bomb end
            end

            local backpack = LocalPlayer:FindFirstChild("Backpack")
            if backpack then
                for _, name in ipairs(bombNamesToCheck) do
                    local bomb = backpack:FindFirstChild(name)
                    if bomb then
                        bomb.Parent = character
                        return true, bomb
                    end
                end
            end

            local success = false
            local attempts = 0
            while not success and attempts < 3 do
                attempts = attempts + 1
                local ok = pcall(function()
                    Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(bombName)
                end)
                if ok then
                    success = true
                    break
                end
                task.wait(0.1)
            end

            if success then
                for _ = 1, 5 do
                    for _, name in ipairs(bombNamesToCheck) do
                        local bomb = character:FindFirstChild(name)
                        if bomb then return true, bomb end
                        if backpack then
                            bomb = backpack:FindFirstChild(name)
                            if bomb then
                                bomb.Parent = character
                                return true, bomb
                            end
                        end
                    end
                    task.wait(0.05)
                end
            end

            return false, nil
        end

        local function IsHoldingBomb(bombName)
            local character = LocalPlayer.Character
            if not character then return false end

            local bombNamesToCheck = {bombName}
            if bombName == "FakeBomb" then
                bombNamesToCheck = BOMB_NAMES
            end

            for _, name in ipairs(bombNamesToCheck) do
                if character:FindFirstChild(name) then
                    return true
                end
            end
            return false
        end

        local function FastBombJump()
            if not IsPlayerInAir() then return end
            if state.onCooldown or state.debounce or state.justRespawned then return end
            state.debounce = true

            local success, bomb = GetAnyBomb(bombName)

            if success and bomb then
                local position = GetCenterPosition()
                if position then
                    local remote = bomb:FindFirstChild("Remote")
                    if remote then
                        PlaySound(Sounds.Click)
                        pcall(function()
                            remote:FireServer(CFrame.new(position), 50)
                        end)
                    end

                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local currentVelocity = root.AssemblyLinearVelocity

                        root.AssemblyLinearVelocity = Vector3.new(
                            currentVelocity.X,
                            currentVelocity.Y + launchPower,
                            currentVelocity.Z
                        )
                    end

                    MakeCharacterJump()
                    UnequipBomb(bomb.Name)

                    task.spawn(function()
                        task.wait(0.1)
                        StartCooldown()
                    end)
                end
            end

            task.spawn(function()
                task.wait(0.5)
                state.debounce = false
            end)
        end

        local section = config.section

        section:AddLabel(displayName .. " Options")
        section:AddToggle("Enable Auto " .. displayName, function(bool)
            state.enabled = bool
        end)

        section:AddToggle("Auto-Get " .. bombName, function(bool)
            state.autoGetBomb = bool
            if bool then
                pcall(function()
                    Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(bombName)
                end)
            end
        end)

        section:AddToggle("Enable " .. displayName .. " Big Button", function(e)
            state.bigBtnExists = e
            if e then
                local size = __UD2(0, state.bigButtonSize, 0, state.bigButtonSize * 0.375)
                AddBigButton(config.bigButtonId, displayName, FastBombJump, isGold, size)
            else
                DeleteBigButton(config.bigButtonId)
            end
        end)

        section:AddSlider(displayName .. " Big Button Size", 50, 300, state.bigButtonSize, function(value)
            state.bigButtonSize = value
            local btn = BBSystem.Buttons[config.bigButtonId]
            if btn then
                btn.Size = __UD2(0, state.bigButtonSize, 0, state.bigButtonSize * 0.375)
            end
        end)

        section:AddToggle("Enable " .. displayName .. " Bind Button", function(e)
            state.bindBtnExists = e
            if e then
                local shortName = isGold and "GBJ" or "BJ"
                BindableButtons.AddBButton(config.bindButtonId, shortName, FastBombJump, isGold, state.bindButtonSize)
                state.bindButton = BindableButtons.Buttons[config.bindButtonId]
                if state.bindButton then
                    local screen = Services.Workspace.CurrentCamera.ViewportSize
                    state.bindButton.Size = __UD2(state.bindButtonSize * (screen.Y / screen.X), 0, state.bindButtonSize, 0)
                    BindableButtons.UpdateBButtonText(config.bindButtonId,
                        state.onCooldown and "Wait" or shortName, state.onCooldown, isGold)
                end
            else
                BindableButtons.DeleteBButton(config.bindButtonId)
                state.bindButton = nil
            end
        end)

        section:AddSlider(displayName .. " Bind Button Size", 5, 25, state.bindButtonSize * 100, function(value)
            state.bindButtonSize = value / 100
            if state.bindButton then
                local screen = Services.Workspace.CurrentCamera.ViewportSize
                state.bindButton.Size = __UD2(state.bindButtonSize * (screen.Y / screen.X), 0, state.bindButtonSize, 0)
            end
        end)

        section:AddKeybind(displayName .. " Keybind", config.keybind, FastBombJump)

        local TAP_MOVEMENT_THRESHOLD = 10
        local TAP_TIME_THRESHOLD = 0.3

        systemMaid:GiveTasks(
            ODHX.Connect(Services.UserInputService.InputBegan, function(input, gp)
                if gp then return end
                if input.UserInputType == Enum.UserInputType.Touch or
                   input.UserInputType == Enum.UserInputType.MouseButton1 then
                    state.activeTouches[input] = {
                        startPosition = input.Position,
                        startTime = tick(),
                        moved = false
                    }
                end
            end),
            ODHX.Connect(Services.UserInputService.InputChanged, function(input)
                local data = state.activeTouches[input]
                if data and (input.Position - data.startPosition).Magnitude > TAP_MOVEMENT_THRESHOLD then
                    data.moved = true
                end
            end),
            ODHX.Connect(Services.UserInputService.InputEnded, function(input, gp)
                if gp then
                    state.activeTouches[input] = nil
                    return
                end
                local data = state.activeTouches[input]
                if data and not data.moved and tick() - data.startTime <= TAP_TIME_THRESHOLD then
                    if state.enabled and not state.onCooldown and not state.debounce then
                        if IsHoldingBomb(bombName) and IsPlayerInAir() then
                            FastBombJump()
                        end
                    end
                end
                state.activeTouches[input] = nil
            end),
            ODHX.Connect(LocalPlayer.CharacterAdded, function()
                ResetCooldown()
                state.activeTouches = {}
                state.justRespawned = true
                task.wait(1)
                state.justRespawned = false
                if state.autoGetBomb then
                    task.wait(0.2)
                    pcall(function()
                        Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(bombName)
                    end)
                end
            end)
        )

        ODHX.Bind(section.Name, "Enable Auto " .. displayName, "Toggle", function() return state.enabled end)
        ODHX.Bind(section.Name, "Auto-Get " .. bombName, "Toggle", function() return state.autoGetBomb end)
        ODHX.Bind(section.Name, "Enable " .. displayName .. " Big Button", "Toggle", function() return state.bigBtnExists end)
        ODHX.Bind(section.Name, "Enable " .. displayName .. " Bind Button", "Toggle", function() return state.bindBtnExists end)
        ODHX.Bind(section.Name, displayName .. " Big Button Size", "Slider", function() return state.bigButtonSize end)
        ODHX.Bind(section.Name, displayName .. " Bind Button Size", "Slider", function() return state.bindButtonSize * 100 end)

        return {
            GetState = function() return state end,
            FastBombJump = FastBombJump,
            ResetCooldown = ResetCooldown,
            SetEnabled = function(bool) state.enabled = bool end,
            SetAutoGet = function(bool)
                state.autoGetBomb = bool
                if bool then
                    pcall(function()
                        Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(bombName)
                    end)
                end
            end
        }
    end

    local section = shared.AddSection("Bomb Jump+")

    local bombJumpSystem = CreateBombJumpSystem({
        bombType = "FakeBomb",
        section = section,
        displayName = "Bomb Jump",
        defaultEnabled = false,
        defaultAutoGet = false,
        defaultBigButton = false,
        defaultBindButton = false,
        bigButtonSize = 90,
        bindButtonSize = 0.11,
        keybind = "E",
        bigButtonId = "bombjump_big",
        bindButtonId = "bombjump_bind"
    })

    if _game == "Murder Mystery Modded" then
        local gbjSection = shared.AddSection("Gold Bomb Jump+")

        local goldBombJumpSystem = CreateBombJumpSystem({
            bombType = "GoldBomb",
            section = gbjSection,
            displayName = "Gold Bomb Jump",
            defaultEnabled = false,
            defaultAutoGet = false,
            defaultBigButton = false,
            defaultBindButton = false,
            bigButtonSize = 200,
            bindButtonSize = 0.11,
            keybind = "G",
            bigButtonId = "goldbombjump_big",
            bindButtonId = "goldbombjump_bind"
        })
    end

    ODHX.Bind("About", "Mute Button SFX", "Toggle", function() return muteButtonSounds end)

    end

    ODHX.cleanup=function()
        RootMaid:DoCleaning()
        for id in pairs(BBSystem.Buttons) do DeleteBigButton(id) end
        for id in pairs(BindableButtons.Buttons) do BindableButtons.DeleteBButton(id) end
    end
    ODHX.Finish()

    for btnId, btn in pairs(BBSystem.Buttons) do SR_Store.posApply("bjp", btnId, btn) end
    for btnId, btn in pairs(BindableButtons.Buttons) do SR_Store.posApply("bjp", btnId, btn) end

end
end)

SR_UI.tryModule("ButtonTransparency", function()
do
    local ODHX = CreateODHX("ButtonTransparency", "Button Transparency", "ODH_ButtonTransparency_settings.json", false, false)

    local shared = ODHX.shared
    if not shared then
    	warn("[Button Transparency] Load this file as a plugin through the Overdrive H menu!")
    	return
    end

    local DEFAULT_VALUE      = 0
    local APPLY_INTERVAL     = 4
    local LIGHT_RESCAN_TICKS = 6
    local BIG_MIN_WIDTH      = 100
    local PICK_SECONDS       = 6

    local MY_GEN = 0
    pcall(function()
    	if type(getgenv) == "function" then
    		local g = getgenv()

    		if type(g.ButtonTransparency) == "table" and type(g.ButtonTransparency.Shutdown) == "function" then
    			pcall(g.ButtonTransparency.Shutdown)
    		end
    		g.__BT_GEN = (g.__BT_GEN or 0) + 1
    		MY_GEN = g.__BT_GEN
    	end
    end)

    local function genAlive()
    	if MY_GEN == 0 then
    		return true
    	end
    	local ok, res = pcall(function()
    		return getgenv().__BT_GEN == MY_GEN
    	end)
    	return ok and res
    end

    local State = {
    	Value      = DEFAULT_VALUE,
    	Active     = false,
    	ManualBind = nil,
    	Dead       = false,
    }

    State.SavedPaths = {}
    State.ManualPath = nil
    if type(ODHX.data.snapshot) == "table" then
        local saved = ODHX.data.snapshot
        if typeof(saved.Value) == typeof(State.Value) then State.Value = saved.Value end
        if typeof(saved.Active) == typeof(State.Active) then State.Active = saved.Active end
        if type(saved.SavedPaths) == "table" then State.SavedPaths = saved.SavedPaths end
        if type(saved.ManualPath) == "table" then State.ManualPath = saved.ManualPath end
    end
    ODHX.capture = function()
        return {
            Value=State.Value,
            Active=State.Active,
            SavedPaths=State.SavedPaths, ManualPath=State.ManualPath,
        }
    end

    local Players     = SR_UI.service("Players")
    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
    	LocalPlayer = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    end

    local originals = setmetatable({}, { __mode = "k" })

    local Cache = {
    	list  = {},
    	dirty = true,
    	tick  = 0,
    }

    local fadeTree, restoreTree

    local TARGET   = "shootmurderer"
    local KEYWORDS = { "shoot", "murderer", "bind" }

    local TEXT_CLASSES = { TextLabel = true, TextButton = true, TextBox = true }
    local BTN_CLASSES  = { TextButton = true, ImageButton = true }

    local function clamp(v, a, b)
    	if v < a then
    		return a
    	elseif v > b then
    		return b
    	end
    	return v
    end

    local function normalize(s)
    	return (tostring(s):lower():gsub("%s+", ""))
    end

    local function stripRich(s)
    	s = tostring(s):gsub("<[^>]*>", "")
    	s = s:gsub("&%a+;", " ")
    	return s
    end

    local function sanitize(s)
    	s = tostring(s):gsub("%c", ""):gsub("%s", "")
    	if #s > 16 then
    		s = s:sub(1, 16) .. "…"
    	end
    	if s == "" then
    		s = "(unnamed)"
    	end
    	return s
    end

    local function isa(inst, cls)
    	local ok, res = pcall(function()
    		return inst:IsA(cls)
    	end)
    	return ok and res or false
    end

    local function isButtonClass(inst)
    	return isa(inst, "TextButton") or isa(inst, "ImageButton")
    end

    local function getPureText(inst)
    	local ok, txt = pcall(function()
    		return inst.Text
    	end)
    	if ok and txt ~= nil then
    		return normalize(stripRich(txt))
    	end
    	return nil
    end

    local function getName(inst)
    	local ok, n = pcall(function()
    		return normalize(inst.Name)
    	end)
    	if ok and n then
    		return n
    	end
    	return nil
    end

    local function matchesKeyword(s)
    	if not s then
    		return false
    	end
    	for _, k in ipairs(KEYWORDS) do
    		if s:find(k, 1, true) then
    			return true
    		end
    	end
    	return false
    end

    local function hasSize(inst)
    	local ok, s = pcall(function()
    		return inst.AbsoluteSize
    	end)
    	if not ok or not s then
    		return false
    	end
    	local okx, w = pcall(function()
    		return s.X
    	end)
    	local oky, h = pcall(function()
    		return s.Y
    	end)
    	return okx and oky and w >= 8 and h >= 8
    end

    local function isVisible(inst)
    	local cur = inst
    	local depth = 0
    	while cur and depth < 60 do
    		local ok, isGui = pcall(function()
    			return cur:IsA("GuiObject") or cur:IsA("ScreenGui")
    		end)
    		if ok and isGui then
    			local okv, vis = pcall(function()
    				return cur.Visible
    			end)
    			if okv and vis == false then
    				return false
    			end
    		end
    		local okp, par = pcall(function()
    			return cur.Parent
    		end)
    		if not okp then
    			break
    		end
    		cur = par
    	end
    	return true
    end

    local function isInsideOverdriveMenu(inst)
    	local cur = inst.Parent
    	local depth = 0
    	while cur and depth < 60 do
    		local okg, isGui = pcall(function()
    			return cur:IsA("GuiObject") or cur:IsA("ScreenGui")
    		end)
    		if okg and isGui then
    			local n = getName(cur)
    			if n and (n:find("overdrive", 1, true) or n:find("odh", 1, true)) then
    				return true
    			end
    			local okc, cls = pcall(function()
    				return cur.ClassName
    			end)
    			if okc and TEXT_CLASSES[cls] then
    				local t = getPureText(cur)
    				if t and (t:find("overdriveh", 1, true) or t:find("overdrivehub", 1, true)) then
    					return true
    				end
    			end
    		end
    		local okp, par = pcall(function()
    			return cur.Parent
    		end)
    		if not okp then
    			break
    		end
    		cur = par
    	end
    	return false
    end

    local function insideRobloxGui(inst)
    	local cur = inst.Parent
    	local depth = 0
    	while cur and depth < 60 do
    		local okS, isS = pcall(function()
    			return cur:IsA("ScreenGui")
    		end)
    		if okS and isS then
    			local n = getName(cur)
    			if n and n:find("roblox", 1, true) then
    				return true
    			end
    		end
    		local okp, par = pcall(function()
    			return cur.Parent
    		end)
    		if not okp then
    			break
    		end
    		cur = par
    	end
    	return false
    end

    local RootCache = { list = nil }

    local function getRoots()
    	if RootCache.list then
    		return RootCache.list
    	end
    	local roots = {}
    	local function add(r)
    		if r then
    			table.insert(roots, r)
    		end
    	end
    	pcall(function()
    		add(SR_UI.service("CoreGui"))
    	end)
    	pcall(function()
    		if gethui then
    			add(gethui())
    		end
    	end)
    	pcall(function()
    		add(LocalPlayer:FindFirstChildOfClass("PlayerGui"))
    	end)
    	RootCache.list = roots
    	return roots
    end

    local function probeCandidate(inst)
    	local ok, res = pcall(function()
    		local cls = inst.ClassName
    		local isBtn  = BTN_CLASSES[cls] or false
    		local isText = TEXT_CLASSES[cls] or false

    		if not (isBtn or isText or cls == "Frame" or cls == "ImageLabel") then
    			return false
    		end

    		local selfText = isText and normalize(stripRich(inst.Text)) or nil

    		local childText = nil
    		if isBtn then
    			local lbl = inst:FindFirstChildWhichIsA("TextLabel", true)
    			if lbl then
    				childText = normalize(stripRich(lbl.Text))
    			end
    		end

    		local n = normalize(inst.Name)
    		local matched = false

    		if selfText == TARGET or childText == TARGET then
    			matched = isBtn or not isInsideOverdriveMenu(inst)
    		end

    		if not matched and isBtn then
    			if (selfText and selfText:find(TARGET, 1, true))
    				or (childText and childText:find(TARGET, 1, true)) then
    				matched = true
    			elseif n:find(TARGET, 1, true) then
    				matched = not isInsideOverdriveMenu(inst)
    			end
    		end

    		if not matched and not isBtn then
    			local nameHit = n:find(TARGET, 1, true)
    			local textHit = selfText and selfText:sub(1, #TARGET) == TARGET
    			if nameHit or textHit then
    				matched = not isInsideOverdriveMenu(inst)
    			end
    		end

    		return matched
    	end)
    	return ok and res or false
    end

    local function smallKeywordButton(inst)
    	local ok, res = pcall(function()
    		local cls = inst.ClassName
    		if not (BTN_CLASSES[cls]) then
    			return false
    		end
    		local s = inst.AbsoluteSize
    		local w, h = s.X, s.Y
    		if not (w >= 8 and h >= 8 and w < BIG_MIN_WIDTH) then
    			return false
    		end
    		if matchesKeyword(normalize(inst.Name)) then
    			return true
    		end
    		local lbl = inst:FindFirstChildWhichIsA("TextLabel", true)
    		if lbl and matchesKeyword(normalize(stripRich(lbl.Text))) then
    			return true
    		end
    		return false
    	end)
    	return ok and res or false
    end

    local function addCandidate(inst)
    	for _, c in ipairs(Cache.list) do
    		if c == inst then
    			return
    		end
    	end
    	table.insert(Cache.list, inst)

    	if State.Active then
    		local t = clamp(State.Value, 0, 100) / 100
    		pcall(function()
    			if t <= 0 then
    				restoreTree(inst)
    			else
    				fadeTree(inst, t)
    			end
    		end)
    	end
    end

    local function fullScan()
        local restored=ODHX.Resolve(State.ManualPath)
        if restored and restored:IsA("GuiObject") then State.ManualBind=restored end
    	local list = {}
    	local seen = {}
    	for _, root in ipairs(getRoots()) do
    		local ok, all = pcall(function()
    			return root:GetDescendants()
    		end)
    		if ok and all then
    			for _, inst in ipairs(all) do
    				local okG, isGui = pcall(function()
    					return inst:IsA("GuiObject")
    				end)
    				if okG and isGui then
    					local matched = false
    					pcall(function()
    						matched = probeCandidate(inst) or smallKeywordButton(inst)
    					end)
    					if matched and not seen[inst] and not insideRobloxGui(inst)
    						and hasSize(inst) and isVisible(inst) then
    						seen[inst] = true
    						table.insert(list, inst)
    					end
    				end
    			end
    		end
    	end
    	local mb = State.ManualBind
    	if mb and mb.Parent and isVisible(mb) and not seen[mb] then
    		seen[mb] = true
    		table.insert(list, mb)
    	end

    	for _, c in ipairs(Cache.list) do
    		if c == State.ManualBind and not seen[c] then
    			local alive = false
    			pcall(function()
    				alive = c.Parent ~= nil
    			end)
    			if alive then
    				seen[c] = true
    				table.insert(list, c)
    			end
    		end
    	end
    	Cache.list = list
    	Cache.dirty = false
    	return list
    end

    local function lightScan()
        local restored=ODHX.Resolve(State.ManualPath)
        if restored and restored:IsA("GuiObject") then State.ManualBind=restored; addCandidate(restored) end
    	local containers = {}
    	for _, root in ipairs(getRoots()) do
    		if root ~= LocalPlayer:FindFirstChildOfClass("PlayerGui") then
    			local ok, kids = pcall(function()
    				return root:GetChildren()
    			end)
    			if ok and kids then
    				for _, gui in ipairs(kids) do
    					local okS, isS = pcall(function()
    						return gui:IsA("ScreenGui")
    					end)
    					if okS and isS then
    						local nm = getName(gui) or ""
    						if nm:find("overdrive", 1, true) or nm:find("odh", 1, true)
    							or not nm:find("roblox", 1, true) then
    							table.insert(containers, gui)
    						end
    					end
    				end
    			end
    		end
    	end
    	for _, gui in ipairs(containers) do
    		local ok, all = pcall(function()
    			return gui:GetDescendants()
    		end)
    		if ok and all then
    			for _, inst in ipairs(all) do
    				local okG, isGui = pcall(function()
    					return inst:IsA("GuiObject")
    				end)
    				if okG and isGui then
    					local matched = false
    					pcall(function()
    						matched = probeCandidate(inst) or smallKeywordButton(inst)
    					end)
    					if matched and not insideRobloxGui(inst) and hasSize(inst) and isVisible(inst) then
    						addCandidate(inst)
    					end
    				end
    			end
    		end
    	end
    end

    local function additive(orig, t)
    	return 1 - (1 - orig) * (1 - t)
    end

    local function getSnapshot(obj)
    	if originals[obj] then
    		return originals[obj]
    	end
    	local snap = {}
    	pcall(function()
    		if isa(obj, "GuiObject") then
    			snap.Background = obj.BackgroundTransparency
    		end
    		if isa(obj, "ImageLabel") or isa(obj, "ImageButton") then
    			snap.Image = obj.ImageTransparency
    		end
    		if isa(obj, "TextLabel") or isa(obj, "TextButton") or isa(obj, "TextBox") then
    			snap.Text   = obj.TextTransparency
    			snap.Stroke = obj.TextStrokeTransparency
    		end
    		if isa(obj, "UIStroke") then
    			snap.UiStroke = obj.Transparency
    		end
    	end)
    	if next(snap) then
    		originals[obj] = snap
    		return snap
    	end
    	return nil
    end

    local function fade(obj, t)
    	pcall(function()
    		local snap = getSnapshot(obj)
    		if not snap then
    			return
    		end
    		if snap.Background then
    			obj.BackgroundTransparency = additive(snap.Background, t)
    		end
    		if snap.Image then
    			obj.ImageTransparency = additive(snap.Image, t)
    		end
    		if snap.Text then
    			obj.TextTransparency       = additive(snap.Text, t)
    			obj.TextStrokeTransparency = additive(snap.Stroke, t)
    		end
    		if snap.UiStroke then
    			obj.Transparency = additive(snap.UiStroke, t)
    		end
    	end)
    end

    fadeTree = function(rootObj, t)
    	fade(rootObj, t)
    	local ok, all = pcall(function()
    		return rootObj:GetDescendants()
    	end)
    	if ok and all then
    		for _, d in ipairs(all) do
    			fade(d, t)
    		end
    	end
    end

    local function restoreOne(obj)
    	local snap = originals[obj]
    	if not snap or not obj then
    		return
    	end
    	pcall(function()
    		if obj.Parent then
    			if snap.Background then
    				obj.BackgroundTransparency = snap.Background
    			end
    			if snap.Image then
    				obj.ImageTransparency = snap.Image
    			end
    			if snap.Text then
    				obj.TextTransparency       = snap.Text
    				obj.TextStrokeTransparency = snap.Stroke
    			end
    			if snap.UiStroke then
    				obj.Transparency = snap.UiStroke
    			end
    		end
    	end)
    end

    restoreTree = function(rootObj)
    	restoreOne(rootObj)
    	local ok, all = pcall(function()
    		return rootObj:GetDescendants()
    	end)
    	if ok and all then
    		for _, d in ipairs(all) do
    			restoreOne(d)
    		end
    	end
    end

    local function restoreAll()
    	for obj, snap in pairs(originals) do
    		if snap then
    			restoreOne(obj)
    		end
    	end
    end

    local function applyCached()
    	if not State.Active then
    		return 0
    	end
    	local t = clamp(State.Value, 0, 100) / 100
    	local final = {}
    	local painted = {}
    	local n = 0
    	for _, inst in ipairs(Cache.list) do
    		local alive = isAliveInstance(inst)
    		if alive then
    			table.insert(final, inst)
    			local underPainted = false
    			local cur = inst.Parent
    			local depth = 0
    			while cur and depth < 40 do
    				if painted[cur] then
    					underPainted = true
    					break
    				end
    				cur = cur.Parent
    				depth = depth + 1
    			end
    			if not underPainted then
    				painted[inst] = true
    				if t <= 0 then
    					restoreTree(inst)
    				else
    					fadeTree(inst, t)
    				end
    				n = n + 1
    			end
    		end
    	end
    	Cache.list = final
    	return n
    end

    local Connections = {}

    local function onDescendantAdded(inst)
    	if State.Dead or not genAlive() then
    		return
    	end

    	local okG, isGui = pcall(function()
    		return inst:IsA("GuiObject")
    	end)
    	if not (okG and isGui) then
    		return
    	end
    	local matched = false
    	pcall(function()
    		matched = probeCandidate(inst) or smallKeywordButton(inst)
    	end)
    	if matched and not insideRobloxGui(inst) and hasSize(inst) and isVisible(inst) then
    		addCandidate(inst)
    	end
    end

    local function connectEvents()
    	for _, root in ipairs(getRoots()) do
    		pcall(function()
    			local conn = root.DescendantAdded:Connect(onDescendantAdded)
    			table.insert(Connections, conn)
    		end)
    	end
    	return #Connections > 0
    end

    local function disconnectEvents()
    	for _, conn in ipairs(Connections) do
    		pcall(function()
    			conn:Disconnect()
    		end)
    	end
    	Connections = {}
    end

    local eventsOk = false
    pcall(function()
    	eventsOk = connectEvents()
    end)
    pcall(function()
    	task.spawn(function()
    		while not State.Dead and genAlive() do
    			pcall(function()
    				Cache.tick = Cache.tick + 1
    				applyCached()
    				if Cache.tick % LIGHT_RESCAN_TICKS == 0 then
    					if Cache.dirty then
    						fullScan()
    					else
    						lightScan()
    					end
    					applyCached()
    				end
    			end)
    			task.wait(APPLY_INTERVAL)
    		end
    	end)
    end)
    if not eventsOk then

    	pcall(function()
    		if type(spawn) == "function" and type(wait) == "function" then
    			spawn(function()
    				while not State.Dead and genAlive() do
    					pcall(function()
    						Cache.tick = Cache.tick + 1
    						if Cache.dirty or Cache.tick % 4 == 0 then
    							fullScan()
    						end
    						applyCached()
    					end)
    					wait(APPLY_INTERVAL)
    				end
    			end)
    		end
    	end)
    end

    local function later(sec, fn)
    	local ok = pcall(function()
    		task.delay(sec, fn)
    	end)
    	if not ok then
    		pcall(function()
    			spawn(function()
    				wait(sec)
    				fn()
    			end)
    		end)
    	end
    end

    local function hitTest(x, y)
    	local best, bestArea, bestIsBtn = nil, nil, nil
    	for _, root in ipairs(getRoots()) do
    		local ok, all = pcall(function()
    			return root:GetDescendants()
    		end)
    		if ok and all then
    			for _, inst in ipairs(all) do
    				if isa(inst, "GuiObject") and isVisible(inst) and inst.Name ~= "BTPicker" then
    					local okP, pos = pcall(function()
    						return inst.AbsolutePosition
    					end)
    					local okS, size = pcall(function()
    						return inst.AbsoluteSize
    					end)
    					if okP and okS and pos and size then
    						local pad = 20
    						if x >= pos.X - pad and x <= pos.X + size.X + pad
    							and y >= pos.Y - pad and y <= pos.Y + size.Y + pad then
    							local area = size.X * size.Y
    							local isBtn = isButtonClass(inst)
    							local better = false
    							if not best then
    								better = true
    							elseif isBtn and not bestIsBtn then
    								better = true
    							elseif isBtn == bestIsBtn and area < bestArea then
    								better = true
    							end
    							if better then
    								best, bestArea, bestIsBtn = inst, area, isBtn
    							end
    						end
    					end
    				end
    			end
    		end
    	end
    	return best
    end

    local function pickAt(x, y)
    	local best = hitTest(x, y)
    	if best then
    		State.ManualBind = best
            State.ManualPath = ODHX.Path(best)
            ODHX.Commit()
    		pcall(function()
    			if State.Active then
    				local t = clamp(State.Value, 0, 100) / 100
    				if t <= 0 then
    					restoreTree(best)
    				else
    					fadeTree(best, t)
    				end
    			end
    		end)
    		local inCache = false
    		for _, inst in ipairs(Cache.list) do
    			if inst == best then
    				inCache = true
    				break
    			end
    		end
    		if not inCache then
    			table.insert(Cache.list, best)
    		end
    		local nm, cls, w, h = "?", "?", 0, 0
    		pcall(function()
    			nm = sanitize(best.Name)
    		end)
    		pcall(function()
    			cls = tostring(best.ClassName)
    		end)
    		pcall(function()
    			w = math.floor(best.AbsoluteSize.X + 0.5)
    			h = math.floor(best.AbsoluteSize.Y + 0.5)
    		end)
    		shared.Notify("Picked: " .. nm .. " [" .. cls .. "] " .. w .. "x" .. h
    			.. " — controlled by the slider", 4)
    		return nm .. "[" .. cls .. "]"
    	end
    	shared.Notify("No button found under that tap. Try again.", 3)
    	return nil
    end

    local pickActive = false

    local function startPick()
    	if pickActive then
    		shared.Notify("Pick mode is already on — tap a button!", 2)
    		return
    	end
    	pickActive = true
    	local ok, err = pcall(function()
    		local gui = Instance.new("ScreenGui")
    		gui.Name = "BTPicker"
    		gui.ResetOnSpawn = false
    		gui.DisplayOrder = 2000000000
    		gui.IgnoreGuiInset = true
    		local btn = Instance.new("TextButton")
    		btn.Name = "BTPicker"
    		btn.Size = UDim2.fromScale(1, 1)
    		btn.BackgroundTransparency = 1
    		btn.Text = ""
    		btn.AutoButtonColor = false
    		btn.Active = true
    		btn.ZIndex = 2147483647
    		btn.Parent = gui
    		local parent = SR_UI.service("CoreGui")
    		if not parent then
    			parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    		end
    		gui.Parent = parent

    		local conn
    		local finish = function(px, py)
    			if conn then
    				pcall(function()
    					conn:Disconnect()
    				end)
    				conn = nil
    			end
    			pcall(function()
    				gui:Destroy()
    			end)
    			pickActive = false
    			if px then
    				pickAt(px, py)
    			end
    		end

    		conn = btn.Activated:Connect(function(inputObject)
    			local px, py = nil, nil
    			pcall(function()
    				px = inputObject.Position.X
    				py = inputObject.Position.Y
    			end)
    			finish(px, py)
    		end)

    		pcall(function()
    			task.delay(PICK_SECONDS, function()
    				if pickActive then
    					shared.Notify("Selection cancelled: time is up.", 2)
    					finish(nil, nil)
    				end
    			end)
    		end)
    	end)
    	if not ok then
    		pickActive = false
    		shared.Notify("Could not start pick mode: " .. sanitize(tostring(err)), 3)
    		return
    	end
    	shared.Notify("Tap a button within " .. PICK_SECONDS .. " seconds!", 4)
    end

    local function clearManual()
        State.ManualPath = nil
    	local mb = State.ManualBind
    	State.ManualBind = nil
    	if mb then
    		restoreTree(mb)
    	end
    	local kept = {}
    	for _, inst in ipairs(Cache.list) do
    		if inst ~= mb then
    			table.insert(kept, inst)
    		end
    	end
    	Cache.list = kept
    	shared.Notify("Manual pick removed" .. (mb and ", button appearance restored." or "."), 2)
    end

    local function hardReset()
        State.ManualPath = nil
    	State.Active     = false
    	State.ManualBind = nil
    	Cache.list       = {}
    	Cache.dirty      = true
    	restoreAll()
    	shared.Notify("Reset. Opacity stays off until you move the slider.", 3)
    	local passes = { 0.3, 0.8, 1.5, 3 }
    	for i, sec in ipairs(passes) do
    		later(sec, function()
    			if not State.Active and not State.Dead then
    				restoreAll()
    				if i == #passes then
    					for obj in pairs(originals) do
    						local alive = false
    						pcall(function()
    							alive = obj and obj.Parent ~= nil
    						end)
    						if not alive then
    							originals[obj] = nil
    						end
    					end
    				end
    			end
    		end)
    	end
    end

    local function shutdown()
    	State.Dead = true
    	disconnectEvents()
    	restoreAll()
    end

    pcall(function()
    	if type(getgenv) == "function" then
    		getgenv().ButtonTransparency = {
    			State       = State,
    			Cache       = Cache,
    			FullScan    = fullScan,
    			LightScan   = lightScan,
    			Apply       = applyCached,
    			Restore     = restoreAll,
    			Reset       = hardReset,
    			PickAt      = pickAt,
    			StartPick   = startPick,
    			ClearManual = clearManual,
    			Shutdown    = shutdown,
    		}
    	end
    end)

    local section = shared.AddSection("Button Transparency")

    SR_Paragraph(section, "Button opacity", "One slider for all Shoot Murderer buttons. 0 = as before, " ..
    	"100 = invisible, colour unchanged. If the button you need is not " ..
    	"coloured — pick it by tap.")

    section:AddSlider("Button opacity", 0, 100, State.Value, function(v)
    	State.Value = v
    	State.Active = true

    	if Cache.dirty and #Cache.list == 0 then
    		Cache.dirty = false
    		pcall(fullScan)
    	end
    	applyCached()
    end)

    section:AddButton("Pick a button by tap", function()
    	startPick()
    end)

    section:AddButton("Remove manual button pick", function()
    	clearManual()
    end)

    section:AddButton("Reset (restore as before)", function()
    	hardReset()
    end)

    section:AddLabel("0 = as before • 100 = invisible")

    SR_Log("Button Transparency v6 loaded")

    later(1, function()
    	if not State.Dead then
    		pcall(fullScan)
    		pcall(applyCached)
    	end
    end)

    ODHX.Bind("Button Transparency", "Button opacity", "Slider", function() return State.Value end)
    ODHX.cleanup=shutdown
    ODHX.Finish()

end
end)

SR_UI.tryModule("PM_VALEX", function()
do
    local ODHX = CreateODHX("PM_VALEX", "PM VALEX", "ODH_PM_VALEX_settings.json", true, true)

    local AUTHOR            = "Noir_Creator"
    local BRAND             = "PM VALEX"
    local PLUGIN_ID         = "pm_valex"
    local PLUGIN_NAME       = BRAND .. " • VOID RESET"
    local VERSION           = "V1.1"
    local VERSION_TAG       = "pmvalex"
    local MARKER_PREFIX     = "@pmvalex_"
    local CONFIG_PATH       = PLUGIN_ID .. ".json"
    local STORAGE_NAME      = "@" .. PLUGIN_ID
    local UNLOAD_GLOBAL     = "__PM_VALEX_UNLOAD"

    local LEGACY_STORAGES   = { "@bindstorage_v6", "@bindstorage_v5" }

    local CLEAN_LEGACY_MENU = true

    local StarterGui = nil

    local function hostNotify(text, dur)
        if not SR_Gate(text) then return end
        if odh_shared_plugins and type(odh_shared_plugins.Notify) == "function" then
            if pcall(odh_shared_plugins.Notify, text, dur or 3) then return end
        end
        pcall(function()
            local sg = StarterGui or SR_UI.service("StarterGui")
            sg:SetCore("SendNotification", {
                Title = BRAND, Text = tostring(text), Duration = dur or 3,
            })
        end)
    end

    local shared = ODHX.shared
    if not shared then
        SR_Log(BRAND .. " " .. VERSION .. ": the host menu is unavailable, the module is skipped")
        return
    end
    -- Murder Mystery 2 and its modded versions (MMV and others) share the same
    -- gameplay remotes, and every lookup this module makes is optional, so it is
    -- built everywhere instead of refusing to load. In a place that does not look
    -- like a Murder Mystery game the menu still appears and simply finds no target.
    local function isMurderMysteryPlace()
        local name = type(shared.game_name) == "string" and shared.game_name or ""
        if name:find("Murder Mystery", 1, true) then return true end
        if game.PlaceId == 142823291 or game.GameId == 66654135 then return true end
        return false
    end
    if not isMurderMysteryPlace() then
        SR_Log(BRAND .. " " .. VERSION .. ": game is not a Murder Mystery place, the reset features may do nothing here")
    end

    pcall(function()
        if type(getgenv) ~= "function" then return end
        local g = getgenv()
        if type(g) ~= "table" then return end
        local prev = rawget(g, UNLOAD_GLOBAL)
        rawset(g, UNLOAD_GLOBAL, nil)
        if type(prev) == "function" then pcall(prev) end
    end)

    local Maid = {}
    Maid.__index = Maid

    function Maid._cleanup(item)
        local t = typeof(item)
        if t == "RBXScriptConnection" then
            pcall(function() item:Disconnect() end)
        elseif t == "Instance" then
            pcall(function() item:Destroy() end)
        elseif t == "function" then
            local ok, err = pcall(item)
            if not ok then warn("[" .. BRAND .. "][maid] " .. tostring(err)) end
        elseif t == "thread" then
            pcall(task.cancel, item)
        elseif t == "table" and type(item.Destroy) == "function" then
            pcall(item.Destroy, item)
        end
    end

    function Maid.new()
        return setmetatable({ _tasks = {}, _destroyed = false }, Maid)
    end

    function Maid:GiveTask(item)
        if item == nil then return nil end
        if self._destroyed then
            Maid._cleanup(item)
            return nil
        end
        local tasks = self._tasks
        tasks[#tasks + 1] = item
        return item
    end

    function Maid:DoCleaning()
        if self._destroyed then return end
        self._destroyed = true
        local tasks = self._tasks
        self._tasks = {}
        for i = #tasks, 1, -1 do
            Maid._cleanup(tasks[i])
            tasks[i] = nil
        end
    end

    function Maid:Destroy()
        self:DoCleaning()
    end

    local RootMaid = Maid.new()

    local ReplicatedStorage = SR_UI.service("ReplicatedStorage")
    local Players           = SR_UI.service("Players")
    local LocalPlayer       = Players.LocalPlayer
    local UserInputService  = SR_UI.service("UserInputService")
    local RunService        = SR_UI.service("RunService")
    local Workspace         = SR_UI.service("Workspace")
    local TweenService      = SR_UI.service("TweenService")
    local HttpService       = SR_UI.service("HttpService")
    local CoreGui           = SR_UI.service("CoreGui")
    StarterGui              = SR_UI.service("StarterGui")

    local new      = Instance.new
    local clamp    = math.clamp
    local sin, cos, floor = math.sin, math.cos, math.floor
    local now      = os.clock
    local insert   = table.insert
    local ud2      = UDim2.new
    local ud       = UDim.new
    local v2       = Vector2.new
    local v3       = Vector3.new
    local cfr      = CFrame.new
    local rgb      = Color3.fromRGB
    local pclr     = Color3.new
    local cs       = ColorSequence.new
    local csk      = ColorSequenceKeypoint.new
    local tinfo    = TweenInfo.new
    local V3_ZERO  = Vector3.zero
    local UIT      = Enum.UserInputType
    local MOUSE1   = UIT.MouseButton1
    local TOUCH    = UIT.Touch
    local MOUSEMOV = UIT.MouseMovement
    local EASING   = Enum.EasingStyle
    local EDIR     = Enum.EasingDirection
    local FALLBACK_VIEWPORT = v2(1920, 1080)

    local function clearTable(t)
        if table.clear then table.clear(t) else for k in pairs(t) do t[k] = nil end end
    end

    local state_whitelist_ref = nil
    local loadedWhitelist = {}
    local persistDisabled = false

    local DEFAULTS = {
        maxRetries        = 3,
        retryDelay        = 0.18,
        auraStuds         = 15,
        resetDuration     = 0.55,
        autoSheriffDelay  = 0.25,
        autoMurdererDelay = 0.35,
        loopInterval      = 0.4,
        auraInterval      = 0.4,
        bindButtonSize    = 0.11,
        targetCooldown    = 0.8,
        roleCacheTTL      = 0.8,
        muteSounds        = false,
        notifications     = true,
        keybinds          = {},
        bindPositions     = {},
        binds             = {},
        hudPos            = { x = 0.5, y = 6 },
        pluginUI          = {},
        whitelist         = {},
    }

    local config = {}
    for key, value in pairs(DEFAULTS) do
        if type(value) == "table" then
            local copy = {}
            for kk, vv in pairs(value) do copy[kk] = vv end
            config[key] = copy
        else
            config[key] = value
        end
    end

    local canPersist = (SR_Store.CanWrite() or SR_Store.CanRead() or SR_Store.mem ~= nil)
    local jsonBroken = false

    local function jsonEncode(tbl)
        if jsonBroken then return nil end
        local ok, res = pcall(function() return HttpService:JSONEncode(tbl) end)
        if ok and type(res) == "string" then return res end
        jsonBroken = true
        return nil
    end

    local function jsonDecode(str)
        if jsonBroken then return nil end
        local ok, res = pcall(function() return HttpService:JSONDecode(str) end)
        if ok and type(res) == "table" then return res end
        return nil
    end

    local function packWhitelist(map)
        local out = {}
        for id, name in pairs(map) do
            insert(out, { id = id, name = tostring(name) })
        end
        return out
    end

    local function unpackWhitelist(list)
        local map = {}
        if type(list) == "table" then
            for _, row in ipairs(list) do
                if type(row) == "table" and type(row.id) == "number" then
                    map[row.id] = tostring(row.name or row.id)
                end
            end
        end
        return map
    end

    local function serializeConfig()
        return {
            maxRetries = config.maxRetries, retryDelay = config.retryDelay,
            auraStuds = config.auraStuds, resetDuration = config.resetDuration,
            autoSheriffDelay = config.autoSheriffDelay, autoMurdererDelay = config.autoMurdererDelay,
            loopInterval = config.loopInterval, auraInterval = config.auraInterval,
            bindButtonSize = config.bindButtonSize, targetCooldown = config.targetCooldown,
            roleCacheTTL = config.roleCacheTTL, muteSounds = config.muteSounds,
            notifications = config.notifications, pluginUI = config.pluginUI,
            keybinds = config.keybinds, bindPositions = config.bindPositions, binds = config.binds,
            hudPos = config.hudPos, whitelist = packWhitelist(state_whitelist_ref or {}),
        }
    end

    local function applyLoaded(data)
        if type(data) ~= "table" then return false end
        local scalars = {
            "maxRetries", "retryDelay", "auraStuds", "resetDuration", "autoSheriffDelay",
            "autoMurdererDelay", "loopInterval", "auraInterval", "bindButtonSize",
            "targetCooldown", "roleCacheTTL", "muteSounds", "notifications",
        }
        for _, key in ipairs(scalars) do
            local v = data[key]
            if v ~= nil and type(v) == type(DEFAULTS[key]) then config[key] = v end
        end
        if type(data.keybinds) == "table" then config.keybinds = data.keybinds end
        if type(data.bindPositions) == "table" then config.bindPositions = data.bindPositions end
        if type(data.binds) == "table" then config.binds = data.binds end
        if type(data.hudPos) == "table" and type(data.hudPos.x) == "number" and type(data.hudPos.y) == "number" then
            config.hudPos = { x = data.hudPos.x, y = data.hudPos.y }
        end
        if type(data.pluginUI)=="table" then config.pluginUI=data.pluginUI end
        loadedWhitelist = unpackWhitelist(data.whitelist)
        return true
    end

    local function loadConfig()
        if not canPersist then return false end
        local applied = false
        pcall(function()
            local text = SR_Store.read(CONFIG_PATH)
            if text then
                local okMain = pcall(function() applied = applyLoaded(jsonDecode(text)) and true or false end)
                if not okMain then applied = false end
            end
            if not applied then
                local bakText = SR_Store.read(CONFIG_PATH .. ".bak")
                if bakText then
                    local okBak = pcall(function() applied = applyLoaded(jsonDecode(bakText)) and true or false end)
                    if okBak and applied then
                        ODHX.Report("Config was corrupted; loaded from " .. CONFIG_PATH .. ".bak")
                    end
                end
            end
        end)
        return applied
    end

    local saveQueued, saveThread = false, nil
    local saveRetries = 0

    local function scheduleSaveRetry()
        if saveRetries >= 3 then return end
        saveRetries = saveRetries + 1
        if type(task) == "table" and type(task.delay) == "function" then
            task.delay(saveRetries * 2, function()
                if not persistDisabled then saveConfig() end
            end)
        end
    end

    local function saveConfig(force)
        if not canPersist or persistDisabled then return false end
        if force then
            if saveThread then pcall(task.cancel,saveThread) end
            saveThread,saveQueued=nil,false
            local ok,err=pcall(function()
                local payload=jsonEncode(serializeConfig())
                assert(payload,"JSON encode failed")
                local saved,why=SR_Store.write(CONFIG_PATH,payload)
                if not saved then error(why or "write failed") end
            end)
            if not ok then
                ODHX.Report("Could not save " .. CONFIG_PATH .. ": " .. tostring(err))
                scheduleSaveRetry()
            else
                saveRetries = 0
            end
            return ok
        end
        if saveQueued and not force then return true end
        saveQueued = true
        if saveThread then pcall(task.cancel, saveThread) end
        saveThread = task.delay(0.35, function()
            saveQueued = false
            saveThread = nil
            local ok, err = pcall(function()
                local payload = jsonEncode(serializeConfig())
                assert(payload, "JSON encode failed")
                local saved, why = SR_Store.write(CONFIG_PATH, payload)
                if not saved then error(why or "write failed") end
            end)
            if not ok then
                ODHX.Report("Could not save " .. CONFIG_PATH .. ": " .. tostring(err))
                scheduleSaveRetry()
            else
                saveRetries = 0
            end
        end)
        return true
    end

    local POS_PATH = PLUGIN_ID .. "_positions.json"
    local posRetries, posRetryThread = 0, nil

    local function savePositions()
        if not canPersist or persistDisabled then return false end
        local payload = jsonEncode({ version = 1, bindPositions = config.bindPositions, hudPos = config.hudPos })
        if type(payload) ~= "string" then return false end
        if SR_Store.write(POS_PATH, payload) then
            posRetries = 0
            return true
        end
        if posRetries < 4 and type(task) == "table" and type(task.delay) == "function" then
            posRetries = posRetries + 1
            if posRetryThread then pcall(task.cancel, posRetryThread) end
            posRetryThread = task.delay(posRetries * 1.5, function()
                posRetryThread = nil
                savePositions()
            end)
        end
        return false
    end

    local function loadPositions()
        local text = SR_Store.read(POS_PATH)
        if not text then return false end
        local applied = false
        pcall(function()
            local data = jsonDecode(text)
            if type(data) ~= "table" or data.version ~= 1 then return end
            if type(data.bindPositions) == "table" then config.bindPositions = data.bindPositions end
            if type(data.hudPos) == "table" and type(data.hudPos.x) == "number" and type(data.hudPos.y) == "number" then
                config.hudPos = { x = data.hudPos.x, y = data.hudPos.y }
            end
            applied = true
        end)
        return applied
    end

    local configLoaded = loadConfig()
    local positionsLoaded = loadPositions()
    ODHX.data.controls=config.pluginUI or {}
    ODHX.backend=function(data)
        config.pluginUI=data.controls
        return saveConfig()
    end

    local state = {
        whitelist       = loadedWhitelist,
        selectedPlayers = {},
        selectedSet     = {},
        resetSelPlr     = nil,
        lastResetAt     = {},
    }
    state_whitelist_ref = state.whitelist

    local maids = {
        loopPlr = nil, clickReset = nil, resetAura = nil,
        autoSheriff = nil, autoMurderer = nil,
    }

    local lastNotify = { text = nil, at = 0 }
    local function Notify(title, msg, dur)
        if not config.notifications then return end
        local text = msg and (title .. ": " .. msg) or title
        local t = now()
        if lastNotify.text == text and (t - lastNotify.at) < 0.35 then return end
        lastNotify.text, lastNotify.at = text, t
        hostNotify(text, dur or 3)
    end

    local Ticker = { _fns = {}, _conn = nil }

    function Ticker._start()
        if Ticker._conn then return end
        Ticker._conn = RunService.RenderStepped:Connect(function(dt)
            local fns = Ticker._fns
            local i = 1
            while i <= #fns do
                local fn = fns[i]
                if fn then
                    local ok, err = xpcall(fn, debug.traceback, dt)
                    if not ok then
                        warn("[" .. BRAND .. "][ticker] " .. tostring(err))
                        table.remove(fns, i)
                        i = i - 1
                    end
                end
                i = i + 1
            end
            if #fns == 0 and Ticker._conn then
                Ticker._conn:Disconnect()
                Ticker._conn = nil
            end
        end)
    end

    function Ticker.add(fn)
        if type(fn) ~= "function" then return function() end end
        local fns = Ticker._fns
        fns[#fns + 1] = fn
        Ticker._start()
        local removed = false
        return function()
            if removed then return end
            removed = true
            for i = 1, #fns do
                if fns[i] == fn then
                    table.remove(fns, i)
                    break
                end
            end
        end
    end

    RootMaid:GiveTask(function()
        if Ticker._conn then Ticker._conn:Disconnect(); Ticker._conn = nil end
        clearTable(Ticker._fns)
    end)

    local LEGACY_TITLES = {
        ["⚡ Quick Actions"] = true,
        ["🤖 Automation"] = true,
        ["📋 Lists Management"] = true,
        ["⚙️ Reset Settings"] = true,
        ["⚙ Reset Settings"] = true,
        ["🔄 Bind Buttons (circles)"] = true,
        ["📊 Status"] = true,
        ["ℹ️ Info"] = true,
        ["⚡ Reset"] = true,
        ["🤖 Auto"] = true,
        ["📋 Lists"] = true,
        ["⚙️ Tuning"] = true,
        ["⚙ Tuning"] = true,
        ["🔘 Binds"] = true,
        ["ℹ️"] = true,
    }

    local EXTRA_LEGACY_TITLES = {}
    for _title in pairs(EXTRA_LEGACY_TITLES) do LEGACY_TITLES[_title] = true end
    local CUR_TITLES = {
        ["💀 " .. BRAND] = true,
        ["⚡ Reset"] = true,
        ["🤖 Auto"] = true,
        ["📋 Lists"] = true,
        ["⚙️ Tuning"] = true,
        ["⚙ Tuning"] = true,
        ["🔘 Binds"] = true,
        ["🔑 Keys"] = true,
        ["💾 Config"] = true,
        ["ℹ️"] = true,
    }

    local HOST_WORDS = {
        "Looking for a feature", "Plugins", "Overdrive", "Logged in as", "gg/overdrivehub",
    }
    local MAX_CARD_HEIGHT = 520

    local RUN_ID = MARKER_PREFIX .. tostring(floor(now() * 1000) % 100000000)
        .. "_" .. tostring(math.random(1000, 9999))

    local storageGui = nil
    local function getStorage()
        if storageGui and storageGui.Parent then return storageGui end

        local parent
        local ok, res = pcall(function()
            if gethui then return gethui() end
            if getcore then return getcore() end
            return nil
        end)
        if ok and typeof(res) == "Instance" then parent = res else parent = CoreGui end
        if typeof(parent) ~= "Instance" then parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") end
        if typeof(parent) ~= "Instance" then parent = LocalPlayer:WaitForChild("PlayerGui", 5) end
        if typeof(parent) ~= "Instance" then parent = CoreGui end

        pcall(function()
            for _, legacyName in ipairs(LEGACY_STORAGES) do
                local legacy = parent:FindFirstChild(legacyName)
                if legacy then legacy:Destroy() end
            end
        end)

        local sg = parent:FindFirstChild(STORAGE_NAME)
        if not sg then
            sg = new("ScreenGui")
            sg.Name = STORAGE_NAME
            sg.ResetOnSpawn = false
            sg.IgnoreGuiInset = true
            pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
            if syn and syn.protect_gui then pcall(syn.protect_gui, sg) end
            sg.Parent = parent
        end
        storageGui = sg
        return sg
    end

    local mySections = {}
    local headlessMode = false

    local function stubSection()
        return setmetatable({}, { __index = function() return function() end end })
    end

    local pmReady = false
    local PM_CONTROL_METHODS = {
        AddToggle = true, AddSlider = true, AddDropdown = true,
        AddColorpicker = true, AddKeybind = true,
    }
    local function protectSection(sec)
        if typeof(sec) ~= "table" then return stubSection() end
        local proxy = { _raw = sec }
        return setmetatable(proxy, {
            __index = function(p, key)
                local raw = p._raw
                local value = raw[key]
                if type(value) == "function" then
                    return function(first, ...)

                        local args = table.pack(...)
                        if first == p then

                            if PM_CONTROL_METHODS[key] and type(args[args.n]) == "function" then
                                local cb = args[args.n]
                                args[args.n] = function(...) if pmReady then return cb(...) end end
                            end
                        else

                            args = table.pack(first, table.unpack(args, 1, args.n))
                        end
                        local ok, err = pcall(value, raw, table.unpack(args, 1, args.n))
                        if not ok then warn("[" .. BRAND .. "][menu] " .. tostring(key) .. ": " .. tostring(err)) end
                        return ok and err or nil
                    end
                end
                return value
            end,
        })
    end

    local function AddSection(name)
        local ok, sec = pcall(function() return shared.AddSection(name) end)
        local obj
        if ok and sec then
            obj = protectSection(sec)
        else
            headlessMode = true
            obj = stubSection()
        end
        insert(mySections, { name = name, obj = obj })
        return obj
    end

    local function guiRoots()
        local roots, seen = {}, {}
        local function add(r)
            if typeof(r) == "Instance" and not seen[r] then
                seen[r] = true
                roots[#roots + 1] = r
            end
        end
        pcall(function() add(gethui and gethui()) end)
        pcall(function() add(getcore and getcore()) end)
        add(CoreGui)
        pcall(function() add(LocalPlayer:FindFirstChildOfClass("PlayerGui")) end)
        return roots
    end

    local function hasHostWords(node, memo)
        local cached = memo[node]
        if cached ~= nil then return cached end
        local res = false
        local descendants = node:GetDescendants()
        for i = 1, #descendants do
            local d = descendants[i]
            if d:IsA("TextLabel") then
                local txt = d.Text
                for w = 1, #HOST_WORDS do
                    if txt:find(HOST_WORDS[w], 1, true) then
                        res = true
                        break
                    end
                end
                if res then break end
            end
        end
        memo[node] = res
        return res
    end

    local function findCard(node, memo)
        for _ = 1, 7 do
            if not node or typeof(node) ~= "Instance" or node == game then return nil end
            if node:IsA("Frame") or node:IsA("ScrollingFrame") then
                local framed = node:FindFirstChildOfClass("UIStroke") or node:FindFirstChildOfClass("UICorner")
                if framed then
                    local sz = node.AbsoluteSize
                    if sz.Y > 0 and sz.Y < MAX_CARD_HEIGHT and not hasHostWords(node, memo) then
                        return node
                    end
                end
            end
            node = node.Parent
        end
        return nil
    end

    local function markerOf(card)
        if not card then return nil end
        local descendants = card:GetDescendants()
        for i = 1, #descendants do
            local d = descendants[i]
            if d.Name:sub(1, #MARKER_PREFIX) == MARKER_PREFIX then return d.Name end
        end
        return nil
    end

    local function attachMarker(card)
        if not card or markerOf(card) then return false end
        local ok = pcall(function()
            local sv = new("StringValue")
            sv.Name = RUN_ID
            sv.Value = VERSION
            sv.Parent = card
        end)
        return ok
    end

    local lastPurge = 0
    local PURGE_COOLDOWN = 0.5

    local SCAN_CHUNK = 400
    local function scanChunk(counter)
        counter.n = counter.n + 1
        if counter.n >= SCAN_CHUNK then
            counter.n = 0
            task.wait()
        end
    end

    local markOwnCards

    local function cardIsOurs(card)
        if markerOf(card) == RUN_ID then return true end
        local descendants = card:GetDescendants()
        for i = 1, #descendants do
            local d = descendants[i]
            if d:IsA("TextLabel") and d.Text:find(VERSION_TAG, 1, true) then return true end
        end
        return false
    end

    local function purgeForeign(force)
        local t = now()
        if not force and (t - lastPurge) < PURGE_COOLDOWN then return 0 end
        lastPurge = t
        local killed = 0
        local counter = { n = 0 }
        for _, root in ipairs(guiRoots()) do
            local memo = {}
            local descendants = root:GetDescendants()
            for i = 1, #descendants do
                scanChunk(counter)
                local d = descendants[i]
                if d.Parent and d:IsA("TextLabel") then
                    local txt = d.Text
                    if CUR_TITLES[txt] or (CLEAN_LEGACY_MENU and LEGACY_TITLES[txt]) then
                        local card = findCard(d, memo)
                        if card and not cardIsOurs(card) then
                            if pcall(function() card:Destroy() end) then killed = killed + 1 end
                        end
                    end
                end
            end
        end
        return killed
    end

    local guiDirty = true
    local dirtyWatches = {}
    local function watchGuiRoots()
        for _, root in ipairs(guiRoots()) do
            if not dirtyWatches[root] then
                local ok, conn = pcall(function()
                    return root.DescendantAdded:Connect(function() guiDirty = true end)
                end)
                dirtyWatches[root] = ok and conn or true
            end
        end
    end
    local function scanIfDirty()
        watchGuiRoots()
        if not guiDirty then return false end
        guiDirty = false
        pcall(markOwnCards)
        pcall(purgeForeign, true)
        return true
    end

    local markedCount = 0

    markOwnCards = function()
        local marked = 0
        local counter = { n = 0 }
        for _, root in ipairs(guiRoots()) do
            local memo = {}
            local descendants = root:GetDescendants()
            for i = 1, #descendants do
                scanChunk(counter)
                local d = descendants[i]
                if d.Parent and d:IsA("TextLabel") and CUR_TITLES[d.Text] then
                    local card = findCard(d, memo)
                    if card and markerOf(card) == nil and attachMarker(card) then
                        marked = marked + 1
                    end
                end
            end
        end
        markedCount = markedCount + marked
        return marked
    end

    local function removeByTitles()
        local removed = 0
        for _, root in ipairs(guiRoots()) do
            local memo = {}
            local descendants = root:GetDescendants()
            for i = 1, #descendants do
                local d = descendants[i]
                if d.Parent and d:IsA("TextLabel") and CUR_TITLES[d.Text] then
                    local card = findCard(d, memo)
                    if card and not markerOf(card) then
                        if pcall(function() card:Destroy() end) then removed = removed + 1 end
                    end
                end
            end
        end
        return removed
    end

    local function removeMySections()
        local removed = 0
        for _, root in ipairs(guiRoots()) do
            local descendants = root:GetDescendants()
            for i = 1, #descendants do
                local d = descendants[i]
                if d.Name == RUN_ID and d.Parent then
                    local card = d.Parent
                    pcall(function() d:Destroy() end)
                    if pcall(function() card:Destroy() end) then removed = removed + 1 end
                end
            end
        end
        if removed == 0 and markedCount == 0 then removed = removeByTitles() end
        return removed
    end

    pcall(purgeForeign, true)

    local Audio = { click = nil }
    function Audio.init()
        local s = new("Sound")
        s.Name = "@click"
        s.SoundId = "rbxassetid://3868133279"
        s.Volume = config.muteSounds and 0 or 0.5
        s.Parent = getStorage()
        Audio.click = s
        RootMaid:GiveTask(s)
    end
    function Audio.play()
        local s = Audio.click
        if not s or s.Volume <= 0 then return end
        pcall(function() s:Play() end)
    end
    function Audio.setMuted(muted)
        config.muteSounds = muted and true or false
        if Audio.click then Audio.click.Volume = config.muteSounds and 0 or 0.5 end
        saveConfig()
    end

    local BindableButtons = {
        Buttons = {},
        Maids   = {},
        recs    = {},
        order   = {},
        Count   = 0,
        ResetActive = false,
        CurrentSize = config.bindButtonSize or 0.11,
    }

    local __SHAPES = {
        [0] = "rbxassetid://86221076925479",
        [1] = "rbxassetid://96242665417546",
        [2] = "rbxassetid://97129189935336",
        [3] = "rbxassetid://76165862027868",
        [4] = "rbxassetid://125868092127496",
    }
    local GLOW_IMG = "rbxassetid://131961136"

    local __NORMAL_COLOR = cs({
        csk(0,   pclr(0.133333, 0.827451, 0.494118)),
        csk(0.6, pclr(0.231373, 0.509804, 0.498039)),
        csk(1,   pclr(0.501961, 0.501961, 0.501961)),
    })
    local __WAIT_COLOR = cs({
        csk(0,   pclr(0.827451, 0.133333, 0.133333)),
        csk(0.6, pclr(0.509804, 0.231373, 0.231373)),
        csk(1,   pclr(0.501961, 0.501961, 0.501961)),
    })
    local __GOLD_NORMAL_COLOR = cs({
        csk(0,   rgb(255, 215, 0)),
        csk(0.6, rgb(218, 165, 32)),
        csk(1,   rgb(128, 128, 128)),
    })
    local __GOLD_WAIT_COLOR = cs({
        csk(0,   rgb(255, 69, 0)),
        csk(0.6, rgb(139, 0, 0)),
        csk(1,   rgb(128, 128, 128)),
    })

    local function bind_safecallback(callback)
        if not callback then return end
        local ok, err = xpcall(callback, debug.traceback)
        if not ok then warn("[" .. BRAND .. "][bind] " .. tostring(err)) end
    end

    function BindableButtons.relayout()
        local camera = Workspace.CurrentCamera
        local screen = (camera and camera.ViewportSize) or FALLBACK_VIEWPORT
        local h = BindableButtons.CurrentSize or 0.11
        local w = h * (screen.Y / screen.X)
        local perRow = math.max(1, floor(0.84 / (w + 0.008)))
        for i = 1, #BindableButtons.order do
            local id = BindableButtons.order[i]
            local rec = BindableButtons.recs[id]
            if rec then
                local saved = config.bindPositions[id]
                if saved and type(saved.x) == "number" and type(saved.y) == "number" then
                    rec.x, rec.y = saved.x, saved.y
                else
                    local row = floor((i - 1) / perRow)
                    local col = (i - 1) % perRow
                    rec.x = 0.08 + col * (w + 0.008)
                    rec.y = 0.88 - row * (h + 0.02)
                end
                rec.btn.Position = ud2(rec.x, 0, rec.y, 0)
                rec.glow.Position = ud2(rec.x, 0, rec.y, 0)
            end
        end
    end

    function BindableButtons.setSize(sizeScale)
        BindableButtons.CurrentSize = clamp(sizeScale or 0.11, 0.02, 0.4)
        config.bindButtonSize = BindableButtons.CurrentSize
        BindableButtons.relayout()
        saveConfig(true)
    end

    local dragState = nil

    local binderGlobalMaid = Maid.new()
    RootMaid:GiveTask(binderGlobalMaid)

    local function isDragInput(input)
        if not dragState then return false end
        if input == dragState.dragInput then return true end
        if input == dragState.input then return true end
        return false
    end

    binderGlobalMaid:GiveTask(UserInputService.InputChanged:Connect(function(input)
        if not dragState then return end
        if input.UserInputType ~= MOUSEMOV and input.UserInputType ~= TOUCH then return end
        if not isDragInput(input) then return end
        local rec = dragState.rec
        if not rec or not rec.btn then return end
        local delta = input.Position - dragState.startInput
        if delta.Magnitude > 7 then dragState.moved = true end
        local parentGui = rec.btn.Parent
        if not parentGui then return end
        local screen = parentGui.AbsoluteSize
        if screen.X <= 0 or screen.Y <= 0 then return end
        rec.x = clamp(dragState.startX + (delta.X / screen.X), 0.03, 0.97)
        rec.y = clamp(dragState.startY + (delta.Y / screen.Y), 0.05, 0.95)
        rec.btn.Position = ud2(rec.x, 0, rec.y, 0)
        rec.glow.Position = ud2(rec.x, 0, rec.y, 0)
    end))

    binderGlobalMaid:GiveTask(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType ~= MOUSE1 and input.UserInputType ~= TOUCH then return end

        for _, rec in pairs(BindableButtons.recs) do rec.targetPress = 0 end
        if not dragState then return end

        local mine = (input == dragState.input)
            or (input == dragState.dragInput)
            or (dragState.isMouse and input.UserInputType == MOUSE1)
        if not mine then return end
        local rec, moved = dragState.rec, dragState.moved
        dragState = nil
        if not rec then return end
        if not moved then
            Audio.play()
            bind_safecallback(rec.onClick)
        else
            config.bindPositions[rec.id] = { x = rec.x, y = rec.y }
            saveConfig(true)
            savePositions()
        end
    end))

    local function binderStep(dt)
        local cam = Workspace.CurrentCamera
        local scr = (cam and cam.ViewportSize) or FALLBACK_VIEWPORT
        local bh = BindableButtons.CurrentSize or 0.11
        local bw = bh * (scr.Y / scr.X)
        local t = now()
        local pulseBase = BindableButtons.ResetActive and (sin(t * 7) * 0.5 + 0.5) * 0.3 or 0
        local rotStep = BindableButtons.ResetActive and 3.5 or 1.1
        local kHover = clamp(dt * 12, 0, 1)
        local kPress = clamp(dt * 16, 0, 1)

        local eps = 1e-4
        for _, rec in BindableButtons.recs do
            local btn, glow = rec.btn, rec.glow
            if btn and glow then
                rec.hover = rec.hover + (rec.targetHover - rec.hover) * kHover
                rec.press = rec.press + (rec.targetPress - rec.press) * kPress

                local scale = 1 + rec.hover * 0.14 - rec.press * 0.10
                local sizeX, sizeY = bw * scale, bh * scale
                if rec.lastSizeX == nil or math.abs(rec.lastSizeX - sizeX) > eps or math.abs(rec.lastSizeY - sizeY) > eps then
                    rec.lastSizeX, rec.lastSizeY = sizeX, sizeY
                    btn.Size = ud2(sizeX, 0, sizeY, 0)
                end

                local glowX, glowY = bw * 2.5, bh * 2.5
                if rec.lastGlowX == nil or math.abs(rec.lastGlowX - glowX) > eps or math.abs(rec.lastGlowY - glowY) > eps then
                    rec.lastGlowX, rec.lastGlowY = glowX, glowY
                    glow.Size = ud2(glowX, 0, glowY, 0)
                end

                if rec.lastPosX ~= rec.x or rec.lastPosY ~= rec.y then
                    rec.lastPosX, rec.lastPosY = rec.x, rec.y
                    glow.Position = ud2(rec.x, 0, rec.y, 0)
                end

                local glowT = clamp(0.78 - rec.hover * 0.28 - pulseBase, 0.25, 1)
                if rec.lastGlowT == nil or math.abs(rec.lastGlowT - glowT) > eps then
                    rec.lastGlowT = glowT
                    glow.ImageTransparency = glowT
                end

                rec.rot = (rec.rot + rotStep) % 360
                rec.stroke.Rotation = rec.rot
            end
        end
    end

    local binderTickerOff = nil
    local function binderEnsureTicker()
        if binderTickerOff then return end
        binderTickerOff = Ticker.add(binderStep)
        RootMaid:GiveTask(function()
            if binderTickerOff then binderTickerOff(); binderTickerOff = nil end
        end)
    end

    function BindableButtons.AddBButton(id, text, clickFunc, isGold)
        if BindableButtons.Buttons[id] then return BindableButtons.Buttons[id] end
        binderEnsureTicker()

        local buttonMaid = Maid.new()
        local storage = getStorage()

        local camera = Workspace.CurrentCamera
        local screen = (camera and camera.ViewportSize) or FALLBACK_VIEWPORT
        local h0 = BindableButtons.CurrentSize or 0.11
        local w0 = h0 * (screen.Y / screen.X)

        local glow = new("ImageLabel")
        glow.Name = "@glow"
        glow.Image = GLOW_IMG
        glow.BackgroundTransparency = 1
        glow.ImageColor3 = isGold and rgb(255, 200, 40) or rgb(40, 220, 140)
        glow.ImageTransparency = 0.78
        glow.Size = ud2(w0 * 2.5, 0, h0 * 2.5, 0)
        glow.AnchorPoint = v2(0.5, 0.5)
        glow.ZIndex = 1
        glow.Parent = storage
        buttonMaid:GiveTask(glow)

        local ImageButton = new("ImageButton")
        ImageButton.Name = id
        ImageButton.Size = ud2(w0, 0, h0, 0)
        ImageButton.AnchorPoint = v2(0.5, 0.5)
        ImageButton.Image = __SHAPES[0]
        ImageButton.BackgroundTransparency = 1
        ImageButton.BorderSizePixel = 0
        ImageButton.ClipsDescendants = false
        ImageButton.AutoButtonColor = false
        ImageButton.ZIndex = 2
        ImageButton.Parent = storage
        buttonMaid:GiveTask(ImageButton)

        local TextLabel = new("TextLabel", ImageButton)
        TextLabel.Name = "@Text"
        TextLabel.Size = ud2(0.85, 0, 0.85, 0)
        TextLabel.Position = ud2(0.5, 0, 0.5, 0)
        TextLabel.AnchorPoint = v2(0.5, 0.5)
        TextLabel.BackgroundTransparency = 1
        TextLabel.Font = Enum.Font.FredokaOne
        TextLabel.Text = text
        TextLabel.TextColor3 = pclr(1, 1, 1)
        TextLabel.TextStrokeTransparency = 0.5
        TextLabel.TextStrokeColor3 = rgb(0, 0, 0)
        TextLabel.TextSize = 11
        TextLabel.TextWrapped = true
        TextLabel.ZIndex = 3

        local Aspect = new("UIAspectRatioConstraint", ImageButton)
        Aspect.AspectRatio = 1
        pcall(function() Aspect.AspectType = Enum.AspectType.ScaleWithParentSize end)

        local Stroke = new("UIGradient", ImageButton)
        Stroke.Name = "@Stroke"
        Stroke.Color = isGold and __GOLD_NORMAL_COLOR or __NORMAL_COLOR

        local ripple = new("Frame")
        ripple.Name = "@ripple"
        ripple.BackgroundColor3 = isGold and rgb(255, 215, 0) or rgb(0, 155, 255)
        ripple.BackgroundTransparency = 0.45
        ripple.Size = ud2(0, 0, 0, 0)
        ripple.AnchorPoint = v2(0.5, 0.5)
        ripple.Visible = false
        ripple.ZIndex = 2
        ripple.Parent = ImageButton
        new("UICorner", ripple).CornerRadius = ud(1, 0)

        local rec = {
            id = id, btn = ImageButton, glow = glow, stroke = Stroke, ripple = ripple,
            onClick = clickFunc, isGold = isGold and true or false,
            hover = 0, press = 0, targetHover = 0, targetPress = 0,
            rot = 0, x = 0.08, y = 0.88,
        }

        buttonMaid:GiveTask(ImageButton.InputBegan:Connect(function(input)
            if input.UserInputType ~= MOUSE1 and input.UserInputType ~= TOUCH then return end
            rec.targetPress = 1
            dragState = {
                rec = rec,
                input = input,
                dragInput = nil,
                isMouse = input.UserInputType == MOUSE1,
                startInput = input.Position,
                startX = rec.x, startY = rec.y,
                moved = false,
            }
            local absPos = ImageButton.AbsolutePosition
            ripple.Position = ud2(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
            ripple.Size = ud2(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.45
            ripple.Visible = true
            TweenService:Create(ripple, tinfo(0.4, EASING.Sine, EDIR.Out), {
                Size = ud2(0, 45, 0, 45), BackgroundTransparency = 1,
            }):Play()
        end))

        buttonMaid:GiveTask(ImageButton.InputChanged:Connect(function(input)
            if input.UserInputType ~= MOUSEMOV and input.UserInputType ~= TOUCH then return end
            if dragState and dragState.rec == rec then dragState.dragInput = input end
        end))

        buttonMaid:GiveTask(ImageButton.MouseEnter:Connect(function() rec.targetHover = 1 end))
        buttonMaid:GiveTask(ImageButton.MouseLeave:Connect(function() rec.targetHover = 0 end))

        BindableButtons.Buttons[id] = ImageButton
        BindableButtons.Maids[id] = buttonMaid
        BindableButtons.recs[id] = rec
        insert(BindableButtons.order, id)
        BindableButtons.Count = #BindableButtons.order

        BindableButtons.relayout()
        return ImageButton
    end

    function BindableButtons.DeleteBButton(id)
        local maid = BindableButtons.Maids[id]
        if maid then maid:Destroy() end
        BindableButtons.Maids[id] = nil
        BindableButtons.Buttons[id] = nil
        BindableButtons.recs[id] = nil
        for i = 1, #BindableButtons.order do
            if BindableButtons.order[i] == id then
                table.remove(BindableButtons.order, i)
                break
            end
        end
        BindableButtons.Count = #BindableButtons.order
        if dragState and dragState.rec and dragState.rec.id == id then dragState = nil end
        BindableButtons.relayout()
    end

    function BindableButtons.UpdateBButtonText(id, text, isWaiting, isGold)
        local btn = BindableButtons.Buttons[id]
        if not btn then return end
        local textLabel = btn:FindFirstChild("@Text")
        if textLabel then textLabel.Text = text end
        local stroke = btn:FindFirstChild("@Stroke")
        if stroke then
            if isGold then
                stroke.Color = isWaiting and __GOLD_WAIT_COLOR or __GOLD_NORMAL_COLOR
            else
                stroke.Color = isWaiting and __WAIT_COLOR or __NORMAL_COLOR
            end
        end
    end

    function BindableButtons.resetLayout()
        clearTable(config.bindPositions)
        saveConfig(true)
        savePositions()
        BindableButtons.relayout()
    end

    function BindableButtons.clearAll()
        local ids = {}
        for id in pairs(BindableButtons.Buttons) do insert(ids, id) end
        for _, id in ipairs(ids) do BindableButtons.DeleteBButton(id) end
    end

    local StatusHUD = { frame = nil, dot = nil, label = nil, stroke = nil, state = "idle", accum = 0 }

    local function hudApplyPosition()
        if not StatusHUD.frame then return end
        local pos = config.hudPos or { x = 0.5, y = 6 }
        StatusHUD.frame.Position = ud2(pos.x, 0, 0, pos.y)
    end

    function StatusHUD.Init()
        local sg = getStorage()

        local frame = new("Frame")
        frame.Name = "@statushud"
        frame.Size = ud2(0, 0, 0, 26)
        frame.AutomaticSize = Enum.AutomaticSize.X
        frame.AnchorPoint = v2(0.5, 0)
        frame.BackgroundColor3 = rgb(12, 14, 18)
        frame.BackgroundTransparency = 0.12
        frame.BorderSizePixel = 0
        frame.Active = true
        frame.ZIndex = 10
        frame.Parent = sg
        new("UICorner", frame).CornerRadius = ud(1, 0)

        local stroke = new("UIStroke")
        stroke.Color = rgb(40, 220, 140)
        stroke.Thickness = 1
        stroke.Transparency = 0.25
        stroke.Parent = frame

        local grad = new("UIGradient")
        grad.Color = cs(rgb(20, 24, 30), rgb(10, 12, 16))
        grad.Rotation = 90
        grad.Parent = frame

        local list = new("UIListLayout")
        list.FillDirection = Enum.FillDirection.Horizontal
        list.VerticalAlignment = Enum.VerticalAlignment.Center
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = ud(0, 7)
        list.Parent = frame

        local pad = new("UIPadding")
        pad.PaddingLeft = ud(0, 10)
        pad.PaddingRight = ud(0, 12)
        pad.PaddingTop = ud(0, 6)
        pad.PaddingBottom = ud(0, 6)
        pad.Parent = frame

        local dot = new("Frame")
        dot.LayoutOrder = 1
        dot.Size = ud2(0, 8, 0, 8)
        dot.BackgroundColor3 = rgb(40, 220, 140)
        dot.BorderSizePixel = 0
        dot.ZIndex = 11
        dot.Parent = frame
        new("UICorner", dot).CornerRadius = ud(1, 0)

        local label = new("TextLabel")
        label.LayoutOrder = 2
        label.Size = ud2(0, 0, 0, 14)
        label.AutomaticSize = Enum.AutomaticSize.X
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.Text = "IDLE"
        label.TextColor3 = rgb(200, 215, 230)
        label.TextSize = 12
        label.ZIndex = 11
        label.Parent = frame

        StatusHUD.frame, StatusHUD.dot, StatusHUD.label, StatusHUD.stroke = frame, dot, label, stroke
        hudApplyPosition()

        local hudDrag = nil
        RootMaid:GiveTask(frame.InputBegan:Connect(function(input)
            if input.UserInputType ~= MOUSE1 and input.UserInputType ~= TOUCH then return end
            local pos = config.hudPos
            hudDrag = { startInput = input.Position, startX = pos.x, startY = pos.y, moved = false }
        end))
        RootMaid:GiveTask(UserInputService.InputChanged:Connect(function(input)
            if not hudDrag then return end
            if input.UserInputType ~= MOUSEMOV and input.UserInputType ~= TOUCH then return end
            local parentGui = frame.Parent
            if not parentGui then return end
            local screen = parentGui.AbsoluteSize
            if screen.X <= 0 or screen.Y <= 0 then return end
            local delta = input.Position - hudDrag.startInput
            if delta.Magnitude > 4 then hudDrag.moved = true end
            config.hudPos.x = clamp(hudDrag.startX + (delta.X / screen.X), 0.05, 0.95)
            config.hudPos.y = clamp(hudDrag.startY + delta.Y, 2, 120)
            hudApplyPosition()
        end))
        RootMaid:GiveTask(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType ~= MOUSE1 and input.UserInputType ~= TOUCH then return end
            if hudDrag and hudDrag.moved then saveConfig(true); savePositions() end
            hudDrag = nil
        end))

        RootMaid:GiveTask(Ticker.add(function(dt)
            if not StatusHUD.dot then return end
            StatusHUD.accum = StatusHUD.accum + (dt or 0.016)
            if StatusHUD.accum < 0.033 then return end
            StatusHUD.accum = 0
            local pulse = sin(now() * 4) * 0.5 + 0.5
            if StatusHUD.state == "active" then
                StatusHUD.dot.BackgroundColor3 = rgb(255, 70, 70)
                StatusHUD.dot.Size = ud2(0, 8 + pulse * 3, 0, 8 + pulse * 3)
                StatusHUD.stroke.Color = rgb(255, 70, 70)
            else
                StatusHUD.dot.BackgroundColor3 = rgb(40, 220, 140)
                StatusHUD.dot.Size = ud2(0, 8 + pulse * 1.5, 0, 8 + pulse * 1.5)
                StatusHUD.stroke.Color = rgb(40, 220, 140)
            end
        end))
    end

    local lastHudText = nil
    function StatusHUD.Set(newState, targetName)
        StatusHUD.state = newState
        if not StatusHUD.label then return end
        local text, color
        if newState == "active" then
            text = "RESET ▸ " .. (targetName or "?")
            color = rgb(255, 120, 120)
        else
            text = "IDLE"
            color = rgb(200, 215, 230)
        end
        if text ~= lastHudText then
            lastHudText = text
            StatusHUD.label.Text = text
            StatusHUD.label.TextColor3 = color
        end
    end

    local roleRemote = nil
    local roleRemoteTried = -1e9
    local function getRoleRemote()
        if roleRemote and roleRemote.Parent then return roleRemote end
        local t = now()
        if (t - roleRemoteTried) < 5 then return roleRemote end
        roleRemoteTried = t
        pcall(function()
            local remote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
            if remote and remote:IsA("RemoteFunction") then roleRemote = remote end
        end)
        return roleRemote
    end

    local roleCache = { data = nil, timestamp = 0 }
    local function getCachedRoleData()
        local t = now()
        local ttl = config.roleCacheTTL or 0.8
        if roleCache.data and (t - roleCache.timestamp) < ttl then return roleCache.data end
        local remote = getRoleRemote()
        if remote then
            local ok, result = pcall(function() return remote:InvokeServer() end)
            if ok and type(result) == "table" then
                roleCache.data, roleCache.timestamp = result, t
                return result
            end
        end
        roleCache.timestamp = t
        return roleCache.data
    end

    local function invalidateRoleCache()
        roleCache.data = nil
        roleCache.timestamp = 0
    end

    local function isValidTarget(player)
        if not player or player == LocalPlayer or not player.Parent then return false end
        if state.whitelist[player.UserId] then return false end
        local char = player.Character
        if not char then return false end
        if not char:FindFirstChild("HumanoidRootPart") then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then return false end
        return true
    end

    local function getSelectedOrFirst()
        if isValidTarget(state.resetSelPlr) then return state.resetSelPlr end
        for _, player in ipairs(state.selectedPlayers) do
            if isValidTarget(player) then return player end
        end
        return nil
    end

    local function hasGunModel(char)
        if not char then return false end
        if char:FindFirstChild("Gun") or char:FindFirstChild("Revolver") then return true end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            local name = tool.Name:lower()
            if name:find("gun", 1, true) or name:find("revolver", 1, true) then return true end
        end
        return false
    end

    local function quickScanSheriff()
        local players = Players:GetPlayers()
        for i = 1, #players do
            local player = players[i]
            if player ~= LocalPlayer and not state.whitelist[player.UserId] then
                if hasGunModel(player.Character) then return player end
                local bp = player:FindFirstChild("Backpack")
                if bp and (bp:FindFirstChild("Gun") or bp:FindFirstChild("Revolver")) then
                    return player
                end
            end
        end
        return nil
    end

    local function findTargetByRole(roleName)
        local roleData = getCachedRoleData()
        if not roleData then return nil end
        for playerName, data in pairs(roleData) do
            if type(data) == "table" and data.Role == roleName and not data.Killed and not data.Dead then
                local p = Players:FindFirstChild(playerName)
                if p and p ~= LocalPlayer and not state.whitelist[p.UserId] then return p end
            end
        end
        return nil
    end

    local sheriffCache = { player = nil, at = 0 }
    local function findSheriff()
        local t = now()
        if sheriffCache.player and (t - sheriffCache.at) < 0.35 and isValidTarget(sheriffCache.player) then
            return sheriffCache.player
        end
        local found = quickScanSheriff()
        if not found then found = findTargetByRole("Sheriff") end
        sheriffCache.player, sheriffCache.at = (isValidTarget(found) and found or nil), t
        return sheriffCache.player
    end

    local function findMurderer()
        local byRole = findTargetByRole("Murderer")
        if byRole then return byRole end

        local players = Players:GetPlayers()
        for i = 1, #players do
            local player = players[i]
            if player ~= LocalPlayer and not state.whitelist[player.UserId] then
                local char = player.Character
                if char then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        local name = tool.Name:lower()
                        if name:find("knife", 1, true) or name:find("murderer", 1, true) then
                            return player
                        end
                    end
                end
            end
        end
        return nil
    end

    local function findNearest()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local best, bestDist = nil, math.huge
        local players = Players:GetPlayers()
        for i = 1, #players do
            local player = players[i]
            if isValidTarget(player) then
                local tr = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if tr then
                    local d = (root.Position - tr.Position).Magnitude
                    if d < bestDist then best, bestDist = player, d end
                end
            end
        end
        return best
    end

    local firetouch = (type(firetouchinterest) == "function") and firetouchinterest or nil
    local sethidden = (type(sethiddenproperty) == "function") and sethiddenproperty or nil

    local function touch(a, b)
        if not firetouch or not a or not b then return end
        firetouch(a, b, 0)
        firetouch(a, b, 1)
    end

    local BODY_PART_NAMES = {
        "HumanoidRootPart", "Head", "Torso", "Upper Torso", "Lower Torso",
        "Left Arm", "Right Arm", "Left Leg", "Right Leg",
        "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand",
        "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot",
    }

    local function restoreSelf(character, savedData, originalDestroyHeight)
        pcall(function()
            Workspace.FallenPartsDestroyHeight = originalDestroyHeight
            if not character or not savedData then return end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not humanoid or not rootPart then return end
            rootPart.CFrame = savedData.cframe
            rootPart.AssemblyLinearVelocity = V3_ZERO
            rootPart.AssemblyAngularVelocity = V3_ZERO
            humanoid.PlatformStand = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            if humanoid.Health < humanoid.MaxHealth then humanoid.Health = humanoid.MaxHealth end
            for i = 1, #BODY_PART_NAMES do
                local part = character:FindFirstChild(BODY_PART_NAMES[i])
                if part and part:IsA("BasePart") then part.CanCollide = true end
            end
        end)
        pcall(function() Workspace.FallenPartsDestroyHeight = originalDestroyHeight end)
    end

    local currentReset = nil
    local massResetThread = nil
    local pendingRetryThread = nil

    local function cancelCurrentReset()
        if massResetThread then
            pcall(task.cancel, massResetThread)
            massResetThread = nil
        end

        if pendingRetryThread then
            pcall(task.cancel, pendingRetryThread)
            pendingRetryThread = nil
        end
        if currentReset and currentReset.cancel then
            pcall(currentReset.cancel)
        end
        currentReset = nil
    end

    local TOUCH_PART_PRIORITY = {
        "RightHand", "LeftHand", "RightFoot", "LeftFoot",
        "Right Arm", "Left Arm", "Right Leg", "Left Leg",
        "Torso", "HumanoidRootPart", "Head",
    }

    local function VoidReset(TargetPlayer, _retryCount)
        if not TargetPlayer or not TargetPlayer.Parent then return false end
        if TargetPlayer == LocalPlayer or state.whitelist[TargetPlayer.UserId] then return false end

        _retryCount = _retryCount or 0

        if _retryCount == 0 then
            local last = state.lastResetAt[TargetPlayer.UserId]
            if last and (now() - last) < (config.targetCooldown or 0) then return false end
        end

        cancelCurrentReset()

        local Character = LocalPlayer.Character
        if not Character then return false end
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        local RootPart = Humanoid and Humanoid.RootPart
        local TCharacter = TargetPlayer.Character
        local TRootPart = TCharacter and TCharacter:FindFirstChild("HumanoidRootPart")
        local THead = TCharacter and TCharacter:FindFirstChild("Head")
        if not (Humanoid and RootPart and TRootPart) then return false end

        state.lastResetAt[TargetPlayer.UserId] = now()

        local touchParts = {}
        for i = 1, #TOUCH_PART_PRIORITY do
            local p = TCharacter:FindFirstChild(TOUCH_PART_PRIORITY[i])
            if p and p:IsA("BasePart") then insert(touchParts, p) end
        end
        if #touchParts == 0 then insert(touchParts, TRootPart) end

        local savedData = { cframe = RootPart.CFrame }
        local originalDestroyHeight = Workspace.FallenPartsDestroyHeight
        Workspace.FallenPartsDestroyHeight = -math.huge
        Humanoid.PlatformStand = true

        local bv = new("BodyVelocity")
        bv.MaxForce = v3(math.huge, math.huge, math.huge)
        bv.Velocity = v3(0, -200000, 0)
        bv.Parent = RootPart

        local bg = new("BodyGyro")
        bg.MaxTorque = v3(math.huge, math.huge, math.huge)
        bg.P = 9e8
        bg.D = 9e8
        bg.CFrame = RootPart.CFrame
        bg.Parent = RootPart

        local startTime = now()
        local frameCount = 0
        local done = false
        local spinRate = math.pi * 20
        local resetObj = { bv = bv, bg = bg, conn = nil, watchdog = nil }

        local function cleanup(success, manual)
            if done then return end
            done = true
            if currentReset == resetObj then currentReset = nil end
            if resetObj.conn then pcall(function() resetObj.conn:Disconnect() end) end
            if resetObj.watchdog then pcall(task.cancel, resetObj.watchdog) end
            pcall(function() bv:Destroy() end)
            pcall(function() bg:Destroy() end)
            restoreSelf(Character, savedData, originalDestroyHeight)
            BindableButtons.ResetActive = false
            StatusHUD.Set("idle")
            if not success and not manual and _retryCount < config.maxRetries then
                local delay = (config.retryDelay or 0.18) * (1 + _retryCount * 0.5)
                pendingRetryThread = task.delay(delay, function()
                    pendingRetryThread = nil
                    if TargetPlayer and TargetPlayer.Parent and not state.whitelist[TargetPlayer.UserId] then
                        VoidReset(TargetPlayer, _retryCount + 1)
                    end
                end)
                RootMaid:GiveTask(pendingRetryThread)
            end
        end

        resetObj.cancel = function() cleanup(true, true) end
        currentReset = resetObj

        StatusHUD.Set("active", TargetPlayer.Name)
        BindableButtons.ResetActive = true

        resetObj.watchdog = task.delay((config.resetDuration or 0.55) + 2, function()
            if not done then cleanup(false) end
        end)

        resetObj.conn = RunService.Heartbeat:Connect(function()
            frameCount = frameCount + 1
            local elapsed = now() - startTime

            if TargetPlayer.Character ~= TCharacter or not TRootPart.Parent then
                cleanup(true)
                return
            end
            if elapsed >= (config.resetDuration or 0.55) or not Character.Parent or not RootPart.Parent then
                cleanup(false)
                return
            end

            local angle = elapsed * spinRate
            local dynamicOffset = v3(cos(angle) * 1.5, sin(angle) * 1.5, sin(angle) * 1.5)
            RootPart.CFrame = cfr(TRootPart.Position + dynamicOffset)
            RootPart.AssemblyLinearVelocity = v3(200000, -200000, 200000)
            RootPart.AssemblyAngularVelocity = v3(20000, 20000, 20000)

            if frameCount % 2 == 1 then
                for i = 1, #touchParts do touch(RootPart, touchParts[i]) end
            else
                touch(RootPart, TRootPart)
                if THead then touch(RootPart, THead) end
            end

            if sethidden then pcall(sethidden, RootPart, "PhysicsRepRootPart", TRootPart) end
            if Humanoid.Health < Humanoid.MaxHealth * 0.5 then
                Humanoid.Health = Humanoid.MaxHealth
            end
        end)

        return true
    end

    local function startAutoModule(maidKey, finderFunc, intervalFn)
        if maids[maidKey] then
            maids[maidKey]:Destroy()
            maids[maidKey] = nil
        end
        local maid = Maid.new()
        maids[maidKey] = maid
        local thread = task.spawn(function()
            while not maid._destroyed do
                local target = nil
                pcall(function()
                    target = finderFunc()
                    if target then VoidReset(target) end
                end)
                local base = intervalFn()
                if target then
                    task.wait(math.max(base, (config.resetDuration or 0.55) + 0.08))
                else
                    task.wait(base)
                end
            end
        end)
        maid:GiveTask(thread)
        return maid
    end

    local function stopAutoModule(maidKey)
        if maids[maidKey] then
            maids[maidKey]:Destroy()
            maids[maidKey] = nil

            cancelCurrentReset()
        end
    end

    local ACTIONS = {}

    ACTIONS.sheriff = {
        name = "Sheriff", short = "Sh", label = "🔫 Sheriff",
        run = function()
            local t = findSheriff()
            if t then VoidReset(t) else Notify("Error", "Sheriff not found", 3) end
        end,
    }
    ACTIONS.murderer = {
        name = "Murderer", short = "Mur", label = "🔪 Murderer",
        run = function()
            local t = findMurderer()
            if t then VoidReset(t) else Notify("Error", "Murderer not found", 3) end
        end,
    }
    ACTIONS.all = {
        name = "All(w)", short = "All", label = "👥 Everyone",
        run = function()
            if massResetThread then
                Notify("Action", "Mass reset already running", 2)
                return
            end
            massResetThread = task.spawn(function()
                local players = Players:GetPlayers()
                for i = 1, #players do
                    local p = players[i]
                    if isValidTarget(p) then
                        VoidReset(p)
                        task.wait((config.resetDuration or 0.55) + 0.1)
                    end
                end
                massResetThread = nil
            end)
            Notify("Action", "Resetting all non-whitelisted...", 2)
        end,
    }
    ACTIONS.selected = {
        name = "Selected", short = "Sel", label = "🎯 Selected",
        run = function()
            local t = getSelectedOrFirst()
            if t then VoidReset(t) else Notify("Quick", "No valid selected player", 2) end
        end,
    }
    ACTIONS.nearest = {
        name = "Nearest", short = "Nrst", label = "📍 Nearest",
        run = function()
            local t = findNearest()
            if t then VoidReset(t) else Notify("Quick", "No valid target nearby", 2) end
        end,
    }
    ACTIONS.cancel = {
        name = "Cancel", short = "Can", label = "⏹ Cancel",
        run = function()
            cancelCurrentReset()
            Notify("Quick", "Reset cancelled", 2)
        end,
    }

    local ACTION_ORDER = { "sheriff", "murderer", "all", "selected", "nearest", "cancel" }

    local function runAction(id)
        local action = ACTIONS[id]
        if not action then return end
        local ok, err = xpcall(action.run, debug.traceback)
        if not ok then
            warn("[" .. BRAND .. "][action:" .. id .. "] " .. tostring(err))
            Notify("Error", "Action failed: " .. id, 3)
        end
    end

    local Keybinds = { capture = nil }
    local IGNORED_KEYS = {
        LeftShift = true, RightShift = true, LeftControl = true, RightControl = true,
        LeftAlt = true, RightAlt = true, LeftMeta = true, RightMeta = true,
        CapsLock = true, Unknown = true, Escape = true,
    }

    local function keyName(id)
        local k = config.keybinds[id]
        return (k and k ~= "") and k or "—"
    end

    RootMaid:GiveTask(UserInputService.InputBegan:Connect(function(input, processed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local name = input.KeyCode.Name

        if Keybinds.capture then
            if IGNORED_KEYS[name] then return end
            local id = Keybinds.capture
            Keybinds.capture = nil
            config.keybinds[id] = name
            saveConfig()
            Notify("Hotkey", ACTIONS[id].name .. " → " .. name, 3)
            return
        end

        if processed then return end
        for _, id in ipairs(ACTION_ORDER) do
            if config.keybinds[id] == name then
                runAction(id)
                break
            end
        end
    end))

    local mainSection = AddSection("💀 " .. BRAND)
    mainSection:AddLabel("MM2 • Void Reset • by " .. AUTHOR)

    local actionSection = AddSection("⚡ Reset")
    actionSection:AddButton("🔫 Sheriff", function() runAction("sheriff") end)
    actionSection:AddButton("🔪 Murderer", function() runAction("murderer") end)
    actionSection:AddButton("👥 Everyone", function() runAction("all") end)
    actionSection:AddButton("🎯 Selected", function() runAction("selected") end)
    actionSection:AddButton("📍 Nearest", function() runAction("nearest") end)
    actionSection:AddButton("⏹ Cancel", function() runAction("cancel") end)
    actionSection:AddPlayerDropdown("▸ Pick player", function(p)
        if p and p ~= LocalPlayer then
            state.resetSelPlr = p
            if state.whitelist[p.UserId] then
                Notify("Whitelist", p.Name .. " is whitelisted!", 3)
            else
                VoidReset(p)
                Notify("Action", "Resetting " .. p.Name, 2)
            end
        end
    end)

    local autoSection = AddSection("🤖 Auto")
    autoSection:AddToggle("Auto Sheriff", function(enabled)
        if enabled then
            startAutoModule("autoSheriff", findSheriff, function() return config.autoSheriffDelay end)
        else
            stopAutoModule("autoSheriff")
        end
    end)
    autoSection:AddToggle("Auto Murderer", function(enabled)
        if enabled then
            startAutoModule("autoMurderer", findMurderer, function() return config.autoMurdererDelay end)
        else
            stopAutoModule("autoMurderer")
        end
    end)
    autoSection:AddToggle("Loop", function(enabled)
        if not enabled then
            stopAutoModule("loopPlr")
            return
        end
        local loopIndex = 1
        startAutoModule("loopPlr", function()
            if isValidTarget(state.resetSelPlr) then return state.resetSelPlr end
            local list = state.selectedPlayers
            for _ = 1, #list do
                loopIndex = ((loopIndex - 1) % #list) + 1
                local p = list[loopIndex]
                if isValidTarget(p) then return p end
            end
            return nil
        end, function() return config.loopInterval end)
    end)
    autoSection:AddToggle("Aura", function(enabled)
        if not enabled then
            stopAutoModule("resetAura")
            return
        end
        startAutoModule("resetAura", function()
            local char = LocalPlayer.Character
            local rootPart = char and char:FindFirstChild("HumanoidRootPart")
            if not rootPart then return nil end
            local myPos = rootPart.Position
            local maxDistSq = (config.auraStuds or 15) ^ 2
            local best, bestDist = nil, maxDistSq
            local players = Players:GetPlayers()
            for i = 1, #players do
                local player = players[i]
                if isValidTarget(player) then
                    local tr = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if tr then
                        local d = (myPos - tr.Position).Magnitude
                        if d * d <= bestDist then best, bestDist = player, d * d end
                    end
                end
            end
            return best
        end, function() return config.auraInterval end)
    end)
    autoSection:AddToggle("Click", function(enabled)
        if maids.clickReset then
            maids.clickReset:Destroy()
            maids.clickReset = nil
        end
        if not enabled then return end

        maids.clickReset = Maid.new()
        local camera = Workspace.CurrentCamera
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.IgnoreWater = true

        local function resolveTarget()

            local char = LocalPlayer.Character
            rayParams.FilterDescendantsInstances = char and { char } or {}
            local mouse = LocalPlayer:GetMouse()
            if camera and mouse then
                local unit = camera:ViewportPointToRay(mouse.X, mouse.Y, 1000)
                local hit = Workspace:Raycast(unit.Origin, unit.Direction * 1000, rayParams)
                if hit and hit.Instance then
                    local model = hit.Instance:FindFirstAncestorWhichIsA("Model")
                    local player = model and Players:GetPlayerFromCharacter(model)
                    if player then return player end
                end
            end
            local target = mouse and mouse.Target
            local model = target and target:FindFirstAncestorWhichIsA("Model")
            local player = model and Players:GetPlayerFromCharacter(model)
            return player or nil
        end

        local function onInput(input, processed)
            if processed then return end
            if input.UserInputType ~= MOUSE1 and input.UserInputType ~= TOUCH then return end
            local ok, player = pcall(resolveTarget)
            if not ok or not player or player == LocalPlayer then return end
            state.resetSelPlr = player
            if state.whitelist[player.UserId] then
                Notify("Click", player.Name .. " is whitelisted!", 3)
            else
                VoidReset(player)
                Notify("Click", "Resetting " .. player.Name, 2)
            end
        end

        maids.clickReset:GiveTask(UserInputService.InputBegan:Connect(onInput))
    end)

    local listSection = AddSection("📋 Lists")
    listSection:AddPlayerDropdown("🎯 Select", function(p)
        if p and p ~= LocalPlayer then
            state.resetSelPlr = p
            Notify("Selected", p.Name .. " set", 3)
        end
    end)
    listSection:AddPlayerDropdown("➕ Loop", function(p)
        if p and p ~= LocalPlayer then
            state.resetSelPlr = p
            if not state.selectedSet[p.UserId] then
                state.selectedSet[p.UserId] = true
                insert(state.selectedPlayers, p)
                Notify("Selected", p.Name .. " added", 3)
            end
        end
    end)
    listSection:AddButton("🧹 Clear loop", function()
        clearTable(state.selectedPlayers)
        clearTable(state.selectedSet)
        Notify("Selected", "Cleared", 3)
    end)
    listSection:AddPlayerDropdown("🛡 Whitelist", function(p)
        if p and p ~= LocalPlayer then
            state.whitelist[p.UserId] = p.Name
            Notify("Whitelist", p.Name .. " added", 3)
            saveConfig()
        end
    end)
    listSection:AddPlayerDropdown("🛡 Un-whitelist", function(p)
        if p and state.whitelist[p.UserId] then
            state.whitelist[p.UserId] = nil
            Notify("Whitelist", p.Name .. " removed", 3)
            saveConfig()
        elseif p then
            Notify("Whitelist", p.Name .. " is not whitelisted", 3)
        end
    end)
    listSection:AddButton("🧹 Clear WL", function()
        clearTable(state.whitelist)
        Notify("Whitelist", "Cleared", 3)
        saveConfig()
    end)

    local settingsSection = AddSection("⚙️ Tuning")
    settingsSection:AddSlider("Max Retries", 0, 5, config.maxRetries, function(v)
        config.maxRetries = v
        saveConfig()
    end)
    settingsSection:AddSlider("Retry Delay (x0.1s)", 1, 10, (config.retryDelay or 0.18) * 10, function(v)
        config.retryDelay = v * 0.1
        saveConfig()
    end)
    settingsSection:AddSlider("Reset Duration (s)", 0.2, 1.0, config.resetDuration, function(v)
        config.resetDuration = v
        saveConfig()
    end)
    settingsSection:AddSlider("Aura Radius (studs)", 5, 50, config.auraStuds, function(v)
        config.auraStuds = v
        saveConfig()
    end)
    settingsSection:AddSlider("Loop Interval (s)", 0.1, 1.0, config.loopInterval, function(v)
        config.loopInterval = v
        saveConfig()
    end)
    settingsSection:AddSlider("Aura Interval (s)", 0.1, 1.0, config.auraInterval, function(v)
        config.auraInterval = v
        saveConfig()
    end)
    settingsSection:AddSlider("Target Cooldown (s)", 0, 3, config.targetCooldown, function(v)
        config.targetCooldown = v
        saveConfig()
    end)
    settingsSection:AddSlider("Role Cache (x0.1s)", 2, 30, (config.roleCacheTTL or 0.8) * 10, function(v)
        config.roleCacheTTL = v * 0.1
        saveConfig()
    end)
    settingsSection:AddToggle("Notifications", function(enabled)
        config.notifications = enabled and true or false
        saveConfig()
    end)

    local floatSection = AddSection("🔘 Binds")
    floatSection:AddToggle("SFX 🔇", function(bool) Audio.setMuted(bool) end)

    local function toggleBindButton(actionId)
        return function(enabled)
            local id = "bind_" .. actionId

            config.binds[actionId] = (enabled == true)
            saveConfig()
            if enabled then
                BindableButtons.AddBButton(id, ACTIONS[actionId].short, function() runAction(actionId) end, actionId == "sheriff")
            else
                BindableButtons.DeleteBButton(id)
            end
        end
    end

    for _, id in ipairs(ACTION_ORDER) do
        floatSection:AddToggle("Bind " .. ACTIONS[id].name, toggleBindButton(id))
    end
    floatSection:AddSlider("Bind Size (%)", 5, 25, math.floor((config.bindButtonSize or 0.11) * 100), function(value)
        BindableButtons.setSize(value / 100)
    end)
    floatSection:AddButton("🧩 Reset bind layout", function()
        BindableButtons.resetLayout()
        Notify("Binds", "Layout reset", 2)
    end)
    floatSection:AddButton("🛑 Panic", function()
        cancelCurrentReset()
        for _, key in ipairs({ "loopPlr", "clickReset", "resetAura", "autoSheriff", "autoMurderer" }) do
            stopAutoModule(key)
        end
        BindableButtons.clearAll()
        for _,r in ipairs(ODHX.records) do
            if r.kind=="Toggle" and (r.section=="🤖 Auto" or (r.section=="🔘 Binds" and r.name:sub(1,5)=="Bind ")) then
                ODHX.Set(r.section,r.name,r.kind,false,false)
            end
        end
        Notify("Panic", "All modules stopped", 3)
    end)

    local keySection = AddSection("🔑 Keys")
    for _, id in ipairs(ACTION_ORDER) do
        keySection:AddToggle("Key " .. ACTIONS[id].name .. " [" .. keyName(id) .. "]", function(enabled)
            if enabled then
                Keybinds.capture = id
                Notify("Hotkey", "Press a key for " .. ACTIONS[id].name .. "...", 5)
            else
                config.keybinds[id] = nil
                if Keybinds.capture == id then Keybinds.capture = nil end
                saveConfig()
                Notify("Hotkey", ACTIONS[id].name .. " key cleared", 3)
            end
        end)
    end
    keySection:AddButton("🧹 Clear keys", function()
        clearTable(config.keybinds)
        Keybinds.capture = nil
        saveConfig()
        Notify("Hotkey", "All hotkeys cleared", 3)
    end)

    local configSection = AddSection("💾 Config")
    configSection:AddButton("💾 Save", function()
        if saveConfig(true) then Notify("Config", "Saved → " .. CONFIG_PATH, 3)
        else Notify("Config", "Filesystem unavailable in this executor", 4) end
    end)
    configSection:AddButton("📂 Reload", function()
        if loadConfig() then
            ODHX.data.controls=config.pluginUI or {}
            ODHX.Restore()
            BindableButtons.setSize(config.bindButtonSize or 0.11)
            hudApplyPosition()
            Notify("Config", "Reloaded", 3)
        else
            Notify("Config", "Nothing to load", 3)
        end
    end)
    configSection:AddButton("♻ Reset config", function()
        for k, v in pairs(DEFAULTS) do
            if type(v) == "table" then
                clearTable(config[k])
                for k2, v2 in pairs(v) do config[k][k2] = v2 end
            else
                config[k] = v
            end
        end
        clearTable(state.whitelist)
        ODHX.ResetControls()
        BindableButtons.setSize(config.bindButtonSize)
        hudApplyPosition()
        saveConfig(true)
        Notify("Config", "Defaults restored", 3)
    end)

    local infoSection = AddSection("ℹ️")
    infoSection:AddButton("🧹 Clean duplicates", function()
        local n = purgeForeign(true)
        markOwnCards()
        Notify("Clean", "Removed " .. n .. " duplicate section(s)", 3)
    end)
    infoSection:AddLabel(PLUGIN_NAME .. " • " .. VERSION .. " • by " .. AUTHOR)
    infoSection:AddLabel("HUD drag • Binds drag • config saved")

    markOwnCards()

    RootMaid:GiveTask(task.spawn(function()

        for _, delay in ipairs({ 1.5, 2.5, 3.0, 5.0 }) do
            task.wait(delay)
            scanIfDirty()
        end
    end))

    Audio.init()
    StatusHUD.Init()
    BindableButtons.setSize(config.bindButtonSize or 0.11)
    hudApplyPosition()
    if configLoaded then
        SR_Log(BRAND .. " " .. VERSION .. " loaded (config restored)"
               .. (positionsLoaded and " (button layout restored)" or ""))
    else
        SR_Log(BRAND .. " " .. VERSION .. " loaded. Duplicates auto-cleaned.")
    end
    if headlessMode then
        Notify(BRAND, "Menu API missing — headless mode (binds/hotkeys work)", 5)
    end

    RootMaid:GiveTask(Players.PlayerRemoving:Connect(function(player)
        if not player then return end
        state.lastResetAt[player.UserId] = nil
        state.selectedSet[player.UserId] = nil
        for i = #state.selectedPlayers, 1, -1 do
            if state.selectedPlayers[i] == player then table.remove(state.selectedPlayers, i) end
        end
        if state.resetSelPlr == player then state.resetSelPlr = nil end
        if sheriffCache.player == player then sheriffCache.player = nil end
        invalidateRoleCache()
    end))

    RootMaid:GiveTask(Players.PlayerAdded:Connect(invalidateRoleCache))

    RootMaid:GiveTask(function()

        if canPersist and not persistDisabled then
            if saveThread then pcall(task.cancel, saveThread) end
            saveThread, saveQueued = nil, false
            pcall(saveConfig, true)
            pcall(savePositions)
        end

        persistDisabled = true
        if saveThread then pcall(task.cancel, saveThread) end
        saveThread, saveQueued = nil, false

        cancelCurrentReset()
        for _, m in pairs(maids) do if m then m:Destroy() end end
        clearTable(maids)
        clearTable(state.whitelist)
        clearTable(state.selectedPlayers)
        clearTable(state.selectedSet)
        clearTable(state.lastResetAt)
        Keybinds.capture = nil
        BindableButtons.clearAll()
        pcall(removeMySections)
        pcall(function()
            if storageGui then storageGui:Destroy() end
            storageGui = nil
        end)
    end)

    local function unload()
        RootMaid:DoCleaning()
    end

    pcall(function()
        if type(getgenv) ~= "function" then return end
        local g = getgenv()
        if type(g) ~= "table" then return end
        rawset(g, UNLOAD_GLOBAL, ODHX.Stop)
    end)

    ODHX.Bind("⚙️ Tuning", "Notifications", "Toggle", function() return config.notifications end)
    ODHX.Bind("🔘 Binds", "SFX 🔇", "Toggle", function() return config.muteSounds end)
    ODHX.Bind("⚙️ Tuning", "Max Retries", "Slider", function() return config.maxRetries end)
    ODHX.Bind("⚙️ Tuning", "Retry Delay (x0.1s)", "Slider", function() return config.retryDelay*10 end)
    ODHX.Bind("⚙️ Tuning", "Reset Duration (s)", "Slider", function() return config.resetDuration end)
    ODHX.Bind("⚙️ Tuning", "Aura Radius (studs)", "Slider", function() return config.auraStuds end)
    ODHX.Bind("⚙️ Tuning", "Loop Interval (s)", "Slider", function() return config.loopInterval end)
    ODHX.Bind("⚙️ Tuning", "Aura Interval (s)", "Slider", function() return config.auraInterval end)
    ODHX.Bind("⚙️ Tuning", "Target Cooldown (s)", "Slider", function() return config.targetCooldown end)
    ODHX.Bind("⚙️ Tuning", "Role Cache (x0.1s)", "Slider", function() return config.roleCacheTTL*10 end)
    ODHX.Bind("🔘 Binds", "Bind Size (%)", "Slider", function() return config.bindButtonSize*100 end)
    ODHX.cleanup=unload
    ODHX.Finish()
    pmReady = true

    local function reconcileBindButtons()
        for _, actionId in ipairs(ACTION_ORDER) do
            local btnId = "bind_" .. actionId
            local want = config.binds and config.binds[actionId] == true
            if not want then

                local ok, restored = pcall(function()
                    if not (ODHX.records and ACTIONS[actionId]) then return false end
                    local wanted = "Bind " .. ACTIONS[actionId].name
                    for _, rec in ipairs(ODHX.records) do
                        if rec.kind == "Toggle" and rec.name == wanted and rec.value == true then return true end
                    end
                    return false
                end)
                if ok and restored then want = true end
            end
            if want then
                BindableButtons.AddBButton(btnId, ACTIONS[actionId].short, function() runAction(actionId) end, actionId == "sheriff")
            else
                BindableButtons.DeleteBButton(btnId)
            end
        end
        BindableButtons.relayout()
    end
    local reconcileOK, reconcileErr = pcall(reconcileBindButtons)
    if not reconcileOK then SR_Log("[PM VALEX] on-screen buttons were not rebuilt: " .. tostring(reconcileErr)) end

end
end)

SR_UI.tryModule("Pm-Wallhop", function()
do
    local ODHX = CreateODHX("Pm-Wallhop", "Pm-WallHop", "ODH_Pm-Wallhop_settings.json", true, false)
    local shared = ODHX.shared
    local UpdateWallhopButtonState, performVideoFlick, performWallhop
    local wallhopButtonSize = 0.11

    local wallhop_section = shared.AddSection("Pm-WallHop")

    wallhop_section:AddLabel("Pm-WallHop Script by Noir_Creator (Improved)")
    SR_Paragraph(wallhop_section, "Pm-WallHop", "Fling on jump next to a wall seam")

    local isWallHopEnabled = false
    wallhop_section:AddToggle("Enable WallHop", function(bool)
        isWallHopEnabled = bool
        if bool then
            shared.Notify("Pm-WallHop enabled", 2)
        else
            shared.Notify("Pm-WallHop disabled", 2)
        end
        UpdateWallhopButtonState()
    end)

    wallhop_section:AddButton("Toggle WallHop", function()
        isWallHopEnabled = not isWallHopEnabled
        shared.Notify(isWallHopEnabled and "Pm-WallHop enabled" or "Pm-WallHop disabled", 2)
        UpdateWallhopButtonState()
    end)

    local detectionDistance = 3
    wallhop_section:AddSlider("Detection distance", 1, 6, 3, function(int)
        detectionDistance = int
        shared.Notify("Distance: " .. int, 2)
    end)

    local flickPower = 50
    wallhop_section:AddSlider("Fling power", 20, 100, 50, function(int)
        flickPower = int
        shared.Notify("Power: " .. int, 2)
    end)

    wallhop_section:AddButton("Test fling", function()
        if isWallHopEnabled then
            performVideoFlick()
        else
            shared.Notify("Enable WallHop first!", 2)
        end
    end)

    wallhop_section:AddKeybind("Toggle Keybind", "F", function()
        isWallHopEnabled = not isWallHopEnabled
        shared.Notify(isWallHopEnabled and "Pm-WallHop enabled" or "Pm-WallHop disabled", 2)
        UpdateWallhopButtonState()
    end)

    wallhop_section:AddKeybind("WallHop Jump Key", "J", function()
        if isWallHopEnabled then
            performWallhop()
        else
            shared.Notify("WallHop is off! Press F or use the menu button", 2)
        end
    end)

    local WallhopBindableButtons = {Buttons = {}, Maids = {}, Count = 0}

    local __SHAPES = {
        [0] = "rbxassetid://86221076925479",
        [1] = "rbxassetid://96242665417546",
        [2] = "rbxassetid://97129189935336",
        [3] = "rbxassetid://76165862027868",
        [4] = "rbxassetid://125868092127496"
    }

    local __NORMAL_COLOR = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(0.133333, 0.827451, 0.494118)),
        ColorSequenceKeypoint.new(0.6, Color3.new(0.231373, 0.509804, 0.498039)),
        ColorSequenceKeypoint.new(1, Color3.new(0.501961, 0.501961, 0.501961))
    })

    local __ACTIVE_COLOR = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(0.0, 0.8, 0.4)),
        ColorSequenceKeypoint.new(0.6, Color3.new(0.0, 0.5, 0.3)),
        ColorSequenceKeypoint.new(1, Color3.new(0.2, 0.8, 0.6))
    })

    local function safecallback(callback)
        if not callback then return end
        local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
        if not ok then warn("[BIND ERROR] " .. tostring(err)) end
    end

    local function GetStorage()
        local parent = gethui and gethui()
        if not parent or typeof(parent) ~= "Instance" then parent = SR_UI.service("CoreGui") end
        if not parent or typeof(parent) ~= "Instance" then
            parent = game.Players.LocalPlayer:WaitForChild("PlayerGui", 5)
        end
        if typeof(parent) ~= "Instance" then
            parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        end
        local sg = parent:FindFirstChild("@wallhopstorage")
        if not sg then
            sg = Instance.new("ScreenGui")
            sg.Name = "@wallhopstorage"
            sg.ResetOnSpawn = false
            sg.IgnoreGuiInset = true
            pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
            sg.Parent = parent
        end
        return sg
    end

    local function MakeDraggable(gui, maid, ripple, sound, clickFunc)
        local dragging, dragInput, dragStart, startPos
        local hasMoved = false

        maid:GiveTask(ODHX.Connect(gui.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging, dragStart, startPos = true, input.Position, gui.Position
                hasMoved = false

                sound:Play()
                local absPos = gui.AbsolutePosition
                ripple.Position = UDim2.new(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
                ripple.Size = UDim2.new(0, 0, 0, 0)
                ripple.BackgroundTransparency = 0.5
                ripple.Visible = true

                SR_UI.service("TweenService"):Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 45, 0, 45),
                    BackgroundTransparency = 1
                }):Play()

                local releaseConn
                releaseConn = ODHX.Connect(SR_UI.service("UserInputService").InputEnded, function(endInput)
                    if endInput.UserInputType == input.UserInputType then
                        dragging = false
                        if not hasMoved then
                            clickFunc()
                        else
                            SR_Store.posSave("wallhop", gui.Name, gui.Position)
                        end
                        releaseConn:Disconnect()
                    end
                end)
            end
        end))

        maid:GiveTask(ODHX.Connect(gui.InputChanged, function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end))

        maid:GiveTask(ODHX.Connect(SR_UI.service("UserInputService").InputChanged, function(input)
            if dragging and input == dragInput then
                local delta = input.Position - dragStart
                if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then hasMoved = true end
                local screen = gui.Parent.AbsoluteSize
                gui.Position = UDim2.new(startPos.X.Scale + (delta.X / screen.X), 0, startPos.Y.Scale + (delta.Y / screen.Y), 0)
            end
        end))
    end

    function WallhopBindableButtons.AddBButton(id, text, onFunc, offFunc)
        if WallhopBindableButtons.Buttons[id] then return WallhopBindableButtons.Buttons[id]:FindFirstChild("BindValue") end

        local buttonMaid = {}
        function buttonMaid:GiveTask(task)
            table.insert(buttonMaid._tasks or {}, task)
            return task
        end
        function buttonMaid:Destroy()
            if buttonMaid._tasks then
                for _, t in pairs(buttonMaid._tasks) do
                    if typeof(t) == "RBXScriptConnection" then t:Disconnect()
                    elseif typeof(t) == "Instance" then t:Destroy()
                    elseif type(t) == "function" then t()
                    end
                end
            end
        end
        buttonMaid._tasks = {}

        local screen = workspace.CurrentCamera.ViewportSize
        local buttonSizeY = 0.11
        local widthScale = buttonSizeY * (screen.Y / screen.X)

        local xPos = 0.1 + ((WallhopBindableButtons.Count % 8) * (widthScale + 0.005))
        local yPos = 0.7 - (math.floor(WallhopBindableButtons.Count / 8) * (buttonSizeY + 0.015))

        local ImageButton = Instance.new("ImageButton")
        ImageButton.Name = id
        ImageButton.Size = UDim2.new(widthScale, 0, buttonSizeY, 0)
        ImageButton.Position = UDim2.new(xPos, 0, yPos, 0)
        local savedPos = SR_Store.posGet("wallhop", id)
        if savedPos then
            ImageButton.Position = UDim2.new(savedPos.xs, savedPos.xo, savedPos.ys, savedPos.yo)
        end
        ImageButton.AnchorPoint = Vector2.new(0.5, 0.5)
        ImageButton.Image = __SHAPES[0]
        ImageButton.BackgroundTransparency = 1
        ImageButton.BorderSizePixel = 0
        ImageButton.ClipsDescendants = false
        ImageButton.AutoButtonColor = false
        ImageButton.Parent = GetStorage()
        buttonMaid:GiveTask(ImageButton)

        local BindValue = Instance.new("BoolValue", ImageButton)
        BindValue.Name = "BindValue"

        local TextLabel = Instance.new("TextLabel", ImageButton)
        TextLabel.Name = "@Text"
        TextLabel.Size = UDim2.new(0.8, 0, 0.8, 0)
        TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
        TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        TextLabel.BackgroundTransparency = 1
        TextLabel.Font = Enum.Font.Jura
        TextLabel.Text = text
        TextLabel.TextColor3 = Color3.new(1, 1, 1)
        TextLabel.TextSize = 10
        TextLabel.TextWrapped = true
        TextLabel.ZIndex = 3

        local Aspect = Instance.new("UIAspectRatioConstraint", ImageButton)
        Aspect.AspectRatio = 1
        Aspect.AspectType = Enum.AspectType.ScaleWithParentSize

        local Gradient = Instance.new("UIGradient", ImageButton)
        Gradient.Name = "@Stroke"
        Gradient.Color = __NORMAL_COLOR

        local ripple = Instance.new("Frame")
        ripple.Name = "@ripple"
        ripple.BackgroundColor3 = Color3.fromRGB(0, 155, 255)
        ripple.BackgroundTransparency = 0.5
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.Visible = false
        ripple.ZIndex = 2
        ripple.Parent = ImageButton
        Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)

        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://3868133279"
        sound.Volume = 0.5
        sound.Parent = ImageButton

        local debounce = false
        local tInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

        local function onClick()
            if debounce then return end
            debounce = true
            local fOut = SR_UI.service("TweenService"):Create(ImageButton, tInfo, {ImageTransparency = 1})
            fOut:Play()
            fOut.Completed:Wait()

            BindValue.Value = not BindValue.Value
            Gradient.Color = BindValue.Value and __ACTIVE_COLOR or __NORMAL_COLOR
            if BindValue.Value then safecallback(onFunc) else safecallback(offFunc) end

            local fIn = SR_UI.service("TweenService"):Create(ImageButton, tInfo, {ImageTransparency = 0})
            fIn:Play()
            fIn.Completed:Wait()
            debounce = false
        end

        MakeDraggable(ImageButton, buttonMaid, ripple, sound, onClick)
        buttonMaid:GiveTask(SR_Rota.Attach(Gradient, nil, 60))

        WallhopBindableButtons.Buttons[id] = ImageButton
        WallhopBindableButtons.Maids[id] = buttonMaid
        WallhopBindableButtons.Count = WallhopBindableButtons.Count + 1
        return BindValue
    end

    function WallhopBindableButtons.DeleteBButton(id)
        if WallhopBindableButtons.Maids[id] then
            WallhopBindableButtons.Maids[id]:Destroy()
            WallhopBindableButtons.Maids[id] = nil
        end
        if WallhopBindableButtons.Buttons[id] then
            WallhopBindableButtons.Buttons[id]:Destroy()
            WallhopBindableButtons.Buttons[id] = nil
        end
    end

    UpdateWallhopButtonState = function()
        ODHX.Commit()
        local btn = WallhopBindableButtons.Buttons["wallhop_toggle"]
        if not btn then return end
        local value=btn:FindFirstChild("BindValue")
        if value then value.Value=isWallHopEnabled end
        local textLabel = btn:FindFirstChild("@Text")
        if textLabel then
            textLabel.Text = isWallHopEnabled and "ON" or "OFF"
        end
        local gradient = btn:FindFirstChild("@Stroke")
        if gradient then
            gradient.Color = isWallHopEnabled and __ACTIVE_COLOR or __NORMAL_COLOR
        end
    end

    local showWallhopButton = true

    local function ToggleWallhopButtonVisibility()
        local btn = WallhopBindableButtons.Buttons["wallhop_toggle"]
        if btn then
            btn.Visible = showWallhopButton
        end
    end

    local function CreateWallhopBindButton()
        if WallhopBindableButtons.Buttons["wallhop_toggle"] then return end

        WallhopBindableButtons.AddBButton("wallhop_toggle", "WH", function()
            isWallHopEnabled = true
            shared.Notify("Pm-WallHop enabled", 2)
            UpdateWallhopButtonState()
        end, function()
            isWallHopEnabled = false
            shared.Notify("Pm-WallHop disabled", 2)
            UpdateWallhopButtonState()
        end)

        UpdateWallhopButtonState()
        ToggleWallhopButtonVisibility()
    end

    wallhop_section:AddToggle("📱 Show on-screen button", function(b)
        showWallhopButton = b
        ToggleWallhopButtonVisibility()
    end)

    wallhop_section:AddSlider("🔘 Button size (%)", 5, 25, 11, function(value)
        local btnSize = value / 100
        wallhopButtonSize = btnSize
        local btn = WallhopBindableButtons.Buttons["wallhop_toggle"]
        if btn then
            local screen = workspace.CurrentCamera.ViewportSize
            btn.Size = UDim2.new(btnSize * (screen.Y / screen.X), 0, btnSize, 0)
        end
    end)

    CreateWallhopBindButton()

    local Players = SR_UI.service("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = SR_UI.service("RunService")
    local UserInputService = SR_UI.service("UserInputService")

    local isFlicking = false
    local lastFlickTime = 0
    local isJumpKeyPressed = false
    local Camera = workspace.CurrentCamera
    local wallDetectionCooldown = 0

    local wallRaycastParams = RaycastParams.new()
    wallRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local function isPlayerCharacter(instance)
        if not instance then return false end
        local current = instance
        while current do
            if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
                local players = Players:GetPlayers()
                for _, player in ipairs(players) do
                    if player.Character == current then
                        return true
                    end
                end
            end
            current = current.Parent
        end
        return false
    end

    local function isWall(instance)
        if not instance or not instance.IsA then return false end

        if instance:IsA("Part") and instance.Parent and instance.Parent:IsA("Model") and instance.Parent:FindFirstChild("Humanoid") then
            return false
        end

        local current = instance
        while current do
            if isPlayerCharacter(current) then
                return false
            end
            current = current.Parent
        end

        if not instance:IsA("BasePart") and not instance:IsA("Terrain") then
            return false
        end

        if instance:IsA("BasePart") and not instance.CanCollide then
            return false
        end

        return true
    end

    local function getWallRaycastResult()
        local character = LocalPlayer.Character
        if not character then return nil end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end

        local players = Players:GetPlayers()
        local blacklist = {character}
        for _, player in ipairs(players) do
            if player ~= LocalPlayer and player.Character then
                table.insert(blacklist, player.Character)
            end
        end
        wallRaycastParams.FilterDescendantsInstances = blacklist

        local closestHit, minDistance = nil, detectionDistance
        local hrpCF = hrp.CFrame
        for i = 0,7 do
            local angle = math.rad(i*45)
            local dir = (hrpCF * CFrame.Angles(0, angle, 0)).LookVector
            local ray = workspace:Raycast(hrp.Position, dir * detectionDistance, wallRaycastParams)
            if ray and ray.Instance and ray.Distance < minDistance then
                local hitInstance = ray.Instance
                if isWall(hitInstance) then
                    minDistance = ray.Distance
                    closestHit = ray
                end
            end
        end
        return closestHit
    end

    performVideoFlick = function()
        if not isWallHopEnabled then return end
        if isFlicking then return end
        isFlicking = true

        local char = LocalPlayer.Character
        if not char then isFlicking = false return end

        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then isFlicking = false return end

        if hum.Health <= 0 then isFlicking = false return end

        local currentVel = hrp.Velocity

        hum:ChangeState(Enum.HumanoidStateType.Jumping)
        hrp.Velocity = Vector3.new(currentVel.X, flickPower, currentVel.Z)

        local startCFrame = Camera.CFrame
        Camera.CFrame = startCFrame * CFrame.Angles(0, math.rad(180), 0)

        task.wait(0.01)
        Camera.CFrame = startCFrame

        isFlicking = false
    end

    performWallhop = function()
        if not isWallHopEnabled then return end

        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not (humanoid and rootPart and humanoid:GetState() ~= Enum.HumanoidStateType.Dead) then return end

        local wall = getWallRaycastResult()
        if not wall then return end

        rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + wall.Normal)
        RunService.Heartbeat:Wait()

        if humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(0.1)
        end
    end

    local lastHitInstance = nil
    local currentHitInstance = nil

    local wallhopChar, wallhopHrp, wallhopHum = nil, nil, nil
    local wallhopRayParams = nil
    local wallhopFilter = {}

    ODHX.Connect(RunService.Heartbeat, function()
        if not isWallHopEnabled or isFlicking then return end

        local char = LocalPlayer.Character
        if not char then
            lastHitInstance = nil
            return
        end

        if char ~= wallhopChar then
            wallhopChar, wallhopHrp, wallhopHum = char, nil, nil
        end

        local hrp = wallhopHrp
        if not hrp or hrp.Parent ~= char then
            hrp = char:FindFirstChild("HumanoidRootPart")
            wallhopHrp = hrp
        end
        local hum = wallhopHum
        if not hum or hum.Parent ~= char then
            hum = char:FindFirstChild("Humanoid")
            wallhopHum = hum
        end

        if not hrp or not hum or hum.Health <= 0 then
            lastHitInstance = nil
            return
        end

        if not isJumpKeyPressed then
            lastHitInstance = nil
            return
        end

        local raycastParams = wallhopRayParams
        if not raycastParams then
            raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.IgnoreWater = true
            wallhopRayParams = raycastParams
        end
        wallhopFilter[1] = char
        raycastParams.FilterDescendantsInstances = wallhopFilter

        local direction = Camera.CFrame.LookVector * detectionDistance
        local result = workspace:Raycast(hrp.Position, direction, raycastParams)

        currentHitInstance = nil

        if result then
            local hitInstance = result.Instance

            if isWall(hitInstance) then
                currentHitInstance = hitInstance

                if lastHitInstance and lastHitInstance ~= currentHitInstance then
                    local currentTime = os.clock()
                    if currentTime - lastFlickTime > 0.1 then
                        lastFlickTime = currentTime
                        performVideoFlick()
                    end
                end
            end
        end

        lastHitInstance = currentHitInstance
    end)

    ODHX.Connect(UserInputService.JumpRequest, function()
        if isWallHopEnabled then
            performWallhop()
        end
    end)

    ODHX.Connect(UserInputService.InputBegan, function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.Space then
            isJumpKeyPressed = true
        end
    end)

    ODHX.Connect(UserInputService.InputEnded, function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.Space then
            isJumpKeyPressed = false

            lastHitInstance = nil
        end
    end)

    ODHX.Connect(LocalPlayer.CharacterAdded, function(character)
        lastHitInstance = nil
        currentHitInstance = nil
        isFlicking = false
    end)

    ODHX.Connect(UserInputService.WindowFocused, function()

        isJumpKeyPressed = false
        lastHitInstance = nil
    end)

    ODHX.Bind("Pm-WallHop", "Enable WallHop", "Toggle", function() return isWallHopEnabled end)
    ODHX.Bind("Pm-WallHop", "Detection distance", "Slider", function() return detectionDistance end)
    ODHX.Bind("Pm-WallHop", "Fling power", "Slider", function() return flickPower end)
    ODHX.Bind("Pm-WallHop", "📱 Show on-screen button", "Toggle", function() return showWallhopButton end)
    ODHX.Bind("Pm-WallHop", "🔘 Button size (%)", "Slider", function() return wallhopButtonSize * 100 end)
    ODHX.cleanup=function()
        for id in pairs(WallhopBindableButtons.Buttons) do WallhopBindableButtons.DeleteBButton(id) end
    end
    ODHX.Finish()

    for btnId, btn in pairs(WallhopBindableButtons.Buttons) do SR_Store.posApply("wallhop", btnId, btn) end

end
end)

SR_UI.tryModule("PrismFlux", function()
do
    local ODHX = CreateODHX("PrismFlux", "PrismFlux", "ODH_PrismFlux_settings.json", false, false)
    local RunService       = SR_UI.service("RunService")
    local Players          = SR_UI.service("Players")
    local Lighting         = SR_UI.service("Lighting")
    local UserInputService = SR_UI.service("UserInputService")
    local Debris           = SR_UI.service("Debris")

    local LocalPlayer = Players.LocalPlayer
    local Terrain     = workspace.Terrain

    local IS_PHONE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local QUALITY  = IS_PHONE and 0.55 or 1

    local function q(n, minimum)
    	return math.max(minimum or 1, math.floor(n * QUALITY + 0.5))
    end

    local TEX = {
    	Spark   = "rbxasset://textures/particles/sparkles_main.dds",
    	Smoke   = "rbxasset://textures/particles/smoke_main.dds",
    	Fire    = "rbxasset://textures/particles/fire_main.dds",
    	Ember   = "rbxasset://textures/particles/fire_sparks_main.dds",
    	Core    = "rbxasset://textures/particles/explosion01_core_main.dds",
    	Implode = "rbxasset://textures/particles/explosion01_implosion_main.dds",
    	Shock   = "rbxasset://textures/particles/explosion01_shockwave_main.dds",
    	Puff    = "rbxasset://textures/particles/explosion01_smoke_main.dds",
    	Field   = "rbxasset://textures/particles/forcefield_glow_main.dds",
    	Vortex  = "rbxasset://textures/particles/forcefield_vortex_main.dds",
    	Star    = "rbxassetid://5860841663",
    	Swirl   = "rbxassetid://5857851812",
    	Heart   = "rbxassetid://5857851618",
    	Circle  = "rbxassetid://6711256324",
    	Cloud   = "rbxassetid://5833235272",
    	Glint   = "rbxassetid://5833323391",
    	Scratch = "rbxassetid://5857892405",
    	Trace   = "rbxassetid://5857931724",
    	Ring    = "rbxassetid://1266170131",
    	Ripple  = "rbxassetid://16829556885",
    	Drop    = "rbxassetid://17082061238",
    	Mote    = "rbxassetid://14302399641",
    	Boom    = "rbxassetid://17040521870",
    }

    local TAU   = math.pi * 2
    local WHITE = Color3.new(1, 1, 1)
    local BLACK = Color3.new(0, 0, 0)

    local S = {}
    S.Spin = { Enabled = false, Speed = 0.8, Wobble = true }

    local function lerp(a, b, t) return a + (b - a) * t end
    local function clamp(v, a, b) if v < a then return a elseif v > b then return b end return v end
    local function rnd(a, b) return a + math.random() * (b - a) end
    local RAD = math.rad
    local atan2 = math.atan2 or math.atan
    local function easeOut(t) t = clamp(t, 0, 1) return 1 - (1 - t) ^ 3 end
    local function easeIn(t)  t = clamp(t, 0, 1) return t * t * t end
    local function easeInOut(t) t = clamp(t, 0, 1) return t < 0.5 and 4 * t * t * t or 1 - (-2 * t + 2) ^ 3 / 2 end
    local function pulse01(t) return 0.5 + 0.5 * math.sin(t) end
    local function pick(list) return list[math.random(#list)] end

    local function tint(c, k)
    	if k >= 0 then return c:Lerp(WHITE, math.min(k, 1)) end
    	return c:Lerp(BLACK, math.min(-k, 1))
    end

    local function organicNoise(t, seed)
    	local s = (seed or 0) * 1.618
    	return 0.62 * math.sin(t * 1.13 + s)
    		+ 0.26 * math.sin(t * 2.71 + s * 2.3) * math.sin(t * 0.37 + s * 0.7)
    		+ 0.12 * math.sin(t * 5.53 + s * 4.1)
    end

    local function cseq(...)
    	local list = { ... }
    	if #list == 1 and typeof(list[1]) == "ColorSequence" then return list[1] end
    	if type(list[1]) == "table" then list = list[1] end
    	for i = 1, #list do
    		if typeof(list[i]) == "ColorSequence" then list[i] = list[i].Keypoints[1].Value end
    	end
    	local n = #list
    	if n == 0 then return ColorSequence.new(WHITE) end
    	if n == 1 then return ColorSequence.new(list[1]) end
    	local keys = {}
    	for i = 1, n do keys[i] = ColorSequenceKeypoint.new((i - 1) / (n - 1), list[i]) end
    	return ColorSequence.new(keys)
    end
    local function nseq(...)
    	local list = { ... }
    	if type(list[1]) == "table" then list = list[1] end
    	local n = #list
    	if n == 0 then return NumberSequence.new(0) end
    	if n == 1 then return NumberSequence.new(list[1]) end
    	local keys = {}
    	for i = 1, n do keys[i] = NumberSequenceKeypoint.new((i - 1) / (n - 1), list[i]) end
    	return NumberSequence.new(keys)
    end
    local function range(a, b) return NumberRange.new(a, b or a) end

    local function makePalette(cfg, hue)
    	local bright, base, deep
    	if hue then
    		bright = Color3.fromHSV(hue % 1, 0.3, 1)
    		base   = Color3.fromHSV(hue % 1, 0.95, 1)
    		deep   = Color3.fromHSV((hue + 0.06) % 1, 1, 0.45)
    	elseif cfg.Palette then
    		bright, base, deep = cfg.Palette[1], cfg.Palette[2], cfg.Palette[3]
    	else
    		base   = cfg.Color or WHITE
    		bright = tint(base, 0.55)
    		deep   = tint(base, -0.5)
    	end
    	local p = { bright = bright, base = base, deep = deep }
    	p.seq      = cseq(bright, base, deep)
    	p.seqUp    = cseq(deep, base, bright)
    	p.seqHot   = cseq(WHITE, bright, base)
    	p.seqFade  = cseq(base, deep)
    	p.seqDark  = cseq(deep, BLACK)
    	p.seqGlass = cseq(WHITE, bright)
    	p.seqPulse = cseq(base, bright, base)
    	p.flat     = ColorSequence.new(base)
    	return p
    end

    local function hueShiftColor(c, dh)
    	local h, sat, val = c:ToHSV()
    	if sat < 0.05 then return c end
    	return Color3.fromHSV((h + dh) % 1, sat, val)
    end
    local function hueShiftSeq(seq, dh)
    	local keys = {}
    	for i, kp in ipairs(seq.Keypoints) do
    		keys[i] = ColorSequenceKeypoint.new(kp.Time, hueShiftColor(kp.Value, dh))
    	end
    	return ColorSequence.new(keys)
    end
    local function baseHue(cfg)
    	local c = (cfg.Palette and cfg.Palette[2]) or cfg.Color or WHITE
    	local h = c:ToHSV()
    	return h
    end
    local function deepCopy(v)
    	if typeof(v) ~= "table" then return v end
    	local t = {}
    	for k, x in pairs(v) do t[k] = deepCopy(x) end
    	return t
    end

    local fxFolder
    local function folder()
    	if fxFolder and fxFolder.Parent then return fxFolder end
    	fxFolder = Instance.new("Folder")
    	fxFolder.Name = "PrismFlux_FX"
    	fxFolder.Parent = workspace
    	return fxFolder
    end
    folder()

    local function attach(parent, cf, name)
    	local a = Instance.new("Attachment")
    	a.Name = name or "PF"
    	if typeof(cf) == "CFrame" then a.CFrame = cf
    	elseif typeof(cf) == "Vector3" then a.Position = cf end
    	a.Parent = parent
    	return a
    end

    local function worldAttach(cf, name)
    	local a = Instance.new("Attachment")
    	a.Name = name or "PF_World"
    	a.CFrame = cf
    	a.Parent = Terrain
    	return a
    end

    local warnedProps = {}
    local function applyProps(inst, props)
    	if not props then return end
    	for k, v in pairs(props) do
    		if k ~= "Parent" then

    			if k == "Color" and typeof(v) == "Color3"
    				and (inst:IsA("ParticleEmitter") or inst:IsA("Beam") or inst:IsA("Trail")) then
    				v = ColorSequence.new(v)
    			end
    			local ok, err = pcall(function() inst[k] = v end)
    			if not ok and not warnedProps[k] then
    				warnedProps[k] = true
    				warn("[PrismFlux] " .. inst.ClassName .. "." .. tostring(k) .. ": " .. tostring(err))
    			end
    		end
    	end
    end

    local function beam(a0, a1, props)
    	local b = Instance.new("Beam")
    	b.Attachment0    = a0
    	b.Attachment1    = a1
    	b.LightEmission  = 1
    	b.LightInfluence = 0
    	b.FaceCamera     = false
    	b.Segments       = 10
    	b.Width0         = 0.3
    	b.Width1         = 0.3
    	b.CurveSize0     = 0
    	b.CurveSize1     = 0
    	b.Transparency   = NumberSequence.new(0)
    	b.Texture        = ""
    	b.TextureMode    = Enum.TextureMode.Stretch
    	b.TextureLength  = 1
    	b.TextureSpeed   = 0
    	applyProps(b, props)
    	b.Parent = (props and props.Parent) or a0
    	return b
    end

    local function emitter(parent, props)
    	local e = Instance.new("ParticleEmitter")
    	e.Enabled           = false
    	e.Rate              = 0
    	e.LightEmission     = 1
    	e.LightInfluence    = 0
    	e.Texture           = TEX.Spark
    	e.Speed             = range(0)
    	e.Lifetime          = range(1)
    	e.Rotation          = range(0, 360)
    	e.RotSpeed          = range(-40, 40)
    	e.SpreadAngle       = Vector2.new(0, 0)
    	e.Drag              = 0
    	e.Acceleration      = Vector3.new(0, 0, 0)
    	e.EmissionDirection = Enum.NormalId.Top
    	e.Size              = nseq(0.3)
    	e.Transparency      = nseq(0, 1)
    	applyProps(e, props)
    	e.Parent = parent
    	return e
    end

    local function light(parent, color, rng, brightness)
    	local l = Instance.new("PointLight")
    	l.Color      = color
    	l.Range      = rng or 10
    	l.Brightness = brightness or 2
    	l.Shadows    = false
    	l.Parent     = parent
    	return l
    end

    local function trail(a0, a1, props)
    	local t = Instance.new("Trail")
    	t.Attachment0    = a0
    	t.Attachment1    = a1
    	t.LightEmission  = 1
    	t.LightInfluence = 0
    	t.FaceCamera     = false
    	t.Lifetime       = 0.5
    	t.MinLength      = 0.05
    	t.Transparency   = nseq(0.1, 1)
    	t.WidthScale     = nseq(1, 0)
    	t.Texture        = ""
    	applyProps(t, props)
    	t.Parent = (props and props.Parent) or a0
    	return t
    end

    local Session = { id = 0 }
    local function later(t, fn)
    	local id = Session.id
    	task.delay(t, function()
    		if Session.id == id then fn() end
    	end)
    end

    local Timeline = { list = {}, conn = nil }
    function Timeline.add(duration, update, finish)
    	local item = { t = 0, d = math.max(duration, 0.05), update = update, finish = finish }
    	table.insert(Timeline.list, item)
    	if not Timeline.conn then
    		Timeline.conn = RunService.Heartbeat:Connect(function(dt)
    			local list = Timeline.list
    			for i = #list, 1, -1 do
    				local it = list[i]
    				it.t = it.t + dt
    				local alpha = math.min(it.t / it.d, 1)
    				local ok = pcall(it.update, alpha, dt, it.t)
    				if (not ok) or alpha >= 1 then
    					table.remove(list, i)
    					if it.finish then pcall(it.finish) end
    				end
    			end
    			if #list == 0 and Timeline.conn then
    				Timeline.conn:Disconnect()
    				Timeline.conn = nil
    			end
    		end)
    	end
    	return item
    end

    local function frameX(pos, x)
    	x = x.Unit
    	local helper = (math.abs(x:Dot(Vector3.yAxis)) > 0.92) and Vector3.zAxis or Vector3.yAxis
    	local z = x:Cross(helper).Unit
    	local y = z:Cross(x)
    	return CFrame.fromMatrix(pos, x, y, z)
    end

    local function makeLoop(parent, centerCF, radius, opts)
    	opts = opts or {}
    	local N = math.max(2, opts.N or 4)
    	local span = clamp(opts.Span or 1, 0.05, 1)
    	local closed = span >= 0.999
    	local M = closed and N or N + 1
    	local loop = { atts = {}, beams = {}, center = centerCF, N = N, M = M, span = span }
    	for i = 1, M do loop.atts[i] = attach(parent, CFrame.new(), opts.Name or "PF_Loop") end
    	for i = 1, N do
    		local a1 = loop.atts[closed and (i % N + 1) or (i + 1)]
    		loop.beams[i] = beam(loop.atts[i], a1, {
    			Segments      = opts.Segments or 12,
    			Color         = opts.Color or ColorSequence.new(WHITE),
    			Transparency  = NumberSequence.new(opts.Alpha or 0),
    			Texture       = opts.Texture or "",
    			TextureMode   = Enum.TextureMode.Wrap,
    			TextureLength = opts.TextureLength or 1,
    			TextureSpeed  = opts.TextureSpeed or 0,
    			ZOffset       = opts.ZOffset or 0,
    			LightEmission = opts.LightEmission or 1,
    		})
    	end
    	function loop:set(r, width, alpha, spin)
    		local step = self.span * TAU / self.N
    		local k = (4 / 3) * math.tan(step / 4) * r
    		spin = spin or 0
    		for i = 1, self.M do
    			local th = spin + (i - 1) * step
    			local c, s = math.cos(th), math.sin(th)
    			local tangent = Vector3.new(-s, 0, c)
    			local radial  = Vector3.new(c, 0, s)
    			self.atts[i].CFrame = self.center * CFrame.fromMatrix(Vector3.new(c * r, 0, s * r), tangent, radial, Vector3.yAxis)
    		end
    		for _, b in ipairs(self.beams) do
    			b.CurveSize0 = k
    			b.CurveSize1 = k
    			b.Width0 = width
    			b.Width1 = width
    			if alpha then b.Transparency = NumberSequence.new(alpha) end
    		end
    	end
    	function loop:color(seq) for _, b in ipairs(self.beams) do b.Color = seq end end
    	function loop:alpha(a) for _, b in ipairs(self.beams) do b.Transparency = NumberSequence.new(a) end end
    	function loop:destroy() for _, a in ipairs(self.atts) do a:Destroy() end end
    	loop:set(radius, opts.Width or 0.3, nil, 0)
    	return loop
    end

    local function makeShell(parent, opts)
    	opts = opts or {}
    	local N = q(opts.Panels or 12, 6)
    	local shell = { top = {}, bot = {}, beams = {}, N = N }
    	for i = 1, N do
    		shell.top[i] = attach(parent, CFrame.new(), "PF_ShellT")
    		shell.bot[i] = attach(parent, CFrame.new(), "PF_ShellB")
    		shell.beams[i] = beam(shell.top[i], shell.bot[i], {
    			Segments      = opts.Segments or 5,
    			Color         = opts.Color or ColorSequence.new(WHITE),
    			Transparency  = opts.Transparency or nseq(0.1, 0.2),
    			Texture       = opts.Texture or "",
    			TextureMode   = opts.Texture and Enum.TextureMode.Wrap or Enum.TextureMode.Stretch,
    			TextureLength = opts.TextureLength or 1,
    			TextureSpeed  = opts.TextureSpeed or 0,
    			LightEmission = opts.LightEmission or 0.85,
    			ZOffset       = opts.ZOffset or 0,
    		})
    	end
    	function shell:set(center, rTop, rBot, height, bulge, spin)
    		bulge = bulge or 0
    		spin = spin or 0
    		local chordT = math.max(0.06, TAU * rTop / self.N * 1.08)
    		local chordB = math.max(0.06, TAU * rBot / self.N * 1.08)
    		local dr = rBot - rTop
    		local L = math.sqrt(dr * dr + height * height)
    		local slope = atan2(height, dr)
    		for i = 1, self.N do
    			local th = spin + (i - 0.5) / self.N * TAU
    			local c, s = math.cos(th), math.sin(th)
    			local function dirAt(phi) return Vector3.new(math.cos(phi) * c, -math.sin(phi), math.cos(phi) * s) end
    			local tangent = Vector3.new(-s, 0, c)
    			local dT, dB = dirAt(slope - bulge), dirAt(slope + bulge)
    			self.top[i].CFrame = center * CFrame.fromMatrix(Vector3.new(c * rTop, height, s * rTop), dT, tangent, dT:Cross(tangent))
    			self.bot[i].CFrame = center * CFrame.fromMatrix(Vector3.new(c * rBot, 0, s * rBot), dB, tangent, dB:Cross(tangent))
    			local b = self.beams[i]
    			b.Width0 = chordT
    			b.Width1 = chordB
    			b.CurveSize0 = L * 0.35
    			b.CurveSize1 = L * 0.35
    		end
    	end
    	function shell:color(seq) for _, b in ipairs(self.beams) do b.Color = seq end end
    	function shell:alpha(a) for _, b in ipairs(self.beams) do b.Transparency = NumberSequence.new(a) end end
    	function shell:destroy()
    		for i = 1, self.N do self.top[i]:Destroy() self.bot[i]:Destroy() end
    	end
    	return shell
    end

    local function plumeDir(side, spread, sweep)
    	return Vector3.new(side * math.cos(spread) * math.cos(sweep), math.sin(spread), math.cos(spread) * math.sin(sweep))
    end
    local function makePlume(parent, spec)
    	local root = attach(parent, CFrame.new(spec.origin), "PF_PlumeRoot")
    	local tip  = attach(parent, CFrame.new(spec.origin), "PF_PlumeTip")
    	local alpha = spec.alpha or 0.05
    	local b = beam(root, tip, {
    		FaceCamera    = true,
    		Segments      = spec.segments or 8,
    		LightEmission = spec.emission or 1,
    		Width0        = spec.w0,
    		Width1        = spec.w1,
    		Texture       = spec.texture or "",
    		TextureMode   = Enum.TextureMode.Stretch,
    		TextureLength = 1,
    		TextureSpeed  = spec.texSpeed or 0,
    		Transparency  = spec.transparency or nseq(alpha, alpha + 0.1, math.min(alpha + 0.75, 1)),
    		ZOffset       = spec.z or 0,
    	})
    	local f = { root = root, tip = tip, beam = b, spec = spec }
    	function f:pose(flap, droop, jitter)
    		local s = self.spec
    		local sp = s.spread + (flap or 0) - (droop or 0)
    		local bend = s.bend + (jitter or 0)
    		local dir   = plumeDir(s.side, sp, s.sweep)
    		local dRoot = plumeDir(s.side, sp + bend, s.sweep)
    		local dTip  = plumeDir(s.side, sp - bend, s.sweep)
    		self.root.CFrame = frameX(s.origin, dRoot)
    		self.tip.CFrame  = frameX(s.origin + dir * s.len, dTip)
    		self.beam.CurveSize0 = s.len * (s.curve or 0.3)
    		self.beam.CurveSize1 = s.len * (s.curve or 0.3)
    	end
    	function f:destroy() self.root:Destroy() self.tip:Destroy() end
    	f:pose(0, 0, 0)
    	return f
    end

    local function makeBolt(parent, opts)
    	opts = opts or {}
    	local K = q(opts.K or 6, 3)
    	local bolt = { atts = {}, beams = {}, K = K }
    	for i = 1, K + 1 do bolt.atts[i] = attach(parent, CFrame.new(), "PF_Bolt") end
    	for i = 1, K do
    		bolt.beams[i] = beam(bolt.atts[i], bolt.atts[i + 1], {
    			FaceCamera = true, Segments = 1,
    			Width0 = opts.Width or 0.12, Width1 = opts.Width or 0.12,
    			Color = opts.Color or ColorSequence.new(WHITE),
    			Transparency = NumberSequence.new(opts.Alpha or 0),
    			ZOffset = opts.ZOffset or 0,
    		})
    	end
    	function bolt:set(p0, p1, jitter, seed)
    		local d = p1 - p0
    		local L = d.Magnitude
    		local u = (L > 1e-4) and (d / L) or Vector3.yAxis
    		local side = u:Cross(Vector3.yAxis)
    		if side.Magnitude < 0.01 then side = u:Cross(Vector3.xAxis) end
    		side = side.Unit
    		local up = side:Cross(u)
    		seed = seed or 0
    		for i = 1, self.K + 1 do
    			local t = (i - 1) / self.K
    			local amp = (i == 1 or i == self.K + 1) and 0 or (jitter or 0.5) * math.sin(t * math.pi)
    			local n = math.sin(seed * 7.1 + i * 3.3) * amp
    			local m = math.cos(seed * 5.7 + i * 2.1) * amp
    			self.atts[i].CFrame = CFrame.new(p0 + u * (L * t) + side * n + up * m)
    		end
    	end
    	function bolt:alpha(a) for _, b in ipairs(self.beams) do b.Transparency = NumberSequence.new(a) end end
    	function bolt:color(seq) for _, b in ipairs(self.beams) do b.Color = seq end end
    	function bolt:destroy() for _, a in ipairs(self.atts) do a:Destroy() end end
    	return bolt
    end

    local function groundAt(pos, ignore, fallback)
    	local params = RaycastParams.new()
    	if not pcall(function() params.FilterType = Enum.RaycastFilterType.Exclude end) then
    		pcall(function() params.FilterType = Enum.RaycastFilterType.Blacklist end)
    	end
    	local list = { folder() }
    	if ignore then table.insert(list, ignore) end
    	params.FilterDescendantsInstances = list
    	local okR, hit = pcall(workspace.Raycast, workspace, pos, Vector3.new(0, -16, 0), params)
    	if okR and hit then return CFrame.new(hit.Position + Vector3.new(0, 0.08, 0)) end
    	return CFrame.new(pos - Vector3.new(0, fallback or 3, 0))
    end

    local function velocityOf(part)
    	local ok, v = pcall(function() return part.AssemblyLinearVelocity end)
    	if ok and v then return v end
    	local ok2, v2 = pcall(function() return part.Velocity end)
    	return (ok2 and v2) or Vector3.zero
    end

    local function withDelay(o, go)
    	if o.Delay and o.Delay > 0 then later(o.Delay, go) else go() end
    end

    local function ringWave(cf, o)
    	withDelay(o, function()
    		local pose = CFrame.Angles(o.Tilt or 0, o.Yaw or 0, o.Roll or 0)
    		local loop = makeLoop(Terrain, cf * pose, o.R0, {
    			Color = o.Color, Width = o.W0, Alpha = o.A0 or 0, Span = o.Span, N = o.N,
    			Texture = o.Texture, TextureLength = o.TextureLength, TextureSpeed = o.TextureSpeed, Segments = o.Segments,
    		})
    		local a0 = o.A0 or 0
    		Timeline.add(o.Dur, function(a)
    			local e = o.Linear and a or easeOut(a)
    			loop.center = cf * CFrame.new(0, (o.Rise or 0) * e - (o.Sink or 0) * e, 0) * pose
    			loop:set(lerp(o.R0, o.R1, e), lerp(o.W0, o.W1 or o.W0, e), lerp(a0, 1, a * a), (o.Spin or 0) * e + (o.Phase or 0))
    		end, function() loop:destroy() end)
    	end)
    end

    local function arcSpray(cf, o)
    	withDelay(o, function()
    		local N = q(o.N or 6, 3)
    		local made = {}
    		for i = 1, N do
    			local th = (i - 1) / N * TAU + (o.Offset or 0)
    			local loop = makeLoop(Terrain, cf, o.R0 or 0.3, { Color = o.Color, Width = o.W or 0.15, Alpha = o.A0 or 0, Span = o.Span or 0.18, N = 2, Segments = 8 })
    			made[i] = { loop = loop, th = th }
    		end
    		Timeline.add(o.Dur, function(a)
    			local e = easeOut(a)
    			local r = lerp(o.R0 or 0.3, o.R1 or 4, e)
    			local tilt = (o.Tilt0 or 0) + ((o.Tilt1 or RAD(70)) - (o.Tilt0 or 0)) * e
    			for _, m in ipairs(made) do
    				m.loop.center = cf * CFrame.Angles(0, m.th + (o.Spin or 0) * e, 0) * CFrame.new(0, (o.Rise or 0) * e, 0) * CFrame.Angles(tilt, 0, 0)
    				m.loop:set(r, (o.W or 0.15) * (1 - a * 0.6), (o.A0 or 0) + a * a * (1 - (o.A0 or 0)), -math.pi * (o.Span or 0.18))
    			end
    		end, function() for _, m in ipairs(made) do m.loop:destroy() end end)
    	end)
    end

    local function column(cf, o)
    	withDelay(o, function()
    		local strips = {}
    		local n = (o.Twist and o.Twist > 0) and 2 or 1
    		for i = 1, n do
    			local a0 = worldAttach(cf)
    			local a1 = worldAttach(cf * CFrame.new(0, 0.1, 0))
    			local b = beam(a0, a1, {
    				FaceCamera = true, Segments = n == 2 and 12 or 1,
    				Width0 = o.W0 or 1, Width1 = o.W1 or 0.2,
    				Color = o.Color, Texture = o.Texture or "",
    				TextureMode = Enum.TextureMode.Wrap, TextureLength = o.TextureLength or 2, TextureSpeed = o.Speed or 0,
    				Transparency = nseq(o.A0 or 0, 1),
    			})
    			strips[i] = { a0 = a0, a1 = a1, b = b, sign = (i == 1) and 1 or -1 }
    		end
    		Timeline.add(o.Dur, function(a)
    			local e = easeOut(a)
    			local h = 0.1 + (o.H or 8) * e
    			for _, s in ipairs(strips) do
    				if n == 2 then
    					local sw = o.Twist * s.sign
    					s.a0.CFrame = cf * CFrame.new(sw, 0, 0)
    					s.a1.CFrame = cf * CFrame.new(-sw, h, 0)
    					s.b.CurveSize0 = sw * 4
    					s.b.CurveSize1 = -sw * 4
    				else
    					s.a1.CFrame = cf * CFrame.new(0, h, 0)
    				end
    				s.b.Transparency = nseq(lerp(o.A0 or 0, 1, a * a), 1)
    				s.b.Width0 = (o.W0 or 1) * (1 - a * 0.6)
    			end
    		end, function() for _, s in ipairs(strips) do s.a0:Destroy() s.a1:Destroy() end end)
    	end)
    end

    local function spokes(cf, o)
    	withDelay(o, function()
    		local N = q(o.N or 8, 4)
    		local made = {}
    		for i = 1, N do
    			local th = (i - 1) / N * TAU + (o.Offset or 0)
    			local dir = CFrame.Angles(0, th, 0) * CFrame.Angles(o.Elev or 0, 0, 0)
    			local a0 = worldAttach(cf * dir * CFrame.new(0, 0, -0.4))
    			local a1 = worldAttach(cf * dir * CFrame.new(0, 0, -0.6))
    			local b = beam(a0, a1, { FaceCamera = true, Segments = 1, Width0 = o.W or 0.5, Width1 = 0.03, Color = o.Color, Transparency = nseq(0, 0.7) })
    			made[i] = { a0 = a0, a1 = a1, b = b, dir = dir }
    		end
    		Timeline.add(o.Dur, function(a)
    			local e = easeOut(a)
    			local L = o.L or 5
    			for _, m in ipairs(made) do
    				m.a1.CFrame = cf * m.dir * CFrame.new(0, 0, -(0.6 + L * e))
    				m.a0.CFrame = cf * m.dir * CFrame.new(0, 0, -(0.4 + L * e * (o.Hollow or 0.55)))
    				m.b.Transparency = nseq(a * a, 1)
    			end
    		end, function() for _, m in ipairs(made) do m.a0:Destroy() m.a1:Destroy() end end)
    	end)
    end

    local function shards(cf, o)
    	withDelay(o, function()
    		local N = q(o.N or 10, 4)
    		local made = {}
    		for i = 1, N do
    			local th = (i - 0.5) / N * TAU + rnd(-0.2, 0.2)
    			local elev = (o.Up or 0.6) + rnd(-0.3, 0.3)
    			local spd = (o.Speed or 10) * rnd(0.6, 1.2)
    			local v = Vector3.new(math.cos(th) * math.cos(elev), math.sin(elev), math.sin(th) * math.cos(elev)) * spd
    			if o.Down then v = Vector3.new(v.X, -math.abs(v.Y), v.Z) end
    			local a0 = worldAttach(cf)
    			local a1 = worldAttach(cf)
    			local b = beam(a0, a1, { FaceCamera = true, Segments = 1, Width0 = o.W or 0.25, Width1 = (o.W or 0.25) * 0.4, Color = o.Color, Transparency = nseq(o.A0 or 0, 0.3) })
    			made[i] = { a0 = a0, a1 = a1, b = b, v = v, p = cf.Position + Vector3.new(0, o.Y or 0.5, 0), spin = rnd(-6, 6) }
    		end
    		local g = o.Gravity or -20
    		local len = o.Len or 0.9
    		Timeline.add(o.Dur, function(a, dt)
    			for _, m in ipairs(made) do
    				m.v = Vector3.new(m.v.X, m.v.Y + g * dt, m.v.Z) * (1 - (o.Drag or 0.6) * dt)
    				m.p = m.p + m.v * dt
    				local dir = m.v.Magnitude > 0.1 and m.v.Unit or Vector3.yAxis
    				local half = dir * (len * 0.5 * (1 - a * 0.5))
    				m.a0.CFrame = CFrame.new(m.p - half)
    				m.a1.CFrame = CFrame.new(m.p + half)
    				m.b.Transparency = nseq((o.A0 or 0) + a * a, 0.3 + a * 0.7)
    			end
    		end, function() for _, m in ipairs(made) do m.a0:Destroy() m.a1:Destroy() end end)
    	end)
    end

    local function helixRibbon(cf, o)
    	withDelay(o, function()
    		local K = q(o.K or 14, 8)
    		local atts, beams = {}, {}
    		for i = 1, K + 1 do atts[i] = worldAttach(cf) end
    		for i = 1, K do
    			beams[i] = beam(atts[i], atts[i + 1], { FaceCamera = true, Segments = 2, Width0 = o.W or 0.3, Width1 = o.W or 0.3, Color = o.Color, Texture = o.Texture or "", TextureMode = Enum.TextureMode.Wrap, TextureLength = 1, TextureSpeed = o.Speed or 0, Transparency = nseq(o.A0 or 0) })
    		end
    		local turns = o.Turns or 2
    		local dir = o.Dir or 1
    		Timeline.add(o.Dur, function(a)
    			local e = easeOut(a)
    			local H = (o.H or 6) * e
    			local R = lerp(o.R0 or 2, o.R1 or 0.4, e)
    			for i = 1, K + 1 do
    				local u = (i - 1) / K
    				local th = dir * (u * turns * TAU + (o.Spin or 3) * e)
    				atts[i].CFrame = cf * CFrame.new(math.cos(th) * R * (1 - u * (o.Taper or 0.5)), u * H + (o.Lift or 0) * e, math.sin(th) * R * (1 - u * (o.Taper or 0.5)))
    			end
    			for _, b in ipairs(beams) do b.Transparency = nseq((o.A0 or 0) + a * a * (1 - (o.A0 or 0))) end
    		end, function() for _, a in ipairs(atts) do a:Destroy() end end)
    	end)
    end

    local function domeBurst(cf, o)
    	withDelay(o, function()
    		local shell = makeShell(Terrain, { Panels = o.Panels or 10, Color = o.Color, Transparency = nseq(o.A0 or 0.2, o.A0 or 0.2), Segments = 6 })
    		local sign = o.Down and -1 or 1
    		Timeline.add(o.Dur, function(a)
    			local e = easeOut(a)
    			local r = lerp(o.R0 or 0.3, o.R1 or 5, e)
    			shell:set(cf, r * 0.25, r, sign * r * (o.Height or 0.8), (o.Bulge or 0.5), (o.Spin or 0) * e)
    			shell:alpha(lerp(o.A0 or 0.2, 1, a * a))
    		end, function() shell:destroy() end)
    	end)
    end

    local function skyBolt(cf, o)
    	withDelay(o, function()
    		local top = cf.Position + Vector3.new(rnd(-2, 2), o.H or 40, rnd(-2, 2))
    		local b = makeBolt(Terrain, { K = o.K or 9, Width = o.W or 0.35, Color = o.Color })
    		b:set(top, cf.Position, o.Jitter or 2.5, math.random() * 10)
    		local branches = {}
    		for i = 1, q(o.Branches or 2, 1) do
    			local mid = top:Lerp(cf.Position, rnd(0.3, 0.7))
    			local br = makeBolt(Terrain, { K = 4, Width = (o.W or 0.35) * 0.5, Color = o.Color })
    			br:set(mid, mid + Vector3.new(rnd(-5, 5), -rnd(3, 8), rnd(-5, 5)), 1.5, i)
    			branches[i] = br
    		end
    		local l = light(b.atts[b.K + 1], (o.LightColor or WHITE), 24, 10)
    		Timeline.add(o.Dur or 0.35, function(a, dt, t)
    			local flick = (math.sin(t * 90) > 0) and 0 or 0.5
    			b:alpha(math.min(1, flick + a * a))
    			for _, br in ipairs(branches) do br:alpha(math.min(1, 0.2 + flick + a)) end
    			if math.floor(t * 30) % 2 == 0 then b:set(top, cf.Position, o.Jitter or 2.5, t * 13) end
    			l.Brightness = 10 * (1 - a)
    		end, function()
    			b:destroy()
    			for _, br in ipairs(branches) do br:destroy() end
    		end)
    	end)
    end

    local function scatter(cf, count, colorSeq, o)
    	o = o or {}
    	local life = o.life or 0.8
    	local size = o.size or 0.35
    	local a = worldAttach(cf * CFrame.new(0, o.y or 0.3, 0))
    	local e = emitter(a, {
    		Texture = o.tex or TEX.Spark, Color = colorSeq,
    		Size = nseq(size, size * 0.5, 0), Transparency = nseq(o.a0 or 0, 0.2, 1),
    		Lifetime = range(life * 0.6, life), Speed = range((o.speed or 8) * 0.5, o.speed or 8),
    		SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, o.gravity or -14, 0),
    		Drag = o.drag or 2, LightEmission = o.emission or 1, RotSpeed = range(-120, 120),
    		WindAffectsDrag = o.wind or false,
    	})
    	if o.streak then e.Orientation = Enum.ParticleOrientation.VelocityParallel e.Squash = nseq(-2, -0.4, 0) e.RotSpeed = range(0) e.Rotation = range(0) end
    	e:Emit(q(count, 4))
    	Debris:AddItem(a, life + 0.4)
    end

    local function fan(cf, count, colorSeq, o)
    	o = o or {}
    	local k = q(o.k or 6, 4)
    	local per = math.max(1, math.floor(q(count, 4) / k + 0.5))
    	local life = o.life or 0.8
    	local size = o.size or 0.35
    	for i = 1, k do
    		local th = (i - 0.5) / k * TAU + (o.offset or 0)
    		local acf = cf * CFrame.Angles(0, th, 0) * CFrame.new(0, o.y or 0.15, -(o.r or 0.4))
    		if o.inward then acf = acf * CFrame.Angles(0, math.pi, 0) end
    		acf = acf * CFrame.Angles(-math.pi / 2 + (o.up or 0.25), 0, 0)
    		local a = worldAttach(acf)
    		local e = emitter(a, {
    			Texture = o.tex or TEX.Spark, Color = colorSeq,
    			Size = nseq(size, size * 0.6, 0), Transparency = nseq(o.a0 or 0, 0.15, 1),
    			Lifetime = range(life * 0.6, life), Speed = range((o.speed or 8) * 0.6, o.speed or 8),
    			SpreadAngle = Vector2.new(o.spread or 28, o.spread or 28), Acceleration = Vector3.new(0, o.gravity or -10, 0),
    			Drag = o.drag or 2, LightEmission = o.emission or 1, RotSpeed = range(-90, 90),
    		})
    		if o.streak then e.Orientation = Enum.ParticleOrientation.VelocityParallel e.Squash = nseq(-2, -0.4, 0) e.RotSpeed = range(0) e.Rotation = range(0) end
    		e:Emit(per)
    		Debris:AddItem(a, life + 0.4)
    	end
    end

    local function plate(cf, colorSeq, o)
    	o = o or {}
    	local life = o.life or 0.6
    	local a = worldAttach(cf * CFrame.new(0, 0.15, 0))
    	local e = emitter(a, {
    		Texture = o.tex or TEX.Smoke, Color = colorSeq,
    		Size = nseq(math.min(o.s0 or 1, 10), math.min(o.s1 or 6, 10)), Transparency = nseq(o.a0 or 0.3, 1),
    		Lifetime = range(life), Speed = range(0.05), EmissionDirection = Enum.NormalId.Bottom,
    		Orientation = Enum.ParticleOrientation.VelocityPerpendicular, Rotation = range(0, 360), RotSpeed = range(o.rot or 0),
    		LightEmission = o.emission or 1, ZOffset = o.z or 0.03,
    	})
    	e:Emit(o.count or 1)
    	Debris:AddItem(a, life + 0.3)
    end

    local function geyser(cf, count, colorSeq, o)
    	o = o or {}
    	local life = o.life or 1
    	local size = o.size or 0.4
    	local a = worldAttach(cf * CFrame.new(0, o.y or 0.2, 0))
    	local e = emitter(a, {
    		Texture = o.tex or TEX.Spark, Color = colorSeq,
    		Size = nseq(size, size * 1.2, 0), Transparency = nseq(o.a0 or 0, 0.1, 1),
    		Lifetime = range(life * 0.5, life), Speed = range((o.speed or 10) * 0.5, o.speed or 10),
    		SpreadAngle = Vector2.new(o.spread or 20, o.spread or 20), Acceleration = Vector3.new(0, o.gravity or -6, 0),
    		Drag = o.drag or 1, LightEmission = o.emission or 1, RotSpeed = range(-60, 60),
    	})
    	if o.streak then e.Orientation = Enum.ParticleOrientation.VelocityParallel e.Squash = nseq(-2.5, -0.5, 0) e.RotSpeed = range(0) e.Rotation = range(0) end
    	e:Emit(q(count, 4))
    	Debris:AddItem(a, life + 0.4)
    end

    local function glint(cf, color, rng, brightness, dur)
    	local a = worldAttach(cf * CFrame.new(0, 1, 0))
    	local l = light(a, color, rng, brightness)
    	Timeline.add(dur, function(al)
    		l.Brightness = brightness * (1 - al)
    		l.Range = rng * (1 + al * 0.6)
    	end, function() a:Destroy() end)
    end

    local function outlinePulse(model, fill, outline, dur, o)
    	if not model then return end
    	o = o or {}
    	local okH, h = pcall(Instance.new, "Highlight")
    	if not okH then return end
    	h.Adornee = model
    	h.FillColor = fill
    	h.OutlineColor = outline
    	h.FillTransparency = o.fill or 0.3
    	h.OutlineTransparency = o.outline or 0
    	pcall(function() h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end)
    	h.Parent = folder()
    	local f0, o0 = o.fill or 0.3, o.outline or 0
    	Timeline.add(dur, function(a)
    		h.FillTransparency = lerp(f0, 1, a)
    		h.OutlineTransparency = lerp(o0, 1, a * a)
    	end, function() h:Destroy() end)
    end

    local function shockSprite(cf, o)
    	o = o or {}
    	local life = o.life or 0.6
    	local a = worldAttach(cf * CFrame.new(0, o.y or 0.12, 0))
    	local e = emitter(a, {
    		Texture = o.tex or TEX.Shock, Color = o.color or ColorSequence.new(WHITE),
    		Size = o.sizeSeq or nseq(o.s0 or 0.5, o.s1 or 8, (o.s1 or 8) * 1.05),
    		Transparency = o.alphaSeq or nseq(o.a0 or 0, (o.a0 or 0) + 0.3, 1),
    		Lifetime = range(life), Speed = range(0.01), EmissionDirection = Enum.NormalId.Top,
    		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
    		Rotation = range(o.rot0 or 0, o.rot1 or 360), RotSpeed = range(o.rotSpeed or 0),
    		LightEmission = o.emission or 1, ZOffset = o.z or 0.05,
    	})
    	e:Emit(o.count or 1)
    	Debris:AddItem(a, life + 0.3)
    end

    local function flashSprite(cf, o)
    	o = o or {}
    	local life = o.life or 0.35
    	local a = worldAttach(cf * CFrame.new(0, o.y or 1, 0))
    	local e = emitter(a, {
    		Texture = o.tex or TEX.Glint, Color = o.color or ColorSequence.new(WHITE),
    		Size = o.sizeSeq or nseq(o.s0 or 0.2, o.s1 or 4, (o.s1 or 4) * 0.6),
    		Transparency = o.alphaSeq or nseq(0, 0, 1),
    		Lifetime = range(life), Speed = range(0), Rotation = range(o.rot0 or -180, o.rot1 or 180), RotSpeed = range(o.rotSpeed or 0),
    		LightEmission = 1, ZOffset = o.z or 0.5,
    	})
    	e:Emit(o.count or 1)
    	Debris:AddItem(a, life + 0.3)
    end

    local function flipBoom(cf, o)
    	o = o or {}
    	local life = o.life or 0.9
    	local size = o.size or 6
    	local a = worldAttach(cf * CFrame.new(0, o.y or 1.5, 0))
    	local e = emitter(a, {
    		Texture = TEX.Boom, Color = o.color or ColorSequence.new(WHITE),
    		Size = nseq(size * 0.8, size, size * 1.1), Transparency = nseq(0, 0, 0.2, 1),
    		Lifetime = range(life), Speed = range(0), Rotation = range(-20, 20), LightEmission = o.emission or 0.8, ZOffset = o.z or 0.3,
    	})
    	local ok = pcall(function()
    		e.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8
    		e.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
    		e.FlipbookStartRandom = false
    	end)
    	if not ok then e.Texture = TEX.Core end
    	e:Emit(o.count or 1)
    	Debris:AddItem(a, life + 0.3)
    end

    local function burst(cf, pal, o)
    	o = o or {}
    	local k = o.size or 1
    	local a = worldAttach(cf * CFrame.new(0, o.y or 1, 0))
    	emitter(a, { Texture = TEX.Core, Color = pal.seqHot, Size = nseq(0.5 * k, 3.5 * k, 4 * k), Transparency = nseq(0, 0.1, 1), Lifetime = range(0.25, 0.35), Speed = range(0), RotSpeed = range(-90, 90), ZOffset = 0.4 }):Emit(2)
    	emitter(a, { Texture = TEX.Field, Color = pal.seq, Size = nseq(1 * k, 6 * k), Transparency = nseq(0.3, 0.6, 1), Lifetime = range(0.5, 0.7), Speed = range(0), ZOffset = -0.2 }):Emit(1)
    	if (o.sparks or 24) > 0 then
    		emitter(a, {
    			Texture = TEX.Ember, Color = cseq(WHITE, pal.bright, pal.base), Size = nseq(0.35 * k, 0.2 * k, 0), Transparency = nseq(0, 0, 1),
    			Lifetime = range(0.6, 1.2), Speed = range(10 * k, 18 * k), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -25, 0), Drag = 2,
    			Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-2.5, -0.3, 0), Rotation = range(0), RotSpeed = range(0),
    		}):Emit(q(o.sparks or 24, 8))
    	end
    	if o.smoke ~= false then
    		emitter(a, {
    			Texture = TEX.Puff, Color = o.smokeColor or cseq(pal.deep, tint(pal.deep, -0.6)), Size = nseq(1.5 * k, 4 * k), Transparency = nseq(0.5, 0.7, 1),
    			Lifetime = range(1, 1.6), Speed = range(2, 5), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 1.5, 0), Drag = 3,
    			RotSpeed = range(-40, 40), LightEmission = 0.15, ZOffset = -0.4,
    		}):Emit(q(o.puffs or 6, 3))
    	end

    	ringWave(cf * CFrame.new(0, 0.15, 0), { Color = pal.seqGlass, R0 = 0.3, R1 = 2.6 * k, W0 = 0.16, W1 = 0.02, Dur = 0.5, A0 = 0.3 })
    	if (o.sparks or 24) > 0 then
    		local ga = worldAttach(cf * CFrame.new(0, 0.25, 0))
    		emitter(ga, { Texture = TEX.Glint, Color = cseq(WHITE, pal.bright), Size = nseq(0.12, 0.5, 0), Lifetime = range(0.3, 0.6), Speed = range(2, 6), SpreadAngle = Vector2.new(180, 180), Transparency = nseq(0, 1), Rotation = range(-180, 180), RotSpeed = range(-160, 160), LightEmission = 1 }):Emit(q(10, 4))
    		Debris:AddItem(ga, 1)
    	end
    	Debris:AddItem(a, 2.2)
    end

    local function ripples(cf, pal, o)
    	o = o or {}
    	local a = worldAttach(cf * CFrame.new(0, 0.1, 0))
    	local e = emitter(a, {
    		Texture = TEX.Ripple, Color = o.color or pal.seqGlass, Size = nseq(o.s0 or 1, o.s1 or 6), Transparency = nseq(0.3, 0.6, 1),
    		Lifetime = range(o.life or 1.2, (o.life or 1.2) * 1.4), Speed = range(0.01), EmissionDirection = Enum.NormalId.Top,
    		Orientation = Enum.ParticleOrientation.VelocityPerpendicular, Rotation = range(0, 360), RotSpeed = range(-20, 20), ZOffset = 0.05,
    	})
    	e:Emit(o.count or 3)
    	Debris:AddItem(a, (o.life or 1.2) * 1.4 + 0.3)
    end

    local PFPrim = {}
    do

    local function shapePaths(kind, seed)
    	local paths, cur = {}, {}
    	local function openPath() if #cur >= 2 then paths[#paths + 1] = cur end cur = {} end
    	local function pt(x, y) cur[#cur + 1] = Vector2.new(x, y) end
    	if kind == "star" then
    		for i = 1, 10 do
    			local r = (i % 2 == 1) and 1 or 0.42
    			local a = (i - 1) / 10 * TAU - math.pi / 2
    			pt(math.cos(a) * r, math.sin(a) * r)
    		end
    		openPath()
    	elseif kind == "pentagram" then
    		for i = 0, 4 do
    			local a = i * (TAU / 5) * 2 - math.pi / 2
    			pt(math.cos(a), math.sin(a))
    		end
    		openPath()
    	elseif kind == "hex" then
    		for i = 0, 5 do local a = i * TAU / 6 pt(math.cos(a), math.sin(a)) end
    		openPath()
    	elseif kind == "tri" then
    		for i = 0, 2 do local a = i * TAU / 3 - math.pi / 2 pt(math.cos(a), math.sin(a)) end
    		openPath()
    	elseif kind == "diamond" then
    		pt(0, -1) pt(0.5, 0) pt(0, 1) pt(-0.5, 0) pt(0, -1)
    		openPath()
    	elseif kind == "heart" then
    		for i = 0, 28 do
    			local t = i / 28 * TAU
    			pt(16 * math.sin(t) ^ 3 / 17, -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)) / 17)
    		end
    		openPath()
    	elseif kind == "crescent" then
    		for i = 0, 16 do local a = -math.pi / 2 + i / 16 * math.pi pt(math.cos(a), math.sin(a)) end
    		openPath()
    		for i = 0, 12 do
    			local a = math.pi / 2 - i / 12 * math.pi
    			local r = 0.72
    			pt(0.34 + math.cos(a) * r, math.sin(a) * r)
    		end
    		openPath()
    	elseif kind == "flake" then

    		for arm = 0, 5 do
    			local a = arm * TAU / 6 - math.pi / 2
    			local ca, sa = math.cos(a), math.sin(a)
    			local function loc(u, v) return ca * u - sa * v, sa * u + ca * v end
    			pt(loc(0, 0)) pt(loc(1, 0)) openPath()
    			pt(loc(0.45, 0)) pt(loc(0.68, 0.22)) openPath()
    			pt(loc(0.45, 0)) pt(loc(0.68, -0.22)) openPath()
    			pt(loc(0.72, 0)) pt(loc(0.92, 0.16)) openPath()
    			pt(loc(0.72, 0)) pt(loc(0.92, -0.16)) openPath()
    		end
    	elseif kind == "flower" then

    		for p = 0, 5 do
    			local a = p * TAU / 6 - math.pi / 2
    			local ca, sa = math.cos(a), math.sin(a)
    			local function loc(u, v) return ca * u - sa * v, sa * u + ca * v end
    			pt(loc(0.08, 0))
    			pt(loc(0.4, 0.3)) pt(loc(0.95, 0)) pt(loc(0.4, -0.3))
    			pt(loc(0.08, 0))
    			openPath()
    		end
    		for i = 0, 10 do local a = i / 10 * TAU pt(math.cos(a) * 0.2, math.sin(a) * 0.2) end
    		openPath()
    	elseif kind == "grid" then

    		for i = -1, 1 do
    			pt(i * 0.62, -0.93) pt(i * 0.62, 0.93) openPath()
    			pt(-0.93, i * 0.62) pt(0.93, i * 0.62) openPath()
    		end
    	elseif kind == "gear" then

    		for i = 0, 32 do
    			local a = i / 32 * TAU
    			local tooth = (math.floor(i / 2) % 2 == 0)
    			local r = tooth and 1 or 0.78
    			pt(math.cos(a) * r, math.sin(a) * r)
    		end
    		openPath()
    	else
    		for i = 0, 18 do local a = i / 18 * TAU pt(math.cos(a), math.sin(a)) end
    		openPath()
    	end
    	if seed then
    		math.randomseed(seed)
    	end
    	return paths
    end

    local function polyFX(cf, o)
    	o = o or {}
    	local paths = o.paths or shapePaths(o.kind or "ring", o.seed)
    	local r = o.r or 3
    	local W = o.W or 0.06
    	local dur = o.Dur or 1
    	local draw = o.Draw or 0.45
    	local spin = o.Spin or 0
    	local rise = o.Rise or 0
    	local a0 = o.A0 or 0
    	local glow = (o.Glow ~= false)
    	local wall = (o.Plane == "wall")
    	local lift = o.lift or 0.12
    	local beams, ats, total = {}, {}, 0
    	for _, p in ipairs(paths) do total = total + math.max(1, #p - 1) end
    	local function spot() local a = worldAttach(cf) ats[#ats + 1] = a return a end
    	for _, p in ipairs(paths) do
    		local loop = (#p > 2) and (math.abs(p[1].X - p[#p].X) < 1e-3 and math.abs(p[1].Y - p[#p].Y) < 1e-3)
    		for i = 1, #p - 1 do
    			local bA, bB = spot(), spot()
    			beams[#beams + 1] = {
    				a = bA, b = bB, p0 = p[i], p1 = p[i + 1],
    				bm = beam(bA, bB, {
    					FaceCamera = not wall, Segments = o.Seg or 1,
    					Width0 = W, Width1 = W,
    					Color = o.color or WHITE, Transparency = nseq(1),
    					LightEmission = glow and 1 or 0.2, ZOffset = o.z or 0.06,
    				}),
    				idx = #beams, loopA = loop and i == 1,
    			}
    		end
    	end

    	local asms
    	if o.Assembly then
    		asms = {}
    		local seen = {}
    		local spread = o.AssembleSpread or (1.4 + r * 0.8)
    		for _, p in ipairs(paths) do
    			for i = 1, #p do
    				local kk = math.floor(p[i].X * 400 + 0.5) .. ":" .. math.floor(p[i].Y * 400 + 0.5)
    				if not seen[kk] then
    					seen[kk] = true
    					local da = worldAttach(cf)
    					ats[#ats + 1] = da
    					local dx, dy, dz = rnd(-1, 1), rnd(-0.2, 1.2), rnd(-1, 1)
    					local mag = math.sqrt(dx * dx + dy * dy + dz * dz)
    					if mag < 1e-3 then dx, dy, dz, mag = 0, 1, 0, 1 end
    					local de = emitter(da, {
    						Enabled = true, Rate = 12, Texture = TEX.Glint,
    						Color = o.color or WHITE, Size = nseq(math.max(W * 2.4, 0.08), math.max(W * 1.4, 0.05), 0),
    						Lifetime = range(0.18, 0.3), Speed = range(0), Transparency = nseq(0, 0.2, 0.5),
    						LockedToPart = true, LightEmission = 1, ZOffset = 0.09,
    					})
    					asms[#asms + 1] = {
    						a = da, e = de, v = p[i],
    						start = cf * CFrame.new(p[i].X * r + dx / mag * spread, lift + p[i].Y * r + dy / mag * spread, -p[i].Y * r + dz / mag * spread),
    						dly = rnd(0, dur * draw * 0.35), ph = rnd(0, TAU),
    					}
    				end
    			end
    		end
    	end

    	local fadeAt = dur * 0.75
    	Timeline.add(dur, function(a, dt, t)
    		local prog = clamp(t / (dur * draw), 0, 1)
    		local ang = spin * t
    		local ca, sa = math.cos(ang), math.sin(ang)
    		local fade = (t > fadeAt) and (1 - (t - fadeAt) / (dur - fadeAt)) or 1
    		local pulse = o.Pulse and (1 + o.Pulse * math.sin(t * 9)) or 1

    		if asms then
    			for _, dm in ipairs(asms) do
    				local k = clamp((t - dm.dly) / (dur * draw * 0.8), 0, 1)
    				local u = k - 1
    				local ease = 1 + 2.70158 * u * u * u + 1.70158 * u * u
    				local x = dm.v.X * ca - dm.v.Y * sa
    				local yv = dm.v.X * sa + dm.v.Y * ca
    				local px, py, pz
    				if wall then
    					px, py, pz = x * r, lift + yv * r + rise * a, -0.05
    				else
    					px, py, pz = x * r * pulse, lift + rise * a, -yv * r * pulse
    				end
    				local target = cf * CFrame.new(px, py, pz)
    				if k >= 1 then
    					dm.a.CFrame = target
    					dm.e.Rate = (math.sin(t * 12 + dm.ph) > 0) and 16 or 5
    				else
    					dm.a.CFrame = dm.start:Lerp(target, ease)
    				end
    				if t > fadeAt then dm.e.Rate = 0 end
    			end
    		end
    		for _, seg in ipairs(beams) do
    			local vis = clamp(prog * total - seg.idx + 1, 0, 1)
    			local function place(pt2, at)
    				local x = pt2.X * ca - pt2.Y * sa
    				local y = pt2.X * sa + pt2.Y * ca
    				local px, py, pz
    				if wall then
    					px, py, pz = x * r, lift + y * r + rise * a, -0.05
    				else
    					px, py, pz = x * r * pulse, lift + rise * a, -y * r * pulse
    				end
    				at.CFrame = cf * CFrame.new(px, py, pz)
    			end
    			place(seg.p0, seg.a)
    			place(seg.p1, seg.b)
    			seg.bm.Transparency = nseq(1 - vis * fade * (1 - a0))
    		end
    	end, function()
    		for _, at in ipairs(ats) do pcall(function() at:Destroy() end) end
    	end)
    	return beams
    end

    local function crackFX(cf, o)
    	o = o or {}
    	local n = o.N or 6
    	local len = o.Len or 3
    	local paths = {}
    	math.randomseed(os.clock() * 1000 % 1000)
    	for b = 1, n do
    		local base = (b - 1) / n * TAU + rnd(-0.2, 0.2)
    		local ang = base
    		local cur = { Vector2.new(0, 0) }
    		local segs = math.random(3, 5)
    		for s = 1, segs do
    			ang = ang + rnd(-0.35, 0.35) * (o.jag or 1)
    			local rr = len * (s / segs) ^ 0.8
    			cur[#cur + 1] = Vector2.new(math.cos(ang) * rr, math.sin(ang) * rr)
    		end
    		paths[#paths + 1] = cur
    	end
    	polyFX(cf, { paths = paths, r = 1, W = o.W or 0.09, color = o.color, Dur = o.Dur or 0.9, Draw = 0.5, Glow = o.glow ~= false, z = 0.04, lift = 0.1 })
    	plate(cf, o.dark or cseq(BLACK, tint(BLACK, 0.3)), { s0 = len * 0.3, s1 = len * 0.9, life = (o.Dur or 0.9) * 1.2, a0 = 0.35, tex = TEX.Cloud, emission = 0 })
    	if o.dust ~= false then
    		for b = 1, math.min(n, q(4, 2)) do
    			local a = (b - 1) / math.min(n, q(4, 2)) * TAU
    			geyser(cf * CFrame.new(math.cos(a) * len * 0.8, 0, math.sin(a) * len * 0.8), 4, o.dustColor or cseq(tint(BLACK, 0.55), BLACK), { speed = 3, life = 0.7, spread = 30, size = 0.5, gravity = 2, tex = TEX.Puff, emission = 0, a0 = 0.5 })
    		end
    	end
    end

    local function spikeFX(cf, o)
    	o = o or {}
    	local n = o.N or 8
    	local len = o.Len or 2.4
    	local dur = o.Dur or 0.8
    	local up = o.Up or 0.35
    	local made = {}
    	for i = 1, n do
    		local a0, a1 = worldAttach(cf), worldAttach(cf)
    		local th = (i - 1) / n * TAU + (o.Offset or 0) + rnd(-0.06, 0.06)
    		local dir = Vector3.new(math.cos(th), up + rnd(-0.08, 0.15), math.sin(th))
    		local b = beam(a0, a1, {
    			FaceCamera = true, Segments = 1, Width0 = (o.W or 0.22), Width1 = 0.01,
    			Color = o.color or WHITE, Transparency = nseq(o.A0 or 0), LightEmission = 1, ZOffset = 0.1,
    		})
    		made[#made + 1] = { a0 = a0, a1 = a1, dir = dir, k = 0.45 + math.random() * 0.55, ph = (i % 3) * 0.06 }
    	end
    	Timeline.add(dur, function(a, dt, t)
    		for _, m in ipairs(made) do
    			local g = easeOut(clamp(t / (dur * 0.45) - m.ph, 0, 1))
    			local L = len * m.k * g
    			m.a1.CFrame = cf * CFrame.new(m.dir * L)
    			m.a0.CFrame = cf * CFrame.new(m.dir * (L * 0.25), 0.15, m.dir * (L * 0.25))
    			m.a0.CFrame = cf * CFrame.new(m.dir.X * L * 0.22, 0.12, m.dir.Z * L * 0.22)
    		end
    	end, function()
    		for _, m in ipairs(made) do m.a0:Destroy() m.a1:Destroy() end
    	end)
    end

    local function cometFX(cf, o)
    	o = o or {}
    	local p0 = o.from or (cf * CFrame.new(0, 9, 0)).Position
    	local p1 = o.to or cf.Position
    	local T = o.T or 0.7
    	local arc = o.arc or 2
    	local head = worldAttach(CFrame.new(p0))
    	local head2 = worldAttach(CFrame.new(p0))
    	local e = emitter(head, {
    		Texture = o.tex or TEX.Glint, Color = o.color or ColorSequence.new(WHITE),
    		Size = nseq((o.size or 0.5) * 0.7, o.size or 0.5, 0), Transparency = nseq(0, 0.1, 1),
    		Lifetime = range(0.22), Speed = range(0), LightEmission = 1, LockedToPart = true, ZOffset = 0.3,
    	})
    	emitter(head, { Texture = TEX.Mote, Color = o.color, Size = nseq((o.size or 0.5) * 0.5, 0), Transparency = nseq(0.2, 1), Lifetime = range(0.4, 0.8), Speed = range(1, 3), SpreadAngle = Vector2.new(180, 180), Drag = 2, LightEmission = 1 })
    	trail(head, head2, { Color = o.color, Lifetime = o.trailLife or 0.4, WidthScale = nseq(1, 0), Transparency = nseq(0.1, 0.7, 1), FaceCamera = true, LightEmission = 1 })
    	Timeline.add(T, function(a)
    		local u = easeIn(a)
    		local pos = p0:Lerp(p1, u) + Vector3.new(0, arc * math.sin(math.pi * a) * (1 - u * 0.4), 0)
    		head.CFrame = CFrame.new(pos)
    		head2.CFrame = CFrame.new(pos:Lerp(p0, 0.08))
    	end, function()
    		head:Destroy() head2:Destroy()
    		if o.impact ~= false then
    			flipBoom(CFrame.new(p1), { size = (o.size or 0.5) * 5, life = 0.55, y = 0.6, color = o.color })
    			geyser(CFrame.new(p1), 8, o.color, { speed = 6, life = 0.5, spread = 55, size = 0.16, gravity = -18, streak = true, drag = 1 })
    			glint(CFrame.new(p1), WHITE, 8, 6, 0.25)
    		end
    	end)
    end

    local function inkFX(cf, o)
    	o = o or {}
    	local s = o.size or 2
    	local dur = o.Dur or 1.2
    	local ink = o.color or cseq(BLACK, tint(BLACK, 0.25), BLACK)
    	shockSprite(cf, { tex = TEX.Cloud, color = ink, s0 = s * 0.4, s1 = s * 1.7, life = dur, a0 = 0.45, emission = 0, z = 0.03, rotSpeed = 15 })
    	local n = o.N or 7
    	local made = {}
    	for i = 1, n do
    		local a0, a1 = worldAttach(cf), worldAttach(cf)
    		local th = (i - 1) / n * TAU + rnd(-0.3, 0.3)
    		local L = s * rnd(0.6, 1.25)
    		local b = beam(a0, a1, {
    			FaceCamera = true, Segments = 1, Width0 = s * 0.2, Width1 = s * 0.05,
    			Color = ink, Transparency = nseq(0.05, 0.6), LightEmission = 0, ZOffset = 0.05,
    		})
    		b.CurveSize0 = rnd(-0.5, 0.5) * s * 0.4
    		made[#made + 1] = { a0 = a0, a1 = a1, th = th, L = L }
    	end
    	Timeline.add(dur, function(a)
    		for _, m in ipairs(made) do
    			local g = easeOut(a)
    			local x, z = math.cos(m.th) * m.L * g, math.sin(m.th) * m.L * g
    			m.a1.CFrame = cf * CFrame.new(x, 0.12, z)
    			m.a0.CFrame = cf * CFrame.new(x * 0.15, 0.12, z * 0.15)
    		end
    	end, function()
    		for _, m in ipairs(made) do m.a0:Destroy() m.a1:Destroy() end
    	end)
    	scatter(cf, q(10, 5), ink, { speed = s * 1.6, life = dur * 0.8, size = 0.16, gravity = -14, drag = 1.5, y = 0.25, emission = 0 })
    end

    local function matrixFX(cf, o)
    	o = o or {}
    	local R = o.R or 2.4
    	local cols = o.cols or 10
    	local dur = o.Dur or 1.1
    	for i = 1, cols do
    		local a = worldAttach(cf * CFrame.new(math.cos(i / cols * TAU) * R * rnd(0.25, 1), o.h or 4, math.sin(i / cols * TAU) * R * rnd(0.25, 1)))
    		emitter(a, {
    			Texture = i % 3 == 0 and TEX.Trace or TEX.Scratch, Color = o.color or ColorSequence.new(WHITE),
    			Size = nseq(0.1, 0.14, 0.05), Transparency = nseq(0, 0.2, 1),
    			Lifetime = range((o.h or 4) / (o.speed or 9) * 0.9, (o.h or 4) / (o.speed or 9) * 1.2),
    			Rate = o.rate or 14, Speed = range(o.speed or 9), EmissionDirection = Enum.NormalId.Bottom,
    			SpreadAngle = Vector2.new(1, 1), Acceleration = Vector3.new(0, -6, 0), Drag = 0,
    			Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-2.4, -1), LightEmission = 1, Rotation = range(0), RotSpeed = range(0),
    		})
    		Debris:AddItem(a, dur + 0.4)
    	end
    end

    local function webFX(cf, o)
    	o = o or {}
    	local m = o.M or 6
    	local R = o.R or 2.6
    	local y = o.y or 0.4
    	local dur = o.Dur or 0.5
    	local nodes = {}
    	for i = 1, m do
    		local th = (i - 1) / m * TAU + rnd(-0.15, 0.15)
    		nodes[i] = cf * CFrame.new(math.cos(th) * R * rnd(0.8, 1.1), y + rnd(-0.3, 0.5), math.sin(th) * R * rnd(0.8, 1.1))
    	end
    	local bolts = {}
    	for i = 1, m do
    		local j = (math.random() < 0.6) and (i % m + 1) or ((i + math.random(2, 3) - 1) % m + 1)
    		local b = makeBolt(Terrain, { K = 5, Width = o.W or 0.1, Color = o.color or cseq(WHITE, WHITE) })
    		bolts[#bolts + 1] = { b = b, a = nodes[i], c = nodes[j], seed = math.random() * 10, on = math.random() < 0.8 }
    	end
    	Timeline.add(dur, function(a, dt, t)
    		for k, bl in ipairs(bolts) do
    			if bl.on then
    				bl.b:set(bl.a.Position, bl.c.Position, 0.45, t * 24 + bl.seed)
    				bl.b:alpha((math.sin(t * 31 + bl.seed * 3) > -0.1) and (1 - a) * 0.9 or 1)
    			end
    		end
    	end, function()
    		for _, bl in ipairs(bolts) do bl.b:destroy() end
    	end)
    	glint(cf * CFrame.new(0, y, 0), WHITE, R * 2, 8, 0.2)
    end

    local function heartFX(cf, o)
    	o = o or {}
    	local r = o.r or 1.6
    	local dur = o.Dur or 1.2
    	local col = o.color or cseq(WHITE, Color3.fromRGB(255, 120, 170), Color3.fromRGB(255, 60, 120))
    	polyFX(cf, { kind = "heart", r = r, W = o.W or 0.09, color = col, Dur = dur, Draw = 0.3, Pulse = 0.06, Rise = o.Rise or 0.8, z = 0.1 })
    	flashSprite(cf * CFrame.new(0, 1, 0), { tex = TEX.Heart, color = col, s0 = r * 0.3, s1 = r * 1.15, life = dur * 0.8, y = 0 })
    	geyser(cf, q(8, 4), col, { speed = 2.5, life = 1.3, spread = 50, size = 0.32, gravity = 2.5, drag = 1.4, tex = TEX.Heart, emission = 1 })
    end

    local function glitchFX(cf, o)
    	o = o or {}
    	local W = o.W or 2.4
    	local rows = o.rows or 7
    	local dur = o.Dur or 0.7
    	local base = o.color or Color3.fromRGB(120, 200, 255)
    	local hueR, hueG, hueB = base, tint(base, 0.4), tint(base, -0.4)
    	local made = {}
    	for i = 1, rows do
    		local y = (i / rows - 0.5) * (o.H or 4)
    		local trio = {}
    		for c = 1, 3 do
    			local a0, a1 = worldAttach(cf), worldAttach(cf)
    			trio[c] = { a0 = a0, a1 = a1, b = beam(a0, a1, {
    				FaceCamera = true, Segments = 1, Width0 = 0.1, Width1 = 0.1,
    				Color = (c == 1 and hueR or c == 2 and hueG or hueB), Transparency = nseq(0.1), LightEmission = 1,
    			}), seed = math.random() * 20 }
    		end
    		made[#made + 1] = { y = y, trio = trio, ph = math.random() }
    	end
    	Timeline.add(dur, function(a, dt, t)
    		for _, m in ipairs(made) do
    			local on = math.sin(t * 37 + m.ph * 9) > -0.55
    			for c, tr in ipairs(m.trio) do
    				local sh = math.sin(t * 41 + tr.seed) * 0.3
    				local w = W * (0.55 + math.abs(math.sin(t * 17 + tr.seed * 2)) * 0.45)
    				tr.a0.CFrame = cf * CFrame.new(-w + sh * (c - 2) * 1.6, m.y + math.sin(t * 23 + m.ph * 7) * 0.12, 0)
    				tr.a1.CFrame = cf * CFrame.new(w + sh * (c - 2) * 1.6, m.y, 0)
    				tr.b.Transparency = nseq(on and (a * 0.9 + 0.05) or 1)
    			end
    		end
    	end, function()
    		for _, m in ipairs(made) do
    			for _, tr in ipairs(m.trio) do tr.a0:Destroy() tr.a1:Destroy() end
    		end
    	end)
    end

    local function runeRingFX(cf, o)
    	o = o or {}
    	local r = o.r or 2.6
    	local dur = o.Dur or 1.4
    	local col = o.color or WHITE
    	shockSprite(cf, { tex = TEX.Swirl, color = col, s0 = r * 0.8, s1 = r * 1.05, life = dur, a0 = 0.15, rotSpeed = 70, z = 0.04 })
    	shockSprite(cf, { tex = TEX.Scratch, color = col, s0 = r * 1.5, s1 = r * 1.55, life = dur * 0.9, a0 = 0.3, rotSpeed = -30, z = 0.045 })
    	polyFX(cf, { kind = "hex", r = r * 0.92, W = o.W or 0.05, color = col, Dur = dur, Draw = 0.3, Spin = 0.6, z = 0.05 })
    	polyFX(cf, { kind = "hex", r = r * 0.6, W = o.W or 0.04, color = col, Dur = dur, Draw = 0.55, Spin = -1, z = 0.05 })
    	for i = 1, 6 do
    		local a = i / 6 * TAU
    		flashSprite(cf * CFrame.new(math.cos(a) * r * 0.92, 0.3, math.sin(a) * r * 0.92), { tex = TEX.Glint, color = col, s0 = 0.1, s1 = 0.5, life = dur * 0.8, y = 0, rotSpeed = 90 })
    	end
    end

    local function snowflakeFX(cf, o)
    	o = o or {}
    	polyFX(cf, { kind = "flake", r = o.r or 1.8, W = o.W or 0.05, color = o.color or cseq(WHITE, Color3.fromRGB(190, 235, 255)), Dur = o.Dur or 1.1, Draw = 0.5, Spin = (o.Spin or 0.8), lift = o.lift or 1.2, z = 0.08 })
    	scatter(cf * CFrame.new(0, (o.lift or 1.2), 0), q(8, 4), o.color or cseq(WHITE, Color3.fromRGB(190, 235, 255)), { speed = 1.2, life = 1, size = 0.12, gravity = -1.5, drag = 2, tex = TEX.Star, y = 0 })
    end

    local function flameWingFX(cf, o)
    	o = o or {}
    	local s = o.size or 1.4
    	local fire = o.color or cseq(WHITE, Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 90, 20), tint(Color3.fromRGB(120, 20, 0), -0.3))
    	for side = -1, 1, 2 do
    		arcSpray(cf * CFrame.new(side * s * 0.22, s * 0.2, 0), { Color = fire, N = 6, R0 = s * 0.2, R1 = s * 1.05, W = s * 0.2, Dur = o.Dur or 0.9, Span = 0.34, Phase = side > 0 and -0.4 or math.pi - 0.4, Tilt = RAD(90), Roll = side * RAD(24), Rise = s * 0.75, Spin = 0.5, Texture = TEX.Fire, TextureLength = 1 })
    		arcSpray(cf * CFrame.new(side * s * 0.22, s * 0.2, 0), { Color = cseq(WHITE, Color3.fromRGB(255, 230, 160)), N = 4, R0 = s * 0.15, R1 = s * 0.7, W = s * 0.08, Dur = (o.Dur or 0.9) * 0.8, Span = 0.3, Phase = side > 0 and -0.4 or math.pi - 0.4, Tilt = RAD(90), Roll = side * RAD(24), Rise = s * 0.75, Delay = 0.05, z = 0.04 })
    	end
    	geyser(cf, q(16, 8), fire, { speed = s * 2.4, life = 0.9, spread = 26, size = s * 0.12, gravity = 2.5, drag = 0.6, tex = TEX.Fire })
    	geyser(cf, q(12, 6), cseq(WHITE, Color3.fromRGB(255, 170, 60)), { speed = s * 3.2, life = 0.7, spread = 34, size = 0.14, gravity = 1.5, tex = TEX.Ember, streak = true })
    end

    local function prismFX(cf, o)
    	o = o or {}
    	local r = o.r or 3
    	local dur = o.Dur or 0.9
    	glint(cf * CFrame.new(0, 0.5, 0), WHITE, r * 1.6, 12, 0.3)
    	local n = 6
    	for i = 1, n do
    		local hue = (i - 1) / n
    		local col = Color3.fromHSV(hue, 0.85, 1)
    		local a0, a1 = worldAttach(cf * CFrame.new(0, 0.5, 0)), worldAttach(cf * CFrame.new(0, 0.5, 0))
    		local th = (i - 1) / n * TAU
    		local b = beam(a0, a1, { FaceCamera = true, Segments = 1, Width0 = 0.16, Width1 = 0.02, Color = ColorSequence.new(WHITE, col), Transparency = nseq(0), LightEmission = 1 })
    		local L = r * (0.7 + (i % 3) * 0.15)
    		Timeline.add(dur, function(fa)
    			local g = easeOut(fa)
    			a1.CFrame = cf * CFrame.new(math.cos(th) * L * g, 0.5 + g * 1.2, math.sin(th) * L * g)
    			b.Transparency = nseq(1 - fa)
    		end, function() a0:Destroy() a1:Destroy() end)
    	end
    	for i = 1, 3 do
    		ringWave(cf, { Color = ColorSequence.new(Color3.fromHSV(i * 0.33, 0.8, 1)), R0 = r * 0.1, R1 = r * (0.5 + i * 0.2), W0 = 0.12, W1 = 0.02, Dur = dur * (0.8 + i * 0.15), Delay = i * 0.07, A0 = 0.25, Segments = 2 })
    	end
    end

    local function clockFX(cf, o)
    	o = o or {}
    	local r = o.r or 2.4
    	local dur = o.Dur or 1.6
    	local col = o.color or cseq(WHITE, WHITE)
    	local made = {}
    	local rim = {}
    	for i = 1, 12 do
    		local a = worldAttach(cf)
    		local a2 = worldAttach(cf)
    		rim[#rim + 1] = { a = a, b = a2, i = i }
    		made[#made + 1] = beam(a, a2, { FaceCamera = true, Segments = 1, Width0 = (i % 3 == 1) and 0.09 or 0.05, Width1 = 0.04, Color = col, Transparency = nseq(0.15), LightEmission = 1 })
    	end
    	local hA, hB = worldAttach(cf), worldAttach(cf)
    	local hand = beam(hA, hB, { FaceCamera = true, Segments = 1, Width0 = 0.12, Width1 = 0.03, Color = cseq(WHITE, WHITE), Transparency = nseq(0), LightEmission = 1 })
    	local mB = worldAttach(cf)
    	local minute = beam(hA, mB, { FaceCamera = true, Segments = 1, Width0 = 0.08, Width1 = 0.02, Color = cseq(WHITE, WHITE), Transparency = nseq(0.1), LightEmission = 1 })
    	Timeline.add(dur, function(a, dt, t)
    		local fade = 1 - a
    		for _, seg in ipairs(rim) do
    			local th = seg.i / 12 * TAU
    			local r0, r1 = r * 0.82, r * (seg.i % 3 == 1 and 1 or 0.93)
    			seg.a.CFrame = cf * CFrame.new(math.cos(th) * r0, 1.2, math.sin(th) * r0)
    			seg.b.CFrame = cf * CFrame.new(math.cos(th) * r1, 1.2, math.sin(th) * r1)
    		end
    		local ha = -t * 1.4
    		hB.CFrame = cf * CFrame.new(math.cos(ha) * r * 0.45, 1.2 + math.sin(ha) * r * 0.45 * 0.35, math.sin(ha) * r * 0.62)
    		local ma = -t * 5.2
    		mB.CFrame = cf * CFrame.new(math.cos(ma) * r * 0.72, 1.2, math.sin(ma) * r * 0.72)
    		hand.Transparency = nseq(fade * 0.9)
    		minute.Transparency = nseq(fade * 0.95)
    		for _, seg in ipairs(rim) do seg.a.Parent = seg.a.Parent end
    	end, function()
    		for _, seg in ipairs(rim) do seg.a:Destroy() seg.b:Destroy() end
    		hA:Destroy() hB:Destroy() mB:Destroy()
    	end)

    	for k = 1, 4 do
    		later(dur * 0.18 * k, function()
    			flashSprite(cf * CFrame.new(0, r * 1.02, 0), { tex = TEX.Glint, color = WHITE, s0 = 0.1, s1 = 0.55, life = 0.18, y = 1.2 })
    		end)
    	end
    end

    local function soulFX(cf, o)
    	o = o or {}
    	local n = o.N or 6
    	local dur = o.Dur or 1.5
    	for i = 1, n do
    		later((i - 1) * dur / n * 0.6, function()
    			local a = worldAttach(cf * CFrame.new(rnd(-1, 1) * (o.spread or 1.2), 0.3, rnd(-1, 1) * (o.spread or 1.2)))
    			local a2 = worldAttach(a.CFrame)
    			emitter(a, {
    				Texture = TEX.Cloud, Color = o.color or cseq(Color3.fromRGB(200, 230, 255), WHITE),
    				Size = nseq(0.5, 0.85, 0.2), Transparency = nseq(0.25, 0.4, 1),
    				Lifetime = range(0.12), Speed = range(0), LightEmission = 0.6, LockedToPart = true, ZOffset = 0.1,
    			})
    			trail(a, a2, { Color = o.color or cseq(Color3.fromRGB(200, 230, 255), WHITE), Lifetime = 0.5, WidthScale = nseq(0.8, 0), Transparency = nseq(0.35, 1), FaceCamera = true, LightEmission = 0.5 })
    			local ph = rnd(0, TAU)
    			Timeline.add(dur * rnd(0.7, 1.1), function(fa, dt, t)
    				a.CFrame = CFrame.new(a.CFrame.Position + Vector3.new(math.sin(t * 3 + ph) * dt * 2.2, dt * (2.6 + math.sin(ph) * 0.8), math.cos(t * 2.2 + ph) * dt * 1.4))
    				a2.CFrame = a.CFrame * CFrame.new(0, -0.25, 0)
    			end, function() a:Destroy() a2:Destroy() end)
    		end)
    	end
    end

    	local function assembleFX(host, o)
    		o = o or {}
    		local n = math.max(6, math.floor(q(o.n or 24, 10) + 0.5))
    		local R, Y = o.r or 1.5, o.y or 0
    		local pts = {}
    		if o.kind == "oval" then
    			for i = 1, n do
    				local an = i / n * TAU
    				pts[i] = Vector3.new(math.cos(an) * R, Y + math.sin(an) * (o.ry or R * 1.6), 0)
    			end
    		elseif o.kind == "sphere" then
    			for i = 1, n do
    				local u = clamp(1 - 2 * ((i - 0.5) / n), -1, 1)
    				local ph = math.acos(u)
    				local th = (i * 0.618033) % 1 * TAU
    				pts[i] = Vector3.new(math.sin(ph) * math.cos(th) * R, Y + math.cos(ph) * R, math.sin(ph) * math.sin(th) * R)
    			end
    		elseif o.kind == "cage" then
    			local bars = math.max(4, math.floor(n / 3))
    			local idx = 0
    			for b = 1, bars do
    				local an = b / bars * TAU
    				for s2 = -1, 0, 1 do
    					idx = idx + 1
    					pts[idx] = Vector3.new(math.cos(an) * R, Y + s2 * (o.h or 4.5) * 0.5, math.sin(an) * R)
    				end
    			end
    			n = idx
    		elseif o.kind == "box" then
    			local idx = 0
    			for sx = -1, 1, 2 do for sy = -1, 1, 2 do for sz2 = -1, 1, 2 do
    				idx = idx + 1
    				pts[idx] = Vector3.new(sx * R, Y + sy * R, sz2 * R)
    			end end end
    			n = idx
    		elseif o.kind == "heart" then
    			for i = 1, n do
    				local u = i / n * TAU
    				local hx = 16 * math.sin(u) * math.sin(u) * math.sin(u)
    				local hy = 13 * math.cos(u) - 5 * math.cos(2 * u) - 2 * math.cos(3 * u) - math.cos(4 * u)
    				pts[i] = Vector3.new(hx / 17 * R, Y + hy / 17 * R + R * 0.1, 0)
    			end
    		else
    			for i = 1, n do
    				local an = i / n * TAU
    				pts[i] = Vector3.new(math.cos(an) * R, Y, math.sin(an) * R)
    			end
    		end
    		local list = {}
    		local spread = o.spread or (R + 2)
    		for i = 1, n do
    			local da = attach(host, CFrame.new(), "PF_Asm")
    			local dx, dy, dz = rnd(-1, 1), rnd(-0.3, 1.1), rnd(-1, 1)
    			local mag = math.sqrt(dx * dx + dy * dy + dz * dz)
    			if mag < 1e-3 then dx, dy, dz, mag = 0, 1, 0, 1 end
    			local e = emitter(da, {
    				Enabled = true, Rate = 12, Texture = o.tex or TEX.Glint,
    				Color = (o.color2 and i % 3 == 0) and o.color2 or o.color or WHITE,
    				Size = nseq(o.size or 0.13, (o.size or 0.13) * 0.7, 0),
    				Lifetime = range(0.16, 0.3), Speed = range(0), Transparency = nseq(0, 0.15, 0.45),
    				LockedToPart = true, LightEmission = 1, ZOffset = 0.1,
    			})
    			list[i] = {
    				a = da, e = e, p1 = pts[i],
    				p0 = pts[i] + Vector3.new(dx / mag * spread, dy / mag * spread, dz / mag * spread),
    				dly = (i - 1) / n * (o.dur or 1.1) * 0.5, ph = rnd(0, TAU), sp = rnd(1.4, 2.4),
    			}
    		end
    		local t0, yawF = nil, 0
    		local function update(t, yaw)
    			if not t0 then t0 = t end
    			yawF = yaw or yawF
    			local k0 = t - t0
    			local spinA = yawF + t * (o.spin or 0)
    			local ca, sa = math.cos(spinA), math.sin(spinA)
    			for i, it in ipairs(list) do
    				local k = clamp((k0 - it.dly) / ((o.dur or 1.1) * 0.72), 0, 1)
    				local u = k - 1
    				local ease = 1 + 2.70158 * u * u * u + 1.70158 * u * u
    				local p = it.p0:Lerp(it.p1, ease)
    				if k >= 1 then
    					p = p + Vector3.new(math.sin(t * it.sp + it.ph), math.cos(t * it.sp * 0.8 + it.ph * 1.7), math.sin(t * it.sp * 1.1 + it.ph * 2.3)) * (o.orbit or 0.05)
    					it.e.Rate = (math.sin(t * 9 + it.ph) > -0.2) and 12 or 4
    				else
    					p = p + Vector3.new(math.sin(t * 8 + it.ph), math.cos(t * 6.5 + it.ph * 1.3), math.sin(t * 7.2 + it.ph * 2.1)) * (1 - k) * 0.55
    				end
    				it.a.Position = Vector3.new(p.X * ca - p.Z * sa, p.Y, p.X * sa + p.Z * ca)
    			end
    		end
    		return list, update
    	end

    PFPrim.shapePaths = shapePaths
    PFPrim.assembleFX = assembleFX
    PFPrim.polyFX = polyFX
    PFPrim.crackFX = crackFX
    PFPrim.spikeFX = spikeFX
    PFPrim.cometFX = cometFX
    PFPrim.inkFX = inkFX
    PFPrim.matrixFX = matrixFX
    PFPrim.webFX = webFX
    PFPrim.heartFX = heartFX
    PFPrim.glitchFX = glitchFX
    PFPrim.runeRingFX = runeRingFX
    PFPrim.snowflakeFX = snowflakeFX
    PFPrim.flameWingFX = flameWingFX
    PFPrim.prismFX = prismFX
    PFPrim.clockFX = clockFX
    PFPrim.soulFX = soulFX
    end

    local Char = { model = nil, humanoid = nil, root = nil, torso = nil, head = nil, r6 = false, limbs = {} }
    local function alive()
    	return Char.model ~= nil and Char.model.Parent ~= nil
    		and Char.root ~= nil and Char.root.Parent ~= nil
    		and Char.torso ~= nil and Char.torso.Parent ~= nil
    end
    local function hpFrac()
    	local h = Char.humanoid
    	if not h then return 1 end
    	local ok, hp, mx = pcall(function() return h.Health, h.MaxHealth end)
    	if ok and mx and mx > 0 then return clamp(hp / mx, 0, 1) end
    	return 1
    end

    local Tick = { conn = nil, clock = 0, users = {}, spin = 0, wobble = 0, cap = 0, acc = 0 }
    function Tick.use(key, fn)
    	Tick.users[key] = fn
    	if next(Tick.users) and not Tick.conn then
    		Tick.conn = RunService.Heartbeat:Connect(function(dt)
    			if Tick.cap > 0 then
    				Tick.acc = Tick.acc + dt
    				if Tick.acc < 1 / Tick.cap then return end
    				dt = Tick.acc
    				Tick.acc = 0
    			end
    			Tick.clock = Tick.clock + dt
    			if S.Spin.Enabled then
    				Tick.spin = Tick.spin + dt * S.Spin.Speed
    				Tick.wobble = S.Spin.Wobble and math.sin(Tick.clock * 1.8) * RAD(12) or 0
    			else
    				Tick.wobble = 0
    			end
    			for _, fn in Tick.users do pcall(fn, dt, Tick.clock) end
    		end)
    	end
    end
    function Tick.drop(key)
    	Tick.users[key] = nil
    	if not next(Tick.users) and Tick.conn then
    		Tick.conn:Disconnect()
    		Tick.conn = nil
    	end
    end

    local Bus = { handlers = {} }
    function Bus.on(name, fn)
    	Bus.handlers[name] = Bus.handlers[name] or {}
    	table.insert(Bus.handlers[name], fn)
    end
    function Bus.emit(name, ...)
    	for _, fn in ipairs(Bus.handlers[name] or {}) do pcall(fn, ...) end
    end

    local RainbowHue = {}
    local function paletteFor(key, cfg)
    	if RainbowHue[key] then return makePalette(cfg, RainbowHue[key]) end
    	return makePalette(cfg)
    end

    do
    	local detailSeq = 0
    	function PFPrim.detailFX(host, o, key)
    		o = o or {}
    		local a = attach(host, CFrame.new(0, o.dy or 0, 0), "PF_Detail")
    		local e = emitter(a, {
    			Enabled = true, Rate = q(o.rate or 8, 2), Texture = o.tex or TEX.Glint,
    			Color = o.color or WHITE, Size = nseq(o.size or 0.1, (o.size or 0.1) * 0.35, 0),
    			Lifetime = range(o.life or 0.6, (o.life or 0.6) * 1.7),
    			Speed = range(o.speed or 0.3, (o.speed or 0.3) * 2.2),
    			SpreadAngle = Vector2.new(180, 180), Transparency = nseq(o.a0 or 0.15, 0.4, 1),
    			Rotation = range(-180, 180), RotSpeed = range(-120, 120),
    			Acceleration = o.accel or Vector3.new(0, 1.4, 0), Drag = o.drag or 1.4,
    			LightEmission = 1, ZOffset = 0.12,
    		})
    		detailSeq = detailSeq + 1
    		local base, id = e.Rate, detailSeq
    		Tick.use(key or ("Detail" .. id), function(dt, t)
    			if e.Parent then e.Rate = base * (1 + 0.45 * organicNoise(t * 0.9, id * 3.7)) end
    		end)
    		return e, a
    	end
    end

    local Modules = { list = {}, map = {} }
    local function defineModule(key, defaults, opts)
    	opts = opts or {}
    	S[key] = defaults
    	local m = { key = key, items = {}, conns = {}, painters = {}, built = false, persistent = not opts.transient, label = opts.label or key }
    	function m:keep(inst) table.insert(self.items, inst) return inst end
    	function m:onPaint(fn) table.insert(self.painters, fn) end
    	function m:repaint(pal) for _, fn in ipairs(self.painters) do pcall(fn, pal) end end
    	function m:connect(signal, fn)
    		local c = signal:Connect(fn)
    		table.insert(self.conns, c)
    		return c
    	end
    	function m:palette() return paletteFor(self.key, S[self.key]) end

    	function m:hueShift(dh)
    		local base = self.hueBase
    		if not base then base = setmetatable({}, { __mode = "k" }) self.hueBase = base end
    		local function paint(inst)
    			local cls = inst.ClassName
    			if cls == "Beam" or cls == "ParticleEmitter" or cls == "Trail" then
    				local b = base[inst]
    				if not b then b = inst.Color base[inst] = b end
    				inst.Color = hueShiftSeq(b, dh)
    			elseif cls == "PointLight" then
    				local b = base[inst]
    				if not b then b = inst.Color base[inst] = b end
    				inst.Color = hueShiftColor(b, dh)
    			end
    		end
    		for _, i in ipairs(self.items) do
    			pcall(function()
    				if typeof(i) == "Instance" then
    					paint(i)
    					for _, d in ipairs(i:GetDescendants()) do paint(d) end
    				elseif i.beams then
    					for _, b in ipairs(i.beams) do paint(b) end
    				elseif i.beam then
    					paint(i.beam)
    				end
    			end)
    		end
    	end
    	function m:clear()
    		for _, c in ipairs(self.conns) do pcall(function() c:Disconnect() end) end
    		for _, i in ipairs(self.items) do
    			pcall(function()
    				if typeof(i) == "Instance" then i:Destroy() else i:destroy() end
    			end)
    		end
    		self.conns, self.items, self.painters = {}, {}, {}
    		self.state = nil
    		self.hueBase = nil
    		self.built = false
    	end

    	function m.stop()
    		Tick.drop(key)
    		m:clear()
    	end
    	Modules.map[key] = m
    	table.insert(Modules.list, m)
    	return m
    end

    local shakeToken, shakeBase = 0, nil
    local function cameraShake(amp, dur, freq)
    	local hum = Char.humanoid
    	if not hum or not amp or amp <= 0 then return end
    	if shakeBase == nil then
    		local ok, b = pcall(function() return hum.CameraOffset end)
    		shakeBase = (ok and b) or Vector3.zero
    	end
    	local base = shakeBase
    	shakeToken = shakeToken + 1
    	local my = shakeToken
    	local f = freq or 28
    	local seed = math.random() * 10
    	Timeline.add(dur or 0.3, function(a, dt, t)
    		if my ~= shakeToken then return end
    		local k = (1 - a) ^ 2 * amp
    		local off = Vector3.new(math.sin(t * f + seed) * k, math.cos(t * f * 1.3 + seed) * k, math.sin(t * f * 0.7) * k * 0.4)
    		pcall(function() hum.CameraOffset = base + off end)
    	end, function()
    		if my == shakeToken then
    			pcall(function() hum.CameraOffset = base end)
    			shakeBase = nil
    		end
    	end)
    end

    local Jump = defineModule("Jump", {
    	Enabled = false, Style = "Ripple", Color = Color3.fromRGB(120, 200, 255),
    	Size = 7, Duration = 0.7, Flash = true, Sparks = true, Column = false, Echo = false,
    	Chain = false, Random = false, DoubleAir = true,
    }, { transient = true })
    Jump.Styles = {
    	"Ripple", "Twin Arc", "Spiral Lift", "Shard Burst", "Beacon", "Dome", "Meteor Ring", "Thunder Step",
    	"Bloom", "Crescent", "Gear", "Glass Break", "Ink Drop", "Star Sigil", "Pulse Grid", "Phoenix",
    	"Nova", "Splash", "Stardust", "Smoke Ring",
    }
    local lastJump, jumpChain = 0, 0

    local function jumpStyle(style, cf, pal, size, dur, sparks)
    	if style == "Ripple" then

    		for i = 1, 3 do
    			ringWave(cf, { Color = i == 1 and pal.seqHot or pal.seq, R0 = size * 0.1, R1 = size * (0.6 + i * 0.15), W0 = size * 0.1 / i, W1 = 0.02, Dur = dur * (0.8 + i * 0.1), Delay = (i - 1) * 0.09, A0 = (i - 1) * 0.2 })
    		end
    		shockSprite(cf, { tex = TEX.Ring, color = pal.seqGlass, s0 = size * 0.3, s1 = size * 1.6, life = dur * 0.8, a0 = 0.2 })
    		geyser(cf, q(10, 5), cseq(WHITE, pal.bright), { speed = size * 1.6, life = 0.45, spread = 16, size = 0.14, gravity = -34, drag = 0.4, tex = TEX.Drop, streak = true, emission = 0.5 })
    		if sparks then fan(cf, 12, pal.seqHot, { speed = size * 1.2, life = dur, size = 0.2, up = 0.5, streak = true }) end
    	elseif style == "Twin Arc" then

    		for i = 0, 1 do
    			PFPrim.polyFX(cf * CFrame.Angles(0, i * math.pi / 2, 0), { Assembly = true, kind = "crescent", r = size * 0.85, W = size * 0.05, color = pal.seqHot, Dur = dur * 0.9, Draw = 0.3, Spin = 1.4 * (i == 0 and 1 or -1), Rise = size * 0.25, Plane = "wall", lift = size * 0.2 })
    		end
    		glint(cf * CFrame.new(0, size * 0.35, 0), WHITE, size * 1.4, 10, 0.22)
    		shockSprite(cf, { tex = TEX.Ring, color = pal.seqGlass, s0 = size * 0.2, s1 = size * 1.2, life = dur * 0.7, a0 = 0.15 })
    		if sparks then scatter(cf, 14, pal.seqGlass, { speed = size * 1.1, life = dur * 0.7, size = 0.16, streak = true, gravity = -6 }) end
    	elseif style == "Spiral Lift" then

    		helixRibbon(cf, { Color = pal.seqHot, R0 = size * 0.5, R1 = size * 0.08, H = size * 1.1, Turns = 2.8, W = size * 0.05, Dur = dur * 1.2, A0 = 0.05 })
    		helixRibbon(cf, { Color = pal.seq, R0 = size * 0.5, R1 = size * 0.08, H = size * 1.1, Turns = 2.8, W = size * 0.04, Dur = dur * 1.2, Dir = -1, A0 = 0.2 })
    		fan(cf, q(14, 7), pal.seqGlass, { inward = true, r = size * 0.9, speed = size * 0.8, life = dur, size = 0.14, up = 0.5, drag = 1.5 })
    		later(dur * 0.7, function()
    			flashSprite(cf * CFrame.new(0, size * 1.15, 0), { tex = TEX.Star, color = pal.seqGlass, s0 = 0.2, s1 = size * 0.5, life = 0.3 })
    		end)
    		if sparks then geyser(cf, 10, pal.seqHot, { speed = size, life = dur, spread = 10, size = 0.2, gravity = -2 }) end
    	elseif style == "Shard Burst" then

    		PFPrim.spikeFX(cf, { N = q(10, 6), Len = size * 0.5, W = 0.2, Dur = dur * 1.1, Up = 0.75, color = pal.seqGlass })
    		shards(cf, { Color = pal.seqHot, N = 10, Speed = size * 1.1, W = 0.18, Len = size * 0.13, Dur = dur * 1.2, Gravity = -22, Up = 0.9 })
    		PFPrim.polyFX(cf, { Assembly = true, kind = "diamond", r = size * 0.55, W = 0.05, color = pal.seqGlass, Dur = dur, Draw = 0.25, Spin = 1.2 })
    		flashSprite(cf, { tex = TEX.Star, color = pal.seqGlass, s0 = 0.5, s1 = size * 0.8, life = 0.3, y = 0.4 })
    		if sparks then scatter(cf, 14, pal.seqGlass, { speed = size, life = dur * 0.8, size = 0.16, streak = true, gravity = -10, tex = TEX.Glint }) end
    	elseif style == "Beacon" then

    		column(cf, { Color = pal.seqHot, W0 = size * 0.25, W1 = size * 0.05, H = size * 1.8, Dur = dur * 1.2, Twist = size * 0.12, Texture = TEX.Spark, Speed = 3 })
    		for i = 1, 3 do
    			ringWave(cf, { Color = pal.seq, R0 = size * 0.12, R1 = size * 0.42, W0 = 0.08, W1 = 0.03, Dur = dur * 1.1, Delay = i * 0.16, Rise = size * (0.9 + i * 0.3), Linear = true, A0 = 0.15 })
    		end
    		later(dur * 0.9, function()
    			flashSprite(cf * CFrame.new(0, size * 1.85, 0), { tex = TEX.Glint, color = pal.seqGlass, s0 = 0.3, s1 = size * 0.7, life = 0.4 })
    		end)
    		if sparks then geyser(cf, 14, pal.seqHot, { speed = size * 1.6, life = dur, spread = 6, size = 0.22, gravity = -1 }) end
    	elseif style == "Dome" then

    		domeBurst(cf, { Color = pal.seqGlass, R0 = size * 0.1, R1 = size * 0.85, Height = 0.75, Dur = dur, A0 = 0.3, Spin = 0.7 })
    		PFPrim.polyFX(cf, { Assembly = true, kind = "hex", r = size * 0.55, W = 0.05, color = pal.seqHot, Dur = dur * 0.9, Draw = 0.3, Spin = -0.8 })
    		geyser(cf, q(12, 6), pal.seqGlass, { speed = size * 0.5, life = dur * 1.2, spread = 70, size = 0.14, gravity = -1.5, drag = 2, tex = TEX.Mote })
    		ringWave(cf, { Color = pal.seqHot, R0 = size * 0.1, R1 = size * 0.8, W0 = size * 0.08, W1 = 0.02, Dur = dur })
    		if sparks then fan(cf, 12, pal.seqHot, { speed = size * 0.9, life = dur, size = 0.2, up = 1.0 }) end
    	elseif style == "Meteor Ring" then

    		local n = q(6, 4)
    		for i = 1, n do
    			local th = i / n * TAU + 0.3
    			local from = (cf * CFrame.new(math.cos(th) * size * 1.15, size * 1.25, math.sin(th) * size * 1.15)).Position
    			PFPrim.cometFX(cf, { from = from, to = cf.Position, T = dur * 0.55, arc = 0.6, color = pal.seqHot, size = 0.42, trailLife = 0.35 })
    		end
    		later(dur * 0.6, function()
    			flipBoom(cf, { size = size * 0.7, life = 0.6, y = 0.8, color = pal.seqGlass })
    			ringWave(cf, { Color = pal.seq, R0 = 0.2, R1 = size * 0.8, W0 = 0.16, W1 = 0.02, Dur = dur * 0.8 })
    		end)
    		if sparks then fan(cf, 16, pal.seqHot, { speed = size * 1.0, life = dur, size = 0.22, r = size * 0.4, up = 0.4 }) end
    	elseif style == "Thunder Step" then

    		PFPrim.crackFX(cf, { N = 5, Len = size * 0.75, W = 0.07, Dur = dur * 0.8, color = pal.seqHot })
    		PFPrim.webFX(cf, { M = q(6, 4), R = size * 0.7, y = 0.35, Dur = dur * 0.55, color = cseq(WHITE, pal.bright), W = 0.09 })
    		flashSprite(cf, { tex = TEX.Glint, color = pal.seqGlass, s0 = 1, s1 = size * 1.2, life = 0.2, y = 0.6 })
    		if sparks then scatter(cf, 16, pal.seqGlass, { speed = size * 1.2, life = dur * 0.6, size = 0.14, gravity = 0, drag = 5, streak = true }) end
    	elseif style == "Bloom" then

    		PFPrim.polyFX(cf, { Assembly = true, kind = "flower", r = size * 0.55, W = size * 0.045, color = pal.seqHot, Dur = dur * 1.15, Draw = 0.55, Spin = 0.5, lift = 0.5 })
    		flashSprite(cf * CFrame.new(0, 0.5, 0), { tex = TEX.Field, color = pal.seqGlass, s0 = 0.3, s1 = size * 0.5, life = 0.5, y = 0 })
    		geyser(cf, q(14, 6), pal.seqGlass, { speed = size * 0.5, life = dur * 1.4, spread = 60, size = 0.13, gravity = -0.5, drag = 1.8, tex = TEX.Mote, y = 0.4 })
    		ringWave(cf, { Color = pal.seq, R0 = size * 0.1, R1 = size * 0.5, W0 = 0.05, W1 = 0.02, Dur = dur, Rise = 0.4 })
    		if sparks then geyser(cf, 12, pal.seqHot, { speed = size * 0.8, life = dur * 1.2, spread = 35, size = 0.18, gravity = -2, drag = 1.5 }) end
    	elseif style == "Crescent" then

    		shockSprite(cf, { tex = TEX.Ring, color = pal.seqHot, s0 = size * 0.2, s1 = size * 1.15, life = dur, a0 = 0.05, z = 0.06 })
    		shockSprite(cf * CFrame.new(size * 0.3, 0.16, -size * 0.18), { tex = TEX.Circle, color = pal.seqDark or cseq(BLACK, BLACK), s0 = size * 0.15, s1 = size * 0.95, life = dur * 0.9, a0 = 0.55, emission = 0, z = 0.05 })
    		arcSpray(cf, { Color = pal.seqHot, N = 5, R0 = size * 0.2, R1 = size * 0.95, W = size * 0.1, Dur = dur * 0.9, Span = 0.24, Tilt1 = RAD(90), Rise = size * 0.55, Spin = 0.8 })
    		if sparks then fan(cf, 12, pal.seqHot, { speed = size, life = dur, size = 0.2, up = 0.7 }) end
    	elseif style == "Gear" then

    		PFPrim.polyFX(cf, { Assembly = true, kind = "gear", r = size * 0.5, W = size * 0.07, color = pal.seq, Dur = dur * 1.2, Draw = 0.4, Spin = 1.1, lift = 0.25 })
    		PFPrim.polyFX(cf * CFrame.new(0, 0.25, 0), { Assembly = true, kind = "ring", r = size * 0.18, W = 0.06, color = pal.seqHot, Dur = dur * 1.2, Draw = 0.2, Spin = -2 })
    		flashSprite(cf * CFrame.new(0, 0.25, 0), { tex = TEX.Glint, color = pal.seqHot, s0 = 0.2, s1 = size * 0.4, life = 0.4 })
    		geyser(cf, q(8, 4), pal.seqFade, { speed = 2, life = 0.9, spread = 50, size = size * 0.1, gravity = 1, drag = 2, tex = TEX.Puff, a0 = 0.4, emission = 0 })
    		if sparks then fan(cf, 12, pal.seqGlass, { speed = size * 0.8, life = dur, size = 0.16, up = 0.2 }) end
    	elseif style == "Glass Break" then

    		PFPrim.crackFX(cf, { N = 7, Len = size * 0.85, W = 0.06, Dur = dur * 1.1, color = pal.seqGlass, dust = false })
    		PFPrim.spikeFX(cf, { N = q(8, 5), Len = size * 0.4, W = 0.14, Dur = dur * 1.2, Up = 0.55, color = pal.seqGlass })
    		shards(cf, { Color = pal.seqGlass, N = 14, Speed = size * 0.9, W = 0.14, Len = size * 0.1, Dur = dur * 1.4, Gravity = -26, Up = 0.5, A0 = 0.1 })
    		for i = 1, 3 do
    			flashSprite(cf * CFrame.new(rnd(-1, 1) * size * 0.4, 0.4, rnd(-1, 1) * size * 0.4), { tex = TEX.Glint, color = Color3.fromHSV(math.random(), 0.5, 1), s0 = 0.1, s1 = 0.7, life = 0.5, rotSpeed = 120 })
    		end
    		if sparks then scatter(cf, 20, pal.seqGlass, { speed = size * 0.7, life = dur, size = 0.13, gravity = -20 }) end
    	elseif style == "Ink Drop" then

    		PFPrim.inkFX(cf, { size = size * 0.42, N = 8, Dur = dur * 1.3, color = pal.seqDark or cseq(BLACK, tint(BLACK, 0.3)) })
    		plate(cf, pal.seqDark or cseq(BLACK, BLACK), { s0 = size * 0.3, s1 = size * 1.1, life = dur * 1.4, a0 = 0.12, count = 2, tex = TEX.Cloud, emission = 0 })
    		geyser(cf, q(8, 4), pal.seqFade, { speed = size * 0.5, life = dur, spread = 60, size = size * 0.12, gravity = -8, tex = TEX.Smoke, a0 = 0.3, emission = 0 })
    		if sparks then scatter(cf, 8, pal.seqHot, { speed = size * 0.5, life = dur * 0.7, size = 0.12 }) end
    	elseif style == "Star Sigil" then

    		PFPrim.polyFX(cf, { Assembly = true, kind = "pentagram", r = size * 0.55, W = 0.055, color = pal.seqHot, Dur = dur * 1.2, Draw = 0.6, Spin = 0.9 })
    		PFPrim.polyFX(cf, { Assembly = true, kind = "star", r = size * 0.34, W = 0.04, color = pal.seqGlass, Dur = dur, Draw = 0.5, Spin = -1.6, lift = 0.14 })
    		PFPrim.runeRingFX(cf, { r = size * 0.62, Dur = dur * 1.2, color = pal.seq, W = 0.04 })
    		geyser(cf, q(10, 5), pal.seqGlass, { speed = size * 0.5, life = dur, spread = 25, size = 0.14, gravity = -1.5, drag = 1.5, tex = TEX.Mote })
    		if sparks then geyser(cf, 10, pal.seqHot, { speed = size * 0.7, life = dur, spread = 30, size = 0.2, gravity = -2 }) end
    	elseif style == "Pulse Grid" then

    		PFPrim.polyFX(cf, { Assembly = true, kind = "grid", r = size * 0.48, W = 0.035, color = pal.seqHot, Dur = dur, Draw = 0.7, z = 0.05 })
    		for i = 1, 4 do
    			local x = (i < 3) and -0.46 or 0.46
    			local z = (i % 2 == 0) and -0.46 or 0.46
    			flashSprite(cf * CFrame.new(x * size, 0.1, z * size), { tex = TEX.Glint, color = pal.seqGlass, s0 = 0.08, s1 = 0.5, life = dur * 0.7, rotSpeed = 100 })
    		end
    		ringWave(cf, { Color = pal.seq, R0 = size * 0.5, R1 = size * 0.56, W0 = 0.04, W1 = 0.02, Dur = dur * 0.6, Delay = dur * 0.45, A0 = 0.2 })
    		if sparks then PFPrim.matrixFX(cf, { R = size * 0.5, cols = q(6, 3), h = 2.2, speed = 7, Dur = dur * 0.7, color = pal.seqGlass }) end
    	elseif style == "Phoenix" then

    		PFPrim.flameWingFX(cf, { size = size * 0.55, Dur = dur, color = cseq(WHITE, pal.bright, pal.base, tint(pal.deep, -0.4)) })
    		column(cf, { Color = cseq(WHITE, pal.bright, pal.base, tint(pal.deep, -0.4)), W0 = size * 0.2, W1 = 0.05, H = size * 1.2, Dur = dur, Texture = TEX.Fire, Speed = 2 })
    		geyser(cf, q(18, 8), cseq(WHITE, pal.bright, pal.base), { speed = size * 1.4, life = dur, size = 0.2, gravity = 2, tex = TEX.Ember, streak = true, spread = 35 })
    		if sparks then geyser(cf, 12, cseq(WHITE, pal.bright), { speed = size * 1.6, life = dur * 0.8, size = 0.16, gravity = 2.5, tex = TEX.Glint, spread = 40 }) end
    	elseif style == "Nova" then

    		flipBoom(cf, { size = size * 0.9, life = 0.7, y = size * 0.25, color = pal.seqGlass })
    		burst(cf, pal, { size = size * 0.12, y = 0.6, sparks = sparks and 26 or 0, puffs = 5 })
    		shockSprite(cf, { tex = TEX.Shock, color = pal.seqHot, s0 = size * 0.2, s1 = size * 1.5, life = dur * 0.7 })
    		ringWave(cf, { Color = pal.seq, R0 = size * 0.1, R1 = size * 0.8, W0 = size * 0.1, W1 = 0.02, Dur = dur })
    	elseif style == "Splash" then

    		ripples(cf, pal, { s0 = size * 0.15, s1 = size * 1.2, life = dur * 1.3, count = 4 })
    		geyser(cf, q(28, 12), cseq(WHITE, pal.bright, pal.base), { speed = size * 2, life = 0.5, spread = 42, size = 0.2, gravity = -40, drag = 0.5, tex = TEX.Drop, streak = true, emission = 0.5 })
    		plate(cf, pal.seqGlass, { s0 = size * 0.4, s1 = size * 1.1, a0 = 0.4, life = dur * 0.6, tex = TEX.Circle })
    		if sparks then scatter(cf, 12, pal.seqGlass, { speed = size * 0.8, life = dur, size = 0.15, gravity = -15, tex = TEX.Glint }) end
    	elseif style == "Stardust" then

    		local a = worldAttach(cf * CFrame.new(0, 0.4, 0))
    		emitter(a, { Texture = TEX.Star, Color = cseq(WHITE, pal.bright, pal.base), Size = nseq(0.1, size * 0.09, 0), Transparency = nseq(0, 0, 1), Lifetime = range(dur * 0.8, dur * 1.4), Speed = range(size * 0.6, size * 1.3), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -6, 0), Drag = 1.5, Rotation = range(-180, 180), RotSpeed = range(-200, 200), ZOffset = 0.2 }):Emit(q(18, 8))
    		emitter(a, { Texture = TEX.Mote, Color = pal.seqGlass, Size = nseq(0.08, 0.14, 0), Transparency = nseq(0.2, 0, 1), Lifetime = range(dur, dur * 2), Speed = range(1, 3), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 0.5, 0), Drag = 2 }):Emit(q(20, 8))
    		Debris:AddItem(a, dur * 2.2)
    		PFPrim.polyFX(cf, { Assembly = true, kind = "star", r = size * 0.4, W = 0.04, color = pal.seqHot, Dur = dur * 0.9, Draw = 0.4, Spin = 1.4 })
    		shockSprite(cf, { tex = TEX.Ring, color = pal.seqHot, s0 = size * 0.2, s1 = size * 1.2, life = dur * 0.8 })
    		if sparks then geyser(cf, 10, pal.seqGlass, { speed = size * 0.9, life = dur, spread = 30, size = 0.16, gravity = -3, tex = TEX.Glint }) end
    	else

    		fan(cf, 24, cseq(pal.bright, pal.base, tint(pal.deep, -0.5)), { speed = size * 0.9, life = dur * 1.6, size = size * 0.14, up = 0.35, tex = TEX.Puff, gravity = 1.5, drag = 2.5, emission = 0.3, spread = 12, r = size * 0.2 })
    		shockSprite(cf, { tex = TEX.Cloud, color = pal.seqFade, s0 = size * 0.3, s1 = size * 1.4, life = dur * 1.2, a0 = 0.5, rotSpeed = 40, emission = 0.3 })
    		ringWave(cf, { Color = pal.seqHot, R0 = size * 0.15, R1 = size * 0.9, W0 = size * 0.05, W1 = 0.02, Dur = dur * 0.9, A0 = 0.2 })
    		if sparks then scatter(cf, 10, pal.seqHot, { speed = size * 0.6, life = dur * 0.8, size = 0.16, gravity = -4 }) end
    	end
    end

    function Jump.play(force)
    	local cfg = S.Jump
    	if not cfg.Enabled or not alive() then return end
    	local now = os.clock()
    	if not force and now - lastJump < 0.15 then return end
    	local pal = paletteFor("Jump", cfg)
    	local size, dur = cfg.Size, cfg.Duration
    	local cf = groundAt(Char.root.Position, Char.model, 3)
    	local style = cfg.Random and pick(Jump.Styles) or cfg.Style
    	if cfg.Chain then
    		jumpChain = (now - lastJump < 1.6) and math.min(jumpChain + 1, 6) or 1
    		size = size * (1 + (jumpChain - 1) * 0.16)
    		if jumpChain >= 3 then
    			ringWave(cf, { Color = pal.seqHot, R0 = size * 0.2, R1 = size * 1.3, W0 = 0.12, W1 = 0.02, Dur = dur * 1.2, Rise = 0.5 * jumpChain, A0 = 0.3 })
    		end
    	end
    	lastJump = now
    	Bus.emit("jump", cf, pal, size)
    	if cfg.Flash then
    		glint(cf, pal.bright, size * 1.5, 6, dur * 0.6)
    		shockSprite(cf, { tex = TEX.Shock, color = pal.seqHot, s0 = size * 0.2, s1 = size * 1.1, life = dur * 0.5, a0 = 0.1 })
    		flashSprite(cf, { tex = TEX.Glint, color = pal.seqGlass, s0 = 0.3, s1 = size * 0.7, life = 0.22, y = 0.4 })
    	end
    	jumpStyle(style, cf, pal, size, dur, cfg.Sparks)
    	if cfg.Column then column(cf, { Color = pal.seqFade, W0 = size * 0.12, W1 = 0.02, H = size * 2.2, Dur = dur * 1.3 }) end
    	if cfg.Echo then
    		later(dur * 0.55, function()
    			if not alive() then return end
    			ringWave(groundAt(Char.root.Position, Char.model, 3), { Color = pal.seqFade, R0 = size * 0.1, R1 = size * 0.6, W0 = size * 0.05, W1 = 0.02, Dur = dur * 0.7, A0 = 0.3 })
    		end)
    	end
    end

    function Jump.air()
    	local cfg = S.Jump
    	if not cfg.Enabled or not cfg.DoubleAir or not alive() then return end
    	local pal = paletteFor("Jump", cfg)
    	local cf = CFrame.new(Char.root.Position - Vector3.new(0, 2.5, 0))
    	ringWave(cf, { Color = pal.seqHot, R0 = 0.3, R1 = cfg.Size * 0.45, W0 = 0.2, W1 = 0.02, Dur = 0.4 })
    	scatter(cf, 8, pal.seqHot, { speed = 4, life = 0.4, size = 0.15, gravity = -4 })
    end

    function Jump.bind()
    	if Jump.jumpConn then Jump.jumpConn:Disconnect() Jump.jumpConn = nil end
    	if Jump.stateConn then Jump.stateConn:Disconnect() Jump.stateConn = nil end
    	local hum = Char.humanoid
    	if not hum then return end
    	Jump.jumpConn = hum.Jumping:Connect(function(active)
    		if not active then return end
    		local okA, air = pcall(function() return hum.FloorMaterial == Enum.Material.Air end)
    		if okA and air and os.clock() - lastJump > 0.25 then Jump.air() else Jump.play() end
    	end)
    end
    function Jump.stop()
    	if Jump.jumpConn then Jump.jumpConn:Disconnect() Jump.jumpConn = nil end
    	Jump:clear()
    end

    local Wings = defineModule("Wings", {
    	Enabled = false, Style = "Archangel", Color = Color3.fromRGB(255, 170, 70),
    	Scale = 1, Droop = 0, Flap = true, Glow = true, Dust = true, Dynamic = true, TipTrails = false,
    	Prop = false, PropStyle = "Halo", PropSize = 1, PropSpeed = 1, PropRing = 2, PropGlow = true,
    })
    Wings.Styles = {
    	"Seraph", "Archangel", "Wyvern", "Nocturne", "Hummingbird", "Stained Glass", "Inferno", "Abyss", "Pixie",
    	"Mantis", "Tempest", "Prism", "Sakura", "Skeletal", "Solaris", "Glacier", "Wraith",
    	"Aurora Veil", "Ember Moth",
    }

    local function wingSpec(style, pal)
    	local cfgPalette = S.Wings
    	local d = RAD
    	local spec = { rows = {}, bones = nil, flapAmp = 0.12, flapSpeed = 2.6 }
    	if style == "Seraph" then

    		local fire = cseq(WHITE, pal.bright, pal.base, tint(pal.deep, -0.45))
    		spec.rows = {
    			{ n = 9, s0 = d(66), s1 = d(-14), sw0 = d(6), sw1 = d(42), l0 = 4.2, l1 = 6.6, w0 = 0.9, w1 = 0.12, bend = d(15), curve = 0.34, color = fire, texture = TEX.Fire, texSpeed = -3, alpha = 0.06, jitter = true },
    			{ n = 7, s0 = d(78), s1 = d(26), sw0 = d(3), sw1 = d(32), l0 = 2.6, l1 = 4.0, w0 = 0.58, w1 = 0.08, bend = d(11), curve = 0.28, color = fire, texture = TEX.Fire, texSpeed = -2, alpha = 0.14, jitter = true },
    			{ n = 6, s0 = d(36), s1 = d(-26), sw0 = d(12), sw1 = d(44), l0 = 2.0, l1 = 3.2, w0 = 0.48, w1 = 0.07, bend = d(9), curve = 0.26, color = pal.seq, alpha = 0.2 },
    			{ n = 4, s0 = d(-24), s1 = d(-52), sw0 = d(18), sw1 = d(40), l0 = 1.6, l1 = 2.6, w0 = 0.6, w1 = 0.1, bend = d(22), curve = 0.42, color = fire, texture = TEX.Fire, texSpeed = -1.5, alpha = 0.18, jitter = true },
    		}
    		spec.flapAmp = 0.1
    		spec.flapSpeed = 1.7
    		spec.dust = { tex = TEX.Ember, size = 0.3, rate = 18, color = fire, accel = Vector3.new(0, 3.5, 0), a0 = 0.12, speed = 1.6, streak = true, wind = true }
    	elseif style == "Archangel" then

    		spec.rows = {
    			{ n = 10, s0 = d(62), s1 = d(-10), sw0 = d(5), sw1 = d(38), l0 = 4.0, l1 = 6.4, w0 = 0.6, w1 = 0.08, bend = d(10), curve = 0.3, color = cseq(WHITE, pal.bright, pal.base), texture = TEX.Spark, texSpeed = -1.5, alpha = 0.1 },
    			{ n = 7, s0 = d(74), s1 = d(20), sw0 = d(2), sw1 = d(28), l0 = 2.6, l1 = 4.0, w0 = 0.45, w1 = 0.06, bend = d(7), curve = 0.24, color = cseq(pal.bright, pal.base), alpha = 0.16 },
    			{ n = 5, s0 = d(28), s1 = d(-30), sw0 = d(12), sw1 = d(44), l0 = 1.7, l1 = 2.8, w0 = 0.4, w1 = 0.06, bend = d(8), curve = 0.26, color = pal.seq, alpha = 0.2 },
    		}
    		spec.flapAmp = 0.09
    		spec.flapSpeed = 1.4
    		spec.dust = { tex = TEX.Glint, size = 0.16, rate = 10, color = cseq(WHITE, pal.bright), accel = Vector3.new(0, 2.4, 0), a0 = 0.1 }
    	elseif style == "Wyvern" then

    		spec.bones = { n = 5, s0 = d(62), s1 = d(-22), sw0 = d(6), sw1 = d(34), l0 = 3.0, l1 = 5.8, w = 0.15, color = cseq(pal.bright, pal.base), mem = cseq(pal.base, pal.deep), memAlpha = 0.25 }
    		spec.rows = { { n = 4, s0 = d(-20), s1 = d(-48), sw0 = d(30), sw1 = d(50), l0 = 1.2, l1 = 2.0, w0 = 0.22, w1 = 0.03, bend = d(22), curve = 0.4, color = pal.seq, alpha = 0.2 } }
    		spec.flapAmp = 0.17
    		spec.flapSpeed = 1.9
    		spec.dust = { tex = TEX.Ember, size = 0.3, rate = 8, color = cseq(pal.bright, pal.base, pal.deep), accel = Vector3.new(0, 2, 0), a0 = 0.2, streak = true }
    	elseif style == "Nocturne" then

    		spec.bones = { n = 7, s0 = d(58), s1 = d(-38), sw0 = d(8), sw1 = d(42), l0 = 2.8, l1 = 5.4, w = 0.09, color = cseq(pal.bright, pal.base, pal.deep), mem = cseq(pal.base, pal.deep, BLACK), memAlpha = 0.16 }
    		spec.flapAmp = 0.22
    		spec.flapSpeed = 1.9
    		spec.dust = { tex = TEX.Star, size = 0.14, rate = 7, color = cseq(WHITE, pal.bright), accel = Vector3.new(0, -0.8, 0), spin = true }
    	elseif style == "Hummingbird" then

    		spec.rows = {
    			{ n = 5, s0 = d(45), s1 = d(5), sw0 = d(6), sw1 = d(26), l0 = 1.5, l1 = 2.5, w0 = 0.34, w1 = 0.04, bend = d(6), curve = 0.22, color = cseq(pal.bright, pal.base, pal.bright), texture = TEX.Spark, texSpeed = 4, alpha = 0.12 },
    			{ n = 4, s0 = d(62), s1 = d(24), sw0 = d(2), sw1 = d(18), l0 = 0.9, l1 = 1.5, w0 = 0.28, w1 = 0.04, bend = d(4), curve = 0.2, color = pal.seqHot, alpha = 0.1 },
    		}
    		spec.flapAmp = 0.5
    		spec.flapSpeed = 15
    		spec.dust = { tex = TEX.Spark, size = 0.1, rate = 22, color = pal.seqHot, speed = 3 }
    	elseif style == "Stained Glass" then

    		spec.bones = { n = 6, s0 = d(65), s1 = d(-15), sw0 = d(4), sw1 = d(30), l0 = 3.2, l1 = 5.2, w = 0.13, color = cseq(tint(pal.deep, -0.4)), mem = cseq(Color3.fromHSV(0.0, 0.7, 1), Color3.fromHSV(0.15, 0.7, 1), Color3.fromHSV(0.45, 0.7, 1), Color3.fromHSV(0.62, 0.7, 1), Color3.fromHSV(0.8, 0.7, 1)), memAlpha = 0.3, memSegs = 4 }
    		spec.flapAmp = 0.06
    		spec.flapSpeed = 1.2
    		spec.dust = { tex = TEX.Glint, size = 0.18, rate = 8, color = cseq(WHITE, pal.bright) }
    	elseif style == "Inferno" then

    		local fire = cseq(WHITE, pal.bright, pal.base, tint(pal.deep, -0.5))
    		spec.rows = {
    			{ n = 8, s0 = d(60), s1 = d(-12), sw0 = d(8), sw1 = d(40), l0 = 3.2, l1 = 5.4, w0 = 0.75, w1 = 0.05, bend = d(18), curve = 0.38, color = fire, texture = TEX.Fire, texSpeed = -2.5, alpha = 0.08, jitter = true },
    			{ n = 6, s0 = d(70), s1 = d(18), sw0 = d(2), sw1 = d(30), l0 = 1.8, l1 = 3.0, w0 = 0.5, w1 = 0.05, bend = d(14), curve = 0.3, color = fire, texture = TEX.Fire, texSpeed = -2, alpha = 0.2, jitter = true },
    		}
    		spec.flapAmp = 0.11
    		spec.flapSpeed = 2.2
    		spec.dust = { tex = TEX.Ember, size = 0.3, rate = 20, color = fire, accel = Vector3.new(0, 4, 0), a0 = 0.12, speed = 1.6, streak = true }
    	elseif style == "Abyss" then

    		spec.bones = { n = 7, s0 = d(70), s1 = d(-40), sw0 = d(0), sw1 = d(36), l0 = 2.4, l1 = 6.2, w = 0.09, color = cseq(pal.bright, pal.base), mem = cseq(BLACK, pal.deep, BLACK), memAlpha = 0.12, memTex = TEX.Smoke, memSpeed = 0.4 }
    		spec.flapAmp = 0.09
    		spec.flapSpeed = 0.8
    		spec.dust = { tex = TEX.Smoke, size = 0.9, rate = 8, color = cseq(pal.deep, BLACK), emission = 0.3, a0 = 0.4, accel = Vector3.new(0, -1.5, 0) }
    	elseif style == "Pixie" then

    		spec.bones = { n = 3, s0 = d(50), s1 = d(15), sw0 = d(4), sw1 = d(20), l0 = 1.6, l1 = 2.6, w = 0.06, color = pal.seqGlass, mem = cseq(pal.bright, pal.base, pal.bright), memAlpha = 0.45 }
    		spec.rows = { { n = 3, s0 = d(-8), s1 = d(-40), sw0 = d(10), sw1 = d(28), l0 = 1.2, l1 = 2.0, w0 = 0.55, w1 = 0.1, bend = d(8), curve = 0.25, color = pal.seqGlass, alpha = 0.4 } }
    		spec.flapAmp = 0.32
    		spec.flapSpeed = 10
    		spec.dust = { tex = TEX.Star, size = 0.14, rate = 16, color = cseq(WHITE, pal.bright), accel = Vector3.new(0, -1, 0), spin = true }
    	elseif style == "Mantis" then

    		spec.bones = { n = 2, s0 = d(38), s1 = d(10), sw0 = d(10), sw1 = d(18), l0 = 4.8, l1 = 5.8, w = 0.07, color = cseq(pal.bright, pal.base), mem = cseq(pal.bright, pal.base), memAlpha = 0.55, memSegs = 4 }
    		spec.rows = { { n = 2, s0 = d(-5), s1 = d(-20), sw0 = d(14), sw1 = d(22), l0 = 3.8, l1 = 4.6, w0 = 0.9, w1 = 0.12, bend = d(4), curve = 0.15, color = pal.seqGlass, alpha = 0.5 } }
    		spec.flapAmp = 0.26
    		spec.flapSpeed = 11
    		spec.dust = { tex = TEX.Spark, size = 0.08, rate = 6, color = pal.seqHot }
    	elseif style == "Tempest" then

    		spec.rows = {
    			{ n = 6, s0 = d(62), s1 = d(-14), sw0 = d(8), sw1 = d(38), l0 = 3.0, l1 = 5.2, w0 = 0.18, w1 = 0.04, bend = d(24), curve = 0.5, color = cseq(WHITE, pal.bright), jitter = true, texture = TEX.Spark, texSpeed = 6 },
    			{ n = 6, s0 = d(62), s1 = d(-14), sw0 = d(8), sw1 = d(38), l0 = 3.0, l1 = 5.2, w0 = 0.6, w1 = 0.05, bend = d(-16), curve = 0.5, color = pal.seqFade, alpha = 0.55, z = -0.02 },
    		}
    		spec.flapAmp = 0.14
    		spec.flapSpeed = 3.4
    		spec.bolts = true
    		spec.dust = { tex = TEX.Spark, size = 0.18, rate = 14, color = cseq(WHITE, pal.bright), speed = 4 }
    	elseif style == "Prism" then

    		spec.rows = {}
    		for i = 1, 6 do
    			local h = (i - 1) / 6
    			table.insert(spec.rows, { n = 1, s0 = d(70 - i * 15), s1 = d(70 - i * 15), sw0 = d(6 + i * 5), sw1 = d(6 + i * 5), l0 = 4.8 - i * 0.25, l1 = 4.8 - i * 0.25, w0 = 0.8, w1 = 0.08, bend = d(10), curve = 0.3, color = cseq(WHITE, Color3.fromHSV(h, 0.8, 1), Color3.fromHSV(h + 0.1, 0.9, 0.7)), alpha = 0.05 })
    		end
    		spec.flapAmp = 0.1
    		spec.dust = { tex = TEX.Star, size = 0.15, rate = 12, color = cseq(Color3.fromHSV(0, 0.7, 1), Color3.fromHSV(0.33, 0.7, 1), Color3.fromHSV(0.66, 0.7, 1)), spin = true }
    	elseif style == "Sakura" then

    		local pink = cseq(WHITE, pal.bright, pal.base)
    		spec.rows = {
    			{ n = 9, s0 = d(56), s1 = d(-6), sw0 = d(8), sw1 = d(40), l0 = 2.7, l1 = 4.8, w0 = 0.6, w1 = 0.4, bend = d(10), curve = 0.3, color = pink, alpha = 0.08 },
    			{ n = 6, s0 = d(70), s1 = d(24), sw0 = d(4), sw1 = d(28), l0 = 1.5, l1 = 2.5, w0 = 0.5, w1 = 0.34, bend = d(8), curve = 0.3, color = pink, alpha = 0.18 },
    		}
    		spec.flapAmp = 0.08
    		spec.flapSpeed = 1.6
    		spec.dust = { tex = TEX.Heart, size = 0.22, rate = 12, color = pink, accel = Vector3.new(0, -2.5, 0), a0 = 0.1, speed = 1.5, emission = 0.6, spin = true, wind = true }
    	elseif style == "Skeletal" then

    		spec.bones = { n = 6, s0 = d(64), s1 = d(-28), sw0 = d(6), sw1 = d(36), l0 = 2.4, l1 = 5.4, w = 0.17, color = cseq(WHITE, pal.bright, pal.base), mem = cseq(pal.deep), memAlpha = 0.92 }
    		spec.rows = { { n = 6, s0 = d(64), s1 = d(-28), sw0 = d(6), sw1 = d(36), l0 = 0.6, l1 = 1.0, w0 = 0.3, w1 = 0.05, bend = d(60), curve = 0.5, color = cseq(WHITE, pal.bright), alpha = 0.1 } }
    		spec.flapAmp = 0.12
    		spec.flapSpeed = 1.5
    		spec.dust = { tex = TEX.Smoke, size = 0.4, rate = 5, color = cseq(pal.bright, pal.deep), emission = 0.4, a0 = 0.5, accel = Vector3.new(0, -1, 0) }
    	elseif style == "Solaris" then

    		spec.rows = {}
    		for i = 1, 8 do
    			local a = 82 - i * 17
    			table.insert(spec.rows, { n = 1, s0 = d(a), s1 = d(a), sw0 = d(12), sw1 = d(12), l0 = 5.2, l1 = 5.2, w0 = 0.1, w1 = 0.65, bend = d(0), curve = 0.05, color = cseq(WHITE, pal.bright, pal.base), alpha = 0.14, emission = 1 })
    		end
    		spec.flapAmp = 0.05
    		spec.flapSpeed = 0.7
    		spec.dust = { tex = TEX.Glint, size = 0.22, rate = 10, color = cseq(WHITE, pal.bright), accel = Vector3.new(0, 1.5, 0) }
    	elseif style == "Glacier" then

    		spec.rows = {
    			{ n = 6, s0 = d(62), s1 = d(-16), sw0 = d(8), sw1 = d(38), l0 = 3.3, l1 = 5.2, w0 = 0.5, w1 = 0.02, bend = d(3), curve = 0.08, color = cseq(WHITE, Color3.fromRGB(200, 240, 255), pal.bright), alpha = 0.1 },
    			{ n = 12, s0 = d(62), s1 = d(-16), sw0 = d(8), sw1 = d(38), l0 = 0.8, l1 = 1.7, w0 = 0.13, w1 = 0.02, bend = d(55), curve = 0.3, color = cseq(WHITE, Color3.fromRGB(170, 225, 255)), alpha = 0.15 },
    		}
    		spec.flapAmp = 0.04
    		spec.flapSpeed = 1.0
    		spec.dust = { tex = TEX.Star, size = 0.13, rate = 12, color = cseq(WHITE, Color3.fromRGB(190, 235, 255)), accel = Vector3.new(0, -1.5, 0), spin = true, wind = true }
    	elseif style == "Wraith" then

    		spec.rows = {
    			{ n = 6, s0 = d(60), s1 = d(-15), sw0 = d(10), sw1 = d(45), l0 = 3.3, l1 = 5.4, w0 = 0.7, w1 = 0.12, bend = d(12), curve = 0.34, color = cseq(pal.base, pal.deep), alpha = 0.35, texture = TEX.Smoke, texSpeed = -1 },
    			{ n = 6, s0 = d(60), s1 = d(-15), sw0 = d(10), sw1 = d(45), l0 = 3.3, l1 = 5.4, w0 = 0.15, w1 = 0.02, bend = d(12), curve = 0.32, color = cseq(WHITE, pal.bright), alpha = 0.2, z = 0.05 },
    		}
    		spec.flapAmp = 0.1
    		spec.dust = { tex = TEX.Puff, size = 0.8, rate = 9, color = cseq(pal.base, pal.deep), emission = 0.5, a0 = 0.4, accel = Vector3.new(0, 1, 0) }
    	elseif style == "Aurora Veil" then

    		local veil = cseq(pal.bright, pal.base, Color3.fromHSV((baseHue(cfgPalette) + 0.25) % 1, 0.8, 1), pal.deep)
    		spec.rows = {
    			{ n = 4, s0 = d(70), s1 = d(-10), sw0 = d(6), sw1 = d(36), l0 = 3.6, l1 = 6.0, w0 = 1.35, w1 = 0.4, bend = d(8), curve = 0.3, color = veil, alpha = 0.42, texture = TEX.Smoke, texSpeed = 0.6, jitter = true },
    			{ n = 4, s0 = d(70), s1 = d(-10), sw0 = d(6), sw1 = d(36), l0 = 3.6, l1 = 6.0, w0 = 0.12, w1 = 0.02, bend = d(8), curve = 0.3, color = cseq(WHITE, pal.bright), alpha = 0.2, z = 0.04 },
    		}
    		spec.flapAmp = 0.06
    		spec.flapSpeed = 0.9
    		spec.dust = { tex = TEX.Mote, size = 0.12, rate = 14, color = veil, accel = Vector3.new(0, 0.6, 0), speed = 0.6, wind = true }
    	else

    		spec.rows = {
    			{ n = 2, s0 = d(48), s1 = d(-6), sw0 = d(8), sw1 = d(24), l0 = 3.4, l1 = 4.2, w0 = 2.3, w1 = 0.8, bend = d(6), curve = 0.2, color = cseq(pal.base, pal.deep, tint(pal.deep, -0.5)), alpha = 0.3, texture = TEX.Puff, texSpeed = 0 },
    			{ n = 2, s0 = d(48), s1 = d(-6), sw0 = d(8), sw1 = d(24), l0 = 2.2, l1 = 2.8, w0 = 1.0, w1 = 0.5, bend = d(6), curve = 0.2, color = cseq(WHITE, pal.bright, pal.base), alpha = 0.35, texture = TEX.Ring, z = 0.03 },
    		}
    		spec.flapAmp = 0.36
    		spec.flapSpeed = 4.5
    		spec.dust = { tex = TEX.Ember, size = 0.16, rate = 14, color = cseq(WHITE, pal.bright, pal.base, pal.deep), accel = Vector3.new(0, -1.5, 0), speed = 1, streak = true, wind = true }
    	end
    	return spec
    end

    local PROP_RING_STYLES = {
    	"Halo", "Rune Wheel", "Arc Reactor", "Solar Flare", "Vortex", "Turbo",
    }

    local function makePropRing(torso, cfg, pal, scale, nRings)

    	local style  = cfg.PropStyle or "Halo"
    	local R      = 1.85 * (cfg.PropSize or 1)
    	local spd    = (cfg.PropSpeed or 1) * 2.4
    	local obj    = { loops = {}, parts = {}, mov = {}, rim = {} }
    	local clock  = 0

    	local hot = cseq(WHITE, pal.bright, pal.base)
    	local soft = pal.seqFade
    	local coreGlow = pal.bright

    	local cy    = (Char.r6 and 1.05 or 0.6)
    	local backZ = (Char.r6 and 0.95 or 0.8)
    	local base  = CFrame.new(0, cy, backZ) * CFrame.Angles(math.pi / 2, 0, 0)
    	local basePos = Vector3.new(0, cy, backZ)

    	local function mkPart(o)
    		o = o or {}
    		local p = Instance.new("Part")
    		p.Name = o.name or "PF_PropCore"
    		p.Anchored = true
    		p.CanCollide = false
    		p.CanQuery = false
    		p.CanTouch = false
    		p.CastShadow = false
    		p.TopSurface = Enum.SurfaceType.Smooth
    		p.BottomSurface = Enum.SurfaceType.Smooth
    		p.Material = o.mat or Enum.Material.Neon
    		p.Color = o.color or coreGlow
    		p.Shape = o.shape or Enum.PartType.Ball
    		p.Size = o.size or Vector3.new(0.3, 0.3, 0.3)
    		p.Locked = true
    		p.Parent = torso
    		obj.parts[#obj.parts + 1] = { p = p, cf = o.cf or CFrame.new() }
    		if o.recolor ~= false then obj.rim[#obj.rim + 1] = p end
    		Wings:keep(p)
    		return p
    	end

    	local function ring(r, w, col, o)
    		o = o or {}
    		local l = makeLoop(torso, base, r, {
    			Color = col or hot,
    			Width = w,
    			Alpha = o.alpha or 0,
    			Segments = o.seg or 18,
    			N = o.N or 12,
    			Texture = o.tex or "",
    			TextureMode = o.tex and Enum.TextureMode.Wrap or Enum.TextureMode.Stretch,
    			TextureLength = o.texLen or 1,
    			TextureSpeed = o.texSpeed or 0,
    			LightEmission = 1,
    			Name = "PF_PropRing",
    		})
    		obj.loops[#obj.loops + 1] = l
    		obj.rim[#obj.rim + 1] = l
    		Wings:keep(l)
    		return l
    	end

    	local sparks = {}
    	local function orbit(r, n, col, rk, dir, tube)
    		rk = rk or 0.12
    		tube = tube or 0.09
    		local grp = { r = r * rk, spd = (dir or 1) * spd * 0.5, ph = math.random() * TAU, items = {} }
    		for i = 1, n do
    			local p = mkPart({ color = col or WHITE, name = "PF_PropSpark", size = Vector3.new(tube, tube, tube * 0.6), cf = CFrame.new(basePos) })
    			grp.items[i] = { p = p, off = (i - 1) / n * TAU }
    		end
    		obj.mov[#obj.mov + 1] = grp
    		return grp
    	end

    	local function core(sizeK)
    		local k = sizeK or 1
    		mkPart({ name = "PF_PropCore", color = coreGlow, size = Vector3.new(0.26 * k, 0.26 * k, 0.26 * k), cf = CFrame.new(basePos) })
    		local inner = makeLoop(torso, base, R * 0.34 * k, {
    			Color = cseq(WHITE, pal.bright), Width = 0.02, Alpha = 0.15,
    			Segments = 10, N = 10, LightEmission = 1, Name = "PF_PropCoreRing",
    		})
    		obj.loops[#obj.loops + 1] = inner
    		obj.rim[#obj.rim + 1] = inner
    		Wings:keep(inner)
    	end

    	if style == "Arc Reactor" then

    		ring(R, 0.16, hot, {})
    		ring(R * 0.72, 0.06, cseq(WHITE, pal.bright), { alpha = 0.1 })
    		core(1)
    		orbit(R, 3, WHITE)
    	elseif style == "Solar Flare" then
    		ring(R, 0.14, cseq(WHITE, pal.bright, pal.base), { tex = TEX.Fire, texLen = 1.2, texSpeed = 1.2 })
    		ring(R * 0.6, 0.05, hot, { alpha = 0.08 })
    		core(0.9)
    		orbit(R, 4, WHITE)
    	elseif style == "Vortex" then
    		ring(R, 0.14, soft, {})
    		ring(R * 0.9, 0.05, hot, { alpha = 0.2, tex = TEX.Swirl, texLen = 0.8, texSpeed = -0.8 })
    		core(0.8)
    		orbit(R, 4, WHITE, 0.7)
    	elseif style == "Turbo" then
    		ring(R, 0.15, hot, {})
    		ring(R * 0.8, 0.05, cseq(WHITE, pal.bright), { alpha = 0.12 })
    		core(1)
    		orbit(R, 5, WHITE, 0.55, -1)
    	elseif style == "Rune Wheel" then
    		ring(R, 0.13, hot, { tex = TEX.Spark, texLen = 0.5, texSpeed = 0.6 })
    		ring(R * 0.85, 0.05, soft, { alpha = 0.15 })
    		core(0.9)
    		orbit(R, 3, WHITE)
    	else
    		ring(R, 0.16, hot, {})
    		ring(R * 1.06, 0.05, soft, { alpha = 0.35 })
    		core(1)
    		orbit(R, 2, WHITE)
    	end

    	if (nRings or 1) >= 2 then
    		ring(R * 0.8, 0.08, soft, { alpha = 0.2 })
    		orbit(R * 0.8, 2, WHITE, 0.9, -1)
    	end

    	local glowAt = attach(torso, CFrame.new(basePos.x, basePos.y - 0.05, basePos.z + 0.1), "PF_PropGlowP")
    	Wings:keep(glowAt)
    	local haloE = emitter(glowAt, {
    		Enabled = true, Rate = q(5, 3), Texture = TEX.Ring, Color = pal.seqFade,
    		Size = nseq(R * 2.05, R * 2.15), Transparency = nseq(0.86, 0.92),
    		Lifetime = range(0.5), Speed = range(0), LockedToPart = true,
    		RotSpeed = range(spd), ZOffset = 0.02, LightEmission = 1,
    	})
    	Wings:keep(haloE)
    	obj.haloE = haloE
    	if cfg.PropGlow ~= false then
    		local gl = attach(torso, CFrame.new(basePos.x, basePos.y, basePos.z + 0.15), "PF_PropGlowL")
    		Wings:keep(gl)
    		local l = light(gl, pal.base, 6 * (0.7 + 0.3 * (cfg.PropSize or 1)), 0.9)
    		Wings:keep(l)
    		obj.glowLight = l
    	end

    	local W0 = torso.CFrame
    	for _, s in ipairs(obj.parts) do s.p.CFrame = W0 * s.cf end

    	function obj.update(dt, speedMul)
    		if not torso or not torso.Parent then return end
    		local W = torso.CFrame
    		if not W then return end
    		clock = clock + dt

    		for _, s in ipairs(obj.parts) do s.p.CFrame = W * s.cf end

    		for _, g in ipairs(obj.mov) do
    			g.ph = g.ph + dt * g.spd * (speedMul or 1)
    			for _, it in ipairs(g.items) do
    				local a = g.ph + it.off
    				it.p.CFrame = W * base * CFrame.new(math.cos(a) * g.r, math.sin(a) * g.r, 0)
    			end
    		end

    		if obj.haloE then
    			local br = 0.86 + 0.05 * math.sin(clock * 2.2)
    			obj.haloE.Transparency = NumberSequence.new(br, br + 0.06)
    		end
    		if obj.glowLight then
    			obj.glowLight.Brightness = 0.65 + 0.3 * (0.5 + 0.5 * math.sin(clock * 2.4))
    		end
    	end

    	function obj:color(p)
    		for _, l in ipairs(self.loops) do l:color(cseq(p.bright, p.base)) end
    		for _, part in ipairs(self.rim) do
    			if typeof(part) ~= "table" and part:IsA("Part") then part.Color = p.bright end
    		end
    	end
    	return obj
    end
    function Wings.build()
    	Wings:clear()
    	if not S.Wings.Enabled or not alive() then return end
    	local cfg = S.Wings
    	local pal = paletteFor("Wings", cfg)
    	local spec = wingSpec(cfg.Style, pal)
    	local scale = cfg.Scale
    	local droop = RAD(cfg.Droop or 0)
    	local torso = Char.torso
    	local baseY = Char.r6 and 0.6 or 0.35
    	local baseZ = Char.r6 and 0.55 or 0.45
    	local plumes, membranes, tips = {}, {}, {}

    	for side = -1, 1, 2 do

    		for ri, row in ipairs(spec.rows) do
    			for i = 1, row.n do
    				local t = (row.n == 1) and 0 or (i - 1) / (row.n - 1)
    				local f = makePlume(torso, {
    					side = side, origin = Vector3.new(side * 0.25, baseY + (ri - 1) * 0.1, baseZ),
    					spread = lerp(row.s0, row.s1, t), sweep = lerp(row.sw0, row.sw1, t),
    					len = lerp(row.l0, row.l1, math.sin(t * math.pi * 0.7)) * scale,
    					w0 = row.w0 * scale, w1 = row.w1 * scale, bend = row.bend, curve = row.curve,
    					alpha = row.alpha, texture = row.texture, texSpeed = row.texSpeed, z = row.z, emission = row.emission,
    				})
    				f.beam.Color = row.color
    				f.phase = t * 0.9 + ri * 0.4
    				f.jitter = row.jitter
    				f.rowIndex = ri
    				f:pose(0, droop, 0)
    				Wings:keep(f)
    				table.insert(plumes, f)
    				if ri == 1 and (i == 1 or i == row.n) then table.insert(tips, f.tip) end
    			end
    		end

    		local bs = spec.bones
    		if bs then
    			local boneList = {}
    			for i = 1, bs.n do
    				local t = (bs.n == 1) and 0 or (i - 1) / (bs.n - 1)
    				local f = makePlume(torso, {
    					side = side, origin = Vector3.new(side * 0.25, baseY, baseZ),
    					spread = lerp(bs.s0, bs.s1, t), sweep = lerp(bs.sw0, bs.sw1, t),
    					len = lerp(bs.l0, bs.l1, math.sin(t * math.pi * 0.62)) * scale,
    					w0 = bs.w * scale, w1 = bs.w * 0.5 * scale, bend = RAD(6), curve = 0.15,
    					alpha = bs.alpha or 0.05, segments = 4,
    				})
    				f.beam.Color = bs.color
    				f.phase = t * 0.8
    				f.rowIndex = 1
    				f.mid = attach(torso, CFrame.new(), "PF_WingMid")
    				Wings:keep(f.mid)
    				f:pose(0, droop, 0)
    				Wings:keep(f)
    				table.insert(plumes, f)
    				table.insert(boneList, f)
    				if i == 1 then table.insert(tips, f.tip) end
    			end
    			for i = 1, #boneList - 1 do
    				local a, b = boneList[i], boneList[i + 1]
    				local mb = beam(a.mid, b.mid, {
    					FaceCamera = false, Segments = bs.memSegs or 2, Color = bs.mem, Transparency = nseq(bs.memAlpha or 0.3),
    					Texture = bs.memTex or "", TextureMode = Enum.TextureMode.Wrap, TextureLength = 2, TextureSpeed = bs.memSpeed or 0,
    					Width0 = a.spec.len, Width1 = b.spec.len, LightEmission = 0.8, ZOffset = -0.02,
    				})
    				table.insert(membranes, { a = a, b = b, beam = mb })
    			end
    		end
    	end

    	local function poseMembranes()
    		for _, m in ipairs(membranes) do
    			local sa, sb = m.a.spec, m.b.spec
    			local da = (m.a.tip.CFrame.Position - sa.origin)
    			local db = (m.b.tip.CFrame.Position - sb.origin)
    			local pa = sa.origin + da * 0.5
    			local pb = sb.origin + db * 0.5
    			local x = pb - pa
    			if x.Magnitude < 1e-3 then x = Vector3.zAxis else x = x.Unit end
    			local function frame(p, boneDir)
    				local y = boneDir.Unit
    				y = (y - x * x:Dot(y))
    				if y.Magnitude < 1e-3 then y = Vector3.yAxis else y = y.Unit end
    				return CFrame.fromMatrix(p, x, y, x:Cross(y))
    			end
    			m.a.mid.CFrame = frame(pa, da)
    			m.b.mid.CFrame = frame(pb, db)
    			m.beam.Width0 = da.Magnitude
    			m.beam.Width1 = db.Magnitude
    		end
    	end
    	poseMembranes()

    	local bolts = {}
    	if spec.bolts then
    		for i = 1, #tips - 1 do
    			local b = makeBolt(torso, { K = 5, Width = 0.1, Color = pal.seqGlass })
    			Wings:keep(b)
    			bolts[i] = { bolt = b, a = tips[i], b = tips[i + 1] }
    		end
    	end

    	if cfg.Dust and spec.dust then
    		local d = spec.dust
    		for _, tip in ipairs(tips) do
    			local e = emitter(tip, {
    				Enabled = true, Rate = q(d.rate, 1) * 0.6, Texture = d.tex, Color = d.color,
    				Size = nseq(d.size, d.size * 0.6, 0), Transparency = nseq(d.a0 or 0, 1),
    				Lifetime = range(0.4, 1.0), Speed = range(d.speed or 1.2), SpreadAngle = Vector2.new(180, 180),
    				Acceleration = d.accel or Vector3.new(0, -2, 0), Drag = 1.5, LightEmission = d.emission or 1,
    				WindAffectsDrag = d.wind or false, ZOffset = 0.05,
    			})
    			if d.streak then e.Orientation = Enum.ParticleOrientation.VelocityParallel e.Squash = nseq(-2, -0.5, 0) e.Rotation = range(0) e.RotSpeed = range(0) end
    			if d.spin then e.Rotation = range(-180, 180) e.RotSpeed = range(-160, 160) end
    		end
    	end
    	do
    		local de, da = PFPrim.detailFX(torso, { rate = 14, size = 0.07, color = pal.seqGlass, life = 0.9, speed = 0.5, accel = Vector3.new(0, 0.8, 0) }, "WingsDetail")
    		Wings:keep(de) Wings:keep(da)
    	end
    	local tipTrails = {}
    	if cfg.TipTrails then
    		for _, tip in ipairs(tips) do
    			local t2 = attach(torso, tip.CFrame * CFrame.new(0, 0.2, 0), "PF_WingTipT")
    			Wings:keep(t2)
    			trail(tip, t2, { Color = pal.seqHot, Lifetime = 0.35, WidthScale = nseq(1, 0), Transparency = nseq(0.2, 1), FaceCamera = true })
    			table.insert(tipTrails, { tip = tip, t2 = t2 })
    		end
    	end
    	if cfg.Glow then
    		local a = attach(torso, CFrame.new(0, 0.5, 0.6), "PF_WingGlow")
    		Wings:keep(a)
    		light(a, pal.base, 9 * scale, 1.4)

    		emitter(a, { Enabled = true, Rate = 6, Texture = TEX.Field, Color = pal.seqFade, Size = nseq(3.5 * scale, 4 * scale), Transparency = nseq(0.9, 0.82, 0.9), Lifetime = range(0.5), Speed = range(0), LockedToPart = true, ZOffset = -1.5, RotSpeed = range(15) })
    	end

    	local propRings = {}
    	if cfg.Prop then
    		local r1 = makePropRing(torso, cfg, pal, scale, (cfg.PropRing or 2) >= 2 and 2 or 1)
    		table.insert(propRings, r1)
    	end

    	Wings:onPaint(function(p)
    		local ns = wingSpec(cfg.Style, p)
    		local idx = 0
    		for side = -1, 1, 2 do
    			for _, row in ipairs(ns.rows) do
    				for _ = 1, row.n do
    					idx = idx + 1
    					if plumes[idx] then plumes[idx].beam.Color = row.color end
    				end
    			end
    			if ns.bones then
    				for _ = 1, ns.bones.n do
    					idx = idx + 1
    					if plumes[idx] then plumes[idx].beam.Color = ns.bones.color end
    				end
    			end
    		end
    		if ns.bones then for _, m in ipairs(membranes) do m.beam.Color = ns.bones.mem end end
    		for _, r in ipairs(propRings) do
    			if r.color then r:color(p) end
    		end
    	end)

    	local flapSpeed, flapAmp = spec.flapSpeed or 2.6, spec.flapAmp or 0.12
    	local acc, flapClock, dyn, ampK = 0, 0, 0, 1
    	local seated = false
    	Tick.use("Wings", function(dt, t)
    		acc = acc + dt
    		if acc < 1 / 30 then return end
    		local step = acc
    		acc = 0
    		local dr = RAD(S.Wings.Droop or 0)

    		local target, mult, ampT = 0, 1, 1
    		if S.Wings.Dynamic and Char.root and Char.root.Parent and Char.humanoid then
    			local vel = velocityOf(Char.root)
    			local okA, air = pcall(function() return Char.humanoid.FloorMaterial == Enum.Material.Air end)
    			pcall(function() seated = Char.humanoid:GetState() == Enum.HumanoidStateType.Seated end)
    			local hs = Vector3.new(vel.X, 0, vel.Z).Magnitude
    			if seated then target, mult, ampT = -0.7, 0.4, 0.3
    			elseif okA and air then target, mult, ampT = 0.35, 1.9, 1.6
    			elseif hs > 3 then target, mult = 0.1, 1.25
    			else target = -0.3 end
    		end
    		local sm = math.min(step * 4, 1)
    		dyn = dyn + (target - dyn) * sm
    		ampK = ampK + (ampT - ampK) * sm
    		flapClock = flapClock + step * flapSpeed * mult
    		for _, f in ipairs(plumes) do
    			local flap = S.Wings.Flap and (math.sin(flapClock + f.phase) * flapAmp * ampK + 0.24 * flapAmp * ampK * organicNoise(flapClock * 1.2, f.phase * 7.3)) or 0
    			local j = (S.Wings.Flap and f.jitter) and (math.random() - 0.5) * 0.12 or 0
    			f:pose(flap, dr - dyn, j)
    		end
    		poseMembranes()
    		for _, tt in ipairs(tipTrails) do tt.t2.CFrame = tt.tip.CFrame * CFrame.new(0, 0.2, 0) end
    		for i, bl in ipairs(bolts) do
    			bl.bolt:set(bl.a.CFrame.Position, bl.b.CFrame.Position, 0.5, t * 9 + i)
    			bl.bolt:alpha((math.sin(t * 17 + i * 2) > 0.2) and 0.1 or 0.85)
    		end
    		for i, r in ipairs(propRings) do r.update(step, 1) end
    	end)
    	Wings.built = true
    end

    local Halo = defineModule("Halo", {
    	Enabled = false, Style = "Corona", Color = Color3.fromRGB(255, 220, 120),
    	Speed = 1, Glow = true, Satellites = false, Mood = false, Height = 1.15, Tilt = 0,
    })
    Halo.Styles = {
    	"Corona", "Broken Ring", "Atom", "Spinner", "Chandelier", "Rune Wheel", "Saturn", "Arc Reactor",
    	"Crescent Moon", "Cage", "Petal Crown", "Vortex", "Storm Eye", "Gyroscope", "Stacked", "Glitch Ring",
    	"Solar Disc", "Star Crown",
    }

    function Halo.build()
    	Halo:clear()
    	if not S.Halo.Enabled or not alive() then return end
    	local cfg = S.Halo
    	local pal = paletteFor("Halo", cfg)
    	local head = Char.head
    	local style = cfg.Style
    	local H = cfg.Height or 1.15
    	local pivot = attach(head, CFrame.new(0, H, 0), "PF_HaloPivot")
    	Halo:keep(pivot)
    	do
    		local de, da = PFPrim.detailFX(head, { rate = 12, size = 0.09, color = pal.seqGlass, life = 0.6, speed = 0.35, dy = H }, "HaloDetail")
    		Halo:keep(de) Halo:keep(da)
    	end
    	local loops, parts = {}, {}

    	local function addLoop(r, w, o)
    		o = o or {}
    		local loop = makeLoop(head, CFrame.new(0, H + (o.y or 0), 0) * CFrame.Angles(o.tilt or 0, 0, o.roll or 0), r, {
    			Color = o.color or pal.seq, Width = w, Texture = o.texture, TextureLength = o.texLen or 1, TextureSpeed = o.texSpeed or 0,
    			Alpha = o.alpha or 0, Segments = o.segments, ZOffset = o.z, Span = o.span, N = o.n, Name = "PF_HaloLoop",
    		})
    		Halo:keep(loop)
    		table.insert(loops, { loop = loop, r = r, w = w, y = o.y or 0, tilt = o.tilt or 0, roll = o.roll or 0, spinMul = o.spin or 1, bob = o.bob or 0, pulse = o.pulse, wobbleAxis = o.wobbleAxis, phase = o.phase or 0, breathe = o.breathe })
    		return loop
    	end
    	local function orb(name, props)
    		local a = attach(head, CFrame.new(), name or "PF_HaloOrb")
    		Halo:keep(a)
    		emitter(a, props or { Enabled = true, Rate = 20, Color = pal.seqHot, Size = nseq(0.3, 0.18, 0), Lifetime = range(0.2, 0.35), Speed = range(0), Transparency = nseq(0, 1) })
    		return a
    	end

    	if style == "Corona" then

    		addLoop(1.05, 0.14, { color = pal.seqHot, texture = TEX.Spark, texLen = 0.7, texSpeed = 1.2 })
    		addLoop(1.05, 0.5, { color = pal.seqFade, alpha = 0.7, z = -0.02, breathe = 0.06 })
    		local n = q(9, 6)
    		for i = 1, n do
    			addLoop(1.3, 0.22, { color = pal.seqGlass, span = 0.05, n = 2, segments = 3, alpha = 0.05, phase = i / n * TAU, spin = 0.9 })
    		end
    		addLoop(1.18, 0.04, { color = pal.seqHot, spin = -1.4 })
    	elseif style == "Broken Ring" then

    		local n = q(6, 4)
    		for i = 1, n do
    			addLoop(1.05 + (i % 3) * 0.09, 0.15, { color = (i % 2 == 0) and pal.seq or pal.seqHot, span = 0.11, n = 2, phase = i / n * TAU + 0.3, spin = 0.6 + (i % 3) * 0.35, y = (i % 2 == 0) and 0.06 or -0.04 })
    		end
    		addLoop(0.8, 0.05, { color = pal.seqFade, alpha = 0.35, spin = -1.2 })
    		local deb = orb("PF_BrokenDust", { Enabled = true, Rate = q(10, 5), Texture = TEX.Mote, Color = pal.seqGlass, Size = nseq(0.12, 0), Lifetime = range(0.6, 1.1), Speed = range(0.6), SpreadAngle = Vector2.new(40, 40), Transparency = nseq(0, 1) })
    		table.insert(parts, function(t, spin, wob) deb.CFrame = CFrame.new(0, H, 0) * CFrame.Angles(wob, spin, 0) end)
    	elseif style == "Atom" then

    		addLoop(0.9, 0.07, { color = pal.seqHot, tilt = RAD(62), spin = 1.3 })
    		addLoop(0.9, 0.07, { color = pal.seq, tilt = RAD(-62), spin = -1.1 })
    		addLoop(0.9, 0.07, { color = pal.seqUp, tilt = RAD(90), roll = RAD(90), spin = 0.9 })
    		local core = orb("PF_HaloCore", { Enabled = true, Rate = 30, Color = pal.seqHot, Size = nseq(0.42, 0.28, 0), Lifetime = range(0.2, 0.3), Speed = range(0), Transparency = nseq(0, 1) })
    		table.insert(parts, function(t, spin, wob) core.CFrame = CFrame.new(0, H, 0) end)
    		for i = 1, 3 do
    			local e = orb("PF_Electron", { Enabled = true, Rate = 16, Texture = TEX.Glint, Color = pal.seqGlass, Size = nseq(0.16, 0.1, 0), Lifetime = range(0.2, 0.3), Speed = range(0), Transparency = nseq(0, 1) })
    			local e2 = attach(head, CFrame.new(), "PF_ElectronT") Halo:keep(e2)
    			trail(e, e2, { Color = pal.seqHot, Lifetime = 0.3, WidthScale = nseq(0.7, 0), Transparency = nseq(0.2, 1), FaceCamera = true })
    			local tilt = (i == 1 and RAD(62)) or (i == 2 and RAD(-62)) or RAD(90)
    			local dir = (i == 2) and -1 or 1
    			table.insert(parts, function(t, spin, wob)
    				local a = t * (1.4 + i * 0.2) * dir + i * 2.1
    				e.CFrame = CFrame.new(0, H, 0) * CFrame.Angles(wob + tilt, 0, 0) * CFrame.Angles(0, 0, a) * CFrame.new(0.9, 0, 0)
    				e2.CFrame = e.CFrame * CFrame.new(0, 0.06, 0)
    			end)
    		end
    	do
    		local alist, aupd = PFPrim.assembleFX(head, { kind = "sphere", r = 0.42, y = H, n = q(14, 8), dur = 1.2, color = pal.seqHot, size = 0.09, spread = 2.2, spin = 1.5 })
    		for _, it in ipairs(alist) do Halo:keep(it.a) Halo:keep(it.e) end
    		table.insert(parts, function(t, spin, wob) aupd(t) end)
    	end
    	elseif style == "Spinner" then

    		local blades = q(3, 3)
    		for i = 1, blades do
    			addLoop(1.2, 0.4, { color = pal.seq, span = 0.19, n = 2, phase = i / blades * TAU, spin = 3, alpha = 0.08 })
    			addLoop(1.2, 0.07, { color = pal.seqHot, span = 0.19, n = 2, phase = i / blades * TAU, spin = 3, z = 0.02 })
    		end
    		addLoop(0.32, 0.12, { color = pal.seqHot, spin = 3 })
    		addLoop(0.95, 0.04, { color = pal.seqGlass, alpha = 0.3, spin = -2 })
    	elseif style == "Chandelier" then

    		addLoop(1.2, 0.08, { color = pal.seqHot })
    		addLoop(0.7, 0.06, { color = pal.seq, y = 0.35 })
    		local n = q(8, 5)
    		for i = 1, n do
    			local a0 = attach(head, CFrame.new(), "PF_Drop0")
    			local a1 = attach(head, CFrame.new(), "PF_Drop1")
    			Halo:keep(a0) Halo:keep(a1)
    			beam(a0, a1, { FaceCamera = true, Segments = 1, Width0 = 0.035, Width1 = 0.12, Color = pal.seqGlass, Transparency = nseq(0.05, 0.35) })
    			local gem = attach(head, CFrame.new(), "PF_DropGem") Halo:keep(gem)
    			emitter(gem, { Enabled = true, Rate = 8, Texture = TEX.Glint, Color = pal.seqGlass, Size = nseq(0.14, 0.1, 0), Lifetime = range(0.25), Speed = range(0), Transparency = nseq(0, 1), Rotation = range(-180, 180), RotSpeed = range(60) })
    			local th = i / n * TAU
    			table.insert(parts, function(t, spin, wob)
    				local base = CFrame.new(0, H, 0) * CFrame.Angles(wob, spin * 0.5 + th, 0) * CFrame.new(0, 0, -1.2)
    				local sway = math.sin(t * 2 + i) * 0.07
    				a0.CFrame = base
    				a1.CFrame = base * CFrame.new(sway, -0.5 - 0.1 * math.sin(t * 3 + i), 0)
    				gem.CFrame = a1.CFrame
    			end)
    		end
    	elseif style == "Rune Wheel" then

    		addLoop(1.25, 0.08, { color = pal.seqHot })
    		addLoop(0.95, 0.05, { color = pal.seq, spin = -1 })
    		local n = q(6, 5)
    		local nodes = {}
    		for i = 1, n do nodes[i] = attach(head, CFrame.new(), "PF_RuneNode") Halo:keep(nodes[i]) end
    		for i = 1, n do
    			beam(nodes[i], nodes[i % n + 1], { FaceCamera = false, Segments = 1, Width0 = 0.035, Width1 = 0.035, Color = pal.seqHot, Transparency = nseq(0.15) })
    			beam(nodes[i], nodes[(i + 2) % n + 1], { FaceCamera = false, Segments = 1, Width0 = 0.025, Width1 = 0.025, Color = pal.seq, Transparency = nseq(0.35) })
    		end
    		for i = 1, n do
    			local rune = attach(head, CFrame.new(), "PF_RuneGlyph") Halo:keep(rune)
    			emitter(rune, { Enabled = true, Rate = 7, Texture = TEX.Swirl, Color = pal.seqGlass, Size = nseq(0.26, 0.24), Transparency = nseq(0.1, 0.3, 1), Lifetime = range(0.35), Speed = range(0), Orientation = Enum.ParticleOrientation.VelocityPerpendicular, LockedToPart = true, Rotation = range(0), RotSpeed = range(24), ZOffset = 0.05 })
    			table.insert(parts, function(t, spin, wob)
    				local th = i / n * TAU - spin * 0.8
    				local cf = CFrame.new(0, H, 0) * CFrame.Angles(wob, 0, 0) * CFrame.new(math.cos(th) * 1.1, 0, math.sin(th) * 1.1) * CFrame.Angles(-math.pi / 2, 0, 0)
    				nodes[i].CFrame = cf
    				rune.CFrame = cf
    			end)
    		end
    	do
    		local alist, aupd = PFPrim.assembleFX(head, { kind = "ring", r = 1.1, y = H, n = q(18, 10), dur = 1.3, color = pal.seqHot, color2 = pal.seqGlass, size = 0.11, spread = 2.6 })
    		for _, it in ipairs(alist) do Halo:keep(it.a) Halo:keep(it.e) end
    		table.insert(parts, function(t, spin, wob) aupd(t, spin * 0.8) end)
    	end
    	elseif style == "Saturn" then

    		addLoop(1.5, 0.55, { color = cseq(pal.deep, pal.base, pal.bright, pal.base, pal.deep), tilt = RAD(22), alpha = 0.25, texture = TEX.Smoke, texLen = 1.4, texSpeed = 0.3 })
    		addLoop(1.55, 0.05, { color = pal.seqHot, tilt = RAD(22) })
    		addLoop(1.15, 0.04, { color = pal.seqHot, tilt = RAD(22), alpha = 0.3 })
    		local core = orb("PF_HaloCore", { Enabled = true, Rate = 24, Color = pal.seqHot, Size = nseq(0.68, 0.5, 0), Lifetime = range(0.25, 0.4), Speed = range(0), Transparency = nseq(0.1, 1) })
    		local moon = orb("PF_Moon", { Enabled = true, Rate = 10, Texture = TEX.Circle, Color = pal.seqGlass, Size = nseq(0.2, 0.16), Transparency = nseq(0.1, 0.4, 1), Lifetime = range(0.4), Speed = range(0), LockedToPart = true })
    		table.insert(parts, function(t, spin, wob)
    			core.CFrame = CFrame.new(0, H, 0)
    			moon.CFrame = CFrame.new(0, H, 0) * CFrame.Angles(wob + RAD(22), -t * 1.1, 0) * CFrame.new(1.7, 0, 0)
    		end)
    	elseif style == "Arc Reactor" then

    		addLoop(1.1, 0.12, { color = pal.seqGlass })
    		addLoop(0.75, 0.22, { color = pal.seqHot, alpha = 0.15, spin = -1.5, pulse = 0.07 })
    		local n = q(10, 6)
    		for i = 1, n do
    			addLoop(0.93, 0.15, { color = pal.seq, span = 1 / n * 0.5, n = 2, segments = 3, phase = i / n * TAU, spin = 1.5 })
    		end
    		local tri = {}
    		for i = 1, 3 do
    			local a = attach(head, CFrame.new(), "PF_ReactorTri") Halo:keep(a)
    			tri[i] = a
    			if i > 1 then
    				beam(tri[i - 1], tri[i], { FaceCamera = false, Segments = 1, Width0 = 0.05, Width1 = 0.05, Color = cseq(WHITE, pal.bright), Transparency = nseq(0.05) })
    			end
    		end
    		beam(tri[3], tri[1], { FaceCamera = false, Segments = 1, Width0 = 0.05, Width1 = 0.05, Color = cseq(WHITE, pal.bright), Transparency = nseq(0.05) })
    		local a = orb("PF_HaloCore", { Enabled = true, Rate = 20, Color = pal.seqGlass, Size = nseq(0.45, 0.3, 0), Lifetime = range(0.2, 0.3), Speed = range(0), Transparency = nseq(0, 1) })
    		table.insert(parts, function(t, spin, wob)
    			a.CFrame = CFrame.new(0, H, 0)
    			for i = 1, 3 do
    				local th = i / 3 * TAU - spin * 0.6 + math.pi / 2
    				tri[i].CFrame = CFrame.new(0, H, 0) * CFrame.Angles(wob, 0, 0) * CFrame.new(math.cos(th) * 0.42, 0, math.sin(th) * 0.42) * CFrame.Angles(-math.pi / 2, 0, 0)
    			end
    		end)
    	elseif style == "Crescent Moon" then

    		local disc = orb("PF_MoonBright", { Enabled = true, Rate = 22, Texture = TEX.Ring, Color = pal.seqHot, Size = nseq(1.7), Transparency = nseq(0.15), Lifetime = range(0.25), Speed = range(0.01), EmissionDirection = Enum.NormalId.Top, Orientation = Enum.ParticleOrientation.VelocityPerpendicular, LockedToPart = true, Rotation = range(180), RotSpeed = range(6), ZOffset = 0.04 })
    		emitter(disc, { Enabled = true, Rate = 20, Texture = TEX.Circle, Color = cseq(pal.deep, BLACK), Size = nseq(1.45), Transparency = nseq(0.08, 0.2, 1), Lifetime = range(0.25), Speed = range(0.01), EmissionDirection = Enum.NormalId.Top, Orientation = Enum.ParticleOrientation.VelocityPerpendicular, LockedToPart = true, ZOffset = 0.055, LightEmission = 0 })
    		addLoop(1.05, 0.05, { color = pal.seqGlass, alpha = 0.3, spin = 0.4 })
    		local stars = q(4, 3)
    		for i = 1, stars do
    			local s = orb("PF_Star", { Enabled = true, Rate = 10, Texture = TEX.Star, Color = pal.seqGlass, Size = nseq(0.2, 0.16), Lifetime = range(0.35), Speed = range(0), Transparency = nseq(0, 0.3, 1), Rotation = range(0, 72), RotSpeed = range(70), LockedToPart = true, ZOffset = 0.1 })
    			local th = i / stars * TAU
    			table.insert(parts, function(t, spin, wob)
    				s.CFrame = CFrame.new(0, H, 0) * CFrame.Angles(wob, spin * 0.6 + th, 0) * CFrame.new(0, 0.25 * math.sin(t * 1.5 + i), -1.45)
    			end)
    		end
    		table.insert(parts, function(t, spin, wob) disc.CFrame = CFrame.new(0, H, 0) * CFrame.Angles(wob, 0, 0) end)
    	elseif style == "Cage" then

    		addLoop(0.9, 0.06, { color = pal.seqHot, y = 0.35 })
    		addLoop(0.9, 0.06, { color = pal.seqHot, y = -0.35, spin = -1 })
    		local bars = q(7, 5)
    		for i = 1, bars do
    			local a0 = attach(head, CFrame.new(), "PF_Bar0")
    			local a1 = attach(head, CFrame.new(), "PF_Bar1")
    			Halo:keep(a0) Halo:keep(a1)
    			local b = beam(a0, a1, { FaceCamera = true, Segments = 6, Width0 = 0.05, Width1 = 0.05, Color = pal.seq, Transparency = nseq(0.08) })
    			b.CurveSize0 = 0.35 b.CurveSize1 = -0.35
    			local th = i / bars * TAU
    			table.insert(parts, function(t, spin, wob)
    				local base = CFrame.new(0, H, 0) * CFrame.Angles(wob, spin + th, 0)
    				a0.CFrame = base * CFrame.new(0, 0.38, -0.92) * CFrame.Angles(0, 0.45, 0)
    				a1.CFrame = base * CFrame.new(0, -0.38, -0.92) * CFrame.Angles(0, -0.45, 0)
    			end)
    		end
    		local key = orb("PF_CageKey", { Enabled = true, Rate = 12, Texture = TEX.Glint, Color = pal.seqHot, Size = nseq(0.2, 0.15, 0), Lifetime = range(0.3), Speed = range(0), Transparency = nseq(0, 1), Rotation = range(-180, 180), RotSpeed = range(90), ZOffset = 0.1 })
    		table.insert(parts, function(t, spin, wob)
    			key.CFrame = CFrame.new(0, H + math.sin(t * 1.8) * 0.3, 0) * CFrame.Angles(0, spin * 2, 0)
    		end)
    	elseif style == "Petal Crown" then

    		local petals = q(8, 6)
    		local made = {}
    		for i = 1, petals do
    			local p = attach(head, CFrame.new(), "PF_CrownPetal") Halo:keep(p)
    			emitter(p, { Enabled = true, Rate = 8, Texture = TEX.Heart, Color = cseq(WHITE, pal.bright, pal.base), Size = nseq(0.34, 0.3), Transparency = nseq(0.05, 0.25, 1), Lifetime = range(0.4), Speed = range(0), Orientation = Enum.ParticleOrientation.VelocityPerpendicular, LockedToPart = true, Rotation = range(0), RotSpeed = range(12), ZOffset = 0.06 })
    			made[i] = p
    		end
    		addLoop(0.5, 0.05, { color = pal.seqHot, spin = 1.6 })
    		local fall = orb("PF_CrownFall", { Enabled = true, Rate = q(5, 2), Texture = TEX.Heart, Color = pal.seqFade, Size = nseq(0.16, 0.1, 0), Lifetime = range(1, 1.6), Speed = range(0.4), SpreadAngle = Vector2.new(60, 60), Acceleration = Vector3.new(0, -2.2, 0), Drag = 1, Transparency = nseq(0.2, 1), Rotation = range(-180, 180), RotSpeed = range(-120, 120) })
    		table.insert(parts, function(t, spin, wob)
    			fall.CFrame = CFrame.new(0, H, 0)
    			local open = 0.45 + 0.2 * math.sin(t * 1.3)
    			for i, p in ipairs(made) do
    				local th = i / petals * TAU + spin * 0.35
    				p.CFrame = CFrame.new(0, H + 0.12, 0) * CFrame.Angles(wob, th, 0) * CFrame.new(0, 0, -open) * CFrame.Angles(RAD(-70), 0, 0)
    			end
    		end)
    	elseif style == "Vortex" then

    		for i = 1, q(5, 3) do
    			addLoop(0.5 + i * 0.16, 0.05 + i * 0.012, { color = i % 2 == 0 and pal.seq or pal.seqHot, y = 0.05 + (i - 1) * 0.16, spin = 2.4 - i * 0.3, alpha = 0.05 * i, span = 0.85, n = 4, phase = i * 1.3 })
    		end
    		local a = orb("PF_HaloCore", { Enabled = true, Rate = 20, Color = pal.seqHot, Size = nseq(0.14, 0), Lifetime = range(0.5, 0.9), Speed = range(1.8), SpreadAngle = Vector2.new(16, 16), Acceleration = Vector3.new(0, 2.4, 0), Transparency = nseq(0, 1) })
    		table.insert(parts, function(t, spin, wob) a.CFrame = CFrame.new(0, H - 0.12, 0) end)
    		local pull = orb("PF_VortexPull", { Enabled = true, Rate = q(12, 5), Texture = TEX.Mote, Color = pal.seqGlass, Size = nseq(0.1, 0.04, 0), Lifetime = range(0.7), Speed = range(0), Transparency = nseq(0.1, 1), LightEmission = 1 })
    		table.insert(parts, function(t, spin, wob)
    			pull.CFrame = CFrame.new(0, H + 0.5, 0) * CFrame.Angles(wob, -t * 2.4, 0) * CFrame.new(0, 0, -1.6)
    		end)
    	elseif style == "Storm Eye" then

    		addLoop(1.15, 0.38, { color = cseq(pal.deep, pal.base, pal.deep), texture = TEX.Smoke, texLen = 1, texSpeed = 1.4, alpha = 0.3, spin = 2.2 })
    		addLoop(1.3, 0.05, { color = pal.seqHot, spin = 2.2 })
    		local n = q(4, 3)
    		local nodes = {}
    		for i = 1, n do nodes[i] = attach(head, CFrame.new(), "PF_StormNode") Halo:keep(nodes[i]) end
    		local bolts = {}
    		for i = 1, n do
    			bolts[i] = makeBolt(head, { K = 4, Width = 0.08, Color = pal.seqGlass })
    			Halo:keep(bolts[i])
    		end
    		table.insert(parts, function(t, spin, wob)
    			for i = 1, n do
    				local th = i / n * TAU + spin * 2
    				nodes[i].CFrame = CFrame.new(0, H, 0) * CFrame.Angles(wob, 0, 0) * CFrame.new(math.cos(th) * 1.15, 0, math.sin(th) * 1.15)
    			end
    			for i = 1, n do
    				local p0 = nodes[i].CFrame.Position
    				local p1 = nodes[i % n + 1].CFrame.Position
    				bolts[i]:set(p0, p1, 0.35, t * 11 + i)
    				bolts[i]:alpha((math.sin(t * 13 + i * 2.7) > 0.55) and 0 or 1)
    			end
    		end)
    	elseif style == "Gyroscope" then

    		addLoop(1.2, 0.08, { color = pal.seqHot, wobbleAxis = "x", spin = 1 })
    		addLoop(1.0, 0.08, { color = pal.seq, wobbleAxis = "z", spin = -1 })
    		addLoop(0.8, 0.08, { color = pal.seqUp, wobbleAxis = "x", spin = 2, phase = 2 })
    		local core = orb("PF_GyroCore", { Enabled = true, Rate = 14, Color = pal.seqGlass, Size = nseq(0.2, 0.14, 0), Lifetime = range(0.3), Speed = range(0), Transparency = nseq(0, 1) })
    		table.insert(parts, function(t, spin, wob)
    			core.CFrame = CFrame.new(0, H + math.sin(t * 2.4) * 0.12, 0)
    		end)
    	elseif style == "Stacked" then

    		for i = 1, q(4, 3) do
    			addLoop(1.25 - i * 0.2, 0.09, { color = (i % 2 == 1) and pal.seqHot or pal.seq, y = (i - 1) * 0.22, spin = (i % 2 == 1) and 1 or -1, bob = 0.05 })
    		end
    		addLoop(0.3, 0.06, { color = pal.seqGlass, alpha = 0.2, spin = 3, y = 0.9 })
    	elseif style == "Glitch Ring" then

    		local segs = q(8, 5)
    		for i = 1, segs do
    			addLoop(1.1, 0.13, { color = (i % 2 == 0) and pal.seqHot or pal.seqGlass, span = 1 / segs * 0.7, n = 2, segments = 3, phase = i / segs * TAU, spin = 1 })
    			loops[#loops].glitch = i
    		end
    		addLoop(1.1, 0.38, { color = pal.seqFade, alpha = 0.75, z = -0.02 })
    		addLoop(1.14, 0.03, { color = cseq(Color3.fromHSV(0, 0.8, 1)), alpha = 0.4, spin = -2.4 })
    		addLoop(1.06, 0.03, { color = cseq(Color3.fromHSV(0.33, 0.8, 1)), alpha = 0.4, spin = 2.6 })
    	elseif style == "Solar Disc" then

    		local disc = orb("PF_HaloDisc", { Enabled = true, Rate = 24, Texture = TEX.Ring, Color = pal.seqHot, Size = nseq(2.7), Transparency = nseq(0.3), Lifetime = range(0.2), Speed = range(0.01), EmissionDirection = Enum.NormalId.Top, Orientation = Enum.ParticleOrientation.VelocityPerpendicular, LockedToPart = true, Rotation = range(0), RotSpeed = range(22), ZOffset = 0.05 })
    		emitter(disc, { Enabled = true, Rate = 24, Texture = TEX.Field, Color = pal.seqFade, Size = nseq(3.4), Transparency = nseq(0.85), Lifetime = range(0.2), Speed = range(0.01), EmissionDirection = Enum.NormalId.Top, Orientation = Enum.ParticleOrientation.VelocityPerpendicular, LockedToPart = true, ZOffset = -0.05 })
    		emitter(disc, { Enabled = true, Rate = 3, Texture = TEX.Glint, Color = pal.seqGlass, Size = nseq(0.3, 1.3, 0.3), Transparency = nseq(0.2, 0, 1), Lifetime = range(0.5), Speed = range(0), Rotation = range(-180, 180), RotSpeed = range(60), LockedToPart = true, ZOffset = 0.2 })
    		addLoop(1.32, 0.05, { color = pal.seqGlass, spin = 0.8 })
    		local rays = q(6, 4)
    		local rAts = {}
    		for i = 1, rays do rAts[i] = attach(head, CFrame.new(), "PF_SolarRay") Halo:keep(rAts[i]) end
    		table.insert(parts, function(t, spin, wob)
    			disc.CFrame = CFrame.new(0, H, 0) * CFrame.Angles(wob, 0, 0)
    			for i = 1, rays do
    				local th = i / rays * TAU + t * 0.4
    				local k = 0.9 + 0.25 * math.sin(t * 2 + i * 1.7)
    				rAts[i].CFrame = CFrame.new(0, H, 0) * CFrame.Angles(-math.pi / 2, 0, th) * CFrame.new(0, -1.9 * k, 0)
    			end
    		end)
    	else

    		local n = q(5, 4)
    		for i = 1, n do
    			local a = orb("PF_HaloStar", { Enabled = true, Rate = 14, Texture = TEX.Star, Color = (i % 2 == 0) and pal.seqHot or pal.seqGlass, Size = nseq(0.5, 0.42), Transparency = nseq(0.05, 0.1, 1), Lifetime = range(0.3), Speed = range(0), Rotation = range(0, 72), RotSpeed = range(90), LockedToPart = true, ZOffset = 0.1 })
    			local th = i / n * TAU
    			table.insert(parts, function(t, spin, wob)
    				a.CFrame = CFrame.new(0, H, 0) * CFrame.Angles(wob, spin * 0.7 + th, 0) * CFrame.new(0, 0.14 * math.sin(t * 2 + i), -1.1)
    			end)
    		end
    		local dots = q(12, 8)
    		for i = 1, dots do
    			addLoop(1.1, 0.08, { color = pal.seq, span = 1 / dots * 0.45, n = 2, segments = 2, phase = i / dots * TAU, spin = -0.7 })
    		end
    		addLoop(0.75, 0.04, { color = pal.seqFade, alpha = 0.4, spin = 1.2 })
    		local top = orb("PF_HaloStarTop", { Enabled = true, Rate = 12, Texture = TEX.Star, Color = pal.seqHot, Size = nseq(0.34, 0.3), Transparency = nseq(0, 0.15, 1), Lifetime = range(0.3), Speed = range(0), Rotation = range(0, 72), RotSpeed = range(50), LockedToPart = true, ZOffset = 0.12 })
    		table.insert(parts, function(t, spin, wob) top.CFrame = CFrame.new(0, H + 0.55 + math.sin(t * 2) * 0.05, 0) end)
    	end

    	if cfg.Satellites then
    		local n = q(4, 3)
    		for i = 1, n do
    			local a = orb("PF_Sat", { Enabled = true, Rate = 18, Texture = TEX.Glint, Color = pal.seqHot, Size = nseq(0.3, 0), Lifetime = range(0.2, 0.35), Speed = range(0), Transparency = nseq(0, 1), Rotation = range(-180, 180), RotSpeed = range(120) })
    			local ta = attach(head, CFrame.new(), "PF_SatT")
    			Halo:keep(ta)
    			trail(a, ta, { Color = pal.seqHot, Lifetime = 0.3, WidthScale = nseq(1, 0), Transparency = nseq(0.3, 1), FaceCamera = true })
    			local th = i / n * TAU
    			table.insert(parts, function(t, spin, wob)
    				local base = CFrame.new(0, H + math.sin(t * 2.5 + i) * 0.25, 0) * CFrame.Angles(wob, th - spin * 0.8, 0)
    				a.CFrame = base * CFrame.new(0, 0, -1.7)
    				ta.CFrame = base * CFrame.new(0, 0.1, -1.7)
    			end)
    		end
    	end
    	if cfg.Glow then
    		light(pivot, pal.base, 6, 1.2)
    		emitter(pivot, { Enabled = true, Rate = 5, Texture = TEX.Field, Color = pal.seqFade, Size = nseq(2.2, 2.6), Transparency = nseq(0.92, 0.85, 0.92), Lifetime = range(0.6), Speed = range(0), LockedToPart = true, ZOffset = -1 })
    	end

    	Halo:onPaint(function(p)
    		for i, l in ipairs(loops) do l.loop:color((i == 1) and p.seqHot or p.seq) end
    	end)

    	local angle, mood, moodAcc, moodPainted = 0, 0, 0, false
    	local userTilt = RAD(cfg.Tilt or 0)
    	Tick.use("Halo", function(dt, t)

    		local target = S.Halo.Mood and (1 - hpFrac()) or 0
    		mood = mood + (target - mood) * math.min(dt * 2, 1)
    		moodAcc = moodAcc + dt
    		if moodAcc > 0.3 then
    			moodAcc = 0
    			if mood > 0.05 then
    				local p = paletteFor("Halo", cfg)
    				local dim = cseq(p.bright:Lerp(BLACK, mood * 0.5), p.base:Lerp(BLACK, mood * 0.6), p.deep:Lerp(BLACK, mood * 0.7))
    				for _, l in ipairs(loops) do l.loop:color(dim) end
    				moodPainted = true
    			elseif moodPainted then
    				moodPainted = false
    				Halo:repaint(paletteFor("Halo", cfg))
    			end
    		end
    		angle = angle + dt * S.Halo.Speed * (1 - mood * 0.7)
    		local spin = angle + (S.Spin.Enabled and Tick.spin or 0)
    		local wob = Tick.wobble + userTilt + mood * (0.35 + math.sin(t * 1.3) * 0.15) + 0.12 * organicNoise(t * 0.9, 2.2)
    		local sag = mood * 0.35
    		for _, l in ipairs(loops) do
    			local tilt, roll, y = l.tilt + wob, l.roll, H + l.y + math.sin(t * 2 + l.y * 10) * l.bob - sag
    			local rot = 0
    			if l.wobbleAxis == "x" then tilt = tilt + math.sin(t * 1.7 + l.phase) * 0.7 end
    			if l.wobbleAxis == "z" then roll = roll + math.cos(t * 1.7 + l.phase) * 0.7 end
    			if l.wobbleAxis == "spinY" then rot = spin * l.spinMul end
    			local rr = l.r * (1 + (l.pulse or 0) * math.sin(t * 3)) * (l.breathe and (1 + l.breathe * math.sin(t * 1.5)) or 1)
    			local alpha = nil
    			if l.glitch then
    				alpha = (math.sin(t * 9 + l.glitch * 2.3) > 0.7) and 0.9 or 0
    				y = y + ((math.sin(t * 23 + l.glitch) > 0.9) and 0.08 or 0)
    			end
    			if l.petal then
    				local open = 0.5 + 0.5 * math.sin(t * 1.2)
    				l.loop.center = CFrame.new(0, y, 0) * CFrame.Angles(wob, spin * l.spinMul + l.petal, 0) * CFrame.new(0, 0, -0.35) * CFrame.Angles(l.tilt + open * 0.5, 0, 0)
    				l.loop:set(rr, l.w, alpha, l.phase)
    			else
    				l.loop.center = CFrame.new(0, y, 0) * CFrame.Angles(tilt, rot, roll)
    				l.loop:set(rr, l.w, alpha, (l.wobbleAxis == "spinY") and l.phase or (spin * l.spinMul + l.phase))
    			end
    		end
    		for _, fn in ipairs(parts) do fn(t, spin, wob) end
    	end)
    	Halo.built = true
    end

    local Hat = defineModule("Hat", {
    	Enabled = false, Style = "Top Hat", Color = Color3.fromRGB(255, 140, 90),
    	Size = 1, Spin = 0, Glow = true, Fringe = false, Bob = true,
    })
    Hat.Styles = {
    	"Top Hat", "Wizard", "Bucket", "Sombrero", "Crown", "Beanie", "Antenna", "Chef",
    	"Pirate", "Party Cone", "Fez", "Bamboo", "Mushroom", "Ice Crown", "Fire Crown", "Nimbus",
    	"Storm Cloud", "Star Halo Hat",
    }

    function Hat.build()
    	Hat:clear()
    	if not S.Hat.Enabled or not alive() then return end
    	local cfg = S.Hat
    	local pal = paletteFor("Hat", cfg)
    	local head = Char.head
    	local style = cfg.Style
    	local sz = cfg.Size
    	local shells, loops, parts = {}, {}, {}
    	do
    		local de, da = PFPrim.detailFX(head, { rate = 8, size = 0.08, color = pal.seqGlass, life = 0.7, speed = 0.25 }, "HatDetail")
    		Hat:keep(de) Hat:keep(da)
    	end

    	local function shell(rTop, rBot, height, y, o)
    		o = o or {}
    		local sh = makeShell(head, { Panels = o.panels or 12, Color = o.color or pal.seq, Transparency = o.transparency or nseq(0.05, 0.2), Texture = o.texture, TextureLength = o.texLen, TextureSpeed = o.texSpeed, LightEmission = o.emission, ZOffset = o.z })
    		Hat:keep(sh)
    		table.insert(shells, { sh = sh, rt = rTop * sz, rb = rBot * sz, h = height * sz, y = y * sz, bulge = o.bulge or 0, spinMul = o.spin or 1, breathe = o.breathe, sway = o.sway })
    		return sh
    	end
    	local function band(radius, width, y, o)
    		o = o or {}
    		local l = makeLoop(head, CFrame.new(0, y * sz, 0), radius * sz, { Color = o.color or pal.seqHot, Width = width * sz, Alpha = o.alpha or 0, Texture = o.texture, TextureLength = o.texLen or 1, TextureSpeed = o.texSpeed or 0, Span = o.span, N = o.n, Name = "PF_HatBand" })
    		Hat:keep(l)
    		table.insert(loops, { loop = l, r = radius * sz, w = width * sz, y = y * sz, spinMul = o.spin or 1, tilt = o.tilt or 0, roll = o.roll or 0, phase = o.phase or 0 })
    		return l
    	end
    	local function spot(cf, name) local a = attach(head, cf, name or "PF_HatSpot") Hat:keep(a) return a end
    	local top = 0.6

    	if style == "Top Hat" then

    		shell(0.95, 0.95, 1.7, top, { color = cseq(pal.deep, pal.base, pal.deep), panels = 12 })
    		shell(0.95, 0.0, 0.02, top + 1.7, { color = pal.seq, panels = 10 })
    		shell(1.7, 1.7, 0.03, top, { color = cseq(pal.base, pal.deep), panels = 16 })
    		shell(1.7, 1.7, 0.02, top + 0.04, { color = pal.seqHot, panels = 16, transparency = nseq(0.4) })
    		band(1.0, 0.3, top + 0.28, { color = pal.seqHot })
    		local buckle = spot(CFrame.new(0, (top + 0.28) * sz, -1.02 * sz), "PF_Tie")
    		emitter(buckle, { Enabled = true, Rate = 6, Texture = TEX.Glint, Color = pal.seqGlass, Size = nseq(0.22 * sz, 0.18 * sz), Lifetime = range(0.4), Speed = range(0), Transparency = nseq(0, 0.2, 1), Rotation = range(45, 45), LockedToPart = true, ZOffset = 0.08 })
    		table.insert(parts, function(t, spin, wob) buckle.CFrame = CFrame.Angles(wob, spin, 0) * CFrame.new(0, (top + 0.28) * sz, -1.02 * sz) end)
    	elseif style == "Wizard" then

    		shell(0.0, 1.3, 3.0, top, { color = cseq(pal.deep, pal.base, pal.deep), bulge = -0.35, panels = 10, sway = 0.12 })
    		shell(2.5, 2.5, 0.03, top, { color = cseq(pal.base, pal.deep), panels = 16 })
    		shell(2.5, 2.5, 0.02, top + 0.05, { color = pal.seqHot, panels = 16, transparency = nseq(0.45) })
    		band(1.3, 0.22, top + 0.35, { color = pal.seqHot, texture = TEX.Spark, texLen = 0.6, texSpeed = 1 })
    		local stars = q(7, 4)
    		for i = 1, stars do
    			local a = spot(CFrame.new(), "PF_HatStar")
    			emitter(a, { Enabled = true, Rate = 2, Texture = TEX.Star, Color = pal.seqGlass, Size = nseq(0.2 * sz, 0.14 * sz), Lifetime = range(0.5, 0.9), Speed = range(0.2), SpreadAngle = Vector2.new(180, 180), Transparency = nseq(0, 1), Rotation = range(0, 72), RotSpeed = range(50) })
    			local th = i / stars * TAU
    			local hgt = 0.6 + (i % 4) * 0.6
    			table.insert(parts, function(t, spin, wob)
    				local r = 1.35 * (1 - hgt / 3.2) + 0.06
    				a.CFrame = CFrame.Angles(wob, spin + th + math.sin(t * 0.8) * 0.2, 0) * CFrame.new(0, (top + hgt) * sz, -r * sz)
    			end)
    		end
    	elseif style == "Bucket" then

    		shell(1.1, 1.25, 1.05, top, { color = pal.seq, panels = 12 })
    		shell(1.1, 0, 0.02, top + 1.05, { color = pal.seqFade, panels = 10 })
    		shell(1.25, 1.95, -0.5, top + 0.5, { color = cseq(pal.base, pal.deep), panels = 16, transparency = nseq(0.1, 0.35) })
    		band(1.25, 0.1, top + 0.02, { color = pal.seqHot })
    		local h0, h1 = spot(CFrame.new(), "PF_Handle0"), spot(CFrame.new(), "PF_Handle1")
    		local hb = beam(h0, h1, { FaceCamera = true, Segments = 8, Width0 = 0.05 * sz, Width1 = 0.05 * sz, Color = pal.seqFade, Transparency = nseq(0.1) })
    		local drip = spot(CFrame.new(), "PF_BucketDrip")
    		emitter(drip, { Enabled = true, Rate = q(6, 2), Texture = TEX.Drop, Color = cseq(WHITE, pal.bright), Size = nseq(0.14 * sz, 0.1 * sz), Lifetime = range(0.7, 1.1), Speed = range(0.5), SpreadAngle = Vector2.new(30, 30), Acceleration = Vector3.new(0, -18, 0), Transparency = nseq(0.1, 0.5, 1), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-1.6), Rotation = range(0), RotSpeed = range(0) })
    		table.insert(parts, function(t, spin, wob)
    			local base = CFrame.Angles(wob, spin, 0)
    			local swing = math.sin(t * 1.8) * 0.12
    			h0.CFrame = base * CFrame.new(-1.16 * sz, (top + 0.9) * sz, 0)
    			h1.CFrame = base * CFrame.new(1.16 * sz, (top + 0.9 + swing * 0.4) * sz, 0)
    			hb.CurveSize0 = 0.9 * sz hb.CurveSize1 = 0.9 * sz
    			drip.CFrame = base * CFrame.new(0, (top + 1.0) * sz, 0)
    		end)
    	elseif style == "Sombrero" then

    		shell(0.35, 1.0, 1.5, top, { color = cseq(pal.bright, pal.base), bulge = 0.15, panels = 10 })
    		shell(1.0, 2.9, 0.55, top - 0.55, { color = cseq(pal.base, pal.deep, pal.base), bulge = -0.25, panels = 18 })
    		shell(2.9, 2.9, 0.02, top - 0.55, { color = pal.seqHot, panels = 18, transparency = nseq(0.5) })
    		band(1.0, 0.22, top + 0.1, { color = pal.seqHot, texture = TEX.Spark, texLen = 0.5, texSpeed = 0.6 })
    		local tas = q(8, 5)
    		for i = 1, tas do
    			local a = spot(CFrame.new(), "PF_SombTassel")
    			emitter(a, { Enabled = true, Rate = 4, Texture = TEX.Scratch, Color = pal.seqHot, Size = nseq(0.1 * sz, 0.34 * sz), Lifetime = range(0.6), Speed = range(0), Transparency = nseq(0.05, 0.5), Rotation = range(90, 90), LockedToPart = true })
    			local th = i / tas * TAU
    			table.insert(parts, function(t, spin, wob)
    				local sway = math.sin(t * 2.2 + i) * 0.05
    				a.CFrame = CFrame.Angles(wob, spin + th, 0) * CFrame.new(0, (top - 0.75 + sway) * sz, -2.85 * sz)
    			end)
    		end
    	elseif style == "Crown" then

    		shell(1.2, 1.05, 0.75, top, { color = cseq(pal.bright, pal.base), panels = 12, transparency = nseq(0.02, 0.2) })
    		band(1.05, 0.14, top, { color = pal.seqHot })
    		band(1.2, 0.06, top + 0.72, { color = pal.seqHot })
    		local spikes = q(6, 4)
    		for i = 1, spikes do
    			local a0 = spot(CFrame.new(), "PF_Spike0")
    			local a1 = spot(CFrame.new(), "PF_Spike1")
    			beam(a0, a1, { FaceCamera = true, Segments = 1, Width0 = 0.3 * sz, Width1 = 0.02, Color = pal.seqHot, Transparency = nseq(0, 0.1) })
    			local gem = spot(CFrame.new(), "PF_Gem")
    			emitter(gem, { Enabled = true, Rate = 6, Texture = TEX.Glint, Color = pal.seqGlass, Size = nseq(0.24 * sz, 0.18 * sz, 0), Lifetime = range(0.3, 0.5), Speed = range(0), Transparency = nseq(0, 1), Rotation = range(-180, 180), RotSpeed = range(70) })
    			local th = i / spikes * TAU
    			table.insert(parts, function(t, spin, wob)
    				local base = CFrame.Angles(wob, spin + th, 0)
    				a0.CFrame = base * CFrame.new(0, (top + 0.72) * sz, -1.2 * sz)
    				a1.CFrame = base * CFrame.new(0, (top + 1.5 + 0.08 * math.sin(t * 3 + i)) * sz, -1.2 * sz)
    				gem.CFrame = base * CFrame.new(0, (top + 0.32) * sz, -1.13 * sz)
    			end)
    		end
    	elseif style == "Beanie" then

    		shell(0.5, 1.15, 1.05, top, { color = cseq(pal.bright, pal.base, pal.bright), bulge = 0.35, panels = 12, breathe = true })
    		shell(1.15, 1.2, 0.4, top - 0.12, { color = cseq(pal.deep, pal.base), panels = 12 })
    		band(1.2, 0.07, top + 0.16, { color = pal.seqHot })
    		local pom = spot(CFrame.new(0, (top + 1.15) * sz, 0), "PF_Pom")
    		emitter(pom, { Enabled = true, Rate = 18, Color = pal.seqHot, Size = nseq(0.5 * sz, 0.4 * sz, 0), Lifetime = range(0.25, 0.4), Speed = range(0.2), SpreadAngle = Vector2.new(180, 180), Transparency = nseq(0.1, 1) })
    		for i = 1, 2 do
    			band(1.16 - i * 0.16, 0.05, top + 0.25 + i * 0.3, { color = (i % 2 == 0) and pal.seqHot or pal.seq, alpha = 0.35 })
    		end
    		table.insert(parts, function(t, spin, wob) pom.CFrame = CFrame.Angles(wob, 0, 0) * CFrame.new(math.sin(t * 2.1) * 0.07, (top + 1.15) * sz, 0) end)
    	elseif style == "Antenna" then

    		shell(0.9, 1.0, 0.5, top, { color = pal.seq, panels = 10, bulge = 0.2 })
    		for i = 1, 2 do
    			local a0 = spot(CFrame.new(), "PF_Rod0")
    			local a1 = spot(CFrame.new(), "PF_Rod1")
    			beam(a0, a1, { FaceCamera = true, Segments = 6, Width0 = 0.07 * sz, Width1 = 0.045 * sz, Color = pal.seqFade, Transparency = nseq(0.1) })
    			local ball = spot(CFrame.new(), "PF_Ball")
    			local lamp = emitter(ball, { Enabled = true, Rate = 18, Color = pal.seqHot, Size = nseq(0.32 * sz, 0.24 * sz, 0), Lifetime = range(0.2, 0.3), Speed = range(0), Transparency = nseq(0, 1) })
    			local ring = spot(CFrame.new(), "PF_Signal")
    			emitter(ring, { Enabled = true, Rate = 1.2, Texture = TEX.Ring, Color = pal.seqGlass, Size = nseq(0.2, 1.1 * sz, 1.4 * sz), Transparency = nseq(0.35, 0.8, 1), Lifetime = range(0.8), Speed = range(0.01), EmissionDirection = Enum.NormalId.Front, Orientation = Enum.ParticleOrientation.VelocityPerpendicular, LightEmission = 1, ZOffset = 0.05 })
    			light(ball, pal.base, 5, 1.1)
    			local side = (i == 1) and -1 or 1
    			table.insert(parts, function(t, spin, wob)
    				local sway = math.sin(t * 3 + i) * 0.25
    				local on = (math.sin(t * 5 + i * 2) > -0.2)
    				a0.CFrame = CFrame.Angles(wob, spin, 0) * CFrame.new(side * 0.5 * sz, (top + 0.5) * sz, 0)
    				a1.CFrame = CFrame.Angles(wob, spin, 0) * CFrame.new(side * (0.9 + sway) * sz, (top + 1.9) * sz, 0)
    				ball.CFrame = a1.CFrame
    				ring.CFrame = a1.CFrame
    				lamp.Rate = on and 18 or 2
    			end)
    		end
    	elseif style == "Chef" then

    		shell(1.0, 1.0, 0.5, top, { color = cseq(WHITE, pal.bright), panels = 12 })
    		shell(1.5, 1.0, 1.25, top + 0.5, { color = cseq(WHITE, pal.bright, WHITE), bulge = 0.45, panels = 12, breathe = true })
    		shell(1.5, 0, 0.02, top + 1.75, { color = cseq(WHITE, pal.bright), panels = 10 })
    		band(1.0, 0.12, top + 0.48, { color = pal.seqHot })
    		for i = 1, 3 do
    			local st = spot(CFrame.new(((i - 2) * 0.5) * sz, (top + 1.7) * sz, 0), "PF_Steam" .. i)
    			emitter(st, { Enabled = true, Rate = 4, Texture = TEX.Puff, Color = cseq(WHITE, pal.bright), Size = nseq(0.3 * sz, 0.8 * sz), Transparency = nseq(0.55, 0.75, 1), Lifetime = range(1, 1.6), Speed = range(0.6), SpreadAngle = Vector2.new(25, 25), Drag = 1.5, RotSpeed = range(-30, 30), LightEmission = 0.2 })
    			table.insert(parts, function(t, spin, wob) st.CFrame = CFrame.Angles(wob, spin, 0) * CFrame.new(((i - 2) * 0.5) * sz, (top + 1.7) * sz, 0) end)
    		end
    	elseif style == "Pirate" then

    		shell(0.9, 1.1, 0.95, top, { color = cseq(pal.deep, pal.base, pal.deep), panels = 10 })
    		for side = -1, 1, 2 do
    			band(1.6, 0.95, top + 0.6, { color = cseq(pal.deep, pal.base), span = 0.27, n = 3, phase = (side > 0) and -0.45 or math.pi - 0.45, roll = side * RAD(-38), alpha = 0.08 })
    		end
    		band(1.1, 0.1, top, { color = pal.seqHot })
    		local skull = spot(CFrame.new(0, (top + 0.55) * sz, -1.05 * sz), "PF_Skull")
    		emitter(skull, { Enabled = true, Rate = 10, Texture = TEX.Star, Color = cseq(WHITE, pal.bright), Size = nseq(0.34 * sz, 0.28 * sz, 0), Lifetime = range(0.35, 0.5), Speed = range(0), Transparency = nseq(0.05, 0.4, 1), Rotation = range(180, 180), LockedToPart = true })
    		local eyes = spot(CFrame.new(0, (top + 0.42) * sz, -0.98 * sz), "PF_SkullEyes")
    		emitter(eyes, { Enabled = true, Rate = 14, Color = pal.seqHot, Size = nseq(0.3 * sz, 0.22 * sz, 0), Lifetime = range(0.2, 0.35), Speed = range(0.15), SpreadAngle = Vector2.new(14, 4), Transparency = nseq(0, 1), LightEmission = 1 })
    		table.insert(parts, function(t, spin, wob)
    			skull.CFrame = CFrame.Angles(wob, spin, 0) * CFrame.new(0, (top + 0.55) * sz, -1.05 * sz)
    			eyes.CFrame = CFrame.Angles(wob, spin, 0) * CFrame.new(0, (top + 0.42) * sz, -0.98 * sz)
    		end)
    	elseif style == "Party Cone" then

    		shell(0.0, 0.9, 2.2, top, { color = cseq(pal.bright, pal.base, pal.bright, pal.base, pal.bright, pal.base), panels = 12, texture = TEX.Spark, texLen = 0.5, texSpeed = 0.5 })
    		band(0.9, 0.12, top, { color = pal.seqHot })
    		local tip = spot(CFrame.new(0, (top + 2.2) * sz, 0), "PF_ConeTip")
    		emitter(tip, { Enabled = true, Rate = 12, Texture = TEX.Glint, Color = pal.seqHot, Size = nseq(0.16 * sz, 0), Lifetime = range(0.5, 0.9), Speed = range(0.6), SpreadAngle = Vector2.new(180, 180), Transparency = nseq(0, 1), Rotation = range(-180, 180), RotSpeed = range(140) })
    		table.insert(parts, function(t, spin, wob) tip.CFrame = CFrame.Angles(wob, 0, 0) * CFrame.new(0, (top + 2.25) * sz, 0) end)
    	elseif style == "Fez" then

    		shell(0.85, 1.0, 1.15, top, { color = cseq(pal.base, pal.deep), panels = 12 })
    		shell(0.85, 0, 0.02, top + 1.15, { color = pal.seqFade, panels = 10 })
    		band(1.0, 0.05, top + 0.06, { color = pal.seqHot, alpha = 0.4 })
    		local a0 = spot(CFrame.new(), "PF_Tassel0")
    		local a1 = spot(CFrame.new(), "PF_Tassel1")
    		beam(a0, a1, { FaceCamera = true, Segments = 6, Width0 = 0.05 * sz, Width1 = 0.2 * sz, Color = pal.seqHot, Transparency = nseq(0, 0.2) })
    		table.insert(parts, function(t, spin, wob)
    			local sway = math.sin(t * 2.4) * 0.3
    			a0.CFrame = CFrame.Angles(wob, spin, 0) * CFrame.new(0, (top + 1.15) * sz, 0)
    			a1.CFrame = CFrame.Angles(wob, spin, 0) * CFrame.new(sway * sz, (top + 0.25) * sz, -1.05 * sz)
    		end)
    	elseif style == "Bamboo" then

    		shell(0.15, 2.4, 1.1, top, { color = cseq(pal.bright, pal.base, pal.deep), bulge = 0.12, panels = 16, texture = TEX.Smoke, texLen = 1.5, texSpeed = 0 })
    		band(2.4, 0.15, top, { color = pal.seqHot })
    		band(1.4, 0.05, top + 0.5, { color = pal.seqGlass, alpha = 0.4, spin = -1 })
    		band(0.5, 0.05, top + 0.95, { color = pal.seqGlass, alpha = 0.4, spin = 1 })
    		local leaves = q(5, 3)
    		for i = 1, leaves do
    			local lf = spot(CFrame.new(), "PF_BambooLeaf")
    			emitter(lf, { Enabled = true, Rate = 3, Texture = TEX.Scratch, Color = cseq(Color3.fromRGB(120, 200, 110), Color3.fromRGB(70, 140, 70)), Size = nseq(0.12 * sz, 0.5 * sz), Lifetime = range(1.2), Speed = range(0), Transparency = nseq(0.1, 0.4), Rotation = range(-70, -110), LockedToPart = true })
    			local th = i / leaves * TAU
    			table.insert(parts, function(t, spin, wob)
    				lf.CFrame = CFrame.Angles(wob, spin + th, 0) * CFrame.new(0, (top - 0.15) * sz, -2.3 * sz) * CFrame.Angles(0, 0, 0.5)
    			end)
    		end
    	elseif style == "Mushroom" then

    		shell(0.6, 0.75, 0.9, top, { color = cseq(WHITE, pal.bright), panels = 10 })
    		shell(0.3, 1.9, 1.05, top + 0.6, { color = cseq(pal.bright, pal.base, pal.deep), bulge = 0.5, panels = 14, breathe = true })
    		local dots = q(7, 4)
    		for i = 1, dots do
    			local a = spot(CFrame.new(), "PF_Dot")
    			emitter(a, { Enabled = true, Rate = 8, Color = cseq(WHITE, pal.bright), Size = nseq(0.3 * sz, 0.24 * sz, 0), Lifetime = range(0.3, 0.45), Speed = range(0), Transparency = nseq(0.05, 0.5, 1) })
    			local th = i / dots * TAU
    			local hgt = 1.0 + (i % 2) * 0.4
    			table.insert(parts, function(t, spin, wob)
    				local r = 1.9 * (1 - (hgt - 0.6) / 1.05) * 0.92
    				a.CFrame = CFrame.Angles(wob, spin + th, 0) * CFrame.new(0, (top + hgt) * sz, -r * sz)
    			end)
    		end
    		emitter(spot(CFrame.new(0, (top + 1.2) * sz, 0), "PF_Spores"), { Enabled = true, Rate = q(7, 3), Texture = TEX.Mote, Color = pal.seqHot, Size = nseq(0.12, 0), Lifetime = range(1.2, 2), Speed = range(0.4), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -0.6, 0), Transparency = nseq(0, 1) })
    	elseif style == "Ice Crown" then

    		shell(1.15, 1.0, 0.6, top, { color = cseq(Color3.fromRGB(215, 245, 255), pal.bright), panels = 12, transparency = nseq(0.15, 0.4) })
    		band(1.0, 0.12, top, { color = cseq(WHITE, Color3.fromRGB(190, 235, 255)) })
    		local spikes = q(7, 5)
    		for i = 1, spikes do
    			local a0 = spot(CFrame.new(), "PF_Ice0")
    			local a1 = spot(CFrame.new(), "PF_Ice1")
    			beam(a0, a1, { FaceCamera = true, Segments = 1, Width0 = 0.26 * sz, Width1 = 0.005, Color = cseq(WHITE, Color3.fromRGB(170, 225, 255), pal.bright), Transparency = nseq(0.1, 0.3), LightEmission = 0.8 })
    			local th = i / spikes * TAU
    			local h = 0.9 + (i % 3) * 0.45
    			table.insert(parts, function(t, spin, wob)
    				local base = CFrame.Angles(wob, spin + th, 0)
    				a0.CFrame = base * CFrame.new(0, (top + 0.58) * sz, -1.08 * sz)
    				a1.CFrame = base * CFrame.new(math.sin(t * 2 + i) * 0.02, (top + 0.58 + h) * sz, -1.08 * sz)
    			end)
    		end
    		emitter(spot(CFrame.new(0, (top + 0.7) * sz, 0), "PF_Frost"), { Enabled = true, Rate = q(9, 4), Texture = TEX.Star, Color = cseq(WHITE, Color3.fromRGB(190, 235, 255)), Size = nseq(0.14, 0.08, 0), Lifetime = range(1, 1.8), Speed = range(0.5), SpreadAngle = Vector2.new(80, 80), Acceleration = Vector3.new(0, -1.4, 0), Drag = 1.5, Transparency = nseq(0, 1), Rotation = range(-180, 180), RotSpeed = range(-90, 90) })
    	elseif style == "Fire Crown" then

    		shell(1.1, 0.95, 0.55, top, { color = cseq(Color3.fromRGB(60, 30, 20), pal.deep), panels = 12 })
    		band(0.95, 0.12, top, { color = cseq(Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 90, 20)) })
    		local flames = q(8, 5)
    		for i = 1, flames do
    			local a = spot(CFrame.new(), "PF_Flame" .. i)
    			emitter(a, { Enabled = true, Rate = 14, Texture = TEX.Fire, Color = cseq(WHITE, Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 80, 15)), Size = nseq(0.34 * sz, 0.1, 0), Lifetime = range(0.35, 0.6), Speed = range(1.6, 2.6), SpreadAngle = Vector2.new(9, 9), Acceleration = Vector3.new(0, 3, 0), Transparency = nseq(0, 0.4, 1), LightEmission = 1 })
    			local th = i / flames * TAU
    			table.insert(parts, function(t, spin, wob)
    				local k = 1 + 0.2 * math.sin(t * 9 + i * 2.2)
    				a.CFrame = CFrame.Angles(wob, spin + th, 0) * CFrame.new(0, (top + 0.5 * k) * sz, -1.02 * sz)
    			end)
    		end
    		emitter(spot(CFrame.new(0, (top + 0.9) * sz, 0), "PF_EmberFall"), { Enabled = true, Rate = q(8, 3), Texture = TEX.Ember, Color = cseq(Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 90, 20)), Size = nseq(0.12, 0.05, 0), Lifetime = range(0.8, 1.4), Speed = range(0.8), SpreadAngle = Vector2.new(70, 70), Acceleration = Vector3.new(0, -3.5, 0), Transparency = nseq(0, 1), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-1.8, -0.4), Rotation = range(0), RotSpeed = range(0) })
    	elseif style == "Nimbus" then

    		for i = 1, q(6, 4) do
    			shell(1.35, 1.5, 0.5, top + 0.35, { color = cseq(WHITE, pal.bright, WHITE), bulge = 0.55, panels = 10, breathe = true, transparency = nseq(0.2, 0.45) })
    		end
    		band(0.85, 0.07, top + 1.05, { color = pal.seqHot, texture = TEX.Spark, texLen = 0.8, texSpeed = 0.8 })
    		emitter(spot(CFrame.new(0, (top + 0.5) * sz, 0), "PF_NimbusPuff"), { Enabled = true, Rate = q(10, 4), Texture = TEX.Puff, Color = cseq(WHITE, pal.bright), Size = nseq(1.1 * sz, 1.6 * sz), Transparency = nseq(0.4, 0.6, 1), Lifetime = range(1, 1.6), Speed = range(0.3), SpreadAngle = Vector2.new(180, 180), Drag = 2, RotSpeed = range(-25, 25), LightEmission = 0.25 })
    		emitter(spot(CFrame.new(0, (top + 0.2) * sz, 0), "PF_NimbusRay"), { Enabled = true, Rate = q(3, 1), Texture = TEX.Scratch, Color = cseq(WHITE, pal.bright), Size = nseq(0.3, 1.3 * sz), Transparency = nseq(0.45, 0.9, 1), Lifetime = range(1.2), Speed = range(0.01), EmissionDirection = Enum.NormalId.Bottom, Orientation = Enum.ParticleOrientation.VelocityPerpendicular, LightEmission = 0.7, ZOffset = -0.1 })
    	elseif style == "Storm Cloud" then

    		for i = 1, 2 do
    			shell(1.4 - i * 0.15, 1.6 - i * 0.1, 0.45, top + 0.4 - i * 0.15, { color = cseq(pal.deep, tint(pal.deep, -0.5), pal.deep), bulge = 0.5, panels = 12, transparency = nseq(0.15 + i * 0.1, 0.4) })
    		end
    		emitter(spot(CFrame.new(0, (top + 0.1) * sz, 0), "PF_StormRain"), { Enabled = true, Rate = q(20, 8), Texture = TEX.Drop, Color = cseq(pal.bright, pal.base), Size = nseq(0.12 * sz, 0.1 * sz), Lifetime = range(0.5, 0.8), Speed = range(6, 9), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(14, 14), Acceleration = Vector3.new(0, -20, 0), Transparency = nseq(0.25, 0.5, 1), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-1.6), Rotation = range(0), RotSpeed = range(0), LightEmission = 0.5, Shape = Enum.ParticleEmitterShape.Disc, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume, ShapePartial = 1 })
    		local boltSpot = spot(CFrame.new(0, (top + 0.3) * sz, 0), "PF_StormBoltHost")
    		local stormBolt = makeBolt(head, { K = 5, Width = 0.06, Color = cseq(WHITE, pal.bright) })
    		Hat:keep(stormBolt)
    		table.insert(parts, function(t, spin, wob)
    			local flash = math.sin(t * 1.1) > 0.93
    			if flash then
    				local dir = CFrame.Angles(0, math.random() * TAU, 0)
    				stormBolt:set((boltSpot.CFrame * dir * CFrame.new(0, 0.2, -0.3)).Position, (boltSpot.CFrame * dir * CFrame.new(0, -1.6, -0.6)).Position, 0.5, t * 22)
    			end
    			stormBolt:alpha(flash and 0.1 or 1)
    		end)
    	else

    		shell(0.95, 1.05, 0.8, top, { color = cseq(pal.deep, pal.base, pal.deep), bulge = 0.3, panels = 12, transparency = nseq(0.2, 0.4) })
    		band(1.05, 0.08, top, { color = pal.seqHot })
    		local stars = q(6, 4)
    		for i = 1, stars do
    			local a = spot(CFrame.new(), "PF_OrbitStar" .. i)
    			emitter(a, { Enabled = true, Rate = 10, Texture = TEX.Star, Color = (i % 2 == 0) and pal.seqHot or pal.seqGlass, Size = nseq(0.3 * sz, 0.24 * sz), Lifetime = range(0.4), Speed = range(0), Transparency = nseq(0, 0.2, 1), Rotation = range(0, 72), RotSpeed = range(80), LockedToPart = true, ZOffset = 0.06 })
    			local th = i / stars * TAU
    			local tilt = RAD(28 + (i % 3) * 18)
    			table.insert(parts, function(t, spin, wob)
    				a.CFrame = CFrame.new(0, (top + 0.5) * sz, 0) * CFrame.Angles(wob + tilt, spin * (0.6 + i * 0.1) + th, 0) * CFrame.new(1.35 * sz, 0, 0)
    			end)
    		end
    		emitter(spot(CFrame.new(0, (top + 0.9) * sz, 0), "PF_StarDust"), { Enabled = true, Rate = q(5, 2), Texture = TEX.Star, Color = pal.seqGlass, Size = nseq(0.14, 0.08, 0), Lifetime = range(1, 1.7), Speed = range(0.4), SpreadAngle = Vector2.new(50, 50), Acceleration = Vector3.new(0, -2, 0), Transparency = nseq(0, 1), Rotation = range(-180, 180), RotSpeed = range(120) })
    	end

    	if cfg.Fringe then
    		local n = q(7, 4)
    		local outer = 0
    		for _, l in ipairs(loops) do outer = math.max(outer, l.r) end
    		for _, s in ipairs(shells) do outer = math.max(outer, s.rb, s.rt) end
    		if outer == 0 then outer = 1.2 * sz end
    		for i = 1, n do
    			local th = i / n * TAU
    			local a0 = spot(CFrame.new(), "PF_Fringe0")
    			local a1 = spot(CFrame.new(), "PF_Fringe1")
    			beam(a0, a1, { FaceCamera = true, Segments = 6, Width0 = 0.1 * sz, Width1 = 0.02, Color = pal.seqHot, Transparency = nseq(0, 0.8) })
    			table.insert(parts, function(t, spin, wob)
    				local base = CFrame.Angles(wob, spin + th, 0)
    				local sway = math.sin(t * 3 + i) * 0.2
    				a0.CFrame = base * CFrame.new(0, top * sz, -outer) * frameX(Vector3.zero, Vector3.new(0, -1, 0))
    				a1.CFrame = base * CFrame.new(sway, top * sz - 0.8 * sz, -outer - 0.15) * frameX(Vector3.zero, Vector3.new(sway, -1, -0.3))
    			end)
    		end
    	end
    	if cfg.Glow then
    		local a = spot(CFrame.new(0, (top + 0.8) * sz, 0), "PF_HatGlow")
    		light(a, pal.base, 7 * sz, 1.2)
    		emitter(a, { Enabled = true, Rate = 5, Texture = TEX.Field, Color = pal.seqFade, Size = nseq(2.4 * sz, 2.8 * sz), Transparency = nseq(0.92, 0.86, 0.92), Lifetime = range(0.6), Speed = range(0), LockedToPart = true, ZOffset = -1 })
    	end

    	Hat:onPaint(function(p)
    		for _, s in ipairs(shells) do s.sh:color(p.seq) end
    		for _, l in ipairs(loops) do l.loop:color(p.seqHot) end
    	end)

    	local angle = 0
    	Tick.use("Hat", function(dt, t)
    		angle = angle + dt * (S.Hat.Spin or 0)
    		local spin = angle + (S.Spin.Enabled and Tick.spin or 0)
    		local wob = Tick.wobble + 0.1 * organicNoise(t * 0.85, 4.4)
    		local bob = S.Hat.Bob and (math.sin(t * 2.2) + 0.3 * organicNoise(t * 1.4, 2.9)) * 0.03 * sz or 0
    		for _, s in ipairs(shells) do
    			local br = s.breathe and (1 + 0.05 * math.sin(t * 2)) or 1
    			local swayX = s.sway and math.sin(t * 1.7) * s.sway or 0
    			s.sh:set(CFrame.new(0, s.y + bob, 0) * CFrame.Angles(wob + swayX, 0, 0), s.rt * br, s.rb * br, s.h, s.bulge, spin * s.spinMul)
    		end
    		for _, l in ipairs(loops) do
    			l.loop.center = CFrame.new(0, l.y + bob, 0) * CFrame.Angles(wob + l.tilt, 0, l.roll)
    			l.loop:set(l.r, l.w, nil, spin * l.spinMul + l.phase)
    		end
    		for _, fn in ipairs(parts) do fn(t, spin, wob) end
    	end)
    	Hat.built = true
    end

    local Glow = defineModule("Glow", {
    	Enabled = false, Color = Color3.fromRGB(120, 200, 255), Range = 12, Brightness = 2,
    	Pulse = true, Shift = true, Outline = false, HPLink = false, Second = false, Bloom = false, Shadows = false,
    })
    Glow.selfRainbow = true
    function Glow.build()
    	Glow:clear()
    	if not S.Glow.Enabled or not alive() then return end
    	local cfg = S.Glow
    	local a = attach(Char.torso, CFrame.new(), "PF_Glow")
    	Glow:keep(a)
    	local l = light(a, cfg.Color, cfg.Range, cfg.Brightness)
    	pcall(function() l.Shadows = cfg.Shadows and true or false end)
    	local bloom = nil
    	if cfg.Bloom then

    		bloom = emitter(a, { Enabled = true, Rate = 8, Texture = TEX.Field, Color = ColorSequence.new(cfg.Color), Size = nseq(5, 5.6), Transparency = nseq(0.9, 0.84, 0.9), Lifetime = range(0.4), Speed = range(0), LockedToPart = true, ZOffset = -2, RotSpeed = range(10) })
    	end
    	local l2 = nil
    	if cfg.Second then
    		local a2 = attach(Char.head, CFrame.new(0, 0.5, 0), "PF_Glow2")
    		Glow:keep(a2)
    		l2 = light(a2, tint(cfg.Color, 0.5), cfg.Range * 0.5, cfg.Brightness * 0.6)
    	end
    	local hl
    	if cfg.Outline then
    		local okH, inst = pcall(Instance.new, "Highlight")
    		if okH then
    			hl = inst
    			hl.Adornee = Char.model
    			hl.FillTransparency = 1
    			hl.OutlineColor = cfg.Color
    			hl.OutlineTransparency = 0.1
    			hl.DepthMode = Enum.HighlightDepthMode.Occluded
    			hl.Parent = folder()
    			Glow:keep(hl)
    		end
    	end
    	local hue = 0
    	Tick.use("Glow", function(dt, t)
    		local c = S.Glow
    		local k, frac, hpK = 1, 1, 1
    		if c.HPLink then frac = hpFrac() hpK = 0.35 + 0.65 * frac end
    		if c.Pulse then k = 0.65 + 0.35 * math.sin(t * (2.4 + (1 - frac) * 5)) end
    		l.Brightness = c.Brightness * k * hpK
    		l.Range = c.Range * (0.9 + 0.1 * k) * (0.7 + 0.3 * hpK)
    		local color = RainbowHue.Glow and Color3.fromHSV(RainbowHue.Glow, 0.85, 1) or c.Color
    		if c.Shift then
    			hue = (hue + dt * 0.08) % 1
    			color = Color3.fromHSV(hue, 0.7, 1):Lerp(c.Color, 0.35)
    		end
    		if c.HPLink and frac < 0.5 then color = color:Lerp(Color3.fromRGB(255, 40, 40), (0.5 - frac) * 1.6) end
    		l.Color = color
    		if bloom then bloom.Color = ColorSequence.new(color) end
    		if l2 then l2.Color = tint(color, 0.5) l2.Brightness = c.Brightness * 0.6 * k end
    		if hl then
    			hl.OutlineColor = color
    			hl.OutlineTransparency = 0.1 + (1 - k) * 0.5
    		end
    	end)
    	Glow.built = true
    end

    local Aura = defineModule("Aura", {
    	Enabled = false, Color = Color3.fromRGB(180, 130, 255), Shape = "Orbit Rings", Count = 6, Radius = 3, Speed = 1.2,
    })
    Aura.Shapes = { "Orbit Rings", "Double Helix", "Cage Bolts", "Rising Glyphs", "Ember Pit", "Snowfall", "Bubbles", "Moths", "Sonar", "Shattered Halo", "Vines", "Static", "Power Up", "Star Shower", "Ground Fog", "Sakura Drift" }

    function Aura.build()
    	Aura:clear()
    	if not S.Aura.Enabled or not alive() then return end
    	local cfg = S.Aura
    	local pal = paletteFor("Aura", cfg)
    	local root = Char.root
    	local shape = cfg.Shape
    	local R = cfg.Radius
    	local n = q(cfg.Count, 3)
    	local movers = {}
    	local function node(name) local a = attach(root, CFrame.new(), name or "PF_AuraNode") Aura:keep(a) return a end

    	if shape == "Orbit Rings" then

    		for i = 1, math.min(n, 4) do
    			local loop = makeLoop(root, CFrame.new(), R, { Color = (i % 2 == 0) and pal.seq or pal.seqHot, Width = 0.08, Alpha = 0.1, Name = "PF_AuraLoop", Span = 0.7, N = 4 })
    			Aura:keep(loop)
    			movers[i] = function(t, spd)
    				loop.center = CFrame.new(0, -1.5 + i * 0.85 + math.sin(t * spd + i) * 0.3, 0) * CFrame.Angles(math.sin(t * 0.7 + i) * 0.38, 0, math.cos(t * 0.6 + i) * 0.38)
    				loop:set(R * (0.8 + 0.1 * i) * (1 + 0.04 * math.sin(t * 1.7 + i * 2)), 0.08, nil, t * spd * (i % 2 == 0 and 1 or -1.3))
    			end
    		end
    	elseif shape == "Double Helix" then

    		local per = math.max(3, math.floor(n / 2))
    		local strandA, strandB = {}, {}
    		for i = 1, per do
    			strandA[i] = node("PF_HelixA" .. i)
    			strandB[i] = node("PF_HelixB" .. i)
    			emitter(strandA[i], { Enabled = true, Rate = 20, Color = pal.seqHot, Size = nseq(0.26, 0.16, 0), Lifetime = range(0.25, 0.4), Speed = range(0.2), Transparency = nseq(0, 1) })
    			emitter(strandB[i], { Enabled = true, Rate = 20, Color = pal.seq, Size = nseq(0.26, 0.16, 0), Lifetime = range(0.25, 0.4), Speed = range(0.2), Transparency = nseq(0, 1) })
    			if i > 1 then
    				beam(strandA[i - 1], strandA[i], { FaceCamera = true, Segments = 2, Width0 = 0.05, Width1 = 0.05, Color = pal.seqHot, Transparency = nseq(0.35) })
    				beam(strandB[i - 1], strandB[i], { FaceCamera = true, Segments = 2, Width0 = 0.05, Width1 = 0.05, Color = pal.seq, Transparency = nseq(0.35) })
    			end
    			beam(strandA[i], strandB[i], { FaceCamera = true, Segments = 1, Width0 = 0.03, Width1 = 0.03, Color = pal.seqGlass, Transparency = nseq(0.6) })
    			movers[i] = function(t, spd)
    				local y = -2.2 + (((t * spd * 0.4) + i / per) % 1) * 4.6
    				local a = y * 1.4 + t * spd * 0.4
    				strandA[i].CFrame = CFrame.new(math.cos(a) * R * 0.75, y, math.sin(a) * R * 0.75)
    				strandB[i].CFrame = CFrame.new(math.cos(a + math.pi) * R * 0.75, y, math.sin(a + math.pi) * R * 0.75)
    			end
    		end
    	elseif shape == "Cage Bolts" then

    		local bars = math.max(3, math.min(n, 6))
    		local bolts = {}
    		for i = 1, bars do
    			bolts[i] = makeBolt(root, { K = 5, Width = 0.1, Color = cseq(WHITE, pal.bright) })
    			Aura:keep(bolts[i])
    		end
    		movers[1] = function(t, spd)
    			for i = 1, bars do
    				local a = i / bars * TAU + t * spd * 1.4
    				local p0 = CFrame.new(math.cos(a) * R * 0.8, 2.2, math.sin(a) * R * 0.8)
    				local p1 = CFrame.new(math.cos(a + 0.5) * R * 0.8, -2.6, math.sin(a + 0.5) * R * 0.8)
    				bolts[i]:set(p0.Position, p1.Position, 0.6, t * 14 + i)
    				bolts[i]:alpha((math.sin(t * 11 + i * 2.2) > 0.1) and 0.12 or 0.9)
    			end
    		end
    		for i = 1, math.min(n, 3) do
    			local s = node("PF_CageSpark")
    			emitter(s, { Enabled = true, Rate = 12, Texture = TEX.Glint, Color = pal.seqGlass, Size = nseq(0.2, 0.12, 0), Lifetime = range(0.2, 0.35), Speed = range(0), Transparency = nseq(0, 1) })
    			movers[#movers + 1] = function(t, spd)
    				local a = i / 3 * TAU - t * spd * 2
    				s.CFrame = CFrame.new(math.cos(a) * R * 0.8, math.sin(t * 3 + i * 2) * 2.2, math.sin(a) * R * 0.8)
    			end
    		end
    	do
    		local alist, aupd = PFPrim.assembleFX(root, { kind = "cage", r = R * 0.8, h = 4.8, y = -0.2, n = q(18, 10), dur = 1.4, color = cseq(WHITE, pal.bright), size = 0.12, spread = 3, spin = 0.25 })
    		for _, it in ipairs(alist) do Aura:keep(it.a) Aura:keep(it.e) end
    		movers[#movers + 1] = function(t, spd) aupd(t, t * 0.3) end
    	end
    	elseif shape == "Rising Glyphs" then

    		for i = 1, n do
    			local g = node("PF_Glyph" .. i)
    			emitter(g, { Enabled = true, Rate = 3, Texture = (i % 2 == 0) and TEX.Swirl or TEX.Trace, Color = pal.seqHot, Size = nseq(0.3, 0.26), Transparency = nseq(0.35, 0.2, 1), Lifetime = range(1.4, 2), Speed = range(0), Orientation = Enum.ParticleOrientation.VelocityPerpendicular, LockedToPart = true, Rotation = range(-180, 180), RotSpeed = range(-40, 40), ZOffset = 0.05 })
    			movers[i] = function(t, spd)
    				local k = ((t * spd * 0.22 + i / n) % 1)
    				local a = i / n * TAU + t * spd * 0.3
    				g.CFrame = CFrame.new(math.cos(a) * R * 0.55, -2 + k * 4.4, math.sin(a) * R * 0.55) * CFrame.Angles(0, math.rad(k * 90), 0)
    			end
    		end
    	elseif shape == "Ember Pit" then

    		local loop = makeLoop(root, CFrame.new(0, -2.6, 0), R, { Color = cseq(WHITE, pal.bright, pal.base, tint(pal.deep, -0.4)), Width = 0.3, Alpha = 0.1, Name = "PF_EmberRing", Texture = TEX.Fire, TextureMode = Enum.TextureMode.Wrap, TextureLength = 1.2, TextureSpeed = -2, Segments = 14, N = 12 })
    		Aura:keep(loop)
    		movers[1] = function(t, spd) loop:set(R * (1 + 0.05 * math.sin(t * 3)), 0.3, nil, t * spd * 2) end
    		for i = 1, math.max(2, math.floor(n / 2)) do
    			local e = node("PF_EmberUp" .. i)
    			emitter(e, { Enabled = true, Rate = 8, Texture = TEX.Ember, Color = cseq(WHITE, pal.bright, pal.base), Size = nseq(0.14, 0.05, 0), Lifetime = range(0.8, 1.4), Speed = range(1.5, 3), SpreadAngle = Vector2.new(12, 12), Acceleration = Vector3.new(0, 2.5, 0), Transparency = nseq(0, 1), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-1.8, -0.4), Rotation = range(0), RotSpeed = range(0) })
    			movers[#movers + 1] = function(t, spd)
    				local a = i / n * TAU + t * spd * 0.6
    				e.CFrame = CFrame.new(math.cos(a) * R * 0.7, -2.5, math.sin(a) * R * 0.7)
    			end
    		end
    	elseif shape == "Snowfall" then

    		local s = node("PF_SnowTop")
    		emitter(s, { Enabled = true, Rate = q(26, 10), Texture = TEX.Star, Color = cseq(WHITE, pal.bright), Size = nseq(0.16, 0.1), Lifetime = range(1.8, 2.6), Speed = range(0.4, 1), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(35, 35), Acceleration = Vector3.new(0, -2.2, 0), Drag = 0.6, Transparency = nseq(0.05, 0.3, 1), Rotation = range(-180, 180), RotSpeed = range(-90, 90), Shape = Enum.ParticleEmitterShape.Disc, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume, ShapePartial = 1 })
    		movers[1] = function(t, spd) s.CFrame = CFrame.new(0, 3.4, 0) * CFrame.Angles(0, t * spd * 0.3, 0) end
    		local mist = node("PF_SnowMist")
    		emitter(mist, { Enabled = true, Rate = q(6, 2), Texture = TEX.Puff, Color = cseq(WHITE, pal.bright), Size = nseq(1.2, 2.2), Transparency = nseq(0.75, 0.9, 1), Lifetime = range(1.4, 2), Speed = range(0.5), SpreadAngle = Vector2.new(180, 180), Drag = 2, LightEmission = 0.2 })
    		movers[2] = function(t, spd) mist.CFrame = CFrame.new(0, -2.2, 0) end
    	elseif shape == "Bubbles" then

    		for i = 1, n do
    			local b = node("PF_Bubble" .. i)
    			emitter(b, { Enabled = true, Rate = 1.6, Texture = TEX.Circle, Color = cseq(WHITE, pal.bright), Size = nseq(0.24, 0.5, 0.55), Transparency = nseq(0.5, 0.25, 0.6, 1), Lifetime = range(1.6, 2.4), Speed = range(0.2), SpreadAngle = Vector2.new(180, 180), Drag = 1, Transparency = nseq(0.5, 0.25, 0.6, 1), Rotation = range(-180, 180), RotSpeed = range(-30, 30), LightEmission = 0.5 })
    			movers[i] = function(t, spd)
    				local k = ((t * spd * 0.16 + i / n) % 1)
    				local a = i / n * TAU + math.sin(t * spd + i) * 0.4
    				b.CFrame = CFrame.new(math.cos(a) * R * (0.4 + k * 0.5), -2.4 + k * 5, math.sin(a) * R * (0.4 + k * 0.5)) * CFrame.Angles(math.sin(t * 2 + i) * 0.3, 0, math.cos(t * 1.7 + i) * 0.3)
    			end
    		end
    	elseif shape == "Moths" then

    		for i = 1, math.max(3, math.min(n, 6)) do
    			local m = node("PF_Moth" .. i)
    			emitter(m, { Enabled = true, Rate = 10, Texture = TEX.Glint, Color = cseq(WHITE, pal.bright), Size = nseq(0.22, 0.15, 0), Lifetime = range(0.3), Speed = range(0), Transparency = nseq(0, 1), Rotation = range(-180, 180), RotSpeed = range(120) })
    			local m2 = node("PF_MothT" .. i)
    			trail(m, m2, { Color = pal.seqHot, Lifetime = 0.35, WidthScale = nseq(0.5, 0), Transparency = nseq(0.5, 1), FaceCamera = true })
    			movers[i] = function(t, spd)
    				local a = i / n * TAU + t * spd * 0.9
    				local flutter = math.sin(t * 9 + i * 2) * 0.35
    				m.CFrame = CFrame.new(math.cos(a) * R * 0.8, math.sin(t * 1.4 + i * 1.3) * 1.6 + flutter, math.sin(a) * R * 0.8)
    				m2.CFrame = m.CFrame * CFrame.new(0, -0.1, 0)
    			end
    		end
    	elseif shape == "Sonar" then

    		local rings = {}
    		for i = 1, 3 do
    			local loop = makeLoop(root, CFrame.new(0, -2.5, 0), 0.3, { Color = i == 1 and pal.seqHot or pal.seq, Width = 0.1, Alpha = 0, Name = "PF_Sonar", Segments = 3, N = 3 })
    			Aura:keep(loop)
    			rings[i] = loop
    		end
    		movers[1] = function(t, spd)
    			for i, loop in ipairs(rings) do
    				local k = ((t * spd * 0.5 + i / 3) % 1)
    				loop:set(0.3 + k * R * 1.6, 0.1 * (1 - k) + 0.02, k * 0.9, t * 0.5)
    			end
    		end
    		for i = 1, 2 do
    			local d = node("PF_SonarDot" .. i)
    			emitter(d, { Enabled = true, Rate = 6, Texture = TEX.Glint, Color = pal.seqHot, Size = nseq(0.18, 0.1, 0), Lifetime = range(0.3), Speed = range(0), Transparency = nseq(0, 1) })
    			movers[#movers + 1] = function(t, spd)
    				local a = t * spd * (i == 1 and 1.2 or -0.9)
    				d.CFrame = CFrame.new(math.cos(a) * R, math.sin(t * 2 + i) * 1.4, math.sin(a) * R)
    			end
    		end
    	elseif shape == "Shattered Halo" then

    		for i = 1, math.max(4, math.min(n, 7)) do
    			local loop = makeLoop(root, CFrame.new(0, 1.7, 0), 1.1, { Color = (i % 2 == 0) and pal.seq or pal.seqHot, Width = 0.12, Alpha = 0.05, Name = "PF_ShadHalo", Span = 0.13, N = 2 })
    			Aura:keep(loop)
    			movers[i] = function(t, spd)
    				loop.center = CFrame.new(0, 1.7 + math.sin(t * 1.4 + i * 1.8) * 0.22, 0) * CFrame.Angles(math.sin(t + i) * 0.3, 0, math.cos(t * 0.8 + i) * 0.3)
    				loop:set(1.1 * (0.9 + 0.15 * math.sin(t * 2 + i)), 0.12, nil, i / n * TAU + t * spd * (0.6 + (i % 3) * 0.3))
    			end
    		end
    	do
    		local alist, aupd = PFPrim.assembleFX(root, { kind = "ring", r = 2.3, y = 2.1, n = q(16, 9), dur = 1.3, color = pal.seqGlass, color2 = pal.seqHot, size = 0.14, tex = TEX.Scratch, spread = 3.4, spin = 0.5 })
    		for _, it in ipairs(alist) do Aura:keep(it.a) Aura:keep(it.e) end
    		movers[#movers + 1] = function(t, spd) aupd(t, t * spd * 0.2) end
    	end
    	elseif shape == "Vines" then

    		for i = 1, math.max(3, math.min(n, 5)) do
    			local a0 = node("PF_Vine0" .. i)
    			local a1 = node("PF_Vine1" .. i)
    			local b = beam(a0, a1, { FaceCamera = true, Segments = 10, Width0 = 0.09, Width1 = 0.02, Color = cseq(pal.bright, pal.base, pal.deep), Transparency = nseq(0.15, 0.5) })
    			local leaf = node("PF_VineLeaf" .. i)
    			emitter(leaf, { Enabled = true, Rate = 4, Texture = TEX.Heart, Color = cseq(pal.bright, pal.base), Size = nseq(0.16, 0.12), Transparency = nseq(0.2, 0.5, 1), Lifetime = range(0.5), Speed = range(0), Rotation = range(-180, 180), RotSpeed = range(-60, 60) })
    			movers[i] = function(t, spd)
    				local a = i / n * TAU + t * spd * 0.25
    				local ph = t * 2 + i * 2
    				a0.CFrame = CFrame.new(math.cos(a) * R * 0.75, -2.6, math.sin(a) * R * 0.75)
    				a1.CFrame = CFrame.new(math.cos(a + math.sin(ph) * 0.5) * R * 0.75, -2.6 + (2.2 + math.sin(ph * 0.7) * 0.8), math.sin(a + math.sin(ph) * 0.5) * R * 0.75)
    				b.CurveSize0 = math.sin(ph) * 1.2
    				b.CurveSize1 = math.sin(ph + 1) * 0.9
    				leaf.CFrame = a1.CFrame
    			end
    		end
    	elseif shape == "Static" then

    		for i = 1, n do
    			local a = node("PF_StaticOrb")
    			emitter(a, { Enabled = true, Rate = 30, Color = cseq(WHITE, pal.bright), Size = nseq(0.22, 0), Lifetime = range(0.15, 0.3), Speed = range(0), Transparency = nseq(0, 1) })
    			movers[i] = function(t, spd)
    				local ang = i / n * TAU + t * spd * 2.2
    				a.CFrame = CFrame.Angles(0, ang, 0) * CFrame.new(0, math.sin(t * 5 * spd + i * 1.7) * 1.6, -R * (0.8 + 0.2 * math.sin(t * 3 + i)))
    			end
    		end
    		local bolt = makeBolt(root, { K = 5, Width = 0.12, Color = cseq(WHITE, pal.bright) })
    		Aura:keep(bolt)
    		local nodes = {}
    		for _, c in ipairs(Aura.items) do if typeof(c) == "Instance" and c.Name == "PF_StaticOrb" then table.insert(nodes, c) end end
    		movers[#movers + 1] = function(t, spd)
    			if #nodes < 2 then return end
    			local i = math.floor(t * 6) % #nodes + 1
    			local j = (i + math.floor(#nodes / 2) - 1) % #nodes + 1
    			bolt:set(nodes[i].CFrame.Position, nodes[j].CFrame.Position, 0.5, t * 20)
    			bolt:alpha((math.sin(t * 15) > 0.5) and 0.1 or 1)
    		end
    	elseif shape == "Power Up" then

    		local col = node("PF_PowerCol")
    		emitter(col, { Enabled = true, Rate = q(30, 12), Texture = TEX.Spark, Color = cseq(WHITE, pal.bright, pal.base), Size = nseq(0.5, 0.2, 0), Lifetime = range(0.5, 0.9), Speed = range(3, 6), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(6, 6), Transparency = nseq(0, 0.4, 1), LightEmission = 1, Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-1.2, -0.2), Shape = Enum.ParticleEmitterShape.Disc, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume, ShapePartial = 1 })
    		movers[1] = function(t, spd) col.CFrame = CFrame.new(0, -2.4, 0) end
    		for i = 1, math.max(3, math.min(n, 5)) do
    			local p = node("PF_PowerPull" .. i)
    			emitter(p, { Enabled = true, Rate = 14, Texture = TEX.Glint, Color = pal.seqHot, Size = nseq(0.2, 0.1, 0), Lifetime = range(0.3, 0.5), Speed = range(0), Transparency = nseq(0, 1) })
    			movers[#movers + 1] = function(t, spd)
    				local k = ((t * spd * 0.7 + i / n) % 1)
    				local a = i / n * TAU + t * spd
    				p.CFrame = CFrame.new(math.cos(a) * R * (1 - k * 0.85), -2 + k * 4, math.sin(a) * R * (1 - k * 0.85))
    			end
    		end
    		local rings = {}
    		for i = 1, 2 do
    			local loop = makeLoop(root, CFrame.new(0, -2.5, 0), 0.3, { Color = pal.seqHot, Width = 0.14, Alpha = 0, Name = "PF_PowerRing", Segments = 3, N = 3 })
    			Aura:keep(loop)
    			rings[i] = loop
    		end
    		movers[#movers + 1] = function(t, spd)
    			for i, loop in ipairs(rings) do
    				local k = ((t * spd * 0.8 + i / 2) % 1)
    				loop:set(0.4 + k * R * 1.3, 0.16 * (1 - k), k * 0.8, t * spd)
    			end
    		end
    	elseif shape == "Star Shower" then

    		for i = 1, math.max(3, math.min(n, 6)) do
    			local s = node("PF_Shower" .. i)
    			local s2 = node("PF_ShowerT" .. i)
    			emitter(s, { Enabled = true, Rate = 8, Texture = TEX.Star, Color = cseq(WHITE, pal.bright), Size = nseq(0.24, 0.18), Lifetime = range(0.35), Speed = range(0), Transparency = nseq(0, 0.3, 1), Rotation = range(0, 72), RotSpeed = range(90), LockedToPart = true })
    			trail(s, s2, { Color = pal.seqHot, Lifetime = 0.4, WidthScale = nseq(0.6, 0), Transparency = nseq(0.2, 1), FaceCamera = true })
    			movers[i] = function(t, spd)
    				local k = ((t * spd * 0.35 + i / n) % 1)
    				local a = i / n * TAU
    				local x = math.cos(a) * R * 0.9
    				local z = math.sin(a) * R * 0.9
    				local y = 3.2 - k * 6 + math.sin(k * math.pi) * 0.6
    				s.CFrame = CFrame.new(x + math.sin(k * 9 + i) * 0.2, y, z + math.cos(k * 7 + i) * 0.2)
    				s2.CFrame = s.CFrame * CFrame.new(0, -0.2, 0)
    			end
    		end
    	elseif shape == "Ground Fog" then

    		local fogs = {}
    		for i = 1, math.max(3, math.min(n, 6)) do
    			local f = node("PF_Fog" .. i)
    			emitter(f, { Enabled = true, Rate = 7, Texture = TEX.Puff, Color = cseq(pal.bright, pal.base, pal.bright), Size = nseq(1.6, 2.6), Transparency = nseq(0.6, 0.8, 1), Lifetime = range(1.6, 2.4), Speed = range(0.3), SpreadAngle = Vector2.new(180, 180), Drag = 2, RotSpeed = range(-20, 20), LightEmission = 0.15 })
    			fogs[i] = f
    			movers[i] = function(t, spd)
    				local a = i / n * TAU + t * spd * 0.22
    				f.CFrame = CFrame.new(math.cos(a) * R * 0.6, -2.5 + math.sin(t * 0.8 + i) * 0.15, math.sin(a) * R * 0.6)
    			end
    		end
    	else

    		for i = 1, n do
    			local p = node("PF_Sakura" .. i)
    			emitter(p, { Enabled = true, Rate = 2.4, Texture = TEX.Heart, Color = cseq(WHITE, pal.bright, pal.base), Size = nseq(0.24, 0.2), Transparency = nseq(0.15, 0.35, 1), Lifetime = range(1.6, 2.2), Speed = range(0), Orientation = Enum.ParticleOrientation.VelocityPerpendicular, LockedToPart = true, Rotation = range(-180, 180), RotSpeed = range(-160, 160) })
    			movers[i] = function(t, spd)
    				local k = ((t * spd * 0.14 + i / n) % 1)
    				local a = i / n * TAU + k * 5
    				p.CFrame = CFrame.new(math.cos(a) * R * (0.5 + 0.5 * math.sin(k * math.pi)), 2.6 - k * 5.4, math.sin(a) * R * (0.5 + 0.5 * math.sin(k * math.pi))) * CFrame.Angles(math.sin(k * 8 + i) * 0.8, k * 4, math.cos(k * 6 + i) * 0.8)
    			end
    		end
    	end

    	Tick.use("Aura", function(dt, t)
    		local spd = S.Aura.Speed

    		for i, fn in ipairs(movers) do
    			fn(t + organicNoise(t * 0.8, i * 2.3) * 0.22 + i * 0.7, spd * (1 + 0.1 * organicNoise(t * 0.55, i * 5.1)))
    		end
    	end)
    	do
    		local de, da = PFPrim.detailFX(root, { rate = 10, size = 0.1, color = pal.seqGlass, life = 1.1, speed = 0.4, accel = Vector3.new(0, 2.2, 0) }, "AuraDetail")
    		Aura:keep(de) Aura:keep(da)
    	end
    	Aura.built = true
    end

    local Foot = defineModule("Foot", {
    	Enabled = false, Color = Color3.fromRGB(120, 200, 255), Interval = 0.28, Size = 0.9, Sparks = true, Style = "Ring Step", Dust = false,
    })
    Foot.Styles = { "Ring Step", "Paw Puff", "Crack", "Blossom", "Frost Print", "Ripple Pad", "Star Stamp", "Ember Trail", "Water Step", "Glyph Stamp", "Smoke Puff" }
    local footTimer, lastFootPos, footSide = 0, nil, 1

    local function stamp(cf, tex, color, size, life, o)
    	o = o or {}
    	local a = worldAttach(cf * CFrame.new(0, 0.08, 0))
    	emitter(a, {
    		Texture = tex, Color = color, Size = nseq(size, size * (o.grow or 1)), Transparency = nseq(o.a0 or 0.1, o.a0 or 0.1, 1),
    		Lifetime = range(life), Speed = range(0.01), EmissionDirection = Enum.NormalId.Top,
    		Orientation = Enum.ParticleOrientation.VelocityPerpendicular, Rotation = range(o.rot or 0, o.rot or 0), RotSpeed = range(o.rotSpeed or 0),
    		LightEmission = o.emission or 1, ZOffset = 0.04,
    	}):Emit(1)
    	Debris:AddItem(a, life + 0.3)
    end

    local function footprint(cf, pal, size, style, yaw)
    	local yawCF = CFrame.Angles(0, math.rad(yaw), 0)
    	if style == "Ring Step" then

    		ringWave(cf, { Color = pal.seqHot, R0 = size * 0.5, R1 = size * 0.85, W0 = size * 0.18, W1 = size * 0.05, Dur = 1.4, A0 = 0.1 })
    		flashSprite(cf * CFrame.new(0, 0.2, 0), { tex = TEX.Glint, color = pal.seqGlass, s0 = 0.06, s1 = size * 0.5, life = 0.35, rotSpeed = 80 })
    	elseif style == "Paw Puff" then

    		stamp(cf, TEX.Circle, cseq(pal.bright, pal.base), size * 0.55, 1.4, { a0 = 0.15 })
    		for i = 1, 4 do
    			local a = (-0.75 + (i - 1) * 0.5)
    			local off = yawCF * CFrame.new(math.sin(a) * size * 0.62, 0.08, -math.cos(a) * size * 0.62 - size * 0.45)
    			stamp(off, TEX.Circle, cseq(pal.bright, pal.base), size * 0.26, 1.2, { a0 = 0.18 })
    		end
    		geyser(cf, 3, pal.seqFade, { speed = 1.2, life = 0.6, spread = 60, size = size * 0.3, gravity = 0.5, drag = 2.5, tex = TEX.Puff, emission = 0, a0 = 0.5 })
    	elseif style == "Crack" then

    		PFPrim.crackFX(cf, { N = 4, Len = size * 0.95, W = 0.055, Dur = 1.1, color = pal.seqHot })
    	elseif style == "Blossom" then

    		PFPrim.polyFX(cf * CFrame.Angles(0, yaw and math.rad(yaw) or 0, 0), { Assembly = true, kind = "flower", r = size * 0.5, W = size * 0.04, color = pal.seqHot, Dur = 1.2, Draw = 0.6, Spin = 0.4 })
    		geyser(cf, 4, pal.seqGlass, { speed = 1, life = 0.9, spread = 70, size = 0.1, gravity = -0.5, drag = 2, tex = TEX.Mote, y = 0.2 })
    	elseif style == "Frost Print" then

    		PFPrim.snowflakeFX(cf, { r = size * 0.6, Dur = 1.3, Spin = 0.35, W = size * 0.04, color = cseq(WHITE, Color3.fromRGB(190, 235, 255)), lift = 0.12 })
    		ringWave(cf, { Color = pal.seqGlass, R0 = size * 0.3, R1 = size * 0.6, W0 = size * 0.22, W1 = size * 0.08, Dur = 1.6, A0 = 0.2, N = 6, Segments = 2 })
    		scatter(cf, 4, pal.seqGlass, { speed = 1.2, life = 0.8, size = 0.1, gravity = -2.5, tex = TEX.Star, y = 0.1 })
    	elseif style == "Ripple Pad" then

    		for i = 1, 2 do
    			ringWave(cf, { Color = pal.seqHot, R0 = size * 0.2, R1 = size * (0.7 + i * 0.3), W0 = size * 0.06, W1 = 0.02, Dur = 1.1, Delay = (i - 1) * 0.15, A0 = 0.2 })
    		end
    		stamp(cf, TEX.Circle, pal.seqGlass, size * 0.7, 0.9, { a0 = 0.5, grow = 1.4 })
    	elseif style == "Star Stamp" then

    		PFPrim.polyFX(cf * CFrame.Angles(0, math.rad((yaw or 0)) + math.random() * 0.6, 0), { Assembly = true, kind = "star", r = size * 0.55, W = size * 0.05, color = pal.seqHot, Dur = 1.3, Draw = 0.5, Spin = 0.8 })
    		stamp(cf, TEX.Field, pal.seqFade, size * 1.5, 1.0, { a0 = 0.7 })
    		flashSprite(cf * CFrame.new(0, 0.3, 0), { tex = TEX.Star, color = pal.seqGlass, s0 = 0.1, s1 = size * 0.6, life = 0.4, rotSpeed = 90 })
    	elseif style == "Ember Trail" then

    		stamp(cf, TEX.Scratch, cseq(WHITE, pal.bright, pal.base, tint(pal.deep, -0.5)), size * 1.2, 1.4, { rot = yaw, a0 = 0.15 })
    		stamp(cf, TEX.Cloud, cseq(pal.deep, BLACK), size * 0.9, 1.1, { a0 = 0.4, emission = 0 })
    		geyser(cf, 5, cseq(WHITE, pal.bright, pal.base), { speed = 2.2, life = 0.6, spread = 30, size = 0.1, gravity = 2, tex = TEX.Ember, streak = true, drag = 1 })
    	elseif style == "Water Step" then

    		ripples(cf, pal, { s0 = size * 0.4, s1 = size * 2.2, life = 0.9, count = 2 })
    		geyser(cf, 7, cseq(WHITE, pal.bright), { speed = 3.6, life = 0.32, spread = 42, size = 0.12, gravity = -36, drag = 0.5, tex = TEX.Drop, streak = true, emission = 0.5 })
    	elseif style == "Glyph Stamp" then

    		stamp(cf, TEX.Swirl, pal.seqHot, size * 1.1, 1.8, { rot = yaw, a0 = 0.05, rotSpeed = 24 })
    		PFPrim.polyFX(cf, { Assembly = true, kind = "hex", r = size * 0.62, W = size * 0.035, color = pal.seqGlass, Dur = 1.3, Draw = 0.45, Spin = -0.7 })
    	elseif style == "Smoke Puff" then

    		local a = worldAttach(cf * CFrame.new(0, 0.2, 0))
    		emitter(a, { Texture = TEX.Puff, Color = cseq(pal.bright, pal.base, pal.deep), Size = nseq(size * 0.5, size * 1.4), Transparency = nseq(0.5, 0.7, 1), Lifetime = range(0.8, 1.3), Speed = range(1, 2), SpreadAngle = Vector2.new(70, 70), Acceleration = Vector3.new(0, 0.8, 0), Drag = 2.5, RotSpeed = range(-40, 40), LightEmission = 0.25, WindAffectsDrag = true }):Emit(q(4, 2))
    		Debris:AddItem(a, 1.7)
    	end
    	if S.Foot.Sparks then
    		geyser(cf, 5, pal.seqHot, { speed = 3, life = 0.6, spread = 40, size = 0.18, gravity = -4, tex = TEX.Glint })
    	end
    	if S.Foot.Dust then
    		local a = worldAttach(cf * CFrame.new(0, 0.15, 0))
    		emitter(a, { Texture = TEX.Puff, Color = pal.seqFade, Size = nseq(size * 0.4, size * 1.1), Transparency = nseq(0.65, 0.8, 1), Lifetime = range(0.6, 0.9), Speed = range(0.8, 1.6), SpreadAngle = Vector2.new(80, 80), Drag = 2, LightEmission = 0.2, WindAffectsDrag = true }):Emit(3)
    		Debris:AddItem(a, 1.3)
    	end
    end

    function Foot.build()
    	Foot:clear()
    	if not S.Foot.Enabled then return end
    	footTimer = 0
    	Tick.use("Foot", function(dt)
    		if not alive() or not Char.humanoid then return end
    		local cfg = S.Foot
    		footTimer = footTimer + dt
    		if footTimer < cfg.Interval then return end
    		local root = Char.root
    		local vel = velocityOf(root)
    		local okF, grounded = pcall(function() return Char.humanoid.FloorMaterial ~= Enum.Material.Air end)
    		if not okF then grounded = true end
    		if vel.Magnitude <= 2 or not grounded then return end
    		if lastFootPos and (root.Position - lastFootPos).Magnitude < 1.2 then return end
    		footTimer = 0
    		lastFootPos = root.Position
    		footSide = -footSide
    		local cf = groundAt(root.Position + root.CFrame.RightVector * footSide * 0.45, Char.model, 3)
    		local hv = Vector3.new(vel.X, 0, vel.Z)
    		local yaw = hv.Magnitude > 0.1 and math.deg(atan2(hv.X, hv.Z)) or 0
    		footprint(cf, paletteFor("Foot", cfg), cfg.Size, cfg.Style, yaw)
    	end)
    	Foot.built = true
    end

    local Pet = defineModule("Pet", {
    	Enabled = false, Style = "Lantern Fish", Color = Color3.fromRGB(120, 255, 200), Size = 0.5,
    	Distance = 3, Height = 3, Speed = 1, Trail = true, Leash = false, React = true, Motion = "Orbit",
    })
    Pet.Styles = { "Lantern Fish", "Drone", "Ghost", "Dragonling", "Cube", "Comet", "Bat", "Hummer", "Blob", "Sentinel", "Nebula Ball", "Origami Bird", "Lightning Core", "Snowflake", "Wisp", "Star Sprite", "Rain Cloud" }
    Pet.Motions = { "Orbit", "Follow", "Hover", "Figure-8" }

    function Pet.build()
    	Pet:clear()
    	if not S.Pet.Enabled or not alive() then return end
    	local cfg = S.Pet
    	local pal = paletteFor("Pet", cfg)
    	local root = Char.root
    	local sz = cfg.Size
    	local style = cfg.Style
    	local core = attach(root, CFrame.new(0, cfg.Height, cfg.Distance), "PF_PetCore")
    	Pet:keep(core)
    	local tailA = attach(root, CFrame.new(0, cfg.Height, cfg.Distance + 0.3), "PF_PetTail")
    	Pet:keep(tailA)
    	local extras = {}
    	local wobble = 1
    	local function body(props) return emitter(core, props) end
    	local function sub(name) local a = attach(root, CFrame.new(), name or "PF_PetSub") Pet:keep(a) return a end

    	if style == "Lantern Fish" then

    		local fish = makeShell(root, { Panels = 8, Color = cseq(pal.bright, pal.base, pal.deep), Transparency = nseq(0.18, 0.4), Segments = 4 })
    		Pet:keep(fish)
    		local tailLoop = makeLoop(root, CFrame.new(), sz * 0.6, { Color = pal.seqFade, Width = sz * 0.5, Alpha = 0.3, Span = 0.45, N = 3, Name = "PF_PetFin" })
    		Pet:keep(tailLoop)
    		local dorsal = makeLoop(root, CFrame.new(), sz * 0.5, { Color = pal.seqHot, Width = sz * 0.3, Alpha = 0.25, Span = 0.3, N = 3, Name = "PF_PetDorsal" })
    		Pet:keep(dorsal)
    		local lure = sub("PF_Lure")
    		emitter(lure, { Enabled = true, Rate = 20, Color = pal.seqHot, Size = nseq(sz * 0.7, sz * 0.5, 0), Lifetime = range(0.2, 0.3), Speed = range(0), Transparency = nseq(0, 1) })
    		light(lure, pal.bright, 8, 1.8)
    		extras[1] = function(t, ccf)
    			local swim = math.sin(t * 6)
    			fish:set(ccf * CFrame.Angles(0, 0, math.pi / 2 + swim * 0.08), sz * 0.5, sz * 0.9, sz * 2.0, 0.3, 0)
    			tailLoop.center = ccf * CFrame.new(0, 0, sz * 1.9) * CFrame.Angles(0, math.pi / 2, swim * 0.55)
    			tailLoop:set(sz * 0.6, sz * 0.4, nil, -math.pi * 0.2 + swim * 0.3)
    			dorsal.center = ccf * CFrame.new(0, sz * 0.95, 0) * CFrame.Angles(math.pi / 2, swim * 0.2, 0)
    			dorsal:set(sz * 0.5, sz * 0.25, nil, swim * 0.3)
    			lure.CFrame = ccf * CFrame.new(0, sz * 1.2, -sz * 1.4 + math.sin(t * 2) * 0.1 * sz)
    		end
    	elseif style == "Drone" then

    		local hull = makeShell(root, { Panels = 6, Color = cseq(pal.deep, pal.base), Transparency = nseq(0.08, 0.3), Segments = 3 })
    		Pet:keep(hull)
    		local rotors = {}
    		for i = 1, 4 do
    			rotors[i] = makeLoop(root, CFrame.new(), sz * 0.5, { Color = pal.seqGlass, Width = sz * 0.08, Alpha = 0.4, Name = "PF_Rotor", N = 4 })
    			Pet:keep(rotors[i])
    		end
    		local eye = sub("PF_DroneEye")
    		emitter(eye, { Enabled = true, Rate = 16, Color = cseq(WHITE, pal.bright), Size = nseq(sz * 0.4, sz * 0.3, 0), Lifetime = range(0.2, 0.3), Speed = range(0), Transparency = nseq(0, 1) })
    		local scan = sub("PF_DroneScan")
    		emitter(scan, { Enabled = true, Rate = 8, Texture = TEX.Scratch, Color = pal.seqGlass, Size = nseq(0.3, 1.1 * sz), Transparency = nseq(0.5, 0.85, 1), Lifetime = range(0.7), Speed = range(0.01), EmissionDirection = Enum.NormalId.Bottom, Orientation = Enum.ParticleOrientation.VelocityPerpendicular, LightEmission = 1, ZOffset = -0.05 })
    		light(eye, pal.base, 6, 1.4)
    		extras[1] = function(t, ccf)
    			hull:set(ccf * CFrame.new(0, -sz * 0.3, 0), sz * 0.7, sz * 0.45, sz * 0.6, 0.1, t)
    			for i = 1, 4 do
    				local th = (i - 0.5) / 4 * TAU
    				rotors[i].center = ccf * CFrame.new(math.cos(th) * sz * 1.1, sz * 0.35, math.sin(th) * sz * 1.1)
    				rotors[i]:set(sz * 0.5, sz * 0.08 + math.abs(math.sin(t * 40 + i)) * sz * 0.1, 0.5 - math.abs(math.sin(t * 40 + i)) * 0.3, t * 30)
    			end
    			eye.CFrame = ccf * CFrame.new(0, 0, -sz * 0.7)
    			scan.CFrame = ccf * CFrame.new(0, -sz * 0.7, 0)
    		end
    		wobble = 3
    	elseif style == "Ghost" then

    		local sheet = makeShell(root, { Panels = 10, Color = cseq(WHITE, pal.bright, pal.base), Transparency = nseq(0.22, 0.88), Segments = 6 })
    		Pet:keep(sheet)
    		body({ Enabled = true, Rate = 10, Texture = TEX.Smoke, Color = pal.seqGlass, Size = nseq(sz * 0.8, sz * 1.8), Lifetime = range(0.8, 1.4), Speed = range(0.5), SpreadAngle = Vector2.new(180, 180), Transparency = nseq(0.6, 1), LightEmission = 0.5 })
    		for i = 1, 2 do
    			local eye = sub("PF_GhostEye")
    			emitter(eye, { Enabled = true, Rate = 14, Color = cseq(pal.deep, BLACK), Size = nseq(sz * 0.3, sz * 0.3, 0), Lifetime = range(0.25, 0.35), Speed = range(0), Transparency = nseq(0, 1), LightEmission = 0 })
    			extras[#extras + 1] = function(t, ccf) eye.CFrame = ccf * CFrame.new((i == 1 and -1 or 1) * sz * 0.35, sz * 0.4, -sz * 0.9) end
    		end
    		local mouth = sub("PF_GhostMouth")
    		emitter(mouth, { Enabled = true, Rate = 10, Color = cseq(pal.deep, BLACK), Size = nseq(sz * 0.18, sz * 0.22), Lifetime = range(0.25), Speed = range(0), Transparency = nseq(0, 1), LightEmission = 0 })
    		extras[#extras + 1] = function(t, ccf)
    			sheet:set(ccf * CFrame.new(0, -sz * 1.3, 0), sz * 0.25, sz * 1.0 + math.sin(t * 4) * sz * 0.1, sz * 2.2, 0.55, t * 0.5)
    			mouth.CFrame = ccf * CFrame.new(0, sz * 0.05, -sz * 0.92)
    		end
    	elseif style == "Dragonling" then

    		local n = q(8, 5)
    		local segs = {}
    		for i = 1, n do segs[i] = sub("PF_DragonSeg") end
    		for i = 1, n - 1 do
    			beam(segs[i], segs[i + 1], { FaceCamera = true, Segments = 2, Width0 = sz * (1.2 - i / n * 0.9), Width1 = sz * (1.2 - (i + 1) / n * 0.9), Color = (i % 2 == 0) and pal.seq or pal.seqUp, Transparency = nseq(0.05) })
    		end
    		for side = -1, 1, 2 do
    			local w = makePlume(root, { side = side, origin = Vector3.zero, spread = RAD(30), sweep = RAD(25), len = sz * 2.2, w0 = sz * 0.9, w1 = sz * 0.1, bend = RAD(15), curve = 0.3, alpha = 0.2 })
    			w.beam.Color = cseq(pal.bright, pal.base, pal.deep)
    			Pet:keep(w)
    			extras[#extras + 1] = function(t, ccf)
    				w.spec.origin = (ccf * CFrame.new(0, sz * 0.2, 0)).Position
    				w:pose(math.sin(t * 8) * 0.45, 0, 0)
    			end
    		end
    		emitter(segs[1], { Enabled = true, Rate = 12, Texture = TEX.Fire, Color = cseq(WHITE, pal.bright, pal.base), Size = nseq(sz * 0.5, 0), Lifetime = range(0.3, 0.5), Speed = range(2, 3), SpreadAngle = Vector2.new(10, 10), EmissionDirection = Enum.NormalId.Front, Transparency = nseq(0, 1) })
    		light(segs[1], pal.base, 7, 1.2)
    		local history = {}
    		extras[#extras + 1] = function(t, ccf)
    			table.insert(history, 1, ccf.Position)
    			if #history > n * 4 then table.remove(history) end
    			for i = 1, n do
    				local idx = math.min(#history, 1 + (i - 1) * 4)
    				segs[i].CFrame = CFrame.lookAt(history[idx], history[math.max(1, idx - 2)] + Vector3.new(0, 0.001, 0))
    			end
    		end
    	elseif style == "Cube" then

    		for i = 1, 3 do
    			local a0 = sub("PF_Cube0" .. i)
    			local a1 = sub("PF_Cube1" .. i)
    			beam(a0, a1, { FaceCamera = false, Segments = 1, Width0 = sz * 0.1, Width1 = sz * 0.1, Color = (i == 1 and pal.seqHot) or (i == 2 and pal.seq) or pal.seqUp, Transparency = nseq(0.05), LightEmission = 1 })
    			extras[i] = function(t, ccf)
    				local rot = ccf * CFrame.Angles(t * (0.7 + i * 0.35), t * (1.1 - i * 0.2), i * 2.1)
    				a0.CFrame = rot * CFrame.new(-sz, -sz, -sz)
    				a1.CFrame = rot * CFrame.new(sz, sz, sz)
    			end
    		end
    		local inner = sub("PF_CubeCore")
    		emitter(inner, { Enabled = true, Rate = 16, Texture = TEX.Glint, Color = cseq(WHITE, pal.bright), Size = nseq(sz * 0.9, sz * 0.6, 0), Lifetime = range(0.15, 0.3), Speed = range(0), Transparency = nseq(0.1, 1), Rotation = range(-180, 180), RotSpeed = range(160) })
    		extras[#extras + 1] = function(t, ccf)
    			local glitch = (math.sin(t * 7) > 0.86) and 1 or 0
    			inner.CFrame = ccf * CFrame.new(rnd(-1, 1) * sz * 0.12 * glitch, rnd(-1, 1) * sz * 0.12 * glitch, 0)
    		end
    	do
    		local alist, aupd = PFPrim.assembleFX(core, { kind = "box", r = sz * 1.15, n = 8, dur = 1.2, color = pal.seqHot, size = 0.11 * math.max(sz, 0.6), spread = sz * 3 + 1.5, spin = 0.9 })
    		for _, it in ipairs(alist) do Pet:keep(it.a) Pet:keep(it.e) end
    		extras[#extras + 1] = function(t, ccf) aupd(t) end
    	end
    	elseif style == "Comet" then

    		body({ Enabled = true, Rate = 24, Texture = TEX.Glint, Color = cseq(WHITE, pal.bright), Size = nseq(sz * 0.9, sz * 0.6, 0), Lifetime = range(0.2, 0.35), Speed = range(0), Transparency = nseq(0, 1), LightEmission = 1 })
    		emitter(core, { Enabled = true, Rate = q(30, 12), Texture = TEX.Fire, Color = cseq(WHITE, pal.bright, pal.base, tint(pal.deep, -0.4)), Size = nseq(sz * 0.7, sz * 0.2, 0), Lifetime = range(0.5, 0.9), Speed = range(4, 7), SpreadAngle = Vector2.new(14, 14), EmissionDirection = Enum.NormalId.Back, Acceleration = Vector3.new(0, 1.5, 0), Transparency = nseq(0, 0.5, 1), LightEmission = 1, Drag = 1 })
    		emitter(core, { Enabled = true, Rate = q(14, 6), Texture = TEX.Ember, Color = cseq(WHITE, pal.bright), Size = nseq(sz * 0.16, 0), Lifetime = range(0.6, 1.1), Speed = range(3, 6), SpreadAngle = Vector2.new(35, 35), EmissionDirection = Enum.NormalId.Back, Transparency = nseq(0, 1), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-2, -0.4), Rotation = range(0), RotSpeed = range(0) })
    		light(core, pal.bright, 9, 1.8)
    		wobble = 2
    	elseif style == "Bat" then

    		body({ Enabled = true, Rate = 18, Color = cseq(pal.deep, pal.base), Size = nseq(sz * 0.8, sz * 0.5, 0), Lifetime = range(0.25, 0.4), Speed = range(0), Transparency = nseq(0.05, 0.5, 1) })
    		local ears = {}
    		for i = 1, 2 do
    			ears[i] = sub("PF_BatEar" .. i)
    		end
    		for side = -1, 1, 2 do
    			local w = makePlume(root, { side = side, origin = Vector3.zero, spread = RAD(46), sweep = RAD(10), len = sz * 2.6, w0 = sz * 1.1, w1 = sz * 0.1, bend = RAD(-12), curve = 0.5, alpha = 0.28 })
    			w.beam.Color = cseq(pal.deep, pal.base, pal.deep)
    			Pet:keep(w)
    			extras[#extras + 1] = function(t, ccf)
    				w.spec.origin = ccf.Position
    				w:pose(math.sin(t * 11 + (side > 0 and 0 or math.pi)) * 0.55, 0, 0)
    			end
    		end
    		local eyes = sub("PF_BatEyes")
    		emitter(eyes, { Enabled = true, Rate = 16, Color = pal.seqHot, Size = nseq(sz * 0.16, sz * 0.12, 0), Lifetime = range(0.2, 0.3), Speed = range(0), SpreadAngle = Vector2.new(10, 4), Transparency = nseq(0, 1), LightEmission = 1 })
    		extras[#extras + 1] = function(t, ccf)
    			ears[1].CFrame = ccf * CFrame.new(-sz * 0.3, sz * 0.7, -sz * 0.2) * CFrame.Angles(0, 0, 0.35)
    			ears[2].CFrame = ccf * CFrame.new(sz * 0.3, sz * 0.7, -sz * 0.2) * CFrame.Angles(0, 0, -0.35)
    			eyes.CFrame = ccf * CFrame.new(0, sz * 0.15, -sz * 0.8)
    		end
    		wobble = 3.5
    	elseif style == "Hummer" then

    		body({ Enabled = true, Rate = 16, Color = cseq(pal.bright, pal.base, pal.bright), Size = nseq(sz * 0.7, sz * 0.4, 0), Lifetime = range(0.25, 0.4), Speed = range(0), Transparency = nseq(0.05, 0.5, 1) })
    		local beak = sub("PF_HummerBeak")
    		beam(beak, sub("PF_HummerBeak2"), { FaceCamera = true, Segments = 1, Width0 = sz * 0.12, Width1 = 0.01, Color = cseq(pal.deep, BLACK), Transparency = nseq(0.1) })
    		for side = -1, 1, 2 do
    			local w = makePlume(root, { side = side, origin = Vector3.zero, spread = RAD(70), sweep = RAD(16), len = sz * 1.5, w0 = sz * 0.8, w1 = sz * 0.05, bend = RAD(8), curve = 0.6, alpha = 0.35 })
    			w.beam.Color = cseq(WHITE, pal.bright, pal.base)
    			Pet:keep(w)
    			extras[#extras + 1] = function(t, ccf)
    				w.spec.origin = ccf.Position
    				w:pose(math.sin(t * 22) * 0.6, 0, side * 0.1)
    			end
    		end
    		extras[#extras + 1] = function(t, ccf)
    			beak.CFrame = ccf * CFrame.new(0, sz * 0.1, -sz * 1.1) * CFrame.Angles(math.sin(t * 20) * 0.04, 0, 0)
    		end
    		wobble = 5
    	elseif style == "Blob" then

    		local jelly = makeShell(root, { Panels = 10, Color = cseq(pal.bright, pal.base, pal.bright), Transparency = nseq(0.15, 0.55), Segments = 5 })
    		Pet:keep(jelly)
    		body({ Enabled = true, Rate = 8, Texture = TEX.Circle, Color = pal.seqGlass, Size = nseq(sz * 0.3, sz * 0.5, 0), Lifetime = range(0.4, 0.7), Speed = range(0), Transparency = nseq(0.25, 0.7, 1), LightEmission = 0.6 })
    		local drip = sub("PF_BlobDrip")
    		emitter(drip, { Enabled = true, Rate = q(6, 2), Texture = TEX.Drop, Color = cseq(pal.bright, pal.base), Size = nseq(sz * 0.2, sz * 0.14), Lifetime = range(0.5, 0.8), Speed = range(0.4), SpreadAngle = Vector2.new(20, 20), Acceleration = Vector3.new(0, -14, 0), Transparency = nseq(0.15, 0.6, 1), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-1.4), Rotation = range(0), RotSpeed = range(0) })
    		local shine = sub("PF_BlobShine")
    		emitter(shine, { Enabled = true, Rate = 8, Texture = TEX.Glint, Color = WHITE, Size = nseq(sz * 0.24, sz * 0.18, 0), Lifetime = range(0.3), Speed = range(0), Transparency = nseq(0.1, 0.7, 1), Rotation = range(-30, 30) })
    		extras[1] = function(t, ccf)
    			local breathe = 1 + 0.18 * math.sin(t * 3.4)
    			jelly:set(ccf * CFrame.new(0, -sz * 0.4 / breathe, 0), sz * 1.15 / breathe, sz * 1.25 * breathe, sz * 1.3 * breathe, 0.75, t * 0.4)
    			drip.CFrame = ccf * CFrame.new(0, -sz * 1.1, 0)
    			shine.CFrame = ccf * CFrame.new(-sz * 0.4, sz * 0.5, -sz * 0.9)
    		end
    		wobble = 1.6
    	elseif style == "Sentinel" then

    		for i = 1, 3 do
    			local l = makeLoop(root, CFrame.new(), sz * (1.3 + i * 0.22), { Color = (i % 2 == 0) and pal.seq or pal.seqDark, Width = sz * 0.12, Alpha = 0.12, Span = 0.6, N = 3, Name = "PF_SentRing" })
    			Pet:keep(l)
    			extras[#extras + 1] = function(t, ccf)
    				l.center = ccf * CFrame.Angles(math.pi / 2 + math.sin(t * 0.8 + i) * 0.22, 0, 0)
    				l:set(sz * (1.3 + i * 0.22), sz * 0.12, nil, t * (i % 2 == 0 and 0.8 or -1.1))
    			end
    		end
    		local eye = sub("PF_SentEye")
    		emitter(eye, { Enabled = true, Rate = 22, Texture = TEX.Circle, Color = cseq(WHITE, pal.bright, pal.base), Size = nseq(sz * 0.95, sz * 0.85), Lifetime = range(0.3), Speed = range(0), Transparency = nseq(0.05, 0.3, 1), LockedToPart = true, ZOffset = 0.05 })
    		local pupil = sub("PF_SentPupil")
    		emitter(pupil, { Enabled = true, Rate = 20, Color = cseq(pal.deep, BLACK), Size = nseq(sz * 0.4, sz * 0.36), Lifetime = range(0.3), Speed = range(0), Transparency = nseq(0, 0.2, 1), LockedToPart = true, ZOffset = 0.07, LightEmission = 0 })
    		light(eye, pal.bright, 8, 1.5)
    		extras[#extras + 1] = function(t, ccf)
    			local look = Vector3.new(math.sin(t * 0.9) * 0.18, math.sin(t * 0.7) * 0.12, -1)
    			eye.CFrame = ccf * CFrame.lookAt(Vector3.zero, look)
    			pupil.CFrame = eye.CFrame * CFrame.new(look * 0.1)
    		end
    	elseif style == "Nebula Ball" then

    		local veil = makeShell(root, { Panels = 12, Color = cseq(pal.deep, pal.base, pal.deep), Transparency = nseq(0.5, 0.85), Segments = 6 })
    		Pet:keep(veil)
    		body({ Enabled = true, Rate = 22, Texture = TEX.Vortex, Color = cseq(pal.bright, pal.base, pal.deep), Size = nseq(sz * 1.6, sz * 1.8, sz * 1.2), Transparency = nseq(0.15, 0.45, 1), Lifetime = range(0.5, 0.8), Speed = range(0), Transparency = nseq(0.1, 0.4, 1), Rotation = range(0), RotSpeed = range(70), LightEmission = 1, LockedToPart = true, ZOffset = 0.02 })
    		emitter(core, { Enabled = true, Rate = q(12, 5), Texture = TEX.Star, Color = cseq(WHITE, pal.bright), Size = nseq(sz * 0.2, 0.1, 0), Lifetime = range(0.8, 1.5), Speed = range(1, 2.4), SpreadAngle = Vector2.new(180, 180), Drag = 1.2, Transparency = nseq(0, 1), Rotation = range(-180, 180), RotSpeed = range(-120, 120) })
    		extras[1] = function(t, ccf)
    			veil:set(ccf * CFrame.new(0, 0, 0), sz * 0.5, sz * 1.4, sz * 1.6, 0.5, t * 0.6)
    		end
    	elseif style == "Origami Bird" then

    		local wings = {}
    		for side = -1, 1, 2 do
    			local a0 = sub("PF_OriW0" .. side)
    			local a1 = sub("PF_OriW1" .. side)
    			local b = beam(a0, a1, { FaceCamera = false, Segments = 1, Width0 = sz * 1.5, Width1 = sz * 0.5, Color = cseq(WHITE, pal.bright), Transparency = nseq(0.08, 0.3), LightEmission = 0.4 })
    			wings[side] = { a0 = a0, a1 = a1, b = b }
    		end
    		local keel = sub("PF_OriKeel0")
    		local keel2 = sub("PF_OriKeel1")
    		beam(keel, keel2, { FaceCamera = true, Segments = 1, Width0 = sz * 0.16, Width1 = sz * 0.02, Color = cseq(pal.deep, pal.base), Transparency = nseq(0.1) })
    		extras[1] = function(t, ccf)
    			local flap = math.sin(t * 5) * 0.5
    			for side = -1, 1, 2 do
    				local w = wings[side]
    				w.a0.CFrame = ccf * CFrame.new(0, 0, -sz * 0.4) * CFrame.Angles(0, 0, 0)
    				w.a1.CFrame = ccf * CFrame.new(side * sz * 0.15, flap * sz * 0.8 - sz * 0.1, sz * 1.5) * CFrame.Angles(side * flap * 0.4, 0, side * (0.9 + flap * 0.3))
    				w.b.CurveSize0 = side * sz * 0.4
    			end
    			keel.CFrame = ccf * CFrame.new(0, -sz * 0.2, -sz * 0.9)
    			keel2.CFrame = ccf * CFrame.new(0, -sz * 1.1, sz * 0.6)
    		end
    	elseif style == "Lightning Core" then

    		body({ Enabled = true, Rate = 26, Texture = TEX.Field, Color = cseq(WHITE, pal.bright, pal.base), Size = nseq(sz * 1.4, sz * 0.9, 0), Lifetime = range(0.15, 0.3), Speed = range(0), Transparency = nseq(0.1, 0.5, 1), LightEmission = 1 })
    		local arcs = {}
    		for i = 1, 4 do
    			arcs[i] = makeBolt(root, { K = 4, Width = sz * 0.08, Color = cseq(WHITE, pal.bright) })
    			Pet:keep(arcs[i])
    		end
    		light(core, pal.bright, 10, 2)
    		extras[1] = function(t, ccf)
    			for i, b in ipairs(arcs) do
    				local th = t * 3 + i * 1.7
    				local p1 = ccf * CFrame.Angles(math.sin(th) * 1.4, th, math.cos(th * 0.7)) * CFrame.new(0, 0, -sz * (1.6 + math.abs(math.sin(t * 9 + i)) * 1.4))
    				b:set(ccf.Position, p1.Position, 0.5, t * 20 + i)
    				b:alpha((math.sin(t * 15 + i * 2.4) > 0.2) and 0.15 or 0.9)
    			end
    		end
    		wobble = 4
    	elseif style == "Snowflake" then

    		for arm = 0, 2 do
    			local a0 = sub("PF_Flake0" .. arm)
    			local a1 = sub("PF_Flake1" .. arm)
    			beam(a0, a1, { FaceCamera = false, Segments = 1, Width0 = sz * 0.1, Width1 = sz * 0.1, Color = cseq(WHITE, pal.bright, WHITE), Transparency = nseq(0.08), LightEmission = 0.9 })
    			local barbs = {}
    			for k = 1, 2 do
    				local b0 = sub("PF_FlakeB" .. arm .. k)
    				barbs[k] = b0
    			end
    			beam(barbs[1], barbs[2], { FaceCamera = false, Segments = 1, Width0 = sz * 0.06, Width1 = sz * 0.06, Color = cseq(WHITE, pal.bright), Transparency = nseq(0.2), LightEmission = 0.9 })
    			extras[#extras + 1] = function(t, ccf)
    				local rot = ccf * CFrame.Angles(0, t * 0.9, arm * math.pi / 3) * CFrame.Angles(0, 0, 0)
    				a0.CFrame = rot * CFrame.new(-sz * 1.25, 0, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
    				a1.CFrame = rot * CFrame.new(sz * 1.25, 0, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
    				barbs[1].CFrame = rot * CFrame.new(sz * 0.7, sz * 0.42, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
    				barbs[2].CFrame = rot * CFrame.new(sz * 1.15, -sz * 0.34, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
    			end
    		end
    		local ring = makeLoop(root, CFrame.new(), sz * 0.9, { Color = pal.seqGlass, Width = sz * 0.05, Alpha = 0.2, Name = "PF_FlakeRing", N = 6, Segments = 2 })
    		Pet:keep(ring)
    		extras[#extras + 1] = function(t, ccf)
    			ring.center = ccf * CFrame.Angles(math.pi / 2, 0, 0) * CFrame.Angles(0, t * 0.9, 0)
    			ring:set(sz * 0.9, sz * 0.05, nil, -t * 0.9)
    		end
    		body({ Enabled = true, Rate = 8, Color = cseq(WHITE, pal.bright), Size = nseq(sz * 0.12, 0), Lifetime = range(0.8, 1.4), Speed = range(0.4), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -1, 0), Transparency = nseq(0, 1) })
    		light(core, pal.bright, 6, 1.2)
    	elseif style == "Wisp" then

    		body({ Enabled = true, Rate = 24, Texture = TEX.Fire, Color = cseq(WHITE, pal.bright, pal.base), Size = nseq(sz * 0.9, sz * 0.3, 0), Lifetime = range(0.3, 0.55), Speed = range(1.2, 2), SpreadAngle = Vector2.new(12, 12), EmissionDirection = Enum.NormalId.Top, Transparency = nseq(0, 0.4, 1), LightEmission = 1, Drag = 0.5 })
    		emitter(core, { Enabled = true, Rate = q(10, 4), Texture = TEX.Ember, Color = cseq(pal.bright, pal.base), Size = nseq(sz * 0.14, 0), Lifetime = range(0.5, 1), Speed = range(0.8), SpreadAngle = Vector2.new(180, 180), Transparency = nseq(0, 1), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-1.6, -0.3) })
    		local flare = sub("PF_WispFlare")
    		local flareE = emitter(flare, { Enabled = false, Rate = 0, Texture = TEX.Glint, Color = WHITE, Size = nseq(sz * 0.6, sz * 2.4, sz), Lifetime = range(0.2), Speed = range(0), Transparency = nseq(0.15, 0, 1), LockedToPart = true, ZOffset = 0.3 })
    		local nextFlare = 1
    		light(core, pal.bright, 8, 1.6)
    		extras[1] = function(t, ccf)
    			flare.CFrame = ccf
    			if t > nextFlare then
    				nextFlare = t + rnd(2, 5)
    				flareE:Emit(1)
    			end
    		end
    		wobble = 2.5
    	elseif style == "Star Sprite" then

    		body({ Enabled = true, Rate = 12, Texture = TEX.Star, Color = cseq(WHITE, pal.bright, pal.base), Size = nseq(sz * 1.3, sz * 1.1), Transparency = nseq(0, 0.15, 1), Lifetime = range(0.4), Speed = range(0), Rotation = range(0, 72), RotSpeed = range(40), LockedToPart = true, ZOffset = 0.05, LightEmission = 1 })
    		emitter(core, { Enabled = true, Rate = q(10, 4), Texture = TEX.Glint, Color = pal.seqGlass, Size = nseq(sz * 0.2, sz * 0.1, 0), Lifetime = range(0.5, 0.9), Speed = range(0.6), SpreadAngle = Vector2.new(180, 180), Transparency = nseq(0, 1), Rotation = range(-180, 180), RotSpeed = range(120) })
    		for i = 1, 2 do
    			local s = sub("PF_StarSat" .. i)
    			emitter(s, { Enabled = true, Rate = 8, Texture = TEX.Star, Color = pal.seqHot, Size = nseq(sz * 0.4, sz * 0.34), Lifetime = range(0.3), Speed = range(0), Transparency = nseq(0, 0.2, 1), Rotation = range(0, 72), RotSpeed = range(60), LockedToPart = true })
    			local tilt = (i == 1) and RAD(30) or RAD(-45)
    			table.insert(extras, function(t, ccf)
    				s.CFrame = ccf * CFrame.Angles(tilt, t * (i == 1 and 2.2 or -1.7), 0) * CFrame.new(sz * 1.9, 0, 0)
    			end)
    		end
    		light(core, pal.bright, 7, 1.4)
    	else

    		local puff1 = makeShell(root, { Panels = 8, Color = cseq(WHITE, pal.bright, WHITE), Transparency = nseq(0.2, 0.5), Segments = 4 })
    		local puff2 = makeShell(root, { Panels = 8, Color = cseq(pal.bright, pal.base), Transparency = nseq(0.35, 0.6), Segments = 4 })
    		Pet:keep(puff1) Pet:keep(puff2)
    		local rain = sub("PF_PetRain")
    		emitter(rain, { Enabled = true, Rate = 22, Texture = TEX.Drop, Color = cseq(pal.bright, pal.base), Size = nseq(sz * 0.3, sz * 0.25), Lifetime = range(0.6, 0.9), Speed = range(5, 8), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(20, 20), Acceleration = Vector3.new(0, -25, 0), Transparency = nseq(0.2, 0.4, 1), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-1.5), Rotation = range(0), RotSpeed = range(0), LightEmission = 0.4, Shape = Enum.ParticleEmitterShape.Disc, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume, ShapePartial = 1 })
    		local l = light(core, pal.bright, 6, 0)
    		local flashE = body({ Enabled = false, Rate = 0, Texture = TEX.Glint, Color = pal.seqGlass, Size = nseq(sz * 0.5, sz * 4, sz), Lifetime = range(0.15), Speed = range(0), Transparency = nseq(0.2, 0, 1), Rotation = range(-180, 180), LockedToPart = true, ZOffset = 0.4 })
    		local nextFlash = 2
    		extras[1] = function(t, ccf)
    			puff1:set(ccf * CFrame.new(0, sz * 0.5, 0), sz * 0.7, sz * 1.5, sz * 1.7, 0.55, t * 0.5)
    			puff2:set(ccf * CFrame.new(0, sz * 0.1, 0), sz * 0.9, sz * 1.2, sz * 1.5, 0.5, -t * 0.4)
    			rain.CFrame = ccf * CFrame.new(0, -sz * 0.8, 0)
    			if t > nextFlash then
    				nextFlash = t + rnd(1.5, 5)
    				flashE:Emit(2)
    				l.Brightness = 3
    			end
    			l.Brightness = math.max(0, l.Brightness - 0.15)
    		end
    		wobble = 0.8
    	end

    	if cfg.Trail then
    		trail(core, tailA, { Color = pal.seqHot, Lifetime = 0.6, WidthScale = nseq(1, 0), Transparency = nseq(0.2, 1), FaceCamera = true })
    		trail(core, tailA, { Color = pal.seqFade, Lifetime = 0.9, WidthScale = nseq(2.2, 0), Transparency = nseq(0.75, 1), FaceCamera = true, Texture = TEX.Smoke, TextureMode = Enum.TextureMode.Wrap, TextureLength = 1.2 })
    	end
    	if cfg.Leash then
    		local la = attach(Char.torso, CFrame.new(), "PF_Leash")
    		Pet:keep(la)
    		local lb = beam(la, core, { FaceCamera = true, Segments = 10, Width0 = 0.1, Width1 = 0.05, Color = pal.seqFade, Transparency = nseq(0.5, 0.8), Texture = TEX.Spark, TextureMode = Enum.TextureMode.Wrap, TextureLength = 1, TextureSpeed = 2 })
    		lb.CurveSize0 = -1.5
    		lb.CurveSize1 = 0
    	end

    	local angle = math.random() * TAU
    	local smooth = Vector3.new(0, cfg.Height, cfg.Distance)
    	local lastLocal = smooth
    	Tick.use("Pet", function(dt, t)
    		local c = S.Pet
    		local target
    		local motion = c.Motion
    		if motion == "Orbit" then
    			angle = angle + dt * c.Speed
    			target = Vector3.new(math.sin(angle) * c.Distance, c.Height + math.sin(t * 2.2 * wobble) * 0.35, math.cos(angle) * c.Distance)
    		elseif motion == "Follow" then
    			target = Vector3.new(1.6, c.Height - 0.5 + math.sin(t * 2 * wobble) * 0.3, c.Distance * 0.6)
    		elseif motion == "Figure-8" then
    			angle = angle + dt * c.Speed
    			target = Vector3.new(math.sin(angle) * c.Distance, c.Height + math.sin(angle * 2) * 0.6, math.sin(angle * 2) * c.Distance * 0.5 + 1)
    		else
    			target = Vector3.new(math.sin(t * 0.7 * c.Speed) * c.Distance * 0.5, c.Height + math.sin(t * 1.6) * 0.5, c.Distance * 0.8)
    		end
    		smooth = smooth:Lerp(target, math.min(dt * 4, 1))

    		local d = smooth - lastLocal
    		lastLocal = smooth
    		local ccf
    		if d.Magnitude > 0.002 then
    			ccf = CFrame.new(smooth, smooth + Vector3.new(d.X, 0, d.Z) * 10 + Vector3.new(0, 0.001, 0))
    		else
    			ccf = CFrame.new(smooth)
    		end
    		core.CFrame = ccf * CFrame.new((math.sin(t * 9 * wobble) + 0.4 * organicNoise(t * 1.3, 1.1)) * 0.05 * sz, 0.06 * organicNoise(t * 0.8, 5.5) * sz, 0)
    		tailA.CFrame = ccf * CFrame.new(0, 0, 0.3 * sz)
    		for _, fn in ipairs(extras) do fn(t + 0.15 * organicNoise(t * 0.9, 3.9), ccf) end
    	end)
    	do
    		local de, da = PFPrim.detailFX(core, { rate = 8, size = 0.07, color = pal.seqGlass, life = 0.7, speed = 0.3, accel = Vector3.new(0, 0.6, 0) }, "PetDetail")
    		Pet:keep(de) Pet:keep(da)
    	end
    	Pet.built = true
    end

    local function petReact(kind)
    	if not Pet.built or not S.Pet.Enabled or not S.Pet.React or not alive() then return end
    	local core
    	for _, it in ipairs(Pet.items) do
    		if typeof(it) == "Instance" and it.Name == "PF_PetCore" then core = it break end
    	end
    	if not core then return end
    	local pal = paletteFor("Pet", S.Pet)
    	local cf = CFrame.new(core.WorldPosition)
    	local sz = S.Pet.Size
    	if kind == "kill" then
    		ringWave(cf, { Color = pal.seqHot, R0 = sz, R1 = sz * 5, W0 = 0.25, W1 = 0.03, Dur = 0.6, Tilt = RAD(90) })
    		scatter(cf, 16, pal.seqHot, { speed = 6, life = 0.6, size = 0.2, gravity = -2, drag = 3, y = 0, streak = true })
    		flashSprite(cf, { tex = TEX.Star, color = pal.seqGlass, s0 = 0.3, s1 = sz * 5, life = 0.3, y = 0 })
    		glint(cf, pal.bright, 10, 6, 0.3)
    	else
    		ringWave(cf, { Color = pal.seqHot, R0 = sz * 0.5, R1 = sz * 3, W0 = 0.15, W1 = 0.02, Dur = 0.4, Tilt = RAD(90) })
    		scatter(cf, 8, pal.seqHot, { speed = 3, life = 0.5, size = 0.15, gravity = 0, drag = 3, y = 0, tex = TEX.Glint })
    	end
    end
    Bus.on("jump", function() petReact("jump") end)
    Bus.on("kill", function() petReact("kill") end)

    local Trails = defineModule("Trails", {
    	Enabled = false, Style = "Silk", Color = Color3.fromRGB(120, 200, 255), Color2 = Color3.fromRGB(255, 110, 200),
    	Width = 1.5, Lifetime = 0.5, Rainbow = false, Echo = false, Limbs = false, SpeedReactive = false, Sparks = false,
    })
    Trails.selfRainbow = true
    Trails.Styles = {
    	"Silk", "Blaze", "Frostbite", "Galaxy", "Bubblegum", "Umbra", "Split Neon", "Petals",
    	"Datastream", "Polar Light", "Comet Tail", "Static", "Phantom", "Spectrum", "Twin Helix", "Vapor",
    	"Stardust", "Ember Wake", "Stamp Path", "Aqua",
    }
    Trails.StyleColors = {
    	["Silk"]        = { Color3.fromRGB(120, 200, 255), Color3.fromRGB(255, 255, 255) },
    	["Blaze"]       = { Color3.fromRGB(255, 170, 40),  Color3.fromRGB(255, 50, 20) },
    	["Frostbite"]   = { Color3.fromRGB(200, 240, 255), Color3.fromRGB(80, 160, 255) },
    	["Galaxy"]      = { Color3.fromRGB(150, 80, 255),  Color3.fromRGB(40, 200, 255) },
    	["Bubblegum"]   = { Color3.fromRGB(255, 120, 200), Color3.fromRGB(120, 255, 220) },
    	["Umbra"]       = { Color3.fromRGB(60, 20, 90),    Color3.fromRGB(0, 0, 0) },
    	["Split Neon"]  = { Color3.fromRGB(0, 255, 200),   Color3.fromRGB(255, 0, 150) },
    	["Petals"]      = { Color3.fromRGB(255, 160, 200), Color3.fromRGB(255, 230, 240) },
    	["Datastream"]  = { Color3.fromRGB(0, 255, 120),   Color3.fromRGB(0, 80, 40) },
    	["Polar Light"] = { Color3.fromRGB(80, 255, 180),  Color3.fromRGB(120, 80, 255) },
    	["Comet Tail"]  = { Color3.fromRGB(255, 240, 200), Color3.fromRGB(255, 140, 60) },
    	["Static"]      = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(120, 200, 255) },
    	["Phantom"]     = { Color3.fromRGB(200, 220, 255), Color3.fromRGB(80, 100, 160) },
    	["Spectrum"]    = { Color3.fromRGB(255, 0, 0),     Color3.fromRGB(0, 0, 255) },
    	["Twin Helix"]  = { Color3.fromRGB(255, 230, 80),  Color3.fromRGB(80, 200, 255) },
    	["Vapor"]       = { Color3.fromRGB(255, 120, 220), Color3.fromRGB(120, 240, 255) },
    	["Stardust"]    = { Color3.fromRGB(255, 240, 200), Color3.fromRGB(180, 140, 255) },
    	["Ember Wake"]  = { Color3.fromRGB(255, 200, 90),  Color3.fromRGB(200, 40, 10) },
    	["Stamp Path"]  = { Color3.fromRGB(120, 255, 220), Color3.fromRGB(40, 120, 255) },
    	["Aqua"]        = { Color3.fromRGB(200, 245, 255), Color3.fromRGB(40, 160, 255) },
    }
    local RAINBOW = cseq(Color3.fromHSV(0, 0.85, 1), Color3.fromHSV(0.17, 0.85, 1), Color3.fromHSV(0.33, 0.85, 1), Color3.fromHSV(0.5, 0.85, 1), Color3.fromHSV(0.67, 0.85, 1), Color3.fromHSV(0.83, 0.85, 1), Color3.fromHSV(1, 0.85, 1))

    local function trailSeq(style, c1, c2, hue)
    	if hue then
    		c1 = Color3.fromHSV(hue % 1, 0.85, 1)
    		c2 = Color3.fromHSV((hue + 0.12) % 1, 0.85, 1)
    	end
    	if style == "Blaze" or style == "Comet Tail" or style == "Ember Wake" then return cseq(WHITE, c1, c2, tint(c2, -0.6)) end
    	if style == "Umbra" or style == "Phantom" then return cseq(c1, c2, BLACK) end
    	if style == "Split Neon" or style == "Twin Helix" then return cseq(c1, c1, c2, c2) end
    	if style == "Static" then return cseq(c1, c2, c1, c2, c1) end
    	if style == "Spectrum" then return RAINBOW end
    	return cseq(WHITE, c1, c2)
    end

    function Trails.build()
    	Trails:clear()
    	if not S.Trails.Enabled or not alive() then return end
    	local cfg = S.Trails
    	local root = Char.root
    	local style = cfg.Style
    	local w = cfg.Width
    	local life = cfg.Lifetime
    	local hue = (cfg.Rainbow or RainbowHue.Trails) and 0 or nil
    	local seq = trailSeq(style, cfg.Color, cfg.Color2, hue)
    	local made = {}
    	local idx = 0

    	local function mk(parent, off0, off1, props, tag)
    		idx = idx + 1
    		local a0 = attach(parent, off0, (tag or "PF_Trail") .. "0")
    		local a1 = attach(parent, off1, (tag or "PF_Trail") .. "1")
    		Trails:keep(a0) Trails:keep(a1)
    		props = props or {}
    		props.Lifetime = props.Lifetime or life
    		props.Color = props.Color or seq
    		local t = trail(a0, a1, props)
    		table.insert(made, t)
    		return t, a0, a1
    	end

    	local function buildOn(parent, scaleW, tag)
    		local W = w * scaleW
    		local up, down = Vector3.new(0, W * 0.5, 0), Vector3.new(0, -W * 0.5, 0)
    		if style == "Silk" then

    			mk(parent, up, down, { Transparency = nseq(0.05, 1), WidthScale = nseq(1, 0.9, 0.3, 0), LightEmission = 0.4 }, tag)
    			mk(parent, up * 1.02, down * 1.02, { Color = cseq(WHITE, cfg.Color), Transparency = nseq(0.5, 1), WidthScale = nseq(0.12, 0), Lifetime = life * 0.8, LightEmission = 1 }, tag)
    		elseif style == "Blaze" then

    			mk(parent, up, down, { Texture = TEX.Fire, TextureMode = Enum.TextureMode.Wrap, TextureLength = 2, Transparency = nseq(0.05, 0.4, 1), WidthScale = nseq(1, 1.3, 0.4, 0), LightEmission = 1 }, tag)
    			mk(parent, up * 0.4, down * 0.4, { Color = cseq(WHITE, tint(cfg.Color, 0.5)), Transparency = nseq(0.2, 1), WidthScale = nseq(1, 0), Lifetime = life * 0.5 }, tag)
    			local a = Trails:keep(attach(parent, Vector3.new(0, 0, 0.3), tag .. "E"))
    			emitter(a, { Enabled = true, Rate = q(16, 6), Texture = TEX.Ember, Color = cseq(WHITE, cfg.Color), Size = nseq(0.14, 0), Lifetime = range(0.4, 0.9), Speed = range(1, 2.5), SpreadAngle = Vector2.new(40, 40), EmissionDirection = Enum.NormalId.Back, Acceleration = Vector3.new(0, 2, 0), Transparency = nseq(0, 1), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-1.8, -0.3), Rotation = range(0), RotSpeed = range(0), LightEmission = 1 })
    		elseif style == "Frostbite" then

    			mk(parent, up, down, { Transparency = nseq(0.1, 0.4, 1), WidthScale = nseq(1, 0.7, 0), Texture = TEX.Spark, TextureMode = Enum.TextureMode.Wrap, TextureLength = 1.5 }, tag)
    			mk(parent, up * 1.3, up * 1.1, { Color = cseq(WHITE, cfg.Color), Transparency = nseq(0.2, 1), WidthScale = nseq(1, 0), Lifetime = life * 1.4 }, tag)
    			mk(parent, down * 1.3, down * 1.1, { Color = cseq(WHITE, cfg.Color), Transparency = nseq(0.2, 1), WidthScale = nseq(1, 0), Lifetime = life * 1.4 }, tag)
    			local a = Trails:keep(attach(parent, Vector3.zero, tag .. "E"))
    			emitter(a, { Enabled = true, Rate = q(12, 5), Texture = TEX.Star, Color = cseq(WHITE, Color3.fromRGB(190, 235, 255)), Size = nseq(0.12, 0.06, 0), Lifetime = range(0.7, 1.3), Speed = range(0.6, 1.4), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -1.2, 0), Drag = 1.5, Transparency = nseq(0, 1), Rotation = range(-180, 180), RotSpeed = range(-100, 100), LightEmission = 0.9 })
    		elseif style == "Galaxy" then

    			mk(parent, up * 1.1, down * 1.1, { Texture = TEX.Smoke, TextureMode = Enum.TextureMode.Wrap, TextureLength = 3, Transparency = nseq(0.25, 0.6, 1), WidthScale = nseq(1, 1.5, 0.6, 0), Lifetime = life * 1.6, LightEmission = 0.3 }, tag)
    			mk(parent, up * 0.5, down * 0.5, { Color = cseq(WHITE, cfg.Color), Transparency = nseq(0.1, 1), WidthScale = nseq(0.6, 0), Texture = TEX.Spark, TextureMode = Enum.TextureMode.Wrap, TextureLength = 0.6, LightEmission = 1 }, tag)
    			local a = Trails:keep(attach(parent, Vector3.zero, tag .. "E"))
    			emitter(a, { Enabled = true, Rate = q(14, 6), Texture = TEX.Star, Color = cseq(WHITE, cfg.Color2), Size = nseq(0.16, 0.08, 0), Lifetime = range(0.9, 1.8), Speed = range(0.5, 1.5), SpreadAngle = Vector2.new(180, 180), Drag = 1.4, Transparency = nseq(0, 1), Rotation = range(-180, 180), RotSpeed = range(-140, 140), LightEmission = 1 })
    		elseif style == "Bubblegum" then

    			mk(parent, up, down, { Transparency = nseq(0.1, 0.3, 0.1, 1), WidthScale = nseq(1, 0.5, 1, 0.5, 0), Lifetime = life * 1.2 }, tag)
    			local a = Trails:keep(attach(parent, Vector3.new(0, 0, 0.2), tag .. "E"))
    			emitter(a, { Enabled = true, Rate = q(8, 3), Texture = TEX.Circle, Color = cseq(cfg.Color2, cfg.Color), Size = nseq(0.14, 0.42, 0.5), Transparency = nseq(0.55, 0.3, 1), Lifetime = range(1, 1.8), Speed = range(0.4, 1), SpreadAngle = Vector2.new(180, 180), Drag = 1.8, Transparency = nseq(0.55, 0.3, 1), Rotation = range(-180, 180), RotSpeed = range(-40, 40), LightEmission = 0.5 })
    		elseif style == "Umbra" then

    			mk(parent, up * 1.4, down * 1.4, { Texture = TEX.Smoke, TextureMode = Enum.TextureMode.Wrap, TextureLength = 2.5, Transparency = nseq(0.3, 0.6, 1), WidthScale = nseq(1, 1.6, 0), LightEmission = 0.1, Lifetime = life * 1.6 }, tag)
    			mk(parent, up * 0.3, down * 0.3, { Color = cseq(cfg.Color, cfg.Color2), Transparency = nseq(0, 1), WidthScale = nseq(1, 0), LightEmission = 1 }, tag)
    		elseif style == "Split Neon" then

    			mk(parent, up * 1.2, up * 0.6, { Color = cseq(cfg.Color), Transparency = nseq(0, 1), WidthScale = nseq(1, 0), LightEmission = 1 }, tag)
    			mk(parent, down * 0.6, down * 1.2, { Color = cseq(cfg.Color2), Transparency = nseq(0, 1), WidthScale = nseq(1, 0), LightEmission = 1 }, tag)
    			mk(parent, up * 0.15, down * 0.15, { Color = cseq(WHITE), Transparency = nseq(0.3, 1), WidthScale = nseq(1, 0), Lifetime = life * 0.6, LightEmission = 1 }, tag)
    		elseif style == "Petals" then

    			mk(parent, up * 0.8, down * 0.8, { Transparency = nseq(0.2, 0.5, 1), WidthScale = nseq(0.5, 1, 0.3, 0), Lifetime = life * 1.3 }, tag)
    			local a = Trails:keep(attach(parent, Vector3.new(0, 0, 0.4), tag .. "P"))
    			emitter(a, { Enabled = true, Rate = q(14, 6), Texture = TEX.Heart, Color = cseq(cfg.Color2, cfg.Color), Size = nseq(0.3, 0.24), Lifetime = range(0.8, 1.4), Speed = range(1, 2), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -2.5, 0), Drag = 1, RotSpeed = range(-180, 180), Transparency = nseq(0.1, 1), LightEmission = 0.6 })
    		elseif style == "Datastream" then

    			for i = -1, 1 do
    				mk(parent, Vector3.new(0, i * W * 0.4 + W * 0.06, 0), Vector3.new(0, i * W * 0.4 - W * 0.06, 0), { Color = i == 0 and cseq(WHITE, cfg.Color) or cseq(cfg.Color, cfg.Color2), Transparency = nseq(0, 0, 1, 0, 0, 1), WidthScale = nseq(1, 1, 0), Lifetime = life * (1 + math.abs(i) * 0.3), Texture = TEX.Spark, TextureMode = Enum.TextureMode.Wrap, TextureLength = 0.4, LightEmission = 1 }, tag)
    			end
    			Trails.glitch = Trails.glitch or {}
    			local a = Trails:keep(attach(parent, Vector3.zero, tag .. "E"))
    			emitter(a, { Enabled = true, Rate = q(10, 4), Texture = TEX.Trace, Color = cseq(WHITE, cfg.Color), Size = nseq(0.14, 0.2, 0.08), Transparency = nseq(0.15, 0.4, 1), Lifetime = range(0.4, 0.8), Speed = range(1, 2.5), SpreadAngle = Vector2.new(30, 30), EmissionDirection = Enum.NormalId.Back, Acceleration = Vector3.new(0, -6, 0), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-2, -0.6), LightEmission = 1, Rotation = range(0), RotSpeed = range(0) })
    		elseif style == "Polar Light" then

    			mk(parent, up * 1.7, down * 0.2, { Color = cseq(cfg.Color, cfg.Color2, cfg.Color), Transparency = nseq(0.3, 0.6, 1), WidthScale = nseq(1, 1.25, 0), Lifetime = life * 1.8, Texture = TEX.Smoke, TextureMode = Enum.TextureMode.Wrap, TextureLength = 2 }, tag)
    			mk(parent, up * 1.7, up * 1.4, { Color = cseq(WHITE, cfg.Color), Transparency = nseq(0.1, 1), WidthScale = nseq(1, 0), Lifetime = life * 1.8, LightEmission = 1 }, tag)
    			local a = Trails:keep(attach(parent, Vector3.new(0, W * 0.8, 0), tag .. "E"))
    			emitter(a, { Enabled = true, Rate = q(10, 4), Texture = TEX.Mote, Color = cseq(WHITE, cfg.Color2), Size = nseq(0.1, 0.05, 0), Lifetime = range(1, 2), Speed = range(0.3, 0.9), SpreadAngle = Vector2.new(180, 180), Drag = 1.6, Transparency = nseq(0.1, 1), LightEmission = 1 })
    		elseif style == "Comet Tail" then

    			mk(parent, up * 0.5, down * 0.5, { Transparency = nseq(0, 0.3, 1), WidthScale = nseq(1, 0.3, 0), Lifetime = life * 1.6, Texture = TEX.Spark, TextureMode = Enum.TextureMode.Wrap, TextureLength = 1, LightEmission = 1 }, tag)
    			mk(parent, up * 1.1, down * 1.1, { Texture = TEX.Field, TextureMode = Enum.TextureMode.Wrap, TextureLength = 2, Transparency = nseq(0.65, 0.85, 1), WidthScale = nseq(1, 1.2, 0), Lifetime = life * 1.2 }, tag)
    			local a = Trails:keep(attach(parent, Vector3.new(0, 0, 0.5), tag .. "C"))
    			emitter(a, { Enabled = true, Rate = q(24, 8), Color = seq, Size = nseq(0.3, 0), Lifetime = range(0.4, 0.8), Speed = range(1, 2), SpreadAngle = Vector2.new(25, 25), EmissionDirection = Enum.NormalId.Back, Acceleration = Vector3.new(0, -3, 0), Transparency = nseq(0, 1) })
    		elseif style == "Static" then

    			mk(parent, up, down, { Transparency = nseq(0, 1), WidthScale = nseq(1, 0.2, 1, 0.2, 0), Lifetime = life * 0.8, LightEmission = 0.8 }, tag)
    			Trails.glitch = Trails.glitch or {}
    			local a = Trails:keep(attach(parent, Vector3.zero, tag .. "E"))
    			emitter(a, { Enabled = true, Rate = q(16, 6), Texture = TEX.Scratch, Color = cseq(WHITE, cfg.Color2), Size = nseq(0.2, 0.5, 0.1), Transparency = nseq(0.1, 0.5, 1), Lifetime = range(0.1, 0.25), Speed = range(2, 5), SpreadAngle = Vector2.new(180, 180), Rotation = range(-180, 180), LightEmission = 1 })
    		elseif style == "Phantom" then

    			mk(parent, Vector3.new(0, 1.2, 0), Vector3.new(0, -1.2, 0), { Transparency = nseq(0.6, 0.7, 1), WidthScale = nseq(1, 0.9, 0), Lifetime = life * 1.2, LightEmission = 0.4 }, tag)
    			mk(parent, up, down, { Texture = TEX.Smoke, TextureMode = Enum.TextureMode.Wrap, TextureLength = 2, Transparency = nseq(0.5, 0.8, 1), WidthScale = nseq(1.3, 1.6, 0), Lifetime = life * 1.8 }, tag)
    		elseif style == "Spectrum" then

    			mk(parent, up, down, { Transparency = nseq(0.05, 0.5, 1), WidthScale = nseq(1, 1.1, 0.3, 0), LightEmission = 0.8 }, tag)
    			local a = Trails:keep(attach(parent, Vector3.zero, tag .. "E"))
    			emitter(a, { Enabled = true, Rate = q(12, 5), Texture = TEX.Glint, Color = ColorSequence.new(Color3.fromHSV(0, 0.8, 1), Color3.fromHSV(0.5, 0.8, 1), Color3.fromHSV(1, 0.8, 1)), Size = nseq(0.14, 0.06, 0), Lifetime = range(0.5, 1), Speed = range(0.8, 1.8), SpreadAngle = Vector2.new(180, 180), Transparency = nseq(0, 1), Rotation = range(-180, 180), RotSpeed = range(140) })
    		elseif style == "Twin Helix" then

    			local t1, h1a, h1b = mk(parent, Vector3.new(0, W * 0.6, 0), Vector3.new(0, -W * 0.6, 0), { Color = cseq(cfg.Color), Transparency = nseq(0, 0.4, 1), WidthScale = nseq(1, 0.9, 0), LightEmission = 1 }, tag)
    			local t2, h2a, h2b = mk(parent, Vector3.new(0, -W * 0.6, 0), Vector3.new(0, W * 0.6, 0), { Color = cseq(cfg.Color2), Transparency = nseq(0, 0.4, 1), WidthScale = nseq(1, 0.9, 0), LightEmission = 1 }, tag)
    			Trails.helix = Trails.helix or {}
    			table.insert(Trails.helix, { a0 = h1a, a1 = h1b, b0 = h2a, b1 = h2b, W = W })
    		elseif style == "Vapor" then

    			mk(parent, up * 1.3, down * 1.3, { Texture = TEX.Puff, TextureMode = Enum.TextureMode.Wrap, TextureLength = 2.2, Transparency = nseq(0.5, 0.8, 1), WidthScale = nseq(1, 1.4, 0), Lifetime = life * 1.5, LightEmission = 0.3 }, tag)
    			local a = Trails:keep(attach(parent, Vector3.zero, tag .. "E"))
    			emitter(a, { Enabled = true, Rate = q(8, 3), Texture = TEX.Puff, Color = cseq(cfg.Color, cfg.Color2), Size = nseq(0.6, 1.4), Transparency = nseq(0.6, 0.8, 1), Lifetime = range(0.8, 1.4), Speed = range(0.4, 1), SpreadAngle = Vector2.new(180, 180), Drag = 2, RotSpeed = range(-40, 40), LightEmission = 0.2 })
    		elseif style == "Stardust" then

    			mk(parent, up * 0.35, down * 0.35, { Transparency = nseq(0.15, 0.6, 1), WidthScale = nseq(1, 0.4, 0), Lifetime = life * 1.1, LightEmission = 0.9 }, tag)
    			local a = Trails:keep(attach(parent, Vector3.zero, tag .. "E"))
    			emitter(a, { Enabled = true, Rate = q(20, 8), Texture = TEX.Star, Color = cseq(WHITE, cfg.Color, cfg.Color2), Size = nseq(0.2, 0.1, 0), Lifetime = range(0.7, 1.4), Speed = range(0.6, 1.6), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -1.5, 0), Drag = 1.4, Transparency = nseq(0, 1), Rotation = range(-180, 180), RotSpeed = range(-200, 200), LightEmission = 1 })
    		elseif style == "Ember Wake" then

    			mk(parent, up, down, { Texture = TEX.Fire, TextureMode = Enum.TextureMode.Wrap, TextureLength = 1.6, Transparency = nseq(0.1, 0.5, 1), WidthScale = nseq(1, 1.2, 0), LightEmission = 1 }, tag)
    			mk(parent, up * 0.5, down * 0.5, { Color = cseq(BLACK, tint(cfg.Color2, -0.4)), Transparency = nseq(0.4, 0.8, 1), WidthScale = nseq(1.2, 1.4, 0), Lifetime = life * 1.8, LightEmission = 0 }, tag)
    			local a = Trails:keep(attach(parent, Vector3.new(0, -0.2, 0), tag .. "E"))
    			emitter(a, { Enabled = true, Rate = q(18, 7), Texture = TEX.Ember, Color = cseq(Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 80, 20)), Size = nseq(0.16, 0.06, 0), Lifetime = range(0.5, 1.1), Speed = range(1, 2.4), SpreadAngle = Vector2.new(60, 60), EmissionDirection = Enum.NormalId.Bottom, Acceleration = Vector3.new(0, -4, 0), Transparency = nseq(0, 1), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-2, -0.4), Rotation = range(0), RotSpeed = range(0) })
    		elseif style == "Stamp Path" then

    			mk(parent, up * 0.6, down * 0.6, { Texture = TEX.Swirl, TextureMode = Enum.TextureMode.Static, TextureLength = 1.4, Transparency = nseq(0.1, 0.4, 1), WidthScale = nseq(1, 1, 0), LightEmission = 0.9 }, tag)
    			mk(parent, up, down, { Texture = TEX.Ring, TextureMode = Enum.TextureMode.Wrap, TextureLength = 2.4, Transparency = nseq(0.6, 0.85, 1), WidthScale = nseq(1.15, 1.3, 0), Lifetime = life * 1.2, LightEmission = 0.4 }, tag)
    		else

    			mk(parent, up, down, { Texture = TEX.Drop, TextureMode = Enum.TextureMode.Wrap, TextureLength = 1.8, Transparency = nseq(0.15, 0.45, 1), WidthScale = nseq(1, 1.3, 0.5, 0), LightEmission = 0.5 }, tag)
    			mk(parent, up * 0.4, down * 0.4, { Color = cseq(WHITE, cfg.Color2), Transparency = nseq(0.4, 1), WidthScale = nseq(0.5, 0), Lifetime = life * 0.8, LightEmission = 1 }, tag)
    			local a = Trails:keep(attach(parent, Vector3.zero, tag .. "E"))
    			emitter(a, { Enabled = true, Rate = q(14, 6), Texture = TEX.Drop, Color = cseq(WHITE, cfg.Color), Size = nseq(0.16, 0.12), Lifetime = range(0.4, 0.8), Speed = range(1.5, 3), SpreadAngle = Vector2.new(60, 60), EmissionDirection = Enum.NormalId.Back, Acceleration = Vector3.new(0, -14, 0), Transparency = nseq(0.15, 0.6, 1), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-1.6, -0.4), Rotation = range(0), RotSpeed = range(0), LightEmission = 0.6 })
    		end
    	end

    	Trails.glitch, Trails.helix = nil, nil
    	buildOn(root, 1, "PF_Trail")
    	if cfg.Limbs then
    		local names = Char.r6 and { "Left Arm", "Right Arm", "Left Leg", "Right Leg" } or { "LeftHand", "RightHand", "LeftFoot", "RightFoot" }
    		for _, nm in ipairs(names) do
    			local part = Char.model:FindFirstChild(nm)
    			if part then buildOn(part, 0.35, "PF_LimbTrail") end
    		end
    	end
    	if cfg.Echo then
    		mk(root, Vector3.new(0, w * 0.9, 0), Vector3.new(0, -w * 0.9, 0), { Color = cseq(cfg.Color2, cfg.Color), Transparency = nseq(0.6, 1), WidthScale = nseq(1, 0), Lifetime = life * 2 }, "PF_TrailEcho")
    	end
    	if cfg.Sparks then
    		local a = attach(root, Vector3.new(0, 0, 0.6), "PF_TrailSparks")
    		Trails:keep(a)
    		emitter(a, { Enabled = true, Rate = q(10, 4), Texture = TEX.Glint, Color = seq, Size = nseq(0.25, 0), Lifetime = range(0.4, 0.8), Speed = range(1, 3), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -4, 0), Drag = 1, Transparency = nseq(0, 1), Rotation = range(-180, 180), RotSpeed = range(-120, 120) })
    	end

    	local acc, hueAcc, was = 0, 0, true
    	Tick.use("Trails", function(dt, t)
    		local c = S.Trails

    		local rh = RainbowHue.Trails
    		if c.Rainbow or rh then
    			hueAcc = hueAcc + dt
    			if hueAcc > 0.1 then
    				hueAcc = 0
    				local h = rh or ((t * 0.12) % 1)
    				local s2 = trailSeq(style, c.Color, c.Color2, h)
    				for _, tr in ipairs(made) do tr.Color = s2 end
    			end
    		end
    		if Trails.glitch then
    			for i, tr in ipairs(Trails.glitch) do tr.Enabled = (math.sin(t * 25 + i * 2.3) + 0.55 * organicNoise(t * 2.2, i * 3.7)) > -0.45 end
    		end
    		if Trails.helix then
    			for _, h in ipairs(Trails.helix) do
    				local y = math.sin(t * 9) * h.W * 0.5
    				h.a0.Position = Vector3.new(0, y + h.W * 0.1, 0) h.a1.Position = Vector3.new(0, y - h.W * 0.1, 0)
    				h.b0.Position = Vector3.new(0, -y + h.W * 0.1, 0) h.b1.Position = Vector3.new(0, -y - h.W * 0.1, 0)
    			end
    		end

    		if c.SpeedReactive and Char.root and Char.root.Parent then
    			acc = acc + dt
    			if acc > 0.1 then
    				acc = 0
    				local v = velocityOf(Char.root)
    				local hs = Vector3.new(v.X, 0, v.Z).Magnitude
    				local on = hs > 2
    				local k = clamp(hs / 16, 0.4, 2.2)
    				for _, tr in ipairs(made) do
    					tr.Enabled = on
    					tr.Lifetime = c.Lifetime * k
    				end
    				was = on
    			end
    		elseif not was then
    			was = true
    			for _, tr in ipairs(made) do tr.Enabled = true tr.Lifetime = c.Lifetime end
    		end
    	end)
    	Trails.built = true
    end

    local Kill = defineModule("Kill", {
    	Enabled = false, Style = "Soul Column", Color = Color3.fromRGB(255, 70, 70), Size = 1,
    	Flash = true, Counter = false, Streak = false, Range = 0, OnSelf = false,
    }, { transient = true })
    Kill.Styles = {
    	"Soul Column", "Supernova", "Glass Shatter", "Inferno Pit", "Singularity", "Heart Pop", "Deep Freeze", "Delete",
    	"Rocket Salvo", "Grave Bloom", "Sky Strike", "Spirit Cage", "Ink Execution", "Clockwork", "Prism Cascade", "Shockwave Dome",
    	"Detonation", "Star Burst", "Smoke Screen", "Tidal",
    }
    Kill.count, Kill.streak, Kill.lastAt = 0, 0, -100

    local function killFX(pos, victim)
    	local cfg = S.Kill
    	local pal = paletteFor("Kill", cfg)
    	local size = cfg.Size
    	local cf = CFrame.new(pos)
    	local ground = groundAt(pos, victim, 3)
    	local style = cfg.Style
    	if cfg.Flash then
    		glint(cf, pal.bright, 14 * size, 8, 0.4)
    		outlinePulse(victim, pal.base, pal.bright, 0.6, { fill = 0.2, outline = 0 })
    		flashSprite(cf, { tex = TEX.Glint, color = pal.seqGlass, s0 = 1, s1 = 9 * size, life = 0.25, y = 0 })
    		shockSprite(ground, { tex = TEX.Shock, color = pal.seqHot, s0 = 0.5, s1 = 9 * size, life = 0.5, a0 = 0.1 })
    	end
    	if style == "Soul Column" then

    		column(ground, { Color = pal.seqHot, W0 = 1.5 * size, W1 = 0.3, H = 13 * size, Dur = 1.4, Twist = 0.5 * size, Texture = TEX.Spark, Speed = 2 })
    		PFPrim.soulFX(ground, { N = q(7, 4), Dur = 1.7, spread = 1.1 * size, color = cseq(Color3.fromRGB(190, 225, 255), WHITE) })
    		for i = 1, 3 do
    			ringWave(ground, { Color = pal.seq, R0 = 0.3, R1 = (3.5 + i) * size, W0 = 0.5, W1 = 0.05, Dur = 1.1, Delay = i * 0.12 })
    		end
    		geyser(ground, q(22, 8), pal.seqHot, { speed = 8, life = 1.5, spread = 12, gravity = 2, size = 0.28, drag = 0.5 })
    	elseif style == "Supernova" then

    		flipBoom(cf, { size = 7 * size, life = 0.9, y = 2, color = pal.seqGlass })
    		burst(cf, pal, { size = 2.2 * size, y = 2, sparks = 40, puffs = 8 })
    		for i = 1, 3 do
    			ringWave(ground, { Color = i == 1 and pal.seqHot or pal.seq, R0 = 0.3, R1 = (5 + i * 1.5) * size, W0 = 0.9, W1 = 0.05, Dur = 0.6 + i * 0.12, Delay = (i - 1) * 0.08 })
    		end
    		spokes(cf, { Color = pal.seqHot, N = 12, L = 6 * size, W = 0.5, Dur = 0.5, Elev = RAD(15) })
    		flashSprite(cf * CFrame.new(0, 2, 0), { tex = TEX.Core, color = pal.seqHot, s0 = 1, s1 = 8 * size, life = 0.35, rotSpeed = 90 })
    		cameraShake(0.25, 0.4)
    	elseif style == "Glass Shatter" then

    		PFPrim.crackFX(ground, { N = 8, Len = 4.5 * size, W = 0.08, Dur = 1.2, color = pal.seqGlass })
    		PFPrim.spikeFX(cf, { N = q(10, 6), Len = 1.6 * size, W = 0.2, Dur = 1.2, Up = 0.6, color = pal.seqGlass })
    		shards(cf, { Color = pal.seqGlass, N = 16, Speed = 11 * size, W = 0.2, Len = 0.8, Dur = 1.4, Gravity = -26, Up = 0.6, A0 = 0.1 })
    		for i = 1, 4 do
    			flashSprite(cf * CFrame.new(rnd(-1, 1) * 2 * size, rnd(0.5, 2.5), rnd(-1, 1) * 2 * size), { tex = TEX.Glint, color = Color3.fromHSV(math.random(), 0.55, 1), s0 = 0.1, s1 = 0.9, life = 0.6, rotSpeed = 140 })
    		end
    		glint(cf, WHITE, 10, 10, 0.15)
    	elseif style == "Inferno Pit" then

    		local fire = cseq(WHITE, pal.bright, pal.base, tint(pal.deep, -0.5))
    		ringWave(ground, { Color = fire, R0 = 0.5, R1 = 4 * size, W0 = 0.3, W1 = 1.2, Dur = 1.6, A0 = 0.1, Texture = TEX.Fire, TextureLength = 1, TextureSpeed = 2 })
    		PFPrim.crackFX(ground, { N = 6, Len = 3.2 * size, W = 0.1, Dur = 1.4, color = fire, dustColor = cseq(pal.deep, BLACK) })
    		geyser(ground, q(30, 12), fire, { speed = 12, life = 1.4, spread = 30, gravity = 4, size = 1.1, tex = TEX.Fire })
    		geyser(ground, q(24, 10), fire, { speed = 14 * size, life = 1.4, spread = 45, gravity = -25, drag = 1, size = 0.3, tex = TEX.Ember, streak = true })
    		geyser(ground * CFrame.new(0, 1, 0), q(10, 4), cseq(pal.deep, BLACK), { speed = 4, life = 2.4, spread = 25, gravity = 2, size = 2, tex = TEX.Puff, emission = 0, a0 = 0.4 })
    		flipBoom(ground, { size = 5 * size, life = 0.8, y = 2, color = fire })
    	elseif style == "Singularity" then

    		for i = 1, 2 do
    			ringWave(cf * CFrame.Angles(RAD(90), i * RAD(90), 0), { Color = pal.seqDark or cseq(BLACK, BLACK), R0 = 6 * size, R1 = 0.2, W0 = 0.1, W1 = 1.2, Dur = 0.9, Spin = 4 })
    		end
    		fan(cf, q(36, 14), cseq(pal.bright, pal.base, BLACK), { inward = true, r = 5 * size, speed = 14, life = 0.8, size = 0.3, up = 0.3 })
    		helixRibbon(cf * CFrame.Angles(0, 0, RAD(90)), { Color = cseq(pal.deep, BLACK), R0 = 3.5 * size, R1 = 0.1, H = 0.2, Turns = 4, W = 0.2, Dur = 0.85, A0 = 0.3 })
    		plate(cf, cseq(BLACK, BLACK), { s0 = 0.5, s1 = 2.2 * size, life = 0.9, a0 = 0.9, tex = TEX.Circle, emission = 0 })
    		later(0.85, function()
    			glint(cf, WHITE, 30, 14, 0.4)
    			shockSprite(ground, { tex = TEX.Shock, color = pal.seqHot, s0 = 1, s1 = 9 * size, life = 0.6 })
    			ringWave(ground, { Color = pal.seqHot, R0 = 0.2, R1 = 8 * size, W0 = 1.0, W1 = 0.05, Dur = 0.7 })
    			scatter(cf, q(26, 10), pal.seqHot, { speed = 16 * size, life = 1, size = 0.3, gravity = 0, drag = 2 })
    		end)
    	elseif style == "Heart Pop" then

    		PFPrim.heartFX(cf, { r = 2.2 * size, W = 0.12, Dur = 1.4, color = cseq(WHITE, Color3.fromRGB(255, 150, 200), pal.base), Rise = 1.4 })
    		local ha = worldAttach(cf * CFrame.new(0, 1.5, 0))
    		emitter(ha, { Texture = TEX.Heart, Color = cseq(WHITE, Color3.fromRGB(255, 150, 200), pal.base), Size = nseq(0.6 * size, 0.8 * size, 0), Transparency = nseq(0, 0, 1), Lifetime = range(1.2, 2), Speed = range(3, 6), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 3, 0), Drag = 2, Rotation = range(-30, 30), RotSpeed = range(-60, 60), ZOffset = 0.2 }):Emit(q(14, 6))
    		Debris:AddItem(ha, 2.4)
    		ringWave(ground, { Color = cseq(WHITE, Color3.fromRGB(255, 170, 210)), R0 = 0.3, R1 = 4 * size, W0 = 0.4, W1 = 0.05, Dur = 1 })
    	elseif style == "Deep Freeze" then

    		PFPrim.snowflakeFX(ground, { r = 2.6 * size, Dur = 1.5, Spin = 0.5, color = cseq(WHITE, Color3.fromRGB(190, 235, 255)) })
    		domeBurst(ground, { Color = pal.seqGlass, R0 = 0.3, R1 = 3.5 * size, Height = 1.1, Dur = 0.8, A0 = 0.35, Spin = 0.4 })
    		PFPrim.spikeFX(cf, { N = q(9, 5), Len = 1.8 * size, W = 0.24, Dur = 1.5, Up = 0.5, color = cseq(WHITE, Color3.fromRGB(200, 240, 255)) })
    		ringWave(ground, { Color = pal.seqGlass, R0 = 0.3, R1 = 5 * size, W0 = 0.5, W1 = 0.05, Dur = 1.2, N = 6, Segments = 2 })
    		geyser(ground, q(12, 5), cseq(WHITE, pal.bright), { speed = 1.5, life = 1.8, spread = 70, size = 0.8, gravity = 0.5, drag = 2.5, tex = TEX.Puff, a0 = 0.55, emission = 0.4 })
    		scatter(cf, q(16, 8), cseq(WHITE, pal.bright), { speed = 5, life = 1.8, size = 0.18, gravity = -2, drag = 1, tex = TEX.Star })
    	elseif style == "Delete" then

    		PFPrim.glitchFX(cf, { W = 2.4 * size, H = 4.5, rows = 8, Dur = 0.9, color = pal.bright })
    		PFPrim.matrixFX(cf, { R = 1.6 * size, cols = q(8, 4), h = 5, speed = 12, Dur = 0.8, color = pal.seqHot })
    		local scan = worldAttach(cf)
    		emitter(scan, { Texture = TEX.Scratch, Color = pal.seqHot, Size = nseq(4.5 * size, 4.5 * size), Transparency = nseq(0.25, 0.7, 1), Lifetime = range(0.5), Speed = range(0.01), EmissionDirection = Enum.NormalId.Top, Orientation = Enum.ParticleOrientation.VelocityPerpendicular, LockedToPart = true, ZOffset = 0.05, LightEmission = 1, Rotation = range(0, 90), RotSpeed = range(0) })
    		Timeline.add(0.9, function(a)
    			scan.CFrame = cf * CFrame.new(0, 4.5 * (1 - a), 0)
    		end, function() scan:Destroy() end)
    		scatter(cf, q(26, 10), pal.seqHot, { speed = 6, life = 1, size = 0.14, gravity = 6, drag = 1 })
    	elseif style == "Rocket Salvo" then

    		for i = 1, 3 do
    			local off = (i - 2) * 1.6 * size
    			local base = ground * CFrame.new(off, 0.2, 0)
    			local hue = (i * 0.31) % 1
    			later((i - 1) * 0.16, function()
    				PFPrim.cometFX(base, { from = base.Position, to = (base * CFrame.new(rnd(-1, 1), 13 * size, rnd(-1, 1))).Position, T = 0.55, arc = 0.4, color = ColorSequence.new(WHITE, Color3.fromHSV(hue, 0.8, 1)), size = 0.4, trailLife = 0.5, impact = false })
    			end)
    			later(0.6 + (i - 1) * 0.16, function()
    				local top = base * CFrame.new(0, 12.5 * size, 0)
    				flipBoom(top, { size = 3 * size, life = 0.5, y = 0, color = ColorSequence.new(WHITE, Color3.fromHSV(hue, 0.8, 1)) })
    				scatter(top, q(30, 12), cseq(WHITE, Color3.fromHSV(hue, 0.8, 1), pal.base), { speed = 12 * size, life = 1.4, size = 0.3, gravity = -8, drag = 1.5 })
    				ringWave(top, { Color = pal.seq, R0 = 0.3, R1 = 5 * size, W0 = 0.4, W1 = 0.03, Dur = 0.7 })
    				glint(top, pal.bright, 24, 10, 0.4)
    			end)
    		end
    	elseif style == "Grave Bloom" then

    		local ghostly = cseq(Color3.fromRGB(190, 255, 210), WHITE, pal.bright)
    		PFPrim.polyFX(ground * CFrame.Angles(0, 0, RAD(90)), { Assembly = true, kind = "cross", r = 1, W = 0.01, color = WHITE, Dur = 0.1, Draw = 0, Plane = "none" })
    		local cross = worldAttach(ground * CFrame.new(0, 0.1, 0))
    		emitter(cross, { Texture = TEX.Scratch, Color = ghostly, Size = nseq(1.6 * size, 2 * size), Transparency = nseq(0.35, 0.6, 1), Lifetime = range(1.6), Speed = range(0.01), EmissionDirection = Enum.NormalId.Top, Orientation = Enum.ParticleOrientation.VelocityPerpendicular, ZOffset = 0.05, LightEmission = 0.7, Rotation = range(0, 90) }):Emit(1)
    		Debris:AddItem(cross, 2)
    		PFPrim.soulFX(ground * CFrame.new(0, 0.6, 0), { N = q(5, 3), Dur = 1.9, spread = 0.7 * size, color = ghostly })
    		geyser(ground, q(20, 8), cseq(Color3.fromRGB(110, 80, 55), Color3.fromRGB(60, 42, 28)), { speed = 7 * size, life = 1.1, spread = 40, gravity = -22, drag = 0.8, size = 0.3, tex = TEX.Puff, emission = 0, a0 = 0.35 })
    		arcSpray(ground, { Color = pal.seqHot, N = 7, R0 = 0.3, R1 = 2.6 * size, W = 0.3, Dur = 1.3, Span = 0.15, Tilt1 = RAD(82), Rise = 1.4 * size, Spin = 0.4 })
    		column(ground, { Color = pal.seqFade, W0 = 1.4 * size, W1 = 0.1, H = 6 * size, Dur = 1.5, A0 = 0.4 })
    	elseif style == "Sky Strike" then

    		column(ground * CFrame.new(0, 22, 0), { Color = cseq(WHITE, pal.bright), W0 = 2.2 * size, W1 = 0.4, H = 44, Dur = 0.55, Texture = TEX.Spark, Speed = 6 })
    		skyBolt(ground, { Color = cseq(WHITE, pal.bright), W = 0.4 * size, H = 45, Dur = 0.4, LightColor = pal.bright, Branches = 3 })
    		later(0.12, function()
    			PFPrim.crackFX(ground, { N = 7, Len = 4.5 * size, W = 0.12, Dur = 1.1, color = pal.seqHot })
    			ringWave(ground, { Color = pal.seqHot, R0 = 0.3, R1 = 6 * size, W0 = 0.7, W1 = 0.05, Dur = 0.6 })
    			scatter(ground * CFrame.new(0, 1, 0), q(26, 10), cseq(WHITE, pal.bright), { speed = 10 * size, life = 0.8, size = 0.24, gravity = -10 })
    			plate(ground, cseq(pal.deep, BLACK), { s0 = 2, s1 = 7 * size, life = 1.2, a0 = 0.3, count = 2, emission = 0 })
    			cameraShake(0.3, 0.45)
    		end)
    	elseif style == "Spirit Cage" then

    		for i = 1, 4 do
    			ringWave(ground, { Color = pal.seqHot, R0 = 3.5 * size, R1 = 1.2 * size, W0 = 0.3, W1 = 0.55, Dur = 1.2, Delay = i * 0.1, Rise = 6 * size * i / 4, Spin = 1.5, A0 = 0.2 })
    		end
    		local bars = q(7, 5)
    		for i = 1, bars do
    			column(ground * CFrame.Angles(0, i / bars * TAU, 0) * CFrame.new(0, 0, -2.4 * size), { Color = pal.seq, W0 = 0.14, W1 = 0.14, H = 7 * size, Dur = 1.5, A0 = 0.15, Texture = TEX.Spark, Speed = 1.5 })
    		end
    		PFPrim.soulFX(ground, { N = q(6, 3), Dur = 1.8, spread = 1.4 * size, color = cseq(pal.bright, WHITE) })
    		geyser(ground, q(18, 8), pal.seqHot, { speed = 5, life = 1.8, spread = 22, gravity = 1.5, size = 0.26, drag = 0.5 })
    	elseif style == "Ink Execution" then

    		PFPrim.inkFX(ground, { size = 3.2 * size, N = 10, Dur = 1.5, color = cseq(BLACK, tint(BLACK, 0.2)) })
    		geyser(cf, q(14, 6), cseq(BLACK, tint(BLACK, 0.25)), { speed = 6, life = 1.3, spread = 24, gravity = -6, drag = 1, size = 0.5 * size, tex = TEX.Smoke, emission = 0, a0 = 0.35 })
    		for i = 1, 3 do
    			ringWave(ground, { Color = cseq(tint(BLACK, 0.15), BLACK), R0 = 0.3, R1 = (2.5 + i) * size, W0 = 0.5, W1 = 0.1, Dur = 1.3, Delay = i * 0.1, A0 = 0.3, Texture = TEX.Smoke, TextureLength = 1.4 })
    		end
    		scatter(ground * CFrame.new(0, 1, 0), q(20, 8), cseq(tint(BLACK, 0.1), BLACK), { speed = 7, life = 1.1, size = 0.2, gravity = -16, drag = 1.2, y = 0.5 })
    		flashSprite(cf * CFrame.new(0, 1.5, 0), { tex = TEX.Scratch, color = WHITE, s0 = 0.5, s1 = 3 * size, life = 0.4, rotSpeed = 60 })
    	elseif style == "Clockwork" then

    		PFPrim.clockFX(ground, { r = 2.8 * size, Dur = 1.7, color = cseq(WHITE, pal.bright) })
    		PFPrim.polyFX(ground * CFrame.new(0, 1.2, 0) * CFrame.Angles(RAD(90), 0, 0), { Assembly = true, kind = "gear", r = 1.4 * size, W = 0.08, color = pal.seq, Dur = 1.7, Draw = 0.35, Spin = 2.2, lift = 0 })
    		PFPrim.polyFX(ground * CFrame.new(0, 1.2, 0) * CFrame.Angles(RAD(90), 0.6, 0), { Assembly = true, kind = "gear", r = 0.9 * size, W = 0.07, color = pal.seqHot, Dur = 1.7, Draw = 0.35, Spin = -3.4, lift = 0 })
    		geyser(ground, q(10, 4), pal.seqFade, { speed = 2.5, life = 1.2, spread = 45, size = 0.5 * size, gravity = 1, drag = 2, tex = TEX.Puff, a0 = 0.4, emission = 0.3 })
    	elseif style == "Prism Cascade" then

    		PFPrim.prismFX(cf * CFrame.new(0, 0, 0), { r = 5 * size, Dur = 1.1 })
    		for i = 1, 5 do
    			local hue = (i - 1) / 5
    			column(ground * CFrame.new((i - 3) * 1.1 * size, 0, rnd(-0.6, 0.6) * size), { Color = ColorSequence.new(WHITE, Color3.fromHSV(hue, 0.85, 1)), W0 = 0.22, W1 = 0.03, H = 11 * size, Dur = 0.9, Delay = i * 0.07 })
    		end
    		scatter(cf * CFrame.new(0, 3, 0), q(24, 10), ColorSequence.new(Color3.fromHSV(0, 0.8, 1), Color3.fromHSV(0.5, 0.8, 1), Color3.fromHSV(1, 0.8, 1)), { speed = 6, life = 1.4, size = 0.2, gravity = -12, drag = 0.6, tex = TEX.Glint })
    		glint(cf, WHITE, 14, 12, 0.3)
    	elseif style == "Shockwave Dome" then

    		domeBurst(cf, { Color = pal.seqGlass, R0 = 0.4, R1 = 7 * size, Height = 1, Dur = 0.9, A0 = 0.25, Spin = 0.3 })
    		shockSprite(ground, { tex = TEX.Shock, color = pal.seqHot, s0 = 0.5, s1 = 10 * size, life = 0.7 })
    		shockSprite(ground, { tex = TEX.Ring, color = pal.seq, s0 = 0.5, s1 = 8 * size, life = 0.9, a0 = 0.2, z = 0.02 })
    		fan(ground, q(20, 8), pal.seqFade, { speed = 9 * size, life = 1, size = 0.7, up = 0.15, tex = TEX.Puff, gravity = 0.5, drag = 2, emission = 0, a0 = 0.45, spread = 14 })
    		ringWave(ground, { Color = pal.seqHot, R0 = 0.3, R1 = 7 * size, W0 = 0.8, W1 = 0.05, Dur = 0.8 })
    		cameraShake(0.2, 0.35)
    	elseif style == "Detonation" then

    		PFPrim.crackFX(ground, { N = 7, Len = 4 * size, W = 0.12, Dur = 1.2, color = cseq(pal.bright, pal.base), dustColor = cseq(pal.deep, BLACK) })
    		flipBoom(ground * CFrame.new(0, 1.5, 0), { size = 6 * size, life = 0.85, y = 0, color = pal.seqGlass })
    		burst(ground * CFrame.new(0, 1, 0), pal, { size = 1.8 * size, y = 0.5, sparks = 34, puffs = 7 })
    		column(ground, { Color = cseq(WHITE, pal.bright, pal.base), W0 = 1.6 * size, W1 = 0.2, H = 9 * size, Dur = 1.1, Texture = TEX.Fire, Speed = 3 })
    		geyser(ground * CFrame.new(0, 5 * size, 0), q(14, 6), cseq(pal.deep, BLACK), { speed = 3, life = 2, spread = 70, size = 2.4, gravity = 0.5, drag = 2, tex = TEX.Puff, emission = 0, a0 = 0.5 })
    		cameraShake(0.32, 0.5)
    	elseif style == "Star Burst" then

    		PFPrim.polyFX(cf * CFrame.new(0, 1.5, 0) * CFrame.Angles(RAD(90), 0, 0), { Assembly = true, kind = "star", r = 3 * size, W = 0.12, color = pal.seqHot, Dur = 1.2, Draw = 0.35, Spin = 1.2, lift = 0 })
    		local sa = worldAttach(cf * CFrame.new(0, 2, 0))
    		emitter(sa, { Texture = TEX.Star, Color = cseq(WHITE, pal.bright, pal.base), Size = nseq(0.4 * size, 0.2 * size, 0), Transparency = nseq(0, 0.2, 1), Lifetime = range(0.8, 1.6), Speed = range(6, 13), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -6, 0), Drag = 1.2, Rotation = range(-180, 180), RotSpeed = range(-220, 220), LightEmission = 1 }):Emit(q(22, 9))
    		Debris:AddItem(sa, 2)
    		spokes(cf * CFrame.new(0, 1.5, 0), { Color = cseq(WHITE, pal.bright), N = 8, L = 5 * size, W = 0.3, Dur = 0.5, Elev = RAD(8) })
    		ringWave(cf * CFrame.new(0, 1.5, 0) * CFrame.Angles(RAD(90), 0, 0), { Color = pal.seqGlass, R0 = 0.3, R1 = 5 * size, W0 = 0.4, W1 = 0.03, Dur = 0.9 })
    		for i = 1, 5 do
    			later(0.15 * i, function()
    				flashSprite(cf * CFrame.new(rnd(-1, 1) * 2.5 * size, rnd(0.5, 3), rnd(-1, 1) * 2.5 * size), { tex = TEX.Star, color = WHITE, s0 = 0.1, s1 = 0.6, life = 0.35, rotSpeed = 160 })
    			end)
    		end
    	elseif style == "Smoke Screen" then

    		local n = q(8, 5)
    		for i = 1, n do
    			local a = i / n * TAU
    			plate(ground * CFrame.new(math.cos(a) * 1.8 * size, 0.6, math.sin(a) * 1.8 * size), cseq(pal.deep, tint(pal.deep, -0.6), pal.deep), { s0 = 1.5 * size, s1 = 3.6 * size, life = 2.2, a0 = 0.5, tex = TEX.Puff, emission = 0.1 })
    		end
    		geyser(ground, q(24, 10), cseq(pal.deep, BLACK), { speed = 3.5, life = 2.4, spread = 80, size = 2.2, gravity = 0.8, drag = 1.8, tex = TEX.Puff, emission = 0, a0 = 0.5 })
    		geyser(ground, q(10, 4), cseq(pal.bright, pal.base), { speed = 1.5, life = 1.6, spread = 60, size = 0.16, gravity = 1.5, drag = 2, tex = TEX.Ember, emission = 1 })
    		plate(ground, cseq(BLACK, tint(pal.deep, -0.5)), { s0 = 1, s1 = 3 * size, life = 1.8, a0 = 0.6, tex = TEX.Cloud, emission = 0 })
    	else

    		local water = cseq(WHITE, Color3.fromRGB(170, 225, 255), pal.base)
    		for i = 1, 3 do
    			arcSpray(ground, { Color = water, N = 14, R0 = 0.5, R1 = (3 + i * 0.7) * size, W = 0.8 * size, Dur = 1.3 + i * 0.1, Span = 1, Tilt0 = RAD(-8), Tilt1 = RAD(24 + i * 10), Delay = (i - 1) * 0.12, A0 = 0.15 + i * 0.1, Texture = TEX.Drop, TextureLength = 1 })
    		end
    		ripples(ground, pal, { s0 = 1 * size, s1 = 7 * size, life = 1.4, count = 5 })
    		geyser(ground, q(30, 12), water, { speed = 9 * size, life = 0.9, spread = 55, size = 0.28, gravity = -28, drag = 0.6, tex = TEX.Drop, streak = true, emission = 0.4 })
    		ringWave(ground, { Color = water, R0 = 0.4, R1 = 6 * size, W0 = 0.9, W1 = 0.06, Dur = 1.2 })
    	end

    end

    local watched = setmetatable({}, { __mode = "k" })
    local function watchChar(char, player)
    	if not char or watched[char] then return end
    	local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
    	if not hum then return end
    	watched[char] = true
    	Kill:connect(hum.Died, function()
    		if not S.Kill.Enabled then return end
    		local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    		if not root then return end
    		if S.Kill.Range and S.Kill.Range > 0 and Char.root and Char.root.Parent then
    			if (root.Position - Char.root.Position).Magnitude > S.Kill.Range then return end
    		end
    		killFX(root.Position, char)
    		Bus.emit("kill", root.Position)
    		Kill.count = Kill.count + 1
    		local now = os.clock()
    		Kill.streak = (now - Kill.lastAt < 8) and Kill.streak + 1 or 1
    		Kill.lastAt = now
    		if S.Kill.Streak and Kill.streak >= 2 and alive() then
    			local pal = paletteFor("Kill", S.Kill)
    			local n = math.min(Kill.streak, 5)
    			local mycf = groundAt(Char.root.Position, Char.model, 3)
    			for i = 1, n do
    				ringWave(mycf, { Color = pal.seqHot, R0 = 0.3, R1 = 2 + n, W0 = 0.3, W1 = 0.03, Dur = 0.7, Delay = (i - 1) * 0.1, Rise = i * 1.5 })
    			end
    			glint(mycf, pal.bright, 10 + n * 3, 6, 0.5)
    			flashSprite(mycf, { tex = TEX.Star, color = pal.seqGlass, s0 = 1, s1 = 4 + n, life = 0.4, y = 3 })
    			PF_UI.notify(("🔥 Kill streak ×%d"):format(Kill.streak), 2)
    		end
    		if S.Kill.Counter then
    			PF_UI.notify(("☠ Kill FX #%d · %s"):format(Kill.count, tostring(player and player.Name or "?")), 2)
    		end
    	end)
    end

    function Kill.build()
    	Kill:clear()
    	if not S.Kill.Enabled then return end
    	local function hook(pl)
    		if pl == LocalPlayer then return end
    		if pl.Character then watchChar(pl.Character, pl) end
    		Kill:connect(pl.CharacterAdded, function(c) task.wait(0.3) watchChar(c, pl) end)
    	end
    	for _, pl in ipairs(Players:GetPlayers()) do hook(pl) end
    	Kill:connect(Players.PlayerAdded, hook)
    	Kill.built = true
    end
    function Kill.stop()
    	Kill:clear()
    	watched = setmetatable({}, { __mode = "k" })
    end
    function Kill.preview()
    	if not alive() then return end
    	killFX(Char.root.Position, Char.model)
    end

    local AuraTrailer = defineModule("AuraTrailer", {
    	Enabled  = false,
    	Color    = Color3.fromRGB(120, 200, 255),
    	Lifetime = 0.55,
    	Length   = 4,
    	Width    = 1.1,
    	Sparks   = true,
    })
    AuraTrailer.ribbons = {}

    local function auraSeq(cfg)
    	local c = cfg.Color or Color3.fromRGB(120, 200, 255)
    	return cseq(tint(c, 0.65), c, tint(c, -0.6))
    end

    function AuraTrailer.build()
    	AuraTrailer:clear()
    	AuraTrailer.ribbons = {}
    	if not S.AuraTrailer.Enabled or not alive() or not Char.root then return end
    	local root = Char.root
    	local cfg = S.AuraTrailer
    	local seq = auraSeq(cfg)
    	local w = cfg.Width or 1.1
    	local defs = {
    		{ off = Vector3.new(0, -1.0, 0.15), side = 0.0, w0 = w,       w1 = 0.02 },
    		{ off = Vector3.new(0.6, -1.25, 0.05), side = 0.55, w0 = w * 0.55, w1 = 0.0 },
    		{ off = Vector3.new(-0.6, -1.25, 0.05), side = -0.55, w0 = w * 0.55, w1 = 0.0 },
    	}
    	for _, d in ipairs(defs) do
    		local a0 = attach(root, d.off, "PF_Aura0")
    		local a1 = Instance.new("Attachment")
    		a1.Name = "PF_Aura1"
    		a1.Parent = Terrain
    		local b = beam(a0, a1, {
    			FaceCamera = true, Segments = 8,
    			Color = seq,
    			Transparency = nseq(0.0, 0.1, 0.5, 1),
    			Width0 = d.w0, Width1 = d.w1,
    			LightEmission = 1,
    		})
    		AuraTrailer:keep(a0)
    		AuraTrailer:keep(a1)
    		AuraTrailer:keep(b)
    		table.insert(AuraTrailer.ribbons, { a0 = a0, a1 = a1, beam = b, side = d.side })
    	end

    	local gA = attach(root, CFrame.new(0, 0, 0.2), "PF_AuraGlow")
    	AuraTrailer:keep(gA)
    	local l = light(gA, cfg.Color, 7, 1.1)
    	AuraTrailer:keep(l)

    	if cfg.Sparks then
    		local eA = attach(root, CFrame.new(0, -0.9, 0.3), "PF_AuraSparks")
    		AuraTrailer:keep(eA)
    		local em = emitter(eA, {
    			Enabled = true, Rate = q(10, 5), Texture = TEX.Spark,
    			Color = cseq(tint(cfg.Color, 0.6), cfg.Color, tint(cfg.Color, -0.5)),
    			Size = nseq(0.16, 0.06, 0), Transparency = nseq(0, 0.35, 1),
    			Lifetime = range(0.4, 0.8), Speed = range(0.4, 1.1),
    			SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -1.4, 0),
    			Drag = 1.1, LightEmission = 1,
    		})
    		AuraTrailer:keep(em)
    	end
    	local buf = {}
    	AuraTrailer.buf = buf
    	Tick.use("AuraTrailer", function()
    		if not S.AuraTrailer.Enabled then return end
    		local r = Char.root
    		if not r or not r.Parent then return end
    		table.insert(buf, 1, r.Position)
    		if #buf > 8 then buf[#buf] = nil end
    		local spd = velocityOf(r)
    		local hs = Vector3.new(spd.X, 0, spd.Z)
    		local moving = hs.Magnitude > 0.6
    		local ext = moving and clamp(hs.Magnitude / 12, 0.15, 1) or 0
    		local dir = moving and hs.Unit or -r.CFrame.LookVector
    		local len = (S.AuraTrailer.Length or 4) * ext
    		local behind = r.Position - dir * len
    		for _, rib in ipairs(AuraTrailer.ribbons) do
    			local p = behind + Vector3.new(rib.side * 1.1, -0.3, rib.side * -0.3)
    			rib.a1.CFrame = CFrame.new(p)
    			rib.beam.Width0 = (S.AuraTrailer.Width or 1.1) * (rib.side == 0 and 1 or 0.55)
    				* (0.7 + 0.3 * math.sin(os.clock() * 3.5 + rib.side * 6))
    		end
    	end)
    	AuraTrailer.built = true
    end
    local function auraTrailerRecolor()
    	if not S.AuraTrailer.Enabled then return end
    	local seq = auraSeq(S.AuraTrailer)
    	for _, i in ipairs(AuraTrailer.items) do
    		pcall(function()
    			if typeof(i) == "Instance" and i:IsA("Beam") then i.Color = seq
    			elseif typeof(i) == "Instance" and i:IsA("PointLight") then i.Color = S.AuraTrailer.Color end
    		end)
    	end
    end

    local Forcefield = defineModule("Forcefield", {
    	Enabled = false,
    	Color   = Color3.fromRGB(128, 128, 128),
    })
    Forcefield.track = {}

    local function forcefieldRemember(part)
    	for _, e in ipairs(Forcefield.track) do
    		if e.part == part then return end
    	end
    	table.insert(Forcefield.track, { part = part, color = part.Color, material = part.Material })
    end
    local function forcefieldPaint(part)
    	part.Color = S.Forcefield.Color
    	part.Material = Enum.Material.ForceField
    end
    function Forcefield.build()
    	Forcefield:clear()
    	Forcefield.track = {}
    	if not S.Forcefield.Enabled or not alive() then return end
    	for _, part in ipairs(Char.model:GetDescendants()) do
    		if part:IsA("BasePart") and part.Name ~= "ChineseHat" then
    			forcefieldRemember(part)
    			forcefieldPaint(part)
    		end
    	end
    	Forcefield:connect(Char.model.DescendantAdded, function(part)
    		if not S.Forcefield.Enabled then return end
    		if part:IsA("BasePart") and part.Name ~= "ChineseHat" then
    			forcefieldRemember(part)
    			forcefieldPaint(part)
    		end
    	end)
    	Forcefield.built = true
    end
    local function forcefieldRestoreAll()
    	for _, e in ipairs(Forcefield.track) do
    		local p = e.part
    		if p and p.Parent then p.Color = e.color p.Material = e.material end
    	end
    	Forcefield.track = {}
    end
    function Forcefield.stop()
    	forcefieldRestoreAll()
    	Forcefield:clear()
    end
    function Forcefield.repaintAll()
    	if not S.Forcefield.Enabled then return end
    	for _, e in ipairs(Forcefield.track) do
    		if e.part.Parent then forcefieldPaint(e.part) end
    	end
    end

    local ParticleAura = defineModule("ParticleAura", {
    	Enabled = false,
    	Color   = Color3.fromRGB(160, 225, 255),
    	Style   = "Starlight",
    })
    ParticleAura.ids = {
    	Starlight = "rbxassetid://134645216613107",
    	Heavenly  = "rbxassetid://139300897520961",
    	Ribbon    = "rbxassetid://132069507632161",
    	Sakura    = "rbxassetid://81755778619404",
    	Angel     = "rbxassetid://97658130917593",
    	Wind      = "rbxassetid://80694081850877",
    	Flow      = "rbxassetid://119913533725648",
    	Star      = "rbxassetid://73754563740680",
    	Neon      = "rbxassetid://18498709246",
    }

    ParticleAura.assetFallback = {
    	Starlight = "Stardust Swirl", Heavenly = "Frost Motes", Ribbon = "Crystal Light",
    	Sakura = "Petal Drift", Angel = "Mana Dust", Wind = "Spirit Embers",
    	Flow = "Bubble Float", Star = "Shock Ripple", Neon = "Flame Wisps",
    }

    ParticleAura.builtins = {
    	["Frost Motes"]   = { tex = TEX.Mote,   anchors = "all",  rate = 30, s0 = 0.42, s1 = 0.16, lo = 0.8, hi = 1.6, sp0 = 0.7, sp1 = 1.8, up = 1.1, drag = 0.5, rot = 60, glow = 1 },
    	["Spirit Embers"] = { tex = TEX.Ember,  anchors = "all",  rate = 26, s0 = 0.46, s1 = 0.12, lo = 0.8, hi = 1.8, sp0 = 1.0, sp1 = 2.6, up = 1.6, drag = 1.0, rot = 80, glow = 1, streak = true },
    	["Crystal Light"] = { tex = TEX.Spark,  anchors = "all",  rate = 30, s0 = 0.40, s1 = 0.12, lo = 0.7, hi = 1.4, sp0 = 0.6, sp1 = 2.0, up = 0.9, drag = 0.8, rot = 120, glow = 1 },
    	["Stardust Swirl"]= { tex = TEX.Star,   anchors = "all",  rate = 22, s0 = 0.52, s1 = 0.16, lo = 1.0, hi = 1.8, sp0 = 0.5, sp1 = 1.4, up = 1.0, drag = 1.4, rot = 140, glow = 1 },
    	["Petal Drift"]   = { tex = TEX.Heart,  anchors = "body", rate = 18, s0 = 0.55, s1 = 0.22, lo = 1.2, hi = 2.2, sp0 = 0.4, sp1 = 1.1, up = 0.5, drag = 2.2, rot = 240, glow = 0.9 },
    	["Pollen Glow"]   = { tex = TEX.Mote,   anchors = "all",  rate = 26, s0 = 0.34, s1 = 0.12, lo = 1.4, hi = 2.4, sp0 = 0.3, sp1 = 0.9, up = 0.4, drag = 2.6, rot = 80, glow = 1 },
    	["Bubble Float"]  = { tex = TEX.Circle, anchors = "core", rate = 16, s0 = 0.40, s1 = 0.60, lo = 1.6, hi = 2.6, sp0 = 0.4, sp1 = 1.0, up = 1.1, drag = 0.9, rot = 40, glow = 0.85 },
    	["Flame Wisps"]   = { tex = TEX.Fire,   anchors = "core", rate = 34, s0 = 0.70, s1 = 0.20, lo = 0.5, hi = 1.0, sp0 = 1.4, sp1 = 3.0, up = 3.4, drag = 0.6, rot = 60, glow = 1 },
    	["Smoke Shade"]   = { tex = TEX.Smoke,  anchors = "core", rate = 18, s0 = 1.20, s1 = 2.4,  lo = 1.8, hi = 2.8, sp0 = 0.6, sp1 = 1.6, up = 1.3, drag = 1.0, rot = 50, glow = 0.5 },
    	["Shock Ripple"]  = { tex = TEX.Ripple, anchors = "core", rate = 14, s0 = 0.90, s1 = 0.50, lo = 0.9, hi = 1.3, sp0 = 0.3, sp1 = 0.9, up = 0.2, drag = 1.2, rot = 260, glow = 1 },
    	["Mana Dust"]     = { tex = TEX.Mote,   anchors = "all",  rate = 30, s0 = 0.40, s1 = 0.12, lo = 0.9, hi = 1.7, sp0 = 0.4, sp1 = 1.3, up = 1.8, drag = 0.6, rot = 120, glow = 1 },
    	["Aurora Veil"]   = { tex = TEX.Puff,   anchors = "body", rate = 20, s0 = 0.90, s1 = 1.5,  lo = 1.4, hi = 2.2, sp0 = 0.3, sp1 = 0.9, up = 0.7, drag = 1.5, rot = 40, glow = 0.8 },
    }
    ParticleAura.Styles = {}
    for n in pairs(ParticleAura.ids) do ParticleAura.Styles[#ParticleAura.Styles + 1] = n end
    for n in pairs(ParticleAura.builtins) do ParticleAura.Styles[#ParticleAura.Styles + 1] = n end

    local particleCache = {}
    local function particleTint(target, seq)
    	pcall(function()
    		if target:IsA("ParticleEmitter") or target:IsA("Beam") or target:IsA("Trail") then
    			target.Color = seq
    			if target:IsA("ParticleEmitter") then target.LightEmission = 1 target.Enabled = true end
    		elseif target:IsA("PointLight") then target.Color = seq.Keypoints[1].Value end
    		for _, o in ipairs(target:GetDescendants()) do
    			if o:IsA("ParticleEmitter") or o:IsA("Beam") or o:IsA("Trail") then
    				o.Color = seq
    				if o:IsA("ParticleEmitter") then o.LightEmission = 1 o.Enabled = true end
    			elseif o:IsA("PointLight") then o.Color = seq.Keypoints[1].Value end
    		end
    	end)
    end

    local function auraAnchors(kind)
    	local out, seen = {}, {}
    	local function add(p) if p and not seen[p] then seen[p] = true out[#out + 1] = p end end
    	if not Char.model then return out end
    	local head = Char.model:FindFirstChild("Head")
    	local torso = Char.model:FindFirstChild("UpperTorso") or Char.model:FindFirstChild("Torso")
    	local low   = Char.model:FindFirstChild("LowerTorso")
    	if kind == "core" then add(head) add(torso) return out end
    	add(head) add(torso)
    	if kind == "all" or kind == "body" then add(low) end
    	if kind == "all" then
    		for _, nm in ipairs({ "LeftHand", "RightHand", "Left Arm", "Right Arm", "LeftFoot", "RightFoot", "Left Foot", "Right Foot" }) do
    			add(Char.model:FindFirstChild(nm))
    		end
    	end
    	if #out == 0 and Char.root then add(Char.root) end
    	return out
    end

    local function applyBuiltin(style)
    	local conf = ParticleAura.builtins[style]
    	if not conf then return end
    	local color = S.ParticleAura.Color or Color3.fromRGB(160, 225, 255)
    	local seq = cseq(WHITE, tint(color, 0.55), color, tint(color, -0.25))
    	local glow = conf.glow or 1
    	local anchors = auraAnchors(conf.anchors)
    	local rate = q(conf.rate, 6)
    	local es = {}
    	local function emitOn(part, scale)
    		scale = scale or 1
    		local a = attach(part, CFrame.new(0, 0, 0), "PF_PAura")
    		ParticleAura:keep(a)
    		local e = emitter(a, {
    			Enabled = true, Rate = rate,
    			Texture = conf.tex, Color = seq,
    			Size = nseq(conf.s0 * scale, conf.s1 * scale, math.min(conf.s1, conf.s0 * 0.35) * scale),
    			Transparency = nseq(0, 0.05, 0.35, 1),
    			Lifetime = range(conf.lo, conf.hi),
    			Speed = range(conf.sp0 * scale, conf.sp1 * scale),
    			SpreadAngle = Vector2.new(180, 180),
    			Acceleration = Vector3.new(0, conf.up or 0.6, 0),
    			Drag = conf.drag or 1,
    			RotSpeed = range(-(conf.rot or 80), conf.rot or 80),
    			LightEmission = glow,
    			LockedToPart = false,
    		})

    		local e2 = emitter(a, {
    			Enabled = true, Rate = q(rate * 0.35, 1), Texture = TEX.Glint,
    			Color = cseq(WHITE, tint(color, 0.6)), Size = nseq(math.max(conf.s0, 0.12) * scale * 0.5, 0),
    			Lifetime = range(0.25, 0.5), Speed = range(conf.sp0 * scale * 0.7),
    			SpreadAngle = Vector2.new(180, 180), Transparency = nseq(0, 0.4, 1),
    			Rotation = range(-180, 180), RotSpeed = range(-140, 140), LightEmission = 1, ZOffset = 0.15,
    		})
    		ParticleAura:keep(e2)
    		es[#es + 1] = { e = e2, base = e2.Rate }
    		if conf.streak then
    			e.Orientation = Enum.ParticleOrientation.VelocityParallel
    			e.Squash = nseq(-2.2, -0.5, 0)
    			e.RotSpeed = range(0)
    		end
    		ParticleAura:keep(e)
    		es[#es + 1] = { e = e, base = rate }
    	end
    	for _, p in ipairs(anchors) do emitOn(p, 1) end

    	Tick.use("ParticleAura", function(dt, t)
    		for i, it in ipairs(es) do
    			if it.e.Parent then it.e.Rate = it.base * (1 + 0.3 * organicNoise(t * 0.7, i * 2.6)) end
    		end
    	end)
    end

    local function applyAsset(style, obj, color)

    	if type(obj) ~= "Instance" or not obj.Clone then
    		applyBuiltin(ParticleAura.assetFallback[style] or "Mana Dust")
    		return
    	end
    	color = color or Color3.fromRGB(160, 225, 255)
    	local partmap = {}
    	if Char.model then
    		for _, part in ipairs(Char.model:GetChildren()) do
    			if part:IsA("BasePart") then partmap[part.Name] = part end
    		end
    	end
    	local seq = cseq(WHITE, color, tint(color, -0.2))
    	local clone = obj:Clone()
    	for _, group in ipairs(clone:GetChildren()) do
    		local host = partmap[group.Name]
    		if not host and Char.root then host = Char.root end
    		if host then
    			for _, child in ipairs(group:GetChildren()) do
    				local copy = child:Clone()
    				copy.Name = "PF_ParticleAura"
    				copy.Parent = host
    				particleTint(copy, seq)
    				ParticleAura:keep(copy)
    			end
    		end
    	end
    	clone:Destroy()
    end

    local function particleSwapIn(style)
    	if not S.ParticleAura.Enabled or S.ParticleAura.Style ~= style or not alive() then return end
    	if not particleCache[style] then return end
    	local m = Modules.map["ParticleAura"]
    	if m and not m.built then return end
    	ParticleAura.build()
    end

    local pgen = 0
    function ParticleAura.build()
    	pgen = pgen + 1
    	local g = pgen
    	ParticleAura:clear()
    	if not S.ParticleAura.Enabled or not alive() then return end
    	ParticleAura.built = true
    	local style = S.ParticleAura.Style or "Starlight"
    	local color = S.ParticleAura.Color or Color3.fromRGB(160, 225, 255)
    	if ParticleAura.ids[style] then
    		local cached = (type(particleCache[style]) == "Instance") and particleCache[style] or nil
    		if cached then
    			applyAsset(style, cached, color)
    			return
    		end

    		local fb = ParticleAura.assetFallback[style] or "Mana Dust"
    		applyBuiltin(fb)
    		return
    	end
    	applyBuiltin(style)
    end
    function ParticleAura.stop()
    	pgen = pgen + 1
    	ParticleAura:clear()
    end
    ParticleAura.preloading = false
    local function preloadAssets()
    	if ParticleAura.preloading then return end
    	ParticleAura.preloading = true
    	local list = {}
    	for style, id in pairs(ParticleAura.ids) do list[#list + 1] = { style, id } end
    	for i, e in ipairs(list) do
    		task.spawn(function()
    			local ok, obj = pcall(function() return game:GetObjects(e[2])[1] end)
    			if ok and obj then
    				particleCache[e[1]] = obj
    				task.spawn(function() particleSwapIn(e[1]) end)
    			end
    		end)
    	end
    end
    task.spawn(function() task.wait(1.2) preloadAssets() end)
    local function particleAuraRebuildStyle()
    	if S.ParticleAura.Enabled then ParticleAura.build() end
    end

    local MotionEcho = defineModule("MotionEcho", {
    	Enabled = false,
    	Color   = Color3.fromRGB(120, 210, 255),
    	Lifetime = 0.75,
    	Interval = 0.08,
    	Transparency = 0.45,
    })
    MotionEcho.live = {}
    local lastPos, since, fadeAcc, totalParts = nil, 0, 0, 0
    local cloneBusy = false
    local HARD_CAP = 260
    local SOFT_CAP = 180

    local function rootPos()
    	local r = Char.root
    	if r and r.Parent then return r.Position end
    	return nil
    end

    local srcCache, srcCacheUntil = {}, 0
    local function echoSourceParts(now)
    	if now <= srcCacheUntil and #srcCache > 0 then return srcCache end
    	local out = {}
    	if alive() then
    		for _, part in ipairs(Char.model:GetDescendants()) do
    			if part:IsA("BasePart")
    				and part.Name ~= "HumanoidRootPart"
    				and part.Name ~= "ChineseHat"
    				and (part.Transparency or 0) < 0.9 then
    				out[#out + 1] = part
    			end
    		end
    	end
    	if #out == 0 and Char.root then out[1] = Char.root end
    	srcCache, srcCacheUntil = out, now + 0.25
    	return out
    end

    local function makeEcho()
    	local char = Char.model
    	if not char or not char.Parent then return end
    	local now = Tick.clock or os.clock()
    	local sources = echoSourceParts(now)
    	if #sources == 0 then return end
    	local base = clamp(S.MotionEcho.Transparency, 0, 0.92)
    	local color = S.MotionEcho.Color
    	local life = math.max(0.05, S.MotionEcho.Lifetime)

    	local snap = {}
    	for _, src in ipairs(sources) do
    		snap[#snap + 1] = { inst = src, cf = src.CFrame }
    	end
    	local ghost, partsCount = {}, 0
    	for i, s in ipairs(snap) do
    		local src = s.inst
    		local okC, copy = pcall(function() return src:Clone() end)
    		if okC and copy then
    			for _, ch in ipairs(copy:GetDescendants()) do
    				if ch:IsA("JointInstance") or ch:IsA("WeldConstraint") or ch:IsA("Constraint")
    					or ch:IsA("Attachment") or ch:IsA("ParticleEmitter") or ch:IsA("Trail")
    					or ch:IsA("Beam") or ch:IsA("Light") or ch:IsA("Sound") or ch:IsA("ForceField")
    					or ch:IsA("BaseScript") or ch:IsA("ModuleScript") or ch:IsA("Humanoid")
    					or ch:IsA("Animator") or ch:IsA("SurfaceAppearance") then
    					ch:Destroy()
    				end
    			end
    			for _, d in ipairs(copy:GetChildren()) do
    				if d:IsA("Decal") or d:IsA("Texture") then d:Destroy() end
    			end
    			copy.CFrame = s.cf
    			copy.Anchored = true
    			copy.CanCollide = false
    			copy.CanQuery = false
    			copy.CanTouch = false
    			copy.CastShadow = false
    			copy.Massless = true
    			copy.Locked = true
    			copy.TopSurface = Enum.SurfaceType.Smooth
    			copy.BottomSurface = Enum.SurfaceType.Smooth
    			if copy:FindFirstChildOfClass("SpecialMesh") == nil then
    				copy.Material = Enum.Material.Neon
    			end
    			copy.Color = color
    			copy.Transparency = base
    			copy.Parent = folder()
    			ghost[#ghost + 1] = copy
    			partsCount = partsCount + 1
    		end

    		if i % 6 == 0 then task.wait() end
    	end
    	if #ghost == 0 then return end
    	totalParts = totalParts + partsCount
    	MotionEcho.live[#MotionEcho.live + 1] = { parts = ghost, clock = 0, life = life, base = base, partsCount = partsCount }

    	while totalParts > HARD_CAP and #MotionEcho.live > 0 do
    		local e = MotionEcho.live[1]
    		totalParts = totalParts - (e.partsCount or 0)
    		table.remove(MotionEcho.live, 1)
    		for _, p in ipairs(e.parts) do pcall(function() p:Destroy() end) end
    	end
    end

    local function stepEcho(dt)
    	if not S.MotionEcho.Enabled then return end
    	local p = rootPos()
    	if not p then return end
    	local moving = false
    	if lastPos then moving = (p - lastPos).Magnitude > 0.006 end
    	lastPos = p
    	if moving then
    		since = since + dt
    		local iv = math.max(0.05, S.MotionEcho.Interval or 0.08)
    		if since >= iv and totalParts < SOFT_CAP and not cloneBusy then
    			since = 0
    			cloneBusy = true
    			task.spawn(function()
    				pcall(makeEcho)
    				cloneBusy = false
    			end)
    		end
    	else
    		since = 0
    	end
    	fadeAcc = fadeAcc + dt
    	if fadeAcc < 0.0333333 then return end
    	local delta = fadeAcc
    	fadeAcc = 0
    	local live = MotionEcho.live
    	local write = 0
    	for i = 1, #live do
    		local e = live[i]
    		e.clock = e.clock + delta
    		local a = math.min(e.clock / e.life, 1)
    		if a >= 1 then
    			for _, pp in ipairs(e.parts) do pcall(function() pp:Destroy() end) end
    			totalParts = totalParts - (e.partsCount or 0)
    			e.parts = {}
    		else
    			local v = e.base + a * (1 - e.base)
    			for _, pp in ipairs(e.parts) do pcall(function() pp.Transparency = v end) end
    			write = write + 1
    			live[write] = e
    		end
    	end
    	for i = #live, write + 1, -1 do live[i] = nil end
    end
    local function destroyLive()
    	for i = 1, #MotionEcho.live do
    		for _, p in ipairs(MotionEcho.live[i].parts) do pcall(function() p:Destroy() end) end
    		MotionEcho.live[i].parts = {}
    	end
    	MotionEcho.live = {}
    	lastPos, since, fadeAcc, totalParts = nil, 0, 0, 0
    	srcCache, srcCacheUntil = {}, 0
    end
    function MotionEcho.build()
    	MotionEcho:clear()
    	destroyLive()
    	if not S.MotionEcho.Enabled or not alive() then return end
    	lastPos = rootPos()
    	Tick.use("MotionEcho", stepEcho)
    	MotionEcho.built = true
    end
    function MotionEcho.stop()
    	Tick.drop("MotionEcho")
    	destroyLive()
    	MotionEcho:clear()
    end

    local ScreenFX = defineModule("ScreenFX", {
    	Enabled = false, Style = "Sparks", Color = Color3.fromRGB(140, 210, 255),
    	Rate = 26, Size = 1, Speed = 1, Lifetime = 1.6,
    })
    ScreenFX.Styles = { "Sparks", "Embers", "Snowfall", "Rain Streaks", "Glitch", "Speed Lines", "Bubbles", "Confetti", "Fireflies", "Sakura Petals" }

    ScreenFX.spec = {
    	["Sparks"]       = { tex = TEX.Glint,  sMin = 5,  sMax = 13, vx = 0.10, vy = 0.42, grav = 0.55, life = 1.1, stretch = 0,  rot = true, hue = 0.14, twk = 9 },
    	["Embers"]       = { tex = TEX.Mote,   sMin = 4,  sMax = 10, vx = 0.05, vy = 0.10, grav = -0.02, life = 3.0, stretch = 0, sway = 0.05, hue = 0.08, twk = 7, fadeIn = true },
    	["Snowfall"]     = { tex = TEX.Star,   sMin = 5,  sMax = 13, vx = 0.05, vy = 0.07, grav = 0.03, life = 5.0, stretch = 0, sway = 0.09, down = true, rot = true, fadeIn = true },
    	["Rain Streaks"] = { tex = TEX.Drop,   sMin = 2,  sMax = 4,  vx = 0.14, vy = 0.95, grav = 0.2,  life = 0.7, stretch = 26, hue = 0.05 },
    	["Glitch"]       = { tex = TEX.Scratch,sMin = 22, sMax = 90, vx = 0.30, vy = 0.0,  grav = 0.0,  life = 0.22, stretch = 0, ar = 0.10, hue = 0.5, twk = 16 },
    	["Speed Lines"]  = { tex = TEX.Trace,  sMin = 30, sMax = 70, vx = 0.0,  vy = 0.0,  grav = 0.0,  life = 0.35, stretch = 0, radial = true },
    	["Bubbles"]      = { tex = TEX.Circle, sMin = 8,  sMax = 26, vx = 0.03, vy = 0.10, grav = -0.04, life = 3.2, sway = 0.06, fadeIn = true, grow = 0.35 },
    	["Confetti"]     = { tex = TEX.Scratch,sMin = 6,  sMax = 12, vx = 0.08, vy = 0.16, grav = 0.12, life = 3.4, sway = 0.10, down = true, rot = true, hue = 0.55, ar = 0.6, arRand = 0.7 },
    	["Fireflies"]    = { tex = TEX.Mote,   sMin = 4,  sMax = 9,  vx = 0.06, vy = 0.04, grav = 0.0,  life = 4.2, sway = 0.12, hue = 0.2, twk = 2.2, fadeIn = true, grow = 0.5 },
    	["Sakura Petals"]= { tex = TEX.Heart,  sMin = 8,  sMax = 16, vx = 0.07, vy = 0.10, grav = 0.02, life = 4.4, sway = 0.13, down = true, rot = true, hue = 0.06, ar = 0.8, fadeIn = true },
    }

    ScreenFX.parts = {}

    ScreenFX.spec = {
    	["Sparks"]       = { tex = TEX.Glint, sMin = 5,  sMax = 13, vx = 0.10, vy = 0.42, grav = 0.55, life = 1.1, stretch = 0,   rot = true },
    	["Embers"]       = { tex = TEX.Mote,  sMin = 4,  sMax = 10, vx = 0.05, vy = 0.10, grav = -0.02, life = 3.0, stretch = 0,   sway = 0.05 },
    	["Snowfall"]     = { tex = TEX.Star,  sMin = 5,  sMax = 13, vx = 0.05, vy = 0.07, grav = 0.03, life = 5.0, stretch = 0,   sway = 0.09, down = true },
    	["Rain Streaks"] = { tex = TEX.Drop,  sMin = 2,  sMax = 4,  vx = 0.14, vy = 0.95, grav = 0.2,  life = 0.7, stretch = 26 },
    	["Glitch"]       = { tex = TEX.Scratch,sMin = 22, sMax = 90, vx = 0.30, vy = 0.0,  grav = 0.0,  life = 0.22, stretch = 0, ar = 0.10 },
    	["Speed Lines"]  = { tex = TEX.Trace, sMin = 30, sMax = 70, vx = 0.0,  vy = 0.0,  grav = 0.0,  life = 0.35, stretch = 0, radial = true },
    }

    ScreenFX.panel = { gui = nil, frame = nil }

    function ScreenFX.screenDestroy()
    	local pn = ScreenFX.panel
    	if pn.gui then pcall(function() pn.gui:Destroy() end) end
    	pn.gui, pn.frame = nil, nil
    	ScreenFX.parts = {}
    end

    function ScreenFX.build()
    	ScreenFX:clear()
    	ScreenFX.screenDestroy()
    	if not S.ScreenFX.Enabled then return end
    	local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    	if not pg then return end
    	local gui = Instance.new("ScreenGui")
    	gui.Name = "PF_ScreenFX"
    	gui.IgnoreGuiInset = true
    	gui.ResetOnSpawn = false
    	pcall(function() gui.DisplayOrder = 40 end)
    	gui.Parent = pg
    	local fr = Instance.new("Frame")
    	fr.Name = "FX"
    	fr.BackgroundTransparency = 1
    	fr.Size = UDim2.new(1, 0, 1, 0)
    	fr.ClipsDescendants = true
    	fr.Parent = gui
    	ScreenFX.panel.gui, ScreenFX.panel.frame = gui, fr
    	Tick.use("ScreenFX", ScreenFX.step)
    	ScreenFX.built = true
    end

    function ScreenFX.stop()
    	Tick.drop("ScreenFX")
    	ScreenFX:clear()
    	ScreenFX.screenDestroy()
    end

    ScreenFX.acc = 0
    function ScreenFX.spawnOne(spec, cfg, t)
    	local img = Instance.new("ImageLabel")
    	img.Name = "PF_2D"
    	img.BackgroundTransparency = 1
    	img.AnchorPoint = Vector2.new(0.5, 0.5)
    	img.Image = spec.tex
    	img.ZIndex = 5

    	local col = cfg.Color
    	if spec.hue then
    		local h, s, v = col:ToHSV()
    		if s < 0.02 then h = math.random() end
    		col = Color3.fromHSV((h + (math.random() - 0.5) * 2 * spec.hue + 1) % 1, math.max(s, 0.35), v)
    	end
    	img.ImageColor3 = col
    	local sz = (spec.sMin + math.random() * (spec.sMax - spec.sMin)) * (cfg.Size or 1)
    	local p = { img = img, age = 0,
    		life = spec.life * (0.6 + math.random() * 0.8) * ((cfg.Lifetime or 1.6) / 1.6) / (cfg.Speed or 1),
    		grav = spec.grav * (cfg.Speed or 1), spec = spec, sway = spec.sway or 0, ph = math.random() * TAU,
    		twk = spec.twk and (spec.twk * (0.7 + math.random() * 0.6)) or nil,
    		growK = spec.grow and (1 + (math.random() - 0.5) * spec.grow) or nil }
    	local ar = spec.ar or 1
    	if spec.arRand then ar = ar * (1 + (math.random() - 0.5) * spec.arRand) end
    	if spec.radial then

    		local ang = math.random() * TAU
    		p.x, p.y = 0.5, 0.5
    		local sp = (0.7 + math.random() * 0.8) * (cfg.Speed or 1)
    		p.vx, p.vy = math.cos(ang) * sp, math.sin(ang) * sp * 0.55
    		p.len = sz * 6
    		p.rot = math.deg(math.atan2(p.vy, p.vx)) - 90
    		img.Size = UDim2.fromOffset(3, p.len)
    	elseif spec.stretch and spec.stretch > 0 then
    		p.x, p.y = math.random(), -0.05
    		p.vx = (math.random() - 0.5) * 2 * spec.vx * (cfg.Speed or 1)
    		p.vy = spec.vy * (0.7 + math.random() * 0.6) * (cfg.Speed or 1)
    		img.Size = UDim2.fromOffset(2, sz + spec.stretch)
    		p.rot = math.deg(math.atan2(p.vy, p.vx)) - 90
    	else
    		p.x, p.y = math.random(), 0.15 + math.random() * 0.85
    		p.vx = (math.random() - 0.5) * 2 * spec.vx * (cfg.Speed or 1)
    		p.vy = spec.vy * (0.6 + math.random() * 0.8) * (spec.down and 1 or -1) * (cfg.Speed or 1)
    		p.baseW, p.baseH = sz, sz * ar
    		img.Size = UDim2.fromOffset(sz, sz * ar)
    		if spec.rot then
    			p.rot = math.random() * 360
    			p.rotSp = (math.random() - 0.5) * 160
    		end
    	end
    	img.Rotation = p.rot or 0
    	img.Position = UDim2.fromScale(p.x, p.y)
    	img.Parent = ScreenFX.panel.frame
    	ScreenFX.parts[#ScreenFX.parts + 1] = p
    end

    function ScreenFX.step(dt, t)
    	if not S.ScreenFX.Enabled then return end
    	if not ScreenFX.panel.frame or not ScreenFX.panel.frame.Parent then return end
    	local cfg = S.ScreenFX
    	local spec = ScreenFX.spec[cfg.Style] or ScreenFX.spec["Sparks"]
    	local cap = q(120, 48)

    	local acc = ScreenFX.acc + dt * (cfg.Rate or 26) * QUALITY
    	ScreenFX.acc = acc
    	if acc >= 1 and #ScreenFX.parts < cap then
    		local n = math.min(math.floor(acc), cap - #ScreenFX.parts)
    		ScreenFX.acc = acc - n
    		for _ = 1, n do ScreenFX.spawnOne(spec, cfg, t) end
    	end

    	local list = ScreenFX.parts
    	local w = 1
    	for i = 1, #list do
    		local p = list[i]
    		p.age = p.age + dt
    		local a = p.age / p.life
    		if a >= 1 then
    			pcall(function() p.img:Destroy() end)
    		else
    			p.vy = p.vy + p.grav * dt
    			p.x = p.x + p.vx * dt
    			p.y = p.y + p.vy * dt
    			if p.sway > 0 then p.x = p.x + math.sin(p.age * 1.8 + p.ph) * p.sway * dt end
    			p.img.Position = UDim2.fromScale(p.x, p.y)
    			if p.rotSp then p.img.Rotation = (p.rot or 0) + p.age * p.rotSp end

    			local tr = a * a
    			if spec.fadeIn and a < 0.2 then tr = (0.2 - a) * 2.5 end

    			if p.twk then
    				local tw = 0.5 + 0.5 * math.sin(p.age * p.twk + p.ph)
    				tr = tr + (1 - tr) * (1 - tw) * 0.45
    			end
    			p.img.ImageTransparency = clamp(tr, 0, 1)

    			if p.growK then
    				local k = 1 + a * p.growK
    				p.img.Size = UDim2.fromOffset((p.baseW or 8) * k, (p.baseH or 8) * k)
    			end
    			list[w] = p
    			w = w + 1
    		end
    	end
    	for i = #list, w, -1 do list[i] = nil end
    end

    local Sky = { current = "Default", saved = nil, objects = {}, stashed = {}, cycle = { on = false, speed = 1 }, smooth = true, weather = { kind = "None", cells = {}, emitters = {}, intensity = 1, wind = 0 } }
    local skyTweenToken = 0
    local LIGHT_KEYS = { "ClockTime", "Brightness", "Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom", "FogColor", "FogStart", "FogEnd", "ExposureCompensation", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "GlobalShadows" }
    local STASH = { "Sky", "Atmosphere", "BloomEffect", "ColorCorrectionEffect", "SunRaysEffect", "BlurEffect", "DepthOfFieldEffect", "Clouds" }

    local function P(r, g, b) return Color3.fromRGB(r, g, b) end
    Sky.Presets = {
    	["Violet Hour"] = {
    		Skybox = "Purple Nebula", Clouds = "Sunset",
    		Sky = { Stars = 4000, Sun = 18, Moon = 8, Bodies = true, MoonTex = 4547507884 },
    		Lighting = { ClockTime = 18.2, Brightness = 2.0, Ambient = P(50, 30, 70), OutdoorAmbient = P(120, 80, 150), ColorShift_Top = P(255, 150, 200), ColorShift_Bottom = P(60, 30, 110), FogColor = P(170, 110, 190), FogEnd = 1800, ExposureCompensation = 0.15 },
    		Atmosphere = { Density = 0.4, Offset = 0.35, Color = P(230, 150, 230), Decay = P(90, 40, 140), Glare = 1.0, Haze = 2.2 },
    		Bloom = { Intensity = 1.2, Size = 32, Threshold = 0.8 },
    		Color = { Contrast = 0.15, Saturation = 0.25, TintColor = P(255, 235, 250) },
    	},
    	["Starfield"] = {
    		Skybox = "Galaxy",
    		Sky = { Stars = 8000, Sun = 0, Moon = 6, Bodies = true, MoonTex = 4547507884 },
    		Lighting = { ClockTime = 0.2, Brightness = 0.9, Ambient = P(12, 14, 30), OutdoorAmbient = P(30, 34, 70), ColorShift_Top = P(90, 110, 220), ColorShift_Bottom = P(5, 5, 20), FogColor = P(15, 18, 45), FogStart = 100, FogEnd = 3000, ExposureCompensation = 0.1 },
    		Atmosphere = { Density = 0.25, Offset = 0.05, Color = P(90, 110, 220), Decay = P(10, 10, 40), Glare = 0.2, Haze = 1.2 },
    		Bloom = { Intensity = 1.5, Size = 40, Threshold = 0.9 },
    		Color = { Contrast = 0.2, Saturation = 0.1, TintColor = P(225, 230, 255) },
    	},
    	["Amber Storm"] = {
    		Skybox = "Setting Sun", Clouds = "Storm",
    		Sky = { Stars = 0, Sun = 40, Moon = 0, Bodies = true, SunTex = 6196665106 },
    		Lighting = { ClockTime = 16.8, Brightness = 2.6, Ambient = P(90, 60, 30), OutdoorAmbient = P(170, 120, 60), ColorShift_Top = P(255, 190, 90), ColorShift_Bottom = P(120, 70, 20), FogColor = P(210, 160, 90), FogStart = 30, FogEnd = 500, ExposureCompensation = 0.3 },
    		Atmosphere = { Density = 0.6, Offset = 0.6, Color = P(240, 180, 100), Decay = P(140, 80, 30), Glare = 1.8, Haze = 3.0 },
    		Bloom = { Intensity = 1.4, Size = 36, Threshold = 0.75 },
    		Rays = { Intensity = 0.3, Spread = 0.9 },
    	},
    	["Abyssal"] = {
    		Skybox = "Neptune",
    		Sky = { Stars = 200, Sun = 0, Moon = 0, Bodies = false },
    		Lighting = { ClockTime = 1, Brightness = 0.8, Ambient = P(5, 20, 35), OutdoorAmbient = P(15, 50, 80), ColorShift_Top = P(20, 90, 140), ColorShift_Bottom = P(0, 10, 25), FogColor = P(6, 30, 50), FogStart = 0, FogEnd = 220, ExposureCompensation = 0.1 },
    		Atmosphere = { Density = 0.7, Offset = 0.0, Color = P(20, 90, 140), Decay = P(0, 10, 30), Glare = 0, Haze = 3.5 },
    		Color = { Contrast = 0.1, Saturation = -0.1, TintColor = P(190, 230, 255) },
    		Bloom = { Intensity = 1.0, Size = 24, Threshold = 0.9 },
    	},
    	["Acid Rain"] = {
    		Clouds = "Overcast",
    		Sky = { Stars = 0, Sun = 0, Moon = 12, Bodies = true },
    		Lighting = { ClockTime = 20, Brightness = 1.4, Ambient = P(30, 50, 20), OutdoorAmbient = P(70, 120, 40), ColorShift_Top = P(150, 255, 80), ColorShift_Bottom = P(20, 40, 10), FogColor = P(80, 130, 50), FogStart = 20, FogEnd = 400, ExposureCompensation = 0.15 },
    		Atmosphere = { Density = 0.55, Offset = 0.2, Color = P(150, 230, 90), Decay = P(30, 60, 20), Glare = 0.4, Haze = 2.6 },
    		Color = { Contrast = 0.2, Saturation = 0.3, TintColor = P(225, 255, 210) },
    		Bloom = { Intensity = 1.1, Size = 30, Threshold = 0.85 },
    	},
    	["Crimson Eclipse"] = {
    		Skybox = "Redshift",
    		Sky = { Stars = 1500, Sun = 22, Moon = 22, Bodies = true, MoonTex = 4547507884 },
    		Lighting = { ClockTime = 6.1, Brightness = 1.3, Ambient = P(60, 10, 15), OutdoorAmbient = P(130, 30, 40), ColorShift_Top = P(255, 60, 60), ColorShift_Bottom = P(40, 0, 10), FogColor = P(120, 20, 30), FogStart = 40, FogEnd = 700, ExposureCompensation = 0.2 },
    		Atmosphere = { Density = 0.45, Offset = 0.3, Color = P(255, 80, 80), Decay = P(80, 10, 20), Glare = 1.2, Haze = 2.4 },
    		Color = { Contrast = 0.3, Saturation = 0.2, TintColor = P(255, 220, 220) },
    		Bloom = { Intensity = 1.6, Size = 40, Threshold = 0.7 },
    	},
    	["Arctic Noon"] = {
    		Skybox = "Fade Blue", Clouds = "Light",
    		Sky = { Stars = 0, Sun = 16, Moon = 0, Bodies = true },
    		Lighting = { ClockTime = 12.5, Brightness = 3.2, Ambient = P(120, 140, 170), OutdoorAmbient = P(200, 215, 240), ColorShift_Top = P(255, 255, 255), ColorShift_Bottom = P(180, 200, 230), FogColor = P(225, 235, 250), FogStart = 80, FogEnd = 1400, ExposureCompensation = 0.05 },
    		Atmosphere = { Density = 0.3, Offset = 0.1, Color = P(230, 240, 255), Decay = P(150, 170, 200), Glare = 0.5, Haze = 1.5 },
    		Color = { Contrast = 0.05, Saturation = -0.3, TintColor = P(235, 245, 255) },
    		Bloom = { Intensity = 0.6, Size = 20, Threshold = 0.95 },
    	},
    	["Synthwave"] = {
    		Skybox = "Pink Daylight",
    		Sky = { Stars = 3000, Sun = 30, Moon = 0, Bodies = true, SunTex = 6196665106 },
    		Lighting = { ClockTime = 18.8, Brightness = 2.2, Ambient = P(60, 10, 90), OutdoorAmbient = P(160, 40, 170), ColorShift_Top = P(255, 60, 180), ColorShift_Bottom = P(20, 0, 80), FogColor = P(190, 40, 150), FogEnd = 1300, ExposureCompensation = 0.25 },
    		Atmosphere = { Density = 0.42, Offset = 0.55, Color = P(255, 90, 190), Decay = P(50, 0, 110), Glare = 1.5, Haze = 2.5 },
    		Bloom = { Intensity = 2.0, Size = 50, Threshold = 0.55 },
    		Color = { Contrast = 0.3, Saturation = 0.5, TintColor = P(255, 220, 250) },
    	},
    	["Honey Dawn"] = {
    		Skybox = "Morning Glow", Clouds = "Light",
    		Sky = { Stars = 300, Sun = 24, Moon = 0, Bodies = true, SunTex = 6196665106 },
    		Lighting = { ClockTime = 6.6, Brightness = 2.4, Ambient = P(90, 70, 50), OutdoorAmbient = P(200, 160, 110), ColorShift_Top = P(255, 220, 150), ColorShift_Bottom = P(150, 100, 60), FogColor = P(240, 200, 150), FogStart = 50, FogEnd = 1200, ExposureCompensation = 0.2 },
    		Atmosphere = { Density = 0.38, Offset = 0.45, Color = P(255, 210, 150), Decay = P(150, 100, 60), Glare = 1.3, Haze = 2.0 },
    		Bloom = { Intensity = 1.2, Size = 34, Threshold = 0.8 },
    		Rays = { Intensity = 0.2, Spread = 0.7 },
    		Color = { Contrast = 0.1, Saturation = 0.15, TintColor = P(255, 245, 225) },
    	},
    	["Cinder Sky"] = {
    		Clouds = "Storm",
    		Sky = { Stars = 0, Sun = 10, Moon = 0, Bodies = true },
    		Lighting = { ClockTime = 14, Brightness = 1.0, Ambient = P(40, 30, 30), OutdoorAmbient = P(90, 70, 65), ColorShift_Top = P(150, 90, 70), ColorShift_Bottom = P(30, 20, 20), FogColor = P(70, 50, 45), FogStart = 10, FogEnd = 350, ExposureCompensation = 0 },
    		Atmosphere = { Density = 0.65, Offset = 0.1, Color = P(120, 80, 70), Decay = P(40, 25, 20), Glare = 0.3, Haze = 3.2 },
    		Color = { Contrast = 0.15, Saturation = -0.35, TintColor = P(240, 225, 220) },
    	},
    	["Cherry Night"] = {
    		Skybox = "Aesthetic Night",
    		Sky = { Stars = 5000, Sun = 0, Moon = 16, Bodies = true, MoonTex = 4547507884 },
    		Lighting = { ClockTime = 21.5, Brightness = 1.4, Ambient = P(70, 30, 50), OutdoorAmbient = P(150, 80, 120), ColorShift_Top = P(255, 170, 210), ColorShift_Bottom = P(60, 20, 50), FogColor = P(200, 130, 170), FogStart = 60, FogEnd = 1100, ExposureCompensation = 0.15 },
    		Atmosphere = { Density = 0.36, Offset = 0.3, Color = P(255, 180, 220), Decay = P(100, 40, 90), Glare = 0.7, Haze = 2.0 },
    		Bloom = { Intensity = 1.3, Size = 36, Threshold = 0.8 },
    		Color = { Contrast = 0.1, Saturation = 0.2, TintColor = P(255, 235, 245) },
    	},
    	["Jade Forest"] = {
    		Skybox = "Elegant Morning", Clouds = "Light",
    		Sky = { Stars = 0, Sun = 14, Moon = 0, Bodies = true },
    		Lighting = { ClockTime = 10, Brightness = 2.2, Ambient = P(30, 70, 40), OutdoorAmbient = P(80, 160, 100), ColorShift_Top = P(200, 255, 200), ColorShift_Bottom = P(20, 60, 30), FogColor = P(120, 190, 140), FogStart = 40, FogEnd = 700, ExposureCompensation = 0.1 },
    		Atmosphere = { Density = 0.45, Offset = 0.25, Color = P(160, 230, 170), Decay = P(30, 80, 50), Glare = 0.6, Haze = 2.2 },
    		Rays = { Intensity = 0.25, Spread = 0.6 },
    		Color = { Contrast = 0.1, Saturation = 0.25, TintColor = P(235, 255, 235) },
    	},
    	["Ultraviolet Grid"] = {
    		Skybox = "Purple Nebula",
    		Sky = { Stars = 6000, Sun = 0, Moon = 0, Bodies = false },
    		Lighting = { ClockTime = 0, Brightness = 1.6, Ambient = P(20, 0, 60), OutdoorAmbient = P(70, 0, 160), ColorShift_Top = P(140, 0, 255), ColorShift_Bottom = P(0, 0, 30), FogColor = P(60, 0, 140), FogStart = 30, FogEnd = 900, ExposureCompensation = 0.3 },
    		Atmosphere = { Density = 0.4, Offset = 0.2, Color = P(150, 40, 255), Decay = P(20, 0, 60), Glare = 0.8, Haze = 2.0 },
    		Bloom = { Intensity = 2.2, Size = 56, Threshold = 0.5 },
    		Color = { Contrast = 0.35, Saturation = 0.4, TintColor = P(235, 220, 255) },
    	},
    	["Sandglass"] = {
    		Skybox = "Morning",
    		Sky = { Stars = 0, Sun = 28, Moon = 0, Bodies = true, SunTex = 6196665106 },
    		Lighting = { ClockTime = 13.5, Brightness = 3.0, Ambient = P(120, 100, 60), OutdoorAmbient = P(220, 190, 130), ColorShift_Top = P(255, 240, 200), ColorShift_Bottom = P(160, 130, 80), FogColor = P(235, 210, 160), FogStart = 30, FogEnd = 600, ExposureCompensation = 0.25 },
    		Atmosphere = { Density = 0.5, Offset = 0.7, Color = P(240, 210, 150), Decay = P(170, 130, 80), Glare = 2.0, Haze = 3.0 },
    		Color = { Contrast = 0.1, Saturation = -0.1, TintColor = P(255, 245, 225) },
    	},
    	["Blackout"] = {
    		Sky = { Stars = 0, Sun = 0, Moon = 0, Bodies = false },
    		Lighting = { ClockTime = 0, Brightness = 0.4, GlobalShadows = true, Ambient = P(6, 6, 10), OutdoorAmbient = P(10, 10, 16), ColorShift_Top = BLACK, ColorShift_Bottom = BLACK, FogColor = BLACK, FogStart = 0, FogEnd = 600, ExposureCompensation = -0.15 },
    		Color = { Contrast = 0.2, Saturation = -0.2, TintColor = P(230, 230, 245) },
    	},
    	["Golden Evening"] = {

    		Skybox = "Evening", Clouds = "Sunset",
    		Sky = { Stars = 500, Sun = 24, Moon = 11, Bodies = true, SunTex = 6196665106 },
    		Lighting = { ClockTime = 17, Brightness = 2.5, Ambient = P(156, 136, 176), OutdoorAmbient = P(156, 136, 176), ColorShift_Top = P(255, 210, 160), ColorShift_Bottom = P(120, 90, 130), FogColor = P(200, 170, 180), FogStart = 100, FogEnd = 2000, ExposureCompensation = 0.1, EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1 },
    		Atmosphere = { Density = 0.272, Offset = 0.25, Color = P(199, 170, 107), Decay = P(85, 78, 54), Glare = 0.8, Haze = 1 },
    		Bloom = { Intensity = 0.8, Size = 24, Threshold = 1.2 },
    		Rays = { Intensity = 0.12, Spread = 0.5 },
    	},
    	["Candlelit Indoor"] = {

    		Skybox = "Indoor Studio",
    		Sky = { Stars = 0, Sun = 8, Moon = 0, Bodies = false },
    		Lighting = { ClockTime = 15.6, Brightness = 1.2, Ambient = P(83, 70, 57), OutdoorAmbient = P(90, 80, 70), ColorShift_Top = P(255, 202, 156), ColorShift_Bottom = P(60, 40, 30), FogColor = P(40, 30, 25), FogStart = 50, FogEnd = 900, ExposureCompensation = 0.2 },
    		Atmosphere = { Density = 0.5, Offset = 0.1, Color = P(255, 202, 156), Decay = P(60, 40, 30), Glare = 0.2, Haze = 1.5 },
    		Rays = { Intensity = 0.023, Spread = 0.266 },
    		Color = { Contrast = 0.1, Saturation = 0.05, TintColor = P(255, 240, 225) },
    	},
    	["Overcast Rain"] = {
    		Clouds = "Storm",
    		Sky = { Stars = 0, Sun = 0, Moon = 0, Bodies = false },
    		Lighting = { ClockTime = 13, Brightness = 1.2, Ambient = P(70, 78, 90), OutdoorAmbient = P(110, 120, 135), ColorShift_Top = P(150, 160, 175), ColorShift_Bottom = P(60, 65, 75), FogColor = P(130, 140, 155), FogStart = 30, FogEnd = 450, ExposureCompensation = -0.05 },
    		Atmosphere = { Density = 0.55, Offset = 0.1, Color = P(160, 170, 185), Decay = P(60, 65, 80), Glare = 0, Haze = 2.4 },
    		Color = { Contrast = 0.05, Saturation = -0.4, TintColor = P(220, 230, 245) },
    	},
    	["Moonlit Clear"] = {
    		Skybox = "Starry Night",
    		Sky = { Stars = 6000, Sun = 0, Moon = 18, Bodies = true, MoonTex = 4547507884 },
    		Lighting = { ClockTime = 23.5, Brightness = 1.1, Ambient = P(30, 38, 60), OutdoorAmbient = P(60, 75, 115), ColorShift_Top = P(140, 170, 255), ColorShift_Bottom = P(10, 15, 40), FogColor = P(20, 28, 55), FogStart = 150, FogEnd = 2500, ExposureCompensation = 0.1 },
    		Atmosphere = { Density = 0.3, Offset = 0.15, Color = P(120, 150, 230), Decay = P(20, 25, 60), Glare = 0.3, Haze = 1.4 },
    		Bloom = { Intensity = 1.0, Size = 28, Threshold = 0.95 },
    		Color = { Contrast = 0.15, Saturation = -0.15, TintColor = P(215, 225, 255) },
    	},
    }
    Sky.Order = { "Default", "Violet Hour", "Starfield", "Amber Storm", "Abyssal", "Acid Rain", "Crimson Eclipse", "Arctic Noon", "Synthwave", "Honey Dawn", "Cinder Sky", "Cherry Night", "Jade Forest", "Ultraviolet Grid", "Sandglass", "Blackout", "Golden Evening", "Candlelit Indoor", "Overcast Rain", "Moonlit Clear" }
    Sky.WeatherOrder = { "None", "Snow", "Rain", "Thunderstorm", "Embers", "Petals", "Leaves", "Fireflies", "Ash", "Pollen", "Meteor Shower", "Bubbles", "Sandstorm", "Aurora", "Fairy Dust" }

    local function sb(bk, dn, ft, lf, rt, up) return { bk, dn, ft, lf, rt, up } end
    Sky.Skyboxes = {
    	["Plain Sky (classic)"] = { "rbxasset://sky/null_plainsky512_bk.jpg", "rbxasset://sky/null_plainsky512_dn.jpg", "rbxasset://sky/null_plainsky512_ft.jpg", "rbxasset://sky/null_plainsky512_lf.jpg", "rbxasset://sky/null_plainsky512_rt.jpg", "rbxasset://sky/null_plainsky512_up.jpg" },
    	["Galaxy"]          = sb(92464172, 92464250, 92464217, 92464234, 92464189, 92464157),
    	["Purple Nebula"]   = sb(159454299, 159454296, 159454293, 159454286, 159454300, 159454288),
    	["Night Sky"]       = sb(12064107, 12064152, 12064121, 12063984, 12064115, 12064131),
    	["Starry Night"]    = sb(15536110634, 15536112543, 15536116141, 15536114370, 15536118762, 15536117282),
    	["Aesthetic Night"] = sb(1045964490, 1045964368, 1045964655, 1045964655, 1045964655, 1045962969),
    	["Pink Daylight"]   = sb(271042516, 271077243, 271042556, 271042310, 271042467, 271077958),
    	["Morning Glow"]    = sb(1417494030, 1417494146, 1417494253, 1417494402, 1417494499, 1417494643),
    	["Elegant Morning"] = sb(153767241, 153767216, 153767266, 153767200, 153767231, 153767288),
    	["Morning"]         = sb(6444884337, 6444884785, 6444884337, 6444884337, 6444884337, 6412503613),
    	["Fade Blue"]       = sb(153695414, 153695352, 153695452, 153695320, 153695383, 153695471),
    	["Setting Sun"]     = sb(626460377, 626460216, 626460513, 626473032, 626458639, 626460625),
    	["Evening"]         = sb(16136021536, 16136025360, 16136021536, 16136021536, 16136021536, 16136023362),
    	["Neptune"]         = sb(218955819, 218953419, 218954524, 218958493, 218957134, 218950090),
    	["Redshift"]        = sb(401664839, 401664862, 401664960, 401664881, 401664901, 401664936),
    	["Red Classic"]     = sb(1012890, 1012891, 1012887, 1012889, 1012888, 1014449),
    	["Indoor Studio"]   = sb(162001887, 161998893, 162001897, 162001904, 162001919, 162001926),
    }
    Sky.SkyboxOrder = { "Preset default", "Game's own", "Plain Sky (classic)", "Galaxy", "Purple Nebula", "Night Sky", "Starry Night", "Aesthetic Night", "Pink Daylight", "Morning Glow", "Elegant Morning", "Morning", "Fade Blue", "Setting Sun", "Evening", "Neptune", "Redshift", "Red Classic", "Indoor Studio" }

    Sky.CloudSpecs = {
    	["Light"]    = { Cover = 0.45, Density = 0.12, Color = P(255, 255, 255) },
    	["Overcast"] = { Cover = 0.8,  Density = 0.25, Color = P(215, 220, 230) },
    	["Storm"]    = { Cover = 0.95, Density = 0.32, Color = P(110, 115, 130) },
    	["Sunset"]   = { Cover = 0.6,  Density = 0.18, Color = P(255, 190, 170) },
    	["Night"]    = { Cover = 0.5,  Density = 0.15, Color = P(120, 130, 170) },
    }
    Sky.CloudOrder = { "Preset default", "Off", "Light", "Overcast", "Storm", "Sunset", "Night" }

    Sky.Filters = {
    	["Warm"]     = { Brightness = 0.02, Contrast = 0.08, Saturation = 0.1,  TintColor = P(255, 235, 210) },
    	["Cool"]     = { Brightness = 0.0,  Contrast = 0.08, Saturation = 0.05, TintColor = P(210, 230, 255) },
    	["Vintage"]  = { Brightness = 0.03, Contrast = -0.05, Saturation = -0.35, TintColor = P(255, 230, 190) },
    	["Noir"]     = { Brightness = -0.02, Contrast = 0.35, Saturation = -1,  TintColor = P(235, 235, 245) },
    	["Vivid"]    = { Brightness = 0.02, Contrast = 0.2,  Saturation = 0.55, TintColor = P(255, 255, 255), Bloom = { Intensity = 0.6, Size = 24, Threshold = 1.1 } },
    	["Dreamy"]   = { Brightness = 0.06, Contrast = -0.15, Saturation = 0.15, TintColor = P(255, 240, 250), Bloom = { Intensity = 1.6, Size = 56, Threshold = 0.7 } },
    	["Cyber"]    = { Brightness = 0.0,  Contrast = 0.3,  Saturation = 0.35, TintColor = P(200, 230, 255), Bloom = { Intensity = 1.2, Size = 40, Threshold = 0.85 } },
    	["Sepia"]    = { Brightness = 0.02, Contrast = 0.05, Saturation = -0.9, TintColor = P(255, 220, 170) },
    	["Frost"]    = { Brightness = 0.05, Contrast = 0.05, Saturation = -0.25, TintColor = P(215, 240, 255) },
    	["Toxic"]    = { Brightness = 0.0,  Contrast = 0.15, Saturation = 0.3,  TintColor = P(200, 255, 190) },
    	["Dusk"]     = { Brightness = -0.06, Contrast = 0.12, Saturation = -0.1, TintColor = P(230, 200, 255) },
    }
    Sky.FilterOrder = { "None", "Warm", "Cool", "Vintage", "Noir", "Vivid", "Dreamy", "Cyber", "Sepia", "Frost", "Toxic", "Dusk" }

    function Sky.save()
    	if Sky.saved then return end
    	local saved = { light = {} }
    	for _, k in ipairs(LIGHT_KEYS) do pcall(function() saved.light[k] = Lighting[k] end) end
    	Sky.saved = saved
    	Sky.stashed = {}
    	local function stashFrom(container)
    		for _, ch in ipairs(container:GetChildren()) do
    			local keep = false
    			for _, cls in ipairs(STASH) do if ch:IsA(cls) then keep = true end end
    			if keep and ch.Name:sub(1, 3) ~= "PF_" then
    				table.insert(Sky.stashed, { inst = ch, parent = container })
    				pcall(function() ch.Parent = nil end)
    			end
    		end
    	end
    	stashFrom(Lighting)
    	stashFrom(Terrain)
    end
    local function killSkyObjects()
    	for _, o in ipairs(Sky.objects) do pcall(function() o:Destroy() end) end
    	Sky.objects = {}
    	Sky.skyObj = nil
    end

    local function stashAll()
    	for _, st in ipairs(Sky.stashed) do pcall(function() st.inst.Parent = nil end) end
    end
    function Sky.restore()
    	skyTweenToken = skyTweenToken + 1
    	killSkyObjects()
    	if Sky.saved then
    		for k, v in pairs(Sky.saved.light) do pcall(function() Lighting[k] = v end) end
    		for _, st in ipairs(Sky.stashed) do pcall(function() st.inst.Parent = st.parent end) end
    		Sky.saved, Sky.stashed = nil, {}
    	end
    	Sky.current = "Default"
    end

    local function mkFX(cls, props, name, parent)
    	local ok, inst = pcall(Instance.new, cls)
    	if not ok then return nil end
    	inst.Name = name or ("PF_" .. cls)
    	applyProps(inst, props)
    	inst.Parent = parent or Lighting
    	table.insert(Sky.objects, inst)
    	return inst
    end

    local function applyLightingTable(tbl, smooth)
    	skyTweenToken = skyTweenToken + 1
    	local my = skyTweenToken
    	if not smooth then
    		for k, v in pairs(tbl) do pcall(function() Lighting[k] = v end) end
    		return
    	end
    	local from = {}
    	for k in pairs(tbl) do pcall(function() from[k] = Lighting[k] end) end
    	Timeline.add(1.2, function(a)
    		if my ~= skyTweenToken then return end
    		local e = easeInOut(a)
    		for k, v in pairs(tbl) do
    			local f = from[k]
    			pcall(function()
    				if typeof(v) == "Color3" and typeof(f) == "Color3" then Lighting[k] = f:Lerp(v, e)
    				elseif type(v) == "number" and type(f) == "number" then
    					if k == "ClockTime" then
    						local d = v - f
    						if d > 12 then d = d - 24 elseif d < -12 then d = d + 24 end
    						Lighting[k] = (f + d * e) % 24
    					else Lighting[k] = f + (v - f) * e end
    				elseif a >= 1 then Lighting[k] = v end
    			end)
    		end
    	end)
    end

    local function assetUrl(id)
    	if type(id) == "number" then return "rbxassetid://" .. id end
    	return tostring(id)
    end
    local function skyboxProps(name)
    	local faces = Sky.Skyboxes[name]
    	if not faces then return nil end
    	return { SkyboxBk = assetUrl(faces[1]), SkyboxDn = assetUrl(faces[2]), SkyboxFt = assetUrl(faces[3]), SkyboxLf = assetUrl(faces[4]), SkyboxRt = assetUrl(faces[5]), SkyboxUp = assetUrl(faces[6]) }
    end
    local function resolveSkybox(p)
    	local pick = S.SkyState.Skybox or "Preset default"
    	if pick == "Game's own" then return nil end
    	if pick ~= "Preset default" then return pick end
    	return p and p.Skybox or nil
    end
    local function resolveClouds(p)
    	local pick = S.SkyState.Clouds or "Preset default"
    	if pick == "Off" then return nil end
    	if pick ~= "Preset default" then return pick end
    	return p and p.Clouds or nil
    end
    local function mkClouds(name)
    	local spec = Sky.CloudSpecs[name]
    	if not spec then return end
    	mkFX("Clouds", { Cover = spec.Cover, Density = spec.Density, Color = spec.Color, Enabled = true }, "PF_Clouds", Terrain)
    end

    function Sky.applyFilter(name)
    	S.SkyState.Filter = name or "None"
    	if Sky.filterObjs then for _, o in ipairs(Sky.filterObjs) do pcall(function() o:Destroy() end) end end
    	Sky.filterObjs = {}
    	local f = Sky.Filters[name]
    	if not f then return end
    	local okC, cc = pcall(Instance.new, "ColorCorrectionEffect")
    	if okC then
    		cc.Name = "PF_Filter"
    		applyProps(cc, { Brightness = f.Brightness, Contrast = f.Contrast, Saturation = f.Saturation, TintColor = f.TintColor })
    		cc.Parent = Lighting
    		table.insert(Sky.filterObjs, cc)
    	end
    	if f.Bloom then
    		local okB, bl = pcall(Instance.new, "BloomEffect")
    		if okB then
    			bl.Name = "PF_FilterBloom"
    			applyProps(bl, f.Bloom)
    			bl.Parent = Lighting
    			table.insert(Sky.filterObjs, bl)
    		end
    	end
    end

    function Sky.apply(name)
    	local p = Sky.Presets[name]
    	if not p then Sky.restore() return end
    	Sky.save()
    	stashAll()
    	killSkyObjects()
    	Sky.current = name
    	local skyProps = {}
    	if p.Sky then
    		skyProps = {
    			StarCount = p.Sky.Stars or 3000, SunAngularSize = p.Sky.Sun or 21, MoonAngularSize = p.Sky.Moon or 11,
    			CelestialBodiesShown = p.Sky.Bodies ~= false,
    		}
    		if p.Sky.SunTex then skyProps.SunTextureId = assetUrl(p.Sky.SunTex) end
    		if p.Sky.MoonTex then skyProps.MoonTextureId = assetUrl(p.Sky.MoonTex) end
    	end
    	local sbx = skyboxProps(resolveSkybox(p))
    	if sbx then for k, v in pairs(sbx) do skyProps[k] = v end end
    	Sky.skyObj = mkFX("Sky", skyProps, "PF_Sky")
    	if p.Atmosphere then mkFX("Atmosphere", p.Atmosphere, "PF_Atmosphere") end
    	if p.Bloom then mkFX("BloomEffect", p.Bloom, "PF_Bloom") end
    	if p.Color then mkFX("ColorCorrectionEffect", p.Color, "PF_Color") end
    	if p.Rays then mkFX("SunRaysEffect", p.Rays, "PF_Rays") end
    	mkClouds(resolveClouds(p))
    	local tbl = {}
    	for k, v in pairs(p.Lighting or {}) do tbl[k] = v end
    	if Sky.cycle.on then tbl.ClockTime = nil end
    	applyLightingTable(tbl, Sky.smooth)
    end

    local function applyDefaultExtras()
    	local sbName = resolveSkybox(nil)
    	local clName = resolveClouds(nil)
    	local cloudsOff = S.SkyState.Clouds == "Off"
    	if not sbName and not clName and not cloudsOff then Sky.restore() return end
    	Sky.save()
    	stashAll()
    	killSkyObjects()
    	local light = Sky.saved and Sky.saved.light or {}
    	for k, v in pairs(light) do pcall(function() Lighting[k] = v end) end
    	Sky.current = "Default"
    	if sbName then Sky.skyObj = mkFX("Sky", skyboxProps(sbName), "PF_Sky") end

    	for _, st in ipairs(Sky.stashed) do
    		local inst = st.inst
    		local back = true
    		if inst:IsA("Sky") and sbName then back = false end
    		if inst:IsA("Clouds") and (clName or S.SkyState.Clouds == "Off") then back = false end
    		if back then pcall(function() inst.Parent = st.parent end) end
    	end
    	if clName then mkClouds(clName) end
    end
    function Sky.select(name)
    	Sky.current = name
    	if name == "Default" then applyDefaultExtras() else Sky.apply(name) end
    end
    function Sky.refresh()
    	Sky.select(S.SkyState.Preset or "Default")
    end

    function Sky.setCycle(on)
    	Sky.cycle.on = on
    	if on then
    		Sky.save()
    		Tick.use("SkyCycle", function(dt)
    			pcall(function() Lighting.ClockTime = (Lighting.ClockTime + dt * Sky.cycle.speed * 0.4) % 24 end)
    		end)
    	else
    		Tick.drop("SkyCycle")
    	end
    end

    Sky.spinAngle = 0
    function Sky.setSpin(degPerSec)
    	Sky.spinSpeed = degPerSec or 0
    	if Sky.spinSpeed > 0 then
    		Tick.use("SkySpin", function(dt)
    			if not Sky.skyObj or not Sky.skyObj.Parent then return end
    			Sky.spinAngle = (Sky.spinAngle + dt * Sky.spinSpeed) % 360
    			local ok = pcall(function() Sky.skyObj.SkyboxOrientation = Vector3.new(0, Sky.spinAngle, 0) end)
    			if not ok then Tick.drop("SkySpin") end
    		end)
    	else
    		Tick.drop("SkySpin")
    	end
    end

    function Sky.setGusts(on)
    	if on then
    		if Sky.windSaved == nil then
    			local ok, w = pcall(function() return workspace.GlobalWind end)
    			Sky.windSaved = (ok and w) or Vector3.zero
    		end
    		Tick.use("Gusts", function(dt, t)
    			local dir = (Sky.weather.wind or 0) >= 0 and 1 or -1
    			local strength = 4 + 10 * math.abs(Sky.weather.wind or 0)
    			local gust = strength * (0.6 + 0.4 * math.sin(t * 0.35) + 0.25 * math.sin(t * 1.3) + 0.1 * math.sin(t * 3.1))
    			pcall(function() workspace.GlobalWind = Vector3.new(dir * gust, 0, gust * 0.25 * math.sin(t * 0.2)) end)
    		end)
    	else
    		Tick.drop("Gusts")
    		if Sky.windSaved ~= nil then
    			pcall(function() workspace.GlobalWind = Sky.windSaved end)
    			Sky.windSaved = nil
    		end
    	end
    end

    local function weatherClear()
    	Tick.drop("Weather")
    	for _, c in ipairs(Sky.weather.cells or {}) do pcall(function() c.att:Destroy() end) end
    	for _, x in ipairs(Sky.weather.objects or {}) do pcall(function() if typeof(x) == "Instance" then x:Destroy() else x:destroy() end end) end
    	Sky.weather.cells, Sky.weather.emitters, Sky.weather.objects, Sky.weather.extra = {}, {}, {}, nil
    end
    function Sky.setWeather(kind)
    	weatherClear()
    	Sky.weather.kind = kind or "None"
    	if Sky.weather.kind == "None" then return end
    	local specs = {}
    	local function em(props) table.insert(specs, props) end
    	local baseRate = q(30, 10) * Sky.weather.intensity
    	local w = Sky.weather.kind
    	local windK = Sky.weather.wind
    	local wind = Vector3.new(windK * 6, 0, 0)
    	local yLevel, spacing = 20, 36
    	if w == "Snow" then
    		yLevel = 18
    		em({ Enabled = true, Rate = baseRate, Texture = TEX.Star, Color = cseq(WHITE, P(220, 235, 255)), Size = nseq(0.16, 0.24, 0.18), Lifetime = range(6, 9), Speed = range(3, 5), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(25, 25), Acceleration = Vector3.new(0, -0.5, 0) + wind, Drag = 0.3, Transparency = nseq(0, 0.1, 1), Rotation = range(-180, 180), RotSpeed = range(-90, 90), WindAffectsDrag = true })
    		em({ Enabled = true, Rate = baseRate * 0.5, Texture = TEX.Mote, Color = cseq(WHITE), Size = nseq(0.08, 0.1), Lifetime = range(7, 10), Speed = range(2, 3.5), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(35, 35), Acceleration = Vector3.new(0, -0.3, 0) + wind, Drag = 0.5, Transparency = nseq(0.2, 0.3, 1), WindAffectsDrag = true })
    	elseif w == "Rain" or w == "Thunderstorm" then
    		yLevel = 35
    		local storm = w == "Thunderstorm"
    		em({ Enabled = true, Rate = baseRate * (storm and 3 or 2), Texture = TEX.Drop, Color = cseq(P(190, 215, 255)), Size = nseq(0.12, 0.1), Lifetime = range(1.2, 1.6), Speed = range(45, 60), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(3, 3), Acceleration = Vector3.new(0, -20, 0) + wind * 3, Transparency = nseq(0.25, 0.45), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-2), Rotation = range(0), RotSpeed = range(0), LightEmission = 0.3 })
    		em({ Enabled = true, Rate = baseRate * 0.3, Texture = TEX.Cloud, Color = cseq(P(200, 215, 235)), Size = nseq(6, 10), Lifetime = range(4, 6), Speed = range(1, 2), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(20, 20), Acceleration = wind, Transparency = nseq(0.93, 0.88, 1), LightEmission = 0.1, WindAffectsDrag = true, Drag = 0.5 })
    		if storm then
    			local nextBolt = 2
    			Sky.weather.extra = function(dt, t, p)
    				if t < nextBolt then return end
    				nextBolt = t + rnd(2.5, 7) / math.max(Sky.weather.intensity, 0.3)
    				local ang, dist = rnd(0, TAU), rnd(40, 110)
    				local hit = groundAt(p + Vector3.new(math.cos(ang) * dist, 30, math.sin(ang) * dist), Char.model, 30)
    				skyBolt(hit, { Color = cseq(WHITE, P(200, 220, 255)), W = 0.6, H = 90, Dur = 0.45, LightColor = P(200, 220, 255), Branches = 3, Jitter = 4 })
    				glint(hit, P(200, 220, 255), 90, 4, 0.5)
    				later(0.05, function() shockSprite(hit, { tex = TEX.Shock, color = cseq(WHITE, P(200, 220, 255)), s0 = 1, s1 = 14, life = 0.5 }) end)
    			end
    		end
    	elseif w == "Embers" then
    		yLevel = -4
    		em({ Enabled = true, Rate = baseRate * 0.5, Texture = TEX.Ember, Color = cseq(P(255, 200, 120), P(255, 90, 20), P(80, 20, 0)), Size = nseq(0.22, 0.14, 0), Lifetime = range(4, 7), Speed = range(2, 4), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(40, 40), Acceleration = Vector3.new(0, 0.8, 0) + wind, Drag = 0.4, Transparency = nseq(0, 0.2, 1), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-1.5, -0.3, 0), Rotation = range(0), RotSpeed = range(0), WindAffectsDrag = true })
    		em({ Enabled = true, Rate = baseRate * 0.15, Texture = TEX.Puff, Color = cseq(P(60, 50, 50), BLACK), Size = nseq(4, 9), Lifetime = range(8, 12), Speed = range(1, 2), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(60, 60), Acceleration = wind, Drag = 0.3, Transparency = nseq(0.85, 0.7, 1), LightEmission = 0, WindAffectsDrag = true })
    	elseif w == "Petals" then
    		yLevel = 15
    		em({ Enabled = true, Rate = baseRate * 0.7, Texture = TEX.Heart, Color = cseq(P(255, 200, 225), P(255, 150, 200), P(255, 220, 235)), Size = nseq(0.28, 0.24), Lifetime = range(6, 9), Speed = range(2, 4), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(45, 45), Acceleration = Vector3.new(1.5, -0.3, 0.5) + wind, Drag = 0.5, Transparency = nseq(0.1, 0.2, 1), Rotation = range(-180, 180), RotSpeed = range(-200, 200), LightEmission = 0.5, WindAffectsDrag = true })
    	elseif w == "Leaves" then
    		yLevel = 14
    		em({ Enabled = true, Rate = baseRate * 0.6, Texture = TEX.Cloud, Color = cseq(P(230, 150, 40), P(190, 80, 20), P(120, 60, 20)), Size = nseq(0.3, 0.26), Lifetime = range(6, 9), Speed = range(2, 4), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(50, 50), Acceleration = Vector3.new(1.2, -0.4, 0.6) + wind, Drag = 0.6, Transparency = nseq(0.1, 0.15, 1), Rotation = range(-180, 180), RotSpeed = range(-260, 260), LightEmission = 0.15, WindAffectsDrag = true })
    		em({ Enabled = true, Rate = baseRate * 0.2, Texture = TEX.Cloud, Color = cseq(P(200, 190, 60), P(150, 110, 30)), Size = nseq(0.22), Lifetime = range(7, 10), Speed = range(1.5, 3), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(60, 60), Acceleration = Vector3.new(0.8, -0.3, 0.3) + wind, Drag = 0.8, Transparency = nseq(0.2, 1), Rotation = range(-180, 180), RotSpeed = range(-180, 180), LightEmission = 0.1, WindAffectsDrag = true })
    	elseif w == "Fireflies" then
    		yLevel = 3
    		em({ Enabled = true, Rate = baseRate * 0.35, Texture = TEX.Mote, Color = cseq(P(255, 255, 170), P(180, 255, 120)), Size = nseq(0, 0.24, 0.2, 0.24, 0), Lifetime = range(4, 7), Speed = range(0.5, 1.5), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 0.1, 0), Drag = 1, Transparency = nseq(1, 0, 0.3, 0, 1), WindAffectsDrag = true })
    	elseif w == "Ash" then
    		yLevel = 18
    		em({ Enabled = true, Rate = baseRate * 0.8, Texture = TEX.Puff, Color = cseq(P(120, 115, 110), P(60, 58, 55)), Size = nseq(0.15, 0.25), Lifetime = range(7, 10), Speed = range(1.5, 3), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(50, 50), Acceleration = Vector3.new(0.6, -0.2, 0.3) + wind, Drag = 0.6, Transparency = nseq(0.2, 0.3, 1), RotSpeed = range(-40, 40), LightEmission = 0, WindAffectsDrag = true })
    		em({ Enabled = true, Rate = baseRate * 0.1, Texture = TEX.Ember, Color = cseq(P(255, 140, 60), P(120, 30, 0)), Size = nseq(0.12, 0), Lifetime = range(4, 6), Speed = range(1, 2), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(60, 60), Acceleration = Vector3.new(0.4, -0.3, 0.2) + wind, Drag = 0.5, Transparency = nseq(0, 1), WindAffectsDrag = true })
    	elseif w == "Pollen" then
    		yLevel = 3
    		em({ Enabled = true, Rate = baseRate * 0.6, Texture = TEX.Mote, Color = cseq(P(255, 245, 180), P(255, 220, 120)), Size = nseq(0.08, 0.12, 0.08), Lifetime = range(5, 8), Speed = range(0.5, 1.5), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0.4, -0.15, 0.2) + wind, Drag = 1, Transparency = nseq(0.3, 0.2, 1), LightEmission = 0.8, WindAffectsDrag = true })
    	elseif w == "Meteor Shower" then
    		yLevel = 45
    		em({ Enabled = true, Rate = baseRate * 0.08, Texture = TEX.Trace, Color = cseq(WHITE, P(255, 220, 160), P(255, 120, 60)), Size = nseq(0.7, 0.4, 0), Lifetime = range(1.2, 2), Speed = range(60, 90), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(12, 12), Acceleration = Vector3.new(25, 0, 10), Transparency = nseq(0, 0.2, 1), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-6, -3), Rotation = range(0), RotSpeed = range(0), LightEmission = 1 })
    		em({ Enabled = true, Rate = baseRate * 0.4, Texture = TEX.Star, Color = cseq(WHITE, P(200, 220, 255)), Size = nseq(0.1, 0.18, 0), Lifetime = range(3, 5), Speed = range(0.2, 0.5), SpreadAngle = Vector2.new(180, 180), Transparency = nseq(1, 0.2, 1), Rotation = range(-180, 180), RotSpeed = range(-60, 60) })
    	elseif w == "Bubbles" then
    		yLevel = -4
    		em({ Enabled = true, Rate = baseRate * 0.5, Texture = TEX.Circle, Color = cseq(WHITE, P(200, 240, 255), P(255, 220, 250)), Size = nseq(0.2, 0.5, 0.55), Lifetime = range(5, 8), Speed = range(1, 2.5), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(40, 40), Acceleration = Vector3.new(0.5, 0.3, 0.2) + wind, Drag = 0.5, Transparency = nseq(0.4, 0.5, 1), LightEmission = 0.6, WindAffectsDrag = true })
    	elseif w == "Sandstorm" then
    		yLevel, spacing = 4, 30
    		local dirX = (windK == 0) and 1 or (windK > 0 and 1 or -1)
    		em({ Enabled = true, Rate = baseRate * 0.6, Texture = TEX.Puff, Color = cseq(P(215, 185, 130), P(180, 150, 100)), Size = nseq(6, 12, 14), Lifetime = range(3, 5), Speed = range(18, 28), EmissionDirection = dirX > 0 and Enum.NormalId.Right or Enum.NormalId.Left, SpreadAngle = Vector2.new(25, 25), Acceleration = Vector3.new(dirX * 6, 0.5, 0), Drag = 0.2, Transparency = nseq(0.9, 0.78, 0.82, 1), RotSpeed = range(-20, 20), LightEmission = 0.05, WindAffectsDrag = true })
    		em({ Enabled = true, Rate = baseRate * 1.2, Texture = TEX.Mote, Color = cseq(P(240, 215, 160)), Size = nseq(0.1, 0.14), Lifetime = range(2, 3.5), Speed = range(25, 40), EmissionDirection = dirX > 0 and Enum.NormalId.Right or Enum.NormalId.Left, SpreadAngle = Vector2.new(20, 20), Acceleration = Vector3.new(dirX * 10, -1, 0), Transparency = nseq(0.4, 0.5, 1), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = nseq(-2), Rotation = range(0), RotSpeed = range(0), LightEmission = 0.2 })
    	elseif w == "Aurora" then

    		local curtains = {}
    		local colors = {
    			cseq(P(60, 255, 160), P(40, 220, 200), P(120, 80, 255)),
    			cseq(P(120, 255, 200), P(60, 200, 255), P(200, 90, 255)),
    			cseq(P(40, 230, 120), P(90, 255, 220), P(80, 120, 255)),
    		}
    		for i = 1, q(3, 2) do
    			local a0 = worldAttach(CFrame.new(), "PF_Weather")
    			local a1 = worldAttach(CFrame.new(), "PF_Weather")
    			local b = beam(a0, a1, { FaceCamera = false, Segments = 24, Width0 = 28 + i * 6, Width1 = 22 + i * 6, Color = colors[(i - 1) % #colors + 1], Texture = TEX.Smoke, TextureMode = Enum.TextureMode.Wrap, TextureLength = 60, TextureSpeed = 0.08 * i * (i % 2 == 0 and -1 or 1), Transparency = nseq(0.7, 0.55, 0.7), LightEmission = 1, ZOffset = -i })
    			table.insert(Sky.weather.objects, a0) table.insert(Sky.weather.objects, a1)
    			curtains[i] = { a0 = a0, a1 = a1, b = b, phase = i * 1.7, z = -60 - i * 40, y = 120 + i * 15 }
    		end
    		Sky.weather.extra = function(dt, t, p)
    			for _, c in ipairs(curtains) do
    				local half = 180
    				local wave = math.sin(t * 0.25 + c.phase) * 25
    				local y = c.y + math.sin(t * 0.18 + c.phase) * 10

    				c.a0.CFrame = CFrame.fromMatrix(Vector3.new(p.X - half, y, p.Z + c.z + wave), Vector3.xAxis, Vector3.yAxis, Vector3.zAxis)
    				c.a1.CFrame = CFrame.fromMatrix(Vector3.new(p.X + half, y, p.Z + c.z - wave), Vector3.xAxis, Vector3.yAxis, Vector3.zAxis)
    				c.b.CurveSize0 = 60 + wave * 2
    				c.b.CurveSize1 = -60 + wave * 2
    				c.b.Width0 = 26 + 8 * math.sin(t * 0.4 + c.phase)
    				c.b.Width1 = 26 + 8 * math.cos(t * 0.3 + c.phase)
    			end
    		end
    		yLevel = 40
    		em({ Enabled = true, Rate = baseRate * 0.2, Texture = TEX.Star, Color = cseq(P(200, 255, 230), P(180, 200, 255)), Size = nseq(0, 0.2, 0.15, 0), Lifetime = range(3, 5), Speed = range(0.1, 0.3), SpreadAngle = Vector2.new(180, 180), Transparency = nseq(1, 0.2, 0.3, 1), Rotation = range(-180, 180), RotSpeed = range(-40, 40) })
    	else
    		yLevel = 4
    		em({ Enabled = true, Rate = baseRate * 0.5, Texture = TEX.Glint, Color = cseq(P(255, 230, 255), P(200, 240, 255), P(255, 250, 200)), Size = nseq(0, 0.3, 0.22, 0.3, 0), Lifetime = range(3, 5), Speed = range(0.3, 1), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -0.15, 0), Drag = 1, Transparency = nseq(1, 0, 0.2, 0, 1), Rotation = range(-180, 180), RotSpeed = range(-120, 120), WindAffectsDrag = true })
    		em({ Enabled = true, Rate = baseRate * 0.6, Texture = TEX.Mote, Color = cseq(WHITE, P(255, 220, 255)), Size = nseq(0.06, 0.1, 0), Lifetime = range(4, 7), Speed = range(0.2, 0.6), SpreadAngle = Vector2.new(180, 180), Drag = 1, Transparency = nseq(0.5, 0, 1), WindAffectsDrag = true })
    	end
    	local cells = {}
    	for ix = -1, 1 do
    		for iz = -1, 1 do
    			local a = worldAttach(CFrame.new(0, 40, 0), "PF_Weather")
    			for _, spec in ipairs(specs) do table.insert(Sky.weather.emitters, emitter(a, spec)) end
    			table.insert(cells, { att = a, off = Vector3.new(ix * spacing, yLevel + math.abs(ix * iz) * 0.5, iz * spacing) })
    		end
    	end
    	Sky.weather.cells = cells
    	Tick.use("Weather", function(dt, t)
    		local p
    		local ok, cam = pcall(function() return workspace.CurrentCamera end)
    		if ok and cam then p = cam.CFrame.Position end
    		if not p then
    			if Char.root and Char.root.Parent then p = Char.root.Position else return end
    		end
    		for _, c in ipairs(Sky.weather.cells) do c.att.CFrame = CFrame.new(p + c.off) end
    		if Sky.weather.extra then pcall(Sky.weather.extra, dt, t, p) end
    	end)
    end
    function Sky.setWeatherIntensity(v)
    	Sky.weather.intensity = v
    	if Sky.weather.kind ~= "None" then Sky.setWeather(Sky.weather.kind) end
    end
    function Sky.setWind(v)
    	Sky.weather.wind = v
    	if Sky.weather.kind ~= "None" then Sky.setWeather(Sky.weather.kind) end
    end
    function Sky.unload()
    	Sky.setCycle(false)
    	Sky.setSpin(0)
    	Sky.setGusts(false)
    	Sky.applyFilter("None")
    	Sky.restore()
    	weatherClear()
    	Sky.weather.kind = "None"
    end
    local DEFAULTS
    local COLOR_PRESETS = {
    	{ name = "Ultraviolet", icon = "🟣", p = { P(225, 190, 255), P(160, 60, 255),  P(50, 10, 110)  } },
    	{ name = "Solar Flare", icon = "☀️", p = { P(255, 245, 190), P(255, 175, 30),  P(150, 60, 0)   } },
    	{ name = "Glacier",     icon = "🧊", p = { P(235, 250, 255), P(130, 210, 255), P(30, 90, 170)  } },
    	{ name = "Bloodmoon",   icon = "🌑", p = { P(255, 150, 150), P(220, 30, 50),   P(70, 0, 15)    } },
    	{ name = "Jungle",      icon = "🌿", p = { P(210, 255, 200), P(60, 220, 90),   P(10, 80, 40)   } },
    	{ name = "Deep Sea",    icon = "🐋", p = { P(180, 230, 255), P(20, 110, 240),  P(5, 30, 100)   } },
    	{ name = "Peach",       icon = "🍑", p = { P(255, 230, 210), P(255, 150, 110), P(170, 60, 60)  } },
    	{ name = "Frostbite",   icon = "❄️", p = { P(245, 252, 255), P(170, 230, 255), P(70, 130, 200) } },
    	{ name = "Magma",       icon = "🌋", p = { P(255, 210, 140), P(255, 100, 10),  P(110, 15, 0)   } },
    	{ name = "Orchid",      icon = "🌺", p = { P(255, 215, 240), P(240, 90, 190),  P(120, 10, 90)  } },
    	{ name = "Radioactive", icon = "☢️", p = { P(235, 255, 180), P(180, 255, 20),  P(60, 110, 0)   } },
    	{ name = "Nebula",      icon = "🌌", p = { P(190, 170, 255), P(110, 70, 200),  P(20, 10, 60)   } },
    	{ name = "Chrome",      icon = "🔘", p = { P(255, 255, 255), P(190, 200, 220), P(70, 80, 110)  } },
    	{ name = "Campfire",    icon = "🔥", p = { P(255, 235, 200), P(255, 160, 70),  P(120, 45, 10)  } },
    	{ name = "Spearmint",   icon = "🌱", p = { P(225, 255, 245), P(90, 255, 200),  P(10, 110, 90)  } },
    	{ name = "Sapphire",    icon = "💎", p = { P(205, 200, 255), P(70, 70, 240),   P(20, 10, 120)  } },
    	{ name = "Cotton",      icon = "🍭", p = { P(255, 235, 250), P(255, 130, 230), P(90, 210, 255) } },
    	{ name = "Lightning",   icon = "⚡", p = { P(255, 255, 255), P(190, 225, 255), P(30, 50, 130)  } },
    	{ name = "Wine",        icon = "🍷", p = { P(255, 140, 150), P(150, 15, 45),   P(40, 0, 15)    } },
    	{ name = "Aurora",      icon = "🌠", p = { P(190, 255, 225), P(70, 230, 170),  P(130, 60, 230) } },
    	{ name = "Amber",       icon = "🍯", p = { P(255, 240, 190), P(255, 185, 50),  P(140, 85, 15)  } },
    	{ name = "Hot Pink",    icon = "💖", p = { P(255, 205, 240), P(255, 40, 160),  P(110, 0, 80)   } },
    	{ name = "Blossom",     icon = "🌸", p = { P(255, 242, 246), P(255, 175, 205), P(190, 80, 120) } },
    	{ name = "Graphite",    icon = "🪨", p = { P(130, 140, 170), P(45, 50, 75),    P(8, 8, 18)     } },
    	{ name = "Ember Glow",  icon = "🕯️", p = { P(255, 220, 160), P(255, 120, 30),  P(120, 20, 0)   } },
    	{ name = "Polar Night", icon = "🌃", p = { P(200, 230, 255), P(60, 120, 220),  P(10, 20, 60)   } },
    	{ name = "Candy Mint",  icon = "🍬", p = { P(240, 255, 250), P(120, 240, 200), P(255, 120, 190) } },
    	{ name = "Royal Gold",  icon = "👑", p = { P(255, 250, 220), P(255, 200, 60),  P(120, 70, 10)  } },
    }
    local COLOR_TARGETS = { "Wings", "Halo", "Hat", "Jump", "Trails", "Kill", "Pet", "Aura", "Glow", "Foot", "ScreenFX" }
    local RAINBOW_SPEEDS = { { label = "🐌 Slow", v = 0.05 }, { label = "🚶 Normal", v = 0.12 }, { label = "🏃 Fast", v = 0.3 }, { label = "⚡ Ultra", v = 0.8 } }
    local Colors = { target = "Wings", presetNames = {}, speedNames = {}, on = {}, hue = {}, speed = 0.12, acc = 0 }
    for i, p in ipairs(COLOR_PRESETS) do Colors.presetNames[i] = p.icon .. " " .. p.name end
    for i, sp in ipairs(RAINBOW_SPEEDS) do Colors.speedNames[i] = sp.label end

    local function rebuild(key)
    	local m = Modules.map[key]
    	if not m or not m.persistent or not m.build then return end
    	if S[key].Enabled then m.build() else m.stop() end
    end
    local pendingRebuild = {}
    local function debounce(key, fn, delay)
    	if pendingRebuild[key] then return end
    	pendingRebuild[key] = true
    	later(delay or 0.15, function()
    		pendingRebuild[key] = false
    		fn()
    	end)
    end
    local function rebuildAll()
    	for _, m in ipairs(Modules.list) do
    		if m.persistent and m.build then
    			if S[m.key].Enabled then pcall(m.build) else pcall(m.stop) end
    		end
    	end
    end
    local function setColor(key, c)
    	S[key].Palette = nil
    	S[key].Color = c
    	if key == "Trails" then S.Trails.Custom = true end
    	if Modules.map[key] and Modules.map[key].built then debounce("color" .. key, function() rebuild(key) end) end
    end
    function Colors.apply(target, preset)
    	local cfg = S[target]
    	if not cfg then return end
    	cfg.Palette = { preset.p[1], preset.p[2], preset.p[3] }
    	cfg.Color = preset.p[2]
    	if target == "Trails" then cfg.Color2 = preset.p[1] cfg.Custom = true end
    	local m = Modules.map[target]
    	if m and m.built then rebuild(target) end
    end
    function Colors.reset(target)
    	local cfg = S[target]
    	if not cfg then return end
    	cfg.Palette = nil
    	cfg.Color = DEFAULTS[target].Color
    	if target == "Trails" then cfg.Color2 = DEFAULTS.Trails.Color2 cfg.Custom = false end
    	if Modules.map[target] and Modules.map[target].built then rebuild(target) end
    end
    function Colors.step(dt)
    	Colors.acc = Colors.acc + dt
    	if Colors.acc < 0.07 then return end
    	local step = Colors.acc
    	Colors.acc = 0
    	for target in pairs(Colors.on) do
    		local h = ((Colors.hue[target] or 0) + step * Colors.speed) % 1
    		Colors.hue[target] = h
    		RainbowHue[target] = h
    		local m = Modules.map[target]
    		if m and m.built and not m.selfRainbow then
    			pcall(function() m:hueShift(h - baseHue(S[target])) end)
    		end
    	end
    end
    function Colors.rainbow(target, on)
    	Colors.on[target] = on and true or nil
    	if not on then
    		RainbowHue[target] = nil
    		local m = Modules.map[target]
    		if m and m.built then rebuild(target) end
    	end
    	if next(Colors.on) then Tick.use("Rainbow", Colors.step) else Tick.drop("Rainbow") end
    end

    S.SkyState = { Preset = "Default", Weather = "None", Cycle = false, CycleSpeed = 1, Smooth = true, Intensity = 1, Wind = 0, Skybox = "Preset default", Clouds = "Preset default", Filter = "None", Spin = 0, Gusts = false }
    S.Perf = { Quality = math.floor(QUALITY * 100 + 0.5), Cap = "Off" }
    DEFAULTS = deepCopy(S)

    local Perf = { caps = { "Off", "30 FPS", "45 FPS", "60 FPS" } }
    function Perf.setQuality(pct)
    	QUALITY = clamp(pct, 20, 100) / 100
    	S.Perf.Quality = pct
    	debounce("quality", rebuildAll, 0.4)
    end
    function Perf.setCap(name)
    	S.Perf.Cap = name
    	Tick.cap = tonumber(name:match("%d+")) or 0
    end
    function Perf.stats()
    	local n = { Beam = 0, ParticleEmitter = 0, Trail = 0, PointLight = 0, Attachment = 0, Highlight = 0, Part = 0 }
    	local function scan(list)
    		for _, d in ipairs(list) do
    			local c = d.ClassName
    			if n[c] then n[c] = n[c] + 1 end
    			if d:IsA("BasePart") then n.Part = n.Part + 1 end
    		end
    	end
    	scan(folder():GetDescendants())
    	for _, ch in ipairs(Terrain:GetChildren()) do
    		if ch.Name:sub(1, 2) == "PF" then n.Attachment = n.Attachment + 1 scan(ch:GetDescendants()) end
    	end
    	if Char.model and Char.model.Parent then
    		for _, d in ipairs(Char.model:GetDescendants()) do
    			if d.Name:sub(1, 2) == "PF" then
    				n.Attachment = n.Attachment + 1
    				scan(d:GetDescendants())
    			end
    		end
    	end
    	local tickUsers = 0
    	for _ in pairs(Tick.users) do tickUsers = tickUsers + 1 end
    	return ("Beams %d · Particles %d · Trails %d · Lights %d · Highlights %d · Attachments %d · Parts %d | anim %d · tick %d · quality %d%%"):format(
    		n.Beam, n.ParticleEmitter, n.Trail, n.PointLight, n.Highlight, n.Attachment, n.Part, #Timeline.list, tickUsers, math.floor(QUALITY * 100 + 0.5))
    end

    local Profiles = { Slots = { "Slot 1", "Slot 2", "Slot 3", "Slot 4" }, slot = "Slot 1", mem = {}, autoload = false }
    local function encodeVal(v)
    	if typeof(v) == "Color3" then return { __c3 = { v.R, v.G, v.B } } end
    	if type(v) == "table" then
    		local t = {}
    		for k, x in pairs(v) do t[tostring(k)] = encodeVal(x) end
    		return t
    	end
    	return v
    end
    local function decodeVal(v)
    	if type(v) ~= "table" then return v end
    	if v.__c3 then return Color3.new(v.__c3[1] or 1, v.__c3[2] or 1, v.__c3[3] or 1) end
    	local t = {}
    	for k, x in pairs(v) do t[tonumber(k) or k] = decodeVal(x) end
    	return t
    end
    local function fileName(slot) return "PrismFlux_v4_" .. slot:gsub("%s", "_") .. ".json" end
    local function canFiles() return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function" end
    function Profiles.save(slot)
    	local blob = encodeVal(S)
    	Profiles.mem[slot] = blob
    	local ok, err = pcall(function()
    		if not canFiles() then error("no file API") end
    		writefile(fileName(slot), SR_UI.service("HttpService"):JSONEncode(blob))
    	end)
    	return true, ok and ("Saved → " .. slot .. " (file)") or ("Saved → " .. slot .. " (session only)")
    end
    function Profiles.load(slot)
    	local blob = Profiles.mem[slot]
    	pcall(function()
    		if canFiles() and isfile(fileName(slot)) then
    			blob = SR_UI.service("HttpService"):JSONDecode(readfile(fileName(slot)))
    		end
    	end)
    	if not blob then return false, "Slot is empty: " .. slot end
    	local data = decodeVal(blob)
    	for key, tbl in pairs(data) do
    		if type(tbl) == "table" and type(S[key]) == "table" then
    			if tbl.Palette == nil then S[key].Palette = nil end
    			for f, v in pairs(tbl) do
    				local cur = S[key][f]
    				if f == "Palette" then S[key].Palette = (type(v) == "table") and { v[1], v[2], v[3] } or nil
    				elseif cur ~= nil and typeof(cur) == typeof(v) then S[key][f] = v end
    			end
    		end
    	end
    	Profiles.slot = slot
    	Profiles.applyState()
    	return true, "Loaded ← " .. slot
    end
    function Profiles.reset()
    	local d = deepCopy(DEFAULTS)
    	for key, tbl in pairs(d) do
    		if type(S[key]) == "table" then
    			for f in pairs(S[key]) do S[key][f] = nil end
    			for f, v in pairs(tbl) do S[key][f] = v end
    		end
    	end
    	for t in pairs(Colors.on) do Colors.rainbow(t, false) end
    	Profiles.applyState()
    	return true, "Defaults restored"
    end
    function Profiles.applyState()
    	QUALITY = clamp(S.Perf.Quality, 20, 100) / 100
    	Perf.setCap(S.Perf.Cap)
    	rebuildAll()
    	if S.Kill.Enabled then Kill.build() else Kill.stop() end
    	Sky.smooth = S.SkyState.Smooth
    	Sky.cycle.speed = S.SkyState.CycleSpeed
    	Sky.select(S.SkyState.Preset)
    	Sky.setCycle(S.SkyState.Cycle)
    	Sky.setSpin(S.SkyState.Spin)
    	Sky.setGusts(S.SkyState.Gusts)
    	Sky.applyFilter(S.SkyState.Filter)
    	Sky.weather.intensity = S.SkyState.Intensity
    	Sky.weather.wind = S.SkyState.Wind
    	Sky.setWeather(S.SkyState.Weather)
    end
    function Profiles.setAutoload(on)
    	Profiles.autoload = on
    	pcall(function()
    		if not canFiles() then return end
    		if on then writefile("PrismFlux_v4_autoload.txt", Profiles.slot) elseif type(delfile) == "function" and isfile("PrismFlux_v4_autoload.txt") then delfile("PrismFlux_v4_autoload.txt") end
    	end)
    	return on and ("Auto-load: " .. Profiles.slot) or "Auto-load off"
    end
    function Profiles.runAutoload()
    	local slot
    	pcall(function() if canFiles() and isfile("PrismFlux_v4_autoload.txt") then slot = readfile("PrismFlux_v4_autoload.txt") end end)
    	if slot and slot ~= "" then
    		Profiles.autoload = true
    		Profiles.slot = slot
    		local ok, msg = Profiles.load(slot)
    		return ok and msg or nil
    	end
    	return nil
    end

    local sysConns = {}
    local function sysConnect(signal, fn)
    	local ok, c = pcall(function() return signal:Connect(fn) end)
    	if ok and c then table.insert(sysConns, c) end
    end
    local charConns = {}
    local function bindCharacter(model)
    	for _, c in ipairs(charConns) do pcall(function() c:Disconnect() end) end
    	charConns = {}
    	if not model then return end
    	local hum = model:FindFirstChildOfClass("Humanoid") or model:WaitForChild("Humanoid", 10)
    	local root = model:FindFirstChild("HumanoidRootPart") or model:WaitForChild("HumanoidRootPart", 10)
    	if not hum or not root or not model.Parent then return end
    	Char.model, Char.humanoid, Char.root = model, hum, root
    	Char.torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or root
    	Char.head = model:FindFirstChild("Head") or Char.torso
    	Char.r6 = model:FindFirstChild("Torso") ~= nil
    	Char.limbs = {}
    	for _, nm in ipairs(Char.r6 and { "Left Arm", "Right Arm", "Left Leg", "Right Leg" } or { "LeftHand", "RightHand", "LeftFoot", "RightFoot" }) do
    		local p = model:FindFirstChild(nm)
    		if p then table.insert(Char.limbs, p) end
    	end
    	table.insert(charConns, hum.Died:Connect(function()
    		if S.Kill.Enabled and S.Kill.OnSelf and Char.root then killFX(Char.root.Position, Char.model) end
    	end))
    	Jump.bind()
    	rebuildAll()
    end

    local function unloadAll()
    	Session.id = Session.id + 1
    	for _, m in ipairs(Modules.list) do
    		if S[m.key] then S[m.key].Enabled = false end
    		pcall(m.stop)
    	end
    	for _, c in ipairs(charConns) do pcall(function() c:Disconnect() end) end
    	for _, c in ipairs(sysConns) do pcall(function() c:Disconnect() end) end
    	charConns, sysConns = {}, {}
    	Tick.users = {}
    	if Tick.conn then Tick.conn:Disconnect() Tick.conn = nil end
    	for _, it in ipairs(Timeline.list) do if it.finish then pcall(it.finish) end end
    	Timeline.list = {}
    	if Timeline.conn then Timeline.conn:Disconnect() Timeline.conn = nil end
    	Colors.on = {}
    	for k in pairs(RainbowHue) do RainbowHue[k] = nil end
    	pcall(Sky.unload)
    	pcall(function() if Char.humanoid then Char.humanoid.CameraOffset = Vector3.zero end end)
    	for _, ch in ipairs(Terrain:GetChildren()) do
    		if ch.Name:sub(1, 2) == "PF" then pcall(function() ch:Destroy() end) end
    	end
    	if Char.model and Char.model.Parent then
    		for _, d in ipairs(Char.model:GetDescendants()) do
    			if d.Name:sub(1, 2) == "PF" then pcall(function() d:Destroy() end) end
    		end
    	end
    	for _, ch in ipairs(Lighting:GetChildren()) do
    		if ch.Name:sub(1, 3) == "PF_" then pcall(function() ch:Destroy() end) end
    	end
    	for _, ch in ipairs(workspace:GetChildren()) do
    		if ch.Name == "PF_Forge" then pcall(function() ch:Destroy() end) end
    	end
    	local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    	if pg then
    		for _, ch in ipairs(pg:GetChildren()) do
    			if ch.Name:sub(1, 3) == "PF_" then pcall(function() ch:Destroy() end) end
    		end
    	end
    	if fxFolder then pcall(function() fxFolder:Destroy() end) fxFolder = nil end
    end

    sysConnect(LocalPlayer.CharacterAdded, function(c)
    	task.wait(0.4)
    	bindCharacter(c)
    end)
    task.spawn(function()
    	if LocalPlayer.Character then bindCharacter(LocalPlayer.Character) end
    end)

    PF_UI = {section=ODHX.shared.AddSection, notify=ODHX.shared.Notify}

    if type(ODHX.data.snapshot)=="table" and type(ODHX.data.snapshot.settings)=="table" then
        local saved=ODHX.data.snapshot
        Profiles.mem["Last session"]=encodeVal(saved.settings)
        Profiles.load("Last session")
        Profiles.slot=saved.slot or "Slot 1"
        Profiles.autoload=saved.autoload==true
        if type(saved.rainbow)=="table" then
            for target,on in pairs(saved.rainbow) do if on==true then Colors.rainbow(target,true) end end
        end
        if type(saved.rainbowSpeed)=="number" then Colors.speed=saved.rainbowSpeed end
        if type(saved.colorTarget)=="string" then Colors.target=saved.colorTarget end

        if saved.autoload==true then Profiles.runAutoload() end
    else
        Profiles.runAutoload()
    end
    ODHX.capture=function()
        return {settings=S,slot=Profiles.slot,autoload=Profiles.autoload,
            rainbow=Colors.on,rainbowSpeed=Colors.speed,colorTarget=Colors.target}
    end

    local function notify(text, dur) PF_UI.notify(text, dur or 3) end
    local function label(sec, text) pcall(function() sec:AddLabel(text) end) end
    local function x10(v) return math.floor(v * 10 + 0.5) end

    local sec = PF_UI.section("Jump FX")
    sec:AddToggle("Enable jump FX", function(v) S.Jump.Enabled = v end)
    sec:AddDropdown("Style", Jump.Styles, function(v) S.Jump.Style = v end)
    sec:AddColorpicker("Color", S.Jump.Color, function(c) setColor("Jump", c) end)
    sec:AddSlider("Size", 3, 20, S.Jump.Size, function(v) S.Jump.Size = v end)
    sec:AddSlider("Duration x10", 3, 20, x10(S.Jump.Duration), function(v) S.Jump.Duration = v / 10 end)
    sec:AddToggle("Ground flash", function(v) S.Jump.Flash = v end)
    sec:AddToggle("Sparks", function(v) S.Jump.Sparks = v end)
    sec:AddToggle("Light column", function(v) S.Jump.Column = v end)
    sec:AddToggle("Echo ring", function(v) S.Jump.Echo = v end)
    sec:AddToggle("Combo chain (grows on bunny-hops)", function(v) S.Jump.Chain = v end)
    sec:AddToggle("Random style each jump", function(v) S.Jump.Random = v end)
    sec:AddToggle("Mid-air (double jump) ring", function(v) S.Jump.DoubleAir = v end)
    sec:AddButton("▶ Test jump FX", function() Jump.play(true) end)

    sec = PF_UI.section("Wings")
    sec:AddToggle("Enable wings", function(v) S.Wings.Enabled = v rebuild("Wings") end)
    sec:AddDropdown("Style", Wings.Styles, function(v) S.Wings.Style = v if S.Wings.Enabled then Wings.build() end end)
    sec:AddColorpicker("Color", S.Wings.Color, function(c) setColor("Wings", c) end)
    sec:AddSlider("Size x10", 5, 20, x10(S.Wings.Scale), function(v) S.Wings.Scale = v / 10 debounce("Wings", function() rebuild("Wings") end) end)
    sec:AddSlider("Droop (deg)", 0, 40, S.Wings.Droop, function(v) S.Wings.Droop = v debounce("Wings", function() rebuild("Wings") end) end)
    sec:AddToggle("Flapping", function(v) S.Wings.Flap = v end)
    sec:AddToggle("Glow light", function(v) S.Wings.Glow = v rebuild("Wings") end)
    sec:AddToggle("Dust / feathers", function(v) S.Wings.Dust = v rebuild("Wings") end)
    sec:AddToggle("Dynamic (spread on jump/run)", function(v) S.Wings.Dynamic = v end)
    sec:AddToggle("Tip trails", function(v) S.Wings.TipTrails = v rebuild("Wings") end)
    sec:AddToggle("Energy ring behind wings", function(v) S.Wings.Prop = v rebuild("Wings") end)
    sec:AddDropdown("Prop ring Style", PROP_RING_STYLES, function(v) S.Wings.PropStyle = v rebuild("Wings") end)
    sec:AddSlider("Ring Size x10", 5, 40, math.floor((S.Wings.PropSize or 1) * 10 + 0.5), function(v) S.Wings.PropSize = v / 10 debounce("Wings", function() rebuild("Wings") end) end)
    sec:AddSlider("Ring Speed x10", 2, 60, math.floor((S.Wings.PropSpeed or 1) * 10 + 0.5), function(v) S.Wings.PropSpeed = v / 10 end)
    sec:AddToggle("Ring halo echo (second ring)", function(v) S.Wings.PropRing = v and 2 or 1 rebuild("Wings") end)
    sec:AddToggle("Ring glow light", function(v) S.Wings.PropGlow = v rebuild("Wings") end)

    sec = PF_UI.section("Halo")
    sec:AddToggle("Enable halo", function(v) S.Halo.Enabled = v rebuild("Halo") end)
    sec:AddDropdown("Style", Halo.Styles, function(v) S.Halo.Style = v if S.Halo.Enabled then Halo.build() end end)
    sec:AddColorpicker("Color", S.Halo.Color, function(c) setColor("Halo", c) end)
    sec:AddSlider("Speed x10", 0, 40, x10(S.Halo.Speed), function(v) S.Halo.Speed = v / 10 end)
    sec:AddSlider("Height x100", 60, 220, math.floor(S.Halo.Height * 100 + 0.5), function(v) S.Halo.Height = v / 100 debounce("Halo", function() rebuild("Halo") end) end)
    sec:AddSlider("Tilt (deg)", 0, 45, S.Halo.Tilt, function(v) S.Halo.Tilt = v debounce("Halo", function() rebuild("Halo") end) end)
    sec:AddToggle("Glow light", function(v) S.Halo.Glow = v rebuild("Halo") end)
    sec:AddToggle("Satellites (orbiting sparks)", function(v) S.Halo.Satellites = v rebuild("Halo") end)
    sec:AddToggle("Mood (dims & sags at low HP)", function(v) S.Halo.Mood = v end)

    sec = PF_UI.section("Hat")
    sec:AddToggle("Enable hat", function(v) S.Hat.Enabled = v rebuild("Hat") end)
    sec:AddDropdown("Style", Hat.Styles, function(v) S.Hat.Style = v if S.Hat.Enabled then Hat.build() end end)
    sec:AddColorpicker("Color", S.Hat.Color, function(c) setColor("Hat", c) end)
    sec:AddSlider("Size x10", 5, 20, x10(S.Hat.Size), function(v) S.Hat.Size = v / 10 debounce("Hat", function() rebuild("Hat") end) end)
    sec:AddSlider("Spin x10", 0, 30, x10(S.Hat.Spin), function(v) S.Hat.Spin = v / 10 end)
    sec:AddToggle("Glow light", function(v) S.Hat.Glow = v rebuild("Hat") end)
    sec:AddToggle("Fringe (hanging sparks)", function(v) S.Hat.Fringe = v rebuild("Hat") end)
    sec:AddToggle("Bob (gentle bounce)", function(v) S.Hat.Bob = v end)

    sec = PF_UI.section("Sky")
    sec:AddDropdown("Preset", Sky.Order, function(v) S.SkyState.Preset = v Sky.select(v) notify("Sky: " .. v, 1.5) end)
    sec:AddDropdown("Skybox override", Sky.SkyboxOrder, function(v) S.SkyState.Skybox = v Sky.refresh() end)
    sec:AddDropdown("Clouds", Sky.CloudOrder, function(v) S.SkyState.Clouds = v Sky.refresh() end)
    sec:AddDropdown("Color filter", Sky.FilterOrder, function(v) Sky.applyFilter(v) end)
    sec:AddToggle("Smooth transitions", function(v) S.SkyState.Smooth = v Sky.smooth = v end)
    sec:AddSlider("Skybox spin (deg/s)", 0, 20, S.SkyState.Spin, function(v) S.SkyState.Spin = v Sky.setSpin(v) end)
    sec:AddDropdown("Weather", Sky.WeatherOrder, function(v) S.SkyState.Weather = v Sky.setWeather(v) notify("Weather: " .. v, 1.5) end)
    sec:AddSlider("Weather intensity x10", 2, 30, x10(Sky.weather.intensity), function(v) S.SkyState.Intensity = v / 10 debounce("Weather", function() Sky.setWeatherIntensity(v / 10) end, 0.4) end)
    sec:AddSlider("Wind (0 west · 10 calm · 20 east)", 0, 20, 10, function(v) S.SkyState.Wind = (v - 10) / 10 debounce("Weather", function() Sky.setWind((v - 10) / 10) end, 0.4) end)
    sec:AddToggle("Wind gusts (GlobalWind: grass, leaves, smoke)", function(v) S.SkyState.Gusts = v Sky.setGusts(v) end)
    sec:AddToggle("Day/night cycle", function(v) S.SkyState.Cycle = v Sky.setCycle(v) end)
    sec:AddSlider("Cycle speed x10", 1, 50, x10(Sky.cycle.speed), function(v) S.SkyState.CycleSpeed = v / 10 Sky.cycle.speed = v / 10 end)
    sec:AddButton("↺ Restore original lighting", function() S.SkyState.Preset = "Default" S.SkyState.Skybox = "Preset default" S.SkyState.Clouds = "Preset default" Sky.applyFilter("None") Sky.restore() notify("Lighting restored", 1.5) end)
    label(sec, "Client-side only: nobody else sees your sky")

    sec = PF_UI.section("Trails")
    sec:AddToggle("Enable trails", function(v) S.Trails.Enabled = v rebuild("Trails") end)
    sec:AddDropdown("Style", Trails.Styles, function(v)
    	S.Trails.Style = v
    	local sc = Trails.StyleColors[v]
    	if sc and not S.Trails.Custom then S.Trails.Color, S.Trails.Color2 = sc[1], sc[2] end
    	if S.Trails.Enabled then Trails.build() end
    end)
    sec:AddColorpicker("Color A", S.Trails.Color, function(c) setColor("Trails", c) end)
    sec:AddColorpicker("Color B", S.Trails.Color2, function(c) S.Trails.Color2 = c S.Trails.Custom = true if Trails.built then debounce("colorTrails2", function() rebuild("Trails") end) end end)
    sec:AddSlider("Width x10", 2, 40, x10(S.Trails.Width), function(v) S.Trails.Width = v / 10 debounce("Trails", function() rebuild("Trails") end) end)
    sec:AddSlider("Lifetime x10", 1, 30, x10(S.Trails.Lifetime), function(v) S.Trails.Lifetime = v / 10 debounce("Trails", function() rebuild("Trails") end) end)
    sec:AddToggle("Rainbow", function(v) S.Trails.Rainbow = v rebuild("Trails") end)
    sec:AddToggle("Echo (second ghost trail)", function(v) S.Trails.Echo = v rebuild("Trails") end)
    sec:AddToggle("Limb trails", function(v) S.Trails.Limbs = v rebuild("Trails") end)
    sec:AddToggle("Speed reactive", function(v) S.Trails.SpeedReactive = v end)
    sec:AddToggle("Sparks", function(v) S.Trails.Sparks = v rebuild("Trails") end)
    sec:AddButton("↺ Reset trail colors to style defaults", function() S.Trails.Custom = false local sc = Trails.StyleColors[S.Trails.Style] if sc then S.Trails.Color, S.Trails.Color2 = sc[1], sc[2] end S.Trails.Palette = nil rebuild("Trails") end)

    sec = PF_UI.section("MM2 Kill FX")
    sec:AddToggle("Enable kill FX", function(v) S.Kill.Enabled = v if v then Kill.build() else Kill.stop() end end)
    sec:AddDropdown("Style", Kill.Styles, function(v) S.Kill.Style = v end)
    sec:AddColorpicker("Color", S.Kill.Color, function(c) setColor("Kill", c) end)
    sec:AddSlider("Size x10", 5, 25, x10(S.Kill.Size), function(v) S.Kill.Size = v / 10 end)
    sec:AddSlider("Max distance (0 = any)", 0, 300, S.Kill.Range, function(v) S.Kill.Range = v end)
    sec:AddToggle("Flash light", function(v) S.Kill.Flash = v end)
    sec:AddToggle("Kill counter notify", function(v) S.Kill.Counter = v end)
    sec:AddToggle("Streak rings (2+ kills in 8s)", function(v) S.Kill.Streak = v end)
    sec:AddToggle("Also on my own death", function(v) S.Kill.OnSelf = v end)
    sec:AddButton("▶ Preview on myself", function() Kill.preview() end)
    label(sec, "Triggers when any other player's Humanoid dies near you")

    sec = PF_UI.section("Anya-Port FX")
    sec:AddToggle("Aura trailer (energy wake)", function(v) S.AuraTrailer.Enabled = v rebuild("AuraTrailer") end)
    sec:AddColorpicker("Aura trailer Color", S.AuraTrailer.Color, function(c)
    	S.AuraTrailer.Color = c
    	auraTrailerRecolor()
    end)
    sec:AddSlider("Aura trail Length x10", 10, 90, math.floor((S.AuraTrailer.Length or 4) * 10 + 0.5), function(v)
    	S.AuraTrailer.Length = v / 10
    	rebuild("AuraTrailer")
    end)
    sec:AddSlider("Aura trail Width x10", 4, 25, math.floor((S.AuraTrailer.Width or 1.1) * 10 + 0.5), function(v)
    	S.AuraTrailer.Width = v / 10
    	rebuild("AuraTrailer")
    end)
    sec:AddToggle("Aura trail sparks", function(v) S.AuraTrailer.Sparks = v rebuild("AuraTrailer") end)

    sec:AddToggle("Forcefield (repaint rig)", function(v) S.Forcefield.Enabled = v if v then Forcefield.build() else Forcefield.stop() end end)
    sec:AddColorpicker("Forcefield Color", S.Forcefield.Color, function(c)
    	S.Forcefield.Color = c
    	Forcefield.repaintAll()
    end)

    sec:AddToggle("Particle aura", function(v) S.ParticleAura.Enabled = v rebuild("ParticleAura") end)
    sec:AddDropdown("Particle aura Style", ParticleAura.Styles, function(v) S.ParticleAura.Style = v particleAuraRebuildStyle() end)
    sec:AddColorpicker("Particle aura Color", S.ParticleAura.Color, function(c) S.ParticleAura.Color = c particleAuraRebuildStyle() end)

    sec:AddToggle("Motion Echo", function(v) S.MotionEcho.Enabled = v if v then MotionEcho.build() else MotionEcho.stop() end end)
    sec:AddColorpicker("Echo Color", S.MotionEcho.Color, function(c) S.MotionEcho.Color = c if S.MotionEcho.Enabled then MotionEcho.build() end end)
    sec:AddSlider("Echo Lifetime x10", 1, 20, math.floor((S.MotionEcho.Lifetime or 0.45) * 10 + 0.5), function(v) S.MotionEcho.Lifetime = v / 10 end)
    sec:AddSlider("Echo Interval x100", 3, 30, math.floor((S.MotionEcho.Interval or 0.09) * 100 + 0.5), function(v) S.MotionEcho.Interval = v / 100 end)
    sec:AddSlider("Echo opacity %", 10, 90, math.floor((1 - (S.MotionEcho.Transparency or 0.45)) * 100 + 0.5), function(v) S.MotionEcho.Transparency = (100 - v) / 100 if S.MotionEcho.Enabled then MotionEcho.build() end end)

    sec = PF_UI.section("Screen FX")
    sec:AddToggle("Enable screen particles", function(v) S.ScreenFX.Enabled = v rebuild("ScreenFX") end)
    sec:AddDropdown("Style", ScreenFX.Styles, function(v) S.ScreenFX.Style = v if S.ScreenFX.Enabled then ScreenFX.build() end end)
    sec:AddColorpicker("Color", S.ScreenFX.Color, function(c) setColor("ScreenFX", c) end)
    sec:AddSlider("Rate", 5, 90, S.ScreenFX.Rate, function(v) S.ScreenFX.Rate = v end)
    sec:AddSlider("Size x10", 3, 30, x10(S.ScreenFX.Size), function(v) S.ScreenFX.Size = v / 10 end)
    sec:AddSlider("Speed x10", 2, 30, x10(S.ScreenFX.Speed), function(v) S.ScreenFX.Speed = v / 10 end)
    label(sec, "2D particles on your own screen only (rParticle / UIParticle style):")
    label(sec, "Sparks, Embers, Snowfall, Rain Streaks, Glitch, Speed Lines")

    sec = PF_UI.section("🎨 Color Presets")
    sec:AddDropdown("Target", COLOR_TARGETS, function(v) Colors.target = v end)
    sec:AddDropdown("Preset → target", Colors.presetNames, function(v)
    	for i, nm in ipairs(Colors.presetNames) do
    		if nm == v then Colors.apply(Colors.target, COLOR_PRESETS[i]) notify(nm .. " → " .. Colors.target, 1.5) break end
    	end
    end)
    sec:AddDropdown("Preset → ALL", Colors.presetNames, function(v)
    	for i, nm in ipairs(Colors.presetNames) do
    		if nm == v then for _, t in ipairs(COLOR_TARGETS) do Colors.apply(t, COLOR_PRESETS[i]) end notify(nm .. " → ALL", 1.5) break end
    	end
    end)
    sec:AddButton("🎲 Random preset → target", function() local p = pick(COLOR_PRESETS) Colors.apply(Colors.target, p) notify(p.icon .. " " .. p.name .. " → " .. Colors.target, 1.5) end)
    sec:AddButton("🎲 Random preset → ALL", function() local p = pick(COLOR_PRESETS) for _, t in ipairs(COLOR_TARGETS) do Colors.apply(t, p) end notify(p.icon .. " " .. p.name .. " → ALL", 1.5) end)
    sec:AddToggle("🌈 Rainbow on target", function(v) Colors.rainbow(Colors.target, v) end)
    sec:AddToggle("🌈 Rainbow on ALL", function(v) for _, t in ipairs(COLOR_TARGETS) do Colors.rainbow(t, v) end end)
    sec:AddDropdown("Rainbow speed", Colors.speedNames, function(v)
    	for i, sp in ipairs(RAINBOW_SPEEDS) do if sp.label == v then Colors.speed = sp.v end end
    end)
    sec:AddButton("↺ Reset target colors", function() Colors.reset(Colors.target) notify("Colors reset: " .. Colors.target, 1.5) end)

    sec = PF_UI.section("✨ Extras")
    sec:AddToggle("Glow light", function(v) S.Glow.Enabled = v rebuild("Glow") end)
    sec:AddColorpicker("Glow color", S.Glow.Color, function(c) setColor("Glow", c) end)
    sec:AddSlider("Glow range", 4, 40, S.Glow.Range, function(v) S.Glow.Range = v end)
    sec:AddSlider("Glow brightness x10", 2, 60, x10(S.Glow.Brightness), function(v) S.Glow.Brightness = v / 10 end)
    sec:AddToggle("Glow pulse", function(v) S.Glow.Pulse = v end)
    sec:AddToggle("Glow hue drift", function(v) S.Glow.Shift = v end)
    sec:AddToggle("Glow outline (Highlight)", function(v) S.Glow.Outline = v rebuild("Glow") end)
    sec:AddToggle("Glow follows HP", function(v) S.Glow.HPLink = v end)
    sec:AddToggle("Second head light", function(v) S.Glow.Second = v rebuild("Glow") end)
    sec:AddToggle("Glow bloom sprite (soft halo)", function(v) S.Glow.Bloom = v rebuild("Glow") end)
    sec:AddToggle("Glow casts shadows (costly)", function(v) S.Glow.Shadows = v rebuild("Glow") end)
    sec:AddToggle("Aura", function(v) S.Aura.Enabled = v rebuild("Aura") end)
    sec:AddDropdown("Aura shape", Aura.Shapes, function(v) S.Aura.Shape = v if S.Aura.Enabled then Aura.build() end end)
    sec:AddColorpicker("Aura color", S.Aura.Color, function(c) setColor("Aura", c) end)
    sec:AddSlider("Aura count", 3, 16, S.Aura.Count, function(v) S.Aura.Count = v debounce("Aura", function() rebuild("Aura") end) end)
    sec:AddSlider("Aura radius x10", 10, 80, x10(S.Aura.Radius), function(v) S.Aura.Radius = v / 10 debounce("Aura", function() rebuild("Aura") end) end)
    sec:AddSlider("Aura speed x10", 1, 40, x10(S.Aura.Speed), function(v) S.Aura.Speed = v / 10 end)
    sec:AddToggle("Footprints", function(v) S.Foot.Enabled = v rebuild("Foot") end)
    sec:AddDropdown("Footprint style", Foot.Styles, function(v) S.Foot.Style = v end)
    sec:AddColorpicker("Footprint color", S.Foot.Color, function(c) setColor("Foot", c) end)
    sec:AddSlider("Footprint interval x100", 10, 80, math.floor(S.Foot.Interval * 100 + 0.5), function(v) S.Foot.Interval = v / 100 end)
    sec:AddSlider("Footprint size x10", 4, 25, x10(S.Foot.Size), function(v) S.Foot.Size = v / 10 end)
    sec:AddToggle("Footprint sparks", function(v) S.Foot.Sparks = v end)
    sec:AddToggle("Footprint dust puffs", function(v) S.Foot.Dust = v end)
    sec:AddToggle("Idle spin (halo & hat)", function(v) S.Spin.Enabled = v end)
    sec:AddSlider("Spin speed x10", 1, 40, x10(S.Spin.Speed), function(v) S.Spin.Speed = v / 10 end)
    sec:AddToggle("Spin wobble", function(v) S.Spin.Wobble = v end)
    sec:AddToggle("Pet", function(v) S.Pet.Enabled = v rebuild("Pet") end)
    sec:AddDropdown("Pet style", Pet.Styles, function(v) S.Pet.Style = v if S.Pet.Enabled then Pet.build() end end)
    sec:AddDropdown("Pet motion", Pet.Motions, function(v) S.Pet.Motion = v end)
    sec:AddColorpicker("Pet color", S.Pet.Color, function(c) setColor("Pet", c) end)
    sec:AddSlider("Pet size x10", 2, 15, x10(S.Pet.Size), function(v) S.Pet.Size = v / 10 debounce("Pet", function() rebuild("Pet") end) end)
    sec:AddSlider("Pet distance x10", 15, 80, x10(S.Pet.Distance), function(v) S.Pet.Distance = v / 10 end)
    sec:AddSlider("Pet height x10", 0, 80, x10(S.Pet.Height), function(v) S.Pet.Height = v / 10 end)
    sec:AddSlider("Pet speed x10", 2, 40, x10(S.Pet.Speed), function(v) S.Pet.Speed = v / 10 end)
    sec:AddToggle("Pet trail", function(v) S.Pet.Trail = v rebuild("Pet") end)
    sec:AddToggle("Pet leash (beam to you)", function(v) S.Pet.Leash = v rebuild("Pet") end)
    sec:AddToggle("Pet reacts to events", function(v) S.Pet.React = v end)

    sec = PF_UI.section("⚙️ Performance")
    sec:AddSlider("Quality %", 20, 100, S.Perf.Quality, function(v) Perf.setQuality(v) end)
    sec:AddDropdown("Animation FPS cap", Perf.caps, function(v) Perf.setCap(v) end)
    sec:AddButton("📊 Show effect stats", function() notify(Perf.stats(), 4) end)
    sec:AddButton("🧹 Rebuild all active effects", function() rebuildAll() notify("Effects rebuilt", 1.5) end)
    sec:AddButton("⏏ Unload PrismFlux (remove everything)", function() ODHX.Stop() notify("PrismFlux unloaded", 2) end)
    label(sec, IS_PHONE and "Phone detected → quality starts at 55%" or "Desktop detected → quality starts at 100%")

    sec = PF_UI.section("💾 Profiles")
    sec:AddDropdown("Slot", Profiles.Slots, function(v) Profiles.slot = v end)
    sec:AddButton("💾 Save settings → slot", function() local _, msg = Profiles.save(Profiles.slot) notify(msg, 2) end)
    sec:AddButton("📂 Load settings ← slot", function() local _, msg = Profiles.load(Profiles.slot) notify(msg, 2) end)
    sec:AddButton("↺ Reset everything to defaults", function() local _, msg = Profiles.reset() notify(msg, 2) end)
    sec:AddToggle("Auto-load this slot on start", function(v) notify(Profiles.setAutoload(v), 2) end)
    label(sec, "Last-session settings are saved automatically. Manual slots remain independent.")

    SR_Log("PrismFlux Zero-Part v4 loaded")

    ODHX.Bind("Jump FX", "Enable jump FX", "Toggle", function() return S.Jump.Enabled end)
    ODHX.Bind("Jump FX", "Style", "Dropdown", function() return S.Jump.Style end)
    ODHX.Bind("Jump FX", "Color", "Colorpicker", function() return S.Jump.Color end)
    ODHX.Bind("Jump FX", "Size", "Slider", function() return S.Jump.Size end)
    ODHX.Bind("Jump FX", "Duration x10", "Slider", function() return x10(S.Jump.Duration) end)
    ODHX.Bind("Jump FX", "Ground flash", "Toggle", function() return S.Jump.Flash end)
    ODHX.Bind("Jump FX", "Sparks", "Toggle", function() return S.Jump.Sparks end)
    ODHX.Bind("Jump FX", "Light column", "Toggle", function() return S.Jump.Column end)
    ODHX.Bind("Jump FX", "Echo ring", "Toggle", function() return S.Jump.Echo end)
    ODHX.Bind("Jump FX", "Combo chain (grows on bunny-hops)", "Toggle", function() return S.Jump.Chain end)
    ODHX.Bind("Jump FX", "Random style each jump", "Toggle", function() return S.Jump.Random end)
    ODHX.Bind("Jump FX", "Mid-air (double jump) ring", "Toggle", function() return S.Jump.DoubleAir end)
    ODHX.Bind("Wings", "Enable wings", "Toggle", function() return S.Wings.Enabled end)
    ODHX.Bind("Wings", "Style", "Dropdown", function() return S.Wings.Style end)
    ODHX.Bind("Wings", "Color", "Colorpicker", function() return S.Wings.Color end)
    ODHX.Bind("Wings", "Size x10", "Slider", function() return x10(S.Wings.Scale) end)
    ODHX.Bind("Wings", "Droop (deg)", "Slider", function() return S.Wings.Droop end)
    ODHX.Bind("Wings", "Flapping", "Toggle", function() return S.Wings.Flap end)
    ODHX.Bind("Wings", "Glow light", "Toggle", function() return S.Wings.Glow end)
    ODHX.Bind("Wings", "Dust / feathers", "Toggle", function() return S.Wings.Dust end)
    ODHX.Bind("Wings", "Dynamic (spread on jump/run)", "Toggle", function() return S.Wings.Dynamic end)
    ODHX.Bind("Wings", "Tip trails", "Toggle", function() return S.Wings.TipTrails end)
    ODHX.Bind("Wings", "Energy ring behind wings", "Toggle", function() return S.Wings.Prop end)
    ODHX.Bind("Wings", "Prop ring Style", "Dropdown", function() return S.Wings.PropStyle end)
    ODHX.Bind("Wings", "Ring Size x10", "Slider", function() return math.floor((S.Wings.PropSize or 1) * 10 + 0.5) end)
    ODHX.Bind("Wings", "Ring Speed x10", "Slider", function() return math.floor((S.Wings.PropSpeed or 1) * 10 + 0.5) end)
    ODHX.Bind("Wings", "Ring halo echo (second ring)", "Toggle", function() return S.Wings.PropRing end)
    ODHX.Bind("Wings", "Ring glow light", "Toggle", function() return S.Wings.PropGlow end)
    ODHX.Bind("Halo", "Enable halo", "Toggle", function() return S.Halo.Enabled end)
    ODHX.Bind("Halo", "Style", "Dropdown", function() return S.Halo.Style end)
    ODHX.Bind("Halo", "Color", "Colorpicker", function() return S.Halo.Color end)
    ODHX.Bind("Halo", "Speed x10", "Slider", function() return x10(S.Halo.Speed) end)
    ODHX.Bind("Halo", "Height x100", "Slider", function() return math.floor(S.Halo.Height * 100 + 0.5) end)
    ODHX.Bind("Halo", "Tilt (deg)", "Slider", function() return S.Halo.Tilt end)
    ODHX.Bind("Halo", "Glow light", "Toggle", function() return S.Halo.Glow end)
    ODHX.Bind("Halo", "Satellites (orbiting sparks)", "Toggle", function() return S.Halo.Satellites end)
    ODHX.Bind("Halo", "Mood (dims & sags at low HP)", "Toggle", function() return S.Halo.Mood end)
    ODHX.Bind("Hat", "Enable hat", "Toggle", function() return S.Hat.Enabled end)
    ODHX.Bind("Hat", "Style", "Dropdown", function() return S.Hat.Style end)
    ODHX.Bind("Hat", "Color", "Colorpicker", function() return S.Hat.Color end)
    ODHX.Bind("Hat", "Size x10", "Slider", function() return x10(S.Hat.Size) end)
    ODHX.Bind("Hat", "Spin x10", "Slider", function() return x10(S.Hat.Spin) end)
    ODHX.Bind("Hat", "Glow light", "Toggle", function() return S.Hat.Glow end)
    ODHX.Bind("Hat", "Fringe (hanging sparks)", "Toggle", function() return S.Hat.Fringe end)
    ODHX.Bind("Hat", "Bob (gentle bounce)", "Toggle", function() return S.Hat.Bob end)
    ODHX.Bind("Sky", "Preset", "Dropdown", function() return S.SkyState.Preset end)
    ODHX.Bind("Sky", "Skybox override", "Dropdown", function() return S.SkyState.Skybox end)
    ODHX.Bind("Sky", "Clouds", "Dropdown", function() return S.SkyState.Clouds end)
    ODHX.Bind("Sky", "Smooth transitions", "Toggle", function() return S.SkyState.Smooth end)
    ODHX.Bind("Sky", "Skybox spin (deg/s)", "Slider", function() return S.SkyState.Spin end)
    ODHX.Bind("Sky", "Weather", "Dropdown", function() return S.SkyState.Weather end)
    ODHX.Bind("Sky", "Weather intensity x10", "Slider", function() return x10(Sky.weather.intensity) end)
    ODHX.Bind("Sky", "Wind (0 west · 10 calm · 20 east)", "Slider", function() return 10 end)
    ODHX.Bind("Sky", "Wind gusts (GlobalWind: grass, leaves, smoke)", "Toggle", function() return S.SkyState.Gusts end)
    ODHX.Bind("Sky", "Day/night cycle", "Toggle", function() return S.SkyState.Cycle end)
    ODHX.Bind("Sky", "Cycle speed x10", "Slider", function() return x10(Sky.cycle.speed) end)
    ODHX.Bind("Trails", "Enable trails", "Toggle", function() return S.Trails.Enabled end)
    ODHX.Bind("Trails", "Color A", "Colorpicker", function() return S.Trails.Color end)
    ODHX.Bind("Trails", "Color B", "Colorpicker", function() return S.Trails.Color2 end)
    ODHX.Bind("Trails", "Width x10", "Slider", function() return x10(S.Trails.Width) end)
    ODHX.Bind("Trails", "Lifetime x10", "Slider", function() return x10(S.Trails.Lifetime) end)
    ODHX.Bind("Trails", "Rainbow", "Toggle", function() return S.Trails.Rainbow end)
    ODHX.Bind("Trails", "Echo (second ghost trail)", "Toggle", function() return S.Trails.Echo end)
    ODHX.Bind("Trails", "Limb trails", "Toggle", function() return S.Trails.Limbs end)
    ODHX.Bind("Trails", "Speed reactive", "Toggle", function() return S.Trails.SpeedReactive end)
    ODHX.Bind("Trails", "Sparks", "Toggle", function() return S.Trails.Sparks end)
    ODHX.Bind("MM2 Kill FX", "Enable kill FX", "Toggle", function() return S.Kill.Enabled end)
    ODHX.Bind("MM2 Kill FX", "Style", "Dropdown", function() return S.Kill.Style end)
    ODHX.Bind("MM2 Kill FX", "Color", "Colorpicker", function() return S.Kill.Color end)
    ODHX.Bind("MM2 Kill FX", "Size x10", "Slider", function() return x10(S.Kill.Size) end)
    ODHX.Bind("MM2 Kill FX", "Max distance (0 = any)", "Slider", function() return S.Kill.Range end)
    ODHX.Bind("MM2 Kill FX", "Flash light", "Toggle", function() return S.Kill.Flash end)
    ODHX.Bind("MM2 Kill FX", "Kill counter notify", "Toggle", function() return S.Kill.Counter end)
    ODHX.Bind("MM2 Kill FX", "Streak rings (2+ kills in 8s)", "Toggle", function() return S.Kill.Streak end)
    ODHX.Bind("MM2 Kill FX", "Also on my own death", "Toggle", function() return S.Kill.OnSelf end)
    ODHX.Bind("Anya-Port FX", "Aura trailer (energy wake)", "Toggle", function() return S.AuraTrailer.Enabled end)
    ODHX.Bind("Anya-Port FX", "Aura trailer Color", "Colorpicker", function() return S.AuraTrailer.Color end)
    ODHX.Bind("Anya-Port FX", "Aura trail Length x10", "Slider", function() return math.floor((S.AuraTrailer.Length or 4) * 10 + 0.5) end)
    ODHX.Bind("Anya-Port FX", "Aura trail Width x10", "Slider", function() return math.floor((S.AuraTrailer.Width or 1.1) * 10 + 0.5) end)
    ODHX.Bind("Anya-Port FX", "Aura trail sparks", "Toggle", function() return S.AuraTrailer.Sparks end)
    ODHX.Bind("Anya-Port FX", "Forcefield (repaint rig)", "Toggle", function() return S.Forcefield.Enabled end)
    ODHX.Bind("Anya-Port FX", "Forcefield Color", "Colorpicker", function() return S.Forcefield.Color end)
    ODHX.Bind("Anya-Port FX", "Particle aura", "Toggle", function() return S.ParticleAura.Enabled end)
    ODHX.Bind("Anya-Port FX", "Particle aura Style", "Dropdown", function() return S.ParticleAura.Style end)
    ODHX.Bind("Anya-Port FX", "Particle aura Color", "Colorpicker", function() return S.ParticleAura.Color end)
    ODHX.Bind("Anya-Port FX", "Motion Echo", "Toggle", function() return S.MotionEcho.Enabled end)
    ODHX.Bind("Anya-Port FX", "Echo Color", "Colorpicker", function() return S.MotionEcho.Color end)
    ODHX.Bind("Anya-Port FX", "Echo Lifetime x10", "Slider", function() return math.floor((S.MotionEcho.Lifetime or 0.45) * 10 + 0.5) end)
    ODHX.Bind("Anya-Port FX", "Echo Interval x100", "Slider", function() return math.floor((S.MotionEcho.Interval or 0.09) * 100 + 0.5) end)
    ODHX.Bind("Anya-Port FX", "Echo opacity %", "Slider", function() return math.floor((1 - (S.MotionEcho.Transparency or 0.45)) * 100 + 0.5) end)
    ODHX.Bind("Screen FX", "Enable screen particles", "Toggle", function() return S.ScreenFX.Enabled end)
    ODHX.Bind("Screen FX", "Style", "Dropdown", function() return S.ScreenFX.Style end)
    ODHX.Bind("Screen FX", "Color", "Colorpicker", function() return S.ScreenFX.Color end)
    ODHX.Bind("Screen FX", "Rate", "Slider", function() return S.ScreenFX.Rate end)
    ODHX.Bind("Screen FX", "Size x10", "Slider", function() return x10(S.ScreenFX.Size) end)
    ODHX.Bind("Screen FX", "Speed x10", "Slider", function() return x10(S.ScreenFX.Speed) end)
    ODHX.Bind("🎨 Color Presets", "Target", "Dropdown", function() return Colors.target end)
    ODHX.Bind("✨ Extras", "Glow light", "Toggle", function() return S.Glow.Enabled end)
    ODHX.Bind("✨ Extras", "Glow color", "Colorpicker", function() return S.Glow.Color end)
    ODHX.Bind("✨ Extras", "Glow range", "Slider", function() return S.Glow.Range end)
    ODHX.Bind("✨ Extras", "Glow brightness x10", "Slider", function() return x10(S.Glow.Brightness) end)
    ODHX.Bind("✨ Extras", "Glow pulse", "Toggle", function() return S.Glow.Pulse end)
    ODHX.Bind("✨ Extras", "Glow hue drift", "Toggle", function() return S.Glow.Shift end)
    ODHX.Bind("✨ Extras", "Glow outline (Highlight)", "Toggle", function() return S.Glow.Outline end)
    ODHX.Bind("✨ Extras", "Glow follows HP", "Toggle", function() return S.Glow.HPLink end)
    ODHX.Bind("✨ Extras", "Second head light", "Toggle", function() return S.Glow.Second end)
    ODHX.Bind("✨ Extras", "Glow bloom sprite (soft halo)", "Toggle", function() return S.Glow.Bloom end)
    ODHX.Bind("✨ Extras", "Glow casts shadows (costly)", "Toggle", function() return S.Glow.Shadows end)
    ODHX.Bind("✨ Extras", "Aura", "Toggle", function() return S.Aura.Enabled end)
    ODHX.Bind("✨ Extras", "Aura shape", "Dropdown", function() return S.Aura.Shape end)
    ODHX.Bind("✨ Extras", "Aura color", "Colorpicker", function() return S.Aura.Color end)
    ODHX.Bind("✨ Extras", "Aura count", "Slider", function() return S.Aura.Count end)
    ODHX.Bind("✨ Extras", "Aura radius x10", "Slider", function() return x10(S.Aura.Radius) end)
    ODHX.Bind("✨ Extras", "Aura speed x10", "Slider", function() return x10(S.Aura.Speed) end)
    ODHX.Bind("✨ Extras", "Footprints", "Toggle", function() return S.Foot.Enabled end)
    ODHX.Bind("✨ Extras", "Footprint style", "Dropdown", function() return S.Foot.Style end)
    ODHX.Bind("✨ Extras", "Footprint color", "Colorpicker", function() return S.Foot.Color end)
    ODHX.Bind("✨ Extras", "Footprint interval x100", "Slider", function() return math.floor(S.Foot.Interval * 100 + 0.5) end)
    ODHX.Bind("✨ Extras", "Footprint size x10", "Slider", function() return x10(S.Foot.Size) end)
    ODHX.Bind("✨ Extras", "Footprint sparks", "Toggle", function() return S.Foot.Sparks end)
    ODHX.Bind("✨ Extras", "Footprint dust puffs", "Toggle", function() return S.Foot.Dust end)
    ODHX.Bind("✨ Extras", "Idle spin (halo & hat)", "Toggle", function() return S.Spin.Enabled end)
    ODHX.Bind("✨ Extras", "Spin speed x10", "Slider", function() return x10(S.Spin.Speed) end)
    ODHX.Bind("✨ Extras", "Spin wobble", "Toggle", function() return S.Spin.Wobble end)
    ODHX.Bind("✨ Extras", "Pet", "Toggle", function() return S.Pet.Enabled end)
    ODHX.Bind("✨ Extras", "Pet style", "Dropdown", function() return S.Pet.Style end)
    ODHX.Bind("✨ Extras", "Pet motion", "Dropdown", function() return S.Pet.Motion end)
    ODHX.Bind("✨ Extras", "Pet color", "Colorpicker", function() return S.Pet.Color end)
    ODHX.Bind("✨ Extras", "Pet size x10", "Slider", function() return x10(S.Pet.Size) end)
    ODHX.Bind("✨ Extras", "Pet distance x10", "Slider", function() return x10(S.Pet.Distance) end)
    ODHX.Bind("✨ Extras", "Pet height x10", "Slider", function() return x10(S.Pet.Height) end)
    ODHX.Bind("✨ Extras", "Pet speed x10", "Slider", function() return x10(S.Pet.Speed) end)
    ODHX.Bind("✨ Extras", "Pet trail", "Toggle", function() return S.Pet.Trail end)
    ODHX.Bind("✨ Extras", "Pet leash (beam to you)", "Toggle", function() return S.Pet.Leash end)
    ODHX.Bind("✨ Extras", "Pet reacts to events", "Toggle", function() return S.Pet.React end)
    ODHX.Bind("⚙️ Performance", "Quality %", "Slider", function() return S.Perf.Quality end)
    ODHX.Bind("💾 Profiles", "Slot", "Dropdown", function() return Profiles.slot end)
    ODHX.Bind("⚙️ Performance", "Animation FPS cap", "Dropdown", function() return S.Perf.Cap end)
    ODHX.Bind("💾 Profiles", "Auto-load this slot on start", "Toggle", function() return Profiles.autoload end)
    ODHX.Bind("Sky", "Color filter", "Dropdown", function() return S.SkyState.Filter end)
    ODHX.Bind("Sky", "Wind (0 west · 10 calm · 20 east)", "Slider", function() return S.SkyState.Wind * 10 + 10 end)
    ODHX.Bind("Sky", "Weather intensity x10", "Slider", function() return x10(S.SkyState.Intensity) end)
    ODHX.Bind("Trails", "Style", "Dropdown", function() return S.Trails.Style end)
    ODHX.Bind("🎨 Color Presets", "🌈 Rainbow on target", "Toggle", function() return Colors.on[Colors.target] == true end)
    ODHX.Bind("🎨 Color Presets","🌈 Rainbow on ALL","Toggle",function()
        for _,target in ipairs(COLOR_TARGETS) do if not Colors.on[target] then return false end end
        return true
    end)
    ODHX.Bind("🎨 Color Presets","Rainbow speed","Dropdown",function()
        for _,sp in ipairs(RAINBOW_SPEEDS) do if sp.v==Colors.speed then return sp.label end end
    end)
    ODHX.cleanup=unloadAll
    ODHX.Finish()

end
end)

SR_UI.tryModule("shiftlock_color", function()
do
    local ODHX = CreateODHX("shiftlock_color", "Shiftlock Crosshair", "ODH_shiftlock_color_settings.json", false, false)

    local shared = ODHX.shared
    local Players = SR_UI.service("Players")
    local RunService = SR_UI.service("RunService")

    local GLOW_PRESETS = {
        {
            name = "Obsidian",
            icon = "🪨",
            colors = {
                Color3.fromRGB(60, 40, 120),
                Color3.fromRGB(120, 80, 200),
                Color3.fromRGB(80, 60, 160),
                Color3.fromRGB(40, 30, 100),
                Color3.fromRGB(60, 40, 120),
            },
        },
        {
            name = "Gold",
            icon = "✨",
            colors = {
                Color3.fromRGB(200, 150, 20),
                Color3.fromRGB(255, 215, 0),
                Color3.fromRGB(200, 150, 20),
                Color3.fromRGB(150, 100, 10),
                Color3.fromRGB(200, 150, 20),
            },
        },
        {
            name = "Neon",
            icon = "💜",
            colors = {
                Color3.fromRGB(150, 20, 200),
                Color3.fromRGB(200, 50, 255),
                Color3.fromRGB(150, 20, 200),
                Color3.fromRGB(100, 10, 150),
                Color3.fromRGB(150, 20, 200),
            },
        },
        {
            name = "Cyber",
            icon = "💠",
            colors = {
                Color3.fromRGB(0, 100, 200),
                Color3.fromRGB(0, 200, 255),
                Color3.fromRGB(0, 100, 200),
                Color3.fromRGB(0, 50, 150),
                Color3.fromRGB(0, 100, 200),
            },
        },
        {
            name = "Crimson",
            icon = "❤️",
            colors = {
                Color3.fromRGB(200, 20, 20),
                Color3.fromRGB(255, 50, 50),
                Color3.fromRGB(200, 20, 20),
                Color3.fromRGB(150, 10, 10),
                Color3.fromRGB(200, 20, 20),
            },
        },
        {
            name = "Emerald",
            icon = "💚",
            colors = {
                Color3.fromRGB(20, 200, 60),
                Color3.fromRGB(50, 255, 100),
                Color3.fromRGB(20, 200, 60),
                Color3.fromRGB(10, 150, 40),
                Color3.fromRGB(20, 200, 60),
            },
        },
        {
            name = "Ocean",
            icon = "🌊",
            colors = {
                Color3.fromRGB(20, 80, 200),
                Color3.fromRGB(50, 150, 255),
                Color3.fromRGB(20, 80, 200),
                Color3.fromRGB(10, 50, 150),
                Color3.fromRGB(20, 80, 200),
            },
        },
        {
            name = "Sunset",
            icon = "🌅",
            colors = {
                Color3.fromRGB(200, 80, 20),
                Color3.fromRGB(255, 150, 50),
                Color3.fromRGB(200, 80, 20),
                Color3.fromRGB(150, 50, 10),
                Color3.fromRGB(200, 80, 20),
            },
        },
        {
            name = "Platinum",
            icon = "⚪",
            colors = {
                Color3.fromRGB(120, 120, 160),
                Color3.fromRGB(200, 200, 220),
                Color3.fromRGB(120, 120, 160),
                Color3.fromRGB(80, 80, 120),
                Color3.fromRGB(120, 120, 160),
            },
        },
        {
            name = "Ice",
            icon = "❄️",
            colors = {
                Color3.fromRGB(80, 180, 220),
                Color3.fromRGB(150, 220, 255),
                Color3.fromRGB(80, 180, 220),
                Color3.fromRGB(40, 120, 180),
                Color3.fromRGB(80, 180, 220),
            },
        },
        {
            name = "Lava",
            icon = "🌋",
            colors = {
                Color3.fromRGB(200, 50, 0),
                Color3.fromRGB(255, 100, 20),
                Color3.fromRGB(200, 50, 0),
                Color3.fromRGB(150, 30, 0),
                Color3.fromRGB(200, 50, 0),
            },
        },
        {
            name = "Dark",
            icon = "🌑",
            colors = {
                Color3.fromRGB(50, 50, 70),
                Color3.fromRGB(100, 100, 120),
                Color3.fromRGB(50, 50, 70),
                Color3.fromRGB(30, 30, 50),
                Color3.fromRGB(50, 50, 70),
            },
        },
        {
            name = "Electric Purple",
            icon = "💜",
            colors = {
                Color3.fromRGB(157, 0, 255),
                Color3.fromRGB(120, 0, 200),
                Color3.fromRGB(80, 0, 150),
                Color3.fromRGB(46, 10, 78),
                Color3.fromRGB(157, 0, 255),
            },
        },
        {
            name = "Monochrome",
            icon = "⚫",
            colors = {
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(169, 169, 169),
                Color3.fromRGB(100, 100, 100),
                Color3.fromRGB(30, 30, 30),
                Color3.fromRGB(255, 255, 255),
            },
        },
        {
            name = "Cosmic Red",
            icon = "❤️",
            colors = {
                Color3.fromRGB(255, 0, 60),
                Color3.fromRGB(200, 0, 50),
                Color3.fromRGB(128, 0, 32),
                Color3.fromRGB(26, 0, 10),
                Color3.fromRGB(255, 0, 60),
            },
        },
        {
            name = "Cosmic Blue",
            icon = "💙",
            colors = {
                Color3.fromRGB(0, 102, 255),
                Color3.fromRGB(0, 70, 200),
                Color3.fromRGB(0, 26, 102),
                Color3.fromRGB(0, 11, 51),
                Color3.fromRGB(0, 102, 255),
            },
        },
        {
            name = "Amethyst",
            icon = "💎",
            colors = {
                Color3.fromRGB(200, 150, 255),
                Color3.fromRGB(160, 100, 220),
                Color3.fromRGB(120, 60, 180),
                Color3.fromRGB(80, 30, 120),
                Color3.fromRGB(200, 150, 255),
            },
        },
        {
            name = "Slate Gray",
            icon = "🛻",
            colors = {
                Color3.fromRGB(200, 200, 210),
                Color3.fromRGB(169, 169, 169),
                Color3.fromRGB(120, 120, 130),
                Color3.fromRGB(60, 60, 70),
                Color3.fromRGB(200, 200, 210),
            },
        },
        {
            name = "Midnight Blue",
            icon = "🌙",
            colors = {
                Color3.fromRGB(80, 150, 255),
                Color3.fromRGB(50, 100, 200),
                Color3.fromRGB(20, 50, 120),
                Color3.fromRGB(0, 10, 30),
                Color3.fromRGB(80, 150, 255),
            },
        },
        {
            name = "Toxic",
            icon = "☢️",
            colors = {
                Color3.fromRGB(100, 255, 0),
                Color3.fromRGB(160, 255, 60),
                Color3.fromRGB(80, 200, 0),
                Color3.fromRGB(40, 140, 0),
                Color3.fromRGB(100, 255, 0),
            },
        },
        {
            name = "Mint",
            icon = "🍃",
            colors = {
                Color3.fromRGB(100, 255, 200),
                Color3.fromRGB(150, 255, 220),
                Color3.fromRGB(80, 220, 180),
                Color3.fromRGB(50, 170, 140),
                Color3.fromRGB(100, 255, 200),
            },
        },
        {
            name = "Rose Gold",
            icon = "🌹",
            colors = {
                Color3.fromRGB(255, 183, 178),
                Color3.fromRGB(255, 210, 200),
                Color3.fromRGB(230, 160, 155),
                Color3.fromRGB(200, 130, 125),
                Color3.fromRGB(255, 183, 178),
            },
        },
        {
            name = "Aurora",
            icon = "🌌",
            colors = {
                Color3.fromRGB(0, 255, 150),
                Color3.fromRGB(100, 200, 255),
                Color3.fromRGB(180, 100, 255),
                Color3.fromRGB(255, 100, 200),
                Color3.fromRGB(0, 255, 150),
            },
        },
        {
            name = "Blood Moon",
            icon = "🩸",
            colors = {
                Color3.fromRGB(120, 0, 0),
                Color3.fromRGB(200, 30, 30),
                Color3.fromRGB(255, 60, 40),
                Color3.fromRGB(150, 10, 10),
                Color3.fromRGB(120, 0, 0),
            },
        },
        {
            name = "Void",
            icon = "🕳️",
            colors = {
                Color3.fromRGB(20, 0, 40),
                Color3.fromRGB(60, 0, 120),
                Color3.fromRGB(120, 0, 200),
                Color3.fromRGB(40, 0, 80),
                Color3.fromRGB(20, 0, 40),
            },
        },
    }

    local SPEED_PRESETS = {
        { label = "🐌 Slow",     value = 0.3 },
        { label = "🚶 Normal",   value = 0.8 },
        { label = "🏃 Fast",     value = 2.0 },
        { label = "⚡ Ultra",    value = 5.0 },
    }

    local PULSE_PRESETS = {
        { label = "🐢 Pulse Slow",   value = 0.8 },
        { label = "🚶 Pulse Normal", value = 2.0 },
        { label = "🏃 Pulse Fast",   value = 4.0 },
        { label = "⚡ Pulse Ultra",  value = 8.0 },
    }

    local WAVEFORMS = {
        { label = "〰️ Sine Wave",      key = "sine" },
        { label = "💨 Breath (smooth)", key = "breath" },
        { label = "📐 Triangle",       key = "triangle" },
        { label = "🟦 Pulse (hard)",   key = "pulse" },
    }

    local SCALE_AMPLITUDE_PRESETS = {
        { label = "🔸 Subtle Scale (+5%)",   value = 0.05 },
        { label = "🔸 Light Scale (+10%)",   value = 0.10 },
        { label = "🔶 Medium Scale (+20%)", value = 0.20 },
        { label = "🔶 Heavy Scale (+35%)",  value = 0.35 },
    }

    local TRANSPARENCY_DEPTH_PRESETS = {
        { label = "🔅 Faint Transparency (0.2)", value = 0.2 },
        { label = "🔆 Light Transparency (0.4)", value = 0.4 },
        { label = "🔆 Strong Transparency (0.6)", value = 0.6 },
        { label = "🌑 Deep Transparency (0.85)", value = 0.85 },
    }

    local TRAIL_COUNT_PRESETS = {
        { label = "👻 Trail x1", value = 1 },
        { label = "👻 Trail x2", value = 2 },
        { label = "👻 Trail x3", value = 3 },
        { label = "👻 Trail x5", value = 5 },
    }

    local CROSSHAIR_KEYWORDS = { "crosshair", "прицел", "aim", "reticle", "target", "cursor" }

    local SETTINGS_KEY = "ShiftlockCrosshair_v3_5_Settings"

    local state = {
        enabled = false,
        speed = SPEED_PRESETS[2].value,
        direction = 1,
        reversed = false,
        currentPreset = nil,
        customColors = nil,

    rainbowMode = false,
    rainbowSpeed = 1.0,

    pulsate = false,
    pulseSpeed = 2,
    pulseWaveform = "sine",
    pulseDepth = 0.4,

    scalePulse = false,
    scaleAmplitude = 0.10,

    trailEnabled = false,
    trailCount = 2,
    trailCopies = {},
    trailBuilding = false,

    targetObjects = {},
    originalProps = {},
    propsByObj = {},
    rotation = 0,
    offset = 0,
    pulsePhase = 0,
    rainbowHue = 0,

    renderConn = nil,
    addedConn = nil,
    removedConn = nil,

    }

    local WAVEFORM_FUNCS = {

        sine = function(phase)
            return math.sin(phase) * 0.5 + 0.5
        end,

        breath = function(phase)
            local s = math.sin(phase) * 0.5 + 0.5
            return s * s * (3 - 2 * s)
        end,

        triangle = function(phase)
            local p = phase % (math.pi * 2)
            if p < math.pi then
                return p / math.pi
            else
                return 1 - (p - math.pi) / math.pi
            end
        end,

        pulse = function(phase)
            return (math.sin(phase) > 0) and 1 or 0
        end,
    }

    local function getWaveformValue(phase, waveform)
        local fn = WAVEFORM_FUNCS[waveform] or WAVEFORM_FUNCS.sine
        return fn(phase)
    end

    local function captureSettings()
        return {
            enabled=state.enabled, speed=state.speed, reversed=state.reversed,
            pulsate=state.pulsate, pulseSpeed=state.pulseSpeed, pulseWaveform=state.pulseWaveform,
            pulseDepth=state.pulseDepth, rainbowMode=state.rainbowMode, rainbowSpeed=state.rainbowSpeed,
            scalePulse=state.scalePulse, scaleAmplitude=state.scaleAmplitude,
            trailEnabled=state.trailEnabled, trailCount=state.trailCount,
            customColors=state.customColors,
            presetName=state.currentPreset and state.currentPreset.name or nil,
        }
    end
    ODHX.capture=captureSettings
    local function saveSettings()
        _G[SETTINGS_KEY]=captureSettings()
        ODHX.Commit()
    end
    local function loadSettings()
        if type(ODHX.data.snapshot)=="table" then return ODHX.data.snapshot end
        local saved=_G[SETTINGS_KEY]
        return type(saved)=="table" and saved or nil
    end

    local function getActiveColors()
        if state.rainbowMode then
            return nil
        elseif state.customColors then
            return state.customColors
        elseif state.currentPreset then
            return state.currentPreset.colors
        end
        return GLOW_PRESETS[13].colors
    end

    local function buildColorSequence(colors)
        local keypoints = {}
        local count = #colors
        if count == 1 then
            return ColorSequence.new(colors[1])
        end
        local step = 1 / (count - 1)
        for i, color in ipairs(colors) do
            table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) * step, color))
        end
        return ColorSequence.new(keypoints)
    end

    local function buildRainbowColorSequence(hue)
        local keypoints = {}
        for i = 0, 4 do
            local h = (hue + i * 0.12) % 1
            local color = Color3.fromHSV(h, 1, 1)
            table.insert(keypoints, ColorSequenceKeypoint.new(i / 4, color))
        end
        return ColorSequence.new(keypoints)
    end

    local function isCrosshairObject(obj)
        if not (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then
            return false
        end
        local name = obj.Name:lower()

        if name:find("crosshairtrail_") then
            return false
        end
        for _, keyword in ipairs(CROSSHAIR_KEYWORDS) do
            if name:find(keyword) then
                return true
            end
        end
        return false
    end

    local function findCrosshairObjects()
        local objects = {}
        local player = Players.LocalPlayer
        local playerGui = player and player:FindFirstChild("PlayerGui")
        if not playerGui then
            return objects
        end
        for _, obj in ipairs(playerGui:GetDescendants()) do
            if isCrosshairObject(obj) then
                table.insert(objects, obj)
            end
        end
        return objects
    end

    local function ensureGradient(obj)
        local grad = obj:FindFirstChild("CrosshairGradient")
        if not grad then
            grad = Instance.new("UIGradient")
            grad.Name = "CrosshairGradient"
            grad.Parent = obj
        end
        return grad
    end

    local function saveOriginalProps(obj)
        if state.propsByObj[obj] then return end
        for _, entry in ipairs(state.originalProps) do
            if entry.obj == obj then
                state.propsByObj[obj] = entry
                return
            end
        end
        local record = {
            obj = obj,
            imageColor3 = obj.ImageColor3,
            imageTransparency = obj.ImageTransparency,
            rotation = obj.Rotation,
            size = obj.Size,
            position = obj.Position,
            anchorPoint = obj.AnchorPoint,
            parent = obj.Parent,
        }
        record.grad = obj:FindFirstChild("CrosshairGradient")
        table.insert(state.originalProps, record)
        state.propsByObj[obj] = record
    end

    local function restoreOriginalProps(obj)
        for _, entry in ipairs(state.originalProps) do
            if entry.obj == obj then
                pcall(function()
                    obj.ImageColor3 = entry.imageColor3
                    obj.ImageTransparency = entry.imageTransparency
                    obj.Rotation = entry.rotation
                    obj.Size = entry.size
                    obj.Position = entry.position
                    obj.AnchorPoint = entry.anchorPoint
                end)
                return
            end
        end
        pcall(function()
            obj.ImageColor3 = Color3.new(1, 1, 1)
            obj.ImageTransparency = 0
            obj.Rotation = 0
        end)
    end

    local function applyColors()
        if state.rainbowMode then
            local colorSeq = buildRainbowColorSequence(state.rainbowHue)
            for _, obj in ipairs(state.targetObjects) do
                pcall(function()
                    local grad = ensureGradient(obj)
                    grad.Color = colorSeq
                end)
            end
            return
        end
        local colorSeq = buildColorSequence(getActiveColors())
        for _, obj in ipairs(state.targetObjects) do
            pcall(function()
                local grad = ensureGradient(obj)
                grad.Color = colorSeq
            end)
        end
    end

    local function refreshObjects()
        state.targetObjects = findCrosshairObjects()
        for _, obj in ipairs(state.targetObjects) do
            saveOriginalProps(obj)
        end
        if state.enabled and #state.targetObjects > 0 then
            applyColors()
        end
    end

    local function clearTrail()
        for _, copy in ipairs(state.trailCopies) do
            pcall(function()
                copy:Destroy()
            end)
        end
        state.trailCopies = {}
    end

    local function buildTrail()

        if state.trailBuilding then return end
        state.trailBuilding = true

    clearTrail()
    if not state.trailEnabled then
        state.trailBuilding = false
        return
    end

    local maxPerObject = math.min(state.trailCount, 8)

    for _, obj in ipairs(state.targetObjects) do
        for i = 1, maxPerObject do
            pcall(function()
                local clone = obj:Clone()

                clone.Name = "CrosshairTrail_" .. i

                local g = clone:FindFirstChild("CrosshairGradient")
                if g then g:Destroy() end

                local cg = Instance.new("UIGradient")
                cg.Name = "CrosshairGradient"

                local srcGrad = obj:FindFirstChild("CrosshairGradient")
                if srcGrad then
                    cg.Color = srcGrad.Color
                    cg.Rotation = srcGrad.Rotation
                    cg.Offset = srcGrad.Offset
                else
                    cg.Color = buildColorSequence(getActiveColors())
                end
                cg.Parent = clone

                clone.ImageTransparency = 0.3 + (i / (maxPerObject + 1)) * 0.5

                clone.ZIndex = (obj.ZIndex or 1) - i

                clone.Parent = obj.Parent
                table.insert(state.trailCopies, clone)
            end)
        end
    end

    state.trailBuilding = false

    end

    local function updateTrailPositions(scaleMul)
        local idx = 0
        for _, obj in ipairs(state.targetObjects) do

            local entry = nil
            for _, e in ipairs(state.originalProps) do
                if e.obj == obj then
                    entry = e
                    break
                end
            end
            if not entry then

            else
                for i = 1, state.trailCount do
                    idx = idx + 1
                    local copy = state.trailCopies[idx]
                    if copy and copy.Parent then
                        pcall(function()

                            local scaleFactor = 1 + (state.scaleAmplitude * scaleMul) * (i / state.trailCount)
                            local origSize = entry.size
                            copy.Size = UDim2.new(
                                origSize.X.Scale, origSize.X.Offset * scaleFactor,
                                origSize.Y.Scale, origSize.Y.Offset * scaleFactor
                            )

                            local origPos = entry.position
                            local drift = (i / state.trailCount) * 0.004 * math.sin(state.pulsePhase + i)
                            copy.Position = UDim2.new(
                                origPos.X.Scale + drift,
                                origPos.X.Offset,
                                origPos.Y.Scale + drift,
                                origPos.Y.Offset
                            )

                            local srcGrad = obj:FindFirstChild("CrosshairGradient")
                            if srcGrad then
                                local cg = copy:FindFirstChild("CrosshairGradient")
                                if cg then
                                    cg.Color = srcGrad.Color
                                    cg.Rotation = srcGrad.Rotation
                                    cg.Offset = srcGrad.Offset
                                end
                            end
                        end)
                    end
                end
            end
        end
    end

    local function stopAnimation()
        if state.renderConn then
            state.renderConn:Disconnect()
            state.renderConn = nil
        end
        if state.addedConn then
            state.addedConn:Disconnect()
            state.addedConn = nil
        end
        if state.removedConn then
            state.removedConn:Disconnect()
            state.removedConn = nil
        end

    clearTrail()

    for _, obj in ipairs(state.targetObjects) do
        pcall(function()
            local grad = obj:FindFirstChild("CrosshairGradient")
            if grad then
                grad:Destroy()
            end
        end)
        restoreOriginalProps(obj)
    end
    state.targetObjects = {}
    state.originalProps = {}
    state.propsByObj = {}

    end

    local function startAnimation()
        if state.renderConn then
            state.renderConn:Disconnect()
            state.renderConn = nil
        end

    state.targetObjects = findCrosshairObjects()
    if #state.targetObjects == 0 then
        shared.Notify("❌ Crosshair not found!", 2)
        return
    end

    state.originalProps = {}
    state.propsByObj = {}
    for _, obj in ipairs(state.targetObjects) do
        saveOriginalProps(obj)
    end

    applyColors()

    if state.trailEnabled then
        buildTrail()
    end

    state.rotation = 0
    state.offset = 0
    state.pulsePhase = 0
    state.rainbowHue = 0

    local function updateCrosshairObjects(transparency, scaleMul)
        local floor = math.floor
        local objects = state.targetObjects
        local props = state.propsByObj
        local rainbow, hue = state.rainbowMode, state.rainbowHue
        local rotation, offset = state.rotation, state.offset
        local pulsing, scaling = state.pulsate, state.scalePulse
        for index = 1, #objects do
            local obj = objects[index]
            local entry = props[obj]
            if entry and obj.Parent then
                local grad = entry.grad
                if not grad or not grad.Parent then
                    grad = obj:FindFirstChild("CrosshairGradient")
                    entry.grad = grad
                end
                if grad then

                    if rainbow then
                        local hueStep = floor(hue * 256)
                        if entry.lastHueStep ~= hueStep then
                            entry.lastHueStep = hueStep
                            grad.Color = buildRainbowColorSequence(hueStep / 256)
                        end
                    end
                    local rotStep = floor(rotation * 2)
                    if entry.lastRotStep ~= rotStep then
                        entry.lastRotStep = rotStep
                        grad.Rotation = rotation
                    end
                    local offStep = floor(offset * 512)
                    if entry.lastOffStep ~= offStep then
                        entry.lastOffStep = offStep
                        grad.Offset = Vector2.new(offStep / 512, 0)
                    end
                end
                if pulsing and entry.lastTransparency ~= transparency then
                    entry.lastTransparency = transparency
                    obj.ImageTransparency = transparency
                end
                if scaling then
                    local origSize = entry.size

                    if entry.lastScale == nil or math.abs(entry.lastScale - scaleMul) > 1e-4 then
                        entry.lastScale = scaleMul
                        obj.Size = UDim2.new(
                            origSize.X.Scale, origSize.X.Offset * scaleMul,
                            origSize.Y.Scale, origSize.Y.Offset * scaleMul
                        )
                    end
                end
            end
        end
    end

    state.renderConn = ODHX.Connect(RunService.RenderStepped, function(dt)
        if not state.enabled then
            if state.renderConn then
                state.renderConn:Disconnect()
                state.renderConn = nil
            end
            return
        end

        local delta = state.speed * state.direction
        state.rotation = (state.rotation + delta) % 360
        state.offset = (state.offset + delta * 0.002) % 1

        if state.rainbowMode then
            state.rainbowHue = (state.rainbowHue + state.rainbowSpeed * 0.01) % 1
        end

        local waveVal = 0
        local anyPulse = state.pulsate or state.scalePulse
        if anyPulse then
            state.pulsePhase = state.pulsePhase + state.pulseSpeed * dt
            waveVal = getWaveformValue(state.pulsePhase, state.pulseWaveform)
        end

        local transparency = 0
        if state.pulsate then

            transparency = waveVal * state.pulseDepth
        end

        local scaleMul = 1
        if state.scalePulse then
            scaleMul = 1 + waveVal * state.scaleAmplitude
        end

        pcall(updateCrosshairObjects, transparency, scaleMul)

        if state.trailEnabled and #state.trailCopies > 0 then
            updateTrailPositions(waveVal)
        end
    end)

    local playerGui = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        state.addedConn = ODHX.Connect(playerGui.DescendantAdded, function(descendant)
            if isCrosshairObject(descendant) then
                table.insert(state.targetObjects, descendant)
                saveOriginalProps(descendant)
                if state.enabled then
                    pcall(function()
                        local grad = ensureGradient(descendant)
                        if state.rainbowMode then
                            grad.Color = buildRainbowColorSequence(state.rainbowHue)
                        else
                            grad.Color = buildColorSequence(getActiveColors())
                        end
                    end)
                    if state.trailEnabled then
                        buildTrail()
                    end
                end
            end
        end)
        state.removedConn = ODHX.Connect(playerGui.DescendantRemoving, function(descendant)

            local dName = descendant.Name:lower()
            if dName:find("crosshairtrail_") then
                return
            end
            for i, obj in ipairs(state.targetObjects) do
                if obj == descendant then
                    table.remove(state.targetObjects, i)
                    for j, e in ipairs(state.originalProps) do
                        if e.obj == descendant then
                            table.remove(state.originalProps, j)
                            break
                        end
                    end
                    break
                end
            end
            if state.trailEnabled then
                buildTrail()
            end
        end)
    end

    end

    local shiftlock_section = shared.AddSection("🎯 Mobile Shiftlock Crosshair")

    shiftlock_section:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    shiftlock_section:AddLabel("⚡ ULTRA GLOW+ EDITION v3.7")
    shiftlock_section:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    shiftlock_section:AddToggle("🔓 Enable Glow", function(bool)
        state.enabled = bool
        if bool then
            startAnimation()
            if #state.targetObjects > 0 then
                shared.Notify("✅ Glow enabled", 2)
            end
        else
            stopAnimation()
            shared.Notify("❌ Glow disabled", 2)
        end
        saveSettings()
    end)

    shiftlock_section:AddColorpicker("🎨 Custom Color", Color3.fromRGB(157, 0, 255), function(color)
        local r, g, b = color.R, color.G, color.B
        state.customColors = {
            Color3.new(r, g, b),
            Color3.new(math.min(r + 0.2, 1), math.min(g + 0.2, 1), math.min(b + 0.2, 1)),
            Color3.new(math.max(r - 0.15, 0), math.max(g - 0.15, 0), math.max(b - 0.15, 0)),
            Color3.new(math.min(r + 0.1, 1), math.min(g + 0.1, 1), math.min(b + 0.1, 1)),
            Color3.new(r, g, b),
        }
        state.currentPreset = nil
        state.rainbowMode = false
        if state.enabled then
            applyColors()
        end
        shared.Notify("🎨 Custom color applied", 1.5)
        saveSettings()
    end)

    shiftlock_section:AddToggle("🌈 Rainbow Mode (RGB)", function(bool)
        state.rainbowMode = bool
        if bool then
            state.customColors = nil
            state.currentPreset = nil
        end
        if state.enabled then
            applyColors()
        end
        shared.Notify(bool and "🌈 Rainbow ON" or "🌈 Rainbow OFF", 1.5)
        saveSettings()
    end)

    for _, preset in ipairs(SPEED_PRESETS) do
        shiftlock_section:AddButton("🌈 Rainbow " .. preset.label, function()
            state.rainbowSpeed = preset.value
            shared.Notify("🌈 Rainbow speed: " .. preset.label, 1.5)
        end)
    end

    shiftlock_section:AddButton("🎲 Random Preset", function()
        local idx = math.random(1, #GLOW_PRESETS)
        local preset = GLOW_PRESETS[idx]
        state.currentPreset = preset
        state.customColors = nil
        state.rainbowMode = false
        if state.enabled then
            applyColors()
        end
        shared.Notify("🎲 " .. preset.icon .. " " .. preset.name, 1.5)
        saveSettings()
    end)

    shiftlock_section:AddButton("🎲 Random Color", function()
        local r = math.random()
        local g = math.random()
        local b = math.random()
        state.customColors = {
            Color3.new(r, g, b),
            Color3.new(math.min(r + 0.2, 1), math.min(g + 0.2, 1), math.min(b + 0.2, 1)),
            Color3.new(math.max(r - 0.15, 0), math.max(g - 0.15, 0), math.max(b - 0.15, 0)),
            Color3.new(math.min(r + 0.1, 1), math.min(g + 0.1, 1), math.min(b + 0.1, 1)),
            Color3.new(r, g, b),
        }
        state.currentPreset = nil
        state.rainbowMode = false
        if state.enabled then
            applyColors()
        end
        shared.Notify("🎲 Random color!", 1.5)
        saveSettings()
    end)

    shiftlock_section:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    shiftlock_section:AddLabel("💗 PULSE v2 (improved)")
    shiftlock_section:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    shiftlock_section:AddToggle("💗 Pulsate Transparency", function(bool)
        state.pulsate = bool
        if not bool then
            for _, obj in ipairs(state.targetObjects) do
                pcall(function()
                    obj.ImageTransparency = 0
                end)
            end
        end
        shared.Notify(bool and "💗 Pulsate ON" or "💗 Pulsate OFF", 1.5)
        saveSettings()
    end)

    for _, wf in ipairs(WAVEFORMS) do
        shiftlock_section:AddButton("〰️ Wave: " .. wf.label, function()
            state.pulseWaveform = wf.key
            shared.Notify("〰️ Waveform: " .. wf.label, 1.5)
            saveSettings()
        end)
    end

    for _, preset in ipairs(TRANSPARENCY_DEPTH_PRESETS) do
        shiftlock_section:AddButton(preset.label, function()
            state.pulseDepth = preset.value
            shared.Notify("🔆 Depth: " .. tostring(preset.value), 1.5)
            saveSettings()
        end)
    end

    for _, preset in ipairs(PULSE_PRESETS) do
        shiftlock_section:AddButton(preset.label, function()
            state.pulseSpeed = preset.value
            shared.Notify("💗 " .. preset.label, 1.5)
            saveSettings()
        end)
    end

    shiftlock_section:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    shiftlock_section:AddLabel("📐 SCALE PULSE v2 (Breathing)")
    shiftlock_section:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    shiftlock_section:AddToggle("📐 Scale Pulse (Breathing)", function(bool)
        state.scalePulse = bool
        if not bool then
            for _, obj in ipairs(state.targetObjects) do
                pcall(function()
                    for _, e in ipairs(state.originalProps) do
                        if e.obj == obj then
                            obj.Size = e.size
                            break
                        end
                    end
                end)
            end
        end
        shared.Notify(bool and "📐 Scale pulse ON" or "📐 Scale pulse OFF", 1.5)
        saveSettings()
    end)

    for _, preset in ipairs(SCALE_AMPLITUDE_PRESETS) do
        shiftlock_section:AddButton(preset.label, function()
            state.scaleAmplitude = preset.value
            shared.Notify("📐 Amplitude: " .. preset.label, 1.5)
            saveSettings()
        end)
    end

    shiftlock_section:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    shiftlock_section:AddLabel("👻 TRAIL / ECHO (ghost trail)")
    shiftlock_section:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    shiftlock_section:AddToggle("👻 Enable Trail", function(bool)
        state.trailEnabled = bool
        if bool then
            if state.enabled then
                buildTrail()
            end
        else
            clearTrail()
        end
        shared.Notify(bool and "👻 Trail ON" or "👻 Trail OFF", 1.5)
        saveSettings()
    end)

    for _, preset in ipairs(TRAIL_COUNT_PRESETS) do
        shiftlock_section:AddButton(preset.label, function()
            state.trailCount = preset.value
            if state.enabled and state.trailEnabled then
                buildTrail()
            end
            shared.Notify("👻 Trail count: " .. tostring(preset.value), 1.5)
            saveSettings()
        end)
    end

    shiftlock_section:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    shiftlock_section:AddLabel("⚙️ SETTINGS")
    shiftlock_section:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    for _, preset in ipairs(SPEED_PRESETS) do
        shiftlock_section:AddButton("💨 Speed " .. preset.label, function()
            state.speed = preset.value
            shared.Notify("💨 Speed: " .. preset.label, 1.5)
            saveSettings()
        end)
    end

    shiftlock_section:AddToggle("🔄 Reverse Direction", function(bool)
        state.reversed = bool
        state.direction = bool and -1 or 1
        shared.Notify(bool and "🔄 Reversed" or "▶️ Forward", 1.5)
        saveSettings()
    end)

    shiftlock_section:AddButton("🔄 Reset to Defaults", function()
        state.enabled = false
        stopAnimation()
        state.customColors = nil
        state.currentPreset = nil
        state.speed = SPEED_PRESETS[2].value
        state.direction = 1
        state.reversed = false
        state.pulsate = false
        state.pulseSpeed = 2
        state.pulseWaveform = "sine"
        state.pulseDepth = 0.4
        state.rainbowMode = false
        state.rainbowSpeed = 1.0
        state.scalePulse = false
        state.scaleAmplitude = 0.10
        state.trailEnabled = false
        state.trailCount = 2
        pcall(function() _G[SETTINGS_KEY] = nil end)
        shared.Notify("↩️ Reset to defaults", 2)
    end)

    shiftlock_section:AddButton("🔍 Re-scan Crosshair", function()
        refreshObjects()
        if #state.targetObjects > 0 then
            shared.Notify("🔍 Found " .. #state.targetObjects .. " crosshair(s)", 2)
        else
            shared.Notify("❌ Crosshair not found!", 2)
        end
    end)

    shiftlock_section:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    shiftlock_section:AddLabel("✨ COLOR PRESETS (" .. #GLOW_PRESETS .. ")")
    shiftlock_section:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    for _, preset in ipairs(GLOW_PRESETS) do
        shiftlock_section:AddButton(preset.icon .. " " .. preset.name, function()
            state.currentPreset = preset
            state.customColors = nil
            state.rainbowMode = false
            if state.enabled then
                applyColors()
            end
            shared.Notify(preset.icon .. " " .. preset.name, 1.5)
            saveSettings()
        end)
    end

    shiftlock_section:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    shiftlock_section:AddLabel("📖 HOW IT WORKS:")
    shiftlock_section:AddLabel("1. Turn on 🔓 Enable Glow")
    shiftlock_section:AddLabel("2. Pick a preset / 🎨 Color / 🌈 Rainbow")
    shiftlock_section:AddLabel("3. 💗 Pulse: waveform + depth")
    shiftlock_section:AddLabel("4. 📐 Scale Pulse: breathing amplitude")
    shiftlock_section:AddLabel("5. 👻 Trail — ghost crosshair echo")
    shiftlock_section:AddLabel("6. 🎲 Random — just for fun!")
    shiftlock_section:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    local function restoreSettings()
        local saved = loadSettings()
        if not saved then
            return
        end
        if type(saved.customColors)=="table" then
            local valid=#saved.customColors==5
            for _,c in ipairs(saved.customColors) do if typeof(c)~="Color3" then valid=false end end
            if valid then state.customColors=saved.customColors end
        end
        state.speed = saved.speed or state.speed
        state.reversed = saved.reversed or false
        state.direction = state.reversed and -1 or 1
        state.pulsate = saved.pulsate or false
        state.pulseSpeed = saved.pulseSpeed or 2
        state.pulseWaveform = saved.pulseWaveform or "sine"
        state.pulseDepth = saved.pulseDepth or 0.4
        state.rainbowMode = saved.rainbowMode or false
        state.rainbowSpeed = saved.rainbowSpeed or 1.0
        state.scalePulse = saved.scalePulse or false
        state.scaleAmplitude = saved.scaleAmplitude or 0.10
        state.trailEnabled = saved.trailEnabled or false
        state.trailCount = saved.trailCount or 2

    if saved.presetName then
        for _, preset in ipairs(GLOW_PRESETS) do
            if preset.name == saved.presetName then
                state.currentPreset = preset
                break
            end
        end
    end

    if saved.enabled then
        state.enabled = true
        task.delay(0.5, function()
            for _=1,30 do
                if not state.enabled or ODHX.stopped then break end
                if #findCrosshairObjects()>0 then startAnimation(); break end
                task.wait(1)
            end
            if state.enabled then shared.Notify("💾 Settings restored", 2) end
        end)
    end

    end

    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🎯 SHIFTLOCK CROSSHAIR v3.5 LOADED")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🌈 Rainbow/RGB mode")
    print("💗 Pulse v2: 4 waveforms + depth")
    print("📐 Scale Pulse v2: adjustable amplitude")
    print("👻 Trail/Echo — ghost trail")
    print("🎨 Colorpicker + " .. #GLOW_PRESETS .. " color presets")
    print("🎲 Random Preset / Random Color")
    print("💾 Settings auto-save")
    print("🔍 Auto-refresh of crosshair objects")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    restoreSettings()

    ODHX.Bind("🎯 Mobile Shiftlock Crosshair", "🔓 Enable Glow", "Toggle", function() return state.enabled end)
    ODHX.Bind("🎯 Mobile Shiftlock Crosshair", "🌈 Rainbow Mode (RGB)", "Toggle", function() return state.rainbowMode end)
    ODHX.Bind("🎯 Mobile Shiftlock Crosshair", "💗 Pulsate Transparency", "Toggle", function() return state.pulsate end)
    ODHX.Bind("🎯 Mobile Shiftlock Crosshair", "📐 Scale Pulse (Breathing)", "Toggle", function() return state.scalePulse end)
    ODHX.Bind("🎯 Mobile Shiftlock Crosshair", "👻 Enable Trail", "Toggle", function() return state.trailEnabled end)
    ODHX.Bind("🎯 Mobile Shiftlock Crosshair", "🔄 Reverse Direction", "Toggle", function() return state.reversed end)
    ODHX.Bind("🎯 Mobile Shiftlock Crosshair", "🎨 Custom Color", "Colorpicker", function() return state.customColors and state.customColors[1] or Color3.fromRGB(157,0,255) end)
    ODHX.cleanup=stopAnimation
    ODHX.Finish()

end
end)

SR_UI.tryModule("Omega", function()
do

local shared = odh_shared_plugins

if not shared or type(shared.CreateTab) ~= "function" then
    warn("[Omega] odh_shared_plugins is unavailable in this plugin context.")
    return
end

local Players = SR_UI.service("Players")
local RunService = SR_UI.service("RunService")
local Lighting = SR_UI.service("Lighting")
local Stats = SR_UI.service("Stats")
local Workspace = SR_UI.service("Workspace")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    warn("[Omega] Run this plugin on the client.")
    return
end

local previousRuntime = _G.OmegaAutoRevertRuntime
if type(previousRuntime) == "table" and type(previousRuntime.Cleanup) == "function" then
    local ok, restored = pcall(previousRuntime.Cleanup)
    if not ok or restored == false then
        warn("[Omega] Previous instance could not clean up. Reload cancelled.")
        return
    end
end

local UI_VERSION = 2
local ui
local reuseUI = type(previousRuntime) == "table"
    and type(previousRuntime.ui) == "table"
    and previousRuntime.ui.owner == shared
    and previousRuntime.ui.version == UI_VERSION
    and previousRuntime.ui.complete == true

if reuseUI then
    ui = previousRuntime.ui
else
    local tabOk, tab = pcall(function()
        return SR_Tab("Omega")
    end)
    if not tabOk or not tab then
        warn("[Omega] shared.CreateTab failed: " .. tostring(tab))
        return
    end

    local secOk, section = pcall(function()
        return tab:AddSection("Omega Auto Revert", "Dynamic MM2 settings by ping")
    end)
    if not secOk or not section then
        warn("[Omega] AddSection failed: " .. tostring(section))
        return
    end

    ui = {
        owner = shared, tab = tab, section = section, complete = false,
        version = UI_VERSION, toggles = {}, toggleStates = {},
    }
end

local defaults = {
    ["Auto Revert"]     = false,
    ["Adaptive Engine"] = true,
    ["Lock Config"]     = false,
    ["Upgrade Mode"]    = false,
    ["Monitor"]         = false,
    ["FPS Boost"]       = false,
}

local SETTINGS_FILE = "Omega_CFG_settings.json"
local storage = { status = "Not saved", issue = nil, skipInitialSave = false }
local environment = {}
if type(getgenv) == "function" then
    local ok, result = pcall(getgenv)
    if ok and type(result) == "table" then environment = result end
end
local fileRead = type(readfile) == "function" and readfile or environment.readfile
local fileWrite = type(writefile) == "function" and writefile or environment.writefile
local fileExists = type(isfile) == "function" and isfile or environment.isfile
local serviceOK, HttpService = pcall(function() return SR_UI.service("HttpService") end)
local canPersist = SR_Store.CanWrite() and serviceOK and HttpService ~= nil

local function ReadPreferences()
    if not canPersist then
        storage.status = "Unavailable"
        storage.issue = "Settings cannot persist: readfile/writefile or HttpService is unavailable."
        return {}
    end
    if type(fileExists) == "function" then
        local ok, exists = pcall(fileExists, SETTINGS_FILE)
        if ok and not exists then return {} end
    end
    local contents = SR_Store.read(SETTINGS_FILE)
    local ok = contents ~= nil
    if not ok then
        storage.status = "Read error"
        storage.issue = "Could not read " .. SETTINGS_FILE .. "."

        storage.skipInitialSave = true
        return {}
    end
    local decoded, data = pcall(function() return HttpService:JSONDecode(contents) end)
    if not decoded or type(data) ~= "table" or data.version ~= 1 or type(data.values) ~= "table" then
        storage.status = "Invalid file"
        storage.issue = "Settings file is invalid or uses an unsupported version. Defaults loaded; toggle a setting to save a new file."
        storage.skipInitialSave = true
        return {}
    end
    local saved = {}
    for name in pairs(defaults) do
        if type(data.values[name]) == "boolean" then saved[name] = data.values[name] end
    end
    storage.status = "Loaded"
    return saved
end

local diskValues = ReadPreferences()
local values = {}
for name, default in pairs(defaults) do
    local saved = diskValues[name]
    if type(previousRuntime) == "table" and type(previousRuntime.values) == "table" then
        local previous = previousRuntime.values[name]
        if type(previous) == "boolean" then saved = previous end
    end
    if type(saved) == "boolean" then
        values[name] = saved
    else
        values[name] = default
    end
end

local runtime = {
    alive = true, initializing = true, ui = ui, values = values, handlers = {},
}
_G.OmegaAutoRevertRuntime = runtime

local function Notify(text, duration)
    if not SR_Gate(text) then return end
    if type(shared.Notify) == "function" then
        local ok, err = pcall(shared.Notify, text, duration or 2)
        if not ok then
            warn("[Omega] Notify failed: " .. tostring(err))
        end
    else
        warn("[Omega] " .. text)
    end
end

local function ReportStorageIssue()
    if storage.issue and storage.reported ~= storage.issue then
        storage.reported = storage.issue
        warn("[Omega Save] " .. storage.issue)
        Notify("Omega: settings could not be saved/loaded. See console.", 5)
    end
end

local function SavePreferences()
    if not runtime.alive then return false end
    if not canPersist then
        ReportStorageIssue()
        return false
    end
    local snapshot = {}
    for name, default in pairs(defaults) do
        if type(values[name]) == "boolean" then snapshot[name] = values[name]
        else snapshot[name] = default end
    end
    local ok, err = pcall(function()
        local text = HttpService:JSONEncode({ version = 1, values = snapshot })
        local saved, why = SR_Store.write(SETTINGS_FILE, text)
        if not saved then error(why or "write failed") end
    end)
    if not ok then
        storage.status = "Write error"
        storage.issue = "Cannot save " .. SETTINGS_FILE .. ": " .. tostring(err)
        ReportStorageIssue()
        return false
    end
    storage.status = "Saved"
    storage.issue = nil
    storage.reported = nil
    return true
end
runtime.SaveSettings = SavePreferences
runtime.settingsFile = SETTINGS_FILE
runtime.storage = storage

local function SetToggleValue(name, state)
    if ui.toggleStates[name] == state then
        return true
    end
    local toggle = ui.toggles[name]
    if type(toggle) ~= "function" then
        warn("[Omega] No toggle closure for " .. name)
        return false
    end
    local ok, err = pcall(toggle)
    if not ok or ui.toggleStates[name] ~= state then
        warn("[Omega] Cannot synchronize toggle " .. name .. ": " .. tostring(err))
        return false
    end
    return true
end

local SAMPLE_INTERVAL   = 0.4
local MONITOR_INTERVAL  = 0.25
local STALE_INTERVAL    = 5
local HYSTERESIS        = 4

local enabled         = values["Auto Revert"]
local adaptiveEngine  = values["Adaptive Engine"]
local monitorEnabled  = false
local fpsBoost        = false
local locked          = values["Lock Config"]
local upgrade         = values["Upgrade Mode"]
local currentProfile  = ""
local applyHealthy    = true
local mappingBlocked  = false
local lastApplied     = {}
local lastSetters     = {}
local activePreset
local upgradeTarget
local lastUpgrade
local workerToken
local updateConnection
local monitorGui
local graphicsSnapshot = {}
local warnings         = {}

local rawPing        = 60
local smoothedPing   = 60
local jitter         = 0
local pingSource     = "Fallback"
local lastAttempt    = -math.huge
local lastGoodSample = -math.huge

local function WarnOnce(key, message)
    if not warnings[key] then
        warnings[key] = true
        warn("[Omega] " .. message)
    end
end

local function IsFinite(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

local function ReadDataPing()
    local network = Stats:FindFirstChild("Network")
    local serverStats = network and network:FindFirstChild("ServerStatsItem")
    local item = serverStats and serverStats:FindFirstChild("Data Ping")
    return item and item:GetValue()
end

local function ReadPerformancePing()
    local performance = Stats:FindFirstChild("PerformanceStats")
    local item = performance and performance:FindFirstChild("Ping")
    return item and item:GetValue()
end

local function ReadNetworkPing()
    local value = LocalPlayer:GetNetworkPing()
    if IsFinite(value) then
        return value * 1000
    end
end

local pingReaders = {
    { ReadDataPing,        "Data Ping" },
    { ReadPerformancePing, "Performance" },
    { ReadNetworkPing,     "Network" },
}

local function SamplePing()
    local now = os.clock()
    if now - lastAttempt < SAMPLE_INTERVAL then
        return
    end
    lastAttempt = now

    local value
    for _, reader in ipairs(pingReaders) do
        local ok, candidate = pcall(reader[1])
        if ok and IsFinite(candidate) and candidate > 0 then
            value = candidate
            pingSource = reader[2]
            break
        end
    end

    if not value then
        pingSource = lastGoodSample == -math.huge and "Fallback" or "Last known"
        return
    end

    local elapsed = now - lastGoodSample
    local nextRaw = math.clamp(math.floor(value + 0.5), 5, 1200)
    if elapsed > STALE_INTERVAL then
        smoothedPing = nextRaw
        jitter = 0
    else
        local weight = elapsed / SAMPLE_INTERVAL
        local jitterAlpha = 1 - 0.75 ^ weight
        jitter = jitter + (math.abs(nextRaw - rawPing) - jitter) * jitterAlpha
        if adaptiveEngine then
            local alpha = math.abs(nextRaw - smoothedPing) > 40 and 0.6 or 0.25
            alpha = 1 - (1 - alpha) ^ weight
            smoothedPing = smoothedPing + (nextRaw - smoothedPing) * alpha
        else
            smoothedPing = nextRaw
        end
    end
    rawPing = nextRaw
    lastGoodSample = now
end

local function GetPing()
    return math.floor(smoothedPing + 0.5)
end

local PingControlPoints = {
    { Ping = 20,  Sim = 48, Interval = 70, H = 154, V = 144, X = -5,  Y = -14, Z = 0 },
    { Ping = 50,  Sim = 54, Interval = 66, H = 162, V = 152, X = -6,  Y = -14, Z = 0 },
    { Ping = 100, Sim = 68, Interval = 60, H = 176, V = 166, X = -8,  Y = -15, Z = 0 },
    { Ping = 150, Sim = 72, Interval = 64, H = 182, V = 170, X = -9,  Y = -12, Z = 0 },
    { Ping = 200, Sim = 76, Interval = 70, H = 188, V = 174, X = -10, Y = -11, Z = 0 },
    { Ping = 300, Sim = 82, Interval = 76, H = 196, V = 180, X = -12, Y = -10, Z = 0 },
}
local ProfileNames      = { "A", "B", "C", "D" }
local ProfileIndices    = { A = 1, B = 2, C = 3, D = 4 }
local ProfileThresholds = { 50, 100, 150 }

local ConfigFields = {
    { name = "Sim",        point = "Sim",      slot = 4,  scale = 1,
        label = "Prediction Max Simulation Time" },
    { name = "Interval",   point = "Interval", slot = 5,  scale = 1,
        label = "Prediction Interval" },
    { name = "X",          point = "X",        slot = 6,  scale = 10,
        label = "X Position Offset (%)" },
    { name = "Y",          point = "Y",        slot = 7,  scale = 10,
        label = "Y Position Offset (%)" },
    { name = "Z",          point = "Z",        slot = 8,  scale = 10,
        label = "Z Position Offset (%)" },
    { name = "Horizontal", point = "H",        slot = 9,  scale = 1,
        label = "Prediction Horizontal Multiplier (%)" },
    { name = "Vertical",   point = "V",        slot = 10, scale = 1,
        label = "Prediction Vertical Multiplier (%)" },
}

local function GetConfig(ping)
    local first, second
    local t = 0
    local name

    if adaptiveEngine then
        name = "Dynamic_" .. math.floor(ping)
        first = PingControlPoints[1]
        second = first
        if ping >= PingControlPoints[#PingControlPoints].Ping then
            first = PingControlPoints[#PingControlPoints]
            second = first
        elseif ping > first.Ping then
            for i = 1, #PingControlPoints - 1 do
                if ping <= PingControlPoints[i + 1].Ping then
                    first = PingControlPoints[i]
                    second = PingControlPoints[i + 1]
                    t = (ping - first.Ping) / (second.Ping - first.Ping)
                    t = t * t * (3 - 2 * t)
                    break
                end
            end
        end
    else
        local index = ProfileIndices[currentProfile]
        if index then
            while index < 4 and ping > ProfileThresholds[index] + HYSTERESIS do
                index = index + 1
            end
            while index > 1 and ping <= ProfileThresholds[index - 1] - HYSTERESIS do
                index = index - 1
            end
        else
            index = 1
            while index < 4 and ping > ProfileThresholds[index] do
                index = index + 1
            end
        end
        first = PingControlPoints[index + 1]
        second = first
        name = ProfileNames[index]
    end

    local cfg = { Name = name }
    for _, field in ipairs(ConfigFields) do
        local a = first[field.point]
        local b = second[field.point]
        cfg[field.name] = math.floor((a + (b - a) * t) * field.scale + 0.5) / field.scale
    end
    if upgrade then
        cfg.Vertical   = cfg.Vertical + 2
        cfg.Horizontal = cfg.Horizontal + 2
        cfg.Sim        = cfg.Sim + 1
    end
    return cfg
end

local function CallPreset(preset, slot, value, key)
    local label = "MM2_GPL[" .. slot .. "]" .. (key and (" (" .. key .. ")") or "")
    local readable, control = pcall(function()
        return preset[slot]
    end)
    if not readable or control == nil then
        local detail = readable and "missing control; check the MM2 slot mapping with Print Telemetry" or tostring(control)
        WarnOnce(slot, label .. " is unavailable: " .. detail)
        if key then lastSetters[key] = nil end
        return false
    end

    local setter
    local method = false
    if type(control) == "function" then
        setter = control
    elseif type(control) == "table" and value ~= nil then
        local ok, candidate = pcall(function() return control.SetValue end)
        if ok and type(candidate) == "function" then
            setter = candidate
            method = true
        end
    end
    if not setter then
        WarnOnce(slot, label .. " has unsupported type " .. type(control)
            .. (value ~= nil and "; expected a function or an object with :SetValue(number)"
                or "; expected a toggle closure") .. ". Use Print Telemetry for details.")
        if key then lastSetters[key] = nil end
        return false
    end

    local cached = key and lastSetters[key]
    if key and lastApplied[key] == value and cached
        and cached.control == control and cached.setter == setter then
        warnings[slot] = nil
        return true
    end
    local ok, err = pcall(function()
        if method then
            setter(control, value)
        elseif value == nil then
            setter()
        else
            setter(value)
        end
    end)
    if not ok then
        WarnOnce(slot, label .. " failed: " .. tostring(err))
        if key then lastSetters[key] = nil end
        return false
    end
    warnings[slot] = nil
    if key then
        lastApplied[key] = value
        lastSetters[key] = { control = control, setter = setter }
    end
    return true
end

local function PrintPresetDiagnostics()
    local ok, err = pcall(function()
        local internal = odh_internal_shared
        local preset = internal and internal.MM2_GPL
        print("[Omega API] MM2_GPL type=" .. type(preset))
        if type(preset) ~= "table" then return end

        local slots = {}
        for slot = 1, 11 do slots[#slots + 1] = slot end
        for slot in pairs(preset) do
            if (type(slot) == "number" and (slot < 1 or slot > 11 or slot % 1 ~= 0))
                or type(slot) == "string" then
                slots[#slots + 1] = slot
                if #slots >= 48 then break end
            end
        end
        for _, slot in ipairs(slots) do
            local control = preset[slot]
            local description = "[Omega API] [" .. tostring(slot) .. "] " .. type(control)
            if type(control) == "table" then
                local name = control.feature_name
                if type(name) ~= "string" then
                    name = control.Name or control.name or control.Title or control.title
                end
                if type(name) == "string" then

                    description = description .. " name=" .. string.format("%q", name:sub(1, 160))
                else
                    description = description .. " name=<unavailable>"
                end
                description = description .. " range=" .. tostring(control.Min) .. ".." .. tostring(control.Max)
                    .. " SetValue=" .. type(control.SetValue)
            end
            print(description)
        end
    end)
    if not ok then
        warn("[Omega API] Diagnostic failed: " .. tostring(err))
    end
end

local function GetInternal()
    local internal = odh_internal_shared
    if not internal then
        WarnOnce("internal", "odh_internal_shared is unavailable; MM2 settings are waiting for this API.")
        return nil
    end
    warnings.internal = nil
    return internal
end

local function SyncUpgrade(internal)
    if not internal then
        return false
    end
    if upgradeTarget == internal and lastUpgrade == upgrade then
        return true
    end
    local ok, err = pcall(function()
        internal.__OMEGA_UPGRADE = upgrade
    end)
    if not ok then
        WarnOnce("upgrade", "Cannot write odh_internal_shared.__OMEGA_UPGRADE: " .. tostring(err))
        return false
    end
    warnings.upgrade = nil
    upgradeTarget = internal
    lastUpgrade = upgrade
    return true
end

local RequiredFlags = {
    { key = "RevertSettings_PrioritizeYourPing", slot = 1 },
    { key = "RevertSettings_PredictJump",        slot = 2 },
    { key = "RevertSettings_PredictLag",         slot = 3 },
}

local function Apply(cfg)
    mappingBlocked = false
    local internal = GetInternal()
    if not internal then
        applyHealthy = false
        return
    end
    local readable, preset = pcall(function()
        return internal.MM2_GPL
    end)
    if not readable or not preset then
        local detail = readable and "missing value" or tostring(preset)
        WarnOnce("preset", "odh_internal_shared.MM2_GPL is unavailable: " .. detail)
        applyHealthy = false
        return
    end
    warnings.preset = nil
    if activePreset ~= preset then
        activePreset = preset
        lastApplied = {}
        lastSetters = {}
    end

    for _, field in ipairs(ConfigFields) do
        local valid, detail = pcall(function()
            local control = preset[field.slot]
            assert(type(control) == "function"
                or (type(control) == "table" and type(control.SetValue) == "function"),
                "missing or unsupported control")
            if type(control) == "table" and type(control.feature_name) == "string" then
                local function NormalizeName(name)
                    return (name:lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
                end
                assert(NormalizeName(control.feature_name) == NormalizeName(field.label),
                    "expected " .. field.label .. "; got " .. control.feature_name)
            end
        end)
        if not valid then
            mappingBlocked = true
            applyHealthy = false
            currentProfile = ""
            lastApplied = {}
            lastSetters = {}
            local firstWarning = not warnings.mapping
            WarnOnce("mapping", "MM2 slot mapping incomplete or changed at [" .. field.slot .. "] ("
                .. field.name .. "): " .. tostring(detail)
                .. ". Slider/flag updates PAUSED; actual names are printed below.")
            if firstWarning then PrintPresetDiagnostics() end
            return
        end
    end
    warnings.mapping = nil
    local ok = SyncUpgrade(internal)

    for _, flag in ipairs(RequiredFlags) do
        if flag.slot ~= 3 or not adaptiveEngine or smoothedPing > 110 then
            local flagOk, state = pcall(function()
                return internal[flag.key]
            end)
            if not flagOk then
                WarnOnce(flag.key, "Cannot read odh_internal_shared." .. flag.key .. ": " .. tostring(state))
                ok = false
            else
                warnings[flag.key] = nil
                if not state and not CallPreset(preset, flag.slot) then
                    ok = false
                end
            end
        end
    end

    for _, field in ipairs(ConfigFields) do
        if not CallPreset(preset, field.slot, cfg[field.name], field.name) then
            ok = false
        end
    end
    applyHealthy = ok
    if ok then
        currentProfile = cfg.Name
    end
end

local function Update()
    SamplePing()
    if enabled and not locked then
        Apply(GetConfig(GetPing()))
    end
end

local function NeedsUpdates()
    return monitorEnabled or (enabled and not locked)
end

local function SyncWorker()
    if not runtime.alive or not NeedsUpdates() then
        workerToken = nil
        return
    end
    if workerToken then
        return
    end
    local token = {}
    workerToken = token
    task.spawn(function()
        while runtime.alive and workerToken == token and NeedsUpdates() do
            task.wait(SAMPLE_INTERVAL)
            if runtime.alive and workerToken == token and NeedsUpdates() then
                Update()
            end
        end
    end)
end

local function RestoreGraphics()
    for i = #graphicsSnapshot, 1, -1 do
        local saved = graphicsSnapshot[i]
        local ok, err = pcall(function()
            saved.object[saved.property] = saved.value
        end)
        if ok then
            warnings[saved.property] = nil
            table.remove(graphicsSnapshot, i)
        else
            WarnOnce(saved.property, "Cannot restore " .. saved.property .. ": " .. tostring(err))
        end
    end
    return #graphicsSnapshot == 0
end

local function SaveAndSet(object, property, value)
    local ok, original = pcall(function()
        return object[property]
    end)
    if not ok then
        WarnOnce(property, "Cannot read " .. property .. ": " .. tostring(original))
        return
    end
    graphicsSnapshot[#graphicsSnapshot + 1] = { object = object, property = property, value = original }
    local applied, err = pcall(function()
        object[property] = value
    end)
    if not applied then
        WarnOnce(property, "Cannot set " .. property .. ": " .. tostring(err))
    end
end

local function SetFPSBoost(state)
    if not state then
        fpsBoost = false
        return RestoreGraphics()
    end
    if fpsBoost then
        return true
    end
    if not RestoreGraphics() then
        return false
    end

    fpsBoost = true
    SaveAndSet(Lighting, "GlobalShadows", false)
    SaveAndSet(Lighting, "OutdoorAmbient", Color3.fromRGB(128, 128, 128))
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        SaveAndSet(terrain, "WaterWaveSize", 0)
        SaveAndSet(terrain, "WaterWaveSpeed", 0)
        SaveAndSet(terrain, "WaterReflectance", 0)
        SaveAndSet(terrain, "WaterTransparency", 0)
    end
    return true
end

local function DestroyMonitor()
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
    if monitorGui then
        if _G.OmegaGui == monitorGui then
            _G.OmegaGui = nil
        end
        monitorGui:Destroy()
        monitorGui = nil
    end
end

local function SetText(label, text)
    if label.Text ~= text then
        label.Text = text
    end
end

local function CreateMonitor()
    DestroyMonitor()
    if _G.OmegaGui then
        pcall(function() _G.OmegaGui:Destroy() end)
        _G.OmegaGui = nil
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "Omega"
    gui.ResetOnSpawn = false
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        pcall(function() gui.Parent = playerGui end)
    end
    if not gui.Parent then
        pcall(function() gui.Parent = SR_UI.service("CoreGui") end)
    end
    if not gui.Parent then
        gui:Destroy()
        monitorEnabled = false
        WarnOnce("gui", "Neither PlayerGui nor CoreGui is available for the monitor.")
        return
    end
    warnings.gui = nil
    monitorGui = gui
    _G.OmegaGui = gui

    local function MakeLabel(name, y)
        local label = Instance.new("TextLabel")
        label.Name = name
        label.AnchorPoint = Vector2.new(1, 0)
        label.Size = UDim2.new(1, -24, 0, 19)
        label.Position = UDim2.new(1, -12, 0, y)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Code
        label.TextXAlignment = Enum.TextXAlignment.Right
        label.TextSize = 14
        label.TextColor3 = Color3.fromRGB(240, 240, 240)
        label.TextStrokeTransparency = 0.4
        label.Text = ""
        label.Parent = gui
        return label
    end

    local pingLabel   = MakeLabel("Ping", 40)
    local fpsLabel    = MakeLabel("FPS", 59)
    local detailLabel = MakeLabel("Telemetry", 78)
    local statusLabel = MakeLabel("Status", 97)
    local elapsed = 0
    local frames  = 0

    local function Refresh(fps)
        SetText(pingLabel, "Ping: " .. GetPing() .. " ms | Raw: " .. rawPing .. " ms")
        SetText(fpsLabel, "FPS: " .. (fps and tostring(fps) or "--"))
        SetText(detailLabel, "Jitter: " .. math.floor(jitter + 0.5) .. " ms | " .. pingSource)
        local status  = not enabled and "OFF" or (locked and "LOCKED" or (mappingBlocked and "API MAP" or (applyHealthy and "ON" or "RETRY")))
        local profile = currentProfile ~= "" and currentProfile or "--"
        local mode    = adaptiveEngine and "Adaptive" or "Classic"
        SetText(statusLabel, status .. " | " .. profile .. " | " .. mode .. (upgrade and " +Upgrade" or ""))
    end

    Refresh()
    updateConnection = RunService.RenderStepped:Connect(function(dt)
        if not runtime.alive or not monitorEnabled then
            return
        end
        if not IsFinite(dt) or dt <= 0 then
            return
        end
        frames  = frames + 1
        elapsed = elapsed + dt
        if elapsed >= MONITOR_INTERVAL then
            Refresh(math.floor(frames / elapsed + 0.5))
            elapsed = 0
            frames  = 0
        end
    end)
end

local function Reconfigure(invalidate)
    if invalidate then
        lastApplied = {}
        lastSetters = {}
    end
    if enabled and not locked then
        Update()
    end
    SyncWorker()
end

runtime.handlers["Auto Revert"] = function(v)
    enabled = v
    Reconfigure(v)
    Notify("Auto Revert: " .. (v and "ON" or "OFF"), 2)
end

runtime.handlers["Adaptive Engine"] = function(v)
    if adaptiveEngine ~= v then
        adaptiveEngine = v
        smoothedPing = rawPing
        currentProfile = ""
    end
    Reconfigure(false)
    Notify("Adaptive Engine: " .. (v and "ON" or "OFF"), 2)
end

runtime.handlers["Lock Config"] = function(v)
    locked = v
    Reconfigure(not v)
    Notify("Config: " .. (v and "LOCKED" or "UNLOCKED"), 2)
end

runtime.handlers["Upgrade Mode"] = function(v)
    upgrade = v
    SyncUpgrade(GetInternal())
    Reconfigure(true)
    Notify("Upgrade Mode: " .. (v and "ON" or "OFF"), 2)
end

runtime.handlers["Monitor"] = function(v)
    monitorEnabled = v
    if v then
        SamplePing()
        CreateMonitor()
        if not monitorEnabled then
            values["Monitor"] = false
            SetToggleValue("Monitor", false)
        else
            Notify("Monitor enabled", 2)
        end
    else
        DestroyMonitor()
        Notify("Monitor disabled", 2)
    end
    SyncWorker()
end

runtime.handlers["FPS Boost"] = function(v)
    local ok = SetFPSBoost(v)
    if v and not ok then
        values["FPS Boost"] = false
        SetToggleValue("FPS Boost", false)
    end
    Notify("FPS Boost: " .. (ok and (v and "ON" or "OFF") or "FAILED"), 2)
end

for name in pairs(defaults) do
    local handler = runtime.handlers[name]
    local function MakePersistentHandler(settingName, callback)
        return function(state)
            values[settingName] = state == true
            local result = callback(state)
            if not runtime.initializing then SavePreferences() end
            return result
        end
    end
    runtime.handlers[name] = MakePersistentHandler(name, handler)
end

runtime.Cleanup = function()
    runtime.alive = false
    workerToken = nil
    DestroyMonitor()
    return SetFPSBoost(false)
end

runtime.handlers["Print Telemetry"] = function()
    SamplePing()
    local text = string.format(
        "Ping=%d ms | Raw=%d | Jitter=%d | Source=%s | Profile=%s | Mode=%s",
        GetPing(), rawPing, math.floor(jitter + 0.5), pingSource,
        currentProfile ~= "" and currentProfile or "--",
        adaptiveEngine and "Adaptive" or "Classic"
    )
    Notify(text, 4)
    print("[Omega] " .. text)
    PrintPresetDiagnostics()
    print("[Omega Save] " .. storage.status .. " | " .. SETTINGS_FILE)
end

ui.runtime = runtime
local names = { "Auto Revert", "Adaptive Engine", "Lock Config", "Upgrade Mode", "Monitor", "FPS Boost" }

if not reuseUI then
    local function RegisterToggle(name)

        ui.toggleStates[name] = false
        local ok, toggle = pcall(function()
            return ui.section:AddToggle(name, function(value)
                local state = value == true
                ui.toggleStates[name] = state
                local active = ui.runtime
                if not active or not active.alive or active.initializing then
                    return
                end
                active.values[name] = state
                local handler = active.handlers[name]
                if handler then
                    handler(state)
                end
            end)
        end)
        if not ok or type(toggle) ~= "function" then
            runtime.Cleanup()
            warn("[Omega] AddToggle must return a closure for " .. name .. ": " .. tostring(toggle))
            return false
        end
        ui.toggles[name] = toggle
        return true
    end

    for _, name in ipairs(names) do
        if not RegisterToggle(name) then
            return
        end
    end

    local ok, err = pcall(function()
        ui.section:AddLabel("Credits: Noir_Creator")
        SR_Paragraph(ui.section, "About", "Adapts MM2_GPL settings to current ping. Adaptive mode interpolates control points; Classic uses profiles A-D. Disabling Auto Revert stops updates; it does not restore MM2 settings.")
        SR_Paragraph(ui.section, "Compatibility", "The UI uses odh_shared_plugins. Auto Revert additionally requires odh_internal_shared.MM2_GPL from the original CFG.")
        ui.section:AddButton("Print Telemetry", function()
            local active = ui.runtime
            if active and active.alive and not active.initializing then
                active.handlers["Print Telemetry"]()
            end
        end)
    end)
    if not ok then
        runtime.Cleanup()
        warn("[Omega] UI registration failed: " .. tostring(err))
        return
    end
end

for _, name in ipairs(names) do
    if not SetToggleValue(name, values[name]) then
        ui.complete = false
        runtime.Cleanup()
        return
    end
end
ui.complete = true

if upgrade then
    SyncUpgrade(GetInternal())
elseif odh_internal_shared then
    SyncUpgrade(odh_internal_shared)
end

if values["FPS Boost"] then
    runtime.handlers["FPS Boost"](true)
end
if values["Monitor"] then
    runtime.handlers["Monitor"](true)
end
Reconfigure(false)

runtime.initializing = false
ReportStorageIssue()
if not storage.skipInitialSave then SavePreferences() end

end
end)

SR_UI.tryModule("Emotes", function()
do

local shared=odh_shared_plugins
if not shared or type(shared.CreateTab)~="function" then
    warn("[ODH Emotes] Load through the current Overdrive H plugin menu.")
    return
end
local KEY="ODH_7yd7_EmotesRuntime_v1"
if type(_G[KEY])=="table" and _G[KEY].alive then
    if type(shared.Notify)=="function" then pcall(shared.Notify,"Emotes is already loaded. Use its existing tab.",4) end
    return
end
local Players=SR_UI.service("Players")
local Player=Players.LocalPlayer
if not Player then warn("[ODH Emotes] LocalPlayer unavailable.");return end
local HttpService=SR_UI.service("HttpService")
local RunService=SR_UI.service("RunService")
local runtime={version=7,alive=true,initializing=true,generation=0,filterGeneration=0,page=1,catalog={},filtered={},resolutions={},connections={}}
local prefs={windowTransparency=22,thumbnailSize=68,thumbnailPresetVersion=2,playbackModeVersion=2,shortcuts={},browserOnLoad=false,loop=false,walk=false,speed=1,favoritesOnly=false,query="",customId="",customKind="Catalog emote ID",favorites={}}
local FILE="ODH_Emotes_settings.json"
local CACHE="ODH_Emotes_catalog.json"
local URL="https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/EmoteSniper.json"
local PAGE_SIZE=12
local MAX_SHORTCUTS=12
local warnings={}
local function Notify(text)
    if not SR_Gate(text) then return end
    if type(shared.Notify)=="function" then pcall(shared.Notify,"Emotes: "..text,5) end
end
local function WarnOnce(key,text)
    if warnings[key] then return end
    warnings[key]=true;warn("[ODH Emotes] "..text);Notify(text)
end
local env={}
if type(getgenv)=="function" then
    local ok,value=pcall(getgenv)
    if ok and type(value)=="table" then env=value end
end
local read=type(readfile)=="function" and readfile or env.readfile
local write=type(writefile)=="function" and writefile or env.writefile
local exists=type(isfile)=="function" and isfile or env.isfile
local canSave=SR_Store.CanWrite() or SR_Store.CanRead() or SR_Store.mem~=nil
runtime.settingsFile=FILE
runtime.saveStatus=canSave and "Not saved" or "Session only"
runtime.preferences=prefs
local function AssetId(value)
    if type(value)~="number" and type(value)~="string" then return nil end
    local id=tonumber(value)
    if id and id==id and id>0 and id<9007199254740992 and id==math.floor(id) then return id end
end
local function IdText(id) return string.format("%.0f",id) end
local function ParseId(text)
    if type(text)~="string" then return nil end
    local digits=text:match("^%s*(%d+)%s*$") or text:match("^rbxassetid://(%d+)$")
        or text:match("[?&]id=(%d+)") or text:match("roblox%.com/catalog/(%d+)")
    return digits and AssetId(digits)
end
local function Item(value)
    if type(value)~="table" then return nil end
    local id=AssetId(value.id)
    if not id then return nil end
    local name=type(value.name)=="string" and value.name:gsub("[%c]"," ") or ("Emote "..IdText(id))
    if #name==0 or #name>2000 then name="Emote "..IdText(id) end
    return {id=id,name=name}
end
local function ReadJSON(path)
    if not SR_Store.CanRead() and not SR_Store.mem then return nil,"unavailable" end
    local text=SR_Store.read(path)
    if not text then return nil,"missing" end
    local decoded,data=pcall(function() return HttpService:JSONDecode(text) end)
    if not decoded or type(data)~="table" then return nil,"invalid JSON" end
    return data
end
local function LoadSettings()
    if not canSave then WarnOnce("files","readfile/writefile unavailable; settings are session-only.");return end
    local data,err=ReadJSON(FILE)
    if not data and err~="missing" then

        local backup=ReadJSON(FILE .. ".bak")
        if backup then
            data,err=backup,"ok"
            WarnOnce("read","Settings file was corrupted; restored from the backup copy.")
        end
    end
    if not data then
        if err~="missing" then WarnOnce("read","Settings not loaded ("..tostring(err).."). Existing file is kept until you change a setting.") end
        return
    end
    if data.version~=1 or type(data.values)~="table" then
        WarnOnce("read","Invalid settings; existing file is kept until you change a setting.");return
    end
    local values=data.values

    if values.playbackModeVersion==2 and type(values.loop)=="boolean" then prefs.loop=values.loop end
    if type(values.shortcuts)=="table" then
        local count=0
        for _,value in pairs(values.shortcuts) do
            local item=Item(value)
            if item then
                local function position(number,default)
                    if type(number)=="number" and number==number and number>-math.huge and number<math.huge then
                        return math.clamp(number,0,1)
                    end
                    return default
                end
                item.x=position(value.x,.75);item.y=position(value.y,.45)
                prefs.shortcuts[IdText(item.id)]=item;count=count+1
                if count>=MAX_SHORTCUTS then break end
            end
        end
    end
    for key,limits in pairs({windowTransparency={0,50},thumbnailSize={50,100}}) do
        local value=values[key]
        if type(value)=="number" and value==value and value>-math.huge and value<math.huge then
            prefs[key]=math.clamp(value,limits[1],limits[2])
        end
    end
    if values.thumbnailPresetVersion~=2 and prefs.thumbnailSize==78 then prefs.thumbnailSize=68 end
    for _,key in ipairs({"walk","favoritesOnly","browserOnLoad"}) do
        if type(values[key])=="boolean" then prefs[key]=values[key] end
    end
    if type(values.speed)=="number" and values.speed==values.speed and values.speed>-math.huge and values.speed<math.huge then prefs.speed=math.clamp(values.speed,0,3) end
    if type(values.query)=="string" then prefs.query=values.query:sub(1,200) end
    if type(values.customId)=="string" and #values.customId<=200 then prefs.customId=values.customId end
    if values.customKind=="Animation ID" then prefs.customKind=values.customKind end
    prefs.selected=Item(values.selected)
    if type(values.favorites)=="table" then
        local count=0
        for _,value in pairs(values.favorites) do
            local item=Item(value)
            if item then prefs.favorites[IdText(item.id)]=item;count=count+1 end
            if count>=10000 then break end
        end
    end
    runtime.saveStatus="Loaded"
end
local function SaveSettings()
    if runtime.initializing or not runtime.alive or not canSave then return false end
    local ok,err=pcall(function()
        local payload=HttpService:JSONEncode({version=1,values=prefs})
        local saved,why=SR_Store.write(FILE,payload)
        if not saved then error(why or "write failed") end
    end)
    if not ok then runtime.saveStatus="Write error";WarnOnce("write","Cannot save settings: "..tostring(err));return false end
    runtime.saveStatus="Saved";warnings.write=nil;return true
end
LoadSettings()

local BUILTIN={
    {id=3360689775,name="Salute"},
    {id=5915779043,name="Applaud"},
    {id=3360692915,name="Tilt"},
    {id=15610015346,name="Yungblud Happier Jump"},
    {id=14353423348,name="Baby Queen - Bouncy Twirl"},
    {id=14353421343,name="Baby Queen - Face Frame"},
    {id=3823158750,name="Godlike"},
    {id=139021427684680,name="KATSEYE - Touch"},
    {id=133596366979822,name="Biblically Accurate Emote"},
    {id=108128682361404,name="Rambunctious"},
    {id=79127989560307,name="Moon Walk"},
    {id=5230661597,name="Bored"},
    {id=14353425085,name="Baby Queen - Strut"},
    {id=15694504637,name="d4vd - Backflip"},
    {id=104142334418357,name="[Original] It's Gangnam Style!"},
    {id=16553249658,name="Mae Stephens - Piano Hands"},
    {id=12507097350,name="Alo Yoga Pose - Lotus Position"},
    {id=15698511500,name="Cuco - Levitate"},
    {id=4689362868,name="Sleep"},
    {id=111426928948833,name="Floating on clouds"},
    {id=130245358716273,name="The Weeknd Starboy Strut"},
    {id=120642514156293,name="Secret Handshake Dance"},
    {id=15506503658,name="Victory Dance"},
    {id=3576717965,name="Shy"},
    {id=73796726960568,name="Nyan Nyan! "},
    {id=78758922757947,name="Kicking Feet Sit"},
    {id=93511411593120,name="/e fly"},
    {id=114899970878842,name="R15 Death (Accurate)"},
    {id=5104377791,name="Hero Landing"},
    {id=5917570207,name="Floss Dance"},
    {id=131763631172236,name="Xaviersobased Emote"},
    {id=132074413582912,name="California Girl Dance"},
    {id=15554010118,name="Olivia Rodrigo Head Bop"},
    {id=112758073578333,name="Bubbly Sit"},
    {id=3716636630,name="Monkey"},
    {id=123015710605336,name="Onion"},
    {id=4646306583,name="Curtsy"},
    {id=85936805522788,name="Caramell"},
    {id=14900153406,name="TWICE Feel Special"},
    {id=102492229412911,name="Deltarune - Tenna Dance"},
    {id=133142324349281,name="Flopping Fish"},
    {id=10214406616,name="Frosty Flair - Tommy Hilfiger"},
    {id=120224229260879,name="Cute crouch "},
    {id=15679955281,name="Festive Dance"},
    {id=4849502101,name="Sad"},
    {id=10214418283,name="V Pose - Tommy Hilfiger"},
    {id=92853367837757,name="Garry's Dance"},
    {id=104485625389237,name="Make You Mine"},
    {id=139830733782518,name="Phut On"},
    {id=132382355371060,name="Tank Transformation"},
    {id=103046131635200,name="Scenario - LOVE SCENARIO"},
    {id=15123050663,name="Bone Chillin' Bop"},
    {id=124305244640379,name="Shattered"},
    {id=134311528115559,name="how did he hit every beat"},
    {id=17748346932,name="Elton John - Heart Shuffle"},
    {id=93105950995997,name="Caramelldansen"},
    {id=7466046574,name="Quiet Waves"},
    {id=96557878503341,name="Caramell Dansen"},
    {id=139859849852362,name="Dead"},
    {id=17360720445,name="HUGO Let's Drive!"},
    {id=103102322875221,name="Skibidi Toilet - Titan Speakerman Laser Spin"},
    {id=3576968026,name="Shrug"},
    {id=130998336536045,name="Gangnam Style"},
    {id=84555218084038,name="Helicopter Spin"},
    {id=71302743123422,name="Popular"},
    {id=133765015173412,name="DearALICE - Ariana"},
    {id=115319301809339,name="2 Phut Hon Dance"},
    {id=70635223083942,name="Be Not Afraid"},
    {id=17746270218,name="Sturdy Dance - Ice Spice"},
    {id=129149402922241,name="griddy"},
    {id=3576686446,name="Hello"},
    {id=113547795536875,name="Gangnam Style"},
    {id=126614732606871,name="Sit"},
    {id=3762654854,name="Greatest"},
    {id=16572756230,name="HIPMOTION - Amaarae"},
    {id=16276506814,name="Sol de Janeiro - Samba"},
    {id=3576823880,name="Point2"},
    {id=78459263478161,name="Family Man Death Pose"},
    {id=14900151704,name="TWICE LIKEY"},
    {id=3360686498,name="Stadium"},
    {id=15571540519,name="Nicki Minaj Starships"},
    {id=4940597758,name="Cower"},
    {id=11394056822,name="Elton John - Elevate"},
    {id=117734400993750,name="Virtual Singer Dance"},
    {id=97263450325496,name="Teto Territory"},
    {id=4102315500,name="Haha"},
    {id=79312439851071,name="Chappell Roan HOT TO GO!"},
    {id=105851216004006,name="Electro Swing"},
    {id=92707348383277,name="Mesmerizer"},
    {id=103139492736941,name="Deltarune - Tenna Swing Dance"},
    {id=15571538346,name="Nicki Minaj Boom Boom Boom"},
    {id=15554016057,name="Olivia Rodrigo Fall Back to Float"},
    {id=70615023659736,name="Floating"},
    {id=136740085081295,name="/e hidden animation"},
    {id=119431985170060,name="Helicopter"},
    {id=87141651594092,name="No-Clip/Speed Glitch"},
    {id=16303091119,name="Beauty Touchdown"},
    {id=3934986896,name="Dizzy"},
    {id=130726889233022,name="rolling crybaby"},
    {id=11309263077,name="Elton John - Heart Skip"},
    {id=84511772437190,name="Emote Loading. Please Wait... | spinning Robloxian"},
    {id=14353417553,name="Baby Queen - Air Guitar & Knee Slide"},
    {id=15392927897,name="Paris Hilton - Sliving For The Groove"},
    {id=94796833553521,name="TWICE Takedown pt 1 from Kpop Demon Hunters"},
    {id=120437019363089,name="peter griffin death pose"},
    {id=15506506103,name="Flex Walk"},
    {id=90608224567833,name="Proud to be Expendable - Pressure"},
    {id=18526338976,name="Team USA Breaking Emote"},
    {id=99818263438846,name="Default Dance"},
    {id=103197720369544,name="Dani's Gangnam Style"},
    {id=75017857395637,name="TV Time Dance"},
    {id=73683655527605,name="Fashion Roadkill"},
    {id=15392932768,name="Paris Hilton - Iconic IT-Grrrl"},
    {id=82217023310738,name="Thanos Happy Jump - Squid Game"},
    {id=102610758906338,name="Possessed"},
    {id=95323795166399,name="Rat Dance"},
    {id=127562607220778,name="Gangnam Style "},
    {id=129132611803602,name="Helicopter"},
    {id=82345302788133,name="Dia Delicia Dance"},
    {id=15392937495,name="Paris Hilton - Checking My Angles"},
    {id=4212496830,name="Zombie"},
    {id=113016438012253,name="⌛ Best Mates EMOTE [LIMITED]"},
    {id=110537281410647,name="[Aura Farm] Wall Lean Idle"},
    {id=92903522317071,name="ILLIT - Magnetic"},
    {id=122899100558551,name="It's TV Time!"},
    {id=75528418031928,name="Rambunctious"},
    {id=103040723950430,name="Gojo Floating"},
    {id=70788193750089,name="Kickn around"},
    {id=5915776835,name="High Wave"},
    {id=84195923658292,name="Jojo"},
    {id=110731335896907,name="[⌛ Limited]  HEADLESS EMOTE "},
    {id=139271706064778,name="Hip Bounce"},
    {id=4849499887,name="Happy"},
    {id=127271798262177,name="M3GAN's Dance"},
    {id=104304182344567,name="ONCE HOP HOP!"},
    {id=85623000473425,name="TWICE Takedown pt 2 from KPop Demon Hunters"},
    {id=84067050907557,name="Pickle Rick Dance"},
    {id=86982022610765,name="Caramelldansen"},
    {id=117301403779781,name="Im Talm Bout Innit"},
    {id=84822284410814,name="Maraschino Step"},
    {id=97847706148165,name="[NEW !] Caramelldansen Kawaii Dance"},
    {id=89174456614428,name="Laying Down - Daydreaming"},
    {id=91023138078288,name="OH WHO IS YOU"},
    {id=107978036345855,name="Prince Of Egypt Dance / What You Want"},
    {id=71363859760586,name="Golden Freddy Pose"},
    {id=80877772569772,name="Default Dance | OG"},
    {id=80436375269036,name="HEADLESS HOOPER"},
    {id=93262662842394,name="Sit"},
    {id=75703899901487,name="6 7 Transformation"},
    {id=100773414188482,name="Stray Kids Walkin On Water"},
    {id=131544122623505,name="Become A Car!"},
    {id=99005087791705,name="Death Pose"},
    {id=132384701706046,name="💀MM2 Fake Dead"},
    {id=129916107176034,name="Discombobulated"},
    {id=88598010609888,name="Angry Stomp "},
    {id=132508867759412,name="xavier so based emote"},
    {id=121167704249654,name="Hide"},
    {id=137873580964093,name="Floating Human Spinner (LIMITED) "},
    {id=76700167742736,name="Belly Dance"},
    {id=87826892596287,name="levitate"},
    {id=70972410468289,name="Fake Dead (Troll Emote)"},
    {id=134615135651900,name="Young-hee Head Spin - Squid Game"},
    {id=13823339506,name="Tommy - Archer"},
    {id=109755476052324,name="IShowSpeed Dance"},
    {id=124828909173982,name="Skibidi"},
    {id=4272351660,name="Fast Hands"},
    {id=137006085779408,name="Speed Glitch+"},
    {id=89633087256727,name="Weird Spin"},
    {id=125032357496729,name="Fake Death (BEST)"},
    {id=81177294287826,name="Hug"},
    {id=88721672617892,name="P.B.J.T."},
    {id=121259524934987,name="Xaviersobased Jig"},
    {id=121067808279598,name="PARROT PARTY DANCE"},
    {id=7202898984,name="Show Dem Wrists - KSI"},
    {id=120377619472998,name="Macarena"},
    {id=4940602656,name="Jumping Wave"},
    {id=94663026124741,name="Torture Dance"},
    {id=120896030393583,name="Get Sturdy"},
    {id=137261874619072,name="Sponge Dance"},
    {id=119746055344304,name="Plane"},
    {id=78620443286892,name="Cute Laying Down"},
    {id=108922782921118,name="📸 Pose for the Pic "},
    {id=131221550165951,name="Heart Hands Pose 3.0"},
    {id=119454955259757,name="Caramel Hip Sway"},
    {id=7202900159,name="Wake Up Call - KSI"},
    {id=79752538807060,name="Griddy"},
    {id=140466682449054,name="head spin"},
    {id=107899954696611,name="Spongebob Shuffle Dance 🧽"},
    {id=96405718067779,name="Cute Sit"},
    {id=4849497510,name="Power Blast"},
    {id=89413575288931,name="Blue Shirt Guy Dancing"},
    {id=112924687333965,name="Aura Farm"},
    {id=100782362883099,name="Car Transformation"},
    {id=102323907950469,name="Space Dance"},
    {id=110521067391235,name="The Old Jitterbug"},
    {id=111304332281521,name="Druski Shuffle"},
    {id=133600250245899,name="🥤 Soda Pop - Saja Boys"},
    {id=133477296392756,name="Rasputin – Boney M."},
    {id=122949892043249,name="[Aura Farm] Sit Idle"},
    {id=82739386299071,name="Jackpot Groove"},
    {id=80422524668416,name="Dreamer"},
    {id=97968838104258,name="Subject Three / AI Cat Chinese Dance"},
    {id=91274761264433,name="Macarena"},
    {id=3994130516,name="Bodybuilder"},
    {id=5938365243,name="Dolphin Dance"},
    {id=99563839802389,name="Jumpstyle"},
    {id=85361710130557,name="Caramelldansen"},
    {id=74646784680842,name="Ishowspeed shake "},
    {id=5230615437,name="Beckon"},
    {id=135489824748823,name="Magical Pose"},
    {id=98603994713783,name="Rat Dance"},
    {id=14353419229,name="Baby Queen - Dramatic Bow"},
    {id=84052327668385,name="Floating"},
    {id=97999370392804,name="Spin my Head"},
    {id=94319114655768,name="Rat Dance"},
    {id=86849720336961,name="Mr. Ant Tennas Dance - DELTARUNE"},
    {id=124754178569693,name="Die Lit!"},
    {id=80544397800234,name="Helicopter"},
    {id=100532972764499,name="MONSTER MASH"},
    {id=88922397617835,name="What You Want"},
    {id=115810068374896,name="Garry's Dance"},
    {id=75842745124834,name="Human Snake"},
    {id=94451497143711,name="Hakari Dance"},
    {id=128972617664804,name="Fortnite Default Dance"},
    {id=73556976257737,name="Saja Boy Pose - Jinu"},
    {id=81390693780805,name="PROXIMA"},
    {id=17000058939,name="Mini Kong"},
    {id=97629500912487,name="BlockyKick Dance"},
    {id=112949099442762,name="Griddy"},
    {id=130641944883645,name=" Jinu Pose - Saja Boys"},
    {id=108474079699304,name="Dep"},
    {id=4049646104,name="Line Dance"},
    {id=91423783304464,name="criss cross sit"},
    {id=90524692306889,name="[⏳] Chill Sit"},
    {id=15506496093,name="Rock n Roll"},
    {id=134737246939931,name="GAG IT DEATH DROP"},
    {id=71787387963141,name="Worm Dance"},
    {id=128658037413893,name="I'm Going To Die Here - Pressure"},
    {id=99568437064777,name="Relaxed Sit"},
    {id=83018514370428,name="Stargazing"},
    {id=92859581691366,name="ALTÉGO - Couldn’t Care Less"},
    {id=94534169345613,name="Casual Sit"},
    {id=16126526506,name="Paris Hilton Sanasa"},
    {id=140037329261678,name="Caramel dance"},
    {id=94118707925458,name="Go Mufasa"},
    {id=105730788757021,name="Dani's BIRDBRAIN"},
    {id=91927498467600,name="Koto Nai Meme Dance"},
    {id=117450501566142,name="Hide Hidden Box Invisible Camo Emote Small tiny"},
    {id=4272484885,name="Baby Dance"},
    {id=88024974500195,name="Oppa Gangnam Style"},
    {id=7202896732,name="Boxing Punch - KSI"},
    {id=128792127841374,name="Watching silly videos (Or texting)"},
    {id=87756443172440,name="xavier so based dance"},
    {id=116770268279002,name="BirdBrain Teto"},
    {id=124935873390035,name="Hiding Human Box"},
    {id=94121796810251,name="Kicking Feet And Blushing"},
}

local statusLabel,catalogLabel,selectedLabel,searchLabel,customLabel
local function Label(control,text)
    if control then pcall(function() control:SetValue(text) end) end
end
local function Status(text)
    runtime.status=text;Label(statusLabel,text)
    if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end
end
local function Dispose(track,animation)
    if track then
        pcall(function() track:Stop(0) end)
        pcall(function() track:Destroy() end)
    end
    if animation then pcall(function() animation:Destroy() end) end
end
local function StopCurrent(message)
    runtime.generation=runtime.generation+1
    if runtime.endedConnection then runtime.endedConnection:Disconnect();runtime.endedConnection=nil end
    local track,animation=runtime.track,runtime.animation
    runtime.track=nil;runtime.animation=nil;runtime.character=nil;runtime.playing=nil
    Dispose(track,animation)
    if message then Status(message) end
end
runtime.Stop=function() StopCurrent("Stopped") end
local function Current(ticket,character)
    return runtime.alive and runtime.generation==ticket and Player.Character==character
end
local function ResolveCatalog(id)
    if runtime.resolutions[id] then return runtime.resolutions[id] end
    local ok,objects=pcall(function() return game:GetObjects("rbxassetid://"..IdText(id)) end)
    if not ok or type(objects)~="table" then return nil end
    local resolved

    pcall(function()
        for _,root in ipairs(objects) do
            if root:IsA("Animation") then resolved=ParseId(root.AnimationId) end
            if not resolved then
                local descendants=root:GetDescendants()
                for i,obj in ipairs(descendants) do
                    if i>4000 then break end
                    if obj:IsA("Animation") then resolved=ParseId(obj.AnimationId);if resolved then break end end
                end
            end
            if resolved then break end
        end
    end)
    for _,root in ipairs(objects) do pcall(function() root:Destroy() end) end
    if resolved then runtime.resolutions[id]=resolved end
    return resolved
end
local function Play(item,direct)
    if not runtime.alive then return end
    if not item or not AssetId(item.id) then Notify("Select an emote or enter a valid ID first.");return end
    StopCurrent()
    local ticket=runtime.generation
    local character=Player.Character
    if not character then Status("Waiting for character — press Play after spawning");return end
    Status("Loading: "..item.name)
    task.spawn(function()
        local track,animation
        local ok,err=pcall(function()
            if not Current(ticket,character) then return end
            local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",8)
            if not Current(ticket,character) then return end
            if not humanoid or humanoid.Health<=0 then error("Character is not ready") end
            if humanoid.RigType~=Enum.HumanoidRigType.R15 then error("R15 character required") end
            local animator=humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator",8)
            if not Current(ticket,character) then return end
            if not animator then error("Animator is not ready") end
            local animationId=direct and item.id or ResolveCatalog(item.id)
            if not Current(ticket,character) then return end
            if not animationId and not direct then

                local nativeOK,nativeTrack=pcall(function() return humanoid:PlayEmoteAndGetAnimTrackById(item.id) end)
                if nativeOK and nativeTrack and typeof(nativeTrack)=="Instance" and nativeTrack:IsA("AnimationTrack") then track=nativeTrack end
                if not Current(ticket,character) then return end
            end
            if not track then
                animation=Instance.new("Animation")
                animation.AnimationId="rbxassetid://"..IdText(animationId or item.id)
                track=animator:LoadAnimation(animation)
            end
            if not Current(ticket,character) then return end
            if not track then error("Roblox did not return an animation track") end
            track.Priority=Enum.AnimationPriority.Action
            track.Looped=prefs.loop
            if not track.IsPlaying then track:Play(0.05,1,prefs.speed) else track:AdjustSpeed(prefs.speed) end
            runtime.track=track;runtime.animation=animation;runtime.character=character
            runtime.playing=item
            runtime.endedConnection=track.Ended:Connect(function()
                if runtime.track==track and Current(ticket,character) then StopCurrent("Finished: "..item.name) end
            end)

            local deadline=os.clock()+8
            while Current(ticket,character) and runtime.track==track and track.Length<=0 and os.clock()<deadline do task.wait(0.1) end
            if not Current(ticket,character) or runtime.track~=track then return end
            if track.Length<=0 then error("Animation did not load. It may be restricted, deleted, or incompatible.") end
            Status("Playing: "..item.name)
        end)
        if not Current(ticket,character) then

            if runtime.track~=track then Dispose(track,animation) end
            return
        end
        if not ok then
            if runtime.track==track then StopCurrent() else Dispose(track,animation) end
            Status("Cannot play this emote")
            Notify(tostring(err))
        end
    end)
end
runtime.Play=function(id,name,direct) Play({id=id,name=name or IdText(id)},direct==true) end
runtime.SaveSettings=SaveSettings
runtime.connections[#runtime.connections+1]=Player.CharacterAdded:Connect(function(character)
    runtime.character=character
    runtime.humanoid=nil
    StopCurrent("Respawned — select an emote and press Play")
end)

runtime.connections[#runtime.connections+1]=RunService.Heartbeat:Connect(function()
    if not runtime.alive or not runtime.track then return end
    local character=runtime.character
    local humanoid=runtime.humanoid
    if not humanoid or humanoid.Parent~=character then
        humanoid=character and character:FindFirstChildOfClass("Humanoid") or nil
        runtime.humanoid=humanoid
    end
    if Player.Character~=character or not humanoid or humanoid.Health<=0 then StopCurrent("Stopped");return end
    if not prefs.walk and humanoid.MoveDirection.Magnitude>0.05 then StopCurrent("Stopped on movement") end
end)
function runtime.Cleanup()
    runtime.alive=false;runtime.filterGeneration=runtime.filterGeneration+1
    StopCurrent()
    for _,connection in ipairs(runtime.connections) do connection:Disconnect() end
    if runtime.DestroyBrowser then runtime.DestroyBrowser() end
end

local dropdown,pageLabel
local displayed={}
local syncing=false
local SENTINEL="— Select an emote —"
local function NormalizeCatalog(data)
    if type(data)~="table" then return nil end
    local source=type(data.data)=="table" and data.data or data
    local items,seen={},{}
    for i,value in ipairs(source) do
        if i>100000 then break end
        local item=Item(value)
        if item and not seen[item.id] then
            seen[item.id]=true;items[#items+1]=item
        end
    end
    return #items>0 and items or nil
end
local function SelectionLabel()
    local item=prefs.selected
    Label(selectedLabel,item and ("Selected: "..item.name.." ["..IdText(item.id).."]") or "Selected: none")
    if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end
end
local function RenderPage()
    if not runtime.alive then return end
    local pages=math.max(1,math.ceil(#runtime.filtered/PAGE_SIZE))
    runtime.page=math.clamp(runtime.page,1,pages)
    local names={SENTINEL}
    displayed={}
    local selectedText=SENTINEL
    for i=(runtime.page-1)*PAGE_SIZE+1,math.min(runtime.page*PAGE_SIZE,#runtime.filtered) do
        local item=runtime.filtered[i]
        local text=item.name.." ["..IdText(item.id).."]"
        names[#names+1]=text;displayed[text]=item
        if prefs.selected and prefs.selected.id==item.id then selectedText=text end
    end
    if dropdown then
        syncing=true
        local ok,err=pcall(function() dropdown:ChangeItems(names);dropdown:Select(selectedText) end)
        syncing=false
        if not ok then WarnOnce("dropdown","Could not update the emote list: "..tostring(err)) end
    end
    Label(pageLabel,"Page "..runtime.page.." / "..pages.." • matches: "..#runtime.filtered.." • catalog: "..#runtime.catalog)
    SelectionLabel()
    if runtime.RenderCards then runtime.RenderCards() end
end
local function Filter(resetPage)
    runtime.filterGeneration=runtime.filterGeneration+1
    local ticket=runtime.filterGeneration
    local query=prefs.query:lower()
    local favoritesOnly=prefs.favoritesOnly
    local source=runtime.catalog
    if favoritesOnly then
        source={}
        for _,item in pairs(prefs.favorites) do source[#source+1]=item end
        table.sort(source,function(a,b) return a.name:lower()<b.name:lower() end)
    end
    local words={}
    for word in query:gmatch("%S+") do words[#words+1]=word end
    runtime.filtering=true
    if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end
    Label(searchLabel,"Search: "..(prefs.query=="" and "(all)" or prefs.query))
    task.spawn(function()
        local filtered={}
        for i,item in ipairs(source) do
            if not runtime.alive or runtime.filterGeneration~=ticket then return end
            local haystack=item.name:lower().." "..IdText(item.id)
            local matches=true
            for _,word in ipairs(words) do
                if not haystack:find(word,1,true) then matches=false;break end
            end
            if matches then filtered[#filtered+1]=item end
            if i%500==0 then task.wait() end
        end
        if not runtime.alive or runtime.filterGeneration~=ticket then return end
        runtime.filtered=filtered;runtime.filtering=false
        if resetPage then runtime.page=1 end
        RenderPage()
    end)
end
local function AdoptCatalog(items,source)
    runtime.catalog=items
    runtime.catalogSource=source
    Label(catalogLabel,"Catalog: "..#items.." emotes • "..source)

    if not prefs.selected then prefs.selected=items[1] end
    SelectionLabel()
    Filter(true)
end
local function RefreshCatalog()
    if not runtime.alive or runtime.catalogBusy then return end
    runtime.catalogBusy=true
    Label(catalogLabel,"Updating catalog... current list remains available")
    task.spawn(function()
        local ok,data=pcall(function() return HttpService:JSONDecode(game:HttpGet(URL)) end)
        if not runtime.alive then return end
        local items=ok and NormalizeCatalog(data) or nil
        runtime.catalogBusy=false
        if not items then
            Label(catalogLabel,"Catalog: "..#runtime.catalog.." • offline / update failed")
            WarnOnce("network","Catalog update failed. The cached or built-in list remains available.")
            return
        end
        warnings.network=nil
        AdoptCatalog(items,"7yd7 online catalog")
        if SR_Store.CanWrite() then
            local saved=SR_Store.write(CACHE,HttpService:JSONEncode({version=1,data=items}))
            if not saved then WarnOnce("cache","Could not save the catalog cache; the list still works this session.") end
        end
    end)
end
runtime.RefreshCatalog=RefreshCatalog

do
    local UI={cards={},connections={},searchToken=0,renderToken=0}
    runtime.browser=UI
    local C={navy=Color3.fromRGB(7,20,35),teal=Color3.fromRGB(9,72,76),
        panel=Color3.fromRGB(10,40,49),accent=Color3.fromRGB(79,235,182),
        white=Color3.fromRGB(235,247,251),muted=Color3.fromRGB(151,185,195)}
    local function Make(class,props,parent)
        local obj=Instance.new(class)
        for key,value in pairs(props or {}) do obj[key]=value end
        obj.Parent=parent
        return obj
    end
    local function Round(obj,radius)
        Make("UICorner",{CornerRadius=UDim.new(0,radius or 12)},obj)
    end
    local function Stroke(obj,color,transparency,thickness)
        return Make("UIStroke",{Color=color or C.accent,Transparency=transparency or .75,Thickness=thickness or 1},obj)
    end
    local function Gradient(obj,a,b,rotation)
        Make("UIGradient",{Color=ColorSequence.new(a,b),Rotation=rotation or 35},obj)
    end
    local function Text(parent,text,size,pos,dimensions)
        return Make("TextLabel",{BackgroundTransparency=1,Text=text,TextColor3=C.white,
            Font=Enum.Font.GothamMedium,TextSize=size,TextXAlignment=Enum.TextXAlignment.Left,
            TextTruncate=Enum.TextTruncate.AtEnd,Position=pos,Size=dimensions},parent)
    end
    local function Button(parent,text,pos,dimensions)
        local b=Make("TextButton",{Text=text,TextColor3=C.white,Font=Enum.Font.GothamMedium,TextSize=15,
            AutoButtonColor=true,Active=true,BackgroundColor3=C.panel,BackgroundTransparency=.08,BorderSizePixel=0,Position=pos,Size=dimensions},parent)
        Round(b,9);return b
    end
    local function Box(parent,placeholder,pos,dimensions)
        local b=Make("TextBox",{Text="",PlaceholderText=placeholder,PlaceholderColor3=C.muted,TextColor3=C.white,
            Font=Enum.Font.Gotham,TextSize=15,TextXAlignment=Enum.TextXAlignment.Left,
            ClearTextOnFocus=false,BackgroundColor3=C.navy,BackgroundTransparency=.08,BorderSizePixel=0,Position=pos,Size=dimensions},parent)
        Round(b,9)
        Make("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,placeholder=="Search name or ID..." and 40 or 10)},b)
        return b
    end
    local function Connect(signal,fn)
        local connection=signal:Connect(fn);UI.connections[#UI.connections+1]=connection;return connection
    end
    local function SyncNative()
        if runtime.SyncNative then runtime.SyncNative() end
    end
    local function Commit()
        SaveSettings();SyncNative()
    end
    local function Focused(box)
        local ok,value=pcall(function() return box:IsFocused() end)
        return ok and value
    end
    local function SetChoice(item)
        prefs.selected={id=item.id,name=item.name};Commit();SelectionLabel()
    end

    UI.quickButtons={}
    local function QuickViewport()
        local viewport=UI.canvas and UI.canvas.AbsoluteSize
        if not viewport or viewport.X<1 or viewport.Y<1 then
            viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(900,600)
        end
        return viewport
    end
    local function PlaceQuick(record)
        local vp=QuickViewport()
        local saved=prefs.shortcuts[record.key]
        if not saved then return end
        local x=math.clamp(saved.x*vp.X,38,math.max(38,vp.X-38))
        local y=math.clamp(saved.y*vp.Y,38,math.max(38,vp.Y-38))
        record.button.Position=UDim2.fromOffset(x,y)
    end
    local function RefreshQuickVisuals()
        for _,record in pairs(UI.quickButtons) do
            local playing=runtime.track and runtime.playing and runtime.playing.id==record.item.id
            record.outline.Color=playing and C.accent or C.muted
            record.outline.Transparency=playing and .05 or .3
            record.button.Visible=UI.root~=nil and not UI.hidden
        end
    end
    local function CreateQuick(key,saved)
        local button=Make("ImageButton",{Name="QuickEmote_"..key,AnchorPoint=Vector2.new(.5,.5),
            Size=UDim2.fromOffset(56,56),BackgroundColor3=C.navy,BackgroundTransparency=.58,
            Image="rbxthumb://type=Asset&id="..key.."&w=420&h=420",ScaleType=Enum.ScaleType.Fit,
            BorderSizePixel=0,AutoButtonColor=true,Active=true,ZIndex=50,Visible=false},UI.canvas)
        Round(button,11)
        local record={button=button,key=key,item={id=saved.id,name=saved.name},outline=Stroke(button,C.muted,.3,1.5),moved=false}
        UI.quickButtons[key]=record
        button.InputBegan:Connect(function(input)
            if not runtime.alive then return end
            if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
            record.moved=false;record.suppressUntil=nil
            UI.quickDrag={record=record,input=input,start=input.Position,
                center=Vector2.new(button.Position.X.Offset,button.Position.Y.Offset)}
        end)
        button.Activated:Connect(function()
            if not runtime.alive or not prefs.shortcuts[key] then return end
            if record.moved or (record.suppressUntil and os.clock()<record.suppressUntil) then return end
            SetChoice(record.item)

            Play(record.item,false)
        end)
        PlaceQuick(record)
    end
    function runtime.SyncQuickButtons()
        if not UI.canvas or not UI.root then return end
        for key,record in pairs(UI.quickButtons) do
            if not prefs.shortcuts[key] then
                if UI.quickDrag and UI.quickDrag.record==record then UI.quickDrag=nil end
                record.button:Destroy();UI.quickButtons[key]=nil
            end
        end
        for key,saved in pairs(prefs.shortcuts) do
            if not UI.quickButtons[key] then CreateQuick(key,saved) end
        end
        RefreshQuickVisuals()
    end
    function runtime.ClearQuickButtons()
        prefs.shortcuts={};SaveSettings();runtime.SyncQuickButtons()
        if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end
    end
    local function ToggleQuick(item)
        local key=IdText(item.id)
        if prefs.shortcuts[key] then
            prefs.shortcuts[key]=nil
        else
            local count=0
            for _ in pairs(prefs.shortcuts) do count=count+1 end
            if count>=MAX_SHORTCUTS then Notify("Up to "..MAX_SHORTCUTS.." screen buttons. Unpin one first.");return end
            local vp=QuickViewport()
            local firstY=math.max(48,vp.Y*.3)
            local rows=math.max(1,math.floor((vp.Y-38-firstY)/78)+1)
            local x=math.clamp(vp.X-52-math.floor(count/rows)*78,38,math.max(38,vp.X-38))
            local y=math.clamp(firstY+(count%rows)*78,38,math.max(38,vp.Y-38))
            prefs.shortcuts[key]={id=item.id,name=item.name,x=x/vp.X,y=y/vp.Y}
        end

        runtime.SyncQuickButtons()
        if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end
        SaveSettings()
    end
    local function QuickInputChanged(input)
        local drag=UI.quickDrag
        if not drag then return end
        if input~=drag.input and not (drag.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then return end
        local dx,dy=input.Position.X-drag.start.X,input.Position.Y-drag.start.Y
        if not drag.record.moved and dx*dx+dy*dy<64 then return end
        drag.record.moved=true
        local saved=prefs.shortcuts[drag.record.key]
        if not saved then UI.quickDrag=nil;return end
        local vp=QuickViewport()
        saved.x=math.clamp((drag.center.X+dx)/vp.X,0,1)
        saved.y=math.clamp((drag.center.Y+dy)/vp.Y,0,1)
        PlaceQuick(drag.record)
    end
    local function QuickInputEnded(input)
        local drag=UI.quickDrag
        if not drag or drag.input~=input then return end
        UI.quickDrag=nil
        if drag.record.moved then
            drag.record.suppressUntil=os.clock()+.3
            SaveSettings()
        end
    end
    local function SetVisible(value)
        if not UI.root then return end
        UI.hidden=false
        UI.screen.Enabled=true
        UI.root.Visible=value;UI.launcher.Visible=not value
        if not value and UI.setSettingsVisible then UI.setSettingsVisible(false) end
        RefreshQuickVisuals()
        if value and runtime.RenderCards then runtime.RenderCards() end
    end
    local function Layout()
        if not UI.root then return end
        local viewport=UI.canvas.AbsoluteSize
        if viewport.X<1 or viewport.Y<1 then
            viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(900,600)
        end
        local width=math.max(240,math.min(1040,viewport.X-24))
        local height=math.max(240,math.min(650,viewport.Y-24))
        UI.root.Size=UDim2.fromOffset(width,height)
        if UI.center then
            UI.center=Vector2.new(math.clamp(UI.center.X,width/2,math.max(width/2,viewport.X-width/2)),
                math.clamp(UI.center.Y,height/2,math.max(height/2,viewport.Y-height/2)))
            UI.root.Position=UDim2.fromOffset(UI.center.X,UI.center.Y)
        else UI.root.Position=UDim2.fromScale(.5,.5) end
        local columns=width>=760 and 3 or (width>=500 and 2 or 1)
        local cellWidth=math.floor((width-48-(columns-1)*12)/columns)
        local short=height<400
        local scrollTop=short and 128 or 143
        local availableHeight=math.max(1,height-scrollTop-68)
        UI.viewHeight=availableHeight
        UI.scroll.Position=UDim2.fromOffset(16,scrollTop)
        UI.scroll.Size=UDim2.new(1,-32,1,-(scrollTop+68))
        local cellHeight=math.max(120,math.min(250,math.floor(cellWidth*.75),availableHeight-8))
        UI.grid.CellSize=UDim2.fromOffset(cellWidth,cellHeight)
        UI.grid.FillDirectionMaxCells=columns
        UI.columns=columns
        UI.root.BackgroundTransparency=prefs.windowTransparency/100
        UI.root.BackgroundColor3=Color3.new(1,1,1)
        local rows=math.ceil(#UI.cards/columns)
        UI.scroll.CanvasSize=UDim2.fromOffset(0,math.max(0,rows*(cellHeight+12)-12)+8)
        UI.compactCards=cellHeight<180
        local thumbAreaWidth=math.max(40,cellWidth-(UI.compactCards and 82 or 30))
        local thumbAreaHeight=math.max(36,cellHeight-(UI.compactCards and 58 or 100))
        local thumbSize=math.floor(math.min(thumbAreaWidth,thumbAreaHeight)*prefs.thumbnailSize/100)
        for _,card in ipairs(UI.cards) do
            card.frame.BackgroundTransparency=math.clamp(prefs.windowTransparency/100*.65,0,.35)
            card.image.Size=UDim2.fromOffset(thumbSize,thumbSize)
            if UI.compactCards then
                card.title.Size=UDim2.new(1,-70,0,34)
                card.image.Position=UDim2.fromOffset(12+thumbAreaWidth/2,48+thumbAreaHeight/2)
                local pinHeight=math.min(44,math.max(22,cellHeight-96))
                local pinTop=44+math.max(0,(cellHeight-95-pinHeight)/2)
                card.star.Position=UDim2.new(1,-56,0,3)
                card.pin.Size=UDim2.fromOffset(44,pinHeight)
                card.pin.Position=UDim2.new(1,-56,0,pinTop)
                card.dot.Position=UDim2.new(1,-34,0,pinTop+pinHeight/2)
                card.play.Position=UDim2.new(1,-56,1,-51)
                card.play.Size=UDim2.fromOffset(44,40)
                card.play.TextSize=22
                card.pin.BackgroundTransparency=1
            else
                card.title.Size=UDim2.new(1,-24,0,34)
                card.image.Position=UDim2.fromOffset(cellWidth/2,44+thumbAreaHeight/2)
                card.star.Position=UDim2.new(0,10,1,-52)
                card.pin.Size=UDim2.fromOffset(44,44)
                card.pin.Position=UDim2.new(0,58,1,-52)
                card.dot.Position=UDim2.new(0,80,1,-30)
                card.play.Position=UDim2.new(0,110,1,-52)
                card.play.Size=UDim2.new(1,-122,0,44)
                card.play.TextSize=14
                card.pin.BackgroundTransparency=.65
            end
        end
        local narrow=width<500
        UI.narrow=narrow
        local searchY=short and 46 or 56
        local searchHeight=short and 38 or 40
        UI.search.Position=UDim2.fromOffset(16,searchY)
        UI.search.Size=UDim2.new(1,narrow and -128 or -162,0,searchHeight)
        UI.favorites.Position=UDim2.new(1,narrow and -104 or -138,0,searchY)
        UI.favorites.Size=UDim2.fromOffset(narrow and 88 or 122,searchHeight)
        UI.summary.Position=UDim2.fromOffset(18,short and 88 or 103)
        UI.random.Position=UDim2.new(1,-186,0,short and 88 or 102)
        UI.stop.Position=UDim2.new(1,-94,0,short and 88 or 102)
        UI.sheet.Size=UDim2.fromOffset(math.min(380,width-24),math.min(460,height-24))
        if UI.alpha and not Focused(UI.alpha) then UI.alpha.Text=tostring(prefs.windowTransparency) end
        if UI.thumb and not Focused(UI.thumb) then UI.thumb.Text=tostring(prefs.thumbnailSize) end
        for _,record in pairs(UI.quickButtons) do PlaceQuick(record) end
    end
    runtime.ApplyBrowserAppearance=Layout
    function runtime.ResetBrowserPosition()
        UI.center=nil;Layout()
    end
    local function UpdateStatus()
        if not UI.root then return end
        UI.status.Text=runtime.status or "Ready — tap a card's play button"
        UI.summary.Text=runtime.filtering and "Searching..." or (#runtime.filtered.." emotes")
        UI.favorites.Text=prefs.favoritesOnly and (UI.narrow and "★ Saved" or "★ Favorites") or (UI.narrow and "☆ Saved" or "☆ Favorites")
        UI.favorites.BackgroundColor3=prefs.favoritesOnly and C.teal or C.panel
        UI.clearSearch.Visible=prefs.query~=""
        UI.favorites.TextColor3=prefs.favoritesOnly and C.accent or C.white
        UI.loop.Text=prefs.loop and "Loop: ON" or "Loop: OFF"
        UI.loop.TextColor3=prefs.loop and C.accent or C.white
        UI.walk.Text=prefs.walk and "Move: ON" or "Move: OFF"
        UI.walk.TextColor3=prefs.walk and C.accent or C.white
        if not Focused(UI.speed) then UI.speed.Text=tostring(prefs.speed) end
        if not Focused(UI.search) and UI.search.Text~=prefs.query then
            UI.syncing=true;UI.search.Text=prefs.query;UI.syncing=false
        end
        local pages=math.max(1,math.ceil(#runtime.filtered/PAGE_SIZE))
        UI.page.Text="Page "..runtime.page.." / "..pages.."  ·  tap to jump"
        UI.previous.TextTransparency=runtime.page<=1 and .6 or 0
        UI.next.TextTransparency=runtime.page>=pages and .6 or 0
        for _,card in ipairs(UI.cards) do
            local selected=prefs.selected and prefs.selected.id==card.item.id
            local playing=runtime.track and runtime.playing and runtime.playing.id==card.item.id
            card.outline.Color=selected and C.accent or C.muted
            card.outline.Transparency=selected and .1 or .82
            card.star.Text=prefs.favorites[IdText(card.item.id)] and "★" or "☆"
            card.star.TextColor3=prefs.favorites[IdText(card.item.id)] and C.accent or C.white
            card.dot.BackgroundTransparency=prefs.shortcuts[IdText(card.item.id)] and 0 or 1
            card.play.Text=playing and (UI.compactCards and "■" or "■ Stop") or (UI.compactCards and "▶" or "▶ Play")
            card.play.TextColor3=playing and C.navy or C.teal
            card.play.BackgroundColor3=playing and C.accent or C.white
        end
    end
    local updateCards=UpdateStatus
    UpdateStatus=function() updateCards();RefreshQuickVisuals() end
    runtime.UpdateCardStatus=UpdateStatus
    local function BuildCard(item,order)
        local frame=Make("Frame",{Name="Emote_"..IdText(item.id),LayoutOrder=order,
            BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=.14,BorderSizePixel=0,ClipsDescendants=true},UI.scroll)
        Round(frame,17);Gradient(frame,Color3.fromRGB(9,33,52),Color3.fromRGB(12,74,77),30)
        local outline=Stroke(frame,C.muted,.82)
        local title=Text(frame,item.name,14,UDim2.fromOffset(12,9),UDim2.new(1,-70,0,34))
        title.TextWrapped=true;title.TextTruncate=Enum.TextTruncate.None;title.TextYAlignment=Enum.TextYAlignment.Top
        local image=Make("ImageButton",{Name="Thumbnail",BackgroundTransparency=1,AutoButtonColor=false,
            AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(80,100),Size=UDim2.fromOffset(90,90),
            Image="rbxthumb://type=Asset&id="..IdText(item.id).."&w=420&h=420",ScaleType=Enum.ScaleType.Fit},frame)

        local dot=Make("Frame",{Name="PinRing",AnchorPoint=Vector2.new(.5,.5),
            Position=UDim2.new(1,-34,0,64),Size=UDim2.fromOffset(18,18),
            BackgroundColor3=C.white,BackgroundTransparency=1,BorderSizePixel=0,
            Active=false,ZIndex=19},frame)
        Round(dot,30);Stroke(dot,C.accent,0,2)
        local pin=Make("TextButton",{Name="ToggleScreenButton",Text="",BackgroundTransparency=1,
            Position=UDim2.new(1,-56,0,44),Size=UDim2.fromOffset(44,44),
            AutoButtonColor=false,Active=true,Selectable=true,ZIndex=20},frame)
        pin.BackgroundColor3=C.panel;Round(pin,9)
        pcall(function() pin.Interactable=true end)
        local lastPinTap=-math.huge
        local function PinTap()
            if not runtime.alive or not UI.root or not UI.root.Visible then return end
            local now=os.clock()

            if now-lastPinTap<.2 then return end
            lastPinTap=now
            local ok,err=pcall(ToggleQuick,item)
            if not ok then
                warn("[ODH Emotes] Screen button: "..tostring(err))
                Notify("Could not toggle the screen button: "..tostring(err))
            end
        end
        pin.Activated:Connect(PinTap)
        pin.MouseButton1Click:Connect(PinTap)
        pcall(function() pin.TouchTap:Connect(PinTap) end)
        local star=Button(frame,"☆",UDim2.new(1,-56,0,3),UDim2.fromOffset(44,42))
        star.BackgroundTransparency=1;star.TextSize=33
        local play=Button(frame,"▶",UDim2.new(1,-56,1,-51),UDim2.fromOffset(44,40))
        play.BackgroundColor3=C.white;play.TextColor3=C.teal;play.TextSize=22
        local card={item=item,frame=frame,title=title,image=image,star=star,play=play,pin=pin,dot=dot,outline=outline}
        UI.cards[#UI.cards+1]=card
        image.Activated:Connect(function() if runtime.alive then SetChoice(item);UpdateStatus() end end)
        star.Activated:Connect(function()
            if not runtime.alive then return end
            local key=IdText(item.id)
            if prefs.favorites[key] then prefs.favorites[key]=nil else prefs.favorites[key]={id=item.id,name=item.name} end
            Commit()
            if prefs.favoritesOnly then Filter(false) else UpdateStatus() end
        end)
        play.Activated:Connect(function()
            if not runtime.alive then return end
            local playing=runtime.track and runtime.playing and runtime.playing.id==item.id
            SetChoice(item)
            if playing then StopCurrent("Stopped") else Play(item,false) end
            UpdateStatus()
        end)
    end
    local function RenderCards()
        if not UI.root or not UI.root.Visible then return end
        local first=(runtime.page-1)*PAGE_SIZE+1
        local last=math.min(runtime.page*PAGE_SIZE,#runtime.filtered)
        local same=UI.renderPage==runtime.page and #UI.cards==math.max(0,last-first+1)
        if same then
            for index,card in ipairs(UI.cards) do
                if card.item~=runtime.filtered[first+index-1] then same=false;break end
            end
        end
        if not same then
            for _,card in ipairs(UI.cards) do card.frame:Destroy() end
            UI.cards={}
            UI.scroll.CanvasPosition=Vector2.zero
            for index=first,last do BuildCard(runtime.filtered[index],index-first+1) end
            UI.renderPage=runtime.page
        end
        UI.empty.Visible=#runtime.filtered==0
        UI.showAll.Visible=#runtime.filtered==0 and not runtime.filtering
        UI.empty.Text=runtime.filtering and "Searching..." or (prefs.favoritesOnly and "No favorites here yet.\nTap a star on any emote to add it." or "No emotes match this search.")
        Layout();UpdateStatus()
        if not same then
            UI.renderToken=UI.renderToken+1
            local ticket=UI.renderToken
            UI.scroll.CanvasPosition=Vector2.zero

            task.defer(function()
                if runtime.alive and UI.root and UI.renderToken==ticket then
                    UI.scroll.CanvasPosition=Vector2.zero
                end
            end)
        end
    end
    runtime.RenderCards=RenderCards
    local function Build()
        local gui=Make("ScreenGui",{Name="ODH_Emotes_Cards",ResetOnSpawn=false,IgnoreGuiInset=false,
            ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=70})
        UI.screen=gui
        local parent
        if type(gethui)=="function" then
            local ok,value=pcall(gethui);if ok and typeof(value)=="Instance" then parent=value end
        end
        parent=parent or Player:FindFirstChildOfClass("PlayerGui") or Player:WaitForChild("PlayerGui",5)
        if not parent then error("PlayerGui unavailable") end
        local parentOK=pcall(function() gui.Parent=parent end)
        if not parentOK then gui.Parent=Player:WaitForChild("PlayerGui",5) end
        UI.canvas=Make("Frame",{Name="Canvas",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
            Active=false},gui)
        UI.root=Make("Frame",{Name="CardBrowser",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
            Size=UDim2.fromOffset(1000,600),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=prefs.windowTransparency/100,BorderSizePixel=0,ClipsDescendants=true,Active=true},UI.canvas)
        Round(UI.root,18);Stroke(UI.root,C.muted,.4);Gradient(UI.root,C.navy,Color3.fromRGB(6,76,78),22)
        local accent=Make("Frame",{Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,0,3),BackgroundColor3=C.accent,BorderSizePixel=0},UI.root)
        Gradient(accent,C.teal,C.accent,0)
        local drag=Make("TextButton",{Name="DragHeader",Position=UDim2.fromOffset(0,3),Size=UDim2.new(1,-188,0,46),
            BackgroundTransparency=1,Text="",AutoButtonColor=false,Active=true},UI.root)
        Text(drag,"Emotes",23,UDim2.fromOffset(18,3),UDim2.new(1,-22,0,26))
        Text(drag,"R15 · Overdrive H · v7",10,UDim2.fromOffset(19,29),UDim2.new(1,-24,0,14)).TextColor3=C.muted
        UI.settings=Button(UI.root,"Settings",UDim2.new(1,-184,0,10),UDim2.fromOffset(80,36));UI.settings.TextSize=13
        local minimize=Button(UI.root,"—",UDim2.new(1,-96,0,10),UDim2.fromOffset(36,36))
        local close=Button(UI.root,"×",UDim2.new(1,-52,0,10),UDim2.fromOffset(36,36));close.TextSize=24
        UI.launcher=Button(UI.canvas,"Emotes  ▶",UDim2.new(0,16,.65,0),UDim2.fromOffset(112,42))
        UI.launcher.BackgroundColor3=C.teal;Stroke(UI.launcher,C.accent,.2);UI.launcher.Visible=false
        Connect(minimize.Activated,function() SetVisible(false) end)
        Connect(close.Activated,function() runtime.CloseBrowser() end)
        Connect(UI.launcher.Activated,function() SetVisible(true) end)
        UI.search=Box(UI.root,"Search name or ID...",UDim2.fromOffset(16,56),UDim2.new(1,-162,0,40))
        UI.search.Text=prefs.query
        UI.clearSearch=Button(UI.search,"×",UDim2.new(1,-36,0,0),UDim2.fromOffset(36,40))
        UI.clearSearch.BackgroundTransparency=1;UI.clearSearch.TextSize=22
        UI.favorites=Button(UI.root,"☆ Favorites",UDim2.new(1,-138,0,56),UDim2.fromOffset(122,40));UI.favorites.TextSize=13
        Connect(UI.favorites.Activated,function()
            prefs.favoritesOnly=not prefs.favoritesOnly;Commit();Filter(true);UpdateStatus()
        end)
        local function SearchNow()
            if UI.syncing or not runtime.alive then return end
            local value=UI.search.Text:sub(1,200)
            if value==prefs.query then return end
            prefs.query=value;Commit();Filter(true);UpdateStatus()
        end
        Connect(UI.clearSearch.Activated,function()
            UI.searchToken=UI.searchToken+1;prefs.query="";UI.syncing=true;UI.search.Text="";UI.syncing=false
            Commit();Filter(true)
        end)
        Connect(UI.search:GetPropertyChangedSignal("Text"),function()
            if UI.syncing then return end
            UI.clearSearch.Visible=UI.search.Text~=""
            UI.searchToken=UI.searchToken+1
            local ticket=UI.searchToken
            task.delay(.3,function() if runtime.alive and ticket==UI.searchToken then SearchNow() end end)
        end)
        Connect(UI.search.FocusLost,SearchNow)
        UI.summary=Text(UI.root,"Loading...",11,UDim2.fromOffset(18,103),UDim2.new(1,-204,0,26));UI.summary.TextColor3=C.muted
        local random=Button(UI.root,"Random",UDim2.new(1,-186,0,102),UDim2.fromOffset(84,32));random.TextSize=12
        local stop=Button(UI.root,"■ Stop",UDim2.new(1,-94,0,102),UDim2.fromOffset(78,32));stop.TextSize=13
        stop.TextColor3=Color3.fromRGB(255,184,178)
        Connect(stop.Activated,function() StopCurrent("Stopped") end)
        Connect(random.Activated,function()
            if runtime.filtering then Notify("Search is still updating.");return end
            if #runtime.filtered==0 then Notify("No matching emotes.");return end
            local item=runtime.filtered[math.random(1,#runtime.filtered)]
            SetChoice(item);Play(item,false);UpdateStatus()
        end)
        UI.scroll=Make("ScrollingFrame",{Name="Cards",Position=UDim2.fromOffset(16,143),Size=UDim2.new(1,-32,1,-211),
            BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=C.accent,
            AutomaticCanvasSize=Enum.AutomaticSize.None,CanvasSize=UDim2.fromOffset(0,0),ElasticBehavior=Enum.ElasticBehavior.Never,ScrollingDirection=Enum.ScrollingDirection.Y},UI.root)
        Make("UIPadding",{PaddingTop=UDim.new(0,2),PaddingLeft=UDim.new(0,2),PaddingRight=UDim.new(0,10),PaddingBottom=UDim.new(0,6)},UI.scroll)
        UI.grid=Make("UIGridLayout",{SortOrder=Enum.SortOrder.LayoutOrder,CellPadding=UDim2.fromOffset(12,12),
            CellSize=UDim2.fromOffset(300,240)},UI.scroll)
        UI.empty=Text(UI.root,"No emotes found",16,UDim2.new(0,28,0,149),UDim2.new(1,-56,1,-265))
        UI.empty.TextWrapped=true;UI.empty.TextXAlignment=Enum.TextXAlignment.Center;UI.empty.Visible=false
        UI.showAll=Button(UI.root,"Show all emotes",UDim2.new(.5,-85,1,-110),UDim2.fromOffset(170,38));UI.showAll.Visible=false
        Connect(UI.showAll.Activated,function() prefs.favoritesOnly=false;prefs.query="";Commit();Filter(true) end)
        local footer=Make("Frame",{Position=UDim2.new(0,16,1,-62),Size=UDim2.new(1,-32,0,56),BackgroundTransparency=1},UI.root)
        local prev=Button(footer,"‹",UDim2.fromOffset(0,0),UDim2.fromOffset(44,38));prev.TextSize=28
        local nextButton=Button(footer,"›",UDim2.new(1,-44,0,0),UDim2.fromOffset(44,38));nextButton.TextSize=28
        UI.page=Button(footer,"Page 1",UDim2.fromOffset(50,0),UDim2.new(1,-100,0,38));UI.page.BackgroundTransparency=1;UI.page.TextSize=12
        UI.pageEntry=Box(footer,"Go to page...",UDim2.fromOffset(50,0),UDim2.new(1,-100,0,38));UI.pageEntry.Visible=false
        Connect(UI.page.Activated,function()
            UI.pageEntry.Text=tostring(runtime.page);UI.pageEntry.Visible=true;UI.page.Visible=false
            pcall(function() UI.pageEntry:CaptureFocus() end)
        end)
        Connect(UI.pageEntry.FocusLost,function()
            local page=tonumber(UI.pageEntry.Text)
            if page and page==page and page>0 and page<math.huge then runtime.page=math.floor(page);RenderPage() end
            UI.pageEntry.Visible=false;UI.page.Visible=true
        end)
        UI.status=Text(footer,"Ready",11,UDim2.fromOffset(2,40),UDim2.new(1,-4,0,14));UI.status.TextColor3=C.muted
        Connect(prev.Activated,function() runtime.page=runtime.page-1;RenderPage() end)
        Connect(nextButton.Activated,function() runtime.page=runtime.page+1;RenderPage() end)
        UI.previous=prev;UI.next=nextButton;UI.close=close;UI.minimize=minimize;UI.random=random;UI.stop=stop

        UI.modal=Make("Frame",{Name="SettingsSheet",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
            Visible=false,Active=true,ZIndex=100},UI.root)
        local dismiss=Make("TextButton",{Text="",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),
            BackgroundTransparency=.38,BorderSizePixel=0,AutoButtonColor=false,ZIndex=1},UI.modal)
        UI.sheet=Make("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-12,.5,0),Size=UDim2.fromOffset(380,420),
            BackgroundColor3=C.navy,BorderSizePixel=0,Active=true,ZIndex=2},UI.modal)
        Round(UI.sheet,16);Stroke(UI.sheet,C.muted,.6)
        Text(UI.sheet,"Settings",19,UDim2.fromOffset(16,12),UDim2.new(1,-100,0,32))
        UI.done=Button(UI.sheet,"Done",UDim2.new(1,-78,0,12),UDim2.fromOffset(62,34));UI.done.TextColor3=C.accent
        local function SettingsVisible(visible)
            UI.modal.Visible=visible;UI.root.ZIndex=visible and 60 or 1
        end
        UI.setSettingsVisible=SettingsVisible
        Connect(UI.settings.Activated,function() SettingsVisible(not UI.modal.Visible) end)
        Connect(UI.done.Activated,function() SettingsVisible(false) end)
        Connect(dismiss.Activated,function() SettingsVisible(false) end)
        UI.controls=Make("ScrollingFrame",{Position=UDim2.fromOffset(14,56),Size=UDim2.new(1,-28,1,-68),
            BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.accent,
            AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.Y},UI.sheet)
        Make("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},UI.controls)
        local order=0
        local function Row(title,height)
            order=order+1
            local row=Make("Frame",{LayoutOrder=order,Size=UDim2.new(1,-6,0,height or 44),BackgroundTransparency=1},UI.controls)
            if title then Text(row,title,13,UDim2.fromOffset(0,0),UDim2.new(1,-156,1,0)) end
            return row
        end
        local repeatRow=Row("Repeat")
        UI.loop=Button(repeatRow,"Loop: OFF",UDim2.new(1,-144,0,0),UDim2.fromOffset(144,42))
        local moveRow=Row("On movement")
        UI.walk=Button(moveRow,"Move: OFF",UDim2.new(1,-144,0,0),UDim2.fromOffset(144,42))
        Connect(UI.loop.Activated,function()
            prefs.loop=not prefs.loop;Commit()
            if runtime.track then pcall(function() runtime.track.Looped=prefs.loop end) end
            UpdateStatus()
        end)
        Connect(UI.walk.Activated,function() prefs.walk=not prefs.walk;Commit();UpdateStatus() end)
        local function Stepper(title,key,lo,hi,step)
            local row=Row(title)
            local minus=Button(row,"−",UDim2.new(1,-144,0,0),UDim2.fromOffset(38,42))
            local box=Box(row,tostring(prefs[key]),UDim2.new(1,-100,0,0),UDim2.fromOffset(56,42))
            box.TextXAlignment=Enum.TextXAlignment.Center
            local plus=Button(row,"+",UDim2.new(1,-38,0,0),UDim2.fromOffset(38,42))
            local function Set(value)
                if value and value==value and value>-math.huge and value<math.huge then
                    prefs[key]=math.clamp(math.floor(value*100+.5)/100,lo,hi);Commit()
                    if key=="speed" and runtime.track then pcall(function() runtime.track:AdjustSpeed(prefs.speed) end) end
                    Layout();UpdateStatus()
                end
                box.Text=tostring(prefs[key])
            end
            Connect(minus.Activated,function() Set(prefs[key]-step) end)
            Connect(plus.Activated,function() Set(prefs[key]+step) end)
            Connect(box.FocusLost,function() Set(tonumber(box.Text)) end)
            return box,minus,plus
        end
        UI.speed,UI.speedMinus,UI.speedPlus=Stepper("Speed", "speed",0,3,.25)
        UI.alpha,UI.alphaMinus,UI.alphaPlus=Stepper("Transparency %","windowTransparency",0,50,5)
        UI.thumb,UI.thumbMinus,UI.thumbPlus=Stepper("Image size %","thumbnailSize",50,100,5)
        local refreshRow=Row(nil)
        UI.refresh=Button(refreshRow,"Refresh catalog",UDim2.new(),UDim2.new(1,0,0,42))
        Connect(UI.refresh.Activated,RefreshCatalog)
        local centerRow=Row(nil)
        local center=Button(centerRow,"Center window",UDim2.new(),UDim2.new(1,0,0,42))
        Connect(center.Activated,function() runtime.ResetBrowserPosition() end)
        local help=Row(nil,74)
        Text(help,"★ = favorite   ○ = screen button\nTap a page number to jump.\nDrag the header or a screen button.\nMove OFF stops the emote when walking.",11,UDim2.new(),UDim2.fromScale(1,1)).TextWrapped=true
        local dragInput,dragStart,dragCenter
        UI.stopDragging=function()
            dragInput=nil
            if UI.quickDrag and UI.quickDrag.record.moved then SaveSettings() end
            UI.quickDrag=nil
        end
        local inputService=SR_UI.service("UserInputService")
        Connect(drag.InputBegan,function(input)
            if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
            dragInput=input;dragStart=input.Position
            local vp=UI.canvas.AbsoluteSize
            dragCenter=Vector2.new(UI.root.Position.X.Scale*vp.X+UI.root.Position.X.Offset,
                UI.root.Position.Y.Scale*vp.Y+UI.root.Position.Y.Offset)
        end)
        Connect(inputService.InputChanged,QuickInputChanged)
        Connect(inputService.InputEnded,QuickInputEnded)
        Connect(inputService.InputChanged,function(input)
            if not dragInput then return end
            if input~=dragInput and not (dragInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then return end
            local delta=input.Position-dragStart
            UI.center=Vector2.new(dragCenter.X+delta.X,dragCenter.Y+delta.Y);Layout()
        end)
        Connect(inputService.InputEnded,function(input) if input==dragInput then dragInput=nil end end)
        Connect(UI.canvas:GetPropertyChangedSignal("AbsoluteSize"),Layout)
        Layout();RenderCards();runtime.SyncQuickButtons()
    end
    function runtime.OpenBrowser()
        if not runtime.alive then return end
        if UI.root then SetVisible(true);return end
        UI.hidden=false
        local ok,err=pcall(Build)
        if not ok then
            for _,connection in ipairs(UI.connections) do connection:Disconnect() end
            UI.connections={}
            if UI.screen then UI.screen:Destroy() end
            UI.screen=nil;UI.root=nil;UI.cards={};UI.quickButtons={};UI.quickDrag=nil
            WarnOnce("cards","Could not open the card browser: "..tostring(err)..". Native ODH controls remain available.")
        end
    end
    function runtime.RestoreQuickButtons()
        if not runtime.alive or UI.hidden or not next(prefs.shortcuts) then return end
        if UI.root then runtime.SyncQuickButtons();return end
        runtime.OpenBrowser()
        if UI.root then SetVisible(false) end
    end
    function runtime.CloseBrowser()

        UI.hidden=true
        UI.searchToken=UI.searchToken+1
        if UI.stopDragging then UI.stopDragging() end
        if UI.setSettingsVisible then UI.setSettingsVisible(false) end
        if UI.root then UI.root.Visible=false end
        if UI.launcher then UI.launcher.Visible=false end
        if UI.screen then UI.screen.Enabled=false end
        for _,box in ipairs({UI.search,UI.speed,UI.alpha,UI.thumb,UI.pageEntry}) do
            pcall(function() box:ReleaseFocus() end)
        end
        RefreshQuickVisuals()
    end
    function runtime.DestroyBrowser()
        UI.searchToken=UI.searchToken+1
        for _,connection in ipairs(UI.connections) do connection:Disconnect() end
        UI.connections={}
        if UI.screen then UI.screen:Destroy() end
        UI.screen=nil;UI.root=nil;UI.cards={};UI.quickButtons={};UI.quickDrag=nil
    end
end

local nativeVisual={favoritesOnly=false,loop=false,walk=false,browserOnLoad=false}
local tab=SR_Tab("Emotes")
local browserSection=tab:AddSection("Card Browser","Pictures • favorites • play buttons • mobile layout")
browserSection:AddButton("Open card browser",function() runtime.OpenBrowser() end)
browserSection:AddButton("Hide card browser",function() runtime.CloseBrowser() end)
local browserToggle=browserSection:AddToggle("Open browser on load",function(value)
    nativeVisual.browserOnLoad=value==true
    if runtime.initializing or not runtime.alive then return end
    prefs.browserOnLoad=value==true;SaveSettings()
end)
SR_Paragraph(browserSection, "Card browser", "Separate window inspired by ODH's emote cards, not an injected native tab. Tap the circle to pin/unpin an on-screen emote button, ▶ to play, ■ to stop, ★ to favorite. Screen buttons appear immediately, even with the browser open; drag them to move. Search, scroll and switch pages; drag the header to move the window. Minus minimizes to an Emotes button. X / Hide hides the entire plugin overlay, including shortcuts; reopen with Open card browser. Native controls below remain available.")
local alphaSlider=browserSection:AddSlider("Window transparency (%)",0,50,prefs.windowTransparency,function(value)
    if runtime.initializing or not runtime.alive or type(value)~="number" or value~=value then return end
    prefs.windowTransparency=math.clamp(value,0,50);SaveSettings();runtime.ApplyBrowserAppearance()
end)
local thumbSlider=browserSection:AddSlider("Thumbnail size (%)",50,100,prefs.thumbnailSize,function(value)
    if runtime.initializing or not runtime.alive or type(value)~="number" or value~=value then return end
    prefs.thumbnailSize=math.clamp(value,50,100);SaveSettings();runtime.ApplyBrowserAppearance()
end)
browserSection:AddButton("Center card browser",function() runtime.ResetBrowserPosition() end)
browserSection:AddButton("Remove all screen buttons",function() runtime.ClearQuickButtons() end)
local library=tab:AddSection("Emote Library","7yd7 catalog • native Overdrive H controls")
catalogLabel=library:AddLabel("Preparing catalog...",true)
pageLabel=library:AddLabel("Page 1",true)
selectedLabel=library:AddLabel("Selected: none",true)
searchLabel=library:AddLabel("Search: "..(prefs.query=="" and "(all)" or prefs.query),true)
library:AddTextBox("Search name or ID",function(text)
    if runtime.initializing or not runtime.alive or type(text)~="string" then return end
    prefs.query=text:sub(1,200);SaveSettings();Filter(true)
end)
library:AddButton("Clear search",function()
    if not runtime.alive then return end
    prefs.query="";SaveSettings();Filter(true)
end)
local favoriteToggle=library:AddToggle("Favorites only",function(value)
    nativeVisual.favoritesOnly=value==true
    if runtime.initializing or not runtime.alive then return end
    prefs.favoritesOnly=value==true;SaveSettings();Filter(true)
end)
dropdown=library:AddDropdown("Emote",{SENTINEL},function(text)
    if runtime.initializing or syncing or not runtime.alive then return end
    local item=displayed[text]
    if not item then return end
    prefs.selected={id=item.id,name=item.name};SaveSettings();SelectionLabel()
end)
library:AddButton("Previous page",function()
    if runtime.alive then runtime.page=runtime.page-1;RenderPage() end
end)
library:AddButton("Next page",function()
    if runtime.alive then runtime.page=runtime.page+1;RenderPage() end
end)
library:AddTextBox("Go to page",function(text)
    if runtime.initializing or not runtime.alive then return end
    local page=tonumber(text)
    if page and page==page and page>0 and page<math.huge then runtime.page=math.floor(page);RenderPage() end
end)
library:AddButton("Add selected to favorites",function()
    if not runtime.alive or not prefs.selected then return end
    prefs.favorites[IdText(prefs.selected.id)]={id=prefs.selected.id,name=prefs.selected.name}
    SaveSettings();Notify("Added to favorites: "..prefs.selected.name)
    if prefs.favoritesOnly then Filter(true) end
end)
library:AddButton("Remove selected from favorites",function()
    if not runtime.alive or not prefs.selected then return end
    prefs.favorites[IdText(prefs.selected.id)]=nil;SaveSettings()
    Notify("Removed from favorites: "..prefs.selected.name)
    if prefs.favoritesOnly then Filter(true) end
end)
library:AddButton("Refresh catalog",RefreshCatalog)

local playback=tab:AddSection("Emote Playback","R15 • controls only this plugin's emote track")
statusLabel=playback:AddLabel("Ready — select an emote and press Play",true)
playback:AddButton("Play selected",function() if runtime.alive then Play(prefs.selected,false) end end)
playback:AddButton("Stop emote",function() if runtime.alive then StopCurrent("Stopped") end end)
playback:AddButton("Random from results",function()
    if not runtime.alive then return end
    if runtime.filtering then Notify("Search is still updating; try again in a moment.");return end
    if #runtime.filtered==0 then Notify("No matching emotes.");return end
    local item=runtime.filtered[math.random(1,#runtime.filtered)]
    prefs.selected={id=item.id,name=item.name};SaveSettings();RenderPage();Play(item,false)
end)
local loopToggle=playback:AddToggle("Loop emote",function(value)
    nativeVisual.loop=value==true
    if runtime.initializing or not runtime.alive then return end
    prefs.loop=value==true;SaveSettings()
    if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end
    if runtime.track then pcall(function() runtime.track.Looped=prefs.loop end) end
end)
local walkToggle=playback:AddToggle("Keep playing while moving",function(value)
    nativeVisual.walk=value==true
    if runtime.initializing or not runtime.alive then return end
    prefs.walk=value==true;SaveSettings()
    if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end
end)
local speed=playback:AddSlider("Emote speed",0,3,prefs.speed,function(value)
    if runtime.initializing or not runtime.alive or type(value)~="number" or value~=value then return end
    prefs.speed=math.clamp(value,0,3);SaveSettings()
    if runtime.UpdateCardStatus then runtime.UpdateCardStatus() end
    if runtime.track then pcall(function() runtime.track:AdjustSpeed(prefs.speed) end) end
end)
SR_Paragraph(playback, "Playback behavior", "Single playback is the default (Loop OFF). Old versions' Loop ON is reset once; you can enable looping manually. Speed 0 pauses the current track. With Keep playing while moving OFF, movement stops the emote. Play is manual: saved settings never start an emote automatically after joining or respawning.")

local custom=tab:AddSection("Custom Emote","Catalog emote asset ID or raw animation ID")
customLabel=custom:AddLabel("Saved ID: "..(prefs.customId=="" and "(empty)" or prefs.customId),true)
custom:AddTextBox("Custom ID",function(text)
    if runtime.initializing or not runtime.alive or type(text)~="string" then return end
    prefs.customId=text:sub(1,200);SaveSettings()
    Label(customLabel,"Saved ID: "..(prefs.customId=="" and "(empty)" or prefs.customId))
end)
local kind=custom:AddDropdown("ID type",{"Catalog emote ID","Animation ID"},function(value)
    if runtime.initializing or not runtime.alive then return end
    if value~="Catalog emote ID" and value~="Animation ID" then return end
    prefs.customKind=value;SaveSettings()
end)
custom:AddButton("Play custom ID",function()
    if not runtime.alive then return end
    local id=ParseId(prefs.customId)
    if not id then Notify("Enter a numeric ID, rbxassetid URL, or Roblox catalog URL.");return end
    Play({id=id,name="Custom "..IdText(id)},prefs.customKind=="Animation ID")
end)
SR_Paragraph(custom, "About this port", "Source: 7yd7/Hub Emotes.lua. A separate card window and native ODH controls replace the original wheel, HUD editor and themes. Walk/run animation bundles are not modified. Some assets are restricted or unavailable; visibility to other players depends on the game. Use one emote player at a time. FE Animations full resets will stop a playing emote.")
SR_Paragraph(custom, "Saving", "Settings, selected emote and favorites: "..FILE..". Catalog cache: "..CACHE..". readfile/writefile are required for cross-session saving. Saved textbox values are shown in the labels because ODH has no documented textbox setter.")
function runtime.SyncNative()
    local initializing=runtime.initializing
    runtime.initializing=true
    local flips={favoritesOnly=favoriteToggle,loop=loopToggle,walk=walkToggle,browserOnLoad=browserToggle}
    for key,flip in pairs(flips) do
        if nativeVisual[key]~=prefs[key] and type(flip)=="function" then pcall(flip) end
    end
    if speed then pcall(function() speed:SetValue(prefs.speed) end) end
    if alphaSlider then pcall(function() alphaSlider:SetValue(prefs.windowTransparency) end) end
    if thumbSlider then pcall(function() thumbSlider:SetValue(prefs.thumbnailSize) end) end
    runtime.initializing=initializing
    SelectionLabel()
end

if prefs.browserOnLoad and type(browserToggle)=="function" then pcall(browserToggle) end
if prefs.favoritesOnly and type(favoriteToggle)=="function" then pcall(favoriteToggle) end
if prefs.loop and type(loopToggle)=="function" then pcall(loopToggle) end
if prefs.walk and type(walkToggle)=="function" then pcall(walkToggle) end
if kind then pcall(function() kind:Select(prefs.customKind) end) end
runtime.initializing=false
_G[KEY]=runtime
Status("Ready — select an emote and press Play")

task.defer(function()
    local cache=ReadJSON(CACHE)
    local cachedItems=NormalizeCatalog(cache)
    if not runtime.alive then return end
    AdoptCatalog(cachedItems or BUILTIN,cachedItems and "saved cache" or "built-in starter list")
    RefreshCatalog()
    if not runtime.alive or (runtime.browser and runtime.browser.hidden) then return end
    if prefs.browserOnLoad then runtime.OpenBrowser() else runtime.RestoreQuickButtons() end
end)

end
end)

SR_UI.tryModule("InventoryUnlimiter", function()
do
    local ODHX = CreateODHX("InventoryUnlimiter", "Inventory Unlimiter", "ODH_InventoryUnlimiter_settings.json", true, false)
    local shared = ODHX.shared

    local ITEMS_MIN, ITEMS_MAX = 2, 9999
    local runtime = { alive = true, ready = false, generation = 0, enabled = false, maxItems = ITEMS_MAX }
    local warnings = {}
    local statusLabel, characterConnection

    local function Log(text)
        SR_Log("[Inventory Unlimiter] " .. tostring(text))
    end
    local function WarnOnce(key, text)
        if warnings[key] then return end
        warnings[key] = true
        Log(text)
        shared.Notify("Inventory Unlimiter: " .. text, 5)
    end
    local function ShowStatus(text)
        runtime.status = text
        if statusLabel then pcall(function() statusLabel:SetValue(text) end) end
    end
    local function Finite(value)
        return type(value) == "number" and value == value and value > -math.huge and value < math.huge
    end
    local function ClampItems(value)
        if not Finite(value) then return nil end
        return math.clamp(math.floor(value + 0.5), ITEMS_MIN, ITEMS_MAX)
    end

    local execEnv = {}
    if type(getgenv) == "function" then
        local ok, result = pcall(getgenv)
        if ok and type(result) == "table" then execEnv = result end
    end
    local debugLibrary = type(debug) == "table" and debug or {}
    local function Resolve(primary, fallback, external)
        if type(primary) == "function" then return primary end
        if type(fallback) == "function" then return fallback end
        if type(external) == "function" then return external end
    end
    local getGC = Resolve(getgc, execEnv.getgc)
    local readUpvalues = Resolve(debugLibrary.getupvalues, getupvalues, execEnv.getupvalues)
    local writeUpvalue = Resolve(debugLibrary.setupvalue, setupvalue, execEnv.setupvalue)
    local readInfo = Resolve(debugLibrary.getinfo, getinfo, execEnv.getinfo)
    local readConstants = Resolve(debugLibrary.getconstants, getconstants, execEnv.getconstants)
    local readName = Resolve(debugLibrary.info)

    local changed = {}

    local identified = setmetatable({}, { __mode = "k" })

    local function IsTarget(fn)
        local name
        if readInfo then
            local ok, info = pcall(readInfo, fn)
            if ok and type(info) == "table" then name = info.name end
        elseif readName then
            local ok, value = pcall(readName, fn, "n")
            if ok then name = value end
        end
        if name == "updateItemFrame" or name == "onItemEquipped" then return true end
        if readConstants then
            local ok, constants = pcall(readConstants, fn)
            if ok and type(constants) == "table" then
                local touch, equip = false, false
                for _, value in constants do
                    if value == "TouchBinding" then touch = true end
                    if value == "EquipButton" then equip = true end
                end
                return touch and equip
            end
        end
        return false
    end

    local function WriteAndVerify(fn, index, value)
        local ok, err = pcall(writeUpvalue, fn, index, value)
        if not ok then return false, tostring(err) end
        local readable, values = pcall(readUpvalues, fn)
        if not readable or type(values) ~= "table" or values[index] ~= value then
            return false, "upvalue verification failed"
        end
        return true
    end

    local function RestoreOriginals()
        local allRestored = true
        for fn, slots in pairs(changed) do
            local readable, values = pcall(readUpvalues, fn)
            if not readable or type(values) ~= "table" then
                allRestored = false
                WarnOnce("restore-read", "Could not inspect previously changed values; restoration is pending.")
            else
                for index, saved in pairs(slots) do
                    local current = values[index]
                    if current == saved.original then
                        slots[index] = nil
                    elseif current ~= saved.last then

                        WarnOnce("conflict", "A value changed elsewhere; left it untouched.")
                        slots[index] = nil
                    else
                        local ok, err = WriteAndVerify(fn, index, saved.original)
                        if ok then slots[index] = nil
                        else
                            allRestored = false
                            WarnOnce("restore-write", "Cannot restore an original limit: " .. tostring(err))
                        end
                    end
                end
            end
            if next(slots) == nil then changed[fn] = nil end
        end
        return allRestored
    end

    local function ApplyLimit()
        if not (getGC and readUpvalues and writeUpvalue and (readInfo or readName or readConstants)) then
            ShowStatus("UNSUPPORTED: required executor debug functions are missing")
            WarnOnce("debug", "Required debug functions are unavailable (getgc/getupvalues/setupvalue and target identification).")
            return 0
        end
        local ok, objects = pcall(getGC)
        if not ok or type(objects) ~= "table" then
            ShowStatus("ERROR: getgc failed")
            WarnOnce("scan", "getgc failed: " .. tostring(objects))
            return 0
        end
        local target = runtime.maxItems
        local count = 0
        for _, fn in pairs(objects) do
            if type(fn) == "function" then
                local known = identified[fn]
                if known == nil then
                    known = IsTarget(fn) or false
                    identified[fn] = known
                end
                if known then
                    local readable, values = pcall(readUpvalues, fn)
                    if readable and type(values) == "table" then
                        for index, value in pairs(values) do
                            if type(index) == "number" and index >= 1 and index % 1 == 0 and type(value) == "number" then
                                local slots = changed[fn]
                                local saved = slots and slots[index]

                                if saved or value == 10 or value == 3 then
                                    if not saved then
                                        slots = slots or {}
                                        changed[fn] = slots
                                        saved = { original = value, last = value }
                                        slots[index] = saved
                                    end
                                    if value == target then
                                        saved.last = target
                                        count = count + 1
                                    elseif value == saved.last or value == saved.original then

                                        saved.last = target
                                        local applied, err = WriteAndVerify(fn, index, target)
                                        if applied then count = count + 1
                                        else WarnOnce("apply", "Cannot write/verify a target limit: " .. tostring(err)) end
                                    else
                                        WarnOnce("conflict", "A value changed elsewhere; left it untouched.")
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if count > 0 then ShowStatus("ON | Max Items: " .. target .. " | verified values: " .. count)
        else ShowStatus("WAITING | Inventory functions not found or not writable") end
        return count
    end

    local function RequestApply()
        runtime.generation = runtime.generation + 1
        local token = runtime.generation
        if not runtime.enabled then
            local restored = RestoreOriginals()
            ShowStatus(restored and "OFF | Original values restored" or "OFF | Restoration pending; press Reapply / Retry")
            return
        end
        ShowStatus("Applying saved/current limit...")

        task.spawn(function()
            for _, pause in ipairs({ 0.2, 0.8, 2.0 }) do
                task.wait(pause)
                if not runtime.alive or runtime.generation ~= token or not runtime.enabled then return end
                ApplyLimit()
            end
        end)
    end

    local function Cleanup()
        runtime.alive = false
        runtime.generation = runtime.generation + 1
        if characterConnection then characterConnection:Disconnect() characterConnection = nil end

        return RestoreOriginals()
    end
    ODHX.cleanup = Cleanup

    local section = shared.AddSection("Inventory Unlimiter")
    section:AddLabel("Inventory Unlimiter V5 • client-side limit only")
    SR_Paragraph(section, "What it does",
        "Raises the item limit of the game's inventory screen on your client. Nothing is sent to the server, " ..
        "so server-side limits stay in force. The switch and Max Items are saved automatically and restored on load.")

    local toggle = section:AddToggle("Unlimit Inventory", function(value)
        if not runtime.ready then return end
        runtime.enabled = value == true
        RequestApply()
    end)
    local slider = section:AddSlider("Max Items", ITEMS_MIN, ITEMS_MAX, ITEMS_MAX, function(value)
        if not runtime.ready then return end
        local number = ClampItems(value)
        if not number then return end
        runtime.maxItems = number
        if runtime.enabled then RequestApply() end
    end)
    section:AddButton("Reapply / Retry", function()
        if not runtime.ready then return end
        RequestApply()
    end)
    statusLabel = section:AddLabel("Initializing...")

    local function migrateLegacySettings()
        if type(ODHX.data.controls) ~= "table" or next(ODHX.data.controls) ~= nil then return end
        local text = SR_Store.read("ODH_InventoryUnlimiter_settings.json")
        if not text then return end
        local http = SR_UI.service("HttpService")
        if not http then return end
        local ok, decoded = pcall(function() return http:JSONDecode(text) end)
        if not ok or type(decoded) ~= "table" or type(decoded.values) ~= "table" then return end
        local values = decoded.values
        local migrated = false
        if type(values.enabled) == "boolean" then
            ODHX.Set("Inventory Unlimiter", "Unlimit Inventory", "Toggle", values.enabled, false)
            migrated = true
        end
        local items = ClampItems(values.maxItems)
        if items then
            ODHX.Set("Inventory Unlimiter", "Max Items", "Slider", items, false)
            migrated = true
        end
        if migrated then
            ODHX.badFile = nil
            Log("preferences of the standalone version were kept")
        end
    end
    migrateLegacySettings()

    ODHX.Finish()

    local function restoredValue(label, kind, fallback)
        if type(ODHX.records) == "table" then
            for _, rec in ipairs(ODHX.records) do
                if rec.name == label and rec.kind == kind and rec.value ~= nil then return rec.value end
            end
        end
        return fallback
    end
    runtime.enabled = restoredValue("Unlimit Inventory", "Toggle", false) == true
    runtime.maxItems = ClampItems(restoredValue("Max Items", "Slider", ITEMS_MAX)) or ITEMS_MAX

    if slider then pcall(function() slider:SetValue(runtime.maxItems) end) end
    runtime.ready = true

    local player = SR_UI.service("Players") and SR_UI.service("Players").LocalPlayer
    if player then
        characterConnection = player.CharacterAdded:Connect(function()
            if runtime.alive and runtime.enabled then RequestApply() end
        end)
    end

    RequestApply()
    Log("loaded | settings: ODH_InventoryUnlimiter_settings.json")

end
end)

SR_Log("modules loaded: " .. SR_UI.modulesLoaded .. "/" .. SR_UI.modulesSeen
    .. (#SR_UI.moduleFailures > 0 and (" | failed: " .. table.concat(SR_UI.moduleFailures, "; ")) or ""))
pcall(SR_BootNotify)
