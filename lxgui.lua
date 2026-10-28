-- lxgui.lua — снимает НАЗВАНИЯ фич из живого UI чита + дифф глобалов.
-- НЕ трогает hookfunction/loadstring/watch — антитампер не спалит.
-- Порядок: 1) этот файл, 2) ждёшь "on", 3) запускаешь свой скрипт официально,
--          4) когда UI хиба прогрузился — ждёшь 30 сек, 5) забираешь IxryDump/*

if getgenv()._LXG_ON then warn("[lxgui] уже стоит"); return end
getgenv()._LXG_ON = true

pcall(makefolder, "IxryDump")
local LOG = function(s)
    pcall(appendfile, "IxryDump/_lxgui.log", s .. "\n")
    warn(s)
end
LOG("[lxgui] start")

-- 1. снапшот глобалов ДО
local before = {}
for k in pairs(getgenv()) do before[k] = true end

local dl = (task and task.delay) or delay
local function scanGui(tag)
    LOG("[lxgui] gui-scan " .. tag)
    local roots = {}
    pcall(function() roots[#roots + 1] = gethui and gethui() or game:GetService("CoreGui") end)
    pcall(function() roots[#roots + 1] = game:GetService("CoreGui") end)
    pcall(function() local lp = game:GetService("Players").LocalPlayer; if lp then roots[#roots + 1] = lp:FindFirstChildOfClass("PlayerGui") end end)

    local seen, lines = {}, {}
    local function walk(inst, depth)
        if depth > 14 or #lines > 4000 then return end
        if seen[inst] then return end
        seen[inst] = true
        local cls = ""
        pcall(function() cls = inst.ClassName end)
        if cls == "" then return end
        local nm = ""
        pcall(function() nm = inst.Name end)
        local txt = ""
        if cls == "TextLabel" or cls == "TextButton" or cls == "TextBox" then
            pcall(function() txt = inst.Text end)
        end
        local vis = ""
        pcall(function() vis = tostring(inst.Visible) end)
        if txt ~= "" or cls == "ScreenGui" or cls == "Frame" or cls == "ScrollingFrame" then
            lines[#lines + 1] = string.rep("  ", depth) ..
                ("[%s] %s%s%s"):format(cls, nm,
                    txt ~= "" and ('  TEXT="' .. txt:sub(1, 120) .. '"') or "",
                    vis ~= "" and ("  vis=" .. vis) or "")
        end
        local ch = nil
        pcall(function() ch = inst:GetChildren() end)
        if ch then for _, c in ipairs(ch) do walk(c, depth + 1) end end
    end
    for _, r in ipairs(roots) do if r then walk(r, 0) end end

    -- фильтр: только ветки где есть текст (формочки), отсекая системные гуи
    local out = {}
    for _, l in ipairs(lines) do out[#out + 1] = l end
    pcall(writefile, ("IxryDump/gui_%s.txt"):format(tag), table.concat(out, "\n"))
    LOG(("[lxgui] gui_%s.txt: %d узлов"):format(tag, #out))

    -- 2. дифф глобалов ПОСЛЕ: новые ключи getgenv
    local diff = {}
    for k, v in pairs(getgenv()) do
        if not before[k] then
            diff[#diff + 1] = ("%s  (%s)"):format(tostring(k), type(v))
        end
    end
    table.sort(diff)
    pcall(writefile, "IxryDump/genv_diff.txt", table.concat(diff, "\n"))
    LOG(("[lxgui] genv_diff.txt: %d новых глобалов"):format(#diff))
end

if dl then
    pcall(dl, 15, function() scanGui("t15") end)
    pcall(dl, 30, function() scanGui("t30") end)
    pcall(dl, 50, function() scanGui("t50") end)
    pcall(dl, 75, function() scanGui("t75"); LOG("[lxgui] финиш — забирай IxryDump") end)
else
    getgenv().LXG_SCAN = scanGui
    LOG("[lxgui] delay нет — вручную: LXG_SCAN('x')")
end
LOG("[lxgui] on. запускай скрипт, жди 75 сек, архивируй IxryDump")
print("[lxgui] on")
