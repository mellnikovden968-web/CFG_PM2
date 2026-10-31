-- NOVA // standalone mobile hub. Self-starting, asset-free and executor-friendly.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local TS=game:GetService("TweenService")
local CoreGui=game:GetService("CoreGui")
local Player=Players.LocalPlayer

local function parentGui()
    local old=CoreGui:FindFirstChild("NOVA_HUB")
    if old then old:Destroy() end
    local ok, ui=pcall(function() return (gethui and gethui()) or CoreGui end)
    local g=Instance.new("ScreenGui"); g.Name="NOVA_HUB"; g.IgnoreGuiInset=true; g.ResetOnSpawn=false; g.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; g.Parent=ok and ui or Player:WaitForChild("PlayerGui")
    return g
end
local gui=parentGui()
local C={bg=Color3.fromRGB(13,15,22),panel=Color3.fromRGB(20,23,33),card=Color3.fromRGB(27,31,43),card2=Color3.fromRGB(33,38,52),line=Color3.fromRGB(67,73,91),text=Color3.fromRGB(239,242,250),muted=Color3.fromRGB(154,161,180),accent=Color3.fromRGB(117,91,255),good=Color3.fromRGB(72,214,158),warn=Color3.fromRGB(255,185,74)}
local function new(class,p)
 local x=Instance.new(class); for k,v in pairs(p or {}) do x[k]=v end; return x
end
local function curve(x,r) new("UICorner",{CornerRadius=UDim.new(0,r or 10),Parent=x}); return x end
local function edge(x,color,t) new("UIStroke",{Color=color or C.line,Transparency=t or .45,Thickness=1,Parent=x}); return x end
local function pad(x,a,b) new("UIPadding",{PaddingLeft=UDim.new(0,a),PaddingRight=UDim.new(0,a),PaddingTop=UDim.new(0,b or a),PaddingBottom=UDim.new(0,b or a),Parent=x}) end
local function layout(x,g) local l=new("UIListLayout",{Padding=UDim.new(0,g or 7),SortOrder=Enum.SortOrder.LayoutOrder,Parent=x}); return l end
local function label(parent,text,size,color,bold)
 return new("TextLabel",{BackgroundTransparency=1,Text=text,TextColor3=color or C.text,Font=bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,TextSize=size or 13,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Size=UDim2.new(1,0,0,(size or 13)+7),Parent=parent})
end
local function tween(x,p,d) return TS:Create(x,TweenInfo.new(d or .16,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),p):Play() end

local Library={Theme=C,Flags={},Tabs={},Connections={}}
local Window={}
Window.__index=Window
local Tab={};Tab.__index=Tab
local Section={};Section.__index=Section

function Window:Notify(o)
 o=o or {}; local t=new("Frame",{BackgroundColor3=C.card,BorderSizePixel=0,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-18,0,18),Size=UDim2.fromOffset(275,64),Parent=self.Overlay}); curve(t,12);edge(t,C.line,.35)
 local stripe=new("Frame",{BackgroundColor3=o.Type=="success" and C.good or C.accent,BorderSizePixel=0,Size=UDim2.fromOffset(4,64),Parent=t});curve(stripe,4)
 local h=label(t,o.Title or "NOVA",13,C.text,true);h.Position=UDim2.fromOffset(16,10);h.Size=UDim2.new(1,-30,0,18)
 local b=label(t,o.Text or "Готово",11,C.muted);b.Position=UDim2.fromOffset(16,30);b.Size=UDim2.new(1,-30,0,18)
 t.Position=UDim2.new(1,290,0,18);tween(t,{Position=UDim2.new(1,-18,0,18)},.22)
 task.delay(o.Duration or 3,function() if t.Parent then tween(t,{Position=UDim2.new(1,290,0,18)},.2);task.wait(.22);t:Destroy() end end)
end
function Window:SetAccent(c)
 C.accent=c
 for _,v in ipairs(self.Accents) do if v and v.Parent then v.BackgroundColor3=c end end
end
function Window:Select(tab)
 for _,item in ipairs(self.Tabs) do
  local on=item==tab; item.Page.Visible=on; item.Indicator.Visible=on
  tween(item.Button,{BackgroundColor3=on and C.card2 or C.panel,TextColor3=on and C.text or C.muted},.14)
 end
 self.Title.Text=tab.Name; self.Subtitle.Text=tab.Description or "Настройки и управление"
end
function Window:SetVisible(v)
 self.Root.Visible=v; self.Launch.Visible=not v
end
function Window:Destroy()
 for _,c in ipairs(self.Connections) do pcall(function()c:Disconnect()end)end; gui:Destroy()
end
function Window:Center() self.Root.Position=UDim2.fromScale(.5,.5) end

function Library:CreateWindow(o)
 o=o or {}; local w=setmetatable({Tabs={},Accents={},Theme=C},Window);self.Window=w
 local shade=new("Frame",{BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.58,Size=UDim2.fromScale(1,1),Parent=gui})
 local root=new("Frame",{Name="Hub",BackgroundColor3=C.bg,BorderSizePixel=0,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(920,590),ClipsDescendants=true,Parent=gui});curve(root,16);edge(root,C.line,.17);w.Root=root
 local scale=new("UIScale",{Parent=root}); w.Scale=scale
 local function fit()
  local v=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(920,590)
  scale.Scale=math.min(1,(v.X-24)/920,(v.Y-24)/590)
 end
 fit();if workspace.CurrentCamera then table.insert(w.Connections,workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit))end
 -- header
 local top=new("Frame",{BackgroundColor3=C.panel,BorderSizePixel=0,Size=UDim2.new(1,0,0,58),Parent=root})
 local mark=new("TextLabel",{BackgroundColor3=C.accent,BorderSizePixel=0,Text="N",TextColor3=C.text,Font=Enum.Font.GothamBold,TextSize=18,Position=UDim2.fromOffset(16,13),Size=UDim2.fromOffset(32,32),Parent=top});curve(mark,10);table.insert(w.Accents,mark)
 w.Title=label(top,o.Title or "NOVA",15,C.text,true);w.Title.Position=UDim2.fromOffset(59,9);w.Title.Size=UDim2.fromOffset(330,19)
 w.Subtitle=label(top,o.Subtitle or "CONTROL CENTER",10,C.muted);w.Subtitle.Position=UDim2.fromOffset(59,29);w.Subtitle.Size=UDim2.fromOffset(330,16)
 local min=new("TextButton",{BackgroundColor3=C.card,BorderSizePixel=0,Text="—",TextColor3=C.muted,Font=Enum.Font.GothamBold,TextSize=15,Position=UDim2.new(1,-82,0,14),Size=UDim2.fromOffset(28,28),Parent=top});curve(min,8)
 local close=new("TextButton",{BackgroundColor3=C.card,BorderSizePixel=0,Text="×",TextColor3=C.muted,Font=Enum.Font.GothamBold,TextSize=18,Position=UDim2.new(1,-47,0,14),Size=UDim2.fromOffset(28,28),Parent=top});curve(close,8)
 min.Activated:Connect(function()w:SetVisible(false)end);close.Activated:Connect(function()w:Destroy()end)
 -- compact rail, no wasted empty sidebar
 local rail=new("Frame",{BackgroundColor3=C.panel,BorderSizePixel=0,Position=UDim2.fromOffset(0,58),Size=UDim2.new(0,76,1,-58),Parent=root});edge(rail,C.line,.66)
 local nav=new("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(10,14),Size=UDim2.new(1,-20,1,-28),Parent=rail});layout(nav,9)
 local content=new("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(76,58),Size=UDim2.new(1,-76,1,-58),Parent=root});w.Content=content
 w.Overlay=new("Frame",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=10,Parent=gui})
 local launch=new("TextButton",{BackgroundColor3=C.accent,BorderSizePixel=0,Text="NOVA",TextColor3=C.text,Font=Enum.Font.GothamBold,TextSize=12,AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,18,1,-18),Size=UDim2.fromOffset(76,38),Visible=false,Parent=gui});curve(launch,12);w.Launch=launch
 -- A tap restores the hub; a finger drag repositions the launcher but never loses it off-screen.
 local launchDrag, launchMoved, launchStart, launchOrigin=false,false,nil,nil
 launch.InputBegan:Connect(function(i)
  if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
   launchDrag=true;launchMoved=false;launchStart=i.Position;launchOrigin=launch.AbsolutePosition
  end
 end)
 table.insert(w.Connections,UIS.InputChanged:Connect(function(i)
  if not launchDrag or (i.UserInputType~=Enum.UserInputType.Touch and i.UserInputType~=Enum.UserInputType.MouseMovement) then return end
  local d=i.Position-launchStart;if d.Magnitude>7 then launchMoved=true end
  local v=workspace.CurrentCamera.ViewportSize;local z=launch.AbsoluteSize
  launch.Position=UDim2.fromOffset(math.clamp(launchOrigin.X+d.X,0,math.max(0,v.X-z.X)),math.clamp(launchOrigin.Y+d.Y,0,math.max(0,v.Y-z.Y)))
 end))
 table.insert(w.Connections,UIS.InputEnded:Connect(function(i)
  if (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1) and launchDrag then
   launchDrag=false;if not launchMoved then w:SetVisible(true) end
  end
 end))
 -- touch/mouse window drag, clamp after UIScale is applied
 local active,start,origin=false,nil,nil
 top.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then active=true;start=i.Position;origin=root.AbsolutePosition end end)
 table.insert(w.Connections,UIS.InputChanged:Connect(function(i)
  if not active or (i.UserInputType~=Enum.UserInputType.Touch and i.UserInputType~=Enum.UserInputType.MouseMovement) then return end
  local d=i.Position-start;local v=workspace.CurrentCamera.ViewportSize;local size=root.AbsoluteSize
  local p=Vector2.new(math.clamp(origin.X+d.X,0,math.max(0,v.X-size.X)),math.clamp(origin.Y+d.Y,0,math.max(0,v.Y-size.Y)))
  root.Position=UDim2.fromOffset(p.X+size.X/2,p.Y+size.Y/2)
 end))
 table.insert(w.Connections,UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then active=false end end))
 function w:Tab(x)
  x=x or {};local tab=setmetatable({Window=w,Name=x.Name or x.Title or "Раздел",Description=x.Description,Items={}},Tab)
  local btn=new("TextButton",{BackgroundColor3=C.panel,BorderSizePixel=0,Text=x.Icon or "•",TextColor3=C.muted,Font=Enum.Font.GothamBold,TextSize=18,Size=UDim2.fromOffset(56,46),Parent=nav});curve(btn,12)
  local ind=new("Frame",{BackgroundColor3=C.accent,BorderSizePixel=0,Visible=false,Position=UDim2.new(0,0,0.5,-11),Size=UDim2.fromOffset(3,22),Parent=btn});curve(ind,3);table.insert(w.Accents,ind)
  local page=new("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Visible=false,ScrollBarThickness=3,ScrollBarImageColor3=C.line,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Position=UDim2.fromOffset(18,16),Size=UDim2.new(1,-36,1,-32),Parent=content});pad(page,0,1);layout(page,10)
  tab.Button,tab.Indicator,tab.Page=btn,ind,page;table.insert(w.Tabs,tab);btn.Activated:Connect(function()w:Select(tab)end);if #w.Tabs==1 then w:Select(tab)end;return tab
 end
 return w
end
function Tab:Section(x)
 x=x or {};local s=setmetatable({Window=self.Window},Section)
 local card=new("Frame",{BackgroundColor3=C.panel,BorderSizePixel=0,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,Parent=self.Page});curve(card,13);edge(card,C.line,.48);pad(card,13,12);layout(card,7);s.Card=card
 local h=label(card,x.Title or "НАСТРОЙКИ",12,C.text,true);h.Size=UDim2.new(1,0,0,18)
 if x.Description then local d=label(card,x.Description,10,C.muted);d.TextWrapped=true;d.AutomaticSize=Enum.AutomaticSize.Y;d.Size=UDim2.new(1,0,0,0)end
 return s
end
function Section:Row(title,desc)
 local r=new("Frame",{BackgroundColor3=C.card,BorderSizePixel=0,Size=UDim2.new(1,0,0,50),Parent=self.Card});curve(r,10);edge(r,C.line,.67)
 local a=label(r,title,12,C.text,true);a.Position=UDim2.fromOffset(12,7);a.Size=UDim2.new(1,-80,0,17)
 if desc then local b=label(r,desc,10,C.muted);b.Position=UDim2.fromOffset(12,25);b.Size=UDim2.new(1,-80,0,15)end
 return r
end
function Section:Toggle(x)
 x=x or {};local r=self:Row(x.Title or "Переключатель",x.Description);local state=x.Default==true
 local sw=new("TextButton",{BackgroundColor3=state and C.accent or C.line,BorderSizePixel=0,Text="",Position=UDim2.new(1,-55,.5,-11),Size=UDim2.fromOffset(42,22),Parent=r});curve(sw,20);if state then table.insert(self.Window.Accents,sw)end
 local dot=new("Frame",{BackgroundColor3=C.text,BorderSizePixel=0,Position=UDim2.new(0,state and 22 or 3,.5,-8),Size=UDim2.fromOffset(16,16),Parent=sw});curve(dot,20)
 local out={Value=state};function out:Set(v)state=v==true;out.Value=state;tween(sw,{BackgroundColor3=state and C.accent or C.line});tween(dot,{Position=UDim2.new(0,state and 22 or 3,.5,-8)});Library.Flags[x.Flag or x.Title]=state;if x.Callback then task.spawn(x.Callback,state)end end
 sw.Activated:Connect(function()out:Set(not state)end);Library.Flags[x.Flag or x.Title]=state;return out
end
function Section:Button(x)
 x=x or {};local r=self:Row(x.Title or "Действие",x.Description);local b=new("TextButton",{BackgroundColor3=C.accent,BorderSizePixel=0,Text=x.Text or "ОТКРЫТЬ",TextColor3=C.text,Font=Enum.Font.GothamBold,TextSize=10,Position=UDim2.new(1,-82,.5,-12),Size=UDim2.fromOffset(68,24),Parent=r});curve(b,7);table.insert(self.Window.Accents,b);b.Activated:Connect(function()if x.Callback then task.spawn(x.Callback)end end);return b
end
function Section:Slider(x)
 x=x or {};local r=self:Row(x.Title or "Значение",x.Description);local min,max=x.Min or 0,x.Max or 100;local value=math.clamp(x.Default or min,min,max)
 local num=label(r,tostring(value),11,C.text,true);num.TextXAlignment=Enum.TextXAlignment.Right;num.Position=UDim2.new(1,-66,0,6);num.Size=UDim2.fromOffset(48,15)
 local track=new("TextButton",{BackgroundColor3=C.line,BorderSizePixel=0,Text="",Position=UDim2.fromOffset(13,35),Size=UDim2.new(1,-26,0,5),Parent=r});curve(track,5)
 local fill=new("Frame",{BackgroundColor3=C.accent,BorderSizePixel=0,Size=UDim2.new((value-min)/(max-min),0,1,0),Parent=track});curve(fill,5);table.insert(self.Window.Accents,fill)
 local out={Value=value};local drag=false
 function out:Set(v)value=math.clamp(math.floor(v+.5),min,max);out.Value=value;num.Text=tostring(value);fill.Size=UDim2.new((value-min)/(max-min),0,1,0);Library.Flags[x.Flag or x.Title]=value;if x.Callback then task.spawn(x.Callback,value)end end
 local function move(pos)out:Set(min+(max-min)*math.clamp((pos.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1))end
 track.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;move(i.Position)end end)
 table.insert(self.Window.Connections,UIS.InputChanged:Connect(function(i)if drag and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement)then move(i.Position)end end));table.insert(self.Window.Connections,UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end));return out
end
function Section:Dropdown(x)
 x=x or {};local values=x.Values or x.Options or {"Обычный"};local n=table.find(values,x.Default) or 1;local r=self:Row(x.Title or "Режим",x.Description);local b=new("TextButton",{BackgroundColor3=C.card2,BorderSizePixel=0,Text=values[n],TextColor3=C.text,Font=Enum.Font.GothamMedium,TextSize=10,Position=UDim2.new(1,-116,.5,-12),Size=UDim2.fromOffset(102,24),Parent=r});curve(b,7)
 local out={Value=values[n]};function out:Set(v) local ix=table.find(values,v)or 1;n=ix;out.Value=values[n];b.Text=values[n];Library.Flags[x.Flag or x.Title]=out.Value;if x.Callback then task.spawn(x.Callback,out.Value)end end;b.Activated:Connect(function()out:Set(values[n%#values+1])end);return out
end
function Section:Label(x) local r=self:Row(x.Title or x.Text or "Информация",x.Content or x.Description);return r end

local ui=Library:CreateWindow({Title="NOVA",Subtitle="SMART CONTROL CENTER"})
local home=ui:Tab({Name="Обзор",Description="Статус и быстрые действия",Icon="◆"})
local sys=home:Section({Title="СИСТЕМА",Description="Компактный layout без пустого sidebar и вылета контента"})
sys:Label({Title="Сессия активна",Description="Интерфейс адаптирован под touch и landscape"})
sys:Button({Title="Показать уведомление",Text="TEST",Callback=function()ui:Notify({Title="NOVA",Text="Все системы работают",Type="success"})end})
local control=ui:Tab({Name="Контроль",Description="Основные параметры",Icon="◉"})
local main=control:Section({Title="ОСНОВНЫЕ ПАРАМЕТРЫ",Description="Каждый элемент имеет touch-friendly область"})
main:Toggle({Title="Главный переключатель",Description="Включение модуля",Flag="Enabled"});main:Slider({Title="Интенсивность",Description="Точная настройка значения",Min=0,Max=100,Default=65,Flag="Intensity"});main:Dropdown({Title="Режим работы",Description="Нажми для смены",Values={"Стандарт", "Точный", "Быстрый"},Flag="Mode"})
local view=ui:Tab({Name="Вид",Description="Внешний вид и тема",Icon="◈"})
local skin=view:Section({Title="ТЕМА И МАСШТАБ",Description="Акцент меняется сразу во всём интерфейсе"})
skin:Dropdown({Title="Цвет акцента",Values={"Фиолетовый","Океан","Изумруд","Янтарь"},Default="Фиолетовый",Callback=function(v)local m={['Фиолетовый']=Color3.fromRGB(117,91,255),['Океан']=Color3.fromRGB(52,151,255),['Изумруд']=Color3.fromRGB(52,205,145),['Янтарь']=Color3.fromRGB(246,174,61)};ui:SetAccent(m[v])end});skin:Button({Title="Центрировать окно",Text="CENTER",Callback=function()ui:Center()end})
local info=ui:Tab({Name="О меню",Description="Управление интерфейсом",Icon="?"})
local help=info:Section({Title="УПРАВЛЕНИЕ",Description="Перетаскивай окно за верхнюю панель. Свернуть — кнопка сверху; NOVA появится снизу слева."})
help:Label({Title="Безопасная зона",Description="Окно зажато в пределах текущего экрана, в том числе при смене ориентации."})
ui:Notify({Title="NOVA",Text="Готово к работе",Type="success",Duration=2.5})
getgenv().NovaUI=Library
return Library
