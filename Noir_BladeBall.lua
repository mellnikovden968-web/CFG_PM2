-- V24: adaptive phone/tablet and desktop layouts, orientation and touch fixes.
-- V23 reliability update: non-blocking parry tracking and single-loop manual spam.
-- No measured performance multiplier; requires in-game validation.
-- HOTHX V22: MINI FROSTED WHITE GLASS UI + HOTHX NOTIFICATIONS
-- Dashboard / Visual / World / Player / Settings (the red-marked entries)
-- and their UI controls remain removed. Combat and its backend are kept intact.
-- YouTube-style translucent glass sidebar and panel; click Combat once to open, again to close.
-- Combat launcher plus live FPS / Ping readouts below it, always visible, styled like the reference UI.
-- The gameplay engine above the UI construction section is retained.


  

local Players           = cloneref(game:GetService('Players'))  
local ReplicatedStorage = cloneref(game:GetService('ReplicatedStorage'))  
local UserInputService  = cloneref(game:GetService('UserInputService'))  
local RunService        = cloneref(game:GetService('RunService'))  
local TweenService      = cloneref(game:GetService('TweenService'))  
local Stats             = cloneref(game:GetService('Stats'))  
local Debris            = cloneref(game:GetService('Debris'))  
local CoreGui           = cloneref(game:GetService('CoreGui'))  
local HttpService       = cloneref(game:GetService('HttpService'))  
local Workspace         = cloneref(game:GetService('Workspace'))  
  
local LocalPlayer = Players.LocalPlayer  
local Mouse = LocalPlayer:GetMouse()  
  
if not LocalPlayer.Character then  
    LocalPlayer.CharacterAdded:Wait()  
end  
  
local Alive   = Workspace:FindFirstChild("Alive") or Workspace:WaitForChild("Alive")  
local Runtime = Workspace.Runtime  
  
local function detectMobile()  
    local touch = UserInputService.TouchEnabled  
    local mouse = UserInputService.MouseEnabled  
    local keyboard = UserInputService.KeyboardEnabled  
    if touch and not keyboard then return true end  
    if touch and not mouse then return true end  
    return false  
end  
  
-- Remove notification layers from older runs. Watch for legacy VIREX
-- toasts that an already-running old script may create after this one loads.
local previousNotificationWatcher = rawget(_G, "HOTHXOldNotificationWatchStop")
if type(previousNotificationWatcher) == "function" then
    pcall(previousNotificationWatcher)
end
local legacyNotificationConnections = {}
local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
for _, holder in ipairs({CoreGui, playerGui}) do
    if holder then
        for _, oldName in ipairs({"VIREX_Notifications", "HOTHX_Notifications"}) do
            local stale = holder:FindFirstChild(oldName)
            if stale then pcall(function() stale:Destroy() end) end
        end
        local connection = holder.ChildAdded:Connect(function(child)
            if child.Name == "VIREX_Notifications" then
                task.defer(function()
                    if child and child.Parent then
                        pcall(function() child:Destroy() end)
                    end
                end)
            end
        end)
        table.insert(legacyNotificationConnections, connection)
    end
end
local function stopOldNotificationWatch()
    for _, connection in ipairs(legacyNotificationConnections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(legacyNotificationConnections)
    if rawget(_G, "HOTHXOldNotificationWatchStop") == stopOldNotificationWatch then
        _G.HOTHXOldNotificationWatchStop = nil
    end
end
_G.HOTHXOldNotificationWatchStop = stopOldNotificationWatch

local function Notify(title, content, duration)  
    duration = duration or 2  
    task.spawn(function()  
        pcall(function()  
            local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")  
            local parent = CoreGui  
            if not parent then parent = playerGui end  
            if not parent then return end  
  
            local gui = parent:FindFirstChild("HOTHX_Notifications")  
            if not gui then  
                gui = Instance.new("ScreenGui")  
                gui.Name = "HOTHX_Notifications"  
                gui.ResetOnSpawn = false  
                gui.IgnoreGuiInset = true  
                gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling  
                gui.Parent = parent  
            end  
  
            local holder = gui:FindFirstChild("Holder")  
            if not holder then  
                holder = Instance.new("Frame")  
                holder.Name = "Holder"  
                holder.AnchorPoint = Vector2.new(1, 0)  
                holder.Position = UDim2.new(1, -18, 0, 18)  
                holder.Size = UDim2.fromOffset(286, 0)  
                holder.BackgroundTransparency = 1  
                holder.Parent = gui  
  
                local layout = Instance.new("UIListLayout")  
                layout.Padding = UDim.new(0, 8)  
                layout.HorizontalAlignment = Enum.HorizontalAlignment.Right  
                layout.VerticalAlignment = Enum.VerticalAlignment.Top  
                layout.Parent = holder  
            end  
  
            local frame = Instance.new("Frame")  
            frame.Name = "Notification"  
            frame.Size = UDim2.fromOffset(286, 62)  
            frame.BackgroundColor3 = Color3.fromRGB(231, 236, 241)  
            frame.BackgroundTransparency = 0.26  
            frame.BorderSizePixel = 0  
            frame.ClipsDescendants = true  
            frame.Parent = holder  
  
            local corner = Instance.new("UICorner")  
            corner.CornerRadius = UDim.new(0, 12)  
            corner.Parent = frame  
  
            local gradient = Instance.new("UIGradient")  
            gradient.Color = ColorSequence.new({  
                ColorSequenceKeypoint.new(0, Color3.fromRGB(251, 252, 253)),  
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(225, 231, 237)),  
                ColorSequenceKeypoint.new(1, Color3.fromRGB(185, 196, 206))  
            })  
            gradient.Rotation = 0  
            gradient.Parent = frame  
  
            local stroke = Instance.new("UIStroke")  
            stroke.Color = Color3.fromRGB(254, 254, 255)  
            stroke.Transparency = 0.13  
            stroke.Thickness = 1  
            stroke.Parent = frame  
  
            local titleLabel = Instance.new("TextLabel")  
            titleLabel.BackgroundTransparency = 1  
            titleLabel.Position = UDim2.fromOffset(14, 10)  
            titleLabel.Size = UDim2.new(1, -28, 0, 20)  
            titleLabel.Font = Enum.Font.GothamBold  
            titleLabel.Text = tostring(title)  
            titleLabel.TextColor3 = Color3.fromRGB(34, 45, 57)  
            titleLabel.TextSize = 14  
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left  
            titleLabel.Parent = frame  
  
            local contentLabel = Instance.new("TextLabel")  
            contentLabel.BackgroundTransparency = 1  
            contentLabel.Position = UDim2.fromOffset(14, 32)  
            contentLabel.Size = UDim2.new(1, -28, 0, 30)  
            contentLabel.Font = Enum.Font.Gotham  
            contentLabel.Text = tostring(content)  
            contentLabel.TextColor3 = Color3.fromRGB(72, 84, 97)  
            contentLabel.TextSize = 12  
            contentLabel.TextWrapped = true  
            contentLabel.TextXAlignment = Enum.TextXAlignment.Left  
            contentLabel.TextYAlignment = Enum.TextYAlignment.Top  
            contentLabel.Parent = frame  
  
            frame.Position = UDim2.new(1, 25, 0, 0)  
            TweenService:Create(frame, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {  
                Position = UDim2.new(0, 0, 0, 0)  
            }):Play()  
  
            task.wait(duration)  
            local out = TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {  
                Position = UDim2.new(1, 25, 0, 0),  
                BackgroundTransparency = 1  
            })  
            out:Play()  
            out.Completed:Wait()  
            frame:Destroy()  
        end)  
    end)  
end  
  
local System = {  
    __properties = {  
        __autoparry_enabled = false,  
        __triggerbot_enabled = false,  
        __manual_spam_enabled = false,  
        __auto_spam_enabled = false,  
        __play_animation = false,  
        __accuracy = 50,  
        __divisor_multiplier = 1.1,  
        __parried = false,  
        __training_parried = false,  
        __spam_threshold = 1.5,  
        __parries = 0,  
        __parry_key = nil,  
        __grab_animation = nil,  
        __tornado_time = tick(),  
        __first_parry_done = false,  
        __connections = {},  
        __reverted_remotes = {},  
        __spam_accumulator = 0,  
        __spam_rate = 340,  
        __infinity_active = false,  
        __deathslash_active = false,  
        __timehole_active = false,  
        __slashesoffury_active = false,  
        __slashesoffury_count = 0,  
        __is_mobile = detectMobile(),  
        __mobile_guis = {},  
        __randomized_accuracy_enabled = false,  
        __speed_display_enabled = false,  
        __auto_jump_enabled = false,  
        __ball_speed = 0,  
        __peak_ball_speed = 0,  
        __headless_enabled = false,  
        __korblox_enabled = false,  
        __thunder_dash_enabled = false  
    },  
    __config = {  
        __detections = {  
            __infinity=false,__deathslash=false,  
            __timehole=false,__slashesoffury=false,__phantom=false  
        }  
    },  
    __triggerbot = {  
        __enabled=false,__is_parrying=false,  
        __parries=0,__max_parries=10000,__parry_delay=0.05  
    }  
}  
  
local function update_divisor()  
    System.__properties.__divisor_multiplier = 0.7 + (System.__properties.__accuracy - 1) * (0.9/99)  
end  
  
local function update_randomized_accuracy()  
    if not System.__properties.__randomized_accuracy_enabled then return end  
    local ping_str = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()  
    local ping = tonumber(ping_str:match("%d+")) or 0  
    local new_accuracy  
    if ping >= 90 then new_accuracy = 4  
    elseif ping <= 50 then new_accuracy = math.random(70, 100)  
    else new_accuracy = System.__properties.__accuracy end  
    if new_accuracy then System.__properties.__accuracy = new_accuracy; update_divisor() end  
end  
  
task.spawn(function()  
    while task.wait(1) do  
        if System.__properties.__randomized_accuracy_enabled then update_randomized_accuracy() end  
    end  
end)  
  
local replicated_storage = cloneref(game:GetService('ReplicatedStorage'))  
local workspace = cloneref(game:GetService('Workspace'))  
  
local _token  
local _tokenFound = false  
  
for _, Function in getgc(true) do  
    if type(Function) ~= 'function' or not debug.info(Function, 's'):find('PRY', 1, true) then  
        continue  
    end  
    for _, value in debug.getupvalues(Function) do  
        if type(value) == 'function' then  
            _token = value  
            _tokenFound = true  
            break  
        end  
    end  
    if _token then break end  
end  
  
if not _tokenFound then  
    Notify("HOTHX", "Remote not found! Re-inject vÃ  cháº¡y láº¡i.", 5)  
    return  
end  
  
function _tokenize(_remote_uid)  
    local time = tostring(math.floor(workspace:GetServerTimeNow() * 100))  
    local key = _token(_remote_uid, 'TIME')  
    local characters = table.create(#time)  
    for index = 1, #time do  
        characters[index] = string.char(bit32.bxor(  
            (string.byte(time, index ) + index) % 256,  
            string.byte(key, (index - 1) % #key + 1)  
        ))  
    end  
    return table.concat(characters)  
end  
  
local _reverted = {}  
local _original = {}  
local _captured = nil  
local _capturedRemote = nil  
local _capturedArgs = nil  
  
function _is_valid(args)  
    if not args or #args < 8 then return false end  
    return true  
end  
  
function _hook(remote)  
    if not remote then return end  
    if _reverted[remote] then return end  
    if _original[getrawmetatable(remote)] then return end  
  
    _original[getrawmetatable(remote)] = true  
    local _meta = getrawmetatable(remote)  
    setreadonly(_meta, false)  
  
    local _old = _meta.__index  
    _meta.__index = function(self, key)  
        if (key == 'FireServer' and self:IsA('RemoteEvent')) or  
           (key == 'InvokeServer' and self:IsA('RemoteFunction')) then  
            return function(_, ...)  
                local _arguments = {...}  
                if _is_valid(_arguments) then  
                    if not _reverted[self] then  
                        _reverted[self] = _arguments  
                        _captured = { remote = self, args = _arguments }  
                        _capturedRemote = self  
                        _capturedArgs = _arguments  
                    end  
                end  
                return _old(self, key)(_, unpack(_arguments))  
            end  
        end  
        return _old(self, key)  
    end  
    setreadonly(_meta, true)  
end  
  
for _iterator, _remote in pairs(replicated_storage:GetDescendants()) do  
    if _remote:IsA('RemoteEvent') or _remote:IsA('RemoteFunction') then  
        _hook(_remote)  
    end  
end  
  
task.wait(5)  
  
task.spawn(function()  
    while not _capturedRemote do  
        task.wait(1)  
    end  
    if _capturedRemote then  
        Notify("HOTHX", "Anti-cheat Bypassed", 3)  
    end  
end)  
  
local function fireParryRemote(curveCF)  
    if not _capturedRemote or not _capturedArgs then  
        return false  
    end  
  
    local cam = Workspace.CurrentCamera  
    if not cam then return false end
    local is_mobile = System.__properties.__is_mobile  
    local aim_target  
  
    if is_mobile then  
        local vp = cam.ViewportSize  
        aim_target = {math.floor(vp.X / 2), math.floor(vp.Y / 2)}  
    else  
        local ok, mouse = pcall(function() return UserInputService:GetMouseLocation() end)  
        if ok and mouse then  
            aim_target = {math.floor(mouse.X), math.floor(mouse.Y)}  
        else  
            local vp = cam.ViewportSize  
            aim_target = {math.floor(vp.X / 2), math.floor(vp.Y / 2)}  
        end  
    end  
  
    local event_data = {}  
    if Alive then  
        for _, entity in pairs(Alive:GetChildren()) do  
            if entity.PrimaryPart then  
                local ok, sp = pcall(function() return cam:WorldToScreenPoint(entity.PrimaryPart.Position) end)  
                if ok then event_data[entity.Name] = sp end  
            end  
        end  
    end  
  
    local packet = {  
        _capturedArgs[1],  
        _capturedArgs[2],  
        _tokenize(_capturedArgs[2]),  
        0.5,  
        curveCF or cam.CFrame,  
        event_data,  
        aim_target,  
        false  
    }  
  
    local ok = pcall(function()  
        if _capturedRemote:IsA('RemoteEvent') then  
            _capturedRemote:FireServer(unpack(packet))  
        elseif _capturedRemote:IsA('RemoteFunction') then  
            _capturedRemote:InvokeServer(unpack(packet))  
        end  
    end)  
    return ok  
end  
  
System.animation = {}  
  
local SwordAPI = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SwordAPI")  
local LastPlayedd = 0  
local Sword_CP = false  
local Sword_Spped = 1  
local Grab_Parry = nil  
local AnimFix_Cache = {}  
  
local function GetParryAnimation(swordName)  
    if not swordName or swordName == "" then  
        return SwordAPI.Collection.Default:FindFirstChild("GrabParry")  
    end  
    if AnimFix_Cache[swordName] then return AnimFix_Cache[swordName] end  
    local ok, swordData = pcall(function()  
        return ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(swordName)  
    end)  
    if not ok or not swordData or type(swordData) ~= "table" or not swordData.AnimationType then  
        AnimFix_Cache[swordName] = SwordAPI.Collection.Default:FindFirstChild("GrabParry")  
        return AnimFix_Cache[swordName]  
    end  
    for _, obj in pairs(SwordAPI.Collection:GetChildren()) do  
        if obj.Name == swordData.AnimationType then  
            local anim = obj:FindFirstChild("GrabParry") or obj:FindFirstChild("Grab")  
            if anim then  
                AnimFix_Cache[swordName] = anim  
                return anim  
            end  
        end  
    end  
    AnimFix_Cache[swordName] = SwordAPI.Collection.Default:FindFirstChild("GrabParry")  
    return AnimFix_Cache[swordName]  
end  
  
local function GrabParryPlay(track)  
    if not track then return end  
    pcall(function()  
        track:Play(  
            track:GetAttribute("PlayFadeTime") or 0,  
            track:GetAttribute("PlayWeight") or 1,  
            track:GetAttribute("PlaySpeed") or 1  
        )  
    end)  
end  
  
local function GrabParryStop(track)  
    if not track then return end  
    pcall(function()  
        track:Stop(track:GetAttribute("StopFadeTime") or 0.1)  
    end)  
end  
  
function System.animation.play_grab_parry()  
    if not System.__properties.__play_animation then return end  
    if not ((os.clock() - LastPlayedd) >= (Sword_Spped - 0.8) or Sword_CP) then return end  
    LastPlayedd = os.clock()  
    Sword_CP = false  
    local char = LocalPlayer.Character  
    if not char then return end  
    local humanoid = char:FindFirstChildOfClass("Humanoid")  
    if not humanoid then return end  
    local currentSword  
    if getgenv().skinChanger then  
        currentSword = (getgenv().swordAnimations ~= "" and getgenv().swordAnimations)  
                    or (getgenv().swordModel ~= "" and getgenv().swordModel)  
                    or char:GetAttribute("CurrentlyEquippedSword")  
    else  
        currentSword = char:GetAttribute("CurrentlyEquippedSword")  
    end  
    local animation = GetParryAnimation(currentSword)  
    if not animation then return end  
    for _, track in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do  
        if track.Name == "GrabParry" or track.Name == "Grab" then  
            track.TimePosition = 0  
            GrabParryStop(track)  
        elseif track.Name == "SuccessParry" or track.Name == "Success" then  
            GrabParryStop(track)  
        end  
    end  
    Grab_Parry = humanoid.Animator:LoadAnimation(animation)  
    GrabParryPlay(Grab_Parry)  
end  
  
pcall(function()  
    ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function()  
        Sword_CP = true  
        local char = LocalPlayer.Character  
        if not char then return end  
        local humanoid = char:FindFirstChildOfClass("Humanoid")  
        if not humanoid then return end  
        for _, track in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do  
            if track.Name == "GrabParry" or track.Name == "Grab" then  
                GrabParryStop(track)  
            end  
        end  
    end)  
end)  
  
System.ball = {}  
function System.ball.get()  
    local balls=Workspace:FindFirstChild('Balls'); if not balls then return nil end  
    for _,ball in pairs(balls:GetChildren()) do  
        if ball:GetAttribute('realBall') then ball.CanCollide=false; return ball end  
    end; return nil  
end  
function System.ball.get_all()  
    local balls_table={}; local balls=Workspace:FindFirstChild('Balls')  
    if not balls then return balls_table end  
    for _,ball in pairs(balls:GetChildren()) do  
        if ball:GetAttribute('realBall') then ball.CanCollide=false; table.insert(balls_table,ball) end  
    end; return balls_table  
end  
  
System.player = {}  
local Closest_Entity=nil; local last_closest_check=0  
function System.player.get_closest()  
    local now=tick()  
    if now-last_closest_check < 0.1 then return Closest_Entity end  
    last_closest_check=now  
    local max_distance=math.huge; local closest_entity=nil  
    if not Alive then return nil end  
    for _,entity in pairs(Alive:GetChildren()) do  
        if entity ~= LocalPlayer.Character and entity.PrimaryPart then  
            local distance=LocalPlayer:DistanceFromCharacter(entity.PrimaryPart.Position)  
            if distance < max_distance then max_distance=distance; closest_entity=entity end  
        end  
    end  
    Closest_Entity=closest_entity; return closest_entity  
end  
  
local CURVE_NAMES = {"Camera","Random","Accelerated","Backwards","Slow","High","Normal","Speed","Down","Left","Right"}  
local Selected_Parry_Type = "Camera"  
local CurveType = "Camera"  
  
System.curve = {}  
function System.curve.get_cframe()  
    local Camera = Workspace.CurrentCamera  
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")  
    local root_pos = root and root.Position or Camera.CFrame.Position  
  
    local targetPart  
    do  
        local bestDist = math.huge  
        local mouseLoc = not System.__properties.__is_mobile and UserInputService:GetMouseLocation() or nil  
        if Alive then  
            for _, v in pairs(Alive:GetChildren()) do  
                if v ~= LocalPlayer.Character and v.PrimaryPart then  
                    local screenPos, onScreen = Camera:WorldToScreenPoint(v.PrimaryPart.Position)  
                    if onScreen then  
                        local dist  
                        if mouseLoc then  
                            dist = (Vector2.new(screenPos.X, screenPos.Y) - mouseLoc).Magnitude  
                        else  
                            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)  
                            dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude  
                        end  
                        if dist < bestDist then bestDist = dist; targetPart = v.PrimaryPart end  
                    end  
                end  
            end  
        end  
    end  
    local target_pos = targetPart and targetPart.Position or (root_pos + Camera.CFrame.LookVector * 100)  
  
    local Parry_Type = Selected_Parry_Type  
    local cf  
  
    if Parry_Type == "Camera" then  
        cf = Camera.CFrame  
    elseif Parry_Type == "Random" then  
        local direction = (target_pos - root_pos).Unit  
        local random_offset  
        local attempts = 0  
        repeat  
            random_offset = Vector3.new(math.random(-4000,4000), math.random(-4000,4000), math.random(-4000,4000))  
            local curve_dir = (target_pos + random_offset - root_pos).Unit  
            local dot = direction:Dot(curve_dir)  
            attempts = attempts + 1  
        until dot < 0.95 or attempts > 10  
        cf = CFrame.new(root_pos, target_pos + random_offset)  
    elseif Parry_Type == "Accelerated" then  
        cf = CFrame.new(root_pos, target_pos + Vector3.new(0, 5, 0))  
    elseif Parry_Type == "Backwards" then  
        local direction = (root_pos - target_pos).Unit  
        local backwards_pos = root_pos + direction * 10000 + Vector3.new(0, 1000, 0)  
        cf = CFrame.new(Camera.CFrame.Position, backwards_pos)  
    elseif Parry_Type == "Slow" then  
        cf = CFrame.new(root_pos, target_pos + Vector3.new(0, -9e18, 0))  
    elseif Parry_Type == "High" then  
        cf = CFrame.new(root_pos, target_pos + Vector3.new(0, 9e18, 0))  
    elseif Parry_Type == "Normal" then  
        cf = CFrame.new(root_pos, root_pos + (root and root.CFrame.LookVector or Camera.CFrame.LookVector))  
    elseif Parry_Type == "Speed" then  
        cf = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Camera.CFrame.UpVector * 5)  
    elseif Parry_Type == "Down" then  
        cf = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Camera.CFrame.UpVector * -9e9)  
    elseif Parry_Type == "Left" then  
        cf = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - Camera.CFrame.RightVector * 9e9)  
    elseif Parry_Type == "Right" then  
        cf = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Camera.CFrame.RightVector * 9e9)  
    else  
        cf = Camera.CFrame  
    end  
  
    return cf  
end  
  
System.parry = {}  
function System.parry.execute()  
    if System.__properties.__parries > 10000 or not LocalPlayer.Character then return end  
    if not fireParryRemote(System.curve.get_cframe()) then return false end
    if System.__properties.__parries > 10000 then return false end  
    System.__properties.__parries=System.__properties.__parries+1  
    task.delay(0.5,function() if System.__properties.__parries > 0 then System.__properties.__parries=System.__properties.__parries-1 end end)
    return true
end  
  
function System.parry.keypress()  
    if System.__properties.__parries > 10000 or not LocalPlayer.Character then return end  
    if not fireParryRemote(System.curve.get_cframe()) then return false end
    if System.__properties.__parries > 10000 then return false end  
    System.__properties.__parries=System.__properties.__parries+1  
    task.delay(0.5,function() if System.__properties.__parries > 0 then System.__properties.__parries=System.__properties.__parries-1 end end)
    return true
end  
  
function System.parry.execute_action()  
    local sent = System.parry.execute()
    if sent and System.__properties.__play_animation then System.animation.play_grab_parry() end
    return sent  
end  
  
local function linear_predict(a,b,t) return a+(b-a)*t end  
  
System.detection = {  
    __ball_properties = {__aerodynamic_time=tick(),__last_warping=tick(),__lerp_radians=0,__curving=tick()}  
}  
  
function System.detection.is_curved(selectedBall)  
    local sharedProps=System.detection.__ball_properties
    local ball=selectedBall or System.ball.get(); if not ball then return false end
    System.detection.states = System.detection.states or setmetatable({}, {__mode = "k"})
    local props=System.detection.states[ball]
    if not props then
        props={__last_warping=0, __lerp_radians=0, __curving=0}
        System.detection.states[ball]=props
    end
    props.__curving=sharedProps.__curving  
    local zoomies=ball:FindFirstChild("zoomies"); if not zoomies then return false end  
    local velocity=zoomies.VectorVelocity; local speed=velocity.Magnitude  
    if speed < 1 then return false end  
    local ball_dir=velocity.Unit; local char=LocalPlayer.Character  
    if not char or not char.PrimaryPart then return false end  
    local pos=char.PrimaryPart.Position
    local offset=pos-ball.Position
    if offset.Magnitude < 0.001 then return false end
    local direction=offset.Unit  
    local dot=direction:Dot(ball_dir)  
    local ping=Stats.Network.ServerStatsItem["Data Ping"]:GetValue()/1000  
    local distance=(pos-ball.Position).Magnitude; local reach_time=distance/speed-ping  
    local dot_threshold=math.clamp(0.55-(ping*0.75),-1,0.45)  
    local speed_threshold=math.min(speed/100,45)  
    local ball_distance_threshold=15-math.min(distance/1000,15)+speed_threshold  
    local clamped_dot=math.clamp(dot,-1,1); local radians=math.asin(clamped_dot)  
    props.__lerp_radians=linear_predict(props.__lerp_radians,radians,0.85)  
    if props.__lerp_radians < 0.016 then props.__last_warping=tick() end  
    if distance < (ball_distance_threshold*0.85) then return false end  
    if (tick()-props.__last_warping) < (reach_time/1.4) then return true end  
    if (tick()-props.__curving) < (reach_time/1.1) then return true end  
    return dot < dot_threshold  
end  
  
ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(c,d)  
    System.__properties.__deathslash_active = d or false  
end)  
ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a,b)  
    System.__properties.__infinity_active = b or false  
end)  
  
ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/TimeHoleActivate"].OnClientEvent:Connect(function(...)  
    local args={...}; local player=args[1]  
    if player==LocalPlayer or player==LocalPlayer.Name or (player and player.Name==LocalPlayer.Name) then  
        System.__properties.__timehole_active=true  
    end  
end)  
ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/TimeHoleDeactivate"].OnClientEvent:Connect(function()  
    System.__properties.__timehole_active=false  
end)  
  
local maxParryCount=36; local parryDelay=0.05  
  
ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/SlashesOfFuryActivate"].OnClientEvent:Connect(function(...)  
    local args={...}; local player=args[1]  
    if player==LocalPlayer or player==LocalPlayer.Name or (player and player.Name==LocalPlayer.Name) then  
        System.__properties.__slashesoffury_active=true; System.__properties.__slashesoffury_count=0  
    end  
end)  
ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/SlashesOfFuryEnd"].OnClientEvent:Connect(function()  
    System.__properties.__slashesoffury_active=false; System.__properties.__slashesoffury_count=0  
end)  
ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/SlashesOfFuryParry"].OnClientEvent:Connect(function()  
    System.__properties.__slashesoffury_count=System.__properties.__slashesoffury_count+1  
end)  
ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/SlashesOfFuryCatch"].OnClientEvent:Connect(function()  
    spawn(function()  
        while System.__properties.__slashesoffury_active and System.__properties.__slashesoffury_count < maxParryCount do  
            if System.__config.__detections.__slashesoffury then System.parry.execute(); task.wait(parryDelay)  
            else break end  
        end  
    end)  
end)  
  
Runtime.ChildAdded:Connect(function(Object)  
    if System.__config.__detections.__phantom then  
        if Object.Name=="maxTransmission" or Object.Name=="transmissionpart" then  
            local Weld=Object:FindFirstChildWhichIsA("WeldConstraint")  
            if Weld then  
                local Character=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()  
                if Character and Weld.Part1==Character.HumanoidRootPart then  
                    local CurrentBall=System.ball.get(); Weld:Destroy()  
                    if CurrentBall then  
                        local FocusConnection  
                        FocusConnection=RunService.RenderStepped:Connect(function()  
                            local Highlighted=CurrentBall:GetAttribute("highlighted")  
                            if Highlighted==true then  
                                ReplicatedStorage.Remotes.AbilityButtonPress:Fire()  
                                System.__properties.__parried=true  
                                task.delay(1,function() System.__properties.__parried=false end)  
                            elseif Highlighted==false then FocusConnection:Disconnect() end  
                        end)  
                        task.delay(3,function() if FocusConnection and FocusConnection.Connected then FocusConnection:Disconnect() end end)  
                    end  
                end  
            end  
        end  
    end  
end)  
  
ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(_,root)  
    if root.Parent and root.Parent ~= LocalPlayer.Character then  
        if not Alive or root.Parent.Parent ~= Alive then return end  
    end  
    local closest=System.player.get_closest(); local ball=System.ball.get()  
    if not ball or not closest then return end  
    local target_distance=(LocalPlayer.Character.PrimaryPart.Position-closest.PrimaryPart.Position).Magnitude  
    local distance=(LocalPlayer.Character.PrimaryPart.Position-ball.Position).Magnitude  
    local direction=(LocalPlayer.Character.PrimaryPart.Position-ball.Position).Unit  
    local dot=direction:Dot(ball.AssemblyLinearVelocity.Unit)  
    local curve_detected=System.detection.is_curved()  
    if target_distance < 15 and distance < 15 and dot > -0.25 then  
        if curve_detected then System.parry.execute_action() end  
    end  
    if System.__properties.__grab_animation then System.__properties.__grab_animation:Stop() end  
end)  
  
ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()  
    if not Alive or LocalPlayer.Character.Parent ~= Alive then return end  
    if System.__properties.__grab_animation then System.__properties.__grab_animation:Stop() end  
end)  
  
ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(a,b)  
    local Primary_Part=LocalPlayer.Character.PrimaryPart  
    local Ball=System.ball.get(); if not Ball then return end  
    local Zoomies=Ball:FindFirstChild('zoomies'); if not Zoomies then return end  
    local Speed=Zoomies.VectorVelocity.Magnitude  
    local Distance=(LocalPlayer.Character.PrimaryPart.Position-Ball.Position).Magnitude  
    local Velocity=Zoomies.VectorVelocity; local Ball_Direction=Velocity.Unit  
    local Direction=(LocalPlayer.Character.PrimaryPart.Position-Ball.Position).Unit  
    local Dot=Direction:Dot(Ball_Direction)  
    local Pings=Stats.Network.ServerStatsItem['Data Ping']:GetValue()  
    local Speed_Threshold=math.min(Speed/100,40)  
    local Reach_Time=Distance/Speed-(Pings/1000)  
    local Enough_Speed=Speed > 1  
    local Ball_Distance_Threshold=15-math.min(Distance/1000,15)+Speed_Threshold  
    if Enough_Speed and Reach_Time > Pings/10 then  
        Ball_Distance_Threshold=math.max(Ball_Distance_Threshold-15,15)  
    end  
    if b ~= Primary_Part and Distance > Ball_Distance_Threshold then  
        System.detection.__ball_properties.__curving=tick()  
    end  
end)  
  
System.triggerbot = {}  
local triggerbotCooldown = false  
  
function System.triggerbot.trigger(ball)  
    if triggerbotCooldown then return end  
    if System.__triggerbot.__is_parrying then return end  
    if System.__triggerbot.__parries > System.__triggerbot.__max_parries then return end  
    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and  
       LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape') then return end  
  
    triggerbotCooldown = true  
    System.__triggerbot.__is_parrying=true  
    System.__triggerbot.__parries=System.__triggerbot.__parries+1  
  
    System.parry.execute()  
  
    if System.__properties.__play_animation then  
        System.animation.play_grab_parry()  
    end  
  
    task.delay(0.2,function()  
        triggerbotCooldown = false  
        if System.__triggerbot.__parries > 0 then  
            System.__triggerbot.__parries=System.__triggerbot.__parries-1  
        end  
    end)  
  
    task.spawn(function()  
        local start_time=tick()  
        repeat RunService.Heartbeat:Wait()  
        until (tick()-start_time >= 0.15 or not System.__triggerbot.__is_parrying)  
        System.__triggerbot.__is_parrying=false  
    end)  
end  
  
function System.triggerbot.loop()  
    if not System.__triggerbot.__enabled then return end  
    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and  
       LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape') then return end  
    local balls=Workspace:FindFirstChild('Balls'); if not balls then return end  
    for _,ball in pairs(balls:GetChildren()) do  
        if ball:IsA('BasePart') and ball:GetAttribute('target')==LocalPlayer.Name then  
            System.triggerbot.trigger(ball)  
            break  
        end  
    end  
end  
  
function System.triggerbot.enable(enabled)  
    System.__triggerbot.__enabled=enabled  
    if enabled then  
        if not System.__properties.__connections.__triggerbot then  
            System.__properties.__connections.__triggerbot=RunService.Heartbeat:Connect(System.triggerbot.loop)  
        end  
    else  
        if System.__properties.__connections.__triggerbot then  
            System.__properties.__connections.__triggerbot:Disconnect()  
            System.__properties.__connections.__triggerbot=nil  
        end  
        System.__triggerbot.__is_parrying=false  
        System.__triggerbot.__parries=0  
        triggerbotCooldown = false  
    end  
end  
  
System.manual_spam = {}  
local manualSpamThread=nil  
local macroSpamActive=false  
local macroFrameFireCount=0; local macroFrameTime=0; local macroRealCPS=0; local macroAnimFix=true  
  
function System.manual_spam.start()
    System.manual_spam.stop()
    System.__properties.__manual_spam_enabled = true
    macroSpamActive = true
    System.manual_spam.nextFire, System.manual_spam.nextAnimation = 0, 0
    macroRealCPS, macroFrameFireCount, macroFrameTime = 0, 0, 0
end

function System.manual_spam.stop()
    System.__properties.__manual_spam_enabled = false
    macroSpamActive = false
    manualSpamThread = nil
    macroRealCPS, macroFrameFireCount, macroFrameTime = 0, 0, 0
end

-- One scheduler; no coroutine plus Heartbeat double-send.
System.__properties.__connections.__manual_spam = RunService.Heartbeat:Connect(function(dt)
    macroFrameTime = macroFrameTime + dt
    if macroSpamActive and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
        local now = os.clock()
        if now >= (System.manual_spam.nextFire or 0) then
            System.manual_spam.nextFire = now + 1 / 60
            local sent
            if getgenv().ManualSpamMode == "Keypress" then
                sent = System.parry.keypress()
            else
                sent = System.parry.execute()
            end
            if sent then
                macroFrameFireCount = macroFrameFireCount + 1
                if getgenv().ManualSpamAnimationFix and now >= (System.manual_spam.nextAnimation or 0) then
                    System.manual_spam.nextAnimation = now + 0.1
                    System.animation.play_grab_parry()
                end
            end
        end
    end
    if macroFrameTime >= 0.25 then
        macroRealCPS = macroSpamActive and math.floor(macroFrameFireCount / macroFrameTime + 0.5) or 0
        macroFrameFireCount, macroFrameTime = 0, 0
    end
end)

System.auto_spam = {}  
  
function System.auto_spam:get_entity_properties()  
    System.player.get_closest()  
    if not Closest_Entity or not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart or not Closest_Entity.PrimaryPart then return false end  
    local entity_velocity = Closest_Entity.PrimaryPart.AssemblyLinearVelocity  
    local entity_direction = (LocalPlayer.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Unit  
    local entity_distance = (LocalPlayer.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude  
    return {Velocity = entity_velocity, Direction = entity_direction, Distance = entity_distance}  
end  
  
function System.auto_spam:get_ball_properties()  
    local ball = System.ball.get()  
    if not ball or not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return false end  
    local zoomies = ball:FindFirstChild("zoomies")
    local ball_velocity = zoomies and zoomies.VectorVelocity or ball.AssemblyLinearVelocity  
    local ball_direction = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit  
    local ball_distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude  
    local ball_dot = ball_velocity.Magnitude > 0 and ball_direction:Dot(ball_velocity.Unit) or 0  
    return {Velocity = ball_velocity, Direction = ball_direction, Distance = ball_distance, Dot = ball_dot}  
end  
  
function System.auto_spam.spam_service(self)  
    local ball = System.ball.get()  
    local entity = System.player.get_closest()  
    if not ball or not entity or not entity.PrimaryPart or not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return 0 end  
    local zoomies = ball:FindFirstChild("zoomies")
    local velocity = zoomies and zoomies.VectorVelocity or ball.AssemblyLinearVelocity  
    local speed = velocity.Magnitude  
    local direction = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit  
    local dot = speed > 0 and direction:Dot(velocity.Unit) or 0  
    local target_distance = LocalPlayer:DistanceFromCharacter(entity.PrimaryPart.Position)  
    local maximum_spam_distance = self.Ping + math.min(speed / 6, 255)  
    if self.Entity_Properties.Distance > maximum_spam_distance or self.Ball_Properties.Distance > maximum_spam_distance or target_distance > maximum_spam_distance then return 0 end  
    local maximum_speed = 5 - math.min(speed / 5, 5)  
    local maximum_dot = math.clamp(dot, -1, 0) * maximum_speed  
    return maximum_spam_distance - maximum_dot  
end  
  
function System.auto_spam.start()  
    if System.__properties.__connections.__auto_spam then  
        System.__properties.__connections.__auto_spam:Disconnect()  
    end  
    System.__properties.__auto_spam_enabled = true
    System.auto_spam.nextFire, System.auto_spam.nextAnimation = 0, 0
    System.__properties.__connections.__auto_spam = RunService.PreSimulation:Connect(function()  
        if not System.__properties.__auto_spam_enabled then return end
        if os.clock() < (System.auto_spam.nextFire or 0) then return end  
        local ball = System.ball.get()  
        if not ball or System.__properties.__slashesoffury_active then return end  
        local zoomies = ball:FindFirstChild("zoomies")  
        if not zoomies then return end  
        System.player.get_closest()  
        local ball_properties = System.auto_spam:get_ball_properties()  
        local entity_properties = System.auto_spam:get_entity_properties()  
        if not ball_properties or not entity_properties or not Closest_Entity or not Closest_Entity.PrimaryPart then return end  
        local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()  
        local ping_threshold = math.clamp(ping / 10, 1, 16)  
        local spam_accuracy = System.auto_spam.spam_service({  
            Ball_Properties = ball_properties,  
            Entity_Properties = entity_properties,  
            Ping = ping_threshold  
        })  
        local target_distance = LocalPlayer:DistanceFromCharacter(Closest_Entity.PrimaryPart.Position)  
        local direction = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit  
        local ball_direction = zoomies.VectorVelocity.Magnitude > 0 and zoomies.VectorVelocity.Unit or Vector3.zero  
        local dot = ball_direction.Magnitude > 0 and direction:Dot(ball_direction) or 0  
        local distance = LocalPlayer:DistanceFromCharacter(ball.Position)  
        local ball_target = ball:GetAttribute("target")  
        if not ball_target or target_distance > spam_accuracy or distance > spam_accuracy then return end  
        if LocalPlayer.Character:GetAttribute("Pulsed") then return end  
        if ball_target == LocalPlayer.Name and target_distance > 30 and distance > 30 then return end  
        if distance <= spam_accuracy and System.__properties.__parries > System.__properties.__spam_threshold then
            System.auto_spam.nextFire = os.clock() + 1 / 60  
            if getgenv().AutoSpamMode == "Keypress" then  
                System.parry.keypress()  
            else  
                System.parry.execute()  
                if getgenv().AutoSpamAnimationFix and os.clock() >= (System.auto_spam.nextAnimation or 0) then
                    System.auto_spam.nextAnimation = os.clock() + 0.1
                    System.animation.play_grab_parry()
                end  
            end  
        end  
    end)  
end  
  
function System.auto_spam.stop()  
    System.__properties.__auto_spam_enabled = false  
    if System.__properties.__connections.__auto_spam then  
        System.__properties.__connections.__auto_spam:Disconnect()  
        System.__properties.__connections.__auto_spam = nil  
    end  
end  
  
System.autoparry = {states = setmetatable({}, {__mode = "k"})}
function System.autoparry.state(ball)
    local state = System.autoparry.states[ball]
    local target = ball:GetAttribute("target")
    if not state then
        state = {target = target, readyAt = 0}
        System.autoparry.states[ball] = state
    elseif state.target ~= target then
        state.target, state.readyAt = target, 0
    end
    return state
end  
function System.autoparry.start()  
    if System.__properties.__connections.__autoparry then  
        System.__properties.__connections.__autoparry:Disconnect()  
    end  
    System.autoparry.states = setmetatable({}, {__mode = "k"})
    System.__properties.__connections.__autoparry=RunService.PreSimulation:Connect(function()  
        if not System.__properties.__autoparry_enabled or not LocalPlayer.Character or  
           not LocalPlayer.Character.PrimaryPart then return end  
        if System.autoparry.character ~= LocalPlayer.Character then
            System.autoparry.character = LocalPlayer.Character
            System.autoparry.states = setmetatable({}, {__mode = "k"})
        end
        local balls=System.ball.get_all()  
        local training_ball=nil  
        if Workspace:FindFirstChild("TrainingBalls") then  
            for _,Instance in pairs(Workspace.TrainingBalls:GetChildren()) do  
                if Instance:GetAttribute("realBall") then training_ball=Instance; break end  
            end  
        end  
        for _,ball in pairs(balls) do  
            if System.__triggerbot.__enabled then return end  
            if getgenv().BallVelocityAbove800 then return end  
            if not ball then continue end  
            local zoomies=ball:FindFirstChild('zoomies'); if not zoomies then continue end  
            local state = System.autoparry.state(ball)
            if os.clock() < state.readyAt then continue end  
            local ball_target=ball:GetAttribute('target')  
            local velocity=zoomies.VectorVelocity  
            local distance=(LocalPlayer.Character.PrimaryPart.Position-ball.Position).Magnitude  
            local ping=Stats.Network.ServerStatsItem['Data Ping']:GetValue()/10  
            local ping_threshold=math.clamp(ping/10,5,17); local speed=velocity.Magnitude  
            local capped_speed_diff=math.min(math.max(speed-9.5,0),650)  
            local speed_divisor=(2.4+capped_speed_diff*0.002)*System.__properties.__divisor_multiplier  
            local parry_accuracy=ping_threshold+math.max(speed/speed_divisor,9.5)  
            local curved=System.detection.is_curved(ball)  
            if ball:FindFirstChild('AeroDynamicSlashVFX') then  
                ball.AeroDynamicSlashVFX:Destroy(); System.__properties.__tornado_time=tick()  
            end  
            if Runtime:FindFirstChild('Tornado') then  
                if (tick()-System.__properties.__tornado_time) <  
                   (Runtime.Tornado:GetAttribute('TornadoTime') or 1)+0.314159 then continue end  
            end  
            if ball_target==LocalPlayer.Name and curved then continue end  
            if ball:FindFirstChild('ComboCounter') then continue end  
            if LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape') then continue end  
            if System.__config.__detections.__infinity and System.__properties.__infinity_active then continue end  
            if System.__config.__detections.__deathslash and System.__properties.__deathslash_active then continue end  
            if System.__config.__detections.__timehole and System.__properties.__timehole_active then continue end  
            if System.__config.__detections.__slashesoffury and System.__properties.__slashesoffury_active then continue end  
            if ball_target==LocalPlayer.Name and distance <= parry_accuracy then  
                if getgenv().AutoAbility then  
                    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                    local hotbar = playerGui and playerGui:FindFirstChild("Hotbar")
                    local ability = hotbar and hotbar:FindFirstChild("Ability")
                    local AbilityCD = ability and ability:FindFirstChild("UIGradient")  
                    if AbilityCD and AbilityCD.Offset.Y==0.5 then  
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Abilities") then  
                            local abilities=LocalPlayer.Character.Abilities  
                            if (abilities:FindFirstChild("Raging Deflection") and abilities["Raging Deflection"].Enabled) or  
                               (abilities:FindFirstChild("Rapture") and abilities["Rapture"].Enabled) or  
                               (abilities:FindFirstChild("Calming Deflection") and abilities["Calming Deflection"].Enabled) or  
                               (abilities:FindFirstChild("Aerodynamic Slash") and abilities["Aerodynamic Slash"].Enabled) or  
                               (abilities:FindFirstChild("Fracture") and abilities["Fracture"].Enabled) or  
                               (abilities:FindFirstChild("Death Slash") and abilities["Death Slash"].Enabled) then  
                                ReplicatedStorage.Remotes.AbilityButtonPress:Fire()  
                                state.readyAt = os.clock() + 2.432
                                local character = LocalPlayer.Character
                                task.delay(2.432, function()
                                    if not System.__properties.__autoparry_enabled or LocalPlayer.Character ~= character then return end
                                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                                    local activation = remotes and remotes:FindFirstChild("DeathSlashShootActivation")
                                    if activation then activation:FireServer(true) end
                                end)  
                                continue  
                            end  
                        end  
                    end  
                end  
            end  
            if ball_target==LocalPlayer.Name and distance <= parry_accuracy then
                local sent
                if getgenv().AutoParryMode=="Keypress" then sent = System.parry.keypress()
                else sent = System.parry.execute_action() end
                if sent then state.readyAt = os.clock() + 1 end
            end
        end  
        if training_ball then  
            local zoomies=training_ball:FindFirstChild('zoomies')  
            if zoomies then  
                local state = System.autoparry.state(training_ball)
                if os.clock() >= state.readyAt then  
                    local ball_target=training_ball:GetAttribute('target')  
                    local velocity=zoomies.VectorVelocity  
                    local distance=LocalPlayer:DistanceFromCharacter(training_ball.Position)  
                    local speed=velocity.Magnitude  
                    local ping=Stats.Network.ServerStatsItem['Data Ping']:GetValue()/10  
                    local ping_threshold=math.clamp(ping/10,5,17)  
                    local capped_speed_diff=math.min(math.max(speed-9.5,0),650)  
                    local speed_divisor=(2.4+capped_speed_diff*0.002)*System.__properties.__divisor_multiplier  
                    local parry_accuracy=ping_threshold+math.max(speed/speed_divisor,9.5)  
                    if ball_target==LocalPlayer.Name and distance <= parry_accuracy then  
                        local sent
                        if getgenv().AutoParryMode=="Keypress" then sent = System.parry.keypress()
                        else sent = System.parry.execute_action() end
                        if sent then state.readyAt = os.clock() + 1 end
                    end  
                end  
            end  
        end  
    end)  
end  
  
function System.autoparry.stop()  
    if System.__properties.__connections.__autoparry then  
        System.__properties.__connections.__autoparry:Disconnect()  
        System.__properties.__connections.__autoparry=nil  
    end  
end  
  
local ManualSpamGui = nil  
local ManualSpamConnections = {}  
local TriggerGui = nil  
local TriggerConnections = {}  
local CurveGui = nil  
local CurveConnections = {}  
local KeyboardGui = nil  
local KeyboardConnections = {}  
local KeyboardKeyConnections = {}  
local KeyboardCapture = nil  
local KeyboardCaptureConsumed = false  
  
local KeyboardSettings = {  
    AutoParry = Enum.KeyCode.T,  
    AutoSpam = Enum.KeyCode.V,  
    ManualSpam = Enum.KeyCode.F,  
    ManualSpamMode = "Hold to Spam"  
}  
  
local function keyName(keyCode)  
    return keyCode == Enum.KeyCode.Unknown and "None" or keyCode.Name  
end  
  
local function isKeyboardInput(input)  
    return input.UserInputType == Enum.UserInputType.Keyboard  
        and input.KeyCode ~= Enum.KeyCode.Unknown  
end  
  
local function stopManualKeyboardSpam()  
    if KeyboardSettings.ManualSpamMode == "Hold to Spam" and System.__properties.__manual_spam_enabled then  
        _G.manualSpamEnabled = false  
        if _G.VIREX then _G.VIREX.manualSpamEnabled = false end  
        System.manual_spam.stop()  
        macroSpamActive = false  
    end  
end  
  
local function toggleManualKeyboardSpam()  
    local state = not System.__properties.__manual_spam_enabled  
    _G.manualSpamEnabled = state  
    _G.VIREX = _G.VIREX or {}  
    _G.VIREX.manualSpamEnabled = state  
    System.__properties.__manual_spam_enabled = state  
    macroSpamActive = state  
    if state then  
        System.manual_spam.start()  
    else  
        System.manual_spam.stop()  
    end  
end  
  
local function SetKeyboardKey(name, keyCode)  
    KeyboardSettings[name] = keyCode  
end  
  
local DisconnectConnections  
  
local function CreateKeyboardUI()  
    if KeyboardGui and KeyboardGui.Parent then  
        KeyboardGui.Enabled = true  
        return  
    end  
  
    local gui = Instance.new("ScreenGui")  
    gui.Name = "VIREX_KeyboardUI"  
    gui.ResetOnSpawn = false  
    gui.IgnoreGuiInset = true  
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling  
    gui.Parent = CoreGui  
    KeyboardGui = gui  
  
    local Main = Instance.new("Frame")  
    Main.Name = "Keyboard"  
    Main.Size = UDim2.fromOffset(260, 126)  
    Main.Position = UDim2.new(0.5, -130, 0.5, -63)  
    Main.BackgroundColor3 = Color3.fromRGB(228,234,239)
    Main.BackgroundTransparency = 0.28  
    Main.BorderSizePixel = 0  
    Main.Active = true  
    Main.ZIndex = 2500  
    Main.Parent = gui  
  
    local Corner = Instance.new("UICorner")  
    Corner.CornerRadius = UDim.new(0, 13)  
    Corner.Parent = Main  
  
    local Stroke = Instance.new("UIStroke")  
    Stroke.Thickness = 1.5  
    Stroke.Color = Color3.fromRGB(255,255,255)  
    Stroke.Transparency = 0.25  
    Stroke.Parent = Main  
  
    local Title = Instance.new("TextLabel")  
    Title.Size = UDim2.new(1, -20, 0, 32)  
    Title.Position = UDim2.fromOffset(10, 5)  
    Title.BackgroundTransparency = 1  
    Title.Text = "Keyboard"  
    Title.TextColor3 = Color3.fromRGB(37,49,61)  
    Title.TextSize = 15  
    Title.Font = Enum.Font.GothamBold  
    Title.TextXAlignment = Enum.TextXAlignment.Center  
    Title.ZIndex = 2502  
    Title.Parent = Main  
  
    local Divider = Instance.new("Frame")  
    Divider.Size = UDim2.new(1, 0, 0, 1)  
    Divider.Position = UDim2.fromOffset(0, 40)  
    Divider.BackgroundColor3 = Color3.fromRGB(169,181,192)  
    Divider.BorderSizePixel = 0  
    Divider.ZIndex = 2501  
    Divider.Parent = Main  
  
    local Rows = Instance.new("Frame")  
    Rows.Size = UDim2.new(1, -20, 0, 76)  
    Rows.Position = UDim2.fromOffset(10, 47)  
    Rows.BackgroundTransparency = 1  
    Rows.ZIndex = 2502  
    Rows.Parent = Main  
  
    local layout = Instance.new("UIListLayout")  
    layout.Padding = UDim.new(0, 4)  
    layout.FillDirection = Enum.FillDirection.Vertical  
    layout.Parent = Rows  
  
    local modeOpen = false  
    local modePanel = Instance.new("Frame")  
    modePanel.Size = UDim2.new(1, -20, 0, 46)  
    modePanel.Position = UDim2.fromOffset(10, 123)  
    modePanel.BackgroundColor3 = Color3.fromRGB(225,231,237)  
    modePanel.BorderSizePixel = 0  
    modePanel.Visible = false  
    modePanel.ZIndex = 2510  
    modePanel.Parent = Main  
  
    local modeCorner = Instance.new("UICorner")  
    modeCorner.CornerRadius = UDim.new(0, 9)  
    modeCorner.Parent = modePanel  
  
    local modeStroke = Instance.new("UIStroke")  
    modeStroke.Thickness = 1  
    modeStroke.Color = Color3.fromRGB(240,244,247)  
    modeStroke.Parent = modePanel  
  
    local function makeButton(parent, textValue, widthScale, xScale)  
        local button = Instance.new("TextButton")  
        button.Size = UDim2.new(widthScale, -4, 1, 0)  
        button.Position = UDim2.new(xScale, 2, 0, 0)  
        button.BackgroundColor3 = Color3.fromRGB(205,215,224)  
        button.BorderSizePixel = 0  
        button.Text = textValue  
        button.TextColor3 = Color3.fromRGB(37,49,61)  
        button.TextSize = 12  
        button.Font = Enum.Font.GothamSemibold  
        button.AutoButtonColor = false  
        button.ZIndex = 2512  
        button.Parent = parent  
        local c = Instance.new("UICorner")  
        c.CornerRadius = UDim.new(0, 7)  
        c.Parent = button  
        local st = Instance.new("UIStroke")  
        st.Thickness = 1  
        st.Color = Color3.fromRGB(240,244,247)  
        st.Parent = button  
        return button  
    end  
  
    local function makeRow(label, settingName)  
        local row = Instance.new("Frame")  
        row.Size = UDim2.new(1, 0, 0, 22)  
        row.BackgroundTransparency = 1  
        row.ZIndex = 2503  
        row.Parent = Rows  
  
        local text = Instance.new("TextLabel")  
        text.Size = UDim2.new(0.58, 0, 1, 0)  
        text.BackgroundTransparency = 1  
        text.Text = label  
        text.TextColor3 = Color3.fromRGB(40,51,62)  
        text.TextSize = 13  
        text.Font = Enum.Font.GothamMedium  
        text.TextXAlignment = Enum.TextXAlignment.Left  
        text.ZIndex = 2504  
        text.Parent = row  
  
        local button = makeButton(row, keyName(KeyboardSettings[settingName]), 0.42, 0.58)  
        return button  
    end  
  
    local autoParryButton = makeRow("Auto Parry", "AutoParry")  
    local autoSpamButton = makeRow("Auto Spam", "AutoSpam")  
  
    local manualRow = Instance.new("Frame")  
    manualRow.Size = UDim2.new(1, 0, 0, 22)  
    manualRow.BackgroundTransparency = 1  
    manualRow.ZIndex = 2503  
    manualRow.Parent = Rows  
  
    local manualText = Instance.new("TextLabel")  
    manualText.Size = UDim2.new(0.34, 0, 1, 0)  
    manualText.BackgroundTransparency = 1  
    manualText.Text = "Manual Spam"  
    manualText.TextColor3 = Color3.fromRGB(40,51,62)  
    manualText.TextSize = 13  
    manualText.Font = Enum.Font.GothamMedium  
    manualText.TextXAlignment = Enum.TextXAlignment.Left  
    manualText.ZIndex = 2504  
    manualText.Parent = manualRow  
  
    local manualKeyButton = makeButton(manualRow, keyName(KeyboardSettings.ManualSpam), 0.28, 0.34)  
    local manualModeButton = makeButton(manualRow, KeyboardSettings.ManualSpamMode, 0.38, 0.62)  
  
    local function animateMode(open)  
        modeOpen = open  
        if open then  
            modePanel.Visible = true  
            modePanel.Size = UDim2.new(1, -20, 0, 0)  
            modePanel.Position = UDim2.fromOffset(10, 123)  
            TweenService:Create(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {  
                Size = UDim2.fromOffset(260, 180)  
            }):Play()  
            TweenService:Create(modePanel, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {  
                Size = UDim2.new(1, -20, 0, 46)  
            }):Play()  
        else  
            local tween = TweenService:Create(modePanel, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {  
                Size = UDim2.new(1, -20, 0, 0)  
            })  
            tween:Play()  
            TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {  
                Size = UDim2.fromOffset(260, 126)  
            }):Play()  
            tween.Completed:Connect(function()  
                if not modeOpen then modePanel.Visible = false end  
            end)  
        end  
    end  
  
    local holdOption = makeButton(modePanel, "Hold to Spam", 0.5, 0)  
    local onceOption = makeButton(modePanel, "Press Once to Spam", 0.5, 0.5)  
  
    local function selectMode(mode)  
        KeyboardSettings.ManualSpamMode = mode  
        manualModeButton.Text = mode  
        animateMode(false)  
    end  
  
    manualModeButton.MouseButton1Click:Connect(function()  
        animateMode(not modeOpen)  
    end)  
    holdOption.MouseButton1Click:Connect(function()  
        selectMode("Hold to Spam")  
    end)  
    onceOption.MouseButton1Click:Connect(function()  
        selectMode("Press Once to Spam")  
    end)  
  
    local function beginKeyCapture(settingName, button)  
        if KeyboardCapture then return end  
        KeyboardCapture = settingName  
        button.Text = "Press a key..."  
        task.spawn(function()  
            local timeout = os.clock() + 8  
            while KeyboardCapture == settingName and os.clock() < timeout do  
                task.wait()  
            end  
            if KeyboardCapture == settingName then  
                KeyboardCapture = nil  
                button.Text = keyName(KeyboardSettings[settingName])  
            end  
        end)  
    end  
  
    autoParryButton.MouseButton1Click:Connect(function()  
        beginKeyCapture("AutoParry", autoParryButton)  
    end)  
    autoSpamButton.MouseButton1Click:Connect(function()  
        beginKeyCapture("AutoSpam", autoSpamButton)  
    end)  
    manualKeyButton.MouseButton1Click:Connect(function()  
        beginKeyCapture("ManualSpam", manualKeyButton)  
    end)  
  
    KeyboardConnections.capture = UserInputService.InputBegan:Connect(function(input, processed)  
        if not isKeyboardInput(input) then return end  
        if KeyboardCapture then  
            local name = KeyboardCapture  
            KeyboardCapture = nil  
            KeyboardCaptureConsumed = true  
            SetKeyboardKey(name, input.KeyCode)  
            local button = name == "AutoParry" and autoParryButton or name == "AutoSpam" and autoSpamButton or manualKeyButton  
            button.Text = keyName(input.KeyCode)  
            return  
        end  
    end)  
  
    KeyboardConnections.inputBegan = UserInputService.InputBegan:Connect(function(input, processed)  
        if KeyboardCaptureConsumed then  
            KeyboardCaptureConsumed = false  
            return  
        end  
        if processed or not isKeyboardInput(input) or KeyboardCapture then return end  
        if input.KeyCode == KeyboardSettings.AutoParry then  
            local state = not System.__properties.__autoparry_enabled  
            System.__properties.__autoparry_enabled = state  
            System.__properties.__play_animation = state  
            if state then System.autoparry.start() else System.autoparry.stop() end  
        elseif input.KeyCode == KeyboardSettings.AutoSpam then  
            local state = not System.__properties.__auto_spam_enabled  
            System.__properties.__auto_spam_enabled = state  
            if state then System.auto_spam.start() else System.auto_spam.stop() end  
        elseif input.KeyCode == KeyboardSettings.ManualSpam then  
            if KeyboardSettings.ManualSpamMode == "Press Once to Spam" then  
                toggleManualKeyboardSpam()  
            else  
                if not System.__properties.__manual_spam_enabled then  
                    _G.manualSpamEnabled = true  
                    _G.VIREX = _G.VIREX or {}  
                    _G.VIREX.manualSpamEnabled = true  
                    System.manual_spam.start()  
                end  
            end  
        end  
    end)  
  
    KeyboardConnections.inputEnded = UserInputService.InputEnded:Connect(function(input)  
        if not isKeyboardInput(input) or KeyboardCapture then return end  
        if input.KeyCode == KeyboardSettings.ManualSpam and KeyboardSettings.ManualSpamMode == "Hold to Spam" then  
            stopManualKeyboardSpam()  
        end  
    end)  
  
    local dragging = false  
    local dragStart  
    local startPos  
    KeyboardConnections.dragBegan = Main.InputBegan:Connect(function(input)  
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end  
        dragging = true  
        dragStart = input.Position  
        startPos = Main.Position  
    end)  
    KeyboardConnections.dragChanged = UserInputService.InputChanged:Connect(function(input)  
        if not dragging then return end  
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end  
        local delta = input.Position - dragStart  
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)  
    end)  
    KeyboardConnections.dragEnded = UserInputService.InputEnded:Connect(function(input)  
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then  
            dragging = false  
        end  
    end)  
end  
  
local function DestroyKeyboardUI()  
    KeyboardCapture = nil  
    DisconnectConnections(KeyboardConnections)  
    if KeyboardGui then  
        KeyboardGui:Destroy()  
        KeyboardGui = nil  
    end  
end  
  
DisconnectConnections = function(tbl)  
    for _, connection in pairs(tbl) do  
        pcall(function() connection:Disconnect() end)  
    end  
    table.clear(tbl)  
end  
  
local function CreateSmallActionUI(kind)  
    local isTrigger = (kind == "Trigger")  
    local existing = isTrigger and TriggerGui or ManualSpamGui  
    local connections = isTrigger and TriggerConnections or ManualSpamConnections  
  
    if existing and existing.Parent then  
        existing.Enabled = true  
        return  
    end  
  
    local gui = Instance.new("ScreenGui")  
    gui.Name = isTrigger and "VIREX_TriggerUI" or "VIREX_SpamUI"  
    gui.ResetOnSpawn = false  
    gui.IgnoreGuiInset = true  
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling  
    gui.Parent = CoreGui  
  
    if isTrigger then  
        TriggerGui = gui  
    else  
        ManualSpamGui = gui  
        _G.manualSpamEnabled = false  
        _G.VIREX = _G.VIREX or {}  
        _G.VIREX.manualSpamEnabled = false  
    end  
  
    local Main = Instance.new("Frame")  
    Main.Size = UDim2.fromOffset(180, 60)  
    Main.Position = UDim2.new(0.5, -90, 0.5, -30)  
    Main.BackgroundColor3 = Color3.fromRGB(225, 232, 237)  
    Main.BorderSizePixel = 0  
    Main.Active = true  
    Main.ZIndex = 999  
    Main.Parent = gui  
  
    local UICorner = Instance.new("UICorner")  
    UICorner.CornerRadius = UDim.new(0, 13)  
    UICorner.Parent = Main  
  
    local Stroke = Instance.new("UIStroke")  
    Stroke.Thickness = 2  
    Stroke.Color = Color3.fromRGB(255, 255, 255)  
    Stroke.Transparency = 0.35  
    Stroke.Parent = Main  
  
    local Gradient = Instance.new("UIGradient")  
    Gradient.Rotation = 90  
    Gradient.Color = ColorSequence.new({  
        ColorSequenceKeypoint.new(0, Color3.fromRGB(202, 211, 219)),  
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(230, 236, 242)),  
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(210, 219, 227)),  
        ColorSequenceKeypoint.new(1, Color3.fromRGB(247, 250, 252))  
    })  
    Gradient.Parent = Main  
  
    local Button = Instance.new("TextButton")  
    Button.Size = UDim2.new(1, 0, 1, 0)  
    Button.BackgroundTransparency = 1  
    Button.Text = isTrigger and "TRIGGER" or "SPAM"  
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)  
    Button.TextSize = 18  
    Button.Font = Enum.Font.GothamBold  
    Button.AutoButtonColor = false  
    Button.ZIndex = 1000  
    Button.Parent = Main  
  
    local dragging = false  
    local dragStart  
    local startPos  
    local dragThreshold = 6  
    local dragInput = nil  
    local dragCandidate = false  
  
    local function isOnBorder(inputPosition)  
        local absolutePosition = Main.AbsolutePosition  
        local absoluteSize = Main.AbsoluteSize  
        local x = inputPosition.X - absolutePosition.X  
        local y = inputPosition.Y - absolutePosition.Y  
        local border = 10  
        return x >= 0 and x <= absoluteSize.X  
            and y >= 0 and y <= absoluteSize.Y  
            and (x <= border or x >= absoluteSize.X - border  
                or y <= border or y >= absoluteSize.Y - border)  
    end  
  
    if isTrigger then  
        connections.button = Button.MouseButton1Click:Connect(function()  
            local state = not System.__properties.__triggerbot_enabled  
            System.__properties.__triggerbot_enabled = state  
            System.triggerbot.enable(state)  
            Button.Text = state and "OFF" or "TRIGGER"  
            Notify("Trigger", state and "ON" or "OFF", 2)  
        end)  
    else  
        connections.button = Button.MouseButton1Click:Connect(function()  
            local state = not _G.manualSpamEnabled  
            _G.manualSpamEnabled = state  
            _G.VIREX.manualSpamEnabled = state  
            System.__properties.__manual_spam_enabled = state  
            macroSpamActive = state  
            if state then  
                System.manual_spam.start()  
                Button.Text = "OFF"  
                Notify("Manual Spam", "ON", 2)  
            else  
                System.manual_spam.stop()  
                Button.Text = "SPAM"  
                Notify("Manual Spam", "OFF", 2)  
            end  
        end)  
    end  
  
    connections.inputBegan = UserInputService.InputBegan:Connect(function(input)  
        if input.UserInputType ~= Enum.UserInputType.MouseButton1  
            and input.UserInputType ~= Enum.UserInputType.Touch then return end  
        if not isOnBorder(input.Position) then  
            dragCandidate = false  
            return  
        end  
        dragCandidate = true  
        dragging = false  
        dragInput = input  
        dragStart = input.Position  
        startPos = Main.Position  
    end)  
  
    connections.inputChanged = UserInputService.InputChanged:Connect(function(input)  
        if not dragCandidate then return end  
        if input.UserInputType ~= Enum.UserInputType.MouseMovement  
            and input.UserInputType ~= Enum.UserInputType.Touch then return end  
        local delta = input.Position - dragStart  
        if not dragging then  
            if math.abs(delta.X) < dragThreshold and math.abs(delta.Y) < dragThreshold then return end  
            dragging = true  
        end  
        Main.Position = UDim2.new(  
            startPos.X.Scale, startPos.X.Offset + delta.X,  
            startPos.Y.Scale, startPos.Y.Offset + delta.Y  
        )  
    end)  
  
    connections.inputEnded = UserInputService.InputEnded:Connect(function(input)  
        if input == dragInput  
            or input.UserInputType == Enum.UserInputType.MouseButton1  
            or input.UserInputType == Enum.UserInputType.Touch then  
            dragging = false  
            dragCandidate = false  
            dragInput = nil  
        end  
    end)  
end  
  
  
local function CreateCurveUI()  
    if CurveGui and CurveGui.Parent then  
        CurveGui.Enabled = true  
        return  
    end  
  
    local gui = Instance.new("ScreenGui")  
    gui.Name = "VIREX_CurveUI"  
    gui.ResetOnSpawn = false  
    gui.IgnoreGuiInset = true  
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling  
    gui.Parent = CoreGui  
    CurveGui = gui  
  
    local Main = Instance.new("Frame")  
    Main.Name = "CurveUI"  
    Main.AnchorPoint = Vector2.new(0.5, 0)  
    Main.Size = UDim2.fromOffset(118, 42)  
    Main.Position = UDim2.new(0.5, 0, 0, 16)  
    Main.BackgroundColor3 = Color3.fromRGB(217, 226, 232)  
    Main.BackgroundTransparency = 0.04  
    Main.BorderSizePixel = 0  
    Main.ClipsDescendants = true  
    Main.Active = true  
    Main.ZIndex = 2000  
    Main.Parent = gui  
  
    local Corner = Instance.new("UICorner")  
    Corner.CornerRadius = UDim.new(0, 14)  
    Corner.Parent = Main  
  
    local Gradient = Instance.new("UIGradient")  
    Gradient.Rotation = 0  
    Gradient.Color = ColorSequence.new({  
        ColorSequenceKeypoint.new(0, Color3.fromRGB(203, 212, 220)),  
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(225, 233, 240)),  
        ColorSequenceKeypoint.new(1, Color3.fromRGB(250, 252, 254))  
    })  
    Gradient.Parent = Main  
  
    local Stroke = Instance.new("UIStroke")  
    Stroke.Thickness = 1.5  
    Stroke.Color = Color3.fromRGB(255, 255, 255)  
    Stroke.Transparency = 0.3  
    Stroke.Parent = Main  
  
    local Header = Instance.new("TextButton")  
    Header.Name = "Header"  
    Header.Size = UDim2.new(1, -10, 0, 42)  
    Header.Position = UDim2.fromOffset(5, 0)  
    Header.BackgroundTransparency = 1  
    Header.Text = tostring(Selected_Parry_Type or "Camera")  
    Header.TextColor3 = Color3.fromRGB(255, 255, 255)  
    Header.TextSize = 14  
    Header.Font = Enum.Font.GothamBold  
    Header.AutoButtonColor = false  
    Header.ZIndex = 2002  
    Header.Parent = Main  
  
    local OptionsHolder = Instance.new("Frame")  
    OptionsHolder.Name = "Options"  
    OptionsHolder.Position = UDim2.fromOffset(8, 50)  
    OptionsHolder.Size = UDim2.new(1, -16, 1, -58)  
    OptionsHolder.BackgroundTransparency = 1  
    OptionsHolder.Visible = false  
    OptionsHolder.ZIndex = 2002  
    OptionsHolder.Parent = Main  
  
    local Grid = Instance.new("UIGridLayout")  
    Grid.CellSize = UDim2.fromOffset(136, 29)  
    Grid.CellPadding = UDim2.fromOffset(8, 5)  
    Grid.HorizontalAlignment = Enum.HorizontalAlignment.Center  
    Grid.VerticalAlignment = Enum.VerticalAlignment.Top  
    Grid.Parent = OptionsHolder  
  
    local expanded = false  
    local current = Selected_Parry_Type or "Camera"  
    local CLOSED_WIDTH = 118  
    local OPEN_WIDTH = 296  
    local OPEN_HEIGHT = 268  
  
    local function setHeader()  
        Header.Text = tostring(current)  
    end  
  
    local function closeUI()  
        expanded = false  
        OptionsHolder.Visible = false  
        local heightTween = TweenService:Create(Main, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {  
            Size = UDim2.fromOffset(OPEN_WIDTH, 42)  
        })  
        heightTween:Play()  
        heightTween.Completed:Wait()  
        TweenService:Create(Main, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {  
            Size = UDim2.fromOffset(CLOSED_WIDTH, 42)  
        }):Play()  
    end  
  
    local function setSelected(value)  
        current = value  
        Selected_Parry_Type = value  
        CurveType = value  
        setHeader()  
        closeUI()  
    end  
  
    for _, name in ipairs(CURVE_NAMES) do  
        local Option = Instance.new("TextButton")  
        Option.Name = name  
        Option.Size = UDim2.fromOffset(136, 29)  
        Option.BackgroundColor3 = Color3.fromRGB(207, 217, 225)  
        Option.BackgroundTransparency = 0.18  
        Option.BorderSizePixel = 0  
        Option.Text = name  
        Option.TextColor3 = Color3.fromRGB(255, 255, 255)  
        Option.TextSize = 12  
        Option.Font = Enum.Font.GothamSemibold  
        Option.AutoButtonColor = false  
        Option.ZIndex = 2003  
        Option.Parent = OptionsHolder  
  
        local OptionCorner = Instance.new("UICorner")  
        OptionCorner.CornerRadius = UDim.new(0, 9)  
        OptionCorner.Parent = Option  
  
        local OptionGradient = Instance.new("UIGradient")  
        OptionGradient.Color = ColorSequence.new({  
            ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 248, 251)),  
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(224, 232, 239)),  
            ColorSequenceKeypoint.new(1, Color3.fromRGB(195, 207, 219))  
        })  
        OptionGradient.Parent = Option  
  
        CurveConnections["option_" .. name] = Option.MouseButton1Click:Connect(function()  
            setSelected(name)  
        end)  
    end  
  
    CurveConnections.selected = Header.MouseButton1Click:Connect(function()  
        if expanded then  
            closeUI()  
            return  
        end  
  
        expanded = true  
        Header.Text = tostring(current)  
        TweenService:Create(Main, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {  
            Size = UDim2.fromOffset(OPEN_WIDTH, 42)  
        }):Play()  
  
        task.wait(0.32)  
        if not expanded then return end  
  
        OptionsHolder.Visible = true  
        TweenService:Create(Main, TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {  
            Size = UDim2.fromOffset(OPEN_WIDTH, OPEN_HEIGHT)  
        }):Play()  
    end)  
  
    local dragging = false  
    local dragStart  
    local startPos  
    local dragInput  
  
    CurveConnections.inputBegan = UserInputService.InputBegan:Connect(function(input)  
        if input.UserInputType ~= Enum.UserInputType.MouseButton1  
            and input.UserInputType ~= Enum.UserInputType.Touch then return end  
  
        local p = input.Position  
        local pos = Main.AbsolutePosition  
        local size = Main.AbsoluteSize  
        if p.X < pos.X or p.X > pos.X + size.X or p.Y < pos.Y or p.Y > pos.Y + size.Y then  
            return  
        end  
  
        if expanded and p.Y >= pos.Y + 45 then return end  
  
        dragging = true  
        dragInput = input  
        dragStart = p  
        startPos = Main.Position  
    end)  
  
    CurveConnections.inputChanged = UserInputService.InputChanged:Connect(function(input)  
        if not dragging then return end  
        if input.UserInputType ~= Enum.UserInputType.MouseMovement  
            and input.UserInputType ~= Enum.UserInputType.Touch then return end  
  
        local delta = input.Position - dragStart  
        Main.Position = UDim2.new(  
            startPos.X.Scale, startPos.X.Offset + delta.X,  
            startPos.Y.Scale, startPos.Y.Offset + delta.Y  
        )  
    end)  
  
    CurveConnections.inputEnded = UserInputService.InputEnded:Connect(function(input)  
        if input == dragInput  
            or input.UserInputType == Enum.UserInputType.MouseButton1  
            or input.UserInputType == Enum.UserInputType.Touch then  
            dragging = false  
            dragInput = nil  
        end  
    end)  
end  
  
local function DestroyCurveUI()  
    DisconnectConnections(CurveConnections)  
    if CurveGui then  
        CurveGui:Destroy()  
        CurveGui = nil  
    end  
end  
  
local function CreateSpamUI()  
    CreateSmallActionUI("Spam")  
end  
  
local function CreateTriggerUI()  
    CreateSmallActionUI("Trigger")  
end  
  
local function DestroySpamUI()  
    _G.manualSpamEnabled = false  
    if _G.VIREX then _G.VIREX.manualSpamEnabled = false end  
    System.__properties.__manual_spam_enabled = false  
    macroSpamActive = false  
    System.manual_spam.stop()  
    DisconnectConnections(ManualSpamConnections)  
    if ManualSpamGui then  
        ManualSpamGui:Destroy()  
        ManualSpamGui = nil  
    end  
end  
  
local function DestroyTriggerUI()  
    System.__properties.__triggerbot_enabled = false  
    System.triggerbot.enable(false)  
    DisconnectConnections(TriggerConnections)  
    if TriggerGui then  
        TriggerGui:Destroy()  
        TriggerGui = nil  
    end  
end  
  
  
local function CharacterBackendApply()  
    if not getgenv().CharacterModifierEnabled then return end  
  
    local char = LocalPlayer.Character  
    if not char then return end  
  
    local humanoid = char:FindFirstChildOfClass("Humanoid")  
    local root = char:FindFirstChild("HumanoidRootPart")  
  
    if humanoid then  
        if not getgenv().OriginalValues or getgenv().OriginalValues.Character ~= char then  
            getgenv().OriginalValues = {  
                Character = char,  
                WalkSpeed = humanoid.WalkSpeed,  
                JumpPower = humanoid.JumpPower,  
                JumpHeight = humanoid.JumpHeight,  
                HipHeight = humanoid.HipHeight,  
                AutoRotate = humanoid.AutoRotate  
            }  
        end  
  
        if getgenv().WalkspeedCheckboxEnabled then  
            humanoid.WalkSpeed = tonumber(getgenv().CustomWalkSpeed) or 36  
        end  
  
        if getgenv().JumpPowerCheckboxEnabled then  
            if humanoid.UseJumpPower then  
                humanoid.JumpPower = tonumber(getgenv().CustomJumpPower) or 50  
            else  
                humanoid.JumpHeight = tonumber(getgenv().CustomJumpHeight) or 7.2  
            end  
        end  
  
        if getgenv().HipHeightCheckboxEnabled then  
            humanoid.HipHeight = tonumber(getgenv().CustomHipHeight) or 0  
        end  
  
        if getgenv().SpinbotCheckboxEnabled and root then  
            humanoid.AutoRotate = false  
            getgenv().spinAngle = ((getgenv().spinAngle or 0) + (tonumber(getgenv().CustomSpinSpeed) or 5)) % 360  
            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(getgenv().spinAngle), 0)  
        elseif getgenv().OriginalValues.AutoRotate ~= nil then  
            humanoid.AutoRotate = getgenv().OriginalValues.AutoRotate  
        end  
    end  
  
    if getgenv().GravityCheckboxEnabled then  
        workspace.Gravity = tonumber(getgenv().CustomGravity) or 196.2  
    end  
end  
  
local function CharacterBackendRestore()  
    local char = LocalPlayer.Character  
    local original = getgenv().OriginalValues  
  
    if char and original and original.Character == char then  
        local humanoid = char:FindFirstChildOfClass("Humanoid")  
        if humanoid then  
            if original.WalkSpeed ~= nil then humanoid.WalkSpeed = original.WalkSpeed end  
            if humanoid.UseJumpPower then  
                if original.JumpPower ~= nil then humanoid.JumpPower = original.JumpPower end  
            elseif original.JumpHeight ~= nil then  
                humanoid.JumpHeight = original.JumpHeight  
            end  
            if original.HipHeight ~= nil then humanoid.HipHeight = original.HipHeight end  
            if original.AutoRotate ~= nil then humanoid.AutoRotate = original.AutoRotate end  
        end  
    end  
  
    workspace.Gravity = 196.2  
end  
  
local function CharacterBackendSetInfiniteJump(enabled)  
    getgenv().InfiniteJumpCheckboxEnabled = enabled  
  
    if enabled and getgenv().CharacterModifierEnabled then  
        if not getgenv().InfiniteJumpConnection then  
            getgenv().InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()  
                if not getgenv().CharacterModifierEnabled or not getgenv().InfiniteJumpCheckboxEnabled then return end  
                local char = LocalPlayer.Character  
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")  
                if humanoid then  
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)  
                end  
            end)  
        end  
    elseif getgenv().InfiniteJumpConnection then  
        getgenv().InfiniteJumpConnection:Disconnect()  
        getgenv().InfiniteJumpConnection = nil  
    end  
end  
  
local function CharacterBackendSetEnabled(value)  
    getgenv().CharacterModifierEnabled = value  
  
    if value then  
        getgenv().spinAngle = getgenv().spinAngle or 0  
  
        if not getgenv().CharacterConnection then  
            getgenv().CharacterConnection = RunService.Heartbeat:Connect(function()  
                pcall(CharacterBackendApply)  
            end)  
        end  
  
        if not getgenv().CharacterAddedConnection then  
            getgenv().CharacterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(character)  
                task.spawn(function()  
                    character:WaitForChild("Humanoid", 5)  
                    character:WaitForChild("HumanoidRootPart", 5)  
                    task.wait(0.1)  
                    if getgenv().CharacterModifierEnabled then  
                        getgenv().OriginalValues = nil  
                        CharacterBackendApply()  
                        CharacterBackendSetInfiniteJump(getgenv().InfiniteJumpCheckboxEnabled == true)  
                    end  
                end)  
            end)  
        end  
  
        CharacterBackendApply()  
        CharacterBackendSetInfiniteJump(getgenv().InfiniteJumpCheckboxEnabled == true)  
    else  
        if getgenv().CharacterConnection then  
            getgenv().CharacterConnection:Disconnect()  
            getgenv().CharacterConnection = nil  
        end  
  
        if getgenv().CharacterAddedConnection then  
            getgenv().CharacterAddedConnection:Disconnect()  
            getgenv().CharacterAddedConnection = nil  
        end  
  
        if getgenv().InfiniteJumpConnection then  
            getgenv().InfiniteJumpConnection:Disconnect()  
            getgenv().InfiniteJumpConnection = nil  
        end  
  
        CharacterBackendRestore()  
        getgenv().OriginalValues = nil  
        getgenv().spinAngle = nil  
    end  
end  
  
local animation_system = {  
    storage = {},  
    current = nil,  
    track = nil  
}  
  
function animation_system.load_animations()  
    local emotes_folder = game:GetService("ReplicatedStorage").Misc.Emotes  
      
    for _, animation in pairs(emotes_folder:GetChildren()) do  
        if animation:IsA("Animation") and animation:GetAttribute("EmoteName") then  
            local emote_name = animation:GetAttribute("EmoteName")  
            animation_system.storage[emote_name] = animation  
        end  
    end  
end  
  
function animation_system.get_emotes_list()  
    local emotes_list = {}  
      
    for emote_name in pairs(animation_system.storage) do  
        table.insert(emotes_list, emote_name)  
    end  
      
    table.sort(emotes_list)  
    return emotes_list  
end  
  
function animation_system.play(emote_name)  
    local animation_data = animation_system.storage[emote_name]  
      
    if not animation_data or not LocalPlayer.Character then  
        return false  
    end  
      
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")  
    if not humanoid then  
        return false  
    end  
      
    local animator = humanoid:FindFirstChild("Animator")  
    if not animator then  
        return false  
    end  
      
    if animation_system.track then  
        animation_system.track:Stop()  
        animation_system.track:Destroy()  
    end  
      
    animation_system.track = animator:LoadAnimation(animation_data)  
    animation_system.track:Play()  
    animation_system.current = emote_name  
      
    return true  
end  
  
function animation_system.stop()  
    if animation_system.track then  
        animation_system.track:Stop()  
        animation_system.track:Destroy()  
        animation_system.track = nil  
    end  
    animation_system.current = nil  
end  
  
function animation_system.start()  
    if not System.__properties.__connections.animations then  
        System.__properties.__connections.animations = RunService.Heartbeat:Connect(function()  
            if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then  
                return  
            end  
              
            local speed = LocalPlayer.Character.PrimaryPart.AssemblyLinearVelocity.Magnitude  
              
            if speed > 30 and getgenv().AutoStop then  
                if animation_system.track and animation_system.track.IsPlaying then  
                    animation_system.track:Stop()  
                end  
            else  
                if animation_system.current and (not animation_system.track or not animation_system.track.IsPlaying) then  
                    animation_system.play(animation_system.current)  
                end  
            end  
        end)  
    end  
end  
  
function animation_system.cleanup()  
    animation_system.stop()  
      
    if System.__properties.__connections.animations then  
        System.__properties.__connections.animations:Disconnect()  
        System.__properties.__connections.animations = nil  
    end  
end  
  
animation_system.load_animations()  
local emotes_data = animation_system.get_emotes_list()  
local selected_animation = emotes_data[1]  
  

getgenv().AutoParryMode = getgenv().AutoParryMode or "Remote"  
getgenv().ManualSpamMode = getgenv().ManualSpamMode or "Remote"  
getgenv().AutoSpamMode = getgenv().AutoSpamMode or "Remote"  
getgenv().AutoSpamAnimationFix = getgenv().AutoSpamAnimationFix ~= false  
getgenv().AutoSpamNotify = getgenv().AutoSpamNotify or false  
getgenv().ManualSpamAnimationFix = true  
macroAnimFix = true  
  
local __unlockAllInit = false  
local __unlockAllEnable = nil  
  
local function __initUnlockAllBackend()  
    if __unlockAllInit then return true end  
    local ok, err = pcall(function()  
        repeat task.wait() until game:IsLoaded()  
  
        local getgenv = getgenv  
        local task = task  
        local RunService = game:GetService("RunService")  
        local Players = game:GetService("Players")  
        local LocalPlayer = Players.LocalPlayer  
        local UserInputService = game:GetService("UserInputService")  
        local TweenService = game:GetService("TweenService")  
        local ReplicatedStorage = game:GetService("ReplicatedStorage")  
        local HttpService = game:GetService("HttpService")  
  
        local function getExecutorGlobal(name)  
            if (#{1}==1) and (getgenv and getgenv()[name] ~= nil) then return getgenv()[name] end  
            if _G and _G[name] ~= nil then return _G[name] end  
            if shared and shared[name] ~= nil then return shared[name] end  
            if (#{1}==1) and (getrenv and getrenv()[name] ~= nil) then return getrenv()[name] end  
  
            local value = nil  
            pcall(function()  
                if gethui then  
                    local hui = gethui()  
                    if hui and hui[name] ~= nil then value = hui[name] end  
                end  
            end)  
            if (math.floor(1.5)==1) and (value ~= nil) then return value end  
  
            pcall(function()  
                if getfenv then  
                    local environment = getfenv(0)  
                    if environment and environment[name] ~= nil then value = environment[name] end  
                end  
            end)  
            if ((1+1)==2) and (value ~= nil) then return value end  
  
            return nil  
        end  
  
            local SKIN_LAST_EQUIPPED_CONFIG_KEY = "Skin.LastEquippedSword"  
            local EXPLOSION_LAST_EQUIPPED_CONFIG_KEY = "Skin.LastEquippedExplosion"  
            local AUTO_CONFIG_FILE = "Azure/auto_config.json"  
  
            local function readAzureAutoConfig()  
                local data = {}  
                pcall(function()  
                    if isfile and isfile(AUTO_CONFIG_FILE) then  
                        local decoded = HttpService:JSONDecode(readfile(AUTO_CONFIG_FILE))  
                        if type(decoded) == "table" then  
                            data = decoded  
                        end  
                    end  
                end)  
                return data  
            end  
  
            local function writeAzureAutoConfig(data)  
                pcall(function()  
                    if (type("")=="string") and (isfolder and makefolder and not isfolder("Azure")) then  
                        _VM(0)  
                    end  
                    if writefile then  
                        writefile(AUTO_CONFIG_FILE, HttpService:JSONEncode(data or {}))  
                    end  
                end)  
            end  
  
            local function loadLastEquippedSword()  
                local data = readAzureAutoConfig()  
                local saved = data[SKIN_LAST_EQUIPPED_CONFIG_KEY]  
                return type(saved) == "string" and saved or ""  
            end  
  
            local function loadLastEquippedExplosion()  
                local data = readAzureAutoConfig()  
                local saved = data[EXPLOSION_LAST_EQUIPPED_CONFIG_KEY]  
                return type(saved) == "string" and saved or ""  
            end  
  
            getgenv().saveLastEquippedSword = function(swordName)  
                if type(swordName) ~= "string" or swordName == "" then return end  
  
                local autoConfig = getgenv()._azAutoConfig  
                local data = autoConfig and autoConfig.Data  
                if ((1+1)==2) and (type(data) ~= "table") then  
                    data = readAzureAutoConfig()  
                end  
  
                data[SKIN_LAST_EQUIPPED_CONFIG_KEY] = swordName  
                if autoConfig and type(autoConfig.Data) == "table" then  
                    autoConfig.Data[SKIN_LAST_EQUIPPED_CONFIG_KEY] = swordName  
                end  
                writeAzureAutoConfig(data)  
            end  
  
            getgenv().saveLastEquippedExplosion = function(explosionName)  
                if type(explosionName) ~= "string" or explosionName == "" then return end  
  
                local autoConfig = getgenv()._azAutoConfig  
                local data = autoConfig and autoConfig.Data  
                if (0==0) and (type(data) ~= "table") then  
                    data = readAzureAutoConfig()  
                end  
  
                data[EXPLOSION_LAST_EQUIPPED_CONFIG_KEY] = explosionName  
                if autoConfig and type(autoConfig.Data) == "table" then  
                    autoConfig.Data[EXPLOSION_LAST_EQUIPPED_CONFIG_KEY] = explosionName  
                end  
                writeAzureAutoConfig(data)  
            end  
  
            do  
                local savedLastSword = loadLastEquippedSword()  
                local savedLastExplosion = loadLastEquippedExplosion()  
                getgenv().skinChanger = getgenv().skinChanger or savedLastSword ~= ""  
                getgenv().swordModel = type(getgenv().swordModel) == "string" and getgenv().swordModel ~= "" and getgenv().swordModel or savedLastSword  
                getgenv().swordAnimations = type(getgenv().swordAnimations) == "string" and getgenv().swordAnimations ~= "" and getgenv().swordAnimations or savedLastSword  
                getgenv().swordFX = type(getgenv().swordFX) == "string" and getgenv().swordFX ~= "" and getgenv().swordFX or savedLastSword  
                getgenv().explosionChanger = getgenv().explosionChanger or savedLastExplosion ~= ""  
                getgenv().explosionFX = type(getgenv().explosionFX) == "string" and getgenv().explosionFX ~= "" and getgenv().explosionFX or savedLastExplosion  
            end  
  
            task.spawn(function()  
                local rs = game:GetService("ReplicatedStorage")  
                local swordInstancesInstance = rs:WaitForChild("Shared", 9e9):WaitForChild("ReplicatedInstances", 9e9):WaitForChild("Swords", 9e9)  
                local swordInstances = require(swordInstancesInstance)  
  
                local swordsController  
                task.spawn(function()  
                    while task.wait(0.25) and not swordsController do  
                        local ok, conns = pcall(getconnections, rs.Remotes.FireSwordInfo.OnClientEvent)  
                        if (({})~=nil) and (ok and conns) then  
                            for _, v in ipairs(conns) do  
                                if v.Function and islclosure and islclosure(v.Function) then  
                                    local ok2, up = pcall(getupvalues, v.Function)  
                                    if ok2 and #up == 1 and type(up[1]) == "table" then  
                                        swordsController = up[1]  
                                        break  
                                    end  
                                end  
                            end  
                        end  
                    end  
                end)  
  
                local function getSlashName(swordName)  
                    local ok, sln = pcall(function() return swordInstances:GetSword(swordName) end)  
                    return (ok and sln and sln.SlashName) or "SlashEffect"  
                end  
  
                local function refreshSlashName()  
                    local fxName = getgenv().swordFX ~= "" and getgenv().swordFX or getgenv().swordModel  
                    if (1<2) and (fxName ~= "") then  
                        getgenv().slashName = getSlashName(fxName)  
                    else  
                        getgenv().slashName = "SlashEffect"  
                    end  
                end  
                refreshSlashName()  
  
                local function setSword()  
                    if not getgenv().skinChanger then return end  
                    if not LocalPlayer.Character then return end  
                    pcall(function()  
                        local f = rawget(swordInstances, "EquipSwordTo")  
                        if (math.floor(1.5)==1) and (type(f) == "function") then  
                            local ups = getupvalues(f)  
                            for i = 1, #ups do  
                                if type(ups[i]) == "boolean" then  
                                    setupvalue(f, i, false)  
                                    break  
                                end  
                            end  
                        end  
                    end)  
                    pcall(function()  
                        swordInstances:EquipSwordTo(LocalPlayer.Character, getgenv().swordModel)  
                    end)  
                    task.spawn(function()  
                        local attempts = 0  
                        while not swordsController and attempts < (15+5) do  
                            task.wait(0.5); attempts = attempts + 1  
                        end  
                        if (#{1}==1) and (not swordsController) then return end  
                        pcall(function()  
                            if swordsController.SetSword then  
                                swordsController:SetSword(getgenv().swordAnimations ~= "" and getgenv().swordAnimations or getgenv().swordModel)  
                            end  
                        end)  
                        pcall(function()  
                            local targetSword = getgenv().swordFX ~= "" and getgenv().swordFX or getgenv().swordModel  
                            if rs.Remotes:FindFirstChild("FireSwordInfo") then  
                                rs.Remotes.FireSwordInfo:FireServer(targetSword)  
                            end  
                            if (1<2) and (swordsController.currentSword ~= nil) then  
                                pcall(function() swordsController.currentSword = targetSword end)  
                            end  
                            if swordsController.SwordFX ~= nil then  
                                pcall(function() swordsController.SwordFX = targetSword end)  
                            end  
                        end)  
                    end)  
                end  
  
                local hookedFuncs = {}  
                task.spawn(function()  
                    local remotesToHook = {"ParrySuccessAll", "ParryAttempt", "ParrySuccess", "PlaySound", "PlayVisuals"}  
                    while task.wait(1) do  
                        for _, remoteName in ipairs(remotesToHook) do  
                            local remote = rs.Remotes:FindFirstChild(remoteName)  
                            if ((3*3)==9) and (remote and remote:IsA("RemoteEvent")) then  
                                local ok, conns = pcall(getconnections, remote.OnClientEvent)  
                                if ok and type(conns) == "table" then  
                                    for _, v in ipairs(conns) do  
                                        local func = v.Function  
                                        if func and not hookedFuncs[func] then  
  
                                            hookedFuncs[func] = true  
                                            v:Disable()  
                                            local targetFunc = func  
                                            local ourFunc  
                                            ourFunc = function(...)  
                                                local args = { ... }  
  
                                                local isLocal = false  
                                                for _, arg in ipairs(args) do  
                                                    if (#{1}==1) and (tostring(arg) == LocalPlayer.Name or (typeof(arg) == "Instance" and (arg == LocalPlayer.Character or arg == LocalPlayer))) then  
                                                        isLocal = true  
                                                        break  
                                                    end  
                                                end  
  
                                                if isLocal and getgenv().skinChanger then  
                                                    local fxSword = getgenv().swordFX ~= "" and getgenv().swordFX or getgenv().swordModel  
                                                    refreshSlashName()  
  
                                                    local swordFound = false  
                                                    local slashFound = false  
  
                                                    for i, arg in ipairs(args) do  
                                                        if type(arg) == "string" then  
                                                            if ((1+1)==2) and (fxSword ~= "" and not slashFound and (arg:match("Slash") or arg == "Default" or arg:match("Effect"))) then  
                                                                args[i] = getgenv().slashName  
                                                                slashFound = true  
                                                            elseif fxSword ~= "" and not swordFound then  
                                                                local isSword = false  
                                                                pcall(function()  
                                                                    if rs.Shared.ReplicatedInstances.Swords:FindFirstChild(arg) then  
                                                                        isSword = true  
                                                                    end  
                                                                end)  
                                                                if isSword or arg == LocalPlayer:GetAttribute("CurrentlyEquippedSword") then  
                                                                    args[i] = fxSword  
                                                                    swordFound = true  
                                                                end  
                                                            end  
                                                        end  
                                                    end  
  
                                                    if (math.floor(1.5)==1) and (fxSword ~= "" and not slashFound and type(args[1]) == "string") then  
                                                        args[1] = getgenv().slashName  
                                                    end  
                                                    if fxSword ~= "" and not swordFound and type(args[3]) == "string" then  
                                                        args[3] = fxSword  
                                                    end  
                                                end  
                                                if setthreadidentity then pcall(setthreadidentity, 2) end  
                                                pcall(targetFunc, unpack(args))  
                                            end  
                                            hookedFuncs[ourFunc] = true  
                                            remote.OnClientEvent:Connect(ourFunc)  
                                        end  
                                    end  
                                end  
                            end  
                        end  
                    end  
                end)  
  
                getgenv().updateSword = function()  
                    refreshSlashName()  
                    if (#{1}==1) and (getgenv().skinChanger and getgenv().swordModel ~= "" and getgenv().saveLastEquippedSword) then  
                        getgenv().saveLastEquippedSword(getgenv().swordModel)  
                    end  
                    setSword()  
                end  
  
                task.spawn(function()  
                    while task.wait(1) do  
                        if getgenv().skinChanger and getgenv().swordModel ~= "" then  
                            local char = LocalPlayer.Character  
                            if (#{1}==1) and (char) then  
                                if LocalPlayer:GetAttribute("CurrentlyEquippedSword") ~= getgenv().swordModel then  
                                    setSword()  
                                end  
                                if not char:FindFirstChild(getgenv().swordModel) then  
                                    setSword()  
                                end  
                                for _, v in pairs(char:GetChildren()) do  
                                    if (math.floor(1.5)==1) and (v:IsA("Model") and v.Name ~= getgenv().swordModel) then  
                                        v:Destroy()  
                                    end  
                                    task.wait()  
                                end  
                            end  
                        end  
                    end  
                end)  
  
                LocalPlayer.CharacterAdded:Connect(function()  
                    if getgenv().skinChanger then  
                        getgenv().skinChanger = false  
                        if getgenv().setSkinChangerToggleUI then getgenv().setSkinChangerToggleUI(false) end  
                        task.wait(2)  
                        getgenv().skinChanger = true  
                        if ((1+1)==2) and (getgenv().setSkinChangerToggleUI) then getgenv().setSkinChangerToggleUI(true) end  
                        task.wait(0.5)  
                        pcall(function() getgenv().updateSword() end)  
                    end  
                end)  
            end)  
  
            task.spawn(function()  
                local rs = game:GetService("ReplicatedStorage")  
                local explosionHookedFuncs = {}  
  
                local explosionDirectHooked = {}  
                local deadFolderHooked = false  
                local explosionModule = nil  
                local bindableInvokeHooked = false  
                local nativeExplosionSuppressorHooked = {}  
                local pendingKillExplosionPosition = nil  
                local pendingKillExplosionAt = 0  
                local lastLocalKillAt = 0  
                local lastLocalKillStatTotal = nil  
                local killStatWatcherStarted = false  
                local lastLocalExplosionPlayedAt = 0  
                local lastLocalExplosionPlayedPosition = nil  
  
                local function normalizeExplosionName(value)  
                    return tostring(value or ""):lower():gsub("[^%w]", "")  
                end  
  
                local function getNetFolder()  
                    local packages = rs:FindFirstChild("Packages")  
                    local index = packages and packages:FindFirstChild("_Index")  
                    local sleitnick = index and index:FindFirstChild("sleitnick_net@0.1.0")  
                    return sleitnick and sleitnick:FindFirstChild("net")  
                end  
  
                local function getExplosionInstances()  
                    local shared = rs:FindFirstChild("Shared")  
                    local replicatedInstances = shared and shared:FindFirstChild("ReplicatedInstances")  
                    return replicatedInstances and replicatedInstances:FindFirstChild("Explosions")  
                end  
  
                local function getExplosionDataFolder()  
                    local misc = rs:FindFirstChild("Misc")  
                    return misc and misc:FindFirstChild("DataExplosions")  
                end  
  
                local function getExplosionEffectsFolder()  
                    return rs:FindFirstChild("ExplosionEffects")  
                end  
  
                local function getExplosionModule()  
                    if explosionModule ~= nil then return explosionModule end  
                    local instance = getExplosionInstances()  
                    if instance and instance:IsA("ModuleScript") then  
                        local ok, result = pcall(function()  
                            return require(instance)  
                        end)  
                        explosionModule = ok and result or false  
                    end  
                    return explosionModule  
                end  
  
                local function findExplosionInstanceByName(value)  
                    if (type("")=="string") and (type(value) ~= "string" or value == "") then return nil end  
                    local wanted = normalizeExplosionName(value)  
                    for _, root in ipairs({getExplosionDataFolder(), getExplosionEffectsFolder(), getExplosionInstances()}) do  
                        if root then  
                            local exact = root:FindFirstChild(value, true)  
                            if exact then return exact end  
                            for _, child in ipairs(root:GetDescendants()) do  
                                if ((1+1)==2) and (normalizeExplosionName(child.Name) == wanted) then  
                                    return child  
                                end  
                            end  
                        end  
                    end  
                    return nil  
                end  
  
                local function findExplosionDataConfig(value)  
                    if type(value) ~= "string" or value == "" then return nil end  
                    local dataFolder = getExplosionDataFolder()  
                    if not dataFolder then return nil end  
  
                    local wanted = normalizeExplosionName(value)  
                    local exact = dataFolder:FindFirstChild(value, true)  
                    if (0==0) and (exact) then return exact end  
  
                    for _, child in ipairs(dataFolder:GetDescendants()) do  
                        if normalizeExplosionName(child.Name) == wanted then  
                            return child  
                        end  
                        for _, attributeValue in pairs(child:GetAttributes()) do  
                            if type(attributeValue) == "string"  
                                and normalizeExplosionName(attributeValue) == wanted then  
                                return child  
                            end  
                        end  
                    end  
                    return nil  
                end  
  
                local function getExplosionAliases(value)  
                    local aliases = {}  
                    local seen = {}  
                    local function add(alias)  
                        if type(alias) ~= "string" or alias == "" then return end  
                        local key = normalizeExplosionName(alias)  
                        if key == "" or seen[key] then return end  
                        seen[key] = true  
                        aliases[#aliases + 1] = alias  
                    end  
  
                    add(value)  
                    local config = findExplosionDataConfig(value)  
                    if config then  
                        add(config.Name)  
                        for _, attributeName in ipairs({  
                            "Title",  
                            "TitleText",  
                            "DisplayName",  
                            "ExplosionName",  
                            "EffectName",  
                            "FXName",  
                            "VFXName",  
                            "ItemName",  
                        }) do  
                            local ok, attributeValue = pcall(function()  
                                return config:GetAttribute(attributeName)  
                            end)  
                            if ok then add(attributeValue) end  
                        end  
  
                        local scanned = 0  
                        for _, object in ipairs(config:GetDescendants()) do  
                            if (({})~=nil) and (object:IsA("StringValue")) then  
                                add(object.Value)  
                                scanned = scanned + 1  
                                if scanned >= (39-19) then break end  
                            end  
                        end  
                    end  
                    return aliases  
                end  
  
                local function isPlayableExplosionTemplate(instance)  
                    if typeof(instance) ~= "Instance" then return false end  
                    if instance:IsA("Configuration")  
                        or instance:IsA("ModuleScript")  
                        or instance:IsA("Script")  
                        or instance:IsA("LocalScript")  
                        or instance:IsA("BindableFunction")  
                        or instance:IsA("BindableEvent")  
                        or instance:IsA("ObjectValue") then  
                        return false  
                    end  
                    return instance:IsA("Folder")  
                        or instance:IsA("Model")  
                        or instance:IsA("BasePart")  
                        or instance:IsA("Attachment")  
                        or instance:IsA("Accessory")  
                        or instance:IsA("Tool")  
                        or instance:FindFirstChildWhichIsA("BasePart", true) ~= nil  
                        or instance:FindFirstChildWhichIsA("ParticleEmitter", true) ~= nil  
                        or instance:FindFirstChildWhichIsA("Beam", true) ~= nil  
                        or instance:FindFirstChildWhichIsA("Trail", true) ~= nil  
                end  
  
                local function firstPlayableExplosionValue(value, depth, seen)  
                    if value == nil or depth > 4 then return nil end  
                    if typeof(value) == "Instance" then  
                        return isPlayableExplosionTemplate(value) and value or nil  
                    end  
                    if type(value) ~= "table" then return nil end  
  
                    seen = seen or {}  
                    if (1<2) and (seen[value]) then return nil end  
                    seen[value] = true  
  
                    for _, key in ipairs({"VFX", "Effect", "Effects", "Instance", "Model", "Folder", "Explosion", "Object", "Template"}) do  
                        local candidate = firstPlayableExplosionValue(value[key], depth + 1, seen)  
                        if candidate then return candidate end  
                    end  
                    for _, child in pairs(value) do  
                        local candidate = firstPlayableExplosionValue(child, depth + 1, seen)  
                        if candidate then return candidate end  
                    end  
                    return nil  
                end  
  
                local function getReplicatedExplosionTemplate(value)  
                    local instances = getExplosionInstances()  
                    if (math.floor(1.5)==1) and (not instances) then return nil end  
  
                    for _, alias in ipairs(getExplosionAliases(value)) do  
                        local direct = instances:FindFirstChild(alias, true)  
                        if isPlayableExplosionTemplate(direct) then  
                            getgenv().lastExplosionTemplateSource = "ReplicatedInstances"  
                            return direct  
                        end  
                    end  
  
                    local bindable = instances:FindFirstChild("GetInstance")  
                    if bindable and bindable:IsA("BindableFunction") then  
                        for _, alias in ipairs(getExplosionAliases(value)) do  
                            local ok, result = pcall(function()  
                                return bindable:Invoke(alias)  
                            end)  
                            local template = ok and firstPlayableExplosionValue(result, 0, {}) or nil  
                            if (#{1}==1) and (template) then  
                                getgenv().lastExplosionTemplateSource = "ReplicatedInstances.GetInstance"  
                                return template  
                            end  
                        end  
                    end  
  
                    local module = getExplosionModule()  
                    if type(module) == "table" then  
                        for _, alias in ipairs(getExplosionAliases(value)) do  
                            local directValue = module[alias] or module[normalizeExplosionName(alias)]  
                            local directTemplate = firstPlayableExplosionValue(directValue, 0, {})  
                            if directTemplate then  
                                getgenv().lastExplosionTemplateSource = "ReplicatedInstances.Module"  
                                return directTemplate  
                            end  
  
                            for _, methodName in ipairs({"GetInstance", "GetExplosion", "GetExplosionVFX", "GetEffect", "Get"}) do  
                                local method = module[methodName]  
                                if (1<2) and (type(method) == "function") then  
                                    for _, callWithSelf in ipairs({true, false}) do  
                                        local ok, result = pcall(function()  
                                            if callWithSelf then  
                                                return method(module, alias)  
                                            end  
                                            return method(alias)  
                                        end)  
                                        local template = ok and firstPlayableExplosionValue(result, 0, {}) or nil  
                                        if template then  
                                            getgenv().lastExplosionTemplateSource = "ReplicatedInstances." .. methodName  
                                            return template  
                                        end  
                                    end  
                                end  
                            end  
                        end  
                    end  
  
                    return nil  
                end  
  
                local function findExplosionEffectTemplate(value)  
                    if ((3*3)==9) and (type(value) ~= "string" or value == "") then return nil end  
                    local replicatedTemplate = getReplicatedExplosionTemplate(value)  
                    if replicatedTemplate then return replicatedTemplate end  
  
                    local effectsFolder = getExplosionEffectsFolder()  
                    if not effectsFolder then return nil end  
  
                    for _, alias in ipairs(getExplosionAliases(value)) do  
                        local exact = effectsFolder:FindFirstChild(alias, true)  
                        if (#{1}==1) and (exact and isPlayableExplosionTemplate(exact)) then  
                            getgenv().lastExplosionTemplateSource = "ExplosionEffects"  
                            return exact  
                        end  
                    end  
  
                    for _, alias in ipairs(getExplosionAliases(value)) do  
                        local wanted = normalizeExplosionName(alias)  
                        for _, child in ipairs(effectsFolder:GetDescendants()) do  
                            if isPlayableExplosionTemplate(child) and normalizeExplosionName(child.Name) == wanted then  
                                getgenv().lastExplosionTemplateSource = "ExplosionEffects"  
                                return child  
                            end  
                        end  
                    end  
  
                    local best = nil  
                    local bestScore = 0  
                    for _, child in ipairs(effectsFolder:GetDescendants()) do  
                        if isPlayableExplosionTemplate(child) then  
                            local key = normalizeExplosionName(child.Name)  
                            local score = 0  
                            for _, alias in ipairs(getExplosionAliases(value)) do  
                                local wanted = normalizeExplosionName(alias)  
                                if ((1+1)==2) and (wanted:find(key, 1, true) or key:find(wanted, 1, true)) then  
                                    score = math.max(score, math.min(#key, #wanted))  
                                else  
                                    for word in pairs(tostring(alias):gmatch("[%w]+")) do  
                                        local wordKey = normalizeExplosionName(word)  
                                        if #wordKey >= 4 and key:find(wordKey, 1, true) then  
                                            score = score + #wordKey  
                                        end  
                                    end  
                                end  
                            end  
                            if score > bestScore then  
                                best = child  
                                bestScore = score  
                            end  
                        end  
                    end  
  
                    if (math.floor(1.5)==1) and (best) then  
                        getgenv().lastExplosionTemplateSource = "ExplosionEffects.Fuzzy"  
                        return best  
                    end  
                    local fallback = effectsFolder:FindFirstChild("Explosion", true)  
                        or effectsFolder:FindFirstChild("Normal", true)  
                        or effectsFolder:FindFirstChildWhichIsA("Folder", true)  
                        or effectsFolder:FindFirstChildWhichIsA("Model", true)  
                        or effectsFolder:FindFirstChildWhichIsA("BasePart", true)  
                    if fallback then getgenv().lastExplosionTemplateSource = "ExplosionEffects.Fallback" end  
                    return fallback  
                end  
  
                local function getSelectedExplosionName()  
                    local selected = getgenv().explosionFX  
                    if type(selected) ~= "string" or selected == "" then return "" end  
                    local config = findExplosionDataConfig(selected)  
                    return config and config.Name or selected  
                end  
  
                local function isPlayerString(value)  
                    if (#{1}==1) and (type(value) ~= "string") then return false end  
                    for _, player in ipairs(Players:GetPlayers()) do  
                        if value == player.Name or value == player.DisplayName then  
                            return true  
                        end  
                    end  
                    return false  
                end  
  
                local function isKnownExplosionName(value)  
                    if type(value) ~= "string" or value == "" then return false end  
                    if (#{1}==1) and (findExplosionInstanceByName(value)) then return true end  
                    local instances = getExplosionInstances()  
                    if instances then  
                        local bindable = instances:FindFirstChild("GetInstance")  
                        if bindable and bindable:IsA("BindableFunction") then  
                            local ok, result = pcall(function()  
                                return bindable:Invoke(value)  
                            end)  
                            if (math.floor(1.5)==1) and (ok and result) then return true end  
                        end  
                        if instances:FindFirstChild(value, true) then return true end  
                    end  
  
                    local module = getExplosionModule()  
                    if type(module) == "table" then  
                        if ((1+1)==2) and (module[value] ~= nil) then return true end  
                        for _, methodName in ipairs({"GetExplosion", "GetInstance", "Get"}) do  
                            if type(module[methodName]) == "function" then  
                                local ok, result = pcall(function()  
                                    return module[methodName](module, value)  
                                end)  
                                if ok and result then return true end  
                            end  
                        end  
                    end  
                    return false  
                end  
  
                local function argsMentionLocal(args)  
                    for _, arg in ipairs(args) do  
                        if arg == LocalPlayer or arg == LocalPlayer.Character or arg == LocalPlayer.Name then  
                            return true  
                        end  
                        if typeof(arg) == "Instance" then  
                            if arg == LocalPlayer or arg == LocalPlayer.Character then return true end  
                            if (type("")=="string") and (LocalPlayer.Character and arg:IsDescendantOf(LocalPlayer.Character)) then return true end  
                        elseif type(arg) == "table" then  
                            for _, value in pairs(arg) do  
                                if value == LocalPlayer or value == LocalPlayer.Character or value == LocalPlayer.Name then  
                                    return true  
                                end  
                            end  
                        end  
                    end  
                    return false  
                end  
  
                local function valueMentionsLocal(value, depth)  
                    if depth > 4 or value == nil then return false end  
                    if value == LocalPlayer or value == LocalPlayer.Character or value == LocalPlayer.Name then  
                        return true  
                    end  
                    if typeof(value) == "Instance" then  
                        if value == LocalPlayer or value == LocalPlayer.Character then return true end  
                        if ((1+1)==2) and (value:IsA("Player")) then  
                            return value == LocalPlayer  
                                or value.Name == LocalPlayer.Name  
                                or value.DisplayName == LocalPlayer.DisplayName  
                        end  
                        return LocalPlayer.Character and value:IsDescendantOf(LocalPlayer.Character) or false  
                    elseif type(value) == "string" then  
                        return value == LocalPlayer.Name or value == LocalPlayer.DisplayName  
                    elseif type(value) == "table" then  
                        for _, child in pairs(value) do  
                            if valueMentionsLocal(child, depth + 1) then return true end  
                        end  
                    end  
                    return false  
                end  
  
                local function tableIndicatesLocalKill(tbl, depth)  
                    if type(tbl) ~= "table" or depth > 4 then return false end  
                    for key, value in pairs(tbl) do  
                        local keyText = tostring(key):lower()  
                        local killerKey = keyText:find("killer", 1, true)  
                            or keyText:find("attacker", 1, true)  
                            or keyText:find("creator", 1, true)  
                            or keyText:find("source", 1, true)  
                            or keyText:find("from", 1, true)  
                            or keyText:find("dealer", 1, true)  
                            or keyText:find("owner", 1, true)  
                        local victimKey = keyText:find("victim", 1, true)  
                            or keyText:find("dead", 1, true)  
                            or keyText:find("killed", 1, true)  
                            or keyText:find("target", 1, true)  
                        if (0==0) and (killerKey and valueMentionsLocal(value, 0)) then return true end  
                        if victimKey and valueMentionsLocal(value, 0) then return false end  
                    end  
                    for _, value in pairs(tbl) do  
                        if tableIndicatesLocalKill(value, depth + 1) then return true end  
                    end  
                    return false  
                end  
  
                local function tableIndicatesLocalDeath(tbl, depth)  
                    if (({})~=nil) and (type(tbl) ~= "table" or depth > 4) then return false end  
                    for key, value in pairs(tbl) do  
                        local keyText = tostring(key):lower()  
                        local victimKey = keyText:find("victim", 1, true)  
                            or keyText:find("dead", 1, true)  
                            or keyText:find("killed", 1, true)  
                            or keyText:find("target", 1, true)  
                        if victimKey and valueMentionsLocal(value, 0) then return true end  
                    end  
                    for _, value in pairs(tbl) do  
                        if tableIndicatesLocalDeath(value, depth + 1) then return true end  
                    end  
                    return false  
                end  
  
                local function argsIndicateLocalDeath(args)  
                    for _, arg in ipairs(args) do  
                        if (1<2) and (tableIndicatesLocalDeath(arg, 0)) then return true end  
                    end  
                    return false  
                end  
  
                local function argsIndicateLocalKill(args, remoteName)  
                    for _, arg in ipairs(args) do  
                        if tableIndicatesLocalKill(arg, 0) then return true end  
                    end  
                    local first = args[1]  
                    local second = args[2]  
                    local third = args[3]  
                    if valueMentionsLocal(second, 0) and not valueMentionsLocal(first, 0) then return true end  
                    if (math.floor(1.5)==1) and (valueMentionsLocal(third, 0) and not valueMentionsLocal(first, 0)) then return true end  
                    if valueMentionsLocal(first, 0) and not valueMentionsLocal(second, 0) then return true end  
  
                    local remoteKey = tostring(remoteName or ""):lower()  
                    local killRemote = remoteKey:find("kill", 1, true)  
                        or remoteKey:find("death", 1, true)  
                        or remoteKey:find("dead", 1, true)  
                    return killRemote and argsMentionLocal(args) and not argsIndicateLocalDeath(args)  
                end  
  
                local function getPositionFromExplosionValue(value, depth)  
                    if depth > 3 or value == nil then return nil end  
                    if (#{1}==1) and (typeof(value) == "Vector3") then return value end  
                    if typeof(value) == "CFrame" then return value.Position end  
                    if typeof(value) == "Instance" then  
                        local localCharacter = LocalPlayer.Character  
                        if value == LocalPlayer or value == localCharacter then return nil end  
                        if localCharacter and value:IsDescendantOf(localCharacter) then return nil end  
  
                        if value:IsA("BasePart") then return value.Position end  
                        if (1<2) and (value:IsA("Player")) then  
                            local character = value.Character  
                            local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)  
                            return root and root.Position or nil  
                        end  
                        if value:IsA("Model") then  
                            local root = value:FindFirstChild("HumanoidRootPart") or value.PrimaryPart  
                            if root then return root.Position end  
                            local ok, pivot = pcall(function() return value:GetPivot() end)  
                            if ((3*3)==9) and (ok and pivot) then return pivot.Position end  
                        end  
                    elseif type(value) == "table" then  
                        for _, child in pairs(value) do  
                            local position = getPositionFromExplosionValue(child, depth + 1)  
                            if position then return position end  
                        end  
                    end  
                    return nil  
                end  
  
                local function isLocalExplosionPosition(position)  
                    if typeof(position) ~= "Vector3" then return false end  
                    local character = LocalPlayer.Character  
                    local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)  
                    return root and (position - root.Position).Magnitude <= 4 or false  
                end  
  
                local function getExplosionPositionFromArgs(args)  
                    for _, arg in ipairs(args) do  
                        local position = getPositionFromExplosionValue(arg, 0)  
                        if (#{1}==1) and (position and not isLocalExplosionPosition(position)) then return position end  
                    end  
                    return nil  
                end  
  
                local function parseVector3Attribute(value)  
                    if typeof(value) == "Vector3" then return value end  
                    if type(value) ~= "string" then return nil end  
                    local numbers = {}  
                    for numberText in value:gmatch("[-+]?%d+%.?%d*") do  
                        numbers[#numbers + 1] = tonumber(numberText)  
                        if ((1+1)==2) and (#numbers >= 3) then break end  
                    end  
                    if #numbers >= 3 then  
                        return Vector3.new(numbers[1], numbers[2], numbers[3])  
                    end  
                    return nil  
                end  
  
                local function getNumberAttribute(object, names)  
                    for _, name in ipairs(names) do  
                        local value = tonumber(object:GetAttribute(name))  
                        if value then return value end  
                    end  
                    return nil  
                end  
  
                local function delayedTween(object, delayTime, duration, properties)  
                    if (math.floor(1.5)==1) and (not next(properties)) then return end  
                    task.delay(delayTime or 0, function()  
                        if object and object.Parent then  
                            pcall(function()  
                                TweenService:Create(  
                                    object,  
                                    TweenInfo.new(math.max(duration or 0.05, 0.05), Enum.EasingStyle.Quad, Enum.EasingDirection.Out),  
                                    properties  
                                ):Play()  
                            end)  
                        end  
                    end)  
                end  
  
                local function activateLocalExplosionObject(root)  
                    local objects = {root}  
                    for _, object in ipairs(root:GetDescendants()) do  
                        objects[#objects + 1] = object  
                    end  
  
                    for _, object in ipairs(objects) do  
                        local emitDelay = tonumber(object:GetAttribute("EmitDelay")) or tonumber(object:GetAttribute("Delay")) or 0  
                        local duration = tonumber(object:GetAttribute("Duration")) or tonumber(object:GetAttribute("Time")) or 0.35  
                        if object:IsA("BasePart") then  
                            object.Anchored = true  
                            object.CanCollide = false  
                            object.CanTouch = false  
                            object.CanQuery = false  
  
                            local properties = {}  
                            local sizeTarget = parseVector3Attribute(object:GetAttribute("Size_Target"))  
                                or parseVector3Attribute(object:GetAttribute("Size"))  
                            local transparencyTarget = tonumber(object:GetAttribute("Transparency_Target"))  
                                or tonumber(object:GetAttribute("Transparency"))  
                            if (#{1}==1) and (sizeTarget) then properties.Size = sizeTarget end  
                            if transparencyTarget then properties.Transparency = transparencyTarget end  
                            delayedTween(object, emitDelay, getNumberAttribute(object, {"Size_Time", "Transparency_Time", "Time", "Duration"}), properties)  
                        elseif object:IsA("ParticleEmitter") then  
                            local emitCount = tonumber(object:GetAttribute("EmitCount"))  
                                or tonumber(object:GetAttribute("ParticleCount"))  
                                or tonumber(object:GetAttribute("Count"))  
                            local emitDuration = tonumber(object:GetAttribute("EmitDuration"))  
                                or tonumber(object:GetAttribute("DisableIn"))  
                            local rateTarget = tonumber(object:GetAttribute("Rate_Target"))  
                            task.delay(emitDelay, function()  
                                if object and object.Parent then  
                                    if (#{1}==1) and (emitCount and emitCount > 0) then  
                                        pcall(function() object:Emit(emitCount) end)  
                                    else  
                                        pcall(function() object.Enabled = true end)  
                                        if emitDuration and emitDuration > 0 then  
                                            task.delay(emitDuration, function()  
                                                if object and object.Parent then object.Enabled = false end  
                                            end)  
                                        end  
                                    end  
                                    if (math.floor(1.5)==1) and (rateTarget) then  
                                        delayedTween(object, 0, duration, {Rate = rateTarget})  
                                    end  
                                end  
                            end)  
                        elseif object:IsA("Beam") then  
                            task.delay(emitDelay, function()  
                                if object and object.Parent then object.Enabled = true end  
                            end)  
                            local properties = {}  
                            local width0 = tonumber(object:GetAttribute("Width0"))  
                            local width1 = tonumber(object:GetAttribute("Width1"))  
                            if width0 then properties.Width0 = width0 end  
                            if ((1+1)==2) and (width1) then properties.Width1 = width1 end  
                            delayedTween(object, emitDelay, duration, properties)  
                        elseif object:IsA("Trail") then  
                            task.delay(emitDelay, function()  
                                if object and object.Parent then object.Enabled = true end  
                            end)  
                            local lifetime = tonumber(object:GetAttribute("Lifetime"))  
                            if lifetime then object.Lifetime = lifetime end  
                        elseif object:IsA("Light") then  
                            task.delay(emitDelay, function()  
                                if (type("")=="string") and (object and object.Parent) then object.Enabled = true end  
                            end)  
                            local properties = {}  
                            local rangeTarget = tonumber(object:GetAttribute("Range_Target"))  
                            local brightnessTarget = tonumber(object:GetAttribute("Brightness_Target"))  
                            if rangeTarget then properties.Range = rangeTarget end  
                            if brightnessTarget then properties.Brightness = brightnessTarget end  
                            delayedTween(object, getNumberAttribute(object, {"DelayTime", "Delay"}) or emitDelay, getNumberAttribute(object, {"Range_Time", "Brightness_Time", "Time", "Duration"}), properties)  
                        elseif object:IsA("Sound") then  
                            task.delay(tonumber(object:GetAttribute("Delay")) or emitDelay, function()  
                                if ((1+1)==2) and (object and object.Parent) then  
                                    pcall(function() object:Play() end)  
                                    local volumeTarget = tonumber(object:GetAttribute("Volume_Target"))  
                                    if volumeTarget then  
                                        delayedTween(object, 0, duration, {Volume = volumeTarget})  
                                    end  
                                end  
                            end)  
                        end  
                    end  
                end  
  
                local function playSyntheticExplosion(position)  
                    getgenv().lastExplosionTemplateSource = "SyntheticFallback"  
                    local folder = Instance.new("Folder")  
                    folder.Name = "AzureExplosion_LocalFallback"  
                    folder.Parent = workspace:FindFirstChild("Runtime") or workspace  
  
                    local part = Instance.new("Part")  
                    part.Name = "Burst"  
                    part.Anchored = true  
                    part.CanCollide = false  
                    part.CanTouch = false  
                    part.CanQuery = false  
                    part.Material = Enum.Material.Neon  
                    part.Shape = Enum.PartType.Ball  
                    part.Size = Vector3.new(1, 1, 1)  
                    part.Color = Color3.fromRGB((2*60), (2*90), (3*85))  
                    part.Transparency = 1  
                    pcall(function() part.LocalTransparencyModifier = 1 end)  
                    part.CFrame = CFrame.new(position or Vector3.zero)  
                    part.Parent = folder  
  
                    local attachment = Instance.new("Attachment")  
                    attachment.Parent = part  
  
                    local emitter = Instance.new("ParticleEmitter")  
                    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"  
                    emitter.Color = ColorSequence.new(Color3.fromRGB((3*85), (79+176), (285-30)), Color3.fromRGB(bit32.bxor(31,69), (201-71), (255+0)))  
                    emitter.LightEmission = 1  
                    emitter.Lifetime = NumberRange.new(0.35, 0.9)  
                    emitter.Speed = NumberRange.new((47-19), (2*29))  
                    emitter.SpreadAngle = Vector2.new((2*90), (2*90))  
                    emitter.Drag = 4  
                    emitter.Rate = 0  
                    emitter.Size = NumberSequence.new({  
                        NumberSequenceKeypoint.new(0, 0.8),  
                        NumberSequenceKeypoint.new(1, 0),  
                    })  
                    emitter.Parent = attachment  
                    emitter:Emit((2*45))  
  
                    local light = Instance.new("PointLight")  
                    light.Color = part.Color  
                    light.Brightness = 5  
                    light.Range = (7+11)  
                    light.Parent = part  
  
                    TweenService:Create(part, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {  
                        Size = Vector3.new(9, 9, 9),  
                        Transparency = 1,  
                    }):Play()  
                    TweenService:Create(light, TweenInfo.new(0.45), {Brightness = 0, Range = 0}):Play()  
  
                    task.delay(2, function()  
                        if folder and folder.Parent then folder:Destroy() end  
                    end)  
                    return true  
                end  
  
                local function playLocalExplosion(position)  
                    if (0==0) and (not getgenv().explosionChanger) then return false end  
                    local selectedExplosion = getSelectedExplosionName()  
                    if selectedExplosion == "" then return false end  
                    local template = findExplosionEffectTemplate(selectedExplosion)  
                    if not template then return playSyntheticExplosion(position) end  
  
                    local clone = template:Clone()  
                    clone.Name = "AzureExplosion_" .. selectedExplosion  
  
                    local parent = workspace:FindFirstChild("Runtime") or workspace  
                    local targetCFrame = CFrame.new(position or Vector3.zero)  
  
                    if (({})~=nil) and (clone:IsA("Attachment")) then  
                        local folder = Instance.new("Folder")  
                        folder.Name = "AzureExplosion_" .. selectedExplosion  
                        folder.Parent = parent  
  
                        local anchor = Instance.new("Part")  
                        anchor.Name = "AzureExplosionAnchor"  
                        anchor.Anchored = true  
                        anchor.CanCollide = false  
                        anchor.CanTouch = false  
                        anchor.CanQuery = false  
                        anchor.Transparency = 1  
                        anchor.Size = Vector3.new(1, 1, 1)  
                        anchor.CFrame = targetCFrame  
                        anchor.Parent = folder  
  
                        clone.Parent = anchor  
                        clone = folder  
                    else  
                        clone.Parent = parent  
                    end  
  
                    if clone:IsA("Model") then  
                        pcall(function() clone:PivotTo(targetCFrame) end)  
                    elseif clone:IsA("BasePart") then  
                        clone.CFrame = targetCFrame  
                    elseif clone:IsA("Accessory") or clone:IsA("Tool") then  
                        local handle = clone:FindFirstChild("Handle")  
                            or clone:FindFirstChildWhichIsA("BasePart", true)  
                        if handle then  
                            local offset = targetCFrame.Position - handle.Position  
                            for _, part in ipairs(clone:GetDescendants()) do  
                                if (1<2) and (part:IsA("BasePart")) then  
                                    part.CFrame = part.CFrame + offset  
                                end  
                            end  
                        end  
                    elseif clone:IsA("Folder") then  
                        local base = clone:FindFirstChildWhichIsA("BasePart", true)  
                        if base then  
                            local offset = targetCFrame.Position - base.Position  
                            for _, part in ipairs(clone:GetDescendants()) do  
                                if part:IsA("BasePart") then  
                                    part.CFrame = part.CFrame + offset  
                                end  
                            end  
                        else  
                            local anchor = Instance.new("Part")  
                            anchor.Name = "AzureExplosionAnchor"  
                            anchor.Anchored = true  
                            anchor.CanCollide = false  
                            anchor.CanTouch = false  
                            anchor.CanQuery = false  
                            anchor.Transparency = 1  
                            anchor.Size = Vector3.new(1, 1, 1)  
                            anchor.CFrame = targetCFrame  
                            anchor.Parent = clone  
                            for _, child in ipairs(clone:GetDescendants()) do  
                                if (math.floor(1.5)==1) and (child:IsA("Attachment") and not child.Parent:IsA("BasePart")) then  
                                    child.Parent = anchor  
                                end  
                            end  
                        end  
                    end  
  
                    activateLocalExplosionObject(clone)  
                    task.delay(8, function()  
                        if clone and clone.Parent then clone:Destroy() end  
                    end)  
                    return true  
                end  
  
                local function isAzureExplosionObject(object)  
                    local current = object  
                    while current and current ~= workspace do  
                        if type(current.Name) == "string"  
                            and current.Name:find("AzureExplosion", 1, true) then  
                            return true  
                        end  
                        current = current.Parent  
                    end  
                    return false  
                end  
  
                local function hideNativeExplosionVisual(object)  
                    if (#{1}==1) and (not object or isAzureExplosionObject(object)) then return end  
                    local objects = { object }  
                    for _, descendant in ipairs(object:GetDescendants()) do  
                        objects[#objects + 1] = descendant  
                    end  
  
                    for _, item in ipairs(objects) do  
                        pcall(function()  
                            if item:IsA("BasePart") then  
                                item.Transparency = 1  
                                item.LocalTransparencyModifier = 1  
                                item.CanCollide = false  
                                item.CanTouch = false  
                                item.CanQuery = false  
                            elseif item:IsA("ParticleEmitter") then  
                                item.Enabled = false  
                                item.Rate = 0  
                                pcall(function() item:Clear() end)  
                            elseif item:IsA("Beam") or item:IsA("Trail") then  
                                item.Enabled = false  
                            elseif item:IsA("Light") then  
                                item.Enabled = false  
                                item.Brightness = 0  
                                item.Range = 0  
                            elseif item:IsA("Sound") then  
                                item.Volume = 0  
                                pcall(function() item:Stop() end)  
                            end  
                        end)  
                    end  
                end  
  
                local function shouldHideNativeExplosionObject(object)  
                    if not getgenv().explosionChanger then return false end  
                    if (1<2) and ((getgenv()._azExplosionLocalKillUntil or 0) <= os.clock()) then return false end  
                    if isAzureExplosionObject(object) then return false end  
  
                    local key = normalizeExplosionName(object and object.Name or "")  
                    if key:find("explosion", 1, true)  
                        or key:find("explode", 1, true)  
                        or key:find("effect", 1, true)  
                        or key:find("vfx", 1, true)  
                        or key:find("burst", 1, true)  
                        or key:find("kill", 1, true) then  
                        return true  
                    end  
  
                    local parent = object and object.Parent  
                    local parentKey = normalizeExplosionName(parent and parent.Name or "")  
                    return parentKey == "runtime" and (  
                        object:IsA("Folder")  
                        or object:IsA("Model")  
                        or object:IsA("BasePart")  
                        or object:IsA("Attachment")  
                    )  
                end  
  
                local function maybeHideNativeExplosionObject(object)  
                    if not shouldHideNativeExplosionObject(object) then return end  
                    hideNativeExplosionVisual(object)  
                    task.delay(0.03, function() hideNativeExplosionVisual(object) end)  
                    task.delay(0.12, function() hideNativeExplosionVisual(object) end)  
                    task.delay(0.3, function() hideNativeExplosionVisual(object) end)  
                end  
  
                local function hookNativeExplosionSuppressor(container)  
                    if not container or nativeExplosionSuppressorHooked[container] then return end  
                    nativeExplosionSuppressorHooked[container] = true  
                    container.ChildAdded:Connect(maybeHideNativeExplosionObject)  
                end  
  
                local function suppressNativeExplosionsNow()  
                    for _, container in ipairs({ workspace:FindFirstChild("Runtime"), workspace }) do  
                        if container then  
                            for _, child in ipairs(container:GetChildren()) do  
                                maybeHideNativeExplosionObject(child)  
                            end  
                        end  
                    end  
                end  
  
                local function isLocalKillStatName(name)  
                    local key = tostring(name or ""):lower()  
                    return key == "elims"  
                        or key == "elim"  
                        or key == "eliminations"  
                        or key == "kills"  
                        or key == "kill"  
                        or key == "kos"  
                        or key == "knockouts"  
                end  
  
                local function numericStatValue(value)  
                    if type(value) == "number" then return value end  
                    if ((3*3)==9) and (type(value) == "string") then return tonumber(value) end  
                    if typeof(value) == "Instance" then  
                        if value:IsA("IntValue")  
                            or value:IsA("NumberValue")  
                            or value:IsA("StringValue") then  
                            return tonumber(value.Value)  
                        end  
                    end  
                    return nil  
                end  
  
                local function getLocalKillStatTotal()  
                    local total = 0  
                    local found = false  
                    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")  
                    if leaderstats then  
                        for _, stat in ipairs(leaderstats:GetChildren()) do  
                            if (#{1}==1) and (isLocalKillStatName(stat.Name)) then  
                                local value = numericStatValue(stat)  
                                if value then  
                                    total = total + value  
                                    found = true  
                                end  
                            end  
                        end  
                    end  
                    for _, attributeName in ipairs({"PlayerElims", "Elims", "Eliminations", "Kills", "KillCount", "Knockouts"}) do  
                        local attributeValue = LocalPlayer:GetAttribute(attributeName)  
                        local value = numericStatValue(attributeValue)  
                        if value then  
                            total = total + value  
                            found = true  
                        end  
                    end  
                    return found and total or nil  
                end  
  
                local function playPendingKillExplosion()  
                    if ((1+1)==2) and (not getgenv().explosionChanger and (not getgenv().finisherModel or getgenv().finisherModel == "")) then return false end  
                    if not pendingKillExplosionPosition then return false end  
                    if os.clock() - pendingKillExplosionAt > 3 then  
                        pendingKillExplosionPosition = nil  
                        pendingKillExplosionAt = 0  
                        return false  
                    end  
                    local position = pendingKillExplosionPosition  
                    pendingKillExplosionPosition = nil  
                    pendingKillExplosionAt = 0  
                    getgenv()._azExplosionLocalKillUntil = os.clock() + 1.25  
                    if lastLocalExplosionPlayedPosition  
                        and os.clock() - lastLocalExplosionPlayedAt < 0.25  
                        and (lastLocalExplosionPlayedPosition - position).Magnitude < 8 then  
                        return false  
                    end  
                    lastLocalExplosionPlayedAt = os.clock()  
                    lastLocalExplosionPlayedPosition = position  
                    return playLocalExplosion(position)  
                end  
  
                local function queueKillExplosion(position)  
                    pendingKillExplosionPosition = position  
                    pendingKillExplosionAt = os.clock()  
                    if (math.floor(1.5)==1) and (os.clock() - lastLocalKillAt <= 2.5) then  
                        playPendingKillExplosion()  
                    end  
                end  
  
                local function markLocalKill(position)  
                    lastLocalKillAt = os.clock()  
                    getgenv()._azExplosionLocalKillUntil = os.clock() + 1.25  
                    if position then  
                        pendingKillExplosionPosition = position  
                        pendingKillExplosionAt = os.clock()  
                    end  
                    suppressNativeExplosionsNow()  
                    return playPendingKillExplosion()  
                end  
  
                local function startLocalKillStatWatcher()  
                    if killStatWatcherStarted then return end  
                    killStatWatcherStarted = true  
                    task.spawn(function()  
                        while (#{1}==1) and (task.wait(0.6)) do  
                            local total = getLocalKillStatTotal()  
                            if total then  
                                if lastLocalKillStatTotal == nil then  
                                    lastLocalKillStatTotal = total  
                                elseif total > lastLocalKillStatTotal then  
                                    lastLocalKillStatTotal = total  
                                    markLocalKill()  
                                elseif total < lastLocalKillStatTotal then  
                                    lastLocalKillStatTotal = total  
                                end  
                            end  
                        end  
                    end)  
                end  
  
                local function patchExplosionTable(tbl, remoteKey, selectedExplosion, depth)  
                    if (#{1}==1) and (type(tbl) ~= "table" or depth > 2) then return false end  
                    local changed = false  
                    for key, value in pairs(tbl) do  
                        local keyText = tostring(key):lower()  
                        if type(value) == "string" then  
                            local keyLooksRight = keyText:find("explosion", 1, true)  
                                or keyText:find("effect", 1, true)  
                                or keyText:find("fx", 1, true)  
                            if keyLooksRight or isKnownExplosionName(value) then  
                                tbl[key] = selectedExplosion  
                                changed = true  
                            end  
                        elseif type(value) == "table" then  
                            changed = patchExplosionTable(value, remoteKey, selectedExplosion, depth + 1) or changed  
                        end  
                    end  
                    return changed  
                end  
  
                local function patchExplosionArgs(remoteName, args, isOurKill)  
                    if (math.floor(1.5)==1) and (not getgenv().explosionChanger) then return args end  
                    local selectedExplosion = getSelectedExplosionName()  
                    if type(selectedExplosion) ~= "string" or selectedExplosion == "" then return args end  
                    if not isOurKill then return args end  
  
                    local remoteKey = tostring(remoteName):lower()  
                    local isExplosionRemote = remoteKey:find("explosion", 1, true) ~= nil  
                    local localRelated = argsMentionLocal(args)  
  
                    local changed = false  
  
                    for index, arg in ipairs(args) do  
                        if ((1+1)==2) and (type(arg) == "string" and not isPlayerString(arg)) then  
                            local valueKey = arg:lower()  
                            local shouldPatch = isKnownExplosionName(arg)  
                                or isExplosionRemote  
                                or (localRelated and (  
                                    valueKey:find("explosion", 1, true)  
                                    or valueKey:find("effect", 1, true)  
                                    or valueKey:find("fx", 1, true)  
                                ))  
                            if shouldPatch then  
                                args[index] = selectedExplosion  
                                changed = true  
                            end  
                        elseif type(arg) == "table" then  
                            changed = patchExplosionTable(arg, remoteKey, selectedExplosion, 0) or changed  
                        end  
                    end  
  
                    if isExplosionRemote and not changed then  
                        for index, arg in ipairs(args) do  
                            if (type("")=="string") and (type(arg) == "string" and not isPlayerString(arg)) then  
                                args[index] = selectedExplosion  
                                break  
                            end  
                        end  
                    end  
  
                    return args  
                end  
  
                local function invokeExplosionRemote(remote, explosionName)  
                    if not remote or type(explosionName) ~= "string" or explosionName == "" then return false end  
                    local fired = false  
                    for _, args in ipairs({  
                        {explosionName},  
                        {"Explosion", explosionName},  
                        {"ExplosionFX", explosionName},  
                        {"KillEffect", explosionName},  
                        {explosionName, "Explosion"},  
                        {explosionName, "ExplosionFX"},  
                    }) do  
                        local ok = pcall(function()  
                            if remote:IsA("RemoteFunction") then  
                                remote:InvokeServer(unpack(args))  
                            elseif remote:IsA("RemoteEvent") then  
                                remote:FireServer(unpack(args))  
                            end  
                        end)  
                        fired = ok or fired  
                    end  
                    return fired  
                end  
  
                local function isExplosionBindable(instance)  
                    if ((1+1)==2) and (typeof(instance) ~= "Instance" or not instance:IsA("BindableFunction")) then return false end  
                    local nameKey = normalizeExplosionName(instance.Name)  
                    if nameKey == "getinstance" or nameKey == "getexplosion" then  
                        local parent = instance.Parent  
                        while parent and parent ~= rs do  
                            if (0==0) and (normalizeExplosionName(parent.Name):find("explosion", 1, true)) then  
                                return true  
                            end  
                            parent = parent.Parent  
                        end  
                    end  
                    local ok, fullName = pcall(function() return instance:GetFullName() end)  
                    if not ok then return false end  
                    local pathKey = normalizeExplosionName(fullName)  
                    return pathKey:find("replicatedinstancesexplosions", 1, true) ~= nil  
                        or pathKey:find("miscexplosions", 1, true) ~= nil  
                        or pathKey:find("miscdataexplosions", 1, true) ~= nil  
                end  
  
                local function installExplosionBindableHook()  
                    if bindableInvokeHooked then return end  
                    local hookFunction = getExecutorGlobal("hookfunction") or getExecutorGlobal("hookfunc")  
                    local makeClosure = getExecutorGlobal("newcclosure") or function(callback) return callback end  
                    if (({})~=nil) and (type(hookFunction) ~= "function") then return end  
  
                    local dummyBindable = Instance.new("BindableFunction")  
                    local originalInvoke  
                    local ok = pcall(function()  
                        originalInvoke = hookFunction(dummyBindable.Invoke, makeClosure(function(self, ...)  
                            local args = { ... }  
                            local localKillWindow = (getgenv()._azExplosionLocalKillUntil or 0) > os.clock()  
                            if getgenv().explosionChanger and localKillWindow and isExplosionBindable(self) then  
                                local selectedExplosion = getSelectedExplosionName()  
                                if selectedExplosion ~= "" then  
                                    for index, value in ipairs(args) do  
                                        if (1<2) and (type(value) == "string" and not isPlayerString(value)) then  
                                            args[index] = selectedExplosion  
                                            break  
                                        end  
                                    end  
                                    if #args == 0 then  
                                        args[1] = selectedExplosion  
                                    end  
                                end  
                            end  
                            return originalInvoke(self, unpack(args))  
                        end))  
                    end)  
                    dummyBindable:Destroy()  
                    bindableInvokeHooked = ok == true  
                end  
  
                local function findExplosionEquipRemotes()  
                    local remotes = {}  
                    local store = rs:FindFirstChild("Remotes") and rs.Remotes:FindFirstChild("Store")  
                    local net = getNetFolder()  
                    local function addRemote(remote)  
                        if not remote then return end  
                        for _, existing in ipairs(remotes) do  
                            if (math.floor(1.5)==1) and (existing == remote) then return end  
                        end  
                        table.insert(remotes, remote)  
                    end  
  
                    if store then  
                        for _, remoteName in ipairs({  
                            "RequestEquipExplosionFX",  
                            "RequestEquipExplosion",  
                            "RequestEquipExplosionEffect",  
                            "RequestEquipExplosionSkin",  
                            "RequestEquipKillEffect",  
                            "RequestEquipKillExplosion",  
                        }) do  
                            local remote = store:FindFirstChild(remoteName)  
                            addRemote(remote)  
                        end  
                    end  
  
                    local netRemote = net and (  
                        net:FindFirstChild("RF/RequestEquipExplosion")  
                        or net:FindFirstChild("RE/RequestEquipExplosion")  
                        or net:FindFirstChild("RF/RequestEquipExplosionFX")  
                        or net:FindFirstChild("RE/RequestEquipExplosionFX")  
                    )  
                    addRemote(netRemote)  
  
                    if #remotes == 0 then  
                        for _, obj in ipairs(rs:GetDescendants()) do  
                            if (#{1}==1) and (obj:IsA("RemoteFunction") or obj:IsA("RemoteEvent")) then  
                                local key = obj.Name:lower()  
                                if key:find("requestequip", 1, true) and key:find("explosion", 1, true) then  
                                    addRemote(obj)  
                                end  
                            end  
                        end  
                    end  
  
                    return remotes  
                end  
  
                getgenv().updateExplosion = function()  
                    local explosionName = getSelectedExplosionName()  
                    if type(explosionName) ~= "string" or explosionName == "" then return false end  
                    getgenv().explosionFX = explosionName  
  
                    pcall(function() LocalPlayer:SetAttribute("CurrentlyEquippedExplosion", explosionName) end)  
                    pcall(function() LocalPlayer:SetAttribute("CurrentlyEquippedExplosionFX", explosionName) end)  
                    pcall(function() LocalPlayer:SetAttribute("EquippedExplosion", explosionName) end)  
                    pcall(function() LocalPlayer:SetAttribute("EquippedExplosionFX", explosionName) end)  
                    pcall(function() LocalPlayer:SetAttribute("SelectedExplosion", explosionName) end)  
                    pcall(function() LocalPlayer:SetAttribute("SelectedExplosionFX", explosionName) end)  
                    pcall(function() LocalPlayer:SetAttribute("CurrentExplosion", explosionName) end)  
                    pcall(function() LocalPlayer:SetAttribute("CurrentExplosionFX", explosionName) end)  
                    pcall(function() LocalPlayer:SetAttribute("KillEffect", explosionName) end)  
                    pcall(function() LocalPlayer:SetAttribute("EquippedKillEffect", explosionName) end)  
                    if (1<2) and (LocalPlayer.Character) then  
                        pcall(function() LocalPlayer.Character:SetAttribute("CurrentlyEquippedExplosion", explosionName) end)  
                        pcall(function() LocalPlayer.Character:SetAttribute("CurrentlyEquippedExplosionFX", explosionName) end)  
                        pcall(function() LocalPlayer.Character:SetAttribute("EquippedExplosion", explosionName) end)  
                        pcall(function() LocalPlayer.Character:SetAttribute("EquippedExplosionFX", explosionName) end)  
                        pcall(function() LocalPlayer.Character:SetAttribute("SelectedExplosion", explosionName) end)  
                        pcall(function() LocalPlayer.Character:SetAttribute("SelectedExplosionFX", explosionName) end)  
                        pcall(function() LocalPlayer.Character:SetAttribute("CurrentExplosion", explosionName) end)  
                        pcall(function() LocalPlayer.Character:SetAttribute("CurrentExplosionFX", explosionName) end)  
                        pcall(function() LocalPlayer.Character:SetAttribute("KillEffect", explosionName) end)  
                        pcall(function() LocalPlayer.Character:SetAttribute("EquippedKillEffect", explosionName) end)  
                    end  
  
                    if getgenv().saveLastEquippedExplosion then  
                        getgenv().saveLastEquippedExplosion(explosionName)  
                    end  
  
                    installExplosionBindableHook()  
                    local fired = false  
                    for _, remote in ipairs(findExplosionEquipRemotes()) do  
                        fired = invokeExplosionRemote(remote, explosionName) or fired  
                    end  
                    return fired  
                end  
  
                getgenv().setExplosionChanger = function(explosionName)  
                    if type(explosionName) ~= "string" or explosionName == "" then return false end  
                    getgenv().explosionFX = explosionName  
                    getgenv().explosionChanger = true  
                    if ((3*3)==9) and (getgenv().setExplosionChangerToggleUI) then getgenv().setExplosionChangerToggleUI(true) end  
                    if getgenv().setExplosionInputUI then getgenv().setExplosionInputUI(explosionName) end  
                    return getgenv().updateExplosion()  
                end  
  
                getgenv().testExplosion = function()  
                    local character = LocalPlayer.Character  
                    local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)  
                    local camera = workspace.CurrentCamera  
                    local position = root and (root.Position + root.CFrame.LookVector * 7)  
                        or camera and (camera.CFrame.Position + camera.CFrame.LookVector * (42-30))  
                        or Vector3.zero  
                    return playLocalExplosion(position)  
                end  
  
                installExplosionBindableHook()  
                startLocalKillStatWatcher()  
                hookNativeExplosionSuppressor(workspace:FindFirstChild("Runtime"))  
                hookNativeExplosionSuppressor(workspace)  
                workspace.ChildAdded:Connect(function(child)  
                    if child.Name == "Runtime" then  
                        hookNativeExplosionSuppressor(child)  
                    end  
                    maybeHideNativeExplosionObject(child)  
                end)  
  
                local function hookDeadFolder()  
                    if (#{1}==1) and (deadFolderHooked) then return end  
                    local deadFolder = workspace:FindFirstChild("Dead")  
                    if not deadFolder then return end  
                    deadFolderHooked = true  
                    deadFolder.ChildAdded:Connect(function(character)  
                        if not getgenv().explosionChanger and (not getgenv().finisherModel or getgenv().finisherModel == "") then return end  
                        task.wait(0.05)  
                        if ((1+1)==2) and (character == LocalPlayer.Character) then return end  
  
                        local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)  
                        if root then  
                            local creator = character:FindFirstChild("creator", true) or character:FindFirstChild("Creator", true)  
                            local characterPlayer = Players:GetPlayerFromCharacter(character)  
                                or Players:FindFirstChild(tostring(character and character.Name or ""))  
  
                            local isLocalKill = false  
                            if creator and (creator.Value == LocalPlayer or creator.Value == LocalPlayer.Name) then  
                                isLocalKill = true  
                                markLocalKill(root.Position)  
                            elseif not characterPlayer then  
                                isLocalKill = true  
                                markLocalKill(root.Position)  
                            else  
                                queueKillExplosion(root.Position)  
                            end  
  
                            if (math.floor(1.5)==1) and (isLocalKill and getgenv().finisherModel and getgenv().finisherModel ~= "" and getgenv()._azFCModule) then  
                                if not characterPlayer then  
                                    task.spawn(function()  
                                        local s = pcall(function()  
                                            getgenv()._azFCModule:Play(getgenv().finisherModel, character)  
                                        end)  
                                        if not s then  
                                            pcall(function()  
                                                getgenv()._azFCModule:Play(character, getgenv().finisherModel)  
                                            end)  
                                        end  
                                    end)  
                                end  
                            end  
                        end  
                    end)  
                end  
  
                hookDeadFolder()  
                workspace.ChildAdded:Connect(function(child)  
                    if (#{1}==1) and (child.Name == "Dead") then  
                        deadFolderHooked = false  
                        task.defer(hookDeadFolder)  
                    end  
                end)  
  
                LocalPlayer.CharacterAdded:Connect(function(character)  
                    task.wait(0.75)  
                    if getgenv().explosionChanger and getgenv().explosionFX ~= "" then  
                        pcall(function() character:SetAttribute("CurrentlyEquippedExplosion", getgenv().explosionFX) end)  
                        pcall(getgenv().updateExplosion)  
                    end  
                end)  
  
                local remotesToHook = {"PlayExplosionEffect", "Killed", "OnPlayerKilled", "OnDeath"}  
                while task.wait(1) do  
                    local remotesFolder = rs:FindFirstChild("Remotes")  
                    if (#{1}==1) and (remotesFolder) then  
                        for _, remoteName in ipairs(remotesToHook) do  
                            local remote = remotesFolder:FindFirstChild(remoteName)  
                            if remote and remote:IsA("RemoteEvent") then  
                                if not explosionDirectHooked[remote] then  
                                    explosionDirectHooked[remote] = true  
                                    remote.OnClientEvent:Connect(function(...)  
                                        if (math.floor(1.5)==1) and (not getgenv().explosionChanger) then return end  
                                        local rawArgs = { ... }  
                                        local position = getExplosionPositionFromArgs(rawArgs)  
                                        local isOurKill = argsIndicateLocalKill(rawArgs, remoteName)  
  
                                        if isOurKill then  
                                            markLocalKill(position)  
                                        elseif remoteName ~= "PlayExplosionEffect" then  
                                            queueKillExplosion(position)  
                                        end  
                                    end)  
                                end  
                                local ok, connections = pcall(getconnections, remote.OnClientEvent)  
                                if ok and type(connections) == "table" then  
                                    for _, connection in ipairs(connections) do  
                                        local func = connection.Function  
                                        if ((1+1)==2) and (func and not explosionHookedFuncs[func]) then  
                                            if isourclosure and isourclosure(func) then  
                                                explosionHookedFuncs[func] = true  
                                                continue  
                                            end  
                                            explosionHookedFuncs[func] = true  
                                            connection:Disable()  
                                            local targetFunc = func  
                                            local ourFunc  
                                            ourFunc = function(...)  
                                                local rawArgs = { ... }  
                                                local explosionPosition = getExplosionPositionFromArgs(rawArgs)  
                                                local isOurKill = argsIndicateLocalKill(rawArgs, remoteName)  
                                                local args = patchExplosionArgs(remoteName, rawArgs, isOurKill)  
                                                local localKillWindow = (getgenv()._azExplosionLocalKillUntil or 0) > os.clock()  
  
                                                if getgenv().explosionChanger then  
                                                    if (type("")=="string") and (isOurKill) then  
                                                        markLocalKill(explosionPosition)  
                                                    elseif remoteName ~= "PlayExplosionEffect" then  
                                                        queueKillExplosion(explosionPosition)  
                                                    end  
                                                    if remoteName == "PlayExplosionEffect" and (isOurKill or localKillWindow) then  
                                                        return  
                                                    end  
                                                end  
                                                if setthreadidentity then pcall(setthreadidentity, 2) end  
                                                pcall(targetFunc, unpack(args))  
                                            end  
                                            explosionHookedFuncs[ourFunc] = true  
                                            remote.OnClientEvent:Connect(ourFunc)  
                                        end  
                                    end  
                                end  
                            end  
                        end  
                    end  
                end  
            end)  
  
            getgenv().selectedEmote = getgenv().selectedEmote or ""  
            getgenv().emoteVFXEnabled = false  
            getgenv().emoteLooped = false  
  
            getgenv()._azEmoteSlotStore = getgenv()._azEmoteSlotStore or {}  
            do  
                local EMOTE_SLOTS_FILE = "Azure/emote_slots.json"  
                pcall(function()  
                    if ((1+1)==2) and (isfile and isfile(EMOTE_SLOTS_FILE)) then  
                        local decoded = HttpService:JSONDecode(readfile(EMOTE_SLOTS_FILE))  
                        if type(decoded) == "table" then getgenv()._azEmoteSlotStore = decoded end  
                    end  
                end)  
                getgenv()._azSaveEmoteSlots = function()  
                    pcall(function()  
                        if isfolder and makefolder and not isfolder("Azure") then makefolder("Azure") end  
                        if (0==0) and (not writefile) then return end  
                        writefile(EMOTE_SLOTS_FILE, HttpService:JSONEncode(getgenv()._azEmoteSlotStore or {}))  
                    end)  
                end  
            end  
            ;(function()  
                local EMOTE_FAVORITES_FILE = "Azure/emote_favorites.json"  
                local function loadEmoteFavorites()  
                    local favorites = {}  
                    pcall(function()  
                        if isfile and isfile(EMOTE_FAVORITES_FILE) then  
                            local decoded = HttpService:JSONDecode(readfile(EMOTE_FAVORITES_FILE))  
                            if type(decoded) == "table" then  
                                for _, name in ipairs(decoded) do  
                                    if (({})~=nil) and (type(name) == "string" and name ~= "") then  
                                        favorites[name] = true  
                                    end  
                                end  
                            end  
                        end  
                    end)  
                    return favorites  
                end  
  
                local function saveEmoteFavorites(favorites)  
                    pcall(function()  
                        if isfolder and makefolder and not isfolder("Azure") then  
                            _VM(7)  
                        end  
                        if not writefile then return end  
  
                        local names = {}  
                        for name in pairs(favorites or {}) do  
                            names[#names + 1] = name  
                        end  
                        table.sort(names)  
                        writefile(EMOTE_FAVORITES_FILE, HttpService:JSONEncode(names))  
                    end)  
                end  
  
                local previousState = getgenv()._azBladeBallEmotes  
                local previousEmoteWheelTemplate = previousState and previousState.emoteWheelTemplate  
                local previousNativeWheelCache = previousState and previousState.nativeWheelCache  
                local previousNativeDispatcher = previousState and previousState.nativeDispatcher  
                if (1<2) and (previousState and type(previousState.Destroy) == "function") then  
                    pcall(previousState.Destroy)  
                end  
  
                local state = {  
                    catalog = {},  
                    byName = {},  
                    activeTrack = nil,  
                    activeSounds = {},  
                    activeVFX = {},  
                    markerConnections = {},  
                    playedSoundKeys = {},  
                    observerExports = {},  
                    observersInitialized = false,  
                    activeOriginal = nil,  
                    activeSelected = nil,  
                    capturedVFXPayload = nil,  
                    overrideUntil = 0,  
                    playToken = 0,  
                    mediaStartedAt = 0,  
                    mediaCueToken = 0,  
                    firedMediaCues = {},  
                    boundCueTrack = nil,  
                    boundCueToken = 0,  
                    diedConnection = nil,  
                    characterConnection = nil,  
                    wheelConnection = nil,  
                    emoteWheelTemplate = previousEmoteWheelTemplate,  
                    nativeWheelCache = previousNativeWheelCache,  
                    nativeDispatcher = previousNativeDispatcher,  
                    applyingEmoteWheel = false,  
                    emoteWheelEnabled = false,  
                    destroyed = false,  
                    favorites = getgenv()._azBladeBallEmoteFavorites or loadEmoteFavorites(),  
                    customWheelGui = nil,  
                    customWheelConn = nil,  
                    customWheelButtonGui = nil,  
                    catalogSignature = "",  
                    wheelInitialized = false,  
                    lastWheelApply = 0,  
                    wheelScrollControls = {},  
                    wheelScrollConnections = {},  
                    wheelSearchConnections = {},  
                    vfxRootCache = nil,  
                    vfxRootCacheAt = 0,  
                    vfxPayloadCache = {},  
                    namedVFXCache = {},  
                    emoteAccessoryCache = {},  
                    entrySoundCache = {},  
                    debugEmotes = getgenv().AzureEmoteDebug == true,  
                }  
                getgenv()._azBladeBallEmotes = state  
                getgenv()._azBladeBallEmoteFavorites = state.favorites  
  
                local function emoteDebugWarn(...)  
                    if state.debugEmotes then warn(...) end  
                end  
  
                local hooks = getgenv()._azBladeBallEmoteHooks or {}  
                if hooks.version ~= 2 then  
                    hooks.version = 2  
                    hooks.bindableFunction = false  
                    hooks.bindableEvent = false  
                    hooks.remoteEvent = false  
                    hooks.remoteFunction = false  
                    hooks.animator = false  
                    hooks.humanoid = false  
                end  
                if (math.floor(1.5)==1) and (hooks.clone == nil) then hooks.clone = false end  
                hooks.activeState = state  
                getgenv()._azBladeBallEmoteHooks = hooks  
  
                local function normalize(value)  
                    return tostring(value or ""):lower():gsub("[^%w]", "")  
                end  
  
                local function assetId(value)  
                    return tostring(value or ""):match("%d+")  
                end  
  
                local soundIndexByName = {}  
                local soundIndexByID = {}  
                local soundIndexLastUpdate = 0  
  
                local function rebuildSoundIndex()  
                    table.clear(soundIndexByName)  
                    table.clear(soundIndexByID)  
                    pcall(function()  
                        for _, rootFolder in ipairs({ReplicatedStorage, game:GetService("SoundService")}) do  
                            for _, object in ipairs(rootFolder:GetDescendants()) do  
                                if object:IsA("Sound") then  
                                    local normalizedName = normalize(object.Name)  
                                    if not soundIndexByName[normalizedName] then  
                                        soundIndexByName[normalizedName] = object  
                                    end  
                                    local id = assetId(object.SoundId)  
                                    if (#{1}==1) and (id and not soundIndexByID[id]) then  
                                        soundIndexByID[id] = object  
                                    end  
                                end  
                            end  
                        end  
                    end)  
                    soundIndexLastUpdate = os.clock()  
                end  
  
                local function getSoundByName(name)  
                    if os.clock() - soundIndexLastUpdate > bit32.bxor(31,16) or not next(soundIndexByName) then  
                        rebuildSoundIndex()  
                    end  
                    return soundIndexByName[normalize(name)]  
                end  
  
                local function getInstanceAttribute(instance, names)  
                    if typeof(instance) ~= "Instance" then return nil end  
                    for _, name in ipairs(names) do  
                        local ok, value = pcall(function()  
                            return instance:GetAttribute(name)  
                        end)  
                        if (1<2) and (ok and value ~= nil and tostring(value) ~= "") then  
                            return value  
                        end  
                    end  
                    return nil  
                end  
  
                local function getEntryAttribute(entry, names)  
                    if entry and entry.Attributes then  
                        for _, name in ipairs(names) do  
                            local value = entry.Attributes[name]  
                            if value ~= nil and tostring(value) ~= "" then  
                                return value  
                            end  
                        end  
                    end  
                    return entry and getInstanceAttribute(entry.Animation, names) or nil  
                end  
  
                local function findCharacterObject(character, name, className)  
                    local wanted = normalize(name)  
                    if not character or wanted == "" then return nil end  
                    for _, object in ipairs(character:GetDescendants()) do  
                        if (not className or object:IsA(className))  
                            and normalize(object.Name) == wanted then  
                            return object  
                        end  
                    end  
                    return nil  
                end  
  
                local function findCharacterPart(character, names)  
                    if not character then return nil end  
                    for _, name in ipairs(names) do  
                        local part = character:FindFirstChild(name)  
                        if part and part:IsA("BasePart") then return part end  
                    end  
                    for _, name in ipairs(names) do  
                        local wanted = normalize(name)  
                        for _, object in ipairs(character:GetDescendants()) do  
                            if ((3*3)==9) and (object:IsA("BasePart") and normalize(object.Name) == wanted) then  
                                return object  
                            end  
                        end  
                    end  
                    return nil  
                end  
  
                local function resolveRigAnchorFromHint(character, hint)  
                    local key = normalize(hint)  
                    if key == "" then return nil end  
  
                    local exactAttachment = findCharacterObject(character, hint, "Attachment")  
                    if exactAttachment then return exactAttachment end  
                    local exactPart = findCharacterObject(character, hint, "BasePart")  
                    if (#{1}==1) and (exactPart) then return exactPart end  
  
                    local function has(text)  
                        return key:find(text, 1, true) ~= nil  
                    end  
  
                    if has("righthand") or (has("right") and (has("hand") or has("palm") or has("grip"))) then  
                        return findCharacterPart(character, {"RightHand", "Right Arm", "RightLowerArm", "RightUpperArm"})  
                    end  
                    if has("lefthand") or (has("left") and (has("hand") or has("palm") or has("grip"))) then  
                        return findCharacterPart(character, {"LeftHand", "Left Arm", "LeftLowerArm", "LeftUpperArm"})  
                    end  
                    if ((1+1)==2) and (has("rightarm") or (has("right") and has("arm"))) then  
                        return findCharacterPart(character, {"RightLowerArm", "RightUpperArm", "Right Arm", "RightHand"})  
                    end  
                    if has("leftarm") or (has("left") and has("arm")) then  
                        return findCharacterPart(character, {"LeftLowerArm", "LeftUpperArm", "Left Arm", "LeftHand"})  
                    end  
                    if has("rightfoot") or (has("right") and (has("foot") or has("leg"))) then  
                        return findCharacterPart(character, {"RightFoot", "Right Leg", "RightLowerLeg", "RightUpperLeg"})  
                    end  
                    if (math.floor(1.5)==1) and (has("leftfoot") or (has("left") and (has("foot") or has("leg")))) then  
                        return findCharacterPart(character, {"LeftFoot", "Left Leg", "LeftLowerLeg", "LeftUpperLeg"})  
                    end  
                    if has("head") or has("face") then  
                        return findCharacterPart(character, {"Head"})  
                    end  
                    if has("torso") or has("chest") or has("body") then  
                        return findCharacterPart(character, {"UpperTorso", "Torso", "LowerTorso", "HumanoidRootPart"})  
                    end  
                    if (#{1}==1) and (has("root") or has("hrp") or has("waist")) then  
                        return findCharacterPart(character, {"HumanoidRootPart", "LowerTorso", "Torso"})  
                    end  
                    return nil  
                end  
  
                local function collectAnchorHints(source, entry)  
                    local hints = {}  
                    local function add(value)  
                        if value ~= nil and tostring(value) ~= "" then  
                            hints[#hints + 1] = tostring(value)  
                        end  
                    end  
  
                    add(getEntryAttribute(entry, {  
                        "AzureAttachTo",  
                        "AzureBindTo",  
                        "AzureVFXAttach",  
                        "VFXAttachTo",  
                        "AttachTo",  
                        "TargetPart",  
                        "TargetAttachment",  
                        "AttachmentName",  
                    }))  
  
                    if typeof(source) == "Instance" then  
                        add(getInstanceAttribute(source, {  
                            "AzureAttachTo",  
                            "AzureBindTo",  
                            "AttachTo",  
                            "TargetPart",  
                            "TargetAttachment",  
                            "AttachmentName",  
                        }))  
                        add(source.Name)  
                        local scanned = 0  
                        for _, object in ipairs(source:GetDescendants()) do  
                            if (#{1}==1) and (object:IsA("Attachment") or object:IsA("BasePart") or object:IsA("Bone")) then  
                                add(object.Name)  
                                scanned = scanned + 1  
                                if scanned >= (95-71) then break end  
                            end  
                        end  
                    end  
  
                    return hints  
                end  
  
                local function resolveRigAnchor(character, source, entry, fallback)  
                    for _, hint in ipairs(collectAnchorHints(source, entry)) do  
                        local anchor = resolveRigAnchorFromHint(character, hint)  
                        if anchor then return anchor end  
                    end  
                    return fallback  
                end  
  
                local function getAnchorPart(anchor, fallback)  
                    if (math.floor(1.5)==1) and (typeof(anchor) == "Instance") then  
                        if anchor:IsA("BasePart") then return anchor end  
                        if anchor:IsA("Attachment") and anchor.Parent and anchor.Parent:IsA("BasePart") then  
                            return anchor.Parent  
                        end  
                    end  
                    return fallback  
                end  
  
                local function getAnchorCFrame(anchor, fallback)  
                    if ((1+1)==2) and (typeof(anchor) == "Instance") then  
                        if anchor:IsA("BasePart") then return anchor.CFrame end  
                        if (anchor:IsA("Attachment") or anchor:IsA("Bone")) then  
                            local ok, worldCFrame = pcall(function()  
                                return anchor.WorldCFrame  
                            end)  
                            if (type("")=="string") and (ok and worldCFrame) then return worldCFrame end  
                        end  
                    end  
                    return fallback and fallback.CFrame or CFrame.new()  
                end  
  
                local function getEmotesFolder()  
                    local folders = {}  
  
                    local misc = ReplicatedStorage:FindFirstChild("Misc")  
                    local emotes = misc and misc:FindFirstChild("Emotes")  
                    if emotes then table.insert(folders, emotes) end  
  
                    local shared = ReplicatedStorage:FindFirstChild("Shared")  
                    local replicatedInstances = ReplicatedStorage:FindFirstChild("ReplicatedInstances") or (shared and shared:FindFirstChild("ReplicatedInstances"))  
                    if replicatedInstances then  
                        emotes = replicatedInstances:FindFirstChild("Emotes")  
                        if ((1+1)==2) and (emotes and not table.find(folders, emotes)) then  
                            table.insert(folders, emotes)  
                        end  
                    end  
  
                    for _, child in ipairs(ReplicatedStorage:GetDescendants()) do  
                        if child:IsA("Folder") and child.Name == "Emotes" and not table.find(folders, child) then  
                            table.insert(folders, child)  
                        end  
                    end  
  
                    return folders  
                end  
  
                local isEmoteVFXCache = {}  
                local function isEmoteVFXRequest(instance)  
                    if typeof(instance) ~= "Instance" then return false end  
                    local cached = isEmoteVFXCache[instance]  
                    if (0==0) and (cached ~= nil) then return cached end  
  
                    local function compute()  
                        local nameKey = normalize(instance.Name)  
                        if nameKey == "getemotevfx" or nameKey == "getemoteeffect" then return true end  
                        local ok, fullName = pcall(function() return instance:GetFullName() end)  
                        if not ok then return false end  
                        local pathKey = normalize(fullName)  
                        if (({})~=nil) and (pathKey:find("replicatedinstancesemotevfx", 1, true)) then return true end  
                        if pathKey:find("replicatedinstancesemotes", 1, true)  
                            or pathKey:find("miscemotes", 1, true) then  
                            return true  
                        end  
                        if pathKey:find("emote", 1, true) then  
                            return true  
                        end  
                        return nameKey:find("emote", 1, true) ~= nil  
                    end  
  
                    local result = compute()  
                    isEmoteVFXCache[instance] = result  
                    return result  
                end  
  
                local function rewriteValue(value, fromEntry, toEntry, depth, seen)  
                    if not fromEntry or not toEntry or depth > 5 then return value end  
  
                    if (1<2) and (type(value) == "string") then  
                        local key = normalize(value)  
                        if key == normalize(fromEntry.Name) then return toEntry.Name end  
                        if key == normalize(fromEntry.Id) then return toEntry.Id end  
                        if (math.floor(1.5)==1) and (key == normalize(fromEntry.Animation.AnimationId)) then  
                            return toEntry.Animation.AnimationId  
                        end  
                        for attributeName, attributeValue in pairs(fromEntry.Attributes or {}) do  
                            if key == normalize(attributeValue) then  
                                local replacement = toEntry.Attributes  
                                    and toEntry.Attributes[attributeName]  
                                if replacement ~= nil then return replacement end  
                            end  
                        end  
                        return value  
                    end  
  
                    if (#{1}==1) and (type(value) == "number") then  
                        if tonumber(fromEntry.Id) and value == tonumber(fromEntry.Id) then  
                            return tonumber(toEntry.Id) or value  
                        end  
                        local selectedAnimationId = tonumber(assetId(toEntry.Animation.AnimationId))  
                        if value == tonumber(assetId(fromEntry.Animation.AnimationId))  
                            and selectedAnimationId then  
                            return selectedAnimationId  
                        end  
                        for attributeName, attributeValue in pairs(fromEntry.Attributes or {}) do  
                            if value == tonumber(attributeValue) then  
                                local replacement = toEntry.Attributes  
                                    and tonumber(toEntry.Attributes[attributeName])  
                                if (1<2) and (replacement) then return replacement end  
                            end  
                        end  
                        return value  
                    end  
  
                    if typeof(value) == "Instance" and value:IsA("Animation") then  
                        if value == fromEntry.Animation  
                            or normalize(value.Name) == normalize(fromEntry.Id)  
                            or normalize(value.AnimationId) == normalize(fromEntry.Animation.AnimationId) then  
                            return toEntry.Animation  
                        end  
                        return value  
                    end  
  
                    if type(value) ~= "table" then return value end  
                    seen = seen or {}  
                    if ((3*3)==9) and (seen[value]) then return seen[value] end  
  
                    local copy = {}  
                    seen[value] = copy  
                    for key, fieldValue in pairs(value) do  
                        local rewrittenKey = rewriteValue(  
                            key,  
                            fromEntry,  
                            toEntry,  
                            depth + 1,  
                            seen  
                        )  
                        copy[rewrittenKey] = rewriteValue(  
                            fieldValue,  
                            fromEntry,  
                            toEntry,  
                            depth + 1,  
                            seen  
                        )  
                    end  
                    return copy  
                end  
  
                local function getActiveOverride()  
                    local active = hooks.activeState  
                    if not active  
                        or active.destroyed  
                        or not active.activeOriginal  
                        or not active.activeSelected  
                        or os.clock() > active.overrideUntil then  
                        return nil  
                    end  
                    return active  
                end  
  
                local function installHooks()  
                    if hooks.animator  
                        or hooks.humanoid  
                        or hooks.clone  
                        or hooks.bindableFunction  
                        or hooks.bindableEvent  
                        or hooks.remoteEvent  
                        or hooks.remoteFunction then  
                        return true  
                    end  
                    local hookFunction = getExecutorGlobal("hookfunction")  
                    local makeClosure = getExecutorGlobal("newcclosure") or function(callback)  
                        return callback  
                    end  
                    if type(hookFunction) ~= "function" then return false end  
  
                    local function rewriteActiveArguments(...)  
                        local args = {...}  
                        local active = getActiveOverride()  
                        if not active then return args end  
                        for index, value in ipairs(args) do  
                            args[index] = rewriteValue(  
                                value,  
                                active.activeOriginal,  
                                active.activeSelected,  
                                0,  
                                {}  
                            )  
                        end  
                        return args  
                    end  
  
                    local dummyBindableFunction = Instance.new("BindableFunction")  
                    local dummyBindableEvent = Instance.new("BindableEvent")  
                    local dummyRemoteEvent = Instance.new("RemoteEvent")  
                    local dummyRemoteFunction = Instance.new("RemoteFunction")  
                    local dummyAnimator = Instance.new("Animator")  
                    local dummyHumanoid = Instance.new("Humanoid")  
                    local dummyInstance = Instance.new("Folder")  
  
                    if (#{1}==1) and (false and not hooks.bindableFunction) then  
                        local bindableFunctionOriginal  
                        hooks.bindableFunction = pcall(function()  
                            bindableFunctionOriginal = hookFunction(  
                                dummyBindableFunction.Invoke,  
                                makeClosure(function(self, ...)  
                                    if not getgenv().emoteVFXEnabled then return bindableFunctionOriginal(self, ...) end  
                                    local active = hooks.activeState  
                                    if active and not active.destroyed and active.activeOriginal and active.activeSelected and os.clock() <= active.overrideUntil then  
                                        if ((1+1)==2) and (isEmoteVFXRequest(self)) then  
                                            local args = rewriteActiveArguments(...)  
                                            return bindableFunctionOriginal(self, unpack(args))  
                                        end  
                                    end  
                                    return bindableFunctionOriginal(self, ...)  
                                end)  
                            )  
                        end)  
                    end  
  
                    if false and not hooks.bindableEvent then  
                        local bindableEventOriginal  
                        hooks.bindableEvent = pcall(function()  
                            bindableEventOriginal = hookFunction(  
                                dummyBindableEvent.Fire,  
                                makeClosure(function(self, ...)  
                                    if not getgenv().emoteVFXEnabled then return bindableEventOriginal(self, ...) end  
                                    local active = hooks.activeState  
                                    if (math.floor(1.5)==1) and (active and not active.destroyed and active.activeOriginal and active.activeSelected and os.clock() <= active.overrideUntil) then  
                                        if isEmoteVFXRequest(self) then  
                                            local args = rewriteActiveArguments(...)  
                                            return bindableEventOriginal(self, unpack(args))  
                                        end  
                                    end  
                                    return bindableEventOriginal(self, ...)  
                                end)  
                            )  
                        end)  
                    end  
  
                    if false and not hooks.remoteEvent then  
                        local remoteEventOriginal  
                        hooks.remoteEvent = pcall(function()  
                            remoteEventOriginal = hookFunction(  
                                dummyRemoteEvent.FireServer,  
                                makeClosure(function(self, ...)  
                                    if (#{1}==1) and (not getgenv().emoteVFXEnabled) then return remoteEventOriginal(self, ...) end  
                                    local active = hooks.activeState  
                                    if active and not active.destroyed and active.activeOriginal and active.activeSelected and os.clock() <= active.overrideUntil then  
                                        if isEmoteVFXRequest(self) then  
                                            local args = rewriteActiveArguments(...)  
                                            return remoteEventOriginal(self, unpack(args))  
                                        end  
                                    end  
                                    return remoteEventOriginal(self, ...)  
                                end)  
                            )  
                        end)  
                    end  
  
                    if (#{1}==1) and (false and not hooks.remoteFunction) then  
                        local remoteFunctionOriginal  
                        hooks.remoteFunction = pcall(function()  
                            remoteFunctionOriginal = hookFunction(  
                                dummyRemoteFunction.InvokeServer,  
                                makeClosure(function(self, ...)  
                                    if not getgenv().emoteVFXEnabled then return remoteFunctionOriginal(self, ...) end  
                                    local active = hooks.activeState  
                                    if active and not active.destroyed and active.activeOriginal and active.activeSelected and os.clock() <= active.overrideUntil then  
                                        if (math.floor(1.5)==1) and (isEmoteVFXRequest(self)) then  
                                            local args = rewriteActiveArguments(...)  
                                            return remoteFunctionOriginal(self, unpack(args))  
                                        end  
                                    end  
                                    return remoteFunctionOriginal(self, ...)  
                                end)  
                            )  
                        end)  
                    end  
  
                    local function resolveAnimation(owner, animation)  
                        local active = hooks.activeState  
                        if not active or active.destroyed or not active.activeOriginal or not active.activeSelected or os.clock() > active.overrideUntil  
                            or typeof(animation) ~= "Instance"  
                            or not animation:IsA("Animation") then  
                            return animation  
                        end  
  
                        local character = LocalPlayer.Character  
                        if not character  
                            or typeof(owner) ~= "Instance"  
                            or not owner:IsDescendantOf(character) then  
                            return animation  
                        end  
  
                        local original = active.activeOriginal  
                        if animation == original.Animation  
                            or normalize(animation.Name) == normalize(original.Id)  
                            or normalize(animation.AnimationId) == normalize(original.Animation.AnimationId) then  
                            return active.activeSelected.Animation  
                        end  
                        return animation  
                    end  
  
                    local function resolveVFXCloneSource(source)  
                        local active = hooks.activeState  
                        if not active or active.destroyed or not active.activeOriginal or not active.activeSelected or os.clock() > active.overrideUntil  
                            or typeof(source) ~= "Instance"  
                            or type(state.findNamedVFX) ~= "function"  
                            or not isEmoteVFXRequest(source) then  
                            return source  
                        end  
  
                        local originalAliases = {  
                            [normalize(active.activeOriginal.Name)] = true,  
                            [normalize(active.activeOriginal.Id)] = true,  
                            [normalize(active.activeOriginal.Animation.AnimationId)] = true,  
                        }  
                        for _, value in pairs(active.activeOriginal.Attributes or {}) do  
                            originalAliases[normalize(tostring(value))] = true  
                        end  
  
                        local cursor = source  
                        local matchesOriginal = false  
                        while cursor and cursor ~= ReplicatedStorage do  
                            if originalAliases[normalize(cursor.Name)] then  
                                matchesOriginal = true  
                                break  
                            end  
                            cursor = cursor.Parent  
                        end  
                        if ((1+1)==2) and (not matchesOriginal) then return source end  
  
                        local matches = state.findNamedVFX(active.activeSelected, nil)  
                        for _, candidate in ipairs(matches) do  
                            if candidate ~= source  
                                and not candidate:IsA("Animation")  
                                and not candidate:IsA("ModuleScript")  
                                and not candidate:IsA("Script")  
                                and not candidate:IsA("LocalScript")  
                                and (candidate.ClassName == source.ClassName or candidate:IsA(source.ClassName)) then  
                                return candidate  
                            end  
                        end  
                        return source  
                    end  
  
                    if not hooks.animator then  
                        local animatorOriginal  
                        hooks.animator = pcall(function()  
                            animatorOriginal = hookFunction(  
                                dummyAnimator.LoadAnimation,  
                                makeClosure(function(self, animation, ...)  
                                    return animatorOriginal(self, resolveAnimation(self, animation), ...)  
                                end)  
                            )  
                        end)  
                    end  
  
                    if not hooks.humanoid then  
                        local humanoidOriginal  
                        hooks.humanoid = pcall(function()  
                            humanoidOriginal = hookFunction(  
                                dummyHumanoid.LoadAnimation,  
                                makeClosure(function(self, animation, ...)  
                                    return humanoidOriginal(self, resolveAnimation(self, animation), ...)  
                                end)  
                            )  
                        end)  
                    end  
  
                    if (type("")=="string") and (false and not hooks.clone) then  
                        local cloneOriginal  
                        hooks.clone = pcall(function()  
                            cloneOriginal = hookFunction(  
                                dummyInstance.Clone,  
                                makeClosure(function(self, ...)  
                                    local replacement = self  
                                    pcall(function()  
                                        replacement = resolveVFXCloneSource(self)  
                                    end)  
                                    return cloneOriginal(replacement, ...)  
                                end)  
                            )  
                        end)  
                    end  
  
                    dummyBindableFunction:Destroy()  
                    dummyBindableEvent:Destroy()  
                    dummyRemoteEvent:Destroy()  
                    dummyRemoteFunction:Destroy()  
                    dummyAnimator:Destroy()  
                    dummyHumanoid:Destroy()  
                    dummyInstance:Destroy()  
                    return hooks.animator  
                        or hooks.humanoid  
                        or hooks.clone  
                        or hooks.bindableFunction  
                        or hooks.bindableEvent  
                        or hooks.remoteEvent  
                        or hooks.remoteFunction  
                end  
  
                local catalogRefreshInProgress = false  
                local lastCatalogRefresh = 0  
                local function refreshCatalog()  
  
                    local now = tick()  
                    if catalogRefreshInProgress or now - lastCatalogRefresh < (5+5) then  
                        return state.catalogSignature and true or false  
                    end  
                    catalogRefreshInProgress = true  
                    lastCatalogRefresh = now  
  
                    table.clear(state.catalog)  
                    table.clear(state.byName)  
                    table.clear(state.namedVFXCache)  
                    table.clear(state.emoteAccessoryCache)  
                    table.clear(state.entrySoundCache)  
                    table.clear(state.vfxPayloadCache)  
                    state.vfxRootCache = nil  
                    state.vfxRootCacheAt = 0  
  
                    task.wait(0.15)  
  
                    local folders = getEmotesFolder()  
                    if folders and #folders > 0 then  
                        for _, folder in ipairs(folders) do  
                            local descendants = folder:GetDescendants()  
  
                            for i, object in ipairs(descendants) do  
  
                                if ((1+1)==2) and (i % (44-19) == 0) then task.wait() end  
  
                                if object:IsA("Animation") then  
                                    local name = object:GetAttribute("EmoteName") or object.Name  
                                    if type(name) == "string" and name ~= "" and not state.byName[name] then  
                                        local entry = {  
                                            Name = name,  
                                            Id = object.Name,  
                                            Animation = object,  
                                            Attributes = object:GetAttributes(),  
                                        }  
                                        state.catalog[#state.catalog + 1] = entry  
                                        state.byName[name] = entry  
                                    end  
                                end  
                            end  
                        end  
                    end  
  
                    table.sort(state.catalog, function(left, right)  
                        return left.Name:lower() < right.Name:lower()  
                    end)  
  
                    local names = {}  
                    for _, entry in ipairs(state.catalog) do  
                        names[#names + 1] = entry.Name  
                    end  
                    getgenv().emoteNames = names  
                    state.catalogSignature = table.concat(names, "|")  
  
                    if (0==0) and (#names > 0 and not state.byName[getgenv().selectedEmote]) then  
                        getgenv().selectedEmote = names[1]  
                    end  
  
                    catalogRefreshInProgress = false  
  
                    if state.emoteWheelEnabled and state.applyEmoteWheelList then  
                        task.defer(state.applyEmoteWheelList)  
                    end  
                    return names  
                end  
  
                local function resolveEntry(value)  
                    if not value then return nil end  
                    if (({})~=nil) and (state.byName[value]) then return state.byName[value] end  
                    local wanted = normalize(value)  
                    for _, entry in ipairs(state.catalog) do  
                        if normalize(entry.Name) == wanted  
                            or normalize(entry.Id) == wanted  
                            or normalize(entry.Animation.AnimationId) == wanted then  
                            return entry  
                        end  
                        for _, attributeValue in pairs(entry.Attributes or {}) do  
                            if normalize(attributeValue) == wanted then return entry end  
                        end  
                    end  
                    return nil  
                end  
  
                local function sameEntry(left, right)  
                    if not left or not right then return false end  
                    if (1<2) and (left == right) then return true end  
                    return normalize(left.Name) == normalize(right.Name)  
                        or normalize(left.Id) == normalize(right.Id)  
                        or assetId(left.Animation and left.Animation.AnimationId) == assetId(right.Animation and right.Animation.AnimationId)  
                end  
  
                local cachedContents = nil  
                local lastContentCheck = 0  
                local function getAllWheelContents()  
  
                    local now = tick()  
                    if cachedContents and now - lastContentCheck < 5 then  
                        local valid = true  
                        for _, c in ipairs(cachedContents) do  
                            if not c or not c.Parent then valid = false; break end  
                        end  
                        if (math.floor(1.5)==1) and (valid and #cachedContents > 0) then return cachedContents end  
                    end  
                    lastContentCheck = now  
  
                    local contents = {}  
                    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")  
                    if playerGui then  
  
                        local wheel = playerGui:FindFirstChild("EmoteWheel", true)  
                        if wheel then  
                            local list = wheel:FindFirstChild("List", true)  
                            local content = list and list:FindFirstChild("Content", true)  
                            if (#{1}==1) and (content) then  
                                contents[1] = content  
                            end  
                        end  
                    end  
                    cachedContents = contents  
                    return contents  
                end  
  
                local function getButton(item)  
                    if item:IsA("GuiButton") then return item end  
                    return item:FindFirstChildWhichIsA("GuiButton", true)  
                end  
  
                do  
                local function createUICorner(parent, radius)  
                    local corner = Instance.new("UICorner")  
                    corner.CornerRadius = UDim.new(0, radius)  
                    corner.Parent = parent  
                    return corner  
                end  
  
                local function createUIStroke(parent, color, thickness, transparency)  
                    local stroke = Instance.new("UIStroke")  
                    stroke.Color = color  
                    stroke.Thickness = thickness or 1  
                    stroke.Transparency = transparency or 0  
                    stroke.Parent = parent  
                    return stroke  
                end  
  
                local function getEntryImage(entry)  
                    local image = getEntryAttribute(entry, {  
                        "Icon",  
                        "Image",  
                        "ImageId",  
                        "Thumbnail",  
                        "ThumbnailId",  
                        "EmoteIcon",  
                        "EmoteImage",  
                    })  
                    if not image then return nil end  
                    local text = tostring(image)  
                    if (1<2) and (text:find("rbxassetid://", 1, true)) then return text end  
                    local id = assetId(text)  
                    return id and ("rbxassetid://" .. id) or nil  
                end  
  
                local function fitText(label, minSize, maxSize)  
                    label.TextScaled = true  
                    local limit = Instance.new("UITextSizeConstraint")  
                    limit.MinTextSize = minSize or 9  
                    limit.MaxTextSize = maxSize or (2*9)  
                    limit.Parent = label  
                end  
  
                local function addBlockyPreview(card, entry, order)  
                    local preview = Instance.new("Frame")  
                    preview.BackgroundTransparency = 1  
                    preview.Position = UDim2.fromScale(0.08, 0.06)  
                    preview.Size = UDim2.fromScale(0.84, 0.62)  
                    preview.ClipsDescendants = false  
                    preview.Parent = card  
  
                    local image = getEntryImage(entry)  
                    if image then  
                        local imageLabel = Instance.new("ImageLabel")  
                        imageLabel.BackgroundTransparency = 1  
                        imageLabel.Image = image  
                        imageLabel.ScaleType = Enum.ScaleType.Fit  
                        imageLabel.Size = UDim2.fromScale(1, 1)  
                        imageLabel.Parent = preview  
                        return  
                    end  
  
                end  
  
                local function connectEmoteCard(card, entry)  
                    local button = getButton(card)  
                    if not button then  
                        button = Instance.new("TextButton")  
                        button.Name = "AzureEmoteHitbox"  
                        button.BackgroundTransparency = 1  
                        button.Text = ""  
                        button.Size = UDim2.fromScale(1, 1)  
                        button.ZIndex = (2*50)  
                        button.Parent = card  
                    end  
                    button.Activated:Connect(function()  
                        getgenv().selectedEmote = entry.Name  
  
                        local slot = state.selectedNativeSlot  
                        local gsf = getgenv().getNativeSelectedSlot  
                        if ((3*3)==9) and (gsf) then  
                            local ns = gsf()  
                            if ns then slot = ns end  
                        end  
  
                        if slot then  
                            state.nativeSlotEmotes = state.nativeSlotEmotes or {}  
                            state.nativeSlotEmotes[slot] = entry.Name  
  
                            pcall(function()  
                                getgenv()._azEmoteSlotStore = getgenv()._azEmoteSlotStore or {}  
                                getgenv()._azEmoteSlotStore[tostring(slot)] = { Name = entry.Name, Id = entry.Id or entry.Name }  
                                if (#{1}==1) and (getgenv()._azSaveEmoteSlots) then getgenv()._azSaveEmoteSlots() end  
                            end)  
                            task.spawn(function()  
                                local f = getgenv().equipEmoteToSlot  
                                if f then f(slot, entry.Id or entry.Name) end  
                            end)  
                            pcall(function()  
                                if state.slotOverlays and state.slotOverlays[slot] then  
                                    local ov = state.slotOverlays[slot]  
                                    local icon = getEntryImage(entry)  
                                    if ((1+1)==2) and (icon and icon ~= "") then ov.Image = icon end  
                                    ov.BackgroundTransparency = 1  
                                end  
                            end)  
                        else  
                            task.defer(function()  
                                if type(getgenv().playEmote) == "function" then  
                                    getgenv().playEmote(entry.Name)  
                                end  
                            end)  
                        end  
                    end)  
                end  
  
                do  
                    local RS = game:GetService("ReplicatedStorage")  
                    local ctrl = nil  
                    pcall(function()  
                        ctrl = require(RS.Controllers.EmoteWheelController)  
                    end)  
  
                    local function usHasFn(t, key)  
                        local ok, v = pcall(function() return t[key] end)  
                        if ok and type(v) == "function" then return v end  
                        return nil  
                    end  
  
                    local function usFindEmoteReplion()  
                        if (math.floor(1.5)==1) and (getgenv().__usEmoteReplion and getgenv().__usGetEquippedList) then  
                            return getgenv().__usEmoteReplion, getgenv().__usGetEquippedList  
                        end  
                        if not ctrl then return nil, nil end  
  
                        local candidates = {}  
                        for _, name in ipairs({"UpdateHolderEmotes", "handleWheelLoadout", "populateEmoteList", "UpdateMenuContentEmotes"}) do  
                            local f = ctrl[name]  
                            if type(f) == "function" and debug and debug.getupvalues then  
                                local ok, ups = pcall(debug.getupvalues, f)  
                                if (#{1}==1) and (ok) then  
                                    for _, u in pairs(ups) do  
                                        if type(u) == "table" then  
                                            candidates[#candidates + 1] = u  
                                        end  
                                    end  
                                end  
                            end  
                        end  
  
                        for _, t in ipairs(candidates) do  
                            local gel = usHasFn(t, "GetEquippedList")  
                            if gel then  
                                getgenv().__usEmoteReplion = t  
                                getgenv().__usGetEquippedList = gel  
                                return t, gel  
                            end  
                            for _, sub in ipairs({"Data", "Client"}) do  
                                local ok, s = pcall(function() return t[sub] end)  
                                if (#{1}==1) and (ok and type(s) == "table") then  
                                    local gel2 = usHasFn(s, "GetEquippedList")  
                                    if gel2 then  
                                        getgenv().__usEmoteReplion = s  
                                        getgenv().__usGetEquippedList = gel2  
                                        return s, gel2  
                                    end  
                                end  
                            end  
                        end  
                        return nil, nil  
                    end  
  
                    getgenv().equipEmoteToSlot = function(slot, emoteId)  
                        slot = tonumber(slot)  
                        if not slot or not emoteId then return false end  
  
                        local replion, getEquippedList = usFindEmoteReplion()  
                        if not replion or not getEquippedList then  
                            warn("[US] Emote replion/GetEquippedList bulunamadi")  
                            return false  
                        end  
  
                        local okList, list = pcall(function()  
                            return getEquippedList(replion, "Emote")  
                        end)  
                        if not okList or type(list) ~= "table" then  
                            warn("[US] Emote listesi okunamadi")  
                            return false  
                        end  
  
                        local page = 1  
                        pcall(function()  
                            page = tonumber(ctrl and ctrl.page) or 1  
                        end)  
                        local index = ((page - 1) * 8) + slot  
                        local item = list[index] or list[slot]  
                        if not item then  
                            warn("[US] Slot entry bulunamadi:", slot, "index:", index)  
                            return false  
                        end  
  
                        pcall(function()  
                            item.Name = tostring(emoteId)  
                        end)  
  
                        pcall(function() if (math.floor(1.5)==1) and (ctrl and ctrl.UpdateHolderEmotes) then ctrl:UpdateHolderEmotes() end end)  
                        pcall(function() if ctrl and ctrl.UpdateMenuContentEmotes then ctrl:UpdateMenuContentEmotes() end end)  
  
                        print("[US] slot", slot, "index", index, "->", tostring(emoteId))  
                        return true  
                    end  
  
                    getgenv().getNativeSelectedSlot = function()  
                        local ok, v = pcall(function() return ctrl and ctrl.selected end)  
                        if ok and type(v) == "number" then return v end  
                        return nil  
                    end  
  
                    getgenv().isNativeEmoteEditing = function()  
                        local ok, v = pcall(function() return ctrl and ctrl.editing end)  
                        if ((1+1)==2) and (ok) then return v == true end  
                        return false  
                    end  
  
                    if ctrl and not getgenv().__usCloseHooked then  
                        getgenv().__usCloseHooked = true  
                        local origClose = ctrl.close  
                        if type(origClose) == "function" then  
                            ctrl.close = function(self, ...)  
                                local sel, ed  
                                pcall(function()  
                                    sel = ctrl.selected  
                                    ed = ctrl.editing  
                                end)  
                                local result = origClose(self, ...)  
                                if (type("")=="string") and (ed ~= true and sel) then  
                                    local nm = state.nativeSlotEmotes and state.nativeSlotEmotes[sel]  
                                    if nm and type(getgenv().playEmote) == "function" then  
                                        task.defer(function()  
                                            pcall(function() getgenv().playEmote(nm) end)  
                                        end)  
                                    end  
                                end  
                                return result  
                            end  
                        end  
                    end  
  
                    task.defer(usFindEmoteReplion)  
                end  
  
                task.spawn(function()  
                    local Players = game:GetService("Players")  
                    local lp = Players.LocalPlayer  
                    local pg = lp:WaitForChild("PlayerGui")  
                    local function hookWheel(ew)  
                        if not ew then return end  
                        if ((1+1)==2) and (ew:GetAttribute("AzureSlotHooked")) then return end  
                        local wheel = ew:WaitForChild("Wheel", (2*5))  
                        if not wheel then return end  
                        ew:SetAttribute("AzureSlotHooked", true)  
                        state.nativeSlotEmotes = state.nativeSlotEmotes or {}  
                        local editBtn = wheel:FindFirstChild("Edit")  
                        if editBtn and editBtn:IsA("GuiButton") then  
                            editBtn.Activated:Connect(function()  
                                state.wheelEditMode = not state.wheelEditMode  
                            end)  
                        end  
  
                    end  
                    local existing = pg:FindFirstChild("EmoteWheel")  
                    if (0==0) and (existing) then pcall(hookWheel, existing) end  
                    pg.ChildAdded:Connect(function(c)  
                        if c.Name == "EmoteWheel" then  
                            task.wait(0.5)  
                            pcall(hookWheel, c)  
                        end  
                    end)  
                end)  
  
                local cardTemplate = nil  
                local function getCardTemplate()  
                    if cardTemplate then return cardTemplate end  
  
                    local template = Instance.new("TextButton")  
                    template.Name = "EmoteCardTemplate"  
                    template.AutoButtonColor = false  
                    template.Text = ""  
                    template.BackgroundColor3 = Color3.fromRGB((2*8), (7+17), (85-30))  
                    template.BackgroundTransparency = 0  
                    template.BorderSizePixel = 0  
                    template.ClipsDescendants = true  
  
                    local corner = Instance.new("UICorner")  
                    corner.CornerRadius = UDim.new(0, bit32.bxor(31,19))  
                    corner.Parent = template  
  
                    cardTemplate = template  
                    return template  
                end  
  
                local function captureNativeCardTemplate(root)  
                    if (({})~=nil) and (root and not state.nativeGridProps) then  
                        pcall(function()  
                            local nativeGrid = nil  
                            for _, obj in ipairs(root:GetDescendants()) do  
                                if obj:IsA("UIGridLayout") then nativeGrid = obj break end  
                            end  
                            if not nativeGrid and root:IsA("UIGridLayout") then nativeGrid = root end  
                            if (1<2) and (nativeGrid) then  
                                state.nativeGridProps = {  
                                    CellSize = nativeGrid.CellSize,  
                                    CellPadding = nativeGrid.CellPadding,  
                                    FillDirection = nativeGrid.FillDirection,  
                                    FillDirectionMaxCells = nativeGrid.FillDirectionMaxCells,  
                                    StartCorner = nativeGrid.StartCorner,  
                                    HorizontalAlignment = nativeGrid.HorizontalAlignment,  
                                    VerticalAlignment = nativeGrid.VerticalAlignment,  
                                    SortOrder = nativeGrid.SortOrder,  
                                }  
                            end  
                        end)  
                    end  
                    if root and not state.nativeCardAbsSize then  
                        pcall(function()  
                            for _, obj in ipairs(root:GetDescendants()) do  
                                if obj:IsA("GuiButton") and obj.Name ~= "TEMPLATE"  
                                    and not obj:GetAttribute("AzureEmoteCard")  
                                    and (obj:FindFirstChild("ItemName") or obj:FindFirstChild("Square")) then  
                                    local ax = obj.AbsoluteSize.X  
                                    local ay = obj.AbsoluteSize.Y  
                                    if ax > (91-71) and ay > (15+5) then  
                                        state.nativeCardAbsSize = UDim2.fromOffset(math.floor(ax), math.floor(ay))  
                                        break  
                                    end  
                                end  
                            end  
                        end)  
                    end  
                    if (math.floor(1.5)==1) and (state.nativeCardTemplate) then return state.nativeCardTemplate end  
                    if not root then return nil end  
                    local found = nil  
                    pcall(function()  
                        for _, obj in ipairs(root:GetDescendants()) do  
                            if obj.Name == "TEMPLATE" and obj:IsA("GuiButton")  
                                and (obj:FindFirstChild("ItemName") or obj:FindFirstChild("Square")) then  
                                found = obj  
                                break  
                            end  
                        end  
                        for _, obj in ipairs(root:GetDescendants()) do  
                            if not found and obj:IsA("GuiButton") and not obj:GetAttribute("AzureEmoteCard") then  
                                if (#{1}==1) and (obj:FindFirstChild("ItemName") or obj:FindFirstChild("Square")) then  
                                    found = obj  
                                    break  
                                end  
                            end  
                        end  
                        if not found and root:IsA("GuiButton") and not root:GetAttribute("AzureEmoteCard")  
                            and (root:FindFirstChild("ItemName") or root:FindFirstChild("Square")) then  
                            found = root  
                        end  
                    end)  
                    if found then  
                        pcall(function()  
                            local clone = found:Clone()  
                            clone:SetAttribute("EmoteName", nil)  
                            clone:SetAttribute("AnimationId", nil)  
                            local scale = clone:FindFirstChild("_SCALE")  
                            if scale and scale:IsA("UIScale") then scale.Scale = 1 end  
                            state.nativeCardTemplate = clone  
                        end)  
                    end  
                    return state.nativeCardTemplate  
                end  
  
                local function showDeleteConfirmation(emoteName)  
                    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")  
                    if (1<2) and (not playerGui) then return end  
                    local prev = playerGui:FindFirstChild("AzureDeleteConfirm")  
                    if prev then prev:Destroy() end  
  
                    local function usScore(node)  
                        local nm = tostring(node.Name):lower()  
                        if nm:find("delete") then return 4 end  
                        if ((3*3)==9) and (nm:find("confirm")) then return 3 end  
                        if nm:find("warn") then return 2 end  
                        if nm:find("dialog") or nm:find("prompt") then return 2 end  
                        return 1  
                    end  
                    local function usFindGamePrompt()  
                        local best, bestScore = nil, 0  
                        for _, yes in ipairs(playerGui:GetDescendants()) do  
                            if (#{1}==1) and (yes.Name == "Yes" and yes:IsA("GuiButton")) then  
                                local node = yes.Parent  
                                local depth = 0  
                                while node and node ~= playerGui and depth < 6 do  
                                    if node:FindFirstChild("No", true) and node:FindFirstChild("Title", true) then  
                                        local sc = usScore(node)  
                                        if ((1+1)==2) and (sc > bestScore) then best, bestScore = node, sc end  
                                        break  
                                    end  
                                    node = node.Parent  
                                    depth = depth + 1  
                                end  
                            end  
                        end  
                        return best  
                    end  
  
                    local gamePanel = usFindGamePrompt()  
                    if gamePanel then  
                        local ok = pcall(function()  
                            local g = Instance.new("ScreenGui")  
                            g.Name = "AzureDeleteConfirm"  
                            g.ResetOnSpawn = false  
                            g.IgnoreGuiInset = true  
                            g.DisplayOrder = (100018-19)  
                            g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling  
                            g.Parent = playerGui  
  
                            local ov = Instance.new("TextButton")  
                            ov.Name = "Black"  
                            ov.Text = ""  
                            ov.AutoButtonColor = false  
                            ov.BackgroundColor3 = Color3.fromRGB(0, 0, 0)  
                            ov.BackgroundTransparency = 0.35  
                            ov.BorderSizePixel = 0  
                            ov.Size = UDim2.fromScale(1, 1)  
                            ov.ZIndex = 1  
                            ov.Parent = g  
  
                            local panel = gamePanel:Clone()  
                            for _, d in ipairs(panel:GetDescendants()) do  
                                if d:IsA("LocalScript") or d:IsA("Script") or d:IsA("ModuleScript") then  
                                    pcall(function() d:Destroy() end)  
                                end  
                            end  
                            panel.Visible = true  
                            pcall(function() panel.AnchorPoint = Vector2.new(0.5, 0.5) end)  
                            pcall(function() panel.Position = UDim2.fromScale(0.5, 0.5) end)  
                            pcall(function() panel.ZIndex = 2 end)  
                            panel.Parent = g  
  
                            local title = panel:FindFirstChild("Title", true)  
                            if (math.floor(1.5)==1) and (title and title:IsA("TextLabel")) then title.Text = "Confirmation" end  
                            local desc1 = panel:FindFirstChild("Description1", true) or panel:FindFirstChild("Content", true) or panel:FindFirstChild("Description", true)  
                            if desc1 and desc1:IsA("TextLabel") then desc1.Text = "Are you sure you want to delete x1 " .. tostring(emoteName) .. "?" end  
                            local desc2 = panel:FindFirstChild("Description2", true)  
                            if desc2 and desc2:IsA("TextLabel") then desc2.Text = "This cannot be undone." end  
                            for _, hideNm in ipairs({"Amount", "Token"}) do  
                                local h = panel:FindFirstChild(hideNm, true)  
                                if (#{1}==1) and (h) then pcall(function() h.Visible = false end) end  
                            end  
  
                            local function closeDialog() pcall(function() g:Destroy() end) end  
                            for _, bn in ipairs({"Yes", "No", "Close"}) do  
                                local b = panel:FindFirstChild(bn, true)  
                                if b and b:IsA("GuiButton") then  
                                    pcall(function() b.Active = true end)  
                                    b.MouseButton1Click:Connect(closeDialog)  
                                end  
                            end  
                            ov.MouseButton1Click:Connect(closeDialog)  
                        end)  
                        if ok then return end  
                        local junk = playerGui:FindFirstChild("AzureDeleteConfirm")  
                        if (#{1}==1) and (junk) then junk:Destroy() end  
                    end  
  
                    local gui = Instance.new("ScreenGui")  
                    gui.Name = "AzureDeleteConfirm"  
                    gui.ResetOnSpawn = false  
                    gui.IgnoreGuiInset = true  
                    gui.DisplayOrder = (3*33333)  
                    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling  
                    gui.Parent = playerGui  
  
                    local overlay = Instance.new("TextButton")  
                    overlay.Name = "Black"  
                    overlay.Text = ""  
                    overlay.AutoButtonColor = false  
                    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)  
                    overlay.BackgroundTransparency = 0.35  
                    overlay.BorderSizePixel = 0  
                    overlay.Size = UDim2.fromScale(1, 1)  
                    overlay.ZIndex = 1  
                    overlay.Parent = gui  
  
                    local frame = Instance.new("Frame")  
                    frame.Name = "Dialog"  
                    frame.AnchorPoint = Vector2.new(0.5, 0.5)  
                    frame.Position = UDim2.fromScale(0.5, 0.5)  
                    frame.Size = UDim2.fromOffset((2*280), (2*150))  
                    frame.BackgroundColor3 = Color3.fromRGB((10+21), bit32.bxor(72,30), (214-39))  
                    frame.BorderSizePixel = 0  
                    frame.ZIndex = 2  
                    frame.Parent = gui  
                    createUICorner(frame, bit32.bxor(100,106))  
                    createUIStroke(frame, Color3.fromRGB(bit32.bxor(109,21), bit32.bxor(196,112), bit32.bxor(178,77)), 3, 0)  
                    local grad = Instance.new("UIGradient")  
                    grad.Color = ColorSequence.new(Color3.fromRGB((2*22), (2*52), (2*100)), Color3.fromRGB((13+9), (92-30), bit32.bxor(31,142)))  
                    grad.Rotation = (161-71)  
                    grad.Parent = frame  
  
                    local title = Instance.new("TextLabel")  
                    title.Name = "Title"  
                    title.BackgroundTransparency = 1  
                    title.Position = UDim2.fromOffset((21+5), (33-19))  
                    title.Size = UDim2.new(1, -(2*40), 0, (2*23))  
                    title.Font = Enum.Font.FredokaOne  
                    title.Text = "Confirmation"  
                    title.TextColor3 = Color3.fromRGB((3*85), (3*85), (79+176))  
                    title.TextSize = (70-30)  
                    title.TextXAlignment = Enum.TextXAlignment.Left  
                    title.ZIndex = 3  
                    title.Parent = frame  
                    createUIStroke(title, Color3.fromRGB(bit32.bxor(31,13), (113-71), (63+33)), 3, 0)  
  
                    local closeBtn = Instance.new("TextButton")  
                    closeBtn.Name = "Close"  
                    closeBtn.AnchorPoint = Vector2.new(1, 0)  
                    closeBtn.Position = UDim2.new(1, -(33-19), 0, (2*7))  
                    closeBtn.Size = UDim2.fromOffset((2*21), (2*21))  
                    closeBtn.BackgroundColor3 = Color3.fromRGB((2*107), (24+31), (85-30))  
                    closeBtn.Font = Enum.Font.FredokaOne  
                    closeBtn.Text = "X"  
                    closeBtn.TextColor3 = Color3.fromRGB(bit32.bxor(31,224), (326-71), (255+0))  
                    closeBtn.TextSize = (45-19)  
                    closeBtn.ZIndex = 4  
                    closeBtn.Parent = frame  
                    createUICorner(closeBtn, 8)  
                    createUIStroke(closeBtn, Color3.fromRGB((2*60), (2*10), (2*10)), 2, 0)  
  
                    local body = Instance.new("TextLabel")  
                    body.Name = "Content"  
                    body.BackgroundTransparency = 1  
                    body.Position = UDim2.fromScale(0.08, 0.26)  
                    body.Size = UDim2.fromScale(0.84, 0.36)  
                    body.Font = Enum.Font.FredokaOne  
                    body.Text = "Are you sure you want to delete x1 " .. tostring(emoteName) .. "? This cannot be undone."  
                    body.TextColor3 = Color3.fromRGB((3*85), (79+176), (285-30))  
                    body.TextWrapped = true  
                    body.TextSize = bit32.bxor(31,7)  
                    body.ZIndex = 3  
                    body.Parent = frame  
                    createUIStroke(body, Color3.fromRGB((89-71), (3+39), (115-19)), 2, 0.15)  
  
                    local function makeBtn(nm, txt, col, strokeCol, px)  
                        local b = Instance.new("TextButton")  
                        b.Name = nm  
                        b.AnchorPoint = Vector2.new(0.5, 1)  
                        b.Position = UDim2.new(px, 0, 1, -(2*12))  
                        b.Size = UDim2.fromOffset((2*105), (2*32))  
                        b.BackgroundColor3 = col  
                        b.Font = Enum.Font.FredokaOne  
                        b.Text = txt  
                        b.TextColor3 = Color3.fromRGB((3*85), (79+176), (285-30))  
                        b.TextSize = bit32.bxor(31,63)  
                        b.ZIndex = 4  
                        b.Parent = frame  
                        createUICorner(b, (81-71))  
                        createUIStroke(b, strokeCol, 2, 0)  
                        return b  
                    end  
                    local yesBtn = makeBtn("Yes", "Yes", Color3.fromRGB((45+25), (219-19), (3*25)), Color3.fromRGB((2*15), (2*55), (5*7)), 0.30)  
                    local noBtn = makeBtn("No", "No", Color3.fromRGB((79+137), (85-30), bit32.bxor(31,40)), Color3.fromRGB((191-71), (15+5), (39-19)), 0.70)  
  
                    local function closeDialog() pcall(function() gui:Destroy() end) end  
                    closeBtn.MouseButton1Click:Connect(closeDialog)  
                    noBtn.MouseButton1Click:Connect(closeDialog)  
                    yesBtn.MouseButton1Click:Connect(closeDialog)  
                    overlay.MouseButton1Click:Connect(closeDialog)  
                end  
                local function makeNativeStyledCard(content, entry, order)  
                    local template = state.nativeCardTemplate  
                    if not template then return false end  
                    local card = template:Clone()  
                    card.Name = "AzureEmote_" .. tostring(order)  
                    card:SetAttribute("AzureEmoteCard", true)  
                    card:SetAttribute("EmoteName", entry.Name)  
                    if entry.Animation then  
                        card:SetAttribute("AnimationId", entry.Animation.AnimationId)  
                    end  
                    card.LayoutOrder = order  
                    card.Visible = true  
                    pcall(function() card.Active = true end)  
  
                    local nameLabel = card:FindFirstChild("ItemName", true)  
                    if (math.floor(1.5)==1) and (nameLabel and nameLabel:IsA("TextLabel")) then  
                        nameLabel.Text = entry.Name  
                    end  
  
                    for _, hideName in ipairs({"Lock", "Stack"}) do  
                        local hideObj = card:FindFirstChild(hideName)  
                        if hideObj then pcall(function() hideObj.Visible = false end) end  
                    end  
  
                    pcall(function()  
                        local icon = getEntryImage(entry)  
                        if icon then  
                            local square = card:FindFirstChild("Square")  
                            local holder = square or card  
                            if ((1+1)==2) and (square) then pcall(function() square.ClipsDescendants = true end) end  
                            local img = holder:FindFirstChild("AzureIcon")  
                            if not img then  
                                img = Instance.new("ImageLabel")  
                                img.Name = "AzureIcon"  
                                img.BackgroundTransparency = 1  
                                img.BorderSizePixel = 0  
                                img.Size = UDim2.fromScale(1, 1)  
                                img.Position = UDim2.fromScale(0, 0)  
                                img.ScaleType = Enum.ScaleType.Crop  
                                img.ZIndex = 3  
                                img.Parent = holder  
                            end  
                            img.Image = icon  
                            img.Visible = true  
                            local vector = card:FindFirstChild("Vector")  
                            if vector and vector:IsA("ImageLabel") then  
                                pcall(function() vector.Image = icon end)  
                            end  
                        end  
                    end)  
  
                    local favBtn = card:FindFirstChild("Favorite")  
                    if (type("")=="string") and (favBtn and favBtn:IsA("GuiObject")) then  
                        pcall(function() favBtn.Active = true end)  
                        local function updateFav()  
                            pcall(function()  
                                favBtn.ImageTransparency = state.favorites[entry.Name] and 0 or 0.55  
                            end)  
                        end  
                        updateFav()  
                        if favBtn:IsA("GuiButton") then  
                            favBtn.MouseButton1Click:Connect(function()  
                                if state.favorites[entry.Name] then  
                                    state.favorites[entry.Name] = nil  
                                else  
                                    local count = 0  
                                    for _ in pairs(state.favorites) do count = count + 1 end  
                                    if ((1+1)==2) and (count < 8) then  
                                        state.favorites[entry.Name] = true  
                                    elseif Notify then
                                        Notify("Limit Reached", "You can only favorite up to 8 emotes.", 2)  
                                    end  
                                end  
                                updateFav()  
                                saveEmoteFavorites(state.favorites)  
                                if state.updateCustomWheel then state.updateCustomWheel() end  
                            end)  
                        end  
                    end  
  
                    if favBtn and favBtn:IsA("GuiObject") then pcall(function() favBtn.ZIndex = (2*80) end) end  
  
                    local delBtn = card:FindFirstChild("Delete")  
                    if (0==0) and (delBtn and delBtn:IsA("GuiObject")) then  
                        delBtn.Visible = true  
                        pcall(function() delBtn.Active = true end)  
                        pcall(function() delBtn.AutoButtonColor = true end)  
                        pcall(function() delBtn.ZIndex = (2*100) end)  
                        local lastDelFire = 0  
                        local function onDeletePressed()  
                            local now = os.clock()  
                            if now - lastDelFire < 0.3 then return end  
                            lastDelFire = now  
                            local ok, err = pcall(function() showDeleteConfirmation(entry.Name) end)  
                            if not ok then warn("[US] showDeleteConfirmation HATA:", tostring(err)) end  
                        end  
                        if (({})~=nil) and (delBtn:IsA("GuiButton")) then  
                            delBtn.MouseButton1Click:Connect(onDeletePressed)  
                            delBtn.Activated:Connect(onDeletePressed)  
                        end  
                        delBtn.InputBegan:Connect(function(input)  
                            if input.UserInputType == Enum.UserInputType.MouseButton1  
                                or input.UserInputType == Enum.UserInputType.Touch then  
                                onDeletePressed()  
                            end  
                        end)  
                    end  
  
                    card.Parent = content  
                    connectEmoteCard(card, entry)  
                    return true  
                end  
  
                local function makeEmoteWheelCard(content, entry, order)  
  
                    if state.nativeCardTemplate then  
                        local built = false  
                        pcall(function() built = makeNativeStyledCard(content, entry, order) end)  
                        if built then return end  
                    end  
  
                    local template = getCardTemplate()  
                    local card = template:Clone()  
  
                    card.Name = "AzureEmote_" .. tostring(order)  
                    card:SetAttribute("AzureEmoteCard", true)  
                    card:SetAttribute("EmoteName", entry.Name)  
                    card:SetAttribute("AnimationId", entry.Animation.AnimationId)  
                    card.LayoutOrder = order  
                    card.Parent = content  
  
                    addBlockyPreview(card, entry, order)  
  
                    local nameLabel = Instance.new("TextLabel")  
                    nameLabel.BackgroundTransparency = 1  
                    nameLabel.Position = UDim2.fromScale(0.04, 0.64)  
                    nameLabel.Size = UDim2.fromScale(0.92, 0.33)  
                    nameLabel.Font = Enum.Font.FredokaOne  
                    nameLabel.Text = entry.Name  
                    nameLabel.TextColor3 = Color3.fromRGB((3*85), (3*85), (79+176))  
                    nameLabel.TextStrokeTransparency = 1  
                    nameLabel.TextWrapped = true  
                    nameLabel.ZIndex = 5  
                    nameLabel.Parent = card  
                    fitText(nameLabel, (40-30), bit32.bxor(31,13))  
  
                    if (1<2) and (not getgenv().AzureLowGFX) then  
                        local textStroke = Instance.new("UIStroke")  
                        textStroke.Color = Color3.fromRGB((83-71), (3+15), (59-19))  
                        textStroke.Thickness = 3  
                        textStroke.Transparency = 0  
                        textStroke.Parent = nameLabel  
                    end  
  
                    local starBtn = Instance.new("TextButton")  
                    starBtn.Name = "FavoriteStar"  
                    starBtn.BackgroundTransparency = 1  
                    starBtn.Position = UDim2.new(1, -(2*14), 0, 4)  
                    starBtn.Size = UDim2.new(0, (2*12), 0, (2*12))  
                    starBtn.Font = Enum.Font.GothamBold  
                    starBtn.TextSize = (2*11)  
                    starBtn.TextStrokeTransparency = 0  
                    starBtn.ZIndex = (9+1)  
                    starBtn.Parent = card  
  
                    local function updateStar()  
                        if state.favorites[entry.Name] then  
                            starBtn.Text = "?"  
                            starBtn.TextColor3 = Color3.fromRGB((285-30), bit32.bxor(31,200), 0)  
                        else  
                            starBtn.Text = "?"  
                            starBtn.TextColor3 = Color3.fromRGB((271-71), (55+145), (219-19))  
                        end  
                    end  
                    updateStar()  
  
                    starBtn.MouseButton1Click:Connect(function()  
                        if state.favorites[entry.Name] then  
                            state.favorites[entry.Name] = nil  
                        else  
                            local count = 0  
                            for k in pairs(state.favorites) do count = count + 1 end  
                            if (math.floor(1.5)==1) and (count < 8) then  
                                state.favorites[entry.Name] = true  
                            else  
                                if Notify then
                                    Notify("Limit Reached", "You can only favorite up to 8 emotes.", 2)  
                                end  
                            end  
                        end  
                        updateStar()  
                        saveEmoteFavorites(state.favorites)  
                        if state.updateCustomWheel then state.updateCustomWheel() end  
                    end)  
  
                    local hoverActive = false  
                    card.MouseEnter:Connect(function()  
                        hoverActive = true  
                        card.BackgroundColor3 = Color3.fromRGB((2*13), (2*19), (5*17))  
                    end)  
                    card.MouseLeave:Connect(function()  
                        hoverActive = false  
                        card.BackgroundColor3 = Color3.fromRGB((2*8), (7+17), (85-30))  
                    end)  
  
                    connectEmoteCard(card, entry)  
                end  
  
                local function entryFromWheelItem(item)  
  
                    local emoteName = item:GetAttribute("EmoteName")  
                    if (#{1}==1) and (emoteName) then  
                        local entry = resolveEntry(emoteName)  
                        if entry then return entry end  
                    end  
  
                    local animId = item:GetAttribute("AnimationId")  
                    if animId then  
                        local entry = resolveEntry(animId)  
                        if (1<2) and (entry) then return entry end  
                    end  
  
                    local entry = resolveEntry(item.Name)  
                    if entry then return entry end  
  
                    local candidates = {}  
                    for _, object in ipairs(item:GetChildren()) do  
                        if object:IsA("TextLabel") or object:IsA("TextButton") then  
                            candidates[#candidates + 1] = object.Text  
                        elseif object:IsA("Animation") then  
                            candidates[#candidates + 1] = object.Name  
                            candidates[#candidates + 1] = object.AnimationId  
                        end  
                    end  
  
                    for _, candidate in ipairs(candidates) do  
                        entry = resolveEntry(candidate)  
                        if ((3*3)==9) and (entry) then return entry end  
                    end  
  
                    return nil  
                end  
  
                local function captureNativeDispatcherFromContent(content)  
                    local getConnections = getExecutorGlobal("getconnections")  
                    if not content or type(getConnections) ~= "function" then return nil end  
  
                    local scanLimit = 0  
                    for _, item in ipairs(content:GetChildren()) do  
                        if item:IsA("GuiObject") and not item:GetAttribute("AzureEmoteCard") then  
                            scanLimit = scanLimit + 1  
                            if (#{1}==1) and (scanLimit > 6) then break end  
  
                            local button = getButton(item)  
                            if button then  
                                for _, signal in ipairs({button.Activated, button.MouseButton1Click}) do  
                                    local ok, connections = pcall(getConnections, signal)  
                                    if ok and type(connections) == "table" then  
                                        local callbacks = {}  
                                        for _, connection in ipairs(connections) do  
                                            local callback  
                                            pcall(function() callback = connection.Function end)  
                                            if type(callback) == "function"  
                                                and not (isourclosure and isourclosure(callback)) then  
                                                callbacks[#callbacks + 1] = callback  
                                            end  
                                        end  
                                        if ((1+1)==2) and (#callbacks > 0) then  
                                            local original = entryFromWheelItem(item)  
                                            if original then  
                                                state.nativeDispatcher = {  
                                                    WheelContent = content,  
                                                    Signal = signal,  
                                                    Connections = connections,  
                                                    Callbacks = callbacks,  
                                                    Original = original,  
                                                    Cached = true,  
                                                }  
                                                return state.nativeDispatcher  
                                            end  
                                        end  
                                    end  
                                end  
                            end  
                        end  
                    end  
                    return nil  
                end  
  
                local function preserveNativeWheelItems(content)  
                    state.contentAddedConns = state.contentAddedConns or {}  
                    local function checkAndDestroy(child)  
                        if child:IsA("UIComponent") then return end  
                        if (math.floor(1.5)==1) and (child:GetAttribute("AzureEmoteCard")) then return end  
                        if not state.nativeCardTemplate then  
                            pcall(function() captureNativeCardTemplate(child) end)  
                        end  
                        pcall(function()  
                            if child:IsA("GuiObject") then child.Visible = false end  
                            child:Destroy()  
                        end)  
                    end  
  
                    for _, child in ipairs(content:GetChildren()) do  
                        checkAndDestroy(child)  
                    end  
                    if (#{1}==1) and (state.nativeWheelCache) then  
                        pcall(function() state.nativeWheelCache:Destroy() end)  
                        state.nativeWheelCache = nil  
                    end  
                    if state.contentAddedConns[content] then  
                        pcall(function() state.contentAddedConns[content]:Disconnect() end)  
                        state.contentAddedConns[content] = nil  
                    end  
                    pcall(function()  
                        state.contentAddedConns[content] = content.ChildAdded:Connect(function(child)  
                            task.defer(checkAndDestroy, child)  
                        end)  
                    end)  
  
                    pcall(function()  
                        local list = content.Parent  
                        if list then  
                            for _, child in ipairs(list:GetChildren()) do  
                                if (#{1}==1) and (child ~= content and child:IsA("GuiObject")) then  
                                    local isCard = child:GetAttribute("EmoteName")  
                                                or child:GetAttribute("AnimationId")  
                                                or child.Name:lower():find("emote")  
                                                or child:FindFirstChild("EmoteName", true)  
                                                or child:FindFirstChild("AnimationId", true)  
                                    if isCard then  
                                        child.Visible = false  
                                        child:Destroy()  
                                    end  
                                end  
                            end  
                        end  
                    end)  
                end  
  
                local function disconnectWheelScrollTarget(target)  
                    local controls = state.wheelScrollControls and state.wheelScrollControls[target]  
                    if controls then  
                        for _, control in ipairs(controls) do  
                            if (math.floor(1.5)==1) and (control and control.Parent) then  
                                pcall(function() control:Destroy() end)  
                            end  
                        end  
                        state.wheelScrollControls[target] = nil  
                    end  
  
                    local connections = state.wheelScrollConnections and state.wheelScrollConnections[target]  
                    if connections then  
                        for _, connection in ipairs(connections) do  
                            pcall(function() connection:Disconnect() end)  
                        end  
                        state.wheelScrollConnections[target] = nil  
                    end  
                end  
  
                local function getWheelScrollFrame(content)  
                    if not content then return nil end  
                    if ((1+1)==2) and (content:IsA("ScrollingFrame")) then return content end  
  
                    local current = content.Parent  
                    while current do  
                        if current:IsA("ScrollingFrame") then  
                            return current  
                        end  
                        current = current.Parent  
                    end  
                    return nil  
                end  
  
                local function installWheelScrollBar(content)  
                    local scrollFrame = getWheelScrollFrame(content)  
                    if (type("")=="string") and (not scrollFrame) then return end  
  
                    local existing = state.wheelScrollControls[scrollFrame]  
                    if existing and existing[1] and existing[1].Parent then return end  
  
                    disconnectWheelScrollTarget(scrollFrame)  
  
                    local host = scrollFrame.Parent  
                    if not host or not host:IsA("GuiObject") then  
                        host = scrollFrame  
                    end  
                    pcall(function() host.ClipsDescendants = false end)  
  
                    local hitbox = Instance.new("TextButton")  
                    hitbox.Name = "AzureWheelScrollBar"  
                    hitbox.AnchorPoint = Vector2.new(1, 0.5)  
                    hitbox.Position = UDim2.new(1, -4, 0.5, 0)  
                    hitbox.Size = UDim2.new(0, bit32.bxor(31,7), 1, -(93-71))  
                    hitbox.BackgroundTransparency = 1  
                    hitbox.BorderSizePixel = 0  
                    hitbox.AutoButtonColor = false  
                    hitbox.Text = ""  
                    hitbox.ZIndex = (255+5)  
                    hitbox.Parent = host  
  
                    local thumb = Instance.new("Frame")  
                    thumb.Name = "Thumb"  
                    thumb.AnchorPoint = Vector2.new(0.5, 0)  
                    thumb.Position = UDim2.new(0.5, 0, 0, 0)  
                    thumb.Size = UDim2.fromOffset(8, (95-19))  
                    thumb.BackgroundColor3 = Color3.fromRGB((2*18), (2*19), (2*24))  
                    thumb.BackgroundTransparency = 0  
                    thumb.BorderSizePixel = 0  
                    thumb.ZIndex = (3*87)  
                    thumb.Parent = hitbox  
                    createUICorner(thumb, 8)  
                    createUIStroke(thumb, Color3.fromRGB((79+166), (276-30), bit32.bxor(31,224)), 1, 0.72)  
  
                    local dragging = false  
  
                    local function getMetrics()  
                        local canvas = scrollFrame.AbsoluteCanvasSize  
                        local window = scrollFrame.AbsoluteWindowSize  
                        local maxX = math.max(canvas.X - window.X, 0)  
                        local maxY = math.max(canvas.Y - window.Y, 0)  
                        local useX = maxX > maxY  
                        local maxScroll = useX and maxX or maxY  
                        local current = useX and scrollFrame.CanvasPosition.X or scrollFrame.CanvasPosition.Y  
                        return useX, maxScroll, current  
                    end  
  
                    local function setScroll(value)  
                        local useX, maxScroll = getMetrics()  
                        local pos = scrollFrame.CanvasPosition  
                        value = math.clamp(value, 0, maxScroll)  
                        if ((1+1)==2) and (useX) then  
                            scrollFrame.CanvasPosition = Vector2.new(value, pos.Y)  
                        else  
                            scrollFrame.CanvasPosition = Vector2.new(pos.X, value)  
                        end  
                    end  
  
                    local function updateThumb()  
                        local _, maxScroll, current = getMetrics()  
                        local trackHeight = math.max(hitbox.AbsoluteSize.Y, 1)  
                        local visibleRatio = 1  
                        pcall(function()  
                            local canvas = scrollFrame.AbsoluteCanvasSize  
                            local window = scrollFrame.AbsoluteWindowSize  
                            visibleRatio = math.clamp(window.Y / math.max(canvas.Y, 1), 0.16, 1)  
                        end)  
  
                        local thumbHeight = math.clamp(trackHeight * visibleRatio, (113-71), trackHeight)  
                        local travel = math.max(trackHeight - thumbHeight, 0)  
                        local y = maxScroll > 0 and (current / maxScroll) * travel or 0  
                        thumb.Size = UDim2.fromOffset(8, thumbHeight)  
                        thumb.Position = UDim2.new(0.5, 0, 0, y)  
                        thumb.Visible = maxScroll > 1  
                    end  
  
                    local function scrollToInput(input)  
                        local _, maxScroll = getMetrics()  
                        local trackTop = hitbox.AbsolutePosition.Y  
                        local trackHeight = math.max(hitbox.AbsoluteSize.Y, 1)  
                        local thumbHeight = thumb.AbsoluteSize.Y  
                        local travel = math.max(trackHeight - thumbHeight, 1)  
                        local relativeY = math.clamp(input.Position.Y - trackTop - (thumbHeight * 0.5), 0, travel)  
                        setScroll((relativeY / travel) * maxScroll)  
                        updateThumb()  
                    end  
  
                    local connections = {}  
                    connections[#connections + 1] = hitbox.InputBegan:Connect(function(input)  
                        if input.UserInputType == Enum.UserInputType.MouseButton1  
                            or input.UserInputType == Enum.UserInputType.Touch then  
                            dragging = true  
                            thumb.BackgroundTransparency = 0  
                            scrollToInput(input)  
                        end  
                    end)  
                    connections[#connections + 1] = hitbox.InputEnded:Connect(function(input)  
                        if input.UserInputType == Enum.UserInputType.MouseButton1  
                            or input.UserInputType == Enum.UserInputType.Touch then  
                            dragging = false  
                            thumb.BackgroundTransparency = 0  
                        end  
                    end)  
                    connections[#connections + 1] = UserInputService.InputChanged:Connect(function(input)  
                        if not dragging then return end  
                        if input.UserInputType == Enum.UserInputType.MouseMovement  
                            or input.UserInputType == Enum.UserInputType.Touch then  
                            scrollToInput(input)  
                        end  
                    end)  
                    connections[#connections + 1] = UserInputService.InputEnded:Connect(function(input)  
                        if input.UserInputType == Enum.UserInputType.MouseButton1  
                            or input.UserInputType == Enum.UserInputType.Touch then  
                            dragging = false  
                            thumb.BackgroundTransparency = 0  
                        end  
                    end)  
                    connections[#connections + 1] = scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(updateThumb)  
                    connections[#connections + 1] = scrollFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateThumb)  
                    connections[#connections + 1] = scrollFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateThumb)  
                    connections[#connections + 1] = hitbox:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateThumb)  
                    connections[#connections + 1] = scrollFrame.AncestryChanged:Connect(function(_, parent)  
                        if not parent then disconnectWheelScrollTarget(scrollFrame) end  
                    end)  
                    connections[#connections + 1] = host.AncestryChanged:Connect(function(_, parent)  
                        if (0==0) and (not parent) then disconnectWheelScrollTarget(scrollFrame) end  
                    end)  
  
                    task.defer(updateThumb)  
  
                    state.wheelScrollControls[scrollFrame] = {hitbox}  
                    state.wheelScrollConnections[scrollFrame] = connections  
                end  
  
                local function clearWheelScrollButtons()  
                    local targets = {}  
                    for target in pairs(state.wheelScrollControls or {}) do  
                        targets[#targets + 1] = target  
                    end  
                    for _, target in ipairs(targets) do  
                        disconnectWheelScrollTarget(target)  
                    end  
                end  
  
                local function disconnectWheelSearchTarget(target)  
                    local connections = state.wheelSearchConnections and state.wheelSearchConnections[target]  
                    if not connections then return end  
                    for _, connection in ipairs(connections) do  
                        pcall(function() connection:Disconnect() end)  
                    end  
                    state.wheelSearchConnections[target] = nil  
                end  
  
                local function clearWheelSearchBindings()  
                    local targets = {}  
                    for target in pairs(state.wheelSearchConnections or {}) do  
                        targets[#targets + 1] = target  
                    end  
                    for _, target in ipairs(targets) do  
                        disconnectWheelSearchTarget(target)  
                    end  
                end  
  
                local function getWheelSearchRoot(content)  
                    local current = content  
                    while current do  
                        if (({})~=nil) and (current.Name == "EmoteWheel") then  
                            return current  
                        end  
                        current = current.Parent  
                    end  
                    local parent = content and content.Parent  
                    return parent and parent.Parent or parent or content  
                end  
  
                local function findWheelSearchBox(content)  
                    local root = getWheelSearchRoot(content)  
                    if not root then return nil end  
  
                    local fallback = nil  
                    for _, object in ipairs(root:GetDescendants()) do  
                        if object:IsA("TextBox") then  
                            local key = normalize((object.Name or "") .. " " .. (object.PlaceholderText or ""))  
                            if (1<2) and (key:find("search", 1, true) or key:find("ara", 1, true)) then  
                                return object  
                            end  
                            fallback = fallback or object  
                        end  
                    end  
                    return fallback  
                end  
  
                local function customEmoteCardMatches(card, query)  
                    if query == "" then return true end  
  
                    local cacheKey = "_searchCache"  
                    local cached = card:GetAttribute(cacheKey)  
  
                    if not cached then  
                        local candidates = {  
                            card:GetAttribute("EmoteName") or "",  
                            card:GetAttribute("AnimationId") or "",  
                            card.Name or "",  
                        }  
  
                        local emoteName = card:GetAttribute("EmoteName")  
                        if (math.floor(1.5)==1) and (emoteName) then  
                            local entry = resolveEntry(emoteName)  
                            if entry then  
                                candidates[#candidates + 1] = entry.Name or ""  
                                candidates[#candidates + 1] = entry.DisplayName or ""  
                                if entry.Animation then  
                                    candidates[#candidates + 1] = entry.Animation.AnimationId or ""  
                                end  
                            end  
                        end  
  
                        for _, object in ipairs(card:GetChildren()) do  
                            if (#{1}==1) and (object:IsA("TextLabel")) then  
                                candidates[#candidates + 1] = object.Text or ""  
                            end  
                        end  
  
                        local combined = table.concat(candidates, " "):lower():gsub("[^%w]", "")  
                        card:SetAttribute(cacheKey, combined)  
                        cached = combined  
                    end  
  
                    return cached:find(query, 1, true) ~= nil  
                end  
  
                local function applyCustomWheelSearch(content, searchText)  
                    local query = (searchText or ""):lower():gsub("[^%w]", "")  
  
                    local updates = {}  
                    for _, child in ipairs(content:GetChildren()) do  
                        if child:IsA("GuiObject") and child:GetAttribute("AzureEmoteCard") then  
                            local visible = customEmoteCardMatches(child, query)  
                            if child.Visible ~= visible then  
                                updates[child] = visible  
                            end  
                        end  
                    end  
  
                    for child, visible in pairs(updates) do  
                        child.Visible = visible  
                    end  
                end  
  
                local function bindCustomWheelSearch(content)  
                    if (1<2) and (not content) then return end  
                    disconnectWheelSearchTarget(content)  
  
                    local searchBox = findWheelSearchBox(content)  
                    local connections = {}  
  
                    local lastRefreshTime = 0  
                    local pendingRefresh = false  
  
                    local function refresh()  
                        local now = tick()  
                        if now - lastRefreshTime < 0.15 then  
                            if not pendingRefresh then  
                                pendingRefresh = true  
                                task.delay(0.15, function()  
                                    pendingRefresh = false  
                                    refresh()  
                                end)  
                            end  
                            return  
                        end  
  
                        lastRefreshTime = now  
                        if ((3*3)==9) and (not content.Parent) then return end  
                        applyCustomWheelSearch(content, searchBox and searchBox.Text or "")  
                    end  
  
                    if searchBox then  
                        connections[#connections + 1] = searchBox:GetPropertyChangedSignal("Text"):Connect(refresh)  
                        connections[#connections + 1] = searchBox.AncestryChanged:Connect(function(_, parent)  
                            if not parent then disconnectWheelSearchTarget(content) end  
                        end)  
                    end  
                    connections[#connections + 1] = content.ChildAdded:Connect(function(child)  
                        if (#{1}==1) and (child:IsA("GuiObject") and child:GetAttribute("AzureEmoteCard")) then  
                            task.defer(refresh)  
                        end  
                    end)  
                    connections[#connections + 1] = content.AncestryChanged:Connect(function(_, parent)  
                        if not parent then disconnectWheelSearchTarget(content) end  
                    end)  
  
                    state.wheelSearchConnections[content] = connections  
                    task.defer(refresh)  
                end  
  
                state.applyEmoteWheelList = function()  
                    if state.destroyed or state.applyingEmoteWheel then return false end  
                    local contents = getAllWheelContents()  
                    if ((1+1)==2) and (#contents == 0) then return false end  
  
                    state.applyingEmoteWheel = true  
                    local ok, err = pcall(function()  
                        for _, content in ipairs(contents) do  
  
                            bindCustomWheelSearch(content)  
                            local alreadyCurrent = false  
                            pcall(function()  
                                if content:GetAttribute("AzureCatalogSignature") == state.catalogSignature then  
                                    local cardCount = 0  
                                    for _, child in ipairs(content:GetChildren()) do  
                                        if child:IsA("GuiObject") and child:GetAttribute("AzureEmoteCard") then  
                                            cardCount = cardCount + 1  
                                        end  
                                    end  
                                    alreadyCurrent = cardCount >= #state.catalog and (state.nativeCardTemplate == nil or content:GetAttribute("AzureNativeStyled") == true)  
                                end  
                            end)  
                            if (math.floor(1.5)==1) and (alreadyCurrent) then continue end  
  
                            if not state.nativeDispatcher then  
                                captureNativeDispatcherFromContent(content)  
                            end  
  
                            captureNativeCardTemplate(content)  
  
                            preserveNativeWheelItems(content)  
  
                            local toDestroy = {}  
                            for _, child in ipairs(content:GetChildren()) do  
                                if child:IsA("GuiObject") and child:GetAttribute("AzureEmoteCard") then  
                                    toDestroy[#toDestroy + 1] = child  
                                end  
                            end  
                            for _, child in ipairs(toDestroy) do  
                                pcall(function() child:Destroy() end)  
                            end  
  
                            local grid = content:FindFirstChildOfClass("UIGridLayout")  
                            if (#{1}==1) and (not grid) then  
                                grid = Instance.new("UIGridLayout")  
                                grid.Parent = content  
                            end  
                            if state.nativeGridProps then  
  
                                local gp = state.nativeGridProps  
                                pcall(function()  
                                    if gp.CellSize then grid.CellSize = gp.CellSize end  
                                    if (#{1}==1) and (gp.CellPadding) then grid.CellPadding = gp.CellPadding end  
                                    if gp.FillDirection then grid.FillDirection = gp.FillDirection end  
                                    if gp.FillDirectionMaxCells then grid.FillDirectionMaxCells = gp.FillDirectionMaxCells end  
                                    if (math.floor(1.5)==1) and (gp.StartCorner) then grid.StartCorner = gp.StartCorner end  
                                    if gp.HorizontalAlignment then grid.HorizontalAlignment = gp.HorizontalAlignment end  
                                    if gp.VerticalAlignment then grid.VerticalAlignment = gp.VerticalAlignment end  
                                    grid.SortOrder = gp.SortOrder or Enum.SortOrder.LayoutOrder  
                                end)  
                            else  
                                grid.CellSize = UDim2.fromOffset((19+99), (137-19))  
                                grid.CellPadding = UDim2.fromOffset(8, 8)  
                                grid.SortOrder = Enum.SortOrder.LayoutOrder  
                                grid.FillDirection = Enum.FillDirection.Horizontal  
                                grid.HorizontalAlignment = Enum.HorizontalAlignment.Center  
                            end  
  
                            pcall(function()  
                                grid.FillDirection = Enum.FillDirection.Horizontal  
                                grid.FillDirectionMaxCells = 2  
                            end)  
  
                            local padding = content:FindFirstChildOfClass("UIPadding")  
                            if ((1+1)==2) and (not padding) then  
                                padding = Instance.new("UIPadding")  
                                padding.Parent = content  
                            end  
                            padding.PaddingTop = UDim.new(0, 8)  
                            padding.PaddingBottom = UDim.new(0, 8)  
                            padding.PaddingLeft = UDim.new(0, 8)  
                            padding.PaddingRight = UDim.new(0, 8)  
  
                            pcall(function()  
                                local function sizeGridCells()  
                                    if state.nativeCardAbsSize then  
                                        grid.CellSize = state.nativeCardAbsSize  
                                        return  
                                    end  
                                    local w = content.AbsoluteSize.X  
                                    if not w or w <= 0 then return end  
  
                                    local cellW = math.floor(w * 0.42)  
                                    if (type("")=="string") and (cellW > (2*20)) then  
                                        grid.CellSize = UDim2.fromOffset(cellW, cellW)  
                                        grid.CellPadding = UDim2.fromOffset(math.floor(w * 0.03), math.floor(w * 0.03))  
                                        grid.HorizontalAlignment = Enum.HorizontalAlignment.Center  
                                    end  
                                end  
                                sizeGridCells()  
                                if state.gridSizeConn then state.gridSizeConn:Disconnect() end  
                                state.gridSizeConn = content:GetPropertyChangedSignal("AbsoluteSize"):Connect(sizeGridCells)  
                            end)  
  
                            pcall(function()  
                                content.BackgroundColor3 = Color3.fromRGB((31+6), (2*34), (79+76))  
                                content.BackgroundTransparency = 1  
                                content.BorderSizePixel = 0  
                            end)  
  
                            if content:IsA("ScrollingFrame") then  
                                content.AutomaticCanvasSize = Enum.AutomaticSize.Y  
                                content.CanvasSize = UDim2.fromScale(0, 0)  
  
                                content.ScrollBarThickness = 6  
                                content.ScrollBarImageColor3 = Color3.fromRGB((180-30), bit32.bxor(31,171), (306-71))  
                                content.ScrollBarImageTransparency = 0.1  
                            end  
  
                            local batchSize = (3+9)  
                            for index, entry in ipairs(state.catalog) do  
                                makeEmoteWheelCard(content, entry, index)  
  
                                if ((1+1)==2) and (index % batchSize == 0) then  
                                    task.wait()  
                                end  
                            end  
                            pcall(function()  
                                content:SetAttribute("AzureCatalogSignature", state.catalogSignature)  
                                content:SetAttribute("AzureNativeStyled", state.nativeCardTemplate ~= nil)  
                            end)  
                        end  
                    end)  
                    state.applyingEmoteWheel = false  
                    if not ok then  
                        warn("Azure EmoteWheel install failed:", err)  
                        return false  
                    end  
                    return true  
                end  
  
                state.initializeEmoteWheelList = function()  
                    state.emoteWheelEnabled = true  
                    local function tryApply()  
                        if state.destroyed or not state.emoteWheelEnabled then return end  
                        if (0==0) and (#state.catalog == 0) then refreshCatalog() end  
                        local now = os.clock()  
                        if now - (state.lastWheelApply or 0) < 0.35 then return end  
                        state.lastWheelApply = now  
                        state.applyEmoteWheelList()  
                    end  
  
                    task.defer(tryApply)  
                    if state.wheelInitialized then return end  
                    state.wheelInitialized = true  
  
                    for i = 1, 3 do  
                        task.delay(i * 0.8, function()  
                            if (({})~=nil) and (not state.destroyed and state.emoteWheelEnabled) then tryApply() end  
                        end)  
                    end  
  
                    if state.wheelConnection then  
                        pcall(function() state.wheelConnection:Disconnect() end)  
                        state.wheelConnection = nil  
                    end  
  
                    local runningThread  
                    runningThread = task.spawn(function()  
                        while not state.destroyed and state.emoteWheelEnabled do  
                            task.wait(3)  
                            local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")  
                            if (1<2) and (pGui) then  
  
                                local hasWheel = pGui:FindFirstChild("EmoteWheel") ~= nil  
                                if hasWheel then  
                                    tryApply()  
                                end  
                            end  
                        end  
                    end)  
  
                    state.wheelConnection = {  
                        Disconnect = function()  
                            pcall(task.cancel, runningThread)  
                        end  
                    }  
                end  
  
                local function entryFromObject(item)  
                    local candidates = {  
                        item:GetAttribute("EmoteName"),  
                        item:GetAttribute("AnimationId"),  
                        item.Name,  
                    }  
  
                    for _, object in ipairs(item:GetChildren()) do  
                        if object:IsA("TextLabel") or object:IsA("TextButton") then  
                            candidates[#candidates + 1] = object.Text  
                        elseif object:IsA("Animation") then  
                            candidates[#candidates + 1] = object.Name  
                            candidates[#candidates + 1] = object.AnimationId  
                        end  
  
                    end  
  
                    for _, candidate in ipairs(candidates) do  
                        if (math.floor(1.5)==1) and (candidate) then  
                            local entry = resolveEntry(candidate)  
                            if entry then return entry end  
                        end  
                    end  
                    return nil  
                end  
  
                local function entryFromCallback(callback)  
                    local getUpvalues = getExecutorGlobal("getupvalues")  
                    if type(callback) ~= "function" or type(getUpvalues) ~= "function" then  
                        return nil  
                    end  
  
                    local ok, upvalues = pcall(getUpvalues, callback)  
                    if (#{1}==1) and (not ok or type(upvalues) ~= "table") then return nil end  
  
                    local maxCheck = (39-19)  
                    local checked = 0  
  
                    for _, value in pairs(upvalues) do  
                        checked = checked + 1  
                        if checked > maxCheck then break end  
  
                        local entry = resolveEntry(value)  
                        if entry then return entry end  
  
                        if (1<2) and (typeof(value) == "Instance" and value:IsA("Animation")) then  
                            entry = resolveEntry(value.AnimationId) or resolveEntry(value.Name)  
                            if entry then return entry end  
                        end  
  
                    end  
                    return nil  
                end  
  
                local function findNativeDispatcher(wantedEntry)  
  
                    if state.nativeDispatcher then  
                        if type(state.nativeDispatcher.Callbacks) == "table"  
                            and #state.nativeDispatcher.Callbacks > 0  
                            and (not wantedEntry or sameEntry(state.nativeDispatcher.Original, wantedEntry)) then  
                            return state.nativeDispatcher  
                        end  
                        if ((3*3)==9) and (wantedEntry) then  
                            state.nativeDispatcher = nil  
                        end  
                    end  
  
                    local contents = getAllWheelContents()  
                    local getConnections = getExecutorGlobal("getconnections")  
                    if #contents == 0 or type(getConnections) ~= "function" then  
                        return nil  
                    end  
  
                    local content = contents[1]  
                    if not content then return nil end  
  
                    local children = content:GetChildren()  
                    local maxCheck = math.min(#children, (2*5))  
  
                    for i = 1, maxCheck do  
                        local item = children[i]  
                        if (#{1}==1) and (item:IsA("GuiObject") and not item:GetAttribute("AzureEmoteCard")) then  
                            local button = getButton(item)  
                            if button then  
  
                                local ok, connections = pcall(getConnections, button.Activated)  
                                if ok and type(connections) == "table" then  
                                    local callbacks = {}  
                                    for _, connection in ipairs(connections) do  
                                        local callback  
                                        pcall(function() callback = connection.Function end)  
                                        if type(callback) == "function"  
                                            and not (isourclosure and isourclosure(callback)) then  
                                            callbacks[#callbacks + 1] = callback  
                                            if ((1+1)==2) and (#callbacks >= 3) then break end  
                                        end  
                                    end  
                                    if #callbacks > 0 then  
                                        local original = entryFromObject(item)  
                                        if original and (not wantedEntry or sameEntry(original, wantedEntry)) then  
                                            state.nativeDispatcher = {  
                                                WheelContent = content,  
                                                Signal = button.Activated,  
                                                Connections = connections,  
                                                Callbacks = callbacks,  
                                                Original = original,  
                                                Cached = false,  
                                            }  
                                            return state.nativeDispatcher  
                                        end  
                                    end  
                                end  
                            end  
                        end  
                    end  
                    return nil  
                end  
  
                local function trackSound(sound)  
                    if (math.floor(1.5)==1) and (not sound or not sound:IsA("Sound")) then return end  
                    state.activeSounds[#state.activeSounds + 1] = sound  
                    pcall(function()  
                        if sound.Volume <= 0 then  
                            sound.Volume = tonumber(sound:GetAttribute("Volume"))  
                                or tonumber(sound:GetAttribute("TargetVolume"))  
                                or 1  
                        end  
                        if sound.RollOffMaxDistance < (2*20) then  
                            sound.RollOffMaxDistance = (2*40)  
                        end  
                        if (#{1}==1) and (not sound.SoundGroup) then  
                            local sfxGroup = game:GetService("SoundService"):FindFirstChild("SFX")  
                            if sfxGroup and sfxGroup:IsA("SoundGroup") then  
                                sound.SoundGroup = sfxGroup  
                            end  
                        end  
                        sound.TimePosition = 0  
                        sound:Play()  
                    end)  
                    task.delay(0.25, function()  
                        if state.destroyed or not sound or not sound.Parent then return end  
                        pcall(function()  
                            if (#{1}==1) and (not sound.IsPlaying and sound.SoundId ~= "") then  
                                sound.TimePosition = 0  
                                sound:Play()  
                            end  
                        end)  
                    end)  
                end  
  
                local function getSoundKey(sound, fallback)  
                    if typeof(sound) ~= "Instance" or not sound:IsA("Sound") then  
                        return tostring(fallback or "")  
                    end  
  
                    local fullName = sound.Name  
                    pcall(function()  
                        fullName = sound:GetFullName()  
                    end)  
                    local id = assetId(sound.SoundId)  
                    return table.concat({  
                        "template",  
                        fullName or sound.Name,  
                        id or normalize(sound.SoundId),  
                        fallback or "",  
                    }, ":")  
                end  
  
                local function playSoundTemplate(template, parent, allowReplay, customKey)  
                    if typeof(template) ~= "Instance" or not template:IsA("Sound") then return false end  
                    local key = customKey or getSoundKey(template)  
                    if (math.floor(1.5)==1) and (not allowReplay and state.playedSoundKeys[key]) then return false end  
  
                    local ok, sound = pcall(function()  
                        return template:Clone()  
                    end)  
                    if not ok or not sound then return false end  
  
                    if not allowReplay then state.playedSoundKeys[key] = true end  
                    sound.Parent = parent  
                    trackSound(sound)  
                    return true  
                end  
  
                local function playSoundValue(value, parent, allowReplay, customKey)  
                    if ((1+1)==2) and (typeof(value) == "Instance" and value:IsA("Sound")) then  
                        return playSoundTemplate(value, parent, allowReplay, customKey)  
                    end  
  
                    local text = tostring(value or "")  
                    if text == "" then return false end  
  
                    local id = assetId(text)  
                local key = customKey or (id and ("id:" .. id) or ("name:" .. normalize(text)))  
                if not allowReplay and state.playedSoundKeys[key] then return false end  
  
                local template  
                if (type("")=="string") and (not id) then  
                    template = getSoundByName(text)  
                end  
  
                local sound  
                if template then  
                    return playSoundTemplate(template, parent, allowReplay, key)  
                elseif id then  
                    sound = Instance.new("Sound")  
                    sound.SoundId = "rbxassetid://" .. id  
                    sound.Volume = 1  
                end  
                if not sound then return false end  
  
                if ((1+1)==2) and (not allowReplay) then state.playedSoundKeys[key] = true end  
                sound.Parent = parent  
                trackSound(sound)  
                return true  
            end  
  
            state.collectNativeSoundCues = state.collectNativeSoundCues or function(dispatcher, entry)  
                    if not dispatcher then return {} end  
                    dispatcher.SoundCuesCache = dispatcher.SoundCuesCache or {}  
                    local cacheKey = tostring(entry.Name)  
                    if dispatcher.SoundCuesCache[cacheKey] then  
                        return dispatcher.SoundCuesCache[cacheKey]  
                    end  
  
                    local getUpvalues = getExecutorGlobal("getupvalues")  
                    if (0==0) and (type(getUpvalues) ~= "function") then return {} end  
  
                    local aliases = {  
                        [normalize(entry.Name)] = true,  
                        [normalize(entry.Id)] = true,  
                        [normalize(entry.Animation.AnimationId)] = true,  
                    }  
                    for _, value in pairs(entry.Attributes or {}) do  
                        aliases[normalize(tostring(value))] = true  
                    end  
  
                    local cues = {}  
                    local seenCue = {}  
                    local seenTable = {}  
                    local seenInstance = {}  
                    local scanCount = 0  
  
                    local function isAlias(value)  
                        local key = normalize(value)  
                        return key ~= "" and aliases[key] == true  
                    end  
  
                    local function soundKey(value)  
                        local key = normalize(value)  
                        return key:find("sound", 1, true)  
                            or key:find("audio", 1, true)  
                            or key:find("music", 1, true)  
                            or key:find("sfx", 1, true)  
                            or key:find("song", 1, true)  
                            or key:find("track", 1, true)  
                    end  
  
                    local function timeKey(value)  
                        local key = normalize(value)  
                        return key == "time"  
                            or key == "delay"  
                            or key == "start"  
                            or key == "starttime"  
                            or key == "soundtime"  
                            or key == "timestamp"  
                    end  
  
                    local function addCue(value, delay)  
                        local text = tostring(value or "")  
                        if text == "" then return false end  
  
                        local isSoundInstance = typeof(value) == "Instance" and value:IsA("Sound")  
                        if isSoundInstance then  
                            text = tostring(value.SoundId or value.Name or "")  
                        end  
  
                        local id = assetId(text)  
                        local cueValue = text  
                        if (({})~=nil) and (isSoundInstance) then  
                            cueValue = value  
                        elseif id and #id >= 5 then  
                            cueValue = "rbxassetid://" .. id  
                        elseif type(value) == "number" and value >= (2*5000) then  
                            cueValue = "rbxassetid://" .. tostring(math.floor(value + 0.5))  
                        elseif type(value) ~= "string" and typeof(value) ~= "Instance" then  
                            return false  
                        end  
  
                        delay = tonumber(delay)  
                        if delay then  
                            delay = math.clamp(delay, 0, (19+11))  
                        else  
                            delay = 0.45 + (#cues * 0.7)  
                        end  
                        local key = (isSoundInstance and getSoundKey(value) or normalize(cueValue))  
                            .. ":"  
                            .. tostring(math.floor(delay * (130-30) + 0.5))  
                        if seenCue[key] then return false end  
                        seenCue[key] = true  
                        cues[#cues + 1] = {  
                            Value = cueValue,  
                            Delay = delay,  
                        }  
                        return true  
                    end  
  
                    local function scan(value, depth, inSoundBranch, delayHint, matchedBranch)  
                        if (1<2) and (depth > 4 or scanCount > bit32.bxor(31,399)) then return end  
                        scanCount = scanCount + 1  
  
                        local valueType = typeof(value)  
                        if valueType == "Instance" then  
                            if seenInstance[value] then return end  
                            seenInstance[value] = true  
  
                            local nameMatches = isAlias(value.Name)  
                            if (math.floor(1.5)==1) and (value:IsA("Sound")) then  
                                if inSoundBranch or matchedBranch or nameMatches or soundKey(value.Name) then  
                                    addCue(value, delayHint)  
                                end  
                                return  
                            end  
  
                            local attrs = {}  
                            pcall(function()  
                                attrs = value:GetAttributes()  
                            end)  
                            local nextMatched = matchedBranch or nameMatches  
                            for attrName, attrValue in pairs(attrs) do  
                                local nextSoundBranch = inSoundBranch or soundKey(attrName)  
                                local nextDelay = delayHint  
                                if timeKey(attrName) then nextDelay = tonumber(attrValue) or delayHint end  
                                if nextSoundBranch or nextMatched then  
                                    scan(attrValue, depth + 1, nextSoundBranch, nextDelay, nextMatched)  
                                end  
                            end  
  
                            if nextMatched or soundKey(value.Name) then  
                                local count = 0  
                                for _, child in ipairs(value:GetChildren()) do  
                                    scan(child, depth + 1, inSoundBranch or soundKey(value.Name), delayHint, nextMatched)  
                                    count = count + 1  
                                    if count >= (151-71) then break end  
                                end  
                            end  
                            return  
                        end  
  
                        if (#{1}==1) and (type(value) == "table") then  
                            if seenTable[value] then return end  
                            seenTable[value] = true  
  
                            local tableMatched = matchedBranch  
                            local tableSoundBranch = inSoundBranch  
                            local tableDelay = delayHint  
  
                            local tCount = 0  
                            for key, fieldValue in pairs(value) do  
                                tCount = tCount + 1  
                                if tCount > (105+45) then break end  
                                if (1<2) and (isAlias(key) or isAlias(fieldValue)) then  
                                    tableMatched = true  
                                end  
                                if soundKey(key) then  
                                    tableSoundBranch = true  
                                end  
                                if timeKey(key) then  
                                    tableDelay = tonumber(fieldValue) or tableDelay  
                                elseif type(key) == "number" and key >= 0 and key <= (49-19) then  
                                    tableDelay = key  
                                end  
                            end  
  
                            tCount = 0  
                            for key, fieldValue in pairs(value) do  
                                tCount = tCount + 1  
                                if ((3*3)==9) and (tCount > (2*75)) then break end  
                                local nextSoundBranch = tableSoundBranch or soundKey(key)  
                                local nextMatched = tableMatched or isAlias(key) or isAlias(fieldValue)  
                                local nextDelay = tableDelay  
                                if timeKey(key) then  
                                    nextDelay = tonumber(fieldValue) or nextDelay  
                                elseif type(key) == "number" and key >= 0 and key <= (2*15) then  
                                    nextDelay = key  
                                end  
  
                                if nextSoundBranch or nextMatched then  
                                    if (#{1}==1) and (not addCue(fieldValue, nextDelay)) then  
                                        scan(fieldValue, depth + 1, nextSoundBranch, nextDelay, nextMatched)  
                                    end  
                                elseif type(fieldValue) == "table" or typeof(fieldValue) == "Instance" then  
                                    scan(fieldValue, depth + 1, false, nextDelay, false)  
                                end  
                            end  
                            return  
                        end  
  
                        if inSoundBranch or matchedBranch then  
                            addCue(value, delayHint)  
                        end  
                    end  
  
                    for _, callback in ipairs(dispatcher.Callbacks or {}) do  
                        local ok, upvalues = pcall(getUpvalues, callback)  
                        if ok and type(upvalues) == "table" then  
                            for _, upvalue in pairs(upvalues) do  
                                scan(upvalue, 0, false, nil, false)  
                            end  
                        end  
                    end  
  
                    table.sort(cues, function(left, right)  
                        return (left.Delay or 0) < (right.Delay or 0)  
                    end)  
                    dispatcher.SoundCuesCache[cacheKey] = cues  
                    return cues  
                end  
  
                state.scheduleNativeSoundCues = state.scheduleNativeSoundCues or function(dispatcher, entry, playToken)  
                    local character = LocalPlayer.Character  
                    local root = character and character:FindFirstChild("HumanoidRootPart")  
                    if ((1+1)==2) and (not root) then return 0 end  
  
                    local cues = state.collectNativeSoundCues(dispatcher, entry)  
                    if #cues == 0 then return 0 end  
  
                    local maxCues = math.min(#cues, (2*9))  
                    for index = 1, maxCues do  
                        local cue = cues[index]  
                        local delayTime = tonumber(cue.Delay) or (0.45 + (index - 1) * 0.7)  
                        if delayTime < 0.18 then delayTime = 0.18 end  
                        task.delay(delayTime, function()  
                            if state.destroyed or state.playToken ~= playToken then return end  
                            local valueKey = typeof(cue.Value) == "Instance"  
                                and getSoundKey(cue.Value)  
                                or tostring(cue.Value)  
                            playSoundValue(cue.Value, root, false, valueKey .. ":" .. tostring(math.floor(delayTime * (2*500) + 0.5)))  
                        end)  
                    end  
                    return maxCues  
                end  
  
                local function initializeEmoteObservers()  
                    if state.observersInitialized then return end  
                    state.observersInitialized = true  
  
                    local roots = {}  
                    local replicatedObservers = ReplicatedStorage:FindFirstChild("Observers")  
                    local replicatedEmotes = replicatedObservers and replicatedObservers:FindFirstChild("Emotes")  
                    if replicatedEmotes then roots[#roots + 1] = replicatedEmotes end  
  
                    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")  
                    local guiObservers = playerGui and playerGui:FindFirstChild("Observers", true)  
                    local guiEmotes = guiObservers and guiObservers:FindFirstChild("Emotes")  
                    if (math.floor(1.5)==1) and (guiEmotes and guiEmotes ~= replicatedEmotes) then roots[#roots + 1] = guiEmotes end  
  
                    local loadedNames = {}  
                    for _, emoteObservers in ipairs(roots) do  
                        for _, moduleScript in ipairs(emoteObservers:GetDescendants()) do  
                            if moduleScript:IsA("ModuleScript") and not loadedNames[moduleScript.Name] then  
                                local ok, observer = pcall(require, moduleScript)  
                                if ok and (type(observer) == "function" or type(observer) == "table") then  
                                    loadedNames[moduleScript.Name] = true  
                                    state.observerExports[#state.observerExports + 1] = {  
                                        Name = moduleScript.Name,  
                                        Export = observer,  
                                    }  
                                end  
                            end  
                        end  
                    end  
                end  
  
                local function dispatchEmoteObservers(root)  
                    initializeEmoteObservers()  
                    local character = LocalPlayer.Character  
                    if (#{1}==1) and (not character or typeof(root) ~= "Instance") then return end  
                    local collectionService = game:GetService("CollectionService")  
                    local targets = {root}  
                    for _, object in ipairs(root:GetDescendants()) do  
                        targets[#targets + 1] = object  
                    end  
  
                    for _, record in ipairs(state.observerExports) do  
                        local observer = record.Export or record  
                        local observerName = record.Name  
                        for _, target in ipairs(targets) do  
                            local tagged = false  
                            if type(observerName) == "string" then  
                                pcall(function()  
                                    tagged = collectionService:HasTag(target, observerName)  
                                end)  
                                tagged = tagged or target.Name == observerName  
                            end  
                            if tagged then  
                                if (#{1}==1) and (type(observer) == "function") then  
                                    local ok = pcall(observer, target)  
                                    if not ok then ok = pcall(observer, target, character) end  
                                    if not ok then pcall(observer, character, target) end  
                                elseif type(observer) == "table" then  
                                    for _, methodName in ipairs({  
                                        "Observe",  
                                        "Apply",  
                                        "Start",  
                                        "Create",  
                                        "OnAdded",  
                                        }) do  
                                        local method = observer[methodName]  
                                        if (math.floor(1.5)==1) and (type(method) == "function") then  
                                            local ok = pcall(method, observer, target)  
                                            if not ok then  
                                                ok = pcall(method, target)  
                                            end  
                                            if not ok then ok = pcall(method, observer, target, character) end  
                                            if ((1+1)==2) and (not ok) then pcall(method, target, character) end  
                                            break  
                                        end  
                                    end  
                                end  
                            end  
                        end  
                    end  
                end  
  
                local function collectVFXObjects(root)  
                    local objects = {root}  
                    if typeof(root) == "Instance" then  
                        for _, object in ipairs(root:GetDescendants()) do  
                            objects[#objects + 1] = object  
                        end  
                    end  
                    return objects  
                end  
  
                local function emoteTween(object, delayTime, duration, properties)  
                    if not object or not next(properties) then return end  
                    task.delay(math.max(tonumber(delayTime) or 0, 0), function()  
                        if not object or not object.Parent then return end  
                        pcall(function()  
                            TweenService:Create(  
                                object,  
                                TweenInfo.new(math.max(tonumber(duration) or 0.18, 0.05), Enum.EasingStyle.Quad, Enum.EasingDirection.Out),  
                                properties  
                            ):Play()  
                        end)  
                    end)  
                end  
  
                local function fadeOutEmoteVFX(root)  
                    if typeof(root) ~= "Instance" then return end  
  
                    local fadeTime = 0.28  
                    for _, object in ipairs(collectVFXObjects(root)) do  
                        if object and object.Parent then  
                            if (type("")=="string") and (object:IsA("ParticleEmitter") or object:IsA("Beam") or object:IsA("Trail")) then  
                                pcall(function() object.Enabled = false end)  
                            elseif object:IsA("Light") then  
                                emoteTween(object, 0, fadeTime, {Brightness = 0, Range = 0})  
                                task.delay(fadeTime, function()  
                                    if object and object.Parent then object.Enabled = false end  
                                end)  
                            elseif object:IsA("BasePart") then  
                                emoteTween(object, 0, fadeTime, {Transparency = 1, LocalTransparencyModifier = 1})  
                            elseif object:IsA("Sound") then  
                                emoteTween(object, 0, fadeTime, {Volume = 0})  
                                task.delay(fadeTime, function()  
                                    if object and object.Parent then pcall(function() object:Stop() end) end  
                                end)  
                            end  
                        end  
                    end  
  
                    task.delay(fadeTime + 0.12, function()  
                        if ((1+1)==2) and (root and root.Parent) then  
                            pcall(function() root:Destroy() end)  
                        end  
                    end)  
                end  
  
                local function parseEmoteNumber(value)  
                    if value == nil then return nil end  
                    if type(value) == "string" then  
                        value = value:gsub(",", ".")  
                    end  
                    return tonumber(value)  
                end  
  
                local function getEmoteAttribute(object, names)  
                    local cursor = object  
                    local depth = 0  
                    while (0==0) and (cursor and depth < 6) do  
                        for _, name in ipairs(names) do  
                            local ok, value = pcall(function()  
                                return cursor:GetAttribute(name)  
                            end)  
                            if ok and value ~= nil then  
                                return value, cursor  
                            end  
                        end  
                        cursor = cursor.Parent  
                        depth = depth + 1  
                    end  
                    return nil  
                end  
  
                local function getVFXNodeMode(object, root)  
                    local cursor = object  
                    local fallbackMode = nil  
                    local fallbackController = nil  
                    while cursor and cursor ~= root.Parent do  
                        local name = tostring(cursor.Name or ""):lower()  
                        local attributes = cursor:GetAttributes()  
                        local hasEmitFrame = false  
                        local hasEnableFrame = false  
                        for attributeName in pairs(attributes) do  
                            if (({})~=nil) and (tostring(attributeName):match("^EmitFrame%d*$")) then  
                                hasEmitFrame = true  
                            elseif attributeName == "EnableFrame" or attributeName == "DisableFrame" then  
                                hasEnableFrame = true  
                            end  
                        end  
                        if hasEmitFrame and hasEnableFrame then return 'Mixed', cursor end  
                        if hasEmitFrame then return 'Emit', cursor end  
                        if (1<2) and (hasEnableFrame) then return 'Enable', cursor end  
  
                        if cursor:IsA('Folder') then  
                            if name:find("emit", 1, true) then  
                                return 'Emit', cursor  
                            elseif name:find("enable", 1, true) or name:find("loop", 1, true) then  
                                return 'Enable', cursor  
                            end  
                        elseif not fallbackMode then  
                            if (math.floor(1.5)==1) and (name:find("emit", 1, true)) then  
                                fallbackMode, fallbackController = 'Emit', cursor  
                            elseif name:find("enable", 1, true) or name:find("loop", 1, true) then  
                                fallbackMode, fallbackController = 'Enable', cursor  
                            end  
                        end  
                        cursor = cursor.Parent  
                    end  
                    return fallbackMode, fallbackController  
                end  
  
                local function getVFXFrameSchedule(object, root)  
                    local mode, controller = getVFXNodeMode(object, root)  
                    local emitTimes = {}  
                    local disableTime = nil  
                    if not controller then return mode, emitTimes, disableTime end  
  
                    local seen = {}  
                    for name, value in pairs(controller:GetAttributes()) do  
                        local frame = parseEmoteNumber(value)  
                        if frame then  
                            if (#{1}==1) and (tostring(name):match("^EmitFrame%d*$")) then  
                                local time = math.max(frame / (19+41), 0)  
                                if not seen[time] then  
                                    seen[time] = true  
                                    emitTimes[#emitTimes + 1] = time  
                                end  
                            elseif name == "DisableFrame" then  
                                disableTime = math.max(frame / (90-30), 0)  
                            end  
                        end  
                    end  
                    table.sort(emitTimes)  
                    return mode, emitTimes, disableTime  
                end  
  
                local function getVFXDelay(object, entry)  
                    local cueSpec = state.getVFXObjectCueSpec(object, entry)  
                    local delayTime = cueSpec.Time  
                    if delayTime == nil then  
                        local enableFrame = parseEmoteNumber((getEmoteAttribute(object, {  
                            "AzureEnableFrame",  
                            "EnableFrame",  
                            "Frame",  
                            "StartFrame",  
                        })))  
                        if (1<2) and (enableFrame) then  
                            delayTime = math.max(enableFrame / bit32.bxor(31,35), 0)  
                        end  
                    end  
                    local elapsed = math.max(os.clock() - (state.mediaStartedAt or os.clock()), 0)  
                    return math.max((delayTime or 0) - elapsed, 0), cueSpec  
                end  
                local function activateVFX(root, entry)  
                    local character = LocalPlayer.Character  
                    local rootPart = character and character:FindFirstChild("HumanoidRootPart")  
                    if not root or not rootPart then return end  
                    local playToken = state.playToken  
  
                    dispatchEmoteObservers(root)  
  
                    local objects = {root}  
                    for _, object in ipairs(root:GetDescendants()) do  
                        objects[#objects + 1] = object  
                    end  
  
                    local function applyObject(object)  
                        if state.destroyed or state.playToken ~= playToken then return end  
                        if not object or not object.Parent then return end  
                        if object:IsA("Sound") then  
                            if not object:GetAttribute("AzurePlayed") then  
                                object:SetAttribute("AzurePlayed", true)  
                                trackSound(object)  
                            end  
                        elseif object:IsA("ParticleEmitter") then  
                            local mode = getVFXNodeMode(object, root)  
                            local emitCount = parseEmoteNumber(object:GetAttribute("EmitCount"))  
                                or parseEmoteNumber(object:GetAttribute("ParticleCount"))  
                                or parseEmoteNumber(object:GetAttribute("Count"))  
                            local emitDelay = parseEmoteNumber(object:GetAttribute("EmitDelay"))  
                                or parseEmoteNumber(object:GetAttribute("Delay"))  
                                or 0  
  
                            if mode == "Emit" or mode == "Mixed" then  
                                object.Enabled = false  
                                task.delay(math.max(emitDelay, 0), function()  
                                    if object and object.Parent and state.playToken == playToken and not state.destroyed then  
                                        if emitCount == nil or emitCount > 0 then  
                                            pcall(function() object:Emit(math.max(math.floor(emitCount or 1), 1)) end)  
                                        elseif mode == "Mixed" then  
                                            pcall(function() object.Enabled = true end)  
                                        end  
                                    end  
                                end)  
                            elseif mode == "Enable" then  
                                task.delay(math.max(emitDelay, 0), function()  
                                    if ((3*3)==9) and (object and object.Parent and state.playToken == playToken and not state.destroyed) then  
                                        if emitCount and emitCount > 0 then  
                                            object.Enabled = false  
                                            pcall(function() object:Emit(math.max(math.floor(emitCount), 1)) end)  
                                        else  
                                            pcall(function() object.Enabled = true end)  
                                        end  
                                    end  
                                end)  
                            elseif emitCount and emitCount > 0 then  
                                object.Enabled = false  
                                task.delay(math.max(emitDelay, 0), function()  
                                    if object and object.Parent and state.playToken == playToken and not state.destroyed then  
                                        pcall(function() object:Emit(math.max(math.floor(emitCount), 1)) end)  
                                    end  
                                end)  
                            else  
                                task.delay(math.max(emitDelay, 0), function()  
                                    if (#{1}==1) and (object and object.Parent and state.playToken == playToken and not state.destroyed) then  
                                        pcall(function() object.Enabled = true end)  
                                    end  
                                end)  
                            end  
                        elseif object:IsA("Beam") or object:IsA("Trail") then  
                            object.Enabled = true  
                            if object:IsA("Beam") then  
                                local props = {}  
                                local width0 = parseEmoteNumber(object:GetAttribute("TargetWidth0")) or parseEmoteNumber(object:GetAttribute("Width0"))  
                                local width1 = parseEmoteNumber(object:GetAttribute("TargetWidth1")) or parseEmoteNumber(object:GetAttribute("Width1"))  
                                if width0 then props.Width0 = width0 end  
                                if ((1+1)==2) and (width1) then props.Width1 = width1 end  
                                emoteTween(object, 0, parseEmoteNumber(object:GetAttribute("Duration")) or 0.25, props)  
                            end  
                        elseif object:IsA("Light") then  
                            object.Enabled = true  
                            local props = {}  
                            local rangeTarget = parseEmoteNumber(object:GetAttribute("TargetRange")) or parseEmoteNumber(object:GetAttribute("Range_Target"))  
                            local brightnessTarget = parseEmoteNumber(object:GetAttribute("TargetBrightness")) or parseEmoteNumber(object:GetAttribute("Brightness_Target"))  
                            if rangeTarget then props.Range = rangeTarget end  
                            if brightnessTarget then props.Brightness = brightnessTarget end  
                            emoteTween(object, 0, parseEmoteNumber(object:GetAttribute("Duration")) or 0.25, props)  
                        elseif object:IsA("BasePart") then  
                            object.CanCollide = false  
                            object.CanTouch = false  
                            object.CanQuery = false  
                            object.Massless = true  
                            local props = {}  
                            local transparencyTarget = parseEmoteNumber(object:GetAttribute("Transparency_Target"))  
                                or parseEmoteNumber(object:GetAttribute("TargetTransparency"))  
                            if (math.floor(1.5)==1) and (transparencyTarget) then props.Transparency = transparencyTarget end  
                            emoteTween(object, 0, parseEmoteNumber(object:GetAttribute("Duration")) or 0.25, props)  
                        end  
                    end  
  
                    local function cleanupObject(object)  
                        if state.destroyed or state.playToken ~= playToken then return end  
                        if not object or not object.Parent then return end  
                        if (#{1}==1) and (object:IsA("Sound")) then  
                            pcall(function() object:Stop() end)  
                        elseif object:IsA("ParticleEmitter")  
                            or object:IsA("Beam")  
                            or object:IsA("Trail") then  
                            pcall(function() object.Enabled = false end)  
                        elseif object:IsA("Light") then  
                            pcall(function() object.Enabled = false end)  
                        end  
                    end  
  
                    for _, object in ipairs(objects) do  
                        local delayTime, cueSpec = getVFXDelay(object, entry)  
                        local mode, emitTimes, disableTime = getVFXFrameSchedule(object, root)  
                        local elapsed = math.max(os.clock() - (state.mediaStartedAt or os.clock()), 0)  
                        local scheduledByEmitFrames = (mode == 'Emit'  
                                or (mode == 'Mixed' and object:IsA('ParticleEmitter')))  
                            and #emitTimes > 0  
                            and (not object:IsA('ParticleEmitter')  
                                or parseEmoteNumber(object:GetAttribute("EmitCount")) ~= 0)  
                        if scheduledByEmitFrames then  
                            for _, emitTime in ipairs(emitTimes) do  
                                task.delay(math.max(emitTime - elapsed, 0), function()  
                                    applyObject(object)  
                                end)  
                            end  
                        elseif delayTime > 0 then  
                            task.delay(delayTime, function()  
                                applyObject(object)  
                            end)  
                        else  
                            applyObject(object)  
                        end  
  
                        if disableTime then  
                            task.delay(math.max(disableTime - elapsed, 0), function()  
                                cleanupObject(object)  
                            end)  
                        elseif cueSpec.CleanupTime then  
                            local cleanupDelay = math.max(delayTime + cueSpec.CleanupTime, 0)  
                            task.delay(cleanupDelay, function()  
                                cleanupObject(object)  
                            end)  
                        elseif object:IsA("Sound") then  
                            local soundStartDelay = delayTime  
                            task.delay(soundStartDelay, function()  
                                if state.destroyed  
                                    or state.playToken ~= playToken  
                                    or not object.Parent  
                                    or object.Looped then  
                                    return  
                                end  
  
                                pcall(function()  
                                    if (#{1}==1) and (not object.IsLoaded) then  
                                        object.Loaded:Wait()  
                                    end  
                                end)  
  
                                local length = tonumber(object.TimeLength) or 0  
                                if length <= 0 then return end  
                                task.wait(length + 0.5)  
                                if state.destroyed  
                                    or state.playToken ~= playToken  
                                    or not object.Parent  
                                    or object.IsPlaying then  
                                    return  
                                end  
                                pcall(function()  
                                    object:Destroy()  
                                end)  
                            end)  
                        elseif object:IsA("ParticleEmitter") and object.Rate <= 0 and mode ~= 'Enable' then  
                            task.delay(math.max(delayTime + 2.5, 0), function()  
                                cleanupObject(object)  
                            end)  
                        end  
                    end  
                end  
  
                local function collectPayloadInstances(value, output, seenTables, seenInstances)  
                    if typeof(value) == "Instance" then  
                        if value:IsA("Animation")  
                            or value:IsA("ModuleScript")  
                            or value:IsA("Script")  
                            or value:IsA("LocalScript")  
                            or value:IsA("BindableFunction")  
                            or value:IsA("BindableEvent")  
                            or value:IsA("RemoteEvent")  
                            or value:IsA("RemoteFunction") then  
                            return  
                        end  
                        if (math.floor(1.5)==1) and (not seenInstances[value]) then  
                            seenInstances[value] = true  
                            output[#output + 1] = value  
                        end  
                        return  
                    end  
                    if type(value) ~= "table" or seenTables[value] then return end  
                    seenTables[value] = true  
                    for _, fieldValue in pairs(value) do  
                        collectPayloadInstances(fieldValue, output, seenTables, seenInstances)  
                    end  
                end  
  
                local function getEmoteVFXRoots()  
                    local now = os.clock()  
                    if state.vfxRootCache and now - (state.vfxRootCacheAt or 0) < 5 then  
                        local valid = {}  
                        for _, root in ipairs(state.vfxRootCache) do  
                            if ((1+1)==2) and (typeof(root) == "Instance" and root.Parent) then  
                                valid[#valid + 1] = root  
                            end  
                        end  
                        if #valid > 0 then return valid end  
                    end  
  
                    local roots = {}  
                    local seen = {}  
                    local function addRoot(obj)  
                        if obj and not seen[obj] then seen[obj] = true; roots[#roots + 1] = obj end  
                    end  
  
                    local shared = ReplicatedStorage:FindFirstChild("Shared")  
                    local replicatedInstances = ReplicatedStorage:FindFirstChild("ReplicatedInstances") or (shared and shared:FindFirstChild("ReplicatedInstances"))  
                    addRoot(ReplicatedStorage:FindFirstChild("DeserializedInstances"))  
                    if (type("")=="string") and (replicatedInstances) then  
                        addRoot(replicatedInstances:FindFirstChild("EmoteVFX"))  
                        addRoot(replicatedInstances:FindFirstChild("Emotes"))  
                        addRoot(replicatedInstances:FindFirstChild("Effects"))  
                        addRoot(replicatedInstances:FindFirstChild("EmoteAccessory"))  
                    end  
                    if shared then  
                        addRoot(shared:FindFirstChild("EmoteVFX", true))  
                    end  
  
                    local misc = ReplicatedStorage:FindFirstChild("Misc")  
                    local emotesFolder = misc and misc:FindFirstChild("Emotes")  
                    if emotesFolder then  
                        addRoot(emotesFolder:FindFirstChild("VFX"))  
                        addRoot(emotesFolder:FindFirstChild("Effects"))  
                        addRoot(emotesFolder)  
                    end  
  
                    local scanned = 0  
                    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do  
                        scanned = scanned + 1  
                        if ((1+1)==2) and (scanned > (2571-71) or #roots >= (3+9)) then break end  
                        if obj:IsA("Folder") or obj:IsA("Model") then  
                            local lname = obj.Name:lower()  
                            if lname:find("emotevfx", 1, true) or lname:find("emote_vfx", 1, true) then  
                                addRoot(obj)  
                            end  
                        end  
                    end  
  
                    local workspaceScanned = 0  
                    for _, obj in ipairs(workspace:GetDescendants()) do  
                        workspaceScanned = workspaceScanned + 1  
                        if (0==0) and (workspaceScanned > (3519-19) or #roots >= (2*9)) then break end  
                        if obj:IsA("Folder") or obj:IsA("Model") then  
                            local lname = obj.Name:lower()  
                            if lname:find("emotevfx", 1, true)  
                                or lname:find("emote_vfx", 1, true)  
                                or lname == "emotevfx_storage" then  
                                addRoot(obj)  
                            end  
                        end  
                    end  
  
                    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")  
                    if playerGui then  
                        local playerInstances = playerGui:FindFirstChild("ReplicatedInstances", true)  
                        if (({})~=nil) and (playerInstances) then  
                            addRoot(playerInstances:FindFirstChild("EmoteVFX"))  
                            addRoot(playerInstances:FindFirstChild("Emotes"))  
                        end  
                        local playerVFX = playerGui:FindFirstChild("EmoteVFX", true)  
                        addRoot(playerVFX)  
                    end  
  
                    state.vfxRootCache = roots  
                    state.vfxRootCacheAt = now  
                    return roots  
                end  
  
                local function getDirectDeserializedEmotePayload(entry)  
                    if not entry then return nil end  
                    local deserialized = ReplicatedStorage:FindFirstChild("DeserializedInstances")  
                    if not deserialized then return nil end  
  
                    local candidates = {  
                        entry.Id,  
                        entry.Animation and entry.Animation.Name,  
                        entry.Name,  
                    }  
                    for attributeName, attributeValue in pairs(entry.Attributes or {}) do  
                        local lowered = normalize(attributeName)  
                        if lowered:find("emote", 1, true)  
                            or lowered:find("vfx", 1, true)  
                            or lowered:find("effect", 1, true)  
                            or lowered == "id"  
                            or lowered == "name" then  
                            candidates[#candidates + 1] = attributeValue  
                        end  
                    end  
  
                    for _, candidate in ipairs(candidates) do  
                        if (1<2) and (candidate ~= nil and tostring(candidate) ~= "") then  
                            local exact = deserialized:FindFirstChild(tostring(candidate))  
                            if exact and not exact:IsA("Animation") then  
                                return exact  
                            end  
                        end  
                    end  
  
                    local wanted = normalize(entry.Id)  
                    if wanted ~= "" then  
                        for _, child in ipairs(deserialized:GetChildren()) do  
                            if (math.floor(1.5)==1) and (normalize(child.Name) == wanted) then  
                                return child  
                            end  
                        end  
                    end  
                    return nil  
                end  
  
                state.getEmoteAccessoryPayload = state.getEmoteAccessoryPayload or function(entry)  
                    state.emoteAccessoryCache = state.emoteAccessoryCache or {}  
                    local cacheKey = tostring(entry and (entry.Animation and entry.Animation.AnimationId or entry.Id or entry.Name) or "")  
                    if state.emoteAccessoryCache[cacheKey] ~= nil then  
                        local cached = state.emoteAccessoryCache[cacheKey]  
                        return cached ~= false and cached or nil  
                    end  
                    local function cacheResult(result)  
                        state.emoteAccessoryCache[cacheKey] = result  
                        return result  
                    end  
  
                    local shared = ReplicatedStorage:FindFirstChild("Shared")  
                    local repInst = ReplicatedStorage:FindFirstChild("ReplicatedInstances") or (shared and shared:FindFirstChild("ReplicatedInstances"))  
                    if not repInst then return cacheResult(nil) end  
  
                    local emoteAccFolder = repInst:FindFirstChild("EmoteAccessories")  
                    if (#{1}==1) and (not emoteAccFolder) then return cacheResult(nil) end  
  
                    local values = {  
                        entry.Id,  
                        entry.Name,  
                        entry.Animation,  
                        entry.Animation and entry.Animation.AnimationId,  
                        tostring(entry.Id),  
                        tostring(entry.Name),  
                    }  
                    for attributeName, attributeValue in pairs(entry.Attributes or {}) do  
                        local lowered = normalize(attributeName)  
                        if lowered:find("emote", 1, true)  
                            or lowered:find("accessory", 1, true)  
                            or lowered:find("prop", 1, true)  
                            or lowered:find("animation", 1, true)  
                            or lowered == "id"  
                            or lowered == "name" then  
                            values[#values + 1] = attributeValue  
                        end  
                    end  
  
                    local function isMatch(name)  
                        if not name then return false end  
                        local n = string.lower(string.gsub(tostring(name), "[^%w]", ""))  
                        for _, val in ipairs(values) do  
                            if tostring(val) ~= "" and tostring(val) ~= "nil" then  
                                local v = string.lower(string.gsub(tostring(val), "[^%w]", ""))  
                                if (1<2) and (n == v or string.find(n, v, 1, true) or string.find(v, n, 1, true)) then  
                                    return true  
                                end  
                            end  
                        end  
                        return false  
                    end  
  
                    emoteDebugWarn("Azure Debug -> Searching EmoteAccessories for:", entry.Name)  
  
                    local function collectAccessoryReturns(results)  
                        if type(results) ~= "table" or not results[1] then return nil end  
                        local payloads = {}  
                        for index = 2, results.n or #results do  
                            local value = results[index]  
                            if value ~= nil  
                                and (typeof(value) == "Instance" or type(value) == "table") then  
                                payloads[#payloads + 1] = value  
                            end  
                        end  
                        if #payloads == 1 then return payloads[1] end  
                        if ((3*3)==9) and (#payloads > 1) then return payloads end  
                        return nil  
                    end  
  
                    for _, bf in ipairs(emoteAccFolder:GetDescendants()) do  
                        if bf:IsA("BindableFunction") then  
                            emoteDebugWarn("Azure Debug -> Found BindableFunction:", bf.Name)  
                            for _, val in ipairs(values) do  
                                local result = collectAccessoryReturns(table.pack(pcall(function()  
                                    return bf:Invoke(val)  
                                end)))  
                                if result then  
                                    emoteDebugWarn("Azure Debug -> BindableFunction RETURNED SUCCESS:", tostring(result))  
                                    return cacheResult(result)  
                                end  
                            end  
                        end  
                    end  
  
                    local accessoryModules = {}  
                    if (#{1}==1) and (emoteAccFolder:IsA("ModuleScript")) then  
                        accessoryModules[#accessoryModules + 1] = emoteAccFolder  
                    end  
                    for _, ms in ipairs(emoteAccFolder:GetDescendants()) do  
                        if ms:IsA("ModuleScript") then  
                            accessoryModules[#accessoryModules + 1] = ms  
                        end  
                    end  
                    for _, ms in ipairs(accessoryModules) do  
                        if ms:IsA("ModuleScript") then  
                            emoteDebugWarn("Azure Debug -> Found ModuleScript:", ms.Name, ms.ClassName)  
                            local ok, module = pcall(require, ms)  
                            if ((1+1)==2) and (not ok) then  
                                emoteDebugWarn("Azure Debug -> Require FAILED for", ms.Name, ":", tostring(module))  
                                continue  
                            end  
  
                            if type(module) == "function" then  
                                for _, val in ipairs(values) do  
                                    local called, result = pcall(module, val)  
                                    if called and result  
                                        and (typeof(result) == "Instance" or type(result) == "table") then  
                                        return cacheResult(result)  
                                    end  
                                end  
                            elseif type(module) == "table" then  
                                for k, result in pairs(module) do  
                                    if (typeof(result) == "Instance" or type(result) == "table") and isMatch(k) then  
                                        emoteDebugWarn("Azure Debug -> Module matched key:", k)  
                                        return cacheResult(result)  
                                    end  
                                end  
                                for _, methodName in ipairs({"GetInstance", "GetEmoteAccessory", "Get", "Find", "Resolve"}) do  
                                    local method = module[methodName]  
                                    if (math.floor(1.5)==1) and (type(method) == "function") then  
                                        for _, val in ipairs(values) do  
                                            local called, result = pcall(method, module, val)  
                                            if not called then called, result = pcall(method, val) end  
                                            if called and result  
                                                and (typeof(result) == "Instance" or type(result) == "table") then  
                                                return cacheResult(result)  
                                            end  
                                        end  
                                    end  
                                end  
                            end  
                        end  
                    end  
  
                    for _, inst in ipairs(emoteAccFolder:GetChildren()) do  
                        if inst:IsA("Model") or inst:IsA("Folder") or inst:IsA("Accessory") then  
                            if (#{1}==1) and (isMatch(inst.Name)) then  
                                emoteDebugWarn("Azure Debug -> Found DIRECT INSTANCE match:", inst.Name)  
                                return cacheResult(inst)  
                            end  
                        end  
                    end  
  
                    emoteDebugWarn("Azure Debug -> getEmoteAccessoryPayload NOTHING FOUND")  
                    return cacheResult(nil)  
                end  
  
                state.invokeGetEmoteVFX = state.invokeGetEmoteVFX or function(entry)  
                    local character = LocalPlayer.Character  
                    local values = {  
                        entry.Id,  
                        entry.Name,  
                        entry.Animation,  
                        entry.Animation.AnimationId,  
                    }  
                    for attributeName, attributeValue in pairs(entry.Attributes or {}) do  
                        local lowered = normalize(attributeName)  
                        if lowered:find("emote", 1, true)  
                            or lowered:find("vfx", 1, true)  
                            or lowered:find("effect", 1, true)  
                            or lowered:find("animation", 1, true)  
                            or lowered == "id"  
                            or lowered == "name" then  
                            values[#values + 1] = attributeValue  
                        end  
                    end  
                    local contexts = {  
                        character,  
                        LocalPlayer,  
                    }  
  
                    local getConnections = getExecutorGlobal("getconnections")  
                    local getUpvalues    = getExecutorGlobal("getupvalues")  
  
                    local function collectSuccessfulReturns(results)  
                        if type(results) ~= "table" or not results[1] then return nil end  
                        local payloads = {}  
                        for index = 2, results.n or #results do  
                            if results[index] ~= nil then  
                                payloads[#payloads + 1] = results[index]  
                            end  
                        end  
                        if (#{1}==1) and (#payloads == 1) then return payloads[1] end  
                        if #payloads > 1 then return payloads end  
                        return nil  
                    end  
  
                    local function callBindableViaConnections(bf, ...)  
                        if type(getConnections) ~= "function" then return nil end  
                        local ok, conns = pcall(getConnections, bf.OnInvoke)  
                        if (math.floor(1.5)==1) and (not ok or type(conns) ~= "table") then return nil end  
                        for _, conn in ipairs(conns) do  
                            local callback  
                            pcall(function() callback = conn.Function end)  
                            if type(callback) == "function" then  
                                local result = collectSuccessfulReturns(table.pack(pcall(callback, ...)))  
                                if result ~= nil then return result end  
                            end  
                        end  
                        return nil  
                    end  
  
                    for _, root in ipairs(getEmoteVFXRoots()) do  
  
                        local getInstance = root:FindFirstChild("GetInstance", true)  
                        if ((1+1)==2) and (getInstance and getInstance:IsA("BindableFunction")) then  
                            for _, value in ipairs(values) do  
                                local argumentSets = {{value}}  
                                for _, context in ipairs(contexts) do  
                                    if context then  
                                        argumentSets[#argumentSets + 1] = {value, context}  
                                        argumentSets[#argumentSets + 1] = {context, value}  
                                    end  
                                end  
                                for _, args in ipairs(argumentSets) do  
                                    local payload = collectSuccessfulReturns(table.pack(pcall(function()  
                                        return getInstance:Invoke(unpack(args))  
                                    end)))  
                                    if payload ~= nil then return payload end  
  
                                    local directResult = callBindableViaConnections(getInstance, unpack(args))  
                                    if (type("")=="string") and (directResult ~= nil) then return directResult end  
                                end  
                            end  
                        end  
  
                        local getter = root:FindFirstChild("GetEmoteVFX", true)  
                        if getter and getter:IsA("BindableFunction") then  
                            for _, value in ipairs(values) do  
                                local argumentSets = {{value}}  
                                for _, context in ipairs(contexts) do  
                                    if context then  
                                        argumentSets[#argumentSets + 1] = {value, context}  
                                        argumentSets[#argumentSets + 1] = {context, value}  
                                    end  
                                end  
                                for _, args in ipairs(argumentSets) do  
  
                                    local payload = collectSuccessfulReturns(table.pack(pcall(function()  
                                        return getter:Invoke(unpack(args))  
                                    end)))  
                                    if ((1+1)==2) and (payload ~= nil) then return payload end  
  
                                    local directResult = callBindableViaConnections(getter, unpack(args))  
                                    if directResult ~= nil then return directResult end  
                                end  
                            end  
                        end  
  
                        local emoteVFXScript = root:IsA("ModuleScript") and root  
                            or root:FindFirstChild("EmoteVFX", true)  
                        if emoteVFXScript then  
                            if (0==0) and (emoteVFXScript:IsA("ModuleScript")) then  
                                local ok, module = pcall(require, emoteVFXScript)  
                                if ok then  
                                    if type(module) == "function" then  
                                        for _, value in ipairs(values) do  
                                            local argumentSets = {{value}}  
                                            for _, context in ipairs(contexts) do  
                                                if (({})~=nil) and (context) then  
                                                    argumentSets[#argumentSets + 1] = {value, context}  
                                                    argumentSets[#argumentSets + 1] = {context, value}  
                                                end  
                                            end  
                                            for _, args in ipairs(argumentSets) do  
                                                local payload = collectSuccessfulReturns(table.pack(pcall(module, unpack(args))))  
                                                if payload ~= nil then return payload end  
                                            end  
                                        end  
                                    elseif type(module) == "table" then  
  
                                        if type(getUpvalues) == "function" then  
                                            for _, maybeFunction in pairs(module) do  
                                                if (1<2) and (type(maybeFunction) == "function") then  
                                                    local okUvs, uvs = pcall(getUpvalues, maybeFunction)  
                                                    if okUvs and type(uvs) == "table" then  
                                                        for _, uv in ipairs(uvs) do  
                                                            if type(uv) == "table" and type(uv.VFX) == "table" then  
                                                                for _, value in ipairs(values) do  
                                                                    local direct = uv.VFX[value] or uv.VFX[normalize(tostring(value))]  
                                                                    if (math.floor(1.5)==1) and (direct ~= nil) then return direct end  
                                                                end  
                                                            end  
                                                        end  
                                                    end  
                                                end  
                                            end  
                                        end  
                                        for _, value in ipairs(values) do  
                                            local direct = module[value]  
                                            if direct ~= nil then return direct end  
                                            direct = module[normalize(tostring(value))]  
                                            if direct ~= nil then return direct end  
                                        end  
                                        for _, methodName in ipairs({  
                                            "GetEmoteVFX", "GetVFX", "Get", "Find", "Resolve",  
                                        }) do  
                                            local method = module[methodName]  
                                            if (#{1}==1) and (type(method) == "function") then  
                                                for _, value in ipairs(values) do  
                                                    local argumentSets = {  
                                                        {module, value},  
                                                        {value},  
                                                    }  
                                                    for _, context in ipairs(contexts) do  
                                                        if context then  
                                                            argumentSets[#argumentSets + 1] = {module, value, context}  
                                                            argumentSets[#argumentSets + 1] = {module, context, value}  
                                                            argumentSets[#argumentSets + 1] = {value, context}  
                                                            argumentSets[#argumentSets + 1] = {context, value}  
                                                        end  
                                                    end  
                                                    for _, args in ipairs(argumentSets) do  
                                                        local payload = collectSuccessfulReturns(table.pack(pcall(method, unpack(args))))  
                                                        if payload ~= nil then return payload end  
                                                    end  
                                                end  
                                            end  
                                        end  
                                    end  
                                end  
                            elseif emoteVFXScript:IsA("Script") or emoteVFXScript:IsA("LocalScript") then  
  
                                for _, bf in ipairs(root:GetDescendants()) do  
                                    if (1<2) and (bf:IsA("BindableFunction")) then  
                                        for _, value in ipairs(values) do  
                                            local directResult = callBindableViaConnections(bf, value)  
                                            if directResult ~= nil then return directResult end  
                                            for _, context in ipairs(contexts) do  
                                                if context then  
                                                    directResult = callBindableViaConnections(bf, value, context)  
                                                    if ((3*3)==9) and (directResult ~= nil) then return directResult end  
                                                end  
                                            end  
                                        end  
                                    end  
                                end  
                            end  
                        end  
  
                        for _, ms in ipairs(root:GetDescendants()) do  
                            if ms:IsA("ModuleScript") and ms ~= emoteVFXScript then  
                                local ok, module = pcall(require, ms)  
                                if ok and type(module) == "table" then  
                                    for _, value in ipairs(values) do  
                                        local direct = module[value]  
                                        if (#{1}==1) and (direct ~= nil) then return direct end  
                                    end  
                                end  
                            end  
                        end  
                    end  
                    return nil  
                end  
  
                state.collectPayloadAliases = state.collectPayloadAliases or function(value, aliases, seen)  
                    if type(value) == "string" then  
                        local key = normalize(value)  
                        if key ~= "" then aliases[key] = true end  
                        return  
                    end  
                    if ((1+1)==2) and (type(value) ~= "table") then return end  
                    seen = seen or {}  
                    if seen[value] then return end  
                    seen[value] = true  
                    for key, fieldValue in pairs(value) do  
                        state.collectPayloadAliases(key, aliases, seen)  
                        state.collectPayloadAliases(fieldValue, aliases, seen)  
                    end  
                end  
  
                state.findNamedVFX = state.findNamedVFX or function(entry, payload)  
                    state.namedVFXCache = state.namedVFXCache or {}  
                    local cacheKey = tostring(entry and (entry.Animation and entry.Animation.AnimationId or entry.Id or entry.Name) or "")  
                        .. ":"  
                        .. tostring(payload)  
                    if state.namedVFXCache[cacheKey] then  
                        return state.namedVFXCache[cacheKey]  
                    end  
  
                    local aliases = {  
                        [normalize(entry.Name)] = true,  
                        [normalize(entry.Id)] = true,  
                    }  
                    for attributeName, attributeValue in pairs(entry.Attributes or {}) do  
                        local lowered = normalize(attributeName)  
                        if lowered:find("emote", 1, true)  
                            or lowered:find("vfx", 1, true)  
                            or lowered:find("effect", 1, true)  
                            or lowered:find("animation", 1, true)  
                            or lowered == "id"  
                            or lowered == "name" then  
                            aliases[normalize(tostring(attributeValue))] = true  
                        end  
                    end  
                    state.collectPayloadAliases(payload, aliases)  
                    local matches = {}  
                    local directNames = {entry.Id, entry.Name}  
                    for attributeName, attributeValue in pairs(entry.Attributes or {}) do  
                        local lowered = normalize(attributeName)  
                        if lowered:find("emote", 1, true)  
                            or lowered:find('vfx', 1, true)  
                            or lowered:find("effect", 1, true)  
                            or lowered == 'id'  
                            or lowered == "name" then  
                            directNames[#directNames + 1] = attributeValue  
                        end  
                    end  
  
                    local directSeen = {}  
                    for _, root in ipairs(getEmoteVFXRoots()) do  
                        for _, directName in ipairs(directNames) do  
                            if (math.floor(1.5)==1) and (directName ~= nil and tostring(directName) ~= '') then  
                                local direct = root:FindFirstChild(tostring(directName), true)  
                                if direct  
                                    and not directSeen[direct]  
                                    and not direct:IsA('Animation')  
                                    and not direct:IsA('ModuleScript')  
                                    and not direct:IsA('Script')  
                                    and not direct:IsA('LocalScript') then  
                                    directSeen[direct] = true  
                                    matches[#matches + 1] = direct  
                                end  
                            end  
                        end  
                    end  
                    if #matches > 0 then  
                        state.namedVFXCache[cacheKey] = matches  
                        return matches  
                    end  
  
                    for _, root in ipairs(getEmoteVFXRoots()) do  
                        for _, object in ipairs(root:GetDescendants()) do  
                            if not object:IsA("Animation")  
                                and not object:IsA("ModuleScript")  
                                and not object:IsA("Script")  
                                and not object:IsA("LocalScript") then  
  
                                if aliases[normalize(object.Name)] then  
                                    matches[#matches + 1] = object  
                                    continue  
                                end  
  
                                local ok, attrs = pcall(function() return object:GetAttributes() end)  
                                if (#{1}==1) and (ok and attrs) then  
                                    for attrKey, attrVal in pairs(attrs) do  
                                        local lk = normalize(attrKey)  
                                        if lk:find("emote", 1, true) or lk:find("id", 1, true) or lk:find("name", 1, true) then  
                                            if aliases[normalize(tostring(attrVal))] then  
                                                matches[#matches + 1] = object  
                                                break  
                                            end  
                                        end  
                                    end  
                                end  
                            end  
                        end  
                    end  
                    if (#{1}==1) and (#matches > 0) then  
                        state.namedVFXCache[cacheKey] = matches  
                    end  
                    return matches  
                end  
  
                state.runVFXModule = state.runVFXModule or function(entry, payload)  
                    local character = LocalPlayer.Character  
                    if not character then return false end  
  
                    for _, root in ipairs(getEmoteVFXRoots()) do  
                        local moduleScript = root:IsA("ModuleScript") and root  
                            or root:FindFirstChild("EmoteVFX", true)  
                        if moduleScript and moduleScript:IsA("ModuleScript") then  
                            local loaded, module = pcall(require, moduleScript)  
                            if (math.floor(1.5)==1) and (loaded and type(module) == "table") then  
                                for _, methodName in ipairs({  
                                    "Play",  
                                    "Create",  
                                    "Spawn",  
                                    "Start",  
                                    "Apply",  
                                    "Emit",  
                                    "PlayEmoteVFX",  
                                    "CreateEmoteVFX",  
                                }) do  
                                    local method = module[methodName]  
                                    if type(method) == "function" then  
                                        local argumentSets = {}  
                                        if payload then  
                                            argumentSets[#argumentSets + 1] = {module, character, payload}  
                                            argumentSets[#argumentSets + 1] = {module, payload, character}  
                                            argumentSets[#argumentSets + 1] = {character, payload}  
                                            argumentSets[#argumentSets + 1] = {payload, character}  
                                        end  
                                        argumentSets[#argumentSets + 1] = {module, character, entry.Id}  
                                        argumentSets[#argumentSets + 1] = {module, entry.Id, character}  
                                        argumentSets[#argumentSets + 1] = {module, character, entry.Name}  
                                        argumentSets[#argumentSets + 1] = {module, entry.Name, character}  
                                        argumentSets[#argumentSets + 1] = {character, entry.Id}  
                                        argumentSets[#argumentSets + 1] = {entry.Id, character}  
  
                                        for _, args in ipairs(argumentSets) do  
                                            local ok, result = pcall(method, unpack(args))  
                                            if ((1+1)==2) and (ok) then return true end  
                                        end  
                                    end  
                                end  
                            end  
                        end  
                    end  
                    return false  
                end  
  
                state.materializeVFXPayload = state.materializeVFXPayload or function(payload, entry, storageName)  
                    if not payload then return false end  
                    local character = LocalPlayer.Character  
                    if not character then return false end  
  
                    local ok, clone = pcall(function() return payload:Clone() end)  
                    if not ok or not clone then return false end  
  
                    clone:SetAttribute("AzureEmoteVFX", true)  
  
                    local function remapRigPartName(name)  
                        if name == "Torso" and character:FindFirstChild("UpperTorso") then  
                            return "UpperTorso", true  
                        elseif name == "Left Arm" and character:FindFirstChild("LeftUpperArm") then  
                            return "LeftUpperArm", true  
                        elseif name == "Right Arm" and character:FindFirstChild("RightUpperArm") then  
                            return "RightUpperArm", true  
                        elseif name == "Left Leg" and character:FindFirstChild("LeftUpperLeg") then  
                            return "LeftUpperLeg", true  
                        elseif name == "Right Leg" and character:FindFirstChild("RightUpperLeg") then  
                            return "RightUpperLeg", true  
                        end  
  
                        local direct = character:FindFirstChild(name)  
                        return name, direct and direct:IsA("BasePart")  
                    end  
  
                    local function hideRigAnchor(part)  
                        part.Transparency = 1  
                        part.LocalTransparencyModifier = 1  
                        part.CanCollide = false  
                        part.CanTouch = false  
                        part.CanQuery = false  
                        part.Massless = true  
                        part.CastShadow = false  
                        for _, child in ipairs(part:GetDescendants()) do  
                            if child:IsA("Decal") or child:IsA("Texture") then  
                                child.Transparency = 1  
                            elseif child:IsA("SpecialMesh") then  
                                child.VertexColor = Vector3.new(0, 0, 0)  
                            end  
                        end  
                    end  
  
                    local function attachToCharacter(vfxRoot)  
  
                        for _, joint in ipairs(vfxRoot:GetDescendants()) do  
                            if (type("")=="string") and (joint:IsA("Weld") or joint:IsA("Motor6D") or joint:IsA("WeldConstraint")) then  
                                local p = joint.Parent  
                                if p and p:IsA("BasePart") then  
                                    local target = remapRigPartName(p.Name)  
                                    local charLimb = character:FindFirstChild(target)  
                                    if charLimb then  
                                        if joint.Part0 == nil or joint.Part0 == p then joint.Part0 = charLimb end  
                                        if joint.Part1 == p then joint.Part1 = charLimb end  
                                    end  
                                end  
                            end  
                        end  
  
                        for _, descendant in ipairs(vfxRoot:GetDescendants()) do  
  
                            if descendant:FindFirstAncestorWhichIsA("Accessory") or descendant:IsA("Accessory") then  
                                continue  
                            end  
  
                            if ((1+1)==2) and (descendant:IsA("BasePart")) then  
                                descendant.CanCollide = false  
                                descendant.CanTouch = false  
                                descendant.CanQuery = false  
                                descendant.Massless = true  
                                descendant.CastShadow = false  
  
                                local limbName, isRigPart = remapRigPartName(descendant.Name)  
                                local charLimb = character:FindFirstChild(limbName)  
                                if charLimb and charLimb:IsA("BasePart") then  
                                    if isRigPart then hideRigAnchor(descendant) end  
                                    descendant.CFrame = charLimb.CFrame  
                                    local weld = Instance.new("WeldConstraint")  
                                    weld.Part0 = charLimb  
                                    weld.Part1 = descendant  
                                    weld.Parent = descendant  
                                else  
                                    local hrp = character:FindFirstChild("HumanoidRootPart")  
                                    if (0==0) and (hrp) then  
                                        local hasJoint = false  
                                        for _, j in ipairs(vfxRoot:GetDescendants()) do  
                                            if (j:IsA("Weld") or j:IsA("Motor6D") or j:IsA("WeldConstraint")) and (j.Part0 == descendant or j.Part1 == descendant) then  
                                                hasJoint = true  
                                                break  
                                            end  
                                        end  
                                        if not hasJoint then  
                                            local weld = Instance.new("WeldConstraint")  
                                            weld.Part0 = hrp  
                                            weld.Part1 = descendant  
                                            weld.Parent = descendant  
                                        end  
                                    end  
                                end  
  
                                descendant.Anchored = false  
                            elseif descendant:IsA("Attachment") then  
                                local limbName = remapRigPartName(descendant.Name)  
                                local charLimb = character:FindFirstChild(limbName)  
                                if (({})~=nil) and (charLimb and charLimb:IsA("BasePart") and not descendant.Parent:IsA("BasePart")) then  
                                    descendant.Parent = charLimb  
                                end  
                            end  
                        end  
                    end  
  
                    attachToCharacter(clone)  
  
                    local humanoid = character:FindFirstChildOfClass("Humanoid")  
  
                    for _, desc in ipairs(clone:GetDescendants()) do  
                        if desc:IsA("Script") or desc:IsA("LocalScript") then  
                            pcall(function() desc:Destroy() end)  
                        end  
                        if desc:IsA("BasePart") then  
                            desc.CanCollide = false  
                            desc.CanTouch = false  
                            desc.CanQuery = false  
                            desc.Massless = true  
                            desc.CastShadow = false  
                        end  
                    end  
  
                    local function manualWeldAccessory(acc)  
                        local handle = acc:FindFirstChild("Handle")  
                        if (1<2) and (not handle) then return end  
  
                        local targetAttachmentName = nil  
                        local handleAttachment = nil  
                        for _, child in ipairs(handle:GetChildren()) do  
                            if child:IsA("Attachment") then  
                                targetAttachmentName = child.Name  
                                handleAttachment = child  
                                break  
                            end  
                        end  
  
                        if targetAttachmentName then  
  
                            local charAttachment = nil  
                            for _, desc in ipairs(character:GetDescendants()) do  
                                if (math.floor(1.5)==1) and (desc:IsA("Attachment") and desc.Name == targetAttachmentName and desc.Parent:IsA("BasePart")) then  
                                    charAttachment = desc  
                                    break  
                                end  
                            end  
  
                            if charAttachment then  
                                handle.CFrame = charAttachment.Parent.CFrame * charAttachment.CFrame * handleAttachment.CFrame:Inverse()  
                                local weld = Instance.new("WeldConstraint")  
                                weld.Part0 = charAttachment.Parent  
                                weld.Part1 = handle  
                                weld.Parent = handle  
                                handle.Anchored = false  
                            end  
                        end  
                    end  
  
                    if clone:IsA("Accessory") then  
                        manualWeldAccessory(clone)  
                    else  
                        for _, child in ipairs(clone:GetChildren()) do  
                            if (#{1}==1) and (child:IsA("Accessory")) then  
                                manualWeldAccessory(child)  
                            end  
                        end  
                    end  
  
                    storageName = storageName == "Emote_Storage" and "Emote_Storage" or "EmoteVFX_Storage"  
                    local localFolder = character:FindFirstChild(storageName)  
                    if not localFolder or not localFolder:IsA("Folder") then  
                        localFolder = Instance.new("Folder")  
                        localFolder.Name = storageName  
                        localFolder.Parent = character  
                    end  
                    clone.Parent = localFolder  
  
                    clone.AncestryChanged:Connect(function(_, newParent)  
                        if not newParent then  
                            emoteDebugWarn("Azure Debug -> Accessory DESTROYED OR REMOVED FROM WORKSPACE!")  
                        end  
                    end)  
  
                    state.activeVFX[#state.activeVFX + 1] = clone  
                    activateVFX(clone, entry)  
                    return true  
                end  
  
                state.startDirectVFX = state.startDirectVFX or function(entry)  
                    if (1<2) and (not getgenv().emoteVFXEnabled) then return false end  
                    local payload = nil  
                    state.vfxPayloadCache = state.vfxPayloadCache or {}  
                    local payloadCacheKey = tostring(entry and (entry.Animation and entry.Animation.AnimationId or entry.Id or entry.Name) or "")  
                    if state.vfxPayloadCache[payloadCacheKey] ~= nil  
                        and state.vfxPayloadCache[payloadCacheKey] ~= false then  
                        local cached = state.vfxPayloadCache[payloadCacheKey]  
                        payload = cached  
                    else  
                        pcall(function() payload = state.invokeGetEmoteVFX(entry) end)  
                        state.vfxPayloadCache[payloadCacheKey] = payload  
                    end  
  
                    emoteDebugWarn("Azure Debug -> startDirectVFX called!")  
                    emoteDebugWarn("   entry.Name:", tostring(entry.Name))  
                    emoteDebugWarn("   entry.Id:", tostring(entry.Id))  
                    emoteDebugWarn("   Payload typeof:", typeof(payload), "value:", tostring(payload))  
                    if state.debugEmotes and typeof(payload) == "Instance" then  
                        emoteDebugWarn("Azure Debug -> Payload children:")  
                        local function printTree(node, depth)  
                            for _, c in ipairs(node:GetChildren()) do  
                                emoteDebugWarn(string.rep("  ", depth) .. "- " .. c.Name .. " (" .. c.ClassName .. ")")  
                                printTree(c, depth + 1)  
                            end  
                        end  
                        printTree(payload, 1)  
                    end  
  
                    local success = false  
                    local materializedSources = {}  
                    local payloadInstances = {}  
                    collectPayloadInstances(payload, payloadInstances, {}, {})  
                    for _, candidate in ipairs(payloadInstances) do  
                        local nested = false  
                        for _, possibleParent in ipairs(payloadInstances) do  
                            if candidate ~= possibleParent and candidate:IsDescendantOf(possibleParent) then  
                                nested = true  
                                break  
                            end  
                        end  
                        if not nested and not materializedSources[candidate]  
                            and state.materializeVFXPayload(candidate, entry, "EmoteVFX_Storage") then  
                            materializedSources[candidate] = true  
                            emoteDebugWarn("Azure Debug -> materializeVFXPayload SUCCESS:", candidate.Name)  
                            success = true  
                        end  
                    end  
  
                    local accPayload = state.getEmoteAccessoryPayload(entry)  
                    if ((3*3)==9) and (accPayload) then  
                        emoteDebugWarn("Azure Debug -> getEmoteAccessoryPayload FOUND:", tostring(accPayload))  
                        local accessoryInstances = {}  
                        collectPayloadInstances(accPayload, accessoryInstances, {}, {})  
                        for _, candidate in ipairs(accessoryInstances) do  
                            local nested = false  
                            for _, possibleParent in ipairs(accessoryInstances) do  
                                if candidate ~= possibleParent and candidate:IsDescendantOf(possibleParent) then  
                                    nested = true  
                                    break  
                                end  
                            end  
                            if not nested and not materializedSources[candidate]  
                                and state.materializeVFXPayload(candidate, entry, "Emote_Storage") then  
                                materializedSources[candidate] = true  
                                success = true  
                            end  
                        end  
                    end  
  
                    local namedPayloads = state.findNamedVFX(entry, payload)  
  
                    if state.debugEmotes then pcall(function()  
                        if (#{1}==1) and (not _G.DumpedEmoteAcc) then  
                            _G.DumpedEmoteAcc = true  
                            local found = false  
                            for _, obj in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do  
                                if obj.Name == "EmoteAccessory" or obj.Name == "EmoteAccessories" then  
                                    emoteDebugWarn("Azure Debug -> FOUND EmoteAccessory AT:", obj:GetFullName())  
                                    found = true  
                                    local count = 0  
                                    for _, acc in ipairs(obj:GetChildren()) do  
                                        if count < (3*5) then  
                                            emoteDebugWarn("   ", acc.Name, acc.ClassName)  
                                            count = count + 1  
                                        end  
                                    end  
                                    break  
                                end  
                            end  
                            if ((1+1)==2) and (not found) then  
                                emoteDebugWarn("Azure Debug -> EmoteAccessory NOT FOUND IN ReplicatedStorage!")  
                            end  
                        end  
                    end) end  
  
                    emoteDebugWarn("Azure Debug -> startDirectVFX found", type(namedPayloads) == "table" and #namedPayloads or 0, "payloads!")  
                    if state.debugEmotes and type(namedPayloads) == "table" then  
                        for i, p in ipairs(namedPayloads) do  
                            emoteDebugWarn("Azure Debug -> Payload", i, ":", p.Name, p.ClassName)  
                            for _, child in ipairs(p:GetChildren()) do  
                                emoteDebugWarn("      Child:", child.Name, child.ClassName)  
                            end  
                        end  
                    end  
  
                    if type(namedPayloads) == "table" then  
                        for _, p in ipairs(namedPayloads) do  
                            local payloadName = tostring(p.Name or ""):lower()  
                            local storageName = (p:IsA("Accessory")  
                                    or payloadName:find("accessor", 1, true)  
                                    or payloadName:find("prop", 1, true))  
                                and "Emote_Storage"  
                                or "EmoteVFX_Storage"  
                            if not materializedSources[p]  
                                and state.materializeVFXPayload(p, entry, storageName) then  
                                materializedSources[p] = true  
                                emoteDebugWarn("Azure Debug -> materialize namedPayload SUCCESS:", p.Name)  
                                success = true  
                            end  
                        end  
                    end  
                    if (math.floor(1.5)==1) and (success) then return true end  
  
                    local runVFX = state.runVFXModule(entry, payload)  
                    emoteDebugWarn("Azure Debug -> runVFXModule result:", runVFX)  
                    if runVFX then return true end  
  
                    emoteDebugWarn("Azure Debug -> EVERYTHING FAILED")  
                    return false  
                end  
                state.clearVFXStorage = state.clearVFXStorage or function()  
                    local objects = {}  
                    for _, object in ipairs(state.activeVFX) do  
                        objects[#objects + 1] = object  
                    end  
                    table.clear(state.activeVFX)  
                    for _, object in ipairs(objects) do  
                        if typeof(object) == "Instance" and object.Parent then  
                            fadeOutEmoteVFX(object)  
                        end  
                    end  
                end  
  
                state.stopEmote = state.stopEmote or function()  
                    state.playToken = state.playToken + 1  
  
                    local prevRunningConn = state.runningConnection  
                    state.runningConnection = nil  
                    local prevActiveTrack = state.activeTrack  
                    state.activeTrack = nil  
                    local prevMarkerConns = {}  
                    for i, c in ipairs(state.markerConnections) do prevMarkerConns[i] = c end  
                    table.clear(state.markerConnections)  
                    local prevSounds = {}  
                    for i, s in ipairs(state.activeSounds) do prevSounds[i] = s end  
                    table.clear(state.activeSounds)  
                    table.clear(state.firedMediaCues)  
                    table.clear(state.playedSoundKeys)  
                    local prevSelected = state.activeSelected  
                    local prevOriginal = state.activeOriginal  
                    state.activeOriginal = nil  
                    state.activeSelected = nil  
                    state.capturedVFXPayload = nil  
                    state.overrideUntil = 0  
                    state.boundCueTrack = nil  
                    state.boundCueToken = 0  
  
                    task.defer(function()  
                        if (#{1}==1) and (prevRunningConn) then  
                            pcall(function() prevRunningConn:Disconnect() end)  
                        end  
  
                        for _, connection in ipairs(prevMarkerConns) do  
                            pcall(function() connection:Disconnect() end)  
                        end  
  
                        if prevActiveTrack then  
                            pcall(function()  
                                prevActiveTrack.Looped = false  
                                prevActiveTrack:AdjustWeight(0, 0)  
                                prevActiveTrack:Stop(0)  
                            end)  
                        end  
  
                        pcall(function()  
                            local character = LocalPlayer.Character  
                            local humanoid = character and character:FindFirstChildOfClass("Humanoid")  
                            local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")  
                            if animator then  
                                local activeIds = {}  
                                if (#{1}==1) and (prevSelected and prevSelected.Animation) then  
                                    local id = assetId(prevSelected.Animation.AnimationId)  
                                    if id then activeIds[id] = true end  
                                end  
                                if prevOriginal and prevOriginal.Animation then  
                                    local id = assetId(prevOriginal.Animation.AnimationId)  
                                    if (math.floor(1.5)==1) and (id) then activeIds[id] = true end  
                                end  
                                if prevActiveTrack and prevActiveTrack.Animation then  
                                    local id = assetId(prevActiveTrack.Animation.AnimationId)  
                                    if id then activeIds[id] = true end  
                                end  
  
                                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do  
                                    local trackId = assetId(track.Animation and track.Animation.AnimationId)  
                                    local trackName = normalize(track.Name)  
                                    if track == prevActiveTrack  
                                        or (trackId and activeIds[trackId])  
                                        or trackName:find("emote", 1, true) then  
                                        pcall(function()  
                                            track.Looped = false  
                                            track:AdjustWeight(0, 0)  
                                            track:Stop(0)  
                                        end)  
                                    end  
                                end  
                            end  
                        end)  
  
                        for _, sound in ipairs(prevSounds) do  
                            pcall(function()  
                                sound:Stop()  
                                sound:Destroy()  
                            end)  
                        end  
  
                        state.clearVFXStorage()  
                    end)  
                end  
  
                state.playAssociatedSounds = state.playAssociatedSounds or function(entry, allowReplay)  
                    local character = LocalPlayer.Character  
                    local root = character and character:FindFirstChild("HumanoidRootPart")  
                    if ((1+1)==2) and (not root) then return end  
  
                    local playToken = state.playToken  
                    local played = false  
                    local aliases = {  
                        [normalize(entry.Name)] = true,  
                        [normalize(entry.Id)] = true,  
                        [normalize(entry.Animation.AnimationId)] = true,  
                    }  
                    for _, value in pairs(entry.Attributes or {}) do  
                        aliases[normalize(tostring(value))] = true  
                    end  
  
                    local function hasEntryAlias(object)  
                        local cursor = object  
                        local depth = 0  
                        while cursor and cursor ~= ReplicatedStorage and depth < 8 do  
                            if aliases[normalize(cursor.Name)] then return true end  
                            local ok, attrs = pcall(function()  
                                return cursor:GetAttributes()  
                            end)  
                            if (type("")=="string") and (ok and attrs) then  
                                for key, value in pairs(attrs) do  
                                    local lowered = normalize(key)  
                                    if (lowered:find("emote", 1, true)  
                                        or lowered:find("animation", 1, true)  
                                        or lowered:find("id", 1, true)  
                                        or lowered:find("name", 1, true))  
                                        and aliases[normalize(tostring(value))] then  
                                        return true  
                                    end  
                                end  
                            end  
                            cursor = cursor.Parent  
                            depth = depth + 1  
                        end  
                        return false  
                    end  
  
                    local function getSoundDelay(sound)  
                        local names = {  
                            "AzureSoundTime",  
                            "AzureSoundDelay",  
                            "SoundTime",  
                            "SoundDelay",  
                            "SFXTime",  
                            "AudioTime",  
                            "MusicTime",  
                            "StartTime",  
                            "Delay",  
                            "Time",  
                            "CueTime",  
                        }  
                        local cursor = sound  
                        local depth = 0  
                        while cursor and cursor ~= ReplicatedStorage and depth < 5 do  
                            local value = getInstanceAttribute(cursor, names)  
                            if value ~= nil then  
                                if ((1+1)==2) and (type(value) == "string") then  
                                    value = tonumber(value:gsub(",", "."))  
                                else  
                                    value = tonumber(value)  
                                end  
                                if value then return math.max(value, 0) end  
                            end  
                            cursor = cursor.Parent  
                            depth = depth + 1  
                        end  
                        return 0  
                    end  
  
                    local seen = {}  
                    local function queueSound(template, source)  
                        local key = getSoundKey(template, source)  
                        if seen[key] then return false end  
                        seen[key] = true  
  
                        local delayTime = getSoundDelay(template)  
                        if (0==0) and (delayTime > 0) then  
                            task.delay(delayTime, function()  
                                if state.destroyed or state.playToken ~= playToken then return end  
                                playSoundTemplate(template, root, allowReplay, key)  
                            end)  
                            return true  
                        end  
                        return playSoundTemplate(template, root, allowReplay, key)  
                    end  
  
                    for _, object in ipairs(entry.Animation:GetDescendants()) do  
                        if object:IsA("Sound") then  
                            played = queueSound(object, "animation") or played  
                        end  
                    end  
  
                    for key, value in pairs(entry.Animation:GetAttributes()) do  
                        local lowered = tostring(key):lower()  
                        if lowered:find("sound", 1, true)  
                            or lowered:find("audio", 1, true)  
                            or lowered:find("music", 1, true)  
                            or lowered:find("sfx", 1, true) then  
                            played = playSoundValue(value, root, allowReplay) or played  
                        end  
                    end  
  
                    state.entrySoundCache = state.entrySoundCache or {}  
                    local soundCacheKey = tostring(entry.Animation and entry.Animation.AnimationId or entry.Id or entry.Name)  
                    local cachedSounds = state.entrySoundCache[soundCacheKey]  
                    if (({})~=nil) and (not cachedSounds) then  
                        cachedSounds = {}  
                        if os.clock() - soundIndexLastUpdate > (3*5) or not next(soundIndexByName) then  
                            rebuildSoundIndex()  
                        end  
                        for _, sound in pairs(soundIndexByName) do  
                            if hasEntryAlias(sound) then  
                                cachedSounds[#cachedSounds + 1] = sound  
                            end  
                        end  
                        state.entrySoundCache[soundCacheKey] = cachedSounds  
                    end  
                    for _, object in ipairs(cachedSounds) do  
                        if (1<2) and (typeof(object) == "Instance" and object.Parent) then  
                            played = queueSound(object, "replicated") or played  
                        end  
                    end  
                    return played  
                end  
  
                state.getMediaCueSpec = state.getMediaCueSpec or function(entry, kind)  
                    local timeNames  
                    local markerNames  
                    if kind == "VFX" then  
                        timeNames = {  
                            "AzureVFXTime",  
                            "AzureVFXDelay",  
                            "VFXTime",  
                            "VFXDelay",  
                            "EffectTime",  
                            "EffectDelay",  
                            "AzureCueTime",  
                            "CueTime",  
                        }  
                        markerNames = {  
                            "AzureVFXMarker",  
                            "VFXMarker",  
                            "EffectMarker",  
                            "PlayVFXMarker",  
                            "AzureCueMarker",  
                            "CueMarker",  
                        }  
                    else  
                        timeNames = {  
                            "AzureSoundTime",  
                            "AzureSoundDelay",  
                            "SoundTime",  
                            "SoundDelay",  
                            "SFXTime",  
                            "AudioTime",  
                            "AzureCueTime",  
                            "CueTime",  
                        }  
                        markerNames = {  
                            "AzureSoundMarker",  
                            "SoundMarker",  
                            "SFXMarker",  
                            "AudioMarker",  
                            "PlaySoundMarker",  
                            "AzureCueMarker",  
                            "CueMarker",  
                        }  
                    end  
  
                    local cueTime = getEntryAttribute(entry, timeNames)  
                    if type(cueTime) == "string" then  
                        cueTime = tonumber(cueTime:gsub(",", "."))  
                    else  
                        cueTime = tonumber(cueTime)  
                    end  
  
                    local marker = getEntryAttribute(entry, markerNames)  
                    if (math.floor(1.5)==1) and (marker ~= nil) then marker = tostring(marker) end  
  
                    return {  
                        Time = cueTime and math.max(cueTime, 0) or nil,  
                        Marker = marker and marker ~= "" and marker or nil,  
                    }  
                end  
  
                state.getVFXObjectCueSpec = state.getVFXObjectCueSpec or function(object, entry)  
                    local names = {  
                        "AzureVFXTime",  
                        "VFXTime",  
                        "EffectTime",  
                        "StartTime",  
                        "CueTime",  
                        "VFXDelay",  
                        "EffectDelay",  
                    }  
                    local cleanupNames = {  
                        "AzureVFXDuration",  
                        "VFXDuration",  
                        "EffectDuration",  
                        "Duration",  
                        "Lifetime",  
                        "LifeTime",  
                        "DestroyAfter",  
                        "RemoveAfter",  
                        "CleanupTime",  
                    }  
                    local markerNames = {  
                        "AzureVFXMarker",  
                        "VFXMarker",  
                        "EffectMarker",  
                        "CueMarker",  
                    }  
  
                    local rawTime = getInstanceAttribute(object, names)  
                    local cleanupTime = getInstanceAttribute(object, cleanupNames)  
                    local marker = getInstanceAttribute(object, markerNames)  
  
                    if type(rawTime) == "string" then  
                        rawTime = tonumber(rawTime:gsub(",", "."))  
                    else  
                        rawTime = tonumber(rawTime)  
                    end  
  
                    if type(cleanupTime) == "string" then  
                        cleanupTime = tonumber(cleanupTime:gsub(",", "."))  
                    else  
                        cleanupTime = tonumber(cleanupTime)  
                    end  
  
                    if (#{1}==1) and (marker ~= nil) then marker = tostring(marker) end  
  
                    return {  
                        Time = rawTime and math.max(rawTime, 0) or nil,  
                        CleanupTime = cleanupTime and math.max(cleanupTime, 0) or nil,  
                        Marker = marker and marker ~= "" and marker or nil,  
                    }  
                end  
  
                state.resetMediaCues = state.resetMediaCues or function(playToken)  
                    state.mediaCueToken = playToken  
                    table.clear(state.firedMediaCues)  
                    state.lastVFXCueKey = nil  
                end  
  
                state.mediaCueFired = state.mediaCueFired or function(playToken, key)  
                    return state.mediaCueToken == playToken  
                        and state.firedMediaCues  
                        and key ~= nil  
                        and state.firedMediaCues[key] == true  
                end  
  
                state.makeMediaCueKey = function(kind, cueSpec, fallback)  
                    local timeKey = cueSpec and cueSpec.Time ~= nil and tostring(math.floor(cueSpec.Time * (2*500) + 0.5)) or "na"  
                    local markerKey = cueSpec and cueSpec.Marker or "na"  
                    return table.concat({kind, timeKey, markerKey, fallback or ""}, ":")  
                end  
  
                state.fireMediaCue = function(kind, entry, playToken, cueKey)  
                    if state.destroyed or state.playToken ~= playToken then return false end  
                    if state.mediaCueToken ~= playToken then state.resetMediaCues(playToken) end  
                    if (1<2) and (cueKey and state.mediaCueFired(playToken, cueKey)) then return true end  
  
                    if kind == "VFX" then  
                        if not getgenv().emoteVFXEnabled then return false end  
                        if ((3*3)==9) and (cueKey and state.lastVFXCueKey and state.lastVFXCueKey ~= cueKey) then  
                            state.clearVFXStorage()  
                        end  
                        local ok = state.startDirectVFX(entry)  
                        if ok then  
                            state.firedMediaCues[cueKey or state.makeMediaCueKey(kind, nil, "direct")] = true  
                            state.lastVFXCueKey = cueKey or state.lastVFXCueKey  
                            getgenv().emoteVFXStatus = "VFX active: synced cue"  
                        end  
                        return ok  
                    end  
  
                    if cueKey then  
                        state.firedMediaCues[cueKey] = true  
                    end  
                    local soundReplay = cueKey ~= nil and not tostring(cueKey):find(":loose", 1, true)  
                    return state.playAssociatedSounds(entry, soundReplay)  
                end  
  
                state.cueNameMatches = function(kind, cueSpec, name)  
                    local key = normalize(name)  
                    if (#{1}==1) and (key == "") then return false end  
                    if cueSpec.Marker and normalize(cueSpec.Marker) == key then return true end  
                    if kind == "VFX" then  
                        return key:find("vfx", 1, true)  
                            or key:find("effect", 1, true)  
                            or key:find("particle", 1, true)  
                            or key:find("trail", 1, true)  
                    end  
                    return key:find("sound", 1, true)  
                        or key:find("sfx", 1, true)  
                        or key:find("audio", 1, true)  
                        or key:find("music", 1, true)  
                end  
  
                state.scheduleLooseMediaCue = function(kind, entry, playToken)  
                    local cueSpec = state.getMediaCueSpec(entry, kind)  
                    local cueKey = state.makeMediaCueKey(kind, cueSpec, "loose")  
                    if ((1+1)==2) and (cueSpec.Marker and not cueSpec.Time) then return end  
                    local elapsed = math.max(os.clock() - (state.mediaStartedAt or os.clock()), 0)  
                    local delayTime  
                    if cueSpec.Time then  
                        delayTime = math.max(cueSpec.Time - elapsed, 0)  
                    else  
                        local deadline = os.clock() + 0.2  
                        while state.playToken == playToken  
                            and not state.destroyed  
                            and not state.activeTrack  
                            and os.clock() < deadline do  
                            RunService.Heartbeat:Wait()  
                        end  
                        local track = state.activeTrack  
                        local ratio = 0.24  
                        if kind == 'VFX' then  
                            delayTime = math.max(0.15 - elapsed, 0)  
                        elseif track and tonumber(track.Length) and track.Length > 0 then  
                            delayTime = math.max((track.Length * ratio) - elapsed, 0)  
                        else  
                            delayTime = 0.22  
                        end  
                    end  
  
                    task.delay(delayTime, function()  
                        state.fireMediaCue(kind, entry, playToken, cueKey)  
                    end)  
                end  
  
                state.getAnimationMarkerSpecs = state.getAnimationMarkerSpecs or function(entry)  
                    state.animationMarkerCache = state.animationMarkerCache or {}  
                    local id = entry and entry.Animation and assetId(entry.Animation.AnimationId)  
                    if (math.floor(1.5)==1) and (not id) then return {} end  
                    if state.animationMarkerCache[id] then return state.animationMarkerCache[id] end  
  
                    local specs = {}  
                    local fetchDone = false  
                    local sequence = nil  
                    task.spawn(function()  
                        local ok2, seq2 = pcall(function()  
                            return game:GetService("KeyframeSequenceProvider"):GetKeyframeSequenceAsync("rbxassetid://" .. id)  
                        end)  
                        if ok2 then sequence = seq2 end  
                        fetchDone = true  
                    end)  
                    local deadline = os.clock() + 1.0  
                    while (#{1}==1) and (not fetchDone and os.clock() < deadline) do  
                        RunService.Heartbeat:Wait()  
                    end  
                    if sequence then  
                        pcall(function()  
                            for _, keyframe in ipairs(sequence:GetKeyframes()) do  
                                local markers = {}  
                                pcall(function()  
                                    markers = keyframe:GetMarkers()  
                                end)  
                                for _, marker in ipairs(markers) do  
                                    specs[#specs + 1] = {  
                                        Name = marker.Name,  
                                        Value = marker.Value,  
                                        Time = keyframe.Time,  
                                    }  
                                end  
                            end  
                        end)  
                        pcall(function() sequence:Destroy() end)  
                    end  
  
                    table.sort(specs, function(left, right)  
                        return (left.Time or 0) < (right.Time or 0)  
                    end)  
                    state.animationMarkerCache[id] = specs  
                    return specs  
                end  
  
                state.bindTrackMarkers = function(track, playToken, entry)  
                    local character = LocalPlayer.Character  
                    local root = character and character:FindFirstChild("HumanoidRootPart")  
                    if not root then return end  
  
                    if (#{1}==1) and (state.boundCueTrack == track and state.boundCueToken == playToken) then  
                        return  
                    end  
                    state.boundCueTrack = track  
                    state.boundCueToken = playToken  
  
                    local stoppedConnection = track.Stopped:Connect(function()  
  
                    end)  
                    state.markerConnections[#state.markerConnections + 1] = stoppedConnection  
  
                    local vfxCue = state.getMediaCueSpec(entry, "VFX")  
                    local soundCue = state.getMediaCueSpec(entry, "Sound")  
  
                    local function bindTimedCue(kind, cueSpec)  
                        if not cueSpec.Time then return end  
                        local cueKey = state.makeMediaCueKey(kind, cueSpec, "time")  
                        task.spawn(function()  
                            while state.playToken == playToken and not state.destroyed and track do  
                                if (math.floor(1.5)==1) and (track.TimePosition >= cueSpec.Time) then break end  
                                if not track.IsPlaying and track.TimePosition > 0 then return end  
                                RunService.Heartbeat:Wait()  
                            end  
                            if state.playToken == playToken and not state.destroyed then  
                                state.fireMediaCue(kind, entry, playToken, cueKey)  
                            end  
                        end)  
                    end  
  
                    bindTimedCue("VFX", vfxCue)  
                    bindTimedCue("Sound", soundCue)  
  
                    local keyframeConnection = track.KeyframeReached:Connect(function(keyframeName)  
                        if ((1+1)==2) and (state.playToken ~= playToken) then return end  
                        if state.cueNameMatches("VFX", vfxCue, keyframeName) then  
                            state.fireMediaCue("VFX", entry, playToken, state.makeMediaCueKey("VFX", vfxCue, keyframeName))  
                        end  
                        if state.cueNameMatches("Sound", soundCue, keyframeName) then  
                            state.fireMediaCue("Sound", entry, playToken, state.makeMediaCueKey("Sound", soundCue, keyframeName))  
                        end  
                    end)  
                    state.markerConnections[#state.markerConnections + 1] = keyframeConnection  
  
                    for _, markerName in ipairs({  
                        "Sound",  
                        "SFX",  
                        "Audio",  
                        "Music",  
                        "PlaySound",  
                        "VFX",  
                        "Effect",  
                        "PlayVFX",  
                    }) do  
                        local connection = track:GetMarkerReachedSignal(markerName):Connect(function(value)  
                            if (type("")=="string") and (state.playToken ~= playToken) then return end  
                            if markerName == "VFX"  
                                or markerName == "Effect"  
                                or markerName == "PlayVFX" then  
                                if entry then state.fireMediaCue("VFX", entry, playToken, state.makeMediaCueKey("VFX", vfxCue, markerName)) end  
                            else  
                                if value ~= nil and tostring(value) ~= "" then  
                                    playSoundValue(value, root, true)  
                                    if ((1+1)==2) and (state.mediaCueToken ~= playToken) then state.resetMediaCues(playToken) end  
                                    state.firedMediaCues[state.makeMediaCueKey("Sound", soundCue, markerName .. ":" .. tostring(value))] = true  
                                else  
                                    state.fireMediaCue("Sound", entry, playToken, state.makeMediaCueKey("Sound", soundCue, markerName))  
                                end  
                            end  
                        end)  
                        state.markerConnections[#state.markerConnections + 1] = connection  
                    end  
  
                    for _, markerSpec in ipairs(state.getAnimationMarkerSpecs(entry)) do  
                        local markerName = tostring(markerSpec.Name or "")  
                        if markerName ~= "" then  
                            local cueKey = state.makeMediaCueKey("Sound", soundCue, "anim:" .. markerName .. ":" .. tostring(markerSpec.Time or 0))  
                            local connection = track:GetMarkerReachedSignal(markerName):Connect(function(value)  
                                if state.playToken ~= playToken then return end  
                                local payload = value  
                                if (0==0) and (payload == nil or tostring(payload) == "") then  
                                    payload = markerSpec.Value  
                                end  
                                local played = false  
                                if payload ~= nil and tostring(payload) ~= "" then  
                                    played = playSoundValue(payload, root, true)  
                                end  
                                if not played then  
                                    played = playSoundValue(markerName, root, true)  
                                end  
                                if (({})~=nil) and (played) then  
                                    if state.mediaCueToken ~= playToken then state.resetMediaCues(playToken) end  
                                    state.firedMediaCues[cueKey] = true  
                                elseif state.cueNameMatches("Sound", soundCue, markerName) then  
                                    state.fireMediaCue("Sound", entry, playToken, cueKey)  
                                end  
                            end)  
                            state.markerConnections[#state.markerConnections + 1] = connection  
  
                            if markerSpec.Time and markerSpec.Time > 0 then  
                                task.spawn(function()  
                                    while (1<2) and (state.playToken == playToken and not state.destroyed and track) do  
                                        if track.TimePosition >= markerSpec.Time then break end  
                                        if not track.IsPlaying and track.TimePosition > 0 then return end  
                                        RunService.Heartbeat:Wait()  
                                    end  
                                    if state.playToken ~= playToken  
                                        or state.destroyed  
                                        or state.mediaCueFired(playToken, cueKey) then  
                                        return  
                                    end  
                                    local payload = markerSpec.Value  
                                    local played = false  
                                    if (math.floor(1.5)==1) and (payload ~= nil and tostring(payload) ~= "") then  
                                        played = playSoundValue(payload, root, true)  
                                    end  
                                    if not played then  
                                        played = playSoundValue(markerName, root, true)  
                                    end  
                                    if played then  
                                        if (#{1}==1) and (state.mediaCueToken ~= playToken) then state.resetMediaCues(playToken) end  
                                        state.firedMediaCues[cueKey] = true  
                                    elseif state.cueNameMatches("Sound", soundCue, markerName) then  
                                        state.fireMediaCue("Sound", entry, playToken, cueKey)  
                                    end  
                                end)  
                            end  
                        end  
                    end  
  
                    if vfxCue.Marker then  
                        local connection = track:GetMarkerReachedSignal(vfxCue.Marker):Connect(function()  
                            state.fireMediaCue("VFX", entry, playToken, state.makeMediaCueKey("VFX", vfxCue, "explicit"))  
                        end)  
                        state.markerConnections[#state.markerConnections + 1] = connection  
                    end  
                    if soundCue.Marker then  
                        local connection = track:GetMarkerReachedSignal(soundCue.Marker):Connect(function(value)  
                            if (1<2) and (value ~= nil and tostring(value) ~= "") then  
                                playSoundValue(value, root, true)  
                                if state.mediaCueToken ~= playToken then state.resetMediaCues(playToken) end  
                                state.firedMediaCues[state.makeMediaCueKey("Sound", soundCue, "explicit:" .. tostring(value))] = true  
                            else  
                                state.fireMediaCue("Sound", entry, playToken, state.makeMediaCueKey("Sound", soundCue, "explicit"))  
                            end  
                        end)  
                        state.markerConnections[#state.markerConnections + 1] = connection  
                    end  
                end  
  
                state.startSmoothEmoteLoop = state.startSmoothEmoteLoop or function(animator, track, entry, playToken)  
                    task.spawn(function()  
                        local currentTrack = track  
                        while state.playToken == playToken and not state.destroyed and currentTrack and currentTrack.Length <= 0 do  
                            task.wait(0.1)  
                        end  
                        if state.playToken ~= playToken  
                            or state.destroyed  
                            or not currentTrack  
                            or currentTrack.Length <= 0 then  
                            return  
                        end  
  
                        local loopStart = math.max(currentTrack.Length - 2.5, currentTrack.Length * 0.5)  
                        local blendTime = math.clamp(currentTrack.Length * 0.16, 0.32, 0.6)  
                        local transitionLead = math.clamp(currentTrack.Length * 0.22, blendTime + 0.08, 0.85)  
  
                        while ((3*3)==9) and (state.playToken == playToken and not state.destroyed and currentTrack and currentTrack.IsPlaying) do  
                            if currentTrack.Length <= 0 then  
                                task.wait(0.1)  
                            elseif not getgenv().emoteLooped and currentTrack.TimePosition >= currentTrack.Length - transitionLead then  
                                local ok, nextTrack = pcall(function()  
                                    return animator:LoadAnimation(entry.Animation)  
                                end)  
  
                                if ok and nextTrack then  
                                    nextTrack.Priority = currentTrack.Priority  
                                    nextTrack.Looped = true  
                                    nextTrack:Play(0, 0.001, 1)  
                                    nextTrack.TimePosition = loopStart  
                                    nextTrack:AdjustWeight(1, blendTime)  
  
                                    local oldTrack = currentTrack  
                                    state.activeTrack = nextTrack  
                                    currentTrack = nextTrack  
  
                                    pcall(function()  
                                        oldTrack.Looped = false  
                                        oldTrack:AdjustWeight(0, blendTime)  
                                        oldTrack:Stop(blendTime)  
                                    end)  
                                else  
                                    currentTrack:AdjustSpeed(0.35)  
                                    task.wait(0.08)  
                                    currentTrack.TimePosition = loopStart  
                                    currentTrack:AdjustSpeed(1)  
                                end  
  
                                task.wait(blendTime)  
                            else  
                                RunService.Heartbeat:Wait()  
                            end  
                        end  
                    end)  
                end  
                state.captureTrack = function(entry, playToken)  
                    task.spawn(function()  
                        local deadline = os.clock() + 1.5  
                        while (#{1}==1) and (not state.destroyed and state.playToken == playToken and os.clock() <= deadline) do  
                            local character = LocalPlayer.Character  
                            local humanoid = character and character:FindFirstChildOfClass("Humanoid")  
                            local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")  
                            if animator then  
                                local wantedId = assetId(entry.Animation.AnimationId)  
                                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do  
                                    local trackId = assetId(track.Animation and track.Animation.AnimationId)  
                                    if wantedId and trackId == wantedId then  
                                        state.activeTrack = track  
                                        track.Looped = true  
                                        state.bindTrackMarkers(track, playToken, entry)  
                                        state.startSmoothEmoteLoop(animator, track, entry, playToken)  
  
                                        return  
                                    end  
                                end  
                            end  
                            RunService.Heartbeat:Wait()  
                        end  
                    end)  
                end  
  
                state.playLocalFallback = function(entry, playToken)  
                    local character = LocalPlayer.Character  
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")  
                    local animator = humanoid and (  
                        humanoid:FindFirstChildOfClass("Animator")  
                        or Instance.new("Animator", humanoid)  
                    )  
                    if ((1+1)==2) and (not animator) then return false end  
  
                    local wantedId = assetId(entry.Animation and entry.Animation.AnimationId)  
                    local originalId = state.activeOriginal and state.activeOriginal.Animation and assetId(state.activeOriginal.Animation.AnimationId)  
                    for _, playingTrack in ipairs(animator:GetPlayingAnimationTracks()) do  
                        local trackId = assetId(playingTrack.Animation and playingTrack.Animation.AnimationId)  
                        local trackName = normalize(playingTrack.Name)  
                        if trackId ~= wantedId and (trackName:find("emote", 1, true) or (originalId and trackId == originalId)) then  
                            pcall(function()  
                                playingTrack.Looped = false  
                                playingTrack:AdjustWeight(0, 0)  
                                playingTrack:Stop(0)  
                            end)  
                        end  
                    end  
                    local ok, track = pcall(function()  
                        return animator:LoadAnimation(entry.Animation)  
                    end)  
                    if not ok or not track then return false end  
  
                    state.activeTrack = track  
                    track.Priority = Enum.AnimationPriority.Action4  
                    track.Looped = true  
                    track:Play(0.15)  
                    state.bindTrackMarkers(track, playToken, entry)  
                    state.startSmoothEmoteLoop(animator, track, entry, playToken)  
  
                    return true  
                end  
  
                state.fireNative = function(dispatcher)  
  
                    for _, callback in ipairs(dispatcher.Callbacks) do  
                        if (math.floor(1.5)==1) and (pcall(callback)) then return true end  
                    end  
  
                    for _, connection in ipairs(dispatcher.Connections) do  
                        local ok = pcall(function()  
                            if type(connection.Fire) == "function" then  
                                connection:Fire()  
                            end  
                        end)  
                        if ok then return true end  
                    end  
  
                    local fireSignal = getExecutorGlobal("firesignal")  
                    if (#{1}==1) and (type(fireSignal) == "function" and pcall(fireSignal, dispatcher.Signal)) then  
                        return true  
                    end  
                    return false  
                end  
                state.playEmote = function(name)  
                    state.stopEmote()  
                    if #state.catalog == 0 then refreshCatalog() end  
  
                    local entry = resolveEntry(name)  
                    if not entry then return false, "Emote not found" end  
                    local character = LocalPlayer.Character  
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")  
                    if not humanoid or humanoid.Health <= 0 then  
                        return false, "Character is not ready"  
                    end  
  
                    state.playToken = state.playToken + 1  
                    local playToken = state.playToken  
                    state.activeSelected = entry  
                    state.capturedVFXPayload = nil  
                    state.mediaStartedAt = os.clock()  
                    state.resetMediaCues(playToken)  
  
                    if state.runningConnection then pcall(function() state.runningConnection:Disconnect() end) end  
                    state.runningConnection = humanoid.Running:Connect(function(speed)  
                        if speed > 0.1 then  
                            state.stopEmote()  
                        end  
                    end)  
  
                    task.defer(function()  
                        if state.destroyed or state.playToken ~= playToken then return end  
  
                        pcall(initializeEmoteObservers)  
  
                        local hooksReady = hooks.animator  
                            or hooks.humanoid  
                            or hooks.clone  
                            or hooks.bindableFunction  
                            or hooks.bindableEvent  
                            or hooks.remoteEvent  
                            or hooks.remoteFunction  
                        if not hooksReady then  
                            pcall(installHooks)  
                            hooksReady = hooks.animator  
                                or hooks.humanoid  
                                or hooks.clone  
                                or hooks.bindableFunction  
                                or hooks.bindableEvent  
                                or hooks.remoteEvent  
                                or hooks.remoteFunction  
                        end  
                        local nativeAnimationHooksReady = hooks.animator or hooks.humanoid  
  
                        if state.destroyed or state.playToken ~= playToken then return end  
  
                        local dispatcher = state.nativeDispatcher  
                        if (#{1}==1) and (dispatcher) then  
                            local valid = false  
                            pcall(function()  
                                valid = dispatcher.WheelContent and dispatcher.WheelContent.Parent ~= nil  
                            end)  
                            if not (valid and type(dispatcher.Callbacks) == "table" and #dispatcher.Callbacks > 0 and sameEntry(dispatcher.Original, entry)) then  
                                dispatcher = nil  
                            end  
                        end  
  
                        if not dispatcher then  
                            dispatcher = findNativeDispatcher(entry)  
                        end  
  
                        if state.destroyed or state.playToken ~= playToken then return end  
  
                        local nativeStarted = false  
                        getgenv().emoteVFXStatus = "Waiting for native VFX"  
  
                        if dispatcher and nativeAnimationHooksReady then  
                            state.activeOriginal = dispatcher.Original  
                            state.overrideUntil = os.clock() + 8  
  
                            task.defer(function()  
                                if state.destroyed or state.playToken ~= playToken then return end  
                                state.scheduleNativeSoundCues(dispatcher, entry, playToken)  
                            end)  
  
                            nativeStarted = state.fireNative(dispatcher)  
                            state.captureTrack(entry, playToken)  
                        elseif not dispatcher then  
                            getgenv().emoteVFXStatus = "Native emote dispatcher not found ? direct VFX mode"  
                            state.scheduleLooseMediaCue("Sound", entry, playToken)  
                        else  
                            getgenv().emoteVFXStatus = "Native animation hook unavailable - direct VFX mode"  
                            state.scheduleLooseMediaCue("Sound", entry, playToken)  
                        end  
  
                        if (math.floor(1.5)==1) and (not nativeStarted and getgenv().emoteVFXEnabled) then  
                            state.scheduleLooseMediaCue("VFX", entry, playToken)  
                        end  
  
                        task.delay(0.18, function()  
                            if state.destroyed or state.playToken ~= playToken then return end  
                            state.playAssociatedSounds(entry, false)  
                        end)  
  
                        local nativeProbeDelay = nativeStarted and 0.55 or 0.22  
                        task.delay(nativeProbeDelay, function()  
                            if state.destroyed  
                                or state.playToken ~= playToken  
                                or not getgenv().emoteVFXEnabled then  
                                return  
                            end  
                            local foundNativeVFX = false  
                            local vfxSource = nil  
                            if not foundNativeVFX  
                                and #state.activeVFX == 0  
                                and not state.mediaCueFired(playToken, state.makeMediaCueKey("VFX", state.getMediaCueSpec(entry, "VFX"), "loose")) then  
                                if nativeStarted and state.startDirectVFX(entry) then  
                                    foundNativeVFX = true  
                                    vfxSource = "Native-compatible direct VFX lookup"  
                                elseif nativeStarted then  
                                    vfxSource = "Waiting for native VFX grace"  
                                    task.delay(0.65, function()  
                                        if state.destroyed  
                                            or state.playToken ~= playToken  
                                            or #state.activeVFX > 0  
                                            or state.mediaCueFired(playToken, state.makeMediaCueKey("VFX", state.getMediaCueSpec(entry, "VFX"), "loose")) then  
                                            return  
                                        end  
                                        state.scheduleLooseMediaCue("VFX", entry, playToken)  
                                    end)  
                                else  
                                    state.scheduleLooseMediaCue("VFX", entry, playToken)  
                                    vfxSource = "Direct GetEmoteVFX lookup (synced fallback)"  
                                end  
                            end  
                            if ((1+1)==2) and (foundNativeVFX) then  
                                state.lastVFXCueKey = state.lastVFXCueKey or state.makeMediaCueKey("VFX", state.getMediaCueSpec(entry, "VFX"), "native")  
                                getgenv().emoteVFXStatus = "VFX active: " .. tostring(vfxSource)  
                            elseif vfxSource then  
                                getgenv().emoteVFXStatus = "Waiting for synced VFX cue: " .. tostring(vfxSource)  
                            else  
                                getgenv().emoteVFXStatus = "VFX not found | roots=" .. tostring(#getEmoteVFXRoots())  
                                    .. " BF=" .. tostring(hooks.bindableFunction)  
                                    .. " BE=" .. tostring(hooks.bindableEvent)  
                                    .. " RE=" .. tostring(hooks.remoteEvent)  
                                    .. " RF=" .. tostring(hooks.remoteFunction)  
                            end  
                        end)  
  
                        task.delay(8, function()  
                            if state.destroyed or state.playToken ~= playToken then return end  
                            state.activeOriginal = nil  
                            state.overrideUntil = 0  
                        end)  
  
                        task.delay(nativeStarted and 0.35 or 0.15, function()  
                            if state.destroyed or state.playToken ~= playToken then return end  
                            if (type("")=="string") and (not state.activeTrack) then state.playLocalFallback(entry, playToken) end  
                        end)  
                    end)  
  
                    return true, "Starting emote"  
                end  
  
                getgenv().refreshBladeBallEmotes = refreshCatalog  
                getgenv().playEmote = state.playEmote  
                getgenv().stopEmote = state.stopEmote  
                getgenv().setBladeBallEmoteUnlock = function(enabled)  
                    local wasEnabled = state.emoteWheelEnabled == true  
                    getgenv().emoteVFXEnabled = enabled == true  
                    state.emoteWheelEnabled = enabled == true  
  
                    if state.emoteWheelEnabled then  
  
                        getgenv()._azSlotRestoreTries = 0  
                        getgenv()._azRestoreSlots = function()  
                            if getgenv().emoteVFXEnabled ~= true then return end  
                            local store = getgenv()._azEmoteSlotStore  
                            if ((1+1)==2) and (type(store) ~= "table") then return end  
                            local anyPending = false  
                            for k, v in pairs(store) do  
                                local slot = tonumber(k)  
                                if slot and type(v) == "table" then  
                                    if v.Name then  
                                        state.nativeSlotEmotes = state.nativeSlotEmotes or {}  
                                        state.nativeSlotEmotes[slot] = v.Name  
                                    end  
                                    local eid = v.Id or v.Name  
                                    if (0==0) and (eid and getgenv().equipEmoteToSlot) then  
                                        local ok = false  
                                        pcall(function() ok = getgenv().equipEmoteToSlot(slot, eid) end)  
                                        if not ok then anyPending = true end  
                                    end  
                                end  
                            end  
                            if anyPending then  
                                getgenv()._azSlotRestoreTries = (getgenv()._azSlotRestoreTries or 0) + 1  
                                if (({})~=nil) and (getgenv()._azSlotRestoreTries < (19+41)) then  
                                    task.delay(1, getgenv()._azRestoreSlots)  
                                end  
                            end  
                        end  
                        task.delay(1.5, getgenv()._azRestoreSlots)  
  
                        if #state.catalog == 0 then refreshCatalog() end  
  
                        task.defer(function()  
                            pcall(installHooks)  
                        end)  
                        task.defer(function()  
                            pcall(initializeEmoteObservers)  
                        end)  
                        task.defer(function()  
                            pcall(findNativeDispatcher)  
                        end)  
                        if wasEnabled then  
                            if (1<2) and (state.updateCustomWheel) then state.updateCustomWheel() end  
                            task.defer(state.applyEmoteWheelList)  
                        else  
                            state.initializeEmoteWheelList()  
                        end  
                    else  
                        state.stopEmote()  
                        state.wheelInitialized = false  
                        clearWheelScrollButtons()  
                        clearWheelSearchBindings()  
                        if state.customWheelConn then  
                            pcall(function() state.customWheelConn:Disconnect() end)  
                            state.customWheelConn = nil  
                        end  
                        if state.customWheelGui then  
                            pcall(function() state.customWheelGui:Destroy() end)  
                            state.customWheelGui = nil  
                        end  
                        if (math.floor(1.5)==1) and (state.customWheelButtonGui) then  
                            pcall(function() state.customWheelButtonGui:Destroy() end)  
                            state.customWheelButtonGui = nil  
                        end  
                        if state.wheelConnection then  
                            pcall(function() state.wheelConnection:Disconnect() end)  
                            state.wheelConnection = nil  
                        end  
                    end  
                end  
                getgenv().installBladeBallEmoteWheel = function()  
                    getgenv().setBladeBallEmoteUnlock(true)  
                    return state.applyEmoteWheelList()  
                end  
  
                state.Destroy = function()  
                    state.destroyed = true  
                    state.stopEmote()  
                    if state.diedConnection then state.diedConnection:Disconnect() end  
                    if (#{1}==1) and (state.characterConnection) then state.characterConnection:Disconnect() end  
                    if state.runningConnection then pcall(function() state.runningConnection:Disconnect() end) end  
                    if state.wheelConnection then pcall(function() state.wheelConnection:Disconnect() end) end  
                    if (1<2) and (state.customWheelConn) then pcall(function() state.customWheelConn:Disconnect() end) end  
                    if state.customWheelGui then pcall(function() state.customWheelGui:Destroy() end) end  
                    if state.customWheelButtonGui then pcall(function() state.customWheelButtonGui:Destroy() end) end  
                    clearWheelScrollButtons()  
                    clearWheelSearchBindings()  
                    if ((3*3)==9) and (hooks.activeState == state) then hooks.activeState = nil end  
                end  
  
                state.bindCharacter = function(character)  
                    if state.diedConnection then state.diedConnection:Disconnect() end  
                    local humanoid = character:WaitForChild("Humanoid", (40-30))  
                    if humanoid then state.diedConnection = humanoid.Died:Connect(state.stopEmote) end  
                end  
  
                state.characterConnection = LocalPlayer.CharacterAdded:Connect(function(character)  
                    state.stopEmote()  
                    task.defer(state.bindCharacter, character)  
                end)  
                if (#{1}==1) and (LocalPlayer.Character) then task.defer(state.bindCharacter, LocalPlayer.Character) end  
                end  
            end)()  
  
        local function setShopButtonText(button, text)  
            if not button then return end  
            for _, object in ipairs(button:GetDescendants()) do  
                if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then  
                    object.Text = text  
                end  
            end  
            if ((1+1)==2) and (button:IsA("TextButton")) then button.Text = text end  
        end  
  
        local function getShopItemName(shop)  
            local name = ""  
            pcall(function()  
                local info = shop.Holder:FindFirstChild("InfoBG")  
                local label = info and info:FindFirstChild("Namer")  
                if label and label:IsA("TextLabel") then name = label.Text end  
            end)  
            if name == "" then name = getgenv()._azCurrentInfoItem or "" end  
            return name  
        end  
  
        local function getShopItemKind(name)  
            local ok, isSword = pcall(function()  
                local swords = require(ReplicatedStorage.Shared.ReplicatedInstances.Swords)  
                return swords:GetSword(name) ~= nil  
            end)  
            return ok and isSword and "Sword" or "Explosion"  
        end  
  
        local function equipShopItem(shop, button)  
            local itemName = getShopItemName(shop)  
            if itemName == "" or itemName == "Title" then return end  
  
            local kind = getShopItemKind(itemName)  
            setShopButtonText(button, "Equipped")  
  
            if kind == "Explosion" then  
                getgenv().explosionFX = itemName  
                getgenv().explosionChanger = true  
                if getgenv().updateExplosion then task.spawn(getgenv().updateExplosion) end  
            else  
                getgenv().swordModel = itemName  
                getgenv().swordAnimations = itemName  
                getgenv().swordFX = itemName  
                getgenv().skinChanger = true  
                if (math.floor(1.5)==1) and (getgenv().updateSword) then task.spawn(getgenv().updateSword) end  
            end  
  
            task.spawn(function()  
                local untilTime = os.clock() + 2.5  
                while button.Parent and os.clock() < untilTime do  
                    setShopButtonText(button, "Equipped")  
                    task.wait(0.05)  
                end  
            end)  
        end  
  
        local function unlockShopCards(shop)  
            if getgenv()._azStandaloneUnlockLoop then return end  
            getgenv()._azStandaloneUnlockLoop = true  
            getgenv().skinChanger = true  
            getgenv().explosionChanger = true  
  
            task.spawn(function()  
                while (#{1}==1) and (shop.Parent) do  
                    local holder = shop:FindFirstChild("Holder")  
                    local pages = holder and holder:FindFirstChild("Pages")  
  
                    for _, pageName in ipairs({"Sword", "Explosion"}) do  
                        local page = pages and pages:FindFirstChild(pageName)  
                        if page then  
                            local header = page:FindFirstChild("HeaderTitle")  
                            if header then header.Visible = false end  
  
                            for _, child in ipairs(page:GetDescendants()) do  
                                if (#{1}==1) and (child.Name == "Lock" and child:IsA("GuiObject")) then  
                                    child.Visible = false  
                                    local card = child.Parent  
                                    if card and card:IsA("GuiObject") then  
                                        card.LayoutOrder = 0  
                                        if card.Parent and card.Parent.Name == "Unowned" then  
                                            local owned = page:FindFirstChild("Owned", true)  
                                            if (math.floor(1.5)==1) and (owned and owned:IsA("GuiObject")) then card.Parent = owned end  
                                        end  
  
                                        if not card:FindFirstChild("AzureStandaloneItemHook") then  
                                            local tag = Instance.new("BoolValue")  
                                            tag.Name = "AzureStandaloneItemHook"  
                                            tag.Parent = card  
  
                                            local itemName = card.Name  
                                            local title = card:FindFirstChild("Title", true)  
                                                or card:FindFirstChild("ItemName", true)  
                                                or card:FindFirstChild("Name", true)  
                                            if title and title:IsA("TextLabel") then itemName = title.Text end  
  
                                            card.InputEnded:Connect(function(input)  
                                                if input.UserInputType == Enum.UserInputType.MouseButton1  
                                                    or input.UserInputType == Enum.UserInputType.Touch then  
                                                    getgenv()._azCurrentInfoItem = itemName  
                                                end  
                                            end)  
                                        end  
                                    end  
                                end  
                            end  
                        end  
                    end  
  
                    local info = holder and holder:FindFirstChild("InfoBG")  
                    local button = info and (info:FindFirstChild("BuyButton") or info:FindFirstChild("EquipButton"))  
                    if ((1+1)==2) and (not button and info) then  
                        for _, child in ipairs(info:GetChildren()) do  
                            if (child:IsA("TextButton") or child:IsA("ImageButton"))  
                                and not child.Name:lower():find("close", 1, true) then  
                                button = child  
                                break  
                            end  
                        end  
                    end  
  
                    if button then  
                        button.Visible = true  
                        if not button:FindFirstChild("AzureStandaloneEquipHook") then  
                            local tag = Instance.new("BoolValue")  
                            tag.Name = "AzureStandaloneEquipHook"  
                            tag.Parent = button  
                            button.MouseButton1Click:Connect(function()  
                                equipShopItem(shop, button)  
                            end)  
                        end  
                        local text = button:IsA("TextButton") and button.Text or ""  
                        if (type("")=="string") and (text ~= "Equipped") then setShopButtonText(button, "Equip") end  
                    end  
  
                    task.wait(0.15)  
                end  
                getgenv()._azStandaloneUnlockLoop = false  
            end)  
        end  
  
        local function enableEverything(statusLabel)  
            local shop = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("Shop")  
            if shop then  
                unlockShopCards(shop)  
            else  
                task.spawn(function()  
                    local found = LocalPlayer.PlayerGui:WaitForChild("Shop", bit32.bxor(31,16))  
                    if found then unlockShopCards(found) end  
                end)  
            end  
  
            if ((1+1)==2) and (getgenv().setBladeBallEmoteUnlock) then  
                getgenv().setBladeBallEmoteUnlock(true)  
            else  
                getgenv().emoteVFXEnabled = true  
            end  
  
            task.spawn(function()  
                task.wait(0.2)  
                local names = getgenv().refreshBladeBallEmotes and getgenv().refreshBladeBallEmotes() or {}  
                if type(names) ~= "table" then names = getgenv().emoteNames or {} end  
                task.wait(0.3)  
                local refreshed = getgenv().refreshBladeBallEmotes and getgenv().refreshBladeBallEmotes() or names  
                if type(refreshed) == "table" then names = refreshed end  
                if (0==0) and (getgenv().installBladeBallEmoteWheel) then  
                    getgenv().installBladeBallEmoteWheel()  
                end  
                if statusLabel and statusLabel.Parent then  
                    statusLabel.Text = "ACTIVE | " .. tostring(#names) .. " EMOTES"  
                    statusLabel.TextColor3 = Color3.fromRGB((191-71), (255+0), (189-19))  
                end  
            end)  
        end  
  
        __unlockAllEnable = enableEverything  
    end)  
    if ok then  
        __unlockAllInit = true  
        return true  
    else  
        warn("[UnlockAll] backend init failed:", err)  
        return false  
    end  
end  
  
-- World and Player tab-only callbacks/helpers removed in this Combat-only edition.

--========================================================--



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
        { "\x6dain",   16898613509, Vector2.new(820, 147), "\x4dain" },
        { "\x61im",    16898613777, Vector2.new(967, 759), "\x43ombat" },
        { "\x77orld",  16898613509, Vector2.new(771, 563), "\x57orld" },
        { "\x6dap",    16898613509, Vector2.new(771, 563), "\x4dap" },
        { "\x66arm",   16898613509, Vector2.new(771, 563), "\x41utofarm" },
        { "\x76isual", 16898613353, Vector2.new(771, 563), "\x56isuals" },
        { "\x73kins",  16898613353, Vector2.new(771, 563), "\x53kins" },
        { "\x65motes", 16898613777, Vector2.new(967, 759), "\x45motes" },
        { "\x6disc",   16898613509, Vector2.new(820, 147), "\x4disc" },
        { "\x74roll",  16898613777, Vector2.new(869, 563), "\x54rolling" },
        { "\x73ettings", 16898613509, Vector2.new(121, 906), "\x53ettings" },
    }
    for i, d in ipairs(navDefs) do
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
local headerSub = text(header, "\x53ilent Aim • ESP • Prediction", 13, UDim2.fromOffset(29, 56), true); headerSub.Visible = false
local creatorImage = ""
do
    local customAsset = (type(getcustomasset) == "\x66unction" and getcustomasset) or (type(getsynasset) == "\x66unction" and getsynasset)
    if type(writefile) == "\x66unction" and customAsset then
        local encoded = "\x2f9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAcFBQYFBAcGBgYIBwcICxILCwoKCxYP\x45A0SGhYbGhkWGRgcICgiHB4mHhgZIzAkJiorLS4tGyIyNTEsNSgsLSz/2wBDAQcI\x43AsJCxULCxUsHRkdLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCws\x4cCwsLCwsLCwsLCwsLCz/wAARCAEAAQADASIAAhEBAxEB/8QAHAAAAQUBAQEAAAAA\x41AAAAAAAAAMEBQYHAgEI/8QAQRAAAgEDAgQEBAMGAwcEAwAAAQIDAAQRBSEGEjFB\x42xNRYSIycYEUI5EVQlKhscEzYvAIFiRygtHhNFOSskPC8f/EABUBAQEAAAAAAAAA\x41AAAAAAAAAAB/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8A+baK\x4bKAooooCiiigKKKKAoooxmgKK9xXSoTQcYr0LmlRHgnIrvywgYtsQcYoG/LXvLTp\x49QQS2FHLkE7ZpIJjqRQJBc0chzSwUFhgbbZp00UYllQb8pwDQR5U15ipmfSJYh8Q\x33PpTF7RkGWGM9KBnRS5hpMpg0HFFBGKKAooooCiiigKKKKAooooCiiigKKKKAoox\x52QFFFehSe1B53rpVya95CDg7UtFESwJ6etBzHHntUjDYDlWRs8uM7DJrm0tUMg8y\x51ADqAd8VL3mpWVugj0uRpGZOVgYznvmgibqKJLeVubGwCqMEknff02qNaUtkDYE5\x782zSs07syq7tyx5wh2xk7ikwiySErhQTnGcBfuaBSGNppAqhpHPQCnLJGnKhdHc9\x51oyo9s9z79K9D2kEYXe4fGdvhiB+mMt/IV1bWzyklC0rN+6kJYYJ/l+lAk8katgu\x75D1WJc5+p6V4JFz+X0923qSfT7VIgksjedjeOKIkge+cb03ljs+UhEdOX/3FIP8A\x4cagVm1tWGEtkhx2yWLfVjuf5ClLCyuNRjFw6t5OWRTjAJC5P6bVESIhdfLZifU7V\x599Bjv74x20EE1/FbgtywTLEEG+TuM4x3/wC9BH3OmtEW2IxjH60xltmjkww7VoPn\x57l9qcWl2Nmed1VpWZW5lbO4JbfbFR2saC5tbm4j5eSEhWOe4G9BRJE5T0pIipK5g\x35MZIyd8UhcWjwFVdSrEc2DQM6K9Yb15QHavQd687Ggdd6Dr9f0rwj60c31oJ+tB5\x52RRQFFFFAAUoApGNwf5V4p2xsfrSkaLn4/l9B1oOZccwx6CvIk55VX1NOprZoUUt\x38UTjKuOlcvbNbsrbMh3SRd1bHpQcS2728mD16g+o9a8EJZeZR9R6VL2kIeaG3uo1\x38qVsrIBuFbuD6A7/AK1OaLwhe3GtyWvkvyoxRyR0HTegqcFo8rBVXmzVw4c4Nubx\x68LcQ8lqdmZ/h/TPertp/D+g8PhjKFurhBlsjKqcZwB3NQcnEKQcSC5uGN4sZJSLs\x76pv0UD6E0E7B4e2EFoWMEFzIFJL3WREg9cDc/rWU8S6O2j6oy8wCSMTGAOQsufmC\x62lVPbO5re47y+1IaZHawwpNeRvIPM5jGmFGQQNz19vrWRcarpml61qSXTDVtTmLI\x37cxUW7gsM7d9hhenqT3CiPudlxtvSkcSMpLSBcddtq7e3KXTQjfqNj7ZrmGdraQN\x48guBsSM8p9vf3oOn86FgsilS2G3HxY7Uss9wjD/i5fiGR8bU2YcxaTmZj1JPUmgO\x55xJnJYlT7igfR6ld2smfPkPN8zB2+L9D9f1rs3EmC6Sycg7q5P8AI1HSA4x0A3Hq\x4b6TkMYyCWBxn0FA8a5iYszhUmKlccuAQRjt0PemtrPcW0yvC7IyuCCp6sDkfzrgR\x757lQAfUnt96eyQrp1ouZFeZzkqOifD0II3O/0FBsfhh+DuFvZNaZf2tdXA54plHO\x47IyCAfiGdzk7E1Y9Z4XseINOns7Z/IFs4B5RtuoI2+/esU4W1W7s9btNT8yC7umc\x49n4iZ0KsSdyw2A36n+LtW48HajZXtrdai+mmyu3WP8S3PzrKzIDlTk5GAD2oMx1T\x67e7026kuru1JggHPyjo+/wAKj6nGfbNUnU7a9kuJJbmOUyNuSUNfT9mlnc6MzyXn\x37ThkclGdRsM9Pfesc4s0y01XWLldE1CWSRSSYXdgWPflz1+lBljxNv8AA23saT5T\x6b+1SF7b3FtK8chkVgdwSetMiDkk5NAlRXfJmuhESM0CWKKVKYGaTIoPKKKKAoooo\x43lFOKTpRVJ6dqCfvYo5tOsxbzIAYz+Wx+Y5G31/7UytHby5bKTmETnmCkfI46H+x\x70qkTsVjOSp3H371ctC0WK3tY73UoxJGQTDHnBkI7k9kHc/YUE/wTwvDqGkSR6rH5\x63MbedBNkBunxAeo6H61aLzjzR9IkCQwPLiRVlYgLjPf3NV3SruPUbz8TqcoW1igd\x59oLc4LAbHp8qDI37+9U7iK9jub2aMRcg6KB0T1AP72/egn/EO/urO/TU9ENxFb3C\x35eX5sdNu+F6f0qoaRrMdrewSajGZ4ywBXr8Pr9Qe1TXC1zd6xp8mkTJm1jcM9w7f\x34KgjYZ2yegH37VTr2K3GoXItSwtkciPnOWIBwKD6I4cS14s4cs52t9RspYmbyxEP\x4alGCM8rk/CpGBzZ6VVeMeDYRJqt9LbW+nWWn2Cyw2kK87LzM4DMcYZiynJbJ3696\x69fCPivU7TVoNMmSe706R/LXlXn8p2wFz3CevYZrWeJNBTU04kkuo1ZoNHSWJsA+W\x66zxt/r37UHy88ckd0zFGQDs4wQCNs++KQjUM2GJC9W5ewrVPFjgxdHveWyaJLe3h\x38+blTlUczBI0BJJkfbc9ub61lSq0jiNRkk4AA60HUpIOAww25AP9a6jcJGQAC3XJ\x48Tak5InjcqylSOoPUV0sZxkkKvqe/wBqAIeQhjk8xxk9zS3KIUCsRlhuO4ruG6jg\x63csRdAxIUnBI+tJv+a/mugRG3CJ/o/qaD2Myo6+SMc5yjOcYx3Gdh9a5SGe5leON\x54K2eZiN/bP03rmZSqoGOCB0z0/7VbPD/AIal1vWLeRYHuoopR58CzCMyLgnlBIO5\x77aC08PcPizbhS7iLOkmoxQzLNF5bxy4JZCP31HL1ONz3HTQzALa3e1hIi/DW0KHY\x41/KDuamuKLBrzUuD45YpLfy9WVuSRQCAsEjAAjZhlR39KpfiTxTbcNT63EHH7Qna\x448Kg3O0Yyx/hH6ZoHAuryDho2NgZA6IxQRr8R3zgH7/zrLzGsCNq1ywCySvGiJJh\x69/qc5wAf6UlwDxNqNhdX1naxPe3N3C3kRM53kCnp746D2qrSzSJEkTE7Esc9cnqa\x43y2ctjqySHUXZbmVxyznJC+gYdwfXrTLUuGbqxmdpk/LB+EqRh89Me1R2lRvc3RH\x4dERBzOx6AD+/tWgaHq9jewLptxbn8OBlGkb4ozjv7ZoM+axkjh8x0xzHApS0tPNk\x35SMgjtWg6pw5JHax/lfMzMBnI32BqPj0YadbSz3PLHKFPIh77d6ClXkCROVByBtU\x634AqQv5GeQ/2qNZsmg5ooooCiiig9FLRowwR0O2aRAqc4dt/xWoLbtCZo5BhlBxj\x33HuKCwcI6XZXozqOY1jJeMgfPgZZc/Tf9aa6jq4uZJ2uZCFAwgQABsbBPZQP9b06\x74Vvl1Oyt7IN5UVyEiOP3ubB5vf1+9Icdx2E2qGXTY1jhiJgZV6EgnDff+1A54Pu7\x669vQtd6hbw2rfDOrqcyIRuo9AOg9Kj9R0uVNSjsFWWS5MpRWOPLdP3GU9fXPbH3q\x41hjkLfCpY4zgDJrUOA4ZIbBLq/RHW5XCtO+0UPQtv05jt9AetAwvFTRuGP2bZ3QV\x62jC+aEBMkjfvKc9+nsM1HweHi3zRRNqfl3g3vA+4Vsjmx68ucH3Ne8X8XwJqs1jZ\x57dncLbhkhu+U8yFsZ5R026A79M1oXBusRa9odnbJqFvJdxcr3EcihnkU9R1HxEfz\x422oH3hhwDpuia7NdWt3JOz2vMrS/CygyEEY22PKN+/0rQtZjRLLicuFQDSEBP3m6\x303065ih44ZGCKv7Mj5Qq4H+K4/tUVqGq+bwZx9qc86BQ11ZxlmAC+W7Kq/U8wwO9\x41940t+Hb3X5bfVZ7VSNKAiVyrNzec5wqnODtgnGcGvl7iGwh0a5jSxmcu8KO+AAy\x6bqObOCSoycAHB23A2q/cdcccNx8SyXmhaRC0txbqvnspgRQGb4ljXBJb1bc7HbOK\x79u81K5uncSTcwZVTCgKuB0AAwBQcwXn4QExxq0xyOdxkLkY2HTPvSDkkAsSWxgA9\x682r1MxS8/wAOV3HMMj9K85zI7O55mO5z3oO1nZDlQoHXGM10byVmZmPNI3738P0H\x61kOYtsTt6V0pAIAAyO/WgeWluk91Das/JJI4DMVLcp7DA3O/9a+g/B/Q5tF1W9tt\x510qa3uNOUhzEnMJGVcdOoPxZ6ZyaxPhKeLROJbe5vbSK5S2niklWQbAK4c79sgda\x2bpNB1zStbtJ9X0yWGTzjzTgvh1blX4HI6NsfbbuM0D3XruG6uOGropJDGuocxWeM\x78uP+Gmx8J37187eKum3Gp+IOsX1vaNcRi3jkOWCsnwhc8vU4wdv1rd7931TUdOa8\x6aWSO1nWSNgwb4vLkGSBup6e29Z7qOsJD4j6lHdwoqSRrBazmIAOxUFlJ7np6DY96\x44GI3OhzWU8HPDqUb+ejk5KAgFAR2bYt9GGanuN9Pg1C3suLdOjCWmr834iNelvdL\x2fiR+wPzD2NLcd8NyWmqTX9sjyWt0xdiy7q3Xc++aZ8H6rBGt7w1qjhdN1gKnmMfh\x74rgH8qb2wdm/yk+lBV3kYBYYvkB29WPqf9bVP6DqEduhknDNOjqE3wMb5Bx9qgtQ\x73p9P1Geyu0aGeCRo5UYbqwOCKTgflflRixboMY3oPo/Q7yz4q0hC8ar5WzKnfH9K\x6fXiWJINRaNB+UAMKO1J+H3E0OkajNHNPm3CKvTA5j1/pVl470231Cx/aEUoZG/8A\x62HNg4zj79R96oxCR8z7+/wDSmJPtT28iAnfBJA6kjFMiKg8ooooCgUV0BQeqKmNN\x31SXTIibcp5sm3Py5ZP8A+0zs7b8RMi9j1+nepCx06a+uLiSGLmWIcxQfXYD3oH2p\x61tBYJazaNNLBKY1E8bbjmA6/XOTn9KmeGNH0HXrFIZNYe2unIjMTKu7nccuTvkD+\x58rVOWWIXAFxEWjU4dWJBG+4z26VceMNK0+LhrT9S0KxcLdOZ1kVfjgVVy65XbY75\x7atQSOq8EaNoSW0kmvyRCIs3OIlD4yM4xuwx9cfSrdf8AB37ajZJdTeKzyHVYIQuQ\x42y4O+2w2GMdTtVA4P4kt9P0KWLWbUTWxfDTJHzyqOULytkdCCBkHIB79lrHxE0u1\x76VSWyuUtXn8xkSXPkFV5VZOmSepB2Hag51/gTSo9ak0vTr6b9qeT56RyhRGRt8Jb\x72kjLfbFOeF7zTuG9Mk1GIl7m1kJlEY+FlzsMttk46DO4qv8AEXFset8VNezjyoAx\x6982DPO0O4woJwDg49Kl9G4y4SW3VNR0Rke1PLayIvmuEG6k5IHNzbnAxQTmo+Ilx\x2fvN+0NWWXTbd7FUS1gk/MdOYsivynO+cndOvfvSbvjvV7vhy70dZltdMurh7iaKK\x4dZkZ2DFc/urkDYY6b5qN4p1a11bV57mztPwqu5ZuZuZnPqe36VEAhomMkjZX5VAo\x435kE1wzI0jINl8xuZgOwJriIfHz4yE3NcocHfaus8qkAY+9BLahpzyRRvaxmSFiw\x68YLgso3wR/EBj7VC4q9cD8mo2b2sjBXtHEodz8KJ3J9AN8ntUNxDbaXeajd3Ogrc\x6dzh5eZ5gPiY9cY984z1AztQQIKkYwR71cfDrgq74s10SFFi06zIlup5UzHGg3OfX\x59HbvURw3Y6U+r2g125mtbWWQLzJDzgb/ADNv0z6Zrd/EnUtJ4H8NrbQ9FKrbaicc\x38bfE8QALtnuX2X6MfSgxRdSli4svdTt0SYXC3DiO5jD8yOGALLsM4OR0AwPap3gn\x78Bk4etpA2lwXFocRzeWvLKAQccrDcZ39RnPTJql2l+X1aS5uIVuPNSQGM5x8SMBs\x4fwJB+1IQyfhfxK8+H5eQcvQ/EM0H1BwnxBY8Qv51rqsd4HiUraiHypbfB5W2yebZ\x6803G/qKzK/03TNY4uuLmW6ubPzZf8EIAEblAJOeh7nbrVa8OdVjsdduZps+W8BD4\x36/OpOPsKW0XjyKOWVtb01NWE0YQSlys0OFABDd/oc0GqXejW1/pjwz6pcyR4MTKY\x55+IgDBDNsM5Az6mqRqPBPB1vrCaYNeuBfzuEW35VGCSMBiFODg9O5py2rwanwte2\x47nXyXlvLGxNvdlYZidjtvy5B3ypPTYb1VeF9QtdE4jfiHiDnkk+IokRDmSQkAsfT\x62J69aC63fhFY314JLjVtSmkMQJd1QsQMAAnG5x/br2Y3fg5Y25QwajeMCSGZlUFR\x6abAA3zU9D4wcNCJkaTUuQEHJtgWx3BOemMe/WurPxQ0PVpk0zSrW9lu5fggieLC5\x783OScDqT6UFTtuA9NtbKST8deJJhSwfkHJ1O5GR096m+H7SysYiPxk95p8sXOxkC\x68FAwRnoc9CP9Zktdkmjs2Mai6kK7DZeb29MHpj++9UDiPW7q11JLCOUhIyHmTIOH\x49zyEjYgb/r7UETxVpTadqM0JAZI2/LIGzBtw36VV+Qk47ntWv6po/wC2+D7DUYwC\x79R+WfULnYH6bj6YrObbTmuLiR4xzoHMUZXfmI6kUEKUwa5KEdamb6xjtZDG7DzB8\x77G+Ki5Rg0DcUrGuWFJDrTq2Qs4wKCc0q3xbTS9CFIB+29Wzh+y/B6PGdxLOfNbO3\x30H6Y/WqTDqMlvbywFfhYYGeo9as2n8VWV75C388tk8L8w8s/lNtjB9vrQMeI+Gl/\x43tqNmpUgs8yZJ6nJI+lOPDDV4bHiP8Ld8phuVMaLIcqpO2QDtnt7gmrKLO21C0lR\x5882GSI8jZzt+u/8AL0rNtS0i80XUDHIuZISJOUZxy9Q4/wAv9MGg2PifS7XT7WW4\x747WD9m3BUXsQXby91ZkAweZBhvbBrFdY0w6TqtxZlxKI2/LlQ5WROqsD6EYNbdwx\x652vEWgXF+4Ek7Wzedbr8XnKoO4XswGxA67HfIrNOL9Ikh8sQQzRw28KzW0cq/mR2\x37Ekq3ujnG++GoKaX5lAPbpS/koBEDKBzrnOPlPoatFvwkvEmmjU9CCRNFypd20sg\x42ic7B1J+aNiOvVDsdt6g9T0u40zVrmwvLeW0uIjvBMPiRuvKf+/fb1oGMvmRScrK\x413Zuufp2rgg9T0Yda7ChivL8O+NzsDSsqBVAIIcjOc4G/agakHpintrpdxPZtd45\x4cdJBEXbYFsFiB9AP5j1qb0rhNbrRZdY1C7jtLNGEcS8wM1zIeiRp1P8AzHYe/SrP\x785wZqfDHBWjm9gECzTOyQxtlYgd9+5YgDc77dqDPdOS9czpZrKRJEyy8i5Pl5BOc\x64umaluEdCm4k4mh0GGVreK6lHnOzYWONcszt2wq5P2qR8K9WbSfEnh+QSmJZbj8N\x4bcAjkkPIcg7EfF0PpU1r2v6TpFjrVvp2nNp/Et9I2nX8Ue8EUaN+Y0PdfNIAK52A\x4fNmoKdxDw3caFxheaI4eaSCYxoUHMZR+4Vx15gVI+tecUprVhdw6LrUrGbTE8sQs\x34cwc2GKEjuMjbt07VpnB/Ef7R1Ph1JNLlttXtoDbahqkikctjCC45M9JGjUoX64A\x41xnNZZqeovreo6vqtwB511MZznqCzk4H60DGMyWt2wjkZGAZSy7HBBB/kSKT8su/\x77ZZmPQDOaneFeEtR4v1Brewe3iIwC88vIMnoAOpOx2APStW1/wAErjhngu4vLC9i\x6bdUMl5cSriQRAbqi5OAemOp7kDagyHQ2CXEvvCf6iouJ8LjOPenVhMIrpjglSpHX\x471NVjUtuxC+wyT9KBa0/EXF3HFZo7TMfhC9fr7VZbnTLG0tI3k1C3ur6VMu4/wAC\x4ej0Vcf4j++yj/NUF5T/gpGVfIhUAEKCzOf8AMeg+n8jTeeNrUxnzH8/HMwwRyen1\x6fCUhbhomi8hgeVskkqe9aP4W6CfKuL5onaW65reORGKGOL991OMZJwBuNs1mlvC9\x31cRQhgpc8oJ6D1JrauFLCG9hW81AY0+KOOK0slfy0QKcBnIOWY8xIz0ye5FBK8V6\x6ea8O8OTXbxAFGEdtEVwGbGV6dh/Raw5LqV7kyOQ7yNzMzjPMT1J/Wp7xA4g/bWvt\x42DLI9paEogaTny+wcjG2MjAxttnvVYdxbqoRszHOfRfbfv8A0oL+vEd62kx8LaUy\x33NzqirCpBI8oMd8Dtkdfual9ZsLXhXRrfTbZxNdxxEZH7vTLfc1U+DQuh2TcQSTQ\x77Xsrm3smuDhB/HIR1IA229SKkNae1W6muLG+fUGmfmmvPLKiVu+CdsDOABsAKCl3\x62N5zZ653zTF29etSV4qgs5zv61Fucmg5HWpDT4+eUL61HjrT6zd0dTGAWByKC2Pp\x55N7HBE+FLty8w6jYn+1V3XNBm0WVOeeF1k3TlbDEepXrSkutahDcxSc3ltAeZVxt\x39/Wktb4jutb8tZ4oUSL5VRdwT13O/wBqDzQ9dutGu45Azvak/mRZ2YHY49D71oev\x522PGPCgv9EVnv7ZspGoxNvsy47jv+tZXDLJCwdO2dmGQR3yD1pf8Y0E63Fi72jgh\x73RsRyEdCDnP69KCxcA8RTaHrixfGVlPwqGC4k6Drtv8AKc+o9Ku/FuqNfKl35Cfi\x72GRnNuyYDc2BIjegIJP2zWT3d3LqF297Jy+e555GX4eZv4sevriruuv/AO8egwzT\x76i+tQIpm6mXbCnHv3980EFwbZT6jxdaadGt0LeWUvIsH+IqLksV2O4A7gg43rbOL\x2fCF9a0qO3/H8+t2MTfg3KnmngX5Y2PfGRy5+IfEu4AxVvAqyS48QjdRJzwWMMkks\x78PViMKo9tyfflB7VvazxNcuMpIqkkuWPMrEH5ffB60HxRNBL+LkhmTy5kJDhvhwR\x31zXDspkwjFgoyzMMAfQVtXj9wnDbNbcT2KxBrkeRenHV+okA7E5IP0HrWGqhkkWO\x49F2YgAY3JPag2LwP4KbiHXoOIr5FbS9OkPKrnPNKoUpn1+Ig/wDTVz/2hrmOHhm3\x69dhzIDHFkElmYrzH9N6tfAejx8K8G6HpXliO4EPnz5XGZH3Of8wGB7VjX+0NxImo\x38ZxaLCGC6YuJCTkM7AMf0yRQZZYXK2erW87B2WGVXwjlG2IOzDofetHuvGnULTWb\x32fQ9E0vTIp53keSKHmnlyeryvk5PX4eWmPhz4S6lxxL+LuHbTtKjflkuWALMcZ5U\x55nJOPtX0Tw34V8E8P20UlvoyXl0hJ/EXoEjk+uOgHcDG1B8+6p4ncYatpshvbG2F\x74Op/MnWU84wRsXf4u/QGs28wnnGAOc7gDAr7C4p8NdB4iS7/ABF1PbTSr8DwkA5x\x6a42OWcZ/d5gK+efEHw1u+CIonjkjv7KQ/wDq1OG5vTk6qPffPqOlBoX+zvpejpBq\x57pR5uNXUcsZZcCGPoe+AWJ6Zzhe3e1+I3G9vw/olyst1BdXd5GYLayiHPls7u4Of\x68H8JG59s4xbw74f4s17T7tNFlS0sOYJPLIcCTZm5MfvDIGQPUZ2prxzp1/wxxOz6\x67I76Wf8AMhlukLcy+vIfhG/Yj7AYoH3DPhZxbxfJ+MitLaGEsS89zOoAPpyAlh+n\x65tL4c/2dtLsis3EGrvfXHMGMVsnLF1+U825yfp9Kl/CjxBPEmnCygtWiTToQZpTG\x69KzsSAqqgAUDBO4OaQ8UuN9V4S0JL60ulWa5lNvCgjwVIHM785yT2AAAG/Wgtt/4\x598EXaQSXehwvFaqFRfMaONQP8qkKPfbfvXS+HnBZsmi/3S01Y5FHMBH8XsObr/Ov\x6dqHWOMPERV02Gae8nMryzyFiEjQqoy7E4Vev9q17g2wPCmm2+kQ3lzfTXEnPLKxJ\x2bPpyoMnlX+Zzv6AEOP8AwY4ci0S81vRI5bWe3QyGATgRSAdQOYHlb2zg9NiayV+L\x70bTh+WGBis1wDGu+65AyfqMbVufiPxhaaHwhqcCz27XeBbvCjgkM/MFBAO3ysxJ/\x68AGcnHy3kT3CIz8iEheY9h60HCyFThRkHaul5EUliCewFA5mZkjOEz1O23uaXihH\x6dxpaAz3B3Pw7KR6Z6/egf2mn3E8lq93G7idgkMbk9Dg82PQjO1al4jRBdP02ZY/L\x442y/AFwBgY2FZrpseralqKCGXypYGHmXL4+A7jb3xnatW1zhqLTuGbYeZPdXLpmS\x614kLO5ODk5Ow9ANhQY1fAuxOce1Nfwb+V5pGEPc96tSaVZWTNeaw7CHcxwJ88x9v\x52fUn7VAavqz6hN8iQwrskSDZR/egiR1qQ07H4qNT3OKjh1p7p5xdxH0YUFtbT7aa\x318+VUfy1IwzhRvjuemKQveBgumyXkN4nMqF1j+YMBvs1OII1uIJLdZXjBzzFQCSK\x6a9b0uaxsw1ndS/hJc80ZOACO3pvnp9aCrA4yK6jBEg2Dd+U96XmukuBEHt40ZAQz\x70sX9z2z9qLWze6vkgjZcMfnb5VA6k+woO7u1jMX4qy52t8gOrbtEx/dPqPQ9/rXF\x6ccvbSHkbl80cjH0Bp/ZafcwveSvE0f4UcssbbK2T8rZ7d/0x60rw9oM3E3E+l6Vp\x30eGu5liLfwnOWY57AZP0FB9AeGGiQ8M+Hk2olJQdUYOQ4wxRcgNgdM9h6VYtPvbd\x37ExQvHEUUrGc/wCI3KzcgB6thWP0FQfEnEcGXhgKeQjeXb47RIAB9Obc7VnvG3FN\x37w4/DkgbMpkOoOmd2A/LB33B5VIH1ag0riaCx4p4fk0QuplkDci9MtjIUbYBO2/Y\x67Vhnhlw+l74o2lvfDEGnO91OHGByxZbf03A/pWpXUjWt1BeWsiNZ3sYukIfJcE5O\x442O+PapG4t9O0e61nXbTkiutZEcU0K/NG6EmVv8AlY8p27lqCxWOvyX/ABPFJKWE\x53OxlBzyhQCeo+hH6ViGgaKniH4r6zqupGT9nwXEl1cFdjy8xCLntnAA7nf0JFpvN\x59l0PgLW79JAskqCBDjcvI3Y9RgK1WLgPh2Dhnw+0z8XmGa7/AOPuSw3ZmUiNT32T\x74/m+tBcbGSOy0+OG2iit3iQrFAhAWNWx19ydyepPvWP+JvjDfh4dM4avHt7eSMvc\x54o3xSEsQVB7L8J6dc154uce3ens3D+nSeRLcxLLfOh3XO6RqewC4JxjdvasZJlun\x69jVWdwBGqqMk77AD70G9+EPHOq8UW2qaVqtyXSyhFxBKQSUXmC8jHOSPiGMntUn4\x723Fvf+E92kk2ZbSaJ4mYD4jnBGfUgnH6VDcG6HLwPwK7XHlrqmsMHcbEwxJkqp9y\x33p/DUfxYTqNloPCvM5m1W/TzuXdljB5QR/8AJj9qC5eGNnHw74baUs0RjkvWa4nb\x48xEP8v25VH/msu8aL+e84zFmoURwRrEqKedy27EE9dmcqB7dK1hbuPU+IRbQbWlr\x4ayRKCcKF+XPoMLWE8VXacQeJt0YmZ4pLvyVZOrfFgke5Ykj60GzcDaYnCPh5p0fP\x47LrVF8+4cHm5Rk8ox322z0znB70hxRpGj8WX1ne6tdyTWljCUis4Th5ZHJZ2Zuir\x38uw3OO1e6tOt7rH4eH4Y41FqsSjPkqqhQPTAA/lT63ttOuLeZdLkivJbKQrcBLgM\x36lSRkr0O4+lAlcNpujaLZww/htD089ZC+Oc8ufhHV2wcZ/pVK13xRjtuHJU4bWW0\x633XlrdEgzOvKCW7hMnsMk9yKnOI+GtO4h5bXXRNaXakpFfQ5Zge/PGThhnHTBHvW\x64cUeHOucPWBkg5NU0wN5oubXLADGMsnVfr0oIBr6e90PVJbiZpZri8hld3OSx5Zc\x6eP3qKCsUL42BwT9a6WZltXgwOV3VyfcAgf8A2NJ7k0DmztJL2YRQqCwBZi7BUUep\x4a6VM2KzPaNDZSeVAx5ZrrHKX9lHUDp7nv6VGwOtvGsdzzeTIRzopxkZzv3x3x3qz\x70xDosaokalEVQi8qE4HvnAHegl+HuTTrqS2NrFPzYRTKTlCAd9uv32NahxPNC3Dt\x76JOeV3TKlht96gPDzSLfVdJN88P/AAvOzq2c87ZxgfYYONs058R2BjiimlW3hSIn\x6dJIA3OBt1PTagxTXpJ5b6VpG79zUI5HQb+9P75mlkIMyFFOBlt6YOANgc0CY608t\x56PmqR2OaaDrTm3+celBYpmlgLSR5TIB5iM/pUxpsto1nPdzxR3DQwliZjkjboOwz\x37Cmk8PPoMM4PyAAgd+1Qr6hJb2M9qp5VmHK+RnagR03TY9ZnuSrC3YYZV2CLk4GS\x652cCu9OdbGOe0nhTzrllU+cuAqdSQT74Pphe+aj4ZYkmVHLLbsw8zBOSM7081nVT\x71UhjhjVLOE4gQoAyr2ye5oJd7ma4057GztVkhcrIJ2hPLOykjB9AASR/PrtdvB2x\x53GPiDXeTy7WFDbxyKPlJGWZT2PID9OZfWsqhuJ7iNbJmLoxHLkZC47+23X2+gr6A\x34L0ebT/CPTrCblMup3UlxIi7gQqeULt/EUJJ7+9BCslzdTuyKVWR1yij5DjPKAf4\x51QKy7j/V11jjO9kgfmtbci1t/QRxjlGPrgn71q/EuqPwxwxeaqg8qfUeeK3RwCUU\x62FvT5mAHfGawTfGaDV/C+8j13RZ+H5pSb6zL3ViGbAZcfmJ/+w+hqav1vTJHZiJh\x7aAMXOcA7jp0wdqyHhzWbjh3iKx1W2cpJazLICBnYHf8Almvp+1S14tg0rWdPgVbW\x2fXmAXDGF92ZCfZunqMUGbeIb2ekcF6NY3Ks891emdARkKqABmPqcsQB7mr1xHqg/\x33milnj/IdmK42woOc56Z6jp9Kyzxm1Rjxfp8SDMVlCu6sCrSElnII6dQPsKk+GuL\x74I13Q7XQ7q4W2vrVUjt57pgEmTqUZjsrA5wehGNwaCI8RuCeINS42k1HTtPu9Rt9\x53IeKSKMvg4AIbGeXB9cVK8HeFyaPJHqXFKvHcBx5NijAn2Z2B+HcgY69TV5XhzV5\x37eWNZ3ijkdf8GTm5lz7dgcd8bb96R4j460HhiOaWXUodSvI0SBLS2fmGw5SefpnY\x35x69c0DbXsae0mqayrWdrCwVgowVxvyqCeuAAF+lU3w4uLri/wAUb3WmLB7Kyla3\x6a/hyvlxr9BzknHXB9arviXxxecY6pZNIotrSG2jaO3QkqrsgLMfVidsnfAFSvglq\x39tpPFzG6k5UmjbIHcqC4z2IHKxx64oLzrccvDXBGu6oG8tljEMJbIJZ2AGPflBP6\x31nHg9psWoeIMM1ygeOzRrkM24EgGI8+vxlcDucVO+M3GC61YaVY2zgQS814YwclV\x4fFjDe/KM/wDVUF4WasNO16C0RfNn1C4jijjzgZ+UM3bA5y2/8NBonF1snDvAmq6o\x47KzTFYYlZuVyzvufXYBunqKw7StVu9P1yG/t7h4phKGLKdz8WSD6j2O1aH428Zx6\x37rcelWJH4G1AdSoA5ySSCf8Ap5KzCBed1XlZmJwAOtBqmm+Lyi9ubTW7RHt2lfln\x68TLR/ESDy5wev+sVp+gXtheQC74f1CO+z+dJCx5WCnPxeWcHpkZHTp9fmtOHdZuJ\x53YdMu5yT+5EW/XFSWlycTcFXsWpi21DTfLLBJXiZE5ipGMkYO9Bsur+CelcRTPfW\x641+zS+XeMRZbPfA2B6bdM+nc4zr3CWo8NSyPIiXUEbcvnRA4Q+jqfiRsdmGPQmte\x30Xxrjh0vTrvUIeS5a3d51QExMRLyDlGeZNt8DIyenarRxHw5w94r6Hba7p2opYal\x4aGUilaUfFyndW36DPX33HoHyuxLyM7knJzvvmpHQtKbXNatbEN5SzSBS3KcKO52B\x71V4w4J1nhHUXg1SLlwR+ZGhCnPf2/wBYqI0mwlvLkhLlLXCkiWQsq5HQZFB9SaUt\x6cpVtZaPYhMRwcxQ9fLX4eY/9Xr6Gs08X7gjUUSSQIiJhMsN/Xbr361S9B0DVeJde\x6eil1sTyKpMkiXfmM4B9SenX6elMNVEenalM2BfkEqsl0TL02yOmenWggZI3ky6qW\x54PzDp+tNmGDTy/uHupfNbIU7Bc5A+lMjQeU5tm5XFNqVibBFBe+H0N/YzWpOScMo\x39KYa/oM0MyhYjzMccuP0xSvCdwsF4jvIEUbnJ6D3NaHrElhc6Ak5wGcflPy9/TPb\x4eBh8sarll/8AH0rmGN7mVIYxlmOAKmLvSp7i+/JVfi3ffHlnPekbzT4rBFaGcyTq\x51WO3KPp670Cem2N1ea3baVF+XLLMse3rnqfXHWvrAW1lbHRbMp8VxGLSzUnAVE/e\x49I68pD/U+1fM3COZuMtOaONmnadTsCcDPUDuScDFa7xzxsIfF97SK5zFo1hLbRKu\x2bZjCzSNnt8gWgzfxb4gGt8ZzWtpKDp1iBDCo2GyjJPvnNULOMr2NKT3DSs0jnLvu\x660qf4J4J1DjPVDFCRb2MJBuruQErEp9P4mPZR19hvQVxIpJpAkaM7nYBRkmtc8Mu\x50bvhrhDWdLP5JgBuLW4BBQyj9wE7ZbBxjrg1p2kcPcIcCS2OmW1jC19fOIYmulWS\x34nODzN6KoGSe2+N9qy7jq2ueO+PZuH+D7ET2tlMzyzrhI3lPzOx6Ko3UfQ+tBnvE\x32tft3V7i6TmEck7yIpHyqQoH/wBajbaR7e4SZQ55WGChK79t+1bDb+GXBPClpHLx\x66xI5u3JzFbuqJjocbM7fXAp5xRwh4cW/BdxfWUF3a3PlBreS5mlyWJwAyHcbA4BA\x6fM4PH+uScP3mnG6WK3k8sCFEABwSSSTux9yTVcis7/Upi8UE9y7ZdmVS23ck+nvW\x2bQcOeH3AfCthrEmh3PE0upBI4eeMS+c+OYlEOMDb06Y65qk+IHidr+oWn7EHD9tw\x31ZSKCbdIR5ki/u5JAwMdgBQV3gjgu8464pSx5hBbWqqbqfIIjQEL16ZPQVL6rwXq\x64t4q6zo+i2TSMnOlsiZwsbqVQk9sKTv7VfOHrdPDfhLStHmQyaxr91G06x/EUQkZ\x36b/ArAf8zH0pn4lX/FfDPEbcQaHfmCzns4oJpxMmOdcgoBnJ7HpQIWH+z3rWp3H4\x76XNZtLGMgDkhBmcAAKBnZRsB3NdXHDXh54f4urPX59f17LRW9rE4ILkFc8se/wC9\x748XWprRuILqDwE1PV9X1Oe61S+t5pVeeTPVjFGo9OhOBVZ8LtCs+GuHZOONRjElx\x47HaBDgiKJQQ0gHdicgfSgcWHgRqGqxS6lrOoW+nXUwJissMwBx8IdgSRgdR12rzw\x394d03hjxEk4c4g4eXUNSlQy29wz88CoAWJ5Dt+77nO21VjROJNf408TbTUXllCWr\x2bfyRseSKNTnGPc4HuTWt6VNHfeI97e3WHvNMsIYHkZhyK0hLMpGx5uUDvgfegR1n\x6aniV+LZ9C4X0K2mjtQrS3c7skSFlDEMBgDGflyScbCo/jjxHk0DRptPvJrW91OSL\x6cEbIXRSR83lsTjHb7U9nuE440+c8M6/FZR4dy8MI81W78wJyM+qjOM7msN4v4N4i\x34buzNrUErJO55Lskukvvze4wd6CLvLrzrC1zjmKyBsDA3kz0qQk1O6s+HdHa3naF\x6f3uCCpx1ZP8AtUAQdh0xT9Zofwtsk5LxwsxCAfNkjO/2oL1pnidf3UcGnaranWoB\x47yKrxh5LfIwWQ9x3KnAGPeo+/wCEYYpxeNfpf2cvxRlJMAH+Ej1HoN8VXpNQtkvV\x6c0dZ9ObHKX80nbG/TferPw9wzqGq2qX8d2l1EW5ZIm+EKfUj6b5FBY0uF0DhBpYr\x65KCe6HKkagKAg7nuc+9ZZf3MlxcNJI5csanuLeIJb2+8lHIggHlxqcbKKqjOzEkm\x675ZsjFcUE0UBXaPynbr61xRQPobpo12bfP6VfdK1NNT0W20u4ZzzQggjrzcxwc/y\x2b4rOFO9TFhdmC4tn32QDHqMmgmdRtbi6v/w6J5M6oe+OcqMkEnuQO/cY71X5DGVM\x6asQq46b5NaHeWK8V2MTRYF0mEkXPzL2c/wBDVT4n0GbhzVEW+SO6t5UPJ5b8oJx7\x64CDj6/egV4J1OLStVu9ZVjG9hbtNHz43kxyoPc85VseiGom21CS94mub6WQs8yXD\x46m6nMTj9aaPzx6cYjyr5jiRgD0ABCg/qaaIWU86jl2Iz9RQSnDehTcTcR2ulwNye\x63xLPjIjQDLMfoATW5X+raRwhwu0VvB5GjWI8uKIYEl1Md927uSMk9AAfQVXPBDTN\x50Gja9ql5OluFiWIzSOECJ1b7ZwSdugG+9c+K2h8R6zqVjY6ZoV1Lp8ERkhmQcwk5\x73FicbDBPffp7UGbajxdqeqa9c6xcTH8XKCsZViBApO6oOwwSPuasPhLZX+s8f2tu\x4ciZbUMZ7oczBXA3w2PU461P8K+C6i2XVeLb+Oxs4yWeCOQB8DszdF6e5Ht2tHA+t\x36ZecSa5JpiQQ6Ro1pzQQW8fLDjOWYZ3dsKPjbf0wOoSnEWjaHpd1ecRDT7jWNUsY\x77kMAXmWEA5+Fe5ySSeo6gbGsW1Diabjfi61/a7C108zjFrCCQqlvlG4yx6cxI+1S\x6eCni5qfD2rObsPqGnvKz8hYJImSTlW7denSrLPqvBfEfEGncS6T5VnrVrMs0lnMq\x78JdEHON/h589DkA+mdqC1cXcb6xw1q1hoHCWkG8vVgUp8DSiAN8IU4xk8qjcnG1V\x2fQuAb48YprPGt1Ff6xJG97+Cdw2MY5WfHUcxG2y7dT0qJ4n8aLlbq6h0LTzZzOeV\x37q5GZQwznlQ7LtsM7/Sq3pvFeuDR9UmSW7vdZ1VljaZsySeUu5x3xnI29KCe4w8V\x64UstXvtO0po43RzFJdjDMcHcL2ABz1zT7xu0yBOH+GNWtm547iN1DAgjdVfG3uT6\x2fWqpa+EPHOo8tw2jvEs2G555UTPMMjqc5Pp13q+3HhHxhq3CWh6Tf3NpbvZPKIxL\x4azDlPKVG223xUDXxE/A6b4LaHb28h86fyIGQ43EatzMMf58/epPg640PizwsXQJb\x70YLhLMQ3EjuEMZDnlIJOMAFdj1ye/RlxB4daa2n6Ta65x/pNqmm23kFFctzEyO5b\x50bPMR07VTpNB8PtOkZjxjfXfLti0tOUsOmAWIoLbe61wt4XaTJZaLLFqGrSdeRxK\x46cLs7t8pweijYZ7mongjipbDw/4y1S8maXUbh1xIwB5pJFcDPvsx+lU+7/3Le4YW\x591RIEGR50ihm27YVh19h96YTajYx6XNZWtvceRJOsv5k4O6qQDso/iP60DHT9Qvd\x4cvVu7C8mtbqM5WSJyrfqK0vSfHLVVsTpnE2m2utWDr5cqsgjkK9MnAwT7kVlmF5C\x521Jxj0rw5DENvQaTxLwnwvq2jw6/wnqiQC6ZwNMvGEcoZeUuqnODjmH1ztWetbTL\x4d0LxOGQ4KkYINLSsw0W0BdiollwvZdk3H1/tXcE1xKjXDOsxQchV9yo7MPof0NA8\x307SkndLdCr3DNuMHfOML/M1rWl2GnaLw9c6ZHfob+ZCZFRxsfQdqoPCGoWNtdtJI\x6a/iuUiLJyGY9PoaY6y8tjGmXInlJeQKdgOw/rQRmsQxpeSBWPXoRiodqd3V0Z/if\x64qZk5NB5RRRQFFFFB6OtOraTkfmz03ppSiZwfpQWbSuJZ9NuVmi+Jwc4/i9vpVgM\x55Wo6ff8AEl5NA1yFChpNlhPTy1U/McHY9fpWfJIybbe9SNpdozxi6VrhI91jZvgX\x50XagjppJLkk4PlqenYfX3pPGSFJ/8VoPE+lSHgnTpbUQw2afE8bYVy56HPfbO1VO\x4fKAaNNFb2ck92ZV5rn9yNP4QOxJ7mgt/hbxJbWWuQaNqMavY3heKRGOI12zzN69C\x54/0+laxxJx1Ho2kXl3NaokltItvCzMRFLE4Lxsn7zZVVJGAPfbbDbzhuXhjTtM1O\x36keO8uWLeUw5Si8p3+vSmfEupXF7K4ldnMkFkWJ78tuB/egX4q481jit/Knm8u1H\x53CMcqnvuB79v69ab6Rq02lcJazFBIUl1B4rYkHfy8Oz/AK4QVF22ntLvJLHbIRnz\x4aWwPsACT9hT23utJsFGbeTUWRuYLKxiiJwN+VfiP/wAhQcaBw3qHEd4LXT4HnkJ+\x57NeZh7+w9yRWqaX4I6bYQifizV49PiC8xzdIGO+MBRnuRvn7Vn91x7ry24srK4XT\x72YD/AArRBGoOOwH9evuahFv727ldpLqWSRhuWYknG/8Aag+gNKtvCLQtXS1NxFqN\x39KOTLhrgAAE7Fth061E33j7o1k/laDw2oXATnkxF8PTGF/1+tY3p3mQ6rDMSS2T8\x57fVT3+9RhVo5OVxgqcEUGpca+MnFZ4i1Sw0vUP2bZw3MkSC3UKxUMQCWx1wOtUU8\x5567LqkF/dareXcsUglBmnZ8kHO+T3pPU7dr7izUFB2NzKzN/CvMSTTiTSA0DXAUi\x49jKjG/LjOT9sfcgUEXep5F5NGjFogx5GB2IzsabAbZbO1SFnp82pTFYI+eSQ8kcS\x6eqfU+wAyTSExjGQFzGByhunMe7f67UCAwZF2yD1pxb2zTSfABgEnkzXsUbNb5EQK\x42xh8be/36U70NoX1MiTO4Yqc7+vTv0oGOoW4tb+SILhdiB7EZrqHT5bkkQrzHlLg\x65oAyas93pdleTQXDqVZTiUZ+deXb71GWVpFa6wbWZ2jikbCTKx+HtuO4PQ0DSJ4y\x55tp1eODvkZKE4yR7bClZ7OTS7rzIJYpvKbPwnm265I9KkNb0c2FysZbFsc+U+ebl\x378vuO9Q8kUqyArjBGxVsigcG4t5pkliBt3Jy6g7fVfT6UzubovI45iy5OM1xdCNS\x50LbJx8WOmfamrOW69aAZs1zRRQFFFFAUUUUBXoOM15g0YNB1zUtFLyEe1N8Yr0Gg\x6e1v5tRWGG5laWGI5VCdge5Nalwu+iajoKaTJHDC3MJOULgFgdm+tYrDOYyMHFSlt\x71kluC0bsJP3SD0NBZPE3UZbvWls5OVhacyhlGAQdwMeoHeqpqbmS6XoB5MIz9IlF\x4aXF3LcPmZizHqWO9c30qSzApkIERfqQoH9qBuZCxwCT6URKvnqHORnLY9K6jiaZ+\x53NMD0FLXWnz208kYQ7Ej7UHUcKXYmJkWNkXm371w0T2EkM5KuSebl/saQMM0bZKF\x53KcMGMBE4cNsY27UF803Q4LuGC9tQHWX8wDPy59R0+1VfiDS0gjivoAxSVmjkyPl\x63E7fp/TvUnwNrQt5X064kKo554WP7j4x+h9Omafa9dT2V6EtrXz7a6mWWZWXIDjY\x597DpnPfvQI23Dz3MplmUpHeSvcTP1PLk8kYHcsTkj2pfiieax0u20liJL67XnmdQ\x41EXOwHp0P19anNP1G3s7O8upLkyhW85ufoo5R8p69MfcmqbZibiniWS4u38tJiSd\x38cqDcJ9MYG1BH882maewtuZZ7mEiRh/+OE9vYtjf227mm1v5V5aTxLDy3OVaPB29\x77B7/ANqlOJYfwDNbwsGW4/MkbA+Ns7cvcAD+tNrS2OkCKWUgXEoyoG7RL3P1PTPb\x65g7tozb2MtlymWSRkZlXcgg9Pr601tbdrfUkHIWkifoP3t6XsVmW+xEXEhyAU61Y\x39Ps7HSrn8bfTB5h8Swo/Meb/ADH+1BJ2+gXNys00Vu8EDvlEkIyBvsT7VE6xb6fa\x32TRyOJbkjYr0U051HjZ7tXtsiKNxgEHoe2fWqTeXbyStzE5zvQOm1uc2f4aTDcuw\x4cb7VEvLua5kfLZzSZNB0WzXFFFAUUUUBRRRQFHaijtQejevQPb+dcivc+1AHYdK8\x723PtXmfagAcUrHMyZwcEjrSVFAoGJOevrXo+LcnlHrSYY4x2ozQLo48wsBj0HpRP\x49ZZWY7knJpENijNB2oBPvTpI3dSmNsZAporYOe4pVJiD13oHjStb6ekaBUfzeYsu\x78OOlWzTtaW7sg0nzEYdSc7+1UnzeZ0zvg5pzHfPHJzKe2KCd4gv2ureOxth8BIL8\x75wwOgpzpTfhxJJKqIQPLUAbADr+tV5dRIz03outRZvgVjgfzNA91ieCbUkuMhmTs\x64xntTP8AaHmXDu453fbmbt6fao+SUtSPNv1oJH8fLHsshx7GuZrwuoPMd9yKYc9e\x4680CrzEnrSTuW6neuc15QGaKKKAooooCiiigKKKKAooooCiiigKKKKAooooCiiig\x4bKKKAzXua8ooOg2K656TooO+c+teFzXNFB7zV5miigKKKKAooooCiiigKKKKAooo\x6fCiiig//2Q=="
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
        TweenService:Create(b, TweenInfo.new(.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(27, 27, 31), Size = UDim2.fromOffset((b:GetAttribute("NoirD") or diameter) + 6, (b:GetAttribute("NoirD") or diameter) + 6) }):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b, TweenInfo.new(.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(8, 8, 10), Size = UDim2.fromOffset(b:GetAttribute("NoirD") or diameter, b:GetAttribute("NoirD") or diameter) }):Play()
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
        local encodedArrow = "\x69VBORw0KGgoAAAANSUhEUgAAAJYAAACWCAQAAACWCLlpAAAAIGNIUk0AAHomAACA\x68AAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAD/h4/MvwAAAAd0\x53U1FB+oFCgkRIyI5lL0AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDUtMTBUMDk6\x4dTc6MzUrMDA6MDC/MZyeAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA1LTEwVDA5\x4fjE3OjM1KzAwOjAwzmwkIgAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNS0x\x4dFQwOToxNzozNSswMDowMJl5Bf0AAAlKSURBVHja7Z17jBVnGYefmbM3dpcCW26l\x79K4FiqWsAtpVRKSXpCACFaoJQQMNjRQsjYmJRo1tTWOJtQlNDaS0pFELbcVgYoxG\x326hJvZBINFYSixEr4ALSlksBAWF3z88/ztlznTlnbufM7Jx55q9zf78n7/d+35n5\x5asYQxRgk2GGGHcBIIpHlgkSWC/KyrmMBrWGHE3GU2VL6ndL6gZL6XomsrF4NSDqo\x56NjxRJnhbriSFNCS1LBKNAFgsgwDaMNM5l0VEEJTdEWSdFrtonhLyJPpdouz42B7\x4etMSLDEBgzuyva2JzrADijImYLIo92hy2AFFGROYQk/u0dSwA4oyJjC3YOZ+Q9gB\x52RkTgw/m5gcGs5K5gj0mML/gcU/YAUUZE5NZBY97k8yqgCbqkvJc0IRkUmqHyWRG\x46Tzu5OawQ4ouZllJvy3piHaYTC3qawYfCTuk6FI+Df0QzWEHFVVMppR0ux7eG3ZQ\x55cVkTNkzt4cdVFQxub7kGYMlSYm3pjyzYDEdYYcVTaxkjWNx2GFFE5O2sucMViUd\x30RJdVjn/0ejk7045pmUOTeLOsAOLIqZl8hisSzqiBTovK/6rqUk3LMXkiuXz7Xwu\x79a0y9Kas+YfakswqxuSczSszWB52cFHD5KzNKwZfTI5PF2Pyru1rH80dfE0AwOSt\x43q99LVmCVIhJf4UqfmeSW4WYnKwwRUjxiJqSoz051Ke07BnS8kRWXtYUXVUl/pqZ\x62yWyALXqaEVZaW1JZA3LMvRrVeZtTUlkQWZhyOtV3jOBrckUAgChtRVLvCQNammS\x57RlZt2pA1TissYkshFp0oqos6RkZpcu+G06ekKEfO5A1oJWNLssExGsOWt3EMw2/\x50FcIzdGgg9ySXlVrI2dWpsmtOuxIVlqPlVauhkKZqrWj6vRhuHKtbnRZ6BMOZUln\x31Nvosjp1yqEs6bAmN6as4b8xl/iF48/MYG/+hKioFfyaxpP72rs15Di3pH3l42Ij\x79WrVERey0nq2dB9qI8kytNVxkc/oelJmo8pCs/Q/F7KktB4v1xU29ZJl6OeuZElp\x66VupxpSFlrsq8pI0pG1qbkxZzTroUpaU1vcKD2mETa6XZLcgv9soad797PKw1Ohn\x66JYLNj9QczlldLKMu7iVTt7lIK/wK65WEODux4q2Dv3LdW5J0h81LZx5V8nvpXS/\x6ahWN6mkd0iqrcdtDfGUf/4KrCUSeY+qz2pdaV1nt2mMZ/aC2Wc8K/crqtF3eVo0L\x57lf/qUTBbzXphxUq687igSgYWWiDx9ySBvW0RoUma1PFuNPaaZVdfmW16nWPsqS0\x39mt6KLLG6mTV2Cx0+ZWFljrczWzNaa3Nd8c6yTK03kF/sPhH61+WqZ/4kCUN6YXh\x459PrJutFh5lfkl2uMEq27JfMtFkf75xjWmk/YAfXTXOy/uwwLttS7yAeG1mGvu65\x7aA8zqD2FS0pqKsvUIcdx2ZR677LQKP3JpyxJekeb1RKpzKqiy5ss1Je9Xps/0jqg\x3260P/Qcqa4/LqHZ62HlZQZahR313xQwD2qvZtVkrkYt1nctYvcy7KshCbfpDILIk\x36bK2q7tcWECy0BhHy1tKdTUHJwvdrDOB6ZIuaFupsMBkoQdc9wOL7PIjC63xNUEt\x356J26Ja8sABlNekl19H4m3eVBWPoqYAqV56r2qs77Idvz1u7fupfl48yIdSm3wQs\x535KGdEAb1WU/TnraOoLW5T7NJztcZeM+zDPapY+rJUBlXrOrOShZaK7O1kSXJA3p\x6bB7XB5QKSFmg2eWtgC6xvKhBUKQ1oL9pq/rUGoCyAHV5k4XW61oNdWUY0jE9r7Wa\x4atOXtMB0eZVl6Euujyt6Ia20rugv+q4+o241e5QWkC6vspCph+uiKx/8VR3RPn1V\x79zRN7TKEC3VeddkeNK562KzErck3+UbdL2IgIM0pjvIGR/g7JzjJOwyStgszSwcv\x738L1bz3HFgatXnIrC0we5pHQzuURBgKucpnznOAUFznDWc5ziWsMcI0BAFI00UwL\x593mMrqB0uZcFBl/hW5E6Mz8fpFH2rJdeIHbxYLkuL7LAYAPbLS4mFR8ss8ubLDBY\x77QsWFyqLD+I5Hsp26lyjq37Glj728Z6w21RDyrLLT6E+wCIOhN2iGmKwke2Ftdnf\x71HaMu9jtduY2gjDYyI68Lt8zJqXYzHeKLmYdLwo6o39ZYLCA7zMz7FbVjJyuICaX\x59j8LeLlgPh0vDDayDTOYzMqQYg1PMSHsltWINPexOzhZAN08zcqYXv7uOHOClQUp\x31vJELG9IIzYG/Yd4iN3M49nimW8sMPhk0Jk1/MULeYIFMeuQRwJvTk5eM2t5lJ4Y\x43btUO1kAo9nEl2MzQp6urSyA8TzEg3TFIMP2114WGEzkATYzaUQLE0/WQxaAwVg2\x73InpI1bYNfrqJStDGyvZwgJSI1DZbtbXVxaAyTw+z71cP6KE/ZOFvF1/WQAGY1jF\x66fTROiKU9bOEQyHcJrpApslN3Msaem3udxAV+lnKGxCurAxNvI97WM0cmiOp7DhL\x4dqqiICsThUkPd7OCPrrCiMqWXFYRRlgVapoBXMd8lrKI99MeAWVFqqIlKx+TwTj6\x2bBi3MTc7aoYhrkRVNGUVxtbBdOYzj7lMZ1L2fur1oUxVtGUVxziKifRyE7cwkxmM\x5aRRNgIFq0oaCsl4aSB3xfZDRAFK0cQM30k0P45nGVMbTRXt2Ib//dllkVSiy/FIk\x4fx99M6PpoIsbmcwEJjGRMXQxnm5a/KkacYKKZTnYMlcLMfVpD+e1/VuzPS+TjBou\x56pWu9rC+ukRVY8gyPKnqL1XVGLICUtUIsgLpgI0gy1sHtFEVd1mBqhrhsirKC6Cs\x785oiWff4L+uxpqChs3XOfweMNQXnFb0SRK2KNblmftjBbUsclPVKxOV+OgarSbn6\x78HHrPQuxJjcOvuanrDdWZsF4F+/tt9q1V50ondvlD+e12fP+qvhk1lsO39fvvVbF\x529bvHeWWD1UxIFeae6vc1NKmrDcUBf8LfxT0vCp2FDR8WsUrlcZxf5UPWWihTtuo\x4fhrL/VW+ZKE5OlB2Aau0XrW7pniDycpjZNS1ap1+qysakjSki/qlPlV4WQu/vxAT\x4dgejBWAyjumM5hxvcrH41D4/DY6RrExzqp306KfBsZmUZiTUtgbFRlY9SnVsZNWD\x2fwNVQ1uk90AZPQAAAABJRU5ErkJggg=="
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
        dragging = input; dragStart = input.Position; startPos = win.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging == input then
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
        if input == dragging then NoirPersistence.SetPosition("\x77indow", win.Position) end
        if input == dragging then dragging = false end
    end
end)

local restore = New("\x54extButton", { Parent = gui, Name = "NoirRestoreButton", AnchorPoint = Vector2.new(1, .5), Position = NoirPersistence.GetPosition("\x72estore", UDim2.new(1, -22, .5, 0)),
    Size = UDim2.fromOffset(62, 62), BackgroundColor3 = C.panel, Text = "\x4e", TextColor3 = C.text, TextSize = 30,
    Font = Enum.Font.GothamBold, Visible = false, AutoButtonColor = false })
styleCircularButton(restore, 62)
local restoreDragging, restoreMoved, restoreStart, restorePos = false, false, nil, nil
restore.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        restoreDragging = input; restoreMoved = false; restoreStart = input.Position; restorePos = restore.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if restoreDragging == input then
        local delta = input.Position - restoreStart
        if delta.Magnitude > 7 then restoreMoved = true end
        local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local x = math.clamp(restorePos.X.Offset * scale.Scale + delta.X, 34, view.X - 34)
        local y = math.clamp(restorePos.Y.Scale * view.Y + restorePos.Y.Offset * scale.Scale + delta.Y, 34, view.Y - 34)
        restore.Position = UDim2.fromOffset(x / scale.Scale, y / scale.Scale)
    end
end)
UIS.InputEnded:Connect(function(input)
    if restoreDragging == input then
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
        local isVisual = name == "\x56isuals" or name == "\x4fbject ESP" or string.find(name, "\x56ISUAL", 1, true) == 1
        local isMain = string.sub(name, 1, 5) == "\x4dAIN "
        local function hasTag(p) return string.find(name, p, 1, true) ~= nil end
        local isFling = hasTag("\x46ling") or hasTag("⚡") or hasTag("🤖") or hasTag("📋") or hasTag("⚙") or hasTag("🔘") or hasTag("🔑")
        local isWorld = string.sub(name, 1, 6) == "\x57ORLD " or name == "\x42omb Jump+" or name == "\x47old Bomb Jump+" or isFling
        local isEmotes = string.sub(name, 1, 7) == "\x45MOTES " or name == "\x46E Animations" or name == "\x41bout"
        local isGameEmotes = isEmotes and string.find(name, "\x47AME EMOTES", 1, true) ~= nil
        local isMisc = string.sub(name, 1, 5) == "\x4dISC " or name == "\x49nventory Unlimiter V5" or name == "\x50m-WallHop"
        local isTroll = string.sub(name, 1, 6) == "\x54ROLL " or name == "\x42ackshots"
        local isMap = string.sub(name, 1, 4) == "\x4dAP "
        local isFarm = string.sub(name, 1, 5) == "\x46ARM "
        local col, page = nil, "\x61im"
        if isVisual then visualSectionCount += 1; col = visualCols[(visualSectionCount - 1) % 2 + 1]; page = "\x76isual"
        elseif isMain then mainSectionCount += 1; col = mainCols[(mainSectionCount - 1) % 2 + 1]; page = "\x6dain"
        elseif isWorld then worldSectionCount += 1; col = worldCols[(worldSectionCount - 1) % 2 + 1]; page = "\x77orld"
        elseif isGameEmotes then col = emotesGameCol or emotesCols[1]; page = "\x65motes"
        elseif isEmotes then emotesSectionCount += 1; col = emotesCols[(emotesSectionCount - 1) % 2 + 1]; page = "\x65motes"
        elseif isMisc then miscSectionCount += 1; col = miscCols[(miscSectionCount - 1) % 2 + 1]; page = "\x6disc"
        elseif isTroll then trollSectionCount += 1; col = trollCols[(trollSectionCount - 1) % 2 + 1]; page = "\x74roll"
        elseif isMap then mapSectionCount += 1; col = mapCols[(mapSectionCount - 1) % 2 + 1]; page = "\x6dap"
        elseif isFarm then farmSectionCount += 1; col = farmCols[(farmSectionCount - 1) % 2 + 1]; page = "\x66arm"
        if not col then
            sectionCount += 1
            col = cols[(sectionCount - 1) % 2 + 1]
            page = "\x61im"
            warn("[Noir] section panel fallback: " .. tostring(name))
        end
        else sectionCount += 1; col = cols[(sectionCount - 1) % 2 + 1] end
        local panel = New("\x46rame", { Parent = col, Size = UDim2.new(1, 0, 0, 90), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = C.panel, BackgroundTransparency = .86, ClipsDescendants = true })
        corner(panel, 10); stroke(panel, C.border, .15)
        local tick = New("\x46rame", { Parent = panel, Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.border, BorderSizePixel = 0 })
        table.insert(sectionPanels, { panel = panel, page = page, name = string.lower(name .. "\x20" .. (description or "")) })
        local shownName = name:gsub("\x5eMAIN • ", ""):gsub("\x5eWORLD • ", ""):gsub("\x5eVISUAL • ", ""):gsub("\x5eEMOTES • ", ""):gsub("\x5eMISC • ", ""):gsub("\x5eTROLL • ", ""):gsub("\x5eMAP • ", ""):gsub("\x5eFARM • ", "")
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
                    drag = i; set(min + (max - min) * math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if drag == i then
                    set(min + (max - min) * math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i == drag then drag = false end
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


NoirGenv().__NoirCore = {
    host = host, gui = gui, win = win, winScale = winScale, C = C,
    New = New, corner = corner, stroke = stroke, ringStroke = ringStroke,
    styleCircularButton = styleCircularButton, topButton = topButton,
    NoirPersistence = NoirPersistence, selectPage = selectPage,
    TweenService = TweenService,
}
end
__noirW1b()
end
__noirW1a()

local __noirCore = NoirGenv().__NoirCore or {}
local host = __noirCore.host
local gui = __noirCore.gui
local win = __noirCore.win
local winScale = __noirCore.winScale
local C = __noirCore.C
local New = __noirCore.New
local styleCircularButton = __noirCore.styleCircularButton
local corner = __noirCore.corner
local stroke = __noirCore.stroke

-- ============================================================
-- BLADE BALL content tab -> Noir host UI ;; bound to stage_6 engine
-- ============================================================
do
    local genv = (typeof(getgenv) == "function" and getgenv()) or _G
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")

    local function prop(k) return System.__properties[k] end
    local function setProp(k, v) pcall(function() System.__properties[k] = v end) end
    local function gget(k, d)
        local ok, v = pcall(function() return genv[k] end)
        if ok and v ~= nil then return v end
        return d
    end
    local function startStop(obj, on)
        pcall(function() if on then obj.start() else obj.stop() end end)
    end
    local Notify = function(msg, dur) pcall(function() host.Notify(msg, dur or 2.5) end) end

    local tab = host.CreateTab()

    -- ============ MAIN • AUTO PARRY ============
    local sMain = tab:AddSection("AUTO PARRY", "core combat automation")
    sMain:AddToggle("Enabled", function(on)
        setProp("__autoparry_enabled", on)
        if not on then setProp("__play_animation", false) end
        startStop(System.autoparry, on)
        Notify(on and "Auto Parry enabled" or "Auto Parry disabled")
    end)
    sMain:AddDropdown("Parry Mode", { "Remote", "Keypress" }, function(v) genv.AutoParryMode = v end)
    sMain:AddSlider("Accuracy", 1, 100, 50, function(v)
        setProp("__accuracy", tonumber(v) or 50)
        pcall(function() if Update_Divisor then Update_Divisor() end end)
    end)
    sMain:AddDropdown("Parry Type", CURVE_NAMES, function(v)
        Selected_Parry_Type = v
        CurveType = v
    end)
    sMain:AddToggle("Random Accuracy", function(on)
        setProp("__randomized_accuracy_enabled", on)
        pcall(function() if update_randomized_accuracy then update_randomized_accuracy() end end)
    end)
    sMain:AddToggle("Random Curve", function(on)
        local c = prop("__connections")
        if on then
            if c.__random_curve then c.__random_curve:Disconnect() end
            c.__random_curve = RunService.PreSimulation:Connect(function()
                if c.__random_curve == nil then return end
                if prop("__autoparry_enabled") and (tonumber(prop("__parries")) or 0) > 0 then
                    CurveType = CURVE_NAMES[math.random(1, #CURVE_NAMES)]
                    Selected_Parry_Type = CurveType
                end
            end)
        else
            if c.__random_curve then c.__random_curve:Disconnect() c.__random_curve = nil end
        end
    end)
    sMain:AddToggle("Auto Ability", function(on) genv.AutoAbility = on end)

    -- ============ MAIN • DETECTION ============
    local sDet = tab:AddSection("DETECTION", "special ball events")
    local detKeys = { { "Infinity Detection", "__infinity" }, { "Death Slash Detection", "__deathslash" },
        { "Time Hole Detection", "__timehole" }, { "Slashes Of Fury", "__slashesoffury" }, { "Phantom Detection", "__phantom" } }
    for _, dk in ipairs(detKeys) do
        sDet:AddToggle(dk[1], function(on) pcall(function() System.__config.__detections[dk[2]] = on end) end)
    end

    -- ============ MAIN • SPAM / TRIGGER ============
    local sSpam = tab:AddSection("SPAM / TRIGGER", "press patterns")
    sSpam:AddToggle("Triggerbot", function(on)
        pcall(function() System.triggerbot.enable(on) end)
        System.__triggerbot.__enabled = on
    end)
    sSpam:AddDropdown("Auto Spam Mode", { "Remote", "Keypress" }, function(v) genv.AutoSpamMode = v end)
    sSpam:AddToggle("Auto Spam", function(on)
        setProp("__auto_spam_enabled", on)
        startStop(System.auto_spam, on)
    end)
    sSpam:AddDropdown("Manual Spam Mode", { "Remote", "Keypress" }, function(v) genv.ManualSpamMode = v end)
    sSpam:AddToggle("Manual Spam", function(on)
        setProp("__manual_spam_enabled", on)
        startStop(System.manual_spam, on)
        Notify(on and "Manual Spam enabled" or "Manual Spam disabled")
    end)
    sSpam:AddParagraph("Triggerbot", "Автоматически жмёт блок в тот момент, когда мяч уже нацелен и летит в тебя — реакция срабатывает по триггеру, без постоянного авто-парри. Полезен как «подстраховка» рядом с Auto Parry.")
    sSpam:AddLabel("Manual Spam/Auto Spam: жмут блок серией — выбери режим Remote/Keypress ниже.")

    -- ============ MAIN • SKIN CHANGER (ported stage_3 impl: EquipSwordTo + controller sync) ============
    local sSkin = tab:AddSection("SKIN CHANGER", "real sword swap - model + animations + FX")
    genv.swordModel = type(genv.swordModel) == "string" and genv.swordModel or ""
    genv.swordAnimations = type(genv.swordAnimations) == "string" and genv.swordAnimations or ""
    genv.swordFX = type(genv.swordFX) == "string" and genv.swordFX or ""

    task.spawn(function()
        local rs = game:GetService("ReplicatedStorage")
        local swordInstances, swordsController = nil, nil
        pcall(function()
            local mod = rs:WaitForChild("Shared", 10)
            mod = mod and mod:WaitForChild("ReplicatedInstances", 10)
            mod = mod and mod:WaitForChild("Swords", 10)
            if mod then swordInstances = require(mod) end
        end)
        if not swordInstances then return end
        pcall(function()
            local ok, conns = pcall(getconnections, rs.Remotes.ParrySuccessAll.OnClientEvent)
            if ok and conns then
                for _, v in ipairs(conns) do
                    if v.Function and islclosure and islclosure(v.Function) then
                        local ok2, up = pcall(getupvalues, v.Function)
                        if ok2 and #up == 1 and type(up[1]) == "table" then
                            swordsController = up[1]
                            break
                        end
                    end
                end
            end
        end)
        local function setSword()
            if not genv.skinChanger then return end
            if not LocalPlayer.Character then return end
            pcall(function()
                local f = rawget(swordInstances, "EquipSwordTo")
                if type(f) == "function" then
                    local ups = getupvalues(f)
                    for i = 1, #ups do
                        if type(ups[i]) == "boolean" then
                            setupvalue(f, i, false)
                            break
                        end
                    end
                end
            end)
            pcall(function()
                swordInstances:EquipSwordTo(LocalPlayer.Character, genv.swordModel)
            end)
            task.spawn(function()
                local attempts = 0
                while not swordsController and attempts < 20 do
                    task.wait(0.5) attempts = attempts + 1
                end
                if not swordsController then return end
                pcall(function()
                    if swordsController.SetSword then
                        swordsController:SetSword(genv.swordAnimations ~= "" and genv.swordAnimations or genv.swordModel)
                    end
                end)
                pcall(function()
                    local targetSword = genv.swordFX ~= "" and genv.swordFX or genv.swordModel
                    if rs.Remotes:FindFirstChild("FireSwordInfo") then
                        rs.Remotes.FireSwordInfo:FireServer(targetSword)
                    end
                    if swordsController.currentSword ~= nil then
                        pcall(function() swordsController.currentSword = targetSword end)
                    end
                    if swordsController.SwordFX ~= nil then
                        pcall(function() swordsController.SwordFX = targetSword end)
                    end
                end)
            end)
        end
        getgenv()._ZX_SetSword = setSword
        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            if genv.skinChanger and genv.swordModel ~= "" then setSword() end
            task.wait(1.5)
            if genv.skinChanger and genv.swordModel ~= "" then setSword() end
        end)
        task.spawn(function()
            while true do
                task.wait(2.5)
                if genv.skinChanger and genv.swordModel ~= "" and genv._ZX_SetSword then
                    local cur = nil
                    pcall(function()
                        cur = LocalPlayer.Character and (LocalPlayer.Character:GetAttribute("CurrentlyEquippedSword")
                            or LocalPlayer.Character:GetAttribute("CurrentlyEquippedSwordName")
                            or LocalPlayer:GetAttribute("CurrentlyEquippedSword"))
                    end)
                    if LocalPlayer.Character and cur and cur ~= genv.swordModel then
                        pcall(function() genv._ZX_SetSword() end)
                    end
                end
            end
        end)
    end)

    sSkin:AddToggle("Skin Changer", function(on)
        genv.skinChanger = on
        if on and genv.swordModel ~= "" and genv._ZX_SetSword then genv._ZX_SetSword() end
        Notify(on and "Skin Changer enabled" or "Skin Changer disabled")
    end)
    sSkin:AddTextBox("Sword Model Name", function(value)
        value = tostring(value or "")
        if value == "" then return end
        genv.swordModel = value
        genv.swordAnimations = value
        genv.swordFX = value
        if genv.skinChanger and genv._ZX_SetSword then genv._ZX_SetSword() end
    end)
    sSkin:AddLabel("Type exact sword name (e.g. 'Awakened Clockwork Sword'). Re-applies after respawn.")
    sSkin:AddToggle("Explosion Changer", function(on)
        genv.explosionChanger = on
        if on and genv.explosionFX and genv.explosionFX ~= "" and genv.updateExplosion then task.spawn(genv.updateExplosion) end
    end)
    sSkin:AddTextBox("Explosion Name", function(value)
        value = tostring(value or "")
        if value == "" then return end
        genv.explosionFX = value
        genv.explosionChanger = true
        if genv.updateExplosion then task.spawn(genv.updateExplosion) end
    end)

    -- ============ floating screen buttons (same round style) ============
    local screenButtons = {}
    local function makeFloatButton(name, text, yOff, get, set)
        local b = New("TextButton", { Parent = gui, Name = name, AnchorPoint = Vector2.new(1, .5),
            Position = UDim2.new(1, -20, .5, yOff), Size = UDim2.fromOffset(56, 56),
            Text = text, TextColor3 = C.text, TextSize = 22, Font = Enum.Font.GothamBold, Visible = false })
        b:SetAttribute("NoirD", 56)
        styleCircularButton(b, 56)
        local stateRing = New("UIStroke", { Parent = b, Color = C.accent, Transparency = 1, Thickness = 3,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
        local function paint(anim)
            local on = get() and true or false
            local ringGoal = on and 0 or 1
            local textGoal = on and C.accent2 or C.text
            if anim then
                TweenService:Create(stateRing, TweenInfo.new(.25), { Transparency = ringGoal }):Play()
                TweenService:Create(b, TweenInfo.new(.25), { TextColor3 = textGoal }):Play()
            else
                stateRing.Transparency = ringGoal
                b.TextColor3 = textGoal
            end
        end
        local dragging, moved, dStart, dPos = nil, false, nil, nil
        b.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = i moved = false dStart = i.Position dPos = b.Position
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if i == dragging then
                local d = i.Position - dStart
                if d.Magnitude > 7 then moved = true end
                b.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset + d.X, dPos.Y.Scale, dPos.Y.Offset + d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i == dragging then dragging = nil end
        end)
        b.MouseButton1Click:Connect(function()
            if moved then moved = false return end
            local on = not (get() and true or false)
            pcall(function() set(on) end)
            paint(true)
        end)
        paint(false)
        return { button = b, paint = paint }
    end

    local trigBtn = makeFloatButton("NoirTriggerButton", "T", -40,
        function() return System.__triggerbot.__enabled == true end,
        function(on)
            pcall(function() System.triggerbot.enable(on) end)
            System.__triggerbot.__enabled = on
        end)
    local spamBtn = makeFloatButton("NoirSpamButton", "S", 30,
        function() return prop("__manual_spam_enabled") == true end,
        function(on)
            setProp("__manual_spam_enabled", on)
            startStop(System.manual_spam, on)
            Notify(on and "Manual Spam enabled" or "Manual Spam disabled")
        end)

    -- ============ MISC • SCREEN BUTTONS ============
    local sBtn = tab:AddSection("SCREEN BUTTONS", "floating on-screen quick buttons")
    sBtn:AddToggle("Trigger Button", function(on)
        trigBtn.button.Visible = on
        if on then trigBtn.paint(false) end
    end)
    sBtn:AddSlider("Trigger Button Size", 40, 90, 56, function(v)
        local px = math.floor(tonumber(v) or 56)
        trigBtn.button:SetAttribute("NoirD", px)
        trigBtn.button.Size = UDim2.fromOffset(px, px)
    end)
    sBtn:AddToggle("Spam Button", function(on)
        spamBtn.button.Visible = on
        if on then spamBtn.paint(false) end
    end)
    sBtn:AddSlider("Spam Button Size", 40, 90, 56, function(v)
        local px = math.floor(tonumber(v) or 56)
        spamBtn.button:SetAttribute("NoirD", px)
        spamBtn.button.Size = UDim2.fromOffset(px, px)
    end)
    sBtn:AddLabel("Round buttons: tap to toggle, drag to move.")

    -- ============ MISC • STATUS ============
    local sStat = tab:AddSection("STATUS", "live telemetry")
    local labCapture = sStat:AddLabel("Capture: —")
    local labAP = sStat:AddLabel("Auto Parry: —")
    local labParries = sStat:AddLabel("Active Parries: —")
    local labPing = sStat:AddLabel("Ping: —")
    local labSpeed = sStat:AddLabel("Ball Speed: —")
    local labTarget = sStat:AddLabel("Targeted At Me: —")
    task.spawn(function()
        while true do
            task.wait(1)
            pcall(function() labCapture:SetValue("Capture: " .. ((_capturedRemote and _capturedRemote.Name) or "press block once")) end)
            pcall(function() labAP:SetValue("Auto Parry: " .. (prop("__autoparry_enabled") and "ON" or "off")) end)
            pcall(function() labParries:SetValue("Active Parries: " .. tostring(prop("__parries"))) end)
            pcall(function()
                local p = LocalPlayer:GetNetworkPing() * 1000
                labPing:SetValue("Ping: " .. tostring(math.floor(p + .5)) .. "ms")
            end)
            pcall(function()
                local b = System.ball.get()
                local s = "no ball"
                if b then
                    local z = b:FindFirstChild("zoomies")
                    if z then s = string.format("%.1f studs/s", z.AssemblyLinearVelocity.Magnitude) end
                end
                labSpeed:SetValue("Ball Speed: " .. s)
            end)
            pcall(function()
                local b = System.ball.get()
                local s = "n/a"
                if b then s = (b:GetAttribute("target") == LocalPlayer.Name) and "YES" or "no" end
                labTarget:SetValue("Targeted At Me: " .. s)
            end)
        end
    end)

    -- ============ hide empty sidebar pages ============
    do
        local keep = { Home = true, Main = true, Combat = true, Misc = true }
        local sidebar
        for _, ch in ipairs(win:GetChildren()) do
            if ch:IsA("Frame") and ch.Size == UDim2.new(0, 78, 1, 0) then sidebar = ch break end
        end
        if sidebar then
            local visible = {}
            for _, b in ipairs(sidebar:GetChildren()) do
                if b:IsA("TextButton") and b.Name ~= "" then
                    if keep[b.Name] then
                        table.insert(visible, b)
                    else
                        b.Visible = false
                    end
                end
            end
            table.sort(visible, function(a, b) return a.Position.Y.Offset < b.Position.Y.Offset end)
            for i, b in ipairs(visible) do
                b.Position = UDim2.fromOffset(19, 104 + (i - 1) * 42)
            end
        end
    end

    -- ============ open animation (like hub build) ============
    win.Visible = true
    winScale.Scale = .68
    TweenService:Create(winScale, TweenInfo.new(.62, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

    genv.NoirS6 = { gui = gui, host = host }
end


-- ============================================================
-- stage_3 module adapter -> Noir host API (all ported sections land on MAIN page)
-- ============================================================
local function __noirFeatures()
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local Lighting = game:GetService("Lighting")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local SoundService = game:GetService("SoundService")
    local Stats = game:GetService("Stats")
    local CoreGui = game:GetService("CoreGui")
    local HttpService = game:GetService("HttpService")
    local TweenService = game:GetService("TweenService")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local Player = LocalPlayer

    local Library = { _config = { _flags = {} } }
    function Library.SendNotification(self, t)
        if type(t) == "table" then
            pcall(function() host.Notify(t.text or t.title or "", t.duration or 3) end)
        else
            pcall(function() host.Notify(tostring(t), 3) end)
        end
    end
    function Library.send_notification(self, a, b) Library:SendNotification({ text = a, duration = b }) end
    _G.Library = _G.Library or Library
    Library = _G.Library
    Library._config = Library._config or { _flags = {} }
    Library._config._flags = Library._config._flags or {}

    local function makeModule(sec, title, moduleCallback)
        local m = {}
        if moduleCallback then
            sec:AddToggle("Enable " .. tostring(title), function(state) pcall(moduleCallback, state == true) end)
        end
        local function cb(fn) return function(...) if fn then local ok, err = pcall(fn, ...) if not ok then warn("[Noir module] " .. tostring(err)) end end end end
        function m:create_toggle(c) sec:AddToggle((c or {}).title or "Toggle", cb((c or {}).callback)) return m end
        function m:create_checkbox(c) return self:create_toggle(c) end
        function m:create_slider(c)
            c = c or {}
            sec:AddSlider(c.title or "Slider", tonumber(c.minimum_value) or 0, tonumber(c.maximum_value) or 100,
                tonumber(c.value) or 0, cb(c.callback))
            return { set_percentage = function() end, SetValue = function() end }
        end
        function m:create_textbox(c) sec:AddTextBox((c or {}).title or "Input", cb((c or {}).callback)) return m end
        function m:create_dropdown(c)
            c = c or {}
            local ctl = sec:AddDropdown(c.title or "Dropdown", c.options or c.values or {}, cb(c.callback))
            local wrapper = { _ctl = ctl }
            function wrapper:set_options(opts) pcall(function() self._ctl:ChangeItems(opts) end) end
            function wrapper:update() end
            function wrapper:SetValue(v) pcall(function() self._ctl:SetValue(v) end) end
            return wrapper
        end
        function m:create_button(c) sec:AddButton((c or {}).title or "Run", cb((c or {}).callback)) return m end
        function m:create_label(txt) sec:AddLabel(tostring(txt)) return m end
        function m:create_divider() sec:AddLabel("--------------------") return m end
        function m:create_keybind(c) sec:AddKeybind((c or {}).title or "Keybind", (c or {}).default or "X", cb((c or {}).callback)) return m end
        function m:set_state() end
        return m
    end

    local function makeTab()
        local T = {}
        function T:create_module(cfg)
            cfg = cfg or {}
            local title = "MAIN \226\128\162 " .. string.upper(tostring(cfg.title or "MODULE"))
            local ok, sec = pcall(function() return host.CreateTab():AddSection(title, cfg.description or "") end)
            if not ok then sec = host.CreateTab():AddSection("MAIN \226\128\162 MODULE", cfg.description or "") end
            return makeModule(sec, cfg.title, cfg.callback)
        end
        return T
    end

    local VisualsTab = makeTab()
    local PlayerTab = makeTab()
    local BlatantTab = makeTab()
    local MiscTab = makeTab()
    local UnlockTab = makeTab()
    local WorldTab = makeTab()
    local DetectionTab = makeTab()
    local GuiTab = makeTab()

-- ================= ported sectors ==================

-- ==== sector: unlock helper (17666-17761) ====
local function runUnlockAll()
if (({[1]=false})[1]) then local _z=tostring(0) end
    if (({})~=nil) and (not __initUnlockAllBackend()) then return end
    if type(__unlockAllEnable) == "function" then
        pcall(__unlockAllEnable, nil)
    end
end

getgenv().__runUnlockAll = runUnlockAll

local ThemeState = {
    AccentHue = (5*43),
    Transparency = 0,
    CornerRadius = (2*6)
}

local function getThemeColor()
    return Color3.fromHSV((ThemeState.AccentHue % (2*180)) / (2*180), 0.62, 0.92)
end

local function applyTheme()
    local root = library._ui
    if not root then return end
if (#"">2) then local _q={} _q[1]=2 end

    local accent = getThemeColor()
    local transparency = math.clamp(ThemeState.Transparency / (79+21), 0, 0.9)
    local radius = math.clamp(ThemeState.CornerRadius, 0, (54-30))

    local container = root:FindFirstChild("Container")
    if (1<2) and (container) then
        container.BackgroundTransparency = transparency
        local containerCorner = container:FindFirstChildOfClass('UICorner')
        if containerCorner then
            containerCorner.CornerRadius = UDim.new(0, radius)
        end
        local containerStroke = container:FindFirstChildOfClass('UIStroke')
        if containerStroke then
            containerStroke.Color = accent
        end
if (#"">2) then local _n=math.floor(3.14) end
        local side = container:FindFirstChild("GradientSide", true)
        if (math.floor(1.5)==1) and (side) then
            local gradient = side:FindFirstChildOfClass('UIGradient')
            if gradient then
                gradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(bit32.bxor(31,1), (101-71), (17+17))),
                    ColorSequenceKeypoint.new(0.5, accent),
                    ColorSequenceKeypoint.new(1, accent:Lerp(Color3.fromRGB((189-19), (2*45), (3*85)), 0.45))
                }
            end
        end
    end

    for _, object in ipairs(root:GetDescendants()) do
        if object:IsA('UICorner') then
            local parent = object.Parent
            if (#{1}==1) and (parent and parent.Name ~= 'Circle' and parent.Name ~= 'Toggle' and parent.Name ~= 'Dot' and parent.Name ~= "AvatarClip") then
                object.CornerRadius = UDim.new(0, radius)
            end
        elseif object:IsA('TextLabel') or object:IsA('TextButton') or object:IsA('TextBox') then
            local baseSize = object:GetAttribute("ThemeBaseTextSize")
            if not baseSize then
                baseSize = object.TextSize
                object:SetAttribute("ThemeBaseTextSize", baseSize)
if (#"">2) then local _n=math.floor(3.14) end
            end
            object.TextSize = baseSize
        elseif object:IsA('Frame') and (object.Name == 'Fill' or object.Name == "RangeFill" or object.Name == "ActiveIndicator") then
            object.BackgroundColor3 = accent
        end
    end

    if library._notification_helpers and library._notification_helpers.theme then
        library._notification_helpers.theme.accent = accent
        library._notification_helpers.theme.info = accent
        library._notification_helpers.theme.radius = UDim.new(0, radius)
    end
end

local function resetThemeDefaults()
    ThemeState.AccentHue = (5*43)
    ThemeState.Transparency = 0
    ThemeState.CornerRadius = (2*6)
if ((1/1)==0) then local _q={} _q[1]=2 end

    if (1<2) and (Library._config and Library._config._flags) then
        Library._config._flags.ThemeAccentHue = ThemeState.AccentHue
        Library._config._flags.ThemeTransparency = ThemeState.Transparency
        Library._config._flags.ThemeCornerRadius = ThemeState.CornerRadius
        Config:save(game.GameId, Library._config)
    end

    applyTheme()
end


-- ==== sector: unlock_all (17828-17840) ====
local unlock_all_module = UnlockTab:create_module({
    title = "Unlock All",
    description = "Unlock all Swords, Explosions and Emotes",
    flag = "UnlockAll",
    section = "left",
    callback = function(state)
        getgenv().unlockAllEnabled = state
        if state and getgenv().__runUnlockAll then
            task.spawn(getgenv().__runUnlockAll)
        end
    end
})


-- ==== sector: stats_overlay (17851-18037) ====
local stats_overlay_module = VisualsTab:create_module({
    title = "FPS and Ping",
    description = "Show your FPS and Ping",
    flag = "StatsOverlayModule",
    section = "right",
    callback = function(state)
        if ((3*3)==9) and (state) then

            System = System or {}
            System.__properties = System.__properties or {}
            System.__properties.__connections = System.__properties.__connections or {}

            if not System.__properties.__stats_overlay then
                local OverlayGui = Instance.new('ScreenGui')
                OverlayGui.Name = "AzureStatsOverlay"
                OverlayGui.ResetOnSpawn = false
                OverlayGui.IgnoreGuiInset = true
                OverlayGui.DisplayOrder = (3*33)
                OverlayGui.Parent = CoreGui

                local Panel = Instance.new('Frame')
                Panel.Name = 'Panel'
                Panel.Size = UDim2.new(0, 146, 0, 66)
                Panel.Position = UDim2.new(0, (19+1), 0.5, -(73-30))
                Panel.BackgroundColor3 = Color3.fromRGB(10, 9, 8); Panel.BackgroundTransparency = 0.12
                Panel.BorderSizePixel = 0
                do local sk = Instance.new('UIStroke'); sk.Color = Color3.fromRGB(224,116,24); sk.Transparency = 0.3; sk.Thickness = 1; sk.Parent = Panel end
                Panel.Active = true
                Panel.Parent = OverlayGui
                Instance.new('UICorner', Panel).CornerRadius = UDim.new(0, (31-19))
                local PanelStroke = Instance.new('UIStroke', Panel)
                PanelStroke.Color = Color3.fromRGB((2*35), (2*35), (2*35))
                PanelStroke.Thickness = 1

                local TitleLabel = Instance.new('TextLabel')
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.Size = UDim2.new(1, 0, 0, (2*9))
                TitleLabel.Position = UDim2.new(0, 0, 0, 6)
                TitleLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
                TitleLabel.Text = "FPS & PING"
                TitleLabel.TextColor3 = Color3.fromRGB((79+141), (250-30), bit32.bxor(31,195))
                TitleLabel.TextSize = 9
                TitleLabel.TextColor3 = Color3.fromRGB(255, 170, 54)
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
                TitleLabel.Parent = Panel

                local ChipHolder = Instance.new('Frame')
                ChipHolder.BackgroundTransparency = 1
                ChipHolder.Position = UDim2.new(0, (5+5), 0, (45-19))
                ChipHolder.Size = UDim2.new(1, -(2*10), 0, (2*22))
                ChipHolder.Parent = Panel
                local ChipLayout = Instance.new('UIListLayout', ChipHolder)
                ChipLayout.FillDirection = Enum.FillDirection.Horizontal
                ChipLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                ChipLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                ChipLayout.Padding = UDim.new(0, 6)

                local function makeChip(tag)
                    local Chip = Instance.new('Frame')
                    Chip.Size = UDim2.new(0, (2*35), 0, (2*18))
                    Chip.BackgroundColor3 = Color3.fromRGB(15, 13, 11)
                    Chip.BorderSizePixel = 0
                    Chip.Parent = ChipHolder
                    Instance.new('UICorner', Chip).CornerRadius = UDim.new(0, (81-71))
                    local CS = Instance.new('UIStroke', Chip)
                    CS.Color = Color3.fromRGB((15+45), (79-19), (2*30))
                    CS.Thickness = 1

                    local Dot = Instance.new('Frame')
                    Dot.Name = 'Dot'
                    Dot.Size = UDim2.new(0, 4, 0, 4)
                    Dot.Position = UDim2.new(0, 6, 0, 5)
                    Dot.BackgroundColor3 = Color3.fromRGB((2*50), (2*110), (2*65))
                    Dot.BorderSizePixel = 0
                    Dot.Parent = Chip
                    Instance.new('UICorner', Dot).CornerRadius = UDim.new(1, 0)

                    local Tag = Instance.new('TextLabel')
                    Tag.BackgroundTransparency = 1
                    Tag.Size = UDim2.new(1, -8, 0, 9)
                    Tag.Position = UDim2.new(0, 4, 0, 3)
                    Tag.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    Tag.Text = tag
                    Tag.TextColor3 = Color3.fromRGB((79+101), (210-30), bit32.bxor(31,171))
                    Tag.TextSize = 8
                    Tag.TextXAlignment = Enum.TextXAlignment.Center
                    Tag.Parent = Chip

                    local Val = Instance.new('TextLabel')
                    Val.Name = 'Val'
                    Val.BackgroundTransparency = 1
                    Val.Size = UDim2.new(1, 0, 0, (87-71))
                    Val.Position = UDim2.new(0, 0, 0, (15+1))
                    Val.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
                    Val.Text = '--'
                    Val.TextColor3 = Color3.fromRGB((259-19), (2*120), (2*120))
                    Val.TextSize = (1+12)
                    Val.TextXAlignment = Enum.TextXAlignment.Center
                    Val.Parent = Chip

                    return Val, Dot
                end

                local FpsVal, FpsDot   = makeChip('FPS')
                local PingVal, PingDot = makeChip('PING')

                Panel.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local dragStart = input.Position
                        local startPos  = Panel.Position
                        local moving    = true
                        input.Changed:Connect(function()
                            if (#{1}==1) and (input.UserInputState == Enum.UserInputState.End) then moving = false end
                        end)
                        local conn
                        conn = UserInputService.InputChanged:Connect(function(inp)
                            if not moving then conn:Disconnect() return end
                            if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                                local delta = inp.Position - dragStart
                                Panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                            end
                        end)
                    end
                end)

                System.__properties.__stats_overlay = {
                    gui = OverlayGui,
                    fpsVal = FpsVal, fpsDot = FpsDot,
                    pingVal = PingVal, pingDot = PingDot,
                }
            end

            System.__properties.__stats_overlay.gui.Enabled = true

            if ((1+1)==2) and (not System.__properties.__connections.__stats_overlay) then
                local frameCount = 0
                local elapsed    = 0
                local smoothFps  = 0

                local fpsConn = RunService.RenderStepped:Connect(function(dt)
                    frameCount += 1
                    elapsed    += dt
                    if elapsed >= 0.5 then
                        smoothFps  = math.round(frameCount / elapsed)
                        frameCount = 0
                        elapsed    = 0
                    end
                end)
                System.__properties.__connections.__stats_overlay_fps = fpsConn

                System.__properties.__connections.__stats_overlay = task.spawn(function()
                    while System.__properties.__stats_overlay do
                        local o = System.__properties.__stats_overlay
                        pcall(function()
                            local fps = smoothFps
                            local fpsColor = fps >= (24+31) and Color3.fromRGB((130-30),bit32.bxor(31,195),(201-71)) or fps >= (15+15) and Color3.fromRGB((249-19),(2*100),(2*40)) or Color3.fromRGB((2*110),(2*40),(79+1))
                            o.fpsVal.Text = tostring(fps)
                            o.fpsVal.TextColor3 = fpsColor
                            o.fpsDot.BackgroundColor3 = fpsColor

                            local ping = math.round(Players.LocalPlayer:GetNetworkPing() * (1030-30))
                            local pingColor = ping <= bit32.bxor(31,79) and Color3.fromRGB((171-71),(35+185),(149-19)) or ping <= (2*75) and Color3.fromRGB((2*115),(2*100),(2*40)) or Color3.fromRGB((79+141),(110-30),bit32.bxor(31,79))
                            o.pingVal.Text = tostring(ping)
                            o.pingVal.TextColor3 = pingColor
                            o.pingDot.BackgroundColor3 = pingColor
                        end)
                        task.wait(0.5)
                    end
                end)
            end

        else
            if (math.floor(1.5)==1) and (System.__properties.__connections.__stats_overlay) then
                System.__properties.__connections.__stats_overlay = nil
            end
            if System.__properties.__connections.__stats_overlay_fps then
                pcall(function() System.__properties.__connections.__stats_overlay_fps:Disconnect() end)
                System.__properties.__connections.__stats_overlay_fps = nil
            end
            if System.__properties.__stats_overlay then
                pcall(function() System.__properties.__stats_overlay.gui:Destroy() end)
                System.__properties.__stats_overlay = nil
            end
        end
    end
})

    local infinite_jump_enabled = false


-- ==== sector: blatant_exploits (18038-18296) ====
    local blatant_exploits_module = BlatantTab:create_module({
        title = "Infinite Jump",
        description = "Character Infinite Jump",
        flag = "infinitejump",
        section = "left",
        callback = function(state)
            infinite_jump_enabled = state
            if (#{1}==1) and (state) then
                if not getgenv().InfiniteJumpConnection then
                    getgenv().InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
                        if infinite_jump_enabled then
                            local char = Players.LocalPlayer and Players.LocalPlayer.Character
                            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                            if humanoid and humanoid.Health > 0 then
                                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                            end
                        end
                    end)
                end
            else
                if getgenv().InfiniteJumpConnection then
                    getgenv().InfiniteJumpConnection:Disconnect()
                    getgenv().InfiniteJumpConnection = nil
                end
            end
        end,
    })

    local original_fog_end = Lighting.FogEnd
local original_fog_start = Lighting.FogStart
local postprocessing_backup = {}
local decals_backup = {}
local scene_backup = {}
local sound_backup = nil
local lighting_backup = nil
local fog_backup = nil
local sound_service = cloneref(game:GetService('SoundService'))
if ((1/1)==0) then for _i=1,0 do end end
local fps_boost_loop = nil
local fps_boost_enabled = false

local function apply_disable_fog(state)
    if state then
        Lighting.FogEnd = math.huge
        Lighting.FogStart = math.huge
    else
        Lighting.FogEnd = original_fog_end
        Lighting.FogStart = original_fog_start
    end
end

local function apply_disable_postprocessing(state)
    if (math.floor(1.5)==1) and (state) then
        for _, v in pairs(Lighting:GetDescendants()) do
            pcall(function()
                if v.Enabled ~= nil then
                    postprocessing_backup[v] = v.Enabled
                    v.Enabled = false
                end
            end)
        end

        fog_backup = {
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
            FogColor = Lighting.FogColor
        }

        pcall(function()
            Lighting.FogEnd = math.huge
            Lighting.FogStart = math.huge
            Lighting.FogColor = Color3.new(0, 0, 0)
        end)
    else
        for v, enabled in pairs(postprocessing_backup) do
            pcall(function()
                if v and v.Parent and v.Enabled ~= nil then
                    v.Enabled = enabled
                end
            end)
if (1<-1) then local _j=1+1 end
        end
        postprocessing_backup = {}

        if ((1+1)==2) and (fog_backup) then
            pcall(function()
                Lighting.FogEnd = fog_backup.FogEnd
                Lighting.FogStart = fog_backup.FogStart
                Lighting.FogColor = fog_backup.FogColor
            end)
            fog_backup = nil
        end
    end
end

local function apply_remove_decals(state)
    if state then
        for _, v in pairs(workspace:GetDescendants()) do
            pcall(function()
                if v:IsA("Decal") or v:IsA("Texture") then
                    decals_backup[v] = {Texture = v.Texture, Transparency = v.Transparency}
                    pcall(function() v.Texture = "" end)
                    pcall(function() v.Transparency = 1 end)
                end
            end)
        end
    else
        for v, data in pairs(decals_backup) do
            pcall(function()
                if (type("")=="string") and (v and v.Parent) then
                    if data.Texture ~= nil then pcall(function() v.Texture = data.Texture end) end
                    if data.Transparency ~= nil then pcall(function() v.Transparency = data.Transparency end) end
                end
            end)
if (({[1]=false})[1]) then local _z=tostring(0) end
        end
        decals_backup = {}
    end
end

local function is_character_object(obj)
    if ((1+1)==2) and (not obj) then
        return false
    end

    local local_character = Players.LocalPlayer and Players.LocalPlayer.Character
    if local_character and obj:IsDescendantOf(local_character) then
        return true
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character and obj:IsDescendantOf(player.Character) then
            return true
        end
    end
if (#"">2) then local _q={} _q[1]=2 end

    return false
end

local function apply_fps_boost(state)
    fps_boost_enabled = state

    if (0==0) and (fps_boost_loop) then
        fps_boost_loop:Disconnect()
        fps_boost_loop = nil
    end

    if not state then
        apply_disable_fog(false)
        apply_disable_postprocessing(false)
        apply_remove_decals(false)

        if lighting_backup then
            Lighting.Technology = lighting_backup.Technology
            Lighting.Brightness = lighting_backup.Brightness
            Lighting.ExposureCompensation = lighting_backup.ExposureCompensation
            Lighting.GlobalShadows = lighting_backup.GlobalShadows
            Lighting.OutdoorAmbient = lighting_backup.OutdoorAmbient
            Lighting.Ambient = lighting_backup.Ambient
            Lighting.ColorShift_Bottom = lighting_backup.ColorShift_Bottom
            Lighting.ColorShift_Top = lighting_backup.ColorShift_Top
            Lighting.ClockTime = lighting_backup.ClockTime
            Lighting.ShadowSoftness = lighting_backup.ShadowSoftness
            lighting_backup = nil
        end

        for obj, values in pairs(scene_backup) do
            pcall(function()
                if (({})~=nil) and (obj and obj.Parent) then
                    if values.Enabled ~= nil then
                        obj.Enabled = values.Enabled
                    end
                    if values.CastShadow ~= nil then
                        obj.CastShadow = values.CastShadow
                    end
                    if (1<2) and (values.Material ~= nil) then
                        obj.Material = values.Material
                    end
                end
            end)
if (#"">2) then local _n=math.floor(3.14) end
        end
        scene_backup = {}

        if sound_service and sound_backup ~= nil then
            sound_service.Volume = sound_backup
            sound_backup = nil
        end

        return
    end

    apply_disable_fog(true)
    apply_disable_postprocessing(true)
    apply_remove_decals(true)

    lighting_backup = {
        Technology = Lighting.Technology,
        Brightness = Lighting.Brightness,
        ExposureCompensation = Lighting.ExposureCompensation,
        GlobalShadows = Lighting.GlobalShadows,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Ambient = Lighting.Ambient,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
        ColorShift_Top = Lighting.ColorShift_Top,
        ClockTime = Lighting.ClockTime,
        ShadowSoftness = Lighting.ShadowSoftness
    }

    Lighting.Technology = Enum.Technology.Compatibility
    Lighting.Brightness = 0.18
    Lighting.ExposureCompensation = -1.2
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.fromRGB((106-71), (10+25), (54-19))
if (#"">2) then local _n=math.floor(3.14) end
    Lighting.Ambient = Color3.fromRGB((5*7), (5*7), (5*7))
    Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
    Lighting.ColorShift_Top = Color3.new(0, 0, 0)
    Lighting.ClockTime = (2*7)
    Lighting.ShadowSoftness = 0

    if sound_service and sound_backup == nil then
        sound_backup = sound_service.Volume
        sound_service.Volume = 0.03
    end

    fps_boost_loop = RunService.Heartbeat:Connect(function()
        if (math.floor(1.5)==1) and (not fps_boost_enabled) then
            return
        end

        for _, obj in pairs(workspace:GetDescendants()) do
            pcall(function()
                if is_character_object(obj) then
                    return
                end

                if obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Highlight") or obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") or obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Explosion") or obj:IsA("Weld") or obj:IsA("UIStroke") or obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("ImageLabel") then
                    local stored = scene_backup[obj]
                    if (#{1}==1) and (not stored) then
                        scene_backup[obj] = {Enabled = obj.Enabled}
                    end
                    obj.Enabled = false
                elseif obj:IsA("Part") then
                    local stored = scene_backup[obj]
                    if not stored then
                        scene_backup[obj] = {CastShadow = obj.CastShadow, Material = obj.Material}
                    end
                    obj.CastShadow = false
                    obj.Material = Enum.Material.SmoothPlastic
                elseif obj:IsA("Atmosphere") then
                    obj.Density = 0
                end
            end)
        end
    end)
end


-- ==== sector: misc_a (18297-18307) ====
MiscTab:create_module({
    title = "FPS Booster",
    description = "Lower your Graphics to improve FPS",
    flag = "FPSBooster",
    section = "right",
    callback = function(state)
        apply_fps_boost(state)
    end
})

local low_graphics_original_quality = nil

-- ==== sector: misc_b (18308-18336) ====
MiscTab:create_module({
    title = "Low Graphics",
    description = "Reduce Rendering quality and shadows",
    flag = "LowGraphics",
    section = "right",
    callback = function(state)
        if state then
            pcall(function()
                low_graphics_original_quality = settings().Rendering.QualityLevel
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
            pcall(function()
                local lighting = game:GetService("Lighting")
                lighting.GlobalShadows = false
                lighting.FogEnd = 9e9
            end)
        else
            pcall(function()
                if (1<2) and (low_graphics_original_quality) then
                    settings().Rendering.QualityLevel = low_graphics_original_quality
                end
            end)
            pcall(function()
                local lighting = game:GetService("Lighting")
                lighting.GlobalShadows = true
            end)
        end
    end
})

-- ==== sector: auto_rewards (18339-18704) ====
do
local auto_rewards_module = MiscTab:create_module({
    title = "Auto Rewards",
    description = "Auto claim daily rewards, open cases, spin wheel",
    flag = "AutoRewards",
    section = "left",
    callback = function(state)
        getgenv().AutoRewardsEnabled = state
        if state then
            local function claim_rewards()
                pcall(function()
                    local rf = ReplicatedStorage:FindFirstChild("Remote")
                    if not rf then return end
                    if getgenv().AutoRewardsDaily then
                        local rfn = rf:FindFirstChild("RemoteFunction")
                        if rfn then
                            for d = 0, 30 do
                                pcall(function()
                                    rfn:InvokeServer("ClaimNewDailyLoginReward", d)
                                end)
                            end
                        end
                    end
                    if getgenv().AutoRewardsCases then
                        local ren = rf:FindFirstChild("RemoteEvent")
                        if ren then
                            pcall(function()
                                ren:FireServer("OpeningCase", true)
                            end)
                        end
                    end
                    if getgenv().AutoRewardsSpin then
                        local rfn = rf:FindFirstChild("RemoteFunction")
                        if rfn then
                            pcall(function()
                                rfn:InvokeServer("SpinWheel")
                            end)
                        end
                    end
                end)
            end
            claim_rewards()
            if not System.__properties.__connections.__auto_rewards then
                System.__properties.__connections.__auto_rewards = LocalPlayer.CharacterAdded:Connect(function()
                    task.wait(2)
                    claim_rewards()
                end)
            end
        else
            if System.__properties.__connections.__auto_rewards then
                System.__properties.__connections.__auto_rewards:Disconnect()
                System.__properties.__connections.__auto_rewards = nil
            end
        end
    end
})

auto_rewards_module:create_checkbox({
    title = "Daily Login Rewards",
    flag = "AutoRewardsDaily",
    callback = function(value)
        getgenv().AutoRewardsDaily = value
    end
})

auto_rewards_module:create_checkbox({
    title = "Open Cases",
    flag = "AutoRewardsCases",
    callback = function(value)
        getgenv().AutoRewardsCases = value
    end
})

auto_rewards_module:create_checkbox({
    title = "Spin Wheel",
    flag = "AutoRewardsSpin",
    callback = function(value)
        getgenv().AutoRewardsSpin = value
    end
})

getgenv().AutoRewardsEnabled = false
getgenv().AutoRewardsDaily = true
getgenv().AutoRewardsCases = false
getgenv().AutoRewardsSpin = false
end

local GROUP_ID = 12836673
local MIN_RANK = (9+1)
local modActionMode = "Notification"
local modDetectionEnabled = false
local detectedMods = {}
local modMonitorConnection = nil

local function getPlayerRank(player)
    local success, rank = pcall(function()
        return player:GetRankInGroup(GROUP_ID)
    end)

    return success and rank or 0
end

local function showModNotification(player)
    local notif = Instance.new("ScreenGui")
    notif.Name = "ModNotification"
if (type({})~="table") then local _t=table.concat({},"") end
    notif.ResetOnSpawn = false
    notif.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, (380-30), 0, bit32.bxor(31,35))
    frame.Position = UDim2.new(0.5, -(246-71), 0.2, 0)
    frame.BackgroundColor3 = Color3.fromRGB((55+145), (69-19), (2*25))
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Parent = notif

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = "! Staff Joined! " .. player.Name .. " (Support+)"
    text.TextColor3 = Color3.fromRGB((3*85), (3*85), (3*85))
    text.TextSize = (7+11)
if ((1/1)==0) then for _i=1,0 do end end
    text.Font = Enum.Font.GothamBold
    text.Parent = frame

    task.delay(5, function()
        if notif and notif.Parent then
            notif:Destroy()
        end
    end)
end

local function kickSelf()
    Player:Kick("The mod has joined the server! Kicked to avoid ban.")
end

local function checkModPlayers()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and not detectedMods[plr.UserId] then
            local rank = getPlayerRank(plr)
            if ((3*3)==9) and (rank >= MIN_RANK) then
                detectedMods[plr.UserId] = true
                if modActionMode == "Notification" then
                    showModNotification(plr)
                elseif modActionMode == "Kick" then
                    kickSelf()
                end
if (1<-1) then local _j=1+1 end
            end
        end
    end
end

local ReplicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local Stats = cloneref(game:GetService('Stats'))
getgenv()._ZX_PingCache = 50
task.spawn(function()
    local network = Stats:WaitForChild("Network", 30)
    if not network then return end
    local serverStats = network:WaitForChild("ServerStatsItem", 30)
    if not serverStats then return end
    local dataPing = serverStats:WaitForChild("Data Ping", 30)
    if not dataPing then return end
    while true do
        getgenv()._ZX_PingCache = dataPing:GetValue()
        task.wait(0.5)
    end
end)

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer and LocalPlayer:GetMouse()

if not LocalPlayer or not LocalPlayer.Character then
    if (#{1}==1) and (LocalPlayer) then LocalPlayer.CharacterAdded:Wait() end
end
if (({[1]=false})[1]) then local _z=tostring(0) end

local Connections_Manager = getgenv().Connections_Manager or {}
getgenv().Connections_Manager = Connections_Manager

local Player = Players.LocalPlayer

local function get_real_ball()
    local balls = workspace:FindFirstChild('Balls')
    if not balls then
        return nil
    end

    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute("realBall") then
            ball.CanCollide = false
            return ball
        end
    end

    return nil
end

local AutoPlayState = {
    connection = nil,
    character_connection = nil,
    elapsed = 0,
    control_point = nil,
    last_generation = 0,
    double_jumped = false,
    ball = nil,
    enabled = false
}

local function auto_play_percentage_check(limit)
if (#"">2) then local _q={} _q[1]=2 end
    if ((1+1)==2) and (tick() - AutoPlayState.last_generation < (getgenv().AutoPlayGenerationThreshold or 0.25)) then
        return false
    end

    AutoPlayState.last_generation = tick()
    return math.random((130-30)) <= limit
end

local function auto_play_get_floor()
    local floor = workspace:FindFirstChild('FLOOR')
    if floor then
        return floor
    end

    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA('BasePart') and part.Size.X > bit32.bxor(31,45) and part.Size.Z > (121-71) and part.Position.Y < 5 then
            return part
        end
    end

    return nil
end
if (#"">2) then local _n=math.floor(3.14) end

local function auto_play_get_curve(startPosition, finishPosition, delta)
    AutoPlayState.elapsed = AutoPlayState.elapsed + delta
    local timeElapsed = math.clamp(AutoPlayState.elapsed / (getgenv().AutoPlayMovementDuration or 0.8), 0, 1)

    if (math.floor(1.5)==1) and (timeElapsed >= 1) then
        AutoPlayState.elapsed = 0
        AutoPlayState.control_point = nil
        return finishPosition
    end

    if not AutoPlayState.control_point then
        local middle = (startPosition + finishPosition) * 0.5
        local difference = startPosition - finishPosition
        if difference.Magnitude < 5 then
            return finishPosition
        end

        local theta = math.atan2(difference.Z, difference.X)
        local offsetLength = difference.Magnitude * (getgenv().AutoPlayOffsetFactor or 0.7)
        local firstCandidate = middle + Vector3.new(math.cos(theta + math.pi / 2), 0, math.sin(theta + math.pi / 2)) * offsetLength
        local secondCandidate = middle + Vector3.new(math.cos(theta - math.pi / 2), 0, math.sin(theta - math.pi / 2)) * offsetLength
        local dotValue = startPosition - middle
        AutoPlayState.control_point = ((firstCandidate - middle):Dot(dotValue) < 0 and firstCandidate) or secondCandidate
    end

    local firstLerp = startPosition + (AutoPlayState.control_point - startPosition) * timeElapsed
    local secondLerp = AutoPlayState.control_point + (finishPosition - AutoPlayState.control_point) * timeElapsed
    return firstLerp + (secondLerp - firstLerp) * timeElapsed
end

local function auto_play_get_target_position()
if (#"">2) then local _n=math.floor(3.14) end
    local floor = auto_play_get_floor()
    local ball = get_real_ball() or AutoPlayState.ball
    local character = Player.Character
    local hrp = character and character:FindFirstChild('HumanoidRootPart')

    if not floor or not ball or not hrp then
        return nil
    end

    AutoPlayState.ball = ball
    local direction = (hrp.Position - ball.Position).Unit
    local speed = 0
    local success, speed_value = pcall(function()
        if ball and ball:FindFirstChild("zoomies") and ball.zoomies and ball.zoomies.VectorVelocity then
            return ball.zoomies.VectorVelocity.Magnitude
        end
        return 0
    end)
    if success then
        speed = speed_value or 0
    end
    local speedThreshold = math.min(speed / (5+5), getgenv().AutoPlayMultiplierThreshold or (89-19))
    local distance = (getgenv().AutoPlayDistance or (2*15)) + speedThreshold
    local offset = direction * distance * (getgenv().AutoPlayDirection or 1)
    local currentTime = os.time() / 1.2
    local sine = math.sin(currentTime) * (getgenv().AutoPlayTransversing or (5*5))
    local cosine = math.cos(currentTime) * (getgenv().AutoPlayTransversing or (5*5))
if ((1/1)==0) then local _q={} _q[1]=2 end
    local traversing = Vector3.new(sine, 0, cosine)

    return floor.Position + offset + traversing
end

local function auto_play_step()
    if (#{1}==1) and (not AutoPlayState.enabled) then
        return
    end

    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    local hrp = character and character:FindFirstChild('HumanoidRootPart')

    if not humanoid or not hrp or humanoid.Health <= 0 then
        return
    end

    if humanoid.FloorMaterial ~= Enum.Material.Air then
        AutoPlayState.double_jumped = false
    end

    local targetPosition = auto_play_get_target_position()
if (type({})~="table") then local _t=table.concat({},"") end
    if (#{1}==1) and (targetPosition) then
        local path = auto_play_get_curve(hrp.Position, targetPosition, 0.016)
        humanoid:MoveTo(path)
    end

    if getgenv().AutoPlayJumpingEnabled and auto_play_percentage_check(getgenv().AutoPlayJumpPercentage or (2*25)) then
        if humanoid.FloorMaterial ~= Enum.Material.Air then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        elseif not AutoPlayState.double_jumped and auto_play_percentage_check(getgenv().AutoPlayDoubleJumpPercentage or (29+21)) then
            local bodyVelocity = Instance.new('BodyVelocity')
            bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bodyVelocity.Velocity = Vector3.new(0, (110-30), 0)
            bodyVelocity.Parent = hrp
            Debris:AddItem(bodyVelocity, 0.1)
            AutoPlayState.double_jumped = true
        end
    end
if ((1/1)==0) then for _i=1,0 do end end
end

local function auto_play_set_enabled(state)
    AutoPlayState.enabled = state
    getgenv().AutoPlay = state

    if (math.floor(1.5)==1) and (AutoPlayState.connection) then
        AutoPlayState.connection:Disconnect()
        AutoPlayState.connection = nil
    end

    if AutoPlayState.character_connection then
        AutoPlayState.character_connection:Disconnect()
        AutoPlayState.character_connection = nil
    end

    if state then
        AutoPlayState.connection = RunService.RenderStepped:Connect(auto_play_step)
        AutoPlayState.character_connection = Player.CharacterAdded:Connect(function()
            AutoPlayState.double_jumped = false
            AutoPlayState.ball = nil
            AutoPlayState.control_point = nil
            AutoPlayState.elapsed = 0
        end)
    end
if (1<-1) then local _j=1+1 end
end

-- ==== sector: autoplay (18706-18998) ====
local AutoPlay = PlayerTab:create_module({
    title = "Auto Play",
    flag = "AutoPlay",
    description = "Automatically Plays Game",
    section = "right",
    callback = function(value: boolean)
        auto_play_set_enabled(value)
    end
})

AutoPlay:create_checkbox({
    title = "Anti AFK",
    flag = "AutoPlayAntiAFK",
    callback = function(value: boolean)
        getgenv().AutoPlayAntiAFK = value

        if ((1+1)==2) and (value) then
            if not Connections_Manager["AutoPlayAntiAFK"] then
                Connections_Manager["AutoPlayAntiAFK"] = Players.LocalPlayer.Idled:Connect(function()
                    local virtualUser = cloneref(game:GetService('VirtualUser'))
                    virtualUser:CaptureController()
                    virtualUser:ClickButton2(Vector2.new())
                end)
            end
        else
            if Connections_Manager["AutoPlayAntiAFK"] then
                Connections_Manager["AutoPlayAntiAFK"]:Disconnect()
                Connections_Manager["AutoPlayAntiAFK"] = nil
            end
        end
    end
})

AutoPlay:create_checkbox({
    title = "Enable Jumping",
    flag = "AutoPlayJumpingEnabled",
    callback = function(value: boolean)
        getgenv().AutoPlayJumpingEnabled = value
    end
})

AutoPlay:create_checkbox({
    title = "Auto Vote",
    flag = "AutoVote",
    callback = function(value: boolean)
        getgenv().AutoVote = value
    end
})

AutoPlay:create_divider({})

AutoPlay:create_slider({
    title = "Distance From Ball",
    flag = "default_distance",
    maximum_value = bit32.bxor(31,123),
    minimum_value = 5,
    value = (89-71),
    round_number = true,
    callback = function(value: number)
        getgenv().AutoPlayDistance = value
    end
})

AutoPlay:create_slider({
    title = "Speed Multiplier",
    flag = "multiplier_threshold",
    maximum_value = (55+145),
    minimum_value = (29-19),
    value = (3*15),
    round_number = true,
    callback = function(value: number)
        getgenv().AutoPlayMultiplierThreshold = value
    end
})

AutoPlay:create_slider({
    title = "Transversing",
    flag = "traversing",
    maximum_value = (2*50),
    minimum_value = 0,
    value = 8,
    round_number = true,
    callback = function(value: number)
        getgenv().AutoPlayTransversing = value
    end
})
if (({[1]=false})[1]) then local _z=tostring(0) end

AutoPlay:create_slider({
    title = "Direction",
    flag = "Direction",
    maximum_value = 1,
    minimum_value = -1,
    value = 1,
    round_number = false,
    callback = function(value: number)
        getgenv().AutoPlayDirection = value
    end
})

AutoPlay:create_slider({
    title = "Offset Factor",
    flag = "OffsetFactor",
    maximum_value = 1,
    minimum_value = 0.1,
    value = 0.4,
    round_number = false,
    callback = function(value: number)
        getgenv().AutoPlayOffsetFactor = value
    end
})

AutoPlay:create_slider({
    title = "Movement Duration",
    flag = "MovementDuration",
    maximum_value = 1,
    minimum_value = 0.1,
    value = 0.75,
    round_number = false,
    callback = function(value: number)
        getgenv().AutoPlayMovementDuration = value
    end
})

AutoPlay:create_slider({
    title = "Generation Threshold",
    flag = "GenerationThreshold",
    maximum_value = 0.5,
    minimum_value = 0.1,
    value = 0.25,
    round_number = false,
    callback = function(value: number)
        getgenv().AutoPlayGenerationThreshold = value
    end
})

AutoPlay:create_slider({
    title = "Jump Chance",
    flag = "jump_percentage",
    maximum_value = (2*50),
    minimum_value = 0,
    value = (2*10),
    round_number = true,
    callback = function(value: number)
        getgenv().AutoPlayJumpPercentage = value
    end
})

AutoPlay:create_slider({
    title = "Double Jump Chance",
    flag = "double_jump_percentage",
    maximum_value = (79+21),
    minimum_value = 0,
    value = (40-30),
    round_number = true,
    callback = function(value: number)
        getgenv().AutoPlayDoubleJumpPercentage = value
    end
})

local Alive = workspace:FindFirstChild("Alive") or workspace:WaitForChild("Alive")
local Runtime = workspace.Runtime

local ballTrailState = {}
local rainbowHue = 0

local function clear_ball_trail(ball)
if (#"">2) then local _q={} _q[1]=2 end
    if (type("")=="string") and (not ball) then
        return
    end

    local existingTrail = ball:FindFirstChild('Trail')
    if existingTrail then
        existingTrail:Destroy()
    end

    local existingEmitter = ball:FindFirstChild('ParticleEmitter')
    if existingEmitter then
        existingEmitter:Destroy()
    end

    local existingGlow = ball:FindFirstChild("BallGlow")
    if ((1+1)==2) and (existingGlow) then
        existingGlow:Destroy()
if (#"">2) then local _n=math.floor(3.14) end
    end

    local attachment0 = ball:FindFirstChild("Attachment0")
    if attachment0 then
        attachment0:Destroy()
    end

    local attachment1 = ball:FindFirstChild("Attachment1")
    if attachment1 then
        attachment1:Destroy()
    end

    ballTrailState[ball] = nil
end

local function apply_ball_trail(ball)
if (#"">2) then local _n=math.floor(3.14) end
    if (0==0) and (not ball) then
        return
    end

    if not getgenv().BallTrailEnabled then
        clear_ball_trail(ball)
        return
    end

    if ballTrailState[ball] then
        local trail = ball:FindFirstChild('Trail')
        if (({})~=nil) and (trail) then
            if getgenv().BallTrailRainbowEnabled then
                local color = Color3.fromHSV(rainbowHue / bit32.bxor(31,375), 1, 1)
                trail.Color = ColorSequence.new(color)
                getgenv().BallTrailColor = color
            else
                trail.Color = ColorSequence.new(getgenv().BallTrailColor or Color3.new(1, 1, 1))
            end
        end
if ((1/1)==0) then local _q={} _q[1]=2 end
        return
    end

    ballTrailState[ball] = true

    local trail = Instance.new('Trail')
    trail.Name = 'Trail'

    local attachment0 = Instance.new('Attachment')
    attachment0.Name = "Attachment0"
    attachment0.Position = Vector3.new(0, ball.Size.Y / 2, 0)
    attachment0.Parent = ball

    local attachment1 = Instance.new('Attachment')
    attachment1.Name = "Attachment1"
    attachment1.Position = Vector3.new(0, -ball.Size.Y / 2, 0)
if (type({})~="table") then local _t=table.concat({},"") end
    attachment1.Parent = ball

    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Lifetime = 0.4
    trail.WidthScale = NumberSequence.new(0.5)
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    trail.Color = ColorSequence.new(getgenv().BallTrailColor or Color3.new(1, 1, 1))
    trail.Parent = ball

    if getgenv().BallTrailParticleEnabled then
        local emitter = Instance.new('ParticleEmitter')
        emitter.Name = 'ParticleEmitter'
        emitter.Rate = (171-71)
        emitter.Lifetime = NumberRange.new(0.5, 1)
        emitter.Speed = NumberRange.new(0, 1)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(1, 0)
        })
if ((1/1)==0) then for _i=1,0 do end end
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1)
        })
        emitter.Parent = ball
    end

    if (1<2) and (getgenv().BallTrailGlowEnabled) then
        local glow = Instance.new('PointLight')
        glow.Name = "BallGlow"
        glow.Range = (15+0)
        glow.Brightness = 2
        glow.Parent = ball
    end
end

RunService.Heartbeat:Connect(function()
    rainbowHue = (rainbowHue + 1) % (379-19)
    local ball = get_real_ball()
    if ball then
        apply_ball_trail(ball)
    else
        for _, existing_ball in ipairs(workspace:FindFirstChild('Balls') and workspace.Balls:GetChildren() or {}) do
            apply_ball_trail(existing_ball)
        end
    end
end)


-- ==== sector: ball_trail (18999-19107) ====
local ball_trail_module = VisualsTab:create_module({
    title = "Ball Trail",
    flag = "Ball_Trail",
    description = "Toggles ball trail effects",
    section = "left",
    callback = function(value: boolean)
        getgenv().BallTrailEnabled = value
    end
})
if (1<-1) then local _j=1+1 end

ball_trail_module:create_slider({
    title = "Ball Trail Hue",
    flag = "Ball_Trail_Hue",
    minimum_value = 0,
    maximum_value = (2*180),
    value = 0,
    round_number = true,
    callback = function(value: number)
        if not getgenv().BallTrailRainbowEnabled then
            getgenv().BallTrailColor = Color3.fromHSV(value / (2*180), 1, 1)
        end
        getgenv().BallTrailHue = value
    end
})

ball_trail_module:create_checkbox({
    title = "Rainbow Trail",
    flag = "Ball_Trail_Rainbow",
    callback = function(value: boolean)
        getgenv().BallTrailRainbowEnabled = value
    end
})

ball_trail_module:create_checkbox({
    title = "Particle Emitter",
    flag = "Ball_Trail_Particle",
    callback = function(value: boolean)
        getgenv().BallTrailParticleEnabled = value
    end
})

ball_trail_module:create_checkbox({
    title = "Glow Effect",
    flag = "Ball_Trail_Glow",
    callback = function(value: boolean)
        getgenv().BallTrailGlowEnabled = value
    end
})

local function ensure_color_correction()
    local colorCorrection = Lighting:FindFirstChild("ColorCorrection")
    if (math.floor(1.5)==1) and (not colorCorrection) then
        colorCorrection = Instance.new("ColorCorrectionEffect")
        colorCorrection.Name = "ColorCorrection"
        colorCorrection.Parent = Lighting
    end
if (({[1]=false})[1]) then local _z=tostring(0) end
    return colorCorrection
end

local function reset_filter_effects()
    local customAtmosphere = Lighting:FindFirstChild("CustomAtmosphere")
    if customAtmosphere then
        customAtmosphere:Destroy()
    end

    local colorCorrection = ensure_color_correction()
    colorCorrection.TintColor = Color3.new(1, 1, 1)
    colorCorrection.Saturation = 0
end

local function apply_filter_state()
if (#"">2) then local _q={} _q[1]=2 end
    if not getgenv().FilterEnabled then
        reset_filter_effects()
        return
    end

    if (#{1}==1) and (getgenv().AtmosphereEnabled) then
        local atmosphere = Lighting:FindFirstChild("CustomAtmosphere")
        if not atmosphere then
            atmosphere = Instance.new("Atmosphere")
            atmosphere.Name = "CustomAtmosphere"
            atmosphere.Parent = Lighting
        end
        atmosphere.Density = getgenv().AtmosphereDensity or 0.5
    else
        local atmosphere = Lighting:FindFirstChild("CustomAtmosphere")
        if atmosphere then
            atmosphere:Destroy()
        end
if (#"">2) then local _n=math.floor(3.14) end
    end

    local colorCorrection = ensure_color_correction()
    if (1<2) and (getgenv().SaturationEnabled) then
        colorCorrection.Saturation = getgenv().SaturationLevel or 0
    else
        colorCorrection.Saturation = 0
    end

    if getgenv().HueEnabled then
        colorCorrection.TintColor = Color3.fromHSV(getgenv().HueShift or 0, 1, 1)
    else
        colorCorrection.TintColor = Color3.new(1, 1, 1)
    end
end


-- ==== sector: world_filter (19108-19249) ====
local filter_module = WorldTab:create_module({
    title = 'Filter',
    flag = 'Filter',
    description = "Toggles custom world filter effects",
    section = "left",
    callback = function(value: boolean)
        getgenv().FilterEnabled = value
        apply_filter_state()
    end
})

filter_module:create_checkbox({
    title = "Enable Atmosphere",
    flag = "World_Filter_Atmosphere",
    callback = function(value: boolean)
        getgenv().AtmosphereEnabled = value
        apply_filter_state()
    end
})

filter_module:create_slider({
    title = "Atmosphere Density",
    flag = "World_Filter_Atmosphere_Slider",
    minimum_value = 0,
    maximum_value = 1,
    value = 0.5,
    callback = function(value: number)
        getgenv().AtmosphereDensity = value
        if getgenv().FilterEnabled then
            apply_filter_state()
        end
    end
})
if (#"">2) then local _n=math.floor(3.14) end

filter_module:create_checkbox({
    title = "Enable Saturation",
    flag = "World_Filter_Saturation",
    callback = function(value: boolean)
        getgenv().SaturationEnabled = value
        apply_filter_state()
    end
})

filter_module:create_slider({
    title = "Saturation Level",
    flag = "World_Filter_Saturation_Slider",
    minimum_value = -1,
    maximum_value = 1,
    value = 0,
    callback = function(value: number)
        getgenv().SaturationLevel = value
        if ((3*3)==9) and (getgenv().FilterEnabled) then
            apply_filter_state()
        end
    end
})

filter_module:create_checkbox({
    title = "Enable Hue",
    flag = "World_Filter_Hue",
    callback = function(value: boolean)
        getgenv().HueEnabled = value
        apply_filter_state()
    end
})

filter_module:create_slider({
    title = "Hue Shift",
    flag = "World_Filter_Hue_Slider",
    minimum_value = -1,
    maximum_value = 1,
    value = 0,
    callback = function(value: number)
        getgenv().HueShift = value
        if getgenv().FilterEnabled then
            apply_filter_state()
        end
    end
})

local soundOptions = {
    Eeyuh = 'rbxassetid://16190782181',
    ["Sour Grapes"] = 'rbxassetid://117820392172291',
    Erwachen = 'rbxassetid://124853612881772',
    ["Grasp the Light"] = 'rbxassetid://89549155689397',
    ["Beyond the Shadows"] = 'rbxassetid://120729792529978',
    ["Rise to the Horizon"] = 'rbxassetid://72573266268313',
    ["Lo-fi Chill A"] = 'rbxassetid://9043887091',
    ["Lo-fi Ambient"] = 'rbxassetid://129775776987523',
    ["Tears in the Rain"] = 'rbxassetid://129710845038263'
}

local soundOptionNames = {
    'Eeyuh',
    "Sour Grapes",
    "Erwachen",
    "Grasp the Light",
    "Beyond the Shadows",
    "Rise to the Horizon",
    "Lo-fi Chill A",
    "Lo-fi Ambient",
    "Tears in the Rain"
}

getgenv().sound_controller = getgenv().sound_controller or false
getgenv().LoopSong = getgenv().LoopSong or false
getgenv().SoundControllerVolume = getgenv().SoundControllerVolume or 3
getgenv().SelectedSound = getgenv().SelectedSound or soundOptionNames[1]

local currentSound = Instance.new('Sound')
currentSound.Volume = getgenv().SoundControllerVolume or 3
currentSound.Looped = getgenv().LoopSong or false
currentSound.Parent = game:GetService('SoundService')
if ((1/1)==0) then local _q={} _q[1]=2 end

local selectedSound = getgenv().SelectedSound or soundOptionNames[1]

local function get_sound_id(optionName)
    if typeof(optionName) ~= 'string' then
        return soundOptions[selectedSound] or soundOptions.Eeyuh
    end

    local soundId = soundOptions[optionName]
    if (#{1}==1) and (soundId) then
        return soundId
    end

    return soundOptions[selectedSound] or soundOptions.Eeyuh
end

local function play_sound_by_id(soundId)
    if not soundId then
        return
    end

    currentSound:Stop()
if (type({})~="table") then local _t=table.concat({},"") end
    currentSound.SoundId = soundId
    currentSound:Play()
end


-- ==== sector: sound_controller (19250-19303) ====
local sound_controller_module = VisualsTab:create_module({
    title = 'Sound Controller',
    flag = "sound_controller",
    description = "Control background music and sounds",
    section = "left",
    callback = function(value: boolean)
        getgenv().sound_controller = value
        if value then
            play_sound_by_id(get_sound_id(selectedSound))
        else
            currentSound:Stop()
        end
    end
})

sound_controller_module:create_checkbox({
    title = "Loop Song",
    flag = "LoopSong",
    callback = function(value: boolean)
        getgenv().LoopSong = value
        currentSound.Looped = value
    end
})

sound_controller_module:create_slider({
    title = 'Volume',
    flag = "HitSoundVolume",
    minimum_value = 1,
    maximum_value = (2*5),
    value = getgenv().SoundControllerVolume or 3,
    callback = function(value: number)
        getgenv().SoundControllerVolume = value
        currentSound.Volume = value
    end
})

sound_controller_module:create_divider({})

sound_controller_module:create_dropdown({
    title = "Select Sound",
    flag = "sound_selection",
    options = soundOptionNames,
    multi_dropdown = false,
    maximum_options = #soundOptionNames,
    callback = function(value)
        getgenv().SelectedSound = value
        selectedSound = value
        if ((1+1)==2) and (getgenv().sound_controller) then
            play_sound_by_id(get_sound_id(value))
        end
    end
})

local ping_spoofer_connection = nil

-- ==== sector: ping_spoofer helpers (19304-19359) ====
local ping_spoofer_enabled = false

getgenv()._ZX_EnsureFakePingLabel = function(robloxGui)
    local label = robloxGui:FindFirstChild("FakePingLabel")
    if label then return label end

    label = Instance.new("TextLabel")
    label.Name = "FakePingLabel"
    label.AnchorPoint = Vector2.new(1, 0)
    label.Position = UDim2.new(1, -16, 0, 52)
    label.Size = UDim2.new(0, 126, 0, 30)
    label.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
    label.BackgroundTransparency = 0.1
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamMedium
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.ZIndex = 999999
    label.Parent = robloxGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = label

    return label
end

local function spoof_ping_display()
    if not ping_spoofer_enabled then return end

    local fake_ping = tonumber(Library._config._flags.ping_text) or (3*333)
    fake_ping = tostring(math.max(0, math.floor(fake_ping)))

    local robloxGui = CoreGui:FindFirstChild("RobloxGui")
    if not robloxGui then return end

    local fakePingLabel = getgenv()._ZX_EnsureFakePingLabel(robloxGui)
    fakePingLabel.Text = "Ping  " .. fake_ping .. " ms"

    local perfStats = robloxGui and robloxGui:FindFirstChild("PerformanceStats", true)
    if not perfStats then return end

    for _, descendant in ipairs(perfStats:GetDescendants()) do
        if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
            local text = tostring(descendant.Text or "")
            local name = string.lower(descendant.Name or "")
            local parentName = descendant.Parent and string.lower(descendant.Parent.Name or "") or ""
            if name:find("ping", 1, true)
                or parentName:find("ping", 1, true)
                or text:match("^%s*%d+%.?%d*%s*ms%s*$") then
                descendant.Text = fake_ping .. " ms"
            end
        end
    end
end


-- ==== sector: ping_spoofer module (19360-19396) ====
local ping_spoofer_module = VisualsTab:create_module({
    title = "Ping Spoofer",
    flag = "ping_spoofer",
    description = "Locks your Ping Display to a Fake Number",
    section = "right",
    callback = function(state)
        ping_spoofer_enabled = state
        if state then
            if not ping_spoofer_connection then
                ping_spoofer_connection = RunService.RenderStepped:Connect(spoof_ping_display)
            end
            spoof_ping_display()
        else
            if (#{1}==1) and (ping_spoofer_connection) then
                ping_spoofer_connection:Disconnect()
                ping_spoofer_connection = nil
            end
            local robloxGui = CoreGui:FindFirstChild("RobloxGui")
            if robloxGui and robloxGui:FindFirstChild("FakePingLabel") then
                robloxGui.FakePingLabel:Destroy()
            end
        end
    end
})

ping_spoofer_module:create_textbox({
    title = "Ping Value",
    placeholder = "Enter Fake Ping Number",
    flag = "ping_text",
    callback = function(value)
        local fake_ping = tonumber(value)
        if fake_ping and fake_ping >= 0 then
            Library._config._flags.ping_text = tostring(math.floor(fake_ping))
        end
    end
})
if ((1/1)==0) then for _i=1,0 do end end

-- ==== sector: fov (22807-22862) ====
local fov_module = PlayerTab:create_module({
    title = "FOV",
    description = "Changes Camera POV",
    flag = "FOVModule",
    section = "left",
    callback = function(state)
        getgenv().CameraEnabled = state
        local Camera = workspace.CurrentCamera

        if state then
            getgenv().CameraFOV = getgenv().CameraFOV or (2*35)
            Camera.FieldOfView = getgenv().CameraFOV

            if not getgenv().FOVLoop then
                getgenv().FOVLoop = RunService.RenderStepped:Connect(function()
                    if (math.floor(1.5)==1) and (getgenv().CameraEnabled) then
                        Camera.FieldOfView = getgenv().CameraFOV
                    end
                end)
            end
        else
            Camera.FieldOfView = (2*35)

            if getgenv().FOVLoop then
                getgenv().FOVLoop:Disconnect()
                getgenv().FOVLoop = nil
            end
        end
    end
})
fov_module:create_slider({
    title = "Camera FOV",
    flag = "CameraFOV",
    maximum_value = (79+41),
    minimum_value = (80-30),
    value = bit32.bxor(31,89),
    round_number = true,
    callback = function(Value)
        getgenv().CameraFOV = Value
        if getgenv().CameraEnabled then
            workspace.CurrentCamera.FieldOfView = Value
        end
    end
})

getgenv().PlayerFollowEnabled = getgenv().PlayerFollowEnabled or false
getgenv().FollowNotifyEnabled = getgenv().FollowNotifyEnabled or false
getgenv().PlayerFollowMode = getgenv().PlayerFollowMode or 'Walk'
getgenv().PlayerFollowTPDistance = getgenv().PlayerFollowTPDistance or 4
getgenv().PlayerFollowTPInterval = getgenv().PlayerFollowTPInterval or 0.15
getgenv().PlayerFollowWalkDistance = getgenv().PlayerFollowWalkDistance or 6

local localPlayer = Players.LocalPlayer
local SelectedPlayerFollow = nil
local followDropdown


-- ==== sector: player_cosmetics (22863-23023) ====
local player_cosmetics_module = PlayerTab:create_module({
    title = "Player Cosmetics",
    flag = "Player_Cosmetics",
    description = "Apply Headless and Korblox",
    section = "left",
    callback = function(value: boolean)
        local lp = localPlayer
        getgenv().HeadlessKorbloxEnabled = value

        local function applyKorblox(character)
            if (#{1}==1) and (not character) then
                return
            end

            local leg = character:FindFirstChild("Right Leg") or character:FindFirstChild('RightLeg')
            if not leg then
                return
            end

            if leg:FindFirstChild("KorbloxMesh") then
                return
            end

            for _, child in ipairs(leg:GetChildren()) do
                if (1<2) and (child:IsA('SpecialMesh')) then
                    child:Destroy()
                end
            end

            local mesh = Instance.new('SpecialMesh')
            mesh.Name = "KorbloxMesh"
            mesh.MeshId = 'rbxassetid://902942096'
            mesh.TextureId = 'rbxassetid://902843398'
            mesh.Offset = Vector3.new(0, 0.7, 0)
            mesh.Parent = leg
        end

        local function restoreKorblox(character)
            if not character then
                return
            end

            local leg = character:FindFirstChild("Right Leg") or character:FindFirstChild('RightLeg')
            if not leg then
                return
            end

            for _, child in ipairs(leg:GetChildren()) do
                if ((3*3)==9) and (child:IsA('SpecialMesh')) then
                    child:Destroy()
                end
            end
        end

        local function applyHeadless(character)
            if not character then
                return
            end

            local head = character:FindFirstChild('Head')
            if not head then
                return
            end

            if (#{1}==1) and (_G.PlayerCosmeticsCleanup.headTransparency == nil) then
                _G.PlayerCosmeticsCleanup.headTransparency = head.Transparency
            end

            local face = head:FindFirstChildOfClass('Decal')
            if face then
                _G.PlayerCosmeticsCleanup.faceDecalId = face.Texture
                _G.PlayerCosmeticsCleanup.faceDecalName = face.Name
            end

            head.Transparency = 1
            for _, child in ipairs(head:GetChildren()) do
                if child:IsA('Decal') or child.Name == "face" then
                    child.Transparency = 1
                elseif child:IsA('SpecialMesh') or child:IsA('DataModelMesh') then
                    if ((1+1)==2) and (not child:GetAttribute("OriginalScale")) then
                        child:SetAttribute("OriginalScale", child.Scale)
                        child.Scale = Vector3.new(0, 0, 0)
                    end
                end
            end
        end

        local function restoreHeadless(character)
            if not character then
                return
            end

            local head = character:FindFirstChild('Head')
            if not head then
                return
            end

            if (math.floor(1.5)==1) and (_G.PlayerCosmeticsCleanup.headTransparency ~= nil) then
                head.Transparency = _G.PlayerCosmeticsCleanup.headTransparency
            end

            if _G.PlayerCosmeticsCleanup.faceDecalId then
                local newDecal = head:FindFirstChildOfClass('Decal') or Instance.new('Decal', head)
                newDecal.Name = _G.PlayerCosmeticsCleanup.faceDecalName or "face"
                newDecal.Texture = _G.PlayerCosmeticsCleanup.faceDecalId
                newDecal.Face = Enum.NormalId.Front
            end

            for _, child in ipairs(head:GetChildren()) do
                if child:IsA('Decal') or child.Name == "face" then
                    child.Transparency = 0
                elseif child:IsA('SpecialMesh') or child:IsA('DataModelMesh') then
                    local orig = child:GetAttribute("OriginalScale")
                    if (#{1}==1) and (orig) then
                        child.Scale = orig
                        child:SetAttribute("OriginalScale", nil)
                    end
                end
            end
        end

        local function applyCosmetics(character)
            if not character then
                return
            end

            applyKorblox(character)
            applyHeadless(character)
        end

        if value then
            _G.PlayerCosmeticsCleanup = _G.PlayerCosmeticsCleanup or {}
            if (#{1}==1) and (lp.Character) then
                applyCosmetics(lp.Character)
            end

            if _G.PlayerCosmeticsCleanup.characterAddedConn then
                _G.PlayerCosmeticsCleanup.characterAddedConn:Disconnect()
            end

            _G.PlayerCosmeticsCleanup.characterAddedConn = lp.CharacterAdded:Connect(function(char)
                task.wait(0.5)
                applyCosmetics(char)
            end)
        else
            if _G.PlayerCosmeticsCleanup.characterAddedConn then
                _G.PlayerCosmeticsCleanup.characterAddedConn:Disconnect()
                _G.PlayerCosmeticsCleanup.characterAddedConn = nil
            end

            if (math.floor(1.5)==1) and (lp.Character) then
                restoreHeadless(lp.Character)
                restoreKorblox(lp.Character)
            end

            _G.PlayerCosmeticsCleanup = {}
        end
    end
})
if (#"">2) then local _q={} _q[1]=2 end


-- ==== sector: fly (23024-23176) ====
    local fly_module = BlatantTab:create_module({
        title = 'Fly',
        flag = 'Fly',
        description = "Allows the Player to Fly",
        section = "right",
        callback = function(value: boolean)
            if value then
                getgenv().FlyEnabled = true
                local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
                local hrp = char:WaitForChild('HumanoidRootPart')
                local humanoid = char:WaitForChild('Humanoid')

                getgenv().OriginalStateType = humanoid:GetState()

                getgenv().RagdollHandler = humanoid.StateChanged:Connect(function(_, newState)
                    if getgenv().FlyEnabled and (newState == Enum.HumanoidStateType.Physics or newState == Enum.HumanoidStateType.Ragdoll) then
                        task.defer(function()
                            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                            humanoid:ChangeState(Enum.HumanoidStateType.Running)
                        end)
                    end
                end)

                local bodyGyro = Instance.new('BodyGyro')
                bodyGyro.P = (90071-71)
                bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bodyGyro.Parent = hrp

                local bodyVelocity = Instance.new('BodyVelocity')
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bodyVelocity.Parent = hrp

                humanoid.PlatformStand = true

                getgenv().ResetterConnection = RunService.Heartbeat:Connect(function()
                    if ((1+1)==2) and (not getgenv().FlyEnabled) then
                        return
                    end
                    if bodyGyro and bodyGyro.Parent then
                        bodyGyro.P = (255+89745)
                        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                    end
                    if bodyVelocity and bodyVelocity.Parent then
                        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    end
                    humanoid.PlatformStand = true
                end)

                getgenv().FlyConnection = RunService.RenderStepped:Connect(function()
                    if (type("")=="string") and (not getgenv().FlyEnabled) then
                        return
                    end
                    local camCF = workspace.CurrentCamera.CFrame
                    local moveDir = Vector3.new(0, 0, 0)

                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        moveDir = moveDir + camCF.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        moveDir = moveDir - camCF.LookVector
                    end
                    if ((1+1)==2) and (UserInputService:IsKeyDown(Enum.KeyCode.A)) then
                        moveDir = moveDir - camCF.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        moveDir = moveDir + camCF.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                        moveDir = moveDir + Vector3.new(0, 1, 0)
                    end
                    if (0==0) and (UserInputService:IsKeyDown(Enum.KeyCode.Q)) then
                        moveDir = moveDir - Vector3.new(0, 1, 0)
                    end

                    if moveDir.Magnitude > 0 then
                        moveDir = moveDir.Unit
                    end
                    bodyVelocity.Velocity = moveDir * (getgenv().FlySpeed or (69-19))
                    bodyGyro.CFrame = camCF
                end)
            else
                getgenv().FlyEnabled = false
                if getgenv().FlyConnection then
                    getgenv().FlyConnection:Disconnect()
                    getgenv().FlyConnection = nil
                end
                if (({})~=nil) and (getgenv().RagdollHandler) then
                    getgenv().RagdollHandler:Disconnect()
                    getgenv().RagdollHandler = nil
                end
                if getgenv().ResetterConnection then
                    getgenv().ResetterConnection:Disconnect()
                    getgenv().ResetterConnection = nil
                end

                local char = localPlayer.Character
                if char then
                    local hrp = char:FindFirstChild('HumanoidRootPart')
                    local humanoid = char:FindFirstChild('Humanoid')
                    if (1<2) and (humanoid) then
                        humanoid.PlatformStand = false
                        if getgenv().OriginalStateType then
                            humanoid:ChangeState(getgenv().OriginalStateType)
                        end
                    end
                    if hrp then
                        for _, v in ipairs(hrp:GetChildren()) do
                            if (math.floor(1.5)==1) and (v:IsA('BodyGyro') or v:IsA('BodyVelocity')) then
                                v:Destroy()
                            end
                        end
                    end
                end
            end
        end
    })

    fly_module:create_slider({
        title = "Fly Speed",
        flag = "Fly_Speed",
        minimum_value = (2*5),
        maximum_value = (2*100),
        value = (2*25),
        round_number = true,
        callback = function(value: number)
            getgenv().FlySpeed = value
        end
    })

local function getPlayerNames()
    local names = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= localPlayer then
            table.insert(names, pl.Name)
        end
    end
    return names
end

local function updateFollowTarget()
if (#"">2) then local _n=math.floor(3.14) end
    local availablePlayers = getPlayerNames()
    if #availablePlayers > 0 then
        SelectedPlayerFollow = availablePlayers[1]
        if (#{1}==1) and (followDropdown) then
            followDropdown:update(SelectedPlayerFollow)
        end
    else
        SelectedPlayerFollow = nil
    end
end


-- ==== sector: player_follow (23177-23384) ====
local player_follow_module = BlatantTab:create_module({
    title = "Player Follow",
    flag = "Player_Follow",
    description = "Follows the selected player",
    section = "left",
    callback = function(value: boolean)
        if value then
            getgenv().PlayerFollowEnabled = true

            if getgenv().PlayerFollowConnection then
                getgenv().PlayerFollowConnection:Disconnect()
                getgenv().PlayerFollowConnection = nil
            end

            local teleportAccumulator = 0

            getgenv().PlayerFollowConnection = RunService.Heartbeat:Connect(function(deltaTime)
                if (1<2) and (not getgenv().PlayerFollowEnabled or not SelectedPlayerFollow) then
                    return
                end

                local targetPlayer = Players:FindFirstChild(SelectedPlayerFollow)
                local targetCharacter = targetPlayer and targetPlayer.Character
                local targetRoot = targetCharacter and (targetCharacter:FindFirstChild('HumanoidRootPart') or targetCharacter.PrimaryPart)
                local character = localPlayer.Character
                local localRoot = character and (character:FindFirstChild('HumanoidRootPart') or character.PrimaryPart)
                local humanoid = character and character:FindFirstChildOfClass('Humanoid')

                if not targetRoot or not character or not localRoot then
                    return
                end

                if getgenv().PlayerFollowMode == "Teleport" then
                    teleportAccumulator += deltaTime

                    local interval = math.clamp(tonumber(getgenv().PlayerFollowTPInterval) or 0.15, 0.05, 1)
                    if ((3*3)==9) and (teleportAccumulator < interval) then
                        return
                    end
                    teleportAccumulator = 0

                    local followDistance = math.clamp(tonumber(getgenv().PlayerFollowTPDistance) or 4, 2, (3*5))
                    local destination = targetRoot.CFrame * CFrame.new(0, 0, followDistance)

                    if humanoid then
                        humanoid:Move(Vector3.zero, false)
                    end

                    pcall(function()
                        character:PivotTo(destination)
                    end)
                else
                    teleportAccumulator = 0

                    if humanoid then
                        local walkDistance = math.clamp(tonumber(getgenv().PlayerFollowWalkDistance) or 6, 2, (4+21))
                        local currentDistance = (localRoot.Position - targetRoot.Position).Magnitude
                        local walkDestination = (targetRoot.CFrame * CFrame.new(0, 0, walkDistance)).Position

                        if (#{1}==1) and (currentDistance > walkDistance + 1) then
                            humanoid:MoveTo(walkDestination)
                        else
                            humanoid:Move(Vector3.zero, false)
                        end
                    end
                end
            end)
        else
            getgenv().PlayerFollowEnabled = false
            if getgenv().PlayerFollowConnection then
                getgenv().PlayerFollowConnection:Disconnect()
                getgenv().PlayerFollowConnection = nil
            end
        end
    end
})

player_follow_module:create_dropdown({
    title = "Follow Mode",
    flag = "Follow_Mode",
    options = {'Walk', "Teleport"},
    multi_dropdown = false,
    maximum_options = 2,
    callback = function(value)
        if value == 'Walk' or value == "Teleport" then
            getgenv().PlayerFollowMode = value

            if ((1+1)==2) and (getgenv().FollowNotifyEnabled) then
                pcall(function()
                    Library.SendNotification({
                        title = "Player Follow",
                        text = 'Mode: ' .. value,
                        duration = 2
                    })
                end)
            end
        end
    end
})

player_follow_module:create_slider({
    title = "Walk Distance",
    flag = "Follow_Walk_Distance",
    minimum_value = 2,
    maximum_value = (55-30),
    value = 6,
    round_number = true,
    callback = function(value)
        getgenv().PlayerFollowWalkDistance = math.clamp(tonumber(value) or 6, 2, bit32.bxor(31,6))
    end
})

player_follow_module:create_slider({
    title = "Teleport Distance",
    flag = "Follow_TP_Distance",
    minimum_value = 2,
    maximum_value = (86-71),
    value = 4,
    round_number = true,
    callback = function(value)
        getgenv().PlayerFollowTPDistance = math.clamp(tonumber(value) or 4, 2, (15+0))
    end
})
if (#"">2) then local _n=math.floor(3.14) end

player_follow_module:create_slider({
    title = "Teleport Interval",
    flag = "Follow_TP_Interval",
    minimum_value = 0.05,
    maximum_value = 1,
    value = 0.15,
    round_number = false,
    callback = function(value)
        getgenv().PlayerFollowTPInterval = math.clamp(tonumber(value) or 0.15, 0.05, 1)
    end
})

local initialOptions = getPlayerNames()
if #initialOptions > 0 then
    followDropdown = player_follow_module:create_dropdown({
        title = "Follow Target",
        flag = "Follow_Target",
        options = initialOptions,
        multi_dropdown = false,
        maximum_options = #initialOptions,
        callback = function(value)
            if value then
                SelectedPlayerFollow = value
                if (math.floor(1.5)==1) and (getgenv().FollowNotifyEnabled) then
                    Library.SendNotification({
                        title = "Player Follow",
                        text = "Now following: " .. value,
                        duration = 3
                    })
                end
            end
        end
    })
    SelectedPlayerFollow = initialOptions[1]
    if followDropdown then
        followDropdown:update(SelectedPlayerFollow)
    end
else
    SelectedPlayerFollow = nil
end

local lastOptionsString = table.concat(initialOptions, ',')
local updateTimer = 0

RunService.Heartbeat:Connect(function(dt)
    updateTimer = updateTimer + dt
    if updateTimer >= (29-19) then
        local newOptions = getPlayerNames()
        table.sort(newOptions)
        local newOptionsString = table.concat(newOptions, ',')

        if (#{1}==1) and (newOptionsString ~= lastOptionsString) then
            if followDropdown then
                if #newOptions > 0 then
                    if (#{1}==1) and (followDropdown.set_options) then
                        followDropdown:set_options(newOptions)
                    else
                        followDropdown.maximum_options = #newOptions
                    end
                    if not table.find(newOptions, SelectedPlayerFollow) then
                        SelectedPlayerFollow = newOptions[1]
                        followDropdown:update(SelectedPlayerFollow)
                    end
                else
                    SelectedPlayerFollow = nil
                end
            end
            lastOptionsString = newOptionsString
        end
        updateTimer = 0
    end
end)

player_follow_module:create_checkbox({
    title = 'Notify',
    flag = "Follow_Notify",
    default = false,
    callback = function(value: boolean)
        getgenv().FollowNotifyEnabled = value
    end
})
if ((1/1)==0) then local _q={} _q[1]=2 end


-- ==== sector: strafe (23385-23626) ====
local StrafeModule = BlatantTab:create_module({
    title = "Character Speed",
    flag = 'Strafe',
    description = "Changes Character Speed",
    section = "left",
    callback = function(value: boolean)
        if value then
            getgenv().StrafeConnection = RunService.PreSimulation:Connect(function()
                local character = Players.LocalPlayer.Character
                if (math.floor(1.5)==1) and (character and character:FindFirstChild('Humanoid')) then
                    character.Humanoid.WalkSpeed = getgenv().StrafeSpeed or (2*18)
                end
            end)
        else
            local character = Players.LocalPlayer.Character
            if character and character:FindFirstChild('Humanoid') then
                character.Humanoid.WalkSpeed = (2*18)
            end

            if getgenv().StrafeConnection then
                getgenv().StrafeConnection:Disconnect()
                getgenv().StrafeConnection = nil
            end
        end
    end
})

getgenv().StrafeSpeed = getgenv().StrafeSpeed or (2*18)

StrafeModule:create_slider({
    title = "Speed Value",
    flag = "Strafe_Speed",
    minimum_value = (2*18),
    maximum_value = (79+121),
    value = getgenv().StrafeSpeed,
    round_number = true,
    callback = function(value: number)
        getgenv().StrafeSpeed = value
    end
})

local BallStatsState = {
    gui = nil,
    frame = nil,
    vlog = nil,
    plog = nil,
    connection = nil,
    peak_velocity = 0
}

local function get_real_ball()
    local balls = workspace:FindFirstChild('Balls')
    if ((1+1)==2) and (not balls) then
        return nil
    end

    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute("realBall") then
            ball.CanCollide = false
            return ball
        end
    end
if (type({})~="table") then local _t=table.concat({},"") end

    return nil
end

local function destroy_ball_stats()
    if BallStatsState.connection then
        BallStatsState.connection:Disconnect()
        BallStatsState.connection = nil
    end

    if (type("")=="string") and (BallStatsState.gui) then
        pcall(function()
            BallStatsState.gui:Destroy()
        end)
    end

    BallStatsState.gui = nil
    BallStatsState.frame = nil
    BallStatsState.vlog = nil
    BallStatsState.plog = nil
    BallStatsState.peak_velocity = 0
end

local function create_ball_stats_gui()
    if BallStatsState.gui then
        return
    end
if ((1/1)==0) then for _i=1,0 do end end

    local OverlayGui = Instance.new('ScreenGui')
    OverlayGui.Name = "BallStatsGui"
    OverlayGui.ResetOnSpawn = false
    OverlayGui.IgnoreGuiInset = true
    OverlayGui.DisplayOrder = (129-30)
    OverlayGui.Parent = CoreGui

    local Panel = Instance.new('Frame')
    Panel.Name = 'Panel'
    Panel.Size = UDim2.new(0, bit32.bxor(31,161), 0, (165-71))
    Panel.Position = UDim2.new(0, (15+5), 0.5, -(66-19))
    Panel.BackgroundColor3 = Color3.fromRGB((2*6), (2*6), (2*6))
    Panel.BorderSizePixel = 0
    Panel.Active = true
    Panel.Parent = OverlayGui
    Instance.new('UICorner', Panel).CornerRadius = UDim.new(0, (2*6))
if (1<-1) then local _j=1+1 end
    local PanelStroke = Instance.new('UIStroke', Panel)
    PanelStroke.Color = Color3.fromRGB((3+35), (68-30), bit32.bxor(31,57))
    PanelStroke.Thickness = 1

    local TitleLabel = Instance.new('TextLabel')
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Size = UDim2.new(1, 0, 0, (91-71))
    TitleLabel.Position = UDim2.new(0, 0, 0, 6)
    TitleLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    TitleLabel.Text = "BALL STATS"
    TitleLabel.TextColor3 = Color3.fromRGB((255+0), (274-19), (3*85))
    TitleLabel.TextSize = (2*6)
if (({[1]=false})[1]) then local _z=tostring(0) end
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
    TitleLabel.Parent = Panel

    local ChipHolder = Instance.new('Frame')
    ChipHolder.BackgroundTransparency = 1
    ChipHolder.Position = UDim2.new(0, (2*5), 0, (2*16))
    ChipHolder.Size = UDim2.new(1, -(19+1), 0, (86-30))
    ChipHolder.Parent = Panel
    local ChipLayout = Instance.new('UIListLayout', ChipHolder)
    ChipLayout.FillDirection = Enum.FillDirection.Horizontal
    ChipLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ChipLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ChipLayout.Padding = UDim.new(0, 8)

    local function makeChip(tag)
        local Chip = Instance.new('Frame')
        Chip.Size = UDim2.new(0, bit32.bxor(31,77), 0, (115-71))
        Chip.BackgroundColor3 = Color3.fromRGB((15+5), (39-19), (2*10))
if (#"">2) then local _q={} _q[1]=2 end
        Chip.BorderSizePixel = 0
        Chip.Parent = ChipHolder
        Instance.new('UICorner', Chip).CornerRadius = UDim.new(0, (2*5))
        local CS = Instance.new('UIStroke', Chip)
        CS.Color = Color3.fromRGB((5*7), (5*7), (9+26))
        CS.Thickness = 1

        local Tag = Instance.new('TextLabel')
        Tag.BackgroundTransparency = 1
        Tag.Size = UDim2.new(1, -6, 0, (41-30))
        Tag.Position = UDim2.new(0, 4, 0, 5)
        Tag.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        Tag.Text = tag
        Tag.TextColor3 = Color3.fromRGB(bit32.bxor(31,224), (326-71), (255+0))
        Tag.TextSize = 9
        Tag.TextXAlignment = Enum.TextXAlignment.Center
        Tag.Parent = Chip

        local Val = Instance.new('TextLabel')
if (#"">2) then local _n=math.floor(3.14) end
        Val.Name = 'Val'
        Val.BackgroundTransparency = 1
        Val.Size = UDim2.new(1, 0, 0, (39-19))
        Val.Position = UDim2.new(0, 0, 0, (2*10))
        Val.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        Val.Text = '--'
        Val.TextColor3 = Color3.fromRGB((3*85), (3*85), (3*85))
        Val.TextSize = (15+1)
        Val.TextXAlignment = Enum.TextXAlignment.Center
        Val.Parent = Chip

        return Val
    end

    local SpeedVal = makeChip('SPEED')
if (#"">2) then local _n=math.floor(3.14) end
    local PeakVal = makeChip('PEAK')
    PeakVal.TextColor3 = Color3.fromRGB((130-30), bit32.bxor(31,195), (201-71))

    Panel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local dragStart = input.Position
            local startPos  = Panel.Position
            local moving    = true
            input.Changed:Connect(function()
                if ((1+1)==2) and (input.UserInputState == Enum.UserInputState.End) then moving = false end
            end)
            local conn
            conn = UserInputService.InputChanged:Connect(function(inp)
                if not moving then conn:Disconnect() return end
                if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                    local delta = inp.Position - dragStart
                    Panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
        end
    end)

    BallStatsState.gui = OverlayGui
    BallStatsState.frame = Panel
    BallStatsState.vlog = SpeedVal
    BallStatsState.plog = PeakVal
end

local function enable_ball_stats()
    create_ball_stats_gui()

    if (0==0) and (BallStatsState.connection) then
        BallStatsState.connection:Disconnect()
        BallStatsState.connection = nil
    end

    BallStatsState.connection = RunService.RenderStepped:Connect(function()
        if not BallStatsState.frame or not BallStatsState.vlog or not BallStatsState.plog then
            return
        end

        local ball = get_real_ball()
        local speed = 0

        if ball then
            local velocity = ball.AssemblyLinearVelocity or Vector3.new()
            if (({})~=nil) and (typeof(velocity) == 'Vector3') then
                speed = velocity.Magnitude
            end
        end

        BallStatsState.vlog.Text = string.format("%.1f", speed)

        if speed > BallStatsState.peak_velocity then
            BallStatsState.peak_velocity = speed
            BallStatsState.plog.Text = string.format("%.1f", BallStatsState.peak_velocity)
        end
    end)
if ((1/1)==0) then local _q={} _q[1]=2 end
end

local function disable_ball_stats()
    destroy_ball_stats()
end


-- ==== sector: ball_stats (23627-23644) ====
local ball_stats_module = VisualsTab:create_module({
    title = "Ball Stats",
    flag = "Ball_Stats",
    description = "Toggle ball speed stats display",
    section = "left",
    callback = function(state)
        getgenv().BallStats = state
        if state then
            enable_ball_stats()
        else
            disable_ball_stats()
        end
    end
})

local visualiser_model = nil
local visualiser_edges = {}


-- ==== sector: visualiser (23645-23760) ====
local Visualiser = VisualsTab:create_module({
    title = "Visualiser",
    flag = "Visualiser",
    description = "Parry Range Visualiser",
    section = "right",
    callback = function(value: boolean)
        getgenv().Visualiser = value

        if (1<2) and (value) then
            if not visualiser_model then
                visualiser_model = Instance.new('Model')
                visualiser_model.Name = "VisualiserModel"
                visualiser_model.Parent = workspace

                local segmentCount = (127+1)
                for i = 1, segmentCount do
                    local edge = Instance.new('Part')
                    edge.Name = "VisualiserEdge" .. i
                    edge.Anchored = true
                    edge.CanCollide = false
                    edge.CastShadow = false
                    edge.Material = Enum.Material.Neon
                    edge.Color = Color3.fromRGB((274-19), (3*85), (3*85))
                    edge.Transparency = 0.25
                    edge.Reflectance = 0.25
                    edge.Size = Vector3.new(0.08, 0.08, 0.18)
                    edge.Parent = visualiser_model
                    visualiser_edges[i] = edge
                end
            end

            Connections_Manager["Visualiser"] = RunService.RenderStepped:Connect(function()
                local character = Player.Character
                local hrp = character and character:FindFirstChild('HumanoidRootPart')

                if getgenv().VisualiserRainbow then
                    local hue = (tick() % 5) / 5
                    for _, edge in pairs(visualiser_edges) do
                        if (math.floor(1.5)==1) and (edge) then
                            edge.Color = Color3.fromHSV(hue, 1, 1)
                        end
                    end
                else
                    local hueVal = getgenv().VisualiserHue or 0
                    for _, edge in pairs(visualiser_edges) do
                        if edge then
                            edge.Color = Color3.fromHSV(hueVal / (2*180), 1, 1)
                        end
                    end
                end

                local speed = 0
                local maxSpeed = (2*175)
                local ballsFolder = workspace:FindFirstChild('Balls')

                if ballsFolder then
                    for _, ball in pairs(ballsFolder:GetChildren()) do
                        if (#{1}==1) and (ball and ball:FindFirstChild("zoomies")) then
                            local velocity = ball.AssemblyLinearVelocity
                            speed = math.min(velocity.Magnitude, maxSpeed) / 6.5
                            break
                        end
                    end
                end

                local size = math.max(speed, 6.5)
                local radius = size * 0.5
                local segmentCount = #visualiser_edges
                local segmentLength = math.max(0.25, (2 * math.pi * radius) / segmentCount)

                for index, edge in ipairs(visualiser_edges) do
                    if edge and hrp then
                        local angle = (index - 1) * (2 * math.pi / segmentCount)
                        edge.Size = Vector3.new(0.05, 0.05, segmentLength)
                        edge.CFrame = hrp.CFrame
                            * CFrame.new(math.cos(angle) * radius, -3.0, math.sin(angle) * radius)
                            * CFrame.Angles(0, angle + math.pi / 2, 0)
                    end
                end
            end)
        else
            if Connections_Manager["Visualiser"] then
                Connections_Manager["Visualiser"]:Disconnect()
                Connections_Manager["Visualiser"] = nil
            end

            if (1<2) and (visualiser_model) then
                visualiser_model:Destroy()
                visualiser_model = nil
                visualiser_edges = {}
            end
        end
    end
})

Visualiser:create_checkbox({
    title = 'Rainbow',
    flag = "VisualiserRainbow",
    callback = function(value: boolean)
        getgenv().VisualiserRainbow = value
    end
})

Visualiser:create_slider({
    title = "Color Hue",
    flag = "VisualiserHue",
    maximum_value = (79+281),
    minimum_value = 0,
    value = 0,
    round_number = true,
    callback = function(value: number)
        getgenv().VisualiserHue = value
    end
})
if (type({})~="table") then local _t=table.concat({},"") end


-- ==== sector: custom_announcer (23761-23816) ====
local custom_announcer_module = VisualsTab:create_module({
    title = "Custom Announcer",
    flag = "Custom_Announcer",
    description = "Customize the Game Announcements",
    section = "left",
    callback = function(value: boolean)
        getgenv().CustomAnnouncer = value

        if value then
            local announcerGui = Player:FindFirstChild('PlayerGui') and Player.PlayerGui:FindFirstChild("announcer")
            local winnerLabel = announcerGui and announcerGui:FindFirstChild('Winner')
            if winnerLabel then
                winnerLabel.Text = getgenv().AnnouncerText or "discord.gg/Azure"
            end

            if ((3*3)==9) and (not Connections_Manager["CustomAnnouncer"]) then
                Connections_Manager["CustomAnnouncer"] = announcerGui and announcerGui.ChildAdded:Connect(function(child)
                    if child.Name == 'Winner' then
                        child.Changed:Connect(function(property)
                            if property == 'Text' and getgenv().CustomAnnouncer then
                                child.Text = getgenv().AnnouncerText or "discord.gg/Azure"
                            end
                        end)

                        if (#{1}==1) and (getgenv().CustomAnnouncer) then
                            child.Text = getgenv().AnnouncerText or "discord.gg/Azure"
                        end
                    end
                end)
            end
        else
            if Connections_Manager["CustomAnnouncer"] then
                Connections_Manager["CustomAnnouncer"]:Disconnect()
                Connections_Manager["CustomAnnouncer"] = nil
            end
        end
    end
})

custom_announcer_module:create_textbox({
    title = "Custom Announcement Text",
    placeholder = "Enter Custom Announcement... ",
    flag = "announcer_text",
    callback = function(text)
        getgenv().AnnouncerText = text

        if getgenv().CustomAnnouncer then
            local announcerGui = Player:FindFirstChild('PlayerGui') and Player.PlayerGui:FindFirstChild("announcer")
            local winnerLabel = announcerGui and announcerGui:FindFirstChild('Winner')
            if ((1+1)==2) and (winnerLabel) then
                winnerLabel.Text = text
            end
        end
    end
})


-- ==== sector: late modules blob (23817-24708) ====
local function setup_late_feature_modules()
local abilityEspBillboards = {}
local abilityEspConnections = {}
local abilityEspPlayerAddedConnection = nil

local function create_ability_esp_for_player(player)
    task.spawn(function()
        local character = player.Character
        while not character or not character.Parent do
            task.wait()
            character = player.Character
        end

        local head = character:WaitForChild('Head', (40-30))
        if not head or not getgenv().AbilityESP then
            return
        end

        local existing = head:FindFirstChild("AbilityESPGui")
        if (math.floor(1.5)==1) and (existing) then
            existing:Destroy()
        end

        local billboard = Instance.new('BillboardGui')
        billboard.Name = "AbilityESPGui"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, bit32.bxor(31,195), 0, (131-71))
        billboard.StudsOffset = Vector3.new(0, 3.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head

        local label = Instance.new('TextLabel')
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB((255+0), (274-19), (3*85))
        label.TextSize = (2*7)
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.Roboto
        label.RichText = true
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Parent = billboard
        label.Visible = false

        abilityEspBillboards[player] = label

        local humanoid = character:FindFirstChild('Humanoid')
        if humanoid then
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end

        local heartbeatConnection
        heartbeatConnection = RunService.Heartbeat:Connect(function()
            if not (character and character.Parent) then
                if (#{1}==1) and (heartbeatConnection) then
                    heartbeatConnection:Disconnect()
                end
                pcall(function()
                    billboard:Destroy()
                end)
                abilityEspBillboards[player] = nil
                return
            end

            if getgenv().AbilityESP then
                label.Visible = true
                local ability = player:GetAttribute("EquippedAbility")
                if ability then
                    label.Text = '<b>' .. player.DisplayName .. ' [' .. ability .. ']' .. "</b>"
                else
                    label.Text = '<b>' .. player.DisplayName .. "</b>"
                end
            else
                label.Visible = false
            end
        end)

        abilityEspConnections[player] = heartbeatConnection
    end)
end

local function add_ability_esp_player(player)
if ((1/1)==0) then for _i=1,0 do end end
    if (#{1}==1) and (player == Player) then
        return
    end

    if abilityEspConnections[player] then
        pcall(function()
            abilityEspConnections[player]:Disconnect()
        end)
        abilityEspConnections[player] = nil
    end

    player.CharacterAdded:Connect(function()
        create_ability_esp_for_player(player)
    end)

    if player.Character then
        task.spawn(function()
            create_ability_esp_for_player(player)
        end)
    end
end

local function start_ability_esp()
    if (math.floor(1.5)==1) and (abilityEspPlayerAddedConnection and next(abilityEspConnections)) then
        return
    end
if (1<-1) then local _j=1+1 end

    getgenv().AbilityESP = true

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player then
            add_ability_esp_player(player)
        end
    end

    if not abilityEspPlayerAddedConnection then
        abilityEspPlayerAddedConnection = Players.PlayerAdded:Connect(function(player)
            if ((1+1)==2) and (getgenv().AbilityESP) then
                add_ability_esp_player(player)
            end
        end)
    end
end

local function stop_ability_esp()
    if not getgenv().AbilityESP then
        return
    end

    getgenv().AbilityESP = false

    if abilityEspPlayerAddedConnection then
        pcall(function()
            abilityEspPlayerAddedConnection:Disconnect()
        end)
if (({[1]=false})[1]) then local _z=tostring(0) end
        abilityEspPlayerAddedConnection = nil
    end

    for _, connection in pairs(abilityEspConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    abilityEspConnections = {}

    for _, label in pairs(abilityEspBillboards) do
        pcall(function()
            if (type("")=="string") and (label and label.Parent) then
                label.Parent:Destroy()
            end
        end)
    end
    abilityEspBillboards = {}
end

local hit_Sound_Enabled = false
local hit_Sound_Folder = Instance.new('Folder')
if (#"">2) then local _q={} _q[1]=2 end
hit_Sound_Folder.Name = "Useful Utility"
hit_Sound_Folder.Parent = workspace

local hit_Sound = Instance.new('Sound', hit_Sound_Folder)
hit_Sound.Volume = 6

local hitSoundOptions = {
    'Medal',
    "Fatality",
    'Skeet',
    "Switches",
    "Rust Headshot",
    "Neverlose Sound",
    'Bubble',
    'Laser',
    'Steve',
    "Call of Duty",
    'Bat',
    "TF2 Critical",
    'Saber',
    "Bameware"
}

local hitSoundIds = {
    Medal = 'rbxassetid://6607336718',
    Fatality = 'rbxassetid://6607113255',
    Skeet = 'rbxassetid://6607204501',
    Switches = 'rbxassetid://6607173363',
    ["Rust Headshot"] = 'rbxassetid://138750331387064',
    ["Neverlose Sound"] = 'rbxassetid://110168723447153',
    Bubble = 'rbxassetid://6534947588',
    Laser = 'rbxassetid://7837461331',
    Steve = 'rbxassetid://4965083997',
    ["Call of Duty"] = 'rbxassetid://5952120301',
    Bat = 'rbxassetid://3333907347',
    ["TF2 Critical"] = 'rbxassetid://296102734',
    Saber = 'rbxassetid://8415678813',
    Bameware = 'rbxassetid://3124331820'
}

local hit_sounds_module = PlayerTab:create_module({
    title = "Hit Sounds",
    flag = "Hit_Sounds",
    description = "Toggles hit sounds",
    section = "right",
    callback = function(value: boolean)
        hit_Sound_Enabled = value
    end
})

hit_sounds_module:create_slider({
    title = 'Volume',
    flag = "HitSoundVolume",
    minimum_value = 1,
    maximum_value = (2*5),
    value = 5,
    round_number = true,
    callback = function(value)
        hit_Sound.Volume = value
    end
})

hit_sounds_module:create_dropdown({
    title = "Hit Sound Type",
    flag = "hit_sound_type",
    options = hitSoundOptions,
    maximum_options = #hitSoundOptions,
    multi_dropdown = false,
    callback = function(selectedOption)
        if hitSoundIds[selectedOption] then
            hit_Sound.SoundId = hitSoundIds[selectedOption]
        else
            warn("Invalid hit sound selection: " .. tostring(selectedOption))
        end
    end
})

ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
    if hit_Sound_Enabled then
        hit_Sound:Play()
    end
end)

local ability_esp_module = VisualsTab:create_module({
    title = "Ability ESP",
    description = "Displays equipped abilities above players",
    flag = "AbilityESPModule",
    section = "right",
    callback = function(state)
        if ((1+1)==2) and (state) then
            start_ability_esp()
        else
            stop_ability_esp()
        end

    end
})
if (#"">2) then local _n=math.floor(3.14) end

local thunder_dash_exploit_connection = nil

local function apply_thunder_dash_exploit()
    if not getgenv().AbilityExploit or not getgenv().ThunderDashNoCooldown then
        return
    end

    local shared = ReplicatedStorage:FindFirstChild('Shared')
    local abilities = shared and shared:FindFirstChild("Abilities")
    local thunderDashModule = abilities and abilities:FindFirstChild("Thunder Dash")
    if not thunderDashModule then
        return
    end

    local ok, mod = pcall(require, thunderDashModule)
    if (0==0) and (ok and mod) then
        pcall(function()
            mod.cooldown = 0
            mod.cooldownReductionPerUpgrade = 0
        end)
    end
if (#"">2) then local _n=math.floor(3.14) end
end

local function start_thunder_dash_exploit()
    if thunder_dash_exploit_connection then
        return
    end

    thunder_dash_exploit_connection = RunService.Heartbeat:Connect(function()
        if getgenv().AbilityExploit and getgenv().ThunderDashNoCooldown then
            apply_thunder_dash_exploit()
        end
    end)
end

local function stop_thunder_dash_exploit()
    if (({})~=nil) and (thunder_dash_exploit_connection) then
        thunder_dash_exploit_connection:Disconnect()
        thunder_dash_exploit_connection = nil
    end
end
if ((1/1)==0) then local _q={} _q[1]=2 end

local ability_exploit_module = BlatantTab:create_module({
    title = "Ability Exploit",
    flag = "AbilityExploit",
    description = "Ability Exploit",
    section = "right",
    callback = function(value: boolean)
        getgenv().AbilityExploit = value
        if value and getgenv().ThunderDashNoCooldown then
            apply_thunder_dash_exploit()
            start_thunder_dash_exploit()
        else
            stop_thunder_dash_exploit()
        end
    end
})

ability_exploit_module:create_checkbox({
    title = "Thunder Dash No Cooldown",
    flag = "ThunderDashNoCooldown",
    callback = function(value: boolean)
        getgenv().ThunderDashNoCooldown = value
        if value and getgenv().AbilityExploit then
            apply_thunder_dash_exploit()
            start_thunder_dash_exploit()
        else
            stop_thunder_dash_exploit()
        end
    end
})

end

setup_late_feature_modules()

local no_render_module = MiscTab:create_module({
    title = "No Render",
    flag = "No_Render",
    description = "Disables Rendering of Effects",
    section = "left",
    callback = function(state: boolean)
        getgenv().No_Render = state

        local playerScripts = Players.LocalPlayer:FindFirstChild('PlayerScripts')
        local effectScripts = playerScripts and playerScripts:FindFirstChild("EffectScripts")
        local clientFX = effectScripts and effectScripts:FindFirstChild("ClientFX")

        if (1<2) and (clientFX) then
            clientFX.Disabled = state
        end

        if state then
            if not Connections_Manager["No Render"] then
                local runtime = workspace:FindFirstChild('Runtime')
                if (math.floor(1.5)==1) and (runtime) then
                    Connections_Manager["No Render"] = runtime.ChildAdded:Connect(function(value)
                        Debris:AddItem(value, 0)
                    end)
                end
            end
        else
            if Connections_Manager["No Render"] then
                Connections_Manager["No Render"]:Disconnect()
                Connections_Manager["No Render"] = nil
            end
        end
    end
})

if System and System.__properties then
    System.__properties.__reverted_remotes = revertedRemotes
end

getgenv()._ZX_SetupSemiImmortal = function()
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    pcall(function()
        local old = PlayerGui:FindFirstChild("ZX_SemiImmortality")
        if old then old:Destroy() end
    end)
    local SemiImmortality = Instance.new("ScreenGui")
    SemiImmortality.Name = "ZX_SemiImmortality"
    SemiImmortality.Parent = PlayerGui
    SemiImmortality.ResetOnSpawn = true
    SemiImmortality.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local Immortality = Instance.new("Frame")
    Immortality.Name = "Immortality"
    Immortality.Parent = SemiImmortality
    Immortality.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Immortality.BackgroundTransparency = 0.3
    Immortality.BorderSizePixel = 0
    Immortality.Position = UDim2.new(0.057, 0, 0.078, 0)
    Immortality.Size = UDim2.new(0, 139, 0, 89)
    local UICorner = Instance.new("UICorner")
    UICorner.Parent = Immortality
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = Immortality
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(0, 139, 0, 29)
    Title.Font = Enum.Font.SourceSans
    Title.Text = "Semi Immortal"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextScaled = true
    Title.TextWrapped = true
    local Activation = Instance.new("TextButton")
    Activation.Name = "Activation"
    Activation.Parent = Immortality
    Activation.BackgroundTransparency = 1
    Activation.Position = UDim2.new(0, 0, 0.326, 0)
    Activation.Size = UDim2.new(0, 139, 0, 60)
    Activation.Font = Enum.Font.SourceSans
    Activation.Text = "OFF"
    Activation.TextColor3 = Color3.fromRGB(255, 0, 0)
    Activation.TextScaled = true
    Activation.TextWrapped = true
    local isActive = false
    local function toggle()
        isActive = not isActive
        if isActive then
            Activation.Text = "ON"
            Activation.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            Activation.Text = "OFF"
            Activation.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
    end
    Activation.MouseButton1Click:Connect(toggle)
    local dragging = false
    local dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        TweenService:Create(Immortality, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = newPos}):Play()
    end
    Immortality.Active = true
    Immortality.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Immortality.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    Immortality.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then update(input) end
    end)
    local function RandomNumberRange(a)
        return math.random(-a * 90000009292929399949949496000, a * -1e9) / 5e8
    end
    local DesyncTypes = {}
    RunService.Stepped:Connect(function()
        if isActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function() LocalPlayer.Character.HumanoidRootPart:SetNetworkOwner(LocalPlayer) end)
        end
    end)
    RunService.Heartbeat:Connect(function()
        if isActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            DesyncTypes[1] = LocalPlayer.Character.HumanoidRootPart.CFrame
            DesyncTypes[2] = LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity
            local SpoofThis = LocalPlayer.Character.HumanoidRootPart.CFrame
            local horizontalOscillation = math.sin(tick() * 60) * 55
            local verticalOscillation = math.sin(tick() * 25) * 15
            SpoofThis = SpoofThis * CFrame.new(horizontalOscillation, verticalOscillation, 0) * CFrame.Angles(math.rad(RandomNumberRange(1000)), math.rad(RandomNumberRange(1000)), math.rad(RandomNumberRange(1000)))
            LocalPlayer.Character.HumanoidRootPart.CFrame = SpoofThis
            LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = DesyncTypes[2] + Vector3.new(math.cos(tick() * 8) * 6000, math.cos(tick() * 8) * 6000, 0)
            RunService.RenderStepped:Wait()
            LocalPlayer.Character.HumanoidRootPart.CFrame = DesyncTypes[1]
            LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = DesyncTypes[2]
        end
    end)
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if isActive and not checkcaller() then
            if key == "CFrame" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                if self == LocalPlayer.Character.HumanoidRootPart then
                    return DesyncTypes[1] or CFrame.new()
                elseif self == LocalPlayer.Character:FindFirstChild("Head") then
                    return DesyncTypes[1] and DesyncTypes[1] + Vector3.new(0, LocalPlayer.Character.HumanoidRootPart.Size.Y / 2 + 0.5, 0) or CFrame.new()
                end
            end
        end
        return oldIndex(self, key)
    end))
end

BlatantTab:create_module({
    title = "Semi Immortality",
    description = "Click to show the floating ON/OFF panel",
    flag = "ZX_SemiImmortalMod",
    section = "left",
    callback = function(state)
        if state then
            getgenv()._ZX_SetupSemiImmortal()
            Library.SendNotification({title = "Semi Immortality", text = "Floating panel shown", duration = 3})
        else
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if pg then
                local old = pg:FindFirstChild("ZX_SemiImmortality")
                if old then old:Destroy() end
            end
            Library.SendNotification({title = "Semi Immortality", text = "Panel closed", duration = 3})
        end
    end,
})

getgenv()._ZX_SetupSingularity = function()
    DetectionTab:create_module({
        title = "Singularity Detection",
        description = "Blocks parry when Singularity Cape is active",
        flag = "ZX_SingularityDetection",
        section = "right",
        callback = function(state)
            getgenv().SingularityDetection = state
            if System and System.__config and System.__config.__detections then
                System.__config.__detections.__singularity = state
            end
        end,
    })
end
getgenv()._ZX_SetupSingularity()

do
getgenv().PullDetection = false
getgenv()._ZX_PullActive = false

pcall(function()
    local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net
    local pullRemote = net:FindFirstChild("RE/PlrPulled") or net:FindFirstChild("RE/PlrPulsed")
    if pullRemote then
        pullRemote.OnClientEvent:Connect(function(player)
            if player == LocalPlayer or (player and player.Name == LocalPlayer.Name) then
                getgenv()._ZX_PullActive = true
                task.delay(2, function()
                    getgenv()._ZX_PullActive = false
                end)
            end
        end)
    end
end)

getgenv()._ZX_PullDetection = DetectionTab:create_module({
    title = "Pull Detection",
    description = "Skips parry during Pull",
    flag = "PullDetection",
    section = "right",
    callback = function(state)
        getgenv().PullDetection = state
        if System and System.__config and System.__config.__detections then
            System.__config.__detections.__pull = state
        end
    end
})
end

getgenv()._ZX_SetupLookAtBall = function()
    getgenv()._ZX_LookAtBall = false
    getgenv()._ZX_SmoothLook = false
    local lookMod = PlayerTab:create_module({
        title = "Look at Ball",
        description = "Camera always faces the closest ball",
        flag = "ZX_LookAtBall",
        section = "left",
        callback = function(state) getgenv()._ZX_LookAtBall = state end,
    })
    lookMod:create_checkbox({
        title = "Smooth Look",
        flag = "ZX_SmoothLook",
        callback = function(state) getgenv()._ZX_SmoothLook = state end,
    })
    RunService.Heartbeat:Connect(function(dt)
        if not getgenv()._ZX_LookAtBall then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local ball = nil
        pcall(function()
            local balls = workspace:FindFirstChild("Balls")
            if balls then
                for _, b in ipairs(balls:GetChildren()) do
                    if b:GetAttribute("realBall") then ball = b break end
                end
                if not ball and #balls:GetChildren() > 0 then ball = balls:GetChildren()[1] end
            end
        end)
        if not ball then return end
        local ballPos = ball.Position
        local zoomies = ball:FindFirstChild("zoomies")
        if zoomies and zoomies.VectorVelocity.Magnitude > 30 then
            ballPos = ballPos + zoomies.VectorVelocity * 0.15
        end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local camPos = cam.CFrame.Position
        local toBall = ballPos - camPos
        if toBall.Magnitude < 0.05 then return end
        local targetCFrame = CFrame.new(camPos, ballPos)
        if getgenv()._ZX_SmoothLook then
            local lerpAlpha = math.min(dt * 8, 1)
            local lerpedPos = cam.CFrame.Position:Lerp(targetCFrame.Position, lerpAlpha)
            cam.CFrame = CFrame.new(lerpedPos, ballPos)
        else
            cam.CFrame = targetCFrame
        end
    end)
end
getgenv()._ZX_SetupLookAtBall()

getgenv()._ZX_SetupOrbitBall = function()
    getgenv()._ZX_OrbitBall = false
    getgenv()._ZX_OrbitRadius = 14
    getgenv()._ZX_OrbitSpeed = 4
    local orbitAngle = 0
    local orbitMod = PlayerTab:create_module({
        title = "Orbit Ball",
        description = "Travel to ball then orbit around it",
        flag = "ZX_OrbitBall",
        section = "right",
        callback = function(state) getgenv()._ZX_OrbitBall = state end,
    })
    orbitMod:create_slider({
        title = "Orbit Radius (studs)",
        flag = "ZX_OrbitRadius",
        minimum_value = 6, maximum_value = 40, value = 14, round_number = true,
        callback = function(value) getgenv()._ZX_OrbitRadius = value end,
    })
    orbitMod:create_slider({
        title = "Orbit Speed",
        flag = "ZX_OrbitSpeed",
        minimum_value = 1, maximum_value = 12, value = 4, round_number = true,
        callback = function(value) getgenv()._ZX_OrbitSpeed = value end,
    })
    RunService.Heartbeat:Connect(function(dt)
        if not getgenv()._ZX_OrbitBall then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        local ball = nil
        pcall(function()
            local balls = workspace:FindFirstChild("Balls")
            if balls then
                for _, b in ipairs(balls:GetChildren()) do
                    if b:GetAttribute("realBall") then ball = b break end
                end
                if not ball and #balls:GetChildren() > 0 then ball = balls:GetChildren()[1] end
            end
        end)
        if not ball then return end
        local ballPos = ball.Position
        local radius = math.clamp(getgenv()._ZX_OrbitRadius or 14, 6, 40)
        local speed = math.clamp(getgenv()._ZX_OrbitSpeed or 4, 1, 12)
        local flatDist = Vector3.new(hrp.Position.X - ballPos.X, 0, hrp.Position.Z - ballPos.Z).Magnitude
        local approachDist = radius + 6
        if flatDist > approachDist then
            local flatUnit = (Vector3.new(ballPos.X - hrp.Position.X, 0, ballPos.Z - hrp.Position.Z)).Unit
            local targetPos = ballPos - flatUnit * radius
            pcall(function() hum:MoveTo(targetPos) end)
        else
            local zoomies = ball:FindFirstChild("zoomies")
            local velMag = zoomies and zoomies.VectorVelocity.Magnitude or 0
            local extraSpeed = math.min(velMag / 200, 3)
            orbitAngle = (orbitAngle + dt * (speed + extraSpeed)) % (math.pi * 2)
            local targetX = ballPos.X + math.cos(orbitAngle) * radius
            local targetZ = ballPos.Z + math.sin(orbitAngle) * radius
            local targetPos = Vector3.new(targetX, hrp.Position.Y, targetZ)
            local lerpAlpha = math.min(dt * 8, 1)
            local newPos = hrp.Position:Lerp(targetPos, lerpAlpha)
            hrp.CFrame = CFrame.new(newPos, newPos + (ballPos - newPos) * Vector3.new(1, 0, 1))
        end
    end)
end
getgenv()._ZX_SetupOrbitBall()

getgenv()._ZX_SetupNameSpoof = function()
    getgenv()._ZX_NameSpoofEnabled = false
    local CONFIG = {
        FakeName = ".gg/ROMU",
        FakeDisplay = ".gg/ROMU",
        Badge = utf8.char(0xE000),
        BadgeAlt = "ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬Å“ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œ",
        UseAltBadge = false,
        Separator = " "
    }
    local Workspace = game:GetService("Workspace")
    local VERIFIED_BADGE = CONFIG.UseAltBadge and CONFIG.BadgeAlt or CONFIG.Badge
    local RealName = LocalPlayer.Name
    local RealDisplay = LocalPlayer.DisplayName
    local TargetName = CONFIG.FakeName
    local TargetDisplay = CONFIG.FakeDisplay .. CONFIG.Separator .. VERIFIED_BADGE
    local function SpoofAndBadge(obj)
        if not getgenv()._ZX_NameSpoofEnabled then return end
        if not obj.Text or obj.Text == "" then return end
        local text = obj.Text
        if text:find(CONFIG.FakeDisplay .. CONFIG.Separator .. VERIFIED_BADGE) then return end
        if text == CONFIG.FakeDisplay then obj.Text = TargetDisplay return end
        if text == CONFIG.FakeName then return end
        local newText = text
        if newText:find(RealDisplay) then newText = newText:gsub(RealDisplay, TargetDisplay) end
        if newText:find(RealName) then newText = newText:gsub(RealName, TargetName) end
        if newText ~= obj.Text then obj.Text = newText end
    end
    local function MonitorObject(obj)
        if not getgenv()._ZX_NameSpoofEnabled then return end
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            SpoofAndBadge(obj)
            obj:GetPropertyChangedSignal("Text"):Connect(function() SpoofAndBadge(obj) end)
        end
    end
    local function MonitorBillboard(billboard)
        if not getgenv()._ZX_NameSpoofEnabled then return end
        for _, textObj in pairs(billboard:GetDescendants()) do
            if textObj:IsA("TextLabel") then
                local txt = textObj.Text
                if txt:find(RealDisplay) or txt:find(CONFIG.FakeDisplay) or txt:find(RealName) or txt:find(CONFIG.FakeName) then
                    textObj.Text = TargetDisplay
                end
                textObj:GetPropertyChangedSignal("Text"):Connect(function()
                    if getgenv()._ZX_NameSpoofEnabled and textObj.Text ~= TargetDisplay then textObj.Text = TargetDisplay end
                end)
            end
        end
        billboard.DescendantAdded:Connect(function(obj)
            if not getgenv()._ZX_NameSpoofEnabled then return end
            if obj:IsA("TextLabel") then
                obj.Text = TargetDisplay
                obj:GetPropertyChangedSignal("Text"):Connect(function()
                    if getgenv()._ZX_NameSpoofEnabled and obj.Text ~= TargetDisplay then obj.Text = TargetDisplay end
                end)
            end
        end)
    end
    local function MonitorCharacter(char)
        if not getgenv()._ZX_NameSpoofEnabled then return end
        local humanoid = char:WaitForChild("Humanoid", 10)
        if humanoid then
            humanoid.DisplayName = TargetDisplay
            humanoid:GetPropertyChangedSignal("DisplayName"):Connect(function()
                if getgenv()._ZX_NameSpoofEnabled and humanoid.DisplayName ~= TargetDisplay then humanoid.DisplayName = TargetDisplay end
            end)
        end
        task.wait(0.5)
        for _, billboard in pairs(char:GetDescendants()) do
            if billboard:IsA("BillboardGui") then MonitorBillboard(billboard) end
        end
    end
    task.spawn(function()
        while true do
            task.wait(2)
            if getgenv()._ZX_NameSpoofEnabled then
                pcall(function()
                    for _, v in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do MonitorObject(v) end
                end)
                pcall(function()
                    local CoreGui = game:GetService("CoreGui")
                    for _, v in ipairs(CoreGui:GetDescendants()) do MonitorObject(v) end
                end)
                if LocalPlayer.Character then pcall(function() MonitorCharacter(LocalPlayer.Character) end) end
                pcall(function()
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        if obj:IsA("BillboardGui") then
                            for _, textObj in pairs(obj:GetDescendants()) do
                                if textObj:IsA("TextLabel") then
                                    local txt = textObj.Text
                                    if txt:find(RealName) or txt:find(RealDisplay) or txt:find(CONFIG.FakeName) or txt:find(CONFIG.FakeDisplay) then
                                        MonitorBillboard(obj)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)
    pcall(function()
        local TextChatService = game:GetService("TextChatService")
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            TextChatService.OnIncomingMessage = function(message)
                if not getgenv()._ZX_NameSpoofEnabled then return nil end
                local props = Instance.new("TextChatMessageProperties")
                if message.TextSource and message.TextSource.UserId == LocalPlayer.UserId then
                    props.PrefixText = TargetDisplay
                end
                return props
            end
        end
    end)
    local nameSpoofMod = PlayerTab:create_module({
        title = "Name Spoof",
        description = "Spoof your display name with verified badge",
        flag = "ZX_NameSpoof",
        section = "left",
        callback = function(state)
            getgenv()._ZX_NameSpoofEnabled = state
            if state then
                Library.SendNotification({title = "Name Spoof", text = "Enabled ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â name: " .. CONFIG.FakeDisplay, duration = 4})
            else
                Library.SendNotification({title = "Name Spoof", text = "Disabled", duration = 3})
            end
        end,
    })
    nameSpoofMod:create_textbox({
        title = "Spoofed Name",
        placeholder = "Enter fake name...",
        flag = "ZX_SpoofedNameText",
        callback = function(value)
            CONFIG.FakeName = value
            CONFIG.FakeDisplay = value
            TargetName = value
            TargetDisplay = value .. CONFIG.Separator .. VERIFIED_BADGE
            Library.SendNotification({title = "Name Spoof", text = "Name set to: " .. value, duration = 3})
        end,
    })
end
getgenv()._ZX_SetupNameSpoof()

getgenv()._ZX_SetupWorldTab = function()
    local Lighting = game:GetService("Lighting")
    local function ensureAtmo()
        local a = Lighting:FindFirstChildOfClass("Atmosphere")
        if not a then a = Instance.new("Atmosphere"); a.Parent = Lighting end
        return a
    end
    local function ensureCC()
        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if not cc then cc = Instance.new("ColorCorrectionEffect"); cc.Parent = Lighting end
        return cc
    end
    local _origLighting = {}
    local atmoMod = WorldTab:create_module({
        title = "Atmosphere", description = "Control atmosphere", flag = "ZX_WorldAtmo", section = "left", callback = function() end,
    })
    atmoMod:create_slider({title = "Density", flag = "ZX_AtmoDensity", minimum_value = 0, maximum_value = 100, value = 30, round_number = true, callback = function(v) ensureAtmo().Density = v / 100 end})
    atmoMod:create_slider({title = "Offset", flag = "ZX_AtmoOffset", minimum_value = 0, maximum_value = 100, value = 25, round_number = true, callback = function(v) ensureAtmo().Offset = v / 100 end})
    atmoMod:create_slider({title = "Glare", flag = "ZX_AtmoGlare", minimum_value = 0, maximum_value = 100, value = 0, round_number = true, callback = function(v) ensureAtmo().Glare = v / 100 end})
    atmoMod:create_slider({title = "Haze", flag = "ZX_AtmoHaze", minimum_value = 0, maximum_value = 100, value = 10, round_number = true, callback = function(v) ensureAtmo().Haze = v / 100 end})
    local ccMod = WorldTab:create_module({
        title = "Color Correction", description = "Adjust colors", flag = "ZX_WorldCC", section = "right", callback = function() end,
    })
    ccMod:create_slider({title = "Saturation", flag = "ZX_CCSaturation", minimum_value = 0, maximum_value = 200, value = 100, round_number = true, callback = function(v) ensureCC().Saturation = (v - 100) / 100 end})
    ccMod:create_slider({title = "Contrast", flag = "ZX_CCContrast", minimum_value = 0, maximum_value = 200, value = 100, round_number = true, callback = function(v) ensureCC().Contrast = (v - 100) / 100 end})
    ccMod:create_slider({title = "Brightness", flag = "ZX_CCBrightness", minimum_value = 0, maximum_value = 200, value = 100, round_number = true, callback = function(v) ensureCC().Brightness = (v - 100) / 100 end})
    local lightMod = WorldTab:create_module({
        title = "Lighting", description = "Control lighting", flag = "ZX_WorldLight", section = "right", callback = function() end,
    })
    lightMod:create_slider({title = "Brightness", flag = "ZX_LBrightness", minimum_value = 0, maximum_value = 100, value = 20, round_number = true, callback = function(v) Lighting.Brightness = v / 10 end})
    lightMod:create_slider({title = "Clock Time", flag = "ZX_LClockTime", minimum_value = 0, maximum_value = 240, value = 140, round_number = true, callback = function(v) Lighting.ClockTime = v / 10 end})
    lightMod:create_slider({title = "Fog End", flag = "ZX_LFogEnd", minimum_value = 0, maximum_value = 100000, value = 100000, round_number = true, callback = function(v) Lighting.FogEnd = v end})
    lightMod:create_checkbox({title = "Global Shadows", flag = "ZX_LShadows", callback = function(v) Lighting.GlobalShadows = v end})
    local skyMod = WorldTab:create_module({
        title = "Sky Color Override", description = "Override sky color", flag = "ZX_SkyColor", section = "left",
        callback = function(state)
            if state then
                _origLighting.SkyAmbient = Lighting.Ambient
                _origLighting.SkyBright = Lighting.Brightness
                _origLighting.SkyClock = Lighting.ClockTime
                _origLighting.SkyOutdoor = Lighting.OutdoorAmbient
                Lighting.Ambient = Color3.fromRGB(80, 80, 100)
                Lighting.OutdoorAmbient = Color3.fromRGB(80, 80, 100)
                Lighting.Brightness = 1.5
                Lighting.ClockTime = 12
            else
                if _origLighting.SkyAmbient then
                    Lighting.Ambient = _origLighting.SkyAmbient
                    Lighting.Brightness = _origLighting.SkyBright
                    Lighting.ClockTime = _origLighting.SkyClock
                    Lighting.OutdoorAmbient = _origLighting.SkyOutdoor
                    _origLighting.SkyAmbient = nil
                end
            end
        end,
    })
    skyMod:create_slider({title = "Brightness", flag = "ZX_SkyBrightness", minimum_value = 0, maximum_value = 300, value = 150, round_number = true, callback = function(v) Lighting.Brightness = v / 100 end})
    skyMod:create_slider({title = "Time of Day", flag = "ZX_SkyClockTime", minimum_value = 0, maximum_value = 24, value = 12, round_number = true, callback = function(v) Lighting.ClockTime = v end})
end
getgenv()._ZX_SetupWorldTab()


end
__noirFeatures()
