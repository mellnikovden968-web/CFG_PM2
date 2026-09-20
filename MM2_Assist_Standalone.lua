-- MM2 Assist standalone edition. Based on user-supplied @assistaim example.
-- No Overdrive H required. Runtime gameplay not verified in Roblox.
-- Standalone UI adapter. No external UI downloads.
local StandaloneHost = {}
do
    local gui, panel, tabs, pages, notice
    local connections = {}
    local function connect(signal, callback)
        local c = signal:Connect(callback)
        connections[#connections+1] = c
        return c
    end
    local function make(class, props, parent)
        local obj = Instance.new(class)
        for k,v in pairs(props) do obj[k] = v end
        obj.Parent = parent
        return obj
    end
    local bg = Color3.fromRGB(23,25,34)
    local accent = Color3.fromRGB(127,108,255)
    local function text(class, title, parent, height)
        local obj = make(class, {Text=title, Size=UDim2.new(1,-8,0,height or 38), BackgroundColor3=bg, BorderSizePixel=0, TextColor3=Color3.fromRGB(234,235,245), TextSize=14, Font=Enum.Font.Gotham, TextWrapped=true}, parent)
        make('UICorner',{CornerRadius=UDim.new(0,7)},obj)
        return obj
    end
    function StandaloneHost.Destroy()
        for _,c in ipairs(connections) do c:Disconnect() end
        connections = {}
        if gui then gui:Destroy();gui=nil end
    end
    function StandaloneHost.Notify(message)
        warn('[MM2 Assist] '..tostring(message))
        if notice then notice.Text=tostring(message) end
    end
    function StandaloneHost.CreateTab()
        gui = make('ScreenGui',{Name='MM2AssistStandalone',ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},nil)
        local parent
        if type(gethui)=='function' then local ok,p=pcall(gethui);if ok and typeof(p)=='Instance' then parent=p end end
        local ok=pcall(function() gui.Parent=parent or game:GetService('CoreGui') end)
        if not ok then gui.Parent=game:GetService('Players').LocalPlayer:WaitForChild('PlayerGui') end
        panel=make('Frame',{Size=UDim2.new(0.9,0,0.8,0),Position=UDim2.new(0.05,0,0.1,0),BackgroundColor3=Color3.fromRGB(14,16,23),BorderSizePixel=0},gui)
        make('UISizeConstraint',{MaxSize=Vector2.new(760,580),MinSize=Vector2.new(280,220)},panel)
        make('UICorner',{CornerRadius=UDim.new(0,12)},panel)
        local title=text('TextLabel','MM2 ASSIST  /  STANDALONE',panel,42)
        title.BackgroundColor3=accent;title.Size=UDim2.new(1,-46,0,42)
        local hide=text('TextButton','—',panel,42);hide.Size=UDim2.new(0,40,0,42);hide.Position=UDim2.new(1,-42,0,0)
        local open=text('TextButton','MM2',gui,40);open.Size=UDim2.new(0,60,0,40);open.Position=UDim2.new(0,8,0.5,-20);open.BackgroundColor3=accent;open.Visible=false
        connect(hide.Activated,function() panel.Visible=false;open.Visible=true end)
        connect(open.Activated,function() panel.Visible=true;open.Visible=false end)
        local input=game:GetService('UserInputService')
        connect(input.InputBegan,function(i,processed)
            if not processed and i.KeyCode==Enum.KeyCode.RightShift then panel.Visible=not panel.Visible;open.Visible=not panel.Visible end
        end)
        local drag,start,pos
        connect(title.InputBegan,function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=i;start=i.Position;pos=panel.Position end
        end)
        connect(input.InputChanged,function(i)
            if drag and (i==drag or i.UserInputType==Enum.UserInputType.MouseMovement) then
                local d=i.Position-start;panel.Position=UDim2.new(pos.X.Scale,pos.X.Offset+d.X,pos.Y.Scale,pos.Y.Offset+d.Y)
            end
        end)
        connect(input.InputEnded,function(i) if i==drag then drag=nil end end)
        tabs=make('ScrollingFrame',{Size=UDim2.new(0.28,-8,1,-104),Position=UDim2.new(0,8,0,50),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},panel)
        make('UIListLayout',{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},tabs)
        notice=text('TextLabel','Right Shift: show / hide. Gameplay features depend on the game and executor.',panel,44)
        notice.Position=UDim2.new(0,8,1,-48);notice.TextSize=11
        pages={}
        local tab={}
        function tab:AddSection(name,description)
            local page=make('ScrollingFrame',{Size=UDim2.new(0.72,-12,1,-104),Position=UDim2.new(0.28,4,0,50),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=#pages==0},panel)
            make('UIListLayout',{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},page)
            pages[#pages+1]=page
            local button=text('TextButton',name,tabs,42)
            connect(button.Activated,function() for _,p in ipairs(pages) do p.Visible=p==page end end)
            local section={}
            local order=0
            local function row(class,title,height)
                order=order+1
                local obj=text(class,title,page,height);obj.LayoutOrder=order
                return obj
            end
            function section:AddLabel(value)
                local label=row('TextLabel',value,36)
                return {SetValue=function(_,v) label.Text=tostring(v) end}
            end
            function section:AddParagraph(title,value)
                local label=row('TextLabel',title..'\n'..value,0)
                label.AutomaticSize=Enum.AutomaticSize.Y
                make('UIPadding',{PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,10),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)},label)
                return {SetValue=function(_,v) label.Text=title..'\n'..tostring(v) end}
            end
            function section:AddButton(name,callback)
                local b=row('TextButton',name)
                connect(b.Activated,callback)
                return b
            end
            function section:AddToggle(name,callback)
                local value=false
                local b=row('TextButton','OFF  •  '..name)
                local function flip()
                    value=not value;b.Text=(value and 'ON  •  ' or 'OFF  •  ')..name;b.BackgroundColor3=value and accent or bg
                    callback(value)
                end
                connect(b.Activated,flip)
                return flip
            end
            function section:AddTextBox(name,callback)
                section:AddLabel(name)
                local box=row('TextBox','')
                box.PlaceholderText='Enter value…';box.ClearTextOnFocus=false
                connect(box.FocusLost,function() callback(box.Text) end)
                return box
            end
            function section:AddDropdown(name,items,callback)
                local selected
                local b=row('TextButton',name..'  ▾')
                local holder=make('Frame',{Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Visible=false},page)
                order=order+1;holder.LayoutOrder=order
                make('UIListLayout',{Padding=UDim.new(0,3)},holder)
                local itemConnections={}
                local control={}
                function control:Select(v) selected=v;b.Text=name..': '..tostring(v);holder.Visible=false;callback(v) end
                function control:ChangeItems(values)
                    for _,c in ipairs(itemConnections) do c:Disconnect() end
                    itemConnections={}
                    for _,o in ipairs(holder:GetChildren()) do if o:IsA('TextButton') then o:Destroy() end end
                    for _,v in ipairs(values) do
                        local option=text('TextButton',tostring(v),holder,34)
                        itemConnections[#itemConnections+1]=option.Activated:Connect(function() control:Select(v) end)
                    end
                end
                control:ChangeItems(items)
                connect(b.Activated,function() holder.Visible=not holder.Visible end)
                return control
            end
            return section
        end
        return tab
    end
end

-- Original gameplay payload with standalone UI adapter.
-- Original payload credited to @assistaim; no external UI download.
-- Gameplay remotes/executor APIs depend on the game and executor; not verified in Roblox here.
local Plugin=(function()
    local host=StandaloneHost
    if not host or type(host.CreateTab)~="function" then warn("[MM2 Assist] UI adapter unavailable.");return nil end
    local key="MM2Assist_Standalone_Runtime_v1"
    if type(_G[key])=="table" and _G[key].alive then
        if type(host.Notify)=="function" then pcall(host.Notify,"MM2 Assist is already loaded.",4) end
        return nil
    end
    local P={alive=true,initializing=true,state={},temporary={},connections={},threads={},objects={},originals={},controls={},values={},positions={},cleanups={}}
    local realTask=task
    local realInstance=Instance
    local http=game:GetService("HttpService")
    local file="MM2Assist_Standalone_settings.json"
    P.settingsFile=file
    local env={}
    if type(getgenv)=="function" then local ok,v=pcall(getgenv);if ok and type(v)=="table" then env=v end end
    local read=type(readfile)=="function" and readfile or env.readfile
    local write=type(writefile)=="function" and writefile or env.writefile
    local exists=type(isfile)=="function" and isfile or env.isfile
    local canSave=type(read)=="function" and type(write)=="function"
    local warned={}
    function P.Notify(text)
        if type(host.Notify)=="function" then pcall(host.Notify,"MM2 Assist: "..tostring(text),5) end
    end
    function P.Warn(key,text)
        if warned[key] then return end
        warned[key]=true;warn("[MM2 Assist] "..tostring(text));P.Notify(text)
    end
    function P.Save()
        if P.initializing or not P.alive or not canSave then return end
        local ok,err=pcall(function() write(file,http:JSONEncode({version=1,values=P.values,positions=P.positions})) end)
        if not ok then P.Warn("write","Cannot save settings: "..tostring(err)) else warned.write=nil end
    end
    if canSave then
        local present=true
        if type(exists)=="function" then local ok,v=pcall(exists,file);if ok then present=v end end
        if present then
            local ok,data=pcall(function() return http:JSONDecode(read(file)) end)
            if ok and type(data)=="table" and data.version==1 and type(data.values)=="table" then
                P.values=data.values
                if type(data.positions)=="table" then P.positions=data.positions end
            else P.Warn("read","Invalid/unreadable settings; original file kept until you edit a control.") end
        end
    else P.Warn("files","readfile/writefile unavailable: settings are session-only.") end
    function P.Call(fn,...)
        if not P.alive then return end
        local thread=coroutine.running()
        if thread then P.threads[thread]=(P.threads[thread] or 0)+1 end
        local result=table.pack(pcall(fn,...))
        if thread then
            local depth=(P.threads[thread] or 1)-1
            P.threads[thread]=depth>0 and depth or nil
        end
        if not result[1] then P.Warn(tostring(fn),tostring(result[2]));return end
        return table.unpack(result,2,result.n)
    end
    local connectionCount=0
    function P.Connect(signal,fn)
        if not P.alive then return {Disconnect=function() end,Connected=false} end
        local conn=signal:Connect(function(...) return P.Call(fn,...) end)
        P.connections[conn]=true;connectionCount=connectionCount+1
        if connectionCount%128==0 then
            for c in pairs(P.connections) do if not c.Connected then P.connections[c]=nil end end
        end
        return conn
    end
    P.task={wait=realTask.wait,cancel=realTask.cancel}
    function P.task.spawn(fn,...)
        if not P.alive then return nil end
        local args=table.pack(...)
        local co=realTask.spawn(function() P.Call(fn,table.unpack(args,1,args.n)) end)
        if coroutine.status(co)~="dead" then P.threads[co]=P.threads[co] or 0 end
        return co
    end
    P.Instance={new=function(class,parent)
        local obj=realInstance.new(class,parent);P.objects[obj]=true;return obj
    end}
    function P.ParentGui(gui)
        local parent
        if type(gethui)=="function" then local ok,v=pcall(gethui);if ok then parent=v end end
        parent=parent or game:GetService("CoreGui")
        local ok=pcall(function() gui.Parent=parent end)
        if not ok then gui.Parent=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui",10) end
    end
    function P.Set(obj,prop,value,group)
        if not obj then return end
        local records=P.originals[obj]
        if not records then records={};P.originals[obj]=records end
        local old=records[prop]
        if not old then old={original=obj[prop],group=group};records[prop]=old end
        old.last=value
        obj[prop]=value
    end
    function P.Restore(group)
        for obj,records in pairs(P.originals) do
            for prop,record in pairs(records) do
                if not group or record.group==group then
                    local ok=pcall(function()
                        if obj.Parent and obj[prop]==record.last then obj[prop]=record.original end
                    end)
                    if ok then records[prop]=nil end
                end
            end
            if next(records)==nil then P.originals[obj]=nil end
        end
    end
    function P.Cleanup()
        if not P.alive then return end
        P.alive=false
        for conn in pairs(P.connections) do pcall(function() conn:Disconnect() end) end
        for _,fn in ipairs(P.cleanups) do pcall(fn) end
        for co in pairs(P.threads) do if co~=coroutine.running() then pcall(realTask.cancel,co) end end
        P.Restore()
        StandaloneHost.Destroy()
        for obj in pairs(P.objects) do pcall(function() obj:Destroy() end) end
        P.Notify("Unloaded. Restart the game before loading again.")
    end
    local touch=type(firetouchinterest)=="function" and firetouchinterest or env.firetouchinterest
    function P.Touch(a,b,state)
        if not touch then P.Warn("touch","firetouchinterest unavailable; touch-based gun/knife actions cannot work.");return end
        if a and b then return touch(a,b,state) end
    end
    _G[key]=P
    return P
end)()
if not Plugin then return end
Plugin.UI=(function(P)
    local host=StandaloneHost
    local UI={}
    local controls={}
    local function keyFor(section,cfg) return tostring(cfg.Flag or (section.." / "..cfg.Name)) end
    local function contains(items,value)
        for _,item in ipairs(items) do if item==value then return true end end
        return false
    end
    function UI:Notify(cfg) P.Notify((cfg.Title and cfg.Title..": " or "")..tostring(cfg.Content or "")) end
    function UI:CreateWindow()
        local tab=host.CreateTab("MM2 Assist","/mellnikovden968-web/CFG_PM2/refs/heads/main/icon")
        local about=tab:AddSection("MM2 Assist","@assistaim payload v1.07 • combat rebuilt v2")
        about:AddParagraph("Compatibility","Shooting uses the real MM2 remote captured from the live game: ReplicatedStorage.ClientServices.WeaponService.GunFired:FireServer(Handle, origin, hit, part), with the old CreateBeam remote as automatic fallback and a game-like click mode. Silent Aim rewrites your own GunFired shots when the executor supports hookmetamethod. Behavior still depends on the game and your executor. The original BOMB function is missing; Chance was marked not working. Aim Status shows the last shot result.")
        about:AddParagraph("Saving","Controls and floating-button positions: "..P.settingsFile..". Textbox values are restored internally and displayed in Saved labels. Other plugins' globals are not overwritten. Avoid running multiple speed/ESP/farm/physics controllers together.")
        about:AddButton("Hide floating UI",function() if P.HideFloating then P.HideFloating() end end)
        about:AddButton("Show floating UI",function() if P.ShowFloating then P.ShowFloating() end end)
        about:AddButton("Unload this session",function() P.Cleanup() end)
        local window={}
        function window:CreateTab(name)
            local section=tab:AddSection(name,"Murder Mystery Assist")
            local api={}
            function api:CreateSection(title) section:AddLabel("— "..title.." —") end
            function api:CreateParagraph(cfg)
                local label=section:AddParagraph(cfg.Title or "",cfg.Content or "",true)
                return {Set=function(_,value)
                    if label then pcall(function() label:SetValue(value.Content or "") end) end
                end}
            end
            function api:CreateButton(cfg)
                section:AddButton(cfg.Name,function() P.Call(cfg.Callback or function() end) end)
                return {}
            end
            function api:CreateToggle(cfg)
                local key=keyFor(name,cfg)
                local c={kind="toggle",key=key,cfg=cfg,value=cfg.CurrentValue==true,visual=false,muted=true}
                c.flip=section:AddToggle(cfg.Name,function(value)
                    c.visual=value==true
                    if c.muted or P.initializing or not P.alive then return end
                    c.value=value==true;P.values[key]=c.value;P.Save()
                    P.Call(cfg.Callback,c.value)
                end)
                c.muted=false
                function c:Set(value)
                    self.value=value==true;self.muted=true
                    if self.visual~=self.value and type(self.flip)=="function" then pcall(self.flip) end
                    self.muted=false
                    if not P.initializing then P.values[key]=self.value;P.Save() end
                    P.Call(cfg.Callback,self.value)
                end
                controls[#controls+1]=c;P.controls[key]=c;return c
            end
            function api:CreateInput(cfg)
                local key=keyFor(name,cfg)
                local c={kind="input",key=key,cfg=cfg}
                local function validate(text)
                    if type(text)~="string" then return nil end
                    text=text:sub(1,256)
                    local ranges={WS_F={0,200},JP_F={0,250},SP_F={0,200},["Main / Aura Range"]={1,100}}
                    local range=ranges[key]
                    if range then
                        local value=tonumber(text)
                        if not value or value~=value or value<=-math.huge or value>=math.huge then return nil end
                        return tostring(math.clamp(value,range[1],range[2]))
                    end
                    if key:sub(1,3)=="KB_" then
                        text=text:upper():gsub("%s","")
                        local ok,code=pcall(function() return Enum.KeyCode[text] end)
                        if not ok or not code or code==Enum.KeyCode.Unknown then return nil end
                    end
                    return text
                end
                c.validate=validate
                c.hint=section:AddLabel("Saved "..cfg.Name..": "..tostring(cfg.PlaceholderText or "(empty)"),true)
                local function show(value)
                    if c.hint then pcall(function() c.hint:SetValue("Saved "..cfg.Name..": "..value) end) end
                end
                c.show=show
                section:AddTextBox(cfg.Name,function(text)
                    if P.initializing or not P.alive then return end
                    local value=validate(text)
                    if not value then P.Notify("Invalid value for "..cfg.Name);return end
                    P.values[key]=value;P.Save();show(value);P.Call(cfg.Callback,value)
                end)
                controls[#controls+1]=c;P.controls[key]=c;return c
            end
            function api:CreateDropdown(cfg)
                local key=keyFor(name,cfg)
                local persist=key~="FlingTarget_Dropdown" -- do not restore targets across servers
                local c={kind="dropdown",key=key,cfg=cfg,items=cfg.Options or {},muted=true,persist=persist}
                c.control=section:AddDropdown(cfg.Name,c.items,function(value)
                    if c.muted or P.initializing or not P.alive or not contains(c.items,value) then return end
                    c.value=value
                    if persist then P.values[key]=value;P.Save() end
                    P.Call(cfg.Callback,{value})
                end)
                c.muted=false
                function c:Refresh(items,selection)
                    self.items=items or {};self.muted=true
                    if self.control then
                        self.control:ChangeItems(self.items)
                        if selection and selection[1] and contains(self.items,selection[1]) then self.control:Select(selection[1]) end
                    end
                    self.muted=false;self.value=selection and selection[1] or nil
                    P.Call(cfg.Callback,self.value and {self.value} or {})
                end
                controls[#controls+1]=c;P.controls[key]=c;return c
            end
            return api
        end
        return window
    end
    function UI:LoadConfiguration()
        for _,kind in ipairs({"input","dropdown","toggle"}) do
            for _,c in ipairs(controls) do
                if c.kind==kind then
                    local value=P.values[c.key]
                    if kind=="input" and type(value)=="string" then
                        value=c.validate(value)
                        if value then c.show(value);P.Call(c.cfg.Callback,value) end
                    elseif kind=="dropdown" then
                        value=(c.persist and type(value)=="string" and value) or (c.cfg.CurrentOption or {})[1]
                        if value and contains(c.items,value) then
                            c.muted=true
                            if c.control then pcall(function() c.control:Select(value) end) end
                            c.muted=false;c.value=value;P.Call(c.cfg.Callback,{value})
                        end
                    elseif kind=="toggle" and type(value)=="boolean" then c:Set(value) end
                end
            end
        end
        P.initializing=false
    end
    return UI
end)(Plugin)
local Rayfield=Plugin.UI
local _G=Plugin.state -- original payload globals are private to this plugin
local getgenv=function() return Plugin.temporary end
local task=Plugin.task
local Instance=Plugin.Instance
local firetouchinterest=Plugin.Touch
local function deployBomb() Plugin.Notify("BOMB was not implemented in the supplied script.") end
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer

local roleCache = {}
local leapDebounce = false
local killAuraConnection = nil
local killAllConnection = nil
local flingDetectionCon = nil
local flingNeutralizerCon = nil
local antiFlingEnabled = false
local detectedPlayers = {}
local layTrack = nil
local layAnim = Instance.new("Animation")
layAnim.AnimationId = "rbxassetid://4686922869"

local ExodusBlue = Color3.fromRGB(160, 32, 240)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ExodusFloatingUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Plugin.ParentGui(ScreenGui)

_G.LockAll = false
_G.ESPEnabled = false
_G.GunESPEnabled = false
_G.AutoCoins = false
_G.AutoGrabGun = false
_G.AutoLeap = false
_G.DesiredSpeed = 16
_G.DesiredJump = 50
_G.ApplySpeed = false
_G.ApplyJump = false
_G.SpeedGlitchEnabled = false
_G.SpeedGlitchValue = 40
_G.RoleNotify = false
_G.KillAuraEnabled = false
_G.KillAllEnabled = false
_G.AuraRange = 10
_G.SilentAimEnabled = false
_G.SilentAimWallCheck = false
_G.ShootingMethod = "New (blatant)"
_G.PredictionMultiplier = 0.125
_G.SafeAutoFarm = false
_G.WebhookURL = ""
_G.CoinTween = nil
_G.HasReportedCoins = false
_G.BindShoot = Enum.KeyCode.Q
_G.BindGun = Enum.KeyCode.R
_G.BindThrow = Enum.KeyCode.E
_G.BindBomb = Enum.KeyCode.B

local InvisibilityActive = false
local InvisConnection = nil

local StandaloneInvisGui = Instance.new("ScreenGui")
StandaloneInvisGui.Name = "StandaloneInvisGui"
StandaloneInvisGui.ResetOnSpawn = false

local invisParentSuccess, _ = pcall(function()
    StandaloneInvisGui.Parent = CoreGui
end)
if not invisParentSuccess then
    StandaloneInvisGui.Parent = lp:WaitForChild("PlayerGui")
end

local StandaloneInvisBtn = Instance.new("TextButton")
StandaloneInvisBtn.Name = "InvisToggle"
StandaloneInvisBtn.Parent = StandaloneInvisGui
StandaloneInvisBtn.Size = UDim2.new(0, 140, 0, 50)
local DefaultStandaloneInvisPos = UDim2.new(0.5, -70, 0.8, 0)
StandaloneInvisBtn.Position = DefaultStandaloneInvisPos
StandaloneInvisBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
StandaloneInvisBtn.BackgroundTransparency = 0.3
StandaloneInvisBtn.Text = "INVIS: OFF"
StandaloneInvisBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StandaloneInvisBtn.TextSize = 16
StandaloneInvisBtn.Font = Enum.Font.SourceSansBold
StandaloneInvisBtn.TextTransparency = 0.1
StandaloneInvisBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
StandaloneInvisBtn.TextStrokeTransparency = 0.5
StandaloneInvisBtn.Active = true
StandaloneInvisBtn.Draggable = false
StandaloneInvisBtn.Visible = false

local StandaloneInvisCorner = Instance.new("UICorner")
StandaloneInvisCorner.CornerRadius = UDim.new(0, 8)
StandaloneInvisCorner.Parent = StandaloneInvisBtn

local function SetCharacterTransparency(character, transparency)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            if part.Name ~= "HumanoidRootPart" then
                Plugin.Set(part,"Transparency",transparency,"invisibility")
            end
        end
    end
end

local pendingInvis=nil
local function EnableInvisibility()
    if InvisConnection then InvisConnection:Disconnect() end
    local character=lp.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end
    SetCharacterTransparency(character,.5)
    InvisConnection=Plugin.Connect(RunService.Heartbeat,function()
        if pendingInvis or not InvisibilityActive or lp.Character~=character then return end
        local pending={root=root,humanoid=humanoid,cframe=root.CFrame,offset=humanoid.CameraOffset}
        pendingInvis=pending
        local ok=pcall(function()
            local down=root.CFrame*CFrame.new(0,-200000,0)
            root.CFrame=down;humanoid.CameraOffset=down:ToObjectSpace(pending.cframe).Position
            RunService.RenderStepped:Wait()
        end)
        if pendingInvis==pending then
            pcall(function() root.CFrame=pending.cframe;humanoid.CameraOffset=pending.offset end)
            pendingInvis=nil
        end
    end)
end
local function DisableInvisibility()
    if InvisConnection then InvisConnection:Disconnect();InvisConnection=nil end
    local pending=pendingInvis;pendingInvis=nil
    if pending then pcall(function() pending.root.CFrame=pending.cframe;pending.humanoid.CameraOffset=pending.offset end) end
    Plugin.Restore("invisibility")
end

local StandaloneInvisStroke = Instance.new("UIStroke")
StandaloneInvisStroke.Thickness = 2
StandaloneInvisStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
StandaloneInvisStroke.Color = Color3.fromRGB(255, 0, 0)
StandaloneInvisStroke.Transparency = 0.2
StandaloneInvisStroke.Parent = StandaloneInvisBtn

Plugin.Connect(StandaloneInvisBtn.MouseEnter,function()
    TweenService:Create(StandaloneInvisBtn, TweenInfo.new(0.3), {
        BackgroundTransparency = 0.1,
        TextTransparency = 0
    }):Play()
    TweenService:Create(StandaloneInvisStroke, TweenInfo.new(0.3), {
        Thickness = 3
    }):Play()
end)

Plugin.Connect(StandaloneInvisBtn.MouseLeave,function()
    TweenService:Create(StandaloneInvisBtn, TweenInfo.new(0.3), {
        BackgroundTransparency = 0.3,
        TextTransparency = 0.1
    }):Play()
    TweenService:Create(StandaloneInvisStroke, TweenInfo.new(0.3), {
        Thickness = 2
    }):Play()
end)

local function toggleStandaloneInvis()
    InvisibilityActive = not InvisibilityActive

    if InvisibilityActive then
        StandaloneInvisBtn.Text = "INVIS: ON"
        StandaloneInvisStroke.Color = Color3.fromRGB(0, 255, 0)
        EnableInvisibility()
    else
        StandaloneInvisBtn.Text = "INVIS: OFF"
        StandaloneInvisStroke.Color = Color3.fromRGB(255, 0, 0)
        DisableInvisibility()
    end
end

local DefaultShootPos = UDim2.new(1, -190, 1, -180)
local DefaultGunPos = UDim2.new(1, -100, 1, -190)
local DefaultThrowPos = UDim2.new(1, -195, 1, -100)
local DefaultBombPos = UDim2.new(1, -100, 0, 100)

local function CreateFloatingButton(config)
    config = config or {}
    local name = config.Name or "Button"
    local text = config.Text or "BUTTON"
    local pos = config.Position or UDim2.new(0.5, 0, 0.5, 0)
    local size = config.Size or UDim2.new(0, 75, 0, 75)
    local isRect = config.IsRect or false
    local parent = config.Parent or ScreenGui
    local visible = config.Visible or false
    local textSize = config.TextSize or (isRect and 18 or 16)
    local cornerRadius = config.CornerRadius or (isRect and UDim.new(0, 10) or UDim.new(1, 0))
    local bgColor = config.BgColor or Color3.fromRGB(10, 10, 10)
    local bgTransparency = config.BgTransparency or 0.3
    local textColor = config.TextColor or Color3.fromRGB(255, 255, 255)
    local strokeColor = config.StrokeColor or ExodusBlue
    local strokeThickness = config.StrokeThickness or 3
    local strokeTransparency = config.StrokeTransparency or 0.2
    local onClick = config.OnClick or nil
    local draggable = config.Draggable ~= false

    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Parent = parent
    btn.Visible = visible
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = bgColor
    btn.BackgroundTransparency = bgTransparency
    btn.Text = text
    btn.TextColor3 = textColor
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = textSize
    btn.TextTransparency = 0.1
    btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    btn.TextStrokeTransparency = 0.5

    local corner = Instance.new("UICorner")
    corner.CornerRadius = cornerRadius
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = strokeThickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = strokeColor
    stroke.Transparency = strokeTransparency
    stroke.Parent = btn

    Plugin.Connect(btn.MouseEnter,function()
        TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundTransparency = 0.1, TextTransparency = 0}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.3), {Thickness = 4, Color = Color3.new(1,1,1)}):Play()
    end)

    Plugin.Connect(btn.MouseLeave,function()
        TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundTransparency = bgTransparency, TextTransparency = 0.1}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.3), {Thickness = strokeThickness, Color = strokeColor}):Play()
    end)


    return btn
end

local function CreateStatusBox(config)
    config = config or {}
    local name = config.Name or "StatusBox"
    local text = config.Text or "STATUS"
    local pos = config.Position or UDim2.new(0.5, 0, 0, 10)
    local size = config.Size or UDim2.new(0, 120, 0, 40)
    local parent = config.Parent or ScreenGui
    local visible = config.Visible or false

    local box = Instance.new("Frame")
    box.Name = name
    box.Parent = parent
    box.Visible = visible
    box.Size = size
    box.Position = pos
    box.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    box.BackgroundTransparency = 0.3

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = box

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 3
    stroke.Color = ExodusBlue
    stroke.Transparency = 0.2
    stroke.Parent = box

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextStrokeTransparency = 0.5
    label.Parent = box

    return box, label
end

local ShootBtn = CreateFloatingButton({
    Name = "ShootButton",
    Text = "SHOOT",
    Position = DefaultShootPos,
    Size = UDim2.new(0, 150, 0, 50),
    IsRect = true,
    OnClick = function() end
})

local GunBtn = CreateFloatingButton({
    Name = "GunButton",
    Text = "GUN",
    Position = DefaultGunPos,
    Size = UDim2.new(0, 75, 0, 75),
    IsRect = false,
    OnClick = function() end
})

local ThrowBtn = CreateFloatingButton({
    Name = "ThrowButton",
    Text = "THROW",
    Position = DefaultThrowPos,
    Size = UDim2.new(0, 75, 0, 75),
    IsRect = false,
    OnClick = function() end
})

local BombBtn = CreateFloatingButton({
    Name = "BombButton",
    Text = "BOMB",
    Position = DefaultBombPos,
    Size = UDim2.new(0, 75, 0, 75),
    IsRect = false,
    OnClick = function() end
})

local TimerBox, TimerText = CreateStatusBox({
    Name = "TimerBox",
    Text = "TIME: --",
    Position = UDim2.new(0.5, -60, 0, 10),
    Size = UDim2.new(0, 120, 0, 40)
})

local ChanceBox, ChanceText = CreateStatusBox({
    Name = "ChanceBox",
    Text = "Soon",
    Position = UDim2.new(0.5, -75, 0, 55),
    Size = UDim2.new(0, 150, 0, 35)
})

local function performLeap(targetHRP)
    if leapDebounce or not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
    leapDebounce = true
    local hrp = lp.Character.HumanoidRootPart
    local direction = (targetHRP.Position - hrp.Position).Unit
    local attachment = Instance.new("Attachment", hrp)
    local lv = Instance.new("LinearVelocity", attachment)
    lv.MaxForce = 100000
    lv.VectorVelocity = direction * 80
    lv.Attachment0 = attachment
    task.wait(0.2)
    lv:Destroy()
    attachment:Destroy()
    task.wait(1.3)
    leapDebounce = false
end

Plugin.Connect(RunService.Heartbeat,function()
    if _G.AutoLeap and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local holdingKnife = lp.Character:FindFirstChild("Knife")
        if holdingKnife and not leapDebounce then
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (lp.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
                    if dist <= 10 then
                        performLeap(v.Character.HumanoidRootPart)
                       break
                    end
                end
            end
        end
    end
end)

Plugin.Connect(RunService.Heartbeat,function()
    pcall(function()
        if lp.Character and lp.Character:FindFirstChild("Humanoid") and lp.Character:FindFirstChild("HumanoidRootPart") then
            local char = lp.Character
            local hum = char.Humanoid
            local hrp = char.HumanoidRootPart
            if _G.ApplySpeed then Plugin.Set(hum,"WalkSpeed",_G.DesiredSpeed,"movement") end
            if _G.ApplyJump then Plugin.Set(hum,"UseJumpPower",true,"movement");Plugin.Set(hum,"JumpPower",_G.DesiredJump,"movement") end
            if _G.SpeedGlitchEnabled and hum.FloorMaterial == Enum.Material.Air then
                local moveDir = hum.MoveDirection
                if moveDir.Magnitude > 0 then
                    local newVel = Vector3.new(moveDir.X * _G.SpeedGlitchValue, hrp.Velocity.Y, moveDir.Z * _G.SpeedGlitchValue)
                    hrp.Velocity = newVel
                    hrp.AssemblyLinearVelocity = newVel
                end
            end
        end
    end)
end)

task.spawn(function()
    while Plugin.alive do
        pcall(function()
            local t = workspace.RoundTimerPart.SurfaceGui.Timer
            TimerText.Text = t.Text
        end)
        pcall(function()
            local chance = lp.PlayerGui.MainGui.Lobby.Chance.Text
            ChanceText.Text = "MURDERER: " .. chance
        end)
        task.wait(0.5)
    end
end)

local function getDynamicPrediction(targetRoot, myRoot)
    local targetVelocity = targetRoot.AssemblyLinearVelocity
    local distance = (myRoot.Position - targetRoot.Position).Magnitude
    local pingValue = 0.06
    pcall(function()
        local pingStr = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
        pingValue = tonumber(pingStr:match("%d+")) / 1000 or 0.06
    end)
    local travelTime = distance / 175
    local speedMultiplier = math.clamp(targetVelocity.Magnitude / 16, 0.5, 1.5)
    return (pingValue + travelTime) * speedMultiplier
end

-- Forward declaration: getMurderer() is defined further below but is used by
-- getCombatData() for role-aware target selection.
local getMurderer

-- Returns the best part to use as the shot origin. Prefers the equipped gun's
-- Handle (this is exactly what the real MM2 GunFired signature uses), then the
-- arm, then the root. Never hard-fails on a missing arm (R6/R15/custom rigs).
local function getOriginPart()
    local char = lp.Character
    if not char then return nil end
    local gun = char:FindFirstChild("Gun") or (lp:FindFirstChild("Backpack") and lp.Backpack:FindFirstChild("Gun"))
    if gun then
        local h = gun:FindFirstChild("Handle")
        if h then return h end
    end
    return char:FindFirstChild("Right Arm")
        or char:FindFirstChild("RightHand")
        or char:FindFirstChild("HumanoidRootPart")
end

local function getCombatData()
    local char = lp.Character
    local myHRP = char and char:FindFirstChild("HumanoidRootPart")
    local originPart = getOriginPart()
    if not myHRP or not originPart then return nil end

    -- Prefer the shared role-aware resolver (visible knife -> role cache), so
    -- shooting still works when the murderer's knife is not currently visible.
    local target = getMurderer()
    if not target or not target.Character then
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p ~= lp and p.Character then
                if p.Character:FindFirstChild("Knife") or (p:FindFirstChild("Backpack") and p.Backpack:FindFirstChild("Knife")) then
                    target = p
                    break
                end
            end
        end
    end

    if not target or not target.Character:FindFirstChild("HumanoidRootPart") then return nil end

    local root = target.Character.HumanoidRootPart
    local velocity = root.AssemblyLinearVelocity
    local activeMethod = _G.ShootingMethod

    if activeMethod == "New (blatant)" and _G.SilentAimWallCheck then
        local visible = false
        local partsToCheck = {target.Character:FindFirstChild("Head"), root, target.Character:FindFirstChild("UpperTorso")}
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local ignoreList = {}
        for _, v in ipairs(game.Players:GetPlayers()) do
            if v.Character then table.insert(ignoreList, v.Character) end
        end
        rayParams.FilterDescendantsInstances = ignoreList

        for _, part in ipairs(partsToCheck) do
            if part then
                local direction = (part.Position - originPart.Position)
                local result = workspace:Raycast(originPart.Position, direction, rayParams)
                if not result then
                    visible = true
                    break
                end
            end
        end
        if not visible then activeMethod = "Normal" end
    end

    local predTime = _G.PredictionMultiplier or 0.12
    local flatVelocity = Vector3.new(velocity.X, 0, velocity.Z)
    local flatOffset = flatVelocity * predTime
    local clampedY = math.clamp((velocity.Y * predTime), -1.2, 1.2)
    local verticalOffset = Vector3.new(0, clampedY, 0)

    if velocity.Magnitude < 2 then
        flatOffset = Vector3.new(0, 0, 0)
        verticalOffset = Vector3.new(0, 0, 0)
    end

    local finalPredictionOffset = flatOffset + verticalOffset
    -- Origin is ALWAYS the real shooter position (gun handle). The old
    -- "New (blatant)" mode put the origin on top of the target, which the
    -- server rejects, so shots never registered.
    local originPos = originPart.Position
    local targetPos

    if activeMethod == "New (blatant)" then
        targetPos = root.Position + (root.AssemblyLinearVelocity * 0.12)
    else
        local dist = (myHRP.Position - root.Position).Magnitude
        local dropComp = Vector3.new(0, (dist / 140), 0)
        targetPos = root.Position + finalPredictionOffset + dropComp
    end

    return root, originPos, targetPos
end

local function TeleportToLobby()
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    local lobby = workspace:FindFirstChild("RegularLobby")
    if hrp and hum and lobby then
        if _G.CoinTween then
            _G.CoinTween:Cancel()
            _G.CoinTween = nil
        end
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        hrp.CFrame = lobby:GetPivot() + Vector3.new(0, 5, 0)
    end
end

getMurderer = function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local backpack = p:FindFirstChild("Backpack")
            local char = p.Character
            if backpack and backpack:FindFirstChild("Knife") then
                return p
            end
            if char and char:FindFirstChild("Knife") then
                return p
            end
        end
    end
    for name, data in pairs(roleCache) do
        if data.Role == "Murderer" then
            local p = Players:FindFirstChild(name)
            if p then return p end
        end
    end
    return nil
end

local function getSheriff()
    if workspace:FindFirstChild("GunDrop", true) then
        return nil
    end
    for _, p in pairs(game:GetService("Players"):GetPlayers()) do
        if p ~= lp and p.Character then
            local backpack = p:FindFirstChild("Backpack")
            local char = p.Character
            local hasGun = char:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun"))
            if hasGun then return p end
        end
    end
    for name, data in pairs(roleCache) do
        if data.Role == "Sheriff" or data.Role == "Hero" then
            local p = game:GetService("Players"):FindFirstChild(name)
            if p then return p end
        end
    end
    return nil
end

local function throwAction()
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
    local knife = lp.Character:FindFirstChild("Knife") or lp.Backpack:FindFirstChild("Knife")
    local near, dist = nil, math.huge
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local d = (lp.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
            if d < dist then dist = d near = v end
        end
    end
    if knife and near and near.Character:FindFirstChild("HumanoidRootPart") then
        if knife.Parent == lp.Backpack then lp.Character.Humanoid:EquipTool(knife) end
        local targetHRP = near.Character.HumanoidRootPart
        local myHRP = lp.Character.HumanoidRootPart
        local origin = myHRP.Position
        local targetPos = targetHRP.Position
        local args = {
            [1] = CFrame.new(origin, targetPos) * CFrame.Angles(1.4531978368759155, 0.04432811588048935, 1.6501713991165161),
            [2] = CFrame.new(targetPos) * CFrame.Angles(-0, 0, -0)
        }
        if knife:FindFirstChild("Events") and knife.Events:FindFirstChild("KnifeThrown") then
            knife.Events.KnifeThrown:FireServer(unpack(args))
        end
    end
end

-- Combat v4: real MM2 signature captured from the live game with a remote spy:
--   ReplicatedStorage.ClientServices.WeaponService.GunFired:FireServer(
--       gunHandle, originPosition, hitPosition, hitPart)
-- Layers:
--   1. target selection: visible knife holder -> role data (GetPlayerData) fallback;
--   2. direct shot via the real GunFired remote (primary);
--   3. legacy Gun.KnifeLocal.CreateBeam.RemoteFunction invoke as fallback;
--   4. "game-like" click: camera snap + Tool:Activate() + simulated click;
--   5. silent aim rewrites the game's own GunFired (hit position + hit part)
--      or legacy InvokeServer shots;
--   6. built-in shot logger prints the exact remote call the game makes.
local AimStatus = nil
local lastShotResult = "Idle."
local gunRemoteCache = {}
local gunFiredCache = nil
local shootBusy = false
local namecallHookInstalled = false
local shotLogging = false
local shotLogCount = 0
local autoShootThread = nil

local function reportAim(text)
    lastShotResult = tostring(text)
    if AimStatus then pcall(function() AimStatus:Set({Content = lastShotResult}) end) end
end

local function getTargetData()
    local root, originPos, targetPos = getCombatData()
    if root and originPos and targetPos then return root, originPos, targetPos end
    local murderer = getMurderer()
    if not murderer or not murderer.Character then return nil end
    local char = lp.Character
    local myHRP = char and char:FindFirstChild("HumanoidRootPart")
    local originPart = getOriginPart()
    local targetRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP or not originPart or not targetRoot then return nil end
    local velocity = targetRoot.AssemblyLinearVelocity
    local predTime = _G.PredictionMultiplier or 0.12
    local flatOffset, verticalOffset = Vector3.zero, Vector3.zero
    if velocity.Magnitude >= 2 then
        flatOffset = Vector3.new(velocity.X, 0, velocity.Z) * predTime
        verticalOffset = Vector3.new(0, math.clamp(velocity.Y * predTime, -1.2, 1.2), 0)
    end
    local dist = (myHRP.Position - targetRoot.Position).Magnitude
    local dropComp = Vector3.new(0, (dist / 140), 0)
    return targetRoot, originPart.Position, targetRoot.Position + flatOffset + verticalOffset + dropComp
end

local function hasLineOfSight(fromPosition, targetRoot)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = {}
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p.Character then ignore[#ignore + 1] = p.Character end
    end
    params.FilterDescendantsInstances = ignore
    local result = workspace:Raycast(fromPosition, targetRoot.Position - fromPosition, params)
    return result == nil
end

local function findGunFiredRemote()
    local rs = game:GetService("ReplicatedStorage")
    local ok, remote = pcall(function()
        return rs.ClientServices.WeaponService.GunFired
    end)
    if ok and remote then return remote end
    ok, remote = pcall(function()
        local cs = rs:FindFirstChild("ClientServices")
        if not cs then return nil end
        local ws = cs:FindFirstChild("WeaponService")
        if not ws then return nil end
        return ws:FindFirstChild("GunFired") or ws:FindFirstChild("ShootGun")
    end)
    if ok and remote then return remote end
    ok, remote = pcall(function()
        for _, inst in ipairs(rs:GetDescendants()) do
            if inst.Name == "GunFired" then return inst end
        end
        return nil
    end)
    if ok and remote then return remote end
    return nil
end

local function fireGunFired(gun, targetPart, targetPos)
    local remote = gunFiredCache
    if not remote or not remote.Parent then
        remote = findGunFiredRemote()
        gunFiredCache = remote
    end
    if not remote then return false, "GunFired remote not found" end
    local handle
    pcall(function() handle = gun:FindFirstChild("Handle") end)
    if not handle then return false, "gun Handle not found" end
    local origin
    pcall(function() origin = handle.Position end)
    if typeof(origin) ~= "Vector3" or origin.X ~= origin.X or origin.Y ~= origin.Y or origin.Z ~= origin.Z then
        return false, "gun Handle has no usable position"
    end
    if typeof(targetPos) ~= "Vector3" or targetPos.X ~= targetPos.X or targetPos.Y ~= targetPos.Y or targetPos.Z ~= targetPos.Z then
        return false, "target position is not a valid Vector3"
    end
    -- Signature captured from the live game: (Handle, origin, hit, hitPart).
    local ok, err = pcall(function() remote:FireServer(handle, origin, targetPos, targetPart) end)
    if ok then return true end
    local first = tostring(err)
    -- Retry without the hit part.
    local ok2, err2 = pcall(function() remote:FireServer(handle, origin, targetPos) end)
    if ok2 then return true end
    -- Retry with a weapon-name string in case the remote expects (string, ...).
    local ok3, err3 = pcall(function() remote:FireServer(tostring(gun.Name), origin, targetPos, targetPart) end)
    if ok3 then return true end
    return false, first:sub(1, 140) .. " / 3-arg: " .. tostring(err2):sub(1, 80)
end

local function resolveGunRemote(gun)
    local cached = gunRemoteCache.remote
    if cached and cached.Parent then return cached, gunRemoteCache.kind end
    gunRemoteCache = {}
    local function chain(parent, names)
        local current = parent
        for _, name in ipairs(names) do
            if not current then return nil end
            current = current:FindFirstChild(name)
        end
        return current
    end
    local remote = chain(gun, {"KnifeLocal", "CreateBeam", "RemoteFunction"})
    if not remote then
        pcall(function() remote = gun:FindFirstChild("ShootGun", true) end)
    end
    if not remote then
        pcall(function() remote = game:GetService("ReplicatedStorage"):FindFirstChild("ShootGun") end)
    end
    -- No fuzzy name scan: invoking a random similarly named remote produces
    -- confusing "argument #1 expects a string" server errors.
    if not remote then return nil end
    local kind = "InvokeServer"
    local isFunction, isEvent = false, false
    pcall(function() isFunction = remote:IsA("RemoteFunction") end)
    if not isFunction then
        pcall(function() isEvent = remote:IsA("RemoteEvent") end)
        if isEvent then kind = "FireServer" else return nil end
    end
    gunRemoteCache.remote = remote
    gunRemoteCache.kind = kind
    return remote, kind
end

local function invokeShot(remote, kind, targetPos)
    if kind == "FireServer" then
        return pcall(function() remote:FireServer(1, targetPos, "AH2") end)
    end
    return pcall(function() return remote:InvokeServer(1, targetPos, "AH2") end)
end

local function shootViaClick(gun, targetPos)
    local cam = workspace.CurrentCamera
    if not cam or not targetPos then return false, "no camera or target" end
    local ok, err = pcall(function()
        local oldCF = cam.CFrame
        cam.CFrame = CFrame.lookAt(oldCF.Position, targetPos)
        pcall(function() gun:Activate() end)
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local size = cam.ViewportSize
            local cx, cy = size.X / 2, size.Y / 2
            vim:SendMouseMoveEvent(cx, cy)
            vim:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
            vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
        end)
        RunService.RenderStepped:Wait()
        cam.CFrame = oldCF
    end)
    if not ok then return false, err end
    return true
end

local function attemptShot(gun, targetPart, targetPos)
    local mode = _G.ShootMode or "Auto (click + remote)"
    local doClick = mode:find("Auto") ~= nil or mode:find("click") ~= nil
    local doRemote = mode:find("Auto") ~= nil or mode:find("remote") ~= nil
    local clickOk, clickErr, remoteOk, remoteErr = false, "skipped", false, "skipped"
    if doClick then
        clickOk, clickErr = shootViaClick(gun, targetPos)
    end
    if doRemote then
        remoteOk, remoteErr = fireGunFired(gun, targetPart, targetPos)
        if not remoteOk then
            local legacy, kind = resolveGunRemote(gun)
            if legacy then
                local legacyOk, legacyErr = invokeShot(legacy, kind, targetPos)
                if legacyOk then
                    remoteOk, remoteErr = true, nil
                elseif remoteErr == "skipped" then
                    remoteErr = legacyErr
                end
            end
        end
    end
    return clickOk or remoteOk, clickOk, clickErr, remoteOk, remoteErr, mode
end

local function fireGunWorker()
    if shootBusy or not Plugin.alive then return end
    shootBusy = true
    local function finish(result, notify)
        reportAim(result)
        if notify then Plugin.Notify(result) end
        shootBusy = false
    end
    local char = lp.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if not char or not hum then shootBusy = false return end
    local gun = char:FindFirstChild("Gun") or (lp:FindFirstChild("Backpack") and lp.Backpack:FindFirstChild("Gun"))
    if not gun then return finish("No gun found. Take the sheriff gun first (Auto Grab Gun can help).", true) end
    if gun.Parent ~= char then
        pcall(function() hum:EquipTool(gun) end)
        local waited = 0
        while gun.Parent ~= char and waited < 0.35 and Plugin.alive do
            task.wait(0.05)
            waited = waited + 0.05
        end
    end
    if gun.Parent ~= char then return finish("Could not equip the gun.", true) end
    local root, originPos, targetPos = getTargetData()
    if not targetPos then return finish("No murderer detected: knife not visible and no role data yet (wait a few seconds).", true) end
    local anyOk, clickOk, clickErr, remoteOk, remoteErr, mode = attemptShot(gun, root, targetPos)
    if not anyOk then
        return finish("Shot failed [" .. mode .. "] click: " .. tostring(clickErr) .. " / remote: " .. tostring(remoteErr), true)
    end
    local via = {}
    if clickOk then via[#via + 1] = "click" end
    if remoteOk then via[#via + 1] = "remote" end
    finish("Shot fired at " .. tostring(root and root.Parent and root.Parent.Name or "target") .. " via " .. table.concat(via, "+") .. " [" .. mode .. "].", false)
end

local function fireGun()
    Plugin.task.spawn(fireGunWorker)
end

local function computeSilentTarget()
    local root, originPos, targetPos = getTargetData()
    if root and targetPos then return targetPos, root end
    return nil, nil
end

local function isShotRemote(self)
    if gunRemoteCache.remote and self == gunRemoteCache.remote then return true end
    if gunFiredCache and self == gunFiredCache then return true end
    local ok, match = pcall(function()
        if self.Name == "GunFired" then return true end
        if self.Name == "ShootGun" then return true end
        if self.Name == "RemoteFunction" and self.Parent and (self.Parent.Name == "CreateBeam" or self.Parent.Name == "KnifeLocal") then return true end
        return false
    end)
    return ok and match == true
end

local function looksLikeShot(args)
    for i = 1, args.n do
        local v = args[i]
        if type(v) == "string" then
            local lower = v:lower()
            if v == "AH2" or lower:find("shoot") or lower:find("beam") then return true end
        end
    end
    if args.n >= 2 and args[1] == 1 and (typeof(args[2]) == "Vector3" or typeof(args[2]) == "CFrame") then return true end
    if args.n >= 4 and typeof(args[2]) == "Vector3" and typeof(args[3]) == "Vector3" then return true end
    return false
end

local function logShot(method, self, args)
    if shotLogCount >= 12 then return end
    shotLogCount = shotLogCount + 1
    local parts = {}
    for i = 1, math.min(args.n, 6) do
        local ok, text = pcall(function()
            local v = args[i]
            if typeof(v) == "Instance" then return v:GetFullName() end
            if typeof(v) == "Vector3" then return string.format("Vector3(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z) end
            if typeof(v) == "CFrame" then return "CFrame(" .. tostring(v.Position) .. ")" end
            return tostring(v)
        end)
        parts[#parts + 1] = ok and text or "<unreadable>"
    end
    local okName, fullName = pcall(function() return self:GetFullName() end)
    warn(string.format("[MM2 Assist][shot %d] %s %s | args(%d): %s",
        shotLogCount, method, okName and fullName or tostring(self.Name), args.n, table.concat(parts, ", ")))
end

local function installNamecallHook()
    if namecallHookInstalled then return true end
    if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then
        Plugin.Notify("Silent Aim / shot logging needs executor support (hookmetamethod). Manual Shoot and Auto Shoot still work.")
        return false
    end
    local ok = pcall(function()
        local original
        local handler = function(self, ...)
            local method = getnamecallmethod()
            if Plugin.alive and (method == "InvokeServer" or method == "FireServer") then
                local redirect = _G.SilentAimEnabled and isShotRemote(self)
                local log = shotLogging
                if redirect or log then
                    local args = table.pack(...)
                    if log and (looksLikeShot(args) or isShotRemote(self)) then
                        logShot(method, self, args)
                    end
                    if redirect then
                        local okAim, position, part = pcall(computeSilentTarget)
                        if okAim and position then
                            if method == "FireServer" then
                                -- Real MM2 signature: (Handle, origin, hit, hitPart).
                                -- Rewrite the hit position (arg 3) and, when present,
                                -- the hit part (arg 4). Never touch the origin (arg 2).
                                if args.n >= 3 then args[3] = position end
                                if args.n >= 4 and part then args[4] = part end
                            else
                                -- Legacy InvokeServer path: (1, hitPos, "AH2").
                                args[2] = position
                            end
                        end
                    end
                    return original(self, table.unpack(args, 1, args.n))
                end
            end
            return original(self, ...)
        end
        if type(newcclosure) == "function" then handler = newcclosure(handler) end
        original = hookmetamethod(game, "__namecall", handler)
    end)
    if not ok then
        Plugin.Notify("Silent Aim hook was blocked by the executor.")
        return false
    end
    namecallHookInstalled = true
    return true
end

local function startAutoShoot()
    if autoShootThread then return end
    autoShootThread = Plugin.task.spawn(function()
        local nextShot = 0
        while Plugin.alive and _G.AutoShootEnabled do
            local char = lp.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local gun = char and char:FindFirstChild("Gun") or (lp:FindFirstChild("Backpack") and lp.Backpack:FindFirstChild("Gun"))
            if char and hum and gun and os.clock() >= nextShot then
                if gun.Parent ~= char then
                    pcall(function() hum:EquipTool(gun) end)
                else
                    local root, originPos, targetPos = getTargetData()
                    if root and targetPos then
                        local clear = true
                        if _G.SilentAimWallCheck then
                            local myHRP = char:FindFirstChild("HumanoidRootPart")
                            clear = myHRP ~= nil and hasLineOfSight(myHRP.Position, root)
                        end
                        if clear then
                            local ok = attemptShot(gun, root, targetPos)
                            if ok then
                                nextShot = os.clock() + 0.5
                                reportAim("Auto shot fired [" .. tostring(_G.ShootMode or "Auto (click + remote)") .. "].")
                            else
                                nextShot = os.clock() + 1
                            end
                        end
                    end
                end
            end
            task.wait(0.15)
        end
        autoShootThread = nil
    end)
end

local function dumpAimInfo()
    local lines = {}
    local function add(text) lines[#lines + 1] = tostring(text) end
    local char = lp.Character
    add("character: " .. (char and char.Name or "none"))
    local gun = char and (char:FindFirstChild("Gun") or (lp:FindFirstChild("Backpack") and lp.Backpack:FindFirstChild("Gun"))) or nil
    add("gun: " .. (gun and (gun.Name .. " in " .. tostring(gun.Parent and gun.Parent.Name)) or "not found"))
    local gfOk, gf = pcall(findGunFiredRemote)
    add("GunFired remote: " .. (gfOk and gf and (tostring(gf.ClassName) .. " " .. tostring(gf:GetFullName())) or "not found"))
    if gun then
        pcall(function()
            local count = 0
            for _, d in ipairs(gun:GetDescendants()) do
                if count >= 60 then break end
                count = count + 1
                add("  gun/" .. d.Name .. " : " .. d.ClassName)
            end
        end)
        local remote, kind = resolveGunRemote(gun)
        add("legacy remote: " .. (remote and (remote.Name .. " (" .. kind .. ") under " .. tostring(remote.Parent and remote.Parent.Name)) or "none"))
    end
    add("hookmetamethod: " .. (type(hookmetamethod) == "function" and "yes" or "no") .. "; hook: " .. (namecallHookInstalled and "installed" or "off") .. "; shot logging: " .. (shotLogging and "on" or "off"))
    add("shoot mode: " .. tostring(_G.ShootMode or "Auto (click + remote)"))
    local root, originPos, targetPos = getTargetData()
    add("target: " .. (root and root.Parent and root.Parent.Name or "none") .. (targetPos and (" @ " .. tostring(targetPos)) or ""))
    add("last result: " .. lastShotResult)
    for _, line in ipairs(lines) do
        warn("[MM2 Assist] " .. line)
    end
    Plugin.Notify("Aim debug written to console (" .. #lines .. " lines). Send it to the developer if shooting fails.")
end

_G.AutoShootEnabled = false
_G.ShootMode = "Auto (click + remote)"
Plugin.cleanups[#Plugin.cleanups + 1] = function()
    _G.SilentAimEnabled = false
    _G.AutoShootEnabled = false
    shotLogging = false
    shootBusy = false
end

local function grabGunAction()
    local d = workspace:FindFirstChild("GunDrop", true)
    if d and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        firetouchinterest(lp.Character.HumanoidRootPart, d, 0)
        firetouchinterest(lp.Character.HumanoidRootPart, d, 1)
    end
end

local function toggleAntiFling(state)
    if flingDetectionCon then flingDetectionCon:Disconnect() end
    if flingNeutralizerCon then flingNeutralizerCon:Disconnect() end
    antiFlingEnabled = state
    if state then
        Rayfield:Notify({Title = "Anti-Fling", Content = "Protection Activated", Duration = 2})
        flingDetectionCon = Plugin.Connect(RunService.Heartbeat,function()
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= lp and pl.Character and pl.Character.PrimaryPart then
                    local primary = pl.Character.PrimaryPart
                    if primary.AssemblyAngularVelocity.Magnitude > 50 or primary.AssemblyLinearVelocity.Magnitude > 100 then
                        for _, p in ipairs(pl.Character:GetDescendants()) do
                            if p:IsA("BasePart") then Plugin.Set(p,"CanCollide",false,"antiFling") end
                        end
                    end
                end
            end
        end)
        flingNeutralizerCon = Plugin.Connect(RunService.Heartbeat,function()
            if lp.Character and lp.Character.PrimaryPart then
                local hrp = lp.Character.PrimaryPart
                if hrp.AssemblyLinearVelocity.Magnitude > 250 or hrp.AssemblyAngularVelocity.Magnitude > 250 then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end)
    else
        if flingDetectionCon then flingDetectionCon:Disconnect() end
        if flingNeutralizerCon then flingNeutralizerCon:Disconnect() end
        detectedPlayers = {}
        Plugin.Restore("antiFling")
        Rayfield:Notify({Title = "Anti-Fling", Content = "Protection Deactivated", Duration = 2})
    end
end

local function rawExecuteFling(target)
    if not target or not target.Character then
        Rayfield:Notify({Title = "Exodus Error", Content = "Target not found.", Duration = 2})
        return
    end
    local wasAntiFlingOn = antiFlingEnabled
    if wasAntiFlingOn then
        toggleAntiFling(false)
        task.wait(0.2)
    end
    local player = lp
    local Targets = {target}
    local AllBool = false

    local SkidFling = function(TargetPlayer)
        local Character = player.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        local RootPart = Humanoid and Humanoid.RootPart
        local TCharacter = TargetPlayer.Character
        local THumanoid
        local TRootPart
        local THead
        local Accessory
        local Handle

        if TCharacter:FindFirstChildOfClass("Humanoid") then
            THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
        end
        if THumanoid and THumanoid.RootPart then
          TRootPart = THumanoid.RootPart
        end
        if TCharacter:FindFirstChild("Head") then
            THead = TCharacter.Head
        end
        if TCharacter:FindFirstChildOfClass("Accessory") then
            Accessory = TCharacter:FindFirstChildOfClass("Accessory")
        end
        if Accessory and Accessory:FindFirstChild("Handle") then
            Handle = Accessory.Handle
        end

        if Character and Humanoid and RootPart then
            getgenv().OldPos = RootPart.CFrame
            getgenv().FPDH = workspace.FallenPartsDestroyHeight
            if THead then
                workspace.CurrentCamera.CameraSubject = THead
            elseif not THead and Handle then
                workspace.CurrentCamera.CameraSubject = Handle
            elseif THumanoid and TRootPart then
                workspace.CurrentCamera.CameraSubject = THumanoid
            end
            if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end

            local FPos = function(BasePart, Pos, Ang)
                RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
                Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
                RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
                RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
            end
            local SFBasePart = function(BasePart)
                local TimeToWait = 2
                local Time = tick()
                local Angle = 0
                repeat
                    if RootPart and THumanoid then
                        if BasePart.Velocity.Magnitude < 50 then
                            Angle = Angle + 100
                            FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                        else
                            FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                            task.wait()
                        end
                    else
                        break
                    end
                until not Plugin.alive or lp.Character~=Character or BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or TargetPlayer.Character ~= TCharacter or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
            end

            workspace.FallenPartsDestroyHeight = 0/0
            local BV = Instance.new("BodyVelocity")
            BV.Name = "EpixVel"
            BV.Parent = RootPart
            BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
            BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

            if TRootPart and THead then
                if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
                    SFBasePart(THead)
                else
                    SFBasePart(TRootPart)
                end
            elseif TRootPart and not THead then
                SFBasePart(TRootPart)
            elseif not TRootPart and THead then
                SFBasePart(THead)
            elseif not TRootPart and not THead and Accessory and Handle then
                SFBasePart(Handle)
            else
                Rayfield:Notify({Title = "Exodus Error", Content = "Cannot find proper part to fling.", Duration = 3})
            end

            BV:Destroy()
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            workspace.CurrentCamera.CameraSubject = Humanoid

            local returnDeadline=os.clock()+3
            repeat
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                for _, x in pairs(Character:GetChildren()) do
                    if x:IsA("BasePart") then
                        x.Velocity = Vector3.new()
                        x.RotVelocity = Vector3.new()
                    end
                end
                task.wait()
            until not Plugin.alive or lp.Character~=Character or os.clock()>returnDeadline or (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
            workspace.FallenPartsDestroyHeight = getgenv().FPDH
        else
            Rayfield:Notify({Title = "Exodus Error", Content = "No valid character of target player.", Duration = 3})
        end
    end

    SkidFling(Targets[1])
    if wasAntiFlingOn then
        task.wait(0.5)
        toggleAntiFling(true)
    end
end

local flingBusy=false
local function executeFling(target)
    if flingBusy then return end
    flingBusy=true
    local char=lp.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    local cam=workspace.CurrentCamera
    local oldSubject=cam and cam.CameraSubject
    local oldHeight=workspace.FallenPartsDestroyHeight
    local oldCF=root and root.CFrame
    local oldSeated=hum and hum:GetStateEnabled(Enum.HumanoidStateType.Seated)
    local wasAnti=antiFlingEnabled
    local function restore()
        if cam then pcall(function() cam.CameraSubject=oldSubject end) end
        pcall(function() workspace.FallenPartsDestroyHeight=oldHeight end)
        if hum and oldSeated~=nil then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated,oldSeated) end) end
        if root then pcall(function()
            local bv=root:FindFirstChild("EpixVel");if bv then bv:Destroy() end
            if lp.Character==char and oldCF then root.CFrame=oldCF end
            root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
        end) end
        flingBusy=false
    end
    Plugin.flingRestore=restore
    local ok,err=pcall(rawExecuteFling,target)
    restore();Plugin.flingRestore=nil
    if Plugin.alive and wasAnti and not antiFlingEnabled then toggleAntiFling(true) end
    if not ok then Plugin.Notify("Fling failed: "..tostring(err)) end
end

local lastRole = nil
task.spawn(function()
    while Plugin.alive and task.wait(1) and Plugin.alive do
        if _G.RoleNotify then
            local myData = roleCache[lp.Name]
            if myData and type(myData) == "table" then
                local currentRole = myData.Role or "Innocent"
                if currentRole ~= lastRole then
                    local roleIcon = 4483345998
                    if currentRole == "Murderer" then
                        roleIcon = 10795431606
                    elseif currentRole == "Sheriff" or currentRole == "Hero" then
                        roleIcon = 10795430489
                    end
                    Rayfield:Notify({
                        Title = "ROUND START",
                        Content = "Assigned Role: " .. currentRole:upper(),
                        Duration = 5,
                        Image = roleIcon,
                    })
                    lastRole = currentRole
                end
            else
                lastRole = nil
            end
        else
            local myData = roleCache[lp.Name]
            if myData and type(myData) == "table" then
                lastRole = myData.Role or "Innocent"
            end
        end
    end
end)

Plugin.Connect(UserInputService.InputBegan,function(input, gameProcessed)
    if gameProcessed or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == _G.BindShoot then
        fireGun()
    elseif input.KeyCode == _G.BindThrow then
        throwAction()
    elseif input.KeyCode == _G.BindGun then
        grabGunAction()
    elseif input.KeyCode == _G.BindBomb then
        deployBomb()
    end
end)

task.spawn(function()
    while Plugin.alive and task.wait(1.5) and Plugin.alive do
        local success, data = pcall(function()
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("GetPlayerData", true)
            if remote then
                return remote:InvokeServer()
            end
        end)
        if success and type(data) == "table" then
            roleCache = data
        end
    end
end)

local function applyPlayerESP(p)
    if not p or p == lp then return end
    local function setup(char)
        if not char then return end
        local head = char:WaitForChild("Head", 10)
        if not head then return end

        local highlight = char:FindFirstChild("ODHAssistESP") or Instance.new("Highlight")
        highlight.Name = "ODHAssistESP"
        highlight.Parent = char
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0

        local bill = head:FindFirstChild("ODHAssistBill") or Instance.new("BillboardGui")
        bill.Name = "ODHAssistBill"
        bill.Parent = head
        bill.Adornee = head
        bill.Size = UDim2.new(0, 150, 0, 50)
        bill.AlwaysOnTop = true
        bill.ExtentsOffset = Vector3.new(0, 3, 0)

        local label = bill:FindFirstChild("TextLabel") or Instance.new("TextLabel")
        label.Parent = bill
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.TextStrokeTransparency = 0

        task.spawn(function()
            while Plugin.alive and char and char.Parent and p and p.Parent and p.Character == char do
                if _G.ESPEnabled then
                    highlight.Enabled = true
                    bill.Enabled = true

                    local activeHero = nil
                    for _, player in ipairs(game.Players:GetPlayers()) do
                        if player and player.Character then
                            local bp = player:FindFirstChild("Backpack")
                            local charGun = player.Character:FindFirstChild("Gun")
                            local backGun = bp and bp:FindFirstChild("Gun")
                            if charGun or backGun then
                                activeHero = player
                                break
                            end
                        end
                    end

                    local backpack = p:FindFirstChild("Backpack")
                    local hasKnife = (backpack and backpack:FindFirstChild("Knife")) or char:FindFirstChild("Knife")
                    local hasGun = (backpack and backpack:FindFirstChild("Gun")) or char:FindFirstChild("Gun")
                    local gunDropped = workspace:FindFirstChild("GunDrop", true)
                    local pData = roleCache[p.Name]
                    local role = (pData and type(pData) == "table" and pData.Role) or "Innocent"

                    if hasKnife or role == "Murderer" then
                        local mColor = Color3.fromRGB(255, 0, 0)
                        highlight.FillColor = mColor
                        label.Text = "MURDERER\n▼"
                        label.TextColor3 = mColor
                    elseif hasGun then
                        local sColor = Color3.fromRGB(160, 32, 240)
                        highlight.FillColor = sColor
                        label.Text = "SHERIFF\n▼"
                        label.TextColor3 = sColor
                    elseif role == "Sheriff" or role == "Hero" then
                        if gunDropped or (activeHero and activeHero ~= p) then
                            local iColor = Color3.fromRGB(0, 255, 0)
                            highlight.FillColor = iColor
                            label.Text = "▼"
                            label.TextColor3 = iColor
                        else
                            local sColor = Color3.fromRGB(160, 32, 240)
                            highlight.FillColor = sColor
                            label.Text = "SHERIFF\n▼"
                            label.TextColor3 = sColor
                        end
                    else
                        local iColor = Color3.fromRGB(0, 255, 0)
                        highlight.FillColor = iColor
                        label.Text = "▼"
                        label.TextColor3 = iColor
                    end
                else
                    highlight.Enabled = false
                    bill.Enabled = false
                end
                task.wait(0.5)
            end
        end)
    end
    Plugin.Connect(p.CharacterAdded,setup)
    if p.Character then task.spawn(setup,p.Character) end
end

for _, player in pairs(game.Players:GetPlayers()) do
    applyPlayerESP(player)
end
Plugin.Connect(game.Players.PlayerAdded,applyPlayerESP)

local function ResetCharacterPhysics()
    if lp.Character and lp.Character:FindFirstChild("Humanoid") then
        local hum = lp.Character.Humanoid
        local hrp = lp.Character:FindFirstChild("HumanoidRootPart")
        if layTrack then layTrack:Stop() end
        hum.JumpPower = _G.DesiredJump
        hum.WalkSpeed = _G.DesiredSpeed
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        for _, part in pairs(lp.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
        if hrp then
            hrp.CFrame = hrp.CFrame * CFrame.new(0, 6, 0)
        end
    end
end

local function applyStats(char)
    local hum=char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid",10)
    if not hum or not Plugin.alive or lp.Character~=char then return end
    if _G.ApplySpeed then Plugin.Set(hum,"WalkSpeed",_G.DesiredSpeed,"movement") end
    if _G.ApplyJump then Plugin.Set(hum,"UseJumpPower",true,"movement");Plugin.Set(hum,"JumpPower",_G.DesiredJump,"movement") end
    if InvisibilityActive then InvisibilityActive=false;DisableInvisibility();StandaloneInvisBtn.Text="INVIS: OFF" end
end
Plugin.Connect(lp.CharacterAdded,applyStats)
if lp.Character then task.spawn(applyStats,lp.Character) end

Plugin.Connect(RunService.Stepped,function()
    if lp.Character and lp.Character:FindFirstChild("Humanoid") then
        if _G.AutoCoins then
            lp.Character.Humanoid:ChangeState(11)
            for _, part in pairs(lp.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    part.Velocity = Vector3.zero
                end
            end
        end
    end
end)

task.spawn(function()
    while Plugin.alive do
        local drop = workspace:FindFirstChild("GunDrop", true)
        if _G.GunESPEnabled and drop and not drop:FindFirstChild("ODHAssistGunESP") then
            local bill = Instance.new("BillboardGui", drop)
            bill.Name = "ODHAssistGunESP"
            bill.Size = UDim2.new(0, 120, 0, 60)
            bill.AlwaysOnTop = true
            bill.ExtentsOffset = Vector3.new(0, 2, 0)
            local label = Instance.new("TextLabel", bill)
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Font = "GothamBold"
            label.TextSize = 16
            label.Text = "GUN HERE\n▼"
            label.TextColor3 = Color3.fromRGB(0, 255, 0)
            label.TextStrokeTransparency = 0
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
        elseif not _G.GunESPEnabled and drop then
            local bill = drop:FindFirstChild("ODHAssistGunESP")
            if bill then bill:Destroy() end
        end
        if _G.AutoGrabGun and drop and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            firetouchinterest(lp.Character.HumanoidRootPart, drop, 0)
            firetouchinterest(lp.Character.HumanoidRootPart, drop, 1)
        end
        task.wait(0.1)
    end
end)

local function setKillAura(enabled)
    if killAuraConnection then
        killAuraConnection:Disconnect()
        killAuraConnection = nil
    end
    if enabled then
        killAuraConnection = Plugin.Connect(RunService.Heartbeat,function()
            if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
            local knife = lp.Character:FindFirstChild("Knife")
            if not knife then
                local backpackKnife = lp.Backpack:FindFirstChild("Knife")
                if backpackKnife then
                    lp.Character:FindFirstChild("Humanoid"):EquipTool(backpackKnife)
                    knife = lp.Character:FindFirstChild("Knife")
                end
            end
            if not knife then return end
            local handle = knife:FindFirstChild("Handle")
            if not handle then return end

            local nearest, shortestDist = nil, math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (lp.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        nearest = p
                    end
                end
            end

            if not nearest or not nearest.Character then return end
            local tHRP = nearest.Character:FindFirstChild("HumanoidRootPart")
            local tHum = nearest.Character:FindFirstChild("Humanoid")
            if not tHRP or not tHum or tHum.Health <= 0 then return end

            local range = _G.AuraRange or 7
            if shortestDist > range then return end

            pcall(function()
                firetouchinterest(handle, tHRP, 0)
                firetouchinterest(handle, tHRP, 1)
                if knife:FindFirstChild("Stab") then
                    knife.Stab:FireServer("Slash")
                end
            end)
        end)
    end
end

local function killAll()
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
    local knife = lp.Character:FindFirstChild("Knife") or lp.Backpack:FindFirstChild("Knife")
    if not knife then
        Rayfield:Notify({Title = "Exodus", Content = "No knife found!", Duration = 3})
        return
    end
    if knife.Parent == lp.Backpack then
        lp.Character:FindFirstChild("Humanoid"):EquipTool(knife)
        knife = lp.Character:FindFirstChild("Knife")
    end
    if not knife then return end
    local handle = knife:FindFirstChild("Handle")
    if not handle then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local tHRP = p.Character.HumanoidRootPart
            local tHum = p.Character:FindFirstChild("Humanoid")
            if tHRP and tHum and tHum.Health > 0 then
                pcall(function()
                    firetouchinterest(handle, tHRP, 0)
                    firetouchinterest(handle, tHRP, 1)
                end)
            end
        end
    end

    pcall(function()
        if knife:FindFirstChild("Stab") then
            knife.Stab:FireServer("Slash")
        end
    end)
end

local Window = Rayfield:CreateWindow({
   Name = "ASSISTAIM HUB | Murder Mystery 2 👾",
   LoadingTitle = "by @assistaim",
   Theme = "Purple",
   ConfigurationSaving = {Enabled = true, FolderName = "ExodusConfigs", FileName = "MM2_Final"}
})

local MainTab = Window:CreateTab("Main", 4483362458)
local FlingTab = Window:CreateTab("Fling", 4483362458)
local FarmTab = Window:CreateTab("Auto Farm", 4483362458)
local PlayerTab = Window:CreateTab("Player", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)
local KeybindsTab = Window:CreateTab("Keybinds", 4483362458)

MainTab:CreateSection("Role ESP")
MainTab:CreateToggle({
    Name = "Enable Arrow ESP",
    CurrentValue = false,
    Flag = "ESP_F",
    Callback = function(V) _G.ESPEnabled = V end
})
MainTab:CreateToggle({
    Name = "Gun ESP",
    CurrentValue = false,
    Flag = "GunESP_F",
    Callback = function(V)
        _G.GunESPEnabled = V
    end
})

MainTab:CreateSection("Aim Utilities (Sheriff)")
MainTab:CreateDropdown({
    Name = "Shooting Method",
    Options = {"Normal", "New (blatant)"},
    CurrentOption = {"New (blatant)"},
    MultipleOptions = false,
    Flag = "SMethod",
    Callback = function(Option) _G.ShootingMethod = Option[1] end
})
MainTab:CreateToggle({
    Name = "Wall-Check",
    CurrentValue = false,
    Flag = "WCheck",
    Callback = function(v) _G.SilentAimWallCheck = v end
})
MainTab:CreateToggle({
    Name = "Auto Grab Gun",
    CurrentValue = false,
    Flag = "AGG_F",
    Callback = function(V) _G.AutoGrabGun = V end
})

MainTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Flag = "SilentAim_F",
    Callback = function(v)
        if v then
            if installNamecallHook() then
                _G.SilentAimEnabled = true
                reportAim("Silent aim active: your own shots redirect to the murderer.")
            else
                _G.SilentAimEnabled = false
                local control = Plugin.controls.SilentAim_F
                if control then control:Set(false) end
            end
        else
            _G.SilentAimEnabled = false
            reportAim("Silent aim off.")
        end
    end
})
MainTab:CreateToggle({
    Name = "Auto Shoot Murderer",
    CurrentValue = false,
    Flag = "AutoShoot_F",
    Callback = function(v)
        _G.AutoShootEnabled = v
        if v then
            startAutoShoot()
            reportAim("Auto shoot running: equips the gun and fires at the murderer.")
        else
            reportAim("Auto shoot off.")
        end
    end
})
MainTab:CreateDropdown({
    Name = "Shoot Mode",
    Options = {"Auto (click + remote)", "Game-like click", "Direct remote"},
    CurrentOption = {"Auto (click + remote)"},
    MultipleOptions = false,
    Flag = "ShootMode_F",
    Callback = function(Option) _G.ShootMode = Option[1] end
})
MainTab:CreateButton({
    Name = "Debug: dump aim info to console",
    Callback = function() Plugin.task.spawn(dumpAimInfo) end
})
MainTab:CreateButton({
    Name = "Debug: log my shots to console",
    Callback = function()
        Plugin.task.spawn(function()
            if not installNamecallHook() then return end
            shotLogging = true
            shotLogCount = 0
            reportAim("Shot logging on: shoot once with the gun, then copy the [MM2 Assist][shot] lines from the console.")
            Plugin.Notify("Shot logging on. Shoot once with the gun and copy [MM2 Assist][shot] lines from the console.")
        end)
    end
})
AimStatus = MainTab:CreateParagraph({
    Title = "Aim Status",
    Content = "Idle. Executor hook support: " .. (type(hookmetamethod) == "function" and "yes" or "no") .. "."
})
MainTab:CreateSection("Knife Utilities (Murderer)")
MainTab:CreateToggle({
    Name = "Kill Aura",
    CurrentValue = false,
    Flag = "KillAura_T",
    Callback = function(v)
        _G.KillAuraEnabled = v
        if v and _G.KillAllEnabled then Plugin.controls.KillAll_T:Set(false) end
        setKillAura(v)
    end
})
MainTab:CreateInput({
    Name = "Aura Range",
    PlaceholderText = "Enter Range (e.g. 15)",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local value = tonumber(Text)
        if value then _G.AuraRange = value end
    end,
})
MainTab:CreateToggle({
    Name = "Kill All Players",
    CurrentValue = false,
    Flag = "KillAll_T",
    Callback = function(v)
        _G.KillAllEnabled = v
        if v then
            if _G.KillAuraEnabled then Plugin.controls.KillAura_T:Set(false) end
            local nextAttack=0
            killAllConnection = Plugin.Connect(RunService.Heartbeat,function()
                if not _G.KillAllEnabled then return end
                if os.clock()<nextAttack then return end
                nextAttack=os.clock()+.5
                killAll()
            end)
        else
            if killAllConnection then killAllConnection:Disconnect() end
        end
    end
})
MainTab:CreateButton({
    Name = "Instant Kill All (One-Time)",
    Callback = function() killAll() end
})
MainTab:CreateToggle({
    Name = "Murd Auto-Leap (Hold Knife)",
    CurrentValue = false,
    Flag = "AL_F",
    Callback = function(V) _G.AutoLeap = V end
})

MainTab:CreateSection("UI Settings")
MainTab:CreateToggle({
    Name = "Lock Floating UI",
    CurrentValue = false,
    Flag = "Lock_F",
    Callback = function(V) _G.LockAll = V end
})
MainTab:CreateToggle({
    Name = "Show Gun Button",
    CurrentValue = false,
    Flag = "SGB_F",
    Callback = function(V) GunBtn.Visible = V end
})
MainTab:CreateToggle({
    Name = "Show Shoot Button",
    CurrentValue = false,
    Flag = "SSB_F",
    Callback = function(V) ShootBtn.Visible = V end
})
MainTab:CreateToggle({
    Name = "Show Throw Button",
    CurrentValue = false,
    Flag = "STB_F",
    Callback = function(V) ThrowBtn.Visible = V end
})
MainTab:CreateSection("Invisibility Toggle UI")
MainTab:CreateToggle({
    Name = "Show Standalone Invis Button",
    CurrentValue = false,
    Flag = "SSInvis_F",
    Callback = function(V) StandaloneInvisBtn.Visible = V end
})
MainTab:CreateButton({
    Name = "Reset UI Positions",
    Callback = function()
        ShootBtn.Position = DefaultShootPos
        GunBtn.Position = DefaultGunPos
        ThrowBtn.Position = DefaultThrowPos
        BombBtn.Position = DefaultBombPos
        StandaloneInvisBtn.Position = DefaultStandaloneInvisPos
        Plugin.positions={};Plugin.Save()
    end
})

MainTab:CreateSection("Others")
MainTab:CreateToggle({
    Name = "Show Game Timer",
    CurrentValue = false,
    Flag = "Timer_F",
    Callback = function(V) TimerBox.Visible = V end
})
MainTab:CreateToggle({
    Name = "Show Chance (not working)",
    CurrentValue = false,
    Flag = "Chance_F",
    Callback = function(V) ChanceBox.Visible = V end
})

PlayerTab:CreateInput({
    Name = "Walk Speed",
    PlaceholderText = "16",
    Flag = "WS_F",
    Callback = function(T)
        local s = tonumber(T)
        if s then
            _G.DesiredSpeed = s
            _G.ApplySpeed = true
            if lp.Character and lp.Character:FindFirstChild("Humanoid") then
                Plugin.Set(lp.Character.Humanoid,"WalkSpeed",s,"movement")
            end
        end
    end
})
PlayerTab:CreateInput({
    Name = "Jump Power",
    PlaceholderText = "50",
    Flag = "JP_F",
    Callback = function(T)
        local s = tonumber(T)
        if s then
            _G.DesiredJump = s
            _G.ApplyJump = true
            if lp.Character and lp.Character:FindFirstChild("Humanoid") then
                Plugin.Set(lp.Character.Humanoid,"UseJumpPower",true,"movement")
                Plugin.Set(lp.Character.Humanoid,"JumpPower",s,"movement")
            end
        end
    end
})
PlayerTab:CreateToggle({
    Name = "Speed Glitch (Air Only)",
    CurrentValue = false,
    Callback = function(V) _G.SpeedGlitchEnabled = V end
})
PlayerTab:CreateInput({
    Name = "Glitch Speed",
    PlaceholderText = "40",
    Flag = "SP_F",
    Callback = function(T) _G.SpeedGlitchValue = tonumber(T) or 50 end
})

KeybindsTab:CreateInput({
    Name = "Shoot Keybind",
    PlaceholderText = "Q",
    Flag = "KB_Shoot",
    Callback = function(T)
        local key = string.upper(T)
        pcall(function() _G.BindShoot = Enum.KeyCode[key] end)
    end
})
KeybindsTab:CreateInput({
    Name = "Gun Keybind",
    PlaceholderText = "R",
    Flag = "KB_Gun",
    Callback = function(T)
        local key = string.upper(T)
        pcall(function() _G.BindGun = Enum.KeyCode[key] end)
    end
})
KeybindsTab:CreateInput({
    Name = "Throw Keybind",
    PlaceholderText = "E",
    Flag = "KB_Throw",
    Callback = function(T)
        local key = string.upper(T)
        pcall(function() _G.BindThrow = Enum.KeyCode[key] end)
    end
})

MiscTab:CreateSection("Role Utilities")
MiscTab:CreateToggle({
    Name = "Role Notify",
    CurrentValue = false,
    Flag = "RoleNotify_F",
    Callback = function(V)
        _G.RoleNotify = V
    end,
})

MiscTab:CreateSection("Teleports")
MiscTab:CreateButton({
   Name = "Teleport to Lobby",
   Callback = function()
       TeleportToLobby()
   end,
})

local selectedFlingTarget = nil
local flingDropdown = nil

local function getOtherPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            table.insert(list, p.Name)
        end
    end
    return list
end

FlingTab:CreateSection("Security")
FlingTab:CreateToggle({
    Name = "Anti-Fling",
    CurrentValue = false,
    Flag = "AntiFling_Toggle",
    Callback = function(Value)
        toggleAntiFling(Value)
    end,
})

FlingTab:CreateSection("Target Selection")
flingDropdown = FlingTab:CreateDropdown({
    Name = "Select Target",
    Options = getOtherPlayers(),
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "FlingTarget_Dropdown",
    Callback = function(Option)
        selectedFlingTarget = Option and Option[1] and Players:FindFirstChild(Option[1]) or nil
    end,
})

FlingTab:CreateButton({
    Name = "Fling Selected Target",
    Callback = function()
        if selectedFlingTarget and selectedFlingTarget.Parent then
            executeFling(selectedFlingTarget)
        else
            Rayfield:Notify({
                Title = "Fling Error",
                Content = "No target selected or target left the game!",
                Duration = 3
            })
        end
    end,
})

FlingTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        local players = getOtherPlayers()
        flingDropdown:Refresh(players, {})
        Rayfield:Notify({
            Title = "Fling",
            Content = "Player list refreshed! Found " .. #players .. " players.",
            Duration = 2
        })
    end,
})

FlingTab:CreateSection("Fling by Roles")
FlingTab:CreateButton({
    Name = "Fling Murderer",
    Callback = function()
        executeFling(getMurderer())
    end,
})
FlingTab:CreateButton({
    Name = "Fling Sheriff",
    Callback = function()
        executeFling(getSheriff())
    end,
})

local StatsParagraph = FarmTab:CreateParagraph({
    Title = "Farm Statistics",
    Content = "Coins Collected: 0\nCoins / Hour: 0\nElapsed Time: 00:00"
})

-- // Farm Logic
local IsFarming = false
local FarmingThread = nil
local TimerThread = nil

local function GetMap()
    while Plugin.alive and IsFarming do
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:GetAttribute("MapID") and obj:FindFirstChild("CoinContainer") then
                return obj
            end
        end
        task.wait()
    end
end

local function GetNearestCoin()
    local map = GetMap()
    if not map then return nil end
    
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local closest, minDistance = nil, math.huge
    for _, coin in ipairs(map.CoinContainer:GetChildren()) do
        local visual = coin:FindFirstChild("CoinVisual")
        if visual and not visual:GetAttribute("Collected") then
            local dist = (hrp.Position - coin.Position).Magnitude
            if dist < minDistance then
                closest = coin
                minDistance = dist
            end
        end
    end
    
    return closest
end

local function MoveToCoin(targetCoin)
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not targetCoin then return end
    
    local distance = (hrp.Position - targetCoin.Position).Magnitude
    local tweenTime = distance / 25
    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
    
    -- Anchor root to prevent character physics / walk states from breaking movement
    Plugin.Set(hrp,"Anchored",true,"farm")
    
    local tween = TweenService:Create(hrp, tweenInfo, { CFrame = targetCoin.CFrame })
    _G.CoinTween=tween
    local completed = false
    local conn
    conn = Plugin.Connect(tween.Completed,function()
        completed = true
    end)
    
    tween:Play()
    while not completed and IsFarming and lp.Character==char and hrp.Parent do
        task.wait()
    end
    
    if not IsFarming or lp.Character~=char then
        tween:Cancel()
    end
    
    if conn then conn:Disconnect() end
    if _G.CoinTween==tween then _G.CoinTween=nil end
    Plugin.Restore("farm")
end

local function UpdateStats(coins, cph, timer)
    StatsParagraph:Set({
        Title = "Farm Statistics",
        Content = string.format("Coins Collected: %d\nCoins / Hour: %d\nElapsed Time: %s", coins, cph, timer)
    })
end

local function StartFarming()
    if FarmingThread or TimerThread then return end

    local coinsCollected = 0
    local cph = 0
    local timerStr = "00:00"
    local startTime = os.time()

    TimerThread = task.spawn(function()
        while Plugin.alive and IsFarming do
            local elapsed = os.time() - startTime
            local minutes = string.format("%02d", math.floor(elapsed / 60))
            local seconds = string.format("%02d", elapsed % 60)
            timerStr = minutes .. ":" .. seconds
            
            UpdateStats(coinsCollected, cph, timerStr)
            task.wait(1)
        end
    end)

    FarmingThread = task.spawn(function()
        while Plugin.alive and IsFarming do
            local target = GetNearestCoin()
            if target and lp:GetAttribute("Alive") then
                MoveToCoin(target)

                local visual = target:FindFirstChild("CoinVisual")
                local collectedByUs = false

                if visual and not visual:GetAttribute("Collected") then
                    while visual and not visual:GetAttribute("Collected") and visual.Parent and IsFarming do
                        if not lp:GetAttribute("Alive") then break end
                        
                        local nearest = GetNearestCoin()
                        if nearest and nearest ~= target then
                            break
                        end
                        task.wait()
                    end

                    if not visual or not visual.Parent or visual:GetAttribute("Collected") then
                        collectedByUs = true
                    end
                end

                if collectedByUs then
                    coinsCollected += 1
                end

                local elapsed = os.time() - startTime
                if elapsed > 0 then
                    cph = math.floor((coinsCollected / elapsed) * 3600)
                else
                    cph = 0
                end
                
                UpdateStats(coinsCollected, cph, timerStr)
            else
                task.wait(0.5)
            end
        end
    end)
end

local function StopFarming()
    IsFarming = false
    if _G.CoinTween then _G.CoinTween:Cancel();_G.CoinTween=nil end
    Plugin.Restore("farm")
    if FarmingThread then
        task.cancel(FarmingThread)
        FarmingThread = nil
    end
    if TimerThread then
        task.cancel(TimerThread)
        TimerThread = nil
    end
end

-- // Controls
FarmTab:CreateToggle({
   Name = "Auto Farm Coins",
   CurrentValue = false,
   Flag = "AutoFarmToggle",
   Callback = function(Value)
      IsFarming = Value
      if IsFarming then
          StartFarming()
      else
          StopFarming()
      end
   end,
})

local function makeDraggable(btn,action)
    local position=Plugin.positions[btn.Name]
    if type(position)=="table" and #position==4 then
        local valid=true
        for _,number in ipairs(position) do if type(number)~="number" or number~=number or math.abs(number)>5000 then valid=false end end
        if valid then btn.Position=UDim2.new(math.clamp(position[1],0,1),position[2],math.clamp(position[3],0,1),position[4]) end
    end
    local active,start,origin,moved,suppressUntil
    btn.Active=true
    Plugin.Connect(btn.InputBegan,function(input)
        if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
        active=input;start=input.Position;origin=btn.Position;moved=false;suppressUntil=nil
    end)
    Plugin.Connect(UserInputService.InputChanged,function(input)
        if not active or _G.LockAll then return end
        if input~=active and not (active.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then return end
        local delta=input.Position-start
        if delta.X*delta.X+delta.Y*delta.Y<64 and not moved then return end
        moved=true
        btn.Position=UDim2.new(origin.X.Scale,origin.X.Offset+delta.X,origin.Y.Scale,origin.Y.Offset+delta.Y)
    end)
    Plugin.Connect(UserInputService.InputEnded,function(input)
        if input~=active then return end
        active=nil
        if moved then
            suppressUntil=os.clock()+.25
            local pos=btn.Position
            Plugin.positions[btn.Name]={pos.X.Scale,pos.X.Offset,pos.Y.Scale,pos.Y.Offset};Plugin.Save()
        end
    end)
    Plugin.Connect(btn.Activated,function()
        if moved or (suppressUntil and os.clock()<suppressUntil) then return end
        if action then action() end
    end)
end
makeDraggable(ShootBtn,fireGun)
makeDraggable(ThrowBtn,throwAction)
makeDraggable(GunBtn,grabGunAction)
makeDraggable(BombBtn,deployBomb)
makeDraggable(StandaloneInvisBtn,toggleStandaloneInvis)
Plugin.floating={ShootBtn,GunBtn,ThrowBtn,BombBtn,StandaloneInvisBtn,TimerBox,ChanceBox}
Plugin.HideFloating=function() ScreenGui.Enabled=false;StandaloneInvisGui.Enabled=false end
Plugin.ShowFloating=function() ScreenGui.Enabled=true;StandaloneInvisGui.Enabled=true end
MiscTab:CreateButton({Name="Restore original speed / jump",Callback=function()
    _G.ApplySpeed=false;_G.ApplyJump=false
    Plugin.Restore("movement")
    Plugin.values.WS_F=nil;Plugin.values.JP_F=nil;Plugin.Save()
    for _,key in ipairs({"WS_F","JP_F"}) do
        local control=Plugin.controls[key];if control then control.show("not overridden") end
    end
end})
Plugin.cleanups[#Plugin.cleanups+1]=function()
    InvisibilityActive=false;DisableInvisibility()
    StopFarming()
    if Plugin.flingRestore then Plugin.flingRestore() end
    if layTrack then layTrack:Stop(0) end
end
Rayfield:LoadConfiguration()
